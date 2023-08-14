#ifdef OMC_BASE_FILE
  #define OMC_FILE OMC_BASE_FILE
#else
  #define OMC_FILE "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/boot/build/tmp/UnorderedMap.c"
#endif
#include "omc_simulation_settings.h"
#include "UnorderedMap.h"
#define _OMC_LIT0_data "UnorderedMap.toJSON"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,19,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,4) {&IOStream_IOStreamType_LIST__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "{\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,2,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "  \""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,3,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "\": \""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,4,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,1,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data ",\n  \""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,5,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "\n}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,2,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,1,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,1,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,2,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,1,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,17,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT14}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT12,_OMC_LIT13,_OMC_LIT15}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "UnorderedMap.toList failed because there is an unequal number of keys ("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,71,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data ") and values ("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,14,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data ")."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,2,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "UnorderedMap.getSafe failed because the key did not exist."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,58,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#include "util/modelica.h"

#include "UnorderedMap_includes.h"


/* default, do not make protected functions static */
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC void omc_UnorderedMap_addEntry(threadData_t *threadData, modelica_metatype _key, modelica_metatype _value, modelica_integer _hash, modelica_metatype _map);
PROTECTED_FUNCTION_STATIC void boxptr_UnorderedMap_addEntry(threadData_t *threadData, modelica_metatype _key, modelica_metatype _value, modelica_metatype _hash, modelica_metatype _map);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_addEntry,2,0) {(void*) boxptr_UnorderedMap_addEntry,0}};
#define boxvar_UnorderedMap_addEntry MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_addEntry)
PROTECTED_FUNCTION_STATIC modelica_integer omc_UnorderedMap_find(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map, modelica_integer *out_hash);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_UnorderedMap_find(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map, modelica_metatype *out_hash);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_find,2,0) {(void*) boxptr_UnorderedMap_find,0}};
#define boxvar_UnorderedMap_find MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_find)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_UnorderedMap_remove_update__indices(threadData_t *threadData, modelica_metatype _bucket, modelica_integer _removedIndex);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_UnorderedMap_remove_update__indices(threadData_t *threadData, modelica_metatype _bucket, modelica_metatype _removedIndex);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedMap_remove_update__indices,2,0) {(void*) boxptr_UnorderedMap_remove_update__indices,0}};
#define boxvar_UnorderedMap_remove_update__indices MMC_REFSTRUCTLIT(boxvar_lit_UnorderedMap_remove_update__indices)

PROTECTED_FUNCTION_STATIC void omc_UnorderedMap_addEntry(threadData_t *threadData, modelica_metatype _key, modelica_metatype _value, modelica_integer _hash, modelica_metatype _map)
{
  modelica_metatype _buckets = NULL;
  modelica_metatype tmpMeta1;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  _buckets = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)));
#line 764 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_push(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), _key);
#line 97 OMC_FILE

#line 765 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_push(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _value);
#line 101 OMC_FILE

#line 767 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if((omc_UnorderedMap_loadFactor(threadData, _map) > 1.0))
#line 767 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 770 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    omc_UnorderedMap_rehash(threadData, _map);
#line 109 OMC_FILE
  }
  else
  {
#line 773 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    tmpMeta1 = mmc_mk_cons(mmc_mk_integer(omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))))), omc_Vector_get(threadData, _buckets, ((modelica_integer) 1) + _hash));
#line 773 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    omc_Vector_update(threadData, _buckets, ((modelica_integer) 1) + _hash, tmpMeta1);
#line 117 OMC_FILE
  }
  _return: OMC_LABEL_UNUSED
  return;
}
PROTECTED_FUNCTION_STATIC void boxptr_UnorderedMap_addEntry(threadData_t *threadData, modelica_metatype _key, modelica_metatype _value, modelica_metatype _hash, modelica_metatype _map)
{
  modelica_integer tmp1;
  tmp1 = mmc_unbox_integer(_hash);
  omc_UnorderedMap_addEntry(threadData, _key, _value, tmp1, _map);
  return;
}

PROTECTED_FUNCTION_STATIC modelica_integer omc_UnorderedMap_find(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map, modelica_integer *out_hash)
{
  modelica_integer _index;
  modelica_integer _hash;
  modelica_fnptr _hashfn;
  modelica_fnptr _eqfn;
  modelica_metatype _bucket = NULL;
  modelica_metatype tmpMeta1;
  modelica_metatype tmpMeta2;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  _index = ((modelica_integer) -1);
  // _hash has no default value.
  _hashfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 5)));
  _eqfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 6)));
  // _bucket has no default value.
#line 739 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if((omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))) > ((modelica_integer) 0)))
#line 739 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 740 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _hash = modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, _key)), omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))));
#line 152 OMC_FILE

#line 742 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _bucket = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))), ((modelica_integer) 1) + _hash);
#line 156 OMC_FILE

#line 743 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    {
#line 743 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      modelica_metatype _i;
#line 743 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      for (tmpMeta1 = _bucket; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
#line 743 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      {
#line 743 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        _i = MMC_CAR(tmpMeta1);
#line 744 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqfn), 2))), _key, omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), mmc_unbox_integer(_i))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqfn), 1)))) (threadData, _key, omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), mmc_unbox_integer(_i)))))
#line 744 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        {
#line 745 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
          _index = mmc_unbox_integer(_i);
#line 174 OMC_FILE

#line 746 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
          break;
