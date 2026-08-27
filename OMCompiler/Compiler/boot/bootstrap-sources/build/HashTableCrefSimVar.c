#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/HashTableCrefSimVar.c"
#endif
#include "omc_simulation_settings.h"
#include "HashTableCrefSimVar.h"
#define _OMC_LIT0_data "function addSimVarToHashTable failed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,36,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Util/HashTableCrefSimVar.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,76,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT2_6,1591169649.0);
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _simvarIn;
{
modelica_metatype _cr = NULL;
modelica_metatype _acr = NULL;
modelica_metatype _sv = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 15));
if (!optionNone(tmpMeta[2])) goto tmp2_end;
_sv = tmp3_1;
_cr = tmpMeta[1];
tmp3 += 1;
tmpMeta[1] = mmc_mk_box2(0, _cr, _sv);
tmpMeta[0] = omc_BaseHashTable_add(threadData, tmpMeta[1], _inHT);
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 15));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_sv = tmp3_1;
_cr = tmpMeta[1];
_acr = tmpMeta[3];
tmpMeta[1] = mmc_mk_box2(0, _acr, _sv);
_outHT = omc_BaseHashTable_add(threadData, tmpMeta[1], _inHT);
tmpMeta[1] = mmc_mk_box2(0, _cr, _sv);
tmpMeta[0] = omc_BaseHashTable_add(threadData, tmpMeta[1], _outHT);
goto tmp2_done;
}
case 2: {
omc_Error_addInternalError(threadData, _OMC_LIT0, _OMC_LIT2);
goto goto_1;
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
if (++tmp3 < 3) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outHT = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outHT;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_HashTableCrefSimVar_opaqueStr(threadData_t *threadData, modelica_metatype _var)
{
modelica_string _str = NULL;
modelica_string tmp1;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = modelica_integer_to_modelica_string(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_var), 7)))), ((modelica_integer) 0), 1);
tmpMeta[0] = stringAppend(_OMC_LIT3,tmp1);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT4);
tmpMeta[2] = stringAppend(tmpMeta[1],omc_ComponentReference_printComponentRefStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_var), 2)))));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT5);
_str = tmpMeta[3];
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_metatype omc_HashTableCrefSimVar_emptyHashTableSized(threadData_t *threadData, modelica_integer _size)
{
modelica_metatype _hashTable = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box4(0, boxvar_ComponentReference_hashComponentRefMod, boxvar_ComponentReference_crefEqual, boxvar_ComponentReference_printComponentRefStr, boxvar_HashTableCrefSimVar_opaqueStr);
_hashTable = omc_BaseHashTable_emptyHashTableWork(threadData, _size, tmpMeta[0]);
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
