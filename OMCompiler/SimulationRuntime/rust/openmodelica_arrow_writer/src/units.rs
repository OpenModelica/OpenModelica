//! Unit definitions in FMI 3.0's terms, shared by the writer and the reader,
//! and the predefined set both sides agree on without the file saying anything.
//!
//! A variable names its `unit` and `displayUnit`; the conversions live in the
//! `modelica.units` and `modelica.displayUnits` tables once, because a model
//! has far more variables than units.

/// A `baseUnit`'s exponents, in FMI's attribute order. OpenModelica has no
/// `rad` dimension and always computes 0 for it; the predefined table below
/// follows FMI.
pub const BASE_EXPONENTS: [&str; 8] = ["kg", "m", "s", "A", "K", "mol", "cd", "rad"];

/// FMI 3.0 `<BaseUnit>`: `v_SI = factor * v_unit + offset` over [`BASE_EXPONENTS`].
#[derive(Clone, PartialEq, Debug)]
pub struct BaseUnit {
    pub exponents: [i32; 8],
    pub factor: f64,
    pub offset: f64,
}

impl Default for BaseUnit {
    fn default() -> BaseUnit {
        BaseUnit { exponents: [0; 8], factor: 1.0, offset: 0.0 }
    }
}

/// FMI 3.0 `<DisplayUnit>`: `v_display = factor * v_unit + offset`, or
/// `factor * (1 / v_unit)` when `inverse`, which FMI allows only with a zero
/// offset (a reciprocal unit such as mpg or Siemens, not a re-association).
#[derive(Clone, PartialEq, Debug)]
pub struct DisplayUnit {
    pub name: String,
    pub factor: f64,
    pub offset: f64,
    pub inverse: bool,
}

impl DisplayUnit {
    pub fn new(name: &str, factor: f64, offset: f64) -> DisplayUnit {
        DisplayUnit { name: name.to_owned(), factor, offset, inverse: false }
    }
}

/// One entry of the `modelica.units` table.
#[derive(Clone, PartialEq, Debug, Default)]
pub struct UnitDef {
    pub name: String,
    /// Absent where the unit string has no SI dimensions the writer could
    /// derive (FMI's `<Unit>` without a `<BaseUnit>`).
    pub base: Option<BaseUnit>,
    pub display_units: Vec<DisplayUnit>,
}

impl UnitDef {
    pub fn new(name: &str) -> UnitDef {
        UnitDef { name: name.to_owned(), base: None, display_units: Vec::new() }
    }

    pub fn display_unit(&self, name: &str) -> Option<&DisplayUnit> {
        self.display_units.iter().find(|d| d.name == name)
    }

    /// Whether this unit is the predefined one of the same name. OpenModelica
    /// cannot express the `rad` exponent, so that one dimension is not compared;
    /// a unit with no dimensions at all is taken to be the predefined one, since
    /// it says nothing that could disagree.
    pub(crate) fn same_base_as_predefined(&self) -> Option<UnitDef> {
        let p = predefined(&self.name)?;
        match (&self.base, &p.base) {
            (Some(a), Some(b)) if a.exponents[..7] == b.exponents[..7] && a.factor == b.factor && a.offset == b.offset => Some(p),
            (None, _) => Some(p),
            _ => None,
        }
    }

    /// Whether the predefined unit of this name says everything this one does,
    /// so the file need not carry it.
    pub fn is_predefined(&self) -> bool {
        let Some(p) = self.same_base_as_predefined() else { return false };
        self.display_units.iter().all(|d| p.display_unit(&d.name) == Some(d))
    }

    /// The predefined display units of this name that this one does not itself
    /// declare — skipped where the two disagree about the dimensions, which
    /// makes them different units that happen to share a name.
    ///
    /// A writer does not need this: an entry of the units table is merged with
    /// the predefined one by whoever reads it. It is for a consumer that must
    /// materialise a complete unit, an FMI exporter where a variable may only
    /// name a declared `<Unit>`.
    pub fn add_predefined_display_units(&mut self) {
        let Some(p) = self.same_base_as_predefined() else { return };
        if self.base.is_none() {
            self.base = p.base;
        }
        for d in p.display_units {
            if self.display_unit(&d.name).is_none() {
                self.display_units.push(d);
            }
        }
    }
}

