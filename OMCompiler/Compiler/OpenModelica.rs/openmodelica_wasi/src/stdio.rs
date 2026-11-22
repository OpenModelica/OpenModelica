//! C's `stdout`/`stderr` FILEs. omc writes through these rather than Rust's
//! handles, like the C runtime: external C code prints into the same buffers,
//! and an embedder that `freopen`s them (OMEdit) only redirects C's streams.

use libc::FILE;

#[cfg(windows)]
unsafe extern "C" {
    fn __acrt_iob_func(index: u32) -> *mut FILE;
}
#[cfg(windows)]
unsafe fn stream(fd: u32) -> *mut FILE {
    unsafe { __acrt_iob_func(fd) }
}

// C code may assign these, hence `static mut`, read anew on every use.
#[cfg(any(target_vendor = "apple", target_os = "freebsd"))]
unsafe extern "C" {
    static mut __stdoutp: *mut FILE;
    static mut __stderrp: *mut FILE;
}
#[cfg(any(target_vendor = "apple", target_os = "freebsd"))]
unsafe fn stream(fd: u32) -> *mut FILE {
    unsafe { if fd == 1 { __stdoutp } else { __stderrp } }
}

#[cfg(not(any(windows, target_vendor = "apple", target_os = "freebsd")))]
unsafe extern "C" {
    static mut stdout: *mut FILE;
    static mut stderr: *mut FILE;
}
#[cfg(not(any(windows, target_vendor = "apple", target_os = "freebsd")))]
unsafe fn stream(fd: u32) -> *mut FILE {
    unsafe { if fd == 1 { stdout } else { stderr } }
}

/// `fwrite` to C's `stdout` (`fd` 1) or `stderr` (2); false if it fell short.
pub fn write(fd: u32, bytes: &[u8]) -> bool {
    bytes.is_empty() || unsafe { libc::fwrite(bytes.as_ptr().cast(), 1, bytes.len(), stream(fd)) } == bytes.len()
}

/// The OS handle C's `stdout` (`fd` 1) or `stderr` (2) writes to; `None` when
/// the stream has none, as in a GUI application without a console.
#[cfg(windows)]
pub fn os_handle(fd: u32) -> Option<std::os::windows::io::RawHandle> {
    let n = unsafe { libc::fileno(stream(fd)) };
    let h = if n < 0 { -1 } else { unsafe { libc::get_osfhandle(n) } };
    (h != -1 && h != -2).then_some(h as std::os::windows::io::RawHandle)
}

/// `fflush(NULL)`.
pub fn flush() {
    unsafe { libc::fflush(std::ptr::null_mut()) };
}

/// Flush C's `stdout` and `stderr` only.
pub fn flush_std() {
    unsafe {
        libc::fflush(stream(1));
        libc::fflush(stream(2));
    }
}
