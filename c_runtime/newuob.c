/* newuob.f -- translated by f2c (version 20041007).
   You must link the resulting object file with libf2c:
	on Microsoft Windows system, link with libf2c.lib;
	on Linux or Unix systems, link with .../path/to/libf2c.a -lm
	or, if you install libf2c.a in a standard place, with -lf2c -lm
	-- in that order, at the end of the command line, as in
		cc *.o -lf2c -lm
	Source for libf2c is in /netlib/f2c/libf2c.zip, e.g.,

		http://www.netlib.org/f2c/libf2c.zip
*/

#include "f2c.h"

/* Table of constant values */

static integer c__1 = 1;

/* Subroutine */ int newuob_(integer *n, integer *npt, doublereal *x, 
	doublereal *rhobeg, doublereal *rhoend, integer *iprint, integer *
	maxfun, doublereal *xbase, doublereal *xopt, doublereal *xnew, 
	doublereal *xpt, doublereal *fval, doublereal *gq, doublereal *hq, 
	doublereal *pq, doublereal *bmat, doublereal *zmat, integer *ndim, 
	doublereal *d__, doublereal *vlag, doublereal *w, S_fp calfun)
{
    /* Format strings */
    static char fmt_320[] = "(/4x,\002Return from NEWUOA because CALFUN has "
	    "been\002,\002 called MAXFUN times.\002)";
    static char fmt_330[] = "(/4x,\002Function number\002,i6,\002    F =\002"
	    ",1pd18.10,\002    The corresponding X is:\002/(2x,5d15.6))";
    static char fmt_370[] = "(/4x,\002Return from NEWUOA because a trus"
	    "t\002,\002 region step has failed to reduce Q.\002)";
    static char fmt_500[] = "(5x)";
    static char fmt_510[] = "(/4x,\002New RHO =\002,1pd11.4,5x,\002Number o"
	    "f\002,\002 function values =\002,i6)";
    static char fmt_520[] = "(4x,\002Least value of F =\002,1pd23.15,9x,\002"
	    "The corresponding X is:\002/(2x,5d15.6))";
    static char fmt_550[] = "(/4x,\002At the return from NEWUOA\002,5x,\002N"
	    "umber of function values =\002,i6)";

    /* System generated locals */
    integer xpt_dim1, xpt_offset, bmat_dim1, bmat_offset, zmat_dim1, 
	    zmat_offset, i__1, i__2, i__3;
    doublereal d__1, d__2, d__3;

    /* Builtin functions */
    double sqrt(doublereal);
    integer s_wsfe(cilist *), e_wsfe(void), do_fio(integer *, char *, ftnlen);

    /* Local variables */
    static doublereal f;
    static integer i__, j, k, ih, nf, nh, ip, jp;
    static doublereal dx;
    static integer np, nfm;
    static doublereal one;
    static integer idz;
    static doublereal dsq, rho;
    static integer ipt, jpt;
    static doublereal sum, fbeg, diff, half, beta;
    static integer nfmm;
    static doublereal gisq;
    static integer knew;
    static doublereal temp, suma, sumb, fopt, bsum, gqsq;
    static integer kopt, nptm;
    static doublereal zero, xipt, xjpt, sumz, diffa, diffb, diffc, hdiag, 
	    alpha, delta, recip, reciq, fsave;
    static integer ksave, nfsav, itemp;
    static doublereal dnorm, ratio, dstep, tenth, vquad;
    static integer ktemp;
    static doublereal tempq;
    static integer itest;
    static doublereal rhosq;
    extern /* Subroutine */ int biglag_(integer *, integer *, doublereal *, 
	    doublereal *, doublereal *, doublereal *, integer *, integer *, 
	    integer *, doublereal *, doublereal *, doublereal *, doublereal *,
	     doublereal *, doublereal *, doublereal *, doublereal *), bigden_(
	    integer *, integer *, doublereal *, doublereal *, doublereal *, 
	    doublereal *, integer *, integer *, integer *, integer *, 
	    doublereal *, doublereal *, doublereal *, doublereal *, 
	    doublereal *, doublereal *, doublereal *), update_(integer *, 
	    integer *, doublereal *, doublereal *, integer *, integer *, 
	    doublereal *, doublereal *, integer *, doublereal *);
    static doublereal detrat, crvmin;
    static integer nftest;
    static doublereal distsq;
    extern /* Subroutine */ int trsapp_(integer *, integer *, doublereal *, 
	    doublereal *, doublereal *, doublereal *, doublereal *, 
	    doublereal *, doublereal *, doublereal *, doublereal *, 
	    doublereal *, doublereal *, doublereal *);
    static doublereal xoptsq;

    /* Fortran I/O blocks */
    static cilist io___55 = { 0, 6, 0, fmt_320, 0 };
    static cilist io___56 = { 0, 6, 0, fmt_330, 0 };
    static cilist io___61 = { 0, 6, 0, fmt_370, 0 };
    static cilist io___68 = { 0, 6, 0, fmt_500, 0 };
    static cilist io___69 = { 0, 6, 0, fmt_510, 0 };
    static cilist io___70 = { 0, 6, 0, fmt_520, 0 };
    static cilist io___71 = { 0, 6, 0, fmt_550, 0 };
    static cilist io___72 = { 0, 6, 0, fmt_520, 0 };



/*     The arguments N, NPT, X, RHOBEG, RHOEND, IPRINT and MAXFUN are identical */
/*       to the corresponding arguments in SUBROUTINE NEWUOA. */
/*     XBASE will hold a shift of origin that should reduce the contributions */
/*       from rounding errors to values of the model and Lagrange functions. */
/*     XOPT will be set to the displacement from XBASE of the vector of */
/*       variables that provides the least calculated F so far. */
/*     XNEW will be set to the displacement from XBASE of the vector of */
/*       variables for the current calculation of F. */
/*     XPT will contain the interpolation point coordinates relative to XBASE. */
/*     FVAL will hold the values of F at the interpolation points. */
/*     GQ will hold the gradient of the quadratic model at XBASE. */
/*     HQ will hold the explicit second derivatives of the quadratic model. */
/*     PQ will contain the parameters of the implicit second derivatives of */
/*       the quadratic model. */
/*     BMAT will hold the last N columns of H. */
/*     ZMAT will hold the factorization of the leading NPT by NPT submatrix of */
/*       H, this factorization being ZMAT times Diag(DZ) times ZMAT^T, where */
/*       the elements of DZ are plus or minus one, as specified by IDZ. */
/*     NDIM is the first dimension of BMAT and has the value NPT+N. */
/*     D is reserved for trial steps from XOPT. */
/*     VLAG will contain the values of the Lagrange functions at a new point X. */
/*       They are part of a product that requires VLAG to be of length NDIM. */
/*     The array W will be used for working space. Its length must be at least */
/*       10*NDIM = 10*(NPT+N). */

/*     Set some constants. */

    /* Parameter adjustments */
    zmat_dim1 = *npt;
    zmat_offset = 1 + zmat_dim1;
    zmat -= zmat_offset;
    xpt_dim1 = *npt;
    xpt_offset = 1 + xpt_dim1;
    xpt -= xpt_offset;
    --x;
    --xbase;
    --xopt;
    --xnew;
    --fval;
    --gq;
    --hq;
    --pq;
    bmat_dim1 = *ndim;
    bmat_offset = 1 + bmat_dim1;
    bmat -= bmat_offset;
    --d__;
    --vlag;
    --w;

    /* Function Body */
    half = .5;
    one = 1.;
    tenth = .1;
    zero = 0.;
    np = *n + 1;
    nh = *n * np / 2;
    nptm = *npt - np;
    nftest = max(*maxfun,1);

/*     Set the initial elements of XPT, BMAT, HQ, PQ and ZMAT to zero. */

    i__1 = *n;
    for (j = 1; j <= i__1; ++j) {
	xbase[j] = x[j];
	i__2 = *npt;
	for (k = 1; k <= i__2; ++k) {
/* L10: */
	    xpt[k + j * xpt_dim1] = zero;
	}
	i__2 = *ndim;
	for (i__ = 1; i__ <= i__2; ++i__) {
/* L20: */
	    bmat[i__ + j * bmat_dim1] = zero;
	}
    }
    i__2 = nh;
    for (ih = 1; ih <= i__2; ++ih) {
/* L30: */
	hq[ih] = zero;
    }
    i__2 = *npt;
    for (k = 1; k <= i__2; ++k) {
	pq[k] = zero;
	i__1 = nptm;
	for (j = 1; j <= i__1; ++j) {
/* L40: */
	    zmat[k + j * zmat_dim1] = zero;
	}
    }

/*     Begin the initialization procedure. NF becomes one more than the number */
/*     of function values so far. The coordinates of the displacement of the */
/*     next initial interpolation point from XBASE are set in XPT(NF,.). */

    rhosq = *rhobeg * *rhobeg;
    recip = one / rhosq;
    reciq = sqrt(half) / rhosq;
    nf = 0;
L50:
    nfm = nf;
    nfmm = nf - *n;
    ++nf;
    if (nfm <= *n << 1) {
	if (nfm >= 1 && nfm <= *n) {
	    xpt[nf + nfm * xpt_dim1] = *rhobeg;
	} else if (nfm > *n) {
	    xpt[nf + nfmm * xpt_dim1] = -(*rhobeg);
	}
    } else {
	itemp = (nfmm - 1) / *n;
	jpt = nfm - itemp * *n - *n;
	ipt = jpt + itemp;
	if (ipt > *n) {
	    itemp = jpt;
	    jpt = ipt - *n;
	    ipt = itemp;
	}
	xipt = *rhobeg;
	if (fval[ipt + np] < fval[ipt + 1]) {
	    xipt = -xipt;
	}
	xjpt = *rhobeg;
	if (fval[jpt + np] < fval[jpt + 1]) {
	    xjpt = -xjpt;
	}
	xpt[nf + ipt * xpt_dim1] = xipt;
	xpt[nf + jpt * xpt_dim1] = xjpt;
    }

/*     Calculate the next value of F, label 70 being reached immediately */
/*     after this calculation. The least function value so far and its index */
/*     are required. */

    i__1 = *n;
    for (j = 1; j <= i__1; ++j) {
/* L60: */
	x[j] = xpt[nf + j * xpt_dim1] + xbase[j];
    }
    goto L310;
L70:
    fval[nf] = f;
    if (nf == 1) {
	fbeg = f;
	fopt = f;
	kopt = 1;
    } else if (f < fopt) {
	fopt = f;
	kopt = nf;
    }

/*     Set the nonzero initial elements of BMAT and the quadratic model in */
/*     the cases when NF is at most 2*N+1. */

    if (nfm <= *n << 1) {
	if (nfm >= 1 && nfm <= *n) {
	    gq[nfm] = (f - fbeg) / *rhobeg;
	    if (*npt < nf + *n) {
		bmat[nfm * bmat_dim1 + 1] = -one / *rhobeg;
		bmat[nf + nfm * bmat_dim1] = one / *rhobeg;
		bmat[*npt + nfm + nfm * bmat_dim1] = -half * rhosq;
	    }
	} else if (nfm > *n) {
	    bmat[nf - *n + nfmm * bmat_dim1] = half / *rhobeg;
	    bmat[nf + nfmm * bmat_dim1] = -half / *rhobeg;
	    zmat[nfmm * zmat_dim1 + 1] = -reciq - reciq;
	    zmat[nf - *n + nfmm * zmat_dim1] = reciq;
	    zmat[nf + nfmm * zmat_dim1] = reciq;
	    ih = nfmm * (nfmm + 1) / 2;
	    temp = (fbeg - f) / *rhobeg;
	    hq[ih] = (gq[nfmm] - temp) / *rhobeg;
	    gq[nfmm] = half * (gq[nfmm] + temp);
	}

/*     Set the off-diagonal second derivatives of the Lagrange functions and */
/*     the initial quadratic model. */

    } else {
	ih = ipt * (ipt - 1) / 2 + jpt;
	if (xipt < zero) {
	    ipt += *n;
	}
	if (xjpt < zero) {
	    jpt += *n;
	}
	zmat[nfmm * zmat_dim1 + 1] = recip;
	zmat[nf + nfmm * zmat_dim1] = recip;
	zmat[ipt + 1 + nfmm * zmat_dim1] = -recip;
	zmat[jpt + 1 + nfmm * zmat_dim1] = -recip;
	hq[ih] = (fbeg - fval[ipt + 1] - fval[jpt + 1] + f) / (xipt * xjpt);
    }
    if (nf < *npt) {
	goto L50;
    }

/*     Begin the iterative procedure, because the initial model is complete. */

    rho = *rhobeg;
    delta = rho;
    idz = 1;
    diffa = zero;
    diffb = zero;
    itest = 0;
    xoptsq = zero;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	xopt[i__] = xpt[kopt + i__ * xpt_dim1];
/* L80: */
/* Computing 2nd power */
	d__1 = xopt[i__];
	xoptsq += d__1 * d__1;
    }