#line 178 OMC_FILE
        }
      }
    }
  }
  else
  {
#line 750 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _hash = ((modelica_integer) 0);
#line 187 OMC_FILE
  }
  _return: OMC_LABEL_UNUSED
  if (out_hash) { *out_hash = _hash; }
  return _index;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_UnorderedMap_find(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map, modelica_metatype *out_hash)
{
  modelica_integer _hash;
  modelica_integer _index;
  modelica_metatype out_index;
  _index = omc_UnorderedMap_find(threadData, _key, _map, &_hash);
  out_index = mmc_mk_icon(_index);
  if (out_hash) { *out_hash = mmc_mk_icon(_hash); }
  return out_index;
}

DLLExport
modelica_string omc_UnorderedMap_toJSON(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _keyStringFn, modelica_fnptr _valueStringFn)
{
  modelica_string _str = NULL;
  modelica_metatype _io = NULL;
  modelica_metatype _keys = NULL;
  modelica_metatype _values = NULL;
  modelica_integer _sz;
  modelica_integer tmp1;
  modelica_integer tmp2;
  modelica_integer tmp3;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _str has no default value.
  // _io has no default value.
  _keys = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)));
  _values = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4)));
  _sz = omc_Vector_size(threadData, _keys);
#line 703 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _io = omc_IOStream_create(threadData, _OMC_LIT0, _OMC_LIT1);
#line 224 OMC_FILE

#line 704 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _io = omc_IOStream_append(threadData, _io, _OMC_LIT2);
#line 228 OMC_FILE

#line 706 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if((_sz > ((modelica_integer) 0)))
#line 706 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 707 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _io = omc_IOStream_append(threadData, _io, _OMC_LIT3);
#line 236 OMC_FILE

#line 708 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _io = omc_IOStream_append(threadData, _io, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 2))), omc_Vector_getNoBounds(threadData, _keys, ((modelica_integer) 1))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 1)))) (threadData, omc_Vector_getNoBounds(threadData, _keys, ((modelica_integer) 1))));
#line 240 OMC_FILE

#line 709 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _io = omc_IOStream_append(threadData, _io, _OMC_LIT4);
#line 244 OMC_FILE

#line 710 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _io = omc_IOStream_append(threadData, _io, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 2))), omc_Vector_getNoBounds(threadData, _values, ((modelica_integer) 1))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 1)))) (threadData, omc_Vector_getNoBounds(threadData, _values, ((modelica_integer) 1))));
#line 248 OMC_FILE

#line 711 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _io = omc_IOStream_append(threadData, _io, _OMC_LIT5);
#line 252 OMC_FILE

#line 713 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    tmp1 = ((modelica_integer) 2); tmp2 = 1; tmp3 = _sz;
#line 713 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
#line 713 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    {
#line 713 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      modelica_integer _i;
#line 713 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
#line 713 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      {
#line 714 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        _io = omc_IOStream_append(threadData, _io, _OMC_LIT6);
#line 268 OMC_FILE

#line 715 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        _io = omc_IOStream_append(threadData, _io, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 2))), omc_Vector_getNoBounds(threadData, _keys, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 1)))) (threadData, omc_Vector_getNoBounds(threadData, _keys, _i)));
#line 272 OMC_FILE

#line 716 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        _io = omc_IOStream_append(threadData, _io, _OMC_LIT4);
#line 276 OMC_FILE

#line 717 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        _io = omc_IOStream_append(threadData, _io, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 2))), omc_Vector_getNoBounds(threadData, _values, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 1)))) (threadData, omc_Vector_getNoBounds(threadData, _values, _i)));
#line 280 OMC_FILE

#line 718 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        _io = omc_IOStream_append(threadData, _io, _OMC_LIT5);
#line 284 OMC_FILE
      }
    }
  }

#line 722 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _io = omc_IOStream_append(threadData, _io, _OMC_LIT7);
#line 291 OMC_FILE

#line 723 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _str = omc_IOStream_string(threadData, _io);
#line 295 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _str;
}

DLLExport
modelica_string omc_UnorderedMap_toString(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _keyStringFn, modelica_fnptr _valueStringFn, modelica_string _delimiter)
{
  modelica_string _str = NULL;
  modelica_metatype _strl = NULL;
  modelica_metatype tmpMeta1;
  modelica_metatype _keys = NULL;
  modelica_metatype _values = NULL;
  modelica_metatype tmpMeta2;
  modelica_metatype tmpMeta3;
  modelica_metatype tmpMeta4;
  modelica_metatype tmpMeta5;
  modelica_metatype tmpMeta6;
  modelica_integer tmp7;
  modelica_integer tmp8;
  modelica_integer tmp9;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _str has no default value.
  tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
  _strl = tmpMeta1;
  _keys = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)));
  _values = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4)));
#line 674 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmp7 = omc_Vector_size(threadData, _keys); tmp8 = ((modelica_integer) -1); tmp9 = ((modelica_integer) 1);
#line 674 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if(!(((tmp8 > 0) && (tmp7 > tmp9)) || ((tmp8 < 0) && (tmp7 < tmp9))))
#line 674 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 674 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    modelica_integer _i;
#line 674 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    for(_i = omc_Vector_size(threadData, _keys); in_range_integer(_i, tmp7, tmp9); _i += tmp8)
#line 674 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    {
#line 675 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      tmpMeta3 = stringAppend(_OMC_LIT9,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 2))), omc_Vector_get(threadData, _keys, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 1)))) (threadData, omc_Vector_get(threadData, _keys, _i)));
#line 675 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      tmpMeta4 = stringAppend(tmpMeta3,_OMC_LIT10);
#line 675 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      tmpMeta5 = stringAppend(tmpMeta4,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 2))), omc_Vector_get(threadData, _values, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 1)))) (threadData, omc_Vector_get(threadData, _values, _i)));
#line 675 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      tmpMeta6 = stringAppend(tmpMeta5,_OMC_LIT11);
#line 675 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      tmpMeta2 = mmc_mk_cons(tmpMeta6, _strl);
#line 675 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      _strl = tmpMeta2;
#line 347 OMC_FILE
    }
  }

