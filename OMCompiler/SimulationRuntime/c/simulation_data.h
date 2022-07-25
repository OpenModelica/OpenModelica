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

/*! \file simulation_data.h
 * Description: This is the C header file to provide all information
 * for simulation
 */

#ifndef SIMULATION_DATA_H
#define SIMULATION_DATA_H

#include "openmodelica.h"
#include "util/doubleEndedList.h"
#include "util/list.h"
#include "util/omc_error.h"
#include "util/rational.h"
#include "util/ringbuffer.h"
#include "util/rtclock.h"
#include "util/simulation_options.h"
#include "util/context.h"

#define omc_dummyVarInfo {-1,-1,"","",omc_dummyFileInfo}
#define omc_dummyEquationInfo {-1,0,0,-1,NULL}
#define omc_dummyFunctionInfo {-1,"",omc_dummyFileInfo}
#define omc_dummyRealAttribute {NULL,NULL,-DBL_MAX,DBL_MAX,0,0,1.0,0.0}

#define OMC_LINEARIZE_DUMP_LANGUAGE_MODELICA 0
#define OMC_LINEARIZE_DUMP_LANGUAGE_MATLAB 1
#define OMC_LINEARIZE_DUMP_LANGUAGE_JULIA 2
#define OMC_LINEARIZE_DUMP_LANGUAGE_PYTHON 3

#if defined(_MSC_VER)
#define set_struct(TYPE, x, info) { const TYPE tmp = info; x = tmp; }
#else
#define set_struct(TYPE, x, info) x = (TYPE)info
#endif

/* Forward declarations */
struct DATA;
typedef struct DATA DATA;

/* Model info structures */
typedef struct VAR_INFO
{
  int id;
  int inputIndex; /* -1 means not an input */
  const char *name;
  const char *comment;
  FILE_INFO info;
} VAR_INFO;

typedef struct EQUATION_INFO
{
  int id;
  int profileBlockIndex;
  int parent;
  int numVar;
  const char **vars;
} EQUATION_INFO;

typedef struct FUNCTION_INFO
{
  int id;
  const char* name;
  FILE_INFO info;
} FUNCTION_INFO;

typedef struct SAMPLE_INFO
{
  long index;
  double start;
  double interval;
} SAMPLE_INFO;

typedef struct CHATTERING_INFO
{
  int numEventLimit;
  int *lastSteps;
  double *lastTimes;
  int currentIndex;
  int lastStepsNumStateEvents;
  int messageEmitted;
} CHATTERING_INFO;

typedef struct CALL_STATISTICS
{
  long functionODE;
  long updateDiscreteSystem;
  long functionZeroCrossingsEquations;
  long functionZeroCrossings;
  long functionEvalDAE;
  long functionAlgebraics;
} CALL_STATISTICS;

typedef enum
{
  ERROR_AT_TIME,
  NO_PROGRESS_START_POINT,
  NO_PROGRESS_FACTOR,
  IMPROPER_INPUT
} EQUATION_SYSTEM_ERROR;

typedef enum
{
  JACOBIAN_UNKNOWN = 0,       /* availability of jacobian unknown (not initialized) */
  JACOBIAN_NOT_AVAILABLE,     /* no symbolic jacobian and no sparsity pattern available */
  JACOBIAN_ONLY_SPARSITY,     /* only sparsity pattern available */
  JACOBIAN_AVAILABLE          /* symbolic jacobian and sparsity pattern available */
} JACOBIAN_AVAILABILITY;

/**
 * @brief Sparse pattern for Jacobian matrix.
 *
 * Using compressed sparse column (CSC) format.
 */
typedef struct SPARSE_PATTERN
{
  unsigned int* leadindex;        /* Array with column indices, size rows+1 */
  unsigned int* index;            /* Array with number of non-zeros indices */
  unsigned int sizeofIndex;       /* Length of array index, equal to numberOfNonZeros */
  unsigned int* colorCols;        /* Color coding of columns. First color is `1`, second is `2`, ...
                                   * Length of array is rows */
  unsigned int numberOfNonZeros;  /* Number of non-zero elements in matrix */
  unsigned int maxColors;         /* Number of colors */
} SPARSE_PATTERN;

