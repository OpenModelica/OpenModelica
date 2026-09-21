//! The String values a run's result rows carry, interned: a row holds the id
//! (as f64) of each String algebraic variable, a String parameter's value is its
//! id, and the `.arrow` writer turns ids back into text. Interned at capture
//! time because a runtime String handle is only valid until the variable is
//! assigned again. Process-global and never emptied: ids stay valid for the
//! life of the result stream that holds them, and the table only grows with
//! distinct texts.

use alloc::collections::BTreeMap;
use alloc::string::{String, ToString};
use alloc::vec::Vec;
use core::cell::UnsafeCell;
use core::sync::atomic::{AtomicBool, Ordering};

struct Table {
    by_id: Vec<String>,
    ids: BTreeMap<String, u32>,
}

struct Cell(UnsafeCell<Option<Table>>);
unsafe impl Sync for Cell {}
static TABLE: Cell = Cell(UnsafeCell::new(None));
static LOCK: AtomicBool = AtomicBool::new(false);

fn with<R>(f: impl FnOnce(&mut Table) -> R) -> R {
    while LOCK.compare_exchange_weak(false, true, Ordering::Acquire, Ordering::Relaxed).is_err() {
        core::hint::spin_loop();
    }
    let table = unsafe { &mut *TABLE.0.get() };
    let r = f(table.get_or_insert_with(|| Table { by_id: Vec::new(), ids: BTreeMap::new() }));
    LOCK.store(false, Ordering::Release);
    r
}

/// The id of `s`, allotting one on first sight.
pub fn intern(s: &str) -> u32 {
    with(|t| match t.ids.get(s) {
        Some(&id) => id,
        None => {
            let id = t.by_id.len() as u32;
            t.by_id.push(s.to_string());
            t.ids.insert(s.to_string(), id);
            id
        }
    })
}

/// The text behind `id`; `None` for an id never allotted.
pub fn lookup(id: u32) -> Option<String> {
    with(|t| t.by_id.get(id as usize).cloned())
}
