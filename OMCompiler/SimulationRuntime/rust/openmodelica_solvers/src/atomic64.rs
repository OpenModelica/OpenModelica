//! `AtomicU64` where the target has one. Without (armv5te), a plain cell: the
//! runtime is single-threaded there, as `parmod::can_parallel` makes sure.

#[cfg(target_has_atomic = "64")]
pub use core::sync::atomic::AtomicU64;

#[cfg(not(target_has_atomic = "64"))]
pub struct AtomicU64(core::cell::Cell<u64>);

#[cfg(not(target_has_atomic = "64"))]
unsafe impl Sync for AtomicU64 {}

#[cfg(not(target_has_atomic = "64"))]
impl AtomicU64 {
    pub const fn new(v: u64) -> Self {
        Self(core::cell::Cell::new(v))
    }

    pub fn load(&self, _: core::sync::atomic::Ordering) -> u64 {
        self.0.get()
    }

    pub fn store(&self, v: u64, _: core::sync::atomic::Ordering) {
        self.0.set(v)
    }

    pub fn swap(&self, v: u64, _: core::sync::atomic::Ordering) -> u64 {
        self.0.replace(v)
    }

    pub fn fetch_add(&self, v: u64, _: core::sync::atomic::Ordering) -> u64 {
        let old = self.0.get();
        self.0.set(old.wrapping_add(v));
        old
    }
}
