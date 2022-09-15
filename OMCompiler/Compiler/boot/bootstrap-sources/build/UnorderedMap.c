#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "UnorderedMap.c"
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
modelica_integer _h;
modelica_fnptr _hashfn;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_buckets = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)));
omc_Vector_push(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), _key);
omc_Vector_push(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _value);
if((omc_UnorderedMap_loadFactor(threadData, _map) > 1.0))
{
omc_UnorderedMap_rehash(threadData, _map);
}
else
{
tmpMeta1 = mmc_mk_cons(mmc_mk_integer(omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))))), omc_Vector_get(threadData, _buckets, ((modelica_integer) 1) + _hash));
omc_Vector_update(threadData, _buckets, ((modelica_integer) 1) + _hash, tmpMeta1);
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
_hashfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 5)));
_eqfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 6)));
_hash = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))), _key, mmc_mk_integer(omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, _key, mmc_mk_integer(omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))))));
if((omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))) > ((modelica_integer) 0)))
{
_bucket = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))), ((modelica_integer) 1) + _hash);
{
modelica_metatype _i;
for (tmpMeta1 = _bucket; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_i = MMC_CAR(tmpMeta1);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqfn), 2))), _key, omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), mmc_unbox_integer(_i))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqfn), 1)))) (threadData, _key, omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), mmc_unbox_integer(_i)))))
{
_index = mmc_unbox_integer(_i);
break;
}
}
}
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
_keys = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)));
_values = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4)));
_sz = omc_Vector_size(threadData, _keys);
_io = omc_IOStream_create(threadData, _OMC_LIT0, _OMC_LIT1);
_io = omc_IOStream_append(threadData, _io, _OMC_LIT2);
if((_sz > ((modelica_integer) 0)))
{
_io = omc_IOStream_append(threadData, _io, _OMC_LIT3);
_io = omc_IOStream_append(threadData, _io, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 2))), omc_Vector_getNoBounds(threadData, _keys, ((modelica_integer) 1))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 1)))) (threadData, omc_Vector_getNoBounds(threadData, _keys, ((modelica_integer) 1))));
_io = omc_IOStream_append(threadData, _io, _OMC_LIT4);
_io = omc_IOStream_append(threadData, _io, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 2))), omc_Vector_getNoBounds(threadData, _values, ((modelica_integer) 1))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 1)))) (threadData, omc_Vector_getNoBounds(threadData, _values, ((modelica_integer) 1))));
_io = omc_IOStream_append(threadData, _io, _OMC_LIT5);
tmp1 = ((modelica_integer) 2); tmp2 = 1; tmp3 = _sz;
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 2); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_io = omc_IOStream_append(threadData, _io, _OMC_LIT6);
_io = omc_IOStream_append(threadData, _io, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 2))), omc_Vector_getNoBounds(threadData, _keys, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 1)))) (threadData, omc_Vector_getNoBounds(threadData, _keys, _i)));
_io = omc_IOStream_append(threadData, _io, _OMC_LIT4);
_io = omc_IOStream_append(threadData, _io, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 2))), omc_Vector_getNoBounds(threadData, _values, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 1)))) (threadData, omc_Vector_getNoBounds(threadData, _values, _i)));
_io = omc_IOStream_append(threadData, _io, _OMC_LIT5);
}
}
}
_io = omc_IOStream_append(threadData, _io, _OMC_LIT7);
_str = omc_IOStream_string(threadData, _io);
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
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_strl = tmpMeta1;
_keys = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)));
_values = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4)));
tmp7 = omc_Vector_size(threadData, _keys); tmp8 = ((modelica_integer) -1); tmp9 = ((modelica_integer) 1);
if(!(((tmp8 > 0) && (tmp7 > tmp9)) || ((tmp8 < 0) && (tmp7 < tmp9))))
{
modelica_integer _i;
for(_i = omc_Vector_size(threadData, _keys); in_range_integer(_i, tmp7, tmp9); _i += tmp8)
{
tmpMeta3 = stringAppend(_OMC_LIT9,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 2))), omc_Vector_get(threadData, _keys, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyStringFn), 1)))) (threadData, omc_Vector_get(threadData, _keys, _i)));
tmpMeta4 = stringAppend(tmpMeta3,_OMC_LIT10);
tmpMeta5 = stringAppend(tmpMeta4,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 2))), omc_Vector_get(threadData, _values, _i)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_valueStringFn), 1)))) (threadData, omc_Vector_get(threadData, _values, _i)));
tmpMeta6 = stringAppend(tmpMeta5,_OMC_LIT11);
tmpMeta2 = mmc_mk_cons(tmpMeta6, _strl);
_strl = tmpMeta2;
}
}
_str = stringDelimitList(_strl, _delimiter);
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
_hashfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 5)));
omc_Vector_clear(threadData, _buckets);
_bucket_count = omc_Util_nextPrime(threadData, (((modelica_integer) 2)) * (omc_Vector_size(threadData, _keys)));
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Vector_resize(threadData, _buckets, _bucket_count, tmpMeta1);
tmp3 = ((modelica_integer) 1); tmp4 = 1; tmp5 = omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))));
if(!(((tmp4 > 0) && (tmp3 > tmp5)) || ((tmp4 < 0) && (tmp3 < tmp5))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp3, tmp5); _i += tmp4)
{
_bucket_id = ((modelica_integer) 1) + mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))), omc_Vector_get(threadData, _keys, _i), mmc_mk_integer(_bucket_count)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, omc_Vector_get(threadData, _keys, _i), mmc_mk_integer(_bucket_count)));
tmpMeta2 = mmc_mk_cons(mmc_mk_integer(_i), omc_Vector_getNoBounds(threadData, _buckets, _bucket_id));
omc_Vector_updateNoBounds(threadData, _buckets, _bucket_id, tmpMeta2);
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
_res = omc_Vector_none(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn));
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
_res = omc_Vector_any(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn));
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
_res = omc_Vector_all(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn));
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
omc_Vector_apply(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn));
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
_new_values = omc_Vector_map(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn), 1);
tmpMeta1 = mmc_mk_box6(3, &UnorderedMap_UNORDERED__MAP__desc, omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))), omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)))), _new_values, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 6))));
_outMap = tmpMeta1;
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
_arg = omc_Vector_fold(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn), _arg);
_return: OMC_LABEL_UNUSED
return _arg;
}
DLLExport
modelica_metatype omc_UnorderedMap_valueVector(threadData_t *threadData, modelica_metatype _map)
{
modelica_metatype _values = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_values = omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))));
_return: OMC_LABEL_UNUSED
return _values;
}
DLLExport
modelica_metatype omc_UnorderedMap_keyVector(threadData_t *threadData, modelica_metatype _map)
{
modelica_metatype _keys = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_keys = omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))));
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
_keys = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)));
_values = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4)));
_sz = omc_Vector_size(threadData, _keys);
_entries = omc_Vector_new(threadData, _sz);
tmp2 = ((modelica_integer) 1); tmp3 = 1; tmp4 = _sz;
if(!(((tmp3 > 0) && (tmp2 > tmp4)) || ((tmp3 < 0) && (tmp2 < tmp4))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp2, tmp4); _i += tmp3)
{
tmpMeta1 = mmc_mk_box2(0, omc_Vector_getNoBounds(threadData, _keys, _i), omc_Vector_getNoBounds(threadData, _values, _i));
omc_Vector_updateNoBounds(threadData, _entries, _i, tmpMeta1);
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
_values = omc_Vector_toArray(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))));
_return: OMC_LABEL_UNUSED
return _values;
}
DLLExport
modelica_metatype omc_UnorderedMap_keyArray(threadData_t *threadData, modelica_metatype _map)
{
modelica_metatype _keys = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_keys = omc_Vector_toArray(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))));
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
_keys = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)));
_values = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4)));
_t = _t;
_sz = omc_Vector_size(threadData, _keys);
_entries = arrayCreateNoInit(_sz, _t);
tmp2 = ((modelica_integer) 1); tmp3 = 1; tmp4 = _sz;
if(!(((tmp3 > 0) && (tmp2 > tmp4)) || ((tmp3 < 0) && (tmp2 < tmp4))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp2, tmp4); _i += tmp3)
{
tmpMeta1 = mmc_mk_box2(0, omc_Vector_getNoBounds(threadData, _keys, _i), omc_Vector_getNoBounds(threadData, _values, _i));
arrayUpdateNoBoundsChecking(_entries, _i, tmpMeta1);
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
_values = omc_Vector_toList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))));
_return: OMC_LABEL_UNUSED
return _values;
}
DLLExport
modelica_metatype omc_UnorderedMap_keyList(threadData_t *threadData, modelica_metatype _map)
{
modelica_metatype _keys = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_keys = omc_Vector_toList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))));
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
_keys = omc_UnorderedMap_keyList(threadData, _map);
_values = omc_UnorderedMap_valueList(threadData, _map);
if((listLength(_keys) == listLength(_values)))
{
_lst = omc_List_zip(threadData, _keys, _values);
}
else
{
tmpMeta2 = stringAppend(_OMC_LIT17,intString(listLength(_keys)));
tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT18);
tmpMeta4 = stringAppend(tmpMeta3,intString(listLength(_values)));
tmpMeta5 = stringAppend(tmpMeta4,_OMC_LIT19);
tmpMeta1 = mmc_mk_cons(tmpMeta5, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT16, tmpMeta1);
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
_value = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index);
_return: OMC_LABEL_UNUSED
return _value;
}
modelica_metatype boxptr_UnorderedMap_valueAt(threadData_t *threadData, modelica_metatype _map, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_metatype _value = NULL;
tmp1 = mmc_unbox_integer(_index);
_value = omc_UnorderedMap_valueAt(threadData, _map, tmp1);
return _value;
}
DLLExport
modelica_metatype omc_UnorderedMap_keyAt(threadData_t *threadData, modelica_metatype _map, modelica_integer _index)
{
modelica_metatype _key = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_key = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), _index);
_return: OMC_LABEL_UNUSED
return _key;
}
modelica_metatype boxptr_UnorderedMap_keyAt(threadData_t *threadData, modelica_metatype _map, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_metatype _key = NULL;
tmp1 = mmc_unbox_integer(_index);
_key = omc_UnorderedMap_keyAt(threadData, _map, tmp1);
return _key;
}
DLLExport
modelica_metatype omc_UnorderedMap_firstKey(threadData_t *threadData, modelica_metatype _map)
{
modelica_metatype _key = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_key = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), ((modelica_integer) 1));
_return: OMC_LABEL_UNUSED
return _key;
}
DLLExport
modelica_metatype omc_UnorderedMap_first(threadData_t *threadData, modelica_metatype _map)
{
modelica_metatype _value = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_value = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_integer) 1));
_return: OMC_LABEL_UNUSED
return _value;
}
DLLExport
modelica_boolean omc_UnorderedMap_contains(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map)
{
modelica_boolean _res;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = (omc_UnorderedMap_find(threadData, _key, _map, NULL) > ((modelica_integer) 0));
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
_index = omc_UnorderedMap_find(threadData, _key, _map, NULL);
_outKey = ((_index > ((modelica_integer) 0))?mmc_mk_some(omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), _index)):mmc_mk_none());
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
_index = omc_UnorderedMap_find(threadData, _key, _map, NULL);
_value = ((_index > ((modelica_integer) 0))?omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index):_default);
_return: OMC_LABEL_UNUSED
return _value;
}
DLLExport
modelica_metatype omc_UnorderedMap_getOrFail(threadData_t *threadData, modelica_metatype _key, modelica_metatype _map)
{
modelica_metatype _value = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_value = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), omc_UnorderedMap_find(threadData, _key, _map, NULL));
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
if(omc_UnorderedMap_contains(threadData, _key, _map))
{
tmpMeta1 = omc_UnorderedMap_get(threadData, _key, _map);
if (optionNone(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
_value = tmpMeta2;
}
else
{
omc_Error_addInternalError(threadData, _OMC_LIT20, _info);
MMC_THROW_INTERNAL();
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
_index = omc_UnorderedMap_find(threadData, _key, _map, NULL);
_value = ((_index > ((modelica_integer) 0))?mmc_mk_some(omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index)):mmc_mk_none());
_return: OMC_LABEL_UNUSED
return _value;
}
DLLExport
void omc_UnorderedMap_clear(threadData_t *threadData, modelica_metatype _map)
{
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_Vector_clear(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))));
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Vector_push(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))), tmpMeta1);
omc_Vector_clear(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))));
omc_Vector_clear(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))));
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_UnorderedMap_remove_update__indices(threadData_t *threadData, modelica_metatype _bucket, modelica_integer _removedIndex)
{
modelica_metatype _outBucket = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp4;
modelica_metatype _i_loopVar = 0;
modelica_metatype _i;
_i_loopVar = _bucket;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar1;
while(1) {
tmp4 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar0 = mmc_mk_integer(((mmc_unbox_integer(_i) > _removedIndex)?((modelica_integer) -1) + mmc_unbox_integer(_i):mmc_unbox_integer(_i)));
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
_outBucket = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outBucket;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_UnorderedMap_remove_update__indices(threadData_t *threadData, modelica_metatype _bucket, modelica_metatype _removedIndex)
{
modelica_integer tmp1;
modelica_metatype _outBucket = NULL;
tmp1 = mmc_unbox_integer(_removedIndex);
_outBucket = omc_UnorderedMap_remove_update__indices(threadData, _bucket, tmp1);
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
_index = omc_UnorderedMap_find(threadData, _key, _map ,&_hash);
_removed = (_index > ((modelica_integer) 0));
if((!_removed))
{
goto _return;
}
_bucket = omc_Vector_get(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))), ((modelica_integer) 1) + _hash);
_bucket = omc_List_deleteMemberOnTrue(threadData, mmc_mk_integer(_index), _bucket, boxvar_intEq, NULL);
omc_Vector_updateNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))), ((modelica_integer) 1) + _hash, _bucket);
omc_Vector_remove(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3))), _index);
omc_Vector_remove(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index);
tmpMeta1 = mmc_mk_box1(0, mmc_mk_integer(_index));
omc_Vector_apply(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2))), (modelica_fnptr) mmc_mk_box2(0,closure0_UnorderedMap_remove_update__indices,tmpMeta1));
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
_index = omc_UnorderedMap_find(threadData, _key, _map ,&_hash);
if((_index > ((modelica_integer) 0)))
{
_value = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), mmc_mk_some(omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, mmc_mk_some(omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index)));
omc_Vector_updateNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index, _value);
}
else
{
_value = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), mmc_mk_none()) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, mmc_mk_none());
omc_UnorderedMap_addEntry(threadData, _key, _value, _hash, _map);
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
_index = omc_UnorderedMap_find(threadData, _key, _map ,&_hash);
if((_index > ((modelica_integer) 0)))
{
_outValue = omc_Vector_getNoBounds(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index);
}
else
{
_outValue = _value;
omc_UnorderedMap_addEntry(threadData, _key, _value, _hash, _map);
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
_index = omc_UnorderedMap_find(threadData, _key, _map ,&_hash);
tmp1 = (_index > ((modelica_integer) 0));
if (0 != tmp1) MMC_THROW_INTERNAL();
omc_UnorderedMap_addEntry(threadData, _key, _value, _hash, _map);
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
_hash = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))), _key, mmc_mk_integer(omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, _key, mmc_mk_integer(omc_Vector_size(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))))));
omc_UnorderedMap_addEntry(threadData, _key, _value, _hash, _map);
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
_index = omc_UnorderedMap_find(threadData, _key, _map ,&_hash);
if((_index > ((modelica_integer) 0)))
{
omc_Vector_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), _index, _value);
}
else
{
omc_UnorderedMap_addEntry(threadData, _key, _value, _hash, _map);
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
tmpMeta1 = mmc_mk_box6(3, &UnorderedMap_UNORDERED__MAP__desc, omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))), omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)))), omc_Vector_deepCopy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4))), ((modelica_fnptr) _fn)), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 6))));
_outMap = tmpMeta1;
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
tmpMeta1 = mmc_mk_box6(3, &UnorderedMap_UNORDERED__MAP__desc, omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 2)))), omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 3)))), omc_Vector_copy(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 4)))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_map), 6))));
_outMap = tmpMeta1;
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
_rest_v = _values;
_key_count = listLength(_keys);
_bucket_count = omc_Util_nextPrime(threadData, _key_count);
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta2 = mmc_mk_box6(3, &UnorderedMap_UNORDERED__MAP__desc, omc_Vector_newFill(threadData, _bucket_count, tmpMeta1), omc_Vector_new(threadData, _key_count), omc_Vector_new(threadData, _key_count), ((modelica_fnptr) _hash), ((modelica_fnptr) _keyEq));
_map = tmpMeta2;
{
modelica_metatype _k;
for (tmpMeta3 = _keys; !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
{
_k = MMC_CAR(tmpMeta3);
tmpMeta4 = _rest_v;
if (listEmpty(tmpMeta4)) MMC_THROW_INTERNAL();
tmpMeta5 = MMC_CAR(tmpMeta4);
tmpMeta6 = MMC_CDR(tmpMeta4);
_v = tmpMeta5;
_rest_v = tmpMeta6;
omc_UnorderedMap_add(threadData, _k, _v, _map);
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
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta2 = mmc_mk_box6(3, &UnorderedMap_UNORDERED__MAP__desc, omc_Vector_newFill(threadData, _bucketCount, tmpMeta1), omc_Vector_new(threadData, ((modelica_integer) 0)), omc_Vector_new(threadData, ((modelica_integer) 0)), ((modelica_fnptr) _hash), ((modelica_fnptr) _keyEq));
_map = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _map;
}
modelica_metatype boxptr_UnorderedMap_new(threadData_t *threadData, modelica_fnptr _hash, modelica_fnptr _keyEq, modelica_metatype _bucketCount)
{
modelica_integer tmp1;
modelica_metatype _map = NULL;
tmp1 = mmc_unbox_integer(_bucketCount);
_map = omc_UnorderedMap_new(threadData, _hash, _keyEq, tmp1);
return _map;
}
