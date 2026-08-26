#include "omc_simulation_settings.h"
#include "NFUnitCheck.h"
#include "util/modelica.h"
#include "NFUnitCheck_includes.h"
DLLDirection
modelica_metatype omc_NFUnitCheck_checkUnits(threadData_t *threadData, modelica_metatype _inDAE, modelica_metatype _func)
{
modelica_metatype _outDAE = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outDAE = _inDAE;
goto _return;
_return: OMC_LABEL_UNUSED
return _outDAE;
}
