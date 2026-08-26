#include "omc_simulation_settings.h"
#include "BackendCevalInterface.h"
#include "util/modelica.h"
#include "BackendCevalInterface_includes.h"
DLLDirection
modelica_metatype omc_BackendCevalInterface_elabCallInteractive(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype _inExps, modelica_metatype _inNamedArgs, modelica_boolean _inImplInst, modelica_metatype _inPrefix, modelica_metatype _inInfo, modelica_metatype *out_outExp, modelica_metatype *out_outProperties)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outExp = NULL;
modelica_metatype _outProperties = NULL;
modelica_metatype _functions = NULL;
modelica_fnptr _func;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_functions = getGlobalRoot(((modelica_integer) 32));
_func = (modelica_fnptr) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_functions), 4)));
_outCache = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _inCache, _inEnv, _inCref, _inExps, _inNamedArgs, mmc_mk_boolean(_inImplInst), _inPrefix, _inInfo ,&_outExp ,&_outProperties) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _inCache, _inEnv, _inCref, _inExps, _inNamedArgs, mmc_mk_boolean(_inImplInst), _inPrefix, _inInfo ,&_outExp ,&_outProperties);
_return: OMC_LABEL_UNUSED
if (out_outExp) { *out_outExp = _outExp; }
if (out_outProperties) { *out_outProperties = _outProperties; }
return _outCache;
}
modelica_metatype boxptr_BackendCevalInterface_elabCallInteractive(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype _inExps, modelica_metatype _inNamedArgs, modelica_metatype _inImplInst, modelica_metatype _inPrefix, modelica_metatype _inInfo, modelica_metatype *out_outExp, modelica_metatype *out_outProperties)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImplInst);
_outCache = omc_BackendCevalInterface_elabCallInteractive(threadData, _inCache, _inEnv, _inCref, _inExps, _inNamedArgs, tmp1, _inPrefix, _inInfo, out_outExp, out_outProperties);
return _outCache;
}
DLLDirection
modelica_metatype omc_BackendCevalInterface_cevalCallFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inValues, modelica_boolean _inImplInst, modelica_metatype _inMsg, modelica_integer _inNumIter, modelica_metatype *out_outValue)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outValue = NULL;
modelica_metatype _functions = NULL;
modelica_fnptr _func;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_functions = getGlobalRoot(((modelica_integer) 32));
_func = (modelica_fnptr) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_functions), 3)));
_outCache = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _inCache, _inEnv, _inExp, _inValues, mmc_mk_boolean(_inImplInst), _inMsg, mmc_mk_integer(_inNumIter) ,&_outValue) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _inCache, _inEnv, _inExp, _inValues, mmc_mk_boolean(_inImplInst), _inMsg, mmc_mk_integer(_inNumIter) ,&_outValue);
_return: OMC_LABEL_UNUSED
if (out_outValue) { *out_outValue = _outValue; }
return _outCache;
}
modelica_metatype boxptr_BackendCevalInterface_cevalCallFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inValues, modelica_metatype _inImplInst, modelica_metatype _inMsg, modelica_metatype _inNumIter, modelica_metatype *out_outValue)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImplInst);
tmp2 = mmc_unbox_integer(_inNumIter);
_outCache = omc_BackendCevalInterface_cevalCallFunction(threadData, _inCache, _inEnv, _inExp, _inValues, tmp1, _inMsg, tmp2, out_outValue);
return _outCache;
}
DLLDirection
modelica_metatype omc_BackendCevalInterface_cevalInteractiveFunctions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inMsg, modelica_integer _inNumIter, modelica_metatype *out_outValue)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outValue = NULL;
modelica_metatype _functions = NULL;
modelica_fnptr _func;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_functions = getGlobalRoot(((modelica_integer) 32));
_func = (modelica_fnptr) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_functions), 2)));
_outCache = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _inCache, _inEnv, _inExp, _inMsg, mmc_mk_integer(_inNumIter) ,&_outValue) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _inCache, _inEnv, _inExp, _inMsg, mmc_mk_integer(_inNumIter) ,&_outValue);
_return: OMC_LABEL_UNUSED
if (out_outValue) { *out_outValue = _outValue; }
return _outCache;
}
modelica_metatype boxptr_BackendCevalInterface_cevalInteractiveFunctions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inMsg, modelica_metatype _inNumIter, modelica_metatype *out_outValue)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inNumIter);
_outCache = omc_BackendCevalInterface_cevalInteractiveFunctions(threadData, _inCache, _inEnv, _inExp, _inMsg, tmp1, out_outValue);
return _outCache;
}
DLLDirection
void omc_BackendCevalInterface_initializeBackendInterface(threadData_t *threadData, modelica_metatype _inFunctions)
{
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
setGlobalRoot(((modelica_integer) 32), _inFunctions);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
