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

/// `-nls`. The discriminants are the wire codes [`SimFlags::solver_codes`] hands to
/// the wasm-jit runtime's `rt_set_solvers`, which mirrors them; 0 means unset, so
/// they start at 1 and must not be renumbered.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum Nls {
    Hybrid = 1,
    Kinsol = 2,
    Newton = 3,
    Mixed = 4,
    Homotopy = 5,
}

/// `-nlsLS`, the linear solver inside the nonlinear one. `Rsparse` is wasm-jit's
/// own solver, not a C runtime value.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum NlsLs {
    Default = 1,
    TotalPivot = 2,
    Lapack = 3,
    Klu = 4,
    Rsparse = 5,
}

/// `-ls`
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum Ls {
    Default = 1,
    Lapack = 2,
    TotalPivot = 3,
    Klu = 4,
}

/// `-lss`. `Rsparse` is wasm-jit's own solver, not a C runtime value.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum Lss {
    Default = 1,
    Klu = 2,
    Rsparse = 3,
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
    /// `-ils`: equidistant homotopy steps of the initial solve (C's
    /// `init_lambda_steps`, default 3).
    pub init_lambda_steps: Option<i32>,
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

    /// `(-nls, -nlsLS, -ls, -lss)` as the wire codes the wasm-jit runtime's
    /// `rt_set_solvers` takes (0 = unset). Which solver each code selects is the
    /// runtime's business — it matches on them — so no policy lives here.
    pub fn solver_codes(&self) -> (u32, u32, u32, u32) {
        let code = |v: Option<u32>| v.unwrap_or(0);
        (
            code(self.nls.map(|v| v as u32)),
            code(self.nls_ls.map(|v| v as u32)),
            code(self.ls.map(|v| v as u32)),
            code(self.lss.map(|v| v as u32)),
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
    let have: Vec<String> = supported(cap)
        .into_iter()
        .find(|(n, _)| *n == "s")
        .map(|(_, v)| v.iter().map(|n| alloc::format!("`{n}`")).collect())
        .unwrap_or_default();
    Err(format!("-s={unsupported}: this runtime supports {} only", have.join(", ")))
}

/// The values each solver flag accepts on this build, in menu order. A UI offering
/// only these never builds a command line [`check`] rejects. `default` is left out:
/// omitting a flag selects it.
pub fn supported(cap: Capabilities) -> Vec<(&'static str, Vec<&'static str>)> {
    let mut solver = alloc::vec!["dassl", "euler"];
    for (name, have) in [("ida", cap.ida), ("cvode", cap.cvode), ("gbode", cap.gbode)] {
        if have {
            solver.push(name);
        }
    }
    let mut nls_ls = alloc::vec!["totalpivot", "lapack", "rsparse"];
    let mut ls = alloc::vec!["lapack", "totalpivot"];
    let mut lss = alloc::vec!["rsparse"];
    if cap.klu {
        nls_ls.push("klu");
        ls.push("klu");
        lss.push("klu");
    }
    alloc::vec![
        ("s", solver),
        ("nls", alloc::vec!["hybrid", "kinsol", "newton", "mixed", "homotopy"]),
        ("nlsLS", nls_ls),
        ("ls", ls),
        ("lss", lss),
    ]
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
            "ils" => {
                f.init_lambda_steps =
                    Some(value(name)?.parse::<i32>().map_err(|_| "-ils needs an integer".to_string())?)
            }
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
        pub fn with<R>(g: impl FnOnce(&SimFlags) -> R) -> R {
            FLAGS.with(|c| g(&c.borrow()))
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
        pub fn with<R>(g: impl FnOnce(&SimFlags) -> R) -> R {
            match unsafe { &*STORE.0.get() } {
                Some(f) => g(f),
                None => g(&SimFlags::default()),
            }
        }
    }

    pub use imp::{get, set, with};
}

pub fn set_flags(f: SimFlags) {
    store::set(f);
}

pub fn flags() -> SimFlags {
    store::get()
}

/// Read the flags in place. [`flags`] clones, and `-override=` carries one `String`
/// per parameter — hundreds on a re-simulation from the web simulator's initial
/// conditions — so a solver hot path must read through this.
pub fn with_flags<R>(f: impl FnOnce(&SimFlags) -> R) -> R {
    store::with(f)
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
        // With the capability present the same request is fine, and the rejection
        // of another solver then offers it.
        let f = parse(&argv(&["-lss=klu"])).expect("parses");
        assert!(check(&f, Capabilities { klu: true, ..NOTHING }).is_ok());
        let f = parse(&argv(&["-s=ida"])).expect("parses");
        let e = check(&f, Capabilities { cvode: true, ..NOTHING }).expect_err("must reject");
        assert!(e.contains("`cvode`"), "{e}");
    }

    #[test]
    fn selectable_solvers_need_no_capability() {
        for arg in ["-nls=kinsol", "-nls=hybrid", "-lss=rsparse", "-s=euler", "-s=dassl"] {
            let f = parse(&argv(&[arg])).expect("parses");
            assert!(check(&f, NOTHING).is_ok(), "{arg}");
        }
    }

    // `supported` feeds the web UI's solver menus, so an offered value must survive
    // both the parser and the capability check of the build that offered it.
    #[test]
    fn everything_supported_parses_and_checks() {
        for cap in [NOTHING, Capabilities { klu: true, ida: true, cvode: true, gbode: true }] {
            for (flag, values) in supported(cap) {
                for v in values {
                    let f = parse(&argv(&[&format!("-{flag}={v}")])).expect(&format!("-{flag}={v}"));
                    assert!(check(&f, cap).is_ok(), "-{flag}={v}");
                }
            }
        }
        // KLU is offered only where it is linked, so it never shows up above.
        assert!(!supported(NOTHING).iter().any(|(_, v)| v.contains(&"klu")));
    }

    // The wire codes the wasm-jit runtime decodes: unset is 0, and the values are
    // fixed. Renumbering here without renumbering `solvers.rs` picks a wrong solver.
    #[test]
    fn solver_codes_are_stable() {
        assert_eq!(parse(&argv(&[])).expect("parses").solver_codes(), (0, 0, 0, 0));
        let f = parse(&argv(&["-nls=kinsol", "-nlsLS=totalpivot", "-ls=klu", "-lss=rsparse"]))
            .expect("parses");
        assert_eq!(f.solver_codes(), (2, 2, 4, 3));
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
