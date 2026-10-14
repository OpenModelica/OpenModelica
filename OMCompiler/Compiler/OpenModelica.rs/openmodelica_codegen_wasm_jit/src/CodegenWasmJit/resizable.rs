//! `--resizableArrays`: an array sized by an Integer parameter stays one `SimVar`
//! and its size symbolic ([`Sz`]) until the runtime resolves it
//! (`openmodelica_sim_meta::resize`).

use super::*;
use openmodelica_sim_meta::SizeParam;
pub(crate) use openmodelica_sim_meta::Sz;

/// The Integer parameters array sizes depend on, in dependency order.
#[derive(Default)]
pub(crate) struct SizeParams {
    by_key: HashMap<String, u32>,
    pub(crate) params: Vec<SizeParam>,
    pub(crate) keys: Vec<String>,
    int_params: HashMap<String, metamodelica::Ref<SimCodeVar::SimVar>>,
    visiting: HashSet<String>,
}

impl SizeParams {
    pub(crate) fn new(vars: &SimCodeVar::SimVars) -> Result<SizeParams> {
        let mut s = SizeParams::default();
        for sv in lst(&vars.intParamVars) {
            s.int_params.insert(sim_cref_key(&sv.name)?, sv.clone());
        }
        Ok(s)
    }

    pub(crate) fn index_of(&self, key: &str) -> Option<u32> {
        self.by_key.get(key).copied()
    }

    fn param(&mut self, key: &str) -> Result<Sz> {
        if let Some(&i) = self.by_key.get(key) {
            return Ok(Sz::param(i));
        }
        let Some(sv) = self.int_params.get(key).cloned() else {
            record_error(format!("CodegenWasmJit: the array size `{key}` is not an Integer parameter"));
            return Err("CodegenWasmJit: unsupported resizable array size");
        };
        if !self.visiting.insert(key.to_string()) {
            return Err("CodegenWasmJit: cyclic array size parameters");
        }
        let start = match &sv.initialValue {
            Some(e) => self.sz_of_exp(e)?,
            None => Sz::lit(0),
        };
        self.visiting.remove(key);
        let i = self.params.len() as u32;
        self.params.push(SizeParam { name: cref_display(&sv.name)?, start, off: 0 });
        self.keys.push(key.to_string());
        self.by_key.insert(key.to_string(), i);
        Ok(Sz::param(i))
    }

    pub(crate) fn sz_of_exp(&mut self, e: &DAE::Exp) -> Result<Sz> {
        use DAE::Exp as E;
        use DAE::Operator as O;
        Ok(match e {
            E::ICONST { integer } => Sz::lit(*integer as i64),
            E::BCONST { bool } => Sz::lit(*bool as i64),
            E::ENUM_LITERAL { index, .. } => Sz::lit(*index as i64),
            E::CREF { componentRef, .. } => self.param(&sim_cref_key(componentRef)?)?,
            E::CAST { exp, .. } => self.sz_of_exp(exp)?,
            E::UNARY { operator: O::UMINUS { .. }, exp } => -self.sz_of_exp(exp)?,
            E::BINARY { exp1, operator, exp2 } => {
                let (a, b) = (self.sz_of_exp(exp1)?, self.sz_of_exp(exp2)?);
                match operator {
                    O::ADD { .. } => a + b,
                    O::SUB { .. } => a - b,
                    O::MUL { .. } => a * b,
                    O::DIV { .. } => a.div(b),
                    _ => return unsupported(e),
                }
            }
            E::CALL { path, expLst, .. } => {
                let name = openmodelica_frontend_dump::AbsynUtil::pathString(path.clone(), arcstr::literal!("."), true, false)?;
                let args: Vec<Sz> = lst(expLst).map(|a| self.sz_of_exp(a)).collect::<Result<_>>()?;
                match (name.as_str(), &args[..]) {
                    ("max", [a, b]) => a.clone().max(b.clone()),
                    ("min", [a, b]) => a.clone().min(b.clone()),
                    ("div", [a, b]) => a.clone().div(b.clone()),
                    ("integer", [a]) => a.clone(),
                    _ => return unsupported(e),
                }
            }
            _ => return unsupported(e),
        })
    }

    pub(crate) fn sz_of_dim(&mut self, d: &DAE::Dimension) -> Result<Sz> {
        use DAE::Dimension as D;
        Ok(match d {
            D::DIM_INTEGER { integer } => Sz::lit(*integer as i64),
            D::DIM_BOOLEAN => Sz::lit(2),
            D::DIM_ENUM { size, .. } => Sz::lit(*size as i64),
            D::DIM_EXP { exp } => self.sz_of_exp(exp)?,
            D::DIM_UNKNOWN => return Err("CodegenWasmJit: array of unknown size"),
        })
    }

