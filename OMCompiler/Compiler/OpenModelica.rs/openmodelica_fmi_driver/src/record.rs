//! Sampling an FMU's variables and writing the result file.
//!
//! The columns are chosen the way a plot wants them: every numeric variable
//! that can change, grouped by type so one `fmi3Get*` call fetches a whole
//! group. Parameters and constants are read once, after initialization, and go
//! into the `.mat`'s time-invariant half — the same layout a simulated
//! OpenModelica model writes, so OMPlot and `omc-diff` read an FMU run
//! unchanged. An alias (an FMI 3.0 `<Alias>` child, or an FMI 1.0 `alias`
//! variable) shares its variable's column.

use crate::api::Fmi3;
use crate::{Error, Result};
use openmodelica_fmi::{
    Alias, Causality, Dimension, ModelDescription, VarType, Variability, Variable,
};
use openmodelica_mat_writer as mat;
use std::collections::HashMap;

pub struct Column {
    pub name: String,
    pub description: String,
    pub unit: Option<String>,
    pub causality: Causality,
    /// A continuous state (something differentiates it).
    pub is_state: bool,
}

/// Variables of one type, fetched together. An array variable is one value
/// reference but several values, so the columns it fills are a span.
struct Group {
    ty: VarType,
    vrs: Vec<u32>,
    /// Per value reference, where its first value lands (a column index inside
    /// a row, 1-based; 0 is time) and how many values it has.
    spans: Vec<(usize, usize)>,
    /// Total values the FMU returns for `vrs`.
    n_values: usize,
}

pub struct Recorder {
    pub columns: Vec<Column>,
    groups: Vec<Group>,
    /// Row-major, `1 + columns.len()` values per row, starting with the time.
    rows: Vec<f64>,
    /// The time-invariant signals, and their values once initialization is over.
    parameters: Vec<(String, String, f64)>,
    param_groups: Vec<Group>,
    /// Aliases: `(name, description, column of the variable it aliases, negated)`.
    aliases: Vec<(String, String, usize, bool)>,
    /// Aliases of parameters: `(name, description, index into `parameters`, negated)`.
    param_aliases: Vec<(String, String, usize, bool)>,
    scratch: Vec<f64>,
}

/// A variable worth sampling: numeric, not an alias, and able to change.
fn is_recorded(v: &Variable) -> bool {
    v.ty.is_numeric()
        && v.alias == Alias::NoAlias
        && v.causality != Causality::Independent
        && !matches!(v.variability, Variability::Constant | Variability::Fixed)
        && v.causality != Causality::Parameter
        && v.causality != Causality::StructuralParameter
}

/// A variable that keeps one value for the whole run.
fn is_parameter(v: &Variable) -> bool {
    v.ty.is_numeric() && v.alias == Alias::NoAlias && v.causality != Causality::Independent && !is_recorded(v)
}

/// The FMI 1.0 alias variables by the value reference they share.
fn fmi1_aliases(md: &ModelDescription) -> HashMap<u32, Vec<&Variable>> {
    let mut map: HashMap<u32, Vec<&Variable>> = HashMap::new();
    for a in md.variables.iter().filter(|a| a.alias != Alias::NoAlias) {
        map.entry(a.value_reference).or_default().push(a);
    }
    map
}

/// `(name, description, negated)` for the names of `v` and its aliases the filter
/// keeps; the first names the column (the variable's own, else a non-negated
/// alias), the rest alias it. `None` when the filter keeps none.
fn names_kept<'a>(
    v: &'a Variable,
    fmi1: &HashMap<u32, Vec<&'a Variable>>,
    keep: &dyn Fn(&str) -> bool,
) -> Option<Vec<(&'a str, &'a str, bool)>> {
    let mut names: Vec<(&str, &str, bool)> = Vec::new();
    if keep(&v.name) {
        names.push((&v.name, v.description.as_deref().unwrap_or_default(), false));
    }
    names.extend(
        v.aliases
            .iter()
            .filter(|a| keep(&a.name))
            .map(|a| (a.name.as_str(), a.description.as_deref().unwrap_or_default(), false)),
    );
    names.extend(
        fmi1.get(&v.value_reference)
            .into_iter()
            .flatten()
            .filter(|a| a.ty == v.ty && keep(&a.name))
            .map(|a| (a.name.as_str(), a.description.as_deref().unwrap_or_default(), a.alias == Alias::NegatedAlias)),
    );
    // A negated alias cannot name the column: it would carry the wrong sign.
    let column = names.iter().position(|(_, _, negated)| !negated)?;
    names.swap(0, column);
    Some(names)
}