L90:
    nfsav = nf;

/*     Generate the next trust region step and test its length. Set KNEW */
/*     to -1 if the purpose of the next F will be to improve the model. */

L100:
    knew = 0;
    trsapp_(n, npt, &xopt[1], &xpt[xpt_offset], &gq[1], &hq[1], &pq[1], &
	    delta, &d__[1], &w[1], &w[np], &w[np + *n], &w[np + (*n << 1)], &
	    crvmin);
    dsq = zero;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L110: */
/* Computing 2nd power */
	d__1 = d__[i__];
	dsq += d__1 * d__1;
    }
/* Computing MIN */
    d__1 = delta, d__2 = sqrt(dsq);
    dnorm = min(d__1,d__2);
    if (dnorm < half * rho) {
	knew = -1;
	delta = tenth * delta;
	ratio = -1.;
	if (delta <= rho * 1.5) {
	    delta = rho;
	}
	if (nf <= nfsav + 2) {
	    goto L460;
	}
	temp = crvmin * .125 * rho * rho;
/* Computing MAX */
	d__1 = max(diffa,diffb);
	if (temp <= max(d__1,diffc)) {
	    goto L460;
	}
	goto L490;
    }

/*     Shift XBASE if XOPT may be too far from XBASE. First make the changes */
/*     to BMAT that do not depend on ZMAT. */

