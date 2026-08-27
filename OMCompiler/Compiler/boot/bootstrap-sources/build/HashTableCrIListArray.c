#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/HashTableCrIListArray.c"
#endif
#include "omc_simulation_settings.h"
#include "HashTableCrIListArray.h"
#define _OMC_LIT0_data "["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,1,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "] {"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,3,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,1,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#include "util/modelica.h"
#include "HashTableCrIListArray_includes.h"
DLLExport
modelica_string omc_HashTableCrIListArray_printIntListArrayStr(threadData_t *threadData, modelica_metatype _iValue)
{
modelica_string _res = NULL;
modelica_metatype _iList = NULL;
modelica_metatype _iArray = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _iValue;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_iList = tmpMeta[1];
_iArray = tmpMeta[2];
tmpMeta[0] = stringAppend(_OMC_LIT0,stringDelimitList(omc_List_map(threadData, _iList, boxvar_intString), _OMC_LIT1));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT2);
tmpMeta[2] = stringAppend(tmpMeta[1],stringDelimitList(omc_List_map(threadData, arrayList(_iArray), boxvar_intString), _OMC_LIT1));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT3);
_res = tmpMeta[3];
_return: OMC_LABEL_UNUSED
return _res;
}
DLLExport
modelica_metatype omc_HashTableCrIListArray_emptyHashTableSized(threadData_t *threadData, modelica_integer _size)
{
modelica_metatype _hashTable = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box4(0, boxvar_ComponentReference_hashComponentRefMod, boxvar_ComponentReference_crefEqual, boxvar_ComponentReference_printComponentRefStr, boxvar_HashTableCrIListArray_printIntListArrayStr);
_hashTable = omc_BaseHashTable_emptyHashTableWork(threadData, _size, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return _hashTable;
}
modelica_metatype boxptr_HashTableCrIListArray_emptyHashTableSized(threadData_t *threadData, modelica_metatype _size)
{
modelica_integer tmp1;
modelica_metatype _hashTable = NULL;
tmp1 = mmc_unbox_integer(_size);
_hashTable = omc_HashTableCrIListArray_emptyHashTableSized(threadData, tmp1);
return _hashTable;
}
DLLExport
modelica_metatype omc_HashTableCrIListArray_emptyHashTable(threadData_t *threadData)
{
modelica_metatype _hashTable = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hashTable = omc_HashTableCrIListArray_emptyHashTableSized(threadData, ((modelica_integer) 2053));
_return: OMC_LABEL_UNUSED
return _hashTable;
}
