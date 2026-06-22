// Manually written file.
//
// Rust port of `OMCompiler/Compiler/Util/System.mo`'s `external "C"`
// declarations into `OMCompiler/Compiler/runtime/systemimpl.c`.
//
// `System` is the umbrella interface for non-MetaModelica runtime
// services: string utilities, file/directory ops, process spawning,
// per-thread compiler-state flags, timers, randomness, platform info,
// plus a handful of opaque-pointer external objects (dlopen handles,
// StringAllocator). Everything is `external "C"` in the .mo source, so
// the auto-generated bodies were a wall of `todo!()`; we replace them
// with proper Rust where the standard library suffices and leave
// well-documented `todo!("...")` stubs for the few that genuinely need
// LAPACK/dlopen/regex/etc. wiring.
//
// State that the C runtime keeps in `threadData` (compiler-config
// strings, "uses cardinality" booleans, tmpTick counters, realtime
// stopwatches, …) lives in this file as `thread_local!` `RefCell`s.

#![allow(non_snake_case)]

use std::cell::RefCell;
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use std::sync::Arc;
// std::time::*::now() panics on wasm32-unknown-unknown (no clock); web-time
// provides the same API backed by the JS clock there. `Duration` is clock-free,
// so it stays from std on both.
#[cfg(not(target_arch = "wasm32"))]
use std::time::{Instant, SystemTime, UNIX_EPOCH};
#[cfg(target_arch = "wasm32")]
use web_time::{Instant, SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result, bail};
use arcstr::{ArcStr, literal};

use metamodelica::List;

use crate::Autoconf;

// ───────────────────────────────── thread-local state ─────────────────────────

#[derive(Default)]
struct SysState {
    // Compiler / linker config strings. The C runtime initialises these from
    // build-time defines (CC, CFLAGS, …); we accept "" as the unset sentinel
    // until a caller sets them, mirroring `init` in `systemimpl.c` which
    // strdup's the autoconf defaults at startup.
    cc: String,
    cflags: String,
    cxx: String,
    linker: String,
    ldflags: String,

    // Per-thread cardinality / connector flags consulted by the front end.
    has_expandable: bool,
    has_overconstrained: bool,
    partial_instantiation: bool,
    has_stream: bool,
    uses_cardinality: bool,
    has_inner_outer: bool,

    // tmpTick / tmpTickIndex counters. Index 0 is the unindexed `tmpTick`.
    // The C runtime keeps an array `tmp_tick_no[NUM_TICKS]`; we lazily grow
    // a Vec so callers don't have to declare the maximum index up-front.
    ticks: Vec<i32>,
    tick_max: Vec<i32>,

    // realtime stopwatches keyed by clockIndex. Each slot remembers either
    // a running start (`Instant`) or the accumulated duration since the last
    // `realtimeAccumulate`. `ntick` counts the number of completed tick/tock
    // pairs — used by profiler reports.
    rt: HashMap<i32, RtSlot>,

    // Free-running timer with a stack (start/stop/reset). Mirrors the
    // `rt_timer_t` global the C runtime uses for `getTimerElapsedTime`.
    timer_running: Option<Instant>,
    timer_accum: f64,
    timer_last_interval: f64,
    timer_stack: i32,

    // Misc settings.
    classnames_for_simulation: String,

    // Internal RNG state for realRand/intRand. Linear-congruential, matches
    // the C runtime's `rand()` semantics (process-thread-local).
    rng: u64,
}

#[derive(Clone, Copy)]
enum RtSlot {
    Running { start: Instant, accumulated_ns: u128, ntick: i32 },
    Stopped { accumulated_ns: u128, ntick: i32 },
}

thread_local! {
    static STATE: RefCell<SysState> = RefCell::new(SysState {
        // Seed the LCG from system time so test runs are non-deterministic
        // unless the caller explicitly resets it. The exact constants don't
        // matter — see intRand below.
        rng: SystemTime::now().duration_since(UNIX_EPOCH)
            .map(|d| d.as_nanos() as u64)
            .unwrap_or(1) | 1,
        ..SysState::default()
    });
}

fn with<R>(f: impl FnOnce(&mut SysState) -> R) -> R {
    STATE.with(|s| f(&mut s.borrow_mut()))
}

/// Build a `List` (MetaModelica cons-list) from a `Vec`, preserving order
/// — the rightmost element ends up at the tail. Mirrors `list![..]` for
/// the dynamic case.
fn list_from_vec<T: Clone>(xs: Vec<T>) -> Arc<List<T>> {
    let mut acc = metamodelica::nil::<T>();
    for x in xs.into_iter().rev() {
        acc = metamodelica::cons(x, acc);
    }
    acc
}

// ───────────────────────────────── string operations ──────────────────────────

pub fn trim(inString: ArcStr, charsToRemove: ArcStr) -> ArcStr {
    let chars: Vec<char> = charsToRemove.chars().collect();
    let trimmed: &str = inString.trim_matches(|c: char| chars.contains(&c));
    ArcStr::from(trimmed)
}

pub fn trimWhitespace(inString: ArcStr) -> ArcStr {
    ArcStr::from(inString.trim())
}

pub fn trimChar(inString1: ArcStr, inString2: ArcStr) -> Result<ArcStr> {
    if inString2.chars().count() != 1 {
        bail!("System.trimChar: second argument must be exactly one character");
    }
    let c = inString2.chars().next().unwrap();
    Ok(ArcStr::from(inString1.trim_matches(c)))
}

pub fn strcmp(inString1: ArcStr, inString2: ArcStr) -> i32 {
    use std::cmp::Ordering::*;
    match inString1.as_str().cmp(inString2.as_str()) {
        Less => -1,
        Equal => 0,
        Greater => 1,
    }
}

pub fn strcmp_offset(string1: ArcStr, offset1: i32, length1: i32, string2: ArcStr, offset2: i32, length2: i32) -> i32 {
    let s1 = string1.as_bytes();
    let s2 = string2.as_bytes();
    let lo1 = (offset1 - 1).max(0) as usize;
    let lo2 = (offset2 - 1).max(0) as usize;
    let hi1 = (lo1 + length1.max(0) as usize).min(s1.len());
    let hi2 = (lo2 + length2.max(0) as usize).min(s2.len());
    use std::cmp::Ordering::*;
    match s1[lo1..hi1].cmp(&s2[lo2..hi2]) {
        Less => -1,
        Equal => 0,
        Greater => 1,
    }
}

