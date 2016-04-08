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

/*! \file initialization.c
 */

#include "initialization.h"

#include "simulation_data.h"
#include "util/omc_error.h"
#include "openmodelica.h"
#include "openmodelica_func.h"
#include "simulation/solver/model_help.h"
#if !defined(OMC_MINIMAL_RUNTIME)
#include "util/read_matlab4.h"
#endif
#include "simulation/solver/events.h"
#include "simulation/solver/stateset.h"
#include "meta/meta_modelica.h"

#include "simulation/solver/mixedSystem.h"
#include "simulation/solver/linearSystem.h"
#include "simulation/solver/nonlinearSystem.h"
#include "simulation/solver/delay.h"
#include "simulation/solver/synchronous.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

/*! \fn void dumpInitializationStatus(DATA *data)
 *
 *  \param [in]  [data]
 *
 *  \author lochel
 */
void dumpInitialSolution(DATA *simData)
{
  long i, j;

  const MODEL_DATA      *mData = simData->modelData;
  const SIMULATION_INFO *sInfo = simData->simulationInfo;

  if (ACTIVE_STREAM(LOG_INIT))
    printParameters(simData, LOG_INIT);

  if (!ACTIVE_STREAM(LOG_SOTI)) return;
  infoStreamPrint(LOG_SOTI, 1, "### SOLUTION OF THE INITIALIZATION ###");

  if (0 < mData->nStates)
  {
    infoStreamPrint(LOG_SOTI, 1, "states variables");
    for(i=0; i<mData->nStates; ++i)
      infoStreamPrint(LOG_SOTI, 0, "[%ld] Real %s(start=%g, nominal=%g) = %g (pre: %g)", i+1,
                                   mData->realVarsData[i].info.name,
                                   mData->realVarsData[i].attribute.start,
                                   mData->realVarsData[i].attribute.nominal,
                                   simData->localData[0]->realVars[i],
                                   sInfo->realVarsPre[i]);
    messageClose(LOG_SOTI);
  }

  if (0 < mData->nStates)
  {
    infoStreamPrint(LOG_SOTI, 1, "derivatives variables");
    for(i=mData->nStates; i<2*mData->nStates; ++i)
      infoStreamPrint(LOG_SOTI, 0, "[%ld] Real %s = %g (pre: %g)", i+1,
                                   mData->realVarsData[i].info.name,
                                   simData->localData[0]->realVars[i],
                                   sInfo->realVarsPre[i]);
    messageClose(LOG_SOTI);
  }

  if (2*mData->nStates < mData->nVariablesReal)
  {
    infoStreamPrint(LOG_SOTI, 1, "other real variables");
    for(i=2*mData->nStates; i<mData->nVariablesReal; ++i)
      infoStreamPrint(LOG_SOTI, 0, "[%ld] Real %s(start=%g, nominal=%g) = %g (pre: %g)", i+1,
                                   mData->realVarsData[i].info.name,
                                   mData->realVarsData[i].attribute.start,
                                   mData->realVarsData[i].attribute.nominal,
                                   simData->localData[0]->realVars[i],
                                   sInfo->realVarsPre[i]);
    messageClose(LOG_SOTI);
  }

  if (0 < mData->nVariablesInteger)
  {
    infoStreamPrint(LOG_SOTI, 1, "integer variables");
    for(i=0; i<mData->nVariablesInteger; ++i)
      infoStreamPrint(LOG_SOTI, 0, "[%ld] Integer %s(start=%ld) = %ld (pre: %ld)", i+1,
                                   mData->integerVarsData[i].info.name,
                                   mData->integerVarsData[i].attribute.start,
                                   simData->localData[0]->integerVars[i],
                                   sInfo->integerVarsPre[i]);
    messageClose(LOG_SOTI);
  }

  if (0 < mData->nVariablesBoolean)
  {
    infoStreamPrint(LOG_SOTI, 1, "boolean variables");
    for(i=0; i<mData->nVariablesBoolean; ++i)
      infoStreamPrint(LOG_SOTI, 0, "[%ld] Boolean %s(start=%s) = %s (pre: %s)", i+1,
                                   mData->booleanVarsData[i].info.name,
                                   mData->booleanVarsData[i].attribute.start ? "true" : "false",
                                   simData->localData[0]->booleanVars[i] ? "true" : "false",
                                   sInfo->booleanVarsPre[i] ? "true" : "false");
    messageClose(LOG_SOTI);
  }

  if (0 < mData->nVariablesString)
  {
    infoStreamPrint(LOG_SOTI, 1, "string variables");
    for(i=0; i<mData->nVariablesString; ++i)
      infoStreamPrint(LOG_SOTI, 0, "[%ld] String %s(start=\"%s\") = \"%s\" (pre: \"%s\")", i+1,
                                   mData->stringVarsData[i].info.name,
                                   MMC_STRINGDATA(mData->stringVarsData[i].attribute.start),
                                   MMC_STRINGDATA(simData->localData[0]->stringVars[i]),
                                   MMC_STRINGDATA(sInfo->stringVarsPre[i]));
    messageClose(LOG_SOTI);
  }

  messageClose(LOG_SOTI);
}

