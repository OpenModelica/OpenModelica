#ifndef NFSCodeFlatten__H
#define NFSCodeFlatten__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_NFSCodeFlatten_flattenClassInProgram(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype __omcQ_24in_5FinProgram, modelica_integer *out_dummy);
DLLExport
modelica_metatype boxptr_NFSCodeFlatten_flattenClassInProgram(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype __omcQ_24in_5FinProgram, modelica_metatype *out_dummy);
static const MMC_DEFSTRUCTLIT(boxvar_lit_NFSCodeFlatten_flattenClassInProgram,2,0) {(void*) boxptr_NFSCodeFlatten_flattenClassInProgram,0}};
#define boxvar_NFSCodeFlatten_flattenClassInProgram MMC_REFSTRUCTLIT(boxvar_lit_NFSCodeFlatten_flattenClassInProgram)
DLLExport
modelica_metatype omc_NFSCodeFlatten_flattenCompleteProgram(threadData_t *threadData, modelica_metatype __omcQ_24in_5FinProgram);
#define boxptr_NFSCodeFlatten_flattenCompleteProgram omc_NFSCodeFlatten_flattenCompleteProgram
static const MMC_DEFSTRUCTLIT(boxvar_lit_NFSCodeFlatten_flattenCompleteProgram,2,0) {(void*) boxptr_NFSCodeFlatten_flattenCompleteProgram,0}};
#define boxvar_NFSCodeFlatten_flattenCompleteProgram MMC_REFSTRUCTLIT(boxvar_lit_NFSCodeFlatten_flattenCompleteProgram)
#ifdef __cplusplus
}
#endif
#endif