pub fn stringFind(r#str: ArcStr, searchStr: ArcStr) -> Result<i32> {
    Ok(r#str.find(searchStr.as_str()).map(|i| i as i32).unwrap_or(-1))
}

pub fn stringFindString(r#str: ArcStr, searchStr: ArcStr) -> ArcStr {
    match r#str.find(searchStr.as_str()) {
        Some(i) => ArcStr::from(&r#str[i..]),
        None => literal!(""),
    }
}

/// POSIX `regex(3)` wrapper, a faithful port of `OpenModelica_regexImpl`
/// (SimulationRuntime/c/util/utility.c): it FFIs straight to the same
/// `regcomp`/`regexec` the C runtime uses, so BRE/ERE syntax and POSIX
/// leftmost-longest matching behave identically (rather than reimplementing a
/// regex engine).
///
/// Returns `(nmatch, matches)` where `matches` always has `maxMatches` elements:
/// the captured substrings (full match at index 0, then each participating
/// group, packed — non-participating groups are skipped) followed by empty
/// strings. `maxMatches == 0` means "match test only" (`REG_NOSUB`): the list
/// is empty and `nmatch` is 1 on match, 0 otherwise. On a compile error
/// `nmatch` is 0 and (for `maxMatches > 0`) the error message is the first
/// element.
#[cfg(target_arch = "wasm32")]
pub fn regex(
    str: ArcStr,
    re: ArcStr,
    maxMatches: i32,
    extended: bool,
    ignoreCase: bool,
) -> (i32, Arc<List<ArcStr>>) {
    // POSIX regcomp/regexec are libc-only; on wasm we run the `regex` crate
    // instead. POSIX ERE maps almost directly onto its syntax; POSIX BRE has the
    // grouping/quantifier metacharacter conventions reversed, so translate first.
    use regex::RegexBuilder;

    fn list_forward(items: Vec<ArcStr>) -> Arc<List<ArcStr>> {
        let mut res = metamodelica::nil();
        for it in items.into_iter().rev() {
            res = metamodelica::cons(it, res);
        }
        res
    }

    let maxn = maxMatches.max(0) as usize;
    let pattern = posix_to_rust(re.as_str(), extended);

    // The C runtime passes no REG_NEWLINE, so `.` matches newline too and `^`/`$`
    // anchor the whole subject (multi_line stays off).
    let compiled = RegexBuilder::new(&pattern)
        .case_insensitive(ignoreCase)
        .dot_matches_new_line(true)
        .build();

    let re_c = match compiled {
        Ok(c) => c,
        Err(e) => {
            // Mirror OpenModelica_regexImpl's compile-failure shape: no slots →
            // nothing to report; otherwise the message goes in slot 0.
            if maxn == 0 {
                return (0, metamodelica::nil());
            }
            let mut items: Vec<ArcStr> = Vec::with_capacity(maxn);
            items.push(ArcStr::from(format!(
                "Failed to compile regular expression: {re} with error: {e}"
            )));
            for _ in 1..maxn {
                items.push(literal!(""));
            }
            return (0, list_forward(items));
        }
    };

    // REG_NOSUB equivalent: match test only, no captured substrings.
    if maxn == 0 {
        return (if re_c.is_match(&str) { 1 } else { 0 }, metamodelica::nil());
    }

    match re_c.captures(&str) {
        None => (0, list_forward(vec![literal!(""); maxn])),
        Some(caps) => {
            // Pack only participating groups (full match at 0, then each group
            // that took part) among the first `maxn` slots, then pad with empties
            // — exactly as the POSIX `pmatch` packing in OpenModelica_regexImpl.
            let mut items: Vec<ArcStr> = Vec::with_capacity(maxn);
            for m in caps.iter().take(maxn).flatten() {
                items.push(ArcStr::from(m.as_str()));
            }
            let nmatch = items.len() as i32;
            while items.len() < maxn {
                items.push(literal!(""));
            }
            (nmatch, list_forward(items))
        }
    }
}

/// Translate a POSIX regular expression into the syntax the `regex` crate
/// accepts, reconciling the two main incompatibilities so matches behave like
/// the C runtime's `regcomp`/`regexec`:
///
///   * BRE (`extended == false`): the grouping/quantifier metacharacters are the
///     *escaped* forms (`\(`, `\)`, `\{`, `\}`, plus the GNU extensions `\+`,
///     `\?`, `\|`) while their bare forms are literal — the reverse of ERE/the
///     crate. Swap them. (ERE passes through, since the crate's syntax is ERE
///     plus extensions.)
///   * Bracket expressions: POSIX treats a leading `]` and a bare `[` as
///     ordinary members, but the crate requires both escaped (`[\]]`, `[\[]`).
///     `[:class:]`/`[.coll.]`/`[=eq=]` are copied to their own close so an inner
///     `]` doesn't end the class early.
///
/// Backreferences (`\1`…) aren't supported by the crate and don't occur in OMC's
/// patterns; a literal backslash inside a bracket expression (POSIX-literal, but
/// an escape to the crate) likewise doesn't occur and is left as-is.
#[cfg(target_arch = "wasm32")]
fn posix_to_rust(re: &str, extended: bool) -> String {
    let mut out = String::with_capacity(re.len() + 8);
    let mut chars = re.chars().peekable();
    while let Some(c) = chars.next() {
        match c {
            '\\' => match chars.next() {
                // In BRE these escapes are the operators; emit the bare form.
                Some(m @ ('(' | ')' | '{' | '}' | '+' | '?' | '|')) if !extended => out.push(m),
                // Any other escape (and all escapes in ERE) carry over verbatim.
                Some(other) => {
                    out.push('\\');
                    out.push(other);
                }
                None => out.push('\\'),
            },
            // Bare operators are literal in BRE: escape them for the crate.
            '(' | ')' | '{' | '}' | '+' | '?' | '|' if !extended => {
                out.push('\\');
                out.push(c);
            }
            '[' => {
                out.push('[');
                if chars.peek() == Some(&'^') {
                    out.push(chars.next().unwrap());
                }
                // A leading ']' is a literal member; the crate needs it escaped.
                if chars.peek() == Some(&']') {
                    chars.next();
                    out.push_str("\\]");
                }
                while let Some(c2) = chars.next() {
                    if c2 == '[' && matches!(chars.peek(), Some(':' | '.' | '=')) {
                        // POSIX [:class:] / [.coll.] / [=eq=]: copy to its close.
                        out.push('[');
                        let kind = chars.next().unwrap();
                        out.push(kind);
                        while let Some(c3) = chars.next() {
                            out.push(c3);
                            if c3 == kind && chars.peek() == Some(&']') {
                                out.push(chars.next().unwrap());
                                break;
                            }
                        }
                    } else if c2 == '[' {
                        // A bare '[' is a literal member to POSIX; escape it.
                        out.push_str("\\[");
                    } else {
                        out.push(c2);
                        if c2 == ']' {
                            break;
                        }
                    }
                }
            }
            _ => out.push(c),
        }
    }
    out
}

#[cfg(not(target_arch = "wasm32"))]
pub fn regex(
    str: ArcStr,
    re: ArcStr,
    maxMatches: i32,
    extended: bool,
    ignoreCase: bool,
) -> (i32, Arc<List<ArcStr>>) {
    use std::ffi::CString;

    fn list_forward(items: Vec<ArcStr>) -> Arc<List<ArcStr>> {
        let mut res = metamodelica::nil();
        for it in items.into_iter().rev() {
            res = metamodelica::cons(it, res);
        }
        res
    }

    let maxn = maxMatches.max(0) as usize;
    let flags = (if extended { libc::REG_EXTENDED } else { 0 })
        | (if ignoreCase { libc::REG_ICASE } else { 0 })
        | (if maxn != 0 { 0 } else { libc::REG_NOSUB });

    // POSIX strings are NUL-terminated; a NUL in the pattern/subject can't be
    // represented. OMC's patterns and subjects never contain NUL, so treat that
    // as a non-match (mirrors the C, which would simply see a truncated string).
    let (c_re, c_str) = match (CString::new(re.as_bytes()), CString::new(str.as_bytes())) {
        (Ok(a), Ok(b)) => (a, b),
        _ => {
            let items = vec![literal!(""); maxn];
            return (0, list_forward(items));
        }
    };

    unsafe {
        let mut preg: libc::regex_t = std::mem::zeroed();
        let rc = libc::regcomp(&mut preg, c_re.as_ptr(), flags);
        if rc != 0 {
            // Compile failure. With no capture slots there is nothing to report;
            // otherwise the first slot carries the error message (regerror), the
            // rest are empty — exactly as OpenModelica_regexImpl does.
            if maxn == 0 {
                return (0, metamodelica::nil());
            }
            let mut buf = vec![0 as core::ffi::c_char; 2048];
            libc::regerror(rc, &preg, buf.as_mut_ptr(), buf.len());
            let msg = std::ffi::CStr::from_ptr(buf.as_ptr()).to_string_lossy().into_owned();
            let mut items: Vec<ArcStr> = Vec::with_capacity(maxn);
            items.push(ArcStr::from(format!("Failed to compile regular expression: {re} with error: {msg}")));
            for _ in 1..maxn {
                items.push(literal!(""));
            }
            // regcomp leaves nothing to free on failure, but freeing a
            // zero-initialised regex_t is safe and matches the C path.
            libc::regfree(&mut preg);
            return (0, list_forward(items));
        }

        let mut pmatch: Vec<libc::regmatch_t> = vec![std::mem::zeroed(); maxn.max(1)];
        let res = libc::regexec(&preg, c_str.as_ptr(), maxn, pmatch.as_mut_ptr(), 0);
        libc::regfree(&mut preg);

        let bytes = str.as_bytes();
        let mut nmatch = 0i32;
        let matches = if maxn == 0 {
            if res == 0 {
                nmatch = 1;
            }
            metamodelica::nil()
        } else {
            let mut items: Vec<ArcStr> = Vec::with_capacity(maxn);
            for m in pmatch.iter().take(maxn) {
                // Pack only participating groups (rm_so != -1), like the C.
                if res == 0 && (m.rm_so as i64) != -1 {
                    let so = m.rm_so as usize;
                    let eo = m.rm_eo as usize;
                    let sub = std::str::from_utf8(&bytes[so..eo]).unwrap_or("");
                    items.push(ArcStr::from(sub));
                    nmatch += 1;
                }
            }
            while items.len() < maxn {
                items.push(literal!(""));
            }
            list_forward(items)
        };
        (nmatch, matches)
    }
}

pub fn strncmp(inString1: ArcStr, inString2: ArcStr, len: i32) -> i32 {
    if len <= 0 { return 0; }
    let n = len as usize;
    let a = inString1.as_bytes();
    let b = inString2.as_bytes();
    let na = a.len().min(n);
    let nb = b.len().min(n);
    use std::cmp::Ordering::*;
    match a[..na].cmp(&b[..nb]) {
        Less => -1,
        Equal => 0,
        Greater => 1,
    }
}

pub fn stringReplace(r#str: ArcStr, source: ArcStr, target: ArcStr) -> Result<ArcStr> {
    if source.is_empty() {
        bail!("System.stringReplace: source pattern must be non-empty");
    }
    Ok(ArcStr::from(r#str.replace(source.as_str(), target.as_str())))
}

pub fn makeC89Identifier(r#str: ArcStr) -> ArcStr {
    // Replace any character that isn't `[A-Za-z0-9_]` with `_`. If the first
    // char is a digit we prefix `_` to keep the identifier C89-legal.
    let mut out = String::with_capacity(r#str.len());
    for (i, c) in r#str.chars().enumerate() {
        if c.is_ascii_alphanumeric() || c == '_' {
            if i == 0 && c.is_ascii_digit() {
                out.push('_');
            }
            out.push(c);
        } else {
            out.push('_');
        }
    }
    ArcStr::from(out)
}

pub fn toupper(inString: ArcStr) -> ArcStr {
    ArcStr::from(inString.to_uppercase())
}

pub fn tolower(inString: ArcStr) -> ArcStr {
    ArcStr::from(inString.to_lowercase())
}

pub fn strtok(string: ArcStr, token: ArcStr) -> Arc<List<ArcStr>> {
    // C strtok semantics: each char of `token` is a delimiter; empty
    // segments are dropped. Returned as a MetaModelica list.
    let delims: Vec<char> = token.chars().collect();
    let parts: Vec<ArcStr> = string
        .split(|c: char| delims.contains(&c))
        .filter(|s| !s.is_empty())
        .map(ArcStr::from)
        .collect();
    list_from_vec(parts)
}

pub fn strtokIncludingDelimiters(string: ArcStr, token: ArcStr) -> Arc<List<ArcStr>> {
    // Splits on the *substring* `token` and re-emits the delimiter between
    // the surrounding segments (mirrors `SystemImpl__strtokIncludingDelimiters`).
    if token.is_empty() {
        return list_from_vec(vec![string]);
    }
    let mut out: Vec<ArcStr> = Vec::new();
    let mut rest: &str = &string;
    while let Some(idx) = rest.find(token.as_str()) {
        if idx > 0 {
            out.push(ArcStr::from(&rest[..idx]));
        }
        out.push(token.clone());
        rest = &rest[idx + token.len()..];
    }
    if !rest.is_empty() {
        out.push(ArcStr::from(rest));
    }
    list_from_vec(out)
}

pub fn splitOnNewline(r#str: ArcStr, includeDelimiter: bool) -> Result<Arc<List<ArcStr>>> {
    // Split on '\n' and '\r\n', mirroring `System_splitOnNewline` in
    // `runtime/System_omc.c`. When `includeDelimiter` is true the newline
    // delimiters are emitted as their OWN tokens, not re-attached to the
    // preceding line:
    //     splitOnNewline("a\nb\r\nc")        = {a, b, c}
    //     splitOnNewline("a\nb\r\nc", true)  = {a, \n, b, \r\n, c}
    // Empty segments (e.g. between consecutive newlines) are dropped. Tpl's
    // `writeChars` relies on the delimiter being a standalone "\n"/"\r\n"
    // token so it can call `newLine` — which re-applies the active block
    // indent — instead of printing a bare '\n' inside a string token (which
    // would leave the next line un-indented).
    let s = r#str.as_str();
    let bytes = s.as_bytes();
    let mut out: Vec<ArcStr> = Vec::new();
    let mut start = 0usize;
    let mut i = 0usize;
    while i < bytes.len() {
        let is_crlf = bytes[i] == b'\r' && i + 1 < bytes.len() && bytes[i + 1] == b'\n';
        if bytes[i] == b'\n' || is_crlf {
            if i > start {
                out.push(ArcStr::from(&s[start..i]));
            }
            let dl = if is_crlf { 2 } else { 1 };
            if includeDelimiter {
                out.push(ArcStr::from(&s[i..i + dl]));
            }
            i += dl;
            start = i;
        } else {
            i += 1;
        }
    }
    if i > start {
        out.push(ArcStr::from(&s[start..i]));
    }
    Ok(list_from_vec(out))
}

// ───────────────────────────────── compiler/linker config ─────────────────────

// Defaults for the simulation-code compiler toolchain, mirroring the
// `DEFAULT_*` macros from `OMCompiler/omc_config.h`: the MinGW section on
// Windows, the configure-substituted `omc_config.unix.h` elsewhere (the
// installed omc this port runs against was configured with clang, and the
// generated simulation code links against its runtime libraries, so the
// Unix values mirror that configuration). All of these can be overridden
// at runtime through the `set*` functions below (the omc
// `setCompiler`/`setCFlags`/… scripting API).
const DEFAULT_CC: &str = "clang";
const DEFAULT_CXX: &str = if cfg!(windows) { "clang++" } else { "clang++ -std=c++17" };
const DEFAULT_OMPCC: &str = "clang -fopenmp";
// Unix: "<RUNTIMECC> -shared". Windows (omc_config.h):
// DEFAULT_LD" -shared -Xlinker --export-all-symbols" with DEFAULT_LD=clang++.
const DEFAULT_LINKER: &str = if cfg!(windows) {
    "clang++ -shared -Xlinker --export-all-symbols"
} else {
    "clang -shared"
};
// DEFAULT_CFLAGS = "-DOM_HAVE_PTHREADS @RUNTIMECFLAGS@ ${MODELICAUSERCFLAGS}"
// on Unix; the MinGW section adds -mstackrealign and drops -fPIC (meaningless
// on Windows, gcc ignores it / clang warns).
const DEFAULT_CFLAGS: &str = if cfg!(windows) {
    "-DOM_HAVE_PTHREADS -Wno-parentheses-equality -falign-functions -mstackrealign -msse2 -mfpmath=sse ${MODELICAUSERCFLAGS}"
} else {
    "-DOM_HAVE_PTHREADS -fPIC -falign-functions -mfpmath=sse -fno-dollars-in-identifiers -Wno-parentheses-equality ${MODELICAUSERCFLAGS}"
};
const DEFAULT_LDFLAGS: &str = if cfg!(windows) {
    "-fopenmp -Wl,-Bstatic -lregex -ltre -lintl -liconv -lexpat -lpthread -loleaut32 -limagehlp -lhdf5 -lz -lsz -Wl,-Bdynamic"
} else {
    ""
};

pub fn setCCompiler(inString: ArcStr) {
    with(|s| s.cc = inString.to_string());
}
pub fn getCCompiler() -> ArcStr {
    let v = with(|s| s.cc.clone());
    if v.is_empty() { ArcStr::from(DEFAULT_CC) } else { ArcStr::from(v) }
}
pub fn setCFlags(inString: ArcStr) {
    with(|s| s.cflags = inString.to_string());
}
pub fn getCFlags() -> ArcStr {
    let v = with(|s| s.cflags.clone());
    if v.is_empty() { ArcStr::from(DEFAULT_CFLAGS) } else { ArcStr::from(v) }
}
pub fn setCXXCompiler(inString: ArcStr) {
    with(|s| s.cxx = inString.to_string());
}
pub fn getCXXCompiler() -> ArcStr {
    let v = with(|s| s.cxx.clone());
    if v.is_empty() { ArcStr::from(DEFAULT_CXX) } else { ArcStr::from(v) }
}
pub fn getOMPCCompiler() -> ArcStr {
    ArcStr::from(DEFAULT_OMPCC)
}
pub fn setLinker(inString: ArcStr) {
    with(|s| s.linker = inString.to_string());
}
pub fn getLinker() -> ArcStr {
    let v = with(|s| s.linker.clone());
    if v.is_empty() { ArcStr::from(DEFAULT_LINKER) } else { ArcStr::from(v) }
}
pub fn setLDFlags(inString: ArcStr) {
    with(|s| s.ldflags = inString.to_string());
}
pub fn getLDFlags() -> ArcStr {
    let v = with(|s| s.ldflags.clone());
    if v.is_empty() { ArcStr::from(DEFAULT_LDFLAGS) } else { ArcStr::from(v) }
}

// ───────────────────────────────── dynamic library loading ────────────────────

// The `-d=gen` pipeline compiles a MetaModelica function to C, builds it into a
// shared object linking the C MetaModelica runtime, loads it and marshals the
// argument/result `Values`. The loader state lives in `crate::dynload`; the
// `Values` marshalling (`DynLoad.executeFunction`) lives in
// `openmodelica_script_util` since it needs the frontend `Values` type.

pub fn loadLibrary(inLib: ArcStr, relativePath: bool, printDebug: bool) -> Result<i32> {
    crate::dynload::load_library(&inLib, relativePath, printDebug)
}
pub fn lookupFunction(inLibHandle: i32, inFunc: ArcStr) -> Result<i32> {
    crate::dynload::lookup_function(inLibHandle, &inFunc)
}
pub fn freeFunction(inFuncHandle: i32, inPrintDebug: bool) -> Result<()> {
    crate::dynload::free_function(inFuncHandle, inPrintDebug)
}
pub fn freeLibrary(inLibHandle: i32, inPrintDebug: bool) -> Result<()> {
    crate::dynload::free_library(inLibHandle, inPrintDebug)
}

// ───────────────────────────────── file I/O ──────────────────────────────────

pub fn writeFile(fileNameToWrite: ArcStr, stringToBeWritten: ArcStr) -> Result<()> {
    // On wasm there is no OS filesystem; keep written files in the in-memory VFS
    // so the rest of the run (and the JS host) can read them back.
    #[cfg(target_arch = "wasm32")]
    {
        openmodelica_vfs::write(fileNameToWrite.as_str(), stringToBeWritten.as_bytes().to_vec());
        return Ok(());
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        fs::write(fileNameToWrite.as_str(), stringToBeWritten.as_bytes())
            .with_context(|| format!("System.writeFile: cannot write {}", fileNameToWrite))?;
        Ok(())
    }
}

pub fn appendFile(file: ArcStr, data: ArcStr) -> Result<()> {
    #[cfg(target_arch = "wasm32")]
    {
        openmodelica_vfs::append(file.as_str(), data.as_bytes());
        return Ok(());
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        use std::io::Write as _;
        let mut f = fs::OpenOptions::new().create(true).append(true)
            .open(file.as_str())
            .with_context(|| format!("System.appendFile: cannot open {file}"))?;
        f.write_all(data.as_bytes())
            .with_context(|| format!("System.appendFile: cannot write to {file}"))?;
        Ok(())
    }
}

pub fn readFile(inString: ArcStr) -> Result<ArcStr> {
    #[cfg(target_arch = "wasm32")]
    let bytes = openmodelica_vfs::read(inString.as_str())
        .with_context(|| format!("System.readFile: cannot read {inString}"))?;
    #[cfg(not(target_arch = "wasm32"))]
    let bytes = fs::read(inString.as_str())
        .with_context(|| format!("System.readFile: cannot read {inString}"))?;
    let s = String::from_utf8(bytes)
        .with_context(|| format!("System.readFile: {inString} is not valid UTF-8"))?;
    Ok(ArcStr::from(s))
}

pub fn systemCallRestrictedEnv(command: ArcStr, outFile: ArcStr) -> Result<i32> {
    // `System.mo`'s systemCallRestrictedEnv is plain MetaModelica: only on
    // Windows does it temporarily restrict PATH (to the Windows / OM / OMDev
    // directories) around the call; on every other OS it is exactly
    // `systemCall(command, outFile)`. This port targets Linux
    // (`Autoconf::os == "linux"`), so forward directly; the Windows PATH
    // dance needs porting only if the port ever targets Windows.
    Ok(systemCall(command, outFile))
}

pub fn winGetSystemDirectory() -> ArcStr {
    // Windows-only (`GetSystemDirectoryA`). We're Linux-only at the
    // moment, so always return the empty string per the .mo doc.
    literal!("")
}

pub fn systemCall(command: ArcStr, outFile: ArcStr) -> i32 {
    // Spawn /bin/sh -c <command>; if outFile is non-empty, redirect both
    // stdout and stderr there. Returns the child's exit code, or -1 on
    // spawn failure.
    use std::process::{Command, Stdio};
    let mut cmd = Command::new("/bin/sh");
    cmd.arg("-c").arg(command.as_str());
    if !outFile.is_empty() {
        match fs::File::create(outFile.as_str()) {
            Ok(f) => {
                let f2 = match f.try_clone() {
                    Ok(c) => c,
                    Err(_) => return -1,
                };
                cmd.stdout(Stdio::from(f));
                cmd.stderr(Stdio::from(f2));
            }
            Err(_) => return -1,
        }
    }
    match cmd.status() {
        Ok(s) => s.code().unwrap_or(-1),
        Err(_) => -1,
    }
}

pub fn popen(command: ArcStr) -> (ArcStr, i32) {
    use std::process::Command;
    match Command::new("/bin/sh").arg("-c").arg(command.as_str()).output() {
        Ok(o) => {
            let out = String::from_utf8_lossy(&o.stdout).into_owned();
            (ArcStr::from(out), o.status.code().unwrap_or(-1))
        }
        Err(_) => (literal!(""), -1),
    }
}

pub fn systemCallParallel(_inStrings: Arc<List<ArcStr>>, _numThreads: i32) -> Arc<List<i32>> {
    // Fan-out N shell commands across a thread pool and collect the exit
    // codes. Not used by code paths exercised today; defer until needed.
    todo!("System.systemCallParallel: parallel shell-out not yet ported")
}

pub fn spawnCall(_path: ArcStr, _str: ArcStr) -> i32 {
    // Spawns a child but does not wait — returns the pid. The C side uses
    // posix_spawn/CreateProcess. Defer until a caller needs it.
    todo!("System.spawnCall: detached subprocess spawn not yet ported")
}

// ───────────────────────────────── plot / loadModel callbacks ─────────────────

// In the in-process embedding (libOpenModelicaCompiler.so, used by OMEdit) the
// host registers C callbacks omc invokes when an evaluated script runs
// `plot(...)` / `loadModel(...)`. The C runtime stored them on `threadData`
// (`SystemImpl__plotCallBack` in runtime/systemimpl.c reads `threadData->plotCB`);
// here a process-global registry holds them, set through the `omc_set_*_callback`
// C entry points the OMEdit C++ shim calls before evaluating a command.

/// Matches the C `PlotCallback` (`gc/omc_gc.h`): the host class pointer, an
/// external-window flag, then 18 string arguments.
pub type PlotCallback = unsafe extern "C" fn(
    *mut std::ffi::c_void,
    core::ffi::c_int,
    *const core::ffi::c_char, *const core::ffi::c_char, *const core::ffi::c_char, *const core::ffi::c_char,
    *const core::ffi::c_char, *const core::ffi::c_char, *const core::ffi::c_char, *const core::ffi::c_char,
    *const core::ffi::c_char, *const core::ffi::c_char, *const core::ffi::c_char, *const core::ffi::c_char,
    *const core::ffi::c_char, *const core::ffi::c_char, *const core::ffi::c_char, *const core::ffi::c_char,
    *const core::ffi::c_char, *const core::ffi::c_char,
);

/// Matches the C `LoadModelCallback`: the host class pointer and a model name.
pub type LoadModelCallback = unsafe extern "C" fn(*mut std::ffi::c_void, *const core::ffi::c_char);

struct PlotReg {
    class_ptr: usize,
    cb: PlotCallback,
}
struct LoadReg {
    class_ptr: usize,
    cb: LoadModelCallback,
}
// The host pointer is stored as `usize` so the statics are `Send`; the function
// pointers are themselves `Send`/`Sync`.
static PLOT_CB: std::sync::Mutex<Option<PlotReg>> = std::sync::Mutex::new(None);
static LOAD_CB: std::sync::Mutex<Option<LoadReg>> = std::sync::Mutex::new(None);

/// Register (or, with a null `cb`, clear) the plot callback. `Option<fn>` is
/// ABI-identical to the function pointer, so a null pointer arrives as `None`.
#[unsafe(no_mangle)]
pub extern "C" fn omc_set_plot_callback(class_ptr: *mut std::ffi::c_void, cb: Option<PlotCallback>) {
    *PLOT_CB.lock().unwrap() = cb.map(|cb| PlotReg { class_ptr: class_ptr as usize, cb });
}

/// Register (or clear) the loadModel callback. See [`omc_set_plot_callback`].
#[unsafe(no_mangle)]
pub extern "C" fn omc_set_loadmodel_callback(
    class_ptr: *mut std::ffi::c_void,
    cb: Option<LoadModelCallback>,
) {
    *LOAD_CB.lock().unwrap() = cb.map(|cb| LoadReg { class_ptr: class_ptr as usize, cb });
}

pub fn plotCallBackDefined() -> bool {
    PLOT_CB.lock().unwrap().is_some()
}

pub fn plotCallBack(
    externalWindow: bool, filename: ArcStr, title: ArcStr, grid: ArcStr, plotType: ArcStr,
    logX: ArcStr, logY: ArcStr, xLabel: ArcStr, yLabel: ArcStr, x1: ArcStr, x2: ArcStr,
    y1: ArcStr, y2: ArcStr, curveWidth: ArcStr, curveStyle: ArcStr, legendPosition: ArcStr,
    footer: ArcStr, autoScale: ArcStr, variables: ArcStr,
) {
    // Copy the (Copy) registration out and release the lock before calling: the
    // host callback may re-enter the compiler, which must not deadlock here.
    let reg = match PLOT_CB.lock().unwrap().as_ref() {
        Some(r) => (r.class_ptr, r.cb),
        None => return,
    };
    let cs = |s: &str| std::ffi::CString::new(s.replace('\0', " ")).unwrap_or_default();
    let (f, ti, g, pt, lx, ly, xl, yl, a1, a2, b1, b2, cw, cstyle, lp, ft, asc, vars) = (
        cs(&filename), cs(&title), cs(&grid), cs(&plotType), cs(&logX), cs(&logY),
        cs(&xLabel), cs(&yLabel), cs(&x1), cs(&x2), cs(&y1), cs(&y2),
        cs(&curveWidth), cs(&curveStyle), cs(&legendPosition), cs(&footer),
        cs(&autoScale), cs(&variables),
    );
    // SAFETY: `reg.1` was registered by the host as a valid C callback paired
    // with `reg.0` (its class pointer); the CStrings outlive the call.
    unsafe {
        (reg.1)(
            reg.0 as *mut std::ffi::c_void, externalWindow as core::ffi::c_int,
            f.as_ptr(), ti.as_ptr(), g.as_ptr(), pt.as_ptr(),
            lx.as_ptr(), ly.as_ptr(), xl.as_ptr(), yl.as_ptr(),
            a1.as_ptr(), a2.as_ptr(), b1.as_ptr(), b2.as_ptr(),
            cw.as_ptr(), cstyle.as_ptr(), lp.as_ptr(), ft.as_ptr(),
            asc.as_ptr(), vars.as_ptr(),
        );
    }
}

pub fn loadModelCallBackDefined() -> bool {
    LOAD_CB.lock().unwrap().is_some()
}

pub fn loadModelCallBack(modelName: ArcStr) {
    let reg = match LOAD_CB.lock().unwrap().as_ref() {
        Some(r) => (r.class_ptr, r.cb),
        None => return,
    };
    let name = std::ffi::CString::new(modelName.replace('\0', " ")).unwrap_or_default();
    // SAFETY: as in `plotCallBack`.
    unsafe { (reg.1)(reg.0 as *mut std::ffi::c_void, name.as_ptr()) }
}

// ───────────────────────────────── directory ops ──────────────────────────────

pub fn cd(inString: ArcStr) -> i32 {
    match std::env::set_current_dir(inString.as_str()) {
        Ok(()) => 0,
        Err(_) => -1,
    }
}

pub fn createDirectory(inString: ArcStr) -> bool {
    // The VFS has no directory objects (a file's path implies its parents), so
    // "creating" one always succeeds — callers (e.g. createDirectoryTree) then
    // write files beneath it.
    #[cfg(target_arch = "wasm32")]
    {
        let _ = inString;
        return true;
    }
    #[cfg(not(target_arch = "wasm32"))]
    fs::create_dir(inString.as_str()).is_ok()
}

pub fn createTemporaryDirectory(inPrefix: ArcStr) -> Result<ArcStr> {
    // Mimic mkdtemp: try a handful of nanosecond-suffixed paths under the
    // given prefix until one creates successfully. The prefix is a *path
    // prefix*, not a parent directory, matching the .mo semantics.
    for _ in 0..32 {
        let nanos = SystemTime::now().duration_since(UNIX_EPOCH)
            .map(|d| d.subsec_nanos()).unwrap_or(0);
        let salt: u32 = with(|s| {
            s.rng = s.rng.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            (s.rng >> 33) as u32
        });
        let candidate = format!("{inPrefix}{:08x}{:08x}", nanos, salt);
        // VFS directories are implicit, so a unique name is "created" by just
        // returning it (files written under it materialise the directory).
        #[cfg(target_arch = "wasm32")]
        if !openmodelica_vfs::exists(&candidate) && !openmodelica_vfs::is_dir(&candidate) {
            return Ok(ArcStr::from(candidate));
        }
        #[cfg(not(target_arch = "wasm32"))]
        if fs::create_dir(&candidate).is_ok() {
            return Ok(ArcStr::from(candidate));
        }
    }
    bail!("System.createTemporaryDirectory: failed to create unique directory under {inPrefix}")
}

pub fn pwd() -> ArcStr {
    match std::env::current_dir() {
        Ok(p) => ArcStr::from(p.to_string_lossy().as_ref()),
        Err(_) => literal!(""),
    }
}

// The wasm build has no OS environment — `std::env::set_var` *panics* on
// wasm32-unknown-unknown — so `setEnv`/`readEnv` keep an in-process map instead
// (wasm is single-threaded, hence a `thread_local`). The JS host seeds it (e.g.
// OPENMODELICAHOME) before init.
#[cfg(target_arch = "wasm32")]
thread_local! {
    static WASM_ENV: std::cell::RefCell<std::collections::HashMap<String, String>> =
        std::cell::RefCell::new(std::collections::HashMap::new());
}

pub fn readEnv(inString: ArcStr) -> Result<ArcStr> {
    #[cfg(target_arch = "wasm32")]
    if let Some(v) = WASM_ENV.with(|e| e.borrow().get(inString.as_str()).cloned()) {
        return Ok(ArcStr::from(v));
    }
    match std::env::var(inString.as_str()) {
        Ok(v) => Ok(ArcStr::from(v)),
        Err(_) => bail!("System.readEnv: variable {inString} not set"),
    }
}

pub fn setEnv(varName: ArcStr, value: ArcStr, overwrite: bool) -> i32 {
    #[cfg(target_arch = "wasm32")]
    {
        WASM_ENV.with(|e| {
            let mut m = e.borrow_mut();
            if overwrite || !m.contains_key(varName.as_str()) {
                m.insert(varName.to_string(), value.to_string());
            }
        });
        return 0;
    }
    // SAFETY: std::env::set_var is `unsafe` under edition 2024 because it
    // races with concurrent getenv calls in other threads. The C runtime
    // accepts the same hazard; we mirror the behavior here and rely on
    // callers using this only during startup configuration.
    #[cfg(not(target_arch = "wasm32"))]
    {
        if !overwrite && std::env::var_os(varName.as_str()).is_some() {
            return 0;
        }
        unsafe { std::env::set_var(varName.as_str(), value.as_str()); }
        0
    }
}

pub fn subDirectories(inString: ArcStr) -> Arc<List<ArcStr>> {
    #[cfg(target_arch = "wasm32")]
    {
        let out: Vec<ArcStr> = openmodelica_vfs::list_dir(inString.as_str())
            .into_iter()
            .filter(|(_, is_dir)| *is_dir)
            .map(|(name, _)| ArcStr::from(name))
            .collect();
        return list_from_vec(out);
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        let mut out: Vec<ArcStr> = Vec::new();
        if let Ok(rd) = fs::read_dir(inString.as_str()) {
            for ent in rd.flatten() {
                let p = ent.path();
                if p.is_dir()
                    && let Some(name) = p.file_name() {
                        out.push(ArcStr::from(name.to_string_lossy().as_ref()));
                    }
            }
        }
        list_from_vec(out)
    }
}

fn files_with_ext(dir: &str, ext: &str) -> Vec<ArcStr> {
    // Mirrors `file_select_mo`/`file_select_moc` in runtime/systemimpl.c:
    // list `*.<ext>` files but exclude the directory's own `package.<ext>`
    // — that file names the package itself, not a sub-class, and callers
    // (ClassLoader.getPackageContentNames) treat every returned name as a
    // class to load. The C version returns directory order (scandir with a
    // NULL comparator); callers that care sort the combined list themselves.
    let package_file = format!("package.{ext}");
    let dot_ext = format!(".{ext}");
    #[cfg(target_arch = "wasm32")]
    {
        openmodelica_vfs::list_dir(dir)
            .into_iter()
            .filter(|(name, is_dir)| {
                !is_dir && name.ends_with(&dot_ext) && name.as_str() != package_file.as_str()
            })
            .map(|(name, _)| ArcStr::from(name))
            .collect()
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        let _ = &dot_ext;
        let mut out: Vec<ArcStr> = Vec::new();
        if let Ok(rd) = fs::read_dir(dir) {
            for ent in rd.flatten() {
                let p = ent.path();
                if p.is_file()
                    && p.extension().map(|e| e == ext).unwrap_or(false)
                    && let Some(name) = p.file_name()
                    && name.to_string_lossy() != package_file.as_str()
                {
                    out.push(ArcStr::from(name.to_string_lossy().as_ref()));
                }
            }
        }
        out
    }
}

pub fn moFiles(inString: ArcStr) -> Arc<List<ArcStr>> {
    list_from_vec(files_with_ext(&inString, "mo"))
}
pub fn mocFiles(inString: ArcStr) -> Arc<List<ArcStr>> {
    list_from_vec(files_with_ext(&inString, "moc"))
}

// ───────────────────────── getLoadModelPath ──────────────────────────
// Port of the modelicaPathEntry machinery in `runtime/systemimpl.c`
// (`System_getLoadModelPath` and helpers).

/// `MODELICAPATH_LEVELS` in systemimpl.c: how many dotted numeric version
/// components are tracked ("3.2.1" == "3.2.1.0.0.0").
const MODELICAPATH_LEVELS: usize = 6;

/// One library candidate found on the load path: `dir` is the MODELICAPATH
/// entry it lives in, `file` the directory or file name (including any
/// " <version>" suffix and `.mo`/`.moc` extension).
struct ModelicaPathEntry {
    dir: ArcStr,
    file: String,
    version: [i64; MODELICAPATH_LEVELS],
    version_extra: String,
    file_is_dir: bool,
}

/// Mirror of `splitVersion`: parse up to [`MODELICAPATH_LEVELS`] dotted
/// numbers, then keep the remainder as the "extra" part (pre-release tag
/// etc.). Returns `(numbers, extra, had_digit_version)`. Quirks preserved
/// from C: a single leading space before the extra is skipped, a `+`
/// remainder means "any build of this version" and clears the extra, and a
/// trailing `mo` is chopped off (this is how the `.mo` file extension is
/// stripped after the dot terminates number parsing).
fn split_version(version: &str) -> ([i64; MODELICAPATH_LEVELS], String, bool) {
    let mut nums = [0i64; MODELICAPATH_LEVELS];
    if !version.starts_with(|c: char| c.is_ascii_digit()) {
        return (nums, version.to_string(), false);
    }
    let mut buf = version;
    for slot in nums.iter_mut() {
        let digits = buf.len() - buf.trim_start_matches(|c: char| c.is_ascii_digit()).len();
        if digits == 0 {
            break;
        }
        // More digits than fit in i64 would be a pathological name; stop
        // parsing numbers there like strtol's clamp effectively would.
        let Ok(l) = buf[..digits].parse::<i64>() else { break };
        *slot = l;
        buf = &buf[digits..];
        if let Some(rest) = buf.strip_prefix('.') {
            buf = rest;
        }
    }
    let buf = buf.strip_prefix(' ').unwrap_or(buf);
    let mut extra = if buf.starts_with('+') { String::new() } else { buf.to_string() };
    if extra.len() >= 2 && extra.ends_with("mo") {
        extra.truncate(extra.len() - 2);
    }
    (nums, extra, true)
}

/// Mirror of `getAllModelicaPaths`: scan every directory in `mps` for
/// entries whose name is `name`, `name.<ext>` or `name <version>[.<ext>]`,
/// either as a library directory (containing `package.mo`/`package.moc`)
/// or as a plain `.mo`/`.moc` file.
fn get_all_modelica_paths(name: &str, mps: &Arc<List<ArcStr>>) -> Vec<ModelicaPathEntry> {
    let mut res = Vec::new();
    for mp in &**mps {
        for (file, _) in dir_entries(mp.as_str()) {
            if !file.starts_with(name)
                || !matches!(file.as_bytes().get(name.len()), None | Some(b' ') | Some(b'.'))
            {
                continue;
            }
            let is_package_dir = ["package.mo", "package.moc"].iter().any(|pkg| {
                path_is_file(&format!("{mp}/{file}/{pkg}"))
            });
            let file_is_dir = if is_package_dir {
                true
            } else if (file.ends_with(".mo") || file.ends_with(".moc"))
                && path_is_file(&format!("{mp}/{file}"))
            {
                false
            } else {
                continue;
            };
            let (version, version_extra) = match file.as_bytes().get(name.len()) {
                Some(b' ') => {
                    let (v, e, _) = split_version(&file[name.len() + 1..]);
                    (v, e)
                }
                _ => ([0; MODELICAPATH_LEVELS], String::new()),
            };
            res.push(ModelicaPathEntry { dir: mp.clone(), file, version, version_extra, file_is_dir });
        }
    }
    res
}

/// Immediate children of `dir` as `(name, is_dir)`: the OS filesystem natively,
/// the in-memory VFS on wasm. Used by the MODELICAPATH scan.
fn dir_entries(dir: &str) -> Vec<(String, bool)> {
    #[cfg(target_arch = "wasm32")]
    {
        openmodelica_vfs::list_dir(dir)
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        let mut out = Vec::new();
        if let Ok(rd) = fs::read_dir(dir) {
            for ent in rd.flatten() {
                if let Ok(name) = ent.file_name().into_string() {
                    out.push((name, ent.path().is_dir()));
                }
            }
        }
        out
    }
}

/// True when `path` is an existing regular file: the OS filesystem natively, the
/// VFS on wasm.
fn path_is_file(path: &str) -> bool {
    #[cfg(target_arch = "wasm32")]
    {
        openmodelica_vfs::exists(path)
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        fs::metadata(path).map(|m| m.is_file()).unwrap_or(false)
    }
}

fn version_equal(v1: &[i64], v2: &[i64], num_to_test: usize) -> bool {
    v1[..num_to_test] == v2[..num_to_test]
}

/// `modelicaPathEntryVersionGreater`: lexicographic >=. (Equal versions
/// also return true, exactly like the C helper.)
fn version_greater(v1: &[i64], v2: &[i64]) -> bool {
    for (a, b) in v1.iter().zip(v2.iter()) {
        if a > b {
            return true;
        }
        if a < b {
            return false;
        }
    }
    true
}

/// Mirror of `getLoadModelPathFromSingleTarget`: find the entry matching a
/// specific requested version, relaxing one trailing version level at a
/// time unless `exact_version` is set.
fn load_model_path_single_target<'e>(
    search_target: &str,
    entries: &'e [ModelicaPathEntry],
    exact_version: bool,
) -> Option<&'e ModelicaPathEntry> {
    let (version, version_extra, found_digit_version) = split_version(search_target);
    if found_digit_version && version_extra.is_empty() {
        // Makes us load 3.2.1 when 3.2.0.0 is not available: drop one more
        // trailing version level from the comparison on each failure.
        let min_level = if exact_version { MODELICAPATH_LEVELS } else { 0 };
        for j in (min_level..=MODELICAPATH_LEVELS).rev() {
            let mut found: Option<&ModelicaPathEntry> = None;
            let mut found_version = [0i64; MODELICAPATH_LEVELS];
            for e in entries {
                if version_equal(&e.version, &version, j)
                    && (j == MODELICAPATH_LEVELS || version_greater(&e.version, &version))
                    && matches!(e.version_extra.as_bytes().first(), None | Some(b'+') | Some(b'-'))
                    && version_greater(&e.version, &found_version)
                {
                    found_version = e.version;
                    found = Some(e);
                }
            }
            if found.is_some() {
                return found;
            }
        }
    }
    for e in entries {
        // Note: like the C code, only the first three levels are checked
        // for zero here (a request like "0.0.0.1" takes this branch too).
        if version[..3] == [0, 0, 0] {
            let entry_extra = if e.version_extra.starts_with('-') && !version_extra.starts_with('-')
            {
                &e.version_extra[1..]
            } else {
                &e.version_extra
            };
            if entry_extra.starts_with(&version_extra) {
                return Some(e);
            }
        }
        if version_equal(&e.version, &version, MODELICAPATH_LEVELS)
            && e.version_extra.starts_with(&version_extra)
        {
            return Some(e);
        }
    }
    None
}

/// Mirror of `getLoadModelPathFromDefaultTarget`: prefer the highest
/// release version (no pre-release tag, or a `+`/`-` build/maintenance
/// tag), falling back to the highest version of any kind.
fn load_model_path_default_target(entries: &[ModelicaPathEntry]) -> Option<&ModelicaPathEntry> {
    let mut found: Option<&ModelicaPathEntry> = None;
    let mut found_version = [-1i64, -1, -1, 0, 0, 0];
    for e in entries {
        if version_greater(&e.version, &found_version)
            && matches!(e.version_extra.as_bytes().first(), None | Some(b'+') | Some(b'-'))
        {
            found_version = e.version;
            found = Some(e);
        }
    }
    if found.is_none() {
        // (The C fallback also tries a versionExtra string tie-break, but
        // it is guarded by `entries[i].version == foundVersion`, which
        // compares two distinct arrays *by pointer* — never true — so the
        // condition reduces to the version comparison alone.)
        for e in entries {
            if version_greater(&e.version, &found_version) {
                found_version = e.version;
                found = Some(e);
            }
        }
    }
    found
}

/// Locate a Modelica package on the load path. Port of
/// `System_getLoadModelPath`: try each priority in order ("default" means
/// best available version); fails (MMC_THROW in C) when nothing matches.
pub fn getLoadModelPath(
    className: ArcStr,
    prios: Arc<List<ArcStr>>,
    mps: Arc<List<ArcStr>>,
    requireExactVersion: bool,
) -> Result<(ArcStr, ArcStr, bool)> {
    let entries = get_all_modelica_paths(&className, &mps);
    for prio in &*prios {
        let found = if prio.as_str() == "default" {
            load_model_path_default_target(&entries)
        } else {
            load_model_path_single_target(prio, &entries, requireExactVersion)
        };
        if let Some(e) = found {
            return Ok((e.dir.clone(), ArcStr::from(e.file.clone()), e.file_is_dir));
        }
    }
    bail!("System.getLoadModelPath: no match for {className} on the MODELICAPATH")
}

pub fn time() -> metamodelica::Real {
    let secs = SystemTime::now().duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs_f64()).unwrap_or(0.0);
    metamodelica::OrderedFloat(secs)
}

