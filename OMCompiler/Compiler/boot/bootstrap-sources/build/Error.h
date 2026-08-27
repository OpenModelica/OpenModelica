#ifndef Error__H
#define Error__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description ErrorTypes_Message_MESSAGE__desc;
extern struct record_description ErrorTypes_MessageType_TRANSLATION__desc;
extern struct record_description ErrorTypes_Severity_ERROR__desc;
extern struct record_description ErrorTypes_Severity_INTERNAL__desc;
extern struct record_description ErrorTypes_Severity_NOTIFICATION__desc;
extern struct record_description ErrorTypes_Severity_WARNING__desc;
extern struct record_description Flags_ConfigFlag_CONFIG__FLAG__desc;
extern struct record_description Flags_FlagData_BOOL__FLAG__desc;
extern struct record_description Flags_FlagVisibility_EXTERNAL__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
extern struct record_description Gettext_TranslatableContent_notrans__desc;
extern struct record_description SourceInfo_SOURCEINFO__desc;
DLLExport
void omc_Error_terminateError(threadData_t *threadData, modelica_string _message, modelica_metatype _info);
#define boxptr_Error_terminateError omc_Error_terminateError
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_terminateError,2,0) {(void*) boxptr_Error_terminateError,0}};
#define boxvar_Error_terminateError MMC_REFSTRUCTLIT(boxvar_lit_Error_terminateError)
DLLExport
void omc_Error_addInternalError(threadData_t *threadData, modelica_string _message, modelica_metatype _info);
#define boxptr_Error_addInternalError omc_Error_addInternalError
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addInternalError,2,0) {(void*) boxptr_Error_addInternalError,0}};
#define boxvar_Error_addInternalError MMC_REFSTRUCTLIT(boxvar_lit_Error_addInternalError)
DLLExport
void omc_Error_addCompilerNotification(threadData_t *threadData, modelica_string _message);
#define boxptr_Error_addCompilerNotification omc_Error_addCompilerNotification
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addCompilerNotification,2,0) {(void*) boxptr_Error_addCompilerNotification,0}};
#define boxvar_Error_addCompilerNotification MMC_REFSTRUCTLIT(boxvar_lit_Error_addCompilerNotification)
DLLExport
void omc_Error_addCompilerWarning(threadData_t *threadData, modelica_string _message);
#define boxptr_Error_addCompilerWarning omc_Error_addCompilerWarning
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addCompilerWarning,2,0) {(void*) boxptr_Error_addCompilerWarning,0}};
#define boxvar_Error_addCompilerWarning MMC_REFSTRUCTLIT(boxvar_lit_Error_addCompilerWarning)
DLLExport
void omc_Error_addCompilerError(threadData_t *threadData, modelica_string _message);
#define boxptr_Error_addCompilerError omc_Error_addCompilerError
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addCompilerError,2,0) {(void*) boxptr_Error_addCompilerError,0}};
#define boxvar_Error_addCompilerError MMC_REFSTRUCTLIT(boxvar_lit_Error_addCompilerError)
#define boxptr_Error_failOnErrorMsg omc_Error_failOnErrorMsg
DLLExport
void omc_Error_assertionOrAddSourceMessage(threadData_t *threadData, modelica_boolean _inCond, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens, modelica_metatype _inInfo);
DLLExport
void boxptr_Error_assertionOrAddSourceMessage(threadData_t *threadData, modelica_metatype _inCond, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_assertionOrAddSourceMessage,2,0) {(void*) boxptr_Error_assertionOrAddSourceMessage,0}};
#define boxvar_Error_assertionOrAddSourceMessage MMC_REFSTRUCTLIT(boxvar_lit_Error_assertionOrAddSourceMessage)
DLLExport
void omc_Error_assertion(threadData_t *threadData, modelica_boolean _b, modelica_string _message, modelica_metatype _info);
DLLExport
void boxptr_Error_assertion(threadData_t *threadData, modelica_metatype _b, modelica_metatype _message, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_assertion,2,0) {(void*) boxptr_Error_assertion,0}};
#define boxvar_Error_assertion MMC_REFSTRUCTLIT(boxvar_lit_Error_assertion)
DLLExport
modelica_string omc_Error_infoStr(threadData_t *threadData, modelica_metatype _info);
#define boxptr_Error_infoStr omc_Error_infoStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_infoStr,2,0) {(void*) boxptr_Error_infoStr,0}};
#define boxvar_Error_infoStr MMC_REFSTRUCTLIT(boxvar_lit_Error_infoStr)
DLLExport
modelica_string omc_Error_severityStr(threadData_t *threadData, modelica_metatype _inSeverity);
#define boxptr_Error_severityStr omc_Error_severityStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_severityStr,2,0) {(void*) boxptr_Error_severityStr,0}};
#define boxvar_Error_severityStr MMC_REFSTRUCTLIT(boxvar_lit_Error_severityStr)
DLLExport
modelica_string omc_Error_messageTypeStr(threadData_t *threadData, modelica_metatype _inMessageType);
#define boxptr_Error_messageTypeStr omc_Error_messageTypeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_messageTypeStr,2,0) {(void*) boxptr_Error_messageTypeStr,0}};
#define boxvar_Error_messageTypeStr MMC_REFSTRUCTLIT(boxvar_lit_Error_messageTypeStr)
DLLExport
modelica_string omc_Error_getMessagesStrSeverity(threadData_t *threadData, modelica_metatype _inSeverity);
#define boxptr_Error_getMessagesStrSeverity omc_Error_getMessagesStrSeverity
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_getMessagesStrSeverity,2,0) {(void*) boxptr_Error_getMessagesStrSeverity,0}};
#define boxvar_Error_getMessagesStrSeverity MMC_REFSTRUCTLIT(boxvar_lit_Error_getMessagesStrSeverity)
DLLExport
modelica_string omc_Error_getMessagesStrType(threadData_t *threadData, modelica_metatype _inMessageType);
#define boxptr_Error_getMessagesStrType omc_Error_getMessagesStrType
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_getMessagesStrType,2,0) {(void*) boxptr_Error_getMessagesStrType,0}};
#define boxvar_Error_getMessagesStrType MMC_REFSTRUCTLIT(boxvar_lit_Error_getMessagesStrType)
DLLExport
modelica_metatype omc_Error_getMessages(threadData_t *threadData);
#define boxptr_Error_getMessages omc_Error_getMessages
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_getMessages,2,0) {(void*) boxptr_Error_getMessages,0}};
#define boxvar_Error_getMessages MMC_REFSTRUCTLIT(boxvar_lit_Error_getMessages)
DLLExport
modelica_integer omc_Error_getNumErrorMessages(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Error_getNumErrorMessages(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_getNumErrorMessages,2,0) {(void*) boxptr_Error_getNumErrorMessages,0}};
#define boxvar_Error_getNumErrorMessages MMC_REFSTRUCTLIT(boxvar_lit_Error_getNumErrorMessages)
DLLExport
modelica_integer omc_Error_getNumMessages(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_Error_getNumMessages(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_getNumMessages,2,0) {(void*) boxptr_Error_getNumMessages,0}};
#define boxvar_Error_getNumMessages MMC_REFSTRUCTLIT(boxvar_lit_Error_getNumMessages)
DLLExport
void omc_Error_clearMessages(threadData_t *threadData);
#define boxptr_Error_clearMessages omc_Error_clearMessages
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_clearMessages,2,0) {(void*) boxptr_Error_clearMessages,0}};
#define boxvar_Error_clearMessages MMC_REFSTRUCTLIT(boxvar_lit_Error_clearMessages)
DLLExport
modelica_metatype omc_Error_printMessagesStrLstSeverity(threadData_t *threadData, modelica_metatype _inSeverity);
#define boxptr_Error_printMessagesStrLstSeverity omc_Error_printMessagesStrLstSeverity
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_printMessagesStrLstSeverity,2,0) {(void*) boxptr_Error_printMessagesStrLstSeverity,0}};
#define boxvar_Error_printMessagesStrLstSeverity MMC_REFSTRUCTLIT(boxvar_lit_Error_printMessagesStrLstSeverity)
DLLExport
modelica_metatype omc_Error_printMessagesStrLstType(threadData_t *threadData, modelica_metatype _inMessageType);
#define boxptr_Error_printMessagesStrLstType omc_Error_printMessagesStrLstType
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_printMessagesStrLstType,2,0) {(void*) boxptr_Error_printMessagesStrLstType,0}};
#define boxvar_Error_printMessagesStrLstType MMC_REFSTRUCTLIT(boxvar_lit_Error_printMessagesStrLstType)
DLLExport
modelica_metatype omc_Error_printMessagesStrLst(threadData_t *threadData);
#define boxptr_Error_printMessagesStrLst omc_Error_printMessagesStrLst
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_printMessagesStrLst,2,0) {(void*) boxptr_Error_printMessagesStrLst,0}};
#define boxvar_Error_printMessagesStrLst MMC_REFSTRUCTLIT(boxvar_lit_Error_printMessagesStrLst)
DLLExport
modelica_string omc_Error_printErrorsNoWarning(threadData_t *threadData);
#define boxptr_Error_printErrorsNoWarning omc_Error_printErrorsNoWarning
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_printErrorsNoWarning,2,0) {(void*) boxptr_Error_printErrorsNoWarning,0}};
#define boxvar_Error_printErrorsNoWarning MMC_REFSTRUCTLIT(boxvar_lit_Error_printErrorsNoWarning)
DLLExport
modelica_string omc_Error_printMessagesStr(threadData_t *threadData, modelica_boolean _warningsAsErrors);
DLLExport
modelica_metatype boxptr_Error_printMessagesStr(threadData_t *threadData, modelica_metatype _warningsAsErrors);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_printMessagesStr,2,0) {(void*) boxptr_Error_printMessagesStr,0}};
#define boxvar_Error_printMessagesStr MMC_REFSTRUCTLIT(boxvar_lit_Error_printMessagesStr)
DLLExport
void omc_Error_addTotalMessages(threadData_t *threadData, modelica_metatype _messages);
#define boxptr_Error_addTotalMessages omc_Error_addTotalMessages
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addTotalMessages,2,0) {(void*) boxptr_Error_addTotalMessages,0}};
#define boxvar_Error_addTotalMessages MMC_REFSTRUCTLIT(boxvar_lit_Error_addTotalMessages)
DLLExport
void omc_Error_addTotalMessage(threadData_t *threadData, modelica_metatype _message);
#define boxptr_Error_addTotalMessage omc_Error_addTotalMessage
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addTotalMessage,2,0) {(void*) boxptr_Error_addTotalMessage,0}};
#define boxvar_Error_addTotalMessage MMC_REFSTRUCTLIT(boxvar_lit_Error_addTotalMessage)
DLLExport
void omc_Error_addMessageOrSourceMessage(threadData_t *threadData, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens, modelica_metatype _inInfoOpt);
#define boxptr_Error_addMessageOrSourceMessage omc_Error_addMessageOrSourceMessage
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addMessageOrSourceMessage,2,0) {(void*) boxptr_Error_addMessageOrSourceMessage,0}};
#define boxvar_Error_addMessageOrSourceMessage MMC_REFSTRUCTLIT(boxvar_lit_Error_addMessageOrSourceMessage)
DLLExport
void omc_Error_addMultiSourceMessage(threadData_t *threadData, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens, modelica_metatype _inInfo);
#define boxptr_Error_addMultiSourceMessage omc_Error_addMultiSourceMessage
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addMultiSourceMessage,2,0) {(void*) boxptr_Error_addMultiSourceMessage,0}};
#define boxvar_Error_addMultiSourceMessage MMC_REFSTRUCTLIT(boxvar_lit_Error_addMultiSourceMessage)
DLLExport
void omc_Error_addSourceMessageAndFail(threadData_t *threadData, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens, modelica_metatype _inInfo);
#define boxptr_Error_addSourceMessageAndFail omc_Error_addSourceMessageAndFail
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addSourceMessageAndFail,2,0) {(void*) boxptr_Error_addSourceMessageAndFail,0}};
#define boxvar_Error_addSourceMessageAndFail MMC_REFSTRUCTLIT(boxvar_lit_Error_addSourceMessageAndFail)
DLLExport
void omc_Error_addStrictMessage(threadData_t *threadData, modelica_metatype _errorMsg, modelica_metatype _tokens, modelica_metatype _info);
#define boxptr_Error_addStrictMessage omc_Error_addStrictMessage
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addStrictMessage,2,0) {(void*) boxptr_Error_addStrictMessage,0}};
#define boxvar_Error_addStrictMessage MMC_REFSTRUCTLIT(boxvar_lit_Error_addStrictMessage)
DLLExport
void omc_Error_addSourceMessageAsError(threadData_t *threadData, modelica_metatype _msg, modelica_metatype _tokens, modelica_metatype _info);
#define boxptr_Error_addSourceMessageAsError omc_Error_addSourceMessageAsError
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addSourceMessageAsError,2,0) {(void*) boxptr_Error_addSourceMessageAsError,0}};
#define boxvar_Error_addSourceMessageAsError MMC_REFSTRUCTLIT(boxvar_lit_Error_addSourceMessageAsError)
DLLExport
void omc_Error_addSourceMessage(threadData_t *threadData, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens, modelica_metatype _inInfo);
#define boxptr_Error_addSourceMessage omc_Error_addSourceMessage
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addSourceMessage,2,0) {(void*) boxptr_Error_addSourceMessage,0}};
#define boxvar_Error_addSourceMessage MMC_REFSTRUCTLIT(boxvar_lit_Error_addSourceMessage)
DLLExport
void omc_Error_addMessage(threadData_t *threadData, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens);
#define boxptr_Error_addMessage omc_Error_addMessage
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_addMessage,2,0) {(void*) boxptr_Error_addMessage,0}};
#define boxvar_Error_addMessage MMC_REFSTRUCTLIT(boxvar_lit_Error_addMessage)
DLLExport
modelica_string omc_Error_getCurrentComponent(threadData_t *threadData, modelica_integer *out_sline, modelica_integer *out_scol, modelica_integer *out_eline, modelica_integer *out_ecol, modelica_boolean *out_read_only, modelica_string *out_filename);
DLLExport
modelica_metatype boxptr_Error_getCurrentComponent(threadData_t *threadData, modelica_metatype *out_sline, modelica_metatype *out_scol, modelica_metatype *out_eline, modelica_metatype *out_ecol, modelica_metatype *out_read_only, modelica_metatype *out_filename);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_getCurrentComponent,2,0) {(void*) boxptr_Error_getCurrentComponent,0}};
#define boxvar_Error_getCurrentComponent MMC_REFSTRUCTLIT(boxvar_lit_Error_getCurrentComponent)
DLLExport
void omc_Error_updateCurrentComponent(threadData_t *threadData, modelica_metatype _cpre, modelica_string _component, modelica_metatype _info, modelica_fnptr _func);
#define boxptr_Error_updateCurrentComponent omc_Error_updateCurrentComponent
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_updateCurrentComponent,2,0) {(void*) boxptr_Error_updateCurrentComponent,0}};
#define boxvar_Error_updateCurrentComponent MMC_REFSTRUCTLIT(boxvar_lit_Error_updateCurrentComponent)
DLLExport
void omc_Error_clearCurrentComponent(threadData_t *threadData);
#define boxptr_Error_clearCurrentComponent omc_Error_clearCurrentComponent
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_clearCurrentComponent,2,0) {(void*) boxptr_Error_clearCurrentComponent,0}};
#define boxvar_Error_clearCurrentComponent MMC_REFSTRUCTLIT(boxvar_lit_Error_clearCurrentComponent)
#ifdef __cplusplus
}
#endif
#endif
