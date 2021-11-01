#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "FExpand.c"
#endif
#include "omc_simulation_settings.h"
#include "FExpand.h"
#define _OMC_LIT0_data "Extends:        "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,16,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "Derived:        "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,16,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "ConstrainedBy:  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,16,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "ClassExtends:   "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,16,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "ComponentTypes: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,16,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "Comp Refs:      "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,16,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "Modifiers:      "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,16,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "FExpand.all:    "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,16,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT9,0.0);
#define _OMC_LIT9 MMC_REFREALLIT(_OMC_LIT_STRUCT9)
#include "util/modelica.h"
#include "FExpand_includes.h"
DLLExport
modelica_metatype omc_FExpand_all(threadData_t *threadData, modelica_metatype _inGraph)
{
modelica_metatype _outGraph = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _lst = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
_g = tmp4_1;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
_lst = tmpMeta6;
omc_System_startTimer(threadData);
_g = omc_FResolve_ext(threadData, omc_FGraph_top(threadData, _g), _g);
omc_System_stopTimer(threadData);
_lst = omc_List_consr(threadData, _lst, mmc_mk_real(omc_System_getTimerIntervalTime(threadData)));
tmpMeta7 = stringAppend(_OMC_LIT0,realString(mmc_unbox_real(listHead(_lst))));
tmpMeta8 = stringAppend(tmpMeta7,_OMC_LIT1);
fputs(MMC_STRINGDATA(tmpMeta8),stdout);
omc_System_startTimer(threadData);
_g = omc_FResolve_derived(threadData, omc_FGraph_top(threadData, _g), _g);
omc_System_stopTimer(threadData);
_lst = omc_List_consr(threadData, _lst, mmc_mk_real(omc_System_getTimerIntervalTime(threadData)));
tmpMeta9 = stringAppend(_OMC_LIT2,realString(mmc_unbox_real(listHead(_lst))));
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT1);
fputs(MMC_STRINGDATA(tmpMeta10),stdout);
omc_System_startTimer(threadData);
_g = omc_FResolve_cc(threadData, omc_FGraph_top(threadData, _g), _g);
omc_System_stopTimer(threadData);
_lst = omc_List_consr(threadData, _lst, mmc_mk_real(omc_System_getTimerIntervalTime(threadData)));
tmpMeta11 = stringAppend(_OMC_LIT3,realString(mmc_unbox_real(listHead(_lst))));
tmpMeta12 = stringAppend(tmpMeta11,_OMC_LIT1);
fputs(MMC_STRINGDATA(tmpMeta12),stdout);
omc_System_startTimer(threadData);
_g = omc_FResolve_clsext(threadData, omc_FGraph_top(threadData, _g), _g);
omc_System_stopTimer(threadData);
_lst = omc_List_consr(threadData, _lst, mmc_mk_real(omc_System_getTimerIntervalTime(threadData)));
tmpMeta13 = stringAppend(_OMC_LIT4,realString(mmc_unbox_real(listHead(_lst))));
tmpMeta14 = stringAppend(tmpMeta13,_OMC_LIT1);
fputs(MMC_STRINGDATA(tmpMeta14),stdout);
omc_System_startTimer(threadData);
_g = omc_FResolve_ty(threadData, omc_FGraph_top(threadData, _g), _g);
omc_System_stopTimer(threadData);
_lst = omc_List_consr(threadData, _lst, mmc_mk_real(omc_System_getTimerIntervalTime(threadData)));
tmpMeta15 = stringAppend(_OMC_LIT5,realString(mmc_unbox_real(listHead(_lst))));
tmpMeta16 = stringAppend(tmpMeta15,_OMC_LIT1);
fputs(MMC_STRINGDATA(tmpMeta16),stdout);
omc_System_startTimer(threadData);
_g = omc_FResolve_cr(threadData, omc_FGraph_top(threadData, _g), _g);
omc_System_stopTimer(threadData);
_lst = omc_List_consr(threadData, _lst, mmc_mk_real(omc_System_getTimerIntervalTime(threadData)));
tmpMeta17 = stringAppend(_OMC_LIT6,realString(mmc_unbox_real(listHead(_lst))));
tmpMeta18 = stringAppend(tmpMeta17,_OMC_LIT1);
fputs(MMC_STRINGDATA(tmpMeta18),stdout);
omc_System_startTimer(threadData);
_g = omc_FResolve_mod(threadData, omc_FGraph_top(threadData, _g), _g);
omc_System_stopTimer(threadData);
_lst = omc_List_consr(threadData, _lst, mmc_mk_real(omc_System_getTimerIntervalTime(threadData)));
tmpMeta19 = stringAppend(_OMC_LIT7,realString(mmc_unbox_real(listHead(_lst))));
tmpMeta20 = stringAppend(tmpMeta19,_OMC_LIT1);
fputs(MMC_STRINGDATA(tmpMeta20),stdout);
tmpMeta21 = stringAppend(_OMC_LIT8,realString(mmc_unbox_real(omc_List_fold(threadData, _lst, boxvar_realAdd, _OMC_LIT9))));
tmpMeta22 = stringAppend(tmpMeta21,_OMC_LIT1);
fputs(MMC_STRINGDATA(tmpMeta22),stdout);
tmpMeta1 = _g;
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
_outGraph = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outGraph;
}
DLLExport
modelica_metatype omc_FExpand_path(threadData_t *threadData, modelica_metatype _inGraph, modelica_metatype _inPath, modelica_metatype *out_outRef)
{
modelica_metatype _outGraph = NULL;
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inGraph;
{
modelica_metatype _r = NULL;
modelica_metatype _t = NULL;
modelica_metatype _g = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_g = tmp4_1;
_t = omc_FGraph_top(threadData, _g);
_r = _t;
tmpMeta[0+0] = _g;
tmpMeta[0+1] = _r;
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
_outRef = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRef) { *out_outRef = _outRef; }
return _outGraph;
}
