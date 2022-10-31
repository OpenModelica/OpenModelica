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

  /* FLAG_ABORT_SLOW */                   "abortSlowSimulation",
  /* FLAG_ALARM */                        "alarm",
  /* FLAG_CLOCK */                        "clock",
  /* FLAG_CPU */                          "cpu",
  /* FLAG_CSV_OSTEP */                    "csvOstep",
  /* FLAG_CVODE_ITER */                   "cvodeNonlinearSolverIteration",
  /* FLAG_CVODE_LMM */                    "cvodeLinearMultistepMethod",
  /* FLAG_DATA_RECONCILE_Cx */            "cx",
  /* FLAG_DAE_MODE */                     "daeMode",
  /* FLAG_DELTA_X_LINEARIZE */            "deltaXLinearize",
  /* FLAG_DELTA_X_SOLVER */               "deltaXSolver",
  /* FLAG_EMBEDDED_SERVER */              "embeddedServer",
  /* FLAG_EMBEDDED_SERVER_PORT */         "embeddedServerPort",
  /* FLAG_MAT_SYNC */                     "mat_sync",
  /* FLAG_EMIT_PROTECTED */               "emit_protected",
  /* FLAG_DATA_RECONCILE_Eps */           "eps",
  /* FLAG_F */                            "f",
  /* FLAG_HELP */                         "help",
  /* FLAG_HOMOTOPY_ADAPT_BEND */          "homAdaptBend",
  /* FLAG_HOMOTOPY_BACKTRACE_STRATEGY */  "homBacktraceStrategy",
  /* FLAG_HOMOTOPY_H_EPS */               "homHEps",
  /* FLAG_HOMOTOPY_MAX_LAMBDA_STEPS */    "homMaxLambdaSteps",
  /* FLAG_HOMOTOPY_MAX_NEWTON_STEPS */    "homMaxNewtonSteps",
  /* FLAG_HOMOTOPY_MAX_TRIES */           "homMaxTries",
  /* FLAG_HOMOTOPY_NEG_START_DIR */       "homNegStartDir",
  /* FLAG_HOMOTOPY_ON_FIRST_TRY */        "homotopyOnFirstTry",
  /* FLAG_NO_HOMOTOPY_ON_FIRST_TRY */     "noHomotopyOnFirstTry",
  /* FLAG_HOMOTOPY_TAU_DEC_FACTOR */      "homTauDecFac",
  /* FLAG_HOMOTOPY_TAU_DEC_FACTOR_PRED */ "homTauDecFacPredictor",
  /* FLAG_HOMOTOPY_TAU_INC_FACTOR */      "homTauIncFac",
  /* FLAG_HOMOTOPY_TAU_INC_THRESHOLD */   "homTauIncThreshold",
  /* FLAG_HOMOTOPY_TAU_MAX */             "homTauMax",
  /* FLAG_HOMOTOPY_TAU_MIN */             "homTauMin",
  /* FLAG_HOMOTOPY_TAU_START */           "homTauStart",
  /* FLAG_IDA_MAXERRORTESTFAIL */         "idaMaxErrorTestFails",
  /* FLAG_IDA_MAXNONLINITERS */           "idaMaxNonLinIters",
  /* FLAG_IDA_MAXCONVFAILS */             "idaMaxConvFails",
  /* FLAG_IDA_NONLINCONVCOEF */           "idaNonLinConvCoef",
  /* FLAG_IDA_LS */                       "idaLS",
  /* FLAG_IDA_SCALING */                  "idaScaling",
  /* FLAG_IDAS */                         "idaSensitivity",
  /* FLAG_IGNORE_HIDERESULT */            "ignoreHideResult",
  /* FLAG_IIF */                          "iif",
  /* FLAG_IIM */                          "iim",
  /* FLAG_IIT */                          "iit",
  /* FLAG_ILS */                          "ils",
  /* FLAG_IMPRK_ORDER */                  "impRKOrder",
  /* FLAG_IMPRK_LS */                     "impRKLS",
  /* FLAG_INITIAL_STEP_SIZE */            "initialStepSize",
  /* FLAG_INPUT_CSV */                    "csvInput",
  /* FLAG_INPUT_FILE_STATES */            "stateFile",
  /* FLAG_INPUT_PATH */                   "inputPath",
  /* FLAG_IPOPT_HESSE*/                   "ipopt_hesse",
  /* FLAG_IPOPT_INIT*/                    "ipopt_init",
  /* FLAG_IPOPT_JAC*/                     "ipopt_jac",
  /* FLAG_IPOPT_MAX_ITER */               "ipopt_max_iter",
  /* FLAG_IPOPT_WARM_START */             "ipopt_warm_start",
  /* FLAG_JACOBIAN */                     "jacobian",
  /* FLAG_JACOBIAN_THREADS */             "jacobianThreads",
  /* FLAG_L */                            "l",
  /* FLAG_L_DATA_RECOVERY */              "l_datarec",
  /* FLAG_LOG_FORMAT */                   "logFormat",
  /* FLAG_LS */                           "ls",
  /* FLAG_LS_IPOPT */                     "ls_ipopt",
  /* FLAG_LSS */                          "lss",
  /* FLAG_LSS_MAX_DENSITY */              "lssMaxDensity",
  /* FLAG_LSS_MIN_SIZE */                 "lssMinSize",
  /* FLAG_LV */                           "lv",
  /* FLAG_LV_TIME */                      "lv_time",
  /* FLAG_MAX_BISECTION_ITERATIONS */     "mbi",
  /* FLAG_MAX_EVENT_ITERATIONS */         "mei",
  /* FLAG_MAX_ORDER */                    "maxIntegrationOrder",
  /* FLAG_MAX_STEP_SIZE */                "maxStepSize",
  /* FLAG_MEASURETIMEPLOTFORMAT */        "measureTimePlotFormat",
  /* FLAG_NEWTON_FTOL */                  "newtonFTol",
  /* FLAG_NEWTON_MAX_STEP_FACTOR */       "newtonMaxStepFactor",
  /* FLAG_NEWTON_XTOL */                  "newtonXTol",
  /* FLAG_NEWTON_STRATEGY */              "newton",
  /* FLAG_NLS */                          "nls",
  /* FLAG_NLS_INFO */                     "nlsInfo",
  /* FLAG_NLS_LS */                       "nlsLS",
  /* FLAG_NLSS_MAX_DENSITY */             "nlssMaxDensity",
  /* FLAG_NLSS_MIN_SIZE */                "nlssMinSize",
  /* FLAG_NOEMIT */                       "noemit",
  /* FLAG_NOEQUIDISTANT_GRID */           "noEquidistantTimeGrid",
  /* FLAG_NOEQUIDISTANT_OUT_FREQ*/        "noEquidistantOutputFrequency",
  /* FLAG_NOEQUIDISTANT_OUT_TIME*/        "noEquidistantOutputTime",
  /* FLAG_NOEVENTEMIT */                  "noEventEmit",
  /* FLAG_NO_RESTART */                   "noRestart",
  /* FLAG_NO_ROOTFINDING */               "noRootFinding",
  /* FLAG_NO_SCALING */                   "noScaling",
  /* FLAG_NO_SUPPRESS_ALG */              "noSuppressAlg",
  /* FLAG_OPTDEBUGEJAC */                 "optDebugJac",
  /* FLAG_OPTIMIZER_NP */                 "optimizerNP",
  /* FLAG_OPTIMIZER_TGRID */              "optimizerTimeGrid",
  /* FLAG_OUTPUT */                       "output",
  /* FLAG_OUTPUT_PATH */                  "outputPath",
  /* FLAG_OVERRIDE */                     "override",
  /* FLAG_OVERRIDE_FILE */                "overrideFile",
  /* FLAG_PORT */                         "port",
  /* FLAG_R */                            "r",
  /* FLAG_DATA_RECONCILE  */              "reconcile",
  /* FLAG_DATA_RECONCILE_BOUNDARY */      "reconcileBoundaryConditions",
  /* FLAG_SR */                           "gbm",
  /* FLAG_SR_CTRL */                      "gbctrl",
  /* FLAG_SR_ERR */                       "gberr",
  /* FLAG_SR_INT */                       "gbint",
  /* FLAG_SR_NLS */                       "gbnls",
  /* FLAG_MR */                           "gbfm",
  /* FLAG_MR_CTRL */                      "gbfctrl",
  /* FLAG_MR_ERR */                       "gbferr",
  /* FLAG_MR_INT */                       "gbfint",
  /* FLAG_MR_NLS */                       "gbfnls",
  /* FLAG_MR_PAR */                       "gbratio",
  /* FLAG_RT */                           "rt",
  /* FLAG_S */                            "s",
  /* FLAG_SINGLE_PRECISION */             "single",
  /* FLAG_SOLVER_STEPS */                 "steps",
  /* FLAG_STEADY_STATE */                 "steadyState",
  /* FLAG_STEADY_STATE_TOL */             "steadyStateTol",
  /* FLAG_DATA_RECONCILE_Sx */            "sx",
  /* FLAG_UP_HESSIAN */                   "keepHessian",
  /* FLAG_W */                            "w",
  /* FLAG_PARMODNUMTHREADS */             "parmodNumThreads",

  "FLAG_MAX"
};

