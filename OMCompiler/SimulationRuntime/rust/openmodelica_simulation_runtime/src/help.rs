//! `-help`, `-?` and `-help=<flag>`, printed from libOpenModelicaRuntimeC's own
//! flag tables (`util/simulation_options.c`, `util/omc_error.c`) so the text is
//! the C runtime's.

use core::ffi::{CStr, c_char, c_int};

use openmodelica_sim_meta::omclog;

use crate::abi::*;

const FLAG_TYPE_FLAG: c_int = 1;

type Names<const N: usize> = [*const c_char; N];

unsafe extern "C" {
    static FLAG_NAME: Names<{ FLAG_MAX + 1 }>;
    static FLAG_DESC: Names<{ FLAG_MAX + 1 }>;
    static FLAG_DETAILED_DESC: Names<{ FLAG_MAX + 1 }>;
    static FLAG_TYPE: [c_int; FLAG_MAX];
    static IDA_LS_METHOD_NAME: Names<{ IDA_LS_MAX as usize }>;
    static IDA_LS_METHOD_DESC: Names<{ IDA_LS_MAX as usize }>;
    static INIT_METHOD_NAME: Names<{ IIM_MAX as usize }>;
    static INIT_METHOD_DESC: Names<{ IIM_MAX as usize }>;
    static JACOBIAN_METHOD_NAME: Names<{ JAC_MAX as usize }>;
    static JACOBIAN_METHOD_DESC: Names<{ JAC_MAX as usize }>;
    static LS_NAME: Names<{ LS_MAX as usize }>;
    static LS_DESC: Names<{ LS_MAX as usize }>;
    static LSS_NAME: Names<{ LSS_MAX as usize }>;
    static LSS_DESC: Names<{ LSS_MAX as usize }>;
    static OMC_LOG_STREAM_NAME: Names<{ OMC_SIM_LOG_MAX as usize }>;
    static OMC_LOG_STREAM_DESC: Names<{ OMC_SIM_LOG_MAX as usize }>;
    static NEWTONSTRATEGY_NAME: Names<{ NEWTON_MAX as usize }>;
    static NEWTONSTRATEGY_DESC: Names<{ NEWTON_MAX as usize }>;
    static NLS_NAME: Names<{ NLS_MAX as usize }>;
    static NLS_DESC: Names<{ NLS_MAX as usize }>;
    static NLS_LS_METHOD_NAME: Names<{ NLS_LS_MAX as usize }>;
    static NLS_LS_METHOD_DESC: Names<{ NLS_LS_MAX as usize }>;
    static SOLVER_METHOD_NAME: Names<{ S_MAX as usize }>;
    static SOLVER_METHOD_DESC: Names<{ S_MAX as usize }>;
    static firstOMCErrorStream: c_int;
}

fn s(p: *const c_char) -> String {
    if p.is_null() { String::new() } else { unsafe { CStr::from_ptr(p) }.to_string_lossy().into_owned() }
}

/// The exit code when `argv` asks for help (C's `helpFlagSet` / `FLAG_HELP`), after
/// printing it; `None` otherwise.
pub fn serve(argv: &[String]) -> Option<i32> {
    let program = argv.first().map_or("", String::as_str);
    let rest = argv.get(1..).unwrap_or_default();
    if rest.iter().any(|a| a == "-help" || a == "-?") {
        usage(program);
        return Some(1);
    }
    let option = rest.iter().rev().find_map(|a| a.strip_prefix("-help="))?;
    Some(detailed(program, option))
}

fn usage(program: &str) {
    omclog::info(omclog::STDOUT, true, &format!("usage: {program}"));
    for i in 1..FLAG_MAX {
        let (name, desc) = unsafe { (s(FLAG_NAME[i]), s(FLAG_DESC[i])) };
        let line = if unsafe { FLAG_TYPE[i] } == FLAG_TYPE_FLAG {
            format!("<-{name}>\n  {desc}")
        } else {
            format!("<-{name}=value> or <-{name} value>\n  {desc}")
        };
        omclog::info(omclog::STDOUT, false, &line);
    }
    omclog::close(omclog::STDOUT);
}

fn detailed(program: &str, option: &str) -> i32 {
    let Some(i) = (1..FLAG_MAX).find(|&i| unsafe { s(FLAG_NAME[i]) } == option) else {
        omclog::warning(omclog::STDOUT, false, &format!("invalid command line option: -help={option}"));
        omclog::warning(
            omclog::STDOUT,
            false,
            &format!("use {program} -help for a list of all command-line flags"),
        );
        return 1;
    };
    let desc = unsafe { s(FLAG_DETAILED_DESC[i]) };
    let head = if unsafe { FLAG_TYPE[i] } == FLAG_TYPE_FLAG {
        format!("detailed flag-description for: <-{option}>\n{desc}")
    } else {
        format!("detailed flag-description for: <-{option}=value> or <-{option} value>\n{desc}")
    };
    omclog::info(omclog::STDOUT, true, &head);
    let values: Option<(&[*const c_char], &[*const c_char], usize)> = unsafe {
        match option {
            "idaLS" => Some((&IDA_LS_METHOD_NAME, &IDA_LS_METHOD_DESC, 1)),
            "iim" => Some((&INIT_METHOD_NAME, &INIT_METHOD_DESC, 1)),
            "jacobian" => Some((&JACOBIAN_METHOD_NAME, &JACOBIAN_METHOD_DESC, 1)),
            "ls" => Some((&LS_NAME, &LS_DESC, 1)),
            "lss" => Some((&LSS_NAME, &LSS_DESC, 1)),
            "lv" => Some((&OMC_LOG_STREAM_NAME, &OMC_LOG_STREAM_DESC, firstOMCErrorStream as usize)),
            "newton" => Some((&NEWTONSTRATEGY_NAME, &NEWTONSTRATEGY_DESC, 1)),
            "nls" => Some((&NLS_NAME, &NLS_DESC, 1)),
            "nlsLS" => Some((&NLS_LS_METHOD_NAME, &NLS_LS_METHOD_DESC, 1)),
            "s" => Some((&SOLVER_METHOD_NAME, &SOLVER_METHOD_DESC, 1)),
            _ => None,
        }
    };
    if let Some((names, descs, first)) = values {
        for j in first..names.len() {
            let line = format!("{:<18} [{}]", s(names[j]), s(descs[j]));
            omclog::info(omclog::STDOUT, false, &line);
        }
    }
    omclog::close(omclog::STDOUT);
    0
}
