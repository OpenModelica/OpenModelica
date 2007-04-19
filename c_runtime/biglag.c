/* biglag.f -- translated by f2c (version 20041007).
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

/* Subroutine */ int biglag_(integer *n, integer *npt, doublereal *xopt, 
	doublereal *xpt, doublereal *bmat, doublereal *zmat, integer *idz, 
	integer *ndim, integer *knew, doublereal *delta, doublereal *d__, 
	doublereal *alpha, doublereal *hcol, doublereal *gc, doublereal *gd, 
	doublereal *s, doublereal *w)
{
    /* System generated locals */
    integer xpt_dim1, xpt_offset, bmat_dim1, bmat_offset, zmat_dim1, 
	    zmat_offset, i__1, i__2;
    doublereal d__1;

    /* Builtin functions */
    double atan(doublereal), sqrt(doublereal), cos(doublereal), sin(
	    doublereal);

    /* Local variables */
    static integer i__, j, k;
    static doublereal dd, gg;
    static integer iu;
    static doublereal sp, ss, cf1, cf2, cf3, cf4, cf5, dhd, cth, one, tau, 
	    sth, sum, half, temp, step;
    static integer nptm;
    static doublereal zero, angle, scale, denom;
    static integer iterc, isave;
    static doublereal delsq, tempa, tempb, twopi, taubeg, tauold, taumax;


/*     N is the number of variables. */
/*     NPT is the number of interpolation equations. */
/*     XOPT is the best interpolation point so far. */
/*     XPT contains the coordinates of the current interpolation points. */
/*     BMAT provides the last N columns of H. */
/*     ZMAT and IDZ give a factorization of the first NPT by NPT submatrix of H. */
/*     NDIM is the first dimension of BMAT and has the value NPT+N. */
/*     KNEW is the index of the interpolation point that is going to be moved. */
/*     DELTA is the current trust region bound. */
/*     D will be set to the step from XOPT to the new point. */
/*     ALPHA will be set to the KNEW-th diagonal element of the H matrix. */
/*     HCOL, GC, GD, S and W will be used for working space. */

/*     The step D is calculated in a way that attempts to maximize the modulus */
/*     of LFUNC(XOPT+D), subject to the bound ||D|| .LE. DELTA, where LFUNC is */
/*     the KNEW-th Lagrange function. */

/*     Set some constants. */

    /* Parameter adjustments */
    zmat_dim1 = *npt;
    zmat_offset = 1 + zmat_dim1;
    zmat -= zmat_offset;
    xpt_dim1 = *npt;
    xpt_offset = 1 + xpt_dim1;
    xpt -= xpt_offset;
    --xopt;
    bmat_dim1 = *ndim;
    bmat_offset = 1 + bmat_dim1;
    bmat -= bmat_offset;
    --d__;
    --hcol;
    --gc;
    --gd;
    --s;
    --w;

    /* Function Body */
    half = .5;
    one = 1.;
    zero = 0.;
    twopi = atan(one) * 8.;
    delsq = *delta * *delta;
    nptm = *npt - *n - 1;

/*     Set the first NPT components of HCOL to the leading elements of the */
/*     KNEW-th column of H. */

    iterc = 0;
    i__1 = *npt;
    for (k = 1; k <= i__1; ++k) {
/* L10: */
	hcol[k] = zero;
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
	    hcol[k] += temp * zmat[k + j * zmat_dim1];
	}
    }
    *alpha = hcol[*knew];

/*     Set the unscaled initial direction D. Form the gradient of LFUNC at */
/*     XOPT, and multiply D by the second derivative matrix of LFUNC. */

    dd = zero;
    i__2 = *n;
    for (i__ = 1; i__ <= i__2; ++i__) {
	d__[i__] = xpt[*knew + i__ * xpt_dim1] - xopt[i__];
	gc[i__] = bmat[*knew + i__ * bmat_dim1];
	gd[i__] = zero;
/* L30: */
/* Computing 2nd power */
	d__1 = d__[i__];
	dd += d__1 * d__1;
    }
    i__2 = *npt;
    for (k = 1; k <= i__2; ++k) {
	temp = zero;
	sum = zero;
	i__1 = *n;
	for (j = 1; j <= i__1; ++j) {
	    temp += xpt[k + j * xpt_dim1] * xopt[j];
/* L40: */
	    sum += xpt[k + j * xpt_dim1] * d__[j];
	}
	temp = hcol[k] * temp;
	sum = hcol[k] * sum;
	i__1 = *n;
	for (i__ = 1; i__ <= i__1; ++i__) {
	    gc[i__] += temp * xpt[k + i__ * xpt_dim1];
/* L50: */
	    gd[i__] += sum * xpt[k + i__ * xpt_dim1];
	}
    }

