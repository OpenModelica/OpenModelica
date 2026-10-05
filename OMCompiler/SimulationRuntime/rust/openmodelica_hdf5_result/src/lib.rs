//! The two HDF5 result-file formats, as writers shaped like
//! `openmodelica_mat_writer` and `openmodelica_arrow_writer`:
//!
//! * [`sdf`] - SDF, the Scientific Data Format: one 1-D dataset per variable in
//!   a group tree mirroring the dotted Modelica name, `time` a dimension scale.
//! * [`mtsf`] - the Modelica Trajectory Storage Format: a `/ModelDescription`
//!   variable table plus one 2-D matrix per (series, element type) under
//!   `/Results`, so a variable is a column index into a shared matrix.
//!
//! Unlike the `.mat` and `.arrow` writers these own their file: HDF5 seeks and
//! rewrites, so there is no byte sink to hand the caller. Everything is behind
//! the `library` feature; without it the crate is empty and needs no HDF5.

#[cfg(feature = "library")]
pub mod h5;
#[cfg(feature = "library")]
pub mod mtsf;
#[cfg(feature = "library")]
pub mod sdf;

#[cfg(feature = "library")]
pub use mtsf::MtsfStream;
#[cfg(feature = "library")]
pub use sdf::SdfStream;

/// `scale * value + offset`.
#[derive(Clone, Copy, Debug)]
pub struct Affine {
    pub scale: f64,
    pub offset: f64,
}

impl Affine {
    pub const IDENTITY: Affine = Affine { scale: 1.0, offset: 0.0 };

    pub fn negated() -> Affine {
        Affine { scale: -1.0, offset: 0.0 }
    }

    pub fn apply(self, v: f64) -> f64 {
        self.scale * v + self.offset
    }

    pub fn is_identity(self) -> bool {
        self.scale == 1.0 && self.offset == 0.0
    }
}

impl Default for Affine {
    fn default() -> Affine {
        Affine::IDENTITY
    }
}

/// Picks the MTSF category and the SDF dataset element type.
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug, Default)]
pub enum VarTy {
    #[default]
    Real,
    Integer,
    Boolean,
    String,
    Enumeration,
}

impl VarTy {
    /// MTSF `/ModelDescription/SimpleTypes.dataType`.
    pub fn mtsf_code(self) -> u8 {
        match self {
            VarTy::Real => 1,
            VarTy::Integer => 2,
            VarTy::Boolean => 3,
            VarTy::String => 4,
            VarTy::Enumeration => 5,
        }
    }

    /// The `/Results/<series>` dataset this variable's column lives in.
    pub fn category(self) -> &'static str {
        match self {
            VarTy::Real => "H5T_NATIVE_DOUBLE",
            VarTy::Integer | VarTy::Enumeration => "H5T_NATIVE_INT32",
            VarTy::Boolean => "H5T_NATIVE_INT8",
            VarTy::String => "H5T_C_S1",
        }
    }

    pub fn name(self) -> &'static str {
        match self {
            VarTy::Real => "Real",
            VarTy::Integer => "Integer",
            VarTy::Boolean => "Boolean",
            VarTy::String => "String",
            VarTy::Enumeration => "Enumeration",
        }
    }
}

/// Where a signal's value comes from. Mirrors `ArrowKind`/`MatKind`.
#[derive(Clone, Copy, Debug)]
pub enum Kind {
    Time,
    /// Result-row column `col` (0 = time), transformed by `affine`.
    Column { col: u32, affine: Affine },
    /// From the `params` slice, in `Param` order.
    Param { affine: Affine },
    Const { value: f64 },
}

/// One result variable; the strings borrow the caller's.
pub struct Var<'a> {
    pub name: &'a str,
    pub comment: &'a str,
    pub unit: &'a str,
    pub display_unit: &'a str,
    /// FMI's `relativeQuantity`: a unit conversion scales it but adds no offset.
    pub relative_quantity: bool,
    pub ty: VarTy,
    /// MTSF puts a discrete-time signal in its `Discrete` series.
    pub discrete: bool,
    pub kind: Kind,
    /// C's `time_unvarying`: computed once at initialization, so it is stored
    /// as a time-invariant value.
    pub unvarying: bool,
}

impl Default for Var<'_> {
    fn default() -> Var<'static> {
        Var {
            name: "",
            comment: "",
            unit: "",
            display_unit: "",
            relative_quantity: false,
            ty: VarTy::Real,
            discrete: false,
            kind: Kind::Const { value: 0.0 },
            unvarying: false,
        }
    }
}

#[derive(Clone, Copy, Debug)]
pub struct Options {
    /// MTSF's reference writer deflates, SDF's does not.
    pub deflate: Option<u8>,
    /// The byte-shuffle filter ahead of deflate.
    pub shuffle: bool,
    /// Rows per chunk, and the number of rows buffered before a write.
    pub chunk_rows: usize,
    /// How many rows the run will produce, when the caller knows (OpenModelica
    /// knows `numberOfIntervals`). An unfilled HDF5 chunk still occupies its
    /// whole size in the file, so without this a 1024-row chunk on a 565-row
    /// run stores 45% padding.
    pub expected_rows: Option<usize>,
    /// Columns per chunk of an MTSF matrix; 0 = the whole matrix. Narrow chunks
    /// cost more chunks but let a reader fetch one variable without inflating
    /// its neighbours.
    pub chunk_cols: usize,
    /// The `-single` flag.
    pub single: bool,
}

impl Options {
    /// The chunk height to use, never taller than the run.
    pub fn chunk_height(&self) -> usize {
        self.expected_rows.unwrap_or(usize::MAX).min(self.chunk_rows).max(1)
    }
}

impl Default for Options {
    fn default() -> Options {
        Options { deflate: None, shuffle: false, chunk_rows: 1024, expected_rows: None, chunk_cols: 0, single: false }
    }
}

/// What the file says about the run rather than about one variable.
pub struct Meta<'a> {
    pub model_name: &'a str,
    pub description: &'a str,
    pub author: &'a str,
    pub generation_tool: &'a str,
    pub date_time: &'a str,
    pub start_time: f64,
    pub stop_time: f64,
    pub tolerance: f64,
    pub algorithm: &'a str,
}

impl Default for Meta<'_> {
    fn default() -> Meta<'static> {
        Meta {
            model_name: "",
            description: "",
            author: "",
            generation_tool: "OpenModelica",
            date_time: "",
            start_time: 0.0,
            stop_time: 1.0,
            tolerance: 1e-6,
            algorithm: "",
        }
    }
}
