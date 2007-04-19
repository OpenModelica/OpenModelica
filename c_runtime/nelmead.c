/* nelmead2.f -- translated by f2c (version 20041007).
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

/* Subroutine */ int nelmead_(doublereal *p, doublereal *step, integer *nop, 
	doublereal *func, integer *max__, integer *iprint, doublereal *stopcr,
	 integer *nloop, integer *iquad, doublereal *simp, doublereal *var, 
	S_fp functn, integer *ifault)
{
    /* Initialized data */

    static doublereal a = 1.;
    static doublereal b = .5;
    static doublereal c__ = 2.;
    static integer lout = 6;

    /* Format strings */
    static char fmt_1000[] = "(\002 Progress Report every\002,i4,\002 functi"
	    "on evaluations\002/,\002 EVAL.   FUNC.VALUE.\002,10x,\002PARAMET"
	    "ER VALUES\002)";
    static char fmt_1010[] = "(/1x,i4,2x,g12.5,2x,5g11.4,3(/21x,5g11.4))";
    static char fmt_1020[] = "(\002 No. of function evaluations > \002,i5)";
    static char fmt_1030[] = "(\002 RMS of function values of last simplex "
	    "=\002,g14.6)";
    static char fmt_1040[] = "(\002 Centroid of last simplex =\002,4(/1x,6g1"
	    "3.5))";
    static char fmt_1050[] = "(\002 Function value at centroid =\002,g14.6)";
    static char fmt_1060[] = "(/\002 EVIDENCE OF CONVERGENCE\002)";
    static char fmt_1070[] = "(//\002 Minimum found after\002,i5,\002 functi"
	    "on evaluations\002)";
    static char fmt_1080[] = "(\002 Minimum at\002,4(/1x,6g13.6))";
    static char fmt_1090[] = "(\002 Function value at minimum =\002,g14.6)";
    static char fmt_1110[] = "(/\002 Fitting quadratic surface about suppose"
	    "d minimum\002/)";
    static char fmt_1120[] = "(/\002 MATRIX OF ESTIMATED SECOND DERIVATIVES "
	    "NOT +VE DEFN.\002/\002 MINIMUM PROBABLY NOT FOUND\002/)";
    static char fmt_1130[] = "(/10x,\002Search restarting\002/)";
    static char fmt_1140[] = "(\002 Minimum of quadratic surface =\002,g14"
	    ".6,\002 at\002,4(/1x,6g13.5))";
    static char fmt_1150[] = "(\002 IF THIS DIFFERS BY MUCH FROM THE MINIMUM"
	    " ESTIMATED\002,1x,\002FROM THE MINIMIZATION,\002/\002 THE MINIMU"
	    "M MAY BE FALSE &/OR THE INFORMATION MATRIX MAY BE\002,1x,\002INA"
	    "CCURATE\002/)";
    static char fmt_1160[] = "(\002 Rank of information matrix =\002,i3/\002"
	    " Inverse of information matrix:-\002)";
    static char fmt_1170[] = "(/\002 If the function minimized was -LOG(LIKE"
	    "LIHOOD),\002/\002 this is the covariance matrix of the parameter"
	    "s.\002/\002 If the function was a sum of squares of residuals"
	    ",\002/\002 this matrix must be multiplied by twice the estimate"
	    "d\002,1x,\002residual variance\002/\002 to obtain the covariance"
	    " matrix.\002/)";
    static char fmt_1190[] = "(\002 INFORMATION MATRIX:-\002/)";
    static char fmt_1200[] = "(//\002 CORRELATION MATRIX:-\002)";
    static char fmt_1210[] = "(/\002 A further\002,i4,\002 function evaluati"
	    "ons have been used\002/)";
    static char fmt_1230[] = "(1x,6g13.5)";
    static char fmt_1240[] = "(/)";

    /* System generated locals */
    integer i__1, i__2, i__3;
    doublereal d__1;

    /* Builtin functions */
    integer s_wsfe(cilist *), do_fio(integer *, char *, ftnlen), e_wsfe(void);
    double sqrt(doublereal);

    /* Local variables */
    static doublereal g[420]	/* was [21][20] */, h__[21];
    static integer i__, j, k, l;
    static doublereal a0;
    static integer i1, i2, j1, ii, ij, jj;
    static doublereal vc[210];
    static integer np1, ijk, nap;
    static doublereal aval[20], pbar[20], bmat[210];
    static integer imin;
    static doublereal hmax;
    static integer imax;
    static doublereal hmin, hstd, pmin[20], temp[20], rmax;
    static integer loop;
    static doublereal ymin, test;
    static integer irow, iflag;
    static doublereal hmean;
    static integer irank, neval, nmore;
    static doublereal hstar, pstar[20], hstst, pstst[20], savemn;
    extern /* Subroutine */ int syminv_(doublereal *, integer *, doublereal *,
	     doublereal *, integer *, integer *, doublereal *);
    static integer nullty;

    /* Fortran I/O blocks */
    static cilist io___5 = { 0, 0, 0, fmt_1000, 0 };
    static cilist io___16 = { 0, 0, 0, fmt_1010, 0 };
    static cilist io___24 = { 0, 0, 0, fmt_1010, 0 };
    static cilist io___27 = { 0, 0, 0, fmt_1010, 0 };
    static cilist io___28 = { 0, 0, 0, fmt_1010, 0 };
    static cilist io___29 = { 0, 0, 0, fmt_1010, 0 };
    static cilist io___32 = { 0, 0, 0, fmt_1010, 0 };
    static cilist io___33 = { 0, 0, 0, fmt_1020, 0 };
    static cilist io___34 = { 0, 0, 0, fmt_1030, 0 };
    static cilist io___35 = { 0, 0, 0, fmt_1040, 0 };
    static cilist io___36 = { 0, 0, 0, fmt_1050, 0 };
    static cilist io___37 = { 0, 0, 0, fmt_1060, 0 };
    static cilist io___38 = { 0, 0, 0, fmt_1040, 0 };
    static cilist io___39 = { 0, 0, 0, fmt_1050, 0 };
    static cilist io___41 = { 0, 0, 0, fmt_1070, 0 };
    static cilist io___42 = { 0, 0, 0, fmt_1080, 0 };
    static cilist io___43 = { 0, 0, 0, fmt_1090, 0 };
    static cilist io___44 = { 0, 0, 0, fmt_1110, 0 };
    static cilist io___47 = { 0, 0, 0, fmt_1010, 0 };
    static cilist io___61 = { 0, 0, 0, fmt_1120, 0 };
    static cilist io___62 = { 0, 0, 0, fmt_1130, 0 };
    static cilist io___64 = { 0, 0, 0, fmt_1140, 0 };
    static cilist io___65 = { 0, 0, 0, fmt_1150, 0 };
    static cilist io___67 = { 0, 0, 0, fmt_1160, 0 };
    static cilist io___69 = { 0, 0, 0, fmt_1170, 0 };
    static cilist io___70 = { 0, 0, 0, fmt_1190, 0 };
    static cilist io___74 = { 0, 0, 0, fmt_1200, 0 };
    static cilist io___75 = { 0, 0, 0, fmt_1210, 0 };
    static cilist io___76 = { 0, 0, 0, fmt_1230, 0 };
    static cilist io___77 = { 0, 0, 0, fmt_1230, 0 };
    static cilist io___78 = { 0, 0, 0, fmt_1240, 0 };



/*     A PROGRAM FOR FUNCTION MINIMIZATION USING THE SIMPLEX METHOD. */

/*     FOR DETAILS, SEE NELDER & MEAD, THE COMPUTER JOURNAL, JANUARY 1965 */

/*     PROGRAMMED BY D.E.SHAW, */
/*     CSIRO, DIVISION OF MATHEMATICS & STATISTICS */
/*     P.O. BOX 218, LINDFIELD, N.S.W. 2070 */

/*     WITH AMENDMENTS BY R.W.M.WEDDERBURN */
/*     ROTHAMSTED EXPERIMENTAL STATION */
/*     HARPENDEN, HERTFORDSHIRE, ENGLAND */

/*     Further amended by Alan Miller */
/*     CSIRO Division of Mathematics & Statistics */
/*     Private Bag 10, CLAYTON, VIC. 3168 */

/*     ARGUMENTS:- */
/*     P()     = INPUT, STARTING VALUES OF PARAMETERS */
/*               OUTPUT, FINAL VALUES OF PARAMETERS */
/*     STEP()  = INPUT, INITIAL STEP SIZES */
/*     NOP     = INPUT, NO. OF PARAMETERS, INCL. ANY TO BE HELD FIXED */
/*     FUNC    = OUTPUT, THE FUNCTION VALUE CORRESPONDING TO THE FINAL */
/*                 PARAMETER VALUES. */
/*     MAX     = INPUT, THE MAXIMUM NO. OF FUNCTION EVALUATIONS ALLOWED. */
/*               Say, 20 times the number of parameters, NOP. */
/*     IPRINT  = INPUT, PRINT CONTROL PARAMETER */
/*                 < 0 NO PRINTING */
/*                 = 0 PRINTING OF PARAMETER VALUES AND THE FUNCTION */
/*                     VALUE AFTER INITIAL EVIDENCE OF CONVERGENCE. */
/*                 > 0 AS FOR IPRINT = 0 PLUS PROGRESS REPORTS AFTER */
/*                     EVERY IPRINT EVALUATIONS, PLUS PRINTING FOR THE */
/*                     INITIAL SIMPLEX. */
/*     STOPCR  = INPUT, STOPPING CRITERION. */
/*               The criterion is applied to the standard deviation of */
/*               the values of FUNC at the points of the simplex. */
/*     NLOOP   = INPUT, THE STOPPING RULE IS APPLIED AFTER EVERY NLOOP */
/*               FUNCTION EVALUATIONS.   Normally NLOOP should be slightly */
/*               greater than NOP, say NLOOP = 2*NOP. */
/*     IQUAD   = INPUT, = 1 IF FITTING OF A QUADRATIC SURFACE IS REQUIRED */
/*                      = 0 IF NOT */
/*               N.B. The fitting of a quadratic surface is strongly */
/*               recommended, provided that the fitted function is */
/*               continuous in the vicinity of the minimum.   It is often */
/*               a good indicator of whether a premature termination of */
/*               the search has occurred. */
/*     SIMP    = INPUT, CRITERION FOR EXPANDING THE SIMPLEX TO OVERCOME */
/*               ROUNDING ERRORS BEFORE FITTING THE QUADRATIC SURFACE. */
/*               The simplex is expanded so that the function values at */
/*               the points of the simplex exceed those at the supposed */
/*               minimum by at least an amount SIMP. */
/*     VAR()   = OUTPUT, CONTAINS THE DIAGONAL ELEMENTS OF THE INVERSE OF */
/*               THE INFORMATION MATRIX. */
/*     FUNCTN  = INPUT, NAME OF THE USER'S SUBROUTINE - ARGUMENTS */
/* 		(NOP,P,FUNC) WHICH RETURNS THE FUNCTION VALUE FOR A GIVEN */
/*               SET OF PARAMETER VALUES IN ARRAY P. */
/* ****     FUNCTN MUST BE DECLARED EXTERNAL IN THE CALLING PROGRAM. */
/*     IFAULT  = OUTPUT, = 0 FOR SUCCESSFUL TERMINATION */
/*                 = 1 IF MAXIMUM NO. OF FUNCTION EVALUATIONS EXCEEDED */
/*                 = 2 IF INFORMATION MATRIX IS NOT +VE SEMI-DEFINITE */
/*                 = 3 IF NOP < 1 */
/*                 = 4 IF NLOOP < 1 */

/*     N.B. P, STEP AND VAR (IF IQUAD = 1) MUST HAVE DIMENSION AT LEAST NOP */
/*          IN THE CALLING PROGRAM. */
/*     THE DIMENSIONS BELOW ARE FOR A MAXIMUM OF 20 PARAMETERS. */

/*     LATEST REVISION - 6 April 1985 */

/* ***************************************************************************** */


/*     A = REFLECTION COEFFICIENT, B = CONTRACTION COEFFICIENT, AND */
/*     C = EXPANSION COEFFICIENT. */

    /* Parameter adjustments */
    --var;
    --step;
    --p;

    /* Function Body */

/*     SET LOUT = LOGICAL UNIT NO. FOR OUTPUT */


/*     IF PROGRESS REPORTS HAVE BEEN REQUESTED, PRINT HEADING */

    if (*iprint > 0) {
	io___5.ciunit = lout;
	s_wsfe(&io___5);
	do_fio(&c__1, (char *)&(*iprint), (ftnlen)sizeof(integer));
	e_wsfe();
    }

/*     CHECK INPUT ARGUMENTS */

    *ifault = 0;
    if (*nop <= 0) {
	*ifault = 3;
    }
    if (*nloop <= 0) {
	*ifault = 4;
    }
    if (*ifault != 0) {
	return 0;
    }

/*     SET NAP = NO. OF PARAMETERS TO BE VARIED, I.E. WITH STEP.NE.0 */

    nap = 0;
    neval = 0;
    loop = 0;
    iflag = 0;
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (step[i__] != 0.) {
	    ++nap;
	}
/* L10: */
    }