/**
 * @brief Analytic jacobian struct
 *
 */
typedef struct ANALYTIC_JACOBIAN
{
  JACOBIAN_AVAILABILITY availability;  /* Availability status */
  unsigned int sizeCols;              /* Number of columns of Jacobian */
  unsigned int sizeRows;              /* Number of rows of Jacobian */
  unsigned int sizeTmpVars;           /* Length of vector tmpVars */
  SPARSE_PATTERN* sparsePattern;      /* Contain sparse pattern including coloring */
  modelica_real* seedVars;            /* Seed vector for specifying which columns to evaluate */
  modelica_real* tmpVars;
  modelica_real* resultVars;          /* Result column for given seed vector */
  modelica_real dae_cj;               /* Is the scalar in the system Jacobian, proportional to the inverse of the step size. From User Documentation for ida v5.4.0 equation (2.5). */
  int (*constantEqns)(void* data, threadData_t *threadData, void* thisJacobian, void* parentJacobian);  /* Constant equations independed of seed vector */
} ANALYTIC_JACOBIAN;

/* EXTERNAL_INPUT
 *
 * extern input for dassl and optimization
 *
 */
typedef struct EXTERNAL_INPUT
{
  modelica_boolean active; // FIXME comments about meaning
  modelica_real** u;
  modelica_real* t;
  modelica_integer N;
  modelica_integer n;
  modelica_integer i;
} EXTERNAL_INPUT;

/* Alias data with various types */
typedef struct DATA_ALIAS
{
  int negate;
  int nameID;                          /* pointer to Alias */
  char aliasType;                      /* 0 variable, 1 parameter, 2 time */
  VAR_INFO info;
  modelica_boolean filterOutput;       /* true if this variable should be filtered */
} DATA_ALIAS;

typedef DATA_ALIAS DATA_REAL_ALIAS;
typedef DATA_ALIAS DATA_INTEGER_ALIAS;
typedef DATA_ALIAS DATA_BOOLEAN_ALIAS;
typedef DATA_ALIAS DATA_STRING_ALIAS;

/* collect all attributes from one variable in one struct */
typedef struct REAL_ATTRIBUTE
{
  modelica_string unit;                /* = "" */
  modelica_string displayUnit;         /* = "" */
  modelica_real min;                   /* = -Inf */
  modelica_real max;                   /* = +Inf */
  modelica_boolean fixed;              /* depends on the type */
  modelica_boolean useNominal;         /* = false */
  modelica_real nominal;               /* = 1.0 */
  modelica_real start;                 /* = 0.0 */
} REAL_ATTRIBUTE;

typedef struct INTEGER_ATTRIBUTE
{
  modelica_integer min;                /* = -Inf */
  modelica_integer max;                /* = +Inf */
  modelica_boolean fixed;              /* depends on the type */
  modelica_integer start;              /* = 0 */
} INTEGER_ATTRIBUTE;

typedef struct BOOLEAN_ATTRIBUTE
{
  modelica_boolean fixed;              /* depends on the type */
  modelica_boolean start;              /* = false */
} BOOLEAN_ATTRIBUTE;

typedef struct STRING_ATTRIBUTE
{
  modelica_string start;               /* = "" */
} STRING_ATTRIBUTE;

typedef struct STATIC_REAL_DATA
{
  VAR_INFO info;
  REAL_ATTRIBUTE attribute;
  modelica_boolean filterOutput;       /* true if this variable should be filtered */
  modelica_boolean time_unvarying;     /* true if the value is only computed once during initialization */
} STATIC_REAL_DATA;

typedef struct STATIC_INTEGER_DATA
{
  VAR_INFO info;
  INTEGER_ATTRIBUTE attribute;
  modelica_boolean filterOutput;       /* true if this variable should be filtered */
  modelica_boolean time_unvarying;     /* true if the value is only computed once during initialization */
} STATIC_INTEGER_DATA;

