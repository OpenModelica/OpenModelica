//! Jacobian sparsity patterns and colorings (NLS, linear, the A matrix).

use super::*;

/// A nonlinear system's Jacobian sparsity in CSC — `colptr` (`n+1`), `rowidx`
/// (`nnz`) and the column coloring. Columns and rows are positional, as C's
/// `evalJacobian` indexes `seedVars[column]` / `resultVars[row]`.
pub(super) struct NlsJacPattern {
    pub(super) colptr: Vec<i32>,
    pub(super) rowidx: Vec<i32>,
    pub(super) colors: Vec<Vec<u32>>,
}

impl NlsJacPattern {
    pub(super) fn passes_sanity_check(&self, n: usize) -> bool {
        sparsity_sanity_check(&self.colptr, &self.rowidx, self.colptr.len() - 1, n)
    }

    /// C's `colorCols`, 0-based. A column the backend left out of the colouring gets
    /// one of its own.
    pub(super) fn color_of_column(&self, n: usize) -> Vec<i32> {
        let mut of = vec![-1i32; n];
        for (c, cols) in self.colors.iter().enumerate() {
            for &col in cols {
                if let Some(slot) = of.get_mut(col as usize) {
                    *slot = c as i32;
                }
            }
        }
        let mut next = self.colors.len() as i32;
        for slot in of.iter_mut().filter(|s| **s < 0) {
            *slot = next;
            next += 1;
        }
        of
    }

    /// C keeps a pattern that is not `n × n`; no solver here could use one.
    pub(super) fn is_square(&self, n: usize) -> bool {
        self.colptr.len() == n + 1 && self.rowidx.iter().all(|&r| (r as usize) < n)
    }
}

/// The two patterns C can carry, in the order `functionNonLinearResiduals` picks
/// them, minus what C's `sparsitySanityCheck` rejects.
pub(super) fn nls_jac_pattern(jm: &SimCode::JacobianMatrix, n: usize) -> Option<NlsJacPattern> {
    let pat = nls_jac_pattern_raw(jm, n)?;
    (pat.passes_sanity_check(n) && pat.is_square(n)).then_some(pat)
}

/// The pattern as the backend emitted it, before C's sanity check.
pub(super) fn nls_jac_pattern_raw(jm: &SimCode::JacobianMatrix, n: usize) -> Option<NlsJacPattern> {
    match &jm.sparsityMatrix {
        SimCode::Sparsity::SPARSITY { .. } => nls_jac_pattern_resizable(jm, n),
        _ => nls_jac_pattern_static(jm, n),
    }
}

/// C's `sparsitySanityCheck`; `size_cols` is what the pattern was built with,
/// which need not be `n`.
fn sparsity_sanity_check(colptr: &[i32], rowidx: &[i32], size_cols: usize, n: usize) -> bool {
    if n == 0 || rowidx.len() < n {
        return false;
    }
    if (1..size_cols.min(n)).any(|i| colptr[i] == colptr[i - 1]) {
        return false;
    }
    let mut seen = vec![false; n];
    for &r in &rowidx[..colptr[size_cols] as usize] {
        if let Some(s) = seen.get_mut(r as usize) {
            *s = true;
        }
    }
    seen.iter().all(|&s| s)
}

/// C's `generateStaticSparseData`: one `sparsity` entry per column holding its
/// nonzero rows, coloring precomputed in `coloredCols`.
fn nls_jac_pattern_static(jm: &SimCode::JacobianMatrix, n: usize) -> Option<NlsJacPattern> {
    let mut cols: Vec<Vec<i32>> =
        lst(&jm.sparsity).map(|(_, rows)| lst(rows).copied().collect()).collect();
    if cols.iter().flatten().any(|&r| r < 0) {
        return None;
    }
    let (colptr, rowidx) = csc_from_columns(&mut cols)?;
    // A coloring that is not a partition of the columns would drop or double-count
    // entries, so recompute instead of trusting it.
    let colors: Vec<Vec<u32>> =
        lst(&jm.coloredCols).map(|grp| lst(grp).map(|&c| c as u32).collect()).collect();
    let mut seen = vec![false; n];
    let partition = cols.len() == n
        && colors.iter().flatten().all(|&c| {
            (c as usize) < n && !core::mem::replace(&mut seen[c as usize], true)
        })
        && seen.iter().all(|&s| s);
    let colors = match (partition, rowidx.iter().all(|&r| (r as usize) < cols.len())) {
        (true, _) => colors,
        (false, true) => computed_coloring(&colptr, &rowidx, cols.len()),
        (false, false) => (0..cols.len() as u32).map(|c| vec![c]).collect(),
    };
    Some(NlsJacPattern { colptr, rowidx, colors })
}

