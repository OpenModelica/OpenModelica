/* newuoa.f -- translated by f2c (version 20041007).
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

/* Subroutine */ int newuoa_(integer *n, integer *npt, doublereal *x, 
	doublereal *rhobeg, doublereal *rhoend, integer *iprint, integer *
	maxfun, doublereal *w, doublereal *calfun)
{
    /* Format strings */
    static char fmt_10[] = "(/4x,\002Return from NEWUOA because NPT is not"
	    " in\002,\002 the required interval\002)";

    /* Builtin functions */
    integer s_wsfe(cilist *), e_wsfe(void);

    /* Local variables */
    static integer id, np, iw, igq, ihq, ixb, ifv, ipq, ivl, ixn, ixo, ixp, 
	    ndim, nptm, ibmat, izmat;
    extern /* Subroutine */ int newuob_(integer *, integer *, doublereal *, 
	    doublereal *, doublereal *, integer *, integer *, doublereal *, 
	    doublereal *, doublereal *, doublereal *, doublereal *, 
	    doublereal *, doublereal *, doublereal *, doublereal *, 
	    doublereal *, integer *, doublereal *, doublereal *, doublereal *,
	     doublereal *);

    /* Fortran I/O blocks */
    static cilist io___3 = { 0, 6, 0, fmt_10, 0 };



/*     This subroutine seeks the least value of a function of many variables, */
/*     by a trust region method that forms quadratic models by interpolation. */
/*     There can be some freedom in the interpolation conditions, which is */
/*     taken up by minimizing the Frobenius norm of the change to the second */
/*     derivative of the quadratic model, beginning with a zero matrix. The */
/*     arguments of the subroutine are as follows. */

/*     N must be set to the number of variables and must be at least two. */
/*     NPT is the number of interpolation conditions. Its value must be in the */
/*       interval [N+2,(N+1)(N+2)/2]. */
/*     Initial values of the variables must be set in X(1),X(2),...,X(N). They */
/*       will be changed to the values that give the least calculated F. */
/*     RHOBEG and RHOEND must be set to the initial and final values of a trust */
/*       region radius, so both must be positive with RHOEND<=RHOBEG. Typically */
/*       RHOBEG should be about one tenth of the greatest expected change to a */
/*       variable, and RHOEND should indicate the accuracy that is required in */
/*       the final values of the variables. */
/*     The value of IPRINT should be set to 0, 1, 2 or 3, which controls the */
/*       amount of printing. Specifically, there is no output if IPRINT=0 and */
/*       there is output only at the return if IPRINT=1. Otherwise, each new */
/*       value of RHO is printed, with the best vector of variables so far and */
/*       the corresponding value of the objective function. Further, each new */
/*       value of F with its variables are output if IPRINT=3. */
/*     MAXFUN must be set to an upper bound on the number of calls of CALFUN. */
/*     The array W will be used for working space. Its length must be at least */
/*     (NPT+13)*(NPT+N)+3*N*(N+3)/2. */

/*     SUBROUTINE CALFUN (N,X,F) must be provided by the user. It must set F to */
/*     the value of the objective function for the variables X(1),X(2),...,X(N). */

/*     Partition the working space array, so that different parts of it can be */
/*     treated separately by the subroutine that performs the main calculation. */

    /* Parameter adjustments */
    --w;
    --x;

    /* Function Body */
    np = *n + 1;
    nptm = *npt - np;
    if (*npt < *n + 2 || *npt > (*n + 2) * np / 2) {
	s_wsfe(&io___3);
	e_wsfe();
	goto L20;
    }
    ndim = *npt + *n;
    ixb = 1;
    ixo = ixb + *n;
    ixn = ixo + *n;
    ixp = ixn + *n;
    ifv = ixp + *n * *npt;
    igq = ifv + *npt;
    ihq = igq + *n;
    ipq = ihq + *n * np / 2;
    ibmat = ipq + *npt;
    izmat = ibmat + ndim * *n;
    id = izmat + *npt * nptm;
    ivl = id + *n;
    iw = ivl + ndim;

/*     The above settings provide a partition of W for subroutine NEWUOB. */
/*     The partition requires the first NPT*(NPT+N)+5*N*(N+3)/2 elements of */
/*     W plus the space that is needed by the last array of NEWUOB. */

    newuob_(n, npt, &x[1], rhobeg, rhoend, iprint, maxfun, &w[ixb], &w[ixo], &
	    w[ixn], &w[ixp], &w[ifv], &w[igq], &w[ihq], &w[ipq], &w[ibmat], &
	    w[izmat], &ndim, &w[id], &w[ivl], &w[iw], calfun);
L20:
    return 0;
} /* newuoa_ */