typedef struct STATIC_BOOLEAN_DATA
{
  VAR_INFO info;
  BOOLEAN_ATTRIBUTE attribute;
  modelica_boolean filterOutput;       /* true if this variable should be filtered */
  modelica_boolean time_unvarying;     /* true if the value is only computed once during initialization */
} STATIC_BOOLEAN_DATA;

typedef struct STATIC_STRING_DATA
{
  VAR_INFO info;
  STRING_ATTRIBUTE attribute;
  modelica_boolean filterOutput;       /* true if this variable should be filtered */
  modelica_boolean time_unvarying;     /* true if the value is only computed once during initialization */
} STATIC_STRING_DATA;

typedef int (*analyticalJacobianColumn_func_ptr)(DATA* data, threadData_t* threadData, ANALYTIC_JACOBIAN* thisJacobian, ANALYTIC_JACOBIAN* parentJacobian);

/**
 * @brief User data provided to residual functions.
 *
 */
typedef struct RESIDUAL_USERDATA {
  DATA* data;
  threadData_t* threadData;
  void* solverData;           /* Optional pointer to ODE solver data.
                               * Used in NLS solving of ODE integrator step. */
} RESIDUAL_USERDATA;

typedef struct NLS_USERDATA NLS_USERDATA;

typedef enum {
  NLS_FAILED = 0,                   /* NLS Solver failed to solve system */
  NLS_SOLVED = 1,                   /* NLS Solver solved system successfully */
  NLS_SOLVED_LESS_ACCURACY = 2     /* NLS Solver found a solution with low accuracy */
} NLS_SOLVER_STATUS;

#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
typedef struct NONLINEAR_SYSTEM_DATA
{
  modelica_integer size;
  modelica_integer equationIndex;      /* index for EQUATION_INFO */

  modelica_boolean homotopySupport;    /* true if homotopy is available */
  modelica_boolean initHomotopy;       /* true if the homotopy solver should be used to solve the initial system */
  modelica_boolean mixedSystem;        /* true if the system contains discrete variables */

  /* attributes of iteration variables */
  modelica_real *min;
  modelica_real *max;
  modelica_real *nominal;

  /* if analyticalJacobianColumn != NULL analyticalJacobian is available and
   * can be produced with the help of analyticalJacobianColumnn function pointer
   * which is a generic column of the jacobian matrix. (see ANALYTIC_JACOBIAN)
   *
   * if analyticalJacobianColumn == NULL no analyticalJacobian is available
   */
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;
  int (*initialAnalyticalJacobian)(DATA* data, threadData_t* threadData, ANALYTIC_JACOBIAN* jacobian);
  modelica_integer jacobianIndex;

  SPARSE_PATTERN *sparsePattern;       /* sparse pattern if no jacobian is available */
  modelica_boolean isPatternAvailable;

  void (*residualFunc)(RESIDUAL_USERDATA* userData, const double* x, double* res, const int* flag);
  int (*residualFuncConstraints)(RESIDUAL_USERDATA* userData, const double*, double*, const int*);
  void (*initializeStaticNLSData)(DATA* data, threadData_t *threadData, struct NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsePattern);
  int (*strictTearingFunctionCall)(DATA* data, threadData_t *threadData);
  void (*getIterationVars)(DATA* data, double* array);
  int (*checkConstraints)(DATA* data, threadData_t *threadData);

  NONLINEAR_SOLVER nlsMethod;          /* nonlinear solver */
  void *solverData;
  NLS_LS nlsLinearSolver;              /* nls linear solver */

  modelica_real *nlsx;                 /* x */
  modelica_real *nlsxOld;              /* previous x */
  modelica_real *nlsxExtrapolation;    /* extrapolated values for x from old and old2 - used as initial guess */

  void *oldValueList;                  /* old values organized in a sorted list for extrapolation and interpolate, respectively */
  modelica_real *resValues;            /* memory space for evaluated residual values */

  NLS_SOLVER_STATUS solved;            /* Specifiex if the NLS could be solved (with less accuracy) or failed */
  modelica_real lastTimeSolved;        /* save last successful solved point in time */

  /* statistics */
  unsigned long numberOfCall;          /* number of solving calls of this system */
  unsigned long numberOfFEval;         /* number of function evaluations of this system */
  unsigned long numberOfJEval;         /* number of jacobian evaluations of this system */
  unsigned long numberOfIterations;    /* number of iteration of non-linear solvers of this system */
  double totalTime;                    /* save the totalTime */
  rtclock_t totalTimeClock;            /* time clock for the totalTime */
  double jacobianTime;                 /* save the time to calculate jacobians */
  rtclock_t jacobianTimeClock;         /* time clock for the jacobianTime */
  void* csvData;                       /* information to save csv data */
} NONLINEAR_SYSTEM_DATA;
#else
typedef void* NONLINEAR_SYSTEM_DATA;
#endif

