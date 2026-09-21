//! A heap ceiling the compiler can recover from, standing in for the C
//! runtime's `omc_GC_set_max_heap_size` + `mmc_do_out_of_memory`.
//!
//! A watchdog samples what the OS reports the process using; past the ceiling it
//! flags a trip that the next allocation turns into an [`OutOfMemory`] unwind,
//! caught at a `__OpenModelica_stackOverflowCheckpoint`. Sampling keeps this off
//! the hot path — an allocation pays one relaxed load, not a thread-local
//! update — at the cost of up to [`SAMPLE`] of overshoot.

use std::alloc::{GlobalAlloc, Layout};
use std::sync::atomic::{AtomicBool, AtomicU8, AtomicUsize, Ordering::Relaxed};
use std::time::Duration;

/// Payload of the panic raised when the ceiling is crossed.
#[derive(Clone, Copy, Debug)]
pub struct OutOfMemory {
    pub used: usize,
    pub limit: usize,
    /// Which budget was exhausted, for the message.
    pub what: &'static str,
}

impl std::fmt::Display for OutOfMemory {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "Out of memory: {} MB of {} exceeds the {} MB limit \
             (raise it with GC_set_max_heap_size or OPENMODELICA_MAX_HEAP_MB; 0 disables it)",
            self.used >> 20,
            self.what,
            self.limit >> 20
        )
    }
}

const SAMPLE: Duration = Duration::from_millis(100);
const BIG: usize = 32 << 20;
/// Growth past a caught trip before tripping again. Recovery frees the failed
/// translation but not the libraries loaded before it, so a session can sit
/// above the ceiling afterwards without that being a new runaway.
const REGROWTH: usize = 256 << 20;

const WHAT_RESIDENT: u8 = 0;
const WHAT_MAPPED: u8 = 1;

/// Ceiling on resident memory; 0 when there is none.
static LIMIT: AtomicUsize = AtomicUsize::new(0);
/// From `RLIMIT_AS`; separate from [`LIMIT`] because exceeding it aborts.
static AS_LIMIT: AtomicUsize = AtomicUsize::new(0);

/// Set once a sample is over a ceiling: the next allocation unwinds.
static PENDING: AtomicBool = AtomicBool::new(false);
/// Held across the unwind and the recovery, which allocate.
static TRIPPED: AtomicBool = AtomicBool::new(false);

/// The level a caught trip settled at, so it does not keep tripping; 0 = none.
static FLOOR: AtomicUsize = AtomicUsize::new(0);
static AS_FLOOR: AtomicUsize = AtomicUsize::new(0);

static PENDING_USED: AtomicUsize = AtomicUsize::new(0);
static PENDING_LIMIT: AtomicUsize = AtomicUsize::new(0);
static PENDING_WHAT: AtomicU8 = AtomicU8::new(WHAT_RESIDENT);

/// True while recovery is running, where the ceiling is disarmed. Code that
/// allocates heavily should stand down: nothing would stop it here.
pub fn recovering() -> bool {
    TRIPPED.load(Relaxed)
}

/// The ceiling on resident memory in bytes; 0 means unlimited.
pub fn max_heap_size() -> usize {
    LIMIT.load(Relaxed)
}

/// Bytes of resident memory; 0 lifts every ceiling. Backs `GCExt.setMaxHeapSize`.
pub fn set_max_heap_size(bytes: usize) {
    arm(bytes);
}

fn arm(limit: usize) {
    let limit = if limit != 0 && measurable() { limit } else { 0 };
    LIMIT.store(limit, Relaxed);
    AS_LIMIT.store(if limit == 0 { 0 } else { address_space_headroom() }, Relaxed);
    if limit != 0 {
        start_watchdog();
    }
}

/// Arm the default ceiling. Call once at startup; without it nothing is capped.
pub fn init() {
    install_panic_hook();
    arm(env_limit().unwrap_or_else(|| physical_memory() / 5 * 4));
}

static RELEASE: AtomicUsize = AtomicUsize::new(0);

/// Register the allocator's "return memory to the OS" call (`mi_collect`,
/// `malloc_trim`). Without it the pages an unwind frees stay mapped and the
/// process never drops back under the ceiling.
pub fn set_release_fn(f: fn()) {
    RELEASE.store(f as usize, Relaxed);
}

