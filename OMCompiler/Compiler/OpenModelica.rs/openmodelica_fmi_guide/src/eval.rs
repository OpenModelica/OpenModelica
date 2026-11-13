//! Decides the settings for a set of answers.

use std::cmp::Ordering;
use std::collections::{BTreeMap, HashMap, HashSet};

use serde::Deserialize;
use serde_json::{Map, Value, json};

use crate::model::{Input, Model, Rule, Setting, SettingOption};

/// The value of an input or a setting. An input that is off and a setting that
/// is not relevant have none.
#[derive(Clone, Debug, PartialEq)]
pub enum Val {
    None,
    One(String),
    Many(Vec<String>),
}

impl Val {
    fn json(&self) -> Value {
        match self {
            Val::None => Value::Null,
            Val::One(s) => json!(s),
            Val::Many(v) => json!(v),
        }
    }
}

pub type Values = HashMap<String, Val>;

#[derive(Clone, Copy, PartialEq)]
pub enum Mode {
    /// The best option that the tool has.
    Today,
    /// The best option, also when the tool does not have it.
    Ideal,
}

/// A user interface that can produce only some options.
#[derive(Deserialize, Default)]
pub struct Host {
    #[serde(default)]
    pub name: String,
    /// Per setting, the options the host can produce. A setting that is not
    /// listed has all of them.
    #[serde(default)]
    pub offers: BTreeMap<String, Vec<String>>,
    /// The settings the host has controls for.
    #[serde(default)]
    pub applies: Vec<String>,
}

fn offered(host: Option<&Host>, setting: &str, value: &str) -> bool {
    host.and_then(|h| h.offers.get(setting))
        .is_none_or(|o| o.iter().any(|v| v == value))
}

fn test(value: &Val, t: &Value) -> bool {
    match (value, t) {
        (Val::None, _) => false,
        (_, Value::Array(items)) => items.iter().any(|x| test(value, x)),
        (_, Value::Object(o)) => {
            if let Some(lacks) = o.get("lacks").and_then(Value::as_str) {
                match value {
                    Val::Many(v) => !v.is_empty() && !v.iter().any(|x| x == lacks),
                    Val::One(s) => s != "unknown" && s != lacks,
                    Val::None => false,
                }
            } else if let Some(want) = o.get("unknown") {
                let unknown = match value {
                    Val::Many(v) => v.is_empty(),
                    Val::One(s) => s == "unknown",
                    Val::None => false,
                };
                want.as_bool() == Some(unknown)
            } else if let Some(inner) = o.get("not") {
                !test(value, inner)
            } else {
                false
            }
        }
        (Val::Many(v), Value::String(s)) => v.iter().any(|x| x == s),
        (Val::One(x), Value::String(s)) => x == s,
        _ => false,
    }
}

pub fn holds(cond: Option<&Value>, values: &Values) -> bool {
    let Some(Value::Object(cond)) = cond else { return true };
    cond.iter().all(|(key, t)| match key.as_str() {
        k if k.starts_with("//") => true,
        "any" => t.as_array().is_some_and(|a| a.iter().any(|c| holds(Some(c), values))),
        "all" => t.as_array().is_some_and(|a| a.iter().all(|c| holds(Some(c), values))),
        "not" => !holds(Some(t), values),
        _ => values.get(key).is_some_and(|v| test(v, t)),
    })
}

/// Every `(id, literal)` that a condition tests. A test without a literal,
/// such as `{ "unknown": true }`, gives `None`.
pub fn references(cond: Option<&Value>) -> Vec<(String, Option<String>)> {
    fn literals(t: &Value, out: &mut Vec<Option<String>>) {
        match t {
            Value::Array(items) => items.iter().for_each(|x| literals(x, out)),
            Value::Object(o) => {
                if let Some(l) = o.get("lacks") {
                    out.push(l.as_str().map(String::from));
                } else if let Some(n) = o.get("not") {
                    literals(n, out);
                } else {
                    out.push(None);
                }
            }
            other => out.push(other.as_str().map(String::from)),
        }
    }
    fn walk(cond: &Value, out: &mut Vec<(String, Option<String>)>) {
        let Value::Object(cond) = cond else { return };
        for (key, t) in cond {
            match key.as_str() {
                k if k.starts_with("//") => {}
                "any" | "all" => t.as_array().into_iter().flatten().for_each(|c| walk(c, out)),
                "not" => walk(t, out),
                _ => {
                    let mut found = Vec::new();
                    literals(t, &mut found);
                    out.extend(found.into_iter().map(|l| (key.clone(), l)));
                }
            }
        }
    }
    let mut out = Vec::new();
    if let Some(cond) = cond {
        walk(cond, &mut out);
    }
    out
}

