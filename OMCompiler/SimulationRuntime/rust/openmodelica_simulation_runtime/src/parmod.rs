//! `--parmodauto`: C's `ParModelica/auto` interface (`PM_*`), served by
//! [`openmodelica_sim_meta::parmod`] and a pool of worker threads rather than by
//! `libParModelicaAuto` and TBB.
//!
//! The generated `main` still creates the model (`PM_Model_create`) and hands over
//! the `functionODE_systems` array (`PM_Model_load_ODE_system`); the task graph is
//! read from the same `<prefix>_ode.json` the C++ runtime reads. From there the
//! shared scheduler owns the evaluation: it clusters the graph, and the driver
//! reaches one task through `SimEngine::call2_raw("parmodTask", _, k)` or a whole
//! [`Plan`] through [`SimEngine::parmod_parallel`](openmodelica_sim_meta::driver::SimEngine::parmod_parallel).

use core::ffi::{c_char, c_int, c_void};
use core::ptr;
use core::sync::atomic::{AtomicBool, AtomicI32, AtomicU32, AtomicUsize, Ordering};
use std::sync::{Arc, Condvar, Mutex, OnceLock};

use openmodelica_sim_meta::ParmodInfo;
use openmodelica_sim_meta::parmod::Plan;
use openmodelica_solvers::atomic64::AtomicU64;

use crate::abi::{DATA, threadData_t};

/// `FunctionType` (`om_pm_interface.hpp`): one ODE equation.
type TaskFn = unsafe extern "C" fn(*mut DATA, *mut threadData_t);

// `omc_init.c`, where `mmc_init` created it: the key external functions look
// `threadData` up under when they were not passed it.
#[cfg(unix)]
unsafe extern "C" {
    static mmc_thread_data_key: libc::pthread_key_t;
}

/// A worker's `threadData_t`. Only the head of the struct is mirrored (the tail
/// past `parent` depends on build options no runtime reads), so the block is sized
/// well past what any platform's `sizeof(threadData_t)` can be — 304 bytes on
/// x86-64 glibc — and C code writing a field this runtime does not know about
/// still writes inside it.
const THREAD_DATA_BYTES: usize = 1024;

struct Model {
    prefix: String,
    data: *mut DATA,
    thread_data: *mut threadData_t,
    funcs: *const TaskFn,
    info: Option<ParmodInfo>,
}

struct Store(core::cell::UnsafeCell<Option<Model>>);
unsafe impl Sync for Store {}
static MODEL: Store = Store(core::cell::UnsafeCell::new(None));

// Set up from the generated `main` and read by the run, both on the main thread.
fn model() -> &'static mut Option<Model> {
    unsafe { &mut *MODEL.0.get() }
}

/// The opaque handle the generated `main` keeps in `pm_model`; there is one model
/// per process, so its address is all it has to be.
static HANDLE: u8 = 0;

fn cstr(p: *const c_char) -> String {
    if p.is_null() {
        return String::new();
    }
    unsafe { core::ffi::CStr::from_ptr(p) }.to_string_lossy().into_owned()
}

#[unsafe(no_mangle)]
pub extern "C" fn PM_Model_create(
    name: *const c_char,
    data: *mut DATA,
    threadData: *mut threadData_t,
    _num_threads: usize,
) -> *mut c_void {
    // `-parmodNumThreads` reaches the scheduler through the parsed simflags, so the
    // count the generated `main` read out of `omc_flagValue` is ignored here.
    *model() = Some(Model {
        prefix: cstr(name),
        data,
        thread_data: threadData,
        funcs: ptr::null(),
        info: None,
    });
    &HANDLE as *const u8 as *mut c_void
}