L120:
    if (dsq <= xoptsq * .001) {
	tempq = xoptsq * .25;
	i__1 = *npt;
	for (k = 1; k <= i__1; ++k) {
	    sum = zero;
	    i__2 = *n;
	    for (i__ = 1; i__ <= i__2; ++i__) {
/* L130: */
		sum += xpt[k + i__ * xpt_dim1] * xopt[i__];
	    }
	    temp = pq[k] * sum;
	    sum -= half * xoptsq;
	    w[*npt + k] = sum;
	    i__2 = *n;
	    for (i__ = 1; i__ <= i__2; ++i__) {
		gq[i__] += temp * xpt[k + i__ * xpt_dim1];
		xpt[k + i__ * xpt_dim1] -= half * xopt[i__];
		vlag[i__] = bmat[k + i__ * bmat_dim1];
		w[i__] = sum * xpt[k + i__ * xpt_dim1] + tempq * xopt[i__];
		ip = *npt + i__;
		i__3 = i__;
		for (j = 1; j <= i__3; ++j) {
/* L140: */
		    bmat[ip + j * bmat_dim1] = bmat[ip + j * bmat_dim1] + 
			    vlag[i__] * w[j] + w[i__] * vlag[j];
		}
	    }
	}

/*     Then the revisions of BMAT that depend on ZMAT are calculated. */

	i__3 = nptm;
	for (k = 1; k <= i__3; ++k) {
	    sumz = zero;
	    i__2 = *npt;
	    for (i__ = 1; i__ <= i__2; ++i__) {
		sumz += zmat[i__ + k * zmat_dim1];
/* L150: */
		w[i__] = w[*npt + i__] * zmat[i__ + k * zmat_dim1];
	    }
	    i__2 = *n;
	    for (j = 1; j <= i__2; ++j) {
		sum = tempq * sumz * xopt[j];
		i__1 = *npt;
		for (i__ = 1; i__ <= i__1; ++i__) {
/* L160: */
		    sum += w[i__] * xpt[i__ + j * xpt_dim1];
		}
		vlag[j] = sum;
		if (k < idz) {
		    sum = -sum;
		}
		i__1 = *npt;
		for (i__ = 1; i__ <= i__1; ++i__) {
/* L170: */
		    bmat[i__ + j * bmat_dim1] += sum * zmat[i__ + k * 
			    zmat_dim1];
		}
	    }
	    i__1 = *n;
	    for (i__ = 1; i__ <= i__1; ++i__) {
		ip = i__ + *npt;
		temp = vlag[i__];
		if (k < idz) {
		    temp = -temp;
		}
		i__2 = i__;
		for (j = 1; j <= i__2; ++j) {
/* L180: */
		    bmat[ip + j * bmat_dim1] += temp * vlag[j];
		}
	    }
	}

/*     The following instructions complete the shift of XBASE, including */
/*     the changes to the parameters of the quadratic model. */

	ih = 0;
	i__2 = *n;
	for (j = 1; j <= i__2; ++j) {
	    w[j] = zero;
	    i__1 = *npt;
	    for (k = 1; k <= i__1; ++k) {
		w[j] += pq[k] * xpt[k + j * xpt_dim1];
/* L190: */
		xpt[k + j * xpt_dim1] -= half * xopt[j];
	    }
	    i__1 = j;
	    for (i__ = 1; i__ <= i__1; ++i__) {
		++ih;
		if (i__ < j) {
		    gq[j] += hq[ih] * xopt[i__];
		}
		gq[i__] += hq[ih] * xopt[j];
		hq[ih] = hq[ih] + w[i__] * xopt[j] + xopt[i__] * w[j];
/* L200: */
		bmat[*npt + i__ + j * bmat_dim1] = bmat[*npt + j + i__ * 
			bmat_dim1];
	    }
	}
	i__1 = *n;
	for (j = 1; j <= i__1; ++j) {
	    xbase[j] += xopt[j];
/* L210: */
	    xopt[j] = zero;
	}
	xoptsq = zero;
    }

