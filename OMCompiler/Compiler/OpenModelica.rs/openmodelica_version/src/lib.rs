//! Version numbers of Modelica libraries: semantic versions with any number
//! of numeric parts, where build metadata (`4.0.0+maint.om`) is a newer
//! build of the same version, and names such as `master` are branches.

use std::cmp::Ordering;
use std::fmt;

#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub enum Kind {
    /// `""` or `"default"`: any version.
    Any,
    Numbered {
        nums: Vec<u64>,
        pre: Vec<String>,
        build: Vec<String>,
    },
    Branch(String),
}

#[derive(Clone, Debug, PartialEq, Eq, Hash)]
pub struct Version {
    pub text: String,
    pub kind: Kind,
}

impl fmt::Display for Version {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.text)
    }
}

fn identifiers(s: &str) -> Option<Vec<String>> {
    let ids: Vec<String> = s.split('.').map(str::to_owned).collect();
    let valid = |id: &String| !id.is_empty() && id.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-');
    ids.iter().all(valid).then_some(ids)
}

fn parse_numbered(s: &str) -> Option<Kind> {
    let (rest, build) = match s.split_once('+') {
        Some((rest, build)) => (rest, identifiers(build)?),
        None => (s, Vec::new()),
    };
    let (numbers, pre) = match rest.split_once('-') {
        Some((numbers, pre)) => (numbers, identifiers(pre)?),
        None => (rest, Vec::new()),
    };
    let nums = numbers
        .split('.')
        .map(|n| {
            if !n.is_empty() && n.bytes().all(|b| b.is_ascii_digit()) {
                n.parse().ok()
            } else {
                None
            }
        })
        .collect::<Option<Vec<u64>>>()?;
    Some(Kind::Numbered { nums, pre, build })
}

impl Version {
    pub fn parse(s: &str) -> Version {
        let text = s.trim();
        let kind = match text {
            "" | "default" => Kind::Any,
            _ => parse_numbered(text)
                .or_else(|| parse_numbered(&text.replacen(' ', "-", 1)))
                .unwrap_or_else(|| Kind::Branch(text.to_owned())),
        };
        Version {
            text: text.to_owned(),
            kind,
        }
    }

    pub fn is_branch(&self) -> bool {
        matches!(self.kind, Kind::Branch(_))
    }

    pub fn is_prerelease(&self) -> bool {
        matches!(&self.kind, Kind::Numbered { pre, .. } if !pre.is_empty())
    }

    /// The branch a version names or is on: `master` for `master`,
    /// `1.2.0-master` and `0.0.0-master`.
    pub fn tag(&self) -> Option<String> {
        match &self.kind {
            Kind::Branch(name) => Some(name.clone()),
            Kind::Numbered { pre, .. } if !pre.is_empty() => Some(pre.join(".")),
            _ => None,
        }
    }

    /// A request for any version on a branch: `master` or `0.0.0-master`.
    pub fn branch_request(&self) -> Option<String> {
        match &self.kind {
            Kind::Branch(name) => Some(name.clone()),
            Kind::Numbered { nums, pre, .. } if !pre.is_empty() && nums.iter().all(|&n| n == 0) => Some(pre.join(".")),
            _ => None,
        }
    }

    /// Whether this version satisfies a request for `wanted`. A request
    /// without prerelease also matches its prereleases, unless it is exact;
    /// build metadata only counts for exact requests that have it.
    pub fn matches(&self, wanted: &Version, exact: bool) -> bool {
        if wanted.kind == Kind::Any {
            return true;
        }
        if let Some(name) = wanted.branch_request() {
            return self.tag().as_deref() == Some(name.as_str());
        }
        match (&self.kind, &wanted.kind) {
            (
                Kind::Numbered { nums, pre, build },
                Kind::Numbered {
                    nums: w_nums,
                    pre: w_pre,
                    build: w_build,
                },
            ) => {
                cmp_nums(nums, w_nums) == Ordering::Equal
                    && ((w_pre.is_empty() && !exact) || pre == w_pre)
                    && (!exact || w_build.is_empty() || build == w_build)
            }
            _ => false,
        }
    }

    /// Equal apart from build metadata.
    pub fn same(&self, other: &Version) -> bool {
        compare(self, other, false) == Ordering::Equal
    }

    /// The text with up to three numbers padded to three, `3.2` as `3.2.0`,
    /// as installed libraries are named.
    pub fn canonical(&self) -> String {
        match &self.kind {
            Kind::Numbered { nums, pre, build } if nums.len() <= 3 && !self.text.contains(' ') => {
                let mut out = (0..3)
                    .map(|i| nums.get(i).unwrap_or(&0).to_string())
                    .collect::<Vec<_>>()
                    .join(".");
                if !pre.is_empty() {
                    out = format!("{out}-{}", pre.join("."));
                }
                if !build.is_empty() {
                    out = format!("{out}+{}", build.join("."));
                }
                out
            }
            _ => self.text.clone(),
        }
    }
}

fn cmp_nums(a: &[u64], b: &[u64]) -> Ordering {
    (0..a.len().max(b.len()))
        .map(|i| a.get(i).unwrap_or(&0).cmp(b.get(i).unwrap_or(&0)))
        .find(|o| o.is_ne())
        .unwrap_or(Ordering::Equal)
}

fn cmp_identifier(a: &str, b: &str) -> Ordering {
    match (a.parse::<u64>(), b.parse::<u64>()) {
        (Ok(x), Ok(y)) => x.cmp(&y),
        (Ok(_), Err(_)) => Ordering::Less,
        (Err(_), Ok(_)) => Ordering::Greater,
        (Err(_), Err(_)) => a.cmp(b),
    }
}

