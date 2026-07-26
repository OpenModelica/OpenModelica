//! Runtime simulation flags, parsed from an **argv-shaped** list.
//!
//! One parser for every entry point. A wasip1 standalone module is a WASI command:
//! its command line arrives through `args_sizes_get`/`args_get`, which
//! `std::env::args()` reads. The interactive runtime is instantiated once and
//! simulated many times, so its host hands the same argv over through
//! `rt_sim_set_args`, in the byte layout `args_get` itself writes (the strings
//! NUL-terminated back to back).
//!
//! Names and accepted values follow the C runtime's
//! (`SimulationRuntime/c/util/simulation_options.c`). Every selector is an
//! `Option`: `None` keeps the built-in default.

use alloc::format;
use alloc::string::{String, ToString};
use alloc::vec::Vec;

/// `-s`
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Solver {
    Dassl,
    Ida,
    Cvode,
    Gbode,
    Euler,
}

/// `-nls`
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Nls {
    Hybrid,
    Kinsol,
    Newton,
    Mixed,
    Homotopy,
}

/// `-nlsLS`, the linear solver inside the nonlinear one. `Rsparse` is wasm-jit's
/// own solver, not a C runtime value.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum NlsLs {
    Default,
    TotalPivot,
    Lapack,
    Klu,
    Rsparse,
}

/// `-ls`
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Ls {
    Default,
    Lapack,
    TotalPivot,
    Klu,
}

/// `-lss`. `Rsparse` is wasm-jit's own solver, not a C runtime value.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Lss {
    Default,
    Klu,
    Rsparse,
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct SimFlags {
    pub solver: Option<Solver>,
    pub nls: Option<Nls>,
    pub nls_ls: Option<NlsLs>,
    pub ls: Option<Ls>,
    pub lss: Option<Lss>,
    /// `-lv` streams, uppercased.
    pub log: Vec<String>,
    pub abort_slow: bool,
    /// `-override=name=value,…` unresolved: mapping a name to its `SimData` slot
    /// needs the model, which only the caller has.
    pub overrides: Vec<(String, f64)>,
    /// Flags this runtime does not model, kept so a caller can report them.
    pub unknown: Vec<String>,
    /// The argv this was parsed from, so a host forwards the same bytes rather than
    /// re-serializing a parsed form.
    pub argv: Vec<String>,
}

impl SimFlags {
    pub fn has_log(&self, stream: &str) -> bool {
        self.log.iter().any(|s| s == stream || s == "LOG_ALL")
    }

    /// Which of `-ls`, `-lss` and `-nlsLS` ask for KLU, with C's defaults: dense
    /// systems go to LAPACK, sparse ones to KLU. The unimplemented `-nlsLS` values
    /// (`totalpivot`, `lapack`) land on `rsparse`.
    pub fn klu_selectors(&self) -> (bool, bool, bool) {
        (
            self.ls == Some(Ls::Klu),
            self.lss != Some(Lss::Rsparse),
            !matches!(self.nls_ls, Some(NlsLs::Rsparse | NlsLs::TotalPivot | NlsLs::Lapack)),
        )
    }

    /// [`argv`](Self::argv) in the WASI `args_get` layout, for `rt_sim_set_args`.
    pub fn to_wasi_args(&self) -> Vec<u8> {
        let mut b = Vec::new();
        for a in &self.argv {
            b.extend_from_slice(a.as_bytes());
            b.push(0);
        }
        b
    }
}

/// What the runtime can serve, so [`check`] fails an unsupported request at startup
/// rather than running a different solver.
#[derive(Clone, Copy, Debug)]
pub struct Capabilities {
    pub klu: bool,
    pub ida: bool,
    pub cvode: bool,
    pub gbode: bool,
}

