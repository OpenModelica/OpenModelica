/* ddasrt.f -- translated by f2c (version 20061008).
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
    integer iero;
} ierode_;

#define ierode_1 ierode_

/* Table of constant values */

static integer c__49 = 49;
static integer c__201 = 201;
static integer c__0 = 0;
static doublereal c_b30 = 0.;
static integer c__47 = 47;
static integer c__202 = 202;
static integer c__1 = 1;
static integer c__41 = 41;
static integer c__203 = 203;
static integer c__3 = 3;
static integer c__2 = 2;
static integer c__38 = 38;
static integer c__610 = 610;
static integer c__48 = 48;
static integer c__611 = 611;
static integer c__620 = 620;
static integer c__621 = 621;
static integer c__45 = 45;
static integer c__622 = 622;
static integer c__630 = 630;
static integer c__28 = 28;
static integer c__631 = 631;
static integer c__44 = 44;
static integer c__640 = 640;
static integer c__57 = 57;
static integer c__641 = 641;
static integer c__650 = 650;
static integer c__651 = 651;
static integer c__652 = 652;
static integer c__660 = 660;
static integer c__37 = 37;
static integer c__661 = 661;
static integer c__670 = 670;
static integer c__671 = 671;
static integer c__672 = 672;
static integer c__675 = 675;
static integer c__676 = 676;
static integer c__36 = 36;
static integer c__677 = 677;
static integer c__40 = 40;
static integer c__680 = 680;
static integer c__681 = 681;
static integer c__685 = 685;
static integer c__686 = 686;
static integer c__55 = 55;
static integer c__25 = 25;
static integer c__34 = 34;
static integer c__60 = 60;
static integer c__4 = 4;
static integer c__5 = 5;
static integer c__39 = 39;
static integer c__6 = 6;
static integer c__7 = 7;
static integer c__8 = 8;
static integer c__54 = 54;
static integer c__9 = 9;
static integer c__10 = 10;
static integer c__11 = 11;
static integer c__29 = 29;
static integer c__12 = 12;
static integer c__13 = 13;
static integer c__14 = 14;
static integer c__15 = 15;
static integer c__52 = 52;
static integer c__17 = 17;
static integer c__18 = 18;
static integer c__19 = 19;
static integer c__24 = 24;
static integer c__30 = 30;
static integer c__32 = 32;
static integer c__46 = 46;
static integer c__801 = 801;
static integer c__802 = 802;
static doublereal c_b588 = 1.;

/* Subroutine */ int ddasrt_(U_fp res, integer *neq, doublereal *t, 
	doublereal *y, doublereal *yprime, doublereal *tout, integer *info, 
	doublereal *rtol, doublereal *atol, integer *idid, doublereal *rwork, 
	integer *lrw, integer *iwork, integer *liw, doublereal *rpar, integer 
	*ipar, U_fp jac, U_fp g, integer *ng, integer *jroot)
{
    /* System generated locals */
    integer i__1;
    doublereal d__1, d__2;

    /* Builtin functions */
    /* Subroutine */ int s_copy(char *, char *, ftnlen, ftnlen);
    double d_sign(doublereal *, doublereal *);

    /* Local variables */
    static doublereal h__;
    static integer i__;
    static doublereal r__;
    static integer le;
    static doublereal ho, rh, tn;
    static integer lg0, lg1, lpd;
    static char msg[80];
    static integer lgx, lwm, irt, lwt;
    static logical done;
    static doublereal hmax;
    static integer lphi;
    static doublereal hmin;
    static integer mband, lenpd;
    static doublereal atoli;
    static integer msave, leniw, itemp, nzflg;
    extern /* Subroutine */ int dcopy_(integer *, doublereal *, integer *, 
	    doublereal *, integer *);
    static integer ntemp, lenrw;
    static doublereal tdist;
    static integer mxord;
    static doublereal rtoli, tnext, tstop;
    extern doublereal dlamch_(char *, ftnlen);
    extern /* Subroutine */ int ddaini_(doublereal *, doublereal *, 
	    doublereal *, integer *, U_fp, U_fp, doublereal *, doublereal *, 
	    integer *, doublereal *, integer *, doublereal *, doublereal *, 
	    doublereal *, doublereal *, integer *, doublereal *, doublereal *,
	     integer *, integer *), drchek_(integer *, U_fp, integer *, 
	    integer *, doublereal *, doublereal *, doublereal *, doublereal *,
	     doublereal *, doublereal *, integer *, doublereal *, doublereal *
	    , doublereal *, integer *, integer *, doublereal *, integer *, 
	    doublereal *, integer *, doublereal *, integer *);
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
	    doublereal *, integer *);
    static doublereal uround, ypnorm;
    extern /* Subroutine */ int xerrwv_(char *, integer *, integer *, integer 
	    *, integer *, integer *, integer *, integer *, doublereal *, 
	    doublereal *, ftnlen);

/* ***MODIF */
/*   WHEN A ROOT IS FOUND YPRIME WAS NOT UPDATED. see c*SS* modifications */

/* ***BEGIN PROLOGUE  DDASRT */
/* ***DATE WRITTEN   821001   (YYMMDD) */
/* ***REVISION DATE  910624   (YYMMDD) */
/* ***KEYWORDS  DIFFERENTIAL/ALGEBRAIC,BACKWARD DIFFERENTIATION FORMULAS */
/*             IMPLICIT DIFFERENTIAL SYSTEMS */
/* ***AUTHOR  PETZOLD,LINDA R.,COMPUTING AND MATHEMATICS RESEARCH DIVISION */
/*             LAWRENCE LIVERMORE NATIONAL LABORATORY */
/*             L - 316, P.O. Box 808, */
/*             LIVERMORE, CA.    94550 */
/* ***PURPOSE  This code solves a system of differential/algebraic */
/*            equations of the form F(T,Y,YPRIME) = 0. */
/* ***DESCRIPTION */

/* *Usage: */

/*      IMPLICIT DOUBLE PRECISION (A-H,O-Z) */
/*      EXTERNAL RES, JAC, G */
/*      INTEGER NEQ, INFO(N), IDID, LRW, LIW, IWORK(LIW), IPAR, NG, */
/*     *   JROOT(NG) */
/*      DOUBLE PRECISION T, Y(NEQ), YPRIME(NEQ), TOUT, RTOL, ATOL, */
/*     *   RWORK(LRW), RPAR */

/*      CALL DDASRT (RES, NEQ, T, Y, YPRIME, TOUT, INFO, RTOL, ATOL, */
/*     *   IDID, RWORK, LRW, IWORK, LIW, RPAR, IPAR, JAC) */



/* *Arguments: */

/*  RES:EXT  This is a subroutine which you provide to define the */
/*           differential/algebraic system. */

/*  NEQ:IN  This is the number of equations to be solved. */

/*  T:INOUT  This is the current value of the independent variable. */

/*  Y(*):INOUT  This array contains the solution components at T. */

/*  YPRIME(*):INOUT  This array contains the derivatives of the solution */
/*                   components at T. */

/*  TOUT:IN  This is a point at which a solution is desired. */

/*  INFO(N):IN  The basic task of the code is to solve the system from T */
/*              to TOUT and return an answer at TOUT.  INFO is an integer */
/*              array which is used to communicate exactly how you want */
/*              this task to be carried out.  N must be greater than or */
/*              equal to 15. */

/*  RTOL,ATOL:INOUT  These quantities represent absolute and relative */
/*                   error tolerances which you provide to indicate how */
/*                   accurately you wish the solution to be computed. */
/*                   You may choose them to be both scalars or else */
/*                   both vectors. */

/*  IDID:OUT  This scalar quantity is an indicator reporting what the */
/*            code did.  You must monitor this integer variable to decide */
/*            what action to take next. */

/*  RWORK:WORK  A real work array of length LRW which provides the */
/*               code with needed storage space. */

/*  LRW:IN  The length of RWORK. */

/*  IWORK:WORK  An integer work array of length LIW which probides the */
/*               code with needed storage space. */

/*  LIW:IN  The length of IWORK. */

/*  RPAR,IPAR:IN  These are real and integer parameter arrays which */
/*                you can use for communication between your calling */
/*                program and the RES subroutine (and the JAC subroutine) */

/*  JAC:EXT  This is the name of a subroutine which you may choose to */
/*           provide for defining a matrix of partial derivatives */
/*           described below. */

/*  G  This is the name of the subroutine for defining */
/*     constraint functions, G(T,Y), whose roots are desired */
/*     during the integration.  This name must be declared */
/*     external in the calling program. */

/*  NG  This is the number of constraint functions G(I). */
/*      If there are none, set NG=0, and pass a dummy name */
/*      for G. */

/*  JROOT  This is an integer array of length NG for output */
/*         of root information. */


/* *Description */

/*  QUANTITIES WHICH MAY BE ALTERED BY THE CODE ARE */
/*     T,Y(*),YPRIME(*),INFO(1),RTOL,ATOL, */
/*     IDID,RWORK(*) AND IWORK(*). */

/*  Subroutine DDASRT uses the backward differentiation formulas of */
/*  orders one through five to solve a system of the above form for Y and */
/*  YPRIME.  Values for Y and YPRIME at the initial time must be given as */
/*  input.  These values must be consistent, (that is, if T,Y,YPRIME are */
/*  the given initial values, they must satisfy F(T,Y,YPRIME) = 0.).  The */
/*  subroutine solves the system from T to TOUT. */
/*  It is easy to continue the solution to get results at additional */
/*  TOUT.  This is the interval mode of operation.  Intermediate results */
/*  can also be obtained easily by using the intermediate-output */
/*  capability.  If DDASRT detects a sign-change in G(T,Y), then */
/*  it will return the intermediate value of T and Y for which */
/*  G(T,Y) = 0. */

/*  ---------INPUT-WHAT TO DO ON THE FIRST CALL TO DDASRT--------------- */


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
/*             DELTA = F(T,Y,YPRIME) */
/*         (DELTA(*) is a vector of length NEQ which is */
/*         output for RES.) */

/*         Subroutine RES must not alter T,Y or YPRIME. */
/*         You must declare the name RES in an external */
/*         statement in your program that calls DDASRT. */
/*         You must dimension Y,YPRIME and DELTA in RES. */

