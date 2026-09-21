//! The FMI value-reference table, derived from `MODEL_DATA`.
//!
//! Value references are handed out per base type as `[variables][parameters]
//! [aliases]` over the same arrays `MODEL_DATA` counts
//! (`SimCodeUtil.getValueReferenceMapping`), so every slot but an alias's follows
//! from the geometry. What an alias stands for does not; the generated code hands
//! that over in `callback->fmi*AliasIndexes`.
//!
//! String and external-object variables are left out: their `SimData` region is
//! opaque here (a `modelica_string` is a pointer, not the flat layout's handle),
//! so the component reports their value references as unresolvable rather than
//! serving a wrong value.

use core::ffi::c_int;

use openmodelica_sim_meta::{FmiVr, Layout, Neg, REAL_OFF, WTy};

use crate::abi::*;

/// One base type's block of value references.
struct Block {
    n_var: u32,
    n_param: u32,
    n_alias: u32,
    /// Scalar start of each array-level variable, parameter and alias
    /// (`simulationInfo->realVarsIndex` & co.) with its array-level count.
    var_index: (*const usize, u32),
    param_index: (*const usize, u32),
    alias_index: (*const usize, u32),
    table: *const c_int,
    /// `SimData` byte offset of variable 0 and of parameter 0, and the slot size.
    var_off: u32,
    param_off: u32,
    stride: u32,
    wty: WTy,
    /// What a negated alias of this type means.
    neg: Neg,
}

impl Block {
    fn size(&self) -> u32 {
        self.n_var + self.n_param + self.n_alias
    }

    /// The variable or parameter a value reference names, and whether reading it
    /// negates. `None` for an alias chain that leads nowhere.
    fn resolve(&self, vr: u32) -> Option<(u32, bool)> {
        let mut vr = vr;
        let mut negate = false;
        for _ in 0..self.n_alias + 1 {
            if vr < self.n_var + self.n_param {
                return Some((vr, negate));
            }
            let (a, elem) = self.alias_elem(vr - (self.n_var + self.n_param))?;
            let ix = unsafe { *self.table.add(a) };
            vr = if ix >= 0 {
                (ix as u32).checked_add(elem)?
            } else {
                negate = !negate;
                u32::try_from(-(ix + 1)).ok()?.checked_add(elem)?
            };
        }
        None
    }

    /// The array-level alias holding scalar alias element `k`, and `k`'s position
    /// in it.
    fn alias_elem(&self, k: u32) -> Option<(usize, u32)> {
        if self.table.is_null() || k >= self.n_alias {
            return None;
        }
        let (idx, n) = self.alias_index;
        if idx.is_null() {
            return (k < n).then_some((k as usize, 0));
        }
        let idx = unsafe { core::slice::from_raw_parts(idx, n as usize + 1) };
        let a = idx.partition_point(|&s| s <= k as usize).checked_sub(1)?;
        (a < n as usize).then(|| (a, k - idx[a] as u32))
    }

    fn slot(&self, i: u32) -> u32 {
        if i < self.n_var {
            self.var_off + i * self.stride
        } else {
            self.param_off + (i - self.n_var) * self.stride
        }
    }
}

/// One entry per scalar element: an array's first element carries the array's
/// length, every other slot 1, which is what `Vrs::expand` walks a block by.
fn elem_lens((index, n_array): (*const usize, u32), n_scalar: u32) -> Vec<u32> {
    let mut out = vec![1u32; n_scalar as usize];
    if index.is_null() {
        return out;
    }
    let idx = unsafe { core::slice::from_raw_parts(index, n_array as usize + 1) };
    for a in 0..n_array as usize {
        if let Some(slot) = out.get_mut(idx[a]) {
            *slot = (idx[a + 1] - idx[a]) as u32;
        }
    }
    out
}

