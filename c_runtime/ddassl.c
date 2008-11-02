/* ddassl.f -- translated by f2c (version 20041007).
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

/* Common Block Declarations */

struct {
    integer nunit, iunit[5];
} xeruni_;

#define xeruni_1 xeruni_

/* Table of constant values */

static integer c__1 = 1;
static integer c_n998 = -998;
static integer c__2 = 2;
static integer c__4 = 4;
static integer c__5 = 5;
static integer c__6 = 6;
static integer c__3 = 3;
static integer c__7 = 7;
static integer c__8 = 8;
static integer c__9 = 9;
static integer c__10 = 10;
static integer c__11 = 11;
static integer c__12 = 12;
static integer c__13 = 13;
static integer c__14 = 14;
static integer c__15 = 15;
static integer c__17 = 17;
static integer c__18 = 18;
static integer c__19 = 19;
static integer c_n999 = -999;
static integer c__0 = 0;
static integer c_n1 = -1;
static integer c__72 = 72;

/* Subroutine */ int ddassl_(U_fp res, integer *neq, doublereal *t,
	doublereal *y, doublereal *yprime, doublereal *tout, integer *info,
	doublereal *rtol, doublereal *atol, integer *idid, doublereal *rwork,
	integer *lrw, integer *iwork, integer *liw, doublereal *rpar, integer
	*ipar, U_fp jac)
{
    /* System generated locals */
    address a__1[4], a__2[5], a__3[6], a__4[3], a__5[2];
    integer i__1, i__2[4], i__3[5], i__4[6], i__5[3], i__6[2];
    doublereal d__1, d__2;
    char ch__1[118], ch__2[81], ch__3[128], ch__4[62], ch__5[110], ch__6[121],
	     ch__7[90], ch__8[132], ch__9[126], ch__10[85], ch__11[98],
	    ch__12[21], ch__13[30], ch__14[61], ch__15[71], ch__16[32],
	    ch__17[51], ch__18[78], ch__19[66], ch__20[49], ch__21[27];

    /* Builtin functions */
    integer s_wsfi(icilist *), do_fio(integer *, char *, ftnlen), e_wsfi(void)
	    ;
    /* Subroutine */ int s_cat(char *, char **, integer *, integer *, ftnlen);
    double d_sign(doublereal *, doublereal *);

    /* Local variables */
    static doublereal h__;
    static integer i__;
    static doublereal r__;
    static integer le;
    static doublereal ho, rh, tn;
    static integer lpd, lwm, lwt;
    static logical done;
    static integer lphi;
    static doublereal hmax, hmin;
    static char xern1[8], xern2[8], xern3[16], xern4[16];
    static integer mband, lenpd;
    static doublereal atoli;
    static integer msave, itemp, leniw, nzflg, ntemp, lenrw;
    static doublereal tdist;
    static integer mxord;
    static doublereal rtoli;
    extern doublereal d1mach_(integer *);
    static doublereal tnext, tstop;
    extern /* Subroutine */ int ddaini_(doublereal *, doublereal *,
	    doublereal *, integer *, U_fp, U_fp, doublereal *, doublereal *,
	    integer *, doublereal *, integer *, doublereal *, doublereal *,
	    doublereal *, doublereal *, integer *, doublereal *, doublereal *,
	     integer *, integer *);
    extern doublereal ddanrm_(integer *, doublereal *, doublereal *,
	    doublereal *, integer *);
    extern /* Subroutine */ int ddatrp_(doublereal *, doublereal *,
	    doublereal *, doublereal *, integer *, integer *, doublereal *,
	    doublereal *), ddastp_(doublereal *, doublereal *, doublereal *,
	    integer *, U_fp, U_fp, doublereal *, doublereal *, integer *,
	    integer *, doublereal *, integer *, doublereal *, doublereal *,
	    doublereal *, doublereal *, integer *, doublereal *, doublereal *,
	     doublereal *, doublereal *, doublereal *, doublereal *,
	    doublereal *, doublereal *, doublereal *, doublereal *,
	    doublereal *, integer *, integer *, integer *, integer *, integer
	    *, integer *, integer *), ddawts_(integer *, integer *,
	    doublereal *, doublereal *, doublereal *, doublereal *,
	    doublereal *, integer *), xermsg_(char *, char *, char *, integer
	    *, integer *, ftnlen, ftnlen, ftnlen);
    static doublereal uround, ypnorm;

    /* Fortran I/O blocks */
    static icilist io___10 = { 0, xern1, 0, "(I8)", 8, 1 };
    static icilist io___34 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___35 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___36 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___37 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___39 = { 0, xern4, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___40 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___41 = { 0, xern4, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___42 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___43 = { 0, xern4, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___44 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___45 = { 0, xern4, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___46 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___47 = { 0, xern4, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___48 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___49 = { 0, xern4, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___50 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___51 = { 0, xern4, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___52 = { 0, xern1, 0, "(I8)", 8, 1 };
    static icilist io___53 = { 0, xern1, 0, "(I8)", 8, 1 };
    static icilist io___54 = { 0, xern1, 0, "(I8)", 8, 1 };
    static icilist io___56 = { 0, xern2, 0, "(I8)", 8, 1 };
    static icilist io___57 = { 0, xern1, 0, "(I8)", 8, 1 };
    static icilist io___58 = { 0, xern2, 0, "(I8)", 8, 1 };
    static icilist io___59 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___60 = { 0, xern4, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___61 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___62 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___63 = { 0, xern4, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___64 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___65 = { 0, xern4, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___66 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___67 = { 0, xern4, 0, "(1P,D15.6)", 16, 1 };
    static icilist io___68 = { 0, xern1, 0, "(I8)", 8, 1 };
    static icilist io___69 = { 0, xern1, 0, "(I8)", 8, 1 };
    static icilist io___70 = { 0, xern3, 0, "(1P,D15.6)", 16, 1 };


/* ***BEGIN PROLOGUE  DDASSL */
/* ***PURPOSE  This code solves a system of differential/algebraic */
/*            equations of the form G(T,Y,YPRIME) = 0. */
/* ***LIBRARY   SLATEC (DASSL) */
/* ***CATEGORY  I1A2 */
/* ***TYPE      DOUBLE PRECISION (SDASSL-S, DDASSL-D) */
/* ***KEYWORDS  DIFFERENTIAL/ALGEBRAIC, BACKWARD DIFFERENTIATION FORMULAS, */
/*             IMPLICIT DIFFERENTIAL SYSTEMS */
/* ***AUTHOR  PETZOLD, LINDA R., (LLNL) */
/*             COMPUTING AND MATHEMATICS RESEARCH DIVISION */
/*             LAWRENCE LIVERMORE NATIONAL LABORATORY */
/*             L - 316, P.O. BOX 808, */
/*             LIVERMORE, CA.    94550 */
/* ***DESCRIPTION */

/* *Usage: */

/*      EXTERNAL RES, JAC */
/*      INTEGER NEQ, INFO(N), IDID, LRW, LIW, IWORK(LIW), IPAR */
/*      DOUBLE PRECISION T, Y(NEQ), YPRIME(NEQ), TOUT, RTOL, ATOL, */
/*     *   RWORK(LRW), RPAR */

/*      CALL DDASSL (RES, NEQ, T, Y, YPRIME, TOUT, INFO, RTOL, ATOL, */
/*     *   IDID, RWORK, LRW, IWORK, LIW, RPAR, IPAR, JAC) */


/* *Arguments: */
/*  (In the following, all real arrays should be type DOUBLE PRECISION.) */

/*  RES:EXT     This is a subroutine which you provide to define the */
/*              differential/algebraic system. */

/*  NEQ:IN      This is the number of equations to be solved. */

/*  T:INOUT     This is the current value of the independent variable. */

/*  Y(*):INOUT  This array contains the solution components at T. */

/*  YPRIME(*):INOUT  This array contains the derivatives of the solution */
/*              components at T. */

/*  TOUT:IN     This is a point at which a solution is desired. */

/*  INFO(N):IN  The basic task of the code is to solve the system from T */
/*              to TOUT and return an answer at TOUT.  INFO is an integer */
/*              array which is used to communicate exactly how you want */
/*              this task to be carried out.  (See below for details.) */
/*              N must be greater than or equal to 15. */

/*  RTOL,ATOL:INOUT  These quantities represent relative and absolute */
/*              error tolerances which you provide to indicate how */
/*              accurately you wish the solution to be computed.  You */
/*              may choose them to be both scalars or else both vectors. */
/*              Caution:  In Fortran 77, a scalar is not the same as an */
/*                        array of length 1.  Some compilers may object */
/*                        to using scalars for RTOL,ATOL. */

/*  IDID:OUT    This scalar quantity is an indicator reporting what the */
/*              code did.  You must monitor this integer variable to */
/*              decide  what action to take next. */

/*  RWORK:WORK  A real work array of length LRW which provides the */
/*              code with needed storage space. */

/*  LRW:IN      The length of RWORK.  (See below for required length.) */

/*  IWORK:WORK  An integer work array of length LIW which probides the */
/*              code with needed storage space. */

/*  LIW:IN      The length of IWORK.  (See below for required length.) */

/*  RPAR,IPAR:IN  These are real and integer parameter arrays which */
/*              you can use for communication between your calling */
/*              program and the RES subroutine (and the JAC subroutine) */

/*  JAC:EXT     This is the name of a subroutine which you may choose */
/*              to provide for defining a matrix of partial derivatives */
/*              described below. */

/*  Quantities which may be altered by DDASSL are: */
/*     T, Y(*), YPRIME(*), INFO(1), RTOL, ATOL, */
/*     IDID, RWORK(*) AND IWORK(*) */

/* *Description */

/*  Subroutine DDASSL uses the backward differentiation formulas of */
/*  orders one through five to solve a system of the above form for Y and */
/*  YPRIME.  Values for Y and YPRIME at the initial time must be given as */
/*  input.  These values must be consistent, (that is, if T,Y,YPRIME are */
/*  the given initial values, they must satisfy G(T,Y,YPRIME) = 0.).  The */
/*  subroutine solves the system from T to TOUT.  It is easy to continue */
/*  the solution to get results at additional TOUT.  This is the interval */
/*  mode of operation.  Intermediate results can also be obtained easily */
/*  by using the intermediate-output capability. */

/*  The following detailed description is divided into subsections: */
/*    1. Input required for the first call to DDASSL. */
/*    2. Output after any return from DDASSL. */
/*    3. What to do to continue the integration. */
/*    4. Error messages. */


/*  -------- INPUT -- WHAT TO DO ON THE FIRST CALL TO DDASSL ------------ */

/*  The first call of the code is defined to be the start of each new */
/*  problem. Read through the descriptions of all the following items, */
/*  provide sufficient storage space for designated arrays, set */
/*  appropriate variables for the initialization of the problem, and */
/*  give information about how you want the problem to be solved. */


/*  RES -- Provide a subroutine of the form */
/*             SUBROUTINE RES(T,Y,YPRIME,DELTA,IRES,RPAR,IPAR) */
/*         to define the system of differential/algebraic */
/*         equations which is to be solved. For the given values */
/*         of T,Y and YPRIME, the subroutine should */
/*         return the residual of the defferential/algebraic */
/*         system */
/*             DELTA = G(T,Y,YPRIME) */
/*         (DELTA(*) is a vector of length NEQ which is */
/*         output for RES.) */

/*         Subroutine RES must not alter T,Y or YPRIME. */
/*         You must declare the name RES in an external */
/*         statement in your program that calls DDASSL. */
/*         You must dimension Y,YPRIME and DELTA in RES. */

/*         IRES is an integer flag which is always equal to */
/*         zero on input. Subroutine RES should alter IRES */
/*         only if it encounters an illegal value of Y or */
/*         a stop condition. Set IRES = -1 if an input value */
/*         is illegal, and DDASSL will try to solve the problem */
/*         without getting IRES = -1. If IRES = -2, DDASSL */
/*         will return control to the calling program */
/*         with IDID = -11. */

/*         RPAR and IPAR are real and integer parameter arrays which */
/*         you can use for communication between your calling program */
/*         and subroutine RES. They are not altered by DDASSL. If you */
/*         do not need RPAR or IPAR, ignore these parameters by treat- */
/*         ing them as dummy arguments. If you do choose to use them, */
/*         dimension them in your calling program and in RES as arrays */
/*         of appropriate length. */

/*  NEQ -- Set it to the number of differential equations. */
/*         (NEQ .GE. 1) */

/*  T -- Set it to the initial point of the integration. */
/*         T must be defined as a variable. */

/*  Y(*) -- Set this vector to the initial values of the NEQ solution */
/*         components at the initial point. You must dimension Y of */
/*         length at least NEQ in your calling program. */

/*  YPRIME(*) -- Set this vector to the initial values of the NEQ */
/*         first derivatives of the solution components at the initial */
/*         point.  You must dimension YPRIME at least NEQ in your */
/*         calling program. If you do not know initial values of some */
/*         of the solution components, see the explanation of INFO(11). */

/*  TOUT -- Set it to the first point at which a solution */
/*         is desired. You can not take TOUT = T. */
/*         integration either forward in T (TOUT .GT. T) or */
/*         backward in T (TOUT .LT. T) is permitted. */

/*         The code advances the solution from T to TOUT using */
/*         step sizes which are automatically selected so as to */
/*         achieve the desired accuracy. If you wish, the code will */
/*         return with the solution and its derivative at */
/*         intermediate steps (intermediate-output mode) so that */
/*         you can monitor them, but you still must provide TOUT in */
/*         accord with the basic aim of the code. */

/*         The first step taken by the code is a critical one */
/*         because it must reflect how fast the solution changes near */
/*         the initial point. The code automatically selects an */
/*         initial step size which is practically always suitable for */
/*         the problem. By using the fact that the code will not step */
/*         past TOUT in the first step, you could, if necessary, */
/*         restrict the length of the initial step size. */

/*         For some problems it may not be permissible to integrate */
/*         past a point TSTOP because a discontinuity occurs there */
/*         or the solution or its derivative is not defined beyond */
/*         TSTOP. When you have declared a TSTOP point (SEE INFO(4) */
/*         and RWORK(1)), you have told the code not to integrate */
/*         past TSTOP. In this case any TOUT beyond TSTOP is invalid */
/*         input. */

/*  INFO(*) -- Use the INFO array to give the code more details about */
/*         how you want your problem solved.  This array should be */
/*         dimensioned of length 15, though DDASSL uses only the first */
/*         eleven entries.  You must respond to all of the following */
/*         items, which are arranged as questions.  The simplest use */
/*         of the code corresponds to answering all questions as yes, */
/*         i.e. setting all entries of INFO to 0. */

/*       INFO(1) - This parameter enables the code to initialize */
/*              itself. You must set it to indicate the start of every */
/*              new problem. */

/*          **** Is this the first call for this problem ... */
/*                Yes - Set INFO(1) = 0 */
/*                 No - Not applicable here. */
/*                      See below for continuation calls.  **** */

/*       INFO(2) - How much accuracy you want of your solution */
/*              is specified by the error tolerances RTOL and ATOL. */
/*              The simplest use is to take them both to be scalars. */
/*              To obtain more flexibility, they can both be vectors. */
/*              The code must be told your choice. */

/*          **** Are both error tolerances RTOL, ATOL scalars ... */
/*                Yes - Set INFO(2) = 0 */
/*                      and input scalars for both RTOL and ATOL */
/*                 No - Set INFO(2) = 1 */
/*                      and input arrays for both RTOL and ATOL **** */

/*       INFO(3) - The code integrates from T in the direction */
/*              of TOUT by steps. If you wish, it will return the */
/*              computed solution and derivative at the next */
/*              intermediate step (the intermediate-output mode) or */
/*              TOUT, whichever comes first. This is a good way to */
/*              proceed if you want to see the behavior of the solution. */
/*              If you must have solutions at a great many specific */
/*              TOUT points, this code will compute them efficiently. */

/*          **** Do you want the solution only at */
/*                TOUT (and not at the next intermediate step) ... */
/*                 Yes - Set INFO(3) = 0 */
/*                  No - Set INFO(3) = 1 **** */

/*       INFO(4) - To handle solutions at a great many specific */
/*              values TOUT efficiently, this code may integrate past */
/*              TOUT and interpolate to obtain the result at TOUT. */
/*              Sometimes it is not possible to integrate beyond some */
/*              point TSTOP because the equation changes there or it is */
/*              not defined past TSTOP. Then you must tell the code */
/*              not to go past. */

/*           **** Can the integration be carried out without any */
/*                restrictions on the independent variable T ... */
/*                 Yes - Set INFO(4)=0 */
/*                  No - Set INFO(4)=1 */
/*                       and define the stopping point TSTOP by */
/*                       setting RWORK(1)=TSTOP **** */

/*       INFO(5) - To solve differential/algebraic problems it is */
/*              necessary to use a matrix of partial derivatives of the */
/*              system of differential equations. If you do not */
/*              provide a subroutine to evaluate it analytically (see */
/*              description of the item JAC in the call list), it will */
/*              be approximated by numerical differencing in this code. */
/*              although it is less trouble for you to have the code */
/*              compute partial derivatives by numerical differencing, */
/*              the solution will be more reliable if you provide the */
/*              derivatives via JAC. Sometimes numerical differencing */
/*              is cheaper than evaluating derivatives in JAC and */
/*              sometimes it is not - this depends on your problem. */

/*           **** Do you want the code to evaluate the partial */
/*                derivatives automatically by numerical differences ... */
/*                   Yes - Set INFO(5)=0 */
/*                    No - Set INFO(5)=1 */
/*                  and provide subroutine JAC for evaluating the */
/*                  matrix of partial derivatives **** */

/*       INFO(6) - DDASSL will perform much better if the matrix of */
/*              partial derivatives, DG/DY + CJ*DG/DYPRIME, */
/*              (here CJ is a scalar determined by DDASSL) */
/*              is banded and the code is told this. In this */
/*              case, the storage needed will be greatly reduced, */
/*              numerical differencing will be performed much cheaper, */
/*              and a number of important algorithms will execute much */
/*              faster. The differential equation is said to have */
/*              half-bandwidths ML (lower) and MU (upper) if equation i */
/*              involves only unknowns Y(J) with */
/*                             I-ML .LE. J .LE. I+MU */
/*              for all I=1,2,...,NEQ. Thus, ML and MU are the widths */
/*              of the lower and upper parts of the band, respectively, */
/*              with the main diagonal being excluded. If you do not */
/*              indicate that the equation has a banded matrix of partial */
/*              derivatives, the code works with a full matrix of NEQ**2 */
/*              elements (stored in the conventional way). Computations */
/*              with banded matrices cost less time and storage than with */
/*              full matrices if 2*ML+MU .LT. NEQ. If you tell the */
/*              code that the matrix of partial derivatives has a banded */
/*              structure and you want to provide subroutine JAC to */
/*              compute the partial derivatives, then you must be careful */
/*              to store the elements of the matrix in the special form */
/*              indicated in the description of JAC. */

/*          **** Do you want to solve the problem using a full */
/*               (dense) matrix (and not a special banded */
/*               structure) ... */
/*                Yes - Set INFO(6)=0 */
/*                 No - Set INFO(6)=1 */
/*                       and provide the lower (ML) and upper (MU) */
/*                       bandwidths by setting */
/*                       IWORK(1)=ML */
/*                       IWORK(2)=MU **** */


/*        INFO(7) -- You can specify a maximum (absolute value of) */
/*              stepsize, so that the code */
/*              will avoid passing over very */
/*              large regions. */

/*          ****  Do you want the code to decide */
/*                on its own maximum stepsize? */
/*                Yes - Set INFO(7)=0 */
/*                 No - Set INFO(7)=1 */
/*                      and define HMAX by setting */
/*                      RWORK(2)=HMAX **** */

/*        INFO(8) -- Differential/algebraic problems */
/*              may occaisionally suffer from */
/*              severe scaling difficulties on the */
/*              first step. If you know a great deal */
/*              about the scaling of your problem, you can */
/*              help to alleviate this problem by */
/*              specifying an initial stepsize HO. */

/*          ****  Do you want the code to define */
/*                its own initial stepsize? */
/*                Yes - Set INFO(8)=0 */
/*                 No - Set INFO(8)=1 */
/*                      and define HO by setting */
/*                      RWORK(3)=HO **** */

/*        INFO(9) -- If storage is a severe problem, */
/*              you can save some locations by */
/*              restricting the maximum order MAXORD. */
/*              the default value is 5. for each */
/*              order decrease below 5, the code */
/*              requires NEQ fewer locations, however */
/*              it is likely to be slower. In any */
/*              case, you must have 1 .LE. MAXORD .LE. 5 */
/*          ****  Do you want the maximum order to */
/*                default to 5? */
/*                Yes - Set INFO(9)=0 */
/*                 No - Set INFO(9)=1 */
/*                      and define MAXORD by setting */
/*                      IWORK(3)=MAXORD **** */

/*        INFO(10) --If you know that the solutions to your equations */
/*               will always be nonnegative, it may help to set this */
/*               parameter. However, it is probably best to */
/*               try the code without using this option first, */
/*               and only to use this option if that doesn't */
/*               work very well. */
/*           ****  Do you want the code to solve the problem without */
/*                 invoking any special nonnegativity constraints? */
/*                  Yes - Set INFO(10)=0 */
/*                   No - Set INFO(10)=1 */

/*        INFO(11) --DDASSL normally requires the initial T, */
/*               Y, and YPRIME to be consistent. That is, */
/*               you must have G(T,Y,YPRIME) = 0 at the initial */
/*               time. If you do not know the initial */
/*               derivative precisely, you can let DDASSL try */
/*               to compute it. */
/*          ****   Are the initialHE INITIAL T, Y, YPRIME consistent? */
/*                 Yes - Set INFO(11) = 0 */
/*                  No - Set INFO(11) = 1, */
/*                       and set YPRIME to an initial approximation */
/*                       to YPRIME.  (If you have no idea what */
/*                       YPRIME should be, set it to zero. Note */
/*                       that the initial Y should be such */
/*                       that there must exist a YPRIME so that */
/*                       G(T,Y,YPRIME) = 0.) */

/*  RTOL, ATOL -- You must assign relative (RTOL) and absolute (ATOL */
/*         error tolerances to tell the code how accurately you */
/*         want the solution to be computed.  They must be defined */
/*         as variables because the code may change them.  You */
/*         have two choices -- */
/*               Both RTOL and ATOL are scalars. (INFO(2)=0) */
/*               Both RTOL and ATOL are vectors. (INFO(2)=1) */
/*         in either case all components must be non-negative. */

/*         The tolerances are used by the code in a local error */
/*         test at each step which requires roughly that */
/*               ABS(LOCAL ERROR) .LE. RTOL*ABS(Y)+ATOL */
/*         for each vector component. */
/*         (More specifically, a root-mean-square norm is used to */
/*         measure the size of vectors, and the error test uses the */
/*         magnitude of the solution at the beginning of the step.) */

/*         The true (global) error is the difference between the */
/*         true solution of the initial value problem and the */
/*         computed approximation.  Practically all present day */
/*         codes, including this one, control the local error at */
/*         each step and do not even attempt to control the global */
/*         error directly. */
/*         Usually, but not always, the true accuracy of the */
/*         computed Y is comparable to the error tolerances. This */
/*         code will usually, but not always, deliver a more */
/*         accurate solution if you reduce the tolerances and */
/*         integrate again.  By comparing two such solutions you */
/*         can get a fairly reliable idea of the true error in the */
/*         solution at the bigger tolerances. */

/*         Setting ATOL=0. results in a pure relative error test on */
/*         that component.  Setting RTOL=0. results in a pure */
/*         absolute error test on that component.  A mixed test */
/*         with non-zero RTOL and ATOL corresponds roughly to a */
/*         relative error test when the solution component is much */
/*         bigger than ATOL and to an absolute error test when the */
/*         solution component is smaller than the threshhold ATOL. */

/*         The code will not attempt to compute a solution at an */
/*         accuracy unreasonable for the machine being used.  It will */
/*         advise you if you ask for too much accuracy and inform */
/*         you as to the maximum accuracy it believes possible. */

/*  RWORK(*) --  Dimension this real work array of length LRW in your */
/*         calling program. */

/*  LRW -- Set it to the declared length of the RWORK array. */
/*               You must have */
/*                    LRW .GE. 40+(MAXORD+4)*NEQ+NEQ**2 */
/*               for the full (dense) JACOBIAN case (when INFO(6)=0), or */
/*                    LRW .GE. 40+(MAXORD+4)*NEQ+(2*ML+MU+1)*NEQ */
/*               for the banded user-defined JACOBIAN case */
/*               (when INFO(5)=1 and INFO(6)=1), or */
/*                     LRW .GE. 40+(MAXORD+4)*NEQ+(2*ML+MU+1)*NEQ */
/*                           +2*(NEQ/(ML+MU+1)+1) */
/*               for the banded finite-difference-generated JACOBIAN case */
/*               (when INFO(5)=0 and INFO(6)=1) */

/*  IWORK(*) --  Dimension this integer work array of length LIW in */
/*         your calling program. */

/*  LIW -- Set it to the declared length of the IWORK array. */
/*               You must have LIW .GE. 20+NEQ */

/*  RPAR, IPAR -- These are parameter arrays, of real and integer */
/*         type, respectively.  You can use them for communication */
/*         between your program that calls DDASSL and the */
/*         RES subroutine (and the JAC subroutine).  They are not */
/*         altered by DDASSL.  If you do not need RPAR or IPAR, */
/*         ignore these parameters by treating them as dummy */
/*         arguments.  If you do choose to use them, dimension */
/*         them in your calling program and in RES (and in JAC) */
/*         as arrays of appropriate length. */

/*  JAC -- If you have set INFO(5)=0, you can ignore this parameter */
/*         by treating it as a dummy argument.  Otherwise, you must */
/*         provide a subroutine of the form */
/*             SUBROUTINE JAC(T,Y,YPRIME,PD,CJ,RPAR,IPAR) */
/*         to define the matrix of partial derivatives */
/*             PD=DG/DY+CJ*DG/DYPRIME */
/*         CJ is a scalar which is input to JAC. */
/*         For the given values of T,Y,YPRIME, the */
/*         subroutine must evaluate the non-zero partial */
/*         derivatives for each equation and each solution */
/*         component, and store these values in the */
/*         matrix PD.  The elements of PD are set to zero */
/*         before each call to JAC so only non-zero elements */
/*         need to be defined. */

/*         Subroutine JAC must not alter T,Y,(*),YPRIME(*), or CJ. */
/*         You must declare the name JAC in an EXTERNAL statement in */
/*         your program that calls DDASSL.  You must dimension Y, */
/*         YPRIME and PD in JAC. */

/*         The way you must store the elements into the PD matrix */
/*         depends on the structure of the matrix which you */
/*         indicated by INFO(6). */
/*               *** INFO(6)=0 -- Full (dense) matrix *** */
/*                   Give PD a first dimension of NEQ. */
/*                   When you evaluate the (non-zero) partial derivative */
/*                   of equation I with respect to variable J, you must */
/*                   store it in PD according to */
/*                   PD(I,J) = "DG(I)/DY(J)+CJ*DG(I)/DYPRIME(J)" */
/*               *** INFO(6)=1 -- Banded JACOBIAN with ML lower and MU */
/*                   upper diagonal bands (refer to INFO(6) description */
/*                   of ML and MU) *** */
/*                   Give PD a first dimension of 2*ML+MU+1. */
/*                   when you evaluate the (non-zero) partial derivative */
/*                   of equation I with respect to variable J, you must */
/*                   store it in PD according to */
/*                   IROW = I - J + ML + MU + 1 */
/*                   PD(IROW,J) = "DG(I)/DY(J)+CJ*DG(I)/DYPRIME(J)" */

/*         RPAR and IPAR are real and integer parameter arrays */
/*         which you can use for communication between your calling */
/*         program and your JACOBIAN subroutine JAC. They are not */
/*         altered by DDASSL. If you do not need RPAR or IPAR, */
/*         ignore these parameters by treating them as dummy */
/*         arguments. If you do choose to use them, dimension */
/*         them in your calling program and in JAC as arrays of */
/*         appropriate length. */


/*  OPTIONALLY REPLACEABLE NORM ROUTINE: */

/*     DDASSL uses a weighted norm DDANRM to measure the size */
/*     of vectors such as the estimated error in each step. */
/*     A FUNCTION subprogram */
/*       DOUBLE PRECISION FUNCTION DDANRM(NEQ,V,WT,RPAR,IPAR) */
/*       DIMENSION V(NEQ),WT(NEQ) */
/*     is used to define this norm. Here, V is the vector */
/*     whose norm is to be computed, and WT is a vector of */
/*     weights.  A DDANRM routine has been included with DDASSL */
/*     which computes the weighted root-mean-square norm */
/*     given by */
/*       DDANRM=SQRT((1/NEQ)*SUM(V(I)/WT(I))**2) */
/*     this norm is suitable for most problems. In some */
/*     special cases, it may be more convenient and/or */
/*     efficient to define your own norm by writing a function */
/*     subprogram to be called instead of DDANRM. This should, */
/*     however, be attempted only after careful thought and */
/*     consideration. */


/*  -------- OUTPUT -- AFTER ANY RETURN FROM DDASSL --------------------- */

/*  The principal aim of the code is to return a computed solution at */
/*  TOUT, although it is also possible to obtain intermediate results */
/*  along the way. To find out whether the code achieved its goal */
/*  or if the integration process was interrupted before the task was */
/*  completed, you must check the IDID parameter. */


/*  T -- The solution was successfully advanced to the */
/*               output value of T. */

/*  Y(*) -- Contains the computed solution approximation at T. */

/*  YPRIME(*) -- Contains the computed derivative */
/*               approximation at T. */

/*  IDID -- Reports what the code did. */

/*                     *** Task completed *** */
/*                Reported by positive values of IDID */

/*           IDID = 1 -- A step was successfully taken in the */
/*                   intermediate-output mode. The code has not */
/*                   yet reached TOUT. */

/*           IDID = 2 -- The integration to TSTOP was successfully */
/*                   completed (T=TSTOP) by stepping exactly to TSTOP. */

/*           IDID = 3 -- The integration to TOUT was successfully */
/*                   completed (T=TOUT) by stepping past TOUT. */
/*                   Y(*) is obtained by interpolation. */
/*                   YPRIME(*) is obtained by interpolation. */

/*                    *** Task interrupted *** */
/*                Reported by negative values of IDID */

/*           IDID = -1 -- A large amount of work has been expended. */
/*                   (About 500 steps) */

/*           IDID = -2 -- The error tolerances are too stringent. */

/*           IDID = -3 -- The local error test cannot be satisfied */
/*                   because you specified a zero component in ATOL */
/*                   and the corresponding computed solution */
/*                   component is zero. Thus, a pure relative error */
/*                   test is impossible for this component. */

/*           IDID = -6 -- DDASSL had repeated error test */
/*                   failures on the last attempted step. */

/*           IDID = -7 -- The corrector could not converge. */

/*           IDID = -8 -- The matrix of partial derivatives */
/*                   is singular. */

/*           IDID = -9 -- The corrector could not converge. */
/*                   there were repeated error test failures */
/*                   in this step. */

/*           IDID =-10 -- The corrector could not converge */
/*                   because IRES was equal to minus one. */

/*           IDID =-11 -- IRES equal to -2 was encountered */
/*                   and control is being returned to the */
/*                   calling program. */

/*           IDID =-12 -- DDASSL failed to compute the initial */
/*                   YPRIME. */



/*           IDID = -13,..,-32 -- Not applicable for this code */

/*                    *** Task terminated *** */
/*                Reported by the value of IDID=-33 */

/*           IDID = -33 -- The code has encountered trouble from which */
/*                   it cannot recover. A message is printed */
/*                   explaining the trouble and control is returned */
/*                   to the calling program. For example, this occurs */
/*                   when invalid input is detected. */

/*  RTOL, ATOL -- These quantities remain unchanged except when */
/*               IDID = -2. In this case, the error tolerances have been */
/*               increased by the code to values which are estimated to */
/*               be appropriate for continuing the integration. However, */
/*               the reported solution at T was obtained using the input */
/*               values of RTOL and ATOL. */

/*  RWORK, IWORK -- Contain information which is usually of no */
/*               interest to the user but necessary for subsequent calls. */
/*               However, you may find use for */

/*               RWORK(3)--Which contains the step size H to be */
/*                       attempted on the next step. */

/*               RWORK(4)--Which contains the current value of the */
/*                       independent variable, i.e., the farthest point */
/*                       integration has reached. This will be different */
/*                       from T only when interpolation has been */
/*                       performed (IDID=3). */

/*               RWORK(7)--Which contains the stepsize used */
/*                       on the last successful step. */

/*               IWORK(7)--Which contains the order of the method to */
/*                       be attempted on the next step. */

/*               IWORK(8)--Which contains the order of the method used */
/*                       on the last step. */

/*               IWORK(11)--Which contains the number of steps taken so */
/*                        far. */

/*               IWORK(12)--Which contains the number of calls to RES */
/*                        so far. */

/*               IWORK(13)--Which contains the number of evaluations of */
/*                        the matrix of partial derivatives needed so */
/*                        far. */

/*               IWORK(14)--Which contains the total number */
/*                        of error test failures so far. */

/*               IWORK(15)--Which contains the total number */
/*                        of convergence test failures so far. */
/*                        (includes singular iteration matrix */
/*                        failures.) */


/*  -------- INPUT -- WHAT TO DO TO CONTINUE THE INTEGRATION ------------ */
/*                    (CALLS AFTER THE FIRST) */

/*  This code is organized so that subsequent calls to continue the */
/*  integration involve little (if any) additional effort on your */
/*  part. You must monitor the IDID parameter in order to determine */
/*  what to do next. */

/*  Recalling that the principal task of the code is to integrate */
/*  from T to TOUT (the interval mode), usually all you will need */
/*  to do is specify a new TOUT upon reaching the current TOUT. */

/*  Do not alter any quantity not specifically permitted below, */
/*  in particular do not alter NEQ,T,Y(*),YPRIME(*),RWORK(*),IWORK(*) */
/*  or the differential equation in subroutine RES. Any such */
/*  alteration constitutes a new problem and must be treated as such, */
/*  i.e., you must start afresh. */

/*  You cannot change from vector to scalar error control or vice */
/*  versa (INFO(2)), but you can change the size of the entries of */
/*  RTOL, ATOL. Increasing a tolerance makes the equation easier */
/*  to integrate. Decreasing a tolerance will make the equation */
/*  harder to integrate and should generally be avoided. */

/*  You can switch from the intermediate-output mode to the */
/*  interval mode (INFO(3)) or vice versa at any time. */

/*  If it has been necessary to prevent the integration from going */
/*  past a point TSTOP (INFO(4), RWORK(1)), keep in mind that the */
/*  code will not integrate to any TOUT beyond the currently */
/*  specified TSTOP. Once TSTOP has been reached you must change */
/*  the value of TSTOP or set INFO(4)=0. You may change INFO(4) */
/*  or TSTOP at any time but you must supply the value of TSTOP in */
/*  RWORK(1) whenever you set INFO(4)=1. */

/*  Do not change INFO(5), INFO(6), IWORK(1), or IWORK(2) */
/*  unless you are going to restart the code. */

/*                 *** Following a completed task *** */
/*  If */
/*     IDID = 1, call the code again to continue the integration */
/*                  another step in the direction of TOUT. */

/*     IDID = 2 or 3, define a new TOUT and call the code again. */
/*                  TOUT must be different from T. You cannot change */
/*                  the direction of integration without restarting. */

/*                 *** Following an interrupted task *** */
/*               To show the code that you realize the task was */
/*               interrupted and that you want to continue, you */
/*               must take appropriate action and set INFO(1) = 1 */
/*  If */
/*    IDID = -1, The code has taken about 500 steps. */
/*                  If you want to continue, set INFO(1) = 1 and */
/*                  call the code again. An additional 500 steps */
/*                  will be allowed. */

/*    IDID = -2, The error tolerances RTOL, ATOL have been */
/*                  increased to values the code estimates appropriate */
/*                  for continuing. You may want to change them */
/*                  yourself. If you are sure you want to continue */
/*                  with relaxed error tolerances, set INFO(1)=1 and */
/*                  call the code again. */

/*    IDID = -3, A solution component is zero and you set the */
/*                  corresponding component of ATOL to zero. If you */
/*                  are sure you want to continue, you must first */
/*                  alter the error criterion to use positive values */
/*                  for those components of ATOL corresponding to zero */
/*                  solution components, then set INFO(1)=1 and call */
/*                  the code again. */

/*    IDID = -4,-5  --- Cannot occur with this code. */

/*    IDID = -6, Repeated error test failures occurred on the */
/*                  last attempted step in DDASSL. A singularity in the */
/*                  solution may be present. If you are absolutely */
/*                  certain you want to continue, you should restart */
/*                  the integration. (Provide initial values of Y and */
/*                  YPRIME which are consistent) */

/*    IDID = -7, Repeated convergence test failures occurred */
/*                  on the last attempted step in DDASSL. An inaccurate */
/*                  or ill-conditioned JACOBIAN may be the problem. If */
/*                  you are absolutely certain you want to continue, you */
/*                  should restart the integration. */

/*    IDID = -8, The matrix of partial derivatives is singular. */
/*                  Some of your equations may be redundant. */
/*                  DDASSL cannot solve the problem as stated. */
/*                  It is possible that the redundant equations */
/*                  could be removed, and then DDASSL could */
/*                  solve the problem. It is also possible */
/*                  that a solution to your problem either */
/*                  does not exist or is not unique. */

/*    IDID = -9, DDASSL had multiple convergence test */
/*                  failures, preceeded by multiple error */
/*                  test failures, on the last attempted step. */
/*                  It is possible that your problem */
/*                  is ill-posed, and cannot be solved */
/*                  using this code. Or, there may be a */
/*                  discontinuity or a singularity in the */
/*                  solution. If you are absolutely certain */
/*                  you want to continue, you should restart */
/*                  the integration. */

/*    IDID =-10, DDASSL had multiple convergence test failures */
/*                  because IRES was equal to minus one. */
/*                  If you are absolutely certain you want */
/*                  to continue, you should restart the */
/*                  integration. */

/*    IDID =-11, IRES=-2 was encountered, and control is being */
/*                  returned to the calling program. */

/*    IDID =-12, DDASSL failed to compute the initial YPRIME. */
/*                  This could happen because the initial */
/*                  approximation to YPRIME was not very good, or */
/*                  if a YPRIME consistent with the initial Y */
/*                  does not exist. The problem could also be caused */
/*                  by an inaccurate or singular iteration matrix. */

/*    IDID = -13,..,-32  --- Cannot occur with this code. */


/*                 *** Following a terminated task *** */

/*  If IDID= -33, you cannot continue the solution of this problem. */
/*                  An attempt to do so will result in your */
/*                  run being terminated. */


/*  -------- ERROR MESSAGES --------------------------------------------- */

/*      The SLATEC error print routine XERMSG is called in the event of */
/*   unsuccessful completion of a task.  Most of these are treated as */
/*   "recoverable errors", which means that (unless the user has directed */
/*   otherwise) control will be returned to the calling program for */
/*   possible action after the message has been printed. */

/*   In the event of a negative value of IDID other than -33, an appro- */
/*   priate message is printed and the "error number" printed by XERMSG */
/*   is the value of IDID.  There are quite a number of illegal input */
/*   errors that can lead to a returned value IDID=-33.  The conditions */
/*   and their printed "error numbers" are as follows: */

/*   Error number       Condition */

/*        1       Some element of INFO vector is not zero or one. */
/*        2       NEQ .le. 0 */
/*        3       MAXORD not in range. */
/*        4       LRW is less than the required length for RWORK. */
/*        5       LIW is less than the required length for IWORK. */
/*        6       Some element of RTOL is .lt. 0 */
/*        7       Some element of ATOL is .lt. 0 */
/*        8       All elements of RTOL and ATOL are zero. */
/*        9       INFO(4)=1 and TSTOP is behind TOUT. */
/*       10       HMAX .lt. 0.0 */
/*       11       TOUT is behind T. */
/*       12       INFO(8)=1 and H0=0.0 */
/*       13       Some element of WT is .le. 0.0 */
/*       14       TOUT is too close to T to start integration. */
/*       15       INFO(4)=1 and TSTOP is behind T. */
/*       16       --( Not used in this version )-- */
/*       17       ML illegal.  Either .lt. 0 or .gt. NEQ */
/*       18       MU illegal.  Either .lt. 0 or .gt. NEQ */
/*       19       TOUT = T. */

/*   If DDASSL is called again without any action taken to remove the */
/*   cause of an unsuccessful return, XERMSG will be called with a fatal */
/*   error flag, which will cause unconditional termination of the */
/*   program.  There are two such fatal errors: */

/*   Error number -998:  The last step was terminated with a negative */
/*       value of IDID other than -33, and no appropriate action was */
/*       taken. */

/*   Error number -999:  The previous call was terminated because of */
/*       illegal input (IDID=-33) and there is illegal input in the */
/*       present call, as well.  (Suspect infinite loop.) */

/*  --------------------------------------------------------------------- */

/* ***REFERENCES  A DESCRIPTION OF DASSL: A DIFFERENTIAL/ALGEBRAIC */
/*                 SYSTEM SOLVER, L. R. PETZOLD, SAND82-8637, */
/*                 SANDIA NATIONAL LABORATORIES, SEPTEMBER 1982. */
/* ***ROUTINES CALLED  D1MACH, DDAINI, DDANRM, DDASTP, DDATRP, DDAWTS, */
/*                    XERMSG */
/* ***REVISION HISTORY  (YYMMDD) */
/*   830315  DATE WRITTEN */
/*   880387  Code changes made.  All common statements have been */
/*           replaced by a DATA statement, which defines pointers into */
/*           RWORK, and PARAMETER statements which define pointers */
/*           into IWORK.  As well the documentation has gone through */
/*           grammatical changes. */
/*   881005  The prologue has been changed to mixed case. */
/*           The subordinate routines had revision dates changed to */
/*           this date, although the documentation for these routines */
/*           is all upper case.  No code changes. */
/*   890511  Code changes made.  The DATA statement in the declaration */
/*           section of DDASSL was replaced with a PARAMETER */
/*           statement.  Also the statement S = 100.D0 was removed */
/*           from the top of the Newton iteration in DDASTP. */
/*           The subordinate routines had revision dates changed to */
/*           this date. */
/*   890517  The revision date syntax was replaced with the revision */
/*           history syntax.  Also the "DECK" comment was added to */
/*           the top of all subroutines.  These changes are consistent */
/*           with new SLATEC guidelines. */
/*           The subordinate routines had revision dates changed to */
/*           this date.  No code changes. */
/*   891013  Code changes made. */
/*           Removed all occurrances of FLOAT or DBLE.  All operations */
/*           are now performed with "mixed-mode" arithmetic. */
/*           Also, specific function names were replaced with generic */
/*           function names to be consistent with new SLATEC guidelines. */
/*           In particular: */
/*              Replaced DSQRT with SQRT everywhere. */
/*              Replaced DABS with ABS everywhere. */
/*              Replaced DMIN1 with MIN everywhere. */
/*              Replaced MIN0 with MIN everywhere. */
/*              Replaced DMAX1 with MAX everywhere. */
/*              Replaced MAX0 with MAX everywhere. */
/*              Replaced DSIGN with SIGN everywhere. */
/*           Also replaced REVISION DATE with REVISION HISTORY in all */
/*           subordinate routines. */
/*  901004  Miscellaneous changes to prologue to complete conversion */
/*          to SLATEC 4.0 format.  No code changes.  (F.N.Fritsch) */
/*  901009  Corrected GAMS classification code and converted subsidiary */
/*          routines to 4.0 format.  No code changes.  (F.N.Fritsch) */
/*  901010  Converted XERRWV calls to XERMSG calls.  (R.Clemens,AFWL) */
/*  901019  Code changes made. */
/*          Merged SLATEC 4.0 changes with previous changes made */
/*          by C. Ulrich.  Below is a history of the changes made by */
/*          C. Ulrich. (Changes in subsidiary routines are implied */
/*          by this history) */
/*          891228  Bug was found and repaired inside the DDASSL */
/*                  and DDAINI routines.  DDAINI was incorrectly */
/*                  returning the initial T with Y and YPRIME */
/*                  computed at T+H.  The routine now returns T+H */
/*                  rather than the initial T. */
/*                  Cosmetic changes made to DDASTP. */
/*          900904  Three modifications were made to fix a bug (inside */
/*                  DDASSL) re interpolation for continuation calls and */
/*                  cases where TN is very close to TSTOP: */

/*                  1) In testing for whether H is too large, just */
/*                     compare H to (TSTOP - TN), rather than */
/*                     (TSTOP - TN) * (1-4*UROUND), and set H to */
/*                     TSTOP - TN.  This will force DDASTP to step */
/*                     exactly to TSTOP under certain situations */
/*                     (i.e. when H returned from DDASTP would otherwise */
/*                     take TN beyond TSTOP). */

/*                  2) Inside the DDASTP loop, interpolate exactly to */
/*                     TSTOP if TN is very close to TSTOP (rather than */
/*                     interpolating to within roundoff of TSTOP). */

/*                  3) Modified IDID description for IDID = 2 to say that */
/*                     the solution is returned by stepping exactly to */
/*                     TSTOP, rather than TOUT.  (In some cases the */
/*                     solution is actually obtained by extrapolating */
/*                     over a distance near unit roundoff to TSTOP, */
/*                     but this small distance is deemed acceptable in */
/*                     these circumstances.) */
/*   901026  Added explicit declarations for all variables and minor */
/*           cosmetic changes to prologue, removed unreferenced labels, */
/*           and improved XERMSG calls.  (FNF) */
/*   901030  Added ERROR MESSAGES section and reworked other sections to */
/*           be of more uniform format.  (FNF) */
/*   910624  Fixed minor bug related to HMAX (five lines ending in */
/*           statement 526 in DDASSL).   (LRP) */

/* ***END PROLOGUE  DDASSL */

/* **End */

/*     Declare arguments. */


/*     Declare externals. */


/*     Declare local variables. */

/*       Auxiliary variables for conversion of values to be included in */
/*       error messages. */

/*     SET POINTERS INTO IWORK */

/*     SET RELATIVE OFFSET INTO RWORK */

/*     SET POINTERS INTO RWORK */

/* ***FIRST EXECUTABLE STATEMENT  DDASSL */
    /* Parameter adjustments */
    --ipar;
    --rpar;
    --iwork;
    --rwork;
    --atol;
    --rtol;
    --info;
    --yprime;
    --y;

    /* Function Body */
    if (info[1] != 0) {
	goto L100;
    }

/* ----------------------------------------------------------------------- */
/*     THIS BLOCK IS EXECUTED FOR THE INITIAL CALL ONLY. */
/*     IT CONTAINS CHECKING OF INPUTS AND INITIALIZATIONS. */
/* ----------------------------------------------------------------------- */

/*     FIRST CHECK INFO ARRAY TO MAKE SURE ALL ELEMENTS OF INFO */
/*     ARE EITHER ZERO OR ONE. */
    for (i__ = 2; i__ <= 11; ++i__) {
	if (info[i__] != 0 && info[i__] != 1) {
	    goto L701;
	}
/* L10: */
    }

    if (*neq <= 0) {
	goto L702;
    }

/*     CHECK AND COMPUTE MAXIMUM ORDER */
    mxord = 5;
    if (info[9] == 0) {
	goto L20;
    }
    mxord = iwork[3];
    if (mxord < 1 || mxord > 5) {
	goto L703;
    }
L20:
    iwork[3] = mxord;

/*     COMPUTE MTYPE,LENPD,LENRW.CHECK ML AND MU. */
    if (info[6] != 0) {
	goto L40;
    }
/* Computing 2nd power */
    i__1 = *neq;
    lenpd = i__1 * i__1;
    lenrw = (iwork[3] + 4) * *neq + 40 + lenpd;
    if (info[5] != 0) {
	goto L30;
    }
    iwork[4] = 2;
    goto L60;
L30:
    iwork[4] = 1;
    goto L60;
L40:
    if (iwork[1] < 0 || iwork[1] >= *neq) {
	goto L717;
    }
    if (iwork[2] < 0 || iwork[2] >= *neq) {
	goto L718;
    }
    lenpd = ((iwork[1] << 1) + iwork[2] + 1) * *neq;
    if (info[5] != 0) {
	goto L50;
    }
    iwork[4] = 5;
    mband = iwork[1] + iwork[2] + 1;
    msave = *neq / mband + 1;
    lenrw = (iwork[3] + 4) * *neq + 40 + lenpd + (msave << 1);
    goto L60;
L50:
    iwork[4] = 4;
    lenrw = (iwork[3] + 4) * *neq + 40 + lenpd;

/*     CHECK LENGTHS OF RWORK AND IWORK */
L60:
    leniw = *neq + 20;
    iwork[16] = lenpd;
    if (*lrw < lenrw) {
	goto L704;
    }
    if (*liw < leniw) {
	goto L705;
    }

/*     CHECK TO SEE THAT TOUT IS DIFFERENT FROM T */
    if (*tout == *t) {
	goto L719;
    }

/*     CHECK HMAX */
    if (info[7] == 0) {
	goto L70;
    }
    hmax = rwork[2];
    if (hmax <= 0.) {
	goto L710;
    }
L70:

/*     INITIALIZE COUNTERS */
    iwork[11] = 0;
    iwork[12] = 0;
    iwork[13] = 0;

    iwork[10] = 0;
    *idid = 1;
    goto L200;

/* ----------------------------------------------------------------------- */
/*     THIS BLOCK IS FOR CONTINUATION CALLS */
/*     ONLY. HERE WE CHECK INFO(1),AND IF THE */
/*     LAST STEP WAS INTERRUPTED WE CHECK WHETHER */
/*     APPROPRIATE ACTION WAS TAKEN. */
/* ----------------------------------------------------------------------- */

L100:
    if (info[1] == 1) {
	goto L110;
    }
    if (info[1] != -1) {
	goto L701;
    }

/*     IF WE ARE HERE, THE LAST STEP WAS INTERRUPTED */
/*     BY AN ERROR CONDITION FROM DDASTP,AND */
/*     APPROPRIATE ACTION WAS NOT TAKEN. THIS */
/*     IS A FATAL ERROR. */
    s_wsfi(&io___10);
    do_fio(&c__1, (char *)&(*idid), (ftnlen)sizeof(integer));
    e_wsfi();
/* Writing concatenation */
    i__2[0] = 57, a__1[0] = "THE LAST STEP TERMINATED WITH A NEGATIVE VALUE "
	    "OF IDID = ";
    i__2[1] = 8, a__1[1] = xern1;
    i__2[2] = 39, a__1[2] = " AND NO APPROPRIATE ACTION WAS TAKEN.  ";
    i__2[3] = 14, a__1[3] = "RUN TERMINATED";
    s_cat(ch__1, a__1, i__2, &c__4, (ftnlen)118);
    xermsg_("SLATEC", "DDASSL", ch__1, &c_n998, &c__2, (ftnlen)6, (ftnlen)6, (
	    ftnlen)118);
    return 0;
L110:
    iwork[10] = iwork[11];

/* ----------------------------------------------------------------------- */
/*     THIS BLOCK IS EXECUTED ON ALL CALLS. */
/*     THE ERROR TOLERANCE PARAMETERS ARE */
/*     CHECKED, AND THE WORK ARRAY POINTERS */
/*     ARE SET. */
/* ----------------------------------------------------------------------- */

L200:
/*     CHECK RTOL,ATOL */
    nzflg = 0;
    rtoli = rtol[1];
    atoli = atol[1];
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (info[2] == 1) {
	    rtoli = rtol[i__];
	}
	if (info[2] == 1) {
	    atoli = atol[i__];
	}
	if (rtoli > 0. || atoli > 0.) {
	    nzflg = 1;
	}
	if (rtoli < 0.) {
	    goto L706;
	}
	if (atoli < 0.) {
	    goto L707;
	}
/* L210: */
    }
    if (nzflg == 0) {
	goto L708;
    }

/*     SET UP RWORK STORAGE.IWORK STORAGE IS FIXED */
/*     IN DATA STATEMENT. */
    le = *neq + 41;
    lwt = le + *neq;
    lphi = lwt + *neq;
    lpd = lphi + (iwork[3] + 1) * *neq;
    lwm = lpd;
    ntemp = iwork[16] + 1;
    if (info[1] == 1) {
	goto L400;
    }

/* ----------------------------------------------------------------------- */
/*     THIS BLOCK IS EXECUTED ON THE INITIAL CALL */
/*     ONLY. SET THE INITIAL STEP SIZE, AND */
/*     THE ERROR WEIGHT VECTOR, AND PHI. */
/*     COMPUTE INITIAL YPRIME, IF NECESSARY. */
/* ----------------------------------------------------------------------- */

    tn = *t;
    *idid = 1;

/*     SET ERROR WEIGHT VECTOR WT */
    ddawts_(neq, &info[2], &rtol[1], &atol[1], &y[1], &rwork[lwt], &rpar[1], &
	    ipar[1]);
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (rwork[lwt + i__ - 1] <= 0.) {
	    goto L713;
	}
/* L305: */
    }

/*     COMPUTE UNIT ROUNDOFF AND HMIN */
    uround = d1mach_(&c__4);
    rwork[9] = uround;
/* Computing MAX */
    d__1 = abs(*t), d__2 = abs(*tout);
    hmin = uround * 4. * max(d__1,d__2);

/*     CHECK INITIAL INTERVAL TO SEE THAT IT IS LONG ENOUGH */
    tdist = (d__1 = *tout - *t, abs(d__1));
    if (tdist < hmin) {
	goto L714;
    }

/*     CHECK HO, IF THIS WAS INPUT */
    if (info[8] == 0) {
	goto L310;
    }
    ho = rwork[3];
    if ((*tout - *t) * ho < 0.) {
	goto L711;
    }
    if (ho == 0.) {
	goto L712;
    }
    goto L320;
L310:

/*     COMPUTE INITIAL STEPSIZE, TO BE USED BY EITHER */
/*     DDASTP OR DDAINI, DEPENDING ON INFO(11) */
    ho = tdist * .001;
    ypnorm = ddanrm_(neq, &yprime[1], &rwork[lwt], &rpar[1], &ipar[1]);
    if (ypnorm > .5 / ho) {
	ho = .5 / ypnorm;
    }
    d__1 = *tout - *t;
    ho = d_sign(&ho, &d__1);
/*     ADJUST HO IF NECESSARY TO MEET HMAX BOUND */
L320:
    if (info[7] == 0) {
	goto L330;
    }
    rh = abs(ho) / rwork[2];
    if (rh > 1.) {
	ho /= rh;
    }
/*     COMPUTE TSTOP, IF APPLICABLE */
L330:
    if (info[4] == 0) {
	goto L340;
    }
    tstop = rwork[1];
    if ((tstop - *t) * ho < 0.) {
	goto L715;
    }
    if ((*t + ho - tstop) * ho > 0.) {
	ho = tstop - *t;
    }
    if ((tstop - *tout) * ho < 0.) {
	goto L709;
    }

/*     COMPUTE INITIAL DERIVATIVE, UPDATING TN AND Y, IF APPLICABLE */
L340:
    if (info[11] == 0) {
	goto L350;
    }
    ddaini_(&tn, &y[1], &yprime[1], neq, (U_fp)res, (U_fp)jac, &ho, &rwork[
	    lwt], idid, &rpar[1], &ipar[1], &rwork[lphi], &rwork[41], &rwork[
	    le], &rwork[lwm], &iwork[1], &hmin, &rwork[9], &info[10], &ntemp);
    if (*idid < 0) {
	goto L390;
    }

/*     LOAD H WITH HO.  STORE H IN RWORK(LH) */
L350:
    h__ = ho;
    rwork[3] = h__;

/*     LOAD Y AND H*YPRIME INTO PHI(*,1) AND PHI(*,2) */
    itemp = lphi + *neq;
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	rwork[lphi + i__ - 1] = y[i__];
/* L370: */
	rwork[itemp + i__ - 1] = h__ * yprime[i__];
    }

L390:
    goto L500;

/* ------------------------------------------------------- */
/*     THIS BLOCK IS FOR CONTINUATION CALLS ONLY. ITS */
/*     PURPOSE IS TO CHECK STOP CONDITIONS BEFORE */
/*     TAKING A STEP. */
/*     ADJUST H IF NECESSARY TO MEET HMAX BOUND */
/* ------------------------------------------------------- */

L400:
    uround = rwork[9];
    done = FALSE_;
    tn = rwork[4];
    h__ = rwork[3];
    if (info[7] == 0) {
	goto L410;
    }
    rh = abs(h__) / rwork[2];
    if (rh > 1.) {
	h__ /= rh;
    }
L410:
    if (*t == *tout) {
	goto L719;
    }
    if ((*t - *tout) * h__ > 0.) {
	goto L711;
    }
    if (info[4] == 1) {
	goto L430;
    }
    if (info[3] == 1) {
	goto L420;
    }
    if ((tn - *tout) * h__ < 0.) {
	goto L490;
    }
    ddatrp_(&tn, tout, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    *t = *tout;
    *idid = 3;
    done = TRUE_;
    goto L490;
L420:
    if ((tn - *t) * h__ <= 0.) {
	goto L490;
    }
    if ((tn - *tout) * h__ > 0.) {
	goto L425;
    }
    ddatrp_(&tn, &tn, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &rwork[
	    29]);
    *t = tn;
    *idid = 1;
    done = TRUE_;
    goto L490;
L425:
    ddatrp_(&tn, tout, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    *t = *tout;
    *idid = 3;
    done = TRUE_;
    goto L490;
L430:
    if (info[3] == 1) {
	goto L440;
    }
    tstop = rwork[1];
    if ((tn - tstop) * h__ > 0.) {
	goto L715;
    }
    if ((tstop - *tout) * h__ < 0.) {
	goto L709;
    }
    if ((tn - *tout) * h__ < 0.) {
	goto L450;
    }
    ddatrp_(&tn, tout, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    *t = *tout;
    *idid = 3;
    done = TRUE_;
    goto L490;
L440:
    tstop = rwork[1];
    if ((tn - tstop) * h__ > 0.) {
	goto L715;
    }
    if ((tstop - *tout) * h__ < 0.) {
	goto L709;
    }
    if ((tn - *t) * h__ <= 0.) {
	goto L450;
    }
    if ((tn - *tout) * h__ > 0.) {
	goto L445;
    }
    ddatrp_(&tn, &tn, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &rwork[
	    29]);
    *t = tn;
    *idid = 1;
    done = TRUE_;
    goto L490;
L445:
    ddatrp_(&tn, tout, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    *t = *tout;
    *idid = 3;
    done = TRUE_;
    goto L490;
L450:
/*     CHECK WHETHER WE ARE WITHIN ROUNDOFF OF TSTOP */
    if ((d__1 = tn - tstop, abs(d__1)) > uround * 100. * (abs(tn) + abs(h__)))
	     {
	goto L460;
    }
    ddatrp_(&tn, &tstop, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    *idid = 2;
    *t = tstop;
    done = TRUE_;
    goto L490;
L460:
    tnext = tn + h__;
    if ((tnext - tstop) * h__ <= 0.) {
	goto L490;
    }
    h__ = tstop - tn;
    rwork[3] = h__;

L490:
    if (done) {
	goto L580;
    }

/* ------------------------------------------------------- */
/*     THE NEXT BLOCK CONTAINS THE CALL TO THE */
/*     ONE-STEP INTEGRATOR DDASTP. */
/*     THIS IS A LOOPING POINT FOR THE INTEGRATION STEPS. */
/*     CHECK FOR TOO MANY STEPS. */
/*     UPDATE WT. */
/*     CHECK FOR TOO MUCH ACCURACY REQUESTED. */
/*     COMPUTE MINIMUM STEPSIZE. */
/* ------------------------------------------------------- */

L500:
/*     CHECK FOR FAILURE TO COMPUTE INITIAL YPRIME */
    if (*idid == -12) {
	goto L527;
    }

/*     CHECK FOR TOO MANY STEPS */
    if (iwork[11] - iwork[10] < 500) {
	goto L510;
    }
    *idid = -1;
    goto L527;

/*     UPDATE WT */
L510:
    ddawts_(neq, &info[2], &rtol[1], &atol[1], &rwork[lphi], &rwork[lwt], &
	    rpar[1], &ipar[1]);
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (rwork[i__ + lwt - 1] > 0.) {
	    goto L520;
	}
	*idid = -3;
	goto L527;
L520:
	;
    }

/*     TEST FOR TOO MUCH ACCURACY REQUESTED. */
    r__ = ddanrm_(neq, &rwork[lphi], &rwork[lwt], &rpar[1], &ipar[1]) * 100. *
	     uround;
    if (r__ <= 1.) {
	goto L525;
    }
/*     MULTIPLY RTOL AND ATOL BY R AND RETURN */
    if (info[2] == 1) {
	goto L523;
    }
    rtol[1] = r__ * rtol[1];
    atol[1] = r__ * atol[1];
    *idid = -2;
    goto L527;
L523:
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	rtol[i__] = r__ * rtol[i__];
/* L524: */
	atol[i__] = r__ * atol[i__];
    }
    *idid = -2;
    goto L527;
L525:

/*     COMPUTE MINIMUM STEPSIZE */
/* Computing MAX */
    d__1 = abs(tn), d__2 = abs(*tout);
    hmin = uround * 4. * max(d__1,d__2);

/*     TEST H VS. HMAX */
    if (info[7] == 0) {
	goto L526;
    }
    rh = abs(h__) / rwork[2];
    if (rh > 1.) {
	h__ /= rh;
    }
L526:

    ddastp_(&tn, &y[1], &yprime[1], neq, (U_fp)res, (U_fp)jac, &h__, &rwork[
	    lwt], &info[1], idid, &rpar[1], &ipar[1], &rwork[lphi], &rwork[41]
	    , &rwork[le], &rwork[lwm], &iwork[1], &rwork[11], &rwork[17], &
	    rwork[23], &rwork[29], &rwork[35], &rwork[5], &rwork[6], &rwork[7]
	    , &rwork[8], &hmin, &rwork[9], &iwork[6], &iwork[5], &iwork[7], &
	    iwork[8], &iwork[9], &info[10], &ntemp);
L527:
    if (*idid < 0) {
	goto L600;
    }

/* -------------------------------------------------------- */
/*     THIS BLOCK HANDLES THE CASE OF A SUCCESSFUL RETURN */
/*     FROM DDASTP (IDID=1).  TEST FOR STOP CONDITIONS. */
/* -------------------------------------------------------- */

    if (info[4] != 0) {
	goto L540;
    }
    if (info[3] != 0) {
	goto L530;
    }
    if ((tn - *tout) * h__ < 0.) {
	goto L500;
    }
    ddatrp_(&tn, tout, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    *idid = 3;
    *t = *tout;
    goto L580;
L530:
    if ((tn - *tout) * h__ >= 0.) {
	goto L535;
    }
    *t = tn;
    *idid = 1;
    goto L580;
L535:
    ddatrp_(&tn, tout, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    *idid = 3;
    *t = *tout;
    goto L580;
L540:
    if (info[3] != 0) {
	goto L550;
    }
    if ((tn - *tout) * h__ < 0.) {
	goto L542;
    }
    ddatrp_(&tn, tout, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    *t = *tout;
    *idid = 3;
    goto L580;
L542:
    if ((d__1 = tn - tstop, abs(d__1)) <= uround * 100. * (abs(tn) + abs(h__))
	    ) {
	goto L545;
    }
    tnext = tn + h__;
    if ((tnext - tstop) * h__ <= 0.) {
	goto L500;
    }
    h__ = tstop - tn;
    goto L500;
L545:
    ddatrp_(&tn, &tstop, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    *idid = 2;
    *t = tstop;
    goto L580;
L550:
    if ((tn - *tout) * h__ >= 0.) {
	goto L555;
    }
    if ((d__1 = tn - tstop, abs(d__1)) <= uround * 100. * (abs(tn) + abs(h__))
	    ) {
	goto L552;
    }
    *t = tn;
    *idid = 1;
    goto L580;
L552:
    ddatrp_(&tn, &tstop, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    *idid = 2;
    *t = tstop;
    goto L580;
L555:
    ddatrp_(&tn, tout, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    *t = *tout;
    *idid = 3;
    goto L580;

/* -------------------------------------------------------- */
/*     ALL SUCCESSFUL RETURNS FROM DDASSL ARE MADE FROM */
/*     THIS BLOCK. */
/* -------------------------------------------------------- */

L580:
    rwork[4] = tn;
    rwork[3] = h__;
    return 0;

/* ----------------------------------------------------------------------- */
/*     THIS BLOCK HANDLES ALL UNSUCCESSFUL */
/*     RETURNS OTHER THAN FOR ILLEGAL INPUT. */
/* ----------------------------------------------------------------------- */

L600:
    itemp = -(*idid);
    switch (itemp) {
	case 1:  goto L610;
	case 2:  goto L620;
	case 3:  goto L630;
	case 4:  goto L690;
	case 5:  goto L690;
	case 6:  goto L640;
	case 7:  goto L650;
	case 8:  goto L660;
	case 9:  goto L670;
	case 10:  goto L675;
	case 11:  goto L680;
	case 12:  goto L685;
    }

/*     THE MAXIMUM NUMBER OF STEPS WAS TAKEN BEFORE */
/*     REACHING TOUT */
L610:
    s_wsfi(&io___34);
    do_fio(&c__1, (char *)&tn, (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__2[0] = 15, a__1[0] = "AT CURRENT T = ";
    i__2[1] = 16, a__1[1] = xern3;
    i__2[2] = 25, a__1[2] = " 500 STEPS TAKEN ON THIS ";
    i__2[3] = 25, a__1[3] = "CALL BEFORE REACHING TOUT";
    s_cat(ch__2, a__1, i__2, &c__4, (ftnlen)81);
    xermsg_("SLATEC", "DDASSL", ch__2, idid, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)81);
    goto L690;

/*     TOO MUCH ACCURACY FOR MACHINE PRECISION */
L620:
    s_wsfi(&io___35);
    do_fio(&c__1, (char *)&tn, (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__3[0] = 7, a__2[0] = "AT T = ";
    i__3[1] = 16, a__2[1] = xern3;
    i__3[2] = 33, a__2[2] = " TOO MUCH ACCURACY REQUESTED FOR ";
    i__3[3] = 54, a__2[3] = "PRECISION OF MACHINE. RTOL AND ATOL WERE INCREA"
	    "SED TO ";
    i__3[4] = 18, a__2[4] = "APPROPRIATE VALUES";
    s_cat(ch__3, a__2, i__3, &c__5, (ftnlen)128);
    xermsg_("SLATEC", "DDASSL", ch__3, idid, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)128);
    goto L690;

/*     WT(I) .LE. 0.0 FOR SOME I (NOT AT START OF PROBLEM) */
L630:
    s_wsfi(&io___36);
    do_fio(&c__1, (char *)&tn, (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__2[0] = 7, a__1[0] = "AT T = ";
    i__2[1] = 16, a__1[1] = xern3;
    i__2[2] = 36, a__1[2] = " SOME ELEMENT OF WT HAS BECOME .LE. ";
    i__2[3] = 3, a__1[3] = "0.0";
    s_cat(ch__4, a__1, i__2, &c__4, (ftnlen)62);
    xermsg_("SLATEC", "DDASSL", ch__4, idid, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)62);
    goto L690;

/*     ERROR TEST FAILED REPEATEDLY OR WITH H=HMIN */
L640:
    s_wsfi(&io___37);
    do_fio(&c__1, (char *)&tn, (ftnlen)sizeof(doublereal));
    e_wsfi();
    s_wsfi(&io___39);
    do_fio(&c__1, (char *)&h__, (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__3[0] = 7, a__2[0] = "AT T = ";
    i__3[1] = 16, a__2[1] = xern3;
    i__3[2] = 18, a__2[2] = " AND STEPSIZE H = ";
    i__3[3] = 16, a__2[3] = xern4;
    i__3[4] = 53, a__2[4] = " THE ERROR TEST FAILED REPEATEDLY OR WITH ABS(H"
	    ")=HMIN";
    s_cat(ch__5, a__2, i__3, &c__5, (ftnlen)110);
    xermsg_("SLATEC", "DDASSL", ch__5, idid, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)110);
    goto L690;

/*     CORRECTOR CONVERGENCE FAILED REPEATEDLY OR WITH H=HMIN */
L650:
    s_wsfi(&io___40);
    do_fio(&c__1, (char *)&tn, (ftnlen)sizeof(doublereal));
    e_wsfi();
    s_wsfi(&io___41);
    do_fio(&c__1, (char *)&h__, (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__4[0] = 7, a__3[0] = "AT T = ";
    i__4[1] = 16, a__3[1] = xern3;
    i__4[2] = 18, a__3[2] = " AND STEPSIZE H = ";
    i__4[3] = 16, a__3[3] = xern4;
    i__4[4] = 53, a__3[4] = " THE CORRECTOR FAILED TO CONVERGE REPEATEDLY OR"
	    " WITH ";
    i__4[5] = 11, a__3[5] = "ABS(H)=HMIN";
    s_cat(ch__6, a__3, i__4, &c__6, (ftnlen)121);
    xermsg_("SLATEC", "DDASSL", ch__6, idid, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)121);
    goto L690;

/*     THE ITERATION MATRIX IS SINGULAR */
L660:
    s_wsfi(&io___42);
    do_fio(&c__1, (char *)&tn, (ftnlen)sizeof(doublereal));
    e_wsfi();
    s_wsfi(&io___43);
    do_fio(&c__1, (char *)&h__, (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__3[0] = 7, a__2[0] = "AT T = ";
    i__3[1] = 16, a__2[1] = xern3;
    i__3[2] = 18, a__2[2] = " AND STEPSIZE H = ";
    i__3[3] = 16, a__2[3] = xern4;
    i__3[4] = 33, a__2[4] = " THE ITERATION MATRIX IS SINGULAR";
    s_cat(ch__7, a__2, i__3, &c__5, (ftnlen)90);
    xermsg_("SLATEC", "DDASSL", ch__7, idid, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)90);
    goto L690;

/*     CORRECTOR FAILURE PRECEEDED BY ERROR TEST FAILURES. */
L670:
    s_wsfi(&io___44);
    do_fio(&c__1, (char *)&tn, (ftnlen)sizeof(doublereal));
    e_wsfi();
    s_wsfi(&io___45);
    do_fio(&c__1, (char *)&h__, (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__4[0] = 7, a__3[0] = "AT T = ";
    i__4[1] = 16, a__3[1] = xern3;
    i__4[2] = 18, a__3[2] = " AND STEPSIZE H = ";
    i__4[3] = 16, a__3[3] = xern4;
    i__4[4] = 57, a__3[4] = " THE CORRECTOR COULD NOT CONVERGE.  ALSO, THE E"
	    "RROR TEST ";
    i__4[5] = 18, a__3[5] = "FAILED REPEATEDLY.";
    s_cat(ch__8, a__3, i__4, &c__6, (ftnlen)132);
    xermsg_("SLATEC", "DDASSL", ch__8, idid, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)132);
    goto L690;

/*     CORRECTOR FAILURE BECAUSE IRES = -1 */
L675:
    s_wsfi(&io___46);
    do_fio(&c__1, (char *)&tn, (ftnlen)sizeof(doublereal));
    e_wsfi();
    s_wsfi(&io___47);
    do_fio(&c__1, (char *)&h__, (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__4[0] = 7, a__3[0] = "AT T = ";
    i__4[1] = 16, a__3[1] = xern3;
    i__4[2] = 18, a__3[2] = " AND STEPSIZE H = ";
    i__4[3] = 16, a__3[3] = xern4;
    i__4[4] = 57, a__3[4] = " THE CORRECTOR COULD NOT CONVERGE BECAUSE IRES "
	    "WAS EQUAL ";
    i__4[5] = 12, a__3[5] = "TO MINUS ONE";
    s_cat(ch__9, a__3, i__4, &c__6, (ftnlen)126);
    xermsg_("SLATEC", "DDASSL", ch__9, idid, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)126);
    goto L690;

/*     FAILURE BECAUSE IRES = -2 */
L680:
    s_wsfi(&io___48);
    do_fio(&c__1, (char *)&tn, (ftnlen)sizeof(doublereal));
    e_wsfi();
    s_wsfi(&io___49);
    do_fio(&c__1, (char *)&h__, (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__3[0] = 7, a__2[0] = "AT T = ";
    i__3[1] = 16, a__2[1] = xern3;
    i__3[2] = 18, a__2[2] = " AND STEPSIZE H = ";
    i__3[3] = 16, a__2[3] = xern4;
    i__3[4] = 28, a__2[4] = " IRES WAS EQUAL TO MINUS TWO";
    s_cat(ch__10, a__2, i__3, &c__5, (ftnlen)85);
    xermsg_("SLATEC", "DDASSL", ch__10, idid, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)85);
    goto L690;

/*     FAILED TO COMPUTE INITIAL YPRIME */
L685:
    s_wsfi(&io___50);
    do_fio(&c__1, (char *)&tn, (ftnlen)sizeof(doublereal));
    e_wsfi();
    s_wsfi(&io___51);
    do_fio(&c__1, (char *)&ho, (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__3[0] = 7, a__2[0] = "AT T = ";
    i__3[1] = 16, a__2[1] = xern3;
    i__3[2] = 18, a__2[2] = " AND STEPSIZE H = ";
    i__3[3] = 16, a__2[3] = xern4;
    i__3[4] = 41, a__2[4] = " THE INITIAL YPRIME COULD NOT BE COMPUTED";
    s_cat(ch__11, a__2, i__3, &c__5, (ftnlen)98);
    xermsg_("SLATEC", "DDASSL", ch__11, idid, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)98);
    goto L690;

L690:
    info[1] = -1;
    *t = tn;
    rwork[4] = tn;
    rwork[3] = h__;
    return 0;

/* ----------------------------------------------------------------------- */
/*     THIS BLOCK HANDLES ALL ERROR RETURNS DUE */
/*     TO ILLEGAL INPUT, AS DETECTED BEFORE CALLING */
/*     DDASTP. FIRST THE ERROR MESSAGE ROUTINE IS */
/*     CALLED. IF THIS HAPPENS TWICE IN */
/*     SUCCESSION, EXECUTION IS TERMINATED */

/* ----------------------------------------------------------------------- */
L701:
    xermsg_("SLATEC", "DDASSL", "SOME ELEMENT OF INFO VECTOR IS NOT ZERO OR "
	    "ONE", &c__1, &c__1, (ftnlen)6, (ftnlen)6, (ftnlen)46);
    goto L750;

L702:
    s_wsfi(&io___52);
    do_fio(&c__1, (char *)&(*neq), (ftnlen)sizeof(integer));
    e_wsfi();
/* Writing concatenation */
    i__5[0] = 6, a__4[0] = "NEQ = ";
    i__5[1] = 8, a__4[1] = xern1;
    i__5[2] = 7, a__4[2] = " .LE. 0";
    s_cat(ch__12, a__4, i__5, &c__3, (ftnlen)21);
    xermsg_("SLATEC", "DDASSL", ch__12, &c__2, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)21);
    goto L750;

L703:
    s_wsfi(&io___53);
    do_fio(&c__1, (char *)&mxord, (ftnlen)sizeof(integer));
    e_wsfi();
/* Writing concatenation */
    i__5[0] = 9, a__4[0] = "MAXORD = ";
    i__5[1] = 8, a__4[1] = xern1;
    i__5[2] = 13, a__4[2] = " NOT IN RANGE";
    s_cat(ch__13, a__4, i__5, &c__3, (ftnlen)30);
    xermsg_("SLATEC", "DDASSL", ch__13, &c__3, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)30);
    goto L750;

L704:
    s_wsfi(&io___54);
    do_fio(&c__1, (char *)&lenrw, (ftnlen)sizeof(integer));
    e_wsfi();
    s_wsfi(&io___56);
    do_fio(&c__1, (char *)&(*lrw), (ftnlen)sizeof(integer));
    e_wsfi();
/* Writing concatenation */
    i__2[0] = 29, a__1[0] = "RWORK LENGTH NEEDED, LENRW = ";
    i__2[1] = 8, a__1[1] = xern1;
    i__2[2] = 16, a__1[2] = ", EXCEEDS LRW = ";
    i__2[3] = 8, a__1[3] = xern2;
    s_cat(ch__14, a__1, i__2, &c__4, (ftnlen)61);
    xermsg_("SLATEC", "DDASSL", ch__14, &c__4, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)61);
    goto L750;

L705:
    s_wsfi(&io___57);
    do_fio(&c__1, (char *)&leniw, (ftnlen)sizeof(integer));
    e_wsfi();
    s_wsfi(&io___58);
    do_fio(&c__1, (char *)&(*liw), (ftnlen)sizeof(integer));
    e_wsfi();
/* Writing concatenation */
    i__2[0] = 29, a__1[0] = "IWORK LENGTH NEEDED, LENIW = ";
    i__2[1] = 8, a__1[1] = xern1;
    i__2[2] = 16, a__1[2] = ", EXCEEDS LIW = ";
    i__2[3] = 8, a__1[3] = xern2;
    s_cat(ch__14, a__1, i__2, &c__4, (ftnlen)61);
    xermsg_("SLATEC", "DDASSL", ch__14, &c__5, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)61);
    goto L750;

L706:
    xermsg_("SLATEC", "DDASSL", "SOME ELEMENT OF RTOL IS .LT. 0", &c__6, &
	    c__1, (ftnlen)6, (ftnlen)6, (ftnlen)30);
    goto L750;

L707:
    xermsg_("SLATEC", "DDASSL", "SOME ELEMENT OF ATOL IS .LT. 0", &c__7, &
	    c__1, (ftnlen)6, (ftnlen)6, (ftnlen)30);
    goto L750;

L708:
    xermsg_("SLATEC", "DDASSL", "ALL ELEMENTS OF RTOL AND ATOL ARE ZERO", &
	    c__8, &c__1, (ftnlen)6, (ftnlen)6, (ftnlen)38);
    goto L750;

L709:
    s_wsfi(&io___59);
    do_fio(&c__1, (char *)&tstop, (ftnlen)sizeof(doublereal));
    e_wsfi();
    s_wsfi(&io___60);
    do_fio(&c__1, (char *)&(*tout), (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__2[0] = 24, a__1[0] = "INFO(4) = 1 AND TSTOP = ";
    i__2[1] = 16, a__1[1] = xern3;
    i__2[2] = 15, a__1[2] = " BEHIND TOUT = ";
    i__2[3] = 16, a__1[3] = xern4;
    s_cat(ch__15, a__1, i__2, &c__4, (ftnlen)71);
    xermsg_("SLATEC", "DDASSL", ch__15, &c__9, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)71);
    goto L750;

L710:
    s_wsfi(&io___61);
    do_fio(&c__1, (char *)&hmax, (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__5[0] = 7, a__4[0] = "HMAX = ";
    i__5[1] = 16, a__4[1] = xern3;
    i__5[2] = 9, a__4[2] = " .LT. 0.0";
    s_cat(ch__16, a__4, i__5, &c__3, (ftnlen)32);
    xermsg_("SLATEC", "DDASSL", ch__16, &c__10, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)32);
    goto L750;

L711:
    s_wsfi(&io___62);
    do_fio(&c__1, (char *)&(*tout), (ftnlen)sizeof(doublereal));
    e_wsfi();
    s_wsfi(&io___63);
    do_fio(&c__1, (char *)&(*t), (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__2[0] = 7, a__1[0] = "TOUT = ";
    i__2[1] = 16, a__1[1] = xern3;
    i__2[2] = 12, a__1[2] = " BEHIND T = ";
    i__2[3] = 16, a__1[3] = xern4;
    s_cat(ch__17, a__1, i__2, &c__4, (ftnlen)51);
    xermsg_("SLATEC", "DDASSL", ch__17, &c__11, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)51);
    goto L750;

L712:
    xermsg_("SLATEC", "DDASSL", "INFO(8)=1 AND H0=0.0", &c__12, &c__1, (
	    ftnlen)6, (ftnlen)6, (ftnlen)20);
    goto L750;

L713:
    xermsg_("SLATEC", "DDASSL", "SOME ELEMENT OF WT IS .LE. 0.0", &c__13, &
	    c__1, (ftnlen)6, (ftnlen)6, (ftnlen)30);
    goto L750;

L714:
    s_wsfi(&io___64);
    do_fio(&c__1, (char *)&(*tout), (ftnlen)sizeof(doublereal));
    e_wsfi();
    s_wsfi(&io___65);
    do_fio(&c__1, (char *)&(*t), (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__3[0] = 7, a__2[0] = "TOUT = ";
    i__3[1] = 16, a__2[1] = xern3;
    i__3[2] = 18, a__2[2] = " TOO CLOSE TO T = ";
    i__3[3] = 16, a__2[3] = xern4;
    i__3[4] = 21, a__2[4] = " TO START INTEGRATION";
    s_cat(ch__18, a__2, i__3, &c__5, (ftnlen)78);
    xermsg_("SLATEC", "DDASSL", ch__18, &c__14, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)78);
    goto L750;

L715:
    s_wsfi(&io___66);
    do_fio(&c__1, (char *)&tstop, (ftnlen)sizeof(doublereal));
    e_wsfi();
    s_wsfi(&io___67);
    do_fio(&c__1, (char *)&(*t), (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__2[0] = 22, a__1[0] = "INFO(4)=1 AND TSTOP = ";
    i__2[1] = 16, a__1[1] = xern3;
    i__2[2] = 12, a__1[2] = " BEHIND T = ";
    i__2[3] = 16, a__1[3] = xern4;
    s_cat(ch__19, a__1, i__2, &c__4, (ftnlen)66);
    xermsg_("SLATEC", "DDASSL", ch__19, &c__15, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)66);
    goto L750;

L717:
    s_wsfi(&io___68);
    do_fio(&c__1, (char *)&iwork[1], (ftnlen)sizeof(integer));
    e_wsfi();
/* Writing concatenation */
    i__5[0] = 5, a__4[0] = "ML = ";
    i__5[1] = 8, a__4[1] = xern1;
    i__5[2] = 36, a__4[2] = " ILLEGAL.  EITHER .LT. 0 OR .GT. NEQ";
    s_cat(ch__20, a__4, i__5, &c__3, (ftnlen)49);
    xermsg_("SLATEC", "DDASSL", ch__20, &c__17, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)49);
    goto L750;

L718:
    s_wsfi(&io___69);
    do_fio(&c__1, (char *)&iwork[2], (ftnlen)sizeof(integer));
    e_wsfi();
/* Writing concatenation */
    i__5[0] = 5, a__4[0] = "MU = ";
    i__5[1] = 8, a__4[1] = xern1;
    i__5[2] = 36, a__4[2] = " ILLEGAL.  EITHER .LT. 0 OR .GT. NEQ";
    s_cat(ch__20, a__4, i__5, &c__3, (ftnlen)49);
    xermsg_("SLATEC", "DDASSL", ch__20, &c__18, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)49);
    goto L750;

L719:
    s_wsfi(&io___70);
    do_fio(&c__1, (char *)&(*tout), (ftnlen)sizeof(doublereal));
    e_wsfi();
/* Writing concatenation */
    i__6[0] = 11, a__5[0] = "TOUT = T = ";
    i__6[1] = 16, a__5[1] = xern3;
    s_cat(ch__21, a__5, i__6, &c__2, (ftnlen)27);
    xermsg_("SLATEC", "DDASSL", ch__21, &c__19, &c__1, (ftnlen)6, (ftnlen)6, (
	    ftnlen)27);
    goto L750;

L750:
    *idid = -33;
    if (info[1] == -1) {
	xermsg_("SLATEC", "DDASSL", "REPEATED OCCURRENCES OF ILLEGAL INPUT$$"
		"RUN TERMINATED. APPARENT INFINITE LOOP", &c_n999, &c__2, (
		ftnlen)6, (ftnlen)6, (ftnlen)77);
    }

    info[1] = -1;
    return 0;
/* -----------END OF SUBROUTINE DDASSL------------------------------------ */
} /* ddassl_ */

/* Subroutine */ int ddawts_(integer *neq, integer *iwt, doublereal *rtol,
	doublereal *atol, doublereal *y, doublereal *wt, doublereal *rpar,
	integer *ipar)
{
    /* System generated locals */
    integer i__1;
    doublereal d__1;

    /* Local variables */
    static integer i__;
    static doublereal atoli, rtoli;

/* ***BEGIN PROLOGUE  DDAWTS */
/* ***SUBSIDIARY */
/* ***PURPOSE  Set error weight vector for DDASSL. */
/* ***LIBRARY   SLATEC (DASSL) */
/* ***TYPE      DOUBLE PRECISION (SDAWTS-S, DDAWTS-D) */
/* ***AUTHOR  PETZOLD, LINDA R., (LLNL) */
/* ***DESCRIPTION */
/* ----------------------------------------------------------------------- */
/*     THIS SUBROUTINE SETS THE ERROR WEIGHT VECTOR */
/*     WT ACCORDING TO WT(I)=RTOL(I)*ABS(Y(I))+ATOL(I), */
/*     I=1,-,N. */
/*     RTOL AND ATOL ARE SCALARS IF IWT = 0, */
/*     AND VECTORS IF IWT = 1. */
/* ----------------------------------------------------------------------- */
/* ***ROUTINES CALLED  (NONE) */
/* ***REVISION HISTORY  (YYMMDD) */
/*   830315  DATE WRITTEN */
/*   901009  Finished conversion to SLATEC 4.0 format (F.N.Fritsch) */
/*   901019  Merged changes made by C. Ulrich with SLATEC 4.0 format. */
/*   901026  Added explicit declarations for all variables and minor */
/*           cosmetic changes to prologue.  (FNF) */
/* ***END PROLOGUE  DDAWTS */



/* ***FIRST EXECUTABLE STATEMENT  DDAWTS */
    /* Parameter adjustments */
    --ipar;
    --rpar;
    --wt;
    --y;
    --atol;
    --rtol;

    /* Function Body */
    rtoli = rtol[1];
    atoli = atol[1];
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (*iwt == 0) {
	    goto L10;
	}
	rtoli = rtol[i__];
	atoli = atol[i__];
L10:
	wt[i__] = rtoli * (d__1 = y[i__], abs(d__1)) + atoli;
/* L20: */
    }
    return 0;
/* -----------END OF SUBROUTINE DDAWTS------------------------------------ */
} /* ddawts_ */

doublereal ddanrm_(integer *neq, doublereal *v, doublereal *wt, doublereal *
	rpar, integer *ipar)
{
    /* System generated locals */
    integer i__1;
    doublereal ret_val, d__1, d__2;

    /* Builtin functions */
    double sqrt(doublereal);

    /* Local variables */
    static integer i__;
    static doublereal sum, vmax;

/* ***BEGIN PROLOGUE  DDANRM */
/* ***SUBSIDIARY */
/* ***PURPOSE  Compute vector norm for DDASSL. */
/* ***LIBRARY   SLATEC (DASSL) */
/* ***TYPE      DOUBLE PRECISION (SDANRM-S, DDANRM-D) */
/* ***AUTHOR  PETZOLD, LINDA R., (LLNL) */
/* ***DESCRIPTION */
/* ----------------------------------------------------------------------- */
/*     THIS FUNCTION ROUTINE COMPUTES THE WEIGHTED */
/*     ROOT-MEAN-SQUARE NORM OF THE VECTOR OF LENGTH */
/*     NEQ CONTAINED IN THE ARRAY V,WITH WEIGHTS */
/*     CONTAINED IN THE ARRAY WT OF LENGTH NEQ. */
/*        DDANRM=SQRT((1/NEQ)*SUM(V(I)/WT(I))**2) */
/* ----------------------------------------------------------------------- */
/* ***ROUTINES CALLED  (NONE) */
/* ***REVISION HISTORY  (YYMMDD) */
/*   830315  DATE WRITTEN */
/*   901009  Finished conversion to SLATEC 4.0 format (F.N.Fritsch) */
/*   901019  Merged changes made by C. Ulrich with SLATEC 4.0 format. */
/*   901026  Added explicit declarations for all variables and minor */
/*           cosmetic changes to prologue.  (FNF) */
/* ***END PROLOGUE  DDANRM */



/* ***FIRST EXECUTABLE STATEMENT  DDANRM */
    /* Parameter adjustments */
    --wt;
    --v;
    --rpar;
    --ipar;

    /* Function Body */
    ret_val = 0.;
    vmax = 0.;
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if ((d__1 = v[i__] / wt[i__], abs(d__1)) > vmax) {
	    vmax = (d__2 = v[i__] / wt[i__], abs(d__2));
	}
/* L10: */
    }
    if (vmax <= 0.) {
	goto L30;
    }
    sum = 0.;
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L20: */
/* Computing 2nd power */
	d__1 = v[i__] / wt[i__] / vmax;
	sum += d__1 * d__1;
    }
    ret_val = vmax * sqrt(sum / *neq);
L30:
    return ret_val;
/* ------END OF FUNCTION DDANRM------ */
} /* ddanrm_ */

/* Subroutine */ int ddaini_(doublereal *x, doublereal *y, doublereal *yprime,
	 integer *neq, S_fp res, U_fp jac, doublereal *h__, doublereal *wt,
	integer *idid, doublereal *rpar, integer *ipar, doublereal *phi,
	doublereal *delta, doublereal *e, doublereal *wm, integer *iwm,
	doublereal *hmin, doublereal *uround, integer *nonneg, integer *ntemp)
{
    /* Initialized data */

    static integer maxit = 10;
    static integer mjac = 5;
    static doublereal damp = .75;

    /* System generated locals */
    integer phi_dim1, phi_offset, i__1;
    doublereal d__1, d__2;

    /* Builtin functions */
    double pow_dd(doublereal *, doublereal *);

    /* Local variables */
    static integer i__, m;
    static doublereal r__, s, cj;
    static integer ncf, nef, ier, nsf;
    static doublereal err, rate;
    static integer ires;
    static doublereal xold;
    static integer jcalc;
    static doublereal ynorm;
    extern /* Subroutine */ int ddajac_(integer *, doublereal *, doublereal *,
	     doublereal *, doublereal *, doublereal *, doublereal *, integer *
	    , doublereal *, doublereal *, doublereal *, integer *, S_fp,
	    integer *, doublereal *, U_fp, doublereal *, integer *, integer *)
	    ;
    extern doublereal ddanrm_(integer *, doublereal *, doublereal *,
	    doublereal *, integer *);
    extern /* Subroutine */ int ddaslv_(integer *, doublereal *, doublereal *,
	     integer *);
    static logical convgd;
    static doublereal delnrm, oldnrm;

/* ***BEGIN PROLOGUE  DDAINI */
/* ***SUBSIDIARY */
/* ***PURPOSE  Initialization routine for DDASSL. */
/* ***LIBRARY   SLATEC (DASSL) */
/* ***TYPE      DOUBLE PRECISION (SDAINI-S, DDAINI-D) */
/* ***AUTHOR  PETZOLD, LINDA R., (LLNL) */
/* ***DESCRIPTION */
/* ----------------------------------------------------------------- */
/*     DDAINI TAKES ONE STEP OF SIZE H OR SMALLER */
/*     WITH THE BACKWARD EULER METHOD, TO */
/*     FIND YPRIME.  X AND Y ARE UPDATED TO BE CONSISTENT WITH THE */
/*     NEW STEP.  A MODIFIED DAMPED NEWTON ITERATION IS USED TO */
/*     SOLVE THE CORRECTOR ITERATION. */

/*     THE INITIAL GUESS FOR YPRIME IS USED IN THE */
/*     PREDICTION, AND IN FORMING THE ITERATION */
/*     MATRIX, BUT IS NOT INVOLVED IN THE */
/*     ERROR TEST. THIS MAY HAVE TROUBLE */
/*     CONVERGING IF THE INITIAL GUESS IS NO */
/*     GOOD, OR IF G(X,Y,YPRIME) DEPENDS */
/*     NONLINEARLY ON YPRIME. */

/*     THE PARAMETERS REPRESENT: */
/*     X --         INDEPENDENT VARIABLE */
/*     Y --         SOLUTION VECTOR AT X */
/*     YPRIME --    DERIVATIVE OF SOLUTION VECTOR */
/*     NEQ --       NUMBER OF EQUATIONS */
/*     H --         STEPSIZE. IMDER MAY USE A STEPSIZE */
/*                  SMALLER THAN H. */
/*     WT --        VECTOR OF WEIGHTS FOR ERROR */
/*                  CRITERION */
/*     IDID --      COMPLETION CODE WITH THE FOLLOWING MEANINGS */
/*                  IDID= 1 -- YPRIME WAS FOUND SUCCESSFULLY */
/*                  IDID=-12 -- DDAINI FAILED TO FIND YPRIME */
/*     RPAR,IPAR -- REAL AND INTEGER PARAMETER ARRAYS */
/*                  THAT ARE NOT ALTERED BY DDAINI */
/*     PHI --       WORK SPACE FOR DDAINI */
/*     DELTA,E --   WORK SPACE FOR DDAINI */
/*     WM,IWM --    REAL AND INTEGER ARRAYS STORING */
/*                  MATRIX INFORMATION */

/* ----------------------------------------------------------------- */
/* ***ROUTINES CALLED  DDAJAC, DDANRM, DDASLV */
/* ***REVISION HISTORY  (YYMMDD) */
/*   830315  DATE WRITTEN */
/*   901009  Finished conversion to SLATEC 4.0 format (F.N.Fritsch) */
/*   901019  Merged changes made by C. Ulrich with SLATEC 4.0 format. */
/*   901026  Added explicit declarations for all variables and minor */
/*           cosmetic changes to prologue.  (FNF) */
/*   901030  Minor corrections to declarations.  (FNF) */
/* ***END PROLOGUE  DDAINI */





    /* Parameter adjustments */
    --y;
    --yprime;
    phi_dim1 = *neq;
    phi_offset = 1 + phi_dim1;
    phi -= phi_offset;
    --wt;
    --rpar;
    --ipar;
    --delta;
    --e;
    --wm;
    --iwm;

    /* Function Body */


/* --------------------------------------------------- */
/*     BLOCK 1. */
/*     INITIALIZATIONS. */
/* --------------------------------------------------- */

/* ***FIRST EXECUTABLE STATEMENT  DDAINI */
    *idid = 1;
    nef = 0;
    ncf = 0;
    nsf = 0;
    xold = *x;
    ynorm = ddanrm_(neq, &y[1], &wt[1], &rpar[1], &ipar[1]);

/*     SAVE Y AND YPRIME IN PHI */
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	phi[i__ + phi_dim1] = y[i__];
/* L100: */
	phi[i__ + (phi_dim1 << 1)] = yprime[i__];
    }


/* ---------------------------------------------------- */
/*     BLOCK 2. */
/*     DO ONE BACKWARD EULER STEP. */
/* ---------------------------------------------------- */

/*     SET UP FOR START OF CORRECTOR ITERATION */
L200:
    cj = 1. / *h__;
    *x += *h__;

/*     PREDICT SOLUTION AND DERIVATIVE */
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L250: */
	y[i__] += *h__ * yprime[i__];
    }

    jcalc = -1;
    m = 0;
    convgd = TRUE_;


/*     CORRECTOR LOOP. */
L300:
    ++iwm[12];
    ires = 0;

    (*res)(x, &y[1], &yprime[1], &delta[1], &ires, &rpar[1], &ipar[1]);
    if (ires < 0) {
	goto L430;
    }


/*     EVALUATE THE ITERATION MATRIX */
    if (jcalc != -1) {
	goto L310;
    }
    ++iwm[13];
    jcalc = 0;
    ddajac_(neq, x, &y[1], &yprime[1], &delta[1], &cj, h__, &ier, &wt[1], &e[
	    1], &wm[1], &iwm[1], (S_fp)res, &ires, uround, (U_fp)jac, &rpar[1]
	    , &ipar[1], ntemp);

    s = 1e6;
    if (ires < 0) {
	goto L430;
    }
    if (ier != 0) {
	goto L430;
    }
    nsf = 0;



/*     MULTIPLY RESIDUAL BY DAMPING FACTOR */
L310:
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L320: */
	delta[i__] *= damp;
    }

/*     COMPUTE A NEW ITERATE (BACK SUBSTITUTION) */
/*     STORE THE CORRECTION IN DELTA */

    ddaslv_(neq, &delta[1], &wm[1], &iwm[1]);

/*     UPDATE Y AND YPRIME */
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	y[i__] -= delta[i__];
/* L330: */
	yprime[i__] -= cj * delta[i__];
    }

/*     TEST FOR CONVERGENCE OF THE ITERATION. */

    delnrm = ddanrm_(neq, &delta[1], &wt[1], &rpar[1], &ipar[1]);
    if (delnrm <= *uround * 100. * ynorm) {
	goto L400;
    }

    if (m > 0) {
	goto L340;
    }
    oldnrm = delnrm;
    goto L350;

L340:
    d__1 = delnrm / oldnrm;
    d__2 = 1. / m;
    rate = pow_dd(&d__1, &d__2);
    if (rate > .9) {
	goto L430;
    }
    s = rate / (1. - rate);

L350:
    if (s * delnrm <= .33) {
	goto L400;
    }


/*     THE CORRECTOR HAS NOT YET CONVERGED. UPDATE */
/*     M AND AND TEST WHETHER THE MAXIMUM */
/*     NUMBER OF ITERATIONS HAVE BEEN TRIED. */
/*     EVERY MJAC ITERATIONS, GET A NEW */
/*     ITERATION MATRIX. */

    ++m;
    if (m >= maxit) {
	goto L430;
    }

    if (m / mjac * mjac == m) {
	jcalc = -1;
    }
    goto L300;


/*     THE ITERATION HAS CONVERGED. */
/*     CHECK NONNEGATIVITY CONSTRAINTS */
L400:
    if (*nonneg == 0) {
	goto L450;
    }
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L410: */
/* Computing MIN */
	d__1 = y[i__];
	delta[i__] = min(d__1,0.);
    }

    delnrm = ddanrm_(neq, &delta[1], &wt[1], &rpar[1], &ipar[1]);
    if (delnrm > .33) {
	goto L430;
    }

    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	y[i__] -= delta[i__];
/* L420: */
	yprime[i__] -= cj * delta[i__];
    }
    goto L450;


/*     EXITS FROM CORRECTOR LOOP. */
L430:
    convgd = FALSE_;
L450:
    if (! convgd) {
	goto L600;
    }



/* ----------------------------------------------------- */
/*     BLOCK 3. */
/*     THE CORRECTOR ITERATION CONVERGED. */
/*     DO ERROR TEST. */
/* ----------------------------------------------------- */

    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L510: */
	e[i__] = y[i__] - phi[i__ + phi_dim1];
    }
    err = ddanrm_(neq, &e[1], &wt[1], &rpar[1], &ipar[1]);

    if (err <= 1.) {
	return 0;
    }



/* -------------------------------------------------------- */
/*     BLOCK 4. */
/*     THE BACKWARD EULER STEP FAILED. RESTORE X, Y */
/*     AND YPRIME TO THEIR ORIGINAL VALUES. */
/*     REDUCE STEPSIZE AND TRY AGAIN, IF */
/*     POSSIBLE. */
/* --------------------------------------------------------- */

L600:
    *x = xold;
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	y[i__] = phi[i__ + phi_dim1];
/* L610: */
	yprime[i__] = phi[i__ + (phi_dim1 << 1)];
    }

    if (convgd) {
	goto L640;
    }
    if (ier == 0) {
	goto L620;
    }
    ++nsf;
    *h__ *= .25;
    if (nsf < 3 && abs(*h__) >= *hmin) {
	goto L690;
    }
    *idid = -12;
    return 0;
L620:
    if (ires > -2) {
	goto L630;
    }
    *idid = -12;
    return 0;
L630:
    ++ncf;
    *h__ *= .25;
    if (ncf < 10 && abs(*h__) >= *hmin) {
	goto L690;
    }
    *idid = -12;
    return 0;

L640:
    ++nef;
    r__ = .9 / (err * 2. + 1e-4);
/* Computing MAX */
    d__1 = .1, d__2 = min(.5,r__);
    r__ = max(d__1,d__2);
    *h__ *= r__;
    if (abs(*h__) >= *hmin && nef < 10) {
	goto L690;
    }
    *idid = -12;
    return 0;
L690:
    goto L200;

/* -------------END OF SUBROUTINE DDAINI---------------------- */
} /* ddaini_ */

/* Subroutine */ int ddatrp_(doublereal *x, doublereal *xout, doublereal *
	yout, doublereal *ypout, integer *neq, integer *kold, doublereal *phi,
	 doublereal *psi)
{
    /* System generated locals */
    integer phi_dim1, phi_offset, i__1, i__2;

    /* Local variables */
    static doublereal c__, d__;
    static integer i__, j;
    static doublereal temp1, gamma;
    static integer koldp1;

/* ***BEGIN PROLOGUE  DDATRP */
/* ***SUBSIDIARY */
/* ***PURPOSE  Interpolation routine for DDASSL. */
/* ***LIBRARY   SLATEC (DASSL) */
/* ***TYPE      DOUBLE PRECISION (SDATRP-S, DDATRP-D) */
/* ***AUTHOR  PETZOLD, LINDA R., (LLNL) */
/* ***DESCRIPTION */
/* ----------------------------------------------------------------------- */
/*     THE METHODS IN SUBROUTINE DDASTP USE POLYNOMIALS */
/*     TO APPROXIMATE THE SOLUTION. DDATRP APPROXIMATES THE */
/*     SOLUTION AND ITS DERIVATIVE AT TIME XOUT BY EVALUATING */
/*     ONE OF THESE POLYNOMIALS,AND ITS DERIVATIVE,THERE. */
/*     INFORMATION DEFINING THIS POLYNOMIAL IS PASSED FROM */
/*     DDASTP, SO DDATRP CANNOT BE USED ALONE. */

/*     THE PARAMETERS ARE: */
/*     X     THE CURRENT TIME IN THE INTEGRATION. */
/*     XOUT  THE TIME AT WHICH THE SOLUTION IS DESIRED */
/*     YOUT  THE INTERPOLATED APPROXIMATION TO Y AT XOUT */
/*           (THIS IS OUTPUT) */
/*     YPOUT THE INTERPOLATED APPROXIMATION TO YPRIME AT XOUT */
/*           (THIS IS OUTPUT) */
/*     NEQ   NUMBER OF EQUATIONS */
/*     KOLD  ORDER USED ON LAST SUCCESSFUL STEP */
/*     PHI   ARRAY OF SCALED DIVIDED DIFFERENCES OF Y */
/*     PSI   ARRAY OF PAST STEPSIZE HISTORY */
/* ----------------------------------------------------------------------- */
/* ***ROUTINES CALLED  (NONE) */
/* ***REVISION HISTORY  (YYMMDD) */
/*   830315  DATE WRITTEN */
/*   901009  Finished conversion to SLATEC 4.0 format (F.N.Fritsch) */
/*   901019  Merged changes made by C. Ulrich with SLATEC 4.0 format. */
/*   901026  Added explicit declarations for all variables and minor */
/*           cosmetic changes to prologue.  (FNF) */
/* ***END PROLOGUE  DDATRP */



/* ***FIRST EXECUTABLE STATEMENT  DDATRP */
    /* Parameter adjustments */
    --yout;
    --ypout;
    phi_dim1 = *neq;
    phi_offset = 1 + phi_dim1;
    phi -= phi_offset;
    --psi;

    /* Function Body */
    koldp1 = *kold + 1;
    temp1 = *xout - *x;
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	yout[i__] = phi[i__ + phi_dim1];
/* L10: */
	ypout[i__] = 0.;
    }
    c__ = 1.;
    d__ = 0.;
    gamma = temp1 / psi[1];
    i__1 = koldp1;
    for (j = 2; j <= i__1; ++j) {
	d__ = d__ * gamma + c__ / psi[j - 1];
	c__ *= gamma;
	gamma = (temp1 + psi[j - 1]) / psi[j];
	i__2 = *neq;
	for (i__ = 1; i__ <= i__2; ++i__) {
	    yout[i__] += c__ * phi[i__ + j * phi_dim1];
/* L20: */
	    ypout[i__] += d__ * phi[i__ + j * phi_dim1];
	}
/* L30: */
    }
    return 0;

/* ------END OF SUBROUTINE DDATRP------ */
} /* ddatrp_ */

/* Subroutine */ int ddastp_(doublereal *x, doublereal *y, doublereal *yprime,
	 integer *neq, S_fp res, U_fp jac, doublereal *h__, doublereal *wt,
	integer *jstart, integer *idid, doublereal *rpar, integer *ipar,
	doublereal *phi, doublereal *delta, doublereal *e, doublereal *wm,
	integer *iwm, doublereal *alpha, doublereal *beta, doublereal *gamma,
	doublereal *psi, doublereal *sigma, doublereal *cj, doublereal *cjold,
	 doublereal *hold, doublereal *s, doublereal *hmin, doublereal *
	uround, integer *iphase, integer *jcalc, integer *k, integer *kold,
	integer *ns, integer *nonneg, integer *ntemp)
{
    /* Initialized data */

    static integer maxit = 4;
    static doublereal xrate = .25;

    /* System generated locals */
    integer phi_dim1, phi_offset, i__1, i__2;
    doublereal d__1, d__2;

    /* Builtin functions */
    double pow_dd(doublereal *, doublereal *);

    /* Local variables */
    static integer i__, j, m;
    static doublereal r__;
    static integer j1;
    static doublereal ck;
    static integer km1, kp1, kp2, ncf, nef, ier;
    static doublereal erk;
    static integer nsf;
    static doublereal err, est;
    static integer nsp1;
    static doublereal rate, hnew;
    static integer ires, knew;
    static doublereal terk, xold, erkm1, erkm2, erkp1, temp1, temp2;
    static integer kdiff;
    static doublereal enorm, pnorm, alpha0, terkm1, terkm2;
    extern /* Subroutine */ int ddajac_(integer *, doublereal *, doublereal *,
	     doublereal *, doublereal *, doublereal *, doublereal *, integer *
	    , doublereal *, doublereal *, doublereal *, integer *, S_fp,
	    integer *, doublereal *, U_fp, doublereal *, integer *, integer *)
	    ;
    static doublereal terkp1;
    extern doublereal ddanrm_(integer *, doublereal *, doublereal *,
	    doublereal *, integer *);
    static doublereal alphas;
    extern /* Subroutine */ int ddaslv_(integer *, doublereal *, doublereal *,
	     integer *), ddatrp_(doublereal *, doublereal *, doublereal *,
	    doublereal *, integer *, integer *, doublereal *, doublereal *);
    static doublereal cjlast, delnrm;
    static logical convgd;
    static doublereal oldnrm;

/* ***BEGIN PROLOGUE  DDASTP */
/* ***SUBSIDIARY */
/* ***PURPOSE  Perform one step of the DDASSL integration. */
/* ***LIBRARY   SLATEC (DASSL) */
/* ***TYPE      DOUBLE PRECISION (SDASTP-S, DDASTP-D) */
/* ***AUTHOR  PETZOLD, LINDA R., (LLNL) */
/* ***DESCRIPTION */
/* ----------------------------------------------------------------------- */
/*     DDASTP SOLVES A SYSTEM OF DIFFERENTIAL/ */
/*     ALGEBRAIC EQUATIONS OF THE FORM */
/*     G(X,Y,YPRIME) = 0,  FOR ONE STEP (NORMALLY */
/*     FROM X TO X+H). */

/*     THE METHODS USED ARE MODIFIED DIVIDED */
/*     DIFFERENCE,FIXED LEADING COEFFICIENT */
/*     FORMS OF BACKWARD DIFFERENTIATION */
/*     FORMULAS. THE CODE ADJUSTS THE STEPSIZE */
/*     AND ORDER TO CONTROL THE LOCAL ERROR PER */
/*     STEP. */


/*     THE PARAMETERS REPRESENT */
/*     X  --        INDEPENDENT VARIABLE */
/*     Y  --        SOLUTION VECTOR AT X */
/*     YPRIME --    DERIVATIVE OF SOLUTION VECTOR */
/*                  AFTER SUCCESSFUL STEP */
/*     NEQ --       NUMBER OF EQUATIONS TO BE INTEGRATED */
/*     RES --       EXTERNAL USER-SUPPLIED SUBROUTINE */
/*                  TO EVALUATE THE RESIDUAL.  THE CALL IS */
/*                  CALL RES(X,Y,YPRIME,DELTA,IRES,RPAR,IPAR) */
/*                  X,Y,YPRIME ARE INPUT.  DELTA IS OUTPUT. */
/*                  ON INPUT, IRES=0.  RES SHOULD ALTER IRES ONLY */
/*                  IF IT ENCOUNTERS AN ILLEGAL VALUE OF Y OR A */
/*                  STOP CONDITION.  SET IRES=-1 IF AN INPUT VALUE */
/*                  OF Y IS ILLEGAL, AND DDASTP WILL TRY TO SOLVE */
/*                  THE PROBLEM WITHOUT GETTING IRES = -1.  IF */
/*                  IRES=-2, DDASTP RETURNS CONTROL TO THE CALLING */
/*                  PROGRAM WITH IDID = -11. */
/*     JAC --       EXTERNAL USER-SUPPLIED ROUTINE TO EVALUATE */
/*                  THE ITERATION MATRIX (THIS IS OPTIONAL) */
/*                  THE CALL IS OF THE FORM */
/*                  CALL JAC(X,Y,YPRIME,PD,CJ,RPAR,IPAR) */
/*                  PD IS THE MATRIX OF PARTIAL DERIVATIVES, */
/*                  PD=DG/DY+CJ*DG/DYPRIME */
/*     H --         APPROPRIATE STEP SIZE FOR NEXT STEP. */
/*                  NORMALLY DETERMINED BY THE CODE */
/*     WT --        VECTOR OF WEIGHTS FOR ERROR CRITERION. */
/*     JSTART --    INTEGER VARIABLE SET 0 FOR */
/*                  FIRST STEP, 1 OTHERWISE. */
/*     IDID --      COMPLETION CODE WITH THE FOLLOWING MEANINGS: */
/*                  IDID= 1 -- THE STEP WAS COMPLETED SUCCESSFULLY */
/*                  IDID=-6 -- THE ERROR TEST FAILED REPEATEDLY */
/*                  IDID=-7 -- THE CORRECTOR COULD NOT CONVERGE */
/*                  IDID=-8 -- THE ITERATION MATRIX IS SINGULAR */
/*                  IDID=-9 -- THE CORRECTOR COULD NOT CONVERGE. */
/*                             THERE WERE REPEATED ERROR TEST */
/*                             FAILURES ON THIS STEP. */
/*                  IDID=-10-- THE CORRECTOR COULD NOT CONVERGE */
/*                             BECAUSE IRES WAS EQUAL TO MINUS ONE */
/*                  IDID=-11-- IRES EQUAL TO -2 WAS ENCOUNTERED, */
/*                             AND CONTROL IS BEING RETURNED TO */
/*                             THE CALLING PROGRAM */
/*     RPAR,IPAR -- REAL AND INTEGER PARAMETER ARRAYS THAT */
/*                  ARE USED FOR COMMUNICATION BETWEEN THE */
/*                  CALLING PROGRAM AND EXTERNAL USER ROUTINES */
/*                  THEY ARE NOT ALTERED BY DDASTP */
/*     PHI --       ARRAY OF DIVIDED DIFFERENCES USED BY */
/*                  DDASTP. THE LENGTH IS NEQ*(K+1),WHERE */
/*                  K IS THE MAXIMUM ORDER */
/*     DELTA,E --   WORK VECTORS FOR DDASTP OF LENGTH NEQ */
/*     WM,IWM --    REAL AND INTEGER ARRAYS STORING */
/*                  MATRIX INFORMATION SUCH AS THE MATRIX */
/*                  OF PARTIAL DERIVATIVES,PERMUTATION */
/*                  VECTOR,AND VARIOUS OTHER INFORMATION. */

/*     THE OTHER PARAMETERS ARE INFORMATION */
/*     WHICH IS NEEDED INTERNALLY BY DDASTP TO */
/*     CONTINUE FROM STEP TO STEP. */

/* ----------------------------------------------------------------------- */
/* ***ROUTINES CALLED  DDAJAC, DDANRM, DDASLV, DDATRP */
/* ***REVISION HISTORY  (YYMMDD) */
/*   830315  DATE WRITTEN */
/*   901009  Finished conversion to SLATEC 4.0 format (F.N.Fritsch) */
/*   901019  Merged changes made by C. Ulrich with SLATEC 4.0 format. */
/*   901026  Added explicit declarations for all variables and minor */
/*           cosmetic changes to prologue.  (FNF) */
/* ***END PROLOGUE  DDASTP */





    /* Parameter adjustments */
    --y;
    --yprime;
    phi_dim1 = *neq;
    phi_offset = 1 + phi_dim1;
    phi -= phi_offset;
    --wt;
    --rpar;
    --ipar;
    --delta;
    --e;
    --wm;
    --iwm;
    --alpha;
    --beta;
    --gamma;
    --psi;
    --sigma;

    /* Function Body */





/* ----------------------------------------------------------------------- */
/*     BLOCK 1. */
/*     INITIALIZE. ON THE FIRST CALL,SET */
/*     THE ORDER TO 1 AND INITIALIZE */
/*     OTHER VARIABLES. */
/* ----------------------------------------------------------------------- */

/*     INITIALIZATIONS FOR ALL CALLS */
/* ***FIRST EXECUTABLE STATEMENT  DDASTP */
    *idid = 1;
    xold = *x;
    ncf = 0;
    nsf = 0;
    nef = 0;
    if (*jstart != 0) {
	goto L120;
    }

/*     IF THIS IS THE FIRST STEP,PERFORM */
/*     OTHER INITIALIZATIONS */
    iwm[14] = 0;
    iwm[15] = 0;
    *k = 1;
    *kold = 0;
    *hold = 0.;
    *jstart = 1;
    psi[1] = *h__;
    *cjold = 1. / *h__;
    *cj = *cjold;
    *s = 100.;
    *jcalc = -1;
    delnrm = 1.;
    *iphase = 0;
    *ns = 0;
L120:





/* ----------------------------------------------------------------------- */
/*     BLOCK 2 */
/*     COMPUTE COEFFICIENTS OF FORMULAS FOR */
/*     THIS STEP. */
/* ----------------------------------------------------------------------- */
L200:
    kp1 = *k + 1;
    kp2 = *k + 2;
    km1 = *k - 1;
    xold = *x;
    if (*h__ != *hold || *k != *kold) {
	*ns = 0;
    }
/* Computing MIN */
    i__1 = *ns + 1, i__2 = *kold + 2;
    *ns = min(i__1,i__2);
    nsp1 = *ns + 1;
    if (kp1 < *ns) {
	goto L230;
    }

    beta[1] = 1.;
    alpha[1] = 1.;
    temp1 = *h__;
    gamma[1] = 0.;
    sigma[1] = 1.;
    i__1 = kp1;
    for (i__ = 2; i__ <= i__1; ++i__) {
	temp2 = psi[i__ - 1];
	psi[i__ - 1] = temp1;
	beta[i__] = beta[i__ - 1] * psi[i__ - 1] / temp2;
	temp1 = temp2 + *h__;
	alpha[i__] = *h__ / temp1;
	sigma[i__] = (i__ - 1) * sigma[i__ - 1] * alpha[i__];
	gamma[i__] = gamma[i__ - 1] + alpha[i__ - 1] / *h__;
/* L210: */
    }
    psi[kp1] = temp1;
L230:

/*     COMPUTE ALPHAS, ALPHA0 */
    alphas = 0.;
    alpha0 = 0.;
    i__1 = *k;
    for (i__ = 1; i__ <= i__1; ++i__) {
	alphas -= 1. / i__;
	alpha0 -= alpha[i__];
/* L240: */
    }

/*     COMPUTE LEADING COEFFICIENT CJ */
    cjlast = *cj;
    *cj = -alphas / *h__;

/*     COMPUTE VARIABLE STEPSIZE ERROR COEFFICIENT CK */
    ck = (d__1 = alpha[kp1] + alphas - alpha0, abs(d__1));
/* Computing MAX */
    d__1 = ck, d__2 = alpha[kp1];
    ck = max(d__1,d__2);

/*     DECIDE WHETHER NEW JACOBIAN IS NEEDED */
    temp1 = (1. - xrate) / (xrate + 1.);
    temp2 = 1. / temp1;
    if (*cj / *cjold < temp1 || *cj / *cjold > temp2) {
	*jcalc = -1;
    }
    if (*cj != cjlast) {
	*s = 100.;
    }

/*     CHANGE PHI TO PHI STAR */
    if (kp1 < nsp1) {
	goto L280;
    }
    i__1 = kp1;
    for (j = nsp1; j <= i__1; ++j) {
	i__2 = *neq;
	for (i__ = 1; i__ <= i__2; ++i__) {
/* L260: */
	    phi[i__ + j * phi_dim1] = beta[j] * phi[i__ + j * phi_dim1];
	}
/* L270: */
    }
L280:

/*     UPDATE TIME */
    *x += *h__;





/* ----------------------------------------------------------------------- */
/*     BLOCK 3 */
/*     PREDICT THE SOLUTION AND DERIVATIVE, */
/*     AND SOLVE THE CORRECTOR EQUATION */
/* ----------------------------------------------------------------------- */

/*     FIRST,PREDICT THE SOLUTION AND DERIVATIVE */
L300:
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	y[i__] = phi[i__ + phi_dim1];
/* L310: */
	yprime[i__] = 0.;
    }
    i__1 = kp1;
    for (j = 2; j <= i__1; ++j) {
	i__2 = *neq;
	for (i__ = 1; i__ <= i__2; ++i__) {
	    y[i__] += phi[i__ + j * phi_dim1];
/* L320: */
	    yprime[i__] += gamma[j] * phi[i__ + j * phi_dim1];
	}
/* L330: */
    }
    pnorm = ddanrm_(neq, &y[1], &wt[1], &rpar[1], &ipar[1]);



/*     SOLVE THE CORRECTOR EQUATION USING A */
/*     MODIFIED NEWTON SCHEME. */
    convgd = TRUE_;
    m = 0;
    ++iwm[12];
    ires = 0;
    (*res)(x, &y[1], &yprime[1], &delta[1], &ires, &rpar[1], &ipar[1]);
    if (ires < 0) {
	goto L380;
    }


/*     IF INDICATED,REEVALUATE THE */
/*     ITERATION MATRIX PD = DG/DY + CJ*DG/DYPRIME */
/*     (WHERE G(X,Y,YPRIME)=0). SET */
/*     JCALC TO 0 AS AN INDICATOR THAT */
/*     THIS HAS BEEN DONE. */
    if (*jcalc != -1) {
	goto L340;
    }
    ++iwm[13];
    *jcalc = 0;
    ddajac_(neq, x, &y[1], &yprime[1], &delta[1], cj, h__, &ier, &wt[1], &e[1]
	    , &wm[1], &iwm[1], (S_fp)res, &ires, uround, (U_fp)jac, &rpar[1],
	    &ipar[1], ntemp);
    *cjold = *cj;
    *s = 100.;
    if (ires < 0) {
	goto L380;
    }
    if (ier != 0) {
	goto L380;
    }
    nsf = 0;


/*     INITIALIZE THE ERROR ACCUMULATION VECTOR E. */
L340:
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L345: */
	e[i__] = 0.;
    }


/*     CORRECTOR LOOP. */
L350:

/*     MULTIPLY RESIDUAL BY TEMP1 TO ACCELERATE CONVERGENCE */
    temp1 = 2. / (*cj / *cjold + 1.);
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L355: */
	delta[i__] *= temp1;
    }

/*     COMPUTE A NEW ITERATE (BACK-SUBSTITUTION). */
/*     STORE THE CORRECTION IN DELTA. */
    ddaslv_(neq, &delta[1], &wm[1], &iwm[1]);

/*     UPDATE Y,E,AND YPRIME */
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	y[i__] -= delta[i__];
	e[i__] -= delta[i__];
/* L360: */
	yprime[i__] -= *cj * delta[i__];
    }

/*     TEST FOR CONVERGENCE OF THE ITERATION */
    delnrm = ddanrm_(neq, &delta[1], &wt[1], &rpar[1], &ipar[1]);
    if (delnrm <= *uround * 100. * pnorm) {
	goto L375;
    }
    if (m > 0) {
	goto L365;
    }
    oldnrm = delnrm;
    goto L367;
L365:
    d__1 = delnrm / oldnrm;
    d__2 = 1. / m;
    rate = pow_dd(&d__1, &d__2);
    if (rate > .9) {
	goto L370;
    }
    *s = rate / (1. - rate);
L367:
    if (*s * delnrm <= .33) {
	goto L375;
    }

/*     THE CORRECTOR HAS NOT YET CONVERGED. */
/*     UPDATE M AND TEST WHETHER THE */
/*     MAXIMUM NUMBER OF ITERATIONS HAVE */
/*     BEEN TRIED. */
    ++m;
    if (m >= maxit) {
	goto L370;
    }

/*     EVALUATE THE RESIDUAL */
/*     AND GO BACK TO DO ANOTHER ITERATION */
    ++iwm[12];
    ires = 0;
    (*res)(x, &y[1], &yprime[1], &delta[1], &ires, &rpar[1], &ipar[1]);
    if (ires < 0) {
	goto L380;
    }
    goto L350;


/*     THE CORRECTOR FAILED TO CONVERGE IN MAXIT */
/*     ITERATIONS. IF THE ITERATION MATRIX */
/*     IS NOT CURRENT,RE-DO THE STEP WITH */
/*     A NEW ITERATION MATRIX. */
L370:
    if (*jcalc == 0) {
	goto L380;
    }
    *jcalc = -1;
    goto L300;


/*     THE ITERATION HAS CONVERGED.  IF NONNEGATIVITY OF SOLUTION IS */
/*     REQUIRED, SET THE SOLUTION NONNEGATIVE, IF THE PERTURBATION */
/*     TO DO IT IS SMALL ENOUGH.  IF THE CHANGE IS TOO LARGE, THEN */
/*     CONSIDER THE CORRECTOR ITERATION TO HAVE FAILED. */
L375:
    if (*nonneg == 0) {
	goto L390;
    }
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L377: */
/* Computing MIN */
	d__1 = y[i__];
	delta[i__] = min(d__1,0.);
    }
    delnrm = ddanrm_(neq, &delta[1], &wt[1], &rpar[1], &ipar[1]);
    if (delnrm > .33) {
	goto L380;
    }
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L378: */
	e[i__] -= delta[i__];
    }
    goto L390;


/*     EXITS FROM BLOCK 3 */
/*     NO CONVERGENCE WITH CURRENT ITERATION */
/*     MATRIX,OR SINGULAR ITERATION MATRIX */
L380:
    convgd = FALSE_;
L390:
    *jcalc = 1;
    if (! convgd) {
	goto L600;
    }





/* ----------------------------------------------------------------------- */
/*     BLOCK 4 */
/*     ESTIMATE THE ERRORS AT ORDERS K,K-1,K-2 */
/*     AS IF CONSTANT STEPSIZE WAS USED. ESTIMATE */
/*     THE LOCAL ERROR AT ORDER K AND TEST */
/*     WHETHER THE CURRENT STEP IS SUCCESSFUL. */
/* ----------------------------------------------------------------------- */

/*     ESTIMATE ERRORS AT ORDERS K,K-1,K-2 */
    enorm = ddanrm_(neq, &e[1], &wt[1], &rpar[1], &ipar[1]);
    erk = sigma[*k + 1] * enorm;
    terk = (*k + 1) * erk;
    est = erk;
    knew = *k;
    if (*k == 1) {
	goto L430;
    }
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L405: */
	delta[i__] = phi[i__ + kp1 * phi_dim1] + e[i__];
    }
    erkm1 = sigma[*k] * ddanrm_(neq, &delta[1], &wt[1], &rpar[1], &ipar[1]);
    terkm1 = *k * erkm1;
    if (*k > 2) {
	goto L410;
    }
    if (terkm1 <= terk * .5) {
	goto L420;
    }
    goto L430;
L410:
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L415: */
	delta[i__] = phi[i__ + *k * phi_dim1] + delta[i__];
    }
    erkm2 = sigma[*k - 1] * ddanrm_(neq, &delta[1], &wt[1], &rpar[1], &ipar[1]
	    );
    terkm2 = (*k - 1) * erkm2;
    if (max(terkm1,terkm2) > terk) {
	goto L430;
    }
/*     LOWER THE ORDER */
L420:
    knew = *k - 1;
    est = erkm1;


/*     CALCULATE THE LOCAL ERROR FOR THE CURRENT STEP */
/*     TO SEE IF THE STEP WAS SUCCESSFUL */
L430:
    err = ck * enorm;
    if (err > 1.) {
	goto L600;
    }





/* ----------------------------------------------------------------------- */
/*     BLOCK 5 */
/*     THE STEP IS SUCCESSFUL. DETERMINE */
/*     THE BEST ORDER AND STEPSIZE FOR */
/*     THE NEXT STEP. UPDATE THE DIFFERENCES */
/*     FOR THE NEXT STEP. */
/* ----------------------------------------------------------------------- */
    *idid = 1;
    ++iwm[11];
    kdiff = *k - *kold;
    *kold = *k;
    *hold = *h__;


/*     ESTIMATE THE ERROR AT ORDER K+1 UNLESS: */
/*        ALREADY DECIDED TO LOWER ORDER, OR */
/*        ALREADY USING MAXIMUM ORDER, OR */
/*        STEPSIZE NOT CONSTANT, OR */
/*        ORDER RAISED IN PREVIOUS STEP */
    if (knew == km1 || *k == iwm[3]) {
	*iphase = 1;
    }
    if (*iphase == 0) {
	goto L545;
    }
    if (knew == km1) {
	goto L540;
    }
    if (*k == iwm[3]) {
	goto L550;
    }
    if (kp1 >= *ns || kdiff == 1) {
	goto L550;
    }
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L510: */
	delta[i__] = e[i__] - phi[i__ + kp2 * phi_dim1];
    }
    erkp1 = 1. / (*k + 2) * ddanrm_(neq, &delta[1], &wt[1], &rpar[1], &ipar[1]
	    );
    terkp1 = (*k + 2) * erkp1;
    if (*k > 1) {
	goto L520;
    }
    if (terkp1 >= terk * .5) {
	goto L550;
    }
    goto L530;
L520:
    if (terkm1 <= min(terk,terkp1)) {
	goto L540;
    }
    if (terkp1 >= terk || *k == iwm[3]) {
	goto L550;
    }

/*     RAISE ORDER */
L530:
    *k = kp1;
    est = erkp1;
    goto L550;

/*     LOWER ORDER */
L540:
    *k = km1;
    est = erkm1;
    goto L550;

/*     IF IPHASE = 0, INCREASE ORDER BY ONE AND MULTIPLY STEPSIZE BY */
/*     FACTOR TWO */
L545:
    *k = kp1;
    hnew = *h__ * 2.;
    *h__ = hnew;
    goto L575;


/*     DETERMINE THE APPROPRIATE STEPSIZE FOR */
/*     THE NEXT STEP. */
L550:
    hnew = *h__;
    temp2 = (doublereal) (*k + 1);
    d__1 = est * 2. + 1e-4;
    d__2 = -1. / temp2;
    r__ = pow_dd(&d__1, &d__2);
    if (r__ < 2.) {
	goto L555;
    }
    hnew = *h__ * 2.;
    goto L560;
L555:
    if (r__ > 1.) {
	goto L560;
    }
/* Computing MAX */
    d__1 = .5, d__2 = min(.9,r__);
    r__ = max(d__1,d__2);
    hnew = *h__ * r__;
L560:
    *h__ = hnew;


/*     UPDATE DIFFERENCES FOR NEXT STEP */
L575:
    if (*kold == iwm[3]) {
	goto L585;
    }
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L580: */
	phi[i__ + kp2 * phi_dim1] = e[i__];
    }
L585:
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L590: */
	phi[i__ + kp1 * phi_dim1] += e[i__];
    }
    i__1 = kp1;
    for (j1 = 2; j1 <= i__1; ++j1) {
	j = kp1 - j1 + 1;
	i__2 = *neq;
	for (i__ = 1; i__ <= i__2; ++i__) {
/* L595: */
	    phi[i__ + j * phi_dim1] += phi[i__ + (j + 1) * phi_dim1];
	}
    }
    return 0;





/* ----------------------------------------------------------------------- */
/*     BLOCK 6 */
/*     THE STEP IS UNSUCCESSFUL. RESTORE X,PSI,PHI */
/*     DETERMINE APPROPRIATE STEPSIZE FOR */
/*     CONTINUING THE INTEGRATION, OR EXIT WITH */
/*     AN ERROR FLAG IF THERE HAVE BEEN MANY */
/*     FAILURES. */
/* ----------------------------------------------------------------------- */
L600:
    *iphase = 1;

/*     RESTORE X,PHI,PSI */
    *x = xold;
    if (kp1 < nsp1) {
	goto L630;
    }
    i__2 = kp1;
    for (j = nsp1; j <= i__2; ++j) {
	temp1 = 1. / beta[j];
	i__1 = *neq;
	for (i__ = 1; i__ <= i__1; ++i__) {
/* L610: */
	    phi[i__ + j * phi_dim1] = temp1 * phi[i__ + j * phi_dim1];
	}
/* L620: */
    }
L630:
    i__2 = kp1;
    for (i__ = 2; i__ <= i__2; ++i__) {
/* L640: */
	psi[i__ - 1] = psi[i__] - *h__;
    }


/*     TEST WHETHER FAILURE IS DUE TO CORRECTOR ITERATION */
/*     OR ERROR TEST */
    if (convgd) {
	goto L660;
    }
    ++iwm[15];


/*     THE NEWTON ITERATION FAILED TO CONVERGE WITH */
/*     A CURRENT ITERATION MATRIX.  DETERMINE THE CAUSE */
/*     OF THE FAILURE AND TAKE APPROPRIATE ACTION. */
    if (ier == 0) {
	goto L650;
    }

/*     THE ITERATION MATRIX IS SINGULAR. REDUCE */
/*     THE STEPSIZE BY A FACTOR OF 4. IF */
/*     THIS HAPPENS THREE TIMES IN A ROW ON */
/*     THE SAME STEP, RETURN WITH AN ERROR FLAG */
    ++nsf;
    r__ = .25;
    *h__ *= r__;
    if (nsf < 3 && abs(*h__) >= *hmin) {
	goto L690;
    }
    *idid = -8;
    goto L675;


/*     THE NEWTON ITERATION FAILED TO CONVERGE FOR A REASON */
/*     OTHER THAN A SINGULAR ITERATION MATRIX.  IF IRES = -2, THEN */
/*     RETURN.  OTHERWISE, REDUCE THE STEPSIZE AND TRY AGAIN, UNLESS */
/*     TOO MANY FAILURES HAVE OCCURED. */
L650:
    if (ires > -2) {
	goto L655;
    }
    *idid = -11;
    goto L675;
L655:
    ++ncf;
    r__ = .25;
    *h__ *= r__;
    if (ncf < 10 && abs(*h__) >= *hmin) {
	goto L690;
    }
    *idid = -7;
    if (ires < 0) {
	*idid = -10;
    }
    if (nef >= 3) {
	*idid = -9;
    }
    goto L675;


/*     THE NEWTON SCHEME CONVERGED,AND THE CAUSE */
/*     OF THE FAILURE WAS THE ERROR ESTIMATE */
/*     EXCEEDING THE TOLERANCE. */
L660:
    ++nef;
    ++iwm[14];
    if (nef > 1) {
	goto L665;
    }

/*     ON FIRST ERROR TEST FAILURE, KEEP CURRENT ORDER OR LOWER */
/*     ORDER BY ONE.  COMPUTE NEW STEPSIZE BASED ON DIFFERENCES */
/*     OF THE SOLUTION. */
    *k = knew;
    temp2 = (doublereal) (*k + 1);
    d__1 = est * 2. + 1e-4;
    d__2 = -1. / temp2;
    r__ = pow_dd(&d__1, &d__2) * .9;
/* Computing MAX */
    d__1 = .25, d__2 = min(.9,r__);
    r__ = max(d__1,d__2);
    *h__ *= r__;
    if (abs(*h__) >= *hmin) {
	goto L690;
    }
    *idid = -6;
    goto L675;

/*     ON SECOND ERROR TEST FAILURE, USE THE CURRENT ORDER OR */
/*     DECREASE ORDER BY ONE.  REDUCE THE STEPSIZE BY A FACTOR OF */
/*     FOUR. */
L665:
    if (nef > 2) {
	goto L670;
    }
    *k = knew;
    *h__ *= .25;
    if (abs(*h__) >= *hmin) {
	goto L690;
    }
    *idid = -6;
    goto L675;

/*     ON THIRD AND SUBSEQUENT ERROR TEST FAILURES, SET THE ORDER TO */
/*     ONE AND REDUCE THE STEPSIZE BY A FACTOR OF FOUR. */
L670:
    *k = 1;
    *h__ *= .25;
    if (abs(*h__) >= *hmin) {
	goto L690;
    }
    *idid = -6;
    goto L675;




/*     FOR ALL CRASHES, RESTORE Y TO ITS LAST VALUE, */
/*     INTERPOLATE TO FIND YPRIME AT LAST X, AND RETURN */
L675:
    ddatrp_(x, x, &y[1], &yprime[1], neq, k, &phi[phi_offset], &psi[1]);
    return 0;


/*     GO BACK AND TRY THIS STEP AGAIN */
L690:
    goto L200;

/* ------END OF SUBROUTINE DDASTP------ */
} /* ddastp_ */

/* Subroutine */ int ddajac_(integer *neq, doublereal *x, doublereal *y,
	doublereal *yprime, doublereal *delta, doublereal *cj, doublereal *
	h__, integer *ier, doublereal *wt, doublereal *e, doublereal *wm,
	integer *iwm, S_fp res, integer *ires, doublereal *uround, S_fp jac,
	doublereal *rpar, integer *ipar, integer *ntemp)
{
    /* System generated locals */
    integer i__1, i__2, i__3, i__4, i__5;
    doublereal d__1, d__2, d__3, d__4, d__5;

    /* Builtin functions */
    double sqrt(doublereal), d_sign(doublereal *, doublereal *);

    /* Local variables */
    static integer i__, j, k, l, n, i1, i2, ii, mba;
    static doublereal del;
    static integer meb1, nrow;
    static doublereal squr;
    static integer npdm1;
    extern /* Subroutine */ int dgbfa_(doublereal *, integer *, integer *,
	    integer *, integer *, integer *, integer *), dgefa_(doublereal *,
	    integer *, integer *, integer *, integer *);
    static integer mband, lenpd, isave, msave;
    static doublereal ysave;
    static integer mtype, meband;
    static doublereal delinv;
    static integer ipsave;
    static doublereal ypsave;

/* ***BEGIN PROLOGUE  DDAJAC */
/* ***SUBSIDIARY */
/* ***PURPOSE  Compute the iteration matrix for DDASSL and form the */
/*            LU-decomposition. */
/* ***LIBRARY   SLATEC (DASSL) */
/* ***TYPE      DOUBLE PRECISION (SDAJAC-S, DDAJAC-D) */
/* ***AUTHOR  PETZOLD, LINDA R., (LLNL) */
/* ***DESCRIPTION */
/* ----------------------------------------------------------------------- */
/*     THIS ROUTINE COMPUTES THE ITERATION MATRIX */
/*     PD=DG/DY+CJ*DG/DYPRIME (WHERE G(X,Y,YPRIME)=0). */
/*     HERE PD IS COMPUTED BY THE USER-SUPPLIED */
/*     ROUTINE JAC IF IWM(MTYPE) IS 1 OR 4, AND */
/*     IT IS COMPUTED BY NUMERICAL FINITE DIFFERENCING */
/*     IF IWM(MTYPE)IS 2 OR 5 */
/*     THE PARAMETERS HAVE THE FOLLOWING MEANINGS. */
/*     Y        = ARRAY CONTAINING PREDICTED VALUES */
/*     YPRIME   = ARRAY CONTAINING PREDICTED DERIVATIVES */
/*     DELTA    = RESIDUAL EVALUATED AT (X,Y,YPRIME) */
/*                (USED ONLY IF IWM(MTYPE)=2 OR 5) */
/*     CJ       = SCALAR PARAMETER DEFINING ITERATION MATRIX */
/*     H        = CURRENT STEPSIZE IN INTEGRATION */
/*     IER      = VARIABLE WHICH IS .NE. 0 */
/*                IF ITERATION MATRIX IS SINGULAR, */
/*                AND 0 OTHERWISE. */
/*     WT       = VECTOR OF WEIGHTS FOR COMPUTING NORMS */
/*     E        = WORK SPACE (TEMPORARY) OF LENGTH NEQ */
/*     WM       = REAL WORK SPACE FOR MATRICES. ON */
/*                OUTPUT IT CONTAINS THE LU DECOMPOSITION */
/*                OF THE ITERATION MATRIX. */
/*     IWM      = INTEGER WORK SPACE CONTAINING */
/*                MATRIX INFORMATION */
/*     RES      = NAME OF THE EXTERNAL USER-SUPPLIED ROUTINE */
/*                TO EVALUATE THE RESIDUAL FUNCTION G(X,Y,YPRIME) */
/*     IRES     = FLAG WHICH IS EQUAL TO ZERO IF NO ILLEGAL VALUES */
/*                IN RES, AND LESS THAN ZERO OTHERWISE.  (IF IRES */
/*                IS LESS THAN ZERO, THE MATRIX WAS NOT COMPLETED) */
/*                IN THIS CASE (IF IRES .LT. 0), THEN IER = 0. */
/*     UROUND   = THE UNIT ROUNDOFF ERROR OF THE MACHINE BEING USED. */
/*     JAC      = NAME OF THE EXTERNAL USER-SUPPLIED ROUTINE */
/*                TO EVALUATE THE ITERATION MATRIX (THIS ROUTINE */
/*                IS ONLY USED IF IWM(MTYPE) IS 1 OR 4) */
/* ----------------------------------------------------------------------- */
/* ***ROUTINES CALLED  DGBFA, DGEFA */
/* ***REVISION HISTORY  (YYMMDD) */
/*   830315  DATE WRITTEN */
/*   901009  Finished conversion to SLATEC 4.0 format (F.N.Fritsch) */
/*   901010  Modified three MAX calls to be all on one line.  (FNF) */
/*   901019  Merged changes made by C. Ulrich with SLATEC 4.0 format. */
/*   901026  Added explicit declarations for all variables and minor */
/*           cosmetic changes to prologue.  (FNF) */
/*   901101  Corrected PURPOSE.  (FNF) */
/* ***END PROLOGUE  DDAJAC */





/* ***FIRST EXECUTABLE STATEMENT  DDAJAC */
    /* Parameter adjustments */
    --ipar;
    --rpar;
    --iwm;
    --wm;
    --e;
    --wt;
    --delta;
    --yprime;
    --y;

    /* Function Body */
    *ier = 0;
    npdm1 = 0;
    mtype = iwm[4];
    switch (mtype) {
	case 1:  goto L100;
	case 2:  goto L200;
	case 3:  goto L300;
	case 4:  goto L400;
	case 5:  goto L500;
    }


/*     DENSE USER-SUPPLIED MATRIX */
L100:
    lenpd = *neq * *neq;
    i__1 = lenpd;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L110: */
	wm[npdm1 + i__] = 0.;
    }
    (*jac)(x, &y[1], &yprime[1], &wm[1], cj, &rpar[1], &ipar[1]);
    goto L230;


/*     DENSE FINITE-DIFFERENCE-GENERATED MATRIX */
L200:
    *ires = 0;
    nrow = npdm1;
    squr = sqrt(*uround);
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* Computing MAX */
	d__4 = (d__1 = y[i__], abs(d__1)), d__5 = (d__2 = *h__ * yprime[i__],
		abs(d__2)), d__4 = max(d__4,d__5), d__5 = (d__3 = wt[i__],
		abs(d__3));
	del = squr * max(d__4,d__5);
	d__1 = *h__ * yprime[i__];
	del = d_sign(&del, &d__1);
	del = y[i__] + del - y[i__];
	ysave = y[i__];
	ypsave = yprime[i__];
	y[i__] += del;
	yprime[i__] += *cj * del;
	(*res)(x, &y[1], &yprime[1], &e[1], ires, &rpar[1], &ipar[1]);
	if (*ires < 0) {
	    return 0;
	}
	delinv = 1. / del;
	i__2 = *neq;
	for (l = 1; l <= i__2; ++l) {
/* L220: */
	    wm[nrow + l] = (e[l] - delta[l]) * delinv;
	}
	nrow += *neq;
	y[i__] = ysave;
	yprime[i__] = ypsave;
/* L210: */
    }


/*     DO DENSE-MATRIX LU DECOMPOSITION ON PD */
L230:
    dgefa_(&wm[1], neq, neq, &iwm[21], ier);
    return 0;


/*     DUMMY SECTION FOR IWM(MTYPE)=3 */
L300:
    return 0;


/*     BANDED USER-SUPPLIED MATRIX */
L400:
    lenpd = ((iwm[1] << 1) + iwm[2] + 1) * *neq;
    i__1 = lenpd;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L410: */
	wm[npdm1 + i__] = 0.;
    }
    (*jac)(x, &y[1], &yprime[1], &wm[1], cj, &rpar[1], &ipar[1]);
    meband = (iwm[1] << 1) + iwm[2] + 1;
    goto L550;


