//! Zero crossings, relations, `sample()` and clock collection.

use super::*;

/// One `sample(index, start, interval)` time event, from `SimCode.timeEvents`.
/// `start`/`interval` are the (parameter-dependent) expressions the emitted
/// `initSample` evaluates into the sample region; `index` is the sample's unique
/// index as it appears in the `sample(index,…)` calls in equations.
pub(super) struct SampleInfo {
    pub(super) index: i32,
    pub(super) start: Arc<DAE::Exp>,
    pub(super) interval: Arc<DAE::Exp>,
}

/// One state-event zero-crossing. The driver's DASKR root callback watches `g`
/// and locates the sign change. `SimCode.zeroCrossings` maps 1:1 onto these (as
/// in the C target's `function_ZeroCrossings`), one `g` per entry.
pub(crate) enum ZcInfo {
    /// A relation or boolean condition: `g = expr ? 1 : -1`. DASKR brackets the ±1
    /// step. A Real inequality is lowered with a hysteresis band and held-relation
    /// direction (see `compile_relation`), consistent with how the same relation
    /// reads in the equations, so an event fires exactly when the relation flips.
    Bool { expr: Arc<DAE::Exp> },
    /// A math-event builtin (`integer`/`floor`/`ceil`/`div`/`mod`): `g =
    /// (test(fresh arg) != test(pre[idx])) ? 1 : -1`, C's `zeroCrossingTpl`. `ops`
    /// are the operands (1 for integer/floor/ceil, 2 for div/mod).
    /// `expr` is the original call, only for the `LOG_EVENTS` description.
    Math { kind: MathEventKind, ops: Vec<Arc<DAE::Exp>>, idx: u32, expr: Arc<DAE::Exp> },
}

/// A math-event builtin's discretizing test (what `mathEventsValuePre` compares).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) enum MathEventKind {
    /// `integer`/`floor`: `floor`.
    Floor,
    /// `ceil`: `ceil`.
    Ceil,
    /// `div`: `trunc(a/b)`.
    Div,
    /// `mod`: `floor(a/b)`.
    Mod,
}

/// Classify a builtin call as a math event by name and arity. `FindZeroCrossings`
/// appends the `mathEventsValuePre` index to event-context calls
/// (`integer(x)`→`integer(x,idx)`), so the extra argument marks the held form.
pub(crate) fn math_event_kind(name: &str, nargs: usize) -> Option<MathEventKind> {
    match (name, nargs) {
        ("integer", 2) | ("floor", 2) => Some(MathEventKind::Floor),
        ("ceil", 2) => Some(MathEventKind::Ceil),
        ("div", 3) => Some(MathEventKind::Div),
        ("mod", 3) => Some(MathEventKind::Mod),
        _ => None,
    }
}

/// The `mathEventsValuePre` slot index (a math-event call's last argument).
pub(crate) fn math_event_index(last: &DAE::Exp) -> Result<u32> {
    match last {
        DAE::Exp::ICONST { integer } if *integer >= 0 => Ok(*integer as u32),
        other => return Err("CodegenWasmJit: math-event index is not a non-negative ICONST"),
    }
}

/// Whether `path` is the unqualified builtin call `name`.
fn path_ident_is(path: &openmodelica_ast::Absyn::Path, name: &str) -> bool {
    matches!(path, openmodelica_ast::Absyn::Path::IDENT { name: n } if &**n == name)
}

/// The unqualified identifier of a builtin call path, or `None` if qualified.
fn path_ident_name(path: &openmodelica_ast::Absyn::Path) -> Option<&str> {
    match path {
        openmodelica_ast::Absyn::Path::IDENT { name } => Some(name),
        _ => None,
    }
}

