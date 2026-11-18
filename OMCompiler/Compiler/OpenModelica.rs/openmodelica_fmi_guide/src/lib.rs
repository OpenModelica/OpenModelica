//! The FMI settings guide: from what a user knows about the use of an FMU to
//! the export settings that fit. The questions, the settings and the rules
//! between them are data (`fmi-settings.json`, see README.md); this crate
//! evaluates them. [`call`] is the interface for the clients: JSON in, JSON out.

mod eval;
mod model;

use serde_json::{Map, Value, json};

pub use eval::{Advice, Evaluation, Host, Mode, advise, evaluate, relevant_inputs, script};
pub use model::{Model, qt_translation_source, strings};

/// The model file that is built in.
pub const MODEL_JSON: &str = include_str!("../fmi-settings.json");

fn error(message: impl std::fmt::Display) -> String {
    json!({ "ok": false, "error": message.to_string() }).to_string()
}

/// Answers a JSON request with JSON. `op` selects what:
///
/// - `model`: the model file, for a client that shows the questions.
/// - `advise`: the settings for `answers` (input id to value, or list of
///   values). Optional: `host` (see [`Host`]) and `modelName` for the script.
/// - `validate`: the mistakes in the model.
/// - `strings`: every text a user can see, for translation.
///
/// Each request can carry its own `model` in place of the built-in one.
pub fn call(request: &str) -> String {
    let request: Value = match serde_json::from_str(request) {
        Ok(v) => v,
        Err(e) => return error(e),
    };
    let raw: Value = match request.get("model") {
        Some(m) => m.clone(),
        None => serde_json::from_str(MODEL_JSON).expect("the built-in model is JSON"),
    };
    let op = request.get("op").and_then(Value::as_str).unwrap_or("");
    match op {
        "model" => return json!({ "ok": true, "model": raw }).to_string(),
        "strings" => {
            let list: Vec<Value> = strings(&raw)
                .into_iter()
                .map(|(text, place)| json!({ "text": text, "where": place }))
                .collect();
            return json!({ "ok": true, "strings": list }).to_string();
        }
        "advise" | "validate" => {}
        other => return error(format!("unknown op \"{other}\"")),
    }
    let model: Model = match serde_json::from_value(raw) {
        Ok(m) => m,
        Err(e) => return error(e),
    };
    let errors = model.validate();
    if op == "validate" {
        return json!({ "ok": true, "errors": errors }).to_string();
    }
    if let Some(first) = errors.first() {
        return error(first);
    }
    let host: Option<Host> = match request.get("host").filter(|h| !h.is_null()) {
        Some(h) => match serde_json::from_value(h.clone()) {
            Ok(h) => Some(h),
            Err(e) => return error(e),
        },
        None => None,
    };
    let empty = Map::new();
    let answers = request.get("answers").and_then(Value::as_object).unwrap_or(&empty);
    let name = request.get("modelName").and_then(Value::as_str).unwrap_or("MyModel");

    let advice = advise(&model, answers, host.as_ref());
    let asked: Vec<&str> = match &host {
        Some(h) if !h.applies.is_empty() => relevant_inputs(&model, &h.applies, Some(h)),
        _ => model.inputs.iter().map(|i| i.id.as_str()).collect(),
    };
    json!({
        "ok": true,
        "today": advice.today.json(),
        "ideal": advice.ideal.json(),
        "gaps": advice.gaps.iter().map(|g| json!({
            "setting": g.setting.id, "ideal": g.ideal.value, "today": g.today.map(|o| o.value.as_str()),
        })).collect::<Vec<_>>(),
        "script": { "today": script(&model, &advice.today, name), "ideal": script(&model, &advice.ideal, name) },
        "asked": asked,
    })
    .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ask(request: Value) -> Value {
        serde_json::from_str(&call(&request.to_string())).unwrap()
    }

    fn pick<'a>(reply: &'a Value, mode: &str, setting: &str) -> &'a Value {
        let settings = reply[mode]["settings"].as_array().unwrap();
        &settings.iter().find(|s| s["id"] == setting).unwrap()["pick"]
    }

    #[test]
    fn built_in_model_is_sound() {
        assert_eq!(ask(json!({ "op": "validate" }))["errors"], json!([]));
    }

    #[test]
    fn defaults_keep_both_interfaces() {
        let reply = ask(json!({ "op": "advise" }));
        assert_eq!(pick(&reply, "today", "fmiVersion"), "2.0");
        assert_eq!(pick(&reply, "today", "fmiType"), "me_cs");
        assert_eq!(reply["gaps"], json!([]));
    }

    #[test]
    fn a_missing_solver_is_a_gap() {
        let reply = ask(json!({ "op": "advise", "answers": { "realtime": "hard", "stiffModel": "yes" } }));
        assert_eq!(pick(&reply, "today", "csSolver"), "cvode");
        assert_eq!(pick(&reply, "ideal", "csSolver"), "rosenbrock");
        let gap = json!({ "setting": "csSolver", "ideal": "rosenbrock", "today": "cvode" });
        assert!(reply["gaps"].as_array().unwrap().contains(&gap));
    }

    #[test]
    fn a_host_gets_only_what_it_offers() {
        let host = json!({ "name": "the Simulator", "offers": { "fmiVersion": ["3.0"], "csSolver": ["dassl", "euler"] },
                           "applies": ["fmiType", "csSolver"] });
        let reply = ask(json!({ "op": "advise", "host": host }));
        assert_eq!(pick(&reply, "today", "fmiVersion"), "3.0");
        assert_eq!(pick(&reply, "today", "csSolver"), "dassl");
        assert!(!reply["asked"].as_array().unwrap().contains(&json!("ip")));

        let reply = ask(json!({ "op": "advise", "host": host, "answers": { "importerVersions": ["2.0"] } }));
        assert_eq!(pick(&reply, "today", "fmiVersion"), &Value::Null);
    }

    #[test]
    fn a_mistake_in_the_model_is_named() {
        let mut model: Value = serde_json::from_str(MODEL_JSON).unwrap();
        model["rules"][0]["exclude"]["interface"] = json!(["bogus"]);
        let reply = ask(json!({ "op": "validate", "model": model }));
        assert_eq!(
            reply["errors"],
            json!(["rule \"importer-lacks-me\": \"interface\" has no option \"bogus\"."])
        );
    }

    #[test]
    fn qt_source_escapes_quotes() {
        let source = qt_translation_source(&json!({ "rules": [{ "id": "r", "because": "Say \"no\"." }] }));
        assert!(source.contains("  //: rule r, reason\n  QT_TRANSLATE_NOOP(\"FMIGuide\", \"Say \\\"no\\\".\"),\n"));
    }

    #[test]
    fn the_texts_for_omedit_are_current() {
        let file = concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/../../../../OMEdit/OMEditLIB/FMI/FMIGuideTexts.cpp"
        );
        let source = qt_translation_source(&serde_json::from_str(MODEL_JSON).unwrap());
        if std::env::var_os("FMI_GUIDE_WRITE_TEXTS").is_some() {
            std::fs::write(file, &source).unwrap();
        }
        // The working copy of a build has no OMEdit.
        let Ok(texts) = std::fs::read_to_string(file) else {
            return;
        };
        assert!(texts == source, "FMIGuideTexts.cpp is out of date, see its first lines");
    }

    #[test]
    fn each_text_is_listed_once() {
        let reply = ask(json!({ "op": "strings" }));
        let texts: Vec<&str> = reply["strings"]
            .as_array()
            .unwrap()
            .iter()
            .map(|s| s["text"].as_str().unwrap())
            .collect();
        assert!(texts.contains(&"Is this model stiff?"));
        let unique: std::collections::HashSet<&&str> = texts.iter().collect();
        assert_eq!(unique.len(), texts.len());
    }
}
