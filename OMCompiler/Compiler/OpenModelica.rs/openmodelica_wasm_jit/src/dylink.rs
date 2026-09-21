//! The `dylink.0` metadata of a shared-everything wasm library.
//!
//! An `external "C"` library for a wasm target is a PIC dylink module: it
//! addresses data through `env.__memory_base` and the table through
//! `env.__table_base`, so the loader may place it anywhere in the simulation's
//! memory. Engine-independent — both hosts drive it.

/// The `WASM_DYLINK_MEM_INFO` subsection.
#[derive(Debug, Clone, Copy, Default)]
pub struct MemInfo {
    pub mem_size: u32,
    /// Power-of-two exponent, as stored (4 means 16-byte alignment).
    pub mem_p2align: u32,
    pub table_size: u32,
    pub table_p2align: u32,
}

impl MemInfo {
    pub fn mem_align(&self) -> u32 {
        1u32 << self.mem_p2align.min(16)
    }
}

/// A parsed `dylink.0` custom section.
#[derive(Debug, Clone, Default)]
pub struct Dylink {
    pub mem: MemInfo,
    pub needed: Vec<String>,
    /// Weakly bound imports: one that nothing defines is a null address rather
    /// than a link failure, which is how `libc.so` references things only a main
    /// module would have.
    pub weak_imports: Vec<String>,
}

const SUB_MEM_INFO: u8 = 1;
const SUB_NEEDED: u8 = 2;
const SUB_IMPORT_INFO: u8 = 4;
const SYM_WEAK: u32 = 0x01;

fn uleb(bytes: &[u8], pos: &mut usize) -> Option<u32> {
    let mut result: u64 = 0;
    let mut shift = 0;
    loop {
        let b = *bytes.get(*pos)?;
        *pos += 1;
        result |= ((b & 0x7f) as u64) << shift;
        if b & 0x80 == 0 {
            break;
        }
        shift += 7;
        if shift > 35 {
            return None;
        }
    }
    u32::try_from(result).ok()
}

fn name<'a>(bytes: &'a [u8], pos: &mut usize) -> Option<&'a str> {
    let len = uleb(bytes, pos)? as usize;
    let s = bytes.get(*pos..*pos + len)?;
    *pos += len;
    core::str::from_utf8(s).ok()
}

/// The `dylink.0` section, or `None` when the module is not a shared library —
/// which the caller reports, `-c` instead of `-shared` being an easy mistake.
pub fn parse(module: &[u8]) -> Option<Dylink> {
    // Magic + version, then (id, size, payload) sections.
    if module.len() < 8 || &module[..4] != b"\0asm" {
        return None;
    }
    let mut pos = 8;
    while pos < module.len() {
        let id = *module.get(pos)?;
        pos += 1;
        let size = uleb(module, &mut pos)? as usize;
        let end = pos.checked_add(size)?;
        if id != 0 {
            // dylink.0 precedes every non-custom section.
            return None;
        }
        let mut p = pos;
        let sec_name = name(module, &mut p)?;
        if sec_name == "dylink.0" {
            return parse_dylink0(module.get(p..end)?);
        }
        pos = end;
    }
    None
}

fn parse_dylink0(body: &[u8]) -> Option<Dylink> {
    let mut out = Dylink::default();
    let mut pos = 0usize;
    while pos < body.len() {
        let id = *body.get(pos)?;
        pos += 1;
        let size = uleb(body, &mut pos)? as usize;
        let end = pos.checked_add(size)?;
        match id {
            SUB_MEM_INFO => {
                let mut p = pos;
                out.mem = MemInfo {
                    mem_size: uleb(body, &mut p)?,
                    mem_p2align: uleb(body, &mut p)?,
                    table_size: uleb(body, &mut p)?,
                    table_p2align: uleb(body, &mut p)?,
                };
            }
            SUB_NEEDED => {
                let mut p = pos;
                let count = uleb(body, &mut p)?;
                for _ in 0..count {
                    out.needed.push(name(body, &mut p)?.to_string());
                }
            }
            SUB_IMPORT_INFO => {
                let mut p = pos;
                let count = uleb(body, &mut p)?;
                for _ in 0..count {
                    let _module = name(body, &mut p)?;
                    let field = name(body, &mut p)?;
                    if uleb(body, &mut p)? & SYM_WEAK != 0 {
                        out.weak_imports.push(field.to_string());
                    }
                }
            }
            _ => {}
        }
        pos = end;
    }
    Some(out)
}

/// Round `addr` up to `align` (a power of two).
pub fn align_up(addr: u32, align: u32) -> u32 {
    let align = align.max(1);
    addr.wrapping_add(align - 1) & !(align - 1)
}