/// Reject flag values this runtime cannot honour.
pub fn check(f: &SimFlags, cap: Capabilities) -> Result<(), String> {
    if !cap.klu {
        for (flag, requested) in [
            ("lss", f.lss == Some(Lss::Klu)),
            ("ls", f.ls == Some(Ls::Klu)),
            ("nlsLS", f.nls_ls == Some(NlsLs::Klu)),
        ] {
            if requested {
                return Err(format!("-{flag}=klu: this runtime has no KLU linear solver"));
            }
        }
    }
    let unsupported = match f.solver {
        Some(Solver::Ida) if !cap.ida => "ida",
        Some(Solver::Cvode) if !cap.cvode => "cvode",
        Some(Solver::Gbode) if !cap.gbode => "gbode",
        _ => return Ok(()),
    };
    Err(format!(
        "-s={unsupported}: this runtime supports `dassl` and `euler` only"
    ))
}

/// Parse an argv slice (`argv[0]` is the program name and is skipped).
/// `-flag=value` and `-flag value` are both accepted, as in the C runtime.
/// An unrecognized *value* for a recognized flag is an error listing what is
/// accepted; an unrecognized *flag* is collected into [`SimFlags::unknown`].
pub fn parse<S: AsRef<str>>(argv: &[S]) -> Result<SimFlags, String> {
    let mut f = SimFlags {
        argv: argv.iter().map(|a| a.as_ref().to_string()).collect(),
        ..SimFlags::default()
    };
    let mut i = 1;
    while i < argv.len() {
        let arg = argv[i].as_ref();
        i += 1;
        let Some(body) = arg.strip_prefix('-') else { continue };
        let (name, inline) = match body.split_once('=') {
            Some((n, v)) => (n, Some(v)),
            None => (body, None),
        };
        // A value-taking flag may carry it inline or as the next argument.
        let mut value = |name: &str| -> Result<String, String> {
            if let Some(v) = inline {
                return Ok(v.to_string());
            }
            let v = argv.get(i).ok_or_else(|| format!("-{name} needs a value"))?;
            i += 1;
            Ok(v.as_ref().to_string())
        };
        match name {
            "s" | "solver" => f.solver = Some(solver(&value(name)?)?),
            "nls" => f.nls = Some(nls(&value(name)?)?),
            "nlsLS" => f.nls_ls = Some(nls_ls(&value(name)?)?),
            "ls" => f.ls = Some(ls(&value(name)?)?),
            "lss" => f.lss = Some(lss(&value(name)?)?),
            "lv" => {
                for s in value(name)?.split(',') {
                    let s = s.trim();
                    if !s.is_empty() {
                        f.log.push(s.to_uppercase());
                    }
                }
            }
            "override" => {
                for item in value(name)?.split(',') {
                    // An unparsable or unknown override is a no-op, as in C.
                    if let Some((n, v)) = item.split_once('=') {
                        if let Ok(val) = v.trim().parse::<f64>() {
                            f.overrides.push((n.trim().to_string(), val));
                        }
                    }
                }
            }
            "abortSlowSimulation" => f.abort_slow = true,
            _ => f.unknown.push(arg.to_string()),
        }
    }
    Ok(f)
}

fn bad(flag: &str, got: &str, accepted: &str) -> String {
    format!("unrecognized value `{got}` for -{flag} (accepted: {accepted})")
}

fn solver(v: &str) -> Result<Solver, String> {
    Ok(match v {
        "dassl" | "dasslrt" => Solver::Dassl,
        "ida" => Solver::Ida,
        "cvode" => Solver::Cvode,
        "gbode" => Solver::Gbode,
        "euler" => Solver::Euler,
        _ => return Err(bad("s", v, "dassl, ida, cvode, gbode, euler")),
    })
}

fn nls(v: &str) -> Result<Nls, String> {
    Ok(match v {
        "hybrid" => Nls::Hybrid,
        "kinsol" => Nls::Kinsol,
        "newton" => Nls::Newton,
        "mixed" => Nls::Mixed,
        "homotopy" => Nls::Homotopy,
        _ => return Err(bad("nls", v, "hybrid, kinsol, newton, mixed, homotopy")),
    })
}

