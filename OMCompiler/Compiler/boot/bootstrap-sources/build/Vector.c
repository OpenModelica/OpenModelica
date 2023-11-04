#ifdef OMC_BASE_FILE
  #define OMC_FILE OMC_BASE_FILE
#else
  #define OMC_FILE "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/boot/build/tmp/Vector.c"
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


/* default, do not make protected functions static */
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
#line 756 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if((_newSize > _cap))
#line 756 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 757 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    _cap = modelica_integer_max((modelica_integer)(_cap),(modelica_integer)(((modelica_integer) 1)));
#line 49 OMC_FILE

#line 759 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    while(1)
#line 759 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 759 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      if(!(_newSize > _cap)) break;
#line 760 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      _cap = (((modelica_integer) 2)) * (_cap);
#line 59 OMC_FILE
    }

#line 763 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    _data = omc_Vector_resizeArray(threadData, omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2)))), _cap);
#line 64 OMC_FILE

#line 764 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))), _data);
#line 68 OMC_FILE
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
  /* skip box _data; array<polymorphic<T>> */
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
  // _outArr has no default value.
  _dummy = _dummy;
#line 742 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _outArr = arrayCreateNoInit(_newSize, _dummy);
#line 96 OMC_FILE

#line 744 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = modelica_integer_min((modelica_integer)(_newSize),(modelica_integer)(arrayLength(_arr)));
#line 744 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 744 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 744 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 744 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 744 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 745 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      arrayUpdateNoBoundsChecking(_outArr, _i, arrayGetNoBoundsChecking(_arr, _i));
#line 112 OMC_FILE
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
  /* skip box _outArr; array<polymorphic<T>> */
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
  // _str has no default value.
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_metatype __omcQ_24tmpVar1;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_metatype* tmp2;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_metatype tmpMeta3;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_string __omcQ_24tmpVar0;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer tmp4;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_metatype _e_loopVar = 0;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer tmp5;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_metatype _e;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    _e_loopVar = omc_Vector_toArray(threadData, _v);
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    tmp5 = 1;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    __omcQ_24tmpVar1 = tmpMeta3; /* defaultValue */
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    tmp2 = &__omcQ_24tmpVar1;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    while(1) {
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      tmp4 = 1;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      if (tmp5 <= arrayLength(_e_loopVar)) {
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        _e = arrayGet(_e_loopVar, tmp5++);
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        tmp4--;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      }
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      if (tmp4 == 0) {
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        __omcQ_24tmpVar0 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stringFn), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stringFn), 1)))) (threadData, _e);
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        *tmp2 = mmc_mk_cons(__omcQ_24tmpVar0,0);
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        tmp2 = &MMC_CDR(*tmp2);
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      } else if (tmp4 == 1) {
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        break;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      } else {
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        MMC_THROW_INTERNAL();
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      }
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    }
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    *tmp2 = mmc_mk_nil();
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    tmpMeta1 = __omcQ_24tmpVar1;
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  }
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmpMeta6 = stringAppend(_strBegin,stringDelimitList(tmpMeta1, _delim));
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmpMeta7 = stringAppend(tmpMeta6,_strEnd);
#line 728 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _str = tmpMeta7;
#line 210 OMC_FILE
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
#line 709 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 2))), _data2);
#line 230 OMC_FILE

#line 710 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 2))), _data1);
#line 234 OMC_FILE

#line 711 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 3))), mmc_mk_integer(_sz2));
#line 238 OMC_FILE

#line 712 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 3))), mmc_mk_integer(_sz1));
#line 242 OMC_FILE
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
  // _c has no default value.
  _data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
  _sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
#line 690 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _data = arrayCopy(_data);
#line 264 OMC_FILE

#line 692 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_data);
#line 692 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 692 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 692 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 692 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 692 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 693 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      arrayUpdateNoBoundsChecking(_data, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i)));
#line 280 OMC_FILE
    }
  }

