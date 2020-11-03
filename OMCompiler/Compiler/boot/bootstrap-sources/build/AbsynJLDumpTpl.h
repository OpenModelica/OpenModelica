#ifndef AbsynJLDumpTpl__H
#define AbsynJLDumpTpl__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_AbsynJLDumpTpl_dump(threadData_t *threadData, modelica_metatype _txt, modelica_metatype _a_program);
#define boxptr_AbsynJLDumpTpl_dump omc_AbsynJLDumpTpl_dump
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynJLDumpTpl_dump,2,0) {(void*) boxptr_AbsynJLDumpTpl_dump,0}};
#define boxvar_AbsynJLDumpTpl_dump MMC_REFSTRUCTLIT(boxvar_lit_AbsynJLDumpTpl_dump)
#ifdef __cplusplus
}
#endif
#endif
