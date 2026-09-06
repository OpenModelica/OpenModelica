//! The benchmark's input: one OpenModelica `.mat` read into memory, plus the
//! units and variability its `_init.xml` records, as the neutral description
//! every writer is then driven from.
//!
//! A `.mat` alone has no units and no types (OpenModelica only appends `[s]` to
//! `time`'s description), so a comparison driven from it alone would understate
//! the metadata every other format carries. The `_init.xml` OpenModelica writes
//! next to the model has both, so it is used whenever it can be found.

use std::collections::HashMap;

pub use openmodelica_hdf5_result::{Affine, Kind, VarTy};
use openmodelica_mat_reader::MatReader;

/// The form every writer's own `Var` is built from.
#[derive(Clone)]
pub struct VarDesc {
    pub name: String,
    pub comment: String,
    pub unit: String,
    pub display_unit: String,
    pub ty: VarTy,
    pub discrete: bool,
    pub kind: Kind,
}

/// A whole result file in memory: the variable table, the time-variant rows
/// (row-major, `n_cols` wide, column 0 = time) and the parameter values.
#[derive(Clone)]
pub struct Dataset {
    pub name: String,
    pub vars: Vec<VarDesc>,
    pub rows: Vec<f64>,
    pub n_cols: usize,
    pub n_rows: usize,
    pub params: Vec<f64>,
    pub start_time: f64,
    pub stop_time: f64,
}

impl Dataset {
    /// The bytes a format has to move if it stores every signal at every step
    /// once, as `f64`: the yardstick the throughput figures are quoted against.
    pub fn payload_bytes(&self) -> u64 {
        (self.n_rows as u64) * (self.n_cols as u64) * 8
    }

    pub fn n_params(&self) -> usize {
        self.vars.iter().filter(|v| matches!(v.kind, Kind::Param { .. })).count()
    }

    pub fn n_aliases(&self) -> usize {
        let mut owner = std::collections::HashSet::new();
        let mut aliases = 0;
        for v in &self.vars {
            if let Kind::Column { col, .. } = v.kind
                && !owner.insert(col)
            {
                aliases += 1;
            }
        }
        aliases
    }

    /// One name per stored column: the variable that owns it, i.e. the first in
    /// the table that reads it without a transform. This is the set the read
    /// benchmark asks every format for, so they are all asked for the same
    /// trajectories however each of them represents an alias.
    pub fn stored_names(&self) -> Vec<String> {
        let mut owner: HashMap<u32, String> = HashMap::new();
        let mut order = Vec::new();
        for v in &self.vars {
            let Kind::Column { col, affine } = v.kind else { continue };
            if !affine.is_identity() || owner.contains_key(&col) {
                continue;
            }
            owner.insert(col, v.name.clone());
            order.push((col, v.name.clone()));
        }
        order.sort_by_key(|(c, _)| *c);
        order.into_iter().map(|(_, n)| n).collect()
    }

    /// The tail of the dotted name, for a table column.
    pub fn short_name(&self) -> String {
        let parts: Vec<&str> = self.name.rsplitn(3, '.').collect();
        parts.into_iter().rev().skip(usize::from(self.name.matches('.').count() >= 2)).collect::<Vec<_>>().join(".")
    }

    /// The first row, which gives the writers their `unvarying` values.
    pub fn first_row(&self) -> &[f64] {
        self.rows.get(..self.n_cols).unwrap_or(&[])
    }

    pub fn load(path: &str) -> Result<Dataset, String> {
        let mut mat = MatReader::open(path)?;
        mat.read_all();
        let n_cols = mat.nvar;
        let n_rows = mat.nrows;

        // data_2 is stored transposed, one contiguous trajectory per column;
        // the writers all want it row-major.
        let mut rows = vec![0.0f64; n_rows * n_cols];
        for c in 0..n_cols {
            let vals = mat.read_vals(c as i32 + 1).ok_or_else(|| format!("column {c} unreadable"))?;
            for (r, v) in vals.iter().enumerate().take(n_rows) {
                rows[r * n_cols + c] = *v;
            }
        }

        let attrs = ModelAttrs::beside(path);
        // The mat table is sorted by name; keep that order, it is what a reader
        // sees and it makes the SDF group tree build depth-first.
        let mut vars = Vec::with_capacity(mat.allInfo.len());
        let mut params = Vec::new();
        for info in &mat.allInfo {
            let a = attrs.get(&info.name);
            let affine = if info.index < 0 { Affine::negated() } else { Affine::IDENTITY };
            let kind = if info.isParam {
                let slot = info.index.unsigned_abs() as usize;
                let value = mat.params.get(slot.saturating_sub(1)).copied().unwrap_or(0.0);
                params.push(value);
                Kind::Param { affine }
            } else if info.index.unsigned_abs() == 1 && info.name == "time" {
                Kind::Time
            } else {
                Kind::Column { col: info.index.unsigned_abs() - 1, affine }
            };
            let (comment, unit) = split_unit(&info.descr);
            vars.push(VarDesc {
                name: info.name.clone(),
                comment: comment.to_owned(),
                unit: a.map_or(unit.to_owned(), |a| a.unit.clone()),
                display_unit: a.map_or_else(|| unit.to_owned(), |a| a.display_unit.clone()),
                ty: a.map_or(VarTy::Real, |a| a.ty),
                discrete: a.is_some_and(|a| a.discrete),
                kind,
            });
        }

        let start_time = mat.start_time();
        let stop_time = mat.stop_time();
        let name = std::path::Path::new(path)
            .file_stem()
            .map_or_else(String::new, |s| s.to_string_lossy().trim_end_matches("_res").to_owned());
        Ok(Dataset { name, vars, rows, n_cols, n_rows, params, start_time, stop_time })
    }