/*     Pick the model step if KNEW is positive. A different choice of D */
/*     may be made later, if the choice of D by BIGLAG causes substantial */
/*     cancellation in DENOM. */

    if (knew > 0) {
	biglag_(n, npt, &xopt[1], &xpt[xpt_offset], &bmat[bmat_offset], &zmat[
		zmat_offset], &idz, ndim, &knew, &dstep, &d__[1], &alpha, &
		vlag[1], &vlag[*npt + 1], &w[1], &w[np], &w[np + *n]);
    }

/*     Calculate VLAG and BETA for the current choice of D. The first NPT */
/*     components of W_check will be held in W. */

    i__1 = *npt;
    for (k = 1; k <= i__1; ++k) {
	suma = zero;
	sumb = zero;
	sum = zero;
	i__2 = *n;
	for (j = 1; j <= i__2; ++j) {
	    suma += xpt[k + j * xpt_dim1] * d__[j];
	    sumb += xpt[k + j * xpt_dim1] * xopt[j];
/* L220: */
	    sum += bmat[k + j * bmat_dim1] * d__[j];
	}
	w[k] = suma * (half * suma + sumb);
/* L230: */
	vlag[k] = sum;
    }
    beta = zero;
    i__1 = nptm;
    for (k = 1; k <= i__1; ++k) {
	sum = zero;
	i__2 = *npt;
	for (i__ = 1; i__ <= i__2; ++i__) {
/* L240: */
	    sum += zmat[i__ + k * zmat_dim1] * w[i__];
	}
	if (k < idz) {
	    beta += sum * sum;
	    sum = -sum;
	} else {
	    beta -= sum * sum;
	}
	i__2 = *npt;
	for (i__ = 1; i__ <= i__2; ++i__) {
/* L250: */
	    vlag[i__] += sum * zmat[i__ + k * zmat_dim1];
	}
    }
    bsum = zero;
    dx = zero;
    i__2 = *n;
    for (j = 1; j <= i__2; ++j) {
	sum = zero;
	i__1 = *npt;
	for (i__ = 1; i__ <= i__1; ++i__) {
/* L260: */
	    sum += w[i__] * bmat[i__ + j * bmat_dim1];
	}
	bsum += sum * d__[j];
	jp = *npt + j;
	i__1 = *n;
	for (k = 1; k <= i__1; ++k) {
/* L270: */
	    sum += bmat[jp + k * bmat_dim1] * d__[k];
	}
	vlag[jp] = sum;
	bsum += sum * d__[j];
/* L280: */
	dx += d__[j] * xopt[j];
    }
    beta = dx * dx + dsq * (xoptsq + dx + dx + half * dsq) + beta - bsum;
    vlag[kopt] += one;

