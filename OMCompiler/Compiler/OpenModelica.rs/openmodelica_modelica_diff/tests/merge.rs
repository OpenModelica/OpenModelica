//! Each directory in tests/cases is a diffModelicaFileListings call from the
//! testsuite or from an issue: before.mo, canonical.mo (omc's listing of
//! before.mo), after.mo and the expected merge, expected.mo. The merge has
//! the code of after.mo, or of before.mo when the edit changed nothing, as
//! code that the printer moved stays in place then.
//! `UPDATE_EXPECT=1 cargo test` writes the merges as the expected files.

use std::fs;
use std::path::Path;

use openmodelica_modelica_diff::{Format, code_equal, merge, merge_bytes, merge_with_stats, render};

#[test]
fn cases() {
    let dir = Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/cases");
    let update = std::env::var_os("UPDATE_EXPECT").is_some();
    let mut cases: Vec<_> = fs::read_dir(&dir).unwrap().map(|e| e.unwrap().path()).collect();
    cases.sort();
    let mut failed = Vec::new();
    for case in &cases {
        let read = |f: &str| fs::read_to_string(case.join(f)).unwrap();
        let name = case.file_name().unwrap().to_string_lossy();
        let (before, canonical, after) = (read("before.mo"), read("canonical.mo"), read("after.mo"));
        let merged = merge(&before, &canonical, &after);
        let unchanged = code_equal(&canonical, &after) && code_equal(&merged, &before);
        if !code_equal(&merged, &after) && !unchanged {
            failed.push(format!("{name}: the code is not that of after.mo"));
        }
        let expected = case.join("expected.mo");
        if update {
            fs::write(&expected, &merged).unwrap();
        } else if fs::read_to_string(&expected).ok().as_deref() != Some(merged.as_str()) {
            failed.push(format!("{name}: differs from expected.mo"));
        }
    }
    assert!(cases.len() > 40);
    assert!(failed.is_empty(), "{}", failed.join("\n"));
}

#[test]
fn unchanged_text_is_kept() {
    let before = "model M  // c\n  Real x(start=1,\n         fixed=true);\nequation\n  der(x)=-x;\nend M;\n";
    let canonical = "model M\n  // c\n  Real x(start = 1, fixed = true);\nequation\n  der(x) = -x;\nend M;";
    let big = before.repeat(2000);
    assert_eq!(merge(&big, &canonical.repeat(2000), &canonical.repeat(2000)), big);
}

#[test]
fn deleted_code_takes_its_comments() {
    let before = "model M
  // about x
  Real x; // x
  Real y;
  // between y and z
  Real z;

  // floating

  Real w;
end M;
";
    let canonical = "model M\n  // about x\n  Real x;\n  // x\n  Real y;\n  // between y and z\n  Real z;\n  // floating\n  Real w;\nend M;";
    let after = "model M\n  Real y;\n  Real w;\nend M;";
    let (merged, stats) = merge_with_stats(before, canonical, after);
    assert_eq!(
        merged,
        "model M\n  Real y;\n  // between y and z\n\n  // floating\n\n  Real w;\nend M;\n"
    );
    assert_eq!(stats.ambiguous_comments_kept, 1);
    assert_eq!(stats.deleted_comments, 2);
}

#[test]
fn comments_the_api_dropped_are_kept() {
    let before = "model M\nannotation(Icon(graphics = {\n    // first\n    Line(points = {{0, 0}, {1, 1}}),\n    // second\n    Line(points = {{0, 0}, {1, 1}})\n  }));\nend M;\n";
    let canonical = "model M\n  annotation(\n    Icon(graphics = {// first\n    Line(points = {{0, 0}, {1, 1}}), // second\n    Line(points = {{0, 0}, {1, 1}})}));\nend M;";
    let after = "model M\n  annotation(\n    Icon(graphics = {Line(points = {{0, 0}, {1, 1}}), Line(origin = {2, 3}, points = {{0, 0}, {1, 1}})}));\nend M;";
    let merged = merge(before, canonical, after);
    assert_eq!(
        merged,
        before.replace(
            "    Line(points = {{0, 0}, {1, 1}})\n  }",
            "    Line(origin = {2, 3}, points = {{0, 0}, {1, 1}})\n  }"
        )
    );
}

