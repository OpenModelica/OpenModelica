/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#define _XOPEN_SOURCE 600
#include "omc_opc_ua.h"
#include "simulation/arrayIndex.h"
#include "open62541.h"
#include <pthread.h>

#define BAD_RESULT() fprintf(stderr, "%s:%d: Bad OPC result\n", __FILE__, __LINE__);

#define N_VARKINDS (VARKIND_BOOL_PARAMETER + 1)

typedef struct {
  int index;
  int negate;
} omc_opc_ua_alias;

typedef struct {
  DATA *data;
  UA_Logger logger;
  UA_ServerNetworkLayer nl;
  UA_Server *server;
  UA_Boolean server_running;
  UA_Boolean run;
  UA_Boolean step;
  UA_Boolean terminate;
  UA_Boolean oldUseStopTime;
  pthread_mutex_t mutex_pause;
  pthread_cond_t cond_pause;
  double time[2];
  pthread_t thread;
  double *inputVarsBackup;
  int gotNewInput;
  pthread_mutex_t write_values;
  pthread_mutex_t mutex_values;
  int latestValues;
  UA_Double *realVals[2];
  UA_Int64 *intVals[2];
  UA_Boolean *boolVals[2];
  /* inputIndex[kind][i] is the index in inputVars of variable i, or -1 */
  int *inputIndex[N_VARKINDS];
  omc_opc_ua_alias *aliases[N_VARKINDS];
  int nAliases[N_VARKINDS];
  int reinitStateFlag;
  int *stateWasUpdatedFlag;
  double *updatedStates;
  double real_time_sync_scaling;
  void (*omc_real_time_sync_update)(DATA *data, double scaling);
} omc_opc_ua_state;

static void* threadWork(void *data)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) data;
  UA_StatusCode status = UA_Server_run(state->server, &state->server_running);
  if (UA_STATUSCODE_GOOD != status) {
    UA_LOG_INFO(state->logger, UA_LOGCATEGORY_SERVER, "UA_Server_run returned code: 0x%08x", status);
    return (void*)1;
  }
  return (void*)0;
}

static void waitForStep(omc_opc_ua_state *state)
{
  int run;
  double scaling;
  pthread_mutex_lock(&state->mutex_pause);
  state->step = 0;
  run = state->run;
  while (!(state->run || state->step)) {
    pthread_cond_wait(&state->cond_pause, &state->mutex_pause);
  }
  pthread_mutex_unlock(&state->mutex_pause);
  pthread_mutex_lock(&state->write_values);
  scaling = state->real_time_sync_scaling;
  pthread_mutex_unlock(&state->write_values);
  if (!run || state->data->real_time_sync.scaling != scaling) {
    /* We were not running or the scaling factor changed. Reset the real-time synchronization! */
    state->omc_real_time_sync_update(state->data, scaling);
    state->data->real_time_sync.scaling = scaling;
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
  UA_Boolean val;
  dataValue->hasValue = UA_FALSE;
  if (nodeid.identifierType != UA_NODEIDTYPE_NUMERIC) {
    BAD_RESULT()
    return UA_STATUSCODE_BADNODEIDUNKNOWN;
  }

  if (nodeid.identifier.numeric == OMC_OPC_NODEID_STEP) {
    val = state->step;
  } else if (nodeid.identifier.numeric == OMC_OPC_NODEID_RUN) {
    val = state->run;
  } else if (nodeid.identifier.numeric == OMC_OPC_NODEID_ENABLE_STOP_TIME) {
    val = state->data->simulationInfo->useStopTime;
  } else if (nodeid.identifier.numeric == OMC_OPC_NODEID_TERMINATE) {
    val = state->terminate;
  } else {
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
      if (!(state->terminate)) {  /* prevent writes to useStopTime if terminate flag is set */
        pthread_mutex_lock(&state->mutex_pause);
        state->data->simulationInfo->useStopTime = newVal;
        pthread_mutex_unlock(&state->mutex_pause);
      } else {
        statusCode = UA_STATUSCODE_BADREQUESTNOTALLOWED;
      }
    } else if (nodeid.identifier.numeric==OMC_OPC_NODEID_TERMINATE) {
      pthread_mutex_lock(&state->mutex_pause);

      if (newVal) {
        /* Store prev. useStopTime state in case terminate flag is reset in same step */
        state->oldUseStopTime = state->data->simulationInfo->useStopTime;
        state->data->simulationInfo->useStopTime = newVal;  /* enable stop time for termination */
      }
      else if (state->terminate)  /* Falling edge of this flag occurred in the same step, restore prev. val of useStopTime */
        state->data->simulationInfo->useStopTime = state->oldUseStopTime;

      state->terminate = newVal;

      pthread_mutex_unlock(&state->mutex_pause);
    } else {
      statusCode = UA_STATUSCODE_BADNODEIDUNKNOWN;
    }
    pthread_mutex_unlock(&state->write_values);
    return statusCode;
  }
  BAD_RESULT()
  return UA_STATUSCODE_BADTYPEMISMATCH;
}

