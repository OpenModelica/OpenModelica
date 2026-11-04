//! Reads `<prefix>_init.bin`, the variables and default experiment of a model
//! that omc writes (`Compiler/SimCode/SerializeInitBin.mo`). The format is
//! described in `include/omc_init_file.h`; the C simulation runtime has its own
//! reader (`c/util/omc_init_bin.c`) because C FMUs are built from C sources.

mod capi;

use std::fmt::Write;

pub const VERSION: u32 = 1;
const STRINGS: u32 = 1;
const MODEL: u32 = 2;
const EXPERIMENT: u32 = 3;
const ENUMERATIONS: u32 = 4;
const VARIABLES: u32 = 5;
const REALS: u32 = 6;
const INTEGERS: u32 = 7;

pub const CLASS_TYPES: [&str; 15] = [
    "rSta", "rDer", "rAlg", "rPar", "rAli", "iAlg", "iPar", "iAli", "bAlg", "bPar", "bAli", "sAlg", "sPar", "sAli",
    "rSen",
];
pub const BASE_TYPES: [&str; 6] = ["Real", "Integer", "Boolean", "String", "Enumeration", "ExternalObject"];
pub const VARIABILITY: [&str; 4] = ["continuous", "discrete", "parameter", "constant"];
pub const CAUSALITY: [&str; 6] = ["local", "none", "output", "input", "parameter", "calculatedParameter"];

pub const REAL: u8 = 0;
pub const INTEGER: u8 = 1;
pub const BOOLEAN: u8 = 2;
pub const STRING: u8 = 3;
pub const ENUMERATION: u8 = 4;
pub const EXTERNAL_OBJECT: u8 = 5;

const REAL_SENSITIVITY: u8 = 14;

pub const NO_ALIAS: u8 = 0;
pub const ALIAS: u8 = 1;
pub const NEGATED_ALIAS: u8 = 2;

pub const DISCRETE: u16 = 1;
pub const VALUE_CHANGEABLE: u16 = 2;
pub const PROTECTED: u16 = 4;
pub const ENCRYPTED: u16 = 8;
pub const INIT_NONLINEAR: u16 = 16;
pub const FIXED: u16 = 32;
pub const RELATIVE_QUANTITY: u16 = 64;
pub const FILE_WRITABLE: u16 = 128;
pub const ARRAY: u16 = 256;
pub const USE_NOMINAL: u16 = 512;

#[derive(Clone, Debug, PartialEq)]
pub enum Value {
    Real(f64),
    Integer(i64),
    Boolean(bool),
    String(String),
}

#[derive(Clone, Debug, Default)]
pub struct Model {
    pub name: String,
    pub identifier: String,
    pub description: String,
    pub guid: String,
    pub generation_tool: String,
    pub generation_date_and_time: String,
    pub omhome: String,
    /// In the order of `COUNT_NAMES`.
    pub counts: [i32; 19],
}

pub const COUNT_NAMES: [&str; 19] = [
    "numberOfContinuousStates",
    "numberOfRealAlgebraicVariables",
    "numberOfRealAlgebraicAliasVariables",
    "numberOfRealParameters",
    "numberOfIntegerAlgebraicVariables",
    "numberOfIntegerAliasVariables",
    "numberOfIntegerParameters",
    "numberOfBooleanAlgebraicVariables",
    "numberOfBooleanAliasVariables",
    "numberOfBooleanParameters",
    "numberOfStringAlgebraicVariables",
    "numberOfStringAliasVariables",
    "numberOfStringParameters",
    "numberOfEventIndicators",
    "numberOfTimeEvents",
    "numberOfInputVariables",
    "numberOfOutputVariables",
    "numberOfExternalObjects",
    "numberOfFunctions",
];

#[derive(Clone, Debug, Default)]
pub struct Experiment {
    pub start_time: f64,
    pub stop_time: f64,
    pub step_size: f64,
    pub tolerance: f64,
    pub solver: String,
    pub output_format: String,
    pub variable_filter: String,
}

#[derive(Clone, Debug, Default)]
pub struct Enumeration {
    pub name: String,
    /// The literals, with the values 1, 2, ...
    pub literals: Vec<String>,
}