/*! \fn static int symbolic_initialization(DATA *data)
 *
 *  \param [ref] [data]
 *
 *  \author lochel
 */
static int symbolic_initialization(DATA *data, threadData_t *threadData, long numLambdaSteps)
{
  TRACE_PUSH
  long step;
  int retVal;

  /* initial sample and delay before initial the system */
  initDelay(data, data->simulationInfo->startTime);

  /* initialize all relations that are ZeroCrossings */
  storePreValues(data);
  overwriteOldSimulationData(data);

  if (data->callback->useHomotopy && numLambdaSteps > 1)
  {
    long i;
    char buffer[4096];
    FILE *pFile = NULL;

    modelica_real* realVars = (modelica_real*)calloc(data->modelData->nVariablesReal, sizeof(modelica_real));
    modelica_integer* integerVars = (modelica_integer*)calloc(data->modelData->nVariablesInteger, sizeof(modelica_integer));
    modelica_boolean* booleanVars = (modelica_boolean*)calloc(data->modelData->nVariablesBoolean, sizeof(modelica_boolean));
    modelica_string* stringVars = (modelica_string*) omc_alloc_interface.malloc_uncollectable(data->modelData->nVariablesString * sizeof(modelica_string));
    MODEL_DATA *mData = data->modelData;

    assertStreamPrint(threadData, 0 != realVars, "out of memory");
    assertStreamPrint(threadData, 0 != integerVars, "out of memory");
    assertStreamPrint(threadData, 0 != booleanVars, "out of memory");
    assertStreamPrint(threadData, 0 != stringVars, "out of memory");

    for(i=0; i<mData->nVariablesReal; ++i) {
      realVars[i] = mData->realVarsData[i].attribute.start;
    }
    for(i=0; i<mData->nVariablesInteger; ++i) {
      integerVars[i] = mData->integerVarsData[i].attribute.start;
    }
    for(i=0; i<mData->nVariablesBoolean; ++i) {
      booleanVars[i] = mData->booleanVarsData[i].attribute.start;
    }
    for(i=0; i<mData->nVariablesString; ++i) {
      stringVars[i] = mData->stringVarsData[i].attribute.start;
    }

    if(ACTIVE_STREAM(LOG_INIT))
    {
      sprintf(buffer, "%s_homotopy.csv", mData->modelFilePrefix);
      pFile = fopen(buffer, "wt");
      fprintf(pFile, "%s,", "lambda");
      for(i=0; i<mData->nVariablesReal; ++i)
        fprintf(pFile, "%s,", mData->realVarsData[i].info.name);
      fprintf(pFile, "\n");
    }

    infoStreamPrint(LOG_INIT, 1, "homotopy process");
    for(step=0; step<numLambdaSteps; ++step)
    {
      data->simulationInfo->lambda = ((double)step)/(numLambdaSteps-1);

      if(data->simulationInfo->lambda > 1.0) {
        data->simulationInfo->lambda = 1.0;
      }

      if(0 == step)
        data->callback->functionInitialEquations_lambda0(data, threadData);
      else
        data->callback->functionInitialEquations(data, threadData);

      infoStreamPrint(LOG_INIT, 0, "lambda = %g done", data->simulationInfo->lambda);

      if(ACTIVE_STREAM(LOG_INIT))
      {
        fprintf(pFile, "%.16g,", data->simulationInfo->lambda);
        for(i=0; i<mData->nVariablesReal; ++i)
          fprintf(pFile, "%.16g,", data->localData[0]->realVars[i]);
        fprintf(pFile, "\n");
      }

      if(check_nonlinear_solutions(data, 0) ||
         check_linear_solutions(data, 0) ||
         check_mixed_solutions(data, 0))
        break;

      setAllStartToVars(data);
    }
    messageClose(LOG_INIT);

    if(ACTIVE_STREAM(LOG_INIT))
      fclose(pFile);

    for(i=0; i<mData->nVariablesReal; ++i)
      mData->realVarsData[i].attribute.start = realVars[i];
    for(i=0; i<mData->nVariablesInteger; ++i)
      mData->integerVarsData[i].attribute.start = integerVars[i];
    for(i=0; i<mData->nVariablesBoolean; ++i)
      mData->booleanVarsData[i].attribute.start = booleanVars[i];
    for(i=0; i<mData->nVariablesString; ++i)
      mData->stringVarsData[i].attribute.start = stringVars[i];

    free(realVars);
    free(integerVars);
    free(booleanVars);
    omc_alloc_interface.free_uncollectable(stringVars);
  }
  else
  {
    data->simulationInfo->lambda = 1.0;
    data->callback->functionInitialEquations(data, threadData);
  }
  storeRelations(data);

  /* check for over-determined systems */
  retVal = data->callback->functionRemovedInitialEquations(data, threadData);

  TRACE_POP
  return retVal;
}

