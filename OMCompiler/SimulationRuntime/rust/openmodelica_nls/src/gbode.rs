//! gbode's `-gbnls=kinsol`, `experimental-kinsol` and `newton` systems, solved by
//! this crate's KINSOL and Newton. gbode cannot depend on this crate: see [`install`].

use alloc::vec;
use alloc::vec::Vec;

use openmodelica_solvers::gbode::nls_hook::{self, GbNlsRequest, NlsMethod};

pub fn install() {
    nls_hook::set_nls_hook(Some(solve));
}

fn solve(req: &mut GbNlsRequest) -> bool {
    let jac0 = crate::jac_evals();
    let ok = match req.method {
        NlsMethod::Kinsol => crate::kinsol::gb_solve(req),
        NlsMethod::KinsolB => crate::kinsol::gb_b_solve(req),
        NlsMethod::Newton => newton(req),
        NlsMethod::Internal => false,
    };
    req.jac_evals = crate::jac_evals() - jac0;
    ok
}

/// C's `solveNewton` from `nlsxExtrapolation`, retrying from `nlsxOld`. gbode's
/// system has `jacobianIndex = -1`, so C differences its Jacobian.
fn newton(req: &mut GbNlsRequest) -> bool {
    let n = req.n;
    let mut x = req.start.to_vec();
    let ok = with_res_scaling(req.handle, n, |res_scaling| {
        crate::solve_newton_c(n, &mut x, req.old, req.nominal, res_scaling, false, req.eval, &mut |_, _| {}, false)
    });
    if ok {
        req.x.copy_from_slice(&x);
    }
    ok
}

/// C's `solverData->resScaling`, kept per gbode system across solves.
fn with_res_scaling<R>(handle: u32, n: usize, f: impl FnOnce(&mut [f64]) -> R) -> R {
    struct Store(core::cell::UnsafeCell<Vec<Vec<f64>>>);
    unsafe impl Sync for Store {}
    static STORE: Store = Store(core::cell::UnsafeCell::new(Vec::new()));
    // gbode runs on one thread, as the rest of this crate's rosters assume.
    let all = unsafe { &mut *STORE.0.get() };
    let h = handle as usize;
    if all.len() <= h {
        all.resize(h + 1, Vec::new());
    }
    if all[h].len() != n {
        all[h] = vec![0.0; n];
    }
    f(&mut all[h])
}
