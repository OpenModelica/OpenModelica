#include "omc_simulation_settings.h"
#include "ValuesMake.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,2,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,3,8) {&Values_Value_ARRAY__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT0}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT2,0.0);
#define _OMC_LIT2 MMC_REFREALLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,2,4) {&Values_Value_REAL__desc,_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,2,3) {&Values_Value_INTEGER__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#include "util/modelica.h"
#include "ValuesMake_includes.h"
DLLDirection
modelica_metatype omc_ValuesMake_makeCodeTypeNameArray(threadData_t *threadData, modelica_metatype _paths)
{
modelica_metatype _val = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp4;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = _paths;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar1;
while(1) {
tmp4 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar0 = omc_ValuesMake_makeCodeTypeName(threadData, _p);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar1;
}
_val = omc_ValuesMake_makeArray(threadData, tmpMeta1);
_return: OMC_LABEL_UNUSED
return _val;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeCodeTypeNameStr(threadData_t *threadData, modelica_string _str)
{
modelica_metatype _val = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _str);
tmpMeta2 = mmc_mk_box2(3, &Absyn_CodeNode_C__TYPENAME__desc, tmpMeta1);
tmpMeta3 = mmc_mk_box2(15, &Values_Value_CODE__desc, tmpMeta2);
_val = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _val;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeCodeTypeName(threadData_t *threadData, modelica_metatype _path)
{
modelica_metatype _val = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(3, &Absyn_CodeNode_C__TYPENAME__desc, _path);
tmpMeta2 = mmc_mk_box2(15, &Values_Value_CODE__desc, tmpMeta1);
_val = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _val;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeRealMatrix(threadData_t *threadData, modelica_metatype _inReals)
{
modelica_metatype _outArray = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = omc_ValuesMake_makeArray(threadData, omc_List_map(threadData, _inReals, boxvar_ValuesMake_makeRealArray));
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeRealArray(threadData_t *threadData, modelica_metatype _inReals)
{
modelica_metatype _outArray = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = omc_ValuesMake_makeArray(threadData, omc_List_map(threadData, _inReals, boxvar_ValuesMake_makeReal));
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeIntArray(threadData_t *threadData, modelica_metatype _inInts)
{
modelica_metatype _outArray = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = omc_ValuesMake_makeArray(threadData, omc_List_map(threadData, _inInts, boxvar_ValuesMake_makeInteger));
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeStringArray(threadData_t *threadData, modelica_metatype _inReals)
{
modelica_metatype _outArray = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = omc_ValuesMake_makeArray(threadData, omc_List_map(threadData, _inReals, boxvar_ValuesMake_makeString));
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeEmptyArray(threadData_t *threadData)
{
modelica_metatype _outValue = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outValue = _OMC_LIT1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeArray(threadData_t *threadData, modelica_metatype _inValueLst)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inValueLst;
{
modelica_integer _i1;
modelica_metatype _il = NULL;
modelica_metatype _vlst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,5,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_vlst = tmp4_1;
_il = tmpMeta8;
_i1 = listLength(_vlst);
tmpMeta9 = mmc_mk_cons(mmc_mk_integer(_i1), _il);
tmpMeta10 = mmc_mk_box3(8, &Values_Value_ARRAY__desc, _vlst, tmpMeta9);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
_vlst = tmp4_1;
_i1 = listLength(_vlst);
tmpMeta11 = mmc_mk_cons(mmc_mk_integer(_i1), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta12 = mmc_mk_box3(8, &Values_Value_ARRAY__desc, _vlst, tmpMeta11);
tmpMeta1 = tmpMeta12;
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
_outValue = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeList(threadData_t *threadData, modelica_metatype _inValueLst)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(9, &Values_Value_LIST__desc, _inValueLst);
_outValue = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeTuple(threadData_t *threadData, modelica_metatype _inValueLst)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(11, &Values_Value_TUPLE__desc, _inValueLst);
_outValue = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeString(threadData_t *threadData, modelica_string _s)
{
modelica_metatype _v = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(5, &Values_Value_STRING__desc, _s);
_v = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _v;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeInteger(threadData_t *threadData, modelica_integer _i)
{
modelica_metatype _v = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(3, &Values_Value_INTEGER__desc, mmc_mk_integer(_i));
_v = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _v;
}
modelica_metatype boxptr_ValuesMake_makeInteger(threadData_t *threadData, modelica_metatype _i)
{
modelica_integer tmp1;
modelica_metatype _v = NULL;
tmp1 = mmc_unbox_integer(_i);
_v = omc_ValuesMake_makeInteger(threadData, tmp1);
return _v;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeReal(threadData_t *threadData, modelica_real _r)
{
modelica_metatype _v = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(4, &Values_Value_REAL__desc, mmc_mk_real(_r));
_v = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _v;
}
modelica_metatype boxptr_ValuesMake_makeReal(threadData_t *threadData, modelica_metatype _r)
{
modelica_real tmp1;
modelica_metatype _v = NULL;
tmp1 = mmc_unbox_real(_r);
_v = omc_ValuesMake_makeReal(threadData, tmp1);
return _v;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeBoolean(threadData_t *threadData, modelica_boolean _b)
{
modelica_metatype _v = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box2(6, &Values_Value_BOOL__desc, mmc_mk_boolean(_b));
_v = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _v;
}
modelica_metatype boxptr_ValuesMake_makeBoolean(threadData_t *threadData, modelica_metatype _b)
{
modelica_integer tmp1;
modelica_metatype _v = NULL;
tmp1 = mmc_unbox_integer(_b);
_v = omc_ValuesMake_makeBoolean(threadData, tmp1);
return _v;
}
DLLDirection
modelica_metatype omc_ValuesMake_makeZero(threadData_t *threadData, modelica_metatype _ty)
{
modelica_metatype _zero = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ty;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT3;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT4;
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
_zero = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _zero;
}