/// The entries a file must carry for the units its variables name: the ones
/// [`predefined`] does not already say everything about.
///
/// An entry carries only what it declares. A reader adds the predefined display
/// units of the same name to it, so a unit that needs spelling out for one
/// display unit the predefined set lacks does not have to repeat the twenty it
/// has - which is what makes prefixing every unit affordable. An entry whose
/// `baseUnit` disagrees with the predefined one is a different unit that happens
/// to share a name, and nothing is merged into it.
pub fn declared(units: impl IntoIterator<Item = UnitDef>) -> Vec<UnitDef> {
    units.into_iter().filter(|u| !u.is_predefined()).collect()
}

/// The `modelica.units` JSON of the pre-`arrow.modelica` layout.
#[cfg(feature = "json-layout")]
pub fn units_json(units: &[UnitDef]) -> String {
    let mut json = String::from("[");
    for (i, u) in units.iter().enumerate() {
        if i > 0 {
            json.push(',');
        }
        json.push_str("{\"name\":");
        crate::json::json_str(&mut json, &u.name);
        if let Some(b) = &u.base {
            json.push_str(",\"baseUnit\":{");
            let mut first = true;
            let mut key = |json: &mut String, k: &str| {
                if !first {
                    json.push(',');
                }
                first = false;
                json.push('"');
                json.push_str(k);
                json.push_str("\":");
            };
            for (k, e) in BASE_EXPONENTS.iter().zip(b.exponents) {
                if e != 0 {
                    key(&mut json, k);
                    json.push_str(&e.to_string());
                }
            }
            if b.factor != 1.0 {
                key(&mut json, "factor");
                json.push_str(&format!("{:?}", b.factor));
            }
            if b.offset != 0.0 {
                key(&mut json, "offset");
                json.push_str(&format!("{:?}", b.offset));
            }
            json.push('}');
        }
        if !u.display_units.is_empty() {
            json.push_str(",\"displayUnits\":[");
            for (j, d) in u.display_units.iter().enumerate() {
                if j > 0 {
                    json.push(',');
                }
                json.push_str("{\"name\":");
                crate::json::json_str(&mut json, &d.name);
                if d.factor != 1.0 {
                    json.push_str(&format!(",\"factor\":{:?}", d.factor));
                }
                if d.offset != 0.0 {
                    json.push_str(&format!(",\"offset\":{:?}", d.offset));
                }
                if d.inverse {
                    json.push_str(",\"inverse\":true");
                }
                json.push('}');
            }
            json.push(']');
        }
        json.push('}');
    }
    json.push(']');
    json
}

