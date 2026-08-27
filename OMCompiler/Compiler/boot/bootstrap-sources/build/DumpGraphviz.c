#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/DumpGraphviz.c"
#endif
#include "omc_simulation_settings.h"
#include "DumpGraphviz.h"
#define _OMC_LIT0_data "DumpGraphviz.dump"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,17,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#include "util/modelica.h"
#include "DumpGraphviz_includes.h"
DLLExport
void omc_DumpGraphviz_dump(threadData_t *threadData, modelica_metatype _p)
{
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/DumpGraphviz.mo",6,3,6,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
return;
}
