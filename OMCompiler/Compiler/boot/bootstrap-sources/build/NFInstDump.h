#ifndef NFInstDump__H
#define NFInstDump__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_string omc_NFInstDump_dumpUntypedComponentDims(threadData_t *threadData, modelica_metatype _inComponent);
#define boxptr_NFInstDump_dumpUntypedComponentDims omc_NFInstDump_dumpUntypedComponentDims
static const MMC_DEFSTRUCTLIT(boxvar_lit_NFInstDump_dumpUntypedComponentDims,2,0) {(void*) boxptr_NFInstDump_dumpUntypedComponentDims,0}};
#define boxvar_NFInstDump_dumpUntypedComponentDims MMC_REFSTRUCTLIT(boxvar_lit_NFInstDump_dumpUntypedComponentDims)
DLLExport
modelica_string omc_NFInstDump_prefixStr(threadData_t *threadData, modelica_metatype _inPrefix);
#define boxptr_NFInstDump_prefixStr omc_NFInstDump_prefixStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_NFInstDump_prefixStr,2,0) {(void*) boxptr_NFInstDump_prefixStr,0}};
#define boxvar_NFInstDump_prefixStr MMC_REFSTRUCTLIT(boxvar_lit_NFInstDump_prefixStr)
#ifdef __cplusplus
}
#endif
#endif
