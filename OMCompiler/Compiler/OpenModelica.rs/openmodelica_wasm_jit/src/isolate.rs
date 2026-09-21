//! Running one simulation in a child process.
//!
//! wasm is sandboxed; the platform libraries an `external "C"` reaches through
//! libffi are not, and one that segfaults, calls `exit()`, aborts from a thread
//! of its own or never returns takes the whole process with it. C's model is an
//! executable, so that is a failed simulation there. Here it would be omc.
//!
//! The child does the whole run (writing the result file and `<prefix>.log`
//! itself) and hands back one payload; the parent waits, enforces the deadline
//! and reports what became of it. POSIX only — Windows keeps the in-process run.

/// What became of the child.
pub enum Outcome {
    /// It ran to the end and answered with this payload.
    Answered(Vec<u8>),
    /// It died before answering: killed by a signal, or `exit()`ed from inside a
    /// library. The string is the reason, for the run's log.
    Died(String),
    /// The `-alarm` deadline passed with the child still running.
    TimedOut,
    /// The host asked to stop (omc's own alarm, a UI Cancel) while it ran.
    Cancelled,
}

/// How long past its own `-alarm` the child may take before the parent kills it:
/// the deadline is the driver's to honour, and this only catches a run wedged
/// where the driver cannot look — inside one call into wasm, or inside a
/// platform library.
#[cfg(all(unix, not(target_arch = "wasm32")))]
fn grace(secs: u32) -> u64 {
    (secs as u64 / 10).clamp(5, 60)
}

/// Run `f` in a child process and return its payload. `alarm` is the run's
/// `-alarm=N`; the parent also polls the host's cancel flag, which the child's
/// copy can no longer see. `None` means the fork itself failed and the caller
/// should run in this process after all.
#[cfg(all(unix, not(target_arch = "wasm32")))]
pub fn run(alarm: Option<u32>, f: impl FnOnce() -> Vec<u8>) -> Option<Outcome> {
    use std::time::{Duration, Instant};
    let mut fds = [0 as libc::c_int; 2];
    if unsafe { libc::pipe(fds.as_mut_ptr()) } != 0 {
        return None;
    }
    let (rd, wr) = (fds[0], fds[1]);
    // Anything still buffered would be written twice, once by each process.
    use std::io::Write;
    let _ = std::io::stdout().flush();
    let _ = std::io::stderr().flush();
    let pid = unsafe { libc::fork() };
    if pid < 0 {
        unsafe { libc::close(rd) };
        unsafe { libc::close(wr) };
        return None;
    }
    if pid == 0 {
        unsafe { libc::close(rd) };
        // The child is single-threaded: only the forking thread survives, so
        // nothing here may wait on a lock another thread held. It runs the
        // simulation, writes the payload and leaves by `_exit` — no atexit
        // handler, no second flush of what the parent already wrote.
        let payload = std::panic::catch_unwind(std::panic::AssertUnwindSafe(f)).unwrap_or_default();
        let mut framed = (payload.len() as u64).to_le_bytes().to_vec();
        framed.extend_from_slice(&payload);
        write_all(wr, &framed);
        unsafe { libc::close(wr) };
        unsafe { libc::_exit(0) };
    }
    unsafe { libc::close(wr) };
    let deadline = alarm.map(|s| Instant::now() + Duration::from_secs(s as u64 + grace(s)));
    let mut stopped: Option<Outcome> = None;
    let mut buf = Vec::new();
    loop {
        let mut p = libc::pollfd { fd: rd, events: libc::POLLIN, revents: 0 };
        let n = unsafe { libc::poll(&mut p, 1, 200) };
        if n < 0 {
            if last_errno() == libc::EINTR {
                continue;
            }
            break;
        }
        if n > 0 {
            let mut chunk = [0u8; 1 << 16];
            let got = unsafe { libc::read(rd, chunk.as_mut_ptr().cast(), chunk.len()) };
            if got > 0 {
                buf.extend_from_slice(&chunk[..got as usize]);
                continue;
            }
            if got < 0 && last_errno() == libc::EINTR {
                continue;
            }
            break; // 0 = the child closed its end or died
        }
        // Idle: the two reasons to end a run the child cannot end itself.
        if stopped.is_none() {
            if metamodelica::cancel::check_cancel() {
                stopped = Some(Outcome::Cancelled);
            } else if deadline.is_some_and(|d| Instant::now() >= d) {
                stopped = Some(Outcome::TimedOut);
            }
            if stopped.is_some() {
                unsafe { libc::kill(pid, libc::SIGKILL) };
            }
        }
    }
    unsafe { libc::close(rd) };
    let mut status: libc::c_int = 0;
    while unsafe { libc::waitpid(pid, &mut status, 0) } < 0 && last_errno() == libc::EINTR {}
    if let Some(o) = stopped {
        return Some(o);
    }
    Some(match payload(&buf) {
        Some(p) => Outcome::Answered(p),
        None => Outcome::Died(died_reason(status)),
    })
}

#[cfg(not(all(unix, not(target_arch = "wasm32"))))]
pub fn run(_alarm: Option<u32>, _f: impl FnOnce() -> Vec<u8>) -> Option<Outcome> {
    None
}

/// The frame the child wrote, if it wrote all of it. A crash mid-write leaves a
/// short buffer, which is not an answer.
#[cfg(all(unix, not(target_arch = "wasm32")))]
fn payload(buf: &[u8]) -> Option<Vec<u8>> {
    let (len, rest) = buf.split_at_checked(8)?;
    let len = u64::from_le_bytes(len.try_into().ok()?) as usize;
    (rest.len() >= len).then(|| rest[..len].to_vec())
}

#[cfg(all(unix, not(target_arch = "wasm32")))]
fn died_reason(status: libc::c_int) -> String {
    if libc::WIFSIGNALED(status) {
        let sig = libc::WTERMSIG(status);
        let name = match sig {
            libc::SIGSEGV => " (segmentation fault)",
            libc::SIGBUS => " (bus error)",
            libc::SIGABRT => " (abort)",
            libc::SIGFPE => " (arithmetic exception)",
            libc::SIGILL => " (illegal instruction)",
            libc::SIGKILL => " (killed)",
            _ => "",
        };
        return format!("the simulation process died with signal {sig}{name}");
    }
    if libc::WIFEXITED(status) {
        return format!(
            "the simulation process exited with status {} before reporting a result",
            libc::WEXITSTATUS(status)
        );
    }
    "the simulation process ended without reporting a result".to_string()
}

#[cfg(all(unix, not(target_arch = "wasm32")))]
fn write_all(fd: libc::c_int, mut bytes: &[u8]) {
    while !bytes.is_empty() {
        let n = unsafe { libc::write(fd, bytes.as_ptr().cast(), bytes.len()) };
        if n > 0 {
            bytes = &bytes[n as usize..];
        } else if !(n < 0 && last_errno() == libc::EINTR) {
            return;
        }
    }
}

#[cfg(all(unix, not(target_arch = "wasm32")))]
fn last_errno() -> libc::c_int {
    std::io::Error::last_os_error().raw_os_error().unwrap_or(0)
}