static UA_StatusCode
readReal(void *handle, const UA_NodeId nodeid, UA_Boolean sourceTimeStamp, const UA_NumericRange *range, UA_DataValue *dataValue)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) handle;
  UA_Double val;

  if (nodeid.identifierType != UA_NODEIDTYPE_NUMERIC) {
    BAD_RESULT()
    return UA_STATUSCODE_BADNODEIDUNKNOWN;
  }

  if (nodeid.identifier.numeric==OMC_OPC_NODEID_TIME) {
    pthread_mutex_lock(&state->mutex_values);
    val = state->time[state->latestValues];
    pthread_mutex_unlock(&state->mutex_values);
  } else if (nodeid.identifier.numeric==OMC_OPC_NODEID_REAL_TIME_SCALING_FACTOR) {
    val = state->real_time_sync_scaling;
  } else {
    BAD_RESULT()
    return UA_STATUSCODE_BADNODEIDUNKNOWN;
  }

  dataValue->hasValue = UA_TRUE;
  UA_Variant_setScalarCopy(&dataValue->value, &val, &UA_TYPES[UA_TYPES_DOUBLE]);
  return UA_STATUSCODE_GOOD;
}

static UA_StatusCode
writeReal(void *handle, const UA_NodeId nodeid, const UA_Variant *data, const UA_NumericRange *range)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) handle;

  if (nodeid.identifierType != UA_NODEIDTYPE_NUMERIC || nodeid.identifier.numeric != OMC_OPC_NODEID_REAL_TIME_SCALING_FACTOR) {
    BAD_RESULT()
    return UA_STATUSCODE_BADNODEIDUNKNOWN;
  }
  if (!(UA_Variant_isScalar(data) && data->type == &UA_TYPES[UA_TYPES_DOUBLE] && data->data)) {
    BAD_RESULT()
    return UA_STATUSCODE_BADTYPEMISMATCH;
  }
  pthread_mutex_lock(&state->write_values);
  state->real_time_sync_scaling = *(UA_Double*)data->data;
  pthread_mutex_unlock(&state->write_values);
  return UA_STATUSCODE_GOOD;
}

static int isVariableKind(var_kind_t kind)
{
  return kind == VARKIND_REAL || kind == VARKIND_BOOL || kind == VARKIND_INTEGER;
}

static long numScalars(const MODEL_DATA *modelData, var_kind_t kind)
{
  switch (kind) {
  case VARKIND_REAL: return modelData->nVariablesReal;
  case VARKIND_BOOL: return modelData->nVariablesBoolean;
  case VARKIND_INTEGER: return modelData->nVariablesInteger;
  case VARKIND_REAL_PARAMETER: return modelData->nParametersReal;
  case VARKIND_INTEGER_PARAMETER: return modelData->nParametersInteger;
  case VARKIND_BOOL_PARAMETER: return modelData->nParametersBoolean;
  }
  return 0;
}

