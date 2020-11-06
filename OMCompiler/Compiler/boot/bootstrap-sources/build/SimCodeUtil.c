#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/SimCodeUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "SimCodeUtil.h"
#define _OMC_LIT0_data "SimCodeUtil.hashEqSystemMod"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,27,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "SimCodeUtil.localCref2Index"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,27,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "SimCodeUtil.localCref2SimVar"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,28,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "SimCodeUtil.simVarFromHT"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,24,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "SimCodeUtil.cref2simvar"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,23,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "SimCodeUtil.getSimCode"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,22,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "SimCodeUtil.eqInfo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,18,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "SimCodeUtil.sortEqSystems"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,25,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#include "util/modelica.h"
#include "SimCodeUtil_includes.h"
DLLExport
modelica_integer omc_SimCodeUtil_hashEqSystemMod(threadData_t *threadData, modelica_integer _eq, modelica_integer _mod)
{
modelica_integer _hash;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hash = ((modelica_integer) 0);
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/SimCodeUtil.mo",90,3,90,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
return _hash;
}
modelica_metatype boxptr_SimCodeUtil_hashEqSystemMod(threadData_t *threadData, modelica_metatype _eq, modelica_metatype _mod)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer _hash;
modelica_metatype out_hash;
tmp1 = mmc_unbox_integer(_eq);
tmp2 = mmc_unbox_integer(_mod);
_hash = omc_SimCodeUtil_hashEqSystemMod(threadData, tmp1, tmp2);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
DLLExport
modelica_string omc_SimCodeUtil_getLocalValueReference(threadData_t *threadData, modelica_metatype _inSimVar, modelica_integer _inSimCode, modelica_metatype _inCrefToSimVarHT, modelica_boolean _inElimNegAliases)
{
modelica_string _outValueReference = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_return: OMC_LABEL_UNUSED
return _outValueReference;
}
modelica_metatype boxptr_SimCodeUtil_getLocalValueReference(threadData_t *threadData, modelica_metatype _inSimVar, modelica_metatype _inSimCode, modelica_metatype _inCrefToSimVarHT, modelica_metatype _inElimNegAliases)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_string _outValueReference = NULL;
tmp1 = mmc_unbox_integer(_inSimCode);
tmp2 = mmc_unbox_integer(_inElimNegAliases);
_outValueReference = omc_SimCodeUtil_getLocalValueReference(threadData, _inSimVar, tmp1, _inCrefToSimVarHT, tmp2);
return _outValueReference;
}
DLLExport
modelica_string omc_SimCodeUtil_getValueReference(threadData_t *threadData, modelica_metatype _inSimVar, modelica_integer _inSimCode, modelica_boolean _inElimNegAliases)
{
modelica_string _outValueReference = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_return: OMC_LABEL_UNUSED
return _outValueReference;
}
modelica_metatype boxptr_SimCodeUtil_getValueReference(threadData_t *threadData, modelica_metatype _inSimVar, modelica_metatype _inSimCode, modelica_metatype _inElimNegAliases)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_string _outValueReference = NULL;
tmp1 = mmc_unbox_integer(_inSimCode);
tmp2 = mmc_unbox_integer(_inElimNegAliases);
_outValueReference = omc_SimCodeUtil_getValueReference(threadData, _inSimVar, tmp1, tmp2);
return _outValueReference;
}
DLLExport
modelica_metatype omc_SimCodeUtil_codegenExpSanityCheck(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fe, modelica_metatype _context)
{
modelica_metatype _e = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_e = __omcQ_24in_5Fe;
_return: OMC_LABEL_UNUSED
return _e;
}
DLLExport
modelica_string omc_SimCodeUtil_localCref2Index(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inOMSIFunction)
{
modelica_string _outIndex = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/SimCodeUtil.mo",56,3,56,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT1));
}
}
}
_return: OMC_LABEL_UNUSED
return _outIndex;
}
DLLExport
modelica_metatype omc_SimCodeUtil_localCref2SimVar(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inCrefToSimVarHT)
{
modelica_metatype _outSimVar = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/SimCodeUtil.mo",48,3,48,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT2));
}
}
}
_return: OMC_LABEL_UNUSED
return _outSimVar;
}
DLLExport
modelica_metatype omc_SimCodeUtil_simVarFromHT(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _simCode)
{
modelica_metatype _outSimVar = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/SimCodeUtil.mo",40,3,40,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT3));
}
}
}
_return: OMC_LABEL_UNUSED
return _outSimVar;
}
DLLExport
modelica_metatype omc_SimCodeUtil_cref2simvar(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inCrefToSimVarHT)
{
modelica_metatype _outSimVar = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/SimCodeUtil.mo",32,3,32,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT4));
}
}
}
_return: OMC_LABEL_UNUSED
return _outSimVar;
}
DLLExport
modelica_integer omc_SimCodeUtil_getSimCode(threadData_t *threadData)
{
modelica_integer _code;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/SimCodeUtil.mo",24,3,24,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT5));
}
}
}
_return: OMC_LABEL_UNUSED
return _code;
}
modelica_metatype boxptr_SimCodeUtil_getSimCode(threadData_t *threadData)
{
modelica_integer _code;
modelica_metatype out_code;
_code = omc_SimCodeUtil_getSimCode(threadData);
out_code = mmc_mk_icon(_code);
return out_code;
}
DLLExport
modelica_metatype omc_SimCodeUtil_eqInfo(threadData_t *threadData, modelica_metatype _eq)
{
modelica_metatype _info = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/SimCodeUtil.mo",18,3,18,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT6));
}
}
}
_return: OMC_LABEL_UNUSED
return _info;
}
DLLExport
modelica_metatype omc_SimCodeUtil_sortEqSystems(threadData_t *threadData, modelica_metatype _eqs)
{
modelica_metatype _outEqs = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/SimCodeUtil.mo",11,3,11,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT7));
}
}
}
_return: OMC_LABEL_UNUSED
return _outEqs;
}