/// The stack a loaded library runs on, shared by every side library (they share
/// one `env.__stack_pointer`) and separate from the runtime's own.
pub const SIDE_STACK_SIZE: u32 = 512 * 1024;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_mem_info_and_needed() {
        let mut body = Vec::new();
        body.push(SUB_MEM_INFO);
        body.push(4);
        body.extend_from_slice(&[52, 2, 0, 0]);
        body.push(SUB_NEEDED);
        let needed = b"libc.so";
        body.push((1 + 1 + needed.len()) as u8);
        body.push(1);
        body.push(needed.len() as u8);
        body.extend_from_slice(needed);

        let mut sec = Vec::new();
        sec.push(8u8);
        sec.extend_from_slice(b"dylink.0");
        sec.extend_from_slice(&body);

        let mut module = Vec::new();
        module.extend_from_slice(b"\0asm\x01\0\0\0");
        module.push(0); // custom section
        module.push(sec.len() as u8);
        module.extend_from_slice(&sec);

        let d = parse(&module).expect("dylink.0 parses");
        assert_eq!(d.mem.mem_size, 52);
        assert_eq!(d.mem.mem_align(), 4);
        assert_eq!(d.needed, vec!["libc.so".to_string()]);
    }

    #[test]
    fn a_module_without_dylink0_is_not_a_library() {
        let module = b"\0asm\x01\0\0\0";
        assert!(parse(module).is_none());
    }

    #[test]
    fn align_up_rounds_to_power_of_two() {
        assert_eq!(align_up(0, 16), 0);
        assert_eq!(align_up(1, 16), 16);
        assert_eq!(align_up(16, 16), 16);
        assert_eq!(align_up(17, 16), 32);
    }
}

// ── the wasm C ABI a library's prototype speaks ─────────────────────────────
//
// Both hosts marshal by these rules, and an FMU export lays records out the same.

/// The C struct a callee declares, in the wasm32 ABI (4-byte pointers).
pub fn c_record_layout(fields: &[(arcstr::ArcStr, crate::sig::SigTy)]) -> crate::sig::CRecordLayout {
    crate::sig::c_record_layout(fields, 4)
}

/// How the wasm C ABI passes a value.
pub enum Abi {
    /// No members: no argument, no result.
    Dropped,
    /// A struct with exactly one member passes and returns as that member,
    /// recursively: clang lowers `struct One { double x; } f(double)` to
    /// `(f64) -> f64`.
    Scalar(crate::sig::SigTy),
    /// By pointer; a return value gets a prepended `sret` pointer.
    Indirect,
}

pub fn abi_of(t: &crate::sig::SigTy) -> Abi {
    use crate::sig::SigTy;
    match t {
        SigTy::Record { fields, .. } => match fields.len() {
            0 => Abi::Dropped,
            1 => abi_of(&fields[0].1),
            _ => Abi::Indirect,
        },
        other => Abi::Scalar(other.clone()),
    }
}

/// The member a single-member struct collapses to, as `(offset from the record
/// object's base, type)`. Descends nested single-member records.
pub fn record_leaf(fields: &[(arcstr::ArcStr, crate::sig::SigTy)]) -> (u32, crate::sig::SigTy) {
    use crate::sig::SigTy;
    let layout = crate::sig::record_layout(fields);
    let off = layout.data_off + layout.field_off.first().copied().unwrap_or(0);
    match fields.first().map(|(_, t)| t) {
        Some(SigTy::Record { fields: inner, .. }) if inner.len() == 1 => {
            // The member is itself a record *object*, so its own base is stored here.
            let (inner_off, ty) = record_leaf(inner);
            (off + inner_off, ty)
        }
        Some(t) => (off, t.clone()),
        None => (off, SigTy::Int),
    }
}

/// Whether the import can bind straight to the library's export: every argument
/// and the result already have the representation C expects, so nothing has to be
/// converted. `Ptr` qualifies — an external object is an opaque handle only the
/// library dereferences.
pub fn is_direct_call(sig: &crate::sig::ExtCallSig) -> bool {
    use crate::sig::SigTy;
    fn scalar(t: &SigTy) -> bool {
        matches!(t, SigTy::Int | SigTy::Real | SigTy::Bool | SigTy::Ptr)
    }
    sig.lang == crate::sig::ExtLang::C
        && sig.args.iter().all(|(t, is_out)| !*is_out && scalar(t))
        && sig.ret.as_ref().is_none_or(scalar)
}

// ── choosing the libraries a model needs ────────────────────────────────────

/// The libraries omc carries that a model reaching `symbols` has to be given,
/// **dependencies first** — the order the native loader places `libc.so` in.
/// Placed the other way, an import can only get a host trampoline, which is slow
/// and, on wasmer's js backend, wrong: it passes an `i64` through a JS number, so
/// HDF5's `hid_t` arguments fail to convert.
///
/// The index (`wasm-blobs/index.json`) names only the entry points a model can
/// declare; the rest follows from `dylink.0` NEEDED. A model that scans a string
/// is given ModelicaExternalC alone; one that reads a table is given zlib → HDF5
/// → ModelicaMatIO → ModelicaIO → ModelicaStandardTables.
pub fn libraries_for(symbols: impl IntoIterator<Item = impl AsRef<str>>) -> Vec<&'static str> {
    let mut wanted: Vec<&'static str> = Vec::new();
    for sym in symbols {
        let Some(file) = crate::ondemand_library_for(sym.as_ref()) else { continue };
        push_with_needed(file, &mut wanted);
    }
    wanted
}

/// Everything `file` needs, then `file`.
fn push_with_needed(file: &'static str, out: &mut Vec<&'static str>) {
    if out.contains(&file) {
        return;
    }
    // Before the recursion, so a cycle cannot spin.
    out.push(file);
    let at = out.len() - 1;
    let Some(bytes) = crate::ext_library(file) else { return };
    let Some(dl) = parse(bytes) else { return };
    for dep in dl.needed {
        // The name a dependency was linked under is the file it ships as; only a
        // library omc carries can be resolved here, and `libc.so` is always given.
        let Some((known, _)) = crate::EXT_FAMILY.iter().find(|(f, _)| *f == dep) else { continue };
        push_with_needed(known, out);
    }
    // Everything the recursion added belongs in front of this one.
    let me = out.remove(at);
    out.push(me);
}

