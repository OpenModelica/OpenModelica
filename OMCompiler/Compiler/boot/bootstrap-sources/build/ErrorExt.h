#ifndef ErrorExt__H
#define ErrorExt__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_ErrorExt_initAssertionFunctions(threadData_t *threadData);
#define boxptr_ErrorExt_initAssertionFunctions omc_ErrorExt_initAssertionFunctions
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_initAssertionFunctions,2,0) {(void*) boxptr_ErrorExt_initAssertionFunctions,0}};
#define boxvar_ErrorExt_initAssertionFunctions MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_initAssertionFunctions)
extern void Error_initAssertionFunctions();
DLLExport
void omc_ErrorExt_moveMessagesToParentThread(threadData_t *threadData);
#define boxptr_ErrorExt_moveMessagesToParentThread omc_ErrorExt_moveMessagesToParentThread
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_moveMessagesToParentThread,2,0) {(void*) boxptr_ErrorExt_moveMessagesToParentThread,0}};
#define boxvar_ErrorExt_moveMessagesToParentThread MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_moveMessagesToParentThread)
extern void Error_moveMessagesToParentThread(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_ErrorExt_setShowErrorMessages(threadData_t *threadData, modelica_boolean _inShow);
DLLExport
void boxptr_ErrorExt_setShowErrorMessages(threadData_t *threadData, modelica_metatype _inShow);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_setShowErrorMessages,2,0) {(void*) boxptr_ErrorExt_setShowErrorMessages,0}};
#define boxvar_ErrorExt_setShowErrorMessages MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_setShowErrorMessages)
extern void Error_setShowErrorMessages(OpenModelica_threadData_ThreadData*, int /*_inShow*/);
DLLExport
modelica_boolean omc_ErrorExt_isTopCheckpoint(threadData_t *threadData, modelica_string _id);
DLLExport
modelica_metatype boxptr_ErrorExt_isTopCheckpoint(threadData_t *threadData, modelica_metatype _id);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_isTopCheckpoint,2,0) {(void*) boxptr_ErrorExt_isTopCheckpoint,0}};
#define boxvar_ErrorExt_isTopCheckpoint MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_isTopCheckpoint)
extern int ErrorImpl__isTopCheckpoint(OpenModelica_threadData_ThreadData*, const char* /*_id*/);
DLLExport
void omc_ErrorExt_freeMessages(threadData_t *threadData, modelica_metatype _handles);
#define boxptr_ErrorExt_freeMessages omc_ErrorExt_freeMessages
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_freeMessages,2,0) {(void*) boxptr_ErrorExt_freeMessages,0}};
#define boxvar_ErrorExt_freeMessages MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_freeMessages)
extern void ErrorImpl__freeMessages(OpenModelica_threadData_ThreadData*, modelica_metatype /*_handles*/);
DLLExport
void omc_ErrorExt_pushMessages(threadData_t *threadData, modelica_metatype _handles);
#define boxptr_ErrorExt_pushMessages omc_ErrorExt_pushMessages
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_pushMessages,2,0) {(void*) boxptr_ErrorExt_pushMessages,0}};
#define boxvar_ErrorExt_pushMessages MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_pushMessages)
extern void ErrorImpl__pushMessages(OpenModelica_threadData_ThreadData*, modelica_metatype /*_handles*/);
DLLExport
modelica_metatype omc_ErrorExt_popCheckPoint(threadData_t *threadData, modelica_string _id);
#define boxptr_ErrorExt_popCheckPoint omc_ErrorExt_popCheckPoint
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_popCheckPoint,2,0) {(void*) boxptr_ErrorExt_popCheckPoint,0}};
#define boxvar_ErrorExt_popCheckPoint MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_popCheckPoint)
extern modelica_metatype ErrorImpl__pop(OpenModelica_threadData_ThreadData*, const char* /*_id*/);
DLLExport
void omc_ErrorExt_rollBack(threadData_t *threadData, modelica_string _id);
#define boxptr_ErrorExt_rollBack omc_ErrorExt_rollBack
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_rollBack,2,0) {(void*) boxptr_ErrorExt_rollBack,0}};
#define boxvar_ErrorExt_rollBack MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_rollBack)
extern void ErrorImpl__rollBack(OpenModelica_threadData_ThreadData*, const char* /*_id*/);
DLLExport
modelica_string omc_ErrorExt_printErrorsNoWarning(threadData_t *threadData);
#define boxptr_ErrorExt_printErrorsNoWarning omc_ErrorExt_printErrorsNoWarning
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_printErrorsNoWarning,2,0) {(void*) boxptr_ErrorExt_printErrorsNoWarning,0}};
#define boxvar_ErrorExt_printErrorsNoWarning MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_printErrorsNoWarning)
extern const char* Error_printErrorsNoWarning(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_ErrorExt_delCheckpoint(threadData_t *threadData, modelica_string _id);
#define boxptr_ErrorExt_delCheckpoint omc_ErrorExt_delCheckpoint
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_delCheckpoint,2,0) {(void*) boxptr_ErrorExt_delCheckpoint,0}};
#define boxvar_ErrorExt_delCheckpoint MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_delCheckpoint)
extern void ErrorImpl__delCheckpoint(OpenModelica_threadData_ThreadData*, const char* /*_id*/);
DLLExport
void omc_ErrorExt_setCheckpoint(threadData_t *threadData, modelica_string _id);
#define boxptr_ErrorExt_setCheckpoint omc_ErrorExt_setCheckpoint
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_setCheckpoint,2,0) {(void*) boxptr_ErrorExt_setCheckpoint,0}};
#define boxvar_ErrorExt_setCheckpoint MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_setCheckpoint)
extern void ErrorImpl__setCheckpoint(OpenModelica_threadData_ThreadData*, const char* /*_id*/);
DLLExport
void omc_ErrorExt_deleteNumCheckpoints(threadData_t *threadData, modelica_integer _n);
DLLExport
void boxptr_ErrorExt_deleteNumCheckpoints(threadData_t *threadData, modelica_metatype _n);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_deleteNumCheckpoints,2,0) {(void*) boxptr_ErrorExt_deleteNumCheckpoints,0}};
#define boxvar_ErrorExt_deleteNumCheckpoints MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_deleteNumCheckpoints)
extern void ErrorImpl__deleteNumCheckpoints(OpenModelica_threadData_ThreadData*, int /*_n*/);
DLLExport
void omc_ErrorExt_rollbackNumCheckpoints(threadData_t *threadData, modelica_integer _n);
DLLExport
void boxptr_ErrorExt_rollbackNumCheckpoints(threadData_t *threadData, modelica_metatype _n);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_rollbackNumCheckpoints,2,0) {(void*) boxptr_ErrorExt_rollbackNumCheckpoints,0}};
#define boxvar_ErrorExt_rollbackNumCheckpoints MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_rollbackNumCheckpoints)
extern void ErrorImpl__rollbackNumCheckpoints(OpenModelica_threadData_ThreadData*, int /*_n*/);
DLLExport
modelica_integer omc_ErrorExt_getNumCheckpoints(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_ErrorExt_getNumCheckpoints(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_getNumCheckpoints,2,0) {(void*) boxptr_ErrorExt_getNumCheckpoints,0}};
#define boxvar_ErrorExt_getNumCheckpoints MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_getNumCheckpoints)
extern int ErrorImpl__getNumCheckpoints(OpenModelica_threadData_ThreadData*);
DLLExport
void omc_ErrorExt_clearMessages(threadData_t *threadData);
#define boxptr_ErrorExt_clearMessages omc_ErrorExt_clearMessages
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_clearMessages,2,0) {(void*) boxptr_ErrorExt_clearMessages,0}};
#define boxvar_ErrorExt_clearMessages MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_clearMessages)
extern void ErrorImpl__clearMessages(OpenModelica_threadData_ThreadData*);
DLLExport
modelica_metatype omc_ErrorExt_getCheckpointMessages(threadData_t *threadData);
#define boxptr_ErrorExt_getCheckpointMessages omc_ErrorExt_getCheckpointMessages
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_getCheckpointMessages,2,0) {(void*) boxptr_ErrorExt_getCheckpointMessages,0}};
#define boxvar_ErrorExt_getCheckpointMessages MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_getCheckpointMessages)
extern modelica_metatype ErrorImpl__getCheckpointMessages(OpenModelica_threadData_ThreadData*);
DLLExport
modelica_metatype omc_ErrorExt_getMessages(threadData_t *threadData);
#define boxptr_ErrorExt_getMessages omc_ErrorExt_getMessages
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_getMessages,2,0) {(void*) boxptr_ErrorExt_getMessages,0}};
#define boxvar_ErrorExt_getMessages MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_getMessages)
extern modelica_metatype Error_getMessages(OpenModelica_threadData_ThreadData*);
DLLExport
modelica_integer omc_ErrorExt_getNumWarningMessages(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_ErrorExt_getNumWarningMessages(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_getNumWarningMessages,2,0) {(void*) boxptr_ErrorExt_getNumWarningMessages,0}};
#define boxvar_ErrorExt_getNumWarningMessages MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_getNumWarningMessages)
extern int ErrorImpl__getNumWarningMessages(OpenModelica_threadData_ThreadData*);
DLLExport
modelica_integer omc_ErrorExt_getNumErrorMessages(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_ErrorExt_getNumErrorMessages(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_getNumErrorMessages,2,0) {(void*) boxptr_ErrorExt_getNumErrorMessages,0}};
#define boxvar_ErrorExt_getNumErrorMessages MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_getNumErrorMessages)
extern int ErrorImpl__getNumErrorMessages(OpenModelica_threadData_ThreadData*);
DLLExport
modelica_integer omc_ErrorExt_getNumMessages(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_ErrorExt_getNumMessages(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_getNumMessages,2,0) {(void*) boxptr_ErrorExt_getNumMessages,0}};
#define boxvar_ErrorExt_getNumMessages MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_getNumMessages)
extern int Error_getNumMessages(OpenModelica_threadData_ThreadData*);
DLLExport
modelica_string omc_ErrorExt_printMessagesStr(threadData_t *threadData, modelica_boolean _warningsAsErrors);
DLLExport
modelica_metatype boxptr_ErrorExt_printMessagesStr(threadData_t *threadData, modelica_metatype _warningsAsErrors);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_printMessagesStr,2,0) {(void*) boxptr_ErrorExt_printMessagesStr,0}};
#define boxvar_ErrorExt_printMessagesStr MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_printMessagesStr)
extern const char* Error_printMessagesStr(OpenModelica_threadData_ThreadData*, int /*_warningsAsErrors*/);
DLLExport
void omc_ErrorExt_addSourceMessage(threadData_t *threadData, modelica_integer _id, modelica_metatype _msg_type, modelica_metatype _msg_severity, modelica_integer _sline, modelica_integer _scol, modelica_integer _eline, modelica_integer _ecol, modelica_boolean _read_only, modelica_string _filename, modelica_string _msg, modelica_metatype _tokens);
DLLExport
void boxptr_ErrorExt_addSourceMessage(threadData_t *threadData, modelica_metatype _id, modelica_metatype _msg_type, modelica_metatype _msg_severity, modelica_metatype _sline, modelica_metatype _scol, modelica_metatype _eline, modelica_metatype _ecol, modelica_metatype _read_only, modelica_metatype _filename, modelica_metatype _msg, modelica_metatype _tokens);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_addSourceMessage,2,0) {(void*) boxptr_ErrorExt_addSourceMessage,0}};
#define boxvar_ErrorExt_addSourceMessage MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_addSourceMessage)
extern void Error_addSourceMessage(OpenModelica_threadData_ThreadData*, int /*_id*/, modelica_metatype /*_msg_type*/, modelica_metatype /*_msg_severity*/, int /*_sline*/, int /*_scol*/, int /*_eline*/, int /*_ecol*/, int /*_read_only*/, const char* /*_filename*/, const char* /*_msg*/, modelica_metatype /*_tokens*/);
DLLExport
void omc_ErrorExt_registerModelicaFormatError(threadData_t *threadData);
#define boxptr_ErrorExt_registerModelicaFormatError omc_ErrorExt_registerModelicaFormatError
static const MMC_DEFSTRUCTLIT(boxvar_lit_ErrorExt_registerModelicaFormatError,2,0) {(void*) boxptr_ErrorExt_registerModelicaFormatError,0}};
#define boxvar_ErrorExt_registerModelicaFormatError MMC_REFSTRUCTLIT(boxvar_lit_ErrorExt_registerModelicaFormatError)
extern void Error_registerModelicaFormatError();
#ifdef __cplusplus
}
#endif
#endif