/*     BANDED FINITE-DIFFERENCE-GENERATED MATRIX */
L500:
    mband = iwm[1] + iwm[2] + 1;
    mba = min(mband,*neq);
    meband = mband + iwm[1];
    meb1 = meband - 1;
    msave = *neq / mband + 1;
    isave = *ntemp - 1;
    ipsave = isave + msave;
    *ires = 0;
    squr = sqrt(*uround);
    i__1 = mba;
    for (j = 1; j <= i__1; ++j) {
	i__2 = *neq;
	i__3 = mband;
	for (n = j; i__3 < 0 ? n >= i__2 : n <= i__2; n += i__3) {
	    k = (n - j) / mband + 1;
	    wm[isave + k] = y[n];
	    wm[ipsave + k] = yprime[n];
/* Computing MAX */
	    d__4 = (d__1 = y[n], abs(d__1)), d__5 = (d__2 = *h__ * yprime[n],
		    abs(d__2)), d__4 = max(d__4,d__5), d__5 = (d__3 = wt[n],
		    abs(d__3));
	    del = squr * max(d__4,d__5);
	    d__1 = *h__ * yprime[n];
	    del = d_sign(&del, &d__1);
	    del = y[n] + del - y[n];
	    y[n] += del;
/* L510: */
	    yprime[n] += *cj * del;
	}
	(*res)(x, &y[1], &yprime[1], &e[1], ires, &rpar[1], &ipar[1]);
	if (*ires < 0) {
	    return 0;
	}
	i__3 = *neq;
	i__2 = mband;
	for (n = j; i__2 < 0 ? n >= i__3 : n <= i__3; n += i__2) {
	    k = (n - j) / mband + 1;
	    y[n] = wm[isave + k];
	    yprime[n] = wm[ipsave + k];
/* Computing MAX */
	    d__4 = (d__1 = y[n], abs(d__1)), d__5 = (d__2 = *h__ * yprime[n],
		    abs(d__2)), d__4 = max(d__4,d__5), d__5 = (d__3 = wt[n],
		    abs(d__3));
	    del = squr * max(d__4,d__5);
	    d__1 = *h__ * yprime[n];
	    del = d_sign(&del, &d__1);
	    del = y[n] + del - y[n];
	    delinv = 1. / del;
/* Computing MAX */
	    i__4 = 1, i__5 = n - iwm[2];
	    i1 = max(i__4,i__5);
/* Computing MIN */
	    i__4 = *neq, i__5 = n + iwm[1];
	    i2 = min(i__4,i__5);
	    ii = n * meb1 - iwm[1] + npdm1;
	    i__4 = i2;
	    for (i__ = i1; i__ <= i__4; ++i__) {
/* L520: */
		wm[ii + i__] = (e[i__] - delta[i__]) * delinv;
	    }
/* L530: */
	}
/* L540: */
    }


