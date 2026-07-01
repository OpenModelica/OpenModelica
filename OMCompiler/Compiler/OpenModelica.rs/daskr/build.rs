use std::path::PathBuf;

fn main() {
    println!("cargo:rerun-if-changed=build.rs");

    // Only build the reference C library when the `cref` feature is enabled
    // (used by the bit-exact cross-validation tests). The default build is
    // pure Rust with no C dependency.
    if std::env::var_os("CARGO_FEATURE_CREF").is_none() {
        return;
    }

    let manifest = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let base = manifest
        .join("../../OpenModelica/OMCompiler/3rdParty/Cdaskr/solver")
        .canonicalize()
        .expect("Cdaskr/solver directory not found (needed for the `cref` feature)");

    let mut b = cc::Build::new();
    b.include(&base)
        // Disable FP contraction (FMA) so the C reference matches Rust's
        // non-fused f64 arithmetic bit-for-bit.
        .flag_if_supported("-ffp-contract=off")
        .opt_level(2)
        .warnings(false)
        .file(base.join("dlinpk.c"))
        .file(base.join("daux.c"))
        .file(base.join("ddaskr.c"));
    for f in ["dlinpk.c", "daux.c", "ddaskr.c"] {
        println!("cargo:rerun-if-changed={}", base.join(f).display());
    }
    b.compile("cdaskr_ref");
}
