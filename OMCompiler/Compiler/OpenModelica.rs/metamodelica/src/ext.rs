//! Hand-written replacements for `external "C"` runtime functions the
//! MetaModelica source declares as FFI shims (see
//! `mmtorust::external_c_calls::external_c_impl_path`).

#![allow(non_snake_case)]

/// C `atof`-style parse: the longest valid floating-point prefix (after
/// leading whitespace), `0.0` when there is none. Hand-written ports of
/// runtime C code use this where the original called `atof`/`strtod` on
/// machine-written text, so trailing junk must be tolerated rather than
/// turned into an error (`str::parse` would reject it).
pub fn c_atof(s: &str) -> f64 {
    let s = s.trim_start();
    let bytes = s.as_bytes();
    let mut end = 0;
    // optional sign
    if end < bytes.len() && (bytes[end] == b'+' || bytes[end] == b'-') {
        end += 1;
    }
    let mut seen_digit = false;
    while end < bytes.len() && bytes[end].is_ascii_digit() {
        end += 1;
        seen_digit = true;
    }
    if end < bytes.len() && bytes[end] == b'.' {
        end += 1;
        while end < bytes.len() && bytes[end].is_ascii_digit() {
            end += 1;
            seen_digit = true;
        }
    }
    if !seen_digit {
        return 0.0;
    }
    // optional exponent (only consumed when it has at least one digit)
    if end < bytes.len() && (bytes[end] == b'e' || bytes[end] == b'E') {
        let mut exp_end = end + 1;
        if exp_end < bytes.len() && (bytes[exp_end] == b'+' || bytes[exp_end] == b'-') {
            exp_end += 1;
        }
        let exp_digits_start = exp_end;
        while exp_end < bytes.len() && bytes[exp_end].is_ascii_digit() {
            exp_end += 1;
        }
        if exp_end > exp_digits_start {
            end = exp_end;
        }
    }
    s[..end].parse::<f64>().unwrap_or(0.0)
}

/// C `atoi`/`strtol(s, NULL, 10)`-style parse: the longest decimal-integer
/// prefix (after leading whitespace), `0` when there is none.
pub fn c_atol(s: &str) -> i64 {
    let s = s.trim_start();
    let bytes = s.as_bytes();
    let mut end = 0;
    if end < bytes.len() && (bytes[end] == b'+' || bytes[end] == b'-') {
        end += 1;
    }
    let digits_start = end;
    while end < bytes.len() && bytes[end].is_ascii_digit() {
        end += 1;
    }
    if end == digits_start {
        return 0;
    }
    s[..end].parse::<i64>().unwrap_or(0)
}