/*     DO LU DECOMPOSITION OF BANDED PD */
L550:
    dgbfa_(&wm[1], &meband, neq, &iwm[1], &iwm[2], &iwm[21], ier);
    return 0;
/* ------END OF SUBROUTINE DDAJAC------ */
} /* ddajac_ */

/* Subroutine */ int ddaslv_(integer *neq, doublereal *delta, doublereal *wm,
	integer *iwm)
{
    extern /* Subroutine */ int dgbsl_(doublereal *, integer *, integer *,
	    integer *, integer *, integer *, doublereal *, integer *), dgesl_(
	    doublereal *, integer *, integer *, integer *, doublereal *,
	    integer *);
    static integer mtype, meband;

/* ***BEGIN PROLOGUE  DDASLV */
/* ***SUBSIDIARY */
/* ***PURPOSE  Linear system solver for DDASSL. */
/* ***LIBRARY   SLATEC (DASSL) */
/* ***TYPE      DOUBLE PRECISION (SDASLV-S, DDASLV-D) */
/* ***AUTHOR  PETZOLD, LINDA R., (LLNL) */
/* ***DESCRIPTION */
/* ----------------------------------------------------------------------- */
/*     THIS ROUTINE MANAGES THE SOLUTION OF THE LINEAR */
/*     SYSTEM ARISING IN THE NEWTON ITERATION. */
/*     MATRICES AND REAL TEMPORARY STORAGE AND */
/*     REAL INFORMATION ARE STORED IN THE ARRAY WM. */
/*     INTEGER MATRIX INFORMATION IS STORED IN */
/*     THE ARRAY IWM. */
/*     FOR A DENSE MATRIX, THE LINPACK ROUTINE */
/*     DGESL IS CALLED. */
/*     FOR A BANDED MATRIX,THE LINPACK ROUTINE */
/*     DGBSL IS CALLED. */
/* ----------------------------------------------------------------------- */
/* ***ROUTINES CALLED  DGBSL, DGESL */
/* ***REVISION HISTORY  (YYMMDD) */
/*   830315  DATE WRITTEN */
/*   901009  Finished conversion to SLATEC 4.0 format (F.N.Fritsch) */
/*   901019  Merged changes made by C. Ulrich with SLATEC 4.0 format. */
/*   901026  Added explicit declarations for all variables and minor */
/*           cosmetic changes to prologue.  (FNF) */
/* ***END PROLOGUE  DDASLV */




/* ***FIRST EXECUTABLE STATEMENT  DDASLV */
    /* Parameter adjustments */
    --iwm;
    --wm;
    --delta;

    /* Function Body */
    mtype = iwm[4];
    switch (mtype) {
	case 1:  goto L100;
	case 2:  goto L100;
	case 3:  goto L300;
	case 4:  goto L400;
	case 5:  goto L400;
    }

/*     DENSE MATRIX */
L100:
    dgesl_(&wm[1], neq, neq, &iwm[21], &delta[1], &c__0);
    return 0;

/*     DUMMY SECTION FOR MTYPE=3 */
L300:
    return 0;

/*     BANDED MATRIX */
L400:
    meband = (iwm[1] << 1) + iwm[2] + 1;
    dgbsl_(&wm[1], &meband, neq, &iwm[1], &iwm[2], &iwm[21], &delta[1], &c__0)
	    ;
    return 0;
/* ------END OF SUBROUTINE DDASLV------ */
} /* ddaslv_ */

