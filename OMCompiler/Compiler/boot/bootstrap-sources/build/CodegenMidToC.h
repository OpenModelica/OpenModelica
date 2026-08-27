#ifndef CodegenMidToC__H
#define CodegenMidToC__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
DLLExport
modelica_metatype omc_CodegenMidToC_genProgram(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_p);
#define boxptr_CodegenMidToC_genProgram omc_CodegenMidToC_genProgram
static const MMC_DEFSTRUCTLIT(boxvar_lit_CodegenMidToC_genProgram,2,0) {(void*) boxptr_CodegenMidToC_genProgram,0}};
#define boxvar_CodegenMidToC_genProgram MMC_REFSTRUCTLIT(boxvar_lit_CodegenMidToC_genProgram)
#ifdef __cplusplus
}
#endif
#endif