/*     IF NAP = 0 EVALUATE FUNCTION AT THE STARTING POINT AND RETURN */

    if (nap > 0) {
	goto L30;
    }
    (*functn)(nop, &p[1], func);
    return 0;

/*     SET UP THE INITIAL SIMPLEX */

L30:
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L40: */
	g[i__ * 21 - 21] = p[i__];
    }
    irow = 2;
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (step[i__] == 0.) {
	    goto L60;
	}
	i__2 = *nop;
	for (j = 1; j <= i__2; ++j) {
/* L50: */
	    g[irow + j * 21 - 22] = p[j];
	}
	g[irow + i__ * 21 - 22] = p[i__] + step[i__];
	++irow;
L60:
	;
    }

    np1 = nap + 1;
    i__1 = np1;
    for (i__ = 1; i__ <= i__1; ++i__) {
	i__2 = *nop;
	for (j = 1; j <= i__2; ++j) {
/* L70: */
	    p[j] = g[i__ + j * 21 - 22];
	}
	(*functn)(nop, &p[1], &h__[i__ - 1]);
	++neval;
	if (*iprint <= 0) {
	    goto L90;
	}
	io___16.ciunit = lout;
	s_wsfe(&io___16);
	do_fio(&c__1, (char *)&neval, (ftnlen)sizeof(integer));
	do_fio(&c__1, (char *)&h__[i__ - 1], (ftnlen)sizeof(doublereal));
	i__2 = *nop;
	for (j = 1; j <= i__2; ++j) {
	    do_fio(&c__1, (char *)&p[j], (ftnlen)sizeof(doublereal));
	}
	e_wsfe();
L90:
	;
    }

