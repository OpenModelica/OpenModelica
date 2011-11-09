/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/* File: modelica.h
 * Description: This is the C header file for the C code generated from
 * Modelica. It includes e.g. the C object representation of the builtin types
 * and arrays, etc.
 */

#ifndef OPENMODELICA_H_
#define OPENMODELICA_H_

#if defined(__cplusplus)
extern "C" {
#endif

#include <stdlib.h>
#include <limits.h>
#include <float.h>
#include <assert.h>

/* adrpo: extreme windows crap! */
#if defined(__MINGW32__) || defined(_MSC_VER)
#define DLLImport   __declspec( dllimport )
#define DLLExport   __declspec( dllexport )
#else
#define DLLImport extern
#define DLLExport /* nothing */
#endif

#if defined(IMPORT_INTO)
#define DLLDirection DLLImport
#else /* we export from the dll */
#define DLLDirection DLLExport
#endif

typedef void* modelica_complex; /* currently only External objects are represented using modelica_complex.*/
typedef void* modelica_metatype; /* MetaModelica extension, added by sjoelund */
/* MetaModelica extension.
We actually store function-pointers in lists, etc...
So it needs to be void*. If we use a platform with different sizes of function-
pointers, some changes need to be done to code generation */
typedef void* modelica_fnptr;

#if defined(__MINGW32__) || defined(_MSC_VER)
 #define WIN32_LEAN_AND_MEAN
#if !defined(NOMINMAX)
 #define NOMINMAX
 #include <Windows.h>
#endif
#endif

/* BEFORE: compat.h */
#if defined(__MINGW32__) || defined(_MSC_VER)
#define EXIT(code) exit(code)
#else
/* We need to patch exit() on Unix systems
 * It does not change the exit code of simulations for some reason! */
#include <unistd.h>
#define EXIT(code) {fflush(NULL); _exit(code);}
#endif

/* BEFORE: inline.h */
#if defined(_MSC_VER)
/* Visual C++ */
# ifndef inline
#  define inline __inline
# endif
#elif defined(__GNUC__)
/* GCC */
# ifndef inline
#  define inline __inline__
# endif
#else
/* Otherwise, leave inline undefined, all functions
 * using inline is also static, so it will hold. */
#endif

/* BEFORE: modelica_string.h */
#ifdef __OPENMODELICA__METAMODELICA
/* When MetaModelica grammar is enabled, all strings are boxed */
typedef modelica_metatype modelica_string_t;
typedef const modelica_metatype modelica_string_const;
typedef modelica_string_t modelica_string;
#else
typedef char* modelica_string_t;
typedef const char* modelica_string_const;
typedef modelica_string_const modelica_string;
#endif


/* BEFORE: #include "memory_pool.h" */
typedef double      m_real;
typedef long        m_integer;
typedef const char* m_string;
typedef signed char m_boolean;
typedef m_integer   _index_t;

struct state_s {
  _index_t buffer;
  _index_t offset;
};

typedef struct state_s state;

/* BEFORE: #include "index_spec.h" */
/* This structure holds indexes when subscripting an array.
 * ndims - number of subscripts, E.g. A[1,{2,3},:] => ndims = 3
 * dim_size - dimension size of each subscript, Eg. A[1,{2,3},:,{3}] => dim_size={1,2,0,1}
 * spec_type - index type for each index, 'S' for scalar, 'A' for array, 'W' for whole dimension (:)
 *     Eg. A[1,{2,3},:,{3}] => spec_type = {'S','A','W','A'}.
 *     spec_type is required to be able to distinguish between {1} and 1 as an index.
 * index - pointer to all indices (except of type 'W'), eg A[1,{2,3},:,{3}] => index -> {1,2,3,3}
*/
struct index_spec_s
{
  _index_t ndims;  /* number of indices/subscripts */
  _index_t* dim_size; /* size for each subscript */
  char* index_type;  /* type of each subscript, any of 'S','A' or 'W' */
  _index_t** index; /* all indices*/
};
typedef struct index_spec_s index_spec_t;


/* BEFORE: #include "base_array.h" */
struct base_array_s
{
  int ndims;
  _index_t *dim_size;
  void *data;
};

typedef struct base_array_s base_array_t;


/* BEFORE: #include "string_array.h" */
typedef base_array_t string_array_t;

/* BEFORE: #include "boolean_array.h" */
typedef signed char modelica_boolean;
typedef base_array_t boolean_array_t;


/* BEFORE: #include "real_array.h" */
typedef double modelica_real;
typedef base_array_t real_array_t;

/* BEFORE: #include "integer_array.h" */
typedef m_integer modelica_integer;
typedef base_array_t integer_array_t;

/* BEFORE: fortran_types */
#if defined(__alpha__) || defined(__sparc64__) || defined(__x86_64__) || defined(__ia64__)
typedef int fortran_integer;
typedef unsigned int fortran_uinteger;
#else
typedef long int fortran_integer;
typedef unsigned long int fortran_uinteger;
#endif

/* BEFORE: simulation_runtime.h */
typedef struct sim_DATA_REAL_ALIAS {
  modelica_real* alias;
  int negate;
  int nameID;
} DATA_REAL_ALIAS;

typedef struct sim_DATA_INT_ALIAS {
  modelica_integer* alias;
  int negate;
  int nameID;
} DATA_INT_ALIAS;

typedef struct sim_DATA_BOOL_ALIAS {
  modelica_boolean* alias;
  int negate;
  int nameID;
} DATA_BOOL_ALIAS;

typedef struct sim_DATA_STRING_ALIAS {
  char** alias;
  int negate;
  int nameID;
} DATA_STRING_ALIAS;

typedef struct sim_DATA_STRING {
  const char** algebraics;
  const char** parameters;
  const char** inputVars;
  const char** outputVars;
  const char** algebraics_saved;
  DATA_STRING_ALIAS* alias;

  long nAlgebraic,nParameters;
  long nInputVars,nOutputVars;
  long nAlias;
} DATA_STRING;

typedef struct sim_DATA_INT {
  modelica_integer* algebraics;
  modelica_integer* parameters;
  modelica_integer* inputVars;
  modelica_integer* outputVars;
  modelica_integer*  algebraics_old, *algebraics_old2, *algebraics_saved;
  DATA_INT_ALIAS* alias;
  modelica_boolean* algebraicsFilterOutput; /* True if this variable should be filtered */
  modelica_boolean* aliasFilterOutput; /* True if this variable should be filtered */

  long nAlgebraic,nParameters;
  long nInputVars,nOutputVars;
  long nAlias;
} DATA_INT;

typedef struct sim_DATA_BOOL {
  modelica_boolean* algebraics;
  modelica_boolean* parameters;
  modelica_boolean* inputVars;
  modelica_boolean* outputVars;
  modelica_boolean* algebraics_old, *algebraics_old2, *algebraics_saved;
  DATA_BOOL_ALIAS* alias;
  modelica_boolean* algebraicsFilterOutput; /* True if this variable should be filtered */
  modelica_boolean* aliasFilterOutput; /* True if this variable should be filtered */

  long nAlgebraic,nParameters;
  long nInputVars,nOutputVars;
  long nAlias;
} DATA_BOOL;

typedef struct sample_raw_time_st {
  double start;
  double interval;
  int zc_index;
} sample_raw_time;

typedef struct sample_time_st {
  double events;
  int zc_index;
  int activated;
} sample_time;

typedef struct sim_DATA {
  /* this is the data structure for saving important data for this simulation. */
  /* Each generated function have a DATA* parameter wich contain the data. */
  /* A object for the data can be created using */
  /* initializeDataStruc() function*/
  double* states;
  double* statesDerivatives;
  double* algebraics;
  double* parameters;
  double* inputVars;
  double* outputVars;
  double* helpVars, *helpVars_saved;
  double* initialResiduals;
  double* jacobianVars;

  /* True if the variable should be filtered */
  modelica_boolean* statesFilterOutput;
  modelica_boolean* statesDerivativesFilterOutput;
  modelica_boolean* algebraicsFilterOutput;
  modelica_boolean* aliasFilterOutput;

  /* Old values used for extrapolation */
  double* states_old,*states_old2,*states_saved;
  double* statesDerivatives_old,*statesDerivatives_old2,*statesDerivatives_saved;
  double* algebraics_old,*algebraics_old2,*algebraics_saved;
  double oldTime,oldTime2;
  double current_stepsize;

  /* Backup derivative for dassl */
  double* statesDerivativesBackup;
  double* statesBackup;

  char* initFixed; /* Fixed attribute for all variables and parameters */
  char* var_attr; /* Type attribute for all variables and parameters */
  int init; /* =1 during initialization, 0 otherwise. */
  int terminal; /* =1 at the end of the simulation, 0 otherwise. */
  void** extObjs; /* External objects */
  /* nStatesDerivatives == states */
  fortran_integer nStates,nAlgebraic,nParameters;
  long nInputVars,nOutputVars,nFunctions,nEquations,nProfileBlocks;
  long nZeroCrossing/*NG*/;
  fortran_integer nJacobianvars;
  long nRelations/*NREL*/;
  long nInitialResiduals/*NR*/;
  long nHelpVars/* NHELP */;
  /* extern char init_fixed[]; */
  DATA_STRING stringVariables;
  DATA_INT intVariables;
  DATA_BOOL boolVariables;

  DATA_REAL_ALIAS* realAlias;
  long nAlias;

  const char* modelName; /* For error messages */
  const char* modelFilePrefix; /* For filenames, input/output */
  const char* modelGUID; /* to check if the model_init.xml match the model */
  const struct omc_varInfo* statesNames;
  const struct omc_varInfo* stateDerivativesNames;
  const struct omc_varInfo* algebraicsNames;
  const struct omc_varInfo* parametersNames;
  const struct omc_varInfo* alias_names;
  const struct omc_varInfo* int_alg_names;
  const struct omc_varInfo* int_param_names;
  const struct omc_varInfo* int_alias_names;
  const struct omc_varInfo* bool_alg_names;
  const struct omc_varInfo* bool_param_names;
  const struct omc_varInfo* bool_alias_names;
  const struct omc_varInfo* string_alg_names;
  const struct omc_varInfo* string_param_names;
  const struct omc_varInfo* string_alias_names;
  const struct omc_varInfo* inputNames;
  const struct omc_varInfo* outputNames;
  const struct omc_varInfo* jacobian_names;
  const struct omc_functionInfo* functionNames;
  const struct omc_equationInfo* equationInfo;
  const int* equationInfo_reverse_prof_index;

  double startTime; /* the start time of the simulation */
  double timeValue; /* the time for the simulation */
  /* used in some generated function */
  /* this is not changed by initializeDataStruc */
  double lastEmittedTime; /* The last time value that has been emitted. */
  int forceEmit; /* when != 0 force emit, set e.g. by newTime for equidistant output signal. */

  /* An array containing the initial data of samples used in the sim */
  sample_raw_time* rawSampleExps;
  long nRawSamples;
  /* The queue of sample time events to be processed. */
  sample_time* sampleTimes; /* Warning: Not implemented yet!? */
  long curSampleTimeIx;
  long nSampleTimes;
} DATA;



/* math functions (-lm)*/

/* Special Modelica builtin functions*/
#define smooth(P,EXP)    (EXP)
#define semiLinear(x,positiveSlope,negativeSlope) (x>=0?positiveSlope*x:negativeSlope*x)

/* sign function */
#define sign(v) (v>0?1:(v<0?-1:0))

#if defined(_MSC_VER)
#define fmax(x, y) ((x>y)?x:y)
#define fmin(x, y) ((x<y)?x:y)
#define snprintf sprintf_s
#endif

#if defined(__cplusplus)
}
#endif

#endif