    /// The dimensions of `ty`, outermost first; empty for a scalar.
    pub(crate) fn dims(&mut self, ty: &DAE::Type) -> Result<Vec<Sz>> {
        let mut out = Vec::new();
        let mut t = ty;
        loop {
            match t {
                DAE::Type::T_ARRAY { ty, dims } => {
                    for d in lst(dims) {
                        out.push(self.sz_of_dim(d)?);
                    }
                    t = ty;
                }
                DAE::Type::T_SUBTYPE_BASIC { complexType, .. } => t = complexType,
                _ => return Ok(out),
            }
        }
    }
}

fn unsupported(e: &DAE::Exp) -> Result<Sz> {
    let s = openmodelica_frontend_dump::ExpressionBasics::printExpStr(metamodelica::Ref::new(e.clone())).unwrap_or_default();
    record_error(format!("CodegenWasmJit: the array size `{s}` is not supported for resizable arrays"));
    Err("CodegenWasmJit: unsupported resizable array size")
}

/// Whether any variable's size is not a constant: the model was translated with
/// `--resizableArrays` and has to be laid out with symbolic sizes.
pub(crate) fn has_symbolic_dims(vars: &SimCodeVar::SimVars) -> bool {
    fn symbolic(ty: &DAE::Type) -> bool {
        match ty {
            DAE::Type::T_ARRAY { ty, dims } => {
                lst(dims).any(|d| match &**d {
                    DAE::Dimension::DIM_EXP { exp } => !matches!(&**exp, DAE::Exp::ICONST { .. }),
                    _ => false,
                }) || symbolic(ty)
            }
            DAE::Type::T_SUBTYPE_BASIC { complexType, .. } => symbolic(complexType),
            _ => false,
        }
    }
    all_var_lists(vars).iter().any(|l| lst(l).any(|sv| symbolic(&sv.type_)))
}

pub(crate) fn all_var_lists(vars: &SimCodeVar::SimVars) -> [&List<metamodelica::Ref<SimCodeVar::SimVar>>; 24] {
    [
        &vars.stateVars, &vars.derivativeVars, &vars.algVars, &vars.discreteAlgVars,
        &vars.realOptimizeConstraintsVars, &vars.realOptimizeFinalConstraintsVars, &vars.intAlgVars,
        &vars.boolAlgVars, &vars.inputVars, &vars.outputVars, &vars.aliasVars, &vars.intAliasVars,
        &vars.boolAliasVars, &vars.paramVars, &vars.intParamVars, &vars.boolParamVars, &vars.stringAlgVars,
        &vars.stringParamVars, &vars.stringAliasVars, &vars.extObjVars, &vars.constVars, &vars.intConstVars,
        &vars.boolConstVars, &vars.stringConstVars,
    ]
}

/// An array variable whose size is only known at runtime.
#[derive(Clone)]
pub(crate) struct DynVar {
    pub(crate) sv: metamodelica::Ref<SimCodeVar::SimVar>,
    pub(crate) dims: Vec<Sz>,
}

impl DynVar {
    pub(crate) fn len(&self) -> Sz {
        self.dims.iter().fold(Sz::lit(1), |a, d| a * d.clone())
    }
}

/// The runtime-sized arrays of each `SimVars` list, in list order; the lists
/// themselves keep only the variables of constant size.
#[derive(Default, Clone)]
pub(crate) struct DynVars {
    pub(crate) states: Vec<DynVar>,
    pub(crate) ders: Vec<DynVar>,
    pub(crate) algs: Vec<DynVar>,
    pub(crate) discrete_algs: Vec<DynVar>,
    pub(crate) params: Vec<DynVar>,
    pub(crate) int_algs: Vec<DynVar>,
    pub(crate) int_params: Vec<DynVar>,
    pub(crate) bool_algs: Vec<DynVar>,
    pub(crate) bool_params: Vec<DynVar>,
    pub(crate) aliases: Vec<DynVar>,
    pub(crate) int_aliases: Vec<DynVar>,
    pub(crate) bool_aliases: Vec<DynVar>,
}

pub(crate) fn total(l: &[DynVar]) -> Sz {
    l.iter().fold(Sz::lit(0), |a, v| a + v.len())
}

