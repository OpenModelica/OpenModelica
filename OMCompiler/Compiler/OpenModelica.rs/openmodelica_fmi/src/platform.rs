//! `binaries/<platform>/` naming. FMI 1.0 and 2.0 standardise `linux64`,
//! `win64`, `darwin64` and their 32-bit forms; FMI 3.0 uses an architecture-OS
//! tuple. Both spellings exist in the wild for the same machine, so a host
//! matches either.

/// fmi-ls-wasm's platform directory.
pub const WASM_DIR: &str = "wasm32-wasip2";

pub struct Platform {
    /// FMI 3.0 tuple, e.g. `x86_64-linux`.
    pub fmi3: &'static str,
    /// FMI 1.0/2.0 directory, e.g. `linux64`.
    pub fmi2: &'static str,
    /// Shared-library extension, with the dot.
    pub ext: &'static str,
}

impl Platform {
    pub fn matches_dir(&self, dir: &str) -> bool {
        dir == self.fmi3 || dir == self.fmi2
    }
}

pub const PLATFORMS: &[Platform] = &[
    Platform { fmi3: "x86_64-linux", fmi2: "linux64", ext: ".so" },
    Platform { fmi3: "x86-linux", fmi2: "linux32", ext: ".so" },
    Platform { fmi3: "aarch64-linux", fmi2: "aarch64-linux", ext: ".so" },
    Platform { fmi3: "x86_64-windows", fmi2: "win64", ext: ".dll" },
    Platform { fmi3: "x86-windows", fmi2: "win32", ext: ".dll" },
    Platform { fmi3: "aarch64-windows", fmi2: "aarch64-windows", ext: ".dll" },
    Platform { fmi3: "x86_64-darwin", fmi2: "darwin64", ext: ".dylib" },
    Platform { fmi3: "aarch64-darwin", fmi2: "aarch64-darwin", ext: ".dylib" },
];

/// `None` when no FMU would carry a binary for this machine.
pub fn host_platform() -> Option<&'static Platform> {
    let want = match (std::env::consts::ARCH, std::env::consts::OS) {
        ("x86_64", "linux") => "x86_64-linux",
        ("x86", "linux") => "x86-linux",
        ("aarch64", "linux") => "aarch64-linux",
        ("x86_64", "windows") => "x86_64-windows",
        ("x86", "windows") => "x86-windows",
        ("aarch64", "windows") => "aarch64-windows",
        ("x86_64", "macos") => "x86_64-darwin",
        ("aarch64", "macos") => "aarch64-darwin",
        _ => return None,
    };
    PLATFORMS.iter().find(|p| p.fmi3 == want)
}

/// The library extension a `binaries/<dir>/` entry must have.
pub fn dir_suffix(dir: &str) -> &'static str {
    match PLATFORMS.iter().find(|p| p.matches_dir(dir)) {
        Some(p) => p.ext,
        // An unknown directory is still a platform some importer knows; go by
        // what its name says rather than rejecting the FMU.
        None if dir.contains("win") => ".dll",
        None if dir.contains("darwin") || dir.contains("apple") => ".dylib",
        None => ".so",
    }
}
