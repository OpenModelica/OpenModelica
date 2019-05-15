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

#define _XOPEN_SOURCE 600
#include "omc_opc_ua.h"
#include "open62541.h"
#include <pthread.h>

#define BAD_RESULT() fprintf(stderr, "%s:%d: Bad OPC result\n", __FILE__, __LINE__);

static volatile int count=0;

typedef struct {
  DATA *data;
  UA_Logger logger;
  UA_ServerNetworkLayer nl;
  UA_Server *server;
  UA_Boolean server_running;
  UA_Boolean run;
  UA_Boolean step;
  pthread_mutex_t mutex_pause;
  pthread_cond_t cond_pause;
  double time[2];
  pthread_t thread;
  UA_MethodAttributes runAttr;
  double *inputVarsBackup;
  int gotNewInput;
  pthread_mutex_t write_values;
  pthread_mutex_t mutex_values[2];
  int latestValues;
  UA_Double *realVals[2];
  int *realValsInputIndex;
  UA_Boolean *boolVals[2];
  int *boolValsInputIndex;
  int reinitStateFlag;
  int *stateWasUpdatedFlag;
  double *updatedStates;
  double real_time_sync_scaling;
  void (*omc_real_time_sync_update)(DATA *data, double scaling);
} omc_opc_ua_state;

static UA_StatusCode runMethod(void *handle, const UA_NodeId objectId, size_t inputSize, const UA_Variant *input, size_t outputSize, UA_Variant *output)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) handle;
  UA_LOG_INFO(state->logger, UA_LOGCATEGORY_SERVER, "run method was called");
  return UA_STATUSCODE_GOOD;
}

static void* threadWork(void *data)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) data;
  UA_StatusCode status = UA_Server_run(state->server, &state->server_running);
  return status == UA_STATUSCODE_GOOD ? (void*)0 : (void*)1;
}

static void waitForStep(omc_opc_ua_state *state)
{
  int run;
  state->step = 0;
  pthread_mutex_lock(&state->mutex_pause);
  run = state->run;
  while (!(state->run || state->step)) {
    pthread_cond_wait(&state->cond_pause, &state->mutex_pause);
  }
  pthread_mutex_unlock(&state->mutex_pause);
  if (!run || state->data->real_time_sync.scaling != state->real_time_sync_scaling) {
    /* We were not running or the scaling factor changed. Reset the real-time synchronization! */
    state->omc_real_time_sync_update(state->data, state->real_time_sync_scaling);
    state->data->real_time_sync.scaling = state->real_time_sync_scaling;
  }
}

void omc_wait_for_step(void *state_vp)
{
  waitForStep((omc_opc_ua_state*) state_vp);
}

static UA_StatusCode
readBoolean(void *handle, const UA_NodeId nodeid, UA_Boolean sourceTimeStamp, const UA_NumericRange *range, UA_DataValue *dataValue)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) handle;
  MODEL_DATA *modelData = state->data->modelData;
  UA_Boolean val;
  dataValue->hasValue = UA_FALSE;
  if (nodeid.identifierType != UA_NODEIDTYPE_NUMERIC) {
    BAD_RESULT()
    return UA_STATUSCODE_BADNODEIDUNKNOWN;
  }

  dataValue->hasValue = UA_TRUE;
  if (nodeid.identifier.numeric == OMC_OPC_NODEID_STEP) {
    val = state->step;
  } else if (nodeid.identifier.numeric == OMC_OPC_NODEID_RUN) {
    val = state->run;
  } else if (nodeid.identifier.numeric == OMC_OPC_NODEID_ENABLE_STOP_TIME) {
    val = state->data->simulationInfo->useStopTime;
  } else if (nodeid.identifier.numeric >= VARKIND_BOOL*MAX_VARS_KIND && nodeid.identifier.numeric < (1+VARKIND_BOOL)*MAX_VARS_KIND) {
    int index1 = nodeid.identifier.numeric-VARKIND_BOOL*MAX_VARS_KIND;
    int index = index1 >= ALIAS_START_ID ? modelData->booleanAlias[index1-ALIAS_START_ID].nameID : index1;
    int negate = index1 >= ALIAS_START_ID ? modelData->booleanAlias[index1-ALIAS_START_ID].negate : 0;
    int latestValues = state->latestValues;
    pthread_mutex_lock(&state->mutex_values[latestValues]);
    val = state->boolVals[latestValues][index];
    val = negate ? !val : val;
    pthread_mutex_unlock(&state->mutex_values[latestValues]);
  } else {
    dataValue->hasValue = UA_FALSE;
    BAD_RESULT()
    return UA_STATUSCODE_BADNODEIDUNKNOWN;
  }
  dataValue->hasValue = UA_TRUE;
  UA_Variant_setScalarCopy(&dataValue->value, &val, &UA_TYPES[UA_TYPES_BOOLEAN]);
  return UA_STATUSCODE_GOOD;
}