const char *FLAG_DESC[FLAG_MAX+1] = {
  "unknown",

  /* FLAG_ABORT_SLOW */                   "aborts if the simulation chatters",
  /* FLAG_ALARM */                        "aborts after the given number of seconds (0 disables)",
  /* FLAG_CLOCK */                        "selects the type of clock to use -clock=RT, -clock=CYC or -clock=CPU",
  /* FLAG_CPU */                          "dumps the cpu-time into the result file",
  /* FLAG_CSV_OSTEP */                    "value specifies csv-files for debug values for optimizer step",
  /* FLAG_CVODE_ITER */                   "nonlinear solver iteration for CVODE solver",
  /* FLAG_CVODE_LMM */                    "linear multistep method for CVODE solver",
  /* FLAG_DATA_RECONCILE_Cx */            "value specifies a csv-file with inputs as correlation coefficient matrix Cx for DataReconciliation",
  /* FLAG_DAE_MODE */                     "flag to let the integrator use daeResiduals",
  /* FLAG_DELTA_X_LINEARIZE */            "value specifies the delta x value for numerical differentiation used by linearization. The default value is 1e-5.",
  /* FLAG_DELTA_X_SOLVER */               "value specifies the delta x value for numerical differentiation used by integrator. The default values is sqrt(DBL_EPSILON).",
  /* FLAG_EMBEDDED_SERVER */              "enables an embedded server. Valid values: none, opc-da [broken], opc-ua [experimental], or the path to a shared object.",
  /* FLAG_EMBEDDED_SERVER_PORT */         "[int (default 4841)] value specifies the port number used by the embedded server",
  /* FLAG_MAT_SYNC */                     "[int (default 0)] syncs the mat file header after emitting every N time-points (default disabled)",
  /* FLAG_EMIT_PROTECTED */               "emits protected variables to the result-file",
  /* FLAG_DATA_RECONCILE_Eps */           "value specifies the number of convergence iteration to be performed for DataReconciliation",
  /* FLAG_F */                            "value specifies a new setup XML file to the generated simulation code",
  /* FLAG_HELP */                         "get detailed information that specifies the command-line flag",
  /* FLAG_HOMOTOPY_ADAPT_BEND */          "[double (default 0.5)] maximum trajectory bending to accept the homotopy step",
  /* FLAG_HOMOTOPY_BACKTRACE_STRATEGY */  "value specifies the backtrace strategy in the homotopy corrector step (fix (default), orthogonal)",
  /* FLAG_HOMOTOPY_H_EPS */               "[double (default 1e-5)] tolerance respecting residuals for the homotopy H-function",
  /* FLAG_HOMOTOPY_MAX_LAMBDA_STEPS */    "[int (default size dependent)] maximum lambda steps allowed to run the homotopy path",
  /* FLAG_HOMOTOPY_MAX_NEWTON_STEPS */    "[int (default 20)] maximum newton steps in the homotopy corrector step",
  /* FLAG_HOMOTOPY_MAX_TRIES */           "[int (default 10)] maximum number of tries for one homotopy lambda step",
  /* FLAG_HOMOTOPY_NEG_START_DIR */       "start to run along the homotopy path in the negative direction",
  /* FLAG_HOMOTOPY_ON_FIRST_TRY */        "directly use the homotopy method to solve the initialization problem",
  /* FLAG_NO_HOMOTOPY_ON_FIRST_TRY */     "disable the use of the homotopy method to solve the initialization problem",
  /* FLAG_HOMOTOPY_TAU_DEC_FACTOR */      "[double (default 10.0)] decrease homotopy step size tau by this factor if tau is too big in the homotopy corrector step",
  /* FLAG_HOMOTOPY_TAU_DEC_FACTOR_PRED */ "[double (default 2.0)] decrease homotopy step size tau by this factor if tau is too big in the homotopy predictor step",
  /* FLAG_HOMOTOPY_TAU_INC_FACTOR */      "[double (default 2.0)] increase homotopy step size tau by this factor if tau is too small in the homotopy corrector step",
  /* FLAG_HOMOTOPY_TAU_INC_THRESHOLD */   "[double (default 10.0)] increase the homotopy step size tau if bend < homAdaptBend/homTauIncThreshold",
  /* FLAG_HOMOTOPY_TAU_MAX */             "[double (default 10.0)] maximum homotopy step size tau for the homotopy process",
  /* FLAG_HOMOTOPY_TAU_MIN */             "[double (default 1e-4)] minimum homotopy step size tau for the homotopy process",
  /* FLAG_HOMOTOPY_TAU_START */           "[double (default 0.2)] homotopy step size tau at the beginning of the homotopy process",
  /* FLAG_IDA_MAXERRORTESTFAIL */         "value specifies the maximum number of error test failures in attempting one step. The default value is 7.",
  /* FLAG_IDA_MAXNONLINITERS */           "value specifies the maximum number of nonlinear solver iterations at one step. The default value is 3.",
  /* FLAG_IDA_MAXCONVFAILS */             "value specifies the maximum number of nonlinear solver convergence failures at one step. The default value is 10.",
  /* FLAG_IDA_NONLINCONVCOEF */           "value specifies the safety factor in the nonlinear convergence test. The default value is 0.33.",
  /* FLAG_IDA_LS */                       "select the linear solver used by ida",
  /* FLAG_IDA_SCALING */                  "enable scaling of the IDA solver",
  /* FLAG_IDAS */                         "flag to add sensitivity information to the result files",
  /* FLAG_IGNORE_HIDERESULT */            "ignore HideResult=true annotation",
  /* FLAG_IIF */                          "value specifies an external file for the initialization of the model relative to -inputPath",
  /* FLAG_IIM */                          "value specifies the initialization method",
  /* FLAG_IIT */                          "[double] value specifies a time for the initialization of the model",
  /* FLAG_ILS */                          "[int (default 3)] number of lambda steps for homotopy methods",
  /* FLAG_IMPRK_ORDER */                  "[int (default 5)] value specifies the integration order of the implicit Runge-Kutta method. Valid values: 1-6",
  /* FLAG_IMPRK_LS */                     "selects the linear solver of the integration methods: impeuler, trapezoid and imprungekuta",
  /* FLAG_INITIAL_STEP_SIZE */            "value specifies an initial step size for supported solver",
  /* FLAG_INPUT_CSV */                    "value specifies an csv-file with inputs for the simulation/optimization of the model",
  /* FLAG_INPUT_FILE_STATES */            "value specifies an file with states start values for the optimization of the model",
  /* FLAG_INPUT_PATH */                   "value specifies a path for reading the input files i.e., model_init.xml and model_info.json",
  /* FLAG_IPOPT_HESSE */                  "value specifies the hessian for Ipopt",
  /* FLAG_IPOPT_INIT */                   "value specifies the initial guess for optimization",
  /* FLAG_IPOPT_JAC */                    "value specifies the Jacobian for Ipopt",
  /* FLAG_IPOPT_MAX_ITER */               "value specifies the max number of iteration for ipopt",
  /* FLAG_IPOPT_WARM_START */             "value specifies lvl for a warm start in ipopt: 1,2,3,...",
  /* FLAG_JACOBIAN */                     "select the calculation method of the Jacobian used only by ida and dassl solver.",
  /* FLAG_JACOBIAN_THREADS */             "[int default: 1] value specifies the number of threads for jacobian evaluation in dassl or ida.",
  /* FLAG_L */                            "value specifies a time where the linearization of the model should be performed",
  /* FLAG_L_DATA_RECOVERY */              "emit data recovery matrices with model linearization",
  /* FLAG_LOG_FORMAT */                   "value specifies the log format of the executable. -logFormat=text (default), -logFormat=xml or -logFormat=xmltcp",
  /* FLAG_LS */                           "value specifies the linear solver method (default: lapack, totalpivot (fallback))",
  /* FLAG_LS_IPOPT */                     "value specifies the linear solver method for ipopt",
  /* FLAG_LSS */                          "value specifies the linear sparse solver method (default: umfpack)",
  /* FLAG_LSS_MAX_DENSITY */              "[double (default " EXPANDSTRING(DEFAULT_FLAG_LSS_MAX_DENSITY) ")] value specifies the maximum density for using a linear sparse solver",
  /* FLAG_LSS_MIN_SIZE */                 "[int (default " EXPANDSTRING(DEFAULT_FLAG_LSS_MIN_SIZE) ")] value specifies the minimum system size for using a linear sparse solver",
  /* FLAG_LV */                           "[string list] value specifies the logging level",
  /* FLAG_LV_TIME */                      "[double list] specifying time interval to allow loging in",
  /* FLAG_MAX_BISECTION_ITERATIONS */     "[int (default 0)] value specifies the maximum number of bisection iterations for state event detection or zero for default behavior",
  /* FLAG_MAX_EVENT_ITERATIONS */         "[int (default 20)] value specifies the maximum number of event iterations",
  /* FLAG_MAX_ORDER */                    "value specifies maximum integration order for supported solver",
  /* FLAG_MAX_STEP_SIZE */                "value specifies maximum absolute step size for supported solver",
  /* FLAG_MEASURETIMEPLOTFORMAT */        "value specifies the output format of the measure time functionality",
  /* FLAG_NEWTON_FTOL */                  "[double (default 1e-12)] tolerance respecting residuals for updating solution vector in Newton solver",
  /* FLAG_NEWTON_MAX_STEP_FACTOR */       "[double (default 1e12)] maximum newton step factor mxnewtstep = maxStepFactor * norm2(xScaling). Used currently only by KINSOL.",
  /* FLAG_NEWTON_XTOL */                  "[double (default 1e-12)] tolerance respecting newton correction (delta_x) for updating solution vector in Newton solver",
  /* FLAG_NEWTON_STRATEGY */              "value specifies the damping strategy for the newton solver",
  /* FLAG_NLS */                          "value specifies the nonlinear solver",
  /* FLAG_NLS_INFO */                     "outputs detailed information about solving process of non-linear systems into csv files.",
  /* FLAG_NLS_LS */                       "value specifies the linear solver used by the non-linear solver",
  /* FLAG_NLSS_MAX_DENSITY */             "[double (default " EXPANDSTRING(DEFAULT_FLAG_NLSS_MAX_DENSITY) ")] value specifies the maximum density for using a non-linear sparse solver",
  /* FLAG_NLSS_MIN_SIZE */                "[int (default " EXPANDSTRING(DEFAULT_FLAG_NLSS_MIN_SIZE) ")] value specifies the minimum system size for using a non-linear sparse solver",
  /* FLAG_NOEMIT */                       "do not emit any results to the result file",
  /* FLAG_NOEQUIDISTANT_GRID */           "stores results not in equidistant time grid as given by stepSize or numberOfIntervals, instead the variable step size of dassl or ida integrator.",
  /* FLAG_NOEQUIDISTANT_OUT_FREQ*/        "value controls the output frequency in noEquidistantTimeGrid mode",
  /* FLAG_NOEQUIDISTANT_OUT_TIME*/        "value controls the output time point in noEquidistantOutputTime mode",
  /* FLAG_NOEVENTEMIT */                  "do not emit event points to the result file",
  /* FLAG_NO_RESTART */                   "disables the restart of the integration method after an event is performed, used by the methods: dassl, ida",
  /* FLAG_NO_ROOTFINDING */               "disables the internal root finding procedure of methods: dassl and ida.",
  /* FLAG_NO_SCALING */                   "disables scaling for the variables and the residuals in the algebraic nonlinear solver KINSOL.",
  /* FLAG_NO_SUPPRESS_ALG */              "flag to not suppress algebraic variables in the local error test of ida solver in daeMode",
  /* FLAG_OPTDEBUGEJAC */                 "value specifies the number of iter from the dyn. optimization, which will be debug, creating *csv and *py file",
  /* FLAG_OPTIMIZER_NP */                 "value specifies the number of points in a subinterval",
  /* FLAG_OPTIMIZER_TGRID */              "value specifies external file with time points.",
  /* FLAG_OUTPUT */                       "output the variables a, b and c at the end of the simulation to the standard output",
  /* FLAG_OUTPUT_PATH */                  "value specifies a path for writing the output files i.e., model_res.mat, model_prof.intdata, model_prof.realdata etc.",
  /* FLAG_OVERRIDE */                     "override the variables or the simulation settings in the XML setup file",
  /* FLAG_OVERRIDE_FILE */                "will override the variables or the simulation settings in the XML setup file with the values from the file",
  /* FLAG_PORT */                         "value specifies the port for simulation status (default disabled)",
  /* FLAG_R */                            "value specifies a new result file than the default Model_res.mat",
  /* FLAG_DATA_RECONCILE */               "Run the Data Reconciliation numerical computation algorithm for constrained equations",
  /* FLAG_DATA_RECONCILE_BOUNDARY */      "Run the Data Reconciliation numerical computation algorithm for boundary condition equations",
  /* FLAG_SR */                           "Value specifies the chosen solver of solver gbode (single-rate, slow states integrator)",
  /* FLAG_SR_CTRL */                      "Step size control of solver gbode (single-rate, slow states integrator)",
  /* FLAG_SR_ERR */                       "Error estimation done by Richardson extrapolation  (-gberr=1) of solver gbode (single-rate, slow states integrator)",
  /* FLAG_SR_INT */                       "Interpolation method of solver gbode (single-rate, slow states integrator)",
  /* FLAG_SR_NLS */                       "Non-linear solver method of solver gbode (single-rate, slow states integrator)",
  /* FLAG_MR */                           "Value specifies the chosen solver of solver gbode (multi-rate, fast states integrator)",
  /* FLAG_MR_CTRL */                      "Step size control of solver gbode (multi-rate, fast states integrator)",
  /* FLAG_MR_ERR */                       "Error estimation done by Richardson extrapolation  (-gberr=1) of solver gbode (multi-rate, fast states integrator)",
  /* FLAG_MR_INT */                       "Interpolation method of solver gbode (multi-rate, fast states integrator)",
  /* FLAG_MR_NLS */                       "Non-linear solver method of solver gbode (multi-rate, fast states integrator)",
  /* FLAG_MR_PAR */                       "Define percentage of states for the fast states selection of solver gbode",
  /* FLAG_RT */                           "value specifies the scaling factor for real-time synchronization (0 disables)",
  /* FLAG_S */                            "value specifies the integration method",
  /* FLAG_SINGLE */                       "output in single precision",
  /* FLAG_SOLVER_STEPS */                 "dumps the number of integration steps into the result file",
  /* FLAG_STEADY_STATE */                 "aborts if steady state is reached",
  /* FLAG_STEADY_STATE_TOL */             "[double (default 1e-3)] This relative tolerance is used to detect steady state.",
  /* FLAG_DATA_RECONCILE_Sx */            "value specifies a csv-file with inputs as covariance matrix Sx for DataReconciliation",
  /* FLAG_UP_HESSIAN */                   "value specifies the number of steps, which keep hessian matrix constant",
  /* FLAG_W */                            "shows all warnings even if a related log-stream is inactive",
  /* FLAG_PARMODNUMTHREADS */             "[int default: 0] value specifies the number of threads for simulation using parmodauto. If not specified (or is 0) it will use the systems max number of threads. Note that this option is ignored if the model is not compiled with --parmodauto",

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
  "  Dumps the cpu-time into the result file using the variable named $cpuTime.",
  /* FLAG_CSV_OSTEP */
  "  Value specifies csv-files for debug values for optimizer step.",
  /* FLAG_CVODE_ITER */
  "  Nonlinear solver iteration for CVODE solver. Default: Depends on flag cvodeLinearMultistepMethod. Valid values\n\n"
  "  * CV_ITER_NEWTON       - Newton iteration.\n"
  "                           Advised to use together with flag -cvodeLinearMultistepMethod=CV_BDF.\n"
  "  * CV_ITER_FIXED_POINT  - Fixed-Point iteration iteration.\n"
  "                           Advised to use together with flag -cvodeLinearMultistepMethod=CV_ADAMS.",
  /* FLAG_CVODE_LMM */
  "  Linear multistep method for CVODE solver. Default: CV_BDF. Valid values\n\n"
  "  * CV_BDF    - BDF linear multistep method for stiff problems.\n"
  "                Use together with flag -cvodeNonlinearSolverIteration=CV_ITER_NEWTON or don't set cvodeNonlinearSolverIteration.\n"
  "  * CV_ADAMS  - Adams-Moulton linear multistep method for nonstiff problems.\n"
  "                Use together with flag -cvodeNonlinearSolverIteration=CV_ITER_FIXED_POINT or don't set cvodeNonlinearSolverIteration.",
  /* FLAG_DATA_RECONCILE_Cx */
  "  Value specifies an csv-file with inputs as correlation coefficient matrix Cx for DataReconciliation",
  /* FLAG_DAE_MODE */
  "  Enables daeMode simulation if the model was compiled with the omc flag --daeMode and ida method is used.",
  /* FLAG_DELTA_X_LINEARIZE */
  "  Value specifies the delta x value for numerical differentiation used by linearization. The default value is sqrt(DBL_EPSILON*2e1).",
  /* FLAG_DELTA_X_SOLVER */
  "  Value specifies the delta x value for numerical differentiation used by integration method. The default values is sqrt(DBL_EPSILON).",
  /* FLAG_EMBEDDED_SERVER */
  "  Enables an embedded server. Valid values:\n\n"
  "  * none - default, run without embedded server\n"
  "  * opc-da - [broken] run with embedded OPC DA server (WIN32 only, uses proprietary OPC SC interface)\n"
  "  * opc-ua - [experimental] run with embedded OPC UA server (TCP port 4841 for now; will have its own configuration option later)\n"
  "  * filename - path to a shared object implementing the embedded server interface (requires access to internal OMC data-structures if you want to read or write data)",
  /* FLAG_EMBEDDED_SERVER_PORT */
  "  Value specifies the port number used by the embedded server. The default value is 4841.",
  /* FLAG_MAT_SYNC */
  "  Syncs the mat file header after emitting every N time-points.",
  /* FLAG_EMIT_PROTECTED */
  "  Emits protected variables to the result-file.",
  /* FLAG_DATA_RECONCILE_Eps */
  "  Value specifies the number of convergence iteration to be performed for DataReconciliation",
  /* FLAG_F */
  "  Value specifies a new setup XML file to the generated simulation code.\n",
  /* FLAG_HELP */
  "  Get detailed information that specifies the command-line flag\n\n"
  "  For example, -help=f prints detailed information for command-line flag f.",
  /* FLAG_HOMOTOPY_ADAPT_BEND */
  "  Maximum trajectory bending to accept the homotopy step.\n"
  "  Default: 0.5, which means the corrector vector has to be smaller than half of the predictor vector.",
  /* FLAG_HOMOTOPY_BACKTRACE_STRATEGY */
  "  Value specifies the backtrace strategy in the homotopy corrector step. Valid values:\n\n"
  "  * fix - default, go back to the path by fixing one coordinate\n"
  "  * orthogonal - go back to the path in an orthogonal direction to the tangent vector",
  /* FLAG_HOMOTOPY_H_EPS */
  "  Tolerance respecting residuals for the homotopy H-function (default: 1e-5).\n\n"
  "  In the last step (lambda=1) newtonFTol is used as tolerance.",
  /* FLAG_HOMOTOPY_MAX_LAMBDA_STEPS */
  "  Maximum lambda steps allowed to run the homotopy path (default: system size * 100).",
  /* FLAG_HOMOTOPY_MAX_NEWTON_STEPS */
  "  Maximum newton steps in the homotopy corrector step (default: 20).",
  /* FLAG_HOMOTOPY_MAX_TRIES */
  "  Maximum number of tries for one homotopy lambda step (default: 10).",
  /* FLAG_HOMOTOPY_NEG_START_DIR */
  "  Start to run along the homotopy path in the negative direction.\n\n"
  "  If one direction fails, the other direction is always used as fallback option.",
  /* FLAG_HOMOTOPY_ON_FIRST_TRY */
  "  If the model contains the homotopy operator, directly use the homotopy method to solve the initialization problem.\n"
  "  This is already the default behaviour, this flag can be used to undo the effect of -noHomotopyOnFirstTry",
  /* FLAG_NO_HOMOTOPY_ON_FIRST_TRY */
  "  Disable the use of the homotopy method to solve the initialization problem.\n"
  "  Without this flag, the solver tries to solve the initialization problem with homotopy if the model contains the homotopy-operator.",
  /* FLAG_HOMOTOPY_TAU_DEC_FACTOR */
  "  Decrease homotopy step size tau by this factor if tau is too big in the homotopy corrector step (default: 10.0).",
  /* FLAG_HOMOTOPY_TAU_DEC_FACTOR_PRED */
  "  Decrease homotopy step size tau by this factor if tau is too big in the homotopy predictor step (default: 2.0).",
  /* FLAG_HOMOTOPY_TAU_INC_FACTOR */
  "  Increase homotopy step size tau by this factor if tau can be increased after the homotopy corrector step (default: 2.0).",
  /* FLAG_HOMOTOPY_TAU_INC_THRESHOLD */
  "  Increase the homotopy step size tau if homAdaptBend/bend > homTauIncThreshold (default: 10).",
  /* FLAG_HOMOTOPY_TAU_MAX */
  "  Maximum homotopy step size tau for the homotopy process (default: 10).",
  /* FLAG_HOMOTOPY_TAU_MIN */
  "  Minimum homotopy step size tau for the homotopy process (default: 1e-4).",
  /* FLAG_HOMOTOPY_TAU_START */
  "  Homotopy step size tau at the beginning of the homotopy process (default: 0.2).",
  /* FLAG_IDA_MAXERRORTESTFAIL */
  "  Value specifies the maximum number of error test failures in attempting one step. The default value is 7.",
  /* FLAG_IDA_MAXNONLINITERS */
  "  Value specifies the maximum number of nonlinear solver iterations at one step. The default value is 3.",
  /* FLAG_IDA_MAXCONVFAILS */
  "  Value specifies the maximum number of nonlinear solver convergence failures at one step. The default value is 10.",
  /* FLAG_IDA_NONLINCONVCOEF */
  "  Value specifies the safety factor in the nonlinear convergence test. The default value is 0.33.",
  /* FLAG_IDA_LS */
  "  Value specifies the linear solver of the ida integration method. Valid values:\n",
  /* FLAG_IDA_SCALING */
  "  Enable scaling of the IDA solver.",
  /* FLAG_IDAS */
  "  Enables sensitivity analysis with respect to parameters if the model is compiled with omc flag --calculateSensitivities.",
  /* FLAG_IGNORE_HIDERESULT */
  "  Emits also variables with HideResult=true annotation.",
  /* FLAG_IIF */
  "  Value specifies an external file for the initialization of the model.",
  /* FLAG_IIM */
  "  Value specifies the initialization method.\n  Following options are available: 'symbolic' (default) and 'none'.",
  /* FLAG_IIT */
  "  Value [Real] specifies a time for the initialization of the model.",
  /* FLAG_ILS */
  "  Value specifies the number of steps for homotopy method (required: -iim=symbolic).\n"
  "  The value is an Integer with default value 3.",
  /* FLAG_IMPRK_ORDER */
  "  Value specifies the integration order of the implicit Runge-Kutta method. Valid values: 1 to 6. Default order is 5.",
  /* FLAG_IMPRK_LS */
  "  Selects the linear solver of the integration methods impeuler, trapezoid and imprungekuta:\n\n"
  "  * iterativ - default, sparse iterativ linear solver with fallback case to dense solver\n"
  "  * dense - dense linear solver, SUNDIALS default method",
  /* FLAG_INITIAL_STEP_SIZE */
  "  Value specifies an initial step size, used by the methods: dassl, ida",
  /* FLAG_INPUT_CSV */
  "  Value specifies an csv-file with inputs for the simulation/optimization of the model",
  /* FLAG_INPUT_FILE_STATES */
  "  Value specifies an file with states start values for the optimization of the model.",
  /* FLAG_INPUT_PATH */
  "  Value specifies a path for reading the input files i.e., model_init.xml and model_info.json",
  /* FLAG_IPOPT_HESSE */
  "  Value specifies the hessematrix for Ipopt(OMC, BFGS, const).",
  /* FLAG_IPOPT_INIT */
  "  Value specifies the initial guess for optimization (sim, const).",
  /* FLAG_IPOPT_JAC */
  "  Value specifies the Jacobian for Ipopt(SYM, NUM, NUMDENSE).",
  /* FLAG_IPOPT_MAX_ITER */
  "  Value specifies the max number of iteration for ipopt.",
  /* FLAG_IPOPT_WARM_START */
  "  Value specifies lvl for a warm start in ipopt: 1,2,3,...",
  /* FLAG_JACOBIAN */
  "  Select the calculation method for Jacobian used by the integration method:\n",
  /* FLAG_JACOBIAN_THREADS */
  "  Value specifies the number of threads for jacobian evaluation in dassl or ida."
  "  The value is an Integer with default value 1.",
  /* FLAG_L */
  "  Value specifies a time where the linearization of the model should be performed.",
  /* FLAG_L_DATA_RECOVERY */
  "  Emit data recovery matrices with model linearization.",
  /* FLAG_LOG_FORMAT */
  "  Value specifies the log format of the executable:\n\n"
  "  * text (default)\n"
  "  * xml\n"
  "  * xmltcp (required -port flag)",
  /* FLAG_LS */
  "  Value specifies the linear solver method",
  /* FLAG_LS_IPOPT */
  "  Value specifies the linear solver method for Ipopt, default mumps.\n"
  "  Note: Use if you build ipopt with other linear solver like ma27",
  /* FLAG_LSS */
  "  Value specifies the linear sparse solver method",
  /* FLAG_LSS_MAX_DENSITY */
  "  Value specifies the maximum density for using a linear sparse solver.\n"
  "  The value is a Double with default value " EXPANDSTRING(DEFAULT_FLAG_LSS_MAX_DENSITY) ".",
  /* FLAG_LSS_MIN_SIZE */
  "  Value specifies the minimum system size for using a linear sparse solver.\n"
  "  The value is an Integer with default value " EXPANDSTRING(DEFAULT_FLAG_LSS_MIN_SIZE) ".",
  /* FLAG_LV */
  "  Value (a comma-separated String list) specifies which logging levels to\n"
  "  enable. Multiple options can be enabled at the same time.",
  /* FLAG_LV_TIME */
  "  Interval (a comma-separated Double list with two elements) specifies in which\n"
  "  time interval logging is active. Doesn't affect LOG_STDOUT, LOG_ASSERT, and\n"
  "  LOG_SUCCESS, LOG_STATS, LOG_STATS_V.",
  /* FLAG_MAX_BISECTION_ITERATIONS */
  "  Value specifies the maximum number of bisection iterations for state event\n"
  "  detection or zero for default behavior",
  /* FLAG_MAX_EVENT_ITERATIONS */
  "  Value specifies the maximum number of event iterations.\n"
  "  The value is an Integer with default value 20.",
  /* FLAG_MAX_ORDER */
  "  Value specifies maximum integration order, used by the methods: dassl, ida.",
  /* FLAG_MAX_STEP_SIZE */
  "  Value specifies maximum absolute step size, used by the methods: dassl, ida.",
  /* FLAG_MEASURETIMEPLOTFORMAT */
  "  Value specifies the output format of the measure time functionality:\n\n"
  "  * svg\n"
  "  * jpg\n"
  "  * ps\n"
  "  * gif\n"
  "  * ...",
  /* FLAG_NEWTON_FTOL */
  "  Tolerance respecting residuals for updating solution vector in Newton solver.\n"
  "  Solution is accepted if the (scaled) 2-norm of the residuals is smaller than the tolerance newtonFTol and the (scaled) newton correction (delta_x) is smaller than the tolerance newtonXTol.\n"
  "  The value is a Double with default value 1e-12.",
  /* FLAG_NEWTON_MAX_STEP_FACTOR */
  "  Maximum newton step factor mxnewtstep = maxStepFactor * norm2(xScaling)."
  "  Used currently only by KINSOL.",
  /* FLAG_NEWTON_XTOL */
  "  Tolerance respecting newton correction (delta_x) for updating solution vector in Newton solver.\n"
  "  Solution is accepted if the (scaled) 2-norm of the residuals is smaller than the tolerance newtonFTol and the (scaled) newton correction (delta_x) is smaller than the tolerance newtonXTol.\n"
  "  The value is a Double with default value 1e-12.",
  /* FLAG_NEWTON_STRATEGY */
  "  Value specifies the damping strategy for the newton solver.",
  /* FLAG_NLS */
  "  Value specifies the nonlinear solver:",
  /* FLAG_NLS_INFO */
  "  Outputs detailed information about solving process of non-linear systems into csv files.",
  /* FLAG_NLS_LS */
  "  Value specifies the linear solver used by the non-linear solver:",
  /* FLAG_NLSS_MAX_DENSITY */
  "  Value specifies the maximum density for using a non-linear sparse solver.\n"
  "  The value is a Double with default value " EXPANDSTRING(DEFAULT_FLAG_NLSS_MAX_DENSITY) ".",
  /* FLAG_NLSS_MIN_SIZE */
  "  Value specifies the minimum system size for using a non-linear sparse solver.\n"
  "  The value is an Integer with default value " EXPANDSTRING(DEFAULT_FLAG_NLSS_MIN_SIZE) ".",
  /* FLAG_NOEMIT */
  "  Do not emit any results to the result file.",
  /* FLAG_NOEQUIDISTANT_GRID */
  "  Output the internal steps given by dassl/ida instead of interpolating results\n"
  "  into an equidistant time grid as given by stepSize or numberOfIntervals.",
  /* FLAG_NOEQUIDISTANT_OUT_FREQ*/
  "  Integer value n controls the output frequency in noEquidistantTimeGrid mode\n"
  "  and outputs every n-th time step",
  /* FLAG_NOEQUIDISTANT_OUT_TIME*/
  "  Real value timeValue controls the output time point in noEquidistantOutputTime\n"
  "  mode and outputs every time>=k*timeValue, where k is an integer",
  /* FLAG_NOEVENTEMIT */
  "  Do not emit event points to the result file.",
  /* FLAG_NO_RESTART */
  "  Disables the restart of the integration method after an event is performed, used by the methods: dassl, ida",
  /* FLAG_NO_ROOTFINDING */
  "  Disables the internal root finding procedure of methods: dassl and ida.",
  /* FLAG_NO_SCALING */
  "  Disables scaling for the variables and the residuals in the algebraic nonlinear solver KINSOL.",
  /* FLAG_NO_SUPPRESS_ALG */
  "  Flag to not suppress algebraic variables in the local error test of the ida solver in daeMode.\n"
  "  In general, the use of this option is discouraged when solving DAE systems of index 1,\n"
  "  whereas it is generally encouraged for systems of index 2 or more.",
  /* FLAG_OPTDEBUGEJAC */
  "  Value specifies the number of iterations from the dynamic optimization, which\n"
  "  will be debugged, creating .csv and .py files.",
  /* FLAG_OPTIMIZER_NP */
  "  Value specifies the number of points in a subinterval.\n"
  "  Currently supports numbers 1 and 3.",
  /* FLAG_OPTIMIZER_TGRID */
  "  Value specifies external file with time points.",
  /* FLAG_OUTPUT */
  "  Output the variables a, b and c at the end of the simulation to the standard\n"
  "  output: time = value, a = value, b = value, c = value",
  /* FLAG_OUTPUT_PATH */
  "  Value specifies a path for writing the output files i.e., model_res.mat, model_prof.intdata, model_prof.realdata etc.",
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
  /* FLAG_DATA_RECONCILE */
  "  Run the Data Reconciliation numerical computation algorithm for constrained equations",
  /* FLAG_DATA_RECONCILE_BOUNDARY */
  "  Run the Data Reconciliation numerical computation algorithm for boundary condition equations",
  /* FLAG_SR */
  "  Value specifies the chosen solver of solver gbode (single-rate, slow states integrator).",
  /* FLAG_SR_CTRL */
  "  Step size control of solver gbode (single-rate, slow states integrator).",
  /* FLAG_SR_ERR */
  "  Error estimation done by Richardson extrapolation (-gberr=1) of solver gbode\n"
  "  (single-rate, slow states integrator).",
  /* FLAG_SR_INT */
  "  Interpolation method of solver gbode (single-rate, slow states integrator).",
  /* FLAG_SR_NLS */
  "  Non-linear solver method of solver gbode (single-rate, slow states integrator).",
  /* FLAG_MR */
  "  Value specifies the chosen solver of solver gbode (multi-rate, fast states integrator).\n"
  "  Current Restriction: Fully implicit (Gauss, Radau, Lobatto) RK methods are not supported, yet.",
  /* FLAG_MR_CTRL */
  "  Step size control of solver gbode (multi-rate, fast states integrator).",
  /* FLAG_MR_ERR */
  "  Error estimation done by Richardson extrapolation  (-gberr=1) of solver gbode\n"
  "  (multi-rate, fast states integrator).",
  /* FLAG_MR_INT */
  "  Interpolation method of solver gbode (multi-rate, fast states integrator).",
  /* FLAG_MR_NLS */
  "  Non-linear solver method of solver gbode (multi-rate, fast states integrator).",
  /* FLAG_MR_PAR */
  "  Define percentage of states for the fast states selection of solver gbode (values from 0 to 1).",
  /* FLAG_RT */
  "  Value specifies the scaling factor for real-time synchronization (0 disables).\n"
  "  A value > 1 means the simulation takes a longer time to simulate.\n",
  /* FLAG_S */
  "  Value specifies the integration method. For additional information see the :ref:`User's Guide <cruntime-integration-methods>`",
  /* FLAG_SINGLE */
  "  Output results in single precision (mat-format only).",
  /* FLAG_SOLVER_STEPS */
  "  Dumps the number of integration steps into the result file.",
  /* FLAG_STEADY_STATE */
  "  Aborts the simulation if steady state is reached.",
  /* FLAG_STEADY_STATE_TOL */
  "  This relative tolerance is used to detect steady state: max(|d(x_i)/dt|/nominal(x_i)) < steadyStateTol",
  /* FLAG_DATA_RECONCILE_Sx */
  "  Value specifies an csv-file with inputs as covariance matrix Sx for DataReconciliation",
  /* FLAG_UP_HESSIAN */
  "  Value specifies the number of steps, which keep Hessian matrix constant.",
  /* FLAG_W */
  "  Shows all warnings even if a related log-stream is inactive.",
  /* FLAG_PARMODNUMTHREADS */
  "  Value specifies the number of threads for simulation using parmodauto. If not specified (or is 0) it will use the systems max number of threads. Note that this option is ignored if the model is not compiled with --parmodauto",

  "FLAG_MAX"
};

