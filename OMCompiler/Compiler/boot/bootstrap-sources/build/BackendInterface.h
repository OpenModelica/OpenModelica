#ifndef BackendInterface__H
#define BackendInterface__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_BackendInterface_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean *out_isChanged);
DLLExport
modelica_metatype boxptr_BackendInterface_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype *out_isChanged);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendInterface_rewriteFrontEnd,2,0) {(void*) boxptr_BackendInterface_rewriteFrontEnd,0}};
#define boxvar_BackendInterface_rewriteFrontEnd MMC_REFSTRUCTLIT(boxvar_lit_BackendInterface_rewriteFrontEnd)
DLLExport
modelica_boolean omc_BackendInterface_noRewriteRulesFrontEnd(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_BackendInterface_noRewriteRulesFrontEnd(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendInterface_noRewriteRulesFrontEnd,2,0) {(void*) boxptr_BackendInterface_noRewriteRulesFrontEnd,0}};
#define boxvar_BackendInterface_noRewriteRulesFrontEnd MMC_REFSTRUCTLIT(boxvar_lit_BackendInterface_noRewriteRulesFrontEnd)
DLLExport
modelica_metatype omc_BackendInterface_elabCallInteractive(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype _inExps, modelica_metatype _inNamedArgs, modelica_boolean _inImplInst, modelica_metatype _inPrefix, modelica_metatype _inInfo, modelica_metatype *out_outExp, modelica_metatype *out_outProperties);
DLLExport
modelica_metatype boxptr_BackendInterface_elabCallInteractive(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype _inExps, modelica_metatype _inNamedArgs, modelica_metatype _inImplInst, modelica_metatype _inPrefix, modelica_metatype _inInfo, modelica_metatype *out_outExp, modelica_metatype *out_outProperties);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendInterface_elabCallInteractive,2,0) {(void*) boxptr_BackendInterface_elabCallInteractive,0}};
#define boxvar_BackendInterface_elabCallInteractive MMC_REFSTRUCTLIT(boxvar_lit_BackendInterface_elabCallInteractive)
DLLExport
modelica_metatype omc_BackendInterface_cevalCallFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inValues, modelica_boolean _inImplInst, modelica_metatype _inMsg, modelica_integer _inNumIter, modelica_metatype *out_outValue);
DLLExport
modelica_metatype boxptr_BackendInterface_cevalCallFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inValues, modelica_metatype _inImplInst, modelica_metatype _inMsg, modelica_metatype _inNumIter, modelica_metatype *out_outValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendInterface_cevalCallFunction,2,0) {(void*) boxptr_BackendInterface_cevalCallFunction,0}};
#define boxvar_BackendInterface_cevalCallFunction MMC_REFSTRUCTLIT(boxvar_lit_BackendInterface_cevalCallFunction)
DLLExport
modelica_metatype omc_BackendInterface_cevalInteractiveFunctions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inMsg, modelica_integer _inNumIter, modelica_metatype *out_outValue);
DLLExport
modelica_metatype boxptr_BackendInterface_cevalInteractiveFunctions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inMsg, modelica_metatype _inNumIter, modelica_metatype *out_outValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendInterface_cevalInteractiveFunctions,2,0) {(void*) boxptr_BackendInterface_cevalInteractiveFunctions,0}};
#define boxvar_BackendInterface_cevalInteractiveFunctions MMC_REFSTRUCTLIT(boxvar_lit_BackendInterface_cevalInteractiveFunctions)
#ifdef __cplusplus
}
#endif
#endif
