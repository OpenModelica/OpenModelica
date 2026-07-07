//! `realString` / `ryu_hr_tdzp` and the `ryu_to_hr` shortest-form
//! decimal formatter (port of `3rdParty/ryu/ryu/om_format.c`).

use arcstr::ArcStr;
use crate::Real;

/// Converts Real to String.
///
/// Mirrors the C runtime's `realString` (`SimulationRuntime/c/meta/realString.c`):
/// the shortest round-trip representation (ryu's `d2s`; Rust's `{:e}` is the
/// same shortest form) post-processed by `ryu_to_hr` with `real_output=true`,
/// so round values keep a trailing `.0` (`3.0` → `"3.0"`, never `"3"`).
pub fn realString(r: Real) -> ArcStr {
    let v = r.0;
    if v.is_infinite() {
        return if v < 0.0 { arcstr::literal!("-inf") } else { arcstr::literal!("inf") };
    }
    if v.is_nan() {
        return arcstr::literal!("NaN");
    }
    ArcStr::from(ryu_to_hr(&std::format!("{:e}", v), true))
}

/// Port of the C runtime's `ryu_hr_tdzp` (`3rdParty/ryu/ryu/om_format.c`): the
/// shortest round-trip representation in OMEdit's display variant (`ryu_to_hr`
/// with `real_output=false`). Used by OMEdit's `StringHandler::number` to format
/// numbers for display, exposed to it through the embedding cdylib.
pub fn ryu_hr_tdzp(d: f64) -> String {
    if d.is_infinite() {
        return if d < 0.0 { "-inf".to_owned() } else { "inf".to_owned() };
    }
    if d.is_nan() {
        return "NaN".to_owned();
    }
    ryu_to_hr(&std::format!("{:e}", d), false)
}

/// Port of `ryu_to_hr` from `3rdParty/ryu/ryu/om_format.c`: convert a
/// shortest-form scientific representation (`8.13e2`) to the minimal
/// decimal or exponential rendering omc uses everywhere it prints Reals.
///
/// * Exponents in `[-3, 5]` (and at most 3 trailing zeros before the
///   decimal point) print in decimal form, everything else stays
///   exponential (with a lowercase `e`).
/// * With `real_output`, round decimal values get a trailing `.0`.
/// * Without `real_output`, a mantissa with more than 12 decimals is
///   rounded to 12 when that removes at least 4 trailing zeros (the
///   OMEdit-style display variant, `ryu_hr_tdzp`).
fn ryu_to_hr(d2s_str: &str, real_output: bool) -> String {
    let Some(epos) = d2s_str.find(['e', 'E']) else {
        // Not in mantissa-exponent form (e.g. "NaN"); pass through.
        return d2s_str.replace('E', "e");
    };
    let mant_str = &d2s_str[..epos];
    let mut exp: i32 = d2s_str[epos + 1..].parse().unwrap_or(0);
    let (neg, mut digits) = match mant_str.strip_prefix('-') {
        Some(m) => (true, m.to_string()),
        None => (false, mant_str.to_string()),
    };
    // Number of digits after the decimal point in the mantissa.
    let mut ndec: i32 = if digits.contains('.') { digits.len() as i32 - 2 } else { 0 };
    // The exponential rendering used when the decimal form is unsuitable.
    let mut exp_repr: String = d2s_str.replace('E', "e");

    if ndec > 12 && !real_output {
        // Round the mantissa to 12 decimals; use it only if that removed at
        // least 4 trailing zeros (i.e. the long tail was an artifact).
        let mant: f64 = digits.parse().unwrap_or(0.0);
        let mut rounded = std::format!("{mant:.12}");
        // 9.999999999999999 rounds to 10.000000000000: renormalise.
        if rounded == "10.000000000000" {
            rounded = "1.000000000000".to_string();
            exp += 1;
        }
        let mut nz = 0;
        while rounded.ends_with('0') {
            rounded.pop();
            nz += 1;
        }
        if rounded.ends_with('.') {
            rounded.pop();
        }
        if nz > 3 {
            digits = rounded;
            ndec = if digits.contains('.') { digits.len() as i32 - 2 } else { 0 };
            exp_repr = std::format!("{}{digits}e{exp}", if neg { "-" } else { "" });
        }
    }

    if !(-3..=5).contains(&exp) || (exp > 0 && exp - ndec > 3) {
        return exp_repr;
    }

    // Decimal form. `digs` is the mantissa without its decimal point:
    // one leading digit followed by `ndec` decimals.
    let digs: Vec<char> = digits.chars().filter(|c| *c != '.').collect();
    let mut out = String::with_capacity(24);
    if neg {
        out.push('-');
    }
    if exp == 0 {
        out.push_str(&digits);
    } else if exp > 0 {
        // Move the decimal point `exp` places to the right.
        out.push(digs[0]);
        let take = ndec.min(exp) as usize;
        out.extend(&digs[1..1 + take]);
        if exp > ndec {
            for _ in 0..(exp - ndec) {
                out.push('0');
            }
        } else if exp < ndec {
            out.push('.');
            out.extend(&digs[1 + take..]);
        }
    } else {
        // exp < 0: the number starts with "0." and some zeros.
        out.push_str("0.");
        for _ in 0..(-exp - 1) {
            out.push('0');
        }
        out.extend(&digs);
    }
    if exp >= ndec && real_output {
        out.push_str(".0");
    }
    out
}

