//! Resizable arrays in the generated code: what depends on a size parameter is
//! read from the model's size table (`openmodelica_sim_meta::resize`). Each entry
//! a function uses is loaded once, in its prologue.

use super::*;
use openmodelica_sim_meta::resize::{MAX_REL, MAX_TABLE, dyn_off, split_dyn};
use openmodelica_sim_meta::{Sz, TABLE_PTR_OFF};
use std::cell::RefCell;

#[derive(Default)]
struct SizeTable {
    entries: Vec<Sz>,
    index: HashMap<Sz, u32>,
}

thread_local! {
    static TABLE: RefCell<Option<SizeTable>> = const { RefCell::new(None) };
}

/// Collects the size table of one model while alive.
pub(crate) struct SizeScope;

impl SizeScope {
    pub(crate) fn begin() -> SizeScope {
        TABLE.with(|t| *t.borrow_mut() = Some(SizeTable::default()));
        SizeScope
    }

    pub(crate) fn entries(&self) -> Vec<Sz> {
        TABLE.with(|t| t.borrow().as_ref().map(|t| t.entries.clone()).unwrap_or_default())
    }
}

impl Drop for SizeScope {
    fn drop(&mut self) {
        TABLE.with(|t| *t.borrow_mut() = None);
    }
}

fn entry(v: &Sz) -> Result<u32> {
    TABLE.with(|t| {
        let mut t = t.borrow_mut();
        let t = t.as_mut().ok_or("CodegenWasmJit: a resizable size outside a model")?;
        if let Some(&k) = t.index.get(v) {
            return Ok(k);
        }
        let k = t.entries.len() as u32;
        if k >= MAX_TABLE {
            return Err("CodegenWasmJit: too many resizable sizes");
        }
        t.entries.push(v.clone());
        t.index.insert(v.clone(), k);
        Ok(k)
    })
}

/// The `SimData` offset `off` as the codegen passes offsets around: plain if it is
/// a constant, else tagged with the table entry holding its non-constant part.
pub(crate) fn sim_offset(off: &Sz) -> Result<u32> {
    if let Some(c) = off.as_const() {
        return u32::try_from(c).map_err(|_| "CodegenWasmJit: SimData offset out of range");
    }
    let (sym, c) = off.split_const();
    if (0..=MAX_REL as i64).contains(&c) {
        Ok(dyn_off(entry(&sym)?, c as u32))
    } else {
        Ok(dyn_off(entry(off)?, 0))
    }
}

/// `off` past its base: itself unless tagged.
pub(crate) fn rel_of(off: u32) -> u32 {
    split_dyn(off).map_or(off, |(_, rel)| rel)
}

pub(crate) fn sz_product(dims: &[Sz]) -> Sz {
    dims.iter().fold(Sz::lit(1), |a, d| a * d.clone())
}

/// The size `sim_offset` made `off` from.
pub(crate) fn off_sz(off: u32) -> Sz {
    match split_dyn(off) {
        None => Sz::lit(off as i64),
        Some((k, rel)) => {
            let base = TABLE.with(|t| t.borrow().as_ref().and_then(|t| t.entries.get(k as usize).cloned()));
            base.unwrap_or_default() + Sz::lit(rel as i64)
        }
    }
}

/// The size-table entry holding `v`, for a value read at runtime ([`FnCtx::emit_size_entry`]).
pub(crate) fn size_entry(v: &Sz) -> Result<u32> {
    entry(v)
}

pub(crate) fn is_resizing() -> bool {
    TABLE.with(|t| t.borrow().is_some())
}

/// Locals of one function caching the table entries it reads.
#[derive(Default)]
pub(crate) struct SizeLocals {
    table: Option<u32>,
    /// entry -> (`data + value` local, `value` local)
    by_entry: HashMap<u32, (Option<u32>, Option<u32>)>,
}

impl FnCtx<'_> {
    fn size_local(&mut self, k: u32, ptr: bool) -> u32 {
        let have = self.size_locals.by_entry.get(&k).copied().unwrap_or_default();
        let cur = if ptr { have.0 } else { have.1 };
        if let Some(l) = cur {
            return l;
        }
        let l = self.alloc_temp(WTy::I32);
        let e = self.size_locals.by_entry.entry(k).or_default();
        if ptr { e.0 = Some(l) } else { e.1 = Some(l) }
        l
    }

    /// Push the base address `off` is relative to and return the offset for the
    /// access's memarg: `data` and `off` itself, unless `off` is tagged.
    pub(crate) fn emit_sim_base(&mut self, off: u32) -> Result<u32> {
        match split_dyn(off) {
            None => {
                let data = self.sim()?.data_local;
                self.emit(we::Instruction::LocalGet(data));
                Ok(off)
            }
            Some((k, rel)) => {
                let l = self.size_local(k, true);
                self.emit(we::Instruction::LocalGet(l));
                Ok(rel)
            }
        }
    }

    /// Push the absolute address of `SimData` offset `off`.
    pub(crate) fn emit_sim_addr(&mut self, off: u32) -> Result<()> {
        let rel = self.emit_sim_base(off)?;
        if rel != 0 {
            self.emit(we::Instruction::I32Const(rel as i32));
            self.emit(we::Instruction::I32Add);
        }
        Ok(())
    }

    /// Push the i32 value of a size.
    pub(crate) fn emit_size(&mut self, v: &Sz) -> Result<()> {
        if let Some(c) = v.as_const() {
            self.emit(we::Instruction::I32Const(c as i32));
            return Ok(());
        }
        let k = entry(v)?;
        let l = self.size_local(k, false);
        self.emit(we::Instruction::LocalGet(l));
        Ok(())
    }

    pub(crate) fn emit_size_entry(&mut self, k: u32) {
        let l = self.size_local(k, false);
        self.emit(we::Instruction::LocalGet(l));
    }

    /// The loads of the table entries the body used, to run before it.
    pub(crate) fn size_prologue(&mut self) -> Vec<we::Instruction<'static>> {
        use we::Instruction as I;
        if self.size_locals.by_entry.is_empty() {
            return Vec::new();
        }
        let Some(data) = self.sim.as_ref().map(|s| s.data_local) else { return Vec::new() };
        let t = match self.size_locals.table {
            Some(t) => t,
            None => {
                let t = self.alloc_temp(WTy::I32);
                self.size_locals.table = Some(t);
                t
            }
        };
        let mut out = vec![
            I::LocalGet(data),
            I::LocalGet(data),
            I::I32Load(mem_arg(TABLE_PTR_OFF, 2)),
            I::I32Add,
            I::LocalSet(t),
        ];
        let mut entries: Vec<_> = self.size_locals.by_entry.iter().map(|(&k, &v)| (k, v)).collect();
        entries.sort_by_key(|e| e.0);
        for (k, (ptr, val)) in entries {
            if let Some(v) = val {
                out.extend([I::LocalGet(t), I::I32Load(mem_arg(4 * k, 2)), I::LocalSet(v)]);
            }
            if let Some(p) = ptr {
                out.extend([I::LocalGet(data), I::LocalGet(t), I::I32Load(mem_arg(4 * k, 2)), I::I32Add, I::LocalSet(p)]);
            }
        }
        out
    }
}
