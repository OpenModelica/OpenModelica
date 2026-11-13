//! An FMU's `<prefix>_paramdeps.bin`: how the parameters depend on each other and
//! which variables an importer may set. The format is described in
//! `SimulationRuntime/c/util/omc_fmu_paramdeps.h`.

use alloc::vec;
use alloc::vec::Vec;
use openmodelica_sim_meta::Layout;

pub const INITIAL_EXACT: u8 = 1;
pub const INITIAL_APPROX: u8 = 2;
pub const INPUT: u8 = 4;
pub const CONTINUOUS: u8 = 8;
pub const TUNABLE: u8 = 16;

const REAL: u32 = 0;
const INTEGER: u32 = 1;
const BOOLEAN: u32 = 2;
pub const STRING: u32 = 3;
const MAX_SLOT: u64 = 1 << 28;

pub struct ParamDeps {
    runnable: Vec<bool>,
    uses: Vec<Vec<u32>>,
    defines: Vec<Vec<u32>>,
    flags: Vec<u8>,
}

struct Reader<'a> {
    b: &'a [u8],
    p: usize,
}

impl Reader<'_> {
    fn u8(&mut self) -> Option<u8> {
        let v = *self.b.get(self.p)?;
        self.p += 1;
        Some(v)
    }
    fn varint(&mut self) -> Option<u64> {
        let (mut v, mut shift) = (0u64, 0);
        loop {
            let b = self.u8()?;
            if shift < 64 {
                v |= u64::from(b & 127) << shift;
            }
            shift += 7;
            if b & 128 == 0 {
                return Some(v);
            }
        }
    }
    fn slot(&mut self) -> Option<u32> {
        self.varint().filter(|&s| s < MAX_SLOT).map(|s| s as u32)
    }
    fn slots(&mut self) -> Option<Vec<u32>> {
        let n = self.varint()? as usize;
        if n > self.b.len() - self.p {
            return None;
        }
        (0..n).map(|_| self.slot()).collect()
    }
}

impl ParamDeps {
    /// `Some(None)` for a model whose runtime neither checks writes nor updates
    /// parameters.
    pub fn parse(b: &[u8], n_slots: usize) -> Option<Option<Self>> {
        if b.len() < 13 || &b[..8] != b"OMCFMUP\0" || b[8..12] != 1u32.to_le_bytes() {
            return None;
        }
        let mut r = Reader { b, p: 12 };
        if r.u8()? == 0 {
            return Some(None);
        }
        let n_eqs = r.varint()? as usize;
        if n_eqs > b.len() {
            return None;
        }
        let mut deps = ParamDeps {
            runnable: Vec::with_capacity(n_eqs),
            uses: Vec::with_capacity(n_eqs),
            defines: Vec::with_capacity(n_eqs),
            flags: Vec::new(),
        };
        for _ in 0..n_eqs {
            deps.runnable.push(r.u8()? != 0);
            deps.uses.push(r.slots()?);
            deps.defines.push(r.slots()?);
        }
        let mut settable = Vec::new();
        for _ in 0..r.varint()? {
            settable.push((r.slot()?, r.u8()?));
        }
        if r.p != b.len() {
            return None;
        }
        let max = deps
            .uses
            .iter()
            .chain(&deps.defines)
            .flatten()
            .chain(settable.iter().map(|(s, _)| s))
            .max();
        deps.flags = vec![0; n_slots.max(max.map_or(0, |&s| s as usize + 1))];
        for (s, f) in settable {
            deps.flags[s as usize] = f;
        }
        Some(Some(deps))
    }

    pub fn n_eqs(&self) -> usize {
        self.runnable.len()
    }

    pub fn n_slots(&self) -> usize {
        self.flags.len()
    }

    pub fn flags(&self, slot: u32) -> u8 {
        self.flags.get(slot as usize).copied().unwrap_or(0)
    }

    /// C's `omc_fmu_paramdeps_select`: extends `dirty` by everything calculated
    /// from it and sets `mask[k]` for each equation `updateTunableParameters` has
    /// to evaluate. Returns how many.
    pub fn select(&self, dirty: &mut [u8], mask: &mut [u8]) -> usize {
        let mut n = 0;
        for k in 0..self.n_eqs() {
            let hit = self.uses[k].iter().any(|&s| dirty[s as usize] != 0);
            mask[k] = (hit && self.runnable[k]) as u8;
            if hit {
                for &s in &self.defines[k] {
                    dirty[s as usize] = 1;
                }
                n += mask[k] as usize;
            }
        }
        n
    }
}

/// The `SimData` regions a slot can name: start, end, bytes per element, type,
/// and the index of its first element (the variables come before the parameters).
fn regions(l: &Layout) -> [(u32, u32, u32, u32, u32); 8] {
    let n_real = (l.rparam_off - l.real_off) / 8;
    let n_int = (l.iparam_off - l.int_off) / 4;
    let n_bool = (l.bparam_off - l.bool_off) / 4;
    let n_str = (l.sparam_off - l.str_off) / 4;
    [
        (l.real_off, l.rparam_off, 8, REAL, 0),
        (l.rparam_off, l.int_off, 8, REAL, n_real),
        (l.int_off, l.iparam_off, 4, INTEGER, 0),
        (l.iparam_off, l.bool_off, 4, INTEGER, n_int),
        (l.bool_off, l.bparam_off, 4, BOOLEAN, 0),
        (l.bparam_off, l.str_off, 4, BOOLEAN, n_bool),
        (l.str_off, l.sparam_off, 4, STRING, 0),
        (l.sparam_off, l.eobj_off, 4, STRING, n_str),
    ]
}

/// At least one more than the largest slot a model with this layout can have.
pub fn n_slots(l: &Layout) -> usize {
    let r = regions(l);
    let n_eobj = (l.pre_real_off - l.eobj_off) / 4;
    (0..4)
        .map(|t| r[2 * t + 1].4 + (r[2 * t + 1].1 - r[2 * t + 1].0) / r[2 * t + 1].2)
        .chain([n_eobj])
        .max()
        .unwrap_or(0) as usize
        * 8
        + 8
}

/// The slot of the variable at `SimData` offset `off`.
pub fn slot_of(l: &Layout, off: u32) -> Option<u32> {
    regions(l)
        .iter()
        .find(|r| off >= r.0 && off < r.1)
        .map(|r| 8 * (r.4 + (off - r.0) / r.2) + r.3)
}

/// Whether the variable at `SimData` offset `off` is a parameter.
pub fn is_param(l: &Layout, off: u32) -> bool {
    regions(l).iter().skip(1).step_by(2).any(|r| off >= r.0 && off < r.1)
}

/// The `SimData` offset, size and type of slot `s`.
pub fn slot_off(l: &Layout, s: u32) -> Option<(u32, u32, u32)> {
    let (ty, index) = (s % 8, s / 8);
    regions(l)
        .iter()
        .filter(|r| r.3 == ty && index >= r.4)
        .map(|r| (r.0 + (index - r.4) * r.2, r.2, ty))
        .filter(|&(off, _, _)| regions(l).iter().any(|r| r.3 == ty && off >= r.0 && off < r.1))
        .last()
}
