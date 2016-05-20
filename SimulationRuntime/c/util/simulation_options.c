/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

#include "simulation_options.h"

const char *FLAG_NAME[FLAG_MAX+1] = {
  "FLAG_UNKNOWN",

  /* FLAG_ABORT_SLOW */            "abortSlowSimulation",
  /* FLAG_ALARM */                 "alarm",
  /* FLAG_CLOCK */                 "clock",
  /* FLAG_CPU */                   "cpu",
  /* FLAG_CSV_OSTEP */             "csvOstep",
  /* FLAG_DASSL_NO_RESTART */      "dasslnoRestart",
  /* FLAG_DASSL_NO_ROOTFINDING */  "dasslnoRootFinding",
  /* FLAG_DAE_MODE */              "daeMode",
  /* FLAG_EMBEDDED_SERVER */       "embeddedServer",
  /* FLAG_EMIT_PROTECTED */        "emit_protected",
  /* FLAG_F */                     "f",
  /* FLAG_HELP */                  "help",
  /* FLAG_IDA_LS */                "idaLS",
  /* FLAG_IDAS */                  "idaSensitivity",
  /* FLAG_IGNORE_HIDERESULT */     "ignoreHideResult",
  /* FLAG_IIF */                   "iif",
  /* FLAG_IIM */                   "iim",
  /* FLAG_IIT */                   "iit",
  /* FLAG_ILS */                   "ils",
  /* FLAG_INITIAL_STEP_SIZE */     "initialStepSize",
  /* FLAG_INPUT_CSV */             "csvInput",
  /* FLAG_INPUT_FILE */            "exInputFile",
  /* FLAG_INPUT_FILE_STATES */     "stateFile",
  /* FLAG_IPOPT_HESSE*/            "ipopt_hesse",
  /* FLAG_IPOPT_INIT*/             "ipopt_init",
  /* FLAG_IPOPT_JAC*/              "ipopt_jac",
  /* FLAG_IPOPT_MAX_ITER */        "ipopt_max_iter",
  /* FLAG_IPOPT_WARM_START */      "ipopt_warm_start",
  /* FLAG_JACOBIAN */              "jacobian",
  /* FLAG_L */                     "l",
  /* FLAG_L_DATA_RECOVERY */       "l_datarec",
  /* FLAG_LOG_FORMAT */            "logFormat",
  /* FLAG_LS */                    "ls",
  /* FLAG_LS_IPOPT */              "ls_ipopt",
  /* FLAG_LSS */                   "lss",
  /* FLAG_LSS_MAX_DENSITY */       "lssMaxDensity",
  /* FLAG_LSS_MIN_SIZE */          "lssMinSize",
  /* FLAG_LV */                    "lv",
  /* FLAG_MAX_BISECTION_ITERATIONS */  "mbi",
  /* FLAG_MAX_EVENT_ITERATIONS */  "mei",
  /* FLAG_MAX_ORDER */             "maxIntegrationOrder",
  /* FLAG_MAX_STEP_SIZE */         "maxStepSize",
  /* FLAG_MEASURETIMEPLOTFORMAT */ "measureTimePlotFormat",
  /* FLAG_NEWTON_FTOL */           "newtonFTol",
  /* FLAG_NEWTON_XTOL */           "newtonXTol",
  /* FLAG_NEWTON_STRATEGY */       "newton",
  /* FLAG_NLS */                   "nls",
  /* FLAG_NLS_INFO */              "nlsInfo",
  /* FLAG_NOEMIT */                "noemit",
  /* FLAG_NOEQUIDISTANT_GRID */    "noEquidistantTimeGrid",
  /* FLAG_NOEQUIDISTANT_OUT_FREQ*/ "noEquidistantOutputFrequency",
  /* FLAG_NOEQUIDISTANT_OUT_TIME*/ "noEquidistantOutputTime",
  /* FLAG_NOEVENTEMIT */           "noEventEmit",
  /* FLAG_OPTDEBUGEJAC */          "optDebugeJac",
  /* FLAG_OPTIMIZER_NP */          "optimizerNP",
  /* FLAG_OPTIMIZER_TGRID */       "optimizerTimeGrid",
  /* FLAG_OUTPUT */                "output",
  /* FLAG_OVERRIDE */              "override",
  /* FLAG_OVERRIDE_FILE */         "overrideFile",
  /* FLAG_PORT */                  "port",
  /* FLAG_R */                     "r",
  /* FLAG_RT */                    "rt",
  /* FLAG_S */                     "s",
  /* FLAG_UP_HESSIAN */            "keepHessian",
  /* FLAG_W */                     "w",

  "FLAG_MAX"
};