fn referenced_ids(cond: Option<&Value>) -> Vec<String> {
    let mut seen = HashSet::new();
    references(cond)
        .into_iter()
        .map(|(id, _)| id)
        .filter(|id| seen.insert(id.clone()))
        .collect()
}

pub struct Support {
    pub level: String,
    pub label: String,
    pub available: bool,
    pub note: String,
    /// False when the host cannot produce the option.
    pub offered: bool,
}

fn level_available(model: &Model, level: &str) -> bool {
    model.level(level).map_or(level != "no", |l| l.available)
}

fn support_of(
    model: &Model,
    setting: &Setting,
    option: &SettingOption,
    values: &Values,
    host: Option<&Host>,
) -> Support {
    if !offered(host, &setting.id, &option.value) {
        let name = host
            .map(|h| h.name.as_str())
            .filter(|n| !n.is_empty())
            .unwrap_or("this tool");
        return Support {
            level: "no".into(),
            label: "Not here".into(),
            available: false,
            note: format!("Not available in {name}."),
            offered: false,
        };
    }
    let mut level = "yes".to_string();
    let mut note = option.support_note.clone().unwrap_or_default();
    match &option.support {
        Some(Value::String(l)) => level = l.clone(),
        Some(Value::Array(entries)) => {
            let entry = entries.iter().find(|e| holds(e.get("when"), values));
            level = entry
                .and_then(|e| e.get("level"))
                .and_then(Value::as_str)
                .unwrap_or("no")
                .to_string();
            if let Some(n) = entry
                .and_then(|e| e.get("note"))
                .and_then(Value::as_str)
                .filter(|n| !n.is_empty())
            {
                note = n.to_string();
            }
        }
        _ => {}
    }
    let label = model.level(&level).map_or_else(|| level.clone(), |l| l.label.clone());
    let available = level_available(model, &level);
    Support {
        level,
        label,
        available,
        note,
        offered: true,
    }
}

/// True when some case exists in which the tool has this option.
fn can_be_available(model: &Model, setting: &str, value: &str, host: Option<&Host>) -> bool {
    let Some(option) = model
        .setting(setting)
        .and_then(|s| s.options.iter().find(|o| o.value == value))
    else {
        return false;
    };
    if !offered(host, setting, value) {
        return false;
    }
    match &option.support {
        Some(Value::String(l)) => level_available(model, l),
        Some(Value::Array(entries)) => entries
            .iter()
            .any(|e| level_available(model, e.get("level").and_then(Value::as_str).unwrap_or("no"))),
        _ => true,
    }
}

pub struct Reason<'a> {
    pub rule: &'a Rule,
    pub points: i64,
}

pub struct OptionResult<'a> {
    pub option: &'a SettingOption,
    index: usize,
    pub score: i64,
    pub reasons: Vec<Reason<'a>>,
    pub excluded_by: Vec<&'a Rule>,
    /// Why the option is impossible with the choices made before it.
    pub unavailable: Option<String>,
    pub support: Support,
}

/// Highest score first; then the default, then what the tool has, then file order.
fn by_rank(a: &OptionResult, b: &OptionResult) -> Ordering {
    b.score
        .cmp(&a.score)
        .then(b.option.default.cmp(&a.option.default))
        .then(b.support.available.cmp(&a.support.available))
        .then(a.index.cmp(&b.index))
}

pub struct SettingResult<'a> {
    pub setting: &'a Setting,
    pub relevant: bool,
    pub options: Vec<OptionResult<'a>>,
    /// Indexes into `options` of those that are possible and not ruled out, best first.
    pub ranked: Vec<usize>,
    pub ideal: Option<usize>,
    pub today: Option<usize>,
    pub pick: Option<usize>,
    /// Options that would rank before the pick, but a rule excludes them.
    pub displaced: Vec<usize>,
}

