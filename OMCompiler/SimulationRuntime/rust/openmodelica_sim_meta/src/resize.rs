//! Models with resizable arrays (`--resizableArrays`): the codegen leaves every
//! size that depends on a size parameter symbolic ([`Sz`]); [`SimMeta::resolve_sizes`]
//! fixes them from the parameter values a run starts with (`-override` included).
//!
//! The generated code addresses what lies past the first resizable region through
//! a table of i32s at [`Layout::table_off`] (its address in the header word at
//! [`TABLE_PTR_OFF`]): entry `k` is [`Resize::table`]`[k]`. The codegen hands
//! such addresses on as *tagged* offsets ([`dyn_off`]), which resolving turns
//! into plain ones.

use alloc::string::{String, ToString};
use alloc::vec::Vec;

use crate::{Layout, LayoutCounts, LayoutFlags, MetaKind, SimMeta, Sz, TABLE_PTR_OFF, WTy};

/// A size parameter. `start` refers to earlier parameters only (a `$DIM_k` the
/// backend adds for `N-1` is `start = N - 1`).
#[derive(Clone, Debug, PartialEq)]
pub struct SizeParam {
    pub name: String,
    pub start: Sz,
    /// Its Integer parameter slot, tagged.
    pub off: u32,
}

#[derive(Clone, Debug, PartialEq, Default)]
pub struct Resize {
    pub params: Vec<SizeParam>,
    pub counts: LayoutCounts<Sz>,
    pub table: Vec<Sz>,
    /// [`SimMeta::var_arrays`]`[i].dims`.
    pub var_dims: Vec<Vec<Sz>>,
    /// [`SotiVars::real_arrays`](crate::SotiVars)`[i].dims`.
    pub soti_dims: Vec<Vec<Sz>>,
    /// The ODE Jacobian's sparsity, expanded into [`SimMeta::jac_a`].
    pub jac_a: Option<crate::sym_sparsity::SymPattern>,
    /// `simulate(variableFilter=)`, for the host to apply to the resolved variables.
    pub var_filter: String,
    /// Bytes past the layout's end the runtime-sized solver blocks take.
    pub scratch: Sz,
    /// Set by [`SimMeta::resolve_sizes`]: the parameter values and the table.
    pub values: Vec<i64>,
    pub table_values: Vec<i32>,
}

const DYN_BIT: u32 = 1 << 31;
const REL_BITS: u32 = 20;
const REL_MASK: u32 = (1 << REL_BITS) - 1;
/// Table entries a tagged offset can name.
pub const MAX_TABLE: u32 = 1 << (31 - REL_BITS);
/// Bytes past a table entry a tagged offset can reach.
pub const MAX_REL: u32 = REL_MASK;

/// `rel` bytes past the offset table entry `entry` holds.
pub fn dyn_off(entry: u32, rel: u32) -> u32 {
    debug_assert!(entry < MAX_TABLE && rel <= MAX_REL);
    DYN_BIT | (entry << REL_BITS) | rel
}

/// `(entry, rel)` of a tagged offset, `None` for a plain one.
pub fn split_dyn(off: u32) -> Option<(u32, u32)> {
    (off & DYN_BIT != 0).then(|| ((off & !DYN_BIT) >> REL_BITS, off & REL_MASK))
}

pub fn is_dyn(off: u32) -> bool {
    off & DYN_BIT != 0
}

impl Resize {
    pub fn resolve_off(&self, off: u32) -> u32 {
        resolve_off(&self.table_values, off)
    }
}

fn resolve_off(table: &[i32], off: u32) -> u32 {
    match split_dyn(off) {
        Some((k, rel)) => table[k as usize] as u32 + rel,
        None => off,
    }
}

/// Where a variable slot at `off` shows in the result: the column of a
/// time-variant one, else read from `SimData`. `None` for a slot without either.
pub fn classify_slot(off: u32, wty: WTy, negate: crate::Neg, layout: &Layout) -> Option<MetaKind> {
    if off == crate::TIME_OFF {
        return Some(MetaKind::Column { col: 0, negate });
    }
    if off >= layout.real_off && off < layout.rparam_off {
        return Some(MetaKind::Column { col: 1 + (off - layout.real_off) / 8, negate });
    }
    if off >= layout.int_off && off < layout.iparam_off {
        return Some(MetaKind::Column { col: layout.n_reals_row() + (off - layout.int_off) / 4, negate });
    }
    if off >= layout.bool_off && off < layout.bparam_off {
        let col = layout.n_reals_row() + layout.n_int_alg() + (off - layout.bool_off) / 4;
        return Some(MetaKind::Column { col, negate });
    }
    if off >= layout.str_off && off < layout.sparam_off {
        return Some(MetaKind::Column { col: layout.str_col0() + (off - layout.str_off) / 4, negate });
    }
    let is_param = (off >= layout.rparam_off && off < layout.int_off)
        || (off >= layout.iparam_off && off < layout.bool_off)
        || (off >= layout.bparam_off && off < layout.str_off)
        || (off >= layout.sparam_off && off < layout.eobj_off);
    is_param.then_some(MetaKind::Param { off, wty, negate })
}