static long numArrays(const MODEL_DATA *modelData, var_kind_t kind)
{
  switch (kind) {
  case VARKIND_REAL: return modelData->nVariablesRealArray;
  case VARKIND_BOOL: return modelData->nVariablesBooleanArray;
  case VARKIND_INTEGER: return modelData->nVariablesIntegerArray;
  case VARKIND_REAL_PARAMETER: return modelData->nParametersRealArray;
  case VARKIND_INTEGER_PARAMETER: return modelData->nParametersIntegerArray;
  case VARKIND_BOOL_PARAMETER: return modelData->nParametersBooleanArray;
  }
  return 0;
}

/* The dimensions, the info and the index of the first scalar of (array) variable k */
static size_t arrayInfo(const DATA *data, var_kind_t kind, long k, const DIMENSION_INFO **dim, const VAR_INFO **info)
{
  const MODEL_DATA *m = data->modelData;
  const SIMULATION_INFO *s = data->simulationInfo;
  switch (kind) {
  case VARKIND_REAL: *dim = &m->realVarsData[k].dimension; *info = &m->realVarsData[k].info; return s->realVarsIndex[k];
  case VARKIND_BOOL: *dim = &m->booleanVarsData[k].dimension; *info = &m->booleanVarsData[k].info; return s->booleanVarsIndex[k];
  case VARKIND_INTEGER: *dim = &m->integerVarsData[k].dimension; *info = &m->integerVarsData[k].info; return s->integerVarsIndex[k];
  case VARKIND_REAL_PARAMETER: *dim = &m->realParameterData[k].dimension; *info = &m->realParameterData[k].info; return s->realParamsIndex[k];
  case VARKIND_INTEGER_PARAMETER: *dim = &m->integerParameterData[k].dimension; *info = &m->integerParameterData[k].info; return s->integerParamsIndex[k];
  case VARKIND_BOOL_PARAMETER: *dim = &m->booleanParameterData[k].dimension; *info = &m->booleanParameterData[k].info; return s->booleanParamsIndex[k];
  }
  abort();
}

static const UA_DataType* dataType(var_kind_t kind)
{
  switch (kind) {
  case VARKIND_REAL: case VARKIND_REAL_PARAMETER: return &UA_TYPES[UA_TYPES_DOUBLE];
  case VARKIND_INTEGER: case VARKIND_INTEGER_PARAMETER: return &UA_TYPES[UA_TYPES_INT64];
  default: return &UA_TYPES[UA_TYPES_BOOLEAN];
  }
}

/* The kind of a model variable node and the index of its value, or -1 */
static int resolveNode(omc_opc_ua_state *state, const UA_NodeId *nodeid, var_kind_t *kind, int *negate)
{
  UA_UInt32 n;
  if (nodeid->identifierType != UA_NODEIDTYPE_NUMERIC || nodeid->namespaceIndex != 1) {
    return -1;
  }
  *kind = (var_kind_t) (nodeid->identifier.numeric / MAX_VARS_KIND);
  if (*kind < VARKIND_REAL || *kind >= N_VARKINDS) {
    return -1;
  }
  n = nodeid->identifier.numeric % MAX_VARS_KIND;
  *negate = 0;
  if (n < ALIAS_START_ID) {
    return n < numScalars(state->data->modelData, *kind) ? (int) n : -1;
  }
  n -= ALIAS_START_ID;
  if ((int) n >= state->nAliases[*kind]) {
    return -1;
  }
  *negate = state->aliases[*kind][n].negate;
  return state->aliases[*kind][n].index;
}

static int isWritable(omc_opc_ua_state *state, var_kind_t kind, int index)
{
  return (isVariableKind(kind) && state->inputIndex[kind][index] >= 0) ||
         (kind == VARKIND_REAL && index < state->data->modelData->nStates);
}

