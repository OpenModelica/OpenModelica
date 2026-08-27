#ifndef BackendDAECreate__H
#define BackendDAECreate__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_BackendDAECreate_lower(threadData_t *threadData, modelica_metatype _a, modelica_metatype _b, modelica_metatype _c, modelica_metatype _d);
#define boxptr_BackendDAECreate_lower omc_BackendDAECreate_lower
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendDAECreate_lower,2,0) {(void*) boxptr_BackendDAECreate_lower,0}};
#define boxvar_BackendDAECreate_lower MMC_REFSTRUCTLIT(boxvar_lit_BackendDAECreate_lower)
#ifdef __cplusplus
}
#endif
#endif