/// `OMModel::load_ODE_system`: the task array, and the graph over it.
#[unsafe(no_mangle)]
pub extern "C" fn PM_Model_load_ODE_system(_model: *mut c_void, funcs: *const TaskFn) {
    let Some(m) = model().as_mut() else { return };
    m.funcs = funcs;
    let dir = unsafe {
        match crate::support::omc_flag[crate::abi::FLAG_INPUT_PATH] != 0 {
            true => Some(cstr(crate::support::omc_flagValue[crate::abi::FLAG_INPUT_PATH])),
            false => None,
        }
    };
    let file = format!("{}_ode.json", m.prefix);
    let path = match dir {
        Some(d) => format!("{d}/{file}"),
        None => file,
    };
    match openmodelica_sim_meta::parmod::load_ode_json(&path) {
        Ok(info) => m.info = Some(info),
        Err(e) => {
            // C's `utility::eq_index_fatal` ends the process rather than run a
            // `--parmodauto` model whose task graph it could not read.
            eprintln!("{e}");
            std::process::exit(1);
        }
    }
}

/// `SimMeta::parmod`, which makes the driver route `functionODE` through the
/// scheduler; `None` for a model translated without `--parmodauto`.
pub fn describe() -> Option<ParmodInfo> {
    model().as_ref()?.info.clone()
}

/// `PM_evaluate_ODE_system`: every task in turn. The generated `functionODE` calls
/// this, and the scheduler reaches it as its sequential evaluation
/// ([`Op::All`](openmodelica_sim_meta::parmod::Op::All)); task order is a valid
/// schedule on its own, every edge pointing forward.
#[unsafe(no_mangle)]
pub extern "C" fn PM_evaluate_ODE_system(_model: *mut c_void) {
    // Reached without a task system only where the generated `main` skipped
    // `PM_Model_create`; evaluating nothing would be a run whose ODE is silently
    // zero, so say so instead. The C++ runtime dereferences the null model here.
    let loaded = model().as_ref().filter(|m| m.info.is_some());
    let Some(m) = loaded else {
        eprintln!("Fatal : --parmodauto: the ODE task system was never loaded.");
        std::process::exit(1);
    };
    for k in 0..m.info.as_ref().map_or(0, |i| i.tasks.len()) {
        unsafe { (*m.funcs.add(k))(m.data, m.thread_data) };
    }
}

/// One task, from the driver's `parmodTask` or from a worker. `td` is the calling
/// thread's own `threadData`: a task that leaves through `simulationJumpBuffer`
/// must leave through the buffer this thread installed.
pub fn call_task(k: u32, td: *mut threadData_t) {
    let Some(m) = model().as_ref() else { return };
    unsafe { (*m.funcs.add(k as usize))(m.data, td) };
}

std::thread_local! {
    static CURRENT_TD: core::cell::Cell<*mut threadData_t> = const { core::cell::Cell::new(ptr::null_mut()) };
}

/// The calling thread's `threadData`, for a runtime hook that is reached from a
/// worker and has no argument to take it from. Null on the main thread, which has
/// the generated `main`'s.
pub fn current_thread_data() -> *mut threadData_t {
    CURRENT_TD.get()
}

/// `dump_times`, called by the generated `main` after the run. The driver's own
/// `parmod::finish` has already printed the block.
#[unsafe(no_mangle)]
pub extern "C" fn dump_times(_model: *mut c_void) {}

// The sequential-evaluation timer of the C++ runtime. Nothing in a generated model
// calls these, but they are part of the interface it was linked against.
#[unsafe(no_mangle)]
pub extern "C" fn seq_ode_timer_start() {}
#[unsafe(no_mangle)]
pub extern "C" fn seq_ode_timer_stop() {}
#[unsafe(no_mangle)]
pub extern "C" fn seq_ode_timer_reset() {}
#[unsafe(no_mangle)]
pub extern "C" fn seq_ode_timer_get_elapsed_time2() {}
#[unsafe(no_mangle)]
pub extern "C" fn seq_ode_timer_get_elapsed_time() -> f64 {
    0.0
}

// ───────────────────────────── the solver lock ─────────────────────────────

static SOLVER_LOCK: Mutex<()> = Mutex::new(());

std::thread_local! {
    static SOLVER_DEPTH: core::cell::Cell<u32> = const { core::cell::Cell::new(0) };
}

