#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "SimCodeFunction.c"
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inFuncs;
{
modelica_metatype _rest = NULL;
modelica_metatype _f = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = listReverse(_inAcc);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,4,5) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (12 != MMC_STRLEN(tmpMeta10) || strcmp(MMC_STRINGDATA(_OMC_LIT1), MMC_STRINGDATA(tmpMeta10)) != 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (10 != MMC_STRLEN(tmpMeta12) || strcmp(MMC_STRINGDATA(_OMC_LIT2), MMC_STRINGDATA(tmpMeta12)) != 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,1,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
if (10 != MMC_STRLEN(tmpMeta14) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmpMeta14)) != 0) goto tmp3_end;
_rest = tmpMeta7;
_inFuncs = _rest;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_1);
tmpMeta16 = MMC_CDR(tmp4_1);
_f = tmpMeta15;
_rest = tmpMeta16;
tmpMeta17 = mmc_mk_cons(_f, _inAcc);
_inFuncs = _rest;
_inAcc = tmpMeta17;
goto _tailrecursive;
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
_outFuncs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outFuncs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SimCodeFunction_removeThreadDataRecord(threadData_t *threadData, modelica_metatype _inRecs, modelica_metatype _inAcc)
{
modelica_metatype _outRecs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRecs;
{
modelica_metatype _rest = NULL;
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = listReverse(_inAcc);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (34 != MMC_STRLEN(tmpMeta8) || strcmp(MMC_STRINGDATA(_OMC_LIT4), MMC_STRINGDATA(tmpMeta8)) != 0) goto tmp3_end;
_rest = tmpMeta7;
_inRecs = _rest;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_1);
tmpMeta10 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,2,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (12 != MMC_STRLEN(tmpMeta12) || strcmp(MMC_STRINGDATA(_OMC_LIT1), MMC_STRINGDATA(tmpMeta12)) != 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
if (10 != MMC_STRLEN(tmpMeta14) || strcmp(MMC_STRINGDATA(_OMC_LIT2), MMC_STRINGDATA(tmpMeta14)) != 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,1,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
if (10 != MMC_STRLEN(tmpMeta16) || strcmp(MMC_STRINGDATA(_OMC_LIT3), MMC_STRINGDATA(tmpMeta16)) != 0) goto tmp3_end;
_rest = tmpMeta10;
_inRecs = _rest;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta17 = MMC_CAR(tmp4_1);
tmpMeta18 = MMC_CDR(tmp4_1);
_r = tmpMeta17;
_rest = tmpMeta18;
tmpMeta19 = mmc_mk_cons(_r, _inAcc);
_inRecs = _rest;
_inAcc = tmpMeta19;
goto _tailrecursive;
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
_outRecs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRecs;
}
DLLExport
void omc_SimCodeFunction_translateFunctions(threadData_t *threadData, modelica_metatype _program, modelica_string _name, modelica_metatype _optMainFunction, modelica_metatype _idaeElements, modelica_metatype _metarecordTypes, modelica_metatype _inIncludes)
{
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
modelica_metatype tmpMeta5;
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
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_daeMainFunction = tmpMeta5;
_daeElements = tmp3_2;
_includes = tmp3_3;
tmpMeta6 = mmc_mk_cons(_daeMainFunction, _daeElements);
_daeElements = omc_SimCodeFunctionUtil_findLiterals(threadData, tmpMeta6 ,&_literals);
tmpMeta12 = omc_SimCodeFunctionUtil_elaborateFunctions(threadData, _program, _daeElements, _metarecordTypes, _literals, _includes, &tmpMeta7, &tmpMeta8, &tmpMeta9, &tmpMeta10, &tmpMeta11);
if (listEmpty(tmpMeta12)) goto goto_1;
tmpMeta13 = MMC_CAR(tmpMeta12);
tmpMeta14 = MMC_CDR(tmpMeta12);
_mainFunction = tmpMeta13;
_fns = tmpMeta14;
_extraRecordDecls = tmpMeta7;
_includes = tmpMeta8;
_includeDirs = tmpMeta9;
_libs = tmpMeta10;
_libPaths = tmpMeta11;
omc_SimCodeFunctionUtil_checkValidMainFunction(threadData, _name, _mainFunction);
_makefileParams = omc_SimCodeFunctionUtil_createMakefileParams(threadData, _includeDirs, _libs, _libPaths, 1, 0);
tmpMeta15 = mmc_mk_box8(3, &SimCodeFunction_FunctionCode_FUNCTIONCODE__desc, _name, mmc_mk_some(_mainFunction), _fns, _literals, _includes, _makefileParams, _extraRecordDecls);
_fnCode = tmpMeta15;
if((stringEqual(omc_Config_simCodeTarget(threadData), _OMC_LIT7)))
{
omc_Tpl_tplString(threadData, boxvar_CodegenCFunctions_translateFunctionHeaderFiles, _fnCode);
tmpMeta16 = mmc_mk_cons(_mainFunction, _fns);
_midfuncs = omc_DAEToMid_DAEFunctionsToMid(threadData, tmpMeta16);
tmpMeta17 = mmc_mk_box3(3, &MidCode_Program_PROGRAM__desc, _name, _midfuncs);
_midCode = omc_Tpl_tplCallWithFailError(threadData, boxvar_CodegenMidToC_genProgram, tmpMeta17, _OMC_LIT5);
tmpMeta18 = stringAppend(_name,_OMC_LIT6);
omc_Tpl_textFileConvertLines(threadData, _midCode, tmpMeta18);
}
else
{
omc_Tpl_tplString(threadData, boxvar_CodegenCFunctions_translateFunctions, _fnCode);
}
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (!optionNone(tmp3_1)) goto tmp2_end;
_daeElements = tmp3_2;
_includes = tmp3_3;
_daeElements = omc_SimCodeFunctionUtil_findLiterals(threadData, _daeElements ,&_literals);
_fns = omc_SimCodeFunctionUtil_elaborateFunctions(threadData, _program, _daeElements, _metarecordTypes, _literals, _includes ,&_extraRecordDecls ,&_includes ,&_includeDirs ,&_libs ,&_libPaths);
_makefileParams = omc_SimCodeFunctionUtil_createMakefileParams(threadData, _includeDirs, _libs, _libPaths, 1, 0);
tmpMeta19 = MMC_REFSTRUCTLIT(mmc_nil);
_fns = omc_SimCodeFunction_removeThreadDataFunction(threadData, _fns, tmpMeta19);
tmpMeta20 = MMC_REFSTRUCTLIT(mmc_nil);
_extraRecordDecls = omc_SimCodeFunction_removeThreadDataRecord(threadData, _extraRecordDecls, tmpMeta20);
tmpMeta21 = mmc_mk_box8(3, &SimCodeFunction_FunctionCode_FUNCTIONCODE__desc, _name, mmc_mk_none(), _fns, _literals, _includes, _makefileParams, _extraRecordDecls);
_fnCode = tmpMeta21;
if((stringEqual(omc_Config_simCodeTarget(threadData), _OMC_LIT7)))
{
omc_Tpl_tplString(threadData, boxvar_CodegenCFunctions_translateFunctionHeaderFiles, _fnCode);
_midfuncs = omc_DAEToMid_DAEFunctionsToMid(threadData, _fns);
tmpMeta22 = mmc_mk_box3(3, &MidCode_Program_PROGRAM__desc, _name, _midfuncs);
_midCode = omc_Tpl_tplCallWithFailError(threadData, boxvar_CodegenMidToC_genProgram, tmpMeta22, _OMC_LIT5);
tmpMeta23 = stringAppend(_name,_OMC_LIT6);
omc_Tpl_textFileConvertLines(threadData, _midCode, tmpMeta23);
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
