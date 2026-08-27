#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/BackendDAEUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "BackendDAEUtil.h"
#define _OMC_LIT0_data "BackendDAEUtil.getAllVarLst"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,27,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "BackendDAEUtil.getAdjacencyMatrixfromOption"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,43,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "BackendDAEUtil.transformBackendDAE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,34,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "BackendDAEUtil.preOptimizeBackendDAE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,36,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "BackendDAEUtil.getSolvedSystem"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,30,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#include "util/modelica.h"
#include "BackendDAEUtil_includes.h"
DLLExport
modelica_metatype omc_BackendDAEUtil_getAllVarLst(threadData_t *threadData, modelica_metatype _dae)
{
modelica_metatype _varLst = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/BackendDAEUtil.mo",54,3,54,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
return _varLst;
}
DLLExport
modelica_metatype omc_BackendDAEUtil_getAdjacencyMatrixfromOption(threadData_t *threadData, modelica_metatype _inSyst, modelica_metatype _inIndxType, modelica_metatype _inFunctionTree, modelica_metatype *out_outM, modelica_metatype *out_outMT)
{
modelica_metatype _outSyst = NULL;
modelica_metatype _outM = NULL;
modelica_metatype _outMT = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/BackendDAEUtil.mo",47,3,47,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT1));
}
}
}
_return: OMC_LABEL_UNUSED
if (out_outM) { *out_outM = _outM; }
if (out_outMT) { *out_outMT = _outMT; }
return _outSyst;
}
DLLExport
modelica_metatype omc_BackendDAEUtil_transformBackendDAE(threadData_t *threadData, modelica_metatype _inDAE, modelica_metatype _inMatchingOptions, modelica_metatype _strmatchingAlgorithm, modelica_metatype _strindexReductionMethod)
{
modelica_metatype _outDAE = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/BackendDAEUtil.mo",36,3,36,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT2));
}
}
}
_return: OMC_LABEL_UNUSED
return _outDAE;
}
DLLExport
modelica_metatype omc_BackendDAEUtil_preOptimizeBackendDAE(threadData_t *threadData, modelica_metatype _inDAE, modelica_metatype _strPreOptModules)
{
modelica_metatype _outDAE = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/BackendDAEUtil.mo",26,3,26,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT3));
}
}
}
_return: OMC_LABEL_UNUSED
return _outDAE;
}
DLLExport
modelica_metatype omc_BackendDAEUtil_getSolvedSystem(threadData_t *threadData, modelica_metatype _inDAE, modelica_string _fileNamePrefix, modelica_metatype _strPreOptModules, modelica_metatype _strmatchingAlgorithm, modelica_metatype _strdaeHandler, modelica_metatype _strPostOptModules, modelica_metatype *out_outInitDAE, modelica_metatype *out_outInitDAE_lambda0, modelica_metatype *out_inlineData, modelica_metatype *out_outRemovedInitialEquationLst)
{
modelica_metatype _outSODE = NULL;
modelica_metatype _outInitDAE = NULL;
modelica_metatype _outInitDAE_lambda0 = NULL;
modelica_metatype _inlineData = NULL;
modelica_metatype _outRemovedInitialEquationLst = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/BackendDAEUtil.mo",18,3,18,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT4));
}
}
}
_return: OMC_LABEL_UNUSED
if (out_outInitDAE) { *out_outInitDAE = _outInitDAE; }
if (out_outInitDAE_lambda0) { *out_outInitDAE_lambda0 = _outInitDAE_lambda0; }
if (out_inlineData) { *out_inlineData = _inlineData; }
if (out_outRemovedInitialEquationLst) { *out_outRemovedInitialEquationLst = _outRemovedInitialEquationLst; }
return _outSODE;
}
