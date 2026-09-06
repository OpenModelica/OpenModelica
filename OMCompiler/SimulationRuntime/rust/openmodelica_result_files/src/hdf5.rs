//! The two HDF5 formats behind [`ResultTable`], so everything built on the
//! `.mat` data model reads them too.
//!
//! Both keep the trajectories on disk and read a column when it is asked for,
//! which is what makes the read benchmark meaningful: opening a file costs the
//! metadata only. The `.mat`'s signed-index convention is preserved - a
//! positive `index` is a 1-based stored column, a negative one the same column
//! negated - so SDF, which has no aliases at all, only ever reports positive
//! indices, while MTSF maps its `negated` flag onto the sign.

#![allow(non_snake_case)]

use openmodelica_hdf5_result::{mtsf, sdf, VarTy};
use openmodelica_mat_reader::{find_closest_points, find_var_in, iws_cmp, MatVariable, ResultTable};

/// `(unit, displayUnit, type, relativeQuantity)` per `allInfo` entry.
type VarMeta = (String, String, &'static str, bool);

fn type_name(ty: VarTy) -> &'static str {
    match ty {
        VarTy::Real => "Real",
        VarTy::Integer => "Integer",
        VarTy::Boolean => "Boolean",
        VarTy::String => "String",
        VarTy::Enumeration => "enumeration",
    }
}

/// The columns already fetched, so a repeated read does not go back to HDF5.
#[derive(Default)]
struct Cache {
    cols: Vec<Option<Vec<f64>>>,
}

impl Cache {
    fn with_len(n: usize) -> Cache {
        Cache { cols: (0..n).map(|_| None).collect() }
    }
}

pub struct SdfReader {
    file: sdf::SdfFile,
    pub allInfo: Vec<MatVariable>,
    pub params: Vec<f64>,
    pub nrows: usize,
    pub nvar: usize,
    pub nparam: usize,
    /// `SdfFile::vars` index per 1-based stored column.
    columns: Vec<usize>,
    meta: Vec<VarMeta>,
    cache: Cache,
}

impl SdfReader {
    pub fn open(filename: &str) -> Result<SdfReader, String> {
        let file = sdf::SdfFile::open(filename)?;
        let mut allInfo = Vec::with_capacity(file.vars.len());
        let mut meta = Vec::with_capacity(file.vars.len());
        let mut params = Vec::new();
        let mut columns = Vec::new();

        // The dimension scale is column 1, as `time` is in a `.mat`.
        columns.push(file.time);
        for (i, v) in file.vars.iter().enumerate() {
            let (isParam, index) = match v.value {
                Some(value) => {
                    params.push(value);
                    (true, params.len() as i32)
                }
                None if i == file.time => (false, 1),
                None => {
                    columns.push(i);
                    (false, columns.len() as i32)
                }
            };
            allInfo.push(MatVariable { name: v.name.clone(), descr: v.comment.clone(), isParam, index });
            meta.push((v.unit.clone(), v.display_unit.clone(), type_name(v.ty), v.relative_quantity));
        }
        sort_by_name(&mut allInfo, &mut meta);

        let nvar = columns.len();
        let nparam = params.len();
        let nrows = file.n_rows;
        Ok(SdfReader { file, allInfo, params, nrows, nvar, nparam, columns, meta, cache: Cache::with_len(nvar) })
    }

    fn column(&mut self, col: usize) -> Option<&[f64]> {
        if self.cache.cols[col].is_none() {
            self.cache.cols[col] = self.file.read_column(self.columns[col]).ok();
        }
        self.cache.cols[col].as_deref()
    }

    /// SDF has no store to fetch in one piece: every variable is a dataset of
    /// its own, so reading n of them is n reads however they are asked for.
    fn prefetch(&mut self) {}
}

