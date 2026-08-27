#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/NFApi.c"
#endif
#include "omc_simulation_settings.h"
#include "NFApi.h"
#define _OMC_LIT0_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,0,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#include "util/modelica.h"
#include "NFApi_includes.h"
DLLExport
modelica_metatype omc_NFApi_mkFullyQual(threadData_t *threadData, modelica_metatype _absynProgram, modelica_metatype _classPath, modelica_metatype _pathToQualify)
{
modelica_metatype _qualPath = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_qualPath = _pathToQualify;
_return: OMC_LABEL_UNUSED
return _qualPath;
}
DLLExport
modelica_metatype omc_NFApi_evaluateAnnotations(threadData_t *threadData, modelica_metatype _absynProgram, modelica_metatype _classPath, modelica_metatype _inElements)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outStringLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outStringLst;
}
DLLExport
modelica_string omc_NFApi_evaluateAnnotation(threadData_t *threadData, modelica_metatype _absynProgram, modelica_metatype _classPath, modelica_metatype _inAnnotation)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = _OMC_LIT0;
_return: OMC_LABEL_UNUSED
return _outString;
}
