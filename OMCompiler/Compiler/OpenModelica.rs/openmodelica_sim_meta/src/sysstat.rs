//! One linear or nonlinear system's solver statistics, as C keeps them in
//! `LINEAR_SYSTEM_DATA` / `NONLINEAR_SYSTEM_DATA` and prints them under
//! `LOG_STATS_V`.
//!
//! The systems are solved inside the wasm runtime, so the table is built there and
//! handed to the host as a flat `f64` array. The word order lives here, with the
//! struct, so the two sides cannot disagree about it.

/// `f64` words one system occupies in that array.
pub const WORDS: usize = 10;

#[derive(Clone, Copy, Default, PartialEq, Debug)]
pub struct SysStat {
    /// The system's equation index, which is how C names it in the log.
    pub eq_index: i32,
    pub nonlinear: bool,
    pub size: u32,
    pub nnz: u32,
    pub calls: u64,
    /// Nonlinear only: C's `numberOfIterations` / `numberOfFEval` / `numberOfJEval`.
    pub iters: u64,
    pub res_evals: u64,
    pub jac_evals: u64,
    /// Seconds in the system, and the share of that spent assembling its Jacobian.
    pub total: f64,
    pub jac: f64,
}

impl SysStat {
    pub fn to_words(&self) -> [f64; WORDS] {
        [
            self.eq_index as f64,
            self.nonlinear as u32 as f64,
            self.size as f64,
            self.nnz as f64,
            self.calls as f64,
            self.iters as f64,
            self.res_evals as f64,
            self.jac_evals as f64,
            self.total,
            self.jac,
        ]
    }

    pub fn from_words(w: &[f64]) -> Self {
        SysStat {
            eq_index: w[0] as i32,
            nonlinear: w[1] != 0.0,
            size: w[2] as u32,
            nnz: w[3] as u32,
            calls: w[4] as u64,
            iters: w[5] as u64,
            res_evals: w[6] as u64,
            jac_evals: w[7] as u64,
            total: w[8],
            jac: w[9],
        }
    }
}

/// Decode a whole published table.
pub fn decode(words: &[f64]) -> alloc::vec::Vec<SysStat> {
    words.chunks_exact(WORDS).map(SysStat::from_words).collect()
}
