#ifndef Builtin__H
#define Builtin__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Absyn_Path_IDENT__desc;
extern struct record_description ClassInf_State_CONNECTOR__desc;
extern struct record_description DAE_Const_C__VAR__desc;
extern struct record_description DAE_FuncArg_FUNCARG__desc;
extern struct record_description DAE_FunctionAttributes_FUNCTION__ATTRIBUTES__desc;
extern struct record_description DAE_FunctionBuiltin_FUNCTION__BUILTIN__desc;
extern struct record_description DAE_FunctionParallelism_FP__NON__PARALLEL__desc;
extern struct record_description DAE_InlineType_NO__INLINE__desc;
extern struct record_description DAE_Type_T__ANYTYPE__desc;
extern struct record_description DAE_Type_T__FUNCTION__desc;
extern struct record_description DAE_Type_T__INTEGER__desc;
extern struct record_description DAE_VarParallelism_NON__PARALLEL__desc;
extern struct record_description FCore_Kind_BASIC__TYPE__desc;
extern struct record_description FCore_Kind_BUILTIN__desc;
extern struct record_description Flags_ConfigFlag_CONFIG__FLAG__desc;
extern struct record_description Flags_FlagData_ENUM__FLAG__desc;
extern struct record_description Flags_FlagVisibility_EXTERNAL__desc;
extern struct record_description Flags_ValidOptions_STRING__OPTION__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
#define boxptr_Builtin_getSetInitialGraph omc_Builtin_getSetInitialGraph
DLLExport
modelica_metatype omc_Builtin_initialGraph(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype *out_graph);
#define boxptr_Builtin_initialGraph omc_Builtin_initialGraph
static const MMC_DEFSTRUCTLIT(boxvar_lit_Builtin_initialGraph,2,0) {(void*) boxptr_Builtin_initialGraph,0}};
#define boxvar_Builtin_initialGraph MMC_REFSTRUCTLIT(boxvar_lit_Builtin_initialGraph)
DLLExport
void omc_Builtin_isDer(threadData_t *threadData, modelica_metatype _inPath);
#define boxptr_Builtin_isDer omc_Builtin_isDer
static const MMC_DEFSTRUCTLIT(boxvar_lit_Builtin_isDer,2,0) {(void*) boxptr_Builtin_isDer,0}};
#define boxvar_Builtin_isDer MMC_REFSTRUCTLIT(boxvar_lit_Builtin_isDer)
DLLExport
modelica_boolean omc_Builtin_variableNameIsBuiltin(threadData_t *threadData, modelica_string _name);
DLLExport
modelica_metatype boxptr_Builtin_variableNameIsBuiltin(threadData_t *threadData, modelica_metatype _name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Builtin_variableNameIsBuiltin,2,0) {(void*) boxptr_Builtin_variableNameIsBuiltin,0}};
#define boxvar_Builtin_variableNameIsBuiltin MMC_REFSTRUCTLIT(boxvar_lit_Builtin_variableNameIsBuiltin)
DLLExport
modelica_boolean omc_Builtin_variableIsBuiltin(threadData_t *threadData, modelica_metatype _cref);
DLLExport
modelica_metatype boxptr_Builtin_variableIsBuiltin(threadData_t *threadData, modelica_metatype _cref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Builtin_variableIsBuiltin,2,0) {(void*) boxptr_Builtin_variableIsBuiltin,0}};
#define boxvar_Builtin_variableIsBuiltin MMC_REFSTRUCTLIT(boxvar_lit_Builtin_variableIsBuiltin)
#ifdef __cplusplus
}
#endif
#endif