#line 679 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _str = stringDelimitList(_strl, _delimiter);
#line 353 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _str;
}

DLLExport
void omc_UnorderedMap_rehash(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _keys = NULL;
  modelica_metatype _buckets = NULL;
  modelica_integer _bucket_count;
  modelica_integer _bucket_id;
  modelica_fnptr _hashfn;
  modelica_metatype tmpMeta1;
  modelica_metatype tmpMeta2;
  modelica_integer tmp3;
  modelica_integer tmp4;
  modelica_integer tmp5;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  _keys = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)));
  _buckets = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)));
  // _bucket_count has no default value.
  // _bucket_id has no default value.
  _hashfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 5)));
#line 639 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_clear(threadData, _buckets);
#line 380 OMC_FILE

#line 642 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _bucket_count = omc_Util_nextPrime(threadData, (((modelica_integer) 2)) * (omc_Vector_size(threadData, _keys)));
#line 384 OMC_FILE

#line 643 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
#line 643 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_resize(threadData, _buckets, _bucket_count, tmpMeta1);
#line 390 OMC_FILE

#line 646 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmp3 = ((modelica_integer) 1); tmp4 = 1; tmp5 = omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))));
#line 646 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if(!(((tmp4 > 0) && (tmp3 > tmp5)) || ((tmp4 < 0) && (tmp3 < tmp5))))
#line 646 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 646 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    modelica_integer _i;
#line 646 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp3, tmp5); _i += tmp4)
#line 646 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    {
#line 647 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      _bucket_id = ((modelica_integer) 1) + modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))), omc_Vector_get(threadData, _keys, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, omc_Vector_get(threadData, _keys, _i))), _bucket_count);
#line 406 OMC_FILE

#line 648 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      tmpMeta2 = mmc_mk_cons(mmc_mk_integer(_i), omc_Vector_getNoBounds(threadData, _buckets, _bucket_id));
#line 648 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      omc_Vector_updateNoBounds(threadData, _buckets, _bucket_id, tmpMeta2);
#line 412 OMC_FILE
    }
  }
  _return: OMC_LABEL_UNUSED
  return;
}

DLLExport
modelica_real omc_UnorderedMap_loadFactor(threadData_t *threadData, modelica_metatype _map)
{
  modelica_real _load;
  modelica_real tmp1;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  tmp1 = ((modelica_real)omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))));
  if (tmp1 == 0) {MMC_THROW_INTERNAL();}
  _load = (((modelica_real)omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)))))) / tmp1;
  _return: OMC_LABEL_UNUSED
  return _load;
}
modelica_metatype boxptr_UnorderedMap_loadFactor(threadData_t *threadData, modelica_metatype _map)
{
  modelica_real _load;
  modelica_real tmp1;
  modelica_metatype out_load;
  _load = omc_UnorderedMap_loadFactor(threadData, _map);
  out_load = mmc_mk_rcon(_load);
  return out_load;
}

DLLExport
modelica_integer omc_UnorderedMap_bucketCount(threadData_t *threadData, modelica_metatype _map)
{
  modelica_integer _count;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  _count = omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))));
  _return: OMC_LABEL_UNUSED
  return _count;
}
modelica_metatype boxptr_UnorderedMap_bucketCount(threadData_t *threadData, modelica_metatype _map)
{
  modelica_integer _count;
  modelica_metatype out_count;
  _count = omc_UnorderedMap_bucketCount(threadData, _map);
  out_count = mmc_mk_icon(_count);
  return out_count;
}

DLLExport
modelica_boolean omc_UnorderedMap_isEmpty(threadData_t *threadData, modelica_metatype _map)
{
  modelica_boolean _empty;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  _empty = omc_Vector_isEmpty(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))));
  _return: OMC_LABEL_UNUSED
  return _empty;
}
modelica_metatype boxptr_UnorderedMap_isEmpty(threadData_t *threadData, modelica_metatype _map)
{
  modelica_boolean _empty;
  modelica_metatype out_empty;
  _empty = omc_UnorderedMap_isEmpty(threadData, _map);
  out_empty = mmc_mk_icon(_empty);
  return out_empty;
}

DLLExport
modelica_integer omc_UnorderedMap_size(threadData_t *threadData, modelica_metatype _map)
{
  modelica_integer _size;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  _size = omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))));
  _return: OMC_LABEL_UNUSED
  return _size;
}
modelica_metatype boxptr_UnorderedMap_size(threadData_t *threadData, modelica_metatype _map)
{
  modelica_integer _size;
  modelica_metatype out_size;
  _size = omc_UnorderedMap_size(threadData, _map);
  out_size = mmc_mk_icon(_size);
  return out_size;
}

