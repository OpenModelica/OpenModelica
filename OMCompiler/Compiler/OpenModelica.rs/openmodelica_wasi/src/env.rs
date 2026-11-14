//! The process environment. wasm32 has none (`std::env::set_var` panics there),
//! so it is an in-process map the JS host seeds before init.

#[cfg(target_arch = "wasm32")]
thread_local! {
    static VARS: std::cell::RefCell<std::collections::BTreeMap<String, String>> =
        const { std::cell::RefCell::new(std::collections::BTreeMap::new()) };
}

pub fn var(name: &str) -> Option<String> {
    #[cfg(target_arch = "wasm32")]
    if let Some(v) = VARS.with(|e| e.borrow().get(name).cloned()) {
        return Some(v);
    }
    std::env::var(name).ok()
}

pub fn set_var(name: &str, value: &str, overwrite: bool) {
    #[cfg(target_arch = "wasm32")]
    VARS.with(|e| {
        let mut m = e.borrow_mut();
        if overwrite || !m.contains_key(name) {
            m.insert(name.to_owned(), value.to_owned());
        }
    });
    #[cfg(not(target_arch = "wasm32"))]
    {
        if !overwrite && std::env::var_os(name).is_some() {
            return;
        }
        // SAFETY: races with a concurrent getenv in another thread, as C's setenv does.
        unsafe { std::env::set_var(name, value) }
    }
}

/// Every variable; one that is not UTF-8 is left out.
pub fn vars() -> Vec<(String, String)> {
    #[cfg(target_arch = "wasm32")]
    return VARS.with(|e| e.borrow().iter().map(|(k, v)| (k.clone(), v.clone())).collect());
    #[cfg(not(target_arch = "wasm32"))]
    std::env::vars_os()
        .filter_map(|(k, v)| Some((k.into_string().ok()?, v.into_string().ok()?)))
        .collect()
}