#line 696 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmpMeta4 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, _data), omc_Mutable_create(threadData, mmc_mk_integer(_sz)));
#line 696 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _c = tmpMeta4;
#line 288 OMC_FILE
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
  // _c has no default value.
  _data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
  _sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
#line 674 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmpMeta1 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, arrayCopy(_data)), omc_Mutable_create(threadData, mmc_mk_integer(_sz)));
#line 674 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _c = tmpMeta1;
#line 309 OMC_FILE
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
  // _res has no default value.
  _data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
#line 656 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
#line 656 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 656 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 656 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 656 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 656 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 657 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i))))
#line 657 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      {
#line 658 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        _res = 0;
#line 344 OMC_FILE

#line 659 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        goto _return;
#line 348 OMC_FILE
      }
    }
  }

#line 663 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _res = 1;
#line 355 OMC_FILE
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
  // _res has no default value.
  _data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
#line 632 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
#line 632 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 632 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 632 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 632 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 632 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 633 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i))))
#line 633 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      {
#line 634 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        _res = 1;
#line 398 OMC_FILE

#line 635 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        goto _return;
#line 402 OMC_FILE
      }
    }
  }

#line 639 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _res = 0;
#line 409 OMC_FILE
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
  // _res has no default value.
  _data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
#line 608 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
#line 608 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 608 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 608 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 608 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 608 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 609 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      if((!mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i)))))
#line 609 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      {
#line 610 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        _res = 0;
#line 452 OMC_FILE

#line 611 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        goto _return;
#line 456 OMC_FILE
      }
    }
  }

#line 615 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _res = 1;
#line 463 OMC_FILE
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
  // _e has no default value.
  // _res has no default value.
#line 583 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp4 = ((modelica_integer) 1); tmp5 = 1; tmp6 = _sz;
#line 583 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp5 > 0) && (tmp4 > tmp6)) || ((tmp5 < 0) && (tmp4 < tmp6))))
#line 583 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 583 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 583 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp4, tmp6); _i += tmp5)
#line 583 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 584 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      _e = arrayGetNoBoundsChecking(_data, _i);
#line 515 OMC_FILE

#line 586 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      /* Pattern-matching tuple assignment */
#line 586 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      tmpMeta2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _e, _arg, &tmpMeta1) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _e, _arg, &tmpMeta1);
#line 586 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      tmp3 = mmc_unbox_integer(tmpMeta2);
#line 586 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      _res = tmp3  /* pattern as ty=Boolean */;
#line 586 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      _arg = tmpMeta1;
#line 527 OMC_FILE

#line 587 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      if(_res)
#line 587 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      {
#line 588 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        _oe = mmc_mk_some(_e);
#line 535 OMC_FILE

#line 589 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        _index = _i;
#line 539 OMC_FILE
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
  /* skip box _oe; Option<polymorphic<T>> */
  if (out_index) { *out_index = mmc_mk_icon(_index); }
  /* skip box _arg; polymorphic<FT> */
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
  // _oe has no default value.
  // _index has no default value.
  _data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
  _sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
  // _e has no default value.
#line 548 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _sz;
#line 548 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 548 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 548 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 548 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 548 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 549 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      _e = arrayGetNoBoundsChecking(_data, _i);
#line 591 OMC_FILE

#line 551 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _e)))
#line 551 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      {
#line 552 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        _oe = mmc_mk_some(_e);
#line 599 OMC_FILE

#line 553 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        _index = _i;
#line 603 OMC_FILE

#line 554 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        goto _return;
#line 607 OMC_FILE
      }
    }
  }

#line 558 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _oe = mmc_mk_none();
#line 614 OMC_FILE

