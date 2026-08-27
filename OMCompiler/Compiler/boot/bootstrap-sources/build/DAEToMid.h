#ifndef DAEToMid__H
#define DAEToMid__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_DAEToMid_DAEFunctionsToMid(threadData_t *threadData, modelica_metatype _simfuncs);
#define boxptr_DAEToMid_DAEFunctionsToMid omc_DAEToMid_DAEFunctionsToMid
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEToMid_DAEFunctionsToMid,2,0) {(void*) boxptr_DAEToMid_DAEFunctionsToMid,0}};
#define boxvar_DAEToMid_DAEFunctionsToMid MMC_REFSTRUCTLIT(boxvar_lit_DAEToMid_DAEFunctionsToMid)
#ifdef __cplusplus
}
#endif
#endif
