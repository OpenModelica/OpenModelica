//! SDF, the Scientific Data Format (<https://github.com/ScientificDataFormat/SDF>).
//!
//! Every variable is a dataset of its own, in a group tree built from the dotted
//! Modelica name, exactly as `sdf.dsres` converts a Dymola/OpenModelica `.mat`:
//! a trajectory is 1-D over the time scale, a parameter or an `unvarying`
//! signal is a scalar. The variable's metadata rides on the dataset as the
//! `COMMENT` / `NAME` / `UNIT` / `DISPLAY_UNIT` / `RELATIVE_QUANTITY`
//! attributes.
//!
//! `time` is an HDF5 dimension scale. The HL library's `H5DSattach_scale`
//! rewrites the scale's `REFERENCE_LIST` once per attached dataset, which is
//! quadratic in the variable count, so the two attributes of the convention are
//! written directly instead: a `DIMENSION_LIST` on each dataset as it is
//! created, and one `REFERENCE_LIST` on `time` at [`SdfStream::finish`].
//!
//! An alias gets a dataset of its own with the transform already applied - SDF
//! has no way to say "this is -x".

use std::collections::HashMap;

use hdf5_metno_sys::h5r::hobj_ref_t;

use crate::h5::{self, Attrs, Dataset, File, Group, Layout, Loc, Type};
use crate::{Kind, Meta, Options, Var, VarTy};

/// The `hvl_t` of a variable-length sequence, which is how a `DIMENSION_LIST`
/// attribute stores its per-dimension list of references.
#[repr(C)]
#[derive(Clone, Copy)]
struct Hvl {
    len: usize,
    p: *mut std::ffi::c_void,
}

/// One `REFERENCE_LIST` entry: an attached dataset and the dimension it uses.
#[repr(C)]
#[derive(Clone, Copy)]
struct RefListEntry {
    dataset: hobj_ref_t,
    index: u32,
}

struct Trajectory {
    ds: Dataset,
    col: usize,
    scale: f64,
    offset: f64,
    ty: VarTy,
    /// The `/`-path, for the `REFERENCE_LIST` written at finish.
    path: String,
}

pub struct SdfStream {
    file: File,
    /// Kept alive so the datasets under them stay valid.
    groups: HashMap<String, Group>,
    time: Dataset,
    traj: Vec<Trajectory>,
    n_reals: usize,
    n_rows: usize,
    /// Row-major, `n_reals` wide.
    pending: Vec<f64>,
    block_rows: usize,
    /// Rows the datasets are currently sized for; the writer only extends past
    /// what `expected_rows` reserved.
    extent: u64,
    single: bool,
    finished: bool,
}