impl<'a> SettingResult<'a> {
    pub fn picked(&self) -> Option<&OptionResult<'a>> {
        self.pick.map(|i| &self.options[i])
    }

    pub fn blocked(&self) -> bool {
        self.relevant && self.pick.is_none()
    }
}

pub struct InputResult<'a> {
    pub input: &'a Input,
    pub enabled: bool,
    pub value: Val,
    pub options: Vec<(&'a str, bool)>,
}

pub struct Note<'a> {
    pub warn: bool,
    pub text: &'a str,
    pub rule: &'a Rule,
}

pub struct Evaluation<'a> {
    pub values: Values,
    pub inputs: Vec<InputResult<'a>>,
    pub settings: Vec<SettingResult<'a>>,
    pub notes: Vec<Note<'a>>,
}

pub fn evaluate<'a>(model: &'a Model, answers: &Map<String, Value>, mode: Mode, host: Option<&Host>) -> Evaluation<'a> {
    let mut values = Values::new();

    let mut inputs = Vec::new();
    for input in &model.inputs {
        let enabled = holds(input.enabled_when.as_ref(), &values);
        let mut options = Vec::new();
        let mut value = Val::None;
        if enabled {
            for o in &input.options {
                options.push((o.value.as_str(), holds(o.enabled_when.as_ref(), &values)));
            }
            let on = |v: &str| options.iter().any(|(k, enabled)| *k == v && *enabled);
            let raw = answers.get(&input.id).unwrap_or(&input.default);
            value = if input.kind == "multi" {
                let chosen = raw.as_array().into_iter().flatten().filter_map(Value::as_str);
                Val::Many(chosen.filter(|v| on(v)).map(String::from).collect())
            } else {
                match raw.as_str().filter(|v| on(v)).or(input.default.as_str()) {
                    Some(v) => Val::One(v.to_string()),
                    None => Val::None,
                }
            };
        }
        values.insert(input.id.clone(), value.clone());
        inputs.push(InputResult {
            input,
            enabled,
            value,
            options,
        });
    }

    let pointless =
        |rule: &Rule| mode == Mode::Today && !rule.enables.iter().all(|(id, v)| can_be_available(model, id, v, host));

    let mut settings = Vec::new();
    for setting in &model.settings {
        if !holds(setting.relevant_when.as_ref(), &values) {
            values.insert(setting.id.clone(), Val::None);
            settings.push(SettingResult {
                setting,
                relevant: false,
                options: vec![],
                ranked: vec![],
                ideal: None,
                today: None,
                pick: None,
                displaced: vec![],
            });
            continue;
        }
        let mut options: Vec<OptionResult> = setting
            .options
            .iter()
            .enumerate()
            .map(|(index, option)| OptionResult {
                option,
                index,
                score: 0,
                reasons: vec![],
                excluded_by: vec![],
                unavailable: (!holds(option.requires.as_ref(), &values)).then(|| {
                    option
                        .requires_note
                        .clone()
                        .unwrap_or_else(|| "Not possible with the settings above.".into())
                }),
                support: support_of(model, setting, option, &values, host),
            })
            .collect();

        for rule in &model.rules {
            let excluded = rule.exclude.get(&setting.id);
            let scored = rule.score.get(&setting.id);
            if (excluded.is_none() && scored.is_none()) || pointless(rule) || !holds(Some(&rule.when), &values) {
                continue;
            }
            for o in options.iter_mut() {
                if excluded.is_some_and(|x| x.contains(&o.option.value)) {
                    o.excluded_by.push(rule);
                }
                if let Some(&points) = scored.and_then(|s| s.get(&o.option.value)) {
                    o.score += points;
                    o.reasons.push(Reason { rule, points });
                }
            }
        }

        let mut ranked: Vec<usize> = (0..options.len())
            .filter(|&i| options[i].unavailable.is_none() && options[i].excluded_by.is_empty())
            .collect();
        ranked.sort_by(|&a, &b| by_rank(&options[a], &options[b]));
        let ideal = ranked.first().copied();
        let today = ranked.iter().copied().find(|&i| options[i].support.available);
        let pick = if mode == Mode::Ideal { ideal } else { today };
        let displaced = match pick {
            Some(p) => (0..options.len())
                .filter(|&i| {
                    let o = &options[i];
                    o.unavailable.is_none() && !o.excluded_by.is_empty() && by_rank(o, &options[p]) == Ordering::Less
                })
                .collect(),
            None => vec![],
        };
        let value = pick
            .or(ideal)
            .map_or(Val::None, |i| Val::One(options[i].option.value.clone()));
        values.insert(setting.id.clone(), value);
        settings.push(SettingResult {
            setting,
            relevant: true,
            options,
            ranked,
            ideal,
            today,
            pick,
            displaced,
        });
    }

    let mut notes = Vec::new();
    for rule in &model.rules {
        if (rule.warn.is_none() && rule.advice.is_none()) || !holds(Some(&rule.when), &values) {
            continue;
        }
        if let Some(text) = &rule.warn {
            notes.push(Note { warn: true, text, rule });
        }
        if let Some(text) = &rule.advice {
            notes.push(Note {
                warn: false,
                text,
                rule,
            });
        }
    }

    Evaluation {
        values,
        inputs,
        settings,
        notes,
    }
}