/// Hand back what the allocator is still holding, through whatever
/// [`set_release_fn`] registered. Does nothing if the process registered
/// nothing. For a caller that allocates in bulk and can pay the syscalls.
pub fn release() {
    let p = RELEASE.load(Relaxed);
    if p != 0 {
        // SAFETY: only ever stored by `set_release_fn` from a `fn()`.
        let f: fn() = unsafe { std::mem::transmute(p) };
        f();
    }
}

/// Arm the ceiling again once recovery is done, above whatever the process
/// could not hand back.
pub fn rearm() {
    release();
    let (resident, mapped) = footprint();
    if resident != 0 {
        let raise = |cur: &AtomicUsize, used: usize, limit: usize| {
            if limit != 0 && used >= limit {
                cur.store(used.saturating_add(REGROWTH), Relaxed);
            }
        };
        raise(&FLOOR, resident, LIMIT.load(Relaxed));
        raise(&AS_FLOOR, mapped, AS_LIMIT.load(Relaxed));
    }
    PENDING.store(false, Relaxed);
    TRIPPED.store(false, Relaxed);
}

/// Arms the ceiling on scope exit. A recovery branch may `fail()` or `return`
/// rather than reach its end, so this cannot be a statement after the body.
pub struct RearmOnDrop;

impl Drop for RearmOnDrop {
    fn drop(&mut self) {
        rearm();
    }
}

/// Run `f`, turning a ceiling trip into `Err(OutOfMemory)`; any other panic is
/// resumed. Returns still disarmed — a trip inside the caller's recovery would
/// be past this catch and would escape outwards — so the caller holds a
/// [`RearmOnDrop`] for the duration of its recovery.
pub fn catch<R, F: FnOnce() -> R>(f: F) -> Result<R, OutOfMemory> {
    match std::panic::catch_unwind(std::panic::AssertUnwindSafe(f)) {
        Ok(r) => Ok(r),
        Err(payload) => match payload.downcast::<OutOfMemory>() {
            Ok(oom) => Err(*oom),
            Err(payload) => std::panic::resume_unwind(payload),
        },
    }
}

/// [`catch`] for a caller that already holds a caught panic's payload. `None`
/// if it was an ordinary panic, which stays the caller's to handle.
pub fn oom_from_panic(payload: &(dyn std::any::Any + Send)) -> Option<OutOfMemory> {
    let oom = *payload.downcast_ref::<OutOfMemory>()?;
    rearm();
    Some(oom)
}

/// Suppress the default hook for [`OutOfMemory`]; the trip printed its own
/// message. Idempotent.
pub fn install_panic_hook() {
    use std::sync::Once;
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        let prev = std::panic::take_hook();
        std::panic::set_hook(Box::new(move |info| {
            if info.payload().is::<OutOfMemory>() {
                return;
            }
            prev(info);
        }));
    });
}

fn start_watchdog() {
    use std::sync::Once;
    static ONCE: Once = Once::new();
    ONCE.call_once(|| {
        let _ = std::thread::Builder::new().name("omc-heap-watch".into()).spawn(|| {
            loop {
                std::thread::sleep(SAMPLE);
                if !PENDING.load(Relaxed) && !TRIPPED.load(Relaxed) {
                    sample();
                }
            }
        });
    });
}

/// Flag a trip if the process is over a ceiling. `extra` is a block about to be
/// requested: one big enough to clear the ceiling by itself has to be judged on
/// where it would land, not where the process is now.
fn sample_with(extra: usize) {
    let (resident, mapped) = footprint();
    if resident == 0 {
        return;
    }
    let (resident, mapped) = (resident.saturating_add(extra), mapped.saturating_add(extra));
    let limit = LIMIT.load(Relaxed);
    let as_limit = AS_LIMIT.load(Relaxed);
    if limit != 0 && resident < limit {
        FLOOR.store(0, Relaxed);
    }
    if as_limit != 0 && mapped < as_limit {
        AS_FLOOR.store(0, Relaxed);
    }
    let limit = limit.max(FLOOR.load(Relaxed));
    let as_limit = if as_limit == 0 { 0 } else { as_limit.max(AS_FLOOR.load(Relaxed)) };
    let (used, limit, what) = if limit != 0 && resident > limit {
        (resident, limit, WHAT_RESIDENT)
    } else if as_limit != 0 && mapped > as_limit {
        (mapped, as_limit, WHAT_MAPPED)
    } else {
        return;
    };
    PENDING_USED.store(used, Relaxed);
    PENDING_LIMIT.store(limit, Relaxed);
    PENDING_WHAT.store(what, Relaxed);
    PENDING.store(true, Relaxed);
}

