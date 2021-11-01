#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "InstMeta.c"
#endif
#include "omc_simulation_settings.h"
#include "InstMeta.h"
#define _OMC_LIT0_data "rml"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,3,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "Converts Modelica-style arrays to lists."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,40,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT1}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(18)),_OMC_LIT0,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "InstMeta.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,11,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT5_6,0.0);
#define _OMC_LIT5_6 MMC_REFREALLIT(_OMC_LIT_STRUCT5_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT4,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(107)),MMC_IMMEDIATE(MMC_TAGFIXNUM(5)),MMC_IMMEDIATE(MMC_TAGFIXNUM(107)),MMC_IMMEDIATE(MMC_TAGFIXNUM(79)),_OMC_LIT5_6}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,1,1) {_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,1,5) {&DAE_EvaluateSingletonType_NOT__SINGLETON__desc,}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#include "util/modelica.h"
#include "InstMeta_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstMeta_fixUniontype2(threadData_t *threadData, modelica_metatype _arr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstMeta_fixUniontype2,2,0) {(void*) boxptr_InstMeta_fixUniontype2,0}};
#define boxvar_InstMeta_fixUniontype2 MMC_REFSTRUCTLIT(boxvar_lit_InstMeta_fixUniontype2)
DLLExport
void omc_InstMeta_checkArrayType(threadData_t *threadData, modelica_metatype _inType)
{
modelica_metatype _el_ty = NULL;
modelica_boolean tmp1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_el_ty = omc_Types_arrayElementType(threadData, _inType);
tmp1 = (((!omc_Types_isString(threadData, _el_ty)) && omc_Types_isBoxedType(threadData, _el_ty)) || omc_Flags_isSet(threadData, _OMC_LIT3));
if (0 != tmp1) MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstMeta_fixUniontype2(threadData_t *threadData, modelica_metatype _arr)
{
modelica_metatype _singletonType = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _p = NULL;
modelica_metatype _ot = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = arrayGet(_arr, ((modelica_integer) 1));
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_cache = tmpMeta2;
_env = tmpMeta3;
_p = tmpMeta4;
_ot = tmpMeta5;
if(isNone(_ot))
{
omc_Lookup_lookupType(threadData, _cache, _env, _p, _OMC_LIT6 ,&_singletonType, NULL);
tmpMeta6 = mmc_mk_box4(0, _cache, _env, _p, mmc_mk_some(_singletonType));
arrayUpdate(_arr, ((modelica_integer) 1), tmpMeta6);
}
else
{
tmpMeta7 = _ot;
if (optionNone(tmpMeta7)) MMC_THROW_INTERNAL();
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_singletonType = tmpMeta8;
}
_return: OMC_LABEL_UNUSED
return _singletonType;
}
static modelica_metatype closure0_InstMeta_fixUniontype2(threadData_t *thData, modelica_metatype closure)
{
modelica_metatype arr = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_InstMeta_fixUniontype2(thData, arr);
}
DLLExport
modelica_metatype omc_InstMeta_fixUniontype(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inState, modelica_metatype _inClassDef, modelica_metatype *out_outType)
{
modelica_metatype _cache = NULL;
modelica_metatype _outType = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cache = _inCache;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inState;
tmp4_2 = _inClassDef;
{
modelica_metatype _p = NULL;
modelica_metatype _p2 = NULL;
modelica_metatype _utPathOfRestriction = NULL;
modelica_metatype _utPath = NULL;
modelica_boolean _isSingleton;
modelica_metatype _singletonType = NULL;
modelica_metatype _paths = NULL;
modelica_metatype _typeVarsTypes = NULL;
modelica_metatype _names = NULL;
modelica_metatype _typeVars = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,8) == 0) goto tmp3_end;
_typeVars = tmpMeta6;
_utPath = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inState), 2)));
_p = omc_AbsynUtil_makeFullyQualified(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inState), 2))));
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp8;
modelica_metatype tmpMeta9;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp10;
modelica_metatype _e_loopVar = 0;
modelica_boolean tmp11 = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inClassDef), 2)));
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta9;
tmp8 = &__omcQ_24tmpVar1;
while(1) {
tmp10 = 1;
while (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
{
modelica_metatype tmp14_1;
tmp14_1 = _e;
{
volatile mmc_switch_type tmp14;
int tmp15;
tmp14 = 0;
for (; tmp14 < 2; tmp14++) {
switch (MMC_SWITCH_CAST(tmp14)) {
case 0: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp14_1,2,8) == 0) goto tmp13_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp14_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,17,5) == 0) goto tmp13_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
_utPathOfRestriction = tmpMeta17;
tmp11 = omc_AbsynUtil_pathSuffixOf(threadData, _utPathOfRestriction, _utPath);
goto tmp13_done;
}
case 1: {
tmp11 = 0;
goto tmp13_done;
}
}
goto tmp13_end;
tmp13_end: ;
}
goto goto_12;
goto_12:;
goto goto_2;
goto tmp13_done;
tmp13_done:;
}
}
if (tmp11) {
tmp10--;
break;
}
}
if (tmp10 == 0) {
__omcQ_24tmpVar0 = _e;
*tmp8 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp8 = &MMC_CDR(*tmp8);
} else if (tmp10 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp8 = mmc_mk_nil();
tmpMeta7 = __omcQ_24tmpVar1;
}
_names = omc_SCodeUtil_elementNames(threadData, tmpMeta7);
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp19;
modelica_metatype tmpMeta20;
modelica_metatype __omcQ_24tmpVar2;
modelica_integer tmp21;
modelica_metatype _n_loopVar = 0;
modelica_metatype _n;
_n_loopVar = _names;
tmpMeta20 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta20;
tmp19 = &__omcQ_24tmpVar3;
while(1) {
tmp21 = 1;
if (!listEmpty(_n_loopVar)) {
_n = MMC_CAR(_n_loopVar);
_n_loopVar = MMC_CDR(_n_loopVar);
tmp21--;
}
if (tmp21 == 0) {
__omcQ_24tmpVar2 = omc_AbsynUtil_suffixPath(threadData, _p, _n);
*tmp19 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp19 = &MMC_CDR(*tmp19);
} else if (tmp21 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp19 = mmc_mk_nil();
tmpMeta18 = __omcQ_24tmpVar3;
}
_paths = tmpMeta18;
_isSingleton = (listLength(_paths) == ((modelica_integer) 1));
if(_isSingleton)
{
_p2 = listGet(_paths, ((modelica_integer) 1));
tmpMeta23 = mmc_mk_box4(0, _cache, _inEnv, _p2, mmc_mk_none());
tmpMeta22 = mmc_mk_box1(0, arrayCreate(((modelica_integer) 1), tmpMeta23));
tmpMeta24 = mmc_mk_box2(3, &DAE_EvaluateSingletonType_EVAL__SINGLETON__TYPE__FUNCTION__desc, (modelica_fnptr) mmc_mk_box2(0,closure0_InstMeta_fixUniontype2,tmpMeta22));
_singletonType = tmpMeta24;
}
else
{
_singletonType = _OMC_LIT7;
}
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype __omcQ_24tmpVar4;
modelica_integer tmp29;
modelica_metatype _tv_loopVar = 0;
modelica_metatype _tv;
_tv_loopVar = _typeVars;
tmpMeta27 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta27;
tmp26 = &__omcQ_24tmpVar5;
while(1) {
tmp29 = 1;
if (!listEmpty(_tv_loopVar)) {
_tv = MMC_CAR(_tv_loopVar);
_tv_loopVar = MMC_CDR(_tv_loopVar);
tmp29--;
}
if (tmp29 == 0) {
tmpMeta28 = mmc_mk_box2(27, &DAE_Type_T__METAPOLYMORPHIC__desc, _tv);
__omcQ_24tmpVar4 = tmpMeta28;
*tmp26 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp26 = &MMC_CDR(*tmp26);
} else if (tmp29 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp26 = mmc_mk_nil();
tmpMeta25 = __omcQ_24tmpVar5;
}
_typeVarsTypes = tmpMeta25;
tmpMeta30 = mmc_mk_box6(23, &DAE_Type_T__METAUNIONTYPE__desc, _paths, _typeVarsTypes, mmc_mk_boolean(_isSingleton), _singletonType, _p);
tmpMeta1 = mmc_mk_some(tmpMeta30);
goto tmp3_done;
}
case 1: {
tmpMeta1 = mmc_mk_none();
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
_outType = tmpMeta1;
_return: OMC_LABEL_UNUSED
if (out_outType) { *out_outType = _outType; }
return _cache;
}