/// Collect the model's zero-crossings (`SimCode.zeroCrossings`), one `ZcInfo` per
/// entry (matching the C `zeroCrossingTpl` cases). A bare numeric inequality keeps
/// the exact continuous `lhs - rhs`; a boolean condition (`==`/`<>`, `LBINARY`
/// combinations, `LUNARY`) maps to ±1 like C's `gout[i] = (relation_) ? 1 : -1`.
/// A `sample(…)` crossing emits no root (time events are driven separately).
/// Math-event builtins (`integer`/`floor`/`ceil`/`div`/`mod`) map to a
/// `ZcInfo::Math` (held-value comparison, C's `mathEventsValuePre` hysteresis).
/// For-loop (`iter`) crossings still error — they need iterator expansion, not
/// yet ported.
pub(super) fn collect_zero_crossings(
    zcs: &List<openmodelica_backend_types::BackendDAE::ZeroCrossing>,
) -> Result<Vec<ZcInfo>> {
    let mut out = Vec::new();
    for zc in lst(zcs) {
        for relation in expand_iter_crossing(&zc.relation_, &zc.iter)? {
            match &*relation {
                DAE::Exp::RELATION { .. } | DAE::Exp::LBINARY { .. } | DAE::Exp::LUNARY { .. } => {
                    out.push(ZcInfo::Bool { expr: relation.clone() });
                }
                // `sample()` in the zero-crossing list is a time event (handled via
                // `collect_samples`); it contributes no DASKR root, like C's empty case.
                DAE::Exp::CALL { path, .. } if path_ident_is(path, "sample") => {}
                DAE::Exp::CALL { path, expLst, .. }
                    if path_ident_name(path)
                        .and_then(|n| math_event_kind(n, count(expLst) as usize))
                        .is_some() =>
                {
                    let kind = math_event_kind(path_ident_name(path).unwrap(), count(expLst) as usize).unwrap();
                    let argv: Vec<Arc<DAE::Exp>> = lst(expLst).cloned().collect();
                    let idx = math_event_index(argv.last().unwrap())?;
                    let ops = argv[..argv.len() - 1].to_vec();
                    out.push(ZcInfo::Math { kind, ops, idx, expr: relation.clone() });
                }
                other => return Err("CodegenWasmJit: unsupported zero-crossing form"),
            }
        }
    }
    Ok(out)
}

/// A for-loop crossing occupies one slot per iteration: C's `forIteratorBody`
/// offsets `gout` mixed-radix, first iterator least significant. The counts are
/// constant, so the same slots come from substituting each iterator value in.
fn expand_iter_crossing(
    relation: &Arc<DAE::Exp>,
    iters: &Option<List<openmodelica_backend_types::BackendDAE::SimIterator>>,
) -> Result<Vec<Arc<DAE::Exp>>> {
    let Some(iters) = iters else { return Ok(vec![relation.clone()]) };
    let mut out = vec![relation.clone()];
    for iter in lst(iters) {
        let (name, values, sub_iters) = iterator_bindings(iter)?;
        let mut next = Vec::with_capacity(out.len() * values.len());
        for (pos, value) in values.iter().enumerate() {
            for e in &out {
                let mut e = subst_iterator(e, &name, value)?;
                for (sub_name, table) in &sub_iters {
                    let v = table
                        .get(pos)
                        .ok_or("CodegenWasmJit: dependent iterator range is too short")?;
                    e = subst_iterator(&e, sub_name, v)?;
                }
                next.push(e);
            }
        }
        out = next;
    }
    Ok(out)
}

/// An iterator's name and per-iteration value, and the same for its dependents.
type IteratorBindings = (String, Vec<Arc<DAE::Exp>>, Vec<(String, Vec<Arc<DAE::Exp>>)>);

pub(super) fn iterator_bindings(
    iter: &openmodelica_backend_types::BackendDAE::SimIterator,
) -> Result<IteratorBindings> {
    use openmodelica_backend_types::BackendDAE::SimIterator as S;
    let iconst = |v: i32| Arc::new(DAE::Exp::ICONST { integer: v });
    let (name, sub_iter, values) = match iter {
        S::SIM_ITERATOR_RANGE { name, start, step, non_resizable_size, sub_iter, .. } => {
            let (Some(start), Some(step)) = (const_int_exp(start), const_int_exp(step)) else {
                return Err("CodegenWasmJit: for-loop crossing over a non-constant range");
            };
            let values = (0..*non_resizable_size).map(|k| iconst(start + k * step)).collect();
            (name, sub_iter, values)
        }
        S::SIM_ITERATOR_LIST { name, lst: values, sub_iter, .. } => {
            (name, sub_iter, (&**values).into_iter().map(|v| iconst(*v)).collect())
        }
    };
    let mut subs = Vec::new();
    for (sub_name, table) in &**sub_iter {
        subs.push((cref_display(sub_name)?, table.borrow().clone()));
    }
    Ok((cref_display(name)?, values, subs))
}

pub(super) fn const_int_exp(e: &DAE::Exp) -> Option<i32> {
    match e {
        DAE::Exp::ICONST { integer } => Some(*integer),
        _ => None,
    }
}

