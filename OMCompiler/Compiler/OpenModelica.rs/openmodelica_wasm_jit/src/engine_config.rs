//! Size the JIT linear-memory reservation to the `RLIMIT_AS` budget.

const FAST_PATH_MIN_AS: u64 = 8 * 1024 * 1024 * 1024;
const CONSTRAINED_MIB: u64 = 256;

fn reservation_bytes() -> Option<u64> {
    if let Ok(s) = std::env::var("OMC_WASM_MEMORY_RESERVATION_MB") {
        if let Ok(mb) = s.trim().parse::<u64>() {
            return Some(mb * 1024 * 1024);
        }
    }
    match address_space_limit() {
        Some(limit) if limit < FAST_PATH_MIN_AS => Some(CONSTRAINED_MIB * 1024 * 1024),
        _ => None,
    }
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

/// A shared memory cannot move, so it is capped at the reservation it starts with:
/// wasm32's 4 GiB, or the constrained one under a small `RLIMIT_AS`.
pub fn shared_max_pages() -> u64 {
    match reservation_bytes() {
        Some(bytes) => (bytes / 65536).max(1),
        None => 65536,
    }
}

/// `memory_may_move` (default on) lets a memory outgrow the reservation.
pub fn tune_memory(cfg: &mut wasmtime::Config) {
    if let Some(bytes) = reservation_bytes() {
        cfg.memory_reservation(bytes);
    }
}