/*     START OF MAIN CYCLE. */

/*     FIND MAX. & MIN. VALUES FOR CURRENT SIMPLEX (HMAX & HMIN). */

L100:
    ++loop;
    imax = 1;
    imin = 1;
    hmax = h__[0];
    hmin = h__[0];
    i__1 = np1;
    for (i__ = 2; i__ <= i__1; ++i__) {
	if (h__[i__ - 1] <= hmax) {
	    goto L110;
	}
	imax = i__;
	hmax = h__[i__ - 1];
	goto L120;
L110:
	if (h__[i__ - 1] >= hmin) {
	    goto L120;
	}
	imin = i__;
	hmin = h__[i__ - 1];
L120:
	;
    }

/*     FIND THE CENTROID OF THE VERTICES OTHER THAN P(IMAX) */

    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L130: */
	pbar[i__ - 1] = 0.;
    }
    i__1 = np1;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (i__ == imax) {
	    goto L150;
	}
	i__2 = *nop;
	for (j = 1; j <= i__2; ++j) {
/* L140: */
	    pbar[j - 1] += g[i__ + j * 21 - 22];
	}
L150:
	;
    }
    i__1 = *nop;
    for (j = 1; j <= i__1; ++j) {
/* L160: */
	pbar[j - 1] /= (real) nap;
    }

/*     REFLECT MAXIMUM THROUGH PBAR TO PSTAR, */
/*     HSTAR = FUNCTION VALUE AT PSTAR. */

    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L170: */
	pstar[i__ - 1] = a * (pbar[i__ - 1] - g[imax + i__ * 21 - 22]) + pbar[
		i__ - 1];
    }
    (*functn)(nop, pstar, &hstar);
    ++neval;
    if (*iprint <= 0) {
	goto L180;
    }
    if (neval % *iprint == 0) {
	io___24.ciunit = lout;
	s_wsfe(&io___24);
	do_fio(&c__1, (char *)&neval, (ftnlen)sizeof(integer));
	do_fio(&c__1, (char *)&hstar, (ftnlen)sizeof(doublereal));
	i__1 = *nop;
	for (j = 1; j <= i__1; ++j) {
	    do_fio(&c__1, (char *)&pstar[j - 1], (ftnlen)sizeof(doublereal));
	}
	e_wsfe();
    }

/*     IF HSTAR < HMIN, REFLECT PBAR THROUGH PSTAR, */
/*     HSTST = FUNCTION VALUE AT PSTST. */

L180:
    if (hstar >= hmin) {
	goto L220;
    }
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L190: */
	pstst[i__ - 1] = c__ * (pstar[i__ - 1] - pbar[i__ - 1]) + pbar[i__ - 
		1];
    }
    (*functn)(nop, pstst, &hstst);
    ++neval;
    if (*iprint <= 0) {
	goto L200;
    }
    if (neval % *iprint == 0) {
	io___27.ciunit = lout;
	s_wsfe(&io___27);
	do_fio(&c__1, (char *)&neval, (ftnlen)sizeof(integer));
	do_fio(&c__1, (char *)&hstst, (ftnlen)sizeof(doublereal));
	i__1 = *nop;
	for (j = 1; j <= i__1; ++j) {
	    do_fio(&c__1, (char *)&pstst[j - 1], (ftnlen)sizeof(doublereal));
	}
	e_wsfe();
    }

