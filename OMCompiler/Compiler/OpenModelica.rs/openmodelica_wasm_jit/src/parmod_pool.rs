//! The `--parmodauto` worker threads: C's TBB pool. A wasmtime store runs on one
//! thread at a time, so each worker owns a store with its own runtime and model
//! instances over the run's one shared memory, and evaluates the clusters the
//! scheduler's [`Plan`] hands it. The calling thread works too, on the run's own
//! instances.
//!
//! A worker's model instance is the main one's twin: its `start` ran in
//! `rt_start_mode(2)`, replaying the main instantiation's `rt_alloc`s, so the
//! globals hold the same block addresses and the table the same callbacks at the
//! same indices. The runtime instance shares every static with the main one (they
//! are memory), and gets its own stack and TLS block.

use std::collections::VecDeque;
use std::sync::atomic::{AtomicBool, AtomicU32, AtomicU64, AtomicUsize, Ordering};
use std::sync::{Arc, Condvar, Mutex};

use openmodelica_sim_meta::parmod::Plan;
use openmodelica_wasi::wasi::WasiCtx;
use wasmtime::{Engine, Instance, Module, SharedMemory, Store, TypedFunc};

use crate::model::SimModel;
use crate::simmem::SimMem;

type Result<T> = std::result::Result<T, String>;

/// Matching the threads runtime's own `-zstack-size` (`THREADS_LINK_ARGS`): a deep
/// solve overran the 1 MiB default.
const STACK_BYTES: u32 = 8 << 20;

fn wts<T, E: std::fmt::Debug>(r: std::result::Result<T, E>) -> Result<T> {
    r.map_err(|e| format!("wasm engine error: {e:?}"))
}

/// The memory the runtime module imports, sized by its import and the engine's
/// reservation.
pub fn new_shared_memory(engine: &Engine, runtime: &Module) -> Result<SharedMemory> {
    let minimum = runtime
        .imports()
        .find_map(|i| i.ty().memory().map(|m| m.minimum()))
        .ok_or("CodegenWasmJit: the threads runtime imports no memory")?;
    let maximum = crate::engine_config::shared_max_pages().max(minimum);
    wts(SharedMemory::new(engine, wasmtime::MemoryType::shared(minimum as u32, maximum as u32)))
}

/// What a cluster's completion releases, derived once per [`Plan::id`].
struct Prepared {
    id: u64,
    children: Vec<Vec<u32>>,
    parents: Vec<u32>,
    /// Level-synchronous plans: each cluster's level, and the clusters per level.
    level_of: Vec<u32>,
    levels: Vec<Vec<u32>>,
}

impl Prepared {
    fn new(plan: &Plan) -> Prepared {
        let n = plan.clusters.len();
        let mut children = vec![Vec::new(); n];
        let mut parents = vec![0u32; n];
        let mut level_of = vec![0u32; n];
        if plan.levels.is_empty() {
            for (c, ps) in plan.parents.iter().enumerate() {
                parents[c] = ps.len() as u32;
                for &p in ps {
                    children[p as usize].push(c as u32);
                }
            }
        } else {
            for (l, cs) in plan.levels.iter().enumerate() {
                for &c in cs {
                    level_of[c as usize] = l as u32;
                    parents[c as usize] = if l == 0 { 0 } else { 1 };
                }
            }
        }
        Prepared { id: plan.id, children, parents, level_of, levels: plan.levels.clone() }
    }
}

struct PlanRef(*const Plan);
unsafe impl Send for PlanRef {}
unsafe impl Sync for PlanRef {}

/// One evaluation: the ready queue and the counters that feed it. Lives for the
/// round; the main thread returns only once every worker has left it.
struct Round {
    plan: PlanRef,
    sim_data: u32,
    no_throw: bool,
    pending: Vec<AtomicU32>,
    level_left: Vec<AtomicU32>,
    queue: Mutex<VecDeque<u32>>,
    remaining: AtomicUsize,
    active: AtomicUsize,
    aborted: AtomicBool,
    failure: Mutex<Option<Failure>>,
    warnings: Mutex<Vec<[i32; 10]>>,
    /// Per participant (0 = the calling thread), the task it is inside, or `u32::MAX`.
    current: Vec<AtomicU32>,
}