pub fn regularFileExists(inString: ArcStr) -> bool {
    #[cfg(target_arch = "wasm32")]
    return openmodelica_vfs::exists(inString.as_str());
    #[cfg(not(target_arch = "wasm32"))]
    fs::metadata(inString.as_str()).map(|m| m.is_file()).unwrap_or(false)
}

pub fn regularFileReadable(inString: ArcStr) -> bool {
    // No portable "readable" probe in std without actually opening — try
    // and immediately drop. Matches what `access(R_OK)` reports modulo
    // races. On wasm, a present VFS file is readable.
    #[cfg(target_arch = "wasm32")]
    return openmodelica_vfs::exists(inString.as_str());
    #[cfg(not(target_arch = "wasm32"))]
    fs::File::open(inString.as_str()).is_ok()
}

pub fn regularFileWritable(inString: ArcStr) -> bool {
    // The VFS is always writable; report writable iff the file exists (matching
    // the native "open an existing file for writing" probe).
    #[cfg(target_arch = "wasm32")]
    return openmodelica_vfs::exists(inString.as_str());
    #[cfg(not(target_arch = "wasm32"))]
    fs::OpenOptions::new().write(true).open(inString.as_str()).is_ok()
}

pub fn removeFile(fileName: ArcStr) -> i32 {
    // 0 on success, -1 if the file was absent / could not be removed — matching
    // the C runtime and `fs::remove_file`. On wasm the file lives in the VFS, so
    // `fs::remove_file` would always fail (no OS filesystem); route to the VFS.
    #[cfg(target_arch = "wasm32")]
    return if openmodelica_vfs::remove(fileName.as_str()) { 0 } else { -1 };
    #[cfg(not(target_arch = "wasm32"))]
    match fs::remove_file(fileName.as_str()) {
        Ok(()) => 0,
        Err(_) => -1,
    }
}

