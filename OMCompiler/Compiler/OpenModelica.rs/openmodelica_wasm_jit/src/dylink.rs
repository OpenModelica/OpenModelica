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