/* *DECK XERMSG */
/* Subroutine */ int xermsg_(char *librar, char *subrou, char *messg, integer
	*nerr, integer *level, ftnlen librar_len, ftnlen subrou_len, ftnlen
	messg_len)
{
    /* System generated locals */
    address a__1[2];
    integer i__1, i__2[2];
    char ch__1[87];

    /* Builtin functions */
    /* Subroutine */ int s_copy(char *, char *, ftnlen, ftnlen);
    integer i_len(char *, ftnlen), s_wsfi(icilist *), do_fio(integer *, char *
	    , ftnlen), e_wsfi(void);
    /* Subroutine */ int s_cat(char *, char **, integer *, integer *, ftnlen);

    /* Local variables */
    static integer i__;
    static char temp[72];
    static integer ltemp;
    extern /* Subroutine */ int xerhlt_(char *, ftnlen);
    static integer lkntrl, mkntrl;
    extern /* Subroutine */ int xerprn_(char *, integer *, char *, integer *,
	    ftnlen, ftnlen);

    /* Fortran I/O blocks */
    static icilist io___178 = { 0, temp, 0, "('ERROR NUMBER = ', I8)", 72, 1 }
	    ;


/* ***BEGIN PROLOGUE  XERMSG */
/* ***PURPOSE  Processes error messages for SLATEC and other libraries */
/* ***LIBRARY   SLATEC */
/* ***CATEGORY  R3C */
/* ***TYPE      ALL */
/* ***KEYWORDS  ERROR MESSAGE, XERROR */
/* ***AUTHOR  FONG, KIRBY, (NMFECC AT LLNL) */
/*             Modified by */
/*           FRITSCH, F. N., (LLNL) */
/* ***DESCRIPTION */

/*   XERMSG processes a diagnostic message in a manner determined by the */
/*   value of LEVEL and the current value of the library error control */
/*   flag, KONTRL.  See subroutine XSETF for details. */
/*       (XSETF is inoperable in this version.). */

/*    LIBRAR   A character constant (or character variable) with the name */
/*             of the library.  This will be 'SLATEC' for the SLATEC */
/*             Common Math Library.  The error handling package is */
/*             general enough to be used by many libraries */
/*             simultaneously, so it is desirable for the routine that */
/*             detects and reports an error to identify the library name */
/*             as well as the routine name. */

/*    SUBROU   A character constant (or character variable) with the name */
/*             of the routine that detected the error.  Usually it is the */
/*             name of the routine that is calling XERMSG.  There are */
/*             some instances where a user callable library routine calls */
/*             lower level subsidiary routines where the error is */
/*             detected.  In such cases it may be more informative to */
/*             supply the name of the routine the user called rather than */
/*             the name of the subsidiary routine that detected the */
/*             error. */

/*    MESSG    A character constant (or character variable) with the text */
/*             of the error or warning message.  In the example below, */
/*             the message is a character constant that contains a */
/*             generic message. */

/*                   CALL XERMSG ('SLATEC', 'MMPY', */
/*                  *'THE ORDER OF THE MATRIX EXCEEDS THE ROW DIMENSION', */
/*                  *3, 1) */

/*             It is possible (and is sometimes desirable) to generate a */
/*             specific message--e.g., one that contains actual numeric */
/*             values.  Specific numeric values can be converted into */
/*             character strings using formatted WRITE statements into */
/*             character variables.  This is called standard Fortran */
/*             internal file I/O and is exemplified in the first three */
/*             lines of the following example.  You can also catenate */
/*             substrings of characters to construct the error message. */
/*             Here is an example showing the use of both writing to */
/*             an internal file and catenating character strings. */

/*                   CHARACTER*5 CHARN, CHARL */
/*                   WRITE (CHARN,10) N */
/*                   WRITE (CHARL,10) LDA */
/*                10 FORMAT(I5) */
/*                   CALL XERMSG ('SLATEC', 'MMPY', 'THE ORDER'//CHARN// */
/*                  *   ' OF THE MATRIX EXCEEDS ITS ROW DIMENSION OF'// */
/*                  *   CHARL, 3, 1) */

/*             There are two subtleties worth mentioning.  One is that */
/*             the // for character catenation is used to construct the */
/*             error message so that no single character constant is */
/*             continued to the next line.  This avoids confusion as to */
/*             whether there are trailing blanks at the end of the line. */
/*             The second is that by catenating the parts of the message */
/*             as an actual argument rather than encoding the entire */
/*             message into one large character variable, we avoid */
/*             having to know how long the message will be in order to */
/*             declare an adequate length for that large character */
/*             variable.  XERMSG calls XERPRN to print the message using */
/*             multiple lines if necessary.  If the message is very long, */
/*             XERPRN will break it into pieces of 72 characters (as */
/*             requested by XERMSG) for printing on multiple lines. */
/*             Also, XERMSG asks XERPRN to prefix each line with ' *  ' */
/*             so that the total line length could be 76 characters. */
/*             Note also that XERPRN scans the error message backwards */
/*             to ignore trailing blanks.  Another feature is that */
/*             the substring '$$' is treated as a new line sentinel */
/*             by XERPRN.  If you want to construct a multiline */
/*             message without having to count out multiples of 72 */
/*             characters, just use '$$' as a separator.  '$$' */
/*             obviously must occur within 72 characters of the */
/*             start of each line to have its intended effect since */
/*             XERPRN is asked to wrap around at 72 characters in */
/*             addition to looking for '$$'. */

/*    NERR     An integer value that is chosen by the library routine's */
/*             author.  It must be in the range -9999999 to 99999999 (8 */
/*             printable digits).  Each distinct error should have its */
/*             own error number.  These error numbers should be described */
/*             in the machine readable documentation for the routine. */
/*             The error numbers need be unique only within each routine, */
/*             so it is reasonable for each routine to start enumerating */
/*             errors from 1 and proceeding to the next integer. */

/*    LEVEL    An integer value in the range 0 to 2 that indicates the */
/*             level (severity) of the error.  Their meanings are */

/*            -1  A warning message.  This is used if it is not clear */
/*                that there really is an error, but the user's attention */
/*                may be needed.  An attempt is made to only print this */
/*                message once. */

/*             0  A warning message.  This is used if it is not clear */
/*                that there really is an error, but the user's attention */
/*                may be needed. */

/*             1  A recoverable error.  This is used even if the error is */
/*                so serious that the routine cannot return any useful */
/*                answer.  If the user has told the error package to */
/*                return after recoverable errors, then XERMSG will */
/*                return to the Library routine which can then return to */
/*                the user's routine.  The user may also permit the error */
/*                package to terminate the program upon encountering a */
/*                recoverable error. */

/*             2  A fatal error.  XERMSG will not return to its caller */
/*                after it receives a fatal error.  This level should */
/*                hardly ever be used; it is much better to allow the */
/*                user a chance to recover.  An example of one of the few */
/*                cases in which it is permissible to declare a level 2 */
/*                error is a reverse communication Library routine that */
/*                is likely to be called repeatedly until it integrates */
/*                across some interval.  If there is a serious error in */
/*                the input such that another step cannot be taken and */
/*                the Library routine is called again without the input */
/*                error having been corrected by the caller, the Library */
/*                routine will probably be called forever with improper */
/*                input.  In this case, it is reasonable to declare the */
/*                error to be fatal. */

/*    Each of the arguments to XERMSG is input; none will be modified by */
/*    XERMSG.  A routine may make multiple calls to XERMSG with warning */
/*    level messages; however, after a call to XERMSG with a recoverable */
/*    error, the routine should return to the user. */

/* ***REFERENCES  JONES, RONDALL E. AND KAHANER, DAVID K., "XERROR, THE */
/*                 SLATEC ERROR-HANDLING PACKAGE", SOFTWARE - PRACTICE */
/*                 AND EXPERIENCE, VOLUME 13, NO. 3, PP. 251-257, */
/*                 MARCH, 1983. */
/* ***ROUTINES CALLED  XERHLT, XERPRN */
/* ***REVISION HISTORY  (YYMMDD) */
/*   880101  DATE WRITTEN */
/*   880621  REVISED AS DIRECTED AT SLATEC CML MEETING OF FEBRUARY 1988. */
/*           THERE ARE TWO BASIC CHANGES. */
/*           1.  A NEW ROUTINE, XERPRN, IS USED INSTEAD OF XERPRT TO */
/*               PRINT MESSAGES.  THIS ROUTINE WILL BREAK LONG MESSAGES */
/*               INTO PIECES FOR PRINTING ON MULTIPLE LINES.  '$$' IS */
/*               ACCEPTED AS A NEW LINE SENTINEL.  A PREFIX CAN BE */
/*               ADDED TO EACH LINE TO BE PRINTED.  XERMSG USES EITHER */
/*               ' ***' OR ' *  ' AND LONG MESSAGES ARE BROKEN EVERY */
/*               72 CHARACTERS (AT MOST) SO THAT THE MAXIMUM LINE */
/*               LENGTH OUTPUT CAN NOW BE AS GREAT AS 76. */
/*           2.  THE TEXT OF ALL MESSAGES IS NOW IN UPPER CASE SINCE THE */
/*               FORTRAN STANDARD DOCUMENT DOES NOT ADMIT THE EXISTENCE */
/*               OF LOWER CASE. */
/*   880708  REVISED AFTER THE SLATEC CML MEETING OF JUNE 29 AND 30. */
/*           THE PRINCIPAL CHANGES ARE */
/*           1.  CLARIFY COMMENTS IN THE PROLOGUES */
/*           2.  RENAME XRPRNT TO XERPRN */
/*           3.  REWORK HANDLING OF '$$' IN XERPRN TO HANDLE BLANK LINES */
/*               SIMILAR TO THE WAY FORMAT STATEMENTS HANDLE THE / */
/*               CHARACTER FOR NEW RECORDS. */
/*   890706  REVISED WITH THE HELP OF FRED FRITSCH AND REG CLEMENS TO */
/*           CLEAN UP THE CODING. */
/*   890721  REVISED TO USE NEW FEATURE IN XERPRN TO COUNT CHARACTERS IN */
/*           PREFIX. */
/*   891013  REVISED TO CORRECT COMMENTS. */
/*   891214  Prologue converted to Version 4.0 format.  (WRB) */
/*   900510  Changed test on NERR to be -9999999 < NERR < 99999999, but */
/*           NERR .ne. 0, and on LEVEL to be -2 < LEVEL < 3.  Added */
/*           LEVEL=-1 logic, changed calls to XERSAV to XERSVE, and */
/*           XERCTL to XERCNT.  (RWC) */
/*   901011  Removed error saving features to produce a simplified */
/*           version for distribution with DASSL and other LLNL codes. */
/*           (FNF) */
/* ***END PROLOGUE  XERMSG */
/* ***FIRST EXECUTABLE STATEMENT  XERMSG */

/*       WE PRINT A FATAL ERROR MESSAGE AND TERMINATE FOR AN ERROR IN */
/*          CALLING XERMSG.  THE ERROR NUMBER SHOULD BE POSITIVE, */
/*          AND THE LEVEL SHOULD BE BETWEEN 0 AND 2. */

    if (*nerr < -9999999 || *nerr > 99999999 || *nerr == 0 || *level < -1 || *
	    level > 2) {
	xerprn_(" ***", &c_n1, "FATAL ERROR IN...$$ XERMSG -- INVALID ERROR "
		"NUMBER OR LEVEL$$ JOB ABORT DUE TO FATAL ERROR.", &c__72, (
		ftnlen)4, (ftnlen)91);
	xerhlt_(" ***XERMSG -- INVALID INPUT", (ftnlen)27);
	return 0;
    }

/*       SET DEFAULT VALUES FOR CONTROL PARAMETERS. */

    lkntrl = 1;
    mkntrl = 1;

/*       ANNOUNCE THE NAMES OF THE LIBRARY AND SUBROUTINE BY BUILDING A */
/*       MESSAGE IN CHARACTER VARIABLE TEMP (NOT EXCEEDING 66 CHARACTERS) */
/*       AND SENDING IT OUT VIA XERPRN.  PRINT ONLY IF CONTROL FLAG */
/*       IS NOT ZERO. */

    if (lkntrl != 0) {
	s_copy(temp, "MESSAGE FROM ROUTINE ", (ftnlen)21, (ftnlen)21);
/* Computing MIN */
	i__1 = i_len(subrou, subrou_len);
	i__ = min(i__1,16);
	s_copy(temp + 21, subrou, i__, i__);
	i__1 = i__ + 21;
	s_copy(temp + i__1, " IN LIBRARY ", i__ + 33 - i__1, (ftnlen)12);
	ltemp = i__ + 33;
/* Computing MIN */
	i__1 = i_len(librar, librar_len);
	i__ = min(i__1,16);
	i__1 = ltemp;
	s_copy(temp + i__1, librar, ltemp + i__ - i__1, i__);
	i__1 = ltemp + i__;
	s_copy(temp + i__1, ".", ltemp + i__ + 1 - i__1, (ftnlen)1);
	ltemp = ltemp + i__ + 1;
	xerprn_(" ***", &c_n1, temp, &c__72, (ftnlen)4, ltemp);
    }

/*       IF LKNTRL IS POSITIVE, PRINT AN INTRODUCTORY LINE BEFORE */
/*       PRINTING THE MESSAGE.  THE INTRODUCTORY LINE TELLS THE CHOICE */
/*       FROM EACH OF THE FOLLOWING TWO OPTIONS. */
/*       1.  LEVEL OF THE MESSAGE */
/*              'INFORMATIVE MESSAGE' */
/*              'POTENTIALLY RECOVERABLE ERROR' */
/*              'FATAL ERROR' */
/*       2.  WHETHER CONTROL FLAG WILL ALLOW PROGRAM TO CONTINUE */
/*              'PROGRAM CONTINUES' */
/*              'PROGRAM ABORTED' */
/*       NOTICE THAT THE LINE INCLUDING FOUR PREFIX CHARACTERS WILL NOT */
/*       EXCEED 74 CHARACTERS. */
/*       WE SKIP THE NEXT BLOCK IF THE INTRODUCTORY LINE IS NOT NEEDED. */

    if (lkntrl > 0) {

/*       THE FIRST PART OF THE MESSAGE TELLS ABOUT THE LEVEL. */

	if (*level <= 0) {
	    s_copy(temp, "INFORMATIVE MESSAGE,", (ftnlen)20, (ftnlen)20);
	    ltemp = 20;
	} else if (*level == 1) {
	    s_copy(temp, "POTENTIALLY RECOVERABLE ERROR,", (ftnlen)30, (
		    ftnlen)30);
	    ltemp = 30;
	} else {
	    s_copy(temp, "FATAL ERROR,", (ftnlen)12, (ftnlen)12);
	    ltemp = 12;
	}

/*       THEN WHETHER THE PROGRAM WILL CONTINUE. */

	if (mkntrl == 2 && *level >= 1 || mkntrl == 1 && *level == 2) {
	    i__1 = ltemp;
	    s_copy(temp + i__1, " PROGRAM ABORTED.", ltemp + 17 - i__1, (
		    ftnlen)17);
	    ltemp += 17;
	} else {
	    i__1 = ltemp;
	    s_copy(temp + i__1, " PROGRAM CONTINUES.", ltemp + 19 - i__1, (
		    ftnlen)19);
	    ltemp += 19;
	}

	xerprn_(" ***", &c_n1, temp, &c__72, (ftnlen)4, ltemp);
    }

/*       NOW SEND OUT THE MESSAGE. */

    xerprn_(" *  ", &c_n1, messg, &c__72, (ftnlen)4, messg_len);

/*       IF LKNTRL IS POSITIVE, WRITE THE ERROR NUMBER. */

    if (lkntrl > 0) {
	s_wsfi(&io___178);
	do_fio(&c__1, (char *)&(*nerr), (ftnlen)sizeof(integer));
	e_wsfi();
	for (i__ = 16; i__ <= 22; ++i__) {
	    if (*(unsigned char *)&temp[i__ - 1] != ' ') {
		goto L20;
	    }
/* L10: */
	}

L20:
/* Writing concatenation */
	i__2[0] = 15, a__1[0] = temp;
	i__2[1] = 23 - (i__ - 1), a__1[1] = temp + (i__ - 1);
	s_cat(ch__1, a__1, i__2, &c__2, (ftnlen)87);
	xerprn_(" *  ", &c_n1, ch__1, &c__72, (ftnlen)4, 23 - (i__ - 1) + 15);
    }

/*       IF LKNTRL IS NOT ZERO, PRINT A BLANK LINE AND AN END OF MESSAGE. */

    if (lkntrl != 0) {
	xerprn_(" *  ", &c_n1, " ", &c__72, (ftnlen)4, (ftnlen)1);
	xerprn_(" ***", &c_n1, "END OF MESSAGE", &c__72, (ftnlen)4, (ftnlen)
		14);
	xerprn_("    ", &c__0, " ", &c__72, (ftnlen)4, (ftnlen)1);
    }

/*       IF THE ERROR IS NOT FATAL OR THE ERROR IS RECOVERABLE AND THE */
/*       CONTROL FLAG IS SET FOR RECOVERY, THEN RETURN. */

/* L30: */
    if (*level <= 0 || *level == 1 && mkntrl <= 1) {
	return 0;
    }

/*       THE PROGRAM WILL BE STOPPED DUE TO AN UNRECOVERED ERROR OR A */
/*       FATAL ERROR.  PRINT THE REASON FOR THE ABORT AND THE ERROR */
/*       SUMMARY IF THE CONTROL FLAG AND THE MAXIMUM ERROR COUNT PERMIT. */

    if (lkntrl > 0) {
	if (*level == 1) {
	    xerprn_(" ***", &c_n1, "JOB ABORT DUE TO UNRECOVERED ERROR.", &
		    c__72, (ftnlen)4, (ftnlen)35);
	} else {
	    xerprn_(" ***", &c_n1, "JOB ABORT DUE TO FATAL ERROR.", &c__72, (
		    ftnlen)4, (ftnlen)29);
	}
	xerhlt_(" ", (ftnlen)1);
    }
    return 0;
} /* xermsg_ */

