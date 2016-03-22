#include <stdio.h>
#include <unistd.h>

#include "open62541.h"
#include "omc_opc_ua.h"

static int doStep=1;

double readReal(UA_Client *client, int id)
{
  double res=0;
  UA_ReadRequest rReq;
  UA_ReadRequest_init(&rReq);
  rReq.nodesToRead = UA_Array_new(1, &UA_TYPES[UA_TYPES_READVALUEID]);
  rReq.nodesToReadSize = 1;
  rReq.nodesToRead[0].nodeId = UA_NODEID_NUMERIC(1, id);
  rReq.nodesToRead[0].attributeId = UA_ATTRIBUTEID_VALUE;

  UA_ReadResponse rResp = UA_Client_Service_read(client, rReq);
  if(rResp.responseHeader.serviceResult == UA_STATUSCODE_GOOD &&
          rResp.resultsSize > 0 && rResp.results[0].hasValue &&
          UA_Variant_isScalar(&rResp.results[0].value) &&
          rResp.results[0].value.type == &UA_TYPES[UA_TYPES_DOUBLE]) {
    res = *(UA_Double*)rResp.results[0].value.data;
  }
  UA_ReadRequest_deleteMembers(&rReq);
  UA_ReadResponse_deleteMembers(&rResp);
  return res;
}

int readBoolean(UA_Client *client, int id)
{
  int res=0;
  UA_ReadRequest rReq;
  UA_ReadRequest_init(&rReq);
  rReq.nodesToRead = UA_Array_new(1, &UA_TYPES[UA_TYPES_READVALUEID]);
  rReq.nodesToReadSize = 1;
  rReq.nodesToRead[0].nodeId = UA_NODEID_NUMERIC(0, id);
  rReq.nodesToRead[0].attributeId = UA_ATTRIBUTEID_VALUE;

  UA_ReadResponse rResp = UA_Client_Service_read(client, rReq);
  if(rResp.responseHeader.serviceResult == UA_STATUSCODE_GOOD &&
          rResp.resultsSize > 0 && rResp.results[0].hasValue &&
          UA_Variant_isScalar(&rResp.results[0].value) &&
          rResp.results[0].value.type == &UA_TYPES[UA_TYPES_BOOLEAN]) {
    res = *(UA_Boolean*)rResp.results[0].value.data;
  }
  UA_ReadRequest_deleteMembers(&rReq);
  UA_ReadResponse_deleteMembers(&rResp);
  return res;
}

int writeBoolean(UA_Client *client, int id, UA_Boolean val)
{
  int res=0;
  UA_WriteRequest wReq;
  UA_WriteRequest_init(&wReq);
  wReq.nodesToWrite = UA_WriteValue_new();
  wReq.nodesToWriteSize = 1;
  wReq.nodesToWrite[0].nodeId = UA_NODEID_NUMERIC(0, id);
  wReq.nodesToWrite[0].attributeId = UA_ATTRIBUTEID_VALUE;
  wReq.nodesToWrite[0].value.hasValue = UA_TRUE;
  wReq.nodesToWrite[0].value.value.type = &UA_TYPES[UA_TYPES_BOOLEAN];
  wReq.nodesToWrite[0].value.value.storageType = UA_VARIANT_DATA_NODELETE;
  wReq.nodesToWrite[0].value.value.data = &val;

  UA_WriteResponse wResp = UA_Client_Service_write(client, wReq);
  if (wResp.responseHeader.serviceResult == UA_STATUSCODE_GOOD) {
    res = 1;
  }
  UA_WriteRequest_deleteMembers(&wReq);
  UA_WriteResponse_deleteMembers(&wResp);

  return res;
}

int writeReal(UA_Client *client, int id, UA_Double val)
{
  int res=0;
  UA_WriteRequest wReq;
  UA_WriteRequest_init(&wReq);
  wReq.nodesToWrite = UA_WriteValue_new();
  wReq.nodesToWriteSize = 1;
  wReq.nodesToWrite[0].nodeId = UA_NODEID_NUMERIC(1, id);
  wReq.nodesToWrite[0].attributeId = UA_ATTRIBUTEID_VALUE;
  wReq.nodesToWrite[0].value.hasValue = UA_TRUE;
  wReq.nodesToWrite[0].value.value.type = &UA_TYPES[UA_TYPES_DOUBLE];
  wReq.nodesToWrite[0].value.value.storageType = UA_VARIANT_DATA_NODELETE;
  wReq.nodesToWrite[0].value.value.data = &val;

  UA_WriteResponse wResp = UA_Client_Service_write(client, wReq);
  if (wResp.responseHeader.serviceResult == UA_STATUSCODE_GOOD) {
    res = 1;
  }
  UA_WriteRequest_deleteMembers(&wReq);
  UA_WriteResponse_deleteMembers(&wResp);

  return res;
}

static void timeChanged(UA_UInt32 handle, UA_DataValue *value, void *client) {
  static int nsteps = 0;
  if (value->hasValue) {
    printf("The time has changed! %.4g client=%p\n", *(UA_Double*)value->value.data, client);
  }
  nsteps++;
  if (nsteps==3) {
    int id = VARKIND_REAL*MAX_VARS_KIND;
    if (1!=writeReal(client, id, 20.0)) {
      printf("Writing to var %d failed\n", id);
    } else {
      printf("Wrote 20.0 to var %d\n", id);
    }
  } else if (nsteps==13) {
    // exit(1);
  }
  if (doStep && 1!=writeBoolean(client, OMC_OPC_NODEID_STEP, UA_TRUE)) {
    printf("Writing to NODEID_STEP failed\n");
  }
  return;
}

