#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/DAEToMid.c"
#endif
#include "omc_simulation_settings.h"
#include "DAEToMid.h"
#define _OMC_LIT0_data "DAEToMid.DAEFunctionsToMid is stubbed away"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,42,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#include "util/modelica.h"
#include "DAEToMid_includes.h"
DLLExport
modelica_metatype omc_DAEToMid_DAEFunctionsToMid(threadData_t *threadData, modelica_metatype _simfuncs)
{
modelica_metatype _midfuncs = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/DAEToMid.mo",38,3,38,56,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
return _midfuncs;
}