/// A task's trap on a worker, with what its thread-local host state recorded.
struct Failure {
    detail: String,
    assert: Option<crate::host::PendingAssert>,
}

impl Round {
    fn plan(&self) -> &Plan {
        unsafe { &*self.plan.0 }
    }

    fn finished(&self, prep: &Prepared, c: u32) {
        let mut ready = Vec::new();
        if prep.levels.is_empty() {
            for &ch in &prep.children[c as usize] {
                if self.pending[ch as usize].fetch_sub(1, Ordering::AcqRel) == 1 {
                    ready.push(ch);
                }
            }
        } else {
            let l = prep.level_of[c as usize] as usize;
            if self.level_left[l].fetch_sub(1, Ordering::AcqRel) == 1 && l + 1 < prep.levels.len() {
                ready.extend_from_slice(&prep.levels[l + 1]);
            }
        }
        if !ready.is_empty() {
            self.queue.lock().unwrap_or_else(|e| e.into_inner()).extend(ready);
        }
        self.remaining.fetch_sub(1, Ordering::AcqRel);
    }

    fn fail(&self, f: Failure) {
        let mut slot = self.failure.lock().unwrap_or_else(|e| e.into_inner());
        if slot.is_none() {
            *slot = Some(f);
        }
        self.aborted.store(true, Ordering::Release);
    }
}

struct Shared {
    state: Mutex<(u64, Option<Arc<Round>>, bool)>,
    cv: Condvar,
    generation: AtomicU64,
}

/// A worker's stores and entry point, built on the main thread and moved to it.
struct WorkerCtx {
    store: Store<WasiCtx>,
    task: TypedFunc<(u32, u32), ()>,
    /// `rt_stats_flush`: the thread's counters into the run's totals, per round.
    flush: TypedFunc<(), ()>,
    memory: SimMem,
}

pub struct Pool {
    shared: Arc<Shared>,
    threads: Vec<std::thread::JoinHandle<()>>,
    prepared: Option<Prepared>,
}

/// Debug tally: clusters run and nanoseconds inside tasks per participant, and
/// the rounds' wall time.
static CLUSTERS_RUN: Mutex<Vec<(u64, u64)>> = Mutex::new(Vec::new());
static ROUND_NANOS: AtomicU64 = AtomicU64::new(0);

impl Pool {
    /// `None` when the run has one thread, or the model reaches `external "C"`,
    /// which only the main store's libraries define.
    pub fn new(
        main: &mut Store<WasiCtx>,
        rt_alloc: &TypedFunc<u32, u32>,
        memory: SharedMemory,
        runtime: &Module,
        model_module: &Module,
        model: &SimModel,
    ) -> Result<Option<Pool>> {
        let threads = openmodelica_sim_meta::parmod::num_threads();
        if threads <= 1 {
            return Ok(None);
        }
        if !model.ext_imports.is_empty() {
            use openmodelica_sim_meta::omclog;
            omclog::info(omclog::STDOUT, false, "parmodauto: the model calls external \"C\"; its ODE is evaluated on one thread");
            return Ok(None);
        }
        let engine = main.engine().clone();
        let mut workers = Vec::with_capacity(threads - 1);
        install_backtrace_signal();
        for i in 1..threads {
            dbg_log(format!("parmod: instantiating worker {i}"));
            let stack = wts(rt_alloc.call(&mut *main, STACK_BYTES + 16))?;
            let stack_top = (stack + STACK_BYTES) & !15;
            workers.push(instantiate_worker(&engine, &memory, runtime, model_module, stack_top, |bytes| {
                wts(rt_alloc.call(&mut *main, bytes))
            })?);
            dbg_log(format!("parmod: worker {i} ready"));
        }
        let shared = Arc::new(Shared {
            state: Mutex::new((0, None, false)),
            cv: Condvar::new(),
            generation: AtomicU64::new(0),
        });
        let mut handles = Vec::with_capacity(workers.len());
        for (i, w) in workers.into_iter().enumerate() {
            let shared = shared.clone();
            let h = std::thread::Builder::new()
                .name(format!("omc-parmod-{}", i + 1))
                .spawn(move || worker_main(w, shared, i + 1))
                .map_err(|e| format!("parmodauto: cannot spawn a worker thread: {e}"))?;
            handles.push(h);
        }
        if debug_enabled() {
            let shared = shared.clone();
            std::thread::spawn(move || loop {
                std::thread::sleep(std::time::Duration::from_secs(5));
                let st = shared.state.lock().unwrap_or_else(|e| e.into_inner());
                if st.2 {
                    return;
                }
                match &st.1 {
                    Some(r) => dbg_log(format!(
                        "parmod watchdog: gen={} remaining={} active={} aborted={} queue={} current={:?}",
                        st.0,
                        r.remaining.load(Ordering::Relaxed),
                        r.active.load(Ordering::Relaxed),
                        r.aborted.load(Ordering::Relaxed),
                        r.queue.lock().unwrap_or_else(|e| e.into_inner()).len(),
                        r.current.iter().map(|c| c.load(Ordering::Relaxed)).collect::<Vec<_>>()
                    )),
                    None => dbg_log(format!("parmod watchdog: gen={} no round", st.0)),
                }
            });
        }
        Ok(Some(Pool { shared, threads: handles, prepared: None }))
    }

