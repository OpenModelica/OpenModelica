//! Frontend-free wasm-signature types shared by the function codegen and the
//! simulation host: how a Modelica value type maps to wasm value types and to
//! the `.wasm.sig` sidecar encoding, plus the external-"C" call shape.

use std::sync::Arc;

use arcstr::ArcStr;
use wasm_encoder as we;

pub use openmodelica_sim_meta::WTy;

pub trait WTyVal {
    fn val(self) -> we::ValType;
}
impl WTyVal for WTy {
    fn val(self) -> we::ValType {
        match self {
            WTy::I32 => we::ValType::I32,
            WTy::F64 => we::ValType::F64,
        }
    }
}

/// One Modelica value type, as the wasm-jit models it and as recorded in the
/// `.wasm.sig` sidecar so `loadAndExecute` can map wasm values back to the right
/// `Values.Value` constructor (an `i32` result is otherwise ambiguous between
/// Integer, Boolean and a heap handle).
///
/// Scalars map to a wasm value type ([`SigTy::wty`]). `Str` and `Array` are
/// reference-counted heap values represented by an `i32` handle into the shared
/// runtime heap. `Array` carries its scalar element type and rank (number of
/// dimensions); Modelica arrays are rectangular, so the rank captures every
/// dimension rather than nesting `Array`s. The element stride, load/store value
/// type, release entry point and marshalling are all derivable from `elem`; the
/// runtime array object additionally records the element kind and the per-axis
/// sizes in its header so a single `rt_array_release` frees nested heap
/// elements and indexing/`size` work for any rank.
#[derive(Clone, PartialEq, Eq, Debug)]
pub enum SigTy {
    Int,
    Real,
    Bool,
    /// A `String`: an `i32` handle; the bytes live in linear memory.
    Str,
    /// An N-dimensional array of `elem` with `rank` dimensions: an `i32` handle
    /// to a runtime array object (flat row-major storage).
    Array { elem: Arc<SigTy>, rank: u32 },
    /// A record: an `i32` handle to a runtime record object. `path` is the
    /// record's class name (for `Values.RECORD`); `fields` are its components in
    /// declaration order (name + type), which fix the field layout.
    Record { path: ArcStr, fields: Arc<Vec<(ArcStr, SigTy)>> },
    /// An external object: a native `void*` (e.g. a table `tableID`). Held in
    /// wasm as an opaque `i32` handle into the host's pointer registry; not a
    /// wasm heap value (no ARC — freed by the object's `destructor`).
    Ptr,
    /// A function reference (`function f(w=3)`): an `i32` handle to a runtime
    /// closure (see the codegen's `closures` module). The signature is what the
    /// holder may call, fixing the `call_indirect` type at every call site.
    Func { params: Arc<Vec<SigTy>>, results: Arc<Vec<SigTy>> },
}

impl SigTy {
    /// Append this type's `.wasm.sig` encoding to `out`. Scalars are a single
    /// letter; a rank-`k` array is `k` `'['`s followed by its scalar element
    /// encoding (e.g. `"[R"` for `Real[:]`, `"[[I"` for `Integer[:,:]`). The
    /// `'['` prefix lets the reader consume one whole type without separators.
    pub fn write_code(&self, out: &mut String) {
        match self {
            SigTy::Int => out.push('I'),
            SigTy::Real => out.push('R'),
            SigTy::Bool => out.push('B'),
            SigTy::Str => out.push('S'),
            SigTy::Array { elem, rank } => {
                for _ in 0..*rank {
                    out.push('[');
                }
                elem.write_code(out);
            }
            // `{path;name:code;name:code…}` — a record, brace-delimited so the
            // reader can consume one whole (possibly nested) record type. Names
            // and dotted paths never contain `{};:` so those are safe delimiters.
            SigTy::Record { path, fields } => {
                out.push('{');
                out.push_str(path);
                for (name, code) in fields.iter() {
                    out.push(';');
                    out.push_str(name);
                    out.push(':');
                    code.write_code(out);
                }
                out.push('}');
            }
            SigTy::Ptr => out.push('P'),
            // `<params|results>` — a function reference, angle-delimited so the
            // reader can consume one whole (possibly nested) signature.
            SigTy::Func { params, results } => {
                out.push('<');
                for p in params.iter() {
                    p.write_code(out);
                }
                out.push('|');
                for r in results.iter() {
                    r.write_code(out);
                }
                out.push('>');
            }
        }
    }
    pub fn wty(&self) -> WTy {
        match self {
            SigTy::Real => WTy::F64,
            _ => WTy::I32,
        }
    }
    /// The runtime element-kind tag stored in an array header when this type is
    /// the array's element. Must stay in sync with the runtime's `EK_*` constants.
    pub fn elem_kind(&self) -> u32 {
        match self {
            SigTy::Int => 0,
            SigTy::Real => 1,
            SigTy::Bool => 2,
            SigTy::Str => 3,
            SigTy::Array { .. } => 4,
            // A closure is a record object, so it releases/copies like one.
            SigTy::Record { .. } | SigTy::Func { .. } => 5,
            // Not a real runtime element kind: arrays of external objects don't
            // occur (table data is Real/Integer). Stored 4-byte, non-heap.
            SigTy::Ptr => 0,
        }
    }
    /// The runtime release entry point for a heap value of this type, or `None`
    /// for a non-heap scalar. Used wherever an owned heap value is freed.
    pub fn release_fn(&self) -> Option<&'static str> {
        match self {
            SigTy::Str => Some("rt_release"),
            SigTy::Array { .. } => Some("rt_array_release"),
            SigTy::Record { .. } | SigTy::Func { .. } => Some("rt_record_release"),
            _ => None,
        }
    }
    /// Whether this is a reference-counted heap value (needs ARC on
    /// assignment / at scope exit).
    pub fn is_heap(&self) -> bool {
        self.release_fn().is_some()
    }
}

