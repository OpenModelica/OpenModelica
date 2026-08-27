#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/DynLoad.c"
#endif
#include "omc_simulation_settings.h"
#include "DynLoad.h"
#define _OMC_LIT0_data "Stack overflow when evaluating function:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,41,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/Util/DynLoad.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,64,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT3_6,1591169649.0);
#define _OMC_LIT3_6 MMC_REFREALLIT(_OMC_LIT_STRUCT3_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT2,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(70)),MMC_IMMEDIATE(MMC_TAGFIXNUM(5)),MMC_IMMEDIATE(MMC_TAGFIXNUM(70)),MMC_IMMEDIATE(MMC_TAGFIXNUM(156)),_OMC_LIT3_6}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
#include "util/modelica.h"
#include "DynLoad_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DynLoad_executeFunction_executeFunction__internal(threadData_t *threadData, modelica_integer _handle, modelica_metatype _values, modelica_boolean _debug);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DynLoad_executeFunction_executeFunction__internal(threadData_t *threadData, modelica_metatype _handle, modelica_metatype _values, modelica_metatype _debug);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DynLoad_executeFunction_executeFunction__internal,2,0) {(void*) boxptr_DynLoad_executeFunction_executeFunction__internal,0}};
#define boxvar_DynLoad_executeFunction_executeFunction__internal MMC_REFSTRUCTLIT(boxvar_lit_DynLoad_executeFunction_executeFunction__internal)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DynLoad_executeFunction_executeFunction__internal(threadData_t *threadData, modelica_integer _handle, modelica_metatype _values, modelica_boolean _debug)
{
int _handle_ext;
modelica_metatype _values_ext;
int _debug_ext;
modelica_metatype _outVal_ext;
modelica_metatype _outVal = NULL;
_handle_ext = (int)_handle;
_values_ext = (modelica_metatype)_values;
_debug_ext = (int)_debug;
_outVal_ext = DynLoad_executeFunction(threadData, _handle_ext, _values_ext, _debug_ext);
_outVal = (modelica_metatype)_outVal_ext;
return _outVal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DynLoad_executeFunction_executeFunction__internal(threadData_t *threadData, modelica_metatype _handle, modelica_metatype _values, modelica_metatype _debug)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outVal = NULL;
tmp1 = mmc_unbox_integer(_handle);
tmp2 = mmc_unbox_integer(_debug);
_outVal = omc_DynLoad_executeFunction_executeFunction__internal(threadData, tmp1, _values, tmp2);
return _outVal;
}
DLLExport
modelica_metatype omc_DynLoad_executeFunction(threadData_t *threadData, modelica_integer _handle, modelica_metatype _values, modelica_boolean _debug)
{
modelica_metatype _outVal = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_StackOverflow_clearStacktraceMessages(threadData);
_outVal = omc_DynLoad_executeFunction_executeFunction__internal(threadData, _handle, _values, _debug);
if(omc_StackOverflow_hasStacktraceMessages(threadData))
{
tmpMeta[0] = stringAppend(_OMC_LIT0,stringDelimitList(omc_StackOverflow_readableStacktraceMessages(threadData), _OMC_LIT1));
omc_Error_addInternalError(threadData, tmpMeta[0], _OMC_LIT3);
}
_return: OMC_LABEL_UNUSED
return _outVal;
}
modelica_metatype boxptr_DynLoad_executeFunction(threadData_t *threadData, modelica_metatype _handle, modelica_metatype _values, modelica_metatype _debug)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outVal = NULL;
tmp1 = mmc_unbox_integer(_handle);
tmp2 = mmc_unbox_integer(_debug);
_outVal = omc_DynLoad_executeFunction(threadData, tmp1, _values, tmp2);
return _outVal;
}
