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

#include "fmi_events.h"

#ifdef __cplusplus
extern "C" {
#endif

int checkForDiscreteChanges(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  MODEL_DATA *modelData = data->modelData;
  long i=0, realStartIndex=modelData->nVariablesReal - modelData->nDiscreteReal, realStopIndex=modelData->nVariablesReal;

  if (ACTIVE_STREAM(LOG_EVENTS_V)) {
    /* We log all changed variables. This takes some extra time because we always iterate over all variables, and duplicates code */
    int needToIterate = 0;
    infoStreamPrint(LOG_EVENTS_V, 1, "check for discrete changes at time=%.12g", data->localData[0]->timeValue);

    if ((!modelData->nDiscreteReal) && (!modelData->nVariablesInteger) &&  (!modelData->nVariablesBoolean) && (!modelData->nVariablesString)) {
      return 0;
    }
    for (i=realStartIndex; i<realStopIndex; i++) {
      modelica_real v1 = data->simulationInfo->realVarsPre[i];
      modelica_real v2 = data->localData[0]->realVars[i];
      if (v1 != v2) {
        infoStreamPrint(LOG_EVENTS_V, 0, "discrete var changed: %s from %g to %g", modelData->realVarsData[i].info.name, v1, v2);
        needToIterate = 1;
      }
    }
    for (i=0; i<modelData->nVariablesInteger; i++) {
      modelica_integer v1 = data->simulationInfo->integerVarsPre[i];
      modelica_integer v2 = data->localData[0]->integerVars[i];
      if (v1 != v2) {
        infoStreamPrint(LOG_EVENTS_V, 0, "discrete var changed: %s from %ld to %ld", modelData->integerVarsData[i].info.name, (long) v1, (long) v2);
        needToIterate = 1;
      }
    }
    for (i=0; i<modelData->nVariablesBoolean; i++) {
      modelica_boolean v1 = data->simulationInfo->booleanVarsPre[i];
      modelica_boolean v2 = data->localData[0]->booleanVars[i];
      if (v1 != v2) {
        infoStreamPrint(LOG_EVENTS_V, 0, "discrete var changed: %s from %d to %d", modelData->booleanVarsData[i].info.name, v1, v2);
        needToIterate = 1;
      }
    }
    for (i=0; i<modelData->nVariablesString; i++) {
      modelica_string v1 = data->simulationInfo->stringVarsPre[i];
      modelica_string v2 = data->localData[0]->stringVars[i];
      if (0 != strcmp(MMC_STRINGDATA(v1),MMC_STRINGDATA(v2))) {
        infoStreamPrint(LOG_EVENTS_V, 0, "discrete var changed: %s from %s to %s", modelData->stringVarsData[i].info.name, MMC_STRINGDATA(v1), MMC_STRINGDATA(v2));
        needToIterate = 1;
      }
    }
    if (ACTIVE_STREAM(LOG_EVENTS_V)) messageClose(LOG_EVENTS_V);
    return needToIterate;
  } else {
    /* Just check if variables changed */
    if (0 != memcmp(data->simulationInfo->realVarsPre + realStartIndex, data->localData[0]->realVars + realStartIndex, modelData->nDiscreteReal*sizeof(modelica_real))) {
      return 1;
    }
    if (0 != memcmp(data->simulationInfo->integerVarsPre, data->localData[0]->integerVars, modelData->nVariablesInteger*sizeof(modelica_integer))) {
      return 1;
    }
    if (0 != memcmp(data->simulationInfo->booleanVarsPre, data->localData[0]->booleanVars, modelData->nVariablesBoolean*sizeof(modelica_boolean))) {
      return 1;
    }
    for (i=0; i<modelData->nVariablesString; i++) {
      modelica_string v1 = data->simulationInfo->stringVarsPre[i];
      modelica_string v2 = data->localData[0]->stringVars[i];
      if (0 != strcmp(MMC_STRINGDATA(v1),MMC_STRINGDATA(v2))) {
        return 1;
      }
    }
    return 0;
  }


  TRACE_POP
}

#ifdef __cplusplus
}
#endif
