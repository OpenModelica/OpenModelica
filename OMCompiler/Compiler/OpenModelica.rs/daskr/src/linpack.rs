//! Port of `dlinpk.c`: the LINPACK dense (`dgefa`/`dgesl`) and banded
//! (`dgbfa`/`dgbsl`) LU factor/solve routines, plus the BLAS-1 kernels
//! (`daxpy`, `dcopy`, `dscal`, `ddot`, `dnrm2`, `idamax`).
//!
//! Indexing follows the original Fortran/f2c convention: matrices are stored
//! column-major with leading dimension `lda`, and a 1-based element `(i, j)`
//! lives at the 0-based offset `(i - 1) + (j - 1) * lda`. `integer` is the C
//! `int`, i.e. [`i32`]; loop and increment arithmetic is kept in `i32` so the
//! negative-stride paths behave exactly as in C.
//!
//! Reduction order is preserved (the LINPACK unrolled `ddot`/`dnrm2` loops) so
//! the results are bit-identical to the C reference — see `tests/cref.rs`.

#![allow(
    clippy::needless_range_loop,
    clippy::manual_swap,
    clippy::too_many_arguments,
    clippy::assign_op_pattern
)]

/// `idamax`: index (1-based) of the element of largest absolute value.
pub fn idamax(n: i32, dx: &[f64], incx: i32) -> i32 {
    if n < 1 {
        return 0;
    }
    if n == 1 {
        return 1;
    }
    if incx == 1 {
        let mut ret = 1;
        let mut dmax = dx[0].abs();
        for i in 2..=n {
            let v = dx[(i - 1) as usize].abs();
            if v > dmax {
                ret = i;
                dmax = v;
            }
        }
        return ret;
    }
    // increment not equal to 1
    let mut ret = 1;
    let mut ix = 1i32;
    let mut dmax = dx[(ix - 1) as usize].abs();
    ix += incx;
    for i in 2..=n {
        let v = dx[(ix - 1) as usize].abs();
        if v > dmax {
            ret = i;
            dmax = v;
        }
        ix += incx;
    }
    ret
}

/// `ddot`: dot product of two strided vectors (LINPACK unrolled-by-5 order).
pub fn ddot(n: i32, dx: &[f64], incx: i32, dy: &[f64], incy: i32) -> f64 {
    let mut dtemp = 0.0f64;
    if n <= 0 {
        return 0.0;
    }
    if incx == 1 && incy == 1 {
        let m = n % 5;
        if m != 0 {
            for i in 1..=m {
                let z = (i - 1) as usize;
                dtemp += dx[z] * dy[z];
            }
            if n < 5 {
                return dtemp;
            }
        }
        let mut i = m + 1;
        while i <= n {
            let z = (i - 1) as usize;
            dtemp = dtemp
                + dx[z] * dy[z]
                + dx[z + 1] * dy[z + 1]
                + dx[z + 2] * dy[z + 2]
                + dx[z + 3] * dy[z + 3]
                + dx[z + 4] * dy[z + 4];
            i += 5;
        }
        return dtemp;
    }
    // unequal or non-unit increments
    let mut ix = 1i32;
    let mut iy = 1i32;
    if incx < 0 {
        ix = (-n + 1) * incx + 1;
    }
    if incy < 0 {
        iy = (-n + 1) * incy + 1;
    }
    for _ in 0..n {
        dtemp += dx[(ix - 1) as usize] * dy[(iy - 1) as usize];
        ix += incx;
        iy += incy;
    }
    dtemp
}

