#ifndef SimCodeUtil__H
#define SimCodeUtil__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_integer omc_SimCodeUtil_hashEqSystemMod(threadData_t *threadData, modelica_integer _eq, modelica_integer _mod);
DLLExport
modelica_metatype boxptr_SimCodeUtil_hashEqSystemMod(threadData_t *threadData, modelica_metatype _eq, modelica_metatype _mod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeUtil_hashEqSystemMod,2,0) {(void*) boxptr_SimCodeUtil_hashEqSystemMod,0}};
#define boxvar_SimCodeUtil_hashEqSystemMod MMC_REFSTRUCTLIT(boxvar_lit_SimCodeUtil_hashEqSystemMod)
DLLExport
modelica_string omc_SimCodeUtil_getLocalValueReference(threadData_t *threadData, modelica_metatype _inSimVar, modelica_integer _inSimCode, modelica_metatype _inCrefToSimVarHT, modelica_boolean _inElimNegAliases);
DLLExport
modelica_metatype boxptr_SimCodeUtil_getLocalValueReference(threadData_t *threadData, modelica_metatype _inSimVar, modelica_metatype _inSimCode, modelica_metatype _inCrefToSimVarHT, modelica_metatype _inElimNegAliases);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeUtil_getLocalValueReference,2,0) {(void*) boxptr_SimCodeUtil_getLocalValueReference,0}};
#define boxvar_SimCodeUtil_getLocalValueReference MMC_REFSTRUCTLIT(boxvar_lit_SimCodeUtil_getLocalValueReference)
DLLExport
modelica_string omc_SimCodeUtil_getValueReference(threadData_t *threadData, modelica_metatype _inSimVar, modelica_integer _inSimCode, modelica_boolean _inElimNegAliases);
DLLExport
modelica_metatype boxptr_SimCodeUtil_getValueReference(threadData_t *threadData, modelica_metatype _inSimVar, modelica_metatype _inSimCode, modelica_metatype _inElimNegAliases);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeUtil_getValueReference,2,0) {(void*) boxptr_SimCodeUtil_getValueReference,0}};
#define boxvar_SimCodeUtil_getValueReference MMC_REFSTRUCTLIT(boxvar_lit_SimCodeUtil_getValueReference)
DLLExport
modelica_metatype omc_SimCodeUtil_codegenExpSanityCheck(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fe, modelica_metatype _context);
#define boxptr_SimCodeUtil_codegenExpSanityCheck omc_SimCodeUtil_codegenExpSanityCheck
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeUtil_codegenExpSanityCheck,2,0) {(void*) boxptr_SimCodeUtil_codegenExpSanityCheck,0}};
#define boxvar_SimCodeUtil_codegenExpSanityCheck MMC_REFSTRUCTLIT(boxvar_lit_SimCodeUtil_codegenExpSanityCheck)
DLLExport
modelica_string omc_SimCodeUtil_localCref2Index(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inOMSIFunction);
#define boxptr_SimCodeUtil_localCref2Index omc_SimCodeUtil_localCref2Index
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeUtil_localCref2Index,2,0) {(void*) boxptr_SimCodeUtil_localCref2Index,0}};
#define boxvar_SimCodeUtil_localCref2Index MMC_REFSTRUCTLIT(boxvar_lit_SimCodeUtil_localCref2Index)
DLLExport
modelica_metatype omc_SimCodeUtil_localCref2SimVar(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inCrefToSimVarHT);
#define boxptr_SimCodeUtil_localCref2SimVar omc_SimCodeUtil_localCref2SimVar
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeUtil_localCref2SimVar,2,0) {(void*) boxptr_SimCodeUtil_localCref2SimVar,0}};
#define boxvar_SimCodeUtil_localCref2SimVar MMC_REFSTRUCTLIT(boxvar_lit_SimCodeUtil_localCref2SimVar)
DLLExport
modelica_metatype omc_SimCodeUtil_simVarFromHT(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _simCode);
#define boxptr_SimCodeUtil_simVarFromHT omc_SimCodeUtil_simVarFromHT
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeUtil_simVarFromHT,2,0) {(void*) boxptr_SimCodeUtil_simVarFromHT,0}};
#define boxvar_SimCodeUtil_simVarFromHT MMC_REFSTRUCTLIT(boxvar_lit_SimCodeUtil_simVarFromHT)
DLLExport
modelica_metatype omc_SimCodeUtil_cref2simvar(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inCrefToSimVarHT);
#define boxptr_SimCodeUtil_cref2simvar omc_SimCodeUtil_cref2simvar
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeUtil_cref2simvar,2,0) {(void*) boxptr_SimCodeUtil_cref2simvar,0}};
#define boxvar_SimCodeUtil_cref2simvar MMC_REFSTRUCTLIT(boxvar_lit_SimCodeUtil_cref2simvar)
DLLExport
modelica_integer omc_SimCodeUtil_getSimCode(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_SimCodeUtil_getSimCode(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeUtil_getSimCode,2,0) {(void*) boxptr_SimCodeUtil_getSimCode,0}};
#define boxvar_SimCodeUtil_getSimCode MMC_REFSTRUCTLIT(boxvar_lit_SimCodeUtil_getSimCode)
DLLExport
modelica_metatype omc_SimCodeUtil_eqInfo(threadData_t *threadData, modelica_metatype _eq);
#define boxptr_SimCodeUtil_eqInfo omc_SimCodeUtil_eqInfo
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeUtil_eqInfo,2,0) {(void*) boxptr_SimCodeUtil_eqInfo,0}};
#define boxvar_SimCodeUtil_eqInfo MMC_REFSTRUCTLIT(boxvar_lit_SimCodeUtil_eqInfo)
DLLExport
modelica_metatype omc_SimCodeUtil_sortEqSystems(threadData_t *threadData, modelica_metatype _eqs);
#define boxptr_SimCodeUtil_sortEqSystems omc_SimCodeUtil_sortEqSystems
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeUtil_sortEqSystems,2,0) {(void*) boxptr_SimCodeUtil_sortEqSystems,0}};
#define boxvar_SimCodeUtil_sortEqSystems MMC_REFSTRUCTLIT(boxvar_lit_SimCodeUtil_sortEqSystems)
#ifdef __cplusplus
}
#endif
#endif
