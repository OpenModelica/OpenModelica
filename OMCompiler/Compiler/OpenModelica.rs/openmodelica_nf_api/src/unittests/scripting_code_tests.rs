//! $Code arguments of OpenModelica.Scripting calls, which only a script quotes.
//! The NF script loop does not exist yet, so no .mos test can reach this.

use crate::NFInstanceAPI;
use metamodelica::*;
use openmodelica_ast::{Absyn, GlobalScript};
use openmodelica_frontend_dump::{BackendInterface, Dump};
use openmodelica_loader::Parser;
use openmodelica_nf_frontend::{NFExpression, NFInst, NFInstContext, NFTyping};
use openmodelica_util::{Error, Settings};

fn set_installation_directory() {
    static DIR: std::sync::OnceLock<String> = std::sync::OnceLock::new();
    let dir = DIR.get_or_init(write_builtins);
    Settings::setInstallationDirectoryPath(arcstr::format!("{}", dir));
}

fn write_builtins() -> String {
    let dir = std::env::temp_dir().join(format!("nf_api_scripting_code_{}", std::process::id()));
    let omc = dir.join("lib").join("omc");
    std::fs::create_dir_all(&omc).unwrap();
    for (name, src) in [
        (
            "ModelicaBuiltin.mo",
            include_str!("../../../../FrontEnd/ModelicaBuiltin.mo"),
        ),
        (
            "MetaModelicaBuiltin.mo",
            include_str!("../../../../FrontEnd/MetaModelicaBuiltin.mo"),
        ),
        (
            "NFModelicaBuiltin.mo",
            include_str!("../../../../NFFrontEnd/NFModelicaBuiltin.mo"),
        ),
        (
            "AnnotationsBuiltin_3_x.mo",
            include_str!("../../../../FrontEnd/AnnotationsBuiltin_3_x.mo"),
        ),
    ] {
        std::fs::write(omc.join(name), src).unwrap();
    }
    dir.display().to_string()
}

fn inst(call: &str, context: i32) -> Result<String, String> {
    set_installation_directory();
    BackendInterface::initializeWithoutBackend();
    let stmts = Parser::parsestringexp(arcstr::format!("{}", call), arcstr::literal!("<test>")).unwrap();
    let (exp, info) = match stmts.interactiveStmtLst.head().unwrap() {
        GlobalScript::Statement::IEXP { exp, info } => (exp.clone(), info.clone()),
        _ => panic!("{call} is not an expression"),
    };
    let result = (|| -> metamodelica::Result<String> {
        let (_, top) = NFInstanceAPI::mkTop(Absyn::Program::default(), None, &arcstr::literal!("test"))?;
        let exp = NFInst::instExp(exp, &top, context, &info)?;
        let (exp, _, _, _) = NFTyping::typeExp(exp, context, &info, false)?;
        Ok(Dump::printExpStr(NFExpression::toAbsyn(exp)?)?.to_string())
    })();
    result.map_err(|_| Error::printMessagesStr(false).to_string())
}

#[test]
fn code_arguments_are_quoted_in_a_script() {
    let s = NFInstContext::SCRIPTING;
    let ok = |call: &str| inst(call, s).unwrap();
    assert_eq!(
        ok("OpenModelica.Scripting.typeNameString(Modelica.Blocks)"),
        "typeNameString($Code(Modelica.Blocks))"
    );
    assert_eq!(
        ok("OpenModelica.Scripting.getVersion()"),
        "getVersion($Code(OpenModelica))"
    );
    assert_eq!(
        ok("OpenModelica.Scripting.val(der(y), 1.0)"),
        "val($Code(der(y)), 1, \"<default>\")"
    );
    assert_eq!(
        ok("OpenModelica.Scripting.setComponentModifierValue(A, b.c, $Code(=1))"),
        "setElementModifierValue($Code(A), $Code(b.c), $Code( = 1))"
    );
    assert!(ok("OpenModelica.Scripting.plot({a, der(b)})").starts_with("plot($Code({a, der(b)}), false, "));
    assert!(ok("OpenModelica.Scripting.plot(z)").starts_with("plot($Code({z}), false, "));
}

#[test]
fn code_arguments_are_not_quoted_outside_a_script() {
    let err = inst(
        "OpenModelica.Scripting.typeNameString(Modelica.Blocks)",
        NFInstContext::NO_CONTEXT,
    )
    .unwrap_err();
    assert!(err.contains("Modelica.Blocks not found"), "{err}");
}