/* Subroutine */ int xerhlt_(char *messg, ftnlen messg_len)
{
    /* Builtin functions */
    /* Subroutine */ int s_stop(char *, ftnlen);

/* ***BEGIN PROLOGUE  XERHLT */
/* ***SUBSIDIARY */
/* ***PURPOSE  Abort program execution and print error message. */
/* ***LIBRARY   SLATEC (XERROR) */
/* ***CATEGORY  R3C */
/* ***TYPE      ALL (XERHLT-A) */
/* ***KEYWORDS  ERROR, XERROR */
/* ***AUTHOR  JONES, R. E., (SNLA) */
/* ***DESCRIPTION */

/*     Abstract */
/*        ***Note*** machine dependent routine */
/*        XERHLT aborts the execution of the program. */
/*        The error message causing the abort is given in the calling */
/*        sequence, in case one needs it for printing on a dayfile, */
/*        for example. */

/*     Description of Parameters */
/*        MESSG is as in XERROR. */

/* ***REFERENCES  JONES R.E., KAHANER D.K., 'XERROR, THE SLATEC ERROR- */
/*                 HANDLING PACKAGE', SAND82-0800, SANDIA LABORATORIES, */
/*                 1982. */
/* ***ROUTINES CALLED  (NONE) */
/* ***REVISION HISTORY  (YYMMDD) */
/*   790801  DATE WRITTEN as XERABT */
/*   861211  REVISION DATE from Version 3.2 */
/*   891214  Prologue converted to Version 4.0 format.  (BAB) */
/*   900206  Routine changed from user-callable to subsidiary.  (WRB) */
/*   900510  Changed calling sequence to delete length of char string */
/*           Changed subroutine name from XERABT to XERHLT.  (RWC) */
/* ***END PROLOGUE  XERHLT */
/* ***FIRST EXECUTABLE STATEMENT  XERHLT */
    s_stop("", (ftnlen)0);
    return 0;
} /* xerhlt_ */

