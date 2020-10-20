#ifndef FTraverse__H
#define FTraverse__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_FTraverse_walk(threadData_t *threadData, modelica_metatype _inGraph, modelica_fnptr _inWalker, modelica_metatype _inExtra, modelica_metatype _inOptions, modelica_metatype *out_outExtra);
#define boxptr_FTraverse_walk omc_FTraverse_walk
static const MMC_DEFSTRUCTLIT(boxvar_lit_FTraverse_walk,2,0) {(void*) boxptr_FTraverse_walk,0}};
#define boxvar_FTraverse_walk MMC_REFSTRUCTLIT(boxvar_lit_FTraverse_walk)
#ifdef __cplusplus
}
#endif
#endif