typedef struct LINEAR_SYSTEM_THREAD_DATA
{
  void *solverData[2];                 /* [1] is the totalPivot solver
                                          [0] holds other solvers
                                          both are used for the default solver */
  modelica_real *x;                    /* solution vector x */
  modelica_real *A;                    /* matrix A */
  modelica_real *b;                    /* vector b */

  ANALYTIC_JACOBIAN* parentJacobian;   /* if != NULL then it's the parent jacobian matrix */
  ANALYTIC_JACOBIAN* jacobian;         /* jacobian */

  /* Statistics for each thread */
  unsigned long numberOfCall;          /* number of solving calls of this system */
  unsigned long numberOfJEval;         /* number of jacobian evaluations of this system */
  double totalTime;                    /* save the totalTime */
  rtclock_t totalTimeClock;            /* time clock for the totalTime */
  double jacobianTime;                 /* save the time to calculate jacobians */
} LINEAR_SYSTEM_THREAD_DATA;

#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
struct LINEAR_SYSTEM_DATA;
typedef struct LINEAR_SYSTEM_DATA LINEAR_SYSTEM_DATA;
typedef struct LINEAR_SYSTEM_DATA
{
  void (*setA)(DATA* data, threadData_t* threadData, LINEAR_SYSTEM_DATA* linearSystemData); /* set matrix A */
  void (*setb)(DATA* data, threadData_t* threadData, LINEAR_SYSTEM_DATA* linearSystemData); /* set vector b (rhs) */
  void (*setAElement)(int row, int col, double value, int nth, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t* threadData);
  void (*setBElement)(int row, double value, LINEAR_SYSTEM_DATA* linearSystemData, threadData_t* threadData);

  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;
  int (*initialAnalyticalJacobian)(DATA* data, threadData_t* threadData, ANALYTIC_JACOBIAN* jacobian);

  void (*residualFunc)(RESIDUAL_USERDATA* userData, const double* x, double* res, const int* flag);
  void (*initializeStaticLSData)(DATA* data, threadData_t* threadData, LINEAR_SYSTEM_DATA* linearSystemData, modelica_boolean initSparsePattern);
  int (*strictTearingFunctionCall)(DATA* data, threadData_t* threadData);
  int (*checkConstraints)(DATA* data, threadData_t* threadData);

  /* attributes of iteration variables */
  modelica_real *min;
  modelica_real *max;
  modelica_real *nominal;

  modelica_integer nnz;                /* number of nonzero entries */
  modelica_integer size;
  modelica_integer equationIndex;      /* index for EQUATION_INFO */
  modelica_integer jacobianIndex;

  modelica_integer method;             /* 0: No Jacobain created for linear system
                                        * 1: Symbolic Jacobian available for linear system */
  modelica_boolean useSparseSolver;    /* true if sparse solver is used */

  LINEAR_SYSTEM_THREAD_DATA* parDynamicData; /* Array of length numMaxThreads for internal write data */

  // ToDo: Gather information from all threads if in parallel region
  modelica_boolean solved;             /* true if solved in current step */
  modelica_boolean failed;             /* true if failed while last try with lapack */

  // ToDo: Gather information from all threads if in parallel region
  /* statistics */
  unsigned long numberOfCall;          /* number of solving calls of this system */
  unsigned long numberOfJEval;         /* number of jacobian evaluations of this system */
  double totalTime;                    /* save the totalTime */
  rtclock_t totalTimeClock;            /* time clock for the totalTime */
  double jacobianTime;                 /* save the time to calculate jacobians */
} LINEAR_SYSTEM_DATA;
#else
typedef void* LINEAR_SYSTEM_DATA;
#endif

