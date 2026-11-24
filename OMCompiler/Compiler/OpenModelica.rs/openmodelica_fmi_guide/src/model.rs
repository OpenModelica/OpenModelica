//! The model file (`fmi-settings.json`): questions, settings and rules.

use std::collections::{BTreeMap, HashMap, HashSet};

use serde::Deserialize;
use serde_json::Value;

use crate::eval::references;

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Model {
    #[serde(default)]
    pub tool: Option<String>,
    #[serde(default)]
    pub support_levels: Vec<SupportLevel>,
    pub inputs: Vec<Input>,
    pub settings: Vec<Setting>,
    pub rules: Vec<Rule>,
}

#[derive(Deserialize)]
pub struct SupportLevel {
    pub id: String,
    pub label: String,
    pub available: bool,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Input {
    pub id: String,
    #[serde(rename = "type")]
    pub kind: String,
    #[serde(default)]
    pub default: Value,
    #[serde(default)]
    pub enabled_when: Option<Value>,
    #[serde(default)]
    pub options: Vec<InputOption>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct InputOption {
    pub value: String,
    #[serde(default)]
    pub enabled_when: Option<Value>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Setting {
    pub id: String,
    #[serde(default)]
    pub label: String,
    #[serde(default)]
    pub explicit: bool,
    #[serde(default)]
    pub relevant_when: Option<Value>,
    #[serde(default)]
    pub options: Vec<SettingOption>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SettingOption {
    pub value: String,
    #[serde(default)]
    pub label: String,
    #[serde(default)]
    pub default: bool,
    #[serde(default)]
    pub requires: Option<Value>,
    #[serde(default)]
    pub requires_note: Option<String>,
    /// A level, or a list of `{ when, level, note }`.
    #[serde(default)]
    pub support: Option<Value>,
    #[serde(default)]
    pub support_note: Option<String>,
    #[serde(default)]
    pub omc: Option<Omc>,
}

#[derive(Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct Omc {
    #[serde(default)]
    pub args: BTreeMap<String, String>,
    #[serde(default)]
    pub flags: Vec<String>,
    #[serde(default)]
    pub fmi_flags: Vec<String>,
}

#[derive(Deserialize)]
pub struct Rule {
    #[serde(default)]
    pub id: String,
    #[serde(default)]
    pub when: Value,
    #[serde(default)]
    pub because: Option<String>,
    #[serde(default)]
    pub exclude: BTreeMap<String, Vec<String>>,
    #[serde(default)]
    pub score: BTreeMap<String, BTreeMap<String, i64>>,
    #[serde(default)]
    pub enables: BTreeMap<String, String>,
    #[serde(default)]
    pub warn: Option<String>,
    #[serde(default)]
    pub advice: Option<String>,
}

impl Model {
    pub fn setting(&self, id: &str) -> Option<&Setting> {
        self.settings.iter().find(|s| s.id == id)
    }

    pub fn level(&self, id: &str) -> Option<&SupportLevel> {
        self.support_levels.iter().find(|l| l.id == id)
    }

    /// Mistakes a person who edits the file is likely to make. Empty when the model is sound.
    pub fn validate(&self) -> Vec<String> {
        let mut errors = Vec::new();
        let mut order: HashMap<&str, usize> = HashMap::new();
        let mut values: HashMap<&str, HashSet<&str>> = HashMap::new();
        let mut is_setting: HashSet<&str> = HashSet::new();

        for (kind, id, options) in self
            .inputs
            .iter()
            .map(|i| {
                (
                    "input",
                    i.id.as_str(),
                    i.options.iter().map(|o| o.value.as_str()).collect::<Vec<_>>(),
                )
            })
            .chain(self.settings.iter().map(|s| {
                (
                    "setting",
                    s.id.as_str(),
                    s.options.iter().map(|o| o.value.as_str()).collect::<Vec<_>>(),
                )
            }))
        {
            if id.is_empty() {
                errors.push(format!("A {kind} has no id."));
                continue;
            }
            if ["any", "all", "not"].contains(&id) {
                errors.push(format!("\"{id}\" is a reserved word and cannot be an id."));
            }
            if order.contains_key(id) {
                errors.push(format!("The id \"{id}\" is used twice."));
            }
            let at = order.len();
            order.insert(id, at);
            if kind == "setting" {
                is_setting.insert(id);
            }
            if options.is_empty() {
                errors.push(format!("{kind} \"{id}\" has no options."));
            }
            let mut seen = HashSet::new();
            for v in options {
                if !seen.insert(v) {
                    errors.push(format!("{kind} \"{id}\" lists the option \"{v}\" twice."));
                }
            }
            values.insert(id, seen);
        }

        let check = |cond: Option<&Value>, place: &str, before: Option<usize>, errors: &mut Vec<String>| {
            for (id, literal) in references(cond) {
                let Some(&at) = order.get(id.as_str()) else {
                    errors.push(format!("{place}: \"{id}\" is not an input or a setting."));
                    continue;
                };
                if before.is_some_and(|b| at >= b) {
                    errors.push(format!("{place}: \"{id}\" is decided later and cannot be tested here."));
                }
                if let Some(v) = literal
                    && !values[id.as_str()].contains(v.as_str())
                {
                    errors.push(format!("{place}: \"{id}\" has no option \"{v}\"."));
                }
            }
        };

        for input in &self.inputs {
            let id = &input.id;
            let at = order.get(id.as_str()).copied();
            if input.kind != "choice" && input.kind != "multi" {
                errors.push(format!("input \"{id}\": type must be \"choice\" or \"multi\"."));
            }
            let defaults: Vec<&str> = match &input.default {
                Value::Array(a) => a.iter().filter_map(Value::as_str).collect(),
                Value::String(s) => vec![s.as_str()],
                _ => vec![],
            };
            for d in defaults {
                if !input.options.iter().any(|o| o.value == d) {
                    errors.push(format!("input \"{id}\": the default \"{d}\" is not an option."));
                }
            }
            check(
                input.enabled_when.as_ref(),
                &format!("input \"{id}\" enabledWhen"),
                at,
                &mut errors,
            );
            for o in &input.options {
                let place = format!("input \"{id}\" option \"{}\" enabledWhen", o.value);
                check(o.enabled_when.as_ref(), &place, at, &mut errors);
            }
        }

        let known_level = |l: &str| self.support_levels.is_empty() || self.level(l).is_some();
        for setting in &self.settings {
            let id = &setting.id;
            let at = order.get(id.as_str()).copied();
            check(
                setting.relevant_when.as_ref(),
                &format!("setting \"{id}\" relevantWhen"),
                at,
                &mut errors,
            );
            if setting.options.iter().filter(|o| o.default).count() > 1 {
                errors.push(format!("setting \"{id}\" has more than one default option."));
            }
            for o in &setting.options {
                let place = format!("setting \"{id}\" option \"{}\"", o.value);
                check(o.requires.as_ref(), &format!("{place} requires"), at, &mut errors);
                match &o.support {
                    Some(Value::String(l)) if !known_level(l) => {
                        errors.push(format!("{place}: unknown support level \"{l}\"."));
                    }
                    Some(Value::Array(entries)) => {
                        for e in entries {
                            check(e.get("when"), &format!("{place} support"), at, &mut errors);
                            let l = e.get("level").and_then(Value::as_str).unwrap_or("");
                            if !known_level(l) {
                                errors.push(format!("{place}: unknown support level \"{l}\"."));
                            }
                        }
                    }
                    _ => {}
                }
            }
        }

        let mut rule_ids = HashSet::new();
        for rule in &self.rules {
            let place = format!("rule \"{}\"", rule.id);
            if rule.id.is_empty() {
                errors.push("A rule has no id.".to_string());
            }
            if !rule_ids.insert(rule.id.as_str()) {
                errors.push(format!("The rule id \"{}\" is used twice.", rule.id));
            }
            let targets: Vec<&String> = rule.exclude.keys().chain(rule.score.keys()).collect();
            if targets.is_empty() && rule.warn.is_none() && rule.advice.is_none() {
                errors.push(format!("{place} has no effect."));
            }
            if !targets.is_empty() && rule.because.as_deref().unwrap_or("").is_empty() {
                errors.push(format!("{place} has no \"because\"."));
            }
            let mut first: Option<usize> = None;
            for t in targets {
                if !is_setting.contains(t.as_str()) {
                    errors.push(format!("{place}: \"{t}\" is not a setting."));
                    continue;
                }
                let at = order[t.as_str()];
                first = Some(first.map_or(at, |f| f.min(at)));
                let named = rule
                    .exclude
                    .get(t)
                    .into_iter()
                    .flatten()
                    .chain(rule.score.get(t).into_iter().flat_map(|m| m.keys()));
                for v in named {
                    if !values[t.as_str()].contains(v.as_str()) {
                        errors.push(format!("{place}: \"{t}\" has no option \"{v}\"."));
                    }
                }
            }
            check(Some(&rule.when), &format!("{place} when"), first, &mut errors);
            for (id, v) in &rule.enables {
                if !is_setting.contains(id.as_str()) {
                    errors.push(format!("{place} enables: \"{id}\" is not a setting."));
                } else if !values[id.as_str()].contains(v.as_str()) {
                    errors.push(format!("{place} enables: \"{id}\" has no option \"{v}\"."));
                }
            }
        }
        errors
    }
}

/// Every text of the model file that a user can see, with where it is used.
/// Each text is listed once, at its first use.
pub fn strings(model: &Value) -> Vec<(String, String)> {
    let mut out: Vec<(String, String)> = Vec::new();
    let mut seen = HashSet::new();
    let mut add = |text: Option<&Value>, place: String| {
        if let Some(t) = text.and_then(Value::as_str)
            && !t.is_empty()
            && seen.insert(t.to_string())
        {
            out.push((t.to_string(), place));
        }
    };
    let list = |key: &str| model.get(key).and_then(Value::as_array).cloned().unwrap_or_default();
    let id = |v: &Value| {
        v.get("id")
            .or_else(|| v.get("value"))
            .and_then(Value::as_str)
            .unwrap_or("")
            .to_string()
    };

    for level in list("supportLevels") {
        add(level.get("label"), format!("support level {}", id(&level)));
    }
    for (groups, kind) in [("inputGroups", "question group"), ("settingGroups", "setting group")] {
        for group in list(groups) {
            add(group.get("label"), format!("{kind} {}", id(&group)));
        }
    }
    for input in list("inputs") {
        let name = id(&input);
        add(input.get("label"), format!("question {name}"));
        add(input.get("help"), format!("question {name}, help"));
        add(input.get("disabledNote"), format!("question {name}, why it is off"));
        for o in input.get("options").and_then(Value::as_array).into_iter().flatten() {
            let option = id(o);
            add(o.get("label"), format!("question {name}, answer {option}"));
            add(o.get("help"), format!("question {name}, answer {option}, help"));
            add(
                o.get("disabledNote"),
                format!("question {name}, answer {option}, why it is off"),
            );
        }
    }
    for preset in list("presets") {
        add(preset.get("label"), format!("preset {}", id(&preset)));
    }
    for setting in list("settings") {
        let name = id(&setting);
        add(setting.get("label"), format!("setting {name}"));
        add(setting.get("help"), format!("setting {name}, help"));
        for o in setting.get("options").and_then(Value::as_array).into_iter().flatten() {
            let option = id(o);
            add(o.get("label"), format!("setting {name}, option {option}"));
            add(o.get("help"), format!("setting {name}, option {option}, help"));
            add(
                o.get("requiresNote"),
                format!("setting {name}, option {option}, why it is impossible"),
            );
            add(
                o.get("supportNote"),
                format!("setting {name}, option {option}, support"),
            );
            add(
                o.get("how"),
                format!("setting {name}, option {option}, how to select it"),
            );
            for e in o.get("support").and_then(Value::as_array).into_iter().flatten() {
                add(e.get("note"), format!("setting {name}, option {option}, support"));
            }
        }
    }
    for rule in list("rules") {
        let name = id(&rule);
        add(rule.get("because"), format!("rule {name}, reason"));
        add(rule.get("warn"), format!("rule {name}, warning"));
        add(rule.get("advice"), format!("rule {name}, tip"));
    }
    out
}

/// A C++ source that names every text of the model to Qt's `lupdate`, in the
/// context `FMIGuide`. A Qt client shows a text with
/// `QCoreApplication::translate("FMIGuide", text)`.
pub fn qt_translation_source(model: &Value) -> String {
    let mut out = String::from(
        "// Generated from fmi-settings.json. Do not edit. To update it, run in\n\
         // OMCompiler/Compiler/runtime/rust:\n\
         //   FMI_GUIDE_WRITE_TEXTS=1 cargo test -p openmodelica_fmi_guide\n\
         // lupdate reads the texts of the FMI settings guide from here.\n\
         #include <QtGlobal>\n\nQ_DECL_UNUSED static const char *const fmiGuideTexts[] = {\n",
    );
    for (text, place) in strings(model) {
        let text = text.replace('\\', "\\\\").replace('"', "\\\"").replace('\n', "\\n");
        out.push_str(&format!(
            "  //: {place}\n  QT_TRANSLATE_NOOP(\"FMIGuide\", \"{text}\"),\n"
        ));
    }
    out.push_str("};\n");
    out
}
