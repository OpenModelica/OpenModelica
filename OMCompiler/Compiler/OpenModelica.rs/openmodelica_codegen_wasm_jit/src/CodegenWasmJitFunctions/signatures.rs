//! Function signatures: main signature types, variable/type -> `SigTy`.

use super::*;

/// Whether an `external "C"`/"builtin" function maps to a known host math builtin
/// we can route (Approach C, name-based). Only simple return-style scalar
/// functions — `output := extName(inputs)`, all-scalar args/result, no
/// output-pointer arguments — qualify; arrays, output-arg style, or an unknown
/// `extName` are left to fail loudly (the array/library ABI is future work).
pub(crate) fn external_known(f: &SimCodeFunction::Function::Function) -> bool {
    use SimCodeFunction::SimExtArg::SimExtArg as A;
    let SimCodeFunction::Function::Function::EXTERNAL_FUNCTION { extName, funArgs, outVars, extReturn, extArgs, .. } = f else {
        return false;
    };
    // One output, produced as the C call's return value (not via an output ptr).
    if (&**outVars).into_iter().count() != 1 || matches!(&**extReturn, A::SIMNOEXTARG) {
        return false;
    }
    // Every external-call argument must be an input (or a constant exp), never an
    // output pointer or a size argument.
    let args_ok = (&**extArgs).into_iter().all(|a| match &**a {
        A::SIMEXTARG { isInput, .. } => *isInput,
        A::SIMEXTARGEXP { .. } => true,
        _ => false,
    });
    if !args_ok {
        return false;
    }
    let (Ok(ins), Ok(outs)) = (var_sigtys(funArgs), var_sigtys(outVars)) else {
        return false;
    };
    supported_external(extName, &ins, &outs[0])
}

pub(super) fn var_sigtys(vars: &List<Arc<SimCodeFunction::Variable::Variable>>) -> Result<Vec<SigTy>> {
    let mut out = Vec::new();
    for v in &**vars {
        out.push(match &**v {
            SimCodeFunction::Variable::Variable::VARIABLE { ty, instDims, .. } => variable_sigty(ty, instDims)?,
            SimCodeFunction::Variable::Variable::FUNCTION_PTR { tys, args, .. } => {
                closures::function_ptr_sigty(tys, args)?
            }
        });
    }
    Ok(out)
}

/// The `SigTy` of a function variable, combining its declared `ty` with its
/// `instDims`. SimCode is inconsistent about where array dimensions live: an
/// input array's `ty` is the full `T_ARRAY`, while an output/local array's `ty`
/// is the scalar element type with the dimensions in `instDims`. So a `T_ARRAY`
/// `ty` is authoritative (its `dims` are complete); otherwise a non-empty
/// `instDims` makes the scalar `ty` the element type of a rank-`|instDims|` array.
pub(super) fn variable_sigty(ty: &DAE::Type, inst_dims: &List<Arc<DAE::Dimension>>) -> Result<SigTy> {
    // Quiet: `external_known`/`external_general` map a function's variables only to
    // decide whether they can lower the call at all.
    let base = sig_ty_quiet(ty)?;
    if matches!(base, SigTy::Array { .. }) {
        return Ok(base);
    }
    let rank = (&**inst_dims).into_iter().count() as u32;
    if rank == 0 {
        Ok(base)
    } else {
        Ok(SigTy::Array { elem: Arc::new(base), rank })
    }
}