/// C's `initialResizableAnalyticJacobian<M>`, with the equation iterators expanded
/// at build time. A regular whole-array dependency of a whole-array unknown pairs
/// element-wise (`resizableColCountRegular`); everything else is the cross product.
fn resizable_rows_by_col(jm: &SimCode::JacobianMatrix, n_cols: usize, n_rows: usize) -> Option<Vec<Vec<i32>>> {
    let SimCode::Sparsity::SPARSITY { rows } = &jm.sparsityMatrix else { return None };
    let slots = JacArraySlots::of(jm)?;
    let mut cols: Vec<Vec<i32>> = vec![Vec::new(); n_cols];
    let mut add = |r: usize, c: usize| {
        if r < n_rows && c < n_cols {
            cols[c].push(r as i32);
        }
    };
    for row in lst(rows) {
        let iters: Vec<&BackendDAE::SimIterator> = lst(&row.equation_iterators).collect();
        for (flat, bindings) in iterator_expansion(&iters).ok()?.into_iter().enumerate() {
            for sc in lst(&row.solved_crefs) {
                let sc = BoundCref::new(sc, &bindings)?;
                let sc_offs = match sc.whole_1d() && !bindings.is_empty() {
                    true => vec![slots.base(&sc.cref)? + flat],
                    false => slots.offsets(&sc)?,
                };
                for (seed, dep, rep) in lst(&row.dependencies) {
                    let seed = BoundCref::new(seed, &bindings)?;
                    let regular = !*rep && lst(&dep.kinds).next() == Some(&false) && seed.whole_1d() && sc.whole_1d();
                    if regular {
                        let (rb, cb) = (slots.base(&sc.cref)?, slots.base(&seed.cref)?);
                        match bindings.is_empty() {
                            true => (0..sc.first_dim()?).for_each(|k| add(rb + k, cb + k)),
                            false => add(rb + flat, cb + flat),
                        }
                        continue;
                    }
                    for c in slots.offsets(&seed)? {
                        for &r in &sc_offs {
                            add(r, c);
                        }
                    }
                }
            }
        }
    }
    Some(cols)
}

/// `SimVar.index` per array base (the C template's `crefsHT` after `crefStripSubs`).
struct JacArraySlots {
    base: HashMap<String, usize>,
}

impl JacArraySlots {
    fn of(jm: &SimCode::JacobianMatrix) -> Option<JacArraySlots> {
        let mut base = HashMap::new();
        for sv in lst(&jm.seedVars).cloned().chain(jac_listed_vars(jm)) {
            let Ok(index) = usize::try_from(sv.index) else { continue };
            let stripped = openmodelica_frontend_base::ComponentReference::crefStripSubs(sv.name.clone()).ok()?;
            base.entry(sim_cref_key(&stripped).ok()?).or_insert(index);
        }
        Some(JacArraySlots { base })
    }

    fn base(&self, cr: &Arc<DAE::ComponentRef>) -> Option<usize> {
        let stripped = openmodelica_frontend_base::ComponentReference::crefStripSubs(cr.clone()).ok()?;
        self.base.get(&sim_cref_key(&stripped).ok()?).copied()
    }

    fn offsets(&self, cr: &BoundCref) -> Option<Vec<usize>> {
        let base = self.base(&cr.cref)?;
        let mut offs = vec![0usize];
        for (dim, positions) in &cr.dims {
            let mut next = Vec::with_capacity(offs.len() * positions.len());
            for o in &offs {
                for p in positions {
                    next.push(o * dim + p);
                }
            }
            offs = next;
        }
        Some(offs.into_iter().map(|o| base + o).collect())
    }
}