DLLExport
modelica_boolean omc_UnorderedMap_none(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn)
{
  modelica_boolean _res;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _res has no default value.
#line 600 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _res = omc_Vector_none(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn));
#line 508 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _res;
}
modelica_metatype boxptr_UnorderedMap_none(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn)
{
  modelica_boolean _res;
  modelica_metatype out_res;
  _res = omc_UnorderedMap_none(threadData, _map, _fn);
  out_res = mmc_mk_icon(_res);
  return out_res;
}

DLLExport
modelica_boolean omc_UnorderedMap_any(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn)
{
  modelica_boolean _res;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _res has no default value.
#line 585 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _res = omc_Vector_any(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn));
#line 530 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _res;
}
modelica_metatype boxptr_UnorderedMap_any(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn)
{
  modelica_boolean _res;
  modelica_metatype out_res;
  _res = omc_UnorderedMap_any(threadData, _map, _fn);
  out_res = mmc_mk_icon(_res);
  return out_res;
}

DLLExport
modelica_boolean omc_UnorderedMap_all(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn)
{
  modelica_boolean _res;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _res has no default value.
#line 570 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _res = omc_Vector_all(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn));
#line 552 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _res;
}
modelica_metatype boxptr_UnorderedMap_all(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn)
{
  modelica_boolean _res;
  modelica_metatype out_res;
  _res = omc_UnorderedMap_all(threadData, _map, _fn);
  out_res = mmc_mk_icon(_res);
  return out_res;
}

DLLExport
void omc_UnorderedMap_apply(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn)
{
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
#line 555 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_apply(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn));
#line 572 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return;
}

DLLExport
modelica_metatype omc_UnorderedMap_map(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn)
{
  modelica_metatype _outMap = NULL;
  modelica_metatype _new_values = NULL;
  modelica_metatype tmpMeta1;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _outMap has no default value.
  // _new_values has no default value.
#line 535 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _new_values = omc_Vector_map(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn), 1);
#line 589 OMC_FILE

#line 536 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmpMeta1 = mmc_mk_box6(3, &UnorderedMap_UNORDERED__MAP__desc, omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))), omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)))), _new_values, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 6))));
#line 536 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _outMap = tmpMeta1;
#line 595 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _outMap;
}

DLLExport
modelica_metatype omc_UnorderedMap_fold(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn, modelica_metatype __omcQ_24in_5Farg)
{
  modelica_metatype _arg = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  _arg = __omcQ_24in_5Farg;
#line 518 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _arg = omc_Vector_fold(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn), _arg);
#line 609 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _arg;
}

DLLExport
modelica_metatype omc_UnorderedMap_valueVector(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _values = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _values has no default value.
#line 504 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _values = omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))));
#line 623 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _values;
}

DLLExport
modelica_metatype omc_UnorderedMap_keyVector(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _keys = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _keys has no default value.
#line 496 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _keys = omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))));
#line 637 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _keys;
}

DLLExport
modelica_metatype omc_UnorderedMap_toVector(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _entries = NULL;
  modelica_metatype _keys = NULL;
  modelica_metatype _values = NULL;
  modelica_integer _sz;
  modelica_metatype tmpMeta1;
  modelica_integer tmp2;
  modelica_integer tmp3;
  modelica_integer tmp4;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _entries has no default value.
  _keys = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)));
  _values = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4)));
  _sz = omc_Vector_size(threadData, _keys);
#line 483 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _entries = omc_Vector_new(threadData, _sz);
#line 661 OMC_FILE

#line 485 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmp2 = ((modelica_integer) 1); tmp3 = 1; tmp4 = _sz;
#line 485 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if(!(((tmp3 > 0) && (tmp2 > tmp4)) || ((tmp3 < 0) && (tmp2 < tmp4))))
#line 485 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 485 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    modelica_integer _i;
#line 485 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp2, tmp4); _i += tmp3)
#line 485 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    {
#line 486 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      tmpMeta1 = mmc_mk_box2(0, omc_Vector_getNoBounds(threadData, _keys, _i), omc_Vector_getNoBounds(threadData, _values, _i));
#line 486 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      omc_Vector_updateNoBounds(threadData, _entries, _i, tmpMeta1);
#line 679 OMC_FILE
    }
  }
  _return: OMC_LABEL_UNUSED
  return _entries;
}

DLLExport
modelica_metatype omc_UnorderedMap_valueArray(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _values = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _values has no default value.
#line 470 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _values = omc_Vector_toArray(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))));
#line 695 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _values;
}

DLLExport
modelica_metatype omc_UnorderedMap_keyArray(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _keys = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _keys has no default value.
#line 462 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _keys = omc_Vector_toArray(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))));
#line 709 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _keys;
}

DLLExport
modelica_metatype omc_UnorderedMap_toArray(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _entries = NULL;
  modelica_metatype _keys = NULL;
  modelica_metatype _values = NULL;
  modelica_metatype _t = NULL;
  modelica_integer _sz;
  modelica_metatype tmpMeta1;
  modelica_integer tmp2;
  modelica_integer tmp3;
  modelica_integer tmp4;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _entries has no default value.
  _keys = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)));
  _values = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4)));
  _t = _t;
  _sz = omc_Vector_size(threadData, _keys);
#line 449 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _entries = arrayCreateNoInit(_sz, _t);
#line 735 OMC_FILE

