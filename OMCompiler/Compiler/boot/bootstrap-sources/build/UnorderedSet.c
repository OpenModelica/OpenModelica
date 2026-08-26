#include "omc_simulation_settings.h"
#include "UnorderedSet.h"
#define _OMC_LIT0_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,1,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#include "util/modelica.h"
#include "UnorderedSet_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_UnorderedSet_extractFromLst(threadData_t *threadData, modelica_metatype _lst, modelica_fnptr _func, modelica_metatype *out_rest);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_extractFromLst,2,0) {(void*) boxptr_UnorderedSet_extractFromLst,0}};
#define boxvar_UnorderedSet_extractFromLst MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_extractFromLst)
PROTECTED_FUNCTION_STATIC void omc_UnorderedSet_addKey(threadData_t *threadData, modelica_metatype _key, modelica_integer _hash, modelica_metatype _set);
PROTECTED_FUNCTION_STATIC void boxptr_UnorderedSet_addKey(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hash, modelica_metatype _set);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_addKey,2,0) {(void*) boxptr_UnorderedSet_addKey,0}};
#define boxvar_UnorderedSet_addKey MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_addKey)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_UnorderedSet_find(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set, modelica_integer *out_hash);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_UnorderedSet_find(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set, modelica_metatype *out_hash);
static const MMC_DEFSTRUCTLIT(boxvar_lit_UnorderedSet_find,2,0) {(void*) boxptr_UnorderedSet_find,0}};
#define boxvar_UnorderedSet_find MMC_REFSTRUCTLIT(boxvar_lit_UnorderedSet_find)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_UnorderedSet_extractFromLst(threadData_t *threadData, modelica_metatype _lst, modelica_fnptr _func, modelica_metatype *out_rest)
{
modelica_metatype _single = NULL;
modelica_metatype _rest = NULL;
modelica_metatype tmpMeta1;
modelica_integer _size;
modelica_metatype _tmp_lst = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_rest = tmpMeta1;
tmpMeta2 = _lst;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_single = tmpMeta3;
_tmp_lst = tmpMeta4;
_size = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_single), 3)))));
{
modelica_metatype _tmp;
for (tmpMeta5 = _tmp_lst; !listEmpty(tmpMeta5); tmpMeta5=MMC_CDR(tmpMeta5))
{
_tmp = MMC_CAR(tmpMeta5);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_tmp), 3)))), mmc_mk_integer(_size)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_tmp), 3)))), mmc_mk_integer(_size))))
{
_size = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_tmp), 3)))));
tmpMeta6 = mmc_mk_cons(_single, _rest);
_rest = tmpMeta6;
_single = _tmp;
}
else
{
tmpMeta7 = mmc_mk_cons(_tmp, _rest);
_rest = tmpMeta7;
}
}
}
_return: OMC_LABEL_UNUSED
if (out_rest) { *out_rest = _rest; }
return _single;
}
PROTECTED_FUNCTION_STATIC void omc_UnorderedSet_addKey(threadData_t *threadData, modelica_metatype _key, modelica_integer _hash, modelica_metatype _set)
{
modelica_metatype _buckets = NULL;
modelica_integer _h;
modelica_fnptr _hashfn;
modelica_metatype tmpMeta1;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((omc_UnorderedSet_loadFactor(threadData, _set) > 1.0))
{
omc_UnorderedSet_rehash(threadData, _set);
_hashfn = (modelica_fnptr) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 4)));
_buckets = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2))));
_h = modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, _key)), arrayLength(_buckets));
}
else
{
_buckets = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2))));
_h = _hash;
}
tmpMeta1 = mmc_mk_cons(_key, arrayGet(_buckets, ((modelica_integer) 1) + _h));
arrayUpdate(_buckets, ((modelica_integer) 1) + _h, tmpMeta1);
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))), mmc_mk_integer(((modelica_integer) 1) + (mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))))))));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
PROTECTED_FUNCTION_STATIC void boxptr_UnorderedSet_addKey(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hash, modelica_metatype _set)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_hash);
omc_UnorderedSet_addKey(threadData, _key, tmp1, _set);
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_UnorderedSet_find(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set, modelica_integer *out_hash)
{
modelica_metatype _outKey = NULL;
modelica_integer _hash;
modelica_fnptr _hashfn;
modelica_fnptr _eqfn;
modelica_metatype _buckets = NULL;
modelica_metatype _bucket = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outKey = mmc_mk_none();
_hashfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 4)));
_eqfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 5)));
_buckets = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2))));
_hash = modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, _key)), arrayLength(_buckets));
_bucket = arrayGet(_buckets, ((modelica_integer) 1) + _hash);
{
modelica_metatype _k;
for (tmpMeta1 = _bucket; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_k = MMC_CAR(tmpMeta1);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqfn), 2))), _k, _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqfn), 1)))) (threadData, _k, _key)))
{
_outKey = mmc_mk_some(_k);
break;
}
}
}
_return: OMC_LABEL_UNUSED
if (out_hash) { *out_hash = _hash; }
return _outKey;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_UnorderedSet_find(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set, modelica_metatype *out_hash)
{
modelica_integer _hash;
modelica_metatype _outKey = NULL;
_outKey = omc_UnorderedSet_find(threadData, _key, _set, &_hash);
if (out_hash) { *out_hash = mmc_mk_icon(_hash); }
return _outKey;
}
DLLDirection
modelica_boolean omc_UnorderedSet_isDisjoint(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2)
{
modelica_boolean _b;
modelica_metatype _set_small = NULL;
modelica_metatype _set_big = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = 1;
if((mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 3))))) > mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set2), 3)))))))
{
_set_small = _set2;
_set_big = _set1;
}
else
{
_set_small = _set1;
_set_big = _set2;
}
if((!omc_UnorderedSet_isEmpty(threadData, _set_small)))
{
{
modelica_metatype _buckets;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set_small), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_buckets = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _buckets; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
if(omc_UnorderedSet_contains(threadData, _k, _set_big))
{
_b = 0;
goto _return;
}
}
}
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _b;
}
modelica_metatype boxptr_UnorderedSet_isDisjoint(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_UnorderedSet_isDisjoint(threadData, _set1, _set2);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLDirection
modelica_metatype omc_UnorderedSet_sym__difference(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2)
{
modelica_metatype _set = NULL;
modelica_metatype _acc = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_integer tmp14;
modelica_integer tmp15;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_acc = tmpMeta1;
if((!omc_UnorderedSet_isEmpty(threadData, _set1)))
{
{
modelica_metatype _b;
for (tmpMeta2 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 2)))), tmp8 = arrayLength(tmpMeta2), tmp7 = 1; tmp7 <= tmp8; tmp7++)
{
_b = arrayGet(tmpMeta2,tmp7);
{
modelica_metatype _k;
for (tmpMeta3 = _b; !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
{
_k = MMC_CAR(tmpMeta3);
if((!omc_UnorderedSet_contains(threadData, _k, _set2)))
{
tmpMeta4 = mmc_mk_cons(_k, _acc);
_acc = tmpMeta4;
}
}
}
}
}
}
if((!omc_UnorderedSet_isEmpty(threadData, _set2)))
{
{
modelica_metatype _b;
for (tmpMeta9 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set2), 2)))), tmp15 = arrayLength(tmpMeta9), tmp14 = 1; tmp14 <= tmp15; tmp14++)
{
_b = arrayGet(tmpMeta9,tmp14);
{
modelica_metatype _k;
for (tmpMeta10 = _b; !listEmpty(tmpMeta10); tmpMeta10=MMC_CDR(tmpMeta10))
{
_k = MMC_CAR(tmpMeta10);
if((!omc_UnorderedSet_contains(threadData, _k, _set1)))
{
tmpMeta11 = mmc_mk_cons(_k, _acc);
_acc = tmpMeta11;
}
}
}
}
}
}
_set = omc_UnorderedSet_fromList(threadData, _acc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 5))));
_return: OMC_LABEL_UNUSED
return _set;
}
DLLDirection
modelica_metatype omc_UnorderedSet_difference(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2)
{
modelica_metatype _set = NULL;
modelica_metatype _acc = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_integer tmp8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_acc = tmpMeta1;
if((!omc_UnorderedSet_isEmpty(threadData, _set1)))
{
{
modelica_metatype _b;
for (tmpMeta2 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 2)))), tmp8 = arrayLength(tmpMeta2), tmp7 = 1; tmp7 <= tmp8; tmp7++)
{
_b = arrayGet(tmpMeta2,tmp7);
{
modelica_metatype _k;
for (tmpMeta3 = _b; !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
{
_k = MMC_CAR(tmpMeta3);
if((!omc_UnorderedSet_contains(threadData, _k, _set2)))
{
tmpMeta4 = mmc_mk_cons(_k, _acc);
_acc = tmpMeta4;
}
}
}
}
}
}
_set = omc_UnorderedSet_fromList(threadData, _acc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 5))));
_return: OMC_LABEL_UNUSED
return _set;
}
DLLDirection
modelica_boolean omc_UnorderedSet_equal__list(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _hashFunc, modelica_fnptr _keyEqFunc)
{
modelica_boolean _b;
modelica_metatype _set1 = NULL;
modelica_metatype _set2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = 0;
_set1 = omc_UnorderedSet_fromList(threadData, _inList1, ((modelica_fnptr) _hashFunc), ((modelica_fnptr) _keyEqFunc));
_set2 = omc_UnorderedSet_fromList(threadData, _inList2, ((modelica_fnptr) _hashFunc), ((modelica_fnptr) _keyEqFunc));
if((mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 3))))) != mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set2), 3)))))))
{
goto _return;
}
{
modelica_metatype _k;
for (tmpMeta1 = _inList1; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_k = MMC_CAR(tmpMeta1);
if((!omc_UnorderedSet_contains(threadData, _k, _set2)))
{
goto _return;
}
}
}
_b = 1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _b;
}
modelica_metatype boxptr_UnorderedSet_equal__list(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _hashFunc, modelica_fnptr _keyEqFunc)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_UnorderedSet_equal__list(threadData, _inList1, _inList2, _hashFunc, _keyEqFunc);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLDirection
modelica_metatype omc_UnorderedSet_difference__list(threadData_t *threadData, modelica_metatype _inList1, modelica_metatype _inList2, modelica_fnptr _hashFunc, modelica_fnptr _keyEqFunc)
{
modelica_metatype _acc = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _set2 = NULL;
modelica_metatype _lst1 = NULL;
modelica_metatype _lst2 = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_acc = tmpMeta1;
_lst1 = _inList1;
_lst2 = _inList2;
while(1)
{
if(!((!(listEmpty(_lst1) || listEmpty(_lst2))) && mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqFunc), 2))), listHead(_lst1), listHead(_lst2)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqFunc), 1)))) (threadData, listHead(_lst1), listHead(_lst2))))) break;
_lst1 = listRest(_lst1);
_lst2 = listRest(_lst2);
}
if((listEmpty(_lst1) || listEmpty(_lst2)))
{
_acc = _lst1;
goto _return;
}
_set2 = omc_UnorderedSet_fromList(threadData, _lst2, ((modelica_fnptr) _hashFunc), ((modelica_fnptr) _keyEqFunc));
{
modelica_metatype _k;
for (tmpMeta2 = _lst1; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
if((!omc_UnorderedSet_contains(threadData, _k, _set2)))
{
tmpMeta3 = mmc_mk_cons(_k, _acc);
_acc = tmpMeta3;
}
}
}
_return: OMC_LABEL_UNUSED
return _acc;
}
static modelica_metatype closure0_UnorderedSet_contains(threadData_t *thData, modelica_metatype closure, modelica_metatype set)
{
modelica_metatype key = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_UnorderedSet_contains(thData, key, set);
}
DLLDirection
modelica_metatype omc_UnorderedSet_intersection__list(threadData_t *threadData, modelica_metatype _set_lst, modelica_fnptr _hashFunc, modelica_fnptr _keyEqFunc)
{
modelica_metatype _set = NULL;
modelica_metatype _set_small = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _acc = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
modelica_integer tmp9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_acc = tmpMeta1;
if((!listEmpty(_set_lst)))
{
_set_small = omc_UnorderedSet_extractFromLst(threadData, _set_lst, boxvar_intLt ,&_rest);
{
modelica_metatype _b;
for (tmpMeta2 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set_small), 2)))), tmp9 = arrayLength(tmpMeta2), tmp8 = 1; tmp8 <= tmp9; tmp8++)
{
_b = arrayGet(tmpMeta2,tmp8);
{
modelica_metatype _k;
for (tmpMeta3 = _b; !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
{
_k = MMC_CAR(tmpMeta3);
tmpMeta4 = mmc_mk_box1(0, _k);
if(omc_List_all(threadData, _rest, (modelica_fnptr) mmc_mk_box2(0,closure0_UnorderedSet_contains,tmpMeta4)))
{
tmpMeta5 = mmc_mk_cons(_k, _acc);
_acc = tmpMeta5;
}
}
}
}
}
}
_set = omc_UnorderedSet_fromList(threadData, _acc, ((modelica_fnptr) _hashFunc), ((modelica_fnptr) _keyEqFunc));
_return: OMC_LABEL_UNUSED
return _set;
}
DLLDirection
modelica_metatype omc_UnorderedSet_intersection(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2)
{
modelica_metatype _set = NULL;
modelica_metatype _set_small = NULL;
modelica_metatype _set_big = NULL;
modelica_metatype _acc = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_integer tmp8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_acc = tmpMeta1;
if((mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 3))))) > mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set2), 3)))))))
{
_set_small = _set2;
_set_big = _set1;
}
else
{
_set_small = _set1;
_set_big = _set2;
}
if((!omc_UnorderedSet_isEmpty(threadData, _set_small)))
{
{
modelica_metatype _b;
for (tmpMeta2 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set_small), 2)))), tmp8 = arrayLength(tmpMeta2), tmp7 = 1; tmp7 <= tmp8; tmp7++)
{
_b = arrayGet(tmpMeta2,tmp7);
{
modelica_metatype _k;
for (tmpMeta3 = _b; !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
{
_k = MMC_CAR(tmpMeta3);
if(omc_UnorderedSet_contains(threadData, _k, _set_big))
{
tmpMeta4 = mmc_mk_cons(_k, _acc);
_acc = tmpMeta4;
}
}
}
}
}
}
_set = omc_UnorderedSet_fromList(threadData, _acc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 5))));
_return: OMC_LABEL_UNUSED
return _set;
}
DLLDirection
modelica_metatype omc_UnorderedSet_merge(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fset1, modelica_metatype _set2)
{
modelica_metatype _set1 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_set1 = __omcQ_24in_5Fset1;
if(omc_UnorderedSet_isEmpty(threadData, _set2))
{
goto _return;
}
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set2), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_b = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _b; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
omc_UnorderedSet_add(threadData, _k, _set1);
}
}
}
}
_return: OMC_LABEL_UNUSED
return _set1;
}
DLLDirection
modelica_metatype omc_UnorderedSet_union__list(threadData_t *threadData, modelica_metatype _set_lst, modelica_fnptr _hashFunc, modelica_fnptr _keyEqFunc)
{
modelica_metatype _set = NULL;
modelica_metatype _rest = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(listEmpty(_set_lst))
{
_set = omc_UnorderedSet_new(threadData, ((modelica_fnptr) _hashFunc), ((modelica_fnptr) _keyEqFunc), ((modelica_integer) 13));
}
else
{
_set = omc_UnorderedSet_extractFromLst(threadData, _set_lst, boxvar_intGt ,&_rest);
{
modelica_metatype _tmp;
for (tmpMeta1 = _rest; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_tmp = MMC_CAR(tmpMeta1);
_set = omc_UnorderedSet_union(threadData, _set, _tmp);
}
}
}
_return: OMC_LABEL_UNUSED
return _set;
}
DLLDirection
modelica_metatype omc_UnorderedSet_union(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2)
{
modelica_metatype _set = NULL;
modelica_integer _sz1;
modelica_integer _sz2;
modelica_integer _small_sz;
modelica_metatype _small_set = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sz1 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 3)))));
_sz2 = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set2), 3)))));
if((_sz1 > _sz2))
{
_set = _set1;
_small_set = _set2;
_small_sz = _sz2;
}
else
{
_set = _set2;
_small_set = _set1;
_small_sz = _sz1;
}
if((_small_sz > ((modelica_integer) 0)))
{
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_small_set), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_b = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _b; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
omc_UnorderedSet_add(threadData, _k, _set);
}
}
}
}
}
_return: OMC_LABEL_UNUSED
return _set;
}
DLLDirection
modelica_metatype omc_UnorderedSet_unique__list(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _hashFunc, modelica_fnptr _keyEqFunc)
{
modelica_metatype _outList = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outList = (omc_List_hasSeveralElements(threadData, _inList)?omc_UnorderedSet_toList(threadData, omc_UnorderedSet_fromList(threadData, _inList, ((modelica_fnptr) _hashFunc), ((modelica_fnptr) _keyEqFunc))):_inList);
_return: OMC_LABEL_UNUSED
return _outList;
}
DLLDirection
void omc_UnorderedSet_dump(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _stringFn)
{
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
fputs(MMC_STRINGDATA(omc_UnorderedSet_toString(threadData, _set, ((modelica_fnptr) _stringFn), _OMC_LIT0)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT0),stdout);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
DLLDirection
modelica_string omc_UnorderedSet_toString(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _stringFn, modelica_string _delimiter)
{
modelica_string _str = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_string __omcQ_24tmpVar0;
modelica_integer tmp4;
modelica_metatype _k_loopVar = 0;
modelica_integer tmp5;
modelica_metatype _k;
_k_loopVar = omc_UnorderedSet_toArray(threadData, _set);
tmp5 = 1;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar1;
while(1) {
tmp4 = 1;
if (tmp5 <= arrayLength(_k_loopVar)) {
_k = arrayGet(_k_loopVar, tmp5++);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar0 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stringFn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stringFn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stringFn), 2))), _k) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stringFn), 1)))) (threadData, _k);
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
_str = stringDelimitList(tmpMeta1, _delimiter);
_return: OMC_LABEL_UNUSED
return _str;
}
DLLDirection
void omc_UnorderedSet_rehash(threadData_t *threadData, modelica_metatype _set)
{
modelica_metatype _old_buckets = NULL;
modelica_metatype _new_buckets = NULL;
modelica_integer _bucket_count;
modelica_integer _hash;
modelica_fnptr _hashfn;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_integer tmp8;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_old_buckets = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2))));
_hashfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 4)));
_bucket_count = omc_Util_nextPrime(threadData, (((modelica_integer) 2)) * (mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3)))))));
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_new_buckets = arrayCreate(_bucket_count, tmpMeta1);
{
modelica_metatype _b;
for (tmpMeta2 = _old_buckets, tmp8 = arrayLength(tmpMeta2), tmp7 = 1; tmp7 <= tmp8; tmp7++)
{
_b = arrayGet(tmpMeta2,tmp7);
{
modelica_metatype _k;
for (tmpMeta3 = _b; !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
{
_k = MMC_CAR(tmpMeta3);
_hash = modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))), _k) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, _k)), _bucket_count);
tmpMeta4 = mmc_mk_cons(_k, arrayGet(_new_buckets, ((modelica_integer) 1) + _hash));
arrayUpdate(_new_buckets, ((modelica_integer) 1) + _hash, tmpMeta4);
}
}
}
}
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2))), _new_buckets);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
DLLDirection
modelica_real omc_UnorderedSet_loadFactor(threadData_t *threadData, modelica_metatype _set)
{
modelica_real _load;
modelica_real tmp1;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = ((modelica_real)omc_UnorderedSet_bucketCount(threadData, _set));
if (tmp1 == 0) {MMC_THROW_INTERNAL();}
_load = (((modelica_real)mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))))))) / tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _load;
}
modelica_metatype boxptr_UnorderedSet_loadFactor(threadData_t *threadData, modelica_metatype _set)
{
modelica_real _load;
modelica_real tmp1;
modelica_metatype out_load;
_load = omc_UnorderedSet_loadFactor(threadData, _set);
out_load = mmc_mk_rcon(_load);
return out_load;
}
DLLDirection
modelica_integer omc_UnorderedSet_bucketCount(threadData_t *threadData, modelica_metatype _set)
{
modelica_integer _count;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_count = arrayLength(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _count;
}
modelica_metatype boxptr_UnorderedSet_bucketCount(threadData_t *threadData, modelica_metatype _set)
{
modelica_integer _count;
modelica_metatype out_count;
_count = omc_UnorderedSet_bucketCount(threadData, _set);
out_count = mmc_mk_icon(_count);
return out_count;
}
DLLDirection
modelica_boolean omc_UnorderedSet_isEmpty(threadData_t *threadData, modelica_metatype _set)
{
modelica_boolean _empty;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_empty = (mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))))) == ((modelica_integer) 0));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _empty;
}
modelica_metatype boxptr_UnorderedSet_isEmpty(threadData_t *threadData, modelica_metatype _set)
{
modelica_boolean _empty;
modelica_metatype out_empty;
_empty = omc_UnorderedSet_isEmpty(threadData, _set);
out_empty = mmc_mk_icon(_empty);
return out_empty;
}
DLLDirection
modelica_integer omc_UnorderedSet_size(threadData_t *threadData, modelica_metatype _set)
{
modelica_integer _s;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s = mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3)))));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _s;
}
modelica_metatype boxptr_UnorderedSet_size(threadData_t *threadData, modelica_metatype _set)
{
modelica_integer _s;
modelica_metatype out_s;
_s = omc_UnorderedSet_size(threadData, _set);
out_s = mmc_mk_icon(_s);
return out_s;
}
DLLDirection
modelica_metatype omc_UnorderedSet_splitOnTrue(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn, modelica_metatype *out_falseSet)
{
modelica_metatype _trueSet = NULL;
modelica_metatype _falseSet = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_trueSet = omc_UnorderedSet_new(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 5))), ((modelica_integer) 13));
_falseSet = omc_UnorderedSet_new(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 5))), ((modelica_integer) 13));
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_b = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _b; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
omc_UnorderedSet_add(threadData, _k, (mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _k) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _k))?_trueSet:_falseSet));
}
}
}
}
_return: OMC_LABEL_UNUSED
if (out_falseSet) { *out_falseSet = _falseSet; }
return _trueSet;
}
DLLDirection
modelica_metatype omc_UnorderedSet_filterOnFalse(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn)
{
modelica_metatype _falseSet = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_falseSet = omc_UnorderedSet_new(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 5))), ((modelica_integer) 13));
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_b = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _b; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
if((!mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _k) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _k))))
{
omc_UnorderedSet_add(threadData, _k, _falseSet);
}
}
}
}
}
_return: OMC_LABEL_UNUSED
return _falseSet;
}
DLLDirection
modelica_boolean omc_UnorderedSet_none(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_UnorderedSet_isEmpty(threadData, _set))
{
_res = 1;
goto _return;
}
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_b = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _b; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _k) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _k)))
{
_res = 0;
goto _return;
}
}
}
}
}
_res = 1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_UnorderedSet_none(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_UnorderedSet_none(threadData, _set, _fn);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_boolean omc_UnorderedSet_any(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_UnorderedSet_isEmpty(threadData, _set))
{
_res = 0;
goto _return;
}
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_b = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _b; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _k) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _k)))
{
_res = 1;
goto _return;
}
}
}
}
}
_res = 0;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_UnorderedSet_any(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_UnorderedSet_any(threadData, _set, _fn);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_boolean omc_UnorderedSet_all(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_UnorderedSet_isEmpty(threadData, _set))
{
_res = 1;
goto _return;
}
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_b = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _b; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
if((!mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _k) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _k))))
{
_res = 0;
goto _return;
}
}
}
}
}
_res = 1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_UnorderedSet_all(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_UnorderedSet_all(threadData, _set, _fn);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
void omc_UnorderedSet_apply(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn)
{
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_b = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _b; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((void(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _k) : ((void(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _k);
}
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
DLLDirection
modelica_metatype omc_UnorderedSet_selfMap(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn)
{
modelica_metatype _outSet = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outSet = omc_UnorderedSet_new(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 5))), ((modelica_integer) 13));
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_b = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _b; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
omc_UnorderedSet_add(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _k) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _k), _outSet);
}
}
}
}
_return: OMC_LABEL_UNUSED
return _outSet;
}
DLLDirection
modelica_metatype omc_UnorderedSet_fold(threadData_t *threadData, modelica_metatype _set, modelica_fnptr _fn, modelica_metatype _startValue)
{
modelica_metatype _result = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_result = _startValue;
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_b = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _b; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
_result = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _k, _result) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _k, _result);
}
}
}
}
_return: OMC_LABEL_UNUSED
return _result;
}
DLLDirection
modelica_metatype omc_UnorderedSet_toArray(threadData_t *threadData, modelica_metatype _set)
{
modelica_metatype _outArray = NULL;
modelica_metatype _dummy = NULL;
modelica_integer _i;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_dummy = _dummy;
_i = ((modelica_integer) 1);
_outArray = arrayCreateNoInit(mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))))), _dummy);
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_b = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _b; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
arrayUpdateNoBoundsChecking(_outArray, _i, _k);
_i = ((modelica_integer) 1) + _i;
}
}
}
}
_return: OMC_LABEL_UNUSED
return _outArray;
}
DLLDirection
modelica_metatype omc_UnorderedSet_toList(threadData_t *threadData, modelica_metatype _set)
{
modelica_metatype _outList = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_integer tmp8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outList = tmpMeta1;
{
modelica_metatype _b;
for (tmpMeta2 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))), tmp8 = arrayLength(tmpMeta2), tmp7 = 1; tmp7 <= tmp8; tmp7++)
{
_b = arrayGet(tmpMeta2,tmp7);
{
modelica_metatype _k;
for (tmpMeta3 = _b; !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
{
_k = MMC_CAR(tmpMeta3);
tmpMeta4 = mmc_mk_cons(_k, _outList);
_outList = tmpMeta4;
}
}
}
}
_return: OMC_LABEL_UNUSED
return _outList;
}
DLLDirection
modelica_boolean omc_UnorderedSet_isEqual(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2)
{
modelica_boolean _equal;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_integer tmp6;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_equal = 1;
if((mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 3))))) != mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set2), 3)))))))
{
_equal = 0;
goto _return;
}
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set1), 2)))), tmp6 = arrayLength(tmpMeta1), tmp5 = 1; tmp5 <= tmp6; tmp5++)
{
_b = arrayGet(tmpMeta1,tmp5);
{
modelica_metatype _k;
for (tmpMeta2 = _b; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_k = MMC_CAR(tmpMeta2);
if((!omc_UnorderedSet_contains(threadData, _k, _set2)))
{
_equal = 0;
goto _return;
}
}
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _equal;
}
modelica_metatype boxptr_UnorderedSet_isEqual(threadData_t *threadData, modelica_metatype _set1, modelica_metatype _set2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_UnorderedSet_isEqual(threadData, _set1, _set2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLDirection
modelica_metatype omc_UnorderedSet_first(threadData_t *threadData, modelica_metatype _set)
{
modelica_metatype _val = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_integer tmp4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _b;
for (tmpMeta1 = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))), tmp4 = arrayLength(tmpMeta1), tmp3 = 1; tmp3 <= tmp4; tmp3++)
{
_b = arrayGet(tmpMeta1,tmp3);
if((!listEmpty(_b)))
{
_val = listHead(_b);
goto _return;
}
}
}
MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return _val;
}
DLLDirection
modelica_boolean omc_UnorderedSet_contains(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set)
{
modelica_boolean _res;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = isSome(omc_UnorderedSet_find(threadData, _key, _set, NULL));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_UnorderedSet_contains(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_UnorderedSet_contains(threadData, _key, _set);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_metatype omc_UnorderedSet_getOrFail(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set)
{
modelica_metatype _outKey = NULL;
modelica_metatype _okey = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_okey = omc_UnorderedSet_find(threadData, _key, _set, NULL);
tmpMeta1 = _okey;
if (optionNone(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
_outKey = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _outKey;
}
DLLDirection
modelica_metatype omc_UnorderedSet_get(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set)
{
modelica_metatype _outKey = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outKey = omc_UnorderedSet_find(threadData, _key, _set, NULL);
_return: OMC_LABEL_UNUSED
return _outKey;
}
DLLDirection
modelica_boolean omc_UnorderedSet_remove(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set)
{
modelica_boolean _removed;
modelica_metatype _buckets = NULL;
modelica_fnptr _hashfn;
modelica_fnptr _eqfn;
modelica_integer _hash;
modelica_metatype _bucket = NULL;
modelica_metatype _okey = NULL;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_buckets = omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2))));
_hashfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 4)));
_eqfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 5)));
_hash = modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, _key)), arrayLength(_buckets));
_bucket = arrayGet(_buckets, ((modelica_integer) 1) + _hash);
_bucket = omc_List_deleteMemberOnTrue(threadData, _key, _bucket, ((modelica_fnptr) _eqfn) ,&_okey);
_removed = isSome(_okey);
if(_removed)
{
arrayUpdateNoBoundsChecking(_buckets, ((modelica_integer) 1) + _hash, _bucket);
omc_Mutable_update(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))), mmc_mk_integer(((modelica_integer) -1) + (mmc_unbox_integer(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))))))));
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _removed;
}
modelica_metatype boxptr_UnorderedSet_remove(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set)
{
modelica_boolean _removed;
modelica_metatype out_removed;
_removed = omc_UnorderedSet_remove(threadData, _key, _set);
out_removed = mmc_mk_icon(_removed);
return out_removed;
}
DLLDirection
void omc_UnorderedSet_addUnique(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set)
{
modelica_integer _hash;
modelica_integer tmp1;
modelica_metatype tmpMeta2;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta2 = omc_UnorderedSet_find(threadData, _key, _set, &tmp1);
if (!optionNone(tmpMeta2)) MMC_THROW_INTERNAL();
_hash = tmp1;
omc_UnorderedSet_addKey(threadData, _key, _hash, _set);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
DLLDirection
void omc_UnorderedSet_addNew(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set)
{
modelica_fnptr _hashfn;
modelica_integer _hash;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hashfn = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 4)));
_hash = modelica_integer_mod(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 2))), _key) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashfn), 1)))) (threadData, _key)), arrayLength(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2))))));
omc_UnorderedSet_addKey(threadData, _key, _hash, _set);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
DLLDirection
modelica_boolean omc_UnorderedSet_add(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set)
{
modelica_boolean _added;
modelica_integer _hash;
modelica_metatype _okey = NULL;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_okey = omc_UnorderedSet_find(threadData, _key, _set ,&_hash);
_added = isNone(_okey);
if(_added)
{
omc_UnorderedSet_addKey(threadData, _key, _hash, _set);
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _added;
}
modelica_metatype boxptr_UnorderedSet_add(threadData_t *threadData, modelica_metatype _key, modelica_metatype _set)
{
modelica_boolean _added;
modelica_metatype out_added;
_added = omc_UnorderedSet_add(threadData, _key, _set);
out_added = mmc_mk_icon(_added);
return out_added;
}
DLLDirection
modelica_metatype omc_UnorderedSet_copy(threadData_t *threadData, modelica_metatype _set)
{
modelica_metatype _outSet = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box5(3, &UnorderedSet_UNORDERED__SET__desc, omc_Mutable_create(threadData, arrayCopy(omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2)))))), omc_Mutable_create(threadData, omc_Mutable_access(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 5))));
_outSet = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSet;
}
DLLDirection
modelica_metatype omc_UnorderedSet_fromList(threadData_t *threadData, modelica_metatype _elements, modelica_fnptr _hash, modelica_fnptr _keyEq)
{
modelica_metatype _set = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_set = omc_UnorderedSet_new(threadData, ((modelica_fnptr) _hash), ((modelica_fnptr) _keyEq), omc_Util_nextPrime(threadData, listLength(_elements)));
{
modelica_metatype _e;
for (tmpMeta1 = _elements; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_e = MMC_CAR(tmpMeta1);
omc_UnorderedSet_add(threadData, _e, _set);
}
}
_return: OMC_LABEL_UNUSED
return _set;
}
DLLDirection
modelica_metatype omc_UnorderedSet_new(threadData_t *threadData, modelica_fnptr _hash, modelica_fnptr _keyEq, modelica_integer _bucketCount)
{
modelica_metatype _set = NULL;
modelica_metatype _buckets = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_buckets = omc_Mutable_create(threadData, arrayCreate(_bucketCount, tmpMeta1));
tmpMeta2 = mmc_mk_box5(3, &UnorderedSet_UNORDERED__SET__desc, _buckets, omc_Mutable_create(threadData, mmc_mk_integer(((modelica_integer) 0))), ((modelica_fnptr) _hash), ((modelica_fnptr) _keyEq));
_set = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _set;
}
modelica_metatype boxptr_UnorderedSet_new(threadData_t *threadData, modelica_fnptr _hash, modelica_fnptr _keyEq, modelica_metatype _bucketCount)
{
modelica_integer tmp1;
modelica_metatype _set = NULL;
tmp1 = mmc_unbox_integer(_bucketCount);
_set = omc_UnorderedSet_new(threadData, _hash, _keyEq, tmp1);
return _set;
}
