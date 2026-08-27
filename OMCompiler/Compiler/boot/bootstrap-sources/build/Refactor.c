#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Refactor.c"
#endif
#include "omc_simulation_settings.h"
#include "Refactor.h"
#define _OMC_LIT0_data "Refactor.refactorGraphicalAnnotation"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,36,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#include "util/modelica.h"
#include "Refactor_includes.h"
DLLExport
modelica_metatype omc_Refactor_refactorGraphicalAnnotation(threadData_t *threadData, modelica_metatype _wholeAST, modelica_metatype _classToRefactor)
{
modelica_metatype _changedClass = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/Refactor.mo",8,3,8,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
return _changedClass;
}
