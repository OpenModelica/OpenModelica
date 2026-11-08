use openmodelica_package_manager::{MessageKind, Solution, resolve};
use serde_json::{Value, json};

fn solve(problem: Value) -> Solution {
    resolve(&serde_json::from_str(&problem.to_string()).unwrap())
}

fn picked(s: &Solution) -> Vec<String> {
    assert!(s.ok, "{:?}", s.error);
    s.selected.iter().map(|x| format!("{} {}", x.name, x.version)).collect()
}

fn kinds(s: &Solution) -> Vec<(MessageKind, String, String)> {
    s.messages
        .iter()
        .map(|m| (m.kind, m.name.clone(), m.version.clone()))
        .collect()
}

fn req(name: &str, version: &str) -> Value {
    json!({"name": name, "version": version, "origin": "test"})
}

fn installed(index: &Value) -> Value {
    let mut all = Vec::new();
    for (name, lib) in index["libs"].as_object().unwrap() {
        for version in lib["versions"].as_object().unwrap().keys() {
            all.push(json!({"name": name, "version": version, "path": format!("{name} {version}")}));
        }
    }
    Value::Array(all)
}

fn media_index() -> Value {
    json!({"libs": {
        "Modelica": {"versions": {
            "3.2.3+maint.om": {"support": "fullSupport", "provides": ["3.2.2"]},
            "4.0.0+maint.om": {"support": "fullSupport"}}},
        "ExternalMedia": {"versions": {
            "3.3.2": {"support": "fullSupport", "uses": {"Modelica": "3.2.3"}, "provides": ["3.3.1"]},
            "4.0.0": {"support": "fullSupport", "uses": {"Modelica": "4.0.0"}, "provides": ["3.3.1", "3.3.2"]}}}}})
}

#[test]
fn issue_10595_old_version_with_its_msl() {
    let index = media_index();
    let s =
        solve(json!({"index": index, "installed": installed(&index), "requirements": [req("ExternalMedia", "3.3.2")]}));
    assert_eq!(picked(&s), ["ExternalMedia 3.3.2", "Modelica 3.2.3+maint.om"]);
    assert!(s.messages.is_empty());
}

#[test]
fn issue_10595_conflict_is_an_error() {
    let index = media_index();
    let s = solve(json!({"index": index, "installed": installed(&index),
        "requirements": [req("ExternalMedia", "3.3.2"), req("Modelica", "4.0.0")]}));
    assert!(!s.ok);
    let error = s.error.unwrap();
    assert!(error.contains("ExternalMedia 3.3.2 cannot be loaded"), "{error}");
}

#[test]
fn issue_10595_old_version_not_installed() {
    let index = media_index();
    let s = solve(json!({"index": index,
        "installed": [{"name": "ExternalMedia", "version": "4.0.0"}, {"name": "Modelica", "version": "4.0.0+maint.om"}],
        "requirements": [req("ExternalMedia", "3.3.2")]}));
    assert!(picked(&s).is_empty());
    assert_eq!(
        kinds(&s),
        [(MessageKind::Missing, "ExternalMedia".into(), "3.3.2".into())]
    );
}

#[test]
fn install_mode_chooses_from_the_index() {
    let s = solve(json!({"index": media_index(), "install": true, "requirements": [req("ExternalMedia", "3.3.2")]}));
    assert_eq!(picked(&s), ["ExternalMedia 3.3.2", "Modelica 3.2.3+maint.om"]);
    assert!(s.selected.iter().all(|x| !x.installed));
}

#[test]
fn loaded_incompatible_version_is_kept_with_a_warning() {
    let index = media_index();
    let s = solve(json!({"index": index, "installed": installed(&index),
        "loaded": [{"name": "Modelica", "version": "4.0.0"}],
        "requirements": [req("ExternalMedia", "3.3.2")]}));
    assert_eq!(picked(&s), ["ExternalMedia 3.3.2", "Modelica 4.0.0+maint.om"]);
    assert!(s.selected[1].loaded);
    assert_eq!(s.messages.len(), 1);
    assert_eq!(s.messages[0].kind, MessageKind::Incompatible);
    assert_eq!(s.messages[0].origin, "ExternalMedia 3.3.2");
}

