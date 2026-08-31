//! The run's wall clock (ms).
//!
//! A host may inject one (wasm `performance.now`, or the in-wasm runtime's own
//! timer) via [`set_clock`]; the native/std build otherwise falls back to
//! `Instant`. wasm has no usable `Instant`, so there the hook is required --
//! unset reads 0, and any finite deadline then fires at once (safe but chatty).

use core::sync::atomic::{AtomicUsize, Ordering};

static CLOCK: AtomicUsize = AtomicUsize::new(0);

pub fn set_clock(f: fn() -> f64) {
    CLOCK.store(f as usize, Ordering::Relaxed);
}

pub fn now_ms() -> f64 {
    let p = CLOCK.load(Ordering::Relaxed);
    if p != 0 {
        let f: fn() -> f64 = unsafe { core::mem::transmute(p) };
        return f();
    }
    #[cfg(all(feature = "std", not(target_arch = "wasm32")))]
    {
        use std::time::Instant;
        static START: std::sync::OnceLock<Instant> = std::sync::OnceLock::new();
        return START.get_or_init(Instant::now).elapsed().as_secs_f64() * 1000.0;
    }
    #[cfg(not(all(feature = "std", not(target_arch = "wasm32"))))]
    0.0
}