/// `dnrm2`: Euclidean norm, via the classic four-phase scaled Lawson algorithm.
pub fn dnrm2(n: i32, dx: &[f64], incx: i32) -> f64 {
    const ZERO: f64 = 0.0;
    const ONE: f64 = 1.0;
    const CUTLO: f64 = 8.232e-11;
    const CUTHI: f64 = 1.304e19;

    if n <= 0 {
        return ZERO;
    }

    // 1-based access to `dx` (the f2c `--dx`).
    let g = |k: i32| dx[(k - 1) as usize];

    // The original uses an assigned-goto state machine; reproduce it directly.
    #[derive(Clone, Copy)]
    enum L {
        L20,
        L30,
        L50,
        L100,
        L105,
        L70,
        L110,
        L115,
        L75,
        L85,
        L200,
    }

    let mut next = 0i32; // 0 -> L30, 1 -> L50, 2 -> L70, 3 -> L110
    let mut sum = ZERO;
    let nn = n * incx;
    let mut i = 1i32;
    let mut j = 0i32;
    let mut xmax = ZERO;
    let mut state = L::L20;

    loop {
        match state {
            L::L20 => {
                state = match next {
                    0 => L::L30,
                    1 => L::L50,
                    2 => L::L70,
                    _ => L::L110,
                };
            }
            L::L30 => {
                if g(i).abs() > CUTLO {
                    state = L::L85;
                } else {
                    next = 1;
                    xmax = ZERO;
                    state = L::L50;
                }
            }
            L::L50 => {
                if g(i) == ZERO {
                    state = L::L200;
                } else if g(i).abs() > CUTLO {
                    state = L::L85;
                } else {
                    next = 2;
                    state = L::L105;
                }
            }
            L::L100 => {
                i = j;
                next = 3;
                sum = sum / g(i) / g(i);
                state = L::L105;
            }
            L::L105 => {
                xmax = g(i).abs();
                state = L::L115;
            }
            L::L70 => {
                if g(i).abs() > CUTLO {
                    state = L::L75;
                } else {
                    state = L::L110;
                }
            }
            L::L110 => {
                if g(i).abs() <= xmax {
                    state = L::L115;
                } else {
                    let d = xmax / g(i);
                    sum = ONE + sum * (d * d);
                    xmax = g(i).abs();
                    state = L::L200;
                }
            }
            L::L115 => {
                let d = g(i) / xmax;
                sum += d * d;
                state = L::L200;
            }
            L::L75 => {
                sum = sum * xmax * xmax;
                state = L::L85;
            }
            L::L85 => {
                let hitest = CUTHI / (n as f64);
                let mut jj = i;
                let mut hit_l100 = false;
                loop {
                    let cont = if incx < 0 { jj >= nn } else { jj <= nn };
                    if !cont {
                        break;
                    }
                    if g(jj).abs() >= hitest {
                        j = jj;
                        hit_l100 = true;
                        break;
                    }
                    let d = g(jj);
                    sum += d * d;
                    jj += incx;
                }
                if hit_l100 {
                    state = L::L100;
                } else {
                    return sum.sqrt();
                }
            }
            L::L200 => {
                i += incx;
                if i <= nn {
                    state = L::L20;
                } else {
                    return xmax * sum.sqrt();
                }
            }
        }
    }
}

/// `dscal`: scale a strided vector in place (`dx := da * dx`).
pub fn dscal(n: i32, da: f64, dx: &mut [f64], incx: i32) {
    if n <= 0 {
        return;
    }
    if incx == 1 {
        let m = n % 5;
        if m != 0 {
            for i in 1..=m {
                let z = (i - 1) as usize;
                dx[z] = da * dx[z];
            }
            if n < 5 {
                return;
            }
        }
        let mut i = m + 1;
        while i <= n {
            let z = (i - 1) as usize;
            dx[z] = da * dx[z];
            dx[z + 1] = da * dx[z + 1];
            dx[z + 2] = da * dx[z + 2];
            dx[z + 3] = da * dx[z + 3];
            dx[z + 4] = da * dx[z + 4];
            i += 5;
        }
        return;
    }
    // increment not equal to 1
    let nincx = n * incx;
    let mut i = 1i32;
    loop {
        let cont = if incx < 0 { i >= nincx } else { i <= nincx };
        if !cont {
            break;
        }
        let z = (i - 1) as usize;
        dx[z] = da * dx[z];
        i += incx;
    }
}