/// `(name, exponents, factor, offset, display units)`.
type Predef = (&'static str, [i32; 8], f64, f64, &'static [(&'static str, f64, f64)]);

const DEG: f64 = 180.0 / core::f64::consts::PI;
const RPM: f64 = 30.0 / core::f64::consts::PI;

/// The units a reader of this format knows without the file declaring them, so
/// a writer omits them. SPECIFICATION.md lists the same table, and a test below
/// holds the two together; the set may only grow, and only with the minor
/// version, since an older reader would not know a unit a newer writer omitted.
#[rustfmt::skip]
const PREDEFINED: &[Predef] = &[
    //        kg  m  s  A  K mol cd rad
    ("1",    [ 0, 0, 0, 0, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("kg",   [ 1, 0, 0, 0, 0, 0, 0, 0], 1.0, 0.0, &[("g", 1e3, 0.0), ("t", 1e-3, 0.0)]),
    ("m",    [ 0, 1, 0, 0, 0, 0, 0, 0], 1.0, 0.0, &[("mm", 1e3, 0.0), ("cm", 1e2, 0.0), ("km", 1e-3, 0.0)]),
    ("s",    [ 0, 0, 1, 0, 0, 0, 0, 0], 1.0, 0.0, &[("ms", 1e3, 0.0), ("min", 1.0 / 60.0, 0.0), ("h", 1.0 / 3600.0, 0.0), ("d", 1.0 / 86400.0, 0.0)]),
    ("A",    [ 0, 0, 0, 1, 0, 0, 0, 0], 1.0, 0.0, &[("mA", 1e3, 0.0), ("kA", 1e-3, 0.0)]),
    ("K",    [ 0, 0, 0, 0, 1, 0, 0, 0], 1.0, 0.0, &[("degC", 1.0, -273.15)]),
    ("mol",  [ 0, 0, 0, 0, 0, 1, 0, 0], 1.0, 0.0, &[]),
    ("cd",   [ 0, 0, 0, 0, 0, 0, 1, 0], 1.0, 0.0, &[]),
    ("rad",  [ 0, 0, 0, 0, 0, 0, 0, 1], 1.0, 0.0, &[("deg", DEG, 0.0)]),
    // The named derived units of the SI.
    ("sr",   [ 0, 0, 0, 0, 0, 0, 0, 2], 1.0, 0.0, &[]),
    ("Hz",   [ 0, 0,-1, 0, 0, 0, 0, 0], 1.0, 0.0, &[("kHz", 1e-3, 0.0), ("MHz", 1e-6, 0.0)]),
    ("N",    [ 1, 1,-2, 0, 0, 0, 0, 0], 1.0, 0.0, &[("kN", 1e-3, 0.0)]),
    ("Pa",   [ 1,-1,-2, 0, 0, 0, 0, 0], 1.0, 0.0, &[("bar", 1e-5, 0.0), ("kPa", 1e-3, 0.0), ("MPa", 1e-6, 0.0)]),
    ("J",    [ 1, 2,-2, 0, 0, 0, 0, 0], 1.0, 0.0, &[("kJ", 1e-3, 0.0), ("MJ", 1e-6, 0.0)]),
    ("W",    [ 1, 2,-3, 0, 0, 0, 0, 0], 1.0, 0.0, &[("kW", 1e-3, 0.0), ("MW", 1e-6, 0.0)]),
    ("C",    [ 0, 0, 1, 1, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("V",    [ 1, 2,-3,-1, 0, 0, 0, 0], 1.0, 0.0, &[("mV", 1e3, 0.0), ("kV", 1e-3, 0.0)]),
    ("F",    [-1,-2, 4, 2, 0, 0, 0, 0], 1.0, 0.0, &[("uF", 1e6, 0.0), ("nF", 1e9, 0.0), ("pF", 1e12, 0.0)]),
    ("Ohm",  [ 1, 2,-3,-2, 0, 0, 0, 0], 1.0, 0.0, &[("kOhm", 1e-3, 0.0), ("MOhm", 1e-6, 0.0)]),
    ("S",    [-1,-2, 3, 2, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("Wb",   [ 1, 2,-2,-1, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("T",    [ 1, 0,-2,-1, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("H",    [ 1, 2,-2,-2, 0, 0, 0, 0], 1.0, 0.0, &[("mH", 1e3, 0.0)]),
    ("lm",   [ 0, 0, 0, 0, 0, 0, 1, 2], 1.0, 0.0, &[]),
    ("lx",   [ 0,-2, 0, 0, 0, 0, 1, 2], 1.0, 0.0, &[]),
    ("Bq",   [ 0, 0,-1, 0, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("Gy",   [ 0, 2,-2, 0, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("Sv",   [ 0, 2,-2, 0, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("kat",  [ 0, 0,-1, 0, 0, 1, 0, 0], 1.0, 0.0, &[]),
    // The kinematic and thermal units a Modelica model reaches for constantly.
    ("m/s",  [ 0, 1,-1, 0, 0, 0, 0, 0], 1.0, 0.0, &[("km/h", 3.6, 0.0)]),
    ("m/s2", [ 0, 1,-2, 0, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("m2",   [ 0, 2, 0, 0, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("m3",   [ 0, 3, 0, 0, 0, 0, 0, 0], 1.0, 0.0, &[("l", 1e3, 0.0), ("ml", 1e6, 0.0)]),
    ("m3/s", [ 0, 3,-1, 0, 0, 0, 0, 0], 1.0, 0.0, &[("l/s", 1e3, 0.0)]),
    ("kg/s", [ 1, 0,-1, 0, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("kg/m3",[ 1,-3, 0, 0, 0, 0, 0, 0], 1.0, 0.0, &[("g/cm3", 1e-3, 0.0)]),
    // `rpm`, `rev/min` and `1/min` are one conversion under three names; the
    // Modelica Standard Library writes all three.
    ("rad/s",[ 0, 0,-1, 0, 0, 0, 0, 1], 1.0, 0.0, &[("rpm", RPM, 0.0), ("rev/min", RPM, 0.0), ("1/min", RPM, 0.0), ("deg/s", DEG, 0.0)]),
    ("N.m",  [ 1, 2,-2, 0, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("J/K",  [ 1, 2,-2, 0,-1, 0, 0, 0], 1.0, 0.0, &[]),
    ("J/(kg.K)", [0, 2,-2, 0,-1, 0, 0, 0], 1.0, 0.0, &[]),
    ("W/(m.K)",  [1, 1,-3, 0,-1, 0, 0, 0], 1.0, 0.0, &[]),
    ("W/(m2.K)", [1, 0,-3, 0,-1, 0, 0, 0], 1.0, 0.0, &[]),
];

/// The SI prefixes, as `(name, exponent)`. A display unit converts *from* the
/// unit, `v_display = factor * v_unit`, so a prefix of 10^n is a factor 10^-n.
/// `u` rather than the micro sign, because a unit name is written in a Modelica
/// source file.
#[rustfmt::skip]
const PREFIXES: &[(&str, i32)] = &[
    ("y", -24), ("z", -21), ("a", -18), ("f", -15), ("p", -12), ("n", -9),
    ("u",  -6), ("m",  -3), ("c",  -2), ("d",  -1), ("da",  1), ("h",  2),
    ("k",   3), ("M",   6), ("G",   9), ("T",  12), ("P",  15), ("E", 18),
    ("Z",  21), ("Y",  24),
];

/// The units a prefix may be written on, as `(unit, stem, stem per unit)`.
///
/// Only the base and named derived units: `mW/(m2.K)` is not something anyone
/// writes, and a compound name is where a reader would have to start guessing.
/// The stem is the unit itself except for `kg`, where the SI prefixes the gram,
/// so its prefixed forms are milligrams and megagrams rather than millikilograms.
#[rustfmt::skip]
const PREFIXABLE: &[(&str, &str, f64)] = &[
    ("kg", "g", 1e3), ("m", "m", 1.0), ("s", "s", 1.0), ("A", "A", 1.0),
    ("K", "K", 1.0), ("mol", "mol", 1.0), ("cd", "cd", 1.0), ("rad", "rad", 1.0),
    ("sr", "sr", 1.0), ("Hz", "Hz", 1.0), ("N", "N", 1.0), ("Pa", "Pa", 1.0),
    ("J", "J", 1.0), ("W", "W", 1.0), ("C", "C", 1.0), ("V", "V", 1.0),
    ("F", "F", 1.0), ("Ohm", "Ohm", 1.0), ("S", "S", 1.0), ("Wb", "Wb", 1.0),
    ("T", "T", 1.0), ("H", "H", 1.0), ("lm", "lm", 1.0), ("lx", "lx", 1.0),
    ("Bq", "Bq", 1.0), ("Gy", "Gy", 1.0), ("Sv", "Sv", 1.0), ("kat", "kat", 1.0),
];

/// The prefixed display units of one unit, in prefix order, skipping any name
/// the hand-written table already gives and any form that is the unit itself
/// (`kg` prefixed back to `kg`, whose factor is 1).
fn prefixed(unit: &str, have: &[DisplayUnit]) -> Vec<DisplayUnit> {
    let Some(&(_, stem, per_unit)) = PREFIXABLE.iter().find(|p| p.0 == unit) else {
        return Vec::new();
    };
    PREFIXES
        .iter()
        .map(|&(p, exp)| DisplayUnit::new(&format!("{p}{stem}"), per_unit * 10f64.powi(-exp), 0.0))
        .filter(|d| d.name != unit && !have.iter().any(|h| h.name == d.name))
        .collect()
}

/// The predefined unit of that name, if there is one.
pub fn predefined(name: &str) -> Option<UnitDef> {
    PREDEFINED.iter().find(|p| p.0 == name).map(unit_def)
}

/// Every predefined unit, for a consumer that must materialise them — an FMI
/// exporter, where a variable may only name a declared `<Unit>`.
pub fn predefined_units() -> impl Iterator<Item = UnitDef> {
    PREDEFINED.iter().map(unit_def)
}

fn unit_def(p: &Predef) -> UnitDef {
    let mut display_units: Vec<DisplayUnit> =
        p.4.iter().map(|&(n, f, o)| DisplayUnit::new(n, f, o)).collect();
    display_units.extend(prefixed(p.0, &display_units));
    UnitDef { name: p.0.to_owned(), base: Some(BaseUnit { exponents: p.1, factor: p.2, offset: p.3 }), display_units }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn prefixed_display_units_are_sane() {
        let units: Vec<UnitDef> = predefined_units().collect();
        let names: Vec<&str> = units.iter().map(|u| u.name.as_str()).collect();
        for u in &units {
            let mut seen = std::collections::HashSet::new();
            for d in &u.display_units {
                assert!(seen.insert(&d.name), "{}: {} twice", u.name, d.name);
                assert!(
                    !names.contains(&d.name.as_str()),
                    "{}: display unit {} is also a unit",
                    u.name,
                    d.name
                );
                assert!(d.factor.is_finite() && d.factor != 0.0, "{}: {}", u.name, d.name);
            }
        }
        // The SI prefixes the gram, not the kilogram.
        let kg = predefined("kg").unwrap();
        assert_eq!(kg.display_unit("mg").map(|d| d.factor), Some(1e6));
        assert_eq!(kg.display_unit("Mg").map(|d| d.factor), Some(1e-3));
        assert!(kg.display_unit("mkg").is_none());
        // A hand-written display unit is not replaced by a prefixed one.
        assert_eq!(predefined("K").unwrap().display_unit("degC").map(|d| d.offset), Some(-273.15));
        // A compound unit takes no prefixes at all.
        assert!(predefined("W/(m2.K)").unwrap().display_units.is_empty());
    }

    #[test]
    fn predefined_names_are_distinct() {
        let mut names: Vec<&str> = PREDEFINED.iter().map(|p| p.0).collect();
        names.sort_unstable();
        let n = names.len();
        names.dedup();
        assert_eq!(names.len(), n, "a name predefined twice would be ambiguous");
    }

    #[test]
    fn a_unit_the_predefined_table_covers_is_omitted() {
        let mut k = UnitDef::new("K");
        k.base = Some(BaseUnit { exponents: [0, 0, 0, 0, 1, 0, 0, 0], ..BaseUnit::default() });
        assert!(k.is_predefined(), "a bare K says nothing the reader does not know");
        k.display_units.push(DisplayUnit::new("degC", 1.0, -273.15));
        assert!(k.is_predefined());
        k.display_units.push(DisplayUnit::new("degF", 1.8, -459.67));
        assert!(!k.is_predefined(), "degF is not predefined, so K must be spelled out");
        // And it is spelled out with what it declares, not with the twenty
        // prefixed kelvins a reader already knows.
        assert_eq!(declared(vec![k])[0].display_units.len(), 2);
    }

    #[test]
    fn a_unit_only_named_takes_the_predefined_definition() {
        // The unit parser gave no dimensions, but the name is one every reader knows.
        let declared = declared([UnitDef::new("K")]);
        assert!(declared.is_empty(), "{declared:?}");
    }

    #[test]
    fn a_name_reused_for_other_dimensions_keeps_its_own() {
        let mut k = UnitDef::new("K");
        k.base = Some(BaseUnit { exponents: [1, 0, 0, 0, 0, 0, 0, 0], ..BaseUnit::default() });
        k.add_predefined_display_units();
        assert!(k.display_units.is_empty(), "degC does not belong to a mass");
        assert_eq!(declared([k.clone()]), vec![k]);
    }

    #[cfg(feature = "json-layout")]
    #[test]
    fn the_json_omits_every_default() {
        let mut k = UnitDef::new("K");
        k.base = Some(BaseUnit { exponents: [0, 0, 0, 0, 1, 0, 0, 0], ..BaseUnit::default() });
        k.display_units.push(DisplayUnit::new("degC", 1.0, -273.15));
        assert_eq!(units_json(&[k]), r#"[{"name":"K","baseUnit":{"K":1},"displayUnits":[{"name":"degC","offset":-273.15}]}]"#);
    }

    /// SPECIFICATION.md's predefined-unit table is this table.
    #[test]
    fn the_specification_lists_the_same_units() {
        let spec = std::fs::read_to_string(concat!(env!("CARGO_MANIFEST_DIR"), "/SPECIFICATION.md")).expect("SPECIFICATION.md");
        let rows: Vec<&str> = spec.lines().filter(|l| l.starts_with("| `")).collect();
        let mut listed = 0;
        for row in rows {
            let cells: Vec<&str> = row.trim_matches('|').split('|').map(str::trim).collect();
            let [name, exponents, display] = cells[..] else { continue };
            let name = name.trim_matches('`');
            let Some(p) = PREDEFINED.iter().find(|p| p.0 == name) else { continue };
            listed += 1;
            let exponents: Vec<i32> = exponents.trim_matches('`').split_whitespace().map(|e| e.parse().unwrap()).collect();
            assert_eq!(exponents, p.1, "{name}: exponents");
            let display: Vec<&str> = display.split(',').map(str::trim).filter(|d| !d.is_empty()).collect();
            assert_eq!(display.len(), p.4.len(), "{name}: display units {display:?}");
            for (d, &(dname, factor, offset)) in display.iter().zip(p.4) {
                let (n, rest) = d.split_once('`').and_then(|(_, r)| r.split_once('`')).expect(d);
                assert_eq!(n, dname, "{name}");
                let want = format!("{}{}", spec_number(factor, true), if offset == 0.0 { String::new() } else { format!(" {}", spec_number(offset, false)) });
                assert_eq!(rest.trim(), want, "{name}: {dname}");
            }
        }
        assert_eq!(listed, PREDEFINED.len(), "every predefined unit is in the specification");
        let units: Vec<UnitDef> = predefined_units().collect();
        assert_eq!(units.len(), 42);
        assert_eq!(units.iter().map(|u| u.display_units.len()).sum::<usize>(), 576);
        assert!(spec.contains("42 units and 576"));
    }

    /// The way the specification writes a factor (`×1e-3`, `×30/π`) or an offset.
    fn spec_number(v: f64, factor: bool) -> String {
        let text = if v == DEG {
            "180/π".to_owned()
        } else if v == RPM {
            "30/π".to_owned()
        } else if v == 1.0 / 60.0 {
            "1/60".to_owned()
        } else if v == 1.0 / 3600.0 {
            "1/3600".to_owned()
        } else if v == 1.0 / 86400.0 {
            "1/86400".to_owned()
        } else if v.abs().log10().fract() == 0.0 && v.abs().log10().abs() >= 2.0 {
            format!("{}1e{}", if v < 0.0 { "-" } else { "" }, v.abs().log10().round() as i32)
        } else if v.fract() == 0.0 {
            format!("{}", v as i64)
        } else {
            format!("{v}")
        };
        if factor { format!("×{text}") } else if v < 0.0 { format!("−{}", &text[1..]) } else { format!("+{text}") }
    }
}