pub struct MtsfReader {
    file: mtsf::MtsfFile,
    pub allInfo: Vec<MatVariable>,
    pub params: Vec<f64>,
    pub nrows: usize,
    pub nvar: usize,
    pub nparam: usize,
    /// The `(matrix, column)` a 1-based stored column reads. Not a variable
    /// index: the first variable to mention a column may be a negated alias,
    /// and the stored values are never negated.
    columns: Vec<(usize, usize)>,
    meta: Vec<VarMeta>,
    cache: Cache,
}

impl MtsfReader {
    pub fn open(filename: &str) -> Result<MtsfReader, String> {
        let file = mtsf::MtsfFile::open(filename)?;
        let mut allInfo = Vec::with_capacity(file.vars.len());
        let mut meta = Vec::with_capacity(file.vars.len());
        let mut params = Vec::new();
        let mut columns: Vec<(usize, usize)> = Vec::new();
        // A matrix column is shared by a variable and its aliases, so number the
        // distinct (matrix, column) pairs rather than the variables.
        let mut stored: std::collections::HashMap<(usize, usize), i32> = std::collections::HashMap::new();
        let mut fixed: std::collections::HashMap<(usize, usize), i32> = std::collections::HashMap::new();

        // Read the Fixed matrices once: they are a single row each and every
        // parameter comes from them.
        let mut fixed_rows: std::collections::HashMap<usize, Vec<f64>> = std::collections::HashMap::new();
        for (m, info) in file.matrices.iter().enumerate() {
            if info.series == mtsf::Series::Fixed {
                fixed_rows.insert(m, file.read_row(m, 0).unwrap_or_default());
            }
        }

        for v in &file.vars {
            let is_fixed = file.matrices[v.matrix].series == mtsf::Series::Fixed;
            let key = (v.matrix, v.column);
            let index = if is_fixed {
                let slot = *fixed.entry(key).or_insert_with(|| {
                    let value = fixed_rows.get(&v.matrix).and_then(|r| r.get(v.column)).copied().unwrap_or(0.0);
                    params.push(value);
                    params.len() as i32
                });
                if v.negated { -slot } else { slot }
            } else {
                let slot = *stored.entry(key).or_insert_with(|| {
                    columns.push(key);
                    columns.len() as i32
                });
                if v.negated { -slot } else { slot }
            };
            allInfo.push(MatVariable { name: v.name.clone(), descr: v.comment.clone(), isParam: is_fixed, index });
            meta.push((v.unit.clone(), v.display_unit.clone(), type_name(v.ty), v.relative_quantity));
        }
        sort_by_name(&mut allInfo, &mut meta);

        let nvar = columns.len();
        let nparam = params.len();
        let nrows = file.n_rows;
        Ok(MtsfReader { file, allInfo, params, nrows, nvar, nparam, columns, meta, cache: Cache::with_len(nvar) })
    }

    fn column(&mut self, col: usize) -> Option<&[f64]> {
        if self.cache.cols[col].is_none() {
            let (matrix, column) = self.columns[col];
            self.cache.cols[col] = self.file.read_matrix_column(matrix, column).ok();
        }
        self.cache.cols[col].as_deref()
    }

    /// Read each time-variant matrix once and fill the cache from it.
    ///
    /// A hyperslab of one column has to visit every chunk that column crosses,
    /// so fetching n columns one at a time reads - and under gzip inflates -
    /// the same chunks n times: 18.5 s against 80 ms for the 298 columns of a
    /// deflated `Buildings` result. Any caller that wants more than a handful
    /// of columns should come through here; `read_all` does.
    pub fn prefetch(&mut self) {
        let mut blocks: std::collections::HashMap<usize, Vec<f64>> = std::collections::HashMap::new();
        for (slot, (matrix, column)) in self.columns.iter().enumerate() {
            if self.cache.cols[slot].is_some() {
                continue;
            }
            let m = &self.file.matrices[*matrix];
            if m.series == mtsf::Series::Fixed {
                continue;
            }
            let block = match blocks.entry(*matrix) {
                std::collections::hash_map::Entry::Occupied(e) => e.into_mut(),
                std::collections::hash_map::Entry::Vacant(e) => {
                    let Ok(b) = self.file.read_matrix(*matrix) else { continue };
                    e.insert(b)
                }
            };
            let n_cols = m.n_cols;
            self.cache.cols[slot] = Some((0..m.n_rows).map(|r| block[r * n_cols + column]).collect());
        }
    }
}

