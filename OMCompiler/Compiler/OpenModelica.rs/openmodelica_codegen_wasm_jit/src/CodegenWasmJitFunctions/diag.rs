//! Diagnostics context: the part/function being lowered and the
//! unknown-variable message.

use super::*;

thread_local! {
    /// What is being lowered, for the diagnostics below.
    pub(super) static CURRENT_FN: std::cell::RefCell<String> = const { std::cell::RefCell::new(String::new()) };
    static CURRENT_PART: std::cell::RefCell<String> = const { std::cell::RefCell::new(String::new()) };
}

pub(super) fn fn_context() -> String {
    let part = CURRENT_PART.with(|p| p.borrow().clone());
    CURRENT_FN.with(|f| match (f.borrow().as_str(), part.as_str()) {
        ("", "") => String::new(),
        ("", p) => format!(" in {p}"),
        (name, "") => format!(" in function `{name}`"),
        (name, p) => format!(" in {p} in function `{name}`"),
    })
}

/// Sets `CURRENT_PART` until it drops, restoring the previous value.
pub(crate) struct PartGuard(String);

impl PartGuard {
    pub(crate) fn new(part: String) -> Self {
        PartGuard(CURRENT_PART.with(|p| p.replace(part)))
    }
}

impl Drop for PartGuard {
    fn drop(&mut self) {
        CURRENT_PART.with(|p| *p.borrow_mut() = std::mem::take(&mut self.0));
    }
}

/// [`PartGuard`] for `CURRENT_FN`, which the equation functions have no
/// `SimCodeFunction` to take a name from.
pub(crate) struct FnNameGuard(String);

impl FnNameGuard {
    pub(crate) fn new(name: &str) -> Self {
        FnNameGuard(CURRENT_FN.with(|f| f.replace(name.to_owned())))
    }
}

impl Drop for FnNameGuard {
    fn drop(&mut self) {
        CURRENT_FN.with(|f| *f.borrow_mut() = std::mem::take(&mut self.0));
    }
}

/// Record a message naming the unresolved variable (the `Result` error is a
/// `&'static str`; `translateModel` surfaces the recorded message).
pub(super) fn unknown_variable(name: &str) -> &'static str {
    crate::CodegenWasmJit::record_error(format!(
        "CodegenWasmJit: reference to unknown variable `{name}`{}",
        fn_context()
    ));
    "CodegenWasmJit: reference to unknown variable"
}

/// Parse one `.wasm.sig` line into a list of [`SigTy`]s (see [`SigTy::write_code`]
/// for the encoding). Types are concatenated without separators; an `'['`
/// consumes the following type as its array element.
pub(super) fn parse_sig_types(line: &str) -> Result<Vec<SigTy>> {
    let mut chars = line.chars().peekable();
    let mut out = Vec::new();
    while chars.peek().is_some() {
        out.push(parse_sig_type(&mut chars)?);
    }
    Ok(out)
}
