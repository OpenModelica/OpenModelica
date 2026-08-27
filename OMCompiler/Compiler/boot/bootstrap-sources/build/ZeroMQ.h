#ifndef ZeroMQ__H
#define ZeroMQ__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_ZeroMQ_close(threadData_t *threadData, modelica_metatype _zmqSocket);
#define boxptr_ZeroMQ_close omc_ZeroMQ_close
static const MMC_DEFSTRUCTLIT(boxvar_lit_ZeroMQ_close,2,0) {(void*) boxptr_ZeroMQ_close,0}};
#define boxvar_ZeroMQ_close MMC_REFSTRUCTLIT(boxvar_lit_ZeroMQ_close)
extern void ZeroMQ_close(modelica_metatype /*_zmqSocket*/);
DLLExport
void omc_ZeroMQ_sendReply(threadData_t *threadData, modelica_metatype _zmqSocket, modelica_string _reply);
#define boxptr_ZeroMQ_sendReply omc_ZeroMQ_sendReply
static const MMC_DEFSTRUCTLIT(boxvar_lit_ZeroMQ_sendReply,2,0) {(void*) boxptr_ZeroMQ_sendReply,0}};
#define boxvar_ZeroMQ_sendReply MMC_REFSTRUCTLIT(boxvar_lit_ZeroMQ_sendReply)
extern void ZeroMQ_sendReply(modelica_metatype /*_zmqSocket*/, const char* /*_reply*/);
DLLExport
modelica_string omc_ZeroMQ_handleRequest(threadData_t *threadData, modelica_metatype _zmqSocket);
#define boxptr_ZeroMQ_handleRequest omc_ZeroMQ_handleRequest
static const MMC_DEFSTRUCTLIT(boxvar_lit_ZeroMQ_handleRequest,2,0) {(void*) boxptr_ZeroMQ_handleRequest,0}};
#define boxvar_ZeroMQ_handleRequest MMC_REFSTRUCTLIT(boxvar_lit_ZeroMQ_handleRequest)
extern const char* ZeroMQ_handleRequest(modelica_metatype /*_zmqSocket*/);
DLLExport
modelica_metatype omc_ZeroMQ_initialize(threadData_t *threadData, modelica_string _fileSuffix, modelica_boolean _listenToAll, modelica_integer _port);
DLLExport
modelica_metatype boxptr_ZeroMQ_initialize(threadData_t *threadData, modelica_metatype _fileSuffix, modelica_metatype _listenToAll, modelica_metatype _port);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ZeroMQ_initialize,2,0) {(void*) boxptr_ZeroMQ_initialize,0}};
#define boxvar_ZeroMQ_initialize MMC_REFSTRUCTLIT(boxvar_lit_ZeroMQ_initialize)
extern modelica_metatype ZeroMQ_initialize(const char* /*_fileSuffix*/, int /*_listenToAll*/, int /*_port*/);
#ifdef __cplusplus
}
#endif
#endif
