#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

#include "open62541.h"
#include "omc_opc_ua.h"
#include "simulation/solver/embedded_server.h"

#define PORT 48410
#define URL "opc.tcp://localhost:48410"
#define NODE(kind, i) UA_NODEID_NUMERIC(1, (kind)*MAX_VARS_KIND + (i))

static int failed = 0;

#define CHECK(cond, ...) do { if (!(cond)) { fprintf(stderr, __VA_ARGS__); fputc('\n', stderr); failed = 1; } } while (0)

static int readValue(UA_Client *c, UA_NodeId id, const UA_DataType *type, void *out)
{
  UA_Variant v;
  int ok;
  UA_Variant_init(&v);
  ok = UA_Client_readValueAttribute(c, id, &v) == UA_STATUSCODE_GOOD
       && UA_Variant_isScalar(&v) && v.type == type;
  if (ok) {
    memcpy(out, v.data, type->memSize);
  }
  UA_Variant_deleteMembers(&v);
  return ok;
}

static UA_StatusCode writeValue(UA_Client *c, UA_NodeId id, const UA_DataType *type, void *val)
{
  UA_Variant v;
  UA_Variant_setScalar(&v, val, type);
  return UA_Client_writeValueAttribute(c, id, &v);
}

static int hasName(UA_Client *c, UA_NodeId id, const char *name)
{
  UA_LocalizedText text;
  int ok;
  UA_LocalizedText_init(&text);
  ok = UA_Client_readDisplayNameAttribute(c, id, &text) == UA_STATUSCODE_GOOD
       && text.text.length == strlen(name) && !memcmp(text.text.data, name, text.text.length);
  UA_LocalizedText_deleteMembers(&text);
  return ok;
}

static int hasAttributes(UA_Client *c, UA_NodeId id, const UA_DataType *type, UA_Byte accessLevel)
{
  UA_NodeId dataType;
  UA_Byte level = 0;
  UA_NodeId_init(&dataType);
  return UA_Client_readDataTypeAttribute(c, id, &dataType) == UA_STATUSCODE_GOOD
         && UA_NodeId_equal(&dataType, &type->typeId)
         && UA_Client_readAccessLevelAttribute(c, id, &level) == UA_STATUSCODE_GOOD
         && level == accessLevel;
}

