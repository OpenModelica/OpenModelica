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

/*! \file simulation_data.h
 * Description: This is the C header file to provide all information 
 * for simulation
 */

#ifndef SIMULATION_DATA_H
#define SIMULATION_DATA_H

#include "openmodelica.h"
#include "ringbuffer.h"

#ifdef __cplusplus
extern "C" {
#endif

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

  typedef struct _X_DATA_REAL_ALIAS
  {
    int negate;  
    int nameID;  /* Pointer to Alias */
    char aliasType; /* 0 variable, 1 parameter, 2 time */
    VAR_INFO info;
    modelica_boolean filterOutput; /* True if this variable should be filtered */
  }_X_DATA_REAL_ALIAS;

  typedef struct _X_DATA_INTEGER_ALIAS
  {
    int negate;
    int nameID;
    char aliasType; /* 0 variable, 1 parameter */
    VAR_INFO info;
    modelica_boolean filterOutput; /* True if this variable should be filtered */
  }_X_DATA_INTEGER_ALIAS;

  typedef struct _X_DATA_BOOLEAN_ALIAS
  {
    int negate;
    int nameID;
    char aliasType; /* 0 variable, 1 parameter */
    VAR_INFO info;
    modelica_boolean filterOutput; /* True if this variable should be filtered */
  }_X_DATA_BOOLEAN_ALIAS;

  typedef struct _X_DATA_STRING_ALIAS
  {
    int negate;
    int nameID;
    char aliasType; /* 0 variable, 1 parameter */
    VAR_INFO info;
    modelica_boolean filterOutput; /* True if this variable should be filtered */
  }_X_DATA_STRING_ALIAS;

  /* collect all attributes from one variable in one struct */
  typedef struct REAL_ATTRIBUTE
  {
    modelica_string quantity;     /* = "" */
    modelica_string unit;         /* = "" */
    modelica_string displayUnit;  /* = "" */
    modelica_real min;            /* = -Inf */
    modelica_real max;            /* = +Inf */
    modelica_boolean fixed;       /* depends on the type */
    modelica_boolean useNominal;
    modelica_real nominal;
    modelica_real start;          /* = 0 */
    modelica_real initial;
  }REAL_ATTRIBUTE;

  typedef struct INTEGER_ATTRIBUTE
  {
    modelica_string quantity;     /* = "" */
    modelica_integer min;         /* = -Inf */
    modelica_integer max;         /* = +Inf */
    modelica_boolean fixed;       /* depends on the type */
    modelica_integer start;       /* = 0 */
    modelica_integer initial;
  }INTEGER_ATTRIBUTE;

  typedef struct BOOLEAN_ATTRIBUTE
  {
    modelica_string quantity;     /* = "" */
    modelica_boolean fixed;       /* depends on the type */
    modelica_boolean start;       /* = 0 */
    modelica_boolean initial;
  }BOOLEAN_ATTRIBUTE;

  typedef struct STRING_ATTRIBUTE
  {
    modelica_string quantity;     /* = "" */
    modelica_string start;       /* = 0 */
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
    STATIC_REAL_DATA* realData;
    STATIC_INTEGER_DATA* integerData;
    STATIC_BOOLEAN_DATA* booleanData;
    STATIC_STRING_DATA* stringData;

    STATIC_REAL_DATA* realParameter;
    STATIC_INTEGER_DATA* integerParameter;
    STATIC_BOOLEAN_DATA* booleanParameter;
    STATIC_STRING_DATA* stringParameter;

    _X_DATA_REAL_ALIAS* realAlias;
    _X_DATA_INTEGER_ALIAS* integerAlias;
    _X_DATA_BOOLEAN_ALIAS* booleanAlias;
    _X_DATA_STRING_ALIAS* stringAlias;

    FUNCTION_INFO* functionNames;
    EQUATION_INFO* equationInfo;
    int equationInfo_reverse_prof_index;

    modelica_string_t modelName;
    modelica_string_t modelFilePrefix;
    modelica_string_t modelDir;
    modelica_string_t modelGUID;

    void** extObjs; /* External objects */

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
    long nResiduals;
    long nExtOpjs;
    long nFunctions;
    long nEquations;
    long nProfileBlocks;

    long nAliasReal;
    long nAliasInteger;
    long nAliasBoolean;
    long nAliasString;
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

    modelica_boolean init; /* =1 during initialization, 0 otherwise. */
    modelica_boolean terminal; /* =1 at the end of the simulation, 0 otherwise. */

    /* An array containing the initial data of samples used in the sim */
    sample_raw_time* rawSampleExps;
    /* The queue of sample time events to be processed. */
    sample_time* sampleTimes;
    modelica_integer curSampleTimeIx;
    modelica_integer nSampleTimes;

    modelica_real* zeroCrossings;
    modelica_real* zeroCrossingsPre;
    modelica_boolean* backupRelations;
    modelica_boolean* zeroCrossingEnabled;

  }SIMULATION_INFO;

  /* collects all dynamic model data like the variabel-values */
  typedef struct SIMULATION_DATA
  {
    modelica_real timeValue;

    modelica_real* realVars;
    modelica_integer* integerVars;
    modelica_boolean* booleanVars;
    modelica_string* stringVars;
    modelica_boolean* helpVars;

    modelica_real* realVarsPre;
    modelica_integer* integerVarsPre;
    modelica_boolean* booleanVarsPre;
    modelica_string* stringVarsPre;
    modelica_boolean* helpVarsPre;

  }SIMULATION_DATA;

  /* top-level struct to collect dynamic and static model data */
  typedef struct _X_DATA
  {
    RINGBUFFER* simulationData;     /* RINGBUFFER of SIMULATION_DATA */
    SIMULATION_DATA **localData;
    MODEL_DATA modelData;           /* static stuff */
    SIMULATION_INFO simulationInfo;
  }_X_DATA;

  void initializeXDataStruc(_X_DATA *data);
  void DeinitializeXDataStruc(_X_DATA *data);

#ifdef __cplusplus
}
#endif

#endif
