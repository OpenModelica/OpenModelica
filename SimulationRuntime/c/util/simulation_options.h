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

enum _FLAG
{
  FLAG_UNKNOWN = 0,

  FLAG_ABORT_SLOW,
  FLAG_ALARM,
  FLAG_CLOCK,
  FLAG_CPU,
  FLAG_CSV_OSTEP,
  FLAG_DASSL_NO_RESTART,
  FLAG_DASSL_NO_ROOTFINDING,
  FLAG_EMBEDDED_SERVER,
  FLAG_EMIT_PROTECTED,
  FLAG_F,
  FLAG_HELP,
  FLAG_IGNORE_HIDERESULT,
  FLAG_IIF,
  FLAG_IIM,
  FLAG_IIT,
  FLAG_ILS,
  FLAG_INITIAL_STEP_SIZE,
  FLAG_INPUT_CSV,
  FLAG_INPUT_FILE,
  FLAG_INPUT_FILE_STATES,
  FLAG_IPOPT_HESSE,
  FLAG_IPOPT_INIT,
  FLAG_IPOPT_JAC,
  FLAG_IPOPT_MAX_ITER,
  FLAG_IPOPT_WARM_START,
  FLAG_JACOBIAN,
  FLAG_L,
  FLAG_L_DATA_RECOVERY,
  FLAG_LOG_FORMAT,
  FLAG_LS,
  FLAG_LS_IPOPT,
  FLAG_LSS,
  FLAG_LSS_MAX_DENSITY,
  FLAG_LSS_MIN_SIZE,
  FLAG_LV,
  FLAG_MAX_BISECTION_ITERATIONS,
  FLAG_MAX_EVENT_ITERATIONS,
  FLAG_MAX_ORDER,
  FLAG_MAX_STEP_SIZE,
  FLAG_MEASURETIMEPLOTFORMAT,
  FLAG_NEWTON_STRATEGY,
  FLAG_NLS,
  FLAG_NLS_INFO,
  FLAG_NOEMIT,
  FLAG_NOEQUIDISTANT_GRID,
  FLAG_NOEQUIDISTANT_OUT_FREQ,
  FLAG_NOEQUIDISTANT_OUT_TIME,
  FLAG_NOEVENTEMIT,
  FLAG_OPTDEBUGEJAC,
  FLAG_OPTIMIZER_NP,
  FLAG_OPTIMIZER_TGRID,
  FLAG_OUTPUT,
  FLAG_OVERRIDE,
  FLAG_OVERRIDE_FILE,
  FLAG_PORT,
  FLAG_R,
  FLAG_RT,
  FLAG_S,
  FLAG_UP_HESSIAN,
  FLAG_W,

  FLAG_MAX
};

enum _FLAG_TYPE
{
  FLAG_TYPE_UNKNOWN = 0,

  FLAG_TYPE_FLAG,         /* e.g. -f */
  FLAG_TYPE_OPTION,       /* e.g. -f=value or -f value */

  FLAG_TYPE_MAX
};

extern const char *FLAG_NAME[FLAG_MAX+1];
extern const char *FLAG_DESC[FLAG_MAX+1];
extern const char *FLAG_DETAILED_DESC[FLAG_MAX+1];
extern const int FLAG_TYPE[FLAG_MAX];

enum SOLVER_METHOD
{
  S_UNKNOWN = 0,

  S_EULER,         /*  1 */
  S_RUNGEKUTTA,    /*  2 */
  S_DASSL,         /*  3 */
  S_OPTIMIZATION,  /*  4 */
  S_RADAU5,        /*  5 */
  S_RADAU3,        /*  6 */
  S_RADAU1,        /*  7 */
  S_LOBATTO2,      /*  8 */
  S_LOBATTO4,      /*  9 */
  S_LOBATTO6,      /* 10 */
  S_SYM_EULER,     /* 11 */
  S_SYM_IMP_EULER, /* 12 */
  S_HEUN,          /* 13 */
  S_QSS,

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

enum LINEAR_SOLVER
{
  LS_NONE = 0,

  LS_LAPACK,
#if !defined(OMC_MINIMAL_RUNTIME)
  LS_LIS,
#endif
  LS_KLU,
  LS_UMFPACK,
  LS_TOTALPIVOT,
  LS_DEFAULT,

  LS_MAX
};

enum LINEAR_SPARSE_SOLVER
{
  LSS_NONE = 0,

#if !defined(OMC_MINIMAL_RUNTIME)
  LSS_LIS,
#endif
  LSS_KLU,
  LSS_UMFPACK,

  LSS_MAX
};

extern const char *LS_NAME[LS_MAX+1];
extern const char *LS_DESC[LS_MAX+1];
extern const char *LSS_NAME[LS_MAX+1];
extern const char *LSS_DESC[LS_MAX+1];

enum NONLINEAR_SOLVER
{
  NLS_NONE = 0,

#if !defined(OMC_MINIMAL_RUNTIME)
  NLS_HYBRID,
  NLS_KINSOL,
#endif
  NLS_NEWTON,
  NLS_HOMOTOPY,
  NLS_MIXED,

  NLS_MAX
};


enum NEWTON_STRATEGY
{
  NEWTON_NONE = 0,

  NEWTON_DAMPED,
  NEWTON_DAMPED2,
  NEWTON_DAMPED_LS,
  NEWTON_DAMPED_BT,
  NEWTON_PURE,

  NEWTON_MAX
};

extern const char *NLS_NAME[NLS_MAX+1];
extern const char *NLS_DESC[NLS_MAX+1];

extern const char *NEWTONSTRATEGY_NAME[NEWTON_MAX+1];
extern const char *NEWTONSTRATEGY_DESC[NEWTON_MAX+1];

enum JACOBIAN_METHOD
{
  JAC_UNKNOWN = 0,

  COLOREDNUMJAC,
  COLOREDSYMJAC,
  INTERNALNUMJAC,
  NUMJAC,
  SYMJAC,

  JAC_MAX
};

extern const char *JACOBIAN_METHOD[JAC_MAX+1];
extern const char *JACOBIAN_METHOD_DESC[JAC_MAX+1];




#if defined(__cplusplus)
  }
#endif

#endif