/// A sparsity cref with its iterators bound: per dimension, size and selected
/// 0-based positions.
struct BoundCref {
    cref: Arc<DAE::ComponentRef>,
    dims: Vec<(usize, Vec<usize>)>,
    whole: Vec<bool>,
}

impl BoundCref {
    fn new(cr: &Arc<DAE::ComponentRef>, bindings: &[(String, Arc<DAE::Exp>)]) -> Option<BoundCref> {
        let mut dims = Vec::new();
        let mut whole = Vec::new();
        let mut part = cr;
        loop {
            let (ty, subs, next) = match &**part {
                DAE::ComponentRef::CREF_IDENT { identType, subscriptLst, .. } => (identType, subscriptLst, None),
                DAE::ComponentRef::CREF_QUAL { identType, subscriptLst, componentRef, .. } => {
                    (identType, subscriptLst, Some(componentRef))
                }
                _ => return None,
            };
            let part_dims = type_dims(ty)?;
            let subs: Vec<&Arc<DAE::Subscript>> = lst(subs).collect();
            if subs.len() > part_dims.len() {
                return None;
            }
            for (k, &dim) in part_dims.iter().enumerate() {
                let (positions, is_whole) = match subs.get(k).map(|s| &***s) {
                    None | Some(DAE::Subscript::WHOLEDIM) | Some(DAE::Subscript::WHOLE_NONEXP { .. }) => {
                        ((0..dim).collect(), true)
                    }
                    Some(DAE::Subscript::INDEX { exp }) => {
                        let v = bound_int(exp, bindings)?;
                        (usize::try_from(v - 1).ok().into_iter().collect(), false)
                    }
                    Some(DAE::Subscript::SLICE { exp }) => {
                        let vs = bound_ints(exp, bindings)?;
                        (vs.into_iter().filter_map(|v| usize::try_from(v - 1).ok()).collect(), false)
                    }
                };
                dims.push((dim, positions));
                whole.push(is_whole);
            }
            match next {
                Some(n) => part = n,
                None => break,
            }
        }
        Some(BoundCref { cref: cr.clone(), dims, whole })
    }

    /// C's `crefSubs(cr) == {WHOLEDIM()}`.
    fn whole_1d(&self) -> bool {
        self.dims.len() == 1 && self.whole[0]
    }

    fn first_dim(&self) -> Option<usize> {
        self.dims.first().map(|(d, _)| *d)
    }
}

pub(super) fn type_dims(ty: &DAE::Type) -> Option<Vec<usize>> {
    let mut out = Vec::new();
    let mut ty = ty;
    while let DAE::Type::T_ARRAY { ty: inner, dims } = ty {
        for d in lst(dims) {
            match &**d {
                DAE::Dimension::DIM_INTEGER { integer } => out.push(usize::try_from(*integer).ok()?),
                _ => return None,
            }
        }
        ty = inner;
    }
    Some(out)
}

fn bound_int(exp: &Arc<DAE::Exp>, bindings: &[(String, Arc<DAE::Exp>)]) -> Option<i32> {
    const_int_exp(&*bound_exp(exp, bindings)?)
}

fn bound_ints(exp: &Arc<DAE::Exp>, bindings: &[(String, Arc<DAE::Exp>)]) -> Option<Vec<i32>> {
    match &*bound_exp(exp, bindings)? {
        DAE::Exp::ARRAY { array, .. } => lst(array).map(|e| const_int_exp(e)).collect(),
        DAE::Exp::RANGE { start, step, stop, .. } => {
            let (start, stop) = (const_int_exp(start)?, const_int_exp(stop)?);
            let step = match step {
                Some(s) => const_int_exp(s)?,
                None => 1,
            };
            if step == 0 {
                return None;
            }
            let mut out = Vec::new();
            let mut v = start;
            while (step > 0 && v <= stop) || (step < 0 && v >= stop) {
                out.push(v);
                v += step;
            }
            Some(out)
        }
        e => const_int_exp(e).map(|v| vec![v]),
    }
}

fn bound_exp(exp: &Arc<DAE::Exp>, bindings: &[(String, Arc<DAE::Exp>)]) -> Option<Arc<DAE::Exp>> {
    let mut e = exp.clone();
    for (name, value) in bindings {
        e = subst_iterator(&e, name, value).ok()?;
    }
    openmodelica_frontend_base::ExpressionSimplify::simplify1(e).ok().map(|(e, _)| e)
}