const flag_repeat_policy FLAG_REPEAT_POLICIES[FLAG_MAX] = {
  FLAG_REPEAT_POLICY_FORBID,

  /* FLAG_ABORT_SLOW */                   FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_ALARM */                        FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_CLOCK */                        FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_CPU */                          FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_CSV_OSTEP */                    FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_CVODE_ITER */                   FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_CVODE_LMM */                    FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_DATA_RECONCILE_Cx */            FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_DAE_MODE */                     FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_DELTA_X_LINEARIZE */            FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_DELTA_X_SOLVER */               FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_EMBEDDED_SERVER */              FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_EMBEDDED_SERVER_PORT */         FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_MAT_SYNC */                     FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_EMIT_PROTECTED */               FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_DATA_RECONCILE_Eps */           FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_F */                            FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HELP */                         FLAG_REPEAT_POLICY_REPLACE,
  /* FLAG_HOMOTOPY_ADAPT_BEND */          FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_BACKTRACE_STRATEGY */  FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_H_EPS */               FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_MAX_LAMBDA_STEPS */    FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_MAX_NEWTON_STEPS */    FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_MAX_TRIES */           FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_NEG_START_DIR */       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_ON_FIRST_TRY */        FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NO_HOMOTOPY_ON_FIRST_TRY */     FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_TAU_DEC_FACTOR */      FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_TAU_DEC_FACTOR_PRED */ FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_TAU_INC_FACTOR */      FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_TAU_INC_THRESHOLD */   FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_TAU_MAX */             FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_TAU_MIN */             FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_HOMOTOPY_TAU_START */           FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IDA_MAXERRORTESTFAIL */         FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IDA_MAXNONLINITERS */           FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IDA_MAXCONVFAILS */             FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IDA_NONLINCONVCOEF */           FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IDA_LS */                       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IDA_SCALING */                  FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IDAS */                         FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IGNORE_HIDERESULT */            FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IIF */                          FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IIM */                          FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IIT */                          FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_ILS */                          FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IMPRK_ORDER */                  FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IMPRK_LS */                     FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_INITIAL_STEP_SIZE */            FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_INPUT_CSV */                    FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_INPUT_FILE_STATES */            FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_INPUT_PATH */                   FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IPOPT_HESSE*/                   FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IPOPT_INIT*/                    FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IPOPT_JAC*/                     FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IPOPT_MAX_ITER */               FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_IPOPT_WARM_START */             FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_JACOBIAN */                     FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_JACOBIAN_THREADS */             FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_L */                            FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_L_DATA_RECOVERY */              FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_LOG_FORMAT */                   FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_LS */                           FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_LS_IPOPT */                     FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_LSS */                          FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_LSS_MAX_DENSITY */              FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_LSS_MIN_SIZE */                 FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_LV */                           FLAG_REPEAT_POLICY_REPLACE,
  /* FLAG_LV_TIME */                      FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_MAX_BISECTION_ITERATIONS */     FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_MAX_EVENT_ITERATIONS */         FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_MAX_ORDER */                    FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_MAX_STEP_SIZE */                FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_MEASURETIMEPLOTFORMAT */        FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NEWTON_FTOL */                  FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NEWTON_MAX_STEP_FACTOR */       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NEWTON_XTOL */                  FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NEWTON_STRATEGY */              FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NLS */                          FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NLS_INFO */                     FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NLS_LS */                       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NLSS_MAX_DENSITY */             FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NLSS_MIN_SIZE */                FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NOEMIT */                       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NOEQUIDISTANT_GRID */           FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NOEQUIDISTANT_OUT_FREQ*/        FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NOEQUIDISTANT_OUT_TIME*/        FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NOEVENTEMIT */                  FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NO_RESTART */                   FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NO_ROOTFINDING */               FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NO_SCALING */                   FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_NO_SUPPRESS_ALG */              FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_OPTDEBUGEJAC */                 FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_OPTIMIZER_NP */                 FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_OPTIMIZER_TGRID */              FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_OUTPUT */                       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_OUTPUT_PATH */                  FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_OVERRIDE */                     FLAG_REPEAT_POLICY_COMBINE,
  /* FLAG_OVERRIDE_FILE */                FLAG_REPEAT_POLICY_COMBINE,
  /* FLAG_PORT */                         FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_R */                            FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_DATA_RECONCILE  */              FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_DATA_RECONCILE_BOUNDARY */      FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_SR */                           FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_SR_CTRL */                      FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_SR_ERR */                       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_SR_INT */                       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_SR_NLS */                       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_MR */                           FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_MR_CTRL */                      FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_MR_ERR */                       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_MR_INT */                       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_MR_NLS */                       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_MR_PAR */                       FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_RT */                           FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_S */                            FLAG_REPEAT_POLICY_REPLACE,
  /* FLAG_SINGLE_PRECISION */             FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_SOLVER_STEPS */                 FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_STEADY_STATE */                 FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_STEADY_STATE_TOL */             FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_DATA_RECONCILE_Sx */            FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_UP_HESSIAN */                   FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_W */                            FLAG_REPEAT_POLICY_FORBID,
  /* FLAG_PARMODNUMTHREADS */             FLAG_REPEAT_POLICY_FORBID,
};