fn parse_int(v: &str) -> Option<i64> {
    let v = v.trim();
    v.parse::<i64>().ok().or_else(|| {
        let f = v.parse::<f64>().ok()?;
        (f == crate::fmath::floor(f)).then_some(f as i64)
    })
}

impl SimMeta {
    /// Fix the sizes of a model with resizable arrays from its size parameters,
    /// `overrides` (`-override`) applied. A no-op for any other model.
    pub fn resolve_sizes(&mut self, overrides: &[(String, String)]) -> Result<(), String> {
        let Some(params) = self.resize.as_ref().map(|r| &r.params) else { return Ok(()) };
        let mut values: Vec<i64> = Vec::with_capacity(params.len());
        for p in params {
            let given = overrides.iter().rev().find(|(n, _)| *n == p.name);
            let v = match given {
                Some((_, v)) if p.start.is_const() => {
                    parse_int(v).ok_or_else(|| alloc::format!("-override {}={v}: not an Integer", p.name))?
                }
                _ => p.start.eval(&values),
            };
            if v < 0 {
                return Err(alloc::format!("The size parameter {} is {v}, an array size must not be negative", p.name));
            }
            values.push(v);
        }
        let Some(mut r) = self.resize.take() else { return Ok(()) };
        let flags = LayoutFlags {
            sym_solver: self.layout.sym_solver,
            has_when: self.layout.has_when,
            has_homotopy: self.layout.has_homotopy,
            homotopy_method: self.layout.homotopy_method,
            has_init_lambda0: self.layout.has_init_lambda0,
            has_history_ops: self.layout.has_history_ops,
            has_old_real: self.layout.has_old_real,
            resizable: true,
        };
        let mut layout = Layout::build(r.counts.eval(&values), flags);
        layout.extra_cols = self.layout.extra_cols;
        layout.total += r.scratch.eval(&values).max(0) as u32;
        layout.table_off = (layout.total + 7) & !7;
        layout.n_table = r.table.len() as u32;
        layout.total = layout.table_off + 4 * layout.n_table;
        r.table_values = r.table.iter().map(|s| s.eval(&values) as i32).collect();
        r.values = values;
        for p in &mut r.params {
            p.off = resolve_off(&r.table_values, p.off);
        }
        for v in &mut self.vars {
            if let MetaKind::Param { off, wty, negate } = v.kind {
                let abs = resolve_off(&r.table_values, off);
                v.kind = classify_slot(abs, wty, negate, &layout).unwrap_or(MetaKind::Param { off: abs, wty, negate });
            }
        }
        let dims = |d: &[Sz]| d.iter().map(|s| s.eval(&r.values).max(0) as u32).collect::<Vec<u32>>();
        for (a, d) in self.var_arrays.iter_mut().zip(&r.var_dims) {
            if !d.is_empty() {
                a.dims = dims(d);
            }
        }
        for (a, d) in self.soti.real_arrays.iter_mut().zip(&r.soti_dims) {
            if !d.is_empty() {
                a.dims = dims(d);
            }
        }
        if let Some(p) = &r.jac_a {
            self.jac_a = p.expand(&r.values).filter(|c| !c.is_empty()).map(|rows_by_col| crate::JacAInfo {
                n: rows_by_col.len() as u32,
                colors: crate::sym_sparsity::color_columns(&rows_by_col),
                rows_by_col,
                sym: None,
            });
        }
        self.layout = layout;
        self.resize = Some(r);
        self.expand_arrays();
        Ok(())
    }

    /// The header word and the size table a freshly allocated `SimData` needs
    /// before any generated function runs: `(offset, value)` pairs.
    pub fn size_table_writes(&self) -> Vec<(u32, i32)> {
        let Some(r) = &self.resize else { return Vec::new() };
        let mut w = Vec::with_capacity(r.table_values.len() + 1);
        w.push((TABLE_PTR_OFF, self.layout.table_off as i32));
        for (k, v) in r.table_values.iter().enumerate() {
            w.push((self.layout.table_off + 4 * k as u32, *v));
        }
        w
    }

    /// The size parameters' slots and the values the arrays were sized for, written
    /// before `functionParameters`, whose loops they bound.
    pub fn size_param_writes(&self) -> Vec<(u32, i32)> {
        let Some(r) = &self.resize else { return Vec::new() };
        r.params.iter().zip(&r.values).map(|(p, v)| (p.off, *v as i32)).collect()
    }
}