impl SdfStream {
    /// Create the file and every dataset. `params` holds the `Param` values in
    /// `vars` order, `first_row` the initial result row (which gives the
    /// `unvarying` signals their scalar value).
    #[allow(clippy::too_many_arguments)]
    pub fn begin(
        path: &str,
        vars: &[Var],
        params: &[f64],
        first_row: &[f64],
        n_reals: u32,
        meta: &Meta,
        opts: &Options,
    ) -> Result<SdfStream, String> {
        h5::init();
        let file = File::create(path)?;
        file.attr_str("COMMENT", meta.description)?;
        file.attr_str("SDF_VERSION", "1.0")?;
        file.attr_str("GENERATION_TOOL", meta.generation_tool)?;

        let n_reals = n_reals.max(1) as usize;
        let layout = Layout {
            chunk: Some([opts.chunk_height() as u64, 1]),
            deflate: opts.deflate,
            shuffle: opts.shuffle,
        };
        // A chunked dataset allocates its chunks as they are written whatever
        // extent it declares, so a known length costs nothing here and saves an
        // `H5Dset_extent` per dataset per block - 8763 of them on FullRobot.
        let rows0 = opts.expected_rows.unwrap_or(0) as u64;
        let mut groups: HashMap<String, Group> = HashMap::new();
        let mut traj = Vec::new();
        let mut time = None;
        let mut next_param = 0usize;

        for v in vars {
            // Neither writer stores text yet; a String signal is dropped as the
            // numeric formats drop it, but it still owns its `params` slot.
            if v.ty == VarTy::String {
                next_param += usize::from(matches!(v.kind, Kind::Param { .. }));
                continue;
            }
            let (group, leaf) = match v.name.rfind('.') {
                Some(i) => (&v.name[..i], &v.name[i + 1..]),
                None => ("", v.name),
            };
            let parent = ensure_group(&file, &mut groups, group)?;
            let full = if group.is_empty() {
                format!("/{leaf}")
            } else {
                format!("/{}/{leaf}", group.replace('.', "/"))
            };

            let (scalar, value) = match v.kind {
                Kind::Const { value } => (true, value),
                Kind::Param { affine } => {
                    let p = params.get(next_param).copied().unwrap_or(0.0);
                    next_param += 1;
                    (true, affine.apply(p))
                }
                Kind::Column { col, affine } if v.unvarying => {
                    (true, affine.apply(first_row.get(col as usize).copied().unwrap_or(0.0)))
                }
                Kind::Time | Kind::Column { .. } => (false, 0.0),
            };

            let ds = if scalar {
                let ty = elem_type(v.ty, opts.single);
                let d = Dataset::create(parent, leaf, &ty, &[], None, Layout::CONTIGUOUS)?;
                write_scalar(&d, v.ty, opts.single, value)?;
                d
            } else {
                let ty = elem_type(v.ty, opts.single);
                Dataset::create(parent, leaf, &ty, &[rows0], Some(&[u64::MAX]), layout)?
            };
            write_attrs(&ds, v)?;

            match v.kind {
                Kind::Time => {
                    ds.attr_str("CLASS", "DIMENSION_SCALE")?;
                    ds.attr_str("NAME", v.name)?;
                    time = Some((ds, full));
                }
                Kind::Column { col, affine } if !scalar => {
                    traj.push(Trajectory {
                        ds,
                        col: col as usize,
                        scale: affine.scale,
                        offset: affine.offset,
                        ty: v.ty,
                        path: full,
                    });
                }
                _ => {}
            }
        }

        let (time, time_path) = time.ok_or("SDF: the variable list has no time")?;
        // The per-dataset half of the scale convention.
        let time_ref = time.reference(&file, &time_path)?;
        let ref_ty = Type::obj_ref();
        let vlen_ref = vlen_of(&ref_ty)?;
        for t in &traj {
            let mut one = [time_ref];
            let vl = [Hvl { len: 1, p: one.as_mut_ptr().cast() }];
            t.ds.attr_array("DIMENSION_LIST", &vlen_ref, &vl)?;
        }

        Ok(SdfStream {
            file,
            groups,
            time,
            traj,
            n_reals,
            n_rows: 0,
            pending: Vec::new(),
            block_rows: opts.chunk_rows.max(1),
            extent: rows0,
            single: opts.single,
            finished: false,
        })
    }

    /// Append `rows` (row-major, `n_reals` values each).
    pub fn push_rows(&mut self, rows: &[f64]) -> Result<(), String> {
        self.pending.extend_from_slice(rows);
        while self.pending.len() / self.n_reals >= self.block_rows {
            self.flush_block(self.block_rows)?;
        }
        Ok(())
    }

    fn flush_block(&mut self, n: usize) -> Result<(), String> {
        let take = n * self.n_reals;
        let start = self.n_rows as u64;
        let end = start + n as u64;

        let grow = end > self.extent;
        let mut col = vec![0.0f64; n];
        for (r, v) in col.iter_mut().enumerate() {
            *v = self.pending[r * self.n_reals];
        }
        if grow {
            self.time.set_extent(&[end])?;
        }
        self.time.write_slab(&Type::f64(), &[start], &[n as u64], &col)?;

        for t in &self.traj {
            for (r, v) in col.iter_mut().enumerate() {
                *v = t.scale * self.pending[r * self.n_reals + t.col] + t.offset;
            }
            if grow {
                t.ds.set_extent(&[end])?;
            }
            write_column(&t.ds, t.ty, self.single, &[start], &[n as u64], &col)?;
        }
        self.extent = self.extent.max(end);

        self.pending.drain(..take);
        self.n_rows += n;
        Ok(())
    }