    /// Evaluate `plan` over the workers and the calling thread, whose instances are
    /// `store` and `task` (the run's `parmodTask`).
    pub fn run(
        &mut self,
        plan: &Plan,
        sim_data: u32,
        store: &mut Store<WasiCtx>,
        task: &TypedFunc<(u32, u32), ()>,
    ) -> metamodelica::Result<()> {
        if self.prepared.as_ref().is_none_or(|p| p.id != plan.id) {
            self.prepared = Some(Prepared::new(plan));
        }
        let prep = self.prepared.as_ref().expect("prepared plan");
        let n = plan.clusters.len();
        let queue: VecDeque<u32> = match prep.levels.first() {
            Some(first) => first.iter().copied().collect(),
            None => (0..n as u32).filter(|&c| prep.parents[c as usize] == 0).collect(),
        };
        let round = Arc::new(Round {
            plan: PlanRef(plan),
            sim_data,
            no_throw: crate::host::no_throw_asserts(),
            pending: prep.parents.iter().map(|&p| AtomicU32::new(p)).collect(),
            level_left: prep.levels.iter().map(|l| AtomicU32::new(l.len() as u32)).collect(),
            queue: Mutex::new(queue),
            remaining: AtomicUsize::new(n),
            active: AtomicUsize::new(0),
            aborted: AtomicBool::new(false),
            failure: Mutex::new(None),
            warnings: Mutex::new(Vec::new()),
            current: (0..self.threads.len() + 1).map(|_| AtomicU32::new(u32::MAX)).collect(),
        });
        {
            let mut st = self.shared.state.lock().unwrap_or_else(|e| e.into_inner());
            st.0 += 1;
            st.1 = Some(round.clone());
            self.shared.generation.store(st.0, Ordering::Release);
            self.shared.cv.notify_all();
            if debug_enabled() && st.0 <= 3 {
                dbg_log(format!("parmod: round {} starts, {} clusters", st.0, n));
            }
        }
        let t_round = std::time::Instant::now();
        work(&round, prep, store, task, 0);
        // No worker joins the round from here on (they enter under the lock), and
        // those inside finish their cluster and leave.
        {
            let mut st = self.shared.state.lock().unwrap_or_else(|e| e.into_inner());
            st.1 = None;
        }
        let mut spins = 0u32;
        let debug = debug_enabled();
        let t0 = std::time::Instant::now();
        let mut reported = 0u64;
        while round.active.load(Ordering::Acquire) != 0 {
            if debug && t0.elapsed().as_secs() / 5 > reported {
                reported = t0.elapsed().as_secs() / 5;
                let cur: Vec<u32> = round.current.iter().map(|c| c.load(Ordering::Relaxed)).collect();
                dbg_log(format!(
                    "parmod: waiting for workers: remaining={} active={} aborted={} current tasks={:?}",
                    round.remaining.load(Ordering::Relaxed),
                    round.active.load(Ordering::Relaxed),
                    round.aborted.load(Ordering::Relaxed),
                    cur
                ));
            }
            pause(&mut spins);
        }
        if debug {
            ROUND_NANOS.fetch_add(t_round.elapsed().as_nanos() as u64, Ordering::Relaxed);
        }
        let warnings = std::mem::take(&mut *round.warnings.lock().unwrap_or_else(|e| e.into_inner()));
        crate::host::record_warnings(warnings);
        let failure = round.failure.lock().unwrap_or_else(|e| e.into_inner()).take();
        match failure {
            None => Ok(()),
            Some(f) => {
                crate::set_engine_error_detail(f.detail);
                if let Some(pa) = f.assert {
                    crate::host::set_pending_assert_raw(pa);
                }
                Err("CodegenWasmJit: wasm engine error")
            }
        }
    }
}

