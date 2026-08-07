//! `--linearizationDumpLanguage`: the `linear_model_frame()` half of the C
//! target's `simulationFile_lnz` / `functionlinearmodel*` templates.
//!
//! `openmodelica_sim_meta::linearize` fills the `printf` conversions at run time,
//! so these are the C templates' string *values*, `%s`/`%g`/`%%` included.

use metamodelica::List;
use openmodelica_backend_types::BackendDAE;
use openmodelica_frontend_types::DAE;
use openmodelica_simcode_types::{SimCode, SimCodeVar};
use openmodelica_sim_meta::LinLanguage;
use std::fmt::Write;
use std::sync::Arc;

use crate::CodegenWasmJit::lst;

/// The four frames plus the diagnostic C prints when linearization is off.
pub(crate) struct Frames {
    pub language: LinLanguage,
    pub frame: String,
    pub frame_datarec: String,
    /// C's message ahead of the empty frame; empty when a frame was built.
    pub disabled_reason: String,
}

/// C's `crefStrNoUnderscore`.
fn cref_str(cr: &Arc<DAE::ComponentRef>) -> String {
    use DAE::ComponentRef as C;
    match &**cr {
        C::CREF_IDENT { ident, subscriptLst, .. } => format!("{ident}{}", subscripts(subscriptLst, false)),
        C::CREF_QUAL { ident, componentRef, .. } if &**ident == "$DER" => {
            format!("der({})", cref_str(componentRef))
        }
        C::CREF_QUAL { ident, componentRef, .. } if &**ident == "$CLKPRE" => {
            format!("previous({})", cref_str(componentRef))
        }
        C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
            format!("{ident}{}.{}", subscripts(subscriptLst, false), cref_str(componentRef))
        }
        _ => "CREF_NOT_IDENT_OR_QUAL".to_string(),
    }
}

/// C's `crefStrMatlabSafe`: an identifier for the target language's name list.
fn cref_str_safe(cr: &Arc<DAE::ComponentRef>) -> String {
    use DAE::ComponentRef as C;
    match &**cr {
        C::CREF_IDENT { ident, subscriptLst, .. } => format!("{ident}{}", subscripts(subscriptLst, true)),
        C::CREF_QUAL { ident, componentRef, .. } if &**ident == "$DER" => {
            format!("der_{}", cref_str_safe(componentRef))
        }
        C::CREF_QUAL { ident, componentRef, .. } if &**ident == "$CLKPRE" => {
            format!("pre_{}", cref_str_safe(componentRef))
        }
        C::CREF_QUAL { ident, subscriptLst, componentRef, .. } => {
            format!("{ident}{}_{}", subscripts(subscriptLst, true), cref_str_safe(componentRef))
        }
        _ => "CREF_NOT_IDENT_OR_QUAL".to_string(),
    }
}

fn subscripts(subs: &Arc<List<Arc<DAE::Subscript>>>, matlab_safe: bool) -> String {
    let items: Vec<String> = lst(subs).map(|s| subscript_str(s)).collect();
    if items.is_empty() {
        return String::new();
    }
    let (open, close) = if matlab_safe { ('(', ')') } else { ('[', ']') };
    format!("{open}{}{close}", items.join(","))
}

/// C's `subscriptStr`: only the constant-index forms a scalarized name carries.
fn subscript_str(s: &DAE::Subscript) -> String {
    use DAE::Exp as E;
    use DAE::Subscript as S;
    let exp = match s {
        S::INDEX { exp } | S::SLICE { exp } => exp,
        S::WHOLEDIM => return "WHOLEDIM".to_string(),
        S::WHOLE_NONEXP { .. } => return "WHOLE_NONEXP".to_string(),
    };
    match &**exp {
        E::ICONST { integer } => integer.to_string(),
        E::BCONST { bool } => bool.to_string(),
        E::ENUM_LITERAL { name, .. } => openmodelica_frontend_dump::AbsynUtil::pathString(
            name.clone(),
            arcstr::literal!("."),
            true,
            false,
        )
        .map(|p| p.to_string())
        .unwrap_or_default(),
        E::CREF { .. } => openmodelica_frontend_dump::ExpressionBasics::printExpStr(exp.clone())
            .map(|p| p.to_string())
            .unwrap_or_default(),
        _ => "UNKNOWN_SUBSCRIPT".to_string(),
    }
}

/// C's `escapeSingleQuoteIdent`.
fn escape_quoted(ident: &str) -> String {
    ident.replace("\\'", "\\\\'").replace('\'', "\\'")
}

