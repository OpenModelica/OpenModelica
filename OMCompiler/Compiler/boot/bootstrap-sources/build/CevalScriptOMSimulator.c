#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/CevalScriptOMSimulator.c"
#endif
#include "omc_simulation_settings.h"
#include "CevalScriptOMSimulator.h"
#include "util/modelica.h"
#include "CevalScriptOMSimulator_includes.h"
DLLExport
modelica_metatype omc_CevalScriptOMSimulator_ceval(threadData_t *threadData, modelica_string _inFunctionName, modelica_metatype _inVals)
{
modelica_metatype _outValue = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return _outValue;
}
