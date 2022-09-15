#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "ComponentReference.c"
#endif
#include "omc_simulation_settings.h"
#include "ComponentReference.h"
#define _OMC_LIT0_data "time"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,4,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,11) {&DAE_Type_T__UNKNOWN__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "$pDER"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,5,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,1,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,1,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data ":"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,1,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "%d"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,2,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,1,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "der("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,4,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,1,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "previous("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,9,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,1,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "$DER"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,4,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "$CLKPRE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,7,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "_P"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,2,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "Subscript '%s' for dimension %s (size = %s) of %s is out of bounds."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,67,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT17}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(99)),_OMC_LIT15,_OMC_LIT16,_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "$P"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,2,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "function ComponentReference.makeCrefsFromSubScriptExp for:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,58,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,1,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "ComponentReference.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,21,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT24_6,0.0);
#define _OMC_LIT24_6 MMC_REFREALLIT(_OMC_LIT_STRUCT24_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT23,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(3598)),MMC_IMMEDIATE(MMC_TAGFIXNUM(7)),MMC_IMMEDIATE(MMC_TAGFIXNUM(3598)),MMC_IMMEDIATE(MMC_TAGFIXNUM(118)),_OMC_LIT24_6}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "function ComponentReference.makeCrefsFromSubScriptLst for:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,58,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT26_6,0.0);
#define _OMC_LIT26_6 MMC_REFREALLIT(_OMC_LIT_STRUCT26_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT23,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(3554)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(3554)),MMC_IMMEDIATE(MMC_TAGFIXNUM(120)),_OMC_LIT26_6}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,1,3) {&DAE_Subscript_WHOLEDIM__desc,}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,9,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,41,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT29}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT28,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT30}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "- ComponentReference.expandCref failed on "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,42,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,1,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,2,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "}\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,2,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data "}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,1,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "_L"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,2,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "_R"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,2,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "_"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,1,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "__"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,2,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,0,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "WARNING - Expression.replaceCref_SliceSub setting subscript last, not containing dimension\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,91,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "- Expression.replaceCref_SliceSub failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,41,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "ComponentReference.crefSetType was applied on a cref that has no type: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,71,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT45_6,0.0);
#define _OMC_LIT45_6 MMC_REFREALLIT(_OMC_LIT_STRUCT45_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT23,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2541)),MMC_IMMEDIATE(MMC_TAGFIXNUM(7)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2541)),MMC_IMMEDIATE(MMC_TAGFIXNUM(124)),_OMC_LIT45_6}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "function ComponentReference.crefApplySubs to non array\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,55,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT47_6,0.0);
#define _OMC_LIT47_6 MMC_REFREALLIT(_OMC_LIT_STRUCT47_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT23,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2520)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2520)),MMC_IMMEDIATE(MMC_TAGFIXNUM(105)),_OMC_LIT47_6}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
#define _OMC_LIT48_data "$START"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT48,6,_OMC_LIT48_data);
#define _OMC_LIT48 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "$PRE"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,4,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
#define _OMC_LIT50_data "$AUX"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT50,4,_OMC_LIT50_data);
#define _OMC_LIT50 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,2,4) {&DAE_Type_T__REAL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
#define _OMC_LIT52_data "$concealed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT52,10,_OMC_LIT52_data);
#define _OMC_LIT52 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "Cpp"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,3,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data "-ComponentReference.crefType failed on Cref:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,44,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "ComponentReference.crefType failed on cref: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,44,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "ComponentReference.crefTypeFull2 failed on cref: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,49,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT57,2,3) {&DAE_Exp_ICONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT57 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT57)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT58,2,5) {&DAE_Subscript_INDEX__desc,_OMC_LIT57}};
#define _OMC_LIT58 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "traverseCref failed!"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,20,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,1,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data " ["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,2,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "] ."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,3,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "] __"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,4,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT64,2,0) {_OMC_LIT37,_OMC_LIT38}};
#define _OMC_LIT64 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT64)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT65,2,0) {_OMC_LIT3,_OMC_LIT7}};
#define _OMC_LIT65 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data "NONE()"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,6,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
#define _OMC_LIT67_data "SOME("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT67,5,_OMC_LIT67_data);
#define _OMC_LIT67 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "modelicaOutput"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,14,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
#define _OMC_LIT69_data "m"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT69,1,_OMC_LIT69_data);
#define _OMC_LIT69 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT69)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT70,1,1) {_OMC_LIT69}};
#define _OMC_LIT70 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT70)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT71,1,4) {&Flags_FlagVisibility_EXTERNAL__desc,}};
#define _OMC_LIT71 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT71)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT72,2,4) {&Flags_FlagData_BOOL__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT72 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT72)
#define _OMC_LIT73_data "Enables valid modelica output for flat modelica."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,48,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT74,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT73}};
#define _OMC_LIT74 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT74)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT75,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(21)),_OMC_LIT68,_OMC_LIT70,_OMC_LIT71,_OMC_LIT72,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT74}};
#define _OMC_LIT75 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT75)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT76,1,6) {&DAE_ComponentRef_WILD__desc,}};
#define _OMC_LIT76 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT76)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT77,1,3) {&Absyn_Subscript_NOSUB__desc,}};
#define _OMC_LIT77 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data "ComponentReference.unelabCref failed on: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,41,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
#define _OMC_LIT79_data "dummy"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT79,5,_OMC_LIT79_data);
#define _OMC_LIT79 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT79)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT80,4,4) {&DAE_ComponentRef_CREF__IDENT__desc,_OMC_LIT79,_OMC_LIT1,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT80 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT80)
#include "util/modelica.h"
#include "ComponentReference_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC void omc_ComponentReference_printSubscriptBoundsError(threadData_t *threadData, modelica_metatype _inSubscriptExp, modelica_metatype _inDimension, modelica_integer _inIndex, modelica_metatype _inCref, modelica_metatype _inInfo);
PROTECTED_FUNCTION_STATIC void boxptr_ComponentReference_printSubscriptBoundsError(threadData_t *threadData, modelica_metatype _inSubscriptExp, modelica_metatype _inDimension, modelica_metatype _inIndex, modelica_metatype _inCref, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_printSubscriptBoundsError,2,0) {(void*) boxptr_ComponentReference_printSubscriptBoundsError,0}};
#define boxvar_ComponentReference_printSubscriptBoundsError MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_printSubscriptBoundsError)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReference_subscriptExpOutOfBounds(threadData_t *threadData, modelica_integer _inDimSize, modelica_metatype _inSubscriptExp);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_subscriptExpOutOfBounds(threadData_t *threadData, modelica_metatype _inDimSize, modelica_metatype _inSubscriptExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_subscriptExpOutOfBounds,2,0) {(void*) boxptr_ComponentReference_subscriptExpOutOfBounds,0}};
#define boxvar_ComponentReference_subscriptExpOutOfBounds MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_subscriptExpOutOfBounds)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReference_checkCrefSubscriptBounds(threadData_t *threadData, modelica_metatype _inSubscript, modelica_metatype _inDimension, modelica_integer _inIndex, modelica_metatype _inWholeCref, modelica_metatype _inInfo);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_checkCrefSubscriptBounds(threadData_t *threadData, modelica_metatype _inSubscript, modelica_metatype _inDimension, modelica_metatype _inIndex, modelica_metatype _inWholeCref, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_checkCrefSubscriptBounds,2,0) {(void*) boxptr_ComponentReference_checkCrefSubscriptBounds,0}};
#define boxvar_ComponentReference_checkCrefSubscriptBounds MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_checkCrefSubscriptBounds)
PROTECTED_FUNCTION_STATIC void omc_ComponentReference_checkCrefSubscriptsBounds4(threadData_t *threadData, modelica_metatype _inSubscripts, modelica_metatype _inDimensions, modelica_integer _inIndex, modelica_metatype _inWholeCref, modelica_metatype _inInfo);
PROTECTED_FUNCTION_STATIC void boxptr_ComponentReference_checkCrefSubscriptsBounds4(threadData_t *threadData, modelica_metatype _inSubscripts, modelica_metatype _inDimensions, modelica_metatype _inIndex, modelica_metatype _inWholeCref, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_checkCrefSubscriptsBounds4,2,0) {(void*) boxptr_ComponentReference_checkCrefSubscriptsBounds4,0}};
#define boxvar_ComponentReference_checkCrefSubscriptsBounds4 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_checkCrefSubscriptsBounds4)
PROTECTED_FUNCTION_STATIC void omc_ComponentReference_checkCrefSubscriptsBounds3(threadData_t *threadData, modelica_metatype _inCrefType, modelica_metatype _inSubscripts, modelica_metatype _inWholeCref, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_checkCrefSubscriptsBounds3,2,0) {(void*) boxptr_ComponentReference_checkCrefSubscriptsBounds3,0}};
#define boxvar_ComponentReference_checkCrefSubscriptsBounds3 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_checkCrefSubscriptsBounds3)
PROTECTED_FUNCTION_STATIC void omc_ComponentReference_checkCrefSubscriptsBounds2(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inWholeCref, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_checkCrefSubscriptsBounds2,2,0) {(void*) boxptr_ComponentReference_checkCrefSubscriptsBounds2,0}};
#define boxvar_ComponentReference_checkCrefSubscriptsBounds2 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_checkCrefSubscriptsBounds2)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReference_identifierCount__tail(threadData_t *threadData, modelica_metatype _inCref, modelica_integer _inAccumCount);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_identifierCount__tail(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inAccumCount);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_identifierCount__tail,2,0) {(void*) boxptr_ComponentReference_identifierCount__tail,0}};
#define boxvar_ComponentReference_identifierCount__tail MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_identifierCount__tail)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_implode__tail(threadData_t *threadData, modelica_metatype _inParts, modelica_metatype _inAccumCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_implode__tail,2,0) {(void*) boxptr_ComponentReference_implode__tail,0}};
#define boxvar_ComponentReference_implode__tail MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_implode__tail)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_explode__tail(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inParts);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_explode__tail,2,0) {(void*) boxptr_ComponentReference_explode__tail,0}};
#define boxvar_ComponentReference_explode__tail MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_explode__tail)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_expandArrayCref1(threadData_t *threadData, modelica_metatype _inCr, modelica_metatype _inSubscripts, modelica_metatype _inAccumSubs, modelica_metatype _inAccumCrefs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_expandArrayCref1,2,0) {(void*) boxptr_ComponentReference_expandArrayCref1,0}};
#define boxvar_ComponentReference_expandArrayCref1 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_expandArrayCref1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_expandCref2(threadData_t *threadData, modelica_string _inId, modelica_metatype _inType, modelica_metatype _inSubscripts, modelica_metatype _inDimensions);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_expandCref2,2,0) {(void*) boxptr_ComponentReference_expandCref2,0}};
#define boxvar_ComponentReference_expandCref2 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_expandCref2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_expandCrefQual(threadData_t *threadData, modelica_metatype _inHeadCrefs, modelica_metatype _inRestCrefs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_expandCrefQual,2,0) {(void*) boxptr_ComponentReference_expandCrefQual,0}};
#define boxvar_ComponentReference_expandCrefQual MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_expandCrefQual)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_expandCrefLst(threadData_t *threadData, modelica_metatype _inCrefs, modelica_metatype _varLst, modelica_metatype _inCrefsAcc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_expandCrefLst,2,0) {(void*) boxptr_ComponentReference_expandCrefLst,0}};
#define boxvar_ComponentReference_expandCrefLst MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_expandCrefLst)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReference_crefDepth1(threadData_t *threadData, modelica_metatype _inCref, modelica_integer _iDepth);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_crefDepth1(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _iDepth);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_crefDepth1,2,0) {(void*) boxptr_ComponentReference_crefDepth1,0}};
#define boxvar_ComponentReference_crefDepth1 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_crefDepth1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_toStringList__tail(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inAccumStrings);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_toStringList__tail,2,0) {(void*) boxptr_ComponentReference_toStringList__tail,0}};
#define boxvar_ComponentReference_toStringList__tail MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_toStringList__tail)
PROTECTED_FUNCTION_STATIC void omc_ComponentReference_printComponentRef2(threadData_t *threadData, modelica_string _inString, modelica_metatype _inSubscriptLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_printComponentRef2,2,0) {(void*) boxptr_ComponentReference_printComponentRef2,0}};
#define boxvar_ComponentReference_printComponentRef2 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_printComponentRef2)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReference_crefStripSubsExceptModelSubs_is__model__array(threadData_t *threadData, modelica_metatype _ty);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_crefStripSubsExceptModelSubs_is__model__array(threadData_t *threadData, modelica_metatype _ty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_crefStripSubsExceptModelSubs_is__model__array,2,0) {(void*) boxptr_ComponentReference_crefStripSubsExceptModelSubs_is__model__array,0}};
#define boxvar_ComponentReference_crefStripSubsExceptModelSubs_is__model__array MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_crefStripSubsExceptModelSubs_is__model__array)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_removeSliceSubs(threadData_t *threadData, modelica_metatype _subs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_removeSliceSubs,2,0) {(void*) boxptr_ComponentReference_removeSliceSubs,0}};
#define boxvar_ComponentReference_removeSliceSubs MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_removeSliceSubs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_replaceSliceSub(threadData_t *threadData, modelica_metatype _inSubs, modelica_metatype _inSub);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_replaceSliceSub,2,0) {(void*) boxptr_ComponentReference_replaceSliceSub,0}};
#define boxvar_ComponentReference_replaceSliceSub MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_replaceSliceSub)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_crefTypeFullComputeDims(threadData_t *threadData, modelica_metatype _inDims, modelica_metatype _inSubs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_crefTypeFullComputeDims,2,0) {(void*) boxptr_ComponentReference_crefTypeFullComputeDims,0}};
#define boxvar_ComponentReference_crefTypeFullComputeDims MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_crefTypeFullComputeDims)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReference_containWholeDim3(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _ad);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_containWholeDim3(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _ad);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_containWholeDim3,2,0) {(void*) boxptr_ComponentReference_containWholeDim3,0}};
#define boxvar_ComponentReference_containWholeDim3 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_containWholeDim3)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReference_containWholeDim2(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inType);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_containWholeDim2(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_containWholeDim2,2,0) {(void*) boxptr_ComponentReference_containWholeDim2,0}};
#define boxvar_ComponentReference_containWholeDim2 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_containWholeDim2)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReference_crefEqualWithoutSubs2(threadData_t *threadData, modelica_boolean _refEq, modelica_metatype _icr1, modelica_metatype _icr2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_crefEqualWithoutSubs2(threadData_t *threadData, modelica_metatype _refEq, modelica_metatype _icr1, modelica_metatype _icr2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_crefEqualWithoutSubs2,2,0) {(void*) boxptr_ComponentReference_crefEqualWithoutSubs2,0}};
#define boxvar_ComponentReference_crefEqualWithoutSubs2 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_crefEqualWithoutSubs2)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReference_crefLexicalCompareSubsAtEnd2(threadData_t *threadData, modelica_metatype _inSubs1, modelica_metatype _inSubs2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_crefLexicalCompareSubsAtEnd2(threadData_t *threadData, modelica_metatype _inSubs1, modelica_metatype _inSubs2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_crefLexicalCompareSubsAtEnd2,2,0) {(void*) boxptr_ComponentReference_crefLexicalCompareSubsAtEnd2,0}};
#define boxvar_ComponentReference_crefLexicalCompareSubsAtEnd2 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_crefLexicalCompareSubsAtEnd2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_toExpCrefSubs(threadData_t *threadData, modelica_metatype _absynSubs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_toExpCrefSubs,2,0) {(void*) boxptr_ComponentReference_toExpCrefSubs,0}};
#define boxvar_ComponentReference_toExpCrefSubs MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_toExpCrefSubs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_unelabSubscripts(threadData_t *threadData, modelica_metatype _inSubscriptLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_unelabSubscripts,2,0) {(void*) boxptr_ComponentReference_unelabSubscripts,0}};
#define boxvar_ComponentReference_unelabSubscripts MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_unelabSubscripts)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReference_hashSubscript(threadData_t *threadData, modelica_metatype _sub);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_hashSubscript(threadData_t *threadData, modelica_metatype _sub);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_hashSubscript,2,0) {(void*) boxptr_ComponentReference_hashSubscript,0}};
#define boxvar_ComponentReference_hashSubscript MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_hashSubscript)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReference_hashSubscripts2(threadData_t *threadData, modelica_metatype _dims, modelica_metatype _subs, modelica_integer _factor);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_hashSubscripts2(threadData_t *threadData, modelica_metatype _dims, modelica_metatype _subs, modelica_metatype _factor);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_hashSubscripts2,2,0) {(void*) boxptr_ComponentReference_hashSubscripts2,0}};
#define boxvar_ComponentReference_hashSubscripts2 MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_hashSubscripts2)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReference_hashSubscripts(threadData_t *threadData, modelica_metatype _tp, modelica_metatype _subs);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_hashSubscripts(threadData_t *threadData, modelica_metatype _tp, modelica_metatype _subs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ComponentReference_hashSubscripts,2,0) {(void*) boxptr_ComponentReference_hashSubscripts,0}};
#define boxvar_ComponentReference_hashSubscripts MMC_REFSTRUCTLIT(boxvar_lit_ComponentReference_hashSubscripts)
DLLExport
modelica_boolean omc_ComponentReference_isWild(threadData_t *threadData, modelica_metatype _cref)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
tmp1 = 1;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_ComponentReference_isWild(threadData_t *threadData, modelica_metatype _cref)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ComponentReference_isWild(threadData, _cref);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_ComponentReference_isTime(threadData_t *threadData, modelica_metatype _cref)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (4 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT0), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
tmp1 = 1;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_ComponentReference_isTime(threadData_t *threadData, modelica_metatype _cref)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ComponentReference_isTime(threadData, _cref);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_ComponentReference_createDifferentiatedCrefName(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inX, modelica_string _inMatrixName)
{
modelica_metatype _outCref = NULL;
modelica_metatype _subs = NULL;
modelica_boolean _debug;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_debug = 0;
_subs = omc_ComponentReference_crefLastSubs(threadData, _inCref);
_outCref = omc_ComponentReference_crefStripLastSubs(threadData, _inCref);
_outCref = omc_ComponentReference_replaceSubsWithString(threadData, _outCref);
_outCref = omc_ComponentReference_crefSetLastType(threadData, _outCref, _OMC_LIT1);
tmpMeta1 = stringAppend(_OMC_LIT2,_inMatrixName);
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_outCref = omc_ComponentReference_joinCrefs(threadData, _outCref, omc_ComponentReference_makeCrefIdent(threadData, tmpMeta1, _OMC_LIT1, tmpMeta2));
_outCref = omc_ComponentReference_joinCrefs(threadData, _outCref, _inX);
_outCref = omc_ComponentReference_crefSetLastSubs(threadData, _outCref, _subs);
_outCref = omc_ComponentReference_crefSetLastType(threadData, _outCref, omc_ComponentReference_crefLastType(threadData, _inCref));
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_real omc_ComponentReference_getConsumedMemory(threadData_t *threadData, modelica_metatype _inCref, modelica_real *out_szTypes, modelica_real *out_szSubs)
{
modelica_real _szIdents;
modelica_real _szTypes;
modelica_real _szSubs;
modelica_metatype _cr = NULL;
modelica_boolean _b;
modelica_boolean tmp1_c0 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_szIdents = 0.0;
_szTypes = 0.0;
_szSubs = 0.0;
_cr = _inCref;
_b = 1;
while(1)
{
if(!_b) break;
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
_szIdents = _szIdents + omc_System_getSizeOfData(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 2))), NULL, NULL);
_szTypes = _szTypes + omc_System_getSizeOfData(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 3))), NULL, NULL);
_szSubs = _szSubs + omc_System_getSizeOfData(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 4))), NULL, NULL);
tmp1_c0 = 0;
tmpMeta[0+1] = _cr;
goto tmp3_done;
}
case 3: {
_szIdents = _szIdents + omc_System_getSizeOfData(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 2))), NULL, NULL);
_szTypes = _szTypes + omc_System_getSizeOfData(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 3))), NULL, NULL);
_szSubs = _szSubs + omc_System_getSizeOfData(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 4))), NULL, NULL);
tmp1_c0 = 1;
tmpMeta[0+1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr), 5)));
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmp1_c0 = 0;
tmpMeta[0+1] = _cr;
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
_b = tmp1_c0;
_cr = tmpMeta[0+1];
}
_return: OMC_LABEL_UNUSED
if (out_szTypes) { *out_szTypes = _szTypes; }
if (out_szSubs) { *out_szSubs = _szSubs; }
return _szIdents;
}
modelica_metatype boxptr_ComponentReference_getConsumedMemory(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype *out_szTypes, modelica_metatype *out_szSubs)
{
modelica_real _szTypes;
modelica_real _szSubs;
modelica_real _szIdents;
modelica_metatype out_szIdents;
_szIdents = omc_ComponentReference_getConsumedMemory(threadData, _inCref, &_szTypes, &_szSubs);
out_szIdents = mmc_mk_rcon(_szIdents);
if (out_szTypes) { *out_szTypes = mmc_mk_rcon(_szTypes); }
if (out_szSubs) { *out_szSubs = mmc_mk_rcon(_szSubs); }
return out_szIdents;
}
DLLExport
void omc_ComponentReference_writeSubscripts(threadData_t *threadData, modelica_complex _file, modelica_metatype _subs, modelica_integer _escape)
{
modelica_boolean _first;
modelica_integer _i;
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta18;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_first = 1;
if(listEmpty(_subs))
{
goto _return;
}
omc_File_write(threadData, _file, _OMC_LIT3);
{
modelica_metatype _s;
for (tmpMeta1 = _subs; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_s = MMC_CAR(tmpMeta1);
if((!_first))
{
omc_File_write(threadData, _file, _OMC_LIT4);
}
else
{
_first = 0;
}
{
modelica_metatype tmp4_1;
tmp4_1 = _s;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
omc_File_write(threadData, _file, _OMC_LIT5);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmp8 = mmc_unbox_integer(tmpMeta7);
_i = tmp8;
omc_File_writeInt(threadData, _file, _i, _OMC_LIT6);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_integer tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmp11 = mmc_unbox_integer(tmpMeta10);
_i = tmp11;
omc_File_writeInt(threadData, _file, _i, _OMC_LIT6);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_integer tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,0,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
tmp14 = mmc_unbox_integer(tmpMeta13);
_i = tmp14;
omc_File_writeInt(threadData, _file, _i, _OMC_LIT6);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta15;
omc_File_write(threadData, _file, omc_ExpressionDump_printExpStr(threadData, _exp));
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta16;
omc_File_write(threadData, _file, omc_ExpressionDump_printExpStr(threadData, _exp));
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta17;
omc_File_write(threadData, _file, omc_ExpressionDump_printExpStr(threadData, _exp));
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
;
}
}
omc_File_write(threadData, _file, _OMC_LIT7);
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_ComponentReference_writeSubscripts(threadData_t *threadData, modelica_metatype _file, modelica_metatype _subs, modelica_metatype _escape)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_escape);
omc_ComponentReference_writeSubscripts(threadData, _file, _subs, tmp1);
return;
}
DLLExport
void omc_ComponentReference_writeCref(threadData_t *threadData, modelica_complex _file, modelica_metatype _cref, modelica_integer _escape)
{
modelica_metatype _c = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_c = _cref;
while(1)
{
if(!1) break;
{
modelica_metatype tmp4_1;
tmp4_1 = _c;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
omc_File_writeEscape(threadData, _file, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 2))), (modelica_integer)_escape);
omc_ComponentReference_writeSubscripts(threadData, _file, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 4))), (modelica_integer)_escape);
goto _return;
goto goto_2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (4 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT12), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
omc_File_write(threadData, _file, _OMC_LIT8);
omc_ComponentReference_writeCref(threadData, _file, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 5))), (modelica_integer)_escape);
omc_File_write(threadData, _file, _OMC_LIT9);
goto _return;
goto goto_2;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (7 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT13), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
omc_File_write(threadData, _file, _OMC_LIT10);
omc_ComponentReference_writeCref(threadData, _file, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 5))), (modelica_integer)_escape);
omc_File_write(threadData, _file, _OMC_LIT9);
goto _return;
goto goto_2;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
omc_File_writeEscape(threadData, _file, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 2))), (modelica_integer)_escape);
omc_ComponentReference_writeSubscripts(threadData, _file, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 4))), (modelica_integer)_escape);
omc_File_write(threadData, _file, _OMC_LIT11);
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_c), 5)));
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
_c = tmpMeta1;
}
_return: OMC_LABEL_UNUSED
return;
}
void boxptr_ComponentReference_writeCref(threadData_t *threadData, modelica_metatype _file, modelica_metatype _cref, modelica_metatype _escape)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_escape);
omc_ComponentReference_writeCref(threadData, _file, _cref, tmp1);
return;
}
DLLExport
modelica_string omc_ComponentReference_crefAppendedSubs(threadData_t *threadData, modelica_metatype _cref)
{
modelica_string _s = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s1 = stringDelimitList(omc_ComponentReference_toStringList(threadData, _cref), _OMC_LIT14);
_s2 = stringDelimitList(omc_List_mapMap(threadData, omc_ComponentReference_crefSubs(threadData, _cref), boxvar_Expression_getSubscriptExp, boxvar_ExpressionDump_printExpStr), _OMC_LIT4);
tmpMeta1 = stringAppend(_s1,_OMC_LIT3);
tmpMeta2 = stringAppend(tmpMeta1,_s2);
tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT7);
_s = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _s;
}
PROTECTED_FUNCTION_STATIC void omc_ComponentReference_printSubscriptBoundsError(threadData_t *threadData, modelica_metatype _inSubscriptExp, modelica_metatype _inDimension, modelica_integer _inIndex, modelica_metatype _inCref, modelica_metatype _inInfo)
{
modelica_string _sub_str = NULL;
modelica_string _dim_str = NULL;
modelica_string _idx_str = NULL;
modelica_string _cref_str = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sub_str = omc_ExpressionDump_printExpStr(threadData, _inSubscriptExp);
_dim_str = omc_ExpressionDump_dimensionString(threadData, _inDimension);
_idx_str = intString(_inIndex);
_cref_str = omc_ComponentReference_printComponentRefStr(threadData, _inCref);
tmpMeta1 = mmc_mk_cons(_sub_str, mmc_mk_cons(_idx_str, mmc_mk_cons(_dim_str, mmc_mk_cons(_cref_str, MMC_REFSTRUCTLIT(mmc_nil)))));
omc_Error_addSourceMessage(threadData, _OMC_LIT19, tmpMeta1, _inInfo);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void boxptr_ComponentReference_printSubscriptBoundsError(threadData_t *threadData, modelica_metatype _inSubscriptExp, modelica_metatype _inDimension, modelica_metatype _inIndex, modelica_metatype _inCref, modelica_metatype _inInfo)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inIndex);
omc_ComponentReference_printSubscriptBoundsError(threadData, _inSubscriptExp, _inDimension, tmp1, _inCref, _inInfo);
return;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReference_subscriptExpOutOfBounds(threadData_t *threadData, modelica_integer _inDimSize, modelica_metatype _inSubscriptExp)
{
modelica_boolean _outOutOfBounds;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSubscriptExp;
{
modelica_integer _i;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
_i = tmp7;
tmp1 = ((_i < ((modelica_integer) 1)) || (_i > _inDimSize));
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
_outOutOfBounds = tmp1;
_return: OMC_LABEL_UNUSED
return _outOutOfBounds;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_subscriptExpOutOfBounds(threadData_t *threadData, modelica_metatype _inDimSize, modelica_metatype _inSubscriptExp)
{
modelica_integer tmp1;
modelica_boolean _outOutOfBounds;
modelica_metatype out_outOutOfBounds;
tmp1 = mmc_unbox_integer(_inDimSize);
_outOutOfBounds = omc_ComponentReference_subscriptExpOutOfBounds(threadData, tmp1, _inSubscriptExp);
out_outOutOfBounds = mmc_mk_icon(_outOutOfBounds);
return out_outOutOfBounds;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReference_checkCrefSubscriptBounds(threadData_t *threadData, modelica_metatype _inSubscript, modelica_metatype _inDimension, modelica_integer _inIndex, modelica_metatype _inWholeCref, modelica_metatype _inInfo)
{
modelica_boolean _outIsValid;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inSubscript;
tmp4_2 = _inDimension;
{
modelica_integer _idx;
modelica_integer _dim;
modelica_metatype _expl = NULL;
modelica_metatype _exp = NULL;
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
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
_dim = tmp7;
_exp = tmpMeta8;
_idx = tmp10;
tmp4 += 1;
tmp11 = ((_idx > ((modelica_integer) 0)) && (_idx <= _dim));
if (0 != tmp11) goto goto_2;
omc_ComponentReference_printSubscriptBoundsError(threadData, _exp, _inDimension, _inIndex, _inWholeCref, _inInfo);
tmp1 = 0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_integer tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp13 = mmc_unbox_integer(tmpMeta12);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,16,3) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 4));
_dim = tmp13;
_expl = tmpMeta15;
_exp = omc_List_getMemberOnTrue(threadData, mmc_mk_integer(_dim), _expl, boxvar_ComponentReference_subscriptExpOutOfBounds);
omc_ComponentReference_printSubscriptBoundsError(threadData, _exp, _inDimension, _inIndex, _inWholeCref, _inInfo);
tmp1 = 0;
goto tmp3_done;
}
case 2: {
tmp1 = 1;
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
_outIsValid = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsValid;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_checkCrefSubscriptBounds(threadData_t *threadData, modelica_metatype _inSubscript, modelica_metatype _inDimension, modelica_metatype _inIndex, modelica_metatype _inWholeCref, modelica_metatype _inInfo)
{
modelica_integer tmp1;
modelica_boolean _outIsValid;
modelica_metatype out_outIsValid;
tmp1 = mmc_unbox_integer(_inIndex);
_outIsValid = omc_ComponentReference_checkCrefSubscriptBounds(threadData, _inSubscript, _inDimension, tmp1, _inWholeCref, _inInfo);
out_outIsValid = mmc_mk_icon(_outIsValid);
return out_outIsValid;
}
PROTECTED_FUNCTION_STATIC void omc_ComponentReference_checkCrefSubscriptsBounds4(threadData_t *threadData, modelica_metatype _inSubscripts, modelica_metatype _inDimensions, modelica_integer _inIndex, modelica_metatype _inWholeCref, modelica_metatype _inInfo)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inSubscripts;
tmp3_2 = _inDimensions;
{
modelica_metatype _sub = NULL;
modelica_metatype _rest_subs = NULL;
modelica_metatype _dim = NULL;
modelica_metatype _rest_dims = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_boolean tmp9;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta5 = MMC_CAR(tmp3_1);
tmpMeta6 = MMC_CDR(tmp3_1);
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta7 = MMC_CAR(tmp3_2);
tmpMeta8 = MMC_CDR(tmp3_2);
_sub = tmpMeta5;
_rest_subs = tmpMeta6;
_dim = tmpMeta7;
_rest_dims = tmpMeta8;
tmp9 = omc_ComponentReference_checkCrefSubscriptBounds(threadData, _sub, _dim, _inIndex, _inWholeCref, _inInfo);
if (1 != tmp9) goto goto_1;
_inSubscripts = _rest_subs;
_inDimensions = _rest_dims;
_inIndex = ((modelica_integer) 1) + _inIndex;
goto _tailrecursive;
;
goto tmp2_done;
}
case 1: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
goto tmp2_done;
}
case 2: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
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
PROTECTED_FUNCTION_STATIC void boxptr_ComponentReference_checkCrefSubscriptsBounds4(threadData_t *threadData, modelica_metatype _inSubscripts, modelica_metatype _inDimensions, modelica_metatype _inIndex, modelica_metatype _inWholeCref, modelica_metatype _inInfo)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_inIndex);
omc_ComponentReference_checkCrefSubscriptsBounds4(threadData, _inSubscripts, _inDimensions, tmp1, _inWholeCref, _inInfo);
return;
}
PROTECTED_FUNCTION_STATIC void omc_ComponentReference_checkCrefSubscriptsBounds3(threadData_t *threadData, modelica_metatype _inCrefType, modelica_metatype _inSubscripts, modelica_metatype _inWholeCref, modelica_metatype _inInfo)
{
modelica_metatype _dims = NULL;
modelica_metatype _subs = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_dims = omc_Types_getDimensions(threadData, _inCrefType);
_dims = listReverse(_dims);
_subs = listReverse(_inSubscripts);
omc_ComponentReference_checkCrefSubscriptsBounds4(threadData, _subs, _dims, ((modelica_integer) 1), _inWholeCref, _inInfo);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_ComponentReference_checkCrefSubscriptsBounds2(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inWholeCref, modelica_metatype _inInfo)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inCref;
{
modelica_metatype _ty = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _rest_cr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_ty = tmpMeta5;
_subs = tmpMeta6;
_rest_cr = tmpMeta7;
omc_ComponentReference_checkCrefSubscriptsBounds3(threadData, _ty, _subs, _inWholeCref, _inInfo);
_inCref = _rest_cr;
goto _tailrecursive;
;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_ty = tmpMeta8;
_subs = tmpMeta9;
omc_ComponentReference_checkCrefSubscriptsBounds3(threadData, _ty, _subs, _inWholeCref, _inInfo);
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
void omc_ComponentReference_checkCrefSubscriptsBounds(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inInfo)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_ComponentReference_checkCrefSubscriptsBounds2(threadData, _inCref, _inCref, _inInfo);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReference_identifierCount__tail(threadData_t *threadData, modelica_metatype _inCref, modelica_integer _inAccumCount)
{
modelica_integer _outIdCount;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta6;
_inCref = _cr;
_inAccumCount = ((modelica_integer) 1) + _inAccumCount;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
tmp1 = ((modelica_integer) 1) + _inAccumCount;
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
_outIdCount = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdCount;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_identifierCount__tail(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inAccumCount)
{
modelica_integer tmp1;
modelica_integer _outIdCount;
modelica_metatype out_outIdCount;
tmp1 = mmc_unbox_integer(_inAccumCount);
_outIdCount = omc_ComponentReference_identifierCount__tail(threadData, _inCref, tmp1);
out_outIdCount = mmc_mk_icon(_outIdCount);
return out_outIdCount;
}
DLLExport
modelica_integer omc_ComponentReference_identifierCount(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_integer _outIdCount;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIdCount = omc_ComponentReference_identifierCount__tail(threadData, _inCref, ((modelica_integer) 0));
_return: OMC_LABEL_UNUSED
return _outIdCount;
}
modelica_metatype boxptr_ComponentReference_identifierCount(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_integer _outIdCount;
modelica_metatype out_outIdCount;
_outIdCount = omc_ComponentReference_identifierCount(threadData, _inCref);
out_outIdCount = mmc_mk_icon(_outIdCount);
return out_outIdCount;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_implode__tail(threadData_t *threadData, modelica_metatype _inParts, modelica_metatype _inAccumCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inParts;
{
modelica_string _id = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _cr = NULL;
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
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_id = tmpMeta8;
_ty = tmpMeta9;
_subs = tmpMeta10;
_rest = tmpMeta7;
tmpMeta11 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _id, _ty, _subs, _inAccumCref);
_cr = tmpMeta11;
_inParts = _rest;
_inAccumCref = _cr;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _inAccumCref;
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_implode__reverse(threadData_t *threadData, modelica_metatype _inParts)
{
modelica_metatype _outCref = NULL;
modelica_metatype _first = NULL;
modelica_metatype _rest = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inParts;
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
_first = tmpMeta2;
_rest = tmpMeta3;
_outCref = omc_ComponentReference_implode__tail(threadData, _rest, _first);
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_implode(threadData_t *threadData, modelica_metatype _inParts)
{
modelica_metatype _outCref = NULL;
modelica_metatype _first = NULL;
modelica_metatype _rest = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCref = omc_ComponentReference_implode__reverse(threadData, listReverse(_inParts));
_return: OMC_LABEL_UNUSED
return _outCref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_explode__tail(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inParts)
{
modelica_metatype _outParts = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_metatype _first_cr = NULL;
modelica_metatype _rest_cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_rest_cr = tmpMeta6;
_first_cr = omc_ComponentReference_crefFirstCref(threadData, _inCref);
tmpMeta7 = mmc_mk_cons(_first_cr, _inParts);
_inCref = _rest_cr;
_inParts = tmpMeta7;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
tmpMeta8 = mmc_mk_cons(_inCref, _inParts);
tmpMeta1 = tmpMeta8;
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
_outParts = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outParts;
}
DLLExport
modelica_metatype omc_ComponentReference_explode(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outParts = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outParts = listReverse(omc_ComponentReference_explode__tail(threadData, _inCref, tmpMeta1));
_return: OMC_LABEL_UNUSED
return _outParts;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_expandArrayCref1(threadData_t *threadData, modelica_metatype _inCr, modelica_metatype _inSubscripts, modelica_metatype _inAccumSubs, modelica_metatype _inAccumCrefs)
{
modelica_metatype _outCrefs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSubscripts;
{
modelica_metatype _sub = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _rest_subs = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype _cref = NULL;
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
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta6);
tmpMeta9 = MMC_CDR(tmpMeta6);
_sub = tmpMeta8;
_subs = tmpMeta9;
_rest_subs = tmpMeta7;
tmpMeta10 = mmc_mk_cons(_subs, _rest_subs);
_crefs = omc_ComponentReference_expandArrayCref1(threadData, _inCr, tmpMeta10, _inAccumSubs, _inAccumCrefs);
tmpMeta11 = mmc_mk_cons(_sub, _inAccumSubs);
_inSubscripts = _rest_subs;
_inAccumSubs = tmpMeta11;
_inAccumCrefs = _crefs;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_1);
tmpMeta13 = MMC_CDR(tmp4_1);
tmpMeta1 = _inAccumCrefs;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta14;
_cref = omc_ComponentReference_crefSetLastSubs(threadData, _inCr, _inAccumSubs);
tmpMeta14 = mmc_mk_cons(_cref, _inAccumCrefs);
tmpMeta1 = tmpMeta14;
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
_outCrefs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
DLLExport
modelica_metatype omc_ComponentReference_expandArrayCref(threadData_t *threadData, modelica_metatype _inCr, modelica_metatype _inDims)
{
modelica_metatype _outCrefs = NULL;
modelica_metatype _lasttype = NULL;
modelica_metatype _tmpcref = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_lasttype = omc_ComponentReference_crefLastType(threadData, _inCr);
_lasttype = omc_Types_liftTypeWithDims(threadData, _lasttype, _inDims);
_tmpcref = omc_ComponentReference_crefSetLastType(threadData, _inCr, _lasttype);
_outCrefs = omc_ComponentReference_expandCref(threadData, _tmpcref, 0);
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
DLLExport
modelica_metatype omc_ComponentReference_replaceLast(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inNewLast)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _ident = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cref = NULL;
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
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_ident = tmpMeta6;
_ty = tmpMeta7;
_subs = tmpMeta8;
_cref = tmpMeta9;
_cref = omc_ComponentReference_replaceLast(threadData, _cref, _inNewLast);
tmpMeta10 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _ident, _ty, _subs, _cref);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta1 = _inNewLast;
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_makeCrefsFromSubScriptExp(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _op = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_string _str = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _enum_lit = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
_str = omc_ExpressionDump_printExpStr(threadData, _inExp);
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta6 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _str, _OMC_LIT1, tmpMeta5);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 9: {
tmpMeta1 = omc_Expression_expCref(threadData, _inExp);
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta7;
_op = tmpMeta8;
_e2 = tmpMeta9;
_str = omc_ExpressionDump_binopSymbol(threadData, _op);
_cr1 = omc_ComponentReference_makeCrefsFromSubScriptExp(threadData, _e1);
_cr2 = omc_ComponentReference_makeCrefsFromSubScriptExp(threadData, _e2);
_outCref = omc_ComponentReference_prependStringCref(threadData, _str, _cr1);
tmpMeta1 = omc_ComponentReference_joinCrefs(threadData, _outCref, _cr2);
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_enum_lit = tmpMeta10;
_str = omc_System_stringReplace(threadData, omc_AbsynUtil_pathString(threadData, _enum_lit, _OMC_LIT11, 1, 0), _OMC_LIT11, _OMC_LIT20);
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta12 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _str, _OMC_LIT1, tmpMeta11);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
_str = omc_ExpressionDump_dumpExpStr(threadData, _inExp, ((modelica_integer) 0));
tmpMeta13 = stringAppend(_OMC_LIT21,_str);
tmpMeta14 = stringAppend(tmpMeta13,_OMC_LIT22);
omc_Error_addInternalError(threadData, tmpMeta14, _OMC_LIT24);
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_makeCrefsFromSubScriptLst(threadData_t *threadData, modelica_metatype _inSubscriptLst, modelica_metatype _inPreCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta10;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCref = _inPreCref;
{
modelica_metatype _subScript;
for (tmpMeta1 = _inSubscriptLst; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_subScript = MMC_CAR(tmpMeta1);
{
modelica_metatype tmp5_1;
tmp5_1 = _subScript;
{
modelica_metatype _cr = NULL;
modelica_metatype _e = NULL;
modelica_string _str = NULL;
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 2; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,2,1) == 0) goto tmp4_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
_e = tmpMeta7;
_cr = omc_ComponentReference_makeCrefsFromSubScriptExp(threadData, _e);
tmpMeta2 = omc_ComponentReference_joinCrefs(threadData, _outCref, _cr);
goto tmp4_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
_str = omc_ExpressionDump_printSubscriptStr(threadData, _subScript);
tmpMeta8 = stringAppend(_OMC_LIT25,_str);
tmpMeta9 = stringAppend(tmpMeta8,_OMC_LIT22);
omc_Error_addInternalError(threadData, tmpMeta9, _OMC_LIT26);
goto goto_3;
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
_outCref = tmpMeta2;
}
}
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_replaceSubsWithString(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _ident = NULL;
modelica_metatype _identType = NULL;
modelica_metatype _subscriptLst = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _cr1 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_ident = tmpMeta6;
_identType = tmpMeta7;
_cr = tmpMeta9;
_cr1 = omc_ComponentReference_replaceSubsWithString(threadData, _cr);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta11 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _ident, _identType, tmpMeta10, _cr1);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_ident = tmpMeta12;
_identType = tmpMeta13;
_subscriptLst = tmpMeta14;
_cr = tmpMeta15;
_identType = omc_Expression_unliftArrayTypeWithSubs(threadData, _subscriptLst, _identType);
_cr1 = omc_ComponentReference_replaceSubsWithString(threadData, _cr);
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta17 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _ident, _identType, tmpMeta16);
_cr = omc_ComponentReference_makeCrefsFromSubScriptLst(threadData, _subscriptLst, tmpMeta17);
tmpMeta1 = omc_ComponentReference_joinCrefs(threadData, _cr, _cr1);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta18)) goto tmp3_end;
tmpMeta1 = _inCref;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_ident = tmpMeta19;
_identType = tmpMeta20;
_subscriptLst = tmpMeta21;
_identType = omc_Expression_unliftArrayTypeWithSubs(threadData, _subscriptLst, _identType);
tmpMeta22 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta23 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _ident, _identType, tmpMeta22);
tmpMeta1 = omc_ComponentReference_makeCrefsFromSubScriptLst(threadData, _subscriptLst, tmpMeta23);
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
tmpMeta1 = _inCref;
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_expandCref2(threadData_t *threadData, modelica_string _inId, modelica_metatype _inType, modelica_metatype _inSubscripts, modelica_metatype _inDimensions)
{
modelica_metatype _outCrefs = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _subslst = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outCrefs = tmpMeta1;
_subslst = omc_List_threadMap(threadData, _inSubscripts, _inDimensions, boxvar_Expression_expandSubscript);
_subslst = omc_List_combination(threadData, _subslst);
{
modelica_metatype _subs;
for (tmpMeta2 = _subslst; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_subs = MMC_CAR(tmpMeta2);
tmpMeta3 = mmc_mk_cons(omc_ComponentReference_makeCrefIdent(threadData, _inId, _inType, _subs), _outCrefs);
_outCrefs = tmpMeta3;
}
}
_outCrefs = listReverse(_outCrefs);
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_expandCrefQual(threadData_t *threadData, modelica_metatype _inHeadCrefs, modelica_metatype _inRestCrefs)
{
modelica_metatype _outCrefs = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _crefs = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outCrefs = tmpMeta1;
{
modelica_metatype _cref;
for (tmpMeta2 = _inHeadCrefs; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_cref = MMC_CAR(tmpMeta2);
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp4;
modelica_metatype tmpMeta5;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp6;
modelica_metatype _rest_cref_loopVar = 0;
modelica_metatype _rest_cref;
_rest_cref_loopVar = _inRestCrefs;
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta5;
tmp4 = &__omcQ_24tmpVar1;
while(1) {
tmp6 = 1;
if (!listEmpty(_rest_cref_loopVar)) {
_rest_cref = MMC_CAR(_rest_cref_loopVar);
_rest_cref_loopVar = MMC_CDR(_rest_cref_loopVar);
tmp6--;
}
if (tmp6 == 0) {
__omcQ_24tmpVar0 = omc_ComponentReference_joinCrefs(threadData, _cref, _rest_cref);
*tmp4 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp4 = &MMC_CDR(*tmp4);
} else if (tmp6 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp4 = mmc_mk_nil();
tmpMeta3 = __omcQ_24tmpVar1;
}
_crefs = tmpMeta3;
_outCrefs = listAppend(_crefs, _outCrefs);
}
}
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_expandCrefLst(threadData_t *threadData, modelica_metatype _inCrefs, modelica_metatype _varLst, modelica_metatype _inCrefsAcc)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCrefs;
{
modelica_metatype _cr = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = omc_List_flatten(threadData, _inCrefsAcc);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_cr = tmpMeta6;
_rest = tmpMeta7;
_crefs = omc_List_map(threadData, _varLst, boxvar_ComponentReference_creffromVar);
_crefs = omc_List_map1r(threadData, _crefs, boxvar_ComponentReference_joinCrefs, _cr);
tmpMeta8 = mmc_mk_cons(_crefs, _inCrefsAcc);
_inCrefs = _rest;
_inCrefsAcc = tmpMeta8;
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_expandCref__impl(threadData_t *threadData, modelica_metatype _inCref, modelica_boolean _expandRecord)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_boolean tmp4_2;
tmp4_1 = _inCref;
tmp4_2 = _expandRecord;
{
modelica_string _id = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _basety = NULL;
modelica_metatype _correctTy = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype _crefs2 = NULL;
modelica_metatype _varLst = NULL;
modelica_integer _missing_subs;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 8; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (1 != tmp4_2) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,9,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta9)) goto tmp3_end;
_varLst = tmpMeta8;
tmp4 += 6;
_crefs = omc_List_map(threadData, _varLst, boxvar_ComponentReference_creffromVar);
_crefs = omc_List_map1r(threadData, _crefs, boxvar_ComponentReference_joinCrefs, _inCref);
tmpMeta1 = omc_List_map1Flat(threadData, _crefs, boxvar_ComponentReference_expandCref__impl, mmc_mk_boolean(1));
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (1 != tmp4_2) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,6,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta12)) goto tmp3_end;
_id = tmpMeta10;
_ty = tmpMeta11;
tmpMeta14 = omc_Types_flattenArrayType(threadData, _ty, &tmpMeta13);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,9,3) == 0) goto goto_2;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,3,1) == 0) goto goto_2;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 3));
_basety = tmpMeta14;
_varLst = tmpMeta16;
_dims = tmpMeta13;
tmpMeta17 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _basety, _dims);
_correctTy = tmpMeta17;
_subs = omc_List_fill(threadData, _OMC_LIT27, listLength(_dims));
_crefs = omc_ComponentReference_expandCref2(threadData, _id, _correctTy, _subs, _dims);
tmpMeta18 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_expandCrefLst(threadData, _crefs, _varLst, tmpMeta18);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,6,2) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta21)) goto tmp3_end;
_id = tmpMeta19;
_ty = tmpMeta20;
_basety = omc_Types_flattenArrayType(threadData, _ty ,&_dims);
tmpMeta22 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _basety, _dims);
_correctTy = tmpMeta22;
_subs = omc_List_fill(threadData, _OMC_LIT27, listLength(_dims));
tmpMeta1 = omc_ComponentReference_expandCref2(threadData, _id, _correctTy, _subs, _dims);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (1 != tmp4_2) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,6,2) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta23;
_ty = tmpMeta24;
_subs = tmpMeta25;
tmpMeta27 = omc_Types_flattenArrayType(threadData, _ty, &tmpMeta26);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,9,3) == 0) goto goto_2;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,3,1) == 0) goto goto_2;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 3));
_basety = tmpMeta27;
_varLst = tmpMeta29;
_dims = tmpMeta26;
tmpMeta30 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _basety, _dims);
_correctTy = tmpMeta30;
_missing_subs = listLength(_dims) - listLength(_subs);
if((_missing_subs > ((modelica_integer) 0)))
{
_subs = listAppend(_subs, omc_List_fill(threadData, _OMC_LIT27, _missing_subs));
}
_crefs = omc_ComponentReference_expandCref2(threadData, _id, _correctTy, _subs, _dims);
tmpMeta31 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_expandCrefLst(threadData, _crefs, _varLst, tmpMeta31);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta33,6,2) == 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta32;
_ty = tmpMeta33;
_subs = tmpMeta34;
tmp4 += 2;
_basety = omc_Types_flattenArrayType(threadData, _ty ,&_dims);
tmpMeta35 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _basety, _dims);
_correctTy = tmpMeta35;
_missing_subs = listLength(_dims) - listLength(_subs);
if((_missing_subs > ((modelica_integer) 0)))
{
_subs = listAppend(_subs, omc_List_fill(threadData, _OMC_LIT27, _missing_subs));
}
tmpMeta1 = omc_ComponentReference_expandCref2(threadData, _id, _correctTy, _subs, _dims);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta37,6,2) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta36;
_ty = tmpMeta37;
_subs = tmpMeta38;
_cref = tmpMeta39;
_crefs = omc_ComponentReference_expandCref__impl(threadData, _cref, _expandRecord);
_basety = omc_Types_flattenArrayType(threadData, _ty ,&_dims);
tmpMeta40 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _basety, _dims);
_correctTy = tmpMeta40;
tmpMeta41 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _id, _correctTy, _subs);
_cref = tmpMeta41;
_crefs2 = omc_ComponentReference_expandCref__impl(threadData, _cref, 0);
_crefs2 = listReverse(_crefs2);
tmpMeta1 = omc_ComponentReference_expandCrefQual(threadData, _crefs2, _crefs);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta42;
_ty = tmpMeta43;
_subs = tmpMeta44;
_cref = tmpMeta45;
_crefs = omc_ComponentReference_expandCref__impl(threadData, _cref, _expandRecord);
tmpMeta1 = omc_List_map3r(threadData, _crefs, boxvar_ComponentReference_makeCrefQual, _id, _ty, _subs);
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta46;
tmpMeta46 = mmc_mk_cons(_inCref, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta46;
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
if (++tmp4 < 8) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
modelica_metatype boxptr_ComponentReference_expandCref__impl(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _expandRecord)
{
modelica_integer tmp1;
modelica_metatype _outCref = NULL;
tmp1 = mmc_unbox_integer(_expandRecord);
_outCref = omc_ComponentReference_expandCref__impl(threadData, _inCref, tmp1);
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_expandCref(threadData_t *threadData, modelica_metatype _inCref, modelica_boolean _expandRecord)
{
modelica_metatype _outCref = NULL;
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
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta1 = omc_ComponentReference_expandCref__impl(threadData, _inCref, _expandRecord);
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
modelica_metatype tmpMeta7;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT31);
if (1 != tmp6) goto goto_2;
tmpMeta7 = stringAppend(_OMC_LIT32,omc_ComponentReference_printComponentRefStr(threadData, _inCref));
omc_Debug_traceln(threadData, tmpMeta7);
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
if (++tmp4 < 2) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
modelica_metatype boxptr_ComponentReference_expandCref(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _expandRecord)
{
modelica_integer tmp1;
modelica_metatype _outCref = NULL;
tmp1 = mmc_unbox_integer(_expandRecord);
_outCref = omc_ComponentReference_expandCref(threadData, _inCref, tmp1);
return _outCref;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReference_crefDepth1(threadData_t *threadData, modelica_metatype _inCref, modelica_integer _iDepth)
{
modelica_integer _depth;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_metatype _n = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 6: {
tmp1 = _iDepth;
goto tmp3_done;
}
case 4: {
tmp1 = ((modelica_integer) 1) + _iDepth;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_n = tmpMeta5;
_inCref = _n;
_iDepth = ((modelica_integer) 1) + _iDepth;
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
_depth = tmp1;
_return: OMC_LABEL_UNUSED
return _depth;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_crefDepth1(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _iDepth)
{
modelica_integer tmp1;
modelica_integer _depth;
modelica_metatype out_depth;
tmp1 = mmc_unbox_integer(_iDepth);
_depth = omc_ComponentReference_crefDepth1(threadData, _inCref, tmp1);
out_depth = mmc_mk_icon(_depth);
return out_depth;
}
DLLExport
modelica_integer omc_ComponentReference_crefDepth(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_integer _depth;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_metatype _n = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 6: {
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 4: {
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_n = tmpMeta5;
tmp1 = omc_ComponentReference_crefDepth1(threadData, _n, ((modelica_integer) 1));
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
_depth = tmp1;
_return: OMC_LABEL_UNUSED
return _depth;
}
modelica_metatype boxptr_ComponentReference_crefDepth(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_integer _depth;
modelica_metatype out_depth;
_depth = omc_ComponentReference_crefDepth(threadData, _inCref);
out_depth = mmc_mk_icon(_depth);
return out_depth;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_toStringList__tail(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inAccumStrings)
{
modelica_metatype _outStringList = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _id = NULL;
modelica_metatype _cref = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta5;
_cref = tmpMeta6;
tmpMeta7 = mmc_mk_cons(_id, _inAccumStrings);
_inCref = _cref;
_inAccumStrings = tmpMeta7;
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_id = tmpMeta8;
tmpMeta9 = mmc_mk_cons(_id, _inAccumStrings);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta10;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta10;
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
_outStringList = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStringList;
}
DLLExport
modelica_metatype omc_ComponentReference_toStringList(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outStringList = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outStringList = listReverseInPlace(omc_ComponentReference_toStringList__tail(threadData, _inCref, tmpMeta1));
_return: OMC_LABEL_UNUSED
return _outStringList;
}
DLLExport
modelica_metatype omc_ComponentReference_splitCrefFirst(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype *out_outCrefRest)
{
modelica_metatype _outCrefFirst = NULL;
modelica_metatype _outCrefRest = NULL;
modelica_string _id = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _subs = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inCref;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,0,4) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
_id = tmpMeta2;
_ty = tmpMeta3;
_subs = tmpMeta4;
_outCrefRest = tmpMeta5;
tmpMeta6 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _id, _ty, _subs);
_outCrefFirst = tmpMeta6;
_return: OMC_LABEL_UNUSED
if (out_outCrefRest) { *out_outCrefRest = _outCrefRest; }
return _outCrefFirst;
}
DLLExport
modelica_metatype omc_ComponentReference_firstNCrefs(threadData_t *threadData, modelica_metatype _inCref, modelica_integer _nIn)
{
modelica_metatype _outFirstCrefs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_integer tmp4_2;
tmp4_1 = _inCref;
tmp4_2 = _nIn;
{
modelica_string _id = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _prefix = NULL;
modelica_metatype _last = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (0 != tmp4_2) goto tmp3_end;
tmp4 += 1;
tmpMeta1 = _inCref;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (1 != tmp4_2) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta6;
_ty = tmpMeta7;
_subs = tmpMeta8;
tmp4 += 1;
tmpMeta9 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _id, _ty, _subs);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmp4 += 1;
tmpMeta1 = _inCref;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta10;
_ty = tmpMeta11;
_subs = tmpMeta12;
_last = tmpMeta13;
_prefix = omc_ComponentReference_firstNCrefs(threadData, _last, ((modelica_integer) -1) + _nIn);
tmpMeta14 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _id, _ty, _subs, _prefix);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 4: {
tmpMeta1 = _inCref;
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
_outFirstCrefs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outFirstCrefs;
}
modelica_metatype boxptr_ComponentReference_firstNCrefs(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _nIn)
{
modelica_integer tmp1;
modelica_metatype _outFirstCrefs = NULL;
tmp1 = mmc_unbox_integer(_nIn);
_outFirstCrefs = omc_ComponentReference_firstNCrefs(threadData, _inCref, tmp1);
return _outFirstCrefs;
}
DLLExport
modelica_metatype omc_ComponentReference_splitCrefLast(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype *out_outLastCref)
{
modelica_metatype _outPrefixCref = NULL;
modelica_metatype _outLastCref = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _id = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _prefix = NULL;
modelica_metatype _last = NULL;
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
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,3) == 0) goto tmp3_end;
_id = tmpMeta6;
_ty = tmpMeta7;
_subs = tmpMeta8;
_last = tmpMeta9;
tmpMeta10 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _id, _ty, _subs);
tmpMeta[0+0] = tmpMeta10;
tmpMeta[0+1] = _last;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta11;
_ty = tmpMeta12;
_subs = tmpMeta13;
_last = tmpMeta14;
_prefix = omc_ComponentReference_splitCrefLast(threadData, _last ,&_last);
tmpMeta15 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _id, _ty, _subs, _prefix);
tmpMeta[0+0] = tmpMeta15;
tmpMeta[0+1] = _last;
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
_outPrefixCref = tmpMeta[0+0];
_outLastCref = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outLastCref) { *out_outLastCref = _outLastCref; }
return _outPrefixCref;
}
DLLExport
modelica_metatype omc_ComponentReference_replaceWholeDimSubscript2(threadData_t *threadData, modelica_metatype _isubs, modelica_integer _index)
{
modelica_metatype _osubs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _isubs;
{
modelica_metatype _sub = NULL;
modelica_metatype _subs = NULL;
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
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,0) == 0) goto tmp3_end;
_subs = tmpMeta7;
tmpMeta8 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_index));
tmpMeta9 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta8);
_sub = tmpMeta9;
tmpMeta10 = mmc_mk_cons(_sub, _subs);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmp4_1);
tmpMeta12 = MMC_CDR(tmp4_1);
_sub = tmpMeta11;
_subs = tmpMeta12;
_subs = omc_ComponentReference_replaceWholeDimSubscript2(threadData, _subs, _index);
tmpMeta13 = mmc_mk_cons(_sub, _subs);
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
_osubs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _osubs;
}
modelica_metatype boxptr_ComponentReference_replaceWholeDimSubscript2(threadData_t *threadData, modelica_metatype _isubs, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_metatype _osubs = NULL;
tmp1 = mmc_unbox_integer(_index);
_osubs = omc_ComponentReference_replaceWholeDimSubscript2(threadData, _isubs, tmp1);
return _osubs;
}
DLLExport
modelica_metatype omc_ComponentReference_replaceWholeDimSubscript(threadData_t *threadData, modelica_metatype _icr, modelica_integer _index)
{
modelica_metatype _ocr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _icr;
{
modelica_string _id = NULL;
modelica_metatype _et = NULL;
modelica_metatype _ss = NULL;
modelica_metatype _cr = NULL;
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
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta6;
_et = tmpMeta7;
_ss = tmpMeta8;
_cr = tmpMeta9;
_ss = omc_ComponentReference_replaceWholeDimSubscript2(threadData, _ss, _index);
tmpMeta10 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _id, _et, _ss, _cr);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta11;
_et = tmpMeta12;
_ss = tmpMeta13;
_cr = tmpMeta14;
tmp4 += 1;
_cr = omc_ComponentReference_replaceWholeDimSubscript(threadData, _cr, _index);
tmpMeta15 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _id, _et, _ss, _cr);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta16;
_et = tmpMeta17;
_ss = tmpMeta18;
_ss = omc_ComponentReference_replaceWholeDimSubscript2(threadData, _ss, _index);
tmpMeta19 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _id, _et, _ss);
tmpMeta1 = tmpMeta19;
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
_ocr = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _ocr;
}
modelica_metatype boxptr_ComponentReference_replaceWholeDimSubscript(threadData_t *threadData, modelica_metatype _icr, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_metatype _ocr = NULL;
tmp1 = mmc_unbox_integer(_index);
_ocr = omc_ComponentReference_replaceWholeDimSubscript(threadData, _icr, tmp1);
return _ocr;
}
DLLExport
void omc_ComponentReference_printComponentRefList(threadData_t *threadData, modelica_metatype _crs)
{
modelica_string _buffer = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_OMC_LIT33,stringDelimitList(omc_List_map(threadData, _crs, boxvar_ComponentReference_printComponentRefStr), _OMC_LIT34));
tmpMeta2 = stringAppend(tmpMeta1,_OMC_LIT35);
_buffer = tmpMeta2;
fputs(MMC_STRINGDATA(_buffer),stdout);
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_string omc_ComponentReference_printComponentRefListStr(threadData_t *threadData, modelica_metatype _crs)
{
modelica_string _res = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_OMC_LIT33,stringDelimitList(omc_List_map(threadData, _crs, boxvar_ComponentReference_printComponentRefStr), _OMC_LIT4));
tmpMeta2 = stringAppend(tmpMeta1,_OMC_LIT36);
_res = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC void omc_ComponentReference_printComponentRef2(threadData_t *threadData, modelica_string _inString, modelica_metatype _inSubscriptLst)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_string tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inString;
tmp3_2 = _inSubscriptLst;
{
modelica_string _s = NULL;
modelica_metatype _l = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
_s = tmp3_1;
omc_Print_printBuf(threadData, _s);
goto tmp2_done;
}
case 1: {
_s = tmp3_1;
_l = tmp3_2;
if(omc_Config_modelicaOutput(threadData))
{
omc_Print_printBuf(threadData, _s);
omc_Print_printBuf(threadData, _OMC_LIT37);
omc_ExpressionDump_printList(threadData, _l, boxvar_ExpressionDump_printSubscript, _OMC_LIT4);
omc_Print_printBuf(threadData, _OMC_LIT38);
}
else
{
omc_Print_printBuf(threadData, _s);
omc_Print_printBuf(threadData, _OMC_LIT3);
omc_ExpressionDump_printList(threadData, _l, boxvar_ExpressionDump_printSubscript, _OMC_LIT4);
omc_Print_printBuf(threadData, _OMC_LIT7);
}
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
;
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_ComponentReference_printComponentRef(threadData_t *threadData, modelica_metatype _inComponentRef)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inComponentRef;
{
modelica_string _s = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 6: {
omc_Print_printBuf(threadData, _OMC_LIT39);
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_s = tmpMeta4;
_subs = tmpMeta5;
omc_ComponentReference_printComponentRef2(threadData, _s, _subs);
goto tmp2_done;
}
case 3: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_s = tmpMeta6;
_subs = tmpMeta7;
_cr = tmpMeta8;
if(omc_Config_modelicaOutput(threadData))
{
omc_ComponentReference_printComponentRef2(threadData, _s, _subs);
omc_Print_printBuf(threadData, _OMC_LIT40);
omc_ComponentReference_printComponentRef(threadData, _cr);
}
else
{
omc_ComponentReference_printComponentRef2(threadData, _s, _subs);
omc_Print_printBuf(threadData, _OMC_LIT11);
omc_ComponentReference_printComponentRef(threadData, _cr);
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
DLLExport
modelica_metatype omc_ComponentReference_stringifyComponentRef(threadData_t *threadData, modelica_metatype _cr)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr_1 = NULL;
modelica_string _crs = NULL;
modelica_metatype _ty = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_subs = omc_ComponentReference_crefLastSubs(threadData, _cr);
_cr_1 = omc_ComponentReference_crefStripLastSubs(threadData, _cr);
_crs = omc_ComponentReference_printComponentRefStr(threadData, _cr_1);
_ty = omc_ComponentReference_crefLastType(threadData, _cr);
_outComponentRef = omc_ComponentReference_makeCrefIdent(threadData, _crs, _ty, _subs);
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_crefStripLastSubsStringified(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _lst = NULL;
modelica_metatype _lst_1 = NULL;
modelica_string _id_1 = NULL;
modelica_string _id = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _t2 = NULL;
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
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta8)) goto tmp3_end;
_id = tmpMeta6;
_t2 = tmpMeta7;
_lst = omc_Util_stringSplitAtChar(threadData, _id, _OMC_LIT3);
_lst_1 = omc_List_stripLast(threadData, _lst);
_id_1 = stringDelimitList(_lst_1, _OMC_LIT3);
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _id_1, _t2, tmpMeta9);
goto tmp3_done;
}
case 1: {
_cr = tmp4_1;
tmpMeta1 = _cr;
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_crefStripFirstIdent(threadData_t *threadData, modelica_metatype _inCr)
{
modelica_metatype _outCr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCr;
{
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta6;
tmpMeta1 = _cr;
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
_outCr = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCr;
}
DLLExport
modelica_metatype omc_ComponentReference_crefStripIterSub(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_string _iter)
{
modelica_metatype _outComponentRef = NULL;
modelica_string _ident = NULL;
modelica_string _index = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
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
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_boolean tmp15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,2,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,6,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,1,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
_ident = tmpMeta6;
_ty = tmpMeta7;
_subs = tmpMeta8;
_index = tmpMeta13;
tmp15 = (modelica_boolean)((stringEqual(_OMC_LIT41, _iter)) || (stringEqual(_index, _iter)));
if(tmp15)
{
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta16 = tmpMeta14;
}
else
{
tmpMeta16 = _subs;
}
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _ident, _ty, tmpMeta16);
goto tmp3_done;
}
case 1: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta19)) goto tmp3_end;
tmpMeta20 = MMC_CAR(tmpMeta19);
tmpMeta21 = MMC_CDR(tmpMeta19);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,2,1) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,6,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,1,3) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
if (!listEmpty(tmpMeta21)) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_ident = tmpMeta17;
_ty = tmpMeta18;
_subs = tmpMeta19;
_index = tmpMeta24;
_cref = tmpMeta25;
if(((stringEqual(_OMC_LIT41, _iter)) || (stringEqual(_index, _iter))))
{
tmpMeta26 = MMC_REFSTRUCTLIT(mmc_nil);
_subs = tmpMeta26;
}
else
{
_cref = omc_ComponentReference_crefStripIterSub(threadData, _cref, _iter);
}
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _ident, _ty, _subs, _cref);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_ident = tmpMeta27;
_ty = tmpMeta28;
_subs = tmpMeta29;
_cref = tmpMeta30;
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _ident, _ty, _subs, omc_ComponentReference_crefStripIterSub(threadData, _cref, _iter));
goto tmp3_done;
}
case 3: {
tmpMeta1 = _inComponentRef;
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_crefStripLastSubs(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _id = NULL;
modelica_metatype _s = NULL;
modelica_metatype _cr_1 = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _t2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_id = tmpMeta6;
_t2 = tmpMeta7;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _id, _t2, tmpMeta8);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta9;
_t2 = tmpMeta10;
_s = tmpMeta11;
_cr = tmpMeta12;
_cr_1 = omc_ComponentReference_crefStripLastSubs(threadData, _cr);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _t2, _s, _cr_1);
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_crefStripLastIdent(threadData_t *threadData, modelica_metatype _inCr)
{
modelica_metatype _outCr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inCr;
{
modelica_string _id = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _t2 = NULL;
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
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,3) == 0) goto tmp3_end;
_id = tmpMeta6;
_t2 = tmpMeta7;
_subs = tmpMeta8;
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _id, _t2, _subs);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta10;
_t2 = tmpMeta11;
_subs = tmpMeta12;
_cr = tmpMeta13;
_cr1 = omc_ComponentReference_crefStripLastIdent(threadData, _cr);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _t2, _subs, _cr1);
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
_outCr = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCr;
}
DLLExport
modelica_metatype omc_ComponentReference_crefStripPrefix(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _prefix)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cref;
tmp4_2 = _prefix;
{
modelica_metatype _subs1 = NULL;
modelica_metatype _subs2 = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
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
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_id1 = tmpMeta6;
_subs1 = tmpMeta7;
_cr1 = tmpMeta8;
_id2 = tmpMeta9;
_subs2 = tmpMeta10;
tmp11 = (stringEqual(_id1, _id2));
if (1 != tmp11) goto goto_2;
tmp12 = omc_Expression_subscriptEqual(threadData, _subs1, _subs2);
if (1 != tmp12) goto goto_2;
tmpMeta1 = _cr1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_boolean tmp19;
modelica_boolean tmp20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
_id1 = tmpMeta13;
_subs1 = tmpMeta14;
_cr1 = tmpMeta15;
_id2 = tmpMeta16;
_subs2 = tmpMeta17;
_cr2 = tmpMeta18;
tmp19 = (stringEqual(_id1, _id2));
if (1 != tmp19) goto goto_2;
tmp20 = omc_Expression_subscriptEqual(threadData, _subs1, _subs2);
if (1 != tmp20) goto goto_2;
_cref = _cr1;
_prefix = _cr2;
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReference_crefStripSubsExceptModelSubs_is__model__array(threadData_t *threadData, modelica_metatype _ty)
{
modelica_boolean _res;
modelica_metatype _state = NULL;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ty;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_boolean tmp8 = 0;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,9,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_state = tmpMeta7;
{
modelica_metatype tmp11_1;
tmp11_1 = _state;
{
int tmp11;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp11_1))) {
case 5: {
tmp8 = 1;
goto tmp10_done;
}
case 7: {
tmp8 = 1;
goto tmp10_done;
}
default:
tmp10_default: OMC_LABEL_UNUSED; {
tmp8 = 0;
goto tmp10_done;
}
}
goto tmp10_end;
tmp10_end: ;
}
goto goto_9;
goto_9:;
goto goto_2;
goto tmp10_done;
tmp10_done:;
}
}tmp1 = tmp8;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_crefStripSubsExceptModelSubs_is__model__array(threadData_t *threadData, modelica_metatype _ty)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_ComponentReference_crefStripSubsExceptModelSubs_is__model__array(threadData, _ty);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_metatype omc_ComponentReference_crefStripSubsExceptModelSubs(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _id = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (!omc_ComponentReference_crefStripSubsExceptModelSubs_is__model__array(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 3))))) goto tmp3_end;
tmpMeta1 = _inCref;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cref = tmp4_1;
_cr = tmpMeta6;
if (!omc_ComponentReference_crefStripSubsExceptModelSubs_is__model__array(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 3))))) goto tmp3_end;
_outCref = omc_ComponentReference_crefStripSubsExceptModelSubs(threadData, _cr);
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_cref), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[5] = _outCref;
_cref = tmpMeta7;
tmpMeta1 = _cref;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_id = tmpMeta8;
_ty = tmpMeta9;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _id, _ty, tmpMeta10);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta11;
_ty = tmpMeta12;
_cr = tmpMeta13;
_outCref = omc_ComponentReference_crefStripSubsExceptModelSubs(threadData, _cr);
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _ty, tmpMeta14, _outCref);
goto tmp3_done;
}
case 4: {
tmpMeta1 = _inCref;
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_crefStripSubs(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _id = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_id = tmpMeta6;
_ty = tmpMeta7;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _id, _ty, tmpMeta8);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta9;
_ty = tmpMeta10;
_cr = tmpMeta11;
_outCref = omc_ComponentReference_crefStripSubs(threadData, _cr);
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _ty, tmpMeta12, _outCref);
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_removeSliceSubs(threadData_t *threadData, modelica_metatype _subs)
{
modelica_metatype _osubs = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_osubs = tmpMeta1;
{
modelica_metatype _s;
for (tmpMeta2 = _subs; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_s = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp6_1;
tmp6_1 = _s;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,1,1) == 0) goto tmp5_end;
tmpMeta3 = _osubs;
goto tmp5_done;
}
case 1: {
modelica_metatype tmpMeta8;
tmpMeta8 = mmc_mk_cons(_s, _osubs);
tmpMeta3 = tmpMeta8;
goto tmp5_done;
}
}
goto tmp5_end;
tmp5_end: ;
}
goto goto_4;
goto_4:;
MMC_THROW_INTERNAL();
goto tmp5_done;
tmp5_done:;
}
}
_osubs = tmpMeta3;
}
}
_osubs = listReverseInPlace(_osubs);
_return: OMC_LABEL_UNUSED
return _osubs;
}
DLLExport
modelica_metatype omc_ComponentReference_stripArrayCref(threadData_t *threadData, modelica_metatype _crefIn, modelica_integer *out_idxOut, modelica_metatype *out_crefTail)
{
modelica_metatype _crefHead = NULL;
modelica_integer _idxOut;
modelica_metatype _crefTail = NULL;
modelica_integer tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _crefIn;
{
modelica_integer _idx;
modelica_string _id = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _outCref = NULL;
modelica_metatype _ty = NULL;
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
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_integer tmp13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,2,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmp13 = mmc_unbox_integer(tmpMeta12);
if (!listEmpty(tmpMeta10)) goto tmp3_end;
_id = tmpMeta6;
_ty = tmpMeta7;
_idx = tmp13;
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = omc_ComponentReference_makeCrefIdent(threadData, _id, _ty, tmpMeta14);
tmp1_c1 = _idx;
tmpMeta[0+2] = mmc_mk_none();
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_integer tmp22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmpMeta17);
tmpMeta19 = MMC_CDR(tmpMeta17);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,2,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,0,1) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
tmp22 = mmc_unbox_integer(tmpMeta21);
if (!listEmpty(tmpMeta19)) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta15;
_ty = tmpMeta16;
_idx = tmp22;
_cr = tmpMeta23;
tmpMeta24 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = omc_ComponentReference_makeCrefIdent(threadData, _id, _ty, tmpMeta24);
tmp1_c1 = _idx;
tmpMeta[0+2] = mmc_mk_some(_cr);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta25;
_ty = tmpMeta26;
_cr = tmpMeta27;
_outCref = omc_ComponentReference_stripCrefIdentSliceSubs(threadData, _cr);
tmpMeta28 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = omc_ComponentReference_makeCrefQual(threadData, _id, _ty, tmpMeta28, _outCref);
tmp1_c1 = ((modelica_integer) -1);
tmpMeta[0+2] = mmc_mk_none();
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
_crefHead = tmpMeta[0+0];
_idxOut = tmp1_c1;
_crefTail = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_idxOut) { *out_idxOut = _idxOut; }
if (out_crefTail) { *out_crefTail = _crefTail; }
return _crefHead;
}
modelica_metatype boxptr_ComponentReference_stripArrayCref(threadData_t *threadData, modelica_metatype _crefIn, modelica_metatype *out_idxOut, modelica_metatype *out_crefTail)
{
modelica_integer _idxOut;
modelica_metatype _crefHead = NULL;
_crefHead = omc_ComponentReference_stripArrayCref(threadData, _crefIn, &_idxOut, out_crefTail);
if (out_idxOut) { *out_idxOut = mmc_mk_icon(_idxOut); }
return _crefHead;
}
DLLExport
modelica_metatype omc_ComponentReference_stripCrefIdentSliceSubs(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _id = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _subs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta6;
_ty = tmpMeta7;
_subs = tmpMeta8;
_subs = omc_ComponentReference_removeSliceSubs(threadData, _subs);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _id, _ty, _subs);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta9;
_ty = tmpMeta10;
_subs = tmpMeta11;
_cr = tmpMeta12;
_outCref = omc_ComponentReference_stripCrefIdentSliceSubs(threadData, _cr);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _ty, _subs, _outCref);
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_replaceSliceSub(threadData_t *threadData, modelica_metatype _inSubs, modelica_metatype _inSub)
{
modelica_metatype _osubs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inSubs;
{
modelica_metatype _subs = NULL;
modelica_metatype _sub = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
_subs = tmpMeta7;
tmp4 += 1;
tmpMeta1 = listAppend(_inSub, _subs);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,0) == 0) goto tmp3_end;
_subs = tmpMeta9;
tmpMeta1 = listAppend(_inSub, _subs);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_sub = tmpMeta10;
_subs = tmpMeta11;
_subs = omc_ComponentReference_replaceSliceSub(threadData, _subs, _inSub);
tmpMeta12 = mmc_mk_cons(_sub, _subs);
tmpMeta1 = tmpMeta12;
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
_osubs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _osubs;
}
DLLExport
modelica_metatype omc_ComponentReference_replaceCrefSliceSub(threadData_t *threadData, modelica_metatype _inCr, modelica_metatype _newSub)
{
modelica_metatype _outCr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inCr;
{
modelica_metatype _t2 = NULL;
modelica_metatype _identType = NULL;
modelica_metatype _child = NULL;
modelica_metatype _subs = NULL;
modelica_string _name = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_name = tmpMeta6;
_identType = tmpMeta7;
_subs = tmpMeta8;
_subs = omc_ComponentReference_replaceSliceSub(threadData, _subs, _newSub);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _name, _identType, _subs);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_t2 = tmpMeta9;
_subs = tmpMeta10;
tmp11 = (listLength(omc_Expression_arrayTypeDimensions(threadData, _t2)) >= ((modelica_integer) 1) + listLength(_subs));
if (1 != tmp11) goto goto_2;
tmpMeta1 = omc_ComponentReference_subscriptCref(threadData, _inCr, _newSub);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_boolean tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_t2 = tmpMeta12;
_subs = tmpMeta13;
tmp4 += 3;
tmp14 = (listLength(omc_Expression_arrayTypeDimensions(threadData, _t2)) >= listLength(_subs) + listLength(_newSub));
if (0 != tmp14) goto goto_2;
_child = omc_ComponentReference_subscriptCref(threadData, _inCr, _newSub);
if(omc_Flags_isSet(threadData, _OMC_LIT31))
{
omc_Debug_trace(threadData, _OMC_LIT42);
}
tmpMeta1 = _child;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_name = tmpMeta15;
_identType = tmpMeta16;
_subs = tmpMeta17;
_child = tmpMeta18;
_subs = omc_ComponentReference_replaceSliceSub(threadData, _subs, _newSub);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _name, _identType, _subs, _child);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_boolean tmp23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_name = tmpMeta19;
_identType = tmpMeta20;
_subs = tmpMeta21;
_child = tmpMeta22;
tmp23 = (listLength(omc_Expression_arrayTypeDimensions(threadData, _identType)) >= ((modelica_integer) 1) + listLength(_subs));
if (1 != tmp23) goto goto_2;
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _name, _identType, listAppend(_subs, _newSub), _child);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_name = tmpMeta24;
_identType = tmpMeta25;
_subs = tmpMeta26;
_child = tmpMeta27;
_child = omc_ComponentReference_replaceCrefSliceSub(threadData, _child, _newSub);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _name, _identType, _subs, _child);
goto tmp3_done;
}
case 6: {
modelica_boolean tmp28;
tmp28 = omc_Flags_isSet(threadData, _OMC_LIT31);
if (1 != tmp28) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT43);
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
_outCr = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCr;
}
DLLExport
modelica_metatype omc_ComponentReference_crefSetLastType(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _newType)
{
modelica_metatype _outRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRef;
{
modelica_metatype _ty = NULL;
modelica_metatype _child = NULL;
modelica_metatype _subs = NULL;
modelica_string _id = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta6;
_subs = tmpMeta7;
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _id, _newType, _subs);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta8;
_ty = tmpMeta9;
_subs = tmpMeta10;
_child = tmpMeta11;
_child = omc_ComponentReference_crefSetLastType(threadData, _child, _newType);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _ty, _subs, _child);
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
_outRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRef;
}
DLLExport
modelica_metatype omc_ComponentReference_crefSetType(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcref, modelica_metatype _ty)
{
modelica_metatype _cref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref = __omcQ_24in_5Fcref;
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_cref), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[3] = _ty;
_cref = tmpMeta5;
tmpMeta1 = _cref;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_cref), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[3] = _ty;
_cref = tmpMeta6;
tmpMeta1 = _cref;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta7;
tmpMeta7 = stringAppend(_OMC_LIT44,omc_ComponentReference_crefStr(threadData, _cref));
omc_Error_addInternalError(threadData, tmpMeta7, _OMC_LIT45);
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
_cref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _cref;
}
DLLExport
modelica_metatype omc_ComponentReference_crefApplySubs(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inSubs)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _id = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,6,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta6;
_tp = tmpMeta7;
_subs = tmpMeta8;
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _id, _tp, listAppend(_subs, _inSubs));
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,6,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta9;
_tp = tmpMeta10;
_subs = tmpMeta11;
_cr = tmpMeta12;
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _tp, listAppend(_subs, _inSubs), _cr);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta13;
_tp = tmpMeta14;
_subs = tmpMeta15;
_cr = tmpMeta16;
_cr = omc_ComponentReference_crefApplySubs(threadData, _cr, _inSubs);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _tp, _subs, _cr);
goto tmp3_done;
}
case 3: {
omc_Error_addInternalError(threadData, _OMC_LIT46, _OMC_LIT47);
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_crefSetLastSubs(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inSubs)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _id = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_id = tmpMeta6;
_tp = tmpMeta7;
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _id, _tp, _inSubs);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta8;
_tp = tmpMeta9;
_subs = tmpMeta10;
_cr = tmpMeta11;
_cr = omc_ComponentReference_crefSetLastSubs(threadData, _cr, _inSubs);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _tp, _subs, _cr);
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_subscriptCrefWithInt(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_integer _inSubscript)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _subs = NULL;
modelica_metatype _new_sub = NULL;
modelica_string _id = NULL;
modelica_metatype _rest_cref = NULL;
modelica_metatype _ty = NULL;
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
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta6;
_ty = tmpMeta7;
_subs = tmpMeta8;
tmpMeta9 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_inSubscript));
tmpMeta10 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, tmpMeta9);
_new_sub = tmpMeta10;
_subs = omc_List_appendElt(threadData, _new_sub, _subs);
_ty = omc_Expression_unliftArray(threadData, _ty);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _id, _ty, _subs);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta11;
_ty = tmpMeta12;
_subs = tmpMeta13;
_rest_cref = tmpMeta14;
_rest_cref = omc_ComponentReference_subscriptCrefWithInt(threadData, _rest_cref, _inSubscript);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _ty, _subs, _rest_cref);
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
modelica_metatype boxptr_ComponentReference_subscriptCrefWithInt(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inSubscript)
{
modelica_integer tmp1;
modelica_metatype _outComponentRef = NULL;
tmp1 = mmc_unbox_integer(_inSubscript);
_outComponentRef = omc_ComponentReference_subscriptCrefWithInt(threadData, _inComponentRef, tmp1);
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_subscriptCref(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inSubscriptLst)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inComponentRef;
tmp4_2 = _inSubscriptLst;
{
modelica_metatype _newsub_1 = NULL;
modelica_metatype _sub = NULL;
modelica_metatype _newsub = NULL;
modelica_string _id = NULL;
modelica_metatype _cref_1 = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _t2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta6;
_t2 = tmpMeta7;
_sub = tmpMeta8;
_newsub = tmp4_2;
_newsub_1 = listAppend(_sub, _newsub);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _id, _t2, _newsub_1);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta9;
_t2 = tmpMeta10;
_sub = tmpMeta11;
_cref = tmpMeta12;
_newsub = tmp4_2;
_cref_1 = omc_ComponentReference_subscriptCref(threadData, _cref, _newsub);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _t2, _sub, _cref_1);
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_joinCrefsExp(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5Fcref, modelica_metatype *out_cref)
{
modelica_metatype _exp = NULL;
modelica_metatype _cref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
_cref = __omcQ_24in_5Fcref;
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
modelica_metatype _cr = NULL;
modelica_metatype _tp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cr = tmpMeta6;
_tp = tmpMeta7;
_cr = omc_ComponentReference_joinCrefs(threadData, _cref, _cr);
tmpMeta8 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _cr, _tp);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _exp;
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
_exp = tmpMeta1;
_return: OMC_LABEL_UNUSED
if (out_cref) { *out_cref = _cref; }
return _exp;
}
DLLExport
modelica_metatype omc_ComponentReference_joinCrefsR(threadData_t *threadData, modelica_metatype _inComponentRef2, modelica_metatype _inComponentRef1)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inComponentRef2;
tmp4_2 = _inComponentRef1;
{
modelica_string _id = NULL;
modelica_metatype _sub = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _cr_1 = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _t2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_id = tmpMeta6;
_t2 = tmpMeta7;
_sub = tmpMeta8;
_cr2 = tmp4_1;
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _t2, _sub, _cr2);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
_id = tmpMeta9;
_t2 = tmpMeta10;
_sub = tmpMeta11;
_cr = tmpMeta12;
_cr2 = tmp4_1;
_cr_1 = omc_ComponentReference_joinCrefs(threadData, _cr, _cr2);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _t2, _sub, _cr_1);
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_joinCrefs(threadData_t *threadData, modelica_metatype _inComponentRef1, modelica_metatype _inComponentRef2)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inComponentRef1;
tmp4_2 = _inComponentRef2;
{
modelica_string _id = NULL;
modelica_metatype _sub = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _cr_1 = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _t2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta6;
_t2 = tmpMeta7;
_sub = tmpMeta8;
_cr2 = tmp4_2;
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _t2, _sub, _cr2);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta9;
_t2 = tmpMeta10;
_sub = tmpMeta11;
_cr = tmpMeta12;
_cr2 = tmp4_2;
_cr_1 = omc_ComponentReference_joinCrefs(threadData, _cr, _cr2);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id, _t2, _sub, _cr_1);
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_appendStringLastIdent(threadData_t *threadData, modelica_string _inString, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _id = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _ty = NULL;
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
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta6;
_ty = tmpMeta7;
_subs = tmpMeta8;
_cr = tmpMeta9;
_cr = omc_ComponentReference_appendStringLastIdent(threadData, _inString, _cr);
tmpMeta10 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _id, _ty, _subs, _cr);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta11;
_ty = tmpMeta12;
_subs = tmpMeta13;
tmpMeta14 = stringAppend(_id,_inString);
_id = tmpMeta14;
tmpMeta15 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _id, _ty, _subs);
tmpMeta1 = tmpMeta15;
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_appendStringFirstIdent(threadData_t *threadData, modelica_string _inString, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _id = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _ty = NULL;
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
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta6;
_ty = tmpMeta7;
_subs = tmpMeta8;
_cr = tmpMeta9;
tmpMeta10 = stringAppend(_id,_inString);
_id = tmpMeta10;
tmpMeta11 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _id, _ty, _subs, _cr);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta12;
_ty = tmpMeta13;
_subs = tmpMeta14;
tmpMeta15 = stringAppend(_id,_inString);
_id = tmpMeta15;
tmpMeta16 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _id, _ty, _subs);
tmpMeta1 = tmpMeta16;
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_appendStringCref(threadData_t *threadData, modelica_string _str, modelica_metatype _cr)
{
modelica_metatype _ocr = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta2 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _str, _OMC_LIT1, tmpMeta1);
_ocr = omc_ComponentReference_joinCrefs(threadData, _cr, tmpMeta2);
_return: OMC_LABEL_UNUSED
return _ocr;
}
DLLExport
modelica_metatype omc_ComponentReference_prependStringCref(threadData_t *threadData, modelica_string _inString, modelica_metatype _inComponentRef)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inString;
tmp4_2 = _inComponentRef;
{
modelica_string _i_1 = NULL;
modelica_string _p = NULL;
modelica_string _i = NULL;
modelica_metatype _s = NULL;
modelica_metatype _c = NULL;
modelica_metatype _t2 = NULL;
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
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
_i = tmpMeta6;
_t2 = tmpMeta7;
_s = tmpMeta8;
_c = tmpMeta9;
_p = tmp4_1;
tmpMeta10 = stringAppend(_p,_i);
_i_1 = tmpMeta10;
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _i_1, _t2, _s, _c);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_i = tmpMeta11;
_t2 = tmpMeta12;
_s = tmpMeta13;
_p = tmp4_1;
tmpMeta14 = stringAppend(_p,_i);
_i_1 = tmpMeta14;
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _i_1, _t2, _s);
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_prefixWithPath(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inPath)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_string _name = NULL;
modelica_metatype _rest_path = NULL;
modelica_metatype _cref = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta5;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta7 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _name, _OMC_LIT1, tmpMeta6, _inCref);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_name = tmpMeta8;
_rest_path = tmpMeta9;
_cref = omc_ComponentReference_prefixWithPath(threadData, _inCref, _rest_path);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta11 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _name, _OMC_LIT1, tmpMeta10, _cref);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_rest_path = tmpMeta12;
_inPath = _rest_path;
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_crefPrefixStringList(threadData_t *threadData, modelica_metatype _inStrings, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inStrings;
tmp4_2 = _inCref;
{
modelica_string _str = NULL;
modelica_metatype _rest_str = NULL;
modelica_metatype _cref = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_str = tmpMeta6;
_rest_str = tmpMeta7;
_cref = tmp4_2;
_cref = omc_ComponentReference_crefPrefixStringList(threadData, _rest_str, _cref);
tmpMeta1 = omc_ComponentReference_crefPrefixString(threadData, _str, _cref);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inCref;
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
_outCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_crefPrefixString(threadData_t *threadData, modelica_string _inString, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outCref = omc_ComponentReference_makeCrefQual(threadData, _inString, _OMC_LIT1, tmpMeta1, _inCref);
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_crefPrefixStart(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outCref = omc_ComponentReference_makeCrefQual(threadData, _OMC_LIT48, _OMC_LIT1, tmpMeta1, _inCref);
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_crefRemovePrePrefix(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcref)
{
modelica_metatype _cref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref = __omcQ_24in_5Fcref;
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (4 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT49), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 5)));
goto tmp3_done;
}
case 1: {
tmpMeta1 = _cref;
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
_cref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _cref;
}
DLLExport
modelica_metatype omc_ComponentReference_crefPrefixAux(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outCref = omc_ComponentReference_makeCrefQual(threadData, _OMC_LIT50, _OMC_LIT51, tmpMeta1, _inCref);
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_crefPrefixPrevious(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outCref = omc_ComponentReference_makeCrefQual(threadData, _OMC_LIT13, _OMC_LIT1, tmpMeta1, _inCref);
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_getConcealedCref(threadData_t *threadData)
{
modelica_metatype _outCref = NULL;
modelica_string _ident = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(_OMC_LIT52,intString(((modelica_integer) 1) + omc_System_tmpTick(threadData)));
_ident = tmpMeta1;
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_outCref = omc_ComponentReference_makeCrefIdent(threadData, _ident, _OMC_LIT1, tmpMeta2);
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_crefPrefixPre(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outCref = omc_ComponentReference_makeCrefQual(threadData, _OMC_LIT49, _OMC_LIT1, tmpMeta1, _inCref);
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_crefPrefixDer(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outCref = omc_ComponentReference_makeCrefQual(threadData, _OMC_LIT12, _OMC_LIT51, tmpMeta1, _inCref);
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_crefPrependIdent(threadData_t *threadData, modelica_metatype _icr, modelica_string _ident, modelica_metatype _subs, modelica_metatype _tp)
{
modelica_metatype _newCr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _icr;
{
modelica_metatype _tp1 = NULL;
modelica_string _id1 = NULL;
modelica_metatype _subs1 = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id1 = tmpMeta6;
_tp1 = tmpMeta7;
_subs1 = tmpMeta8;
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id1, _tp1, _subs1, omc_ComponentReference_makeCrefIdent(threadData, _ident, _tp, _subs));
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id1 = tmpMeta9;
_tp1 = tmpMeta10;
_subs1 = tmpMeta11;
_cr = tmpMeta12;
_cr = omc_ComponentReference_crefPrependIdent(threadData, _cr, _ident, _subs, _tp);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _id1, _tp1, _subs1, _cr);
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
_newCr = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _newCr;
}
DLLExport
modelica_metatype omc_ComponentReference_getArraySubs(threadData_t *threadData, modelica_metatype _name)
{
modelica_metatype _arraySubs = NULL;
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
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta1 = omc_ComponentReference_crefSubs(threadData, _name);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
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
_arraySubs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _arraySubs;
}
DLLExport
modelica_metatype omc_ComponentReference_getArrayCref(threadData_t *threadData, modelica_metatype _name)
{
modelica_metatype _arrayCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _arrayCrefInner = NULL;
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
tmp6 = omc_ComponentReference_crefIsFirstArrayElt(threadData, _name);
if (1 != tmp6) goto goto_2;
if((stringEqual(omc_Config_simCodeTarget(threadData), _OMC_LIT53)))
{
_arrayCrefInner = omc_ComponentReference_crefStripLastSubs(threadData, _name);
}
else
{
_arrayCrefInner = omc_ComponentReference_crefStripSubs(threadData, _name);
}
tmpMeta1 = mmc_mk_some(_arrayCrefInner);
goto tmp3_done;
}
case 1: {
tmpMeta1 = mmc_mk_none();
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
_arrayCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _arrayCref;
}
DLLExport
modelica_string omc_ComponentReference_crefNameType(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype *out_res)
{
modelica_string _id = NULL;
modelica_metatype _res = NULL;
modelica_string tmp1_c0 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inRef;
{
modelica_metatype _t2 = NULL;
modelica_string _name = NULL;
modelica_string _s = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_name = tmpMeta6;
_t2 = tmpMeta7;
tmp4 += 1;
tmp1_c0 = _name;
tmpMeta[0+1] = _t2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_name = tmpMeta8;
_t2 = tmpMeta9;
tmp1_c0 = _name;
tmpMeta[0+1] = _t2;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp10;
tmp10 = omc_Flags_isSet(threadData, _OMC_LIT31);
if (1 != tmp10) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT54);
_s = omc_ComponentReference_printComponentRefStr(threadData, _inRef);
omc_Debug_traceln(threadData, _s);
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
_id = tmp1_c0;
_res = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_res) { *out_res = _res; }
return _id;
}
DLLExport
modelica_metatype omc_ComponentReference_crefTypeConsiderSubs(threadData_t *threadData, modelica_metatype _cr)
{
modelica_metatype _res = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_Expression_unliftArrayTypeWithSubs(threadData, omc_ComponentReference_crefLastSubs(threadData, _cr), omc_ComponentReference_crefLastType(threadData, _cr));
_return: OMC_LABEL_UNUSED
return _res;
}
DLLExport
modelica_metatype omc_ComponentReference_crefFirstCref(threadData_t *threadData, modelica_metatype _inCr)
{
modelica_metatype _outCr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCr;
{
modelica_string _id = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _t2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta6;
_t2 = tmpMeta7;
_subs = tmpMeta8;
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _id, _t2, _subs);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta1 = _inCr;
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
_outCr = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCr;
}
DLLExport
modelica_metatype omc_ComponentReference_crefLastSubs(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outSubscriptLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _subs = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_subs = tmpMeta6;
tmpMeta1 = _subs;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta7;
_inComponentRef = _cr;
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
_outSubscriptLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSubscriptLst;
}
DLLExport
modelica_metatype omc_ComponentReference_crefFirstSubs(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outSubscripts = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 4)));
goto tmp3_done;
}
case 3: {
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 4)));
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta5;
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
_outSubscripts = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSubscripts;
}
DLLExport
modelica_metatype omc_ComponentReference_crefSubs(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outSubscriptLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _subs = NULL;
modelica_metatype _res = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_subs = tmpMeta6;
tmpMeta1 = _subs;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_subs = tmpMeta7;
_cr = tmpMeta8;
_res = omc_ComponentReference_crefSubs(threadData, _cr);
tmpMeta1 = listAppend(_subs, _res);
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
_outSubscriptLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSubscriptLst;
}
DLLExport
modelica_metatype omc_ComponentReference_crefDims(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outDimensionLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _dims = NULL;
modelica_metatype _res = NULL;
modelica_metatype _idType = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_idType = tmpMeta6;
tmpMeta1 = omc_Types_getDimensions(threadData, _idType);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_idType = tmpMeta7;
_cr = tmpMeta8;
_dims = omc_Types_getDimensions(threadData, _idType);
_res = omc_ComponentReference_crefDims(threadData, _cr);
tmpMeta1 = listAppend(_dims, _res);
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
_outDimensionLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDimensionLst;
}
DLLExport
modelica_metatype omc_ComponentReference_crefLastType(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_metatype _res = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRef;
{
modelica_metatype _t2 = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_t2 = tmpMeta6;
tmpMeta1 = _t2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta7;
_inRef = _cr;
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
_res = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _res;
}
DLLExport
modelica_metatype omc_ComponentReference_crefType(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outType = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_metatype _ty = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_ty = tmpMeta5;
tmpMeta1 = _ty;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_ty = tmpMeta6;
tmpMeta1 = _ty;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_boolean tmp7;
tmp7 = omc_Flags_isSet(threadData, _OMC_LIT31);
if (1 != tmp7) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT55);
omc_Debug_traceln(threadData, omc_ComponentReference_printComponentRefStr(threadData, _inCref));
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
_outType = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outType;
}
DLLExport
modelica_metatype omc_ComponentReference_crefTypeFull(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outType = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _dims = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_ty = omc_ComponentReference_crefTypeFull2(threadData, _inCref, tmpMeta1 ,&_dims);
if(listEmpty(_dims))
{
_outType = _ty;
}
else
{
tmpMeta2 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, _dims);
_outType = tmpMeta2;
}
_return: OMC_LABEL_UNUSED
return _outType;
}
DLLExport
modelica_metatype omc_ComponentReference_crefTypeFull2(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _accumDims, modelica_metatype *out_outDims)
{
modelica_metatype _outType = NULL;
modelica_metatype _outDims = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_metatype _cr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _subs = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_ty = tmpMeta5;
_subs = tmpMeta6;
_ty = omc_Types_flattenArrayType(threadData, _ty ,&_dims);
_dims = omc_ComponentReference_crefTypeFullComputeDims(threadData, _dims, _subs);
if((!listEmpty(_accumDims)))
{
_dims = listReverse(omc_List_append__reverse(threadData, _dims, _accumDims));
}
tmpMeta[0+0] = _ty;
tmpMeta[0+1] = _dims;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_ty = tmpMeta7;
_subs = tmpMeta8;
_cr = tmpMeta9;
_ty = omc_Types_flattenArrayType(threadData, _ty ,&_dims);
_dims = omc_ComponentReference_crefTypeFullComputeDims(threadData, _dims, _subs);
_inCref = _cr;
_accumDims = omc_List_append__reverse(threadData, _dims, _accumDims);
goto _tailrecursive;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_boolean tmp10;
tmp10 = omc_Flags_isSet(threadData, _OMC_LIT31);
if (1 != tmp10) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT56);
omc_Debug_traceln(threadData, omc_ComponentReference_printComponentRefStr(threadData, _inCref));
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
_outType = tmpMeta[0+0];
_outDims = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outDims) { *out_outDims = _outDims; }
return _outType;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_crefTypeFullComputeDims(threadData_t *threadData, modelica_metatype _inDims, modelica_metatype _inSubs)
{
modelica_metatype _outDims = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _dim = NULL;
modelica_metatype _slice_dim = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta14;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_dims = _inDims;
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outDims = tmpMeta1;
{
modelica_metatype _sub;
for (tmpMeta2 = _inSubs; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_sub = MMC_CAR(tmpMeta2);
tmpMeta3 = _dims;
if (listEmpty(tmpMeta3)) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_CAR(tmpMeta3);
tmpMeta5 = MMC_CDR(tmpMeta3);
_dim = tmpMeta4;
_dims = tmpMeta5;
{
modelica_metatype tmp8_1;
tmp8_1 = _sub;
{
int tmp8;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp8_1))) {
case 5: {
goto tmp7_done;
}
case 4: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta9 = omc_Types_getDimensions(threadData, omc_Expression_typeof(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sub), 2)))));
if (listEmpty(tmpMeta9)) goto goto_6;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
_slice_dim = tmpMeta10;
tmpMeta12 = mmc_mk_cons(_slice_dim, _outDims);
_outDims = tmpMeta12;
goto tmp7_done;
}
case 3: {
modelica_metatype tmpMeta13;
tmpMeta13 = mmc_mk_cons(_dim, _outDims);
_outDims = tmpMeta13;
goto tmp7_done;
}
}
goto tmp7_end;
tmp7_end: ;
}
goto goto_6;
goto_6:;
MMC_THROW_INTERNAL();
goto tmp7_done;
tmp7_done:;
}
}
;
}
}
_outDims = listAppend(_outDims, _dims);
_return: OMC_LABEL_UNUSED
return _outDims;
}
DLLExport
modelica_metatype omc_ComponentReference_crefRest(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inCref;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,0,4) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
_outCref = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _outCref;
}
DLLExport
modelica_metatype omc_ComponentReference_crefLastCref(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta1 = _inComponentRef;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta6;
_inComponentRef = _cr;
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_string omc_ComponentReference_crefLastIdent(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _id = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_id = tmpMeta6;
tmp1 = _id;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta7;
_inComponentRef = _cr;
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
DLLExport
modelica_string omc_ComponentReference_crefFirstIdent(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _id = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_id = tmpMeta6;
tmp1 = _id;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_id = tmpMeta7;
tmp1 = _id;
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
DLLExport
modelica_metatype omc_ComponentReference_crefLastPath(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _i = NULL;
modelica_metatype _c = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
_i = tmpMeta6;
tmpMeta8 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _i);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_c = tmpMeta10;
_inComponentRef = _c;
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_metatype omc_ComponentReference_crefArrayGetFirstCref(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _cr = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _newsubs = NULL;
modelica_integer _diff;
modelica_metatype _ty = NULL;
modelica_string _i = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_i = tmpMeta6;
_ty = tmpMeta7;
_subs = tmpMeta8;
_dims = omc_Types_getDimensions(threadData, _ty);
_diff = listLength(_dims) - listLength(_subs);
_newsubs = omc_List_fill(threadData, _OMC_LIT58, _diff);
tmpMeta9 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _i, _ty, listAppend(_subs, _newsubs));
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_i = tmpMeta10;
_ty = tmpMeta11;
_subs = tmpMeta12;
_cr = tmpMeta13;
_dims = omc_Types_getDimensions(threadData, _ty);
_diff = listLength(_dims) - listLength(_subs);
_newsubs = omc_List_fill(threadData, _OMC_LIT58, _diff);
_cr = omc_ComponentReference_crefArrayGetFirstCref(threadData, _cr);
tmpMeta14 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _i, _ty, listAppend(_subs, _newsubs), _cr);
tmpMeta1 = tmpMeta14;
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReference_containWholeDim3(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _ad)
{
modelica_boolean _ob;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _ad;
{
modelica_metatype _expl = NULL;
modelica_integer _x1;
modelica_integer _x2;
modelica_metatype _d = NULL;
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
modelica_boolean tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_2);
tmpMeta8 = MMC_CDR(tmp4_2);
_expl = tmpMeta6;
_d = tmpMeta7;
_x1 = listLength(_expl);
_x2 = omc_Expression_dimensionSize(threadData, _d);
tmp9 = (_x1 == _x2);
if (1 != tmp9) goto goto_2;
tmp1 = 1;
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
_ob = tmp1;
_return: OMC_LABEL_UNUSED
return _ob;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_containWholeDim3(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _ad)
{
modelica_boolean _ob;
modelica_metatype out_ob;
_ob = omc_ComponentReference_containWholeDim3(threadData, _inExp, _ad);
out_ob = mmc_mk_icon(_ob);
return out_ob;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReference_containWholeDim2(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inType)
{
modelica_boolean _wholedim;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inRef;
tmp4_2 = _inType;
{
modelica_metatype _ssl = NULL;
modelica_metatype _tty = NULL;
modelica_metatype _ad = NULL;
modelica_metatype _es1 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 4;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,2) == 0) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,0) == 0) goto tmp3_end;
tmp4 += 1;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_1);
tmpMeta10 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_ad = tmpMeta8;
_es1 = tmpMeta11;
tmp12 = omc_ComponentReference_containWholeDim3(threadData, _es1, _ad);
if (1 != tmp12) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,2) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_ssl = tmpMeta14;
_tty = tmpMeta15;
_ad = tmpMeta16;
_ad = omc_List_stripFirst(threadData, _ad);
tmpMeta17 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _tty, _ad);
tmp1 = omc_ComponentReference_containWholeDim2(threadData, _ssl, tmpMeta17);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmp4_1);
tmpMeta19 = MMC_CDR(tmp4_1);
_ssl = tmpMeta19;
tmp1 = omc_ComponentReference_containWholeDim2(threadData, _ssl, _inType);
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
_wholedim = tmp1;
_return: OMC_LABEL_UNUSED
return _wholedim;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_containWholeDim2(threadData_t *threadData, modelica_metatype _inRef, modelica_metatype _inType)
{
modelica_boolean _wholedim;
modelica_metatype out_wholedim;
_wholedim = omc_ComponentReference_containWholeDim2(threadData, _inRef, _inType);
out_wholedim = mmc_mk_icon(_wholedim);
return out_wholedim;
}
DLLExport
modelica_metatype omc_ComponentReference_crefGetFirstRec(threadData_t *threadData, modelica_metatype _cref, modelica_boolean *out_isRec)
{
modelica_metatype _result = NULL;
modelica_boolean _isRec;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
modelica_metatype _innerCref = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmpMeta[0+0] = _cref;
tmp1_c1 = omc_Types_isRecord(threadData, omc_ComponentReference_crefType(threadData, _cref));
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if(omc_Types_isRecord(threadData, omc_ComponentReference_crefType(threadData, _cref)))
{
tmpMeta5 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4))));
_result = tmpMeta5;
_isRec = 1;
}
else
{
_innerCref = omc_ComponentReference_crefGetFirstRec(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 5))) ,&_isRec);
tmpMeta6 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4))), _innerCref);
_result = tmpMeta6;
}
tmpMeta[0+0] = _result;
tmp1_c1 = _isRec;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta[0+0] = _cref;
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
_result = tmpMeta[0+0];
_isRec = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_isRec) { *out_isRec = _isRec; }
return _result;
}
modelica_metatype boxptr_ComponentReference_crefGetFirstRec(threadData_t *threadData, modelica_metatype _cref, modelica_metatype *out_isRec)
{
modelica_boolean _isRec;
modelica_metatype _result = NULL;
_result = omc_ComponentReference_crefGetFirstRec(threadData, _cref, &_isRec);
if (out_isRec) { *out_isRec = mmc_mk_icon(_isRec); }
return _result;
}
DLLExport
modelica_boolean omc_ComponentReference_crefIsRec(threadData_t *threadData, modelica_metatype _cref, modelica_boolean _isRecIn)
{
modelica_boolean _isRec;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_isRec = (_isRecIn || omc_Types_isRecord(threadData, omc_ComponentReference_crefLastType(threadData, _cref)));
_return: OMC_LABEL_UNUSED
return _isRec;
}
modelica_metatype boxptr_ComponentReference_crefIsRec(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _isRecIn)
{
modelica_integer tmp1;
modelica_boolean _isRec;
modelica_metatype out_isRec;
tmp1 = mmc_unbox_integer(_isRecIn);
_isRec = omc_ComponentReference_crefIsRec(threadData, _cref, tmp1);
out_isRec = mmc_mk_icon(_isRec);
return out_isRec;
}
DLLExport
modelica_metatype omc_ComponentReference_traverseCref(threadData_t *threadData, modelica_metatype _cref, modelica_fnptr _func, modelica_metatype _argIn)
{
modelica_metatype _argOut = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
modelica_metatype _cr = NULL;
modelica_metatype _arg = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmp4 += 1;
tmpMeta1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _cref, _argIn) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _cref, _argIn);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta6;
_arg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _cref, _argIn) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _cref, _argIn);
tmpMeta1 = omc_ComponentReference_traverseCref(threadData, _cr, ((modelica_fnptr) _func), _arg);
goto tmp3_done;
}
case 2: {
fputs(MMC_STRINGDATA(_OMC_LIT59),stdout);
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
_argOut = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _argOut;
}
DLLExport
modelica_boolean omc_ComponentReference_containWholeDim(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _wholedim;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRef;
{
modelica_metatype _cr = NULL;
modelica_metatype _ssl = NULL;
modelica_metatype _ty = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_ty = tmpMeta5;
_ssl = tmpMeta6;
tmp1 = omc_ComponentReference_containWholeDim2(threadData, _ssl, _ty);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta7;
_inRef = _cr;
goto _tailrecursive;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
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
_wholedim = tmp1;
_return: OMC_LABEL_UNUSED
return _wholedim;
}
modelica_metatype boxptr_ComponentReference_containWholeDim(threadData_t *threadData, modelica_metatype _inRef)
{
modelica_boolean _wholedim;
modelica_metatype out_wholedim;
_wholedim = omc_ComponentReference_containWholeDim(threadData, _inRef);
out_wholedim = mmc_mk_icon(_wholedim);
return out_wholedim;
}
DLLExport
modelica_boolean omc_ComponentReference_crefIsScalarWithVariableSubs(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_boolean _isScalar;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _subs = NULL;
modelica_metatype _dims = NULL;
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
modelica_boolean tmp9;
modelica_boolean tmp10;
tmpMeta6 = omc_ComponentReference_crefSubs(threadData, _inCref);
if (listEmpty(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_subs = tmpMeta6;
_dims = omc_ComponentReference_crefDims(threadData, _inCref);
tmp9 = (listLength(_dims) <= listLength(_subs));
if (1 != tmp9) goto goto_2;
tmp10 = omc_Expression_subscriptConstants(threadData, _subs);
if (0 != tmp10) goto goto_2;
tmp1 = 1;
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
_isScalar = tmp1;
_return: OMC_LABEL_UNUSED
return _isScalar;
}
modelica_metatype boxptr_ComponentReference_crefIsScalarWithVariableSubs(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_boolean _isScalar;
modelica_metatype out_isScalar;
_isScalar = omc_ComponentReference_crefIsScalarWithVariableSubs(threadData, _inCref);
out_isScalar = mmc_mk_icon(_isScalar);
return out_isScalar;
}
DLLExport
modelica_boolean omc_ComponentReference_crefIsScalarWithAllConstSubs(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_boolean _isScalar;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _subs = NULL;
modelica_metatype _dims = NULL;
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
tmpMeta6 = omc_ComponentReference_crefSubs(threadData, _inCref);
if (!listEmpty(tmpMeta6)) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
modelica_boolean tmp11;
tmpMeta7 = omc_ComponentReference_crefSubs(threadData, _inCref);
if (listEmpty(tmpMeta7)) goto goto_2;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
_subs = tmpMeta7;
_dims = omc_ComponentReference_crefDims(threadData, _inCref);
tmp10 = (listLength(_dims) <= listLength(_subs));
if (1 != tmp10) goto goto_2;
tmp11 = omc_Expression_subscriptConstants(threadData, _subs);
if (1 != tmp11) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
tmp1 = 0;
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
_isScalar = tmp1;
_return: OMC_LABEL_UNUSED
return _isScalar;
}
modelica_metatype boxptr_ComponentReference_crefIsScalarWithAllConstSubs(threadData_t *threadData, modelica_metatype _inCref)
{
modelica_boolean _isScalar;
modelica_metatype out_isScalar;
_isScalar = omc_ComponentReference_crefIsScalarWithAllConstSubs(threadData, _inCref);
out_isScalar = mmc_mk_icon(_isScalar);
return out_isScalar;
}
DLLExport
modelica_boolean omc_ComponentReference_crefHasScalarSubscripts(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _hasScalarSubs;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _subs = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _dims = NULL;
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
tmpMeta6 = omc_ComponentReference_crefLastSubs(threadData, _cr);
if (!listEmpty(tmpMeta6)) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
modelica_boolean tmp11;
tmpMeta7 = omc_ComponentReference_crefLastSubs(threadData, _cr);
if (listEmpty(tmpMeta7)) goto goto_2;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
_subs = tmpMeta7;
tmp10 = omc_Expression_subscriptConstants(threadData, _subs);
if (1 != tmp10) goto goto_2;
_tp = omc_ComponentReference_crefLastType(threadData, _cr);
_dims = omc_Expression_arrayDimension(threadData, _tp);
tmp11 = (listLength(_dims) <= listLength(_subs));
if (1 != tmp11) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
tmp1 = 0;
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
_hasScalarSubs = tmp1;
_return: OMC_LABEL_UNUSED
return _hasScalarSubs;
}
modelica_metatype boxptr_ComponentReference_crefHasScalarSubscripts(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _hasScalarSubs;
modelica_metatype out_hasScalarSubs;
_hasScalarSubs = omc_ComponentReference_crefHasScalarSubscripts(threadData, _cr);
out_hasScalarSubs = mmc_mk_icon(_hasScalarSubs);
return out_hasScalarSubs;
}
DLLExport
modelica_boolean omc_ComponentReference_crefHaveSubs(threadData_t *threadData, modelica_metatype _icr)
{
modelica_boolean _ob;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _icr;
{
modelica_metatype _cr = NULL;
modelica_string _str = NULL;
modelica_integer _idx;
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
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
tmp4 += 3;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
tmp4 += 2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta13)) goto tmp3_end;
_str = tmpMeta12;
tmp4 += 1;
_idx = omc_System_stringFind(threadData, _str, _OMC_LIT3);
if((!(_idx > ((modelica_integer) 0))))
{
goto goto_2;
}
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta14)) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta15;
tmp1 = omc_ComponentReference_crefHaveSubs(threadData, _cr);
goto tmp3_done;
}
case 4: {
tmp1 = 0;
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
_ob = tmp1;
_return: OMC_LABEL_UNUSED
return _ob;
}
modelica_metatype boxptr_ComponentReference_crefHaveSubs(threadData_t *threadData, modelica_metatype _icr)
{
modelica_boolean _ob;
modelica_metatype out_ob;
_ob = omc_ComponentReference_crefHaveSubs(threadData, _icr);
out_ob = mmc_mk_icon(_ob);
return out_ob;
}
DLLExport
modelica_boolean omc_ComponentReference_crefIsFirstArrayElt(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _subs = NULL;
modelica_metatype _cr = NULL;
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
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
_cr = tmp4_1;
if((stringEqual(omc_Config_simCodeTarget(threadData), _OMC_LIT53)))
{
tmpMeta6 = omc_ComponentReference_crefLastSubs(threadData, _cr);
if (listEmpty(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
_subs = tmpMeta6;
}
else
{
tmpMeta9 = omc_ComponentReference_crefSubs(threadData, _cr);
if (listEmpty(tmpMeta9)) goto goto_2;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
_subs = tmpMeta9;
}
tmp1 = omc_List_mapAllValueBool(threadData, _subs, boxvar_Expression_subscriptIsFirst, mmc_mk_boolean(1));
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_ComponentReference_crefIsFirstArrayElt(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_ComponentReference_crefIsFirstArrayElt(threadData, _inComponentRef);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_metatype omc_ComponentReference_popCref(threadData_t *threadData, modelica_metatype _inCR)
{
modelica_metatype _outCR = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCR;
{
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta6;
tmpMeta1 = _cr;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inCR;
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
_outCR = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCR;
}
DLLExport
modelica_metatype omc_ComponentReference_popPreCref(threadData_t *threadData, modelica_metatype _inCR)
{
modelica_metatype _outCR = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCR;
{
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (4 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT49), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta7;
tmpMeta1 = _cr;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inCR;
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
_outCR = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCR;
}
DLLExport
modelica_boolean omc_ComponentReference_isStartCref(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (6 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT48), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
tmp1 = 1;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_ComponentReference_isStartCref(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ComponentReference_isStartCref(threadData, _cr);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_ComponentReference_isPreviousCref(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (7 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT13), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
tmp1 = 1;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_ComponentReference_isPreviousCref(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ComponentReference_isPreviousCref(threadData, _cr);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_ComponentReference_isPreCref(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (4 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT49), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
tmp1 = 1;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_ComponentReference_isPreCref(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ComponentReference_isPreCref(threadData, _cr);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_ComponentReference_isArrayElement(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
modelica_metatype _comp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,6,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_comp = tmpMeta8;
_cr = _comp;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
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
return _b;
}
modelica_metatype boxptr_ComponentReference_isArrayElement(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ComponentReference_isArrayElement(threadData, _cr);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_ComponentReference_isRecord(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
modelica_metatype _comp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,9,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_comp = tmpMeta8;
_cr = _comp;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
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
return _b;
}
modelica_metatype boxptr_ComponentReference_isRecord(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ComponentReference_isRecord(threadData, _cr);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_ComponentReference_isInternalCref(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _b;
modelica_string _s = NULL;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (4 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT12), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (7 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT13), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_s = tmpMeta8;
tmp1 = (stringEqual(substring(_s, ((modelica_integer) 1), ((modelica_integer) 1)), _OMC_LIT60));
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_s = tmpMeta9;
tmp1 = (stringEqual(substring(_s, ((modelica_integer) 1), ((modelica_integer) 1)), _OMC_LIT60));
goto tmp3_done;
}
case 4: {
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
return _b;
}
modelica_metatype boxptr_ComponentReference_isInternalCref(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ComponentReference_isInternalCref(threadData, _cr);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_ComponentReference_crefIsNotIdent(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
tmp1 = 1;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_crefIsNotIdent(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_ComponentReference_crefIsNotIdent(threadData, _cr);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_ComponentReference_crefIsIdent(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmp1 = 1;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_crefIsIdent(threadData_t *threadData, modelica_metatype _cr)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_ComponentReference_crefIsIdent(threadData, _cr);
out_res = mmc_mk_icon(_res);
return out_res;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ComponentReference_crefEqualWithoutSubs2(threadData_t *threadData, modelica_boolean _refEq, modelica_metatype _icr1, modelica_metatype _icr2)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _refEq;
tmp4_2 = _icr1;
tmp4_3 = _icr2;
{
modelica_string _n1 = NULL;
modelica_string _n2 = NULL;
modelica_boolean _r;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (1 != tmp4_1) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_n1 = tmpMeta6;
_n2 = tmpMeta7;
tmp1 = (stringEqual(_n1, _n2));
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
modelica_boolean tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,4) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
_n1 = tmpMeta8;
_cr1 = tmpMeta9;
_n2 = tmpMeta10;
_cr2 = tmpMeta11;
_r = (stringEqual(_n1, _n2));
tmp12 = (modelica_boolean)_r;
if(tmp12)
{
_refEq = referenceEq(_cr1, _cr2);
_icr1 = _cr1;
_icr2 = _cr2;
goto _tailrecursive;
}
else
{
tmp13 = 0;
}
tmp1 = tmp13;
goto tmp3_done;
}
case 3: {
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_crefEqualWithoutSubs2(threadData_t *threadData, modelica_metatype _refEq, modelica_metatype _icr1, modelica_metatype _icr2)
{
modelica_integer tmp1;
modelica_boolean _res;
modelica_metatype out_res;
tmp1 = mmc_unbox_integer(_refEq);
_res = omc_ComponentReference_crefEqualWithoutSubs2(threadData, tmp1, _icr1, _icr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_ComponentReference_crefEqualWithoutSubs(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _res;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_ComponentReference_crefEqualWithoutSubs2(threadData, referenceEq(_cr1, _cr2), _cr1, _cr2);
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_crefEqualWithoutSubs(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_ComponentReference_crefEqualWithoutSubs(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_ComponentReference_crefEqualWithoutLastSubs(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _res;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_ComponentReference_crefEqualNoStringCompare(threadData, omc_ComponentReference_crefStripLastSubs(threadData, _cr1), omc_ComponentReference_crefStripLastSubs(threadData, _cr2));
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_crefEqualWithoutLastSubs(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_ComponentReference_crefEqualWithoutLastSubs(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_metatype omc_ComponentReference_crefEqualReturn(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _cr2)
{
modelica_metatype _ocr = NULL;
modelica_boolean tmp1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = omc_ComponentReference_crefEqualNoStringCompare(threadData, _cr, _cr2);
if (1 != tmp1) MMC_THROW_INTERNAL();
_ocr = _cr;
_return: OMC_LABEL_UNUSED
return _ocr;
}
DLLExport
modelica_boolean omc_ComponentReference_crefEqualNoStringCompare(threadData_t *threadData, modelica_metatype _inCref1, modelica_metatype _inCref2)
{
modelica_boolean _outEqual;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(referenceEq(_inCref1, _inCref2))
{
_outEqual = 1;
goto _return;
}
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inCref1;
tmp4_2 = _inCref2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref2), 2))))) && omc_Expression_subscriptEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref2), 4)))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmp1 = (((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref2), 2))))) && omc_ComponentReference_crefEqualNoStringCompare(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref1), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref2), 5))))) && omc_Expression_subscriptEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref2), 4)))));
goto tmp3_done;
}
case 2: {
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
_outEqual = tmp1;
_return: OMC_LABEL_UNUSED
return _outEqual;
}
modelica_metatype boxptr_ComponentReference_crefEqualNoStringCompare(threadData_t *threadData, modelica_metatype _inCref1, modelica_metatype _inCref2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_ComponentReference_crefEqualNoStringCompare(threadData, _inCref1, _inCref2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
DLLExport
modelica_boolean omc_ComponentReference_crefEqualVerySlowStringCompareDoNotUse(threadData_t *threadData, modelica_metatype _inComponentRef1, modelica_metatype _inComponentRef2)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inComponentRef1;
tmp4_2 = _inComponentRef2;
{
modelica_string _n1 = NULL;
modelica_string _n2 = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_metatype _idx1 = NULL;
modelica_metatype _idx2 = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 9; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
tmp6 = referenceEq(_inComponentRef1, _inComponentRef2);
if (1 != tmp6) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta8)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
_n1 = tmpMeta7;
_n2 = tmpMeta9;
tmp4 += 6;
tmp11 = (stringEqual(_n1, _n2));
if (1 != tmp11) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_boolean tmp20;
modelica_boolean tmp21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (listEmpty(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmpMeta17);
tmpMeta19 = MMC_CDR(tmpMeta17);
_n1 = tmpMeta12;
_idx1 = tmpMeta13;
_n2 = tmpMeta16;
_idx2 = tmpMeta17;
tmp4 += 5;
tmp20 = (stringEqual(_n1, _n2));
if (1 != tmp20) goto goto_2;
tmp21 = omc_Expression_subscriptEqual(threadData, _idx1, _idx2);
if (1 != tmp21) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_integer tmp28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_boolean tmp32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta23)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (listEmpty(tmpMeta25)) goto tmp3_end;
tmpMeta26 = MMC_CAR(tmpMeta25);
tmpMeta27 = MMC_CDR(tmpMeta25);
_n1 = tmpMeta22;
_n2 = tmpMeta24;
_idx2 = tmpMeta25;
tmp4 += 4;
tmp28 = omc_System_stringFind(threadData, _n1, _n2);
if (0 != tmp28) goto goto_2;
tmpMeta29 = stringAppend(_n2,_OMC_LIT3);
tmpMeta30 = stringAppend(tmpMeta29,omc_ExpressionDump_printListStr(threadData, _idx2, boxvar_ExpressionDump_printSubscriptStr, _OMC_LIT4));
tmpMeta31 = stringAppend(tmpMeta30,_OMC_LIT7);
_s1 = tmpMeta31;
tmp32 = (stringEqual(_s1, _n1));
if (1 != tmp32) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_integer tmp39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_boolean tmp43;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta34)) goto tmp3_end;
tmpMeta35 = MMC_CAR(tmpMeta34);
tmpMeta36 = MMC_CDR(tmpMeta34);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (!listEmpty(tmpMeta38)) goto tmp3_end;
_n1 = tmpMeta33;
_idx2 = tmpMeta34;
_n2 = tmpMeta37;
tmp4 += 3;
tmp39 = omc_System_stringFind(threadData, _n2, _n1);
if (0 != tmp39) goto goto_2;
tmpMeta40 = stringAppend(_n1,_OMC_LIT3);
tmpMeta41 = stringAppend(tmpMeta40,omc_ExpressionDump_printListStr(threadData, _idx2, boxvar_ExpressionDump_printSubscriptStr, _OMC_LIT4));
tmpMeta42 = stringAppend(tmpMeta41,_OMC_LIT7);
_s1 = tmpMeta42;
tmp43 = (stringEqual(_s1, _n2));
if (1 != tmp43) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_boolean tmp50;
modelica_boolean tmp51;
modelica_boolean tmp52;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
_n1 = tmpMeta44;
_idx1 = tmpMeta45;
_cr1 = tmpMeta46;
_n2 = tmpMeta47;
_idx2 = tmpMeta48;
_cr2 = tmpMeta49;
tmp4 += 2;
tmp50 = (stringEqual(_n1, _n2));
if (1 != tmp50) goto goto_2;
tmp51 = omc_ComponentReference_crefEqualVerySlowStringCompareDoNotUse(threadData, _cr1, _cr2);
if (1 != tmp51) goto goto_2;
tmp52 = omc_Expression_subscriptEqual(threadData, _idx1, _idx2);
if (1 != tmp52) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_integer tmp55;
modelica_boolean tmp56;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_cr1 = tmp4_1;
_n1 = tmpMeta53;
_cr2 = tmp4_2;
_n2 = tmpMeta54;
tmp4 += 1;
tmp55 = omc_System_stringFind(threadData, _n2, _n1);
if (0 != tmp55) goto goto_2;
_s1 = omc_ComponentReference_printComponentRefStr(threadData, _cr1);
_s2 = omc_ComponentReference_printComponentRefStr(threadData, _cr2);
tmp56 = (stringEqual(_s1, _s2));
if (1 != tmp56) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_integer tmp59;
modelica_boolean tmp60;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_cr1 = tmp4_1;
_n1 = tmpMeta57;
_cr2 = tmp4_2;
_n2 = tmpMeta58;
tmp59 = omc_System_stringFind(threadData, _n1, _n2);
if (0 != tmp59) goto goto_2;
_s1 = omc_ComponentReference_printComponentRefStr(threadData, _cr1);
_s2 = omc_ComponentReference_printComponentRefStr(threadData, _cr2);
tmp60 = (stringEqual(_s1, _s2));
if (1 != tmp60) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 8: {
tmp1 = 0;
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
if (++tmp4 < 9) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_ComponentReference_crefEqualVerySlowStringCompareDoNotUse(threadData_t *threadData, modelica_metatype _inComponentRef1, modelica_metatype _inComponentRef2)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_ComponentReference_crefEqualVerySlowStringCompareDoNotUse(threadData, _inComponentRef1, _inComponentRef2);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_ComponentReference_crefNotInLst(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _lst)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = (!omc_List_isMemberOnTrue(threadData, _cref, _lst, boxvar_ComponentReference_crefEqual));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_ComponentReference_crefNotInLst(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _lst)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ComponentReference_crefNotInLst(threadData, _cref, _lst);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_ComponentReference_crefInLst(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _lst)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = omc_List_isMemberOnTrue(threadData, _cref, _lst, boxvar_ComponentReference_crefEqual);
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_ComponentReference_crefInLst(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _lst)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ComponentReference_crefInLst(threadData, _cref, _lst);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_ComponentReference_crefEqual(threadData_t *threadData, modelica_metatype _inComponentRef1, modelica_metatype _inComponentRef2)
{
modelica_boolean _outBoolean;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outBoolean = omc_ComponentReference_crefEqualNoStringCompare(threadData, _inComponentRef1, _inComponentRef2);
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_ComponentReference_crefEqual(threadData_t *threadData, modelica_metatype _inComponentRef1, modelica_metatype _inComponentRef2)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_ComponentReference_crefEqual(threadData, _inComponentRef1, _inComponentRef2);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_ComponentReference_crefNotPrefixOf(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cr1;
tmp4_2 = _cr2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
tmp1 = (!omc_ComponentReference_crefPrefixOf(threadData, _cr1, _cr2));
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_ComponentReference_crefNotPrefixOf(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_ComponentReference_crefNotPrefixOf(threadData, _cr1, _cr2);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_ComponentReference_crefPrefixOfIgnoreSubscripts(threadData_t *threadData, modelica_metatype _prefixCref, modelica_metatype _fullCref)
{
modelica_boolean _outPrefixOf;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _prefixCref;
tmp4_2 = _fullCref;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2))))) && omc_ComponentReference_crefPrefixOfIgnoreSubscripts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 5)))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2)))));
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2)))));
goto tmp3_done;
}
case 3: {
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
_outPrefixOf = tmp1;
_return: OMC_LABEL_UNUSED
return _outPrefixOf;
}
modelica_metatype boxptr_ComponentReference_crefPrefixOfIgnoreSubscripts(threadData_t *threadData, modelica_metatype _prefixCref, modelica_metatype _fullCref)
{
modelica_boolean _outPrefixOf;
modelica_metatype out_outPrefixOf;
_outPrefixOf = omc_ComponentReference_crefPrefixOfIgnoreSubscripts(threadData, _prefixCref, _fullCref);
out_outPrefixOf = mmc_mk_icon(_outPrefixOf);
return out_outPrefixOf;
}
DLLExport
modelica_boolean omc_ComponentReference_crefPrefixOf(threadData_t *threadData, modelica_metatype _prefixCref, modelica_metatype _fullCref)
{
modelica_boolean _outPrefixOf;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _prefixCref;
tmp4_2 = _fullCref;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmp1 = (((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2))))) && omc_Expression_subscriptEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 4))))) && omc_ComponentReference_crefPrefixOf(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 5)))));
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2)))));
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2))))) && omc_Expression_subscriptEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 4)))));
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2)))));
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = ((stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 2))))) && omc_Expression_subscriptEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_prefixCref), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fullCref), 4)))));
goto tmp3_done;
}
case 5: {
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
_outPrefixOf = tmp1;
_return: OMC_LABEL_UNUSED
return _outPrefixOf;
}
modelica_metatype boxptr_ComponentReference_crefPrefixOf(threadData_t *threadData, modelica_metatype _prefixCref, modelica_metatype _fullCref)
{
modelica_boolean _outPrefixOf;
modelica_metatype out_outPrefixOf;
_outPrefixOf = omc_ComponentReference_crefPrefixOf(threadData, _prefixCref, _fullCref);
out_outPrefixOf = mmc_mk_icon(_outPrefixOf);
return out_outPrefixOf;
}
DLLExport
modelica_boolean omc_ComponentReference_crefContainedIn(threadData_t *threadData, modelica_metatype _containerCref, modelica_metatype _containedCref)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _containerCref;
tmp4_2 = _containedCref;
{
modelica_metatype _full = NULL;
modelica_metatype _partOf = NULL;
modelica_metatype _cr2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
_full = tmp4_1;
_partOf = tmp4_2;
tmp6 = omc_ComponentReference_crefEqualNoStringCompare(threadData, _full, _partOf);
if (1 != tmp6) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_full = tmp4_1;
_cr2 = tmpMeta7;
_partOf = tmp4_2;
tmp8 = omc_ComponentReference_crefEqualNoStringCompare(threadData, _full, _partOf);
if (0 != tmp8) goto goto_2;
tmp1 = omc_ComponentReference_crefContainedIn(threadData, _cr2, _partOf);
goto tmp3_done;
}
case 3: {
tmp1 = 0;
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_ComponentReference_crefContainedIn(threadData_t *threadData, modelica_metatype _containerCref, modelica_metatype _containedCref)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_ComponentReference_crefContainedIn(threadData, _containerCref, _containedCref);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReference_crefLexicalCompareSubsAtEnd2(threadData_t *threadData, modelica_metatype _inSubs1, modelica_metatype _inSubs2)
{
modelica_integer _res;
modelica_metatype _rest = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_integer tmp5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = ((modelica_integer) 0);
_rest = _inSubs2;
{
modelica_metatype _i;
for (tmpMeta1 = _inSubs1; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_i = MMC_CAR(tmpMeta1);
tmpMeta2 = _rest;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
tmp5 = mmc_unbox_integer(tmpMeta3);
_res = tmp5;
_rest = tmpMeta4;
_res = ((mmc_unbox_integer(_i) > _res)?((modelica_integer) 1):((mmc_unbox_integer(_i) < _res)?((modelica_integer) -1):((modelica_integer) 0)));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
}
}
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_crefLexicalCompareSubsAtEnd2(threadData_t *threadData, modelica_metatype _inSubs1, modelica_metatype _inSubs2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReference_crefLexicalCompareSubsAtEnd2(threadData, _inSubs1, _inSubs2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_integer omc_ComponentReference_crefLexicalCompareSubsAtEnd(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_metatype _subs1 = NULL;
modelica_metatype _subs2 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_ComponentReference_CompareWithoutSubscripts_compare(threadData, _cr1, _cr2);
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_subs1 = omc_Expression_subscriptsInt(threadData, omc_ComponentReference_crefSubs(threadData, _cr1));
_subs2 = omc_Expression_subscriptsInt(threadData, omc_ComponentReference_crefSubs(threadData, _cr2));
_res = omc_ComponentReference_crefLexicalCompareSubsAtEnd2(threadData, _subs1, _subs2);
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_crefLexicalCompareSubsAtEnd(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReference_crefLexicalCompareSubsAtEnd(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_ComponentReference_crefLexicalGreaterSubsAtEnd(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _isGreater;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_isGreater = (omc_ComponentReference_crefLexicalCompareSubsAtEnd(threadData, _cr1, _cr2) > ((modelica_integer) 0));
_return: OMC_LABEL_UNUSED
return _isGreater;
}
modelica_metatype boxptr_ComponentReference_crefLexicalGreaterSubsAtEnd(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _isGreater;
modelica_metatype out_isGreater;
_isGreater = omc_ComponentReference_crefLexicalGreaterSubsAtEnd(threadData, _cr1, _cr2);
out_isGreater = mmc_mk_icon(_isGreater);
return out_isGreater;
}
DLLExport
modelica_integer omc_ComponentReference_crefCompareGenericNotAlphabetic(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _comp;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_comp = omc_ComponentReference_CompareWithGenericSubscriptNotAlphabetic_compare(threadData, _cr1, _cr2);
_return: OMC_LABEL_UNUSED
return _comp;
}
modelica_metatype boxptr_ComponentReference_crefCompareGenericNotAlphabetic(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _comp;
modelica_metatype out_comp;
_comp = omc_ComponentReference_crefCompareGenericNotAlphabetic(threadData, _cr1, _cr2);
out_comp = mmc_mk_icon(_comp);
return out_comp;
}
DLLExport
modelica_integer omc_ComponentReference_crefCompareIntSubscript(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _comp;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_comp = omc_ComponentReference_CompareWithIntSubscript_compare(threadData, _cr1, _cr2);
_return: OMC_LABEL_UNUSED
return _comp;
}
modelica_metatype boxptr_ComponentReference_crefCompareIntSubscript(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _comp;
modelica_metatype out_comp;
_comp = omc_ComponentReference_crefCompareIntSubscript(threadData, _cr1, _cr2);
out_comp = mmc_mk_icon(_comp);
return out_comp;
}
DLLExport
modelica_integer omc_ComponentReference_crefCompareGeneric(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _comp;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_comp = omc_ComponentReference_CompareWithGenericSubscript_compare(threadData, _cr1, _cr2);
_return: OMC_LABEL_UNUSED
return _comp;
}
modelica_metatype boxptr_ComponentReference_crefCompareGeneric(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _comp;
modelica_metatype out_comp;
_comp = omc_ComponentReference_crefCompareGeneric(threadData, _cr1, _cr2);
out_comp = mmc_mk_icon(_comp);
return out_comp;
}
DLLExport
modelica_boolean omc_ComponentReference_crefSortFunc(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _greaterThan;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_greaterThan = (omc_ComponentReference_CompareWithGenericSubscript_compare(threadData, _cr1, _cr2) > ((modelica_integer) 0));
_return: OMC_LABEL_UNUSED
return _greaterThan;
}
modelica_metatype boxptr_ComponentReference_crefSortFunc(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _greaterThan;
modelica_metatype out_greaterThan;
_greaterThan = omc_ComponentReference_crefSortFunc(threadData, _cr1, _cr2);
out_greaterThan = mmc_mk_icon(_greaterThan);
return out_greaterThan;
}
DLLExport
modelica_integer omc_ComponentReference_CompareWithIntSubscript_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cr1;
tmp4_2 = _cr2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = omc_ComponentReference_CompareWithIntSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReference_CompareWithIntSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_cr1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 5)));
_cr2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 5)));
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReference_CompareWithIntSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReference_CompareWithIntSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) -1);
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_CompareWithIntSubscript_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReference_CompareWithIntSubscript_compare(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_integer omc_ComponentReference_CompareWithIntSubscript_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype _ss = NULL;
modelica_metatype _s2 = NULL;
modelica_integer _i1;
modelica_integer _i2;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = ((modelica_integer) 0);
_ss = _ss2;
{
modelica_metatype _s1;
for (tmpMeta1 = _ss1; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_s1 = MMC_CAR(tmpMeta1);
if(listEmpty(_ss))
{
_res = ((modelica_integer) -1);
goto _return;
}
tmpMeta2 = _ss;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_s2 = tmpMeta3;
_ss = tmpMeta4;
_i1 = omc_Expression_subscriptInt(threadData, _s1);
_i2 = omc_Expression_subscriptInt(threadData, _s2);
_res = ((_i1 < _i2)?((modelica_integer) -1):((_i1 > _i2)?((modelica_integer) 1):((modelica_integer) 0)));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
}
}
if((!listEmpty(_ss)))
{
_res = ((modelica_integer) 1);
}
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_CompareWithIntSubscript_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReference_CompareWithIntSubscript_compareSubs(threadData, _ss1, _ss2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_integer omc_ComponentReference_CompareWithoutSubscripts_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cr1;
tmp4_2 = _cr2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
goto _return;
tmp1 = omc_ComponentReference_CompareWithoutSubscripts_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_cr1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 5)));
_cr2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 5)));
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) -1);
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_CompareWithoutSubscripts_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReference_CompareWithoutSubscripts_compare(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_integer omc_ComponentReference_CompareWithoutSubscripts_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype _ss = NULL;
modelica_metatype _s2 = NULL;
modelica_integer _i1;
modelica_integer _i2;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = ((modelica_integer) 0);
_ss = _ss2;
{
modelica_metatype _s1;
for (tmpMeta1 = _ss1; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_s1 = MMC_CAR(tmpMeta1);
if(listEmpty(_ss))
{
_res = ((modelica_integer) -1);
goto _return;
}
tmpMeta2 = _ss;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_s2 = tmpMeta3;
_ss = tmpMeta4;
_i1 = omc_Expression_subscriptInt(threadData, _s1);
_i2 = omc_Expression_subscriptInt(threadData, _s2);
_res = ((_i1 < _i2)?((modelica_integer) -1):((_i1 > _i2)?((modelica_integer) 1):((modelica_integer) 0)));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
}
}
if((!listEmpty(_ss)))
{
_res = ((modelica_integer) 1);
}
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_CompareWithoutSubscripts_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReference_CompareWithoutSubscripts_compareSubs(threadData, _ss1, _ss2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_integer omc_ComponentReference_CompareWithGenericSubscriptNotAlphabetic_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cr1;
tmp4_2 = _cr2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = omc_ComponentReference_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReference_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_cr1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 5)));
_cr2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 5)));
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReference_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReference_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) -1);
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_CompareWithGenericSubscriptNotAlphabetic_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReference_CompareWithGenericSubscriptNotAlphabetic_compare(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_integer omc_ComponentReference_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype _ss = NULL;
modelica_metatype _s2 = NULL;
modelica_integer _i1;
modelica_integer _i2;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = ((modelica_integer) 0);
_ss = _ss2;
{
modelica_metatype _s1;
for (tmpMeta1 = _ss1; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_s1 = MMC_CAR(tmpMeta1);
if(listEmpty(_ss))
{
_res = ((modelica_integer) -1);
goto _return;
}
tmpMeta2 = _ss;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_s2 = tmpMeta3;
_ss = tmpMeta4;
_res = omc_Expression_compareSubscripts(threadData, _s1, _s2);
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
}
}
if((!listEmpty(_ss)))
{
_res = ((modelica_integer) 1);
}
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReference_CompareWithGenericSubscriptNotAlphabetic_compareSubs(threadData, _ss1, _ss2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_integer omc_ComponentReference_CompareWithGenericSubscript_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype _ss = NULL;
modelica_metatype _s2 = NULL;
modelica_integer _i1;
modelica_integer _i2;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = ((modelica_integer) 0);
_ss = _ss2;
{
modelica_metatype _s1;
for (tmpMeta1 = _ss1; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_s1 = MMC_CAR(tmpMeta1);
if(listEmpty(_ss))
{
_res = ((modelica_integer) -1);
goto _return;
}
tmpMeta2 = _ss;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_s2 = tmpMeta3;
_ss = tmpMeta4;
_res = stringCompare(omc_ExpressionDump_printSubscriptStr(threadData, _s1), omc_ExpressionDump_printSubscriptStr(threadData, _s2));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
}
}
if((!listEmpty(_ss)))
{
_res = ((modelica_integer) 1);
}
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_CompareWithGenericSubscript_compareSubs(threadData_t *threadData, modelica_metatype _ss1, modelica_metatype _ss2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReference_CompareWithGenericSubscript_compareSubs(threadData, _ss1, _ss2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_integer omc_ComponentReference_CompareWithGenericSubscript_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cr1;
tmp4_2 = _cr2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = omc_ComponentReference_CompareWithGenericSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReference_CompareWithGenericSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_cr1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 5)));
_cr2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 5)));
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReference_CompareWithGenericSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
_res = stringCompare((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 2))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
_res = omc_ComponentReference_CompareWithGenericSubscript_compareSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr1), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cr2), 4))));
if((_res != ((modelica_integer) 0)))
{
goto _return;
}
tmp1 = ((modelica_integer) -1);
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_CompareWithGenericSubscript_compare(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_integer _res;
modelica_metatype out_res;
_res = omc_ComponentReference_CompareWithGenericSubscript_compare(threadData, _cr1, _cr2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_ComponentReference_crefFirstIdentEqual(threadData_t *threadData, modelica_metatype _inCref1, modelica_metatype _inCref2)
{
modelica_boolean _outEqual;
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_id1 = omc_ComponentReference_crefFirstIdent(threadData, _inCref1);
_id2 = omc_ComponentReference_crefFirstIdent(threadData, _inCref2);
_outEqual = (stringEqual(_id1, _id2));
_return: OMC_LABEL_UNUSED
return _outEqual;
}
modelica_metatype boxptr_ComponentReference_crefFirstIdentEqual(threadData_t *threadData, modelica_metatype _inCref1, modelica_metatype _inCref2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_ComponentReference_crefFirstIdentEqual(threadData, _inCref1, _inCref2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
DLLExport
modelica_boolean omc_ComponentReference_crefFirstCrefLastCrefEqual(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_metatype _pcr1 = NULL;
modelica_metatype _pcr2 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_pcr1 = omc_ComponentReference_crefFirstCref(threadData, _cr1);
_pcr2 = omc_ComponentReference_crefLastCref(threadData, _cr2);
_equal = omc_ComponentReference_crefEqual(threadData, _pcr1, _pcr2);
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_ComponentReference_crefFirstCrefLastCrefEqual(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_ComponentReference_crefFirstCrefLastCrefEqual(threadData, _cr1, _cr2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_ComponentReference_crefFirstCrefEqual(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_metatype _pcr1 = NULL;
modelica_metatype _pcr2 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_pcr1 = omc_ComponentReference_crefFirstCref(threadData, _cr1);
_pcr2 = omc_ComponentReference_crefFirstCref(threadData, _cr2);
_equal = omc_ComponentReference_crefEqual(threadData, _pcr1, _pcr2);
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_ComponentReference_crefFirstCrefEqual(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_ComponentReference_crefFirstCrefEqual(threadData, _cr1, _cr2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_ComponentReference_crefLastIdentEqual(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_id1 = omc_ComponentReference_crefLastIdent(threadData, _cr1);
_id2 = omc_ComponentReference_crefLastIdent(threadData, _cr2);
_equal = (stringEqual(_id1, _id2));
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_ComponentReference_crefLastIdentEqual(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_ComponentReference_crefLastIdentEqual(threadData, _cr1, _cr2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_string omc_ComponentReference_debugPrintComponentRefTypeStr(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _s = NULL;
modelica_string _str = NULL;
modelica_string _str2 = NULL;
modelica_string _strrest = NULL;
modelica_string _str_1 = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _ty = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 6: {
tmp1 = _OMC_LIT39;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
modelica_string tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_s = tmpMeta5;
_ty = tmpMeta6;
_subs = tmpMeta7;
_str_1 = omc_ExpressionDump_printListStr(threadData, _subs, boxvar_ExpressionDump_debugPrintSubscriptStr, _OMC_LIT34);
tmp10 = (modelica_boolean)(stringLength(_str_1) > ((modelica_integer) 0));
if(tmp10)
{
tmpMeta8 = stringAppend(_OMC_LIT3,_str_1);
tmpMeta9 = stringAppend(tmpMeta8,_OMC_LIT7);
tmp11 = tmpMeta9;
}
else
{
tmp11 = _OMC_LIT41;
}
tmpMeta12 = stringAppend(_s,tmp11);
_str = tmpMeta12;
_str2 = omc_Types_unparseType(threadData, _ty);
tmpMeta13 = mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT61, mmc_mk_cons(_str2, mmc_mk_cons(_OMC_LIT7, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta13);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_boolean tmp21;
modelica_string tmp22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_s = tmpMeta14;
_ty = tmpMeta15;
_subs = tmpMeta16;
_cr = tmpMeta17;
if(omc_Config_modelicaOutput(threadData))
{
_str = omc_ComponentReference_printComponentRef2Str(threadData, _s, _subs);
_str2 = omc_Types_unparseType(threadData, _ty);
_strrest = omc_ComponentReference_debugPrintComponentRefTypeStr(threadData, _cr);
tmpMeta18 = mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT61, mmc_mk_cons(_str2, mmc_mk_cons(_OMC_LIT63, mmc_mk_cons(_strrest, MMC_REFSTRUCTLIT(mmc_nil))))));
_str = stringAppendList(tmpMeta18);
}
else
{
_str_1 = omc_ExpressionDump_printListStr(threadData, _subs, boxvar_ExpressionDump_debugPrintSubscriptStr, _OMC_LIT34);
tmp21 = (modelica_boolean)(stringLength(_str_1) > ((modelica_integer) 0));
if(tmp21)
{
tmpMeta19 = stringAppend(_OMC_LIT3,_str_1);
tmpMeta20 = stringAppend(tmpMeta19,_OMC_LIT7);
tmp22 = tmpMeta20;
}
else
{
tmp22 = _OMC_LIT41;
}
tmpMeta23 = stringAppend(_s,tmp22);
_str = tmpMeta23;
_str2 = omc_Types_unparseType(threadData, _ty);
_strrest = omc_ComponentReference_debugPrintComponentRefTypeStr(threadData, _cr);
tmpMeta24 = mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT61, mmc_mk_cons(_str2, mmc_mk_cons(_OMC_LIT62, mmc_mk_cons(_strrest, MMC_REFSTRUCTLIT(mmc_nil))))));
_str = stringAppendList(tmpMeta24);
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ComponentReference_printComponentRef2Str(threadData_t *threadData, modelica_string _inIdent, modelica_metatype _inSubscriptLst)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inIdent;
tmp4_2 = _inSubscriptLst;
{
modelica_string _s = NULL;
modelica_string _str = NULL;
modelica_string _strseba = NULL;
modelica_string _strsebb = NULL;
modelica_metatype _l = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_s = tmp4_1;
tmp1 = _s;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
_s = tmp4_1;
_l = tmp4_2;
_b = omc_Config_modelicaOutput(threadData);
_str = omc_ExpressionDump_printListStr(threadData, _l, boxvar_ExpressionDump_printSubscriptStr, _OMC_LIT4);
tmpMeta6 = (_b?_OMC_LIT64:_OMC_LIT65);
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_strseba = tmpMeta7;
_strsebb = tmpMeta8;
tmpMeta9 = mmc_mk_cons(_s, mmc_mk_cons(_strseba, mmc_mk_cons(_str, mmc_mk_cons(_strsebb, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp1 = stringAppendList(tmpMeta9);
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
modelica_string omc_ComponentReference_printComponentRefStrFixDollarDer(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _cr = NULL;
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
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (4 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT12), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr = tmpMeta8;
tmpMeta9 = stringAppend(_OMC_LIT8,omc_ComponentReference_printComponentRefStr(threadData, _cr));
tmpMeta10 = stringAppend(tmpMeta9,_OMC_LIT9);
tmp1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
tmp1 = omc_ComponentReference_printComponentRefStr(threadData, _inComponentRef);
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
modelica_string omc_ComponentReference_printComponentRefStr(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _s = NULL;
modelica_string _str = NULL;
modelica_string _strrest = NULL;
modelica_string _strseb = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
_s = tmpMeta6;
tmp1 = _s;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_s = tmpMeta8;
_subs = tmpMeta9;
tmp1 = omc_ComponentReference_printComponentRef2Str(threadData, _s, _subs);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_s = tmpMeta10;
_subs = tmpMeta11;
_cr = tmpMeta12;
_b = omc_Config_modelicaOutput(threadData);
_str = omc_ComponentReference_printComponentRef2Str(threadData, _s, _subs);
_strrest = omc_ComponentReference_printComponentRefStr(threadData, _cr);
_strseb = (_b?_OMC_LIT40:_OMC_LIT11);
tmpMeta13 = mmc_mk_cons(_str, mmc_mk_cons(_strseb, mmc_mk_cons(_strrest, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta13);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT39;
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
modelica_string omc_ComponentReference_printComponentRefOptStr(threadData_t *threadData, modelica_metatype _inComponentRefOpt)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRefOpt;
{
modelica_string _str = NULL;
modelica_metatype _cref = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmp1 = _OMC_LIT66;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_cref = tmpMeta6;
_str = omc_ComponentReference_printComponentRefStr(threadData, _cref);
tmpMeta7 = stringAppend(_OMC_LIT67,_str);
tmpMeta8 = stringAppend(tmpMeta7,_OMC_LIT9);
tmp1 = tmpMeta8;
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
modelica_string omc_ComponentReference_crefModelicaStr(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = stringDelimitList(omc_ComponentReference_toStringList(threadData, _inComponentRef), _OMC_LIT39);
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ComponentReference_crefListStr(threadData_t *threadData, modelica_metatype _crList)
{
modelica_string _outString = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = _OMC_LIT41;
{
modelica_metatype _cr;
for (tmpMeta1 = _crList; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_cr = MMC_CAR(tmpMeta1);
tmpMeta2 = stringAppend(_outString,omc_ComponentReference_crefStr(threadData, _cr));
tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT22);
_outString = tmpMeta3;
}
}
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_ComponentReference_crefStr(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = stringDelimitList(omc_ComponentReference_toStringList(threadData, _inComponentRef), (omc_Flags_getConfigBool(threadData, _OMC_LIT75)?_OMC_LIT40:_OMC_LIT11));
_return: OMC_LABEL_UNUSED
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_toExpCrefSubs(threadData_t *threadData, modelica_metatype _absynSubs)
{
modelica_metatype _daeSubs = NULL;
modelica_integer _i;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype __omcQ_24tmpVar2;
modelica_integer tmp10;
modelica_metatype _sub_loopVar = 0;
modelica_metatype _sub;
_sub_loopVar = _absynSubs;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar3;
while(1) {
tmp10 = 1;
if (!listEmpty(_sub_loopVar)) {
_sub = MMC_CAR(_sub_loopVar);
_sub_loopVar = MMC_CDR(_sub_loopVar);
tmp10--;
}
if (tmp10 == 0) {
{
modelica_metatype tmp7_1;
tmp7_1 = _sub;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 2; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,1,1) == 0) goto tmp6_end;
tmpMeta9 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, omc_Expression_fromAbsynExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sub), 2)))));
tmpMeta4 = tmpMeta9;
goto tmp6_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,0) == 0) goto tmp6_end;
tmpMeta4 = _OMC_LIT27;
goto tmp6_done;
}
}
goto tmp6_end;
tmp6_end: ;
}
goto goto_5;
goto_5:;
MMC_THROW_INTERNAL();
goto tmp6_done;
tmp6_done:;
}
}__omcQ_24tmpVar2 = tmpMeta4;
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp10 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar3;
}
_daeSubs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _daeSubs;
}
DLLExport
modelica_metatype omc_ComponentReference_toExpCref(threadData_t *threadData, modelica_metatype _absynCref)
{
modelica_metatype _daeCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _absynCref;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_absynCref), 2))), _OMC_LIT1, omc_ComponentReference_toExpCrefSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_absynCref), 3)))));
goto tmp3_done;
}
case 4: {
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_absynCref), 2))), _OMC_LIT1, omc_ComponentReference_toExpCrefSubs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_absynCref), 3)))), omc_ComponentReference_toExpCref(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_absynCref), 4)))));
goto tmp3_done;
}
case 3: {
_absynCref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_absynCref), 2)));
goto _tailrecursive;
goto tmp3_done;
}
case 6: {
tmpMeta1 = _OMC_LIT76;
goto tmp3_done;
}
case 7: {
tmpMeta1 = _OMC_LIT76;
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
_daeCref = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _daeCref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ComponentReference_unelabSubscripts(threadData_t *threadData, modelica_metatype _inSubscriptLst)
{
modelica_metatype _outAbsynSubscriptLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSubscriptLst;
{
modelica_metatype _xs_1 = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,0) == 0) goto tmp3_end;
_xs = tmpMeta8;
_xs_1 = omc_ComponentReference_unelabSubscripts(threadData, _xs);
tmpMeta9 = mmc_mk_cons(_OMC_LIT77, _xs_1);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_e = tmpMeta12;
_xs = tmpMeta11;
_xs_1 = omc_ComponentReference_unelabSubscripts(threadData, _xs);
_e_1 = omc_Expression_unelabExp(threadData, _e);
tmpMeta14 = mmc_mk_box2(4, &Absyn_Subscript_SUBSCRIPT__desc, _e_1);
tmpMeta13 = mmc_mk_cons(tmpMeta14, _xs_1);
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_1);
tmpMeta16 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,2,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
_e = tmpMeta17;
_xs = tmpMeta16;
_xs_1 = omc_ComponentReference_unelabSubscripts(threadData, _xs);
_e_1 = omc_Expression_unelabExp(threadData, _e);
tmpMeta19 = mmc_mk_box2(4, &Absyn_Subscript_SUBSCRIPT__desc, _e_1);
tmpMeta18 = mmc_mk_cons(tmpMeta19, _xs_1);
tmpMeta1 = tmpMeta18;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta20 = MMC_CAR(tmp4_1);
tmpMeta21 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,3,1) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
_e = tmpMeta22;
_xs = tmpMeta21;
_xs_1 = omc_ComponentReference_unelabSubscripts(threadData, _xs);
_e_1 = omc_Expression_unelabExp(threadData, _e);
tmpMeta24 = mmc_mk_box2(4, &Absyn_Subscript_SUBSCRIPT__desc, _e_1);
tmpMeta23 = mmc_mk_cons(tmpMeta24, _xs_1);
tmpMeta1 = tmpMeta23;
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
_outAbsynSubscriptLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynSubscriptLst;
}
DLLExport
modelica_metatype omc_ComponentReference_unelabCref(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_metatype _subs_1 = NULL;
modelica_string _id = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr_1 = NULL;
modelica_metatype _cr = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta6;
_subs = tmpMeta7;
tmp4 += 1;
_subs_1 = omc_ComponentReference_unelabSubscripts(threadData, _subs);
tmpMeta8 = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _id, _subs_1);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta9;
_subs = tmpMeta10;
_cr = tmpMeta11;
_cr_1 = omc_ComponentReference_unelabCref(threadData, _cr);
_subs_1 = omc_ComponentReference_unelabSubscripts(threadData, _subs);
tmpMeta12 = mmc_mk_box4(4, &Absyn_ComponentRef_CREF__QUAL__desc, _id, _subs_1, _cr_1);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmp13 = omc_Flags_isSet(threadData, _OMC_LIT31);
if (1 != tmp13) goto goto_2;
tmpMeta14 = stringAppend(_OMC_LIT78,omc_ComponentReference_printComponentRefStr(threadData, _inComponentRef));
tmpMeta15 = stringAppend(tmpMeta14,_OMC_LIT22);
fputs(MMC_STRINGDATA(tmpMeta15),stdout);
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_creffromVar(threadData_t *threadData, modelica_metatype _inVar)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVar;
{
modelica_string _name = NULL;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_name = tmpMeta6;
_ty = tmpMeta7;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _name, _ty, tmpMeta8);
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_pathToCref(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_metatype _outComponentRef = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_string _i = NULL;
modelica_metatype _c = NULL;
modelica_metatype _p = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_i = tmpMeta5;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _i, _OMC_LIT1, tmpMeta6);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta7;
_inPath = _p;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_i = tmpMeta8;
_p = tmpMeta9;
_c = omc_ComponentReference_pathToCref(threadData, _p);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _i, _OMC_LIT1, tmpMeta10, _c);
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
_outComponentRef = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
DLLExport
modelica_metatype omc_ComponentReference_crefToPathIgnoreSubs(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _i = NULL;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_i = tmpMeta6;
tmpMeta7 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _i);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_i = tmpMeta8;
_c = tmpMeta9;
_p = omc_ComponentReference_crefToPathIgnoreSubs(threadData, _c);
tmpMeta10 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _i, _p);
tmpMeta1 = tmpMeta10;
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
DLLExport
modelica_metatype omc_ComponentReference_crefToPath(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentRef;
{
modelica_string _i = NULL;
modelica_metatype _p = NULL;
modelica_metatype _c = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
_i = tmpMeta6;
tmpMeta8 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _i);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_i = tmpMeta9;
_c = tmpMeta11;
_p = omc_ComponentReference_crefToPath(threadData, _c);
tmpMeta12 = mmc_mk_box3(3, &Absyn_Path_QUALIFIED__desc, _i, _p);
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
_outPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outPath;
}
DLLExport
modelica_metatype omc_ComponentReference_makeCrefQual(threadData_t *threadData, modelica_string _ident, modelica_metatype _identType, modelica_metatype _subscriptLst, modelica_metatype _componentRef)
{
modelica_metatype _outCrefQual = NULL;
modelica_metatype _subCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _ident, _identType, _subscriptLst, _componentRef);
_outCrefQual = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCrefQual;
}
DLLExport
modelica_metatype omc_ComponentReference_makeUntypedCrefIdent(threadData_t *threadData, modelica_string _ident)
{
modelica_metatype _outCrefIdent = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta2 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _ident, _OMC_LIT1, tmpMeta1);
_outCrefIdent = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _outCrefIdent;
}
DLLExport
modelica_metatype omc_ComponentReference_makeCrefIdent(threadData_t *threadData, modelica_string _ident, modelica_metatype _identType, modelica_metatype _subscriptLst)
{
modelica_metatype _outCrefIdent = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _ident, _identType, _subscriptLst);
_outCrefIdent = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outCrefIdent;
}
DLLExport
modelica_metatype omc_ComponentReference_makeDummyCref(threadData_t *threadData)
{
modelica_metatype _outCrefIdent = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCrefIdent = _OMC_LIT80;
_return: OMC_LABEL_UNUSED
return _outCrefIdent;
}
DLLExport
modelica_metatype omc_ComponentReference_createEmptyCrefMemory(threadData_t *threadData)
{
modelica_metatype _crefMemory = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_crefMemory = arrayCreate(((modelica_integer) 3), tmpMeta1);
_return: OMC_LABEL_UNUSED
return _crefMemory;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReference_hashSubscript(threadData_t *threadData, modelica_metatype _sub)
{
modelica_integer _hash;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _sub;
{
modelica_metatype _exp = NULL;
modelica_integer _i;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmp8 = mmc_unbox_integer(tmpMeta7);
_i = tmp8;
tmp1 = _i;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta9;
tmp1 = omc_Expression_hashExp(threadData, _exp);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta10;
tmp1 = omc_Expression_hashExp(threadData, _exp);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta11;
tmp1 = omc_Expression_hashExp(threadData, _exp);
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
_hash = tmp1;
_return: OMC_LABEL_UNUSED
return _hash;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_hashSubscript(threadData_t *threadData, modelica_metatype _sub)
{
modelica_integer _hash;
modelica_metatype out_hash;
_hash = omc_ComponentReference_hashSubscript(threadData, _sub);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReference_hashSubscripts2(threadData_t *threadData, modelica_metatype _dims, modelica_metatype _subs, modelica_integer _factor)
{
modelica_integer _hash;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _dims;
tmp4_2 = _subs;
{
modelica_metatype _s = NULL;
modelica_metatype _rest_dims = NULL;
modelica_metatype _rest_subs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_2);
tmpMeta9 = MMC_CDR(tmp4_2);
_rest_dims = tmpMeta7;
_s = tmpMeta8;
_rest_subs = tmpMeta9;
tmp1 = (omc_ComponentReference_hashSubscript(threadData, _s)) * (_factor) + omc_ComponentReference_hashSubscripts2(threadData, _rest_dims, _rest_subs, (((modelica_integer) 1000)) * (_factor));
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
_hash = tmp1;
_return: OMC_LABEL_UNUSED
return _hash;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_hashSubscripts2(threadData_t *threadData, modelica_metatype _dims, modelica_metatype _subs, modelica_metatype _factor)
{
modelica_integer tmp1;
modelica_integer _hash;
modelica_metatype out_hash;
tmp1 = mmc_unbox_integer(_factor);
_hash = omc_ComponentReference_hashSubscripts2(threadData, _dims, _subs, tmp1);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ComponentReference_hashSubscripts(threadData_t *threadData, modelica_metatype _tp, modelica_metatype _subs)
{
modelica_integer _hash;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _subs;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 1: {
tmp1 = omc_ComponentReference_hashSubscripts2(threadData, omc_List_fill(threadData, mmc_mk_integer(((modelica_integer) 1)), listLength(_subs)), _subs, ((modelica_integer) 1));
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
_hash = tmp1;
_return: OMC_LABEL_UNUSED
return _hash;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ComponentReference_hashSubscripts(threadData_t *threadData, modelica_metatype _tp, modelica_metatype _subs)
{
modelica_integer _hash;
modelica_metatype out_hash;
_hash = omc_ComponentReference_hashSubscripts(threadData, _tp, _subs);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
DLLExport
modelica_integer omc_ComponentReference_hashComponentRef(threadData_t *threadData, modelica_metatype _cr)
{
modelica_integer _hash;
modelica_integer tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
modelica_string _id = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr1 = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_id = tmpMeta5;
_tp = tmpMeta6;
_subs = tmpMeta7;
tmp1 = stringHashDjb2(_id) + omc_ComponentReference_hashSubscripts(threadData, _tp, _subs);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta8;
_tp = tmpMeta9;
_subs = tmpMeta10;
_cr1 = tmpMeta11;
tmp1 = stringHashDjb2(_id) + omc_ComponentReference_hashSubscripts(threadData, _tp, _subs) + omc_ComponentReference_hashComponentRef(threadData, _cr1);
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmp1 = ((modelica_integer) 0);
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
_hash = tmp1;
_return: OMC_LABEL_UNUSED
return _hash;
}
modelica_metatype boxptr_ComponentReference_hashComponentRef(threadData_t *threadData, modelica_metatype _cr)
{
modelica_integer _hash;
modelica_metatype out_hash;
_hash = omc_ComponentReference_hashComponentRef(threadData, _cr);
out_hash = mmc_mk_icon(_hash);
return out_hash;
}
DLLExport
modelica_integer omc_ComponentReference_hashComponentRefMod(threadData_t *threadData, modelica_metatype _cr, modelica_integer _mod)
{
modelica_integer _res;
modelica_integer _h;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_h = labs(omc_ComponentReference_hashComponentRef(threadData, _cr));
_res = modelica_integer_mod(_h, _mod);
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ComponentReference_hashComponentRefMod(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _mod)
{
modelica_integer tmp1;
modelica_integer _res;
modelica_metatype out_res;
tmp1 = mmc_unbox_integer(_mod);
_res = omc_ComponentReference_hashComponentRefMod(threadData, _cr, tmp1);
out_res = mmc_mk_icon(_res);
return out_res;
}