#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
typedef struct MIXED_SYSTEM_DATA
{
  modelica_integer size;
  modelica_integer equationIndex;      /* index for EQUATION_INFO */
  modelica_boolean continuous_solution; /* indicates if the continuous part could be solved */

  /* solveContinuousPart */
  void (*solveContinuousPart)(void* data);

  void (*updateIterationExps)(void* data);

  modelica_boolean** iterationVarsPtr;
  modelica_boolean** iterationPreVarsPtr;
  void *solverData;

  modelica_integer method;             /* not used yet */
  modelica_boolean solved;             /* true if solved in current step */
} MIXED_SYSTEM_DATA;
#else
typedef void* MIXED_SYSTEM_DATA;
#endif

#if !defined(OMC_NO_STATESELECTION)
typedef struct STATE_SET_DATA
{
  modelica_integer nCandidates;
  modelica_integer nStates;
  modelica_integer nDummyStates;       /* nCandidates - nStates */

  VAR_INFO* A;
  modelica_integer* rowPivot;
  modelica_integer* colPivot;
  modelica_real* J;

  VAR_INFO** states;
  VAR_INFO** statescandidates;

  /* if analyticalJacobianColumn != NULL analyticalJacobian is available and
   * can be produced with the help of analyticalJacobianColumnn function pointer
   * which is a generic column of the jacobian matrix. (see ANALYTIC_JACOBIAN)
   *
   * if analyticalJacobianColumn == NULL no analyticalJacobian is available
   */
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;
  int (*initialAnalyticalJacobian)(DATA* data, threadData_t* threadData, ANALYTIC_JACOBIAN* jacobian);
  modelica_integer jacobianIndex;
} STATE_SET_DATA;
#else
typedef void* STATE_SET_DATA;
#endif

typedef struct DAEMODE_DATA
{
  long nResidualVars;                  /* number of dae residual variables */
  long nAlgebraicDAEVars;              /* number of algebraic variables */
  long nAuxiliaryVars;                 /* number of algebraic variables */
  modelica_real* residualVars;         /* workspace for the residual variables */
  modelica_real* auxiliaryVars;        /* workspace for the auxiliary variables */
  SPARSE_PATTERN* sparsePattern;       /* daeMode sparse pattern */
  int (*evaluateDAEResiduals)(DATA*, threadData_t*, int); /* function to evaluate dynamic equations for DAE solver */
  int *algIndexes;                     /* index of the algebraic DAE variable in original order */
} DAEMODE_DATA;

typedef struct INLINE_DATA
{
  modelica_real dt;                    /* step size for inline step */
  modelica_real* algVars;              /* alg-state variables */
  modelica_real* algOldVars;           /* old alg-state variables */
} INLINE_DATA;

typedef struct MODEL_DATA_XML
{
  const char *fileName;
  const char *infoXMLData;
  size_t modelInfoXmlLength;
  long nFunctions;
  long nEquations;
  long nProfileBlocks;
  FUNCTION_INFO *functionNames;        /* lazy loading; read from file if it is NULL when accessed */
  EQUATION_INFO *equationInfo;         /* lazy loading; read from file if it is NULL when accessed */
} MODEL_DATA_XML;