const char *FLAG_DESC[FLAG_MAX+1] = {
  "unknown",

  /* FLAG_ABORT_SLOW */            "aborts if the simulation chatters",
  /* FLAG_ALARM */                 "aborts after the given number of seconds (0 disables)",
  /* FLAG_CLOCK */                 "selects the type of clock to use -clock=RT, -clock=CYC or -clock=CPU",
  /* FLAG_CPU */                   "dumps the cpu-time into the results-file",
  /* FLAG_CSV_OSTEP */             "value specifies csv-files for debuge values for optimizer step",
  /* FLAG_DASSL_NO_RESTART */      "flag deactivates the restart of dassl after an event is performed.",
  /* FLAG_DASSL_NO_ROOTFINDING */  "flag deactivates the internal root finding procedure of dassl.",
  /* FLAG_DAE_MODE */              "flag to let the integrator use daeResiduals",
  /* FLAG_EMBEDDED_SERVER */       "enables an embedded server. Valid values: none, opc-da [broken], opc-ua [experimental], or the path to a shared object.",
  /* FLAG_EMIT_PROTECTED */        "emits protected variables to the result-file",
  /* FLAG_F */                     "value specifies a new setup XML file to the generated simulation code",
  /* FLAG_HELP */                  "get detailed information that specifies the command-line flag",
  /* FLAG_IDA_LS */                "selects the linear solver used by ida",
  /* FLAG_IDAS */                  "flag to add sensitivity information to the result files",
  /* FLAG_IGNORE_HIDERESULT */     "ignore HideResult=true annotation",
  /* FLAG_IIF */                   "value specifies an external file for the initialization of the model",
  /* FLAG_IIM */                   "value specifies the initialization method",
  /* FLAG_IIT */                   "[double] value specifies a time for the initialization of the model",
  /* FLAG_ILS */                   "[int] default: 1",
  /* FLAG_INITIAL_STEP_SIZE */     "value specifies an initial stepsize for the dassl solver",
  /* FLAG_INPUT_CSV */             "value specifies an csv-file with inputs for the simulation/optimization of the model",
  /* FLAG_INPUT_FILE */            "value specifies an external file with inputs for the simulation/optimization of the model",
  /* FLAG_INPUT_FILE_STATES */     "value specifies an file with states start values for the optimization of the model",
  /* FLAG_IPOPT_HESSE */           "value specifies the hessian for Ipopt",
  /* FLAG_IPOPT_INIT */            "value specifies the initial guess for optimization",
  /* FLAG_IPOPT_JAC */             "value specifies the jacobian for Ipopt",
  /* FLAG_IPOPT_MAX_ITER */        "value specifies the max number of iteration for ipopt",
  /* FLAG_IPOPT_WARM_START */      "value specifies lvl for a warm start in ipopt: 1,2,3,...",
  /* FLAG_JACOBIAN */              "selects the type of the jacobians that is used for the integrator.\n  jacobian=[coloredNumerical (default) |numerical|internalNumerical|coloredSymbolical|symbolical].",
  /* FLAG_L */                     "value specifies a time where the linearization of the model should be performed",
  /* FLAG_L_DATA_RECOVERY */       "emit data recovery matrices with model linearization",
  /* FLAG_LOG_FORMAT */            "value specifies the log format of the executable. -logFormat=text (default) or -logFormat=xml",
  /* FLAG_LS */                    "value specifies the linear solver method (default: lapack, totalpivot (fallback))",
  /* FLAG_LS_IPOPT */              "value specifies the linear solver method for ipopt",
  /* FLAG_LSS */                   "value specifies the linear sparse solver method (default: umfpack)",
  /* FLAG_LSS_MAX_DENSITY */       "[double (default 0.2)] value specifies the maximum density for using a linear sparse solver",
  /* FLAG_LSS_MIN_SIZE */          "[int (default 4001)] value specifies the minimum system size for using a linear sparse solver",
  /* FLAG_LV */                    "[string list] value specifies the logging level",
  /* FLAG_MAX_BISECTION_ITERATIONS */  "[int (default 0)] value specifies the maximum number of bisection iterations for state event detection or zero for default behavior",
  /* FLAG_MAX_EVENT_ITERATIONS */  "[int (default 20)] value specifies the maximum number of event iterations",
  /* FLAG_MAX_ORDER */             "value specifies maximum integration order, used by dassl solver",
  /* FLAG_MAX_STEP_SIZE */         "value specifies maximum absolute step size, used by dassl solver",
  /* FLAG_MEASURETIMEPLOTFORMAT */ "value specifies the output format of the measure time functionality",
  /* FLAG_NEWTON_FTOL */           "[double (default 1e-24)] tolerance for accepting accuracy in Newton solver",
  /* FLAG_NEWTON_XTOL */           "[double (default 1e-24)] tolerance for updating solution vector in Newton solver",
  /* FLAG_NEWTON_STRATEGY */       "value specifies the damping strategy for the newton solver",
  /* FLAG_NLS */                   "value specifies the nonlinear solver",
  /* FLAG_NLS_INFO */              "outputs detailed information about solving process of non-linear systems into csv files.",
  /* FLAG_NOEMIT */                "do not emit any results to the result file",
  /* FLAG_NOEQUIDISTANT_GRID */    "stores results not in equidistant time grid as given by stepSize or numberOfIntervals, instead the variable step size of dassl is used.",
  /* FLAG_NOEQUIDISTANT_OUT_FREQ*/ "value controls the output frequency in noEquidistantTimeGrid mode",
  /* FLAG_NOEQUIDISTANT_OUT_TIME*/ "value controls the output time point in noEquidistantOutputTime mode",
  /* FLAG_NOEVENTEMIT */           "do not emit event points to the result file",
  /* FLAG_OPTDEBUGEJAC */          "value specifies the number of iter from the dyn. optimization, which will be debuge, creating *csv and *py file",
  /* FLAG_OPTIMIZER_NP */          "value specifies the number of points in a subinterval",
  /* FLAG_OPTIMIZER_TGRID */       "value specifies external file with time points.",
  /* FLAG_OUTPUT */                "output the variables a, b and c at the end of the simulation to the standard output",
  /* FLAG_OVERRIDE */              "override the variables or the simulation settings in the XML setup file",
  /* FLAG_OVERRIDE_FILE */         "will override the variables or the simulation settings in the XML setup file with the values from the file",
  /* FLAG_PORT */                  "value specifies the port for simulation status (default disabled)",
  /* FLAG_R */                     "value specifies a new result file than the default Model_res.mat",
  /* FLAG_RT */                    "value specifies the scaling factor for real-time synchronization (0 disables)",
  /* FLAG_S */                     "value specifies the solver",
  /* FLAG_UP_HESSIAN */            "value specifies the number of steps, which keep hessian matrix constant",
  /* FLAG_W */                     "shows all warnings even if a related log-stream is inactive",

  "FLAG_MAX"
};

