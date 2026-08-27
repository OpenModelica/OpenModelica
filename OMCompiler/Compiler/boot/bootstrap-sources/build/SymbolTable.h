#ifndef SymbolTable__H
#define SymbolTable__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Absyn_Direction_BIDIR__desc;
extern struct record_description Absyn_InnerOuter_NOT__INNER__OUTER__desc;
extern struct record_description Absyn_IsField_NONFIELD__desc;
extern struct record_description Absyn_Path_IDENT__desc;
extern struct record_description Absyn_Program_PROGRAM__desc;
extern struct record_description Absyn_TypeSpec_TPATH__desc;
extern struct record_description Absyn_Within_TOP__desc;
extern struct record_description AvlTreeStringString_Tree_EMPTY__desc;
extern struct record_description DAE_Attributes_ATTR__desc;
extern struct record_description DAE_Binding_VALBOUND__desc;
extern struct record_description DAE_BindingSource_BINDING__FROM__DEFAULT__VALUE__desc;
extern struct record_description DAE_ConnectorType_NON__CONNECTOR__desc;
extern struct record_description DAE_Mod_NOMOD__desc;
extern struct record_description DAE_Type_T__UNKNOWN__desc;
extern struct record_description DAE_Var_TYPES__VAR__desc;
extern struct record_description ErrorTypes_Message_MESSAGE__desc;
extern struct record_description ErrorTypes_MessageType_SCRIPTING__desc;
extern struct record_description ErrorTypes_MessageType_TRANSLATION__desc;
extern struct record_description ErrorTypes_Severity_ERROR__desc;
extern struct record_description FCore_Status_VAR__TYPED__desc;
extern struct record_description FCore_Status_VAR__UNTYPED__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
extern struct record_description GlobalScript_Variable_IVAR__desc;
extern struct record_description SCode_Attributes_ATTR__desc;
extern struct record_description SCode_Comment_COMMENT__desc;
extern struct record_description SCode_ConnectorType_POTENTIAL__desc;
extern struct record_description SCode_Element_COMPONENT__desc;
extern struct record_description SCode_Final_NOT__FINAL__desc;
extern struct record_description SCode_Mod_NOMOD__desc;
extern struct record_description SCode_Parallelism_NON__PARALLEL__desc;
extern struct record_description SCode_Prefixes_PREFIXES__desc;
extern struct record_description SCode_Redeclare_NOT__REDECLARE__desc;
extern struct record_description SCode_Replaceable_NOT__REPLACEABLE__desc;
extern struct record_description SCode_Variability_VAR__desc;
extern struct record_description SCode_Visibility_PUBLIC__desc;
extern struct record_description SourceInfo_SOURCEINFO__desc;
extern struct record_description SymbolTable_SYMBOLTABLE__desc;
#define boxptr_SymbolTable_updateUriMapping omc_SymbolTable_updateUriMapping
#define boxptr_SymbolTable_addVarToEnv omc_SymbolTable_addVarToEnv
#define boxptr_SymbolTable_addVarsToEnv omc_SymbolTable_addVarsToEnv
DLLExport
modelica_metatype omc_SymbolTable_buildEnv(threadData_t *threadData);
#define boxptr_SymbolTable_buildEnv omc_SymbolTable_buildEnv
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_buildEnv,2,0) {(void*) boxptr_SymbolTable_buildEnv,0}};
#define boxvar_SymbolTable_buildEnv MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_buildEnv)
#define boxptr_SymbolTable_addVarToVarList omc_SymbolTable_addVarToVarList
DLLExport
void omc_SymbolTable_deleteVarFirstEntry(threadData_t *threadData, modelica_string _inIdent);
#define boxptr_SymbolTable_deleteVarFirstEntry omc_SymbolTable_deleteVarFirstEntry
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_deleteVarFirstEntry,2,0) {(void*) boxptr_SymbolTable_deleteVarFirstEntry,0}};
#define boxvar_SymbolTable_deleteVarFirstEntry MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_deleteVarFirstEntry)
DLLExport
void omc_SymbolTable_appendVar(threadData_t *threadData, modelica_string _inIdent, modelica_metatype _inValue, modelica_metatype _inType);
#define boxptr_SymbolTable_appendVar omc_SymbolTable_appendVar
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_appendVar,2,0) {(void*) boxptr_SymbolTable_appendVar,0}};
#define boxvar_SymbolTable_appendVar MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_appendVar)
DLLExport
void omc_SymbolTable_addVar(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv);
#define boxptr_SymbolTable_addVar omc_SymbolTable_addVar
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_addVar,2,0) {(void*) boxptr_SymbolTable_addVar,0}};
#define boxvar_SymbolTable_addVar MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_addVar)
DLLExport
void omc_SymbolTable_addVars(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inValues, modelica_metatype _inEnv);
#define boxptr_SymbolTable_addVars omc_SymbolTable_addVars
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_addVars,2,0) {(void*) boxptr_SymbolTable_addVars,0}};
#define boxvar_SymbolTable_addVars MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_addVars)
DLLExport
void omc_SymbolTable_setVars(threadData_t *threadData, modelica_metatype _vars);
#define boxptr_SymbolTable_setVars omc_SymbolTable_setVars
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_setVars,2,0) {(void*) boxptr_SymbolTable_setVars,0}};
#define boxvar_SymbolTable_setVars MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_setVars)
DLLExport
modelica_metatype omc_SymbolTable_getVars(threadData_t *threadData);
#define boxptr_SymbolTable_getVars omc_SymbolTable_getVars
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_getVars,2,0) {(void*) boxptr_SymbolTable_getVars,0}};
#define boxvar_SymbolTable_getVars MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_getVars)
DLLExport
void omc_SymbolTable_clearProgram(threadData_t *threadData);
#define boxptr_SymbolTable_clearProgram omc_SymbolTable_clearProgram
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_clearProgram,2,0) {(void*) boxptr_SymbolTable_clearProgram,0}};
#define boxvar_SymbolTable_clearProgram MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_clearProgram)
DLLExport
void omc_SymbolTable_clearSCode(threadData_t *threadData);
#define boxptr_SymbolTable_clearSCode omc_SymbolTable_clearSCode
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_clearSCode,2,0) {(void*) boxptr_SymbolTable_clearSCode,0}};
#define boxvar_SymbolTable_clearSCode MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_clearSCode)
DLLExport
void omc_SymbolTable_setSCode(threadData_t *threadData, modelica_metatype _ast);
#define boxptr_SymbolTable_setSCode omc_SymbolTable_setSCode
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_setSCode,2,0) {(void*) boxptr_SymbolTable_setSCode,0}};
#define boxvar_SymbolTable_setSCode MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_setSCode)
DLLExport
modelica_metatype omc_SymbolTable_getSCode(threadData_t *threadData);
#define boxptr_SymbolTable_getSCode omc_SymbolTable_getSCode
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_getSCode,2,0) {(void*) boxptr_SymbolTable_getSCode,0}};
#define boxvar_SymbolTable_getSCode MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_getSCode)
DLLExport
void omc_SymbolTable_setAbsyn(threadData_t *threadData, modelica_metatype _ast);
#define boxptr_SymbolTable_setAbsyn omc_SymbolTable_setAbsyn
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_setAbsyn,2,0) {(void*) boxptr_SymbolTable_setAbsyn,0}};
#define boxvar_SymbolTable_setAbsyn MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_setAbsyn)
DLLExport
modelica_metatype omc_SymbolTable_getAbsyn(threadData_t *threadData);
#define boxptr_SymbolTable_getAbsyn omc_SymbolTable_getAbsyn
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_getAbsyn,2,0) {(void*) boxptr_SymbolTable_getAbsyn,0}};
#define boxvar_SymbolTable_getAbsyn MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_getAbsyn)
DLLExport
modelica_metatype omc_SymbolTable_get(threadData_t *threadData);
#define boxptr_SymbolTable_get omc_SymbolTable_get
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_get,2,0) {(void*) boxptr_SymbolTable_get,0}};
#define boxvar_SymbolTable_get MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_get)
DLLExport
void omc_SymbolTable_update(threadData_t *threadData, modelica_metatype _table);
#define boxptr_SymbolTable_update omc_SymbolTable_update
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_update,2,0) {(void*) boxptr_SymbolTable_update,0}};
#define boxvar_SymbolTable_update MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_update)
DLLExport
void omc_SymbolTable_reset(threadData_t *threadData);
#define boxptr_SymbolTable_reset omc_SymbolTable_reset
static const MMC_DEFSTRUCTLIT(boxvar_lit_SymbolTable_reset,2,0) {(void*) boxptr_SymbolTable_reset,0}};
#define boxvar_SymbolTable_reset MMC_REFSTRUCTLIT(boxvar_lit_SymbolTable_reset)
#ifdef __cplusplus
}
#endif
#endif
