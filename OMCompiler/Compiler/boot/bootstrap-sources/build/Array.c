#include "omc_simulation_settings.h"
#include "Array.h"
#define _OMC_LIT0_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,0,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,2,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,1,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "..."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,3,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#include "util/modelica.h"
#include "Array_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Array_downheap(threadData_t *threadData, modelica_metatype __omcQ_24in_5FinArray, modelica_integer _n, modelica_integer _vIn);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Array_downheap(threadData_t *threadData, modelica_metatype __omcQ_24in_5FinArray, modelica_metatype _n, modelica_metatype _vIn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_downheap,2,0) {(void*) boxptr_Array_downheap,0}};
#define boxvar_Array_downheap MMC_REFSTRUCTLIT(boxvar_lit_Array_downheap)
DLLDirection
modelica_metatype omc_Array_filter(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _fun)
{
modelica_metatype _new_arr = NULL;
modelica_integer _new_size;
modelica_metatype _dummy = NULL;
modelica_integer _index;
modelica_integer tmp1;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_integer tmp6;
modelica_integer tmp7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_dummy = _dummy;
_index = ((modelica_integer) 1);
{
modelica_integer __omcQ_24tmpVar1;
modelica_integer __omcQ_24tmpVar0;
modelica_integer tmp2;
modelica_metatype _e_loopVar = 0;
modelica_integer tmp3;
modelica_metatype _e;
_e_loopVar = _arr;
tmp3 = 1;
__omcQ_24tmpVar1 = ((modelica_integer) 0);
while(1) {
tmp2 = 1;
while (tmp3 <= arrayLength(_e_loopVar)) {
_e = arrayGet(_e_loopVar, tmp3++);
if (mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fun), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fun), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fun), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fun), 1)))) (threadData, _e))) {
tmp2--;
break;
}
}
if (tmp2 == 0) {
__omcQ_24tmpVar0 = ((modelica_integer) 1);
__omcQ_24tmpVar1 = __omcQ_24tmpVar1 + __omcQ_24tmpVar0;
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp1 = __omcQ_24tmpVar1;
}
_new_size = arrayLength(_arr) - (tmp1);
_new_arr = arrayCreateNoInit(_new_size, _dummy);
{
modelica_metatype _e;
for (tmpMeta4 = _arr, tmp7 = arrayLength(tmpMeta4), tmp6 = 1; tmp6 <= tmp7; tmp6++)
{
_e = arrayGet(tmpMeta4,tmp6);
if((!mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fun), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fun), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fun), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fun), 1)))) (threadData, _e))))
{
arrayUpdateNoBoundsChecking(_new_arr, _index, _e);
_index = ((modelica_integer) 1) + _index;
}
}
}
_return: OMC_LABEL_UNUSED
return _new_arr;
}
DLLDirection
modelica_metatype omc_Array_generate(threadData_t *threadData, modelica_integer _n, modelica_fnptr _generator)
{
modelica_metatype _arr = NULL;
modelica_metatype _e = NULL;
modelica_metatype tmpMeta1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((_n <= ((modelica_integer) 0)))
{
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_arr = listArray(tmpMeta1);
}
else
{
_e = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_generator), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_generator), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_generator), 2)))) : ((modelica_metatype(*)(threadData_t*)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_generator), 1)))) (threadData);
_arr = arrayCreateNoInit(_n, _e);
arrayUpdateNoBoundsChecking(_arr, ((modelica_integer) 1), _e);
tmp2 = ((modelica_integer) 2); tmp3 = 1; tmp4 = _n;
if(!(((tmp3 > 0) && (tmp2 > tmp4)) || ((tmp3 < 0) && (tmp2 < tmp4))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp2, tmp4); _i += tmp3)
{
arrayUpdateNoBoundsChecking(_arr, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_generator), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_generator), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_generator), 2)))) : ((modelica_metatype(*)(threadData_t*)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_generator), 1)))) (threadData));
}
}
}
_return: OMC_LABEL_UNUSED
return _arr;
}
modelica_metatype boxptr_Array_generate(threadData_t *threadData, modelica_metatype _n, modelica_fnptr _generator)
{
modelica_integer tmp1;
modelica_metatype _arr = NULL;
tmp1 = mmc_unbox_integer(_n);
_arr = omc_Array_generate(threadData, tmp1, _generator);
return _arr;
}
DLLDirection
modelica_metatype omc_Array_threadMap(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2, modelica_fnptr _func)
{
modelica_metatype _outArray = NULL;
modelica_metatype _res = NULL;
modelica_integer _len1;
modelica_integer _len2;
modelica_metatype tmpMeta1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((arrayLength(_arr1) == ((modelica_integer) 0)))
{
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outArray = listArray(tmpMeta1);
goto _return;
}
_len1 = arrayLength(_arr1);
_len2 = arrayLength(_arr2);
if((_len1 != _len2))
{
MMC_THROW_INTERNAL();
}
_res = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), arrayGetNoBoundsChecking(_arr1, ((modelica_integer) 1)), arrayGetNoBoundsChecking(_arr2, ((modelica_integer) 1))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, arrayGetNoBoundsChecking(_arr1, ((modelica_integer) 1)), arrayGetNoBoundsChecking(_arr2, ((modelica_integer) 1)));
_outArray = arrayCreateNoInit(_len1, _res);
arrayUpdateNoBoundsChecking(_outArray, ((modelica_integer) 1), _res);
tmp2 = ((modelica_integer) 2); tmp3 = 1; tmp4 = _len1;
if(!(((tmp3 > 0) && (tmp2 > tmp4)) || ((tmp3 < 0) && (tmp2 < tmp4))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp2, tmp4); _i += tmp3)
{
arrayUpdateNoBoundsChecking(_outArray, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), arrayGetNoBoundsChecking(_arr1, _i), arrayGetNoBoundsChecking(_arr2, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, arrayGetNoBoundsChecking(_arr1, _i), arrayGetNoBoundsChecking(_arr2, _i)));
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_transpose(threadData_t *threadData, modelica_metatype _arr)
{
modelica_metatype _outArray = NULL;
modelica_integer _c_len;
modelica_integer _r_len;
modelica_metatype _val = NULL;
modelica_metatype _row = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((arrayLength(_arr) == ((modelica_integer) 0)))
{
_outArray = _arr;
goto _return;
}
_row = arrayGetNoBoundsChecking(_arr, ((modelica_integer) 1));
if((arrayLength(_row) == ((modelica_integer) 0)))
{
_outArray = _arr;
goto _return;
}
_val = arrayGetNoBoundsChecking(_row, ((modelica_integer) 1));
_c_len = arrayLength(_arr);
_r_len = arrayLength(_row);
_outArray = arrayCreateNoInit(_r_len, _row);
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _r_len;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_outArray, _i, arrayCreateNoInit(_c_len, _val));
}
}
tmp7 = ((modelica_integer) 1); tmp8 = 1; tmp9 = _r_len;
if(!(((tmp8 > 0) && (tmp7 > tmp9)) || ((tmp8 < 0) && (tmp7 < tmp9))))
{
modelica_integer _r;
for(_r = ((modelica_integer) 1); in_range_integer(_r, tmp7, tmp9); _r += tmp8)
{
tmp4 = ((modelica_integer) 1); tmp5 = 1; tmp6 = _c_len;
if(!(((tmp5 > 0) && (tmp4 > tmp6)) || ((tmp5 < 0) && (tmp4 < tmp6))))
{
modelica_integer _c;
for(_c = ((modelica_integer) 1); in_range_integer(_c, tmp4, tmp6); _c += tmp5)
{
_val = arrayGetNoBoundsChecking(arrayGetNoBoundsChecking(_arr, _c), _r);
arrayUpdateNoBoundsChecking(arrayGetNoBoundsChecking(_outArray, _r), _c, _val);
}
}
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_mapFold(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _func, modelica_metatype _arg, modelica_metatype *out_outArg)
{
modelica_metatype _outArray = NULL;
modelica_metatype _outArg = NULL;
modelica_integer _len;
modelica_metatype _res = NULL;
modelica_metatype tmpMeta1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArg = _arg;
_len = arrayLength(_arr);
if((_len == ((modelica_integer) 0)))
{
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outArray = listArray(tmpMeta1);
}
else
{
_res = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), arrayGetNoBoundsChecking(_arr, ((modelica_integer) 1)), _outArg ,&_outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, arrayGetNoBoundsChecking(_arr, ((modelica_integer) 1)), _outArg ,&_outArg);
_outArray = arrayCreateNoInit(_len, _res);
arrayUpdateNoBoundsChecking(_outArray, ((modelica_integer) 1), _res);
tmp2 = ((modelica_integer) 2); tmp3 = 1; tmp4 = _len;
if(!(((tmp3 > 0) && (tmp2 > tmp4)) || ((tmp3 < 0) && (tmp2 < tmp4))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp2, tmp4); _i += tmp3)
{
_res = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), arrayGetNoBoundsChecking(_arr, _i), _outArg ,&_outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, arrayGetNoBoundsChecking(_arr, _i), _outArg ,&_outArg);
arrayUpdateNoBoundsChecking(_outArray, _i, _res);
}
}
}
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outArray;
}
DLLDirection
modelica_integer omc_Array_compare(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2, modelica_fnptr _compFn)
{
modelica_integer _res;
modelica_integer _l1;
modelica_integer _l2;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_l1 = arrayLength(_arr1);
_l2 = arrayLength(_arr2);
_res = ((_l1 == _l2)?((modelica_integer) 0):((_l1 > _l2)?((modelica_integer) 1):((modelica_integer) -1)));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _l1;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_res = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_compFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_compFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_compFn), 2))), arrayGetNoBoundsChecking(_arr1, _i), arrayGetNoBoundsChecking(_arr2, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_compFn), 1)))) (threadData, arrayGetNoBoundsChecking(_arr1, _i), arrayGetNoBoundsChecking(_arr2, _i)));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_Array_compare(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2, modelica_fnptr _compFn)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_Array_compare(threadData, _arr1, _arr2, _compFn);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_metatype omc_Array_maxElement(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _lessFn)
{
modelica_metatype _res = NULL;
modelica_metatype _e = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = arrayGet(_arr,((modelica_integer) 1));
tmp1 = ((modelica_integer) 2); tmp2 = 1; tmp3 = arrayLength(_arr);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_e = arrayGetNoBoundsChecking(_arr, _i);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 2))), _res, _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 1)))) (threadData, _res, _e)))
{
_res = _e;
}
}
}
_return: OMC_LABEL_UNUSED
return _res;
}
DLLDirection
modelica_metatype omc_Array_minElement(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _lessFn)
{
modelica_metatype _res = NULL;
modelica_metatype _e = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = arrayGet(_arr,((modelica_integer) 1));
tmp1 = ((modelica_integer) 2); tmp2 = 1; tmp3 = arrayLength(_arr);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_e = arrayGetNoBoundsChecking(_arr, _i);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 2))), _e, _res) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 1)))) (threadData, _e, _res)))
{
_res = _e;
}
}
}
_return: OMC_LABEL_UNUSED
return _res;
}
DLLDirection
modelica_boolean omc_Array_any(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _inFunc)
{
modelica_boolean _outResult;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_integer tmp4;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _e;
for (tmpMeta1 = _arr, tmp4 = arrayLength(tmpMeta1), tmp3 = 1; tmp3 <= tmp4; tmp3++)
{
_e = arrayGet(tmpMeta1,tmp3);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _e)))
{
_outResult = 1;
goto _return;
}
}
}
_outResult = 0;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outResult;
}
modelica_metatype boxptr_Array_any(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _inFunc)
{
modelica_boolean _outResult;
modelica_metatype out_outResult;
_outResult = omc_Array_any(threadData, _arr, _inFunc);
out_outResult = mmc_mk_icon(_outResult);
return out_outResult;
}
DLLDirection
modelica_boolean omc_Array_all(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _inFunc)
{
modelica_boolean _outResult;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_integer tmp4;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _e;
for (tmpMeta1 = _arr, tmp4 = arrayLength(tmpMeta1), tmp3 = 1; tmp3 <= tmp4; tmp3++)
{
_e = arrayGet(tmpMeta1,tmp3);
if((!mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _e))))
{
_outResult = 0;
goto _return;
}
}
}
_outResult = 1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outResult;
}
modelica_metatype boxptr_Array_all(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _inFunc)
{
modelica_boolean _outResult;
modelica_metatype out_outResult;
_outResult = omc_Array_all(threadData, _arr, _inFunc);
out_outResult = mmc_mk_icon(_outResult);
return out_outResult;
}
DLLDirection
modelica_metatype omc_Array_remove(threadData_t *threadData, modelica_metatype _arr, modelica_integer _index)
{
modelica_metatype _outArr = NULL;
modelica_integer _len;
modelica_boolean tmp1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_len = arrayLength(_arr);
tmp1 = ((_index <= _len) && (_index >= ((modelica_integer) 1)));
if (1 /* true */ != tmp1) MMC_THROW_INTERNAL();
if((_len <= ((modelica_integer) 1)))
{
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_outArr = listArray(tmpMeta2);
}
else
{
_outArr = arrayCreateNoInit(((modelica_integer) -1) + _len, arrayGet(_arr,((modelica_integer) 1)) /* DAE.ASUB */);
tmp3 = ((modelica_integer) 1); tmp4 = 1; tmp5 = ((modelica_integer) -1) + _index;
if(!(((tmp4 > 0) && (tmp3 > tmp5)) || ((tmp4 < 0) && (tmp3 < tmp5))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp3, tmp5); _i += tmp4)
{
arrayUpdateNoBoundsChecking(_outArr, _i, arrayGetNoBoundsChecking(_arr, _i));
}
}
tmp6 = ((modelica_integer) 1) + _index; tmp7 = 1; tmp8 = _len;
if(!(((tmp7 > 0) && (tmp6 > tmp8)) || ((tmp7 < 0) && (tmp6 < tmp8))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1) + _index; in_range_integer(_i, tmp6, tmp8); _i += tmp7)
{
arrayUpdateNoBoundsChecking(_outArr, ((modelica_integer) -1) + _i, arrayGetNoBoundsChecking(_arr, _i));
}
}
}
_return: OMC_LABEL_UNUSED
return _outArr;
}
modelica_metatype boxptr_Array_remove(threadData_t *threadData, modelica_metatype _arr, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_metatype _outArr = NULL;
tmp1 = mmc_unbox_integer(_index);
_outArr = omc_Array_remove(threadData, _arr, tmp1);
return _outArr;
}
DLLDirection
modelica_metatype omc_Array_insertList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farr, modelica_metatype _lst, modelica_integer _startPos)
{
modelica_metatype _arr = NULL;
modelica_integer _i;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_arr = __omcQ_24in_5Farr;
_i = _startPos;
{
modelica_metatype _e;
for (tmpMeta1 = _lst; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_e = MMC_CAR(tmpMeta1);
arrayUpdate(_arr,_i,_e);
_i = ((modelica_integer) 1) + _i;
}
}
_return: OMC_LABEL_UNUSED
return _arr;
}
modelica_metatype boxptr_Array_insertList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farr, modelica_metatype _lst, modelica_metatype _startPos)
{
modelica_integer tmp1;
modelica_metatype _arr = NULL;
tmp1 = mmc_unbox_integer(_startPos);
_arr = omc_Array_insertList(threadData, __omcQ_24in_5Farr, _lst, tmp1);
return _arr;
}
DLLDirection
modelica_boolean omc_Array_isLess(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2, modelica_fnptr _lessFn)
{
modelica_boolean _res;
modelica_integer _len1;
modelica_integer _len2;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_len1 = arrayLength(_arr1);
_len2 = arrayLength(_arr2);
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = modelica_integer_min((modelica_integer)(_len1),(modelica_integer)(_len2));
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_e1 = arrayGetNoBoundsChecking(_arr1, _i);
_e2 = arrayGetNoBoundsChecking(_arr2, _i);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 2))), _e1, _e2) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 1)))) (threadData, _e1, _e2)))
{
_res = 1;
goto _return;
}
else
{
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 2))), _e2, _e1) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_lessFn), 1)))) (threadData, _e2, _e1)))
{
_res = 0;
goto _return;
}
}
}
}
_res = (_len1 < _len2);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_Array_isLess(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2, modelica_fnptr _lessFn)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_Array_isLess(threadData, _arr1, _arr2, _lessFn);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_boolean omc_Array_allEqual(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _pred)
{
modelica_boolean _equal;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_equal = 1;
if((arrayLength(_arr) == ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) 2); tmp2 = 1; tmp3 = arrayLength(_arr);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
if((!mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pred), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pred), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pred), 2))), arrayGetNoBoundsChecking(_arr, ((modelica_integer) 1)), arrayGetNoBoundsChecking(_arr, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pred), 1)))) (threadData, arrayGetNoBoundsChecking(_arr, ((modelica_integer) 1)), arrayGetNoBoundsChecking(_arr, _i)))))
{
_equal = 0;
goto _return;
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _equal;
}
modelica_metatype boxptr_Array_allEqual(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _pred)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_Array_allEqual(threadData, _arr, _pred);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLDirection
modelica_boolean omc_Array_isEqualOnTrue(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2, modelica_fnptr _pred)
{
modelica_boolean _equal;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_equal = (arrayLength(_arr1) == arrayLength(_arr2));
if((!_equal))
{
goto _return;
}
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_arr1);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
if((!mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pred), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pred), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pred), 2))), arrayGetNoBoundsChecking(_arr1, _i), arrayGetNoBoundsChecking(_arr2, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pred), 1)))) (threadData, arrayGetNoBoundsChecking(_arr1, _i), arrayGetNoBoundsChecking(_arr2, _i)))))
{
_equal = 0;
goto _return;
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _equal;
}
modelica_metatype boxptr_Array_isEqualOnTrue(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2, modelica_fnptr _pred)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_Array_isEqualOnTrue(threadData, _arr1, _arr2, _pred);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLDirection
modelica_boolean omc_Array_isEqual(threadData_t *threadData, modelica_metatype _inArr1, modelica_metatype _inArr2)
{
modelica_boolean _outIsEqual;
modelica_integer _arrLength;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIsEqual = 1;
_arrLength = arrayLength(_inArr1);
if((!(_arrLength == arrayLength(_inArr2))))
{
MMC_THROW_INTERNAL();
}
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _arrLength;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
if((!valueEq(arrayGet(_inArr1,_i) /* DAE.ASUB */, arrayGet(_inArr2,_i) /* DAE.ASUB */)))
{
_outIsEqual = 0;
break;
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outIsEqual;
}
modelica_metatype boxptr_Array_isEqual(threadData_t *threadData, modelica_metatype _inArr1, modelica_metatype _inArr2)
{
modelica_boolean _outIsEqual;
modelica_metatype out_outIsEqual;
_outIsEqual = omc_Array_isEqual(threadData, _inArr1, _inArr2);
out_outIsEqual = mmc_mk_icon(_outIsEqual);
return out_outIsEqual;
}
DLLDirection
modelica_integer omc_Array_hashIntArray(threadData_t *threadData, modelica_metatype _arr)
{
modelica_integer _hash;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hash = ((modelica_integer) 5381);
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_arr);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_hash = modelica_integer_mod((((modelica_integer) 31)) * (_hash) + (mmc_unbox_integer(arrayGetNoBoundsChecking(_arr, _i))), ((modelica_integer) 536870911));
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _hash;
}
modelica_metatype boxptr_Array_hashIntArray(threadData_t *threadData, modelica_metatype _arr)
{
modelica_integer _hash;
modelica_metatype out_hash;
_hash = omc_Array_hashIntArray(threadData, _arr);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
DLLDirection
modelica_string omc_Array_toString(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inPrintFunc, modelica_string _inNameStr, modelica_string _inBeginStr, modelica_string _inDelimitStr, modelica_string _inEndStr, modelica_boolean _inPrintEmpty, modelica_integer _maxLength)
{
modelica_string _outString = NULL;
modelica_metatype _lst = NULL;
modelica_string _endStr = NULL;
modelica_metatype tmpMeta1;
modelica_string tmp2 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_endStr = _inEndStr;
if(((_maxLength > ((modelica_integer) 0)) && (arrayLength(_inArray) > _maxLength)))
{
_lst = omc_List_firstN(threadData, arrayList(_inArray), _maxLength);
tmpMeta1 = mmc_mk_cons(_inDelimitStr, mmc_mk_cons(_OMC_LIT4, mmc_mk_cons(_inEndStr, MMC_REFSTRUCTLIT(mmc_nil))));
_endStr = stringAppendList(tmpMeta1);
}
else
{
_lst = arrayList(_inArray);
}
{
modelica_metatype tmp5_1;modelica_boolean tmp5_2;
tmp5_1 = _lst;
tmp5_2 = _inPrintEmpty;
{
modelica_string _str = NULL;
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 3; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
modelica_metatype tmpMeta7;
if (1 /* true */ != tmp5_2) goto tmp4_end;
if (!listEmpty(tmp5_1)) goto tmp4_end;
tmpMeta7 = mmc_mk_cons(_inNameStr, mmc_mk_cons(_inBeginStr, mmc_mk_cons(_inEndStr, MMC_REFSTRUCTLIT(mmc_nil))));
tmp2 = stringAppendList(tmpMeta7);
goto tmp4_done;
}
case 1: {
if (0 /* false */ != tmp5_2) goto tmp4_end;
if (!listEmpty(tmp5_1)) goto tmp4_end;
tmp2 = _inNameStr;
goto tmp4_done;
}
case 2: {
modelica_metatype tmpMeta8;
_str = stringDelimitList(omc_List_map(threadData, _lst, ((modelica_fnptr) _inPrintFunc)), _inDelimitStr);
tmpMeta8 = mmc_mk_cons(_inNameStr, mmc_mk_cons(_inBeginStr, mmc_mk_cons(_str, mmc_mk_cons(_endStr, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp2 = stringAppendList(tmpMeta8);
goto tmp4_done;
}
}
goto tmp4_end;
tmp4_end: ;
}
goto goto_3;
goto_3:;
MMC_THROW_INTERNAL();
goto tmp4_done;
tmp4_done:;
}
}
_outString = tmp2;
_return: OMC_LABEL_UNUSED
return _outString;
}
modelica_metatype boxptr_Array_toString(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inPrintFunc, modelica_metatype _inNameStr, modelica_metatype _inBeginStr, modelica_metatype _inDelimitStr, modelica_metatype _inEndStr, modelica_metatype _inPrintEmpty, modelica_metatype _maxLength)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_inPrintEmpty);
tmp2 = mmc_unbox_integer(_maxLength);
_outString = omc_Array_toString(threadData, _inArray, _inPrintFunc, _inNameStr, _inBeginStr, _inDelimitStr, _inEndStr, tmp1, tmp2);
return _outString;
}
DLLDirection
modelica_metatype omc_Array_reverse(threadData_t *threadData, modelica_metatype _inArray)
{
modelica_metatype _outArray = NULL;
modelica_integer _size;
modelica_integer _i;
modelica_metatype _elem1 = NULL;
modelica_metatype _elem2 = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = _inArray;
_size = arrayLength(_inArray);
tmp1 = 1.0; tmp2 = 1; tmp3 = (0.5) * (((modelica_real)_size));
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = 1.0; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_elem1 = arrayGet(_inArray, _i);
_elem2 = arrayGet(_inArray, ((modelica_integer) 1) + (_size - _i));
_outArray = arrayUpdate(_outArray, _i, _elem2);
_outArray = arrayUpdate(_outArray, ((modelica_integer) 1) + (_size - _i), _elem1);
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_getMemberOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inArray, modelica_fnptr _inCompFunc, modelica_integer *out_outIndex)
{
modelica_metatype _outElement = NULL;
modelica_integer _outIndex;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_inArray);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCompFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCompFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCompFunc), 2))), _inValue, arrayGetNoBoundsChecking(_inArray, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCompFunc), 1)))) (threadData, _inValue, arrayGetNoBoundsChecking(_inArray, _i))))
{
_outElement = arrayGetNoBoundsChecking(_inArray, _i);
_outIndex = _i;
goto _return;
}
}
}
MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
if (out_outIndex) { *out_outIndex = _outIndex; }
return _outElement;
}
modelica_metatype boxptr_Array_getMemberOnTrue(threadData_t *threadData, modelica_metatype _inValue, modelica_metatype _inArray, modelica_fnptr _inCompFunc, modelica_metatype *out_outIndex)
{
modelica_integer _outIndex;
modelica_metatype _outElement = NULL;
_outElement = omc_Array_getMemberOnTrue(threadData, _inValue, _inArray, _inCompFunc, &_outIndex);
if (out_outIndex) { *out_outIndex = mmc_mk_icon(_outIndex); }
return _outElement;
}
DLLDirection
modelica_integer omc_Array_position(threadData_t *threadData, modelica_metatype _inArray, modelica_metatype _inElement, modelica_integer _inFilledSize)
{
modelica_integer _outIndex;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _inFilledSize;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
if(valueEq(_inElement, arrayGet(_inArray,_i) /* DAE.ASUB */))
{
_outIndex = _i;
goto _return;
}
}
}
_outIndex = ((modelica_integer) 0);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outIndex;
}
modelica_metatype boxptr_Array_position(threadData_t *threadData, modelica_metatype _inArray, modelica_metatype _inElement, modelica_metatype _inFilledSize)
{
modelica_integer tmp1;
modelica_integer _outIndex;
modelica_metatype out_outIndex;
tmp1 = mmc_unbox_integer(_inFilledSize);
_outIndex = omc_Array_position(threadData, _inArray, _inElement, tmp1);
out_outIndex = mmc_mk_icon(_outIndex);
return out_outIndex;
}
DLLDirection
modelica_metatype omc_Array_getRange(threadData_t *threadData, modelica_integer _inStart, modelica_integer _inEnd, modelica_metatype _inArray)
{
modelica_metatype _outList = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _value = NULL;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outList = tmpMeta1;
if((_inStart > arrayLength(_inArray)))
{
MMC_THROW_INTERNAL();
}
tmp3 = _inStart; tmp4 = 1; tmp5 = _inEnd;
if(!(((tmp4 > 0) && (tmp3 > tmp5)) || ((tmp4 < 0) && (tmp3 < tmp5))))
{
modelica_integer _i;
for(_i = _inStart; in_range_integer(_i, tmp3, tmp5); _i += tmp4)
{
_value = arrayGet(_inArray, _i);
tmpMeta2 = mmc_mk_cons(_value, _outList);
_outList = tmpMeta2;
}
}
_return: OMC_LABEL_UNUSED
return _outList;
}
modelica_metatype boxptr_Array_getRange(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inEnd, modelica_metatype _inArray)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outList = NULL;
modelica_metatype tmpMeta3;
tmp1 = mmc_unbox_integer(_inStart);
tmp2 = mmc_unbox_integer(_inEnd);
_outList = omc_Array_getRange(threadData, tmp1, tmp2, _inArray);
return _outList;
}
DLLDirection
modelica_metatype omc_Array_setRange(threadData_t *threadData, modelica_integer _inStart, modelica_integer _inEnd, modelica_metatype _inArray, modelica_metatype _inValue)
{
modelica_metatype _outArray = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = _inArray;
if((_inStart > arrayLength(_inArray)))
{
MMC_THROW_INTERNAL();
}
tmp1 = _inStart; tmp2 = 1; tmp3 = _inEnd;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = _inStart; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdate(_inArray, _i, _inValue);
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
modelica_metatype boxptr_Array_setRange(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inEnd, modelica_metatype _inArray, modelica_metatype _inValue)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outArray = NULL;
tmp1 = mmc_unbox_integer(_inStart);
tmp2 = mmc_unbox_integer(_inEnd);
_outArray = omc_Array_setRange(threadData, tmp1, tmp2, _inArray, _inValue);
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_createIntRange(threadData_t *threadData, modelica_integer _inLen)
{
modelica_metatype _outArray = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = arrayCreateNoInit(_inLen, mmc_mk_integer(((modelica_integer) 0)));
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _inLen;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_outArray, _i, mmc_mk_integer(_i));
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
modelica_metatype boxptr_Array_createIntRange(threadData_t *threadData, modelica_metatype _inLen)
{
modelica_integer tmp1;
modelica_metatype _outArray = NULL;
tmp1 = mmc_unbox_integer(_inLen);
_outArray = omc_Array_createIntRange(threadData, tmp1);
return _outArray;
}
DLLDirection
void omc_Array_copyRange(threadData_t *threadData, modelica_metatype _srcArray, modelica_metatype _dstArray, modelica_integer _srcFirst, modelica_integer _srcLast, modelica_integer _dstPos)
{
modelica_integer _offset;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_offset = _dstPos - _srcFirst;
if((((_srcFirst > _srcLast) || (_srcLast > arrayLength(_srcArray))) || (_offset + _srcLast > arrayLength(_dstArray))))
{
MMC_THROW_INTERNAL();
}
tmp1 = _srcFirst; tmp2 = 1; tmp3 = _srcLast;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = _srcFirst; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_dstArray, _offset + _i, arrayGetNoBoundsChecking(_srcArray, _i));
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
void boxptr_Array_copyRange(threadData_t *threadData, modelica_metatype _srcArray, modelica_metatype _dstArray, modelica_metatype _srcFirst, modelica_metatype _srcLast, modelica_metatype _dstPos)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
tmp1 = mmc_unbox_integer(_srcFirst);
tmp2 = mmc_unbox_integer(_srcLast);
tmp3 = mmc_unbox_integer(_dstPos);
omc_Array_copyRange(threadData, _srcArray, _dstArray, tmp1, tmp2, tmp3);
return;
}
DLLDirection
modelica_metatype omc_Array_copyN(threadData_t *threadData, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest, modelica_integer _inN, modelica_integer _srcOffset, modelica_integer _dstOffset)
{
modelica_metatype _outArray = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = _inArrayDest;
if(((_inN + _dstOffset > arrayLength(_inArrayDest)) || (_inN + _srcOffset > arrayLength(_inArraySrc))))
{
MMC_THROW_INTERNAL();
}
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _inN;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_outArray, _i + _dstOffset, arrayGetNoBoundsChecking(_inArraySrc, _i + _srcOffset));
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
modelica_metatype boxptr_Array_copyN(threadData_t *threadData, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest, modelica_metatype _inN, modelica_metatype _srcOffset, modelica_metatype _dstOffset)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _outArray = NULL;
tmp1 = mmc_unbox_integer(_inN);
tmp2 = mmc_unbox_integer(_srcOffset);
tmp3 = mmc_unbox_integer(_dstOffset);
_outArray = omc_Array_copyN(threadData, _inArraySrc, _inArrayDest, tmp1, tmp2, tmp3);
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_copy(threadData_t *threadData, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest)
{
modelica_metatype _outArray = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = _inArrayDest;
if((arrayLength(_inArraySrc) > arrayLength(_inArrayDest)))
{
MMC_THROW_INTERNAL();
}
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_inArraySrc);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_outArray, _i, arrayGetNoBoundsChecking(_inArraySrc, _i));
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_join(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2)
{
modelica_metatype _outArray = NULL;
modelica_integer _len1;
modelica_integer _len2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_len1 = arrayLength(_arr1);
_len2 = arrayLength(_arr2);
if((_len1 == ((modelica_integer) 0)))
{
_outArray = arrayCopy(_arr2);
}
else
{
if((_len2 == ((modelica_integer) 0)))
{
_outArray = arrayCopy(_arr1);
}
else
{
_outArray = arrayCreateNoInit(_len1 + _len2, arrayGet(_arr1,((modelica_integer) 1)) /* DAE.ASUB */);
omc_Array_copyRange(threadData, _arr1, _outArray, ((modelica_integer) 1), _len1, ((modelica_integer) 1));
omc_Array_copyRange(threadData, _arr2, _outArray, ((modelica_integer) 1), _len2, ((modelica_integer) 1) + _len1);
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_appendList(threadData_t *threadData, modelica_metatype _arr, modelica_metatype _lst)
{
modelica_metatype _outArray = NULL;
modelica_integer _arr_len;
modelica_integer _lst_len;
modelica_metatype _e = NULL;
modelica_metatype _rest = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_arr_len = arrayLength(_arr);
if(listEmpty(_lst))
{
_outArray = _arr;
}
else
{
if((_arr_len == ((modelica_integer) 0)))
{
_outArray = listArray(_lst);
}
else
{
_lst_len = listLength(_lst);
_outArray = arrayCreateNoInit(_arr_len + _lst_len, arrayGet(_arr,((modelica_integer) 1)) /* DAE.ASUB */);
omc_Array_copy(threadData, _arr, _outArray);
_rest = _lst;
tmp4 = ((modelica_integer) 1) + _arr_len; tmp5 = 1; tmp6 = _arr_len + _lst_len;
if(!(((tmp5 > 0) && (tmp4 > tmp6)) || ((tmp5 < 0) && (tmp4 < tmp6))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1) + _arr_len; in_range_integer(_i, tmp4, tmp6); _i += tmp5)
{
tmpMeta1 = _rest;
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
_e = tmpMeta2;
_rest = tmpMeta3;
arrayUpdateNoBoundsChecking(_outArray, _i, _e);
}
}
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_appendToElement(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inElements, modelica_metatype _inArray)
{
modelica_metatype _outArray = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = arrayUpdate(_inArray, _inIndex, listAppend(arrayGet(_inArray,_inIndex) /* DAE.ASUB */, _inElements));
_return: OMC_LABEL_UNUSED
return _outArray;
}
modelica_metatype boxptr_Array_appendToElement(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inElements, modelica_metatype _inArray)
{
modelica_integer tmp1;
modelica_metatype _outArray = NULL;
tmp1 = mmc_unbox_integer(_inIndex);
_outArray = omc_Array_appendToElement(threadData, tmp1, _inElements, _inArray);
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_consToElement(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inElement, modelica_metatype _inArray)
{
modelica_metatype _outArray = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_cons(_inElement, arrayGet(_inArray,_inIndex) /* DAE.ASUB */);
_outArray = arrayUpdate(_inArray, _inIndex, tmpMeta1);
_return: OMC_LABEL_UNUSED
return _outArray;
}
modelica_metatype boxptr_Array_consToElement(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inElement, modelica_metatype _inArray)
{
modelica_integer tmp1;
modelica_metatype _outArray = NULL;
tmp1 = mmc_unbox_integer(_inIndex);
_outArray = omc_Array_consToElement(threadData, tmp1, _inElement, _inArray);
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_expandOnDemand(threadData_t *threadData, modelica_integer _inNewSize, modelica_metatype _inArray, modelica_real _inExpansionFactor, modelica_metatype _inFillValue)
{
modelica_metatype _outArray = NULL;
modelica_integer _new_size;
modelica_integer _len;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_len = arrayLength(_inArray);
if((_inNewSize <= _len))
{
_outArray = _inArray;
}
else
{
_new_size = ((modelica_integer)floor((((modelica_real)_len)) * (_inExpansionFactor)));
_outArray = arrayCreateNoInit(_new_size, _inFillValue);
omc_Array_copy(threadData, _inArray, _outArray);
omc_Array_setRange(threadData, ((modelica_integer) 1) + _len, _new_size, _outArray, _inFillValue);
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
modelica_metatype boxptr_Array_expandOnDemand(threadData_t *threadData, modelica_metatype _inNewSize, modelica_metatype _inArray, modelica_metatype _inExpansionFactor, modelica_metatype _inFillValue)
{
modelica_integer tmp1;
modelica_real tmp2;
modelica_metatype _outArray = NULL;
tmp1 = mmc_unbox_integer(_inNewSize);
tmp2 = mmc_unbox_real(_inExpansionFactor);
_outArray = omc_Array_expandOnDemand(threadData, tmp1, _inArray, tmp2, _inFillValue);
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_expand(threadData_t *threadData, modelica_integer _inN, modelica_metatype _inArray, modelica_metatype _inFill)
{
modelica_metatype _outArray = NULL;
modelica_integer _len;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((_inN < ((modelica_integer) 1)))
{
_outArray = _inArray;
}
else
{
_len = arrayLength(_inArray);
_outArray = arrayCreateNoInit(_len + _inN, _inFill);
omc_Array_copy(threadData, _inArray, _outArray);
omc_Array_setRange(threadData, ((modelica_integer) 1) + _len, _len + _inN, _outArray, _inFill);
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
modelica_metatype boxptr_Array_expand(threadData_t *threadData, modelica_metatype _inN, modelica_metatype _inArray, modelica_metatype _inFill)
{
modelica_integer tmp1;
modelica_metatype _outArray = NULL;
tmp1 = mmc_unbox_integer(_inN);
_outArray = omc_Array_expand(threadData, tmp1, _inArray, _inFill);
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_expandToSize(threadData_t *threadData, modelica_integer _inNewSize, modelica_metatype _inArray, modelica_metatype _inFill)
{
modelica_metatype _outArray = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((_inNewSize <= arrayLength(_inArray)))
{
_outArray = _inArray;
}
else
{
_outArray = arrayCreate(_inNewSize, _inFill);
omc_Array_copy(threadData, _inArray, _outArray);
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
modelica_metatype boxptr_Array_expandToSize(threadData_t *threadData, modelica_metatype _inNewSize, modelica_metatype _inArray, modelica_metatype _inFill)
{
modelica_integer tmp1;
modelica_metatype _outArray = NULL;
tmp1 = mmc_unbox_integer(_inNewSize);
_outArray = omc_Array_expandToSize(threadData, tmp1, _inArray, _inFill);
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_replaceAtWithFill(threadData_t *threadData, modelica_integer _inPos, modelica_metatype _inTypeReplace, modelica_metatype _inTypeFill, modelica_metatype _inArray)
{
modelica_metatype _outArray = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = omc_Array_expandToSize(threadData, _inPos, _inArray, _inTypeFill);
arrayUpdate(_outArray, _inPos, _inTypeReplace);
_return: OMC_LABEL_UNUSED
return _outArray;
}
modelica_metatype boxptr_Array_replaceAtWithFill(threadData_t *threadData, modelica_metatype _inPos, modelica_metatype _inTypeReplace, modelica_metatype _inTypeFill, modelica_metatype _inArray)
{
modelica_integer tmp1;
modelica_metatype _outArray = NULL;
tmp1 = mmc_unbox_integer(_inPos);
_outArray = omc_Array_replaceAtWithFill(threadData, tmp1, _inTypeReplace, _inTypeFill, _inArray);
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_getIndexFirst(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inArray)
{
modelica_metatype _outElement = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outElement = arrayGet(_inArray, _inIndex);
_return: OMC_LABEL_UNUSED
return _outElement;
}
modelica_metatype boxptr_Array_getIndexFirst(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inArray)
{
modelica_integer tmp1;
modelica_metatype _outElement = NULL;
tmp1 = mmc_unbox_integer(_inIndex);
_outElement = omc_Array_getIndexFirst(threadData, tmp1, _inArray);
return _outElement;
}
DLLDirection
void omc_Array_updateIndexFirst(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inValue, modelica_metatype _inArray)
{
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
arrayUpdate(_inArray, _inIndex, _inValue);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
void boxptr_Array_updateIndexFirst(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inValue, modelica_metatype _inArray)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inIndex);
omc_Array_updateIndexFirst(threadData, tmp1, _inValue, _inArray);
return;
}
DLLDirection
modelica_metatype omc_Array_reduce(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inReduceFunc)
{
modelica_metatype _outResult = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outResult = arrayGet(_inArray, ((modelica_integer) 1));
tmp1 = ((modelica_integer) 2); tmp2 = 1; tmp3 = arrayLength(_inArray);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_outResult = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inReduceFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inReduceFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inReduceFunc), 2))), _outResult, arrayGet(_inArray, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inReduceFunc), 1)))) (threadData, _outResult, arrayGet(_inArray, _i));
}
}
_return: OMC_LABEL_UNUSED
return _outResult;
}
DLLDirection
modelica_metatype omc_Array_foldIndex(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue)
{
modelica_metatype _outResult = NULL;
modelica_metatype _e = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outResult = _inStartValue;
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_inArray);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_e = arrayGet(_inArray, _i);
_outResult = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))), _e, mmc_mk_integer(_i), _outResult) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, _e, mmc_mk_integer(_i), _outResult);
}
}
_return: OMC_LABEL_UNUSED
return _outResult;
}
DLLDirection
modelica_metatype omc_Array_fold(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue)
{
modelica_metatype _outResult = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_integer tmp4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outResult = _inStartValue;
{
modelica_metatype _e;
for (tmpMeta1 = _inArray, tmp4 = arrayLength(tmpMeta1), tmp3 = 1; tmp3 <= tmp4; tmp3++)
{
_e = arrayGet(tmpMeta1,tmp3);
_outResult = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))), _e, _outResult) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, _e, _outResult);
}
}
_return: OMC_LABEL_UNUSED
return _outResult;
}
DLLDirection
modelica_metatype omc_Array_mapList(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc)
{
modelica_metatype _outArray = NULL;
modelica_integer _i;
modelica_integer _len;
modelica_metatype _res = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_i = ((modelica_integer) 2);
_len = listLength(_inList);
if((_len == ((modelica_integer) 0)))
{
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outArray = listArray(tmpMeta1);
}
else
{
_res = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), listHead(_inList)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, listHead(_inList));
_outArray = arrayCreateNoInit(_len, _res);
arrayUpdate(_outArray, ((modelica_integer) 1), _res);
{
modelica_metatype _e;
for (tmpMeta2 = listRest(_inList); !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_e = MMC_CAR(tmpMeta2);
arrayUpdate(_outArray, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _e));
_i = ((modelica_integer) 1) + _i;
}
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_map1Ind(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc, modelica_metatype _inArg)
{
modelica_metatype _outArray = NULL;
modelica_integer _len;
modelica_metatype _res = NULL;
modelica_metatype tmpMeta1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_len = arrayLength(_inArray);
if((_len == ((modelica_integer) 0)))
{
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outArray = listArray(tmpMeta1);
}
else
{
_res = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, ((modelica_integer) 1)), mmc_mk_integer(((modelica_integer) 1)), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, ((modelica_integer) 1)), mmc_mk_integer(((modelica_integer) 1)), _inArg);
_outArray = arrayCreateNoInit(_len, _res);
arrayUpdate(_outArray, ((modelica_integer) 1), _res);
tmp2 = ((modelica_integer) 2); tmp3 = 1; tmp4 = _len;
if(!(((tmp3 > 0) && (tmp2 > tmp4)) || ((tmp3 < 0) && (tmp2 < tmp4))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp2, tmp4); _i += tmp3)
{
arrayUpdate(_outArray, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, _i), mmc_mk_integer(_i), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, _i), mmc_mk_integer(_i), _inArg));
}
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_map1(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc, modelica_metatype _inArg)
{
modelica_metatype _outArray = NULL;
modelica_integer _len;
modelica_metatype _res = NULL;
modelica_metatype tmpMeta1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_len = arrayLength(_inArray);
if((_len == ((modelica_integer) 0)))
{
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outArray = listArray(tmpMeta1);
}
else
{
_res = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, ((modelica_integer) 1)), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, ((modelica_integer) 1)), _inArg);
_outArray = arrayCreateNoInit(_len, _res);
arrayUpdate(_outArray, ((modelica_integer) 1), _res);
tmp2 = ((modelica_integer) 2); tmp3 = 1; tmp4 = _len;
if(!(((tmp3 > 0) && (tmp2 > tmp4)) || ((tmp3 < 0) && (tmp2 < tmp4))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp2, tmp4); _i += tmp3)
{
arrayUpdate(_outArray, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, _i), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, _i), _inArg));
}
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_map(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc)
{
modelica_metatype _outArray = NULL;
modelica_integer _len;
modelica_metatype _res = NULL;
modelica_metatype tmpMeta1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_len = arrayLength(_inArray);
if((_len == ((modelica_integer) 0)))
{
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outArray = listArray(tmpMeta1);
}
else
{
_res = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, ((modelica_integer) 1))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, ((modelica_integer) 1)));
_outArray = arrayCreateNoInit(_len, _res);
arrayUpdateNoBoundsChecking(_outArray, ((modelica_integer) 1), _res);
tmp2 = ((modelica_integer) 2); tmp3 = 1; tmp4 = _len;
if(!(((tmp3 > 0) && (tmp2 > tmp4)) || ((tmp3 < 0) && (tmp2 < tmp4))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp2, tmp4); _i += tmp3)
{
arrayUpdateNoBoundsChecking(_outArray, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, _i)));
}
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_select(threadData_t *threadData, modelica_metatype _inArray, modelica_metatype _inIndices)
{
modelica_metatype _outArray = NULL;
modelica_integer _i;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_i = ((modelica_integer) 1);
_outArray = arrayCreateNoInit(listLength(_inIndices), arrayGet(_inArray,((modelica_integer) 1)) /* DAE.ASUB */);
{
modelica_metatype _e;
for (tmpMeta1 = _inIndices; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_e = MMC_CAR(tmpMeta1);
arrayUpdate(_outArray, _i, arrayGet(_inArray, mmc_unbox_integer(_e)));
_i = ((modelica_integer) 1) + _i;
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_findFirstOnTrueWithIdx(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inPredicate, modelica_integer *out_idxOut)
{
modelica_metatype _outElement = NULL;
modelica_integer _idxOut;
modelica_integer _idx;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_integer tmp4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_idxOut = ((modelica_integer) -1);
_idx = ((modelica_integer) 1);
_outElement = mmc_mk_none();
{
modelica_metatype _e;
for (tmpMeta1 = _inArray, tmp4 = arrayLength(tmpMeta1), tmp3 = 1; tmp3 <= tmp4; tmp3++)
{
_e = arrayGet(tmpMeta1,tmp3);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPredicate), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPredicate), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPredicate), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPredicate), 1)))) (threadData, _e)))
{
_idxOut = _idx;
_outElement = mmc_mk_some(_e);
break;
}
_idx = ((modelica_integer) 1) + _idx;
}
}
_return: OMC_LABEL_UNUSED
if (out_idxOut) { *out_idxOut = _idxOut; }
return _outElement;
}
modelica_metatype boxptr_Array_findFirstOnTrueWithIdx(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inPredicate, modelica_metatype *out_idxOut)
{
modelica_integer _idxOut;
modelica_metatype _outElement = NULL;
_outElement = omc_Array_findFirstOnTrueWithIdx(threadData, _inArray, _inPredicate, &_idxOut);
if (out_idxOut) { *out_idxOut = mmc_mk_icon(_idxOut); }
return _outElement;
}
DLLDirection
modelica_metatype omc_Array_findFirstOnTrue(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inPredicate)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_integer tmp4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outElement = mmc_mk_none();
{
modelica_metatype _e;
for (tmpMeta1 = _inArray, tmp4 = arrayLength(tmpMeta1), tmp3 = 1; tmp3 <= tmp4; tmp3++)
{
_e = arrayGet(tmpMeta1,tmp3);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPredicate), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPredicate), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPredicate), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPredicate), 1)))) (threadData, _e)))
{
_outElement = mmc_mk_some(_e);
break;
}
}
}
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLDirection
modelica_metatype omc_Array_heapSort(threadData_t *threadData, modelica_metatype __omcQ_24in_5FinArray)
{
modelica_metatype _inArray = NULL;
modelica_integer _n;
modelica_integer _tmp;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_inArray = __omcQ_24in_5FinArray;
_n = arrayLength(_inArray);
tmp4 = ((modelica_integer) 2);
if (tmp4 == 0) {MMC_THROW_INTERNAL();}
tmp1 = ((modelica_integer) -1) + modelica_div_integer(_n,tmp4).quot; tmp2 = ((modelica_integer) -1); tmp3 = ((modelica_integer) 0);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _v;
for(_v = ((modelica_integer) -1) + modelica_div_integer(_n,tmp4).quot; in_range_integer(_v, tmp1, tmp3); _v += tmp2)
{
_inArray = omc_Array_downheap(threadData, _inArray, _n, _v);
}
}
tmp5 = _n; tmp6 = ((modelica_integer) -1); tmp7 = ((modelica_integer) 2);
if(!(((tmp6 > 0) && (tmp5 > tmp7)) || ((tmp6 < 0) && (tmp5 < tmp7))))
{
modelica_integer _v;
for(_v = _n; in_range_integer(_v, tmp5, tmp7); _v += tmp6)
{
_tmp = mmc_unbox_integer(arrayGet(_inArray,((modelica_integer) 1)) /* DAE.ASUB */);
arrayUpdate(_inArray,((modelica_integer) 1),arrayGet(_inArray,_v) /* DAE.ASUB */);
arrayUpdate(_inArray,_v,mmc_mk_integer(_tmp));
_inArray = omc_Array_downheap(threadData, _inArray, ((modelica_integer) -1) + _v, ((modelica_integer) 0));
}
}
_return: OMC_LABEL_UNUSED
return _inArray;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Array_downheap(threadData_t *threadData, modelica_metatype __omcQ_24in_5FinArray, modelica_integer _n, modelica_integer _vIn)
{
modelica_metatype _inArray = NULL;
modelica_integer _v;
modelica_integer _w;
modelica_integer _tmp;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_inArray = __omcQ_24in_5FinArray;
_v = _vIn;
_w = ((modelica_integer) 1) + ((((modelica_integer) 2)) * (_v));
while(1)
{
if(!(_w < _n)) break;
if((((modelica_integer) 1) + _w < _n))
{
if((mmc_unbox_integer(arrayGet(_inArray,((modelica_integer) 2) + _w) /* DAE.ASUB */) > mmc_unbox_integer(arrayGet(_inArray,((modelica_integer) 1) + _w) /* DAE.ASUB */)))
{
_w = ((modelica_integer) 1) + _w;
}
}
if((mmc_unbox_integer(arrayGet(_inArray,((modelica_integer) 1) + _v) /* DAE.ASUB */) >= mmc_unbox_integer(arrayGet(_inArray,((modelica_integer) 1) + _w) /* DAE.ASUB */)))
{
goto _return;
}
_tmp = mmc_unbox_integer(arrayGet(_inArray,((modelica_integer) 1) + _v) /* DAE.ASUB */);
arrayUpdate(_inArray,((modelica_integer) 1) + _v,arrayGet(_inArray,((modelica_integer) 1) + _w) /* DAE.ASUB */);
arrayUpdate(_inArray,((modelica_integer) 1) + _w,mmc_mk_integer(_tmp));
_v = _w;
_w = ((modelica_integer) 1) + ((((modelica_integer) 2)) * (_v));
}
_return: OMC_LABEL_UNUSED
return _inArray;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Array_downheap(threadData_t *threadData, modelica_metatype __omcQ_24in_5FinArray, modelica_metatype _n, modelica_metatype _vIn)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _inArray = NULL;
tmp1 = mmc_unbox_integer(_n);
tmp2 = mmc_unbox_integer(_vIn);
_inArray = omc_Array_downheap(threadData, __omcQ_24in_5FinArray, tmp1, tmp2);
return _inArray;
}
DLLDirection
modelica_metatype omc_Array_mapNoCopy__1(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outArray = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype _e = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = _inArray;
_outArg = _inArg;
tmp6 = ((modelica_integer) 1); tmp7 = 1; tmp8 = arrayLength(_inArray);
if(!(((tmp7 > 0) && (tmp6 > tmp8)) || ((tmp7 < 0) && (tmp6 < tmp8))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp6, tmp8); _i += tmp7)
{
tmpMeta1 = mmc_mk_box2(0, arrayGetNoBoundsChecking(_inArray, _i), _outArg);
tmpMeta2 = mmc_mk_box2(0, arrayGetNoBoundsChecking(_inArray, _i), _outArg);
tmpMeta3 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), tmpMeta2) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, tmpMeta1);
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 1));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
_e = tmpMeta4;
_outArg = tmpMeta5;
arrayUpdateNoBoundsChecking(_inArray, _i, _e);
}
}
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outArray;
}
DLLDirection
modelica_metatype omc_Array_mapNoCopy(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc)
{
modelica_metatype _outArray = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = _inArray;
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_inArray);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_inArray, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, _i)));
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