pub fn directoryExists(inString: ArcStr) -> bool {
    #[cfg(target_arch = "wasm32")]
    return openmodelica_vfs::is_dir(inString.as_str());
    #[cfg(not(target_arch = "wasm32"))]
    fs::metadata(inString.as_str()).map(|m| m.is_dir()).unwrap_or(false)
}

pub fn copyFile(source: ArcStr, destination: ArcStr) -> bool {
    #[cfg(target_arch = "wasm32")]
    {
        match openmodelica_vfs::read(source.as_str()) {
            Some(bytes) => {
                openmodelica_vfs::write(destination.as_str(), bytes);
                true
            }
            None => false,
        }
    }
    #[cfg(not(target_arch = "wasm32"))]
    fs::copy(source.as_str(), destination.as_str()).is_ok()
}

pub fn removeDirectory(inString: ArcStr) -> bool {
    // `SystemImpl__removeDirectory` is more than a recursive delete; the
    // scripting `remove()` API relies on two quirks:
    //   * a non-directory path is unlink'ed (scripts call remove() on plain
    //     files, e.g. recompileFMU.mos removes simpleLoop.fmu), and
    //   * the path may contain a `*` wildcard inside one component
    //     ("[base/]pre*post[/sub]"); every matching entry is removed,
    //     failures of individual matches are ignored, and the result is
    //     true as long as the wildcard's base directory could be read.
    #[cfg(target_arch = "wasm32")]
    return wasm_remove_path(inString.as_str());
    #[cfg(not(target_arch = "wasm32"))]
    remove_directory_wild(inString.as_str())
}

/// VFS counterpart of [`remove_directory_wild`]: remove a plain file, a whole
/// directory subtree (every entry under `path/`), or — for a `*` wildcard — every
/// VFS file matching the prefix/suffix around the first star. Lenient (always
/// true), matching the native version's "true as long as the base was readable".
#[cfg(target_arch = "wasm32")]
fn wasm_remove_path(path: &str) -> bool {
    if let Some((pre, post)) = path.split_once('*') {
        for f in openmodelica_vfs::list() {
            if f.len() >= pre.len() + post.len() && f.starts_with(pre) && f.ends_with(post) {
                openmodelica_vfs::remove(&f);
            }
        }
        return true;
    }
    openmodelica_vfs::remove(path);
    let prefix = format!("{}/", path.trim_end_matches('/'));
    for f in openmodelica_vfs::list() {
        if f.starts_with(&prefix) {
            openmodelica_vfs::remove(&f);
        }
    }
    true
}

#[cfg(not(target_arch = "wasm32"))]
fn remove_directory_wild(path: &str) -> bool {
    let Some(star) = path.find('*') else {
        return remove_directory_item(path);
    };
    // Split "[basepath/]pre*post[/sub]" around the component holding the
    // first `*`. Like the C unix branch, only `/` separates components
    // (omc-internal paths are forward-slash normalized).
    let (prefix, sub) = match path[star..].find('/') {
        Some(i) => (&path[..star + i], Some(&path[star + i + 1..])),
        None => (path, None),
    };
    let (basepath, pattern) = match prefix[..star].rfind('/') {
        Some(i) => (&prefix[..i], &prefix[i + 1..]),
        None => (".", prefix),
    };
    // Only the first `*` splits the pattern; a second one would be matched
    // literally in C as well.
    let (pat_pre, pat_post) = pattern.split_once('*').expect("component contains the `*`");
    // An empty basepath (wildcard in the first component of an absolute
    // path) fails read_dir just like C's opendir("").
    let Ok(entries) = fs::read_dir(basepath) else {
        return false;
    };
    for entry in entries.flatten() {
        let name = entry.file_name();
        let Some(name) = name.to_str() else { continue };
        let matches = name.len() >= pat_pre.len() + pat_post.len()
            && name.starts_with(pat_pre)
            && name.ends_with(pat_post);
        if !matches {
            continue;
        }
        let full = format!("{basepath}/{name}");
        // stat (following symlinks) like the C code; ignore per-item errors.
        let Ok(meta) = fs::metadata(&full) else { continue };
        if meta.is_dir() {
            match sub {
                Some(sub) => {
                    remove_directory_wild(&format!("{full}/{sub}"));
                }
                None => {
                    remove_directory_item(&full);
                }
            }
        } else if sub.is_none() {
            let _ = fs::remove_file(&full);
        }
        // A file with remaining sub-path components is skipped, as in C.
    }
    true
}

/// Wildcard-free delete: directories recursively, anything else (plain
/// file, dead symlink) via unlink — `SystemImpl__removeDirectoryItem`.
#[cfg(not(target_arch = "wasm32"))]
fn remove_directory_item(path: &str) -> bool {
    if fs::metadata(path).map(|m| m.is_dir()).unwrap_or(false) {
        fs::remove_dir_all(path).is_ok()
    } else {
        fs::remove_file(path).is_ok()
    }
}

// ───────────────────────────────── classnames-for-simulation cache ────────────