/// Replace the bare iterator `name`, including inside cref subscripts.
pub(super) fn subst_iterator(exp: &Arc<DAE::Exp>, name: &str, value: &Arc<DAE::Exp>) -> Result<Arc<DAE::Exp>> {
    let name = name.to_string();
    let value = value.clone();
    let replace = move |e: Arc<DAE::Exp>, acc: i32| -> Result<(Arc<DAE::Exp>, i32)> {
        if let DAE::Exp::CREF { componentRef, .. } = &*e {
            if let DAE::ComponentRef::CREF_IDENT { ident, subscriptLst, .. } = &**componentRef {
                if subscriptLst.is_empty() && ident.as_str() == name {
                    return Ok((value.clone(), acc));
                }
            }
        }
        Ok((e, acc))
    };
    openmodelica_frontend_base::Expression::traverseExpBottomUp(exp.clone(), Arc::new(replace), 0)
        .map(|(e, _)| e)
}

/// Collect `SimCode.relations`, one slot per entry as in C's `functionRelations`:
/// `Some` for a bare relation, `None` for a form C's `relationTpl` also leaves
/// untouched while still consuming its index.
pub(super) fn collect_relations(
    rels: &List<openmodelica_backend_types::BackendDAE::ZeroCrossing>,
) -> Result<Vec<Option<Arc<DAE::Exp>>>> {
    let mut out = Vec::new();
    for zc in lst(rels) {
        for relation in expand_iter_crossing(&zc.relation_, &zc.iter)? {
            out.push(match &*relation {
                DAE::Exp::RELATION { .. } => Some(relation.clone()),
                _ => None,
            });
        }
    }
    Ok(out)
}

/// Collect the model's `SAMPLE_TIME_EVENT`s in order. For-loop samples (with an
/// `iter`) expand to multiple runtime samples and are not handled yet, so bail
/// loudly rather than mis-simulate.
pub(super) fn collect_samples(
    time_events: &List<openmodelica_backend_types::BackendDAE::TimeEvent>,
) -> Result<Vec<SampleInfo>> {
    use openmodelica_backend_types::BackendDAE::TimeEvent as TE;
    let mut out = Vec::new();
    for te in lst(time_events) {
        if let TE::SAMPLE_TIME_EVENT { index, startExp, intervalExp, iter } = te {
            if iter.is_some() {
                return Err("CodegenWasmJit: for-loop `sample` (iterator) not yet supported");
            }
            out.push(SampleInfo { index: *index, start: startExp.clone(), interval: intervalExp.clone() });
        }
    }
    Ok(out)
}

/// One synchronous base clock: the [`BaseClockMeta`] the driver needs, plus the
/// `ClockKind` expressions and sub-partition equations the three emitted
/// functions are built from (C's `baseClockInit`/`updatePartition`/
/// `functionEquationsSynchronous`).
pub(super) struct ClockInfo {
    pub(super) meta: BaseClockMeta,
    pub(super) kind: Arc<DAE::ClockKind>,
    /// Equations of each sub-partition (`equations ++ removedEquations`).
    pub(super) sub_eqs: Vec<Vec<Arc<SimCode::SimEqSystem>>>,
}

/// Split a `ClockedPartition` list into per-base-clock info, assigning the flat
/// sub-clock indices the `SimData` sub-clock region is addressed by.
pub(super) fn collect_clocks(partitions: &List<SimCode::ClockedPartition>) -> Result<Vec<ClockInfo>> {
    let mut out = Vec::new();
    let mut sub_base = 0u32;
    for part in lst(partitions) {
        let mut sub = Vec::new();
        let mut sub_eqs = Vec::new();
        for sp in lst(&part.subPartitions) {
            let BackendDAE::SubClock::SUBCLOCK { factor, shift, solver } = &sp.subClock else {
                return Err("CodegenWasmJit: sub-partition still has an inferred sub-clock");
            };
            sub.push(SubClockMeta {
                shift_num: shift.nom as i64,
                shift_den: shift.denom as i64,
                factor_num: factor.nom as i64,
                factor_den: factor.denom as i64,
                hold_events: sp.holdEvents,
                external_solver: solver.is_some(),
            });
            sub_eqs.push(lst(&sp.equations).chain(lst(&sp.removedEquations)).cloned().collect());
        }
        // C's "fake" sub-partition 0 for an empty clocked partition, which its
        // base-clock handling then activates like any other.
        if sub.is_empty() {
            sub.push(SubClockMeta { shift_den: 1, factor_num: 1, factor_den: 1, ..SubClockMeta::default() });
            sub_eqs.push(Vec::new());
        }
        let n_sub = sub.len() as u32;
        out.push(ClockInfo {
            meta: BaseClockMeta {
                is_event_clock: matches!(&*part.baseClock, DAE::ClockKind::EVENT_CLOCK { .. }),
                inferred: matches!(&*part.baseClock, DAE::ClockKind::INFERRED_CLOCK),
                sub_base,
                sub,
            },
            kind: part.baseClock.clone(),
            sub_eqs,
        });
        sub_base += n_sub;
    }
    Ok(out)
}
