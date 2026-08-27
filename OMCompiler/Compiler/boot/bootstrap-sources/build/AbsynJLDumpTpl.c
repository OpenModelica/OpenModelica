#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/AbsynJLDumpTpl.c"
#endif
#include "omc_simulation_settings.h"
#include "AbsynJLDumpTpl.h"
#include "util/modelica.h"
#include "AbsynJLDumpTpl_includes.h"
DLLExport
modelica_metatype omc_AbsynJLDumpTpl_dump(threadData_t *threadData, modelica_metatype _txt, modelica_metatype _a_program)
{
modelica_metatype _out_txt = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_out_txt = _txt;
_return: OMC_LABEL_UNUSED
return _out_txt;
}
