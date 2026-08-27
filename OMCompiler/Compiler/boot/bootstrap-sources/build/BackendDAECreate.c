#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/BackendDAECreate.c"
#endif
#include "omc_simulation_settings.h"
#include "BackendDAECreate.h"
#define _OMC_LIT0_data "BackendDAECreate.lower"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,22,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#include "util/modelica.h"
#include "BackendDAECreate_includes.h"
DLLExport
modelica_metatype omc_BackendDAECreate_lower(threadData_t *threadData, modelica_metatype _a, modelica_metatype _b, modelica_metatype _c, modelica_metatype _d)
{
modelica_metatype _outBackendDAE = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/BackendDAECreate.mo",12,3,12,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
return _outBackendDAE;
}
