#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/NFUnitCheck.c"
#endif
#include "omc_simulation_settings.h"
#include "NFUnitCheck.h"
#include "util/modelica.h"
#include "NFUnitCheck_includes.h"
DLLExport
modelica_metatype omc_NFUnitCheck_checkUnits(threadData_t *threadData, modelica_metatype _inDAE, modelica_metatype _func)
{
modelica_metatype _outDAE = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outDAE = _inDAE;
goto _return;
_return: OMC_LABEL_UNUSED
return _outDAE;
}