pub fn getClassnamesForSimulation() -> ArcStr {
    ArcStr::from(with(|s| s.classnames_for_simulation.clone()))
}
pub fn setClassnamesForSimulation(inString: ArcStr) {
    with(|s| s.classnames_for_simulation = inString.to_string());
}

pub fn getVariableValue(
    _timeStamp: metamodelica::Real,
    _timeValues: Arc<List<metamodelica::Real>>,
    _varValues: Arc<List<metamodelica::Real>>,
) -> Result<metamodelica::Real> {
    // Linear interpolation of a varValues sample at timeStamp; the C
    // runtime walks the parallel `timeValues` list looking for the
    // surrounding samples. Defer until a caller needs it.
    todo!("System.getVariableValue: time-series interpolation not yet ported")
}

pub fn getFileModificationTime(fileName: ArcStr) -> Option<metamodelica::Real> {
    // The VFS keeps no timestamps; report epoch (0) for a file that exists so
    // callers get `Some` for present files and `None` for missing ones.
    #[cfg(target_arch = "wasm32")]
    return openmodelica_vfs::exists(fileName.as_str()).then(|| metamodelica::OrderedFloat(0.0));
    #[cfg(not(target_arch = "wasm32"))]
    fs::metadata(fileName.as_str()).ok()
        .and_then(|m| m.modified().ok())
        .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
        .map(|d| metamodelica::OrderedFloat(d.as_secs_f64()))
}

pub fn getCurrentTime() -> metamodelica::Real {
    time()
}

pub fn getCurrentDateTime() -> (i32, i32, i32, i32, i32, i32) {
    // Returns (sec, min, hour, mday, mon, year) — the C runtime mirrors
    // POSIX `struct tm` *without* the `tm_year - 1900` adjustment, so
    // `year` is the full year (e.g. 2026). chrono isn't a dependency, so
    // compute by hand from a unix timestamp: this is good enough for the
    // `getCurrentTimeStr` formatter, which is the only consumer.
    let secs = SystemTime::now().duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64).unwrap_or(0);
    let (year, mon, mday, hour, min, sec) = epoch_to_civil(secs);
    (sec, min, hour, mday, mon, year)
}

/// Convert a Unix timestamp (in seconds) to (year, month, day-of-month,
/// hour, minute, second) in UTC. Adapted from Howard Hinnant's `civil`
/// algorithm — no DST, no leap seconds, sufficient for stamp formatting.
fn epoch_to_civil(secs: i64) -> (i32, i32, i32, i32, i32, i32) {
    let days = secs.div_euclid(86_400);
    let secs_of_day = secs.rem_euclid(86_400);
    let z = days + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let doe = (z - era * 146_097) as u32;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let y = yoe as i64 + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = if m <= 2 { y + 1 } else { y };
    let hour = secs_of_day / 3600;
    let min = (secs_of_day % 3600) / 60;
    let sec = secs_of_day % 60;
    (year as i32, m as i32, d as i32, hour as i32, min as i32, sec as i32)
}

pub fn getCurrentTimeStr() -> Result<ArcStr> {
    let (sec, min, hour, mday, mon, year) = getCurrentDateTime();
    Ok(ArcStr::from(format!(
        "{year:04}-{mon:02}-{mday:02} {hour:02}:{min:02}:{sec:02}"
    )))
}

// ───────────────────────────────── connector / cardinality flags ──────────────

macro_rules! flag_pair {
    ($set:ident, $get:ident, $field:ident) => {
        pub fn $set(v: bool) { with(|s| s.$field = v); }
        pub fn $get() -> bool { with(|s| s.$field) }
    };
}
flag_pair!(setHasExpandableConnectors,    getHasExpandableConnectors,    has_expandable);
flag_pair!(setHasOverconstrainedConnectors, getHasOverconstrainedConnectors, has_overconstrained);
flag_pair!(setPartialInstantiation,       getPartialInstantiation,       partial_instantiation);
flag_pair!(setHasStreamConnectors,        getHasStreamConnectors,        has_stream);
flag_pair!(setUsesCardinality,            getUsesCardinality,            uses_cardinality);
flag_pair!(setHasInnerOuterDefinitions,   getHasInnerOuterDefinitions,   has_inner_outer);

// ───────────────────────────────── tmpTick ────────────────────────────────────

fn tick_slot(s: &mut SysState, idx: usize) -> &mut i32 {
    if s.ticks.len() <= idx { s.ticks.resize(idx + 1, 0); }
    if s.tick_max.len() <= idx { s.tick_max.resize(idx + 1, 0); }
    &mut s.ticks[idx]
}

pub fn tmpTick() -> i32 {
    with(|s| {
        let v = *tick_slot(s, 0);
        s.ticks[0] = v + 1;
        if s.tick_max[0] < s.ticks[0] { s.tick_max[0] = s.ticks[0]; }
        v
    })
}

pub fn tmpTickReset(start: i32) {
    with(|s| {
        let _ = tick_slot(s, 0);
        s.ticks[0] = start;
        s.tick_max[0] = start;
    });
}

pub fn tmpTickIndex(index: i32) -> i32 {
    let idx = index as usize;
    with(|s| {
        let v = *tick_slot(s, idx);
        s.ticks[idx] = v + 1;
        if s.tick_max[idx] < s.ticks[idx] { s.tick_max[idx] = s.ticks[idx]; }
        v
    })
}

pub fn tmpTickIndexReserve(index: i32, reserve: i32) -> i32 {
    let idx = index as usize;
    with(|s| {
        let v = *tick_slot(s, idx);
        s.ticks[idx] = v + reserve;
        if s.tick_max[idx] < s.ticks[idx] { s.tick_max[idx] = s.ticks[idx]; }
        v
    })
}

pub fn tmpTickResetIndex(start: i32, index: i32) {
    let idx = index as usize;
    with(|s| {
        let _ = tick_slot(s, idx);
        s.ticks[idx] = start;
        if s.tick_max[idx] < start { s.tick_max[idx] = start; }
    });
}

pub fn tmpTickSetIndex(start: i32, index: i32) {
    let idx = index as usize;
    with(|s| {
        let _ = tick_slot(s, idx);
        s.ticks[idx] = start;
        if s.tick_max[idx] < start { s.tick_max[idx] = start; }
    });
}

pub fn tmpTickMaximum(index: i32) -> i32 {
    let idx = index as usize;
    with(|s| {
        let _ = tick_slot(s, idx);
        s.tick_max[idx]
    })
}

// ───────────────────────────────── user IDs ───────────────────────────────────

pub fn userIsRoot() -> bool {
    getuid() == 0
}

pub fn getuid() -> i32 {
    // POSIX `getuid()` returns a `uid_t`; on Windows the C runtime returns
    // 0 unconditionally. `libc::getuid()` is the canonical path but `libc`
    // isn't a workspace dep; on the only platform that currently builds
    // (Linux) we rely on `$UID` if set, falling back to 1000 if not. This
    // matches the runtime well enough for `userIsRoot()` checks because
    // production OMC sessions are never run as root.
    if cfg!(unix) {
        std::env::var("UID").ok().and_then(|s| s.parse::<i32>().ok()).unwrap_or(1000)
    } else {
        0
    }
}

// ───────────────────────────────── realtime stopwatches ──────────────────────

fn rt_slot_mut(s: &mut SysState, idx: i32) -> &mut RtSlot {
    s.rt.entry(idx).or_insert(RtSlot::Stopped { accumulated_ns: 0, ntick: 0 })
}

pub fn realtimeTick(clockIndex: i32) -> Result<()> {
    with(|s| {
        let slot = rt_slot_mut(s, clockIndex);
        *slot = RtSlot::Running { start: Instant::now(), accumulated_ns: 0, ntick: 0 };
    });
    Ok(())
}

pub fn realtimeTock(clockIndex: i32) -> Result<metamodelica::Real> {
    // The C runtime's `rt_tock(ix)` never fails: a clock that was never
    // started has a zeroed `tick_tp[ix]` and the call returns "now minus
    // zero" — a large, meaningless duration. Callers do tock without tick
    // (e.g. `Tpl.textFileConvertLines` reads RT_CLOCK_BUILD_MODEL purely
    // for optional perf logging), so failing here is wrong. Return the
    // slot's accumulated time instead (0.0 for a never-started clock),
    // which is harmless for the logging-only consumers and avoids the C
    // version's garbage value.
    let nanos = with(|s| -> u128 {
        let slot = rt_slot_mut(s, clockIndex);
        match slot {
            RtSlot::Running { start, ntick, .. } => {
                let elapsed = start.elapsed().as_nanos();
                *ntick += 1;
                elapsed
            }
            RtSlot::Stopped { accumulated_ns, .. } => *accumulated_ns,
        }
    });
    Ok(metamodelica::OrderedFloat(nanos as f64 / 1.0e9))
}

pub fn realtimeClear(clockIndex: i32) -> Result<()> {
    with(|s| {
        s.rt.insert(clockIndex, RtSlot::Stopped { accumulated_ns: 0, ntick: 0 });
    });
    Ok(())
}

pub fn realtimeAccumulate(clockIndex: i32) -> Result<metamodelica::Real> {
    with(|s| {
        let slot = rt_slot_mut(s, clockIndex);
        match *slot {
            RtSlot::Running { start, accumulated_ns, ntick } => {
                let new_acc = accumulated_ns + start.elapsed().as_nanos();
                *slot = RtSlot::Stopped { accumulated_ns: new_acc, ntick: ntick + 1 };
                Ok(metamodelica::OrderedFloat(new_acc as f64 / 1.0e9))
            }
            RtSlot::Stopped { accumulated_ns, .. } => {
                Ok(metamodelica::OrderedFloat(accumulated_ns as f64 / 1.0e9))
            }
        }
    })
}

pub fn realtimeAccumulated(clockIndex: i32) -> Result<metamodelica::Real> {
    with(|s| {
        let slot = rt_slot_mut(s, clockIndex);
        let nanos = match *slot {
            RtSlot::Running { start, accumulated_ns, .. } => accumulated_ns + start.elapsed().as_nanos(),
            RtSlot::Stopped { accumulated_ns, .. } => accumulated_ns,
        };
        Ok(metamodelica::OrderedFloat(nanos as f64 / 1.0e9))
    })
}

pub fn realtimeNtick(clockIndex: i32) -> Result<i32> {
    with(|s| {
        let slot = rt_slot_mut(s, clockIndex);
        Ok(match *slot {
            RtSlot::Running { ntick, .. } | RtSlot::Stopped { ntick, .. } => ntick,
        })
    })
}

// ───────────────────────────────── single-instance timer ─────────────────────

pub fn resetTimer() {
    with(|s| {
        s.timer_running = None;
        s.timer_accum = 0.0;
        s.timer_last_interval = 0.0;
        s.timer_stack = 0;
    });
}
pub fn startTimer() {
    with(|s| {
        if s.timer_running.is_none() {
            s.timer_running = Some(Instant::now());
        }
        s.timer_stack += 1;
    });
}
pub fn stopTimer() {
    with(|s| {
        if let Some(t0) = s.timer_running.take() {
            let elapsed = t0.elapsed().as_secs_f64();
            s.timer_last_interval = elapsed;
            s.timer_accum += elapsed;
        }
        s.timer_stack = (s.timer_stack - 1).max(0);
    });
}
pub fn getTimerIntervalTime() -> metamodelica::Real {
    metamodelica::OrderedFloat(with(|s| s.timer_last_interval))
}
pub fn getTimerCummulatedTime() -> metamodelica::Real {
    metamodelica::OrderedFloat(with(|s| s.timer_accum))
}
pub fn getTimerElapsedTime() -> metamodelica::Real {
    metamodelica::OrderedFloat(with(|s| {
        match s.timer_running {
            Some(t0) => s.timer_accum + t0.elapsed().as_secs_f64(),
            None => s.timer_accum,
        }
    }))
}
pub fn getTimerStackIndex() -> i32 {
    with(|s| s.timer_stack)
}

// ───────────────────────────────── UUID / path helpers ────────────────────────

pub fn getUUIDStr() -> ArcStr {
    // The C runtime uses uuid_generate(3); we synthesise a v4-shaped UUID
    // from the per-thread RNG. This is not cryptographic — but neither is
    // the use case (temp directory naming, error report IDs).
    let (a, b) = with(|s| {
        let mut step = || {
            s.rng = s.rng.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            s.rng
        };
        (step(), step())
    });
    ArcStr::from(format!(
        "{:08x}-{:04x}-4{:03x}-{:04x}-{:012x}",
        (a >> 32) as u32,
        ((a >> 16) & 0xffff) as u32,
        (a & 0x0fff) as u32,
        0x8000 | ((b >> 48) & 0x3fff) as u32,
        b & 0x0000_ffff_ffff_ffff,
    ))
}

pub fn basename(filename: ArcStr) -> ArcStr {
    Path::new(filename.as_str())
        .file_name()
        .map(|s| ArcStr::from(s.to_string_lossy().as_ref()))
        .unwrap_or_else(|| filename.clone())
}

pub fn dirname(filename: ArcStr) -> ArcStr {
    Path::new(filename.as_str())
        .parent()
        .map(|p| ArcStr::from(p.to_string_lossy().as_ref()))
        .unwrap_or_else(|| literal!(""))
}

// ───────────────────────────────── escape helpers ────────────────────────────

pub fn escapedString(unescapedString: ArcStr, unescapeNewline: bool) -> ArcStr {
    // Mirror `SystemImpl__escapedString`: convert special characters to
    // their backslash form. When `unescapeNewline` is true (sic — the
    // parameter name in the .mo is misleading), newlines are *also*
    // escaped; when false, newlines pass through verbatim.
    // Escape exactly the characters `omc__escapedString` does: the double
    // quote, the backslash, and the \a \b \f \v control characters always;
    // \r and \n only when `unescapeNewline` is set. Notably single quotes and
    // tabs are NOT escaped — escaping them (as an earlier port did) corrupts
    // round-tripped strings such as simulate()'s `method = 'dassl'`.
    let mut out = String::with_capacity(unescapedString.len());
    for c in unescapedString.chars() {
        match c {
            '"'  => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\x07' => out.push_str("\\a"),
            '\x08' => out.push_str("\\b"),
            '\x0c' => out.push_str("\\f"),
            '\x0b' => out.push_str("\\v"),
            '\r' if unescapeNewline => out.push_str("\\r"),
            '\n' if unescapeNewline => out.push_str("\\n"),
            c => out.push(c),
        }
    }
    ArcStr::from(out)
}

