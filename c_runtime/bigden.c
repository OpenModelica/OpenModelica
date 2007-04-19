/* bigden.f -- translated by f2c (version 20041007).
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

/* Subroutine */ int bigden_(integer *n, integer *npt, doublereal *xopt, 
	doublereal *xpt, doublereal *bmat, doublereal *zmat, integer *idz, 
	integer *ndim, integer *kopt, integer *knew, doublereal *d__, 
	doublereal *w, doublereal *vlag, doublereal *beta, doublereal *s, 
	doublereal *wvec, doublereal *prod)
{
    /* System generated locals */
    integer xpt_dim1, xpt_offset, bmat_dim1, bmat_offset, zmat_dim1, 
	    zmat_offset, wvec_dim1, wvec_offset, prod_dim1, prod_offset, i__1,
	     i__2;
    doublereal d__1;

    /* Builtin functions */
    double atan(doublereal), sqrt(doublereal), cos(doublereal), sin(
	    doublereal);

    /* Local variables */
    static integer i__, j, k;
    static doublereal dd;
    static integer jc;
    static doublereal ds;
    static integer ip, iu, nw;
    static doublereal ss, den[9], one, par[9], tau, sum, two, diff, half, 
	    temp;
    static integer ksav;
    static doublereal step;
    static integer nptm;
    static doublereal zero, alpha, angle, denex[9];
    static integer iterc;
    static doublereal tempa, tempb, tempc;
    static integer isave;
    static doublereal ssden, dtest, quart, xoptd, twopi, xopts, denold, 
	    denmax, densav, dstemp, sumold, sstemp, xoptsq;


/*     N is the number of variables. */
/*     NPT is the number of interpolation equations. */
/*     XOPT is the best interpolation point so far. */
/*     XPT contains the coordinates of the current interpolation points. */
/*     BMAT provides the last N columns of H. */
/*     ZMAT and IDZ give a factorization of the first NPT by NPT submatrix of H. */
/*     NDIM is the first dimension of BMAT and has the value NPT+N. */
/*     KOPT is the index of the optimal interpolation point. */
/*     KNEW is the index of the interpolation point that is going to be moved. */
/*     D will be set to the step from XOPT to the new point, and on entry it */
/*       should be the D that was calculated by the last call of BIGLAG. The */
/*       length of the initial D provides a trust region bound on the final D. */
/*     W will be set to Wcheck for the final choice of D. */
/*     VLAG will be set to Theta*Wcheck+e_b for the final choice of D. */
/*     BETA will be set to the value that will occur in the updating formula */
/*       when the KNEW-th interpolation point is moved to its new position. */
/*     S, WVEC, PROD and the private arrays DEN, DENEX and PAR will be used */
/*       for working space. */

/*     D is calculated in a way that should provide a denominator with a large */
/*     modulus in the updating formula when the KNEW-th interpolation point is */
/*     shifted to the new position XOPT+D. */

/*     Set some constants. */

    /* Parameter adjustments */
    zmat_dim1 = *npt;
    zmat_offset = 1 + zmat_dim1;
    zmat -= zmat_offset;
    xpt_dim1 = *npt;
    xpt_offset = 1 + xpt_dim1;
    xpt -= xpt_offset;
    --xopt;
    prod_dim1 = *ndim;
    prod_offset = 1 + prod_dim1;
    prod -= prod_offset;
    wvec_dim1 = *ndim;
    wvec_offset = 1 + wvec_dim1;
    wvec -= wvec_offset;
    bmat_dim1 = *ndim;
    bmat_offset = 1 + bmat_dim1;
    bmat -= bmat_offset;
    --d__;
    --w;
    --vlag;
    --s;

    /* Function Body */
    half = .5;
    one = 1.;
    quart = .25;
    two = 2.;
    zero = 0.;
    twopi = atan(one) * 8.;
    nptm = *npt - *n - 1;

/*     Store the first NPT elements of the KNEW-th column of H in W(N+1) */
/*     to W(N+NPT). */

    i__1 = *npt;
    for (k = 1; k <= i__1; ++k) {
/* L10: */
	w[*n + k] = zero;
    }
    i__1 = nptm;
    for (j = 1; j <= i__1; ++j) {
	temp = zmat[*knew + j * zmat_dim1];
	if (j < *idz) {
	    temp = -temp;
	}
	i__2 = *npt;
	for (k = 1; k <= i__2; ++k) {
/* L20: */
	    w[*n + k] += temp * zmat[k + j * zmat_dim1];
	}
    }
    alpha = w[*n + *knew];

/*     The initial search direction D is taken from the last call of BIGLAG, */
/*     and the initial S is set below, usually to the direction from X_OPT */
/*     to X_KNEW, but a different direction to an interpolation point may */
/*     be chosen, in order to prevent S from being nearly parallel to D. */

    dd = zero;
    ds = zero;
    ss = zero;
    xoptsq = zero;
    i__2 = *n;
    for (i__ = 1; i__ <= i__2; ++i__) {
/* Computing 2nd power */
	d__1 = d__[i__];
	dd += d__1 * d__1;
	s[i__] = xpt[*knew + i__ * xpt_dim1] - xopt[i__];
	ds += d__[i__] * s[i__];
/* Computing 2nd power */
	d__1 = s[i__];
	ss += d__1 * d__1;
/* L30: */
/* Computing 2nd power */
	d__1 = xopt[i__];
	xoptsq += d__1 * d__1;
    }
    if (ds * ds > dd * .99 * ss) {
	ksav = *knew;
	dtest = ds * ds / ss;
	i__2 = *npt;
	for (k = 1; k <= i__2; ++k) {
	    if (k != *kopt) {
		dstemp = zero;
		sstemp = zero;
		i__1 = *n;
		for (i__ = 1; i__ <= i__1; ++i__) {
		    diff = xpt[k + i__ * xpt_dim1] - xopt[i__];
		    dstemp += d__[i__] * diff;
/* L40: */
		    sstemp += diff * diff;
		}
		if (dstemp * dstemp / sstemp < dtest) {
		    ksav = k;
		    dtest = dstemp * dstemp / sstemp;
		    ds = dstemp;
		    ss = sstemp;
		}
	    }
/* L50: */
	}
	i__2 = *n;
	for (i__ = 1; i__ <= i__2; ++i__) {
/* L60: */
	    s[i__] = xpt[ksav + i__ * xpt_dim1] - xopt[i__];
	}
    }
    ssden = dd * ss - ds * ds;
    iterc = 0;
    densav = zero;

/*     Begin the iteration by overwriting S with a vector that has the */
/*     required length and direction. */

L70:
    ++iterc;
    temp = one / sqrt(ssden);
    xoptd = zero;
    xopts = zero;
    i__2 = *n;
    for (i__ = 1; i__ <= i__2; ++i__) {
	s[i__] = temp * (dd * s[i__] - ds * d__[i__]);
	xoptd += xopt[i__] * d__[i__];
/* L80: */
	xopts += xopt[i__] * s[i__];
    }

/*     Set the coefficients of the first two terms of BETA. */

    tempa = half * xoptd * xoptd;
    tempb = half * xopts * xopts;
    den[0] = dd * (xoptsq + half * dd) + tempa + tempb;
    den[1] = two * xoptd * dd;
    den[2] = two * xopts * dd;
    den[3] = tempa - tempb;
    den[4] = xoptd * xopts;
    for (i__ = 6; i__ <= 9; ++i__) {
/* L90: */
	den[i__ - 1] = zero;
    }

/*     Put the coefficients of Wcheck in WVEC. */

    i__2 = *npt;
    for (k = 1; k <= i__2; ++k) {
	tempa = zero;
	tempb = zero;
	tempc = zero;
	i__1 = *n;
	for (i__ = 1; i__ <= i__1; ++i__) {
	    tempa += xpt[k + i__ * xpt_dim1] * d__[i__];
	    tempb += xpt[k + i__ * xpt_dim1] * s[i__];
/* L100: */
	    tempc += xpt[k + i__ * xpt_dim1] * xopt[i__];
	}
	wvec[k + wvec_dim1] = quart * (tempa * tempa + tempb * tempb);
	wvec[k + (wvec_dim1 << 1)] = tempa * tempc;
	wvec[k + wvec_dim1 * 3] = tempb * tempc;
	wvec[k + (wvec_dim1 << 2)] = quart * (tempa * tempa - tempb * tempb);
/* L110: */
	wvec[k + wvec_dim1 * 5] = half * tempa * tempb;
    }
    i__2 = *n;
    for (i__ = 1; i__ <= i__2; ++i__) {
	ip = i__ + *npt;
	wvec[ip + wvec_dim1] = zero;
	wvec[ip + (wvec_dim1 << 1)] = d__[i__];
	wvec[ip + wvec_dim1 * 3] = s[i__];
	wvec[ip + (wvec_dim1 << 2)] = zero;
/* L120: */
	wvec[ip + wvec_dim1 * 5] = zero;
    }

/*     Put the coefficents of THETA*Wcheck in PROD. */

    for (jc = 1; jc <= 5; ++jc) {
	nw = *npt;
	if (jc == 2 || jc == 3) {
	    nw = *ndim;
	}
	i__2 = *npt;
	for (k = 1; k <= i__2; ++k) {
/* L130: */
	    prod[k + jc * prod_dim1] = zero;
	}
	i__2 = nptm;
	for (j = 1; j <= i__2; ++j) {
	    sum = zero;
	    i__1 = *npt;
	    for (k = 1; k <= i__1; ++k) {
/* L140: */
		sum += zmat[k + j * zmat_dim1] * wvec[k + jc * wvec_dim1];
	    }
	    if (j < *idz) {
		sum = -sum;
	    }
	    i__1 = *npt;
	    for (k = 1; k <= i__1; ++k) {
/* L150: */
		prod[k + jc * prod_dim1] += sum * zmat[k + j * zmat_dim1];
	    }
	}
	if (nw == *ndim) {
	    i__1 = *npt;
	    for (k = 1; k <= i__1; ++k) {
		sum = zero;
		i__2 = *n;
		for (j = 1; j <= i__2; ++j) {
/* L160: */
		    sum += bmat[k + j * bmat_dim1] * wvec[*npt + j + jc * 
			    wvec_dim1];
		}
/* L170: */
		prod[k + jc * prod_dim1] += sum;
	    }
	}
	i__1 = *n;
	for (j = 1; j <= i__1; ++j) {
	    sum = zero;
	    i__2 = nw;
	    for (i__ = 1; i__ <= i__2; ++i__) {
/* L180: */
		sum += bmat[i__ + j * bmat_dim1] * wvec[i__ + jc * wvec_dim1];
	    }
/* L190: */
	    prod[*npt + j + jc * prod_dim1] = sum;
	}
    }

/*     Include in DEN the part of BETA that depends on THETA. */

    i__1 = *ndim;
    for (k = 1; k <= i__1; ++k) {
	sum = zero;
	for (i__ = 1; i__ <= 5; ++i__) {
	    par[i__ - 1] = half * prod[k + i__ * prod_dim1] * wvec[k + i__ * 
		    wvec_dim1];
/* L200: */
	    sum += par[i__ - 1];
	}
	den[0] = den[0] - par[0] - sum;
	tempa = prod[k + prod_dim1] * wvec[k + (wvec_dim1 << 1)] + prod[k + (
		prod_dim1 << 1)] * wvec[k + wvec_dim1];
	tempb = prod[k + (prod_dim1 << 1)] * wvec[k + (wvec_dim1 << 2)] + 
		prod[k + (prod_dim1 << 2)] * wvec[k + (wvec_dim1 << 1)];
	tempc = prod[k + prod_dim1 * 3] * wvec[k + wvec_dim1 * 5] + prod[k + 
		prod_dim1 * 5] * wvec[k + wvec_dim1 * 3];
	den[1] = den[1] - tempa - half * (tempb + tempc);
	den[5] -= half * (tempb - tempc);
	tempa = prod[k + prod_dim1] * wvec[k + wvec_dim1 * 3] + prod[k + 
		prod_dim1 * 3] * wvec[k + wvec_dim1];
	tempb = prod[k + (prod_dim1 << 1)] * wvec[k + wvec_dim1 * 5] + prod[k 
		+ prod_dim1 * 5] * wvec[k + (wvec_dim1 << 1)];
	tempc = prod[k + prod_dim1 * 3] * wvec[k + (wvec_dim1 << 2)] + prod[k 
		+ (prod_dim1 << 2)] * wvec[k + wvec_dim1 * 3];
	den[2] = den[2] - tempa - half * (tempb - tempc);
	den[6] -= half * (tempb + tempc);
	tempa = prod[k + prod_dim1] * wvec[k + (wvec_dim1 << 2)] + prod[k + (
		prod_dim1 << 2)] * wvec[k + wvec_dim1];
	den[3] = den[3] - tempa - par[1] + par[2];
	tempa = prod[k + prod_dim1] * wvec[k + wvec_dim1 * 5] + prod[k + 
		prod_dim1 * 5] * wvec[k + wvec_dim1];
	tempb = prod[k + (prod_dim1 << 1)] * wvec[k + wvec_dim1 * 3] + prod[k 
		+ prod_dim1 * 3] * wvec[k + (wvec_dim1 << 1)];
	den[4] = den[4] - tempa - half * tempb;
	den[7] = den[7] - par[3] + par[4];
	tempa = prod[k + (prod_dim1 << 2)] * wvec[k + wvec_dim1 * 5] + prod[k 
		+ prod_dim1 * 5] * wvec[k + (wvec_dim1 << 2)];
/* L210: */
	den[8] -= half * tempa;
    }

/*     Extend DEN so that it holds all the coefficients of DENOM. */

    sum = zero;
    for (i__ = 1; i__ <= 5; ++i__) {
/* Computing 2nd power */
	d__1 = prod[*knew + i__ * prod_dim1];
	par[i__ - 1] = half * (d__1 * d__1);
/* L220: */
	sum += par[i__ - 1];
    }
    denex[0] = alpha * den[0] + par[0] + sum;
    tempa = two * prod[*knew + prod_dim1] * prod[*knew + (prod_dim1 << 1)];
    tempb = prod[*knew + (prod_dim1 << 1)] * prod[*knew + (prod_dim1 << 2)];
    tempc = prod[*knew + prod_dim1 * 3] * prod[*knew + prod_dim1 * 5];
    denex[1] = alpha * den[1] + tempa + tempb + tempc;
    denex[5] = alpha * den[5] + tempb - tempc;
    tempa = two * prod[*knew + prod_dim1] * prod[*knew + prod_dim1 * 3];
    tempb = prod[*knew + (prod_dim1 << 1)] * prod[*knew + prod_dim1 * 5];
    tempc = prod[*knew + prod_dim1 * 3] * prod[*knew + (prod_dim1 << 2)];
    denex[2] = alpha * den[2] + tempa + tempb - tempc;
    denex[6] = alpha * den[6] + tempb + tempc;
    tempa = two * prod[*knew + prod_dim1] * prod[*knew + (prod_dim1 << 2)];
    denex[3] = alpha * den[3] + tempa + par[1] - par[2];
    tempa = two * prod[*knew + prod_dim1] * prod[*knew + prod_dim1 * 5];
    denex[4] = alpha * den[4] + tempa + prod[*knew + (prod_dim1 << 1)] * prod[
	    *knew + prod_dim1 * 3];
    denex[7] = alpha * den[7] + par[3] - par[4];
    denex[8] = alpha * den[8] + prod[*knew + (prod_dim1 << 2)] * prod[*knew + 
	    prod_dim1 * 5];

/*     Seek the value of the angle that maximizes the modulus of DENOM. */

    sum = denex[0] + denex[1] + denex[3] + denex[5] + denex[7];
    denold = sum;
    denmax = sum;
    isave = 0;
    iu = 49;
    temp = twopi / (doublereal) (iu + 1);
    par[0] = one;
    i__1 = iu;
    for (i__ = 1; i__ <= i__1; ++i__) {
	angle = (doublereal) i__ * temp;
	par[1] = cos(angle);
	par[2] = sin(angle);
	for (j = 4; j <= 8; j += 2) {
	    par[j - 1] = par[1] * par[j - 3] - par[2] * par[j - 2];
/* L230: */
	    par[j] = par[1] * par[j - 2] + par[2] * par[j - 3];
	}
	sumold = sum;
	sum = zero;
	for (j = 1; j <= 9; ++j) {
/* L240: */
	    sum += denex[j - 1] * par[j - 1];
	}
	if (abs(sum) > abs(denmax)) {
	    denmax = sum;
	    isave = i__;
	    tempa = sumold;
	} else if (i__ == isave + 1) {
	    tempb = sum;
	}
/* L250: */
    }
    if (isave == 0) {
	tempa = sum;
    }
    if (isave == iu) {
	tempb = denold;
    }
    step = zero;
    if (tempa != tempb) {
	tempa -= denmax;
	tempb -= denmax;
	step = half * (tempa - tempb) / (tempa + tempb);
    }
    angle = temp * ((doublereal) isave + step);

/*     Calculate the new parameters of the denominator, the new VLAG vector */
/*     and the new D. Then test for convergence. */

    par[1] = cos(angle);
    par[2] = sin(angle);
    for (j = 4; j <= 8; j += 2) {
	par[j - 1] = par[1] * par[j - 3] - par[2] * par[j - 2];
/* L260: */
	par[j] = par[1] * par[j - 2] + par[2] * par[j - 3];
    }
    *beta = zero;
    denmax = zero;
    for (j = 1; j <= 9; ++j) {
	*beta += den[j - 1] * par[j - 1];
/* L270: */
	denmax += denex[j - 1] * par[j - 1];
    }
    i__1 = *ndim;
    for (k = 1; k <= i__1; ++k) {
	vlag[k] = zero;
	for (j = 1; j <= 5; ++j) {
/* L280: */
	    vlag[k] += prod[k + j * prod_dim1] * par[j - 1];
	}
    }
    tau = vlag[*knew];
    dd = zero;
    tempa = zero;
    tempb = zero;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	d__[i__] = par[1] * d__[i__] + par[2] * s[i__];
	w[i__] = xopt[i__] + d__[i__];
/* Computing 2nd power */
	d__1 = d__[i__];
	dd += d__1 * d__1;
	tempa += d__[i__] * w[i__];
/* L290: */
	tempb += w[i__] * w[i__];
    }
    if (iterc >= *n) {
	goto L340;
    }
    if (iterc > 1) {
	densav = max(densav,denold);
    }
    if (abs(denmax) <= abs(densav) * 1.1) {
	goto L340;
    }
    densav = denmax;