fn sample() {
    sample_with(0)
}

#[cold]
fn trip() -> ! {
    // The unwind, the message and every `Drop` on the way out allocate.
    TRIPPED.store(true, Relaxed);
    PENDING.store(false, Relaxed);
    let oom = OutOfMemory {
        used: PENDING_USED.load(Relaxed),
        limit: PENDING_LIMIT.load(Relaxed),
        what: match PENDING_WHAT.load(Relaxed) {
            WHAT_MAPPED => "mapped address space",
            _ => "resident memory",
        },
    };
    eprintln!("{oom}");
    std::panic::panic_any(oom)
}

/// Physical memory, as reported by the OS. 0 when it does not say.
#[cfg(unix)]
fn physical_memory() -> usize {
    unsafe {
        let pages = libc::sysconf(libc::_SC_PHYS_PAGES);
        let page = libc::sysconf(libc::_SC_PAGESIZE);
        if pages > 0 && page > 0 { (pages as usize).saturating_mul(page as usize) } else { 0 }
    }
}

/// `RLIMIT_AS` less a tenth, so the unwind and the reporting after it still
/// have room to allocate. 0 when the limit is unlimited.
#[cfg(unix)]
fn address_space_headroom() -> usize {
    let mut rl = libc::rlimit { rlim_cur: 0, rlim_max: 0 };
    if unsafe { libc::getrlimit(libc::RLIMIT_AS, &mut rl) } != 0 || rl.rlim_cur == libc::RLIM_INFINITY
    {
        return 0;
    }
    usize::try_from(rl.rlim_cur).unwrap_or(usize::MAX) / 10 * 9
}

#[cfg(windows)]
fn physical_memory() -> usize {
    use windows_sys::Win32::System::SystemInformation::{GlobalMemoryStatusEx, MEMORYSTATUSEX};
    let mut st: MEMORYSTATUSEX = unsafe { std::mem::zeroed() };
    st.dwLength = size_of::<MEMORYSTATUSEX>() as u32;
    if unsafe { GlobalMemoryStatusEx(&mut st) } == 0 {
        return 0;
    }
    usize::try_from(st.ullTotalPhys).unwrap_or(usize::MAX)
}

#[cfg(not(any(unix, windows)))]
fn physical_memory() -> usize {
    0
}

#[cfg(not(unix))]
fn address_space_headroom() -> usize {
    0
}

/// `virtual_size` counts every reserved mapping, so it is only ever compared
/// against `RLIMIT_AS`, which macOS leaves unlimited.
#[cfg(target_os = "macos")]
fn footprint() -> (usize, usize) {
    let mut info: libc::mach_task_basic_info = unsafe { std::mem::zeroed() };
    let mut count = (size_of::<libc::mach_task_basic_info>() / size_of::<libc::natural_t>())
        as libc::mach_msg_type_number_t;
    let rc = unsafe {
        libc::task_info(
            libc::mach_task_self(),
            libc::MACH_TASK_BASIC_INFO as libc::task_flavor_t,
            (&raw mut info).cast(),
            &mut count,
        )
    };
    if rc != libc::KERN_SUCCESS {
        return (0, 0);
    }
    (info.resident_size as usize, info.virtual_size as usize)
}

#[cfg(windows)]
fn footprint() -> (usize, usize) {
    use windows_sys::Win32::System::ProcessStatus::{
        GetProcessMemoryInfo, PROCESS_MEMORY_COUNTERS,
    };
    use windows_sys::Win32::System::Threading::GetCurrentProcess;
    let mut c: PROCESS_MEMORY_COUNTERS = unsafe { std::mem::zeroed() };
    c.cb = size_of::<PROCESS_MEMORY_COUNTERS>() as u32;
    if unsafe { GetProcessMemoryInfo(GetCurrentProcess(), &mut c, c.cb) } == 0 {
        return (0, 0);
    }
    (c.WorkingSetSize, c.PagefileUsage)
}