/*     If KNEW is positive and if the cancellation in DENOM is unacceptable, */
/*     then BIGDEN calculates an alternative model step, XNEW being used for */
/*     working space. */

    if (knew > 0) {
/* Computing 2nd power */
	d__1 = vlag[knew];
	temp = one + alpha * beta / (d__1 * d__1);
	if (abs(temp) <= .8) {
	    bigden_(n, npt, &xopt[1], &xpt[xpt_offset], &bmat[bmat_offset], &
		    zmat[zmat_offset], &idz, ndim, &kopt, &knew, &d__[1], &w[
		    1], &vlag[1], &beta, &xnew[1], &w[*ndim + 1], &w[*ndim * 
		    6 + 1]);
	}
    }

/*     Calculate the next value of the objective function. */

L290:
    i__2 = *n;
    for (i__ = 1; i__ <= i__2; ++i__) {
	xnew[i__] = xopt[i__] + d__[i__];
/* L300: */
	x[i__] = xbase[i__] + xnew[i__];
    }
    ++nf;
L310:
    if (nf > nftest) {
	--nf;
	if (*iprint > 0) {
	    s_wsfe(&io___55);
	    e_wsfe();
	}
	goto L530;
    }
    (*calfun)(n, &x[1], &f);
    if (*iprint == 3) {
	s_wsfe(&io___56);
	do_fio(&c__1, (char *)&nf, (ftnlen)sizeof(integer));
	do_fio(&c__1, (char *)&f, (ftnlen)sizeof(doublereal));
	i__2 = *n;
	for (i__ = 1; i__ <= i__2; ++i__) {
	    do_fio(&c__1, (char *)&x[i__], (ftnlen)sizeof(doublereal));
	}
	e_wsfe();
    }
    if (nf <= *npt) {
	goto L70;
    }
    if (knew == -1) {
	goto L530;
    }