/*         IRES is an integer flag which is always equal to */
/*         zero on input. Subroutine RES should alter IRES */
/*         only if it encounters an illegal value of Y or */
/*         a stop condition. Set IRES = -1 if an input value */
/*         is illegal, and DDASRT will try to solve the problem */
/*         without getting IRES = -1. If IRES = -2, DDASRT */
/*         will return control to the calling program */
/*         with IDID = -11. */

/*         RPAR and IPAR are real and integer parameter arrays which */
/*         you can use for communication between your calling program */
/*         and subroutine RES. They are not altered by DDASRT. If you */
/*         do not need RPAR or IPAR, ignore these parameters by treat- */
/*         ing them as dummy arguments. If you do choose to use them, */
/*         dimension them in your calling program and in RES as arrays */
/*         of appropriate length. */

/*  NEQ -- Set it to the number of differential equations. */
/*         (NEQ .GE. 1) */

/*  T -- Set it to the initial point of the integration. */
/*       T must be defined as a variable. */

/*  Y(*) -- Set this vector to the initial values of the NEQ solution */
/*          components at the initial point. You must dimension Y of */
/*          length at least NEQ in your calling program. */

/*  YPRIME(*) -- Set this vector to the initial values of */
/*               the NEQ first derivatives of the solution */
/*               components at the initial point. You */
/*               must dimension YPRIME at least NEQ */
/*               in your calling program. If you do not */
/*               know initial values of some of the solution */
/*               components, see the explanation of INFO(11). */

/*  TOUT - Set it to the first point at which a solution */
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

/*         the first step taken by the code is a critical one */
/*         because it must reflect how fast the solution changes near */
/*         the initial point. The code automatically selects an */
/*         initial step size which is practically always suitable for */
/*         the problem. By using the fact that the code will not step */
/*         past TOUT in the first step, you could, if necessary, */
/*         restrict the length of the initial step size. */

/*         For some problems it may not be permissable to integrate */
/*         past a point TSTOP because a discontinuity occurs there */
/*         or the solution or its derivative is not defined beyond */
/*         TSTOP. When you have declared a TSTOP point (SEE INFO(4) */
/*         and RWORK(1)), you have told the code not to integrate */
/*         past TSTOP. In this case any TOUT beyond TSTOP is invalid */
/*         input. */

/*  INFO(*) - Use the INFO array to give the code more details about */
/*            how you want your problem solved. This array should be */
/*            dimensioned of length 15, though DDASRT uses */
/*            only the first eleven entries. You must respond to all of */
/*            the following items which are arranged as questions. The */
/*            simplest use of the code corresponds to answering all */
/*            questions as yes, i.e. setting all entries of INFO to 0. */

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

/*       INFO(6) - DDASRT will perform much better if the matrix of */
/*              partial derivatives, DG/DY + CJ*DG/DYPRIME, */
/*              (here CJ is a scalar determined by DDASRT) */
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
/*              specifying an initial stepsize H0. */

/*          ****  Do you want the code to define */
/*                its own initial stepsize? */
/*                Yes - Set INFO(8)=0 */
/*                 No - Set INFO(8)=1 */
/*                      and define H0 by setting */
/*                      RWORK(3)=H0 **** */

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

/*        INFO(11) --DDASRT normally requires the initial T, */
/*               Y, and YPRIME to be consistent. That is, */
/*               you must have F(T,Y,YPRIME) = 0 at the initial */
/*               time. If you do not know the initial */
/*               derivative precisely, you can let DDASRT try */
/*               to compute it. */
/*          ****   Are the initial T, Y, YPRIME consistent? */
/*                 Yes - Set INFO(11) = 0 */
/*                  No - Set INFO(11) = 1, */
/*                       and set YPRIME to an initial approximation */
/*                       to YPRIME.  (If you have no idea what */
/*                       YPRIME should be, set it to zero. Note */
/*                       that the initial Y should be such */
/*                       that there must exist a YPRIME so that */
/*                       F(T,Y,YPRIME) = 0.) */

/*   RTOL, ATOL -- You must assign relative (RTOL) and absolute (ATOL */
/*               error tolerances to tell the code how accurately you */
/*               want the solution to be computed. They must be defined */
/*               as variables because the code may change them. You */
/*               have two choices -- */
/*                     Both RTOL and ATOL are scalars. (INFO(2)=0) */
/*                     Both RTOL and ATOL are vectors. (INFO(2)=1) */
/*               in either case all components must be non-negative. */

/*               The tolerances are used by the code in a local error */
/*               test at each step which requires roughly that */
/*                     ABS(LOCAL ERROR) .LE. RTOL*ABS(Y)+ATOL */
/*               for each vector component. */
/*               (More specifically, a root-mean-square norm is used to */
/*               measure the size of vectors, and the error test uses the */
/*               magnitude of the solution at the beginning of the step.) */

/*               The true (global) error is the difference between the */
/*               true solution of the initial value problem and the */
/*               computed approximation. Practically all present day */
/*               codes, including this one, control the local error at */
/*               each step and do not even attempt to control the global */
/*               error directly. */
/*               Usually, but not always, the true accuracy of the */
/*               computed Y is comparable to the error tolerances. This */
/*               code will usually, but not always, deliver a more */
/*               accurate solution if you reduce the tolerances and */
/*               integrate again. By comparing two such solutions you */
/*               can get a fairly reliable idea of the true error in the */
/*               solution at the bigger tolerances. */

/*               Setting ATOL=0. results in a pure relative error test on */
/*               that component. Setting RTOL=0. results in a pure */
/*               absolute error test on that component. A mixed test */
/*               with non-zero RTOL and ATOL corresponds roughly to a */
/*               relative error test when the solution component is much */
/*               bigger than ATOL and to an absolute error test when the */
/*               solution component is smaller than the threshhold ATOL. */

/*               The code will not attempt to compute a solution at an */
/*               accuracy unreasonable for the machine being used. It */
/*               will advise you if you ask for too much accuracy and */
/*               inform you as to the maximum accuracy it believes */
/*               possible. */

/*  RWORK(*) --  Dimension this real work array of length LRW in your */
/*               calling program. */

/*  LRW -- Set it to the declared length of the RWORK array. */
/*               You must have */
/*                    LRW .GE. 50+(MAXORD+4)*NEQ+NEQ**2+3*NG */
/*               for the full (dense) JACOBIAN case (when INFO(6)=0), or */
/*                    LRW .GE. 50+(MAXORD+4)*NEQ+(2*ML+MU+1)*NEQ+3*NG */
/*               for the banded user-defined JACOBIAN case */
/*               (when INFO(5)=1 and INFO(6)=1), or */
/*                     LRW .GE. 50+(MAXORD+4)*NEQ+(2*ML+MU+1)*NEQ */
/*                           +2*(NEQ/(ML+MU+1)+1)+3*NG */
/*               for the banded finite-difference-generated JACOBIAN case */
/*               (when INFO(5)=0 and INFO(6)=1) */

/*  IWORK(*) --  Dimension this integer work array of length LIW in */
/*               your calling program. */

/*  LIW -- Set it to the declared length of the IWORK array. */
/*               you must have LIW .GE. 20+NEQ */

/*  RPAR, IPAR -- These are parameter arrays, of real and integer */
/*               type, respectively. You can use them for communication */
/*               between your program that calls DDASRT and the */
/*               RES subroutine (and the JAC subroutine). They are not */
/*               altered by DDASRT. If you do not need RPAR or IPAR, */
/*               ignore these parameters by treating them as dummy */
/*               arguments. If you do choose to use them, dimension */
/*               them in your calling program and in RES (and in JAC) */
/*               as arrays of appropriate length. */

/*  JAC -- If you have set INFO(5)=0, you can ignore this parameter */
/*               by treating it as a dummy argument. Otherwise, you must */
/*               provide a subroutine of the form */
/*               JAC(T,Y,YPRIME,PD,CJ,RPAR,IPAR) */
/*               to define the matrix of partial derivatives */
/*               PD=DG/DY+CJ*DG/DYPRIME */
/*               CJ is a scalar which is input to JAC. */
/*               For the given values of T,Y,YPRIME, the */
/*               subroutine must evaluate the non-zero partial */
/*               derivatives for each equation and each solution */
/*               component, and store these values in the */
/*               matrix PD. The elements of PD are set to zero */
/*               before each call to JAC so only non-zero elements */
/*               need to be defined. */

/*               Subroutine JAC must not alter T,Y,(*),YPRIME(*), or CJ. */
/*               You must declare the name JAC in an */
/*               EXTERNAL STATEMENT in your program that calls */
/*               DDASRT. You must dimension Y, YPRIME and PD */
/*               in JAC. */

/*               The way you must store the elements into the PD matrix */
/*               depends on the structure of the matrix which you */
/*               indicated by INFO(6). */
/*               *** INFO(6)=0 -- Full (dense) matrix *** */
/*                   Give PD a first dimension of NEQ. */
/*                   When you evaluate the (non-zero) partial derivative */
/*                   of equation I with respect to variable J, you must */
/*                   store it in PD according to */
/*                   PD(I,J) = * DF(I)/DY(J)+CJ*DF(I)/DYPRIME(J)* */
/*               *** INFO(6)=1 -- Banded JACOBIAN with ML lower and MU */
/*                   upper diagonal bands (refer to INFO(6) description */
/*                   of ML and MU) *** */
/*                   Give PD a first dimension of 2*ML+MU+1. */
/*                   when you evaluate the (non-zero) partial derivative */
/*                   of equation I with respect to variable J, you must */
/*                   store it in PD according to */
/*                   IROW = I - J + ML + MU + 1 */
/*                   PD(IROW,J) = *DF(I)/DY(J)+CJ*DF(I)/DYPRIME(J)* */
/*               RPAR and IPAR are real and integer parameter arrays */
/*               which you can use for communication between your calling */
/*               program and your JACOBIAN subroutine JAC. They are not */
/*               altered by DDASRT. If you do not need RPAR or IPAR, */
/*               ignore these parameters by treating them as dummy */
/*               arguments. If you do choose to use them, dimension */
/*               them in your calling program and in JAC as arrays of */
/*               appropriate length. */

