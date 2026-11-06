#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

#include "open62541.h"
#include "omc_opc_ua.h"
#include "simulation/solver/embedded_server.h"

#define PORT 48410
#define URL "opc.tcp://localhost:48410"
#define X_NODE (VARKIND_REAL*MAX_VARS_KIND)
#define B_NODE (VARKIND_BOOL*MAX_VARS_KIND)

static int failed = 0;

#define CHECK(cond, ...) do { if (!(cond)) { fprintf(stderr, __VA_ARGS__); fputc('\n', stderr); failed = 1; } } while (0)

static int readValue(UA_Client *c, UA_UInt16 ns, UA_UInt32 id, const UA_DataType *type, void *out)
{
  UA_Variant v;
  int ok;
  UA_Variant_init(&v);
  ok = UA_Client_readValueAttribute(c, UA_NODEID_NUMERIC(ns, id), &v) == UA_STATUSCODE_GOOD
       && UA_Variant_isScalar(&v) && v.type == type;
  if (ok) {
    memcpy(out, v.data, type->memSize);
  }
  UA_Variant_deleteMembers(&v);
  return ok;
}

static UA_StatusCode writeValue(UA_Client *c, UA_UInt16 ns, UA_UInt32 id, const UA_DataType *type, void *val)
{
  UA_Variant v;
  UA_Variant_setScalar(&v, val, type);
  return UA_Client_writeValueAttribute(c, UA_NODEID_NUMERIC(ns, id), &v);
}

static void* client(void *arg)
{
  UA_Client *c = UA_Client_new(UA_ClientConfig_standard);
  UA_Double t = -1, x = 0, newX = 20;
  UA_Boolean b = 0, run = 1;
  int i;

  for (i = 0; i < 100 && UA_Client_connect(c, URL) != UA_STATUSCODE_GOOD; i++) {
    usleep(100000);
  }
  CHECK(i < 100, "Could not connect to the server");

  /* The server thread runs before the first update, so wait for its values */
  for (i = 0; i < 100 && readValue(c, 0, OMC_OPC_NODEID_TIME, &UA_TYPES[UA_TYPES_DOUBLE], &t) && t != 0.5; i++) {
    usleep(100000);
  }
  CHECK(t == 0.5, "time: expected 0.5, got %g", t);
  CHECK(readValue(c, 1, X_NODE, &UA_TYPES[UA_TYPES_DOUBLE], &x) && x == 1.5, "x: expected 1.5, got %g", x);
  CHECK(readValue(c, 1, B_NODE, &UA_TYPES[UA_TYPES_BOOLEAN], &b) && b, "b: expected true");
  CHECK(writeValue(c, 1, X_NODE, &UA_TYPES[UA_TYPES_DOUBLE], &newX) == UA_STATUSCODE_GOOD, "Could not write x");
  CHECK(writeValue(c, 0, OMC_OPC_NODEID_RUN, &UA_TYPES[UA_TYPES_BOOLEAN], &run) == UA_STATUSCODE_GOOD, "Could not write run");

  UA_Client_disconnect(c);
  UA_Client_delete(c);
  return NULL;
}

static void realTimeSyncUpdate(DATA *data, double scaling)
{
}

int main(void)
{
  STATIC_REAL_DATA realVarsData[2] = {
    {.info = {.inputIndex = -1, .name = "x", .comment = ""}},
    {.info = {.inputIndex = -1, .name = "y", .comment = "y"}}};
  STATIC_BOOLEAN_DATA booleanVarsData[1] = {{.info = {.inputIndex = -1, .name = "b", .comment = ""}}};
  modelica_real realVars[2] = {1, 2};
  modelica_boolean booleanVars[1] = {0};
  MODEL_DATA modelData = {0};
  SIMULATION_INFO simulationInfo = {0};
  SIMULATION_DATA simulationData = {0};
  SIMULATION_DATA *localData[1] = {&simulationData};
  DATA data = {0};
  void *dll, *state;
  pthread_t thread;
  int res, terminate = 0;

  modelData.nStates = 1;
  modelData.nVariablesReal = 2;
  modelData.nVariablesBoolean = 1;
  modelData.realVarsData = realVarsData;
  modelData.booleanVarsData = booleanVarsData;
  simulationData.realVars = realVars;
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

  CHECK(res == 1, "embedded_server_update: expected 1 after a state write, got %d", res);
  CHECK(realVars[0] == 20, "x after write: expected 20, got %g", realVars[0]);
  CHECK(!terminate, "terminate was set");

  embedded_server_deinit(state);
  embedded_server_unload_functions(dll);

  printf(failed ? "Some tests failed!\n" : "All tests passed!\n");
  return failed;
}