fn nls_ls(v: &str) -> Result<NlsLs, String> {
    Ok(match v {
        "default" => NlsLs::Default,
        "totalpivot" => NlsLs::TotalPivot,
        "lapack" => NlsLs::Lapack,
        "klu" => NlsLs::Klu,
        "rsparse" => NlsLs::Rsparse,
        _ => return Err(bad("nlsLS", v, "default, totalpivot, lapack, klu, rsparse")),
    })
}

fn ls(v: &str) -> Result<Ls, String> {
    Ok(match v {
        "default" => Ls::Default,
        "lapack" => Ls::Lapack,
        "totalpivot" => Ls::TotalPivot,
        "klu" => Ls::Klu,
        _ => return Err(bad("ls", v, "default, lapack, totalpivot, klu")),
    })
}

fn lss(v: &str) -> Result<Lss, String> {
    Ok(match v {
        "default" => Lss::Default,
        "klu" => Lss::Klu,
        "rsparse" => Lss::Rsparse,
        _ => return Err(bad("lss", v, "default, klu, rsparse")),
    })
}

/// Set once per run before the driver starts; read from anywhere, since the NLS/LS
/// entry points take no flag arguments.
mod store {
    use super::SimFlags;

    #[cfg(feature = "std")]
    mod imp {
        use super::SimFlags;
        use core::cell::RefCell;
        std::thread_local! {
            static FLAGS: RefCell<SimFlags> = RefCell::new(SimFlags::default());
        }
        pub fn set(f: SimFlags) {
            FLAGS.with(|c| *c.borrow_mut() = f);
        }
        pub fn get() -> SimFlags {
            FLAGS.with(|c| c.borrow().clone())
        }
    }

    #[cfg(not(feature = "std"))]
    mod imp {
        use super::SimFlags;
        use core::cell::UnsafeCell;
        // Single-threaded in-wasm runtime, so a plain cell is sound (as in
        // `driver::overrides_store`).
        struct Store(UnsafeCell<Option<SimFlags>>);
        unsafe impl Sync for Store {}
        static STORE: Store = Store(UnsafeCell::new(None));
        pub fn set(f: SimFlags) {
            unsafe { *STORE.0.get() = Some(f) };
        }
        pub fn get() -> SimFlags {
            unsafe { (*STORE.0.get()).clone().unwrap_or_default() }
        }
    }

    pub use imp::{get, set};
}

pub fn set_flags(f: SimFlags) {
    store::set(f);
}

pub fn flags() -> SimFlags {
    store::get()
}