/// `find_var_in` binary-searches, so the table has to be in [`iws_cmp`] order;
/// `meta` rides along.
fn sort_by_name(allInfo: &mut Vec<MatVariable>, meta: &mut Vec<VarMeta>) {
    let mut order: Vec<usize> = (0..allInfo.len()).collect();
    order.sort_by(|a, b| iws_cmp(&allInfo[*a].name, &allInfo[*b].name));
    *allInfo = order.iter().map(|i| allInfo[*i].clone()).collect();
    *meta = order.iter().map(|i| meta[*i].clone()).collect();
}

macro_rules! result_table {
    ($reader:ident) => {
        impl ResultTable for $reader {
            fn all_info(&self) -> &[MatVariable] {
                &self.allInfo
            }
            fn params(&self) -> &[f64] {
                &self.params
            }
            fn nrows(&self) -> usize {
                self.nrows
            }
            fn nvar(&self) -> usize {
                self.nvar
            }
            fn nparam(&self) -> usize {
                self.nparam
            }
            fn find_var(&self, name: &str) -> Option<usize> {
                find_var_in(&self.allInfo, name)
            }
            fn read_vals(&mut self, index: i32) -> Option<Vec<f64>> {
                let col = index.unsigned_abs() as usize;
                if col == 0 || col > self.columns.len() {
                    return None;
                }
                let mut v = self.column(col - 1)?.to_vec();
                if index < 0 {
                    for x in &mut v {
                        *x = -*x;
                    }
                }
                Some(v)
            }
            fn val(&mut self, var_idx: usize, time: f64) -> Option<f64> {
                let info = self.allInfo.get(var_idx)?;
                let (isParam, index) = (info.isParam, info.index);
                if isParam {
                    let p = *self.params.get(index.unsigned_abs() as usize - 1)?;
                    return Some(if index < 0 { -p } else { p });
                }
                self.interp_val(index, time)
            }
            fn interp_val(&mut self, index: i32, time: f64) -> Option<f64> {
                let t = self.column(0)?.to_vec();
                let (i1, w1, i2, w2) = find_closest_points(time, &t);
                if i1 < 0 || i2 < 0 {
                    return None;
                }
                let col = index.unsigned_abs() as usize;
                if col == 0 || col > self.columns.len() {
                    return None;
                }
                let v = self.column(col - 1)?;
                let y = w1 * v[i1 as usize] + w2 * v[i2 as usize];
                Some(if index < 0 { -y } else { y })
            }
            fn start_time(&mut self) -> f64 {
                self.column(0).and_then(|t| t.first().copied()).unwrap_or(0.0)
            }
            fn stop_time(&mut self) -> f64 {
                self.column(0).and_then(|t| t.last().copied()).unwrap_or(0.0)
            }
            fn read_all(&mut self) -> bool {
                self.prefetch();
                for c in 0..self.columns.len() {
                    if self.column(c).is_none() {
                        return false;
                    }
                }
                true
            }
            fn unit(&self, idx: usize) -> (&str, &str) {
                self.meta.get(idx).map_or(("", ""), |m| (m.0.as_str(), m.1.as_str()))
            }
            fn var_type(&self, idx: usize) -> &str {
                self.meta.get(idx).map_or("Real", |m| m.2)
            }
            fn relative_quantity(&self, idx: usize) -> bool {
                self.meta.get(idx).is_some_and(|m| m.3)
            }
        }
    };
}

result_table!(SdfReader);
result_table!(MtsfReader);