const int FLAG_TYPE[FLAG_MAX] = {
  FLAG_TYPE_UNKNOWN,

  /* FLAG_ABORT_SLOW */                   FLAG_TYPE_FLAG,
  /* FLAG_ALARM */                        FLAG_TYPE_OPTION,
  /* FLAG_CLOCK */                        FLAG_TYPE_OPTION,
  /* FLAG_CPU */                          FLAG_TYPE_FLAG,
  /* FLAG_CSV_OSTEP */                    FLAG_TYPE_OPTION,
  /* FLAG_CVODE_ITER */                   FLAG_TYPE_OPTION,
  /* FLAG_CVODE_LMM */                    FLAG_TYPE_OPTION,
  /* FLAG_DATA_RECONCILE_Cx */            FLAG_TYPE_OPTION,
  /* FLAG_DAE_SOLVING */                  FLAG_TYPE_FLAG,
  /* FLAG_DELTA_X_LINEARIZE */            FLAG_TYPE_OPTION,
  /* FLAG_DELTA_X_SOLVER */               FLAG_TYPE_OPTION,
  /* FLAG_EMBEDDED_SERVER */              FLAG_TYPE_OPTION,
  /* FLAG_EMBEDDED_SERVER_PORT */         FLAG_TYPE_OPTION,
  /* FLAG_MAT_SYNC */                     FLAG_TYPE_OPTION,
  /* FLAG_EMIT_PROTECTED */               FLAG_TYPE_FLAG,
  /* FLAG_DATA_RECONCILE_Eps */           FLAG_TYPE_OPTION,
  /* FLAG_F */                            FLAG_TYPE_OPTION,
  /* FLAG_HELP */                         FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_ADAPT_BEND */          FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_BACKTRACE_STRATEGY */  FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_H_EPS */               FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_MAX_LAMBDA_STEPS */    FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_MAX_NEWTON_STEPS */    FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_MAX_TRIES */           FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_NEG_START_DIR */       FLAG_TYPE_FLAG,
  /* FLAG_HOMOTOPY_ON_FIRST_TRY */        FLAG_TYPE_FLAG,
  /* FLAG_NO_HOMOTOPY_ON_FIRST_TRY */     FLAG_TYPE_FLAG,
  /* FLAG_HOMOTOPY_TAU_DEC_FACTOR */      FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_TAU_DEC_FACTOR_PRED */ FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_TAU_INC_FACTOR */      FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_TAU_INC_THRESHOLD */   FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_TAU_MAX */             FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_TAU_MIN */             FLAG_TYPE_OPTION,
  /* FLAG_HOMOTOPY_TAU_START */           FLAG_TYPE_OPTION,
  /* FLAG_IDA_MAXERRORTESTFAIL */         FLAG_TYPE_OPTION,
  /* FLAG_IDA_MAXNONLINITERS */           FLAG_TYPE_OPTION,
  /* FLAG_IDA_MAXCONVFAILS */             FLAG_TYPE_OPTION,
  /* FLAG_IDA_NONLINCONVCOEF */           FLAG_TYPE_OPTION,
  /* FLAG_IDA_LS */                       FLAG_TYPE_OPTION,
  /* FLAG_IDA_SCALING */                  FLAG_TYPE_FLAG,
  /* FLAG_IDAS */                         FLAG_TYPE_FLAG,
  /* FLAG_IGNORE_HIDERESULT */            FLAG_TYPE_FLAG,
  /* FLAG_IIF */                          FLAG_TYPE_OPTION,
  /* FLAG_IIM */                          FLAG_TYPE_OPTION,
  /* FLAG_IIT */                          FLAG_TYPE_OPTION,
  /* FLAG_ILS */                          FLAG_TYPE_OPTION,
  /* FLAG_IMPRK_LS */                     FLAG_TYPE_OPTION,
  /* FLAG_IMPRK_ORDER */                  FLAG_TYPE_OPTION,
  /* FLAG_INITIAL_STEP_SIZE */            FLAG_TYPE_OPTION,
  /* FLAG_INPUT_CSV */                    FLAG_TYPE_OPTION,
  /* FLAG_INPUT_FILE_STATES */            FLAG_TYPE_OPTION,
  /* FLAG_INPUT_PATH */                   FLAG_TYPE_OPTION,
  /* FLAG_IPOPT_HESSE */                  FLAG_TYPE_OPTION,
  /* FLAG_IPOPT_INIT */                   FLAG_TYPE_OPTION,
  /* FLAG_IPOPT_JAC */                    FLAG_TYPE_OPTION,
  /* FLAG_IPOPT_MAX_ITER */               FLAG_TYPE_OPTION,
  /* FLAG_IPOPT_WARM_START */             FLAG_TYPE_OPTION,
  /* FLAG_JACOBIAN */                     FLAG_TYPE_OPTION,
  /* FLAG_JACOBIAN_THREADS */             FLAG_TYPE_OPTION,
  /* FLAG_L */                            FLAG_TYPE_OPTION,
  /* FLAG_L_DATA_RECOVERY */              FLAG_TYPE_FLAG,
  /* FLAG_LOG_FORMAT */                   FLAG_TYPE_OPTION,
  /* FLAG_LS */                           FLAG_TYPE_OPTION,
  /* FLAG_LS_IPOPT */                     FLAG_TYPE_OPTION,
  /* FLAG_LSS */                          FLAG_TYPE_OPTION,
  /* FLAG_LSS_MAX_DENSITY */              FLAG_TYPE_OPTION,
  /* FLAG_LSS_MIN_SIZE */                 FLAG_TYPE_OPTION,
  /* FLAG_LV */                           FLAG_TYPE_OPTION,
  /* FLAG_LV_TIME */                      FLAG_TYPE_OPTION,
  /* FLAG_MAX_BISECTION_ITERATIONS */     FLAG_TYPE_OPTION,
  /* FLAG_MAX_EVENT_ITERATIONS */         FLAG_TYPE_OPTION,
  /* FLAG_MAX_ORDER */                    FLAG_TYPE_OPTION,
  /* FLAG_MAX_STEP_SIZE */                FLAG_TYPE_OPTION,
  /* FLAG_MEASURETIMEPLOTFORMAT */        FLAG_TYPE_OPTION,
  /* FLAG_NEWTON_FTOL */                  FLAG_TYPE_OPTION,
  /* FLAG_NEWTON_MAX_STEP_FACTOR */       FLAG_TYPE_OPTION,
  /* FLAG_NEWTON_XTOL */                  FLAG_TYPE_OPTION,
  /* FLAG_NEWTON_STRATEGY */              FLAG_TYPE_OPTION,
  /* FLAG_NLS */                          FLAG_TYPE_OPTION,
  /* FLAG_NLS_INFO */                     FLAG_TYPE_FLAG,
  /* FLAG_NLS_LS */                       FLAG_TYPE_OPTION,
  /* FLAG_NLSS_MAX_DENSITY */             FLAG_TYPE_OPTION,
  /* FLAG_NLSS_MIN_SIZE */                FLAG_TYPE_OPTION,
  /* FLAG_NOEMIT */                       FLAG_TYPE_FLAG,
  /* FLAG_NOEQUIDISTANT_GRID*/            FLAG_TYPE_FLAG,
  /* FLAG_NOEQUIDISTANT_OUT_FREQ*/        FLAG_TYPE_OPTION,
  /* FLAG_NOEQUIDISTANT_OUT_TIME*/        FLAG_TYPE_OPTION,
  /* FLAG_NO_RESTART */                   FLAG_TYPE_FLAG,
  /* FLAG_NO_ROOTFINDING */               FLAG_TYPE_FLAG,
  /* FLAG_NO_SCALING */                   FLAG_TYPE_FLAG,
  /* FLAG_NO_SUPPRESS_ALG */              FLAG_TYPE_FLAG,
  /* FLAG_NOEVENTEMIT */                  FLAG_TYPE_FLAG,
  /* FLAG_OPTDEBUGEJAC */                 FLAG_TYPE_OPTION,
  /* FLAG_OPTIZER_NP */                   FLAG_TYPE_OPTION,
  /* FLAG_OPTIZER_TGRID */                FLAG_TYPE_OPTION,
  /* FLAG_OUTPUT */                       FLAG_TYPE_OPTION,
  /* FLAG_OUTPUT_PATH */                  FLAG_TYPE_OPTION,
  /* FLAG_OVERRIDE */                     FLAG_TYPE_OPTION,
  /* FLAG_OVERRIDE_FILE */                FLAG_TYPE_OPTION,
  /* FLAG_PORT */                         FLAG_TYPE_OPTION,
  /* FLAG_R */                            FLAG_TYPE_OPTION,
  /* FLAG_DATA_RECONCILE */               FLAG_TYPE_FLAG,
  /* FLAG_DATA_RECONCILE_BOUNDARY */      FLAG_TYPE_FLAG,
  /* FLAG_SR */                           FLAG_TYPE_OPTION,
  /* FLAG_SR_CTRL */                      FLAG_TYPE_OPTION,
  /* FLAG_SR_ERR */                       FLAG_TYPE_OPTION,
  /* FLAG_SR_INT */                       FLAG_TYPE_OPTION,
  /* FLAG_SR_NLS */                       FLAG_TYPE_OPTION,
  /* FLAG_MR */                           FLAG_TYPE_OPTION,
  /* FLAG_MR_CTRL */                      FLAG_TYPE_OPTION,
  /* FLAG_MR_ERR */                       FLAG_TYPE_OPTION,
  /* FLAG_MR_INT */                       FLAG_TYPE_OPTION,
  /* FLAG_MR_NLS */                       FLAG_TYPE_OPTION,
  /* FLAG_MR_PAR */                       FLAG_TYPE_OPTION,
  /* FLAG_RT */                           FLAG_TYPE_OPTION,
  /* FLAG_S */                            FLAG_TYPE_OPTION,
  /* FLAG_SINGLE */                       FLAG_TYPE_FLAG,
  /* FLAG_SOLVER_STEPS */                 FLAG_TYPE_FLAG,
  /* FLAG_STEADY_STATE */                 FLAG_TYPE_FLAG,
  /* FLAG_STEADY_STATE_TOL */             FLAG_TYPE_OPTION,
  /* FLAG_DATA_RECONCILE_Sx */            FLAG_TYPE_OPTION,
  /* FLAG_UP_HESSIAN */                   FLAG_TYPE_OPTION,
  /* FLAG_W */                            FLAG_TYPE_FLAG,
  /* FLAG_PARMODNUMTHREADS */             FLAG_TYPE_OPTION,
};