#[derive(Clone, Debug, Default)]
pub struct Variable {
    pub name: String,
    pub description: String,
    pub file_name: String,
    pub unit: String,
    pub display_unit: String,
    /// The enumeration type or external object class, else empty.
    pub declared_type: String,
    /// The variable this one is an alias of, else empty.
    pub alias_variable: String,
    pub value_reference: i32,
    pub input_index: i32,
    pub class_index: i32,
    pub start_line: i32,
    pub start_column: i32,
    pub end_line: i32,
    pub end_column: i32,
    pub class_type: u8,
    pub base_type: u8,
    pub variability: u8,
    pub causality: u8,
    pub alias: u8,
    /// 0 not given, 1 false, 2 true.
    pub hide_result: u8,
    pub flags: u16,
    /// Per dimension its size, or the value reference of the Integer parameter that gives it.
    pub dimensions: Vec<Dimension>,
    /// Empty if not given. One value for an array is the value of all elements.
    pub start: Vec<Value>,
    pub min: Vec<Value>,
    pub max: Vec<Value>,
    pub nominal: Vec<Value>,
}

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum Dimension {
    Size(i64),
    ValueReference(i64),
}

impl Variable {
    pub fn has(&self, flag: u16) -> bool {
        self.flags & flag != 0
    }
}

#[derive(Clone, Debug, Default)]
pub struct InitFile {
    pub model: Model,
    pub experiment: Experiment,
    pub enumerations: Vec<Enumeration>,
    /// Ordered by class type, as the runtime arrays.
    pub variables: Vec<Variable>,
}

#[derive(Clone, Copy, Default)]
struct Section<'a> {
    data: &'a [u8],
    count: usize,
    stride: usize,
}

fn u16_at(d: &[u8], o: usize) -> u16 {
    u16::from_le_bytes([d[o], d[o + 1]])
}
fn u32_at(d: &[u8], o: usize) -> u32 {
    u32::from_le_bytes(d[o..o + 4].try_into().unwrap())
}
fn i32_at(d: &[u8], o: usize) -> i32 {
    u32_at(d, o) as i32
}
fn u64_at(d: &[u8], o: usize) -> u64 {
    u64::from_le_bytes(d[o..o + 8].try_into().unwrap())
}
fn f64_at(d: &[u8], o: usize) -> f64 {
    f64::from_bits(u64_at(d, o))
}

struct Pools<'a> {
    strings: &'a [u8],
    reals: Section<'a>,
    integers: Section<'a>,
}

impl Pools<'_> {
    fn string(&self, offset: u64) -> Result<String, String> {
        let rest = self
            .strings
            .get(offset as usize..)
            .ok_or_else(|| format!("string offset {offset} out of range"))?;
        let end = rest
            .iter()
            .position(|&b| b == 0)
            .ok_or("the strings are not NUL-terminated")?;
        Ok(String::from_utf8_lossy(&rest[..end]).into_owned())
    }
    fn string_at(&self, d: &[u8], o: usize) -> Result<String, String> {
        self.string(u32_at(d, o) as u64)
    }
    fn integer(&self, i: usize) -> Result<i64, String> {
        if i >= self.integers.count {
            return Err(format!("integer {i} out of range"));
        }
        Ok(u64_at(self.integers.data, 8 * i) as i64)
    }
    fn real(&self, i: usize) -> Result<f64, String> {
        if i >= self.reals.count {
            return Err(format!("real {i} out of range"));
        }
        Ok(f64_at(self.reals.data, 8 * i))
    }
    fn values(&self, d: &[u8], o: usize, base: u8) -> Result<Vec<Value>, String> {
        let (count, index) = (u32_at(d, o) as usize, u32_at(d, o + 4) as usize);
        (index..index + count)
            .map(|i| {
                Ok(match base {
                    REAL => Value::Real(self.real(i)?),
                    BOOLEAN => Value::Boolean(self.integer(i)? != 0),
                    STRING => Value::String(self.string(self.integer(i)? as u64)?),
                    _ => Value::Integer(self.integer(i)?),
                })
            })
            .collect()
    }
}

impl InitFile {
    pub fn read(path: &str) -> Result<InitFile, String> {
        let bytes = std::fs::read(path).map_err(|e| format!("cannot read {path}: {e}"))?;
        InitFile::parse(&bytes).map_err(|e| format!("{path}: {e}"))
    }