static UA_StatusCode
readVariable(void *handle, const UA_NodeId nodeid, UA_Boolean sourceTimeStamp, const UA_NumericRange *range, UA_DataValue *dataValue)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) handle;
  const SIMULATION_INFO *sInfo = state->data->simulationInfo;
  var_kind_t kind;
  int negate;
  int index = resolveNode(state, &nodeid, &kind, &negate);
  UA_Double r = 0;
  UA_Int64 i = 0;
  UA_Boolean b = 0;

  if (index < 0) {
    return UA_STATUSCODE_BADNODEIDUNKNOWN;
  }
  pthread_mutex_lock(&state->mutex_values);
  switch (kind) {
  case VARKIND_REAL: r = state->realVals[state->latestValues][index]; break;
  case VARKIND_INTEGER: i = state->intVals[state->latestValues][index]; break;
  case VARKIND_BOOL: b = state->boolVals[state->latestValues][index]; break;
  case VARKIND_REAL_PARAMETER: r = sInfo->realParameter[index]; break;
  case VARKIND_INTEGER_PARAMETER: i = sInfo->integerParameter[index]; break;
  case VARKIND_BOOL_PARAMETER: b = sInfo->booleanParameter[index]; break;
  }
  pthread_mutex_unlock(&state->mutex_values);

  if (dataType(kind) == &UA_TYPES[UA_TYPES_DOUBLE]) {
    r = negate ? -r : r;
    UA_Variant_setScalarCopy(&dataValue->value, &r, dataType(kind));
  } else if (dataType(kind) == &UA_TYPES[UA_TYPES_INT64]) {
    i = negate ? -i : i;
    UA_Variant_setScalarCopy(&dataValue->value, &i, dataType(kind));
  } else {
    b = negate ? !b : b;
    UA_Variant_setScalarCopy(&dataValue->value, &b, dataType(kind));
  }
  dataValue->hasValue = UA_TRUE;
  return UA_STATUSCODE_GOOD;
}

static UA_StatusCode
writeVariable(void *handle, const UA_NodeId nodeid, const UA_Variant *data, const UA_NumericRange *range)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) handle;
  var_kind_t kind;
  int negate;
  int index = resolveNode(state, &nodeid, &kind, &negate);
  double val;

  if (index < 0) {
    return UA_STATUSCODE_BADNODEIDUNKNOWN;
  }
  if (!isWritable(state, kind, index)) {
    return UA_STATUSCODE_BADNOTWRITABLE;
  }
  if (!(UA_Variant_isScalar(data) && data->type == dataType(kind) && data->data)) {
    return UA_STATUSCODE_BADTYPEMISMATCH;
  }
  switch (kind) {
  case VARKIND_REAL: val = *(UA_Double*)data->data; val = negate ? -val : val; break;
  case VARKIND_INTEGER: val = (double) *(UA_Int64*)data->data; val = negate ? -val : val; break;
  default: val = negate ? !*(UA_Boolean*)data->data : *(UA_Boolean*)data->data; break;
  }

  pthread_mutex_lock(&state->write_values);
  if (state->inputIndex[kind][index] >= 0) {
    double *input = &state->inputVarsBackup[state->inputIndex[kind][index]];
    if (*input != val) {
      state->gotNewInput = 1;
      *input = val;
    }
  } else {
    state->reinitStateFlag = 1;
    state->stateWasUpdatedFlag[index] = 1;
    state->updatedStates[index] = val;
  }
  pthread_mutex_unlock(&state->write_values);
  return UA_STATUSCODE_GOOD;
}

static void setAttributes(UA_VariableAttributes *attr, char *name, char *description, const UA_DataType *type, int writable)
{
  UA_VariableAttributes_init(attr);
  /* set it to scalar as some clients do not like -2 variant */
  attr->valueRank = -1;
  attr->dataType = type->typeId;
  attr->accessLevel = UA_ACCESSLEVELMASK_READ | (writable ? UA_ACCESSLEVELMASK_WRITE : 0);
  attr->userAccessLevel = attr->accessLevel;
  /* OMEdit uses the write mask to find the writable variables */
  attr->writeMask = writable ? 1 : 0;
  attr->userWriteMask = attr->writeMask;
  attr->description = UA_LOCALIZEDTEXT("en_US", description[0] ? description : name);
  attr->displayName = UA_LOCALIZEDTEXT("en_US", name);
}