pub struct Gap<'a> {
    pub setting: &'a Setting,
    pub ideal: &'a SettingOption,
    pub today: Option<&'a SettingOption>,
}

pub struct Advice<'a> {
    pub today: Evaluation<'a>,
    pub ideal: Evaluation<'a>,
    /// What the ideal FMU uses that the tool does not have.
    pub gaps: Vec<Gap<'a>>,
}

pub fn advise<'a>(model: &'a Model, answers: &Map<String, Value>, host: Option<&Host>) -> Advice<'a> {
    let today = evaluate(model, answers, Mode::Today, host);
    let ideal = evaluate(model, answers, Mode::Ideal, host);
    let mut gaps = Vec::new();
    for (i, t) in ideal.settings.iter().zip(&today.settings) {
        if let Some(pick) = i.picked().filter(|p| !p.support.available) {
            gaps.push(Gap {
                setting: i.setting,
                ideal: pick.option,
                today: t.picked().map(|p| p.option),
            });
        }
    }
    Advice { today, ideal, gaps }
}

/// The omc script for the picks that the tool can produce.
pub fn script(model: &Model, result: &Evaluation, model_name: &str) -> String {
    let blocked: Vec<&str> = result
        .settings
        .iter()
        .filter(|s| s.blocked())
        .map(|s| s.setting.label.as_str())
        .collect();
    if !blocked.is_empty() {
        return format!(
            "// No export is possible: nothing is left to choose for {}.",
            blocked.join(", ")
        );
    }
    let mut args: Vec<(&str, &str)> = Vec::new();
    let mut flags: Vec<&str> = Vec::new();
    let mut fmi_flags: Vec<&str> = Vec::new();
    let mut missing = Vec::new();
    for s in &result.settings {
        let Some(pick) = s.picked() else { continue };
        if !pick.support.available {
            missing.push(format!("{}: {}", s.setting.label, pick.option.label));
            continue;
        }
        let Some(omc) = pick
            .option
            .omc
            .as_ref()
            .filter(|_| s.setting.explicit || !pick.option.default)
        else {
            continue;
        };
        for (k, v) in &omc.args {
            match args.iter_mut().find(|(name, _)| name == k) {
                Some(entry) => entry.1 = v,
                None => args.push((k, v)),
            }
        }
        flags.extend(omc.flags.iter().map(String::as_str));
        fmi_flags.extend(omc.fmi_flags.iter().map(String::as_str));
    }
    let mut lines = Vec::new();
    let fmi = format!("--fmiFlags={}", fmi_flags.join(","));
    if !fmi_flags.is_empty() {
        flags.insert(0, &fmi);
    }
    if !flags.is_empty() {
        lines.push(format!(
            "setCommandLineOptions(\"{}\"); getErrorString();",
            flags.join(" ")
        ));
    }
    let args: String = args.iter().map(|(k, v)| format!(", {k}={v}")).collect();
    lines.push(format!("buildModelFMU({model_name}{args}); getErrorString();"));
    let tool = model.tool.as_deref().unwrap_or("the tool");
    lines.extend(missing.iter().map(|m| format!("// Not in {tool} yet: {m}")));
    lines.join("\n")
}