    /// Flush the last block and attach the scale. Idempotent.
    pub fn finish(&mut self) -> Result<(), String> {
        if self.finished {
            return Ok(());
        }
        self.finished = true;
        let n = self.pending.len() / self.n_reals;
        if n > 0 {
            self.flush_block(n)?;
        }
        // A run that stopped early leaves the reserved rows unwritten.
        if self.extent > self.n_rows as u64 {
            self.time.set_extent(&[self.n_rows as u64])?;
            for t in &self.traj {
                t.ds.set_extent(&[self.n_rows as u64])?;
            }
        }
        // The other half of the dimension-scale convention, written once rather
        // than rewritten per attached dataset as H5DSattach_scale would.
        let entries: Vec<RefListEntry> = self
            .traj
            .iter()
            .map(|t| Ok(RefListEntry { dataset: t.ds.reference(&self.file, &t.path)?, index: 0 }))
            .collect::<Result<_, String>>()?;
        if !entries.is_empty() {
            let ty = Type::compound(
                size_of::<RefListEntry>(),
                &[("dataset", 0, &Type::obj_ref()), ("index", size_of::<hobj_ref_t>(), &Type::i32())],
            )?;
            self.time.attr_array("REFERENCE_LIST", &ty, &entries)?;
        }
        self.groups.clear();
        Ok(())
    }

    pub fn n_rows(&self) -> usize {
        self.n_rows
    }
}

/// SDF stores a Boolean or an Integer as `int32`.
fn elem_type(ty: VarTy, single: bool) -> Type {
    match ty {
        VarTy::Real if single => Type::f32(),
        VarTy::Real => Type::f64(),
        _ => Type::i32(),
    }
}

fn write_scalar(ds: &Dataset, ty: VarTy, single: bool, value: f64) -> Result<(), String> {
    match ty {
        VarTy::Real if single => ds.write_all(&Type::f32(), &[value as f32]),
        VarTy::Real => ds.write_all(&Type::f64(), &[value]),
        _ => ds.write_all(&Type::i32(), &[value as i32]),
    }
}

fn write_column(ds: &Dataset, ty: VarTy, single: bool, start: &[u64], count: &[u64], col: &[f64]) -> Result<(), String> {
    match ty {
        VarTy::Real if single => {
            let v: Vec<f32> = col.iter().map(|x| *x as f32).collect();
            ds.write_slab(&Type::f32(), start, count, &v)
        }
        VarTy::Real => ds.write_slab(&Type::f64(), start, count, col),
        _ => {
            let v: Vec<i32> = col.iter().map(|x| *x as i32).collect();
            ds.write_slab(&Type::i32(), start, count, &v)
        }
    }
}

fn write_attrs(ds: &Dataset, v: &Var) -> Result<(), String> {
    if !v.comment.is_empty() {
        ds.attr_str("COMMENT", v.comment)?;
    }
    if !v.unit.is_empty() {
        ds.attr_str("UNIT", v.unit)?;
    }
    if !v.display_unit.is_empty() && v.display_unit != v.unit {
        ds.attr_str("DISPLAY_UNIT", v.display_unit)?;
    }
    if v.relative_quantity {
        ds.attr_str("RELATIVE_QUANTITY", "TRUE")?;
    }
    Ok(())
}

/// Create the group chain for a dotted prefix, caching each level.
fn ensure_group<'a>(
    file: &'a File,
    groups: &'a mut HashMap<String, Group>,
    dotted: &str,
) -> Result<&'a dyn Loc, String> {
    if dotted.is_empty() {
        return Ok(file);
    }
    if !groups.contains_key(dotted) {
        let mut prefix = String::new();
        for segment in dotted.split('.') {
            if !prefix.is_empty() {
                prefix.push('.');
            }
            prefix.push_str(segment);
            if !groups.contains_key(&prefix) {
                let path = format!("/{}", prefix.replace('.', "/"));
                let g = Group::create(file, &path)?;
                groups.insert(prefix.clone(), g);
            }
        }
    }
    Ok(groups.get(dotted).expect("just created"))
}

