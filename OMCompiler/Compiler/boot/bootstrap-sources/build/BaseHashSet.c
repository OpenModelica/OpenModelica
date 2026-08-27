#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/BaseHashSet.c"
#endif
#include "omc_simulation_settings.h"
#include "BaseHashSet.h"
#define _OMC_LIT0_data "-HashSet.valueArrayClearnth failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,35,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "-HashSet.valueArraySetnth failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,33,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "-HashSet.valueArrayAdd failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,30,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "HashSet:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,9,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,1,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "-HashSet.delete failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,23,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "- BaseHashSet.addNoUpdCheck failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,35,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "- BaseHashSet.add failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,26,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "bsize: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,7,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data " key: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,6,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data " Hash: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,7,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#include "util/modelica.h"
#include "BaseHashSet_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BaseHashSet_valueArrayNthT(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashSet_valueArrayNthT(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArrayNthT,2,0) {(void*) boxptr_BaseHashSet_valueArrayNthT,0}};
#define boxvar_BaseHashSet_valueArrayNthT MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_valueArrayNthT)
PROTECTED_FUNCTION_STATIC modelica_integer omc_BaseHashSet_get2(threadData_t *threadData, modelica_metatype _key, modelica_metatype _keyIndices, modelica_fnptr _keyEqual, modelica_boolean *out_found);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashSet_get2(threadData_t *threadData, modelica_metatype _key, modelica_metatype _keyIndices, modelica_fnptr _keyEqual, modelica_metatype *out_found);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_get2,2,0) {(void*) boxptr_BaseHashSet_get2,0}};
#define boxvar_BaseHashSet_get2 MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_get2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BaseHashSet_get1(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet, modelica_integer *out_indx);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashSet_get1(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet, modelica_metatype *out_indx);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashSet_get1,2,0) {(void*) boxptr_BaseHashSet_get1,0}};
#define boxvar_BaseHashSet_get1 MMC_REFSTRUCTLIT(boxvar_lit_BaseHashSet_get1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BaseHashSet_valueArrayNthT(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos)
{
modelica_metatype _key = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _valueArray;
{
modelica_integer _n;
modelica_metatype _arr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_n = tmp5;
_arr = tmpMeta[2];
if((!(_pos <= _n)))
{
goto goto_1;
}
tmpMeta[0] = arrayGet(_arr,((modelica_integer) 1) + _pos);
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
_key = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _key;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashSet_valueArrayNthT(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos)
{
modelica_integer tmp1;
modelica_metatype _key = NULL;
tmp1 = mmc_unbox_integer(_pos);
_key = omc_BaseHashSet_valueArrayNthT(threadData, _valueArray, tmp1);
return _key;
}
DLLExport
modelica_metatype omc_BaseHashSet_valueArrayNth(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos)
{
modelica_metatype _key = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _valueArray;
{
modelica_metatype _k = NULL;
modelica_integer _n;
modelica_metatype _arr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_n = tmp5;
_arr = tmpMeta[2];
if((!(_pos <= _n)))
{
goto goto_1;
}
tmpMeta[1] = arrayGet(_arr,((modelica_integer) 1) + _pos);
if (optionNone(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_k = tmpMeta[2];
tmpMeta[0] = _k;
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
_key = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _key;
}
modelica_metatype boxptr_BaseHashSet_valueArrayNth(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos)
{
modelica_integer tmp1;
modelica_metatype _key = NULL;
tmp1 = mmc_unbox_integer(_pos);
_key = omc_BaseHashSet_valueArrayNth(threadData, _valueArray, tmp1);
return _key;
}
DLLExport
modelica_metatype omc_BaseHashSet_valueArrayClearnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos)
{
modelica_metatype _outValueArray = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _valueArray;
{
modelica_metatype _arr_1 = NULL;
modelica_metatype _arr = NULL;
modelica_integer _n;
modelica_integer _size;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_n = tmp5;
_size = tmp6;
_arr = tmpMeta[3];
if((!(_pos < _size)))
{
goto goto_1;
}
_arr_1 = arrayUpdate(_arr, ((modelica_integer) 1) + _pos, mmc_mk_none());
tmpMeta[1] = mmc_mk_box3(0, mmc_mk_integer(_n), mmc_mk_integer(_size), _arr_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT0),stdout);
goto goto_1;
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
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outValueArray = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outValueArray;
}
modelica_metatype boxptr_BaseHashSet_valueArrayClearnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos)
{
modelica_integer tmp1;
modelica_metatype _outValueArray = NULL;
tmp1 = mmc_unbox_integer(_pos);
_outValueArray = omc_BaseHashSet_valueArrayClearnth(threadData, _valueArray, tmp1);
return _outValueArray;
}
DLLExport
modelica_metatype omc_BaseHashSet_valueArraySetnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos, modelica_metatype _entry)
{
modelica_metatype _outValueArray = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _valueArray;
{
modelica_metatype _arr_1 = NULL;
modelica_metatype _arr = NULL;
modelica_integer _n;
modelica_integer _size;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_n = tmp5;
_size = tmp6;
_arr = tmpMeta[3];
if((!(_pos < _size)))
{
goto goto_1;
}
_arr_1 = arrayUpdate(_arr, ((modelica_integer) 1) + _pos, mmc_mk_some(_entry));
tmpMeta[1] = mmc_mk_box3(0, mmc_mk_integer(_n), mmc_mk_integer(_size), _arr_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT1),stdout);
goto goto_1;
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
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outValueArray = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outValueArray;
}
modelica_metatype boxptr_BaseHashSet_valueArraySetnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos, modelica_metatype _entry)
{
modelica_integer tmp1;
modelica_metatype _outValueArray = NULL;
tmp1 = mmc_unbox_integer(_pos);
_outValueArray = omc_BaseHashSet_valueArraySetnth(threadData, _valueArray, tmp1, _entry);
return _outValueArray;
}
DLLExport
modelica_metatype omc_BaseHashSet_valueArrayAdd(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _entry)
{
modelica_metatype _outValueArray = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _valueArray;
{
modelica_integer _n_1;
modelica_integer _n;
modelica_integer _size;
modelica_integer _expandsize;
modelica_integer _expandsize_1;
modelica_integer _newsize;
modelica_metatype _arr_1 = NULL;
modelica_metatype _arr = NULL;
modelica_metatype _arr_2 = NULL;
modelica_real _rsize;
modelica_real _rexpandsize;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_n = tmp5;
_size = tmp6;
_arr = tmpMeta[3];
if((!(_n < _size)))
{
goto goto_1;
}
_n_1 = ((modelica_integer) 1) + _n;
_arr_1 = arrayUpdate(_arr, ((modelica_integer) 1) + _n, mmc_mk_some(_entry));
tmpMeta[1] = mmc_mk_box3(0, mmc_mk_integer(_n_1), mmc_mk_integer(_size), _arr_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_integer tmp7;
modelica_integer tmp8;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp8 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_n = tmp7;
_size = tmp8;
_arr = tmpMeta[3];
if((_n < _size))
{
goto goto_1;
}
_rsize = ((modelica_real)_size);
_rexpandsize = (0.4) * (_rsize);
_expandsize = ((modelica_integer)floor(_rexpandsize));
_expandsize_1 = modelica_integer_max((modelica_integer)(_expandsize),(modelica_integer)(((modelica_integer) 1)));
_newsize = _expandsize_1 + _size;
_arr_1 = omc_Array_expand(threadData, _expandsize_1, _arr, mmc_mk_none());
_n_1 = ((modelica_integer) 1) + _n;
_arr_2 = arrayUpdate(_arr_1, ((modelica_integer) 1) + _n, mmc_mk_some(_entry));
tmpMeta[1] = mmc_mk_box3(0, mmc_mk_integer(_n_1), mmc_mk_integer(_newsize), _arr_2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
fputs(MMC_STRINGDATA(_OMC_LIT2),stdout);
goto goto_1;
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
if (++tmp3 < 3) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outValueArray = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outValueArray;
}
DLLExport
modelica_integer omc_BaseHashSet_valueArrayLength(threadData_t *threadData, modelica_metatype _valueArray)
{
modelica_integer _sz;
modelica_integer tmp1;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _valueArray;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
_sz = tmp1;
_return: OMC_LABEL_UNUSED
return _sz;
}
modelica_metatype boxptr_BaseHashSet_valueArrayLength(threadData_t *threadData, modelica_metatype _valueArray)
{
modelica_integer _sz;
modelica_metatype out_sz;
_sz = omc_BaseHashSet_valueArrayLength(threadData, _valueArray);
out_sz = mmc_mk_icon(_sz);
return out_sz;
}
DLLExport
modelica_integer omc_BaseHashSet_currentSize(threadData_t *threadData, modelica_metatype _hashSet)
{
modelica_integer _sz;
modelica_metatype _va = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _hashSet;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_va = tmpMeta[1];
_sz = omc_BaseHashSet_valueArrayLength(threadData, _va);
_return: OMC_LABEL_UNUSED
return _sz;
}
modelica_metatype boxptr_BaseHashSet_currentSize(threadData_t *threadData, modelica_metatype _hashSet)
{
modelica_integer _sz;
modelica_metatype out_sz;
_sz = omc_BaseHashSet_currentSize(threadData, _hashSet);
out_sz = mmc_mk_icon(_sz);
return out_sz;
}
DLLExport
modelica_metatype omc_BaseHashSet_valueArrayList(threadData_t *threadData, modelica_metatype _inValueArray)
{
modelica_metatype _outList = NULL;
modelica_metatype _arr = NULL;
modelica_integer _size;
modelica_metatype _e = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outList = tmpMeta[0];
tmpMeta[1] = _inValueArray;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp1 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_size = tmp1;
_arr = tmpMeta[3];
tmp2 = ((modelica_integer) 1); tmp3 = 1; tmp4 = _size;
if(!(((tmp3 > 0) && (tmp2 > tmp4)) || ((tmp3 < 0) && (tmp2 < tmp4))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp2, tmp4); _i += tmp3)
{
if(isSome(arrayGet(_arr,_i) /* DAE.ASUB */))
{
tmpMeta[1] = arrayGet(_arr,_i);
if (optionNone(tmpMeta[1])) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_e = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_e, _outList);
_outList = tmpMeta[1];
}
}
}
_outList = listReverse(_outList);
_return: OMC_LABEL_UNUSED
return _outList;
}
DLLExport
modelica_metatype omc_BaseHashSet_hashSetList(threadData_t *threadData, modelica_metatype _hashSet)
{
modelica_metatype _lst = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _hashSet;
{
modelica_metatype _varr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_varr = tmpMeta[1];
tmpMeta[0] = omc_BaseHashSet_valueArrayList(threadData, _varr);
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
_lst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _lst;
}
DLLExport
void omc_BaseHashSet_dumpHashSet(threadData_t *threadData, modelica_metatype _hashSet)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
fputs(MMC_STRINGDATA(_OMC_LIT3),stdout);
omc_BaseHashSet_printHashSet(threadData, _hashSet);
fputs(MMC_STRINGDATA(_OMC_LIT4),stdout);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_BaseHashSet_printHashSet(threadData_t *threadData, modelica_metatype _hashSet)
{
modelica_fnptr _printKey;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _hashSet;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_printKey = tmpMeta[2];
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp1;
modelica_string __omcQ_24tmpVar0;
int tmp2;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = omc_BaseHashSet_hashSetList(threadData, _hashSet);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar1;
while(1) {
tmp2 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp2--;
}
if (tmp2 == 0) {
__omcQ_24tmpVar0 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 1)))) (threadData, _e);
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar1;
}
fputs(MMC_STRINGDATA(stringDelimitList(tmpMeta[0], _OMC_LIT4)),stdout);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_BaseHashSet_get2(threadData_t *threadData, modelica_metatype _key, modelica_metatype _keyIndices, modelica_fnptr _keyEqual, modelica_boolean *out_found)
{
modelica_integer _index;
modelica_boolean _found;
modelica_metatype _key2 = NULL;
modelica_integer tmp1;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_found = 1;
{
modelica_metatype _t;
for (tmpMeta[0] = _keyIndices; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_t = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = _t;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[3]);
_key2 = tmpMeta[2];
_index = tmp1;
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqual), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqual), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqual), 2))), _key, _key2) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqual), 1)))) (threadData, _key, _key2)))
{
goto _return;
}
}
}
_found = 0;
_return: OMC_LABEL_UNUSED
if (out_found) { *out_found = _found; }
return _index;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashSet_get2(threadData_t *threadData, modelica_metatype _key, modelica_metatype _keyIndices, modelica_fnptr _keyEqual, modelica_metatype *out_found)
{
modelica_boolean _found;
modelica_integer _index;
modelica_metatype out_index;
_index = omc_BaseHashSet_get2(threadData, _key, _keyIndices, _keyEqual, &_found);
out_index = mmc_mk_icon(_index);
if (out_found) { *out_found = mmc_mk_icon(_found); }
return out_index;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BaseHashSet_get1(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet, modelica_integer *out_indx)
{
modelica_metatype _okey = NULL;
modelica_integer _indx;
modelica_integer tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _hashSet;
{
modelica_integer _hashindx;
modelica_integer _bsize;
modelica_metatype _indexes = NULL;
modelica_metatype _hashvec = NULL;
modelica_metatype _varr = NULL;
modelica_metatype _k = NULL;
modelica_fnptr _keyEqual;
modelica_fnptr _hashFunc;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
_hashvec = tmpMeta[2];
_varr = tmpMeta[3];
_bsize = tmp6;
_hashFunc = tmpMeta[6];
_keyEqual = tmpMeta[7];
_hashindx = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key, mmc_mk_integer(_bsize)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key, mmc_mk_integer(_bsize)));
_indexes = arrayGet(_hashvec,((modelica_integer) 1) + _hashindx);
_indx = omc_BaseHashSet_get2(threadData, _key, _indexes, ((modelica_fnptr) _keyEqual) ,&_b);
_k = (_b?omc_BaseHashSet_valueArrayNthT(threadData, _varr, _indx):mmc_mk_none());
tmpMeta[0+0] = _k;
tmp1_c1 = _indx;
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
_okey = tmpMeta[0+0];
_indx = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_indx) { *out_indx = _indx; }
return _okey;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashSet_get1(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet, modelica_metatype *out_indx)
{
modelica_integer _indx;
modelica_metatype _okey = NULL;
_okey = omc_BaseHashSet_get1(threadData, _key, _hashSet, &_indx);
if (out_indx) { *out_indx = mmc_mk_icon(_indx); }
return _okey;
}
DLLExport
modelica_metatype omc_BaseHashSet_get(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet)
{
modelica_metatype _okey = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_okey = omc_BaseHashSet_get1(threadData, _key, _hashSet, NULL);
_return: OMC_LABEL_UNUSED
return _okey;
}
DLLExport
modelica_boolean omc_BaseHashSet_hasAll(threadData_t *threadData, modelica_metatype _keys, modelica_metatype _hashSet)
{
modelica_boolean _b;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = 1;
{
modelica_metatype _key;
for (tmpMeta[0] = _keys; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_key = MMC_CAR(tmpMeta[0]);
_b = omc_BaseHashSet_has(threadData, _key, _hashSet);
if((!_b))
{
goto _return;
}
}
}
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_BaseHashSet_hasAll(threadData_t *threadData, modelica_metatype _keys, modelica_metatype _hashSet)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_BaseHashSet_hasAll(threadData, _keys, _hashSet);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_BaseHashSet_has(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _hashSet;
{
modelica_metatype _oKey = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
if (0 != tmp6) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
_oKey = omc_BaseHashSet_get1(threadData, _key, _hashSet, NULL);
tmp1 = isSome(_oKey);
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_BaseHashSet_has(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_BaseHashSet_has(threadData, _key, _hashSet);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_BaseHashSet_delete(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet)
{
modelica_metatype _outHashSet = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _hashSet;
{
modelica_integer _indx;
modelica_integer _n;
modelica_integer _bsize;
modelica_metatype _varr_1 = NULL;
modelica_metatype _varr = NULL;
modelica_metatype _hashvec = NULL;
modelica_metatype _fntpl = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp5 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmp6 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_hashvec = tmpMeta[1];
_varr = tmpMeta[2];
_bsize = tmp5;
_n = tmp6;
_fntpl = tmpMeta[5];
tmpMeta[1] = omc_BaseHashSet_get1(threadData, _key, _hashSet, &tmp7);
if (optionNone(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_indx = tmp7;
_varr_1 = omc_BaseHashSet_valueArrayClearnth(threadData, _varr, _indx);
tmpMeta[1] = mmc_mk_box5(0, _hashvec, _varr_1, mmc_mk_integer(_bsize), mmc_mk_integer(_n), _fntpl);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT5),stdout);
goto goto_1;
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
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outHashSet = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outHashSet;
}
DLLExport
modelica_metatype omc_BaseHashSet_addUnique(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet)
{
modelica_metatype _outHashSet = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _hashSet;
{
modelica_integer _indx;
modelica_integer _newpos;
modelica_integer _n_1;
modelica_integer _bsize;
modelica_metatype _varr_1 = NULL;
modelica_metatype _varr = NULL;
modelica_metatype _indexes = NULL;
modelica_metatype _hashvec_1 = NULL;
modelica_metatype _hashvec = NULL;
modelica_metatype _fntpl = NULL;
modelica_fnptr _hashFunc;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp5 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 1));
_hashvec = tmpMeta[1];
_varr = tmpMeta[2];
_bsize = tmp5;
_fntpl = tmpMeta[4];
_hashFunc = tmpMeta[5];
if (!(!omc_BaseHashSet_has(threadData, _key, _hashSet))) goto tmp2_end;
_indx = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key, mmc_mk_integer(_bsize)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key, mmc_mk_integer(_bsize)));
_newpos = omc_BaseHashSet_valueArrayLength(threadData, _varr);
_varr_1 = omc_BaseHashSet_valueArrayAdd(threadData, _varr, _key);
_indexes = arrayGet(_hashvec,((modelica_integer) 1) + _indx);
tmpMeta[2] = mmc_mk_box2(0, _key, mmc_mk_integer(_newpos));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _indexes);
_hashvec_1 = arrayUpdate(_hashvec, ((modelica_integer) 1) + _indx, tmpMeta[1]);
_n_1 = omc_BaseHashSet_valueArrayLength(threadData, _varr_1);
tmpMeta[1] = mmc_mk_box5(0, _hashvec_1, _varr_1, mmc_mk_integer(_bsize), mmc_mk_integer(_n_1), _fntpl);
tmpMeta[0] = tmpMeta[1];
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
_outHashSet = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outHashSet;
}
DLLExport
modelica_metatype omc_BaseHashSet_addNoUpdCheck(threadData_t *threadData, modelica_metatype _entry, modelica_metatype _hashSet)
{
modelica_metatype _outHashSet = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _entry;
tmp3_2 = _hashSet;
{
modelica_integer _indx;
modelica_integer _newpos;
modelica_integer _n_1;
modelica_integer _bsize;
modelica_metatype _varr_1 = NULL;
modelica_metatype _varr = NULL;
modelica_metatype _indexes = NULL;
modelica_metatype _hashvec_1 = NULL;
modelica_metatype _hashvec = NULL;
modelica_metatype _key = NULL;
modelica_metatype _fntpl = NULL;
modelica_fnptr _hashFunc;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp5 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 1));
_key = tmp3_1;
_hashvec = tmpMeta[1];
_varr = tmpMeta[2];
_bsize = tmp5;
_fntpl = tmpMeta[4];
_hashFunc = tmpMeta[5];
_indx = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key, mmc_mk_integer(_bsize)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key, mmc_mk_integer(_bsize)));
_newpos = omc_BaseHashSet_valueArrayLength(threadData, _varr);
_varr_1 = omc_BaseHashSet_valueArrayAdd(threadData, _varr, _key);
_indexes = arrayGet(_hashvec,((modelica_integer) 1) + _indx);
tmpMeta[2] = mmc_mk_box2(0, _key, mmc_mk_integer(_newpos));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _indexes);
_hashvec_1 = arrayUpdate(_hashvec, ((modelica_integer) 1) + _indx, tmpMeta[1]);
_n_1 = omc_BaseHashSet_valueArrayLength(threadData, _varr_1);
tmpMeta[1] = mmc_mk_box5(0, _hashvec_1, _varr_1, mmc_mk_integer(_bsize), mmc_mk_integer(_n_1), _fntpl);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT6),stdout);
goto goto_1;
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
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outHashSet = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outHashSet;
}
DLLExport
modelica_metatype omc_BaseHashSet_add(threadData_t *threadData, modelica_metatype _entry, modelica_metatype _hashSet)
{
modelica_metatype _outHashSet = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _entry;
tmp3_2 = _hashSet;
{
modelica_integer _hval;
modelica_integer _indx;
modelica_integer _newpos;
modelica_integer _n;
modelica_integer _bsize;
modelica_metatype _varr = NULL;
modelica_metatype _indexes = NULL;
modelica_metatype _hashvec = NULL;
modelica_metatype _key = NULL;
modelica_metatype _fkey = NULL;
modelica_metatype _fntpl = NULL;
modelica_fnptr _hashFunc;
modelica_fnptr _keystrFunc;
modelica_string _s = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp5 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
tmp6 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
_key = tmp3_1;
_hashvec = tmpMeta[1];
_varr = tmpMeta[2];
_bsize = tmp5;
_n = tmp6;
_fntpl = tmpMeta[5];
_hashFunc = tmpMeta[6];
_fkey = omc_BaseHashSet_get1(threadData, _key, _hashSet ,&_indx);
if(isSome(_fkey))
{
_varr = omc_BaseHashSet_valueArraySetnth(threadData, _varr, _indx, _key);
}
else
{
_indx = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key, mmc_mk_integer(_bsize)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key, mmc_mk_integer(_bsize)));
_newpos = omc_BaseHashSet_valueArrayLength(threadData, _varr);
_varr = omc_BaseHashSet_valueArrayAdd(threadData, _varr, _key);
_indexes = arrayGet(_hashvec,((modelica_integer) 1) + _indx);
tmpMeta[2] = mmc_mk_box2(0, _key, mmc_mk_integer(_newpos));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _indexes);
_hashvec = arrayUpdate(_hashvec, ((modelica_integer) 1) + _indx, tmpMeta[1]);
_n = omc_BaseHashSet_valueArrayLength(threadData, _varr);
}
tmpMeta[1] = mmc_mk_box5(0, _hashvec, _varr, mmc_mk_integer(_bsize), mmc_mk_integer(_n), _fntpl);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_integer tmp7;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 5));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_key = tmp3_1;
_bsize = tmp7;
_hashFunc = tmpMeta[3];
_keystrFunc = tmpMeta[4];
fputs(MMC_STRINGDATA(_OMC_LIT7),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT8),stdout);
fputs(MMC_STRINGDATA(intString(_bsize)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT9),stdout);
_s = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keystrFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keystrFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keystrFunc), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keystrFunc), 1)))) (threadData, _key);
tmpMeta[1] = stringAppend(_s,_OMC_LIT10);
fputs(MMC_STRINGDATA(tmpMeta[1]),stdout);
_hval = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key, mmc_mk_integer(_bsize)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key, mmc_mk_integer(_bsize)));
fputs(MMC_STRINGDATA(intString(_hval)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT4),stdout);
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
_outHashSet = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outHashSet;
}
DLLExport
modelica_metatype omc_BaseHashSet_emptyHashSetWork(threadData_t *threadData, modelica_integer _szBucket, modelica_metatype _fntpl)
{
modelica_metatype _hashSet = NULL;
modelica_metatype _arr = NULL;
modelica_metatype _lst = NULL;
modelica_metatype _emptyarr = NULL;
modelica_integer _szArr;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_arr = arrayCreate(_szBucket, tmpMeta[0]);
_szArr = omc_BaseHashSet_bucketToValuesSize(threadData, _szBucket);
_emptyarr = arrayCreate(_szArr, mmc_mk_none());
tmpMeta[0] = mmc_mk_box3(0, mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(_szArr), _emptyarr);
tmpMeta[1] = mmc_mk_box5(0, _arr, tmpMeta[0], mmc_mk_integer(_szBucket), mmc_mk_integer(((modelica_integer) 0)), _fntpl);
_hashSet = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _hashSet;
}
modelica_metatype boxptr_BaseHashSet_emptyHashSetWork(threadData_t *threadData, modelica_metatype _szBucket, modelica_metatype _fntpl)
{
modelica_integer tmp1;
modelica_metatype _hashSet = NULL;
tmp1 = mmc_unbox_integer(_szBucket);
_hashSet = omc_BaseHashSet_emptyHashSetWork(threadData, tmp1, _fntpl);
return _hashSet;
}
DLLExport
modelica_integer omc_BaseHashSet_bucketToValuesSize(threadData_t *threadData, modelica_integer _szBucket)
{
modelica_integer _szArr;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_szArr = ((modelica_integer)floor((0.6) * (((modelica_real)_szBucket))));
_return: OMC_LABEL_UNUSED
return _szArr;
}
modelica_metatype boxptr_BaseHashSet_bucketToValuesSize(threadData_t *threadData, modelica_metatype _szBucket)
{
modelica_integer tmp1;
modelica_integer _szArr;
modelica_metatype out_szArr;
tmp1 = mmc_unbox_integer(_szBucket);
_szArr = omc_BaseHashSet_bucketToValuesSize(threadData, tmp1);
out_szArr = mmc_mk_icon(_szArr);
return out_szArr;
}
