use std::sync::Arc;
use anyhow::Result;
use arcstr::literal;
use metamodelica::*;
use openmodelica_frontend_types::DAE;
use crate::ExpressionBasics;
use openmodelica_util::{FlagsUtil, Flags};

// Initialize flags with default values for the current thread.
// Required by print functions that call Config::modelicaOutput() etc.
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

fn iconst(i: i32) -> Arc<DAE::Exp> {
    Arc::new(DAE::Exp::ICONST { integer: i })
}

fn rconst(r: f64) -> Arc<DAE::Exp> {
    Arc::new(DAE::Exp::RCONST { real: metamodelica::OrderedFloat(r) })
}

fn bconst(b: bool) -> Arc<DAE::Exp> {
    Arc::new(DAE::Exp::BCONST { bool: b })
}

fn sconst(s: &str) -> Arc<DAE::Exp> {
    Arc::new(DAE::Exp::SCONST { string: arcstr::format!("{}", s) })
}

fn index_sub(exp: Arc<DAE::Exp>) -> Arc<DAE::Subscript> {
    Arc::new(DAE::Subscript::INDEX { exp })
}

fn wholedim() -> Arc<DAE::Subscript> {
    Arc::new(DAE::Subscript::WHOLEDIM)
}

fn add_op() -> DAE::Operator {
    DAE::Operator::ADD { ty: DAE::T_REAL_DEFAULT().clone() }
}

fn sub_op() -> DAE::Operator {
    DAE::Operator::SUB { ty: DAE::T_REAL_DEFAULT().clone() }
}

fn make_binary(e1: Arc<DAE::Exp>, op: DAE::Operator, e2: Arc<DAE::Exp>) -> Arc<DAE::Exp> {
    Arc::new(DAE::Exp::BINARY { exp1: e1, operator: op, exp2: e2 })
}

fn make_unary(op: DAE::Operator, e: Arc<DAE::Exp>) -> Arc<DAE::Exp> {
    Arc::new(DAE::Exp::UNARY { operator: op, exp: e })
}

// ---------------------------------------------------------------------------
// compare
// ---------------------------------------------------------------------------

#[test]
fn compare_same_iconst_returns_zero() -> Result<()> {
    let result = ExpressionBasics::compare(iconst(5), iconst(5))?;
    assert_eq!(result, 0);
    Ok(())
}

#[test]
fn compare_iconst_less_than() -> Result<()> {
    let result = ExpressionBasics::compare(iconst(3), iconst(7))?;
    assert!(result < 0, "expected negative, got {}", result);
    Ok(())
}

#[test]
fn compare_iconst_greater_than() -> Result<()> {
    let result = ExpressionBasics::compare(iconst(7), iconst(3))?;
    assert!(result > 0, "expected positive, got {}", result);
    Ok(())
}

/// Bug: compare(ICONST, RCONST) should return a non-zero value indicating that
/// the two expressions have different constructors.  Instead it errors with
/// "pattern mismatch" because valueConstructor::<Arc<DAE::Exp>>() always
/// returns the same hash regardless of the runtime variant, so comp == 0
/// and the code falls into the ICONST match arm while inExp2 is RCONST.
#[test]
fn compare_different_constructors_should_return_nonzero_not_error() -> Result<()> {
    let result = ExpressionBasics::compare(iconst(1), rconst(1.0))?;
    assert_ne!(result, 0, "expected non-zero for different constructors, got 0");
    Ok(())
}

/// Same bug, different direction.
#[test]
fn compare_rconst_vs_iconst_should_return_nonzero_not_error() -> Result<()> {
    let result = ExpressionBasics::compare(rconst(1.0), iconst(1))?;
    assert_ne!(result, 0, "expected non-zero for different constructors, got 0");
    Ok(())
}

/// compare(BCONST, ICONST) — different constructors should give non-zero.
#[test]
fn compare_bconst_vs_iconst_should_return_nonzero_not_error() -> Result<()> {
    let result = ExpressionBasics::compare(bconst(true), iconst(0))?;
    assert_ne!(result, 0, "expected non-zero for different constructors, got 0");
    Ok(())
}

/// compare(SCONST, RCONST) — different constructors should give non-zero.
#[test]
fn compare_sconst_vs_rconst_should_return_nonzero_not_error() -> Result<()> {
    let result = ExpressionBasics::compare(sconst("hello"), rconst(1.0))?;
    assert_ne!(result, 0, "expected non-zero for different constructors, got 0");
    Ok(())
}

