#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "ClassInf.c"
#endif
#include "omc_simulation_settings.h"
#include "ClassInf.h"
#define _OMC_LIT0_data "quantity"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,8,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "unit"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,4,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "displayUnit"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,11,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "min"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,3,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "max"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,3,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "start"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,5,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "fixed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,5,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "nominal"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,7,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "stateSelect"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,11,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "uncertain"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,9,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "distribution"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,12,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,2,1) {_OMC_LIT10,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,2,1) {_OMC_LIT9,_OMC_LIT11}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,2,1) {_OMC_LIT8,_OMC_LIT12}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,2,1) {_OMC_LIT7,_OMC_LIT13}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,2,1) {_OMC_LIT6,_OMC_LIT14}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,2,1) {_OMC_LIT5,_OMC_LIT15}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,2,1) {_OMC_LIT4,_OMC_LIT16}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,2,1) {_OMC_LIT3,_OMC_LIT17}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,2,1) {_OMC_LIT2,_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,2,1) {_OMC_LIT1,_OMC_LIT19}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,2,1) {_OMC_LIT0,_OMC_LIT20}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,1,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "Class specialization violation: %s is a %s, which may not contain an %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,72,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT25}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(212)),_OMC_LIT23,_OMC_LIT24,_OMC_LIT26}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "Class specialization violation: %s is a %s, not a %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,53,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT28}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(151)),_OMC_LIT23,_OMC_LIT24,_OMC_LIT29}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "In class %s, class specialization 'type' can only be derived from predefined types."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,83,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT31}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(27)),_OMC_LIT23,_OMC_LIT24,_OMC_LIT32}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,9,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,41,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT35}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT34,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT36}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "- ClassInf.trans failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,25,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,2,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "equation"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,8,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "constraint"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,10,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "new definition"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,14,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "component "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,10,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "external function declaration"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,29,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
#define _OMC_LIT45_data "Unknown event"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT45,13,_OMC_LIT45_data);
#define _OMC_LIT45 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "#getStateName failed#"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,21,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT46}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
#define _OMC_LIT48_data "UNKNOWN "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT48,8,_OMC_LIT48_data);
#define _OMC_LIT48 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "OPTIMIZATION "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,13,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
#define _OMC_LIT50_data "MODEL "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT50,6,_OMC_LIT50_data);
#define _OMC_LIT50 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT50)
#define _OMC_LIT51_data "RECORD "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT51,7,_OMC_LIT51_data);
#define _OMC_LIT51 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT51)
#define _OMC_LIT52_data "BLOCK "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT52,6,_OMC_LIT52_data);
#define _OMC_LIT52 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "CONNECTOR "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,10,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data "TYPE "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,5,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "PACKAGE "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,8,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "IMPURE FUNCTION "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,16,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "FUNCTION "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,9,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "TYPE_INTEGER "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,13,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "TYPE_REAL "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,10,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "TYPE_STRING "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,12,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "TYPE_BOOL "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,10,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "TYPE_CLOCK "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,11,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "HAS_RESTRICTIONS "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,17,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
#define _OMC_LIT64_data "unknown"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT64,7,_OMC_LIT64_data);
#define _OMC_LIT64 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT64)
#define _OMC_LIT65_data "optimization"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT65,12,_OMC_LIT65_data);
#define _OMC_LIT65 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data "model"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,5,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
#define _OMC_LIT67_data "record"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT67,6,_OMC_LIT67_data);
#define _OMC_LIT67 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "block"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,5,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
#define _OMC_LIT69_data "connector"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT69,9,_OMC_LIT69_data);
#define _OMC_LIT69 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data "type"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,4,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
#define _OMC_LIT71_data "package"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT71,7,_OMC_LIT71_data);
#define _OMC_LIT71 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT71)
#define _OMC_LIT72_data "impure function"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT72,15,_OMC_LIT72_data);
#define _OMC_LIT72 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT72)
#define _OMC_LIT73_data "function"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,8,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
#define _OMC_LIT74_data "Integer"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT74,7,_OMC_LIT74_data);
#define _OMC_LIT74 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT74)
#define _OMC_LIT75_data "Real"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT75,4,_OMC_LIT75_data);
#define _OMC_LIT75 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT75)
#define _OMC_LIT76_data "String"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT76,6,_OMC_LIT76_data);
#define _OMC_LIT76 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT76)
#define _OMC_LIT77_data "Boolean"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT77,7,_OMC_LIT77_data);
#define _OMC_LIT77 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data "Clock"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,5,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
#define _OMC_LIT79_data "new def"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT79,7,_OMC_LIT79_data);
#define _OMC_LIT79 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT79)
#define _OMC_LIT80_data "has"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT80,3,_OMC_LIT80_data);
#define _OMC_LIT80 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data " equations"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,10,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,0,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
#define _OMC_LIT83_data " algorithms"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT83,11,_OMC_LIT83_data);
#define _OMC_LIT83 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT83)
#define _OMC_LIT84_data " constraints"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT84,12,_OMC_LIT84_data);
#define _OMC_LIT84 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT84)
#define _OMC_LIT85_data "ExternalObject"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT85,14,_OMC_LIT85_data);
#define _OMC_LIT85 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT85)
#define _OMC_LIT86_data "tuple"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT86,5,_OMC_LIT86_data);
#define _OMC_LIT86 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT86)
#define _OMC_LIT87_data "list"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT87,4,_OMC_LIT87_data);
#define _OMC_LIT87 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT87)
#define _OMC_LIT88_data "Option"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT88,6,_OMC_LIT88_data);
#define _OMC_LIT88 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT88)
#define _OMC_LIT89_data "meta_record"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT89,11,_OMC_LIT89_data);
#define _OMC_LIT89 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT89)
#define _OMC_LIT90_data "polymorphic"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT90,11,_OMC_LIT90_data);
#define _OMC_LIT90 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT90)
#define _OMC_LIT91_data "meta_array"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT91,10,_OMC_LIT91_data);
#define _OMC_LIT91 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT91)
#define _OMC_LIT92_data "uniontype"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT92,9,_OMC_LIT92_data);
#define _OMC_LIT92 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT92)
#define _OMC_LIT93_data "#printStateStr failed#"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT93,22,_OMC_LIT93_data);
#define _OMC_LIT93 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT93)
#include "util/modelica.h"
#include "ClassInf_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassInf_start__dispatch(threadData_t *threadData, modelica_metatype _inRestriction, modelica_metatype _inPath);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_start__dispatch,2,0) {(void*) boxptr_ClassInf_start__dispatch,0}};
#define boxvar_ClassInf_start__dispatch MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_start__dispatch)
PROTECTED_FUNCTION_STATIC modelica_string omc_ClassInf_printEventStr(threadData_t *threadData, modelica_metatype _inEvent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ClassInf_printEventStr,2,0) {(void*) boxptr_ClassInf_printEventStr,0}};
#define boxvar_ClassInf_printEventStr MMC_REFSTRUCTLIT(boxvar_lit_ClassInf_printEventStr)
DLLExport
modelica_boolean omc_ClassInf_isMetaRecord(threadData_t *threadData, modelica_metatype _inState)
{
modelica_boolean _outIsRecord;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inState;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,1) == 0) goto tmp3_end;
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
_outIsRecord = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsRecord;
}
modelica_metatype boxptr_ClassInf_isMetaRecord(threadData_t *threadData, modelica_metatype _inState)
{
modelica_boolean _outIsRecord;
modelica_metatype out_outIsRecord;
_outIsRecord = omc_ClassInf_isMetaRecord(threadData, _inState);
out_outIsRecord = mmc_mk_icon(_outIsRecord);
return out_outIsRecord;
}
DLLExport
modelica_boolean omc_ClassInf_isRecord(threadData_t *threadData, modelica_metatype _inState)
{
modelica_boolean _outIsRecord;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inState;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
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
_outIsRecord = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsRecord;
}
modelica_metatype boxptr_ClassInf_isRecord(threadData_t *threadData, modelica_metatype _inState)
{
modelica_boolean _outIsRecord;
modelica_metatype out_outIsRecord;
_outIsRecord = omc_ClassInf_isRecord(threadData, _inState);
out_outIsRecord = mmc_mk_icon(_outIsRecord);
return out_outIsRecord;
}
DLLExport
modelica_boolean omc_ClassInf_isTypeOrRecord(threadData_t *threadData, modelica_metatype _inState)
{
modelica_boolean _outIsTypeOrRecord;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inState;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 9: {
tmp1 = 1;
goto tmp3_done;
}
case 6: {
tmp1 = 1;
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
_outIsTypeOrRecord = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsTypeOrRecord;
}
modelica_metatype boxptr_ClassInf_isTypeOrRecord(threadData_t *threadData, modelica_metatype _inState)
{
modelica_boolean _outIsTypeOrRecord;
modelica_metatype out_outIsTypeOrRecord;
_outIsTypeOrRecord = omc_ClassInf_isTypeOrRecord(threadData, _inState);
out_outIsTypeOrRecord = mmc_mk_icon(_outIsTypeOrRecord);
return out_outIsTypeOrRecord;
}
DLLExport
modelica_boolean omc_ClassInf_isBasicTypeComponentName(threadData_t *threadData, modelica_string _name)
{
modelica_boolean _res;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = listMember(_name, _OMC_LIT21);
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_ClassInf_isBasicTypeComponentName(threadData_t *threadData, modelica_metatype _name)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_ClassInf_isBasicTypeComponentName(threadData, _name);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
void omc_ClassInf_isConnector(threadData_t *threadData, modelica_metatype _inState)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inState;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,2) == 0) goto tmp2_end;
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
modelica_boolean omc_ClassInf_isFunctionOrRecord(threadData_t *threadData, modelica_metatype _inState)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inState;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 11: {
tmp1 = 1;
goto tmp3_done;
}
case 6: {
tmp1 = 1;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_ClassInf_isFunctionOrRecord(threadData_t *threadData, modelica_metatype _inState)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ClassInf_isFunctionOrRecord(threadData, _inState);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_ClassInf_isFunction(threadData_t *threadData, modelica_metatype _inState)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inState;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
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
modelica_metatype boxptr_ClassInf_isFunction(threadData_t *threadData, modelica_metatype _inState)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ClassInf_isFunction(threadData, _inState);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_ClassInf_matchingState(threadData_t *threadData, modelica_metatype _inState, modelica_metatype _inStateLst)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inState;
tmp4_2 = _inStateLst;
{
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 17; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_2);
tmpMeta9 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_2);
tmpMeta11 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,3,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_2);
tmpMeta13 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,4,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmp4_2);
tmpMeta15 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,5,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_2);
tmpMeta17 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,6,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmp4_2);
tmpMeta19 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,7,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta20 = MMC_CAR(tmp4_2);
tmpMeta21 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,8,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta22 = MMC_CAR(tmp4_2);
tmpMeta23 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,9,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta24 = MMC_CAR(tmp4_2);
tmpMeta25 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,11,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta26 = MMC_CAR(tmp4_2);
tmpMeta27 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,12,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta28 = MMC_CAR(tmp4_2);
tmpMeta29 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,13,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta30 = MMC_CAR(tmp4_2);
tmpMeta31 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta30,14,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta32 = MMC_CAR(tmp4_2);
tmpMeta33 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta32,15,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,1) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta34 = MMC_CAR(tmp4_2);
tmpMeta35 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,16,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta36 = MMC_CAR(tmp4_2);
tmpMeta37 = MMC_CDR(tmp4_2);
_rest = tmpMeta37;
_inStateLst = _rest;
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_ClassInf_matchingState(threadData_t *threadData, modelica_metatype _inState, modelica_metatype _inStateLst)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_ClassInf_matchingState(threadData, _inState, _inStateLst);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_metatype omc_ClassInf_assertTrans(threadData_t *threadData, modelica_metatype _inState, modelica_metatype _event, modelica_metatype _info)
{
modelica_metatype _outState = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inState;
{
modelica_metatype _st = NULL;
modelica_string _str1 = NULL;
modelica_string _str2 = NULL;
modelica_string _str3 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_st = tmp4_1;
tmpMeta1 = omc_ClassInf_trans(threadData, _st, _event);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
_st = tmp4_1;
_str1 = omc_AbsynUtil_pathString(threadData, omc_ClassInf_getStateName(threadData, _st), _OMC_LIT22, 1, 0);
_str2 = omc_ClassInf_printStateStr(threadData, _st);
_str3 = omc_ClassInf_printEventStr(threadData, _event);
tmpMeta6 = mmc_mk_cons(_str1, mmc_mk_cons(_str2, mmc_mk_cons(_str3, MMC_REFSTRUCTLIT(mmc_nil))));
omc_Error_addSourceMessage(threadData, _OMC_LIT27, tmpMeta6, _info);
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
_outState = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outState;
}
DLLExport
void omc_ClassInf_assertValid(threadData_t *threadData, modelica_metatype _inState, modelica_metatype _inRestriction, modelica_metatype _info)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inState;
tmp3_2 = _inRestriction;
{
modelica_metatype _st = NULL;
modelica_metatype _re = NULL;
modelica_string _str1 = NULL;
modelica_string _str2 = NULL;
modelica_string _str3 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_st = tmp3_1;
_re = tmp3_2;
omc_ClassInf_valid(threadData, _st, _re);
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta5;
_st = tmp3_1;
_re = tmp3_2;
_str1 = omc_AbsynUtil_pathString(threadData, omc_ClassInf_getStateName(threadData, _st), _OMC_LIT22, 1, 0);
_str2 = omc_ClassInf_printStateStr(threadData, _st);
_str3 = omc_SCodeDump_restrictionStringPP(threadData, _re);
tmpMeta5 = mmc_mk_cons(_str1, mmc_mk_cons(_str2, mmc_mk_cons(_str3, MMC_REFSTRUCTLIT(mmc_nil))));
omc_Error_addSourceMessage(threadData, _OMC_LIT30, tmpMeta5, _info);
goto goto_1;
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
void omc_ClassInf_valid(threadData_t *threadData, modelica_metatype _inState, modelica_metatype _inRestriction)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inState;
tmp3_2 = _inRestriction;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 40; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,3,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 7: {
modelica_metatype tmpMeta5;
modelica_integer tmp6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta5);
if (0 != tmp6) goto tmp2_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmp8 = mmc_unbox_integer(tmpMeta7);
if (0 != tmp8) goto tmp2_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmp10 = mmc_unbox_integer(tmpMeta9);
if (0 != tmp10) goto tmp2_end;
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,4,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,2) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 11: {
modelica_metatype tmpMeta11;
modelica_integer tmp12;
modelica_metatype tmpMeta13;
modelica_integer tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,2) == 0) goto tmp2_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp12 = mmc_unbox_integer(tmpMeta11);
if (0 != tmp12) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,1) == 0) goto tmp2_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp14 = mmc_unbox_integer(tmpMeta13);
if (0 != tmp14) goto tmp2_end;
goto tmp2_done;
}
case 12: {
modelica_metatype tmpMeta15;
modelica_integer tmp16;
modelica_metatype tmpMeta17;
modelica_integer tmp18;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,2) == 0) goto tmp2_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp16 = mmc_unbox_integer(tmpMeta15);
if (1 != tmp16) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,1) == 0) goto tmp2_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp18 = mmc_unbox_integer(tmpMeta17);
if (1 != tmp18) goto tmp2_end;
goto tmp2_done;
}
case 13: {
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
modelica_integer tmp22;
modelica_metatype tmpMeta23;
modelica_integer tmp24;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp20 = mmc_unbox_integer(tmpMeta19);
if (0 != tmp20) goto tmp2_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmp22 = mmc_unbox_integer(tmpMeta21);
if (0 != tmp22) goto tmp2_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmp24 = mmc_unbox_integer(tmpMeta23);
if (0 != tmp24) goto tmp2_end;
goto tmp2_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,11,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,12,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,14,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,15,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 19: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,9,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 21: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 22: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 23: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,11,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 24: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,12,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 25: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 26: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,14,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 27: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,15,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 28: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 29: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,9,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 30: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 31: {
modelica_metatype tmpMeta25;
modelica_integer tmp26;
modelica_metatype tmpMeta27;
modelica_integer tmp28;
modelica_metatype tmpMeta29;
modelica_integer tmp30;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,0) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp26 = mmc_unbox_integer(tmpMeta25);
if (0 != tmp26) goto tmp2_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmp28 = mmc_unbox_integer(tmpMeta27);
if (0 != tmp28) goto tmp2_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmp30 = mmc_unbox_integer(tmpMeta29);
if (0 != tmp30) goto tmp2_end;
goto tmp2_done;
}
case 32: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,2) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 33: {
modelica_metatype tmpMeta31;
modelica_integer tmp32;
modelica_metatype tmpMeta33;
modelica_integer tmp34;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp32 = mmc_unbox_integer(tmpMeta31);
if (0 != tmp32) goto tmp2_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmp34 = mmc_unbox_integer(tmpMeta33);
if (0 != tmp34) goto tmp2_end;
goto tmp2_done;
}
case 34: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,18,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 35: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,19,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 36: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,20,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 37: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,21,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 38: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,23,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 39: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,22,2) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
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
modelica_metatype omc_ClassInf_trans(threadData_t *threadData, modelica_metatype _inState, modelica_metatype _inEvent)
{
modelica_metatype _outState = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inState;
tmp4_2 = _inEvent;
{
modelica_metatype _p = NULL;
modelica_metatype _st = NULL;
modelica_metatype _ev = NULL;
modelica_boolean _b1;
modelica_boolean _b2;
modelica_boolean _b3;
modelica_string _s = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 54; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
_p = tmpMeta6;
tmpMeta7 = mmc_mk_box5(13, &ClassInf_State_HAS__RESTRICTIONS__desc, _p, mmc_mk_boolean(0), mmc_mk_boolean(0), mmc_mk_boolean(0));
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
_p = tmpMeta8;
tmpMeta9 = mmc_mk_box2(9, &ClassInf_State_TYPE__desc, _p);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
_p = tmpMeta10;
tmpMeta11 = mmc_mk_box2(10, &ClassInf_State_PACKAGE__desc, _p);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
_p = tmpMeta12;
tmpMeta13 = mmc_mk_box5(13, &ClassInf_State_HAS__RESTRICTIONS__desc, _p, mmc_mk_boolean(0), mmc_mk_boolean(0), mmc_mk_boolean(0));
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 19: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 21: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 22: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 23: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_p = tmpMeta14;
_s = tmpMeta15;
if((!omc_ClassInf_isBasicTypeComponentName(threadData, _s)))
{
tmpMeta16 = mmc_mk_cons(omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0), MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT33, tmpMeta16);
goto goto_2;
}
tmpMeta17 = mmc_mk_box2(9, &ClassInf_State_TYPE__desc, _p);
tmpMeta1 = tmpMeta17;
goto tmp3_done;
}
case 25: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 26: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 27: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 28: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 29: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 30: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 31: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 32: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 33: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 34: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 35: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 36: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 37: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
_p = tmpMeta18;
tmpMeta19 = mmc_mk_box5(13, &ClassInf_State_HAS__RESTRICTIONS__desc, _p, mmc_mk_boolean(1), mmc_mk_boolean(0), mmc_mk_boolean(0));
tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
case 38: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 39: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 40: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 41: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 42: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 43: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 44: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 45: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 46: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_integer tmp22;
modelica_metatype tmpMeta23;
modelica_integer tmp24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp22 = mmc_unbox_integer(tmpMeta21);
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp24 = mmc_unbox_integer(tmpMeta23);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
_p = tmpMeta20;
_b2 = tmp22;
_b3 = tmp24;
tmpMeta25 = mmc_mk_box5(13, &ClassInf_State_HAS__RESTRICTIONS__desc, _p, mmc_mk_boolean(1), mmc_mk_boolean(_b2), mmc_mk_boolean(_b3));
tmpMeta1 = tmpMeta25;
goto tmp3_done;
}
case 47: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_integer tmp28;
modelica_metatype tmpMeta29;
modelica_integer tmp30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp28 = mmc_unbox_integer(tmpMeta27);
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp30 = mmc_unbox_integer(tmpMeta29);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
_p = tmpMeta26;
_b1 = tmp28;
_b2 = tmp30;
tmpMeta31 = mmc_mk_box5(13, &ClassInf_State_HAS__RESTRICTIONS__desc, _p, mmc_mk_boolean(_b1), mmc_mk_boolean(_b2), mmc_mk_boolean(1));
tmpMeta1 = tmpMeta31;
goto tmp3_done;
}
case 48: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_integer tmp34;
modelica_metatype tmpMeta35;
modelica_integer tmp36;
modelica_metatype tmpMeta37;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp34 = mmc_unbox_integer(tmpMeta33);
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp36 = mmc_unbox_integer(tmpMeta35);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
_p = tmpMeta32;
_b1 = tmp34;
_b3 = tmp36;
tmpMeta37 = mmc_mk_box5(13, &ClassInf_State_HAS__RESTRICTIONS__desc, _p, mmc_mk_boolean(_b1), mmc_mk_boolean(1), mmc_mk_boolean(_b3));
tmpMeta1 = tmpMeta37;
goto tmp3_done;
}
case 49: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,0) == 0) goto tmp3_end;
tmpMeta1 = _inState;
goto tmp3_done;
}
case 50: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,0) == 0) goto tmp3_end;
goto goto_2;
goto tmp3_done;
}
case 51: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
goto goto_2;
goto tmp3_done;
}
case 52: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
goto goto_2;
goto tmp3_done;
}
case 53: {
modelica_boolean tmp38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
_st = tmp4_1;
_ev = tmp4_2;
tmp38 = omc_Flags_isSet(threadData, _OMC_LIT37);
if (1 != tmp38) goto goto_2;
tmpMeta39 = stringAppend(_OMC_LIT38,omc_ClassInf_printStateStr(threadData, _st));
tmpMeta40 = stringAppend(tmpMeta39,_OMC_LIT39);
tmpMeta41 = stringAppend(tmpMeta40,omc_ClassInf_printEventStr(threadData, _ev));
omc_Debug_traceln(threadData, tmpMeta41);
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
_outState = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outState;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ClassInf_start__dispatch(threadData_t *threadData, modelica_metatype _inRestriction, modelica_metatype _inPath)
{
modelica_metatype _outState = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inRestriction;
tmp4_2 = _inPath;
{
modelica_metatype _p = NULL;
modelica_boolean _isExpandable;
modelica_boolean _isImpure;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 22; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta6 = mmc_mk_box2(3, &ClassInf_State_UNKNOWN__desc, _p);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta7 = mmc_mk_box2(4, &ClassInf_State_OPTIMIZATION__desc, _p);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta8 = mmc_mk_box2(5, &ClassInf_State_MODEL__desc, _p);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta9 = mmc_mk_box2(6, &ClassInf_State_RECORD__desc, _p);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta10 = mmc_mk_box2(7, &ClassInf_State_BLOCK__desc, _p);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta11;
modelica_integer tmp12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp12 = mmc_unbox_integer(tmpMeta11);
_isExpandable = tmp12;
_p = tmp4_2;
tmpMeta13 = mmc_mk_box3(8, &ClassInf_State_CONNECTOR__desc, _p, mmc_mk_boolean(_isExpandable));
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta14 = mmc_mk_box2(9, &ClassInf_State_TYPE__desc, _p);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta15 = mmc_mk_box2(10, &ClassInf_State_PACKAGE__desc, _p);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_integer tmp18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,0,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmp18 = mmc_unbox_integer(tmpMeta17);
_isImpure = tmp18;
_p = tmp4_2;
tmpMeta19 = mmc_mk_box3(11, &ClassInf_State_FUNCTION__desc, _p, mmc_mk_boolean(_isImpure));
tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_integer tmp22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,1,1) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
tmp22 = mmc_unbox_integer(tmpMeta21);
_isImpure = tmp22;
_p = tmp4_2;
tmpMeta23 = mmc_mk_box3(11, &ClassInf_State_FUNCTION__desc, _p, mmc_mk_boolean(_isImpure));
tmpMeta1 = tmpMeta23;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,3,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta25 = mmc_mk_box3(11, &ClassInf_State_FUNCTION__desc, _p, mmc_mk_boolean(0));
tmpMeta1 = tmpMeta25;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta26 = mmc_mk_box3(11, &ClassInf_State_FUNCTION__desc, _p, mmc_mk_boolean(0));
tmpMeta1 = tmpMeta26;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta27 = mmc_mk_box3(11, &ClassInf_State_FUNCTION__desc, _p, mmc_mk_boolean(0));
tmpMeta1 = tmpMeta27;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta28 = mmc_mk_box2(12, &ClassInf_State_ENUMERATION__desc, _p);
tmpMeta1 = tmpMeta28;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta29 = mmc_mk_box2(14, &ClassInf_State_TYPE__INTEGER__desc, _p);
tmpMeta1 = tmpMeta29;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta30 = mmc_mk_box2(15, &ClassInf_State_TYPE__REAL__desc, _p);
tmpMeta1 = tmpMeta30;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta31 = mmc_mk_box2(16, &ClassInf_State_TYPE__STRING__desc, _p);
tmpMeta1 = tmpMeta31;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta32 = mmc_mk_box2(17, &ClassInf_State_TYPE__BOOL__desc, _p);
tmpMeta1 = tmpMeta32;
goto tmp3_done;
}
case 18: {
modelica_boolean tmp33;
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmp33 = omc_Config_synchronousFeaturesAllowed(threadData);
if (1 != tmp33) goto goto_2;
tmpMeta34 = mmc_mk_box2(18, &ClassInf_State_TYPE__CLOCK__desc, _p);
tmpMeta1 = tmpMeta34;
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta35;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,0) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta35 = mmc_mk_box2(19, &ClassInf_State_TYPE__ENUM__desc, _p);
tmpMeta1 = tmpMeta35;
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta36;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,1) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta36 = mmc_mk_box3(25, &ClassInf_State_META__UNIONTYPE__desc, _p, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inRestriction), 2))));
tmpMeta1 = tmpMeta36;
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta37;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,5) == 0) goto tmp3_end;
_p = tmp4_2;
tmpMeta37 = mmc_mk_box2(24, &ClassInf_State_META__RECORD__desc, _p);
tmpMeta1 = tmpMeta37;
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
_outState = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outState;
}
DLLExport
modelica_metatype omc_ClassInf_start(threadData_t *threadData, modelica_metatype _inRestriction, modelica_metatype _inPath)
{
modelica_metatype _outState = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outState = omc_ClassInf_start__dispatch(threadData, _inRestriction, omc_AbsynUtil_makeFullyQualified(threadData, _inPath));
_return: OMC_LABEL_UNUSED
return _outState;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ClassInf_printEventStr(threadData_t *threadData, modelica_metatype _inEvent)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inEvent;
{
modelica_string _name = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT40;
goto tmp3_done;
}
case 5: {
tmp1 = _OMC_LIT41;
goto tmp3_done;
}
case 7: {
tmp1 = _OMC_LIT42;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta5;
tmpMeta6 = stringAppend(_OMC_LIT43,_name);
tmp1 = tmpMeta6;
goto tmp3_done;
}
case 6: {
tmp1 = _OMC_LIT44;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmp1 = _OMC_LIT45;
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
modelica_metatype omc_ClassInf_getStateName(threadData_t *threadData, modelica_metatype _inState)
{
modelica_metatype _outPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inState;
{
modelica_metatype _p = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta5;
tmpMeta1 = _p;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta6;
tmpMeta1 = _p;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta7;
tmpMeta1 = _p;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta8;
tmpMeta1 = _p;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta9;
tmpMeta1 = _p;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta10;
tmpMeta1 = _p;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta11;
tmpMeta1 = _p;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta12;
tmpMeta1 = _p;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta13;
tmpMeta1 = _p;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta14;
tmpMeta1 = _p;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta15;
tmpMeta1 = _p;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta16;
tmpMeta1 = _p;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta17;
tmpMeta1 = _p;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta18;
tmpMeta1 = _p;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta19;
tmpMeta1 = _p;
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta20;
tmpMeta1 = _p;
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,1) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta21;
tmpMeta1 = _p;
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,1) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta22;
tmpMeta1 = _p;
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,1) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta23;
tmpMeta1 = _p;
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,1) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta24;
tmpMeta1 = _p;
goto tmp3_done;
}
case 23: {
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,1) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta25;
tmpMeta1 = _p;
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,1) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta26;
tmpMeta1 = _p;
goto tmp3_done;
}
case 25: {
modelica_metatype tmpMeta27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,2) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta27;
tmpMeta1 = _p;
goto tmp3_done;
}
case 26: {
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,1) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta28;
tmpMeta1 = _p;
goto tmp3_done;
}
case 27: {
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,1) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta29;
tmpMeta1 = _p;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta1 = _OMC_LIT47;
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
void omc_ClassInf_printState(threadData_t *threadData, modelica_metatype _inState)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inState;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 16; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta5;
omc_Print_printBuf(threadData, _OMC_LIT48);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta6;
omc_Print_printBuf(threadData, _OMC_LIT49);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 2: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta7;
omc_Print_printBuf(threadData, _OMC_LIT50);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 3: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta8;
omc_Print_printBuf(threadData, _OMC_LIT51);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta9;
omc_Print_printBuf(threadData, _OMC_LIT52);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 5: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,2) == 0) goto tmp2_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta10;
omc_Print_printBuf(threadData, _OMC_LIT53);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 6: {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,1) == 0) goto tmp2_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta11;
omc_Print_printBuf(threadData, _OMC_LIT54);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 7: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,1) == 0) goto tmp2_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta12;
omc_Print_printBuf(threadData, _OMC_LIT55);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 8: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,2) == 0) goto tmp2_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp15 = mmc_unbox_integer(tmpMeta14);
if (1 != tmp15) goto tmp2_end;
_p = tmpMeta13;
omc_Print_printBuf(threadData, _OMC_LIT56);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 9: {
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,2) == 0) goto tmp2_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta16;
omc_Print_printBuf(threadData, _OMC_LIT57);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 10: {
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,11,1) == 0) goto tmp2_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta17;
omc_Print_printBuf(threadData, _OMC_LIT58);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 11: {
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,12,1) == 0) goto tmp2_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta18;
omc_Print_printBuf(threadData, _OMC_LIT59);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 12: {
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,1) == 0) goto tmp2_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta19;
omc_Print_printBuf(threadData, _OMC_LIT60);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 13: {
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,14,1) == 0) goto tmp2_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta20;
omc_Print_printBuf(threadData, _OMC_LIT61);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 14: {
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,15,1) == 0) goto tmp2_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta21;
omc_Print_printBuf(threadData, _OMC_LIT62);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
goto tmp2_done;
}
case 15: {
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta22;
omc_Print_printBuf(threadData, _OMC_LIT63);
omc_Print_printBuf(threadData, omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0));
omc_Print_printBuf(threadData, omc_ClassInf_printStateStr(threadData, _inState));
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
modelica_string omc_ClassInf_printStateStr(threadData_t *threadData, modelica_metatype _inState)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inState;
{
modelica_boolean _b1;
modelica_boolean _b2;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 26; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT64;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT65;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT66;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT67;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT68;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmp1 = _OMC_LIT69;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT70;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT71;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (1 != tmp7) goto tmp3_end;
tmp1 = _OMC_LIT72;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmp1 = _OMC_LIT73;
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT74;
goto tmp3_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT75;
goto tmp3_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT76;
goto tmp3_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT77;
goto tmp3_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT78;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_integer tmp11;
modelica_metatype tmpMeta12;
modelica_integer tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp9 = mmc_unbox_integer(tmpMeta8);
if (0 != tmp9) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp11 = mmc_unbox_integer(tmpMeta10);
if (0 != tmp11) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp13 = mmc_unbox_integer(tmpMeta12);
if (0 != tmp13) goto tmp3_end;
tmp1 = _OMC_LIT79;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
modelica_integer tmp17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp15 = mmc_unbox_integer(tmpMeta14);
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp17 = mmc_unbox_integer(tmpMeta16);
_b1 = tmp15;
_b2 = tmp17;
tmpMeta18 = stringAppend(_OMC_LIT80,(_b1?_OMC_LIT81:_OMC_LIT82));
tmpMeta19 = stringAppend(tmpMeta18,(_b2?_OMC_LIT83:_OMC_LIT82));
tmpMeta20 = stringAppend(tmpMeta19,(_b1?_OMC_LIT84:_OMC_LIT82));
tmp1 = tmpMeta20;
goto tmp3_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT85;
goto tmp3_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT86;
goto tmp3_done;
}
case 19: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT87;
goto tmp3_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT88;
goto tmp3_done;
}
case 21: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT89;
goto tmp3_done;
}
case 22: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT90;
goto tmp3_done;
}
case 23: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,1) == 0) goto tmp3_end;
tmp1 = _OMC_LIT91;
goto tmp3_done;
}
case 24: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,2) == 0) goto tmp3_end;
tmp1 = _OMC_LIT92;
goto tmp3_done;
}
case 25: {
tmp1 = _OMC_LIT93;
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
