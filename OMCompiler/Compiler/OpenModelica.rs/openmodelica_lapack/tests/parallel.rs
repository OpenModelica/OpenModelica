//! oxiblas sizes its work from `rayon::current_num_threads()`, so what has to
//! hold is that `install` runs in a pool of exactly the capped size. Its own
//! binary, because `set_max_threads` is once-only.
#![cfg(feature = "parallel")]

use openmodelica_lapack::parallel::{install, set_max_threads};

#[test]
fn install_puts_oxiblas_in_the_capped_pool() {
    // Not the machine's count: rayon's global pool would fail this on any host
    // with more than three cores.
    set_max_threads(3);
    assert_eq!(install(rayon::current_num_threads), 3);

    // Set once: the second call is ignored rather than rebuilding underneath work.
    set_max_threads(7);
    assert_eq!(install(rayon::current_num_threads), 3);
}
