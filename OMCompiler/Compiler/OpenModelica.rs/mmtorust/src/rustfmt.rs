//! Pipes generated Rust through `rustfmt` before it is written, so the
//! transpiled sources follow the same `rustfmt.toml` as the hand-written ones
//! (which CI checks with `format.sh --check`).
//!
//! Shared by the two tools that write `.rs` files: mmtorust, and the `susan`
//! binary's Rust backend, which `#[path]`-includes this file.
//!
//! Formatting happens on the string, before `write_if_changed` compares it with
//! the file on disk, so an unchanged transpile still leaves the file (and its
//! mtime) alone. rustfmt reads stdin, so it does not follow `mod` declarations.
//! It leaves the bodies of brace macros alone, so the `match_deref! { ... }`
//! blocks keep the generator's layout.
//!
//! `MMTORUST_RUSTFMT=off` skips formatting (e.g. to compare raw generator
//! output); any other value names the rustfmt executable to run.

use std::io::{Read, Write};
use std::path::Path;
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc;
use std::time::{Duration, Instant};

/// Set once rustfmt cannot be started, so a missing rustfmt is reported once
/// instead of once per generated file.
static UNAVAILABLE: AtomicBool = AtomicBool::new(false);

/// Returns `code` formatted as if it lived at `dest`, or `code` unchanged when
/// rustfmt is disabled, missing, or rejects it (the warning names the file; a
/// rejection means the generator emitted invalid syntax, which the cargo build
/// reports in full).
pub fn format(code: &str, dest: &Path) -> String {
    let exe = std::env::var("MMTORUST_RUSTFMT").unwrap_or_else(|_| "rustfmt".to_owned());
    if exe == "off" || exe == "0" || UNAVAILABLE.load(Ordering::Relaxed) {
        return code.to_owned();
    }
    match run(&exe, code, dest) {
        Ok(formatted) => formatted,
        Err(Error::Spawn(e)) => {
            if !UNAVAILABLE.swap(true, Ordering::Relaxed) {
                eprintln!("warning: cannot run {exe} ({e}); generated Rust is written unformatted");
            }
            code.to_owned()
        }
        Err(Error::Failed(e)) => {
            eprintln!("warning: {}: not formatted: {e}", dest.display());
            code.to_owned()
        }
    }
}

enum Error {
    /// rustfmt could not be started at all.
    Spawn(std::io::Error),
    /// rustfmt ran but rejected the input, or talking to it failed.
    Failed(String),
}

fn run(exe: &str, code: &str, dest: &Path) -> Result<String, Error> {
    let dest = std::path::absolute(dest).map_err(|e| Error::Failed(e.to_string()))?;
    // The rustfmt.toml rustfmt would pick for a file at `dest`.
    let config = dest
        .ancestors()
        .skip(1)
        .map(|d| d.join("rustfmt.toml"))
        .find(|p| p.is_file());
    let mut cmd = Command::new(exe);
    cmd.args(["--emit", "stdout"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    match &config {
        Some(cfg) => {
            cmd.arg("--config-path").arg(cfg);
            // rust-toolchain.toml sits next to rustfmt.toml, so starting there
            // makes the rustup proxy pick the pinned toolchain's rustfmt (susan
            // runs from the Template source directory, outside any workspace).
            cmd.current_dir(cfg.parent().unwrap());
        }
        None => {
            cmd.args(["--edition", "2024"]);
        }
    }
    let mut child = cmd.spawn().map_err(Error::Spawn)?;
    // Each pipe gets its own detached thread, so a full pipe cannot deadlock
    // rustfmt, and the output is collected with a deadline: a reader is not
    // waited for after a timeout, since a grandchild (e.g. of a wrapper
    // script) may hold the pipe open after the child is killed.
    let mut stdin = child.stdin.take().unwrap();
    let input = code.to_owned();
    std::thread::spawn(move || stdin.write_all(input.as_bytes()));
    let stdout = read_in_background(child.stdout.take().unwrap());
    let stderr = read_in_background(child.stderr.take().unwrap());
    let deadline = Instant::now() + TIMEOUT;
    let timed_out = || Error::Failed(format!("{exe} timed out after {}s", TIMEOUT.as_secs()));
    let status = loop {
        match child.try_wait() {
            Ok(Some(status)) => break status,
            Ok(None) if Instant::now() < deadline => std::thread::sleep(Duration::from_millis(5)),
            Ok(None) => {
                let _ = child.kill();
                let _ = child.wait();
                return Err(timed_out());
            }
            Err(e) => return Err(Error::Failed(format!("{exe}: {e}"))),
        }
    };
    // rustfmt has exited, so its pipes are closed and the readers finish at
    // once; the floor only matters when it exited just before the deadline.
    let remaining = deadline
        .saturating_duration_since(Instant::now())
        .max(Duration::from_secs(5));
    let out = stdout.recv_timeout(remaining).map_err(|_| timed_out())?;
    let err = stderr.recv_timeout(remaining).unwrap_or_default();
    if !status.success() || out.is_empty() {
        let err = String::from_utf8_lossy(&err);
        let first = err.lines().next().unwrap_or("no output");
        return Err(Error::Failed(format!("{exe} failed ({status}): {first}")));
    }
    String::from_utf8(out).map_err(|e| Error::Failed(e.to_string()))
}

/// rustfmt is exponential on some deeply nested expressions. Generated code
/// avoids the known cases (see `chain_cmps` in codegen.rs); this bounds the
/// cost of an unknown one to a warning and an unformatted file instead of a
/// build that hangs. A normal file takes well under a second.
const TIMEOUT: Duration = Duration::from_secs(60);

/// Reads `pipe` to the end on a detached thread; the result arrives on the
/// returned channel (an empty buffer if reading failed).
fn read_in_background(mut pipe: impl Read + Send + 'static) -> mpsc::Receiver<Vec<u8>> {
    let (tx, rx) = mpsc::channel();
    std::thread::spawn(move || {
        let mut buf = Vec::new();
        let _ = pipe.read_to_end(&mut buf);
        let _ = tx.send(buf);
    });
    rx
}
