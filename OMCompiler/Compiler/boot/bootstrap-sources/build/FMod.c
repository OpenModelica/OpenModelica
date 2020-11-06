#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/FMod.c"
#endif
#include "omc_simulation_settings.h"
#include "FMod.h"
#define _OMC_LIT0_data "component "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,10,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "extends "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,8,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,1,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "inherited class "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,16,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "class extends class "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,20,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "constrainedby class "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,20,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "Duplicate modification of element %s on %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,43,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT8}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(103)),_OMC_LIT6,_OMC_LIT7,_OMC_LIT9}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
#include "util/modelica.h"
#include "FMod_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_string omc_FMod_printModScope(threadData_t *threadData, modelica_metatype _inModScope);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FMod_printModScope,2,0) {(void*) boxptr_FMod_printModScope,0}};
#define boxvar_FMod_printModScope MMC_REFSTRUCTLIT(boxvar_lit_FMod_printModScope)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FMod_mergeSubModsInSameScope(threadData_t *threadData, modelica_metatype _inMod1, modelica_metatype _inMod2, modelica_metatype _inElementName, modelica_metatype _inModScope);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FMod_mergeSubModsInSameScope,2,0) {(void*) boxptr_FMod_mergeSubModsInSameScope,0}};
#define boxvar_FMod_mergeSubModsInSameScope MMC_REFSTRUCTLIT(boxvar_lit_FMod_mergeSubModsInSameScope)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FMod_compactSubMod2(threadData_t *threadData, modelica_metatype _inExistingMod, modelica_metatype _inNewMod, modelica_metatype _inModScope, modelica_metatype _inName, modelica_boolean *out_outFound);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FMod_compactSubMod2(threadData_t *threadData, modelica_metatype _inExistingMod, modelica_metatype _inNewMod, modelica_metatype _inModScope, modelica_metatype _inName, modelica_metatype *out_outFound);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FMod_compactSubMod2,2,0) {(void*) boxptr_FMod_compactSubMod2,0}};
#define boxvar_FMod_compactSubMod2 MMC_REFSTRUCTLIT(boxvar_lit_FMod_compactSubMod2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FMod_compactSubMod(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inModScope, modelica_metatype _inName, modelica_metatype _inAccumMods);
static const MMC_DEFSTRUCTLIT(boxvar_lit_FMod_compactSubMod,2,0) {(void*) boxptr_FMod_compactSubMod,0}};
#define boxvar_FMod_compactSubMod MMC_REFSTRUCTLIT(boxvar_lit_FMod_compactSubMod)
PROTECTED_FUNCTION_STATIC modelica_string omc_FMod_printModScope(threadData_t *threadData, modelica_metatype _inModScope)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inModScope;
{
modelica_string _name = NULL;
modelica_metatype _path = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta[0];
tmpMeta[0] = stringAppend(_OMC_LIT0,_name);
tmp1 = tmpMeta[0];
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta[0];
tmpMeta[0] = stringAppend(_OMC_LIT1,omc_AbsynUtil_pathString(threadData, _path, _OMC_LIT2, 1, 0));
tmp1 = tmpMeta[0];
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta[0];
tmpMeta[0] = stringAppend(_OMC_LIT3,omc_AbsynUtil_pathString(threadData, _path, _OMC_LIT2, 1, 0));
tmp1 = tmpMeta[0];
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta[0];
tmpMeta[0] = stringAppend(_OMC_LIT4,_name);
tmp1 = tmpMeta[0];
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta[0];
tmpMeta[0] = stringAppend(_OMC_LIT5,omc_AbsynUtil_pathString(threadData, _path, _OMC_LIT2, 1, 0));
tmp1 = tmpMeta[0];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FMod_mergeSubModsInSameScope(threadData_t *threadData, modelica_metatype _inMod1, modelica_metatype _inMod2, modelica_metatype _inElementName, modelica_metatype _inModScope)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[11] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inMod1;
tmp3_2 = _inMod2;
{
modelica_string _id = NULL;
modelica_string _scope = NULL;
modelica_string _name = NULL;
modelica_metatype _fp = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _submods1 = NULL;
modelica_metatype _submods2 = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _info1 = NULL;
modelica_metatype _info2 = NULL;
modelica_metatype _mod1 = NULL;
modelica_metatype _mod2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,5) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],0,5) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 4));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 5));
if (!optionNone(tmpMeta[10])) goto tmp2_end;
_id = tmpMeta[1];
_fp = tmpMeta[3];
_ep = tmpMeta[4];
_submods1 = tmpMeta[5];
_binding = tmpMeta[6];
_info1 = tmpMeta[7];
_submods2 = tmpMeta[9];
_submods1 = omc_List_fold2(threadData, _submods1, boxvar_FMod_compactSubMod, _inModScope, _inElementName, _submods2);
tmpMeta[1] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _fp, _ep, _submods1, _binding, _info1);
tmpMeta[2] = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _id, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,5) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],0,5) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 4));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 5));
if (!optionNone(tmpMeta[10])) goto tmp2_end;
_id = tmpMeta[1];
_fp = tmpMeta[3];
_ep = tmpMeta[4];
_submods2 = tmpMeta[5];
_binding = tmpMeta[6];
_info2 = tmpMeta[7];
_submods1 = tmpMeta[9];
_submods1 = omc_List_fold2(threadData, _submods1, boxvar_FMod_compactSubMod, _inModScope, _inElementName, _submods2);
tmpMeta[1] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _fp, _ep, _submods1, _binding, _info2);
tmpMeta[2] = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _id, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 2: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
_mod1 = tmpMeta[1];
_mod2 = tmpMeta[2];
_info1 = omc_SCodeUtil_getModifierInfo(threadData, _mod1);
_info2 = omc_SCodeUtil_getModifierInfo(threadData, _mod2);
_scope = omc_FMod_printModScope(threadData, _inModScope);
_name = stringDelimitList(listReverse(_inElementName), _OMC_LIT2);
tmpMeta[1] = mmc_mk_cons(_name, mmc_mk_cons(_scope, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[2] = mmc_mk_cons(_info2, mmc_mk_cons(_info1, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMultiSourceMessage(threadData, _OMC_LIT10, tmpMeta[1], tmpMeta[2]);
goto goto_1;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FMod_compactSubMod2(threadData_t *threadData, modelica_metatype _inExistingMod, modelica_metatype _inNewMod, modelica_metatype _inModScope, modelica_metatype _inName, modelica_boolean *out_outFound)
{
modelica_metatype _outMod = NULL;
modelica_boolean _outFound;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExistingMod;
tmp4_2 = _inNewMod;
{
modelica_string _name1 = NULL;
modelica_string _name2 = NULL;
modelica_metatype _submod = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_name1 = tmpMeta[2];
_name2 = tmpMeta[3];
tmp6 = (stringEqual(_name1, _name2));
if (0 != tmp6) goto goto_2;
tmpMeta[0+0] = _inExistingMod;
tmp1_c1 = 0;
goto tmp3_done;
}
case 1: {
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name1 = tmpMeta[2];
tmpMeta[2] = mmc_mk_cons(_name1, _inName);
_submod = omc_FMod_mergeSubModsInSameScope(threadData, _inExistingMod, _inNewMod, tmpMeta[2], _inModScope);
tmpMeta[0+0] = _submod;
tmp1_c1 = 1;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outMod = tmpMeta[0+0];
_outFound = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outFound) { *out_outFound = _outFound; }
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_FMod_compactSubMod2(threadData_t *threadData, modelica_metatype _inExistingMod, modelica_metatype _inNewMod, modelica_metatype _inModScope, modelica_metatype _inName, modelica_metatype *out_outFound)
{
modelica_boolean _outFound;
modelica_metatype _outMod = NULL;
_outMod = omc_FMod_compactSubMod2(threadData, _inExistingMod, _inNewMod, _inModScope, _inName, &_outFound);
if (out_outFound) { *out_outFound = mmc_mk_icon(_outFound); }
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_FMod_compactSubMod(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inModScope, modelica_metatype _inName, modelica_metatype _inAccumMods)
{
modelica_metatype _outSubMods = NULL;
modelica_string _name = NULL;
modelica_metatype _submods = NULL;
modelica_boolean _found;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inSubMod;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_name = tmpMeta[1];
_submods = omc_List_findMap3(threadData, _inAccumMods, boxvar_FMod_compactSubMod2, _inSubMod, _inModScope, _inName ,&_found);
_outSubMods = omc_List_consOnTrue(threadData, (!_found), _inSubMod, _submods);
_return: OMC_LABEL_UNUSED
return _outSubMods;
}
DLLExport
modelica_metatype omc_FMod_compactSubMods(threadData_t *threadData, modelica_metatype _inSubMods, modelica_metatype _inModScope)
{
modelica_metatype _outSubMods = NULL;
modelica_metatype _submods = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_submods = omc_List_fold2(threadData, _inSubMods, boxvar_FMod_compactSubMod, _inModScope, tmpMeta[0], tmpMeta[1]);
_outSubMods = listReverse(_submods);
_return: OMC_LABEL_UNUSED
return _outSubMods;
}
DLLExport
modelica_metatype omc_FMod_apply(threadData_t *threadData, modelica_metatype _inTargetRef, modelica_metatype _inModRef, modelica_metatype _inGraph, modelica_metatype *out_outNodeRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outNodeRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inTargetRef;
tmp4_2 = _inGraph;
{
modelica_metatype _r = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_r = tmp4_1;
_g = tmp4_2;
tmpMeta[0+0] = _g;
tmpMeta[0+1] = _r;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta[0+0];
_outNodeRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outNodeRef) { *out_outNodeRef = _outNodeRef; }
return _outGraph;
}
DLLExport
modelica_metatype omc_FMod_merge(threadData_t *threadData, modelica_metatype _inParentRef, modelica_metatype _inOuterModRef, modelica_metatype _inInnerModRef, modelica_metatype _inGraph, modelica_metatype *out_outMergedModRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outMergedModRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inParentRef;
tmp4_2 = _inGraph;
{
modelica_metatype _r = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_r = tmp4_1;
_g = tmp4_2;
tmpMeta[0+0] = _g;
tmpMeta[0+1] = _r;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta[0+0];
_outMergedModRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outMergedModRef) { *out_outMergedModRef = _outMergedModRef; }
return _outGraph;
}