    pub fn parse(d: &[u8]) -> Result<InitFile, String> {
        if d.len() < 16 || &d[..8] != b"OMCINIT\0" {
            return Err("not an init.bin file".into());
        }
        let version = u32_at(d, 8);
        if version != VERSION {
            return Err(format!("unsupported version {version}, expected {VERSION}"));
        }
        let num_sections = u32_at(d, 12) as usize;
        if 16 + 24 * num_sections > d.len() {
            return Err("truncated section table".into());
        }
        let mut sections = [Section::default(); 8];
        let mut present = [false; 8];
        for i in 0..num_sections {
            let e = 16 + 24 * i;
            let (id, count, offset, size) = (
                u32_at(d, e),
                u32_at(d, e + 4) as usize,
                u64_at(d, e + 8),
                u64_at(d, e + 16),
            );
            let end = offset.checked_add(size).ok_or("section out of range")?;
            let data = d
                .get(offset as usize..end as usize)
                .ok_or_else(|| format!("section {id} out of range"))?;
            if (1..=7).contains(&id) {
                let stride = if id == STRINGS || count == 0 {
                    1
                } else {
                    data.len() / count
                };
                sections[id as usize] = Section { data, count, stride };
                present[id as usize] = true;
            }
        }
        let section = |id: u32, min_stride: usize| -> Result<Section, String> {
            if !present[id as usize] {
                return Err(format!("section {id} is missing"));
            }
            let s = sections[id as usize];
            if s.count > 0 && (s.stride < min_stride || s.stride * s.count > s.data.len()) {
                return Err(format!(
                    "section {id} has records of {} bytes, expected {min_stride}",
                    s.stride
                ));
            }
            Ok(s)
        };
        let p = Pools {
            strings: section(STRINGS, 1)?.data,
            reals: section(REALS, 8)?,
            integers: section(INTEGERS, 8)?,
        };

        let m = section(MODEL, 104)?.data;
        let mut model = Model {
            name: p.string_at(m, 0)?,
            identifier: p.string_at(m, 4)?,
            description: p.string_at(m, 8)?,
            guid: p.string_at(m, 12)?,
            generation_tool: p.string_at(m, 16)?,
            generation_date_and_time: p.string_at(m, 20)?,
            omhome: p.string_at(m, 24)?,
            counts: [0; 19],
        };
        for (i, c) in model.counts.iter_mut().enumerate() {
            *c = i32_at(m, 28 + 4 * i);
        }

        let e = section(EXPERIMENT, 48)?.data;
        let experiment = Experiment {
            start_time: f64_at(e, 0),
            stop_time: f64_at(e, 8),
            step_size: f64_at(e, 16),
            tolerance: f64_at(e, 24),
            solver: p.string_at(e, 32)?,
            output_format: p.string_at(e, 36)?,
            variable_filter: p.string_at(e, 40)?,
        };

        let en = section(ENUMERATIONS, 12)?;
        let mut enumerations = Vec::with_capacity(en.count);
        for k in 0..en.count {
            let r = &en.data[k * en.stride..];
            let (n, first) = (u32_at(r, 4) as usize, u32_at(r, 8) as usize);
            let literals = (first..first + n)
                .map(|i| p.string(p.integer(i)? as u64))
                .collect::<Result<_, String>>()?;
            enumerations.push(Enumeration {
                name: p.string_at(r, 0)?,
                literals,
            });
        }

        let vs = section(VARIABLES, 104)?;
        let mut variables = Vec::with_capacity(vs.count);
        for k in 0..vs.count {
            let r = &vs.data[k * vs.stride..];
            let (class_type, base_type) = (r[56], r[57]);
            if class_type as usize >= CLASS_TYPES.len() || base_type as usize >= BASE_TYPES.len() {
                return Err(format!("variable {}: invalid class or base type", p.string_at(r, 0)?));
            }
            let (num_dims, first_dim) = (u32_at(r, 64) as usize, u32_at(r, 68) as usize);
            let mut dimensions = Vec::with_capacity(num_dims);
            for i in 0..num_dims {
                let (size, vr) = (p.integer(first_dim + 2 * i)?, p.integer(first_dim + 2 * i + 1)?);
                dimensions.push(if vr >= 0 {
                    Dimension::ValueReference(vr)
                } else {
                    Dimension::Size(size)
                });
            }
            variables.push(Variable {
                name: p.string_at(r, 0)?,
                description: p.string_at(r, 4)?,
                file_name: p.string_at(r, 8)?,
                unit: p.string_at(r, 12)?,
                display_unit: p.string_at(r, 16)?,
                declared_type: p.string_at(r, 20)?,
                alias_variable: p.string_at(r, 24)?,
                value_reference: i32_at(r, 28),
                input_index: i32_at(r, 32),
                class_index: i32_at(r, 36),
                start_line: i32_at(r, 40),
                start_column: i32_at(r, 44),
                end_line: i32_at(r, 48),
                end_column: i32_at(r, 52),
                class_type,
                base_type,
                variability: r[58].min(3),
                causality: r[59].min(5),
                alias: r[60].min(2),
                hide_result: r[61].min(2),
                flags: u16_at(r, 62),
                dimensions,
                start: p.values(r, 72, base_type)?,
                min: p.values(r, 80, base_type)?,
                max: p.values(r, 88, base_type)?,
                nominal: p.values(r, 96, base_type)?,
            });
        }
        Ok(InitFile {
            model,
            experiment,
            enumerations,
            variables,
        })
    }

