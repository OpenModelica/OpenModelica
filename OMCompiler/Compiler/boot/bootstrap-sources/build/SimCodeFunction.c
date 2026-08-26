#include "omc_simulation_settings.h"
#include "SimCodeFunction.h"
#define _OMC_LIT0_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,0,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "name: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,6,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data ", type: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,8,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "VARIABLE("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,9,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,1,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "FUNCTION_PTR("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,13,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,17,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT6,_OMC_LIT7,_OMC_LIT8}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "SimCodeFunction.Variable.toString failed for an unknown reason."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,63,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,2,1) {_OMC_LIT10,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "cref: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,6,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data ", isInput: true"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,15,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data ", isInput: false"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,16,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data ", outputIndex: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,15,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data ", isArray: true"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,15,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data ", isArray: false"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,16,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data ", hasBinding: true"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,18,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data ", hasBinding: false"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,19,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "SIMEXTARG("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,10,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "exp: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,5,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "SIMEXTARGEXP("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,13,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data ", exp: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,7,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "SIMEXTARGSIZE("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,14,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "SIMNOEXTARG()"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,13,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "SimCodeFunction.SimExtArg.toString failed for an unknown reason."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,64,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,2,1) {_OMC_LIT26,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,1,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "FUNCTION("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,9,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data "PARALLEL_FUNCTION("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,18,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "KERNEL_FUNCTION("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,16,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,1,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "  name: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,8,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data ",\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,2,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "  extName: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,11,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data "  funArgs: {"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,12,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,2,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "},\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,3,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "  extArgs: {"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,12,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "  extReturn: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,13,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "  inVars: {"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,11,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "  outVars: {"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,12,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "  biVars: {"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,11,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "  includes: {"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,13,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
#define _OMC_LIT45_data "  libs: {"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT45,9,_OMC_LIT45_data);
#define _OMC_LIT45 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "  language: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,12,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "EXTERNAL_FUNCTION("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,18,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
#define _OMC_LIT48_data "RECORD_CONSTRUCTOR("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT48,19,_OMC_LIT48_data);
#define _OMC_LIT48 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "SimCodeFunction.Function.toString failed for an unknown reason."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,63,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,2,1) {_OMC_LIT49,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
#include "util/modelica.h"
#include "SimCodeFunction_includes.h"
DLLDirection
modelica_string omc_SimCodeFunction_Variable_toString(threadData_t *threadData, modelica_metatype _variable)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = _OMC_LIT0;
{
modelica_metatype tmp4_1;
tmp4_1 = _variable;
{
modelica_string _tmp = NULL;
int tmp4;
_tmp = (modelica_string) mmc_emptystring;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta5 = stringAppend(_tmp,_OMC_LIT1);
tmpMeta6 = stringAppend(tmpMeta5,omc_ComponentReferenceBasics_printComponentRefStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_variable), 2)))));
_tmp = tmpMeta6;
tmpMeta7 = stringAppend(_tmp,_OMC_LIT2);
tmpMeta8 = stringAppend(tmpMeta7,omc_TypesDump_unparseType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_variable), 3)))));
_tmp = tmpMeta8;
tmpMeta9 = stringAppend(_OMC_LIT3,_tmp);
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT4);
tmp1 = tmpMeta10;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
tmpMeta11 = stringAppend(_tmp,_OMC_LIT1);
tmpMeta12 = stringAppend(tmpMeta11,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_variable), 2))));
_tmp = tmpMeta12;
tmpMeta13 = stringAppend(_OMC_LIT5,_tmp);
tmpMeta14 = stringAppend(tmpMeta13,_OMC_LIT4);
tmp1 = tmpMeta14;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
omc_Error_addMessage(threadData, _OMC_LIT9, _OMC_LIT11);
goto goto_2;
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
DLLDirection
modelica_string omc_SimCodeFunction_SimExtArg_toString(threadData_t *threadData, modelica_metatype _simExtArg)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = _OMC_LIT0;
{
modelica_metatype tmp4_1;
tmp4_1 = _simExtArg;
{
modelica_string _tmp = NULL;
int tmp4;
_tmp = (modelica_string) mmc_emptystring;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_boolean tmp9;
modelica_string tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_boolean tmp15;
modelica_string tmp16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_boolean tmp19;
modelica_string tmp20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
tmpMeta5 = stringAppend(_tmp,_OMC_LIT12);
tmpMeta6 = stringAppend(tmpMeta5,omc_ComponentReferenceBasics_printComponentRefStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 2)))));
_tmp = tmpMeta6;
tmp9 = (modelica_boolean)mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 3))));
if(tmp9)
{
tmpMeta7 = stringAppend(_tmp,_OMC_LIT13);
tmp10 = tmpMeta7;
}
else
{
tmpMeta8 = stringAppend(_tmp,_OMC_LIT14);
tmp10 = tmpMeta8;
}
_tmp = tmp10;
tmpMeta11 = stringAppend(_tmp,_OMC_LIT15);
tmpMeta12 = stringAppend(tmpMeta11,intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 4))))));
_tmp = tmpMeta12;
tmp15 = (modelica_boolean)mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 5))));
if(tmp15)
{
tmpMeta13 = stringAppend(_tmp,_OMC_LIT16);
tmp16 = tmpMeta13;
}
else
{
tmpMeta14 = stringAppend(_tmp,_OMC_LIT17);
tmp16 = tmpMeta14;
}
_tmp = tmp16;
tmp19 = (modelica_boolean)mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 6))));
if(tmp19)
{
tmpMeta17 = stringAppend(_tmp,_OMC_LIT18);
tmp20 = tmpMeta17;
}
else
{
tmpMeta18 = stringAppend(_tmp,_OMC_LIT19);
tmp20 = tmpMeta18;
}
_tmp = tmp20;
tmpMeta21 = stringAppend(_tmp,_OMC_LIT2);
tmpMeta22 = stringAppend(tmpMeta21,omc_TypesDump_unparseType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 7)))));
_tmp = tmpMeta22;
tmpMeta23 = stringAppend(_OMC_LIT20,_tmp);
tmpMeta24 = stringAppend(tmpMeta23,_OMC_LIT4);
tmp1 = tmpMeta24;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
tmpMeta25 = stringAppend(_tmp,_OMC_LIT21);
tmpMeta26 = stringAppend(tmpMeta25,omc_ExpressionBasics_printExpStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 2)))));
_tmp = tmpMeta26;
tmpMeta27 = stringAppend(_tmp,_OMC_LIT2);
tmpMeta28 = stringAppend(tmpMeta27,omc_TypesDump_unparseType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 3)))));
_tmp = tmpMeta28;
tmpMeta29 = stringAppend(_OMC_LIT22,_tmp);
tmpMeta30 = stringAppend(tmpMeta29,_OMC_LIT4);
tmp1 = tmpMeta30;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_boolean tmp35;
modelica_string tmp36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
tmpMeta31 = stringAppend(_tmp,_OMC_LIT12);
tmpMeta32 = stringAppend(tmpMeta31,omc_ComponentReferenceBasics_printComponentRefStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 2)))));
_tmp = tmpMeta32;
tmp35 = (modelica_boolean)mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 3))));
if(tmp35)
{
tmpMeta33 = stringAppend(_tmp,_OMC_LIT13);
tmp36 = tmpMeta33;
}
else
{
tmpMeta34 = stringAppend(_tmp,_OMC_LIT14);
tmp36 = tmpMeta34;
}
_tmp = tmp36;
tmpMeta37 = stringAppend(_tmp,_OMC_LIT15);
tmpMeta38 = stringAppend(tmpMeta37,intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 4))))));
_tmp = tmpMeta38;
tmpMeta39 = stringAppend(_tmp,_OMC_LIT2);
tmpMeta40 = stringAppend(tmpMeta39,omc_TypesDump_unparseType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 5)))));
_tmp = tmpMeta40;
tmpMeta41 = stringAppend(_tmp,_OMC_LIT23);
tmpMeta42 = stringAppend(tmpMeta41,omc_ExpressionBasics_printExpStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_simExtArg), 6)))));
_tmp = tmpMeta42;
tmpMeta43 = stringAppend(_OMC_LIT24,_tmp);
tmpMeta44 = stringAppend(tmpMeta43,_OMC_LIT4);
tmp1 = tmpMeta44;
goto tmp3_done;
}
case 6: {
tmp1 = _OMC_LIT25;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
omc_Error_addMessage(threadData, _OMC_LIT9, _OMC_LIT27);
goto goto_2;
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
DLLDirection
modelica_string omc_SimCodeFunction_Function_toString(threadData_t *threadData, modelica_metatype _func)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = _OMC_LIT0;
{
modelica_metatype tmp4_1;
tmp4_1 = _func;
{
modelica_string _tmp = NULL;
modelica_metatype _ls = NULL;
int tmp4;
_tmp = (modelica_string) mmc_emptystring;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta5 = stringAppend(_tmp,_OMC_LIT1);
tmpMeta6 = stringAppend(tmpMeta5,omc_AbsynUtil_pathString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _OMC_LIT28, 1 /* true */, 0 /* false */));
_tmp = tmpMeta6;
tmpMeta7 = stringAppend(_OMC_LIT29,_tmp);
tmpMeta8 = stringAppend(tmpMeta7,_OMC_LIT4);
tmp1 = tmpMeta8;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta9 = stringAppend(_tmp,_OMC_LIT1);
tmpMeta10 = stringAppend(tmpMeta9,omc_AbsynUtil_pathString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _OMC_LIT28, 1 /* true */, 0 /* false */));
_tmp = tmpMeta10;
tmpMeta11 = stringAppend(_OMC_LIT30,_tmp);
tmpMeta12 = stringAppend(tmpMeta11,_OMC_LIT4);
tmp1 = tmpMeta12;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta13 = stringAppend(_tmp,_OMC_LIT1);
tmpMeta14 = stringAppend(tmpMeta13,omc_AbsynUtil_pathString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _OMC_LIT28, 1 /* true */, 0 /* false */));
_tmp = tmpMeta14;
tmpMeta15 = stringAppend(_OMC_LIT31,_tmp);
tmpMeta16 = stringAppend(tmpMeta15,_OMC_LIT4);
tmp1 = tmpMeta16;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
_tmp = _OMC_LIT32;
tmpMeta17 = stringAppend(_tmp,_OMC_LIT33);
tmpMeta18 = stringAppend(tmpMeta17,omc_AbsynUtil_pathString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _OMC_LIT28, 1 /* true */, 0 /* false */));
tmpMeta19 = stringAppend(tmpMeta18,_OMC_LIT34);
_tmp = tmpMeta19;
tmpMeta20 = stringAppend(_tmp,_OMC_LIT35);
tmpMeta21 = stringAppend(tmpMeta20,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 3))));
tmpMeta22 = stringAppend(tmpMeta21,_OMC_LIT34);
_tmp = tmpMeta22;
_ls = omc_List_map(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 4))), boxvar_SimCodeFunction_Variable_toString);
tmpMeta23 = stringAppend(_tmp,_OMC_LIT36);
tmpMeta24 = stringAppend(tmpMeta23,stringDelimitList(_ls, _OMC_LIT37));
tmpMeta25 = stringAppend(tmpMeta24,_OMC_LIT38);
_tmp = tmpMeta25;
_ls = omc_List_map(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 5))), boxvar_SimCodeFunction_SimExtArg_toString);
tmpMeta26 = stringAppend(_tmp,_OMC_LIT39);
tmpMeta27 = stringAppend(tmpMeta26,stringDelimitList(_ls, _OMC_LIT37));
tmpMeta28 = stringAppend(tmpMeta27,_OMC_LIT38);
_tmp = tmpMeta28;
tmpMeta29 = stringAppend(_tmp,_OMC_LIT40);
tmpMeta30 = stringAppend(tmpMeta29,omc_SimCodeFunction_SimExtArg_toString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 6)))));
tmpMeta31 = stringAppend(tmpMeta30,_OMC_LIT34);
_tmp = tmpMeta31;
_ls = omc_List_map(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 7))), boxvar_SimCodeFunction_Variable_toString);
tmpMeta32 = stringAppend(_tmp,_OMC_LIT41);
tmpMeta33 = stringAppend(tmpMeta32,stringDelimitList(_ls, _OMC_LIT37));
tmpMeta34 = stringAppend(tmpMeta33,_OMC_LIT38);
_tmp = tmpMeta34;
_ls = omc_List_map(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 8))), boxvar_SimCodeFunction_Variable_toString);
tmpMeta35 = stringAppend(_tmp,_OMC_LIT42);
tmpMeta36 = stringAppend(tmpMeta35,stringDelimitList(_ls, _OMC_LIT37));
tmpMeta37 = stringAppend(tmpMeta36,_OMC_LIT38);
_tmp = tmpMeta37;
_ls = omc_List_map(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 9))), boxvar_SimCodeFunction_Variable_toString);
tmpMeta38 = stringAppend(_tmp,_OMC_LIT43);
tmpMeta39 = stringAppend(tmpMeta38,stringDelimitList(_ls, _OMC_LIT37));
tmpMeta40 = stringAppend(tmpMeta39,_OMC_LIT38);
_tmp = tmpMeta40;
tmpMeta41 = stringAppend(_tmp,_OMC_LIT44);
tmpMeta42 = stringAppend(tmpMeta41,stringDelimitList((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 10))), _OMC_LIT37));
tmpMeta43 = stringAppend(tmpMeta42,_OMC_LIT38);
_tmp = tmpMeta43;
tmpMeta44 = stringAppend(_tmp,_OMC_LIT45);
tmpMeta45 = stringAppend(tmpMeta44,stringDelimitList((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 11))), _OMC_LIT37));
tmpMeta46 = stringAppend(tmpMeta45,_OMC_LIT38);
_tmp = tmpMeta46;
tmpMeta47 = stringAppend(_tmp,_OMC_LIT46);
tmpMeta48 = stringAppend(tmpMeta47,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 12))));
tmpMeta49 = stringAppend(tmpMeta48,_OMC_LIT32);
_tmp = tmpMeta49;
tmpMeta50 = stringAppend(_OMC_LIT47,_tmp);
tmpMeta51 = stringAppend(tmpMeta50,_OMC_LIT4);
tmp1 = tmpMeta51;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
tmpMeta52 = stringAppend(_tmp,_OMC_LIT1);
tmpMeta53 = stringAppend(tmpMeta52,omc_AbsynUtil_pathString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _OMC_LIT28, 1 /* true */, 0 /* false */));
_tmp = tmpMeta53;
tmpMeta54 = stringAppend(_OMC_LIT48,_tmp);
tmpMeta55 = stringAppend(tmpMeta54,_OMC_LIT4);
tmp1 = tmpMeta55;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
omc_Error_addMessage(threadData, _OMC_LIT9, _OMC_LIT50);
goto goto_2;
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
