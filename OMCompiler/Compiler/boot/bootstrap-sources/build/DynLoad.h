#ifndef DynLoad__H
#define DynLoad__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description SourceInfo_SOURCEINFO__desc;
extern modelica_metatype DynLoad_executeFunction(OpenModelica_threadData_ThreadData*, int /*_handle*/, modelica_metatype /*_values*/, int /*_debug*/);
DLLExport
modelica_metatype omc_DynLoad_executeFunction(threadData_t *threadData, modelica_integer _handle, modelica_metatype _values, modelica_boolean _debug);
DLLExport
modelica_metatype boxptr_DynLoad_executeFunction(threadData_t *threadData, modelica_metatype _handle, modelica_metatype _values, modelica_metatype _debug);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DynLoad_executeFunction,2,0) {(void*) boxptr_DynLoad_executeFunction,0}};
#define boxvar_DynLoad_executeFunction MMC_REFSTRUCTLIT(boxvar_lit_DynLoad_executeFunction)
#ifdef __cplusplus
}
#endif
#endif
