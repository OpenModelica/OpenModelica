//! Compares `src/abi.rs` against the C headers it mirrors.
//!
//! Builds a throw-away C program that prints `sizeof`/`offsetof` for every struct
//! and field the mirror declares, and the value of every `FLAG_*` it names, then
//! checks each against Rust's. A change to `simulation_data.h` that the mirror
//! has not followed fails here instead of corrupting the `DATA` the generated
//! `main` puts on its stack.
//!
//! Needs the runtime headers. `OMC_SIMRT_INCLUDE_DIRS` (set by the CMake build,
//! `|`-separated) names them; without it the test looks for them relative to the
//! source tree, and skips only if that fails too — a mirrored build copy run
//! outside CMake. Headers that are found but do not compile are a failure.

use std::path::{Path, PathBuf};
use std::process::Command;

use SimulationRuntimeRust::abi;

include!(concat!(env!("OUT_DIR"), "/abi_layout_checks.rs"));

fn include_dirs() -> Option<Vec<PathBuf>> {
    if let Ok(dirs) = std::env::var("OMC_SIMRT_INCLUDE_DIRS") {
        return Some(dirs.split('|').filter(|s| !s.is_empty()).map(PathBuf::from).collect());
    }
    // <repo>/OMCompiler/SimulationRuntime/rust/<crate> -> <repo>/OMCompiler/SimulationRuntime/c
    let manifest = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    let c = manifest.parent()?.parent()?.join("c");
    let gc = find_gc_h(&c)?;
    c.join("simulation_data.h").exists().then(|| vec![c, gc])
}

/// `gc/omc_gc.h` angle-includes Boehm's `gc.h`, which lives in 3rdParty.
fn find_gc_h(c_dir: &Path) -> Option<PathBuf> {
    let third = c_dir.parent()?.parent()?.join("3rdParty/gc");
    for sub in ["include", "gc-8.2.8/include", "gc/include"] {
        let p = third.join(sub);
        if p.join("gc.h").exists() {
            return Some(p);
        }
    }
    // A configured build tree has an installed copy; take the first one found.
    None
}

#[test]
fn abi_matches_the_c_headers() {
    let Some(includes) = include_dirs() else {
        eprintln!("skipping: no runtime headers (set OMC_SIMRT_INCLUDE_DIRS)");
        return;
    };
    let checks = checks();
    assert!(checks.len() > 300, "the generator found almost nothing to check ({})", checks.len());
    let mut c = String::from(
        "#include <stddef.h>\n#include <stdio.h>\n#include \"simulation_data.h\"\n\
         #include \"simulation/options.h\"\n\
         int main(void){\n",
    );
    for (expr, _) in &checks {
        c.push_str(&format!("  printf(\"%zu\\n\", (size_t)({expr}));\n"));
    }
    c.push_str("  return 0;\n}\n");

    let dir = std::env::temp_dir().join(format!("omc-abi-layout-{}", std::process::id()));
    std::fs::create_dir_all(&dir).expect("scratch dir");
    let src = dir.join("layout.c");
    let exe = dir.join("layout");
    std::fs::write(&src, &c).expect("write layout.c");

    let cc = std::env::var("CC").unwrap_or_else(|_| "cc".into());
    let mut cmd = Command::new(&cc);
    for inc in &includes {
        cmd.arg("-I").arg(inc);
    }
    cmd.arg(&src).arg("-o").arg(&exe);
    let out = cmd.output().expect("run the C compiler");
    assert!(
        out.status.success(),
        "the layout probe does not compile against {includes:?}:\n{}",
        String::from_utf8_lossy(&out.stderr)
    );
    let run = Command::new(&exe).output().expect("run the layout probe");
    let text = String::from_utf8_lossy(&run.stdout);
    let got: Vec<u64> = text.lines().map(|l| l.trim().parse().expect("a number")).collect();
    assert_eq!(got.len(), checks.len(), "the probe printed the wrong number of values");

    let mut bad = Vec::new();
    for ((expr, rust), c_val) in checks.iter().zip(&got) {
        if *rust != *c_val {
            bad.push(format!("  {expr}: C {c_val}, Rust {rust}"));
        }
    }
    let _ = std::fs::remove_dir_all(&dir);
    assert!(bad.is_empty(), "src/abi.rs no longer matches the C headers:\n{}", bad.join("\n"));
}

/// src/shim.c declares its own `FILE_INFO`; check it against the mirror.
#[test]
fn shim_file_info_matches_the_mirror() {
    unsafe extern "C" {
        fn omr_file_info_layout(out: *mut usize);
    }
    let mut shim = [0usize; 7];
    unsafe { omr_file_info_layout(shim.as_mut_ptr()) };
    assert_eq!(
        shim,
        [
            size_of::<abi::FILE_INFO>(),
            core::mem::offset_of!(abi::FILE_INFO, filename),
            core::mem::offset_of!(abi::FILE_INFO, lineStart),
            core::mem::offset_of!(abi::FILE_INFO, colStart),
            core::mem::offset_of!(abi::FILE_INFO, lineEnd),
            core::mem::offset_of!(abi::FILE_INFO, colEnd),
            core::mem::offset_of!(abi::FILE_INFO, readonly),
        ]
    );
}