const char *GB_METHOD_NAME[RK_MAX] = {
  /* GB_UNKNOWN = 0 */   "unknown",
  /* MS_ADAMS_MOULTON */ "adams",
  /* RK_EXPL_EULER */    "expl_euler",
  /* RK_IMPL_EULER */    "impl_euler",
  /* RK_TRAPEZOID */     "trapezoid",
  /* RK_SDIRK2 */        "sdirk2",
  /* RK_SDIRK3 */        "sdirk3",
  /* RK_ESDIRK2 */       "esdirk2",
  /* RK_ESDIRK3 */       "esdirk3",
  /* RK_ESDIRK4 */       "esdirk4",
  /* RK_RADAU_IA_2 */    "radauIA2",
  /* RK_RADAU_IA_3 */    "radauIA3",
  /* RK_RADAU_IA_4 */    "radauIA4",
  /* RK_RADAU_IIA_2 */   "radauIIA2",
  /* RK_RADAU_IIA_3 */   "radauIIA3",
  /* RK_RADAU_IIA_4 */   "radauIIA4",
  /* RK_LOBA_IIIA_3 */   "lobattoIIIA3",
  /* RK_LOBA_IIIA_4 */   "lobattoIIIA4",
  /* RK_LOBA_IIIB_3 */   "lobattoIIIB3",
  /* RK_LOBA_IIIB_4 */   "lobattoIIIB4",
  /* RK_LOBA_IIIC_3 */   "lobattoIIIC3",
  /* RK_LOBA_IIIC_4 */   "lobattoIIIC4",
  /* RK_GAUSS2 */        "gauss2",
  /* RK_GAUSS3 */        "gauss3",
  /* RK_GAUSS4 */        "gauss4",
  /* RK_GAUSS5 */        "gauss5",
  /* RK_GAUSS6 */        "gauss6",
  /* RK_MERSON */        "merson",
  /* RK_MERSONSSC1 */    "mersonSsc1",
  /* RK_MERSONSSC2 */    "mersonSsc2",
  /* RK_HEUN */          "heun",
  /* RK_FEHLBERG12 */    "fehlberg12",
  /* RK_FEHLBERG45 */    "fehlberg45",
  /* RK_FEHLBERG78 */    "fehlberg78",
  /* RK_FEHLBERGSSC1 */  "fehlbergSsc1",
  /* RK_FEHLBERGSSC2 */  "fehlbergSsc2",
  /* RK_RK810 */         "rk810",
  /* RK_RK1012 */        "rk1012",
  /* RK_RK1214 */        "rk1214",
  /* RK_DOPRI45 */       "dopri45",
  /* RK_DOPRISSC1 */     "dopriSsc1",
  /* RK_DOPRISSC2 */     "dopriSsc2",
  /* RK_RKSSC */         "rungekuttaSsc"
};

