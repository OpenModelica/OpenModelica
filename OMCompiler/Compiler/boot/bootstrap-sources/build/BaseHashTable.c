#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "BaseHashTable.c"
#endif
#include "omc_simulation_settings.h"
#include "BaseHashTable.h"
#define _OMC_LIT0_data "HashTable.valueArraySet(pos="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,28,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data ") size="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,7,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data " arrSize="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,9,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data " failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,8,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "BaseHashTable.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,16,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT5_6,0.0);
#define _OMC_LIT5_6 MMC_REFREALLIT(_OMC_LIT_STRUCT5_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT4,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(595)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(595)),MMC_IMMEDIATE(MMC_TAGFIXNUM(161)),_OMC_LIT5_6}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "-HashTable.valueArrayAdd failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,32,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,1,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data ",{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,2,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "}}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,2,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "Debug HashTable:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,17,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "szBucket: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,10,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,1,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "Debug ValueArray:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,18,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "number of entires: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,19,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "size: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,6,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data ": "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,2,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "Debug HashVector:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,18,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data ":"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,1,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data " {"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,2,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,2,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,1,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "HashTable:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,11,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "}}\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,3,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "BaseHashTable.delete failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,28,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "- BaseHashTable.addNoUpdCheck failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,37,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "index list lengths:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,20,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,1,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "non-zero: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,10,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "/"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,1,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data "max element: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,13,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "total entries: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,15,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "Got internal hash table size "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,29,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data " <1"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,3,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT34_6,0.0);
#define _OMC_LIT34_6 MMC_REFREALLIT(_OMC_LIT_STRUCT34_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT4,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(119)),MMC_IMMEDIATE(MMC_TAGFIXNUM(5)),MMC_IMMEDIATE(MMC_TAGFIXNUM(119)),MMC_IMMEDIATE(MMC_TAGFIXNUM(104)),_OMC_LIT34_6}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
#include "util/modelica.h"
#include "BaseHashTable_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_boolean omc_BaseHashTable_valueArrayKeyIndexExists(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashTable_valueArrayKeyIndexExists(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashTable_valueArrayKeyIndexExists,2,0) {(void*) boxptr_BaseHashTable_valueArrayKeyIndexExists,0}};
#define boxvar_BaseHashTable_valueArrayKeyIndexExists MMC_REFSTRUCTLIT(boxvar_lit_BaseHashTable_valueArrayKeyIndexExists)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BaseHashTable_getValueArray(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos, modelica_metatype *out_value);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashTable_getValueArray(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos, modelica_metatype *out_value);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashTable_getValueArray,2,0) {(void*) boxptr_BaseHashTable_getValueArray,0}};
#define boxvar_BaseHashTable_getValueArray MMC_REFSTRUCTLIT(boxvar_lit_BaseHashTable_getValueArray)
PROTECTED_FUNCTION_STATIC void omc_BaseHashTable_valueArrayClear(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos);
PROTECTED_FUNCTION_STATIC void boxptr_BaseHashTable_valueArrayClear(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashTable_valueArrayClear,2,0) {(void*) boxptr_BaseHashTable_valueArrayClear,0}};
#define boxvar_BaseHashTable_valueArrayClear MMC_REFSTRUCTLIT(boxvar_lit_BaseHashTable_valueArrayClear)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BaseHashTable_valueArraySet(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos, modelica_metatype _entry);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashTable_valueArraySet(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos, modelica_metatype _entry);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashTable_valueArraySet,2,0) {(void*) boxptr_BaseHashTable_valueArraySet,0}};
#define boxvar_BaseHashTable_valueArraySet MMC_REFSTRUCTLIT(boxvar_lit_BaseHashTable_valueArraySet)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BaseHashTable_valueArrayAdd(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _entry, modelica_integer *out_newpos);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashTable_valueArrayAdd(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _entry, modelica_metatype *out_newpos);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashTable_valueArrayAdd,2,0) {(void*) boxptr_BaseHashTable_valueArrayAdd,0}};
#define boxvar_BaseHashTable_valueArrayAdd MMC_REFSTRUCTLIT(boxvar_lit_BaseHashTable_valueArrayAdd)
PROTECTED_FUNCTION_STATIC modelica_string omc_BaseHashTable_dumpTuple(threadData_t *threadData, modelica_metatype _tpl, modelica_fnptr _printKey, modelica_fnptr _printValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashTable_dumpTuple,2,0) {(void*) boxptr_BaseHashTable_dumpTuple,0}};
#define boxvar_BaseHashTable_dumpTuple MMC_REFSTRUCTLIT(boxvar_lit_BaseHashTable_dumpTuple)
PROTECTED_FUNCTION_STATIC modelica_integer omc_BaseHashTable_hasKeyIndex2(threadData_t *threadData, modelica_metatype _key, modelica_metatype _keyIndices, modelica_fnptr _keyEqual);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashTable_hasKeyIndex2(threadData_t *threadData, modelica_metatype _key, modelica_metatype _keyIndices, modelica_fnptr _keyEqual);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashTable_hasKeyIndex2,2,0) {(void*) boxptr_BaseHashTable_hasKeyIndex2,0}};
#define boxvar_BaseHashTable_hasKeyIndex2 MMC_REFSTRUCTLIT(boxvar_lit_BaseHashTable_hasKeyIndex2)
PROTECTED_FUNCTION_STATIC modelica_integer omc_BaseHashTable_hasKeyIndex(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashTable);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashTable_hasKeyIndex(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashTable);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BaseHashTable_hasKeyIndex,2,0) {(void*) boxptr_BaseHashTable_hasKeyIndex,0}};
#define boxvar_BaseHashTable_hasKeyIndex MMC_REFSTRUCTLIT(boxvar_lit_BaseHashTable_hasKeyIndex)
DLLExport
void omc_BaseHashTable_clearAssumeNoDelete(threadData_t *threadData, modelica_metatype _ht)
{
modelica_metatype _hv = NULL;
modelica_integer _bs;
modelica_integer _sz;
modelica_integer _vs;
modelica_integer _ve;
modelica_integer _hash_idx;
modelica_metatype _ft = NULL;
modelica_fnptr _hashFunc;
modelica_metatype _key = NULL;
modelica_metatype _vae = NULL;
modelica_boolean _workaroundForBug;
modelica_boolean _debug;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_integer tmp19;
modelica_integer tmp20;
modelica_integer tmp21;
modelica_metatype tmpMeta22;
modelica_integer tmp23;
modelica_integer tmp24;
modelica_integer tmp25;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_workaroundForBug = 1;
_debug = 0;
tmpMeta1 = _ht;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 1));
tmp5 = mmc_unbox_integer(tmpMeta4);
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp10 = mmc_unbox_integer(tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 1));
_hv = tmpMeta2;
_vs = tmp5;
_ve = tmp7;
_vae = tmpMeta8;
_bs = tmp10;
_ft = tmpMeta11;
_hashFunc = tmpMeta12;
tmp19 = ((modelica_integer) 1); tmp20 = 1; tmp21 = _ve;
if(!(((tmp20 > 0) && (tmp19 > tmp21)) || ((tmp20 < 0) && (tmp19 < tmp21))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp19, tmp21); _i += tmp20)
{
{
modelica_metatype tmp15_1;
tmp15_1 = arrayGet(_vae, _i);
{
volatile mmc_switch_type tmp15;
int tmp16;
tmp15 = 0;
for (; tmp15 < 2; tmp15++) {
switch (MMC_SWITCH_CAST(tmp15)) {
case 0: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (optionNone(tmp15_1)) goto tmp14_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp15_1), 1));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 1));
_key = tmpMeta18;
arrayUpdate(_vae, _i, mmc_mk_none());
goto tmp14_done;
}
case 1: {
goto tmp14_done;
}
}
goto tmp14_end;
tmp14_end: ;
}
goto goto_13;
goto_13:;
MMC_THROW_INTERNAL();
goto tmp14_done;
tmp14_done:;
}
}
;
}
}
tmp23 = ((modelica_integer) 1); tmp24 = 1; tmp25 = arrayLength(_hv);
if(!(((tmp24 > 0) && (tmp23 > tmp25)) || ((tmp24 < 0) && (tmp23 < tmp25))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp23, tmp25); _i += tmp24)
{
if((!listEmpty(arrayGet(_hv, _i))))
{
tmpMeta22 = MMC_REFSTRUCTLIT(mmc_nil);
arrayUpdate(_hv, _i, tmpMeta22);
}
}
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_BaseHashTable_clear(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fht)
{
modelica_metatype _ht = NULL;
modelica_metatype _hv = NULL;
modelica_integer _bs;
modelica_integer _sz;
modelica_integer _vs;
modelica_integer _ve;
modelica_integer _hash_idx;
modelica_metatype _ft = NULL;
modelica_fnptr _hashFunc;
modelica_metatype _key = NULL;
modelica_metatype _vae = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_integer tmp20;
modelica_integer tmp21;
modelica_integer tmp22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ht = __omcQ_24in_5Fht;
tmpMeta1 = _ht;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 1));
tmp5 = mmc_unbox_integer(tmpMeta4);
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp10 = mmc_unbox_integer(tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 1));
_hv = tmpMeta2;
_vs = tmp5;
_ve = tmp7;
_vae = tmpMeta8;
_bs = tmp10;
_ft = tmpMeta11;
_hashFunc = tmpMeta12;
tmp20 = ((modelica_integer) 1); tmp21 = 1; tmp22 = _vs;
if(!(((tmp21 > 0) && (tmp20 > tmp22)) || ((tmp21 < 0) && (tmp20 < tmp22))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp20, tmp22); _i += tmp21)
{
{
modelica_metatype tmp15_1;
tmp15_1 = arrayGet(_vae, _i);
{
volatile mmc_switch_type tmp15;
int tmp16;
tmp15 = 0;
for (; tmp15 < 2; tmp15++) {
switch (MMC_SWITCH_CAST(tmp15)) {
case 0: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (optionNone(tmp15_1)) goto tmp14_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp15_1), 1));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 1));
_key = tmpMeta18;
_hash_idx = ((modelica_integer) 1) + mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key, mmc_mk_integer(_bs)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key, mmc_mk_integer(_bs)));
tmpMeta19 = MMC_REFSTRUCTLIT(mmc_nil);
arrayUpdate(_hv, _hash_idx, tmpMeta19);
arrayUpdate(_vae, _i, mmc_mk_none());
goto tmp14_done;
}
case 1: {
goto tmp14_done;
}
}
goto tmp14_end;
tmp14_end: ;
}
goto goto_13;
goto_13:;
MMC_THROW_INTERNAL();
goto tmp14_done;
tmp14_done:;
}
}
;
}
}
tmpMeta23 = mmc_mk_box3(0, mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(_ve), _vae);
tmpMeta24 = mmc_mk_box4(0, _hv, tmpMeta23, mmc_mk_integer(_bs), _ft);
_ht = tmpMeta24;
_return: OMC_LABEL_UNUSED
return _ht;
}
DLLExport
modelica_metatype omc_BaseHashTable_copy(threadData_t *threadData, modelica_metatype _inHashTable)
{
modelica_metatype _outCopy = NULL;
modelica_metatype _hv = NULL;
modelica_integer _bs;
modelica_integer _sz;
modelica_integer _vs;
modelica_integer _ve;
modelica_metatype _ft = NULL;
modelica_metatype _vae = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inHashTable;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 1));
tmp5 = mmc_unbox_integer(tmpMeta4);
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp10 = mmc_unbox_integer(tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_hv = tmpMeta2;
_vs = tmp5;
_ve = tmp7;
_vae = tmpMeta8;
_bs = tmp10;
_ft = tmpMeta11;
_hv = arrayCopy(_hv);
_vae = arrayCopy(_vae);
tmpMeta12 = mmc_mk_box3(0, mmc_mk_integer(_vs), mmc_mk_integer(_ve), _vae);
tmpMeta13 = mmc_mk_box4(0, _hv, tmpMeta12, mmc_mk_integer(_bs), _ft);
_outCopy = tmpMeta13;
_return: OMC_LABEL_UNUSED
return _outCopy;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_BaseHashTable_valueArrayKeyIndexExists(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_integer tmp4_2;
tmp4_1 = _valueArray;
tmp4_2 = _pos;
{
modelica_integer _n;
modelica_metatype _arr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (-1 != tmp4_2) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_n = tmp7;
_arr = tmpMeta8;
tmp1 = ((_pos <= _n)?isSome(arrayGet(_arr,_pos) /* DAE.ASUB */):0);
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashTable_valueArrayKeyIndexExists(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos)
{
modelica_integer tmp1;
modelica_boolean _b;
modelica_metatype out_b;
tmp1 = mmc_unbox_integer(_pos);
_b = omc_BaseHashTable_valueArrayKeyIndexExists(threadData, _valueArray, tmp1);
out_b = mmc_mk_icon(_b);
return out_b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BaseHashTable_getValueArray(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos, modelica_metatype *out_value)
{
modelica_metatype _key = NULL;
modelica_metatype _value = NULL;
modelica_metatype _arr = NULL;
modelica_integer _n;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_metatype tmpMeta4;
modelica_boolean tmp5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _valueArray;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmp3 = mmc_unbox_integer(tmpMeta2);
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_n = tmp3;
_arr = tmpMeta4;
tmp5 = (_pos <= _n);
if (1 != tmp5) MMC_THROW_INTERNAL();
tmpMeta6 = arrayGet(_arr, _pos);
if (optionNone(tmpMeta6)) MMC_THROW_INTERNAL();
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_key = tmpMeta8;
_value = tmpMeta9;
_return: OMC_LABEL_UNUSED
if (out_value) { *out_value = _value; }
return _key;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashTable_getValueArray(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos, modelica_metatype *out_value)
{
modelica_integer tmp1;
modelica_metatype _key = NULL;
tmp1 = mmc_unbox_integer(_pos);
_key = omc_BaseHashTable_getValueArray(threadData, _valueArray, tmp1, out_value);
return _key;
}
PROTECTED_FUNCTION_STATIC void omc_BaseHashTable_valueArrayClear(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos)
{
modelica_metatype _arr = NULL;
modelica_integer _size;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_metatype tmpMeta4;
modelica_boolean tmp5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _valueArray;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmp3 = mmc_unbox_integer(tmpMeta2);
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_size = tmp3;
_arr = tmpMeta4;
tmp5 = (_pos <= _size);
if (1 != tmp5) MMC_THROW_INTERNAL();
arrayUpdate(_arr, _pos, mmc_mk_none());
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void boxptr_BaseHashTable_valueArrayClear(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_pos);
omc_BaseHashTable_valueArrayClear(threadData, _valueArray, tmp1);
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BaseHashTable_valueArraySet(threadData_t *threadData, modelica_metatype _valueArray, modelica_integer _pos, modelica_metatype _entry)
{
modelica_metatype _outValueArray = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _valueArray;
{
modelica_metatype _arr = NULL;
modelica_integer _n;
modelica_integer _size;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_n = tmp7;
_size = tmp9;
_arr = tmpMeta10;
tmp11 = (_pos <= _size);
if (1 != tmp11) goto goto_2;
_arr = arrayUpdate(_arr, _pos, mmc_mk_some(_entry));
tmpMeta12 = mmc_mk_box3(0, mmc_mk_integer(_n), mmc_mk_integer(_size), _arr);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_integer tmp14;
modelica_metatype tmpMeta15;
modelica_string tmp16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_string tmp19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_string tmp22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp14 = mmc_unbox_integer(tmpMeta13);
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_size = tmp14;
_arr = tmpMeta15;
tmp16 = modelica_integer_to_modelica_string(_pos, ((modelica_integer) 0), 1);
tmpMeta17 = stringAppend(_OMC_LIT0,tmp16);
tmpMeta18 = stringAppend(tmpMeta17,_OMC_LIT1);
tmp19 = modelica_integer_to_modelica_string(_size, ((modelica_integer) 0), 1);
tmpMeta20 = stringAppend(tmpMeta18,tmp19);
tmpMeta21 = stringAppend(tmpMeta20,_OMC_LIT2);
tmp22 = modelica_integer_to_modelica_string(arrayLength(_arr), ((modelica_integer) 0), 1);
tmpMeta23 = stringAppend(tmpMeta21,tmp22);
tmpMeta24 = stringAppend(tmpMeta23,_OMC_LIT3);
omc_Error_addInternalError(threadData, tmpMeta24, _OMC_LIT5);
goto goto_2;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outValueArray = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValueArray;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashTable_valueArraySet(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _pos, modelica_metatype _entry)
{
modelica_integer tmp1;
modelica_metatype _outValueArray = NULL;
tmp1 = mmc_unbox_integer(_pos);
_outValueArray = omc_BaseHashTable_valueArraySet(threadData, _valueArray, tmp1, _entry);
return _outValueArray;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BaseHashTable_valueArrayAdd(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _entry, modelica_integer *out_newpos)
{
modelica_metatype _outValueArray = NULL;
modelica_integer _newpos;
modelica_integer tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _valueArray;
{
modelica_integer _n;
modelica_integer _size;
modelica_integer _expandsize;
modelica_integer _newsize;
modelica_metatype _arr = NULL;
modelica_real _rsize;
modelica_real _rexpandsize;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_n = tmp7;
_size = tmp9;
_arr = tmpMeta10;
if((!(_n < _size)))
{
goto goto_2;
}
_n = ((modelica_integer) 1) + _n;
_arr = arrayUpdate(_arr, _n, mmc_mk_some(_entry));
tmpMeta11 = mmc_mk_box3(0, mmc_mk_integer(_n), mmc_mk_integer(_size), _arr);
tmpMeta[0+0] = tmpMeta11;
tmp1_c1 = _n;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_integer tmp13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmp13 = mmc_unbox_integer(tmpMeta12);
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_n = tmp13;
_size = tmp15;
_arr = tmpMeta16;
if((_n < _size))
{
goto goto_2;
}
_rsize = ((modelica_real)_size);
_rexpandsize = (0.4) * (_rsize);
_expandsize = ((modelica_integer)floor(_rexpandsize));
_expandsize = modelica_integer_max((modelica_integer)(_expandsize),(modelica_integer)(((modelica_integer) 1)));
_newsize = _expandsize + _size;
_arr = omc_Array_expand(threadData, _expandsize, _arr, mmc_mk_none());
_n = ((modelica_integer) 1) + _n;
_arr = arrayUpdate(_arr, _n, mmc_mk_some(_entry));
tmpMeta17 = mmc_mk_box3(0, mmc_mk_integer(_n), mmc_mk_integer(_newsize), _arr);
tmpMeta[0+0] = tmpMeta17;
tmp1_c1 = _n;
goto tmp3_done;
}
case 2: {
fputs(MMC_STRINGDATA(_OMC_LIT6),stdout);
goto goto_2;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 3) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outValueArray = tmpMeta[0+0];
_newpos = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_newpos) { *out_newpos = _newpos; }
return _outValueArray;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashTable_valueArrayAdd(threadData_t *threadData, modelica_metatype _valueArray, modelica_metatype _entry, modelica_metatype *out_newpos)
{
modelica_integer _newpos;
modelica_metatype _outValueArray = NULL;
_outValueArray = omc_BaseHashTable_valueArrayAdd(threadData, _valueArray, _entry, &_newpos);
if (out_newpos) { *out_newpos = mmc_mk_icon(_newpos); }
return _outValueArray;
}
DLLExport
modelica_integer omc_BaseHashTable_valueArrayLength(threadData_t *threadData, modelica_metatype _valueArray)
{
modelica_integer _sz;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _valueArray;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmp3 = mmc_unbox_integer(tmpMeta2);
_sz = tmp3;
_return: OMC_LABEL_UNUSED
return _sz;
}
modelica_metatype boxptr_BaseHashTable_valueArrayLength(threadData_t *threadData, modelica_metatype _valueArray)
{
modelica_integer _sz;
modelica_metatype out_sz;
_sz = omc_BaseHashTable_valueArrayLength(threadData, _valueArray);
out_sz = mmc_mk_icon(_sz);
return out_sz;
}
DLLExport
modelica_integer omc_BaseHashTable_hashTableCurrentSize(threadData_t *threadData, modelica_metatype _hashTable)
{
modelica_integer _sz;
modelica_metatype _va = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _hashTable;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_va = tmpMeta2;
_sz = omc_BaseHashTable_valueArrayLength(threadData, _va);
_return: OMC_LABEL_UNUSED
return _sz;
}
modelica_metatype boxptr_BaseHashTable_hashTableCurrentSize(threadData_t *threadData, modelica_metatype _hashTable)
{
modelica_integer _sz;
modelica_metatype out_sz;
_sz = omc_BaseHashTable_hashTableCurrentSize(threadData, _hashTable);
out_sz = mmc_mk_icon(_sz);
return out_sz;
}
DLLExport
modelica_metatype omc_BaseHashTable_valueArrayListReversed(threadData_t *threadData, modelica_metatype _valueArray)
{
modelica_metatype _entries = NULL;
modelica_metatype _arr = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _valueArray;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_arr = tmpMeta2;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_entries = omc_Array_fold(threadData, _arr, boxvar_List_consOption, tmpMeta3);
_return: OMC_LABEL_UNUSED
return _entries;
}
DLLExport
modelica_metatype omc_BaseHashTable_valueArrayList(threadData_t *threadData, modelica_metatype _valueArray)
{
modelica_metatype _outEntries = NULL;
modelica_metatype _arr = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _valueArray;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_arr = tmpMeta2;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_outEntries = omc_Array_fold(threadData, _arr, boxvar_List_consOption, tmpMeta3);
_outEntries = listReverse(_outEntries);
_return: OMC_LABEL_UNUSED
return _outEntries;
}
DLLExport
modelica_metatype omc_BaseHashTable_hashTableListReversed(threadData_t *threadData, modelica_metatype _hashTable)
{
modelica_metatype _entries = NULL;
modelica_metatype _varr = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _hashTable;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_varr = tmpMeta2;
_entries = omc_BaseHashTable_valueArrayListReversed(threadData, _varr);
_return: OMC_LABEL_UNUSED
return _entries;
}
DLLExport
modelica_metatype omc_BaseHashTable_hashTableList(threadData_t *threadData, modelica_metatype _hashTable)
{
modelica_metatype _outEntries = NULL;
modelica_metatype _varr = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _hashTable;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_varr = tmpMeta2;
_outEntries = omc_BaseHashTable_valueArrayList(threadData, _varr);
_return: OMC_LABEL_UNUSED
return _outEntries;
}
DLLExport
modelica_metatype omc_BaseHashTable_hashTableKeyList(threadData_t *threadData, modelica_metatype _hashTable)
{
modelica_metatype _valLst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_valLst = omc_List_unzipFirst(threadData, omc_BaseHashTable_hashTableList(threadData, _hashTable));
_return: OMC_LABEL_UNUSED
return _valLst;
}
DLLExport
modelica_metatype omc_BaseHashTable_hashTableValueList(threadData_t *threadData, modelica_metatype _hashTable)
{
modelica_metatype _valLst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_valLst = omc_List_unzipSecond(threadData, omc_BaseHashTable_hashTableList(threadData, _hashTable));
_return: OMC_LABEL_UNUSED
return _valLst;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_BaseHashTable_dumpTuple(threadData_t *threadData, modelica_metatype _tpl, modelica_fnptr _printKey, modelica_fnptr _printValue)
{
modelica_string _str = NULL;
modelica_metatype _k = NULL;
modelica_metatype _v = NULL;
modelica_string _sk = NULL;
modelica_string _sv = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _tpl;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_k = tmpMeta2;
_v = tmpMeta3;
_sk = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 2))), _k) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 1)))) (threadData, _k);
_sv = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printValue), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printValue), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printValue), 2))), _v) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printValue), 1)))) (threadData, _v);
tmpMeta4 = mmc_mk_cons(_OMC_LIT7, mmc_mk_cons(_sk, mmc_mk_cons(_OMC_LIT8, mmc_mk_cons(_sv, mmc_mk_cons(_OMC_LIT9, MMC_REFSTRUCTLIT(mmc_nil))))));
_str = stringAppendList(tmpMeta4);
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
void omc_BaseHashTable_debugDump(threadData_t *threadData, modelica_metatype _ht)
{
modelica_fnptr _printKey;
modelica_fnptr _printValue;
modelica_metatype _k = NULL;
modelica_metatype _v = NULL;
modelica_integer _n;
modelica_integer _size;
modelica_integer _i;
modelica_integer _j;
modelica_integer _szBucket;
modelica_metatype _arr = NULL;
modelica_metatype _he = NULL;
modelica_metatype _hashVector = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_integer tmp27;
modelica_integer tmp28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_integer tmp35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_integer tmp42;
modelica_integer tmp43;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _ht;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 1));
tmp5 = mmc_unbox_integer(tmpMeta4);
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp10 = mmc_unbox_integer(tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 4));
_hashVector = tmpMeta2;
_n = tmp5;
_size = tmp7;
_arr = tmpMeta8;
_szBucket = tmp10;
_printKey = tmpMeta12;
_printValue = tmpMeta13;
fputs(MMC_STRINGDATA(_OMC_LIT10),stdout);
tmpMeta14 = stringAppend(_OMC_LIT11,intString(_szBucket));
tmpMeta15 = stringAppend(tmpMeta14,_OMC_LIT12);
fputs(MMC_STRINGDATA(tmpMeta15),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT13),stdout);
tmpMeta16 = stringAppend(_OMC_LIT14,intString(_n));
tmpMeta17 = stringAppend(tmpMeta16,_OMC_LIT12);
fputs(MMC_STRINGDATA(tmpMeta17),stdout);
tmpMeta18 = stringAppend(_OMC_LIT15,intString(_size));
tmpMeta19 = stringAppend(tmpMeta18,_OMC_LIT12);
fputs(MMC_STRINGDATA(tmpMeta19),stdout);
_i = ((modelica_integer) 0);
{
modelica_metatype _entry;
for (tmpMeta20 = _arr, tmp28 = arrayLength(tmpMeta20), tmp27 = 1; tmp27 <= tmp28; tmp27++)
{
_entry = arrayGet(tmpMeta20,tmp27);
_i = ((modelica_integer) 1) + _i;
if(isSome(_entry))
{
tmpMeta21 = _entry;
if (optionNone(tmpMeta21)) MMC_THROW_INTERNAL();
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 1));
_he = tmpMeta22;
tmpMeta23 = stringAppend(intString(_i),_OMC_LIT16);
tmpMeta24 = stringAppend(tmpMeta23,omc_BaseHashTable_dumpTuple(threadData, _he, ((modelica_fnptr) _printKey), ((modelica_fnptr) _printValue)));
tmpMeta25 = stringAppend(tmpMeta24,_OMC_LIT12);
fputs(MMC_STRINGDATA(tmpMeta25),stdout);
}
}
}
fputs(MMC_STRINGDATA(_OMC_LIT17),stdout);
_i = ((modelica_integer) 0);
{
modelica_metatype _node;
for (tmpMeta29 = _hashVector, tmp43 = arrayLength(tmpMeta29), tmp42 = 1; tmp42 <= tmp43; tmp42++)
{
_node = arrayGet(tmpMeta29,tmp42);
_i = ((modelica_integer) 1) + _i;
if((!listEmpty(_node)))
{
tmpMeta30 = stringAppend(intString(_i),_OMC_LIT18);
fputs(MMC_STRINGDATA(tmpMeta30),stdout);
{
modelica_metatype _n;
for (tmpMeta31 = _node; !listEmpty(tmpMeta31); tmpMeta31=MMC_CDR(tmpMeta31))
{
_n = MMC_CAR(tmpMeta31);
tmpMeta32 = _n;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 1));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 2));
tmp35 = mmc_unbox_integer(tmpMeta34);
_k = tmpMeta33;
_j = tmp35;
tmpMeta36 = stringAppend(_OMC_LIT19,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 2))), _k) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 1)))) (threadData, _k));
tmpMeta37 = stringAppend(tmpMeta36,_OMC_LIT20);
tmpMeta38 = stringAppend(tmpMeta37,intString(_j));
tmpMeta39 = stringAppend(tmpMeta38,_OMC_LIT21);
fputs(MMC_STRINGDATA(tmpMeta39),stdout);
}
}
fputs(MMC_STRINGDATA(_OMC_LIT12),stdout);
}
}
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_BaseHashTable_dumpHashTable(threadData_t *threadData, modelica_metatype _t)
{
modelica_fnptr _printKey;
modelica_fnptr _printValue;
modelica_metatype _k = NULL;
modelica_metatype _v = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _t;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 4));
_printKey = tmpMeta3;
_printValue = tmpMeta4;
fputs(MMC_STRINGDATA(_OMC_LIT22),stdout);
{
modelica_metatype _entry;
for (tmpMeta5 = omc_BaseHashTable_hashTableList(threadData, _t); !listEmpty(tmpMeta5); tmpMeta5=MMC_CDR(tmpMeta5))
{
_entry = MMC_CAR(tmpMeta5);
tmpMeta6 = _entry;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_k = tmpMeta7;
_v = tmpMeta8;
fputs(MMC_STRINGDATA(_OMC_LIT7),stdout);
fputs(MMC_STRINGDATA((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 2))), _k) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printKey), 1)))) (threadData, _k)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT8),stdout);
fputs(MMC_STRINGDATA((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printValue), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printValue), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printValue), 2))), _v) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_printValue), 1)))) (threadData, _v)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT23),stdout);
}
}
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_BaseHashTable_hasKeyIndex2(threadData_t *threadData, modelica_metatype _key, modelica_metatype _keyIndices, modelica_fnptr _keyEqual)
{
modelica_integer _index;
modelica_metatype _key2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _keyIndex;
for (tmpMeta1 = _keyIndices; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_keyIndex = MMC_CAR(tmpMeta1);
tmpMeta2 = _keyIndex;
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
_index = ((modelica_integer) -1);
_return: OMC_LABEL_UNUSED
return _index;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashTable_hasKeyIndex2(threadData_t *threadData, modelica_metatype _key, modelica_metatype _keyIndices, modelica_fnptr _keyEqual)
{
modelica_integer _index;
modelica_metatype out_index;
_index = omc_BaseHashTable_hasKeyIndex2(threadData, _key, _keyIndices, _keyEqual);
out_index = mmc_mk_icon(_index);
return out_index;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_BaseHashTable_hasKeyIndex(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashTable)
{
modelica_integer _indx;
modelica_integer _hashindx;
modelica_integer _bsize;
modelica_metatype _indexes = NULL;
modelica_metatype _hashvec = NULL;
modelica_fnptr _keyEqual;
modelica_fnptr _hashFunc;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _hashTable;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
_hashvec = tmpMeta2;
_bsize = tmp4;
_hashFunc = tmpMeta6;
_keyEqual = tmpMeta7;
_hashindx = ((modelica_integer) 1) + mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key, mmc_mk_integer(_bsize)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key, mmc_mk_integer(_bsize)));
_indexes = arrayGet(_hashvec,_hashindx);
_indx = omc_BaseHashTable_hasKeyIndex2(threadData, _key, _indexes, ((modelica_fnptr) _keyEqual));
_return: OMC_LABEL_UNUSED
return _indx;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BaseHashTable_hasKeyIndex(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashTable)
{
modelica_integer _indx;
modelica_metatype out_indx;
_indx = omc_BaseHashTable_hasKeyIndex(threadData, _key, _hashTable);
out_indx = mmc_mk_icon(_indx);
return out_indx;
}
DLLExport
modelica_metatype omc_BaseHashTable_get(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashTable)
{
modelica_metatype _value = NULL;
modelica_integer _i;
modelica_metatype _varr = NULL;
modelica_boolean tmp1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_i = omc_BaseHashTable_hasKeyIndex(threadData, _key, _hashTable);
tmp1 = (_i == ((modelica_integer) -1));
if (0 != tmp1) MMC_THROW_INTERNAL();
tmpMeta2 = _hashTable;
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
_varr = tmpMeta3;
omc_BaseHashTable_getValueArray(threadData, _varr, _i ,&_value);
_return: OMC_LABEL_UNUSED
return _value;
}
DLLExport
modelica_boolean omc_BaseHashTable_anyKeyInHashTable(threadData_t *threadData, modelica_metatype _keys, modelica_metatype _ht)
{
modelica_boolean _res;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _key;
for (tmpMeta1 = _keys; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_key = MMC_CAR(tmpMeta1);
if(omc_BaseHashTable_hasKey(threadData, _key, _ht))
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
modelica_metatype boxptr_BaseHashTable_anyKeyInHashTable(threadData_t *threadData, modelica_metatype _keys, modelica_metatype _ht)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_BaseHashTable_anyKeyInHashTable(threadData, _keys, _ht);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_BaseHashTable_hasKey(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashTable)
{
modelica_boolean _b;
modelica_metatype _varr = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _hashTable;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_varr = tmpMeta2;
_b = omc_BaseHashTable_valueArrayKeyIndexExists(threadData, _varr, omc_BaseHashTable_hasKeyIndex(threadData, _key, _hashTable));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_BaseHashTable_hasKey(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashTable)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_BaseHashTable_hasKey(threadData, _key, _hashTable);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
void omc_BaseHashTable_delete(threadData_t *threadData, modelica_metatype _key, modelica_metatype _hashTable)
{
modelica_integer _indx;
modelica_metatype _varr = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_indx = omc_BaseHashTable_hasKeyIndex(threadData, _key, _hashTable);
tmpMeta1 = _hashTable;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_varr = tmpMeta2;
if((!omc_BaseHashTable_valueArrayKeyIndexExists(threadData, _varr, _indx)))
{
fputs(MMC_STRINGDATA(_OMC_LIT24),stdout);
MMC_THROW_INTERNAL();
}
omc_BaseHashTable_valueArrayClear(threadData, _varr, _indx);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_BaseHashTable_update(threadData_t *threadData, modelica_metatype _entry, modelica_metatype _hashTable)
{
modelica_metatype _varr = NULL;
modelica_integer _index;
modelica_metatype _key = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_boolean tmp5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _entry;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
_key = tmpMeta2;
tmpMeta3 = _hashTable;
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
_varr = tmpMeta4;
_index = omc_BaseHashTable_hasKeyIndex(threadData, _key, _hashTable);
tmp5 = omc_BaseHashTable_valueArrayKeyIndexExists(threadData, _varr, _index);
if (1 != tmp5) MMC_THROW_INTERNAL();
omc_BaseHashTable_valueArraySet(threadData, _varr, _index, _entry);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_BaseHashTable_addUnique(threadData_t *threadData, modelica_metatype _entry, modelica_metatype _hashTable)
{
modelica_metatype _outHashTable = NULL;
modelica_integer _indx;
modelica_integer _newpos;
modelica_integer _bsize;
modelica_metatype _varr = NULL;
modelica_metatype _indexes = NULL;
modelica_metatype _hashvec = NULL;
modelica_metatype _key = NULL;
modelica_metatype _fntpl = NULL;
modelica_fnptr _hashFunc;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _entry;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
_key = tmpMeta2;
tmpMeta3 = _hashTable;
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 1));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 3));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
_hashvec = tmpMeta4;
_varr = tmpMeta5;
_bsize = tmp7;
_fntpl = tmpMeta8;
_hashFunc = tmpMeta9;
tmp10 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
omc_BaseHashTable_get(threadData, _key, _hashTable);
tmp10 = 1;
goto goto_11;
goto_11:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp10) {MMC_THROW_INTERNAL();}
_indx = ((modelica_integer) 1) + mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key, mmc_mk_integer(_bsize)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key, mmc_mk_integer(_bsize)));
_varr = omc_BaseHashTable_valueArrayAdd(threadData, _varr, _entry ,&_newpos);
_indexes = arrayGet(_hashvec,_indx);
tmpMeta13 = mmc_mk_box2(0, _key, mmc_mk_integer(_newpos));
tmpMeta12 = mmc_mk_cons(tmpMeta13, _indexes);
_hashvec = arrayUpdate(_hashvec, _indx, tmpMeta12);
tmpMeta14 = mmc_mk_box4(0, _hashvec, _varr, mmc_mk_integer(_bsize), _fntpl);
_outHashTable = tmpMeta14;
_return: OMC_LABEL_UNUSED
return _outHashTable;
}
DLLExport
modelica_metatype omc_BaseHashTable_addNoUpdCheck(threadData_t *threadData, modelica_metatype _entry, modelica_metatype _hashTable)
{
modelica_metatype _outHashTable = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _entry;
tmp4_2 = _hashTable;
{
modelica_integer _indx;
modelica_integer _newpos;
modelica_integer _bsize;
modelica_metatype _varr = NULL;
modelica_metatype _indexes = NULL;
modelica_metatype _hashvec = NULL;
modelica_metatype _v = NULL;
modelica_metatype _key = NULL;
modelica_metatype _fntpl = NULL;
modelica_fnptr _hashFunc;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp10 = mmc_unbox_integer(tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 1));
_v = tmp4_1;
_key = tmpMeta6;
_hashvec = tmpMeta7;
_varr = tmpMeta8;
_bsize = tmp10;
_fntpl = tmpMeta11;
_hashFunc = tmpMeta12;
_indx = ((modelica_integer) 1) + mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key, mmc_mk_integer(_bsize)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key, mmc_mk_integer(_bsize)));
_varr = omc_BaseHashTable_valueArrayAdd(threadData, _varr, _v ,&_newpos);
_indexes = arrayGet(_hashvec,_indx);
tmpMeta14 = mmc_mk_box2(0, _key, mmc_mk_integer(_newpos));
tmpMeta13 = mmc_mk_cons(tmpMeta14, _indexes);
_hashvec = arrayUpdate(_hashvec, _indx, tmpMeta13);
tmpMeta15 = mmc_mk_box4(0, _hashvec, _varr, mmc_mk_integer(_bsize), _fntpl);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 1: {
fputs(MMC_STRINGDATA(_OMC_LIT25),stdout);
goto goto_2;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outHashTable = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outHashTable;
}
DLLExport
void omc_BaseHashTable_dumpHashTableStatistics(threadData_t *threadData, modelica_metatype _hashTable)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _hashTable;
{
modelica_metatype _hvec = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_string tmp11;
modelica_integer tmp12;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_string tmp17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_string tmp20;
modelica_integer tmp21;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_string tmp26;
modelica_integer tmp27;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_hvec = tmpMeta5;
fputs(MMC_STRINGDATA(_OMC_LIT26),stdout);
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp7;
modelica_metatype tmpMeta8;
modelica_string __omcQ_24tmpVar0;
modelica_integer tmp9;
modelica_metatype _l_loopVar = 0;
modelica_integer tmp10;
modelica_metatype _l;
_l_loopVar = _hvec;
tmp10 = 1;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta8;
tmp7 = &__omcQ_24tmpVar1;
while(1) {
tmp9 = 1;
if (tmp10 <= arrayLength(_l_loopVar)) {
_l = arrayGet(_l_loopVar, tmp10++);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar0 = intString(listLength(_l));
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp9 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp7 = mmc_mk_nil();
tmpMeta6 = __omcQ_24tmpVar1;
}
fputs(MMC_STRINGDATA(stringDelimitList(tmpMeta6, _OMC_LIT27)),stdout);
fputs(MMC_STRINGDATA(_OMC_LIT12),stdout);
{
modelica_integer __omcQ_24tmpVar7;
modelica_integer __omcQ_24tmpVar6;
modelica_integer tmp13;
modelica_metatype _l_loopVar = 0;
modelica_integer tmp14;
modelica_metatype _l;
_l_loopVar = _hvec;
tmp14 = 1;
__omcQ_24tmpVar7 = ((modelica_integer) 0);
while(1) {
tmp13 = 1;
while (tmp14 <= arrayLength(_l_loopVar)) {
_l = arrayGet(_l_loopVar, tmp14++);
if ((!listEmpty(_l))) {
tmp13--;
break;
}
}
if (tmp13 == 0) {
__omcQ_24tmpVar6 = ((modelica_integer) 1);
__omcQ_24tmpVar7 = __omcQ_24tmpVar7 + __omcQ_24tmpVar6;
} else if (tmp13 == 1) {
break;
} else {
goto goto_1;
}
}
tmp12 = __omcQ_24tmpVar7;
}
tmp11 = modelica_integer_to_modelica_string(tmp12, ((modelica_integer) 0), 1);
tmpMeta15 = stringAppend(_OMC_LIT28,tmp11);
tmpMeta16 = stringAppend(tmpMeta15,_OMC_LIT29);
tmp17 = modelica_integer_to_modelica_string(arrayLength(_hvec), ((modelica_integer) 0), 1);
tmpMeta18 = stringAppend(tmpMeta16,tmp17);
tmpMeta19 = stringAppend(tmpMeta18,_OMC_LIT12);
fputs(MMC_STRINGDATA(tmpMeta19),stdout);
{
modelica_integer __omcQ_24tmpVar13;
modelica_integer __omcQ_24tmpVar12;
modelica_integer tmp22;
modelica_metatype _l_loopVar = 0;
modelica_integer tmp23;
modelica_metatype _l;
_l_loopVar = _hvec;
tmp23 = 1;
__omcQ_24tmpVar13 = ((modelica_integer) -4611686018427387903);
while(1) {
tmp22 = 1;
if (tmp23 <= arrayLength(_l_loopVar)) {
_l = arrayGet(_l_loopVar, tmp23++);
tmp22--;
}
if (tmp22 == 0) {
__omcQ_24tmpVar12 = listLength(_l);
__omcQ_24tmpVar13 = modelica_integer_max((modelica_integer)(__omcQ_24tmpVar12),(modelica_integer)(__omcQ_24tmpVar13));
} else if (tmp22 == 1) {
break;
} else {
goto goto_1;
}
}
tmp21 = __omcQ_24tmpVar13;
}
tmp20 = modelica_integer_to_modelica_string(tmp21, ((modelica_integer) 0), 1);
tmpMeta24 = stringAppend(_OMC_LIT30,tmp20);
tmpMeta25 = stringAppend(tmpMeta24,_OMC_LIT12);
fputs(MMC_STRINGDATA(tmpMeta25),stdout);
{
modelica_integer __omcQ_24tmpVar19;
modelica_integer __omcQ_24tmpVar18;
modelica_integer tmp28;
modelica_metatype _l_loopVar = 0;
modelica_integer tmp29;
modelica_metatype _l;
_l_loopVar = _hvec;
tmp29 = 1;
__omcQ_24tmpVar19 = ((modelica_integer) 0);
while(1) {
tmp28 = 1;
if (tmp29 <= arrayLength(_l_loopVar)) {
_l = arrayGet(_l_loopVar, tmp29++);
tmp28--;
}
if (tmp28 == 0) {
__omcQ_24tmpVar18 = listLength(_l);
__omcQ_24tmpVar19 = __omcQ_24tmpVar19 + __omcQ_24tmpVar18;
} else if (tmp28 == 1) {
break;
} else {
goto goto_1;
}
}
tmp27 = __omcQ_24tmpVar19;
}
tmp26 = modelica_integer_to_modelica_string(tmp27, ((modelica_integer) 0), 1);
tmpMeta30 = stringAppend(_OMC_LIT31,tmp26);
tmpMeta31 = stringAppend(tmpMeta30,_OMC_LIT12);
fputs(MMC_STRINGDATA(tmpMeta31),stdout);
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
;
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_BaseHashTable_add(threadData_t *threadData, modelica_metatype _entry, modelica_metatype _hashTable)
{
modelica_metatype _outHashTable = NULL;
modelica_metatype _hashvec = NULL;
modelica_metatype _varr = NULL;
modelica_integer _bsize;
modelica_integer _hash_idx;
modelica_integer _arr_idx;
modelica_integer _new_pos;
modelica_metatype _fntpl = NULL;
modelica_fnptr _hashFunc;
modelica_fnptr _keyEqual;
modelica_metatype _key = NULL;
modelica_metatype _key2 = NULL;
modelica_metatype _val = NULL;
modelica_metatype _indices = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_integer tmp16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _entry;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
_key = tmpMeta2;
tmpMeta3 = _hashTable;
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 1));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 3));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_hashvec = tmpMeta4;
_varr = tmpMeta5;
_bsize = tmp7;
_fntpl = tmpMeta8;
_hashFunc = tmpMeta9;
_keyEqual = tmpMeta10;
_hash_idx = ((modelica_integer) 1) + mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 2))), _key, mmc_mk_integer(_bsize)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_hashFunc), 1)))) (threadData, _key, mmc_mk_integer(_bsize)));
_indices = arrayGet(_hashvec,_hash_idx);
{
modelica_metatype _i;
for (tmpMeta11 = _indices; !listEmpty(tmpMeta11); tmpMeta11=MMC_CDR(tmpMeta11))
{
_i = MMC_CAR(tmpMeta11);
tmpMeta12 = _i;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
_key2 = tmpMeta13;
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqual), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqual), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqual), 2))), _key, _key2) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_keyEqual), 1)))) (threadData, _key, _key2)))
{
tmpMeta14 = _i;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmp16 = mmc_unbox_integer(tmpMeta15);
_arr_idx = tmp16;
omc_BaseHashTable_valueArraySet(threadData, _varr, _arr_idx, _entry);
_outHashTable = _hashTable;
goto _return;
}
}
}
_varr = omc_BaseHashTable_valueArrayAdd(threadData, _varr, _entry ,&_new_pos);
tmpMeta19 = mmc_mk_box2(0, _key, mmc_mk_integer(_new_pos));
tmpMeta18 = mmc_mk_cons(tmpMeta19, _indices);
arrayUpdate(_hashvec, _hash_idx, tmpMeta18);
tmpMeta20 = mmc_mk_box4(0, _hashvec, _varr, mmc_mk_integer(_bsize), _fntpl);
_outHashTable = tmpMeta20;
_return: OMC_LABEL_UNUSED
return _outHashTable;
}
DLLExport
modelica_metatype omc_BaseHashTable_emptyHashTableWork(threadData_t *threadData, modelica_integer _szBucket, modelica_metatype _fntpl)
{
modelica_metatype _hashTable = NULL;
modelica_metatype _arr = NULL;
modelica_metatype _lst = NULL;
modelica_metatype _emptyarr = NULL;
modelica_integer _szArr;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((_szBucket < ((modelica_integer) 1)))
{
tmpMeta1 = stringAppend(_OMC_LIT32,intString(_szBucket));
tmpMeta2 = stringAppend(tmpMeta1,_OMC_LIT33);
omc_Error_addInternalError(threadData, tmpMeta2, _OMC_LIT34);
MMC_THROW_INTERNAL();
}
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_arr = arrayCreate(_szBucket, tmpMeta3);
_szArr = omc_BaseHashTable_bucketToValuesSize(threadData, _szBucket);
_emptyarr = arrayCreate(_szArr, mmc_mk_none());
tmpMeta4 = mmc_mk_box3(0, mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(_szArr), _emptyarr);
tmpMeta5 = mmc_mk_box4(0, _arr, tmpMeta4, mmc_mk_integer(_szBucket), _fntpl);
_hashTable = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _hashTable;
}
modelica_metatype boxptr_BaseHashTable_emptyHashTableWork(threadData_t *threadData, modelica_metatype _szBucket, modelica_metatype _fntpl)
{
modelica_integer tmp1;
modelica_metatype _hashTable = NULL;
tmp1 = mmc_unbox_integer(_szBucket);
_hashTable = omc_BaseHashTable_emptyHashTableWork(threadData, tmp1, _fntpl);
return _hashTable;
}
DLLExport
modelica_integer omc_BaseHashTable_bucketToValuesSize(threadData_t *threadData, modelica_integer _szBucket)
{
modelica_integer _szArr;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_szArr = ((modelica_integer)floor((0.6) * (((modelica_real)_szBucket))));
_return: OMC_LABEL_UNUSED
return _szArr;
}
modelica_metatype boxptr_BaseHashTable_bucketToValuesSize(threadData_t *threadData, modelica_metatype _szBucket)
{
modelica_integer tmp1;
modelica_integer _szArr;
modelica_metatype out_szArr;
tmp1 = mmc_unbox_integer(_szBucket);
_szArr = omc_BaseHashTable_bucketToValuesSize(threadData, tmp1);
out_szArr = mmc_mk_icon(_szArr);
return out_szArr;
}
