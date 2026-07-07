use std::sync::Arc;
use anyhow::Result;
use arcstr::literal;
use metamodelica::*;
use openmodelica_frontend_types::DAE;
use crate::ComponentReferenceBasics as CRB;
use openmodelica_util::{FlagsUtil, Flags};

// Initialize flags with default values for the current thread.
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

fn make_ident(name: &str) -> Arc<DAE::ComponentRef> {
    CRB::makeCrefIdent(
        arcstr::format!("{}", name),
        DAE::T_REAL_DEFAULT().clone(),
        metamodelica::nil(),
    )
}

fn make_ident_with_subs(
    name: &str,
    subs: Arc<metamodelica::List<Arc<DAE::Subscript>>>,
) -> Arc<DAE::ComponentRef> {
    CRB::makeCrefIdent(arcstr::format!("{}", name), DAE::T_REAL_DEFAULT().clone(), subs)
}

fn make_qual(name: &str, rest: Arc<DAE::ComponentRef>) -> Arc<DAE::ComponentRef> {
    CRB::makeCrefQual(
        arcstr::format!("{}", name),
        DAE::T_REAL_DEFAULT().clone(),
        metamodelica::nil(),
        rest,
    )
}

fn index_sub(i: i32) -> Arc<DAE::Subscript> {
    Arc::new(DAE::Subscript::INDEX {
        exp: Arc::new(DAE::Exp::ICONST { integer: i }),
    })
}

// ---------------------------------------------------------------------------
// crefEqual
// ---------------------------------------------------------------------------

#[test]
fn cref_equal_same_ident() -> Result<()> {
    assert_eq!(CRB::crefEqual(make_ident("x"), make_ident("x"))?, true);
    Ok(())
}

#[test]
fn cref_equal_different_ident() -> Result<()> {
    assert_eq!(CRB::crefEqual(make_ident("x"), make_ident("y"))?, false);
    Ok(())
}

#[test]
fn cref_equal_ident_vs_qual() -> Result<()> {
    assert_eq!(
        CRB::crefEqual(make_ident("a"), make_qual("a", make_ident("b")))?,
        false
    );
    Ok(())
}

#[test]
fn cref_equal_same_qual() -> Result<()> {
    let q1 = make_qual("a", make_ident("b"));
    let q2 = make_qual("a", make_ident("b"));
    assert_eq!(CRB::crefEqual(q1, q2)?, true);
    Ok(())
}

#[test]
fn cref_equal_diff_qual_last_component() -> Result<()> {
    let q1 = make_qual("a", make_ident("b"));
    let q2 = make_qual("a", make_ident("c"));
    assert_eq!(CRB::crefEqual(q1, q2)?, false);
    Ok(())
}

// ---------------------------------------------------------------------------
// crefFirstIdent / crefLastIdent
// ---------------------------------------------------------------------------

#[test]
fn cref_first_ident_of_ident() -> Result<()> {
    assert_eq!(CRB::crefFirstIdent(make_ident("x"))?, "x");
    Ok(())
}

#[test]
fn cref_first_ident_of_qual() -> Result<()> {
    assert_eq!(CRB::crefFirstIdent(make_qual("a", make_ident("b")))?, "a");
    Ok(())
}

#[test]
fn cref_last_ident_of_ident() -> Result<()> {
    assert_eq!(CRB::crefLastIdent(make_ident("x"))?, "x");
    Ok(())
}

#[test]
fn cref_last_ident_of_qual() -> Result<()> {
    assert_eq!(CRB::crefLastIdent(make_qual("a", make_ident("b")))?, "b");
    Ok(())
}

#[test]
fn cref_last_ident_of_deep_qual() -> Result<()> {
    let deep = make_qual("a", make_qual("b", make_ident("c")));
    assert_eq!(CRB::crefLastIdent(deep)?, "c");
    Ok(())
}

// ---------------------------------------------------------------------------
// crefFirstCref / crefLastCref
// ---------------------------------------------------------------------------

#[test]
fn cref_first_cref_of_ident_is_that_ident() -> Result<()> {
    let cr = make_ident("x");
    let first = CRB::crefFirstCref(cr.clone())?;
    assert_eq!(CRB::crefFirstIdent(first)?, "x");
    Ok(())
}

#[test]
fn cref_first_cref_of_qual_is_ident() -> Result<()> {
    // crefFirstCref("a.b") should return CREF_IDENT("a"), not CREF_QUAL
    let q = make_qual("a", make_ident("b"));
    let first = CRB::crefFirstCref(q)?;
    assert_eq!(CRB::crefFirstIdent(first)?, "a");
    Ok(())
}

#[test]
fn cref_last_cref_of_ident() -> Result<()> {
    let cr = make_ident("x");
    let last = CRB::crefLastCref(cr)?;
    assert_eq!(CRB::crefFirstIdent(last)?, "x");
    Ok(())
}

#[test]
fn cref_last_cref_of_qual() -> Result<()> {
    let q = make_qual("a", make_ident("b"));
    let last = CRB::crefLastCref(q)?;
    assert_eq!(CRB::crefFirstIdent(last)?, "b");
    Ok(())
}

// ---------------------------------------------------------------------------
// crefLastIdentEqual
// ---------------------------------------------------------------------------