pub fn unescapedString(escapedString: ArcStr) -> ArcStr {
    let mut out = String::with_capacity(escapedString.len());
    let mut chars = escapedString.chars();
    while let Some(c) = chars.next() {
        if c != '\\' { out.push(c); continue; }
        match chars.next() {
            Some('n') => out.push('\n'),
            Some('t') => out.push('\t'),
            Some('r') => out.push('\r'),
            Some('a') => out.push('\x07'),
            Some('b') => out.push('\x08'),
            Some('f') => out.push('\x0c'),
            Some('v') => out.push('\x0b'),
            Some('\\') => out.push('\\'),
            Some('"') => out.push('"'),
            Some('\'') => out.push('\''),
            Some('?') => out.push('?'),
            Some('0') => out.push('\0'),
            Some(other) => { out.push('\\'); out.push(other); }
            None => out.push('\\'),
        }
    }
    ArcStr::from(out)
}

pub fn unescapedStringLength(unescapedString: ArcStr) -> i32 {
    // Length the string would have *after* unescape pre-applied. The C
    // runtime decrements one byte per recognised escape sequence; do the
    // same by walking once.
    let mut len: i32 = 0;
    let mut chars = unescapedString.chars();
    while let Some(c) = chars.next() {
        if c != '\\' { len += 1; continue; }
        if chars.next().is_some() { len += 1; } else { len += 1; }
    }
    len
}

pub fn unquoteIdentifier(r#str: ArcStr) -> ArcStr {
    // `SystemImpl__unquoteIdentifier`: identifiers that are not valid C
    // identifiers — Modelica's `'...'` quoted form, or names containing `$`
    // (compiler-generated temporaries like `$tmpVar1`; the generated code is
    // compiled with `-fno-dollars-in-identifiers`) — are mapped to the
    // canonical, reversible `_omcQ` form: alphanumerics kept, every other
    // byte encoded as `_` plus two uppercase hex digits (e.g. `$` → `_24`).
    let s = r#str.as_str();
    if !(s.starts_with('\'') || s.contains('$')) {
        return r#str;
    }
    let mut out = String::with_capacity(s.len() + 8);
    out.push_str("_omcQ");
    for b in s.bytes() {
        if b.is_ascii_alphanumeric() {
            out.push(b as char);
        } else {
            out.push('_');
            out.push_str(&format!("{b:02X}"));
        }
    }
    ArcStr::from(out)
}

// ───────────────────────────────── numeric limits ─────────────────────────────

pub fn intMaxLit() -> i32 {
    // MetaModelica `Integer` lowers to Rust `i32`, so the maximum literal
    // is `i32::MAX`. (The original C runtime returns LONG_MAX cast to int.)
    i32::MAX
}

pub fn realMaxLit() -> metamodelica::Real {
    // Mirrors the C runtime (`meta_modelica_builtin.c`): `DBL_MAX / 2048`, kept
    // below DBL_MAX so a solver adding a small eps to this value can't overflow.
    metamodelica::OrderedFloat(f64::MAX / 2048.0)
}

// ───────────────────────────────── URI / platform info ───────────────────────

/// Percent-decode a URI component, mirroring `decodeUri2` in
/// systemimpl.c: `+` becomes a space, `%XX` a hex-decoded byte, and a
/// malformed escape is kept literally.
fn decode_uri_component(src: &str) -> String {
    let bytes = src.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        match bytes[i] {
            b'+' => out.push(b' '),
            b'%' if i + 2 < bytes.len()
                && bytes[i + 1].is_ascii_hexdigit()
                && bytes[i + 2].is_ascii_hexdigit() =>
            {
                let hex = std::str::from_utf8(&bytes[i + 1..i + 3]).unwrap();
                out.push(u8::from_str_radix(hex, 16).unwrap());
                i += 2;
            }
            b => out.push(b),
        }
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

/// `c_add_message(NULL, -1, ErrorType_scripting, ErrorLevel_error, ...)`
/// equivalent for the URI errors below.
fn add_scripting_error(template: &str, token: &str) {
    let _ = crate::Error::addMessage(
        openmodelica_error::ErrorTypes::Message {
            id: -1,
            ty: openmodelica_error::ErrorTypes::MessageType::SCRIPTING,
            severity: openmodelica_error::ErrorTypes::Severity::ERROR,
            message: ArcStr::from(template),
        },
        metamodelica::cons(ArcStr::from(token), metamodelica::nil()),
    );
}

/// Split `modelica://Pkg.Sub/dir/file` / `file:///some/path` URIs into
/// `(scheme, classname, pathname)`. Port of
/// `SystemImpl__uriToClassAndPath`; sets the error buffer and fails on
/// malformed or unknown URIs like the C version (which MMC_THROWs).
pub fn uriToClassAndPath(uri: ArcStr) -> Result<(ArcStr, ArcStr, ArcStr)> {
    fn split_name_path(rest: &str) -> (String, String) {
        match rest.find('/') {
            Some(p) => (decode_uri_component(&rest[..p]), decode_uri_component(&rest[p..])),
            None => (decode_uri_component(rest), String::new()),
        }
    }
    let lower = uri.to_ascii_lowercase();
    if let Some(rest) = lower.strip_prefix("modelica://").map(|r| &uri[uri.len() - r.len()..]) {
        let (name, path) = split_name_path(rest);
        if name.is_empty() {
            add_scripting_error("Modelica URI lacks classname: %s", &uri);
            bail!("Modelica URI lacks classname: {uri}");
        }
        return Ok((literal!("modelica://"), ArcStr::from(name), ArcStr::from(path)));
    }
    if let Some(rest) = lower.strip_prefix("file://").map(|r| &uri[uri.len() - r.len()..]) {
        let (name, path) = split_name_path(rest);
        if path.is_empty() {
            add_scripting_error("File URI has no path: %s", &uri);
            bail!("File URI has no path: {uri}");
        }
        if !name.is_empty() {
            add_scripting_error("File URI using hostnames is not supported: %s", &uri);
            bail!("File URI using hostnames is not supported: {uri}");
        }
        return Ok((literal!("file://"), literal!(""), ArcStr::from(path)));
    }
    add_scripting_error("Unknown uri: %s", &uri);
    bail!("Unknown uri: {uri}")
}

pub fn modelicaPlatform() -> ArcStr {
    // Standardised platform name per the Modelica spec
    // (linux32 / linux64 / win32 / win64 / darwin64).
    let s = match (Autoconf::os, Autoconf::is64Bit) {
        ("linux",  true)  => "linux64",
        ("linux",  false) => "linux32",
        ("Windows_NT", true)  => "win64",
        ("Windows_NT", false) => "win32",
        ("OSX", _)  => "darwin64",
        _ => Autoconf::os,
    };
    ArcStr::from(s)
}

pub fn openModelicaPlatform() -> ArcStr {
    // OMC's preferred platform identifier — same as modelicaPlatform for
    // now since we have no separate notion.
    modelicaPlatform()
}

pub fn openModelicaPlatformAlternative() -> ArcStr {
    literal!("")
}

pub fn gccDumpMachine() -> ArcStr {
    // Output of `<CC> -dumpmachine`. Requires invoking the compiler;
    // defer until a code path actually consumes it.
    todo!("System.gccDumpMachine: needs to shell out to the configured CC")
}

pub fn gccVersion() -> ArcStr {
    todo!("System.gccVersion: needs to shell out to the configured CC")
}

// ───────────────────────────────── LAPACK / iconv / printf ───────────────────

pub fn dgesv(
    A: Arc<List<Arc<List<metamodelica::Real>>>>,
    B: Arc<List<metamodelica::Real>>,
) -> Result<(Arc<List<metamodelica::Real>>, i32)> {
    // Port of SystemImpl__dgesv (systemimpl.c), which calls LAPACK `dgesv` to
    // solve the dense linear system A*X = B for a single right-hand side.
    // LAPACK's dgesv is an LU factorization with partial pivoting (dgetrf)
    // followed by a triangular solve (dgetrs); we replicate that algorithm in
    // pure Rust so no BLAS/LAPACK link is required. `info` matches LAPACK:
    //   0  : success
    //   <0 : the -info-th argument was illegal (here: a non-square A)
    //   >0 : U(info,info) is exactly zero — A is singular (1-based index)
    let a_rows: Vec<Vec<f64>> = A
        .as_ref()
        .into_iter()
        .map(|row| row.as_ref().into_iter().map(|v| v.into_inner()).collect::<Vec<f64>>())
        .collect();
    let mut b: Vec<f64> = B.as_ref().into_iter().map(|v| v.into_inner()).collect();
    let n = a_rows.len();

    // Argument validity: A must be square (n x n) and B must have length n,
    // mirroring the dimensions the C wrapper passes to LAPACK.
    if b.len() != n || a_rows.iter().any(|r| r.len() != n) {
        return Ok((B.clone(), -1));
    }
    if n == 0 {
        return Ok((Arc::new(List::Nil), 0));
    }

    // Working copy of the matrix: a[i][j] = row i, column j (as in the C code,
    // where A[j*sz+i] holds element (i,j)).
    let mut a = a_rows;

    // LU factorization with partial pivoting, applying the row swaps to `b` as
    // we go (equivalent to LAPACK forming the permutation in `ipiv` and then
    // applying it in dgetrs).
    for k in 0..n {
        // Pivot: row of largest magnitude in column k at or below the diagonal.
        let mut p = k;
        let mut maxv = a[k][k].abs();
        for i in (k + 1)..n {
            let v = a[i][k].abs();
            if v > maxv {
                maxv = v;
                p = i;
            }
        }
        if a[p][k] == 0.0 {
            // U(k,k) == 0: singular. LAPACK records the first such index and
            // completes the factorization; the solve below would divide by
            // zero, so stop and report (callers check `info != 0`).
            return Ok((B.clone(), (k + 1) as i32));
        }
        if p != k {
            a.swap(p, k);
            b.swap(p, k);
        }
        let akk = a[k][k];
        for i in (k + 1)..n {
            let f = a[i][k] / akk;
            a[i][k] = f;
            for j in (k + 1)..n {
                let akj = a[k][j];
                a[i][j] -= f * akj;
            }
            b[i] -= f * b[k];
        }
    }

    // Back substitution into `b` (now holding the forward-solved RHS).
    let mut x = vec![0.0f64; n];
    for k in (0..n).rev() {
        let mut s = b[k];
        for j in (k + 1)..n {
            s -= a[k][j] * x[j];
        }
        x[k] = s / a[k][k];
    }

    let out = List::from_iter(x.into_iter().map(metamodelica::OrderedFloat));
    Ok((Arc::new(out), 0))
}

pub fn reopenStandardStream(_stream: i32, _filename: ArcStr) -> bool {
    todo!("System.reopenStandardStream: freopen(stdin/stdout/stderr) not yet ported")
}

pub fn iconv(string: ArcStr, from: ArcStr, to: ArcStr) -> ArcStr {
    // Port of `SystemImpl__iconv` (systemimpl.c): reinterpret the bytes of
    // `string` as being encoded in `from` and convert them to `to`.
    //
    // In the C runtime MetaModelica strings are raw byte arrays, so iconv can
    // both consume and produce arbitrary (non-UTF-8) byte sequences. In this
    // port strings are `ArcStr`, i.e. always valid UTF-8, which has two
    // consequences:
    //   * the input bytes we hand to the decoder are exactly this string's
    //     UTF-8 bytes, and
    //   * the only `to` whose output is representable as an `ArcStr` is one
    //     whose byte stream is itself valid UTF-8 (UTF-8 proper, or an
    //     ASCII-only result of some other charset).
    // This matches real usage: the only non-trivial caller is
    // `loadString`/`loadFile`, which always converts *to* "UTF-8".
    //
    // On any failure the C function returns "" after emitting a scripting
    // error via `c_add_message`; we mirror both behaviours.
    use encoding_rs::{Encoding, UTF_8};

    // WHATWG label lookup. Case-insensitive and alias-aware ("utf8",
    // "iso-8859-1", "latin1", …), mirroring iconv_open's tolerant name
    // matching. An unknown charset is the iconv_open == (iconv_t)-1 case.
    let Some(from_enc) = Encoding::for_label(from.as_bytes()) else {
        return iconv_failed(&string, &from, &to, "unknown source character set");
    };
    let Some(to_enc) = Encoding::for_label(to.as_bytes()) else {
        return iconv_failed(&string, &from, &to, "unknown target character set");
    };

    // UTF-8 → UTF-8: the C code validates the input and returns it unchanged.
    // An `ArcStr` is already valid UTF-8, so this is unconditionally a no-op.
    if from_enc == UTF_8 && to_enc == UTF_8 {
        return string;
    }

    // Decode the input bytes from `from` into Unicode. `iconv` without
    // `//IGNORE` fails on malformed input; `decode_without_bom_handling`
    // reports that via `had_errors` (and, like iconv, performs no BOM sniffing
    // that would override the requested `from`).
    let (decoded, had_errors) = from_enc.decode_without_bom_handling(string.as_bytes());
    if had_errors {
        return iconv_failed(&string, &from, &to, "invalid input sequence");
    }

    if to_enc == UTF_8 {
        return ArcStr::from(decoded.as_ref());
    }

    // Encode Unicode into the target charset. Unmappable characters make iconv
    // fail rather than substitute; `encode` flags them via `had_unmappable`.
    let (encoded, _enc, had_unmappable) = to_enc.encode(&decoded);
    if had_unmappable {
        return iconv_failed(&string, &from, &to, "character not representable in target set");
    }
    // The target bytes must be valid UTF-8 to live in an `ArcStr`. Most
    // non-UTF-8 charsets emit high bytes for non-ASCII input, so such a result
    // is not representable in this all-UTF-8 port. C would hand back those raw
    // bytes in a byte-array `modelica_string`; we cannot, so we fail rather
    // than corrupt the string.
    match std::str::from_utf8(&encoded) {
        Ok(s) => ArcStr::from(s),
        Err(_) => iconv_failed(&string, &from, &to, "result is not representable as UTF-8"),
    }
}

/// Emit the scripting diagnostic for a failed `iconv` conversion and return the
/// empty string, exactly as `SystemImpl__iconv` does on every failure path.
///
/// The shape mirrors the C message `iconv("%s",from="%s",to="%s") failed: %s`;
/// the first token is the input rendered through `iconv_ascii_fallback` (a
/// best-effort ASCII view, like C's `SystemImpl__iconv__ascii`) so the user
/// gets a hint of the offending content without us echoing raw bytes.
fn iconv_failed(string: &str, from: &str, to: &str, reason: &str) -> ArcStr {
    let msg = openmodelica_error::ErrorTypes::Message {
        id: -1,
        ty: openmodelica_error::ErrorTypes::MessageType::SCRIPTING,
        severity: openmodelica_error::ErrorTypes::Severity::ERROR,
        message: literal!("iconv(\"%s\",from=\"%s\",to=\"%s\") failed: %s"),
    };
    let tokens = metamodelica::list![
        iconv_ascii_fallback(string),
        ArcStr::from(from),
        ArcStr::from(to),
        ArcStr::from(reason),
    ];
    // `addMessage` only returns `Err` if the error machinery itself fails;
    // there is nothing useful to do with that here (and `iconv` is infallible),
    // so it is dropped — the C runtime likewise cannot surface such a failure.
    let _ = crate::Error::addMessage(msg, tokens);
    literal!("")
}

/// Port of `SystemImpl__iconv__ascii`: every byte with the high bit set becomes
/// `'?'`, the rest pass through. Used only to render a readable hint of the
/// failing input in the diagnostic above.
fn iconv_ascii_fallback(string: &str) -> ArcStr {
    let mut out = String::with_capacity(string.len());
    for &b in string.as_bytes() {
        out.push(if b & 0x80 != 0 { '?' } else { b as char });
    }
    ArcStr::from(out)
}

pub fn snprintff(format: ArcStr, maxlen: i32, val: metamodelica::Real) -> Result<ArcStr> {
    // `snprintff(fmt, n, x)` is a thin wrapper around C's snprintf for
    // floating-point values — used by the dumper to emit Modelica-formatted
    // doubles. Rust's std doesn't expose printf-style format-string parsing,
    // so for now we honour the `%.{prec}{spec}` shape most callers use,
    // and fall back to `{:?}` for anything else. The C runtime truncates
    // to maxlen-1 bytes; we mirror that.
    let formatted = c_format_double(format.as_str(), val.into_inner())
        .with_context(|| format!("System.snprintff: unsupported format {format}"))?;
    let cap = (maxlen.max(0) as usize).saturating_sub(1);
    let truncated: String = formatted.chars().take(cap).collect();
    Ok(ArcStr::from(truncated))
}

pub fn sprintff(format: ArcStr, val: metamodelica::Real) -> Result<ArcStr> {
    let s = c_format_double(format.as_str(), val.into_inner())
        .with_context(|| format!("System.sprintff: unsupported format {format}"))?;
    Ok(ArcStr::from(s))
}

/// Formats `val` like C's `%e`/`%E`: a mantissa followed by `e`/`E`, an explicit
/// sign and an at-least-two-digit exponent (Rust's `{:e}` omits the sign and
/// zero-padding, e.g. `1.5e2` rather than `1.500000e+02`).
fn format_c_exp(val: f64, precision: usize, upper: bool) -> String {
    let raw = format!("{:.*e}", precision, val);
    let (mant, exp) = raw.split_once('e').unwrap_or((raw.as_str(), "0"));
    let exp_num: i32 = exp.parse().unwrap_or(0);
    let e_char = if upper { 'E' } else { 'e' };
    let sign = if exp_num < 0 { '-' } else { '+' };
    format!("{mant}{e_char}{sign}{:02}", exp_num.abs())
}

/// Returns the decimal exponent X that C's `%e` conversion of `val` would use
/// when rendered with `sig` significant digits (so rounding can carry into a
/// higher exponent, e.g. 9.99 at 2 sig digits -> "1.0e1", X = 1).
fn decimal_exponent(val: f64, sig: usize) -> i32 {
    if val == 0.0 || !val.is_finite() {
        return 0;
    }
    let raw = format!("{:.*e}", sig.saturating_sub(1), val);
    raw.split_once('e')
        .and_then(|(_, e)| e.parse().ok())
        .unwrap_or(0)
}

/// Strips trailing zeros (and a trailing decimal point) from the significand of
/// a `%g` result, leaving any exponent suffix untouched. Mirrors the trailing-
/// zero removal C performs unless the `#` flag is given.
fn trim_g_significand(s: String) -> String {
    let (mant, exp) = match s.find(['e', 'E']) {
        Some(idx) => (&s[..idx], &s[idx..]),
        None => (s.as_str(), ""),
    };
    let mant = if mant.contains('.') {
        mant.trim_end_matches('0').trim_end_matches('.')
    } else {
        mant
    };
    format!("{mant}{exp}")
}

/// Best-effort port of C `snprintf` for a single floating-point conversion.
/// Recognises `%[flags][width][.prec][fFeEgG]`. Returns `None` for shapes
/// we don't (yet) understand so callers can decide how loudly to fail.
fn c_format_double(fmt: &str, val: f64) -> Option<String> {
    let bytes = fmt.as_bytes();
    let pct = bytes.iter().position(|b| *b == b'%')?;
    let prefix = &fmt[..pct];
    // Walk flags, width, precision, conversion.
    let mut i = pct + 1;
    let mut flags = String::new();
    while i < bytes.len() && matches!(bytes[i], b'-' | b'+' | b' ' | b'#' | b'0') {
        flags.push(bytes[i] as char);
        i += 1;
    }
    let mut width = String::new();
    while i < bytes.len() && bytes[i].is_ascii_digit() {
        width.push(bytes[i] as char);
        i += 1;
    }
    let mut precision: Option<usize> = None;
    if i < bytes.len() && bytes[i] == b'.' {
        i += 1;
        let mut p = String::new();
        while i < bytes.len() && bytes[i].is_ascii_digit() {
            p.push(bytes[i] as char);
            i += 1;
        }
        precision = Some(p.parse().unwrap_or(0));
    }
    if i >= bytes.len() { return None; }
    let spec = bytes[i] as char;
    let suffix = &fmt[i + 1..];

    let body = match spec {
        'f' | 'F' => match precision {
            Some(p) => format!("{:.*}", p, val),
            None => format!("{:.6}", val),
        },
        'e' => format_c_exp(val, precision.unwrap_or(6), false),
        'E' => format_c_exp(val, precision.unwrap_or(6), true),
        'g' | 'G' => {
            // C's %g treats `precision` as the number of *significant digits*
            // (default 6, a value of 0 is taken as 1). The %e-style exponent X
            // of the value selects the presentation: %f when -4 <= X < P,
            // otherwise %e. Unless the '#' flag is set, trailing zeros (and a
            // dangling decimal point) are stripped from the significand.
            let upper = spec == 'G';
            let mut p = precision.unwrap_or(6);
            if p == 0 { p = 1; }
            let x = decimal_exponent(val, p);
            let mut s = if x >= -4 && (x as i64) < p as i64 {
                let prec = (p as i32 - 1 - x).max(0) as usize;
                format!("{:.*}", prec, val)
            } else {
                format_c_exp(val, p - 1, upper)
            };
            if !flags.contains('#') {
                s = trim_g_significand(s);
            }
            s
        }
        _ => return None,
    };

    let pad_to: Option<usize> = width.parse().ok();
    let padded = match pad_to {
        Some(w) if body.len() < w => {
            let fill = w - body.len();
            let pad: String = if flags.contains('0') { "0".repeat(fill) } else { " ".repeat(fill) };
            if flags.contains('-') { format!("{body}{pad}") } else { format!("{pad}{body}") }
        }
        _ => body,
    };
    Some(format!("{prefix}{padded}{suffix}"))
}

// ───────────────────────────────── randomness ─────────────────────────────────

fn next_rand(s: &mut SysState) -> u64 {
    s.rng = s.rng.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
    s.rng
}

pub fn realRand() -> metamodelica::Real {
    let r = with(next_rand);
    // 53-bit mantissa worth of randomness so the result is uniform in [0,1).
    let v = (r >> 11) as f64 / ((1u64 << 53) as f64);
    metamodelica::OrderedFloat(v)
}

pub fn intRand(n: i32) -> i32 {
    if n <= 0 { return 0; }
    let r = with(next_rand);
    (r % n as u64) as i32
}

pub fn intRandom(n: i32) -> i32 {
    // `intRandom` differs from `intRand` only in the upper bound being
    // inclusive in the .mo doc (`Integer in {0,...,n-1}` is what callers
    // expect — same semantics).
    intRand(n)
}

pub fn anyStringCode<Any: Clone + 'static>(_any: Any) -> ArcStr {
    // Pretty-prints any MetaModelica runtime value (`mmc_anyString`).
    // Useful for debug dumps; defer until a caller needs it.
    todo!("System.anyStringCode: generic runtime-value printer not yet ported")
}

