#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/Error.c"
#endif
#include "omc_simulation_settings.h"
#include "Error.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,3) {&ErrorTypes_Severity_INTERNAL__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "%s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,2,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,17,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT4}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT0,_OMC_LIT3,_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT7,0.0);
#define _OMC_LIT7 MMC_REFREALLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,1,6) {&ErrorTypes_Severity_NOTIFICATION__desc,}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,2,4) {&Gettext_TranslatableContent_notrans__desc,_OMC_LIT2}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(6001)),_OMC_LIT0,_OMC_LIT8,_OMC_LIT9}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(6000)),_OMC_LIT0,_OMC_LIT11,_OMC_LIT9}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(5999)),_OMC_LIT0,_OMC_LIT3,_OMC_LIT9}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,1,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data ":"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,1,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "-"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,1,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,1,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "Internal error"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,14,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "Error"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,5,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "Warning"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,7,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "Notification"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,12,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "SYNTAX"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,6,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "GRAMMAR"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,7,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "TRANSLATION"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,11,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "SYMBOLIC"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,8,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "SIMULATION"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,10,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "SCRIPTING"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,9,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "not impl yet."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,13,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "Not impl. yet"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,13,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,2,1) {_OMC_LIT29,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "From here:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,10,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT31}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(174)),_OMC_LIT0,_OMC_LIT8,_OMC_LIT32}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data "strict"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,6,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,1,4) {&Flags_FlagVisibility_EXTERNAL__desc,}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,2,4) {&Flags_FlagData_BOOL__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "Enables stricter enforcement of Modelica language rules."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,56,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT37}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(48)),_OMC_LIT34,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT35,_OMC_LIT36,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT38}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "demoMode"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,8,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "Disable Warning/Error Massages."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,31,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT42,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT41}};
#define _OMC_LIT42 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT42)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT43,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(38)),_OMC_LIT40,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT35,_OMC_LIT36,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT42}};
#define _OMC_LIT43 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,0,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
#define _OMC_LIT45_data "Variable "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT45,9,_OMC_LIT45_data);
#define _OMC_LIT45 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data ": "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,2,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT44,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT7}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
#include "util/modelica.h"
#include "Error_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC void omc_Error_failOnErrorMsg(threadData_t *threadData, modelica_metatype _inMessage);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_failOnErrorMsg,2,0) {(void*) boxptr_Error_failOnErrorMsg,0}};
#define boxvar_Error_failOnErrorMsg MMC_REFSTRUCTLIT(boxvar_lit_Error_failOnErrorMsg)
PROTECTED_FUNCTION_STATIC modelica_string omc_Error_clearCurrentComponent_dummy(threadData_t *threadData, modelica_string __omcQ_24in_5Fstr, modelica_integer _i);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Error_clearCurrentComponent_dummy(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fstr, modelica_metatype _i);
static const MMC_DEFSTRUCTLIT(boxvar_lit_Error_clearCurrentComponent_dummy,2,0) {(void*) boxptr_Error_clearCurrentComponent_dummy,0}};
#define boxvar_Error_clearCurrentComponent_dummy MMC_REFSTRUCTLIT(boxvar_lit_Error_clearCurrentComponent_dummy)
DLLExport
void omc_Error_terminateError(threadData_t *threadData, modelica_string _message, modelica_metatype _info)
{
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_cons(_message, MMC_REFSTRUCTLIT(mmc_nil));
omc_ErrorExt_addSourceMessage(threadData, ((modelica_integer) 0), _OMC_LIT0, _OMC_LIT1, mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_info), 4)))), mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_info), 5)))), mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_info), 6)))), mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_info), 7)))), mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_info), 3)))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_info), 2))), _OMC_LIT2, tmpMeta[0]);
fputs(MMC_STRINGDATA(omc_ErrorExt_printMessagesStr(threadData, 0)),stdout);
omc_System_exit(threadData, ((modelica_integer) -1));
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Error_addInternalError(threadData_t *threadData, modelica_string _message, modelica_metatype _info)
{
modelica_string _filename = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_Testsuite_isRunning(threadData))
{
tmpMeta[0] = _info;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_filename = tmpMeta[1];
tmpMeta[0] = mmc_mk_cons(_message, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[1] = mmc_mk_box8(3, &SourceInfo_SOURCEINFO__desc, _filename, mmc_mk_boolean(0), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)), _OMC_LIT7);
omc_Error_addSourceMessage(threadData, _OMC_LIT6, tmpMeta[0], tmpMeta[1]);
}
else
{
tmpMeta[0] = mmc_mk_cons(_message, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT6, tmpMeta[0], _info);
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Error_addCompilerNotification(threadData_t *threadData, modelica_string _message)
{
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_cons(_message, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT10, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Error_addCompilerWarning(threadData_t *threadData, modelica_string _message)
{
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_cons(_message, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT12, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Error_addCompilerError(threadData_t *threadData, modelica_string _message)
{
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_cons(_message, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT13, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_Error_failOnErrorMsg(threadData_t *threadData, modelica_metatype _inMessage)
{
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inMessage;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,0) == 0) goto tmp2_end;
goto goto_1;
goto tmp2_done;
}
case 1: {
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
DLLExport
void omc_Error_assertionOrAddSourceMessage(threadData_t *threadData, modelica_boolean _inCond, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens, modelica_metatype _inInfo)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;
tmp3_1 = _inCond;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (1 != tmp3_1) goto tmp2_end;
goto tmp2_done;
}
case 1: {
omc_Error_addSourceMessage(threadData, _inErrorMsg, _inMessageTokens, _inInfo);
omc_Error_failOnErrorMsg(threadData, _inErrorMsg);
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
void boxptr_Error_assertionOrAddSourceMessage(threadData_t *threadData, modelica_metatype _inCond, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens, modelica_metatype _inInfo)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inCond);
omc_Error_assertionOrAddSourceMessage(threadData, tmp1, _inErrorMsg, _inMessageTokens, _inInfo);
return;
}
DLLExport
void omc_Error_assertion(threadData_t *threadData, modelica_boolean _b, modelica_string _message, modelica_metatype _info)
{
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;
tmp3_1 = _b;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (1 != tmp3_1) goto tmp2_end;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = mmc_mk_cons(_message, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT6, tmpMeta[0], _info);
goto goto_1;
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
void boxptr_Error_assertion(threadData_t *threadData, modelica_metatype _b, modelica_metatype _message, modelica_metatype _info)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_b);
omc_Error_assertion(threadData, tmp1, _message, _info);
return;
}
DLLExport
modelica_string omc_Error_infoStr(threadData_t *threadData, modelica_metatype _info)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _info;
{
modelica_string _filename = NULL;
modelica_integer _line_start;
modelica_integer _line_end;
modelica_integer _col_start;
modelica_integer _col_end;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp7 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmp8 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmp9 = mmc_unbox_integer(tmpMeta[4]);
_filename = tmpMeta[0];
_line_start = tmp6;
_col_start = tmp7;
_line_end = tmp8;
_col_end = tmp9;
tmpMeta[0] = stringAppend(_OMC_LIT14,omc_Testsuite_friendly(threadData, _filename));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT15);
tmpMeta[2] = stringAppend(tmpMeta[1],intString(_line_start));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT15);
tmpMeta[4] = stringAppend(tmpMeta[3],intString(_col_start));
tmpMeta[5] = stringAppend(tmpMeta[4],_OMC_LIT16);
tmpMeta[6] = stringAppend(tmpMeta[5],intString(_line_end));
tmpMeta[7] = stringAppend(tmpMeta[6],_OMC_LIT15);
tmpMeta[8] = stringAppend(tmpMeta[7],intString(_col_end));
tmpMeta[9] = stringAppend(tmpMeta[8],_OMC_LIT17);
tmp1 = tmpMeta[9];
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
DLLExport
modelica_string omc_Error_severityStr(threadData_t *threadData, modelica_metatype _inSeverity)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSeverity;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT18;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT19;
goto tmp3_done;
}
case 5: {
tmp1 = _OMC_LIT20;
goto tmp3_done;
}
case 6: {
tmp1 = _OMC_LIT21;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_Error_messageTypeStr(threadData_t *threadData, modelica_metatype _inMessageType)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inMessageType;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT22;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT23;
goto tmp3_done;
}
case 5: {
tmp1 = _OMC_LIT24;
goto tmp3_done;
}
case 6: {
tmp1 = _OMC_LIT25;
goto tmp3_done;
}
case 7: {
tmp1 = _OMC_LIT26;
goto tmp3_done;
}
case 8: {
tmp1 = _OMC_LIT27;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_Error_getMessagesStrSeverity(threadData_t *threadData, modelica_metatype _inSeverity)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = _OMC_LIT28;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_Error_getMessagesStrType(threadData_t *threadData, modelica_metatype _inMessageType)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = _OMC_LIT28;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_metatype omc_Error_getMessages(threadData_t *threadData)
{
modelica_metatype _res = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_ErrorExt_getMessages(threadData);
_return: OMC_LABEL_UNUSED
return _res;
}
DLLExport
modelica_integer omc_Error_getNumErrorMessages(threadData_t *threadData)
{
modelica_integer _num;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_num = omc_ErrorExt_getNumErrorMessages(threadData);
_return: OMC_LABEL_UNUSED
return _num;
}
modelica_metatype boxptr_Error_getNumErrorMessages(threadData_t *threadData)
{
modelica_integer _num;
modelica_metatype out_num;
_num = omc_Error_getNumErrorMessages(threadData);
out_num = mmc_mk_icon(_num);
return out_num;
}
DLLExport
modelica_integer omc_Error_getNumMessages(threadData_t *threadData)
{
modelica_integer _num;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_num = omc_ErrorExt_getNumMessages(threadData);
_return: OMC_LABEL_UNUSED
return _num;
}
modelica_metatype boxptr_Error_getNumMessages(threadData_t *threadData)
{
modelica_integer _num;
modelica_metatype out_num;
_num = omc_Error_getNumMessages(threadData);
out_num = mmc_mk_icon(_num);
return out_num;
}
DLLExport
void omc_Error_clearMessages(threadData_t *threadData)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_ErrorExt_clearMessages(threadData);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_Error_printMessagesStrLstSeverity(threadData_t *threadData, modelica_metatype _inSeverity)
{
modelica_metatype _outStringLst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStringLst = _OMC_LIT30;
_return: OMC_LABEL_UNUSED
return _outStringLst;
}
DLLExport
modelica_metatype omc_Error_printMessagesStrLstType(threadData_t *threadData, modelica_metatype _inMessageType)
{
modelica_metatype _outStringLst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStringLst = _OMC_LIT30;
_return: OMC_LABEL_UNUSED
return _outStringLst;
}
DLLExport
modelica_metatype omc_Error_printMessagesStrLst(threadData_t *threadData)
{
modelica_metatype _outStringLst = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStringLst = _OMC_LIT30;
_return: OMC_LABEL_UNUSED
return _outStringLst;
}
DLLExport
modelica_string omc_Error_printErrorsNoWarning(threadData_t *threadData)
{
modelica_string _res = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_ErrorExt_printErrorsNoWarning(threadData);
_return: OMC_LABEL_UNUSED
return _res;
}
DLLExport
modelica_string omc_Error_printMessagesStr(threadData_t *threadData, modelica_boolean _warningsAsErrors)
{
modelica_string _res = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_ErrorExt_printMessagesStr(threadData, _warningsAsErrors);
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_Error_printMessagesStr(threadData_t *threadData, modelica_metatype _warningsAsErrors)
{
modelica_integer tmp1;
modelica_string _res = NULL;
tmp1 = mmc_unbox_integer(_warningsAsErrors);
_res = omc_Error_printMessagesStr(threadData, tmp1);
return _res;
}
DLLExport
void omc_Error_addTotalMessages(threadData_t *threadData, modelica_metatype _messages)
{
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _msg;
for (tmpMeta[0] = _messages; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_msg = MMC_CAR(tmpMeta[0]);
omc_Error_addTotalMessage(threadData, _msg);
}
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Error_addTotalMessage(threadData_t *threadData, modelica_metatype _message)
{
modelica_metatype _msg = NULL;
modelica_metatype _info = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _message;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_msg = tmpMeta[1];
_info = tmpMeta[2];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessage(threadData, _msg, tmpMeta[0], _info);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Error_addMessageOrSourceMessage(threadData_t *threadData, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens, modelica_metatype _inInfoOpt)
{
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inInfoOpt;
{
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_1)) goto tmp2_end;
omc_Error_addMessage(threadData, _inErrorMsg, _inMessageTokens);
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_info = tmpMeta[0];
omc_Error_addSourceMessage(threadData, _inErrorMsg, _inMessageTokens, _info);
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
DLLExport
void omc_Error_addMultiSourceMessage(threadData_t *threadData, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens, modelica_metatype _inInfo)
{
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inInfo;
{
modelica_metatype _info = NULL;
modelica_metatype _rest_info = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_CAR(tmp3_1);
tmpMeta[1] = MMC_CDR(tmp3_1);
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
_info = tmpMeta[0];
omc_Error_addSourceMessage(threadData, _inErrorMsg, _inMessageTokens, _info);
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_CAR(tmp3_1);
tmpMeta[1] = MMC_CDR(tmp3_1);
_info = tmpMeta[0];
_rest_info = tmpMeta[1];
if((!listMember(_info, _rest_info)))
{
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessage(threadData, _OMC_LIT33, tmpMeta[0], _info);
}
_inInfo = _rest_info;
goto _tailrecursive;
;
goto tmp2_done;
}
case 2: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
omc_Error_addMessage(threadData, _inErrorMsg, _inMessageTokens);
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
DLLExport
void omc_Error_addSourceMessageAndFail(threadData_t *threadData, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens, modelica_metatype _inInfo)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_Error_addSourceMessage(threadData, _inErrorMsg, _inMessageTokens, _inInfo);
MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Error_addStrictMessage(threadData_t *threadData, modelica_metatype _errorMsg, modelica_metatype _tokens, modelica_metatype _info)
{
modelica_metatype _msg = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_msg = _errorMsg;
if(omc_Flags_getConfigBool(threadData, _OMC_LIT39))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_msg), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = _OMC_LIT3;
_msg = tmpMeta[0];
omc_Error_addSourceMessageAndFail(threadData, _msg, _tokens, _info);
}
else
{
omc_Error_addSourceMessage(threadData, _msg, _tokens, _info);
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Error_addSourceMessageAsError(threadData_t *threadData, modelica_metatype _msg, modelica_metatype _tokens, modelica_metatype _info)
{
modelica_metatype _m = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_m = _msg;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_m), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = _OMC_LIT3;
_m = tmpMeta[0];
omc_Error_addSourceMessage(threadData, _m, _tokens, _info);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_Error_addSourceMessage(threadData_t *threadData, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens, modelica_metatype _inInfo)
{
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _inErrorMsg;
tmp3_2 = _inMessageTokens;
tmp3_3 = _inInfo;
{
modelica_metatype _msg_type = NULL;
modelica_metatype _severity = NULL;
modelica_string _msg_str = NULL;
modelica_string _file = NULL;
modelica_integer _error_id;
modelica_integer _sline;
modelica_integer _scol;
modelica_integer _eline;
modelica_integer _ecol;
modelica_metatype _tokens = NULL;
modelica_boolean _isReadOnly;
modelica_metatype _msg = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
modelica_integer tmp10;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[0]);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmp6 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
tmp7 = mmc_unbox_integer(tmpMeta[6]);
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 5));
tmp8 = mmc_unbox_integer(tmpMeta[7]);
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 6));
tmp9 = mmc_unbox_integer(tmpMeta[8]);
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 7));
tmp10 = mmc_unbox_integer(tmpMeta[9]);
_error_id = tmp5;
_msg_type = tmpMeta[1];
_severity = tmpMeta[2];
_msg = tmpMeta[3];
_tokens = tmp3_2;
_file = tmpMeta[4];
_isReadOnly = tmp6;
_sline = tmp7;
_scol = tmp8;
_eline = tmp9;
_ecol = tmp10;
_msg_str = omc_Gettext_translateContent(threadData, _msg);
omc_ErrorExt_addSourceMessage(threadData, _error_id, _msg_type, _severity, _sline, _scol, _eline, _ecol, _isReadOnly, omc_Testsuite_friendly(threadData, _file), _msg_str, _tokens);
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
DLLExport
void omc_Error_addMessage(threadData_t *threadData, modelica_metatype _inErrorMsg, modelica_metatype _inMessageTokens)
{
modelica_metatype _msg_type = NULL;
modelica_metatype _severity = NULL;
modelica_string _str = NULL;
modelica_string _msg_str = NULL;
modelica_string _file = NULL;
modelica_integer _error_id;
modelica_integer _sline;
modelica_integer _scol;
modelica_integer _eline;
modelica_integer _ecol;
modelica_boolean _isReadOnly;
modelica_metatype _msg = NULL;
modelica_integer tmp1;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((!omc_Flags_getConfigBool(threadData, _OMC_LIT43)))
{
_str = omc_Error_getCurrentComponent(threadData ,&_sline ,&_scol ,&_eline ,&_ecol ,&_isReadOnly ,&_file);
tmpMeta[0] = _inErrorMsg;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_error_id = tmp1;
_msg_type = tmpMeta[2];
_severity = tmpMeta[3];
_msg = tmpMeta[4];
_msg_str = omc_Gettext_translateContent(threadData, _msg);
tmpMeta[0] = stringAppend(_str,_msg_str);
omc_ErrorExt_addSourceMessage(threadData, _error_id, _msg_type, _severity, _sline, _scol, _eline, _ecol, _isReadOnly, omc_Testsuite_friendly(threadData, _file), tmpMeta[0], _inMessageTokens);
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_string omc_Error_getCurrentComponent(threadData_t *threadData, modelica_integer *out_sline, modelica_integer *out_scol, modelica_integer *out_eline, modelica_integer *out_ecol, modelica_boolean *out_read_only, modelica_string *out_filename)
{
modelica_string _str = NULL;
modelica_integer _sline;
modelica_integer _scol;
modelica_integer _eline;
modelica_integer _ecol;
modelica_boolean _read_only;
modelica_string _filename = NULL;
modelica_metatype _tpl = NULL;
modelica_metatype _apre = NULL;
modelica_metatype _astr = NULL;
modelica_metatype _ainfo = NULL;
modelica_metatype _afunc = NULL;
modelica_metatype _info = NULL;
modelica_fnptr _func;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sline = ((modelica_integer) 0);
_scol = ((modelica_integer) 0);
_eline = ((modelica_integer) 0);
_ecol = ((modelica_integer) 0);
_read_only = 0;
_filename = _OMC_LIT44;
_tpl = getGlobalRoot(((modelica_integer) 23));
{
modelica_metatype tmp4_1;
tmp4_1 = _tpl;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmp1 = _OMC_LIT44;
goto tmp3_done;
}
case 1: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_apre = tmpMeta[1];
_astr = tmpMeta[2];
_ainfo = tmpMeta[3];
_afunc = tmpMeta[4];
_str = arrayGet(_astr, ((modelica_integer) 1));
if((!stringEqual(_str, _OMC_LIT44)))
{
_func = (modelica_fnptr) arrayGet(_afunc, ((modelica_integer) 1));
tmpMeta[0] = stringAppend(_OMC_LIT45,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_string, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _str, arrayGet(_apre, ((modelica_integer) 1))) : ((modelica_metatype(*)(threadData_t*, modelica_string, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _str, arrayGet(_apre, ((modelica_integer) 1))));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT46);
_str = tmpMeta[1];
_info = arrayGet(_ainfo, ((modelica_integer) 1));
_sline = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_info), 4))));
_scol = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_info), 5))));
_eline = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_info), 6))));
_ecol = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_info), 7))));
_read_only = mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_info), 3))));
_filename = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_info), 2)));
}
tmp1 = _str;
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
if (out_sline) { *out_sline = _sline; }
if (out_scol) { *out_scol = _scol; }
if (out_eline) { *out_eline = _eline; }
if (out_ecol) { *out_ecol = _ecol; }
if (out_read_only) { *out_read_only = _read_only; }
if (out_filename) { *out_filename = _filename; }
return _str;
}
modelica_metatype boxptr_Error_getCurrentComponent(threadData_t *threadData, modelica_metatype *out_sline, modelica_metatype *out_scol, modelica_metatype *out_eline, modelica_metatype *out_ecol, modelica_metatype *out_read_only, modelica_metatype *out_filename)
{
modelica_integer _sline;
modelica_integer _scol;
modelica_integer _eline;
modelica_integer _ecol;
modelica_boolean _read_only;
modelica_string _str = NULL;
_str = omc_Error_getCurrentComponent(threadData, &_sline, &_scol, &_eline, &_ecol, &_read_only, out_filename);
if (out_sline) { *out_sline = mmc_mk_icon(_sline); }
if (out_scol) { *out_scol = mmc_mk_icon(_scol); }
if (out_eline) { *out_eline = mmc_mk_icon(_eline); }
if (out_ecol) { *out_ecol = mmc_mk_icon(_ecol); }
if (out_read_only) { *out_read_only = mmc_mk_icon(_read_only); }
return _str;
}
DLLExport
void omc_Error_updateCurrentComponent(threadData_t *threadData, modelica_metatype _cpre, modelica_string _component, modelica_metatype _info, modelica_fnptr _func)
{
modelica_metatype _tpl = NULL;
modelica_metatype _apre = NULL;
modelica_metatype _astr = NULL;
modelica_metatype _ainfo = NULL;
modelica_metatype _afunc = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_tpl = getGlobalRoot(((modelica_integer) 23));
{
modelica_metatype tmp3_1;
tmp3_1 = _tpl;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = mmc_mk_box4(0, arrayCreate(((modelica_integer) 1), _cpre), arrayCreate(((modelica_integer) 1), _component), arrayCreate(((modelica_integer) 1), _info), arrayCreate(((modelica_integer) 1), ((modelica_fnptr) _func)));
setGlobalRoot(((modelica_integer) 23), mmc_mk_some(tmpMeta[0]));
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_apre = tmpMeta[1];
_astr = tmpMeta[2];
_ainfo = tmpMeta[3];
_afunc = tmpMeta[4];
arrayUpdate(_apre, ((modelica_integer) 1), _cpre);
arrayUpdate(_astr, ((modelica_integer) 1), _component);
arrayUpdate(_ainfo, ((modelica_integer) 1), _info);
arrayUpdate(_afunc, ((modelica_integer) 1), ((modelica_fnptr) _func));
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
PROTECTED_FUNCTION_STATIC modelica_string omc_Error_clearCurrentComponent_dummy(threadData_t *threadData, modelica_string __omcQ_24in_5Fstr, modelica_integer _i)
{
modelica_string _str = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = __omcQ_24in_5Fstr;
_return: OMC_LABEL_UNUSED
return _str;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_Error_clearCurrentComponent_dummy(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fstr, modelica_metatype _i)
{
modelica_integer tmp1;
modelica_string _str = NULL;
tmp1 = mmc_unbox_integer(_i);
_str = omc_Error_clearCurrentComponent_dummy(threadData, __omcQ_24in_5Fstr, tmp1);
return _str;
}
DLLExport
void omc_Error_clearCurrentComponent(threadData_t *threadData)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_Error_updateCurrentComponent(threadData, mmc_mk_integer(((modelica_integer) 0)), _OMC_LIT44, _OMC_LIT47, boxvar_Error_clearCurrentComponent_dummy);
_return: OMC_LABEL_UNUSED
return;
}