/*     IF HSTST < HMIN REPLACE CURRENT MAXIMUM POINT BY PSTST AND */
/*     HMAX BY HSTST, THEN TEST FOR CONVERGENCE. */

L200:
    if (hstst >= hmin) {
	goto L320;
    }
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (step[i__] != 0.) {
	    g[imax + i__ * 21 - 22] = pstst[i__ - 1];
	}
/* L210: */
    }
    h__[imax - 1] = hstst;
    goto L340;

/*     HSTAR IS NOT < HMIN. */
/*     TEST WHETHER IT IS < FUNCTION VALUE AT SOME POINT OTHER THAN */
/*     P(IMAX).   IF IT IS REPLACE P(IMAX) BY PSTAR & HMAX BY HSTAR. */

L220:
    i__1 = np1;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (i__ == imax) {
	    goto L230;
	}
	if (hstar < h__[i__ - 1]) {
	    goto L320;
	}
L230:
	;
    }

/*     HSTAR > ALL FUNCTION VALUES EXCEPT POSSIBLY HMAX. */
/*     IF HSTAR <= HMAX, REPLACE P(IMAX) BY PSTAR & HMAX BY HSTAR. */

    if (hstar > hmax) {
	goto L260;
    }
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (step[i__] != 0.) {
	    g[imax + i__ * 21 - 22] = pstar[i__ - 1];
	}
/* L250: */
    }
    hmax = hstar;
    h__[imax - 1] = hstar;

/*     CONTRACTED STEP TO THE POINT PSTST, */
/*     HSTST = FUNCTION VALUE AT PSTST. */

L260:
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L270: */
	pstst[i__ - 1] = b * g[imax + i__ * 21 - 22] + (1.f - b) * pbar[i__ - 
		1];
    }
    (*functn)(nop, pstst, &hstst);
    ++neval;
    if (*iprint <= 0) {
	goto L280;
    }
    if (neval % *iprint == 0) {
	io___28.ciunit = lout;
	s_wsfe(&io___28);
	do_fio(&c__1, (char *)&neval, (ftnlen)sizeof(integer));
	do_fio(&c__1, (char *)&hstst, (ftnlen)sizeof(doublereal));
	i__1 = *nop;
	for (j = 1; j <= i__1; ++j) {
	    do_fio(&c__1, (char *)&pstst[j - 1], (ftnlen)sizeof(doublereal));
	}
	e_wsfe();
    }

/*     IF HSTST < HMAX REPLACE P(IMAX) BY PSTST & HMAX BY HSTST. */

L280:
    if (hstst > hmax) {
	goto L300;
    }
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (step[i__] != 0.) {
	    g[imax + i__ * 21 - 22] = pstst[i__ - 1];
	}
/* L290: */
    }
    h__[imax - 1] = hstst;
    goto L340;

/*     HSTST > HMAX. */
/*     SHRINK THE SIMPLEX BY REPLACING EACH POINT, OTHER THAN THE CURRENT */
/*     MINIMUM, BY A POINT MID-WAY BETWEEN ITS CURRENT POSITION AND THE */
/*     MINIMUM. */

L300:
    i__1 = np1;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (i__ == imin) {
	    goto L315;
	}
	i__2 = *nop;
	for (j = 1; j <= i__2; ++j) {
	    if (step[j] != 0.) {
		g[i__ + j * 21 - 22] = (g[i__ + j * 21 - 22] + g[imin + j * 
			21 - 22]) * .5f;
	    }
/* L310: */
	    p[j] = g[i__ + j * 21 - 22];
	}
	(*functn)(nop, &p[1], &h__[i__ - 1]);
	++neval;
	if (*iprint <= 0) {
	    goto L315;
	}
	if (neval % *iprint == 0) {
	    io___29.ciunit = lout;
	    s_wsfe(&io___29);
	    do_fio(&c__1, (char *)&neval, (ftnlen)sizeof(integer));
	    do_fio(&c__1, (char *)&h__[i__ - 1], (ftnlen)sizeof(doublereal));
	    i__2 = *nop;
	    for (j = 1; j <= i__2; ++j) {
		do_fio(&c__1, (char *)&p[j], (ftnlen)sizeof(doublereal));
	    }
	    e_wsfe();
	}
L315:
	;
    }
    goto L340;

/*     REPLACE MAXIMUM POINT BY PSTAR & H(IMAX) BY HSTAR. */

L320:
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (step[i__] != 0.) {
	    g[imax + i__ * 21 - 22] = pstar[i__ - 1];
	}
/* L330: */
    }
    h__[imax - 1] = hstar;

/*     IF LOOP = NLOOP TEST FOR CONVERGENCE, OTHERWISE REPEAT MAIN CYCLE. */

L340:
    if (loop < *nloop) {
	goto L100;
    }

/*     CALCULATE MEAN & STANDARD DEVIATION OF FUNCTION VALUES FOR THE */
/*     CURRENT SIMPLEX. */

    hstd = 0.;
    hmean = 0.;
    i__1 = np1;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L350: */
	hmean += h__[i__ - 1];
    }
    hmean /= (real) np1;
    i__1 = np1;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L360: */
/* Computing 2nd power */
	d__1 = h__[i__ - 1] - hmean;
	hstd += d__1 * d__1;
    }
    hstd = sqrt(hstd / (real) np1);

/*     IF THE RMS > STOPCR, SET IFLAG & LOOP TO ZERO AND GO TO THE */
/*     START OF THE MAIN CYCLE AGAIN. */

    if (hstd <= *stopcr || neval > *max__) {
	goto L410;
    }
    iflag = 0;
    loop = 0;
    goto L100;

/*     FIND THE CENTROID OF THE CURRENT SIMPLEX AND THE FUNCTION VALUE THERE. */

L410:
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (step[i__] == 0.) {
	    goto L380;
	}
	p[i__] = 0.;
	i__2 = np1;
	for (j = 1; j <= i__2; ++j) {
/* L370: */
	    p[i__] += g[j + i__ * 21 - 22];
	}
	p[i__] /= (real) np1;