/// C's `genMatrix` family. A zero dimension leaves a `zeros(...)` literal — the
/// `%s` stays so the (empty) argument is still consumed.
fn gen_matrix(lang: LinLanguage, name: &str, row: &str, col: &str, row_n: u32, col_n: u32) -> String {
    let empty = row_n == 0 || col_n == 0;
    match (lang, empty) {
        (LinLanguage::Modelica, true) => format!("  parameter Real {name}[{row}, {col}] = zeros({row}, {col});%s\n\n"),
        (LinLanguage::Modelica, false) => format!("  parameter Real {name}[{row}, {col}] =\n\t[%s];\n\n"),
        (LinLanguage::Matlab, true) => format!("  {name} = zeros({row}, {col});%s\n\n"),
        (LinLanguage::Matlab, false) => format!("  {name} =\t[%s];\n\n"),
        (LinLanguage::Julia, true) => format!("  local {name} = zeros({row}, {col})%s\n"),
        (LinLanguage::Julia, false) => format!("  local {name} = [%s]\n\n"),
        (LinLanguage::Python, _) => format!("    {name} = %s\n\n"),
    }
}

/// C's `genVector`; `flag` is C's 0 = plain, 1 = input, 2 = output.
fn gen_vector(name: &str, num: &str, num_n: u32, flag: u32) -> String {
    match flag {
        0 if num_n == 0 => format!("  Real {name}[{num}];\n"),
        0 => format!("  Real {name}[{num}](start={name}0);\n"),
        1 if num_n == 0 => format!("  input Real {name}[{num}];\n"),
        1 => format!("  input Real {name}[{num}](start={name}0);\n"),
        _ => format!("  output Real {name}[{num}];\n"),
    }
}

/// C's `getVarNameC`: keeps the original names in the linearized model.
fn var_names_modelica(vars: &[&SimCodeVar::SimVar], array: &str) -> String {
    let mut out = String::new();
    for (i, sv) in vars.iter().enumerate() {
        let _ = writeln!(
            out,
            "  Real '{array}_{}' = {array}[{}];",
            escape_quoted(&cref_str(&sv.name)),
            i + 1
        );
    }
    out
}

/// C's `getVarNameMatlab`/`Python`/`Julia`; Julia quotes with `"`.
fn var_names_list(vars: &[&SimCodeVar::SimVar], lang: LinLanguage) -> String {
    let q = if lang == LinLanguage::Julia { '"' } else { '\'' };
    vars.iter().map(|sv| format!("{q}{}{q}", cref_str_safe(&sv.name))).collect::<Vec<_>>().join(",")
}

