#ifndef SimCodeFunction__H
#define SimCodeFunction__H
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
DLLDirection
modelica_string omc_SimCodeFunction_Variable_toString(threadData_t *threadData, modelica_metatype _variable);
#define boxptr_SimCodeFunction_Variable_toString omc_SimCodeFunction_Variable_toString
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeFunction_Variable_toString,2,0) {(void*) boxptr_SimCodeFunction_Variable_toString,0}};
#define boxvar_SimCodeFunction_Variable_toString MMC_REFSTRUCTLIT(boxvar_lit_SimCodeFunction_Variable_toString)
DLLDirection
modelica_string omc_SimCodeFunction_SimExtArg_toString(threadData_t *threadData, modelica_metatype _simExtArg);
#define boxptr_SimCodeFunction_SimExtArg_toString omc_SimCodeFunction_SimExtArg_toString
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeFunction_SimExtArg_toString,2,0) {(void*) boxptr_SimCodeFunction_SimExtArg_toString,0}};
#define boxvar_SimCodeFunction_SimExtArg_toString MMC_REFSTRUCTLIT(boxvar_lit_SimCodeFunction_SimExtArg_toString)
DLLDirection
modelica_string omc_SimCodeFunction_Function_toString(threadData_t *threadData, modelica_metatype _func);
#define boxptr_SimCodeFunction_Function_toString omc_SimCodeFunction_Function_toString
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeFunction_Function_toString,2,0) {(void*) boxptr_SimCodeFunction_Function_toString,0}};
#define boxvar_SimCodeFunction_Function_toString MMC_REFSTRUCTLIT(boxvar_lit_SimCodeFunction_Function_toString)
#ifdef __cplusplus
}
#endif
#endif
