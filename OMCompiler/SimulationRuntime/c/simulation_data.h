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
#include "util/ringbuffer.h"
#include "util/omc_error.h"
#include "util/rtclock.h"
#include "util/rational.h"
#include "util/list.h"

#define omc_dummyVarInfo {-1,-1,"","",omc_dummyFileInfo}
#define omc_dummyEquationInfo {-1,0,0,-1,NULL}
#define omc_dummyFunctionInfo {-1,"",omc_dummyFileInfo}
#define omc_dummyRealAttribute {NULL,NULL,-DBL_MAX,DBL_MAX,0,0,1.0,0.0}

#if defined(_MSC_VER)
#define set_struct(TYPE, x, info) { const TYPE tmp = info; x = tmp; }
#else
#define set_struct(TYPE, x, info) x = (TYPE)info
#endif

/* Forward declaration of DATA to avoid warnings in NONLINEAR_SYSTEM_DATA. */
struct DATA;

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
}EQUATION_INFO;

typedef struct FUNCTION_INFO
{
  int id;
  const char* name;
  FILE_INFO info;
}FUNCTION_INFO;

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

typedef enum {ERROR_AT_TIME,NO_PROGRESS_START_POINT,NO_PROGRESS_FACTOR,IMPROPER_INPUT} equationSystemError;

/* SPARSE_PATTERN
 *
 * sparse pattern struct used by jacobians
 * leadindex points to an index where to corresponding
 * index of an row or column is noted in index.
 * sizeofIndex contain number of elements in index
 * colorsCols contain color of colored columns
 *
 * Use freeSparsePattern(SPARSE_PATTERM *spp) for "destruction" (see util/jacobian_util.c/h).
 *
 */
typedef struct SPARSE_PATTERN
{
  unsigned int* leadindex;
  unsigned int* index;
  unsigned int sizeofIndex;
  unsigned int* colorCols;
  unsigned int numberOfNoneZeros;
  unsigned int maxColors;
}SPARSE_PATTERN;

/* ANALYTIC_JACOBIAN
 *
 * analytic jacobian struct used for dassl and linearization.
 * jacobianName contain "A" || "B" etc.
 * sizeCols contain size of column
 * sizeRows contain size of rows
 * sparsePattern contain the sparse pattern include colors
 * seedVars contain seed vector to the corresponding jacobian
 * resultVars contain result of one column to the corresponding jacobian
 * jacobian contains dense jacobian elements
 *
 * Use freeAnalyticJacobian(ANALYTIC_JACOBIAN *jac) for "destruction" (see util/jacobian_util.c/h).
 */
typedef struct ANALYTIC_JACOBIAN
{
  unsigned int sizeCols;
  unsigned int sizeRows;
  unsigned int sizeTmpVars;
  SPARSE_PATTERN* sparsePattern;
  modelica_real* seedVars;
  modelica_real* tmpVars;
  modelica_real* resultVars;
  int (*constantEqns)(void* data, threadData_t *threadData, void* thisJacobian, void* parentJacobian);
}ANALYTIC_JACOBIAN;

/* EXTERNAL_INPUT
 *
 * extern input for dassl and optimization
 *
 */
typedef struct EXTERNAL_INPUT
{
  modelica_boolean active;
  modelica_real** u;
  modelica_real* t;
  modelica_integer N;
  modelica_integer n;
  modelica_integer i;
}EXTERNAL_INPUT;

/* Alias data with various types*/
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
}REAL_ATTRIBUTE;

typedef struct INTEGER_ATTRIBUTE
{
  modelica_integer min;                /* = -Inf */
  modelica_integer max;                /* = +Inf */
  modelica_boolean fixed;              /* depends on the type */
  modelica_integer start;              /* = 0 */
}INTEGER_ATTRIBUTE;

typedef struct BOOLEAN_ATTRIBUTE
{
  modelica_boolean fixed;              /* depends on the type */
  modelica_boolean start;              /* = false */
}BOOLEAN_ATTRIBUTE;

typedef struct STRING_ATTRIBUTE
{
  modelica_string start;               /* = "" */
}STRING_ATTRIBUTE;