typedef struct MODEL_DATA
{
  STATIC_REAL_DATA* realVarsData;      /* states + derived states + algs + (constrainsVars+FinalconstrainsVars) + discrete */
  STATIC_INTEGER_DATA* integerVarsData;
  STATIC_BOOLEAN_DATA* booleanVarsData;
  STATIC_STRING_DATA* stringVarsData;

  STATIC_REAL_DATA* realParameterData;
  STATIC_INTEGER_DATA* integerParameterData;
  STATIC_BOOLEAN_DATA* booleanParameterData;
  STATIC_STRING_DATA* stringParameterData;

  DATA_REAL_ALIAS* realAlias;
  DATA_INTEGER_ALIAS* integerAlias;
  DATA_BOOLEAN_ALIAS* booleanAlias;
  DATA_STRING_ALIAS* stringAlias;

  STATIC_REAL_DATA* realSensitivityData;

  MODEL_DATA_XML modelDataXml;         /* TODO: Rename me? */

  const char* modelName;
  const char* modelFilePrefix;
  char* resultFileName;                /* default is <modelFilePrefix>_res.mat, but it can be overriden using -r=<resultFilename> */
  const char* modelDir;
  const char* modelGUID;
  const char* initXMLData;
  char* resourcesDir;
  modelica_boolean runTestsuite;       /* true if this model was generated during testing */

  int linearizationDumpLanguage;        /* default is 0-modelica, options: 1-matlab, 2-julia, 3-pythong */
  modelica_boolean create_linearmodel;  /* true if model gets linearized */

  long nSamples;                       /* number of different sample-calls */
  SAMPLE_INFO* samplesInfo;            /* array containing each sample-call */

  long nBaseClocks;                    /* total number of base-clocks*/

  fortran_integer nStates;
  long nVariablesReal;                 /* all Real Variables of the model (states, statesderivatives, algebraics, real discretes) */
  long nDiscreteReal;                  /* only all _discrete_ reals */
  long nVariablesInteger;
  long nVariablesBoolean;
  long nVariablesString;
  long nParametersReal;
  long nParametersInteger;
  long nParametersBoolean;
  long nParametersString;
  long nInputVars;
  long nOutputVars;

  long nZeroCrossings;
  long nRelations;
  long nMathEvents;                    /* number of math triggering functions e.g. cail, floor, integer */
  long nDelayExpressions;
  long nSpatialDistributions;          /* Number of different spatialDistribution-calls. */
  long nExtObjs;
  long nMixedSystems;
  long nLinearSystems;
  long nNonLinearSystems;
  long nStateSets;
  long nInlineVars;                    /* number of additional variables for the inline solver */
  long nOptimizeConstraints;           /* number of additional variables for constraint in dynamic optimization */
  long nOptimizeFinalConstraints;      /* number of additional variables for final constraint in dynamic optimization */

  long nAliasReal;
  long nAliasInteger;
  long nAliasBoolean;
  long nAliasString;

  long nJacobians;

  long nSensitivityVars;
  long nSensitivityParamVars;
  long nSetcVars;
  long ndataReconVars;
} MODEL_DATA;

/**
 * @brief Type of synchronous timer.
 */
typedef enum SYNC_TIMER_TYPE {
  SYNC_BASE_CLOCK,    /**< Base clock */
  SYNC_SUB_CLOCK      /**< Sub-clock */
} SYNC_TIMER_TYPE;

/**
 * @brief Data elements of list data->simulationInfo->intvlTimers.
 * Stores next activation time of synchronous clock idx.
 */
typedef struct SYNC_TIMER {
  int base_idx;               /**< Index of base clock */
  int sub_idx;                /**< Index of sub clock */
  SYNC_TIMER_TYPE type;       /**< Type of clock */
  double activationTime;      /**< Next activation time of clock */
} SYNC_TIMER;

/**
 * @brief Statistics for base- and sub-clocks.
 */
typedef struct CLOCK_STATS {
  modelica_real previousInterval;   /**< Length of previous interval, startInterval at initialization. */
  int count;                        /**< Number of times clock was fired */
  double lastActivationTime;        /**< Last time clock was activated */
} CLOCK_STATS;

/**
 * @brief Information about one sub-clock.
 */
typedef struct SUBCLOCK_DATA {
  RATIONAL shift;                 /**< Shift of clock compared to base-clock.
                                   *  For shiftSample(u, shiftCounter, resolution) this is shiftCounter/resolution,
                                   *  for backSample((u, backCounter, resolution)) this is backCounter/resolution. */
  RATIONAL factor;                /**< Factor on how much slower/faster the sub-clock is compared to base-clock.
                                   *   For subSample(u,factor) this is factor/1,
                                   *   for superSample(u,factor) this is 1/factor. */
  const char* solverMethod;       /**< Integration method to solve differential equations in clocked discretized continuous-time partition */
  modelica_boolean holdEvents;    /**< Trigger event at activation time of clock if true. */

  CLOCK_STATS stats;
} SUBCLOCK_DATA;

