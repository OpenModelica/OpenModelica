// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/Print.mo`'s `external "C"`
// declarations into `OMCompiler/Compiler/runtime/printimpl.c`. The C
// runtime maintains two per-thread `std::string` buffers (a normal print
// buffer and an error buffer), plus a stack of saved buffers used by
// templates that want to render a subtree, capture the text, and then
// roll back to the prior buffer.
//
// We mirror that design with `thread_local!` `RefCell`s. The buffers are
// kept as `String` for cheap byte-level append; conversion to `ArcStr`
// happens only at the boundary functions `getString` / `getErrorString`
// which the MetaModelica callers consume.

#![allow(non_snake_case)]

use std::cell::RefCell;
use std::collections::HashMap;
use std::fs::OpenOptions;
use std::io::Write as _;

use anyhow::{Context, Result};
use arcstr::ArcStr;

#[derive(Default)]
struct PrintState {
    buf: String,
    err_buf: String,
    saved: HashMap<i32, String>,
    next_handle: i32,
}

thread_local! {
    static STATE: RefCell<PrintState> = RefCell::new(PrintState::default());
}

fn with<R>(f: impl FnOnce(&mut PrintState) -> R) -> R {
    STATE.with(|s| f(&mut s.borrow_mut()))
}

pub fn clearBuf() {
    with(|s| s.buf.clear());
}

pub fn clearErrorBuf() {
    with(|s| s.err_buf.clear());
}

pub fn getBufLength() -> i32 {
    with(|s| s.buf.len() as i32)
}

pub fn getErrorString() -> Result<ArcStr> {
    Ok(with(|s| ArcStr::from(s.err_buf.as_str())))
}

pub fn getString() -> Result<ArcStr> {
    Ok(with(|s| ArcStr::from(s.buf.as_str())))
}

pub fn hasBufNewLineAtEnd() -> bool {
    with(|s| s.buf.ends_with('\n'))
}

pub fn printBuf(inString: ArcStr) -> Result<()> {
    with(|s| s.buf.push_str(&inString));
    Ok(())
}

pub fn printBufNewLine() -> Result<()> {
    with(|s| s.buf.push('\n'));
    Ok(())
}

pub fn printBufSpace(inNumOfSpaces: i32) -> Result<()> {
    if inNumOfSpaces > 0 {
        with(|s| {
            for _ in 0..inNumOfSpaces {
                s.buf.push(' ');
            }
        });
    }
    Ok(())
}

pub fn printErrorBuf(inString: ArcStr) -> Result<()> {
    with(|s| s.err_buf.push_str(&inString));
    Ok(())
}

/// Pop the saved buffer named by `handle` back into the active print
/// buffer. The C runtime swaps the slot in-place; we drop the saved
/// entry so handles are single-use.
pub fn restoreBuf(handle: i32) -> Result<()> {
    with(|s| {
        if let Some(prev) = s.saved.remove(&handle) {
            s.buf = prev;
        }
    });
    Ok(())
}

/// Save the active print buffer under a fresh handle and return that
/// handle to the caller. The buffer is reset to empty so the caller can
/// render a subtree in isolation before calling [`restoreBuf`] to splice
/// the saved text back.
pub fn saveAndClearBuf() -> Result<i32> {
    Ok(with(|s| {
        s.next_handle = s.next_handle.wrapping_add(1);
        if s.next_handle == 0 {
            s.next_handle = 1;
        }
        let h = s.next_handle;
        let prev = std::mem::take(&mut s.buf);
        s.saved.insert(h, prev);
        h
    }))
}

pub fn writeBuf(filename: ArcStr) -> Result<()> {
    let contents = with(|s| s.buf.clone());
    let mut f = OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(true)
        .open(filename.as_str())
        .with_context(|| format!("Print.writeBuf: cannot open {filename}"))?;
    f.write_all(contents.as_bytes())
        .with_context(|| format!("Print.writeBuf: write failed for {filename}"))?;
    Ok(())
}

/// Parse one `/*#modelicaLine [file:lineStart:colStart-lineEnd:colEnd]*/`
/// marker line, returning `(file, lineStart)`. Mirrors `re_str[0]` in
/// `PrintImpl__writeBufConvertLines`:
///
/// * Unix:    `^ */[*]#modelicaLine .([^:]*):([0-9]*):[0-9]*-[0-9]*:[0-9]*.[*]/$`
/// * Windows: `^ */[*]#modelicaLine .(.:/[^:]*):([0-9]*):[0-9]*-[0-9]*:[0-9]*.[*]/$`
///   (drive letter included in the file group)
///
/// Like the regex, the digit runs may be empty (strtol of "" yields 0) and
/// the line must end immediately after the closing `*/`.
fn parse_modelica_line_marker(line: &str) -> Option<(&str, u64)> {
    fn split_digits(s: &str) -> (&str, &str) {
        let end = s.bytes().take_while(u8::is_ascii_digit).count();
        s.split_at(end)
    }
    let s = line.trim_start_matches(' ');
    let s = s.strip_prefix("/*#modelicaLine ")?;
    // `.` before the group: the `[` bracket (any single byte in the regex).
    let s = s.get(1..)?;
    // File group: on Windows `(.:/[^:]*)` — one char, ":/", then up to the
    // next colon; on Unix `([^:]*)` — up to the first colon.
    let (file, s) = if cfg!(windows) {
        let drive_end = s.char_indices().nth(1).map(|(i, _)| i)?;
        let rest = s.get(drive_end..)?;
        if !rest.starts_with(":/") {
            return None;
        }
        let after_colon = drive_end + 1;
        let path_len = s[after_colon..].find(':')?;
        s.split_at(after_colon + path_len)
    } else {
        let path_len = s.find(':')?;
        s.split_at(path_len)
    };
    let s = s.strip_prefix(':')?;
    let (line_digits, s) = split_digits(s);
    let line_no = line_digits.parse::<u64>().unwrap_or(0); // strtol("") == 0
    let s = s.strip_prefix(':')?;
    let (_, s) = split_digits(s);
    let s = s.strip_prefix('-')?;
    let (_, s) = split_digits(s);
    let s = s.strip_prefix(':')?;
    let (_, s) = split_digits(s);
    // `.` for the `]` bracket, then the closing `*/` and end of line.
    let mut chars = s.chars();
    chars.next()?;
    if chars.as_str() != "*/" {
        return None;
    }
    Some((file, line_no))
}