typedef struct STATIC_REAL_DATA
{
  VAR_INFO info;
  REAL_ATTRIBUTE attribute;
  modelica_boolean filterOutput;       /* true if this variable should be filtered */
  modelica_boolean time_unvarying;     /* true if the value is only computed once during initialization */
}STATIC_REAL_DATA;

typedef struct STATIC_INTEGER_DATA
{
  VAR_INFO info;
  INTEGER_ATTRIBUTE attribute;
  modelica_boolean filterOutput;       /* true if this variable should be filtered */
  modelica_boolean time_unvarying;     /* true if the value is only computed once during initialization */
}STATIC_INTEGER_DATA;

typedef struct STATIC_BOOLEAN_DATA
{
  VAR_INFO info;
  BOOLEAN_ATTRIBUTE attribute;
  modelica_boolean filterOutput;       /* true if this variable should be filtered */
  modelica_boolean time_unvarying;     /* true if the value is only computed once during initialization */
}STATIC_BOOLEAN_DATA;

typedef struct STATIC_STRING_DATA
{
  VAR_INFO info;
  STRING_ATTRIBUTE attribute;
  modelica_boolean filterOutput;       /* true if this variable should be filtered */
  modelica_boolean time_unvarying;     /* true if the value is only computed once during initialization */
}STATIC_STRING_DATA;

#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
typedef struct NONLINEAR_SYSTEM_DATA
{
  modelica_integer size;
  modelica_integer equationIndex;      /* index for EQUATION_INFO */

  modelica_boolean homotopySupport;    /* 1 if homotopy is available, 0 otherwise */
  modelica_boolean initHomotopy;       /* 1 if the homotopy solver should be used to solve the initial system, 0 otherwise */
  modelica_boolean mixedSystem;        /* 1 if the system contains discrete variables, 0 otherwise */
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
  int (*analyticalJacobianColumn)(void*, threadData_t*, ANALYTIC_JACOBIAN*, ANALYTIC_JACOBIAN* parentJacobian);
  int (*initialAnalyticalJacobian)(void*, threadData_t*, ANALYTIC_JACOBIAN*);
  modelica_integer jacobianIndex;

  SPARSE_PATTERN *sparsePattern;        /* sparse pattern if no jacobian is available */
  modelica_boolean isPatternAvailable;

  void (*residualFunc)(void**, const double*, double*, const int*);
  int (*residualFuncConstraints)(void**, const double*, double*, const int*);
  void (*initializeStaticNLSData)(void*, threadData_t *threadData, void*);
  int (*strictTearingFunctionCall)(struct DATA*, threadData_t *threadData);
  void (*getIterationVars)(struct DATA*, double*);
  int (*checkConstraints)(struct DATA*, threadData_t *threadData);

  void *solverData;
  modelica_real *nlsx;                 /* x */
  modelica_real *nlsxOld;              /* previous x */
  modelica_real *nlsxExtrapolation;    /* extrapolated values for x from old and old2 - used as initial guess */

  void *oldValueList;                  /* old values organized in a sorted list for extrapolation and interpolate, respectively */
  modelica_real *resValues;            /* memory space for evaluated residual values */

  modelica_real residualError;         /* not used */
  modelica_boolean solved;             /* 1: solved in current step - else not */
  modelica_real lastTimeSolved;        /* save last successful solved point in time */

  /* statistics */
  unsigned long numberOfCall;          /* number of solving calls of this system */
  unsigned long numberOfFEval;         /* number of function evaluations of this system */
  unsigned long numberOfJEval;         /* number of jacobian evaluations of this system */
  unsigned long numberOfIterations;    /* number of iteration of non-linear solvers of this system */
  double totalTime;                    /* save the totalTime */
  rtclock_t totalTimeClock;            /* time clock for the totalTime  */
  double jacobianTime;                 /* save the time to calculate jacobians */
  rtclock_t jacobianTimeClock;         /* time clock for the jacobianTime  */
  void* csvData;                       /* information to save csv data */
} NONLINEAR_SYSTEM_DATA;
#else
typedef void* NONLINEAR_SYSTEM_DATA;
#endif