#[test]
fn issue_8885_highest_declared_compatible() {
    let installed = json!([
        {"name": "MyLib", "version": "9.8.0", "provides": ["9.7.0"]},
        {"name": "MyLib", "version": "9.9.0", "provides": ["9.7.0", "9.8.0"]},
        {"name": "MyLib", "version": "10.0.0"},
        {"name": "MyLib", "version": "10.1.0", "provides": ["10.0.0"]}]);
    for (wanted, expected) in [
        ("9.7.0", "9.9.0"),
        ("9.8.0", "9.9.0"),
        ("9.9.0", "9.9.0"),
        ("10.0.0", "10.1.0"),
        ("10.1.0", "10.1.0"),
    ] {
        let s = solve(json!({"installed": installed, "requirements": [req("MyLib", wanted)]}));
        assert_eq!(picked(&s), [format!("MyLib {expected}")], "{wanted}");
    }
    let s = solve(json!({"installed": installed, "requirements": [req("MyLib", "9.6.0")]}));
    assert_eq!(picked(&s), ["MyLib 9.9.0"]);
    let s = solve(json!({"installed": installed, "requirements": [req("MyLib", "8.0.0")]}));
    assert!(picked(&s).is_empty());
    assert_eq!(s.messages[0].kind, MessageKind::Missing);
}

#[test]
fn newer_dependency_provides_both() {
    let index = json!({"libs": {
        "Modelica": {"versions": {"3.2.1": {}, "3.2.2": {}, "3.2.3": {"provides": ["3.2.1", "3.2.2"]}}},
        "L": {"versions": {
            "2.3.1": {"uses": {"Modelica": "3.2.1"}},
            "2.3.4": {"uses": {"Modelica": "3.2.2"}, "provides": ["2.3.1"]}}}}});
    let s = solve(json!({"index": index, "installed": installed(&index), "requirements": [req("L", "2.3.1")]}));
    assert_eq!(picked(&s), ["L 2.3.4", "Modelica 3.2.3"]);
}

#[test]
fn support_and_prereleases() {
    let index = json!({"libs": {"Modelica": {"versions": {
        "4.0.0+maint.om": {"support": "fullSupport"},
        "4.1.0+maint.om": {"support": "fullSupport", "provides": ["4.0.0"]},
        "4.2.0-dev": {"support": "noSupport", "provides": ["4.0.0", "4.1.0"]},
        "master": {"support": "noSupport", "provides": ["4.0.0", "4.1.0"]}}}}});
    let all = installed(&index);
    let s = solve(json!({"index": index, "installed": all, "requirements": [req("Modelica", "4.0.0")]}));
    assert_eq!(picked(&s), ["Modelica 4.1.0+maint.om"]);
    let s = solve(json!({"index": index, "installed": all, "requirements": [req("Modelica", "")]}));
    assert_eq!(picked(&s), ["Modelica 4.1.0+maint.om"]);
    let s = solve(json!({"index": index, "installed": all,
        "requirements": [{"name": "Modelica", "version": "4.0.0", "exact": true, "origin": "test"}]}));
    assert_eq!(picked(&s), ["Modelica 4.0.0+maint.om"]);
    let s = solve(json!({"index": index, "installed": all, "requirements": [req("Modelica", "master")]}));
    assert_eq!(picked(&s), ["Modelica master"]);
}

#[test]
fn known_version_falls_back_to_a_branch() {
    let index = json!({"libs": {"Modelica": {"versions": {
        "4.0.0+maint.om": {"support": "fullSupport"},
        "master": {"support": "noSupport"}}}}});
    let s = solve(
        json!({"index": index, "installed": [{"name": "Modelica", "version": "master"}],
        "requirements": [req("Modelica", "4.0.0")]}),
    );
    assert_eq!(picked(&s), ["Modelica master"]);
    assert_eq!(
        kinds(&s),
        [(MessageKind::BranchFallback, "Modelica".into(), "4.0.0".into())]
    );
}

fn ipsl_index() -> Value {
    json!({"libs": {
        "OpenIPSL": {"versions": {"3.0.1": {"support": "support"}, "master": {"support": "noSupport"}}},
        "OpenHPL": {"versions": {"1.0.0": {"support": "support", "uses": {"OpenIPSL": "2.0.0-dev"}}}}}})
}