const char *FLAG_DETAILED_DESC[FLAG_MAX+1] = {
  "unknown",
  /* FLAG_ABORT_SLOW */
  "  Aborts if the simulation chatters.",
  /* FLAG_ALARM */
  "  Aborts after the given number of seconds (default=0 disables the alarm).",
  /* FLAG_CLOCK */
  "  Selects the type of clock to use. Valid options include:\n\n"
  "  * RT (monotonic real-time clock)\n"
  "  * CYC (cpu cycles measured with RDTSC)\n"
  "  * CPU (process-based CPU-time)",
  /* FLAG_CPU */
  "  Dumps the cpu-time into the result-file using the variable named $cpuTime",
  /* FLAG_CSV_OSTEP */
  "value specifies csv-files for debuge values for optimizer step",
  /* FLAG_DASSL_NO_RESTART */
  "  Deactivates the restart of dassl after an event is performed.",
  /* FLAG_DASSL_NO_ROOTFINDING */
  "  Deactivates the internal root finding procedure of dassl.",
  /* FLAG_DAE_MODE */
  "flag to let the integrator use daeMode",
  /* FLAG_EMBEDDED_SERVER */
  "  Enables an embedded server. Valid values:\n\n"
  "  * none - default, run without embedded server\n"
  "  * opc-da - [broken] run with embedded OPC DA server (WIN32 only, uses proprietary OPC SC interface)\n"
  "  * opc-ua - [experimental] run with embedded OPC UA server (TCP port 4841 for now; will have its own configuration option later)\n"
  "  * filename - path to a shared object implementing the embedded server interface (requires access to internal OMC data-structures if you want to read or write data)",
  /* FLAG_EMIT_PROTECTED */
  "  Emits protected variables to the result-file.",
  /* FLAG_F */
  "  Value specifies a new setup XML file to the generated simulation code.\n",
  /* FLAG_HELP */
  "  Get detailed information that specifies the command-line flag\n"
  "  For example, -help=f prints detailed information for command-line flag f.",
  /* FLAG_IDA_LS */
  "  Value specifies the IDA solver linear solver.",
  /* FLAG_IDAS */
  "flag to add sensitivity information to the result files",
  /* FLAG_IGNORE_HIDERESULT */
  "  Emits also variables with HideResult=true annotation.",
  /* FLAG_IIF */
  "  Value specifies an external file for the initialization of the model.",
  /* FLAG_IIM */
  "  Value specifies the initialization method.", /* TODO: Fill me in */
  /* FLAG_IIT */
  "  Value [Real] specifies a time for the initialization of the model.",
  /* FLAG_ILS */
  "  Value specifies the number of steps for homotopy method (required: -iim=symbolic) or 'start value homotopy' method (required: -iim=numeric -iom=nelder_mead_ex).\n"
  "  The value is an Integer with default value 1.",
  /* FLAG_INITIAL_STEP_SIZE */
  "  Value specifies an initial stepsize for the dassl solver.",
   /* FLAG_INPUT_CSV */
  "  Value specifies an csv-file with inputs for the simulation/optimization of the model",
  /* FLAG_INPUT_FILE */
  "  Value specifies an external file with inputs for the simulation/optimization of the model.",
 /* FLAG_INPUT_FILE_STATES */
  "  Value specifies an file with states start values for the optimization of the model.",
  /* FLAG_IPOPT_HESSE */
  "  Value specifies the hessematrix for Ipopt(OMC, BFGS, const).",
  /* FLAG_IPOPT_INIT */
  "  Value specifies the initial guess for optimization (sim, const).",
  /* FLAG_IPOPT_JAC */
  "  Value specifies the jacobian for Ipopt(SYM, NUM, NUMDENSE).",
  /* FLAG_IPOPT_MAX_ITER */
  "  Value specifies the max number of iteration for ipopt.",
  /* FLAG_IPOPT_WARM_START */
  "  Value specifies lvl for a warm start in ipopt: 1,2,3,...",
  /* FLAG_JACOBIAN */
  "  Selects the type of the Jacobian that is used for the integrator:\n\n"
  "  * coloredNumerical (colored numerical Jacobian, the default).\n"
  "  * internalNumerical (internal dassl numerical Jacobian).\n"
  "  * coloredSymbolical (colored symbolical Jacobian. Only usable if the simulation is compiled with --generateSymbolicJacobian or --generateSymbolicLinearization.\n"
  "  * numerical - numerical Jacobian.\n\n"
  "  * symbolical - symbolical Jacobian. Only usable if the simulation is compiled with --generateSymbolicJacobian or --generateSymbolicLinearization.",
  /* FLAG_L */
  "  Value specifies a time where the linearization of the model should be performed.",
  /* FLAG_L_DATA_RECOVERY */
  "  Emit data recovery matrices with model linearization.",
  /* FLAG_LOG_FORMAT */
  "  Value specifies the log format of the executable:\n\n"
  "  * text (default)\n"
  "  * xml",
  /* FLAG_LS */
  "  Value specifies the linear solver method",
  /* FLAG_LS_IPOPT */
  "  Value specifies the linear solver method for Ipopt, default mumps.\n"
  "  Note: Use if you build ipopt with other linear solver like ma27",
  /* FLAG_LSS */
  "  Value specifies the linear sparse solver method",
  /* FLAG_LSS_MAX_DENSITY */
  "  Value specifies the maximum density for using a linear sparse solver.\n"
  "  The value is a Double with default value 0.2.",
  /* FLAG_LSS_MIN_SIZE */
  "  Value specifies the minimum system size for using a linear sparse solver.\n"
  "  The value is an Integer with default value 4001.",
  /* FLAG_LV */
  "  Value (a comma-separated String list) specifies which logging levels to\n"
  "  enable. Multiple options can be enabled at the same time.",
  /* FLAG_MAX_BISECTION_ITERATIONS */
  "  value specifies the maximum number of bisection iterations for state event\n"
  "  detection or zero for default behavior",
  /* FLAG_MAX_EVENT_ITERATIONS */
  "  Value specifies the maximum number of event iterations.\n"
  "  The value is an Integer with default value 20.",
  /* FLAG_MAX_ORDER */
  "  Value specifies maximum integration order, used by dassl solver.",
  /* FLAG_MAX_STEP_SIZE */
  "  Value specifies maximum absolute step size, used by dassl solver.",
  /* FLAG_MEASURETIMEPLOTFORMAT */
  "  Value specifies the output format of the measure time functionality\n\n"
  "  * svg\n"
  "  * jpg\n"
  "  * ps\n"
  "  * gif\n"
  "  * ...",
  /* FLAG_NEWTON_FTOL */
  "  Tolerance for accepting accuracy in Newton solver."
  "  The value is a Double with default value 1e-24.",
  /* FLAG_NEWTON_XTOL */
  "  Tolerance for updating solution vector in Newton solver."
  "  The value is a Double with default value 1e-24.",
  /* FLAG_NEWTON_STRATEGY */
  "  Value specifies the damping strategy for the newton solver.",
  /* FLAG_NLS */
  "  Value specifies the nonlinear solver:\n\n"
  "  * hybrid\n"
  "  * kinsol\n"
  "  * newton\n"
  "  * mixed",
  /* FLAG_NLS_INFO */
  "  Outputs detailed information about solving process of non-linear systems into csv files.",
  /* FLAG_NOEMIT */
  "  Do not emit any results to the result file.",
  /* FLAG_NOEQUIDISTANT_GRID */
  "  Output the internal steps given by dassl instead of interpolating results\n"
  "  into an equidistant time grid as given by stepSize or numberOfIntervals.",
  /* FLAG_NOEQUIDISTANT_OUT_FREQ*/
  "  Integer value n controls the output frequency in noEquidistantTimeGrid mode\n"
  "  and outputs every n-th time step",
  /* FLAG_NOEQUIDISTANT_OUT_TIME*/
  "  Real value timeValue controls the output time point in noEquidistantOutputTime\n"
  "  mode and outputs every time>=k*timeValue, where k is an integer",
  /* FLAG_NOEVENTEMIT */
  "  Do not emit event points to the result file.",
  /* FLAG_OPTDEBUGEJAC */
  "  Value specifies the number of itereations from the dynamic optimization, which\n"
  "  will be debugged, creating .csv and .py files.",
  /* FLAG_OPTIMIZER_NP */
  "  Value specifies the number of points in a subinterval.\n"
  "  Currently supports numbers 1 and 3.",
  /* FLAG_OPTIMIZER_TGRID */
  "  Value specifies external file with time points.",
  /* FLAG_OUTPUT */
  "  Output the variables a, b and c at the end of the simulation to the standard\n"
  "  output: time = value, a = value, b = value, c = value",
  /* FLAG_OVERRIDE */
  "  Override the variables or the simulation settings in the XML setup file\n"
  "  For example: var1=start1,var2=start2,par3=start3,startTime=val1,stopTime=val2",
  /* FLAG_OVERRIDE_FILE */
  "  Will override the variables or the simulation settings in the XML setup file\n"
  "  with the values from the file.\n"
  "  Note that: -overrideFile CANNOT be used with -override.\n"
  "  Use when variables for -override are too many.\n"
  "  overrideFileName contains lines of the form: var1=start1",
  /* FLAG_PORT */
  "  Value specifies the port for simulation status (default disabled).",
  /* FLAG_R */
  "  Value specifies the name of the output result file.\n"
  "  The default file-name is based on the model name and output format.\n"
  "  For example: Model_res.mat.",
  /* FLAG_RT */
  "  Value specifies the scaling factor for real-time synchronization (0 disables).\n"
  "  A value > 1 means the simulation takes a longer time to simulate.\n",
  /* FLAG_S */
  "  Value specifies the solver (integration method).",
  /* FLAG_UP_HESSIAN */
  "  Value specifies the number of steps, which keep hessian matrix constant.",
  /* FLAG_W */
  "  Shows all warnings even if a related log-stream is inactive.",

  "FLAG_MAX"
};