typedef struct LINEAR_SYSTEM_THREAD_DATA
{
  void *solverData[2];                  /* [1] is the totalPivot solver
                                           [0] holds other solvers
                                           both are used for the default solver */
  modelica_real *x;                     /* solution vector x */
  modelica_real *A;                     /* matrix A */
  modelica_real *b;                     /* vector b */

  modelica_real residualError;          /* not used yet*/

  ANALYTIC_JACOBIAN* parentJacobian;    /* if != NULL then it's the parent jacobian matrix */
  ANALYTIC_JACOBIAN* jacobian;          /* jacobian */

  /* Statistics for each thread */
  unsigned long numberOfCall;           /* number of solving calls of this system */
  unsigned long numberOfJEval;          /* number of jacobian evaluations of this system */
  double totalTime;                     /* save the totalTime */
  rtclock_t totalTimeClock;             /* time clock for the totalTime  */
  double jacobianTime;                  /* save the time to calculate jacobians */
}LINEAR_SYSTEM_THREAD_DATA;

#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
typedef struct LINEAR_SYSTEM_DATA
{
  /* set matrix A */
  void (*setA)(void* data, threadData_t *threadData, void* systemData);
  /* set vector b (rhs) */
  void (*setb)(void* data, threadData_t *threadData, void* systemData);

  void (*setAElement)(int row, int col, double value, int nth, void *data, threadData_t *threadData);
  void (*setBElement)(int row, double value, void *data, threadData_t *threadData);

  int (*analyticalJacobianColumn)(void*, threadData_t*, ANALYTIC_JACOBIAN*, ANALYTIC_JACOBIAN* parentJacobian);
  int (*initialAnalyticalJacobian)(void*, threadData_t*, ANALYTIC_JACOBIAN*);

  void (*residualFunc)(void**, const double*, double*, const int*);
  void (*initializeStaticLSData)(void*, threadData_t *threadData, void*);
  int (*strictTearingFunctionCall)(struct DATA*, threadData_t *threadData);
  int (*checkConstraints)(struct DATA*, threadData_t *threadData);

  /* attributes of iteration variables */
  modelica_real *min;
  modelica_real *max;
  modelica_real *nominal;

  modelica_integer nnz;                 /* number of nonzero entries */
  modelica_integer size;
  modelica_integer equationIndex;       /* index for EQUATION_INFO */
  modelica_integer jacobianIndex;

  modelica_integer method;              /* not used yet*/
  modelica_boolean useSparseSolver;     /* 1: use sparse solver, - else any solver */

  LINEAR_SYSTEM_THREAD_DATA* parDynamicData; /* Array of length numMaxThreads for internal write data */

  // ToDo: Gather information from all threads if in parallel region
  modelica_boolean solved;              /* 1: solved in current step - else not */
  modelica_boolean failed;              /* 1: failed while last try with lapack - else not */

  // ToDo: Gather information from all threads if in parallel region
  /* statistics */
  unsigned long numberOfCall;           /* number of solving calls of this system */
  unsigned long numberOfJEval;          /* number of jacobian evaluations of this system */
  double totalTime;                     /* save the totalTime */
  rtclock_t totalTimeClock;             /* time clock for the totalTime  */
  double jacobianTime;                  /* save the time to calculate jacobians */
}LINEAR_SYSTEM_DATA;
#else
typedef void* LINEAR_SYSTEM_DATA;
#endif

#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
typedef struct MIXED_SYSTEM_DATA
{
  modelica_integer size;
  modelica_integer equationIndex;       /* index for EQUATION_INFO */
  modelica_boolean continuous_solution; /* indicates if the continuous part could be solved */

  /* solveContinuousPart */
  void (*solveContinuousPart)(void* data);

  void (*updateIterationExps)(void* data);

  modelica_boolean** iterationVarsPtr;
  modelica_boolean** iterationPreVarsPtr;
  void *solverData;

  modelica_integer method;          /* not used yet */
  modelica_boolean solved;          /* 1: solved in current step - else not */
}MIXED_SYSTEM_DATA;
#else
typedef void* MIXED_SYSTEM_DATA;
#endif

#if !defined(OMC_NO_STATESELECTION)
typedef struct STATE_SET_DATA
{
  modelica_integer nCandidates;
  modelica_integer nStates;
  modelica_integer nDummyStates;    /* nCandidates - nStates */

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
  int (*analyticalJacobianColumn)(void*, threadData_t*, ANALYTIC_JACOBIAN*, ANALYTIC_JACOBIAN* parentJacobian);
  int (*initialAnalyticalJacobian)(void*, threadData_t*, ANALYTIC_JACOBIAN*);
  modelica_integer jacobianIndex;
}STATE_SET_DATA;
#else
typedef void* STATE_SET_DATA;
#endif