// ---------------------------------------------------------------------------
// expEqual
// ---------------------------------------------------------------------------

#[test]
fn exp_equal_same_iconst() -> Result<()> {
    assert_eq!(ExpressionBasics::expEqual(iconst(5), iconst(5))?, true);
    Ok(())
}

#[test]
fn exp_equal_different_iconst() -> Result<()> {
    assert_eq!(ExpressionBasics::expEqual(iconst(5), iconst(6))?, false);
    Ok(())
}

#[test]
fn exp_equal_same_rconst() -> Result<()> {
    assert_eq!(ExpressionBasics::expEqual(rconst(3.14), rconst(3.14))?, true);
    Ok(())
}

#[test]
fn exp_equal_different_rconst() -> Result<()> {
    assert_eq!(ExpressionBasics::expEqual(rconst(1.0), rconst(2.0))?, false);
    Ok(())
}

// ---------------------------------------------------------------------------
// operatorCompare
// ---------------------------------------------------------------------------

/// Bug: operatorCompare(ADD{ty}, SUB{ty}) should return non-zero because they
/// are different variants.  Instead it always returns 0 because both
/// `valueConstructor::<DAE::Operator>()` calls receive the same type parameter
/// and therefore produce the same hash.
#[test]
fn operator_compare_add_vs_sub_should_return_nonzero() -> Result<()> {
    let result = ExpressionBasics::operatorCompare(add_op(), sub_op())?;
    assert_ne!(result, 0, "ADD and SUB should compare as unequal");
    Ok(())
}

/// Corollary: compare(BINARY(a,ADD,b), BINARY(a,SUB,b)) should return non-zero.
/// Because operatorCompare is broken, compare returns 0 (equal) for these.
#[test]
fn compare_binary_add_vs_binary_sub_should_return_nonzero() -> Result<()> {
    let lhs = make_binary(iconst(1), add_op(), iconst(2));
    let rhs = make_binary(iconst(1), sub_op(), iconst(2));
    let result = ExpressionBasics::compare(lhs, rhs)?;
    assert_ne!(result, 0, "BINARY(ADD) and BINARY(SUB) should compare as unequal");
    Ok(())
}

#[test]
fn operator_compare_same_add_returns_zero() -> Result<()> {
    let result = ExpressionBasics::operatorCompare(add_op(), add_op())?;
    assert_eq!(result, 0, "same operator should compare as equal");
    Ok(())
}

// ---------------------------------------------------------------------------
// dimensionString
// ---------------------------------------------------------------------------

#[test]
fn dimension_string_unknown_is_colon() -> Result<()> {
    let dim = Arc::new(DAE::Dimension::DIM_UNKNOWN);
    assert_eq!(ExpressionBasics::dimensionString(dim)?, ":");
    Ok(())
}

#[test]
fn dimension_string_integer() -> Result<()> {
    let dim = Arc::new(DAE::Dimension::DIM_INTEGER { integer: 5 });
    assert_eq!(ExpressionBasics::dimensionString(dim)?, "5");
    Ok(())
}

#[test]
fn dimension_string_boolean() -> Result<()> {
    let dim = Arc::new(DAE::Dimension::DIM_BOOLEAN);
    assert_eq!(ExpressionBasics::dimensionString(dim)?, "Boolean");
    Ok(())
}

// ---------------------------------------------------------------------------
// priority
// ---------------------------------------------------------------------------

#[test]
fn priority_iconst_is_zero() -> Result<()> {
    assert_eq!(ExpressionBasics::priority(iconst(5), true)?, 0);
    assert_eq!(ExpressionBasics::priority(iconst(5), false)?, 0);
    Ok(())
}

#[test]
fn priority_rconst_positive_is_zero() -> Result<()> {
    // positive real — not caught by the negative-real guard, so priority is 0
    assert_eq!(ExpressionBasics::priority(rconst(1.0), true)?, 0);
    Ok(())
}

#[test]
fn priority_rconst_negative_is_four() -> Result<()> {
    // negative real has same priority as unary minus
    assert_eq!(ExpressionBasics::priority(rconst(-1.0), true)?, 4);
    Ok(())
}

