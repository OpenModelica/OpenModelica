#include "omc_simulation_settings.h"
#include "CodegenWasmJitFunctions.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,16) {&Values_Value_NORETCALL__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
#include "util/modelica.h"
#include "CodegenWasmJitFunctions_includes.h"
DLLDirection
modelica_metatype omc_CodegenWasmJitFunctions_loadAndExecute(threadData_t *threadData, modelica_string _fileName, modelica_string _name, modelica_metatype _args)
{
modelica_metatype _result = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_result = _OMC_LIT0;
_return: OMC_LABEL_UNUSED
return _result;
}
DLLDirection
void omc_CodegenWasmJitFunctions_translateFunctions(threadData_t *threadData, modelica_metatype _fnCode)
{
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
