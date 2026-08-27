#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/UnitChecker.c"
#endif
#include "omc_simulation_settings.h"
#include "UnitChecker.h"
#define _OMC_LIT0_data "UnitChecker.isComplete"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,22,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "UnitChecker.check"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,17,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#include "util/modelica.h"
#include "UnitChecker_includes.h"
DLLExport
modelica_boolean omc_UnitChecker_isComplete(threadData_t *threadData, modelica_metatype _st, modelica_metatype *out_stout)
{
modelica_boolean _complete;
modelica_metatype _stout = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/UnitChecker.mo",16,3,16,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
if (out_stout) { *out_stout = _stout; }
return _complete;
}
modelica_metatype boxptr_UnitChecker_isComplete(threadData_t *threadData, modelica_metatype _st, modelica_metatype *out_stout)
{
modelica_boolean _complete;
modelica_metatype out_complete;
_complete = omc_UnitChecker_isComplete(threadData, _st, out_stout);
out_complete = mmc_mk_icon(_complete);
return out_complete;
}
DLLExport
modelica_metatype omc_UnitChecker_check(threadData_t *threadData, modelica_metatype _tms, modelica_metatype _ist)
{
modelica_metatype _outSt = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/UnitChecker.mo",8,3,8,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT1));
}
}
}
_return: OMC_LABEL_UNUSED
return _outSt;
}
