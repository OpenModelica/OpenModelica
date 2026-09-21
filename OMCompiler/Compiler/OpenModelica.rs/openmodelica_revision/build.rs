// Resolve the revision and hand it to the crate as OMC_REVISION: the file cmake
// wrote, else `git describe` here (raw cargo builds), else "unknown" like
// omc_config.h without revision.h.
//
// cmake passes a *path*, not the revision: an env var carrying the revision
// itself is part of every rustc invocation's environment and would miss the
// whole workspace's compilation cache on each commit.

use std::process::Command;

fn from_cmake() -> Option<String> {
    let path = std::env::var("OMC_REVISION_FILE").ok()?;
    println!("cargo:rerun-if-changed={path}");
    let rev = std::fs::read_to_string(&path).ok()?.trim().to_owned();
    (!rev.is_empty()).then_some(rev)
}

fn from_git(dir: &str) -> Option<String> {
    let git = |args: &[&str]| {
        Command::new("git")
            .args(args)
            .current_dir(dir)
            .output()
            .ok()
            .filter(|o| o.status.success())
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_owned())
            .filter(|s| !s.is_empty())
    };
    // logs/HEAD is rewritten by every commit, unlike HEAD itself.
    if let Some(gitdir) = git(&["rev-parse", "--absolute-git-dir"]) {
        println!("cargo:rerun-if-changed={gitdir}/logs/HEAD");
    }
    git(&["describe", "--match", "v*.*", "--always"])
}

fn main() {
    println!("cargo:rerun-if-env-changed=OMC_REVISION_FILE");
    let dir = std::env::var("CARGO_MANIFEST_DIR").expect("CARGO_MANIFEST_DIR set by cargo");
    let revision = from_cmake()
        .or_else(|| from_git(&dir))
        .unwrap_or_else(|| "unknown".to_owned());
    println!("cargo:rustc-env=OMC_REVISION={revision}");
}
