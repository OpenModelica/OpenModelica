#include "omc_simulation_settings.h"
#include "RewriteRules.h"
#define _OMC_LIT0_data "RewriteRules.clearRules"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,23,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "RewriteRules.loadRules"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,22,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#include "util/modelica.h"
#include "RewriteRules_includes.h"
DLLDirection
void omc_RewriteRules_clearRules(threadData_t *threadData)
{
static int tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"RewriteRules.mo",59,3,59,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
DLLDirection
void omc_RewriteRules_loadRules(threadData_t *threadData)
{
static int tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"RewriteRules.mo",54,3,54,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT1));
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
DLLDirection
modelica_boolean omc_RewriteRules_noRewriteRulesBackEnd(threadData_t *threadData)
{
modelica_boolean _noRules;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_noRules = 1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _noRules;
}
modelica_metatype boxptr_RewriteRules_noRewriteRulesBackEnd(threadData_t *threadData)
{
modelica_boolean _noRules;
modelica_metatype out_noRules;
_noRules = omc_RewriteRules_noRewriteRulesBackEnd(threadData);
out_noRules = mmc_mk_icon(_noRules);
return out_noRules;
}
DLLDirection
modelica_boolean omc_RewriteRules_noRewriteRulesFrontEnd(threadData_t *threadData)
{
modelica_boolean _noRules;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_noRules = 1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _noRules;
}
modelica_metatype boxptr_RewriteRules_noRewriteRulesFrontEnd(threadData_t *threadData)
{
modelica_boolean _noRules;
modelica_metatype out_noRules;
_noRules = omc_RewriteRules_noRewriteRulesFrontEnd(threadData);
out_noRules = mmc_mk_icon(_noRules);
return out_noRules;
}
DLLDirection
modelica_metatype omc_RewriteRules_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean *out_isChanged)
{
modelica_metatype _outExp = NULL;
modelica_boolean _isChanged;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = _inExp;
_isChanged = 0;
_return: OMC_LABEL_UNUSED
if (out_isChanged) { *out_isChanged = _isChanged; }
return _outExp;
}
modelica_metatype boxptr_RewriteRules_rewriteFrontEnd(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype *out_isChanged)
{
modelica_boolean _isChanged;
modelica_metatype _outExp = NULL;
_outExp = omc_RewriteRules_rewriteFrontEnd(threadData, _inExp, &_isChanged);
if (out_isChanged) { *out_isChanged = mmc_mk_icon(_isChanged); }
return _outExp;
}
