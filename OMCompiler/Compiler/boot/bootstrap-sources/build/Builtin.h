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
extern struct record_description FCore_Kind_BASIC__TYPE__desc;
extern struct record_description FCore_Kind_BUILTIN__desc;
extern struct record_description Flags_ConfigFlag_CONFIG__FLAG__desc;
extern struct record_description Flags_FlagData_ENUM__FLAG__desc;
extern struct record_description Flags_FlagVisibility_EXTERNAL__desc;
DLLDirection
void omc_Builtin_clearInitialGraph(threadData_t *threadData);
#define boxptr_Builtin_clearInitialGraph omc_Builtin_clearInitialGraph
static const MMC_DEFSTRUCTLIT(boxvar_lit_Builtin_clearInitialGraph,2,0) {(void*) boxptr_Builtin_clearInitialGraph,0}};
#define boxvar_Builtin_clearInitialGraph MMC_REFSTRUCTLIT(boxvar_lit_Builtin_clearInitialGraph)
#define boxptr_Builtin_getSetInitialGraph omc_Builtin_getSetInitialGraph
DLLDirection
modelica_metatype omc_Builtin_initialGraph(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype *out_graph);
#define boxptr_Builtin_initialGraph omc_Builtin_initialGraph
static const MMC_DEFSTRUCTLIT(boxvar_lit_Builtin_initialGraph,2,0) {(void*) boxptr_Builtin_initialGraph,0}};
#define boxvar_Builtin_initialGraph MMC_REFSTRUCTLIT(boxvar_lit_Builtin_initialGraph)
DLLDirection
void omc_Builtin_isDer(threadData_t *threadData, modelica_metatype _inPath);
#define boxptr_Builtin_isDer omc_Builtin_isDer
static const MMC_DEFSTRUCTLIT(boxvar_lit_Builtin_isDer,2,0) {(void*) boxptr_Builtin_isDer,0}};
#define boxvar_Builtin_isDer MMC_REFSTRUCTLIT(boxvar_lit_Builtin_isDer)
DLLDirection
modelica_boolean omc_Builtin_variableNameIsBuiltin(threadData_t *threadData, modelica_string _name);
DLLDirection
modelica_metatype boxptr_Builtin_variableNameIsBuiltin(threadData_t *threadData, modelica_metatype _name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Builtin_variableNameIsBuiltin,2,0) {(void*) boxptr_Builtin_variableNameIsBuiltin,0}};
#define boxvar_Builtin_variableNameIsBuiltin MMC_REFSTRUCTLIT(boxvar_lit_Builtin_variableNameIsBuiltin)
DLLDirection
modelica_boolean omc_Builtin_variableIsBuiltin(threadData_t *threadData, modelica_metatype _cref);
DLLDirection
modelica_metatype boxptr_Builtin_variableIsBuiltin(threadData_t *threadData, modelica_metatype _cref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Builtin_variableIsBuiltin,2,0) {(void*) boxptr_Builtin_variableIsBuiltin,0}};
#define boxvar_Builtin_variableIsBuiltin MMC_REFSTRUCTLIT(boxvar_lit_Builtin_variableIsBuiltin)
#ifdef __cplusplus
}
#endif
#endif