fn group_by_type(vars: &[(&Variable, usize, usize)]) -> Vec<Group> {
    let mut groups: Vec<Group> = Vec::new();
    for (v, col, len) in vars {
        let ty = v.ty.wire();
        match groups.iter_mut().find(|g| g.ty == ty) {
            Some(g) => {
                g.vrs.push(v.value_reference);
                g.spans.push((*col, *len));
                g.n_values += len;
            }
            None => groups.push(Group {
                ty,
                vrs: vec![v.value_reference],
                spans: vec![(*col, *len)],
                n_values: *len,
            }),
        }
    }
    groups
}

/// The extent of each of a variable's dimensions. A dimension given by a value
/// reference is a structural parameter, whose start value is the extent — the
/// FMU is not instantiated yet when the columns are laid out.
fn extents(md: &ModelDescription, v: &Variable) -> Vec<usize> {
    v.dimensions
        .iter()
        .map(|d| match d {
            Dimension::Fixed(k) => *k as usize,
            Dimension::ValueReference(vr) => md
                .variable_by_vr(*vr)
                .and_then(|s| s.start.as_ref())
                .and_then(|s| s.first_f64())
                .unwrap_or(1.0) as usize,
        })
        .collect()
}

/// `a` for a scalar, `a[1]`, `a[2,3]`, … for the elements of an array, in the
/// row-major order FMI flattens them in.
fn element_names(name: &str, dimensions: &[usize]) -> Vec<String> {
    if dimensions.is_empty() {
        return vec![name.to_string()];
    }
    let mut out = vec![String::new()];
    for extent in dimensions {
        out = out
            .iter()
            .flat_map(|prefix| {
                (1..=*extent).map(move |i| {
                    if prefix.is_empty() { i.to_string() } else { format!("{prefix},{i}") }
                })
            })
            .collect();
    }
    out.into_iter().map(|index| format!("{name}[{index}]")).collect()
}

impl Recorder {
    pub fn new(md: &ModelDescription, keep: Option<&dyn Fn(&str) -> bool>) -> Recorder {
        // Dropped here, not at write time: the sampling is the cost.
        let keep = |name: &str| keep.is_none_or(|k| k(name));
        let states: Vec<u32> = md.continuous_states();
        let mut columns = Vec::new();
        let mut recorded = Vec::new();
        let mut aliases = Vec::new();
        let fmi1 = fmi1_aliases(md);
        for v in md.variables.iter().filter(|v| is_recorded(v)) {
            let Some(names) = names_kept(v, &fmi1, &keep) else { continue };
            let (name, description, _) = names[0];
            let extents = extents(md, v);
            let first = columns.len() + 1; // column 0 is time
            for element in element_names(name, &extents) {
                columns.push(Column {
                    name: element,
                    description: description.to_string(),
                    unit: v.unit.clone(),
                    causality: v.causality,
                    is_state: states.contains(&v.value_reference),
                });
            }
            for (alias, description, negated) in &names[1..] {
                for (k, element) in element_names(alias, &extents).into_iter().enumerate() {
                    aliases.push((element, description.to_string(), first + k, *negated));
                }
            }
            recorded.push((v, first, columns.len() + 1 - first));
        }
        let mut parameters = Vec::new();
        let mut param_aliases = Vec::new();
        let mut params = Vec::new();
        for v in md.variables.iter().filter(|v| is_parameter(v)) {
            let Some(names) = names_kept(v, &fmi1, &keep) else { continue };
            let (name, description, _) = names[0];
            let extents = extents(md, v);
            let first = parameters.len();
            let starts = match &v.start {
                Some(openmodelica_fmi::Start::Reals(r)) => r.clone(),
                Some(openmodelica_fmi::Start::Ints(i)) => i.iter().map(|v| *v as f64).collect(),
                Some(openmodelica_fmi::Start::Bools(b)) => {
                    b.iter().map(|v| *v as u8 as f64).collect()
                }
                _ => Vec::new(),
            };
            for (k, element) in element_names(name, &extents).into_iter().enumerate() {
                parameters.push((element, description.to_string(), starts.get(k).copied().unwrap_or(0.0)));
            }
            for (alias, description, negated) in &names[1..] {
                for (k, element) in element_names(alias, &extents).into_iter().enumerate() {
                    param_aliases.push((element, description.to_string(), first + k, *negated));
                }
            }
            params.push((v, first, parameters.len() - first));
        }
        let n_values = columns.len();
        Recorder {
            groups: group_by_type(&recorded),
            param_groups: group_by_type(&params),
            columns,
            rows: Vec::new(),
            parameters,
            aliases,
            param_aliases,
            scratch: vec![0.0; n_values.max(1)],
        }
    }