/*! \fn static char *mapToDymolaVars(const char *varname)
 *
 *  \param [in]  [varname]
 *
 *  converts a given variable name into dymola style
 *  ** der(foo.foo2) -> foo.der(foo2)
 *  ** foo.foo2[1,2,3] -> foo.foo2[1, 2, 3]
 *
 *  \author lochel
 */
static char *mapToDymolaVars(const char *varname)
{
  unsigned int varnameSize = strlen(varname);
  unsigned int level = 0;
  unsigned int i=0, j=0, pos=0;
  char* newVarname = NULL;
  unsigned int newVarnameSize = 0;

  newVarnameSize = varnameSize;
  for(i=0; i<varnameSize; i++)
  {
    if(varname[i] == '[')
      level++;
    else if(varname[i] == ']')
      level--;

    if(level > 0 && varname[i] == ',' && varname[i+1] != ' ')
      newVarnameSize++;
  }

  newVarname = (char*)malloc((newVarnameSize+1) * sizeof(char));
  for(i=0,j=0; i<newVarnameSize; i++,j++)
  {
    if(varname[j] == '[')
      level++;
    else if(varname[j] == ']')
      level--;

    newVarname[i] = varname[j];
    if(level > 0 && varname[j] == ',' && varname[j+1] != ' ')
    {
      i++;
      newVarname[i] = ' ';
    }
  }
  newVarname[newVarnameSize] = '\0';

  while(!memcmp((const void*)newVarname, (const void*)"der(", 4*sizeof(char)))
  {
    for(pos=newVarnameSize; pos>=4; pos--)
      if(newVarname[pos] == '.')
        break;

    if(pos == 3)
      break;

    memcpy((void*)newVarname, (const void*)(newVarname+4), (pos-3)*sizeof(char));
    memcpy((void*)(newVarname+pos-3), (const void*)"der(", 4*sizeof(char));
  }

  return newVarname;
}

#if !defined(OMC_MINIMAL_RUNTIME)
/*! \fn int importStartValues(DATA *data, const char *pInitFile, const double initTime)
 *
 *  \param [ref] [data]
 *  \param [in]  [pInitFile]
 *  \param [in]  [initTime]
 *
 *  \author lochel
 */