#[cfg(test)]
#[allow(unused_imports)]
mod tests {
    use super::*;
    use crate::*;
    use std::sync::Arc;
    use std::rc::Rc;
    use arcstr::{literal, ArcStr};
    mod real_conversion_tests {
    use super::*;
    fn r(x: f64) -> Real { OrderedFloat(x) }

        #[test]
        fn test_real_string() {
            assert_eq!(&*realString(r(3.14)), "3.14");
            assert_eq!(&*realString(r(0.0)), "0.0");
            assert_eq!(&*realString(r(-1.5)), "-1.5");
            assert_eq!(&*realString(r(3.0)), "3.0");
            assert_eq!(&*realString(r(f64::INFINITY)), "inf");
            assert_eq!(&*realString(r(f64::NEG_INFINITY)), "-inf");
            assert_eq!(&*realString(r(f64::NAN)), "NaN");
        }

        /// The `real_output=1` vectors from om_format.c's TEST_RYU_TO_HR main.
        #[test]
        fn test_ryu_to_hr_real() {
            for (input, expected) in [
                ("8e5", "8e5"),
                ("8e4", "8e4"),
                ("8e3", "8000.0"),
                ("8e2", "800.0"),
                ("8e1", "80.0"),
                ("8e0", "8.0"),
                ("8e-1", "0.8"),
                ("8e-2", "0.08"),
                ("8e-3", "0.008"),
                ("8e-4", "8e-4"),
                ("8e-5", "8e-5"),
                ("8.13e6", "8.13e6"),
                ("8.13e5", "813000.0"),
                ("8.13e4", "81300.0"),
                ("8.13e3", "8130.0"),
                ("8.13e2", "813.0"),
                ("8.13e1", "81.3"),
                ("8.13e0", "8.13"),
                ("8.13e-1", "0.813"),
                ("8.13e-2", "0.0813"),
                ("8.13e-3", "0.00813"),
                ("8.13e-4", "8.13e-4"),
                ("8.13e-5", "8.13e-5"),
                ("8.1234567e6", "8.1234567e6"),
                ("8.1234567e5", "812345.67"),
                ("8.1234567e4", "81234.567"),
                ("8.1234567e0", "8.1234567"),
                ("8.1234567e-3", "0.0081234567"),
                ("8.1234567e-4", "8.1234567e-4"),
                ("-1.2e1", "-12.0"),
                ("-4.56e8", "-4.56e8"),
                ("1e-60", "1e-60"),
                ("1e80", "1e80"),
                ("NaN", "NaN"),
                ("Inf", "Inf"),
                ("-Inf", "-Inf"),
                ("9.499999999999999e2", "949.9999999999999"),
                ("1.000000000000002e0", "1.000000000000002"),
                ("-9.499999999999999e2", "-949.9999999999999"),
            ] {
                assert_eq!(ryu_to_hr(input, true), expected, "ryu_to_hr({input:?}, true)");
            }
        }

        /// The `real_output=0` vectors from om_format.c's TEST_RYU_TO_HR main.
        #[test]
        fn test_ryu_to_hr_plain() {
            for (input, expected) in [
                ("8e3", "8000"),
                ("8e0", "8"),
                ("8e-3", "0.008"),
                ("8e-4", "8e-4"),
                ("8.13e2", "813"),
                ("8.13e1", "81.3"),
                ("-1.2e1", "-12"),
                ("9.499999999999999e2", "950"),
                ("1.9999999999999998e8", "2e8"),
                ("1.9999999999999998e-6", "2e-6"),
                ("-9.499999999999999e2", "-950"),
                ("1.000000000000002e0", "1"),
                ("1.0000000000000022e0", "1"),
                ("9.99999999999999e-13", "1e-12"),
                ("9.99999999999999e-5", "1e-4"),
                ("9.99999999999999e-2", "0.1"),
                ("9.99999999999999e-1", "1"),
                ("9.99999999999999e0", "10"),
                ("9.99999999999999e1", "100"),
                ("9.99999999999999e5", "1e6"),
                ("9.99999999999999e11", "1e12"),
                ("-9.99999999999999e1", "-100"),
                ("1.234567890123456e6", "1.234567890123456e6"),
                ("1.2e6", "1.2e6"),
                ("1e6", "1e6"),
            ] {
                assert_eq!(ryu_to_hr(input, false), expected, "ryu_to_hr({input:?}, false)");
            }
        }
    }
}