/// Held while a task is inside an equation system. Re-entrant: a residual can
/// reach another system, and that is the same thread's solve.
pub struct SolverGuard {
    counted: bool,
    _lock: Option<std::sync::MutexGuard<'static, ()>>,
}

impl Drop for SolverGuard {
    fn drop(&mut self) {
        if self.counted {
            SOLVER_DEPTH.with(|d| d.set(d.get() - 1));
        }
    }
}

/// Held over one equation-system solve while `-lv=LOG_STATS_V` is measuring: the
/// per-system statistics table is one shared nesting stack, the only solver state
/// two `--parmodauto` tasks still share. Everything else a solve owns is per thread
/// (`openmodelica_nls`'s flags and counters) or per system, so a run that is not
/// measuring serialises nothing.
pub fn stats_guard() -> SolverGuard {
    guard(openmodelica_solvers::sysstat::enabled())
}

fn guard(needed: bool) -> SolverGuard {
    if !needed || POOL.get().is_none() {
        return SolverGuard { counted: false, _lock: None };
    }
    let first = SOLVER_DEPTH.with(|d| {
        let v = d.get();
        d.set(v + 1);
        v == 0
    });
    let lock = first.then(|| SOLVER_LOCK.lock().unwrap_or_else(|e| e.into_inner()));
    SolverGuard { counted: true, _lock: lock }
}

// ───────────────────────────── the worker pool ─────────────────────────────

/// How long a participant already in a round waits for another to free the next
/// cluster. That is a wait of one cluster, so spinning through it beats sleeping.
const SPINS_ROUND: u32 = 4000;

/// How long an idle worker looks for the next round before sleeping. While the
/// scheduler is still timing the two evaluations against each other it has to be
/// short: a worker spinning between rounds takes a core off the thread running the
/// sequential ones, and the trial then measures them as slower than they are. Once
/// it has settled on the threads there is nothing left to bias, and waiting eagerly
/// is what keeps a round's hand-over cheap.
const SPINS_IDLE_TRIAL: u32 = 200;
const SPINS_IDLE_SETTLED: u32 = 20_000;

/// What a plan is evaluated from, derived once per [`Plan`] and read without the
/// lock: its clusters, how many parents each waits for, and who waits for it.
struct Graph {
    clusters: Vec<Vec<u32>>,
    parents_n: Vec<u32>,
    children: Vec<Vec<u32>>,
}

/// The round's mutable state. What a spinning participant looks at is outside it,
/// in [`Pool`]'s atomics, so an idle worker never touches the lock the working ones
/// need. Both buffers are reused: a round must not allocate.
struct Round {
    waiting: Vec<u32>,
    ready: Vec<usize>,
}

struct Pool {
    /// Bumped once per evaluation; a worker that sees a new value joins it.
    generation: AtomicU64,
    /// Clusters not finished, and of those the ones nobody has claimed:
    /// `ready.len()`, mirrored so a spinning worker can see it without the lock.
    remaining: AtomicUsize,
    ready_n: AtomicUsize,
    /// The error stage a task runs under, and whether one left through its jump
    /// buffer.
    stage: AtomicI32,
    jumped: AtomicBool,
    /// Rebuilt when the scheduler hands over a different plan, and read by every
    /// participant while the round runs.
    graph: Mutex<Arc<Graph>>,
    lock: Mutex<Round>,
    work: Condvar,
    /// Workers asleep on `work`, so a round nobody is waiting for costs no `futex`
    /// call at all.
    sleepers: AtomicU32,
    /// `graph` is derived from a plan; the id says when to derive it again.
    plan_id: AtomicU64,
    /// [`SPINS_IDLE_TRIAL`] or [`SPINS_IDLE_SETTLED`].
    idle_spins: AtomicU32,
    /// Participants inside a cluster's tasks. Zero with clusters left and none
    /// ready is a deadlock, where a long-running cluster merely looks like one.
    running: AtomicU32,
}

