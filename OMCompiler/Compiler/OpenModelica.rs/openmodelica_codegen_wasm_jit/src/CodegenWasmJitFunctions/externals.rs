//! External function classification: known, shared and general externals,
//! declined reasons, import signatures.

use super::*;

/// Whether external function `ext_name` with input types `ins` and result type
/// `out` is one this codegen can route (Approach C, name-based). Covers scalar
/// libm math (host builtins / inline) and the pure `ModelicaStrings` functions
/// that map directly to existing runtime string ops.
pub(super) fn supported_external(ext_name: &str, ins: &[SigTy], out: &SigTy) -> bool {
    let scalar = |s: &SigTy| matches!(s, SigTy::Int | SigTy::Real | SigTy::Bool);
    match ext_name {
        // `Modelica.Utilities.Strings.length` → `rt_str_len`.
        "ModelicaStrings_length" => matches!(ins, [SigTy::Str]) && matches!(out, SigTy::Int),
        // `Modelica.Utilities.Strings.substring` → `rt_substring` (1-based incl.).
        "ModelicaStrings_substring" => matches!(ins, [SigTy::Str, SigTy::Int, SigTy::Int]) && matches!(out, SigTy::Str),
        // Scalar math: a host transcendental or single-instruction math function.
        _ if builtin_index(ext_name).is_some()
            || matches!(ext_name, "sqrt" | "fabs" | "floor" | "ceil" | "abs" | "div" | "mod") =>
        {
            ins.iter().all(scalar) && scalar(out)
        }
        _ => false,
    }
}

/// The declared-output slot an `extArgs` entry writes, 1-based as `SimExtArg`
/// records it; 0 for an input-side argument. `isInput` does *not* answer this: a
/// protected `biVars` local is `isInput = false, outputIndex = 0` and passed in.
pub(super) fn ext_arg_output_index(a: &SimCodeFunction::SimExtArg::SimExtArg) -> usize {
    use SimCodeFunction::SimExtArg::SimExtArg as A;
    match a {
        A::SIMEXTARG { outputIndex, .. } | A::SIMEXTARGSIZE { outputIndex, .. } => (*outputIndex).max(0) as usize,
        _ => 0,
    }
}

/// The external calling convention of `language`, or `None` for one we do not
/// lower. `"BUILTIN"` shares C's convention, as in `extFunCall`.
fn ext_lang(language: &str) -> Option<ExtLang> {
    match language {
        "C" | "BUILTIN" => Some(ExtLang::C),
        "FORTRAN 77" => Some(ExtLang::Fortran77),
        _ => None,
    }
}

thread_local! {
    /// Externals left out of the module, by Modelica identifier, with why. A call
    /// to one reports that instead of failing as an unknown builtin — the name
    /// reaching [`compile_math_builtin`] looks the same either way.
    static DECLINED_EXTERNALS: std::cell::RefCell<HashMap<String, String>> =
        std::cell::RefCell::new(HashMap::new());
}

pub(crate) fn reset_declined_externals() {
    DECLINED_EXTERNALS.with(|d| d.borrow_mut().clear());
}

pub(crate) fn note_declined_external(f: &SimCodeFunction::Function::Function, why: String) {
    let SimCodeFunction::Function::Function::EXTERNAL_FUNCTION { name, .. } = f else { return };
    let ident = AbsynUtil::pathLastIdent(name.clone());
    DECLINED_EXTERNALS.with(|d| d.borrow_mut().insert(ident.to_string(), why));
}

pub(super) fn declined_external_reason(ident: &str) -> Option<String> {
    DECLINED_EXTERNALS.with(|d| d.borrow().get(ident).cloned())
}

/// A general external function routed to an `ext.<extName>` host import: one
/// whose `extName` is not a known builtin ([`external_known`]). Every value
/// crossing the C boundary must be a marshallable kind — scalar
/// (Real/Integer/Boolean), `String` (→ `char*`), an external object (→ `void*`),
/// or an array (→ a pointer to its data); only the return value may not be an
/// array.
pub(crate) fn external_general(f: &SimCodeFunction::Function::Function) -> bool {
    external_general_why(f).is_ok()
}

