//! C's `%g` for the diagnostic text and HTML reports.

pub fn format_g(x: f64) -> String {
    // Rust has no direct `%g`; this matches the common cases (finite values use
    // the shortest round-tripping representation, which is close enough for the
    // diagnostic text). Non-finite values print like C.
    if x.is_nan() {
        "nan".to_string()
    } else if x.is_infinite() {
        if x < 0.0 { "-inf".to_string() } else { "inf".to_string() }
    } else {
        format!("{x}")
    }
}

/// C `%.*g` with `sig` significant digits: fixed notation when the decimal
/// exponent is in `[-4, sig)`, exponential (`e±NN`, two-digit exponent)
/// otherwise, with trailing zeros stripped in both forms. Used for the data
/// values (sig=15, i.e. `%.15g`) and tolerance text (sig=2) of the HTML report.
pub fn format_g_prec(x: f64, sig: usize) -> String {
    if !x.is_finite() {
        return format_g(x);
    }
    if x == 0.0 {
        return "0".to_string();
    }
    let sig = sig.max(1);
    let exp = x.abs().log10().floor() as i32;
    if exp < -4 || exp >= sig as i32 {
        // Exponential. Rust prints `8.00e-7`; C `%g` prints `8e-07`: strip the
        // mantissa's trailing zeros and pad the exponent to two digits.
        let s = format!("{:.*e}", sig - 1, x);
        let (mant, e) = s.split_once('e').unwrap();
        let mant = if mant.contains('.') {
            mant.trim_end_matches('0').trim_end_matches('.')
        } else {
            mant
        };
        let e: i32 = e.parse().unwrap_or(0);
        format!("{mant}e{}{:02}", if e < 0 { '-' } else { '+' }, e.abs())
    } else {
        let decimals = (sig as i32 - 1 - exp).max(0) as usize;
        let s = format!("{:.*}", decimals, x);
        if s.contains('.') {
            s.trim_end_matches('0').trim_end_matches('.').to_string()
        } else {
            s
        }
    }
}

/// `%.15g`, the format C uses for the numeric data/time values in the report.
pub fn format_g_prec15(x: f64) -> String {
    format_g_prec(x, 15)
}