    /// One line per variable, for tests and debugging. Attributes that are not
    /// given or have their default are left out.
    pub fn to_text(&self) -> String {
        let mut s = String::new();
        let e = &self.experiment;
        let _ = writeln!(s, "model {}", self.model.name);
        let sizes: Vec<String> = COUNT_NAMES
            .iter()
            .zip(self.model.counts)
            .filter(|(_, n)| *n != 0)
            .map(|(name, n)| format!("{name}={n}"))
            .collect();
        let _ = writeln!(s, "sizes {}", sizes.join(" "));
        let _ = writeln!(
            s,
            "experiment startTime={:?} stopTime={:?} stepSize={:?} tolerance={:?} solver={} outputFormat={} variableFilter={:?}",
            e.start_time, e.stop_time, e.step_size, e.tolerance, e.solver, e.output_format, e.variable_filter
        );
        for en in &self.enumerations {
            let _ = writeln!(s, "enumeration {}({})", en.name, en.literals.join(", "));
        }
        for v in &self.variables {
            let _ = write!(
                s,
                "{} {} {} {}",
                CLASS_TYPES[v.class_type as usize],
                v.name,
                BASE_TYPES[v.base_type as usize],
                VARIABILITY[v.variability as usize]
            );
            if v.causality != 0 {
                let _ = write!(s, " causality={}", CAUSALITY[v.causality as usize]);
            }
            if v.variability == 0 && v.has(DISCRETE) {
                s.push_str(" discrete");
            }
            for (flag, name) in [
                (VALUE_CHANGEABLE, "changeable"),
                (FIXED, "fixed"),
                (PROTECTED, "protected"),
                (ENCRYPTED, "encrypted"),
                (INIT_NONLINEAR, "initNonlinear"),
                (RELATIVE_QUANTITY, "relativeQuantity"),
                (USE_NOMINAL, "useNominal"),
            ] {
                if v.has(flag) {
                    let _ = write!(s, " {name}");
                }
            }
            match v.hide_result {
                1 => s.push_str(" hideResult=false"),
                2 => s.push_str(" hideResult=true"),
                _ => {}
            }
            match v.alias {
                ALIAS => {
                    let _ = write!(s, " alias={}", v.alias_variable);
                }
                NEGATED_ALIAS => {
                    let _ = write!(s, " negatedAlias={}", v.alias_variable);
                }
                _ => {}
            }
            if !v.declared_type.is_empty() {
                let _ = write!(s, " type={}", v.declared_type);
            }
            if v.input_index >= 0 {
                let _ = write!(s, " inputIndex={}", v.input_index);
            }
            if !v.dimensions.is_empty() {
                let dims: Vec<String> = v
                    .dimensions
                    .iter()
                    .map(|d| match d {
                        Dimension::Size(n) => n.to_string(),
                        Dimension::ValueReference(vr) => format!("vr{vr}"),
                    })
                    .collect();
                let _ = write!(s, " dimensions=[{}]", dims.join(","));
            }
            for (name, values) in [
                ("start", &v.start),
                ("min", &v.min),
                ("max", &v.max),
                ("nominal", &v.nominal),
            ] {
                if !values.is_empty() {
                    let _ = write!(s, " {name}={}", values_text(values));
                }
            }
            if !v.unit.is_empty() {
                let _ = write!(s, " unit={:?}", v.unit);
            }
            if !v.display_unit.is_empty() {
                let _ = write!(s, " displayUnit={:?}", v.display_unit);
            }
            if !v.description.is_empty() {
                let _ = write!(s, " description={:?}", v.description);
            }
            s.push('\n');
        }
        s
    }