#line 451 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmp2 = ((modelica_integer) 1); tmp3 = 1; tmp4 = _sz;
#line 451 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if(!(((tmp3 > 0) && (tmp2 > tmp4)) || ((tmp3 < 0) && (tmp2 < tmp4))))
#line 451 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 451 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    modelica_integer _i;
#line 451 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp2, tmp4); _i += tmp3)
#line 451 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    {
#line 452 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      tmpMeta1 = mmc_mk_box2(0, omc_Vector_getNoBounds(threadData, _keys, _i), omc_Vector_getNoBounds(threadData, _values, _i));
#line 452 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      arrayUpdateNoBoundsChecking(_entries, _i, tmpMeta1);
#line 753 OMC_FILE
    }
  }
  _return: OMC_LABEL_UNUSED
  return _entries;
}

DLLExport
modelica_metatype omc_UnorderedMap_valueList(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _values = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _values has no default value.
#line 436 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _values = omc_Vector_toList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))));
#line 769 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _values;
}

DLLExport
modelica_metatype omc_UnorderedMap_keyList(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _keys = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _keys has no default value.
#line 428 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _keys = omc_Vector_toList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))));
#line 783 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _keys;
}

DLLExport
modelica_metatype omc_UnorderedMap_toList(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _lst = NULL;
  modelica_metatype _keys = NULL;
  modelica_metatype _values = NULL;
  modelica_metatype tmpMeta1;
  modelica_metatype tmpMeta2;
  modelica_metatype tmpMeta3;
  modelica_metatype tmpMeta4;
  modelica_metatype tmpMeta5;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _lst has no default value.
  _keys = omc_UnorderedMap_keyList(threadData, _map);
  _values = omc_UnorderedMap_valueList(threadData, _map);
#line 415 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if((listLength(_keys) == listLength(_values)))
#line 415 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 416 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _lst = omc_List_zip(threadData, _keys, _values);
#line 810 OMC_FILE
  }
  else
  {
#line 418 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    tmpMeta2 = stringAppend(_OMC_LIT17,intString(listLength(_keys)));
#line 418 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT18);
#line 418 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    tmpMeta4 = stringAppend(tmpMeta3,intString(listLength(_values)));
#line 418 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    tmpMeta5 = stringAppend(tmpMeta4,_OMC_LIT19);
#line 418 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    tmpMeta1 = mmc_mk_cons(tmpMeta5, MMC_REFSTRUCTLIT(mmc_nil));
#line 418 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    omc_Error_addMessage(threadData, _OMC_LIT16, tmpMeta1);
#line 826 OMC_FILE
  }
  _return: OMC_LABEL_UNUSED
  return _lst;
}

DLLExport
modelica_metatype omc_UnorderedMap_valueAt(threadData_t *threadData, modelica_metatype _map, modelica_integer _index)
{
  modelica_metatype _value = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _value has no default value.
#line 404 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _value = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index);
#line 841 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _value;
}
modelica_metatype boxptr_UnorderedMap_valueAt(threadData_t *threadData, modelica_metatype _map, modelica_metatype _index)
{
  modelica_integer tmp1;
  modelica_metatype _value = NULL;
  tmp1 = mmc_unbox_integer(_index);
  _value = omc_UnorderedMap_valueAt(threadData, _map, tmp1);
  /* skip box _value; polymorphic<V> */
  return _value;
}

DLLExport
modelica_metatype omc_UnorderedMap_keyAt(threadData_t *threadData, modelica_metatype _map, modelica_integer _index)
{
  modelica_metatype _key = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _key has no default value.
#line 396 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _key = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), _index);
#line 864 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _key;
}
modelica_metatype boxptr_UnorderedMap_keyAt(threadData_t *threadData, modelica_metatype _map, modelica_metatype _index)
{
  modelica_integer tmp1;
  modelica_metatype _key = NULL;
  tmp1 = mmc_unbox_integer(_index);
  _key = omc_UnorderedMap_keyAt(threadData, _map, tmp1);
  /* skip box _key; polymorphic<K> */
  return _key;
}

DLLExport
modelica_metatype omc_UnorderedMap_firstKey(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _key = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _key has no default value.
#line 388 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _key = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), ((modelica_integer) 1));
#line 887 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _key;
}

DLLExport
modelica_metatype omc_UnorderedMap_first(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _value = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _value has no default value.
#line 380 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _value = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_integer) 1));
#line 901 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _value;
}

DLLExport
modelica_boolean omc_UnorderedMap_contains(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map)
{
  modelica_boolean _res;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _res has no default value.
#line 372 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _res = (omc_UnorderedMap_find(threadData, _key, _map, NULL) > ((modelica_integer) 0));
#line 915 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _res;
}
modelica_metatype boxptr_UnorderedMap_contains(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map)
{
  modelica_boolean _res;
  modelica_metatype out_res;
  _res = omc_UnorderedMap_contains(threadData, _key, _map);
  out_res = mmc_mk_icon(_res);
  return out_res;
}

DLLExport
modelica_metatype omc_UnorderedMap_getKey(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map)
{
  modelica_metatype _outKey = NULL;
  modelica_integer _index;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _outKey has no default value.
  // _index has no default value.
#line 362 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _index = omc_UnorderedMap_find(threadData, _key, _map, NULL);
#line 939 OMC_FILE

#line 363 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _outKey = ((_index > ((modelica_integer) 0))?mmc_mk_some(omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), _index)):mmc_mk_none());
#line 943 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _outKey;
}

