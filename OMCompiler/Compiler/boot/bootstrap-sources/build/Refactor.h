#ifndef Refactor__H
#define Refactor__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_Refactor_refactorGraphicalAnnotation(threadData_t *threadData, modelica_metatype _wholeAST, modelica_metatype _classToRefactor);
#define boxptr_Refactor_refactorGraphicalAnnotation omc_Refactor_refactorGraphicalAnnotation
static const MMC_DEFSTRUCTLIT(boxvar_lit_Refactor_refactorGraphicalAnnotation,2,0) {(void*) boxptr_Refactor_refactorGraphicalAnnotation,0}};
#define boxvar_Refactor_refactorGraphicalAnnotation MMC_REFSTRUCTLIT(boxvar_lit_Refactor_refactorGraphicalAnnotation)
#ifdef __cplusplus
}
#endif
#endif