#[test]
fn unknown_version_takes_a_branch() {
    let index = ipsl_index();
    let s = solve(json!({"index": index, "installed": installed(&index), "requirements": [req("OpenHPL", "1.0.0")]}));
    assert_eq!(picked(&s), ["OpenHPL 1.0.0", "OpenIPSL master"]);
    assert_eq!(
        kinds(&s),
        [(MessageKind::UnknownVersion, "OpenIPSL".into(), "2.0.0-dev".into())]
    );
}

#[test]
fn unknown_version_does_not_override_a_release() {
    let index = ipsl_index();
    let s = solve(json!({"index": index, "installed": installed(&index),
        "requirements": [req("OpenIPSL", "3.0.1"), req("OpenHPL", "1.0.0")]}));
    assert_eq!(picked(&s), ["OpenHPL 1.0.0", "OpenIPSL 3.0.1"]);
    assert_eq!(
        kinds(&s),
        [(MessageKind::UnknownVersion, "OpenIPSL".into(), "2.0.0-dev".into())]
    );
}

#[test]
fn unknown_version_never_forces() {
    let index = json!({"libs": {
        "Modelica": {"versions": {"3.2.3": {}, "4.0.0": {}}},
        "TILMedia": {"versions": {"1.9.0-ClaRa": {"uses": {"Modelica": "4.0.0"}}, "main": {"uses": {"Modelica": "4.0.0"}}}},
        "ClaRa": {"versions": {"1.3.0": {"uses": {"Modelica": "3.2.3", "TILMedia": "1.3.0-ClaRa"}}}}}});
    let s = solve(json!({"index": index, "installed": installed(&index), "requirements": [req("ClaRa", "1.3.0")]}));
    assert_eq!(picked(&s), ["ClaRa 1.3.0", "Modelica 3.2.3"]);
    assert_eq!(
        kinds(&s),
        [(MessageKind::Missing, "TILMedia".into(), "1.3.0-ClaRa".into())]
    );
}

fn linear_systems(any_version: bool) -> Value {
    json!({"libs": {
        "DymolaCommands": {"anyVersion": any_version, "versions": {"master": {"support": "noSupport"}}},
        "Modelica_LinearSystems2": {"versions": {
            "3.0.0": {"support": "support", "uses": {"DymolaCommands": "1.17.0"}},
            "3.0.1": {"support": "support", "uses": {"DymolaCommands": "1.20.0"}, "provides": ["3.0.0"]}}}}})
}

#[test]
fn any_version_library_keeps_claims() {
    let index = linear_systems(true);
    let s = solve(json!({"index": index, "installed": installed(&index),
        "requirements": [req("Modelica_LinearSystems2", "3.0.0")]}));
    assert_eq!(picked(&s), ["DymolaCommands master", "Modelica_LinearSystems2 3.0.1"]);
    let index = linear_systems(false);
    let s = solve(json!({"index": index, "installed": installed(&index),
        "requirements": [req("Modelica_LinearSystems2", "3.0.0")]}));
    assert_eq!(picked(&s), ["DymolaCommands master", "Modelica_LinearSystems2 3.0.0"]);
}

#[test]
fn all_requirements_together() {
    let index = json!({"libs": {
        "B": {"versions": {"1.0.0": {}, "2.0.0": {}}},
        "A": {"versions": {"1.0.0": {"uses": {"B": "1.0.0"}}}}}});
    let s = solve(
        json!({"index": index, "installed": installed(&index), "requirements": [req("B", ""), req("A", "1.0.0")]}),
    );
    assert_eq!(picked(&s), ["A 1.0.0", "B 1.0.0"]);
}

#[test]
fn missing_dependency_is_reported() {
    let s = solve(
        json!({"installed": [{"name": "A", "version": "1.0.0", "uses": {"X": "2.0.0"}}],
        "requirements": [req("A", "1.0.0")]}),
    );
    assert_eq!(picked(&s), ["A 1.0.0"]);
    assert_eq!(kinds(&s), [(MessageKind::Missing, "X".into(), "2.0.0".into())]);
    assert_eq!(s.messages[0].origin, "A 1.0.0");
}

