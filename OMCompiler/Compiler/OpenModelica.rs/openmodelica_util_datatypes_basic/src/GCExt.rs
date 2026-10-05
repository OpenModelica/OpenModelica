// Manually written file
#![allow(warnings)]
#![allow(unreachable_patterns, unreachable_code, non_camel_case_types, non_snake_case, dead_code, unused_imports, unused_variables, non_upper_case_globals, unused_mut)]

use std::sync::Arc;
use arcstr::ArcStr;
use metamodelica::Result;
use loop_unwrap::unwrap_break_err;
use metamodelica::*; // Built-in types and functions
use const_str;

/// The Rust port has real weak semantics, so a cell needs an explicit owner.
pub const cellsNeedOwners: bool = true;

#[derive(Clone, Debug, Default, PartialEq, Eq, Hash)]
pub struct ProfStats {
    pub heapsize_full: i32,
    pub free_bytes_full: i32,
    pub unmapped_bytes: i32,
    pub bytes_allocd_since_gc: i32,
    pub allocd_bytes_before_gc: i32,
    pub non_gc_bytes: i32,
    pub gc_no: i32,
    pub markers_m1: i32,
    pub bytes_reclaimed_since_gc: i32,
    pub reclaimed_bytes_before_gc: i32,
}

pub type PROFSTATS = ProfStats;


pub fn disable() {}

pub fn enable() {}

pub fn expandHeap(sz: metamodelica::Real) -> bool {
    true
}

pub fn free<T>(data: T) {}

/// `OPENMODELICA_GC_CYCLE_LOG=1`: report which types were actually on a
/// reclaimed cycle. A static analysis cannot answer this — it sees a cycle
/// wherever two types refer to each other, even when the values form a tree.
#[cfg(feature = "cycle-collect")]
fn collect_reporting() {
    if std::env::var_os("OPENMODELICA_GC_CYCLE_LOG").is_none() {
        metamodelica::gc::collect();
        return;
    }
    metamodelica::gc::log_cycles();
    // Report only: nothing should be cyclic any more, so a collector bug here
    // would free live data rather than reclaim garbage.
    let stats = metamodelica::gc::report_only();
    let log = metamodelica::gc::take_cycle_log();
    let total: usize = log.iter().map(|(_, n)| n).sum();
    // Print the total traced as the denominator: removing a strong edge raises
    // the reclaimed count, and that is only good news if traced did not rise
    // with it.
    eprintln!(
        "gc-cycle-log: reclaimed {total} allocations across {} types, of {} traced",
        log.len(),
        stats.traced_allocations
    );
    for (ty, n) in log.iter().take(40) {
        eprintln!("  {n:>9}  {ty}");
    }
}

fn report_cell_stats() {
    if crate::Mutable::stats::enabled() {
        let (created, updated, accessed) = crate::Mutable::stats::report();
        let upgraded = crate::Mutable::stats::UPGRADED.with(|c| c.get());
        let owning = crate::Mutable::stats::UPGRADED_OWNING.with(|c| c.get());
        let rooted = crate::Mutable::stats::ROOTED.with(|c| c.get());
        eprintln!(
            "cell-stats: {created} cells created, {rooted} rooted, {updated} published \
             (a record copy each), {upgraded} borrowing + {owning} owning weak \
             upgrades (the owning ones copy the record too), {accessed} reads"
        );
    }
}

fn report_cell_sample() {
    if !crate::Mutable::sample::enabled() {
        return;
    }
    let (seen, rows) = crate::Mutable::sample::report();
    eprintln!("cell-sample: {seen} samples, innermost frontend frame:");
    for (frame, n) in rows.iter().take(20) {
        eprintln!("  {n:>7}  {frame}");
    }
}

/// The refcounted heap frees as ownership ends, so a collection only reclaims
/// cycles closed through mutable cells, and costs a shadow graph the size of
/// the live heap to look for them.
pub fn gcollect() {
    #[cfg(feature = "cycle-collect")]
    {
        // `Interactive.evaluate2` calls this from its out-of-memory recovery.
        if metamodelica::heap_limit::recovering() {
            return;
        }
        collect_reporting();
    }
    report_cell_stats();
    report_cell_sample();
}

