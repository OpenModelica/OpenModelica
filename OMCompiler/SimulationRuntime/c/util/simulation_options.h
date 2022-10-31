/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/* Simulation help constants are available in the regular runtime so we can link omc with them */

#ifndef OPENMODELICA_SIMULATION_OPTIONS_H
#define OPENMODELICA_SIMULATION_OPTIONS_H

#if defined(__cplusplus)
  extern "C" {
#endif

#define EXPANDSTRING(s) EXPANDSTRINGHELPER(s)
#define EXPANDSTRINGHELPER(s) #s

#define DEFAULT_FLAG_LSS_MAX_DENSITY 0.2
#define DEFAULT_FLAG_LSS_MIN_SIZE 1000
#define DEFAULT_FLAG_NLSS_MAX_DENSITY 0.1
#define DEFAULT_FLAG_NLSS_MIN_SIZE 1000

enum _FLAG
{
  FLAG_UNKNOWN = 0,

  FLAG_ABORT_SLOW,
  FLAG_ALARM,
  FLAG_CLOCK,
  FLAG_CPU,
  FLAG_CSV_OSTEP,
  FLAG_CVODE_ITER,
  FLAG_CVODE_LMM,
  FLAG_DATA_RECONCILE_Cx,
  FLAG_DAE_MODE,
  FLAG_DELTA_X_LINEARIZE,
  FLAG_DELTA_X_SOLVER,
  FLAG_EMBEDDED_SERVER,
  FLAG_EMBEDDED_SERVER_PORT,
  FLAG_MAT_SYNC,
  FLAG_EMIT_PROTECTED,
  FLAG_DATA_RECONCILE_Eps,
  FLAG_F,
  FLAG_HELP,
  FLAG_HOMOTOPY_ADAPT_BEND,
  FLAG_HOMOTOPY_BACKTRACE_STRATEGY,
  FLAG_HOMOTOPY_H_EPS,
  FLAG_HOMOTOPY_MAX_LAMBDA_STEPS,
  FLAG_HOMOTOPY_MAX_NEWTON_STEPS,
  FLAG_HOMOTOPY_MAX_TRIES,
  FLAG_HOMOTOPY_NEG_START_DIR,
  FLAG_HOMOTOPY_ON_FIRST_TRY,
  FLAG_NO_HOMOTOPY_ON_FIRST_TRY,
  FLAG_HOMOTOPY_TAU_DEC_FACTOR,
  FLAG_HOMOTOPY_TAU_DEC_FACTOR_PRED,
  FLAG_HOMOTOPY_TAU_INC_FACTOR,
  FLAG_HOMOTOPY_TAU_INC_THRESHOLD,
  FLAG_HOMOTOPY_TAU_MAX,
  FLAG_HOMOTOPY_TAU_MIN,
  FLAG_HOMOTOPY_TAU_START,
  FLAG_IDA_MAXERRORTESTFAIL,
  FLAG_IDA_MAXNONLINITERS,
  FLAG_IDA_MAXCONVFAILS,
  FLAG_IDA_NONLINCONVCOEF,
  FLAG_IDA_LS,
  FLAG_IDA_SCALING,
  FLAG_IDAS,
  FLAG_IGNORE_HIDERESULT,
  FLAG_IIF,
  FLAG_IIM,
  FLAG_IIT,
  FLAG_ILS,
  FLAG_IMPRK_ORDER,
  FLAG_IMPRK_LS,
  FLAG_INITIAL_STEP_SIZE,
  FLAG_INPUT_CSV,
  FLAG_INPUT_FILE_STATES,
  FLAG_INPUT_PATH,
  FLAG_IPOPT_HESSE,
  FLAG_IPOPT_INIT,
  FLAG_IPOPT_JAC,
  FLAG_IPOPT_MAX_ITER,
  FLAG_IPOPT_WARM_START,
  FLAG_JACOBIAN,
  FLAG_JACOBIAN_THREADS,
  FLAG_L,
  FLAG_L_DATA_RECOVERY,
  FLAG_LOG_FORMAT,
  FLAG_LS,
  FLAG_LS_IPOPT,
  FLAG_LSS,
  FLAG_LSS_MAX_DENSITY,
  FLAG_LSS_MIN_SIZE,
  FLAG_LV,
  FLAG_LV_TIME,
  FLAG_MAX_BISECTION_ITERATIONS,
  FLAG_MAX_EVENT_ITERATIONS,
  FLAG_MAX_ORDER,
  FLAG_MAX_STEP_SIZE,
  FLAG_MEASURETIMEPLOTFORMAT,
  FLAG_NEWTON_FTOL,
  FLAG_NEWTON_MAX_STEP_FACTOR,
  FLAG_NEWTON_XTOL,
  FLAG_NEWTON_STRATEGY,
  FLAG_NLS,
  FLAG_NLS_INFO,
  FLAG_NLS_LS,
  FLAG_NLSS_MAX_DENSITY,
  FLAG_NLSS_MIN_SIZE,
  FLAG_NOEMIT,
  FLAG_NOEQUIDISTANT_GRID,
  FLAG_NOEQUIDISTANT_OUT_FREQ,
  FLAG_NOEQUIDISTANT_OUT_TIME,
  FLAG_NOEVENTEMIT,
  FLAG_NO_RESTART,
  FLAG_NO_ROOTFINDING,
  FLAG_NO_SCALING,
  FLAG_NO_SUPPRESS_ALG,
  FLAG_OPTDEBUGEJAC,
  FLAG_OPTIMIZER_NP,
  FLAG_OPTIMIZER_TGRID,
  FLAG_OUTPUT,
  FLAG_OUTPUT_PATH,
  FLAG_OVERRIDE,
  FLAG_OVERRIDE_FILE,
  FLAG_PORT,
  FLAG_R,
  FLAG_DATA_RECONCILE,
  FLAG_DATA_RECONCILE_BOUNDARY,
  FLAG_SR,
  FLAG_SR_CTRL,
  FLAG_SR_ERR,
  FLAG_SR_INT,
  FLAG_SR_NLS,
  FLAG_MR,
  FLAG_MR_CTRL,
  FLAG_MR_ERR,
  FLAG_MR_INT,
  FLAG_MR_NLS,
  FLAG_MR_PAR,
  FLAG_RT,
  FLAG_S,
  FLAG_SINGLE_PRECISION,
  FLAG_SOLVER_STEPS,
  FLAG_STEADY_STATE,
  FLAG_STEADY_STATE_TOL,
  FLAG_DATA_RECONCILE_Sx,
  FLAG_UP_HESSIAN,
  FLAG_W,
  FLAG_PARMODNUMTHREADS,

  FLAG_MAX
};

enum _FLAG_TYPE
{
  FLAG_TYPE_UNKNOWN = 0,

  FLAG_TYPE_FLAG,         /* e.g. -f */
  FLAG_TYPE_OPTION,       /* e.g. -f=value or -f value */

  FLAG_TYPE_MAX
};

typedef enum {
  FLAG_REPEAT_POLICY_FORBID = 0,
  FLAG_REPEAT_POLICY_IGNORE,
  FLAG_REPEAT_POLICY_REPLACE,
  FLAG_REPEAT_POLICY_COMBINE
} flag_repeat_policy;

extern const char *FLAG_NAME[FLAG_MAX+1];
extern const char *FLAG_DESC[FLAG_MAX+1];
extern const char *FLAG_DETAILED_DESC[FLAG_MAX+1];
extern const flag_repeat_policy FLAG_REPEAT_POLICIES[FLAG_MAX];
extern const int FLAG_TYPE[FLAG_MAX];

enum GB_METHOD {
  GB_UNKNOWN = 0,

  MS_ADAMS_MOULTON,   /* adams*/
  RK_EXPL_EULER,      /* expl_euler*/
  RK_IMPL_EULER,      /* impl_euler*/
  RK_TRAPEZOID,       /* trapezoid */
  RK_SDIRK2,          /* sdirk2*/
  RK_SDIRK3,          /* sdirk3*/
  RK_ESDIRK2,         /* esdirk2*/
  RK_ESDIRK3,         /* esdirk3*/
  RK_ESDIRK4,         /* esdirk4*/
  RK_RADAU_IA_2,      /* radauIA2*/
  RK_RADAU_IA_3,      /* radauIA3*/
  RK_RADAU_IA_4,      /* radauIA4*/
  RK_RADAU_IIA_2,     /* radauIIA2*/
  RK_RADAU_IIA_3,     /* radauIIA3*/
  RK_RADAU_IIA_4,     /* radauIIA4*/
  RK_LOBA_IIIA_3,     /* lobattoIIIA3*/
  RK_LOBA_IIIA_4,     /* lobattoIIIA4*/
  RK_LOBA_IIIB_3,     /* lobattoIIIB3*/
  RK_LOBA_IIIB_4,     /* lobattoIIIB4*/
  RK_LOBA_IIIC_3,     /* lobattoIIIC3*/
  RK_LOBA_IIIC_4,     /* lobattoIIIC4*/
  RK_GAUSS2,          /* gauss2*/
  RK_GAUSS3,          /* gauss3*/
  RK_GAUSS4,          /* gauss4*/
  RK_GAUSS5,          /* gauss5*/
  RK_GAUSS6,          /* gauss6*/
  RK_MERSON,          /* merson*/
  RK_MERSONSSC1,      /* mersonSsc1*/
  RK_MERSONSSC2,      /* mersonSsc2*/
  RK_HEUN,            /* heun */
  RK_FEHLBERG12,      /* fehlberg12*/
  RK_FEHLBERG45,      /* fehlberg45*/
  RK_FEHLBERG78,      /* fehlberg78*/
  RK_FEHLBERGSSC1,    /* fehlbergSsc1*/
  RK_FEHLBERGSSC2,    /* fehlbergSsc2*/
  RK_RK810,           /* rk810*/
  RK_RK1012,          /* rk1012*/
  RK_RK1214,          /* rk1214*/
  RK_DOPRI45,         /* dopri45*/
  RK_DOPRISSC1,       /* dopriSsc1*/
  RK_DOPRISSC2,       /* dopriSsc2*/
  RK_RKSSC,           /* rungekuttaSsc */


  RK_MAX
};

extern const char *GB_METHOD_NAME[RK_MAX];
extern const char *GB_METHOD_DESC[RK_MAX];

enum GB_NLS_METHOD {
  GB_NLS_UNKNOWN = 0,

  GB_NLS_NEWTON,
  GB_NLS_KINSOL,

  GB_NLS_MAX
};

extern const char *GB_NLS_METHOD_NAME[GB_NLS_MAX];
extern const char *GB_NLS_METHOD_DESC[GB_NLS_MAX];

/**
 * @brief Step size controller method
 */
enum GB_CTRL_METHOD {
  GB_CTRL_UNKNOWN = 0,  /* Unknown controller */
  GB_CTRL_I = 1,        /* I controller */
  GB_CTRL_PI = 2,       /* PI controller */
  GB_CTRL_CNST = 3,     /* Constant step size */

  GB_CTRL_MAX
};

extern const char *GB_CTRL_METHOD_NAME[GB_CTRL_MAX];
extern const char *GB_CTRL_METHOD_DESC[GB_CTRL_MAX];

enum GB_INTERPOL_METHOD {
  GB_INTERPOL_UNKNOWN = 0,      /* Unknown interpolation method */
  GB_INTERPOL_LIN,              /* Linear interpolation */
  GB_INTERPOL_HERMITE,          /* Hermite interpolation */
  GB_INTERPOL_HERMITE_a,        /* Hermite interpolation (only for left hand side)*/
  GB_INTERPOL_HERMITE_b,        /* Hermite interpolation (only for right hand side)*/
  GB_INTERPOL_HERMITE_ERRCTRL,  /* Hermite interpolation with error control */
  GB_DENSE_OUTPUT,              /* Dense output, if available else hermite */
  GB_DENSE_OUTPUT_ERRCTRL,      /* Dense output, if available else hermite with error control */

  GB_INTERPOL_MAX
};

extern const char *GB_INTERPOL_METHOD_NAME[GB_INTERPOL_MAX];
extern const char *GB_INTERPOL_METHOD_DESC[GB_INTERPOL_MAX];

enum SOLVER_METHOD
{
  S_UNKNOWN = 0,

  S_EULER,
  S_HEUN,
  S_RUNGEKUTTA,
  S_IMPEULER,
  S_TRAPEZOID,
  S_IMPRUNGEKUTTA,
  S_GBODE,
  S_IRKSCO,
  S_DASSL,
  S_IDA,
  S_CVODE,
  S_ERKSSC,
  S_SYM_SOLVER,
  S_SYM_SOLVER_SSC,
  S_QSS,
  S_OPTIMIZATION,

  S_MAX
};

extern const char *SOLVER_METHOD_NAME[S_MAX];
extern const char *SOLVER_METHOD_DESC[S_MAX];

enum INIT_INIT_METHOD
{
  IIM_UNKNOWN = 0,
  IIM_NONE,
  IIM_SYMBOLIC,
  IIM_MAX
};

extern const char *INIT_METHOD_NAME[IIM_MAX];
extern const char *INIT_METHOD_DESC[IIM_MAX];

typedef enum LINEAR_SOLVER
{
  LS_NONE = 0,

  LS_LAPACK,
#if !defined(OMC_MINIMAL_RUNTIME)
  LS_LIS,
#else
  LS_LIS_NOT_AVAILABLE,
#endif
  LS_KLU,
  LS_UMFPACK,
  LS_TOTALPIVOT,
  LS_DEFAULT,

  LS_MAX
} LINEAR_SOLVER;

extern const char *LS_NAME[LS_MAX];
extern const char *LS_DESC[LS_MAX];

typedef enum LINEAR_SPARSE_SOLVER
{
  LSS_NONE = 0,

  LSS_DEFAULT,
#if !defined(OMC_MINIMAL_RUNTIME)
  LSS_LIS,
#else
  LSS_LIS_NOT_AVAILABLE,
#endif
  LSS_KLU,
  LSS_UMFPACK,
  LSS_MAX
} LINEAR_SPARSE_SOLVER;

extern const char *LSS_NAME[LSS_MAX];
extern const char *LSS_DESC[LSS_MAX];

typedef enum NONLINEAR_SOLVER
{
  NLS_NONE = 0,

#if !defined(OMC_MINIMAL_RUNTIME)
  NLS_HYBRID,
  NLS_KINSOL,
  NLS_NEWTON,
  NLS_MIXED,
#else
  NLS_HYBRID_DOESNT_EXIST,
  NLS_KINSOL_DOESNT_EXIST,
  NLS_NEWTON_DOESNT_EXIST,
  NLS_MIXED_DOESNT_EXIST,
#endif
  NLS_HOMOTOPY,

  NLS_MAX
} NONLINEAR_SOLVER;

extern const char *NLS_NAME[NLS_MAX];
extern const char *NLS_DESC[NLS_MAX];

typedef enum NEWTON_STRATEGY
{
  NEWTON_NONE = 0,

  NEWTON_DAMPED,
  NEWTON_DAMPED2,
  NEWTON_DAMPED_LS,
  NEWTON_DAMPED_BT,
  NEWTON_PURE,

  NEWTON_MAX
} NEWTON_STRATEGY;

extern const char *NEWTONSTRATEGY_NAME[NEWTON_MAX];
extern const char *NEWTONSTRATEGY_DESC[NEWTON_MAX];

enum JACOBIAN_METHOD
{
  JAC_UNKNOWN = 0,

  COLOREDNUMJAC,      /* Colored numeric Jacobian */
  INTERNALNUMJAC,     /* Internal numeric Jacobian */
  COLOREDSYMJAC,      /* Colored symbolic Jacobian */
  NUMJAC,             /* Non-colored numeric Jacobian */
  SYMJAC,             /* Non-colored symbolic Jacobian */

  JAC_MAX
};

extern const char *JACOBIAN_METHOD[JAC_MAX];
extern const char *JACOBIAN_METHOD_DESC[JAC_MAX];

/**
 * @brief Linear system solver method
 *
 * Specify method to solve linear systems inside IDA.
 */
enum IDA_LS
{
  IDA_LS_UNKNOWN = 0, /* Unknown method */

  IDA_LS_DENSE,     /* Default dense linear solver method */
  IDA_LS_KLU,       /* KLU as linear solver method */
  IDA_LS_SPGMR,     /* Scaled, Preconditioned, Generalized Minimum Residual iterative linear solver method */
  IDA_LS_SPBCG,     /* Scaled, Preconditioned, Bi-Conjugate Gradient, Stabilized iterative linear solver method */
  IDA_LS_SPTFQMR,   /* Scaled, Preconditioned, Transpose-Free Quasi-Minimum Residual iterative linear solver method */

  IDA_LS_MAX        /* Maximum number of methods available. Not a method itself! */
};

extern const char *IDA_LS_METHOD[IDA_LS_MAX];
extern const char *IDA_LS_METHOD_DESC[IDA_LS_MAX];

/**
 * @brief Type of non-linear solver method
 *
 * Specify method to solve underlying non-linear systems.
 */
typedef enum NLS_LS
{
  NLS_LS_UNKNOWN = 0,

  NLS_LS_DEFAULT,

  NLS_LS_TOTALPIVOT,
  NLS_LS_LAPACK,
  NLS_LS_KLU,

  NLS_LS_MAX
} NLS_LS;

extern const char *NLS_LS_METHOD[NLS_LS_MAX];
extern const char *NLS_LS_METHOD_DESC[NLS_LS_MAX];

/**
 * @brief Solver method for linear systems
 *
 * Will be used for implicit Runge-Kutta-Integrators.
 */
enum IMPRK_LS
{
  IMPRK_LS_UNKNOWN = 0,

  IMPRK_LS_ITERATIVE,
  IMPRK_LS_DENSE,

  IMPRK_LS_MAX
};

extern const char *IMPRK_LS_METHOD[IMPRK_LS_MAX];
extern const char *IMPRK_LS_METHOD_DESC[IMPRK_LS_MAX];

enum HOMOTOPY_BACKTRACE_STRATEGY
{
  HOM_BACK_STRAT_NONE = 0,

  HOM_BACK_STRAT_FIX,
  HOM_BACK_STRAT_ORTHOGONAL,

  HOM_BACK_STRAT_MAX
};

extern const char *HOM_BACK_STRAT_NAME[HOM_BACK_STRAT_MAX];
extern const char *HOM_BACK_STRAT_DESC[HOM_BACK_STRAT_MAX];

enum FMU_FLAG
{
  FMU_FLAG_UNKNOWN = 0,

  FMU_FLAG_SOLVER,
  FMU_FLAG_NLS,

  FMU_FLAG_MAX
};

/* Flag mapping to use the same descriptions and names for FMU.*/
extern const int FMU_FLAG_MAP[FMU_FLAG_MAX];

#if defined(__cplusplus)
  }
#endif

#endif