int importStartValues(DATA *data, threadData_t *threadData, const char *pInitFile, const double initTime)
{
  ModelicaMatReader reader;
  ModelicaMatVariable_t *pVar = NULL;
  double value;
  const char *pError = NULL;
  char* newVarname = NULL;

  MODEL_DATA *mData = data->modelData;
  long i;

  infoStreamPrint(LOG_INIT, 0, "import start values\nfile: %s\ntime: %g", pInitFile, initTime);

  if(!strcmp(data->modelData->resultFileName, pInitFile))
  {
    errorStreamPrint(LOG_INIT, 0, "Cannot import a result file for initialization that is also the current output file <%s>.\nConsider redirecting the output result file (-r=<new_res.mat>) or renaming the result file that is used for initialization import.", pInitFile);
    return 1;
  }

  pError = omc_new_matlab4_reader(pInitFile, &reader);
  if(pError)
  {
    throwStreamPrint(threadData, "unable to read input-file <%s> [%s]", pInitFile, pError);
    return 1;
  }
  else
  {
    infoStreamPrint(LOG_INIT, 0, "import real variables");
    for(i=0; i<mData->nVariablesReal; ++i) {
      pVar = omc_matlab4_find_var(&reader, mData->realVarsData[i].info.name);

      if(!pVar) {
        newVarname = mapToDymolaVars(mData->realVarsData[i].info.name);
        pVar = omc_matlab4_find_var(&reader, newVarname);
        free(newVarname);
      }

      if(pVar) {
        omc_matlab4_val(&(mData->realVarsData[i].attribute.start), &reader, pVar, initTime);
        infoStreamPrint(LOG_INIT, 0, "| %s(start=%g)", mData->realVarsData[i].info.name, mData->realVarsData[i].attribute.start);
      } else if((strlen(mData->realVarsData[i].info.name) > 0) &&
              (mData->realVarsData[i].info.name[0] != '$') &&
              (strncmp(mData->realVarsData[i].info.name, "der($", 5) != 0)) {
        /* skip warnings about self-generated variables */
        warningStreamPrint(LOG_INIT, 0, "unable to import real variable %s from given file", mData->realVarsData[i].info.name);
      }
    }

    infoStreamPrint(LOG_INIT, 0, "import real parameters");
    for(i=0; i<mData->nParametersReal; ++i) {
      pVar = omc_matlab4_find_var(&reader, mData->realParameterData[i].info.name);

      if(!pVar) {
        newVarname = mapToDymolaVars(mData->realParameterData[i].info.name);
        pVar = omc_matlab4_find_var(&reader, newVarname);
        free(newVarname);
      }

      if(pVar) {
        omc_matlab4_val(&(mData->realParameterData[i].attribute.start), &reader, pVar, initTime);
        data->simulationInfo->realParameter[i] = mData->realParameterData[i].attribute.start;
        infoStreamPrint(LOG_INIT, 0, "| %s(start=%g)", mData->realParameterData[i].info.name, mData->realParameterData[i].attribute.start);
      } else {
        warningStreamPrint(LOG_INIT, 0, "unable to import real parameter %s from given file", mData->realParameterData[i].info.name);
      }
    }

    infoStreamPrint(LOG_INIT, 0, "import real discrete");
    for(i=mData->nVariablesReal-mData->nDiscreteReal; i<mData->nDiscreteReal; ++i) {
      pVar = omc_matlab4_find_var(&reader, mData->realParameterData[i].info.name);

      if(!pVar) {
        newVarname = mapToDymolaVars(mData->realParameterData[i].info.name);
        pVar = omc_matlab4_find_var(&reader, newVarname);
        free(newVarname);
      }

      if(pVar) {
        omc_matlab4_val(&(mData->realParameterData[i].attribute.start), &reader, pVar, initTime);
        infoStreamPrint(LOG_INIT, 0, "| %s(start=%g)", mData->realParameterData[i].info.name, mData->realParameterData[i].attribute.start);
      } else {
        warningStreamPrint(LOG_INIT, 0, "unable to import real parameter %s from given file", mData->realParameterData[i].info.name);
      }
    }

    infoStreamPrint(LOG_INIT, 0, "import integer parameters");
    for(i=0; i<mData->nParametersInteger; ++i)
    {
      pVar = omc_matlab4_find_var(&reader, mData->integerParameterData[i].info.name);

      if (!pVar) {
        newVarname = mapToDymolaVars(mData->integerParameterData[i].info.name);
        pVar = omc_matlab4_find_var(&reader, newVarname);
        free(newVarname);
      }

      if (pVar) {
        omc_matlab4_val(&value, &reader, pVar, initTime);
        mData->integerParameterData[i].attribute.start = (modelica_integer)value;
        data->simulationInfo->integerParameter[i] = (modelica_integer)value;
        infoStreamPrint(LOG_INIT, 0, "| %s(start=%ld)", mData->integerParameterData[i].info.name, mData->integerParameterData[i].attribute.start);
      } else {
        warningStreamPrint(LOG_INIT, 0, "unable to import integer parameter %s from given file", mData->integerParameterData[i].info.name);
      }
    }

    infoStreamPrint(LOG_INIT, 0, "import boolean parameters");
    for(i=0; i<mData->nParametersBoolean; ++i) {
      pVar = omc_matlab4_find_var(&reader, mData->booleanParameterData[i].info.name);

      if(!pVar) {
        newVarname = mapToDymolaVars(mData->booleanParameterData[i].info.name);
        pVar = omc_matlab4_find_var(&reader, newVarname);
        free(newVarname);
      }

      if(pVar) {
        omc_matlab4_val(&value, &reader, pVar, initTime);
        mData->booleanParameterData[i].attribute.start = (modelica_boolean)value;
        data->simulationInfo->booleanParameter[i] = (modelica_boolean)value;
        infoStreamPrint(LOG_INIT, 0, "| %s(start=%s)", mData->booleanParameterData[i].info.name, mData->booleanParameterData[i].attribute.start ? "true" : "false");
      } else {
        warningStreamPrint(LOG_INIT, 0, "unable to import boolean parameter %s from given file", mData->booleanParameterData[i].info.name);
      }
    }
    omc_free_matlab4_reader(&reader);
  }

  return 0;
}
#endif