L380:
	;
    }
    (*functn)(nop, &p[1], func);
    ++neval;
    if (*iprint <= 0) {
	goto L390;
    }
    if (neval % *iprint == 0) {
	io___32.ciunit = lout;
	s_wsfe(&io___32);
	do_fio(&c__1, (char *)&neval, (ftnlen)sizeof(integer));
	do_fio(&c__1, (char *)&(*func), (ftnlen)sizeof(doublereal));
	i__1 = *nop;
	for (j = 1; j <= i__1; ++j) {
	    do_fio(&c__1, (char *)&p[j], (ftnlen)sizeof(doublereal));
	}
	e_wsfe();
    }

/*     TEST WHETHER THE NO. OF FUNCTION VALUES ALLOWED, MAX, HAS BEEN */
/*     OVERRUN; IF SO, EXIT WITH IFAULT = 1. */

L390:
    if (neval <= *max__) {
	goto L420;
    }
    *ifault = 1;
    if (*iprint < 0) {
	return 0;
    }
    io___33.ciunit = lout;
    s_wsfe(&io___33);
    do_fio(&c__1, (char *)&(*max__), (ftnlen)sizeof(integer));
    e_wsfe();
    io___34.ciunit = lout;
    s_wsfe(&io___34);
    do_fio(&c__1, (char *)&hstd, (ftnlen)sizeof(doublereal));
    e_wsfe();
    io___35.ciunit = lout;
    s_wsfe(&io___35);
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
	do_fio(&c__1, (char *)&p[i__], (ftnlen)sizeof(doublereal));
    }
    e_wsfe();
    io___36.ciunit = lout;
    s_wsfe(&io___36);
    do_fio(&c__1, (char *)&(*func), (ftnlen)sizeof(doublereal));
    e_wsfe();
    return 0;

/*     CONVERGENCE CRITERION SATISFIED. */
/*     IF IFLAG = 0, SET IFLAG & SAVE HMEAN. */
/*     IF IFLAG = 1 & CHANGE IN HMEAN <= STOPCR THEN SEARCH IS COMPLETE. */

L420:
    if (*iprint < 0) {
	goto L430;
    }
    io___37.ciunit = lout;
    s_wsfe(&io___37);
    e_wsfe();
    io___38.ciunit = lout;
    s_wsfe(&io___38);
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
	do_fio(&c__1, (char *)&p[i__], (ftnlen)sizeof(doublereal));
    }
    e_wsfe();
    io___39.ciunit = lout;
    s_wsfe(&io___39);
    do_fio(&c__1, (char *)&(*func), (ftnlen)sizeof(doublereal));
    e_wsfe();
L430:
    if (iflag > 0) {
	goto L450;
    }
    iflag = 1;
L440:
    savemn = hmean;
    loop = 0;
    goto L100;
L450:
    if ((d__1 = savemn - hmean, abs(d__1)) >= *stopcr) {
	goto L440;
    }
    if (*iprint < 0) {
	goto L460;
    }
    io___41.ciunit = lout;
    s_wsfe(&io___41);
    do_fio(&c__1, (char *)&neval, (ftnlen)sizeof(integer));
    e_wsfe();
    io___42.ciunit = lout;
    s_wsfe(&io___42);
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
	do_fio(&c__1, (char *)&p[i__], (ftnlen)sizeof(doublereal));
    }
    e_wsfe();
    io___43.ciunit = lout;
    s_wsfe(&io___43);
    do_fio(&c__1, (char *)&(*func), (ftnlen)sizeof(doublereal));
    e_wsfe();
L460:
    if (*iquad <= 0) {
	return 0;
    }

/* ------------------------------------------------------------------ */

/*     QUADRATIC SURFACE FITTING */

    if (*iprint >= 0) {
	io___44.ciunit = lout;
	s_wsfe(&io___44);
	e_wsfe();
    }

/*     EXPAND THE FINAL SIMPLEX, IF NECESSARY, TO OVERCOME ROUNDING */
/*     ERRORS. */

    hmin = *func;
    nmore = 0;
    i__1 = np1;
    for (i__ = 1; i__ <= i__1; ++i__) {
L470:
	test = (d__1 = h__[i__ - 1] - *func, abs(d__1));
	if (test >= *simp) {
	    goto L490;
	}
	i__2 = *nop;
	for (j = 1; j <= i__2; ++j) {
	    if (step[j] != 0.) {
		g[i__ + j * 21 - 22] = g[i__ + j * 21 - 22] - p[j] + g[i__ + 
			j * 21 - 22];
	    }
/* L480: */
	    pstst[j - 1] = g[i__ + j * 21 - 22];
	}
	(*functn)(nop, pstst, &h__[i__ - 1]);
	++nmore;
	++neval;
	if (h__[i__ - 1] >= hmin) {
	    goto L470;
	}
	hmin = h__[i__ - 1];
	if (*iprint >= 0) {
	    io___47.ciunit = lout;
	    s_wsfe(&io___47);
	    do_fio(&c__1, (char *)&neval, (ftnlen)sizeof(integer));
	    do_fio(&c__1, (char *)&hmin, (ftnlen)sizeof(doublereal));
	    i__2 = *nop;
	    for (j = 1; j <= i__2; ++j) {
		do_fio(&c__1, (char *)&pstst[j - 1], (ftnlen)sizeof(
			doublereal));
	    }
	    e_wsfe();
	}
	goto L470;
L490:
	;
    }

/*     FUNCTION VALUES ARE CALCULATED AT AN ADDITIONAL NAP POINTS. */

    i__1 = nap;
    for (i__ = 1; i__ <= i__1; ++i__) {
	i1 = i__ + 1;
	i__2 = *nop;
	for (j = 1; j <= i__2; ++j) {
/* L500: */
	    pstar[j - 1] = (g[j * 21 - 21] + g[i1 + j * 21 - 22]) * .5f;
	}
	(*functn)(nop, pstar, &aval[i__ - 1]);
	++nmore;
	++neval;
/* L510: */
    }