impl DynVars {
    /// `algVars ++ discreteAlgVars`, the order of `real_alg_vars`.
    pub(crate) fn real_algs(&self) -> Vec<DynVar> {
        self.algs.iter().chain(&self.discrete_algs).cloned().collect()
    }
}

/// `counts` with the runtime-sized arrays added.
pub(crate) fn resizable_counts(c: &openmodelica_sim_meta::LayoutCounts, d: &DynVars) -> openmodelica_sim_meta::LayoutCounts<Sz> {
    let l = |v: u32| Sz::lit(v as i64);
    openmodelica_sim_meta::LayoutCounts {
        n_states: l(c.n_states) + total(&d.states),
        n_real_alg: l(c.n_real_alg) + total(&d.real_algs()),
        n_real_param: l(c.n_real_param) + total(&d.params),
        n_int_alg: l(c.n_int_alg) + total(&d.int_algs),
        n_int_param: l(c.n_int_param) + total(&d.int_params),
        n_bool_alg: l(c.n_bool_alg) + total(&d.bool_algs),
        n_bool_param: l(c.n_bool_param) + total(&d.bool_params),
        n_str_alg: l(c.n_str_alg),
        n_str_param: l(c.n_str_param),
        n_eobj: l(c.n_eobj),
        n_samples: l(c.n_samples),
        n_zc: l(c.n_zc),
        n_rel: l(c.n_rel),
        n_stateset_f64: l(c.n_stateset_f64),
        n_nlsjac_f64: l(c.n_nlsjac_f64),
        n_math: l(c.n_math),
        n_sens: l(c.n_sens),
        n_dae_res: l(c.n_dae_res),
        n_dae_aux: l(c.n_dae_aux),
        n_dae_alg: l(c.n_dae_alg),
        n_base_clocks: l(c.n_base_clocks),
        n_sub_clocks: l(c.n_sub_clocks),
        n_linz: l(c.n_linz),
        n_opt_attr: l(c.n_opt_attr),
        n_attr_log: l(c.n_attr_log),
        n_removed_init: l(c.n_removed_init),
    }
}

/// A count the codegen cannot know: large enough that a loop or allocation
/// sized by it fails loudly.
pub(crate) const UNKNOWN_COUNT: u32 = 0x4000_0000;