/*! \fn initSample
 *
 *  \param [ref] [data]
 *  \param [in]  [startTime]
 *  \param [in]  [stopTime]
 *
 *  This function initializes sample-events.
 */
void initSample(DATA* data, threadData_t *threadData, double startTime, double stopTime)
{
  TRACE_PUSH
  long i;

  data->callback->function_initSample(data, threadData);              /* set-up sample */
  data->simulationInfo->nextSampleEvent = NAN;  /* should never be reached */
  for(i=0; i<data->modelData->nSamples; ++i) {
    if(startTime < data->modelData->samplesInfo[i].start) {
      data->simulationInfo->nextSampleTimes[i] = data->modelData->samplesInfo[i].start;
    } else {
      data->simulationInfo->nextSampleTimes[i] = data->modelData->samplesInfo[i].start + ceil((startTime-data->modelData->samplesInfo[i].start) / data->modelData->samplesInfo[i].interval) * data->modelData->samplesInfo[i].interval;
    }

    if((i == 0) || (data->simulationInfo->nextSampleTimes[i] < data->simulationInfo->nextSampleEvent)) {
      data->simulationInfo->nextSampleEvent = data->simulationInfo->nextSampleTimes[i];
    }
  }

  if(stopTime < data->simulationInfo->nextSampleEvent) {
    debugStreamPrint(LOG_EVENTS, 0, "there are no sample-events");
  } else {
    debugStreamPrint(LOG_EVENTS, 0, "first sample-event at t = %g", data->simulationInfo->nextSampleEvent);
  }

  TRACE_POP
}

/*! \fn int initialization(DATA *data, const char* pInitMethod, const char* pOptiMethod, const char* pInitFile, double initTime)
 *
 *  \param [ref] [data]
 *  \param [in]  [pInitMethod] user defined initialization method
 *  \param [in]  [pInitFile] extra argument for initialization-method "file"
 *  \param [in]  [initTime] extra argument for initialization-method "file"
 *
 *  \author lochel
 */
