#ifndef Debug__H
#define Debug__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_Debug_traceln(threadData_t *threadData, modelica_string _str);
#define boxptr_Debug_traceln omc_Debug_traceln
static const MMC_DEFSTRUCTLIT(boxvar_lit_Debug_traceln,2,0) {(void*) boxptr_Debug_traceln,0}};
#define boxvar_Debug_traceln MMC_REFSTRUCTLIT(boxvar_lit_Debug_traceln)
DLLExport
void omc_Debug_trace(threadData_t *threadData, modelica_string _s);
#define boxptr_Debug_trace omc_Debug_trace
static const MMC_DEFSTRUCTLIT(boxvar_lit_Debug_trace,2,0) {(void*) boxptr_Debug_trace,0}};
#define boxvar_Debug_trace MMC_REFSTRUCTLIT(boxvar_lit_Debug_trace)
#ifdef __cplusplus
}
#endif
#endif
