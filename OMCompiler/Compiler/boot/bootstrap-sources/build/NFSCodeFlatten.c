#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/NFSCodeFlatten.c"
#endif
#include "omc_simulation_settings.h"
#include "NFSCodeFlatten.h"
#include "util/modelica.h"
#include "NFSCodeFlatten_includes.h"
DLLExport
modelica_metatype omc_NFSCodeFlatten_flattenClassInProgram(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype __omcQ_24in_5FinProgram, modelica_integer *out_dummy)
{
modelica_metatype _inProgram = NULL;
modelica_integer _dummy;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_inProgram = __omcQ_24in_5FinProgram;
_return: OMC_LABEL_UNUSED
if (out_dummy) { *out_dummy = _dummy; }
return _inProgram;
}
modelica_metatype boxptr_NFSCodeFlatten_flattenClassInProgram(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype __omcQ_24in_5FinProgram, modelica_metatype *out_dummy)
{
modelica_integer _dummy;
modelica_metatype _inProgram = NULL;
_inProgram = omc_NFSCodeFlatten_flattenClassInProgram(threadData, _inPath, __omcQ_24in_5FinProgram, &_dummy);
if (out_dummy) { *out_dummy = mmc_mk_icon(_dummy); }
return _inProgram;
}
DLLExport
modelica_metatype omc_NFSCodeFlatten_flattenCompleteProgram(threadData_t *threadData, modelica_metatype __omcQ_24in_5FinProgram)
{
modelica_metatype _inProgram = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_inProgram = __omcQ_24in_5FinProgram;
_return: OMC_LABEL_UNUSED
return _inProgram;
}