    /// The output of `-listVariables`. `override_value` gives the `-override`
    /// value of a variable; the C runtime prints the same.
    pub fn list_variables(&self, override_value: impl Fn(&str) -> Option<String>) -> String {
        let e = &self.experiment;
        let mut s = format!(
            "{{\"modelName\":{},\"generationTool\":{},\"defaultExperiment\":{{\"startTime\":{},\"stopTime\":{},\"stepSize\":{},\"tolerance\":{},\"solver\":{},\"outputFormat\":{},\"variableFilter\":{}}},\"variables\":[",
            json_string(&self.model.name),
            json_string(&self.model.generation_tool),
            json_real(e.start_time),
            json_real(e.stop_time),
            json_real(e.step_size),
            json_real(e.tolerance),
            json_string(&e.solver),
            json_string(&e.output_format),
            json_string(&e.variable_filter)
        );
        for (i, v) in self.variables.iter().enumerate() {
            s.push_str(if i == 0 { "\n" } else { ",\n" });
            let changeable = v.has(VALUE_CHANGEABLE) && v.class_type != REAL_SENSITIVITY;
            json_variable(&mut s, v, changeable.then(|| override_value(&v.name)).flatten());
        }
        s.push_str("\n]}\n");
        s
    }
}

fn json_variable(s: &mut String, v: &Variable, start: Option<String>) {
    let _ = write!(
        s,
        "{{\"name\":{},\"type\":\"{}\",\"description\":{},\"variability\":\"{}\",\"causality\":\"{}\",\"isValueChangeable\":{},\"alias\":\"{}\"",
        json_string(&v.name),
        BASE_TYPES[v.base_type as usize],
        json_string(&v.description),
        VARIABILITY[v.variability as usize],
        CAUSALITY[v.causality as usize],
        v.has(VALUE_CHANGEABLE),
        ["noAlias", "alias", "negatedAlias"][v.alias as usize]
    );
    if v.alias != NO_ALIAS {
        let _ = write!(s, ",\"aliasVariable\":{}", json_string(&v.alias_variable));
    }
    let _ = write!(
        s,
        ",\"isProtected\":{},\"isEncrypted\":{}",
        v.has(PROTECTED),
        v.has(ENCRYPTED)
    );
    if v.hide_result != 0 {
        let _ = write!(s, ",\"hideResult\":{}", v.hide_result == 2);
    }
    if !v.declared_type.is_empty() {
        let _ = write!(s, ",\"declaredType\":{}", json_string(&v.declared_type));
    }
    if v.has(ARRAY) {
        let dims: Vec<String> = v
            .dimensions
            .iter()
            .map(|d| match d {
                Dimension::Size(n) => n.to_string(),
                Dimension::ValueReference(vr) => format!("{{\"valueReference\":{vr}}}"),
            })
            .collect();
        let _ = write!(s, ",\"dimensions\":[{}]", dims.join(","));
    }
    match start {
        Some(value) => {
            let _ = write!(s, ",\"start\":{}", json_override(v, &value));
        }
        None => json_values(s, v, "start", &v.start),
    }
    json_values(s, v, "min", &v.min);
    json_values(s, v, "max", &v.max);
    if !v.unit.is_empty() {
        let _ = write!(s, ",\"unit\":{}", json_string(&v.unit));
    }
    if !v.display_unit.is_empty() {
        let _ = write!(s, ",\"displayUnit\":{}", json_string(&v.display_unit));
    }
    s.push('}');
}

fn json_values(s: &mut String, v: &Variable, name: &str, values: &[Value]) {
    if values.is_empty() {
        return;
    }
    let _ = write!(s, ",\"{name}\":");
    if v.has(ARRAY) {
        let elements: Vec<String> = values.iter().map(json_value).collect();
        let _ = write!(s, "[{}]", elements.join(","));
    } else {
        s.push_str(&json_value(&values[0]));
    }
}