static UA_StatusCode
writeBoolean(void *handle, const UA_NodeId nodeid, const UA_Variant *data, const UA_NumericRange *range)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) handle;
  MODEL_DATA *modelData = state->data->modelData;
  if (nodeid.identifierType != UA_NODEIDTYPE_NUMERIC) {
    BAD_RESULT()
    return UA_STATUSCODE_BADNODEIDUNKNOWN;
  }

  if (UA_Variant_isScalar(data) && data->type == &UA_TYPES[UA_TYPES_BOOLEAN] && data->data) {
    UA_Boolean newVal = *(UA_Boolean*)data->data;
    UA_StatusCode statusCode = UA_STATUSCODE_GOOD;
    pthread_mutex_lock(&state->write_values);
    if (nodeid.identifier.numeric==OMC_OPC_NODEID_STEP) {
      pthread_mutex_lock(&state->mutex_pause);
      state->step = newVal;
      pthread_mutex_unlock(&state->mutex_pause);
      pthread_cond_signal(&state->cond_pause);
    } else if (nodeid.identifier.numeric==OMC_OPC_NODEID_RUN) {
      pthread_mutex_lock(&state->mutex_pause);
      state->run = newVal;
      pthread_mutex_unlock(&state->mutex_pause);
      pthread_cond_signal(&state->cond_pause);
    } else if (nodeid.identifier.numeric==OMC_OPC_NODEID_ENABLE_STOP_TIME) {
      pthread_mutex_lock(&state->mutex_pause);
      state->data->simulationInfo->useStopTime = newVal;
      pthread_mutex_unlock(&state->mutex_pause);
      pthread_cond_signal(&state->cond_pause);
    } else if (nodeid.identifier.numeric >= VARKIND_BOOL*MAX_VARS_KIND && nodeid.identifier.numeric < (1+VARKIND_BOOL)*MAX_VARS_KIND) {
      int index1 = nodeid.identifier.numeric-VARKIND_BOOL*MAX_VARS_KIND;
      int index = index1 >= ALIAS_START_ID ? modelData->booleanAlias[index1-ALIAS_START_ID].nameID : index1;
      int negate = index1 >= ALIAS_START_ID ? modelData->booleanAlias[index1-ALIAS_START_ID].negate : 0;
      int inputIndex = state->boolValsInputIndex[index];
      newVal = negate ? !newVal : newVal;
      if (inputIndex != -1) {
        if (state->data->simulationInfo->inputVars[inputIndex] != newVal) {
          state->gotNewInput = 1;
          state->inputVarsBackup[inputIndex] = newVal;
        }
      } else {
        pthread_mutex_unlock(&state->write_values);
        statusCode = UA_STATUSCODE_BADUNEXPECTEDERROR;
      }
    } else {
      pthread_mutex_unlock(&state->write_values);
      statusCode = UA_STATUSCODE_BADUNEXPECTEDERROR;
    }
    pthread_mutex_unlock(&state->write_values);
    return statusCode;
  }
  BAD_RESULT()
  return UA_STATUSCODE_BADUNEXPECTEDERROR;
}