DLLExport
modelica_metatype omc_UnorderedMap_getOrDefault(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map, modelica_metatype _default)
{
  modelica_metatype _value = NULL;
  modelica_integer _index;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _value has no default value.
  // _index has no default value.
#line 350 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _index = omc_UnorderedMap_find(threadData, _key, _map, NULL);
#line 959 OMC_FILE

#line 351 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _value = ((_index > ((modelica_integer) 0))?omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index):_default);
#line 963 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _value;
}

DLLExport
modelica_metatype omc_UnorderedMap_getOrFail(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map)
{
  modelica_metatype _value = NULL;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _value has no default value.
#line 339 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _value = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), omc_UnorderedMap_find(threadData, _key, _map, NULL));
#line 977 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _value;
}

DLLExport
modelica_metatype omc_UnorderedMap_getSafe(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map, modelica_metatype _info)
{
  modelica_metatype _value = NULL;
  modelica_metatype tmpMeta1;
  modelica_metatype tmpMeta2;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _value has no default value.
#line 325 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if(omc_UnorderedMap_contains(threadData, _key, _map))
#line 325 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 326 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    /* Pattern-matching assignment */
#line 326 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    tmpMeta1 = omc_UnorderedMap_get(threadData, _key, _map);
#line 326 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    if (optionNone(tmpMeta1)) MMC_THROW_INTERNAL();
#line 326 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
#line 326 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _value = tmpMeta2;
#line 1005 OMC_FILE
  }
  else
  {
#line 328 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    omc_Error_addInternalError(threadData, _OMC_LIT20, _info);
#line 1011 OMC_FILE

#line 329 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    MMC_THROW_INTERNAL();
#line 1015 OMC_FILE
  }
  _return: OMC_LABEL_UNUSED
  return _value;
}

DLLExport
modelica_metatype omc_UnorderedMap_get(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map)
{
  modelica_metatype _value = NULL;
  modelica_integer _index;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _value has no default value.
  // _index has no default value.
#line 313 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _index = omc_UnorderedMap_find(threadData, _key, _map, NULL);
#line 1032 OMC_FILE

#line 314 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _value = ((_index > ((modelica_integer) 0))?mmc_mk_some(omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index)):mmc_mk_none());
#line 1036 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _value;
}

DLLExport
void omc_UnorderedMap_clear(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype tmpMeta1;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
#line 298 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_clear(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))));
#line 1049 OMC_FILE

#line 299 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
#line 299 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_push(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))), tmpMeta1);
#line 1055 OMC_FILE

#line 300 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_clear(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))));
#line 1059 OMC_FILE

#line 301 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_clear(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))));
#line 1063 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return;
}

PROTECTED_FUNCTION_STATIC modelica_metatype omc_UnorderedMap_remove_update__indices(threadData_t *threadData, modelica_metatype _bucket, modelica_integer _removedIndex)
{
  modelica_metatype _outBucket = NULL;
  modelica_metatype tmpMeta1;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _outBucket has no default value.
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    modelica_metatype __omcQ_24tmpVar1;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    modelica_metatype* tmp2;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    modelica_metatype tmpMeta3;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    modelica_metatype __omcQ_24tmpVar0;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    modelica_integer tmp4;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    modelica_metatype _i_loopVar = 0;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    modelica_metatype _i;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _i_loopVar = _bucket;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    __omcQ_24tmpVar1 = tmpMeta3; /* defaultValue */
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    tmp2 = &__omcQ_24tmpVar1;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    while(1) {
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      tmp4 = 1;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      if (!listEmpty(_i_loopVar)) {
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        _i = MMC_CAR(_i_loopVar);
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        _i_loopVar = MMC_CDR(_i_loopVar);
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        tmp4--;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      }
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      if (tmp4 == 0) {
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        __omcQ_24tmpVar0 = mmc_mk_integer(((mmc_unbox_integer(_i) > _removedIndex)?((modelica_integer) -1) + mmc_unbox_integer(_i):mmc_unbox_integer(_i)));
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        *tmp2 = mmc_mk_cons(__omcQ_24tmpVar0,0);
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        tmp2 = &MMC_CDR(*tmp2);
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      } else if (tmp4 == 1) {
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        break;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      } else {
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
        MMC_THROW_INTERNAL();
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      }
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    }
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    *tmp2 = mmc_mk_nil();
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    tmpMeta1 = __omcQ_24tmpVar1;
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  }
#line 271 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _outBucket = tmpMeta1;
#line 1141 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _outBucket;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_UnorderedMap_remove_update__indices(threadData_t *threadData, modelica_metatype _bucket, modelica_metatype _removedIndex)
{
  modelica_integer tmp1;
  modelica_metatype _outBucket = NULL;
  tmp1 = mmc_unbox_integer(_removedIndex);
  _outBucket = omc_UnorderedMap_remove_update__indices(threadData, _bucket, tmp1);
  /* skip box _outBucket; list<#Integer> */
  return _outBucket;
}

static modelica_metatype closure0_UnorderedMap_remove_update__indices(threadData_t *thData, modelica_metatype closure, modelica_metatype bucket)
{
  modelica_metatype removedIndex = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
  return boxptr_UnorderedMap_remove_update__indices(thData, bucket, removedIndex);
}
DLLExport
modelica_boolean omc_UnorderedMap_remove(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map)
{
  modelica_boolean _removed;
  modelica_integer _hash;
  modelica_integer _index;
  modelica_metatype _bucket = NULL;
  modelica_metatype tmpMeta1;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _removed has no default value.
  // _hash has no default value.
  // _index has no default value.
  // _bucket has no default value.
#line 274 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _index = omc_UnorderedMap_find(threadData, _key, _map ,&_hash);
#line 1176 OMC_FILE

#line 275 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _removed = (_index > ((modelica_integer) 0));
#line 1180 OMC_FILE

#line 278 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if((!_removed))
#line 278 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 279 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    goto _return;
#line 1188 OMC_FILE
  }

