#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/HashTableCrToExpOption.c"
#endif
#include "omc_simulation_settings.h"
#include "HashTableCrToExpOption.h"
#define _OMC_LIT0_data "SOME("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,5,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "NONE()"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,6,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#include "util/modelica.h"
#include "HashTableCrToExpOption_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_integer omc_HashTableCrToExpOption_calcHashValue(threadData_t *threadData, modelica_metatype _cr, modelica_integer _imod);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_HashTableCrToExpOption_calcHashValue(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _imod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCrToExpOption_calcHashValue,2,0) {(void*) boxptr_HashTableCrToExpOption_calcHashValue,0}};
#define boxvar_HashTableCrToExpOption_calcHashValue MMC_REFSTRUCTLIT(boxvar_lit_HashTableCrToExpOption_calcHashValue)
PROTECTED_FUNCTION_STATIC modelica_string omc_HashTableCrToExpOption_printExpOtionStr(threadData_t *threadData, modelica_metatype _expOpt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableCrToExpOption_printExpOtionStr,2,0) {(void*) boxptr_HashTableCrToExpOption_printExpOtionStr,0}};
#define boxvar_HashTableCrToExpOption_printExpOtionStr MMC_REFSTRUCTLIT(boxvar_lit_HashTableCrToExpOption_printExpOtionStr)
PROTECTED_FUNCTION_STATIC modelica_integer omc_HashTableCrToExpOption_calcHashValue(threadData_t *threadData, modelica_metatype _cr, modelica_integer _imod)
{
modelica_integer _value;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_value = stringHashDjb2Mod(omc_ComponentReference_printComponentRefStr(threadData, _cr), _imod);
_return: OMC_LABEL_UNUSED
return _value;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_HashTableCrToExpOption_calcHashValue(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _imod)
{
modelica_integer tmp1;
modelica_integer _value;
modelica_metatype out_value;
tmp1 = mmc_unbox_integer(_imod);
_value = omc_HashTableCrToExpOption_calcHashValue(threadData, _cr, tmp1);
out_value = mmc_mk_icon(_value);
return out_value;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_HashTableCrToExpOption_printExpOtionStr(threadData_t *threadData, modelica_metatype _expOpt)
{
modelica_string _outStr = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _expOpt;
{
modelica_metatype _exp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_exp = tmpMeta[0];
tmpMeta[0] = stringAppend(_OMC_LIT0,omc_ExpressionDump_printExpStr(threadData, _exp));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT1);
tmp1 = tmpMeta[1];
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT2;
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
_outStr = tmp1;
_return: OMC_LABEL_UNUSED
return _outStr;
}
DLLExport
modelica_metatype omc_HashTableCrToExpOption_emptyHashTableSized(threadData_t *threadData, modelica_integer _size)
{
modelica_metatype _hashTable = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box4(0, boxvar_ComponentReference_hashComponentRefMod, boxvar_ComponentReference_crefEqual, boxvar_ComponentReference_printComponentRefStr, boxvar_HashTableCrToExpOption_printExpOtionStr);
_hashTable = omc_BaseHashTable_emptyHashTableWork(threadData, _size, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return _hashTable;
}
modelica_metatype boxptr_HashTableCrToExpOption_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size)
{
modelica_integer tmp1;
modelica_metatype _hashTable = NULL;
tmp1 = mmc_unbox_integer(_size);
_hashTable = omc_HashTableCrToExpOption_emptyHashTableSized(threadData, tmp1);
return _hashTable;
}
DLLExport
modelica_metatype omc_HashTableCrToExpOption_emptyHashTable(threadData_t *threadData)
{
modelica_metatype _hashTable = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hashTable = omc_HashTableCrToExpOption_emptyHashTableSized(threadData, ((modelica_integer) 2053));
_return: OMC_LABEL_UNUSED
return _hashTable;
}