/// C's `simulationFile_lnz`: `none`, an oversized system and `--daeMode` each
/// leave empty frames behind a diagnostic.
pub(crate) fn build_frames(
    vars: &SimCodeVar::SimVars,
    n_states: u32,
    n_in: u32,
    n_out: u32,
    n_alg: u32,
    prefix: &str,
) -> metamodelica::Result<Frames> {
    use openmodelica_util::Flags;
    let disabled = |reason: &str| Frames {
        language: LinLanguage::Modelica,
        frame: String::new(),
        frame_datarec: String::new(),
        disabled_reason: reason.to_string(),
    };
    let language = match &*Flags::getConfigString(Flags::LINEARIZATION_DUMP_LANGUAGE.clone())? {
        "none" => {
            return Ok(disabled(
                "Linearization disabled. Use compiler flag `--linearizationDumpLanguage` to change target language.",
            ));
        }
        "modelica" => LinLanguage::Modelica,
        "matlab" => LinLanguage::Matlab,
        "julia" => LinLanguage::Julia,
        "python" => LinLanguage::Python,
        _ => return Err("CodegenWasmJit: unknown linearization language"),
    };
    let max_size = Flags::getConfigInt(Flags::MAX_SIZE_LINEARIZATION.clone())?;
    if (n_states + n_in + n_out + n_alg) as i32 > max_size {
        return Ok(disabled("System too big. Use compiler flag `--maxSizeLinearization` to change threshold."));
    }
    if Flags::getConfigBool(Flags::DAE_MODE.clone())? {
        return Ok(disabled("Linearization not available with `--daeMode`."));
    }

    let states: Vec<&SimCodeVar::SimVar> = lst(&vars.stateVars).collect();
    let inputs: Vec<&SimCodeVar::SimVar> = lst(&vars.inputVars).collect();
    let outputs: Vec<&SimCodeVar::SimVar> = lst(&vars.outputVars).collect();
    let algs: Vec<&SimCodeVar::SimVar> = lst(&vars.algVars).collect();
    let m = |name: &str, row: &str, col: &str, r: u32, c: u32| gen_matrix(language, name, row, col, r, c);
    let (a, b, c, d) = (
        m("A", "n", "n", n_states, n_states),
        m("B", "n", "m", n_states, n_in),
        m("C", "p", "n", n_out, n_states),
        m("D", "p", "m", n_out, n_in),
    );
    let (cz, dz) = (m("Cz", "nz", "n", n_alg, n_states), m("Dz", "nz", "m", n_alg, n_in));

    let (frame, frame_datarec) = match language {
        LinLanguage::Modelica => {
            let head = |extra: &str| {
                format!(
                    "model linearized_model \"{prefix}\"\n\
                     \x20 parameter Integer n = {n_states} \"number of states\";\n\
                     \x20 parameter Integer m = {n_in} \"number of inputs\";\n\
                     \x20 parameter Integer p = {n_out} \"number of outputs\";\n{extra}\n"
                )
            };
            let vec_x = gen_vector("x", "n", n_states, 0);
            let vec_u = gen_vector("u", "m", n_in, 1);
            let vec_y = gen_vector("y", "p", n_out, 2);
            let vec_z = gen_vector("z", "nz", n_alg, 2);
            let nm_x = var_names_modelica(&states, "x");
            let nm_u = var_names_modelica(&inputs, "u");
            let nm_y = var_names_modelica(&outputs, "y");
            let nm_z = var_names_modelica(&algs, "z");
            (
                format!(
                    "{}  parameter Real x0[n] = %s;\n  parameter Real u0[m] = %s;\n\n\
                     {a}{b}{c}{d}\n{vec_x}{vec_u}{vec_y}\n{nm_x}{nm_u}{nm_y}\
                     equation\n  der(x) = A * x + B * u;\n  y = C * x + D * u;\nend linearized_model;\n",
                    head("")
                ),
                format!(
                    "{}  parameter Real x0[n] = %s;\n  parameter Real u0[m] = %s;\n  parameter Real z0[nz] = %s;\n\n\
                     {a}{b}{c}{d}{cz}{dz}\n{vec_x}{vec_u}{vec_y}{vec_z}\n{nm_x}{nm_u}{nm_y}{nm_z}\
                     equation\n  der(x) = A * x + B * u;\n  y = C * x + D * u;\n  z = Cz * x + Dz * u;\nend linearized_model;\n",
                    head(&format!("  parameter Integer nz = {n_alg} \"data recovery variables\";\n"))
                ),
            )
        }
        LinLanguage::Matlab => (
            format!(
                "function [A, B, C, D, stateVars, inputVars, outputVars] = linearized_model()\n\
                 %% {prefix}\n%% der(x) = A * x + B * u\n%% y = C * x + D * u\n\
                 \x20 n = {n_states}; %% number of states\n\
                 \x20 m = {n_in}; %% number of inputs\n\
                 \x20 p = {n_out}; %% number of outputs\n\n\
                 \x20 x0 = %s;\n  u0 = %s;\n\n{a}{b}{c}{d}\
                 \x20 stateVars  = {{{}}};\n  inputVars  = {{{}}};\n  outputVars = {{{}}};\n\
                 \x20 Ts = %g; %% stop time\n\nend",
                var_names_list(&states, language),
                var_names_list(&inputs, language),
                var_names_list(&outputs, language),
            ),
            String::new(),
        ),
        LinLanguage::Julia => (
            format!(
                "function linearized_model()\n  # {prefix} #\n\
                 \x20 local n = {n_states} # number of states\n\
                 \x20 local m = {n_in} # number of inputs\n\
                 \x20 local p = {n_out} # number of outputs\n\n\
                 \x20 local x0 = %s\n  local u0 = %s\n\n{a}{b}{c}{d}\
                 \x20 stateVars  = [{}]\n  inputVars  = [{}]\n  outputVars = [{}]\n\
                 \x20 Ts = %g; #stop time\n\n\n\
                 \x20 return (n, m, p, x0, u0, A, B, C, D, stateVars, inputVars, outputVars)\nend",
                var_names_list(&states, language),
                var_names_list(&inputs, language),
                var_names_list(&outputs, language),
            ),
            String::new(),
        ),
        LinLanguage::Python => (
            format!(
                "def linearized_model():\n    # {prefix}\n    # der(x) = A * x + B * u\n    # y = C * x + D * u\n\
                 \x20   n = {n_states} # number of states\n\
                 \x20   m = {n_in} # number of inputs\n\
                 \x20   p = {n_out} # number of outputs\n\n\
                 \x20   x0 = %s\n    u0 = %s\n\n{a}{b}{c}{d}\
                 \x20   stateVars  = [{}]\n    inputVars  = [{}]\n    outputVars = [{}]\n\n\
                 \x20   return (n, m, p, x0, u0, A, B, C, D, stateVars, inputVars, outputVars)\n",
                var_names_list(&states, language),
                var_names_list(&inputs, language),
                var_names_list(&outputs, language),
            ),
            String::new(),
        ),
    };
    let datarec_reason = match language {
        LinLanguage::Modelica => String::new(),
        LinLanguage::Matlab => "Linearization with data recovery not implemented for Matlab.".to_string(),
        LinLanguage::Julia => "Linearization with data recovery not implemented for Julia.".to_string(),
        LinLanguage::Python => "Linearization with data recovery not implemented for Python.".to_string(),
    };
    Ok(Frames { language, frame, frame_datarec, disabled_reason: datarec_reason })
}