static UA_StatusCode
readReal(void *handle, const UA_NodeId nodeid, UA_Boolean sourceTimeStamp, const UA_NumericRange *range, UA_DataValue *dataValue)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) handle;
  MODEL_DATA *modelData = state->data->modelData;
  UA_Double val;
  int latestValues = state->latestValues;

  if (nodeid.identifierType != UA_NODEIDTYPE_NUMERIC) {
    BAD_RESULT()
    return UA_STATUSCODE_BADNODEIDUNKNOWN;
  }

  pthread_mutex_lock(&state->mutex_values[latestValues]);

  if (nodeid.identifier.numeric==OMC_OPC_NODEID_TIME) {
    val = state->time[latestValues];
  } else if (nodeid.identifier.numeric==OMC_OPC_NODEID_REAL_TIME_SCALING_FACTOR) {
    val = state->real_time_sync_scaling;
  } else if (nodeid.identifier.numeric >= VARKIND_REAL*MAX_VARS_KIND && nodeid.identifier.numeric < (1+VARKIND_REAL)*MAX_VARS_KIND) {
    int index1 = nodeid.identifier.numeric-VARKIND_REAL*MAX_VARS_KIND;
    int index = index1 >= ALIAS_START_ID ? modelData->realAlias[index1-ALIAS_START_ID].nameID : index1;
    int negate = index1 >= ALIAS_START_ID ? modelData->realAlias[index1-ALIAS_START_ID].negate : 0;
    val = state->realVals[latestValues][index];
    val = negate ? -val : val;
  } else {
    pthread_mutex_unlock(&state->mutex_values[latestValues]);
    BAD_RESULT()
    return UA_STATUSCODE_BADNODEIDUNKNOWN;
  }
  pthread_mutex_unlock(&state->mutex_values[latestValues]);

  dataValue->hasValue = UA_TRUE;
  UA_Variant_setScalarCopy(&dataValue->value, &val, &UA_TYPES[UA_TYPES_DOUBLE]);
  // UA_LOG_INFO(state->logger, UA_LOGCATEGORY_USERLAND, "read value %.6g", val);
  return UA_STATUSCODE_GOOD;
}

static UA_StatusCode
writeReal(void *handle, const UA_NodeId nodeid, const UA_Variant *data, const UA_NumericRange *range)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) handle;
  MODEL_DATA *modelData = state->data->modelData;
  UA_Double newVal;

  if (nodeid.identifierType != UA_NODEIDTYPE_NUMERIC) {
    BAD_RESULT()
    return UA_STATUSCODE_BADNODEIDUNKNOWN;
  }
  if (!(UA_Variant_isScalar(data) && (data->type == &UA_TYPES[UA_TYPES_DOUBLE] || data->type == &UA_TYPES[UA_TYPES_FLOAT]) && data->data)) {
    BAD_RESULT()
    return UA_STATUSCODE_BADUNEXPECTEDERROR;
  }
  if (data->type == &UA_TYPES[UA_TYPES_DOUBLE]) {
    newVal = *(UA_Double*)data->data;
  } else {
    newVal = *(UA_Float*)data->data;
  }
  pthread_mutex_lock(&state->write_values);
  if (nodeid.identifier.numeric==OMC_OPC_NODEID_REAL_TIME_SCALING_FACTOR) {
    state->real_time_sync_scaling = newVal;
  } else if (nodeid.identifier.numeric >= VARKIND_REAL*MAX_VARS_KIND && nodeid.identifier.numeric < (1+VARKIND_REAL)*MAX_VARS_KIND) {
    int index1 = nodeid.identifier.numeric-VARKIND_REAL*MAX_VARS_KIND;
    int index = index1 >= ALIAS_START_ID ? modelData->realAlias[index1-ALIAS_START_ID].nameID : index1;
    int negate = index1 >= ALIAS_START_ID ? modelData->realAlias[index1-ALIAS_START_ID].negate : 0;
    int inputIndex = state->realValsInputIndex[index];
    newVal = negate ? -newVal : newVal;
    if (inputIndex != -1) {
      if (state->data->simulationInfo->inputVars[inputIndex] != newVal) {
        state->gotNewInput = 1;
        state->inputVarsBackup[inputIndex] = newVal;
      }
    } else if (index < state->data->modelData->nStates) {
      state->reinitStateFlag = 1;
      state->stateWasUpdatedFlag[index] = 1;
      state->updatedStates[index] = newVal;
    } else {
      BAD_RESULT()
      pthread_mutex_unlock(&state->write_values);
      return UA_STATUSCODE_BADUNEXPECTEDERROR;
    }
  } else {
    BAD_RESULT()
    pthread_mutex_unlock(&state->write_values);
    return UA_STATUSCODE_BADUNEXPECTEDERROR;
  }
  pthread_mutex_unlock(&state->write_values);
  return UA_STATUSCODE_GOOD;
}