/*     THE MATRIX OF ESTIMATED SECOND DERIVATIVES IS CALCULATED AND ITS */
/*     LOWER TRIANGLE STORED IN BMAT. */

    a0 = h__[0];
    i__1 = nap;
    for (i__ = 1; i__ <= i__1; ++i__) {
	i1 = i__ - 1;
	i2 = i__ + 1;
	if (i1 < 1) {
	    goto L540;
	}
	i__2 = i1;
	for (j = 1; j <= i__2; ++j) {
	    j1 = j + 1;
	    i__3 = *nop;
	    for (k = 1; k <= i__3; ++k) {
/* L520: */
		pstst[k - 1] = (g[i2 + k * 21 - 22] + g[j1 + k * 21 - 22]) * 
			.5f;
	    }
	    (*functn)(nop, pstst, &hstst);
	    ++nmore;
	    ++neval;
	    l = i__ * (i__ - 1) / 2 + j;
	    bmat[l - 1] = (hstst + a0 - aval[i__ - 1] - aval[j - 1]) * 2.f;
/* L530: */
	}
L540:
	;
    }
    l = 0;
    i__1 = nap;
    for (i__ = 1; i__ <= i__1; ++i__) {
	i1 = i__ + 1;
	l += i__;
	bmat[l - 1] = (h__[i1 - 1] + a0 - aval[i__ - 1] * 2.f) * 2.f;
/* L550: */
    }

/*     THE VECTOR OF ESTIMATED FIRST DERIVATIVES IS CALCULATED AND */
/*     STORED IN AVAL. */

    i__1 = nap;
    for (i__ = 1; i__ <= i__1; ++i__) {
	i1 = i__ + 1;
/* L560: */
	aval[i__ - 1] = aval[i__ - 1] * 2.f - (h__[i1 - 1] + a0 * 3.f) * .5f;
    }

/*     THE MATRIX Q OF NELDER & MEAD IS CALCULATED AND STORED IN G. */

    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L570: */
	pmin[i__ - 1] = g[i__ * 21 - 21];
    }
    i__1 = nap;
    for (i__ = 1; i__ <= i__1; ++i__) {
	i1 = i__ + 1;
	i__2 = *nop;
	for (j = 1; j <= i__2; ++j) {
	    g[i1 + j * 21 - 22] -= g[j * 21 - 21];
/* L580: */
	}
    }
    i__2 = nap;
    for (i__ = 1; i__ <= i__2; ++i__) {
	i1 = i__ + 1;
	i__1 = *nop;
	for (j = 1; j <= i__1; ++j) {
	    g[i__ + j * 21 - 22] = g[i1 + j * 21 - 22];
/* L590: */
	}
    }

/*     INVERT BMAT */

    syminv_(bmat, &nap, bmat, temp, &nullty, ifault, &rmax);
    if (*ifault != 0) {
	goto L600;
    }
    irank = nap - nullty;
    goto L610;
L600:
    if (*iprint >= 0) {
	io___61.ciunit = lout;
	s_wsfe(&io___61);
	e_wsfe();
    }
    *ifault = 2;
    if (neval > *max__) {
	return 0;
    }
    io___62.ciunit = lout;
    s_wsfe(&io___62);
    e_wsfe();
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L605: */
	step[i__] *= .5f;
    }
    goto L30;

/*     BMAT*A/2 IS CALCULATED AND STORED IN H. */

L610:
    i__1 = nap;
    for (i__ = 1; i__ <= i__1; ++i__) {
	h__[i__ - 1] = 0.;
	i__2 = nap;
	for (j = 1; j <= i__2; ++j) {
	    if (j > i__) {
		goto L620;
	    }
	    l = i__ * (i__ - 1) / 2 + j;
	    goto L630;
L620:
	    l = j * (j - 1) / 2 + i__;
L630:
	    h__[i__ - 1] += bmat[l - 1] * aval[j - 1];
/* L640: */
	}
/* L650: */
    }

/*     FIND THE POSITION, PMIN, & VALUE, YMIN, OF THE MINIMUM OF THE */
/*     QUADRATIC. */

    ymin = 0.;
    i__1 = nap;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L660: */
	ymin += h__[i__ - 1] * aval[i__ - 1];
    }
    ymin = a0 - ymin;
    i__1 = *nop;
    for (i__ = 1; i__ <= i__1; ++i__) {
	pstst[i__ - 1] = 0.;
	i__2 = nap;
	for (j = 1; j <= i__2; ++j) {
/* L670: */
	    pstst[i__ - 1] += h__[j - 1] * g[j + i__ * 21 - 22];
	}
    }
    i__2 = *nop;
    for (i__ = 1; i__ <= i__2; ++i__) {
/* L680: */
	pmin[i__ - 1] -= pstst[i__ - 1];
    }
    if (*iprint < 0) {
	goto L690;
    }
    io___64.ciunit = lout;
    s_wsfe(&io___64);
    do_fio(&c__1, (char *)&ymin, (ftnlen)sizeof(doublereal));
    i__2 = *nop;
    for (i__ = 1; i__ <= i__2; ++i__) {
	do_fio(&c__1, (char *)&pmin[i__ - 1], (ftnlen)sizeof(doublereal));
    }
    e_wsfe();
    io___65.ciunit = lout;
    s_wsfe(&io___65);
    e_wsfe();

/*     Q*BMAT*Q'/2 IS CALCULATED & ITS LOWER TRIANGLE STORED IN VC */

L690:
    i__2 = *nop;
    for (i__ = 1; i__ <= i__2; ++i__) {
	i__1 = nap;
	for (j = 1; j <= i__1; ++j) {
	    h__[j - 1] = 0.;
	    i__3 = nap;
	    for (k = 1; k <= i__3; ++k) {
		if (k > j) {
		    goto L700;
		}
		l = j * (j - 1) / 2 + k;
		goto L710;
L700:
		l = k * (k - 1) / 2 + j;
L710:
		h__[j - 1] += bmat[l - 1] * g[k + i__ * 21 - 22] * .5f;
/* L720: */
	    }
/* L730: */
	}
	i__1 = *nop;
	for (j = i__; j <= i__1; ++j) {
	    l = j * (j - 1) / 2 + i__;
	    vc[l - 1] = 0.;
	    i__3 = nap;
	    for (k = 1; k <= i__3; ++k) {
/* L740: */
		vc[l - 1] += h__[k - 1] * g[k + j * 21 - 22];
	    }
/* L750: */
	}
/* L760: */
    }

