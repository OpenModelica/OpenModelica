//! What the process is using, asked of the allocator that has it: jemalloc is
//! linked with its symbols prefixed `_rjem_`, so glibc's `mallinfo2` reports
//! an empty heap and `malloc_trim` has nothing to give back.
//!
//! Budget against [`live`], not address space: jemalloc retains freed extents
//! rather than unmapping them, so mapped memory only ever grows. `retain:false`
//! would make the two agree, but then the process runs out of
//! `vm.max_map_count`, and a failed munmap leaks the mapping.

#[cfg(feature = "jemalloc")]
mod imp {
    use std::ffi::c_void;

    /// Statistics are cached until the epoch is advanced, so every read starts
    /// with one.
    fn refresh() {
        let mut epoch: u64 = 1;
        let mut size = size_of::<u64>();
        unsafe {
            tikv_jemalloc_sys::mallctl(
                c"epoch".as_ptr(),
                (&raw mut epoch).cast::<c_void>(),
                &mut size,
                (&raw mut epoch).cast::<c_void>(),
                size_of::<u64>(),
            );
        }
    }

    /// `None` when jemalloc has no such statistic, which is not zero.
    fn stat(name: &std::ffi::CStr) -> Option<u64> {
        let mut value: usize = 0;
        let mut size = size_of::<usize>();
        let read = unsafe {
            tikv_jemalloc_sys::mallctl(
                name.as_ptr(),
                (&raw mut value).cast::<c_void>(),
                &mut size,
                std::ptr::null_mut(),
                0,
            )
        };
        (read == 0).then_some(value as u64)
    }

    /// Bytes in extents that hold live allocations: what falls when a scope is
    /// dropped.
    pub fn live() -> u64 {
        refresh();
        stat(c"stats.active").unwrap_or(0)
    }

    /// Allocated, active, mapped, retained.
    pub fn stats() -> (u64, u64, u64, u64) {
        refresh();
        let of = |name| stat(name).unwrap_or(0);
        (
            of(c"stats.allocated"),
            of(c"stats.active"),
            of(c"stats.mapped"),
            of(c"stats.retained"),
        )
    }

    /// Whether live memory has passed `budget`. `thread.allocated` is a
    /// thread-local load, while [`live`] advances the epoch, taking jemalloc's
    /// control lock and aggregating every arena, so a thread asks that only
    /// once it has allocated enough to have moved the answer.
    pub fn over(budget: u64) -> bool {
        const PROBE: u64 = 128 << 20;
        std::thread_local! {
            static PROBED: std::cell::Cell<u64> = const { std::cell::Cell::new(0) };
        }
        let Some(allocated) = stat(c"thread.allocated") else {
            return live() > budget;
        };
        if allocated.saturating_sub(PROBED.get()) < PROBE {
            return false;
        }
        PROBED.set(allocated);
        live() > budget
    }

    /// Hand back every dirty page in every arena. `MALLCTL_ARENAS_ALL` is 4096.
    pub fn release() {
        unsafe {
            tikv_jemalloc_sys::mallctl(
                c"arena.4096.purge".as_ptr(),
                std::ptr::null_mut(),
                std::ptr::null_mut(),
                std::ptr::null_mut(),
                0,
            );
        }
    }
}

#[cfg(not(feature = "jemalloc"))]
mod imp {
    unsafe extern "C" {
        fn malloc_trim(pad: usize) -> i32;
        fn mallinfo2() -> MallInfo2;
    }

    #[repr(C)]
    struct MallInfo2 {
        arena: usize,
        ordblks: usize,
        smblks: usize,
        hblks: usize,
        hblkhd: usize,
        usmblks: usize,
        fsmblks: usize,
        uordblks: usize,
        fordblks: usize,
        keepcost: usize,
    }

    pub fn live() -> u64 {
        let info = unsafe { mallinfo2() };
        (info.uordblks + info.hblkhd) as u64
    }

    pub fn stats() -> (u64, u64, u64, u64) {
        let info = unsafe { mallinfo2() };
        ((info.uordblks + info.hblkhd) as u64, live(), info.arena as u64, 0)
    }

    /// `mallinfo2` walks every free chunk in every arena, and there is no
    /// cheap counter to gate it on, so it is asked every tenth class.
    pub fn over(budget: u64) -> bool {
        std::thread_local! {
            static SINCE: std::cell::Cell<u32> = const { std::cell::Cell::new(0) };
        }
        let due = SINCE.with(|since| {
            let n = since.get() + 1;
            since.set(if n >= 10 { 0 } else { n });
            n >= 10
        });
        due && live() > budget
    }

    pub fn release() {
        unsafe { malloc_trim(0) };
    }
}

pub use imp::{over, release, stats};

pub fn resident() -> u64 {
    let Ok(text) = std::fs::read_to_string("/proc/self/statm") else {
        return 0;
    };
    let resident: u64 = text
        .split_whitespace()
        .nth(1)
        .and_then(|v| v.parse().ok())
        .unwrap_or(0);
    resident * 4096
}