pub fn numBits() -> i32 {
    if Autoconf::is64Bit { 64 } else { 32 }
}

pub fn realpath(path: ArcStr) -> Result<ArcStr> {
    // No filesystem on wasm to canonicalize against (and no symlinks to
    // resolve); collapse `.`/`..` lexically and return the path as-is.
    #[cfg(target_arch = "wasm32")]
    return Ok(ArcStr::from(lexical_normalize(path.as_str())));
    #[cfg(not(target_arch = "wasm32"))]
    {
        let canon = fs::canonicalize(path.as_str())
            .with_context(|| format!("System.realpath: cannot resolve {path}"))?;
        Ok(ArcStr::from(canon.to_string_lossy().as_ref()))
    }
}

/// Collapse `.` and `..` components in a forward-slash path without touching a
/// filesystem (wasm has none). Used by [`realpath`] on wasm so the builtin paths
/// FBuiltin builds (`<home>/bin/../lib/omc/…`) reduce to a stable canonical form.
#[cfg(target_arch = "wasm32")]
fn lexical_normalize(path: &str) -> String {
    let absolute = path.starts_with('/');
    let mut out: Vec<&str> = Vec::new();
    for comp in path.split('/') {
        match comp {
            "" | "." => {}
            ".." => {
                if matches!(out.last(), Some(&c) if c != "..") {
                    out.pop();
                } else if !absolute {
                    out.push("..");
                }
            }
            c => out.push(c),
        }
    }
    let joined = out.join("/");
    if absolute { format!("/{joined}") } else { joined }
}

pub fn getSimulationHelpText(_detailed: bool, _sphinx: bool) -> ArcStr {
    // Simulation-runtime CLI help; the C version asks the runtime for its
    // option list. None of the Rust-side callers consume it yet.
    todo!("System.getSimulationHelpText: simulation runtime help text not yet ported")
}

pub fn getTerminalWidth() -> i32 {
    // The C runtime probes `TIOCGWINSZ`; without an `ioctl` binding we
    // fall back to the COLUMNS env var, then 80.
    std::env::var("COLUMNS").ok().and_then(|s| s.parse::<i32>().ok()).unwrap_or(80)
}

pub fn fileIsNewerThan(file1: ArcStr, file2: ArcStr) -> Result<bool> {
    // The VFS has no timestamps to compare; conservatively treat `file1` as
    // newer (so freshness-gated work re-runs) when it exists.
    #[cfg(target_arch = "wasm32")]
    {
        let _ = &file2;
        return Ok(openmodelica_vfs::exists(file1.as_str()));
    }
    #[cfg(not(target_arch = "wasm32"))]
    {
        let m1 = fs::metadata(file1.as_str()).with_context(|| format!("stat {file1}"))?;
        let m2 = fs::metadata(file2.as_str()).with_context(|| format!("stat {file2}"))?;
        Ok(m1.modified()? > m2.modified()?)
    }
}

pub fn fileContentsEqual(file1: ArcStr, file2: ArcStr) -> bool {
    #[cfg(target_arch = "wasm32")]
    return match (openmodelica_vfs::read(file1.as_str()), openmodelica_vfs::read(file2.as_str())) {
        (Some(a), Some(b)) => a == b,
        _ => false,
    };
    #[cfg(not(target_arch = "wasm32"))]
    match (fs::read(file1.as_str()), fs::read(file2.as_str())) {
        (Ok(a), Ok(b)) => a == b,
        _ => false,
    }
}

pub fn rename(source: ArcStr, dest: ArcStr) -> bool {
    #[cfg(target_arch = "wasm32")]
    {
        match openmodelica_vfs::read(source.as_str()) {
            Some(bytes) => {
                openmodelica_vfs::write(dest.as_str(), bytes);
                openmodelica_vfs::remove(source.as_str());
                true
            }
            None => false,
        }
    }
    #[cfg(not(target_arch = "wasm32"))]
    fs::rename(source.as_str(), dest.as_str()).is_ok()
}

pub fn numProcessors() -> i32 {
    std::thread::available_parallelism().map(|n| n.get() as i32).unwrap_or(1)
}

pub fn launchParallelTasks<AnyInput: Clone + 'static, AnyOutput: Clone + 'static>(
    _numThreads: i32,
    inData: Arc<List<AnyInput>>,
    func: Arc<dyn Fn(AnyInput) -> Result<AnyOutput> + 'static>,
) -> Result<Arc<List<AnyOutput>>> {
    // The C runtime (System_omc.c) spawns `numThreads` worker pthreads pulling
    // tasks off a shared queue, but collects the results back in INPUT ORDER
    // (`commands[i] = fn(task[i])`) and itself falls back to a plain serial map
    // (`System_launchParallelTasksSerial`) whenever `numThreads == 1` or there
    // is a single task. Parallelism is therefore a throughput optimisation, not
    // a semantic requirement.
    //
    // We run the serial map unconditionally: the MetaModelica payloads carried
    // here (e.g. a `SymbolTable` with `Rc<RefCell<…>>` fields and `Arc<dyn Fn>`
    // callbacks) are deliberately NOT `Send`, so spawning OS threads is not
    // possible without a representational change. The `Send` bounds the C-port
    // stub previously carried were premature and only blocked call sites; drop
    // them. A failing task aborts the whole run, mirroring the C version's
    // `MMC_THROW` on a worker failure (here: the first `Err` short-circuits the
    // `collect`).
    let results: Result<Vec<AnyOutput>> =
        (&*inData).into_iter().map(|x| func(x.clone())).collect();
    Ok(Arc::new(results?.into_iter().collect::<List<AnyOutput>>()))
}

pub fn exit(status: i32) -> Result<()> {
    std::process::exit(status);
}

pub fn threadWorkFailed() {
    // The C version calls `pthread_exit(EXIT_FAILURE)`. With no thread
    // pool to bail out of, the closest equivalent is a panic — but the
    // .mo callers always wrap this in a guarded try, so the panic will
    // be observed as a failed task by the orchestrator once
    // `launchParallelTasks` is implemented.
    panic!("System.threadWorkFailed: worker thread aborted by user code");
}

pub fn getMemorySize() -> metamodelica::Real {
    // Total system memory in bytes. The C runtime reads `_SC_PHYS_PAGES *
    // _SC_PAGE_SIZE` on POSIX; we don't have a portable shortcut in std.
    todo!("System.getMemorySize: physical memory probe not yet ported")
}

pub fn initGarbageCollector() {
    // Boehm GC initialisation — irrelevant in the Rust port; ownership
    // covers everything the GC used to.
}

pub fn ctime(t: metamodelica::Real) -> ArcStr {
    // POSIX ctime(3) returns "Day Mon DD HH:MM:SS YYYY\n"; we approximate
    // with the same layout sans the trailing newline so callers that
    // splice it into messages don't get a stray line break.
    let secs = t.into_inner() as i64;
    let (year, mon, mday, hour, min, sec) = epoch_to_civil(secs);
    let mon_name = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        .get(mon as usize - 1).copied().unwrap_or("???");
    // Day-of-week via Zeller's congruence (Gregorian, 0=Saturday).
    let (q, m, y) = if mon < 3 { (mday, mon + 12, year - 1) } else { (mday, mon, year) };
    let k = y % 100;
    let j = y / 100;
    let h = (q + (13 * (m + 1)) / 5 + k + k / 4 + j / 4 + 5 * j).rem_euclid(7);
    let dow = ["Sat","Sun","Mon","Tue","Wed","Thu","Fri"][h as usize];
    ArcStr::from(format!(
        "{dow} {mon_name} {mday:2} {hour:02}:{min:02}:{sec:02} {year:04}"
    ))
}

