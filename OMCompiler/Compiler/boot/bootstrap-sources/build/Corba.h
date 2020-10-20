#ifndef Corba__H
#define Corba__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_Corba_close(threadData_t *threadData);
#define boxptr_Corba_close omc_Corba_close
static const MMC_DEFSTRUCTLIT(boxvar_lit_Corba_close,2,0) {(void*) boxptr_Corba_close,0}};
#define boxvar_Corba_close MMC_REFSTRUCTLIT(boxvar_lit_Corba_close)
extern void Corba_close();
DLLExport
void omc_Corba_sendreply(threadData_t *threadData, modelica_string _inString);
#define boxptr_Corba_sendreply omc_Corba_sendreply
static const MMC_DEFSTRUCTLIT(boxvar_lit_Corba_sendreply,2,0) {(void*) boxptr_Corba_sendreply,0}};
#define boxvar_Corba_sendreply MMC_REFSTRUCTLIT(boxvar_lit_Corba_sendreply)
extern void Corba_sendreply(const char* /*_inString*/);
DLLExport
modelica_string omc_Corba_waitForCommand(threadData_t *threadData);
#define boxptr_Corba_waitForCommand omc_Corba_waitForCommand
static const MMC_DEFSTRUCTLIT(boxvar_lit_Corba_waitForCommand,2,0) {(void*) boxptr_Corba_waitForCommand,0}};
#define boxvar_Corba_waitForCommand MMC_REFSTRUCTLIT(boxvar_lit_Corba_waitForCommand)
extern const char* Corba_waitForCommand();
DLLExport
void omc_Corba_initialize(threadData_t *threadData);
#define boxptr_Corba_initialize omc_Corba_initialize
static const MMC_DEFSTRUCTLIT(boxvar_lit_Corba_initialize,2,0) {(void*) boxptr_Corba_initialize,0}};
#define boxvar_Corba_initialize MMC_REFSTRUCTLIT(boxvar_lit_Corba_initialize)
extern void Corba_initialize();
DLLExport
void omc_Corba_setSessionName(threadData_t *threadData, modelica_string _inSessionName);
#define boxptr_Corba_setSessionName omc_Corba_setSessionName
static const MMC_DEFSTRUCTLIT(boxvar_lit_Corba_setSessionName,2,0) {(void*) boxptr_Corba_setSessionName,0}};
#define boxvar_Corba_setSessionName MMC_REFSTRUCTLIT(boxvar_lit_Corba_setSessionName)
extern void Corba_setSessionName(const char* /*_inSessionName*/);
DLLExport
void omc_Corba_setObjectReferenceFilePath(threadData_t *threadData, modelica_string _inObjectReferenceFilePath);
#define boxptr_Corba_setObjectReferenceFilePath omc_Corba_setObjectReferenceFilePath
static const MMC_DEFSTRUCTLIT(boxvar_lit_Corba_setObjectReferenceFilePath,2,0) {(void*) boxptr_Corba_setObjectReferenceFilePath,0}};
#define boxvar_Corba_setObjectReferenceFilePath MMC_REFSTRUCTLIT(boxvar_lit_Corba_setObjectReferenceFilePath)
extern void Corba_setObjectReferenceFilePath(const char* /*_inObjectReferenceFilePath*/);
DLLExport
modelica_boolean omc_Corba_haveCorba(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Corba_haveCorba(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Corba_haveCorba,2,0) {(void*) boxptr_Corba_haveCorba,0}};
#define boxvar_Corba_haveCorba MMC_REFSTRUCTLIT(boxvar_lit_Corba_haveCorba)
extern int Corba_haveCorba();
#ifdef __cplusplus
}
#endif
#endif
