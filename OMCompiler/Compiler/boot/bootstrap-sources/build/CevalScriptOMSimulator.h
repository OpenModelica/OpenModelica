#ifndef CevalScriptOMSimulator__H
#define CevalScriptOMSimulator__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_CevalScriptOMSimulator_ceval(threadData_t *threadData, modelica_string _inFunctionName, modelica_metatype _inVals);
#define boxptr_CevalScriptOMSimulator_ceval omc_CevalScriptOMSimulator_ceval
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalScriptOMSimulator_ceval,2,0) {(void*) boxptr_CevalScriptOMSimulator_ceval,0}};
#define boxvar_CevalScriptOMSimulator_ceval MMC_REFSTRUCTLIT(boxvar_lit_CevalScriptOMSimulator_ceval)
#ifdef __cplusplus
}
#endif
#endif