/// Every row the sparsity pattern says can be nonzero has a `JAC_VAR` result to
/// read it from. A row without one is a structural zero (C reads it back from its
/// `calloc`d `resultVars`); a row the pattern claims but the lowering cannot
/// produce — an array-valued `$pDER` result — would silently zero the matrix.
fn covers_sparsity(jm: &SimCode::JacobianMatrix, rows: u32) -> bool {
    let produced: Vec<usize> = crate::CodegenWasmJit::jac_column_vars(jm)
        .iter()
        .filter(|v| matches!(v.varKind, BackendDAE::VarKind::JAC_VAR))
        .filter_map(crate::CodegenWasmJit::jac_result_row)
        .collect();
    lst(&jm.sparsity)
        .flat_map(|(_, nz)| lst(nz))
        .all(|r| (*r as u32) < rows && produced.contains(&(*r as usize)))
}

/// The `A`,`B`,`C`,`D` Jacobians the flat emitter can lower, with the shape each
/// one actually has (C's per-matrix `initialAnalyticJacobian<X>`: `sizeCols` is the
/// seed count, `sizeRows` covers every row the results and the sparsity mention).
///
/// The shape is read off the matrix rather than derived from
/// `nStates`/`nInputVars`/`nOutputVars`, because `DynamicOptimization` reshapes
/// these same matrices for an `optimization` model — B and C then have
/// `nStates+nInputVars` columns and a row per state, path constraint and objective
/// term. [`crate::CodegenWasmJit::LinzPlan`] compares the shape against what `-l`
/// expects and only lets the linearization use the ones that match.
pub(crate) fn symbolic_jacobians(
    sim_code: &SimCode::SimCode,
) -> [Option<(Arc<SimCode::JacobianMatrix>, u32, u32)>; 4] {
    let names = ["A", "B", "C", "D"];
    core::array::from_fn(|k| {
        let jm = lst(&sim_code.jacobianMatrices).find(|j| &*j.matrixName == names[k])?.clone();
        let cols = crate::CodegenWasmJit::count(&jm.seedVars) as u32;
        let rows = matrix_rows(&jm);
        if rows == 0 || cols == 0 {
            return None;
        }
        // A sparsity-only matrix carries seeds but no equations; C reports it as
        // `JACOBIAN_NOT_AVAILABLE`.
        let has_equations = lst(&jm.columns)
            .next()
            .is_some_and(|c| lst(&c.columnEqns).next().is_some());
        let usable =
            has_equations && covers_sparsity(&jm, rows) && crate::CodegenWasmJit::jac_lowerable(&jm);
        usable.then_some((jm, rows, cols))
    })
}

/// C's `sizeRows`: one past the last row either a `JAC_VAR` result or the sparsity
/// pattern names.
fn matrix_rows(jm: &SimCode::JacobianMatrix) -> u32 {
    let results = crate::CodegenWasmJit::jac_column_vars(jm)
        .iter()
        .filter(|v| matches!(v.varKind, BackendDAE::VarKind::JAC_VAR))
        .filter_map(crate::CodegenWasmJit::jac_result_row)
        .map(|r| r as u32 + 1)
        .max()
        .unwrap_or(0);
    let sparse = lst(&jm.sparsity)
        .flat_map(|(_, nz)| lst(nz))
        .map(|r| *r as u32 + 1)
        .max()
        .unwrap_or(0);
    results.max(sparse)
}
