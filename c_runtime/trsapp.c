/* trsapp.f -- translated by f2c (version 20041007).
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

/* Subroutine */ int trsapp_(integer *n, integer *npt, doublereal *xopt,
	doublereal *xpt, doublereal *gq, doublereal *hq, doublereal *pq,
	doublereal *delta, doublereal *step, doublereal *d__, doublereal *g,
	doublereal *hd, doublereal *hs, doublereal *crvmin)
{
    /* System generated locals */
    integer xpt_dim1, xpt_offset, i__1, i__2;
    doublereal d__1, d__2;

    /* Builtin functions */
    double atan(doublereal), sqrt(doublereal), cos(doublereal), sin(
	    doublereal);

    /* Local variables */
    static integer i__, j, k;
    static doublereal dd, cf, dg, gg;
    static integer ih;
    static doublereal ds, sg;
    static integer iu;
    static doublereal ss, dhd, dhs, cth, sgk, shs, sth, qadd, half, qbeg,
	    qred, qmin, temp, qsav, qnew, zero, ggbeg, alpha, angle, reduc;
    static integer iterc;
    static doublereal ggsav, delsq, tempa, tempb;
    static integer isave;
    static doublereal bstep, ratio, twopi;
    static integer itersw;
    static doublereal angtest;
    static integer itermax;


/*     N is the number of variables of a quadratic objective function, Q say. */
/*     The arguments NPT, XOPT, XPT, GQ, HQ and PQ have their usual meanings, */
/*       in order to define the current quadratic model Q. */
/*     DELTA is the trust region radius, and has to be positive. */
/*     STEP will be set to the calculated trial step. */
/*     The arrays D, G, HD and HS will be used for working space. */
/*     CRVMIN will be set to the least curvature of H along the conjugate */
/*       directions that occur, except that it is set to zero if STEP goes */
/*       all the way to the trust region boundary. */

/*     The calculation of STEP begins with the truncated conjugate gradient */
/*     method. If the boundary of the trust region is reached, then further */
/*     changes to STEP may be made, each one being in the 2D space spanned */
/*     by the current STEP and the corresponding gradient of Q. Thus STEP */
/*     should provide a substantial reduction to Q within the trust region. */

/*     Initialization, which includes setting HD to H times XOPT. */

    /* Parameter adjustments */
    xpt_dim1 = *npt;
    xpt_offset = 1 + xpt_dim1;
    xpt -= xpt_offset;
    --xopt;
    --gq;
    --hq;
    --pq;
    --step;
    --d__;
    --g;
    --hd;
    --hs;

    /* Function Body */
    half = .5;
    zero = 0.;
    twopi = atan(1.) * 8.;
    delsq = *delta * *delta;
    iterc = 0;
    itermax = *n;
    itersw = itermax;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L10: */
	d__[i__] = xopt[i__];
    }
    goto L170;

/*     Prepare for the first line search. */

L20:
    qred = zero;
    dd = zero;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	step[i__] = zero;
	hs[i__] = zero;
	g[i__] = gq[i__] + hd[i__];
	d__[i__] = -g[i__];
/* L30: */
/* Computing 2nd power */
	d__1 = d__[i__];
	dd += d__1 * d__1;
    }
    *crvmin = zero;
    if (dd == zero) {
	goto L160;
    }
    ds = zero;
    ss = zero;
    gg = dd;
    ggbeg = gg;

/*     Calculate the step to the trust region boundary and the product HD. */

L40:
    ++iterc;
    temp = delsq - ss;
    bstep = temp / (ds + sqrt(ds * ds + dd * temp));
    goto L170;
L50:
    dhd = zero;
    i__1 = *n;
    for (j = 1; j <= i__1; ++j) {
/* L60: */
	dhd += d__[j] * hd[j];
    }

/*     Update CRVMIN and set the step-length ALPHA. */

    alpha = bstep;
    if (dhd > zero) {
	temp = dhd / dd;
	if (iterc == 1) {
	    *crvmin = temp;
	}
	*crvmin = min(*crvmin,temp);
/* Computing MIN */
	d__1 = alpha, d__2 = gg / dhd;
	alpha = min(d__1,d__2);
    }
    qadd = alpha * (gg - half * alpha * dhd);
    qred += qadd;

/*     Update STEP and HS. */

    ggsav = gg;
    gg = zero;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	step[i__] += alpha * d__[i__];
	hs[i__] += alpha * hd[i__];
/* L70: */
/* Computing 2nd power */
	d__1 = g[i__] + hs[i__];
	gg += d__1 * d__1;
    }