/// [`external_general`] with the rejection reason, for the diagnostics the
/// unlowered call site reports.
pub(crate) fn external_general_why(f: &SimCodeFunction::Function::Function) -> std::result::Result<(), String> {
    use SimCodeFunction::SimExtArg::SimExtArg as A;
    if external_known(f) {
        return Err("lowered as a known math/string builtin".to_string());
    }
    let SimCodeFunction::Function::Function::EXTERNAL_FUNCTION { funArgs, outVars, biVars, extReturn, extArgs, language, .. } = f else {
        return Err("not an external function".to_string());
    };
    if ext_lang(language).is_none() {
        return Err(format!("external language \"{language}\" is not supported"));
    }
    // The host converts a record field by field, so each field must marshal too.
    fn record_ok(s: &SigTy) -> bool {
        match s {
            SigTy::Record { fields, .. } => fields.iter().all(|(_, t)| {
                matches!(t, SigTy::Int | SigTy::Real | SigTy::Bool | SigTy::Str | SigTy::Array { .. }) || record_ok(t)
            }),
            _ => false,
        }
    }
    let arg_ok = |s: &SigTy| {
        matches!(s, SigTy::Int | SigTy::Real | SigTy::Bool | SigTy::Str | SigTy::Ptr | SigTy::Array { .. })
            || record_ok(s)
    };
    let ret_ok = |s: &SigTy| {
        matches!(s, SigTy::Int | SigTy::Real | SigTy::Bool | SigTy::Str | SigTy::Ptr) || record_ok(s)
    };
    let n_out = (&**outVars).into_iter().count();
    // Each declared output is written by at most one `extArgs` entry (or the
    // return value); one left unwritten keeps its binding, as in the C target.
    let mut written = vec![false; n_out];
    // Written once — except that a record output may be filled through its pointer
    // *and* have one field assigned from the return value, different lvalues.
    let mut claim = |oi: usize, field: bool| -> bool {
        if oi == 0 {
            return true;
        }
        oi <= n_out && (field || !std::mem::replace(&mut written[oi - 1], true))
    };
    for a in &**extArgs {
        let ty = match &**a {
            A::SIMEXTARGSIZE { .. } => SigTy::Int,
            A::SIMEXTARG { type_, .. } | A::SIMEXTARGEXP { type_, .. } => {
                sig_ty_quiet(type_).map_err(|e| e.to_string())?
            }
            _ => return Err("unsupported external-call argument".to_string()),
        };
        if !arg_ok(&ty) {
            return Err(format!("argument type {ty:?} cannot be marshalled"));
        }
        if !claim(ext_arg_output_index(a), false) {
            return Err("an argument writes an output the function does not declare".to_string());
        }
    }
    match &**extReturn {
        A::SIMNOEXTARG => {}
        A::SIMEXTARG { type_, outputIndex, cref, .. } => {
            let t = sig_ty_quiet(type_).map_err(|e| e.to_string())?;
            if !ret_ok(&t) || !claim((*outputIndex).max(0) as usize, cref_field(cref).is_some()) {
                return Err(format!("return type {t:?} cannot be marshalled"));
            }
        }
        _ => return Err("unsupported external return".to_string()),
    }
    for (what, vars) in [("input", funArgs), ("output", outVars), ("protected variable", biVars)] {
        let tys = var_sigtys(vars).map_err(|e| format!("{what}: {e}"))?;
        if let Some(t) = tys.iter().find(|t| !arg_ok(t)) {
            return Err(format!("{what} of type {t:?} is not supported"));
        }
    }
    Ok(())
}

/// The C-call shape ([`ExtCallSig`]) of a general external function, for its
/// `ext.<extName>` import. Distinct from [`function_signature`] (the Modelica
/// wrapper's own signature).
pub(crate) fn external_import_sig(f: &SimCodeFunction::Function::Function) -> Result<ExtCallSig> {
    use SimCodeFunction::SimExtArg::SimExtArg as A;
    let SimCodeFunction::Function::Function::EXTERNAL_FUNCTION { extName, extArgs, extReturn, language, includes, .. } =
        f
    else {
        return Err("CodegenWasmJit: external_import_sig on a non-external function");
    };
    let lang = ext_lang(language).ok_or("CodegenWasmJit: unsupported external language")?;
    let mut args: Vec<(SigTy, bool)> = Vec::new();
    for a in &**extArgs {
        let ty = match &**a {
            // A `size(array, dim)` argument is a C `int` dimension (input).
            A::SIMEXTARGSIZE { .. } => SigTy::Int,
            A::SIMEXTARG { type_, .. } | A::SIMEXTARGEXP { type_, .. } => sig_ty(type_)?,
            other => return Err("CodegenWasmJit: unsupported external-call argument"),
        };
        args.push((ty, ext_arg_output_index(a) != 0));
    }
    let ret = match &**extReturn {
        A::SIMNOEXTARG => None,
        A::SIMEXTARG { type_, .. } => Some(sig_ty(type_)?),
        other => return Err("CodegenWasmJit: unsupported external return"),
    };
    // Fortran symbols carry a trailing underscore, as `extFunCallF77` emits.
    let name = match lang {
        ExtLang::C => extName.to_string(),
        ExtLang::Fortran77 => format!("{extName}_"),
    };
    Ok(ExtCallSig { name, lang, args, ret, declare: includes.is_empty() })
}

/// The input/output scalar `SigTy`s of the main function, for the sidecar.
pub(super) fn main_sig_types(f: &SimCodeFunction::Function::Function) -> Result<(Vec<SigTy>, Vec<SigTy>)> {
    use SimCodeFunction::Function::Function as F;
    match f {
        F::FUNCTION { outVars, functionArguments, .. } => Ok((var_sigtys(functionArguments)?, var_sigtys(outVars)?)),
        F::EXTERNAL_FUNCTION { outVars, funArgs, .. } if external_known(f) || external_general(f) => Ok((var_sigtys(funArgs)?, var_sigtys(outVars)?)),
        _ => return Err("CodegenWasmJit: only plain FUNCTIONs and known scalar-math external functions are supported"),
    }
}
