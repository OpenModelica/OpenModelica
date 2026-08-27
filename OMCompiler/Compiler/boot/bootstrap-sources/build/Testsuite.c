#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Testsuite.c"
#endif
#include "omc_simulation_settings.h"
#include "Testsuite.h"
#define _OMC_LIT0_data "../"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,3,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "^(.*/Compiler/)?(.*/testsuite/(libraries-for-testing/.openmodelica/libraries/)?)?(.*/lib/omlibrary/)?(.*/build/)?(.*)$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,118,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "^(.*)(/[_[:alnum:]]*\\.mos?_temp[0-9]*)(.*)$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,43,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "running-testsuite"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,17,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,1,3) {&Flags_FlagVisibility_INTERNAL__desc,}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,0,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,8) {&Flags_FlagData_STRING__FLAG__desc,_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "Used when running the testsuite."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,32,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT7}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(3)),_OMC_LIT3,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT4,_OMC_LIT6,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT8}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
#include "util/modelica.h"
#include "Testsuite_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_string omc_Testsuite_friendly2(threadData_t *threadData, modelica_boolean _cond, modelica_string _name);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Testsuite_friendly2(threadData_t *threadData, modelica_metatype _cond, modelica_metatype _name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Testsuite_friendly2,2,0) {(void*) boxptr_Testsuite_friendly2,0}};
#define boxvar_Testsuite_friendly2 MMC_REFSTRUCTLIT(boxvar_lit_Testsuite_friendly2)
DLLExport
modelica_string omc_Testsuite_friendlyPath(threadData_t *threadData, modelica_string _inPath)
{
modelica_string _outPath = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_string _path = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
modelica_boolean tmp7;
modelica_boolean tmp8;
modelica_boolean tmp9;
tmp6 = omc_Testsuite_isRunning(threadData);
if (1 != tmp6) goto goto_2;
tmp7 = omc_System_directoryExists(threadData, _inPath);
if (0 != tmp7) goto goto_2;
tmp8 = omc_System_regularFileExists(threadData, _inPath);
if (0 != tmp8) goto goto_2;
tmpMeta[0] = stringAppend(_OMC_LIT0,_inPath);
_path = tmpMeta[0];
tmp9 = (omc_System_directoryExists(threadData, _path) || omc_System_regularFileExists(threadData, _path));
if (1 != tmp9) goto goto_2;
tmp1 = _path;
goto tmp3_done;
}
case 1: {
tmp1 = _inPath;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outPath = tmp1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_Testsuite_friendly2(threadData_t *threadData, modelica_boolean _cond, modelica_string _name)
{
modelica_string _friendly = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp4_1;
tmp4_1 = _cond;
{
modelica_integer _i;
modelica_metatype _strs = NULL;
modelica_string _newName = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (1 != tmp4_1) goto tmp3_end;
_newName = _name;
_i = omc_System_regex(threadData, _newName, _OMC_LIT1, ((modelica_integer) 7), 1, 0 ,&_strs);
_friendly = listGet(_strs, _i);
_i = omc_System_regex(threadData, _friendly, _OMC_LIT2, ((modelica_integer) 4), 1, 0 ,&_strs);
if((_i == ((modelica_integer) 4)))
{
tmpMeta[0] = stringAppend(listGet(_strs, ((modelica_integer) 2)),listGet(_strs, ((modelica_integer) 4)));
_friendly = tmpMeta[0];
}
tmp1 = _friendly;
goto tmp3_done;
}
case 1: {
tmp1 = _name;
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
_friendly = tmp1;
_return: OMC_LABEL_UNUSED
return _friendly;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Testsuite_friendly2(threadData_t *threadData, modelica_metatype _cond, modelica_metatype _name)
{
modelica_integer tmp1;
modelica_string _friendly = NULL;
tmp1 = mmc_unbox_integer(_cond);
_friendly = omc_Testsuite_friendly2(threadData, tmp1, _name);
return _friendly;
}
DLLExport
modelica_string omc_Testsuite_friendly(threadData_t *threadData, modelica_string _name)
{
modelica_string _friendly = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_friendly = omc_Testsuite_friendly2(threadData, omc_Testsuite_isRunning(threadData), _name);
_return: OMC_LABEL_UNUSED
return _friendly;
}
DLLExport
modelica_string omc_Testsuite_getTempFilesFile(threadData_t *threadData)
{
modelica_string _tempFile = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_tempFile = omc_Flags_getConfigString(threadData, _OMC_LIT9);
_return: OMC_LABEL_UNUSED
return _tempFile;
}
DLLExport
modelica_boolean omc_Testsuite_isRunning(threadData_t *threadData)
{
modelica_boolean _runningTestsuite;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_runningTestsuite = (!(stringEqual(omc_Flags_getConfigString(threadData, _OMC_LIT9), _OMC_LIT5)));
_return: OMC_LABEL_UNUSED
return _runningTestsuite;
}
modelica_metatype boxptr_Testsuite_isRunning(threadData_t *threadData)
{
modelica_boolean _runningTestsuite;
modelica_metatype out_runningTestsuite;
_runningTestsuite = omc_Testsuite_isRunning(threadData);
out_runningTestsuite = mmc_mk_icon(_runningTestsuite);
return out_runningTestsuite;
}