typedef struct DAEMODE_DATA
{
  /* number of dae residual variables */
  long nResidualVars;

  /* number of algebraic variables */
  long nAlgebraicDAEVars;

  /* number of algebraic variables */
  long nAuxiliaryVars;

  /* workspace for the residual variables */
  modelica_real* residualVars;

  /* workspace for the auxiliary variables */
  modelica_real* auxiliaryVars;

  /* daeMode sparse pattern */
  SPARSE_PATTERN* sparsePattern;

  /* function to evaluate dynamic equations for DAE solver*/
  int (*evaluateDAEResiduals)(struct DATA*, threadData_t*, int);

  /* index of the algebraic DAE variable in original order */
  int *algIndexes;

} DAEMODE_DATA;

typedef struct INLINE_DATA
{
  /* step size for inline step */
  modelica_real dt;
  /* alg-state variables */
  modelica_real* algVars;
  /* old alg-state variables */
  modelica_real* algOldVars;
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

typedef struct SUBCLOCK_INFO {
  RATIONAL shift;
  RATIONAL factor;
  const char* solverMethod;
  modelica_boolean holdEvents;
} SUBCLOCK_INFO;

typedef struct CLOCK_INFO {
  long nSubClocks;
  SUBCLOCK_INFO* subClocks;
  modelica_boolean isBoolClock;
} CLOCK_INFO;

typedef struct MODEL_DATA
{
  STATIC_REAL_DATA* realVarsData;     /* states + derived states + algs + (constrainsVars+FinalconstrainsVars) + discrete */
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
  char* resultFileName;          /* default is <modelFilePrefix>_res.mat, but it can be overriden using -r=<resultFilename> */
  const char* modelDir;
  const char* modelGUID;
  const char* initXMLData;
  char* resourcesDir;

  long nSamples;                       /* number of different sample-calls */
  SAMPLE_INFO* samplesInfo;            /* array containing each sample-call */

  long nClocks;
  CLOCK_INFO* clocksInfo;
  long nSubClocks;
  SUBCLOCK_INFO* subClocksInfo;

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
  long nExtObjs;
  long nMixedSystems;
  long nLinearSystems;
  long nNonLinearSystems;
  long nStateSets;
  long nInlineVars;                    /* number of additional variables for the inline solver */
  long nOptimizeConstraints;           /* number of additional variables for constraint in dynamic optimization*/
  long nOptimizeFinalConstraints;      /* number of additional variables for final constraint in dynamic optimization*/

  long nAliasReal;
  long nAliasInteger;
  long nAliasBoolean;
  long nAliasString;

  long nJacobians;

  long nSensitivityVars;
  long nSensitivityParamVars;
  long nSetcVars;
  long ndataReconVars;
}MODEL_DATA;

typedef struct CLOCK_DATA {
  modelica_real interval;
  modelica_real timepoint;
  long cnt;
} CLOCK_DATA;

enum EVAL_CONTEXT
{
  CONTEXT_UNKNOWN = 0,

  CONTEXT_ODE,
  CONTEXT_ALGEBRAIC,
  CONTEXT_EVENTS,
  CONTEXT_JACOBIAN,
  CONTEXT_SYM_JACOBIAN,

  CONTEXT_MAX
};

typedef struct SIMULATION_INFO
{
  modelica_real startTime;
  modelica_real stopTime;
  int useStopTime;
  modelica_integer numSteps;
  modelica_real stepSize;
  modelica_real minStepSize;           /* defines the minimal step size */
  modelica_real tolerance;
  const char *solverMethod;
  const char *outputFormat;
  const char *variableFilter;

  int lsMethod;                        /* linear solver */
  int lssMethod;                       /* linear sparse solver */
  int mixedMethod;                     /* mixed solver */

  int nlsMethod;                       /* nonlinear solver */
  int newtonStrategy;                  /* newton damping strategy solver */
  int nlsCsvInfomation;                /* = 1 csv files with detailed nonlinear solver process are generated */
  int nlsLinearSolver;                 /* nls linear solver setting =1 totalpivot, =2 lapack, =3=klu */
  /* current context evaluation, set by dassl and used for extrapolation
   * of next non-linear guess */
  int currentContext;
  int currentContextOld;
  int jacobianEvals;                   /* number of different columns to evaluate functionODE */
  int currentJacobianEval;             /* current column to evaluate functionODE for Jacobian*/

  int homotopySteps;                   /* the number of homotopy lambda steps during initialization, =0 no homotopy was used */
  double lambda;                       /* homotopy parameter E [0, 1.0] */

  /* indicators for simulations state */
  modelica_boolean initial;            /* =1 during initialization, 0 otherwise. */
  modelica_boolean terminal;           /* =1 at the end of the simulation, 0 otherwise. */
  modelica_boolean discreteCall;       /* =1 for a discrete step, otherwise 0 */
  modelica_boolean needToIterate;      /* =1 if reinit has been activated, iteration about the system is needed */
  modelica_boolean simulationSuccess;  /* =0 the simulation run successful, otherwise an error code is set */
  modelica_boolean sampleActivated;    /* =1 a sample expresion if going to be actived, 0 otherwise */
  modelica_boolean solveContinuous;    /* =1 during the continuous integration to avoid zero-crossings jumps,  0 otherwise. */
  modelica_boolean noThrowDivZero;     /* =1 if solving nonlinear system to avoid THROW for division by zero,  0 otherwise. */

  double solverSteps;                  /* Number of integration steps so far for writing to the result file*/

  void** extObjs;                      /* External objects */

  double nextSampleEvent;              /* point in time of next sample-call */
  double *nextSampleTimes;             /* array of next sample time */
  modelica_boolean *samples;           /* array of the current value for all sample-calls */

  LIST* intvlTimers;
  CLOCK_DATA *clocksData;

  modelica_real* zeroCrossings;
  modelica_real* zeroCrossingsPre;
  modelica_real* zeroCrossingsBackup;  /* used by bisection in event.c */
  modelica_boolean* relations;
  modelica_boolean* relationsPre;
  modelica_boolean* storedRelations;   /* this array contains a copy of relations each time the event iteration starts */
  modelica_real* mathEventsValuePre;
  long* zeroCrossingIndex;             /* := {0, 1, 2, ..., data->modelData->nZeroCrossings-1}; pointer for a list events at event instants */

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

  modelica_real* sensitivityMatrix;    /* used by integrator for sensitivity mode  */
  int* sensitivityParList;             /* used by integrator for sensitivity mode  */

  ANALYTIC_JACOBIAN* analyticJacobians;   // ToDo Only store informations for Jacobian used by integrator here

  NONLINEAR_SYSTEM_DATA* nonlinearSystemData;
  int currentNonlinearSystemIndex;

  LINEAR_SYSTEM_DATA* linearSystemData;
  int currentLinearSystemIndex;

  MIXED_SYSTEM_DATA* mixedSystemData;

  STATE_SET_DATA* stateSetData;

  DAEMODE_DATA* daeModeData;

  INLINE_DATA* inlineData;

  /* delay vars */
  double tStart;
  RINGBUFFER **delayStructure;
  const char *OPENMODELICAHOME;

  CHATTERING_INFO chatteringInfo;
  CALL_STATISTICS callStatistics;      /* used to store the number of function evaluations */
} SIMULATION_INFO;

/* collects all dynamic model data like the variabel-values */
typedef struct SIMULATION_DATA
{
  modelica_real timeValue;

  modelica_real* realVars;
  modelica_integer* integerVars;
  modelica_boolean* booleanVars;
  modelica_string* stringVars;

  modelica_real* inlineVars;           /* needed for the inline solver */

}SIMULATION_DATA;

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
  MODEL_DATA *modelData;                /* static stuff */
  SIMULATION_INFO *simulationInfo;
  struct OpenModelicaGeneratedFunctionCallbacks *callback;
#if !defined(OMC_MINIMAL_RUNTIME)
  void *embeddedServerState; /* Variable sent around controlling the state of the embedded server */
  real_time_sync_t real_time_sync;
#endif
} DATA;

#include "openmodelica_func.h"

#endif