const char *GB_METHOD_DESC[RK_MAX] = {
  /* GB_UNKNOWN = 0 */   "unknown",
  /* MS_ADAMS_MOULTON */ "Implicit multistep method of type Adams-Moulton (order 2)",
  /* RK_EXPL_EULER */    "Explizit Runge-Kutta Euler method (order 1)",
  /* RK_IMPL_EULER */    "Implizit Runge-Kutta Euler method (order 1)",
  /* RK_TRAPEZOID */     "Implicit Runge-Kutta trapezoid method (order 2)",
  /* RK_SDIRK2 */        "Singly-diagonal implicit Runge-Kutta (order 2)",
  /* RK_SDIRK3 */        "Singly-diagonal implicit Runge-Kutta (order 3)",
  /* RK_ESDIRK2 */       "Explicit singly-diagonal implicit Runge-Kutta (order 2)",
  /* RK_ESDIRK3 */       "Explicit singly-diagonal implicit Runge-Kutta (order 3)",
  /* RK_ESDIRK4 */       "Explicit singly-diagonal implicit Runge-Kutta (order 4)",
  /* RK_RADAU_IA_2 */    "Implicit Runge-Kutta method of Radau family IA (order 3)",
  /* RK_RADAU_IA_3 */    "Implicit Runge-Kutta method of Radau family IA (order 5)",
  /* RK_RADAU_IA_4 */    "Implicit Runge-Kutta method of Radau family IA (order 7)",
  /* RK_RADAU_IIA_2 */   "Implicit Runge-Kutta method of Radau family IIA (order 3)",
  /* RK_RADAU_IIA_3 */   "Implicit Runge-Kutta method of Radau family IIA (order 5)",
  /* RK_RADAU_IIA_4 */   "Implicit Runge-Kutta method of Radau family IIA (order 7)",
  /* RK_LOBA_IIIA_3 */   "Implicit Runge-Kutta method of Lobatto family IIIA (order 4)",
  /* RK_LOBA_IIIA_4 */   "Implicit Runge-Kutta method of Lobatto family IIIA (order 6)",
  /* RK_LOBA_IIIB_3 */   "Implicit Runge-Kutta method of Lobatto family IIIB (order 4)",
  /* RK_LOBA_IIIB_4 */   "Implicit Runge-Kutta method of Lobatto family IIIB (order 6)",
  /* RK_LOBA_IIIC_3 */   "Implicit Runge-Kutta method of Lobatto family IIIC (order 4)",
  /* RK_LOBA_IIIC_4 */   "Implicit Runge-Kutta method of Lobatto family IIIC (order 6)",
  /* RK_GAUSS2 */        "Implicit Runge-Kutta method of Gauss (order 4)",
  /* RK_GAUSS3 */        "Implicit Runge-Kutta method of Gauss (order 6)",
  /* RK_GAUSS4 */        "Implicit Runge-Kutta method of Gauss (order 8)",
  /* RK_GAUSS5 */        "Implicit Runge-Kutta method of Gauss (order 10)",
  /* RK_GAUSS6 */        "Implicit Runge-Kutta method of Gauss (order 12)",
  /* RK_MERSON */        "Explicit Runge-Kutta Merson method (order 4)",
  /* RK_MERSONSSC1 */    "Explicit Runge-Kutta Merson method with large stability region (order 1)",
  /* RK_MERSONSSC2 */    "Explicit Runge-Kutta Merson method with large stability region (order 2)",
  /* RK_HEUN */          "Explicit Runge-Kutta Heun method (order 2)",
  /* RK_FEHLBERG12 */    "Explicit Runge-Kutta Fehlberg method (order 2)",
  /* RK_FEHLBERG45 */    "Explicit Runge-Kutta Fehlberg method (order 5)",
  /* RK_FEHLBERG78 */    "Explicit Runge-Kutta Fehlberg method (order 8)",
  /* RK_FEHLBERGSSC1 */  "Explicit Runge-Kutta Fehlberg method with large stability region (order 1)",
  /* RK_FEHLBERGSSC2 */  "Explicit Runge-Kutta Fehlberg method with large stability region (order 2)",
  /* RK_RK810 */         "Explicit 8-10 Runge-Kutta method (order 10)",
  /* RK_RK1012 */        "Explicit 10-12 Runge-Kutta method (order 12)",
  /* RK_RK1214 */        "Explicit 12-14 Runge-Kutta method (order 14)",
  /* RK_DOPRI45 */       "Explicit Runge-Kutta method Dormand-Prince (order 5)",
  /* RK_DOPRISSC1 */     "Explicit Runge-Kutta method Dormand-Prince with large stability region (order 1)",
  /* RK_DOPRISSC2 */     "Explicit Runge-Kutta method Dormand-Prince with large stability region (order 2)",
  /* RK_RKSSC */         "Explicit Runge-Kutta method with large stabiliy region (order 1)"
};