    /// `factor` times the rows, by repeating the trajectory: the same variable
    /// table over a larger payload.
    pub fn with_rows_scaled(&self, factor: usize) -> Dataset {
        let n_rows = self.n_rows * factor;
        let mut rows = Vec::with_capacity(n_rows * self.n_cols);
        let span = self.stop_time - self.start_time;
        for k in 0..factor {
            for r in 0..self.n_rows {
                let src = &self.rows[r * self.n_cols..(r + 1) * self.n_cols];
                rows.extend_from_slice(src);
                // Time has to stay monotone or an interpolating reader breaks.
                let t = rows.len() - self.n_cols;
                rows[t] = src[0] + span * k as f64;
            }
        }
        Dataset {
            name: format!("{} x{factor}", self.name),
            vars: self.vars.clone(),
            rows,
            n_cols: self.n_cols,
            n_rows,
            params: self.params.clone(),
            start_time: self.start_time,
            stop_time: self.start_time + span * factor as f64,
        }
    }
}

/// `"Simulation time [s]"` -> `("Simulation time", "s")`, the one place a `.mat`
/// description carries a unit.
fn split_unit(descr: &str) -> (&str, &str) {
    match (descr.strip_suffix(']').and_then(|d| d.rfind('[')), descr.ends_with(']')) {
        (Some(i), true) => (descr[..i].trim_end(), &descr[i + 1..descr.len() - 1]),
        _ => (descr, ""),
    }
}

struct Attr {
    unit: String,
    display_unit: String,
    ty: VarTy,
    discrete: bool,
}

/// The `<ScalarVariable>` table of an OpenModelica `_init.xml`, scanned for the
/// attributes a `.mat` cannot hold. Deliberately not a real XML parser: the file
/// is machine-written and only four attributes are wanted.
struct ModelAttrs(HashMap<String, Attr>);

impl ModelAttrs {
    fn get(&self, name: &str) -> Option<&Attr> {
        self.0.get(name)
    }

    /// `<model>_res.mat` -> `<model>_init.xml`; an empty table if it is absent.
    fn beside(mat_path: &str) -> ModelAttrs {
        let path = mat_path.strip_suffix("_res.mat").map(|p| format!("{p}_init.xml"));
        let Some(text) = path.and_then(|p| std::fs::read_to_string(p).ok()) else {
            return ModelAttrs(HashMap::new());
        };
        let mut map = HashMap::new();
        for chunk in text.split("<ScalarVariable").skip(1) {
            let Some(name) = attr(chunk, "name") else { continue };
            let variability = attr(chunk, "variability").unwrap_or_default();
            // The type element follows the ScalarVariable's own attributes.
            let ty = if chunk.contains("<Integer ") {
                VarTy::Integer
            } else if chunk.contains("<Boolean ") {
                VarTy::Boolean
            } else if chunk.contains("<String ") {
                VarTy::String
            } else if chunk.contains("<Enumeration ") {
                VarTy::Enumeration
            } else {
                VarTy::Real
            };
            let unit = attr(chunk, "unit").unwrap_or_default();
            let display_unit = attr(chunk, "displayUnit").unwrap_or_else(|| unit.clone());
            map.insert(
                name,
                Attr { unit, display_unit, ty, discrete: variability == "discrete" },
            );
        }
        ModelAttrs(map)
    }
}

fn attr(chunk: &str, key: &str) -> Option<String> {
    let pat = format!("{key}=\"");
    let at = chunk.find(&pat)? + pat.len();
    let end = chunk[at..].find('"')? + at;
    let raw = &chunk[at..end];
    Some(if raw.contains('&') { unescape(raw) } else { raw.to_owned() })
}

fn unescape(s: &str) -> String {
    s.replace("&quot;", "\"").replace("&apos;", "'").replace("&lt;", "<").replace("&gt;", ">").replace("&amp;", "&")
}
