// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/IOStreamExt.mo`'s `external "C"`
// declarations into `OMCompiler/Compiler/runtime/IOStreamExt_omc.cpp`.
//
// The C runtime only actually implements `appendReversedList` and
// `printReversedList`; every file/buffer entry point prints `NYI` to
// stderr and throws (the IOStream module's LIST() backend is the only one
// the compiler uses). We mirror that exactly: the unimplemented functions
// report and fail instead of panicking, so MetaModelica-level
// try/matchcontinue around them keeps working.

#![allow(non_snake_case)]

use std::sync::Arc;

use anyhow::{Result, bail};
use arcstr::ArcStr;
use metamodelica::List;

/// Shared body for the entry points that are NYI in the C runtime too:
/// report on stderr (like the `fprintf(stderr, "NYI: ...")` there) and
/// fail (MMC_THROW).
macro_rules! nyi {
    ($name:literal) => {{
        eprintln!(concat!("NYI: IOStreamExt.", $name));
        bail!(concat!("NYI: IOStreamExt.", $name));
    }};
}

pub fn createFile(_fileName: ArcStr) -> Result<i32> {
    nyi!("createFile")
}

pub fn closeFile(_fileID: i32) -> Result<()> {
    nyi!("closeFile")
}

pub fn deleteFile(_fileID: i32) -> Result<()> {
    nyi!("deleteFile")
}

pub fn clearFile(_fileID: i32) -> Result<()> {
    nyi!("clearFile")
}

pub fn appendFile(_fileID: i32, _inString: ArcStr) -> Result<()> {
    nyi!("appendFile")
}

pub fn readFile(_fileID: i32) -> Result<ArcStr> {
    nyi!("readFile")
}

pub fn printFile(_fileID: i32, _whereToPrint: i32) -> Result<()> {
    nyi!("printFile")
}

pub fn createBuffer() -> Result<i32> {
    nyi!("createBuffer")
}

pub fn appendBuffer(_bufferID: i32, _inString: ArcStr) -> Result<()> {
    nyi!("appendBuffer")
}

pub fn deleteBuffer(_bufferID: i32) -> Result<()> {
    nyi!("deleteBuffer")
}

pub fn clearBuffer(_bufferID: i32) -> Result<()> {
    nyi!("clearBuffer")
}

pub fn readBuffer(_bufferID: i32) -> Result<ArcStr> {
    nyi!("readBuffer")
}

pub fn printBuffer(_bufferID: i32, _whereToPrint: i32) -> Result<()> {
    nyi!("printBuffer")
}

/// Concatenate a *reversed* list of strings: the IOStream LIST() backend
/// conses new chunks onto the head, so the last list element is the first
/// chunk of the output.
pub fn appendReversedList(inStringLst: Arc<List<ArcStr>>) -> ArcStr {
    let chunks: Vec<&ArcStr> = (&*inStringLst).into_iter().collect();
    let total: usize = chunks.iter().map(|s| s.len()).sum();
    let mut out = String::with_capacity(total);
    for s in chunks.into_iter().rev() {
        out.push_str(s);
    }
    ArcStr::from(out)
}

/// Print a *reversed* list of strings to stdout (`whereToPrint` = 1) or
/// stderr (= 2); any other destination fails like the C version.
pub fn printReversedList(inStringLst: Arc<List<ArcStr>>, whereToPrint: i32) -> Result<()> {
    use std::io::Write;
    let chunks: Vec<&ArcStr> = (&*inStringLst).into_iter().collect();
    match whereToPrint {
        1 => {
            let stdout = std::io::stdout();
            let mut f = stdout.lock();
            for s in chunks.into_iter().rev() {
                f.write_all(s.as_bytes())?;
            }
            f.flush()?;
        }
        2 => {
            let stderr = std::io::stderr();
            let mut f = stderr.lock();
            for s in chunks.into_iter().rev() {
                f.write_all(s.as_bytes())?;
            }
            f.flush()?;
        }
        _ => bail!("IOStreamExt.printReversedList: invalid whereToPrint {whereToPrint}"),
    }
    Ok(())
}
