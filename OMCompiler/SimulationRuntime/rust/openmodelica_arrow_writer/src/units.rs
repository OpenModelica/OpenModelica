//! The `modelica.units` table: unit definitions in FMI 3.0's terms, shared by
//! the writer and the reader, and the predefined set both sides agree on
//! without the file saying anything.
//!
//! ```text
//! {"name": "K", "baseUnit": {"K": 1}, "displayUnits": [{"name": "degC", "offset": -273.15}]}
//! ```
//!
//! A variable names its `unit` and `displayUnit`; the conversions live here
//! once, because a model has far more variables than units.

use crate::json_str;

/// A `baseUnit`'s exponents, in FMI's attribute order. OpenModelica has no
/// `rad` dimension and always computes 0 for it; the predefined table below
/// follows FMI, which treats `rad` as 1 for dimensional analysis anyway.
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
    fn same_base_as_predefined(&self) -> Option<UnitDef> {
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
        self.base.is_some() && self.display_units.iter().all(|d| p.display_unit(&d.name) == Some(d))
    }

    /// The predefined display units of this name that this one does not itself
    /// declare — skipped where the two disagree about the dimensions, which
    /// makes them different units that happen to share a name.
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
/// [`predefined`] does not already say everything about, each completed with the
/// predefined display units its own entry would otherwise hide.
pub fn declared(units: impl IntoIterator<Item = UnitDef>) -> Vec<UnitDef> {
    units
        .into_iter()
        .map(|mut u| {
            u.add_predefined_display_units();
            u
        })
        .filter(|u| !u.is_predefined())
        .collect()
}

/// The `modelica.units` JSON for the units a file must spell out.
pub fn units_json(units: &[UnitDef]) -> String {
    let mut json = String::from("[");
    for (i, u) in units.iter().enumerate() {
        if i > 0 {
            json.push(',');
        }
        json.push_str("{\"name\":");
        json_str(&mut json, &u.name);
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
                json_str(&mut json, &d.name);
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

/// The units a reader of format version `1` knows without the file declaring
/// them, so a writer omits them. The set is tied to the format version: growing
/// it would leave an older reader not knowing a unit a newer writer omitted, so
/// it may only grow together with `FORMAT_VERSION`.
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
    ("m3",   [ 0, 3, 0, 0, 0, 0, 0, 0], 1.0, 0.0, &[("l", 1e3, 0.0)]),
    ("m3/s", [ 0, 3,-1, 0, 0, 0, 0, 0], 1.0, 0.0, &[("l/s", 1e3, 0.0)]),
    ("kg/s", [ 1, 0,-1, 0, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("kg/m3",[ 1,-3, 0, 0, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("rad/s",[ 0, 0,-1, 0, 0, 0, 0, 1], 1.0, 0.0, &[("rpm", RPM, 0.0), ("deg/s", DEG, 0.0)]),
    ("N.m",  [ 1, 2,-2, 0, 0, 0, 0, 0], 1.0, 0.0, &[]),
    ("J/K",  [ 1, 2,-2, 0,-1, 0, 0, 0], 1.0, 0.0, &[]),
    ("J/(kg.K)", [0, 2,-2, 0,-1, 0, 0, 0], 1.0, 0.0, &[]),
    ("W/(m.K)",  [1, 1,-3, 0,-1, 0, 0, 0], 1.0, 0.0, &[]),
    ("W/(m2.K)", [1, 0,-3, 0,-1, 0, 0, 0], 1.0, 0.0, &[]),
];

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
    UnitDef {
        name: p.0.to_owned(),
        base: Some(BaseUnit { exponents: p.1, factor: p.2, offset: p.3 }),
        display_units: p.4.iter().map(|&(n, f, o)| DisplayUnit::new(n, f, o)).collect(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

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
        k.add_predefined_display_units();
        assert_eq!(k.display_units.len(), 2, "degC was already there");
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

    #[test]
    fn the_json_omits_every_default() {
        let k = predefined("K").expect("K");
        assert_eq!(units_json(&[k]), r#"[{"name":"K","baseUnit":{"K":1},"displayUnits":[{"name":"degC","offset":-273.15}]}]"#);
    }
}
