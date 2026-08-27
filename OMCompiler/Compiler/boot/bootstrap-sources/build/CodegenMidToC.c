#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/CodegenMidToC.c"
#endif
#include "omc_simulation_settings.h"
#include "CodegenMidToC.h"
#define _OMC_LIT0_data "MidToC not enabled with stubs"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,29,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#include "util/modelica.h"
#include "CodegenMidToC_includes.h"
DLLExport
modelica_metatype omc_CodegenMidToC_genProgram(threadData_t *threadData, modelica_metatype _in_txt, modelica_metatype _in_a_p)
{
modelica_metatype _out_txt = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/CodegenMidToC.mo",13,3,13,49,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
return _out_txt;
}