#[derive(Clone)]
pub struct FnSig {
    pub params: Vec<SigTy>,
    pub results: Vec<SigTy>,
}

/// The calling convention of an external function's `extArgs`.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum ExtLang {
    /// `external "C"` / `external "builtin"`: scalars by value, arrays row-major.
    C,
    /// `external "FORTRAN 77"`: every argument by reference, arrays column-major.
    Fortran77,
}

/// The C-call shape of a general external "C" import. `args` is the C argument
/// list in `extArgs` order, each flagged as an `_Out_` pointer or not; `ret` is
/// the C return-value type (`None` for a `void` function). The corresponding wasm
/// import takes the *input* args (and any *output arrays*, which are pre-allocated
/// by the wasm side and passed by pointer) as parameters, and returns the scalar/
/// string outputs — the C return value first (if any), then each `_Out_` scalar/
/// string pointer's written value — as multi-value results. Array outputs are
/// filled in place (native) or copied back by the host (web), so they are NOT
/// results. The host trampoline owns all pointer marshalling, including the
/// by-reference/column-major conversions `lang == Fortran77` asks for.
#[derive(Clone)]
pub struct ExtCallSig {
    /// The linker symbol; already `_`-suffixed for [`ExtLang::Fortran77`].
    pub name: String,
    pub lang: ExtLang,
    pub args: Vec<(SigTy, bool)>,
    pub ret: Option<SigTy>,
}

impl ExtCallSig {
    /// Array args are always passed by pointer (the buffer is pre-allocated on the
    /// wasm side), so both input and output arrays are wasm *parameters*; only
    /// scalar/string `_Out_` args come back as results.
    fn as_result(ty: &SigTy, is_out: bool) -> bool {
        is_out && !matches!(ty, SigTy::Array { .. })
    }
    /// The wasm import parameters: input args + output arrays, in `extArgs` order.
    pub fn wasm_params(&self) -> Vec<SigTy> {
        self.args.iter().filter(|(t, is_out)| !Self::as_result(t, *is_out)).map(|(t, _)| t.clone()).collect()
    }
    /// The wasm import results: the C return value (if any) then each scalar/string
    /// `_Out_` arg, in `extArgs` order — matching those output variables' order.
    pub fn wasm_results(&self) -> Vec<SigTy> {
        let mut r: Vec<SigTy> = self.ret.iter().cloned().collect();
        r.extend(self.args.iter().filter(|(t, is_out)| Self::as_result(t, *is_out)).map(|(t, _)| t.clone()));
        r
    }
    pub fn wasm_sig(&self) -> FnSig {
        FnSig { params: self.wasm_params(), results: self.wasm_results() }
    }
}

// ─────────────────────────── record objects ───────────────────────────

/// 8 bytes for a `Real`, 4 for everything else (an `Integer`/`Boolean`, a handle).
pub fn field_size(t: &SigTy) -> u32 {
    if matches!(t, SigTy::Real) { 8 } else { 4 }
}

fn align_up(n: u32, a: u32) -> u32 {
    (n + a - 1) & !(a - 1)
}

/// The byte layout of a record object's payload, which must agree with
/// `rec_data_off` in the runtime. `data_off` is the offset from the object base to
/// the first field (after the refcount, `nheap` and the inline release table),
/// `field_off[i]` field `i`'s offset within the field data, `heap` the
/// `(elem_kind, field_off)` of each heap field.
pub struct RecordLayout {
    pub data_off: u32,
    pub size: u32,
    pub field_off: Vec<u32>,
    pub heap: Vec<(u32, u32)>,
}

pub fn record_layout(fields: &[(ArcStr, SigTy)]) -> RecordLayout {
    let nheap = fields.iter().filter(|(_, t)| t.is_heap()).count() as u32;
    let data_off = align_up(8 + nheap * 8, 8);
    let mut off = 0u32;
    let mut field_off = Vec::with_capacity(fields.len());
    let mut heap = Vec::new();
    for (_, t) in fields {
        let sz = field_size(t);
        off = align_up(off, sz);
        field_off.push(off);
        if t.is_heap() {
            heap.push((t.elem_kind(), off));
        }
        off += sz;
    }
    RecordLayout { data_off, size: data_off + align_up(off, 8), field_off, heap }
}

/// The layout of C's `<record>_external`: `double`, `int`, a `ptr`-wide pointer
/// for a String/external object/array, a nested record inlined.
pub struct CRecordLayout {
    pub size: u32,
    pub align: u32,
    pub offsets: Vec<u32>,
}

pub fn c_size_align(t: &SigTy, ptr: u32) -> (u32, u32) {
    match t {
        SigTy::Real => (8, 8),
        SigTy::Int | SigTy::Bool => (4, 4),
        SigTy::Record { fields, .. } => {
            let l = c_record_layout(fields, ptr);
            (l.size, l.align)
        }
        _ => (ptr, ptr),
    }
}

pub fn c_record_layout(fields: &[(ArcStr, SigTy)], ptr: u32) -> CRecordLayout {
    let mut off = 0u32;
    let mut align = 1u32;
    let mut offsets = Vec::with_capacity(fields.len());
    for (_, t) in fields {
        let (sz, a) = c_size_align(t, ptr);
        off = align_up(off, a);
        offsets.push(off);
        off += sz;
        align = align.max(a);
    }
    CRecordLayout { size: align_up(off, align), align, offsets }
}