static void* client(void *arg)
{
  const UA_DataType *DOUBLE = &UA_TYPES[UA_TYPES_DOUBLE], *INT64 = &UA_TYPES[UA_TYPES_INT64], *BOOLEAN = &UA_TYPES[UA_TYPES_BOOLEAN];
  const UA_Byte R = UA_ACCESSLEVELMASK_READ, RW = UA_ACCESSLEVELMASK_READ | UA_ACCESSLEVELMASK_WRITE;
  UA_Client *c = UA_Client_new(UA_ClientConfig_standard);
  UA_Double t = -1, d = 0, newC = 20, newV = 6;
  UA_Int64 n = 0, newN = 9;
  UA_Boolean b = 0, newB = 0, run = 1;
  int i;

  for (i = 0; i < 100 && UA_Client_connect(c, URL) != UA_STATUSCODE_GOOD; i++) {
    usleep(100000);
  }
  CHECK(i < 100, "Could not connect to the server");

  /* The server thread runs before the first update, so wait for its values */
  for (i = 0; i < 100 && readValue(c, UA_NODEID_NUMERIC(0, OMC_OPC_NODEID_TIME), DOUBLE, &t) && t != 0.5; i++) {
    usleep(100000);
  }
  CHECK(t == 0.5, "time: expected 0.5, got %g", t);
  CHECK(readValue(c, NODE(VARKIND_REAL, 0), DOUBLE, &d) && d == 1.5, "x: expected 1.5, got %g", d);
  CHECK(readValue(c, NODE(VARKIND_REAL, ALIAS_START_ID), DOUBLE, &d) && d == -1.5, "c = -x: expected -1.5, got %g", d);
  CHECK(readValue(c, NODE(VARKIND_REAL, 3), DOUBLE, &d) && d == 4, "v[2]: expected 4, got %g", d);
  CHECK(readValue(c, NODE(VARKIND_INTEGER, 0), INT64, &n) && n == 4, "n: expected 4, got %lld", (long long) n);
  CHECK(readValue(c, NODE(VARKIND_BOOL, 0), BOOLEAN, &b) && b, "b: expected true");
  CHECK(readValue(c, NODE(VARKIND_REAL_PARAMETER, 0), DOUBLE, &d) && d == 2.5, "p: expected 2.5, got %g", d);
  CHECK(readValue(c, NODE(VARKIND_REAL_PARAMETER, ALIAS_START_ID), DOUBLE, &d) && d == 2.5, "q = p: expected 2.5, got %g", d);
  CHECK(readValue(c, NODE(VARKIND_INTEGER_PARAMETER, 0), INT64, &n) && n == 7, "m: expected 7, got %lld", (long long) n);

  CHECK(hasName(c, NODE(VARKIND_REAL, 2), "v[1]") && hasName(c, NODE(VARKIND_REAL, 3), "v[2]"), "Wrong names of the elements of v");
  CHECK(hasName(c, NODE(VARKIND_REAL, ALIAS_START_ID), "c"), "Wrong name of the alias c");

  CHECK(hasAttributes(c, NODE(VARKIND_REAL, 0), DOUBLE, RW), "x: expected a writable Double");
  CHECK(hasAttributes(c, NODE(VARKIND_REAL, ALIAS_START_ID), DOUBLE, RW), "c: expected a writable Double");
  CHECK(hasAttributes(c, NODE(VARKIND_REAL, 1), DOUBLE, R), "der(x): expected a read-only Double");
  CHECK(hasAttributes(c, NODE(VARKIND_REAL, 3), DOUBLE, RW), "v[2]: expected a writable Double");
  CHECK(hasAttributes(c, NODE(VARKIND_INTEGER, 0), INT64, RW), "n: expected a writable Int64");
  CHECK(hasAttributes(c, NODE(VARKIND_BOOL, 0), BOOLEAN, RW), "b: expected a writable Boolean");
  CHECK(hasAttributes(c, NODE(VARKIND_REAL_PARAMETER, 0), DOUBLE, R), "p: expected a read-only Double");
  CHECK(hasAttributes(c, UA_NODEID_NUMERIC(0, OMC_OPC_NODEID_TIME), DOUBLE, R), "time: expected a read-only Double");
  CHECK(hasAttributes(c, UA_NODEID_NUMERIC(0, OMC_OPC_NODEID_RUN), BOOLEAN, RW), "run: expected a writable Boolean");

  CHECK(writeValue(c, NODE(VARKIND_REAL, 1), DOUBLE, &newC) == UA_STATUSCODE_BADNOTWRITABLE, "der(x): expected BadNotWritable");
  CHECK(writeValue(c, NODE(VARKIND_REAL, 0), INT64, &newN) == UA_STATUSCODE_BADTYPEMISMATCH, "x: expected BadTypeMismatch for an Int64");
  CHECK(writeValue(c, NODE(VARKIND_REAL_PARAMETER, 0), DOUBLE, &newC) == UA_STATUSCODE_BADNOTWRITABLE, "p: expected BadNotWritable");
  CHECK(writeValue(c, NODE(VARKIND_REAL, ALIAS_START_ID), DOUBLE, &newC) == UA_STATUSCODE_GOOD, "Could not write c");
  CHECK(writeValue(c, NODE(VARKIND_INTEGER, 0), INT64, &newN) == UA_STATUSCODE_GOOD, "Could not write n");
  CHECK(writeValue(c, NODE(VARKIND_BOOL, 0), BOOLEAN, &newB) == UA_STATUSCODE_GOOD, "Could not write b");
  CHECK(writeValue(c, NODE(VARKIND_REAL, 3), DOUBLE, &newV) == UA_STATUSCODE_GOOD, "Could not write v[2]");
  CHECK(writeValue(c, UA_NODEID_NUMERIC(0, OMC_OPC_NODEID_RUN), BOOLEAN, &run) == UA_STATUSCODE_GOOD, "Could not write run");

  UA_Client_disconnect(c);
  UA_Client_delete(c);
  return NULL;
}

static void realTimeSyncUpdate(DATA *data, double scaling)
{
}

