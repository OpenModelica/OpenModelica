#ifndef CodegenWasmJitFunctions__H
#define CodegenWasmJitFunctions__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Values_Value_NORETCALL__desc;
DLLDirection
modelica_metatype omc_CodegenWasmJitFunctions_loadAndExecute(threadData_t *threadData, modelica_string _fileName, modelica_string _name, modelica_metatype _args);
#define boxptr_CodegenWasmJitFunctions_loadAndExecute omc_CodegenWasmJitFunctions_loadAndExecute
static const MMC_DEFSTRUCTLIT(boxvar_lit_CodegenWasmJitFunctions_loadAndExecute,2,0) {(void*) boxptr_CodegenWasmJitFunctions_loadAndExecute,0}};
#define boxvar_CodegenWasmJitFunctions_loadAndExecute MMC_REFSTRUCTLIT(boxvar_lit_CodegenWasmJitFunctions_loadAndExecute)
DLLDirection
void omc_CodegenWasmJitFunctions_translateFunctions(threadData_t *threadData, modelica_metatype _fnCode);
#define boxptr_CodegenWasmJitFunctions_translateFunctions omc_CodegenWasmJitFunctions_translateFunctions
static const MMC_DEFSTRUCTLIT(boxvar_lit_CodegenWasmJitFunctions_translateFunctions,2,0) {(void*) boxptr_CodegenWasmJitFunctions_translateFunctions,0}};
#define boxvar_CodegenWasmJitFunctions_translateFunctions MMC_REFSTRUCTLIT(boxvar_lit_CodegenWasmJitFunctions_translateFunctions)
#ifdef __cplusplus
}
#endif
#endif
