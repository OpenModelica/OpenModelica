// Tests for crate::Dump::unparseStr
//
// The Rust source is auto-generated from:
//   ~/OpenModelica/OMCompiler/Compiler/ModelicaBuiltin.mo (and AbsynDumpTpl.tpl)
//
// unparseStr round-trips a parsed Absyn::Program back to Modelica source text.
// Tests here parse a small model string, call unparseStr, and assert properties
// on the output string.
//
// Known bugs detected while writing these tests are documented inline with
// "Bug:" prefixes.

use anyhow::Result;
use std::sync::Arc;
use metamodelica::*;
use openmodelica_ast::parser::{parse, Grammar};
use crate::Dump;
use openmodelica_util::{FlagsUtil, Flags};

// ---------------------------------------------------------------------------
// Flags initialisation — required because unparseStr calls
// Flags::getConfigBool / FlagsUtil::setConfigBool internally.
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

/// Parse `src` with the MetaModelica grammar and return the Absyn::Program.
fn parse_prog(src: &str) -> openmodelica_ast::Absyn::Program {
    parse(src, "test.mo", "test.mo", Grammar::MetaModelica, false, 0.0)
        .unwrap_or_else(|e| panic!("parse failed: {}", e))
}

/// Parse `src` and call unparseStr with default options (no markup).
fn unparse(src: &str) -> Result<arcstr::ArcStr> {
    init_flags();
    let prog = parse_prog(src);
    Dump::unparseStr(prog, false, Dump::defaultDumpOptions.clone())
}

// ---------------------------------------------------------------------------
// smoke test — empty program (no classes)
// ---------------------------------------------------------------------------