/*     THE DIAGONAL ELEMENTS OF VC ARE COPIED INTO VAR. */

    j = 0;
    i__2 = *nop;
    for (i__ = 1; i__ <= i__2; ++i__) {
	j += i__;
/* L770: */
	var[i__] = vc[j - 1];
    }
    if (*iprint < 0) {
	return 0;
    }
    io___67.ciunit = lout;
    s_wsfe(&io___67);
    do_fio(&c__1, (char *)&irank, (ftnlen)sizeof(integer));
    e_wsfe();
    ijk = 1;
    goto L880;

L790:
    io___69.ciunit = lout;
    s_wsfe(&io___69);
    e_wsfe();
    syminv_(vc, &nap, bmat, temp, &nullty, ifault, &rmax);

/*     BMAT NOW CONTAINS THE INFORMATION MATRIX */

    io___70.ciunit = lout;
    s_wsfe(&io___70);
    e_wsfe();
    ijk = 3;
    goto L880;

L800:
    ijk = 2;
    ii = 0;
    ij = 0;
    i__2 = *nop;
    for (i__ = 1; i__ <= i__2; ++i__) {
	ii += i__;
	if (vc[ii - 1] > 0.) {
	    vc[ii - 1] = 1.f / sqrt(vc[ii - 1]);
	} else {
	    vc[ii - 1] = 0.;
	}
	jj = 0;
	i__1 = i__ - 1;
	for (j = 1; j <= i__1; ++j) {
	    jj += j;
	    ++ij;
	    vc[ij - 1] = vc[ij - 1] * vc[ii - 1] * vc[jj - 1];
/* L830: */
	}
	++ij;
/* L840: */
    }

    io___74.ciunit = lout;
    s_wsfe(&io___74);
    e_wsfe();
    ii = 0;
    i__2 = *nop;
    for (i__ = 1; i__ <= i__2; ++i__) {
	ii += i__;
	if (vc[ii - 1] != 0.) {
	    vc[ii - 1] = 1.;
	}
/* L850: */
    }
    goto L880;

/*     Exit, on successful termination. */

L860:
    io___75.ciunit = lout;
    s_wsfe(&io___75);
    do_fio(&c__1, (char *)&nmore, (ftnlen)sizeof(integer));
    e_wsfe();
    return 0;

L880:
    l = 1;
L890:
    if (l > *nop) {
	switch (ijk) {
	    case 1:  goto L790;
	    case 2:  goto L860;
	    case 3:  goto L800;
	}
    }
    ii = l * (l - 1) / 2;
    i__2 = *nop;
    for (i__ = l; i__ <= i__2; ++i__) {
	i1 = ii + l;
	ii += i__;
/* Computing MIN */
	i__1 = ii, i__3 = i1 + 5;
	i2 = min(i__1,i__3);
	if (ijk == 3) {
	    goto L900;
	}
	io___76.ciunit = lout;
	s_wsfe(&io___76);
	i__1 = i2;
	for (j = i1; j <= i__1; ++j) {
	    do_fio(&c__1, (char *)&vc[j - 1], (ftnlen)sizeof(doublereal));
	}
	e_wsfe();
	goto L910;
L900:
	io___77.ciunit = lout;
	s_wsfe(&io___77);
	i__1 = i2;
	for (j = i1; j <= i__1; ++j) {
	    do_fio(&c__1, (char *)&bmat[j - 1], (ftnlen)sizeof(doublereal));
	}
	e_wsfe();
L910:
	;
    }
    io___78.ciunit = lout;
    s_wsfe(&io___78);
    e_wsfe();
    l += 6;
    goto L890;
} /* nelmead_ */

/* Subroutine */ int syminv_(doublereal *a, integer *n, doublereal *c__, 
	doublereal *w, integer *nullty, integer *ifault, doublereal *rmax)
{
    /* System generated locals */
    integer i__1;

    /* Local variables */
    static integer i__, j, k, l;
    static doublereal x;
    static integer nn, icol, jcol, irow, nrow, mdiag, ndiag;
    extern /* Subroutine */ int chola_(doublereal *, integer *, doublereal *, 
	    integer *, integer *, doublereal *, doublereal *);


/*     ALGORITHM AS7, APPLIED STATISTICS, VOL.17, 1968. */

/*     ARGUMENTS:- */
/*     A()    = INPUT, THE SYMMETRIC MATRIX TO BE INVERTED, STORED IN */
/*                LOWER TRIANGULAR FORM */
/*     N      = INPUT, ORDER OF THE MATRIX */
/*     C()    = OUTPUT, THE INVERSE OF A (A GENERALIZED INVERSE IF C IS */
/*                SINGULAR), ALSO STORED IN LOWER TRIANGULAR. */
/*                C AND A MAY OCCUPY THE SAME LOCATIONS. */
/*     W()    = WORKSPACE, DIMENSION AT LEAST N. */
/*     NULLTY = OUTPUT, THE RANK DEFICIENCY OF A. */
/*     IFAULT = OUTPUT, ERROR INDICATOR */
/*                 = 1 IF N < 1 */
/*                 = 2 IF A IS NOT +VE SEMI-DEFINITE */
/*                 = 0 OTHERWISE */
/*     RMAX   = OUTPUT, APPROXIMATE BOUND ON THE ACCURACY OF THE DIAGONAL */
/*                ELEMENTS OF C.  E.G. IF RMAX = 1.E-04 THEN THE DIAGONAL */
/*                ELEMENTS OF C WILL BE ACCURATE TO ABOUT 4 DEC. DIGITS. */

/*     LATEST REVISION - 1 April 1985 */

/* *************************************************************************** */

    /* Parameter adjustments */
    --a;
    --w;
    --c__;

    /* Function Body */
    nrow = *n;
    *ifault = 1;
    if (nrow <= 0) {
	goto L100;
    }
    *ifault = 0;

/*     CHOLESKY FACTORIZATION OF A, RESULT IN C */

    chola_(&a[1], &nrow, &c__[1], nullty, ifault, rmax, &w[1]);
    if (*ifault != 0) {
	goto L100;
    }

/*     INVERT C & FORM THE PRODUCT (CINV)'*CINV, WHERE CINV IS THE INVERSE */
/*     OF C, ROW BY ROW STARTING WITH THE LAST ROW. */
/*     IROW = THE ROW NUMBER, NDIAG = LOCATION OF LAST ELEMENT IN THE ROW. */

    nn = nrow * (nrow + 1) / 2;
    irow = nrow;
    ndiag = nn;
L10:
    if (c__[ndiag] == 0.) {
	goto L60;
    }
    l = ndiag;
    i__1 = nrow;
    for (i__ = irow; i__ <= i__1; ++i__) {
	w[i__] = c__[l];
	l += i__;
/* L20: */
    }
    icol = nrow;
    jcol = nn;
    mdiag = nn;
L30:
    l = jcol;
    x = 0.;
    if (icol == irow) {
	x = 1. / w[irow];
    }
    k = nrow;
L40:
    if (k == irow) {
	goto L50;
    }
    x -= w[k] * c__[l];
    --k;
    --l;
    if (l > mdiag) {
	l = l - k + 1;
    }
    goto L40;
L50:
    c__[l] = x / w[irow];
    if (icol == irow) {
	goto L80;
    }
    mdiag -= icol;
    --icol;
    --jcol;
    goto L30;
L60:
    l = ndiag;
    i__1 = nrow;
    for (j = irow; j <= i__1; ++j) {
	c__[l] = 0.;
	l += j;
/* L70: */
    }
L80:
    ndiag -= irow;
    --irow;
    if (irow != 0) {
	goto L10;
    }
L100:
    return 0;
} /* syminv_ */