    pub fn len(&self) -> usize {
        let width = self.columns.len() + 1;
        if width == 0 { 0 } else { self.rows.len() / width }
    }

    pub fn is_empty(&self) -> bool {
        self.rows.is_empty()
    }

    /// The time-invariant signals and the values they were read with, for a
    /// host that shows them beside the plot.
    pub fn parameters(&self) -> impl Iterator<Item = (&str, f64)> {
        self.parameters.iter().map(|(name, _, value)| (name.as_str(), *value))
    }

    /// The samples as they are stored: `stride()` values per row, the time
    /// first. A host that plots reads them here rather than copying columns.
    pub fn raw(&self) -> &[f64] {
        &self.rows
    }

    pub fn stride(&self) -> usize {
        self.columns.len() + 1
    }

    pub fn times(&self) -> impl Iterator<Item = f64> + '_ {
        self.rows.chunks(self.columns.len() + 1).map(|r| r[0])
    }

    pub fn values(&self, column: usize) -> impl Iterator<Item = f64> + '_ {
        self.rows.chunks(self.columns.len() + 1).map(move |r| r[column + 1])
    }

    /// Read every recorded variable at `time` and append a row.
    pub fn sample(&mut self, inst: &mut dyn Fmi3, time: f64) -> Result<()> {
        let base = self.rows.len();
        self.rows.resize(base + self.columns.len() + 1, 0.0);
        self.rows[base] = time;
        for g in &self.groups {
            let out = &mut self.scratch[..g.n_values];
            inst.get_numeric(g.ty, &g.vrs, out)?;
            let mut k = 0;
            for (col, len) in &g.spans {
                self.rows[base + col..base + col + len].copy_from_slice(&out[k..k + len]);
                k += len;
            }
        }
        Ok(())
    }

    /// Read the parameters and constants, which FMI only lets a master see once
    /// the FMU has been initialized.
    pub fn snapshot_parameters(&mut self, inst: &mut dyn Fmi3) -> Result<()> {
        for g in &self.param_groups {
            let mut out = vec![0.0; g.n_values];
            // A parameter the FMU refuses to hand out keeps its start value
            // rather than failing the run.
            if inst.get_numeric(g.ty, &g.vrs, &mut out).is_err() {
                continue;
            }
            let mut k = 0;
            for (slot, len) in &g.spans {
                for j in 0..*len {
                    self.parameters[slot + j].2 = out[k + j];
                }
                k += len;
            }
        }
        Ok(())
    }

    /// Serialize as the MATLAB v4 result file the OpenModelica tools read.
    pub fn to_mat(&self, start_time: f64, stop_time: f64) -> Vec<u8> {
        let mut signals = vec![mat::MatVar {
            name: "time",
            comment: "Simulation time [s]",
            kind: mat::MatKind::Time,
        }];
        for (i, c) in self.columns.iter().enumerate() {
            signals.push(mat::MatVar {
                name: &c.name,
                comment: &c.description,
                kind: mat::MatKind::Column { col: i as u32 + 1, negate: mat::Neg::None },
            });
        }
        for (name, description, col, negated) in &self.aliases {
            signals.push(mat::MatVar {
                name,
                comment: description,
                kind: mat::MatKind::Column {
                    col: *col as u32,
                    negate: if *negated { mat::Neg::Arith } else { mat::Neg::None },
                },
            });
        }
        let mut params: Vec<f64> = Vec::with_capacity(self.parameters.len() + self.param_aliases.len());
        for (name, description, value) in &self.parameters {
            signals.push(mat::MatVar {
                name,
                comment: description,
                kind: mat::MatKind::Param { negate: mat::Neg::None },
            });
            params.push(*value);
        }
        for (name, description, index, negated) in &self.param_aliases {
            signals.push(mat::MatVar {
                name,
                comment: description,
                kind: mat::MatKind::Param { negate: if *negated { mat::Neg::Arith } else { mat::Neg::None } },
            });
            params.push(self.parameters[*index].2);
        }
        mat::write_mat4(
            &signals,
            start_time,
            stop_time,
            &self.rows,
            self.columns.len() as u32 + 1,
            &params,
            // An FMU recording has no String channel.
            &[],
            mat::Precision::Double,
        )
    }

    /// Write the result file. On the web this goes through WASI like every other
    /// file the simulation writes.
    pub fn write_mat(&self, path: &std::path::Path, start_time: f64, stop_time: f64) -> Result<()> {
        std::fs::write(path, self.to_mat(start_time, stop_time))
            .map_err(|e| Error::Io(format!("{}: {e}", path.display())))
    }
}