const int FLAG_TYPE[FLAG_MAX] = {
  FLAG_TYPE_UNKNOWN,

  /* FLAG_ABORT_SLOW */            FLAG_TYPE_FLAG,
  /* FLAG_ALARM */                 FLAG_TYPE_OPTION,
  /* FLAG_CLOCK */                 FLAG_TYPE_OPTION,
  /* FLAG_CPU */                   FLAG_TYPE_FLAG,
  /* FLAG_CSV_OSTEP */             FLAG_TYPE_OPTION,
  /* FLAG_DASSL_NO_RESTART */      FLAG_TYPE_FLAG,
  /* FLAG_DASSL_NO_ROOTFINDING */  FLAG_TYPE_FLAG,
  /* FLAG_DAE_SOLVING */           FLAG_TYPE_FLAG,
  /* FLAG_EMBEDDED_SERVER */       FLAG_TYPE_OPTION,
  /* FLAG_EMIT_PROTECTED */        FLAG_TYPE_FLAG,
  /* FLAG_F */                     FLAG_TYPE_OPTION,
  /* FLAG_HELP */                  FLAG_TYPE_OPTION,
  /* FLAG_IDA_LS */                FLAG_TYPE_OPTION,
  /* FLAG_IDAS */                  FLAG_TYPE_FLAG,
  /* FLAG_IGNORE_HIDERESULT */     FLAG_TYPE_FLAG,
  /* FLAG_IIF */                   FLAG_TYPE_OPTION,
  /* FLAG_IIM */                   FLAG_TYPE_OPTION,
  /* FLAG_IIT */                   FLAG_TYPE_OPTION,
  /* FLAG_ILS */                   FLAG_TYPE_OPTION,
  /* FLAG_INITIAL_STEP_SIZE */     FLAG_TYPE_OPTION,
  /* FLAG_INPUT_CSV */             FLAG_TYPE_OPTION,
  /* FLAG_INPUT_FILE */            FLAG_TYPE_OPTION,
  /* FLAG_INPUT_FILE_STATES */     FLAG_TYPE_OPTION,
  /* FLAG_IPOPT_HESSE */           FLAG_TYPE_OPTION,
  /* FLAG_IPOPT_INIT */            FLAG_TYPE_OPTION,
  /* FLAG_IPOPT_JAC */             FLAG_TYPE_OPTION,
  /* FLAG_IPOPT_MAX_ITER */        FLAG_TYPE_OPTION,
  /* FLAG_IPOPT_WARM_START */      FLAG_TYPE_OPTION,
  /* FLAG_JACOBIAN */              FLAG_TYPE_OPTION,
  /* FLAG_L */                     FLAG_TYPE_OPTION,
  /* FLAG_L_DATA_RECOVERY */       FLAG_TYPE_FLAG,
  /* FLAG_LOG_FORMAT */            FLAG_TYPE_OPTION,
  /* FLAG_LS */                    FLAG_TYPE_OPTION,
  /* FLAG_LS_IPOPT */              FLAG_TYPE_OPTION,
  /* FLAG_LSS */                   FLAG_TYPE_OPTION,
  /* FLAG_LSS_MAX_DENSITY */       FLAG_TYPE_OPTION,
  /* FLAG_LSS_MIN_SIZE */          FLAG_TYPE_OPTION,
  /* FLAG_LV */                    FLAG_TYPE_OPTION,
  /* FLAG_MAX_BISECTION_ITERATIONS */  FLAG_TYPE_OPTION,
  /* FLAG_MAX_EVENT_ITERATIONS */  FLAG_TYPE_OPTION,
  /* FLAG_MAX_ORDER */             FLAG_TYPE_OPTION,
  /* FLAG_MAX_STEP_SIZE */         FLAG_TYPE_OPTION,
  /* FLAG_MEASURETIMEPLOTFORMAT */ FLAG_TYPE_OPTION,
  /* FLAG_NEWTON_FTOL */           FLAG_TYPE_OPTION,
  /* FLAG_NEWTON_XTOL */           FLAG_TYPE_OPTION,
  /* FLAG_NEWTON_STRATEGY */       FLAG_TYPE_OPTION,
  /* FLAG_NLS */                   FLAG_TYPE_OPTION,
  /* FLAG_NLS_INFO */              FLAG_TYPE_FLAG,
  /* FLAG_NOEMIT */                FLAG_TYPE_FLAG,
  /* FLAG_NOEQUIDISTANT_GRID*/     FLAG_TYPE_FLAG,
  /* FLAG_NOEQUIDISTANT_OUT_FREQ*/ FLAG_TYPE_OPTION,
  /* FLAG_NOEQUIDISTANT_OUT_TIME*/ FLAG_TYPE_OPTION,
  /* FLAG_NOEVENTEMIT */           FLAG_TYPE_FLAG,
  /* FLAG_OPTDEBUGEJAC */          FLAG_TYPE_OPTION,
  /* FLAG_OPTIZER_NP */            FLAG_TYPE_OPTION,
  /* FLAG_OPTIZER_TGRID */         FLAG_TYPE_OPTION,
  /* FLAG_OUTPUT */                FLAG_TYPE_OPTION,
  /* FLAG_OVERRIDE */              FLAG_TYPE_OPTION,
  /* FLAG_OVERRIDE_FILE */         FLAG_TYPE_OPTION,
  /* FLAG_PORT */                  FLAG_TYPE_OPTION,
  /* FLAG_R */                     FLAG_TYPE_OPTION,
  /* FLAG_RT */                    FLAG_TYPE_OPTION,
  /* FLAG_S */                     FLAG_TYPE_OPTION,
  /* FLAG_UP_HESSIAN */            FLAG_TYPE_OPTION,
  /* FLAG_W */                     FLAG_TYPE_FLAG
};

