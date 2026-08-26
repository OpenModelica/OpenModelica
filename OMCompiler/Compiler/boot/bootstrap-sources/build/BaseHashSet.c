#include "omc_simulation_settings.h"
#include "BaseHashSet.h"
#define _OMC_LIT0_data "HashSet:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,9,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "- BaseHashSet.add failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,26,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "bsize: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,7,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data " key: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,6,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data " Hash: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,7,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _valueArray;
{
modelica_integer _n;
modelica_metatype _arr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_n = tmp7;
_arr = tmpMeta8;
if (!(_pos <= _n)) goto tmp3_end;
tmpMeta1 = arrayGet(_arr,((modelica_integer) 1) + _pos);
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
_key = tmpMeta1;
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
DLLDirection
modelica_metatype omc_BaseHashSet_valueArrayNth(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos)
{
modelica_metatype _key = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _valueArray;
{
modelica_metatype _k = NULL;
modelica_integer _n;
modelica_metatype _arr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_n = tmp7;
_arr = tmpMeta8;
if (!(_pos <= _n)) goto tmp3_end;
tmpMeta9 = arrayGet(_arr,((modelica_integer) 1) + _pos);
if (optionNone(tmpMeta9)) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
_k = tmpMeta10;
tmpMeta1 = _k;
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
_key = tmpMeta1;
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
DLLDirection
modelica_metatype omc_BaseHashSet_valueArrayClearnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos)
{
modelica_metatype _outValueArray = NULL;
modelica_metatype _arr_1 = NULL;
modelica_metatype _arr = NULL;
modelica_integer _n;
modelica_integer _size;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
modelica_boolean tmp7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _valueArray;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmp3 = mmc_unbox_integer(tmpMeta2);
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmp5 = mmc_unbox_integer(tmpMeta4);
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_n = tmp3;
_size = tmp5;
_arr = tmpMeta6;
tmp7 = (_pos < _size);
if (1 /* true */ != tmp7) MMC_THROW_INTERNAL();
_arr_1 = arrayUpdate(_arr, ((modelica_integer) 1) + _pos, mmc_mk_none());
tmpMeta8 = mmc_mk_box3(0, mmc_mk_integer(_n), mmc_mk_integer(_size), _arr_1);
_outValueArray = tmpMeta8;
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
DLLDirection
modelica_metatype omc_BaseHashSet_valueArraySetnth(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos, modelica_metatype _entry)
{
modelica_metatype _outValueArray = NULL;
modelica_metatype _arr_1 = NULL;
modelica_metatype _arr = NULL;
modelica_integer _n;
modelica_integer _size;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
modelica_boolean tmp7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _valueArray;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmp3 = mmc_unbox_integer(tmpMeta2);
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmp5 = mmc_unbox_integer(tmpMeta4);
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_n = tmp3;
_size = tmp5;
_arr = tmpMeta6;
tmp7 = (_pos < _size);
if (1 /* true */ != tmp7) MMC_THROW_INTERNAL();
_arr_1 = arrayUpdate(_arr, ((modelica_integer) 1) + _pos, mmc_mk_some(_entry));
tmpMeta8 = mmc_mk_box3(0, mmc_mk_integer(_n), mmc_mk_integer(_size), _arr_1);
_outValueArray = tmpMeta8;
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
DLLDirection
modelica_metatype omc_BaseHashSet_valueArrayAdd(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _entry)
{
modelica_metatype _outValueArray = NULL;
modelica_integer _n;
modelica_integer _size;
modelica_integer _expandsize;
modelica_integer _expandsize_1;
modelica_metatype _arr = NULL;
modelica_real _rsize;
modelica_real _rexpandsize;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _valueArray;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmp3 = mmc_unbox_integer(tmpMeta2);
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmp5 = mmc_unbox_integer(tmpMeta4);
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_n = tmp3;
_size = tmp5;
_arr = tmpMeta6;
if((_n >= _size))
{
_rsize = ((modelica_real)_size);
_rexpandsize = (0.4) * (_rsize);
_expandsize = ((modelica_integer)floor(_rexpandsize));
_expandsize_1 = modelica_integer_max((modelica_integer)(_expandsize),(modelica_integer)(((modelica_integer) 1)));
_size = _expandsize_1 + _size;
_arr = omc_Array_expand(threadData, _expandsize_1, _arr, mmc_mk_none());
}
_arr = arrayUpdate(_arr, ((modelica_integer) 1) + _n, mmc_mk_some(_entry));
tmpMeta7 = mmc_mk_box3(0, mmc_mk_integer(((modelica_integer) 1) + _n), mmc_mk_integer(_size), _arr);
_outValueArray = tmpMeta7;
_return: OMC_LABEL_UNUSED
return _outValueArray;
}
DLLDirection
modelica_integer omc_BaseHashSet_valueArrayLength(threadData_t *threadData, modelica_metatype _valueArray)
{
modelica_integer _sz;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _valueArray;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmp3 = mmc_unbox_integer(tmpMeta2);
_sz = tmp3;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
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
DLLDirection
modelica_integer omc_BaseHashSet_currentSize(threadData_t *threadData, modelica_metatype _hashSet)
{
modelica_integer _sz;
modelica_metatype _va = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _hashSet;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_va = tmpMeta2;
_sz = omc_BaseHashSet_valueArrayLength(threadData, _va);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
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
DLLDirection
modelica_metatype omc_BaseHashSet_valueArrayList(threadData_t *threadData, modelica_metatype _inValueArray)
{
modelica_metatype _outList = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _arr = NULL;
modelica_integer _size;
modelica_metatype _e = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_integer tmp10;
modelica_integer tmp11;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outList = tmpMeta1;
tmpMeta2 = _inValueArray;
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 1));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 3));
_size = tmp4;
_arr = tmpMeta5;
tmp9 = ((modelica_integer) 1); tmp10 = 1; tmp11 = _size;
if(!(((tmp10 > 0) && (tmp9 > tmp11)) || ((tmp10 < 0) && (tmp9 < tmp11))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp9, tmp11); _i += tmp10)
{
if(isSome(arrayGet(_arr,_i) /* DAE.ASUB */))
{
tmpMeta6 = arrayGet(_arr,_i);
if (optionNone(tmpMeta6)) MMC_THROW_INTERNAL();
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
_e = tmpMeta7;
tmpMeta8 = mmc_mk_cons(_e, _outList);
_outList = tmpMeta8;
}
}
}
_outList = listReverse(_outList);
_return: OMC_LABEL_UNUSED
return _outList;
}
DLLDirection
modelica_metatype omc_BaseHashSet_hashSetList(threadData_t *threadData, modelica_metatype _hashSet)
{
modelica_metatype _lst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _hashSet;
{
modelica_metatype _varr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_varr = tmpMeta6;
tmpMeta1 = omc_BaseHashSet_valueArrayList(threadData, _varr);
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
_lst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _lst;
}
DLLDirection
void omc_BaseHashSet_dumpHashSet(threadData_t *threadData, modelica_metatype _hashSet)
{
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
fputs(MMC_STRINGDATA(_OMC_LIT0),stdout);
omc_BaseHashSet_printHashSet(threadData, _hashSet);
fputs(MMC_STRINGDATA(_OMC_LIT1),stdout);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
DLLDirection
void omc_BaseHashSet_printHashSet(threadData_t *threadData, modelica_metatype _hashSet)
{
modelica_fnptr _printKey;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _hashSet;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 3));
_printKey = tmpMeta3;
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp5;
modelica_metatype tmpMeta6;
modelica_string __omcQ_24tmpVar0;
modelica_integer tmp7;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = omc_BaseHashSet_hashSetList(threadData, _hashSet);
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta6;
tmp5 = &__omcQ_24tmpVar1;
while(1) {
tmp7 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp7--;
}
if (tmp7 == 0) {
__omcQ_24tmpVar0 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 1)))) (threadData, _e);
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp7 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp5 = mmc_mk_nil();
tmpMeta4 = __omcQ_24tmpVar1;
}
fputs(MMC_STRINGDATA(stringDelimitList(tmpMeta4, _OMC_LIT1)),stdout);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_BaseHashSet_get2(threadData_t *threadData, modelica_metatype _key, modelica_metatype _keyIndices, modelica_fnptr _keyEqual, modelica_boolean *out_found)
{
modelica_integer _index;
modelica_boolean _found;
modelica_metatype _key2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_index = ((modelica_integer) -1);
_found = 1;
{
modelica_metatype _t;
for (tmpMeta1 = _keyIndices; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_t = MMC_CAR(tmpMeta1);
tmpMeta2 = _t;
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 1));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
tmp5 = mmc_unbox_integer(tmpMeta4);
_key2 = tmpMeta3;
_index = tmp5;
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqual), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqual), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqual), 2))), _key, _key2) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqual), 1)))) (threadData, _key, _key2)))
{
goto _return;
}
}
}
_found = 0;
_return: OMC_LABEL_UNUSED
if (out_found) { *out_found = _found; }
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp9 = mmc_unbox_integer(tmpMeta8);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_hashvec = tmpMeta6;
_varr = tmpMeta7;
_bsize = tmp9;
_hashFunc = tmpMeta11;
_keyEqual = tmpMeta12;
_hashindx = modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key)), _bsize);
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
DLLDirection
modelica_metatype omc_BaseHashSet_get(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet)
{
modelica_metatype _okey = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_okey = omc_BaseHashSet_get1(threadData, _key, _hashSet, NULL);
_return: OMC_LABEL_UNUSED
return _okey;
}
DLLDirection
modelica_boolean omc_BaseHashSet_hasAll(threadData_t *threadData, modelica_metatype _keys, modelica_metatype _hashSet)
{
modelica_boolean _b;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = 1;
{
modelica_metatype _key;
for (tmpMeta1 = _keys; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_key = MMC_CAR(tmpMeta1);
_b = omc_BaseHashSet_has(threadData, _key, _hashSet);
if((!_b))
{
goto _return;
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
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
DLLDirection
modelica_boolean omc_BaseHashSet_has(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmp8 = mmc_unbox_integer(tmpMeta7);
if (0 != tmp8) goto tmp3_end;
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
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
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
DLLDirection
modelica_metatype omc_BaseHashSet_delete(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet)
{
modelica_metatype _outHashSet = NULL;
modelica_integer _indx;
modelica_integer _n;
modelica_integer _bsize;
modelica_metatype _varr_1 = NULL;
modelica_metatype _varr = NULL;
modelica_metatype _hashvec = NULL;
modelica_metatype _fntpl = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _hashSet;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp5 = mmc_unbox_integer(tmpMeta4);
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
_hashvec = tmpMeta2;
_varr = tmpMeta3;
_bsize = tmp5;
_n = tmp7;
_fntpl = tmpMeta8;
tmpMeta10 = omc_BaseHashSet_get1(threadData, _key, _hashSet, &tmp9);
if (optionNone(tmpMeta10)) MMC_THROW_INTERNAL();
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
_indx = tmp9;
_varr_1 = omc_BaseHashSet_valueArrayClearnth(threadData, _varr, _indx);
tmpMeta12 = mmc_mk_box5(0, _hashvec, _varr_1, mmc_mk_integer(_bsize), mmc_mk_integer(_n), _fntpl);
_outHashSet = tmpMeta12;
_return: OMC_LABEL_UNUSED
return _outHashSet;
}
DLLDirection
modelica_metatype omc_BaseHashSet_addUnique(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashSet)
{
modelica_metatype _outHashSet = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _hashSet;
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
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp9 = mmc_unbox_integer(tmpMeta8);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
_hashvec = tmpMeta6;
_varr = tmpMeta7;
_bsize = tmp9;
_fntpl = tmpMeta10;
_hashFunc = tmpMeta11;
if (!(!omc_BaseHashSet_has(threadData, _key, _hashSet))) goto tmp3_end;
_indx = modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key)), _bsize);
_newpos = omc_BaseHashSet_valueArrayLength(threadData, _varr);
_varr_1 = omc_BaseHashSet_valueArrayAdd(threadData, _varr, _key);
_indexes = arrayGet(_hashvec,((modelica_integer) 1) + _indx);
tmpMeta13 = mmc_mk_box2(0, _key, mmc_mk_integer(_newpos));
tmpMeta12 = mmc_mk_cons(tmpMeta13, _indexes);
_hashvec_1 = arrayUpdate(_hashvec, ((modelica_integer) 1) + _indx, tmpMeta12);
_n_1 = omc_BaseHashSet_valueArrayLength(threadData, _varr_1);
tmpMeta14 = mmc_mk_box5(0, _hashvec_1, _varr_1, mmc_mk_integer(_bsize), mmc_mk_integer(_n_1), _fntpl);
tmpMeta1 = tmpMeta14;
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
_outHashSet = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outHashSet;
}
DLLDirection
modelica_metatype omc_BaseHashSet_addNoUpdCheck(threadData_t *threadData, modelica_metatype _entry, modelica_metatype _hashSet)
{
modelica_metatype _outHashSet = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _entry;
tmp4_2 = _hashSet;
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
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp9 = mmc_unbox_integer(tmpMeta8);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
_key = tmp4_1;
_hashvec = tmpMeta6;
_varr = tmpMeta7;
_bsize = tmp9;
_fntpl = tmpMeta10;
_hashFunc = tmpMeta11;
_indx = modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key)), _bsize);
_newpos = omc_BaseHashSet_valueArrayLength(threadData, _varr);
_varr_1 = omc_BaseHashSet_valueArrayAdd(threadData, _varr, _key);
_indexes = arrayGet(_hashvec,((modelica_integer) 1) + _indx);
tmpMeta13 = mmc_mk_box2(0, _key, mmc_mk_integer(_newpos));
tmpMeta12 = mmc_mk_cons(tmpMeta13, _indexes);
_hashvec_1 = arrayUpdate(_hashvec, ((modelica_integer) 1) + _indx, tmpMeta12);
_n_1 = omc_BaseHashSet_valueArrayLength(threadData, _varr_1);
tmpMeta14 = mmc_mk_box5(0, _hashvec_1, _varr_1, mmc_mk_integer(_bsize), mmc_mk_integer(_n_1), _fntpl);
tmpMeta1 = tmpMeta14;
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
_outHashSet = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outHashSet;
}
DLLDirection
modelica_metatype omc_BaseHashSet_add(threadData_t *threadData, modelica_metatype _entry, modelica_metatype _hashSet)
{
modelica_metatype _outHashSet = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _entry;
tmp4_2 = _hashSet;
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
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_integer tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp9 = mmc_unbox_integer(tmpMeta8);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmp11 = mmc_unbox_integer(tmpMeta10);
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
_key = tmp4_1;
_hashvec = tmpMeta6;
_varr = tmpMeta7;
_bsize = tmp9;
_n = tmp11;
_fntpl = tmpMeta12;
_hashFunc = tmpMeta13;
_fkey = omc_BaseHashSet_get1(threadData, _key, _hashSet ,&_indx);
if(isSome(_fkey))
{
_varr = omc_BaseHashSet_valueArraySetnth(threadData, _varr, _indx, _key);
}
else
{
_indx = modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key)), _bsize);
_newpos = omc_BaseHashSet_valueArrayLength(threadData, _varr);
_varr = omc_BaseHashSet_valueArrayAdd(threadData, _varr, _key);
_indexes = arrayGet(_hashvec,((modelica_integer) 1) + _indx);
tmpMeta15 = mmc_mk_box2(0, _key, mmc_mk_integer(_newpos));
tmpMeta14 = mmc_mk_cons(tmpMeta15, _indexes);
_hashvec = arrayUpdate(_hashvec, ((modelica_integer) 1) + _indx, tmpMeta14);
_n = omc_BaseHashSet_valueArrayLength(threadData, _varr);
}
tmpMeta16 = mmc_mk_box5(0, _hashvec, _varr, mmc_mk_integer(_bsize), mmc_mk_integer(_n), _fntpl);
tmpMeta1 = tmpMeta16;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta17;
modelica_integer tmp18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp18 = mmc_unbox_integer(tmpMeta17);
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 1));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 3));
_key = tmp4_1;
_bsize = tmp18;
_hashFunc = tmpMeta20;
_keystrFunc = tmpMeta21;
fputs(MMC_STRINGDATA(_OMC_LIT2),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT3),stdout);
fputs(MMC_STRINGDATA(intString(_bsize)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT4),stdout);
_s = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keystrFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keystrFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keystrFunc), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keystrFunc), 1)))) (threadData, _key);
tmpMeta22 = stringAppend(_s,_OMC_LIT5);
fputs(MMC_STRINGDATA(tmpMeta22),stdout);
_hval = modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key)), _bsize);
fputs(MMC_STRINGDATA(intString(_hval)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT1),stdout);
goto goto_2;
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
_outHashSet = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outHashSet;
}
DLLDirection
modelica_metatype omc_BaseHashSet_emptyHashSetWork(threadData_t *threadData, modelica_integer _szBucket, modelica_metatype _fntpl)
{
modelica_metatype _hashSet = NULL;
modelica_metatype _arr = NULL;
modelica_metatype _emptyarr = NULL;
modelica_integer _szArr;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_arr = arrayCreate(_szBucket, tmpMeta1);
_szArr = omc_BaseHashSet_bucketToValuesSize(threadData, _szBucket);
_emptyarr = arrayCreate(_szArr, mmc_mk_none());
tmpMeta2 = mmc_mk_box3(0, mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(_szArr), _emptyarr);
tmpMeta3 = mmc_mk_box5(0, _arr, tmpMeta2, mmc_mk_integer(_szBucket), mmc_mk_integer(((modelica_integer) 0)), _fntpl);
_hashSet = tmpMeta3;
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
DLLDirection
modelica_integer omc_BaseHashSet_bucketToValuesSize(threadData_t *threadData, modelica_integer _szBucket)
{
modelica_integer _szArr;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_szArr = ((modelica_integer)floor((0.6) * (((modelica_real)_szBucket))));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
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
