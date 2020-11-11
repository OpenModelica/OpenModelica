#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/InstMeta.c"
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
#define _OMC_LIT4_data "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/FrontEnd/InstMeta.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,69,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT5_6,1602262265.0);
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = arrayGet(_arr, ((modelica_integer) 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_cache = tmpMeta[1];
_env = tmpMeta[2];
_p = tmpMeta[3];
_ot = tmpMeta[4];
if(isNone(_ot))
{
omc_Lookup_lookupType(threadData, _cache, _env, _p, _OMC_LIT6 ,&_singletonType, NULL);
tmpMeta[0] = mmc_mk_box4(0, _cache, _env, _p, mmc_mk_some(_singletonType));
arrayUpdate(_arr, ((modelica_integer) 1), tmpMeta[0]);
}
else
{
tmpMeta[0] = _ot;
if (optionNone(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
_singletonType = tmpMeta[1];
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cache = _inCache;
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inState;
tmp3_2 = _inClassDef;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,22,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,8) == 0) goto tmp2_end;
_typeVars = tmpMeta[1];
_utPath = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inState), 2)));
_p = omc_AbsynUtil_makeFullyQualified(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inState), 2))));
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar0;
int tmp6;
modelica_metatype _e_loopVar = 0;
modelica_boolean tmp7 = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inClassDef), 2)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[2];
tmp5 = &__omcQ_24tmpVar1;
while(1) {
tmp6 = 1;
while (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
{
modelica_metatype tmp10_1;
tmp10_1 = _e;
{
volatile mmc_switch_type tmp10;
int tmp11;
tmp10 = 0;
for (; tmp10 < 2; tmp10++) {
switch (MMC_SWITCH_CAST(tmp10)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp10_1,2,8) == 0) goto tmp9_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp10_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],17,5) == 0) goto tmp9_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_utPathOfRestriction = tmpMeta[4];
tmp7 = omc_AbsynUtil_pathSuffixOf(threadData, _utPathOfRestriction, _utPath);
goto tmp9_done;
}
case 1: {
tmp7 = 0;
goto tmp9_done;
}
}
goto tmp9_end;
tmp9_end: ;
}
goto goto_8;
goto_8:;
goto goto_1;
goto tmp9_done;
tmp9_done:;
}
}
if (tmp7) {
tmp6--;
break;
}
}
if (tmp6 == 0) {
__omcQ_24tmpVar0 = _e;
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar1;
}
_names = omc_SCodeUtil_elementNames(threadData, tmpMeta[1]);
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp12;
modelica_metatype __omcQ_24tmpVar2;
int tmp13;
modelica_metatype _n_loopVar = 0;
modelica_metatype _n;
_n_loopVar = _names;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta[2];
tmp12 = &__omcQ_24tmpVar3;
while(1) {
tmp13 = 1;
if (!listEmpty(_n_loopVar)) {
_n = MMC_CAR(_n_loopVar);
_n_loopVar = MMC_CDR(_n_loopVar);
tmp13--;
}
if (tmp13 == 0) {
__omcQ_24tmpVar2 = omc_AbsynUtil_suffixPath(threadData, _p, _n);
*tmp12 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp12 = &MMC_CDR(*tmp12);
} else if (tmp13 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp12 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar3;
}
_paths = tmpMeta[1];
_isSingleton = (listLength(_paths) == ((modelica_integer) 1));
if(_isSingleton)
{
_p2 = listGet(_paths, ((modelica_integer) 1));
tmpMeta[2] = mmc_mk_box4(0, _cache, _inEnv, _p2, mmc_mk_none());
tmpMeta[1] = mmc_mk_box1(0, arrayCreate(((modelica_integer) 1), tmpMeta[2]));
tmpMeta[3] = mmc_mk_box2(3, &DAE_EvaluateSingletonType_EVAL__SINGLETON__TYPE__FUNCTION__desc, (modelica_fnptr) mmc_mk_box2(0,closure0_InstMeta_fixUniontype2,tmpMeta[1]));
_singletonType = tmpMeta[3];
}
else
{
_singletonType = _OMC_LIT7;
}
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp14;
modelica_metatype __omcQ_24tmpVar4;
int tmp15;
modelica_metatype _tv_loopVar = 0;
modelica_metatype _tv;
_tv_loopVar = _typeVars;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta[2];
tmp14 = &__omcQ_24tmpVar5;
while(1) {
tmp15 = 1;
if (!listEmpty(_tv_loopVar)) {
_tv = MMC_CAR(_tv_loopVar);
_tv_loopVar = MMC_CDR(_tv_loopVar);
tmp15--;
}
if (tmp15 == 0) {
tmpMeta[3] = mmc_mk_box2(27, &DAE_Type_T__METAPOLYMORPHIC__desc, _tv);
__omcQ_24tmpVar4 = tmpMeta[3];
*tmp14 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp14 = &MMC_CDR(*tmp14);
} else if (tmp15 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp14 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar5;
}
_typeVarsTypes = tmpMeta[1];
tmpMeta[1] = mmc_mk_box6(23, &DAE_Type_T__METAUNIONTYPE__desc, _paths, _typeVarsTypes, mmc_mk_boolean(_isSingleton), _singletonType, _p);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = mmc_mk_none();
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
_outType = tmpMeta[0];
_return: OMC_LABEL_UNUSED
if (out_outType) { *out_outType = _outType; }
return _cache;
}