/// `dcopy`: copy a strided vector (`sy := sx`), LINPACK unrolled by 7.
pub fn dcopy(n: i32, sx: &[f64], incx: i32, sy: &mut [f64], incy: i32) {
    if n <= 0 {
        return;
    }
    if incx == 1 && incy == 1 {
        let m = n % 7;
        if m != 0 {
            for i in 1..=m {
                sy[(i - 1) as usize] = sx[(i - 1) as usize];
            }
            if n < 7 {
                return;
            }
        }
        let mut i = m + 1;
        while i <= n {
            let z = (i - 1) as usize;
            sy[z] = sx[z];
            sy[z + 1] = sx[z + 1];
            sy[z + 2] = sx[z + 2];
            sy[z + 3] = sx[z + 3];
            sy[z + 4] = sx[z + 4];
            sy[z + 5] = sx[z + 5];
            sy[z + 6] = sx[z + 6];
            i += 7;
        }
        return;
    }
    let mut ix = 1i32;
    let mut iy = 1i32;
    if incx < 0 {
        ix = (-n + 1) * incx + 1;
    }
    if incy < 0 {
        iy = (-n + 1) * incy + 1;
    }
    for _ in 0..n {
        sy[(iy - 1) as usize] = sx[(ix - 1) as usize];
        ix += incx;
        iy += incy;
    }
}

/// `daxpy`: `dy := dy + da * dx`, LINPACK unrolled by 4.
pub fn daxpy(n: i32, da: f64, dx: &[f64], incx: i32, dy: &mut [f64], incy: i32) {
    if n <= 0 {
        return;
    }
    if da == 0.0 {
        return;
    }
    if incx == 1 && incy == 1 {
        let m = n % 4;
        if m != 0 {
            for i in 1..=m {
                let z = (i - 1) as usize;
                dy[z] += da * dx[z];
            }
            if n < 4 {
                return;
            }
        }
        let mut i = m + 1;
        while i <= n {
            let z = (i - 1) as usize;
            dy[z] += da * dx[z];
            dy[z + 1] += da * dx[z + 1];
            dy[z + 2] += da * dx[z + 2];
            dy[z + 3] += da * dx[z + 3];
            i += 4;
        }
        return;
    }
    let mut ix = 1i32;
    let mut iy = 1i32;
    if incx < 0 {
        ix = (-n + 1) * incx + 1;
    }
    if incy < 0 {
        iy = (-n + 1) * incy + 1;
    }
    for _ in 0..n {
        dy[(iy - 1) as usize] += da * dx[(ix - 1) as usize];
        ix += incx;
        iy += incy;
    }
}

/// `dgefa`: Gaussian elimination with partial pivoting on a dense matrix.
///
/// `a` is `lda * n` column-major; on return it holds the LU factors, `ipvt`
/// the (1-based) pivot indices, and `info` is 0 or the index of a zero pivot.
pub fn dgefa(a: &mut [f64], lda: i32, n: i32, ipvt: &mut [i32], info: &mut i32) {
    let idx = |i: i32, j: i32| ((i - 1) + (j - 1) * lda) as usize;
    *info = 0;
    let nm1 = n - 1;
    if nm1 >= 1 {
        for k in 1..=nm1 {
            let kp1 = k + 1;

            // pivot index within column k
            let l = idamax(n - k + 1, &a[idx(k, k)..], 1) + k - 1;
            ipvt[(k - 1) as usize] = l;

            if a[idx(l, k)] == 0.0 {
                *info = k;
                continue;
            }

            if l != k {
                a.swap(idx(l, k), idx(k, k));
            }

            // compute multipliers
            let t = -1.0 / a[idx(k, k)];
            dscal(n - k, t, &mut a[idx(k + 1, k)..], 1);

            // row elimination with column indexing
            for j in kp1..=n {
                let tj = a[idx(l, j)];
                if l != k {
                    a[idx(l, j)] = a[idx(k, j)];
                    a[idx(k, j)] = tj;
                }
                // daxpy(n-k, tj, col k, col j) — same array, disjoint columns.
                let xoff = idx(k + 1, k);
                let yoff = idx(k + 1, j);
                for ii in 0..(n - k) as usize {
                    a[yoff + ii] += tj * a[xoff + ii];
                }
            }
        }
    }
    ipvt[(n - 1) as usize] = n;
    if a[idx(n, n)] == 0.0 {
        *info = n;
    }
}

