//! The NF evaluates builtin OpenModelica.Scripting calls in a script through
//! BackendInterface.evalScriptingFunction. No .mos test can set the SCRIPTING
//! context before the NF script loop exists.

use crate::BackendInterfaceImplementation;
use metamodelica::*;
use openmodelica_ast::GlobalScript;
use openmodelica_frontend_dump::Dump;
use openmodelica_loader::Parser;
use openmodelica_nf_api::NFInstanceAPI;
use openmodelica_nf_frontend::{NFCeval, NFExpression, NFInst, NFInstContext, NFTyping};
use openmodelica_util::{Config, Error, Flags, Settings};

const PROGRAM: &str = "
function f
  input String suffix;
  output String s;
algorithm
  s := OpenModelica.Scripting.typeNameString(Modelica.Blocks) + suffix;
end f;
";

fn set_installation_directory() {
    static DIR: std::sync::OnceLock<String> = std::sync::OnceLock::new();
    let dir = DIR.get_or_init(write_builtins);
    Settings::setInstallationDirectoryPath(arcstr::format!("{}", dir));
}

fn write_builtins() -> String {
    let dir = std::env::temp_dir().join(format!("backend_main_scripting_eval_{}", std::process::id()));
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

fn eval(call: &str, context: i32) -> Result<String, String> {
    set_installation_directory();
    BackendInterfaceImplementation::initializeBackendInterface();
    let result = (|| -> metamodelica::Result<String> {
        let grammar = Config::acceptedGrammar()?;
        let std = Flags::getConfigEnum(Flags::LANGUAGE_STANDARD.clone())?;
        let program = Parser::parsestring(PROGRAM.into(), "<program>".into(), grammar, std, false)?;
        let stmts = Parser::parsestringexp(arcstr::format!("{}", call), "<call>".into())?;
        let GlobalScript::Statement::IEXP { exp, info } = stmts.interactiveStmtLst.head()?.clone() else {
            panic!("{call} is not an expression");
        };
        let (_, top) = NFInstanceAPI::mkTop(program, None, &"test".into())?;
        let exp = NFInst::instExp(exp, &top, context, &info)?;
        let (exp, _, _, _) = NFTyping::typeExp(exp, context, &info, false)?;
        let exp = NFCeval::evalExp(exp, &NFCeval::EvalTarget::new(info, context, None))?;
        Ok(Dump::printExpStr(NFExpression::toAbsyn(exp)?)?.to_string())
    })();
    result.map_err(|_| Error::printMessagesStr(false).to_string())
}

fn eval_in_script(call: &str) -> (String, String) {
    let result = eval(call, NFInstContext::SCRIPTING).unwrap();
    (result, Error::printMessagesStr(false).to_string())
}

#[test]
fn scripting_calls_are_evaluated_in_a_script() {
    let no_messages = |call| {
        let (result, messages) = eval_in_script(call);
        assert_eq!(messages, "", "{call}");
        result
    };
    assert_eq!(
        no_messages("OpenModelica.Scripting.typeNameString(Modelica.Blocks)"),
        "\"Modelica.Blocks\""
    );
    assert_eq!(
        no_messages("OpenModelica.Scripting.stringReplace(\"abc\", \"b\", \"x\")"),
        "\"axc\""
    );
    // The first of the three outputs, as in any expression.
    assert_eq!(
        no_messages("OpenModelica.Scripting.convertUnits(\"m\", \"mm\")"),
        "true"
    );
    assert_eq!(no_messages("f(\"!\")"), "\"Modelica.Blocks!\"");
    assert!(no_messages("OpenModelica.Scripting.getVersion()").starts_with('"'));

    let (result, messages) = eval_in_script("OpenModelica.Scripting.loadFile(\"/nonexistent/a.mo\")");
    assert_eq!(result, "false");
    assert!(messages.contains("Failed to load file /nonexistent/a.mo"), "{messages}");
}

#[test]
fn scripting_calls_are_not_evaluated_outside_a_script() {
    let err = eval(
        "OpenModelica.Scripting.stringReplace(\"abc\", \"b\", \"x\")",
        NFInstContext::NO_CONTEXT,
    )
    .unwrap_err();
    assert!(err.contains("unimplemented case for stringReplace"), "{err}");
}