/*  G -- This is the name of the subroutine for defining constraint */
/*               functions, whose roots are desired during the */
/*               integration.  It is to have the form */
/*                   SUBROUTINE G(NEQ,T,Y,NG,GOUT,RPAR,IPAR) */
/*                   DIMENSION Y(NEQ),GOUT(NG), */
/*               where NEQ, T, Y and NG are INPUT, and the array GOUT is */
/*               output.  NEQ, T, and Y have the same meaning as in the */
/*               RES routine, and GOUT is an array of length NG. */
/*               For I=1,...,NG, this routine is to load into GOUT(I) */
/*               the value at (T,Y) of the I-th constraint function G(I). */
/*               DDASRT will find roots of the G(I) of odd multiplicity */
/*               (that is, sign changes) as they occur during */
/*               the integration.  G must be declared EXTERNAL in the */
/*               calling program. */

/*               CAUTION..because of numerical errors in the functions */
/*               G(I) due to roundoff and integration error, DDASRT */
/*               may return false roots, or return the same root at two */
/*               or more nearly equal values of T.  If such false roots */
/*               are suspected, the user should consider smaller error */
/*               tolerances and/or higher precision in the evaluation of */
/*               the G(I). */

/*               If a root of some G(I) defines the end of the problem, */
/*               the input to DDASRT should nevertheless allow */
/*               integration to a point slightly past that ROOT, so */
/*               that DDASRT can locate the root by interpolation. */

/*  NG -- The number of constraint functions G(I).  If there are none, */
/*               set NG = 0, and pass a dummy name for G. */

/* JROOT -- This is an integer array of length NG.  It is used only for */
/*               output.  On a return where one or more roots have been */
/*               found, JROOT(I)=1 If G(I) has a root at T, */
/*               or JROOT(I)=0 if not. */



/*  OPTIONALLY REPLACEABLE NORM ROUTINE: */
/*  DDASRT uses a weighted norm DDANRM to measure the size */
/*  of vectors such as the estimated error in each step. */
/*  A FUNCTION subprogram */
/*    DOUBLE PRECISION FUNCTION DDANRM(NEQ,V,WT,RPAR,IPAR) */
/*    DIMENSION V(NEQ),WT(NEQ) */
/*  is used to define this norm. Here, V is the vector */
/*  whose norm is to be computed, and WT is a vector of */
/*  weights.  A DDANRM routine has been included with DDASRT */
/*  which computes the weighted root-mean-square norm */
/*  given by */
/*    DDANRM=SQRT((1/NEQ)*SUM(V(I)/WT(I))**2) */
/*  this norm is suitable for most problems. In some */
/*  special cases, it may be more convenient and/or */
/*  efficient to define your own norm by writing a function */
/*  subprogram to be called instead of DDANRM. This should */
/*  ,however, be attempted only after careful thought and */
/*  consideration. */


/* ------OUTPUT-AFTER ANY RETURN FROM DDASRT---- */

/*  The principal aim of the code is to return a computed solution at */
/*  TOUT, although it is also possible to obtain intermediate results */
/*  along the way. To find out whether the code achieved its goal */
/*  or if the integration process was interrupted before the task was */
/*  completed, you must check the IDID parameter. */


/*   T -- The solution was successfully advanced to the */
/*               output value of T. */

/*   Y(*) -- Contains the computed solution approximation at T. */

/*   YPRIME(*) -- Contains the computed derivative */
/*               approximation at T. */

/*   IDID -- Reports what the code did. */

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

/*           IDID = 4 -- The integration was successfully completed */
/*                   by finding one or more roots of G at T. */

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

/*           IDID = -6 -- DDASRT had repeated error test */
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

/*           IDID =-12 -- DDASRT failed to compute the initial */
/*                   YPRIME. */



/*           IDID = -13,..,-32 -- Not applicable for this code */

/*                    *** Task terminated *** */
/*                Reported by the value of IDID=-33 */

/*           IDID = -33 -- The code has encountered trouble from which */
/*                   it cannot recover. A message is printed */
/*                   explaining the trouble and control is returned */
/*                   to the calling program. For example, this occurs */
/*                   when invalid input is detected. */

/*   RTOL, ATOL -- These quantities remain unchanged except when */
/*               IDID = -2. In this case, the error tolerances have been */
/*               increased by the code to values which are estimated to */
/*               be appropriate for continuing the integration. However, */
/*               the reported solution at T was obtained using the input */
/*               values of RTOL and ATOL. */

/*   RWORK, IWORK -- Contain information which is usually of no */
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

/*               IWORK(16)--Which contains the total number of calls */
/*                        to the constraint function g so far */



/*   INPUT -- What to do to continue the integration */
/*            (calls after the first)                ** */

/*     This code is organized so that subsequent calls to continue the */
/*     integration involve little (if any) additional effort on your */
/*     part. You must monitor the IDID parameter in order to determine */
/*     what to do next. */

/*     Recalling that the principal task of the code is to integrate */
/*     from T to TOUT (the interval mode), usually all you will need */
/*     to do is specify a new TOUT upon reaching the current TOUT. */

/*     Do not alter any quantity not specifically permitted below, */
/*     in particular do not alter NEQ,T,Y(*),YPRIME(*),RWORK(*),IWORK(*) */
/*     or the differential equation in subroutine RES. Any such */
/*     alteration constitutes a new problem and must be treated as such, */
/*     i.e., you must start afresh. */

/*     You cannot change from vector to scalar error control or vice */
/*     versa (INFO(2)), but you can change the size of the entries of */
/*     RTOL, ATOL. Increasing a tolerance makes the equation easier */
/*     to integrate. Decreasing a tolerance will make the equation */
/*     harder to integrate and should generally be avoided. */

/*     You can switch from the intermediate-output mode to the */
/*     interval mode (INFO(3)) or vice versa at any time. */

/*     If it has been necessary to prevent the integration from going */
/*     past a point TSTOP (INFO(4), RWORK(1)), keep in mind that the */
/*     code will not integrate to any TOUT beyond the currently */
/*     specified TSTOP. Once TSTOP has been reached you must change */
/*     the value of TSTOP or set INFO(4)=0. You may change INFO(4) */
/*     or TSTOP at any time but you must supply the value of TSTOP in */
/*     RWORK(1) whenever you set INFO(4)=1. */

/*     Do not change INFO(5), INFO(6), IWORK(1), or IWORK(2) */
/*     unless you are going to restart the code. */

/*                    *** Following a completed task *** */
/*     If */
/*     IDID = 1, call the code again to continue the integration */
/*                  another step in the direction of TOUT. */

/*     IDID = 2 or 3, define a new TOUT and call the code again. */
/*                  TOUT must be different from T. You cannot change */
/*                  the direction of integration without restarting. */

/*     IDID = 4, call the code again to continue the integration */
/*                  another step in the direction of TOUT.  You may */
/*                  change the functions in G after a return with IDID=4, */
/*                  but the number of constraint functions NG must remain */
/*                  the same.  If you wish to change */
/*                  the functions in RES or in G, then you */
/*                  must restart the code. */

/*                    *** Following an interrupted task *** */
/*                  To show the code that you realize the task was */
/*                  interrupted and that you want to continue, you */
/*                  must take appropriate action and set INFO(1) = 1 */
/*     If */
/*     IDID = -1, The code has taken about 500 steps. */
/*                  If you want to continue, set INFO(1) = 1 and */
/*                  call the code again. An additional 500 steps */
/*                  will be allowed. */

/*     IDID = -2, The error tolerances RTOL, ATOL have been */
/*                  increased to values the code estimates appropriate */
/*                  for continuing. You may want to change them */
/*                  yourself. If you are sure you want to continue */
/*                  with relaxed error tolerances, set INFO(1)=1 and */
/*                  call the code again. */

/*     IDID = -3, A solution component is zero and you set the */
/*                  corresponding component of ATOL to zero. If you */
/*                  are sure you want to continue, you must first */
/*                  alter the error criterion to use positive values */
/*                  for those components of ATOL corresponding to zero */
/*                  solution components, then set INFO(1)=1 and call */
/*                  the code again. */

/*     IDID = -4,-5  --- Cannot occur with this code. */

/*     IDID = -6, Repeated error test failures occurred on the */
/*                  last attempted step in DDASRT. A singularity in the */
/*                  solution may be present. If you are absolutely */
/*                  certain you want to continue, you should restart */
/*                  the integration. (Provide initial values of Y and */
/*                  YPRIME which are consistent) */

/*     IDID = -7, Repeated convergence test failures occurred */
/*                  on the last attempted step in DDASRT. An inaccurate */
/*                  or ill-conditioned JACOBIAN may be the problem. If */
/*                  you are absolutely certain you want to continue, you */
/*                  should restart the integration. */

/*     IDID = -8, The matrix of partial derivatives is singular. */
/*                  Some of your equations may be redundant. */
/*                  DDASRT cannot solve the problem as stated. */
/*                  It is possible that the redundant equations */
/*                  could be removed, and then DDASRT could */
/*                  solve the problem. It is also possible */
/*                  that a solution to your problem either */
/*                  does not exist or is not unique. */

/*     IDID = -9, DDASRT had multiple convergence test */
/*                  failures, preceeded by multiple error */
/*                  test failures, on the last attempted step. */
/*                  It is possible that your problem */
/*                  is ill-posed, and cannot be solved */
/*                  using this code. Or, there may be a */
/*                  discontinuity or a singularity in the */
/*                  solution. If you are absolutely certain */
/*                  you want to continue, you should restart */
/*                  the integration. */

/*    IDID =-10, DDASRT had multiple convergence test failures */
/*                  because IRES was equal to minus one. */
/*                  If you are absolutely certain you want */
/*                  to continue, you should restart the */
/*                  integration. */

/*    IDID =-11, IRES=-2 was encountered, and control is being */
/*                  returned to the calling program. */

/*    IDID =-12, DDASRT failed to compute the initial YPRIME. */
/*               This could happen because the initial */
/*               approximation to YPRIME was not very good, or */
/*               if a YPRIME consistent with the initial Y */
/*               does not exist. The problem could also be caused */
/*               by an inaccurate or singular iteration matrix. */



/*     IDID = -13,..,-32 --- Cannot occur with this code. */

/*                       *** Following a terminated task *** */
/*     If IDID= -33, you cannot continue the solution of this */
/*                  problem. An attempt to do so will result in your */
/*                  run being terminated. */

/*  --------------------------------------------------------------------- */

/* ***REFERENCE */
/*      K. E. Brenan, S. L. Campbell, and L. R. Petzold, Numerical */
/*      Solution of Initial-Value Problems in Differential-Algebraic */
/*      Equations, Elsevier, New York, 1989. */