/*     Begin another conjugate direction iteration if required. */

    if (alpha < bstep) {
	if (qadd <= qred * .01) {
	    goto L160;
	}
	if (gg <= ggbeg * 1e-4) {
	    goto L160;
	}
	if (iterc == itermax) {
	    goto L160;
	}
	temp = gg / ggsav;
	dd = zero;
	ds = zero;
	ss = zero;
	i__1 = *n;
	for (i__ = 1; i__ <= i__1; ++i__) {
	    d__[i__] = temp * d__[i__] - g[i__] - hs[i__];
/* Computing 2nd power */
	    d__1 = d__[i__];
	    dd += d__1 * d__1;
	    ds += d__[i__] * step[i__];
/* L80: */
/* Computing 2nd power */
	    d__1 = step[i__];
	    ss += d__1 * d__1;
	}
	if (ds <= zero) {
	    goto L160;
	}
	if (ss < delsq) {
	    goto L40;
	}
    }
    *crvmin = zero;
    itersw = iterc;

/*     Test whether an alternative iteration is required. */

L90:
    if (gg <= ggbeg * 1e-4) {
	goto L160;
    }
    sg = zero;
    shs = zero;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	sg += step[i__] * g[i__];
/* L100: */
	shs += step[i__] * hs[i__];
    }
    sgk = sg + shs;
    angtest = sgk / sqrt(gg * delsq);
    if (angtest <= -.99) {
	goto L160;
    }

/*     Begin the alternative iteration by calculating D and HD and some */
/*     scalar products. */

    ++iterc;
    temp = sqrt(delsq * gg - sgk * sgk);
    tempa = delsq / temp;
    tempb = sgk / temp;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L110: */
	d__[i__] = tempa * (g[i__] + hs[i__]) - tempb * step[i__];
    }
    goto L170;
L120:
    dg = zero;
    dhd = zero;
    dhs = zero;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	dg += d__[i__] * g[i__];
	dhd += hd[i__] * d__[i__];
/* L130: */
	dhs += hd[i__] * step[i__];
    }

/*     Seek the value of the angle that minimizes Q. */

    cf = half * (shs - dhd);
    qbeg = sg + cf;
    qsav = qbeg;
    qmin = qbeg;
    isave = 0;
    iu = 49;
    temp = twopi / (doublereal) (iu + 1);
    i__1 = iu;
    for (i__ = 1; i__ <= i__1; ++i__) {
	angle = (doublereal) i__ * temp;
	cth = cos(angle);
	sth = sin(angle);
	qnew = (sg + cf * cth) * cth + (dg + dhs * cth) * sth;
	if (qnew < qmin) {
	    qmin = qnew;
	    isave = i__;
	    tempa = qsav;
	} else if (i__ == isave + 1) {
	    tempb = qnew;
	}
/* L140: */
	qsav = qnew;
    }
    if ((doublereal) isave == zero) {
	tempa = qnew;
    }
    if (isave == iu) {
	tempb = qbeg;
    }
    angle = zero;
    if (tempa != tempb) {
	tempa -= qmin;
	tempb -= qmin;
	angle = half * (tempa - tempb) / (tempa + tempb);
    }
    angle = temp * ((doublereal) isave + angle);

/*     Calculate the new STEP and HS. Then test for convergence. */

    cth = cos(angle);
    sth = sin(angle);
    reduc = qbeg - (sg + cf * cth) * cth - (dg + dhs * cth) * sth;
    gg = zero;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	step[i__] = cth * step[i__] + sth * d__[i__];
	hs[i__] = cth * hs[i__] + sth * hd[i__];
/* L150: */
/* Computing 2nd power */
	d__1 = g[i__] + hs[i__];
	gg += d__1 * d__1;
    }
    qred += reduc;
    ratio = reduc / qred;
    if (iterc < itermax && ratio > .01) {
	goto L90;
    }
L160:
    return 0;

/*     The following instructions act as a subroutine for setting the vector */
/*     HD to the vector D multiplied by the second derivative matrix of Q. */
/*     They are called from three different places, which are distinguished */
/*     by the value of ITERC. */

L170:
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L180: */
	hd[i__] = zero;
    }
    i__1 = *npt;
    for (k = 1; k <= i__1; ++k) {
	temp = zero;
	i__2 = *n;
	for (j = 1; j <= i__2; ++j) {
/* L190: */
	    temp += xpt[k + j * xpt_dim1] * d__[j];
	}
	temp *= pq[k];
	i__2 = *n;
	for (i__ = 1; i__ <= i__2; ++i__) {
/* L200: */
	    hd[i__] += temp * xpt[k + i__ * xpt_dim1];
	}
    }
    ih = 0;
    i__2 = *n;
    for (j = 1; j <= i__2; ++j) {
	i__1 = j;
	for (i__ = 1; i__ <= i__1; ++i__) {
	    ++ih;
	    if (i__ < j) {
		hd[j] += hq[ih] * d__[i__];
	    }
/* L210: */
	    hd[i__] += hq[ih] * d__[j];
	}
    }
    if (iterc == 0) {
	goto L20;
    }
    if (iterc <= itersw) {
	goto L50;
    }
    goto L120;
} /* trsapp_ */

