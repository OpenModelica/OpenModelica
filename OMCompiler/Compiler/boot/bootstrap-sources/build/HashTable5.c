#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/HashTable5.c"
#endif
#include "omc_simulation_settings.h"
#include "HashTable5.h"
#include "util/modelica.h"
#include "HashTable5_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_integer omc_HashTable5_hashFunc(threadData_t *threadData, modelica_metatype _cr, modelica_integer _mod);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_HashTable5_hashFunc(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _mod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_HashTable5_hashFunc,2,0) {(void*) boxptr_HashTable5_hashFunc,0}};
#define boxvar_HashTable5_hashFunc MMC_REFSTRUCTLIT(boxvar_lit_HashTable5_hashFunc)
DLLExport
modelica_metatype omc_HashTable5_emptyHashTableSized(threadData_t *threadData, modelica_integer _size)
{
modelica_metatype _hashTable = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box4(0, boxvar_HashTable5_hashFunc, boxvar_AbsynUtil_crefEqual, boxvar_Dump_printComponentRefStr, boxvar_intString);
_hashTable = omc_BaseHashTable_emptyHashTableWork(threadData, _size, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return _hashTable;
}
modelica_metatype boxptr_HashTable5_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size)
{
modelica_integer tmp1;
modelica_metatype _hashTable = NULL;
tmp1 = mmc_unbox_integer(_size);
_hashTable = omc_HashTable5_emptyHashTableSized(threadData, tmp1);
return _hashTable;
}
DLLExport
modelica_metatype omc_HashTable5_emptyHashTable(threadData_t *threadData)
{
modelica_metatype _hashTable = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hashTable = omc_HashTable5_emptyHashTableSized(threadData, ((modelica_integer) 2053));
_return: OMC_LABEL_UNUSED
return _hashTable;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_HashTable5_hashFunc(threadData_t *threadData, modelica_metatype _cr, modelica_integer _mod)
{
modelica_integer _res;
modelica_string _crstr = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_crstr = omc_Dump_printComponentRefStr(threadData, _cr);
_res = stringHashDjb2Mod(_crstr, _mod);
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_HashTable5_hashFunc(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _mod)
{
modelica_integer tmp1;
modelica_integer _res;
modelica_metatype out_res;
tmp1 = mmc_unbox_integer(_mod);
_res = omc_HashTable5_hashFunc(threadData, _cr, tmp1);
out_res = mmc_mk_icon(_res);
return out_res;
}