pub fn gcollectAndUnmap() {
    // No unmapping concept on the refcounted heap; same as `gcollect`.
    gcollect();
}

pub fn getForceUnmapOnGcollect() -> bool {
    true
}

pub fn getProfStats() -> ProfStats {
    ProfStats { heapsize_full: 0, free_bytes_full: 0, unmapped_bytes: 0, bytes_allocd_since_gc: 0, allocd_bytes_before_gc: 0, non_gc_bytes: 0, gc_no: 0, markers_m1: 0, bytes_reclaimed_since_gc: 0, reclaimed_bytes_before_gc: 0 }
}

// `profStatsStr` calls `intString` to format each field. `intString` is
// infallible and now returns `ArcStr` directly (no `.unwrap()` needed).
pub fn profStatsStr(stats: ProfStats, head: ArcStr, delimiter: ArcStr) -> ArcStr {
    let s: ArcStr = (match stats.clone() {
        PROFSTATS { .. } => { let mut __mm_s = String::new();
            __mm_s.push_str(&*head);
            __mm_s.push_str(&*delimiter);
            __mm_s.push_str("heapsize_full: ");
            __mm_s.push_str(&*intString(stats.heapsize_full.clone()));
            __mm_s.push_str(&*delimiter);
            __mm_s.push_str("free_bytes_full: ");
            __mm_s.push_str(&*intString(stats.free_bytes_full.clone()));
            __mm_s.push_str(&*delimiter);
            __mm_s.push_str(&*"unmapped_bytes: ");
            __mm_s.push_str(&*intString(stats.unmapped_bytes.clone()));
            __mm_s.push_str(&*delimiter);
            __mm_s.push_str(&*"bytes_allocd_since_gc: ");
            __mm_s.push_str(&*intString(stats.bytes_allocd_since_gc.clone()));
            __mm_s.push_str(&*delimiter);
            __mm_s.push_str(&*("allocd_bytes_before_gc: "));
            __mm_s.push_str(&*intString(stats.allocd_bytes_before_gc.clone()));
            __mm_s.push_str(&*delimiter);
            __mm_s.push_str(&*("total_allocd_bytes: "));
            __mm_s.push_str(&*intString(stats.bytes_allocd_since_gc.clone() + stats.allocd_bytes_before_gc.clone()));
            __mm_s.push_str(&*delimiter);
            __mm_s.push_str(&*("non_gc_bytes: "));
            __mm_s.push_str(&*intString(stats.non_gc_bytes.clone()));
            __mm_s.push_str(&*delimiter);
            __mm_s.push_str(&*("gc_no: "));
            __mm_s.push_str(&*intString(stats.gc_no.clone()));
            __mm_s.push_str(&*delimiter);
            __mm_s.push_str(&*("markers_m1: "));
            __mm_s.push_str(&*intString(stats.markers_m1.clone()));
            __mm_s.push_str(&*delimiter);
            __mm_s.push_str(&*("bytes_reclaimed_since_gc: "));
            __mm_s.push_str(&*intString(stats.bytes_reclaimed_since_gc.clone()));
            __mm_s.push_str(&*delimiter);
            __mm_s.push_str(&*("reclaimed_bytes_before_gc: "));
            __mm_s.push_str(&*intString(stats.reclaimed_bytes_before_gc.clone()));
            ArcStr::from(__mm_s) },
    });
    s
}

pub fn setForceUnmapOnGcollect(forceUnmap: bool) {}

pub fn setFreeSpaceDivisor(divisor: i32) {}

// 0 lifts the ceiling, as in Boehm.
pub fn setMaxHeapSize(sz: metamodelica::Real) {
    let sz = sz.into_inner();
    metamodelica::heap_limit::set_max_heap_size(if sz > 0.0 { sz as usize } else { 0 });
}