/*     Use the quadratic model to predict the change in F due to the step D, */
/*     and set DIFF to the error of this prediction. */

    vquad = zero;
    ih = 0;
    i__2 = *n;
    for (j = 1; j <= i__2; ++j) {
	vquad += d__[j] * gq[j];
	i__1 = j;
	for (i__ = 1; i__ <= i__1; ++i__) {
	    ++ih;
	    temp = d__[i__] * xnew[j] + d__[j] * xopt[i__];
	    if (i__ == j) {
		temp = half * temp;
	    }
/* L340: */
	    vquad += temp * hq[ih];
	}
    }
    i__1 = *npt;
    for (k = 1; k <= i__1; ++k) {
/* L350: */
	vquad += pq[k] * w[k];
    }
    diff = f - fopt - vquad;
    diffc = diffb;
    diffb = diffa;
    diffa = abs(diff);
    if (dnorm > rho) {
	nfsav = nf;
    }

/*     Update FOPT and XOPT if the new F is the least value of the objective */
/*     function so far. The branch when KNEW is positive occurs if D is not */
/*     a trust region step. */

    fsave = fopt;
    if (f < fopt) {
	fopt = f;
	xoptsq = zero;
	i__1 = *n;
	for (i__ = 1; i__ <= i__1; ++i__) {
	    xopt[i__] = xnew[i__];
/* L360: */
/* Computing 2nd power */
	    d__1 = xopt[i__];
	    xoptsq += d__1 * d__1;
	}
    }
    ksave = knew;
    if (knew > 0) {
	goto L410;
    }

/*     Pick the next value of DELTA after a trust region step. */

    if (vquad >= zero) {
	if (*iprint > 0) {
	    s_wsfe(&io___61);
	    e_wsfe();
	}
	goto L530;
    }
    ratio = (f - fsave) / vquad;
    if (ratio <= tenth) {
	delta = half * dnorm;
    } else if (ratio <= .7) {
/* Computing MAX */
	d__1 = half * delta;
	delta = max(d__1,dnorm);
    } else {
/* Computing MAX */
	d__1 = half * delta, d__2 = dnorm + dnorm;
	delta = max(d__1,d__2);
    }
    if (delta <= rho * 1.5) {
	delta = rho;
    }

/*     Set KNEW to the index of the next interpolation point to be deleted. */

/* Computing MAX */
    d__2 = tenth * delta;
