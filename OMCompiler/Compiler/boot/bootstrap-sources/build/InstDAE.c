#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "InstDAE.c"
#endif
#include "omc_simulation_settings.h"
#include "InstDAE.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,2,3) {&DAE_Type_T__INTEGER__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,2,4) {&DAE_Type_T__REAL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,2,6) {&DAE_Type_T__BOOL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,2,7) {&DAE_Type_T__CLOCK__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,2,5) {&DAE_Type_T__STRING__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,2,3) {&DAE_DAElist_DAE__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,1,5) {&DAE_Mod_NOMOD__desc,}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "Dimensions must be parameter or constant expression (in %s)."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,60,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT9}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(23)),_OMC_LIT7,_OMC_LIT8,_OMC_LIT10}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "showDaeGeneration"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,17,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "Show the dae variable declarations as they happen."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,50,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT13}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(112)),_OMC_LIT12,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT14}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "'"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,1,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,0,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT18,0.0);
#define _OMC_LIT18 MMC_REFREALLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT17,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,1,4) {&DAE_ComponentPrefix_NOCOMPPRE__desc,}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,8,3) {&DAE_ElementSource_SOURCE__desc,_OMC_LIT19,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT20,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data " partial"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,8,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data " full"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,5,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "DAE: parent: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,13,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data " class: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,8,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data " state: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,8,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,1,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,1,5) {&DAE_AvlTreePathFunction_Tree_EMPTY__desc,}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "DAE: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,5,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data " - could not print\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,19,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,9,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,41,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT32}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT31,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT33}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "- Inst.daeDeclare failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,25,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
#include "util/modelica.h"
#include "InstDAE_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstDAE_daeDeclare2(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inType, modelica_metatype _inConnectorType, modelica_metatype _inVarKind, modelica_metatype _inVarDirection, modelica_metatype _inParallelism, modelica_metatype _protection, modelica_metatype _inExpExpOption, modelica_metatype _inInstDims, modelica_metatype _inStartValue, modelica_metatype _inAttr, modelica_metatype _inComment, modelica_metatype _io, modelica_metatype _source, modelica_boolean _declareComplexVars);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstDAE_daeDeclare2(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inType, modelica_metatype _inConnectorType, modelica_metatype _inVarKind, modelica_metatype _inVarDirection, modelica_metatype _inParallelism, modelica_metatype _protection, modelica_metatype _inExpExpOption, modelica_metatype _inInstDims, modelica_metatype _inStartValue, modelica_metatype _inAttr, modelica_metatype _inComment, modelica_metatype _io, modelica_metatype _source, modelica_metatype _declareComplexVars);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstDAE_daeDeclare2,2,0) {(void*) boxptr_InstDAE_daeDeclare2,0}};
#define boxvar_InstDAE_daeDeclare2 MMC_REFSTRUCTLIT(boxvar_lit_InstDAE_daeDeclare2)
PROTECTED_FUNCTION_STATIC void omc_InstDAE_showDAE(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inParentEnv, modelica_metatype _inClassEnv, modelica_metatype _inState, modelica_metatype _inDAE);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstDAE_showDAE,2,0) {(void*) boxptr_InstDAE_showDAE,0}};
#define boxvar_InstDAE_showDAE MMC_REFSTRUCTLIT(boxvar_lit_InstDAE_showDAE)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstDAE_daeDeclare2(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inType, modelica_metatype _inConnectorType, modelica_metatype _inVarKind, modelica_metatype _inVarDirection, modelica_metatype _inParallelism, modelica_metatype _protection, modelica_metatype _inExpExpOption, modelica_metatype _inInstDims, modelica_metatype _inStartValue, modelica_metatype _inAttr, modelica_metatype _inComment, modelica_metatype _io, modelica_metatype _source, modelica_boolean _declareComplexVars)
{
modelica_metatype _outDAe = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;volatile modelica_metatype tmp4_6;volatile modelica_metatype tmp4_7;volatile modelica_metatype tmp4_8;volatile modelica_metatype tmp4_9;volatile modelica_metatype tmp4_10;volatile modelica_metatype tmp4_11;volatile modelica_metatype tmp4_12;volatile modelica_boolean tmp4_13;
tmp4_1 = _inComponentRef;
tmp4_2 = _inType;
tmp4_3 = _inConnectorType;
tmp4_4 = _inVarKind;
tmp4_5 = _inVarDirection;
tmp4_6 = _inParallelism;
tmp4_7 = _protection;
tmp4_8 = _inExpExpOption;
tmp4_9 = _inInstDims;
tmp4_10 = _inStartValue;
tmp4_11 = _inAttr;
tmp4_12 = _inComment;
tmp4_13 = _declareComplexVars;
{
modelica_metatype _vn = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _kind = NULL;
modelica_metatype _dir = NULL;
modelica_metatype _daePrl = NULL;
modelica_metatype _e = NULL;
modelica_metatype _start = NULL;
modelica_metatype _inst_dims = NULL;
modelica_metatype _dae_var_attr = NULL;
modelica_metatype _comment = NULL;
modelica_string _s = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _prot = NULL;
modelica_metatype _finst_dims = NULL;
modelica_metatype _path = NULL;
modelica_metatype _tty = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 16; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
_vn = tmp4_1;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
tmp4 += 13;
_finst_dims = omc_List_flatten(threadData, _inst_dims);
tmpMeta7 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _vn, _kind, _dir, _daePrl, _prot, _OMC_LIT0, _e, _finst_dims, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta6 = mmc_mk_cons(tmpMeta7, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta8 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta6);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
_vn = tmp4_1;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
tmp4 += 12;
_finst_dims = omc_List_flatten(threadData, _inst_dims);
tmpMeta10 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _vn, _kind, _dir, _daePrl, _prot, _OMC_LIT1, _e, _finst_dims, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta9 = mmc_mk_cons(tmpMeta10, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta11 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta9);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
_vn = tmp4_1;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
tmp4 += 11;
_finst_dims = omc_List_flatten(threadData, _inst_dims);
tmpMeta13 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _vn, _kind, _dir, _daePrl, _prot, _OMC_LIT2, _e, _finst_dims, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta12 = mmc_mk_cons(tmpMeta13, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta14 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta12);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,1) == 0) goto tmp3_end;
_vn = tmp4_1;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
tmp4 += 10;
_finst_dims = omc_List_flatten(threadData, _inst_dims);
tmpMeta16 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _vn, _kind, _dir, _daePrl, _prot, _OMC_LIT3, _e, _finst_dims, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta15 = mmc_mk_cons(tmpMeta16, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta17 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta15);
tmpMeta1 = tmpMeta17;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
_vn = tmp4_1;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
tmp4 += 9;
_finst_dims = omc_List_flatten(threadData, _inst_dims);
tmpMeta19 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _vn, _kind, _dir, _daePrl, _prot, _OMC_LIT4, _e, _finst_dims, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta18 = mmc_mk_cons(tmpMeta19, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta20 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta18);
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,5) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (optionNone(tmpMeta21)) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 1));
tmpMeta1 = _OMC_LIT5;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,5) == 0) goto tmp3_end;
_ty = tmp4_2;
_vn = tmp4_1;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
tmp4 += 7;
_finst_dims = omc_List_flatten(threadData, _inst_dims);
tmpMeta24 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _vn, _kind, _dir, _daePrl, _prot, _ty, _e, _finst_dims, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta23 = mmc_mk_cons(tmpMeta24, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta25 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta23);
tmpMeta1 = tmpMeta25;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,3) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,17,1) == 0) goto tmp3_end;
_ty = tmp4_2;
_vn = tmp4_1;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
tmp4 += 6;
_finst_dims = omc_List_flatten(threadData, _inst_dims);
tmpMeta28 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _vn, _kind, _dir, _daePrl, _prot, _ty, _e, _finst_dims, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta27 = mmc_mk_cons(tmpMeta28, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta29 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta27);
tmpMeta1 = tmpMeta29;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,10,4) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_tp = tmpMeta30;
_vn = tmp4_1;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_start = tmp4_10;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
tmp4 += 5;
tmpMeta31 = MMC_REFSTRUCTLIT(mmc_nil);
omc_InstBinding_instDaeVariableAttributes(threadData, omc_FCore_emptyCache(threadData), omc_FGraph_empty(threadData), _OMC_LIT6, _tp, tmpMeta31 ,&_dae_var_attr);
tmpMeta1 = omc_InstDAE_daeDeclare2(threadData, _vn, _tp, _ct, _kind, _dir, _daePrl, _prot, _e, _inst_dims, _start, _dae_var_attr, _comment, _io, _source, _declareComplexVars);
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,2) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta33)) goto tmp3_end;
tmpMeta34 = MMC_CAR(tmpMeta33);
tmpMeta35 = MMC_CDR(tmpMeta33);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,0,1) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta35)) goto tmp3_end;
_tp = tmpMeta32;
_vn = tmp4_1;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_start = tmp4_10;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
tmpMeta1 = omc_InstDAE_daeDeclare2(threadData, _vn, _tp, _ct, _kind, _dir, _daePrl, _prot, _e, _inst_dims, _start, _dae_var_attr, _comment, _io, _source, _declareComplexVars);
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta36;
modelica_boolean tmp37;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,2) == 0) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_tp = tmpMeta36;
_vn = tmp4_1;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_start = tmp4_10;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
tmp37 = omc_Config_splitArrays(threadData);
if (0 != tmp37) goto goto_2;
tmpMeta1 = omc_InstDAE_daeDeclare2(threadData, _vn, _tp, _ct, _kind, _dir, _daePrl, _prot, _e, _inst_dims, _start, _dae_var_attr, _comment, _io, _source, _declareComplexVars);
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_boolean tmp41;
modelica_metatype tmpMeta42;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,2) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta38)) goto tmp3_end;
tmpMeta39 = MMC_CAR(tmpMeta38);
tmpMeta40 = MMC_CDR(tmpMeta38);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,4,0) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta40)) goto tmp3_end;
_vn = tmp4_1;
tmp4 += 2;
tmp41 = omc_Config_splitArrays(threadData);
if (1 != tmp41) goto goto_2;
_s = omc_ComponentReference_printComponentRefStr(threadData, _vn);
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _source);
tmpMeta42 = mmc_mk_cons(_s, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT11, tmpMeta42, _info);
goto goto_2;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
if (1 != tmp4_13) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,3) == 0) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta43,3,1) == 0) goto tmp3_end;
_ty = tmp4_2;
_vn = tmp4_1;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
tmp4 += 1;
_finst_dims = omc_List_flatten(threadData, _inst_dims);
tmpMeta45 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _vn, _kind, _dir, _daePrl, _prot, _ty, _e, _finst_dims, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta44 = mmc_mk_cons(tmpMeta45, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta46 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta44);
tmpMeta1 = tmpMeta46;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,11,4) == 0) goto tmp3_end;
_tty = tmp4_2;
_vn = tmp4_1;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
_finst_dims = omc_List_flatten(threadData, _inst_dims);
_path = omc_ComponentReference_crefToPath(threadData, _vn);
tmpMeta47 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta47), MMC_UNTAGPTR(_tty), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta47))[5] = _path;
_tty = tmpMeta47;
tmpMeta49 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _vn, _kind, _dir, _daePrl, _prot, _tty, _e, _finst_dims, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta48 = mmc_mk_cons(tmpMeta49, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta50 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta48);
tmpMeta1 = tmpMeta50;
goto tmp3_done;
}
case 14: {
modelica_boolean tmp51;
modelica_boolean tmp52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
_vn = tmp4_1;
_ty = tmp4_2;
_ct = tmp4_3;
_kind = tmp4_4;
_dir = tmp4_5;
_daePrl = tmp4_6;
_prot = tmp4_7;
_e = tmp4_8;
_inst_dims = tmp4_9;
_dae_var_attr = tmp4_11;
_comment = tmp4_12;
tmp51 = omc_Config_acceptMetaModelicaGrammar(threadData);
if (1 != tmp51) goto goto_2;
tmp52 = omc_Types_isBoxedType(threadData, _ty);
if (1 != tmp52) goto goto_2;
_finst_dims = omc_List_flatten(threadData, _inst_dims);
tmpMeta54 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _vn, _kind, _dir, _daePrl, _prot, _ty, _e, _finst_dims, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta53 = mmc_mk_cons(tmpMeta54, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta55 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta53);
tmpMeta1 = tmpMeta55;
goto tmp3_done;
}
case 15: {
tmpMeta1 = _OMC_LIT5;
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
if (++tmp4 < 16) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outDAe = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDAe;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstDAE_daeDeclare2(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inType, modelica_metatype _inConnectorType, modelica_metatype _inVarKind, modelica_metatype _inVarDirection, modelica_metatype _inParallelism, modelica_metatype _protection, modelica_metatype _inExpExpOption, modelica_metatype _inInstDims, modelica_metatype _inStartValue, modelica_metatype _inAttr, modelica_metatype _inComment, modelica_metatype _io, modelica_metatype _source, modelica_metatype _declareComplexVars)
{
modelica_integer tmp1;
modelica_metatype _outDAe = NULL;
tmp1 = mmc_unbox_integer(_declareComplexVars);
_outDAe = omc_InstDAE_daeDeclare2(threadData, _inComponentRef, _inType, _inConnectorType, _inVarKind, _inVarDirection, _inParallelism, _protection, _inExpExpOption, _inInstDims, _inStartValue, _inAttr, _inComment, _io, _source, tmp1);
return _outDAe;
}
PROTECTED_FUNCTION_STATIC void omc_InstDAE_showDAE(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inParentEnv, modelica_metatype _inClassEnv, modelica_metatype _inState, modelica_metatype _inDAE)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_string _str = NULL;
modelica_string _sstr = NULL;
modelica_metatype _comp = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _els = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
tmp5 = omc_Flags_isSet(threadData, _OMC_LIT15);
if (0 != tmp5) goto goto_1;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
_els = omc_DAEUtil_daeElements(threadData, _inDAE);
_sstr = omc_ClassInf_printStateStr(threadData, _inState);
tmpMeta6 = stringAppend(_OMC_LIT16,_sstr);
tmpMeta7 = stringAppend(tmpMeta6,_OMC_LIT16);
_sstr = tmpMeta7;
tmpMeta8 = mmc_mk_box5(20, &DAE_Element_COMP__desc, _sstr, _els, _OMC_LIT21, mmc_mk_none());
_comp = tmpMeta8;
tmpMeta9 = mmc_mk_cons(_comp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta10 = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta9);
_dae = tmpMeta10;
_str = (omc_System_getPartialInstantiation(threadData)?_OMC_LIT22:_OMC_LIT23);
tmpMeta11 = stringAppend(_OMC_LIT24,omc_FGraph_getGraphNameStr(threadData, _inParentEnv));
tmpMeta12 = stringAppend(tmpMeta11,_OMC_LIT25);
tmpMeta13 = stringAppend(tmpMeta12,omc_FGraph_getGraphNameStr(threadData, _inClassEnv));
tmpMeta14 = stringAppend(tmpMeta13,_OMC_LIT26);
tmpMeta15 = stringAppend(tmpMeta14,_sstr);
tmpMeta16 = stringAppend(tmpMeta15,_str);
tmpMeta17 = stringAppend(tmpMeta16,_OMC_LIT27);
tmpMeta18 = stringAppend(tmpMeta17,omc_DAEDump_dumpStr(threadData, _dae, _OMC_LIT28));
tmpMeta19 = stringAppend(tmpMeta18,_OMC_LIT27);
fputs(MMC_STRINGDATA(tmpMeta19),stdout);
goto tmp2_done;
}
case 2: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
_str = (omc_System_getPartialInstantiation(threadData)?_OMC_LIT22:_OMC_LIT23);
tmpMeta20 = stringAppend(_OMC_LIT29,omc_ClassInf_printStateStr(threadData, _inState));
tmpMeta21 = stringAppend(tmpMeta20,_str);
tmpMeta22 = stringAppend(tmpMeta21,_OMC_LIT30);
fputs(MMC_STRINGDATA(tmpMeta22),stdout);
goto tmp2_done;
}
case 3: {
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
;
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_InstDAE_daeDeclare(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inParentEnv, modelica_metatype _inClassEnv, modelica_metatype _inComponentRef, modelica_metatype _inState, modelica_metatype _inType, modelica_metatype _inAttributes, modelica_metatype _visibility, modelica_metatype _inBinding, modelica_metatype _inInstDims, modelica_metatype _inStartValue, modelica_metatype _inVarAttr, modelica_metatype _inComment, modelica_metatype _io, modelica_metatype _finalPrefix, modelica_metatype _source, modelica_boolean _declareComplexVars)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_metatype tmp4_5;volatile modelica_metatype tmp4_6;volatile modelica_metatype tmp4_7;volatile modelica_metatype tmp4_8;volatile modelica_metatype tmp4_9;volatile modelica_metatype tmp4_10;
tmp4_1 = _inComponentRef;
tmp4_2 = _inState;
tmp4_3 = _inType;
tmp4_4 = _inAttributes;
tmp4_5 = _visibility;
tmp4_6 = _inBinding;
tmp4_7 = _inInstDims;
tmp4_8 = _inStartValue;
tmp4_9 = _inVarAttr;
tmp4_10 = _inComment;
{
modelica_metatype _ct1 = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _vn = NULL;
modelica_metatype _daeParallelism = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _vis = NULL;
modelica_metatype _var = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _dir = NULL;
modelica_metatype _e = NULL;
modelica_metatype _start = NULL;
modelica_metatype _inst_dims = NULL;
modelica_metatype _dae_var_attr = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _info = NULL;
modelica_metatype _vk = NULL;
modelica_metatype _vd = NULL;
modelica_metatype _vv = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 5));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 6));
_vn = tmp4_1;
_ci_state = tmp4_2;
_ty = tmp4_3;
_ct = tmpMeta6;
_prl = tmpMeta7;
_var = tmpMeta8;
_dir = tmpMeta9;
_vis = tmp4_5;
_e = tmp4_6;
_inst_dims = tmp4_7;
_start = tmp4_8;
_dae_var_attr = tmp4_9;
_comment = tmp4_10;
tmpMeta10 = _source;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_info = tmpMeta11;
_ct1 = omc_DAEUtil_toConnectorType(threadData, _ct, _ci_state);
_daeParallelism = omc_DAEUtil_toDaeParallelism(threadData, _vn, _prl, _ci_state, _info);
_vk = omc_InstUtil_makeDaeVariability(threadData, _var);
_vd = omc_InstUtil_makeDaeDirection(threadData, _dir);
_vv = omc_InstUtil_makeDaeProt(threadData, _vis);
_dae_var_attr = omc_DAEUtil_setFinalAttr(threadData, _dae_var_attr, omc_SCodeUtil_finalBool(threadData, _finalPrefix));
_dae = omc_InstDAE_daeDeclare2(threadData, _vn, _ty, _ct1, _vk, _vd, _daeParallelism, _vv, _e, _inst_dims, _start, _dae_var_attr, _comment, _io, _source, _declareComplexVars);
omc_InstDAE_showDAE(threadData, _inCache, _inParentEnv, _inClassEnv, _inState, _dae);
tmpMeta1 = _dae;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp12;
tmp12 = omc_Flags_isSet(threadData, _OMC_LIT34);
if (1 != tmp12) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT35);
goto goto_2;
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
_outDae = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDae;
}
modelica_metatype boxptr_InstDAE_daeDeclare(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inParentEnv, modelica_metatype _inClassEnv, modelica_metatype _inComponentRef, modelica_metatype _inState, modelica_metatype _inType, modelica_metatype _inAttributes, modelica_metatype _visibility, modelica_metatype _inBinding, modelica_metatype _inInstDims, modelica_metatype _inStartValue, modelica_metatype _inVarAttr, modelica_metatype _inComment, modelica_metatype _io, modelica_metatype _finalPrefix, modelica_metatype _source, modelica_metatype _declareComplexVars)
{
modelica_integer tmp1;
modelica_metatype _outDae = NULL;
tmp1 = mmc_unbox_integer(_declareComplexVars);
_outDae = omc_InstDAE_daeDeclare(threadData, _inCache, _inParentEnv, _inClassEnv, _inComponentRef, _inState, _inType, _inAttributes, _visibility, _inBinding, _inInstDims, _inStartValue, _inVarAttr, _inComment, _io, _finalPrefix, _source, tmp1);
return _outDae;
}
