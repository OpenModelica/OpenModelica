//! `SemanticVersion.mo`: the version parsing and ordering of omc's package
//! manager, kept as it is because the order of listed versions depends on it.

use std::cmp::Ordering;

#[derive(Clone, Debug, PartialEq, Eq)]
pub(crate) enum LVersion {
    Semver {
        major: i64,
        minor: i64,
        patch: i64,
        prerelease: Vec<String>,
        meta: Vec<String>,
    },
    Nonsemver(String),
}

fn split_prerelease_and_meta(s: &str) -> (Vec<String>, Vec<String>) {
    let split = |s: &str| {
        if s.is_empty() {
            Vec::new()
        } else {
            s.split('.').map(str::to_owned).collect()
        }
    };
    if s.is_empty() {
        return (Vec::new(), Vec::new());
    }
    if let Some(meta) = s.strip_prefix('+') {
        return (Vec::new(), split(meta));
    }
    let (pre, meta) = s.split_once('+').unwrap_or((s, ""));
    (split(pre.strip_prefix('-').unwrap_or(pre)), split(meta))
}

/// `^([0-9][0-9]*\.?[0-9]*\.?[0-9]*)([+-][0-9A-Za-z.-]*)?$`
fn semver_parts(s: &str) -> Option<(&str, &str)> {
    let end = s.find(|c: char| c == '+' || c == '-').unwrap_or(s.len());
    let (numbers, rest) = s.split_at(end);
    let mut it = numbers.split('.');
    let first = it.next()?;
    if first.is_empty() || !first.bytes().all(|b| b.is_ascii_digit()) {
        return None;
    }
    let others: Vec<&str> = it.collect();
    if others.len() > 2 || !others.iter().all(|o| o.bytes().all(|b| b.is_ascii_digit())) {
        return None;
    }
    if !rest
        .bytes()
        .skip(1)
        .all(|b| b.is_ascii_alphanumeric() || b == b'.' || b == b'-')
    {
        return None;
    }
    Some((numbers, rest))
}

pub(crate) fn parse(s: &str, nonsemver_as_zero: bool) -> LVersion {
    let Some((numbers, rest)) = semver_parts(s) else {
        if s.is_empty() || !nonsemver_as_zero {
            return LVersion::Nonsemver(s.to_owned());
        }
        let (prerelease, meta) = split_prerelease_and_meta(s);
        return LVersion::Semver {
            major: 0,
            minor: 0,
            patch: 0,
            prerelease,
            meta,
        };
    };
    let mut nums = numbers.split('.').map(|n| n.parse::<i64>().unwrap_or(0));
    let (major, minor, patch) = (
        nums.next().unwrap_or(0),
        nums.next().unwrap_or(0),
        nums.next().unwrap_or(0),
    );
    let (prerelease, meta) = split_prerelease_and_meta(rest);
    LVersion::Semver {
        major,
        minor,
        patch,
        prerelease,
        meta,
    }
}

fn compare_identifier(a: &str, b: &str) -> i32 {
    let int = |s: &str| !s.is_empty() && s.bytes().all(|b| b.is_ascii_digit());
    if int(a) {
        return if int(b) {
            ordering(a.parse::<i64>().unwrap_or(0).cmp(&b.parse().unwrap_or(0)))
        } else {
            -1
        };
    }
    ordering(a.cmp(b))
}

fn compare_identifier_list(a: &[String], b: &[String]) -> i32 {
    for i in 0.. {
        match (a.get(i), b.get(i)) {
            (None, None) => return 0,
            (None, Some(_)) => return -1,
            (Some(_), None) => return 1,
            (Some(x), Some(y)) => {
                let c = compare_identifier(x, y);
                if c != 0 {
                    return c;
                }
            }
        }
    }
    0
}

fn ordering(o: Ordering) -> i32 {
    match o {
        Ordering::Less => -1,
        Ordering::Equal => 0,
        Ordering::Greater => 1,
    }
}

pub(crate) fn compare(a: &LVersion, b: &LVersion, compare_prerelease: bool, compare_build: bool) -> i32 {
    match (a, b) {
        (LVersion::Nonsemver(x), LVersion::Nonsemver(y)) => ordering(x.cmp(y)),
        (LVersion::Nonsemver(_), _) => -1,
        (_, LVersion::Nonsemver(_)) => 1,
        (
            LVersion::Semver {
                major,
                minor,
                patch,
                prerelease,
                meta,
            },
            LVersion::Semver {
                major: b_major,
                minor: b_minor,
                patch: b_patch,
                prerelease: b_pre,
                meta: b_meta,
            },
        ) => {
            let zero = |x: i64, y: i64, z: i64| x == 0 && y == 0 && z == 0;
            let mut c = 0;
            if !zero(*major, *minor, *patch) && !zero(*b_major, *b_minor, *b_patch) {
                c = ordering(major.cmp(b_major).then(minor.cmp(b_minor)).then(patch.cmp(b_patch)));
                if c != 0 {
                    return c;
                }
            }
            if compare_prerelease {
                c = compare_identifier_list(prerelease, b_pre);
            }
            if c == 0 && compare_build {
                c = compare_identifier_list(meta, b_meta);
            }
            c
        }
    }
}

pub(crate) fn to_string(v: &LVersion) -> String {
    match v {
        LVersion::Nonsemver(s) => s.clone(),
        LVersion::Semver {
            major,
            minor,
            patch,
            prerelease,
            meta,
        } => {
            let mut out = format!("{major}.{minor}.{patch}");
            if !prerelease.is_empty() {
                out = format!("{out}-{}", prerelease.join("."));
            }
            if !meta.is_empty() {
                out = format!("{out}+{}", meta.join("."));
            }
            out
        }
    }
}

/// `SemanticVersion.toString(SemanticVersion.parse(s))`.
pub(crate) fn normalize(s: &str) -> String {
    to_string(&parse(s, false))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn as_omc_did() {
        assert_eq!(normalize("3.2"), "3.2.0");
        assert_eq!(normalize("4.0.0+maint.om"), "4.0.0+maint.om");
        assert_eq!(normalize("master"), "master");
        assert_eq!(normalize("1.0.0.1"), "1.0.0.1");
        let p = |s: &str| parse(s, true);
        assert_eq!(compare(&p("master"), &p("4.0.0"), false, false), 0);
        assert_eq!(compare(&p("4.0.0"), &p("4.0.0-dev"), true, false), -1);
        assert_eq!(compare(&p("4.0.0"), &p("4.0.0+maint.om"), true, true), -1);
        assert_eq!(compare(&parse("", true), &parse("", true), true, false), 0);
        assert_eq!(compare(&parse("trunk", false), &parse("4.0.0", false), true, false), -1);
    }
}