const char *SOLVER_METHOD_NAME[S_MAX] = {
  "unknown",
  "euler",
  "rungekutta",
  "dassl",
  "optimization",
  "radau5",
  "radau3",
  "impeuler",
  "trapezoid",
  "lobatto4",
  "lobatto6",
  "symEuler",
  "symEulerSsc",
  "heun",
  "ida",
  "qss"
};

const char *SOLVER_METHOD_DESC[S_MAX] = {
  "unknown",
  "euler - Explicit Euler (order 1)",
  "rungekutta - Runge-Kutta (fixed step, order 4)",
  "dassl - BDF solver with colored numerical jacobian, with interval root finding - default",
  "optimization - Special solver for dynamic optimization",
  "radau5 - Radau IIA with 3 points, \"Implicit Runge-Kutta\", order 5 [sundial/kinsol needed]",
  "radau3 - Radau IIA with 2 points, \"Implicit Runge-Kutta\", order 3 [sundial/kinsol needed]",
  "impeuler - Implicit Euler (actually Radau IIA, order 1) [sundial/kinsol needed]",
  "trapezoid - Trapezoidal rule (actually Lobatto IIA with 2 points) [sundial/kinsol needed]",
  "lobatto4 - Lobatto IIA with 3 points, order 4 [sundial/kinsol needed]",
  "lobatto6 - Lobatto IIA with 4 points, order 6 [sundial/kinsol needed]",
  "symEuler - symbolic implicit euler, [compiler flag +symEuler needed]",
  "symEulerSsc - symbolic implicit euler with step-size control, [compiler flag +symEuler needed]",
  "heun - Heun's method (Runge-Kutta fixed step, order 2)",
  "ida - Sundials ida solver",
  "qss - A QSS solver [experimental]"
};

