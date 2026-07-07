// Tests for crate::AbsynUtil::pathString
//
// The Rust source is auto-generated from:
//   ~/OpenModelica/OMCompiler/Compiler/FrontEnd/AbsynUtil.mo
//
// pathString builds the string with a System.StringAllocator filled at
// computed offsets, so these tests exercise both the allocator port and the
// offset arithmetic of pathStringWork — in particular reverse=true, which is
// used by Inst.generatePrefixStr to print a reversed-stored prefix in source
// order (and whose delimiter offsets were wrong in the MetaModelica source
// until they were fixed together with the Rust allocator port).

use std::sync::Arc;

use anyhow::Result;
use arcstr::literal;
use openmodelica_ast::Absyn;
use crate::AbsynUtil;

fn ident(name: &str) -> Arc<Absyn::Path> {
    Arc::new(Absyn::Path::IDENT { name: arcstr::ArcStr::from(name) })
}

fn qualified(name: &str, path: Arc<Absyn::Path>) -> Arc<Absyn::Path> {
    Arc::new(Absyn::Path::QUALIFIED { name: arcstr::ArcStr::from(name), path })
}

fn fully_qualified(path: Arc<Absyn::Path>) -> Arc<Absyn::Path> {
    Arc::new(Absyn::Path::FULLYQUALIFIED { path })
}

/// a.b.c
fn abc() -> Arc<Absyn::Path> {
    qualified("a", qualified("b", ident("c")))
}

#[test]
fn test_path_string_ident() -> Result<()> {
    assert_eq!(AbsynUtil::pathString(ident("x"), literal!("."), true, false)?, literal!("x"));
    Ok(())
}

#[test]
fn test_path_string_forward() -> Result<()> {
    assert_eq!(AbsynUtil::pathString(abc(), literal!("."), true, false)?, literal!("a.b.c"));
    Ok(())
}

#[test]
fn test_path_string_forward_long_delimiter() -> Result<()> {
    assert_eq!(AbsynUtil::pathString(abc(), literal!("::"), true, false)?, literal!("a::b::c"));
    Ok(())
}

#[test]
fn test_path_string_reverse() -> Result<()> {
    assert_eq!(AbsynUtil::pathString(abc(), literal!("."), true, true)?, literal!("c.b.a"));
    Ok(())
}

#[test]
fn test_path_string_reverse_mixed_lengths() -> Result<()> {
    // Inst.generatePrefixStr pattern: a prefix stored innermost-first is
    // printed in source order with "$" between the segments.
    let stored = qualified("inner", qualified("mid", ident("out")));
    assert_eq!(
        AbsynUtil::pathString(stored, literal!("$"), true, true)?,
        literal!("out$mid$inner")
    );
    Ok(())
}

#[test]
fn test_path_string_fully_qualified() -> Result<()> {
    assert_eq!(
        AbsynUtil::pathString(fully_qualified(abc()), literal!("."), true, false)?,
        literal!(".a.b.c")
    );
    // usefq=false strips the leading qualification.
    assert_eq!(
        AbsynUtil::pathString(fully_qualified(abc()), literal!("."), false, false)?,
        literal!("a.b.c")
    );
    Ok(())
}