/// An empty stored_definition (just `within;`) has no classes;
/// unparseStr should return an empty string.
#[test]
fn unparse_str_empty_program_returns_empty() -> Result<()> {
    init_flags();
    let prog = openmodelica_ast::Absyn::Program {
        classes: metamodelica::nil(),
        within_: openmodelica_ast::Absyn::Within::TOP,
    };
    let out = Dump::unparseStr(prog, false, Dump::defaultDumpOptions.clone())?;
    assert_eq!(out, "", "empty program should produce empty string, got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// simple empty model
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_empty_model_contains_keyword_and_name() -> Result<()> {
    let out = unparse("model Empty end Empty;")?;
    assert!(out.contains("model"), "expected 'model' keyword, got: {:?}", out);
    assert!(out.contains("Empty"), "expected class name 'Empty', got: {:?}", out);
    assert!(out.contains("end"), "expected 'end' keyword, got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_empty_model_ends_with_semicolon() -> Result<()> {
    let out = unparse("model Empty end Empty;")?;
    // The model declaration should be terminated by a semicolon.
    assert!(
        out.trim_end().ends_with(';'),
        "expected output to end with ';', got: {:?}", out
    );
    Ok(())
}

// ---------------------------------------------------------------------------
// package with a nested model
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_package_preserves_name() -> Result<()> {
    let src = "package MyPkg end MyPkg;";
    let out = unparse(src)?;
    assert!(out.contains("package"), "expected 'package' keyword, got: {:?}", out);
    assert!(out.contains("MyPkg"), "expected 'MyPkg', got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_nested_class_names_present() -> Result<()> {
    let src = "package Outer model Inner end Inner; end Outer;";
    let out = unparse(src)?;
    assert!(out.contains("Outer"), "expected 'Outer', got: {:?}", out);
    assert!(out.contains("Inner"), "expected 'Inner', got: {:?}", out);
    assert!(out.contains("model"), "expected 'model' keyword, got: {:?}", out);
    assert!(out.contains("package"), "expected 'package' keyword, got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// connector
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_connector_keyword_preserved() -> Result<()> {
    let src = "connector Pin Real v; flow Real i; end Pin;";
    let out = unparse(src)?;
    assert!(out.contains("connector"), "expected 'connector' keyword, got: {:?}", out);
    assert!(out.contains("Pin"), "expected 'Pin', got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// function
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_function_keyword_preserved() -> Result<()> {
    let src = "function add input Real a; input Real b; output Real c; algorithm c := a + b; end add;";
    let out = unparse(src)?;
    assert!(out.contains("function"), "expected 'function' keyword, got: {:?}", out);
    assert!(out.contains("add"), "expected function name 'add', got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// within clause — Bug suspected: verify that the within path is emitted
// ---------------------------------------------------------------------------

/// The within clause (non-TOP) should appear in the output as "within <path>;".
/// Bug: if the template does not emit the within clause, this test will fail.
#[test]
fn unparse_str_within_clause_present() -> Result<()> {
    init_flags();
    // Build a program with a within clause manually, since the parser in
    // MetaModelica grammar may not support top-level `within` directives
    // for all model variants.  We construct the AST directly.
    use openmodelica_ast::Absyn;
    let dummy_info = metamodelica::SourceInfo {
        fileName: arcstr::literal!("test.mo"),
        isReadOnly: false,
        lineNumberStart: 1,
        columnNumberStart: 1,
        lineNumberEnd: 1,
        columnNumberEnd: 1,
        lastModification: metamodelica::OrderedFloat(0.0),
    };
    let within_path = Arc::new(Absyn::Path::IDENT { name: arcstr::literal!("Foo") });
    let prog = Absyn::Program {
        classes: metamodelica::list![Arc::new(Absyn::Class {
            name: arcstr::literal!("Bar"),
            partialPrefix: false,
            finalPrefix: false,
            encapsulatedPrefix: false,
            restriction: Absyn::Restriction::R_MODEL,
            body: Arc::new(Absyn::ClassDef::PARTS {
                typeVars: metamodelica::nil(),
                classAttrs: metamodelica::nil(),
                classParts: metamodelica::nil(),
                ann: metamodelica::nil(),
                comment: None,
            }),
            commentsBeforeClass: metamodelica::nil(),
            commentsBeforeEnd: metamodelica::nil(),
            commentsAfterEnd: metamodelica::nil(),
            info: dummy_info,
        })],
        within_: Absyn::Within::WITHIN { path: within_path },
    };
    let out = Dump::unparseStr(prog, false, Dump::defaultDumpOptions.clone())?;
    assert!(
        out.contains("within"),
        "expected 'within' keyword in output, got: {:?}", out
    );
    assert!(
        out.contains("Foo"),
        "expected within path 'Foo' in output, got: {:?}", out
    );
    Ok(())
}

// ---------------------------------------------------------------------------
// idempotency: unparse(parse(unparse(parse(s)))) == unparse(parse(s))
// ---------------------------------------------------------------------------

/// Parsing and unparsing a simple model twice should give the same string on
/// the second pass (the template should be deterministic and idempotent).
/// Bug: if the formatter introduces or drops tokens on successive passes this
/// test will fail, surfacing a round-trip instability.
#[test]
fn unparse_str_idempotent_for_simple_model() -> Result<()> {
    let src = "model M end M;";
    let pass1 = unparse(src)?;
    let pass2 = unparse(&pass1)?;
    assert_eq!(
        pass1, pass2,
        "unparseStr should be idempotent but pass1 != pass2:\npass1={:?}\npass2={:?}",
        pass1, pass2
    );
    Ok(())
}

// ---------------------------------------------------------------------------
// components and type names
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_component_type_names_preserved() -> Result<()> {
    let src = "model M Real x; Integer n; Boolean b; end M;";
    let out = unparse(src)?;
    assert!(out.contains("Real"),    "expected type 'Real', got: {:?}", out);
    assert!(out.contains("Integer"), "expected type 'Integer', got: {:?}", out);
    assert!(out.contains("Boolean"), "expected type 'Boolean', got: {:?}", out);
    assert!(out.contains("x"),       "expected variable 'x', got: {:?}", out);
    assert!(out.contains("n"),       "expected variable 'n', got: {:?}", out);
    assert!(out.contains("b"),       "expected variable 'b', got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_parameter_modifier_preserved() -> Result<()> {
    let src = "model M parameter Real m = 1.0; parameter Integer n = 5; end M;";
    let out = unparse(src)?;
    assert!(out.contains("parameter"), "expected 'parameter' keyword, got: {:?}", out);
    assert!(out.contains("m"),         "expected variable 'm', got: {:?}", out);
    assert!(out.contains("n"),         "expected variable 'n', got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_component_with_start_attribute() -> Result<()> {
    let src = "model M Real x(start = 0.5, fixed = true); end M;";
    let out = unparse(src)?;
    assert!(out.contains("x"),    "expected variable 'x', got: {:?}", out);
    assert!(out.contains("Real"), "expected type 'Real', got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// equation section
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_equation_section_present() -> Result<()> {
    let src = "model M Real x; equation x = 1.0; end M;";
    let out = unparse(src)?;
    assert!(out.contains("equation"), "expected 'equation' keyword, got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_differential_equation_preserved() -> Result<()> {
    let src = "model M Real x(start=1.0); equation der(x) = -x; end M;";
    let out = unparse(src)?;
    assert!(out.contains("equation"), "expected 'equation' keyword, got: {:?}", out);
    assert!(out.contains("der"),      "expected 'der' call, got: {:?}", out);
    assert!(out.contains("x"),        "expected variable 'x', got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_initial_equation_present() -> Result<()> {
    let src = "model M Real x; initial equation x = 0.0; end M;";
    let out = unparse(src)?;
    assert!(out.contains("initial"),  "expected 'initial' keyword, got: {:?}", out);
    assert!(out.contains("equation"), "expected 'equation' keyword, got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_if_equation_preserved() -> Result<()> {
    let src = "model M Real x; equation if x > 0 then x = 1.0; end if; end M;";
    let out = unparse(src)?;
    assert!(out.contains("if"),  "expected 'if' keyword, got: {:?}", out);
    assert!(out.contains("end if") || out.contains("end  if"),
        "expected 'end if', got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_for_equation_preserved() -> Result<()> {
    let src = "model M Real x[5]; equation for i in 1:5 loop x[i] = 0.0; end for; end M;";
    let out = unparse(src)?;
    assert!(out.contains("for"), "expected 'for' keyword, got: {:?}", out);
    assert!(out.contains("end for") || out.contains("end  for"),
        "expected 'end for', got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_when_equation_preserved() -> Result<()> {
    let src = "model M Real x; equation when time > 1.0 then x = 1.0; end when; end M;";
    let out = unparse(src)?;
    assert!(out.contains("when"), "expected 'when' keyword, got: {:?}", out);
    assert!(out.contains("end when") || out.contains("end  when"),
        "expected 'end when', got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// algorithm section
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_algorithm_section_present() -> Result<()> {
    let src = "model M Real x; algorithm x := 1.0; end M;";
    let out = unparse(src)?;
    assert!(out.contains("algorithm"), "expected 'algorithm' keyword, got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_algorithm_assignment_preserved() -> Result<()> {
    let src = "model M Real x; algorithm x := 2.0 * x + 1.0; end M;";
    let out = unparse(src)?;
    assert!(out.contains("algorithm"), "expected 'algorithm' keyword, got: {:?}", out);
    assert!(out.contains(":="), "expected ':=' assignment operator, got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_algorithm_if_preserved() -> Result<()> {
    let src = "model M Real x; algorithm if x > 0 then x := x - 1; end if; end M;";
    let out = unparse(src)?;
    assert!(out.contains("algorithm"), "expected 'algorithm' keyword, got: {:?}", out);
    assert!(out.contains("if"),        "expected 'if' keyword, got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_initial_algorithm_present() -> Result<()> {
    let src = "model M Real x; initial algorithm x := 0.0; end M;";
    let out = unparse(src)?;
    assert!(out.contains("initial"),   "expected 'initial' keyword, got: {:?}", out);
    assert!(out.contains("algorithm"), "expected 'algorithm' keyword, got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// extends and inheritance
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_extends_clause_preserved() -> Result<()> {
    let src = "model Child extends Parent; end Child;";
    let out = unparse(src)?;
    assert!(out.contains("extends"), "expected 'extends' keyword, got: {:?}", out);
    assert!(out.contains("Parent"),  "expected base class 'Parent', got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_extends_with_modification() -> Result<()> {
    let src = "model M extends Base(x = 1.0); end M;";
    let out = unparse(src)?;
    assert!(out.contains("extends"), "expected 'extends' keyword, got: {:?}", out);
    assert!(out.contains("Base"),    "expected base class 'Base', got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// public / protected sections
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_protected_section_preserved() -> Result<()> {
    let src = "model M Real pub; protected Real priv; end M;";
    let out = unparse(src)?;
    assert!(out.contains("protected"), "expected 'protected' keyword, got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_public_section_preserved() -> Result<()> {
    let src = "model M protected Real priv; public Real pub; end M;";
    let out = unparse(src)?;
    assert!(out.contains("public"),    "expected 'public' keyword, got: {:?}", out);
    assert!(out.contains("protected"), "expected 'protected' keyword, got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// class modifiers: partial, encapsulated
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_partial_modifier_preserved() -> Result<()> {
    let src = "partial model Abstract end Abstract;";
    let out = unparse(src)?;
    assert!(out.contains("partial"), "expected 'partial' keyword, got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_encapsulated_modifier_preserved() -> Result<()> {
    let src = "encapsulated model M end M;";
    let out = unparse(src)?;
    assert!(out.contains("encapsulated"), "expected 'encapsulated' keyword, got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// annotations
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_class_annotation_preserved() -> Result<()> {
    let src = "model M annotation(Documentation(info = \"My model\")); end M;";
    let out = unparse(src)?;
    assert!(out.contains("annotation"), "expected 'annotation' keyword, got: {:?}", out);
    assert!(out.contains("Documentation"), "expected 'Documentation', got: {:?}", out);
    Ok(())
}

/// Bug: component-level annotations are silently dropped by unparseStr.
/// The output contains only "Real x;" — the annotation(...) clause is missing.
#[test]
fn unparse_str_component_annotation_preserved() -> Result<()> {
    let src = "model M Real x annotation(Dialog(group = \"Parameters\")); end M;";
    let out = unparse(src)?;
    assert!(
        out.contains("annotation"),
        "Bug: component annotation is dropped by unparseStr, got: {:?}", out
    );
    Ok(())
}

// ---------------------------------------------------------------------------
// record type
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_record_fields_preserved() -> Result<()> {
    let src = "record Point Real x; Real y; Real z; end Point;";
    let out = unparse(src)?;
    assert!(out.contains("record"), "expected 'record' keyword, got: {:?}", out);
    assert!(out.contains("Point"),  "expected record name 'Point', got: {:?}", out);
    assert!(out.contains("x"),      "expected field 'x', got: {:?}", out);
    assert!(out.contains("y"),      "expected field 'y', got: {:?}", out);
    assert!(out.contains("z"),      "expected field 'z', got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// enumeration type
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_enumeration_literals_preserved() -> Result<()> {
    let src = "type Color = enumeration(red, green, blue);";
    let out = unparse(src)?;
    assert!(out.contains("enumeration"), "expected 'enumeration' keyword, got: {:?}", out);
    assert!(out.contains("Color"),       "expected type name 'Color', got: {:?}", out);
    assert!(out.contains("red"),         "expected literal 'red', got: {:?}", out);
    assert!(out.contains("green"),       "expected literal 'green', got: {:?}", out);
    assert!(out.contains("blue"),        "expected literal 'blue', got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// type alias
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_type_alias_preserved() -> Result<()> {
    let src = "type Voltage = Real(unit = \"V\");";
    let out = unparse(src)?;
    assert!(out.contains("Voltage"), "expected type alias name 'Voltage', got: {:?}", out);
    assert!(out.contains("Real"),    "expected base type 'Real', got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// block type
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_block_keyword_preserved() -> Result<()> {
    let src = "block Integrator Real u; Real y; equation der(y) = u; end Integrator;";
    let out = unparse(src)?;
    assert!(out.contains("block"),      "expected 'block' keyword, got: {:?}", out);
    assert!(out.contains("Integrator"), "expected block name 'Integrator', got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// function with full body
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_function_with_body() -> Result<()> {
    let src = "function square input Real x; output Real y; algorithm y := x * x; end square;";
    let out = unparse(src)?;
    assert!(out.contains("function"),  "expected 'function' keyword, got: {:?}", out);
    assert!(out.contains("square"),    "expected function name 'square', got: {:?}", out);
    assert!(out.contains("input"),     "expected 'input' keyword, got: {:?}", out);
    assert!(out.contains("output"),    "expected 'output' keyword, got: {:?}", out);
    assert!(out.contains("algorithm"), "expected 'algorithm' keyword, got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_function_with_multiple_statements() -> Result<()> {
    let src = concat!(
        "function clamp ",
        "input Real x; input Real lo; input Real hi; ",
        "output Real y; ",
        "algorithm ",
        "  if x < lo then y := lo; ",
        "  elseif x > hi then y := hi; ",
        "  else y := x; ",
        "  end if; ",
        "end clamp;"
    );
    let out = unparse(src)?;
    assert!(out.contains("function"), "expected 'function', got: {:?}", out);
    assert!(out.contains("clamp"),    "expected 'clamp', got: {:?}", out);
    assert!(out.contains("input"),    "expected 'input', got: {:?}", out);
    assert!(out.contains("output"),   "expected 'output', got: {:?}", out);
    assert!(out.contains("if"),       "expected 'if', got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_function_external_declaration() -> Result<()> {
    let src = "function sin input Real x; output Real y; external \"C\" y = sin(x); end sin;";
    let out = unparse(src)?;
    assert!(out.contains("function"), "expected 'function' keyword, got: {:?}", out);
    assert!(out.contains("external"), "expected 'external' keyword, got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// import statement
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_import_statement_preserved() -> Result<()> {
    let src = "package P import Modelica.Math.sin; model M end M; end P;";
    let out = unparse(src)?;
    assert!(out.contains("import"),   "expected 'import' keyword, got: {:?}", out);
    assert!(out.contains("Modelica"), "expected 'Modelica', got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// multiple top-level classes
// ---------------------------------------------------------------------------

#[test]
fn unparse_str_multiple_top_level_classes() -> Result<()> {
    let src = "model A end A; model B end B; model C end C;";
    let out = unparse(src)?;
    assert!(out.contains("A"), "expected class 'A', got: {:?}", out);
    assert!(out.contains("B"), "expected class 'B', got: {:?}", out);
    assert!(out.contains("C"), "expected class 'C', got: {:?}", out);
    Ok(())
}

// ---------------------------------------------------------------------------
// string comments / descriptions
// ---------------------------------------------------------------------------

/// Bug: component-level string comments (descriptions) are silently dropped by
/// unparseStr.  `Real x "The state variable"` round-trips to just `Real x;`.
#[test]
fn unparse_str_component_string_comment_preserved() -> Result<()> {
    let src = "model M Real x \"The state variable\"; end M;";
    let out = unparse(src)?;
    assert!(out.contains("x"), "expected variable 'x', got: {:?}", out);
    assert!(
        out.contains("The state variable"),
        "Bug: component string comment is dropped by unparseStr, got: {:?}", out
    );
    Ok(())
}

#[test]
fn unparse_str_class_string_comment_preserved() -> Result<()> {
    let src = "model Pendulum \"A simple pendulum model\" end Pendulum;";
    let out = unparse(src)?;
    assert!(out.contains("Pendulum"), "expected class name, got: {:?}", out);
    assert!(
        out.contains("A simple pendulum model"),
        "expected class comment to be preserved, got: {:?}", out
    );
    Ok(())
}

// ---------------------------------------------------------------------------
// larger realistic models
// ---------------------------------------------------------------------------

const PENDULUM_MODEL: &str = r#"model Pendulum "Simple pendulum"
  parameter Real m = 1.0 "Mass in kg";
  parameter Real L = 1.0 "Length in m";
  parameter Real g = 9.81 "Gravitational acceleration";
  Real phi(start = 0.1) "Angle from vertical";
  Real phiDot(start = 0.0) "Angular velocity";
equation
  der(phi) = phiDot;
  m * L * L * der(phiDot) = -m * g * L * sin(phi);
end Pendulum;"#;

#[test]
fn unparse_str_pendulum_model_keywords_present() -> Result<()> {
    let out = unparse(PENDULUM_MODEL)?;
    assert!(out.contains("Pendulum"),  "expected class name, got: {:?}", out);
    assert!(out.contains("parameter"), "expected 'parameter', got: {:?}", out);
    assert!(out.contains("equation"),  "expected 'equation', got: {:?}", out);
    assert!(out.contains("der"),       "expected 'der', got: {:?}", out);
    assert!(out.contains("phi"),       "expected 'phi', got: {:?}", out);
    assert!(out.contains("phiDot"),    "expected 'phiDot', got: {:?}", out);
    assert!(out.contains("sin"),       "expected 'sin', got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_pendulum_model_idempotent() -> Result<()> {
    let pass1 = unparse(PENDULUM_MODEL)?;
    assert!(!pass1.is_empty(), "first unparse should not be empty");
    let pass2 = unparse(&pass1)?;
    assert_eq!(
        pass1, pass2,
        "unparseStr should be idempotent for pendulum model:\npass1={:?}\npass2={:?}",
        pass1, pass2
    );
    Ok(())
}

const ELECTRICAL_PACKAGE: &str = r#"package Electrical "Simple electrical models"

  connector Pin "Electrical pin"
    Real v "Voltage";
    flow Real i "Current";
  end Pin;

  model Resistor "Ideal linear resistor"
    parameter Real R = 1.0 "Resistance in Ohm";
    Pin p "Positive pin";
    Pin n "Negative pin";
  equation
    p.v - n.v = R * p.i;
    p.i + n.i = 0;
  end Resistor;

  model Capacitor "Ideal capacitor"
    parameter Real C = 1.0e-6 "Capacitance in Farad";
    Pin p;
    Pin n;
    Real v(start = 0) "Voltage across capacitor";
  equation
    v = p.v - n.v;
    C * der(v) = p.i;
    p.i + n.i = 0;
  end Capacitor;

end Electrical;"#;

#[test]
fn unparse_str_electrical_package_structure_preserved() -> Result<()> {
    let out = unparse(ELECTRICAL_PACKAGE)?;
    assert!(out.contains("package"),    "expected 'package', got: {:?}", out);
    assert!(out.contains("Electrical"), "expected 'Electrical', got: {:?}", out);
    assert!(out.contains("connector"),  "expected 'connector', got: {:?}", out);
    assert!(out.contains("Pin"),        "expected 'Pin', got: {:?}", out);
    assert!(out.contains("Resistor"),   "expected 'Resistor', got: {:?}", out);
    assert!(out.contains("Capacitor"),  "expected 'Capacitor', got: {:?}", out);
    assert!(out.contains("parameter"),  "expected 'parameter', got: {:?}", out);
    assert!(out.contains("equation"),   "expected 'equation', got: {:?}", out);
    assert!(out.contains("flow"),       "expected 'flow', got: {:?}", out);
    assert!(out.contains("der"),        "expected 'der', got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_electrical_package_idempotent() -> Result<()> {
    let pass1 = unparse(ELECTRICAL_PACKAGE)?;
    assert!(!pass1.is_empty(), "first unparse should not be empty");
    let pass2 = unparse(&pass1)?;
    assert_eq!(
        pass1, pass2,
        "unparseStr should be idempotent for electrical package:\npass1={:?}\npass2={:?}",
        pass1, pass2
    );
    Ok(())
}

const STATE_MACHINE_MODEL: &str = r#"model ThermostatController "Simple on-off thermostat"
  parameter Real T_on  = 20.0 "Lower switching temperature";
  parameter Real T_off = 22.0 "Upper switching temperature";
  input  Real T_meas "Measured temperature";
  output Boolean heaterOn(start = false) "Heater command";
equation
  when T_meas < T_on then
    heaterOn = true;
  end when;
  when T_meas > T_off then
    heaterOn = false;
  end when;
end ThermostatController;"#;

#[test]
fn unparse_str_thermostat_model_when_equations_preserved() -> Result<()> {
    let out = unparse(STATE_MACHINE_MODEL)?;
    assert!(out.contains("ThermostatController"), "expected class name, got: {:?}", out);
    assert!(out.contains("parameter"),  "expected 'parameter', got: {:?}", out);
    assert!(out.contains("input"),      "expected 'input', got: {:?}", out);
    assert!(out.contains("output"),     "expected 'output', got: {:?}", out);
    assert!(out.contains("Boolean"),    "expected 'Boolean', got: {:?}", out);
    assert!(out.contains("equation"),   "expected 'equation', got: {:?}", out);
    assert!(out.contains("when"),       "expected 'when', got: {:?}", out);
    assert!(out.contains("end when") || out.contains("end  when"),
        "expected 'end when', got: {:?}", out);
    Ok(())
}

const NUMERIC_PACKAGE: &str = r#"package Numeric "Numerical utility functions"

  function factorial "Compute n!"
    input Integer n;
    output Integer result;
  algorithm
    if n <= 1 then
      result := 1;
    else
      result := n * factorial(n - 1);
    end if;
  end factorial;

  function clamp "Clamp x to [lo, hi]"
    input Real x;
    input Real lo;
    input Real hi;
    output Real y;
  algorithm
    if x < lo then
      y := lo;
    elseif x > hi then
      y := hi;
    else
      y := x;
    end if;
  end clamp;

  type NonnegativeReal = Real(min = 0.0);

  type Status = enumeration(ok, warning, error);

end Numeric;"#;

#[test]
fn unparse_str_numeric_package_structure_preserved() -> Result<()> {
    let out = unparse(NUMERIC_PACKAGE)?;
    assert!(out.contains("Numeric"),     "expected 'Numeric', got: {:?}", out);
    assert!(out.contains("factorial"),   "expected 'factorial', got: {:?}", out);
    assert!(out.contains("clamp"),       "expected 'clamp', got: {:?}", out);
    assert!(out.contains("function"),    "expected 'function', got: {:?}", out);
    assert!(out.contains("algorithm"),   "expected 'algorithm', got: {:?}", out);
    assert!(out.contains("if"),          "expected 'if', got: {:?}", out);
    assert!(out.contains("elseif"),      "expected 'elseif', got: {:?}", out);
    assert!(out.contains("input"),       "expected 'input', got: {:?}", out);
    assert!(out.contains("output"),      "expected 'output', got: {:?}", out);
    assert!(out.contains("enumeration"), "expected 'enumeration', got: {:?}", out);
    assert!(out.contains("Status"),      "expected 'Status', got: {:?}", out);
    assert!(out.contains("NonnegativeReal"), "expected 'NonnegativeReal', got: {:?}", out);
    Ok(())
}

#[test]
fn unparse_str_numeric_package_idempotent() -> Result<()> {
    let pass1 = unparse(NUMERIC_PACKAGE)?;
    assert!(!pass1.is_empty(), "first unparse should not be empty");
    let pass2 = unparse(&pass1)?;
    assert_eq!(
        pass1, pass2,
        "unparseStr should be idempotent for numeric package:\npass1={:?}\npass2={:?}",
        pass1, pass2
    );
    Ok(())
}
