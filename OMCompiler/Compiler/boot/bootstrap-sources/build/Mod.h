#ifndef Mod__H
#define Mod__H
#include "meta/meta_modelica.h"
#include "util/modelica.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#ifdef __cplusplus
extern "C" {
#endif
extern struct record_description Absyn_ComponentRef_CREF__IDENT__desc;
extern struct record_description Absyn_Exp_INTEGER__desc;
extern struct record_description Absyn_Subscript_SUBSCRIPT__desc;
extern struct record_description Absyn_TypeSpec_TPATH__desc;
extern struct record_description DAE_Const_C__CONST__desc;
extern struct record_description DAE_EqMod_TYPED__desc;
extern struct record_description DAE_EqMod_UNTYPED__desc;
extern struct record_description DAE_Mod_MOD__desc;
extern struct record_description DAE_Mod_NOMOD__desc;
extern struct record_description DAE_Mod_REDECL__desc;
extern struct record_description DAE_Properties_PROP__desc;
extern struct record_description DAE_SubMod_NAMEMOD__desc;
extern struct record_description DAE_Type_T__UNKNOWN__desc;
extern struct record_description ErrorTypes_Message_MESSAGE__desc;
extern struct record_description ErrorTypes_MessageType_TRANSLATION__desc;
extern struct record_description ErrorTypes_Severity_ERROR__desc;
extern struct record_description ErrorTypes_Severity_WARNING__desc;
extern struct record_description Flags_DebugFlag_DEBUG__FLAG__desc;
extern struct record_description Gettext_TranslatableContent_gettext__desc;
extern struct record_description Mod_FullMod_MOD__desc;
extern struct record_description Mod_FullMod_SUB__MOD__desc;
extern struct record_description Mod_ModScope_COMPONENT__desc;
extern struct record_description SCode_ClassDef_DERIVED__desc;
extern struct record_description SCode_Each_EACH__desc;
extern struct record_description SCode_Element_CLASS__desc;
extern struct record_description SCode_Element_COMPONENT__desc;
extern struct record_description SCode_Final_NOT__FINAL__desc;
extern struct record_description SCode_Mod_MOD__desc;
extern struct record_description SCode_Mod_NOMOD__desc;
extern struct record_description SCode_Mod_REDECL__desc;
extern struct record_description SCode_Prefixes_PREFIXES__desc;
extern struct record_description SCode_SubMod_NAMEMOD__desc;
extern struct record_description SCodeDump_SCodeDumpOptions_OPTIONS__desc;
extern struct record_description SourceInfo_SOURCEINFO__desc;
#define boxptr_Mod_unparseBindingStr omc_Mod_unparseBindingStr
#define boxptr_Mod_unparseSubModStr omc_Mod_unparseSubModStr
DLLExport
modelica_string omc_Mod_unparseModStr(threadData_t *threadData, modelica_metatype _inMod);
#define boxptr_Mod_unparseModStr omc_Mod_unparseModStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_unparseModStr,2,0) {(void*) boxptr_Mod_unparseModStr,0}};
#define boxvar_Mod_unparseModStr MMC_REFSTRUCTLIT(boxvar_lit_Mod_unparseModStr)
#define boxptr_Mod_filterRedeclaresSubMods omc_Mod_filterRedeclaresSubMods
DLLExport
modelica_metatype omc_Mod_filterRedeclares(threadData_t *threadData, modelica_metatype _inMod);
#define boxptr_Mod_filterRedeclares omc_Mod_filterRedeclares
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_filterRedeclares,2,0) {(void*) boxptr_Mod_filterRedeclares,0}};
#define boxvar_Mod_filterRedeclares MMC_REFSTRUCTLIT(boxvar_lit_Mod_filterRedeclares)
#define boxptr_Mod_stripSubModBindings omc_Mod_stripSubModBindings
#define boxptr_Mod_setEqMod omc_Mod_setEqMod
#define boxptr_Mod_subModInfo omc_Mod_subModInfo
#define boxptr_Mod_subModName omc_Mod_subModName
#define boxptr_Mod_subModValue omc_Mod_subModValue
DLLExport
modelica_metatype omc_Mod_getClassModifier(threadData_t *threadData, modelica_metatype _inEnv, modelica_string _inName);
#define boxptr_Mod_getClassModifier omc_Mod_getClassModifier
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_getClassModifier,2,0) {(void*) boxptr_Mod_getClassModifier,0}};
#define boxvar_Mod_getClassModifier MMC_REFSTRUCTLIT(boxvar_lit_Mod_getClassModifier)
DLLExport
modelica_boolean omc_Mod_isRedeclareMod(threadData_t *threadData, modelica_metatype _inMod);
DLLExport
modelica_metatype boxptr_Mod_isRedeclareMod(threadData_t *threadData, modelica_metatype _inMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_isRedeclareMod,2,0) {(void*) boxptr_Mod_isRedeclareMod,0}};
#define boxvar_Mod_isRedeclareMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_isRedeclareMod)
DLLExport
modelica_metatype omc_Mod_getModInfo(threadData_t *threadData, modelica_metatype _inMod);
#define boxptr_Mod_getModInfo omc_Mod_getModInfo
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_getModInfo,2,0) {(void*) boxptr_Mod_getModInfo,0}};
#define boxvar_Mod_getModInfo MMC_REFSTRUCTLIT(boxvar_lit_Mod_getModInfo)
DLLExport
modelica_boolean omc_Mod_isNoMod(threadData_t *threadData, modelica_metatype _inMod);
DLLExport
modelica_metatype boxptr_Mod_isNoMod(threadData_t *threadData, modelica_metatype _inMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_isNoMod,2,0) {(void*) boxptr_Mod_isNoMod,0}};
#define boxvar_Mod_isNoMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_isNoMod)
DLLExport
modelica_boolean omc_Mod_isEmptyMod(threadData_t *threadData, modelica_metatype _inMod);
DLLExport
modelica_metatype boxptr_Mod_isEmptyMod(threadData_t *threadData, modelica_metatype _inMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_isEmptyMod,2,0) {(void*) boxptr_Mod_isEmptyMod,0}};
#define boxvar_Mod_isEmptyMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_isEmptyMod)
DLLExport
modelica_metatype omc_Mod_addEachToSubsIfNeeded(threadData_t *threadData, modelica_metatype _inSubMods, modelica_metatype _inDimensions);
#define boxptr_Mod_addEachToSubsIfNeeded omc_Mod_addEachToSubsIfNeeded
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_addEachToSubsIfNeeded,2,0) {(void*) boxptr_Mod_addEachToSubsIfNeeded,0}};
#define boxvar_Mod_addEachToSubsIfNeeded MMC_REFSTRUCTLIT(boxvar_lit_Mod_addEachToSubsIfNeeded)
DLLExport
modelica_metatype omc_Mod_addEachOneLevel(threadData_t *threadData, modelica_metatype _inMod);
#define boxptr_Mod_addEachOneLevel omc_Mod_addEachOneLevel
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_addEachOneLevel,2,0) {(void*) boxptr_Mod_addEachOneLevel,0}};
#define boxvar_Mod_addEachOneLevel MMC_REFSTRUCTLIT(boxvar_lit_Mod_addEachOneLevel)
DLLExport
modelica_metatype omc_Mod_addEachIfNeeded(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inDimensions);
#define boxptr_Mod_addEachIfNeeded omc_Mod_addEachIfNeeded
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_addEachIfNeeded,2,0) {(void*) boxptr_Mod_addEachIfNeeded,0}};
#define boxvar_Mod_addEachIfNeeded MMC_REFSTRUCTLIT(boxvar_lit_Mod_addEachIfNeeded)
#define boxptr_Mod_removeModInSubs omc_Mod_removeModInSubs
DLLExport
modelica_metatype omc_Mod_removeMod(threadData_t *threadData, modelica_metatype _inMod, modelica_string _componentModified);
#define boxptr_Mod_removeMod omc_Mod_removeMod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_removeMod,2,0) {(void*) boxptr_Mod_removeMod,0}};
#define boxvar_Mod_removeMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_removeMod)
DLLExport
modelica_metatype omc_Mod_removeModList(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _remStrings);
#define boxptr_Mod_removeModList omc_Mod_removeModList
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_removeModList,2,0) {(void*) boxptr_Mod_removeModList,0}};
#define boxvar_Mod_removeModList MMC_REFSTRUCTLIT(boxvar_lit_Mod_removeModList)
#define boxptr_Mod_removeRedecl omc_Mod_removeRedecl
DLLExport
modelica_metatype omc_Mod_removeFirstSubsRedecl(threadData_t *threadData, modelica_metatype _inMod);
#define boxptr_Mod_removeFirstSubsRedecl omc_Mod_removeFirstSubsRedecl
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_removeFirstSubsRedecl,2,0) {(void*) boxptr_Mod_removeFirstSubsRedecl,0}};
#define boxvar_Mod_removeFirstSubsRedecl MMC_REFSTRUCTLIT(boxvar_lit_Mod_removeFirstSubsRedecl)
DLLExport
modelica_metatype omc_Mod_stripSubmod(threadData_t *threadData, modelica_metatype _inMod);
#define boxptr_Mod_stripSubmod omc_Mod_stripSubmod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_stripSubmod,2,0) {(void*) boxptr_Mod_stripSubmod,0}};
#define boxvar_Mod_stripSubmod MMC_REFSTRUCTLIT(boxvar_lit_Mod_stripSubmod)
#define boxptr_Mod_getUntypedCrefFromSubMod omc_Mod_getUntypedCrefFromSubMod
DLLExport
modelica_metatype omc_Mod_getUntypedCrefs(threadData_t *threadData, modelica_metatype _inMod);
#define boxptr_Mod_getUntypedCrefs omc_Mod_getUntypedCrefs
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_getUntypedCrefs,2,0) {(void*) boxptr_Mod_getUntypedCrefs,0}};
#define boxvar_Mod_getUntypedCrefs MMC_REFSTRUCTLIT(boxvar_lit_Mod_getUntypedCrefs)
DLLExport
modelica_boolean omc_Mod_isUntypedMod(threadData_t *threadData, modelica_metatype _inMod);
DLLExport
modelica_metatype boxptr_Mod_isUntypedMod(threadData_t *threadData, modelica_metatype _inMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_isUntypedMod,2,0) {(void*) boxptr_Mod_isUntypedMod,0}};
#define boxvar_Mod_isUntypedMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_isUntypedMod)
#define boxptr_Mod_getUnelabedSubMod2 omc_Mod_getUnelabedSubMod2
DLLExport
modelica_metatype omc_Mod_getUnelabedSubMod(threadData_t *threadData, modelica_metatype _inMod, modelica_string _inIdent);
#define boxptr_Mod_getUnelabedSubMod omc_Mod_getUnelabedSubMod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_getUnelabedSubMod,2,0) {(void*) boxptr_Mod_getUnelabedSubMod,0}};
#define boxvar_Mod_getUnelabedSubMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_getUnelabedSubMod)
#define boxptr_Mod_getFullModsFromSubMods omc_Mod_getFullModsFromSubMods
#define boxptr_Mod_getFullModFromModRedeclare omc_Mod_getFullModFromModRedeclare
#define boxptr_Mod_getFullModsFromMod omc_Mod_getFullModsFromMod
DLLExport
modelica_boolean omc_Mod_emptyModOrEquality(threadData_t *threadData, modelica_metatype _mod);
DLLExport
modelica_metatype boxptr_Mod_emptyModOrEquality(threadData_t *threadData, modelica_metatype _mod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_emptyModOrEquality,2,0) {(void*) boxptr_Mod_emptyModOrEquality,0}};
#define boxvar_Mod_emptyModOrEquality MMC_REFSTRUCTLIT(boxvar_lit_Mod_emptyModOrEquality)
DLLExport
modelica_metatype omc_Mod_renameNamedSubMod(threadData_t *threadData, modelica_metatype _submod, modelica_string _oldIdent, modelica_string _newIdent);
#define boxptr_Mod_renameNamedSubMod omc_Mod_renameNamedSubMod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_renameNamedSubMod,2,0) {(void*) boxptr_Mod_renameNamedSubMod,0}};
#define boxvar_Mod_renameNamedSubMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_renameNamedSubMod)
DLLExport
modelica_metatype omc_Mod_renameTopLevelNamedSubMod(threadData_t *threadData, modelica_metatype _mod, modelica_string _oldIdent, modelica_string _newIdent);
#define boxptr_Mod_renameTopLevelNamedSubMod omc_Mod_renameTopLevelNamedSubMod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_renameTopLevelNamedSubMod,2,0) {(void*) boxptr_Mod_renameTopLevelNamedSubMod,0}};
#define boxvar_Mod_renameTopLevelNamedSubMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_renameTopLevelNamedSubMod)
#define boxptr_Mod_printEqmodStr omc_Mod_printEqmodStr
#define boxptr_Mod_printSubStr omc_Mod_printSubStr
DLLExport
modelica_metatype omc_Mod_printSubs1Str(threadData_t *threadData, modelica_metatype _inTypesSubModLst);
#define boxptr_Mod_printSubs1Str omc_Mod_printSubs1Str
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_printSubs1Str,2,0) {(void*) boxptr_Mod_printSubs1Str,0}};
#define boxvar_Mod_printSubs1Str MMC_REFSTRUCTLIT(boxvar_lit_Mod_printSubs1Str)
DLLExport
modelica_string omc_Mod_prettyPrintSubmod(threadData_t *threadData, modelica_metatype _inSub);
#define boxptr_Mod_prettyPrintSubmod omc_Mod_prettyPrintSubmod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_prettyPrintSubmod,2,0) {(void*) boxptr_Mod_prettyPrintSubmod,0}};
#define boxvar_Mod_prettyPrintSubmod MMC_REFSTRUCTLIT(boxvar_lit_Mod_prettyPrintSubmod)
DLLExport
modelica_string omc_Mod_prettyPrintMod(threadData_t *threadData, modelica_metatype _m, modelica_integer _depth);
DLLExport
modelica_metatype boxptr_Mod_prettyPrintMod(threadData_t *threadData, modelica_metatype _m, modelica_metatype _depth);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_prettyPrintMod,2,0) {(void*) boxptr_Mod_prettyPrintMod,0}};
#define boxvar_Mod_prettyPrintMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_prettyPrintMod)
DLLExport
void omc_Mod_printMod(threadData_t *threadData, modelica_metatype _m);
#define boxptr_Mod_printMod omc_Mod_printMod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_printMod,2,0) {(void*) boxptr_Mod_printMod,0}};
#define boxvar_Mod_printMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_printMod)
DLLExport
modelica_string omc_Mod_printModStr(threadData_t *threadData, modelica_metatype _inMod);
#define boxptr_Mod_printModStr omc_Mod_printModStr
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_printModStr,2,0) {(void*) boxptr_Mod_printModStr,0}};
#define boxvar_Mod_printModStr MMC_REFSTRUCTLIT(boxvar_lit_Mod_printModStr)
DLLExport
modelica_boolean omc_Mod_subModEqual(threadData_t *threadData, modelica_metatype _subMod1, modelica_metatype _subMod2);
DLLExport
modelica_metatype boxptr_Mod_subModEqual(threadData_t *threadData, modelica_metatype _subMod1, modelica_metatype _subMod2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_subModEqual,2,0) {(void*) boxptr_Mod_subModEqual,0}};
#define boxvar_Mod_subModEqual MMC_REFSTRUCTLIT(boxvar_lit_Mod_subModEqual)
DLLExport
modelica_boolean omc_Mod_modEqual(threadData_t *threadData, modelica_metatype _mod1, modelica_metatype _mod2);
DLLExport
modelica_metatype boxptr_Mod_modEqual(threadData_t *threadData, modelica_metatype _mod1, modelica_metatype _mod2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_modEqual,2,0) {(void*) boxptr_Mod_modEqual,0}};
#define boxvar_Mod_modEqual MMC_REFSTRUCTLIT(boxvar_lit_Mod_modEqual)
DLLExport
modelica_metatype omc_Mod_modEquation(threadData_t *threadData, modelica_metatype _inMod);
#define boxptr_Mod_modEquation omc_Mod_modEquation
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_modEquation,2,0) {(void*) boxptr_Mod_modEquation,0}};
#define boxvar_Mod_modEquation MMC_REFSTRUCTLIT(boxvar_lit_Mod_modEquation)
#define boxptr_Mod_mergeEq omc_Mod_mergeEq
DLLExport
modelica_boolean omc_Mod_isFinalMod(threadData_t *threadData, modelica_metatype _inMod1);
DLLExport
modelica_metatype boxptr_Mod_isFinalMod(threadData_t *threadData, modelica_metatype _inMod1);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_isFinalMod,2,0) {(void*) boxptr_Mod_isFinalMod,0}};
#define boxvar_Mod_isFinalMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_isFinalMod)
DLLExport
modelica_metatype omc_Mod_merge(threadData_t *threadData, modelica_metatype _inModOuter, modelica_metatype _inModInner, modelica_string _inElementName, modelica_boolean _inCheckFinal);
DLLExport
modelica_metatype boxptr_Mod_merge(threadData_t *threadData, modelica_metatype _inModOuter, modelica_metatype _inModInner, modelica_metatype _inElementName, modelica_metatype _inCheckFinal);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_merge,2,0) {(void*) boxptr_Mod_merge,0}};
#define boxvar_Mod_merge MMC_REFSTRUCTLIT(boxvar_lit_Mod_merge)
#define boxptr_Mod_indexEqmod omc_Mod_indexEqmod
#define boxptr_Mod_lookupIdxModification3 omc_Mod_lookupIdxModification3
#define boxptr_Mod_lookupIdxModification2 omc_Mod_lookupIdxModification2
DLLExport
modelica_metatype omc_Mod_lookupIdxModification(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inIndex);
#define boxptr_Mod_lookupIdxModification omc_Mod_lookupIdxModification
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_lookupIdxModification,2,0) {(void*) boxptr_Mod_lookupIdxModification,0}};
#define boxvar_Mod_lookupIdxModification MMC_REFSTRUCTLIT(boxvar_lit_Mod_lookupIdxModification)
#define boxptr_Mod_lookupCompModification2 omc_Mod_lookupCompModification2
DLLExport
modelica_string omc_Mod_printSubsStr(threadData_t *threadData, modelica_metatype _inSubMods, modelica_boolean _addParan);
DLLExport
modelica_metatype boxptr_Mod_printSubsStr(threadData_t *threadData, modelica_metatype _inSubMods, modelica_metatype _addParan);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_printSubsStr,2,0) {(void*) boxptr_Mod_printSubsStr,0}};
#define boxvar_Mod_printSubsStr MMC_REFSTRUCTLIT(boxvar_lit_Mod_printSubsStr)
#define boxptr_Mod_lookupNamedSubMod omc_Mod_lookupNamedSubMod
#define boxptr_Mod_mergeRedeclareWithBinding omc_Mod_mergeRedeclareWithBinding
#define boxptr_Mod_checkDuplicateModifications2 omc_Mod_checkDuplicateModifications2
#define boxptr_Mod_checkDuplicateModifications omc_Mod_checkDuplicateModifications
#define boxptr_Mod_lookupComplexCompModification omc_Mod_lookupComplexCompModification
#define boxptr_Mod_selectEqMod omc_Mod_selectEqMod
DLLExport
modelica_metatype omc_Mod_lookupCompModificationFromEqu(threadData_t *threadData, modelica_metatype _inMod, modelica_string _inIdent);
#define boxptr_Mod_lookupCompModificationFromEqu omc_Mod_lookupCompModificationFromEqu
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_lookupCompModificationFromEqu,2,0) {(void*) boxptr_Mod_lookupCompModificationFromEqu,0}};
#define boxvar_Mod_lookupCompModificationFromEqu MMC_REFSTRUCTLIT(boxvar_lit_Mod_lookupCompModificationFromEqu)
#define boxptr_Mod_mergeSubMods omc_Mod_mergeSubMods
#define boxptr_Mod_mergeModifiers omc_Mod_mergeModifiers
DLLExport
modelica_metatype omc_Mod_getModifs(threadData_t *threadData, modelica_metatype _inMods, modelica_string _inName, modelica_metatype _inSMod);
#define boxptr_Mod_getModifs omc_Mod_getModifs
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_getModifs,2,0) {(void*) boxptr_Mod_getModifs,0}};
#define boxvar_Mod_getModifs MMC_REFSTRUCTLIT(boxvar_lit_Mod_getModifs)
DLLExport
modelica_metatype omc_Mod_lookupCompModification(threadData_t *threadData, modelica_metatype _inMod, modelica_string _inIdent);
#define boxptr_Mod_lookupCompModification omc_Mod_lookupCompModification
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_lookupCompModification,2,0) {(void*) boxptr_Mod_lookupCompModification,0}};
#define boxvar_Mod_lookupCompModification MMC_REFSTRUCTLIT(boxvar_lit_Mod_lookupCompModification)
DLLExport
modelica_metatype omc_Mod_lookupModificationP(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inPath);
#define boxptr_Mod_lookupModificationP omc_Mod_lookupModificationP
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_lookupModificationP,2,0) {(void*) boxptr_Mod_lookupModificationP,0}};
#define boxvar_Mod_lookupModificationP MMC_REFSTRUCTLIT(boxvar_lit_Mod_lookupModificationP)
#define boxptr_Mod_elabUntypedSubmod omc_Mod_elabUntypedSubmod
#define boxptr_Mod_elabUntypedSubmods omc_Mod_elabUntypedSubmods
#define boxptr_Mod_printModScope omc_Mod_printModScope
#define boxptr_Mod_mergeSubModsInSameScope omc_Mod_mergeSubModsInSameScope
#define boxptr_Mod_compactSubMod omc_Mod_compactSubMod
#define boxptr_Mod_compactSubMods omc_Mod_compactSubMods
DLLExport
modelica_metatype omc_Mod_elabUntypedMod(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _inModScope);
#define boxptr_Mod_elabUntypedMod omc_Mod_elabUntypedMod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_elabUntypedMod,2,0) {(void*) boxptr_Mod_elabUntypedMod,0}};
#define boxvar_Mod_elabUntypedMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_elabUntypedMod)
DLLExport
modelica_metatype omc_Mod_updateMod(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_boolean _inBoolean, modelica_metatype _inInfo, modelica_metatype *out_outMod);
DLLExport
modelica_metatype boxptr_Mod_updateMod(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _inBoolean, modelica_metatype _inInfo, modelica_metatype *out_outMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_updateMod,2,0) {(void*) boxptr_Mod_updateMod,0}};
#define boxvar_Mod_updateMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_updateMod)
#define boxptr_Mod_unelabSubscript omc_Mod_unelabSubscript
#define boxptr_Mod_unelabSubmods omc_Mod_unelabSubmods
DLLExport
modelica_metatype omc_Mod_unelabMod(threadData_t *threadData, modelica_metatype _inMod);
#define boxptr_Mod_unelabMod omc_Mod_unelabMod
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_unelabMod,2,0) {(void*) boxptr_Mod_unelabMod,0}};
#define boxvar_Mod_unelabMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_unelabMod)
#define boxptr_Mod_checkIfSubmodsAreBasicTypeMods omc_Mod_checkIfSubmodsAreBasicTypeMods
#define boxptr_Mod_checkIfModsAreBasicTypeMods omc_Mod_checkIfModsAreBasicTypeMods
DLLExport
modelica_metatype omc_Mod_elabModForBasicType(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_boolean _inBoolean, modelica_metatype _inModScope, modelica_metatype _info, modelica_metatype *out_outMod);
DLLExport
modelica_metatype boxptr_Mod_elabModForBasicType(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _inBoolean, modelica_metatype _inModScope, modelica_metatype _info, modelica_metatype *out_outMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_elabModForBasicType,2,0) {(void*) boxptr_Mod_elabModForBasicType,0}};
#define boxvar_Mod_elabModForBasicType MMC_REFSTRUCTLIT(boxvar_lit_Mod_elabModForBasicType)
DLLExport
modelica_boolean omc_Mod_isInvariantDAEMod(threadData_t *threadData, modelica_metatype _mod);
DLLExport
modelica_metatype boxptr_Mod_isInvariantDAEMod(threadData_t *threadData, modelica_metatype _mod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_isInvariantDAEMod,2,0) {(void*) boxptr_Mod_isInvariantDAEMod,0}};
#define boxvar_Mod_isInvariantDAEMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_isInvariantDAEMod)
DLLExport
modelica_boolean omc_Mod_isInvariantMod(threadData_t *threadData, modelica_metatype _mod);
DLLExport
modelica_metatype boxptr_Mod_isInvariantMod(threadData_t *threadData, modelica_metatype _mod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_isInvariantMod,2,0) {(void*) boxptr_Mod_isInvariantMod,0}};
#define boxvar_Mod_isInvariantMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_isInvariantMod)
DLLExport
modelica_metatype omc_Mod_elabMod(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_boolean _inBoolean, modelica_metatype _inModScope, modelica_metatype _inInfo, modelica_metatype *out_outMod);
DLLExport
modelica_metatype boxptr_Mod_elabMod(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIH, modelica_metatype _inPrefix, modelica_metatype _inMod, modelica_metatype _inBoolean, modelica_metatype _inModScope, modelica_metatype _inInfo, modelica_metatype *out_outMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Mod_elabMod,2,0) {(void*) boxptr_Mod_elabMod,0}};
#define boxvar_Mod_elabMod MMC_REFSTRUCTLIT(boxvar_lit_Mod_elabMod)
#ifdef __cplusplus
}
#endif
#endif