const char *INIT_METHOD_NAME[IIM_MAX] = {
  "unknown",
  "none",
  "symbolic"
};

const char *INIT_METHOD_DESC[IIM_MAX] = {
  "unknown",
  "sets all variables to their start values and skips the initialization process",
  "solves the initialization problem symbolically - default"
};

const char *LS_NAME[LS_MAX+1] = {
  "LS_UNKNOWN",

  /* LS_LAPACK */       "lapack",
#if !defined(OMC_MINIMAL_RUNTIME)
  /* LS_LIS */          "lis",
#endif
  /* LS_KLU */          "klu",
  /* LS_UMFPACK */      "umfpack",
  /* LS_TOTALPIVOT */   "totalpivot",
  /* LS_DEFAULT */      "default",

  "LS_MAX"
};

const char *LS_DESC[LS_MAX+1] = {
  "unknown",

  /* LS_LAPACK */       "method using lapack LU factorization",
#if !defined(OMC_MINIMAL_RUNTIME)
  /* LS_LIS */          "method using iterativ solver Lis",
#endif
  /* LS_KLU */          "method using klu sparse linear solver",
  /* LS_UMFPACK */      "method using umfpack sparse linear solver",
  /* LS_TOTALPIVOT */   "method using a total pivoting LU factorization for underdetermination systems",
  /* LS_DEFAULT */      "default method - lapack with total pivoting as fallback",

  "LS_MAX"
};