static POOL: OnceLock<Arc<Pool>> = OnceLock::new();

/// Whether there are worker threads to run a plan on. `-parmodNumThreads` counts
/// the calling thread, so one means the sequential evaluation. Asked once per ODE
/// evaluation, and the flags it reads do not change during a run.
pub fn can_parallel() -> bool {
    static CAN: OnceLock<bool> = OnceLock::new();
    *CAN.get_or_init(|| cfg!(target_has_atomic = "64") && openmodelica_sim_meta::parmod::num_threads() > 1)
}

/// The pool, started on its first use: `-parmodNumThreads - 1` workers, the caller
/// being the last participant.
fn pool(main_td: *mut threadData_t) -> &'static Arc<Pool> {
    POOL.get_or_init(|| {
        let empty = Arc::new(Graph { clusters: Vec::new(), parents_n: Vec::new(), children: Vec::new() });
        let pool = Arc::new(Pool {
            generation: AtomicU64::new(0),
            remaining: AtomicUsize::new(0),
            ready_n: AtomicUsize::new(0),
            stage: AtomicI32::new(0),
            jumped: AtomicBool::new(false),
            graph: Mutex::new(empty),
            lock: Mutex::new(Round { waiting: Vec::new(), ready: Vec::new() }),
            work: Condvar::new(),
            sleepers: AtomicU32::new(0),
            plan_id: AtomicU64::new(0),
            idle_spins: AtomicU32::new(SPINS_IDLE_TRIAL),
            running: AtomicU32::new(0),
        });
        let main = main_td as usize;
        let flags = openmodelica_solvers::simflags::flags();
        for _ in 1..openmodelica_sim_meta::parmod::num_threads() {
            let (p, f) = (Arc::clone(&pool), flags.clone());
            std::thread::spawn(move || worker(p, f, main as *mut threadData_t));
        }
        pool
    })
}

/// A worker's own `threadData_t`: C's `MMC_ALLOC_AND_INIT_THREADDATA` without what
/// only MetaModelica needs (the stack-overflow bottom, the parent mutex). C's own
/// ParModelica shares the main thread's, which cannot be right — a violated
/// assertion inside a task leaves through `simulationJumpBuffer`, and that buffer
/// belongs to whichever thread installed it. `localRoots` is carried over because
/// external functions reach the run's data through it.
fn thread_data_for(main: *mut threadData_t) -> *mut threadData_t {
    unsafe {
        // One per worker, alive until the process ends.
        let td = libc::calloc(1, THREAD_DATA_BYTES) as *mut threadData_t;
        if !main.is_null() {
            (*td).localRoots = (*main).localRoots;
        }
        (*td).parent = main;
        #[cfg(unix)]
        libc::pthread_setspecific(mmc_thread_data_key, td as *const c_void);
        CURRENT_TD.set(td);
        td
    }
}

fn worker(pool: Arc<Pool>, flags: openmodelica_solvers::simflags::SimFlags, main_td: *mut threadData_t) {
    // The run's simflags and `-lv` mask live in a thread-local under `std`, so a
    // worker that did not copy them would solve its tasks under the defaults.
    openmodelica_solvers::simflags::set_flags(flags);
    let td = thread_data_for(main_td);
    let mut seen = 0u64;
    loop {
        let mut spins = 0;
        while pool.generation.load(Ordering::Acquire) == seen {
            if spins < pool.idle_spins.load(Ordering::Relaxed) {
                spins += 1;
                core::hint::spin_loop();
                continue;
            }
            let mut g = pool.lock.lock().unwrap();
            pool.sleepers.fetch_add(1, Ordering::SeqCst);
            while pool.generation.load(Ordering::Acquire) == seen {
                g = pool.work.wait(g).unwrap();
            }
            pool.sleepers.fetch_sub(1, Ordering::SeqCst);
        }
        seen = pool.generation.load(Ordering::Acquire);
        let graph = Arc::clone(&pool.graph.lock().unwrap());
        run_round(&pool, &graph, td, seen);
    }
}