impl Drop for Pool {
    fn drop(&mut self) {
        if debug_enabled() {
            dbg_log(format!(
                "parmod: (clusters, ms in tasks) per participant {:?}; rounds total {} ms",
                CLUSTERS_RUN.lock().unwrap_or_else(|e| e.into_inner()).iter().map(|(c, ns)| (*c, ns / 1_000_000)).collect::<Vec<_>>(),
                ROUND_NANOS.load(Ordering::Relaxed) / 1_000_000
            ));
        }
        {
            let mut st = self.shared.state.lock().unwrap_or_else(|e| e.into_inner());
            st.2 = true;
            st.0 += 1;
            self.shared.generation.store(st.0, Ordering::Release);
            self.shared.cv.notify_all();
        }
        for h in self.threads.drain(..) {
            let _ = h.join();
        }
    }
}

/// A worker's runtime + model instances over `memory`, in a fresh store: the
/// runtime's `start` waits for the main instance's memory initialisation, then the
/// instance gets its own stack and TLS block, and the model instantiates in replay
/// mode against the main instantiation's allocations.
fn instantiate_worker(
    engine: &Engine,
    memory: &SharedMemory,
    runtime: &Module,
    model_module: &Module,
    stack_top: u32,
    mut alloc: impl FnMut(u32) -> Result<u32>,
) -> Result<WorkerCtx> {
    let mut linker = wasmtime::Linker::new(engine);
    crate::host::add_host_builtins(&mut linker)?;
    crate::wasi_shim::add_to_linker(&mut linker)?;
    let mut store = Store::new(engine, WasiCtx::new("/", Vec::new()));
    // The same hard `-alarm` as the run's own store, so a wedged task traps too.
    if let secs @ 1.. = crate::sim_runtime::alarm_secs() {
        store.set_epoch_deadline(secs as u64);
        store.epoch_deadline_callback(|_| Err(wasmtime::Error::msg(crate::sim_driver::ALARM_ABORT_ERR)));
    }
    wts(linker.define(&mut store, "env", "memory", memory.clone()))?;
    let rt_inst = wts(linker.instantiate(&mut store, runtime))?;
    let sp = rt_inst.get_global(&mut store, "__stack_pointer").ok_or("threads runtime exports no __stack_pointer")?;
    wts(sp.set(&mut store, wasmtime::Val::I32(stack_top as i32)))?;
    let tls_size = global_i32(&mut store, &rt_inst, "__tls_size")?;
    let tls_align = global_i32(&mut store, &rt_inst, "__tls_align")?.max(1);
    let tls = alloc(tls_size + tls_align)?;
    let tls = (tls + tls_align - 1) & !(tls_align - 1);
    let init_tls = wts(rt_inst.get_typed_func::<u32, ()>(&mut store, "__wasm_init_tls"))?;
    wts(init_tls.call(&mut store, tls))?;
    let init_thread = wts(rt_inst.get_typed_func::<(), ()>(&mut store, "rt_thread_init"))?;
    wts(init_thread.call(&mut store, ()))?;
    wts(linker.instance(&mut store, "rt", rt_inst))?;
    let mem = SimMem::Shared(memory.clone());
    let str_new = wts(rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_str_new"))?;
    let str_data = wts(rt_inst.get_typed_func::<u32, u32>(&mut store, "rt_str_data"))?;
    crate::sim_runtime::define_print_import(&mut linker, mem.clone())?;
    crate::host::define_uri_import(&mut linker, mem.clone(), str_new, str_data)?;
    let start_mode = wts(rt_inst.get_typed_func::<u32, ()>(&mut store, "rt_start_mode"))?;
    wts(start_mode.call(&mut store, 2))?;
    let instance = linker.instantiate(&mut store, model_module);
    wts(start_mode.call(&mut store, 0))?;
    let instance: Instance = wts(instance)?;
    let task = wts(instance.get_typed_func::<(u32, u32), ()>(&mut store, "parmodTask"))?;
    let flush = wts(rt_inst.get_typed_func::<(), ()>(&mut store, "rt_stats_flush"))?;
    Ok(WorkerCtx { store, task, flush, memory: mem })
}

/// A task call whose out-of-bounds access surfaces as an error: with two instances
/// of one store importing the same memory, wasmtime's signal-based fault handler
/// asserts (`StoreOpaque::wasm_fault`) instead of trapping, and a panic must not
/// take the thread out of the round.
fn call_task(store: &mut Store<WasiCtx>, task: &TypedFunc<(u32, u32), ()>, sim_data: u32, t: u32) -> std::result::Result<(), wasmtime::Error> {
    match std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| task.call(&mut *store, (sim_data, t)))) {
        Ok(r) => r,
        Err(_) => Err(wasmtime::Error::msg("wasm trap: out of bounds memory access (in a shared-memory store)")),
    }
}