/// An `-override` value with the type of `v`, else as a string.
fn json_override(v: &Variable, value: &str) -> String {
    if !v.has(ARRAY) {
        match v.base_type {
            REAL => {
                if let Ok(r) = value.parse::<f64>() {
                    return json_real(r);
                }
            }
            INTEGER | ENUMERATION => {
                if let Ok(i) = value.parse::<i64>() {
                    return i.to_string();
                }
            }
            BOOLEAN if value == "true" || value == "false" => return value.to_string(),
            _ => {}
        }
    }
    json_string(value)
}

fn json_string(t: &str) -> String {
    let mut s = String::with_capacity(t.len() + 2);
    s.push('"');
    for c in t.chars() {
        match c {
            '"' => s.push_str("\\\""),
            '\\' => s.push_str("\\\\"),
            '\n' => s.push_str("\\n"),
            '\r' => s.push_str("\\r"),
            '\t' => s.push_str("\\t"),
            c if (c as u32) < 0x20 => {
                let _ = write!(s, "\\u{:04x}", c as u32);
            }
            c => s.push(c),
        }
    }
    s.push('"');
    s
}

/// The shortest of C's `%.15g`, `%.16g` and `%.17g` that reads back as `r`, as
/// the C runtime prints it. JSON has no infinity or NaN: an infinity is written
/// as a number that overflows (`1e999`), NaN as null.
fn json_real(r: f64) -> String {
    if r.is_nan() {
        return "null".into();
    }
    if r.is_infinite() {
        return if r > 0.0 { "1e999" } else { "-1e999" }.into();
    }
    (15..17)
        .map(|p| c_format_g(r, p))
        .find(|t| t.parse::<f64>() == Ok(r))
        .unwrap_or_else(|| c_format_g(r, 17))
}

/// C's `%.<precision>g`.
fn c_format_g(r: f64, precision: usize) -> String {
    if r == 0.0 {
        return if r.is_sign_negative() { "-0" } else { "0" }.into();
    }
    let e = format!("{:.*e}", precision - 1, r);
    let (mantissa, exp) = e.split_once('e').unwrap_or((&e, "0"));
    let exp: i32 = exp.parse().unwrap_or(0);
    let trim = |t: &str| -> String {
        match t.contains('.') {
            true => t.trim_end_matches('0').trim_end_matches('.').to_string(),
            false => t.to_string(),
        }
    };
    if exp < -4 || exp >= precision as i32 {
        let sign = if exp < 0 { '-' } else { '+' };
        format!("{}e{sign}{:02}", trim(mantissa), exp.abs())
    } else {
        trim(&format!("{:.*}", (precision as i32 - 1 - exp) as usize, r))
    }
}

fn json_value(v: &Value) -> String {
    match v {
        Value::Real(r) => json_real(*r),
        Value::Integer(i) => i.to_string(),
        Value::Boolean(b) => b.to_string(),
        Value::String(t) => json_string(t),
    }
}

/// The values as the init XML spelled them: space-separated, the String
/// elements of an array quoted.
pub fn values_plain_text(values: &[Value], is_array: bool) -> String {
    values
        .iter()
        .map(|v| match v {
            Value::Real(r) => format!("{r:?}"),
            Value::Integer(i) => i.to_string(),
            Value::Boolean(b) => b.to_string(),
            Value::String(s) if is_array => format!("\"{s}\""),
            Value::String(s) => s.clone(),
        })
        .collect::<Vec<_>>()
        .join(" ")
}

fn values_text(values: &[Value]) -> String {
    let text = |v: &Value| match v {
        Value::Real(r) => format!("{r:?}"),
        Value::Integer(i) => i.to_string(),
        Value::Boolean(b) => b.to_string(),
        Value::String(t) => format!("{t:?}"),
    };
    if values.len() == 1 {
        text(&values[0])
    } else {
        format!("{{{}}}", values.iter().map(text).collect::<Vec<_>>().join(", "))
    }
}

#[cfg(test)]
mod tests {
    use super::json_real;

    #[test]
    fn real_as_c_prints_it() {
        for (r, t) in [
            (1.0, "1"),
            (0.1, "0.1"),
            (-2.5, "-2.5"),
            (1e-6, "1e-06"),
            (1.5e300, "1.5e+300"),
            (123456789012345680.0, "1.2345678901234568e+17"),
            (1e15, "1e+15"),
            (0.0001, "0.0001"),
            (1.0 / 3.0, "0.3333333333333333"),
            (f64::INFINITY, "1e999"),
            (f64::NAN, "null"),
        ] {
            assert_eq!(json_real(r), t, "{r:?}");
        }
    }
}
