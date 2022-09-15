#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "BackendInterface.c"
#endif
#include "omc_simulation_settings.h"
#include "BackendInterface.h"
#define _OMC_LIT0_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,0,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "default"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,7,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,2,1) {_OMC_LIT1,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
#include "util/modelica.h"
#include "BackendInterface_includes.h"
DLLExport
modelica_metatype omc_BackendInterface_appendLibrary(threadData_t *threadData, modelica_metatype _modelName, modelica_string _modelicaPath, modelica_boolean *out_success)
{
modelica_metatype _program = NULL;
modelica_boolean _success;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_program = omc_SymbolTable_getAbsyn(threadData);
tmpMeta2 = mmc_mk_box4(0, _modelName, _OMC_LIT0, _OMC_LIT2, mmc_mk_boolean(0));
tmpMeta1 = mmc_mk_cons(tmpMeta2, MMC_REFSTRUCTLIT(mmc_nil));
_program = omc_CevalScript_loadModel(threadData, tmpMeta1, _modelicaPath, _program, 1, 1, 1, 0, 0, _OMC_LIT0 ,&_success);
omc_SymbolTable_setAbsyn(threadData, _program);
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
