#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "ClockIndexes.c"
#endif
#include "omc_simulation_settings.h"
#include "ClockIndexes.h"
#define _OMC_LIT0_data "NON"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,3,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "STO"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,3,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "SSI"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,3,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "BLD"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,3,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "EXS"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,3,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "EXC"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,3,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "FRT"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,3,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "BCK"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,3,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "SCD"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,3,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "LIN"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,3,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "TMP"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,3,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "UNC"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,3,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "PR0"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,3,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "PR1"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,3,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "PR2"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,3,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "JAC"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,3,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "RES"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,3,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "HPC"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,3,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "STM"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,3,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "FIN"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,3,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "SIM"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,3,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "INI"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,3,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "ERR"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,3,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#include "util/modelica.h"
#include "ClockIndexes_includes.h"
DLLExport
modelica_string omc_ClockIndexes_toString(threadData_t *threadData, modelica_integer _clockIndex)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_integer tmp4_1;
tmp4_1 = _clockIndex;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(tmp4_1)) {
case -1: {
if (-1 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT0;
goto tmp3_done;
}
case 8: {
if (8 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT1;
goto tmp3_done;
}
case 9: {
if (9 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT2;
goto tmp3_done;
}
case 10: {
if (10 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT3;
goto tmp3_done;
}
case 11: {
if (11 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT4;
goto tmp3_done;
}
case 12: {
if (12 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT5;
goto tmp3_done;
}
case 13: {
if (13 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT6;
goto tmp3_done;
}
case 14: {
if (14 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT7;
goto tmp3_done;
}
case 15: {
if (15 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT8;
goto tmp3_done;
}
case 16: {
if (16 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT9;
goto tmp3_done;
}
case 17: {
if (17 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT10;
goto tmp3_done;
}
case 18: {
if (18 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT11;
goto tmp3_done;
}
case 19: {
if (19 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT12;
goto tmp3_done;
}
case 20: {
if (20 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT13;
goto tmp3_done;
}
case 21: {
if (21 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT14;
goto tmp3_done;
}
case 22: {
if (22 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT15;
goto tmp3_done;
}
case 23: {
if (23 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT16;
goto tmp3_done;
}
case 24: {
if (24 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT17;
goto tmp3_done;
}
case 25: {
if (25 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT18;
goto tmp3_done;
}
case 26: {
if (26 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT19;
goto tmp3_done;
}
case 29: {
if (29 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT20;
goto tmp3_done;
}
case 30: {
if (30 != tmp4_1) goto tmp3_end;
tmp1 = _OMC_LIT21;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmp1 = _OMC_LIT22;
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
_str = tmp1;
_return: OMC_LABEL_UNUSED
return _str;
}
modelica_metatype boxptr_ClockIndexes_toString(threadData_t *threadData, modelica_metatype _clockIndex)
{
modelica_integer tmp1;
modelica_string _str = NULL;
tmp1 = mmc_unbox_integer(_clockIndex);
_str = omc_ClockIndexes_toString(threadData, tmp1);
return _str;
}
