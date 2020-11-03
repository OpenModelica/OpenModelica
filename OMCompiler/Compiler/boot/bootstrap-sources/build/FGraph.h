#ifndef FGraph__H
#define FGraph__H
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
extern struct record_description Absyn_Path_QUALIFIED__desc;
extern struct record_description Absyn_TypeSpec_TPATH__desc;
extern struct record_description ClassInf_State_UNKNOWN__desc;
extern struct record_description DAE_Attributes_ATTR__desc;
extern struct record_description DAE_ConnectorType_NON__CONNECTOR__desc;
extern struct record_description DAE_Mod_NOMOD__desc;
extern struct record_description DAE_Prefix_NOPRE__desc;
extern struct record_description DAE_Var_TYPES__VAR__desc;
extern struct record_description FCore_Data_CL__desc;
extern struct record_description FCore_Data_CO__desc;
extern struct record_description FCore_Data_IT__desc;
extern struct record_description FCore_Data_ND__desc;
extern struct record_description FCore_Data_REF__desc;
extern struct record_description FCore_Data_TOP__desc;
extern struct record_description FCore_Extra_EXTRA__desc;
extern struct record_description FCore_Graph_EG__desc;
extern struct record_description FCore_Graph_G__desc;
extern struct record_description FCore_Kind_BUILTIN__desc;
extern struct record_description FCore_Kind_USERDEFINED__desc;
extern struct record_description FCore_Node_N__desc;
extern struct record_description FCore_ScopeType_CLASS__SCOPE__desc;
extern struct record_description FCore_ScopeType_FUNCTION__SCOPE__desc;
extern struct record_description FCore_ScopeType_PARALLEL__SCOPE__desc;
extern struct record_description FCore_Status_CLS__INSTANCE__desc;
extern struct record_description FCore_Status_VAR__UNTYPED__desc;
extern struct record_description FCore_Top_GTOP__desc;
extern struct record_description Flags_DebugFlag_DEBUG__FLAG__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
extern struct record_description SCode_Attributes_ATTR__desc;
extern struct record_description SCode_Comment_COMMENT__desc;
extern struct record_description SCode_ConnectorType_POTENTIAL__desc;
extern struct record_description SCode_Element_COMPONENT__desc;
extern struct record_description SCode_Final_NOT__FINAL__desc;
extern struct record_description SCode_FunctionRestriction_FR__NORMAL__FUNCTION__desc;
extern struct record_description SCode_FunctionRestriction_FR__PARALLEL__FUNCTION__desc;
extern struct record_description SCode_Mod_NOMOD__desc;
extern struct record_description SCode_Parallelism_NON__PARALLEL__desc;
extern struct record_description SCode_Prefixes_PREFIXES__desc;
extern struct record_description SCode_Redeclare_NOT__REDECLARE__desc;
extern struct record_description SCode_Replaceable_NOT__REPLACEABLE__desc;
extern struct record_description SCode_Restriction_R__CLASS__desc;
extern struct record_description SCode_Restriction_R__FUNCTION__desc;
extern struct record_description SCode_Variability_CONST__desc;
extern struct record_description SCode_Visibility_PUBLIC__desc;
extern struct record_description SCodeDump_SCodeDumpOptions_OPTIONS__desc;
extern struct record_description SourceInfo_SOURCEINFO__desc;
DLLExport
modelica_boolean omc_FGraph_isPartialScope(threadData_t *threadData, modelica_metatype _inEnv);
DLLExport
modelica_metatype boxptr_FGraph_isPartialScope(threadData_t *threadData, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_isPartialScope,2,0) {(void*) boxptr_FGraph_isPartialScope,0}};
#define boxvar_FGraph_isPartialScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_isPartialScope)
DLLExport
modelica_metatype omc_FGraph_makeScopePartial(threadData_t *threadData, modelica_metatype _inEnv);
#define boxptr_FGraph_makeScopePartial omc_FGraph_makeScopePartial
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_makeScopePartial,2,0) {(void*) boxptr_FGraph_makeScopePartial,0}};
#define boxvar_FGraph_makeScopePartial MMC_REFSTRUCTLIT(boxvar_lit_FGraph_makeScopePartial)
DLLExport
modelica_metatype omc_FGraph_selectScope(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inPath);
#define boxptr_FGraph_selectScope omc_FGraph_selectScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_selectScope,2,0) {(void*) boxptr_FGraph_selectScope,0}};
#define boxvar_FGraph_selectScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_selectScope)
DLLExport
modelica_metatype omc_FGraph_getStatus(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inName);
#define boxptr_FGraph_getStatus omc_FGraph_getStatus
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_getStatus,2,0) {(void*) boxptr_FGraph_getStatus,0}};
#define boxvar_FGraph_getStatus MMC_REFSTRUCTLIT(boxvar_lit_FGraph_getStatus)
DLLExport
modelica_metatype omc_FGraph_setStatus(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inName, modelica_metatype _inStatus);
#define boxptr_FGraph_setStatus omc_FGraph_setStatus
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_setStatus,2,0) {(void*) boxptr_FGraph_setStatus,0}};
#define boxvar_FGraph_setStatus MMC_REFSTRUCTLIT(boxvar_lit_FGraph_setStatus)
DLLExport
modelica_boolean omc_FGraph_graphPrefixOf2(threadData_t *threadData, modelica_metatype _inPrefixEnv, modelica_metatype _inEnv);
DLLExport
modelica_metatype boxptr_FGraph_graphPrefixOf2(threadData_t *threadData, modelica_metatype _inPrefixEnv, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_graphPrefixOf2,2,0) {(void*) boxptr_FGraph_graphPrefixOf2,0}};
#define boxvar_FGraph_graphPrefixOf2 MMC_REFSTRUCTLIT(boxvar_lit_FGraph_graphPrefixOf2)
DLLExport
modelica_boolean omc_FGraph_graphPrefixOf(threadData_t *threadData, modelica_metatype _inPrefixEnv, modelica_metatype _inEnv);
DLLExport
modelica_metatype boxptr_FGraph_graphPrefixOf(threadData_t *threadData, modelica_metatype _inPrefixEnv, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_graphPrefixOf,2,0) {(void*) boxptr_FGraph_graphPrefixOf,0}};
#define boxvar_FGraph_graphPrefixOf MMC_REFSTRUCTLIT(boxvar_lit_FGraph_graphPrefixOf)
DLLExport
modelica_string omc_FGraph_getInstanceOriginalName(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inName);
#define boxptr_FGraph_getInstanceOriginalName omc_FGraph_getInstanceOriginalName
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_getInstanceOriginalName,2,0) {(void*) boxptr_FGraph_getInstanceOriginalName,0}};
#define boxvar_FGraph_getInstanceOriginalName MMC_REFSTRUCTLIT(boxvar_lit_FGraph_getInstanceOriginalName)
DLLExport
modelica_boolean omc_FGraph_isInstance(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inName);
DLLExport
modelica_metatype boxptr_FGraph_isInstance(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_isInstance,2,0) {(void*) boxptr_FGraph_isInstance,0}};
#define boxvar_FGraph_isInstance MMC_REFSTRUCTLIT(boxvar_lit_FGraph_isInstance)
DLLExport
modelica_metatype omc_FGraph_getClassPrefix(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inClassName);
#define boxptr_FGraph_getClassPrefix omc_FGraph_getClassPrefix
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_getClassPrefix,2,0) {(void*) boxptr_FGraph_getClassPrefix,0}};
#define boxvar_FGraph_getClassPrefix MMC_REFSTRUCTLIT(boxvar_lit_FGraph_getClassPrefix)
DLLExport
modelica_string omc_FGraph_mkVersionName(threadData_t *threadData, modelica_metatype _inSourceEnv, modelica_string _inSourceName, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _inTargetClassEnv, modelica_string _inTargetClassName, modelica_metatype *out_outCrefPrefix);
#define boxptr_FGraph_mkVersionName omc_FGraph_mkVersionName
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_mkVersionName,2,0) {(void*) boxptr_FGraph_mkVersionName,0}};
#define boxvar_FGraph_mkVersionName MMC_REFSTRUCTLIT(boxvar_lit_FGraph_mkVersionName)
DLLExport
modelica_boolean omc_FGraph_isTargetClassBuiltin(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inClass);
DLLExport
modelica_metatype boxptr_FGraph_isTargetClassBuiltin(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inClass);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_isTargetClassBuiltin,2,0) {(void*) boxptr_FGraph_isTargetClassBuiltin,0}};
#define boxvar_FGraph_isTargetClassBuiltin MMC_REFSTRUCTLIT(boxvar_lit_FGraph_isTargetClassBuiltin)
DLLExport
modelica_metatype omc_FGraph_createVersionScope(threadData_t *threadData, modelica_metatype _inSourceEnv, modelica_string _inSourceName, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _inTargetClassEnv, modelica_metatype _inTargetClass, modelica_metatype _inIH, modelica_metatype *out_outVersionedTargetClass, modelica_metatype *out_outIH);
#define boxptr_FGraph_createVersionScope omc_FGraph_createVersionScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_createVersionScope,2,0) {(void*) boxptr_FGraph_createVersionScope,0}};
#define boxvar_FGraph_createVersionScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_createVersionScope)
DLLExport
modelica_metatype omc_FGraph_mkVersionNode(threadData_t *threadData, modelica_metatype _inSourceEnv, modelica_string _inSourceName, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _inTargetClassEnv, modelica_metatype _inTargetClass, modelica_metatype _inIH, modelica_metatype *out_outVersionedTargetClass, modelica_metatype *out_outIH);
#define boxptr_FGraph_mkVersionNode omc_FGraph_mkVersionNode
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_mkVersionNode,2,0) {(void*) boxptr_FGraph_mkVersionNode,0}};
#define boxvar_FGraph_mkVersionNode MMC_REFSTRUCTLIT(boxvar_lit_FGraph_mkVersionNode)
DLLExport
modelica_metatype omc_FGraph_updateScope(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_updateScope omc_FGraph_updateScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_updateScope,2,0) {(void*) boxptr_FGraph_updateScope,0}};
#define boxvar_FGraph_updateScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_updateScope)
DLLExport
modelica_metatype omc_FGraph_cloneLastScopeRef(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_cloneLastScopeRef omc_FGraph_cloneLastScopeRef
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_cloneLastScopeRef,2,0) {(void*) boxptr_FGraph_cloneLastScopeRef,0}};
#define boxvar_FGraph_cloneLastScopeRef MMC_REFSTRUCTLIT(boxvar_lit_FGraph_cloneLastScopeRef)
DLLExport
modelica_metatype omc_FGraph_removeComponentsFromScope(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_removeComponentsFromScope omc_FGraph_removeComponentsFromScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_removeComponentsFromScope,2,0) {(void*) boxptr_FGraph_removeComponentsFromScope,0}};
#define boxvar_FGraph_removeComponentsFromScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_removeComponentsFromScope)
DLLExport
modelica_metatype omc_FGraph_getVariablesFromGraphScope(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_getVariablesFromGraphScope omc_FGraph_getVariablesFromGraphScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_getVariablesFromGraphScope,2,0) {(void*) boxptr_FGraph_getVariablesFromGraphScope,0}};
#define boxvar_FGraph_getVariablesFromGraphScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_getVariablesFromGraphScope)
DLLExport
modelica_metatype omc_FGraph_splitGraphScope__dispatch(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inAcc, modelica_metatype *out_outForScope);
#define boxptr_FGraph_splitGraphScope__dispatch omc_FGraph_splitGraphScope__dispatch
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_splitGraphScope__dispatch,2,0) {(void*) boxptr_FGraph_splitGraphScope__dispatch,0}};
#define boxvar_FGraph_splitGraphScope__dispatch MMC_REFSTRUCTLIT(boxvar_lit_FGraph_splitGraphScope__dispatch)
DLLExport
modelica_metatype omc_FGraph_splitGraphScope(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype *out_outForScope);
#define boxptr_FGraph_splitGraphScope omc_FGraph_splitGraphScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_splitGraphScope,2,0) {(void*) boxptr_FGraph_splitGraphScope,0}};
#define boxvar_FGraph_splitGraphScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_splitGraphScope)
DLLExport
modelica_metatype omc_FGraph_joinScopePath(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inPath);
#define boxptr_FGraph_joinScopePath omc_FGraph_joinScopePath
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_joinScopePath,2,0) {(void*) boxptr_FGraph_joinScopePath,0}};
#define boxvar_FGraph_joinScopePath MMC_REFSTRUCTLIT(boxvar_lit_FGraph_joinScopePath)
DLLExport
modelica_boolean omc_FGraph_isImplicitScope(threadData_t *threadData, modelica_string _inName);
DLLExport
modelica_metatype boxptr_FGraph_isImplicitScope(threadData_t *threadData, modelica_metatype _inName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_isImplicitScope,2,0) {(void*) boxptr_FGraph_isImplicitScope,0}};
#define boxvar_FGraph_isImplicitScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_isImplicitScope)
#define boxptr_FGraph_getGraphPathNoImplicitScope__dispatch omc_FGraph_getGraphPathNoImplicitScope__dispatch
DLLExport
modelica_metatype omc_FGraph_getGraphPathNoImplicitScope(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_getGraphPathNoImplicitScope omc_FGraph_getGraphPathNoImplicitScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_getGraphPathNoImplicitScope,2,0) {(void*) boxptr_FGraph_getGraphPathNoImplicitScope,0}};
#define boxvar_FGraph_getGraphPathNoImplicitScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_getGraphPathNoImplicitScope)
DLLExport
modelica_metatype omc_FGraph_getScopeRestriction(threadData_t *threadData, modelica_metatype _inScope);
#define boxptr_FGraph_getScopeRestriction omc_FGraph_getScopeRestriction
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_getScopeRestriction,2,0) {(void*) boxptr_FGraph_getScopeRestriction,0}};
#define boxvar_FGraph_getScopeRestriction MMC_REFSTRUCTLIT(boxvar_lit_FGraph_getScopeRestriction)
DLLExport
modelica_metatype omc_FGraph_lastScopeRestriction(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_lastScopeRestriction omc_FGraph_lastScopeRestriction
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_lastScopeRestriction,2,0) {(void*) boxptr_FGraph_lastScopeRestriction,0}};
#define boxvar_FGraph_lastScopeRestriction MMC_REFSTRUCTLIT(boxvar_lit_FGraph_lastScopeRestriction)
DLLExport
modelica_boolean omc_FGraph_checkScopeType(threadData_t *threadData, modelica_metatype _inScope, modelica_metatype _inScopeType);
DLLExport
modelica_metatype boxptr_FGraph_checkScopeType(threadData_t *threadData, modelica_metatype _inScope, modelica_metatype _inScopeType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_checkScopeType,2,0) {(void*) boxptr_FGraph_checkScopeType,0}};
#define boxvar_FGraph_checkScopeType MMC_REFSTRUCTLIT(boxvar_lit_FGraph_checkScopeType)
DLLExport
modelica_string omc_FGraph_getScopeName(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_getScopeName omc_FGraph_getScopeName
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_getScopeName,2,0) {(void*) boxptr_FGraph_getScopeName,0}};
#define boxvar_FGraph_getScopeName MMC_REFSTRUCTLIT(boxvar_lit_FGraph_getScopeName)
DLLExport
modelica_boolean omc_FGraph_inFunctionScope(threadData_t *threadData, modelica_metatype _inGraph);
DLLExport
modelica_metatype boxptr_FGraph_inFunctionScope(threadData_t *threadData, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_inFunctionScope,2,0) {(void*) boxptr_FGraph_inFunctionScope,0}};
#define boxvar_FGraph_inFunctionScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_inFunctionScope)
DLLExport
modelica_string omc_FGraph_printGraphStr(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_printGraphStr omc_FGraph_printGraphStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_printGraphStr,2,0) {(void*) boxptr_FGraph_printGraphStr,0}};
#define boxvar_FGraph_printGraphStr MMC_REFSTRUCTLIT(boxvar_lit_FGraph_printGraphStr)
DLLExport
modelica_boolean omc_FGraph_isEmptyScope(threadData_t *threadData, modelica_metatype _graph);
DLLExport
modelica_metatype boxptr_FGraph_isEmptyScope(threadData_t *threadData, modelica_metatype _graph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_isEmptyScope,2,0) {(void*) boxptr_FGraph_isEmptyScope,0}};
#define boxvar_FGraph_isEmptyScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_isEmptyScope)
DLLExport
modelica_boolean omc_FGraph_isNotEmpty(threadData_t *threadData, modelica_metatype _inGraph);
DLLExport
modelica_metatype boxptr_FGraph_isNotEmpty(threadData_t *threadData, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_isNotEmpty,2,0) {(void*) boxptr_FGraph_isNotEmpty,0}};
#define boxvar_FGraph_isNotEmpty MMC_REFSTRUCTLIT(boxvar_lit_FGraph_isNotEmpty)
DLLExport
modelica_boolean omc_FGraph_isEmpty(threadData_t *threadData, modelica_metatype _inGraph);
DLLExport
modelica_metatype boxptr_FGraph_isEmpty(threadData_t *threadData, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_isEmpty,2,0) {(void*) boxptr_FGraph_isEmpty,0}};
#define boxvar_FGraph_isEmpty MMC_REFSTRUCTLIT(boxvar_lit_FGraph_isEmpty)
DLLExport
modelica_metatype omc_FGraph_classInfToScopeType(threadData_t *threadData, modelica_metatype _inState);
#define boxptr_FGraph_classInfToScopeType omc_FGraph_classInfToScopeType
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_classInfToScopeType,2,0) {(void*) boxptr_FGraph_classInfToScopeType,0}};
#define boxvar_FGraph_classInfToScopeType MMC_REFSTRUCTLIT(boxvar_lit_FGraph_classInfToScopeType)
DLLExport
modelica_metatype omc_FGraph_mkDefunitNode(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inDu);
#define boxptr_FGraph_mkDefunitNode omc_FGraph_mkDefunitNode
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_mkDefunitNode,2,0) {(void*) boxptr_FGraph_mkDefunitNode,0}};
#define boxvar_FGraph_mkDefunitNode MMC_REFSTRUCTLIT(boxvar_lit_FGraph_mkDefunitNode)
DLLExport
modelica_metatype omc_FGraph_mkImportNode(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inImport);
#define boxptr_FGraph_mkImportNode omc_FGraph_mkImportNode
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_mkImportNode,2,0) {(void*) boxptr_FGraph_mkImportNode,0}};
#define boxvar_FGraph_mkImportNode MMC_REFSTRUCTLIT(boxvar_lit_FGraph_mkImportNode)
DLLExport
modelica_metatype omc_FGraph_mkTypeNode(threadData_t *threadData, modelica_metatype _inGraph, modelica_string _inName, modelica_metatype _inType);
#define boxptr_FGraph_mkTypeNode omc_FGraph_mkTypeNode
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_mkTypeNode,2,0) {(void*) boxptr_FGraph_mkTypeNode,0}};
#define boxvar_FGraph_mkTypeNode MMC_REFSTRUCTLIT(boxvar_lit_FGraph_mkTypeNode)
DLLExport
modelica_metatype omc_FGraph_mkClassNode(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inClass, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_boolean _checkDuplicate);
DLLExport
modelica_metatype boxptr_FGraph_mkClassNode(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inClass, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _checkDuplicate);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_mkClassNode,2,0) {(void*) boxptr_FGraph_mkClassNode,0}};
#define boxvar_FGraph_mkClassNode MMC_REFSTRUCTLIT(boxvar_lit_FGraph_mkClassNode)
DLLExport
modelica_metatype omc_FGraph_mkComponentNode(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inVar, modelica_metatype _inVarEl, modelica_metatype _inMod, modelica_metatype _instStatus, modelica_metatype _inCompGraph);
#define boxptr_FGraph_mkComponentNode omc_FGraph_mkComponentNode
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_mkComponentNode,2,0) {(void*) boxptr_FGraph_mkComponentNode,0}};
#define boxvar_FGraph_mkComponentNode MMC_REFSTRUCTLIT(boxvar_lit_FGraph_mkComponentNode)
DLLExport
modelica_metatype omc_FGraph_pathStripGraphScopePrefix(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inEnv, modelica_boolean _stripPartial);
DLLExport
modelica_metatype boxptr_FGraph_pathStripGraphScopePrefix(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inEnv, modelica_metatype _stripPartial);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_pathStripGraphScopePrefix,2,0) {(void*) boxptr_FGraph_pathStripGraphScopePrefix,0}};
#define boxvar_FGraph_pathStripGraphScopePrefix MMC_REFSTRUCTLIT(boxvar_lit_FGraph_pathStripGraphScopePrefix)
DLLExport
modelica_metatype omc_FGraph_crefStripGraphScopePrefix(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inEnv, modelica_boolean _stripPartial);
DLLExport
modelica_metatype boxptr_FGraph_crefStripGraphScopePrefix(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inEnv, modelica_metatype _stripPartial);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_crefStripGraphScopePrefix,2,0) {(void*) boxptr_FGraph_crefStripGraphScopePrefix,0}};
#define boxvar_FGraph_crefStripGraphScopePrefix MMC_REFSTRUCTLIT(boxvar_lit_FGraph_crefStripGraphScopePrefix)
DLLExport
modelica_boolean omc_FGraph_isTopScope(threadData_t *threadData, modelica_metatype _graph);
DLLExport
modelica_metatype boxptr_FGraph_isTopScope(threadData_t *threadData, modelica_metatype _graph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_isTopScope,2,0) {(void*) boxptr_FGraph_isTopScope,0}};
#define boxvar_FGraph_isTopScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_isTopScope)
DLLExport
modelica_metatype omc_FGraph_scopeTypeToRestriction(threadData_t *threadData, modelica_metatype _inScopeType);
#define boxptr_FGraph_scopeTypeToRestriction omc_FGraph_scopeTypeToRestriction
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_scopeTypeToRestriction,2,0) {(void*) boxptr_FGraph_scopeTypeToRestriction,0}};
#define boxvar_FGraph_scopeTypeToRestriction MMC_REFSTRUCTLIT(boxvar_lit_FGraph_scopeTypeToRestriction)
DLLExport
modelica_metatype omc_FGraph_restrictionToScopeType(threadData_t *threadData, modelica_metatype _inRestriction);
#define boxptr_FGraph_restrictionToScopeType omc_FGraph_restrictionToScopeType
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_restrictionToScopeType,2,0) {(void*) boxptr_FGraph_restrictionToScopeType,0}};
#define boxvar_FGraph_restrictionToScopeType MMC_REFSTRUCTLIT(boxvar_lit_FGraph_restrictionToScopeType)
DLLExport
modelica_metatype omc_FGraph_setScope(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fgraph, modelica_metatype _inScope);
#define boxptr_FGraph_setScope omc_FGraph_setScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_setScope,2,0) {(void*) boxptr_FGraph_setScope,0}};
#define boxvar_FGraph_setScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_setScope)
DLLExport
modelica_metatype omc_FGraph_pushScope(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fgraph, modelica_metatype _inScope);
#define boxptr_FGraph_pushScope omc_FGraph_pushScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_pushScope,2,0) {(void*) boxptr_FGraph_pushScope,0}};
#define boxvar_FGraph_pushScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_pushScope)
DLLExport
modelica_metatype omc_FGraph_pushScopeRef(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fgraph, modelica_metatype _inRef);
#define boxptr_FGraph_pushScopeRef omc_FGraph_pushScopeRef
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_pushScopeRef,2,0) {(void*) boxptr_FGraph_pushScopeRef,0}};
#define boxvar_FGraph_pushScopeRef MMC_REFSTRUCTLIT(boxvar_lit_FGraph_pushScopeRef)
DLLExport
modelica_metatype omc_FGraph_getGraphNameNoImplicitScopes(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_getGraphNameNoImplicitScopes omc_FGraph_getGraphNameNoImplicitScopes
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_getGraphNameNoImplicitScopes,2,0) {(void*) boxptr_FGraph_getGraphNameNoImplicitScopes,0}};
#define boxvar_FGraph_getGraphNameNoImplicitScopes MMC_REFSTRUCTLIT(boxvar_lit_FGraph_getGraphNameNoImplicitScopes)
DLLExport
modelica_metatype omc_FGraph_getGraphName(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_getGraphName omc_FGraph_getGraphName
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_getGraphName,2,0) {(void*) boxptr_FGraph_getGraphName,0}};
#define boxvar_FGraph_getGraphName MMC_REFSTRUCTLIT(boxvar_lit_FGraph_getGraphName)
DLLExport
modelica_string omc_FGraph_getGraphNameStr(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_getGraphNameStr omc_FGraph_getGraphNameStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_getGraphNameStr,2,0) {(void*) boxptr_FGraph_getGraphNameStr,0}};
#define boxvar_FGraph_getGraphNameStr MMC_REFSTRUCTLIT(boxvar_lit_FGraph_getGraphNameStr)
DLLExport
modelica_metatype omc_FGraph_getScopePath(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_getScopePath omc_FGraph_getScopePath
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_getScopePath,2,0) {(void*) boxptr_FGraph_getScopePath,0}};
#define boxvar_FGraph_getScopePath MMC_REFSTRUCTLIT(boxvar_lit_FGraph_getScopePath)
DLLExport
modelica_boolean omc_FGraph_inForOrParforIterLoopScope(threadData_t *threadData, modelica_metatype _inGraph);
DLLExport
modelica_metatype boxptr_FGraph_inForOrParforIterLoopScope(threadData_t *threadData, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_inForOrParforIterLoopScope,2,0) {(void*) boxptr_FGraph_inForOrParforIterLoopScope,0}};
#define boxvar_FGraph_inForOrParforIterLoopScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_inForOrParforIterLoopScope)
DLLExport
modelica_boolean omc_FGraph_inForLoopScope(threadData_t *threadData, modelica_metatype _inGraph);
DLLExport
modelica_metatype boxptr_FGraph_inForLoopScope(threadData_t *threadData, modelica_metatype _inGraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_inForLoopScope,2,0) {(void*) boxptr_FGraph_inForLoopScope,0}};
#define boxvar_FGraph_inForLoopScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_inForLoopScope)
DLLExport
modelica_metatype omc_FGraph_openScope(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _encapsulatedPrefix, modelica_string _inName, modelica_metatype _inScopeType);
#define boxptr_FGraph_openScope omc_FGraph_openScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_openScope,2,0) {(void*) boxptr_FGraph_openScope,0}};
#define boxvar_FGraph_openScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_openScope)
DLLExport
modelica_metatype omc_FGraph_openNewScope(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _encapsulatedPrefix, modelica_metatype _inName, modelica_metatype _inScopeType);
#define boxptr_FGraph_openNewScope omc_FGraph_openNewScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_openNewScope,2,0) {(void*) boxptr_FGraph_openNewScope,0}};
#define boxvar_FGraph_openNewScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_openNewScope)
DLLExport
modelica_string omc_FGraph_printGraphPathStr(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_printGraphPathStr omc_FGraph_printGraphPathStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_printGraphPathStr,2,0) {(void*) boxptr_FGraph_printGraphPathStr,0}};
#define boxvar_FGraph_printGraphPathStr MMC_REFSTRUCTLIT(boxvar_lit_FGraph_printGraphPathStr)
DLLExport
modelica_metatype omc_FGraph_addForIterator(threadData_t *threadData, modelica_metatype _inGraph, modelica_string _name, modelica_metatype _ty, modelica_metatype _binding, modelica_metatype _variability, modelica_metatype _constOfForIteratorRange);
#define boxptr_FGraph_addForIterator omc_FGraph_addForIterator
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_addForIterator,2,0) {(void*) boxptr_FGraph_addForIterator,0}};
#define boxvar_FGraph_addForIterator MMC_REFSTRUCTLIT(boxvar_lit_FGraph_addForIterator)
DLLExport
modelica_metatype omc_FGraph_updateClassElement(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inElement, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _instStatus, modelica_metatype _inTargetGraph);
#define boxptr_FGraph_updateClassElement omc_FGraph_updateClassElement
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_updateClassElement,2,0) {(void*) boxptr_FGraph_updateClassElement,0}};
#define boxvar_FGraph_updateClassElement MMC_REFSTRUCTLIT(boxvar_lit_FGraph_updateClassElement)
DLLExport
modelica_metatype omc_FGraph_updateClass(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inElement, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _instStatus, modelica_metatype _inTargetGraph);
#define boxptr_FGraph_updateClass omc_FGraph_updateClass
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_updateClass,2,0) {(void*) boxptr_FGraph_updateClass,0}};
#define boxvar_FGraph_updateClass MMC_REFSTRUCTLIT(boxvar_lit_FGraph_updateClass)
#define boxptr_FGraph_updateVarAndMod omc_FGraph_updateVarAndMod
DLLExport
modelica_metatype omc_FGraph_updateInstance(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inVar);
#define boxptr_FGraph_updateInstance omc_FGraph_updateInstance
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_updateInstance,2,0) {(void*) boxptr_FGraph_updateInstance,0}};
#define boxvar_FGraph_updateInstance MMC_REFSTRUCTLIT(boxvar_lit_FGraph_updateInstance)
DLLExport
modelica_metatype omc_FGraph_updateSourceTargetScope(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inTargetScope);
#define boxptr_FGraph_updateSourceTargetScope omc_FGraph_updateSourceTargetScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_updateSourceTargetScope,2,0) {(void*) boxptr_FGraph_updateSourceTargetScope,0}};
#define boxvar_FGraph_updateSourceTargetScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_updateSourceTargetScope)
DLLExport
modelica_metatype omc_FGraph_updateComp(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inVar, modelica_metatype _instStatus, modelica_metatype _inTargetGraph);
#define boxptr_FGraph_updateComp omc_FGraph_updateComp
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_updateComp,2,0) {(void*) boxptr_FGraph_updateComp,0}};
#define boxvar_FGraph_updateComp MMC_REFSTRUCTLIT(boxvar_lit_FGraph_updateComp)
DLLExport
modelica_metatype omc_FGraph_clone(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_clone omc_FGraph_clone
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_clone,2,0) {(void*) boxptr_FGraph_clone,0}};
#define boxvar_FGraph_clone MMC_REFSTRUCTLIT(boxvar_lit_FGraph_clone)
DLLExport
modelica_metatype omc_FGraph_node(threadData_t *threadData, modelica_metatype _inGraph, modelica_string _inName, modelica_metatype _inParents, modelica_metatype _inData, modelica_metatype *out_outNode);
#define boxptr_FGraph_node omc_FGraph_node
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_node,2,0) {(void*) boxptr_FGraph_node,0}};
#define boxvar_FGraph_node MMC_REFSTRUCTLIT(boxvar_lit_FGraph_node)
DLLExport
modelica_metatype omc_FGraph_new(threadData_t *threadData, modelica_string _inGraphName, modelica_metatype _inPath);
#define boxptr_FGraph_new omc_FGraph_new
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_new,2,0) {(void*) boxptr_FGraph_new,0}};
#define boxvar_FGraph_new MMC_REFSTRUCTLIT(boxvar_lit_FGraph_new)
DLLExport
modelica_metatype omc_FGraph_empty(threadData_t *threadData);
#define boxptr_FGraph_empty omc_FGraph_empty
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_empty,2,0) {(void*) boxptr_FGraph_empty,0}};
#define boxvar_FGraph_empty MMC_REFSTRUCTLIT(boxvar_lit_FGraph_empty)
DLLExport
modelica_metatype omc_FGraph_topScope(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_topScope omc_FGraph_topScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_topScope,2,0) {(void*) boxptr_FGraph_topScope,0}};
#define boxvar_FGraph_topScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_topScope)
DLLExport
modelica_metatype omc_FGraph_stripLastScopeRef(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype *out_outRef);
#define boxptr_FGraph_stripLastScopeRef omc_FGraph_stripLastScopeRef
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_stripLastScopeRef,2,0) {(void*) boxptr_FGraph_stripLastScopeRef,0}};
#define boxvar_FGraph_stripLastScopeRef MMC_REFSTRUCTLIT(boxvar_lit_FGraph_stripLastScopeRef)
DLLExport
modelica_metatype omc_FGraph_setLastScopeRef(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inGraph);
#define boxptr_FGraph_setLastScopeRef omc_FGraph_setLastScopeRef
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_setLastScopeRef,2,0) {(void*) boxptr_FGraph_setLastScopeRef,0}};
#define boxvar_FGraph_setLastScopeRef MMC_REFSTRUCTLIT(boxvar_lit_FGraph_setLastScopeRef)
DLLExport
modelica_metatype omc_FGraph_lastScopeRef(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_lastScopeRef omc_FGraph_lastScopeRef
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_lastScopeRef,2,0) {(void*) boxptr_FGraph_lastScopeRef,0}};
#define boxvar_FGraph_lastScopeRef MMC_REFSTRUCTLIT(boxvar_lit_FGraph_lastScopeRef)
DLLExport
modelica_metatype omc_FGraph_currentScope(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_currentScope omc_FGraph_currentScope
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_currentScope,2,0) {(void*) boxptr_FGraph_currentScope,0}};
#define boxvar_FGraph_currentScope MMC_REFSTRUCTLIT(boxvar_lit_FGraph_currentScope)
DLLExport
modelica_metatype omc_FGraph_extra(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_extra omc_FGraph_extra
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_extra,2,0) {(void*) boxptr_FGraph_extra,0}};
#define boxvar_FGraph_extra MMC_REFSTRUCTLIT(boxvar_lit_FGraph_extra)
DLLExport
modelica_metatype omc_FGraph_top(threadData_t *threadData, modelica_metatype _inGraph);
#define boxptr_FGraph_top omc_FGraph_top
static const MMC_DEFSTRUCTLIT(boxvar_lit_FGraph_top,2,0) {(void*) boxptr_FGraph_top,0}};
#define boxvar_FGraph_top MMC_REFSTRUCTLIT(boxvar_lit_FGraph_top)
#ifdef __cplusplus
}
#endif
#endif