fn cmp_identifiers(a: &[String], b: &[String]) -> Ordering {
    a.iter()
        .zip(b)
        .map(|(x, y)| cmp_identifier(x, y))
        .find(|o| o.is_ne())
        .unwrap_or_else(|| a.len().cmp(&b.len()))
}

/// [`Version::canonical`] of a text.
pub fn canonical(text: &str) -> String {
    Version::parse(text).canonical()
}

/// A total order: any < branches (by name) < numbered versions. A release is
/// newer than its prereleases (semver) and, with `compare_build`, older than
/// its builds.
pub fn compare(a: &Version, b: &Version, compare_build: bool) -> Ordering {
    compare_parts(a, b, true, compare_build)
}

/// [`compare`], ignoring prereleases unless `compare_pre`.
pub fn compare_parts(a: &Version, b: &Version, compare_pre: bool, compare_build: bool) -> Ordering {
    let rank = |k: &Kind| match k {
        Kind::Any => 0,
        Kind::Branch(_) => 1,
        Kind::Numbered { .. } => 2,
    };
    match (&a.kind, &b.kind) {
        (Kind::Branch(x), Kind::Branch(y)) => x.cmp(y),
        (
            Kind::Numbered { nums, pre, build },
            Kind::Numbered {
                nums: b_nums,
                pre: b_pre,
                build: b_build,
            },
        ) => cmp_nums(nums, b_nums)
            .then_with(
                || match (pre.is_empty() || !compare_pre, b_pre.is_empty() || !compare_pre) {
                    (true, true) => Ordering::Equal,
                    (true, false) => Ordering::Greater,
                    (false, true) => Ordering::Less,
                    (false, false) => cmp_identifiers(pre, b_pre),
                },
            )
            .then_with(|| {
                if compare_build {
                    cmp_identifiers(build, b_build)
                } else {
                    Ordering::Equal
                }
            }),
        (x, y) => rank(x).cmp(&rank(y)),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn v(s: &str) -> Version {
        Version::parse(s)
    }

    #[test]
    fn parse() {
        assert_eq!(v("").kind, Kind::Any);
        assert_eq!(v("default").kind, Kind::Any);
        assert_eq!(v("master").kind, Kind::Branch("master".into()));
        assert_eq!(v("1.1.0-maint/2.4.1").kind, Kind::Branch("1.1.0-maint/2.4.1".into()));
        assert_eq!(
            v("4.0.0-dev.1+maint.om").kind,
            Kind::Numbered {
                nums: vec![4, 0, 0],
                pre: vec!["dev".into(), "1".into()],
                build: vec!["maint".into(), "om".into()]
            }
        );
        assert_eq!(
            v("1.0.0.1").kind,
            Kind::Numbered {
                nums: vec![1, 0, 0, 1],
                pre: vec![],
                build: vec![]
            }
        );
        assert_eq!(v("1.1.0-Dev").tag().as_deref(), Some("Dev"));
        assert_eq!(
            v("3.4 beta1").kind,
            Kind::Numbered {
                nums: vec![3, 4],
                pre: vec!["beta1".into()],
                build: vec![]
            }
        );
    }

    #[test]
    fn order() {
        let sorted = [
            "",
            "master",
            "trunk",
            "3.2",
            "3.2.1",
            "4.0.0-alpha",
            "4.0.0-alpha.1",
            "4.0.0-beta.2",
            "4.0.0-beta.11",
            "4.0.0",
            "4.0.0+maint.om",
            "4.0.0.1",
        ];
        for w in sorted.windows(2) {
            assert_eq!(compare(&v(w[0]), &v(w[1]), true), Ordering::Less, "{} < {}", w[0], w[1]);
        }
        assert_eq!(compare(&v("3.2"), &v("3.2.0"), true), Ordering::Equal);
        assert_eq!(compare(&v("4.0.0"), &v("4.0.0+maint.om"), false), Ordering::Equal);
    }

    #[test]
    fn canonical() {
        for (text, canonical) in [
            ("3.2", "3.2.0"),
            ("4.0.0+maint.om", "4.0.0+maint.om"),
            ("1.0-beta.2", "1.0.0-beta.2"),
            ("01.2.3", "1.2.3"),
            ("1.0.0.1", "1.0.0.1"),
            ("3.4 beta1", "3.4 beta1"),
            ("master", "master"),
            ("", ""),
        ] {
            assert_eq!(v(text).canonical(), canonical, "{text}");
        }
    }

    #[test]
    fn without_prereleases() {
        assert_eq!(
            compare_parts(&v("4.0.0-beta"), &v("4.0.0"), false, false),
            Ordering::Equal
        );
        assert_eq!(
            compare_parts(&v("4.0.0-beta+b"), &v("4.0.0+a"), false, true),
            Ordering::Greater
        );
        assert_eq!(
            compare_parts(&v("4.0.0-beta"), &v("4.0.0"), true, false),
            Ordering::Less
        );
    }

    #[test]
    fn matching() {
        assert!(v("4.0.0+maint.om").matches(&v("4.0.0"), true));
        assert!(!v("4.0.0").matches(&v("4.0.0+maint.om"), true));
        assert!(v("4.0.0").matches(&v("4.0.0+maint.om"), false));
        assert!(v("4.2.0-dev").matches(&v("4.2.0"), false));
        assert!(!v("4.2.0").matches(&v("4.2.0-dev"), false));
        assert!(!v("4.2.0-dev").matches(&v("4.2.0"), true));
        assert!(v("3.2").matches(&v("3.2.0"), false));
        assert!(v("1.2.0-master").matches(&v("master"), false));
        assert!(v("master").matches(&v("0.0.0-master"), false));
        assert!(!v("master").matches(&v("4.0.0"), false));
        assert!(v("4.0.0").matches(&v(""), true));
    }
}