/* *DECK XERPRN */
/* Subroutine */ int xerprn_(char *prefix, integer *npref, char *messg,
	integer *nwrap, ftnlen prefix_len, ftnlen messg_len)
{
    /* System generated locals */
    integer i__1, i__2;

    /* Builtin functions */
    integer i_len(char *, ftnlen);
    /* Subroutine */ int s_copy(char *, char *, ftnlen, ftnlen);
    integer s_wsfe(cilist *), do_fio(integer *, char *, ftnlen), e_wsfe(void),
	     i_indx(char *, char *, ftnlen, ftnlen), s_cmp(char *, char *,
	    ftnlen, ftnlen);

    /* Local variables */
    static integer i__, n, iu[5];
    static char cbuff[148];
    static integer lpref, nextc, lwrap, nunit;
    extern integer i1mach_(integer *);
    static integer lpiece, idelta, lenmsg;
    extern /* Subroutine */ int xgetua_(integer *, integer *);

    /* Fortran I/O blocks */
    static cilist io___187 = { 0, 0, 0, "(A)", 0 };
    static cilist io___191 = { 0, 0, 0, "(A)", 0 };


/* ***BEGIN PROLOGUE  XERPRN */
/* ***SUBSIDIARY */
/* ***PURPOSE  This routine is called by XERMSG to print error messages */
/* ***LIBRARY   SLATEC */
/* ***CATEGORY  R3C */
/* ***TYPE      ALL */
/* ***KEYWORDS  ERROR MESSAGES, PRINTING, XERROR */
/* ***AUTHOR  FONG, KIRBY, (NMFECC AT LLNL) */
/* ***DESCRIPTION */

/* This routine sends one or more lines to each of the (up to five) */
/* logical units to which error messages are to be sent.  This routine */
/* is called several times by XERMSG, sometimes with a single line to */
/* print and sometimes with a (potentially very long) message that may */
/* wrap around into multiple lines. */

/* PREFIX  Input argument of type CHARACTER.  This argument contains */
/*         characters to be put at the beginning of each line before */
/*         the body of the message.  No more than 16 characters of */
/*         PREFIX will be used. */

/* NPREF   Input argument of type INTEGER.  This argument is the number */
/*         of characters to use from PREFIX.  If it is negative, the */
/*         intrinsic function LEN is used to determine its length.  If */
/*         it is zero, PREFIX is not used.  If it exceeds 16 or if */
/*         LEN(PREFIX) exceeds 16, only the first 16 characters will be */
/*         used.  If NPREF is positive and the length of PREFIX is less */
/*         than NPREF, a copy of PREFIX extended with blanks to length */
/*         NPREF will be used. */

/* MESSG   Input argument of type CHARACTER.  This is the text of a */
/*         message to be printed.  If it is a long message, it will be */
/*         broken into pieces for printing on multiple lines.  Each line */
/*         will start with the appropriate prefix and be followed by a */
/*         piece of the message.  NWRAP is the number of characters per */
/*         piece; that is, after each NWRAP characters, we break and */
/*         start a new line.  In addition the characters '$$' embedded */
/*         in MESSG are a sentinel for a new line.  The counting of */
/*         characters up to NWRAP starts over for each new line.  The */
/*         value of NWRAP typically used by XERMSG is 72 since many */
/*         older error messages in the SLATEC Library are laid out to */
/*         rely on wrap-around every 72 characters. */

/* NWRAP   Input argument of type INTEGER.  This gives the maximum size */
/*         piece into which to break MESSG for printing on multiple */
/*         lines.  An embedded '$$' ends a line, and the count restarts */
/*         at the following character.  If a line break does not occur */
/*         on a blank (it would split a word) that word is moved to the */
/*         next line.  Values of NWRAP less than 16 will be treated as */
/*         16.  Values of NWRAP greater than 132 will be treated as 132. */
/*         The actual line length will be NPREF + NWRAP after NPREF has */
/*         been adjusted to fall between 0 and 16 and NWRAP has been */
/*         adjusted to fall between 16 and 132. */

/* ***REFERENCES  (NONE) */
/* ***ROUTINES CALLED  I1MACH, XGETUA */
/* ***REVISION HISTORY  (YYMMDD) */
/*   880621  DATE WRITTEN */
/*   880708  REVISED AFTER THE SLATEC CML SUBCOMMITTEE MEETING OF */
/*           JUNE 29 AND 30 TO CHANGE THE NAME TO XERPRN AND TO REWORK */
/*           THE HANDLING OF THE NEW LINE SENTINEL TO BEHAVE LIKE THE */
/*           SLASH CHARACTER IN FORMAT STATEMENTS. */
/*   890706  REVISED WITH THE HELP OF FRED FRITSCH AND REG CLEMMENS TO */
/*           STREAMLINE THE CODING AND FIX A BUG THAT CAUSED EXTRA BLANK */
/*           LINES TO BE PRINTED. */
/*   890721  REVISED TO ADD A NEW FEATURE.  A NEGATIVE VALUE OF NPREF */
/*           CAUSES LEN(PREFIX) TO BE USED AS THE LENGTH. */
/*   891013  REVISED TO CORRECT ERROR IN CALCULATING PREFIX LENGTH. */
/*   891214  Prologue converted to Version 4.0 format.  (WRB) */
/*   900510  Added code to break messages between words.  (RWC) */
/* ***END PROLOGUE  XERPRN */
/* ***FIRST EXECUTABLE STATEMENT  XERPRN */
    xgetua_(iu, &nunit);

/*       A ZERO VALUE FOR A LOGICAL UNIT NUMBER MEANS TO USE THE STANDARD */
/*       ERROR MESSAGE UNIT INSTEAD.  I1MACH(4) RETRIEVES THE STANDARD */
/*       ERROR MESSAGE UNIT. */

    n = i1mach_(&c__4);
    i__1 = nunit;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (iu[i__ - 1] == 0) {
	    iu[i__ - 1] = n;
	}
/* L10: */
    }

