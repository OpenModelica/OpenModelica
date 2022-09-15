#ifndef ClockIndexes__H
#define ClockIndexes__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_string omc_ClockIndexes_toString(threadData_t *threadData, modelica_integer _clockIndex);
DLLExport
modelica_metatype boxptr_ClockIndexes_toString(threadData_t *threadData, modelica_metatype _clockIndex);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClockIndexes_toString,2,0) {(void*) boxptr_ClockIndexes_toString,0}};
#define boxvar_ClockIndexes_toString MMC_REFSTRUCTLIT(boxvar_lit_ClockIndexes_toString)
#ifdef __cplusplus
}
#endif
#endif