#line 283 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _bucket = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))), ((modelica_integer) 1) + _hash);
#line 1193 OMC_FILE

#line 284 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _bucket = omc_List_deleteMemberOnTrue(threadData, mmc_mk_integer(_index), _bucket, boxvar_intEq, NULL);
#line 1197 OMC_FILE

#line 285 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_updateNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))), ((modelica_integer) 1) + _hash, _bucket);
#line 1201 OMC_FILE

#line 288 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_remove(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), _index);
#line 1205 OMC_FILE

#line 289 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_remove(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index);
#line 1209 OMC_FILE

#line 292 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmpMeta1 = mmc_mk_box1(0, mmc_mk_integer(_index));
#line 292 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_Vector_apply(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))), (modelica_fnptr) mmc_mk_box2(0,closure0_UnorderedMap_remove_update__indices,tmpMeta1));
#line 1215 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _removed;
}
modelica_metatype boxptr_UnorderedMap_remove(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map)
{
  modelica_boolean _removed;
  modelica_metatype out_removed;
  _removed = omc_UnorderedMap_remove(threadData, _key, _map);
  out_removed = mmc_mk_icon(_removed);
  return out_removed;
}

DLLExport
modelica_metatype omc_UnorderedMap_addUpdate(threadData_t *threadData, modelica_metatype _key, modelica_fnptr _fn, modelica_metatype _map)
{
  modelica_metatype _value = NULL;
  modelica_integer _index;
  modelica_integer _hash;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _value has no default value.
  // _index has no default value.
  // _hash has no default value.
#line 240 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _index = omc_UnorderedMap_find(threadData, _key, _map ,&_hash);
#line 1241 OMC_FILE

#line 242 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if((_index > ((modelica_integer) 0)))
#line 242 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 243 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _value = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), mmc_mk_some(omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, mmc_mk_some(omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index)));
#line 1249 OMC_FILE

#line 244 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    omc_Vector_updateNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index, _value);
#line 1253 OMC_FILE
  }
  else
  {
#line 246 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _value = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), mmc_mk_none()) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, mmc_mk_none());
#line 1259 OMC_FILE

#line 247 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    omc_UnorderedMap_addEntry(threadData, _key, _value, _hash, _map);
#line 1263 OMC_FILE
  }
  _return: OMC_LABEL_UNUSED
  return _value;
}

DLLExport
modelica_metatype omc_UnorderedMap_tryAdd(threadData_t *threadData, modelica_metatype _key, modelica_metatype _value, modelica_metatype _map)
{
  modelica_metatype _outValue = NULL;
  modelica_integer _index;
  modelica_integer _hash;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _outValue has no default value.
  // _index has no default value.
  // _hash has no default value.
#line 209 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _index = omc_UnorderedMap_find(threadData, _key, _map ,&_hash);
#line 1282 OMC_FILE

#line 211 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if((_index > ((modelica_integer) 0)))
#line 211 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 212 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _outValue = omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index);
#line 1290 OMC_FILE
  }
  else
  {
#line 214 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    _outValue = _value;
#line 1296 OMC_FILE

#line 215 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    omc_UnorderedMap_addEntry(threadData, _key, _value, _hash, _map);
#line 1300 OMC_FILE
  }
  _return: OMC_LABEL_UNUSED
  return _outValue;
}

DLLExport
void omc_UnorderedMap_addUnique(threadData_t *threadData, modelica_metatype _key, modelica_metatype _value, modelica_metatype _map)
{
  modelica_integer _index;
  modelica_integer _hash;
  modelica_boolean tmp1;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _index has no default value.
  // _hash has no default value.
#line 193 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _index = omc_UnorderedMap_find(threadData, _key, _map ,&_hash);
#line 1318 OMC_FILE

#line 194 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  /* Pattern-matching assignment */
#line 194 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmp1 = (_index > ((modelica_integer) 0));
#line 194 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if (0 != tmp1) MMC_THROW_INTERNAL();
#line 1326 OMC_FILE

#line 195 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_UnorderedMap_addEntry(threadData, _key, _value, _hash, _map);
#line 1330 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return;
}

DLLExport
void omc_UnorderedMap_addNew(threadData_t *threadData, modelica_metatype _key, modelica_metatype _value, modelica_metatype _map)
{
  modelica_fnptr _hashfn;
  modelica_integer _hash;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  _hashfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 5)));
  // _hash has no default value.
#line 180 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _hash = modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, _key)), omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))));
#line 1346 OMC_FILE

#line 181 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  omc_UnorderedMap_addEntry(threadData, _key, _value, _hash, _map);
#line 1350 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return;
}

DLLExport
void omc_UnorderedMap_add(threadData_t *threadData, modelica_metatype _key, modelica_metatype _value, modelica_metatype _map)
{
  modelica_integer _index;
  modelica_integer _hash;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _index has no default value.
  // _hash has no default value.
#line 159 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _index = omc_UnorderedMap_find(threadData, _key, _map ,&_hash);
#line 1366 OMC_FILE

#line 161 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  if((_index > ((modelica_integer) 0)))
#line 161 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 162 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    omc_Vector_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index, _value);
#line 1374 OMC_FILE
  }
  else
  {
#line 164 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    omc_UnorderedMap_addEntry(threadData, _key, _value, _hash, _map);
#line 1380 OMC_FILE
  }
  _return: OMC_LABEL_UNUSED
  return;
}