#line 559 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _index = ((modelica_integer) -1);
#line 618 OMC_FILE
  _return: OMC_LABEL_UNUSED
  if (out_index) { *out_index = _index; }
  return _oe;
}
modelica_metatype boxptr_Vector_find(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn, modelica_metatype *out_index)
{
  modelica_integer _index;
  modelica_metatype _oe = NULL;
  _oe = omc_Vector_find(threadData, _v, _fn, &_index);
  /* skip box _oe; Option<polymorphic<T>> */
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
#line 526 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _sz;
#line 526 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 526 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 526 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 526 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 526 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 527 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      _arg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i), _arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i), _arg);
#line 661 OMC_FILE
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
#line 505 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _sz;
#line 505 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 505 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 505 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 505 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 505 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 506 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      arrayUpdateNoBoundsChecking(_data, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i)));
#line 694 OMC_FILE
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
#line 487 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp3 = _sz; tmp4 = ((modelica_integer) -1); tmp5 = ((modelica_integer) 1);
#line 487 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp4 > 0) && (tmp3 > tmp5)) || ((tmp4 < 0) && (tmp3 < tmp5))))
#line 487 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 487 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 487 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = _sz; in_range_integer(_i, tmp3, tmp5); _i += tmp4)
#line 487 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 488 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      tmpMeta2 = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i)), _l);
#line 488 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      _l = tmpMeta2;
#line 734 OMC_FILE
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
  // _outV has no default value.
  _data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
  _sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
  // _new_data has no default value.
  _dummy = _dummy;
#line 463 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _new_data = arrayCreateNoInit((_shrink?_sz:arrayLength(_data)), _dummy);
#line 762 OMC_FILE

#line 465 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _sz;
#line 465 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 465 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 465 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 465 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 465 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 466 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      arrayUpdateNoBoundsChecking(_new_data, _i, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), arrayGetNoBoundsChecking(_data, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, arrayGetNoBoundsChecking(_data, _i)));
#line 778 OMC_FILE
    }
  }

#line 469 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmpMeta4 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, _new_data), omc_Mutable_create(threadData, mmc_mk_integer(_sz)));
#line 469 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _outV = tmpMeta4;
#line 786 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _outV;
}
modelica_metatype boxptr_Vector_map(threadData_t *threadData, modelica_metatype _v, modelica_fnptr _fn, modelica_metatype _shrink)
{
  modelica_integer tmp1;
  modelica_metatype _outV = NULL;
  tmp1 = mmc_unbox_integer(_shrink);
  _outV = omc_Vector_map(threadData, _v, _fn, tmp1);
  /* skip box _outV; Vector<polymorphic<OT>> */
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
#line 434 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(((((_from < ((modelica_integer) 1)) || (_to < ((modelica_integer) 1))) || (_from > _sz)) || (_to > _sz)))
#line 434 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 435 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    MMC_THROW_INTERNAL();
#line 818 OMC_FILE
  }

#line 438 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = _from; tmp2 = 1; tmp3 = _to;
#line 438 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 438 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 438 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 438 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = _from; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 438 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 439 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      arrayUpdateNoBoundsChecking(_data, _i, _value);
#line 835 OMC_FILE
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
#line 416 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if((_sz < arrayLength(_data)))
#line 416 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 417 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    _data = omc_Vector_resizeArray(threadData, _data, _sz);
#line 866 OMC_FILE

#line 418 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))), _data);
#line 870 OMC_FILE
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
#line 403 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if((_newCapacity > arrayLength(_data)))
#line 403 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 404 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    _data = omc_Vector_resizeArray(threadData, _data, _newCapacity);
#line 889 OMC_FILE

#line 405 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))), _data);
#line 893 OMC_FILE
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
  // _value has no default value.
  _data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
  _sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
#line 369 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if((_sz == ((modelica_integer) 0)))
#line 369 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 370 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    MMC_THROW_INTERNAL();
#line 980 OMC_FILE
  }

#line 373 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _value = arrayGetNoBoundsChecking(_data, _sz);
#line 985 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _value;
}