/// Every iterator combination, first iterator least significant (C's `forIteratorBody`).
fn iterator_expansion(iters: &[&BackendDAE::SimIterator]) -> Result<Vec<Vec<(String, Arc<DAE::Exp>)>>> {
    let mut out: Vec<Vec<(String, Arc<DAE::Exp>)>> = vec![Vec::new()];
    for iter in iters {
        let (name, values, sub_iters) = iterator_bindings(iter)?;
        let mut next = Vec::with_capacity(out.len() * values.len());
        for (pos, value) in values.iter().enumerate() {
            for prev in &out {
                let mut b = prev.clone();
                b.push((name.clone(), value.clone()));
                for (sub_name, table) in &sub_iters {
                    let v = table.get(pos).ok_or("CodegenWasmJit: dependent iterator range is too short")?;
                    b.push((sub_name.clone(), v.clone()));
                }
                next.push(b);
            }
        }
        out = next;
    }
    Ok(out)
}

/// Built at C's size (`numScalarElems(seedVars)` columns, rows unguarded) so the
/// sanity check sees what C's does.
fn nls_jac_pattern_resizable(jm: &SimCode::JacobianMatrix, _n: usize) -> Option<NlsJacPattern> {
    let n_cols = jac_seed_scalar_count(jm)?;
    let mut cols = resizable_rows_by_col(jm, n_cols, usize::MAX)?;
    let (colptr, rowidx) = csc_from_columns(&mut cols)?;
    let colors = match rowidx.iter().all(|&r| (r as usize) < n_cols) {
        true => computed_coloring(&colptr, &rowidx, n_cols),
        false => (0..n_cols as u32).map(|c| vec![c]).collect(),
    };
    Some(NlsJacPattern { colptr, rowidx, colors })
}

/// Per-column row lists → CSC, sorted and deduplicated. `None` for an all-zero
/// Jacobian.
fn csc_from_columns(cols: &mut [Vec<i32>]) -> Option<(Vec<i32>, Vec<i32>)> {
    let mut colptr = vec![0i32; cols.len() + 1];
    let mut rowidx: Vec<i32> = Vec::new();
    for (c, rows) in cols.iter_mut().enumerate() {
        rows.sort_unstable();
        rows.dedup();
        rowidx.extend_from_slice(rows);
        colptr[c + 1] = rowidx.len() as i32;
    }
    (!rowidx.is_empty()).then_some((colptr, rowidx))
}

/// C's `computeColumnColoring`: one column-equation pass per group of columns
/// sharing no row.
fn computed_coloring(colptr: &[i32], rowidx: &[i32], n: usize) -> Vec<Vec<u32>> {
    let (color_ptr, color_cols) =
        crate::CodegenWasmJitFunctions::lin_jac_coloring(colptr, rowidx, n);
    (0..color_ptr.len() - 1)
        .map(|c| {
            color_cols[color_ptr[c] as usize..color_ptr[c + 1] as usize].iter().map(|&j| j as u32).collect()
        })
        .collect()
}

/// The nonzero count of a nonlinear system's Jacobian, matching C's
/// `initializeNonlinearSystemData` (`sparsePattern->nnz`).
pub(super) fn nls_system_nnz(nlsystem: &SimCode::NonlinearSystem) -> usize {
    let Some(jm) = nlsystem.jacobianMatrix.as_ref() else { return 0 };
    let n = lst(&nlsystem.crefs).count();
    nls_jac_pattern(jm, n).map_or(0, |p| p.rowidx.len())
}

/// Row coloring for the adjoint evaluation: rows seeded together share no column.
pub(super) fn row_coloring(rows_by_col: &[Vec<u32>], n: usize) -> Vec<Vec<u32>> {
    let mut cols_by_row: Vec<Vec<i32>> = vec![Vec::new(); n];
    for (c, rows) in rows_by_col.iter().enumerate() {
        for &r in rows {
            cols_by_row[r as usize].push(c as i32);
        }
    }
    match csc_from_columns(&mut cols_by_row) {
        Some((colptr, rowidx)) => computed_coloring(&colptr, &rowidx, n),
        None => (0..n as u32).map(|r| vec![r]).collect(),
    }
}