/* Subroutine */ int chola_(doublereal *a, integer *n, doublereal *u, integer 
	*nullty, integer *ifault, doublereal *rmax, doublereal *r__)
{
    /* System generated locals */
    integer i__1, i__2, i__3;
    doublereal d__1, d__2;

    /* Builtin functions */
    double sqrt(doublereal);

    /* Local variables */
    static integer i__, j, k, l, m;
    static doublereal w, eta, rsq;
    static integer icol, irow;


/*     ALGORITHM AS6, APPLIED STATISTICS, VOL.17, 1968, WITH */
/*     MODIFICATIONS BY A.J.MILLER */

/*     ARGUMENTS:- */
/*     A()    = INPUT, A +VE DEFINITE MATRIX STORED IN LOWER-TRIANGULAR */
/*                FORM. */
/*     N      = INPUT, THE ORDER OF A */
/*     U()    = OUTPUT, A LOWER TRIANGULAR MATRIX SUCH THAT U*U' = A. */
/*                A & U MAY OCCUPY THE SAME LOCATIONS. */
/*     NULLTY = OUTPUT, THE RANK DEFICIENCY OF A. */
/*     IFAULT = OUTPUT, ERROR INDICATOR */
/*                 = 1 IF N < 1 */
/*                 = 2 IF A IS NOT +VE SEMI-DEFINITE */
/*                 = 0 OTHERWISE */
/*     RMAX   = OUTPUT, AN ESTIMATE OF THE RELATIVE ACCURACY OF THE */
/*                DIAGONAL ELEMENTS OF U. */
/*     R()    = OUTPUT, ARRAY CONTAINING BOUNDS ON THE RELATIVE ACCURACY */
/*                OF EACH DIAGONAL ELEMENT OF U. */

/*     LATEST REVISION - 1 April 1985 */

/* *************************************************************************** */


    /* Parameter adjustments */
    --a;
    --r__;
    --u;

    /* Function Body */
    eta = .5;
L110:
    eta /= 2.;
    if (eta + 1. > 1.) {
	goto L110;
    }
    eta *= 2.;
    *ifault = 1;
    if (*n <= 0) {
	goto L100;
    }
    *ifault = 2;
    *nullty = 0;
    *rmax = eta;
    r__[1] = eta;
    j = 1;
    k = 0;

/*     FACTORIZE COLUMN BY COLUMN, ICOL = COLUMN NO. */

    i__1 = *n;
    for (icol = 1; icol <= i__1; ++icol) {
	l = 0;

/*     IROW = ROW NUMBER WITHIN COLUMN ICOL */

	i__2 = icol;
	for (irow = 1; irow <= i__2; ++irow) {
	    ++k;
	    w = a[k];
	    if (irow == icol) {
/* Computing 2nd power */
		d__1 = w * eta;
		rsq = d__1 * d__1;
	    }
	    m = j;
	    i__3 = irow;
	    for (i__ = 1; i__ <= i__3; ++i__) {
		++l;
		if (i__ == irow) {
		    goto L20;
		}
		w -= u[l] * u[m];
		if (irow == icol) {
/* Computing 2nd power */
		    d__2 = u[l];
/* Computing 2nd power */
		    d__1 = d__2 * d__2 * r__[i__];
		    rsq += d__1 * d__1;
		}
		++m;
/* L10: */
	    }
L20:
	    if (irow == icol) {
		goto L50;
	    }
	    if (u[l] == 0.) {
		goto L30;
	    }
	    u[k] = w / u[l];
	    goto L40;
L30:
	    u[k] = 0.;
	    if (abs(w) > (d__1 = *rmax * a[k], abs(d__1))) {
		goto L100;
	    }
L40:
	    ;
	}

/*     END OF ROW, ESTIMATE RELATIVE ACCURACY OF DIAGONAL ELEMENT. */

L50:
	rsq = sqrt(rsq);
	if (abs(w) <= rsq * 5.f) {
	    goto L60;
	}
	if (w < 0.) {
	    goto L100;
	}
	u[k] = sqrt(w);
	r__[i__] = rsq / w;
	if (r__[i__] > *rmax) {
	    *rmax = r__[i__];
	}
	goto L70;
L60:
	u[k] = 0.;
	++(*nullty);
L70:
	j += icol;
/* L80: */
    }
    *ifault = 0;
L100:
    return 0;
} /* chola_ */