static inline omc_opc_ua_state* addVars(omc_opc_ua_state *state, var_kind_t varKind, int n, void *vars, int *varIndex)
{
  MODEL_DATA *modelData = state->data->modelData;
  int i;
  for (i = 0; i < n; i++, (*varIndex)++) {
    int nodeIdInt = varKind*MAX_VARS_KIND + *varIndex;
    UA_NodeId nodeId = UA_NODEID_NUMERIC(1, nodeIdInt);
    char *nameStr;
    char *commentStr;
    UA_QualifiedName name;
    UA_DataSource dataSource = {0};
    UA_VariableAttributes attr;
    UA_VariableAttributes_init(&attr);
    int inputIndex;
    int isState=0;

    switch (varKind) {
    case VARKIND_REAL:
    {
      STATIC_REAL_DATA *realVarsData = modelData->realVarsData;
      state->realVals[state->latestValues][*varIndex] = ((double*)vars)[i];
      inputIndex = realVarsData[i].info.inputIndex;
      state->realValsInputIndex[*varIndex] = inputIndex;
      nameStr = (char*) realVarsData[i].info.name;
      commentStr = (char*) realVarsData[i].info.comment;
      isState = i < modelData->nStates;
      dataSource = (UA_DataSource) {.handle = state, .read = readReal, .write = inputIndex >= 0 || isState ? writeReal : NULL};
      break;
    }
    case VARKIND_BOOL:
    {
      STATIC_BOOLEAN_DATA *booleanVarsData = modelData->booleanVarsData;
      state->boolVals[state->latestValues][*varIndex] = ((int*)vars)[i];
      inputIndex = booleanVarsData[i].info.inputIndex;
      state->boolValsInputIndex[*varIndex] = inputIndex;
      nameStr = (char*) booleanVarsData[i].info.name;
      commentStr = (char*) booleanVarsData[i].info.comment;
      dataSource = (UA_DataSource) {.handle = state, .read = readBoolean, .write = inputIndex >= 0 ? writeBoolean : NULL};
      break;
    }
    default:
      UA_LOG_INFO(state->logger, UA_LOGCATEGORY_USERLAND, "Unknown varKind %d", varKind);
      return NULL;
    }

    if (inputIndex >= 0 || isState) {
      attr.writeMask = 1;
      attr.userWriteMask = 1;
    }

    name = UA_QUALIFIEDNAME(1, nameStr);

    if (!commentStr[0]) {
      commentStr = nameStr;
    }

    attr.description = UA_LOCALIZEDTEXT("en_US", commentStr);
    attr.displayName = UA_LOCALIZEDTEXT("en_US", nameStr);

    UA_StatusCode status =
      UA_Server_addDataSourceVariableNode(state->server, nodeId,
                                          UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER),
                                          UA_NODEID_NUMERIC(0, UA_NS0ID_ORGANIZES),
                                          name, UA_NODEID_NULL, attr, dataSource, NULL);
    if (status != UA_STATUSCODE_GOOD) {
      UA_LOG_INFO(state->logger, UA_LOGCATEGORY_USERLAND, "Failed to add variable %s: 0x%X", nameStr, status);
      return NULL;
    } else {
#if 0
      UA_LOG_INFO(state->logger, UA_LOGCATEGORY_USERLAND, "Added variable %s=%d, inputIndex=%d", nameStr, nodeIdInt, inputIndex);
#endif
    }
  }
  return state;
}