/*     Scale D and GD, with a sign change if required. Set S to another */
/*     vector in the initial two dimensional subspace. */

    gg = zero;
    sp = zero;
    dhd = zero;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* Computing 2nd power */
	d__1 = gc[i__];
	gg += d__1 * d__1;
	sp += d__[i__] * gc[i__];
/* L60: */
	dhd += d__[i__] * gd[i__];
    }
    scale = *delta / sqrt(dd);
    if (sp * dhd < zero) {
	scale = -scale;
    }
    temp = zero;
    if (sp * sp > dd * .99 * gg) {
	temp = one;
    }
    tau = scale * (abs(sp) + half * scale * abs(dhd));
    if (gg * delsq < tau * .01 * tau) {
	temp = one;
    }
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	d__[i__] = scale * d__[i__];
	gd[i__] = scale * gd[i__];
/* L70: */
	s[i__] = gc[i__] + temp * gd[i__];
    }

/*     Begin the iteration by overwriting S with a vector that has the */
/*     required length and direction, except that termination occurs if */
/*     the given D and S are nearly parallel. */

L80:
    ++iterc;
    dd = zero;
    sp = zero;
    ss = zero;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* Computing 2nd power */
	d__1 = d__[i__];
	dd += d__1 * d__1;
	sp += d__[i__] * s[i__];
/* L90: */
/* Computing 2nd power */
	d__1 = s[i__];
	ss += d__1 * d__1;
    }
    temp = dd * ss - sp * sp;
    if (temp <= dd * 1e-8 * ss) {
	goto L160;
    }
    denom = sqrt(temp);
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	s[i__] = (dd * s[i__] - sp * d__[i__]) / denom;
/* L100: */
	w[i__] = zero;
    }

/*     Calculate the coefficients of the objective function on the circle, */
/*     beginning with the multiplication of S by the second derivative matrix. */

    i__1 = *npt;
    for (k = 1; k <= i__1; ++k) {
	sum = zero;
	i__2 = *n;
	for (j = 1; j <= i__2; ++j) {
/* L110: */
	    sum += xpt[k + j * xpt_dim1] * s[j];
	}
	sum = hcol[k] * sum;
	i__2 = *n;
	for (i__ = 1; i__ <= i__2; ++i__) {
/* L120: */
	    w[i__] += sum * xpt[k + i__ * xpt_dim1];
	}
    }
    cf1 = zero;
    cf2 = zero;
    cf3 = zero;
    cf4 = zero;
    cf5 = zero;
    i__2 = *n;
    for (i__ = 1; i__ <= i__2; ++i__) {
	cf1 += s[i__] * w[i__];
	cf2 += d__[i__] * gc[i__];
	cf3 += s[i__] * gc[i__];
	cf4 += d__[i__] * gd[i__];
/* L130: */
	cf5 += s[i__] * gd[i__];
    }
    cf1 = half * cf1;
    cf4 = half * cf4 - cf1;

/*     Seek the value of the angle that maximizes the modulus of TAU. */

    taubeg = cf1 + cf2 + cf4;
    taumax = taubeg;
    tauold = taubeg;
    isave = 0;
    iu = 49;
    temp = twopi / (doublereal) (iu + 1);
    i__2 = iu;
    for (i__ = 1; i__ <= i__2; ++i__) {
	angle = (doublereal) i__ * temp;
	cth = cos(angle);
	sth = sin(angle);
	tau = cf1 + (cf2 + cf4 * cth) * cth + (cf3 + cf5 * cth) * sth;
	if (abs(tau) > abs(taumax)) {
	    taumax = tau;
	    isave = i__;
	    tempa = tauold;
	} else if (i__ == isave + 1) {
	    tempb = tau;
	}
/* L140: */
	tauold = tau;
    }
    if (isave == 0) {
	tempa = tau;
    }
    if (isave == iu) {
	tempb = taubeg;
    }
    step = zero;
    if (tempa != tempb) {
	tempa -= taumax;
	tempb -= taumax;
	step = half * (tempa - tempb) / (tempa + tempb);
    }
    angle = temp * ((doublereal) isave + step);

/*     Calculate the new D and GD. Then test for convergence. */

    cth = cos(angle);
    sth = sin(angle);
    tau = cf1 + (cf2 + cf4 * cth) * cth + (cf3 + cf5 * cth) * sth;
    i__2 = *n;
    for (i__ = 1; i__ <= i__2; ++i__) {
	d__[i__] = cth * d__[i__] + sth * s[i__];
	gd[i__] = cth * gd[i__] + sth * w[i__];
/* L150: */
	s[i__] = gc[i__] + gd[i__];
    }
    if (abs(tau) <= abs(taubeg) * 1.1) {
	goto L160;
    }
    if (iterc < *n) {
	goto L80;
    }
L160:
    return 0;
} /* biglag_ */

