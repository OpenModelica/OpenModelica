use std::sync::Arc;
use anyhow::Result;
use metamodelica::*;
use openmodelica_ast::Absyn;
use crate::Dump;
use openmodelica_util::{FlagsUtil, Flags};

// Initialize flags with default values for the current thread.
// Required by Config-using functions (printExpStr, WILD branch, etc.).
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

fn ident_cref(name: &str) -> Arc<Absyn::ComponentRef> {
    Arc::new(Absyn::ComponentRef::CREF_IDENT {
        name: arcstr::format!("{}", name),
        subscripts: metamodelica::nil(),
    })
}

fn qual_cref(name: &str, rest: Arc<Absyn::ComponentRef>) -> Arc<Absyn::ComponentRef> {
    Arc::new(Absyn::ComponentRef::CREF_QUAL {
        name: arcstr::format!("{}", name),
        subscripts: metamodelica::nil(),
        componentRef: rest,
    })
}

fn fully_qualified_cref(cr: Arc<Absyn::ComponentRef>) -> Arc<Absyn::ComponentRef> {
    Arc::new(Absyn::ComponentRef::CREF_FULLYQUALIFIED { componentRef: cr })
}

fn integer_exp(v: i32) -> Arc<Absyn::Exp> {
    Arc::new(Absyn::Exp::INTEGER { value: v })
}

fn binary_exp(e1: Arc<Absyn::Exp>, op: Absyn::Operator, e2: Arc<Absyn::Exp>) -> Arc<Absyn::Exp> {
    Arc::new(Absyn::Exp::BINARY { exp1: e1, op, exp2: e2 })
}

fn unary_exp(op: Absyn::Operator, e: Arc<Absyn::Exp>) -> Arc<Absyn::Exp> {
    Arc::new(Absyn::Exp::UNARY { op, exp: e })
}

// ---------------------------------------------------------------------------
// opSymbol — no flags needed
// ---------------------------------------------------------------------------

#[test]
fn op_symbol_add() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::ADD)?, " + ");
    Ok(())
}

#[test]
fn op_symbol_sub() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::SUB)?, " - ");
    Ok(())
}

#[test]
fn op_symbol_mul() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::MUL)?, " * ");
    Ok(())
}

#[test]
fn op_symbol_div() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::DIV)?, " / ");
    Ok(())
}

#[test]
fn op_symbol_pow() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::POW)?, " ^ ");
    Ok(())
}

#[test]
fn op_symbol_and() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::AND)?, " and ");
    Ok(())
}

#[test]
fn op_symbol_or() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::OR)?, " or ");
    Ok(())
}

#[test]
fn op_symbol_less() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::LESS)?, " < ");
    Ok(())
}

#[test]
fn op_symbol_lesseq() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::LESSEQ)?, " <= ");
    Ok(())
}

#[test]
fn op_symbol_greater() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::GREATER)?, " > ");
    Ok(())
}

#[test]
fn op_symbol_equal() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::EQUAL)?, " == ");
    Ok(())
}

#[test]
fn op_symbol_nequal() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::NEQUAL)?, " <> ");
    Ok(())
}

#[test]
fn op_symbol_not() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::NOT)?, "not ");
    Ok(())
}

#[test]
fn op_symbol_uminus() -> Result<()> {
    assert_eq!(Dump::opSymbol(Absyn::Operator::UMINUS)?, "-");
    Ok(())
}

// ---------------------------------------------------------------------------
// opSymbolCompact — no flags needed
// ---------------------------------------------------------------------------

#[test]
fn op_symbol_compact_add() -> Result<()> {
    assert_eq!(Dump::opSymbolCompact(Absyn::Operator::ADD)?, "+");
    Ok(())
}

#[test]
fn op_symbol_compact_sub() -> Result<()> {
    assert_eq!(Dump::opSymbolCompact(Absyn::Operator::SUB)?, "-");
    Ok(())
}

#[test]
fn op_symbol_compact_not() -> Result<()> {
    assert_eq!(Dump::opSymbolCompact(Absyn::Operator::NOT)?, "not");
    Ok(())
}

#[test]
fn op_symbol_compact_and() -> Result<()> {
    assert_eq!(Dump::opSymbolCompact(Absyn::Operator::AND)?, "and");
    Ok(())
}

#[test]
fn op_symbol_compact_or() -> Result<()> {
    assert_eq!(Dump::opSymbolCompact(Absyn::Operator::OR)?, "or");
    Ok(())
}

// ---------------------------------------------------------------------------
// directionSymbol — no flags needed
// ---------------------------------------------------------------------------