const char *GB_NLS_METHOD_NAME[GB_NLS_MAX] = {
  /* GB_NLS_UNKNOWN = 0*/ "unknown",
  /* GB_NLS_NEWTON */     "newton",
  /* GB_NLS_KINSOL */     "kinsol"
};

const char *GB_NLS_METHOD_DESC[GB_NLS_MAX] = {
  /* GB_NLS_UNKNOWN = 0*/ "unknown",
  /* GB_NLS_NEWTON */     "Newton method, dense",
  /* GB_NLS_KINSOL */     "SUNDIALS KINSOL: Inexact Newton, sparse"
};

const char *GB_CTRL_METHOD_NAME[GB_CTRL_MAX] = {
  /* GB_CTRL_UNKNOWN */   "unknown",
  /* GB_CTRL_I */         "i",
  /* GB_CTRL_PI */        "pi",
  /* GB_CTRL_CNST */      "const"
};

const char *GB_CTRL_METHOD_DESC[GB_CTRL_MAX] = {
  /* GB_CTRL_UNKNOWN */   "unknown",
  /* GB_CTRL_I */         "I controller for step size",
  /* GB_CTRL_PI */        "PI controller for step size",
  /* GB_CTRL_CNST */      "Constant step size"
};

const char *GB_INTERPOL_METHOD_NAME[GB_INTERPOL_MAX] = {
  /* GB_INTERPOL_UNKNOWN */           "unknown",
  /* GB_INTERPOL_LIN */               "linear",
  /* GB_INTERPOL_HERMITE */           "hermite",
  /* GB_INTERPOL_HERMITE_a */         "hermite_a",
  /* GB_INTERPOL_HERMITE_b */         "hermite_b",
  /* GB_INTERPOL_HERMITE_ERRCTRL */   "hermite_errctrl",
  /* GB_DENSE_OUTPUT */               "dense_output",
  /* GB_DENSE_OUTPUT_ERRCTRL */       "dense_output_errctrl"
};

const char *GB_INTERPOL_METHOD_DESC[GB_INTERPOL_MAX] = {
  /* GB_INTERPOL_UNKNOWN */         "unknown",
  /* GB_INTERPOL_LIN */             "Linear interpolation (1st order)",
  /* GB_INTERPOL_HERMITE */         "Hermite interpolation (3rd order)",
  /* GB_INTERPOL_HERMITE_a */       "Hermite interpolation (only for left hand side)",
  /* GB_INTERPOL_HERMITE_b */       "Hermite interpolation (only for right hand side)",
  /* GB_INTERPOL_HERMITE_ERRCTRL */ "Hermite interpolation with error control",
  /* GB_DENSE_OUTPUT */             "use dense output formula for interpolation",
  /* GB_DENSE_OUTPUT_ERRCTRL */     "use dense output fomular with error control"
};

const char *SOLVER_METHOD_NAME[S_MAX] = {
  /* S_UNKNOWN = 0 */   "unknown",
  /* S_EULER */         "euler",
  /* S_HEUN */          "heun",
  /* S_RUNGEKUTTA */    "rungekutta",
  /* S_IMPEULER */      "impeuler",
  /* S_TRAPEZOID */     "trapezoid",
  /* S_IMPRUNGEKUTTA */ "imprungekutta",
  /* S_GBODE */         "gbode",
  /* S_IRKSCO */        "irksco",
  /* S_DASSL */         "dassl",
  /* S_IDA */           "ida",
  /* S_CVODE */         "cvode",
  /* S_ERKSSC */        "rungekuttaSsc",
  /* S_SYM_SOLVER */    "symSolver",
  /* S_SYM_SOLVER_SSC */"symSolverSsc",
  /* S_QSS */           "qss",
  /* S_OPTIMIZATION */  "optimization"
};