fn global_i32(store: &mut Store<WasiCtx>, inst: &Instance, name: &str) -> Result<u32> {
    match inst.get_global(&mut *store, name).map(|g| g.get(&mut *store)) {
        Some(wasmtime::Val::I32(v)) => Ok(v as u32),
        _ => Err(format!("threads runtime exports no {name}")),
    }
}

fn pause(spins: &mut u32) {
    *spins += 1;
    if *spins < 200 {
        std::hint::spin_loop();
    } else {
        std::thread::yield_now();
    }
}

fn worker_main(mut w: WorkerCtx, shared: Arc<Shared>, who: usize) {
    crate::host::set_sim_memory(w.memory.clone());
    let mut seen = 0u64;
    let mut prepared: Option<Prepared> = None;
    loop {
        // Spin briefly for the next round: an ODE evaluation follows the last within
        // microseconds while the integrator is busy; park when it does not.
        let mut spins = 0u32;
        while shared.generation.load(Ordering::Acquire) == seen && spins < 20_000 {
            spins += 1;
            std::hint::spin_loop();
        }
        let round = {
            let mut st = shared.state.lock().unwrap_or_else(|e| e.into_inner());
            while st.0 == seen {
                st = shared.cv.wait(st).unwrap_or_else(|e| e.into_inner());
            }
            seen = st.0;
            if st.2 {
                return;
            }
            let round = st.1.clone();
            if let Some(r) = &round {
                r.active.fetch_add(1, Ordering::AcqRel);
            }
            round
        };
        let Some(round) = round else { continue };
        crate::host::set_no_throw_asserts(round.no_throw);
        let plan = round.plan();
        if prepared.as_ref().is_none_or(|p| p.id != plan.id) {
            prepared = Some(Prepared::new(plan));
        }
        work(&round, prepared.as_ref().expect("prepared plan"), &mut w.store, &w.task, who);
        let _ = w.flush.call(&mut w.store, ());
        let warnings = crate::host::take_pending_warnings();
        if !warnings.is_empty() {
            round.warnings.lock().unwrap_or_else(|e| e.into_inner()).extend(warnings);
        }
        round.active.fetch_sub(1, Ordering::AcqRel);
    }
}