/**
 * @brief Base-clock data.
 *
 * Containing its sub-clocks.
 */
typedef struct BASECLOCK_DATA {
  int intervalCounter;
  int resolution;     /* Should be cosntant, defaults to 1 */

  double interval;    // is intervalCounter/resolution

  SUBCLOCK_DATA* subClocks;       /**< Array with sub-clocks */
  int nSubClocks;                 /**< Number of sub-clocks */
  modelica_boolean isEventClock;  /**< true if base-clock is a event clock */

  CLOCK_STATS stats;
  //SolverMethod solverMethod;
} BASECLOCK_DATA;

typedef struct SPATIAL_DISTRIBUTION_DATA {
  unsigned int index;
  modelica_boolean isInitialized;

  modelica_real oldPosX;

  DOUBLE_ENDED_LIST* transportedQuantity;
  DOUBLE_ENDED_LIST* storedEvents;
  int lastStoredEventValue;
} SPATIAL_DISTRIBUTION_DATA;

typedef struct SIMULATION_INFO
{
  modelica_real startTime;             /* Start time of the simulation */
  modelica_real stopTime;              /* Stop time of the simulation */
  int useStopTime;
  modelica_integer numSteps;
  modelica_real stepSize;
  modelica_real minStepSize;           /* defines the minimal step size */
  modelica_real tolerance;
  const char *solverMethod;
  const char *outputFormat;
  const char *variableFilter;

  double loggingTimeRecord[2];         /* Time interval in which logging is active. Only used if useLoggingTime=1 */
  int useLoggingTime;                  /* 0 if logging is currently disabled, 1 if enabled */

  LINEAR_SOLVER lsMethod;              /* linear solver */
  LINEAR_SPARSE_SOLVER lssMethod;      /* linear sparse solver */
  int mixedMethod;                     /* mixed solver */

  NONLINEAR_SOLVER nlsMethod;          /* nonlinear solver */
  NEWTON_STRATEGY newtonStrategy;      /* newton damping strategy solver */
  int nlsCsvInfomation;                /* = 1 csv files with detailed nonlinear solver process are generated */
  NLS_LS nlsLinearSolver;              /* nls linear solver */

  EVAL_CONTEXT currentContext;         /* Simulation context */
  EVAL_CONTEXT currentContextOld;      /* Previous value of currentContext */
  int jacobianEvals;                   /* number of different columns to evaluate functionODE */
  int currentJacobianEval;             /* current column to evaluate functionODE for Jacobian */

  int homotopySteps;                   /* the number of homotopy lambda steps during initialization, =0 no homotopy was used */
  double lambda;                       /* homotopy parameter E [0, 1.0] */

  /* indicators for simulations state */
  modelica_boolean initial;            /* true during initialization */
  modelica_boolean terminal;           /* true at the end of the simulation */
  modelica_boolean discreteCall;       /* true for a discrete step */
  modelica_boolean needToIterate;      /* true if reinit has been activated, iteration about the system is needed */
  modelica_boolean simulationSuccess;  /* =0 the simulation run successful, otherwise an error code is set */ // FIXME why is this a boolean?
  modelica_boolean sampleActivated;    /* true if a sample expresion is going to be actived */
  modelica_boolean solveContinuous;    /* true during continuous integration to avoid zero-crossings jumps */
  modelica_boolean noThrowDivZero;     /* true if solving nonlinear system to avoid THROW for division by zero */
  modelica_boolean noThrowAsserts;     /* true if asserts can be ignored, e.g. when searching for an event location */
  modelica_boolean needToReThrow;      /* true if an ignored asserts was found, and may need to be rethrown */

  double solverSteps;                  /* Number of integration steps so far for writing to the result file */ // FIXME why is this not an integer?

  void** extObjs;                      /* External objects */

  double nextSampleEvent;              /* point in time of next sample-call */
  double *nextSampleTimes;             /* array of next sample time */ // TODO ringbuffer
  modelica_boolean *samples;           /* array of the current value for all sample-calls */

  BASECLOCK_DATA *baseClocks;          /* Containing simulation data for clocks. E.g interval and next evaluation time */
  LIST* intvlTimers;                   /* Sorted list with next actiavtion time for each base-clock partition. */

  SPATIAL_DISTRIBUTION_DATA* spatialDistributionData;     /* Array of spatialDistribution data */

  modelica_real* zeroCrossings;
  modelica_real* zeroCrossingsPre;
  modelica_real* zeroCrossingsBackup;  /* used by bisection in event.c */
  modelica_boolean* relations;
  modelica_boolean* relationsPre;
  modelica_boolean* storedRelations;   /* this array contains a copy of relations each time the event iteration starts */
  modelica_real* mathEventsValuePre;
  long* zeroCrossingIndex;             /* := {0, 1, 2, ..., data->modelData->nZeroCrossings-1}; pointer for a list events at event instants */
  modelica_real* states_left;          /* work array for findRoot in event.c */
  modelica_real* states_right;         /* work array for findRoot in event.c */

  /* old vars for event handling */
  modelica_real timeValueOld;
  modelica_real* realVarsOld;
  modelica_integer* integerVarsOld;
  modelica_boolean* booleanVarsOld;
  modelica_string* stringVarsOld;

  modelica_real* realVarsPre;
  modelica_integer* integerVarsPre;
  modelica_boolean* booleanVarsPre;
  modelica_string* stringVarsPre;

  modelica_real* realParameter;
  modelica_integer* integerParameter;
  modelica_boolean* booleanParameter;
  modelica_string* stringParameter;

  modelica_real* inputVars;
  modelica_real* outputVars;
  modelica_real* setcVars;
  modelica_real* datainputVars;

  EXTERNAL_INPUT external_input;

  modelica_real* sensitivityMatrix;    /* used by integrator for sensitivity mode */
  int* sensitivityParList;             /* used by integrator for sensitivity mode */

  ANALYTIC_JACOBIAN* analyticJacobians; // TODO Only store information for Jacobian used by integrator here

  NONLINEAR_SYSTEM_DATA* nonlinearSystemData;

  LINEAR_SYSTEM_DATA* linearSystemData;
  int currentLinearSystemIndex;

  MIXED_SYSTEM_DATA* mixedSystemData;

  STATE_SET_DATA* stateSetData;

  DAEMODE_DATA* daeModeData;

  INLINE_DATA* inlineData;

  void* backupSolverData;              /* Used for generic Runge-Kutta methods to get access to some solver details inside callbacks */

  /* delay vars */
  RINGBUFFER **delayStructure;         /* Array of ring buffers for delay expressions */
  const char *OPENMODELICAHOME;

  CHATTERING_INFO chatteringInfo;
  CALL_STATISTICS callStatistics;      /* used to store the number of function evaluations */
} SIMULATION_INFO;

/* collects all dynamic model data like the variable-values */
typedef struct SIMULATION_DATA
{
  modelica_real timeValue;

  modelica_real* realVars;
  modelica_integer* integerVars;
  modelica_boolean* booleanVars;
  modelica_string* stringVars;

  modelica_real* inlineVars;           /* needed for the inline solver */

} SIMULATION_DATA;

#if !defined(OMC_MINIMAL_RUNTIME)
typedef struct {
  int enabled;
  double scaling;
  double time;
  rtclock_t clock;
  int64_t maxLate;
} real_time_sync_t;
#endif

/* top-level struct to collect dynamic and static model data */
typedef struct DATA
{
  RINGBUFFER* simulationData;          /* RINGBUFFER of SIMULATION_DATA */
  SIMULATION_DATA **localData;
  MODEL_DATA *modelData;               /* static stuff */
  SIMULATION_INFO *simulationInfo;
  struct OpenModelicaGeneratedFunctionCallbacks *callback;
#if !defined(OMC_MINIMAL_RUNTIME)
  void *embeddedServerState;           /* Variable sent around controlling the state of the embedded server */
  real_time_sync_t real_time_sync;
#endif
} DATA;

#include "openmodelica_func.h"

#endif
