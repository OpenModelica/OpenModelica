//! The `.wasm.sig` sidecar: parsing and writing signature lines.

use super::*;

pub(super) fn parse_sig_type(chars: &mut std::iter::Peekable<std::str::Chars>) -> Result<SigTy> {
    match chars.next() {
        Some('I') => Ok(SigTy::Int),
        Some('R') => Ok(SigTy::Real),
        Some('B') => Ok(SigTy::Bool),
        Some('S') => Ok(SigTy::Str),
        Some('P') => Ok(SigTy::Ptr),
        Some('[') => {
            // Consecutive `'['`s are the rank of one array (Modelica arrays are
            // rectangular, so the element after them is a scalar, never another
            // array).
            let mut rank = 1u32;
            while chars.peek() == Some(&'[') {
                chars.next();
                rank += 1;
            }
            Ok(SigTy::Array { elem: Arc::new(parse_sig_type(chars)?), rank })
        }
        // `{path;name:code;…}` — a record (see [`SigTy::write_code`]).
        Some('{') => {
            let mut path = String::new();
            while let Some(&c) = chars.peek() {
                if matches!(c, ';' | '}') {
                    break;
                }
                chars.next();
                path.push(c);
            }
            let mut fields = Vec::new();
            while chars.peek() == Some(&';') {
                chars.next(); // ';'
                let mut name = String::new();
                loop {
                    match chars.next() {
                        Some(':') => break,
                        Some(c) => name.push(c),
                        None => return Err("CodegenWasmJit: unterminated record field in signature"),
                    }
                }
                fields.push((ArcStr::from(name.as_str()), parse_sig_type(chars)?));
            }
            match chars.next() {
                Some('}') => {}
                other => return Err("CodegenWasmJit: expected a closing brace in record signature"),
            }
            Ok(SigTy::Record { path: ArcStr::from(path.as_str()), fields: Arc::new(fields) })
        }
        // `<params|results>` — a function reference (see [`SigTy::write_code`]).
        Some('<') => {
            let mut params = Vec::new();
            while !matches!(chars.peek(), Some('|') | None) {
                params.push(parse_sig_type(chars)?);
            }
            if chars.next() != Some('|') {
                return Err("CodegenWasmJit: expected `|` in function-reference signature");
            }
            let mut results = Vec::new();
            while !matches!(chars.peek(), Some('>') | None) {
                results.push(parse_sig_type(chars)?);
            }
            if chars.next() != Some('>') {
                return Err("CodegenWasmJit: expected a closing `>` in function-reference signature");
            }
            Ok(SigTy::Func { params: Arc::new(params), results: Arc::new(results) })
        }
        other => return Err("CodegenWasmJit: malformed signature type code"),
    }
}