/*       LPREF IS THE LENGTH OF THE PREFIX.  THE PREFIX IS PLACED AT THE */
/*       BEGINNING OF CBUFF, THE CHARACTER BUFFER, AND KEPT THERE DURING */
/*       THE REST OF THIS ROUTINE. */

    if (*npref < 0) {
	lpref = i_len(prefix, prefix_len);
    } else {
	lpref = *npref;
    }
    lpref = min(16,lpref);
    if (lpref != 0) {
	s_copy(cbuff, prefix, lpref, prefix_len);
    }

/*       LWRAP IS THE MAXIMUM NUMBER OF CHARACTERS WE WANT TO TAKE AT ONE */
/*       TIME FROM MESSG TO PRINT ON ONE LINE. */

/* Computing MAX */
    i__1 = 16, i__2 = min(132,*nwrap);
    lwrap = max(i__1,i__2);

/*       SET LENMSG TO THE LENGTH OF MESSG, IGNORE ANY TRAILING BLANKS. */

    lenmsg = i_len(messg, messg_len);
    n = lenmsg;
    i__1 = n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (*(unsigned char *)&messg[lenmsg - 1] != ' ') {
	    goto L30;
	}
	--lenmsg;
/* L20: */
    }
L30:

/*       IF THE MESSAGE IS ALL BLANKS, THEN PRINT ONE BLANK LINE. */

    if (lenmsg == 0) {
	i__1 = lpref;
	s_copy(cbuff + i__1, " ", lpref + 1 - i__1, (ftnlen)1);
	i__1 = nunit;
	for (i__ = 1; i__ <= i__1; ++i__) {
	    io___187.ciunit = iu[i__ - 1];
	    s_wsfe(&io___187);
	    do_fio(&c__1, cbuff, lpref + 1);
	    e_wsfe();
/* L40: */
	}
	return 0;
    }