/// Split the WASI `args_get` byte layout — NUL-terminated strings back to back —
/// into an argv vector. A trailing unterminated tail is taken as a final argument
/// so a caller that forgot the last NUL loses nothing.
pub fn argv_from_bytes(bytes: &[u8]) -> Vec<String> {
    let mut out = Vec::new();
    for part in bytes.split(|&b| b == 0) {
        if !part.is_empty() {
            out.push(String::from_utf8_lossy(part).into_owned());
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn argv(s: &[&str]) -> Vec<String> {
        core::iter::once("model".to_string()).chain(s.iter().map(|x| x.to_string())).collect()
    }

    const NOTHING: Capabilities =
        Capabilities { klu: false, ida: false, cvode: false, gbode: false };

    #[test]
    fn defaults_are_all_unset() {
        let f = parse(&argv(&[])).expect("empty argv parses");
        assert_eq!(f.solver, None);
        assert_eq!((f.nls, f.nls_ls, f.ls, f.lss), (None, None, None, None));
        assert!(f.log.is_empty() && f.overrides.is_empty() && !f.abort_slow);
        assert!(check(&f, NOTHING).is_ok());
    }

    #[test]
    fn argv_survives_a_round_trip_through_the_wasi_layout() {
        let f = parse(&argv(&["-nls=newton", "-lv=LOG_STATS"])).expect("parses");
        let back = parse(&argv_from_bytes(&f.to_wasi_args())).expect("re-parses");
        assert_eq!(back, f);
    }

    #[test]
    fn unavailable_solvers_are_rejected_with_the_flag_named() {
        for (arg, needle) in [("-lss=klu", "KLU"), ("-ls=klu", "KLU"), ("-nlsLS=klu", "KLU"),
                              ("-s=ida", "dassl"), ("-s=cvode", "dassl")] {
            let f = parse(&argv(&[arg])).expect("parses");
            let e = check(&f, NOTHING).expect_err("must reject");
            assert!(e.contains(needle), "{arg}: {e}");
        }
        // With the capability present the same request is fine.
        let f = parse(&argv(&["-lss=klu"])).expect("parses");
        assert!(check(&f, Capabilities { klu: true, ..NOTHING }).is_ok());
    }

    #[test]
    fn selectable_solvers_need_no_capability() {
        for arg in ["-nls=kinsol", "-nls=hybrid", "-lss=rsparse", "-s=euler", "-s=dassl"] {
            let f = parse(&argv(&[arg])).expect("parses");
            assert!(check(&f, NOTHING).is_ok(), "{arg}");
        }
    }

    #[test]
    fn klu_serves_the_sparse_paths_by_default() {
        let f = parse(&argv(&[])).expect("parses");
        assert_eq!(f.klu_selectors(), (false, true, true));
        let f = parse(&argv(&["-ls=klu", "-lss=rsparse", "-nlsLS=rsparse"])).expect("parses");
        assert_eq!(f.klu_selectors(), (true, false, false));
        // The unimplemented C values land on rsparse too, not on KLU.
        let f = parse(&argv(&["-nlsLS=totalpivot"])).expect("parses");
        assert_eq!(f.klu_selectors().2, false);
    }

    #[test]
    fn inline_and_separate_values_agree() {
        let a = parse(&argv(&["-nls=kinsol", "-lss=klu"])).expect("inline");
        let b = parse(&argv(&["-nls", "kinsol", "-lss", "klu"])).expect("separate");
        // `argv` differs by construction; the parsed selectors must not.
        assert_eq!((a.nls, a.lss), (b.nls, b.lss));
        assert_eq!(a.nls, Some(Nls::Kinsol));
        assert_eq!(a.lss, Some(Lss::Klu));
    }

    #[test]
    fn program_name_is_not_a_flag() {
        // argv[0] is skipped even when it looks like one.
        let f = parse(&["-nls=kinsol", "-lss=klu"]).expect("parses");
        assert_eq!(f.nls, None);
        assert_eq!(f.lss, Some(Lss::Klu));
    }

    #[test]
    fn bad_value_is_an_error_listing_the_accepted_ones() {
        let e = parse(&argv(&["-nls=nope"])).expect_err("must reject");
        assert!(e.contains("nope") && e.contains("kinsol"), "{e}");
    }

    #[test]
    fn unknown_flags_are_collected_not_rejected() {
        let f = parse(&argv(&["-noEquidistantTimeGrid", "-lv=LOG_STATS"])).expect("parses");
        assert_eq!(f.unknown, ["-noEquidistantTimeGrid"]);
        assert!(f.has_log("LOG_STATS"));
    }

    #[test]
    fn log_all_implies_every_stream() {
        let f = parse(&argv(&["-lv=LOG_ALL"])).expect("parses");
        assert!(f.has_log("LOG_NLS_V"));
    }

    #[test]
    fn overrides_keep_order_and_skip_junk() {
        let f = parse(&argv(&["-override=a=1,bad,b=2.5,c=x"])).expect("parses");
        assert_eq!(f.overrides, [("a".to_string(), 1.0), ("b".to_string(), 2.5)]);
    }

    #[test]
    fn missing_value_is_an_error() {
        assert!(parse(&argv(&["-nls"])).is_err());
    }

    #[test]
    fn wasi_args_layout_round_trips() {
        let bytes = b"model\0-nls=kinsol\0-lv=LOG_STATS\0";
        let a = argv_from_bytes(bytes);
        assert_eq!(a, ["model", "-nls=kinsol", "-lv=LOG_STATS"]);
        assert_eq!(parse(&a).expect("parses").nls, Some(Nls::Kinsol));
        // A missing final NUL must not drop the last argument.
        assert_eq!(argv_from_bytes(b"model\0-nls=newton"), ["model", "-nls=newton"]);
    }
}