/* Computing 2nd power */
    d__1 = max(d__2,rho);
    rhosq = d__1 * d__1;
    ktemp = 0;
    detrat = zero;
    if (f >= fsave) {
	ktemp = kopt;
	detrat = one;
    }
    i__1 = *npt;
    for (k = 1; k <= i__1; ++k) {
	hdiag = zero;
	i__2 = nptm;
	for (j = 1; j <= i__2; ++j) {
	    temp = one;
	    if (j < idz) {
		temp = -one;
	    }
/* L380: */
/* Computing 2nd power */
	    d__1 = zmat[k + j * zmat_dim1];
	    hdiag += temp * (d__1 * d__1);
	}
/* Computing 2nd power */
	d__2 = vlag[k];
	temp = (d__1 = beta * hdiag + d__2 * d__2, abs(d__1));
	distsq = zero;
	i__2 = *n;
	for (j = 1; j <= i__2; ++j) {
/* L390: */
/* Computing 2nd power */
	    d__1 = xpt[k + j * xpt_dim1] - xopt[j];
	    distsq += d__1 * d__1;
	}
	if (distsq > rhosq) {
/* Computing 3rd power */
	    d__1 = distsq / rhosq;
	    temp *= d__1 * (d__1 * d__1);
	}
	if (temp > detrat && k != ktemp) {
	    detrat = temp;
	    knew = k;
	}
/* L400: */
    }
    if (knew == 0) {
	goto L460;
    }

/*     Update BMAT, ZMAT and IDZ, so that the KNEW-th interpolation point */
/*     can be moved. Begin the updating of the quadratic model, starting */
/*     with the explicit second derivative term. */

L410:
    update_(n, npt, &bmat[bmat_offset], &zmat[zmat_offset], &idz, ndim, &vlag[
	    1], &beta, &knew, &w[1]);
    fval[knew] = f;
    ih = 0;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	temp = pq[knew] * xpt[knew + i__ * xpt_dim1];
	i__2 = i__;
	for (j = 1; j <= i__2; ++j) {
	    ++ih;
/* L420: */
	    hq[ih] += temp * xpt[knew + j * xpt_dim1];
	}
    }
    pq[knew] = zero;

/*     Update the other second derivative parameters, and then the gradient */
/*     vector of the model. Also include the new interpolation point. */

    i__2 = nptm;
    for (j = 1; j <= i__2; ++j) {
	temp = diff * zmat[knew + j * zmat_dim1];
	if (j < idz) {
	    temp = -temp;
	}
	i__1 = *npt;
	for (k = 1; k <= i__1; ++k) {
/* L440: */
	    pq[k] += temp * zmat[k + j * zmat_dim1];
	}
    }
    gqsq = zero;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	gq[i__] += diff * bmat[knew + i__ * bmat_dim1];
/* Computing 2nd power */
	d__1 = gq[i__];
	gqsq += d__1 * d__1;
/* L450: */
	xpt[knew + i__ * xpt_dim1] = xnew[i__];
    }

/*     If a trust region step makes a small change to the objective function, */
/*     then calculate the gradient of the least Frobenius norm interpolant at */
/*     XBASE, and store it in W, using VLAG for a vector of right hand sides. */

    if (ksave == 0 && delta == rho) {
	if (abs(ratio) > .01) {
	    itest = 0;
	} else {
	    i__1 = *npt;
	    for (k = 1; k <= i__1; ++k) {
/* L700: */
		vlag[k] = fval[k] - fval[kopt];
	    }
	    gisq = zero;
	    i__1 = *n;
	    for (i__ = 1; i__ <= i__1; ++i__) {
		sum = zero;
		i__2 = *npt;
		for (k = 1; k <= i__2; ++k) {
/* L710: */
		    sum += bmat[k + i__ * bmat_dim1] * vlag[k];
		}
		gisq += sum * sum;
/* L720: */
		w[i__] = sum;
	    }

/*     Test whether to replace the new quadratic model by the least Frobenius */
/*     norm interpolant, making the replacement if the test is satisfied. */

	    ++itest;
	    if (gqsq < gisq * 100.) {
		itest = 0;
	    }
	    if (itest >= 3) {
		i__1 = *n;
		for (i__ = 1; i__ <= i__1; ++i__) {
/* L730: */
		    gq[i__] = w[i__];
		}
		i__1 = nh;
		for (ih = 1; ih <= i__1; ++ih) {
/* L740: */
		    hq[ih] = zero;
		}
		i__1 = nptm;
		for (j = 1; j <= i__1; ++j) {
		    w[j] = zero;
		    i__2 = *npt;
		    for (k = 1; k <= i__2; ++k) {
/* L750: */
			w[j] += vlag[k] * zmat[k + j * zmat_dim1];
		    }
/* L760: */
		    if (j < idz) {
			w[j] = -w[j];
		    }
		}
		i__1 = *npt;
		for (k = 1; k <= i__1; ++k) {
		    pq[k] = zero;
		    i__2 = nptm;
		    for (j = 1; j <= i__2; ++j) {
/* L770: */
			pq[k] += zmat[k + j * zmat_dim1] * w[j];
		    }
		}
		itest = 0;
	    }
	}
    }
    if (f < fsave) {
	kopt = knew;
    }

