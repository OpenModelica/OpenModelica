#ifndef Global__H
#define Global__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_Global_initialize(threadData_t *threadData);
#define boxptr_Global_initialize omc_Global_initialize
static const MMC_DEFSTRUCTLIT(boxvar_lit_Global_initialize,2,0) {(void*) boxptr_Global_initialize,0}};
#define boxvar_Global_initialize MMC_REFSTRUCTLIT(boxvar_lit_Global_initialize)
#ifdef __cplusplus
}
#endif
#endif