/*       SET NEXTC TO THE POSITION IN MESSG WHERE THE NEXT SUBSTRING */
/*       STARTS.  FROM THIS POSITION WE SCAN FOR THE NEW LINE SENTINEL. */
/*       WHEN NEXTC EXCEEDS LENMSG, THERE IS NO MORE TO PRINT. */
/*       WE LOOP BACK TO LABEL 50 UNTIL ALL PIECES HAVE BEEN PRINTED. */

/*       WE LOOK FOR THE NEXT OCCURRENCE OF THE NEW LINE SENTINEL.  THE */
/*       INDEX INTRINSIC FUNCTION RETURNS ZERO IF THERE IS NO OCCURRENCE */
/*       OR IF THE LENGTH OF THE FIRST ARGUMENT IS LESS THAN THE LENGTH */
/*       OF THE SECOND ARGUMENT. */

/*       THERE ARE SEVERAL CASES WHICH SHOULD BE CHECKED FOR IN THE */
/*       FOLLOWING ORDER.  WE ARE ATTEMPTING TO SET LPIECE TO THE NUMBER */
/*       OF CHARACTERS THAT SHOULD BE TAKEN FROM MESSG STARTING AT */
/*       POSITION NEXTC. */

/*       LPIECE .EQ. 0   THE NEW LINE SENTINEL DOES NOT OCCUR IN THE */
/*                       REMAINDER OF THE CHARACTER STRING.  LPIECE */
/*                       SHOULD BE SET TO LWRAP OR LENMSG+1-NEXTC, */
/*                       WHICHEVER IS LESS. */

/*       LPIECE .EQ. 1   THE NEW LINE SENTINEL STARTS AT MESSG(NEXTC: */
/*                       NEXTC).  LPIECE IS EFFECTIVELY ZERO, AND WE */
/*                       PRINT NOTHING TO AVOID PRODUCING UNNECESSARY */
/*                       BLANK LINES.  THIS TAKES CARE OF THE SITUATION */
/*                       WHERE THE LIBRARY ROUTINE HAS A MESSAGE OF */
/*                       EXACTLY 72 CHARACTERS FOLLOWED BY A NEW LINE */
/*                       SENTINEL FOLLOWED BY MORE CHARACTERS.  NEXTC */
/*                       SHOULD BE INCREMENTED BY 2. */

/*       LPIECE .GT. LWRAP+1  REDUCE LPIECE TO LWRAP. */

/*       ELSE            THIS LAST CASE MEANS 2 .LE. LPIECE .LE. LWRAP+1 */
/*                       RESET LPIECE = LPIECE-1.  NOTE THAT THIS */
/*                       PROPERLY HANDLES THE END CASE WHERE LPIECE .EQ. */
/*                       LWRAP+1.  THAT IS, THE SENTINEL FALLS EXACTLY */
/*                       AT THE END OF A LINE. */

    nextc = 1;
L50:
    lpiece = i_indx(messg + (nextc - 1), "$$", lenmsg - (nextc - 1), (ftnlen)
	    2);
    if (lpiece == 0) {

/*       THERE WAS NO NEW LINE SENTINEL FOUND. */

	idelta = 0;
/* Computing MIN */
	i__1 = lwrap, i__2 = lenmsg + 1 - nextc;
	lpiece = min(i__1,i__2);
	if (lpiece < lenmsg + 1 - nextc) {
	    for (i__ = lpiece + 1; i__ >= 2; --i__) {
		i__1 = nextc + i__ - 2;
		if (s_cmp(messg + i__1, " ", nextc + i__ - 1 - i__1, (ftnlen)
			1) == 0) {
		    lpiece = i__ - 1;
		    idelta = 1;
		    goto L54;
		}
/* L52: */
	    }
	}
L54:
	i__1 = lpref;
	s_copy(cbuff + i__1, messg + (nextc - 1), lpref + lpiece - i__1,
		nextc + lpiece - 1 - (nextc - 1));
	nextc = nextc + lpiece + idelta;
    } else if (lpiece == 1) {

/*       WE HAVE A NEW LINE SENTINEL AT MESSG(NEXTC:NEXTC+1). */
/*       DON'T PRINT A BLANK LINE. */

	nextc += 2;
	goto L50;
    } else if (lpiece > lwrap + 1) {

/*       LPIECE SHOULD BE SET DOWN TO LWRAP. */

	idelta = 0;
	lpiece = lwrap;
	for (i__ = lpiece + 1; i__ >= 2; --i__) {
	    i__1 = nextc + i__ - 2;
	    if (s_cmp(messg + i__1, " ", nextc + i__ - 1 - i__1, (ftnlen)1) ==
		     0) {
		lpiece = i__ - 1;
		idelta = 1;
		goto L58;
	    }
/* L56: */
	}
L58:
	i__1 = lpref;
	s_copy(cbuff + i__1, messg + (nextc - 1), lpref + lpiece - i__1,
		nextc + lpiece - 1 - (nextc - 1));
	nextc = nextc + lpiece + idelta;
    } else {

/*       IF WE ARRIVE HERE, IT MEANS 2 .LE. LPIECE .LE. LWRAP+1. */
/*       WE SHOULD DECREMENT LPIECE BY ONE. */

	--lpiece;
	i__1 = lpref;
	s_copy(cbuff + i__1, messg + (nextc - 1), lpref + lpiece - i__1,
		nextc + lpiece - 1 - (nextc - 1));
	nextc = nextc + lpiece + 2;
    }

/*       PRINT */

    i__1 = nunit;
    for (i__ = 1; i__ <= i__1; ++i__) {
	io___191.ciunit = iu[i__ - 1];
	s_wsfe(&io___191);
	do_fio(&c__1, cbuff, lpref + lpiece);
	e_wsfe();
/* L60: */
    }

    if (nextc <= lenmsg) {
	goto L50;
    }
    return 0;
} /* xerprn_ */

/* *DECK XGETUA */
/* Subroutine */ int xgetua_(integer *iunita, integer *n)
{
    /* System generated locals */
    integer i__1;

    /* Local variables */
    static integer i__;

/* ***BEGIN PROLOGUE  XGETUA */
/* ***PURPOSE  Return unit number(s) to which error messages are being */
/*            sent. */
/* ***LIBRARY   SLATEC (XERROR) */
/* ***CATEGORY  R3C */
/* ***TYPE      ALL (XGETUA-A) */
/* ***KEYWORDS  ERROR, XERROR */
/* ***AUTHOR  JONES, R. E., (SNLA) */
/*             Modified by */
/*           FRITSCH, F. N., (LLNL) */
/* ***DESCRIPTION */

/*     Abstract */
/*        XGETUA may be called to determine the unit number or numbers */
/*        to which error messages are being sent. */
/*        These unit numbers may have been set by a call to XSETUN, */
/*        or a call to XSETUA, or may be a default value. */

/*     Description of Parameters */
/*      --Output-- */
/*        IUNIT - an array of one to five unit numbers, depending */
/*                on the value of N.  A value of zero refers to the */
/*                default unit, as defined by the I1MACH machine */
/*                constant routine.  Only IUNIT(1),...,IUNIT(N) are */
/*                defined by XGETUA.  The values of IUNIT(N+1),..., */
/*                IUNIT(5) are not defined (for N .LT. 5) or altered */
/*                in any way by XGETUA. */
/*        N     - the number of units to which copies of the */
/*                error messages are being sent.  N will be in the */
/*                range from 1 to 5. */

/*     CAUTION:  The use of COMMON in this version is not safe for */
/*               multiprocessing. */

/* ***REFERENCES  JONES R.E., KAHANER D.K., 'XERROR, THE SLATEC ERROR- */
/*                 HANDLING PACKAGE', SAND82-0800, SANDIA LABORATORIES, */
/*                 1982. */
/* ***ROUTINES CALLED  (NONE) */
/* ***COMMON BLOCKS    XERUNI */
/* ***REVISION HISTORY  (YYMMDD) */
/*   790801  DATE WRITTEN */
/*   861211  REVISION DATE from Version 3.2 */
/*   891214  Prologue converted to Version 4.0 format.  (BAB) */
/*   901011  Rewritten to not use J4SAVE.  (FNF) */
/*   901012  Corrected initialization problem.  (FNF) */
/* ***END PROLOGUE  XGETUA */
/* ***FIRST EXECUTABLE STATEMENT  XGETUA */
/*       Initialize so XERMSG will use standard error unit number if */
/*       block has not been set up by a CALL XSETUA. */
/*       CAUTION:  This assumes uninitialized COMMON tests .LE.0 . */
    /* Parameter adjustments */
    --iunita;

    /* Function Body */
    if (xeruni_1.nunit <= 0) {
	xeruni_1.nunit = 1;
	xeruni_1.iunit[0] = 0;
    }
    *n = xeruni_1.nunit;
    i__1 = *n;
    for (i__ = 1; i__ <= i__1; ++i__) {
	iunita[i__] = xeruni_1.iunit[i__ - 1];
/* L30: */
    }
    return 0;
} /* xgetua_ */

/* *DECK XSETUA */
/* Subroutine */ int xsetua_(integer *iunita, integer *n)
{
    /* System generated locals */
    address a__1[2];
    integer i__1[2], i__2;
    char ch__1[37];

    /* Builtin functions */
    integer s_wsfi(icilist *), do_fio(integer *, char *, ftnlen), e_wsfi(void)
	    ;
    /* Subroutine */ int s_cat(char *, char **, integer *, integer *, ftnlen);

    /* Local variables */
    static integer i__;
    static char xern1[8];
    extern /* Subroutine */ int xermsg_(char *, char *, char *, integer *,
	    integer *, ftnlen, ftnlen, ftnlen);

    /* Fortran I/O blocks */
    static icilist io___194 = { 0, xern1, 0, "(I8)", 8, 1 };


/* ***BEGIN PROLOGUE  XSETUA */
/* ***PURPOSE  Set logical unit numbers (up to 5) to which error */
/*            messages are to be sent. */
/* ***LIBRARY   SLATEC (XERROR) */
/* ***CATEGORY  R3B */
/* ***TYPE      ALL (XSETUA-A) */
/* ***KEYWORDS  ERROR, XERROR */
/* ***AUTHOR  JONES, R. E., (SNLA) */
/*             Modified by */
/*           FRITSCH, F. N., (LLNL) */
/* ***DESCRIPTION */

/*     Abstract */
/*        XSETUA may be called to declare a list of up to five */
/*        logical units, each of which is to receive a copy of */
/*        each error message processed by this package. */
/*        The purpose of XSETUA is to allow simultaneous printing */
/*        of each error message on, say, a main output file, */
/*        an interactive terminal, and other files such as graphics */
/*        communication files. */

/*     Description of Parameters */
/*      --Input-- */
/*        IUNIT - an array of up to five unit numbers. */
/*                Normally these numbers should all be different */
/*                (but duplicates are not prohibited.) */
/*        N     - the number of unit numbers provided in IUNIT */
/*                must have 1 .LE. N .LE. 5. */

/*     CAUTION:  The use of COMMON in this version is not safe for */
/*               multiprocessing. */

/* ***REFERENCES  JONES R.E., KAHANER D.K., 'XERROR, THE SLATEC ERROR- */
/*                 HANDLING PACKAGE', SAND82-0800, SANDIA LABORATORIES, */
/*                 1982. */
/* ***ROUTINES CALLED  XERMSG */
/* ***COMMON BLOCKS    XERUNI */
/* ***REVISION HISTORY  (YYMMDD) */
/*   790801  DATE WRITTEN */
/*   861211  REVISION DATE from Version 3.2 */
/*   891214  Prologue converted to Version 4.0 format.  (BAB) */
/*   900510  Change call to XERRWV to XERMSG.  (RWC) */
/*   901011  Rewritten to not use J4SAVE.  (FNF) */
/* ***END PROLOGUE  XSETUA */
/* ***FIRST EXECUTABLE STATEMENT  XSETUA */

    /* Parameter adjustments */
    --iunita;

    /* Function Body */
    if (*n < 1 || *n > 5) {
	s_wsfi(&io___194);
	do_fio(&c__1, (char *)&(*n), (ftnlen)sizeof(integer));
	e_wsfi();
/* Writing concatenation */
	i__1[0] = 29, a__1[0] = "INVALID NUMBER OF UNITS, N = ";
	i__1[1] = 8, a__1[1] = xern1;
	s_cat(ch__1, a__1, i__1, &c__2, (ftnlen)37);
	xermsg_("SLATEC", "XSETUA", ch__1, &c__1, &c__2, (ftnlen)6, (ftnlen)6,
		 (ftnlen)37);
	return 0;
    }

    i__2 = *n;
    for (i__ = 1; i__ <= i__2; ++i__) {
	xeruni_1.iunit[i__ - 1] = iunita[i__];
/* L10: */
    }
    xeruni_1.nunit = *n;
    return 0;
} /* xsetua_ */