/* ***ROUTINES CALLED  DDASTP,DDAINI,DDANRM,DDAWTS,DDATRP,DRCHEK,DROOTS, */
/*                    XERRWV,D1MACH */
/* ***END PROLOGUE  DDASRT */

/* **End */


/*     SET POINTERS INTO IWORK */

/*     SET RELATIVE OFFSET INTO RWORK */

/*     SET POINTERS INTO RWORK */

/* ***FIRST EXECUTABLE STATEMENT  DDASRT */
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
    lenrw = (iwork[3] + 4) * *neq + 50 + lenpd;
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
    lenrw = (iwork[3] + 4) * *neq + 50 + lenpd + (msave << 1);
    goto L60;
L50:
    iwork[4] = 4;
    lenrw = (iwork[3] + 4) * *neq + 50 + lenpd;

/*     CHECK LENGTHS OF RWORK AND IWORK */
L60:
    leniw = *neq + 20;
    iwork[17] = lenpd;
    if (*lrw < lenrw) {
	goto L704;
    }
    if (*liw < leniw) {
	goto L705;
    }

/*     CHECK TO SEE THAT TOUT IS DIFFERENT FROM T */
/*     Also check to see that NG is larger than 0. */
    if (*tout == *t) {
	goto L719;
    }
    if (*ng < 0) {
	goto L730;
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
    iwork[16] = 0;

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
    s_copy(msg, "DASSL--  THE LAST STEP TERMINATED WITH A NEGATIVE", (ftnlen)
	    80, (ftnlen)49);
    xerrwv_(msg, &c__49, &c__201, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    s_copy(msg, "DASSL--  VALUE (=I1) OF IDID AND NO APPROPRIATE", (ftnlen)80,
	     (ftnlen)47);
    xerrwv_(msg, &c__47, &c__202, &c__0, &c__1, idid, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    s_copy(msg, "DASSL--  ACTION WAS TAKEN. RUN TERMINATED", (ftnlen)80, (
	    ftnlen)41);
    xerrwv_(msg, &c__41, &c__203, &c__1, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
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
    lg0 = *neq + 51;
    lg1 = lg0 + *ng;
    lgx = lg1 + *ng;
    le = lgx + *ng;
    lwt = le + *neq;
    lphi = lwt + *neq;
    lpd = lphi + (iwork[3] + 1) * *neq;
    lwm = lpd;
    ntemp = iwork[17] + 1;
    if (info[1] == 1) {
	goto L400;
    }

/* ----------------------------------------------------------------------- */
/*     THIS BLOCK IS EXECUTED ON THE INITIAL CALL */
/*     ONLY. SET THE INITIAL STEP SIZE, AND */
/*     THE ERROR WEIGHT VECTOR, AND PHI. */
/*     COMPUTE INITIAL YPRIME, IF NECESSARY. */
/* ----------------------------------------------------------------------- */

/* L300: */
    tn = *t;
    *idid = 1;

/*     SET ERROR WEIGHT VECTOR WT */
    ddawts_(neq, &info[2], &rtol[1], &atol[1], &y[1], &rwork[lwt], &rpar[1], &
	    ipar[1]);
/*      if(iero.gt.0) return */
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if (rwork[lwt + i__ - 1] <= 0.) {
	    goto L713;
	}
/* L305: */
    }

/*     COMPUTE UNIT ROUNDOFF AND HMIN */
    uround = dlamch_("P", (ftnlen)1);
    rwork[9] = uround;
/* Computing MAX */
    d__1 = abs(*t), d__2 = abs(*tout);
    hmin = uround * 4. * max(d__1,d__2);

/*     CHECK INITIAL INTERVAL TO SEE THAT IT IS LONG ENOUGH */
    tdist = (d__1 = *tout - *t, abs(d__1));
    if (tdist < hmin) {
	goto L714;
    }

/*     CHECK H0, IF THIS WAS INPUT */
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
	    lwt], idid, &rpar[1], &ipar[1], &rwork[lphi], &rwork[51], &rwork[
	    le], &rwork[lwm], &iwork[1], &hmin, &rwork[9], &info[10], &ntemp);
    if (ierode_1.iero > 0) {
	return 0;
    }
    if (*idid < 0) {
	goto L390;
    }

/*     LOAD H WITH H0.  STORE H IN RWORK(LH) */
L350:
    h__ = ho;
    rwork[3] = h__;

/*     LOAD Y AND H*YPRIME INTO PHI(*,1) AND PHI(*,2) */
/* L360: */
    itemp = lphi + *neq;
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
	rwork[lphi + i__ - 1] = y[i__];
/* L370: */
	rwork[itemp + i__ - 1] = h__ * yprime[i__];
    }

/*     INITIALIZE T0 IN RWORK AND CHECK FOR A ZERO OF G NEAR THE */
/*     INITIAL T. */

    rwork[41] = *t;
    iwork[18] = 0;
    rwork[29] = h__;
    rwork[30] = h__ * 2.;
    iwork[8] = 1;
    if (*ng == 0) {
	goto L390;
    }
    drchek_(&c__1, (U_fp)g, ng, neq, t, tout, &y[1], &rwork[le], &rwork[lphi],
	     &rwork[29], &iwork[8], &rwork[lg0], &rwork[lg1], &rwork[lgx], 
	    jroot, &irt, &rwork[9], &info[3], &rwork[1], &iwork[1], &rpar[1], 
	    &ipar[1]);
    if (ierode_1.iero > 0) {
	return 0;
    }
    if (irt != 0) {
	goto L732;
    }

/*     Check for a root in the interval (T0,TN], unless DDASRT */
/*     did not have to initialize YPRIME. */

    if (*ng == 0 || info[11] == 0) {
	goto L390;
    }
    drchek_(&c__3, (U_fp)g, ng, neq, &tn, tout, &y[1], &rwork[le], &rwork[
	    lphi], &rwork[29], &iwork[8], &rwork[lg0], &rwork[lg1], &rwork[
	    lgx], jroot, &irt, &rwork[9], &info[3], &rwork[1], &iwork[1], &
	    rpar[1], &ipar[1]);
    if (ierode_1.iero > 0) {
	return 0;
    }
    if (irt != 1) {
	goto L390;
    }
    iwork[18] = 1;
    *idid = 4;
    *t = rwork[41];
/* *SS* 1997 next line added to return current value of yprime */
    dcopy_(neq, &rwork[le], &c__1, &yprime[1], &c__1);
    goto L580;

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
    if (*ng == 0) {
	goto L405;
    }

/*     Check for a zero of G near TN. */

    drchek_(&c__2, (U_fp)g, ng, neq, &tn, tout, &y[1], &rwork[le], &rwork[
	    lphi], &rwork[29], &iwork[8], &rwork[lg0], &rwork[lg1], &rwork[
	    lgx], jroot, &irt, &rwork[9], &info[3], &rwork[1], &iwork[1], &
	    rpar[1], &ipar[1]);
    if (ierode_1.iero > 0) {
	return 0;
    }
    if (irt != 1) {
	goto L405;
    }
    iwork[18] = 1;
    *idid = 4;
    *t = rwork[41];
/* *SS* 1997 next line added to return current value of yprime */
    dcopy_(neq, &rwork[le], &c__1, &yprime[1], &c__1);
    done = TRUE_;
    goto L490;

L405:
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
    if (ierode_1.iero > 0) {
	return 0;
    }
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
    if (ierode_1.iero > 0) {
	return 0;
    }
    *t = tn;
    *idid = 1;
    done = TRUE_;
    goto L490;