static int addVariableNode(omc_opc_ua_state *state, var_kind_t kind, UA_UInt32 id, const char *name, const char *comment, int writable)
{
  UA_VariableAttributes attr;
  UA_DataSource dataSource = {.handle = state, .read = readVariable, .write = writeVariable};
  UA_StatusCode status;
  setAttributes(&attr, (char*) name, (char*) comment, dataType(kind), writable);
  status = UA_Server_addDataSourceVariableNode(state->server, UA_NODEID_NUMERIC(1, kind*MAX_VARS_KIND + id),
                                               UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER),
                                               UA_NODEID_NUMERIC(0, UA_NS0ID_ORGANIZES),
                                               UA_QUALIFIEDNAME(1, (char*) name), UA_NODEID_NULL, attr, dataSource, NULL);
  if (status != UA_STATUSCODE_GOOD) {
    UA_LOG_INFO(state->logger, UA_LOGCATEGORY_USERLAND, "Failed to add variable %s: 0x%X", name, status);
    return 1;
  }
  return 0;
}

static int addVariables(omc_opc_ua_state *state, var_kind_t kind)
{
  const MODEL_DATA *modelData = state->data->modelData;
  const DIMENSION_INFO *dim;
  const VAR_INFO *info;
  char name[4096];
  long k;
  size_t e, start;

  if (numScalars(modelData, kind) >= ALIAS_START_ID) {
    UA_LOG_INFO(state->logger, UA_LOGCATEGORY_USERLAND, "Too many variables of kind %d", kind);
    return 1;
  }
  if (isVariableKind(kind)) {
    state->inputIndex[kind] = (int*) malloc(numScalars(modelData, kind) * sizeof(int));
  }
  for (k = 0; k < numArrays(modelData, kind); k++) {
    start = arrayInfo(state->data, kind, k, &dim, &info);
    for (e = 0; e < dim->scalar_length; e++) {
      int index = (int) (start + e);
      if (isVariableKind(kind)) {
        state->inputIndex[kind][index] = info->inputIndex >= 0 ? info->inputIndex + (int) e : -1;
      }
      printArrayElementName(name, sizeof(name), info->name, dim, e, kind == VARKIND_REAL && modelData->nStatesArray <= k && k < 2*modelData->nStatesArray);
      if (addVariableNode(state, kind, index, name, info->comment, isWritable(state, kind, index))) {
        return 1;
      }
    }
  }
  return 0;
}

/* Adds the aliases of the variables of `kind` and the parameters of `paramKind` */
static int addAliases(omc_opc_ua_state *state, var_kind_t kind, var_kind_t paramKind)
{
  const MODEL_DATA *modelData = state->data->modelData;
  const DATA_ALIAS *aliases;
  const DIMENSION_INFO *dim;
  const VAR_INFO *info;
  char name[4096];
  long i, n;
  size_t e, start;
  int pass;

  switch (kind) {
  case VARKIND_REAL: aliases = modelData->realAlias; n = modelData->nAliasRealArray; break;
  case VARKIND_INTEGER: aliases = modelData->integerAlias; n = modelData->nAliasIntegerArray; break;
  default: aliases = modelData->booleanAlias; n = modelData->nAliasBooleanArray; break;
  }

  /* The first pass counts the scalars to allocate the tables */
  for (pass = 0; pass < 2; pass++) {
    if (pass == 1) {
      state->aliases[kind] = (omc_opc_ua_alias*) malloc(state->nAliases[kind] * sizeof(omc_opc_ua_alias));
      state->aliases[paramKind] = (omc_opc_ua_alias*) malloc(state->nAliases[paramKind] * sizeof(omc_opc_ua_alias));
      state->nAliases[kind] = 0;
      state->nAliases[paramKind] = 0;
    }
    for (i = 0; i < n; i++) {
      const DATA_ALIAS *a = &aliases[i];
      var_kind_t targetKind;
      if (a->aliasType == ALIAS_TYPE_TIME) {
        continue;
      }
      targetKind = a->aliasType == ALIAS_TYPE_PARAMETER ? paramKind : kind;
      start = arrayInfo(state->data, targetKind, a->nameID, &dim, &info);
      for (e = 0; e < dim->scalar_length; e++) {
        int pos = state->nAliases[targetKind]++;
        int index = (int) (start + e);
        if (pass == 0) {
          continue;
        }
        if (pos >= MAX_VARS_KIND - ALIAS_START_ID) {
          UA_LOG_INFO(state->logger, UA_LOGCATEGORY_USERLAND, "Too many aliases of kind %d", targetKind);
          return 1;
        }
        state->aliases[targetKind][pos].index = index;
        state->aliases[targetKind][pos].negate = a->negate;
        printArrayElementName(name, sizeof(name), a->info.name, dim, e, targetKind == VARKIND_REAL && modelData->nStatesArray <= a->nameID && a->nameID < 2*modelData->nStatesArray);
        if (addVariableNode(state, targetKind, ALIAS_START_ID + pos, name, a->info.comment, isWritable(state, targetKind, index))) {
          return 1;
        }
      }
    }
  }
  return 0;
}