/// The table, and the fmi-ls-dae `EnableDAEParameter` value reference (0 without
/// one). The value references are the globally unique FMI 3.0 ones: an FMI 2.0 one
/// is its base type's block base less than this.
pub(crate) fn build(data: *mut DATA, layout: &Layout) -> (Vec<FmiVr>, u32) {
    let md = unsafe { &*(*data).modelData };
    let si = unsafe { &*(*data).simulationInfo };
    let cb = unsafe { &*(*data).callback };

    let blocks = [
        Block {
            n_var: md.nVariablesReal as u32,
            n_param: md.nParametersReal as u32,
            n_alias: md.nAliasReal as u32,
            var_index: (si.realVarsIndex, md.nVariablesRealArray as u32),
            param_index: (si.realParamsIndex, md.nParametersRealArray as u32),
            alias_index: (si.realAliasIndex, md.nAliasRealArray as u32),
            table: cb.fmiRealAliasIndexes,
            var_off: REAL_OFF,
            param_off: layout.rparam_off,
            stride: 8,
            wty: WTy::F64,
            neg: Neg::Arith,
        },
        Block {
            n_var: md.nVariablesInteger as u32,
            n_param: md.nParametersInteger as u32,
            n_alias: md.nAliasInteger as u32,
            var_index: (si.integerVarsIndex, md.nVariablesIntegerArray as u32),
            param_index: (si.integerParamsIndex, md.nParametersIntegerArray as u32),
            alias_index: (si.integerAliasIndex, md.nAliasIntegerArray as u32),
            table: cb.fmiIntegerAliasIndexes,
            var_off: layout.int_off,
            param_off: layout.iparam_off,
            stride: 4,
            wty: WTy::I32,
            neg: Neg::Arith,
        },
        Block {
            n_var: md.nVariablesBoolean as u32,
            n_param: md.nParametersBoolean as u32,
            n_alias: md.nAliasBoolean as u32,
            var_index: (si.booleanVarsIndex, md.nVariablesBooleanArray as u32),
            param_index: (si.booleanParamsIndex, md.nParametersBooleanArray as u32),
            alias_index: (si.booleanAliasIndex, md.nAliasBooleanArray as u32),
            table: cb.fmiBooleanAliasIndexes,
            var_off: layout.bool_off,
            param_off: layout.bparam_off,
            stride: 4,
            wty: WTy::I32,
            neg: Neg::Not,
        },
    ];

    let mut out = Vec::new();
    let mut base = 0u32;
    for (b, blk) in blocks.iter().enumerate() {
        let lens = [
            elem_lens(blk.var_index, blk.n_var),
            elem_lens(blk.param_index, blk.n_param),
            elem_lens(blk.alias_index, blk.n_alias),
        ];
        for vr in 0..blk.size() {
            let Some((i, negate)) = blk.resolve(vr) else { continue };
            let (section, k) = if vr < blk.n_var {
                (0, vr)
            } else if vr < blk.n_var + blk.n_param {
                (1, vr - blk.n_var)
            } else {
                (2, vr - blk.n_var - blk.n_param)
            };
            out.push(FmiVr {
                vr: base + vr,
                off: blk.slot(i),
                wty: blk.wty,
                negate: if negate { blk.neg } else { Neg::None },
                start_off: if b == 0 && i < blk.n_var { layout.real_start_off(i) } else { 0 },
                is_string: false,
                der_off: 0,
                len: lens[section].get(k as usize).copied().unwrap_or(1),
            });
        }
        base += blk.size();
    }

    // The string and external-object blocks hold no resolvable slot, but their
    // value references still shift everything that follows.
    let time_vr = base
        + md.nVariablesString as u32
        + md.nParametersString as u32
        + md.nAliasString as u32
        + md.nExtObjs as u32
        + layout.n_base_clocks;
    let scalar = |vr: u32, off: u32| FmiVr {
        vr,
        off,
        wty: WTy::F64,
        negate: Neg::None,
        start_off: 0,
        is_string: false,
        der_off: 0,
        len: 1,
    };
    out.push(scalar(time_vr, openmodelica_sim_meta::TIME_OFF));
    for k in 0..layout.n_zc {
        out.push(scalar(time_vr + 1 + k, layout.zc_off + k * 8));
    }
    let mut dae_enable_vr = 0;
    if layout.dae_mode() {
        dae_enable_vr = time_vr + 1 + layout.n_zc;
        for i in 0..layout.n_dae_res {
            out.push(scalar(dae_enable_vr + 1 + i, layout.dae_res_off + i * 8));
        }
    }
    out.sort_by_key(|e| e.vr);
    out.dedup_by_key(|e| e.vr);
    (out, dae_enable_vr)
}