/// `dgesl`: solve `a*x = b` (`job == 0`) or `trans(a)*x = b` (`job != 0`)
/// using the factors from [`dgefa`]. `b` holds the right-hand side on entry and
/// the solution on return.
pub fn dgesl(a: &[f64], lda: i32, n: i32, ipvt: &[i32], b: &mut [f64], job: i32) {
    let idx = |i: i32, j: i32| ((i - 1) + (j - 1) * lda) as usize;
    let nm1 = n - 1;
    if job == 0 {
        // solve l*y = b
        if nm1 >= 1 {
            for k in 1..=nm1 {
                let l = ipvt[(k - 1) as usize];
                let t = b[(l - 1) as usize];
                if l != k {
                    b[(l - 1) as usize] = b[(k - 1) as usize];
                    b[(k - 1) as usize] = t;
                }
                daxpy(n - k, t, &a[idx(k + 1, k)..], 1, &mut b[k as usize..], 1);
            }
        }
        // solve u*x = y
        for kb in 1..=n {
            let k = n + 1 - kb;
            b[(k - 1) as usize] /= a[idx(k, k)];
            let t = -b[(k - 1) as usize];
            daxpy(k - 1, t, &a[((k - 1) * lda) as usize..], 1, &mut b[..], 1);
        }
    } else {
        // solve trans(u)*y = b
        for k in 1..=n {
            let t = ddot(k - 1, &a[((k - 1) * lda) as usize..], 1, &b[..], 1);
            b[(k - 1) as usize] = (b[(k - 1) as usize] - t) / a[idx(k, k)];
        }
        // solve trans(l)*x = y
        if nm1 >= 1 {
            for kb in 1..=nm1 {
                let k = n - kb;
                b[(k - 1) as usize] += ddot(n - k, &a[idx(k + 1, k)..], 1, &b[k as usize..], 1);
                let l = ipvt[(k - 1) as usize];
                if l != k {
                    let t = b[(l - 1) as usize];
                    b[(l - 1) as usize] = b[(k - 1) as usize];
                    b[(k - 1) as usize] = t;
                }
            }
        }
    }
}

