#include "omc_simulation_settings.h"
#include "BackendInterfaceImplementation.h"
#define _OMC_LIT0_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,0,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "default"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,7,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,2,1) {_OMC_LIT1,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
#include "util/modelica.h"
#include "BackendInterfaceImplementation_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BackendInterfaceImplementation_appendLibrary(threadData_t *threadData, modelica_metatype _modelName, modelica_string _modelicaPath, modelica_boolean *out_success);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BackendInterfaceImplementation_appendLibrary(threadData_t *threadData, modelica_metatype _modelName, modelica_metatype _modelicaPath, modelica_metatype *out_success);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendInterfaceImplementation_appendLibrary,2,0) {(void*) boxptr_BackendInterfaceImplementation_appendLibrary,0}};
#define boxvar_BackendInterfaceImplementation_appendLibrary MMC_REFSTRUCTLIT(boxvar_lit_BackendInterfaceImplementation_appendLibrary)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BackendInterfaceImplementation_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean *out_isChanged);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BackendInterfaceImplementation_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype *out_isChanged);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendInterfaceImplementation_rewriteFrontEnd,2,0) {(void*) boxptr_BackendInterfaceImplementation_rewriteFrontEnd,0}};
#define boxvar_BackendInterfaceImplementation_rewriteFrontEnd MMC_REFSTRUCTLIT(boxvar_lit_BackendInterfaceImplementation_rewriteFrontEnd)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_BackendInterfaceImplementation_noRewriteRulesFrontEnd(threadData_t *threadData);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BackendInterfaceImplementation_noRewriteRulesFrontEnd(threadData_t *threadData);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendInterfaceImplementation_noRewriteRulesFrontEnd,2,0) {(void*) boxptr_BackendInterfaceImplementation_noRewriteRulesFrontEnd,0}};
#define boxvar_BackendInterfaceImplementation_noRewriteRulesFrontEnd MMC_REFSTRUCTLIT(boxvar_lit_BackendInterfaceImplementation_noRewriteRulesFrontEnd)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BackendInterfaceImplementation_elabCallInteractive(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype _inExps, modelica_metatype _inNamedArgs, modelica_boolean _inImplInst, modelica_metatype _inPrefix, modelica_metatype _inInfo, modelica_metatype *out_outExp, modelica_metatype *out_outProperties);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BackendInterfaceImplementation_elabCallInteractive(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype _inExps, modelica_metatype _inNamedArgs, modelica_metatype _inImplInst, modelica_metatype _inPrefix, modelica_metatype _inInfo, modelica_metatype *out_outExp, modelica_metatype *out_outProperties);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendInterfaceImplementation_elabCallInteractive,2,0) {(void*) boxptr_BackendInterfaceImplementation_elabCallInteractive,0}};
#define boxvar_BackendInterfaceImplementation_elabCallInteractive MMC_REFSTRUCTLIT(boxvar_lit_BackendInterfaceImplementation_elabCallInteractive)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BackendInterfaceImplementation_cevalCallFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inValues, modelica_boolean _inImplInst, modelica_metatype _inMsg, modelica_integer _inNumIter, modelica_metatype *out_outValue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BackendInterfaceImplementation_cevalCallFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inValues, modelica_metatype _inImplInst, modelica_metatype _inMsg, modelica_metatype _inNumIter, modelica_metatype *out_outValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendInterfaceImplementation_cevalCallFunction,2,0) {(void*) boxptr_BackendInterfaceImplementation_cevalCallFunction,0}};
#define boxvar_BackendInterfaceImplementation_cevalCallFunction MMC_REFSTRUCTLIT(boxvar_lit_BackendInterfaceImplementation_cevalCallFunction)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BackendInterfaceImplementation_cevalInteractiveFunctions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inMsg, modelica_integer _inNumIter, modelica_metatype *out_outValue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BackendInterfaceImplementation_cevalInteractiveFunctions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inMsg, modelica_metatype _inNumIter, modelica_metatype *out_outValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_BackendInterfaceImplementation_cevalInteractiveFunctions,2,0) {(void*) boxptr_BackendInterfaceImplementation_cevalInteractiveFunctions,0}};
#define boxvar_BackendInterfaceImplementation_cevalInteractiveFunctions MMC_REFSTRUCTLIT(boxvar_lit_BackendInterfaceImplementation_cevalInteractiveFunctions)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BackendInterfaceImplementation_appendLibrary(threadData_t *threadData, modelica_metatype _modelName, modelica_string _modelicaPath, modelica_boolean *out_success)
{
modelica_metatype _program = NULL;
modelica_boolean _success;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_program = omc_SymbolTable_getAbsyn(threadData);
tmpMeta2 = mmc_mk_box4(0, _modelName, _OMC_LIT0, _OMC_LIT2, mmc_mk_boolean(0 /* false */));
tmpMeta1 = mmc_mk_cons(tmpMeta2, MMC_REFSTRUCTLIT(mmc_nil));
_program = omc_CevalScript_loadModel(threadData, tmpMeta1, _modelicaPath, _program, 1 /* true */, 1 /* true */, 1 /* true */, 0 /* false */, 0 /* false */, _OMC_LIT0 ,&_success);
omc_SymbolTable_setAbsyn(threadData, _program);
_return: OMC_LABEL_UNUSED
if (out_success) { *out_success = _success; }
return _program;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BackendInterfaceImplementation_appendLibrary(threadData_t *threadData, modelica_metatype _modelName, modelica_metatype _modelicaPath, modelica_metatype *out_success)
{
modelica_boolean _success;
modelica_metatype _program = NULL;
_program = omc_BackendInterfaceImplementation_appendLibrary(threadData, _modelName, _modelicaPath, &_success);
if (out_success) { *out_success = mmc_mk_icon(_success); }
return _program;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BackendInterfaceImplementation_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean *out_isChanged)
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BackendInterfaceImplementation_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype *out_isChanged)
{
modelica_boolean _isChanged;
modelica_metatype _outExp = NULL;
_outExp = omc_BackendInterfaceImplementation_rewriteFrontEnd(threadData, _inExp, &_isChanged);
if (out_isChanged) { *out_isChanged = mmc_mk_icon(_isChanged); }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_BackendInterfaceImplementation_noRewriteRulesFrontEnd(threadData_t *threadData)
{
modelica_boolean _noRules;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_noRules = omc_RewriteRules_noRewriteRulesFrontEnd(threadData);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _noRules;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BackendInterfaceImplementation_noRewriteRulesFrontEnd(threadData_t *threadData)
{
modelica_boolean _noRules;
modelica_metatype out_noRules;
_noRules = omc_BackendInterfaceImplementation_noRewriteRulesFrontEnd(threadData);
out_noRules = mmc_mk_icon(_noRules);
return out_noRules;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BackendInterfaceImplementation_elabCallInteractive(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype _inExps, modelica_metatype _inNamedArgs, modelica_boolean _inImplInst, modelica_metatype _inPrefix, modelica_metatype _inInfo, modelica_metatype *out_outExp, modelica_metatype *out_outProperties)
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BackendInterfaceImplementation_elabCallInteractive(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inCref, modelica_metatype _inExps, modelica_metatype _inNamedArgs, modelica_metatype _inImplInst, modelica_metatype _inPrefix, modelica_metatype _inInfo, modelica_metatype *out_outExp, modelica_metatype *out_outProperties)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImplInst);
_outCache = omc_BackendInterfaceImplementation_elabCallInteractive(threadData, _inCache, _inEnv, _inCref, _inExps, _inNamedArgs, tmp1, _inPrefix, _inInfo, out_outExp, out_outProperties);
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BackendInterfaceImplementation_cevalCallFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inValues, modelica_boolean _inImplInst, modelica_metatype _inMsg, modelica_integer _inNumIter, modelica_metatype *out_outValue)
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BackendInterfaceImplementation_cevalCallFunction(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inValues, modelica_metatype _inImplInst, modelica_metatype _inMsg, modelica_metatype _inNumIter, modelica_metatype *out_outValue)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inImplInst);
tmp2 = mmc_unbox_integer(_inNumIter);
_outCache = omc_BackendInterfaceImplementation_cevalCallFunction(threadData, _inCache, _inEnv, _inExp, _inValues, tmp1, _inMsg, tmp2, out_outValue);
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_BackendInterfaceImplementation_cevalInteractiveFunctions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inMsg, modelica_integer _inNumIter, modelica_metatype *out_outValue)
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_BackendInterfaceImplementation_cevalInteractiveFunctions(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inExp, modelica_metatype _inMsg, modelica_metatype _inNumIter, modelica_metatype *out_outValue)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inNumIter);
_outCache = omc_BackendInterfaceImplementation_cevalInteractiveFunctions(threadData, _inCache, _inEnv, _inExp, _inMsg, tmp1, out_outValue);
return _outCache;
}
DLLDirection
void omc_BackendInterfaceImplementation_initializeBackendInterface(threadData_t *threadData)
{
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box5(3, &BackendInterface_BackendInterfaceFunctions_BACKEND__INTERFACE__FUNCTIONS__desc, boxvar_BackendInterfaceImplementation_noRewriteRulesFrontEnd, boxvar_BackendInterfaceImplementation_rewriteFrontEnd, boxvar_BackendInterfaceImplementation_appendLibrary, boxvar_InstHashTable_init);
omc_BackendInterface_initializeBackendInterface(threadData, tmpMeta1);
tmpMeta2 = mmc_mk_box4(3, &BackendCevalInterface_BackendInterfaceFunctions_BACKEND__INTERFACE__FUNCTIONS__desc, boxvar_BackendInterfaceImplementation_cevalInteractiveFunctions, boxvar_BackendInterfaceImplementation_cevalCallFunction, boxvar_BackendInterfaceImplementation_elabCallInteractive);
omc_BackendCevalInterface_initializeBackendInterface(threadData, tmpMeta2);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
