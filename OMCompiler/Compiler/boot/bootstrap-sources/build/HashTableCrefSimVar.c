#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "HashTableCrefSimVar.c"
#endif
#include "omc_simulation_settings.h"
#include "HashTableCrefSimVar.h"
#define _OMC_LIT0_data "function addSimVarToHashTable failed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,36,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "HashTableCrefSimVar.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,22,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT2_6,0.0);
#define _OMC_LIT2_6 MMC_REFREALLIT(_OMC_LIT_STRUCT2_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT1,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(142)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(142)),MMC_IMMEDIATE(MMC_TAGFIXNUM(85)),_OMC_LIT2_6}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "#SimVar(index="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,14,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data ",name="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,6,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data ")#"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,2,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#include "util/modelica.h"
#include "HashTableCrefSimVar_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_string omc_HashTableCrefSimVar_opaqueStr(threadData_t *threadData, modelica_metatype _var);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCrefSimVar_opaqueStr,2,0) {(void*) boxptr_HashTableCrefSimVar_opaqueStr,0}};
#define boxvar_HashTableCrefSimVar_opaqueStr MMC_REFSTRUCTLIT(boxvar_lit_HashTableCrefSimVar_opaqueStr)
DLLExport
modelica_metatype omc_HashTableCrefSimVar_addSimVarToHashTable(threadData_t *threadData, modelica_metatype _simvarIn, modelica_metatype _inHT)
{
modelica_metatype _outHT = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _simvarIn;
{
modelica_metatype _cr = NULL;
modelica_metatype _acr = NULL;
modelica_metatype _sv = NULL;
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
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 15));
if (!optionNone(tmpMeta7)) goto tmp3_end;
_sv = tmp4_1;
_cr = tmpMeta6;
tmp4 += 1;
tmpMeta8 = mmc_mk_box2(0, _cr, _sv);
tmpMeta1 = omc_BaseHashTable_add(threadData, tmpMeta8, _inHT);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 15));
if (optionNone(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
_sv = tmp4_1;
_cr = tmpMeta9;
_acr = tmpMeta11;
tmpMeta12 = mmc_mk_box2(0, _acr, _sv);
_outHT = omc_BaseHashTable_add(threadData, tmpMeta12, _inHT);
tmpMeta13 = mmc_mk_box2(0, _cr, _sv);
tmpMeta1 = omc_BaseHashTable_add(threadData, tmpMeta13, _outHT);
goto tmp3_done;
}
case 2: {
omc_Error_addInternalError(threadData, _OMC_LIT0, _OMC_LIT2);
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
_outHT = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outHT;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_HashTableCrefSimVar_opaqueStr(threadData_t *threadData, modelica_metatype _var)
{
modelica_string _str = NULL;
modelica_string tmp1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = modelica_integer_to_modelica_string(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_var), 7)))), ((modelica_integer) 0), 1);
tmpMeta2 = stringAppend(_OMC_LIT3,tmp1);
tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT4);
tmpMeta4 = stringAppend(tmpMeta3,omc_ComponentReference_printComponentRefStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_var), 2)))));
tmpMeta5 = stringAppend(tmpMeta4,_OMC_LIT5);
_str = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_metatype omc_HashTableCrefSimVar_emptyHashTableSized(threadData_t *threadData, modelica_integer _size)
{
modelica_metatype _hashTable = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box4(0, boxvar_ComponentReference_hashComponentRefMod, boxvar_ComponentReference_crefEqual, boxvar_ComponentReference_printComponentRefStr, boxvar_HashTableCrefSimVar_opaqueStr);
_hashTable = omc_BaseHashTable_emptyHashTableWork(threadData, _size, tmpMeta1);
_return: OMC_LABEL_UNUSED
return _hashTable;
}
modelica_metatype boxptr_HashTableCrefSimVar_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size)
{
modelica_integer tmp1;
modelica_metatype _hashTable = NULL;
tmp1 = mmc_unbox_integer(_size);
_hashTable = omc_HashTableCrefSimVar_emptyHashTableSized(threadData, tmp1);
return _hashTable;
}
DLLExport
modelica_metatype omc_HashTableCrefSimVar_emptyHashTable(threadData_t *threadData)
{
modelica_metatype _hashTable = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hashTable = omc_HashTableCrefSimVar_emptyHashTableSized(threadData, ((modelica_integer) 2053));
_return: OMC_LABEL_UNUSED
return _hashTable;
}