pub(crate) fn put_resize(o: &mut Vec<u8>, r: &Option<Resize>) {
    let Some(r) = r else {
        o.push(0);
        return;
    };
    o.push(1);
    let put_u32 = |o: &mut Vec<u8>, v: u32| o.extend_from_slice(&v.to_le_bytes());
    let put_szs = |o: &mut Vec<u8>, v: &[Sz]| {
        put_u32(o, v.len() as u32);
        for s in v {
            s.encode(o);
        }
    };
    put_u32(o, r.params.len() as u32);
    for p in &r.params {
        put_u32(o, p.name.len() as u32);
        o.extend_from_slice(p.name.as_bytes());
        p.start.encode(o);
        put_u32(o, p.off);
    }
    let c = &r.counts;
    for s in counts_fields(c) {
        s.encode(o);
    }
    put_szs(o, &r.table);
    for list in [&r.var_dims, &r.soti_dims] {
        put_u32(o, list.len() as u32);
        for d in list {
            put_szs(o, d);
        }
    }
    crate::sym_sparsity::put(o, &r.jac_a);
    put_u32(o, r.var_filter.len() as u32);
    o.extend_from_slice(r.var_filter.as_bytes());
    r.scratch.encode(o);
}

pub(crate) fn get_resize(b: &[u8], p: &mut usize) -> Result<Option<Resize>, &'static str> {
    let u8_ = |b: &[u8], p: &mut usize| -> Result<u8, &'static str> {
        let v = *b.get(*p).ok_or("sim_meta: truncated")?;
        *p += 1;
        Ok(v)
    };
    let u32_ = |b: &[u8], p: &mut usize| -> Result<u32, &'static str> {
        let s = b.get(*p..*p + 4).ok_or("sim_meta: truncated")?;
        *p += 4;
        Ok(u32::from_le_bytes(s.try_into().unwrap()))
    };
    let szs = |b: &[u8], p: &mut usize| -> Result<Vec<Sz>, &'static str> {
        let n = u32_(b, p)?;
        (0..n).map(|_| Sz::decode(b, p)).collect()
    };
    if u8_(b, p)? == 0 {
        return Ok(None);
    }
    let n = u32_(b, p)?;
    let mut params = Vec::with_capacity(n as usize);
    for _ in 0..n {
        let len = u32_(b, p)? as usize;
        let name = core::str::from_utf8(b.get(*p..*p + len).ok_or("sim_meta: truncated")?)
            .map_err(|_| "sim_meta: bad size parameter name")?
            .to_string();
        *p += len;
        let start = Sz::decode(b, p)?;
        let off = u32_(b, p)?;
        params.push(SizeParam { name, start, off });
    }
    let mut c: [Sz; N_COUNTS] = Default::default();
    for s in c.iter_mut() {
        *s = Sz::decode(b, p)?;
    }
    let counts = counts_from(c);
    let table = szs(b, p)?;
    let mut lists: [Vec<Vec<Sz>>; 2] = Default::default();
    for l in lists.iter_mut() {
        let n = u32_(b, p)?;
        for _ in 0..n {
            l.push(szs(b, p)?);
        }
    }
    let [var_dims, soti_dims] = lists;
    let jac_a = crate::sym_sparsity::get(b, p)?;
    let len = u32_(b, p)? as usize;
    let var_filter = core::str::from_utf8(b.get(*p..*p + len).ok_or("sim_meta: truncated")?)
        .map_err(|_| "sim_meta: bad variable filter")?
        .to_string();
    *p += len;
    let scratch = Sz::decode(b, p)?;
    Ok(Some(Resize { params, counts, table, var_dims, soti_dims, jac_a, var_filter, scratch, values: Vec::new(), table_values: Vec::new() }))
}

const N_COUNTS: usize = 26;

fn counts_fields(c: &LayoutCounts<Sz>) -> [&Sz; N_COUNTS] {
    [
        &c.n_states, &c.n_real_alg, &c.n_real_param, &c.n_int_alg, &c.n_int_param, &c.n_bool_alg, &c.n_bool_param,
        &c.n_str_alg, &c.n_str_param, &c.n_eobj, &c.n_samples, &c.n_zc, &c.n_rel, &c.n_stateset_f64,
        &c.n_nlsjac_f64, &c.n_math, &c.n_sens, &c.n_dae_res, &c.n_dae_aux, &c.n_dae_alg, &c.n_base_clocks,
        &c.n_sub_clocks, &c.n_linz, &c.n_opt_attr, &c.n_attr_log, &c.n_removed_init,
    ]
}

fn counts_from(c: [Sz; N_COUNTS]) -> LayoutCounts<Sz> {
    let [
        n_states, n_real_alg, n_real_param, n_int_alg, n_int_param, n_bool_alg, n_bool_param, n_str_alg,
        n_str_param, n_eobj, n_samples, n_zc, n_rel, n_stateset_f64, n_nlsjac_f64, n_math, n_sens, n_dae_res,
        n_dae_aux, n_dae_alg, n_base_clocks, n_sub_clocks, n_linz, n_opt_attr, n_attr_log, n_removed_init,
    ] = c;
    LayoutCounts {
        n_states, n_real_alg, n_real_param, n_int_alg, n_int_param, n_bool_alg, n_bool_param, n_str_alg,
        n_str_param, n_eobj, n_samples, n_zc, n_rel, n_stateset_f64, n_nlsjac_f64, n_math, n_sens, n_dae_res,
        n_dae_aux, n_dae_alg, n_base_clocks, n_sub_clocks, n_linz, n_opt_attr, n_attr_log, n_removed_init,
    }
}
