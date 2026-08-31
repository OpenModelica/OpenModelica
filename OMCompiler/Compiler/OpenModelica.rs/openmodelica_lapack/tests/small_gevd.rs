//! Small pencils, where faer 0.24.4's scratch sizing is short. Every routine is
//! called the way MSL calls it — `dggev` with `jobvl = jobvr = "V"` — over every
//! job combination and a range of `n` that brackets the affected sizes.
//!
//! Without `GEVD_MIN_SCRATCH_DIM` in `faer_backend.rs` this panics inside faer
//! for every 2x2 pencil.
#![cfg(feature = "faer-backend")]

use openmodelica_lapack as om;

fn mk(n: usize, seed: u64) -> Vec<f64> {
    let mut s = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
    let mut next = move || {
        s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((s >> 33) as f64 / (1u64 << 31) as f64) - 1.0
    };
    let mut a = vec![0.0; n * n];
    for j in 0..n {
        for i in 0..n {
            a[i + j * n] = next();
        }
    }
    for i in 0..n.min(n) {
        a[i + i * n] += n as f64;
    }
    a
}

#[test]
fn dggev_every_job_on_small_pencils() {
    for n in 1..=10usize {
        for seed in 0..30u64 {
            let (a, b) = (mk(n, seed * 7919 + n as u64), mk(n, seed * 7919 + n as u64 + 5000));
            for (jl, jr) in [("N", "N"), ("V", "N"), ("N", "V"), ("V", "V")] {
                let (mut ar, mut ai, mut be) = (vec![0.0; n], vec![0.0; n], vec![0.0; n]);
                let (mut vl, mut vr) = (vec![0.0; n * n], vec![0.0; n * n]);
                let info = om::gev::dggev(jl, jr, n, &a, n, &b, n, &mut ar, &mut ai, &mut be,
                                          &mut vl, n, &mut vr, n);
                assert_eq!(info, 0, "dggev {jl}/{jr} n={n} seed={seed}: INFO");
                // beta*A*x = alpha*B*x for the right eigenvectors, so the small
                // sizes are checked for correctness and not merely for not panicking.
                if jr != "V" {
                    continue;
                }
                let scale = a.iter().chain(&b).fold(1.0f64, |m, v| m.max(v.abs()));
                let mut k = 0;
                while k < n {
                    let pair = ai[k] != 0.0 && k + 1 < n;
                    for r in 0..n {
                        let (mut are, mut aim, mut bre, mut bim) = (0.0, 0.0, 0.0, 0.0);
                        for cl in 0..n {
                            let xr = vr[cl + k * n];
                            let xi = if pair { vr[cl + (k + 1) * n] } else { 0.0 };
                            are += a[r + cl * n] * xr;
                            aim += a[r + cl * n] * xi;
                            bre += b[r + cl * n] * xr;
                            bim += b[r + cl * n] * xi;
                        }
                        let lre = ar[k] * bre - ai[k] * bim;
                        let lim = ar[k] * bim + ai[k] * bre;
                        assert!((be[k] * are - lre).abs() <= 1e-9 * scale
                                && (be[k] * aim - lim).abs() <= 1e-9 * scale,
                            "dggev {jl}/{jr} n={n} seed={seed}: eigenvector {k} row {r}");
                    }
                    k += if pair { 2 } else { 1 };
                }
            }
        }
    }
}

#[test]
fn dhgeqz_on_small_pencils() {
    for n in 1..=10usize {
        for seed in 0..30u64 {
            let mut h = mk(n, seed * 7919 + n as u64);
            let mut t = mk(n, seed * 7919 + n as u64 + 5000);
            for j in 0..n {
                for r in j + 2..n {
                    h[r + j * n] = 0.0;
                }
                for r in j + 1..n {
                    t[r + j * n] = 0.0;
                }
            }
            for (job, cq, cz) in [("E", "N", "N"), ("S", "I", "I"), ("S", "V", "V")] {
                let (mut ar, mut ai, mut be) = (vec![0.0; n], vec![0.0; n], vec![0.0; n]);
                let (mut q, mut z) = (vec![0.0; n * n], vec![0.0; n * n]);
                for i in 0..n {
                    q[i + i * n] = 1.0;
                    z[i + i * n] = 1.0;
                }
                let (mut hw, mut tw) = (h.clone(), t.clone());
                let info = om::eig::dhgeqz(job, cq, cz, n, &mut hw, n, &mut tw, n, &mut ar,
                                           &mut ai, &mut be, &mut q, n, &mut z, n);
                assert_eq!(info, 0, "dhgeqz {job}/{cq}/{cz} n={n} seed={seed}: INFO");
            }
        }
    }
}

#[test]
fn dgeev_on_small_matrices() {
    for n in 1..=10usize {
        for seed in 0..30u64 {
            let a = mk(n, seed * 7919 + n as u64);
            for (jl, jr) in [("N", "N"), ("V", "N"), ("N", "V"), ("V", "V")] {
                let (mut wr, mut wi) = (vec![0.0; n], vec![0.0; n]);
                let (mut vl, mut vr) = (vec![0.0; n * n], vec![0.0; n * n]);
                let info = om::dgeev(jl, jr, n, &a, n, &mut wr, &mut wi, &mut vl, n, &mut vr, n);
                assert_eq!(info, 0, "dgeev {jl}/{jr} n={n} seed={seed}: INFO");
            }
        }
    }
}
