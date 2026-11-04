//! `<prefix>_init.bin`, read by `openmodelica_init_file`, as the attribute maps
//! [`InitXml`] that `model_data` consumes.

use std::collections::HashMap;

use omc_init::{self as init, Dimension, InitFile};

use crate::model_data::{InitXml, XmlVar};

pub fn convert(f: InitFile) -> InitXml {
    let m = &f.model;
    let mut md: HashMap<String, String> = [
        ("modelName", &m.name),
        ("modelIdentifier", &m.identifier),
        ("description", &m.description),
        ("guid", &m.guid),
        ("generationTool", &m.generation_tool),
        ("generationDateAndTime", &m.generation_date_and_time),
        ("OPENMODELICAHOME", &m.omhome),
    ]
    .into_iter()
    .map(|(k, v)| (k.to_string(), v.clone()))
    .collect();
    for (name, count) in init::COUNT_NAMES.iter().zip(m.counts) {
        md.insert(name.to_string(), count.to_string());
    }

    let e = &f.experiment;
    let experiment: HashMap<String, String> = [
        ("startTime", format!("{:?}", e.start_time)),
        ("stopTime", format!("{:?}", e.stop_time)),
        ("stepSize", format!("{:?}", e.step_size)),
        ("tolerance", format!("{:?}", e.tolerance)),
        ("solver", e.solver.clone()),
        ("outputFormat", e.output_format.clone()),
        ("variableFilter", e.variable_filter.clone()),
    ]
    .into_iter()
    .map(|(k, v)| (k.to_string(), v))
    .collect();

    let enumerations = f.enumerations.into_iter().map(|en| (en.name, en.literals)).collect();

    let mut groups: HashMap<String, Vec<Option<XmlVar>>> = HashMap::new();
    for v in f.variables {
        let flag = |f: u16| (if v.has(f) { "true" } else { "false" }).to_string();
        let mut a: HashMap<String, String> = HashMap::new();
        if !v.description.is_empty() {
            a.insert("description".into(), v.description.clone());
        }
        a.insert("fileName".into(), v.file_name.clone());
        if !v.unit.is_empty() {
            a.insert("unit".into(), v.unit.clone());
        }
        if !v.display_unit.is_empty() {
            a.insert("displayUnit".into(), v.display_unit.clone());
        }
        if v.base_type == init::ENUMERATION {
            a.insert("declaredType".into(), v.declared_type.clone());
        }
        a.insert("valueReference".into(), v.value_reference.to_string());
        a.insert(
            "alias".into(),
            ["noAlias", "alias", "negatedAlias"][v.alias as usize].into(),
        );
        if v.alias != init::NO_ALIAS {
            a.insert("aliasVariable".into(), v.alias_variable.clone());
        }
        if v.input_index != -1 {
            a.insert("inputIndex".into(), v.input_index.to_string());
        }
        let class_index = v.class_index.max(0) as usize;
        let class = init::CLASS_TYPES[v.class_type as usize];
        a.insert("classIndex".into(), class_index.to_string());
        a.insert("classType".into(), class.into());
        for (key, n) in [
            ("startLine", v.start_line),
            ("startColumn", v.start_column),
            ("endLine", v.end_line),
            ("endColumn", v.end_column),
        ] {
            a.insert(key.into(), n.to_string());
        }
        a.insert("variability".into(), init::VARIABILITY[v.variability as usize].into());
        a.insert("causality".into(), init::CAUSALITY[v.causality as usize].into());
        a.insert(
            "hideResult".into(),
            ["", "false", "true"][v.hide_result as usize].into(),
        );
        a.insert("isDiscrete".into(), flag(init::DISCRETE));
        a.insert("isValueChangeable".into(), flag(init::VALUE_CHANGEABLE));
        a.insert("isProtected".into(), flag(init::PROTECTED));
        a.insert("isEncrypted".into(), flag(init::ENCRYPTED));
        a.insert("initNonlinear".into(), flag(init::INIT_NONLINEAR));
        a.insert("fileWritable".into(), flag(init::FILE_WRITABLE));
        if v.base_type != init::EXTERNAL_OBJECT {
            a.insert("fixed".into(), flag(init::FIXED));
        }
        if v.base_type == init::REAL {
            a.insert("useNominal".into(), flag(init::USE_NOMINAL));
            if v.has(init::RELATIVE_QUANTITY) {
                a.insert("relativeQuantity".into(), "true".into());
            }
        }
        for (i, d) in v.dimensions.iter().enumerate() {
            match d {
                Dimension::Size(n) => a.insert(format!("dim-{}-start", i + 1), n.to_string()),
                Dimension::ValueReference(vr) => a.insert(format!("dim-{}-valueReference", i + 1), vr.to_string()),
            };
        }
        if !v.dimensions.is_empty() {
            a.insert("num_dimensions".into(), v.dimensions.len().to_string());
        }
        let is_array = v.has(init::ARRAY);
        for (key, values) in [
            ("start", &v.start),
            ("min", &v.min),
            ("max", &v.max),
            ("nominal", &v.nominal),
        ] {
            if !values.is_empty() {
                a.insert(key.into(), init::values_plain_text(values, is_array));
            }
        }
        a.insert("name".into(), v.name);
        let slot = groups.entry(class.to_string()).or_default();
        if slot.len() <= class_index {
            slot.resize_with(class_index + 1, || None);
        }
        slot[class_index] = Some(XmlVar { attrs: a });
    }
    InitXml {
        groups,
        md,
        experiment,
        enumerations,
    }
}