/// The layout the codegen addresses through: offsets tagged where they depend on
/// a size ([`crate::CodegenWasmJitFunctions::sizes::sim_offset`]), counts that do
/// set to [`UNKNOWN_COUNT`].
pub(crate) fn tagged_layout(l: &openmodelica_sim_meta::Layout<Sz>) -> Result<SimLayout> {
    use crate::CodegenWasmJitFunctions::sizes::sim_offset;
    let n = |v: &Sz| v.as_const().map_or(UNKNOWN_COUNT, |c| c as u32);
    let o = |v: &Sz| sim_offset(v);
    Ok(SimLayout {
        n_states: n(&l.n_states),
        n_real_alg: n(&l.n_real_alg),
        has_when: l.has_when,
        has_homotopy: l.has_homotopy,
        homotopy_method: l.homotopy_method,
        has_init_lambda0: l.has_init_lambda0,
        has_history_ops: l.has_history_ops,
        has_old_real: l.has_old_real,
        lambda_off: o(&l.lambda_off)?,
        rparam_off: o(&l.rparam_off)?,
        int_off: o(&l.int_off)?,
        iparam_off: o(&l.iparam_off)?,
        bool_off: o(&l.bool_off)?,
        bparam_off: o(&l.bparam_off)?,
        str_off: o(&l.str_off)?,
        sparam_off: o(&l.sparam_off)?,
        eobj_off: o(&l.eobj_off)?,
        pre_real_off: o(&l.pre_real_off)?,
        pre_int_off: o(&l.pre_int_off)?,
        pre_bool_off: o(&l.pre_bool_off)?,
        old_real_off: o(&l.old_real_off)?,
        terminate_off: o(&l.terminate_off)?,
        terminal_off: o(&l.terminal_off)?,
        initial_off: o(&l.initial_off)?,
        term_info_off: o(&l.term_info_off)?,
        n_out_off: o(&l.n_out_off)?,
        nls_fail_off: o(&l.nls_fail_off)?,
        n_samples: n(&l.n_samples),
        sample_off: o(&l.sample_off)?,
        sample_active_off: o(&l.sample_active_off)?,
        n_zc: n(&l.n_zc),
        zc_off: o(&l.zc_off)?,
        zc_pre_off: o(&l.zc_pre_off)?,
        zc_probe_off: o(&l.zc_probe_off)?,
        n_rel: n(&l.n_rel),
        relations_off: o(&l.relations_off)?,
        rel_fresh_off: o(&l.rel_fresh_off)?,
        stored_rel_off: o(&l.stored_rel_off)?,
        relations_pre_off: o(&l.relations_pre_off)?,
        stateset_off: o(&l.stateset_off)?,
        nls_jac_off: o(&l.nls_jac_off)?,
        n_math: n(&l.n_math),
        mathevents_off: o(&l.mathevents_off)?,
        zctol_off: o(&l.zctol_off)?,
        start_off: o(&l.start_off)?,
        real_nom_off: o(&l.real_nom_off)?,
        state_nom_off: o(&l.state_nom_off)?,
        state_max_off: o(&l.state_max_off)?,
        state_min_off: o(&l.state_min_off)?,
        n_sens: n(&l.n_sens),
        sens_off: o(&l.sens_off)?,
        n_dae_res: n(&l.n_dae_res),
        dae_res_off: o(&l.dae_res_off)?,
        n_dae_aux: n(&l.n_dae_aux),
        dae_aux_off: o(&l.dae_aux_off)?,
        n_dae_alg: n(&l.n_dae_alg),
        dae_alg_nom_off: o(&l.dae_alg_nom_off)?,
        n_base_clocks: n(&l.n_base_clocks),
        clock_off: o(&l.clock_off)?,
        n_sub_clocks: n(&l.n_sub_clocks),
        subclock_off: o(&l.subclock_off)?,
        clock_fire_off: o(&l.clock_fire_off)?,
        linz_off: o(&l.linz_off)?,
        n_linz: n(&l.n_linz),
        n_opt_attr: n(&l.n_opt_attr),
        opt_min_off: o(&l.opt_min_off)?,
        opt_max_off: o(&l.opt_max_off)?,
        opt_nom_off: o(&l.opt_nom_off)?,
        opt_use_nom_off: o(&l.opt_use_nom_off)?,
        n_attr_log: n(&l.n_attr_log),
        attr_log_off: o(&l.attr_log_off)?,
        n_removed_init: n(&l.n_removed_init),
        removed_init_res_off: o(&l.removed_init_res_off)?,
        removed_init_idx_off: o(&l.removed_init_idx_off)?,
        sym_solver: l.sym_solver,
        inline_dt_off: o(&l.inline_dt_off)?,
        alg_old_off: o(&l.alg_old_off)?,
        total: o(&l.total)?,
        real_off: o(&l.real_off)?,
        table_off: 0,
        n_table: 0,
        extra_cols: 0,
    })
}

/// Where the reals sit in the real region: the `n_fixed` constant-size ones of the
/// states, derivatives and algebraics (`all_reals` order), each list followed by
/// its runtime-sized arrays, as `build_var_map` lays them out.
pub(crate) struct RealPositions {
    n_fixed: [usize; 3],
    n_states: Sz,
    /// Each runtime-sized real array and the index of its first element.
    pub(crate) dyn_reals: Vec<(DynVar, Sz)>,
}

impl RealPositions {
    pub(crate) fn new(n_fixed: [usize; 3], d: &DynVars) -> RealPositions {
        let n_states = Sz::lit(n_fixed[0] as i64) + total(&d.states);
        let mut dyn_reals = Vec::new();
        let mut idx = Sz::lit(0);
        for (n, dyns) in n_fixed.iter().zip([d.states.clone(), d.ders.clone(), d.real_algs()]) {
            idx = idx + Sz::lit(*n as i64);
            for dv in dyns {
                let len = dv.len();
                dyn_reals.push((dv, idx.clone()));
                idx = idx + len;
            }
        }
        RealPositions { n_fixed, n_states, dyn_reals }
    }

    /// The index of the `i`-th constant-size real (`all_reals` order).
    pub(crate) fn fixed(&self, i: usize) -> Sz {
        let [s, d, _] = self.n_fixed;
        if i < s {
            Sz::lit(i as i64)
        } else if i < s + d {
            self.n_states.clone() + Sz::lit((i - s) as i64)
        } else {
            self.n_states.clone() * 2 + Sz::lit((i - s - d) as i64)
        }
    }
}

/// `SimData` offset of real-region-parallel slot `idx` of the region at `base`.
pub(crate) fn at_real(base: &Sz, idx: &Sz) -> Result<u32> {
    crate::CodegenWasmJitFunctions::sizes::sim_offset(&(base.clone() + idx.clone() * 8))
}