static void realChanged(UA_UInt32 handle, UA_DataValue *value, void *client) {
  if (value->hasValue) {
    printf("The value of %d has changed! %.4g client=%p\n", handle, *(UA_Double*)value->value.data, client);
  }
  return;
}

static void stepChanged(UA_UInt32 handle, UA_DataValue *value, void *client) {
  if (value->hasValue) {
    printf("The step has changed! %d\n", *(UA_Boolean*)value->value.data);
  }
  return;
}

int main(void) {
  int i;
  UA_Client *client = UA_Client_new(UA_ClientConfig_standard, Logger_Stdout);
  UA_StatusCode retval = UA_Client_connect(client, UA_ClientConnectionTCP,
                                           "opc.tcp://localhost:4841");
  if (retval != UA_STATUSCODE_GOOD) {
    UA_Client_delete(client);
    return retval;
  }

    // Create a subscription with interval 0 (immediate)...
    UA_UInt32 subId;
    UA_SubscriptionSettings subSettings = UA_SubscriptionSettings_standard;
    subSettings.requestedPublishingInterval = 5;
    UA_Client_Subscriptions_new(client, subSettings, &subId);
    if (subId) {
        printf("Create subscription succeeded, id %u\n", subId);
    }

    // .. and monitor TheAnswer
    UA_NodeId monitorTime = UA_NODEID_NUMERIC(0, OMC_OPC_NODEID_TIME);
    UA_NodeId monitorStep = UA_NODEID_NUMERIC(0, OMC_OPC_NODEID_STEP);
    UA_NodeId monitorVar1 = UA_NODEID_NUMERIC(1, VARKIND_REAL*MAX_VARS_KIND);
    UA_NodeId monitorVar2 = UA_NODEID_NUMERIC(1, VARKIND_REAL*MAX_VARS_KIND+1);
    UA_NodeId monitorVar3 = UA_NODEID_NUMERIC(1, VARKIND_REAL*MAX_VARS_KIND+2);
    UA_UInt32 monId1=1,monId2=2,monId3=3,monId4=4,monId5=5;
    UA_Client_Subscriptions_addMonitoredItem(client, subId, monitorTime,
                                             UA_ATTRIBUTEID_VALUE, &timeChanged, client, &monId1);
    UA_Client_Subscriptions_addMonitoredItem(client, subId, monitorStep,
                                             UA_ATTRIBUTEID_VALUE, &stepChanged, client, &monId2);
    UA_Client_Subscriptions_addMonitoredItem(client, subId, monitorVar1,
                                             UA_ATTRIBUTEID_VALUE, &realChanged, client, &monId3);
    UA_Client_Subscriptions_addMonitoredItem(client, subId, monitorVar2,
                                             UA_ATTRIBUTEID_VALUE, &realChanged, client, &monId4);
    UA_Client_Subscriptions_addMonitoredItem(client, subId, monitorVar3,
                                             UA_ATTRIBUTEID_VALUE, &realChanged, client, &monId5);
    if (monId1) {
        printf("Monitoring 'time', id %u\n", monId1);
    }
    if (monId2) {
        printf("Monitoring 'step', id %u\n", monId2);
    }
    if (monId3) {
        printf("Monitoring var1, id %u\n", monId3);
    }
    if (monId4) {
        printf("Monitoring var2, id %u\n", monId4);
    }

    // First Publish always generates data (current value) and call out handler.
    UA_Client_Subscriptions_manuallySendPublishRequest(client);

    // This should not generate anything
    UA_Client_Subscriptions_manuallySendPublishRequest(client);

  printf("step is: %d\n", readBoolean(client, OMC_OPC_NODEID_STEP));

  for (int i=0; i<100; i++) {
    // TODO: Figure out if simulation crashed :)
    UA_Client_Subscriptions_manuallySendPublishRequest(client);
    usleep(100);
    // printf("time=%.5g\n", readReal(client, OMC_OPC_NODEID_TIME));
  }

  doStep=0;
  fprintf(stderr, "Pause\n");

  for (int i=0; i<10000; i++) {
    // TODO: Figure out if simulation crashed :)
    UA_Client_Subscriptions_manuallySendPublishRequest(client);
    usleep(100);
    // printf("time=%.5g\n", readReal(client, OMC_OPC_NODEID_TIME));
  }

  fprintf(stderr, "Do run\n");
  writeBoolean(client, OMC_OPC_NODEID_RUN, UA_TRUE);

  for (int i=0; i<10000; i++) {
    // TODO: Figure out if simulation crashed :)
    UA_Client_Subscriptions_manuallySendPublishRequest(client);
    usleep(100);
    // printf("time=%.5g\n", readReal(client, OMC_OPC_NODEID_TIME));
  }

  UA_Client_disconnect(client);
  UA_Client_delete(client);
  return UA_STATUSCODE_GOOD;
}
