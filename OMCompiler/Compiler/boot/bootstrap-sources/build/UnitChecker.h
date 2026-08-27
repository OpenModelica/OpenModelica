#ifndef UnitChecker__H
#define UnitChecker__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_boolean omc_UnitChecker_isComplete(threadData_t *threadData, modelica_metatype _st, modelica_metatype *out_stout);
DLLExport
modelica_metatype boxptr_UnitChecker_isComplete(threadData_t *threadData, modelica_metatype _st, modelica_metatype *out_stout);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitChecker_isComplete,2,0) {(void*) boxptr_UnitChecker_isComplete,0}};
#define boxvar_UnitChecker_isComplete MMC_REFSTRUCTLIT(boxvar_lit_UnitChecker_isComplete)
DLLExport
modelica_metatype omc_UnitChecker_check(threadData_t *threadData, modelica_metatype _tms, modelica_metatype _ist);
#define boxptr_UnitChecker_check omc_UnitChecker_check
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnitChecker_check,2,0) {(void*) boxptr_UnitChecker_check,0}};
#define boxvar_UnitChecker_check MMC_REFSTRUCTLIT(boxvar_lit_UnitChecker_check)
#ifdef __cplusplus
}
#endif
#endif