static inline omc_opc_ua_state* addAliasVars(omc_opc_ua_state *state, var_kind_t varKind)
{
  MODEL_DATA *modelData = state->data->modelData;
  DATA_ALIAS *aliases;
  int i, n, maxIndex;
  switch (varKind) {
  case VARKIND_REAL:
  {
    n = modelData->nAliasReal;
    aliases = modelData->realAlias;
    maxIndex = modelData->nVariablesReal; /* Because we did not add discrete reals, etc. yet */
    break;
  }
  case VARKIND_BOOL:
  {
    n = modelData->nAliasBoolean;
    aliases = modelData->booleanAlias;
    maxIndex = modelData->nVariablesBoolean;
    break;
  }
  default:
    UA_LOG_INFO(state->logger, UA_LOGCATEGORY_USERLAND, "Unknown varKind %d", varKind);
    return NULL;
  }
  for (i = 0; i < n; i++) {
    int nodeIdInt = varKind*MAX_VARS_KIND + ALIAS_START_ID + i;
    UA_NodeId nodeId = UA_NODEID_NUMERIC(1, nodeIdInt);
    char *nameStr;
    char *commentStr;
    UA_QualifiedName name;
    UA_DataSource dataSource = {0};
    UA_VariableAttributes attr;
    UA_VariableAttributes_init(&attr);
    int inputIndex;
    int isState = 0;

    if (aliases[i].aliasType != 0) {
      /* We only alias non-parameter/time variables in OPC */
      continue;
    }

    switch (varKind) {
    case VARKIND_REAL:
    {
      int index = aliases[i].nameID;
      STATIC_REAL_DATA *realVarsData = modelData->realVarsData;
      if (index >= maxIndex) {
        continue; /* Because we did not add discrete reals, etc. yet */
      }
      inputIndex = realVarsData[index].info.inputIndex;
      nameStr = (char*) aliases[i].info.name;
      commentStr = (char*) aliases[i].info.comment;
      isState = i < modelData->nStates;
      dataSource = (UA_DataSource) {.handle = state, .read = readReal, .write = inputIndex >= 0 || isState ? writeReal : NULL};
      break;
    }
    case VARKIND_BOOL:
    {
      int index = aliases[i].nameID;
      STATIC_BOOLEAN_DATA *booleanVarsData = modelData->booleanVarsData;
      if (index >= maxIndex) {
        continue; /* Because we did not add discrete reals, etc. yet */
      }
      inputIndex = booleanVarsData[index].info.inputIndex;
      nameStr = (char*) aliases[i].info.name;
      commentStr = (char*) aliases[i].info.comment;
      dataSource = (UA_DataSource) {.handle = state, .read = readBoolean, .write = inputIndex >= 0 ? writeBoolean : NULL};
      break;
    }
    default:
      abort();
    }

    if (inputIndex >= 0 || isState) {
      attr.writeMask = 1;
      attr.userWriteMask = 1;
    }

    name = UA_QUALIFIEDNAME(1, nameStr);

    if (!commentStr[0]) {
      commentStr = nameStr;
    }

    attr.description = UA_LOCALIZEDTEXT("en_US", commentStr);
    attr.displayName = UA_LOCALIZEDTEXT("en_US", nameStr);

    UA_StatusCode status =
      UA_Server_addDataSourceVariableNode(state->server, nodeId,
                                          UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER),
                                          UA_NODEID_NUMERIC(0, UA_NS0ID_ORGANIZES),
                                          name, UA_NODEID_NULL, attr, dataSource, NULL);
    if (status != UA_STATUSCODE_GOOD) {
      UA_LOG_INFO(state->logger, UA_LOGCATEGORY_USERLAND, "Failed to add variable %s: 0x%X", nameStr, status);
      return NULL;
    } else {
#if 0
      UA_LOG_INFO(state->logger, UA_LOGCATEGORY_USERLAND, "Added variable %s=%d, inputIndex=%d", nameStr, nodeIdInt, inputIndex);
#endif
    }
  }
  return state;
}
void* omc_embedded_server_init(DATA *data, double t, double step, const char *argv_0, void (*omc_real_time_sync_update)(DATA *data, double scaling), int port)
{
  MODEL_DATA *modelData = data->modelData;
  omc_opc_ua_state *state = (omc_opc_ua_state*) malloc(sizeof(omc_opc_ua_state));
  UA_ServerConfig config = UA_ServerConfig_standard;
  var_kind_t vk;
  pthread_rwlockattr_t lockattr;
  state->logger = UA_Log_Stdout;
  state->nl = UA_ServerNetworkLayerTCP(UA_ConnectionConfig_standard, port);
  config.logger = UA_Log_Stdout;
  config.networkLayers = &state->nl;
  config.networkLayersSize = 1;
  /* The open62541 v0.2 client sets the client sampling interval to the server publishing interval
   * and does not support any queues, so we need to publish values often.
   */
  config.publishingIntervalLimits.min = 5;
  config.samplingIntervalLimits.min = 5;
  state->server = UA_Server_new(config);
  state->data = data;
  state->real_time_sync_scaling = data->real_time_sync.scaling;

  state->server_running = 1;
  state->time[0] = t;
  state->time[1] = t;
  state->omc_real_time_sync_update = omc_real_time_sync_update;

  pthread_cond_init(&state->cond_pause, NULL);
  pthread_mutex_init(&state->mutex_pause, NULL);
  pthread_mutex_init(&state->write_values, NULL);
  pthread_mutex_init(&state->mutex_values[0], NULL);
  pthread_mutex_init(&state->mutex_values[1], NULL);

  state->latestValues = 0;

  state->run = 0;
  state->step = 0;

  pthread_create(&state->thread, NULL, (void*) &threadWork, state);

  /* add a variable node to the address space */
  UA_NodeId stepNodeId = UA_NODEID_NUMERIC(0, OMC_OPC_NODEID_STEP);
  UA_QualifiedName stepName = UA_QUALIFIEDNAME(1, "OpenModelica.step");
  UA_DataSource stepDataSource = (UA_DataSource) {
      .handle = state, .read = readBoolean, .write = writeBoolean};
  UA_VariableAttributes attr;
  UA_VariableAttributes_init(&attr);
  attr.description = UA_LOCALIZEDTEXT("en_US","When set to true, the simulator takes a single step");
  attr.displayName = UA_LOCALIZEDTEXT("en_US","step");
  attr.writeMask = 1;
  attr.userWriteMask = 1;
  UA_Server_addDataSourceVariableNode(state->server, stepNodeId,
                                      UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER),
                                      UA_NODEID_NUMERIC(0, UA_NS0ID_ORGANIZES),
                                      stepName, UA_NODEID_NULL, attr, stepDataSource, NULL);

  /* Run variable */
  UA_NodeId runNodeId = UA_NODEID_NUMERIC(0, OMC_OPC_NODEID_RUN);
  UA_QualifiedName runName = UA_QUALIFIEDNAME(1, "OpenModelica.run");
  UA_VariableAttributes runAttr;
  UA_VariableAttributes_init(&runAttr);
  attr.description = UA_LOCALIZEDTEXT("en_US","When set to true, the simulator keeps running until run is set to false");
  attr.displayName = UA_LOCALIZEDTEXT("en_US","run");
  attr.writeMask = 1;
  attr.userWriteMask = 1;
  UA_Server_addDataSourceVariableNode(state->server, runNodeId,
                                      UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER),
                                      UA_NODEID_NUMERIC(0, UA_NS0ID_ORGANIZES),
                                      runName, UA_NODEID_NULL, attr, stepDataSource, NULL);

  { /* add variable for real-time scaling factor */
    UA_NodeId nodeId = UA_NODEID_NUMERIC(0, OMC_OPC_NODEID_REAL_TIME_SCALING_FACTOR);
    UA_QualifiedName name = UA_QUALIFIEDNAME(1, "OpenModelica.realTimeScalingFactor");
    UA_DataSource dataSource = (UA_DataSource) {
        .handle = state, .read = readReal, .write = writeReal};
    UA_VariableAttributes attr;
    UA_VariableAttributes_init(&attr);
    attr.description = UA_LOCALIZEDTEXT("en_US","Real-time scaling factor. 1.0=real-time, 0.0=disabled");
    attr.displayName = UA_LOCALIZEDTEXT("en_US","realTimeScalingFactor");
    attr.writeMask = 1;
    attr.userWriteMask = 1;
    UA_Server_addDataSourceVariableNode(state->server, nodeId,
                                        UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER),
                                        UA_NODEID_NUMERIC(0, UA_NS0ID_ORGANIZES),
                                        name, UA_NODEID_NULL, attr, dataSource, NULL);
  }

  { /* add variable for disabling stopTime */
    UA_NodeId nodeId = UA_NODEID_NUMERIC(0, OMC_OPC_NODEID_ENABLE_STOP_TIME);
    UA_QualifiedName name = UA_QUALIFIEDNAME(1, "OpenModelica.enableStopTime");
    UA_DataSource dataSource = (UA_DataSource) {
        .handle = state, .read = readBoolean, .write = writeBoolean};
    UA_VariableAttributes attr;
    UA_VariableAttributes_init(&attr);
    attr.description = UA_LOCALIZEDTEXT("en_US","Enabled when using the stopTime to stop the simulation");
    attr.displayName = UA_LOCALIZEDTEXT("en_US","enableStopTime");
    attr.writeMask = 1;
    attr.userWriteMask = 1;
    UA_Server_addDataSourceVariableNode(state->server, nodeId,
                                        UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER),
                                        UA_NODEID_NUMERIC(0, UA_NS0ID_ORGANIZES),
                                        name, UA_NODEID_NULL, attr, dataSource, NULL);
  }

  /* add a variable node to the address space */
  UA_NodeId timeNodeId = UA_NODEID_NUMERIC(0, OMC_OPC_NODEID_TIME);
  UA_QualifiedName timeName = UA_QUALIFIEDNAME(1, "time");
  UA_DataSource timeDataSource = (UA_DataSource) {
      .handle = state, .read = readReal, .write = NULL};
  UA_VariableAttributes timeAttr;
  UA_VariableAttributes_init(&timeAttr);
  timeAttr.description = UA_LOCALIZEDTEXT("en_US","current simulation time");
  timeAttr.displayName = UA_LOCALIZEDTEXT("en_US","time");
  UA_Server_addDataSourceVariableNode(state->server, timeNodeId,
                                      UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER),
                                      UA_NODEID_NUMERIC(0, UA_NS0ID_ORGANIZES),
                                      timeName, UA_NODEID_NULL, timeAttr, timeDataSource, NULL);

  state->gotNewInput = 0;
  state->inputVarsBackup = malloc(modelData->nInputVars * sizeof(double));
  memcpy(state->inputVarsBackup, data->simulationInfo->inputVars, modelData->nInputVars * sizeof(double));
  state->realVals[0] = malloc(modelData->nVariablesReal * sizeof(UA_Double));
  state->realVals[1] = malloc(modelData->nVariablesReal * sizeof(UA_Double));
  state->realValsInputIndex = malloc(modelData->nVariablesReal * sizeof(int));
  state->boolVals[0] = malloc(modelData->nVariablesBoolean * sizeof(UA_Boolean));
  state->boolVals[1] = malloc(modelData->nVariablesBoolean * sizeof(UA_Boolean));
  state->boolValsInputIndex = malloc(modelData->nVariablesBoolean * sizeof(int));

  state->reinitStateFlag = 0;
  state->stateWasUpdatedFlag = (int*) calloc(sizeof(int), modelData->nStates);
  state->updatedStates = (double*) malloc(sizeof(double)*modelData->nStates);

  int realIndex = 0, boolIndex = 0;
  assert(modelData->nVariablesReal < MAX_VARS_KIND);

  // state = addVars(state, VARKIND_REAL, nInputVars, modelData->realVarsData, &realIndex);
  state = addVars(state, VARKIND_REAL, modelData->nVariablesReal, (data->localData[0])->realVars, &realIndex);
  state = addVars(state, VARKIND_BOOL, modelData->nVariablesBoolean, (data->localData[0])->booleanVars, &boolIndex);
  for (vk=VARKIND_REAL; vk<=VARKIND_BOOL; vk++) {
    state = addAliasVars(state, vk);
  }

  return state;
}