/// The inputs that can change one of the given settings, directly or through
/// another setting. A setting of which the host offers one option is decided:
/// only a rule that excludes that option still matters for it.
pub fn relevant_inputs<'a>(model: &'a Model, settings: &[String], host: Option<&Host>) -> Vec<&'a str> {
    let mut seen: HashSet<String> = settings.iter().cloned().collect();
    let mut used: HashSet<&str> = HashSet::new();
    let mut queue: Vec<String> = settings.to_vec();
    let mut pending: Vec<String> = Vec::new();
    while let Some(id) = queue.pop() {
        if let Some(setting) = model.setting(&id) {
            let only = host
                .and_then(|h| h.offers.get(&id))
                .filter(|o| o.len() == 1)
                .map(|o| o[0].as_str());
            pending.extend(referenced_ids(setting.relevant_when.as_ref()));
            for o in &setting.options {
                if only.is_some_and(|v| v != o.value) {
                    continue;
                }
                pending.extend(referenced_ids(o.requires.as_ref()));
                if let Some(Value::Array(entries)) = &o.support {
                    entries
                        .iter()
                        .for_each(|e| pending.extend(referenced_ids(e.get("when"))));
                }
            }
            for rule in &model.rules {
                let excluded = rule.exclude.get(&id);
                let matters = match only {
                    Some(v) => excluded.is_some_and(|x| x.iter().any(|e| e == v)),
                    None => excluded.is_some() || rule.score.contains_key(&id),
                };
                if matters {
                    pending.extend(referenced_ids(Some(&rule.when)));
                }
            }
        } else if let Some(input) = model.inputs.iter().find(|i| i.id == id) {
            used.insert(input.id.as_str());
            pending.extend(referenced_ids(input.enabled_when.as_ref()));
            input
                .options
                .iter()
                .for_each(|o| pending.extend(referenced_ids(o.enabled_when.as_ref())));
        }
        for next in pending.drain(..) {
            if seen.insert(next.clone()) {
                queue.push(next);
            }
        }
    }
    model
        .inputs
        .iter()
        .map(|i| i.id.as_str())
        .filter(|id| used.contains(id))
        .collect()
}

fn option_json(o: &OptionResult) -> Value {
    json!({
        "value": o.option.value,
        "score": o.score,
        "unavailable": o.unavailable,
        "support": {
            "level": o.support.level, "label": o.support.label, "available": o.support.available,
            "note": o.support.note, "offered": o.support.offered,
        },
        "reasons": o.reasons.iter().map(|r| json!({
            "rule": r.rule.id, "because": r.rule.because.as_deref().unwrap_or(""), "points": r.points,
        })).collect::<Vec<_>>(),
        "excludedBy": o.excluded_by.iter().map(|r| json!({
            "rule": r.id, "because": r.because.as_deref().unwrap_or(""),
        })).collect::<Vec<_>>(),
    })
}

impl Evaluation<'_> {
    pub fn json(&self) -> Value {
        let value_of = |s: &SettingResult, i: Option<usize>| i.map(|i| s.options[i].option.value.clone());
        json!({
            "values": self.values.iter().map(|(k, v)| (k.clone(), v.json())).collect::<Map<_, _>>(),
            "inputs": self.inputs.iter().map(|i| (i.input.id.clone(), json!({
                "enabled": i.enabled,
                "value": i.value.json(),
                "options": i.options.iter().map(|(k, on)| (k.to_string(), json!(on))).collect::<Map<_, _>>(),
            }))).collect::<Map<_, _>>(),
            "settings": self.settings.iter().map(|s| if s.relevant {
                json!({
                    "id": s.setting.id,
                    "relevant": true,
                    "pick": value_of(s, s.pick),
                    "ideal": value_of(s, s.ideal),
                    "today": value_of(s, s.today),
                    "blocked": s.blocked(),
                    "ranked": s.ranked.iter().map(|&i| s.options[i].option.value.as_str()).collect::<Vec<_>>(),
                    "displaced": s.displaced.iter().map(|&i| s.options[i].option.value.as_str()).collect::<Vec<_>>(),
                    "options": s.options.iter().map(option_json).collect::<Vec<_>>(),
                })
            } else {
                json!({ "id": s.setting.id, "relevant": false })
            }).collect::<Vec<_>>(),
            "notes": self.notes.iter().map(|n| json!({
                "level": if n.warn { "warn" } else { "advice" }, "text": n.text, "rule": n.rule.id,
            })).collect::<Vec<_>>(),
        })
    }
}