#[test]
fn moved_code_keeps_its_text() {
    let before = "model M\n  Real x(start=1,\n         fixed=true) \"x\"; // about x\n  Real y;\n  Real z;\nend M;\n";
    let canonical = "model M\n  Real x(start = 1, fixed = true) \"x\";\n  // about x\n  Real y;\n  Real z;\nend M;";
    let after = "model M\n  Real y;\n  Real z;\n  Real x(start = 2, fixed = true) \"x\";\nend M;";
    let (merged, stats) = merge_with_stats(before, canonical, after);
    assert_eq!(
        merged,
        "model M\n  Real y;\n  Real z;\n  Real x(start=2,\n         fixed=true) \"x\"; // about x\nend M;\n"
    );
    assert_eq!(stats.moves, 1);
}

#[test]
fn code_follows_the_order_of_the_printer_in_changed_classes() {
    let before = "package P
  model A
    annotation(Icon(graphics={
      Line(points={{0,0},{1,1}})}));
    extends B(x=1);
  end A;
  model C
    annotation(Icon(graphics={
      Line(points={{0,0},{1,1}})}));
    extends B(x=1);
  end C;
end P;
";
    let canonical = "package P
  model A
    extends B(x = 1);
    annotation(
      Icon(graphics = {Line(points = {{0, 0}, {1, 1}})}));
  end A;

  model C
    extends B(x = 1);
    annotation(
      Icon(graphics = {Line(points = {{0, 0}, {1, 1}})}));
  end C;
end P;";
    let after = canonical.replacen("B(x = 1)", "B(x = 2)", 1);
    let (merged, stats) = merge_with_stats(before, canonical, &after);
    assert_eq!(
        merged,
        before.replacen(
            "    annotation(Icon(graphics={\n      Line(points={{0,0},{1,1}})}));\n    extends B(x=1);",
            "    extends B(x=2);\n    annotation(Icon(graphics={\n      Line(points={{0,0},{1,1}})}));",
            1
        )
    );
    assert_eq!(stats.reordered, 1);
    assert_eq!(merge(before, canonical, canonical), before);
}

#[test]
fn new_list_elements_follow_the_layout_of_the_list() {
    let before = "model M\n  annotation(Icon(graphics={\n      Line(points={{0,0},{1,1}}),\n      Line(points={{2,2},{3,3}})}));\nend M;\n";
    let canonical = "model M\n  annotation(\n    Icon(graphics = {Line(points = {{0, 0}, {1, 1}}), Line(points = {{2, 2}, {3, 3}})}));\nend M;";
    let after = "model M\n  annotation(\n    Icon(graphics = {Line(points = {{0, 0}, {1, 1}}), Line(points = {{2, 2}, {3, 3}}), Rectangle(extent = {{0, 0}, {1, 1}})}));\nend M;";
    let merged = merge(before, canonical, after);
    assert_eq!(
        merged,
        before.replace("{3,3}})}", "{3,3}}),\n      Rectangle(extent = {{0, 0}, {1, 1}})}")
    );
}

#[test]
fn new_elements_are_indented_like_their_neighbours() {
    let before = "package A\n    model M\n        Real x;\n    end M;\nend A;\n";
    let canonical = "package A\n  model M\n    Real x;\n  end M;\nend A;";
    let after = "package A\n  model M\n    Real x;\n    Real y \"new\";\n  end M;\nend A;";
    let merged = merge(before, canonical, after);
    assert_eq!(
        merged,
        "package A\n    model M\n        Real x;\n        Real y \"new\";\n    end M;\nend A;\n"
    );
}

#[test]
fn removing_a_modifier_keeps_words_apart() {
    let before = "model M\n  A a(abc=23) annotation(Placement(visible=true));\nend M;\n";
    let canonical = "model M\n  A a(abc = 23) annotation(\n    Placement(visible = true));\nend M;";
    let after = "model M\n  A a annotation(\n    Placement(visible = true));\nend M;";
    assert_eq!(
        merge(before, canonical, after),
        "model M\n  A a annotation(Placement(visible=true));\nend M;\n"
    );
}

#[test]
fn within_is_kept_and_added_on_a_line_of_its_own() {
    let before = "within P;\nmodel M\nend M;\n";
    assert_eq!(merge(before, "within P;\nmodel M\nend M;", "model M\nend M;"), before);
    let merged = merge("model M\n\nend M;", "model M\nend M;", "within A;\nmodel M\nend M;");
    assert_eq!(merged, "within A;\nmodel M\n\nend M;");
}

