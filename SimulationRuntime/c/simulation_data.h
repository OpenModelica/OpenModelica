/*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-CurrentYear, Link�ping University,
* Department of Computer and Information Science,
* SE-58183 Link�ping, Sweden.
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
* from Link�ping University, either from the above address,
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

/*! \file simulation_data.h
 * Description: This is the C header file to provide all information 
 * for simulation
 */

#ifndef SIMULATION_DATA_H
#define SIMULATION_DATA_H

#include "openmodelica.h"
#include "ringbuffer.h"


#define omc_dummyFileInfo {"",-1,-1,-1,-1,1}
#define omc_dummyVarInfo {-1,"","",omc_dummyFileInfo}
#define omc_dummyEquationInfo {-1,"",-1,NULL}
#define omc_dummyFunctionInfo {-1,"",omc_dummyFileInfo}

  /* Model info structures */
  typedef struct FILE_INFO
  {
    const char* filename;
    int lineStart;
    int colStart;
    int lineEnd;
    int colEnd;
    int readonly;
  }FILE_INFO;

  typedef struct VAR_INFO
  {
    int id;
    const char* name;
    const char* comment;
    const FILE_INFO info;
  }VAR_INFO;

  typedef struct EQUATION_INFO
  {
    int id;
    const char *name;
    int numVar;
    const VAR_INFO** vars; /* The variables involved in the equation */
  }EQUATION_INFO;

  typedef struct FUNCTION_INFO
  {
    int id;
    const char* name;
    const FILE_INFO info;
  }FUNCTION_INFO;

  typedef enum {ERROR_AT_TIME,NO_PROGRESS_START_POINT,NO_PROGRESS_FACTOR,IMPROPER_INPUT} equationSystemError;

  /* Sample times */
  typedef struct SAMPLE_RAW_TIME {
    double start;
    double interval;
    int zc_index;
  } SAMPLE_RAW_TIME;

  typedef struct SAMPLE_TIME {
    double events;
    int zc_index;
    int activated;
  } SAMPLE_TIME;


  /* SPARSE_PATTERN
   *
   * sparse pattern struct used by jacobians
   * leadindex points to an index where to corresponding
   * index of an row or column is noted in index.
   * sizeofIndex contain number of elements in index
   * colorsCols contain color of colored columns
   *
   */
  typedef struct SPARSE_PATTERN
  {
      unsigned int* leadindex;
      unsigned int* index;
      unsigned int sizeofIndex;
      unsigned int* colorCols;
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
   */
  typedef struct ANALYTIC_JACOBIAN
  {
      char jacobianName;
      unsigned int sizeCols;
      unsigned int sizeRows;
      SPARSE_PATTERN sparsePattern;
      modelica_real* seedVars;
      modelica_real* tmpVars;
      modelica_real* resultVars;
      modelica_real* jacobian;

  }ANALYTIC_JACOBIAN;

  /* Alias data with various types*/
  typedef struct DATA_REAL_ALIAS
  {
    int negate;  
    int nameID;  /* Pointer to Alias */
    char aliasType; /* 0 variable, 1 parameter, 2 time */
    VAR_INFO info;
    modelica_boolean filterOutput; /* True if this variable should be filtered */
  }DATA_REAL_ALIAS;

  typedef struct DATA_INTEGER_ALIAS
  {
    int negate;
    int nameID;
    char aliasType; /* 0 variable, 1 parameter */
    VAR_INFO info;
    modelica_boolean filterOutput; /* True if this variable should be filtered */
  }DATA_INTEGER_ALIAS;

  typedef struct DATA_BOOLEAN_ALIAS
  {
    int negate;
    int nameID;
    char aliasType; /* 0 variable, 1 parameter */
    VAR_INFO info;
    modelica_boolean filterOutput; /* True if this variable should be filtered */
  }DATA_BOOLEAN_ALIAS;

  typedef struct DATA_STRING_ALIAS
  {
    int negate;
    int nameID;
    char aliasType; /* 0 variable, 1 parameter */
    VAR_INFO info;
    modelica_boolean filterOutput; /* True if this variable should be filtered */
  }DATA_STRING_ALIAS;


  /* collect all attributes from one variable in one struct */
  typedef struct REAL_ATTRIBUTE
  {
    modelica_string quantity;     /* = "" */
    modelica_string unit;         /* = "" */
    modelica_string displayUnit;  /* = "" */
    modelica_real min;            /* = -Inf */
    modelica_real max;            /* = +Inf */
    modelica_boolean fixed;       /* depends on the type */
    modelica_boolean useNominal;  /* = false */
    modelica_real nominal;        /* = 1.0 */
    modelica_boolean useStart;    /* = false */
    modelica_real start;          /* = 0.0 */
    modelica_real initial;
  }REAL_ATTRIBUTE;

  typedef struct INTEGER_ATTRIBUTE
  {
    modelica_string quantity;     /* = "" */
    modelica_integer min;         /* = -Inf */
    modelica_integer max;         /* = +Inf */
    modelica_boolean fixed;       /* depends on the type */
    modelica_boolean useStart;    /* = false */
    modelica_integer start;       /* = 0 */
    modelica_integer initial;
  }INTEGER_ATTRIBUTE;

  typedef struct BOOLEAN_ATTRIBUTE
  {
    modelica_string quantity;     /* = "" */
    modelica_boolean fixed;       /* depends on the type */
    modelica_boolean useStart;    /* = false */
    modelica_boolean start;       /* = false */
    modelica_boolean initial;
  }BOOLEAN_ATTRIBUTE;

  typedef struct STRING_ATTRIBUTE
  {
    modelica_string quantity;     /* = "" */
    modelica_boolean useStart;    /* = false */
    modelica_string start;        /* = "" */
    modelica_string initial;
  }STRING_ATTRIBUTE;

  typedef struct STATIC_REAL_DATA
  {
    VAR_INFO info;
    REAL_ATTRIBUTE attribute;
    modelica_boolean filterOutput; /* True if this variable should be filtered */
  }STATIC_REAL_DATA;

  typedef struct STATIC_INTEGER_DATA
  {
    VAR_INFO info;
    INTEGER_ATTRIBUTE attribute;
    modelica_boolean filterOutput; /* True if this variable should be filtered */
  }STATIC_INTEGER_DATA;

  typedef struct STATIC_BOOLEAN_DATA
  {
    VAR_INFO info;
    BOOLEAN_ATTRIBUTE attribute;
    modelica_boolean filterOutput; /* True if this variable should be filtered */
  }STATIC_BOOLEAN_DATA;

  typedef struct STATIC_STRING_DATA
  {
    VAR_INFO info;
    STRING_ATTRIBUTE attribute;
    modelica_boolean filterOutput; /* True if this variable should be filtered */
  }STATIC_STRING_DATA;

  typedef struct MODEL_DATA
  {
    STATIC_REAL_DATA* realVarsData;
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

    FUNCTION_INFO* functionNames;
    EQUATION_INFO* equationInfo;
    int* equationInfo_reverse_prof_index;

    modelica_string_t modelName;
    modelica_string_t modelFilePrefix;
    modelica_string_t modelDir;
    modelica_string_t modelGUID;

    long nStates;
    long nVariablesReal; /* all Real Variables of the model (states,statesderivatives,algebraics) */
    long nVariablesInteger;
    long nVariablesBoolean;
    long nVariablesString;
    long nParametersReal;
    long nParametersInteger;
    long nParametersBoolean;
    long nParametersString;
    long nInputVars;
    long nOutputVars;
    long nHelpVars;   /* results of relations in when equation */

    long nZeroCrossings;
    long nSamples;
    long nDelayExpressions;
    long nInitEquations;      /* number of initial equations */
    long nInitAlgorithms;     /* number of initial algorithms */
    long nInitResiduals;      /* number of initial residuals */
    long nExtObjs;
    long nFunctions;
    long nEquations;
    long nProfileBlocks;

    long nAliasReal;
    long nAliasInteger;
    long nAliasBoolean;
    long nAliasString;

    long nJacobians;
  }MODEL_DATA;

  typedef struct SIMULTAION_INFO
  {
    modelica_real startTime;
    modelica_real stopTime;
    modelica_integer numSteps;
    modelica_real stepSize;
    modelica_real tolerance;
    modelica_string solverMethod;
    modelica_string outputFormat;
    modelica_string variableFilter;

    modelica_boolean initial; /* =1 during initialization, 0 otherwise. */
    modelica_boolean terminal; /* =1 at the end of the simulation, 0 otherwise. */

    void** extObjs; /* External objects */

    /* An array containing the initial data of samples used in the sim */
    SAMPLE_RAW_TIME* rawSampleExps;
    /* The queue of sample time events to be processed. */
    SAMPLE_TIME* sampleTimes;
    modelica_integer curSampleTimeIx;
    modelica_integer nSampleTimes;

    modelica_real* zeroCrossings;
    modelica_real* zeroCrossingsPre;
    modelica_boolean* backupRelations;
    modelica_boolean* zeroCrossingEnabled;

    /* helpVars are the result when relations and samples */
    modelica_boolean* helpVars;
    modelica_boolean* helpVarsPre;

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

    ANALYTIC_JACOBIAN* analyticJacobians;

    /* delay vars */
    double tStart;
    RINGBUFFER **delayStructure;

  }SIMULATION_INFO;

  /* collects all dynamic model data like the variabel-values */
  typedef struct SIMULATION_DATA
  {
    modelica_real timeValue;

    modelica_real* realVars;
    modelica_integer* integerVars;
    modelica_boolean* booleanVars;
    modelica_string* stringVars;

  }SIMULATION_DATA;

  /* top-level struct to collect dynamic and static model data */
  typedef struct DATA
  {
    RINGBUFFER* simulationData;     /* RINGBUFFER of SIMULATION_DATA */
    SIMULATION_DATA **localData;
    MODEL_DATA modelData;           /* static stuff */
    SIMULATION_INFO simulationInfo;
  }DATA;

#endif