DLLExport
modelica_metatype omc_Vector_getNoBounds(threadData_t *threadData, modelica_metatype _v, modelica_integer _index)
{
  modelica_metatype _value = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _value has no default value.
#line 358 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _value = arrayGetNoBoundsChecking(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2)))), _index);
#line 999 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _value;
}
modelica_metatype boxptr_Vector_getNoBounds(threadData_t *threadData, modelica_metatype _v, modelica_metatype _index)
{
  modelica_integer tmp1;
  modelica_metatype _value = NULL;
  tmp1 = mmc_unbox_integer(_index);
  _value = omc_Vector_getNoBounds(threadData, _v, tmp1);
  /* skip box _value; polymorphic<T> */
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
  // _value has no default value.
  _data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
  _sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
#line 343 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(((_index <= ((modelica_integer) 0)) || (_index > _sz)))
#line 343 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 344 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    MMC_THROW_INTERNAL();
#line 1030 OMC_FILE
  }

#line 347 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _value = arrayGetNoBoundsChecking(_data, _index);
#line 1035 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _value;
}
modelica_metatype boxptr_Vector_get(threadData_t *threadData, modelica_metatype _v, modelica_metatype _index)
{
  modelica_integer tmp1;
  modelica_metatype _value = NULL;
  tmp1 = mmc_unbox_integer(_index);
  _value = omc_Vector_get(threadData, _v, tmp1);
  /* skip box _value; polymorphic<T> */
  return _value;
}

DLLExport
void omc_Vector_updateNoBounds(threadData_t *threadData, modelica_metatype _v, modelica_integer _index, modelica_metatype _value)
{
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
#line 330 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  arrayUpdateNoBoundsChecking(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2)))), _index, _value);
#line 1056 OMC_FILE
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
#line 315 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(((_index <= ((modelica_integer) 0)) || (_index > _sz)))
#line 315 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 316 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    MMC_THROW_INTERNAL();
#line 1083 OMC_FILE
  }

#line 319 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  arrayUpdateNoBoundsChecking(_data, _index, _value);
#line 1088 OMC_FILE
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
  // _data has no default value.
#line 289 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if((_index == _sz))
#line 289 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 290 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    omc_Vector_pop(threadData, _v);
#line 1118 OMC_FILE
  }
  else
  {
    if(((_index < ((modelica_integer) 0)) || (_index > _sz)))
    {
#line 292 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      MMC_THROW_INTERNAL();
#line 1126 OMC_FILE
    }
    else
    {
#line 294 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      _data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
#line 1132 OMC_FILE

#line 296 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      tmp1 = _index; tmp2 = 1; tmp3 = _sz;
#line 296 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 296 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      {
#line 296 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        modelica_integer _i;
#line 296 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        for(_i = _index; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 296 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        {
#line 297 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
          arrayUpdateNoBoundsChecking(_data, _i, arrayGetNoBoundsChecking(_data, ((modelica_integer) 1) + _i));
#line 1148 OMC_FILE
        }
      }

#line 301 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(((modelica_integer) -1) + _sz));
#line 1154 OMC_FILE
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
#line 273 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if((_newSize < _sz))
#line 273 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 274 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    omc_Vector_shrink(threadData, _v, _newSize);
#line 1181 OMC_FILE
  }
  else
  {
    if((_newSize > _sz))
    {
#line 276 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      omc_Vector_grow(threadData, _v, _newSize, _fillValue);
#line 1189 OMC_FILE
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
  // _data has no default value.
  _sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
#line 255 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if((_newSize > _sz))
#line 255 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 256 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    _data = omc_Vector_reserveCapacity(threadData, _v, _newSize);
#line 1221 OMC_FILE

#line 258 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    tmp1 = ((modelica_integer) 1) + _sz; tmp2 = 1; tmp3 = _newSize;
#line 258 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 258 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 258 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      modelica_integer _i;
#line 258 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      for(_i = ((modelica_integer) 1) + _sz; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 258 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      {
#line 259 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        arrayUpdateNoBoundsChecking(_data, _i, _fillValue);
#line 1237 OMC_FILE
      }
    }

#line 262 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(_newSize));
#line 1243 OMC_FILE
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
#line 238 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if((_newSize < _sz))
#line 238 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 239 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    tmp1 = _newSize; tmp2 = 1; tmp3 = _sz;
#line 239 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 239 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 239 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      modelica_integer _i;
#line 239 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      for(_i = _newSize; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 239 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      {
#line 240 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        arrayUpdateNoBoundsChecking(_data, _i, _null);
#line 1288 OMC_FILE
      }
    }