L425:
    ddatrp_(&tn, tout, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    if (ierode_1.iero > 0) {
	return 0;
    }
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
    if (ierode_1.iero > 0) {
	return 0;
    }
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
    if (ierode_1.iero > 0) {
	return 0;
    }
    *t = tn;
    *idid = 1;
    done = TRUE_;
    goto L490;
L445:
    ddatrp_(&tn, tout, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    if (ierode_1.iero > 0) {
	return 0;
    }
    *t = *tout;
    *idid = 3;
    done = TRUE_;
    goto L490;
L450:
/*     CHECK WHETHER WE ARE WITH IN ROUNDOFF OF TSTOP */
    if ((d__1 = tn - tstop, abs(d__1)) > uround * 100. * (abs(tn) + abs(h__)))
	     {
	goto L460;
    }
    ddatrp_(&tn, &tstop, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    if (ierode_1.iero > 0) {
	return 0;
    }
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
	goto L590;
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
    if (ierode_1.iero > 0) {
	return 0;
    }
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
	    lwt], &info[1], idid, &rpar[1], &ipar[1], &rwork[lphi], &rwork[51]
	    , &rwork[le], &rwork[lwm], &iwork[1], &rwork[11], &rwork[17], &
	    rwork[23], &rwork[29], &rwork[35], &rwork[5], &rwork[6], &rwork[7]
	    , &rwork[8], &hmin, &rwork[9], &iwork[6], &iwork[5], &iwork[7], &
	    iwork[8], &iwork[9], &info[10], &ntemp);
    if (ierode_1.iero > 0) {
	return 0;
    }
L527:
    if (*idid < 0) {
	goto L600;
    }

/* -------------------------------------------------------- */
/*     THIS BLOCK HANDLES THE CASE OF A SUCCESSFUL RETURN */
/*     FROM DDASTP (IDID=1).  TEST FOR STOP CONDITIONS. */
/* -------------------------------------------------------- */

    if (*ng == 0) {
	goto L529;
    }

/*     Check for a zero of G near TN. */

    drchek_(&c__3, (U_fp)g, ng, neq, &tn, tout, &y[1], &rwork[le], &rwork[
	    lphi], &rwork[29], &iwork[8], &rwork[lg0], &rwork[lg1], &rwork[
	    lgx], jroot, &irt, &rwork[9], &info[3], &rwork[1], &iwork[1], &
	    rpar[1], &ipar[1]);
    if (ierode_1.iero > 0) {
	return 0;
    }
    if (irt != 1) {
	goto L529;
    }
    iwork[18] = 1;
    *idid = 4;
    *t = rwork[41];
/* *SS* 1997 next line added to return current value of yprime */
    dcopy_(neq, &rwork[le], &c__1, &yprime[1], &c__1);
    goto L580;

L529:
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
    if (ierode_1.iero > 0) {
	return 0;
    }
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
    if (ierode_1.iero > 0) {
	return 0;
    }
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
    if (ierode_1.iero > 0) {
	return 0;
    }
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
    if (ierode_1.iero > 0) {
	return 0;
    }
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
    if (ierode_1.iero > 0) {
	return 0;
    }
    *idid = 2;
    *t = tstop;
    goto L580;
L555:
    ddatrp_(&tn, tout, &y[1], &yprime[1], neq, &iwork[8], &rwork[lphi], &
	    rwork[29]);
    if (ierode_1.iero > 0) {
	return 0;
    }
    *t = *tout;
    *idid = 3;
L580:

/* -------------------------------------------------------- */
/*     ALL SUCCESSFUL RETURNS FROM DDASRT ARE MADE FROM */
/*     THIS BLOCK. */
/* -------------------------------------------------------- */

L590:
    rwork[4] = tn;
    rwork[3] = h__;
    rwork[42] = *t;
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
    s_copy(msg, "DASSL--  AT CURRENT T (=R1)  500 STEPS", (ftnlen)80, (ftnlen)
	    38);
    xerrwv_(msg, &c__38, &c__610, &c__0, &c__0, &c__0, &c__0, &c__1, &tn, &
	    c_b30, (ftnlen)80);
    s_copy(msg, "DASSL--  TAKEN ON THIS CALL BEFORE REACHING TOUT", (ftnlen)
	    80, (ftnlen)48);
    xerrwv_(msg, &c__48, &c__611, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L690;

/*     TOO MUCH ACCURACY FOR MACHINE PRECISION */
L620:
    s_copy(msg, "DASSL--  AT T (=R1) TOO MUCH ACCURACY REQUESTED", (ftnlen)80,
	     (ftnlen)47);
    xerrwv_(msg, &c__47, &c__620, &c__0, &c__0, &c__0, &c__0, &c__1, &tn, &
	    c_b30, (ftnlen)80);
    s_copy(msg, "DASSL--  FOR PRECISION OF MACHINE. RTOL AND ATOL", (ftnlen)
	    80, (ftnlen)48);
    xerrwv_(msg, &c__48, &c__621, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    s_copy(msg, "DASSL--  WERE INCREASED TO APPROPRIATE VALUES", (ftnlen)80, (
	    ftnlen)45);
    xerrwv_(msg, &c__45, &c__622, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);

    goto L690;
/*     WT(I) .LE. 0.0D0 FOR SOME I (NOT AT START OF PROBLEM) */
L630:
    s_copy(msg, "DASSL--  AT T (=R1) SOME ELEMENT OF WT", (ftnlen)80, (ftnlen)
	    38);
    xerrwv_(msg, &c__38, &c__630, &c__0, &c__0, &c__0, &c__0, &c__1, &tn, &
	    c_b30, (ftnlen)80);
    s_copy(msg, "DASSL--  HAS BECOME .LE. 0.0", (ftnlen)80, (ftnlen)28);
    xerrwv_(msg, &c__28, &c__631, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L690;

/*     ERROR TEST FAILED REPEATEDLY OR WITH H=HMIN */
L640:
    s_copy(msg, "DASSL--  AT T (=R1) AND STEPSIZE H (=R2) THE", (ftnlen)80, (
	    ftnlen)44);
    xerrwv_(msg, &c__44, &c__640, &c__0, &c__0, &c__0, &c__0, &c__2, &tn, &
	    h__, (ftnlen)80);
    s_copy(msg, "DASSL--  ERROR TEST FAILED REPEATEDLY OR WITH ABS(H)=HMIN", (
	    ftnlen)80, (ftnlen)57);
    xerrwv_(msg, &c__57, &c__641, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L690;

/*     CORRECTOR CONVERGENCE FAILED REPEATEDLY OR WITH H=HMIN */
L650:
    s_copy(msg, "DASSL--  AT T (=R1) AND STEPSIZE H (=R2) THE", (ftnlen)80, (
	    ftnlen)44);
    xerrwv_(msg, &c__44, &c__650, &c__0, &c__0, &c__0, &c__0, &c__2, &tn, &
	    h__, (ftnlen)80);
    s_copy(msg, "DASSL--  CORRECTOR FAILED TO CONVERGE REPEATEDLY", (ftnlen)
	    80, (ftnlen)48);
    xerrwv_(msg, &c__48, &c__651, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    s_copy(msg, "DASSL--  OR WITH ABS(H)=HMIN", (ftnlen)80, (ftnlen)28);
    xerrwv_(msg, &c__28, &c__652, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L690;

/*     THE ITERATION MATRIX IS SINGULAR */
L660:
    s_copy(msg, "DASSL--  AT T (=R1) AND STEPSIZE H (=R2) THE", (ftnlen)80, (
	    ftnlen)44);
    xerrwv_(msg, &c__44, &c__660, &c__0, &c__0, &c__0, &c__0, &c__2, &tn, &
	    h__, (ftnlen)80);
    s_copy(msg, "DASSL--  ITERATION MATRIX IS SINGULAR", (ftnlen)80, (ftnlen)
	    37);
    xerrwv_(msg, &c__37, &c__661, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L690;

/*     CORRECTOR FAILURE PRECEEDED BY ERROR TEST FAILURES. */
L670:
    s_copy(msg, "DASSL--  AT T (=R1) AND STEPSIZE H (=R2) THE", (ftnlen)80, (
	    ftnlen)44);
    xerrwv_(msg, &c__44, &c__670, &c__0, &c__0, &c__0, &c__0, &c__2, &tn, &
	    h__, (ftnlen)80);
    s_copy(msg, "DASSL--  CORRECTOR COULD NOT CONVERGE.  ALSO, THE", (ftnlen)
	    80, (ftnlen)49);
    xerrwv_(msg, &c__49, &c__671, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    s_copy(msg, "DASSL--  ERROR TEST FAILED REPEATEDLY.", (ftnlen)80, (ftnlen)
	    38);
    xerrwv_(msg, &c__38, &c__672, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L690;

/*     CORRECTOR FAILURE BECAUSE IRES = -1 */
L675:
    s_copy(msg, "DASSL--  AT T (=R1) AND STEPSIZE H (=R2) THE", (ftnlen)80, (
	    ftnlen)44);
    xerrwv_(msg, &c__44, &c__675, &c__0, &c__0, &c__0, &c__0, &c__2, &tn, &
	    h__, (ftnlen)80);
    s_copy(msg, "DASSL--  CORRECTOR COULD NOT CONVERGE BECAUSE", (ftnlen)80, (
	    ftnlen)45);
    xerrwv_(msg, &c__45, &c__676, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    s_copy(msg, "DASSL--  IRES WAS EQUAL TO MINUS ONE", (ftnlen)80, (ftnlen)
	    36);
    xerrwv_(msg, &c__36, &c__677, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L690;

/*     FAILURE BECAUSE IRES = -2 */
L680:
    s_copy(msg, "DASSL--  AT T (=R1) AND STEPSIZE H (=R2)", (ftnlen)80, (
	    ftnlen)40);
    xerrwv_(msg, &c__40, &c__680, &c__0, &c__0, &c__0, &c__0, &c__2, &tn, &
	    h__, (ftnlen)80);
    s_copy(msg, "DASSL--  IRES WAS EQUAL TO MINUS TWO", (ftnlen)80, (ftnlen)
	    36);
    xerrwv_(msg, &c__36, &c__681, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L690;

/*     FAILED TO COMPUTE INITIAL YPRIME */
L685:
    s_copy(msg, "DASSL--  AT T (=R1) AND STEPSIZE H (=R2) THE", (ftnlen)80, (
	    ftnlen)44);
    xerrwv_(msg, &c__44, &c__685, &c__0, &c__0, &c__0, &c__0, &c__2, &tn, &ho,
	     (ftnlen)80);
    s_copy(msg, "DASSL--  INITIAL YPRIME COULD NOT BE COMPUTED", (ftnlen)80, (
	    ftnlen)45);
    xerrwv_(msg, &c__45, &c__686, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
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
    s_copy(msg, "DASSL--  SOME ELEMENT OF INFO VECTOR IS NOT ZERO OR ONE", (
	    ftnlen)80, (ftnlen)55);
    xerrwv_(msg, &c__55, &c__1, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L750;
L702:
    s_copy(msg, "DASSL--  NEQ (=I1) .LE. 0", (ftnlen)80, (ftnlen)25);
    xerrwv_(msg, &c__25, &c__2, &c__0, &c__1, neq, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L750;
L703:
    s_copy(msg, "DASSL--  MAXORD (=I1) NOT IN RANGE", (ftnlen)80, (ftnlen)34);
    xerrwv_(msg, &c__34, &c__3, &c__0, &c__1, &mxord, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L750;
L704:
    s_copy(msg, "DASSL--  RWORK LENGTH NEEDED, LENRW (=I1), EXCEEDS LRW (=I2)"
	    , (ftnlen)80, (ftnlen)60);
    xerrwv_(msg, &c__60, &c__4, &c__0, &c__2, &lenrw, lrw, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L750;
L705:
    s_copy(msg, "DASSL--  IWORK LENGTH NEEDED, LENIW (=I1), EXCEEDS LIW (=I2)"
	    , (ftnlen)80, (ftnlen)60);
    xerrwv_(msg, &c__60, &c__5, &c__0, &c__2, &leniw, liw, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L750;
L706:
    s_copy(msg, "DASSL--  SOME ELEMENT OF RTOL IS .LT. 0", (ftnlen)80, (
	    ftnlen)39);
    xerrwv_(msg, &c__39, &c__6, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L750;
L707:
    s_copy(msg, "DASSL--  SOME ELEMENT OF ATOL IS .LT. 0", (ftnlen)80, (
	    ftnlen)39);
    xerrwv_(msg, &c__39, &c__7, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L750;
L708:
    s_copy(msg, "DASSL--  ALL ELEMENTS OF RTOL AND ATOL ARE ZERO", (ftnlen)80,
	     (ftnlen)47);
    xerrwv_(msg, &c__47, &c__8, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L750;
L709:
    s_copy(msg, "DASSL--  INFO(4) = 1 AND TSTOP (=R1) BEHIND TOUT (=R2)", (
	    ftnlen)80, (ftnlen)54);
    xerrwv_(msg, &c__54, &c__9, &c__0, &c__0, &c__0, &c__0, &c__2, &tstop, 
	    tout, (ftnlen)80);
    goto L750;
L710:
    s_copy(msg, "DASSL--  HMAX (=R1) .LT. 0.0", (ftnlen)80, (ftnlen)28);
    xerrwv_(msg, &c__28, &c__10, &c__0, &c__0, &c__0, &c__0, &c__1, &hmax, &
	    c_b30, (ftnlen)80);
    goto L750;
L711:
    s_copy(msg, "DASSL--  TOUT (=R1) BEHIND T (=R2)", (ftnlen)80, (ftnlen)34);
    xerrwv_(msg, &c__34, &c__11, &c__0, &c__0, &c__0, &c__0, &c__2, tout, t, (
	    ftnlen)80);
    goto L750;
L712:
    s_copy(msg, "DASSL--  INFO(8)=1 AND H0=0.0", (ftnlen)80, (ftnlen)29);
    xerrwv_(msg, &c__29, &c__12, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L750;
L713:
    s_copy(msg, "DASSL--  SOME ELEMENT OF WT IS .LE. 0.0", (ftnlen)80, (
	    ftnlen)39);
    xerrwv_(msg, &c__39, &c__13, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L750;
L714:
    s_copy(msg, "DASSL-- TOUT (=R1) TOO CLOSE TO T (=R2) TO START INTEGRATION"
	    , (ftnlen)80, (ftnlen)60);
    xerrwv_(msg, &c__60, &c__14, &c__0, &c__0, &c__0, &c__0, &c__2, tout, t, (
	    ftnlen)80);
    goto L750;
L715:
    s_copy(msg, "DASSL--  INFO(4)=1 AND TSTOP (=R1) BEHIND T (=R2)", (ftnlen)
	    80, (ftnlen)49);
    xerrwv_(msg, &c__49, &c__15, &c__0, &c__0, &c__0, &c__0, &c__2, &tstop, t,
	     (ftnlen)80);
    goto L750;
L717:
    s_copy(msg, "DASSL--  ML (=I1) ILLEGAL. EITHER .LT. 0 OR .GT. NEQ", (
	    ftnlen)80, (ftnlen)52);
    xerrwv_(msg, &c__52, &c__17, &c__0, &c__1, &iwork[1], &c__0, &c__0, &
	    c_b30, &c_b30, (ftnlen)80);
    goto L750;
L718:
    s_copy(msg, "DASSL--  MU (=I1) ILLEGAL. EITHER .LT. 0 OR .GT. NEQ", (
	    ftnlen)80, (ftnlen)52);
    xerrwv_(msg, &c__52, &c__18, &c__0, &c__1, &iwork[2], &c__0, &c__0, &
	    c_b30, &c_b30, (ftnlen)80);
    goto L750;
L719:
    s_copy(msg, "DASSL--  TOUT (=R1) IS EQUAL TO T (=R2)", (ftnlen)80, (
	    ftnlen)39);
    xerrwv_(msg, &c__39, &c__19, &c__0, &c__0, &c__0, &c__0, &c__2, tout, t, (
	    ftnlen)80);
    goto L750;
L730:
    s_copy(msg, "DASSL--  NG (=I1) .LT. 0", (ftnlen)80, (ftnlen)24);
    xerrwv_(msg, &c__24, &c__30, &c__1, &c__1, ng, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    goto L750;
L732:
    s_copy(msg, "DASSL--  ONE OR MORE COMPONENTS OF G HAS A ROOT", (ftnlen)80,
	     (ftnlen)47);
    xerrwv_(msg, &c__47, &c__32, &c__1, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    s_copy(msg, "         TOO NEAR TO THE INITIAL POINT", (ftnlen)80, (ftnlen)
	    38);
    xerrwv_(msg, &c__38, &c__32, &c__1, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
L750:
    if (info[1] == -1) {
	goto L760;
    }
    info[1] = -1;
    *idid = -33;
    return 0;
L760:
    s_copy(msg, "DASSL--  REPEATED OCCURRENCES OF ILLEGAL INPUT", (ftnlen)80, 
	    (ftnlen)46);
    xerrwv_(msg, &c__46, &c__801, &c__0, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
/* L770: */
    s_copy(msg, "DASSL--  RUN TERMINATED. APPARENT INFINITE LOOP", (ftnlen)80,
	     (ftnlen)47);
    xerrwv_(msg, &c__47, &c__802, &c__1, &c__0, &c__0, &c__0, &c__0, &c_b30, &
	    c_b30, (ftnlen)80);
    return 0;
/* -----------END OF SUBROUTINE DDASRT------------------------------------ */
} /* ddasrt_ */

/* Subroutine */ int drchek_(integer *job, S_fp g, integer *ng, integer *neq, 
	doublereal *tn, doublereal *tout, doublereal *y, doublereal *yp, 
	doublereal *phi, doublereal *psi, integer *kold, doublereal *g0, 
	doublereal *g1, doublereal *gx, integer *jroot, integer *irt, 
	doublereal *uround, integer *info3, doublereal *rwork, integer *iwork,
	 doublereal *rpar, integer *ipar)
{
    /* System generated locals */
    integer phi_dim1, phi_offset, i__1;
    doublereal d__1;

    /* Builtin functions */
    double d_sign(doublereal *, doublereal *);

    /* Local variables */
    static doublereal h__;
    static integer i__;
    static doublereal x, t1, temp1, temp2;
    static integer jflag;
    static doublereal hming;
    extern /* Subroutine */ int dcopy_(integer *, doublereal *, integer *, 
	    doublereal *, integer *);
    static logical zroot;
    extern /* Subroutine */ int ddatrp_(doublereal *, doublereal *, 
	    doublereal *, doublereal *, integer *, integer *, doublereal *, 
	    doublereal *), droots_(integer *, doublereal *, integer *, 
	    doublereal *, doublereal *, doublereal *, doublereal *, 
	    doublereal *, doublereal *, integer *, integer *, integer *, 
	    doublereal *, doublereal *);


/* ***BEGIN PROLOGUE  DRCHEK */
/* ***REFER TO DDASRT */
/* ***ROUTINES CALLED  DDATRP, DROOTS, DCOPY */
/* ***DATE WRITTEN   821001   (YYMMDD) */
/* ***REVISION DATE  900926   (YYMMDD) */
/* ***END PROLOGUE  DRCHEK */

/* ----------------------------------------------------------------------- */
/* THIS ROUTINE CHECKS FOR THE PRESENCE OF A ROOT IN THE */
/* VICINITY OF THE CURRENT T, IN A MANNER DEPENDING ON THE */
/* INPUT FLAG JOB.  IT CALLS SUBROUTINE DROOTS TO LOCATE THE ROOT */
/* AS PRECISELY AS POSSIBLE. */

/* IN ADDITION TO VARIABLES DESCRIBED PREVIOUSLY, DRCHEK */
/* USES THE FOLLOWING FOR COMMUNICATION.. */
/* JOB    = INTEGER FLAG INDICATING TYPE OF CALL.. */
/*          JOB = 1 MEANS THE PROBLEM IS BEING INITIALIZED, AND DRCHEK */
/*                  IS TO LOOK FOR A ROOT AT OR VERY NEAR THE INITIAL T. */
/*          JOB = 2 MEANS A CONTINUATION CALL TO THE SOLVER WAS JUST */
/*                  MADE, AND DRCHEK IS TO CHECK FOR A ROOT IN THE */
/*                  RELEVANT PART OF THE STEP LAST TAKEN. */
/*          JOB = 3 MEANS A SUCCESSFUL STEP WAS JUST TAKEN, AND DRCHEK */
/*                  IS TO LOOK FOR A ROOT IN THE INTERVAL OF THE STEP. */
/* G0     = ARRAY OF LENGTH NG, CONTAINING THE VALUE OF G AT T = T0. */
/*          G0 IS INPUT FOR JOB .GE. 2 AND ON OUTPUT IN ALL CASES. */
/* G1,GX  = ARRAYS OF LENGTH NG FOR WORK SPACE. */
/* IRT    = COMPLETION FLAG.. */
/*          IRT = 0  MEANS NO ROOT WAS FOUND. */
/*          IRT = -1 MEANS JOB = 1 AND A ROOT WAS FOUND TOO NEAR TO T. */
/*          IRT = 1  MEANS A LEGITIMATE ROOT WAS FOUND (JOB = 2 OR 3). */
/*                   ON RETURN, T0 IS THE ROOT LOCATION, AND Y IS THE */
/*                   CORRESPONDING SOLUTION VECTOR. */
/* T0     = VALUE OF T AT ONE ENDPOINT OF INTERVAL OF INTEREST.  ONLY */
/*          ROOTS BEYOND T0 IN THE DIRECTION OF INTEGRATION ARE SOUGHT. */
/*          T0 IS INPUT IF JOB .GE. 2, AND OUTPUT IN ALL CASES. */
/*          T0 IS UPDATED BY DRCHEK, WHETHER A ROOT IS FOUND OR NOT. */
/*          STORED IN THE GLOBAL ARRAY RWORK. */
/* TLAST  = LAST VALUE OF T RETURNED BY THE SOLVER (INPUT ONLY). */
/*          STORED IN THE GLOBAL ARRAY RWORK. */
/* TOUT   = FINAL OUTPUT TIME FOR THE SOLVER. */
/* IRFND  = INPUT FLAG SHOWING WHETHER THE LAST STEP TAKEN HAD A ROOT. */
/*          IRFND = 1 IF IT DID, = 0 IF NOT. */
/*          STORED IN THE GLOBAL ARRAY IWORK. */
/* INFO3  = COPY OF INFO(3) (INPUT ONLY). */
/* ----------------------------------------------------------------------- */

    /* Parameter adjustments */
    phi_dim1 = *neq;
    phi_offset = 1 + phi_dim1;
    phi -= phi_offset;
    --y;
    --yp;
    --psi;
    --g0;
    --g1;
    --gx;
    --jroot;
    --rwork;
    --iwork;

    /* Function Body */
    h__ = psi[1];
    *irt = 0;
    i__1 = *ng;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L10: */
	jroot[i__] = 0;
    }
    hming = (abs(*tn) + abs(h__)) * *uround * 100.;

    switch (*job) {
	case 1:  goto L100;
	case 2:  goto L200;
	case 3:  goto L300;
    }

/* EVALUATE G AT INITIAL T (STORED IN RWORK(LT0)), AND CHECK FOR */
/* ZERO VALUES.---------------------------------------------------------- */
L100:
    ddatrp_(tn, &rwork[41], &y[1], &yp[1], neq, kold, &phi[phi_offset], &psi[
	    1]);
    if (ierode_1.iero > 0) {
	return 0;
    }
    (*g)(neq, &rwork[41], &y[1], ng, &g0[1], rpar, ipar);
    if (ierode_1.iero > 0) {
	return 0;
    }
    iwork[16] = 1;
    zroot = FALSE_;
    i__1 = *ng;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L110: */
	if ((d__1 = g0[i__], abs(d__1)) <= 0.) {
	    zroot = TRUE_;
	}
    }
    if (! zroot) {
	goto L190;
    }
/* G HAS A ZERO AT T.  LOOK AT G AT T + (SMALL INCREMENT). -------------- */
    temp1 = d_sign(&hming, &h__);
    rwork[41] += temp1;
    temp2 = temp1 / h__;
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L120: */
	y[i__] += temp2 * phi[i__ + (phi_dim1 << 1)];
    }
    (*g)(neq, &rwork[41], &y[1], ng, &g0[1], rpar, ipar);
    if (ierode_1.iero > 0) {
	return 0;
    }
    ++iwork[16];
    zroot = FALSE_;
    i__1 = *ng;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L130: */
	if ((d__1 = g0[i__], abs(d__1)) <= 0.) {
	    zroot = TRUE_;
	}
    }
    if (! zroot) {
	goto L190;
    }
/* G HAS A ZERO AT T AND ALSO CLOSE TO T.  TAKE ERROR RETURN. ----------- */
    *irt = -1;
    return 0;

L190:
    return 0;


L200:
    if (iwork[18] == 0) {
	goto L260;
    }
/* IF A ROOT WAS FOUND ON THE PREVIOUS STEP, EVALUATE G0 = G(T0). ------- */
    ddatrp_(tn, &rwork[41], &y[1], &yp[1], neq, kold, &phi[phi_offset], &psi[
	    1]);
    if (ierode_1.iero > 0) {
	return 0;
    }
    (*g)(neq, &rwork[41], &y[1], ng, &g0[1], rpar, ipar);
    if (ierode_1.iero > 0) {
	return 0;
    }
    ++iwork[16];
    zroot = FALSE_;
    i__1 = *ng;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L210: */
	if ((d__1 = g0[i__], abs(d__1)) <= 0.) {
	    zroot = TRUE_;
	}
    }
    if (! zroot) {
	goto L260;
    }
/* G HAS A ZERO AT T0.  LOOK AT G AT T + (SMALL INCREMENT). ------------- */
    temp1 = d_sign(&hming, &h__);
    rwork[41] += temp1;
    if ((rwork[41] - *tn) * h__ < 0.) {
	goto L230;
    }
    temp2 = temp1 / h__;
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L220: */
	y[i__] += temp2 * phi[i__ + (phi_dim1 << 1)];
    }
    goto L240;
L230:
    ddatrp_(tn, &rwork[41], &y[1], &yp[1], neq, kold, &phi[phi_offset], &psi[
	    1]);
    if (ierode_1.iero > 0) {
	return 0;
    }
L240:
    (*g)(neq, &rwork[41], &y[1], ng, &g0[1], rpar, ipar);
    if (ierode_1.iero > 0) {
	return 0;
    }
    ++iwork[16];
    zroot = FALSE_;
    i__1 = *ng;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if ((d__1 = g0[i__], abs(d__1)) > 0.) {
	    goto L250;
	}
	jroot[i__] = 1;
	zroot = TRUE_;
L250:
	;
    }
    if (! zroot) {
	goto L260;
    }
/* G HAS A ZERO AT T0 AND ALSO CLOSE TO T0.  RETURN ROOT. --------------- */
    *irt = 1;
    return 0;
/*     HERE, G0 DOES NOT HAVE A ROOT */
/* G0 HAS NO ZERO COMPONENTS.  PROCEED TO CHECK RELEVANT INTERVAL. ------ */
L260:
    if (*tn == rwork[42]) {
	goto L390;
    }

L300:
/* SET T1 TO TN OR TOUT, WHICHEVER COMES FIRST, AND GET G AT T1. -------- */
    if (*info3 == 1) {
	goto L310;
    }
    if ((*tout - *tn) * h__ >= 0.) {
	goto L310;
    }
    t1 = *tout;
    if ((t1 - rwork[41]) * h__ <= 0.) {
	goto L390;
    }
    ddatrp_(tn, &t1, &y[1], &yp[1], neq, kold, &phi[phi_offset], &psi[1]);
    if (ierode_1.iero > 0) {
	return 0;
    }
    goto L330;
L310:
    t1 = *tn;
    i__1 = *neq;
    for (i__ = 1; i__ <= i__1; ++i__) {
/* L320: */
	y[i__] = phi[i__ + phi_dim1];
    }
L330:
    (*g)(neq, &t1, &y[1], ng, &g1[1], rpar, ipar);
    if (ierode_1.iero > 0) {
	return 0;
    }
    ++iwork[16];
/* CALL DROOTS TO SEARCH FOR ROOT IN INTERVAL FROM T0 TO T1. ------------ */
    jflag = 0;
L350:
    droots_(ng, &hming, &jflag, &rwork[41], &t1, &g0[1], &g1[1], &gx[1], &x, &
	    jroot[1], &iwork[20], &iwork[19], &rwork[43], &rwork[44]);
    if (ierode_1.iero > 0) {
	return 0;
    }
    if (jflag > 1) {
	goto L360;
    }
    ddatrp_(tn, &x, &y[1], &yp[1], neq, kold, &phi[phi_offset], &psi[1]);
    if (ierode_1.iero > 0) {
	return 0;
    }
    (*g)(neq, &x, &y[1], ng, &gx[1], rpar, ipar);
    if (ierode_1.iero > 0) {
	return 0;
    }
    ++iwork[16];
    goto L350;
L360:
    rwork[41] = x;
    dcopy_(ng, &gx[1], &c__1, &g0[1], &c__1);
    if (jflag == 4) {
	goto L390;
    }
/* FOUND A ROOT.  INTERPOLATE TO X AND RETURN. -------------------------- */
    ddatrp_(tn, &x, &y[1], &yp[1], neq, kold, &phi[phi_offset], &psi[1]);
    if (ierode_1.iero > 0) {
	return 0;
    }
    *irt = 1;
    return 0;

L390:
    return 0;
/* ---------------------- END OF SUBROUTINE DRCHEK ----------------------- */
} /* drchek_ */

/* Subroutine */ int droots_(integer *ng, doublereal *hmin, integer *jflag, 
	doublereal *x0, doublereal *x1, doublereal *g0, doublereal *g1, 
	doublereal *gx, doublereal *x, integer *jroot, integer *imax, integer 
	*last, doublereal *alpha, doublereal *x2)
{
    /* Initialized data */

    static doublereal zero = 0.;

    /* System generated locals */
    integer i__1;
    doublereal d__1, d__2;

    /* Builtin functions */
    double d_sign(doublereal *, doublereal *);

    /* Local variables */
    static integer i__;
    static doublereal t2, tmax;
    extern /* Subroutine */ int dcopy_(integer *, doublereal *, integer *, 
	    doublereal *, integer *);
    static logical xroot, zroot, sgnchg;
    static integer imxold, nxlast;

/*      subroutine roots (ng, hmin, jflag, x0, x1, g0, g1, gx, x, jroot) */

/* ***BEGIN PROLOGUE  DROOTS */
/* ***REFER TO DDASRT */
/* ***ROUTINES CALLED  DCOPY */
/* ***DATE WRITTEN   821001   (YYMMDD) */
/* ***REVISION DATE  900926   (YYMMDD) */
/* ***END PROLOGUE  DROOTS */

/* ----------------------------------------------------------------------- */
/* THIS SUBROUTINE FINDS THE LEFTMOST ROOT OF A SET OF ARBITRARY */
/* FUNCTIONS GI(X) (I = 1,...,NG) IN AN INTERVAL (X0,X1).  ONLY ROOTS */
/* OF ODD MULTIPLICITY (I.E. CHANGES OF SIGN OF THE GI) ARE FOUND. */
/* HERE THE SIGN OF X1 - X0 IS ARBITRARY, BUT IS CONSTANT FOR A GIVEN */
/* PROBLEM, AND -LEFTMOST- MEANS NEAREST TO X0. */
/* THE VALUES OF THE VECTOR-VALUED FUNCTION G(X) = (GI, I=1...NG) */
/* ARE COMMUNICATED THROUGH THE CALL SEQUENCE OF DROOTS. */
/* THE METHOD USED IS THE ILLINOIS ALGORITHM. */

/* REFERENCE.. */
/* KATHIE L. HIEBERT AND LAWRENCE F. SHAMPINE, IMPLICITLY DEFINED */
/* OUTPUT POINTS FOR SOLUTIONS OF ODE-S, SANDIA REPORT SAND80-0180, */
/* FEBRUARY, 1980. */

/* DESCRIPTION OF PARAMETERS. */

/* NG     = NUMBER OF FUNCTIONS GI, OR THE NUMBER OF COMPONENTS OF */
/*          THE VECTOR VALUED FUNCTION G(X).  INPUT ONLY. */

/* HMIN   = RESOLUTION PARAMETER IN X.  INPUT ONLY.  WHEN A ROOT IS */
/*          FOUND, IT IS LOCATED ONLY TO WITHIN AN ERROR OF HMIN IN X. */
/*          TYPICALLY, HMIN SHOULD BE SET TO SOMETHING ON THE ORDER OF */
/*               100 * UROUND * MAX(ABS(X0),ABS(X1)), */
/*          WHERE UROUND IS THE UNIT ROUNDOFF OF THE MACHINE. */

/* JFLAG  = INTEGER FLAG FOR INPUT AND OUTPUT COMMUNICATION. */

/*          ON INPUT, SET JFLAG = 0 ON THE FIRST CALL FOR THE PROBLEM, */
/*          AND LEAVE IT UNCHANGED UNTIL THE PROBLEM IS COMPLETED. */
/*          (THE PROBLEM IS COMPLETED WHEN JFLAG .GE. 2 ON RETURN.) */

/*          ON OUTPUT, JFLAG HAS THE FOLLOWING VALUES AND MEANINGS.. */
/*          JFLAG = 1 MEANS DROOTS NEEDS A VALUE OF G(X).  SET GX = G(X) */
/*                    AND CALL DROOTS AGAIN. */
/*          JFLAG = 2 MEANS A ROOT HAS BEEN FOUND.  THE ROOT IS */
/*                    AT X, AND GX CONTAINS G(X).  (ACTUALLY, X IS THE */
/*                    RIGHTMOST APPROXIMATION TO THE ROOT ON AN INTERVAL */
/*                    (X0,X1) OF SIZE HMIN OR LESS.) */
/*          JFLAG = 3 MEANS X = X1 IS A ROOT, WITH ONE OR MORE OF THE GI */
/*                    BEING ZERO AT X1 AND NO SIGN CHANGES IN (X0,X1). */
/*                    GX CONTAINS G(X) ON OUTPUT. */
/*          JFLAG = 4 MEANS NO ROOTS (OF ODD MULTIPLICITY) WERE */
/*                    FOUND IN (X0,X1) (NO SIGN CHANGES). */

/* X0,X1  = ENDPOINTS OF THE INTERVAL WHERE ROOTS ARE SOUGHT. */
/*          X1 AND X0 ARE INPUT WHEN JFLAG = 0 (FIRST CALL), AND */
/*          MUST BE LEFT UNCHANGED BETWEEN CALLS UNTIL THE PROBLEM IS */
/*          COMPLETED.  X0 AND X1 MUST BE DISTINCT, BUT X1 - X0 MAY BE */
/*          OF EITHER SIGN.  HOWEVER, THE NOTION OF -LEFT- AND -RIGHT- */
/*          WILL BE USED TO MEAN NEARER TO X0 OR X1, RESPECTIVELY. */
/*          WHEN JFLAG .GE. 2 ON RETURN, X0 AND X1 ARE OUTPUT, AND */
/*          ARE THE ENDPOINTS OF THE RELEVANT INTERVAL. */

/* G0,G1  = ARRAYS OF LENGTH NG CONTAINING THE VECTORS G(X0) AND G(X1), */
/*          RESPECTIVELY.  WHEN JFLAG = 0, G0 AND G1 ARE INPUT AND */
/*          NONE OF THE G0(I) SHOULD BE BE ZERO. */
/*          WHEN JFLAG .GE. 2 ON RETURN, G0 AND G1 ARE OUTPUT. */

/* GX     = ARRAY OF LENGTH NG CONTAINING G(X).  GX IS INPUT */
/*          WHEN JFLAG = 1, AND OUTPUT WHEN JFLAG .GE. 2. */

/* X      = INDEPENDENT VARIABLE VALUE.  OUTPUT ONLY. */
/*          WHEN JFLAG = 1 ON OUTPUT, X IS THE POINT AT WHICH G(X) */
/*          IS TO BE EVALUATED AND LOADED INTO GX. */
/*          WHEN JFLAG = 2 OR 3, X IS THE ROOT. */
/*          WHEN JFLAG = 4, X IS THE RIGHT ENDPOINT OF THE INTERVAL, X1. */

/* JROOT  = INTEGER ARRAY OF LENGTH NG.  OUTPUT ONLY. */
/*          WHEN JFLAG = 2 OR 3, JROOT INDICATES WHICH COMPONENTS */
/*          OF G(X) HAVE A ROOT AT X.  JROOT(I) IS 1 IF THE I-TH */
/*          COMPONENT HAS A ROOT, AND JROOT(I) = 0 OTHERWISE. */

/* IMAX, LAST, ALPHA, X2 = */
/*          BOOKKEEPING VARIABLES WHICH MUST BE SAVED FROM CALL */
/*          TO CALL.  THEY ARE SAVED INSIDE THE CALLING ROUTINE, */
/*          BUT THEY ARE USED ONLY WITHIN THIS ROUTINE. */
/* ----------------------------------------------------------------------- */
    /* Parameter adjustments */
    --jroot;
    --gx;
    --g1;
    --g0;

    /* Function Body */

    if (*jflag == 1) {
	goto L200;
    }
/* JFLAG .NE. 1.  CHECK FOR CHANGE IN SIGN OF G OR ZERO AT X1. ---------- */
    *imax = 0;
    tmax = zero;
    zroot = FALSE_;
    i__1 = *ng;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if ((d__1 = g1[i__], abs(d__1)) > zero) {
	    goto L110;
	}
	zroot = TRUE_;
	goto L120;
/* AT THIS POINT, G0(I) HAS BEEN CHECKED AND CANNOT BE ZERO. ------------ */
L110:
	if (d_sign(&c_b588, &g0[i__]) == d_sign(&c_b588, &g1[i__])) {
	    goto L120;
	}
	t2 = (d__1 = g1[i__] / (g1[i__] - g0[i__]), abs(d__1));
	if (t2 <= tmax) {
	    goto L120;
	}
	tmax = t2;
	*imax = i__;
L120:
	;
    }
    if (*imax > 0) {
	goto L130;
    }
    sgnchg = FALSE_;
    goto L140;
L130:
    sgnchg = TRUE_;
L140:
    if (! sgnchg) {
	goto L400;
    }
/* THERE IS A SIGN CHANGE.  FIND THE FIRST ROOT IN THE INTERVAL. -------- */
    xroot = FALSE_;
    nxlast = 0;
    *last = 1;

/* REPEAT UNTIL THE FIRST ROOT IN THE INTERVAL IS FOUND.  LOOP POINT. --- */
L150:
    if (xroot) {
	goto L300;
    }
    if (nxlast == *last) {
	goto L160;
    }
    *alpha = 1.;
    goto L180;
L160:
    if (*last == 0) {
	goto L170;
    }
    *alpha *= .5;
    goto L180;
L170:
    *alpha *= 2.;
L180:
    *x2 = *x1 - (*x1 - *x0) * g1[*imax] / (g1[*imax] - *alpha * g0[*imax]);
    if ((d__1 = *x2 - *x0, abs(d__1)) < *hmin && (d__2 = *x1 - *x0, abs(d__2))
	     > *hmin * 10.) {
	*x2 = *x0 + (*x1 - *x0) * .1;
    }
    *jflag = 1;
    *x = *x2;
/* RETURN TO THE CALLING ROUTINE TO GET A VALUE OF GX = G(X). ----------- */
    return 0;
/* CHECK TO SEE IN WHICH INTERVAL G CHANGES SIGN. ----------------------- */
L200:
    imxold = *imax;
    *imax = 0;
    tmax = zero;
    zroot = FALSE_;
    i__1 = *ng;
    for (i__ = 1; i__ <= i__1; ++i__) {
	if ((d__1 = gx[i__], abs(d__1)) > zero) {
	    goto L210;
	}
	zroot = TRUE_;
	goto L220;
/* NEITHER G0(I) NOR GX(I) CAN BE ZERO AT THIS POINT. ------------------- */
L210:
	if (d_sign(&c_b588, &g0[i__]) == d_sign(&c_b588, &gx[i__])) {
	    goto L220;
	}
	t2 = (d__1 = gx[i__] / (gx[i__] - g0[i__]), abs(d__1));
	if (t2 <= tmax) {
	    goto L220;
	}
	tmax = t2;
	*imax = i__;
L220:
	;
    }
    if (*imax > 0) {
	goto L230;
    }
    sgnchg = FALSE_;
    *imax = imxold;
    goto L240;
L230:
    sgnchg = TRUE_;
L240:
    nxlast = *last;
    if (! sgnchg) {
	goto L250;
    }
/* SIGN CHANGE BETWEEN X0 AND X2, SO REPLACE X1 WITH X2. ---------------- */
    *x1 = *x2;
    dcopy_(ng, &gx[1], &c__1, &g1[1], &c__1);
    *last = 1;
    xroot = FALSE_;
    goto L270;
L250:
    if (! zroot) {
	goto L260;
    }
/* ZERO VALUE AT X2 AND NO SIGN CHANGE IN (X0,X2), SO X2 IS A ROOT. ----- */
    *x1 = *x2;
    dcopy_(ng, &gx[1], &c__1, &g1[1], &c__1);
    xroot = TRUE_;
    goto L270;
/* NO SIGN CHANGE BETWEEN X0 AND X2.  REPLACE X0 WITH X2. --------------- */
L260:
    dcopy_(ng, &gx[1], &c__1, &g0[1], &c__1);
    *x0 = *x2;
    *last = 0;
    xroot = FALSE_;
L270:
    if ((d__1 = *x1 - *x0, abs(d__1)) <= *hmin) {
	xroot = TRUE_;
    }
    goto L150;

/* RETURN WITH X1 AS THE ROOT.  SET JROOT.  SET X = X1 AND GX = G1. ----- */
L300:
    *jflag = 2;
    *x = *x1;
    dcopy_(ng, &g1[1], &c__1, &gx[1], &c__1);
    i__1 = *ng;
    for (i__ = 1; i__ <= i__1; ++i__) {
	jroot[i__] = 0;
	if ((d__1 = g1[i__], abs(d__1)) > zero) {
	    goto L310;
	}
	jroot[i__] = 1;
	goto L320;
L310:
	if (d_sign(&c_b588, &g0[i__]) != d_sign(&c_b588, &g1[i__])) {
	    jroot[i__] = 1;
	}
L320:
	;
    }
    return 0;

/* NO SIGN CHANGE IN THE INTERVAL.  CHECK FOR ZERO AT RIGHT ENDPOINT. --- */
L400:
    if (! zroot) {
	goto L420;
    }

/* ZERO VALUE AT X1 AND NO SIGN CHANGE IN (X0,X1).  RETURN JFLAG = 3. --- */
    *x = *x1;
    dcopy_(ng, &g1[1], &c__1, &gx[1], &c__1);
    i__1 = *ng;
    for (i__ = 1; i__ <= i__1; ++i__) {
	jroot[i__] = 0;
	if ((d__1 = g1[i__], abs(d__1)) <= zero) {
	    jroot[i__] = 1;
	}
/* L410: */
    }
    *jflag = 3;
    return 0;

/* NO SIGN CHANGES IN THIS INTERVAL.  SET X = X1, RETURN JFLAG = 4. ----- */
L420:
    dcopy_(ng, &g1[1], &c__1, &gx[1], &c__1);
    *x = *x1;
    *jflag = 4;
    return 0;
/* ---------------------- END OF SUBROUTINE DROOTS ----------------------- */
} /* droots_ */