/// Claim ready clusters until the round is empty, taking the lock only to claim one
/// and to report it done. `gen` is the round this participant joined: the scheduler
/// hands over a new plan when it re-clusters, and a participant that carried the
/// old graph into the new round would count down the wrong clusters' parents —
/// which hung a `-parmodScheduler=level` run outright.
fn run_round(pool: &Pool, graph: &Graph, td: *mut threadData_t, round: u64) {
    let mut spins = 0u32;
    let mut waited: Option<std::time::Instant> = None;
    loop {
        if pool.remaining.load(Ordering::Acquire) == 0
            || pool.generation.load(Ordering::Acquire) != round
        {
            return;
        }
        if pool.ready_n.load(Ordering::Acquire) == 0 {
            // Every ready cluster is claimed; what frees the next one is another
            // participant finishing, so this is a short wait.
            spins += 1;
            if spins > SPINS_ROUND {
                std::thread::yield_now();
                stalled(pool, graph, &mut waited);
            } else {
                core::hint::spin_loop();
            }
            continue;
        }
        let claimed = {
            let mut g = pool.lock.lock().unwrap();
            // The authoritative round check: the two atomics above are hints a
            // participant reads without the lock, and both can already belong to the
            // next round by the time it gets here.
            if pool.generation.load(Ordering::Relaxed) != round {
                return;
            }
            let claimed = g.ready.pop();
            // Exactly `ready.len()`, always published by the thread that changed
            // it, so a spinning worker never reads a count with nothing behind it.
            pool.ready_n.store(g.ready.len(), Ordering::Release);
            claimed
        };
        let Some(c) = claimed else {
            // Another participant took it between the two reads.
            core::hint::spin_loop();
            continue;
        };
        spins = 0;
        waited = None;
        let stage = pool.stage.load(Ordering::Relaxed);
        let tasks = &graph.clusters[c];
        pool.running.fetch_add(1, Ordering::AcqRel);
        // One jump buffer per cluster rather than per task: a task that leaves
        // through it ends the cluster, which is what it would end in C too.
        if !crate::support::protected(td, stage, || {
            for &k in tasks {
                call_task(k, td);
            }
        }) {
            pool.jumped.store(true, Ordering::Relaxed);
        }
        {
            let mut g = pool.lock.lock().unwrap();
            for &ch in &graph.children[c] {
                let ch = ch as usize;
                g.waiting[ch] -= 1;
                if g.waiting[ch] == 0 {
                    g.ready.push(ch);
                }
            }
            pool.ready_n.store(g.ready.len(), Ordering::Release);
        }
        pool.remaining.fetch_sub(1, Ordering::Release);
        pool.running.fetch_sub(1, Ordering::AcqRel);
    }
}

