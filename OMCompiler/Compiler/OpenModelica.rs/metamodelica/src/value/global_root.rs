//! `setGlobalRoot` / `getGlobalRoot`.
//!
//! Each MetaModelica `setGlobalRoot(idx, v)` stores `v` in a fixed slot.
//! The boot/Rust path runs the compiler single-threaded, so one
//! thread-local table suffices (and avoids Send/Sync constraints that
//! would be incompatible with the `Rc<RefCell<_>>`-shaped values stored).
//! Values are erased through `Rc<dyn Any>`; `getGlobalRoot::<A>`
//! downcasts on retrieval.

use anyhow::Result;

thread_local! {
    static GLOBAL_ROOTS: std::cell::RefCell<Vec<Option<std::rc::Rc<dyn std::any::Any>>>> =
        const { std::cell::RefCell::new(Vec::new()) };
}

pub fn setGlobalRoot<A: std::any::Any + 'static>(index: i32, value: A) -> Result<()> {
    GLOBAL_ROOTS.with(|r| {
        let mut v = r.borrow_mut();
        let idx = index as usize;
        if v.len() <= idx {
            v.resize_with(idx + 1, || None);
        }
        v[idx] = Some(std::rc::Rc::new(value));
    });
    Ok(())
}

pub fn getGlobalRoot<A: std::any::Any + Clone + 'static>(index: i32) -> Result<A> {
    GLOBAL_ROOTS.with(|r| {
        let v = r.borrow();
        let entry = v
            .get(index as usize)
            .and_then(|o| o.clone())
            .ok_or_else(|| anyhow::anyhow!("getGlobalRoot: index {} is uninitialized", index))?;
        match entry.downcast::<A>() {
            Ok(rc) => Ok((*rc).clone()),
            Err(_) => Err(anyhow::anyhow!(
                "getGlobalRoot: index {} type mismatch (expected {})",
                index,
                std::any::type_name::<A>()
            )),
        }
    })
}
