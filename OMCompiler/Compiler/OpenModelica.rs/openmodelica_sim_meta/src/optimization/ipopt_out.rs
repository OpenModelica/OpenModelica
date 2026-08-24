//! Ipopt's own console output, into the run's log.
//!
//! Ipopt is C++ and writes its banner and its iteration table straight to `stdout`.
//! With the C target that is the simulation executable's stdout, which omc captures
//! whole; a wasm-jit run happens inside omc, so those bytes would bypass the log the
//! `messages` field is built from and land on the terminal instead.
//!
//! So `stdout` is redirected into a pipe for the duration of the solve and drained
//! into the log sink. The drain also runs at the top of every Ipopt callback, which
//! is what keeps the order the C target has: the banner (written before the first
//! callback) precedes the `LOG_IPOPT_ERROR` lines the callbacks emit.

use alloc::string::String;
use alloc::vec;

/// The redirected `stdout`, restored on drop.
pub(crate) struct Capture {
    /// Read end of the pipe.
    read: i32,
    /// `dup` of the original `stdout`.
    saved: i32,
}

unsafe extern "C" {
    fn pipe(fds: *mut i32) -> i32;
    fn dup(fd: i32) -> i32;
    fn dup2(old: i32, new: i32) -> i32;
    fn close(fd: i32) -> i32;
    fn read(fd: i32, buf: *mut u8, n: usize) -> isize;
    fn fflush(stream: *mut core::ffi::c_void) -> i32;
    fn fcntl(fd: i32, cmd: i32, ...) -> i32;
}

/// `F_SETFL` / `O_NONBLOCK` on Linux and macOS; the drain must never block on an
/// empty pipe.
const F_SETFL: i32 = 4;
const O_NONBLOCK: i32 = 0o4000;

impl Capture {
    /// Redirect `stdout`. `None` if the platform refuses, in which case Ipopt's
    /// output goes where it always did.
    pub(crate) fn begin() -> Option<Capture> {
        let mut fds = [0i32; 2];
        unsafe {
            if pipe(fds.as_mut_ptr()) != 0 {
                return None;
            }
            if fcntl(fds[0], F_SETFL, O_NONBLOCK) != 0 {
                close(fds[0]);
                close(fds[1]);
                return None;
            }
            let saved = dup(1);
            if saved < 0 || dup2(fds[1], 1) < 0 {
                close(fds[0]);
                close(fds[1]);
                return None;
            }
            close(fds[1]);
            Some(Capture { read: fds[0], saved })
        }
    }

    /// Move whatever Ipopt has written so far into the log.
    pub(crate) fn drain(&self) {
        // Ipopt's C++ streams buffer; flush before reading so a partial line is not
        // held back until the next drain.
        unsafe { fflush(core::ptr::null_mut()) };
        let mut buf = vec![0u8; 8192];
        let mut out = String::new();
        loop {
            let n = unsafe { read(self.read, buf.as_mut_ptr(), buf.len()) };
            if n <= 0 {
                break;
            }
            out.push_str(&String::from_utf8_lossy(&buf[..n as usize]));
            if (n as usize) < buf.len() {
                break;
            }
        }
        if !out.is_empty() {
            crate::driver::log_line(crate::omclog::STDOUT, crate::omclog::INFO, &out);
        }
    }
}

impl Drop for Capture {
    fn drop(&mut self) {
        self.drain();
        unsafe {
            dup2(self.saved, 1);
            close(self.saved);
            close(self.read);
        }
    }
}