#line 243 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(_newSize));
#line 1294 OMC_FILE
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
#line 219 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
#line 219 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 219 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 219 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 219 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 219 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 220 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      arrayUpdateNoBoundsChecking(_data, _i, _null);
#line 1333 OMC_FILE
    }
  }

#line 223 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(((modelica_integer) 0)));
#line 1339 OMC_FILE
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
#line 207 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  arrayUpdateNoBoundsChecking(_data, _sz, _null);
#line 1357 OMC_FILE

#line 208 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(((modelica_integer) -1) + _sz));
#line 1361 OMC_FILE
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
  // _data has no default value.
  _sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
  _new_sz = _sz + arrayLength(_arr);
#line 188 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _data = omc_Vector_reserveCapacity(threadData, _v, _new_sz);
#line 1382 OMC_FILE

#line 190 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_arr);
#line 190 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 190 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 190 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 190 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 190 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 191 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      arrayUpdateNoBoundsChecking(_data, _sz + _i, arrayGetNoBoundsChecking(_arr, _i));
#line 1398 OMC_FILE
    }
  }

#line 195 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(_new_sz));
#line 1404 OMC_FILE
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
  // _data has no default value.
  _sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
  _new_sz = _sz + listLength(_l);
  _rest_l = _l;
#line 169 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _data = omc_Vector_reserveCapacity(threadData, _v, _new_sz);
#line 1427 OMC_FILE

#line 171 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1) + _sz; tmp2 = 1; tmp3 = _new_sz;
#line 171 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 171 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 171 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 171 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1) + _sz; in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 171 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 172 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      arrayUpdateNoBoundsChecking(_data, _i, listHead(_rest_l));
#line 1443 OMC_FILE

#line 173 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      _rest_l = listRest(_rest_l);
#line 1447 OMC_FILE
    }
  }

#line 176 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(_new_sz));
#line 1453 OMC_FILE
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
  // _data1 has no default value.
  _sz1 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 3)))));
  _data2 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 2))));
  _sz2 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v2), 3)))));
  _new_sz = _sz1 + _sz2;
#line 148 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _data1 = omc_Vector_reserveCapacity(threadData, _v1, _new_sz);
#line 1478 OMC_FILE

#line 150 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _sz1 = ((modelica_integer) 1) + _sz1;
#line 1482 OMC_FILE

#line 151 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_data2);
#line 151 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 151 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 151 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    modelica_integer _i;
#line 151 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 151 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 152 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      arrayUpdateNoBoundsChecking(_data1, _sz1 + _i, arrayGetNoBoundsChecking(_data2, _i));
#line 1498 OMC_FILE
    }
  }

#line 156 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v1), 3))), mmc_mk_integer(_new_sz));
#line 1504 OMC_FILE
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
  // _data has no default value.
  _sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
#line 130 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _sz = ((modelica_integer) 1) + _sz;
#line 1520 OMC_FILE

#line 131 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3))), mmc_mk_integer(_sz));
#line 1524 OMC_FILE

#line 133 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _data = omc_Vector_reserveCapacity(threadData, _v, _sz);
#line 1528 OMC_FILE

#line 134 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  arrayUpdateNoBoundsChecking(_data, _sz, _value);
#line 1532 OMC_FILE
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
  // _l has no default value.
  _data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
  _sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