/// The ODE state Jacobian "A", if the backend emitted one at all.
fn jac_a_matrix(sim_code: &SimCode::SimCode) -> Option<&SimCode::JacobianMatrix> {
    lst(&sim_code.jacobianMatrices).find(|j| &*j.matrixName == "A").map(|j| &**j)
}

pub(super) fn build_jac_a_info(sim_code: &SimCode::SimCode, n_states: u32) -> Option<JacAInfo> {
    if n_states == 0 {
        return None;
    }
    let jac = jac_a_matrix(sim_code)?;
    let info = jac_pattern_info(jac, n_states as usize)?;
    if std::env::var("OMC_WASM_SIM_BENCH").is_ok() {
        let nnz: usize = info.rows_by_col.iter().map(|r| r.len()).sum();
        eprintln!("wasm-jit jac-A: n={n_states} colors={} nnz={nnz}", info.colors.len());
    }
    Some(info)
}

/// One Jacobian matrix's `n × n` sparsity + coloring, or `None` when the backend
/// left either out (or produced indices out of range), in which case the caller
/// falls back to a solver-internal numerical Jacobian.
pub(super) fn jac_pattern_info(jac: &SimCode::JacobianMatrix, n: usize) -> Option<JacAInfo> {
    if n == 0 {
        return None;
    }
    let (rows_by_col, colors): (Vec<Vec<u32>>, Vec<Vec<u32>>) = match &jac.sparsityMatrix {
        SimCode::Sparsity::SPARSITY { .. } => {
            if jac_seed_scalar_count(jac)? != n {
                return None;
            }
            let mut cols = resizable_rows_by_col(jac, n, n)?;
            let (colptr, rowidx) = csc_from_columns(&mut cols)?;
            let colors = computed_coloring(&colptr, &rowidx, n);
            (cols.iter().map(|c| c.iter().map(|&r| r as u32).collect()).collect(), colors)
        }
        _ => {
            // sparsity: positional per column → 0-based nonzero rows (CSC), one entry per
            // column (empty columns carry an empty row list).
            let rows_by_col = lst(&jac.sparsity)
                .map(|(_, rows)| lst(rows).map(|r| *r as u32).collect())
                .collect();
            // coloredCols: each color → its 0-based column indices.
            let colors = lst(&jac.coloredCols)
                .map(|grp| lst(grp).map(|c| *c as u32).collect())
                .collect();
            (rows_by_col, colors)
        }
    };
    if rows_by_col.len() != n
        || colors.is_empty()
        || colors.iter().flatten().any(|&c| c as usize >= n)
        || rows_by_col.iter().flatten().any(|&r| r as usize >= n)
    {
        return None;
    }
    Some(JacAInfo { n: n as u32, colors, rows_by_col, sym: None })
}

/// Map each result variable's display name to its unit (`h` -> `m`, `der(h)` ->
/// the derivative var's unit), for a host to label plotted signals. Empty units
/// are skipped. Names match [`build_var_map`]'s result-variable names.
pub(super) fn collect_var_units(vars: &SimCodeVar::SimVars) -> Result<HashMap<String, String>> {
    let mut units = HashMap::new();
    let mut add = |name: String, sv: &SimCodeVar::SimVar| {
        if !sv.unit.is_empty() {
            units.insert(name, sv.unit.to_string());
        }
    };
    for sv in lst(&vars.stateVars).chain(lst(&vars.derivativeVars)) {
        add(cref_display(&sv.name)?, sv);
    }
    for sv in lst(&vars.algVars)
        .chain(lst(&vars.discreteAlgVars))
        .chain(lst(&vars.paramVars))
        .chain(lst(&vars.intAlgVars))
        .chain(lst(&vars.intParamVars))
        .chain(lst(&vars.boolAlgVars))
        .chain(lst(&vars.boolParamVars))
    {
        add(cref_display(&sv.name)?, sv);
    }
    for av in lst(&vars.aliasVars).chain(lst(&vars.intAliasVars)).chain(lst(&vars.boolAliasVars)) {
        add(cref_display(&av.name)?, av);
    }
    Ok(units)
}
