#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "Vector.c"
#endif
#include "omc_simulation_settings.h"
#include "Vector.h"
#define _OMC_LIT0_data "["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,1,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,2,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,1,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#include "util/modelica.h"
#include "Vector_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Vector_reserveCapacity(threadData_t *threadData, modelica_metatype _v, modelica_integer _newSize);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Vector_reserveCapacity(threadData_t *threadData, modelica_metatype _v, modelica_metatype _newSize);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Vector_reserveCapacity,2,0) {(void*) boxptr_Vector_reserveCapacity,0}};
#define boxvar_Vector_reserveCapacity MMC_REFSTRUCTLIT(boxvar_lit_Vector_reserveCapacity)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Vector_resizeArray(threadData_t *threadData, modelica_metatype _arr, modelica_integer _newSize);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Vector_resizeArray(threadData_t *threadData, modelica_metatype _arr, modelica_metatype _newSize);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Vector_resizeArray,2,0) {(void*) boxptr_Vector_resizeArray,0}};
#define boxvar_Vector_resizeArray MMC_REFSTRUCTLIT(boxvar_lit_Vector_resizeArray)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Vector_reserveCapacity(threadData_t *threadData, modelica_metatype _v, modelica_integer _newSize)
{
modelica_metatype _data = NULL;
modelica_integer _cap;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_cap = arrayLength(_data);
if((_newSize > _cap))
{
_cap = modelica_integer_max((modelica_integer)(_cap),(modelica_integer)(((modelica_integer) 1)));
while(1)
{
if(!(_newSize > _cap)) break;
_cap = (((modelica_integer) 2)) * (_cap);
}
_data = omc_Vector_resizeArray(threadData, omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2)))), _cap);
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))), _data);
}
_return: OMC_LABEL_UNUSED
return _data;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Vector_reserveCapacity(threadData_t *threadData, modelica_metatype _v, modelica_metatype _newSize)
{
modelica_integer tmp1;
modelica_metatype _data = NULL;
tmp1 = mmc_unbox_integer(_newSize);
_data = omc_Vector_reserveCapacity(threadData, _v, tmp1);
return _data;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Vector_resizeArray(threadData_t *threadData, modelica_metatype _arr, modelica_integer _newSize)
{
modelica_metatype _outArr = NULL;
modelica_metatype _dummy = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_dummy = _dummy;
_outArr = arrayCreateNoInit(_newSize, _dummy);
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = modelica_integer_min((modelica_integer)(_newSize),(modelica_integer)(arrayLength(_arr)));
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_outArr, _i, arrayGetNoBoundsChecking(_arr, _i));
}
}
_return: OMC_LABEL_UNUSED
return _outArr;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Vector_resizeArray(threadData_t *threadData, modelica_metatype _arr, modelica_metatype _newSize)
{
modelica_integer tmp1;
modelica_metatype _outArr = NULL;
tmp1 = mmc_unbox_integer(_newSize);
_outArr = omc_Vector_resizeArray(threadData, _arr, tmp1);
return _outArr;
}
DLLExport
modelica_string omc_Vector_toString(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _stringFn, modelica_string _strBegin, modelica_string _delim, modelica_string _strEnd)
{
modelica_string _str = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_string __omcQ_24tmpVar0;
modelica_integer tmp4;
modelica_metatype _e_loopVar = 0;
modelica_integer tmp5;
modelica_metatype _e;
_e_loopVar = omc_Vector_toArray(threadData, _v);
tmp5 = 1;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar1;
while(1) {
tmp4 = 1;
if (tmp5 <= arrayLength(_e_loopVar)) {
_e = arrayGet(_e_loopVar, tmp5++);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar0 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stringFn), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stringFn), 1)))) (threadData, _e);
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
tmpMeta6 = stringAppend(_strBegin,stringDelimitList(tmpMeta1, _delim));
tmpMeta7 = stringAppend(tmpMeta6,_strEnd);
_str = tmpMeta7;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
void omc_Vector_swap(threadData_t *threadData, modelica_metatype _v1, modelica_metatype _v2)
{
modelica_metatype _data1 = NULL;
modelica_metatype _data2 = NULL;
modelica_integer _sz1;
modelica_integer _sz2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 2))));
_data2 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 2))));
_sz1 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 3)))));
_sz2 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 3)))));
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 2))), _data2);
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 2))), _data1);
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 3))), mmc_mk_integer(_sz2));
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 3))), mmc_mk_integer(_sz1));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_Vector_deepCopy(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn)
{
modelica_metatype _c = NULL;
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
_data = arrayCopy(_data);
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_data);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_data, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i)));
}
}
tmpMeta4 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, _data), omc_Mutable_create(threadData, mmc_mk_integer(_sz)));
_c = tmpMeta4;
_return: OMC_LABEL_UNUSED
return _c;
}
DLLExport
modelica_metatype omc_Vector_copy(threadData_t *threadData, modelica_metatype _v)
{
modelica_metatype _c = NULL;
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
tmpMeta1 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, arrayCopy(_data)), omc_Mutable_create(threadData, mmc_mk_integer(_sz)));
_c = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _c;
}
DLLExport
modelica_boolean omc_Vector_none(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype _data = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i))))
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
modelica_metatype boxptr_Vector_none(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_Vector_none(threadData, _v, _fn);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_Vector_any(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype _data = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i))))
{
_res = 1;
goto _return;
}
}
}
_res = 0;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_Vector_any(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_Vector_any(threadData, _v, _fn);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_Vector_all(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype _data = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
if((!mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i)))))
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
modelica_metatype boxptr_Vector_all(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_Vector_all(threadData, _v, _fn);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_metatype omc_Vector_findFold(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn, modelica_metatype __omcQ_24in_5Farg, modelica_integer *out_index, modelica_metatype *out_arg)
{
modelica_metatype _oe = NULL;
modelica_integer _index;
modelica_metatype _arg = NULL;
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_metatype _e = NULL;
modelica_boolean _res;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_oe = mmc_mk_none();
_index = ((modelica_integer) -1);
_arg = __omcQ_24in_5Farg;
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
tmp4 = ((modelica_integer) 1); tmp5 = 1; tmp6 = _sz;
if(!(((tmp5 > 0) && (tmp4 > tmp6)) || ((tmp5 < 0) && (tmp4 < tmp6))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp4, tmp6); _i += tmp5)
{
_e = arrayGetNoBoundsChecking(_data, _i);
tmpMeta2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _e, _arg, &tmpMeta1) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _e, _arg, &tmpMeta1);
tmp3 = mmc_unbox_integer(tmpMeta2);
_res = tmp3;
_arg = tmpMeta1;
if(_res)
{
_oe = mmc_mk_some(_e);
_index = _i;
}
}
}
_return: OMC_LABEL_UNUSED
if (out_index) { *out_index = _index; }
if (out_arg) { *out_arg = _arg; }
return _oe;
}
modelica_metatype boxptr_Vector_findFold(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_index, modelica_metatype *out_arg)
{
modelica_integer _index;
modelica_metatype _oe = NULL;
_oe = omc_Vector_findFold(threadData, _v, _fn, __omcQ_24in_5Farg, &_index, out_arg);
if (out_index) { *out_index = mmc_mk_icon(_index); }
return _oe;
}
DLLExport
modelica_metatype omc_Vector_find(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn, modelica_integer *out_index)
{
modelica_metatype _oe = NULL;
modelica_integer _index;
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_metatype _e = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _sz;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_e = arrayGetNoBoundsChecking(_data, _i);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _e)))
{
_oe = mmc_mk_some(_e);
_index = _i;
goto _return;
}
}
}
_oe = mmc_mk_none();
_index = ((modelica_integer) -1);
_return: OMC_LABEL_UNUSED
if (out_index) { *out_index = _index; }
return _oe;
}
modelica_metatype boxptr_Vector_find(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn, modelica_metatype *out_index)
{
modelica_integer _index;
modelica_metatype _oe = NULL;
_oe = omc_Vector_find(threadData, _v, _fn, &_index);
if (out_index) { *out_index = mmc_mk_icon(_index); }
return _oe;
}
DLLExport
modelica_metatype omc_Vector_fold(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn, modelica_metatype __omcQ_24in_5Farg)
{
modelica_metatype _arg = NULL;
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_arg = __omcQ_24in_5Farg;
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _sz;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_arg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i), _arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i), _arg);
}
}
_return: OMC_LABEL_UNUSED
return _arg;
}
DLLExport
void omc_Vector_apply(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn)
{
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _sz;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_data, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i)));
}
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_Vector_mapToList(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn)
{
modelica_metatype _l = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_l = tmpMeta1;
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
tmp3 = _sz; tmp4 = ((modelica_integer) -1); tmp5 = ((modelica_integer) 1);
if(!(((tmp4 > 0) && (tmp3 > tmp5)) || ((tmp4 < 0) && (tmp3 < tmp5))))
{
modelica_integer _i;
for(_i = _sz; in_range_integer(_i, tmp3, tmp5); _i += tmp4)
{
tmpMeta2 = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i)), _l);
_l = tmpMeta2;
}
}
_return: OMC_LABEL_UNUSED
return _l;
}
DLLExport
modelica_metatype omc_Vector_map(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn, modelica_boolean _shrink)
{
modelica_metatype _outV = NULL;
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_metatype _new_data = NULL;
modelica_metatype _dummy = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
_dummy = _dummy;
_new_data = arrayCreateNoInit((_shrink?_sz:arrayLength(_data)), _dummy);
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _sz;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_new_data, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i)));
}
}
tmpMeta4 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, _new_data), omc_Mutable_create(threadData, mmc_mk_integer(_sz)));
_outV = tmpMeta4;
_return: OMC_LABEL_UNUSED
return _outV;
}
modelica_metatype boxptr_Vector_map(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn, modelica_metatype _shrink)
{
modelica_integer tmp1;
modelica_metatype _outV = NULL;
tmp1 = mmc_unbox_integer(_shrink);
_outV = omc_Vector_map(threadData, _v, _fn, tmp1);
return _outV;
}
DLLExport
void omc_Vector_fill(threadData_t *threadData, modelica_metatype _v, modelica_metatype _value, modelica_integer _from, modelica_integer _to)
{
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if(((((_from < ((modelica_integer) 1)) || (_to < ((modelica_integer) 1))) || (_from > _sz)) || (_to > _sz)))
{
MMC_THROW_INTERNAL();
}
tmp1 = _from; tmp2 = 1; tmp3 = _to;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = _from; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_data, _i, _value);
}
}
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Vector_fill(threadData_t *threadData, modelica_metatype _v, modelica_metatype _value, modelica_metatype _from, modelica_metatype _to)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_from);
tmp2 = mmc_unbox_integer(_to);
omc_Vector_fill(threadData, _v, _value, tmp1, tmp2);
return;
}
DLLExport
void omc_Vector_trim(threadData_t *threadData, modelica_metatype _v)
{
modelica_metatype _data = NULL;
modelica_integer _sz;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if((_sz < arrayLength(_data)))
{
_data = omc_Vector_resizeArray(threadData, _data, _sz);
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))), _data);
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Vector_reserve(threadData_t *threadData, modelica_metatype _v, modelica_integer _newCapacity)
{
modelica_metatype _data = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
if((_newCapacity > arrayLength(_data)))
{
_data = omc_Vector_resizeArray(threadData, _data, _newCapacity);
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))), _data);
}
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Vector_reserve(threadData_t *threadData, modelica_metatype _v, modelica_metatype _newCapacity)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_newCapacity);
omc_Vector_reserve(threadData, _v, tmp1);
return;
}
DLLExport
modelica_boolean omc_Vector_isEmpty(threadData_t *threadData, modelica_metatype _v)
{
modelica_boolean _empty;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_empty = (mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))))) == ((modelica_integer) 0));
_return: OMC_LABEL_UNUSED
return _empty;
}
modelica_metatype boxptr_Vector_isEmpty(threadData_t *threadData, modelica_metatype _v)
{
modelica_boolean _empty;
modelica_metatype out_empty;
_empty = omc_Vector_isEmpty(threadData, _v);
out_empty = mmc_mk_icon(_empty);
return out_empty;
}
DLLExport
modelica_integer omc_Vector_capacity(threadData_t *threadData, modelica_metatype _v)
{
modelica_integer _capacity;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_capacity = arrayLength(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2)))));
_return: OMC_LABEL_UNUSED
return _capacity;
}
modelica_metatype boxptr_Vector_capacity(threadData_t *threadData, modelica_metatype _v)
{
modelica_integer _capacity;
modelica_metatype out_capacity;
_capacity = omc_Vector_capacity(threadData, _v);
out_capacity = mmc_mk_icon(_capacity);
return out_capacity;
}
DLLExport
modelica_integer omc_Vector_size(threadData_t *threadData, modelica_metatype _v)
{
modelica_integer _sz;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
_return: OMC_LABEL_UNUSED
return _sz;
}
modelica_metatype boxptr_Vector_size(threadData_t *threadData, modelica_metatype _v)
{
modelica_integer _sz;
modelica_metatype out_sz;
_sz = omc_Vector_size(threadData, _v);
out_sz = mmc_mk_icon(_sz);
return out_sz;
}
DLLExport
modelica_metatype omc_Vector_last(threadData_t *threadData, modelica_metatype _v)
{
modelica_metatype _value = NULL;
modelica_metatype _data = NULL;
modelica_integer _sz;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if((_sz == ((modelica_integer) 0)))
{
MMC_THROW_INTERNAL();
}
_value = arrayGetNoBoundsChecking(_data, _sz);
_return: OMC_LABEL_UNUSED
return _value;
}
DLLExport
modelica_metatype omc_Vector_getNoBounds(threadData_t *threadData, modelica_metatype _v, modelica_integer _index)
{
modelica_metatype _value = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_value = arrayGetNoBoundsChecking(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2)))), _index);
_return: OMC_LABEL_UNUSED
return _value;
}
modelica_metatype boxptr_Vector_getNoBounds(threadData_t *threadData, modelica_metatype _v, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_metatype _value = NULL;
tmp1 = mmc_unbox_integer(_index);
_value = omc_Vector_getNoBounds(threadData, _v, tmp1);
return _value;
}
DLLExport
modelica_metatype omc_Vector_get(threadData_t *threadData, modelica_metatype _v, modelica_integer _index)
{
modelica_metatype _value = NULL;
modelica_metatype _data = NULL;
modelica_integer _sz;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if(((_index <= ((modelica_integer) 0)) || (_index > _sz)))
{
MMC_THROW_INTERNAL();
}
_value = arrayGetNoBoundsChecking(_data, _index);
_return: OMC_LABEL_UNUSED
return _value;
}
modelica_metatype boxptr_Vector_get(threadData_t *threadData, modelica_metatype _v, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_metatype _value = NULL;
tmp1 = mmc_unbox_integer(_index);
_value = omc_Vector_get(threadData, _v, tmp1);
return _value;
}
DLLExport
void omc_Vector_updateNoBounds(threadData_t *threadData, modelica_metatype _v, modelica_integer _index, modelica_metatype _value)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
arrayUpdateNoBoundsChecking(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2)))), _index, _value);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Vector_updateNoBounds(threadData_t *threadData, modelica_metatype _v, modelica_metatype _index, modelica_metatype _value)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_index);
omc_Vector_updateNoBounds(threadData, _v, tmp1, _value);
return;
}
DLLExport
void omc_Vector_update(threadData_t *threadData, modelica_metatype _v, modelica_integer _index, modelica_metatype _value)
{
modelica_metatype _data = NULL;
modelica_integer _sz;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if(((_index <= ((modelica_integer) 0)) || (_index > _sz)))
{
MMC_THROW_INTERNAL();
}
arrayUpdateNoBoundsChecking(_data, _index, _value);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Vector_update(threadData_t *threadData, modelica_metatype _v, modelica_metatype _index, modelica_metatype _value)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_index);
omc_Vector_update(threadData, _v, tmp1, _value);
return;
}
DLLExport
void omc_Vector_remove(threadData_t *threadData, modelica_metatype _v, modelica_integer _index)
{
modelica_integer _sz;
modelica_metatype _data = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if((_index == _sz))
{
omc_Vector_pop(threadData, _v);
}
else
{
if(((_index < ((modelica_integer) 0)) || (_index > _sz)))
{
MMC_THROW_INTERNAL();
}
else
{
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
tmp1 = _index; tmp2 = 1; tmp3 = _sz;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = _index; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_data, _i, arrayGetNoBoundsChecking(_data, ((modelica_integer) 1) + _i));
}
}
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(((modelica_integer) -1) + _sz));
}
}
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Vector_remove(threadData_t *threadData, modelica_metatype _v, modelica_metatype _index)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_index);
omc_Vector_remove(threadData, _v, tmp1);
return;
}
DLLExport
void omc_Vector_resize(threadData_t *threadData, modelica_metatype _v, modelica_integer _newSize, modelica_metatype _fillValue)
{
modelica_integer _sz;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if((_newSize < _sz))
{
omc_Vector_shrink(threadData, _v, _newSize);
}
else
{
if((_newSize > _sz))
{
omc_Vector_grow(threadData, _v, _newSize, _fillValue);
}
}
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Vector_resize(threadData_t *threadData, modelica_metatype _v, modelica_metatype _newSize, modelica_metatype _fillValue)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_newSize);
omc_Vector_resize(threadData, _v, tmp1, _fillValue);
return;
}
DLLExport
void omc_Vector_grow(threadData_t *threadData, modelica_metatype _v, modelica_integer _newSize, modelica_metatype _fillValue)
{
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if((_newSize > _sz))
{
_data = omc_Vector_reserveCapacity(threadData, _v, _newSize);
tmp1 = ((modelica_integer) 1) + _sz; tmp2 = 1; tmp3 = _newSize;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1) + _sz; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_data, _i, _fillValue);
}
}
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(_newSize));
}
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Vector_grow(threadData_t *threadData, modelica_metatype _v, modelica_metatype _newSize, modelica_metatype _fillValue)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_newSize);
omc_Vector_grow(threadData, _v, tmp1, _fillValue);
return;
}
DLLExport
void omc_Vector_shrink(threadData_t *threadData, modelica_metatype _v, modelica_integer _newSize)
{
modelica_metatype _null = NULL;
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_null = _null;
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if((_newSize < _sz))
{
tmp1 = _newSize; tmp2 = 1; tmp3 = _sz;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = _newSize; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_data, _i, _null);
}
}
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(_newSize));
}
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_Vector_shrink(threadData_t *threadData, modelica_metatype _v, modelica_metatype _newSize)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_newSize);
omc_Vector_shrink(threadData, _v, tmp1);
return;
}
DLLExport
void omc_Vector_clear(threadData_t *threadData, modelica_metatype _v)
{
modelica_metatype _null = NULL;
modelica_metatype _data = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_null = _null;
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_data, _i, _null);
}
}
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(((modelica_integer) 0)));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Vector_pop(threadData_t *threadData, modelica_metatype _v)
{
modelica_metatype _null = NULL;
modelica_metatype _data = NULL;
modelica_integer _sz;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_null = _null;
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
arrayUpdateNoBoundsChecking(_data, _sz, _null);
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(((modelica_integer) -1) + _sz));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Vector_appendArray(threadData_t *threadData, modelica_metatype _v, modelica_metatype _arr)
{
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_integer _new_sz;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
_new_sz = _sz + arrayLength(_arr);
_data = omc_Vector_reserveCapacity(threadData, _v, _new_sz);
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_arr);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_data, _sz + _i, arrayGetNoBoundsChecking(_arr, _i));
}
}
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(_new_sz));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Vector_appendList(threadData_t *threadData, modelica_metatype _v, modelica_metatype _l)
{
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_integer _new_sz;
modelica_metatype _rest_l = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
_new_sz = _sz + listLength(_l);
_rest_l = _l;
_data = omc_Vector_reserveCapacity(threadData, _v, _new_sz);
tmp1 = ((modelica_integer) 1) + _sz; tmp2 = 1; tmp3 = _new_sz;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1) + _sz; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_data, _i, listHead(_rest_l));
_rest_l = listRest(_rest_l);
}
}
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(_new_sz));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Vector_append(threadData_t *threadData, modelica_metatype _v1, modelica_metatype _v2)
{
modelica_metatype _data1 = NULL;
modelica_integer _sz1;
modelica_metatype _data2 = NULL;
modelica_integer _sz2;
modelica_integer _new_sz;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sz1 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 3)))));
_data2 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 2))));
_sz2 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 3)))));
_new_sz = _sz1 + _sz2;
_data1 = omc_Vector_reserveCapacity(threadData, _v1, _new_sz);
_sz1 = ((modelica_integer) 1) + _sz1;
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_data2);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_data1, _sz1 + _i, arrayGetNoBoundsChecking(_data2, _i));
}
}
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 3))), mmc_mk_integer(_new_sz));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Vector_push(threadData_t *threadData, modelica_metatype _v, modelica_metatype _value)
{
modelica_metatype _data = NULL;
modelica_integer _sz;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
_sz = ((modelica_integer) 1) + _sz;
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(_sz));
_data = omc_Vector_reserveCapacity(threadData, _v, _sz);
arrayUpdateNoBoundsChecking(_data, _sz, _value);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_Vector_toList(threadData_t *threadData, modelica_metatype _v)
{
modelica_metatype _l = NULL;
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
if((_sz == arrayLength(_data)))
{
_l = arrayList(_data);
}
else
{
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar2;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer _i;
tmp5 = 1;
tmp6 = _sz;
_i = ((modelica_integer) 1);
_i = (((modelica_integer) 1) /* Range start-value */)-tmp5;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar3;
while(1) {
tmp4 = 1;
if (tmp5 > 0 ? _i+tmp5 <= tmp6 : _i+tmp5 >= tmp6) {
_i += tmp5;
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar2 = arrayGetNoBoundsChecking(_data, _i);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar3;
}
_l = tmpMeta1;
}
_return: OMC_LABEL_UNUSED
return _l;
}
DLLExport
modelica_metatype omc_Vector_fromList(threadData_t *threadData, modelica_metatype _l)
{
modelica_metatype _v = NULL;
modelica_metatype _data = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = listArray(_l);
tmpMeta1 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, _data), omc_Mutable_create(threadData, mmc_mk_integer(arrayLength(_data))));
_v = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _v;
}
DLLExport
modelica_metatype omc_Vector_toArray(threadData_t *threadData, modelica_metatype _v)
{
modelica_metatype _arr = NULL;
modelica_metatype _data = NULL;
modelica_integer _sz;
modelica_metatype _dummy = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
_sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
_dummy = _dummy;
if((_sz == arrayLength(_data)))
{
_arr = arrayCopy(_data);
}
else
{
_arr = arrayCreateNoInit(_sz, _dummy);
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _sz;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
arrayUpdateNoBoundsChecking(_arr, _i, arrayGetNoBoundsChecking(_data, _i));
}
}
}
_return: OMC_LABEL_UNUSED
return _arr;
}
DLLExport
modelica_metatype omc_Vector_fromArray(threadData_t *threadData, modelica_metatype _arr)
{
modelica_metatype _v = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, arrayCopy(_arr)), omc_Mutable_create(threadData, mmc_mk_integer(arrayLength(_arr))));
_v = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _v;
}
DLLExport
modelica_metatype omc_Vector_newFill(threadData_t *threadData, modelica_integer _size, modelica_metatype _value)
{
modelica_metatype _v = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, arrayCreate(_size, _value)), omc_Mutable_create(threadData, mmc_mk_integer(_size)));
_v = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _v;
}
modelica_metatype boxptr_Vector_newFill(threadData_t *threadData, modelica_metatype _size, modelica_metatype _value)
{
modelica_integer tmp1;
modelica_metatype _v = NULL;
tmp1 = mmc_unbox_integer(_size);
_v = omc_Vector_newFill(threadData, tmp1, _value);
return _v;
}
DLLExport
modelica_metatype omc_Vector_new(threadData_t *threadData, modelica_integer _size)
{
modelica_metatype _v = NULL;
modelica_metatype _dummy = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_dummy = _dummy;
tmpMeta1 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, arrayCreateNoInit(_size, _dummy)), omc_Mutable_create(threadData, mmc_mk_integer(((modelica_integer) 0))));
_v = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _v;
}
modelica_metatype boxptr_Vector_new(threadData_t *threadData, modelica_metatype _size)
{
modelica_integer tmp1;
modelica_metatype _v = NULL;
tmp1 = mmc_unbox_integer(_size);
_v = omc_Vector_new(threadData, tmp1);
return _v;
}
