#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "HashTableCrILst.c"
#endif
#include "omc_simulation_settings.h"
#include "HashTableCrILst.h"
#define _OMC_LIT0_data "{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,1,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,1,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#include "util/modelica.h"
#include "HashTableCrILst_includes.h"
DLLExport
modelica_string omc_HashTableCrILst_printIntListStr(threadData_t *threadData, modelica_metatype _ilst)
{
modelica_string _res = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_OMC_LIT0,stringDelimitList(omc_List_map(threadData, _ilst, boxvar_intString), _OMC_LIT1));
tmpMeta2 = stringAppend(tmpMeta1,_OMC_LIT2);
_res = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _res;
}
DLLExport
modelica_metatype omc_HashTableCrILst_emptyHashTableSized(threadData_t *threadData, modelica_integer _size)
{
modelica_metatype _hashTable = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box4(0, boxvar_ComponentReference_hashComponentRefMod, boxvar_ComponentReference_crefEqual, boxvar_ComponentReference_printComponentRefStr, boxvar_HashTableCrILst_printIntListStr);
_hashTable = omc_BaseHashTable_emptyHashTableWork(threadData, _size, tmpMeta1);
_return: OMC_LABEL_UNUSED
return _hashTable;
}
modelica_metatype boxptr_HashTableCrILst_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size)
{
modelica_integer tmp1;
modelica_metatype _hashTable = NULL;
tmp1 = mmc_unbox_integer(_size);
_hashTable = omc_HashTableCrILst_emptyHashTableSized(threadData, tmp1);
return _hashTable;
}
DLLExport
modelica_metatype omc_HashTableCrILst_emptyHashTable(threadData_t *threadData)
{
modelica_metatype _hashTable = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hashTable = omc_HashTableCrILst_emptyHashTableSized(threadData, ((modelica_integer) 2053));
_return: OMC_LABEL_UNUSED
return _hashTable;
}
