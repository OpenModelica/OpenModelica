#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/FTraverse.c"
#endif
#include "omc_simulation_settings.h"
#include "FTraverse.h"
#include "util/modelica.h"
#include "FTraverse_includes.h"
DLLExport
modelica_metatype omc_FTraverse_walk(threadData_t *threadData, modelica_metatype _inGraph, modelica_fnptr _inWalker, modelica_metatype _inExtra, modelica_metatype _inOptions, modelica_metatype *out_outExtra)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outExtra = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0+0] = _inGraph;
tmpMeta[0+1] = _inExtra;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outGraph = tmpMeta[0+0];
_outExtra = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outExtra) { *out_outExtra = _outExtra; }
return _outGraph;
}
