#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/NFInstDump.c"
#endif
#include "omc_simulation_settings.h"
#include "NFInstDump.h"
#define _OMC_LIT0_data "NFInstDump.dumpUntypedComponentDims"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,35,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "NFInstDump.prefixStr"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,20,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#include "util/modelica.h"
#include "NFInstDump_includes.h"
DLLExport
modelica_string omc_NFInstDump_dumpUntypedComponentDims(threadData_t *threadData, modelica_metatype _inComponent)
{
modelica_string _outString = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/NFInstDump.mo",14,3,14,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_NFInstDump_prefixStr(threadData_t *threadData, modelica_metatype _inPrefix)
{
modelica_string _outString = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/NFInstDump.mo",7,3,7,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT1));
}
}
}
_return: OMC_LABEL_UNUSED
return _outString;
}