/// `H5Tvlen_create(base)`: the element type of a `DIMENSION_LIST`.
fn vlen_of(base: &Type) -> Result<Type, String> {
    let id = unsafe { hdf5_metno_sys::h5t::H5Tvlen_create(base.id()) };
    if id < 0 { Err("HDF5: H5Tvlen_create failed".into()) } else { Ok(Type::from_raw(id)) }
}

/// An opened SDF file: the group tree walked once into a flat variable list,
/// the trajectories left on disk.
pub struct SdfFile {
    file: File,
    pub vars: Vec<Info>,
    pub n_rows: usize,
    /// Index into `vars` of the dimension scale.
    pub time: usize,
}

pub struct Info {
    pub name: String,
    pub comment: String,
    pub unit: String,
    pub display_unit: String,
    pub relative_quantity: bool,
    pub ty: VarTy,
    pub path: String,
    /// A scalar dataset - a parameter, a constant or an `unvarying` signal.
    pub value: Option<f64>,
}

impl SdfFile {
    /// Walk the whole tree. Every scalar is read here, since a caller asking for
    /// the parameters wants them all; the trajectories are not touched.
    pub fn open(path: &str) -> Result<SdfFile, String> {
        h5::init();
        let file = File::open_ro(path)?;
        let mut vars = Vec::new();
        let root = Group::open(&file, "/")?;
        walk(&root, "", "", &mut vars)?;
        let time = vars
            .iter()
            .position(|v| v.value.is_none() && is_scale(&file, &v.path))
            .or_else(|| vars.iter().position(|v| v.name == "time" || v.name == "Time"))
            .ok_or("SDF: no dimension scale")?;
        let n_rows = Dataset::open(&file, &vars[time].path)?.space()?.dims().map(|d| d[0] as usize)?;
        Ok(SdfFile { file, vars, n_rows, time })
    }

    pub fn read_column(&self, idx: usize) -> Result<Vec<f64>, String> {
        let info = self.vars.get(idx).ok_or("SDF: no such variable")?;
        if let Some(v) = info.value {
            return Ok(vec![v; self.n_rows]);
        }
        let ds = Dataset::open(&self.file, &info.path)?;
        let n = ds.space()?.dims()?.first().copied().unwrap_or(0) as usize;
        let mut out = vec![0.0f64; n];
        // H5Dread converts, so ask for f64 whatever the dataset stores.
        ds.read_all(&Type::f64(), &mut out)?;
        Ok(out)
    }
}

fn is_scale(file: &File, path: &str) -> bool {
    Dataset::open(file, path).ok().and_then(|d| d.read_attr_str("CLASS")).as_deref() == Some("DIMENSION_SCALE")
}

/// Depth-first over the group tree, rebuilding the dotted Modelica name.
fn walk(group: &Group, prefix: &str, path: &str, out: &mut Vec<Info>) -> Result<(), String> {
    for (name, kind) in group.links()? {
        let dotted = if prefix.is_empty() { name.clone() } else { format!("{prefix}.{name}") };
        let full = format!("{path}/{name}");
        match kind {
            h5::LinkKind::Group => {
                let g = Group::open(group, &name)?;
                walk(&g, &dotted, &full, out)?;
            }
            h5::LinkKind::Dataset => {
                let ds = Dataset::open(group, &name)?;
                let dims = ds.space()?.dims()?;
                let ty = match Type::of_dataset(&ds)?.class() {
                    hdf5_metno_sys::h5t::H5T_class_t::H5T_INTEGER => VarTy::Integer,
                    _ => VarTy::Real,
                };
                let value = if dims.is_empty() {
                    let mut v = [0.0f64];
                    ds.read_all(&Type::f64(), &mut v)?;
                    Some(v[0])
                } else {
                    None
                };
                let unit = ds.read_attr_str("UNIT").unwrap_or_default();
                out.push(Info {
                    name: dotted,
                    comment: ds.read_attr_str("COMMENT").unwrap_or_default(),
                    display_unit: ds.read_attr_str("DISPLAY_UNIT").unwrap_or_else(|| unit.clone()),
                    unit,
                    relative_quantity: ds.read_attr_str("RELATIVE_QUANTITY").as_deref() == Some("TRUE"),
                    ty,
                    path: full,
                    value,
                });
            }
            h5::LinkKind::Other => {}
        }
    }
    Ok(())
}