/// Map a `DAE.Type` to a `SigTy`, or fail for types not yet supported. Without
/// the diagnostic: callers that only *probe* a type must not report the ones they
/// go on to handle.
pub(crate) fn sig_ty_quiet(ty: &DAE::Type) -> Result<SigTy> {
    Ok(match ty {
        DAE::Type::T_INTEGER { .. } => SigTy::Int,
        DAE::Type::T_REAL { .. } => SigTy::Real,
        DAE::Type::T_BOOL { .. } => SigTy::Bool,
        // An enumeration value is its 1-based Integer index.
        DAE::Type::T_ENUMERATION { .. } => SigTy::Int,
        DAE::Type::T_STRING { .. } => SigTy::Str,
        // An N-dimensional array. A `T_ARRAY` usually carries all dimensions in
        // `dims` (so `Real[2,3]` is one `T_ARRAY` with two dims), but a nested
        // `T_ARRAY` element is also possible; both flatten to a single rank
        // since Modelica arrays are rectangular.
        DAE::Type::T_ARRAY { ty, dims } => {
            let ndims = (&**dims).into_iter().count() as u32;
            match sig_ty_quiet(ty)? {
                SigTy::Array { elem, rank } => SigTy::Array { elem, rank: rank + ndims },
                elem => SigTy::Array { elem: Arc::new(elem), rank: ndims },
            }
        }
        // A record class: an ordered set of component fields. MetaModelica
        // uniontypes / metarecords (`T_METARECORD`) are a different runtime
        // representation and are not handled here.
        // An external object is an opaque native `void*` held as an `i32` handle.
        DAE::Type::T_COMPLEX { complexClassType: ClassInf::State::EXTERNAL_OBJ { .. }, .. } => SigTy::Ptr,
        DAE::Type::T_COMPLEX { complexClassType, varLst, .. } => {
            let ClassInf::State::RECORD { path } = complexClassType else {
                return Err("CodegenWasmJit: non-record complex type not supported");
            };
            let path_str = AbsynUtil::pathString(path.clone(), arcstr::literal!("."), true, false)?;
            let mut fields = Vec::new();
            match record_decl_fields(&path_str) {
                Some(decl) => {
                    for f in decl.iter() {
                        fields.push((f.name.clone(), sig_ty_quiet(&f.ty)?));
                    }
                }
                None => {
                    for v in &**varLst {
                        fields.push((v.name.clone(), sig_ty_quiet(&v.ty)?));
                    }
                }
            }
            SigTy::Record { path: path_str, fields: Arc::new(fields) }
        }
        // A function reference's argument/result types arrive MetaModelica-boxed
        // (C calls one boxed `boxptr_` shape); our closures are typed and pass
        // values unboxed, so the box is nothing.
        DAE::Type::T_METABOXED { ty } => sig_ty_quiet(ty)?,
        // A function reference: a closure handle, callable with the wrapped
        // function type's signature.
        DAE::Type::T_FUNCTION_REFERENCE_VAR { .. } | DAE::Type::T_FUNCTION_REFERENCE_FUNC { .. } => {
            closures::reference_sigty(ty)?
        }
        DAE::Type::T_SUBTYPE_BASIC { .. } => return Err("CodegenWasmJit: subtype-basic types not yet supported"),
        // Name the variant: `Err` is `&'static str`, and a quiet probe never
        // reaches `record_error`'s unparsed form.
        DAE::Type::T_UNKNOWN { .. } => return Err("CodegenWasmJit: type not supported: T_UNKNOWN"),
        DAE::Type::T_CLOCK { .. } => return Err("CodegenWasmJit: type not supported: Clock"),
        DAE::Type::T_NORETCALL { .. } => return Err("CodegenWasmJit: type not supported: T_NORETCALL"),
        DAE::Type::T_FUNCTION { .. } => return Err("CodegenWasmJit: type not supported: T_FUNCTION"),
        DAE::Type::T_TUPLE { .. } => return Err("CodegenWasmJit: type not supported: T_TUPLE"),
        DAE::Type::T_CODE { .. } => return Err("CodegenWasmJit: type not supported: T_CODE"),
        DAE::Type::T_ANYTYPE { .. } => return Err("CodegenWasmJit: type not supported: T_ANYTYPE"),
        _ => return Err("CodegenWasmJit: type not supported: MetaModelica type"),
    })
}

/// The wasm signature type of a DAE type, reporting the type it cannot handle.
pub(crate) fn sig_ty(ty: &DAE::Type) -> Result<SigTy> {
    sig_ty_quiet(ty).inspect_err(|_| {
        let name = openmodelica_frontend_dump::TypesDump::unparseType(Arc::new(ty.clone()))
            .map(|s| s.to_string())
            .unwrap_or_default();
        crate::CodegenWasmJit::record_error(format!("CodegenWasmJit: type not supported: {name}"));
    })
}