/*     If a trust region step has provided a sufficient decrease in F, then */
/*     branch for another trust region calculation. The case KSAVE>0 occurs */
/*     when the new function value was calculated by a model step. */

    if (f <= fsave + tenth * vquad) {
	goto L100;
    }
    if (ksave > 0) {
	goto L100;
    }

/*     Alternatively, find out if the interpolation points are close enough */
/*     to the best point so far. */

    knew = 0;
L460:
    distsq = delta * 4. * delta;
    i__2 = *npt;
    for (k = 1; k <= i__2; ++k) {
	sum = zero;
	i__1 = *n;
	for (j = 1; j <= i__1; ++j) {
/* L470: */
/* Computing 2nd power */
	    d__1 = xpt[k + j * xpt_dim1] - xopt[j];
	    sum += d__1 * d__1;
	}
	if (sum > distsq) {
	    knew = k;
	    distsq = sum;
	}
/* L480: */
    }

/*     If KNEW is positive, then set DSTEP, and branch back for the next */
/*     iteration, which will generate a "model step". */

    if (knew > 0) {
/* Computing MAX */
/* Computing MIN */
	d__2 = tenth * sqrt(distsq), d__3 = half * delta;
	d__1 = min(d__2,d__3);
	dstep = max(d__1,rho);
	dsq = dstep * dstep;
	goto L120;
    }
    if (ratio > zero) {
	goto L100;
    }
    if (max(delta,dnorm) > rho) {
	goto L100;
    }

/*     The calculations with the current value of RHO are complete. Pick the */
/*     next values of RHO and DELTA. */

L490:
    if (rho > *rhoend) {
	delta = half * rho;
	ratio = rho / *rhoend;
	if (ratio <= 16.) {
	    rho = *rhoend;
	} else if (ratio <= 250.) {
	    rho = sqrt(ratio) * *rhoend;
	} else {
	    rho = tenth * rho;
	}
	delta = max(delta,rho);
	if (*iprint >= 2) {
	    if (*iprint >= 3) {
		s_wsfe(&io___68);
		e_wsfe();
	    }
	    s_wsfe(&io___69);
	    do_fio(&c__1, (char *)&rho, (ftnlen)sizeof(doublereal));
	    do_fio(&c__1, (char *)&nf, (ftnlen)sizeof(integer));
	    e_wsfe();
	    s_wsfe(&io___70);
	    do_fio(&c__1, (char *)&fopt, (ftnlen)sizeof(doublereal));
	    i__2 = *n;
	    for (i__ = 1; i__ <= i__2; ++i__) {
		d__1 = xbase[i__] + xopt[i__];
		do_fio(&c__1, (char *)&d__1, (ftnlen)sizeof(doublereal));
	    }
	    e_wsfe();
	}
	goto L90;
    }

/*     Return from the calculation, after another Newton-Raphson step, if */
/*     it is too short to have been tried before. */

    if (knew == -1) {
	goto L290;
    }
L530:
    if (fopt <= f) {
	i__2 = *n;
	for (i__ = 1; i__ <= i__2; ++i__) {
/* L540: */
	    x[i__] = xbase[i__] + xopt[i__];
	}
	f = fopt;
    }
    if (*iprint >= 1) {
	s_wsfe(&io___71);
	do_fio(&c__1, (char *)&nf, (ftnlen)sizeof(integer));
	e_wsfe();
	s_wsfe(&io___72);
	do_fio(&c__1, (char *)&f, (ftnlen)sizeof(doublereal));
	i__2 = *n;
	for (i__ = 1; i__ <= i__2; ++i__) {
	    do_fio(&c__1, (char *)&x[i__], (ftnlen)sizeof(doublereal));
	}
	e_wsfe();
    }
    return 0;
} /* newuob_ */

