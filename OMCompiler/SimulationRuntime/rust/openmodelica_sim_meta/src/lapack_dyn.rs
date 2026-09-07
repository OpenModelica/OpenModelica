//! The LAPACK/BLAS routines Ipopt and MUMPS call, bound at first use so that
//! OpenBLAS (which sizes its thread pool when it loads) sees omc's `-n`.

use std::ffi::{c_char, c_int, c_void};
use std::sync::OnceLock;

macro_rules! routines {
    ($($name:ident: fn($($arg:ident: $ty:ty),*) $(-> $ret:ty)?;)*) => {
        struct Syms { $($name: unsafe extern "C" fn($($ty),*) $(-> $ret)?),* }

        fn resolve(libs: &[*mut c_void]) -> Syms {
            Syms { $($name: sym(libs, concat!(stringify!($name), "\0"))),* }
        }

        $(
            #[unsafe(no_mangle)]
            pub unsafe extern "C" fn $name($($arg: $ty),*) $(-> $ret)? {
                unsafe { (syms().$name)($($arg),*) }
            }
        )*
    };
}

// Fortran ABI; the trailing `usize`s are the hidden `character` lengths.
routines! {
    dasum_: fn(n: *const c_int, x: *const f64, incx: *const c_int) -> f64;
    dlamch_: fn(cmach: *const c_char, cmach_len: usize) -> f64;
    dlarfg_: fn(n: *const c_int, alpha: *mut f64, x: *mut f64, incx: *const c_int, tau: *mut f64);
    dnrm2_: fn(n: *const c_int, x: *const f64, incx: *const c_int) -> f64;
    dppsv_: fn(uplo: *const c_char, n: *const c_int, nrhs: *const c_int, ap: *mut f64, b: *mut f64,
               ldb: *const c_int, info: *mut c_int, uplo_len: usize);
    dswap_: fn(n: *const c_int, x: *mut f64, incx: *const c_int, y: *mut f64, incy: *const c_int);
    dsyev_: fn(jobz: *const c_char, uplo: *const c_char, n: *const c_int, a: *mut f64, lda: *const c_int,
               w: *mut f64, work: *mut f64, lwork: *const c_int, info: *mut c_int, jobz_len: usize,
               uplo_len: usize);
    dsymv_: fn(uplo: *const c_char, n: *const c_int, alpha: *const f64, a: *const f64, lda: *const c_int,
               x: *const f64, incx: *const c_int, beta: *const f64, y: *mut f64, incy: *const c_int,
               uplo_len: usize);
    dsyrk_: fn(uplo: *const c_char, trans: *const c_char, n: *const c_int, k: *const c_int,
               alpha: *const f64, a: *const f64, lda: *const c_int, beta: *const f64, c: *mut f64,
               ldc: *const c_int, uplo_len: usize, trans_len: usize);
    dtrtrs_: fn(uplo: *const c_char, trans: *const c_char, diag: *const c_char, n: *const c_int,
                nrhs: *const c_int, a: *const f64, lda: *const c_int, b: *mut f64, ldb: *const c_int,
                info: *mut c_int, uplo_len: usize, trans_len: usize, diag_len: usize);
    idamax_: fn(n: *const c_int, x: *const f64, incx: *const c_int) -> c_int;
    ilaenv_: fn(ispec: *const c_int, name: *const c_char, opts: *const c_char, n1: *const c_int,
                n2: *const c_int, n3: *const c_int, n4: *const c_int, name_len: usize, opts_len: usize)
                -> c_int;
}

#[cfg(target_os = "macos")]
const LIBS: [&str; 2] = ["liblapack.dylib\0", "libblas.dylib\0"];
#[cfg(not(target_os = "macos"))]
const LIBS: [&str; 2] = ["liblapack.so.3\0", "libblas.so.3\0"];

fn syms() -> &'static Syms {
    static SYMS: OnceLock<Syms> = OnceLock::new();
    SYMS.get_or_init(|| {
        let libs: Vec<*mut c_void> = LIBS
            .iter()
            .map(|name| {
                let h = unsafe { libc::dlopen(name.as_ptr().cast(), libc::RTLD_NOW | libc::RTLD_GLOBAL) };
                if h.is_null() {
                    let err = unsafe { std::ffi::CStr::from_ptr(libc::dlerror()) }.to_string_lossy().into_owned();
                    panic!("cannot load {}: {err}", name.trim_end_matches('\0'));
                }
                h
            })
            .collect();
        resolve(&libs)
    })
}

fn sym<F: Copy>(libs: &[*mut c_void], name: &str) -> F {
    assert_eq!(std::mem::size_of::<F>(), std::mem::size_of::<*mut c_void>());
    for &lib in libs {
        let p = unsafe { libc::dlsym(lib, name.as_ptr().cast()) };
        if !p.is_null() {
            return unsafe { std::mem::transmute_copy(&p) };
        }
    }
    panic!("{} is in neither LAPACK nor BLAS", name.trim_end_matches('\0'));
}