#[test]
fn cref_last_ident_equal_same_ident() -> Result<()> {
    assert_eq!(CRB::crefLastIdentEqual(make_ident("x"), make_ident("x"))?, true);
    Ok(())
}

#[test]
fn cref_last_ident_equal_different_prefix_same_last() -> Result<()> {
    let cr1 = make_qual("a", make_ident("b"));
    let cr2 = make_qual("c", make_ident("b"));
    assert_eq!(CRB::crefLastIdentEqual(cr1, cr2)?, true);
    Ok(())
}

#[test]
fn cref_last_ident_equal_different_last() -> Result<()> {
    let cr1 = make_qual("a", make_ident("b"));
    let cr2 = make_qual("a", make_ident("c"));
    assert_eq!(CRB::crefLastIdentEqual(cr1, cr2)?, false);
    Ok(())
}

// ---------------------------------------------------------------------------
// crefFirstIdentEqual
// ---------------------------------------------------------------------------

#[test]
fn cref_first_ident_equal_same() -> Result<()> {
    assert_eq!(CRB::crefFirstIdentEqual(make_ident("x"), make_ident("x"))?, true);
    Ok(())
}

#[test]
fn cref_first_ident_equal_qual_vs_ident_same_first() -> Result<()> {
    let q = make_qual("x", make_ident("y"));
    assert_eq!(CRB::crefFirstIdentEqual(q, make_ident("x"))?, true);
    Ok(())
}

#[test]
fn cref_first_ident_equal_different() -> Result<()> {
    assert_eq!(CRB::crefFirstIdentEqual(make_ident("a"), make_ident("b"))?, false);
    Ok(())
}

// ---------------------------------------------------------------------------
// crefPrefixOf / crefNotPrefixOf
// ---------------------------------------------------------------------------

#[test]
fn cref_prefix_of_same_ident() -> Result<()> {
    assert_eq!(CRB::crefPrefixOf(make_ident("a"), make_ident("a"))?, true);
    Ok(())
}

#[test]
fn cref_prefix_of_ident_is_prefix_of_qual() -> Result<()> {
    let full = make_qual("a", make_ident("b"));
    assert_eq!(CRB::crefPrefixOf(make_ident("a"), full)?, true);
    Ok(())
}

#[test]
fn cref_prefix_of_wrong_ident() -> Result<()> {
    let full = make_qual("a", make_ident("b"));
    assert_eq!(CRB::crefPrefixOf(make_ident("b"), full)?, false);
    Ok(())
}

#[test]
fn cref_prefix_of_qual_prefix_of_deeper_qual() -> Result<()> {
    let prefix = make_qual("a", make_ident("b"));
    let full = make_qual("a", make_qual("b", make_ident("c")));
    assert_eq!(CRB::crefPrefixOf(prefix, full)?, true);
    Ok(())
}

#[test]
fn cref_not_prefix_of_qual_vs_ident() -> Result<()> {
    // make_qual("a","b") is NOT a prefix of make_ident("a")
    let q = make_qual("a", make_ident("b"));
    assert_eq!(CRB::crefNotPrefixOf(q, make_ident("a"))?, true);
    Ok(())
}

#[test]
fn cref_not_prefix_of_same_ident_is_false() -> Result<()> {
    assert_eq!(CRB::crefNotPrefixOf(make_ident("a"), make_ident("a"))?, false);
    Ok(())
}

// ---------------------------------------------------------------------------
// crefSubs
// ---------------------------------------------------------------------------

#[test]
fn cref_subs_ident_no_subs() -> Result<()> {
    let subs = CRB::crefSubs(make_ident("x"))?;
    assert!(subs.is_empty(), "expected empty subs for plain ident");
    Ok(())
}

#[test]
fn cref_subs_ident_with_subs() -> Result<()> {
    let sub = index_sub(3);
    let cr = make_ident_with_subs("x", list![sub.clone()]);
    let subs = CRB::crefSubs(cr)?;
    let v: Vec<Arc<DAE::Subscript>> = subs.into_iter().cloned().collect();
    assert_eq!(v.len(), 1);
    assert_eq!(v[0], sub);
    Ok(())
}

// ---------------------------------------------------------------------------
// printComponentRefStr  (CREF_IDENT with no subs: no flags needed)
// ---------------------------------------------------------------------------

#[test]
fn print_component_ref_str_plain_ident() -> Result<()> {
    // CREF_IDENT with empty subscript list — no Config call, no flags needed.
    assert_eq!(CRB::printComponentRefStr(make_ident("x"))?, "x");
    Ok(())
}

#[test]
fn print_component_ref_str_qual_needs_flags() -> Result<()> {
    init_flags();
    // CREF_QUAL calls Config::modelicaOutput() which requires flags initialized.
    let q = make_qual("a", make_ident("b"));
    assert_eq!(CRB::printComponentRefStr(q)?, "a.b");
    Ok(())
}

#[test]
fn print_component_ref_str_deep_qual_needs_flags() -> Result<()> {
    init_flags();
    let deep = make_qual("a", make_qual("b", make_ident("c")));
    assert_eq!(CRB::printComponentRefStr(deep)?, "a.b.c");
    Ok(())
}
