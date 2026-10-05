//! `arrow.modelica` result files (`.arrow`): a sequence of Arrow IPC streams —
//! the variable table, the units, the parameters as one dense union column, the
//! trajectories, the batch index — and a 16-byte trailer. `SPECIFICATION.md`
//! beside this crate is the format.
//!
//! Writes bytes into a caller-owned [`Out`] and does no I/O of its own. The
//! data stream is written one record batch per block of rows, and the schema
//! is decided up front from the variable list: one field per *stored*
//! time-variant signal, `time` first, in the Arrow type of the variable's own
//! (`Float64`/`Float32`, `Int32`, `Boolean`, `Utf8`, or
//! `Dictionary<Int32, Utf8>` for an enumeration), run-end encoded when the
//! signal is discrete-time. Aliases share their column through the variable
//! table's `scale` and `offset`; time-invariant values go to the parameter
//! table, each in its own type.

pub mod units;
#[cfg(feature = "json-layout")]
pub mod json;
#[cfg(feature = "ipc")]
mod writer;
#[cfg(feature = "ipc")]
pub use writer::{ArrowStream, ArrowVar, FileMeta, Out, no_strings, write_arrow};
#[cfg(feature = "json-layout")]
pub(crate) use writer::ree_type;

pub use units::{BaseUnit, DisplayUnit, UnitDef};

/// Turns an interned String id (what a String column or parameter holds in the
/// result rows) back into its text. `Send`, so a writer holding one can be
/// handed to a thread of its own.
pub type Resolve = Box<dyn Fn(u32) -> String + Send>;

/// Schema metadata key naming a stream's table.
pub const TABLE_KEY: &str = "modelica.table";
/// Schema metadata key holding the layout version, on the variable table.
pub const FORMAT_KEY: &str = "modelica.format";
/// Schema metadata keys holding the run's start and stop time, on the variable
/// table; absent when the writer had no run.
pub const START_TIME_KEY: &str = "modelica.startTime";
pub const STOP_TIME_KEY: &str = "modelica.stopTime";
pub const FORMAT_VERSION: &str = "0.1";
/// The last 8 bytes of a finished file; the 8 before them are the byte offset
/// of the index stream.
pub const TRAILER_MAGIC: &[u8; 8] = b"MODELICA";

/// Rows per record batch when streaming.
pub const DEFAULT_BLOCK_ROWS: usize = 1024;

/// Rows per record batch: the default, or the `-mat_sync` interval when it is
/// smaller (each complete batch is readable in a file still being written).
pub fn block_rows(sync: usize) -> usize {
    if sync > 0 { sync.min(DEFAULT_BLOCK_ROWS) } else { DEFAULT_BLOCK_ROWS }
}

/// How an alias derives its value from the column it shares: `scale * v + offset`.
#[derive(Clone, Copy, PartialEq, Debug)]
pub struct Affine {
    pub scale: f64,
    pub offset: f64,
}

impl Affine {
    pub const IDENTITY: Affine = Affine { scale: 1.0, offset: 0.0 };
    /// `-v`
    pub const NEGATE: Affine = Affine { scale: -1.0, offset: 0.0 };
    /// `!v` over the 0/1 encoding.
    pub const NOT: Affine = Affine { scale: -1.0, offset: 1.0 };

    pub fn apply(self, v: f64) -> f64 {
        self.scale * v + self.offset
    }

    pub fn is_identity(self) -> bool {
        self == Affine::IDENTITY
    }

    /// `self` applied after the inverse of `base`: the map from a column stored
    /// as `base(v)` to `self(v)`.
    #[cfg(feature = "ipc")]
    fn relative_to(self, base: Affine) -> Affine {
        let scale = self.scale / base.scale;
        Affine { scale, offset: self.offset - scale * base.offset }
    }
}

impl Default for Affine {
    fn default() -> Affine {
        Affine::IDENTITY
    }
}

/// The Modelica type of a result variable.
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum VarTy {
    #[default]
    Real,
    Integer,
    Boolean,
    String,
}

impl VarTy {
    pub fn code(self) -> u8 {
        match self {
            VarTy::Real => 0,
            VarTy::Integer => 1,
            VarTy::Boolean => 2,
            VarTy::String => 3,
        }
    }
    pub fn from_code(c: u8) -> VarTy {
        match c {
            1 => VarTy::Integer,
            2 => VarTy::Boolean,
            3 => VarTy::String,
            _ => VarTy::Real,
        }
    }
    pub fn name(self) -> &'static str {
        match self {
            VarTy::Real => "Real",
            VarTy::Integer => "Integer",
            VarTy::Boolean => "Boolean",
            VarTy::String => "String",
        }
    }
    pub fn from_name(s: &str) -> VarTy {
        match s {
            "Integer" => VarTy::Integer,
            "Boolean" => VarTy::Boolean,
            "String" => VarTy::String,
            "enumeration" => VarTy::Integer,
            _ => VarTy::Real,
        }
    }
}

/// How a result signal sources its value. Mirrors `MatKind`.
#[derive(Clone, Copy, Debug)]
pub enum ArrowKind {
    Time,
    /// Result-row column `col` (0 = time), transformed by `affine` for an alias.
    Column { col: u32, affine: Affine },
    /// A time-invariant value taken from the `params` slice, in `Param` order.
    Param { affine: Affine },
    Const { value: f64 },
}

/// The storage type of a result-row column.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum ColTy {
    F64,
    /// A Real under `-single`.
    F32,
    I32,
    Bool,
    /// An interned String id (see [`Resolve`]).
    Str,
}