static void addControlNode(omc_opc_ua_state *state, UA_UInt32 id, char *name, char *displayName, char *description,
                           const UA_DataType *type, UA_DataSource dataSource)
{
  UA_VariableAttributes attr;
  setAttributes(&attr, displayName, description, type, dataSource.write != NULL);
  UA_Server_addDataSourceVariableNode(state->server, UA_NODEID_NUMERIC(0, id),
                                      UA_NODEID_NUMERIC(0, UA_NS0ID_OBJECTSFOLDER),
                                      UA_NODEID_NUMERIC(0, UA_NS0ID_ORGANIZES),
                                      UA_QUALIFIEDNAME(1, name), UA_NODEID_NULL, attr, dataSource, NULL);
}

static void storeValues(omc_opc_ua_state *state, int buffer)
{
  const DATA *data = state->data;
  const MODEL_DATA *modelData = data->modelData;
  long i;
  for (i = 0; i < modelData->nVariablesReal; i++) {
    state->realVals[buffer][i] = data->localData[0]->realVars[i];
  }
  for (i = 0; i < modelData->nVariablesInteger; i++) {
    state->intVals[buffer][i] = data->localData[0]->integerVars[i];
  }
  for (i = 0; i < modelData->nVariablesBoolean; i++) {
    state->boolVals[buffer][i] = data->localData[0]->booleanVars[i];
  }
}

void* omc_embedded_server_init(DATA *data, double t, double step, const char *argv_0, void (*omc_real_time_sync_update)(DATA *data, double scaling), int port)
{
  MODEL_DATA *modelData = data->modelData;
  omc_opc_ua_state *state = (omc_opc_ua_state*) calloc(1, sizeof(omc_opc_ua_state));
  UA_ServerConfig config = UA_ServerConfig_standard;
  UA_DataSource boolSource = {.handle = state, .read = readBoolean, .write = writeBoolean};
  UA_DataSource realSource = {.handle = state, .read = readReal, .write = writeReal};
  UA_DataSource timeSource = {.handle = state, .read = readReal, .write = NULL};
  int i;
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
  pthread_mutex_init(&state->mutex_values, NULL);

  state->latestValues = 0;

  state->run = 0;
  state->step = 0;
  state->terminate = 0;
  state->oldUseStopTime = data->simulationInfo->useStopTime;

  addControlNode(state, OMC_OPC_NODEID_STEP, "OpenModelica.step", "step",
                 "When set to true, the simulator takes a single step", &UA_TYPES[UA_TYPES_BOOLEAN], boolSource);
  addControlNode(state, OMC_OPC_NODEID_RUN, "OpenModelica.run", "run",
                 "When set to true, the simulator keeps running until run is set to false", &UA_TYPES[UA_TYPES_BOOLEAN], boolSource);
  addControlNode(state, OMC_OPC_NODEID_REAL_TIME_SCALING_FACTOR, "OpenModelica.realTimeScalingFactor", "realTimeScalingFactor",
                 "Real-time scaling factor. 1.0=real-time, 0.0=disabled", &UA_TYPES[UA_TYPES_DOUBLE], realSource);
  addControlNode(state, OMC_OPC_NODEID_ENABLE_STOP_TIME, "OpenModelica.enableStopTime", "enableStopTime",
                 "Enabled when using the stopTime to stop the simulation", &UA_TYPES[UA_TYPES_BOOLEAN], boolSource);
  addControlNode(state, OMC_OPC_NODEID_TIME, "time", "time",
                 "current simulation time", &UA_TYPES[UA_TYPES_DOUBLE], timeSource);
  addControlNode(state, OMC_OPC_NODEID_TERMINATE, "OpenModelica.terminate", "terminate",
                 "When set to true, the simulation is terminated gracefully", &UA_TYPES[UA_TYPES_BOOLEAN], boolSource);

  state->gotNewInput = 0;
  state->inputVarsBackup = malloc(modelData->nInputVars * sizeof(double));
  memcpy(state->inputVarsBackup, data->simulationInfo->inputVars, modelData->nInputVars * sizeof(double));
  for (i = 0; i < 2; i++) {
    state->realVals[i] = malloc(modelData->nVariablesReal * sizeof(UA_Double));
    state->intVals[i] = malloc(modelData->nVariablesInteger * sizeof(UA_Int64));
    state->boolVals[i] = malloc(modelData->nVariablesBoolean * sizeof(UA_Boolean));
  }
  storeValues(state, 0);

  state->reinitStateFlag = 0;
  state->stateWasUpdatedFlag = (int*) calloc(sizeof(int), modelData->nStates);
  state->updatedStates = (double*) malloc(sizeof(double)*modelData->nStates);

  if (addVariables(state, VARKIND_REAL) || addVariables(state, VARKIND_BOOL) || addVariables(state, VARKIND_INTEGER) ||
      addVariables(state, VARKIND_REAL_PARAMETER) || addVariables(state, VARKIND_BOOL_PARAMETER) || addVariables(state, VARKIND_INTEGER_PARAMETER) ||
      addAliases(state, VARKIND_REAL, VARKIND_REAL_PARAMETER) || addAliases(state, VARKIND_BOOL, VARKIND_BOOL_PARAMETER) ||
      addAliases(state, VARKIND_INTEGER, VARKIND_INTEGER_PARAMETER)) {
    UA_LOG_INFO(state->logger, UA_LOGCATEGORY_USERLAND, "Not all variables are available through OPC UA");
  }

  pthread_create(&state->thread, NULL, threadWork, state);

  return state;
}