const char *LSS_NAME[LS_MAX+1] = {
  "LS_UNKNOWN",

#if !defined(OMC_MINIMAL_RUNTIME)
  /* LS_LIS */          "lis",
#endif
  /* LS_KLU */          "klu",
  /* LS_UMFPACK */      "umfpack",

  "LSS_MAX"
};

const char *LSS_DESC[LS_MAX+1] = {
  "unknown",

#if !defined(OMC_MINIMAL_RUNTIME)
  /* LS_LIS */          "method using iterativ solver Lis",
#endif
  /* LS_KLU */          "method using klu sparse linear solver",
  /* LS_UMFPACK */      "method using umfpack sparse linear solver",

  "LSS_MAX"
};

const char *NLS_NAME[NLS_MAX+1] = {
  "NLS_UNKNOWN",

#if !defined(OMC_MINIMAL_RUNTIME)
  /* NLS_HYBRID */       "hybrid",
  /* NLS_KINSOL */       "kinsol",
  /* NLS_NEWTON */       "newton",
#endif
  /* NLS_HOMOTOPY */     "homotopy",
#if !defined(OMC_MINIMAL_RUNTIME)
  /* NLS_MIXED */        "mixed",
#endif
  "NLS_MAX"
};

const char *NLS_DESC[NLS_MAX+1] = {
  "unknown",

#if !defined(OMC_MINIMAL_RUNTIME)
  /* NLS_HYBRID */       "Modification of the Powell hybrid method from minpack - former default solver",
  /* NLS_KINSOL */       "sundials/kinsol - prototype implementation",
  /* NLS_NEWTON */       "Newton Raphson - prototype implementation",
#endif
  /* NLS_HOMOTOPY */     "Damped Newton solver if failing case fixed-point and Newton homotopies are tried.",
#if !defined(OMC_MINIMAL_RUNTIME)
  /* NLS_MIXED */        "Mixed strategy. First the homotopy solver is tried and then as fallback the hybrid solver.",
#endif
  "NLS_MAX"
};