/*     Set S to half the gradient of the denominator with respect to D. */
/*     Then branch for the next iteration. */

    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	temp = tempa * xopt[i__] + tempb * d__[i__] - vlag[*npt + i__];
/* L300: */
	s[i__] = tau * bmat[*knew + i__ * bmat_dim1] + alpha * temp;
    }
    i__1 = *npt;
    for (k = 1; k <= i__1; ++k) {
	sum = zero;
	i__2 = *n;
	for (j = 1; j <= i__2; ++j) {
/* L310: */
	    sum += xpt[k + j * xpt_dim1] * w[j];
	}
	temp = (tau * w[*n + k] - alpha * vlag[k]) * sum;
	i__2 = *n;
	for (i__ = 1; i__ <= i__2; ++i__) {
/* L320: */
	    s[i__] += temp * xpt[k + i__ * xpt_dim1];
	}
    }
    ss = zero;
    ds = zero;
    i__2 = *n;
    for (i__ = 1; i__ <= i__2; ++i__) {
/* Computing 2nd power */
	d__1 = s[i__];
	ss += d__1 * d__1;
/* L330: */
	ds += d__[i__] * s[i__];
    }
    ssden = dd * ss - ds * ds;
    if (ssden >= dd * 1e-8 * ss) {
	goto L70;
    }

/*     Set the vector W before the RETURN from the subroutine. */

L340:
    i__2 = *ndim;
    for (k = 1; k <= i__2; ++k) {
	w[k] = zero;
	for (j = 1; j <= 5; ++j) {
/* L350: */
	    w[k] += wvec[k + j * wvec_dim1] * par[j - 1];
	}
    }
    vlag[*kopt] += one;
    return 0;
} /* bigden_ */