DLLExport
modelica_metatype omc_UnorderedMap_deepCopy(threadData_t *threadData, modelica_metatype _map, modelica_fnptr _fn)
{
  modelica_metatype _outMap = NULL;
  modelica_metatype tmpMeta1;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _outMap has no default value.
#line 141 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmpMeta1 = mmc_mk_box6(3, &UnorderedMap_UNORDERED__MAP__desc, omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))), omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)))), omc_Vector_deepCopy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn)), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 6))));
#line 141 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _outMap = tmpMeta1;
#line 1398 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _outMap;
}

DLLExport
modelica_metatype omc_UnorderedMap_copy(threadData_t *threadData, modelica_metatype _map)
{
  modelica_metatype _outMap = NULL;
  modelica_metatype tmpMeta1;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _outMap has no default value.
#line 122 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmpMeta1 = mmc_mk_box6(3, &UnorderedMap_UNORDERED__MAP__desc, omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))), omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)))), omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4)))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 6))));
#line 122 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _outMap = tmpMeta1;
#line 1415 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _outMap;
}

DLLExport
modelica_metatype omc_UnorderedMap_fromLists(threadData_t *threadData, modelica_metatype _keys, modelica_metatype _values, modelica_fnptr _hash, modelica_fnptr _keyEq)
{
  modelica_metatype _map = NULL;
  modelica_integer _key_count;
  modelica_integer _bucket_count;
  modelica_metatype _v = NULL;
  modelica_metatype _rest_v = NULL;
  modelica_metatype tmpMeta1;
  modelica_metatype tmpMeta2;
  modelica_metatype tmpMeta3;
  modelica_metatype tmpMeta4;
  modelica_metatype tmpMeta5;
  modelica_metatype tmpMeta6;
  modelica_metatype tmpMeta7;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _map has no default value.
  // _key_count has no default value.
  // _bucket_count has no default value.
  // _v has no default value.
  _rest_v = _values;
#line 100 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _key_count = listLength(_keys);
#line 1444 OMC_FILE

#line 101 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _bucket_count = omc_Util_nextPrime(threadData, _key_count);
#line 1448 OMC_FILE

#line 103 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
#line 103 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmpMeta2 = mmc_mk_box6(3, &UnorderedMap_UNORDERED__MAP__desc, omc_Vector_newFill(threadData, _bucket_count, tmpMeta1), omc_Vector_new(threadData, _key_count), omc_Vector_new(threadData, _key_count), ((modelica_fnptr) _hash), ((modelica_fnptr) _keyEq));
#line 103 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _map = tmpMeta2;
#line 1456 OMC_FILE

#line 111 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  {
#line 111 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    modelica_metatype _k;
#line 111 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    for (tmpMeta3 = _keys; !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
#line 111 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
    {
#line 111 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      _k = MMC_CAR(tmpMeta3);
#line 112 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      /* Pattern-matching assignment */
#line 112 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      tmpMeta4 = _rest_v;
#line 112 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      if (listEmpty(tmpMeta4)) MMC_THROW_INTERNAL();
#line 112 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      tmpMeta5 = MMC_CAR(tmpMeta4);
#line 112 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      tmpMeta6 = MMC_CDR(tmpMeta4);
#line 112 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      _v = tmpMeta5;
#line 112 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      _rest_v = tmpMeta6;
#line 1482 OMC_FILE

#line 113 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
      omc_UnorderedMap_add(threadData, _k, _v, _map);
#line 1486 OMC_FILE
    }
  }
  _return: OMC_LABEL_UNUSED
  return _map;
}

DLLExport
modelica_metatype omc_UnorderedMap_new(threadData_t *threadData, modelica_fnptr _hash, modelica_fnptr _keyEq, modelica_integer _bucketCount)
{
  modelica_metatype _map = NULL;
  modelica_metatype tmpMeta1;
  modelica_metatype tmpMeta2;
  MMC_SO();
  _tailrecursive: OMC_LABEL_UNUSED
  // _map has no default value.
#line 78 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
#line 78 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  tmpMeta2 = mmc_mk_box6(3, &UnorderedMap_UNORDERED__MAP__desc, omc_Vector_newFill(threadData, _bucketCount, tmpMeta1), omc_Vector_new(threadData, ((modelica_integer) 0)), omc_Vector_new(threadData, ((modelica_integer) 0)), ((modelica_fnptr) _hash), ((modelica_fnptr) _keyEq));
#line 78 "/home/kab/workspace/2_OM_Build/OMCompiler/Compiler/Util/UnorderedMap.mo"
  _map = tmpMeta2;
#line 1508 OMC_FILE
  _return: OMC_LABEL_UNUSED
  return _map;
}
modelica_metatype boxptr_UnorderedMap_new(threadData_t *threadData, modelica_fnptr _hash, modelica_fnptr _keyEq, modelica_metatype _bucketCount)
{
  modelica_integer tmp1;
  modelica_metatype _map = NULL;
  tmp1 = mmc_unbox_integer(_bucketCount);
  _map = omc_UnorderedMap_new(threadData, _hash, _keyEq, tmp1);
  /* skip box _map; UnorderedMap<polymorphic<K>,polymorphic<V>> */
  return _map;
}

