#ifndef NFUnitCheck__H
#define NFUnitCheck__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_NFUnitCheck_checkUnits(threadData_t *threadData, modelica_metatype _inDAE, modelica_metatype _func);
#define boxptr_NFUnitCheck_checkUnits omc_NFUnitCheck_checkUnits
static const MMC_DEFSTRUCTLIT(boxvar_lit_NFUnitCheck_checkUnits,2,0) {(void*) boxptr_NFUnitCheck_checkUnits,0}};
#define boxvar_NFUnitCheck_checkUnits MMC_REFSTRUCTLIT(boxvar_lit_NFUnitCheck_checkUnits)
#ifdef __cplusplus
}
#endif
#endif
