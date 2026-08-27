#ifndef Socket__H
#define Socket__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_Socket_cleanup(threadData_t *threadData);
#define boxptr_Socket_cleanup omc_Socket_cleanup
static const MMC_DEFSTRUCTLIT(boxvar_lit_Socket_cleanup,2,0) {(void*) boxptr_Socket_cleanup,0}};
#define boxvar_Socket_cleanup MMC_REFSTRUCTLIT(boxvar_lit_Socket_cleanup)
extern void Socket_cleanup();
DLLExport
void omc_Socket_close(threadData_t *threadData, modelica_integer _inInteger);
DLLExport
void boxptr_Socket_close(threadData_t *threadData, modelica_metatype _inInteger);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Socket_close,2,0) {(void*) boxptr_Socket_close,0}};
#define boxvar_Socket_close MMC_REFSTRUCTLIT(boxvar_lit_Socket_close)
extern void Socket_close(int /*_inInteger*/);
DLLExport
void omc_Socket_sendreply(threadData_t *threadData, modelica_integer _inInteger, modelica_string _inString);
DLLExport
void boxptr_Socket_sendreply(threadData_t *threadData, modelica_metatype _inInteger, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Socket_sendreply,2,0) {(void*) boxptr_Socket_sendreply,0}};
#define boxvar_Socket_sendreply MMC_REFSTRUCTLIT(boxvar_lit_Socket_sendreply)
extern void Socket_sendreply(int /*_inInteger*/, const char* /*_inString*/);
DLLExport
modelica_string omc_Socket_handlerequest(threadData_t *threadData, modelica_integer _inInteger);
DLLExport
modelica_metatype boxptr_Socket_handlerequest(threadData_t *threadData, modelica_metatype _inInteger);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Socket_handlerequest,2,0) {(void*) boxptr_Socket_handlerequest,0}};
#define boxvar_Socket_handlerequest MMC_REFSTRUCTLIT(boxvar_lit_Socket_handlerequest)
extern const char* Socket_handlerequest(int /*_inInteger*/);
DLLExport
modelica_integer omc_Socket_waitforconnect(threadData_t *threadData, modelica_integer _inInteger);
DLLExport
modelica_metatype boxptr_Socket_waitforconnect(threadData_t *threadData, modelica_metatype _inInteger);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Socket_waitforconnect,2,0) {(void*) boxptr_Socket_waitforconnect,0}};
#define boxvar_Socket_waitforconnect MMC_REFSTRUCTLIT(boxvar_lit_Socket_waitforconnect)
extern int Socket_waitforconnect(int /*_inInteger*/);
#ifdef __cplusplus
}
#endif
#endif