#[test]
fn priority_binary_add_lhs() -> Result<()> {
    let e = make_binary(iconst(1), add_op(), iconst(2));
    assert_eq!(ExpressionBasics::priority(e, true)?, 5);
    Ok(())
}

#[test]
fn priority_binary_add_rhs() -> Result<()> {
    let e = make_binary(iconst(1), add_op(), iconst(2));
    assert_eq!(ExpressionBasics::priority(e, false)?, 6);
    Ok(())
}

#[test]
fn priority_unary_is_four() -> Result<()> {
    let uminus = DAE::Operator::UMINUS { ty: DAE::T_REAL_DEFAULT().clone() };
    let e = make_unary(uminus, iconst(1));
    assert_eq!(ExpressionBasics::priority(e, true)?, 4);
    Ok(())
}

// ---------------------------------------------------------------------------
// subscriptInt / subscriptsInt
// ---------------------------------------------------------------------------

#[test]
fn subscript_int_from_index() -> Result<()> {
    let sub = index_sub(iconst(3));
    assert_eq!(ExpressionBasics::subscriptInt(sub)?, 3);
    Ok(())
}

#[test]
fn subscripts_int_list() -> Result<()> {
    let subs: Arc<metamodelica::List<Arc<DAE::Subscript>>> =
        list![index_sub(iconst(2)), index_sub(iconst(7))];
    let result = ExpressionBasics::subscriptsInt(subs)?;
    let v: Vec<i32> = result.into_iter().cloned().collect();
    assert_eq!(v, vec![2, 7]);
    Ok(())
}

// ---------------------------------------------------------------------------
// subscriptEqual
// ---------------------------------------------------------------------------

#[test]
fn subscript_equal_empty_lists() -> Result<()> {
    assert_eq!(ExpressionBasics::subscriptEqual(metamodelica::nil(), metamodelica::nil())?, true);
    Ok(())
}

#[test]
fn subscript_equal_wholedim_wholedim() -> Result<()> {
    let s = list![wholedim()];
    assert_eq!(ExpressionBasics::subscriptEqual(s.clone(), s.clone())?, true);
    Ok(())
}

#[test]
fn subscript_equal_same_index() -> Result<()> {
    let s = list![index_sub(iconst(1))];
    assert_eq!(ExpressionBasics::subscriptEqual(s.clone(), s.clone())?, true);
    Ok(())
}

#[test]
fn subscript_equal_different_index() -> Result<()> {
    let s1 = list![index_sub(iconst(1))];
    let s2 = list![index_sub(iconst(2))];
    assert_eq!(ExpressionBasics::subscriptEqual(s1, s2)?, false);
    Ok(())
}

#[test]
fn subscript_equal_mixed_kinds() -> Result<()> {
    let s1 = list![wholedim()];
    let s2 = list![index_sub(iconst(1))];
    assert_eq!(ExpressionBasics::subscriptEqual(s1, s2)?, false);
    Ok(())
}

// ---------------------------------------------------------------------------
// printSubscriptStr  (needs flags)
// ---------------------------------------------------------------------------

#[test]
fn print_subscript_str_wholedim() -> Result<()> {
    init_flags();
    assert_eq!(ExpressionBasics::printSubscriptStr(wholedim())?, ":");
    Ok(())
}

#[test]
fn print_subscript_str_index_iconst() -> Result<()> {
    init_flags();
    let sub = index_sub(iconst(3));
    assert_eq!(ExpressionBasics::printSubscriptStr(sub)?, "3");
    Ok(())
}

// ---------------------------------------------------------------------------
// printListStr
// ---------------------------------------------------------------------------

#[test]
fn print_list_str_empty() -> Result<()> {
    let result = ExpressionBasics::printListStr::<Arc<DAE::Subscript>>(
        metamodelica::nil(),
        Arc::new(|s| ExpressionBasics::printSubscriptStr(s)),
        literal!(","),
    )?;
    assert_eq!(result, "");
    Ok(())
}

#[test]
fn print_list_str_multiple() -> Result<()> {
    init_flags();
    let subs: Arc<metamodelica::List<Arc<DAE::Subscript>>> =
        list![index_sub(iconst(3)), index_sub(iconst(5))];
    let result = ExpressionBasics::printListStr(
        subs,
        Arc::new(|s| ExpressionBasics::printSubscriptStr(s)),
        literal!(","),
    )?;
    assert_eq!(result, "3,5");
    Ok(())
}
