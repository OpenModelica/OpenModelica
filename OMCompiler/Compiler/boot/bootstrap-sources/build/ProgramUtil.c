#include "omc_simulation_settings.h"
#include "ProgramUtil.h"
#define _OMC_LIT0_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,0,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "/"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,1,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,1,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data ".mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,3,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,1,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data ";"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,1,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "default"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,7,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,2,1) {_OMC_LIT6,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "Could not resolve modelica://"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,29,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data " with MODELICAPATH: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,20,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "%s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,2,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(5999)),_OMC_LIT10,_OMC_LIT11,_OMC_LIT12}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "modelica://"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,11,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "file://"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,7,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,1,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "work\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,5,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "Class %s not found in scope %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,31,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(3)),_OMC_LIT10,_OMC_LIT11,_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "<TOP>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,5,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "Failed in replaceInnerClass\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,28,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,1,4) {&Absyn_Within_TOP__desc,}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "\n  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,3,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,1,8) {&ErrorTypes_MessageType_SCRIPTING__desc,}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "Failed to insert class %s %s the available classes were:%s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,58,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(213)),_OMC_LIT25,_OMC_LIT11,_OMC_LIT26}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "OpenModelica"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,12,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#include "util/modelica.h"
#include "ProgramUtil_includes.h"
DLLDirection
modelica_string omc_ProgramUtil_findModelicaPath2(threadData_t *threadData, modelica_string _mp, modelica_metatype _inames, modelica_string _version, modelica_boolean _b)
{
modelica_string _basePath = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_boolean tmp4_2;
tmp4_1 = _inames;
tmp4_2 = _b;
{
modelica_metatype _names = NULL;
modelica_string _name = NULL;
modelica_string _file = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_boolean tmp13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_name = tmpMeta6;
_names = tmpMeta7;
tmp8 = (stringEqual(_version, _OMC_LIT0));
if (0 /* false */ != tmp8) goto goto_2;
tmpMeta9 = stringAppend(_mp,_OMC_LIT1);
tmpMeta10 = stringAppend(tmpMeta9,_name);
tmpMeta11 = stringAppend(tmpMeta10,_OMC_LIT2);
tmpMeta12 = stringAppend(tmpMeta11,_version);
_file = tmpMeta12;
tmp13 = omc_System_directoryExists(threadData, _file);
if (1 /* true */ != tmp13) goto goto_2;
tmp1 = omc_ProgramUtil_findModelicaPath2(threadData, _file, _names, _OMC_LIT0, 1 /* true */);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_boolean tmp16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_boolean tmp22;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmp4_1);
tmpMeta15 = MMC_CDR(tmp4_1);
_name = tmpMeta14;
tmp16 = (stringEqual(_version, _OMC_LIT0));
if (0 /* false */ != tmp16) goto goto_2;
tmpMeta17 = stringAppend(_mp,_OMC_LIT1);
tmpMeta18 = stringAppend(tmpMeta17,_name);
tmpMeta19 = stringAppend(tmpMeta18,_OMC_LIT2);
tmpMeta20 = stringAppend(tmpMeta19,_version);
tmpMeta21 = stringAppend(tmpMeta20,_OMC_LIT3);
_file = tmpMeta21;
tmp22 = omc_System_regularFileExists(threadData, _file);
if (1 /* true */ != tmp22) goto goto_2;
tmp1 = _mp;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_boolean tmp27;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta23 = MMC_CAR(tmp4_1);
tmpMeta24 = MMC_CDR(tmp4_1);
_name = tmpMeta23;
_names = tmpMeta24;
tmpMeta25 = stringAppend(_mp,_OMC_LIT1);
tmpMeta26 = stringAppend(tmpMeta25,_name);
_file = tmpMeta26;
tmp27 = omc_System_directoryExists(threadData, _file);
if (1 /* true */ != tmp27) goto goto_2;
tmp1 = omc_ProgramUtil_findModelicaPath2(threadData, _file, _names, _OMC_LIT0, 1 /* true */);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_boolean tmp33;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta28 = MMC_CAR(tmp4_1);
tmpMeta29 = MMC_CDR(tmp4_1);
_name = tmpMeta28;
tmpMeta30 = stringAppend(_mp,_OMC_LIT1);
tmpMeta31 = stringAppend(tmpMeta30,_name);
tmpMeta32 = stringAppend(tmpMeta31,_OMC_LIT3);
_file = tmpMeta32;
tmp33 = omc_System_regularFileExists(threadData, _file);
if (1 /* true */ != tmp33) goto goto_2;
tmp1 = _mp;
goto tmp3_done;
}
case 4: {
if (1 /* true */ != tmp4_2) goto tmp3_end;
tmp1 = _mp;
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
if (++tmp4 < 5) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_basePath = tmp1;
_return: OMC_LABEL_UNUSED
return _basePath;
}
modelica_metatype boxptr_ProgramUtil_findModelicaPath2(threadData_t *threadData, modelica_metatype _mp, modelica_metatype _inames, modelica_metatype _version, modelica_metatype _b)
{
modelica_integer tmp1;
modelica_string _basePath = NULL;
tmp1 = mmc_unbox_integer(_b);
_basePath = omc_ProgramUtil_findModelicaPath2(threadData, _mp, _inames, _version, tmp1);
return _basePath;
}
DLLDirection
modelica_string omc_ProgramUtil_findModelicaPath(threadData_t *threadData, modelica_metatype _imps, modelica_metatype _names, modelica_string _version)
{
modelica_string _basePath = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _imps;
{
modelica_string _mp = NULL;
modelica_metatype _mps = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_mp = tmpMeta6;
tmp1 = omc_ProgramUtil_findModelicaPath2(threadData, _mp, _names, _version, 0 /* false */);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
_mps = tmpMeta9;
tmp1 = omc_ProgramUtil_findModelicaPath(threadData, _mps, _names, _version);
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
_basePath = tmp1;
_return: OMC_LABEL_UNUSED
return _basePath;
}
DLLDirection
modelica_string omc_ProgramUtil_getBasePathFromUri(threadData_t *threadData, modelica_string _scheme, modelica_string _iname, modelica_metatype _program, modelica_string _modelicaPath, modelica_boolean _printError)
{
modelica_string _basePath = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_string tmp4_1;volatile modelica_string tmp4_2;volatile modelica_string tmp4_3;volatile modelica_boolean tmp4_4;
tmp4_1 = _scheme;
tmp4_2 = _iname;
tmp4_3 = _modelicaPath;
tmp4_4 = _printError;
{
modelica_boolean _isDir;
modelica_metatype _mps = NULL;
modelica_metatype _names = NULL;
modelica_string _gd = NULL;
modelica_string _mp = NULL;
modelica_string _str = NULL;
modelica_string _name = NULL;
modelica_string _fileName = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (11 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT14), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
_name = tmp4_2;
tmpMeta6 = omc_System_strtok(threadData, _name, _OMC_LIT4);
if (listEmpty(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_name = tmpMeta7;
_names = tmpMeta8;
tmpMeta9 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
tmpMeta10 = omc_ProgramUtil_getPathedClassInProgram(threadData, tmpMeta9, _program, 0 /* false */, 0 /* false */);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 11));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_fileName = tmpMeta12;
_mp = omc_System_dirname(threadData, _fileName);
tmp1 = omc_ProgramUtil_findModelicaPath2(threadData, _mp, _names, _OMC_LIT0, 1 /* true */);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_boolean tmp16;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_boolean tmp20;
modelica_string tmp21;
if (11 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT14), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
_name = tmp4_2;
_mp = tmp4_3;
tmp4 += 1;
tmpMeta13 = omc_System_strtok(threadData, _name, _OMC_LIT4);
if (listEmpty(tmpMeta13)) goto goto_2;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
_name = tmpMeta14;
_names = tmpMeta15;
tmp16 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmpMeta18 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
omc_ProgramUtil_getPathedClassInProgram(threadData, tmpMeta18, _program, 0 /* false */, 0 /* false */);
tmp16 = 1;
goto goto_17;
goto_17:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp16) {goto goto_2;}
_gd = _OMC_LIT5;
_mps = omc_System_strtok(threadData, _mp, _gd);
_mp = omc_System_getLoadModelPath(threadData, _name, _OMC_LIT7, _mps, 0 /* false */ ,&_name ,&_isDir);
tmp20 = (modelica_boolean)_isDir;
if(tmp20)
{
tmpMeta19 = stringAppend(_mp,_name);
tmp21 = tmpMeta19;
}
else
{
tmp21 = _mp;
}
_mp = tmp21;
tmp1 = omc_ProgramUtil_findModelicaPath2(threadData, _mp, _names, _OMC_LIT0, 1 /* true */);
goto tmp3_done;
}
case 2: {
if (7 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT15), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmp4 += 1;
tmp1 = _OMC_LIT0;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (1 /* true */ != tmp4_4) goto tmp3_end;
if (11 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT14), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
_name = tmp4_2;
_mp = tmp4_3;
tmpMeta22 = omc_System_strtok(threadData, _name, _OMC_LIT4);
if (listEmpty(tmpMeta22)) goto goto_2;
tmpMeta23 = MMC_CAR(tmpMeta22);
tmpMeta24 = MMC_CDR(tmpMeta22);
_name = tmpMeta23;
tmpMeta25 = stringAppend(_OMC_LIT8,_name);
tmpMeta26 = stringAppend(tmpMeta25,_OMC_LIT9);
tmpMeta27 = stringAppend(tmpMeta26,_mp);
_str = tmpMeta27;
tmpMeta28 = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT13, tmpMeta28);
goto goto_2;
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
if (++tmp4 < 4) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_basePath = tmp1;
_return: OMC_LABEL_UNUSED
return _basePath;
}
modelica_metatype boxptr_ProgramUtil_getBasePathFromUri(threadData_t *threadData, modelica_metatype _scheme, modelica_metatype _iname, modelica_metatype _program, modelica_metatype _modelicaPath, modelica_metatype _printError)
{
modelica_integer tmp1;
modelica_string _basePath = NULL;
tmp1 = mmc_unbox_integer(_printError);
_basePath = omc_ProgramUtil_getBasePathFromUri(threadData, _scheme, _iname, _program, _modelicaPath, tmp1);
return _basePath;
}
DLLDirection
modelica_string omc_ProgramUtil_getFullPathFromUri(threadData_t *threadData, modelica_metatype _program, modelica_string _uri, modelica_boolean _printError)
{
modelica_string _path = NULL;
modelica_string _str1 = NULL;
modelica_string _str2 = NULL;
modelica_string _str3 = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str1 = omc_System_uriToClassAndPath(threadData, _uri ,&_str2 ,&_str3);
tmpMeta1 = stringAppend(omc_ProgramUtil_getBasePathFromUri(threadData, _str1, _str2, _program, omc_Settings_getModelicaPath(threadData, omc_Testsuite_isRunning(threadData)), _printError),_str3);
_path = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _path;
}
modelica_metatype boxptr_ProgramUtil_getFullPathFromUri(threadData_t *threadData, modelica_metatype _program, modelica_metatype _uri, modelica_metatype _printError)
{
modelica_integer tmp1;
modelica_string _path = NULL;
tmp1 = mmc_unbox_integer(_printError);
_path = omc_ProgramUtil_getFullPathFromUri(threadData, _program, _uri, tmp1);
return _path;
}
DLLDirection
modelica_string omc_ProgramUtil_getFileDir(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inProgram)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inComponentRef;
tmp4_2 = _inProgram;
{
modelica_metatype _p_class = NULL;
modelica_metatype _cdef = NULL;
modelica_string _filename = NULL;
modelica_string _pd = NULL;
modelica_string _omhome = NULL;
modelica_string _omhome_1 = NULL;
modelica_string _pd_1 = NULL;
modelica_metatype _filename_1 = NULL;
modelica_metatype _dir = NULL;
modelica_metatype _class_ = NULL;
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
_class_ = tmp4_1;
_p = tmp4_2;
_p_class = omc_AbsynUtil_crefToPath(threadData, _class_);
_cdef = omc_ProgramUtil_getPathedClassInProgram(threadData, _p_class, _p, 0 /* false */, 0 /* false */);
_filename = omc_AbsynUtil_classFilename(threadData, _cdef);
_pd = _OMC_LIT1;
tmpMeta6 = stringListStringChar(_pd);
if (listEmpty(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_pd_1 = tmpMeta7;
_filename_1 = omc_Util_stringSplitAtChar(threadData, _filename, _pd_1);
_dir = omc_List_stripLast(threadData, _filename_1);
tmp1 = stringDelimitList(_dir, _pd);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
_omhome = omc_Settings_getInstallationDirectoryPath(threadData);
_omhome_1 = omc_System_trim(threadData, _omhome, _OMC_LIT16);
_pd = _OMC_LIT1;
tmpMeta9 = mmc_mk_cons(_OMC_LIT16, mmc_mk_cons(_omhome_1, mmc_mk_cons(_pd, mmc_mk_cons(_OMC_LIT17, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta9);
goto tmp3_done;
}
case 2: {
tmp1 = _OMC_LIT0;
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
if (++tmp4 < 3) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getNamedAnnotationExp(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _id, modelica_metatype _default, modelica_fnptr _f)
{
modelica_metatype _outString = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inPath;
tmp4_2 = _inProgram;
tmp4_3 = _default;
{
modelica_metatype _cdef = NULL;
modelica_metatype _str = NULL;
modelica_metatype _modelpath = NULL;
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_modelpath = tmp4_1;
_p = tmp4_2;
_cdef = omc_ProgramUtil_getPathedClassInProgram(threadData, _modelpath, _p, 0 /* false */, 0 /* false */);
tmpMeta6 = omc_AbsynUtil_getNamedAnnotationInClass(threadData, _cdef, _id, ((modelica_fnptr) _f));
if (optionNone(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
_str = tmpMeta7;
tmpMeta1 = _str;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
if (optionNone(tmp4_3)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 1));
_str = tmpMeta8;
tmpMeta1 = _str;
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
_outString = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLDirection
modelica_string omc_ProgramUtil_getDefaultComponentPrefixesModStr(threadData_t *threadData, modelica_metatype _mod)
{
modelica_string _docStr = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _mod;
{
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_e = tmpMeta8;
tmp1 = omc_Dump_printExpStr(threadData, _e);
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT0;
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
_docStr = tmp1;
_return: OMC_LABEL_UNUSED
return _docStr;
}
DLLDirection
modelica_metatype omc_ProgramUtil_joinPaths(threadData_t *threadData, modelica_string _child, modelica_metatype _parent)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _child;
tmp4_2 = _parent;
{
modelica_metatype _r = NULL;
modelica_string _c = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
_c = tmp4_1;
_r = tmp4_2;
tmpMeta6 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _c);
tmpMeta1 = omc_AbsynUtil_joinPaths(threadData, _r, tmpMeta6);
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLDirection
modelica_boolean omc_ProgramUtil_classElementItemIsNamed(threadData_t *threadData, modelica_string _inClassName, modelica_metatype _inElement)
{
modelica_boolean _outIsNamed;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_string _name = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_name = tmpMeta9;
tmp1 = (stringEqual(_inClassName, _name));
goto tmp3_done;
}
case 1: {
tmp1 = 0;
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
_outIsNamed = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outIsNamed;
}
modelica_metatype boxptr_ProgramUtil_classElementItemIsNamed(threadData_t *threadData, modelica_metatype _inClassName, modelica_metatype _inElement)
{
modelica_boolean _outIsNamed;
modelica_metatype out_outIsNamed;
_outIsNamed = omc_ProgramUtil_classElementItemIsNamed(threadData, _inClassName, _inElement);
out_outIsNamed = mmc_mk_icon(_outIsNamed);
return out_outIsNamed;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getClassnamesInClass(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_boolean _inShowProtected, modelica_boolean _includeConstants)
{
modelica_metatype _paths = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_boolean tmp4_2;modelica_boolean tmp4_3;
tmp4_1 = _inClass;
tmp4_2 = _inShowProtected;
tmp4_3 = _includeConstants;
{
modelica_metatype _strlist = NULL;
modelica_metatype _parts = NULL;
modelica_boolean _b;
modelica_boolean _c;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_parts = tmpMeta7;
_b = tmp4_2;
_c = tmp4_3;
_strlist = omc_ProgramUtil_getClassnamesInParts(threadData, _parts, _b, _c);
tmpMeta1 = omc_List_map(threadData, _strlist, boxvar_AbsynUtil_makeIdentPathFromString);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
_parts = tmpMeta9;
_b = tmp4_2;
_c = tmp4_3;
_strlist = omc_ProgramUtil_getClassnamesInParts(threadData, _parts, _b, _c);
tmpMeta1 = omc_List_map(threadData, _strlist, boxvar_AbsynUtil_makeIdentPathFromString);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,4) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta12;
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
_paths = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _paths;
}
modelica_metatype boxptr_ProgramUtil_getClassnamesInClass(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_metatype _inShowProtected, modelica_metatype _includeConstants)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _paths = NULL;
tmp1 = mmc_unbox_integer(_inShowProtected);
tmp2 = mmc_unbox_integer(_includeConstants);
_paths = omc_ProgramUtil_getClassnamesInClass(threadData, _inPath, _inProgram, _inClass, tmp1, tmp2);
return _paths;
}
DLLDirection
modelica_metatype omc_ProgramUtil_excludeElementsFromFile(threadData_t *threadData, modelica_string _inFile, modelica_metatype _inEls)
{
modelica_metatype _outEls = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inFile;
tmp4_2 = _inEls;
{
modelica_metatype _e = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _filtered = NULL;
modelica_string _f = NULL;
modelica_string _file = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
_b = 0;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_boolean tmp13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_2);
tmpMeta8 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,6) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_e = tmpMeta7;
_f = tmpMeta11;
_rest = tmpMeta8;
_file = tmp4_1;
_b = (stringEqual(_file, _f));
_filtered = omc_ProgramUtil_excludeElementsFromFile(threadData, _file, _rest);
tmp13 = (modelica_boolean)(!_b);
if(tmp13)
{
tmpMeta12 = mmc_mk_cons(_e, _filtered);
tmpMeta14 = tmpMeta12;
}
else
{
tmpMeta14 = _filtered;
}
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_2);
tmpMeta16 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,1,1) == 0) goto tmp3_end;
_rest = tmpMeta16;
_file = tmp4_1;
_inFile = _file;
_inEls = _rest;
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
_outEls = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outEls;
}
DLLDirection
modelica_metatype omc_ProgramUtil_mergeElements(threadData_t *threadData, modelica_metatype _inEls1, modelica_metatype _inEls2)
{
modelica_metatype _outEls = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inEls1;
tmp4_2 = _inEls2;
{
modelica_metatype _rest = NULL;
modelica_metatype _merged = NULL;
modelica_metatype _e2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _inEls2;
goto tmp3_done;
}
case 1: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta1 = _inEls1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
_e2 = tmpMeta6;
_rest = tmpMeta7;
_merged = omc_ProgramUtil_mergeElement(threadData, _inEls1, _e2);
_inEls1 = _merged;
_inEls2 = _rest;
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
_outEls = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outEls;
}
DLLDirection
modelica_metatype omc_ProgramUtil_mergeElement(threadData_t *threadData, modelica_metatype _inEls, modelica_metatype _inEl)
{
modelica_metatype _outEls = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inEls;
tmp4_2 = _inEl;
{
modelica_string _n1 = NULL;
modelica_string _n2 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _filtered = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_boolean _r;
modelica_boolean _f;
modelica_metatype _redecl = NULL;
modelica_metatype _innout = NULL;
modelica_metatype _i = NULL;
modelica_metatype _cc = NULL;
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 2;
tmpMeta6 = mmc_mk_cons(_inEl, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_boolean tmp25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,6) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmp4_1);
tmpMeta12 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,6) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 4));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,0,2) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmp20 = mmc_unbox_integer(tmpMeta19);
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 6));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 7));
_c2 = tmpMeta9;
_n2 = tmpMeta10;
_f = tmp15;
_redecl = tmpMeta16;
_innout = tmpMeta17;
_r = tmp20;
_c1 = tmpMeta21;
_n1 = tmpMeta22;
_i = tmpMeta23;
_cc = tmpMeta24;
_rest = tmpMeta12;
tmp25 = (stringEqual(_n1, _n2));
if (1 /* true */ != tmp25) goto goto_2;
_c1 = omc_ProgramUtil_mergeClasses(threadData, _c1, _c2);
tmpMeta27 = mmc_mk_box3(3, &Absyn_ElementSpec_CLASSDEF__desc, mmc_mk_boolean(_r), _c1);
tmpMeta28 = mmc_mk_box7(3, &Absyn_Element_ELEMENT__desc, mmc_mk_boolean(_f), _redecl, _innout, tmpMeta27, _i, _cc);
tmpMeta29 = mmc_mk_box2(3, &Absyn_ElementItem_ELEMENTITEM__desc, tmpMeta28);
tmpMeta26 = mmc_mk_cons(tmpMeta29, _rest);
tmpMeta1 = tmpMeta26;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta30 = MMC_CAR(tmp4_1);
tmpMeta31 = MMC_CDR(tmp4_1);
_e1 = tmpMeta30;
_rest = tmpMeta31;
_e2 = tmp4_2;
_filtered = omc_ProgramUtil_mergeElement(threadData, _rest, _e2);
tmpMeta32 = mmc_mk_cons(_e1, _filtered);
tmpMeta1 = tmpMeta32;
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
if (++tmp4 < 3) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outEls = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outEls;
}
DLLDirection
modelica_metatype omc_ProgramUtil_mergeClasses(threadData_t *threadData, modelica_metatype _cNew, modelica_metatype _cOld)
{
modelica_metatype _c = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _cNew;
tmp4_2 = _cOld;
{
modelica_metatype _partsC1 = NULL;
modelica_metatype _partsC2 = NULL;
modelica_metatype _pubElementsC1 = NULL;
modelica_metatype _pubElementsC2 = NULL;
modelica_string _file = NULL;
modelica_metatype _typeVars1 = NULL;
modelica_metatype _classAttrs1 = NULL;
modelica_metatype _ann1 = NULL;
modelica_metatype _cmt1 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmp4 += 1;
tmpMeta1 = _cNew;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
if (!listEmpty(tmpMeta9)) goto tmp3_end;
tmp4 += 1;
tmpMeta1 = _cNew;
goto tmp3_done;
}
case 2: {
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
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,5) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 5));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 6));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,0,5) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 4));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 11));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
_c = tmp4_1;
_typeVars1 = tmpMeta11;
_classAttrs1 = tmpMeta12;
_partsC1 = tmpMeta13;
_ann1 = tmpMeta14;
_cmt1 = tmpMeta15;
_partsC2 = tmpMeta17;
_file = tmpMeta19;
_pubElementsC2 = omc_ProgramUtil_getPublicList(threadData, _partsC2);
_pubElementsC2 = omc_ProgramUtil_excludeElementsFromFile(threadData, _file, _pubElementsC2);
_pubElementsC1 = omc_ProgramUtil_getPublicList(threadData, _partsC1);
_pubElementsC1 = omc_ProgramUtil_mergeElements(threadData, _pubElementsC1, _pubElementsC2);
_partsC1 = omc_ProgramUtil_replacePublicList(threadData, _partsC1, _pubElementsC1);
tmpMeta21 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars1, _classAttrs1, _partsC1, _ann1, _cmt1);
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_c), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta20))[7] = tmpMeta21;
_c = tmpMeta20;
tmpMeta1 = _c;
goto tmp3_done;
}
case 3: {
tmpMeta1 = _cNew;
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
if (++tmp4 < 4) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_c = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _c;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getClassNamesRecursive(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_boolean _inShowProtected, modelica_boolean _includeConstants, modelica_metatype _inAcc, modelica_metatype *out_paths)
{
modelica_metatype _opath = NULL;
modelica_metatype _paths = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_boolean tmp4_3;volatile modelica_boolean tmp4_4;volatile modelica_metatype tmp4_5;
tmp4_1 = _inPath;
tmp4_2 = _inProgram;
tmp4_3 = _inShowProtected;
tmp4_4 = _includeConstants;
tmp4_5 = _inAcc;
{
modelica_metatype _cdef = NULL;
modelica_string _s1 = NULL;
modelica_metatype _strlst = NULL;
modelica_metatype _pp = NULL;
modelica_metatype _p = NULL;
modelica_metatype _classes = NULL;
modelica_metatype _result_path_lst = NULL;
modelica_metatype _acc = NULL;
modelica_boolean _b;
modelica_boolean _c;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_pp = tmpMeta6;
_p = tmp4_2;
_b = tmp4_3;
_c = tmp4_4;
_acc = tmp4_5;
tmp4 += 1;
tmpMeta7 = mmc_mk_cons(_pp, _acc);
_acc = tmpMeta7;
_cdef = omc_ProgramUtil_getPathedClassInProgram(threadData, _pp, _p, 0 /* false */, 0 /* false */);
_strlst = omc_ProgramUtil_getClassnamesInClassList(threadData, _pp, _p, _cdef, _b, _c);
_result_path_lst = omc_List_map(threadData, omc_List_map1(threadData, _strlst, boxvar_ProgramUtil_joinPaths, _pp), boxvar_Util_makeOption);
omc_List_map3Fold(threadData, _result_path_lst, boxvar_ProgramUtil_getClassNamesRecursive, _p, mmc_mk_boolean(_b), mmc_mk_boolean(_c), _acc ,&_acc);
tmpMeta[0+0] = _inPath;
tmpMeta[0+1] = _acc;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_p = tmp4_2;
_classes = tmpMeta8;
_b = tmp4_3;
_c = tmp4_4;
_acc = tmp4_5;
tmp4 += 1;
_strlst = omc_List_map(threadData, _classes, boxvar_AbsynUtil_getClassName);
_result_path_lst = omc_List_mapMap(threadData, _strlst, boxvar_AbsynUtil_makeIdentPathFromString, boxvar_Util_makeOption);
omc_List_map3Fold(threadData, _result_path_lst, boxvar_ProgramUtil_getClassNamesRecursive, _p, mmc_mk_boolean(_b), mmc_mk_boolean(_c), _acc ,&_acc);
tmpMeta[0+0] = _inPath;
tmpMeta[0+1] = _acc;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_pp = tmpMeta9;
_s1 = omc_AbsynUtil_pathString(threadData, _pp, _OMC_LIT4, 1 /* true */, 0 /* false */);
tmpMeta10 = mmc_mk_cons(_s1, mmc_mk_cons(_OMC_LIT20, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMessage(threadData, _OMC_LIT19, tmpMeta10);
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _inPath;
tmpMeta[0+1] = tmpMeta11;
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
if (++tmp4 < 3) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_opath = tmpMeta[0+0];
_paths = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_paths) { *out_paths = _paths; }
return _opath;
}
modelica_metatype boxptr_ProgramUtil_getClassNamesRecursive(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inShowProtected, modelica_metatype _includeConstants, modelica_metatype _inAcc, modelica_metatype *out_paths)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _opath = NULL;
tmp1 = mmc_unbox_integer(_inShowProtected);
tmp2 = mmc_unbox_integer(_includeConstants);
_opath = omc_ProgramUtil_getClassNamesRecursive(threadData, _inPath, _inProgram, tmp1, tmp2, _inAcc, out_paths);
return _opath;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getClassnamesInClassList(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_boolean _inShowProtected, modelica_boolean _includeConstants)
{
modelica_metatype _outString = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_boolean tmp4_2;modelica_boolean tmp4_3;
tmp4_1 = _inClass;
tmp4_2 = _inShowProtected;
tmp4_3 = _includeConstants;
{
modelica_metatype _parts = NULL;
modelica_boolean _b;
modelica_boolean _c;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_parts = tmpMeta7;
_b = tmp4_2;
_c = tmp4_3;
tmpMeta1 = omc_ProgramUtil_getClassnamesInParts(threadData, _parts, _b, _c);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
_parts = tmpMeta9;
_b = tmp4_2;
_c = tmp4_3;
tmpMeta1 = omc_ProgramUtil_getClassnamesInParts(threadData, _parts, _b, _c);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,4) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,3,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,2,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta16;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,5,3) == 0) goto tmp3_end;
tmpMeta18 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta18;
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
_outString = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outString;
}
modelica_metatype boxptr_ProgramUtil_getClassnamesInClassList(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_metatype _inShowProtected, modelica_metatype _includeConstants)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outString = NULL;
tmp1 = mmc_unbox_integer(_inShowProtected);
tmp2 = mmc_unbox_integer(_includeConstants);
_outString = omc_ProgramUtil_getClassnamesInClassList(threadData, _inPath, _inProgram, _inClass, tmp1, tmp2);
return _outString;
}
static modelica_metatype closure0_AbsynUtil_isClassNamed(threadData_t *thData, modelica_metatype closure, modelica_metatype inClass)
{
modelica_string inName = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_isClassNamed(thData, inName, inClass);
}
DLLDirection
modelica_metatype omc_ProgramUtil_getClassInProgram(threadData_t *threadData, modelica_string _name, modelica_metatype _program)
{
modelica_metatype _cls = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box1(0, _name);
_cls = omc_List_find(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_program), 2))), (modelica_fnptr) mmc_mk_box2(0,closure0_AbsynUtil_isClassNamed,tmpMeta1));
_return: OMC_LABEL_UNUSED
return _cls;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getClassInClass(threadData_t *threadData, modelica_string _name, modelica_metatype _inClass)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _part;
for (tmpMeta1 = omc_AbsynUtil_getClassPartsInClass(threadData, _inClass); !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_part = MMC_CAR(tmpMeta1);
{
modelica_metatype _item;
for (tmpMeta2 = omc_AbsynUtil_getElementItemsInClassPart(threadData, _part); !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_item = MMC_CAR(tmpMeta2);
if(omc_AbsynUtil_isElementItemClassNamed(threadData, _name, _item))
{
_outClass = omc_AbsynUtil_elementItemClass(threadData, _item);
goto _return;
}
}
}
}
}
MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return _outClass;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getPathedClassInClass(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inClass, modelica_boolean _enclOnError)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_metatype _c = NULL;
modelica_string _str = NULL;
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta6;
tmp4 += 2;
tmpMeta1 = omc_ProgramUtil_getClassInClass(threadData, _str, _inClass);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta7;
tmp4 += 1;
tmpMeta1 = omc_ProgramUtil_getPathedClassInClass(threadData, _path, _inClass, _enclOnError);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_str = tmpMeta8;
_path = tmpMeta9;
_c = omc_ProgramUtil_getClassInClass(threadData, _str, _inClass);
tmpMeta1 = omc_ProgramUtil_getPathedClassInClass(threadData, _path, _c, _enclOnError);
goto tmp3_done;
}
case 3: {
if (!_enclOnError) goto tmp3_end;
tmpMeta1 = _inClass;
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
if (++tmp4 < 4) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClass;
}
modelica_metatype boxptr_ProgramUtil_getPathedClassInClass(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inClass, modelica_metatype _enclOnError)
{
modelica_integer tmp1;
modelica_metatype _outClass = NULL;
tmp1 = mmc_unbox_integer(_enclOnError);
_outClass = omc_ProgramUtil_getPathedClassInClass(threadData, _inPath, _inClass, tmp1);
return _outClass;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getPathedClassInProgramWork(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_boolean _enclOnErr)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_metatype _c = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmpMeta1 = omc_ProgramUtil_getClassInProgram(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPath), 2))), _inProgram);
goto tmp3_done;
}
case 3: {
_c = omc_ProgramUtil_getClassInProgram(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPath), 2))), _inProgram);
tmpMeta1 = omc_ProgramUtil_getPathedClassInClass(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPath), 3))), _c, _enclOnErr);
goto tmp3_done;
}
case 5: {
_inPath = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inPath), 2)));
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
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClass;
}
modelica_metatype boxptr_ProgramUtil_getPathedClassInProgramWork(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _enclOnErr)
{
modelica_integer tmp1;
modelica_metatype _outClass = NULL;
tmp1 = mmc_unbox_integer(_enclOnErr);
_outClass = omc_ProgramUtil_getPathedClassInProgramWork(threadData, _inPath, _inProgram, tmp1);
return _outClass;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getPathedClassInProgram(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_boolean _enclOnErr, modelica_boolean _showError)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta1 = omc_ProgramUtil_getPathedClassInProgramWork(threadData, _inPath, _inProgram, _enclOnErr);
goto tmp3_done;
}
case 1: {
tmpMeta1 = omc_ProgramUtil_getPathedClassInProgramWork(threadData, _inPath, omc_FBuiltin_getInitialFunctions(threadData, NULL), _enclOnErr);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta6;
if(_showError)
{
tmpMeta6 = mmc_mk_cons(omc_AbsynUtil_pathString(threadData, _inPath, _OMC_LIT4, 1 /* true */, 0 /* false */), mmc_mk_cons(_OMC_LIT20, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMessage(threadData, _OMC_LIT19, tmpMeta6);
}
goto goto_2;
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
if (++tmp4 < 3) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClass;
}
modelica_metatype boxptr_ProgramUtil_getPathedClassInProgram(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _enclOnErr, modelica_metatype _showError)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outClass = NULL;
tmp1 = mmc_unbox_integer(_enclOnErr);
tmp2 = mmc_unbox_integer(_showError);
_outClass = omc_ProgramUtil_getPathedClassInProgram(threadData, _inPath, _inProgram, tmp1, tmp2);
return _outClass;
}
DLLDirection
modelica_boolean omc_ProgramUtil_classInProgram(threadData_t *threadData, modelica_string _name, modelica_metatype _p)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _p;
{
modelica_string _str = NULL;
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
{
modelica_metatype _cl;
for (tmpMeta6 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))); !listEmpty(tmpMeta6); tmpMeta6=MMC_CDR(tmpMeta6))
{
_cl = MMC_CAR(tmpMeta6);
tmpMeta7 = _cl;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_str = tmpMeta8;
if((stringEqual(_str, _name)))
{
_b = 1;
goto _return;
}
}
}
tmp1 = 0;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _b;
}
modelica_metatype boxptr_ProgramUtil_classInProgram(threadData_t *threadData, modelica_metatype _name, modelica_metatype _p)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ProgramUtil_classInProgram(threadData, _name, _p);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getClassFromElementitemlist(threadData_t *threadData, modelica_metatype _inElements, modelica_string _inIdent)
{
modelica_metatype _outClass = NULL;
modelica_metatype _elem = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elem = omc_List_getMemberOnTrue(threadData, _inIdent, _inElements, boxvar_ProgramUtil_classElementItemIsNamed);
tmpMeta1 = _elem;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,0,1) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,0,6) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta3,0,2) == 0) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 3));
_outClass = tmpMeta4;
_return: OMC_LABEL_UNUSED
return _outClass;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getProtectedList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAbsynElementItemLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _res2 = NULL;
modelica_metatype _res1 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _xs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_res1 = tmpMeta9;
_rest = tmpMeta8;
_res2 = omc_ProgramUtil_getProtectedList(threadData, _rest);
tmpMeta1 = listAppend(_res1, _res2);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_xs = tmpMeta11;
_inAbsynClassPartLst = _xs;
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
_outAbsynElementItemLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynElementItemLst;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getPublicList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAbsynElementItemLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _res2 = NULL;
modelica_metatype _res1 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _xs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_res1 = tmpMeta9;
_rest = tmpMeta8;
_res2 = omc_ProgramUtil_getPublicList(threadData, _rest);
tmpMeta1 = listAppend(_res1, _res2);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_xs = tmpMeta11;
_inAbsynClassPartLst = _xs;
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
_outAbsynElementItemLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynElementItemLst;
}
DLLDirection
modelica_metatype omc_ProgramUtil_deleteProtectedList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAbsynClassPartLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _res = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _x = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,1) == 0) goto tmp3_end;
_xs = tmpMeta8;
_inAbsynClassPartLst = _xs;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_1);
tmpMeta10 = MMC_CDR(tmp4_1);
_x = tmpMeta9;
_xs = tmpMeta10;
_res = omc_ProgramUtil_deleteProtectedList(threadData, _xs);
tmpMeta11 = mmc_mk_cons(_x, _res);
tmpMeta1 = tmpMeta11;
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
_outAbsynClassPartLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynClassPartLst;
}
DLLDirection
modelica_metatype omc_ProgramUtil_deletePublicList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAbsynClassPartLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _res = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _x = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,1) == 0) goto tmp3_end;
_xs = tmpMeta8;
_inAbsynClassPartLst = _xs;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_1);
tmpMeta10 = MMC_CDR(tmp4_1);
_x = tmpMeta9;
_xs = tmpMeta10;
_res = omc_ProgramUtil_deletePublicList(threadData, _xs);
tmpMeta11 = mmc_mk_cons(_x, _res);
tmpMeta1 = tmpMeta11;
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
_outAbsynClassPartLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynClassPartLst;
}
DLLDirection
modelica_metatype omc_ProgramUtil_replaceProtectedList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_metatype _inAbsynElementItemLst)
{
modelica_metatype _outAbsynClassPartLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inAbsynClassPartLst;
tmp4_2 = _inAbsynElementItemLst;
{
modelica_metatype _rest_1 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _ys = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _x = NULL;
modelica_metatype _newprotlist = NULL;
modelica_metatype _new = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
_rest = tmpMeta7;
_newprotlist = tmp4_2;
_rest_1 = omc_ProgramUtil_deleteProtectedList(threadData, _rest);
tmpMeta9 = mmc_mk_box2(4, &Absyn_ClassPart_PROTECTED__desc, _newprotlist);
tmpMeta8 = mmc_mk_cons(tmpMeta9, _rest_1);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_x = tmpMeta10;
_xs = tmpMeta11;
_new = tmp4_2;
_ys = omc_ProgramUtil_replaceProtectedList(threadData, _xs, _new);
tmpMeta12 = mmc_mk_cons(_x, _ys);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (!listEmpty(tmp4_1)) goto tmp3_end;
_newprotlist = tmp4_2;
tmpMeta14 = mmc_mk_box2(4, &Absyn_ClassPart_PROTECTED__desc, _newprotlist);
tmpMeta13 = mmc_mk_cons(tmpMeta14, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta13;
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
_outAbsynClassPartLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynClassPartLst;
}
DLLDirection
modelica_metatype omc_ProgramUtil_replacePublicList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_metatype _inAbsynElementItemLst)
{
modelica_metatype _outAbsynClassPartLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inAbsynClassPartLst;
tmp4_2 = _inAbsynElementItemLst;
{
modelica_metatype _rest_1 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _ys = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _x = NULL;
modelica_metatype _newpublst = NULL;
modelica_metatype _new = NULL;
modelica_metatype _newpublist = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
_rest = tmpMeta7;
_newpublst = tmp4_2;
_rest_1 = omc_ProgramUtil_deletePublicList(threadData, _rest);
tmpMeta9 = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, _newpublst);
tmpMeta8 = mmc_mk_cons(tmpMeta9, _rest_1);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_x = tmpMeta10;
_xs = tmpMeta11;
_new = tmp4_2;
_ys = omc_ProgramUtil_replacePublicList(threadData, _xs, _new);
tmpMeta12 = mmc_mk_cons(_x, _ys);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (!listEmpty(tmp4_1)) goto tmp3_end;
_newpublist = tmp4_2;
tmpMeta14 = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, _newpublist);
tmpMeta13 = mmc_mk_cons(tmpMeta14, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta13;
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
_outAbsynClassPartLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynClassPartLst;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getInnerClass(threadData_t *threadData, modelica_metatype _inClass, modelica_string _inIdent)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_string tmp4_2;
tmp4_1 = _inClass;
tmp4_2 = _inIdent;
{
modelica_metatype _publst = NULL;
modelica_metatype _prolst = NULL;
modelica_metatype _parts = NULL;
modelica_string _name = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_parts = tmpMeta7;
_name = tmp4_2;
_publst = omc_ProgramUtil_getPublicList(threadData, _parts);
tmpMeta1 = omc_ProgramUtil_getClassFromElementitemlist(threadData, _publst, _name);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
_parts = tmpMeta9;
_name = tmp4_2;
tmp4 += 2;
_prolst = omc_ProgramUtil_getProtectedList(threadData, _parts);
tmpMeta1 = omc_ProgramUtil_getClassFromElementitemlist(threadData, _prolst, _name);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,4,5) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 5));
_parts = tmpMeta11;
_name = tmp4_2;
_publst = omc_ProgramUtil_getPublicList(threadData, _parts);
tmpMeta1 = omc_ProgramUtil_getClassFromElementitemlist(threadData, _publst, _name);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,4,5) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 5));
_parts = tmpMeta13;
_name = tmp4_2;
_prolst = omc_ProgramUtil_getProtectedList(threadData, _parts);
tmpMeta1 = omc_ProgramUtil_getClassFromElementitemlist(threadData, _prolst, _name);
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
if (++tmp4 < 4) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClass;
}
DLLDirection
modelica_metatype omc_ProgramUtil_addClassInElementitemlist(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _inClass)
{
modelica_metatype _outAbsynElementItemLst = NULL;
modelica_metatype _info = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inClass;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 11));
_info = tmpMeta2;
tmpMeta4 = mmc_mk_box3(3, &Absyn_ElementSpec_CLASSDEF__desc, mmc_mk_boolean(0 /* false */), _inClass);
tmpMeta5 = mmc_mk_box7(3, &Absyn_Element_ELEMENT__desc, mmc_mk_boolean(0 /* false */), mmc_mk_none(), _OMC_LIT21, tmpMeta4, _info, mmc_mk_none());
tmpMeta6 = mmc_mk_box2(3, &Absyn_ElementItem_ELEMENTITEM__desc, tmpMeta5);
tmpMeta3 = mmc_mk_cons(tmpMeta6, MMC_REFSTRUCTLIT(mmc_nil));
_outAbsynElementItemLst = listAppend(_inAbsynElementItemLst, tmpMeta3);
_return: OMC_LABEL_UNUSED
return _outAbsynElementItemLst;
}
DLLDirection
modelica_metatype omc_ProgramUtil_replaceClassInElementitemlist(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _inClass, modelica_boolean _mergeAST, modelica_boolean *out_replaced)
{
modelica_metatype _outAbsynElementItemLst = NULL;
modelica_boolean _replaced;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inAbsynElementItemLst;
tmp4_2 = _inClass;
{
modelica_metatype _res = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _c = NULL;
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
modelica_string _name1 = NULL;
modelica_string _name = NULL;
modelica_boolean _a;
modelica_boolean _e;
modelica_metatype _b = NULL;
modelica_metatype _info = NULL;
modelica_metatype _h = NULL;
modelica_metatype _io = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,6) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 7));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_a = tmp10;
_b = tmpMeta11;
_io = tmpMeta12;
_e = tmp15;
_c1 = tmpMeta16;
_name1 = tmpMeta17;
_h = tmpMeta18;
_xs = tmpMeta7;
_c2 = tmp4_2;
_name = tmpMeta19;
if (!(stringEqual(_name1, _name))) goto tmp3_end;
_c = (_mergeAST?omc_ProgramUtil_mergeClasses(threadData, _c2, _c1):_c2);
tmpMeta20 = _c;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 11));
_info = tmpMeta21;
tmpMeta23 = mmc_mk_box3(3, &Absyn_ElementSpec_CLASSDEF__desc, mmc_mk_boolean(_e), _c);
tmpMeta24 = mmc_mk_box7(3, &Absyn_Element_ELEMENT__desc, mmc_mk_boolean(_a), _b, _io, tmpMeta23, _info, _h);
tmpMeta25 = mmc_mk_box2(3, &Absyn_ElementItem_ELEMENTITEM__desc, tmpMeta24);
tmpMeta22 = mmc_mk_cons(tmpMeta25, _xs);
tmpMeta[0+0] = tmpMeta22;
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta26 = MMC_CAR(tmp4_1);
tmpMeta27 = MMC_CDR(tmp4_1);
_e1 = tmpMeta26;
_xs = tmpMeta27;
_c = tmp4_2;
_res = omc_ProgramUtil_replaceClassInElementitemlist(threadData, _xs, _c, _mergeAST ,&_replaced);
tmpMeta28 = mmc_mk_cons(_e1, _res);
tmpMeta[0+0] = tmpMeta28;
tmp1_c1 = _replaced;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta29;
tmpMeta29 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta29;
tmp1_c1 = 0;
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
_outAbsynElementItemLst = tmpMeta[0+0];
_replaced = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_replaced) { *out_replaced = _replaced; }
return _outAbsynElementItemLst;
}
modelica_metatype boxptr_ProgramUtil_replaceClassInElementitemlist(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _inClass, modelica_metatype _mergeAST, modelica_metatype *out_replaced)
{
modelica_integer tmp1;
modelica_boolean _replaced;
modelica_metatype _outAbsynElementItemLst = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outAbsynElementItemLst = omc_ProgramUtil_replaceClassInElementitemlist(threadData, _inAbsynElementItemLst, _inClass, tmp1, &_replaced);
if (out_replaced) { *out_replaced = mmc_mk_icon(_replaced); }
return _outAbsynElementItemLst;
}
DLLDirection
modelica_metatype omc_ProgramUtil_replaceInnerClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inClass2, modelica_boolean _mergeAST)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inClass1;
tmp4_2 = _inClass2;
{
modelica_metatype _publst = NULL;
modelica_metatype _publst2 = NULL;
modelica_metatype _prolst = NULL;
modelica_metatype _prolst2 = NULL;
modelica_metatype _parts2 = NULL;
modelica_metatype _parts = NULL;
modelica_metatype _c1 = NULL;
modelica_string _bcname = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _modif = NULL;
modelica_metatype _typeVars = NULL;
modelica_metatype _classAttrs = NULL;
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
_outClass = tmp4_2;
_typeVars = tmpMeta7;
_classAttrs = tmpMeta8;
_parts = tmpMeta9;
_ann = tmpMeta10;
_cmt = tmpMeta11;
_c1 = tmp4_1;
_publst = omc_ProgramUtil_getPublicList(threadData, _parts);
tmpMeta13 = omc_ProgramUtil_replaceClassInElementitemlist(threadData, _publst, _c1, _mergeAST, &tmp12);
_publst2 = tmpMeta13;
if (1 /* true */ != tmp12) goto goto_2;
_parts2 = omc_ProgramUtil_replacePublicList(threadData, _parts, _publst2);
tmpMeta15 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars, _classAttrs, _parts2, _ann, _cmt);
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[7] = tmpMeta15;
_outClass = tmpMeta14;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_boolean tmp22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,0,5) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 4));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 5));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 6));
_outClass = tmp4_2;
_typeVars = tmpMeta17;
_classAttrs = tmpMeta18;
_parts = tmpMeta19;
_ann = tmpMeta20;
_cmt = tmpMeta21;
_c1 = tmp4_1;
_prolst = omc_ProgramUtil_getProtectedList(threadData, _parts);
tmpMeta23 = omc_ProgramUtil_replaceClassInElementitemlist(threadData, _prolst, _c1, _mergeAST, &tmp22);
_prolst2 = tmpMeta23;
if (1 /* true */ != tmp22) goto goto_2;
_parts2 = omc_ProgramUtil_replaceProtectedList(threadData, _parts, _prolst2);
tmpMeta25 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars, _classAttrs, _parts2, _ann, _cmt);
tmpMeta24 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta24), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta24))[7] = tmpMeta25;
_outClass = tmpMeta24;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,0,5) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 3));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 4));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 5));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 6));
_outClass = tmp4_2;
_typeVars = tmpMeta27;
_classAttrs = tmpMeta28;
_parts = tmpMeta29;
_ann = tmpMeta30;
_cmt = tmpMeta31;
_c1 = tmp4_1;
tmp4 += 3;
_publst = omc_ProgramUtil_getPublicList(threadData, _parts);
_publst = omc_ProgramUtil_addClassInElementitemlist(threadData, _publst, _c1);
_parts2 = omc_ProgramUtil_replacePublicList(threadData, _parts, _publst);
tmpMeta33 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars, _classAttrs, _parts2, _ann, _cmt);
tmpMeta32 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta32), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta32))[7] = tmpMeta33;
_outClass = tmpMeta32;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_boolean tmp40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,4,5) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 2));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 3));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 4));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 5));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 6));
_outClass = tmp4_2;
_bcname = tmpMeta35;
_modif = tmpMeta36;
_cmt = tmpMeta37;
_parts = tmpMeta38;
_ann = tmpMeta39;
_c1 = tmp4_1;
_publst = omc_ProgramUtil_getPublicList(threadData, _parts);
tmpMeta41 = omc_ProgramUtil_replaceClassInElementitemlist(threadData, _publst, _c1, _mergeAST, &tmp40);
_publst2 = tmpMeta41;
if (1 /* true */ != tmp40) goto goto_2;
_parts2 = omc_ProgramUtil_replacePublicList(threadData, _parts, _publst2);
tmpMeta43 = mmc_mk_box6(7, &Absyn_ClassDef_CLASS__EXTENDS__desc, _bcname, _modif, _cmt, _parts2, _ann);
tmpMeta42 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta42), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta42))[7] = tmpMeta43;
_outClass = tmpMeta42;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_boolean tmp50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta44,4,5) == 0) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 2));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 3));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 4));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 5));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 6));
_outClass = tmp4_2;
_bcname = tmpMeta45;
_modif = tmpMeta46;
_cmt = tmpMeta47;
_parts = tmpMeta48;
_ann = tmpMeta49;
_c1 = tmp4_1;
_prolst = omc_ProgramUtil_getProtectedList(threadData, _parts);
tmpMeta51 = omc_ProgramUtil_replaceClassInElementitemlist(threadData, _prolst, _c1, _mergeAST, &tmp50);
_prolst2 = tmpMeta51;
if (1 /* true */ != tmp50) goto goto_2;
_parts2 = omc_ProgramUtil_replaceProtectedList(threadData, _parts, _prolst2);
tmpMeta53 = mmc_mk_box6(7, &Absyn_ClassDef_CLASS__EXTENDS__desc, _bcname, _modif, _cmt, _parts2, _ann);
tmpMeta52 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta52), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta52))[7] = tmpMeta53;
_outClass = tmpMeta52;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta54,4,5) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 2));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 3));
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 4));
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 5));
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 6));
_outClass = tmp4_2;
_bcname = tmpMeta55;
_modif = tmpMeta56;
_cmt = tmpMeta57;
_parts = tmpMeta58;
_ann = tmpMeta59;
_c1 = tmp4_1;
_publst = omc_ProgramUtil_getPublicList(threadData, _parts);
_publst = omc_ProgramUtil_addClassInElementitemlist(threadData, _publst, _c1);
_parts2 = omc_ProgramUtil_replacePublicList(threadData, _parts, _publst);
tmpMeta61 = mmc_mk_box6(7, &Absyn_ClassDef_CLASS__EXTENDS__desc, _bcname, _modif, _cmt, _parts2, _ann);
tmpMeta60 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta60), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta60))[7] = tmpMeta61;
_outClass = tmpMeta60;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 6: {
omc_Print_printBuf(threadData, _OMC_LIT22);
goto goto_2;
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
if (++tmp4 < 7) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClass;
}
modelica_metatype boxptr_ProgramUtil_replaceInnerClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inClass2, modelica_metatype _mergeAST)
{
modelica_integer tmp1;
modelica_metatype _outClass = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outClass = omc_ProgramUtil_replaceInnerClass(threadData, _inClass1, _inClass2, tmp1);
return _outClass;
}
DLLDirection
modelica_metatype omc_ProgramUtil_insertClassInClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inWithin2, modelica_metatype _inClass3, modelica_boolean _mergeAST)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inClass1;
tmp4_2 = _inWithin2;
tmp4_3 = _inClass3;
{
modelica_metatype _cnew = NULL;
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
modelica_metatype _cinner = NULL;
modelica_string _name2 = NULL;
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
_c1 = tmp4_1;
_c2 = tmp4_3;
tmpMeta1 = omc_ProgramUtil_replaceInnerClass(threadData, _c1, _c2, _mergeAST);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
_path = tmpMeta8;
_c1 = tmp4_1;
_c2 = tmp4_3;
_name2 = omc_AbsynUtil_pathFirstIdent(threadData, _path);
_cinner = omc_ProgramUtil_getInnerClass(threadData, _c2, _name2);
tmpMeta9 = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, _path);
_cnew = omc_ProgramUtil_insertClassInClass(threadData, _c1, tmpMeta9, _cinner, _mergeAST);
tmpMeta1 = omc_ProgramUtil_replaceInnerClass(threadData, _cnew, _c2, _mergeAST);
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
_outClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outClass;
}
modelica_metatype boxptr_ProgramUtil_insertClassInClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inWithin2, modelica_metatype _inClass3, modelica_metatype _mergeAST)
{
modelica_integer tmp1;
modelica_metatype _outClass = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outClass = omc_ProgramUtil_insertClassInClass(threadData, _inClass1, _inWithin2, _inClass3, tmp1);
return _outClass;
}
DLLDirection
modelica_metatype omc_ProgramUtil_insertClassInProgram(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inWithin, modelica_metatype _inProgram, modelica_boolean _mergeAST)
{
modelica_metatype _outProgram = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inClass;
tmp4_2 = _inWithin;
tmp4_3 = _inProgram;
{
modelica_metatype _c2 = NULL;
modelica_metatype _c3 = NULL;
modelica_metatype _c1 = NULL;
modelica_metatype _p = NULL;
modelica_metatype _w = NULL;
modelica_string _n1 = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_string _name = NULL;
modelica_metatype _paths = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_w = tmp4_2;
_n1 = tmpMeta7;
_c1 = tmp4_1;
_p = tmp4_3;
tmp4 += 1;
_c2 = omc_ProgramUtil_getClassInProgram(threadData, _n1, _p);
_c3 = omc_ProgramUtil_insertClassInClass(threadData, _c1, _w, _c2, _mergeAST);
tmpMeta8 = mmc_mk_cons(_c3, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta9 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta8, _OMC_LIT23);
tmpMeta1 = omc_ProgramUtil_updateProgram(threadData, tmpMeta9, _p, _mergeAST);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_w = tmp4_2;
_n1 = tmpMeta11;
_c1 = tmp4_1;
_p = tmp4_3;
tmp4 += 1;
_c2 = omc_ProgramUtil_getClassInProgram(threadData, _n1, _p);
_c3 = omc_ProgramUtil_insertClassInClass(threadData, _c1, _w, _c2, _mergeAST);
tmpMeta12 = mmc_mk_cons(_c3, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta13 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta12, _OMC_LIT23);
tmpMeta1 = omc_ProgramUtil_updateProgram(threadData, tmpMeta13, _p, _mergeAST);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,0,2) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
if (12 != MMC_STRLEN(tmpMeta15) || strcmp(MMC_STRINGDATA(_OMC_LIT28), MMC_STRINGDATA(tmpMeta15)) != 0) goto tmp3_end;
_p = tmp4_3;
tmpMeta1 = _p;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta22;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta16;
_w = tmp4_2;
_p = tmp4_3;
_s1 = omc_Dump_unparseWithin(threadData, _w);
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
omc_ProgramUtil_getClassNamesRecursive(threadData, mmc_mk_none(), _p, 0 /* false */, 0 /* false */, tmpMeta17 ,&_paths);
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp19;
modelica_metatype tmpMeta20;
modelica_string __omcQ_24tmpVar0;
modelica_integer tmp21;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = _paths;
tmpMeta20 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta20;
tmp19 = &__omcQ_24tmpVar1;
while(1) {
tmp21 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp21--;
}
if (tmp21 == 0) {
__omcQ_24tmpVar0 = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT4, 1 /* true */, 0 /* false */);
*tmp19 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp19 = &MMC_CDR(*tmp19);
} else if (tmp21 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp19 = mmc_mk_nil();
tmpMeta18 = __omcQ_24tmpVar1;
}
_s2 = stringAppendList(omc_List_map1r(threadData, tmpMeta18, boxvar_stringAppend, _OMC_LIT24));
tmpMeta22 = mmc_mk_cons(_name, mmc_mk_cons(_s1, mmc_mk_cons(_s2, MMC_REFSTRUCTLIT(mmc_nil))));
omc_Error_addMessage(threadData, _OMC_LIT27, tmpMeta22);
goto goto_2;
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
if (++tmp4 < 4) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outProgram = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outProgram;
}
modelica_metatype boxptr_ProgramUtil_insertClassInProgram(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inWithin, modelica_metatype _inProgram, modelica_metatype _mergeAST)
{
modelica_integer tmp1;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outProgram = omc_ProgramUtil_insertClassInProgram(threadData, _inClass, _inWithin, _inProgram, tmp1);
return _outProgram;
}
static modelica_metatype closure1_ProgramUtil_replaceClassInProgram2(threadData_t *thData, modelica_metatype closure, modelica_metatype inClass)
{
modelica_string inClassName = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_ProgramUtil_replaceClassInProgram2(thData, inClass, inClassName);
}static modelica_metatype closure2_ProgramUtil_replaceClassInProgram2(threadData_t *thData, modelica_metatype closure, modelica_metatype inClass)
{
modelica_string inClassName = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_ProgramUtil_replaceClassInProgram2(thData, inClass, inClassName);
}
DLLDirection
modelica_metatype omc_ProgramUtil_replaceClassInProgram(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inProgram, modelica_boolean _mergeAST)
{
modelica_metatype _outProgram = NULL;
modelica_string _cls_name1 = NULL;
modelica_metatype _clst = NULL;
modelica_metatype _clsFilter = NULL;
modelica_metatype _w = NULL;
modelica_boolean _replaced;
modelica_metatype _cls = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inClass;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_cls_name1 = tmpMeta2;
tmpMeta3 = _inProgram;
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 3));
_clst = tmpMeta4;
_w = tmpMeta5;
if(_mergeAST)
{
tmpMeta6 = mmc_mk_box1(0, _cls_name1);
_clsFilter = omc_List_filterOnTrue(threadData, _clst, (modelica_fnptr) mmc_mk_box2(0,closure1_ProgramUtil_replaceClassInProgram2,tmpMeta6));
if(listEmpty(_clsFilter))
{
_cls = _inClass;
}
else
{
tmpMeta7 = _clsFilter;
if (listEmpty(tmpMeta7)) MMC_THROW_INTERNAL();
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
_cls = tmpMeta8;
_cls = omc_ProgramUtil_mergeClasses(threadData, _inClass, _cls);
}
}
else
{
_cls = _inClass;
}
tmpMeta10 = mmc_mk_box1(0, _cls_name1);
_clst = omc_List_replaceOnTrue(threadData, _cls, _clst, (modelica_fnptr) mmc_mk_box2(0,closure2_ProgramUtil_replaceClassInProgram2,tmpMeta10) ,&_replaced);
if((!_replaced))
{
_clst = omc_List_appendElt(threadData, _inClass, _clst);
}
tmpMeta11 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, _clst, _w);
_outProgram = tmpMeta11;
_return: OMC_LABEL_UNUSED
return _outProgram;
}
modelica_metatype boxptr_ProgramUtil_replaceClassInProgram(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inProgram, modelica_metatype _mergeAST)
{
modelica_integer tmp1;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outProgram = omc_ProgramUtil_replaceClassInProgram(threadData, _inClass, _inProgram, tmp1);
return _outProgram;
}
DLLDirection
modelica_boolean omc_ProgramUtil_replaceClassInProgram2(threadData_t *threadData, modelica_metatype _inClass, modelica_string _inClassName)
{
modelica_boolean _outReplace;
modelica_string _cls_name = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inClass;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_cls_name = tmpMeta2;
_outReplace = (stringEqual(_cls_name, _inClassName));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _outReplace;
}
modelica_metatype boxptr_ProgramUtil_replaceClassInProgram2(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inClassName)
{
modelica_boolean _outReplace;
modelica_metatype out_outReplace;
_outReplace = omc_ProgramUtil_replaceClassInProgram2(threadData, _inClass, _inClassName);
out_outReplace = mmc_mk_icon(_outReplace);
return out_outReplace;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getComponentItemsName(threadData_t *threadData, modelica_metatype _inComponents, modelica_boolean _inQuoteNames)
{
modelica_metatype _outStrings = NULL;
modelica_metatype tmpMeta1;
modelica_string _name = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta13;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outStrings = tmpMeta1;
{
modelica_metatype _comp;
for (tmpMeta2 = listReverse(_inComponents); !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_comp = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp5_1;
tmp5_1 = _comp;
{
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 2; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
modelica_string tmp12;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_name = tmpMeta8;
tmp11 = (modelica_boolean)_inQuoteNames;
if(tmp11)
{
tmpMeta10 = mmc_mk_cons(_OMC_LIT16, mmc_mk_cons(_name, mmc_mk_cons(_OMC_LIT16, MMC_REFSTRUCTLIT(mmc_nil))));
tmp12 = stringAppendList(tmpMeta10);
}
else
{
tmp12 = _name;
}
tmpMeta9 = mmc_mk_cons(tmp12, _outStrings);
_outStrings = tmpMeta9;
goto tmp4_done;
}
case 1: {
goto tmp4_done;
}
}
goto tmp4_end;
tmp4_end: ;
}
goto goto_3;
goto_3:;
MMC_THROW_INTERNAL();
goto tmp4_done;
tmp4_done:;
}
}
;
}
}
_return: OMC_LABEL_UNUSED
return _outStrings;
}
modelica_metatype boxptr_ProgramUtil_getComponentItemsName(threadData_t *threadData, modelica_metatype _inComponents, modelica_metatype _inQuoteNames)
{
modelica_integer tmp1;
modelica_metatype _outStrings = NULL;
modelica_metatype tmpMeta2;
tmp1 = mmc_unbox_integer(_inQuoteNames);
_outStrings = omc_ProgramUtil_getComponentItemsName(threadData, _inComponents, tmp1);
return _outStrings;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getClassnamesInElts(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_boolean _includeConstants)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype _delst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_delst = omc_DoubleEnded_fromList(threadData, tmpMeta1);
{
modelica_metatype _elt;
for (tmpMeta2 = _inAbsynElementItemLst; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_elt = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp5_1;
tmp5_1 = _elt;
{
modelica_string _id = NULL;
modelica_metatype _lst = NULL;
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 4; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,0,1) == 0) goto tmp4_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,6) == 0) goto tmp4_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,2) == 0) goto tmp4_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,4,5) == 0) goto tmp4_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_id = tmpMeta11;
omc_DoubleEnded_push__back(threadData, _delst, _id);
goto tmp4_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,0,1) == 0) goto tmp4_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,0,6) == 0) goto tmp4_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,2) == 0) goto tmp4_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
_id = tmpMeta15;
omc_DoubleEnded_push__back(threadData, _delst, _id);
goto tmp4_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,0,1) == 0) goto tmp4_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,0,6) == 0) goto tmp4_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,3,3) == 0) goto tmp4_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,3,0) == 0) goto tmp4_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 4));
_lst = tmpMeta20;
if (!_includeConstants) goto tmp4_end;
omc_DoubleEnded_push__list__back(threadData, _delst, omc_ProgramUtil_getComponentItemsName(threadData, _lst, 0 /* false */));
goto tmp4_done;
}
case 3: {
goto tmp4_done;
}
}
goto tmp4_end;
tmp4_end: ;
}
goto goto_3;
goto_3:;
MMC_THROW_INTERNAL();
goto tmp4_done;
tmp4_done:;
}
}
;
}
}
tmpMeta22 = MMC_REFSTRUCTLIT(mmc_nil);
_outStringLst = omc_DoubleEnded_toListAndClear(threadData, _delst, tmpMeta22);
_return: OMC_LABEL_UNUSED
return _outStringLst;
}
modelica_metatype boxptr_ProgramUtil_getClassnamesInElts(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _includeConstants)
{
modelica_integer tmp1;
modelica_metatype _outStringLst = NULL;
tmp1 = mmc_unbox_integer(_includeConstants);
_outStringLst = omc_ProgramUtil_getClassnamesInElts(threadData, _inAbsynElementItemLst, tmp1);
return _outStringLst;
}
DLLDirection
modelica_metatype omc_ProgramUtil_getClassnamesInParts(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_boolean _inShowProtected, modelica_boolean _includeConstants)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_boolean tmp4_2;volatile modelica_boolean tmp4_3;
tmp4_1 = _inAbsynClassPartLst;
tmp4_2 = _inShowProtected;
tmp4_3 = _includeConstants;
{
modelica_metatype _l1 = NULL;
modelica_metatype _l2 = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _rest = NULL;
modelica_boolean _b;
modelica_boolean _c;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 3;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_elts = tmpMeta9;
_rest = tmpMeta8;
_b = tmp4_2;
_c = tmp4_3;
tmp4 += 1;
_l1 = omc_ProgramUtil_getClassnamesInElts(threadData, _elts, _c);
_l2 = omc_ProgramUtil_getClassnamesInParts(threadData, _rest, _b, _c);
tmpMeta1 = listAppend(_l1, _l2);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (1 /* true */ != tmp4_2) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_elts = tmpMeta12;
_rest = tmpMeta11;
_c = tmp4_3;
_l1 = omc_ProgramUtil_getClassnamesInElts(threadData, _elts, _c);
_l2 = omc_ProgramUtil_getClassnamesInParts(threadData, _rest, 1 /* true */, _c);
tmpMeta1 = listAppend(_l1, _l2);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
_rest = tmpMeta14;
_b = tmp4_2;
_c = tmp4_3;
tmpMeta1 = omc_ProgramUtil_getClassnamesInParts(threadData, _rest, _b, _c);
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
if (++tmp4 < 4) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outStringLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStringLst;
}
modelica_metatype boxptr_ProgramUtil_getClassnamesInParts(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_metatype _inShowProtected, modelica_metatype _includeConstants)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outStringLst = NULL;
tmp1 = mmc_unbox_integer(_inShowProtected);
tmp2 = mmc_unbox_integer(_includeConstants);
_outStringLst = omc_ProgramUtil_getClassnamesInParts(threadData, _inAbsynClassPartLst, tmp1, tmp2);
return _outStringLst;
}
DLLDirection
modelica_metatype omc_ProgramUtil_updateProgram2(threadData_t *threadData, modelica_metatype _inNewClasses, modelica_metatype _w, modelica_metatype _inOldProgram, modelica_boolean _mergeAST)
{
modelica_metatype _outProgram = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inNewClasses;
tmp4_2 = _w;
tmp4_3 = _inOldProgram;
{
modelica_metatype _prg = NULL;
modelica_metatype _newp = NULL;
modelica_metatype _p2 = NULL;
modelica_metatype _c1 = NULL;
modelica_string _name = NULL;
modelica_metatype _c2 = NULL;
modelica_metatype _c3 = NULL;
modelica_metatype _w2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_prg = tmp4_3;
tmpMeta1 = _prg;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_c1 = tmpMeta6;
_name = tmpMeta8;
_c2 = tmpMeta7;
_p2 = tmp4_3;
_c3 = tmpMeta9;
_w2 = tmpMeta10;
if(omc_ProgramUtil_classInProgram(threadData, _name, _p2))
{
_newp = omc_ProgramUtil_replaceClassInProgram(threadData, _c1, _p2, _mergeAST);
}
else
{
tmpMeta11 = mmc_mk_cons(_c1, _c3);
tmpMeta12 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta11, _w2);
_newp = tmpMeta12;
}
_inNewClasses = _c2;
_inOldProgram = _newp;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
_c1 = tmpMeta13;
_c2 = tmpMeta14;
_p2 = tmp4_3;
_newp = omc_ProgramUtil_insertClassInProgram(threadData, _c1, _w, _p2, _mergeAST);
_inNewClasses = _c2;
_inOldProgram = _newp;
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
_outProgram = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outProgram;
}
modelica_metatype boxptr_ProgramUtil_updateProgram2(threadData_t *threadData, modelica_metatype _inNewClasses, modelica_metatype _w, modelica_metatype _inOldProgram, modelica_metatype _mergeAST)
{
modelica_integer tmp1;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outProgram = omc_ProgramUtil_updateProgram2(threadData, _inNewClasses, _w, _inOldProgram, tmp1);
return _outProgram;
}
DLLDirection
modelica_metatype omc_ProgramUtil_updateProgram(threadData_t *threadData, modelica_metatype _inNewProgram, modelica_metatype _inOldProgram, modelica_boolean _mergeAST)
{
modelica_metatype _outProgram = NULL;
modelica_metatype _cs = NULL;
modelica_metatype _w = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inNewProgram;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
_cs = tmpMeta2;
_w = tmpMeta3;
_outProgram = omc_ProgramUtil_updateProgram2(threadData, listReverse(_cs), _w, _inOldProgram, _mergeAST);
_return: OMC_LABEL_UNUSED
return _outProgram;
}
modelica_metatype boxptr_ProgramUtil_updateProgram(threadData_t *threadData, modelica_metatype _inNewProgram, modelica_metatype _inOldProgram, modelica_metatype _mergeAST)
{
modelica_integer tmp1;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outProgram = omc_ProgramUtil_updateProgram(threadData, _inNewProgram, _inOldProgram, tmp1);
return _outProgram;
}
DLLDirection
modelica_metatype omc_ProgramUtil_buildWithin(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_metatype _outWithin = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_metatype _w_path = NULL;
modelica_metatype _path = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmpMeta1 = _OMC_LIT23;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta5;
_inPath = _path;
goto _tailrecursive;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta6;
_path = tmp4_1;
_w_path = omc_AbsynUtil_stripLast(threadData, _path);
tmpMeta6 = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, _w_path);
tmpMeta1 = tmpMeta6;
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
_outWithin = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outWithin;
}