const char *SOLVER_METHOD_DESC[S_MAX] = {
  /* S_UNKNOWN = 0 */   "unknown",
  /* S_EULER */         "euler - Euler - explicit, fixed step size, order 1",
  /* S_HEUN */          "heun - Heun's method - explicit, fixed step, order 2",
  /* S_RUNGEKUTTA */    "rungekutta - classical Runge-Kutta - explicit, fixed step, order 4",
  /* S_IMPEULER */      "impeuler - Euler - implicit, fixed step size, order 1",
  /* S_TRAPEZOID */     "trapezoid - trapezoidal rule - implicit, fixed step size, order 2",
  /* S_IMPRUNGEKUTTA */ "imprungekutta - Runge-Kutta methods based on Radau and Lobatto IIA - implicit, fixed step size, order 1-6(selected manually by flag -impRKOrder)",
  /* S_GBODE */         "gbode - generic bi-rate ODE solver - implicit, explicit, step size control, arbitrary order",
  /* S_IRKSCO */        "irksco - own developed Runge-Kutta solver - implicit, step size control, order 1-2",
  /* S_DASSL */         "dassl - default solver - BDF method - implicit, step size control, order 1-5",
  /* S_IDA */           "ida - SUNDIALS IDA solver - BDF method with sparse linear solver - implicit, step size control, order 1-5",
  /* S_CVODE */         "cvode - experimental implementation of SUNDIALS CVODE solver - BDF or Adams-Moulton method - step size control, order 1-12",
  /* S_ERKSSC */        "rungekuttaSsc - Runge-Kutta based on Novikov (2016) - explicit, step size control, order 4-5 [experimental]",
  /* S_SYM_SOLVER */     "symSolver - symbolic inline Solver [compiler flag +symSolver needed] - fixed step size, order 1",
  /* S_SYM_SOLVER_SSC */ "symSolverSsc - symbolic implicit Euler with step size control [compiler flag +symSolver needed] - step size control, order 1",
  /* S_QSS */           "qss - A QSS solver [experimental]",
  /* S_OPTIMIZATION */  "optimization - Special solver for dynamic optimization"
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

const char *LS_NAME[LS_MAX] = {
  "LS_UNKNOWN",

  /* LS_LAPACK */       "lapack",
#if !defined(OMC_MINIMAL_RUNTIME)
  /* LS_LIS */          "lis",
#else
  /* LS_LIS */          "lis-not-available",
#endif
  /* LS_KLU */          "klu",
  /* LS_UMFPACK */      "umfpack",
  /* LS_TOTALPIVOT */   "totalpivot",
  /* LS_DEFAULT */      "default"
};

const char *LS_DESC[LS_MAX] = {
  "unknown",

  /* LS_LAPACK */       "method using LAPACK LU factorization",
#if !defined(OMC_MINIMAL_RUNTIME)
  /* LS_LIS */          "method using iterative solver Lis",
#else
  /* LS_LIS */          "iterative solver Lis is not available",
#endif
  /* LS_KLU */          "method using KLU sparse linear solver",
  /* LS_UMFPACK */      "method using UMFPACK sparse linear solver",
  /* LS_TOTALPIVOT */   "method using a total pivoting LU factorization for underdetermination systems",
  /* LS_DEFAULT */      "default method - LAPACK with total pivoting as fallback"
};

const char *LSS_NAME[LSS_MAX] = {
  "LS_UNKNOWN",
  /* LSS_DEFAULT */     "default",
#if !defined(OMC_MINIMAL_RUNTIME)
  /* LSS_LIS */         "lis",
#else
  /* LSS_LIS */         "lis-not-available",
#endif
  /* LSS_KLU */         "klu",
  /* LSS_UMFPACK */     "umfpack"
};

const char *LSS_DESC[LSS_MAX] = {
  "unknown",
  /* LSS_DEFAULT */     "the default sparse linear solver (or a dense solver if there is none available) ",
#if !defined(OMC_MINIMAL_RUNTIME)
  /* LSS_LIS */         "method using iterative solver Lis",
#else
  /* LSS_LIS */         "iterative solver Lis not available",
#endif
  /* LSS_KLU */         "method using klu sparse linear solver",
  /* LSS_UMFPACK */     "method using umfpack sparse linear solver"
};

const char *NLS_NAME[NLS_MAX] = {
  "NLS_UNKNOWN",

#if !defined(OMC_MINIMAL_RUNTIME)
  /* NLS_HYBRID */       "hybrid",
  /* NLS_KINSOL */       "kinsol",
  /* NLS_NEWTON */       "newton",
  /* NLS_MIXED */        "mixed",
#else
  /* NLS_HYBRID */       "hybrid-not-available",
  /* NLS_KINSOL */       "kinsol-not-available",
  /* NLS_NEWTON */       "newton-not-available",
  /* NLS_MIXED */        "mixed-not-available",
#endif
  /* NLS_HOMOTOPY */     "homotopy"
};

const char *NLS_DESC[NLS_MAX] = {
  "unknown",

#if !defined(OMC_MINIMAL_RUNTIME)
  /* NLS_HYBRID */       "Modification of the Powell hybrid method from minpack - former default solver",
  /* NLS_KINSOL */       "SUNDIALS/KINSOL includes an interface to the sparse direct solver, KLU. See simulation option -nlsLS for more information.",
  /* NLS_NEWTON */       "Newton Raphson - prototype implementation",
  /* NLS_MIXED */        "Mixed strategy. First the homotopy solver is tried and then as fallback the hybrid solver.",
#else
  /* NLS_HYBRID */       "Modification of the Powell hybrid method from minpack - former default solver. Not available in minimal runtime.",
  /* NLS_KINSOL */       "SUNDIALS/KINSOL includes interface to the sparse direct solver, KLU. See simulation option -nlsLS for more information."
  /* NLS_NEWTON */       "Newton Raphson - prototype implementation. Not available in minimal runtime.",
  /* NLS_MIXED */        "Mixed strategy. First the homotopy solver is tried and then as fallback the hybrid solver. Not available in minimal runtime.",
#endif
  /* NLS_HOMOTOPY */     "Damped Newton solver if failing case fixed-point and Newton homotopies are tried."
};

const char *NEWTONSTRATEGY_NAME[NEWTON_MAX] = {
  "NEWTON_UNKNOWN",

  /* NEWTON_DAMPED */       "damped",
  /* NEWTON_DAMPED2 */      "damped2",
  /* NEWTON_DAMPED_LS */    "damped_ls",
  /* NEWTON_DAMPED_BT */    "damped_bt",
  /* NEWTON_PURE */         "pure"
};

const char *NEWTONSTRATEGY_DESC[NEWTON_MAX] = {
  "unknown",

  /* NEWTON_DAMPED */       "Newton with a damping strategy",
  /* NEWTON_DAMPED2 */      "Newton with a damping strategy 2",
  /* NEWTON_DAMPED_LS */    "Newton with a damping line search",
  /* NEWTON_DAMPED_BT */    "Newton with a damping backtracking and a minimum search via golden ratio method",
  /* NEWTON_PURE */         "Newton without damping strategy"
};


const char *JACOBIAN_METHOD[JAC_MAX] = {
  "unknown",

  "coloredNumerical",
  "internalNumerical",
  "coloredSymbolical",
  "numerical",
  "symbolical"
};

const char *JACOBIAN_METHOD_DESC[JAC_MAX] = {
  "unknown",

  "Colored numerical Jacobian, which is default for dassl and ida. With option -idaLS=klu a sparse matrix is used.",
  "Dense solver internal numerical Jacobian.",
  "Colored symbolical Jacobian. Needs omc compiler flag --generateSymbolicJacobian. With option -idaLS=klu a sparse matrix is used.",
  "Dense numerical Jacobian.",
  "Dense symbolical Jacobian. Needs omc compiler flag --generateSymbolicJacobian.",
 };

const char *IDA_LS_METHOD[IDA_LS_MAX] = {
  "unknown",

  "dense",
  "klu",
  "spgmr",
  "spbcg",
  "sptfqmr"
};

const char *IDA_LS_METHOD_DESC[IDA_LS_MAX] = {
  "unknown",

  "ida internal dense method.",
  "ida use sparse direct solver KLU. (default)",
  "ida generalized minimal residual method. Iterative method",
  "ida Bi-CGStab. Iterative method",
  "ida TFQMR. Iterative method"
};

const char *NLS_LS_METHOD[NLS_LS_MAX] = {
  "unknown",

  "default",
  "totalpivot",
  "lapack",
  "klu"
};

const char *NLS_LS_METHOD_DESC[NLS_LS_MAX] = {
  "unknown",

  "chooses the nls linear solver based on which nls is being used.",
  "internal total pivot implementation. Solve in some case even under-determined systems.",
  "use external LAPACK implementation.",
  "use KLU direct sparse solver. Only with KINSOL available."
};

const char *IMPRK_LS_METHOD[IMPRK_LS_MAX] = {
  "unknown",

  "iterative",
  "dense"
};

const char *IMPRK_LS_METHOD_DESC[IMPRK_LS_MAX] = {
  "unknown",

  "use sparse iterative solvers",
  "use direct dense method"
};

const char *HOM_BACK_STRAT_NAME[HOM_BACK_STRAT_MAX] = {
  "HOM_BACK_STRAT_UNKNOWN",

  /* HOM_BACK_STRAT_FIX */         "fix",
  /* HOM_BACK_STRAT_ORTHOGONAL */  "orthogonal"
};

const char *HOM_BACK_STRAT_DESC[HOM_BACK_STRAT_MAX] = {
  "unknown",

  /* HOM_BACK_STRAT_FIX */          "go back to the path by fixing one coordinate",
  /* HOM_BACK_STRAT_ORTHOGONAL */   "go back to the path in an orthogonal direction to the tangent vector"
};

const int FMU_FLAG_MAP[FMU_FLAG_MAX] = {
 /* FMU_FLAG_UNKNOWN */             FLAG_UNKNOWN,
 /* FMU_FLAG_SOLVER */              FLAG_S,
 /* FMU_FLAG_NLS */                 FLAG_NLS
};
