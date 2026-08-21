//! The thread pool oxiblas's kernels run in.
//!
//! oxiblas takes its width from `rayon::current_num_threads()`, which left alone
//! is rayon's global pool — one thread per core, ignoring `-n`. So the pool is
//! ours and [`install`] runs the kernels inside it. Set once: the limit is
//! process-wide. Without the `parallel` feature this all compiles away.

#[cfg(feature = "parallel")]
static POOL: std::sync::OnceLock<Option<rayon::ThreadPool>> = std::sync::OnceLock::new();

/// Cap the threads oxiblas may use; `0` asks for one per core. Only the first
/// call has any effect; until then [`install`] runs on the caller.
pub fn set_max_threads(n: usize) {
    #[cfg(feature = "parallel")]
    POOL.get_or_init(|| {
        let want = if n == 0 {
            std::thread::available_parallelism().map(|p| p.get()).unwrap_or(1)
        } else {
            n
        };
        if want <= 1 {
            // Also covers kernels reached by a path `install` does not wrap.
            oxiblas_core::parallel::disable_global_parallelism();
            return None; // a 1-thread pool would still round-trip via a worker
        }
        rayon::ThreadPoolBuilder::new()
            .num_threads(want)
            .thread_name(|i| format!("omc-lapack-{i}"))
            .build()
            .ok()
    });
    #[cfg(not(feature = "parallel"))]
    let _ = n;
}

/// Run `f` on that pool. Falls back to the calling thread when the limit is one,
/// none was set, or the pool could not be built.
pub fn install<T: Send>(f: impl FnOnce() -> T + Send) -> T {
    #[cfg(feature = "parallel")]
    if let Some(pool) = POOL.get().and_then(Option::as_ref) {
        return pool.install(f);
    }
    f()
}
