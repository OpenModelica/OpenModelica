#ifndef RewriteRules__H
#define RewriteRules__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_RewriteRules_clearRules(threadData_t *threadData);
#define boxptr_RewriteRules_clearRules omc_RewriteRules_clearRules
static const MMC_DEFSTRUCTLIT(boxvar_lit_RewriteRules_clearRules,2,0) {(void*) boxptr_RewriteRules_clearRules,0}};
#define boxvar_RewriteRules_clearRules MMC_REFSTRUCTLIT(boxvar_lit_RewriteRules_clearRules)
DLLExport
void omc_RewriteRules_loadRules(threadData_t *threadData);
#define boxptr_RewriteRules_loadRules omc_RewriteRules_loadRules
static const MMC_DEFSTRUCTLIT(boxvar_lit_RewriteRules_loadRules,2,0) {(void*) boxptr_RewriteRules_loadRules,0}};
#define boxvar_RewriteRules_loadRules MMC_REFSTRUCTLIT(boxvar_lit_RewriteRules_loadRules)
DLLExport
modelica_boolean omc_RewriteRules_noRewriteRulesBackEnd(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_RewriteRules_noRewriteRulesBackEnd(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_RewriteRules_noRewriteRulesBackEnd,2,0) {(void*) boxptr_RewriteRules_noRewriteRulesBackEnd,0}};
#define boxvar_RewriteRules_noRewriteRulesBackEnd MMC_REFSTRUCTLIT(boxvar_lit_RewriteRules_noRewriteRulesBackEnd)
DLLExport
modelica_boolean omc_RewriteRules_noRewriteRulesFrontEnd(threadData_t *threadData);
DLLExport
modelica_metatype boxptr_RewriteRules_noRewriteRulesFrontEnd(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_RewriteRules_noRewriteRulesFrontEnd,2,0) {(void*) boxptr_RewriteRules_noRewriteRulesFrontEnd,0}};
#define boxvar_RewriteRules_noRewriteRulesFrontEnd MMC_REFSTRUCTLIT(boxvar_lit_RewriteRules_noRewriteRulesFrontEnd)
DLLExport
modelica_metatype omc_RewriteRules_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean *out_isChanged);
DLLExport
modelica_metatype boxptr_RewriteRules_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype *out_isChanged);
static const MMC_DEFSTRUCTLIT(boxvar_lit_RewriteRules_rewriteFrontEnd,2,0) {(void*) boxptr_RewriteRules_rewriteFrontEnd,0}};
#define boxvar_RewriteRules_rewriteFrontEnd MMC_REFSTRUCTLIT(boxvar_lit_RewriteRules_rewriteFrontEnd)
#ifdef __cplusplus
}
#endif
#endif
