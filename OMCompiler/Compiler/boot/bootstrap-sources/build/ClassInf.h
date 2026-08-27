#ifndef ClassInf__H
#define ClassInf__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Absyn_Path_IDENT__desc;
extern struct record_description ClassInf_State_BLOCK__desc;
extern struct record_description ClassInf_State_CONNECTOR__desc;
extern struct record_description ClassInf_State_ENUMERATION__desc;
extern struct record_description ClassInf_State_FUNCTION__desc;
extern struct record_description ClassInf_State_HAS__RESTRICTIONS__desc;
extern struct record_description ClassInf_State_META__RECORD__desc;
extern struct record_description ClassInf_State_META__UNIONTYPE__desc;
extern struct record_description ClassInf_State_MODEL__desc;
extern struct record_description ClassInf_State_OPTIMIZATION__desc;
extern struct record_description ClassInf_State_PACKAGE__desc;
extern struct record_description ClassInf_State_RECORD__desc;
extern struct record_description ClassInf_State_TYPE__desc;
extern struct record_description ClassInf_State_TYPE__BOOL__desc;
extern struct record_description ClassInf_State_TYPE__CLOCK__desc;
extern struct record_description ClassInf_State_TYPE__ENUM__desc;
extern struct record_description ClassInf_State_TYPE__INTEGER__desc;
extern struct record_description ClassInf_State_TYPE__REAL__desc;
extern struct record_description ClassInf_State_TYPE__STRING__desc;
extern struct record_description ClassInf_State_UNKNOWN__desc;
extern struct record_description ErrorTypes_Message_MESSAGE__desc;
extern struct record_description ErrorTypes_MessageType_TRANSLATION__desc;
extern struct record_description ErrorTypes_Severity_ERROR__desc;
extern struct record_description Flags_DebugFlag_DEBUG__FLAG__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
DLLExport
modelica_boolean omc_ClassInf_isMetaRecord(threadData_t *threadData, modelica_metatype _inState);
DLLExport
modelica_metatype boxptr_ClassInf_isMetaRecord(threadData_t *threadData, modelica_metatype _inState);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_isMetaRecord,2,0) {(void*) boxptr_ClassInf_isMetaRecord,0}};
#define boxvar_ClassInf_isMetaRecord MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_isMetaRecord)
DLLExport
modelica_boolean omc_ClassInf_isRecord(threadData_t *threadData, modelica_metatype _inState);
DLLExport
modelica_metatype boxptr_ClassInf_isRecord(threadData_t *threadData, modelica_metatype _inState);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_isRecord,2,0) {(void*) boxptr_ClassInf_isRecord,0}};
#define boxvar_ClassInf_isRecord MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_isRecord)
DLLExport
modelica_boolean omc_ClassInf_isTypeOrRecord(threadData_t *threadData, modelica_metatype _inState);
DLLExport
modelica_metatype boxptr_ClassInf_isTypeOrRecord(threadData_t *threadData, modelica_metatype _inState);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_isTypeOrRecord,2,0) {(void*) boxptr_ClassInf_isTypeOrRecord,0}};
#define boxvar_ClassInf_isTypeOrRecord MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_isTypeOrRecord)
DLLExport
modelica_boolean omc_ClassInf_isBasicTypeComponentName(threadData_t *threadData, modelica_string _name);
DLLExport
modelica_metatype boxptr_ClassInf_isBasicTypeComponentName(threadData_t *threadData, modelica_metatype _name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_isBasicTypeComponentName,2,0) {(void*) boxptr_ClassInf_isBasicTypeComponentName,0}};
#define boxvar_ClassInf_isBasicTypeComponentName MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_isBasicTypeComponentName)
DLLExport
void omc_ClassInf_isConnector(threadData_t *threadData, modelica_metatype _inState);
#define boxptr_ClassInf_isConnector omc_ClassInf_isConnector
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_isConnector,2,0) {(void*) boxptr_ClassInf_isConnector,0}};
#define boxvar_ClassInf_isConnector MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_isConnector)
DLLExport
modelica_boolean omc_ClassInf_isFunctionOrRecord(threadData_t *threadData, modelica_metatype _inState);
DLLExport
modelica_metatype boxptr_ClassInf_isFunctionOrRecord(threadData_t *threadData, modelica_metatype _inState);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_isFunctionOrRecord,2,0) {(void*) boxptr_ClassInf_isFunctionOrRecord,0}};
#define boxvar_ClassInf_isFunctionOrRecord MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_isFunctionOrRecord)
DLLExport
modelica_boolean omc_ClassInf_isFunction(threadData_t *threadData, modelica_metatype _inState);
DLLExport
modelica_metatype boxptr_ClassInf_isFunction(threadData_t *threadData, modelica_metatype _inState);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_isFunction,2,0) {(void*) boxptr_ClassInf_isFunction,0}};
#define boxvar_ClassInf_isFunction MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_isFunction)
DLLExport
modelica_boolean omc_ClassInf_matchingState(threadData_t *threadData, modelica_metatype _inState, modelica_metatype _inStateLst);
DLLExport
modelica_metatype boxptr_ClassInf_matchingState(threadData_t *threadData, modelica_metatype _inState, modelica_metatype _inStateLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_matchingState,2,0) {(void*) boxptr_ClassInf_matchingState,0}};
#define boxvar_ClassInf_matchingState MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_matchingState)
DLLExport
modelica_metatype omc_ClassInf_assertTrans(threadData_t *threadData, modelica_metatype _inState, modelica_metatype _event, modelica_metatype _info);
#define boxptr_ClassInf_assertTrans omc_ClassInf_assertTrans
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_assertTrans,2,0) {(void*) boxptr_ClassInf_assertTrans,0}};
#define boxvar_ClassInf_assertTrans MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_assertTrans)
DLLExport
void omc_ClassInf_assertValid(threadData_t *threadData, modelica_metatype _inState, modelica_metatype _inRestriction, modelica_metatype _info);
#define boxptr_ClassInf_assertValid omc_ClassInf_assertValid
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_assertValid,2,0) {(void*) boxptr_ClassInf_assertValid,0}};
#define boxvar_ClassInf_assertValid MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_assertValid)
DLLExport
void omc_ClassInf_valid(threadData_t *threadData, modelica_metatype _inState, modelica_metatype _inRestriction);
#define boxptr_ClassInf_valid omc_ClassInf_valid
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_valid,2,0) {(void*) boxptr_ClassInf_valid,0}};
#define boxvar_ClassInf_valid MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_valid)
DLLExport
modelica_metatype omc_ClassInf_trans(threadData_t *threadData, modelica_metatype _inState, modelica_metatype _inEvent);
#define boxptr_ClassInf_trans omc_ClassInf_trans
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_trans,2,0) {(void*) boxptr_ClassInf_trans,0}};
#define boxvar_ClassInf_trans MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_trans)
#define boxptr_ClassInf_start__dispatch omc_ClassInf_start__dispatch
DLLExport
modelica_metatype omc_ClassInf_start(threadData_t *threadData, modelica_metatype _inRestriction, modelica_metatype _inPath);
#define boxptr_ClassInf_start omc_ClassInf_start
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_start,2,0) {(void*) boxptr_ClassInf_start,0}};
#define boxvar_ClassInf_start MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_start)
#define boxptr_ClassInf_printEventStr omc_ClassInf_printEventStr
DLLExport
modelica_metatype omc_ClassInf_getStateName(threadData_t *threadData, modelica_metatype _inState);
#define boxptr_ClassInf_getStateName omc_ClassInf_getStateName
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_getStateName,2,0) {(void*) boxptr_ClassInf_getStateName,0}};
#define boxvar_ClassInf_getStateName MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_getStateName)
DLLExport
void omc_ClassInf_printState(threadData_t *threadData, modelica_metatype _inState);
#define boxptr_ClassInf_printState omc_ClassInf_printState
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_printState,2,0) {(void*) boxptr_ClassInf_printState,0}};
#define boxvar_ClassInf_printState MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_printState)
DLLExport
modelica_string omc_ClassInf_printStateStr(threadData_t *threadData, modelica_metatype _inState);
#define boxptr_ClassInf_printStateStr omc_ClassInf_printStateStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_printStateStr,2,0) {(void*) boxptr_ClassInf_printStateStr,0}};
#define boxvar_ClassInf_printStateStr MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_printStateStr)
#ifdef __cplusplus
}
#endif
#endif
