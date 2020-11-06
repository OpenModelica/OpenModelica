#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/SimCodeFunction.c"
#endif
#include "omc_simulation_settings.h"
#include "SimCodeFunction.h"
#define _OMC_LIT0_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,1,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "OpenModelica"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,12,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "threadData"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,10,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "ThreadData"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,10,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "OpenModelica_threadData_ThreadData"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,34,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,3,3) {&Tpl_Text_MEM__TEXT__desc,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data ".c"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,2,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "MidC"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,4,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#include "util/modelica.h"
#include "SimCodeFunction_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SimCodeFunction_removeThreadDataFunction(threadData_t *threadData, modelica_metatype _inFuncs, modelica_metatype _inAcc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeFunction_removeThreadDataFunction,2,0) {(void*) boxptr_SimCodeFunction_removeThreadDataFunction,0}};
#define boxvar_SimCodeFunction_removeThreadDataFunction MMC_REFSTRUCTLIT(boxvar_lit_SimCodeFunction_removeThreadDataFunction)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SimCodeFunction_removeThreadDataRecord(threadData_t *threadData, modelica_metatype _inRecs, modelica_metatype _inAcc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SimCodeFunction_removeThreadDataRecord,2,0) {(void*) boxptr_SimCodeFunction_removeThreadDataRecord,0}};
#define boxvar_SimCodeFunction_removeThreadDataRecord MMC_REFSTRUCTLIT(boxvar_lit_SimCodeFunction_removeThreadDataRecord)
DLLExport
modelica_metatype omc_SimCodeFunction_getCalledFunctionsInFunction(threadData_t *threadData, modelica_metatype _path, modelica_metatype _funcs)
{
modelica_metatype _outPaths = NULL;
modelica_metatype _ht = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ht = omc_HashTableStringToPath_emptyHashTable(threadData);
_ht = omc_SimCodeFunctionUtil_getCalledFunctionsInFunction2(threadData, _path, omc_AbsynUtil_pathStringNoQual(threadData, _path, _OMC_LIT0, 0, 0), _ht, _funcs);
_outPaths = omc_BaseHashTable_hashTableValueList(threadData, _ht);
_return: OMC_LABEL_UNUSED
return _outPaths;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SimCodeFunction_removeThreadDataFunction(threadData_t *threadData, modelica_metatype _inFuncs, modelica_metatype _inAcc)
{
modelica_metatype _outFuncs = NULL;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inFuncs;
{
modelica_metatype _rest = NULL;
modelica_metatype _f = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = listReverse(_inAcc);
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,5) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,2) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (12 != MMC_STRLEN(tmpMeta[5]) || strcmp(MMC_STRINGDATA(_OMC_LIT1), MMC_STRINGDATA(tmpMeta[5])) != 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],0,2) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (10 != MMC_STRLEN(tmpMeta[7]) || strcmp(MMC_STRINGDATA(_OMC_LIT2), MMC_STRINGDATA(tmpMeta[7])) != 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],1,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
if (10 != MMC_STRLEN(tmpMeta[9]) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmpMeta[9])) != 0) goto tmp2_end;
_rest = tmpMeta[2];
_inFuncs = _rest;
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_f = tmpMeta[1];
_rest = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_f, _inAcc);
_inFuncs = _rest;
_inAcc = tmpMeta[1];
goto _tailrecursive;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outFuncs = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outFuncs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SimCodeFunction_removeThreadDataRecord(threadData_t *threadData, modelica_metatype _inRecs, modelica_metatype _inAcc)
{
modelica_metatype _outRecs = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inRecs;
{
modelica_metatype _rest = NULL;
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = listReverse(_inAcc);
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (34 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT4), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
_rest = tmpMeta[2];
_inRecs = _rest;
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (12 != MMC_STRLEN(tmpMeta[4]) || strcmp(MMC_STRINGDATA(_OMC_LIT1), MMC_STRINGDATA(tmpMeta[4])) != 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (10 != MMC_STRLEN(tmpMeta[6]) || strcmp(MMC_STRINGDATA(_OMC_LIT2), MMC_STRINGDATA(tmpMeta[6])) != 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (10 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp2_end;
_rest = tmpMeta[2];
_inRecs = _rest;
goto _tailrecursive;
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_r = tmpMeta[1];
_rest = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_r, _inAcc);
_inRecs = _rest;
_inAcc = tmpMeta[1];
goto _tailrecursive;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outRecs = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outRecs;
}
DLLExport
void omc_SimCodeFunction_translateFunctions(threadData_t *threadData, modelica_metatype _program, modelica_string _name, modelica_metatype _optMainFunction, modelica_metatype _idaeElements, modelica_metatype _metarecordTypes, modelica_metatype _inIncludes)
{
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
setGlobalRoot(((modelica_integer) 25), mmc_mk_none());
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _optMainFunction;
tmp3_2 = _idaeElements;
tmp3_3 = _inIncludes;
{
modelica_metatype _daeMainFunction = NULL;
modelica_metatype _mainFunction = NULL;
modelica_metatype _fns = NULL;
modelica_metatype _includes = NULL;
modelica_metatype _libs = NULL;
modelica_metatype _libPaths = NULL;
modelica_metatype _includeDirs = NULL;
modelica_metatype _makefileParams = NULL;
modelica_metatype _fnCode = NULL;
modelica_metatype _extraRecordDecls = NULL;
modelica_metatype _literals = NULL;
modelica_metatype _daeElements = NULL;
modelica_metatype _midCode = NULL;
modelica_metatype _midfuncs = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_daeMainFunction = tmpMeta[0];
_daeElements = tmp3_2;
_includes = tmp3_3;
tmpMeta[0] = mmc_mk_cons(_daeMainFunction, _daeElements);
_daeElements = omc_SimCodeFunctionUtil_findLiterals(threadData, tmpMeta[0] ,&_literals);
tmpMeta[5] = omc_SimCodeFunctionUtil_elaborateFunctions(threadData, _program, _daeElements, _metarecordTypes, _literals, _includes, &tmpMeta[0], &tmpMeta[1], &tmpMeta[2], &tmpMeta[3], &tmpMeta[4]);
if (listEmpty(tmpMeta[5])) goto goto_1;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
_mainFunction = tmpMeta[6];
_fns = tmpMeta[7];
_extraRecordDecls = tmpMeta[0];
_includes = tmpMeta[1];
_includeDirs = tmpMeta[2];
_libs = tmpMeta[3];
_libPaths = tmpMeta[4];
omc_SimCodeFunctionUtil_checkValidMainFunction(threadData, _name, _mainFunction);
_makefileParams = omc_SimCodeFunctionUtil_createMakefileParams(threadData, _includeDirs, _libs, _libPaths, 1, 0);
tmpMeta[0] = mmc_mk_box8(3, &SimCodeFunction_FunctionCode_FUNCTIONCODE__desc, _name, mmc_mk_some(_mainFunction), _fns, _literals, _includes, _makefileParams, _extraRecordDecls);
_fnCode = tmpMeta[0];
if((stringEqual(omc_Config_simCodeTarget(threadData), _OMC_LIT7)))
{
omc_Tpl_tplString(threadData, boxvar_CodegenCFunctions_translateFunctionHeaderFiles, _fnCode);
tmpMeta[0] = mmc_mk_cons(_mainFunction, _fns);
_midfuncs = omc_DAEToMid_DAEFunctionsToMid(threadData, tmpMeta[0]);
tmpMeta[0] = mmc_mk_box3(3, &MidCode_Program_PROGRAM__desc, _name, _midfuncs);
_midCode = omc_Tpl_tplCallWithFailError(threadData, boxvar_CodegenMidToC_genProgram, tmpMeta[0], _OMC_LIT5);
tmpMeta[0] = stringAppend(_name,_OMC_LIT6);
omc_Tpl_textFileConvertLines(threadData, _midCode, tmpMeta[0]);
}
else
{
omc_Tpl_tplString(threadData, boxvar_CodegenCFunctions_translateFunctions, _fnCode);
}
goto tmp2_done;
}
case 1: {
if (!optionNone(tmp3_1)) goto tmp2_end;
_daeElements = tmp3_2;
_includes = tmp3_3;
_daeElements = omc_SimCodeFunctionUtil_findLiterals(threadData, _daeElements ,&_literals);
_fns = omc_SimCodeFunctionUtil_elaborateFunctions(threadData, _program, _daeElements, _metarecordTypes, _literals, _includes ,&_extraRecordDecls ,&_includes ,&_includeDirs ,&_libs ,&_libPaths);
_makefileParams = omc_SimCodeFunctionUtil_createMakefileParams(threadData, _includeDirs, _libs, _libPaths, 1, 0);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_fns = omc_SimCodeFunction_removeThreadDataFunction(threadData, _fns, tmpMeta[0]);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_extraRecordDecls = omc_SimCodeFunction_removeThreadDataRecord(threadData, _extraRecordDecls, tmpMeta[0]);
tmpMeta[0] = mmc_mk_box8(3, &SimCodeFunction_FunctionCode_FUNCTIONCODE__desc, _name, mmc_mk_none(), _fns, _literals, _includes, _makefileParams, _extraRecordDecls);
_fnCode = tmpMeta[0];
if((stringEqual(omc_Config_simCodeTarget(threadData), _OMC_LIT7)))
{
omc_Tpl_tplString(threadData, boxvar_CodegenCFunctions_translateFunctionHeaderFiles, _fnCode);
_midfuncs = omc_DAEToMid_DAEFunctionsToMid(threadData, _fns);
tmpMeta[0] = mmc_mk_box3(3, &MidCode_Program_PROGRAM__desc, _name, _midfuncs);
_midCode = omc_Tpl_tplCallWithFailError(threadData, boxvar_CodegenMidToC_genProgram, tmpMeta[0], _OMC_LIT5);
tmpMeta[0] = stringAppend(_name,_OMC_LIT6);
omc_Tpl_textFileConvertLines(threadData, _midCode, tmpMeta[0]);
}
else
{
omc_Tpl_tplString(threadData, boxvar_CodegenCFunctions_translateFunctions, _fnCode);
}
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
;
_return: OMC_LABEL_UNUSED
return;
}