// ───────────────────────────────── stat ──────────────────────────────────────

#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
#[repr(i32)]
pub enum StatFileType {
    NoFile = 1,
    RegularFile = 2,
    Directory = 3,
    SpecialFile = 4,
}
impl PartialOrd for StatFileType {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> { Some(self.cmp(other)) }
}
impl Ord for StatFileType {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering { (*self as i32).cmp(&(*other as i32)) }
}

pub fn stat(filename: ArcStr) -> (bool, metamodelica::Real, metamodelica::Real, StatFileType) {
    #[cfg(target_arch = "wasm32")]
    {
        let f = filename.as_str();
        if let Some(bytes) = openmodelica_vfs::read(f) {
            return (true, metamodelica::OrderedFloat(bytes.len() as f64),
                    metamodelica::OrderedFloat(0.0), StatFileType::RegularFile);
        }
        if openmodelica_vfs::is_dir(f) {
            return (true, metamodelica::OrderedFloat(0.0),
                    metamodelica::OrderedFloat(0.0), StatFileType::Directory);
        }
        return (false, metamodelica::OrderedFloat(0.0), metamodelica::OrderedFloat(0.0), StatFileType::NoFile);
    }
    #[cfg(not(target_arch = "wasm32"))]
    match fs::metadata(filename.as_str()) {
        Ok(m) => {
            let size = m.len() as f64;
            let mtime = m.modified().ok()
                .and_then(|t| t.duration_since(std::time::UNIX_EPOCH).ok())
                .map(|d| d.as_secs_f64())
                .unwrap_or(0.0);
            let kind = if m.is_file() {
                StatFileType::RegularFile
            } else if m.is_dir() {
                StatFileType::Directory
            } else {
                StatFileType::SpecialFile
            };
            (true, metamodelica::OrderedFloat(size), metamodelica::OrderedFloat(mtime), kind)
        }
        Err(_) => (false, metamodelica::OrderedFloat(0.0), metamodelica::OrderedFloat(0.0), StatFileType::NoFile),
    }
}

/// Mirrors `SystemImpl__alarm`: schedule a SIGALRM `seconds` from now and, on
/// the first call, install a handler that broadcasts SIGALRM to the whole
/// process group (so child processes die too) and then restores the default
/// disposition. Used by `--alarm=N` to force-terminate omc after a timeout.
/// Returns the number of seconds remaining on the previously scheduled alarm.
#[cfg(unix)]
pub fn alarm(seconds: i32) -> i32 {
    use std::sync::atomic::{AtomicBool, Ordering};
    static HANDLER_INSTALLED: AtomicBool = AtomicBool::new(false);

    extern "C" fn alarm_handler(signo: core::ffi::c_int) {
        unsafe {
            // Forward the alarm to every process in our group, then reset
            // SIGALRM to its default action so the signal terminates us.
            libc::kill(-libc::getpid(), signo);
            libc::signal(libc::SIGALRM, libc::SIG_DFL);
        }
    }

    unsafe {
        if HANDLER_INSTALLED
            .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
            .is_ok()
        {
            libc::signal(libc::SIGALRM, alarm_handler as *const () as libc::sighandler_t);
        }
        libc::alarm(seconds as core::ffi::c_uint) as i32
    }
}

#[cfg(not(unix))]
pub fn alarm(_seconds: i32) -> i32 {
    // The Windows runtime uses the C library's `alarm` directly without a
    // custom SIGALRM disposition; no MSVC target is built here yet.
    todo!("System.alarm: non-unix SIGALRM scheduling not yet ported")
}

pub fn covertTextFileToCLiteral(_textFile: ArcStr, _outFile: ArcStr, _target: ArcStr) -> bool {
    // Reads a text file and writes a C-source file containing the text
    // as a string literal. The C runtime handles escaping platform-by-
    // platform; defer until a Susan template needs it.
    todo!("System.covertTextFileToCLiteral: text-to-C-literal converter not yet ported")
}

pub fn dladdr<T: Clone + 'static>(_symbol: T) -> (ArcStr, ArcStr, ArcStr) {
    // C: dladdr(3) on the MM closure's entry pointer, used purely as
    // best-effort diagnostics for Error.TEMPLATE_ERROR_FUNC ("Template
    // error: <file>: <symbol>"); platforms without dladdr return dummy
    // strings ("dladdr failed"). A Rust `Arc<dyn Fn>` value carries no
    // resolvable exported symbol, so this port always takes the
    // dummy-string path. The callback's static type name is the best
    // information available without symbolication machinery.
    let file: ArcStr = literal!("dladdr failed");
    let name: ArcStr = ArcStr::from(std::any::type_name::<T>());
    let info: ArcStr = arcstr::format!("{file}: {name}");
    (info, file, name)
}

// ───────────────────────────────── StringAllocator ───────────────────────────

/// External object `StringAllocator` from `System.mo`: a fixed-size string
/// buffer that callers fill piecewise with [`stringAllocatorStringCopy`] and
/// finally reinterpret as a `String` with [`stringAllocatorResult`] (see
/// `StringUtil.repeat`, `AbsynUtil.pathStringWork`,
/// `Initialization.warnAboutVars2Work`).
///
/// The C runtime backs it with an unboxed `mmc_alloc_scon(sz)` string that is
/// mutated in place; we use a shared zero-initialised byte buffer, which is
/// deterministic where the C version would expose uninitialised bytes if a
/// caller left gaps. The handle is `Clone` and shared, matching external-
/// object reference semantics, and the `Mutex` keeps it thread-safe — these
/// are cold-path string builders, never a hot loop.
#[derive(Clone, Debug)]
pub struct StringAllocator {
    buf: Arc<std::sync::Mutex<Vec<u8>>>,
}

impl StringAllocator {
    pub fn new(sz: i32) -> Result<StringAllocator> {
        // `StringAllocator_constructor` throws (MMC_THROW) on a negative size.
        if sz < 0 {
            bail!("StringAllocator: negative size {sz}");
        }
        Ok(StringAllocator {
            buf: Arc::new(std::sync::Mutex::new(vec![0u8; sz as usize])),
        })
    }
}
pub fn StringAllocator(sz: i32) -> Result<StringAllocator> {
    StringAllocator::new(sz)
}

pub fn destructor(_str: StringAllocator) {}

pub fn stringAllocatorStringCopy(dest: StringAllocator, source: ArcStr, destOffset: i32) {
    // `om_stringAllocatorStringCopy` is a raw `strcpy` into the buffer at the
    // given byte offset. Two deliberate differences from the C helper:
    //
    //  - C's `strcpy` also writes the trailing NUL. In forward fills the next
    //    segment (or the allocation's extra terminator byte) overwrites it,
    //    but in the reverse-order fills of `AbsynUtil.pathStringWork`
    //    (reverse=true) that NUL lands on the first byte of the segment
    //    written in the previous iteration and corrupts it. We copy exactly
    //    the source bytes instead of reproducing that.
    //
    //  - The C side documents that bad offsets simply write out of bounds.
    //    We panic with the offending values: every call site computes exact
    //    offsets from `stringLength`, so a violation is a compiler bug.
    let bytes = source.as_bytes();
    if bytes.is_empty() {
        return; // C: `if (*source)` guard.
    }
    let mut buf = dest.buf.lock().unwrap();
    let len = buf.len();
    usize::try_from(destOffset)
        .ok()
        .and_then(|off| buf.get_mut(off..off + bytes.len()))
        .unwrap_or_else(|| {
            panic!(
                "System.stringAllocatorStringCopy: copy of {} bytes at offset {destOffset} \
                 does not fit in a StringAllocator of size {len}",
                bytes.len()
            )
        })
        .copy_from_slice(bytes);
}

pub fn stringAllocatorResult<T: Clone + 'static>(sa: StringAllocator, _dummy: T) -> T {
    // `om_stringAllocatorResult` returns the buffer reinterpreted as the
    // result type. The MetaModelica declaration is generic only so the caller
    // can pass its `output String` as a dummy and avoid an extra allocation;
    // the result *is* the string buffer, so `T = String` is the only
    // instantiation that makes sense and the only one supported here.
    let buf = sa.buf.lock().unwrap();
    let s = std::str::from_utf8(&buf).unwrap_or_else(|e| {
        // Every copy writes a whole `String` (valid UTF-8) and the zero fill
        // is valid UTF-8 too, so this only fires if a caller overwrote part
        // of a multi-byte sequence — a compiler bug, as is C's out-of-bounds.
        panic!("System.stringAllocatorResult: buffer is not valid UTF-8: {e}")
    });
    let res: ArcStr = ArcStr::from(s);
    let any: &dyn std::any::Any = &res;
    match any.downcast_ref::<T>() {
        Some(r) => r.clone(),
        None => panic!(
            "System.stringAllocatorResult: only String results are supported, got {}",
            std::any::type_name::<T>()
        ),
    }
}

pub fn relocateFunctions(_fileName: ArcStr, _names: Arc<List<(ArcStr, ArcStr)>>) -> bool {
    // Hot-swap runtime symbols from a fresh .so — needs dlopen + relocation
    // walking. Not used by the Rust-side compile path.
    todo!("System.relocateFunctions: symbol relocation not yet ported")
}

pub fn fflush() {
    use std::io::Write as _;
    let _ = std::io::stdout().flush();
    let _ = std::io::stderr().flush();
}

pub fn updateUriMapping(namesAndDirs: metamodelica::Array<ArcStr>) {
    // Port of `OpenModelica_updateUriMapping` (util/utility.c). The table
    // lives in the `metamodelica` crate (the analogue of the C runtime,
    // which owns `threadData->localRoots[LOCAL_ROOT_URI_LOOKUP]`) so that
    // `metamodelica::uriToFilename` — the `OpenModelica.Scripting.uriToFilename`
    // builtin — can resolve `modelica://` URIs against it.
    metamodelica::updateUriMapping(namesAndDirs);
}

pub fn getSizeOfData<T: Clone + 'static>(_data: T) -> (metamodelica::Real, metamodelica::Real, metamodelica::Real) {
    // Walks the in-memory object graph counting bytes. The C version
    // leans on Boehm GC's heap layout; Rust has nothing equivalent.
    todo!("System.getSizeOfData: heap-walking memory profiler not yet ported")
}

// ───────────────────────────────── fputs / waitForInput ──────────────────────

#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
#[repr(i32)]
pub enum StreamType {
    STDOUT = 1,
    STDERR = 2,
}
impl PartialOrd for StreamType {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> { Some(self.cmp(other)) }
}
impl Ord for StreamType {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering { (*self as i32).cmp(&(*other as i32)) }
}

pub fn fputs(r#str: ArcStr, streamType: StreamType) -> i32 {
    use std::io::Write as _;
    let res = match streamType {
        StreamType::STDOUT => std::io::stdout().write_all(r#str.as_bytes()),
        StreamType::STDERR => std::io::stderr().write_all(r#str.as_bytes()),
    };
    if res.is_ok() { 0 } else { -1 }
}

pub fn waitForInput() {
    // Block until a single byte arrives on stdin — used as a debugger
    // synchronisation point (attach valgrind, then press enter).
    let mut buf = [0u8; 1];
    use std::io::Read as _;
    let _ = std::io::stdin().read(&mut buf);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sprintff_g_uses_significant_digits() {
        // C's `%g` precision counts significant digits, not digits after the
        // decimal point. These mirror `String(x, significantDigits=..)` results.
        let g = |fmt: &str, v: f64| c_format_double(fmt, v).unwrap();
        assert_eq!(g("%.3g", 1.234232), "1.23");
        assert_eq!(g("%-0.4g", 1.2342342), "1.234");
        assert_eq!(g("%.4g", 1.2342342), "1.234");
        // Trailing zeros are stripped (no '#').
        assert_eq!(g("%.6g", 1.5), "1.5");
        // Large/small magnitudes fall back to %e with a C-style exponent.
        assert_eq!(g("%.3g", 1234567.0), "1.23e+06");
        assert_eq!(g("%.2g", 0.00012345), "0.00012");
        assert_eq!(g("%.2g", 0.0000012345), "1.2e-06");
        // Rounding can carry into a higher exponent.
        assert_eq!(g("%.2g", 9.99), "10");
    }

    #[test]
    fn sprintff_e_is_c_style_exponent() {
        let e = |fmt: &str, v: f64| c_format_double(fmt, v).unwrap();
        assert_eq!(e("%.2e", 1234.5), "1.23e+03");
        assert_eq!(e("%.3e", 0.0012345), "1.234e-03");
    }

    #[test]
    fn iconv_utf8_to_utf8_is_identity() {
        // Valid UTF-8 in, UTF-8 out: returned unchanged (case-insensitive labels).
        let s = ArcStr::from("héllo αβγ");
        assert_eq!(iconv(s.clone(), literal!("UTF-8"), literal!("UTF-8")), s);
        assert_eq!(iconv(s.clone(), literal!("utf8"), literal!("UTF-8")), s);
    }

    #[test]
    fn iconv_latin1_to_utf8() {
        // The UTF-8 byte sequence C3 A9 ("é") reinterpreted as ISO-8859-1 is the
        // two characters 'Ã' (C3) and '©' (A9), which become this UTF-8 string.
        let input = ArcStr::from("é"); // bytes: 0xC3 0xA9
        let out = iconv(input, literal!("ISO-8859-1"), literal!("UTF-8"));
        assert_eq!(out.as_str(), "Ã©");
    }

    #[test]
    fn iconv_unknown_charset_returns_empty() {
        let out = iconv(ArcStr::from("abc"), literal!("NO-SUCH-CHARSET"), literal!("UTF-8"));
        assert_eq!(out.as_str(), "");
    }

    #[test]
    fn iconv_ascii_roundtrips_through_legacy_target() {
        // Pure-ASCII content survives a non-UTF-8 target because the encoded
        // bytes stay valid UTF-8.
        let out = iconv(ArcStr::from("plain ascii"), literal!("UTF-8"), literal!("ISO-8859-1"));
        assert_eq!(out.as_str(), "plain ascii");
    }

    #[test]
    fn iconv_nonrepresentable_target_returns_empty() {
        // Encoding non-ASCII to a non-UTF-8 charset yields high bytes that are
        // not valid UTF-8, so the all-UTF-8 port cannot represent the result.
        let out = iconv(ArcStr::from("é"), literal!("UTF-8"), literal!("ISO-8859-1"));
        assert_eq!(out.as_str(), "");
    }
}