#[test]
fn exact_uses_fall_back() {
    let index = json!({"libs": {
        "Modelica": {"versions": {"4.0.0": {}, "4.1.0": {"provides": ["4.0.0"]}}},
        "B": {"versions": {"9.0.0": {"uses": {"Modelica": "4.0.0"}}, "10.0.0": {"uses": {"Modelica": "3.9.0"}}}}}});
    let exact = |version: &str| json!([{"name": "B", "version": version, "exact": true, "origin": "test"}]);
    let s = solve(json!({"index": index, "install": true, "exactUses": true, "requirements": exact("9.0.0")}));
    assert_eq!(picked(&s), ["B 9.0.0", "Modelica 4.0.0"]);
    assert!(s.messages.is_empty());
    assert_eq!(s.selected[1].origin, "B 9.0.0");
    let s = solve(json!({"index": index, "install": true, "requirements": exact("9.0.0")}));
    assert_eq!(picked(&s), ["B 9.0.0", "Modelica 4.1.0"]);
    let s = solve(json!({"index": index, "install": true, "exactUses": true, "requirements": exact("9.1.0")}));
    assert!(picked(&s).is_empty());
}

#[test]
fn version_list() {
    let mut index = media_index();
    index["libs"]["ExternalMedia"]["versions"]["master"] = json!({"support": "noSupport"});
    let list = |version: &str| {
        solve(
            json!({"index": index, "install": true, "versions": true, "requirements": [req("ExternalMedia", version)]}),
        )
        .versions
    };
    assert_eq!(list("3.3.2"), ["3.3.2", "master"]);
    assert_eq!(list("3.3.1"), ["4.0.0", "3.3.2", "master"]);
    assert_eq!(list(""), ["4.0.0", "3.3.2", "master"]);
    assert_eq!(list("9.0.0"), ["master"]);
    assert!(list("master").contains(&"master".to_owned()));
}

#[test]
fn priority_versions_and_old_prereleases() {
    let installed = json!([
        {"name": "Modelica", "version": "3.1"}, {"name": "Modelica", "version": "3.2"},
        {"name": "Modelica", "version": "3.2.1"}, {"name": "Modelica", "version": "3.4 beta1"},
        {"name": "Modelica", "version": "CustomSort"}]);
    let load = |versions: Value| {
        picked(&solve(json!({"installed": installed,
            "requirements": [{"name": "Modelica", "versions": versions, "origin": "test"}]})))
    };
    assert_eq!(load(json!(["4.1", "3.2"])), ["Modelica 3.2"]);
    assert_eq!(load(json!(["4.1", "3.1", "3.2"])), ["Modelica 3.1"]);
    assert_eq!(load(json!(["default", "3.2"])), ["Modelica 3.2.1"]);
    assert_eq!(load(json!(["3.4"])), ["Modelica 3.4 beta1"]);
    assert_eq!(load(json!(["CustomSort"])), ["Modelica CustomSort"]);
}

#[test]
fn malformed_facts_are_left_out() {
    let s = solve(json!({
        "index": {"libs": {
            "Modelica": {"versions": {"4.0.0": {"provides": "3.2.3", "uses": {"X": 1}, "support": 5}}},
            "Bad": 7,
            "Worse": {"versions": ["1.0.0"]}}},
        "installed": [{"name": "Modelica", "version": "4.0.0", "uses": ["X"], "provides": {"a": 1}, "support": false}],
        "requirements": [req("Modelica", "4.0.0")]}));
    assert_eq!(picked(&s), ["Modelica 4.0.0"]);
    assert!(s.messages.is_empty());
}

#[test]
fn newer_release_with_the_same_major_version() {
    let installed = json!([{"name": "E", "version": "3.2.0"}, {"name": "E", "version": "3.0.5"},
        {"name": "E", "version": "4.0.0"}, {"name": "E", "version": "master"}]);
    let load = |v: &str| picked(&solve(json!({"installed": installed, "requirements": [req("E", v)]})));
    assert_eq!(load("3.0.0"), ["E 3.0.5"]);
    assert_eq!(load("3.1.0"), ["E 3.2.0"]);
    assert_eq!(load("2.0.0"), ["E master"]);
    let s = solve(
        json!({"install": true, "index": {"libs": {"E": {"versions": {"3.2.0": {}}}}},
        "requirements": [req("E", "3.0.0")]}),
    );
    assert!(picked(&s).is_empty());
}