void omc_embedded_server_deinit(void *state_vp)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) state_vp;
  void *res;
  int i;

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
  pthread_mutex_destroy(&state->mutex_values);
  pthread_cond_destroy(&state->cond_pause);
  free(state->inputVarsBackup);
  for (i = 0; i < 2; i++) {
    free(state->realVals[i]);
    free(state->intVals[i]);
    free(state->boolVals[i]);
  }
  for (i = 0; i < N_VARKINDS; i++) {
    free(state->inputIndex[i]);
    free(state->aliases[i]);
  }
  free(state->stateWasUpdatedFlag);
  free(state->updatedStates);
  free(state);
}

int omc_embedded_server_update(void *state_vp, double t, int *terminate)
{
  omc_opc_ua_state *state = (omc_opc_ua_state*) state_vp;
  int i, res=0;
  DATA *data = state->data;
  MODEL_DATA *modelData = data->modelData;
  int latestValues;

  latestValues = state->latestValues ? 0 : 1;

  state->time[latestValues] = t;
  storeValues(state, latestValues);

  pthread_mutex_lock(&state->mutex_values);
  state->latestValues = latestValues;
  pthread_mutex_unlock(&state->mutex_values);


  waitForStep(state);


  pthread_mutex_lock(&state->write_values);

  if (state->gotNewInput) {
    res = 1; /* Trigger an event in the solver, restarting it */
    memcpy(data->simulationInfo->inputVars, state->inputVarsBackup, modelData->nInputVars * sizeof(double));

    state->gotNewInput = 0;
  }

  if (state->reinitStateFlag) {
    res = 1; /* Trigger an event in the solver, restarting it */
    for (i = 0; i < modelData->nStates; i++) {
      if (state->stateWasUpdatedFlag[i]) {
        state->stateWasUpdatedFlag[i] = 0;
        (data->localData[0])->realVars[i] = state->updatedStates[i];
      }
    }

    state->reinitStateFlag = 0;
  }

  if (state->terminate)
    *terminate = 1;

  pthread_mutex_unlock(&state->write_values);

  return res;
}
