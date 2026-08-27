#ifndef FExpand__H
#define FExpand__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_FExpand_all(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FExpand_all omc_FExpand_all
static const MMC_DEFSTRUCTLIT(boxvar_lit_FExpand_all,2,0) {(void*) boxptr_FExpand_all,0}};
#define boxvar_FExpand_all MMC_REFSTRUCTLIT(boxvar_lit_FExpand_all)
DLLExport
modelica_metatype omc_FExpand_path(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inPath, modelica_metatype *out_outRef);
#define boxptr_FExpand_path omc_FExpand_path
static const MMC_DEFSTRUCTLIT(boxvar_lit_FExpand_path,2,0) {(void*) boxptr_FExpand_path,0}};
#define boxvar_FExpand_path MMC_REFSTRUCTLIT(boxvar_lit_FExpand_path)
#ifdef __cplusplus
}
#endif
#endif