fn env_limit() -> Option<usize> {
    let mb = std::env::var("OPENMODELICA_MAX_HEAP_MB").ok()?;
    Some(mb.trim().parse::<usize>().ok()?.saturating_mul(1 << 20))
}

/// Resident and mapped size in bytes, 0/0 where the platform does not say.
/// Reads into a stack buffer: a big allocation probes this from inside the
/// global allocator, so it must not allocate.
#[cfg(target_os = "linux")]
fn footprint() -> (usize, usize) {
    use std::sync::atomic::AtomicI32;
    static FD: AtomicI32 = AtomicI32::new(-1);

    let mut fd = FD.load(Relaxed);
    if fd < 0 {
        fd = unsafe { libc::open(c"/proc/self/statm".as_ptr(), libc::O_RDONLY | libc::O_CLOEXEC) };
        if fd < 0 {
            return (0, 0);
        }
        if FD.compare_exchange(-1, fd, Relaxed, Relaxed).is_err() {
            unsafe { libc::close(fd) };
            fd = FD.load(Relaxed);
        }
    }
    let mut buf = [0u8; 64];
    let n = unsafe { libc::pread(fd, buf.as_mut_ptr().cast(), buf.len() - 1, 0) };
    if n <= 0 {
        return (0, 0);
    }
    // "size resident shared text lib data dt", in pages.
    let mut it = buf[..n as usize].split(|b| *b == b' ').map(|f| {
        f.iter()
            .take_while(|b| b.is_ascii_digit())
            .fold(0usize, |a, b| a.wrapping_mul(10).wrapping_add((b - b'0') as usize))
    });
    let page = unsafe { libc::sysconf(libc::_SC_PAGESIZE) } as usize;
    match (it.next(), it.next()) {
        (Some(size), Some(resident)) => (resident.saturating_mul(page), size.saturating_mul(page)),
        _ => (0, 0),
    }
}

#[cfg(not(any(target_os = "linux", target_os = "macos", windows)))]
fn footprint() -> (usize, usize) {
    (0, 0)
}

/// A ceiling only means something where [`footprint`] reports; arming without
/// it would spin a watchdog that can never trip and claim a cap that is not
/// there.
fn measurable() -> bool {
    footprint().0 != 0
}

/// Global allocator wrapper that unwinds once the process is over its ceiling.
pub struct Limited<A>(pub A);

impl<A> Limited<A> {
    #[inline]
    fn check(size: usize) {
        if PENDING.load(Relaxed) {
            trip();
        }
        // One block big enough to clear the ceiling on its own would otherwise
        // not be noticed until the next sample, which may be too late.
        if size >= BIG && !TRIPPED.load(Relaxed) {
            sample_with(size);
            if PENDING.load(Relaxed) {
                trip();
            }
        }
    }
}

unsafe impl<A: GlobalAlloc> GlobalAlloc for Limited<A> {
    #[inline]
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        Self::check(layout.size());
        unsafe { self.0.alloc(layout) }
    }

    #[inline]
    unsafe fn alloc_zeroed(&self, layout: Layout) -> *mut u8 {
        Self::check(layout.size());
        unsafe { self.0.alloc_zeroed(layout) }
    }

    #[inline]
    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        unsafe { self.0.dealloc(ptr, layout) };
    }

    #[inline]
    unsafe fn realloc(&self, ptr: *mut u8, layout: Layout, new_size: usize) -> *mut u8 {
        if new_size > layout.size() {
            Self::check(new_size);
        }
        unsafe { self.0.realloc(ptr, layout, new_size) }
    }
}

#[cfg(all(test, target_os = "linux"))]
mod tests {
    #[test]
    fn footprint_matches_proc_status() {
        let (resident, mapped) = super::footprint();
        let status = std::fs::read_to_string("/proc/self/status").unwrap();
        let kb = |key: &str| -> usize {
            status
                .lines()
                .find(|l| l.starts_with(key))
                .and_then(|l| l.split_whitespace().nth(1))
                .unwrap()
                .parse::<usize>()
                .unwrap()
                * 1024
        };
        assert!(resident.abs_diff(kb("VmRSS:")) < 4 << 20);
        assert!(mapped.abs_diff(kb("VmSize:")) < 4 << 20);
    }
}
