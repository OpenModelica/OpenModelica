//! Timing and the synthetic load that stands in for a simulation step.

use std::hint::black_box;
use std::time::{Duration, Instant};

/// Wall and CPU time over one phase. CPU time separates the work a format does
/// from the time it waits for the device.
#[derive(Clone, Copy, Default)]
pub struct Span {
    pub wall: Duration,
    pub user: Duration,
    /// Kernel time, which on the write side is the I/O.
    pub sys: Duration,
}

impl Span {
    pub fn ms(self) -> f64 {
        self.wall.as_secs_f64() * 1e3
    }
    pub fn sys_ms(self) -> f64 {
        self.sys.as_secs_f64() * 1e3
    }
}

impl std::ops::Add for Span {
    type Output = Span;
    fn add(self, o: Span) -> Span {
        Span { wall: self.wall + o.wall, user: self.user + o.user, sys: self.sys + o.sys }
    }
}

impl std::ops::AddAssign for Span {
    fn add_assign(&mut self, o: Span) {
        *self = *self + o;
    }
}

pub struct Stopwatch {
    wall: Instant,
    user: Duration,
    sys: Duration,
}

impl Stopwatch {
    pub fn start() -> Stopwatch {
        let (user, sys) = cpu_time();
        Stopwatch { wall: Instant::now(), user, sys }
    }

    pub fn stop(self) -> Span {
        let (user, sys) = cpu_time();
        Span {
            wall: self.wall.elapsed(),
            user: user.saturating_sub(self.user),
            sys: sys.saturating_sub(self.sys),
        }
    }
}

pub fn timed<T>(f: impl FnOnce() -> T) -> (T, Span) {
    let w = Stopwatch::start();
    let v = f();
    (v, w.stop())
}

/// Bytes the C allocator currently has handed out. Unlike resident memory this
/// does not count what the allocator is holding back for reuse, so the
/// difference across one reader is the memory that reader is keeping - which is
/// the whole difference between a reader that decodes a file at open and one
/// that fetches a column at a time. HDF5, arrow-rs and Rust all allocate
/// through it here.
pub fn heap_in_use_bytes() -> u64 {
    // SAFETY: mallinfo2 reads the allocator's own counters and takes nothing.
    unsafe { libc::mallinfo2() }.uordblks as u64
}

/// The name of the filesystem `path` is on. Every write number depends on it,
/// and a container's overlay mount behaves nothing like the disk under it.
pub fn filesystem(path: &str) -> String {
    use std::os::unix::ffi::OsStrExt;
    let Ok(c) = std::ffi::CString::new(std::path::Path::new(path).as_os_str().as_bytes()) else {
        return "unknown".into();
    };
    let mut s: libc::statfs = unsafe { std::mem::zeroed() };
    if unsafe { libc::statfs(c.as_ptr(), &mut s) } != 0 {
        return "unknown".into();
    }
    // The magic numbers are in `statfs(2)`; only the ones a build tree is
    // plausibly on are named.
    match s.f_type as i64 {
        0xef53 => "ext2/3/4".into(),
        0x9123683e => "btrfs".into(),
        0x58465342 => "xfs".into(),
        0x01021994 => "tmpfs (in memory)".into(),
        0x794c7630 => "overlayfs".into(),
        0x6969 => "nfs".into(),
        0x2fc12fc1 => "zfs".into(),
        0xff534d42 => "cifs".into(),
        other => format!("0x{other:x}"),
    }
}

/// User and system time of the whole process.
fn cpu_time() -> (Duration, Duration) {
    let mut u: libc::rusage = unsafe { std::mem::zeroed() };
    if unsafe { libc::getrusage(libc::RUSAGE_SELF, &mut u) } != 0 {
        return (Duration::ZERO, Duration::ZERO);
    }
    let to_dur = |t: libc::timeval| Duration::new(t.tv_sec as u64, t.tv_usec as u32 * 1000);
    (to_dur(u.ru_utime), to_dur(u.ru_stime))
}

/// A busy loop calibrated to a wall-clock duration: the stand-in for the
/// integration step between two result rows. It has to burn CPU rather than
/// sleep, so the writer competes with it for cache and memory bandwidth exactly
/// as it does inside a simulation.
pub struct Spinner {
    /// Loop iterations per nanosecond, measured at construction.
    per_ns: f64,
}

impl Spinner {
    pub fn calibrate() -> Spinner {
        // Warm up first: the first pass pays for the branch predictor and the
        // frequency ramp, and would halve the measured rate.
        for _ in 0..3 {
            burn(1 << 20);
        }
        let mut best = f64::MAX;
        for _ in 0..5 {
            let n = 1 << 22;
            let t = Instant::now();
            burn(n);
            let ns = t.elapsed().as_secs_f64() * 1e9;
            best = best.min(ns / n as f64);
        }
        Spinner { per_ns: 1.0 / best }
    }

    pub fn spin(&self, ns: u64) {
        if ns == 0 {
            return;
        }
        burn((ns as f64 * self.per_ns) as u64);
    }

    /// The rate, so the report can state how the delay was produced.
    pub fn iters_per_us(&self) -> f64 {
        self.per_ns * 1e3
    }
}

/// The loop itself: a dependent chain, so neither the compiler nor the
/// out-of-order engine can collapse it.
#[inline(never)]
fn burn(iters: u64) {
    let mut x = 1u64;
    for _ in 0..iters {
        x = black_box(x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407));
    }
    black_box(x);
}

/// The median of a sample, and the spread the report quotes with it.
pub struct Stats {
    pub min: f64,
    pub median: f64,
    pub max: f64,
}

impl Stats {
    pub fn of(values: &[f64]) -> Stats {
        let mut v = values.to_vec();
        v.sort_by(f64::total_cmp);
        let median = match v.len() {
            0 => 0.0,
            n if n % 2 == 1 => v[n / 2],
            n => (v[n / 2 - 1] + v[n / 2]) / 2.0,
        };
        Stats {
            min: v.first().copied().unwrap_or(0.0),
            median,
            max: v.last().copied().unwrap_or(0.0),
        }
    }

    /// Half the min-max span as a percentage of the median: a spread this wide
    /// means the number should not be read too closely.
    pub fn spread_pct(&self) -> f64 {
        if self.median == 0.0 {
            return 0.0;
        }
        (self.max - self.min) / 2.0 / self.median * 100.0
    }
}