/// `dgbfa`: LU factorization of a band matrix in LINPACK band storage.
///
/// `abd` is `lda * n`; the diagonals occupy rows `ml+1 .. 2*ml+mu+1`. On return
/// `abd` holds the factors, `ipvt` the pivots, `info` a zero-pivot index or 0.
pub fn dgbfa(
    abd: &mut [f64],
    lda: i32,
    n: i32,
    ml: i32,
    mu: i32,
    ipvt: &mut [i32],
    info: &mut i32,
) {
    let idx = |i: i32, j: i32| ((i - 1) + (j - 1) * lda) as usize;
    let m = ml + mu + 1;
    *info = 0;

    // zero initial fill-in columns
    let j0 = mu + 2;
    let j1 = n.min(m) - 1;
    if j1 >= j0 {
        for jz in j0..=j1 {
            let i0 = m + 1 - jz;
            for i in i0..=ml {
                abd[idx(i, jz)] = 0.0;
            }
        }
    }
    let mut jz = j1;
    let mut ju = 0i32;

    let nm1 = n - 1;
    if nm1 >= 1 {
        for k in 1..=nm1 {
            let kp1 = k + 1;

            // zero next fill-in column
            jz += 1;
            if jz <= n && ml >= 1 {
                for i in 1..=ml {
                    abd[idx(i, jz)] = 0.0;
                }
            }

            // pivot index
            let lm = ml.min(n - k);
            let mut l = idamax(lm + 1, &abd[idx(m, k)..], 1) + m - 1;
            ipvt[(k - 1) as usize] = l + k - m;

            if abd[idx(l, k)] == 0.0 {
                *info = k;
                continue;
            }

            if l != m {
                abd.swap(idx(l, k), idx(m, k));
            }

            // compute multipliers
            let t = -1.0 / abd[idx(m, k)];
            dscal(lm, t, &mut abd[idx(m + 1, k)..], 1);

            // row elimination with column indexing
            ju = (ju.max(mu + ipvt[(k - 1) as usize])).min(n);
            let mut mm = m;
            if ju >= kp1 {
                for j in kp1..=ju {
                    l -= 1;
                    mm -= 1;
                    let tj = abd[idx(l, j)];
                    if l != mm {
                        abd[idx(l, j)] = abd[idx(mm, j)];
                        abd[idx(mm, j)] = tj;
                    }
                    let xoff = idx(m + 1, k);
                    let yoff = idx(mm + 1, j);
                    for ii in 0..lm as usize {
                        abd[yoff + ii] += tj * abd[xoff + ii];
                    }
                }
            }
        }
    }
    ipvt[(n - 1) as usize] = n;
    if abd[idx(m, n)] == 0.0 {
        *info = n;
    }
}

/// `dgbsl`: solve `a*x = b` (`job == 0`) or `trans(a)*x = b` (`job != 0`) for a
/// band matrix factored by [`dgbfa`].
pub fn dgbsl(
    abd: &[f64],
    lda: i32,
    n: i32,
    ml: i32,
    mu: i32,
    ipvt: &[i32],
    b: &mut [f64],
    job: i32,
) {
    let idx = |i: i32, j: i32| ((i - 1) + (j - 1) * lda) as usize;
    let m = mu + ml + 1;
    let nm1 = n - 1;
    if job == 0 {
        // solve l*y = b
        if ml != 0 && nm1 >= 1 {
            for k in 1..=nm1 {
                let lm = ml.min(n - k);
                let l = ipvt[(k - 1) as usize];
                let t = b[(l - 1) as usize];
                if l != k {
                    b[(l - 1) as usize] = b[(k - 1) as usize];
                    b[(k - 1) as usize] = t;
                }
                daxpy(lm, t, &abd[idx(m + 1, k)..], 1, &mut b[k as usize..], 1);
            }
        }
        // solve u*x = y
        for kb in 1..=n {
            let k = n + 1 - kb;
            b[(k - 1) as usize] /= abd[idx(m, k)];
            let lm = k.min(m) - 1;
            let la = m - lm;
            let lb = k - lm;
            let t = -b[(k - 1) as usize];
            daxpy(lm, t, &abd[idx(la, k)..], 1, &mut b[(lb - 1) as usize..], 1);
        }
    } else {
        // solve trans(u)*y = b
        for k in 1..=n {
            let lm = k.min(m) - 1;
            let la = m - lm;
            let lb = k - lm;
            let t = ddot(lm, &abd[idx(la, k)..], 1, &b[(lb - 1) as usize..], 1);
            b[(k - 1) as usize] = (b[(k - 1) as usize] - t) / abd[idx(m, k)];
        }
        // solve trans(l)*x = y
        if ml != 0 && nm1 >= 1 {
            for kb in 1..=nm1 {
                let k = n - kb;
                let lm = ml.min(n - k);
                b[(k - 1) as usize] += ddot(lm, &abd[idx(m + 1, k)..], 1, &b[k as usize..], 1);
                let l = ipvt[(k - 1) as usize];
                if l != k {
                    let t = b[(l - 1) as usize];
                    b[(l - 1) as usize] = b[(k - 1) as usize];
                    b[(k - 1) as usize] = t;
                }
            }
        }
    }
}