int main(void)
{
  DIMENSION_ATTRIBUTE vDims[1] = {{.type = DIMENSION_BY_START, .start = 2}};
  STATIC_REAL_DATA realVarsData[3] = {
    {.dimension = {.scalar_length = 1}, .info = {.inputIndex = -1, .name = "x", .comment = ""}},
    {.dimension = {.scalar_length = 1}, .info = {.inputIndex = -1, .name = "der(x)", .comment = ""}},
    {.dimension = {.numberOfDimensions = 1, .dimensions = vDims, .scalar_length = 2}, .info = {.inputIndex = 2, .name = "v", .comment = ""}}};
  STATIC_INTEGER_DATA integerVarsData[1] = {{.dimension = {.scalar_length = 1}, .info = {.inputIndex = 0, .name = "n", .comment = ""}}};
  STATIC_BOOLEAN_DATA booleanVarsData[1] = {{.dimension = {.scalar_length = 1}, .info = {.inputIndex = 1, .name = "b", .comment = ""}}};
  STATIC_REAL_DATA realParameterData[1] = {{.dimension = {.scalar_length = 1}, .info = {.inputIndex = -1, .name = "p", .comment = ""}}};
  STATIC_INTEGER_DATA integerParameterData[1] = {{.dimension = {.scalar_length = 1}, .info = {.inputIndex = -1, .name = "m", .comment = ""}}};
  DATA_REAL_ALIAS realAlias[2] = {
    {.negate = 1, .nameID = 0, .aliasType = ALIAS_TYPE_VARIABLE, .info = {.name = "c", .comment = ""}},
    {.negate = 0, .nameID = 0, .aliasType = ALIAS_TYPE_PARAMETER, .info = {.name = "q", .comment = ""}}};
  size_t realVarsIndex[3] = {0, 1, 2}, scalarIndex[1] = {0};
  modelica_real realVars[4] = {1, -1, 3, 4};
  modelica_integer integerVars[1] = {4};
  modelica_boolean booleanVars[1] = {0};
  modelica_real realParameter[1] = {2.5};
  modelica_integer integerParameter[1] = {7};
  modelica_real inputVars[4] = {4, 1, 3, 4};
  MODEL_DATA modelData = {0};
  SIMULATION_INFO simulationInfo = {0};
  SIMULATION_DATA simulationData = {0};
  SIMULATION_DATA *localData[1] = {&simulationData};
  DATA data = {0};
  void *dll, *state;
  pthread_t thread;
  int res, terminate = 0;

  modelData.nStates = modelData.nStatesArray = 1;
  modelData.nVariablesReal = 4;
  modelData.nVariablesRealArray = 3;
  modelData.nVariablesInteger = modelData.nVariablesIntegerArray = 1;
  modelData.nVariablesBoolean = modelData.nVariablesBooleanArray = 1;
  modelData.nParametersReal = modelData.nParametersRealArray = 1;
  modelData.nParametersInteger = modelData.nParametersIntegerArray = 1;
  modelData.nAliasReal = modelData.nAliasRealArray = 2;
  modelData.nInputVars = 4;
  modelData.realVarsData = realVarsData;
  modelData.integerVarsData = integerVarsData;
  modelData.booleanVarsData = booleanVarsData;
  modelData.realParameterData = realParameterData;
  modelData.integerParameterData = integerParameterData;
  modelData.realAlias = realAlias;
  simulationInfo.realVarsIndex = realVarsIndex;
  simulationInfo.integerVarsIndex = scalarIndex;
  simulationInfo.booleanVarsIndex = scalarIndex;
  simulationInfo.realParamsIndex = scalarIndex;
  simulationInfo.integerParamsIndex = scalarIndex;
  simulationInfo.realParameter = realParameter;
  simulationInfo.integerParameter = integerParameter;
  simulationInfo.inputVars = inputVars;
  simulationData.realVars = realVars;
  simulationData.integerVars = integerVars;
  simulationData.booleanVars = booleanVars;
  data.modelData = &modelData;
  data.simulationInfo = &simulationInfo;
  data.localData = localData;

  dll = embedded_server_load_functions(OMOPCUA_PATH);
  state = embedded_server_init(&data, 0, 0.1, "test_embedded_server", realTimeSyncUpdate, PORT);
  CHECK(state != NULL, "embedded_server_init failed");

  realVars[0] = 1.5;
  booleanVars[0] = 1;
  pthread_create(&thread, NULL, client, NULL);
  res = embedded_server_update(state, 0.5, &terminate);
  pthread_join(thread, NULL);

  CHECK(res == 1, "embedded_server_update: expected 1 after the writes, got %d", res);
  CHECK(realVars[0] == -20, "x after the write of c = -x: expected -20, got %g", realVars[0]);
  CHECK(inputVars[0] == 9, "input n: expected 9, got %g", inputVars[0]);
  CHECK(inputVars[1] == 0, "input b: expected 0, got %g", inputVars[1]);
  CHECK(inputVars[2] == 3 && inputVars[3] == 6, "input v: expected {3, 6}, got {%g, %g}", inputVars[2], inputVars[3]);
  CHECK(!terminate, "terminate was set");

  {
    /* run is still set, so the next update does not wait for a client */
    UA_Client *c = UA_Client_new(UA_ClientConfig_standard);
    UA_Int64 sameN = 9;
    CHECK(UA_Client_connect(c, URL) == UA_STATUSCODE_GOOD
          && writeValue(c, NODE(VARKIND_INTEGER, 0), &UA_TYPES[UA_TYPES_INT64], &sameN) == UA_STATUSCODE_GOOD, "Could not write n again");
    UA_Client_disconnect(c);
    UA_Client_delete(c);
  }
  res = embedded_server_update(state, 0.6, &terminate);
  CHECK(res == 0, "embedded_server_update: expected 0 after writing an unchanged input, got %d", res);

  embedded_server_deinit(state);
  embedded_server_unload_functions(dll);

  printf(failed ? "Some tests failed!\n" : "All tests passed!\n");
  return failed;
}