void omc_embedded_server_deinit(void *state_vp)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) state_vp;
  void *res;

  state->server_running = 0;
  if (pthread_join(state->thread, &res)) {
    fprintf(stderr, "Failed to join OPC UA thread\n");
  }
  if (0 != res) {
    fprintf(stderr, "OPC UA server did not shut down cleanly\n");
  }
  UA_Server_delete(state->server);
  state->nl.deleteMembers(&state->nl);
  pthread_mutex_destroy(&state->mutex_pause);
  pthread_mutex_destroy(&state->write_values);
  pthread_mutex_destroy(&state->mutex_values[0]);
  pthread_mutex_destroy(&state->mutex_values[1]);
  pthread_cond_destroy(&state->cond_pause);
  free(state->inputVarsBackup);
  free(state->realVals[0]);
  free(state->realVals[1]);
  free(state->realValsInputIndex);
  free(state->boolVals[0]);
  free(state->boolVals[1]);
  free(state->boolValsInputIndex);
  free(state);
}

int omc_embedded_server_update(void *state_vp, double t)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) state_vp;
  int i, realIndex=0, boolIndex=0, res=0;
  DATA *data = state->data;
  MODEL_DATA *modelData = data->modelData;
  int latestValues;

  waitForStep(state);

  pthread_mutex_lock(&state->mutex_values[state->latestValues ? 0 : 1]);
  latestValues = state->latestValues;
  state->latestValues = state->latestValues ? 0 : 1;

  state->time[latestValues] = t;

  for (i = 0; i < modelData->nVariablesReal; i++, realIndex++) {
    state->realVals[latestValues][realIndex] = (data->localData[0])->realVars[i];
  }
  for (i = 0; i < modelData->nVariablesReal; i++, boolIndex++) {
    state->boolVals[latestValues][boolIndex] = (data->localData[0])->booleanVars[i];
  }

  pthread_mutex_unlock(&state->mutex_values[latestValues]);
  pthread_mutex_lock(&state->write_values);

  if (state->gotNewInput) {
    res = 1; /* Trigger an event in the solver, restarting it */
    memcpy(data->simulationInfo->inputVars, state->inputVarsBackup, modelData->nInputVars * sizeof(double));
  }

  if (state->reinitStateFlag) {
    res = 1; /* Trigger an event in the solver, restarting it */
    for (i = 0; i < modelData->nStates; i++) {
      if (state->stateWasUpdatedFlag[i]) {
        state->stateWasUpdatedFlag[i] = 0;
        (data->localData[0])->realVars[i] = state->updatedStates[i];
      }
    }
  }
  pthread_mutex_unlock(&state->write_values);

  return res;
}
