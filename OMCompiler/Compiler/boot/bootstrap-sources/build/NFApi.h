#ifndef NFApi__H
#define NFApi__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_NFApi_mkFullyQual(threadData_t *threadData, modelica_metatype _absynProgram, modelica_metatype _classPath, modelica_metatype _pathToQualify);
#define boxptr_NFApi_mkFullyQual omc_NFApi_mkFullyQual
static const MMC_DEFSTRUCTLIT(boxvar_lit_NFApi_mkFullyQual,2,0) {(void*) boxptr_NFApi_mkFullyQual,0}};
#define boxvar_NFApi_mkFullyQual MMC_REFSTRUCTLIT(boxvar_lit_NFApi_mkFullyQual)
DLLExport
modelica_metatype omc_NFApi_evaluateAnnotations(threadData_t *threadData, modelica_metatype _absynProgram, modelica_metatype _classPath, modelica_metatype _inElements);
#define boxptr_NFApi_evaluateAnnotations omc_NFApi_evaluateAnnotations
static const MMC_DEFSTRUCTLIT(boxvar_lit_NFApi_evaluateAnnotations,2,0) {(void*) boxptr_NFApi_evaluateAnnotations,0}};
#define boxvar_NFApi_evaluateAnnotations MMC_REFSTRUCTLIT(boxvar_lit_NFApi_evaluateAnnotations)
DLLExport
modelica_string omc_NFApi_evaluateAnnotation(threadData_t *threadData, modelica_metatype _absynProgram, modelica_metatype _classPath, modelica_metatype _inAnnotation);
#define boxptr_NFApi_evaluateAnnotation omc_NFApi_evaluateAnnotation
static const MMC_DEFSTRUCTLIT(boxvar_lit_NFApi_evaluateAnnotation,2,0) {(void*) boxptr_NFApi_evaluateAnnotation,0}};
#define boxvar_NFApi_evaluateAnnotation MMC_REFSTRUCTLIT(boxvar_lit_NFApi_evaluateAnnotation)
#ifdef __cplusplus
}
#endif
#endif
