#ifndef InstTypes__H
#define InstTypes__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_string omc_InstTypes_callingScopeStr(threadData_t *threadData, modelica_metatype _inCallingScope);
#define boxptr_InstTypes_callingScopeStr omc_InstTypes_callingScopeStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstTypes_callingScopeStr,2,0) {(void*) boxptr_InstTypes_callingScopeStr,0}};
#define boxvar_InstTypes_callingScopeStr MMC_REFSTRUCTLIT(boxvar_lit_InstTypes_callingScopeStr)
#ifdef __cplusplus
}
#endif
#endif