const char *NEWTONSTRATEGY_NAME[NEWTON_MAX+1] = {
  "NEWTON_UNKNOWN",

  /* NEWTON_DAMPED */       "damped",
  /* NEWTON_DAMPED2 */      "damped2",
  /* NEWTON_DAMPED_LS */    "damped_ls",
  /* NEWTON_DAMPED_BT */    "damped_bt",
  /* NEWTON_PURE */         "pure",

  "NEWTON_MAX"
};

const char *NEWTONSTRATEGY_DESC[NEWTON_MAX+1] = {
  "unknown",

  /* NEWTON_DAMPED */       "Newton with a damping strategy",
  /* NEWTON_DAMPED2 */      "Newton with a damping strategy 2",
  /* NEWTON_DAMPED_LS */    "Newton with a damping line search",
  /* NEWTON_DAMPED_BT */    "Newton with a damping backtracking and a minimum search via golden ratio method",
  /* NEWTON_PURE */         "Newton without damping strategy",

  "NEWTON_MAX"
};


const char *JACOBIAN_METHOD[JAC_MAX+1] = {
  "unknown",

  "coloredNumerical",
  "coloredSymbolical",
  "internalNumerical",
  "numerical",
  "symbolical",
  "kluSparse",
  "kluColored",

  "JAC_MAX"
};

const char *JACOBIAN_METHOD_DESC[JAC_MAX+1] = {
  "unknown",

  "colored numerical jacobian - default.",
  "colored symbolic jacobian - needs omc compiler flags +generateSymbolicJacobian or +generateSymbolicLinearization.",
  "internal numerical jacobian.",
  "numerical jacobian.",
  "symbolic jacobian - needs omc compiler flags +generateSymbolicJacobian or +generateSymbolicLinearization.",
  "sparse jacobian for KLU",
  "colored jacobian for KLU",

  "JAC_MAX"
 };

const char *IDA_LS_METHOD[IDA_LS_MAX+1] = {
  "unknown",

  "dense",
  "klu",
  "spgmr",
  "spbcg",
  "sptfqmr",

  "IDA_LS_MAX"
};

const char *IDA_LS_METHOD_DESC[IDA_LS_MAX+1] = {
  "unknown",

  "ida internal dense method",
  "ida use sparse direct solver KLU",
  "ida generalized minimal residual method. Iterativ method",
  "ida Bi-CGStab. Iterativ method",
  "ida TFQMR. Iterativ method",

  "IDA_LS_MAX"
};