/// `^ */[*]#endModelicaLine[*]/$`
fn is_end_modelica_line_marker(line: &str) -> bool {
    line.trim_start_matches(' ') == "/*#endModelicaLine*/"
}

/// Same as [`writeBuf`] but converts the `/*#modelicaLine [...]*/` /
/// `/*#endModelicaLine*/` markers that the code generators emit under
/// `-d=gendebugsymbols` into C `#line` preprocessor directives, so that
/// `__FILE__`/`__LINE__` (and debugger stepping) inside the generated code
/// refer to the originating Modelica source. Faithful port of
/// `PrintImpl__writeBufConvertLines` (`Compiler/runtime/printimpl.c`):
///
/// * a 5-line preamble defines `OMC_FILE` as the generated file's own name
///   (overridable via `OMC_BASE_FILE`);
/// * a begin marker records (file, line) and is itself dropped;
/// * every line inside a marker region is prefixed with
///   `#line <line> "<file>"`;
/// * the end marker becomes `#line <n> OMC_FILE`, switching the location
///   back to the generated file (`n` mirrors the C line counter, including
///   its start value of 6 after the 5-line preamble);
/// * with `OPENMODELICA_BACKEND_STUBS` set, only the basename of the
///   generated file is used in the preamble.
///
/// Like the C version, an empty buffer still creates/truncates the file but
/// reports failure.
pub fn writeBufConvertLines(filename: ArcStr) -> Result<()> {
    let mut f = OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(true)
        .open(filename.as_str())
        .with_context(|| format!("Print.writeBufConvertLines: cannot open {filename}"))?;
    // The C version destructively clears the print buffer on the paths that
    // reach the line-by-line loop (and on the empty-buffer early exit the
    // buffer is empty anyway); it only stays intact when the file cannot be
    // opened, which the `?` above mirrors.
    let contents = with(|s| std::mem::take(&mut s.buf));
    if contents.is_empty() {
        // C: "nothing to write to file, just close it and return 1"
        anyhow::bail!("Print.writeBufConvertLines: nothing to write to {filename}");
    }

    let mut out = String::with_capacity(contents.len() + contents.len() / 8);
    // On Windows the C opens the file in text mode ("wt"), so backslashes in
    // the name are normalised to keep #line paths compileable.
    let own_name = if cfg!(windows) { filename.replace('\\', "/") } else { filename.to_string() };
    let own_name = if std::env::var_os("OPENMODELICA_BACKEND_STUBS").is_some() {
        std::path::Path::new(&own_name)
            .file_name()
            .map(|b| b.to_string_lossy().into_owned())
            .unwrap_or(own_name)
    } else {
        own_name
    };
    out.push_str(&format!(
        "#ifdef OMC_BASE_FILE\n  #define OMC_FILE OMC_BASE_FILE\n#else\n  #define OMC_FILE \"{own_name}\"\n#endif\n"
    ));

    // Number of the next physical output line, 1-based; the preamble above
    // is 5 lines, so the first content line is line 6.
    let mut nlines: u64 = 6;
    let mut region: Option<(String, u64)> = None;
    let mut rest = contents.as_str();
    loop {
        let Some(nl) = rest.find('\n') else {
            // Final fragment without a trailing newline: emitted verbatim.
            out.push_str(rest);
            break;
        };
        let (line, tail) = rest.split_at(nl);
        rest = &tail[1..];
        if let Some((file, line_no)) = parse_modelica_line_marker(line) {
            let file = if cfg!(windows) { file.replace('\\', "/") } else { file.to_string() };
            region = Some((file, line_no));
        } else if is_end_modelica_line_marker(line) {
            // Sometimes there is an #endModelicaLine without a matching
            // begin marker; those are dropped without a directive.
            if region.take().is_some() {
                out.push_str(&format!("#line {nlines} OMC_FILE\n"));
                nlines += 1;
            }
        } else if let Some((file, line_no)) = &region {
            out.push_str(&format!("#line {line_no} \"{file}\"\n"));
            out.push_str(line);
            out.push('\n');
            nlines += 2;
        } else {
            out.push_str(line);
            out.push('\n');
            nlines += 1;
        }
    }

    f.write_all(out.as_bytes())
        .with_context(|| format!("Print.writeBufConvertLines: write failed for {filename}"))?;
    Ok(())
}
