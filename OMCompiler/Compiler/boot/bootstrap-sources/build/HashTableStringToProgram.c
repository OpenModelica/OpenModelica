#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/HashTableStringToProgram.c"
#endif
#include "omc_simulation_settings.h"
#include "HashTableStringToProgram.h"
#define _OMC_LIT0_data "<dummy Absyn.Program string>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,28,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#include "util/modelica.h"
#include "HashTableStringToProgram_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_string omc_HashTableStringToProgram_dummyStr(threadData_t *threadData, modelica_metatype _p);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTableStringToProgram_dummyStr,2,0) {(void*) boxptr_HashTableStringToProgram_dummyStr,0}};
#define boxvar_HashTableStringToProgram_dummyStr MMC_REFSTRUCTLIT(boxvar_lit_HashTableStringToProgram_dummyStr)
PROTECTED_FUNCTION_STATIC modelica_string omc_HashTableStringToProgram_dummyStr(threadData_t *threadData, modelica_metatype _p)
{
modelica_string _str = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = _OMC_LIT0;
_return: OMC_LABEL_UNUSED
return _str;
}
DLLExport
modelica_metatype omc_HashTableStringToProgram_emptyHashTableSized(threadData_t *threadData, modelica_integer _size)
{
modelica_metatype _hashTable = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box4(0, boxvar_stringHashDjb2Mod, boxvar_stringEq, boxvar_Util_id, boxvar_HashTableStringToProgram_dummyStr);
_hashTable = omc_BaseHashTable_emptyHashTableWork(threadData, _size, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return _hashTable;
}
modelica_metatype boxptr_HashTableStringToProgram_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size)
{
modelica_integer tmp1;
modelica_metatype _hashTable = NULL;
tmp1 = mmc_unbox_integer(_size);
_hashTable = omc_HashTableStringToProgram_emptyHashTableSized(threadData, tmp1);
return _hashTable;
}
DLLExport
modelica_metatype omc_HashTableStringToProgram_emptyHashTable(threadData_t *threadData)
{
modelica_metatype _hashTable = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hashTable = omc_HashTableStringToProgram_emptyHashTableSized(threadData, ((modelica_integer) 2053));
_return: OMC_LABEL_UNUSED
return _hashTable;
}
