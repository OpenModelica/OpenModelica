// Manually written file
#![allow(warnings)]
#![allow(unreachable_patterns, unreachable_code, non_camel_case_types, non_snake_case, dead_code, unused_imports, unused_variables, non_upper_case_globals, unused_mut)]

use std::sync::Arc;

/// The Rust port has real weak semantics, so a cell needs an explicit owner.
pub const cellsNeedOwners: bool = true;
use arcstr::ArcStr;
use metamodelica::Result;
use loop_unwrap::unwrap_break_err;
use metamodelica::*; // Built-in types and functions
use const_str;

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

// MetaModelica `GCExt.gcollect` maps to one run of the cycle collector: the
// refcounted heap frees acyclic garbage eagerly on its own, so an explicit
// collection only needs to reclaim cycles closed through cyclic cells.
/// `OPENMODELICA_GC_CYCLE_LOG=1`: report which types were actually on a
/// reclaimed cycle. Pair it with `OPENMODELICA_GC_DISABLE=1` so nothing is
/// collected until this call and the report covers the whole run. A static
/// analysis cannot answer this — it sees a cycle wherever two types refer to
/// each other, even when the values form a tree.
fn collect_reporting() {
    if std::env::var_os("OPENMODELICA_GC_CYCLE_LOG").is_none() {
        metamodelica::mmval::collect();
        metamodelica::gc::collect();
        return;
    }
    metamodelica::mmval::log_cycles();
    metamodelica::gc::log_cycles();
    metamodelica::mmval::collect();
    // Report only: nothing should be cyclic any more, so a collector bug here
    // would free live data rather than reclaim garbage.
    let stats = metamodelica::gc::report_only();
    let mut log = metamodelica::mmval::take_cycle_log();
    log.extend(metamodelica::gc::take_cycle_log());
    log.sort_by(|a, b| b.1.cmp(&a.1));
    let total: usize = log.iter().map(|(_, n)| n).sum();
    // `traced` is the denominator: reclaimed went *up* on a change that
    // removed a strong edge is only good news if traced did not go up with it,
    // which is what tells a converted leak from fresh garbage.
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
        let upgraded = crate::MutableWeak::UPGRADED.with(|c| c.get());
        let rooted = crate::MutableWeak::ROOTED.with(|c| c.get());
        eprintln!(
            "cell-stats: {created} cells created, {rooted} rooted, {updated} published \
             (a record copy each), {upgraded} weak upgrades, {accessed} reads"
        );
    }
}

pub fn gcollect() {
    collect_reporting();
    report_cell_stats();
}

pub fn gcollectAndUnmap() {
    // No unmapping concept on the refcounted heap; same as `gcollect`.
    collect_reporting();
    report_cell_stats();
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

pub fn setMaxHeapSize(sz: metamodelica::Real) {}
