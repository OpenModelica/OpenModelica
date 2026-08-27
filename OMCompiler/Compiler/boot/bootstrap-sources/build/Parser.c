#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Parser.c"
#endif
#include "omc_simulation_settings.h"
#include "Parser.h"
#define _OMC_LIT0_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,0,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "<internal>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,10,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "std"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,3,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,1,4) {&Flags_FlagVisibility_EXTERNAL__desc,}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "1.x"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,3,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,2,0) {_OMC_LIT4,MMC_IMMEDIATE(MMC_TAGFIXNUM(10))}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "2.x"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,3,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,2,0) {_OMC_LIT6,MMC_IMMEDIATE(MMC_TAGFIXNUM(20))}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "3.0"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,3,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,2,0) {_OMC_LIT8,MMC_IMMEDIATE(MMC_TAGFIXNUM(30))}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "3.1"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,3,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,2,0) {_OMC_LIT10,MMC_IMMEDIATE(MMC_TAGFIXNUM(31))}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "3.2"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,3,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,2,0) {_OMC_LIT12,MMC_IMMEDIATE(MMC_TAGFIXNUM(32))}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "3.3"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,3,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,2,0) {_OMC_LIT14,MMC_IMMEDIATE(MMC_TAGFIXNUM(33))}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "3.4"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,3,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,2,0) {_OMC_LIT16,MMC_IMMEDIATE(MMC_TAGFIXNUM(34))}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "latest"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,6,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,2,0) {_OMC_LIT18,MMC_IMMEDIATE(MMC_TAGFIXNUM(1000))}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "3.5"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,3,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,2,0) {_OMC_LIT20,MMC_IMMEDIATE(MMC_TAGFIXNUM(1035))}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "experimental"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,12,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,2,0) {_OMC_LIT22,MMC_IMMEDIATE(MMC_TAGFIXNUM(9999))}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,2,1) {_OMC_LIT23,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,2,1) {_OMC_LIT21,_OMC_LIT24}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,2,1) {_OMC_LIT19,_OMC_LIT25}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,2,1) {_OMC_LIT17,_OMC_LIT26}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,2,1) {_OMC_LIT15,_OMC_LIT27}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,2,1) {_OMC_LIT13,_OMC_LIT28}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,2,1) {_OMC_LIT11,_OMC_LIT29}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,2,1) {_OMC_LIT9,_OMC_LIT30}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,2,1) {_OMC_LIT7,_OMC_LIT31}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,2,1) {_OMC_LIT5,_OMC_LIT32}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,3,10) {&Flags_FlagData_ENUM__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1000)),_OMC_LIT33}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,2,1) {_OMC_LIT22,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,2,1) {_OMC_LIT20,_OMC_LIT35}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,2,1) {_OMC_LIT18,_OMC_LIT36}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,2,1) {_OMC_LIT16,_OMC_LIT37}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,2,1) {_OMC_LIT14,_OMC_LIT38}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,2,1) {_OMC_LIT12,_OMC_LIT39}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,2,1) {_OMC_LIT10,_OMC_LIT40}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT42,2,1) {_OMC_LIT6,_OMC_LIT41}};
#define _OMC_LIT42 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT42)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT43,2,1) {_OMC_LIT4,_OMC_LIT42}};
#define _OMC_LIT43 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,2,3) {&Flags_ValidOptions_STRING__OPTION__desc,_OMC_LIT43}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,1,1) {_OMC_LIT44}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "Sets the language standard that should be used."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,47,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT46}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(8)),_OMC_LIT2,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT3,_OMC_LIT34,_OMC_LIT45,_OMC_LIT47}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "<interactive>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,13,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
#include "util/modelica.h"
#include "Parser_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_loadFileThread(threadData_t *threadData, modelica_metatype _inFileEncoding);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_loadFileThread,2,0) {(void*) boxptr_Parser_loadFileThread,0}};
#define boxvar_Parser_loadFileThread MMC_REFSTRUCTLIT(boxvar_lit_Parser_loadFileThread)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_parallelParseFilesWork(threadData_t *threadData, modelica_metatype _filenames, modelica_string _encoding, modelica_integer _numThreads, modelica_string _libraryPath, modelica_metatype _lveInstance);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Parser_parallelParseFilesWork(threadData_t *threadData, modelica_metatype _filenames, modelica_metatype _encoding, modelica_metatype _numThreads, modelica_metatype _libraryPath, modelica_metatype _lveInstance);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Parser_parallelParseFilesWork,2,0) {(void*) boxptr_Parser_parallelParseFilesWork,0}};
#define boxvar_Parser_parallelParseFilesWork MMC_REFSTRUCTLIT(boxvar_lit_Parser_parallelParseFilesWork)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_loadFileThread(threadData_t *threadData, modelica_metatype _inFileEncoding)
{
modelica_metatype _result = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inFileEncoding;
{
modelica_string _filename = NULL;
modelica_string _encoding = NULL;
modelica_string _libraryPath = NULL;
modelica_metatype _lveInstance = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_filename = tmpMeta[1];
_encoding = tmpMeta[2];
_libraryPath = tmpMeta[3];
_lveInstance = tmpMeta[4];
tmpMeta[1] = mmc_mk_box3(3, &Parser_ParserResult_PARSERRESULT__desc, _filename, mmc_mk_some(omc_Parser_parse(threadData, _filename, _encoding, _libraryPath, _lveInstance)));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_filename = tmpMeta[1];
tmpMeta[1] = mmc_mk_box3(3, &Parser_ParserResult_PARSERRESULT__desc, _filename, mmc_mk_none());
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
tmp2_done:
(void)tmp3;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp2_done2;
goto_1:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp3 < 2) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_result = tmpMeta[0];
if((omc_ErrorExt_getNumMessages(threadData) > ((modelica_integer) 0)))
{
omc_ErrorExt_moveMessagesToParentThread(threadData);
}
_return: OMC_LABEL_UNUSED
return _result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_Parser_parallelParseFilesWork(threadData_t *threadData, modelica_metatype _filenames, modelica_string _encoding, modelica_integer _numThreads, modelica_string _libraryPath, modelica_metatype _lveInstance)
{
modelica_metatype _partialResults = NULL;
modelica_metatype _workList = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar0;
int tmp2;
modelica_metatype _file_loopVar = 0;
modelica_metatype _file;
_file_loopVar = _filenames;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar1;
while(1) {
tmp2 = 1;
if (!listEmpty(_file_loopVar)) {
_file = MMC_CAR(_file_loopVar);
_file_loopVar = MMC_CDR(_file_loopVar);
tmp2--;
}
if (tmp2 == 0) {
tmpMeta[2] = mmc_mk_box4(0, _file, _encoding, _libraryPath, _lveInstance);
__omcQ_24tmpVar0 = tmpMeta[2];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar1;
}
_workList = tmpMeta[0];
if(((((omc_Testsuite_isRunning(threadData) || (omc_Config_noProc(threadData) == ((modelica_integer) 1))) || (_numThreads == ((modelica_integer) 1))) || (listLength(_filenames) < ((modelica_integer) 2))) || (!(stringEqual(_libraryPath, _OMC_LIT0)))))
{
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp3;
modelica_metatype __omcQ_24tmpVar2;
int tmp4;
modelica_metatype _t_loopVar = 0;
modelica_metatype _t;
_t_loopVar = _workList;
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta[4];
tmp3 = &__omcQ_24tmpVar3;
while(1) {
tmp4 = 1;
if (!listEmpty(_t_loopVar)) {
_t = MMC_CAR(_t_loopVar);
_t_loopVar = MMC_CDR(_t_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar2 = omc_Parser_loadFileThread(threadData, _t);
*tmp3 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp3 = &MMC_CDR(*tmp3);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp3 = mmc_mk_nil();
tmpMeta[3] = __omcQ_24tmpVar3;
}
_partialResults = tmpMeta[3];
}
else
{
_partialResults = omc_System_launchParallelTasks(threadData, modelica_integer_min((modelica_integer)(((modelica_integer) 8)),(modelica_integer)(_numThreads)), _workList, boxvar_Parser_loadFileThread);
}
_return: OMC_LABEL_UNUSED
return _partialResults;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Parser_parallelParseFilesWork(threadData_t *threadData, modelica_metatype _filenames, modelica_metatype _encoding, modelica_metatype _numThreads, modelica_metatype _libraryPath, modelica_metatype _lveInstance)
{
modelica_integer tmp1;
modelica_metatype _partialResults = NULL;
tmp1 = mmc_unbox_integer(_numThreads);
_partialResults = omc_Parser_parallelParseFilesWork(threadData, _filenames, _encoding, tmp1, _libraryPath, _lveInstance);
return _partialResults;
}
DLLExport
void omc_Parser_stopLibraryVendorExecutable(threadData_t *threadData, modelica_metatype _lveInstance)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_ParserExt_stopLibraryVendorExecutable(threadData, _lveInstance);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Parser_checkLVEToolFeature(threadData_t *threadData, modelica_metatype _lveInstance, modelica_string _feature)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_ParserExt_checkLVEToolFeature(threadData, _lveInstance, _feature);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_boolean omc_Parser_checkLVEToolLicense(threadData_t *threadData, modelica_metatype _lveInstance, modelica_string _packageName)
{
modelica_boolean _status;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_status = omc_ParserExt_checkLVEToolLicense(threadData, _lveInstance, _packageName);
_return: OMC_LABEL_UNUSED
return _status;
}
modelica_metatype boxptr_Parser_checkLVEToolLicense(threadData_t *threadData, modelica_metatype _lveInstance, modelica_metatype _packageName)
{
modelica_boolean _status;
modelica_metatype out_status;
_status = omc_Parser_checkLVEToolLicense(threadData, _lveInstance, _packageName);
out_status = mmc_mk_icon(_status);
return out_status;
}
DLLExport
modelica_boolean omc_Parser_startLibraryVendorExecutable(threadData_t *threadData, modelica_string _lvePath, modelica_metatype *out_lveInstance)
{
modelica_boolean _success;
modelica_metatype _lveInstance = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_success = omc_ParserExt_startLibraryVendorExecutable(threadData, _lvePath ,&_lveInstance);
_return: OMC_LABEL_UNUSED
if (out_lveInstance) { *out_lveInstance = _lveInstance; }
return _success;
}
modelica_metatype boxptr_Parser_startLibraryVendorExecutable(threadData_t *threadData, modelica_metatype _lvePath, modelica_metatype *out_lveInstance)
{
modelica_boolean _success;
modelica_metatype out_success;
_success = omc_Parser_startLibraryVendorExecutable(threadData, _lvePath, out_lveInstance);
out_success = mmc_mk_icon(_success);
return out_success;
}
DLLExport
modelica_metatype omc_Parser_parallelParseFilesToProgramList(threadData_t *threadData, modelica_metatype _filenames, modelica_string _encoding, modelica_integer _numThreads)
{
modelica_metatype _result = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_result = tmpMeta[0];
{
modelica_metatype _r;
for (tmpMeta[1] = omc_Parser_parallelParseFilesWork(threadData, _filenames, _encoding, _numThreads, _OMC_LIT0, mmc_mk_none()); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_r = MMC_CAR(tmpMeta[1]);
{
modelica_metatype tmp3_1;
tmp3_1 = _r;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (optionNone(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 1));
_p = tmpMeta[5];
tmpMeta[3] = _p;
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
}tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _result);
_result = tmpMeta[2];
}
}
_result = listReverseInPlace(_result);
_return: OMC_LABEL_UNUSED
return _result;
}
modelica_metatype boxptr_Parser_parallelParseFilesToProgramList(threadData_t *threadData, modelica_metatype _filenames, modelica_metatype _encoding, modelica_metatype _numThreads)
{
modelica_integer tmp1;
modelica_metatype _result = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
tmp1 = mmc_unbox_integer(_numThreads);
_result = omc_Parser_parallelParseFilesToProgramList(threadData, _filenames, _encoding, tmp1);
return _result;
}
DLLExport
modelica_metatype omc_Parser_parallelParseFiles(threadData_t *threadData, modelica_metatype _filenames, modelica_string _encoding, modelica_integer _numThreads, modelica_string _libraryPath, modelica_metatype _lveInstance)
{
modelica_metatype _ht = NULL;
modelica_metatype _partialResults = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_partialResults = omc_Parser_parallelParseFilesWork(threadData, _filenames, _encoding, _numThreads, _libraryPath, _lveInstance);
_ht = omc_HashTableStringToProgram_emptyHashTableSized(threadData, omc_Util_nextPrime(threadData, listLength(_partialResults)));
{
modelica_metatype _res;
for (tmpMeta[0] = _partialResults; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_res = MMC_CAR(tmpMeta[0]);
{
modelica_metatype tmp3_1;
tmp3_1 = _res;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_p = tmpMeta[3];
tmpMeta[2] = mmc_mk_box2(0, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_res), 2))), _p);
tmpMeta[1] = omc_BaseHashTable_add(threadData, tmpMeta[2], _ht);
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
_ht = tmpMeta[1];
}
}
_return: OMC_LABEL_UNUSED
return _ht;
}
modelica_metatype boxptr_Parser_parallelParseFiles(threadData_t *threadData, modelica_metatype _filenames, modelica_metatype _encoding, modelica_metatype _numThreads, modelica_metatype _libraryPath, modelica_metatype _lveInstance)
{
modelica_integer tmp1;
modelica_metatype _ht = NULL;
tmp1 = mmc_unbox_integer(_numThreads);
_ht = omc_Parser_parallelParseFiles(threadData, _filenames, _encoding, tmp1, _libraryPath, _lveInstance);
return _ht;
}
DLLExport
modelica_metatype omc_Parser_stringCref(threadData_t *threadData, modelica_string _str)
{
modelica_metatype _cref = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref = omc_ParserExt_stringCref(threadData, _str, _OMC_LIT1, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT48), omc_Testsuite_isRunning(threadData));
_return: OMC_LABEL_UNUSED
return _cref;
}
DLLExport
modelica_metatype omc_Parser_stringPath(threadData_t *threadData, modelica_string _str)
{
modelica_metatype _path = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_path = omc_ParserExt_stringPath(threadData, _str, _OMC_LIT1, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT48), omc_Testsuite_isRunning(threadData));
_return: OMC_LABEL_UNUSED
return _path;
}
DLLExport
modelica_metatype omc_Parser_parsestringexp(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename)
{
modelica_metatype _outStatements = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStatements = omc_ParserExt_parsestringexp(threadData, _str, _infoFilename, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT48), omc_Testsuite_isRunning(threadData));
_return: OMC_LABEL_UNUSED
return _outStatements;
}
DLLExport
modelica_metatype omc_Parser_parsebuiltin(threadData_t *threadData, modelica_string _filename, modelica_string _encoding, modelica_string _libraryPath, modelica_metatype _lveInstance, modelica_integer _acceptedGram, modelica_integer _languageStandardInt)
{
modelica_metatype _outProgram = NULL;
modelica_string _realpath = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_realpath = omc_Util_replaceWindowsBackSlashWithPathDelimiter(threadData, omc_System_realpath(threadData, _filename));
_outProgram = omc_ParserExt_parse(threadData, _realpath, omc_Testsuite_friendly(threadData, _realpath), _acceptedGram, _encoding, _languageStandardInt, omc_Testsuite_isRunning(threadData), _libraryPath, _lveInstance);
_return: OMC_LABEL_UNUSED
return _outProgram;
}
modelica_metatype boxptr_Parser_parsebuiltin(threadData_t *threadData, modelica_metatype _filename, modelica_metatype _encoding, modelica_metatype _libraryPath, modelica_metatype _lveInstance, modelica_metatype _acceptedGram, modelica_metatype _languageStandardInt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_acceptedGram);
tmp2 = mmc_unbox_integer(_languageStandardInt);
_outProgram = omc_Parser_parsebuiltin(threadData, _filename, _encoding, _libraryPath, _lveInstance, tmp1, tmp2);
return _outProgram;
}
DLLExport
modelica_metatype omc_Parser_parsestring(threadData_t *threadData, modelica_string _str, modelica_string _infoFilename)
{
modelica_metatype _outProgram = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outProgram = omc_ParserExt_parsestring(threadData, _str, _infoFilename, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT48), omc_Testsuite_isRunning(threadData));
omc_AbsynToSCode_translateAbsyn2SCode(threadData, _outProgram);
_return: OMC_LABEL_UNUSED
return _outProgram;
}
DLLExport
modelica_metatype omc_Parser_parseexp(threadData_t *threadData, modelica_string _filename)
{
modelica_metatype _outStatements = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStatements = omc_ParserExt_parseexp(threadData, omc_System_realpath(threadData, _filename), omc_Testsuite_friendly(threadData, omc_System_realpath(threadData, _filename)), omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT48), omc_Testsuite_isRunning(threadData));
_return: OMC_LABEL_UNUSED
return _outStatements;
}
DLLExport
modelica_metatype omc_Parser_parse(threadData_t *threadData, modelica_string _filename, modelica_string _encoding, modelica_string _libraryPath, modelica_metatype _lveInstance)
{
modelica_metatype _outProgram = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outProgram = omc_Parser_parsebuiltin(threadData, _filename, _encoding, _libraryPath, _lveInstance, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT48));
omc_AbsynToSCode_translateAbsyn2SCode(threadData, _outProgram);
_return: OMC_LABEL_UNUSED
return _outProgram;
}