#[test]
fn broken_claims_are_no_semver_fallback() {
    let index = json!({"libs": {
        "M": {"versions": {"1.0.0": {}, "2.0.0": {}}},
        "L": {"versions": {
            "1.0.0": {"uses": {"M": "1.0.0"}},
            "1.1.0": {"uses": {"M": "2.0.0"}, "provides": ["1.0.0"]}}}}});
    let s = solve(json!({"index": index,
        "installed": [{"name": "L", "version": "1.1.0"}, {"name": "M", "version": "2.0.0"}],
        "requirements": [req("L", "1.0.0")]}));
    assert!(picked(&s).is_empty());
}

#[test]
fn priority_falls_back_within_the_major_version() {
    let installed = json!([{"name": "R", "version": "3.2.3"}, {"name": "R", "version": "4.0.0"}]);
    let s = solve(json!({"installed": installed,
        "requirements": [{"name": "R", "versions": ["3.2.2", "4.0.0"], "origin": "test"}]}));
    assert_eq!(picked(&s), ["R 3.2.3"]);
}

#[test]
fn exact_does_not_take_prereleases() {
    let s = solve(
        json!({"install": true, "index": {"libs": {"W": {"versions": {"4.2.0-dev": {}}}}},
        "requirements": [{"name": "W", "version": "4.2.0", "exact": true, "origin": "test"}]}),
    );
    assert!(picked(&s).is_empty());
}

#[test]
fn exact_uses_are_only_preferred() {
    let index = json!({"libs": {
        "Y": {"versions": {"1.0.0": {}, "1.1.0": {"provides": ["1.0.0"]}}},
        "Z": {"versions": {"1.0.0": {"uses": {"Y": "1.1.0"}}}},
        "X": {"versions": {"1.0.0": {"uses": {"Y": "1.0.0", "Z": "1.0.0"}}}}}});
    let s = solve(json!({"index": index, "install": true, "exactUses": true,
        "requirements": [{"name": "X", "version": "1.0.0", "exact": true, "origin": "test"}]}));
    assert_eq!(picked(&s), ["X 1.0.0", "Y 1.1.0", "Z 1.0.0"]);
}

#[test]
fn claims_do_not_depend_on_other_requirements() {
    let index = json!({"libs": {
        "A": {"versions": {"1.0.0": {"uses": {"B": "1.0.0", "C": "1.0.0"}},
                           "2.0.0": {"uses": {"B": "2.0.0", "C": "2.0.0"}, "provides": ["1.0.0"]}}},
        "B": {"versions": {"1.0.0": {"uses": {"A": "1.0.0"}},
                           "2.0.0": {"uses": {"A": "2.0.0"}, "provides": ["1.0.0"]}}},
        "C": {"versions": {"1.0.0": {}, "2.0.0": {}}},
        "X": {"versions": {"1.0.0": {"uses": {"B": "1.0.0"}}}},
        "D": {"versions": {"2.0.0": {"uses": {"A": "2.0.0"}},
                           "3.0.0": {"uses": {"A": "1.0.0"}, "provides": ["2.0.0"]}}}}});
    let ok = |reqs: Value| solve(json!({"index": index, "install": true, "requirements": reqs})).ok;
    assert!(!ok(json!([req("X", "1.0.0"), req("A", "2.0.0")])));
    assert!(!ok(json!([req("X", "1.0.0"), req("A", "2.0.0"), req("D", "2.0.0")])));
}

/// `OMC_PKGRESOLVE_INDEX=~/.openmodelica/libraries/index.json cargo test -- --ignored`
#[test]
#[ignore]
fn every_index_version_installs() {
    let path = std::env::var("OMC_PKGRESOLVE_INDEX").expect("OMC_PKGRESOLVE_INDEX");
    let index: Value = serde_json::from_str(&std::fs::read_to_string(path).unwrap()).unwrap();
    let mut failed = Vec::new();
    let mut messages = 0;
    for (name, lib) in index["libs"].as_object().unwrap() {
        for version in lib["versions"].as_object().unwrap().keys() {
            let s = solve(json!({"index": index, "install": true,
                "requirements": [{"name": name, "version": version, "exact": true, "origin": "test"}]}));
            if s.ok {
                messages += s.messages.len();
            } else {
                failed.push(format!("{name} {version}: {}", s.error.unwrap()));
            }
        }
    }
    eprintln!("{} unsolvable, {messages} messages", failed.len());
    for f in &failed {
        eprintln!("{f}");
    }
}
