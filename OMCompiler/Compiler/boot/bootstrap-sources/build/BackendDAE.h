#ifndef BackendDAE__H
#define BackendDAE__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLDirection
modelica_integer omc_BackendDAE_getSimIteratorSize(threadData_t *threadData, modelica_metatype _iters);
DLLDirection
modelica_metatype boxptr_BackendDAE_getSimIteratorSize(threadData_t *threadData, modelica_metatype _iters);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendDAE_getSimIteratorSize,2,0) {(void*) boxptr_BackendDAE_getSimIteratorSize,0}};
#define boxvar_BackendDAE_getSimIteratorSize MMC_REFSTRUCTLIT(boxvar_lit_BackendDAE_getSimIteratorSize)
#ifdef __cplusplus
}
#endif
#endif
