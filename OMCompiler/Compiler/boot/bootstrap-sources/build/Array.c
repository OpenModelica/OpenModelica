#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Array.c"
#endif
#include "omc_simulation_settings.h"
#include "Array.h"
#include "util/modelica.h"
#include "Array_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Array_downheap(threadData_t *threadData, modelica_metatype __omcQ_24in_5FinArray, modelica_integer _n, modelica_integer _vIn);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Array_downheap(threadData_t *threadData, modelica_metatype __omcQ_24in_5FinArray, modelica_metatype _n, modelica_metatype _vIn);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Array_downheap,2,0) {(void*) boxptr_Array_downheap,0}};
#define boxvar_Array_downheap MMC_REFSTRUCTLIT(boxvar_lit_Array_downheap)
DLLExport
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
DLLExport
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
DLLExport
modelica_boolean omc_Array_all(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _e;
for (tmpMeta[0] = _arr, tmp2 = arrayLength(tmpMeta[0]), tmp1 = 1; tmp1 <= tmp2; tmp1++)
{
_e = arrayGet(tmpMeta[0],tmp1);
if((!mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _e))))
{
_res = 0;
goto _return;
}
}
}
_res = 1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_Array_all(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_Array_all(threadData, _arr, _fn);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_metatype omc_Array_remove(threadData_t *threadData, modelica_metatype _arr, modelica_integer _index)
{
modelica_metatype _outArr = NULL;
modelica_integer _len;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_len = arrayLength(_arr);
if((_len <= ((modelica_integer) 1)))
{
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outArr = listArray(tmpMeta[0]);
}
else
{
_outArr = arrayCreateNoInit(((modelica_integer) -1) + _len, arrayGet(_arr,((modelica_integer) 1)) /* DAE.ASUB */);
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = ((modelica_integer) -1) + _index;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_outArr, _i, arrayGetNoBoundsChecking(_arr, _i));
}
}
tmp4 = ((modelica_integer) 1) + _index; tmp5 = 1; tmp6 = ((modelica_integer) -1) + _len;
if(!(((tmp5 > 0) && (tmp4 > tmp6)) || ((tmp5 < 0) && (tmp4 < tmp6))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1) + _index; in_range_integer(_i, tmp4, tmp6); _i += tmp5)
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
DLLExport
modelica_metatype omc_Array_insertList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farr, modelica_metatype _lst, modelica_integer _startPos)
{
modelica_metatype _arr = NULL;
modelica_integer _i;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_arr = __omcQ_24in_5Farr;
_i = _startPos;
{
modelica_metatype _e;
for (tmpMeta[0] = _lst; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_e = MMC_CAR(tmpMeta[0]);
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
DLLExport
modelica_boolean omc_Array_exist(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _pred)
{
modelica_boolean _exists;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _e;
for (tmpMeta[0] = _arr, tmp2 = arrayLength(tmpMeta[0]), tmp1 = 1; tmp1 <= tmp2; tmp1++)
{
_e = arrayGet(tmpMeta[0],tmp1);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pred), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pred), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pred), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_pred), 1)))) (threadData, _e)))
{
_exists = 1;
goto _return;
}
}
}
_exists = 0;
_return: OMC_LABEL_UNUSED
return _exists;
}
modelica_metatype boxptr_Array_exist(threadData_t *threadData, modelica_metatype _arr, modelica_fnptr _pred)
{
modelica_boolean _exists;
modelica_metatype out_exists;
_exists = omc_Array_exist(threadData, _arr, _pred);
out_exists = mmc_mk_icon(_exists);
return out_exists;
}
DLLExport
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
DLLExport
modelica_boolean omc_Array_isEqualOnTrue(threadData_t *threadData, modelica_metatype _arr1, modelica_metatype _arr2, modelica_fnptr _pred)
{
modelica_boolean _equal;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
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
DLLExport
modelica_boolean omc_Array_isEqual(threadData_t *threadData, modelica_metatype _inArr1, modelica_metatype _inArr2)
{
modelica_boolean _outIsEqual;
modelica_integer _arrLength;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
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
DLLExport
modelica_boolean omc_Array_arrayListsEmpty1(threadData_t *threadData, modelica_metatype _lst, modelica_boolean _isEmptyIn)
{
modelica_boolean _isEmptyOut;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_isEmptyOut = (listEmpty(_lst) && _isEmptyIn);
_return: OMC_LABEL_UNUSED
return _isEmptyOut;
}
modelica_metatype boxptr_Array_arrayListsEmpty1(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _isEmptyIn)
{
modelica_integer tmp1;
modelica_boolean _isEmptyOut;
modelica_metatype out_isEmptyOut;
tmp1 = mmc_unbox_integer(_isEmptyIn);
_isEmptyOut = omc_Array_arrayListsEmpty1(threadData, _lst, tmp1);
out_isEmptyOut = mmc_mk_icon(_isEmptyOut);
return out_isEmptyOut;
}
DLLExport
modelica_boolean omc_Array_arrayListsEmpty(threadData_t *threadData, modelica_metatype _arr)
{
modelica_boolean _isEmpty;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_isEmpty = mmc_unbox_boolean(omc_Array_fold(threadData, _arr, boxvar_Array_arrayListsEmpty1, mmc_mk_boolean(1)));
_return: OMC_LABEL_UNUSED
return _isEmpty;
}
modelica_metatype boxptr_Array_arrayListsEmpty(threadData_t *threadData, modelica_metatype _arr)
{
modelica_boolean _isEmpty;
modelica_metatype out_isEmpty;
_isEmpty = omc_Array_arrayListsEmpty(threadData, _arr);
out_isEmpty = mmc_mk_icon(_isEmpty);
return out_isEmpty;
}
DLLExport
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
_elem2 = arrayGet(_inArray, ((modelica_integer) 1) + _size - _i);
_outArray = arrayUpdate(_outArray, _i, _elem2);
_outArray = arrayUpdate(_outArray, ((modelica_integer) 1) + _size - _i, _elem1);
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLExport
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
DLLExport
modelica_integer omc_Array_position(threadData_t *threadData, modelica_metatype _inArray, modelica_metatype _inElement, modelica_integer _inFilledSize)
{
modelica_integer _outIndex;
modelica_metatype _e = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
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
DLLExport
modelica_metatype omc_Array_getRange(threadData_t *threadData, modelica_integer _inStart, modelica_integer _inEnd, modelica_metatype _inArray)
{
modelica_metatype _outList = NULL;
modelica_metatype _value = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outList = tmpMeta[0];
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
_value = arrayGet(_inArray, _i);
tmpMeta[1] = mmc_mk_cons(_value, _outList);
_outList = tmpMeta[1];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
tmp1 = mmc_unbox_integer(_inStart);
tmp2 = mmc_unbox_integer(_inEnd);
_outList = omc_Array_getRange(threadData, tmp1, tmp2, _inArray);
return _outList;
}
DLLExport
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
DLLExport
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
DLLExport
void omc_Array_copyRange(threadData_t *threadData, modelica_metatype _srcArray, modelica_metatype _dstArray, modelica_integer _srcFirst, modelica_integer _srcLast, modelica_integer _dstPos)
{
modelica_integer _offset;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
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
DLLExport
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
DLLExport
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
DLLExport
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
DLLExport
modelica_metatype omc_Array_appendList(threadData_t *threadData, modelica_metatype _arr, modelica_metatype _lst)
{
modelica_metatype _outArray = NULL;
modelica_integer _arr_len;
modelica_integer _lst_len;
modelica_metatype _e = NULL;
modelica_metatype _rest = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
tmp1 = ((modelica_integer) 1) + _arr_len; tmp2 = 1; tmp3 = _arr_len + _lst_len;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1) + _arr_len; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
tmpMeta[0] = _rest;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
_e = tmpMeta[1];
_rest = tmpMeta[2];
arrayUpdateNoBoundsChecking(_outArray, _i, _e);
}
}
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLExport
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
DLLExport
modelica_metatype omc_Array_consToElement(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inElement, modelica_metatype _inArray)
{
modelica_metatype _outArray = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_cons(_inElement, arrayGet(_inArray,_inIndex) /* DAE.ASUB */);
_outArray = arrayUpdate(_inArray, _inIndex, tmpMeta[0]);
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
DLLExport
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
DLLExport
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
DLLExport
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
DLLExport
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
DLLExport
void omc_Array_updateElementListAppend(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inValue, modelica_metatype _inArray)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
arrayUpdate(_inArray, _inIndex, listAppend(arrayGet(_inArray,_inIndex) /* DAE.ASUB */, _inValue));
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Array_updateElementListAppend(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inValue, modelica_metatype _inArray)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inIndex);
omc_Array_updateElementListAppend(threadData, tmp1, _inValue, _inArray);
return;
}
DLLExport
void omc_Array_updatewithListIndexFirst(threadData_t *threadData, modelica_metatype _inList, modelica_integer _inStartIndex, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = _inStartIndex; tmp2 = 1; tmp3 = _inStartIndex + listLength(_inList);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = _inStartIndex; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdate(_inArrayDest, _i, arrayGet(_inArraySrc,_i) /* DAE.ASUB */);
}
}
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Array_updatewithListIndexFirst(threadData_t *threadData, modelica_metatype _inList, modelica_metatype _inStartIndex, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inStartIndex);
omc_Array_updatewithListIndexFirst(threadData, _inList, tmp1, _inArraySrc, _inArrayDest);
return;
}
DLLExport
void omc_Array_updatewithArrayIndexFirst(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
arrayUpdate(_inArrayDest, _inIndex, arrayGet(_inArraySrc,_inIndex) /* DAE.ASUB */);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Array_updatewithArrayIndexFirst(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inArraySrc, modelica_metatype _inArrayDest)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inIndex);
omc_Array_updatewithArrayIndexFirst(threadData, tmp1, _inArraySrc, _inArrayDest);
return;
}
DLLExport
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
DLLExport
void omc_Array_updateIndexFirst(threadData_t *threadData, modelica_integer _inIndex, modelica_metatype _inValue, modelica_metatype _inArray)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
arrayUpdate(_inArray, _inIndex, _inValue);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Array_updateIndexFirst(threadData_t *threadData, modelica_metatype _inIndex, modelica_metatype _inValue, modelica_metatype _inArray)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inIndex);
omc_Array_updateIndexFirst(threadData, tmp1, _inValue, _inArray);
return;
}
DLLExport
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
DLLExport
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
DLLExport
modelica_metatype omc_Array_fold6(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inArg5, modelica_metatype _inArg6, modelica_metatype _inStartValue)
{
modelica_metatype _outResult = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outResult = _inStartValue;
{
modelica_metatype _e;
for (tmpMeta[0] = _inArray, tmp2 = arrayLength(tmpMeta[0]), tmp1 = 1; tmp1 <= tmp2; tmp1++)
{
_e = arrayGet(tmpMeta[0],tmp1);
_outResult = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))), _e, _inArg1, _inArg2, _inArg3, _inArg4, _inArg5, _inArg6, _outResult) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, _e, _inArg1, _inArg2, _inArg3, _inArg4, _inArg5, _inArg6, _outResult);
}
}
_return: OMC_LABEL_UNUSED
return _outResult;
}
DLLExport
modelica_metatype omc_Array_fold5(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inArg5, modelica_metatype _inStartValue)
{
modelica_metatype _outResult = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outResult = _inStartValue;
{
modelica_metatype _e;
for (tmpMeta[0] = _inArray, tmp2 = arrayLength(tmpMeta[0]), tmp1 = 1; tmp1 <= tmp2; tmp1++)
{
_e = arrayGet(tmpMeta[0],tmp1);
_outResult = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))), _e, _inArg1, _inArg2, _inArg3, _inArg4, _inArg5, _outResult) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, _e, _inArg1, _inArg2, _inArg3, _inArg4, _inArg5, _outResult);
}
}
_return: OMC_LABEL_UNUSED
return _outResult;
}
DLLExport
modelica_metatype omc_Array_fold4(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inArg4, modelica_metatype _inStartValue)
{
modelica_metatype _outResult = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outResult = _inStartValue;
{
modelica_metatype _e;
for (tmpMeta[0] = _inArray, tmp2 = arrayLength(tmpMeta[0]), tmp1 = 1; tmp1 <= tmp2; tmp1++)
{
_e = arrayGet(tmpMeta[0],tmp1);
_outResult = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))), _e, _inArg1, _inArg2, _inArg3, _inArg4, _outResult) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, _e, _inArg1, _inArg2, _inArg3, _inArg4, _outResult);
}
}
_return: OMC_LABEL_UNUSED
return _outResult;
}
DLLExport
modelica_metatype omc_Array_fold3(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inArg3, modelica_metatype _inStartValue)
{
modelica_metatype _outResult = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outResult = _inStartValue;
{
modelica_metatype _e;
for (tmpMeta[0] = _inArray, tmp2 = arrayLength(tmpMeta[0]), tmp1 = 1; tmp1 <= tmp2; tmp1++)
{
_e = arrayGet(tmpMeta[0],tmp1);
_outResult = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))), _e, _inArg1, _inArg2, _inArg3, _outResult) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, _e, _inArg1, _inArg2, _inArg3, _outResult);
}
}
_return: OMC_LABEL_UNUSED
return _outResult;
}
DLLExport
modelica_metatype omc_Array_fold2(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inArg1, modelica_metatype _inArg2, modelica_metatype _inStartValue)
{
modelica_metatype _outResult = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outResult = _inStartValue;
{
modelica_metatype _e;
for (tmpMeta[0] = _inArray, tmp2 = arrayLength(tmpMeta[0]), tmp1 = 1; tmp1 <= tmp2; tmp1++)
{
_e = arrayGet(tmpMeta[0],tmp1);
_outResult = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))), _e, _inArg1, _inArg2, _outResult) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, _e, _inArg1, _inArg2, _outResult);
}
}
_return: OMC_LABEL_UNUSED
return _outResult;
}
DLLExport
modelica_metatype omc_Array_fold1(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inArg, modelica_metatype _inStartValue)
{
modelica_metatype _outResult = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outResult = _inStartValue;
{
modelica_metatype _e;
for (tmpMeta[0] = _inArray, tmp2 = arrayLength(tmpMeta[0]), tmp1 = 1; tmp1 <= tmp2; tmp1++)
{
_e = arrayGet(tmpMeta[0],tmp1);
_outResult = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))), _e, _inArg, _outResult) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, _e, _inArg, _outResult);
}
}
_return: OMC_LABEL_UNUSED
return _outResult;
}
DLLExport
modelica_metatype omc_Array_fold(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFoldFunc, modelica_metatype _inStartValue)
{
modelica_metatype _outResult = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outResult = _inStartValue;
{
modelica_metatype _e;
for (tmpMeta[0] = _inArray, tmp2 = arrayLength(tmpMeta[0]), tmp1 = 1; tmp1 <= tmp2; tmp1++)
{
_e = arrayGet(tmpMeta[0],tmp1);
_outResult = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 2))), _e, _outResult) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFoldFunc), 1)))) (threadData, _e, _outResult);
}
}
_return: OMC_LABEL_UNUSED
return _outResult;
}
DLLExport
modelica_metatype omc_Array_mapList(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc)
{
modelica_metatype _outArray = NULL;
modelica_integer _i;
modelica_integer _len;
modelica_metatype _res = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_i = ((modelica_integer) 2);
_len = listLength(_inList);
if((_len == ((modelica_integer) 0)))
{
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outArray = listArray(tmpMeta[0]);
}
else
{
_res = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), listHead(_inList)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, listHead(_inList));
_outArray = arrayCreateNoInit(_len, _res);
arrayUpdate(_outArray, ((modelica_integer) 1), _res);
{
modelica_metatype _e;
for (tmpMeta[0] = listRest(_inList); !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_e = MMC_CAR(tmpMeta[0]);
arrayUpdate(_outArray, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _e));
_i = ((modelica_integer) 1) + _i;
}
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLExport
void omc_Array_map0(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _e;
for (tmpMeta[0] = _inArray, tmp2 = arrayLength(tmpMeta[0]), tmp1 = 1; tmp1 <= tmp2; tmp1++)
{
_e = arrayGet(tmpMeta[0],tmp1);
(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((void(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _e) : ((void(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _e);
}
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_Array_map1Ind(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc, modelica_metatype _inArg)
{
modelica_metatype _outArray = NULL;
modelica_integer _len;
modelica_metatype _res = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_len = arrayLength(_inArray);
if((_len == ((modelica_integer) 0)))
{
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outArray = listArray(tmpMeta[0]);
}
else
{
_res = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, ((modelica_integer) 1)), mmc_mk_integer(((modelica_integer) 1)), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, ((modelica_integer) 1)), mmc_mk_integer(((modelica_integer) 1)), _inArg);
_outArray = arrayCreateNoInit(_len, _res);
arrayUpdate(_outArray, ((modelica_integer) 1), _res);
tmp1 = ((modelica_integer) 2); tmp2 = 1; tmp3 = _len;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdate(_outArray, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, _i), mmc_mk_integer(_i), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, _i), mmc_mk_integer(_i), _inArg));
}
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLExport
modelica_metatype omc_Array_map1(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc, modelica_metatype _inArg)
{
modelica_metatype _outArray = NULL;
modelica_integer _len;
modelica_metatype _res = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_len = arrayLength(_inArray);
if((_len == ((modelica_integer) 0)))
{
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outArray = listArray(tmpMeta[0]);
}
else
{
_res = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, ((modelica_integer) 1)), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, ((modelica_integer) 1)), _inArg);
_outArray = arrayCreateNoInit(_len, _res);
arrayUpdate(_outArray, ((modelica_integer) 1), _res);
tmp1 = ((modelica_integer) 2); tmp2 = 1; tmp3 = _len;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdate(_outArray, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, _i), _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, _i), _inArg));
}
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLExport
modelica_metatype omc_Array_map(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc)
{
modelica_metatype _outArray = NULL;
modelica_integer _len;
modelica_metatype _res = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_len = arrayLength(_inArray);
if((_len == ((modelica_integer) 0)))
{
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outArray = listArray(tmpMeta[0]);
}
else
{
_res = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, ((modelica_integer) 1))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, ((modelica_integer) 1)));
_outArray = arrayCreateNoInit(_len, _res);
arrayUpdateNoBoundsChecking(_outArray, ((modelica_integer) 1), _res);
tmp1 = ((modelica_integer) 2); tmp2 = 1; tmp3 = _len;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_outArray, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, _i)));
}
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLExport
modelica_metatype omc_Array_select(threadData_t *threadData, modelica_metatype _inArray, modelica_metatype _inIndices)
{
modelica_metatype _outArray = NULL;
modelica_integer _i;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_i = ((modelica_integer) 1);
_outArray = arrayCreateNoInit(listLength(_inIndices), arrayGet(_inArray,((modelica_integer) 1)) /* DAE.ASUB */);
{
modelica_metatype _e;
for (tmpMeta[0] = _inIndices; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_e = MMC_CAR(tmpMeta[0]);
arrayUpdate(_outArray, _i, arrayGet(_inArray, mmc_unbox_integer(_e)));
_i = ((modelica_integer) 1) + _i;
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLExport
modelica_metatype omc_Array_findFirstOnTrueWithIdx(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inPredicate, modelica_integer *out_idxOut)
{
modelica_metatype _outElement = NULL;
modelica_integer _idxOut;
modelica_integer _idx;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_idxOut = ((modelica_integer) -1);
_idx = ((modelica_integer) 1);
_outElement = mmc_mk_none();
{
modelica_metatype _e;
for (tmpMeta[0] = _inArray, tmp2 = arrayLength(tmpMeta[0]), tmp1 = 1; tmp1 <= tmp2; tmp1++)
{
_e = arrayGet(tmpMeta[0],tmp1);
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
DLLExport
modelica_metatype omc_Array_findFirstOnTrue(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inPredicate)
{
modelica_metatype _outElement = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outElement = mmc_mk_none();
{
modelica_metatype _e;
for (tmpMeta[0] = _inArray, tmp2 = arrayLength(tmpMeta[0]), tmp1 = 1; tmp1 <= tmp2; tmp1++)
{
_e = arrayGet(tmpMeta[0],tmp1);
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
DLLExport
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
tmp1 = ((modelica_integer) -1) + ldiv(_n,tmp4).quot; tmp2 = ((modelica_integer) -1); tmp3 = ((modelica_integer) 0);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _v;
for(_v = ((modelica_integer) -1) + ldiv(_n,tmp4).quot; in_range_integer(_v, tmp1, tmp3); _v += tmp2)
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
_w = ((modelica_integer) 1) + (((modelica_integer) 2)) * (_v);
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
_w = ((modelica_integer) 1) + (((modelica_integer) 2)) * (_v);
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
DLLExport
modelica_metatype omc_Array_mapNoCopy__1(threadData_t *threadData, modelica_metatype _inArray, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outArray = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype _e = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArray = _inArray;
_outArg = _inArg;
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_inArray);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
tmpMeta[0] = mmc_mk_box2(0, arrayGetNoBoundsChecking(_inArray, _i), _outArg);
tmpMeta[1] = mmc_mk_box2(0, arrayGetNoBoundsChecking(_inArray, _i), _outArg);
tmpMeta[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), tmpMeta[1]) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, tmpMeta[0]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_e = tmpMeta[3];
_outArg = tmpMeta[4];
arrayUpdate(_inArray, _i, _e);
}
}
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outArray;
}
DLLExport
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
arrayUpdate(_inArray, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), arrayGetNoBoundsChecking(_inArray, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, arrayGetNoBoundsChecking(_inArray, _i)));
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