#line 114 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if((_sz == arrayLength(_data)))
#line 114 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 116 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    _l = arrayList(_data);
#line 1555 OMC_FILE
  }
  else
  {
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      modelica_metatype __omcQ_24tmpVar3;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      modelica_metatype* tmp2;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      modelica_metatype tmpMeta3;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      modelica_metatype __omcQ_24tmpVar2;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      modelica_integer tmp4;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      modelica_integer tmp5;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      modelica_integer tmp6;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      modelica_integer _i;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      tmp5 = 1 /* Range step-value */;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      tmp6 = _sz /* Range stop-value */;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      _i = ((modelica_integer) 1) /* Range start-value */;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      _i = (((modelica_integer) 1) /* Range start-value */)-tmp5;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      __omcQ_24tmpVar3 = tmpMeta3; /* defaultValue */
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      tmp2 = &__omcQ_24tmpVar3;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      while(1) {
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        tmp4 = 1;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        if (tmp5 > 0 ? _i+tmp5 <= tmp6 : _i+tmp5 >= tmp6) {
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
          _i += tmp5;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
          tmp4--;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        }
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        if (tmp4 == 0) {
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
          __omcQ_24tmpVar2 = arrayGetNoBoundsChecking(_data, _i);
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
          *tmp2 = mmc_mk_cons(__omcQ_24tmpVar2,0);
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
          tmp2 = &MMC_CDR(*tmp2);
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        } else if (tmp4 == 1) {
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
          break;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        } else {
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
          MMC_THROW_INTERNAL();
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        }
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      }
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      *tmp2 = mmc_mk_nil();
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      tmpMeta1 = __omcQ_24tmpVar3;
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    }
#line 118 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    _l = tmpMeta1;
#line 1631 OMC_FILE
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
  // _v has no default value.
  _data = listArray(_l);
#line 103 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmpMeta1 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, _data), omc_Mutable_create(threadData, mmc_mk_integer(arrayLength(_data))));
#line 103 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _v = tmpMeta1;
#line 1651 OMC_FILE
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
  // _arr has no default value.
  _data = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2))));
  _sz = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 3)))));
  _dummy = _dummy;
#line 85 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  if((_sz == arrayLength(_data)))
#line 85 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  {
#line 87 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    _arr = arrayCopy(_data);
#line 1678 OMC_FILE
  }
  else
  {
#line 89 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    _arr = arrayCreateNoInit(_sz, _dummy);
#line 1684 OMC_FILE

#line 90 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = _sz;
#line 90 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 90 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
    {
#line 90 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      modelica_integer _i;
#line 90 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 90 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
      {
#line 91 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
        arrayUpdateNoBoundsChecking(_arr, _i, arrayGetNoBoundsChecking(_data, _i));
#line 1700 OMC_FILE
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
  // _v has no default value.
#line 72 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmpMeta1 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, arrayCopy(_arr)), omc_Mutable_create(threadData, mmc_mk_integer(arrayLength(_arr))));
#line 72 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _v = tmpMeta1;
#line 1720 OMC_FILE
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
  // _v has no default value.
#line 63 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmpMeta1 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, arrayCreate(_size, _value)), omc_Mutable_create(threadData, mmc_mk_integer(_size)));
#line 63 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _v = tmpMeta1;
#line 1737 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _v;
}
modelica_metatype boxptr_Vector_newFill(threadData_t *threadData, modelica_metatype _size, modelica_metatype _value)
{
  modelica_integer tmp1;
  modelica_metatype _v = NULL;
  tmp1 = mmc_unbox_integer(_size);
  _v = omc_Vector_newFill(threadData, tmp1, _value);
  /* skip box _v; Vector<polymorphic<T>> */
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
  // _v has no default value.
  _dummy = _dummy;
#line 53 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  tmpMeta1 = mmc_mk_box3(3, &Vector_VECTOR__desc, omc_Mutable_create(threadData, arrayCreateNoInit(_size, _dummy)), omc_Mutable_create(threadData, mmc_mk_integer(((modelica_integer) 0))));
#line 53 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/Vector.mo"
  _v = tmpMeta1;
#line 1765 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _v;
}
modelica_metatype boxptr_Vector_new(threadData_t *threadData, modelica_metatype _size)
{
  modelica_integer tmp1;
  modelica_metatype _v = NULL;
  tmp1 = mmc_unbox_integer(_size);
  _v = omc_Vector_new(threadData, tmp1);
  /* skip box _v; Vector<polymorphic<T>> */
  return _v;
}