/// Pull ready clusters until the round is over: every cluster done, or aborted.
fn work(round: &Round, prep: &Prepared, store: &mut Store<WasiCtx>, task: &TypedFunc<(u32, u32), ()>, who: usize) {
    let plan = round.plan();
    let mut spins = 0u32;
    let debug = debug_enabled();
    let mut idle_since: Option<std::time::Instant> = None;
    loop {
        if round.aborted.load(Ordering::Acquire) || round.remaining.load(Ordering::Acquire) == 0 {
            return;
        }
        let next = round.queue.lock().unwrap_or_else(|e| e.into_inner()).pop_front();
        let Some(c) = next else {
            if debug {
                let t = idle_since.get_or_insert_with(std::time::Instant::now);
                if t.elapsed().as_secs() >= 5 {
                    let pending: Vec<u32> = round.pending.iter().map(|p| p.load(Ordering::Relaxed)).collect();
                    dbg_log(format!(
                        "parmod stall on {:?}: remaining={} active={} queue={} pending={:?} parents={:?}",
                        std::thread::current().name(),
                        round.remaining.load(Ordering::Relaxed),
                        round.active.load(Ordering::Relaxed),
                        round.queue.lock().unwrap_or_else(|e| e.into_inner()).len(),
                        pending,
                        prep.parents,
                    ));
                    *t = std::time::Instant::now();
                }
            }
            pause(&mut spins);
            continue;
        };
        idle_since = None;
        spins = 0;
        let t_cluster = std::time::Instant::now();
        for &t in &plan.clusters[c as usize] {
            round.current[who].store(t, Ordering::Relaxed);
            // `OMC_WASM_PARMOD_SERIAL`: one task at a time across the pool (debug).
            static SERIAL: Mutex<()> = Mutex::new(());
            let serial = std::env::var_os("OMC_WASM_PARMOD_SERIAL").map(|_| SERIAL.lock().unwrap_or_else(|e| e.into_inner()));
            let r = call_task(store, task, round.sim_data, t);
            drop(serial);
            round.current[who].store(u32::MAX, Ordering::Relaxed);
            if let Err(e) = r {
                if std::env::var_os("OMC_WASM_TRAP_DEBUG").is_some() {
                    dbg_log(format!("wasm-jit parmod task {t} trap: {e:?}"));
                }
                round.fail(Failure { detail: format!("{e:?}"), assert: crate::host::take_pending_assert_raw() });
                return;
            }
        }
        round.finished(prep, c);
        if debug {
            let mut v = CLUSTERS_RUN.lock().unwrap_or_else(|e| e.into_inner());
            if v.len() <= who {
                v.resize(who + 1, (0, 0));
            }
            v[who].0 += 1;
            v[who].1 += t_cluster.elapsed().as_nanos() as u64;
        }
    }
}

/// Debug aid: `kill -USR1 <tid>` appends that thread's native backtrace to the file.
fn install_backtrace_signal() {
    if !debug_enabled() {
        return;
    }
    extern "C" fn on_usr1(_: libc::c_int) {
        dbg_log(format!(
            "parmod backtrace of {:?}:\n{}",
            std::thread::current().name(),
            std::backtrace::Backtrace::force_capture()
        ));
    }
    unsafe {
        libc::signal(libc::SIGUSR1, on_usr1 as *const () as usize);
    }
    let prev = std::panic::take_hook();
    std::panic::set_hook(Box::new(move |info| {
        dbg_log(format!(
            "parmod panic on {:?}: {info}\n{}",
            std::thread::current().name(),
            std::backtrace::Backtrace::force_capture()
        ));
        prev(info);
    }));
}

/// `OMC_WASM_PARMOD_DEBUG=<file>`: pool diagnostics, appended there (stderr is
/// captured into the simulation log during a run).
fn debug_enabled() -> bool {
    std::env::var_os("OMC_WASM_PARMOD_DEBUG").is_some()
}

fn dbg_log(line: String) {
    use std::io::Write;
    let Some(path) = std::env::var_os("OMC_WASM_PARMOD_DEBUG") else { return };
    if let Ok(mut f) = std::fs::OpenOptions::new().append(true).create(true).open(path) {
        let _ = writeln!(f, "{line}");
    }
}