/// One evaluation of `plan` across the pool, the calling thread included; `true`
/// when a task left through its jump buffer. `Plan::levels` is not consulted — the
/// parent counters express the same order without a barrier between levels.
pub fn run_plan(plan: &Plan, stage: c_int, main_td: *mut threadData_t, settled: bool) -> bool {
    // A single cluster is the whole evaluation in dependency order; handing it to
    // the pool would only pay for the hand-over.
    if plan.clusters.len() < 2 {
        let mut jumped = false;
        for k in plan.clusters.iter().flatten() {
            if !crate::support::protected(main_td, stage, || call_task(*k, main_td)) {
                jumped = true;
            }
        }
        return jumped;
    }
    // Every parent must point backwards, or the counters cannot reach zero and the
    // round would spin for ever. That is a scheduler bug; report it and evaluate
    // sequentially rather than hang on it.
    if !plan_points_backwards(plan) {
        static SAID: std::sync::atomic::AtomicBool = std::sync::atomic::AtomicBool::new(false);
        if !SAID.swap(true, Ordering::Relaxed) {
            openmodelica_solvers::omclog::warning(
                openmodelica_solvers::omclog::STDOUT,
                false,
                "parmodauto: the scheduler handed over a task graph whose dependencies are not in order; evaluating sequentially.",
            );
        }
        let mut jumped = false;
        for k in plan.clusters.iter().flatten() {
            if !crate::support::protected(main_td, stage, || call_task(*k, main_td)) {
                jumped = true;
            }
        }
        return jumped;
    }
    let pool = pool(main_td);
    pool.idle_spins.store(
        if settled { SPINS_IDLE_SETTLED } else { SPINS_IDLE_TRIAL },
        Ordering::Relaxed,
    );
    let graph = {
        let mut held = pool.graph.lock().unwrap();
        if pool.plan_id.swap(plan.id, Ordering::Relaxed) != plan.id {
            let mut children = vec![Vec::new(); plan.clusters.len()];
            for (c, ps) in plan.parents.iter().enumerate() {
                for &p in ps {
                    children[p as usize].push(c as u32);
                }
            }
            *held = Arc::new(Graph {
                clusters: plan.clusters.clone(),
                parents_n: plan.parents.iter().map(|p| p.len() as u32).collect(),
                children,
            });
        }
        Arc::clone(&held)
    };
    // The whole round is published under the lock, the generation last. A
    // participant still in the previous round's `run_round` decides whether to claim
    // under that same lock, so it cannot take a cluster out of a round it did not
    // join — which stranded clusters and hung the run.
    let round = {
        // Reused buffers: an ODE evaluation must not allocate.
        let mut g = pool.lock.lock().unwrap();
        g.waiting.clear();
        g.waiting.extend_from_slice(&graph.parents_n);
        g.ready.clear();
        g.ready.extend((0..graph.clusters.len()).filter(|&c| graph.parents_n[c] == 0));
        pool.ready_n.store(g.ready.len(), Ordering::Release);
        pool.stage.store(stage, Ordering::Relaxed);
        pool.jumped.store(false, Ordering::Relaxed);
        pool.remaining.store(graph.clusters.len(), Ordering::Release);
        pool.generation.fetch_add(1, Ordering::Release) + 1
    };
    if pool.sleepers.load(Ordering::SeqCst) > 0 {
        let _g = pool.lock.lock().unwrap();
        pool.work.notify_all();
    }
    run_round(pool, &graph, main_td, round);
    pool.jumped.load(Ordering::Relaxed)
}

/// Whether `plan.parents[c]` only names clusters before `c`, which is what makes a
/// parent count reach zero.
fn plan_points_backwards(plan: &Plan) -> bool {
    plan.parents.len() == plan.clusters.len()
        && plan.parents.iter().enumerate().all(|(c, ps)| ps.iter().all(|&p| (p as usize) < c))
}

/// A round that stops making progress is a bug in the counters, and one that only
/// shows as a busy process. Say so once a participant has waited far longer than
/// any cluster takes, rather than let the run look merely slow.
fn stalled(pool: &Pool, graph: &Graph, since: &mut Option<std::time::Instant>) {
    // With a participant inside a cluster there is nothing wrong, only a long
    // cluster; the clock starts over each time one finishes.
    if pool.running.load(Ordering::Acquire) != 0 {
        *since = None;
        return;
    }
    let start = since.get_or_insert_with(std::time::Instant::now);
    if start.elapsed().as_secs() < 10 {
        return;
    }
    *since = Some(std::time::Instant::now());
    let stuck: String = {
        let g = pool.lock.lock().unwrap();
        g.waiting
            .iter()
            .enumerate()
            .filter(|(_, w)| **w != 0)
            .take(8)
            .map(|(c, w)| format!(" c{c} waits for {w} of {}", graph.parents_n[c]))
            .collect()
    };
    openmodelica_solvers::omclog::warning!(
        openmodelica_solvers::omclog::STDOUT,
        false,
        "parmodauto: nothing is running and no cluster is ready, with {} of {} left: the task graph's parent counts do not add up.{stuck}",
        pool.remaining.load(Ordering::Relaxed),
        graph.clusters.len(),
    );
}
