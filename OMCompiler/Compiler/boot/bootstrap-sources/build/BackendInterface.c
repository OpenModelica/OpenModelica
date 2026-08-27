#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/BackendInterface.c"
#endif
#include "omc_simulation_settings.h"
#include "BackendInterface.h"
#include "util/modelica.h"
#include "BackendInterface_includes.h"
DLLExport
modelica_metatype omc_BackendInterface_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean *out_isChanged)
{
modelica_metatype _outExp = NULL;
modelica_boolean _isChanged;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = omc_RewriteRules_rewriteFrontEnd(threadData, _inExp ,&_isChanged);
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
DLLExport
modelica_boolean omc_BackendInterface_noRewriteRulesFrontEnd(threadData_t *threadData)
{
modelica_boolean _noRules;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_noRules = omc_RewriteRules_noRewriteRulesFrontEnd(threadData);
_return: OMC_LABEL_UNUSED
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
DLLExport
modelica_metatype omc_BackendInterface_elabCallInteractive(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype _inExps, modelica_metatype _inNamedArgs, modelica_boolean _inImplInst, modelica_metatype _inPrefix, modelica_metatype _inInfo, modelica_metatype *out_outExp, modelica_metatype *out_outProperties)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outExp = NULL;
modelica_metatype _outProperties = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = omc_StaticScript_elabCallInteractive(threadData, _inCache, _inEnv, _inCref, _inExps, _inNamedArgs, _inImplInst, _inPrefix, _inInfo ,&_outExp ,&_outProperties);
_return: OMC_LABEL_UNUSED
if (out_outExp) { *out_outExp = _outExp; }
if (out_outProperties) { *out_outProperties = _outProperties; }
return _outCache;
}
modelica_metatype boxptr_BackendInterface_elabCallInteractive(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype _inExps, modelica_metatype _inNamedArgs, modelica_metatype _inImplInst, modelica_metatype _inPrefix, modelica_metatype _inInfo, modelica_metatype *out_outExp, modelica_metatype *out_outProperties)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImplInst);
_outCache = omc_BackendInterface_elabCallInteractive(threadData, _inCache, _inEnv, _inCref, _inExps, _inNamedArgs, tmp1, _inPrefix, _inInfo, out_outExp, out_outProperties);
return _outCache;
}
DLLExport
modelica_metatype omc_BackendInterface_cevalCallFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inValues, modelica_boolean _inImplInst, modelica_metatype _inMsg, modelica_integer _inNumIter, modelica_metatype *out_outValue)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outValue = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = omc_CevalScript_cevalCallFunction(threadData, _inCache, _inEnv, _inExp, _inValues, _inImplInst, _inMsg, _inNumIter ,&_outValue);
_return: OMC_LABEL_UNUSED
if (out_outValue) { *out_outValue = _outValue; }
return _outCache;
}
modelica_metatype boxptr_BackendInterface_cevalCallFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inValues, modelica_metatype _inImplInst, modelica_metatype _inMsg, modelica_metatype _inNumIter, modelica_metatype *out_outValue)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImplInst);
tmp2 = mmc_unbox_integer(_inNumIter);
_outCache = omc_BackendInterface_cevalCallFunction(threadData, _inCache, _inEnv, _inExp, _inValues, tmp1, _inMsg, tmp2, out_outValue);
return _outCache;
}
DLLExport
modelica_metatype omc_BackendInterface_cevalInteractiveFunctions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inMsg, modelica_integer _inNumIter, modelica_metatype *out_outValue)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outValue = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = omc_CevalScript_cevalInteractiveFunctions(threadData, _inCache, _inEnv, _inExp, _inMsg, _inNumIter ,&_outValue);
_return: OMC_LABEL_UNUSED
if (out_outValue) { *out_outValue = _outValue; }
return _outCache;
}
modelica_metatype boxptr_BackendInterface_cevalInteractiveFunctions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inMsg, modelica_metatype _inNumIter, modelica_metatype *out_outValue)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inNumIter);
_outCache = omc_BackendInterface_cevalInteractiveFunctions(threadData, _inCache, _inEnv, _inExp, _inMsg, tmp1, out_outValue);
return _outCache;
}
