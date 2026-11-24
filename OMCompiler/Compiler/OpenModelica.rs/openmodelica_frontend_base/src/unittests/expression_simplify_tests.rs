use crate::{Expression, ExpressionSimplify};
use arcstr::literal;
use metamodelica::*;
use openmodelica_ast::Absyn;
use openmodelica_error::ErrorExt;
use openmodelica_frontend_dump::{ExpressionBasics, TypesDump};
use openmodelica_frontend_types::DAE;
use openmodelica_util::{Flags, FlagsUtil};

fn init_flags() {
    let config_vec: Vec<Flags::FlagData> = FlagsUtil::allConfigFlags
        .clone()
        .into_iter()
        .cloned()
        .map(|f| f.defaultValue.clone())
        .collect();
    let debug_vec: Vec<bool> = FlagsUtil::allDebugFlags
        .clone()
        .into_iter()
        .cloned()
        .map(|f| f.default)
        .collect();
    FlagsUtil::saveFlags(Flags::Flag::FLAGS {
        debugFlags: metamodelica::arrayFromVec(debug_vec),
        configFlags: metamodelica::arrayFromVec(config_vec),
    });
}

fn real_array_type(dims: &[Option<i32>]) -> Ref<DAE::Type> {
    let dims: Vec<Ref<DAE::Dimension>> = dims
        .iter()
        .map(|d| {
            Ref::new(match d {
                Some(n) => DAE::Dimension::DIM_INTEGER { integer: *n },
                None => DAE::Dimension::DIM_UNKNOWN,
            })
        })
        .collect();
    Ref::new(DAE::Type::T_ARRAY {
        ty: DAE::T_REAL_DEFAULT(),
        dims: dims.into_iter().collect(),
    })
}

fn rconst(r: f64) -> Ref<DAE::Exp> {
    Ref::new(DAE::Exp::RCONST {
        real: metamodelica::OrderedFloat(r),
    })
}

fn int_cref(name: &str) -> Ref<DAE::Exp> {
    let ty = DAE::T_INTEGER_DEFAULT();
    Ref::new(DAE::Exp::CREF {
        componentRef: Ref::new(DAE::ComponentRef::CREF_IDENT {
            ident: arcstr::format!("{}", name),
            identType: ty.clone(),
            subscriptLst: nil(),
        }),
        ty,
    })
}

/// A literal array with the given dimensions, filled with 1.0, 2.0, ...
fn literal_array(dims: &[i32], next: &mut f64) -> Ref<DAE::Exp> {
    let elems: Vec<Ref<DAE::Exp>> = (0..dims[0])
        .map(|_| {
            if dims.len() == 1 {
                *next += 1.0;
                rconst(*next)
            } else {
                literal_array(&dims[1..], next)
            }
        })
        .collect();
    Ref::new(DAE::Exp::ARRAY {
        ty: real_array_type(&dims.iter().map(|d| Some(*d)).collect::<Vec<_>>()),
        scalar: dims.len() == 1,
        array: elems.into_iter().collect(),
    })
}

fn index(exp: Ref<DAE::Exp>) -> Ref<DAE::Subscript> {
    Ref::new(DAE::Subscript::INDEX { exp })
}

fn wholedim() -> Ref<DAE::Subscript> {
    Ref::new(DAE::Subscript::WHOLEDIM)
}

fn asub(exp: Ref<DAE::Exp>, subs: Vec<Ref<DAE::Subscript>>) -> Ref<DAE::Exp> {
    Ref::new(DAE::Exp::ASUB {
        exp,
        sub: subs.into_iter().collect(),
    })
}

fn has_wholedim(exp: &Ref<DAE::Exp>) -> bool {
    match &**exp {
        DAE::Exp::ASUB { exp, sub } => {
            sub.iter().any(|s| matches!(&**s, DAE::Subscript::WHOLEDIM)) || has_wholedim(exp)
        }
        DAE::Exp::ARRAY { array, .. } => array.iter().any(has_wholedim),
        _ => false,
    }
}

#[test]
fn asub_trailing_wholedim_is_dropped() -> Result<()> {
    init_flags();
    let a = literal_array(&[3, 2], &mut 0.0);
    let (e, changed) = ExpressionSimplify::simplify(asub(a, vec![index(int_cref("j")), wholedim()]))?;
    assert!(changed);
    assert!(!has_wholedim(&e), "{}", ExpressionBasics::printExpStr(e.clone())?);
    assert_eq!(
        ExpressionBasics::printExpStr(e.clone())?.as_str(),
        "{{1.0, 2.0}, {3.0, 4.0}, {5.0, 6.0}}[j]"
    );
    assert_eq!(TypesDump::unparseType(Expression::r#typeof(e)?)?.as_str(), "Real[2]");
    Ok(())
}

#[test]
fn asub_inner_wholedim_is_expanded() -> Result<()> {
    init_flags();
    let b = literal_array(&[2, 2, 2], &mut 0.0);
    let (e, changed) =
        ExpressionSimplify::simplify(asub(b, vec![index(int_cref("j")), wholedim(), index(int_cref("i"))]))?;
    assert!(changed);
    assert!(!has_wholedim(&e), "{}", ExpressionBasics::printExpStr(e.clone())?);
    let DAE::Exp::ARRAY { array, .. } = &*e else {
        panic!("expected an array: {}", ExpressionBasics::printExpStr(e.clone())?);
    };
    let elems: Vec<String> = array
        .iter()
        .map(|x| ExpressionBasics::printExpStr(x.clone()).map(|s| s.to_string()))
        .collect::<Result<_>>()?;
    let lit = "{{{1.0, 2.0}, {3.0, 4.0}}, {{5.0, 6.0}, {7.0, 8.0}}}";
    assert_eq!(elems, vec![format!("{lit}[j,1,i]"), format!("{lit}[j,2,i]")]);
    assert_eq!(TypesDump::unparseType(Expression::r#typeof(e)?)?.as_str(), "Real[2]");
    Ok(())
}

#[test]
fn asub_inner_wholedim_of_unknown_size_is_kept() -> Result<()> {
    init_flags();
    let x = Ref::new(DAE::Exp::CREF {
        componentRef: Ref::new(DAE::ComponentRef::CREF_IDENT {
            ident: literal!("x"),
            identType: real_array_type(&[None, None, None]),
            subscriptLst: nil(),
        }),
        ty: real_array_type(&[None, None, None]),
    });
    let input = asub(x, vec![index(int_cref("j")), wholedim(), index(int_cref("i"))]);
    let (e, changed) = ExpressionSimplify::simplify(input.clone())?;
    assert!(!changed);
    assert!(
        referenceEq(&*e, &*input),
        "{}",
        ExpressionBasics::printExpStr(e.clone())?
    );
    Ok(())
}

#[test]
fn failed_simplify_leaves_no_checkpoint() {
    init_flags();
    let record = Ref::new(DAE::Exp::RECORD {
        path: Ref::new(Absyn::Path::IDENT { name: literal!("R") }),
        exps: list![rconst(1.0)],
        comp: list![literal!("a")],
        ty: DAE::T_COMPLEX_DEFAULT_RECORD(),
    });
    let rsub = Ref::new(DAE::Exp::RSUB {
        exp: record,
        ix: -1,
        fieldName: literal!("b"),
        ty: DAE::T_REAL_DEFAULT(),
    });
    assert!(ExpressionSimplify::simplify(rsub).is_err());
    assert_eq!(ErrorExt::getNumCheckpoints(), 0);
}
