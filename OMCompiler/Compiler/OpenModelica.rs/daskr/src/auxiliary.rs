//! Port of `daux.c`: machine constants (`d1mach`), the simplified SLATEC error
//! handler (`xerrwd`/`xsetf`/`xsetun`/`ixsav`) and the few libf2c intrinsics the
//! solver relies on (`real_sign`, `real_pow`).

use std::sync::atomic::{AtomicI32, Ordering};

/// `d1mach`: the unit roundoff, computed in a machine-independent way exactly as
/// the C does (so it yields the same value, `f64::EPSILON`).
pub fn d1mach() -> f64 {
    let mut u = 1.0f64;
    loop {
        u *= 0.5;
        let comp = 1.0 + u;
        if comp == 1.0 {
            break;
        }
    }
    u * 2.0
}

/// Fortran `SIGN(a, b)`: magnitude of `a` with the sign of `b`.
#[inline]
pub fn real_sign(a: f64, b: f64) -> f64 {
    let x = if a >= 0.0 { a } else { -a };
    if b >= 0.0 { x } else { -x }
}

/// Fortran `a ** b` for reals.
#[inline]
pub fn real_pow(a: f64, b: f64) -> f64 {
    a.powf(b)
}

// --- error message control (IXSAV state) ------------------------------------

static LUNIT: AtomicI32 = AtomicI32::new(-1);
static LUNDEF: i32 = 6;
static MESFLG: AtomicI32 = AtomicI32::new(1);

/// `ixsav`: save/recall the message logical-unit (`ipar == 1`) or print flag
/// (`ipar == 2`). Returns the previous value.
pub fn ixsav(ipar: i32, ivalue: i32, iset: bool) -> i32 {
    match ipar {
        1 => {
            let mut cur = LUNIT.load(Ordering::Relaxed);
            if cur == -1 {
                cur = LUNDEF;
                LUNIT.store(cur, Ordering::Relaxed);
            }
            if iset {
                LUNIT.store(ivalue, Ordering::Relaxed);
            }
            cur
        }
        2 => {
            let cur = MESFLG.load(Ordering::Relaxed);
            if iset {
                MESFLG.store(ivalue, Ordering::Relaxed);
            }
            cur
        }
        _ => 0,
    }
}

/// `xsetf`: set the error-print control flag (1 = print, 0 = quiet).
pub fn xsetf(mflag: i32) {
    if mflag == 0 || mflag == 1 {
        ixsav(2, mflag, true);
    }
}

/// `xsetun`: set the logical unit number for error messages.
pub fn xsetun(lun: i32) {
    if lun > 0 {
        ixsav(1, lun, true);
    }
}

/// `xerrwd`: print an error message plus up to two integers and two reals, in
/// the same layout as the C/Fortran original. `level == 2` aborts the run.
///
/// `ni`/`nr` select how many of `i1,i2`/`r1,r2` are appended.
#[allow(clippy::too_many_arguments)]
pub fn xerrwd(msg: &str, _nerr: i32, level: i32, ni: i32, i1: i32, i2: i32, nr: i32, r1: f64, r2: f64) {
    let mesflg = ixsav(2, 0, false);
    if mesflg != 0 {
        let mut out = String::new();
        out.push_str(msg);
        out.push('\n');
        if ni == 1 {
            out.push_str(&format!("      In above message,  I1 = {}\n", i1));
        }
        if ni == 2 {
            out.push_str(&format!("      In above message,  I1 = {}   I2 = {}\n", i1, i2));
        }
        if nr == 1 {
            out.push_str(&format!("      In above message,  R1 = {}\n", fmt_e21_13(r1)));
        }
        if nr == 2 {
            out.push_str(&format!(
                "      In above,  R1 = {}   R2 = {}\n",
                fmt_e21_13(r1),
                fmt_e21_13(r2)
            ));
        }
        print!("{}", out);
    }
    if level == 2 {
        std::process::exit(0);
    }
}

/// Format like C's `%21.13E`: 13 fractional digits, uppercase `E`, a signed
/// exponent of at least two digits, right-justified to width 21.
fn fmt_e21_13(x: f64) -> String {
    // Rust's `{:.13E}` gives e.g. "1.2345678901234E5"; rebuild the C exponent.
    let s = format!("{:.13E}", x);
    let (mantissa, exp) = match s.split_once('E') {
        Some((m, e)) => (m.to_string(), e.parse::<i32>().unwrap_or(0)),
        None => (s, 0),
    };
    let sign = if exp < 0 { '-' } else { '+' };
    let body = format!("{}E{}{:02}", mantissa, sign, exp.abs());
    format!("{:>21}", body)
}