int initialization(DATA *data, threadData_t *threadData, const char* pInitMethod, const char* pInitFile, double initTime, int lambda_steps)
{
  TRACE_PUSH
  int initMethod = IIM_SYMBOLIC; /* default method */
  int retVal = -1;
  int i;

  infoStreamPrint(LOG_INIT, 0, "### START INITIALIZATION ###");

  setAllParamsToStart(data);

#if !defined(OMC_MINIMAL_RUNTIME)
  /* import start values from extern mat-file */
  if(pInitFile && strcmp(pInitFile, ""))
  {
    data->callback->updateBoundParameters(data, threadData);
    data->callback->updateBoundVariableAttributes(data, threadData);

    if(importStartValues(data, threadData, pInitFile, initTime)) {
      TRACE_POP
      return 1;
    }
  }
#endif
  /* set up all variables with their start-values */
  setAllVarsToStart(data);

  if(!(pInitFile && strcmp(pInitFile, ""))) {
    data->callback->updateBoundParameters(data, threadData);
    data->callback->updateBoundVariableAttributes(data, threadData);
    setAllVarsToStart(data);
  }

  /* update static data of linear/non-linear system solvers */
  updateStaticDataOfLinearSystems(data, threadData);
  updateStaticDataOfNonlinearSystems(data, threadData);

  /* if there are user-specified options, use them! */
  if (pInitMethod && strcmp(pInitMethod, "")) {
    initMethod = IIM_UNKNOWN;

    for (i=1; i<IIM_MAX; ++i) {
      if(!strcmp(pInitMethod, INIT_METHOD_NAME[i])) {
        initMethod = i;
      }
    }

    if(initMethod == IIM_UNKNOWN) {
      warningStreamPrint(LOG_STDOUT, 0, "unrecognized option -iim %s", pInitMethod);
      warningStreamPrint(LOG_STDOUT, 0, "current options are:");
      for (i=1; i<IIM_MAX; ++i) {
        warningStreamPrint(LOG_STDOUT, 0, "| %-15s [%s]", INIT_METHOD_NAME[i], INIT_METHOD_DESC[i]);
      }
      throwStreamPrint(threadData, "see last warning");
    }
  }

  infoStreamPrint(LOG_INIT, 0, "initialization method: %-15s [%s]", INIT_METHOD_NAME[initMethod], INIT_METHOD_DESC[initMethod]);

  /* start with the real initialization */
  data->simulationInfo->initial = 1;             /* to evaluate when-equations with initial()-conditions */

  /* initialize all (nonlinear|linear|mixed) systems
   * This is a workaround and should be removed as soon as possible.
   */
  for(i=0; i<data->modelData->nNonLinearSystems; ++i) {
    data->simulationInfo->nonlinearSystemData[i].solved = 1;
  }
  for(i=0; i<data->modelData->nLinearSystems; ++i) {
    data->simulationInfo->linearSystemData[i].solved = 1;
  }
  for(i=0; i<data->modelData->nMixedSystems; ++i) {
    data->simulationInfo->mixedSystemData[i].solved = 1;
  }
  /* end workaround */

  /* select the right initialization-method */
  if(IIM_NONE == initMethod) {
    retVal = 0;
  } else if(IIM_SYMBOLIC == initMethod) {
    retVal = symbolic_initialization(data, threadData, lambda_steps);
  } else {
    throwStreamPrint(threadData, "unsupported option -iim");
  }

  /* do pivoting for dynamic state selection if selection changed try again */
  if(stateSelection(data, threadData, 0, 1) == 1) {
    if(stateSelection(data, threadData, 1, 1) == 1) {
      /* report a warning about strange start values */
      warningStreamPrint(LOG_STDOUT, 0, "Cannot initialize the dynamic state selection in an unique way. Use -lv LOG_DSS to see the switching state set.");
    }
  }

  /* check for unsolved (nonlinear|linear|mixed) systems
   * This is a workaround and should be removed as soon as possible.
   */
  if(check_nonlinear_solutions(data, 1)) {
    retVal = -2;
  } else if(check_linear_solutions(data, 1)) {
    retVal = -3;
  } else if(check_mixed_solutions(data, 1)) {
    retVal = -4;
  }
  /* end workaround */

  dumpInitialSolution(data);
  infoStreamPrint(LOG_INIT, 0, "### END INITIALIZATION ###");

  overwriteOldSimulationData(data);     /* overwrite the whole ring-buffer with initialized values */
  storePreValues(data);                 /* save pre-values */
  updateDiscreteSystem(data, threadData);           /* evaluate discrete variables (event iteration) */
  saveZeroCrossings(data, threadData);

  data->simulationInfo->initial = 0;
  /* initialization is done */

  initSample(data, threadData, data->simulationInfo->startTime, data->simulationInfo->stopTime);
  data->callback->function_storeDelayed(data, threadData);
  data->callback->function_updateRelations(data, threadData, 1);
  initSynchronous(data, threadData, data->simulationInfo->startTime);

  printRelations(data, LOG_EVENTS);
  printZeroCrossings(data, LOG_EVENTS);

  /* valid system for the first time! */
  TRACE_POP
  return retVal;
}
