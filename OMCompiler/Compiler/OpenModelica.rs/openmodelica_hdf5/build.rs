//! Publishes the HDF5 install tree that `hdf5-metno-src` built.
//!
//! `DEP_HDF5SRC_ROOT` points into a cargo build directory whose path carries a
//! hash, so copy the tree to `OMC_HDF5_OUT` when CMake names a stable one.

use std::path::{Path, PathBuf};

fn main() {
    println!("cargo:rerun-if-env-changed=OMC_HDF5_OUT");
    let Some(src) = std::env::var_os("DEP_HDF5SRC_ROOT") else { return };
    let src = PathBuf::from(src);
    let root = match std::env::var_os("OMC_HDF5_OUT") {
        Some(out) => {
            let out = PathBuf::from(out);
            copy_tree(&src.join("include"), &out.join("include"));
            let lib = out.join("lib");
            std::fs::create_dir_all(&lib).expect("create lib dir");
            std::fs::copy(src.join("lib/libhdf5.a"), lib.join("libhdf5.a"))
                .expect("copy libhdf5.a");
            out
        }
        None => src,
    };
    println!("cargo:rustc-env=OMC_HDF5_ROOT={}", root.display());
}

fn copy_tree(from: &Path, to: &Path) {
    std::fs::create_dir_all(to).expect("create dir");
    for entry in std::fs::read_dir(from).expect("read dir").flatten() {
        let (path, dest) = (entry.path(), to.join(entry.file_name()));
        if path.is_dir() {
            copy_tree(&path, &dest);
        } else {
            std::fs::copy(&path, &dest).expect("copy file");
        }
    }
}
