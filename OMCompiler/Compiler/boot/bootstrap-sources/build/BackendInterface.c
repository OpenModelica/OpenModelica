#include "omc_simulation_settings.h"
#include "BackendInterface.h"
#include "util/modelica.h"
#include "BackendInterface_includes.h"
DLLDirection
void omc_BackendInterface_initInstHashTable(threadData_t *threadData)
{
modelica_metatype _functions = NULL;
modelica_fnptr _func;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_functions = getGlobalRoot(((modelica_integer) 31));
_func = (modelica_fnptr) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_functions), 5)));
(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((void(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2)))) : ((void(*)(threadData_t*)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
DLLDirection
modelica_metatype omc_BackendInterface_appendLibrary(threadData_t *threadData, modelica_metatype _modelName, modelica_string _modelicaPath, modelica_boolean *out_success)
{
modelica_metatype _program = NULL;
modelica_boolean _success;
modelica_metatype _functions = NULL;
modelica_fnptr _func;
modelica_metatype tmpMeta1;
modelica_integer tmp2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_functions = getGlobalRoot(((modelica_integer) 31));
_func = (modelica_fnptr) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_functions), 4)));
tmpMeta3 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_string, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _modelName, _modelicaPath, &tmpMeta1) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_string, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _modelName, _modelicaPath, &tmpMeta1);
_program = tmpMeta3;
tmp2 = mmc_unbox_integer(tmpMeta1);
_success = tmp2;
_return: OMC_LABEL_UNUSED
if (out_success) { *out_success = _success; }
return _program;
}
modelica_metatype boxptr_BackendInterface_appendLibrary(threadData_t *threadData, modelica_metatype _modelName, modelica_metatype _modelicaPath, modelica_metatype *out_success)
{
modelica_boolean _success;
modelica_metatype _program = NULL;
_program = omc_BackendInterface_appendLibrary(threadData, _modelName, _modelicaPath, &_success);
if (out_success) { *out_success = mmc_mk_icon(_success); }
return _program;
}
DLLDirection
modelica_metatype omc_BackendInterface_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean *out_isChanged)
{
modelica_metatype _outExp = NULL;
modelica_boolean _isChanged;
modelica_metatype _functions = NULL;
modelica_fnptr _func;
modelica_metatype tmpMeta1;
modelica_integer tmp2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_functions = getGlobalRoot(((modelica_integer) 31));
_func = (modelica_fnptr) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_functions), 3)));
tmpMeta3 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _inExp, &tmpMeta1) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _inExp, &tmpMeta1);
_outExp = tmpMeta3;
tmp2 = mmc_unbox_integer(tmpMeta1);
_isChanged = tmp2;
_return: OMC_LABEL_UNUSED
if (out_isChanged) { *out_isChanged = _isChanged; }
return _outExp;
}
modelica_metatype boxptr_BackendInterface_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype *out_isChanged)
{
modelica_boolean _isChanged;
modelica_metatype _outExp = NULL;
_outExp = omc_BackendInterface_rewriteFrontEnd(threadData, _inExp, &_isChanged);
if (out_isChanged) { *out_isChanged = mmc_mk_icon(_isChanged); }
return _outExp;
}
DLLDirection
modelica_boolean omc_BackendInterface_noRewriteRulesFrontEnd(threadData_t *threadData)
{
modelica_boolean _noRules;
modelica_metatype _functions = NULL;
modelica_fnptr _func;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_functions = getGlobalRoot(((modelica_integer) 31));
_func = (modelica_fnptr) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_functions), 2)));
_noRules = mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2)))) : ((modelica_metatype(*)(threadData_t*)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _noRules;
}
modelica_metatype boxptr_BackendInterface_noRewriteRulesFrontEnd(threadData_t *threadData)
{
modelica_boolean _noRules;
modelica_metatype out_noRules;
_noRules = omc_BackendInterface_noRewriteRulesFrontEnd(threadData);
out_noRules = mmc_mk_icon(_noRules);
return out_noRules;
}
DLLDirection
void omc_BackendInterface_initializeBackendInterface(threadData_t *threadData, modelica_metatype _inFunctions)
{
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
setGlobalRoot(((modelica_integer) 31), _inFunctions);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