#[test]
fn formats() {
    let before = "model M\n  Real x=1;\nend M;\n";
    let merged = merge(
        before,
        "model M\n  Real x = 1;\nend M;",
        "model M\n  Real x = 2;\nend M;",
    );
    assert_eq!(render(before, &merged, Format::Plain), merged);
    assert_eq!(
        render(before, &merged, Format::Color),
        "model M\n  Real x=\x1b[9;31m1\x1b[0m\x1b[4;32m2\x1b[0m;\nend M;\n"
    );
    assert_eq!(
        render(before, &merged, Format::Xml),
        "<equal>model M\n  Real x=</equal><del>1</del><add>2</add><equal>;\nend M;\n</equal>"
    );
}

#[test]
fn code_equality() {
    assert!(code_equal(
        "within P;\nmodel M Real x=1.0; end M;",
        "model M\n  // c\n  Real x = 1.; end M;"
    ));
    assert!(code_equal("x = \"a\n   b\n     c\";", "x = \"a\n b\n   c\";"));
    assert!(!code_equal("x = \"a\n   b\n     c\";", "x = \"a\n b\n c\";"));
    assert!(!code_equal("model M Real x; end M;", "model M Real y; end M;"));
    assert!(!code_equal("model M end M;", "model M Real y; end M;"));
}

#[test]
fn moved_code_keeps_new_tokens_once() {
    let before = "model M\n  Modelica.Blocks.Math.Gain gain(k=2) annotation(Placement(transformation(extent={{-10,-10},{10,10}})));\n  Real x;\nend M;\n";
    let canonical = "model M\n  Modelica.Blocks.Math.Gain gain(k = 2) annotation(\n    Placement(transformation(extent = {{-10, -10}, {10, 10}})));\n  Real x;\nend M;";
    let after = "model M\n  Real x;\n  Buildings.Controls.OBC.CDL.Reals.MultiplyByParameter gain1(k = 2) annotation(\n    Placement(transformation(extent = {{-10, -10}, {10, 10}})));\nend M;";
    let merged = merge(before, canonical, after);
    assert!(code_equal(&merged, after), "{merged}");
    assert_eq!(merged.matches("Buildings").count(), 1, "{merged}");
}

#[test]
fn whitespace_edits_in_strings_are_kept() {
    let before = "model M\n  annotation(Documentation(info=\"<html>\n<pre>\nx = 1;\n</pre>\n</html>\"));\nend M;\n";
    let canonical = "model M\n  annotation(\n    Documentation(info = \"<html>\n    <pre>\n    x = 1;\n    </pre>\n    </html>\"));\nend M;";
    let after = canonical.replace("    x = 1;", "        x = 1;");
    let merged = merge(before, canonical, &after);
    assert!(merged.contains("<pre>\n        x = 1;"), "{merged}");
    assert!(code_equal(&merged, &after));
    assert!(!code_equal(&merged, canonical));
}

#[test]
fn comments_are_not_copied_from_after() {
    let before = "model M Real x; /* about x */ Real z; end M;";
    let canonical = "model M\n  Real x;\n  /* about x */\n  Real z;\nend M;";
    let after = "model M\n  Real x;\n  /* about x */\n  Real y;\n  Real z;\nend M;";
    let merged = merge(before, canonical, after);
    assert_eq!(merged.matches("about x").count(), 1, "{merged}");
    assert!(code_equal(&merged, after), "{merged}");
}

#[test]
fn new_lines_go_after_a_comment_that_continues() {
    let before = "model M\n  Real x; /* about x\n     continues */\nend M;\n";
    let canonical = "model M\n  Real x;\n  /* about x\n     continues */\nend M;";
    let after = "model M\n  Real x;\n  /* about x\n     continues */\n  Real w;\nend M;";
    assert_eq!(
        merge(before, canonical, after),
        "model M\n  Real x; /* about x\n     continues */\n  Real w;\nend M;\n"
    );
}

#[test]
fn new_comments_are_kept() {
    let before = "model M\n  Real x;\nend M;\n";
    let canonical = "model M\n  Real x;\nend M;";
    let after = "model M\n  Real x;\n  // about y\n  Real y;\nend M;";
    assert_eq!(
        merge(before, canonical, after),
        "model M\n  Real x;\n  // about y\n  Real y;\nend M;\n"
    );
    let before = "model M Real x; Real z; end M;";
    let canonical = "model M\n  Real x;\n  Real z;\nend M;";
    let after = "model M\n  Real x; // about x\n  Real z;\nend M;";
    assert!(merge(before, canonical, after).contains("// about x\n"));
}