#[test]
fn direction_symbol_bidir_is_empty() -> Result<()> {
    assert_eq!(Dump::directionSymbol(Absyn::Direction::BIDIR)?, "");
    Ok(())
}

#[test]
fn direction_symbol_input() -> Result<()> {
    assert_eq!(Dump::directionSymbol(Absyn::Direction::INPUT)?, "input");
    Ok(())
}

#[test]
fn direction_symbol_output() -> Result<()> {
    assert_eq!(Dump::directionSymbol(Absyn::Direction::OUTPUT)?, "output");
    Ok(())
}

// ---------------------------------------------------------------------------
// expPriority — no flags needed (pure structural match)
// ---------------------------------------------------------------------------

#[test]
fn exp_priority_integer_is_zero() -> Result<()> {
    assert_eq!(Dump::expPriority(integer_exp(5), true)?, 0);
    assert_eq!(Dump::expPriority(integer_exp(5), false)?, 0);
    Ok(())
}

#[test]
fn exp_priority_binary_add_lhs() -> Result<()> {
    let e = binary_exp(integer_exp(1), Absyn::Operator::ADD, integer_exp(2));
    assert_eq!(Dump::expPriority(e, true)?, 5);
    Ok(())
}

#[test]
fn exp_priority_binary_add_rhs() -> Result<()> {
    let e = binary_exp(integer_exp(1), Absyn::Operator::ADD, integer_exp(2));
    assert_eq!(Dump::expPriority(e, false)?, 6);
    Ok(())
}

#[test]
fn exp_priority_binary_sub_lhs() -> Result<()> {
    let e = binary_exp(integer_exp(1), Absyn::Operator::SUB, integer_exp(2));
    assert_eq!(Dump::expPriority(e, true)?, 5);
    Ok(())
}

#[test]
fn exp_priority_binary_sub_rhs() -> Result<()> {
    let e = binary_exp(integer_exp(1), Absyn::Operator::SUB, integer_exp(2));
    assert_eq!(Dump::expPriority(e, false)?, 5);
    Ok(())
}

#[test]
fn exp_priority_binary_mul_lhs() -> Result<()> {
    let e = binary_exp(integer_exp(1), Absyn::Operator::MUL, integer_exp(2));
    assert_eq!(Dump::expPriority(e, true)?, 2);
    Ok(())
}

#[test]
fn exp_priority_binary_pow_lhs() -> Result<()> {
    let e = binary_exp(integer_exp(2), Absyn::Operator::POW, integer_exp(3));
    assert_eq!(Dump::expPriority(e, true)?, 1);
    Ok(())
}

#[test]
fn exp_priority_unary_is_four() -> Result<()> {
    let e = unary_exp(Absyn::Operator::UMINUS, integer_exp(1));
    assert_eq!(Dump::expPriority(e, true)?, 4);
    Ok(())
}

// ---------------------------------------------------------------------------
// printComponentRefStr (Absyn) — CREF_IDENT with no subs needs no flags
// ---------------------------------------------------------------------------

#[test]
fn print_component_ref_str_plain_ident() -> Result<()> {
    // CREF_IDENT("x", []) — no Config call, no flags needed
    assert_eq!(Dump::printComponentRefStr(ident_cref("x"))?, "x");
    Ok(())
}

#[test]
fn print_component_ref_str_qual_no_subs() -> Result<()> {
    // CREF_QUAL delegates to printSubscriptsStr([], …) which returns "" immediately,
    // then recurses on the inner CREF_IDENT. No Config call needed.
    let q = qual_cref("a", ident_cref("b"));
    assert_eq!(Dump::printComponentRefStr(q)?, "a.b");
    Ok(())
}

#[test]
fn print_component_ref_str_fully_qualified() -> Result<()> {
    let fq = fully_qualified_cref(ident_cref("x"));
    assert_eq!(Dump::printComponentRefStr(fq)?, ".x");
    Ok(())
}

#[test]
fn print_component_ref_str_allwild() -> Result<()> {
    let aw = Arc::new(Absyn::ComponentRef::ALLWILD);
    assert_eq!(Dump::printComponentRefStr(aw)?, "__");
    Ok(())
}

/// WILD branches on Config::acceptMetaModelicaGrammar() — needs flags.
/// With default flags (grammar = Modelica), the result should be "".
#[test]
fn print_component_ref_str_wild_with_default_flags() -> Result<()> {
    init_flags();
    let wild = Arc::new(Absyn::ComponentRef::WILD);
    assert_eq!(Dump::printComponentRefStr(wild)?, "");
    Ok(())
}
