//! Size the JIT linear-memory reservation to the address-space budget: wasmtime
//! reserves 4 GiB per 32-bit memory (plus guards, plus 2 GiB when one moves),
//! which a `ulimit -v` counts.

const MIB: u64 = 1 << 20;
const GIB: u64 = 1 << 30;
// wasmtime's defaults.
const FULL_RESERVATION: u64 = 4 * GIB;
const GUARD: u64 = 32 * MIB;
const GROWTH: u64 = 2 * GIB;
const HOST_HEADROOM: u64 = GIB;
const MIN_RESERVATION: u64 = 64 * MIB;

struct Budget {
    reservation: u64,
    growth: u64,
}

fn budget() -> Option<Budget> {
    if let Ok(s) = std::env::var("OMC_WASM_MEMORY_RESERVATION_MB") {
        if let Ok(mb) = s.trim().parse::<u64>() {
            let reservation = mb * MIB;
            return Some(Budget { reservation, growth: reservation.min(GROWTH) });
        }
    }
    let limit = address_space_limit()?;
    let avail = limit.saturating_sub(vm_size()).saturating_sub(HOST_HEADROOM);
    // The session's runtime and its model can hold two memories at once.
    let per_memory = avail / 2;
    if per_memory >= FULL_RESERVATION + 2 * GUARD + GROWTH {
        return None;
    }
    let reservation = (per_memory / 2).clamp(MIN_RESERVATION, FULL_RESERVATION - 64 * MIB) & !(64 * 1024 - 1);
    Some(Budget { reservation, growth: reservation })
}

#[cfg(target_os = "linux")]
fn address_space_limit() -> Option<u64> {
    unsafe {
        let mut rl: libc::rlimit = std::mem::zeroed();
        if libc::getrlimit(libc::RLIMIT_AS, &mut rl) == 0 && rl.rlim_cur != libc::RLIM_INFINITY {
            return Some(rl.rlim_cur as u64);
        }
    }
    None
}

#[cfg(not(target_os = "linux"))]
fn address_space_limit() -> Option<u64> {
    None
}

#[cfg(target_os = "linux")]
fn vm_size() -> u64 {
    let pages = std::fs::read_to_string("/proc/self/statm")
        .ok()
        .and_then(|s| s.split_whitespace().next()?.parse::<u64>().ok())
        .unwrap_or(0);
    pages * unsafe { libc::sysconf(libc::_SC_PAGESIZE) }.max(0) as u64
}

#[cfg(not(target_os = "linux"))]
fn vm_size() -> u64 {
    0
}

/// `memory_may_move` (default on) lets a memory outgrow the reservation.
pub fn tune_memory(cfg: &mut wasmtime::Config) {
    if let Some(b) = budget() {
        cfg.memory_reservation(b.reservation);
        cfg.memory_reservation_for_growth(b.growth);
    }
}
