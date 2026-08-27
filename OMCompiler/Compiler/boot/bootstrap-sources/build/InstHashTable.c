#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/InstHashTable.c"
#endif
#include "omc_simulation_settings.h"
#include "InstHashTable.h"
#define _OMC_LIT0_data "instCacheSize"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,13,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,4) {&Flags_FlagVisibility_EXTERNAL__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,2,5) {&Flags_FlagData_INT__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(25343))}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "Sets the size of the internal hash table used for instantiation caching."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,72,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(90)),_OMC_LIT0,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT1,_OMC_LIT2,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT4}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "OPAQUE_VALUE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,12,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "Cache"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,5,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "Turns off the instantiation cache."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,34,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT8}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(17)),_OMC_LIT7,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT9}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
#include "util/modelica.h"
#include "InstHashTable_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstHashTable_emptyInstHashTableSized(threadData_t *threadData, modelica_integer _size);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstHashTable_emptyInstHashTableSized(threadData_t *threadData, modelica_metatype _size);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstHashTable_emptyInstHashTableSized,2,0) {(void*) boxptr_InstHashTable_emptyInstHashTableSized,0}};
#define boxvar_InstHashTable_emptyInstHashTableSized MMC_REFSTRUCTLIT(boxvar_lit_InstHashTable_emptyInstHashTableSized)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstHashTable_emptyInstHashTable(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstHashTable_emptyInstHashTable,2,0) {(void*) boxptr_InstHashTable_emptyInstHashTable,0}};
#define boxvar_InstHashTable_emptyInstHashTable MMC_REFSTRUCTLIT(boxvar_lit_InstHashTable_emptyInstHashTable)
PROTECTED_FUNCTION_STATIC modelica_string omc_InstHashTable_opaqVal(threadData_t *threadData, modelica_metatype _v);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InstHashTable_opaqVal,2,0) {(void*) boxptr_InstHashTable_opaqVal,0}};
#define boxvar_InstHashTable_opaqVal MMC_REFSTRUCTLIT(boxvar_lit_InstHashTable_opaqVal)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstHashTable_emptyInstHashTableSized(threadData_t *threadData, modelica_integer _size)
{
modelica_metatype _hashTable = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box4(0, boxvar_AbsynUtil_pathHashMod, boxvar_AbsynUtil_pathEqual, boxvar_AbsynUtil_pathStringDefault, boxvar_InstHashTable_opaqVal);
_hashTable = omc_BaseHashTable_emptyHashTableWork(threadData, _size, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return _hashTable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InstHashTable_emptyInstHashTableSized(threadData_t *threadData, modelica_metatype _size)
{
modelica_integer tmp1;
modelica_metatype _hashTable = NULL;
tmp1 = mmc_unbox_integer(_size);
_hashTable = omc_InstHashTable_emptyInstHashTableSized(threadData, tmp1);
return _hashTable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InstHashTable_emptyInstHashTable(threadData_t *threadData)
{
modelica_metatype _hashTable = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hashTable = omc_InstHashTable_emptyInstHashTableSized(threadData, omc_Flags_getConfigInt(threadData, _OMC_LIT5));
omc_OperatorOverloading_initCache(threadData);
_return: OMC_LABEL_UNUSED
return _hashTable;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_InstHashTable_opaqVal(threadData_t *threadData, modelica_metatype _v)
{
modelica_string _str = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = _OMC_LIT6;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
void omc_InstHashTable_addToInstCache(threadData_t *threadData, modelica_metatype _fullEnvPathPlusClass, modelica_metatype _fullInstOpt, modelica_metatype _partialInstOpt)
{
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _fullInstOpt;
tmp3_2 = _partialInstOpt;
{
modelica_metatype _instHash = NULL;
modelica_metatype _opt = NULL;
modelica_metatype _lst = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 7; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
tmp5 = omc_Flags_isSet(threadData, _OMC_LIT10);
if (0 != tmp5) goto goto_1;
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
tmp3 += 4;
_instHash = getGlobalRoot(((modelica_integer) 9));
tmpMeta[0] = mmc_mk_cons(_fullInstOpt, mmc_mk_cons(_partialInstOpt, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[1] = mmc_mk_box2(0, _fullEnvPathPlusClass, tmpMeta[0]);
_instHash = omc_BaseHashTable_add(threadData, tmpMeta[1], _instHash);
setGlobalRoot(((modelica_integer) 9), _instHash);
goto tmp2_done;
}
case 2: {
if (!optionNone(tmp3_1)) goto tmp2_end;
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
_instHash = getGlobalRoot(((modelica_integer) 9));
tmpMeta[0] = omc_BaseHashTable_get(threadData, _fullEnvPathPlusClass, _instHash);
if (listEmpty(tmpMeta[0])) goto goto_1;
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (listEmpty(tmpMeta[2])) goto goto_1;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto goto_1;
_opt = tmpMeta[1];
tmpMeta[0] = mmc_mk_cons(_opt, mmc_mk_cons(_partialInstOpt, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[1] = mmc_mk_box2(0, _fullEnvPathPlusClass, tmpMeta[0]);
_instHash = omc_BaseHashTable_add(threadData, tmpMeta[1], _instHash);
setGlobalRoot(((modelica_integer) 9), _instHash);
goto tmp2_done;
}
case 3: {
if (!optionNone(tmp3_1)) goto tmp2_end;
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
tmp3 += 2;
_instHash = getGlobalRoot(((modelica_integer) 9));
tmpMeta[0] = mmc_mk_cons(mmc_mk_none(), mmc_mk_cons(_partialInstOpt, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[1] = mmc_mk_box2(0, _fullEnvPathPlusClass, tmpMeta[0]);
_instHash = omc_BaseHashTable_add(threadData, tmpMeta[1], _instHash);
setGlobalRoot(((modelica_integer) 9), _instHash);
goto tmp2_done;
}
case 4: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (!optionNone(tmp3_2)) goto tmp2_end;
_instHash = getGlobalRoot(((modelica_integer) 9));
tmpMeta[0] = omc_BaseHashTable_get(threadData, _fullEnvPathPlusClass, _instHash);
if (listEmpty(tmpMeta[0])) goto goto_1;
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (listEmpty(tmpMeta[2])) goto goto_1;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (optionNone(tmpMeta[3])) goto goto_1;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
if (!listEmpty(tmpMeta[4])) goto goto_1;
_lst = tmpMeta[2];
tmpMeta[0] = mmc_mk_cons(_fullInstOpt, _lst);
tmpMeta[1] = mmc_mk_box2(0, _fullEnvPathPlusClass, tmpMeta[0]);
_instHash = omc_BaseHashTable_add(threadData, tmpMeta[1], _instHash);
setGlobalRoot(((modelica_integer) 9), _instHash);
goto tmp2_done;
}
case 5: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (!optionNone(tmp3_2)) goto tmp2_end;
_instHash = getGlobalRoot(((modelica_integer) 9));
tmpMeta[0] = mmc_mk_cons(_fullInstOpt, mmc_mk_cons(mmc_mk_none(), MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[1] = mmc_mk_box2(0, _fullEnvPathPlusClass, tmpMeta[0]);
_instHash = omc_BaseHashTable_add(threadData, tmpMeta[1], _instHash);
setGlobalRoot(((modelica_integer) 9), _instHash);
goto tmp2_done;
}
case 6: {
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
if (++tmp3 < 7) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
;
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_InstHashTable_get(threadData_t *threadData, modelica_metatype _k)
{
modelica_metatype _v = NULL;
modelica_metatype _ht = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ht = getGlobalRoot(((modelica_integer) 9));
_v = omc_BaseHashTable_get(threadData, _k, _ht);
_return: OMC_LABEL_UNUSED
return _v;
}
DLLExport
void omc_InstHashTable_release(threadData_t *threadData)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
setGlobalRoot(((modelica_integer) 9), omc_InstHashTable_emptyInstHashTable(threadData));
omc_OperatorOverloading_initCache(threadData);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_InstHashTable_init(threadData_t *threadData)
{
modelica_metatype _ht = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_ht = getGlobalRoot(((modelica_integer) 9));
_ht = omc_BaseHashTable_clear(threadData, _ht);
setGlobalRoot(((modelica_integer) 9), _ht);
goto tmp2_done;
}
case 1: {
setGlobalRoot(((modelica_integer) 9), omc_InstHashTable_emptyInstHashTable(threadData));
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
;
_return: OMC_LABEL_UNUSED
return;
}
