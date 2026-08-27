#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/UnitAbsynBuilder.c"
#endif
#include "omc_simulation_settings.h"
#include "UnitAbsynBuilder.h"
#define _OMC_LIT0_data "UnitAbsynBuilder.unit2str"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,25,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "UnitAbsynBuilder.registerUnitWeights"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,36,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "UnitAbsynBuilder.instBuildUnitTerms"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,35,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,1,4) {&UnitAbsyn_InstStore_NOSTORE__desc,}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
#include "util/modelica.h"
#include "UnitAbsynBuilder_includes.h"
DLLExport
modelica_string omc_UnitAbsynBuilder_unit2str(threadData_t *threadData, modelica_metatype _unit)
{
modelica_string _res = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/UnitAbsynBuilder.mo",39,3,39,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
return _res;
}
DLLExport
modelica_metatype omc_UnitAbsynBuilder_instAddStore(threadData_t *threadData, modelica_metatype _istore, modelica_metatype _itp, modelica_metatype _cr)
{
modelica_metatype _outStore = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStore = _istore;
_return: OMC_LABEL_UNUSED
return _outStore;
}
DLLExport
void omc_UnitAbsynBuilder_registerUnitWeights(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _dae)
{
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/UnitAbsynBuilder.mo",25,3,25,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT1));
}
}
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_UnitAbsynBuilder_instBuildUnitTerms(threadData_t *threadData, modelica_metatype _env, modelica_metatype _dae, modelica_metatype _compDae, modelica_metatype _store, modelica_metatype *out_terms)
{
modelica_metatype _outStore = NULL;
modelica_metatype _terms = NULL;
static int tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Stubs/UnitAbsynBuilder.mo",17,3,17,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT2));
}
}
}
_return: OMC_LABEL_UNUSED
if (out_terms) { *out_terms = _terms; }
return _outStore;
}
DLLExport
modelica_metatype omc_UnitAbsynBuilder_emptyInstStore(threadData_t *threadData)
{
modelica_metatype _st = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_st = _OMC_LIT3;
_return: OMC_LABEL_UNUSED
return _st;
}
