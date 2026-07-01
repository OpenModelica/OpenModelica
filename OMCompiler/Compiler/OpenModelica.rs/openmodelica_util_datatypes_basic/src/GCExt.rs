// Manually written file
#![allow(warnings)]
#![allow(unreachable_patterns, unreachable_code, non_camel_case_types, non_snake_case, dead_code, unused_imports, unused_variables, non_upper_case_globals, unused_mut)]

use std::sync::Arc;
use arcstr::ArcStr;
use anyhow::Result;
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
// collection only needs to reclaim cycles closed through mutable cells.
pub fn gcollect() {
    metamodelica::gc::collect();
}

pub fn gcollectAndUnmap() {
    // No unmapping concept on the refcounted heap; same as `gcollect`.
    metamodelica::gc::collect();
}

pub fn getForceUnmapOnGcollect() -> bool {
    true
}

pub fn getProfStats() -> ProfStats {
    ProfStats { heapsize_full: 0, free_bytes_full: 0, unmapped_bytes: 0, bytes_allocd_since_gc: 0, allocd_bytes_before_gc: 0, non_gc_bytes: 0, gc_no: 0, markers_m1: 0, bytes_reclaimed_since_gc: 0, reclaimed_bytes_before_gc: 0 }
}

// `profStatsStr` calls `intString` to format each field. `intString` is
// infallible and now returns `ArcStr` directly (no `.unwrap()` needed).
pub fn profStatsStr(stats: ProfStats, head: ArcStr, delimiter: ArcStr) -> Result<ArcStr> {
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
    Ok(s)
}

pub fn setForceUnmapOnGcollect(forceUnmap: bool) {}

pub fn setFreeSpaceDivisor(divisor: i32) {}

pub fn setMaxHeapSize(sz: metamodelica::Real) {}
