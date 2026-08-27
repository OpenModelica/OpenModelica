#ifndef DumpGraphviz__H
#define DumpGraphviz__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
void omc_DumpGraphviz_dump(threadData_t *threadData, modelica_metatype _p);
#define boxptr_DumpGraphviz_dump omc_DumpGraphviz_dump
static const MMC_DEFSTRUCTLIT(boxvar_lit_DumpGraphviz_dump,2,0) {(void*) boxptr_DumpGraphviz_dump,0}};
#define boxvar_DumpGraphviz_dump MMC_REFSTRUCTLIT(boxvar_lit_DumpGraphviz_dump)
#ifdef __cplusplus
}
#endif
#endif