#[test]
fn new_elements_are_indented_like_the_start_of_their_neighbours() {
    let before = "model M\n  Real y(start=1,\n         fixed=true);\nend M;\n";
    let canonical = "model M\n  Real y(start = 1, fixed = true);\nend M;";
    let after = "model M\n  Real y(start = 1, fixed = true);\n  Real w;\nend M;";
    assert_eq!(
        merge(before, canonical, after),
        "model M\n  Real y(start=1,\n         fixed=true);\n  Real w;\nend M;\n"
    );
}

#[test]
fn code_between_comments_is_not_a_comment() {
    let before = "model M\n\n  /* a */ Real z; /* b */\n  Real x;\nend M;\n";
    let canonical = "model M\n  /* a */\n  Real z;\n  /* b */\n  Real x;\nend M;";
    let after = "model M\n  /* a */\n  Real z;\n  /* b */\nend M;";
    assert_eq!(
        merge(before, canonical, after),
        "model M\n\n  /* a */ Real z; /* b */\nend M;\n"
    );
}

#[test]
fn tokens_the_printer_changed_are_replaced_with_their_edit() {
    let merged = merge(
        "model M\n  Real y = (a + b);\nend M;\n",
        "model M\n  Real y = a + b;\nend M;",
        "model M\n  Real y = a + c;\nend M;",
    );
    assert_eq!(merged, "model M\n  Real y = (a + c);\nend M;\n");
    let merged = merge(
        "model M\n  Real y = 'abs'(x);\nend M;\n",
        "model M\n  Real y = abs(x);\nend M;",
        "model M\n  Real y = sqrt(x);\nend M;",
    );
    assert_eq!(merged, "model M\n  Real y = sqrt(x);\nend M;\n");
}

#[test]
fn many_moved_annotations_are_fast_and_stay_in_unchanged_classes() {
    let class = |i: usize, k: usize| {
        (
            format!(
                "  model M{i}\n    Real x;\n    annotation(Icon(graphics={{Line(points={{{{0,0}},{{1,1}}}})}}));\n  equation\n    x = {k};\n  end M{i};\n"
            ),
            format!(
                "  model M{i}\n    Real x;\n  equation\n    x = {k};\n    annotation(\n      Icon(graphics = {{Line(points = {{{{0, 0}}, {{1, 1}}}})}}));\n  end M{i};\n"
            ),
        )
    };
    let n = 3000;
    let mut before = String::from("package P\n");
    let mut canonical = String::from("package P\n");
    let mut after = String::from("package P\n");
    for i in 0..n {
        let (b, c) = class(i, 1);
        before += &b;
        canonical += &c;
        after += &if i == n / 2 { class(i, 2).1 } else { c };
    }
    before += "end P;\n";
    canonical += "end P;";
    after += "end P;";
    let t = std::time::Instant::now();
    let (merged, stats) = merge_with_stats(&before, &canonical, &after);
    assert!(t.elapsed().as_secs() < 10, "{:?}", t.elapsed());
    assert_eq!(stats.reordered, 1);
    assert_eq!(merged.matches("x = 2").count(), 1);
    let changed = merged.lines().zip(before.lines()).filter(|(m, b)| m != b).count();
    assert!(changed <= 4, "{changed} lines changed");
}

#[test]
fn bytes_that_are_not_utf8_are_kept() {
    let before = b"model M\n  Real x; // F\xf6rster\nend M;\n";
    let merged = merge_bytes(
        before,
        b"model M\n  Real x;\nend M;",
        b"model M\n  Real x;\n  Real y;\nend M;",
    );
    assert_eq!(merged, b"model M\n  Real x; // F\xf6rster\n  Real y;\nend M;\n");
}

#[test]
fn no_panic_for_other_edits() {
    let dir = Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/cases");
    for case in fs::read_dir(&dir).unwrap().map(|e| e.unwrap().path()) {
        let read = |f: &str| fs::read_to_string(case.join(f)).unwrap();
        let (before, canonical, after) = (read("before.mo"), read("canonical.mo"), read("after.mo"));
        let lines: Vec<&str> = after.lines().collect();
        for i in (0..lines.len()).step_by(lines.len().div_ceil(10)) {
            let mut variants = vec![lines.clone(), lines.clone(), lines.clone()];
            variants[0].remove(i);
            variants[1].insert(i, lines[i]);
            variants[2].swap(i, (i * 7 + 3) % lines.len());
            for v in variants {
                let edited = v.join("\n");
                let merged = merge(&before, &canonical, &edited);
                render(&before, &merged, Format::Color);
            }
        }
    }
}
