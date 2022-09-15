#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "InteractiveUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "InteractiveUtil.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,8) {&ErrorTypes_MessageType_SCRIPTING__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "Class %s not found inside class %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,35,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(555)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,1,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "Class %s not found in scope %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,31,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT8}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(3)),_OMC_LIT6,_OMC_LIT7,_OMC_LIT9}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "<TOP>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,5,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,1,4) {&Absyn_Within_TOP__desc,}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "public"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,6,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,0,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,1,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,1,4) {&Absyn_Each_NON__EACH__desc,}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,1,3) {&Absyn_EqMod_NOMOD__desc,}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT18,0.0);
#define _OMC_LIT18 MMC_REFREALLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT14,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "- InteractiveUtil.namedargToModification failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,48,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "InteractiveUtil.recordConstructorToModification failed, exp="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,60,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,1,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
#define _OMC_LIT23_data "annotate"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT23,8,_OMC_LIT23_data);
#define _OMC_LIT23 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "comment"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,7,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "Failed in replaceInnerClass\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,28,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "\n  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,3,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "Failed to insert class %s %s the available classes were:%s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,58,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT28}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(213)),_OMC_LIT0,_OMC_LIT7,_OMC_LIT29}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "OpenModelica"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,12,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,1,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "\", \""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,4,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data ", \""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,3,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,2,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data ", \"{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,4,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "}\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,2,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data ", {"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,3,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,1,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "\"input\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,7,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "\"output\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,8,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "\"unspecified\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,13,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "\"discrete\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,10,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
#define _OMC_LIT44_data "\"parameter\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT44,11,_OMC_LIT44_data);
#define _OMC_LIT44 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT44)
#define _OMC_LIT45_data "\"constant\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT45,10,_OMC_LIT45_data);
#define _OMC_LIT45 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "\"parglobal\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,11,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "\"parlocal\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,10,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
#define _OMC_LIT48_data "true"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT48,4,_OMC_LIT48_data);
#define _OMC_LIT48 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "false"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,5,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
#define _OMC_LIT50_data "\"inner\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT50,7,_OMC_LIT50_data);
#define _OMC_LIT50 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT50)
#define _OMC_LIT51_data "\"outer\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT51,7,_OMC_LIT51_data);
#define _OMC_LIT51 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT51)
#define _OMC_LIT52_data "\"none\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT52,6,_OMC_LIT52_data);
#define _OMC_LIT52 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "\"innerouter\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,12,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data "},{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,3,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,1,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "$Any"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,4,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "nfAPI"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,5,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "Enables experimental new instantiation use in the OMC API."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,58,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT59,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT58}};
#define _OMC_LIT59 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT59)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT60,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(171)),_OMC_LIT57,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT59}};
#define _OMC_LIT60 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "Real"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,4,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "Integer"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,7,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "Boolean"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,7,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
#define _OMC_LIT64_data "String"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT64,6,_OMC_LIT64_data);
#define _OMC_LIT64 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT64)
#define _OMC_LIT65_data "\"-\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT65,3,_OMC_LIT65_data);
#define _OMC_LIT65 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data "\"co\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,4,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT67,2,1) {_OMC_LIT14,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT67 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "\"cl\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,4,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
#define _OMC_LIT69_data "checkModel"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT69,10,_OMC_LIT69_data);
#define _OMC_LIT69 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT69)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT70,1,3) {&Flags_FlagVisibility_INTERNAL__desc,}};
#define _OMC_LIT70 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT70)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT71,2,4) {&Flags_FlagData_BOOL__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT71 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT71)
#define _OMC_LIT72_data "Set when checkModel is used to turn on specific features for checking."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT72,70,_OMC_LIT72_data);
#define _OMC_LIT72 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT72)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT73,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT72}};
#define _OMC_LIT73 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT73)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT74,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(31)),_OMC_LIT69,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT70,_OMC_LIT71,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT73}};
#define _OMC_LIT74 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT74)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT75,3,3) {&Absyn_Program_PROGRAM__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT12}};
#define _OMC_LIT75 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT75)
#define _OMC_LIT76_data "\n\npackage GraphicalAnnotationsProgram____ end GraphicalAnnotationsProgram____;\n\n// Not implemented yet!\n  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT76,106,_OMC_LIT76_data);
#define _OMC_LIT76 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT76)
#define _OMC_LIT77_data "<1.x annotations>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT77,17,_OMC_LIT77_data);
#define _OMC_LIT77 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data "std"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,3,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT79,1,4) {&Flags_FlagVisibility_EXTERNAL__desc,}};
#define _OMC_LIT79 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT79)
#define _OMC_LIT80_data "1.x"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT80,3,_OMC_LIT80_data);
#define _OMC_LIT80 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT80)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT81,2,0) {_OMC_LIT80,MMC_IMMEDIATE(MMC_TAGFIXNUM(10))}};
#define _OMC_LIT81 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data "2.x"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,3,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT83,2,0) {_OMC_LIT82,MMC_IMMEDIATE(MMC_TAGFIXNUM(20))}};
#define _OMC_LIT83 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT83)
#define _OMC_LIT84_data "3.0"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT84,3,_OMC_LIT84_data);
#define _OMC_LIT84 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT84)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT85,2,0) {_OMC_LIT84,MMC_IMMEDIATE(MMC_TAGFIXNUM(30))}};
#define _OMC_LIT85 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT85)
#define _OMC_LIT86_data "3.1"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT86,3,_OMC_LIT86_data);
#define _OMC_LIT86 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT86)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT87,2,0) {_OMC_LIT86,MMC_IMMEDIATE(MMC_TAGFIXNUM(31))}};
#define _OMC_LIT87 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT87)
#define _OMC_LIT88_data "3.2"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT88,3,_OMC_LIT88_data);
#define _OMC_LIT88 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT88)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT89,2,0) {_OMC_LIT88,MMC_IMMEDIATE(MMC_TAGFIXNUM(32))}};
#define _OMC_LIT89 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT89)
#define _OMC_LIT90_data "3.3"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT90,3,_OMC_LIT90_data);
#define _OMC_LIT90 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT90)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT91,2,0) {_OMC_LIT90,MMC_IMMEDIATE(MMC_TAGFIXNUM(33))}};
#define _OMC_LIT91 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT91)
#define _OMC_LIT92_data "3.4"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT92,3,_OMC_LIT92_data);
#define _OMC_LIT92 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT92)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT93,2,0) {_OMC_LIT92,MMC_IMMEDIATE(MMC_TAGFIXNUM(34))}};
#define _OMC_LIT93 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT93)
#define _OMC_LIT94_data "3.5"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT94,3,_OMC_LIT94_data);
#define _OMC_LIT94 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT94)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT95,2,0) {_OMC_LIT94,MMC_IMMEDIATE(MMC_TAGFIXNUM(35))}};
#define _OMC_LIT95 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT95)
#define _OMC_LIT96_data "latest"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT96,6,_OMC_LIT96_data);
#define _OMC_LIT96 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT96)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT97,2,0) {_OMC_LIT96,MMC_IMMEDIATE(MMC_TAGFIXNUM(1000))}};
#define _OMC_LIT97 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT97)
#define _OMC_LIT98_data "experimental"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT98,12,_OMC_LIT98_data);
#define _OMC_LIT98 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT98)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT99,2,0) {_OMC_LIT98,MMC_IMMEDIATE(MMC_TAGFIXNUM(9999))}};
#define _OMC_LIT99 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT99)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT100,2,1) {_OMC_LIT99,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT100 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT100)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT101,2,1) {_OMC_LIT97,_OMC_LIT100}};
#define _OMC_LIT101 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT101)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT102,2,1) {_OMC_LIT95,_OMC_LIT101}};
#define _OMC_LIT102 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT102)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT103,2,1) {_OMC_LIT93,_OMC_LIT102}};
#define _OMC_LIT103 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT103)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT104,2,1) {_OMC_LIT91,_OMC_LIT103}};
#define _OMC_LIT104 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT104)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT105,2,1) {_OMC_LIT89,_OMC_LIT104}};
#define _OMC_LIT105 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT105)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT106,2,1) {_OMC_LIT87,_OMC_LIT105}};
#define _OMC_LIT106 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT106)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT107,2,1) {_OMC_LIT85,_OMC_LIT106}};
#define _OMC_LIT107 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT107)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT108,2,1) {_OMC_LIT83,_OMC_LIT107}};
#define _OMC_LIT108 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT108)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT109,2,1) {_OMC_LIT81,_OMC_LIT108}};
#define _OMC_LIT109 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT109)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT110,3,10) {&Flags_FlagData_ENUM__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1000)),_OMC_LIT109}};
#define _OMC_LIT110 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT110)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT111,2,1) {_OMC_LIT98,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT111 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT111)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT112,2,1) {_OMC_LIT96,_OMC_LIT111}};
#define _OMC_LIT112 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT112)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT113,2,1) {_OMC_LIT94,_OMC_LIT112}};
#define _OMC_LIT113 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT113)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT114,2,1) {_OMC_LIT92,_OMC_LIT113}};
#define _OMC_LIT114 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT114)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT115,2,1) {_OMC_LIT90,_OMC_LIT114}};
#define _OMC_LIT115 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT115)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT116,2,1) {_OMC_LIT88,_OMC_LIT115}};
#define _OMC_LIT116 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT116)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT117,2,1) {_OMC_LIT86,_OMC_LIT116}};
#define _OMC_LIT117 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT117)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT118,2,1) {_OMC_LIT82,_OMC_LIT117}};
#define _OMC_LIT118 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT118)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT119,2,1) {_OMC_LIT80,_OMC_LIT118}};
#define _OMC_LIT119 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT119)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT120,2,3) {&Flags_ValidOptions_STRING__OPTION__desc,_OMC_LIT119}};
#define _OMC_LIT120 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT120)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT121,1,1) {_OMC_LIT120}};
#define _OMC_LIT121 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT121)
#define _OMC_LIT122_data "Sets the language standard that should be used."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT122,47,_OMC_LIT122_data);
#define _OMC_LIT122 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT122)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT123,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT122}};
#define _OMC_LIT123 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT123)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT124,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(8)),_OMC_LIT78,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT79,_OMC_LIT110,_OMC_LIT121,_OMC_LIT123}};
#define _OMC_LIT124 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT124)
#define _OMC_LIT125_data "strict"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT125,6,_OMC_LIT125_data);
#define _OMC_LIT125 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT125)
#define _OMC_LIT126_data "Enables stricter enforcement of Modelica language rules."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT126,56,_OMC_LIT126_data);
#define _OMC_LIT126 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT126)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT127,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT126}};
#define _OMC_LIT127 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT127)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT128,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(47)),_OMC_LIT125,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT79,_OMC_LIT71,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT127}};
#define _OMC_LIT128 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT128)
#define _OMC_LIT129_data "\n\npackage GraphicalAnnotationsProgram____  end GraphicalAnnotationsProgram____;\n\n// Constants.diagramProgram:\nrecord GraphicItem\n  Boolean visible=true;\nend GraphicItem;\n\nrecord CoordinateSystem\n  Real extent[2,2];\nend CoordinateSystem;\n\nrecord Diagram\n  CoordinateSystem coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}});\nend Diagram;\n\ntype LinePattern= enumeration(None, Solid, Dash, Dot, DashDot, DashDotDot );\ntype Arrow= enumeration(None, Open, Filled , Half );\ntype FillPattern= enumeration(None, Solid, Horizontal, Vertical, Cross, Forward, Backward, CrossDiag, HorizontalCylinder, VerticalCylinder, Sphere );\ntype BorderPattern= enumeration(None, Raised, Sunken, Engraved );\ntype TextStyle= enumeration(Bold, Italic, Underline );\n\nrecord Line\n  Boolean visible=true;\n  Real points[:,2];\n  Integer color[3]={0,0,0};\n  LinePattern pattern=LinePattern.Solid;\n  Real thickness=0.25;\n  Arrow arrow[2]={Arrow.None,Arrow.None};\n  Real arrowSize=3.0;\n  Boolean smooth=false;\nend Line;\n\nrecord Polygon\n  Boolean visible=true;\n  Integer lineColor[3]={0,0,0};\n  Integer fillColor[3]={0,0,0};\n  LinePattern pattern=LinePattern.Solid;\n  FillPattern fillPattern=FillPattern.None;\n  Real lineThickness=0.25;\n  Real points[:,2];\n  Boolean smooth=false;\nend Polygon;\n\nrecord Rectangle\n  Boolean visible=true;\n  Integer lineColor[3]={0,0,0};\n  Integer fillColor[3]={0,0,0};\n  LinePattern pattern=LinePattern.Solid;\n  FillPattern fillPattern=FillPattern.None;\n  Real lineThickness=0.25;\n  BorderPattern borderPattern=BorderPattern.None;\n  Real extent[2,2];\n  Real radius=0.0;\nend Rectangle;\n\nrecord Ellipse\n  Boolean visible=true;\n  Integer lineColor[3]={0,0,0};\n  Integer fillColor[3]={0,0,0};\n  LinePattern pattern=LinePattern.Solid;\n  FillPattern fillPattern=FillPattern.None;\n  Real lineThickness=0.25;\n  Real extent[2,2];\nend Ellipse;\n\nrecord Text\n  Boolean visible=true;\n  Integer lineColor[3]={0,0,0};\n  Integer fillColor[3]={0,0,0};\n  LinePattern pattern=LinePattern.Solid;\n  FillPattern fillPattern=FillPattern.None;\n  Real lineThickness=0.25;\n  Real extent[2,2];\n  String textString;\n  Real fontSize=0.0;\n  String fontName=\"\";\n  TextStyle textStyle[:];\nend Text;\n\nrecord Bitmap\n  Boolean visible=true;\n  Real extent[2,2];\n  String fileName=\"\";\n  String imageSource=\"\";\nend Bitmap;\n\n// Constants.iconProgram:\nrecord Icon\n  CoordinateSystem coordinateSystem(extent={{-10.0,-10.0},{10.0,10.0}});\nend Icon;\n\n// Constants.graphicsProgram\n// ...\n// Constants.lineProgram\n// ...\n\n// Constants.placementProgram:\nrecord Transformation\n  Real x=0.0;\n  Real y=0.0;\n  Real scale=1.0;\n  Real aspectRatio=1.0;\n  Boolean flipHorizontal=false;\n  Boolean flipVertical=false;\n  Real rotation=0.0;\nend Transformation;\n\nrecord Placement\n  Boolean visible=true;\n  Transformation transformation;\n  Transformation iconTransformation;\nend Placement;\n\n  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT129,2835,_OMC_LIT129_data);
#define _OMC_LIT129 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT129)
#define _OMC_LIT130_data "<2.x annotations>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT130,17,_OMC_LIT130_data);
#define _OMC_LIT130 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT130)
#define _OMC_LIT131_data "\n\npackage GraphicalAnnotationsProgram____ end     GraphicalAnnotationsProgram____;\n\n// type DrawingUnit = Real/*(final unit=\"mm\")*/;\n// type Point = DrawingUnit[2] \"{x, y}\";\n// type Extent = Point[2] \"Defines a rectangular area {{x1, y1}, {x2, y2}}\";\n\n//partial\nrecord GraphicItem\n  Boolean visible = true;\n  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};\n  Real rotation(quantity=\"angle\", unit=\"deg\")=0;\nend GraphicItem;\n\nrecord CoordinateSystem\n  Real extent[2,2]/*(each final unit=\"mm\")*/;\n  Boolean preserveAspectRatio;\n  Real initialScale;\n  Real grid[2]/*(each final unit=\"mm\")*/;\nend CoordinateSystem;\n\n// example\n// CoordinateSystem(extent = {{-10, -10}, {10, 10}});\n// i.e. a coordinate system with width 20 units and height 20 units.\n\nrecord Icon \"Representation of the icon layer\"\n  CoordinateSystem coordinateSystem;\n  //GraphicItem[:] graphics;\nend Icon;\n\nrecord Diagram \"Representation of the diagram layer\"\n  CoordinateSystem coordinateSystem;\n  //GraphicItem[:] graphics;\nend Diagram;\n\ntype Color = Integer[3](each min=0, each max=255) \"RGB representation\";\n// constant Color Black = {0, 0, 0}; // zeros(3);\ntype LinePattern = enumeration(None, Solid, Dash, Dot, DashDot, DashDotDot);\ntype FillPattern = enumeration(None, Solid, Horizontal, Vertical, Cross, Forward, Backward, CrossDiag, HorizontalCylinder, VerticalCylinder, Sphere);\ntype BorderPattern = enumeration(None, Raised, Sunken, Engraved);\ntype Smooth = enumeration(None, Bezier);\ntype EllipseClosure = enumeration(None, Chord, Radial); // added in Modelica 3.4\n\ntype Arrow = enumeration(None, Open, Filled, Half);\ntype TextStyle = enumeration(Bold, Italic, UnderLine);\ntype TextAlignment = enumeration(Left, Center, Right);\n\n// Filled shapes have the following attributes for the border and interior.\nrecord FilledShape \"Style attributes for filled shapes\"\n  Integer lineColor[3] = {0, 0, 0} \"Color of border line\";\n  Integer fillColor[3] = {0, 0, 0} \"Interior fill color\";\n  LinePattern pattern = LinePattern.Solid \"Border line pattern\";\n  FillPattern fillPattern = FillPattern.None \"Interior fill pattern\";\n  Real lineThickness = 0.25 \"Line thickness\";\nend FilledShape;\n\nrecord Transformation\n  Real origin[2]/*(each final unit=\"mm\")*/;\n  Real extent[2,2]/*(each final unit=\"mm\")*/;\n  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/;\nend Transformation;\n\nrecord Placement\n  Boolean visible = true;\n  Transformation transformation \"Placement in the dagram layer\";\n  Transformation iconTransformation \"Placement in the icon layer\";\nend Placement;\n\nrecord IconMap\n  Real extent[2,2]/*(each final unit=\"mm\")*/ = {{0, 0}, {0, 0}};\n  Boolean primitivesVisible = true;\nend IconMap;\n\nrecord DiagramMap\n  Real extent[2,2]/*(each final unit=\"mm\")*/ = {{0, 0}, {0, 0}};\n  Boolean primitivesVisible = true;\nend DiagramMap;\n\nrecord Line\n  //extends GraphicItem;\n  Boolean visible = true;\n  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};\n  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/ = 0;\n  // end GraphicItem\n\n  Real points[:, 2]/*(each final unit=\"mm\")*/;\n  Integer color[3] = {0, 0, 0};\n  LinePattern pattern = LinePattern.Solid;\n  Real thickness/*(final unit=\"mm\")*/ = 0.25;\n  Arrow arrow[2] = {Arrow.None, Arrow.None} \"{start arrow, end arrow}\";\n  Real arrowSize/*(final unit=\"mm\")*/ = 3;\n  Smooth smooth = Smooth.None \"Spline\";\nend Line;\n\nrecord Polygon\n  //extends GraphicItem;\n  Boolean visible = true;\n  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};\n  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/ = 0;\n  // end GraphicItem\n\n  //extends FilledShape;\n  Integer lineColor[3] = {0, 0, 0} \"Color of border line\";\n  Integer fillColor[3] = {0, 0, 0} \"Interior fill color\";\n  LinePattern pattern = LinePattern.Solid \"Border line pattern\";\n  FillPattern fillPattern = FillPattern.None \"Interior fill pattern\";\n  Real lineThickness = 0.25 \"Line thickness\";\n  // end FilledShape\n\n  Real points[:,2]/*(each final unit=\"mm\")*/;\n  Smooth smooth = Smooth.None \"Spline outline\";\nend Polygon;\n\nrecord Rectangle\n  //extends GraphicItem;\n  Boolean visible = true;\n  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};\n  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/ = 0;\n  // end GraphicItem\n\n  //extends FilledShape;\n  Integer lineColor[3] = {0, 0, 0} \"Color of border line\";\n  Integer fillColor[3] = {0, 0, 0} \"Interior fill color\";\n  LinePattern pattern = LinePattern.Solid \"Border line pattern\";\n  FillPattern fillPattern = FillPattern.None \"Interior fill pattern\";\n  Real lineThickness = 0.25 \"Line thickness\";\n  // end FilledShape\n\n  BorderPattern borderPattern = BorderPattern.None;\n  Real extent[2,2]/*(each final unit=\"mm\")*/;\n  Real radius/*(final unit=\"mm\")*/ = 0 \"Corner radius\";\nend Rectangle;\n\nrecord Ellipse\n  //extends GraphicItem;\n  Boolean visible = true;\n  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};\n  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/=0;\n  // end GraphicItem\n\n  //extends FilledShape;\n  Integer lineColor[3] = {0, 0, 0} \"Color of border line\";\n  Integer fillColor[3] = {0, 0, 0} \"Interior fill color\";\n  LinePattern pattern = LinePattern.Solid \"Border line pattern\";\n  FillPattern fillPattern = FillPattern.None \"Interior fill pattern\";\n  Real lineThickness = 0.25 \"Line thickness\";\n  // end FilledShape\n\n  Real extent[2,2]/*(each final unit=\"mm\")*/;\n  Real startAngle/*(quantity=\"angle\", unit=\"deg\")*/ = 0;\n  Real endAngle/*(quantity=\"angle\", unit=\"deg\")*/ = 360;\n  EllipseClosure closure = if startAngle == 0 and endAngle == 360 then EllipseClosure.Chord else EllipseClosure.Radial; // added in Modelica 3.4\nend Ellipse;\n\nrecord Text\n  //extends GraphicItem;\n  Boolean visible = true;\n  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};\n  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/ = 0;\n  // end GraphicItem\n\n  //extends FilledShape;\n  Integer lineColor[3] = {0, 0, 0} \"Color of border line\";\n  Integer fillColor[3] = {0, 0, 0} \"Interior fill color\";\n  LinePattern pattern = LinePattern.Solid \"Border line pattern\";\n  FillPattern fillPattern = FillPattern.None \"Interior fill pattern\";\n  Real lineThickness = 0.25 \"Line thickness\";\n  // end FilledShape\n\n  Real extent[2,2]/*(each final unit=\"mm\")*/ = {{-10, -10}, {10, 10}};\n  String textString = \"\";\n  Real fontSize = 0 \"unit pt\";\n  Integer textColor[3] = {-1, -1, -1} \"defaults to fillColor\";\n  String fontName = \"\";\n  TextStyle textStyle[:] = fill(TextStyle.Bold, 0);\n  TextAlignment horizontalAlignment = TextAlignment.Center;\nend Text;\n\nrecord Bitmap\n  //extends GraphicItem;\n  Boolean visible = true;\n  Real origin[2]/*(each final unit=\"mm\")*/ = {0.0, 0.0};\n  Real rotation/*(quantity=\"angle\", unit=\"deg\")*/=0;\n  // end GraphicItem\n\n  Real extent[2,2]/*(each final unit=\"mm\")*/;\n  String fileName = \"\" \"Name of bitmap file\";\n  String imageSource =  \"\" \"Base64 representation of bitmap\";\nend Bitmap;\n\n// dynamic annotations\n// annotation (\n//   Icon(graphics={Rectangle(\n//     extent=DynamicSelect({{0,0},{20,20}},{{0,0},{20,level}}),\n//     fillColor=DynamicSelect({0,0,255},\n//     if overflow then {255,0,0} else {0,0,255}))}\n//   );\n\n// events & interaction\nrecord OnMouseDownSetBoolean\n   Boolean variable \"Name of variable to change when mouse button pressed\";\n   Boolean value \"Assigned value\";\nend OnMouseDownSetBoolean;\n\n// interaction={OnMouseDown(on, true), OnMouseUp(on, false)};\nrecord OnMouseMoveXSetReal\n   Real xVariable \"Name of variable to change when cursor moved in x direction\";\n   Real minValue;\n   Real maxValue;\nend OnMouseMoveXSetReal;\n\n//\nrecord OnMouseMoveYSetReal\n   Real yVariable \"Name of variable to change when cursor moved in y direction\";\n   Real minValue;\n   Real maxValue;\nend OnMouseMoveYSetReal;\n\nrecord OnMouseDownEditInteger\n   Integer variable \"Name of variable to change\";\nend OnMouseDownEditInteger;\n\nrecord OnMouseDownEditReal\n   Real variable \"Name of variable to change\";\nend OnMouseDownEditReal;\n\n//\nrecord OnMouseDownEditString\n   String variable \"Name of variable to change\";\nend OnMouseDownEditString;\n\n//\n// annotation(defaultComponentName = \"name\")\n// annotation(missingInnerMessage = \"message\")\n//\n// model World\n//   annotation(defaultComponentName = \"world\",\n//   defaultComponentPrefixes = \"inner replaceable\",\n//   missingInnerMessage = \"The World object is missing\");\n// ...\n// end World;\n//\n// inner replaceable World world;\n//\n// annotation(unassignedMessage = \"message\");\n//\n// annotation(Dialog(enable = parameter-expression, tab = \"tab\", group = \"group\"));\n//\n\nrecord Dialog\n   parameter String tab = \"General\";\n   parameter String group = \"Parameters\";\n   parameter Boolean enable = true;\n   parameter Boolean showStartAttribute = false;\n   parameter Boolean colorSelector = false;\n   parameter Selector loadSelector;\n   parameter Selector saveSelector;\n   parameter String groupImage = \"\";\n   parameter Boolean connectorSizing = false;\nend Dialog;\n\nrecord Selector\n  parameter String filter;\n  parameter String caption;\nend Selector;\n\n// Annotations for Version Handling\nrecord Version\n  String version \"The version number of the released library.\";\n  String versionDate \"The date in UTC format (according to ISO 8601) when the library was released.\";\n  Integer versionBuild \"The optional build number of the library.\";\n  String dateModified \"The UTC date and time (according to ISO 8601) of the last modification of the package.\";\n  String revisionId \"A tool specific revision identifier possibly generated by a source code management system (e.g. Subversion or CVS).\";\nend Version;\n\n//record uses \"A list of dependent classes.\"\n//end uses;\n\n// Annotations for Access Control to Protect Intellectual Property\ntype Access = enumeration(hide, icon, documentation, diagram, nonPackageText, nonPackageDuplicate, packageText, packageDuplicate);\n\nrecord Protection \"Protection of class\"\n  Access access \"Defines what parts of a class are visible.\";\n  String features[:] = fill(\"\", 0) \"Required license features\";\n  record License\n    String libraryKey;\n    String licenseFile = \"\" \"Optional, default mapping if empty\";\n  end License;\nend Protection;\n\nrecord Authorization\n  String licensor = \"\" \"Optional string to show information about the licensor\";\n  String libraryKey \"Matching the key in the class. Must be encrypted and not visible\";\n  License license[:] \"Definition of the license options and of the access rights\";\nend Authorization;\n\nrecord License\n  String licensee = \"\" \"Optional string to show information about the licensee\";\n  String id[:] \"Unique machine identifications, e.g. MAC addresses\";\n  String features[:] = fill(\"\", 0) \"Activated library license features\";\n  String startDate = \"\" \"Optional start date in UTCformat YYYY-MM-DD\";\n  String expirationDate = \"\" \"Optional expiration date in UTCformat YYYY-MM-DD\";\n  String operations[:] = fill(\"\",0) \"Library usage conditions\";\nend License;\n\n// TODO: Function Derivative Annotations\n\n// Inverse Function Annotation\n//record inverse\n//end inverse;\n\nrecord choices\n  Boolean checkBox = false;\n  Boolean __Dymola_checkBox = false;\n  String choice[:] = fill(\"\", 0) \"the choices as string\";\nend choices;\n\n//\n// connector Frame \"Frame of a mechanical system\"\n//   ...\n//   flow Modelica.SIunits.Force f[3] annotation(unassignedMessage =\n//    \"All Forces cannot be uniquely calculated. The reason could be that the\n//      mechanism contains a planar loop or that joints constrain the same motion.\n//      For planar loops, use in one revolute joint per loop the option\n//      PlanarCutJoint=true in the Advanced menu.\");\n// end Frame;\n//\n// model BodyShape\n//   ...\n//   parameter Boolean animation = true;\n//   parameter SI.Length length \"Length of shape\"\n//   annotation(Dialog(enable = animation, tab = \"Animation\",\n//   group = \"Shape definition\"));\n//   ...\n// end BodyShape;\n\nrecord Documentation\n  String info = \"\" \"Description of the class\";\n  String revisions = \"\" \"Revision history\";\n  // Spec 3.5 Figure[:] figures = {}; \"Simulation result figures\";\nend Documentation;\n  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT131,11915,_OMC_LIT131_data);
#define _OMC_LIT131 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT131)
#define _OMC_LIT132_data "<3.x annotations>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT132,17,_OMC_LIT132_data);
#define _OMC_LIT132 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT132)
#define _OMC_LIT133_data "3.x"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT133,3,_OMC_LIT133_data);
#define _OMC_LIT133 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT133)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT134,1,3) {&DAE_Prefix_NOPRE__desc,}};
#define _OMC_LIT134 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT134)
#define _OMC_LIT135_data "="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT135,1,_OMC_LIT135_data);
#define _OMC_LIT135 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT135)
#define _OMC_LIT136_data "Icon"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT136,4,_OMC_LIT136_data);
#define _OMC_LIT136 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT136)
#define _OMC_LIT137_data "Diagram"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT137,7,_OMC_LIT137_data);
#define _OMC_LIT137 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT137)
#define _OMC_LIT138_data "choices"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT138,7,_OMC_LIT138_data);
#define _OMC_LIT138 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT138)
#define _OMC_LIT139_data "buildEnvForGraphicProgram"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT139,25,_OMC_LIT139_data);
#define _OMC_LIT139 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT139)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT140,1,4) {&SCode_Final_NOT__FINAL__desc,}};
#define _OMC_LIT140 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT140)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT141,1,4) {&SCode_Each_NOT__EACH__desc,}};
#define _OMC_LIT141 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT141)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT142,1,4) {&UnitAbsyn_InstStore_NOSTORE__desc,}};
#define _OMC_LIT142 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT142)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT143,1,3) {&InstTypes_CallingScope_TOP__CALL__desc,}};
#define _OMC_LIT143 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT143)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT144,7,3) {&ConnectionGraph_ConnectionGraph_GRAPH__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT144 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT144)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT145,1,6) {&DAE_ComponentRef_WILD__desc,}};
#define _OMC_LIT145 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT145)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT146,5,3) {&DAE_Connect_SetTrieNode_SET__TRIE__NODE__desc,_OMC_LIT14,_OMC_LIT145,MMC_REFSTRUCTLIT(mmc_nil),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT146 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT146)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT147,5,3) {&DAE_Connect_Sets_SETS__desc,_OMC_LIT146,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT147 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT147)
#define _OMC_LIT148_data "getAnnotationString: Icon"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT148,25,_OMC_LIT148_data);
#define _OMC_LIT148 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT148)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT149,1,4) {&SCode_Partial_NOT__PARTIAL__desc,}};
#define _OMC_LIT149 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT149)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT150,2,1) {_OMC_LIT138,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT150 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT150)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT151,2,1) {_OMC_LIT137,_OMC_LIT150}};
#define _OMC_LIT151 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT151)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT152,2,1) {_OMC_LIT136,_OMC_LIT151}};
#define _OMC_LIT152 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT152)
#define _OMC_LIT153_data "("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT153,1,_OMC_LIT153_data);
#define _OMC_LIT153 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT153)
#define _OMC_LIT154_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT154,1,_OMC_LIT154_data);
#define _OMC_LIT154 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT154)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT155,1,5) {&DAE_Mod_NOMOD__desc,}};
#define _OMC_LIT155 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT155)
#define _OMC_LIT156_data "error evaluating: annotation("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT156,29,_OMC_LIT156_data);
#define _OMC_LIT156 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT156)
#define _OMC_LIT157_data "(\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT157,2,_OMC_LIT157_data);
#define _OMC_LIT157 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT157)
#define _OMC_LIT158_data "\")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT158,2,_OMC_LIT158_data);
#define _OMC_LIT158 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT158)
#define _OMC_LIT159_data "{}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT159,2,_OMC_LIT159_data);
#define _OMC_LIT159 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT159)
#define _OMC_LIT160_data "empty"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT160,5,_OMC_LIT160_data);
#define _OMC_LIT160 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT160)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT161,2,4) {&FCore_Graph_EG__desc,_OMC_LIT160}};
#define _OMC_LIT161 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT161)
#define _OMC_LIT162_data "Error"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT162,5,_OMC_LIT162_data);
#define _OMC_LIT162 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT162)
#define _OMC_LIT163_data "permissive"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT163,10,_OMC_LIT163_data);
#define _OMC_LIT163 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT163)
#define _OMC_LIT164_data "Disables some error checks to allow erroneous models to compile."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT164,64,_OMC_LIT164_data);
#define _OMC_LIT164 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT164)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT165,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT164}};
#define _OMC_LIT165 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT165)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT166,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(82)),_OMC_LIT163,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT70,_OMC_LIT71,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT165}};
#define _OMC_LIT166 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT166)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT167,1,3) {&SCode_Visibility_PUBLIC__desc,}};
#define _OMC_LIT167 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT167)
#define _OMC_LIT168_data "\"public\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT168,8,_OMC_LIT168_data);
#define _OMC_LIT168 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT168)
#define _OMC_LIT169_data "\"protected\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT169,11,_OMC_LIT169_data);
#define _OMC_LIT169 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT169)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT170,3,3) {&Absyn_Modification_CLASSMOD__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT17}};
#define _OMC_LIT170 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT170)
#define _OMC_LIT171_data "-set_submodifier_in_elementargs failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT171,39,_OMC_LIT171_data);
#define _OMC_LIT171 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT171)
#define _OMC_LIT172_data "Ok"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT172,2,_OMC_LIT172_data);
#define _OMC_LIT172 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT172)
#include "util/modelica.h"
#include "InteractiveUtil_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_removeClassInElementitemlist(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inClass);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_removeClassInElementitemlist,2,0) {(void*) boxptr_InteractiveUtil_removeClassInElementitemlist,0}};
#define boxvar_InteractiveUtil_removeClassInElementitemlist MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_removeClassInElementitemlist)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getClassnamesInClassListNoPartial(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_boolean _inShowProtected, modelica_boolean _includeConstants);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getClassnamesInClassListNoPartial(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_metatype _inShowProtected, modelica_metatype _includeConstants);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getClassnamesInClassListNoPartial,2,0) {(void*) boxptr_InteractiveUtil_getClassnamesInClassListNoPartial,0}};
#define boxvar_InteractiveUtil_getClassnamesInClassListNoPartial MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getClassnamesInClassListNoPartial)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_updateConnectionNamesInEqList(threadData_t *threadData, modelica_metatype _equations, modelica_string _from, modelica_string _to, modelica_string _fromNew, modelica_string _toNew);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_updateConnectionNamesInEqList,2,0) {(void*) boxptr_InteractiveUtil_updateConnectionNamesInEqList,0}};
#define boxvar_InteractiveUtil_updateConnectionNamesInEqList MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_updateConnectionNamesInEqList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_updateConnectionNamesInClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_string _inFrom, modelica_string _inTo, modelica_string _inFromNew, modelica_string _inToNew);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_updateConnectionNamesInClass,2,0) {(void*) boxptr_InteractiveUtil_updateConnectionNamesInClass,0}};
#define boxvar_InteractiveUtil_updateConnectionNamesInClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_updateConnectionNamesInClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_updateConnectionAnnotationInEqList(threadData_t *threadData, modelica_metatype _equations, modelica_string _from, modelica_string _to, modelica_metatype _ann);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_updateConnectionAnnotationInEqList,2,0) {(void*) boxptr_InteractiveUtil_updateConnectionAnnotationInEqList,0}};
#define boxvar_InteractiveUtil_updateConnectionAnnotationInEqList MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_updateConnectionAnnotationInEqList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_excludeElementsFromFile(threadData_t *threadData, modelica_string _inFile, modelica_metatype _inEls);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_excludeElementsFromFile,2,0) {(void*) boxptr_InteractiveUtil_excludeElementsFromFile,0}};
#define boxvar_InteractiveUtil_excludeElementsFromFile MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_excludeElementsFromFile)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_mergeElements(threadData_t *threadData, modelica_metatype _inEls1, modelica_metatype _inEls2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_mergeElements,2,0) {(void*) boxptr_InteractiveUtil_mergeElements,0}};
#define boxvar_InteractiveUtil_mergeElements MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_mergeElements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_mergeElement(threadData_t *threadData, modelica_metatype _inEls, modelica_metatype _inEl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_mergeElement,2,0) {(void*) boxptr_InteractiveUtil_mergeElement,0}};
#define boxvar_InteractiveUtil_mergeElement MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_mergeElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_mergeClasses(threadData_t *threadData, modelica_metatype _cNew, modelica_metatype _cOld);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_mergeClasses,2,0) {(void*) boxptr_InteractiveUtil_mergeClasses,0}};
#define boxvar_InteractiveUtil_mergeClasses MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_mergeClasses)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_joinPaths(threadData_t *threadData, modelica_string _child, modelica_metatype _parent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_joinPaths,2,0) {(void*) boxptr_InteractiveUtil_joinPaths,0}};
#define boxvar_InteractiveUtil_joinPaths MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_joinPaths)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getClassnamesInClassList(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_boolean _inShowProtected, modelica_boolean _includeConstants);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getClassnamesInClassList(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_metatype _inShowProtected, modelica_metatype _includeConstants);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getClassnamesInClassList,2,0) {(void*) boxptr_InteractiveUtil_getClassnamesInClassList,0}};
#define boxvar_InteractiveUtil_getClassnamesInClassList MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getClassnamesInClassList)
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getLocalVariablesInAlgorithmItem(threadData_t *threadData, modelica_metatype _inAbsynAlgorithmItem, modelica_boolean _inBoolean, modelica_metatype _inEnv);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getLocalVariablesInAlgorithmItem(threadData_t *threadData, modelica_metatype _inAbsynAlgorithmItem, modelica_metatype _inBoolean, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getLocalVariablesInAlgorithmItem,2,0) {(void*) boxptr_InteractiveUtil_getLocalVariablesInAlgorithmItem,0}};
#define boxvar_InteractiveUtil_getLocalVariablesInAlgorithmItem MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getLocalVariablesInAlgorithmItem)
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getLocalVariablesInAlgorithmsItems(threadData_t *threadData, modelica_metatype _inAbsynAlgorithmItemLst, modelica_boolean _inBoolean, modelica_metatype _inEnv);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getLocalVariablesInAlgorithmsItems(threadData_t *threadData, modelica_metatype _inAbsynAlgorithmItemLst, modelica_metatype _inBoolean, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getLocalVariablesInAlgorithmsItems,2,0) {(void*) boxptr_InteractiveUtil_getLocalVariablesInAlgorithmsItems,0}};
#define boxvar_InteractiveUtil_getLocalVariablesInAlgorithmsItems MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getLocalVariablesInAlgorithmsItems)
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getLocalVariablesInClassParts(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_boolean _inBoolean, modelica_metatype _inEnv);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getLocalVariablesInClassParts(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_metatype _inBoolean, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getLocalVariablesInClassParts,2,0) {(void*) boxptr_InteractiveUtil_getLocalVariablesInClassParts,0}};
#define boxvar_InteractiveUtil_getLocalVariablesInClassParts MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getLocalVariablesInClassParts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_namedargToModification(threadData_t *threadData, modelica_metatype _inNamedArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_namedargToModification,2,0) {(void*) boxptr_InteractiveUtil_namedargToModification,0}};
#define boxvar_InteractiveUtil_namedargToModification MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_namedargToModification)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_recordConstructorToModification(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_recordConstructorToModification,2,0) {(void*) boxptr_InteractiveUtil_recordConstructorToModification,0}};
#define boxvar_InteractiveUtil_recordConstructorToModification MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_recordConstructorToModification)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InteractiveUtil_compareClassName(threadData_t *threadData, modelica_metatype _cl, modelica_string _str);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_compareClassName(threadData_t *threadData, modelica_metatype _cl, modelica_metatype _str);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_compareClassName,2,0) {(void*) boxptr_InteractiveUtil_compareClassName,0}};
#define boxvar_InteractiveUtil_compareClassName MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_compareClassName)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getClassesInElts(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getClassesInElts,2,0) {(void*) boxptr_InteractiveUtil_getClassesInElts,0}};
#define boxvar_InteractiveUtil_getClassesInElts MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getClassesInElts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getClassesInClass(threadData_t *threadData, modelica_metatype _inClass);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getClassesInClass,2,0) {(void*) boxptr_InteractiveUtil_getClassesInClass,0}};
#define boxvar_InteractiveUtil_getClassesInClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getClassesInClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getClassInClass(threadData_t *threadData, modelica_string _inString, modelica_metatype _inClass);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getClassInClass,2,0) {(void*) boxptr_InteractiveUtil_getClassInClass,0}};
#define boxvar_InteractiveUtil_getClassInClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getClassInClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getPathedClassInProgramWorkNoThrow(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inClass);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getPathedClassInProgramWorkNoThrow,2,0) {(void*) boxptr_InteractiveUtil_getPathedClassInProgramWorkNoThrow,0}};
#define boxvar_InteractiveUtil_getPathedClassInProgramWorkNoThrow MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getPathedClassInProgramWorkNoThrow)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getPathedClassInProgramWorkThrow(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inClass);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getPathedClassInProgramWorkThrow,2,0) {(void*) boxptr_InteractiveUtil_getPathedClassInProgramWorkThrow,0}};
#define boxvar_InteractiveUtil_getPathedClassInProgramWorkThrow MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getPathedClassInProgramWorkThrow)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getPathedClassInProgramWork(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_boolean _enclOnErr);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getPathedClassInProgramWork(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _enclOnErr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getPathedClassInProgramWork,2,0) {(void*) boxptr_InteractiveUtil_getPathedClassInProgramWork,0}};
#define boxvar_InteractiveUtil_getPathedClassInProgramWork MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getPathedClassInProgramWork)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InteractiveUtil_classInProgram(threadData_t *threadData, modelica_string _name, modelica_metatype _p);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_classInProgram(threadData_t *threadData, modelica_metatype _name, modelica_metatype _p);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_classInProgram,2,0) {(void*) boxptr_InteractiveUtil_classInProgram,0}};
#define boxvar_InteractiveUtil_classInProgram MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_classInProgram)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getClassFromElementitemlist(threadData_t *threadData, modelica_metatype _inElements, modelica_string _inIdent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getClassFromElementitemlist,2,0) {(void*) boxptr_InteractiveUtil_getClassFromElementitemlist,0}};
#define boxvar_InteractiveUtil_getClassFromElementitemlist MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getClassFromElementitemlist)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_deleteProtectedList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_deleteProtectedList,2,0) {(void*) boxptr_InteractiveUtil_deleteProtectedList,0}};
#define boxvar_InteractiveUtil_deleteProtectedList MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_deleteProtectedList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_deletePublicList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_deletePublicList,2,0) {(void*) boxptr_InteractiveUtil_deletePublicList,0}};
#define boxvar_InteractiveUtil_deletePublicList MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_deletePublicList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getInnerClass(threadData_t *threadData, modelica_metatype _inClass, modelica_string _inIdent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getInnerClass,2,0) {(void*) boxptr_InteractiveUtil_getInnerClass,0}};
#define boxvar_InteractiveUtil_getInnerClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getInnerClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_addClassInElementitemlist(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _inClass);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_addClassInElementitemlist,2,0) {(void*) boxptr_InteractiveUtil_addClassInElementitemlist,0}};
#define boxvar_InteractiveUtil_addClassInElementitemlist MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_addClassInElementitemlist)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_replaceClassInElementitemlist(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _inClass, modelica_boolean _mergeAST, modelica_boolean *out_replaced);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_replaceClassInElementitemlist(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _inClass, modelica_metatype _mergeAST, modelica_metatype *out_replaced);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_replaceClassInElementitemlist,2,0) {(void*) boxptr_InteractiveUtil_replaceClassInElementitemlist,0}};
#define boxvar_InteractiveUtil_replaceClassInElementitemlist MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_replaceClassInElementitemlist)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_replaceInnerClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inClass2, modelica_boolean _mergeAST);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_replaceInnerClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inClass2, modelica_metatype _mergeAST);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_replaceInnerClass,2,0) {(void*) boxptr_InteractiveUtil_replaceInnerClass,0}};
#define boxvar_InteractiveUtil_replaceInnerClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_replaceInnerClass)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InteractiveUtil_classElementItemIsNamed(threadData_t *threadData, modelica_string _inClassName, modelica_metatype _inElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_classElementItemIsNamed(threadData_t *threadData, modelica_metatype _inClassName, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_classElementItemIsNamed,2,0) {(void*) boxptr_InteractiveUtil_classElementItemIsNamed,0}};
#define boxvar_InteractiveUtil_classElementItemIsNamed MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_classElementItemIsNamed)
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getFirstIdentFromPath(threadData_t *threadData, modelica_metatype _inPath);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getFirstIdentFromPath,2,0) {(void*) boxptr_InteractiveUtil_getFirstIdentFromPath,0}};
#define boxvar_InteractiveUtil_getFirstIdentFromPath MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getFirstIdentFromPath)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_insertClassInClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inWithin2, modelica_metatype _inClass3, modelica_boolean _mergeAST);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_insertClassInClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inWithin2, modelica_metatype _inClass3, modelica_metatype _mergeAST);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_insertClassInClass,2,0) {(void*) boxptr_InteractiveUtil_insertClassInClass,0}};
#define boxvar_InteractiveUtil_insertClassInClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_insertClassInClass)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InteractiveUtil_replaceClassInProgram2(threadData_t *threadData, modelica_metatype _inClass, modelica_string _inClassName);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_replaceClassInProgram2(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inClassName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_replaceClassInProgram2,2,0) {(void*) boxptr_InteractiveUtil_replaceClassInProgram2,0}};
#define boxvar_InteractiveUtil_replaceClassInProgram2 MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_replaceClassInProgram2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementsInfo2(threadData_t *threadData, modelica_metatype _inAbsynElementLst, modelica_boolean _inBoolean, modelica_string _inString, modelica_metatype _inEnv, modelica_metatype _acc);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getElementsInfo2(threadData_t *threadData, modelica_metatype _inAbsynElementLst, modelica_metatype _inBoolean, modelica_metatype _inString, modelica_metatype _inEnv, modelica_metatype _acc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementsInfo2,2,0) {(void*) boxptr_InteractiveUtil_getElementsInfo2,0}};
#define boxvar_InteractiveUtil_getElementsInfo2 MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementsInfo2)
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getElementsInfo(threadData_t *threadData, modelica_metatype _inAbsynElementLst, modelica_boolean _inBoolean, modelica_string _inString, modelica_metatype _inEnv);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getElementsInfo(threadData_t *threadData, modelica_metatype _inAbsynElementLst, modelica_metatype _inBoolean, modelica_metatype _inString, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementsInfo,2,0) {(void*) boxptr_InteractiveUtil_getElementsInfo,0}};
#define boxvar_InteractiveUtil_getElementsInfo MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementsInfo)
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_arrayDimensionStr(threadData_t *threadData, modelica_metatype _ad);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_arrayDimensionStr,2,0) {(void*) boxptr_InteractiveUtil_arrayDimensionStr,0}};
#define boxvar_InteractiveUtil_arrayDimensionStr MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_arrayDimensionStr)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementInfo(threadData_t *threadData, modelica_metatype _inElement, modelica_boolean _inQuoteNames, modelica_string _inVisibility, modelica_metatype _inEnv);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getElementInfo(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inQuoteNames, modelica_metatype _inVisibility, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementInfo,2,0) {(void*) boxptr_InteractiveUtil_getElementInfo,0}};
#define boxvar_InteractiveUtil_getElementInfo MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementInfo)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementsInElementitems(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementsInElementitems,2,0) {(void*) boxptr_InteractiveUtil_getElementsInElementitems,0}};
#define boxvar_InteractiveUtil_getElementsInElementitems MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementsInElementitems)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_buildEnvForGraphicProgramFull(threadData_t *threadData, modelica_metatype _inProgram, modelica_metatype _inModelPath, modelica_metatype *out_outEnv, modelica_metatype *out_outProgram);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_buildEnvForGraphicProgramFull,2,0) {(void*) boxptr_InteractiveUtil_buildEnvForGraphicProgramFull,0}};
#define boxvar_InteractiveUtil_buildEnvForGraphicProgramFull MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_buildEnvForGraphicProgramFull)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementitemsAnnotationsFromItems(threadData_t *threadData, modelica_metatype _inComponentItems, modelica_metatype _ccAnnotations, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype _inCache, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementitemsAnnotationsFromItems,2,0) {(void*) boxptr_InteractiveUtil_getElementitemsAnnotationsFromItems,0}};
#define boxvar_InteractiveUtil_getElementitemsAnnotationsFromItems MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementitemsAnnotationsFromItems)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getAnnotationsFromConstraintClass(threadData_t *threadData, modelica_metatype _inCC);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getAnnotationsFromConstraintClass,2,0) {(void*) boxptr_InteractiveUtil_getAnnotationsFromConstraintClass,0}};
#define boxvar_InteractiveUtil_getAnnotationsFromConstraintClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getAnnotationsFromConstraintClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementitemsAnnotationsFromElArgs(threadData_t *threadData, modelica_metatype _inAnnotations, modelica_metatype _ccAnnotations, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype _inCache, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementitemsAnnotationsFromElArgs,2,0) {(void*) boxptr_InteractiveUtil_getElementitemsAnnotationsFromElArgs,0}};
#define boxvar_InteractiveUtil_getElementitemsAnnotationsFromElArgs MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementitemsAnnotationsFromElArgs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementitemsAnnotations(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype _inCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementitemsAnnotations,2,0) {(void*) boxptr_InteractiveUtil_getElementitemsAnnotations,0}};
#define boxvar_InteractiveUtil_getElementitemsAnnotations MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementitemsAnnotations)
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getElementAnnotationsFromElts(threadData_t *threadData, modelica_metatype _els, modelica_metatype _inClass, modelica_metatype _inFullProgram, modelica_metatype _inModelPath);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementAnnotationsFromElts,2,0) {(void*) boxptr_InteractiveUtil_getElementAnnotationsFromElts,0}};
#define boxvar_InteractiveUtil_getElementAnnotationsFromElts MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElementAnnotationsFromElts)
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getElements2(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_boolean _inBoolean, modelica_integer _inAccess);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getElements2(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inBoolean, modelica_metatype _inAccess);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElements2,2,0) {(void*) boxptr_InteractiveUtil_getElements2,0}};
#define boxvar_InteractiveUtil_getElements2 MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getElements2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_updateProgram2(threadData_t *threadData, modelica_metatype _inNewClasses, modelica_metatype _w, modelica_metatype _inOldProgram, modelica_boolean _mergeAST);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_updateProgram2(threadData_t *threadData, modelica_metatype _inNewClasses, modelica_metatype _w, modelica_metatype _inOldProgram, modelica_metatype _mergeAST);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_updateProgram2,2,0) {(void*) boxptr_InteractiveUtil_updateProgram2,0}};
#define boxvar_InteractiveUtil_updateProgram2 MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_updateProgram2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getModificationNames(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_boolean _includeRedeclares);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getModificationNames(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_metatype _includeRedeclares);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getModificationNames,2,0) {(void*) boxptr_InteractiveUtil_getModificationNames,0}};
#define boxvar_InteractiveUtil_getModificationNames MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getModificationNames)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getModificationValues(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_metatype _inPath);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getModificationValues,2,0) {(void*) boxptr_InteractiveUtil_getModificationValues,0}};
#define boxvar_InteractiveUtil_getModificationValues MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getModificationValues)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setSubmodifierInClass(threadData_t *threadData, modelica_metatype _inElementName, modelica_metatype _inClass, modelica_metatype _inMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_setSubmodifierInClass,2,0) {(void*) boxptr_InteractiveUtil_setSubmodifierInClass,0}};
#define boxvar_InteractiveUtil_setSubmodifierInClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_setSubmodifierInClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setSubmodifierInElementSpec(threadData_t *threadData, modelica_metatype _inElementName, modelica_metatype _inElSpec, modelica_metatype _inMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_setSubmodifierInElementSpec,2,0) {(void*) boxptr_InteractiveUtil_setSubmodifierInElementSpec,0}};
#define boxvar_InteractiveUtil_setSubmodifierInElementSpec MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_setSubmodifierInElementSpec)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setSubmodifierInElement(threadData_t *threadData, modelica_metatype _inElement, modelica_boolean _inFound, modelica_metatype _inElementName, modelica_metatype _inMod, modelica_boolean *out_outFound, modelica_boolean *out_outContinue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_setSubmodifierInElement(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inFound, modelica_metatype _inElementName, modelica_metatype _inMod, modelica_metatype *out_outFound, modelica_metatype *out_outContinue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_setSubmodifierInElement,2,0) {(void*) boxptr_InteractiveUtil_setSubmodifierInElement,0}};
#define boxvar_InteractiveUtil_setSubmodifierInElement MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_setSubmodifierInElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setElementSubmodifierInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inElementName, modelica_metatype _inMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_setElementSubmodifierInClass,2,0) {(void*) boxptr_InteractiveUtil_setElementSubmodifierInClass,0}};
#define boxvar_InteractiveUtil_setElementSubmodifierInClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_setElementSubmodifierInClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_stripModifiersKeepRedeclares(threadData_t *threadData, modelica_metatype _inMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_stripModifiersKeepRedeclares,2,0) {(void*) boxptr_InteractiveUtil_stripModifiersKeepRedeclares,0}};
#define boxvar_InteractiveUtil_stripModifiersKeepRedeclares MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_stripModifiersKeepRedeclares)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_clearComponentModifiersInCompitems(threadData_t *threadData, modelica_metatype _inComponents, modelica_boolean _inFound, modelica_string _inComponentName, modelica_boolean _keepRedeclares, modelica_boolean *out_outFound, modelica_boolean *out_outContinue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_clearComponentModifiersInCompitems(threadData_t *threadData, modelica_metatype _inComponents, modelica_metatype _inFound, modelica_metatype _inComponentName, modelica_metatype _keepRedeclares, modelica_metatype *out_outFound, modelica_metatype *out_outContinue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_clearComponentModifiersInCompitems,2,0) {(void*) boxptr_InteractiveUtil_clearComponentModifiersInCompitems,0}};
#define boxvar_InteractiveUtil_clearComponentModifiersInCompitems MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_clearComponentModifiersInCompitems)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getExtendsElementspecInElement(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getExtendsElementspecInElement,2,0) {(void*) boxptr_InteractiveUtil_getExtendsElementspecInElement,0}};
#define boxvar_InteractiveUtil_getExtendsElementspecInElement MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getExtendsElementspecInElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getExtendsElementspecInElementitems(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getExtendsElementspecInElementitems,2,0) {(void*) boxptr_InteractiveUtil_getExtendsElementspecInElementitems,0}};
#define boxvar_InteractiveUtil_getExtendsElementspecInElementitems MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getExtendsElementspecInElementitems)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getExtendsElementspecInClassparts(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getExtendsElementspecInClassparts,2,0) {(void*) boxptr_InteractiveUtil_getExtendsElementspecInClassparts,0}};
#define boxvar_InteractiveUtil_getExtendsElementspecInClassparts MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getExtendsElementspecInClassparts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_removeClassInElementitemlist(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inClass)
{
modelica_metatype _outElements = NULL;
modelica_string _name = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inClass;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_name = tmpMeta2;
_outElements = omc_List_deleteMemberOnTrue(threadData, _name, _inElements, boxvar_InteractiveUtil_classElementItemIsNamed, NULL);
_return: OMC_LABEL_UNUSED
return _outElements;
}
DLLExport
modelica_metatype omc_InteractiveUtil_removeInnerClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inClass2)
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
modelica_string _a = NULL;
modelica_string _bcname = NULL;
modelica_string _n = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _file_info = NULL;
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
for (; tmp4 < 5; tmp4++) {
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
_publst = omc_InteractiveUtil_getPublicList(threadData, _parts);
_publst2 = omc_InteractiveUtil_removeClassInElementitemlist(threadData, _publst, _c1);
_parts2 = omc_InteractiveUtil_replacePublicList(threadData, _parts, _publst2);
tmpMeta13 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars, _classAttrs, _parts2, _ann, _cmt);
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[7] = tmpMeta13;
_outClass = tmpMeta12;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,0,5) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 4));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 5));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 6));
_outClass = tmp4_2;
_typeVars = tmpMeta15;
_classAttrs = tmpMeta16;
_parts = tmpMeta17;
_ann = tmpMeta18;
_cmt = tmpMeta19;
_c1 = tmp4_1;
tmp4 += 2;
_prolst = omc_InteractiveUtil_getProtectedList(threadData, _parts);
_prolst2 = omc_InteractiveUtil_removeClassInElementitemlist(threadData, _prolst, _c1);
_parts2 = omc_InteractiveUtil_replaceProtectedList(threadData, _parts, _prolst2);
tmpMeta21 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars, _classAttrs, _parts2, _ann, _cmt);
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta20))[7] = tmpMeta21;
_outClass = tmpMeta20;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,4,5) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 3));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 4));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 5));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 6));
_outClass = tmp4_2;
_bcname = tmpMeta23;
_modif = tmpMeta24;
_cmt = tmpMeta25;
_parts = tmpMeta26;
_ann = tmpMeta27;
_c1 = tmp4_1;
_publst = omc_InteractiveUtil_getPublicList(threadData, _parts);
_publst2 = omc_InteractiveUtil_removeClassInElementitemlist(threadData, _publst, _c1);
_parts2 = omc_InteractiveUtil_replacePublicList(threadData, _parts, _publst2);
tmpMeta29 = mmc_mk_box6(7, &Absyn_ClassDef_CLASS__EXTENDS__desc, _bcname, _modif, _cmt, _parts2, _ann);
tmpMeta28 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta28), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta28))[7] = tmpMeta29;
_outClass = tmpMeta28;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta30,4,5) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 2));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 3));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 4));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 5));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 6));
_outClass = tmp4_2;
_bcname = tmpMeta31;
_modif = tmpMeta32;
_cmt = tmpMeta33;
_parts = tmpMeta34;
_ann = tmpMeta35;
_c1 = tmp4_1;
_prolst = omc_InteractiveUtil_getProtectedList(threadData, _parts);
_prolst2 = omc_InteractiveUtil_removeClassInElementitemlist(threadData, _prolst, _c1);
_parts2 = omc_InteractiveUtil_replaceProtectedList(threadData, _parts, _prolst2);
tmpMeta37 = mmc_mk_box6(7, &Absyn_ClassDef_CLASS__EXTENDS__desc, _bcname, _modif, _cmt, _parts2, _ann);
tmpMeta36 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta36), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta36))[7] = tmpMeta37;
_outClass = tmpMeta36;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 10));
_n = tmpMeta38;
_a = tmpMeta39;
_file_info = tmpMeta40;
tmpMeta41 = mmc_mk_cons(_n, mmc_mk_cons(_a, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT4, tmpMeta41, _file_info);
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
if (++tmp4 < 5) {
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
DLLExport
modelica_metatype omc_InteractiveUtil_getClassnamesInEltsNoPartial(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_boolean _includeConstants)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype _delst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
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
modelica_integer tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,0,1) == 0) goto tmp4_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,6) == 0) goto tmp4_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,2) == 0) goto tmp4_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
tmp11 = mmc_unbox_integer(tmpMeta10);
if (0 != tmp11) goto tmp4_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,4,5) == 0) goto tmp4_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
_id = tmpMeta13;
omc_DoubleEnded_push__back(threadData, _delst, _id);
goto tmp4_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_integer tmp19;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,0,1) == 0) goto tmp4_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,0,6) == 0) goto tmp4_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,0,2) == 0) goto tmp4_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
tmp19 = mmc_unbox_integer(tmpMeta18);
if (0 != tmp19) goto tmp4_end;
_id = tmpMeta17;
omc_DoubleEnded_push__back(threadData, _delst, _id);
goto tmp4_done;
}
case 2: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,0,1) == 0) goto tmp4_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,0,6) == 0) goto tmp4_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,3,3) == 0) goto tmp4_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,3,0) == 0) goto tmp4_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 4));
_lst = tmpMeta24;
if (!_includeConstants) goto tmp4_end;
omc_DoubleEnded_push__list__back(threadData, _delst, omc_InteractiveUtil_getComponentItemsName(threadData, _lst, 0));
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
tmpMeta26 = MMC_REFSTRUCTLIT(mmc_nil);
_outStringLst = omc_DoubleEnded_toListAndClear(threadData, _delst, tmpMeta26);
_return: OMC_LABEL_UNUSED
return _outStringLst;
}
modelica_metatype boxptr_InteractiveUtil_getClassnamesInEltsNoPartial(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _includeConstants)
{
modelica_integer tmp1;
modelica_metatype _outStringLst = NULL;
tmp1 = mmc_unbox_integer(_includeConstants);
_outStringLst = omc_InteractiveUtil_getClassnamesInEltsNoPartial(threadData, _inAbsynElementItemLst, tmp1);
return _outStringLst;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getClassnamesInPartsNoPartial(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_boolean _inShowProtected, modelica_boolean _includeConstants)
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
_l1 = omc_InteractiveUtil_getClassnamesInEltsNoPartial(threadData, _elts, _c);
_l2 = omc_InteractiveUtil_getClassnamesInPartsNoPartial(threadData, _rest, _b, _c);
tmpMeta1 = listAppend(_l1, _l2);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (1 != tmp4_2) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_elts = tmpMeta12;
_rest = tmpMeta11;
_c = tmp4_3;
_l1 = omc_InteractiveUtil_getClassnamesInEltsNoPartial(threadData, _elts, _c);
_l2 = omc_InteractiveUtil_getClassnamesInPartsNoPartial(threadData, _rest, 1, _c);
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
tmpMeta1 = omc_InteractiveUtil_getClassnamesInPartsNoPartial(threadData, _rest, _b, _c);
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
modelica_metatype boxptr_InteractiveUtil_getClassnamesInPartsNoPartial(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_metatype _inShowProtected, modelica_metatype _includeConstants)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outStringLst = NULL;
tmp1 = mmc_unbox_integer(_inShowProtected);
tmp2 = mmc_unbox_integer(_includeConstants);
_outStringLst = omc_InteractiveUtil_getClassnamesInPartsNoPartial(threadData, _inAbsynClassPartLst, tmp1, tmp2);
return _outStringLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getClassnamesInClassListNoPartial(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_boolean _inShowProtected, modelica_boolean _includeConstants)
{
modelica_metatype _outString = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_AbsynUtil_isPartial(threadData, _inClass))
{
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outString = tmpMeta1;
goto _return;
}
{
modelica_metatype tmp5_1;modelica_boolean tmp5_2;modelica_boolean tmp5_3;
tmp5_1 = _inClass;
tmp5_2 = _inShowProtected;
tmp5_3 = _includeConstants;
{
modelica_metatype _parts = NULL;
modelica_boolean _b;
modelica_boolean _c;
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 6; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,5) == 0) goto tmp4_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
_parts = tmpMeta8;
_b = tmp5_2;
_c = tmp5_3;
tmpMeta2 = omc_InteractiveUtil_getClassnamesInPartsNoPartial(threadData, _parts, _b, _c);
goto tmp4_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,4,5) == 0) goto tmp4_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 5));
_parts = tmpMeta10;
_b = tmp5_2;
_c = tmp5_3;
tmpMeta2 = omc_InteractiveUtil_getClassnamesInPartsNoPartial(threadData, _parts, _b, _c);
goto tmp4_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,1,4) == 0) goto tmp4_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,0,2) == 0) goto tmp4_end;
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta2 = tmpMeta13;
goto tmp4_done;
}
case 3: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,3,2) == 0) goto tmp4_end;
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta2 = tmpMeta15;
goto tmp4_done;
}
case 4: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,2,2) == 0) goto tmp4_end;
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta2 = tmpMeta17;
goto tmp4_done;
}
case 5: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,5,3) == 0) goto tmp4_end;
tmpMeta19 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta2 = tmpMeta19;
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
_outString = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getClassnamesInClassListNoPartial(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_metatype _inShowProtected, modelica_metatype _includeConstants)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outString = NULL;
tmp1 = mmc_unbox_integer(_inShowProtected);
tmp2 = mmc_unbox_integer(_includeConstants);
_outString = omc_InteractiveUtil_getClassnamesInClassListNoPartial(threadData, _inPath, _inProgram, _inClass, tmp1, tmp2);
return _outString;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getClassNamesRecursiveNoPartial(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_boolean _inShowProtected, modelica_boolean _includeConstants, modelica_metatype _inAcc, modelica_metatype *out_paths)
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
_cdef = omc_InteractiveUtil_getPathedClassInProgram(threadData, _pp, _p, 0, 0);
if(omc_AbsynUtil_isNotPartial(threadData, _cdef))
{
tmpMeta7 = mmc_mk_cons(_pp, _acc);
_acc = tmpMeta7;
_strlst = omc_InteractiveUtil_getClassnamesInClassListNoPartial(threadData, _pp, _p, _cdef, _b, _c);
_result_path_lst = omc_List_map(threadData, omc_List_map1(threadData, _strlst, boxvar_InteractiveUtil_joinPaths, _pp), boxvar_Util_makeOption);
omc_List_map3Fold(threadData, _result_path_lst, boxvar_InteractiveUtil_getClassNamesRecursiveNoPartial, _p, mmc_mk_boolean(_b), mmc_mk_boolean(_c), _acc ,&_acc);
}
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
_strlst = omc_List_map(threadData, omc_List_filterOnTrue(threadData, _classes, boxvar_AbsynUtil_isNotPartial), boxvar_AbsynUtil_getClassName);
_result_path_lst = omc_List_mapMap(threadData, _strlst, boxvar_AbsynUtil_makeIdentPathFromString, boxvar_Util_makeOption);
omc_List_map3Fold(threadData, _result_path_lst, boxvar_InteractiveUtil_getClassNamesRecursiveNoPartial, _p, mmc_mk_boolean(_b), mmc_mk_boolean(_c), _acc ,&_acc);
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
_s1 = omc_AbsynUtil_pathString(threadData, _pp, _OMC_LIT5, 1, 0);
tmpMeta10 = mmc_mk_cons(_s1, mmc_mk_cons(_OMC_LIT11, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMessage(threadData, _OMC_LIT10, tmpMeta10);
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
modelica_metatype boxptr_InteractiveUtil_getClassNamesRecursiveNoPartial(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inShowProtected, modelica_metatype _includeConstants, modelica_metatype _inAcc, modelica_metatype *out_paths)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _opath = NULL;
tmp1 = mmc_unbox_integer(_inShowProtected);
tmp2 = mmc_unbox_integer(_includeConstants);
_opath = omc_InteractiveUtil_getClassNamesRecursiveNoPartial(threadData, _inPath, _inProgram, tmp1, tmp2, _inAcc, out_paths);
return _opath;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_updateConnectionNamesInEqList(threadData_t *threadData, modelica_metatype _equations, modelica_string _from, modelica_string _to, modelica_string _fromNew, modelica_string _toNew)
{
modelica_metatype _outEquations = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
modelica_string _c1_str = NULL;
modelica_string _c2_str = NULL;
modelica_boolean _found;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outEquations = tmpMeta1;
_found = 0;
{
modelica_metatype _eq;
for (tmpMeta2 = _equations; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_eq = MMC_CAR(tmpMeta2);
if((!_found))
{
{
modelica_metatype tmp6_1;
tmp6_1 = _eq;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,3) == 0) goto tmp5_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,2) == 0) goto tmp5_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
_c1 = tmpMeta9;
_c2 = tmpMeta10;
_c1_str = omc_AbsynUtil_crefString(threadData, _c1);
_c2_str = omc_AbsynUtil_crefString(threadData, _c2);
_found = (((stringEqual(_c1_str, _from)) && (stringEqual(_c2_str, _to)))?1:((stringEqual(_c1_str, _to)) && (stringEqual(_c2_str, _from))));
if(_found)
{
tmpMeta12 = mmc_mk_box3(6, &Absyn_Equation_EQ__CONNECT__desc, omc_Parser_stringCref(threadData, _fromNew), omc_Parser_stringCref(threadData, _toNew));
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_eq), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[2] = tmpMeta12;
_eq = tmpMeta11;
}
tmpMeta3 = _eq;
goto tmp5_done;
}
case 1: {
tmpMeta3 = _eq;
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
_eq = tmpMeta3;
}
tmpMeta13 = mmc_mk_cons(_eq, _outEquations);
_outEquations = tmpMeta13;
}
}
_outEquations = listReverseInPlace(_outEquations);
_return: OMC_LABEL_UNUSED
return _outEquations;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_updateConnectionNamesInClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_string _inFrom, modelica_string _inTo, modelica_string _inFromNew, modelica_string _inToNew)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_string tmp4_2;modelica_string tmp4_3;modelica_string tmp4_4;modelica_string tmp4_5;
tmp4_1 = _inClass1;
tmp4_2 = _inFrom;
tmp4_3 = _inTo;
tmp4_4 = _inFromNew;
tmp4_5 = _inToNew;
{
modelica_metatype _eqlst = NULL;
modelica_metatype _eqlst_1 = NULL;
modelica_metatype _parts2 = NULL;
modelica_metatype _parts = NULL;
modelica_string _bcname = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _modif = NULL;
modelica_metatype _typeVars = NULL;
modelica_metatype _classAttrs = NULL;
modelica_metatype _ann = NULL;
modelica_string _from = NULL;
modelica_string _to = NULL;
modelica_string _fromNew = NULL;
modelica_string _toNew = NULL;
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
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
_outClass = tmp4_1;
_typeVars = tmpMeta7;
_classAttrs = tmpMeta8;
_parts = tmpMeta9;
_ann = tmpMeta10;
_cmt = tmpMeta11;
_from = tmp4_2;
_to = tmp4_3;
_fromNew = tmp4_4;
_toNew = tmp4_5;
_eqlst = omc_InteractiveUtil_getEquationList(threadData, _parts);
_eqlst_1 = omc_InteractiveUtil_updateConnectionNamesInEqList(threadData, _eqlst, _from, _to, _fromNew, _toNew);
_parts2 = omc_InteractiveUtil_replaceEquationList(threadData, _parts, _eqlst_1);
tmpMeta13 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars, _classAttrs, _parts2, _ann, _cmt);
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[7] = tmpMeta13;
_outClass = tmpMeta12;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,4,5) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 4));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 5));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 6));
_outClass = tmp4_1;
_bcname = tmpMeta15;
_modif = tmpMeta16;
_cmt = tmpMeta17;
_parts = tmpMeta18;
_ann = tmpMeta19;
_from = tmp4_2;
_to = tmp4_3;
_fromNew = tmp4_4;
_toNew = tmp4_5;
_eqlst = omc_InteractiveUtil_getEquationList(threadData, _parts);
_eqlst_1 = omc_InteractiveUtil_updateConnectionNamesInEqList(threadData, _eqlst, _from, _to, _fromNew, _toNew);
_parts2 = omc_InteractiveUtil_replaceEquationList(threadData, _parts, _eqlst_1);
tmpMeta21 = mmc_mk_box6(7, &Absyn_ClassDef_CLASS__EXTENDS__desc, _bcname, _modif, _cmt, _parts2, _ann);
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta20))[7] = tmpMeta21;
_outClass = tmpMeta20;
tmpMeta1 = _outClass;
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
DLLExport
modelica_boolean omc_InteractiveUtil_updateConnectionNames(threadData_t *threadData, modelica_metatype _inPath, modelica_string _inFrom, modelica_string _inTo, modelica_string _inFromNew, modelica_string _inToNew, modelica_metatype _inProgram, modelica_metatype *out_outProgram)
{
modelica_boolean _outResult;
modelica_metatype _outProgram = NULL;
modelica_boolean tmp1_c0 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_string tmp4_2;volatile modelica_string tmp4_3;volatile modelica_string tmp4_4;volatile modelica_string tmp4_5;volatile modelica_metatype tmp4_6;
tmp4_1 = _inPath;
tmp4_2 = _inFrom;
tmp4_3 = _inTo;
tmp4_4 = _inFromNew;
tmp4_5 = _inToNew;
tmp4_6 = _inProgram;
{
modelica_metatype _path = NULL;
modelica_metatype _modelwithin = NULL;
modelica_string _from = NULL;
modelica_string _to = NULL;
modelica_string _fromNew = NULL;
modelica_string _toNew = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype _newcdef = NULL;
modelica_metatype _newp = NULL;
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
_path = tmp4_1;
_from = tmp4_2;
_to = tmp4_3;
_fromNew = tmp4_4;
_toNew = tmp4_5;
_p = tmp4_6;
_modelwithin = omc_AbsynUtil_stripLast(threadData, _path);
_cdef = omc_InteractiveUtil_getPathedClassInProgram(threadData, _path, _p, 0, 0);
_newcdef = omc_InteractiveUtil_updateConnectionNamesInClass(threadData, _cdef, _from, _to, _fromNew, _toNew);
tmpMeta6 = mmc_mk_cons(_newcdef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta7 = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, _modelwithin);
tmpMeta8 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta6, tmpMeta7);
_newp = omc_InteractiveUtil_updateProgram(threadData, tmpMeta8, _p, 0);
tmp1_c0 = 1;
tmpMeta[0+1] = _newp;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
_path = tmp4_1;
_from = tmp4_2;
_to = tmp4_3;
_fromNew = tmp4_4;
_toNew = tmp4_5;
_p = tmp4_6;
_cdef = omc_InteractiveUtil_getPathedClassInProgram(threadData, _path, _p, 0, 0);
_newcdef = omc_InteractiveUtil_updateConnectionNamesInClass(threadData, _cdef, _from, _to, _fromNew, _toNew);
tmpMeta9 = mmc_mk_cons(_newcdef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta10 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta9, _OMC_LIT12);
_newp = omc_InteractiveUtil_updateProgram(threadData, tmpMeta10, _p, 0);
tmp1_c0 = 1;
tmpMeta[0+1] = _newp;
goto tmp3_done;
}
case 2: {
_p = tmp4_6;
tmp1_c0 = 0;
tmpMeta[0+1] = _p;
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
_outResult = tmp1_c0;
_outProgram = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outProgram) { *out_outProgram = _outProgram; }
return _outResult;
}
modelica_metatype boxptr_InteractiveUtil_updateConnectionNames(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inFrom, modelica_metatype _inTo, modelica_metatype _inFromNew, modelica_metatype _inToNew, modelica_metatype _inProgram, modelica_metatype *out_outProgram)
{
modelica_boolean _outResult;
modelica_metatype out_outResult;
_outResult = omc_InteractiveUtil_updateConnectionNames(threadData, _inPath, _inFrom, _inTo, _inFromNew, _inToNew, _inProgram, out_outProgram);
out_outResult = mmc_mk_icon(_outResult);
return out_outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_updateConnectionAnnotationInEqList(threadData_t *threadData, modelica_metatype _equations, modelica_string _from, modelica_string _to, modelica_metatype _ann)
{
modelica_metatype _outEquations = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
modelica_string _c1_str = NULL;
modelica_string _c2_str = NULL;
modelica_boolean _found;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outEquations = tmpMeta1;
_found = 0;
{
modelica_metatype _eq;
for (tmpMeta2 = _equations; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_eq = MMC_CAR(tmpMeta2);
if((!_found))
{
{
modelica_metatype tmp6_1;
tmp6_1 = _eq;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,3) == 0) goto tmp5_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,2) == 0) goto tmp5_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
_c1 = tmpMeta9;
_c2 = tmpMeta10;
_c1_str = omc_AbsynUtil_crefString(threadData, _c1);
_c2_str = omc_AbsynUtil_crefString(threadData, _c2);
if(((stringEqual(_c1_str, _from)) && (stringEqual(_c2_str, _to))))
{
_found = 1;
}
if((!_found))
{
_found = ((stringEqual(_c1_str, _to)) && (stringEqual(_c2_str, _from)));
}
if(_found)
{
tmpMeta12 = mmc_mk_box3(3, &Absyn_Comment_COMMENT__desc, mmc_mk_some(_ann), mmc_mk_none());
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_eq), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[3] = mmc_mk_some(tmpMeta12);
_eq = tmpMeta11;
}
tmpMeta3 = _eq;
goto tmp5_done;
}
case 1: {
tmpMeta3 = _eq;
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
_eq = tmpMeta3;
}
tmpMeta13 = mmc_mk_cons(_eq, _outEquations);
_outEquations = tmpMeta13;
}
}
_outEquations = listReverseInPlace(_outEquations);
_return: OMC_LABEL_UNUSED
return _outEquations;
}
DLLExport
modelica_metatype omc_InteractiveUtil_updateConnectionAnnotationInClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_string _inFrom, modelica_string _inTo, modelica_metatype _inAnnotation)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_string tmp4_2;modelica_string tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _inClass1;
tmp4_2 = _inFrom;
tmp4_3 = _inTo;
tmp4_4 = _inAnnotation;
{
modelica_metatype _eqlst = NULL;
modelica_metatype _eqlst_1 = NULL;
modelica_metatype _parts2 = NULL;
modelica_metatype _parts = NULL;
modelica_string _bcname = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _modif = NULL;
modelica_metatype _typeVars = NULL;
modelica_metatype _classAttrs = NULL;
modelica_metatype _ann = NULL;
modelica_string _from = NULL;
modelica_string _to = NULL;
modelica_metatype _annotation_ = NULL;
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
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
_outClass = tmp4_1;
_typeVars = tmpMeta7;
_classAttrs = tmpMeta8;
_parts = tmpMeta9;
_ann = tmpMeta10;
_cmt = tmpMeta11;
_from = tmp4_2;
_to = tmp4_3;
_annotation_ = tmp4_4;
_eqlst = omc_InteractiveUtil_getEquationList(threadData, _parts);
_eqlst_1 = omc_InteractiveUtil_updateConnectionAnnotationInEqList(threadData, _eqlst, _from, _to, _annotation_);
_parts2 = omc_InteractiveUtil_replaceEquationList(threadData, _parts, _eqlst_1);
tmpMeta13 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars, _classAttrs, _parts2, _ann, _cmt);
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[7] = tmpMeta13;
_outClass = tmpMeta12;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,4,5) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 4));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 5));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 6));
_outClass = tmp4_1;
_bcname = tmpMeta15;
_modif = tmpMeta16;
_cmt = tmpMeta17;
_parts = tmpMeta18;
_ann = tmpMeta19;
_from = tmp4_2;
_to = tmp4_3;
_annotation_ = tmp4_4;
_eqlst = omc_InteractiveUtil_getEquationList(threadData, _parts);
_eqlst_1 = omc_InteractiveUtil_updateConnectionAnnotationInEqList(threadData, _eqlst, _from, _to, _annotation_);
_parts2 = omc_InteractiveUtil_replaceEquationList(threadData, _parts, _eqlst_1);
tmpMeta21 = mmc_mk_box6(7, &Absyn_ClassDef_CLASS__EXTENDS__desc, _bcname, _modif, _cmt, _parts2, _ann);
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta20))[7] = tmpMeta21;
_outClass = tmpMeta20;
tmpMeta1 = _outClass;
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
DLLExport
modelica_metatype omc_InteractiveUtil_updateConnectionAnnotation(threadData_t *threadData, modelica_metatype _inClass, modelica_string _inFrom, modelica_string _inTo, modelica_metatype _inAnnotation, modelica_metatype _inProgram)
{
modelica_metatype _outProgram = NULL;
modelica_metatype _class_path = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _class_within = NULL;
modelica_metatype tmpMeta1;
modelica_boolean tmp2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_class_path = omc_AbsynUtil_crefToPath(threadData, _inClass);
_cls = omc_InteractiveUtil_getPathedClassInProgram(threadData, _class_path, _inProgram, 0, 0);
_cls = omc_InteractiveUtil_updateConnectionAnnotationInClass(threadData, _cls, _inFrom, _inTo, omc_InteractiveUtil_annotationListToAbsyn(threadData, _inAnnotation));
tmp2 = (modelica_boolean)omc_AbsynUtil_pathIsIdent(threadData, _class_path);
if(tmp2)
{
tmpMeta3 = _OMC_LIT12;
}
else
{
tmpMeta1 = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, omc_AbsynUtil_stripLast(threadData, _class_path));
tmpMeta3 = tmpMeta1;
}
_class_within = tmpMeta3;
tmpMeta4 = mmc_mk_cons(_cls, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta5 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta4, _class_within);
_outProgram = omc_InteractiveUtil_updateProgram(threadData, tmpMeta5, _inProgram, 0);
_return: OMC_LABEL_UNUSED
return _outProgram;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getAllSubtypeOf(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inParentClass, modelica_metatype _inProgram, modelica_boolean _qualified, modelica_boolean _includePartial)
{
modelica_metatype _paths = NULL;
modelica_metatype _cdef = NULL;
modelica_string _s1 = NULL;
modelica_metatype _strlst = NULL;
modelica_metatype _pp = NULL;
modelica_metatype _fqpath = NULL;
modelica_metatype _p = NULL;
modelica_metatype _classes = NULL;
modelica_metatype _result_path_lst = NULL;
modelica_metatype _acc = NULL;
modelica_metatype _extendPaths = NULL;
modelica_boolean _b;
modelica_boolean _c;
modelica_metatype _genv = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inProgram;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_classes = tmpMeta2;
_strlst = omc_List_map(threadData, omc_List_filterOnTrue(threadData, _classes, boxvar_AbsynUtil_isNotPartial), boxvar_AbsynUtil_getClassName);
_result_path_lst = omc_List_mapMap(threadData, _strlst, boxvar_AbsynUtil_makeIdentPathFromString, boxvar_Util_makeOption);
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
omc_List_map3Fold(threadData, _result_path_lst, boxvar_InteractiveUtil_getClassNamesRecursiveNoPartial, _inProgram, mmc_mk_boolean(1), mmc_mk_boolean(0), tmpMeta3 ,&_acc);
{
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp5_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
_genv = omc_InteractiveUtil_createEnvironment(threadData, _inProgram, mmc_mk_none(), _inParentClass);
_fqpath = omc_InteractiveUtil_qualifyPath(threadData, _genv, _inClass);
goto tmp5_done;
}
case 1: {
_fqpath = _inClass;
goto tmp5_done;
}
}
goto tmp5_end;
tmp5_end: ;
}
goto goto_4;
tmp5_done:
(void)tmp6;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp5_done2;
goto_4:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp6 < 2) {
goto tmp5_top;
}
MMC_THROW_INTERNAL();
tmp5_done2:;
}
}
;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
_paths = tmpMeta8;
{
modelica_metatype _pt;
for (tmpMeta9 = _acc; !listEmpty(tmpMeta9); tmpMeta9=MMC_CDR(tmpMeta9))
{
_pt = MMC_CAR(tmpMeta9);
_extendPaths = omc_InteractiveUtil_getAllInheritedClasses(threadData, _pt, _inProgram);
_b = mmc_unbox_boolean(omc_List_applyAndFold1(threadData, _extendPaths, boxvar_boolOr, boxvar_AbsynUtil_pathSuffixOfr, _fqpath, mmc_mk_boolean(0)));
tmp11 = (modelica_boolean)_b;
if(tmp11)
{
tmpMeta10 = mmc_mk_cons(_pt, _paths);
tmpMeta12 = tmpMeta10;
}
else
{
tmpMeta12 = _paths;
}
_paths = tmpMeta12;
}
}
_paths = omc_List_unique(threadData, _paths);
_return: OMC_LABEL_UNUSED
return _paths;
}
modelica_metatype boxptr_InteractiveUtil_getAllSubtypeOf(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inParentClass, modelica_metatype _inProgram, modelica_metatype _qualified, modelica_metatype _includePartial)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _paths = NULL;
tmp1 = mmc_unbox_integer(_qualified);
tmp2 = mmc_unbox_integer(_includePartial);
_paths = omc_InteractiveUtil_getAllSubtypeOf(threadData, _inClass, _inParentClass, _inProgram, tmp1, tmp2);
return _paths;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_excludeElementsFromFile(threadData_t *threadData, modelica_string _inFile, modelica_metatype _inEls)
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
_filtered = omc_InteractiveUtil_excludeElementsFromFile(threadData, _file, _rest);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_mergeElements(threadData_t *threadData, modelica_metatype _inEls1, modelica_metatype _inEls2)
{
modelica_metatype _outEls = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inEls1;
tmp4_2 = _inEls2;
{
modelica_metatype _rest = NULL;
modelica_metatype _merged = NULL;
modelica_metatype _e2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _inEls2;
goto tmp3_done;
}
case 1: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp4 += 1;
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
_merged = omc_InteractiveUtil_mergeElement(threadData, _inEls1, _e2);
tmpMeta1 = omc_InteractiveUtil_mergeElements(threadData, _merged, _rest);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_mergeElement(threadData_t *threadData, modelica_metatype _inEls, modelica_metatype _inEl)
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
if (1 != tmp25) goto goto_2;
_c1 = omc_InteractiveUtil_mergeClasses(threadData, _c1, _c2);
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
_filtered = omc_InteractiveUtil_mergeElement(threadData, _rest, _e2);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_mergeClasses(threadData_t *threadData, modelica_metatype _cNew, modelica_metatype _cOld)
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
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 10));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
_c = tmp4_1;
_typeVars1 = tmpMeta11;
_classAttrs1 = tmpMeta12;
_partsC1 = tmpMeta13;
_ann1 = tmpMeta14;
_cmt1 = tmpMeta15;
_partsC2 = tmpMeta17;
_file = tmpMeta19;
_pubElementsC2 = omc_InteractiveUtil_getPublicList(threadData, _partsC2);
_pubElementsC2 = omc_InteractiveUtil_excludeElementsFromFile(threadData, _file, _pubElementsC2);
_pubElementsC1 = omc_InteractiveUtil_getPublicList(threadData, _partsC1);
_pubElementsC1 = omc_InteractiveUtil_mergeElements(threadData, _pubElementsC1, _pubElementsC2);
_partsC1 = omc_InteractiveUtil_replacePublicList(threadData, _partsC1, _pubElementsC1);
tmpMeta21 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars1, _classAttrs1, _partsC1, _ann1, _cmt1);
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_c), 11*sizeof(modelica_metatype));
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
DLLExport
modelica_metatype omc_InteractiveUtil_getBaseClassNameFromExtends(threadData_t *threadData, modelica_metatype _inElementSpec)
{
modelica_metatype _outBaseClassPath = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementSpec;
{
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta6;
tmpMeta1 = _path;
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
_outBaseClassPath = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outBaseClassPath;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getAllInheritedClasses(threadData_t *threadData, modelica_metatype _inClassName, modelica_metatype _inProgram)
{
modelica_metatype _outBaseClassNames = NULL;
modelica_metatype _genv = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp5_1;volatile modelica_metatype tmp5_2;
tmp5_1 = _inClassName;
tmp5_2 = _inProgram;
{
modelica_metatype _p_class = NULL;
modelica_metatype _paths = NULL;
modelica_metatype _fqpaths = NULL;
modelica_metatype _allPaths = NULL;
modelica_metatype tmpMeta3;
modelica_metatype _cdef = NULL;
modelica_metatype _exts = NULL;
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp5;
int tmp6;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_allPaths = tmpMeta3;
tmp5 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp4_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp5 < 2; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
_p_class = tmp5_1;
_p = tmp5_2;
_cdef = omc_InteractiveUtil_getPathedClassInProgram(threadData, _p_class, _p, 0, 0);
_exts = omc_InteractiveUtil_getExtendsElementspecInClass(threadData, _cdef);
_paths = omc_List_map(threadData, _exts, boxvar_InteractiveUtil_getBaseClassNameFromExtends);
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
_fqpaths = tmpMeta7;
{
{
volatile mmc_switch_type tmp10;
int tmp11;
tmp10 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp9_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp10 < 2; tmp10++) {
switch (MMC_SWITCH_CAST(tmp10)) {
case 0: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
_genv = omc_InteractiveUtil_createEnvironment(threadData, _p, mmc_mk_none(), _p_class);
{
modelica_metatype _pt;
for (tmpMeta12 = _paths; !listEmpty(tmpMeta12); tmpMeta12=MMC_CDR(tmpMeta12))
{
_pt = MMC_CAR(tmpMeta12);
tmpMeta13 = mmc_mk_cons(omc_InteractiveUtil_qualifyPath(threadData, _genv, _pt), _fqpaths);
_fqpaths = tmpMeta13;
}
}
_fqpaths = listReverse(_fqpaths);
goto tmp9_done;
}
case 1: {
_fqpaths = _paths;
goto tmp9_done;
}
}
goto tmp9_end;
tmp9_end: ;
}
goto goto_8;
tmp9_done:
(void)tmp10;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp9_done2;
goto_8:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp10 < 2) {
goto tmp9_top;
}
goto goto_2;
tmp9_done2:;
}
}
;
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
_allPaths = tmpMeta15;
{
modelica_metatype _pt;
for (tmpMeta16 = _fqpaths; !listEmpty(tmpMeta16); tmpMeta16=MMC_CDR(tmpMeta16))
{
_pt = MMC_CAR(tmpMeta16);
_allPaths = omc_List_append__reverse(threadData, omc_InteractiveUtil_getAllInheritedClasses(threadData, _pt, _p), _allPaths);
}
}
_allPaths = listReverseInPlace(omc_List_unique(threadData, _allPaths));
tmpMeta1 = listAppend(_fqpaths, _allPaths);
goto tmp4_done;
}
case 1: {
modelica_metatype tmpMeta18;
tmpMeta18 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta18;
goto tmp4_done;
}
}
goto tmp4_end;
tmp4_end: ;
}
goto goto_2;
tmp4_done:
(void)tmp5;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp4_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp5 < 2) {
goto tmp4_top;
}
MMC_THROW_INTERNAL();
tmp4_done2:;
}
}
_outBaseClassNames = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outBaseClassNames;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getClassNamesRecursive(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_boolean _inShowProtected, modelica_boolean _includeConstants, modelica_metatype _inAcc, modelica_metatype *out_paths)
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
_cdef = omc_InteractiveUtil_getPathedClassInProgram(threadData, _pp, _p, 0, 0);
_strlst = omc_InteractiveUtil_getClassnamesInClassList(threadData, _pp, _p, _cdef, _b, _c);
_result_path_lst = omc_List_map(threadData, omc_List_map1(threadData, _strlst, boxvar_InteractiveUtil_joinPaths, _pp), boxvar_Util_makeOption);
omc_List_map3Fold(threadData, _result_path_lst, boxvar_InteractiveUtil_getClassNamesRecursive, _p, mmc_mk_boolean(_b), mmc_mk_boolean(_c), _acc ,&_acc);
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
omc_List_map3Fold(threadData, _result_path_lst, boxvar_InteractiveUtil_getClassNamesRecursive, _p, mmc_mk_boolean(_b), mmc_mk_boolean(_c), _acc ,&_acc);
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
_s1 = omc_AbsynUtil_pathString(threadData, _pp, _OMC_LIT5, 1, 0);
tmpMeta10 = mmc_mk_cons(_s1, mmc_mk_cons(_OMC_LIT11, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMessage(threadData, _OMC_LIT10, tmpMeta10);
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
modelica_metatype boxptr_InteractiveUtil_getClassNamesRecursive(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inShowProtected, modelica_metatype _includeConstants, modelica_metatype _inAcc, modelica_metatype *out_paths)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _opath = NULL;
tmp1 = mmc_unbox_integer(_inShowProtected);
tmp2 = mmc_unbox_integer(_includeConstants);
_opath = omc_InteractiveUtil_getClassNamesRecursive(threadData, _inPath, _inProgram, tmp1, tmp2, _inAcc, out_paths);
return _opath;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_joinPaths(threadData_t *threadData, modelica_string _child, modelica_metatype _parent)
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getClassnamesInClassList(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_boolean _inShowProtected, modelica_boolean _includeConstants)
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
tmpMeta1 = omc_InteractiveUtil_getClassnamesInParts(threadData, _parts, _b, _c);
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
tmpMeta1 = omc_InteractiveUtil_getClassnamesInParts(threadData, _parts, _b, _c);
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getClassnamesInClassList(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_metatype _inShowProtected, modelica_metatype _includeConstants)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outString = NULL;
tmp1 = mmc_unbox_integer(_inShowProtected);
tmp2 = mmc_unbox_integer(_includeConstants);
_outString = omc_InteractiveUtil_getClassnamesInClassList(threadData, _inPath, _inProgram, _inClass, tmp1, tmp2);
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getLocalVariablesInAlgorithmItem(threadData_t *threadData, modelica_metatype _inAbsynAlgorithmItem, modelica_boolean _inBoolean, modelica_metatype _inEnv)
{
modelica_string _outList = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_boolean tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inAbsynAlgorithmItem;
tmp4_2 = _inBoolean;
tmp4_3 = _inEnv;
{
modelica_metatype _env = NULL;
modelica_boolean _b;
modelica_metatype _elsItems = NULL;
modelica_metatype _els = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,21,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_elsItems = tmpMeta7;
_b = tmp4_2;
_env = tmp4_3;
_els = omc_Interactive_getComponentsInElementitems(threadData, _elsItems);
tmp1 = omc_Interactive_getComponentsInfo(threadData, _els, _b, _OMC_LIT13, _env);
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT14;
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
_outList = tmp1;
_return: OMC_LABEL_UNUSED
return _outList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getLocalVariablesInAlgorithmItem(threadData_t *threadData, modelica_metatype _inAbsynAlgorithmItem, modelica_metatype _inBoolean, modelica_metatype _inEnv)
{
modelica_integer tmp1;
modelica_string _outList = NULL;
tmp1 = mmc_unbox_integer(_inBoolean);
_outList = omc_InteractiveUtil_getLocalVariablesInAlgorithmItem(threadData, _inAbsynAlgorithmItem, tmp1, _inEnv);
return _outList;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getLocalVariablesInAlgorithmsItems(threadData_t *threadData, modelica_metatype _inAbsynAlgorithmItemLst, modelica_boolean _inBoolean, modelica_metatype _inEnv)
{
modelica_string _outList = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_boolean tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inAbsynAlgorithmItemLst;
tmp4_2 = _inBoolean;
tmp4_3 = _inEnv;
{
modelica_metatype _env = NULL;
modelica_boolean _b;
modelica_metatype _xs = NULL;
modelica_metatype _alg = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_alg = tmpMeta8;
_b = tmp4_2;
_env = tmp4_3;
tmp1 = omc_InteractiveUtil_getLocalVariablesInAlgorithmItem(threadData, _alg, _b, _env);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_1);
tmpMeta10 = MMC_CDR(tmp4_1);
_xs = tmpMeta10;
_b = tmp4_2;
_env = tmp4_3;
tmp4 += 1;
tmp1 = omc_InteractiveUtil_getLocalVariablesInAlgorithmsItems(threadData, _xs, _b, _env);
goto tmp3_done;
}
case 2: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp1 = _OMC_LIT14;
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
_outList = tmp1;
_return: OMC_LABEL_UNUSED
return _outList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getLocalVariablesInAlgorithmsItems(threadData_t *threadData, modelica_metatype _inAbsynAlgorithmItemLst, modelica_metatype _inBoolean, modelica_metatype _inEnv)
{
modelica_integer tmp1;
modelica_string _outList = NULL;
tmp1 = mmc_unbox_integer(_inBoolean);
_outList = omc_InteractiveUtil_getLocalVariablesInAlgorithmsItems(threadData, _inAbsynAlgorithmItemLst, tmp1, _inEnv);
return _outList;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getLocalVariablesInClassParts(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_boolean _inBoolean, modelica_metatype _inEnv)
{
modelica_string _outList = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_boolean tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inAbsynClassPartLst;
tmp4_2 = _inBoolean;
tmp4_3 = _inEnv;
{
modelica_metatype _env = NULL;
modelica_boolean _b;
modelica_metatype _algs = NULL;
modelica_metatype _xs = NULL;
modelica_string _strList = NULL;
modelica_string _strList1 = NULL;
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
modelica_boolean tmp10;
modelica_string tmp11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,5,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_algs = tmpMeta8;
_xs = tmpMeta7;
_b = tmp4_2;
_env = tmp4_3;
_strList1 = omc_InteractiveUtil_getLocalVariablesInAlgorithmsItems(threadData, _algs, _b, _env);
_strList = omc_InteractiveUtil_getLocalVariablesInClassParts(threadData, _xs, _b, _env);
tmp10 = (modelica_boolean)(stringEqual(_strList, _OMC_LIT14));
if(tmp10)
{
tmp11 = _strList1;
}
else
{
tmpMeta9 = mmc_mk_cons(_strList1, mmc_mk_cons(_OMC_LIT15, mmc_mk_cons(_strList, MMC_REFSTRUCTLIT(mmc_nil))));
tmp11 = stringAppendList(tmpMeta9);
}
tmp1 = tmp11;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_1);
tmpMeta13 = MMC_CDR(tmp4_1);
_xs = tmpMeta13;
_b = tmp4_2;
_env = tmp4_3;
tmp4 += 1;
tmp1 = omc_InteractiveUtil_getLocalVariablesInClassParts(threadData, _xs, _b, _env);
goto tmp3_done;
}
case 2: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp1 = _OMC_LIT14;
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
_outList = tmp1;
_return: OMC_LABEL_UNUSED
return _outList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getLocalVariablesInClassParts(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_metatype _inBoolean, modelica_metatype _inEnv)
{
modelica_integer tmp1;
modelica_string _outList = NULL;
tmp1 = mmc_unbox_integer(_inBoolean);
_outList = omc_InteractiveUtil_getLocalVariablesInClassParts(threadData, _inAbsynClassPartLst, tmp1, _inEnv);
return _outList;
}
DLLExport
modelica_string omc_InteractiveUtil_getLocalVariables(threadData_t *threadData, modelica_metatype _inClass, modelica_boolean _inBoolean, modelica_metatype _inEnv)
{
modelica_string _outList = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_boolean tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inClass;
tmp4_2 = _inBoolean;
tmp4_3 = _inEnv;
{
modelica_metatype _env = NULL;
modelica_boolean _b;
modelica_metatype _parts = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_parts = tmpMeta7;
_b = tmp4_2;
_env = tmp4_3;
tmp1 = omc_InteractiveUtil_getLocalVariablesInClassParts(threadData, _parts, _b, _env);
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
_env = tmp4_3;
tmp1 = omc_InteractiveUtil_getLocalVariablesInClassParts(threadData, _parts, _b, _env);
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
_outList = tmp1;
_return: OMC_LABEL_UNUSED
return _outList;
}
modelica_metatype boxptr_InteractiveUtil_getLocalVariables(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inBoolean, modelica_metatype _inEnv)
{
modelica_integer tmp1;
modelica_string _outList = NULL;
tmp1 = mmc_unbox_integer(_inBoolean);
_outList = omc_InteractiveUtil_getLocalVariables(threadData, _inClass, tmp1, _inEnv);
return _outList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_namedargToModification(threadData_t *threadData, modelica_metatype _inNamedArg)
{
modelica_metatype _outElementArg = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inNamedArg;
{
modelica_metatype _elts = NULL;
modelica_string _id = NULL;
modelica_metatype _c = NULL;
modelica_metatype _e = NULL;
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
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,11,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (!listEmpty(tmpMeta9)) goto tmp3_end;
_id = tmpMeta6;
_c = tmpMeta7;
tmpMeta10 = omc_InteractiveUtil_recordConstructorToModification(threadData, _c);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,6) == 0) goto goto_2;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 5));
if (optionNone(tmpMeta11)) goto goto_2;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 1));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 6));
if (!optionNone(tmpMeta14)) goto goto_2;
_elts = tmpMeta13;
tmpMeta15 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
tmpMeta16 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _elts, _OMC_LIT17);
tmpMeta17 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0), _OMC_LIT16, tmpMeta15, mmc_mk_some(tmpMeta16), mmc_mk_none(), _OMC_LIT19);
tmpMeta1 = tmpMeta17;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_id = tmpMeta18;
_e = tmpMeta19;
tmpMeta20 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
tmpMeta21 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta22 = mmc_mk_box3(4, &Absyn_EqMod_EQMOD__desc, _e, _OMC_LIT19);
tmpMeta23 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta21, tmpMeta22);
tmpMeta24 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0), _OMC_LIT16, tmpMeta20, mmc_mk_some(tmpMeta23), mmc_mk_none(), _OMC_LIT19);
tmpMeta1 = tmpMeta24;
goto tmp3_done;
}
case 2: {
omc_Print_printBuf(threadData, _OMC_LIT20);
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
_outElementArg = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElementArg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_recordConstructorToModification(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outElementArg = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _eltarglst = NULL;
modelica_metatype _emod = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _nargs = NULL;
modelica_metatype _e = NULL;
modelica_metatype _p = NULL;
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
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (!listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
if (!listEmpty(tmpMeta11)) goto tmp3_end;
_cr = tmpMeta6;
_e = tmpMeta9;
tmp4 += 1;
_p = omc_AbsynUtil_crefToPath(threadData, _cr);
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta13 = mmc_mk_box3(4, &Absyn_EqMod_EQMOD__desc, _e, _OMC_LIT19);
tmpMeta14 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta12, tmpMeta13);
tmpMeta15 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0), _OMC_LIT16, _p, mmc_mk_some(tmpMeta14), mmc_mk_none(), _OMC_LIT19);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,0,2) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
if (!listEmpty(tmpMeta18)) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 3));
_cr = tmpMeta16;
_nargs = tmpMeta19;
tmp4 += 1;
_eltarglst = omc_List_map(threadData, _nargs, boxvar_InteractiveUtil_namedargToModification);
_p = omc_AbsynUtil_crefToPath(threadData, _cr);
tmpMeta20 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _eltarglst, _OMC_LIT17);
tmpMeta21 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0), _OMC_LIT16, _p, mmc_mk_some(tmpMeta20), mmc_mk_none(), _OMC_LIT19);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,0,2) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
if (listEmpty(tmpMeta24)) goto tmp3_end;
tmpMeta25 = MMC_CAR(tmpMeta24);
tmpMeta26 = MMC_CDR(tmpMeta24);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,11,3) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta26)) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 3));
_cr = tmpMeta22;
_e = tmpMeta25;
_nargs = tmpMeta27;
_eltarglst = omc_List_map(threadData, _nargs, boxvar_InteractiveUtil_namedargToModification);
_emod = omc_InteractiveUtil_recordConstructorToModification(threadData, _e);
_p = omc_AbsynUtil_crefToPath(threadData, _cr);
tmpMeta28 = mmc_mk_cons(_emod, _eltarglst);
tmpMeta29 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta28, _OMC_LIT17);
tmpMeta30 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0), _OMC_LIT16, _p, mmc_mk_some(tmpMeta29), mmc_mk_none(), _OMC_LIT19);
tmpMeta1 = tmpMeta30;
goto tmp3_done;
}
case 3: {
omc_Print_printBuf(threadData, _OMC_LIT21);
omc_Dump_printExp(threadData, _inExp);
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
if (++tmp4 < 4) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outElementArg = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElementArg;
}
DLLExport
modelica_metatype omc_InteractiveUtil_annotationListToAbsyn(threadData_t *threadData, modelica_metatype _inAbsynNamedArgLst)
{
modelica_metatype _outAnnotation = NULL;
modelica_metatype _args = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_args = tmpMeta1;
{
modelica_metatype _arg;
for (tmpMeta2 = _inAbsynNamedArgLst; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_arg = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp6_1;
tmp6_1 = _arg;
{
modelica_metatype _eltarg = NULL;
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 3; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
if (8 != MMC_STRLEN(tmpMeta8) || strcmp(MMC_STRINGDATA(_OMC_LIT23), MMC_STRINGDATA(tmpMeta8)) != 0) goto tmp5_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 3));
_e = tmpMeta9;
_eltarg = omc_InteractiveUtil_recordConstructorToModification(threadData, _e);
tmpMeta10 = mmc_mk_cons(_eltarg, _args);
tmpMeta3 = tmpMeta10;
goto tmp5_done;
}
case 1: {
modelica_metatype tmpMeta11;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
if (7 != MMC_STRLEN(tmpMeta11) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmpMeta11)) != 0) goto tmp5_end;
tmpMeta3 = _args;
goto tmp5_done;
}
case 2: {
tmpMeta3 = _args;
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
_args = tmpMeta3;
}
}
tmpMeta13 = mmc_mk_box2(3, &Absyn_Annotation_ANNOTATION__desc, listReverseInPlace(_args));
_outAnnotation = tmpMeta13;
_return: OMC_LABEL_UNUSED
return _outAnnotation;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InteractiveUtil_compareClassName(threadData_t *threadData, modelica_metatype _cl, modelica_string _str)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cl;
{
modelica_string _c1name = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,4,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_c1name = tmpMeta7;
tmp1 = (stringEqual(_str, _c1name));
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_c1name = tmpMeta8;
tmp1 = (stringEqual(_str, _c1name));
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_compareClassName(threadData_t *threadData, modelica_metatype _cl, modelica_metatype _str)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_InteractiveUtil_compareClassName(threadData, _cl, _str);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getClassInProgram(threadData_t *threadData, modelica_string _inString, modelica_metatype _inProgram)
{
modelica_metatype _cl = NULL;
modelica_metatype _classes = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inProgram;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_classes = tmpMeta2;
_cl = omc_List_find1(threadData, _classes, boxvar_InteractiveUtil_compareClassName, _inString);
_return: OMC_LABEL_UNUSED
return _cl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getClassesInElts(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst)
{
modelica_metatype _outAbsynClassLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynElementItemLst;
{
modelica_metatype _res = NULL;
modelica_metatype _class_ = NULL;
modelica_metatype _rest = NULL;
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
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,6) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
_class_ = tmpMeta11;
_rest = tmpMeta8;
_res = omc_InteractiveUtil_getClassesInElts(threadData, _rest);
tmpMeta12 = mmc_mk_cons(_class_, _res);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
_rest = tmpMeta14;
_inAbsynElementItemLst = _rest;
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
_outAbsynClassLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynClassLst;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getClassesInParts(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAbsynClassLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _l1 = NULL;
modelica_metatype _l2 = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _rest = NULL;
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
tmp4 += 1;
_l1 = omc_InteractiveUtil_getClassesInParts(threadData, _rest);
_l2 = omc_InteractiveUtil_getClassesInElts(threadData, _elts);
tmpMeta1 = listAppend(_l1, _l2);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_elts = tmpMeta12;
_rest = tmpMeta11;
_l1 = omc_InteractiveUtil_getClassesInParts(threadData, _rest);
_l2 = omc_InteractiveUtil_getClassesInElts(threadData, _elts);
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
tmpMeta1 = omc_InteractiveUtil_getClassesInParts(threadData, _rest);
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
_outAbsynClassLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynClassLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getClassesInClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _outAbsynClassLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_metatype _parts = NULL;
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
tmpMeta1 = omc_InteractiveUtil_getClassesInParts(threadData, _parts);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
_parts = tmpMeta9;
tmpMeta1 = omc_InteractiveUtil_getClassesInParts(threadData, _parts);
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
_outAbsynClassLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynClassLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getClassInClass(threadData_t *threadData, modelica_string _inString, modelica_metatype _inClass)
{
modelica_metatype _outClass = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClass = omc_List_find1(threadData, omc_InteractiveUtil_getClassesInClass(threadData, _inClass), boxvar_InteractiveUtil_compareClassName, _inString);
_return: OMC_LABEL_UNUSED
return _outClass;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getPathedClassInProgramWorkNoThrow(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inClass)
{
modelica_metatype _outClass = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
{
modelica_metatype tmp8_1;
tmp8_1 = _inPath;
{
modelica_metatype _c = NULL;
modelica_string _str = NULL;
modelica_metatype _path = NULL;
int tmp8;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp8_1))) {
case 4: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,1,1) == 0) goto tmp7_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 2));
_str = tmpMeta9;
tmpMeta5 = omc_InteractiveUtil_getClassInClass(threadData, _str, _inClass);
goto tmp7_done;
}
case 5: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,2,1) == 0) goto tmp7_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 2));
_path = tmpMeta10;
tmpMeta5 = omc_InteractiveUtil_getPathedClassInProgramWorkNoThrow(threadData, _path, _inClass);
goto tmp7_done;
}
case 3: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,0,2) == 0) goto tmp7_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 3));
_str = tmpMeta11;
_path = tmpMeta12;
_c = omc_InteractiveUtil_getClassInClass(threadData, _str, _inClass);
tmpMeta5 = omc_InteractiveUtil_getPathedClassInProgramWorkNoThrow(threadData, _path, _c);
goto tmp7_done;
}
}
goto tmp7_end;
tmp7_end: ;
}
goto goto_6;
goto_6:;
goto goto_1;
goto tmp7_done;
tmp7_done:;
}
}
_outClass = tmpMeta5;
goto tmp2_done;
}
case 1: {
_outClass = _inClass;
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
return _outClass;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getPathedClassInProgramWorkThrow(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inClass)
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
modelica_string _str = NULL;
modelica_metatype _path = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta5;
tmpMeta1 = omc_InteractiveUtil_getClassInClass(threadData, _str, _inClass);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta6;
_inPath = _path;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_str = tmpMeta7;
_path = tmpMeta8;
_c = omc_InteractiveUtil_getClassInClass(threadData, _str, _inClass);
_inPath = _path;
_inClass = _c;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getPathedClassInProgramWork(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_boolean _enclOnErr)
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
modelica_string _str = NULL;
modelica_metatype _path = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_str = tmpMeta5;
tmpMeta1 = omc_InteractiveUtil_getClassInProgram(threadData, _str, _inProgram);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_path = tmpMeta6;
tmpMeta1 = omc_InteractiveUtil_getPathedClassInProgram(threadData, _path, _inProgram, _enclOnErr, 0);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_str = tmpMeta7;
_path = tmpMeta8;
_c = omc_InteractiveUtil_getClassInProgram(threadData, _str, _inProgram);
tmpMeta1 = (_enclOnErr?omc_InteractiveUtil_getPathedClassInProgramWorkNoThrow(threadData, _path, _c):omc_InteractiveUtil_getPathedClassInProgramWorkThrow(threadData, _path, _c));
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getPathedClassInProgramWork(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _enclOnErr)
{
modelica_integer tmp1;
modelica_metatype _outClass = NULL;
tmp1 = mmc_unbox_integer(_enclOnErr);
_outClass = omc_InteractiveUtil_getPathedClassInProgramWork(threadData, _inPath, _inProgram, tmp1);
return _outClass;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getPathedClassInProgram(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_boolean _enclOnErr, modelica_boolean _showError)
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
tmpMeta1 = omc_InteractiveUtil_getPathedClassInProgramWork(threadData, _inPath, _inProgram, _enclOnErr);
goto tmp3_done;
}
case 1: {
tmpMeta1 = omc_InteractiveUtil_getPathedClassInProgramWork(threadData, _inPath, omc_FBuiltin_getInitialFunctions(threadData, NULL), _enclOnErr);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta6;
if(_showError)
{
tmpMeta6 = mmc_mk_cons(omc_AbsynUtil_pathString(threadData, _inPath, _OMC_LIT5, 1, 0), mmc_mk_cons(_OMC_LIT11, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMessage(threadData, _OMC_LIT10, tmpMeta6);
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
modelica_metatype boxptr_InteractiveUtil_getPathedClassInProgram(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _enclOnErr, modelica_metatype _showError)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outClass = NULL;
tmp1 = mmc_unbox_integer(_enclOnErr);
tmp2 = mmc_unbox_integer(_showError);
_outClass = omc_InteractiveUtil_getPathedClassInProgram(threadData, _inPath, _inProgram, tmp1, tmp2);
return _outClass;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InteractiveUtil_classInProgram(threadData_t *threadData, modelica_string _name, modelica_metatype _p)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
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
return _b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_classInProgram(threadData_t *threadData, modelica_metatype _name, modelica_metatype _p)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_InteractiveUtil_classInProgram(threadData, _name, _p);
out_b = mmc_mk_icon(_b);
return out_b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getClassFromElementitemlist(threadData_t *threadData, modelica_metatype _inElements, modelica_string _inIdent)
{
modelica_metatype _outClass = NULL;
modelica_metatype _elem = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elem = omc_List_getMemberOnTrue(threadData, _inIdent, _inElements, boxvar_InteractiveUtil_classElementItemIsNamed);
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
DLLExport
modelica_metatype omc_InteractiveUtil_getEquationList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAbsynEquationItemLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _lst = NULL;
modelica_metatype _xs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_lst = tmpMeta8;
tmpMeta1 = _lst;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_1);
tmpMeta10 = MMC_CDR(tmp4_1);
_xs = tmpMeta10;
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
_outAbsynEquationItemLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynEquationItemLst;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getProtectedList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
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
_res2 = omc_InteractiveUtil_getProtectedList(threadData, _rest);
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
DLLExport
modelica_metatype omc_InteractiveUtil_getPublicList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
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
_res2 = omc_InteractiveUtil_getPublicList(threadData, _rest);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_deleteProtectedList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
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
_res = omc_InteractiveUtil_deleteProtectedList(threadData, _xs);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_deletePublicList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
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
_res = omc_InteractiveUtil_deletePublicList(threadData, _xs);
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
DLLExport
modelica_metatype omc_InteractiveUtil_replaceEquationList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_metatype _inAbsynEquationItemLst)
{
modelica_metatype _outAbsynClassPartLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inAbsynClassPartLst;
tmp4_2 = _inAbsynEquationItemLst;
{
modelica_metatype _x = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _ys = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _newequationlst = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,1) == 0) goto tmp3_end;
_rest = tmpMeta7;
_newequationlst = tmp4_2;
tmpMeta9 = mmc_mk_box2(6, &Absyn_ClassPart_EQUATIONS__desc, _newequationlst);
tmpMeta8 = mmc_mk_cons(tmpMeta9, _rest);
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
_ys = omc_InteractiveUtil_replaceEquationList(threadData, _xs, _new);
tmpMeta12 = mmc_mk_cons(_x, _ys);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
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
DLLExport
modelica_metatype omc_InteractiveUtil_replaceProtectedList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_metatype _inAbsynElementItemLst)
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
_rest_1 = omc_InteractiveUtil_deleteProtectedList(threadData, _rest);
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
_ys = omc_InteractiveUtil_replaceProtectedList(threadData, _xs, _new);
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
DLLExport
modelica_metatype omc_InteractiveUtil_replacePublicList(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_metatype _inAbsynElementItemLst)
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
_rest_1 = omc_InteractiveUtil_deletePublicList(threadData, _rest);
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
_ys = omc_InteractiveUtil_replacePublicList(threadData, _xs, _new);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getInnerClass(threadData_t *threadData, modelica_metatype _inClass, modelica_string _inIdent)
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
_publst = omc_InteractiveUtil_getPublicList(threadData, _parts);
tmpMeta1 = omc_InteractiveUtil_getClassFromElementitemlist(threadData, _publst, _name);
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
_prolst = omc_InteractiveUtil_getProtectedList(threadData, _parts);
tmpMeta1 = omc_InteractiveUtil_getClassFromElementitemlist(threadData, _prolst, _name);
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
_publst = omc_InteractiveUtil_getPublicList(threadData, _parts);
tmpMeta1 = omc_InteractiveUtil_getClassFromElementitemlist(threadData, _publst, _name);
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
_prolst = omc_InteractiveUtil_getProtectedList(threadData, _parts);
tmpMeta1 = omc_InteractiveUtil_getClassFromElementitemlist(threadData, _prolst, _name);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_addClassInElementitemlist(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _inClass)
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
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 10));
_info = tmpMeta2;
tmpMeta4 = mmc_mk_box3(3, &Absyn_ElementSpec_CLASSDEF__desc, mmc_mk_boolean(0), _inClass);
tmpMeta5 = mmc_mk_box7(3, &Absyn_Element_ELEMENT__desc, mmc_mk_boolean(0), mmc_mk_none(), _OMC_LIT25, tmpMeta4, _info, mmc_mk_none());
tmpMeta6 = mmc_mk_box2(3, &Absyn_ElementItem_ELEMENTITEM__desc, tmpMeta5);
tmpMeta3 = mmc_mk_cons(tmpMeta6, MMC_REFSTRUCTLIT(mmc_nil));
_outAbsynElementItemLst = listAppend(_inAbsynElementItemLst, tmpMeta3);
_return: OMC_LABEL_UNUSED
return _outAbsynElementItemLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_replaceClassInElementitemlist(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _inClass, modelica_boolean _mergeAST, modelica_boolean *out_replaced)
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
_c = (_mergeAST?omc_InteractiveUtil_mergeClasses(threadData, _c2, _c1):_c2);
tmpMeta20 = _c;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 10));
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
_res = omc_InteractiveUtil_replaceClassInElementitemlist(threadData, _xs, _c, _mergeAST ,&_replaced);
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_replaceClassInElementitemlist(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _inClass, modelica_metatype _mergeAST, modelica_metatype *out_replaced)
{
modelica_integer tmp1;
modelica_boolean _replaced;
modelica_metatype _outAbsynElementItemLst = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outAbsynElementItemLst = omc_InteractiveUtil_replaceClassInElementitemlist(threadData, _inAbsynElementItemLst, _inClass, tmp1, &_replaced);
if (out_replaced) { *out_replaced = mmc_mk_icon(_replaced); }
return _outAbsynElementItemLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_replaceInnerClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inClass2, modelica_boolean _mergeAST)
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
_publst = omc_InteractiveUtil_getPublicList(threadData, _parts);
tmpMeta13 = omc_InteractiveUtil_replaceClassInElementitemlist(threadData, _publst, _c1, _mergeAST, &tmp12);
_publst2 = tmpMeta13;
if (1 != tmp12) goto goto_2;
_parts2 = omc_InteractiveUtil_replacePublicList(threadData, _parts, _publst2);
tmpMeta15 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars, _classAttrs, _parts2, _ann, _cmt);
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
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
_prolst = omc_InteractiveUtil_getProtectedList(threadData, _parts);
tmpMeta23 = omc_InteractiveUtil_replaceClassInElementitemlist(threadData, _prolst, _c1, _mergeAST, &tmp22);
_prolst2 = tmpMeta23;
if (1 != tmp22) goto goto_2;
_parts2 = omc_InteractiveUtil_replaceProtectedList(threadData, _parts, _prolst2);
tmpMeta25 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars, _classAttrs, _parts2, _ann, _cmt);
tmpMeta24 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta24), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
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
_publst = omc_InteractiveUtil_getPublicList(threadData, _parts);
_publst = omc_InteractiveUtil_addClassInElementitemlist(threadData, _publst, _c1);
_parts2 = omc_InteractiveUtil_replacePublicList(threadData, _parts, _publst);
tmpMeta33 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars, _classAttrs, _parts2, _ann, _cmt);
tmpMeta32 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta32), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
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
_publst = omc_InteractiveUtil_getPublicList(threadData, _parts);
tmpMeta41 = omc_InteractiveUtil_replaceClassInElementitemlist(threadData, _publst, _c1, _mergeAST, &tmp40);
_publst2 = tmpMeta41;
if (1 != tmp40) goto goto_2;
_parts2 = omc_InteractiveUtil_replacePublicList(threadData, _parts, _publst2);
tmpMeta43 = mmc_mk_box6(7, &Absyn_ClassDef_CLASS__EXTENDS__desc, _bcname, _modif, _cmt, _parts2, _ann);
tmpMeta42 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta42), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
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
_prolst = omc_InteractiveUtil_getProtectedList(threadData, _parts);
tmpMeta51 = omc_InteractiveUtil_replaceClassInElementitemlist(threadData, _prolst, _c1, _mergeAST, &tmp50);
_prolst2 = tmpMeta51;
if (1 != tmp50) goto goto_2;
_parts2 = omc_InteractiveUtil_replaceProtectedList(threadData, _parts, _prolst2);
tmpMeta53 = mmc_mk_box6(7, &Absyn_ClassDef_CLASS__EXTENDS__desc, _bcname, _modif, _cmt, _parts2, _ann);
tmpMeta52 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta52), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
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
_publst = omc_InteractiveUtil_getPublicList(threadData, _parts);
_publst = omc_InteractiveUtil_addClassInElementitemlist(threadData, _publst, _c1);
_parts2 = omc_InteractiveUtil_replacePublicList(threadData, _parts, _publst);
tmpMeta61 = mmc_mk_box6(7, &Absyn_ClassDef_CLASS__EXTENDS__desc, _bcname, _modif, _cmt, _parts2, _ann);
tmpMeta60 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta60), MMC_UNTAGPTR(_outClass), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta60))[7] = tmpMeta61;
_outClass = tmpMeta60;
tmpMeta1 = _outClass;
goto tmp3_done;
}
case 6: {
omc_Print_printBuf(threadData, _OMC_LIT26);
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_replaceInnerClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inClass2, modelica_metatype _mergeAST)
{
modelica_integer tmp1;
modelica_metatype _outClass = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outClass = omc_InteractiveUtil_replaceInnerClass(threadData, _inClass1, _inClass2, tmp1);
return _outClass;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InteractiveUtil_classElementItemIsNamed(threadData_t *threadData, modelica_string _inClassName, modelica_metatype _inElement)
{
modelica_boolean _outIsNamed;
modelica_boolean tmp1 = 0;
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
return _outIsNamed;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_classElementItemIsNamed(threadData_t *threadData, modelica_metatype _inClassName, modelica_metatype _inElement)
{
modelica_boolean _outIsNamed;
modelica_metatype out_outIsNamed;
_outIsNamed = omc_InteractiveUtil_classElementItemIsNamed(threadData, _inClassName, _inElement);
out_outIsNamed = mmc_mk_icon(_outIsNamed);
return out_outIsNamed;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getFirstIdentFromPath(threadData_t *threadData, modelica_metatype _inPath)
{
modelica_string _outIdent = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
modelica_string _name = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta6;
tmp1 = _name;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta7;
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
_outIdent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIdent;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_insertClassInClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inWithin2, modelica_metatype _inClass3, modelica_boolean _mergeAST)
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
tmpMeta1 = omc_InteractiveUtil_replaceInnerClass(threadData, _c1, _c2, _mergeAST);
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
_name2 = omc_InteractiveUtil_getFirstIdentFromPath(threadData, _path);
_cinner = omc_InteractiveUtil_getInnerClass(threadData, _c2, _name2);
tmpMeta9 = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, _path);
_cnew = omc_InteractiveUtil_insertClassInClass(threadData, _c1, tmpMeta9, _cinner, _mergeAST);
tmpMeta1 = omc_InteractiveUtil_replaceInnerClass(threadData, _cnew, _c2, _mergeAST);
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_insertClassInClass(threadData_t *threadData, modelica_metatype _inClass1, modelica_metatype _inWithin2, modelica_metatype _inClass3, modelica_metatype _mergeAST)
{
modelica_integer tmp1;
modelica_metatype _outClass = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outClass = omc_InteractiveUtil_insertClassInClass(threadData, _inClass1, _inWithin2, _inClass3, tmp1);
return _outClass;
}
DLLExport
modelica_metatype omc_InteractiveUtil_insertClassInProgram(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inWithin, modelica_metatype _inProgram, modelica_boolean _mergeAST)
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
_c2 = omc_InteractiveUtil_getClassInProgram(threadData, _n1, _p);
_c3 = omc_InteractiveUtil_insertClassInClass(threadData, _c1, _w, _c2, _mergeAST);
tmpMeta8 = mmc_mk_cons(_c3, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta9 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta8, _OMC_LIT12);
tmpMeta1 = omc_InteractiveUtil_updateProgram(threadData, tmpMeta9, _p, _mergeAST);
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
_c2 = omc_InteractiveUtil_getClassInProgram(threadData, _n1, _p);
_c3 = omc_InteractiveUtil_insertClassInClass(threadData, _c1, _w, _c2, _mergeAST);
tmpMeta12 = mmc_mk_cons(_c3, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta13 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta12, _OMC_LIT12);
tmpMeta1 = omc_InteractiveUtil_updateProgram(threadData, tmpMeta13, _p, _mergeAST);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,0,2) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
if (12 != MMC_STRLEN(tmpMeta15) || strcmp(MMC_STRINGDATA(_OMC_LIT31), MMC_STRINGDATA(tmpMeta15)) != 0) goto tmp3_end;
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
omc_InteractiveUtil_getClassNamesRecursive(threadData, mmc_mk_none(), _p, 0, 0, tmpMeta17 ,&_paths);
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
__omcQ_24tmpVar0 = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT5, 1, 0);
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
_s2 = stringAppendList(omc_List_map1r(threadData, tmpMeta18, boxvar_stringAppend, _OMC_LIT27));
tmpMeta22 = mmc_mk_cons(_name, mmc_mk_cons(_s1, mmc_mk_cons(_s2, MMC_REFSTRUCTLIT(mmc_nil))));
omc_Error_addMessage(threadData, _OMC_LIT30, tmpMeta22);
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
modelica_metatype boxptr_InteractiveUtil_insertClassInProgram(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inWithin, modelica_metatype _inProgram, modelica_metatype _mergeAST)
{
modelica_integer tmp1;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outProgram = omc_InteractiveUtil_insertClassInProgram(threadData, _inClass, _inWithin, _inProgram, tmp1);
return _outProgram;
}
static modelica_metatype closure0_InteractiveUtil_replaceClassInProgram2(threadData_t *thData, modelica_metatype closure, modelica_metatype inClass)
{
modelica_string inClassName = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_InteractiveUtil_replaceClassInProgram2(thData, inClass, inClassName);
}static modelica_metatype closure1_InteractiveUtil_replaceClassInProgram2(threadData_t *thData, modelica_metatype closure, modelica_metatype inClass)
{
modelica_string inClassName = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_InteractiveUtil_replaceClassInProgram2(thData, inClass, inClassName);
}
DLLExport
modelica_metatype omc_InteractiveUtil_replaceClassInProgram(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inProgram, modelica_boolean _mergeAST)
{
modelica_metatype _outProgram = NULL;
modelica_string _cls_name1 = NULL;
modelica_string _cls_name2 = NULL;
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
_clsFilter = omc_List_filterOnTrue(threadData, _clst, (modelica_fnptr) mmc_mk_box2(0,closure0_InteractiveUtil_replaceClassInProgram2,tmpMeta6));
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
_cls = omc_InteractiveUtil_mergeClasses(threadData, _inClass, _cls);
}
}
else
{
_cls = _inClass;
}
tmpMeta10 = mmc_mk_box1(0, _cls_name1);
_clst = omc_List_replaceOnTrue(threadData, _cls, _clst, (modelica_fnptr) mmc_mk_box2(0,closure1_InteractiveUtil_replaceClassInProgram2,tmpMeta10) ,&_replaced);
if((!_replaced))
{
_clst = omc_List_appendElt(threadData, _inClass, _clst);
}
tmpMeta11 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, _clst, _w);
_outProgram = tmpMeta11;
_return: OMC_LABEL_UNUSED
return _outProgram;
}
modelica_metatype boxptr_InteractiveUtil_replaceClassInProgram(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inProgram, modelica_metatype _mergeAST)
{
modelica_integer tmp1;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outProgram = omc_InteractiveUtil_replaceClassInProgram(threadData, _inClass, _inProgram, tmp1);
return _outProgram;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InteractiveUtil_replaceClassInProgram2(threadData_t *threadData, modelica_metatype _inClass, modelica_string _inClassName)
{
modelica_boolean _outReplace;
modelica_string _cls_name = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inClass;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_cls_name = tmpMeta2;
_outReplace = (stringEqual(_cls_name, _inClassName));
_return: OMC_LABEL_UNUSED
return _outReplace;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_replaceClassInProgram2(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inClassName)
{
modelica_boolean _outReplace;
modelica_metatype out_outReplace;
_outReplace = omc_InteractiveUtil_replaceClassInProgram2(threadData, _inClass, _inClassName);
out_outReplace = mmc_mk_icon(_outReplace);
return out_outReplace;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getComponentItemsName(threadData_t *threadData, modelica_metatype _inComponents, modelica_boolean _inQuoteNames)
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
tmpMeta10 = mmc_mk_cons(_OMC_LIT32, mmc_mk_cons(_name, mmc_mk_cons(_OMC_LIT32, MMC_REFSTRUCTLIT(mmc_nil))));
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
modelica_metatype boxptr_InteractiveUtil_getComponentItemsName(threadData_t *threadData, modelica_metatype _inComponents, modelica_metatype _inQuoteNames)
{
modelica_integer tmp1;
modelica_metatype _outStrings = NULL;
modelica_metatype tmpMeta2;
tmp1 = mmc_unbox_integer(_inQuoteNames);
_outStrings = omc_InteractiveUtil_getComponentItemsName(threadData, _inComponents, tmp1);
return _outStrings;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getComponentItemsNameAndComment(threadData_t *threadData, modelica_metatype _inComponents, modelica_boolean _inQuoteNames)
{
modelica_metatype _outStrings = NULL;
modelica_metatype tmpMeta1;
modelica_string _name = NULL;
modelica_string _cmt_str = NULL;
modelica_string _str = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta14;
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
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
modelica_string tmp13;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_name = tmpMeta8;
_cmt_str = omc_InteractiveUtil_getClassCommentInCommentOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_comp), 4))));
tmp12 = (modelica_boolean)_inQuoteNames;
if(tmp12)
{
tmpMeta10 = mmc_mk_cons(_OMC_LIT32, mmc_mk_cons(_name, mmc_mk_cons(_OMC_LIT33, mmc_mk_cons(_cmt_str, mmc_mk_cons(_OMC_LIT32, MMC_REFSTRUCTLIT(mmc_nil))))));
tmp13 = stringAppendList(tmpMeta10);
}
else
{
tmpMeta11 = mmc_mk_cons(_name, mmc_mk_cons(_OMC_LIT34, mmc_mk_cons(_cmt_str, mmc_mk_cons(_OMC_LIT32, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp13 = stringAppendList(tmpMeta11);
}
tmpMeta9 = mmc_mk_cons(tmp13, _outStrings);
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
modelica_metatype boxptr_InteractiveUtil_getComponentItemsNameAndComment(threadData_t *threadData, modelica_metatype _inComponents, modelica_metatype _inQuoteNames)
{
modelica_integer tmp1;
modelica_metatype _outStrings = NULL;
modelica_metatype tmpMeta2;
tmp1 = mmc_unbox_integer(_inQuoteNames);
_outStrings = omc_InteractiveUtil_getComponentItemsNameAndComment(threadData, _inComponents, tmp1);
return _outStrings;
}
DLLExport
modelica_metatype omc_InteractiveUtil_prefixTypename(threadData_t *threadData, modelica_string _inType, modelica_metatype _inComponents)
{
modelica_metatype _outComponents = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_string __omcQ_24tmpVar2;
modelica_integer tmp5;
modelica_metatype _c_loopVar = 0;
modelica_metatype _c;
_c_loopVar = _inComponents;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar3;
while(1) {
tmp5 = 1;
if (!listEmpty(_c_loopVar)) {
_c = MMC_CAR(_c_loopVar);
_c_loopVar = MMC_CDR(_c_loopVar);
tmp5--;
}
if (tmp5 == 0) {
tmpMeta4 = mmc_mk_cons(_inType, mmc_mk_cons(_OMC_LIT35, mmc_mk_cons(_c, MMC_REFSTRUCTLIT(mmc_nil))));
__omcQ_24tmpVar2 = stringAppendList(tmpMeta4);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp5 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar3;
}
_outComponents = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComponents;
}
DLLExport
modelica_metatype omc_InteractiveUtil_suffixInfos(threadData_t *threadData, modelica_metatype _eltInfo, modelica_metatype _idims, modelica_string _typeAd, modelica_string _suffix, modelica_boolean _inQuoteNames)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_boolean tmp4_3;
tmp4_1 = _eltInfo;
tmp4_2 = _idims;
tmp4_3 = _inQuoteNames;
{
modelica_metatype _res = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _dims = NULL;
modelica_string _str_1 = NULL;
modelica_string _str = NULL;
modelica_string _dim = NULL;
modelica_string _s1 = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
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
modelica_metatype tmpMeta13;
modelica_boolean tmp14;
modelica_string tmp15;
modelica_metatype tmpMeta16;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_2);
tmpMeta10 = MMC_CDR(tmp4_2);
_str = tmpMeta7;
_rest = tmpMeta8;
_dim = tmpMeta9;
_dims = tmpMeta10;
_b = tmp4_3;
_res = omc_InteractiveUtil_suffixInfos(threadData, _rest, _dims, _typeAd, _suffix, _b);
tmpMeta11 = mmc_mk_cons(_dim, mmc_mk_cons(_typeAd, MMC_REFSTRUCTLIT(mmc_nil)));
_s1 = omc_Util_stringDelimitListNonEmptyElts(threadData, tmpMeta11, _OMC_LIT15);
tmp14 = (modelica_boolean)_b;
if(tmp14)
{
tmpMeta12 = mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT35, mmc_mk_cons(_suffix, mmc_mk_cons(_OMC_LIT36, mmc_mk_cons(_s1, mmc_mk_cons(_OMC_LIT37, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp15 = stringAppendList(tmpMeta12);
}
else
{
tmpMeta13 = mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT35, mmc_mk_cons(_suffix, mmc_mk_cons(_OMC_LIT38, mmc_mk_cons(_s1, mmc_mk_cons(_OMC_LIT39, MMC_REFSTRUCTLIT(mmc_nil)))))));
tmp15 = stringAppendList(tmpMeta13);
}
_str_1 = tmp15;
tmpMeta16 = mmc_mk_cons(_str_1, _res);
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
_outStringLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStringLst;
}
modelica_metatype boxptr_InteractiveUtil_suffixInfos(threadData_t *threadData, modelica_metatype _eltInfo, modelica_metatype _idims, modelica_metatype _typeAd, modelica_metatype _suffix, modelica_metatype _inQuoteNames)
{
modelica_integer tmp1;
modelica_metatype _outStringLst = NULL;
tmp1 = mmc_unbox_integer(_inQuoteNames);
_outStringLst = omc_InteractiveUtil_suffixInfos(threadData, _eltInfo, _idims, _typeAd, _suffix, tmp1);
return _outStringLst;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getComponentitemsDimension(threadData_t *threadData, modelica_metatype _inAbsynComponentItemLst)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inAbsynComponentItemLst;
{
modelica_string _str = NULL;
modelica_metatype _lst = NULL;
modelica_metatype _c2 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _ad = NULL;
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
modelica_metatype tmpMeta13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta7);
tmpMeta11 = MMC_CDR(tmpMeta7);
_ad = tmpMeta9;
_c2 = tmpMeta10;
_rest = tmpMeta11;
tmpMeta12 = mmc_mk_cons(_c2, _rest);
_lst = omc_InteractiveUtil_getComponentitemsDimension(threadData, tmpMeta12);
_str = stringDelimitList(omc_List_map(threadData, _ad, boxvar_Dump_printSubscriptStr), _OMC_LIT15);
tmpMeta13 = mmc_mk_cons(_str, _lst);
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmp4_1);
tmpMeta15 = MMC_CDR(tmp4_1);
_rest = tmpMeta15;
tmpMeta1 = omc_InteractiveUtil_getComponentitemsDimension(threadData, _rest);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_1);
tmpMeta17 = MMC_CDR(tmp4_1);
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
if (!listEmpty(tmpMeta17)) goto tmp3_end;
_ad = tmpMeta19;
_str = stringDelimitList(omc_List_map(threadData, _ad, boxvar_Dump_printSubscriptStr), _OMC_LIT15);
tmpMeta20 = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta21 = MMC_CAR(tmp4_1);
tmpMeta22 = MMC_CDR(tmp4_1);
if (!listEmpty(tmpMeta22)) goto tmp3_end;
tmpMeta23 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta23;
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
DLLExport
modelica_string omc_InteractiveUtil_attrDirectionStr(threadData_t *threadData, modelica_metatype _inElementAttributes)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementAttributes;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT40;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT41;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT42;
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
modelica_string omc_InteractiveUtil_attrDimensionStr(threadData_t *threadData, modelica_metatype _inElementAttributes)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementAttributes;
{
modelica_metatype _ad = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_ad = tmpMeta6;
tmp1 = omc_InteractiveUtil_arrayDimensionStr(threadData, mmc_mk_some(_ad));
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
modelica_string omc_InteractiveUtil_attrVariabilityStr(threadData_t *threadData, modelica_metatype _inElementAttributes)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementAttributes;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT42;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT43;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT44;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta9;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,0) == 0) goto tmp3_end;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_InteractiveUtil_attrParallelismStr(threadData_t *threadData, modelica_metatype _inElementAttributes)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementAttributes;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT46;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT47;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT14;
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
modelica_string omc_InteractiveUtil_attrStreamStr(threadData_t *threadData, modelica_metatype _inElementAttributes)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementAttributes;
{
modelica_boolean _s;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp7 = mmc_unbox_integer(tmpMeta6);
_s = tmp7;
tmp1 = (_s?_OMC_LIT48:_OMC_LIT49);
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
modelica_string omc_InteractiveUtil_attrFlowStr(threadData_t *threadData, modelica_metatype _inElementAttributes)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementAttributes;
{
modelica_boolean _f;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
_f = tmp7;
tmp1 = (_f?_OMC_LIT48:_OMC_LIT49);
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
modelica_string omc_InteractiveUtil_innerOuterStr(threadData_t *threadData, modelica_metatype _inInnerOuter)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inInnerOuter;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT50;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT51;
goto tmp3_done;
}
case 6: {
tmp1 = _OMC_LIT52;
goto tmp3_done;
}
case 5: {
tmp1 = _OMC_LIT53;
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
modelica_boolean omc_InteractiveUtil_keywordReplaceable(threadData_t *threadData, modelica_metatype _inAbsynRedeclareKeywordsOption)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynRedeclareKeywordsOption;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,2,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_InteractiveUtil_keywordReplaceable(threadData_t *threadData, modelica_metatype _inAbsynRedeclareKeywordsOption)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_InteractiveUtil_keywordReplaceable(threadData, _inAbsynRedeclareKeywordsOption);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementsInfo2(threadData_t *threadData, modelica_metatype _inAbsynElementLst, modelica_boolean _inBoolean, modelica_string _inString, modelica_metatype _inEnv, modelica_metatype _acc)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_boolean tmp4_2;modelica_string tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _inAbsynElementLst;
tmp4_2 = _inBoolean;
tmp4_3 = _inString;
tmp4_4 = _inEnv;
{
modelica_metatype _res = NULL;
modelica_metatype _elt = NULL;
modelica_metatype _rest = NULL;
modelica_string _access = NULL;
modelica_metatype _env = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = listReverse(_acc);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_elt = tmpMeta6;
_rest = tmpMeta7;
_b = tmp4_2;
_access = tmp4_3;
_env = tmp4_4;
_res = omc_InteractiveUtil_getElementInfo(threadData, _elt, _b, _access, _env);
_inAbsynElementLst = _rest;
_inBoolean = _b;
_inString = _access;
_inEnv = _env;
_acc = omc_List_append__reverse(threadData, _res, _acc);
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
_outStringLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStringLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getElementsInfo2(threadData_t *threadData, modelica_metatype _inAbsynElementLst, modelica_metatype _inBoolean, modelica_metatype _inString, modelica_metatype _inEnv, modelica_metatype _acc)
{
modelica_integer tmp1;
modelica_metatype _outStringLst = NULL;
tmp1 = mmc_unbox_integer(_inBoolean);
_outStringLst = omc_InteractiveUtil_getElementsInfo2(threadData, _inAbsynElementLst, tmp1, _inString, _inEnv, _acc);
return _outStringLst;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getElementsInfo(threadData_t *threadData, modelica_metatype _inAbsynElementLst, modelica_boolean _inBoolean, modelica_string _inString, modelica_metatype _inEnv)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_string tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inAbsynElementLst;
tmp4_2 = _inString;
tmp4_3 = _inEnv;
{
modelica_metatype _lst = NULL;
modelica_string _lst_1 = NULL;
modelica_string _access = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _env = NULL;
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
_elts = tmp4_1;
_access = tmp4_2;
_env = tmp4_3;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta7 = omc_InteractiveUtil_getElementsInfo2(threadData, _elts, _inBoolean, _access, _env, tmpMeta6);
if (listEmpty(tmpMeta7)) goto goto_2;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
_lst = tmpMeta7;
_lst_1 = stringDelimitList(_lst, _OMC_LIT54);
tmpMeta10 = mmc_mk_cons(_OMC_LIT55, mmc_mk_cons(_lst_1, mmc_mk_cons(_OMC_LIT39, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta10);
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT14;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getElementsInfo(threadData_t *threadData, modelica_metatype _inAbsynElementLst, modelica_metatype _inBoolean, modelica_metatype _inString, modelica_metatype _inEnv)
{
modelica_integer tmp1;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_inBoolean);
_outString = omc_InteractiveUtil_getElementsInfo(threadData, _inAbsynElementLst, tmp1, _inString, _inEnv);
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_arrayDimensionStr(threadData_t *threadData, modelica_metatype _ad)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ad;
{
modelica_metatype _adim = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_adim = tmpMeta6;
tmp1 = stringDelimitList(omc_List_map(threadData, _adim, boxvar_Dump_printSubscriptStr), _OMC_LIT15);
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT14;
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
modelica_metatype omc_InteractiveUtil_qualifyType(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _p)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _fqp = NULL;
modelica_metatype _oenv_path = NULL;
modelica_metatype _env_path = NULL;
modelica_metatype _tp_path = NULL;
modelica_metatype _pkg_path = NULL;
modelica_string _tp_name = NULL;
modelica_metatype _env = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_fqp = _p;
if(omc_AbsynUtil_pathIsFullyQualified(threadData, _p))
{
goto _return;
}
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
omc_Lookup_lookupClass(threadData, omc_FCore_emptyCache(threadData), _inEnv, _p, mmc_mk_none() ,NULL ,&_env);
_oenv_path = omc_FGraph_getScopePath(threadData, _env);
if(isSome(_oenv_path))
{
tmpMeta6 = _oenv_path;
if (optionNone(tmpMeta6)) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
_env_path = tmpMeta7;
_tp_name = omc_AbsynUtil_pathLastIdent(threadData, _p);
_tp_path = omc_AbsynUtil_suffixPath(threadData, _env_path, _tp_name);
}
else
{
_tp_path = _p;
}
tmpMeta1 = _tp_path;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
_pkg_path = omc_AbsynUtil_pathFirstPath(threadData, _p);
omc_Lookup_lookupClass(threadData, omc_FCore_emptyCache(threadData), _inEnv, _pkg_path, mmc_mk_none() ,NULL ,&_env);
_oenv_path = omc_FGraph_getScopePath(threadData, _env);
if(isSome(_oenv_path))
{
tmpMeta8 = _oenv_path;
if (optionNone(tmpMeta8)) goto goto_2;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
_env_path = tmpMeta9;
_tp_path = omc_AbsynUtil_joinPaths(threadData, _env_path, _p);
}
else
{
_tp_path = _p;
}
tmpMeta1 = _tp_path;
goto tmp3_done;
}
case 2: {
tmpMeta1 = _p;
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
_fqp = tmpMeta1;
_return: OMC_LABEL_UNUSED
threadData->mmc_jumper = old_mmc_jumper;
return _fqp;
}
DLLExport
modelica_string omc_InteractiveUtil_getConstrainClassStr(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _occ)
{
modelica_string _s = NULL;
modelica_metatype _p = NULL;
modelica_metatype _qpath = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _occ;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_p = tmpMeta8;
tmp1 = omc_AbsynUtil_pathString(threadData, omc_InteractiveUtil_qualifyPath(threadData, _inEnv, _p), _OMC_LIT5, 1, 0);
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT56;
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
_s = tmp1;
_return: OMC_LABEL_UNUSED
return _s;
}
DLLExport
modelica_metatype omc_InteractiveUtil_qualifyPath(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inPath)
{
modelica_metatype _outPath = NULL;
modelica_string _n = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPath;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta1 = _inPath;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (4 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT61), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
tmpMeta1 = _inPath;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (7 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT62), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmpMeta1 = _inPath;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (7 != MMC_STRLEN(tmpMeta8) || strcmp(MMC_STRINGDATA(_OMC_LIT63), MMC_STRINGDATA(tmpMeta8)) != 0) goto tmp3_end;
tmpMeta1 = _inPath;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (6 != MMC_STRLEN(tmpMeta9) || strcmp(MMC_STRINGDATA(_OMC_LIT64), MMC_STRINGDATA(tmpMeta9)) != 0) goto tmp3_end;
tmpMeta1 = _inPath;
goto tmp3_done;
}
case 5: {
{
{
volatile mmc_switch_type tmp12;
int tmp13;
tmp12 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp11_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp12 < 2; tmp12++) {
switch (MMC_SWITCH_CAST(tmp12)) {
case 0: {
if(omc_Flags_isSet(threadData, _OMC_LIT60))
{
omc_Interactive_mkFullyQual(threadData, _inEnv, _inPath ,&_outPath);
}
else
{
_outPath = omc_InteractiveUtil_qualifyType(threadData, omc_Interactive_envFromGraphicEnvCache(threadData, _inEnv), _inPath);
}
goto tmp11_done;
}
case 1: {
_outPath = _inPath;
goto tmp11_done;
}
}
goto tmp11_end;
tmp11_end: ;
}
goto goto_10;
tmp11_done:
(void)tmp12;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp11_done2;
goto_10:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp12 < 2) {
goto tmp11_top;
}
goto goto_2;
tmp11_done2:;
}
}
;
tmpMeta1 = _outPath;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementInfo(threadData_t *threadData, modelica_metatype _inElement, modelica_boolean _inQuoteNames, modelica_string _inVisibility, modelica_metatype _inEnv)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_metatype _attr = NULL;
modelica_metatype _p = NULL;
modelica_metatype _comps = NULL;
modelica_metatype _names = NULL;
modelica_metatype _dims = NULL;
modelica_string _typename = NULL;
modelica_string _final_str = NULL;
modelica_string _repl_str = NULL;
modelica_string _io_str = NULL;
modelica_string _flow_str = NULL;
modelica_string _stream_str = NULL;
modelica_string _var_str = NULL;
modelica_string _dir_str = NULL;
modelica_string _dim_str = NULL;
modelica_string _str = NULL;
modelica_string _cc_str = NULL;
modelica_string _name = NULL;
modelica_string _cmt_str = NULL;
modelica_metatype _ocmt = NULL;
modelica_metatype _oadim = NULL;
modelica_metatype _ad = NULL;
modelica_metatype _occ = NULL;
modelica_metatype _restriction = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_attr = tmpMeta7;
_p = tmpMeta9;
_comps = tmpMeta10;
_occ = tmpMeta11;
_typename = omc_AbsynUtil_pathString(threadData, omc_InteractiveUtil_qualifyPath(threadData, _inEnv, _p), _OMC_LIT5, 1, 0);
_names = omc_InteractiveUtil_getComponentItemsNameAndComment(threadData, _comps, _inQuoteNames);
_dims = omc_InteractiveUtil_getComponentitemsDimension(threadData, _comps);
_final_str = (mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement), 2))))?_OMC_LIT48:_OMC_LIT49);
_repl_str = (omc_InteractiveUtil_keywordReplaceable(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement), 3))))?_OMC_LIT48:_OMC_LIT49);
_io_str = omc_InteractiveUtil_innerOuterStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement), 4))));
_flow_str = omc_InteractiveUtil_attrFlowStr(threadData, _attr);
_stream_str = omc_InteractiveUtil_attrStreamStr(threadData, _attr);
_var_str = omc_InteractiveUtil_attrVariabilityStr(threadData, _attr);
_dir_str = omc_InteractiveUtil_attrDirectionStr(threadData, _attr);
_dim_str = omc_InteractiveUtil_attrDimensionStr(threadData, _attr);
_cc_str = omc_InteractiveUtil_getConstrainClassStr(threadData, _inEnv, _occ);
if(_inQuoteNames)
{
_typename = omc_StringUtil_quote(threadData, _typename);
_final_str = omc_StringUtil_quote(threadData, _final_str);
_repl_str = omc_StringUtil_quote(threadData, _repl_str);
_flow_str = omc_StringUtil_quote(threadData, _flow_str);
_stream_str = omc_StringUtil_quote(threadData, _stream_str);
_cc_str = omc_StringUtil_quote(threadData, _cc_str);
}
_names = omc_InteractiveUtil_prefixTypename(threadData, _typename, _names);
_names = omc_InteractiveUtil_prefixTypename(threadData, _OMC_LIT65, _names);
_names = omc_InteractiveUtil_prefixTypename(threadData, _OMC_LIT66, _names);
tmpMeta12 = mmc_mk_cons(_inVisibility, mmc_mk_cons(_final_str, mmc_mk_cons(_flow_str, mmc_mk_cons(_stream_str, mmc_mk_cons(_repl_str, mmc_mk_cons(_var_str, mmc_mk_cons(_io_str, mmc_mk_cons(_dir_str, mmc_mk_cons(_cc_str, MMC_REFSTRUCTLIT(mmc_nil))))))))));
_str = stringDelimitList(tmpMeta12, _OMC_LIT35);
tmpMeta1 = omc_InteractiveUtil_suffixInfos(threadData, _names, _dims, _dim_str, _str, _inQuoteNames);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
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
modelica_metatype tmpMeta26;
modelica_boolean tmp27;
modelica_string tmp28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 6));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,1,4) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,0,2) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 3));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 5));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_name = tmpMeta15;
_restriction = tmpMeta16;
_p = tmpMeta19;
_oadim = tmpMeta20;
_attr = tmpMeta21;
_ocmt = tmpMeta22;
_occ = tmpMeta23;
_typename = omc_AbsynUtil_pathString(threadData, omc_InteractiveUtil_qualifyPath(threadData, _inEnv, _p), _OMC_LIT5, 1, 0);
_cmt_str = omc_InteractiveUtil_getClassCommentInCommentOpt(threadData, _ocmt);
tmp27 = (modelica_boolean)_inQuoteNames;
if(tmp27)
{
tmpMeta25 = mmc_mk_cons(_OMC_LIT32, mmc_mk_cons(_name, mmc_mk_cons(_OMC_LIT33, mmc_mk_cons(_cmt_str, mmc_mk_cons(_OMC_LIT32, MMC_REFSTRUCTLIT(mmc_nil))))));
tmp28 = stringAppendList(tmpMeta25);
}
else
{
tmpMeta26 = mmc_mk_cons(_name, mmc_mk_cons(_OMC_LIT34, mmc_mk_cons(_cmt_str, mmc_mk_cons(_OMC_LIT32, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp28 = stringAppendList(tmpMeta26);
}
tmpMeta24 = mmc_mk_cons(tmp28, MMC_REFSTRUCTLIT(mmc_nil));
_names = tmpMeta24;
{
modelica_metatype tmp32_1;
tmp32_1 = _oadim;
{
volatile mmc_switch_type tmp32;
int tmp33;
tmp32 = 0;
for (; tmp32 < 2; tmp32++) {
switch (MMC_SWITCH_CAST(tmp32)) {
case 0: {
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
if (optionNone(tmp32_1)) goto tmp31_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp32_1), 1));
_ad = tmpMeta34;
tmpMeta35 = mmc_mk_cons(stringDelimitList(omc_List_map(threadData, _ad, boxvar_Dump_printSubscriptStr), _OMC_LIT15), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta29 = tmpMeta35;
goto tmp31_done;
}
case 1: {
tmpMeta29 = _OMC_LIT67;
goto tmp31_done;
}
}
goto tmp31_end;
tmp31_end: ;
}
goto goto_30;
goto_30:;
goto goto_2;
goto tmp31_done;
tmp31_done:;
}
}
_dims = tmpMeta29;
_final_str = (mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement), 2))))?_OMC_LIT48:_OMC_LIT49);
_repl_str = (omc_InteractiveUtil_keywordReplaceable(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement), 3))))?_OMC_LIT48:_OMC_LIT49);
_io_str = omc_InteractiveUtil_innerOuterStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement), 4))));
_flow_str = omc_InteractiveUtil_attrFlowStr(threadData, _attr);
_stream_str = omc_InteractiveUtil_attrStreamStr(threadData, _attr);
_var_str = omc_InteractiveUtil_attrVariabilityStr(threadData, _attr);
_dir_str = omc_InteractiveUtil_attrDirectionStr(threadData, _attr);
_dim_str = omc_InteractiveUtil_attrDimensionStr(threadData, _attr);
_cc_str = omc_InteractiveUtil_getConstrainClassStr(threadData, _inEnv, _occ);
if(_inQuoteNames)
{
_typename = omc_StringUtil_quote(threadData, _typename);
_final_str = omc_StringUtil_quote(threadData, _final_str);
_repl_str = omc_StringUtil_quote(threadData, _repl_str);
_flow_str = omc_StringUtil_quote(threadData, _flow_str);
_stream_str = omc_StringUtil_quote(threadData, _stream_str);
_cc_str = omc_StringUtil_quote(threadData, _cc_str);
}
_names = omc_InteractiveUtil_prefixTypename(threadData, _typename, _names);
tmpMeta36 = stringAppend(_OMC_LIT32,omc_Dump_unparseRestrictionStr(threadData, _restriction));
tmpMeta37 = stringAppend(tmpMeta36,_OMC_LIT32);
_names = omc_InteractiveUtil_prefixTypename(threadData, tmpMeta37, _names);
_names = omc_InteractiveUtil_prefixTypename(threadData, _OMC_LIT68, _names);
tmpMeta38 = mmc_mk_cons(_inVisibility, mmc_mk_cons(_final_str, mmc_mk_cons(_flow_str, mmc_mk_cons(_stream_str, mmc_mk_cons(_repl_str, mmc_mk_cons(_var_str, mmc_mk_cons(_io_str, mmc_mk_cons(_dir_str, mmc_mk_cons(_cc_str, MMC_REFSTRUCTLIT(mmc_nil))))))))));
_str = stringDelimitList(tmpMeta38, _OMC_LIT35);
tmpMeta1 = omc_InteractiveUtil_suffixInfos(threadData, _names, _dims, _dim_str, _str, _inQuoteNames);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta39;
tmpMeta39 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta39;
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
_outStringLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStringLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getElementInfo(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inQuoteNames, modelica_metatype _inVisibility, modelica_metatype _inEnv)
{
modelica_integer tmp1;
modelica_metatype _outStringLst = NULL;
tmp1 = mmc_unbox_integer(_inQuoteNames);
_outStringLst = omc_InteractiveUtil_getElementInfo(threadData, _inElement, tmp1, _inVisibility, _inEnv);
return _outStringLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementsInElementitems(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst)
{
modelica_metatype _outAbsynElementLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outAbsynElementLst = tmpMeta1;
{
modelica_metatype _el;
for (tmpMeta2 = _inAbsynElementItemLst; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_el = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp5_1;
tmp5_1 = _el;
{
modelica_metatype _elt = NULL;
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 2; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,0,1) == 0) goto tmp4_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
_elt = tmpMeta7;
tmpMeta8 = mmc_mk_cons(_elt, _outAbsynElementLst);
_outAbsynElementLst = tmpMeta8;
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
_outAbsynElementLst = listReverseInPlace(_outAbsynElementLst);
_return: OMC_LABEL_UNUSED
return _outAbsynElementLst;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getProtectedElementsInClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _outAbsynElementLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_metatype _lst1 = NULL;
modelica_metatype _res = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _lst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta18;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,5) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
_lst = tmpMeta10;
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
_res = tmpMeta11;
{
modelica_metatype _elt;
for (tmpMeta12 = _lst; !listEmpty(tmpMeta12); tmpMeta12=MMC_CDR(tmpMeta12))
{
_elt = MMC_CAR(tmpMeta12);
{
modelica_metatype tmp15_1;
tmp15_1 = _elt;
{
volatile mmc_switch_type tmp15;
int tmp16;
tmp15 = 0;
for (; tmp15 < 2; tmp15++) {
switch (MMC_SWITCH_CAST(tmp15)) {
case 0: {
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp15_1,1,1) == 0) goto tmp14_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp15_1), 2));
_elts = tmpMeta17;
_lst1 = omc_InteractiveUtil_getElementsInElementitems(threadData, _elts);
_res = omc_List_append__reverse(threadData, _lst1, _res);
goto tmp14_done;
}
case 1: {
goto tmp14_done;
}
}
goto tmp14_end;
tmp14_end: ;
}
goto goto_13;
goto_13:;
goto goto_2;
goto tmp14_done;
tmp14_done:;
}
}
;
}
}
tmpMeta1 = listReverseInPlace(_res);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,4,5) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 5));
if (!listEmpty(tmpMeta20)) goto tmp3_end;
tmpMeta21 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta31;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,4,5) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 5));
_lst = tmpMeta23;
tmpMeta24 = MMC_REFSTRUCTLIT(mmc_nil);
_res = tmpMeta24;
{
modelica_metatype _elt;
for (tmpMeta25 = _lst; !listEmpty(tmpMeta25); tmpMeta25=MMC_CDR(tmpMeta25))
{
_elt = MMC_CAR(tmpMeta25);
{
modelica_metatype tmp28_1;
tmp28_1 = _elt;
{
volatile mmc_switch_type tmp28;
int tmp29;
tmp28 = 0;
for (; tmp28 < 2; tmp28++) {
switch (MMC_SWITCH_CAST(tmp28)) {
case 0: {
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp28_1,1,1) == 0) goto tmp27_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp28_1), 2));
_elts = tmpMeta30;
_lst1 = omc_InteractiveUtil_getElementsInElementitems(threadData, _elts);
_res = omc_List_append__reverse(threadData, _lst1, _res);
goto tmp27_done;
}
case 1: {
goto tmp27_done;
}
}
goto tmp27_end;
tmp27_end: ;
}
goto goto_26;
goto_26:;
goto goto_2;
goto tmp27_done;
tmp27_done:;
}
}
;
}
}
tmpMeta1 = listReverseInPlace(_res);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta32;
tmpMeta32 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta32;
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
_outAbsynElementLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynElementLst;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getPublicElementsInClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _outAbsynElementLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_metatype _lst1 = NULL;
modelica_metatype _res = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _lst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta18;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,5) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
_lst = tmpMeta10;
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
_res = tmpMeta11;
{
modelica_metatype _elt;
for (tmpMeta12 = _lst; !listEmpty(tmpMeta12); tmpMeta12=MMC_CDR(tmpMeta12))
{
_elt = MMC_CAR(tmpMeta12);
{
modelica_metatype tmp15_1;
tmp15_1 = _elt;
{
volatile mmc_switch_type tmp15;
int tmp16;
tmp15 = 0;
for (; tmp15 < 2; tmp15++) {
switch (MMC_SWITCH_CAST(tmp15)) {
case 0: {
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp15_1,0,1) == 0) goto tmp14_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp15_1), 2));
_elts = tmpMeta17;
_lst1 = omc_InteractiveUtil_getElementsInElementitems(threadData, _elts);
_res = omc_List_append__reverse(threadData, _lst1, _res);
goto tmp14_done;
}
case 1: {
goto tmp14_done;
}
}
goto tmp14_end;
tmp14_end: ;
}
goto goto_13;
goto_13:;
goto goto_2;
goto tmp14_done;
tmp14_done:;
}
}
;
}
}
tmpMeta1 = listReverseInPlace(_res);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,4,5) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 5));
if (!listEmpty(tmpMeta20)) goto tmp3_end;
tmpMeta21 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta31;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,4,5) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 5));
_lst = tmpMeta23;
tmpMeta24 = MMC_REFSTRUCTLIT(mmc_nil);
_res = tmpMeta24;
{
modelica_metatype _elt;
for (tmpMeta25 = _lst; !listEmpty(tmpMeta25); tmpMeta25=MMC_CDR(tmpMeta25))
{
_elt = MMC_CAR(tmpMeta25);
{
modelica_metatype tmp28_1;
tmp28_1 = _elt;
{
volatile mmc_switch_type tmp28;
int tmp29;
tmp28 = 0;
for (; tmp28 < 2; tmp28++) {
switch (MMC_SWITCH_CAST(tmp28)) {
case 0: {
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp28_1,0,1) == 0) goto tmp27_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp28_1), 2));
_elts = tmpMeta30;
_lst1 = omc_InteractiveUtil_getElementsInElementitems(threadData, _elts);
_res = omc_List_append__reverse(threadData, _lst1, _res);
goto tmp27_done;
}
case 1: {
goto tmp27_done;
}
}
goto tmp27_end;
tmp27_end: ;
}
goto goto_26;
goto_26:;
goto goto_2;
goto tmp27_done;
tmp27_done:;
}
}
;
}
}
tmpMeta1 = listReverseInPlace(_res);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta32;
tmpMeta32 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta32;
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
_outAbsynElementLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynElementLst;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getElementsInClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _outAbsynElementLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_metatype _lst1 = NULL;
modelica_metatype _res = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _lst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta18;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,5) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
_lst = tmpMeta10;
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
_res = tmpMeta11;
{
modelica_metatype _elt;
for (tmpMeta12 = _lst; !listEmpty(tmpMeta12); tmpMeta12=MMC_CDR(tmpMeta12))
{
_elt = MMC_CAR(tmpMeta12);
{
modelica_metatype tmp15_1;
tmp15_1 = _elt;
{
int tmp15;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp15_1))) {
case 3: {
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp15_1,0,1) == 0) goto tmp14_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp15_1), 2));
_elts = tmpMeta16;
_lst1 = omc_InteractiveUtil_getElementsInElementitems(threadData, _elts);
_res = omc_List_append__reverse(threadData, _lst1, _res);
goto tmp14_done;
}
case 4: {
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp15_1,1,1) == 0) goto tmp14_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp15_1), 2));
_elts = tmpMeta17;
_lst1 = omc_InteractiveUtil_getElementsInElementitems(threadData, _elts);
_res = omc_List_append__reverse(threadData, _lst1, _res);
goto tmp14_done;
}
default:
tmp14_default: OMC_LABEL_UNUSED; {
goto tmp14_done;
}
}
goto tmp14_end;
tmp14_end: ;
}
goto goto_13;
goto_13:;
goto goto_2;
goto tmp14_done;
tmp14_done:;
}
}
;
}
}
tmpMeta1 = listReverseInPlace(_res);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,4,5) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 5));
if (!listEmpty(tmpMeta20)) goto tmp3_end;
tmpMeta21 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta31;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,4,5) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 5));
_lst = tmpMeta23;
tmpMeta24 = MMC_REFSTRUCTLIT(mmc_nil);
_res = tmpMeta24;
{
modelica_metatype _elt;
for (tmpMeta25 = _lst; !listEmpty(tmpMeta25); tmpMeta25=MMC_CDR(tmpMeta25))
{
_elt = MMC_CAR(tmpMeta25);
{
modelica_metatype tmp28_1;
tmp28_1 = _elt;
{
int tmp28;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp28_1))) {
case 3: {
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp28_1,0,1) == 0) goto tmp27_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp28_1), 2));
_elts = tmpMeta29;
_lst1 = omc_InteractiveUtil_getElementsInElementitems(threadData, _elts);
_res = omc_List_append__reverse(threadData, _lst1, _res);
goto tmp27_done;
}
case 4: {
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp28_1,1,1) == 0) goto tmp27_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp28_1), 2));
_elts = tmpMeta30;
_lst1 = omc_InteractiveUtil_getElementsInElementitems(threadData, _elts);
_res = omc_List_append__reverse(threadData, _lst1, _res);
goto tmp27_done;
}
default:
tmp27_default: OMC_LABEL_UNUSED; {
goto tmp27_done;
}
}
goto tmp27_end;
tmp27_end: ;
}
goto goto_26;
goto_26:;
goto goto_2;
goto tmp27_done;
tmp27_done:;
}
}
;
}
}
tmpMeta1 = listReverseInPlace(_res);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta32;
tmpMeta32 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta32;
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
_outAbsynElementLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynElementLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_buildEnvForGraphicProgramFull(threadData_t *threadData, modelica_metatype _inProgram, modelica_metatype _inModelPath, modelica_metatype *out_outEnv, modelica_metatype *out_outProgram)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outProgram = NULL;
modelica_boolean _check_model;
modelica_boolean _eval_param;
modelica_boolean _failed;
modelica_boolean _graphics_mode;
modelica_metatype _graphic_program = NULL;
modelica_metatype _scode_program = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_failed = 0;
_graphic_program = omc_InteractiveUtil_modelicaAnnotationProgram(threadData, omc_Config_getAnnotationVersion(threadData));
_outProgram = omc_InteractiveUtil_updateProgram(threadData, _graphic_program, _inProgram, 0);
_scode_program = omc_AbsynToSCode_translateAbsyn2SCode(threadData, _outProgram);
_check_model = omc_Flags_getConfigBool(threadData, _OMC_LIT74);
_eval_param = omc_Config_getEvaluateParametersInAnnotations(threadData);
_graphics_mode = omc_Config_getGraphicsExpMode(threadData);
omc_FlagsUtil_setConfigBool(threadData, _OMC_LIT74, 1);
omc_Config_setEvaluateParametersInAnnotations(threadData, 1);
omc_Config_setGraphicsExpMode(threadData, 1);
{
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
_outCache = omc_Inst_instantiateClass(threadData, omc_FCore_emptyCache(threadData), tmpMeta5, _scode_program, _inModelPath, 1, 1 ,&_outEnv, NULL, NULL);
goto tmp2_done;
}
case 1: {
_failed = 1;
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
omc_Config_setEvaluateParametersInAnnotations(threadData, _eval_param);
omc_FlagsUtil_setConfigBool(threadData, _OMC_LIT74, _check_model);
omc_Config_setGraphicsExpMode(threadData, _graphics_mode);
if(_failed)
{
MMC_THROW_INTERNAL();
}
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outProgram) { *out_outProgram = _outProgram; }
return _outCache;
}
DLLExport
modelica_metatype omc_InteractiveUtil_buildEnvForGraphicProgram(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inAnnotationMod, modelica_metatype *out_outEnv, modelica_metatype *out_outGraphicProgram, modelica_metatype *out_outGraphicEnvCache)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outGraphicProgram = NULL;
modelica_metatype _outGraphicEnvCache = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCache;
{
modelica_metatype _scode_program = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmpMeta[0+0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 4)));
tmpMeta[0+1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 5)));
tmpMeta[0+2] = _OMC_LIT75;
tmpMeta[0+3] = _inCache;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta5;
if(omc_AbsynUtil_onlyLiteralsInAnnotationMod(threadData, _inAnnotationMod))
{
_outCache = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 4)));
_outEnv = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 5)));
_outGraphicEnvCache = _inCache;
_outGraphicProgram = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 2)));
}
else
{
_outCache = omc_InteractiveUtil_buildEnvForGraphicProgramFull(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 3))) ,&_outEnv ,&_outGraphicProgram);
tmpMeta5 = mmc_mk_box5(5, &Interactive_GraphicEnvCache_GRAPHIC__ENV__FULL__CACHE__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 3))), _outCache, _outEnv);
_outGraphicEnvCache = tmpMeta5;
}
tmpMeta[0+0] = _outCache;
tmpMeta[0+1] = _outEnv;
tmpMeta[0+2] = _outGraphicProgram;
tmpMeta[0+3] = _outGraphicEnvCache;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if(omc_AbsynUtil_onlyLiteralsInAnnotationMod(threadData, _inAnnotationMod))
{
_outGraphicProgram = omc_InteractiveUtil_modelicaAnnotationProgram(threadData, omc_Config_getAnnotationVersion(threadData));
_scode_program = omc_AbsynToSCode_translateAbsyn2SCode(threadData, _outGraphicProgram);
_outCache = omc_Inst_makeEnvFromProgram(threadData, _scode_program ,&_outEnv);
tmpMeta6 = mmc_mk_box5(4, &Interactive_GraphicEnvCache_GRAPHIC__ENV__PARTIAL__CACHE__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 3))), _outCache, _outEnv);
_outGraphicEnvCache = tmpMeta6;
}
else
{
_outCache = omc_InteractiveUtil_buildEnvForGraphicProgramFull(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 3))) ,&_outEnv ,&_outGraphicProgram);
tmpMeta7 = mmc_mk_box5(5, &Interactive_GraphicEnvCache_GRAPHIC__ENV__FULL__CACHE__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCache), 3))), _outCache, _outEnv);
_outGraphicEnvCache = tmpMeta7;
}
tmpMeta[0+0] = _outCache;
tmpMeta[0+1] = _outEnv;
tmpMeta[0+2] = _outGraphicProgram;
tmpMeta[0+3] = _outGraphicEnvCache;
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outGraphicProgram = tmpMeta[0+2];
_outGraphicEnvCache = tmpMeta[0+3];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outGraphicProgram) { *out_outGraphicProgram = _outGraphicProgram; }
if (out_outGraphicEnvCache) { *out_outGraphicEnvCache = _outGraphicEnvCache; }
return _outCache;
}
DLLExport
modelica_metatype omc_InteractiveUtil_modelicaAnnotationProgram(threadData_t *threadData, modelica_string _annotationVersion)
{
modelica_metatype _annotationProgram = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp4_1;
tmp4_1 = _annotationVersion;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT80), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmpMeta1 = omc_Parser_parsestring(threadData, _OMC_LIT76, _OMC_LIT77, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT124), omc_Flags_getConfigBool(threadData, _OMC_LIT128));
goto tmp3_done;
}
case 1: {
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT82), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmpMeta1 = omc_Parser_parsestring(threadData, _OMC_LIT129, _OMC_LIT130, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT124), omc_Flags_getConfigBool(threadData, _OMC_LIT128));
goto tmp3_done;
}
case 2: {
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT133), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
tmpMeta1 = omc_Parser_parsestring(threadData, _OMC_LIT131, _OMC_LIT132, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT124), omc_Flags_getConfigBool(threadData, _OMC_LIT128));
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
_annotationProgram = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _annotationProgram;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementitemsAnnotationsFromItems(threadData_t *threadData, modelica_metatype _inComponentItems, modelica_metatype _ccAnnotations, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype _inCache, modelica_metatype *out_outCache)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _outCache = NULL;
modelica_metatype _annotations = NULL;
modelica_metatype _res = NULL;
modelica_string _str = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outStringLst = tmpMeta1;
_outCache = _inCache;
{
modelica_metatype _comp;
for (tmpMeta2 = listReverse(_inComponentItems); !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_comp = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp6_1;
tmp6_1 = _comp;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 4));
if (optionNone(tmpMeta8)) goto tmp5_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (optionNone(tmpMeta10)) goto tmp5_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_annotations = tmpMeta12;
tmpMeta3 = listAppend(_annotations, _ccAnnotations);
goto tmp5_done;
}
case 1: {
tmpMeta3 = _ccAnnotations;
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
_annotations = tmpMeta3;
_res = omc_InteractiveUtil_getElementitemsAnnotationsElArgs(threadData, _annotations, _inEnv, _inClass, _outCache, 1 ,&_outCache);
_str = stringDelimitList(_res, _OMC_LIT35);
tmpMeta14 = mmc_mk_cons(_OMC_LIT55, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT39, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta13 = mmc_mk_cons(stringAppendList(tmpMeta14), _outStringLst);
_outStringLst = tmpMeta13;
}
}
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _outStringLst;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getElementitemsAnnotationsElArgs(threadData_t *threadData, modelica_metatype _inElementArgs, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype _inCache, modelica_boolean _addAnnotationName, modelica_metatype *out_outCache)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _outCache = NULL;
modelica_string _str = NULL;
modelica_string _ann_name = NULL;
modelica_metatype _eq_aexp = NULL;
modelica_metatype _graphic_exp = NULL;
modelica_metatype _eq_dexp = NULL;
modelica_metatype _graphic_dexp = NULL;
modelica_metatype _prop = NULL;
modelica_metatype _info = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _env2 = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _stripped_mod = NULL;
modelica_metatype _graphic_mod = NULL;
modelica_metatype _c = NULL;
modelica_metatype _smod = NULL;
modelica_metatype _dmod = NULL;
modelica_metatype _dae = NULL;
modelica_boolean _is_icon;
modelica_boolean _is_diagram;
modelica_metatype _graphic_prog = NULL;
modelica_metatype _placement_cls = NULL;
modelica_metatype tmpMeta2;
modelica_string tmp3 = 0;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outStringLst = tmpMeta1;
_outCache = _inCache;
{
modelica_metatype _e;
for (tmpMeta2 = listReverse(_inElementArgs); !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_e = MMC_CAR(tmpMeta2);
_e = omc_AbsynUtil_createChoiceArray(threadData, _e);
{
volatile modelica_metatype tmp6_1;
tmp6_1 = _e;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp5_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp6 < 4; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,6) == 0) goto tmp5_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp5_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 5));
if (optionNone(tmpMeta10)) goto tmp5_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (!listEmpty(tmpMeta12)) goto tmp5_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,1,2) == 0) goto tmp5_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 7));
_ann_name = tmpMeta9;
_eq_aexp = tmpMeta14;
_info = tmpMeta15;
tmp6 += 2;
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InteractiveUtil_buildEnvForGraphicProgram(threadData, _outCache, tmpMeta16 ,&_env ,NULL ,&_outCache);
omc_StaticScript_elabGraphicsExp(threadData, _cache, _env, _eq_aexp, 0, _OMC_LIT134, _info ,&_eq_dexp ,&_prop);
_cache = omc_Ceval_cevalIfConstant(threadData, _cache, _env, _eq_dexp, _prop, 0, _info ,&_eq_dexp ,&_prop);
_eq_dexp = omc_ExpressionSimplify_simplify1(threadData, _eq_dexp, NULL);
omc_Print_clearErrorBuf(threadData);
_str = omc_ExpressionDump_printExpStr(threadData, _eq_dexp);
tmpMeta17 = mmc_mk_cons(_ann_name, mmc_mk_cons(_OMC_LIT135, mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil))));
tmp3 = stringAppendList(tmpMeta17);
goto tmp5_done;
}
case 1: {
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
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta53;
modelica_boolean tmp54;
modelica_string tmp55;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,6) == 0) goto tmp5_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,1,1) == 0) goto tmp5_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 5));
if (optionNone(tmpMeta20)) goto tmp5_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 1));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,0,0) == 0) goto tmp5_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 7));
_ann_name = tmpMeta19;
_mod = tmpMeta22;
_info = tmpMeta24;
tmp6 += 1;
if((!listMember(_ann_name, _OMC_LIT152)))
{
_cache = omc_InteractiveUtil_buildEnvForGraphicProgram(threadData, _outCache, _mod ,&_env ,NULL ,&_outCache);
_cache = omc_Lookup_lookupClassIdent(threadData, _cache, _inEnv, _ann_name, mmc_mk_none() ,&_c ,&_env2);
tmpMeta25 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _mod, _OMC_LIT17);
_smod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta25), _OMC_LIT140, _OMC_LIT141, _info);
tmpMeta26 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta27 = mmc_mk_box2(3, &Mod_ModScope_COMPONENT__desc, _ann_name);
_cache = omc_Mod_elabMod(threadData, _cache, _env, tmpMeta26, _OMC_LIT134, _smod, 0, tmpMeta27, _OMC_LIT19 ,&_dmod);
_c = omc_SCodeUtil_classSetPartial(threadData, _c, _OMC_LIT149);
tmpMeta28 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta29 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Inst_instClass(threadData, _cache, _env2, tmpMeta28, _OMC_LIT142, _dmod, _OMC_LIT134, _c, tmpMeta29, 0, _OMC_LIT143, _OMC_LIT144, _OMC_LIT147 ,NULL ,NULL ,NULL ,&_dae, NULL, NULL, NULL, NULL, NULL);
_str = omc_DAEUtil_getVariableBindingsStr(threadData, omc_DAEUtil_daeElements(threadData, _dae));
}
else
{
_is_icon = (stringEqual(_ann_name, _OMC_LIT136));
_is_diagram = ((stringEqual(_ann_name, _OMC_LIT137)) || (stringEqual(_ann_name, _OMC_LIT138)));
_stripped_mod = omc_AbsynUtil_stripGraphicsAndInteractionModification(threadData, _mod ,&_graphic_mod);
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT139);
{
{
volatile mmc_switch_type tmp32;
int tmp33;
tmp32 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp31_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp32 < 2; tmp32++) {
switch (MMC_SWITCH_CAST(tmp32)) {
case 0: {
_cache = omc_InteractiveUtil_buildEnvForGraphicProgram(threadData, _inCache, _mod ,&_env ,&_graphic_prog ,NULL);
omc_ErrorExt_rollBack(threadData, _OMC_LIT139);
goto tmp31_done;
}
case 1: {
modelica_metatype tmpMeta34;
omc_ErrorExt_delCheckpoint(threadData, _OMC_LIT139);
tmpMeta34 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InteractiveUtil_buildEnvForGraphicProgram(threadData, _inCache, tmpMeta34 ,&_env ,&_graphic_prog ,NULL);
goto tmp31_done;
}
}
goto tmp31_end;
tmp31_end: ;
}
goto goto_30;
tmp31_done:
(void)tmp32;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp31_done2;
goto_30:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp32 < 2) {
goto tmp31_top;
}
goto goto_4;
tmp31_done2:;
}
}
;
tmpMeta35 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _stripped_mod, _OMC_LIT17);
_smod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta35), _OMC_LIT140, _OMC_LIT141, _info);
tmpMeta36 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta37 = mmc_mk_box2(3, &Mod_ModScope_COMPONENT__desc, _ann_name);
_cache = omc_Mod_elabMod(threadData, _cache, _env, tmpMeta36, _OMC_LIT134, _smod, 0, tmpMeta37, _info ,&_dmod);
_placement_cls = omc_AbsynToSCode_translateClass(threadData, omc_InteractiveUtil_getClassInProgram(threadData, _ann_name, _graphic_prog));
tmpMeta38 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta39 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Inst_instClass(threadData, _cache, _env, tmpMeta38, _OMC_LIT142, _dmod, _OMC_LIT134, _placement_cls, tmpMeta39, 0, _OMC_LIT143, _OMC_LIT144, _OMC_LIT147 ,NULL ,NULL ,NULL ,&_dae, NULL, NULL, NULL, NULL, NULL);
_str = omc_DAEUtil_getVariableBindingsStr(threadData, omc_DAEUtil_daeElements(threadData, _dae));
if((_is_icon || _is_diagram))
{
{
{
volatile mmc_switch_type tmp42;
int tmp43;
tmp42 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp41_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp42 < 2; tmp42++) {
switch (MMC_SWITCH_CAST(tmp42)) {
case 0: {
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
tmpMeta44 = _graphic_mod;
if (listEmpty(tmpMeta44)) goto goto_40;
tmpMeta45 = MMC_CAR(tmpMeta44);
tmpMeta46 = MMC_CDR(tmpMeta44);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta45,0,6) == 0) goto goto_40;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 5));
if (optionNone(tmpMeta47)) goto goto_40;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta47), 1));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta48), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta49,1,2) == 0) goto goto_40;
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 2));
if (!listEmpty(tmpMeta46)) goto goto_40;
_graphic_exp = tmpMeta50;
omc_StaticScript_elabGraphicsExp(threadData, _cache, _env, _graphic_exp, 0, _OMC_LIT134, _info ,&_graphic_dexp ,&_prop);
if(_is_icon)
{
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT148);
_cache = omc_Ceval_cevalIfConstant(threadData, _cache, _env, _graphic_dexp, _prop, 0, _info ,&_graphic_dexp, NULL);
_graphic_dexp = omc_ExpressionSimplify_simplify1(threadData, _graphic_dexp, NULL);
omc_ErrorExt_rollBack(threadData, _OMC_LIT148);
}
tmpMeta51 = stringAppend(_str,_OMC_LIT15);
tmpMeta52 = stringAppend(tmpMeta51,omc_ExpressionDump_printExpStr(threadData, _graphic_dexp));
_str = tmpMeta52;
goto tmp41_done;
}
case 1: {
goto tmp41_done;
}
}
goto tmp41_end;
tmp41_end: ;
}
goto goto_40;
tmp41_done:
(void)tmp42;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp41_done2;
goto_40:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp42 < 2) {
goto tmp41_top;
}
goto goto_4;
tmp41_done2:;
}
}
;
}
omc_Print_clearErrorBuf(threadData);
}
tmp54 = (modelica_boolean)_addAnnotationName;
if(tmp54)
{
tmpMeta53 = mmc_mk_cons(_ann_name, mmc_mk_cons(_OMC_LIT153, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT154, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp55 = stringAppendList(tmpMeta53);
}
else
{
tmp55 = _str;
}
tmp3 = tmp55;
goto tmp5_done;
}
case 2: {
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_boolean tmp63;
modelica_string tmp64;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,6) == 0) goto tmp5_end;
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta56,1,1) == 0) goto tmp5_end;
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta56), 2));
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 5));
if (!optionNone(tmpMeta58)) goto tmp5_end;
_ann_name = tmpMeta57;
tmpMeta59 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_InteractiveUtil_buildEnvForGraphicProgram(threadData, _outCache, tmpMeta59 ,NULL ,NULL ,&_outCache);
_cache = omc_Lookup_lookupClassIdent(threadData, _cache, _inEnv, _ann_name, mmc_mk_none() ,&_c ,&_env);
_c = omc_SCodeUtil_classSetPartial(threadData, _c, _OMC_LIT149);
tmpMeta60 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta61 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Inst_instClass(threadData, _cache, _env, tmpMeta60, _OMC_LIT142, _OMC_LIT155, _OMC_LIT134, _c, tmpMeta61, 0, _OMC_LIT143, _OMC_LIT144, _OMC_LIT147 ,NULL ,NULL ,NULL ,&_dae, NULL, NULL, NULL, NULL, NULL);
_str = omc_DAEUtil_getVariableBindingsStr(threadData, omc_DAEUtil_daeElements(threadData, _dae));
tmp63 = (modelica_boolean)_addAnnotationName;
if(tmp63)
{
tmpMeta62 = mmc_mk_cons(_ann_name, mmc_mk_cons(_OMC_LIT153, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT154, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp64 = stringAppendList(tmpMeta62);
}
else
{
tmp64 = _str;
}
tmp3 = tmp64;
goto tmp5_done;
}
case 3: {
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,6) == 0) goto tmp5_end;
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta65,1,1) == 0) goto tmp5_end;
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 2));
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 7));
_ann_name = tmpMeta66;
_info = tmpMeta67;
tmpMeta68 = stringAppend(_OMC_LIT156,omc_Dump_unparseElementArgStr(threadData, _e));
tmpMeta69 = stringAppend(tmpMeta68,_OMC_LIT154);
_str = tmpMeta69;
_str = omc_Util_escapeQuotes(threadData, _str);
tmpMeta70 = mmc_mk_cons(_ann_name, mmc_mk_cons(_OMC_LIT157, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT158, MMC_REFSTRUCTLIT(mmc_nil)))));
tmp3 = stringAppendList(tmpMeta70);
goto tmp5_done;
}
}
goto tmp5_end;
tmp5_end: ;
}
goto goto_4;
tmp5_done:
(void)tmp6;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp5_done2;
goto_4:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp6 < 4) {
goto tmp5_top;
}
MMC_THROW_INTERNAL();
tmp5_done2:;
}
}
_str = tmp3;
tmpMeta71 = mmc_mk_cons(_str, _outStringLst);
_outStringLst = tmpMeta71;
}
}
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _outStringLst;
}
modelica_metatype boxptr_InteractiveUtil_getElementitemsAnnotationsElArgs(threadData_t *threadData, modelica_metatype _inElementArgs, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype _inCache, modelica_metatype _addAnnotationName, modelica_metatype *out_outCache)
{
modelica_integer tmp1;
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta2;
tmp1 = mmc_unbox_integer(_addAnnotationName);
_outStringLst = omc_InteractiveUtil_getElementitemsAnnotationsElArgs(threadData, _inElementArgs, _inEnv, _inClass, _inCache, tmp1, out_outCache);
return _outStringLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getAnnotationsFromConstraintClass(threadData_t *threadData, modelica_metatype _inCC)
{
modelica_metatype _outElArgLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCC;
{
modelica_metatype _elementArgs = NULL;
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
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (optionNone(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_elementArgs = tmpMeta11;
tmpMeta1 = _elementArgs;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta12;
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
_outElArgLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElArgLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementitemsAnnotationsFromElArgs(threadData_t *threadData, modelica_metatype _inAnnotations, modelica_metatype _ccAnnotations, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype _inCache, modelica_metatype *out_outCache)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _outCache = NULL;
modelica_metatype _annotations = NULL;
modelica_metatype _res = NULL;
modelica_string _str = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outStringLst = tmpMeta1;
_outCache = _inCache;
_annotations = listAppend(_inAnnotations, _ccAnnotations);
_res = omc_InteractiveUtil_getElementitemsAnnotationsElArgs(threadData, _annotations, _inEnv, _inClass, _outCache, 1 ,&_outCache);
_str = stringDelimitList(_res, _OMC_LIT35);
tmpMeta3 = mmc_mk_cons(_OMC_LIT55, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT39, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta2 = mmc_mk_cons(stringAppendList(tmpMeta3), _outStringLst);
_outStringLst = tmpMeta2;
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _outStringLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementitemsAnnotations(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype _inCache)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _res = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _items = NULL;
modelica_metatype _cc = NULL;
modelica_metatype _annotations = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _fullProgram = NULL;
modelica_metatype _modelPath = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta32;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outStringLst = tmpMeta1;
_cache = _inCache;
if(omc_Flags_isSet(threadData, _OMC_LIT60))
{
_fullProgram = omc_Interactive_cacheProgramAndPath(threadData, _inCache ,&_modelPath);
_outStringLst = omc_NFApi_evaluateAnnotations(threadData, _fullProgram, _modelPath, _inElements);
goto _return;
}
{
modelica_metatype _e;
for (tmpMeta2 = listReverse(_inElements); !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_e = MMC_CAR(tmpMeta2);
{
volatile modelica_metatype tmp6_1;
tmp6_1 = _e;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp5_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp6 < 5; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,6) == 0) goto tmp5_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,3) == 0) goto tmp5_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 7));
_items = tmpMeta9;
_cc = tmpMeta10;
tmp6 += 1;
_res = omc_InteractiveUtil_getElementitemsAnnotationsFromItems(threadData, _items, omc_InteractiveUtil_getAnnotationsFromConstraintClass(threadData, _cc), _inEnv, _inClass, _cache ,&_cache);
tmpMeta3 = listAppend(_res, _outStringLst);
goto tmp5_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,6) == 0) goto tmp5_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,2) == 0) goto tmp5_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,1,4) == 0) goto tmp5_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 5));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 7));
_cmt = tmpMeta14;
_cc = tmpMeta15;
tmp6 += 1;
{
modelica_metatype tmp19_1;
tmp19_1 = _cmt;
{
volatile mmc_switch_type tmp19;
int tmp20;
tmp19 = 0;
for (; tmp19 < 2; tmp19++) {
switch (MMC_SWITCH_CAST(tmp19)) {
case 0: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (optionNone(tmp19_1)) goto tmp18_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp19_1), 1));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
if (optionNone(tmpMeta22)) goto tmp18_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 1));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
_annotations = tmpMeta24;
tmpMeta16 = _annotations;
goto tmp18_done;
}
case 1: {
modelica_metatype tmpMeta25;
tmpMeta25 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta16 = tmpMeta25;
goto tmp18_done;
}
}
goto tmp18_end;
tmp18_end: ;
}
goto goto_17;
goto_17:;
goto goto_4;
goto tmp18_done;
tmp18_done:;
}
}
_annotations = tmpMeta16;
_res = omc_InteractiveUtil_getElementitemsAnnotationsFromElArgs(threadData, _annotations, omc_InteractiveUtil_getAnnotationsFromConstraintClass(threadData, _cc), _inEnv, _inClass, _cache ,&_cache);
tmpMeta3 = listAppend(_res, _outStringLst);
goto tmp5_done;
}
case 2: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,6) == 0) goto tmp5_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,3,3) == 0) goto tmp5_end;
tmp6 += 1;
tmpMeta27 = mmc_mk_cons(_OMC_LIT159, _outStringLst);
tmpMeta3 = tmpMeta27;
goto tmp5_done;
}
case 3: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,6) == 0) goto tmp5_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,0,2) == 0) goto tmp5_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 3));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta30,1,4) == 0) goto tmp5_end;
tmpMeta31 = mmc_mk_cons(_OMC_LIT159, _outStringLst);
tmpMeta3 = tmpMeta31;
goto tmp5_done;
}
case 4: {
tmpMeta3 = _outStringLst;
goto tmp5_done;
}
}
goto tmp5_end;
tmp5_end: ;
}
goto goto_4;
tmp5_done:
(void)tmp6;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp5_done2;
goto_4:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp6 < 5) {
goto tmp5_top;
}
MMC_THROW_INTERNAL();
tmp5_done2:;
}
}
_outStringLst = tmpMeta3;
}
}
_return: OMC_LABEL_UNUSED
threadData->mmc_jumper = old_mmc_jumper;
return _outStringLst;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getElementAnnotationsFromElts(threadData_t *threadData, modelica_metatype _els, modelica_metatype _inClass, modelica_metatype _inFullProgram, modelica_metatype _inModelPath)
{
modelica_string _resStr = NULL;
modelica_metatype _graphicProgramSCode = NULL;
modelica_metatype _env = NULL;
modelica_metatype _res = NULL;
modelica_metatype _placementProgram = NULL;
modelica_metatype _cache = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((!omc_Flags_isSet(threadData, _OMC_LIT60)))
{
_placementProgram = omc_InteractiveUtil_modelicaAnnotationProgram(threadData, omc_Config_getAnnotationVersion(threadData));
_graphicProgramSCode = omc_AbsynToSCode_translateAbsyn2SCode(threadData, _placementProgram);
omc_Inst_makeEnvFromProgram(threadData, _graphicProgramSCode ,&_env);
}
else
{
_env = _OMC_LIT161;
}
tmpMeta1 = mmc_mk_box3(3, &Interactive_GraphicEnvCache_GRAPHIC__ENV__NO__CACHE__desc, _inFullProgram, _inModelPath);
_cache = tmpMeta1;
_res = omc_InteractiveUtil_getElementitemsAnnotations(threadData, _els, _env, _inClass, _cache);
_resStr = stringDelimitList(_res, _OMC_LIT15);
_return: OMC_LABEL_UNUSED
return _resStr;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getClassnamesInElts(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_boolean _includeConstants)
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
omc_DoubleEnded_push__list__back(threadData, _delst, omc_InteractiveUtil_getComponentItemsName(threadData, _lst, 0));
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
modelica_metatype boxptr_InteractiveUtil_getClassnamesInElts(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _includeConstants)
{
modelica_integer tmp1;
modelica_metatype _outStringLst = NULL;
tmp1 = mmc_unbox_integer(_includeConstants);
_outStringLst = omc_InteractiveUtil_getClassnamesInElts(threadData, _inAbsynElementItemLst, tmp1);
return _outStringLst;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getClassnamesInParts(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_boolean _inShowProtected, modelica_boolean _includeConstants)
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
_l1 = omc_InteractiveUtil_getClassnamesInElts(threadData, _elts, _c);
_l2 = omc_InteractiveUtil_getClassnamesInParts(threadData, _rest, _b, _c);
tmpMeta1 = listAppend(_l1, _l2);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (1 != tmp4_2) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_elts = tmpMeta12;
_rest = tmpMeta11;
_c = tmp4_3;
_l1 = omc_InteractiveUtil_getClassnamesInElts(threadData, _elts, _c);
_l2 = omc_InteractiveUtil_getClassnamesInParts(threadData, _rest, 1, _c);
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
tmpMeta1 = omc_InteractiveUtil_getClassnamesInParts(threadData, _rest, _b, _c);
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
modelica_metatype boxptr_InteractiveUtil_getClassnamesInParts(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst, modelica_metatype _inShowProtected, modelica_metatype _includeConstants)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outStringLst = NULL;
tmp1 = mmc_unbox_integer(_inShowProtected);
tmp2 = mmc_unbox_integer(_includeConstants);
_outStringLst = omc_InteractiveUtil_getClassnamesInParts(threadData, _inAbsynClassPartLst, tmp1, tmp2);
return _outStringLst;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getClassnamesInClass(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_boolean _inShowProtected, modelica_boolean _includeConstants)
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
_strlist = omc_InteractiveUtil_getClassnamesInParts(threadData, _parts, _b, _c);
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
_strlist = omc_InteractiveUtil_getClassnamesInParts(threadData, _parts, _b, _c);
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
modelica_metatype boxptr_InteractiveUtil_getClassnamesInClass(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inProgram, modelica_metatype _inClass, modelica_metatype _inShowProtected, modelica_metatype _includeConstants)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _paths = NULL;
tmp1 = mmc_unbox_integer(_inShowProtected);
tmp2 = mmc_unbox_integer(_includeConstants);
_paths = omc_InteractiveUtil_getClassnamesInClass(threadData, _inPath, _inProgram, _inClass, tmp1, tmp2);
return _paths;
}
DLLExport
modelica_string omc_InteractiveUtil_getClassCommentInCommentOpt(threadData_t *threadData, modelica_metatype _inComment)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComment;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_outString = tmpMeta8;
tmp1 = _outString;
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT14;
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
modelica_string omc_InteractiveUtil_getElementAnnotations(threadData_t *threadData, modelica_metatype _inClassPath, modelica_metatype _inProgram, modelica_integer _inAccess)
{
modelica_string _outString = NULL;
modelica_metatype _model_path = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype _els1 = NULL;
modelica_metatype _els2 = NULL;
modelica_metatype _els = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
_model_path = omc_AbsynUtil_crefToPath(threadData, _inClassPath);
_cdef = omc_InteractiveUtil_getPathedClassInProgram(threadData, _model_path, _inProgram, 0, 0);
_els1 = omc_InteractiveUtil_getPublicElementsInClass(threadData, _cdef);
if((_inAccess >= ((modelica_integer) 4)))
{
_els2 = omc_InteractiveUtil_getProtectedElementsInClass(threadData, _cdef);
}
else
{
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
_els2 = tmpMeta5;
}
_els = listAppend(_els1, _els2);
_outString = omc_InteractiveUtil_getElementAnnotationsFromElts(threadData, _els, _cdef, _inProgram, _model_path);
tmpMeta6 = mmc_mk_cons(_OMC_LIT55, mmc_mk_cons(_outString, mmc_mk_cons(_OMC_LIT39, MMC_REFSTRUCTLIT(mmc_nil))));
_outString = stringAppendList(tmpMeta6);
goto tmp2_done;
}
case 1: {
_outString = _OMC_LIT162;
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
return _outString;
}
modelica_metatype boxptr_InteractiveUtil_getElementAnnotations(threadData_t *threadData, modelica_metatype _inClassPath, modelica_metatype _inProgram, modelica_metatype _inAccess)
{
modelica_integer tmp1;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_inAccess);
_outString = omc_InteractiveUtil_getElementAnnotations(threadData, _inClassPath, _inProgram, tmp1);
return _outString;
}
DLLExport
modelica_metatype omc_InteractiveUtil_createEnvironment(threadData_t *threadData, modelica_metatype _p, modelica_metatype _os, modelica_metatype _modelPath)
{
modelica_metatype _genv = NULL;
modelica_metatype _env = NULL;
modelica_metatype _env_1 = NULL;
modelica_metatype _env2 = NULL;
modelica_metatype _s = NULL;
modelica_metatype _c = NULL;
modelica_string _id = NULL;
modelica_metatype _encflag = NULL;
modelica_metatype _restr = NULL;
modelica_metatype _ci_state = NULL;
modelica_metatype _model_ = NULL;
modelica_metatype _cache = NULL;
modelica_boolean _b;
modelica_boolean _permissive;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta14;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_Flags_isSet(threadData, _OMC_LIT60))
{
tmpMeta1 = mmc_mk_box5(5, &Interactive_GraphicEnvCache_GRAPHIC__ENV__FULL__CACHE__desc, _p, _modelPath, omc_FCore_emptyCache(threadData), _OMC_LIT161);
_genv = tmpMeta1;
}
else
{
_s = omc_Util_getOptionOrDefault(threadData, _os, omc_AbsynToSCode_translateAbsyn2SCode(threadData, _p));
_cache = omc_Inst_makeEnvFromProgram(threadData, _s ,&_env);
tmpMeta7 = omc_Lookup_lookupClass(threadData, _cache, _env, _modelPath, mmc_mk_none(), &tmpMeta2, &tmpMeta6);
_cache = tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 4));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 6));
_c = tmpMeta2;
_id = tmpMeta3;
_encflag = tmpMeta4;
_restr = tmpMeta5;
_env_1 = tmpMeta6;
_env2 = omc_FGraph_openScope(threadData, _env_1, _encflag, _id, omc_FGraph_restrictionToScopeType(threadData, _restr));
_ci_state = omc_ClassInf_start(threadData, _restr, omc_FGraph_getGraphName(threadData, _env2));
_permissive = omc_Flags_getConfigBool(threadData, _OMC_LIT166);
omc_FlagsUtil_setConfigBool(threadData, _OMC_LIT166, 1);
{
{
volatile mmc_switch_type tmp10;
int tmp11;
tmp10 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp9_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp10 < 2; tmp10++) {
switch (MMC_SWITCH_CAST(tmp10)) {
case 0: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Inst_partialInstClassIn(threadData, _cache, _env2, tmpMeta12, _OMC_LIT155, _OMC_LIT134, _ci_state, _c, _OMC_LIT167, tmpMeta13, ((modelica_integer) 0) ,&_env2 ,NULL ,NULL ,NULL);
omc_FlagsUtil_setConfigBool(threadData, _OMC_LIT166, _permissive);
goto tmp9_done;
}
case 1: {
omc_FlagsUtil_setConfigBool(threadData, _OMC_LIT166, _permissive);
goto goto_8;
goto tmp9_done;
}
}
goto tmp9_end;
tmp9_end: ;
}
goto goto_8;
tmp9_done:
(void)tmp10;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp9_done2;
goto_8:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp10 < 2) {
goto tmp9_top;
}
MMC_THROW_INTERNAL();
tmp9_done2:;
}
}
;
tmpMeta14 = mmc_mk_box5(5, &Interactive_GraphicEnvCache_GRAPHIC__ENV__FULL__CACHE__desc, omc_SymbolTable_getAbsyn(threadData), _modelPath, _cache, _env2);
_genv = tmpMeta14;
}
_return: OMC_LABEL_UNUSED
return _genv;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_getElements2(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_boolean _inBoolean, modelica_integer _inAccess)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_boolean tmp4_2;volatile modelica_integer tmp4_3;
tmp4_1 = _inComponentRef;
tmp4_2 = _inBoolean;
tmp4_3 = _inAccess;
{
modelica_metatype _modelpath = NULL;
modelica_metatype _cdef = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_string _str = NULL;
modelica_metatype _comps1 = NULL;
modelica_metatype _comps2 = NULL;
modelica_metatype _model_ = NULL;
modelica_boolean _b;
modelica_metatype _genv = NULL;
modelica_integer _access;
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
_model_ = tmp4_1;
_b = tmp4_2;
_access = tmp4_3;
_modelpath = omc_AbsynUtil_crefToPath(threadData, _model_);
_cdef = omc_InteractiveUtil_getPathedClassInProgram(threadData, _modelpath, omc_SymbolTable_getAbsyn(threadData), 0, 0);
_genv = omc_InteractiveUtil_createEnvironment(threadData, omc_SymbolTable_getAbsyn(threadData), mmc_mk_some(omc_SymbolTable_getSCode(threadData)), _modelpath);
_comps1 = omc_InteractiveUtil_getPublicElementsInClass(threadData, _cdef);
_s1 = omc_InteractiveUtil_getElementsInfo(threadData, _comps1, _b, _OMC_LIT168, _genv);
if((_access >= ((modelica_integer) 4)))
{
_comps2 = omc_InteractiveUtil_getProtectedElementsInClass(threadData, _cdef);
_s2 = omc_InteractiveUtil_getElementsInfo(threadData, _comps2, _b, _OMC_LIT169, _genv);
}
else
{
_s2 = _OMC_LIT14;
}
tmpMeta6 = mmc_mk_cons(_s1, mmc_mk_cons(_s2, MMC_REFSTRUCTLIT(mmc_nil)));
_str = omc_Util_stringDelimitListNonEmptyElts(threadData, tmpMeta6, _OMC_LIT15);
tmpMeta7 = mmc_mk_cons(_OMC_LIT55, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT39, MMC_REFSTRUCTLIT(mmc_nil))));
tmp1 = stringAppendList(tmpMeta7);
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT162;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getElements2(threadData_t *threadData, modelica_metatype _inComponentRef, modelica_metatype _inBoolean, modelica_metatype _inAccess)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_inBoolean);
tmp2 = mmc_unbox_integer(_inAccess);
_outString = omc_InteractiveUtil_getElements2(threadData, _inComponentRef, tmp1, tmp2);
return _outString;
}
DLLExport
modelica_string omc_InteractiveUtil_getElements(threadData_t *threadData, modelica_metatype _cr, modelica_boolean _inBoolean, modelica_integer _inAccess)
{
modelica_string _outString = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outString = omc_InteractiveUtil_getElements2(threadData, _cr, _inBoolean, _inAccess);
_return: OMC_LABEL_UNUSED
return _outString;
}
modelica_metatype boxptr_InteractiveUtil_getElements(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _inBoolean, modelica_metatype _inAccess)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_inBoolean);
tmp2 = mmc_unbox_integer(_inAccess);
_outString = omc_InteractiveUtil_getElements(threadData, _cr, tmp1, tmp2);
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_updateProgram2(threadData_t *threadData, modelica_metatype _inNewClasses, modelica_metatype _w, modelica_metatype _inOldProgram, modelica_boolean _mergeAST)
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
if(omc_InteractiveUtil_classInProgram(threadData, _name, _p2))
{
_newp = omc_InteractiveUtil_replaceClassInProgram(threadData, _c1, _p2, _mergeAST);
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
_newp = omc_InteractiveUtil_insertClassInProgram(threadData, _c1, _w, _p2, _mergeAST);
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_updateProgram2(threadData_t *threadData, modelica_metatype _inNewClasses, modelica_metatype _w, modelica_metatype _inOldProgram, modelica_metatype _mergeAST)
{
modelica_integer tmp1;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outProgram = omc_InteractiveUtil_updateProgram2(threadData, _inNewClasses, _w, _inOldProgram, tmp1);
return _outProgram;
}
DLLExport
modelica_metatype omc_InteractiveUtil_updateProgram(threadData_t *threadData, modelica_metatype _inNewProgram, modelica_metatype _inOldProgram, modelica_boolean _mergeAST)
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
_outProgram = omc_InteractiveUtil_updateProgram2(threadData, listReverse(_cs), _w, _inOldProgram, _mergeAST);
_return: OMC_LABEL_UNUSED
return _outProgram;
}
modelica_metatype boxptr_InteractiveUtil_updateProgram(threadData_t *threadData, modelica_metatype _inNewProgram, modelica_metatype _inOldProgram, modelica_metatype _mergeAST)
{
modelica_integer tmp1;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_mergeAST);
_outProgram = omc_InteractiveUtil_updateProgram(threadData, _inNewProgram, _inOldProgram, tmp1);
return _outProgram;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getComponentitemsInElement(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outAbsynComponentItemLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_metatype _l = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_l = tmpMeta7;
tmpMeta1 = _l;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
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
_outAbsynComponentItemLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynComponentItemLst;
}
DLLExport
modelica_boolean omc_InteractiveUtil_componentitemNamed(threadData_t *threadData, modelica_metatype _inComponentItem, modelica_string _inIdent)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_string tmp4_2;
tmp4_1 = _inComponentItem;
tmp4_2 = _inIdent;
{
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_id1 = tmpMeta7;
_id2 = tmp4_2;
if (!(stringEqual(_id1, _id2))) goto tmp3_end;
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_InteractiveUtil_componentitemNamed(threadData_t *threadData, modelica_metatype _inComponentItem, modelica_metatype _inIdent)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_InteractiveUtil_componentitemNamed(threadData, _inComponentItem, _inIdent);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_metatype omc_InteractiveUtil_buildWithin(threadData_t *threadData, modelica_metatype _inPath)
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
tmpMeta1 = _OMC_LIT12;
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
DLLExport
modelica_metatype omc_InteractiveUtil_getVariableBindingInComponentitem(threadData_t *threadData, modelica_metatype _inComponentItem)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponentItem;
{
modelica_metatype _e = NULL;
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
modelica_metatype tmpMeta10;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_e = tmpMeta10;
tmpMeta1 = _e;
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getComponentInClass(threadData_t *threadData, modelica_metatype _cls, modelica_string _componentName)
{
modelica_metatype _component = NULL;
modelica_metatype _body = NULL;
modelica_metatype _parts = NULL;
modelica_metatype _elements = NULL;
modelica_metatype _components = NULL;
modelica_boolean _found;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_found = 0;
tmpMeta1 = _cls;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 7));
_body = tmpMeta2;
{
modelica_metatype tmp6_1;
tmp6_1 = _body;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,5) == 0) goto tmp5_end;
tmpMeta3 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_body), 4)));
goto tmp5_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,4,5) == 0) goto tmp5_end;
tmpMeta3 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_body), 5)));
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
_parts = tmpMeta3;
{
modelica_metatype _part;
for (tmpMeta8 = _parts; !listEmpty(tmpMeta8); tmpMeta8=MMC_CDR(tmpMeta8))
{
_part = MMC_CAR(tmpMeta8);
{
modelica_metatype tmp12_1;
tmp12_1 = _part;
{
int tmp12;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp12_1))) {
case 3: {
tmpMeta9 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2)));
goto tmp11_done;
}
case 4: {
tmpMeta9 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2)));
goto tmp11_done;
}
default:
tmp11_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta13;
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta9 = tmpMeta13;
goto tmp11_done;
}
}
goto tmp11_end;
tmp11_end: ;
}
goto goto_10;
goto_10:;
MMC_THROW_INTERNAL();
goto tmp11_done;
tmp11_done:;
}
}
_elements = tmpMeta9;
{
modelica_metatype _e;
for (tmpMeta14 = _elements; !listEmpty(tmpMeta14); tmpMeta14=MMC_CDR(tmpMeta14))
{
_e = MMC_CAR(tmpMeta14);
{
modelica_metatype tmp18_1;
tmp18_1 = _e;
{
volatile mmc_switch_type tmp18;
int tmp19;
tmp18 = 0;
for (; tmp18 < 2; tmp18++) {
switch (MMC_SWITCH_CAST(tmp18)) {
case 0: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp18_1,0,1) == 0) goto tmp17_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp18_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,0,6) == 0) goto tmp17_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,3,3) == 0) goto tmp17_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 4));
_components = tmpMeta22;
tmpMeta15 = _components;
goto tmp17_done;
}
case 1: {
modelica_metatype tmpMeta23;
tmpMeta23 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta15 = tmpMeta23;
goto tmp17_done;
}
}
goto tmp17_end;
tmp17_end: ;
}
goto goto_16;
goto_16:;
MMC_THROW_INTERNAL();
goto tmp17_done;
tmp17_done:;
}
}
_components = tmpMeta15;
{
modelica_metatype _c;
for (tmpMeta24 = _components; !listEmpty(tmpMeta24); tmpMeta24=MMC_CDR(tmpMeta24))
{
_c = MMC_CAR(tmpMeta24);
if((stringEqual(omc_AbsynUtil_componentName(threadData, _c), _componentName)))
{
_component = _c;
goto _return;
}
}
}
}
}
}
}
MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return _component;
}
DLLExport
modelica_string omc_InteractiveUtil_getElementBinding(threadData_t *threadData, modelica_metatype _path, modelica_string _parameterName, modelica_metatype _program)
{
modelica_string _bindingStr = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _component = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_cls = omc_InteractiveUtil_getPathedClassInProgram(threadData, _path, _program, 0, 0);
_component = omc_InteractiveUtil_getComponentInClass(threadData, _cls, _parameterName);
_bindingStr = omc_Dump_printExpStr(threadData, omc_InteractiveUtil_getVariableBindingInComponentitem(threadData, _component));
goto tmp2_done;
}
case 1: {
_bindingStr = _OMC_LIT14;
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
return _bindingStr;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getModificationNames(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_boolean _includeRedeclares)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inAbsynElementArgLst;
{
modelica_metatype _names = NULL;
modelica_metatype _names2 = NULL;
modelica_metatype _res = NULL;
modelica_string _name = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _args = NULL;
modelica_metatype _elSpec = NULL;
modelica_metatype _p = NULL;
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
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 6;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,6) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
if (!optionNone(tmpMeta11)) goto tmp3_end;
_name = tmpMeta10;
_rest = tmpMeta8;
tmp4 += 4;
_names = omc_InteractiveUtil_getModificationNames(threadData, _rest, _includeRedeclares);
tmpMeta12 = mmc_mk_cons(_name, _names);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,6) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 4));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 5));
if (optionNone(tmpMeta16)) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 1));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
if (!listEmpty(tmpMeta18)) goto tmp3_end;
_p = tmpMeta15;
_rest = tmpMeta14;
_name = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT5, 1, 0);
_names = omc_InteractiveUtil_getModificationNames(threadData, _rest, _includeRedeclares);
tmpMeta19 = mmc_mk_cons(_name, _names);
tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta33;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta20 = MMC_CAR(tmp4_1);
tmpMeta21 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,0,6) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 4));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 5));
if (optionNone(tmpMeta23)) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 1));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 2));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,1,2) == 0) goto tmp3_end;
_p = tmpMeta22;
_args = tmpMeta25;
_rest = tmpMeta21;
_name = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT5, 1, 0);
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_string __omcQ_24tmpVar6;
modelica_integer tmp32;
modelica_metatype _n_loopVar = 0;
modelica_metatype _n;
_n_loopVar = omc_InteractiveUtil_getModificationNames(threadData, _args, _includeRedeclares);
tmpMeta29 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta29;
tmp28 = &__omcQ_24tmpVar7;
while(1) {
tmp32 = 1;
if (!listEmpty(_n_loopVar)) {
_n = MMC_CAR(_n_loopVar);
_n_loopVar = MMC_CDR(_n_loopVar);
tmp32--;
}
if (tmp32 == 0) {
tmpMeta30 = stringAppend(_name,_OMC_LIT5);
tmpMeta31 = stringAppend(tmpMeta30,_n);
__omcQ_24tmpVar6 = tmpMeta31;
*tmp28 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp28 = &MMC_CDR(*tmp28);
} else if (tmp32 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp28 = mmc_mk_nil();
tmpMeta27 = __omcQ_24tmpVar7;
}
_names2 = tmpMeta27;
_names = omc_InteractiveUtil_getModificationNames(threadData, _rest, _includeRedeclares);
_res = listAppend(_names2, _names);
tmpMeta33 = mmc_mk_cons(_name, _res);
tmpMeta1 = tmpMeta33;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta34 = MMC_CAR(tmp4_1);
tmpMeta35 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,0,6) == 0) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 4));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 5));
if (optionNone(tmpMeta37)) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 1));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 2));
_p = tmpMeta36;
_args = tmpMeta39;
_rest = tmpMeta35;
tmp4 += 1;
_name = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT5, 1, 0);
{
modelica_metatype __omcQ_24tmpVar9;
modelica_metatype* tmp41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_string __omcQ_24tmpVar8;
modelica_integer tmp45;
modelica_metatype _n_loopVar = 0;
modelica_metatype _n;
_n_loopVar = omc_InteractiveUtil_getModificationNames(threadData, _args, _includeRedeclares);
tmpMeta42 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar9 = tmpMeta42;
tmp41 = &__omcQ_24tmpVar9;
while(1) {
tmp45 = 1;
if (!listEmpty(_n_loopVar)) {
_n = MMC_CAR(_n_loopVar);
_n_loopVar = MMC_CDR(_n_loopVar);
tmp45--;
}
if (tmp45 == 0) {
tmpMeta43 = stringAppend(_name,_OMC_LIT5);
tmpMeta44 = stringAppend(tmpMeta43,_n);
__omcQ_24tmpVar8 = tmpMeta44;
*tmp41 = mmc_mk_cons(__omcQ_24tmpVar8,0);
tmp41 = &MMC_CDR(*tmp41);
} else if (tmp45 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp41 = mmc_mk_nil();
tmpMeta40 = __omcQ_24tmpVar9;
}
_names2 = tmpMeta40;
_names = omc_InteractiveUtil_getModificationNames(threadData, _rest, _includeRedeclares);
tmpMeta1 = listAppend(_names2, _names);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta46 = MMC_CAR(tmp4_1);
tmpMeta47 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta46,1,6) == 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 5));
_elSpec = tmpMeta48;
_rest = tmpMeta47;
if (!_includeRedeclares) goto tmp3_end;
_name = omc_AbsynUtil_elementSpecName(threadData, _elSpec);
_names = omc_InteractiveUtil_getModificationNames(threadData, _rest, _includeRedeclares);
tmpMeta49 = mmc_mk_cons(_name, _names);
tmpMeta1 = tmpMeta49;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta50 = MMC_CAR(tmp4_1);
tmpMeta51 = MMC_CDR(tmp4_1);
_rest = tmpMeta51;
tmpMeta1 = omc_InteractiveUtil_getModificationNames(threadData, _rest, _includeRedeclares);
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
_outStringLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStringLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getModificationNames(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_metatype _includeRedeclares)
{
modelica_integer tmp1;
modelica_metatype _outStringLst = NULL;
tmp1 = mmc_unbox_integer(_includeRedeclares);
_outStringLst = omc_InteractiveUtil_getModificationNames(threadData, _inAbsynElementArgLst, tmp1);
return _outStringLst;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getElementModifierNames(threadData_t *threadData, modelica_metatype _path, modelica_string _inElementName, modelica_metatype _inProgram3)
{
modelica_metatype _outList = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp6_1;
tmp6_1 = _inProgram3;
{
modelica_metatype _cdef = NULL;
modelica_metatype _elems = NULL;
modelica_string _name = NULL;
modelica_metatype _p = NULL;
modelica_metatype _mod = NULL;
modelica_metatype tmpMeta3;
modelica_metatype _args = NULL;
modelica_metatype tmpMeta4;
modelica_metatype _components = NULL;
modelica_boolean _found;
modelica_metatype _optMod = NULL;
volatile mmc_switch_type tmp6;
int tmp7;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_mod = tmpMeta3;
tmpMeta4 = MMC_REFSTRUCTLIT(mmc_nil);
_args = tmpMeta4;
_found = 0;
tmp6 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp5_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta30;
_p = tmp6_1;
_cdef = omc_InteractiveUtil_getPathedClassInProgram(threadData, _path, _p, 0, 0);
_elems = omc_InteractiveUtil_getElementsInClass(threadData, _cdef);
{
modelica_metatype _e;
for (tmpMeta8 = _elems; !listEmpty(tmpMeta8); tmpMeta8=MMC_CDR(tmpMeta8))
{
_e = MMC_CAR(tmpMeta8);
{
modelica_metatype tmp12_1;
tmp12_1 = _e;
{
volatile mmc_switch_type tmp12;
int tmp13;
tmp12 = 0;
for (; tmp12 < 3; tmp12++) {
switch (MMC_SWITCH_CAST(tmp12)) {
case 0: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp12_1,0,6) == 0) goto tmp11_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp12_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,0,2) == 0) goto tmp11_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 3));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,1,4) == 0) goto tmp11_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 4));
_name = tmpMeta16;
_args = tmpMeta18;
if (!(stringEqual(_name, _inElementName))) goto tmp11_end;
_found = 1;
tmpMeta9 = _args;
goto tmp11_done;
}
case 1: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp12_1,0,6) == 0) goto tmp11_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp12_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,3,3) == 0) goto tmp11_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 4));
_components = tmpMeta20;
{
modelica_metatype _c;
for (tmpMeta21 = _components; !listEmpty(tmpMeta21); tmpMeta21=MMC_CDR(tmpMeta21))
{
_c = MMC_CAR(tmpMeta21);
tmpMeta22 = _c;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 4));
_name = tmpMeta24;
_optMod = tmpMeta25;
if((stringEqual(_name, _inElementName)))
{
tmpMeta26 = omc_Util_getOptionOrDefault(threadData, _optMod, _OMC_LIT170);
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
_mod = tmpMeta27;
_found = 1;
}
}
}
tmpMeta9 = _mod;
goto tmp11_done;
}
case 2: {
modelica_metatype tmpMeta29;
tmpMeta29 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta9 = tmpMeta29;
goto tmp11_done;
}
}
goto tmp11_end;
tmp11_end: ;
}
goto goto_10;
goto_10:;
goto goto_2;
goto tmp11_done;
tmp11_done:;
}
}
_mod = tmpMeta9;
if(_found)
{
break;
}
}
}
tmpMeta1 = omc_InteractiveUtil_getModificationNames(threadData, _mod, 1);
goto tmp5_done;
}
case 1: {
modelica_metatype tmpMeta31;
tmpMeta31 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta31;
goto tmp5_done;
}
}
goto tmp5_end;
tmp5_end: ;
}
goto goto_2;
tmp5_done:
(void)tmp6;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp5_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp6 < 2) {
goto tmp5_top;
}
MMC_THROW_INTERNAL();
tmp5_done2:;
}
}
_outList = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getModificationValues(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_metatype _inPath)
{
modelica_metatype _outModification = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inAbsynElementArgLst;
tmp4_2 = _inPath;
{
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _args = NULL;
modelica_string _name1 = NULL;
modelica_string _name2 = NULL;
modelica_metatype _elSpec = NULL;
modelica_metatype _elArg = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (optionNone(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
_p1 = tmpMeta8;
_mod = tmpMeta10;
_p2 = tmp4_2;
if (!omc_AbsynUtil_pathEqual(threadData, _p1, _p2)) goto tmp3_end;
tmpMeta1 = _mod;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,6) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,1,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 5));
if (optionNone(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 1));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
_name2 = tmpMeta11;
_p2 = tmpMeta12;
_name1 = tmpMeta16;
_args = tmpMeta19;
if (!(stringEqual(_name1, _name2))) goto tmp3_end;
_inAbsynElementArgLst = _args;
_inPath = _p2;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta20 = MMC_CAR(tmp4_1);
tmpMeta21 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,1,6) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 5));
_elArg = tmpMeta20;
_elSpec = tmpMeta22;
_p1 = tmp4_2;
if (!(stringEqual(omc_AbsynUtil_pathFirstIdent(threadData, _p1), omc_AbsynUtil_elementSpecName(threadData, _elSpec)))) goto tmp3_end;
tmpMeta23 = mmc_mk_cons(_elArg, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta24 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta23, _OMC_LIT17);
tmpMeta1 = tmpMeta24;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta25 = MMC_CAR(tmp4_1);
tmpMeta26 = MMC_CDR(tmp4_1);
_rest = tmpMeta26;
_inAbsynElementArgLst = _rest;
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
_outModification = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outModification;
}
DLLExport
modelica_string omc_InteractiveUtil_unparseMods(threadData_t *threadData, modelica_metatype _mod)
{
modelica_string _s = NULL;
modelica_metatype _arg = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _mod;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,6) == 0) goto tmp3_end;
_arg = tmpMeta7;
tmp1 = omc_System_escapedString(threadData, omc_Dump_unparseElementArgStr(threadData, _arg), 0);
goto tmp3_done;
}
case 1: {
tmp1 = omc_Dump_unparseModificationStr(threadData, _mod);
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
_s = tmp1;
_return: OMC_LABEL_UNUSED
return _s;
}
DLLExport
modelica_string omc_InteractiveUtil_getElementModifierValues(threadData_t *threadData, modelica_metatype _inComponentRef1, modelica_metatype _inComponentRef2, modelica_metatype _inComponentRef3, modelica_metatype _inProgram4)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;
tmp4_1 = _inComponentRef1;
tmp4_2 = _inComponentRef2;
tmp4_3 = _inComponentRef3;
tmp4_4 = _inProgram4;
{
modelica_metatype _p_class = NULL;
modelica_string _name = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype _elems = NULL;
modelica_metatype _compelts = NULL;
modelica_metatype _compelts_1 = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _class_ = NULL;
modelica_metatype _ident = NULL;
modelica_metatype _subident = NULL;
modelica_metatype _p = NULL;
modelica_metatype _elementArgLst = NULL;
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
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
_class_ = tmp4_1;
_ident = tmp4_2;
_subident = tmp4_3;
_p = tmp4_4;
_p_class = omc_AbsynUtil_crefToPath(threadData, _class_);
tmpMeta6 = omc_AbsynUtil_crefToPath(threadData, _ident);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto goto_2;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_name = tmpMeta7;
_cdef = omc_InteractiveUtil_getPathedClassInProgram(threadData, _p_class, _p, 0, 0);
_elems = omc_InteractiveUtil_getElementsInClass(threadData, _cdef);
_compelts = omc_List_map(threadData, _elems, boxvar_InteractiveUtil_getComponentitemsInElement);
_compelts_1 = omc_List_flatten(threadData, _compelts);
tmpMeta8 = omc_List_select1(threadData, _compelts_1, boxvar_InteractiveUtil_componentitemNamed, _name);
if (listEmpty(tmpMeta8)) goto goto_2;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 4));
if (optionNone(tmpMeta12)) goto goto_2;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
if (!listEmpty(tmpMeta10)) goto goto_2;
_elementArgLst = tmpMeta14;
_mod = omc_InteractiveUtil_getModificationValues(threadData, _elementArgLst, omc_AbsynUtil_crefToPath(threadData, _subident));
tmp1 = omc_InteractiveUtil_unparseMods(threadData, _mod);
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT162;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_string omc_InteractiveUtil_getModificationValueStr(threadData_t *threadData, modelica_metatype _args, modelica_metatype _path)
{
modelica_string _value = NULL;
modelica_string _name = NULL;
modelica_metatype _rest_args = NULL;
modelica_metatype _arg = NULL;
modelica_boolean _found;
modelica_metatype _elSpec = NULL;
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_boolean tmp4 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_value = _OMC_LIT14;
_rest_args = _args;
_found = 0;
while(1)
{
if(!(!_found)) break;
tmpMeta1 = _rest_args;
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
_arg = tmpMeta2;
_rest_args = tmpMeta3;
{
modelica_metatype tmp7_1;
tmp7_1 = _arg;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 4; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,6) == 0) goto tmp6_end;
if (!omc_AbsynUtil_pathEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 4))), _path)) goto tmp6_end;
tmpMeta9 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 5)));
if (optionNone(tmpMeta9)) goto goto_5;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,1,2) == 0) goto goto_5;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_exp = tmpMeta12;
_value = omc_Dump_printExpStr(threadData, _exp);
tmp4 = 1;
goto tmp6_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,6) == 0) goto tmp6_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,1,1) == 0) goto tmp6_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
_name = tmpMeta14;
if (!(stringEqual(_name, omc_AbsynUtil_pathFirstIdent(threadData, _path)))) goto tmp6_end;
tmpMeta15 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 5)));
if (optionNone(tmpMeta15)) goto goto_5;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 1));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
_rest_args = tmpMeta17;
_value = omc_InteractiveUtil_getModificationValueStr(threadData, _rest_args, omc_AbsynUtil_pathRest(threadData, _path));
tmp4 = 1;
goto tmp6_done;
}
case 2: {
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,1,6) == 0) goto tmp6_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 5));
_elSpec = tmpMeta18;
if (!(stringEqual(omc_AbsynUtil_pathFirstIdent(threadData, _path), omc_AbsynUtil_elementSpecName(threadData, _elSpec)))) goto tmp6_end;
_value = omc_System_escapedString(threadData, omc_Dump_unparseElementArgStr(threadData, _arg), 0);
tmp4 = 1;
goto tmp6_done;
}
case 3: {
tmp4 = 0;
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
}
_found = tmp4;
}
_return: OMC_LABEL_UNUSED
return _value;
}
DLLExport
modelica_string omc_InteractiveUtil_getElementModifierValue(threadData_t *threadData, modelica_metatype _classRef, modelica_metatype _varRef, modelica_metatype _subModRef, modelica_metatype _program)
{
modelica_string _valueStr = NULL;
modelica_metatype _cls_path = NULL;
modelica_string _name = NULL;
modelica_string _elName = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _args = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _elems = NULL;
modelica_boolean _found;
modelica_metatype _components = NULL;
modelica_metatype _optMod = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_args = tmpMeta1;
_found = 0;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta28;
_cls_path = omc_AbsynUtil_crefToPath(threadData, _classRef);
_elName = omc_AbsynUtil_crefIdent(threadData, _varRef);
_cls = omc_InteractiveUtil_getPathedClassInProgram(threadData, _cls_path, _program, 0, 0);
_elems = omc_InteractiveUtil_getElementsInClass(threadData, _cls);
{
modelica_metatype _e;
for (tmpMeta6 = _elems; !listEmpty(tmpMeta6); tmpMeta6=MMC_CDR(tmpMeta6))
{
_e = MMC_CAR(tmpMeta6);
{
modelica_metatype tmp10_1;
tmp10_1 = _e;
{
volatile mmc_switch_type tmp10;
int tmp11;
tmp10 = 0;
for (; tmp10 < 3; tmp10++) {
switch (MMC_SWITCH_CAST(tmp10)) {
case 0: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp10_1,0,6) == 0) goto tmp9_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp10_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,0,2) == 0) goto tmp9_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,1,4) == 0) goto tmp9_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 4));
_name = tmpMeta14;
_args = tmpMeta16;
if (!(stringEqual(_name, _elName))) goto tmp9_end;
_found = 1;
tmpMeta7 = _args;
goto tmp9_done;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp10_1,0,6) == 0) goto tmp9_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp10_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,3,3) == 0) goto tmp9_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 4));
_components = tmpMeta18;
{
modelica_metatype _c;
for (tmpMeta19 = _components; !listEmpty(tmpMeta19); tmpMeta19=MMC_CDR(tmpMeta19))
{
_c = MMC_CAR(tmpMeta19);
tmpMeta20 = _c;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 4));
_name = tmpMeta22;
_optMod = tmpMeta23;
if((stringEqual(_name, _elName)))
{
tmpMeta24 = omc_Util_getOptionOrDefault(threadData, _optMod, _OMC_LIT170);
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 2));
_args = tmpMeta25;
_found = 1;
}
}
}
tmpMeta7 = _args;
goto tmp9_done;
}
case 2: {
modelica_metatype tmpMeta27;
tmpMeta27 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta7 = tmpMeta27;
goto tmp9_done;
}
}
goto tmp9_end;
tmp9_end: ;
}
goto goto_8;
goto_8:;
goto goto_2;
goto tmp9_done;
tmp9_done:;
}
}
_args = tmpMeta7;
if(_found)
{
break;
}
}
}
if(_found)
{
_valueStr = omc_InteractiveUtil_getModificationValueStr(threadData, _args, omc_AbsynUtil_crefToPath(threadData, _subModRef));
}
else
{
_valueStr = _OMC_LIT14;
}
goto tmp3_done;
}
case 1: {
_valueStr = _OMC_LIT14;
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
;
_return: OMC_LABEL_UNUSED
return _valueStr;
}
DLLExport
modelica_boolean omc_InteractiveUtil_findPathModification(threadData_t *threadData, modelica_metatype _path, modelica_metatype _lst)
{
modelica_boolean _found;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _lst;
{
modelica_metatype _p = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,6) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_p = tmpMeta8;
if (!omc_AbsynUtil_pathEqual(threadData, _path, _p)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_1);
tmpMeta10 = MMC_CDR(tmp4_1);
_rest = tmpMeta10;
_lst = _rest;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
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
_found = tmp1;
_return: OMC_LABEL_UNUSED
return _found;
}
modelica_metatype boxptr_InteractiveUtil_findPathModification(threadData_t *threadData, modelica_metatype _path, modelica_metatype _lst)
{
modelica_boolean _found;
modelica_metatype out_found;
_found = omc_InteractiveUtil_findPathModification(threadData, _path, _lst);
out_found = mmc_mk_icon(_found);
return out_found;
}
DLLExport
modelica_metatype omc_InteractiveUtil_setSubmodifierInElementargs(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_metatype _inPath, modelica_metatype _inModification)
{
modelica_metatype _outAbsynElementArgLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inAbsynElementArgLst;
tmp4_2 = _inPath;
tmp4_3 = _inModification;
{
modelica_metatype _mod = NULL;
modelica_boolean _f;
modelica_metatype _each_ = NULL;
modelica_string _name = NULL;
modelica_string _submodident = NULL;
modelica_string _name1 = NULL;
modelica_string _name2 = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _args_1 = NULL;
modelica_metatype _args = NULL;
modelica_metatype _res = NULL;
modelica_metatype _submods = NULL;
modelica_metatype _m = NULL;
modelica_metatype _eqMod = NULL;
modelica_metatype _info = NULL;
modelica_metatype _p = NULL;
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 14; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,0) == 0) goto tmp3_end;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (!listEmpty(tmp4_1)) goto tmp3_end;
_mod = tmp4_3;
tmp4 += 11;
tmpMeta10 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0), _OMC_LIT16, _inPath, mmc_mk_some(_mod), mmc_mk_none(), _OMC_LIT19);
tmpMeta9 = mmc_mk_cons(tmpMeta10, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_integer tmp17;
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
modelica_boolean tmp28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (!listEmpty(tmpMeta12)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,0) == 0) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmp4_1);
tmpMeta15 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,0,6) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 3));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,1,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 5));
if (optionNone(tmpMeta21)) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 1));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
if (listEmpty(tmpMeta23)) goto tmp3_end;
tmpMeta24 = MMC_CAR(tmpMeta23);
tmpMeta25 = MMC_CDR(tmpMeta23);
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 6));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 7));
_submodident = tmpMeta11;
_f = tmp17;
_each_ = tmpMeta18;
_p = tmpMeta19;
_name = tmpMeta20;
_submods = tmpMeta23;
_cmt = tmpMeta26;
_info = tmpMeta27;
_rest = tmpMeta15;
tmp4 += 2;
tmp28 = (stringEqual(_name, _submodident));
if (1 != tmp28) goto goto_2;
tmpMeta30 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _submods, _OMC_LIT17);
tmpMeta31 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(_f), _each_, _p, mmc_mk_some(tmpMeta30), _cmt, _info);
tmpMeta29 = mmc_mk_cons(tmpMeta31, _rest);
tmpMeta1 = tmpMeta29;
goto tmp3_done;
}
case 3: {
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
modelica_boolean tmp42;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (!listEmpty(tmpMeta33)) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,0,0) == 0) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta35 = MMC_CAR(tmp4_1);
tmpMeta36 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta35,0,6) == 0) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta37,1,1) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 2));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 5));
if (optionNone(tmpMeta39)) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 1));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta40), 2));
if (!listEmpty(tmpMeta41)) goto tmp3_end;
_submodident = tmpMeta32;
_name = tmpMeta38;
_rest = tmpMeta36;
tmp4 += 1;
tmp42 = (stringEqual(_name, _submodident));
if (1 != tmp42) goto goto_2;
tmpMeta1 = _rest;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_integer tmp49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_boolean tmp58;
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (!listEmpty(tmpMeta44)) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta45,1,2) == 0) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta46 = MMC_CAR(tmp4_1);
tmpMeta47 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta46,0,6) == 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 2));
tmp49 = mmc_unbox_integer(tmpMeta48);
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 3));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta51,1,1) == 0) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta51), 2));
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 5));
if (optionNone(tmpMeta53)) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta53), 1));
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 2));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 6));
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 7));
_submodident = tmpMeta43;
_eqMod = tmpMeta45;
_f = tmp49;
_each_ = tmpMeta50;
_name = tmpMeta52;
_submods = tmpMeta55;
_cmt = tmpMeta56;
_info = tmpMeta57;
_rest = tmpMeta47;
tmp58 = (stringEqual(_name, _submodident));
if (1 != tmp58) goto goto_2;
tmpMeta60 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
tmpMeta61 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _submods, _eqMod);
tmpMeta62 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(_f), _each_, tmpMeta60, mmc_mk_some(tmpMeta61), _cmt, _info);
tmpMeta59 = mmc_mk_cons(tmpMeta62, _rest);
tmpMeta1 = tmpMeta59;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_integer tmp67;
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_boolean tmp73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta64 = MMC_CAR(tmp4_1);
tmpMeta65 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta64,0,6) == 0) goto tmp3_end;
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta64), 2));
tmp67 = mmc_unbox_integer(tmpMeta66);
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta64), 3));
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta64), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta69,1,1) == 0) goto tmp3_end;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 2));
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta64), 6));
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta64), 7));
_submodident = tmpMeta63;
_f = tmp67;
_each_ = tmpMeta68;
_name = tmpMeta70;
_cmt = tmpMeta71;
_info = tmpMeta72;
_rest = tmpMeta65;
_mod = tmp4_3;
tmp4 += 5;
tmp73 = (stringEqual(_name, _submodident));
if (1 != tmp73) goto goto_2;
tmpMeta75 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
tmpMeta76 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(_f), _each_, tmpMeta75, mmc_mk_some(_mod), _cmt, _info);
tmpMeta74 = mmc_mk_cons(tmpMeta76, _rest);
tmpMeta1 = tmpMeta74;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
modelica_boolean tmp82;
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (!listEmpty(tmpMeta77)) goto tmp3_end;
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta78,0,0) == 0) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta79 = MMC_CAR(tmp4_1);
tmpMeta80 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta79,0,6) == 0) goto tmp3_end;
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta79), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta81,0,2) == 0) goto tmp3_end;
_p1 = tmpMeta81;
_rest = tmpMeta80;
_p2 = tmp4_2;
tmp82 = omc_AbsynUtil_pathEqual(threadData, _p1, _p2);
if (1 != tmp82) goto goto_2;
tmpMeta1 = _rest;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
modelica_boolean tmp90;
modelica_boolean tmp91;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (!listEmpty(tmpMeta84)) goto tmp3_end;
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta85,0,0) == 0) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta86 = MMC_CAR(tmp4_1);
tmpMeta87 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta86,0,6) == 0) goto tmp3_end;
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta86), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta88,0,2) == 0) goto tmp3_end;
tmpMeta89 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta88), 2));
_p = tmp4_2;
_name2 = tmpMeta83;
_name1 = tmpMeta89;
_rest = tmpMeta87;
tmp4 += 3;
tmp90 = (stringEqual(_name1, _name2));
if (1 != tmp90) goto goto_2;
tmp91 = omc_InteractiveUtil_findPathModification(threadData, _p, _rest);
if (0 != tmp91) goto goto_2;
tmpMeta1 = _rest;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_integer tmp99;
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
modelica_metatype tmpMeta104;
modelica_metatype tmpMeta105;
modelica_metatype tmpMeta106;
modelica_metatype tmpMeta107;
modelica_metatype tmpMeta108;
modelica_boolean tmp109;
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta92 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta93 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (!listEmpty(tmpMeta94)) goto tmp3_end;
tmpMeta95 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta95,0,0) == 0) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta96 = MMC_CAR(tmp4_1);
tmpMeta97 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta96,0,6) == 0) goto tmp3_end;
tmpMeta98 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta96), 2));
tmp99 = mmc_unbox_integer(tmpMeta98);
tmpMeta100 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta96), 3));
tmpMeta101 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta96), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta101,1,1) == 0) goto tmp3_end;
tmpMeta102 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta101), 2));
tmpMeta103 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta96), 5));
if (optionNone(tmpMeta103)) goto tmp3_end;
tmpMeta104 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta103), 1));
tmpMeta105 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta104), 2));
tmpMeta106 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta104), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta106,0,0) == 0) goto tmp3_end;
tmpMeta107 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta96), 6));
tmpMeta108 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta96), 7));
_name1 = tmpMeta92;
_p1 = tmpMeta93;
_f = tmp99;
_each_ = tmpMeta100;
_p = tmpMeta101;
_name2 = tmpMeta102;
_args = tmpMeta105;
_cmt = tmpMeta107;
_info = tmpMeta108;
_rest = tmpMeta97;
tmp4 += 1;
tmp109 = (stringEqual(_name1, _name2));
if (1 != tmp109) goto goto_2;
tmpMeta110 = omc_InteractiveUtil_setSubmodifierInElementargs(threadData, _args, _p1, _OMC_LIT170);
if (!listEmpty(tmpMeta110)) goto goto_2;
tmpMeta112 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(_f), _each_, _p, mmc_mk_none(), _cmt, _info);
tmpMeta111 = mmc_mk_cons(tmpMeta112, _rest);
tmpMeta1 = tmpMeta111;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta113;
modelica_metatype tmpMeta114;
modelica_metatype tmpMeta115;
modelica_metatype tmpMeta116;
modelica_metatype tmpMeta117;
modelica_metatype tmpMeta118;
modelica_metatype tmpMeta119;
modelica_integer tmp120;
modelica_metatype tmpMeta121;
modelica_metatype tmpMeta122;
modelica_metatype tmpMeta123;
modelica_metatype tmpMeta124;
modelica_metatype tmpMeta125;
modelica_metatype tmpMeta126;
modelica_metatype tmpMeta127;
modelica_metatype tmpMeta128;
modelica_metatype tmpMeta129;
modelica_boolean tmp130;
modelica_metatype tmpMeta131;
modelica_metatype tmpMeta132;
modelica_metatype tmpMeta133;
modelica_metatype tmpMeta134;
modelica_metatype tmpMeta135;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta113 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta114 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta115 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (!listEmpty(tmpMeta115)) goto tmp3_end;
tmpMeta116 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta116,0,0) == 0) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta117 = MMC_CAR(tmp4_1);
tmpMeta118 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta117,0,6) == 0) goto tmp3_end;
tmpMeta119 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta117), 2));
tmp120 = mmc_unbox_integer(tmpMeta119);
tmpMeta121 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta117), 3));
tmpMeta122 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta117), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta122,1,1) == 0) goto tmp3_end;
tmpMeta123 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta122), 2));
tmpMeta124 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta117), 5));
if (optionNone(tmpMeta124)) goto tmp3_end;
tmpMeta125 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta124), 1));
tmpMeta126 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta125), 2));
tmpMeta127 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta125), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta127,1,2) == 0) goto tmp3_end;
tmpMeta128 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta117), 6));
tmpMeta129 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta117), 7));
_name1 = tmpMeta113;
_p1 = tmpMeta114;
_f = tmp120;
_each_ = tmpMeta121;
_p = tmpMeta122;
_name2 = tmpMeta123;
_args = tmpMeta126;
_eqMod = tmpMeta127;
_cmt = tmpMeta128;
_info = tmpMeta129;
_rest = tmpMeta118;
tmp130 = (stringEqual(_name1, _name2));
if (1 != tmp130) goto goto_2;
tmpMeta131 = omc_InteractiveUtil_setSubmodifierInElementargs(threadData, _args, _p1, _OMC_LIT170);
if (!listEmpty(tmpMeta131)) goto goto_2;
tmpMeta133 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta134 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta133, _eqMod);
tmpMeta135 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(_f), _each_, _p, mmc_mk_some(tmpMeta134), _cmt, _info);
tmpMeta132 = mmc_mk_cons(tmpMeta135, _rest);
tmpMeta1 = tmpMeta132;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta136;
modelica_metatype tmpMeta137;
modelica_metatype tmpMeta138;
modelica_metatype tmpMeta139;
modelica_metatype tmpMeta140;
modelica_integer tmp141;
modelica_metatype tmpMeta142;
modelica_metatype tmpMeta143;
modelica_metatype tmpMeta144;
modelica_metatype tmpMeta145;
modelica_metatype tmpMeta146;
modelica_metatype tmpMeta147;
modelica_metatype tmpMeta148;
modelica_metatype tmpMeta149;
modelica_metatype tmpMeta150;
modelica_boolean tmp151;
modelica_metatype tmpMeta152;
modelica_metatype tmpMeta153;
modelica_metatype tmpMeta154;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,2) == 0) goto tmp3_end;
tmpMeta136 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta137 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta138 = MMC_CAR(tmp4_1);
tmpMeta139 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta138,0,6) == 0) goto tmp3_end;
tmpMeta140 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta138), 2));
tmp141 = mmc_unbox_integer(tmpMeta140);
tmpMeta142 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta138), 3));
tmpMeta143 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta138), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta143,1,1) == 0) goto tmp3_end;
tmpMeta144 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta143), 2));
tmpMeta145 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta138), 5));
if (optionNone(tmpMeta145)) goto tmp3_end;
tmpMeta146 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta145), 1));
tmpMeta147 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta146), 2));
tmpMeta148 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta146), 3));
tmpMeta149 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta138), 6));
tmpMeta150 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta138), 7));
_name1 = tmpMeta136;
_p1 = tmpMeta137;
_f = tmp141;
_each_ = tmpMeta142;
_p = tmpMeta143;
_name2 = tmpMeta144;
_args = tmpMeta147;
_eqMod = tmpMeta148;
_cmt = tmpMeta149;
_info = tmpMeta150;
_rest = tmpMeta139;
_mod = tmp4_3;
tmp151 = (stringEqual(_name1, _name2));
if (1 != tmp151) goto goto_2;
_args_1 = omc_InteractiveUtil_setSubmodifierInElementargs(threadData, _args, _p1, _mod);
tmpMeta153 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _args_1, _eqMod);
tmpMeta154 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(_f), _each_, _p, mmc_mk_some(tmpMeta153), _cmt, _info);
tmpMeta152 = mmc_mk_cons(tmpMeta154, _rest);
tmpMeta1 = tmpMeta152;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta155;
modelica_metatype tmpMeta156;
modelica_metatype tmpMeta157;
modelica_integer tmp158;
modelica_metatype tmpMeta159;
modelica_metatype tmpMeta160;
modelica_metatype tmpMeta161;
modelica_metatype tmpMeta162;
modelica_metatype tmpMeta163;
modelica_metatype tmpMeta164;
modelica_boolean tmp165;
modelica_metatype tmpMeta166;
modelica_metatype tmpMeta167;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta155 = MMC_CAR(tmp4_1);
tmpMeta156 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta155,0,6) == 0) goto tmp3_end;
tmpMeta157 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta155), 2));
tmp158 = mmc_unbox_integer(tmpMeta157);
tmpMeta159 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta155), 3));
tmpMeta160 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta155), 4));
tmpMeta161 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta155), 5));
if (optionNone(tmpMeta161)) goto tmp3_end;
tmpMeta162 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta161), 1));
tmpMeta163 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta155), 6));
tmpMeta164 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta155), 7));
_f = tmp158;
_each_ = tmpMeta159;
_p1 = tmpMeta160;
_cmt = tmpMeta163;
_info = tmpMeta164;
_rest = tmpMeta156;
_p2 = tmp4_2;
_mod = tmp4_3;
tmp165 = omc_AbsynUtil_pathEqual(threadData, _p1, _p2);
if (1 != tmp165) goto goto_2;
tmpMeta167 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(_f), _each_, _p1, mmc_mk_some(_mod), _cmt, _info);
tmpMeta166 = mmc_mk_cons(tmpMeta167, _rest);
tmpMeta1 = tmpMeta166;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta168;
modelica_metatype tmpMeta169;
modelica_metatype tmpMeta170;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta168 = MMC_CAR(tmp4_1);
tmpMeta169 = MMC_CDR(tmp4_1);
_m = tmpMeta168;
_rest = tmpMeta169;
_p = tmp4_2;
_mod = tmp4_3;
_res = omc_InteractiveUtil_setSubmodifierInElementargs(threadData, _rest, _p, _mod);
tmpMeta170 = mmc_mk_cons(_m, _res);
tmpMeta1 = tmpMeta170;
goto tmp3_done;
}
case 13: {
fputs(MMC_STRINGDATA(_OMC_LIT171),stdout);
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
if (++tmp4 < 14) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outAbsynElementArgLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynElementArgLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setSubmodifierInClass(threadData_t *threadData, modelica_metatype _inElementName, modelica_metatype _inClass, modelica_metatype _inMod)
{
modelica_metatype _outClass = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _optMod = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _body = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cls = _inClass;
{
modelica_metatype tmp4_1;
tmp4_1 = _cls;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta20;
_body = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 7)));
{
modelica_metatype tmp9_1;
tmp9_1 = _body;
{
volatile mmc_switch_type tmp9;
int tmp10;
tmp9 = 0;
for (; tmp9 < 1; tmp9++) {
switch (MMC_SWITCH_CAST(tmp9)) {
case 0: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp9_1,1,4) == 0) goto tmp8_end;
tmpMeta11 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_body), 4))), _OMC_LIT17);
tmpMeta12 = omc_Interactive_propagateMod(threadData, omc_AbsynUtil_crefToPath(threadData, _inElementName), _inMod, mmc_mk_some(tmpMeta11));
if (optionNone(tmpMeta12)) goto goto_7;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 1));
_mod = tmpMeta13;
{
modelica_metatype tmp18_1;
tmp18_1 = _mod;
{
volatile mmc_switch_type tmp18;
int tmp19;
tmp18 = 0;
for (; tmp18 < 1; tmp18++) {
switch (MMC_SWITCH_CAST(tmp18)) {
case 0: {
tmpMeta15 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 2)));
goto tmp17_done;
}
}
goto tmp17_end;
tmp17_end: ;
}
goto goto_16;
goto_16:;
goto goto_7;
goto tmp17_done;
tmp17_done:;
}
}
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_body), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[4] = tmpMeta15;
_body = tmpMeta14;
tmpMeta6 = _body;
goto tmp8_done;
}
}
goto tmp8_end;
tmp8_end: ;
}
goto goto_7;
goto_7:;
goto goto_2;
goto tmp8_done;
tmp8_done:;
}
}
_body = tmpMeta6;
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_cls), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta20))[7] = _body;
_cls = tmpMeta20;
tmpMeta1 = _cls;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setSubmodifierInElementSpec(threadData_t *threadData, modelica_metatype _inElementName, modelica_metatype _inElSpec, modelica_metatype _inMod)
{
modelica_metatype _outElSpec = NULL;
modelica_metatype _elSpec = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elSpec = _inElSpec;
{
modelica_metatype tmp4_1;
tmp4_1 = _elSpec;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_elSpec), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[3] = omc_InteractiveUtil_setSubmodifierInClass(threadData, _inElementName, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elSpec), 3))), _inMod);
_elSpec = tmpMeta6;
tmpMeta1 = _elSpec;
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
_outElSpec = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElSpec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setSubmodifierInElement(threadData_t *threadData, modelica_metatype _inElement, modelica_boolean _inFound, modelica_metatype _inElementName, modelica_metatype _inMod, modelica_boolean *out_outFound, modelica_boolean *out_outContinue)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _outElement = NULL;
modelica_boolean _outFound;
modelica_boolean _outContinue;
modelica_metatype _args_old = NULL;
modelica_metatype _args_new = NULL;
modelica_metatype _eqmod_old = NULL;
modelica_metatype _eqmod_new = NULL;
modelica_string _el_id = NULL;
modelica_string _id = NULL;
modelica_metatype _el = NULL;
modelica_metatype _elSpec = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outElement = _inElement;
_id = _OMC_LIT14;
_el = _inElement;
_el_id = omc_AbsynUtil_crefFirstIdent(threadData, _inElementName);
_elSpec = omc_AbsynUtil_elementSpec(threadData, _inElement);
if(omc_AbsynUtil_isClassOrComponentElementSpec(threadData, _elSpec))
{
_id = omc_AbsynUtil_elementSpecName(threadData, _elSpec);
}
else
{
_outFound = 0;
_outContinue = 1;
goto _return;
}
if((stringEqual(_el_id, _id)))
{
{
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
{
modelica_metatype tmp8_1;
tmp8_1 = _el;
{
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
for (; tmp8 < 1; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,0,6) == 0) goto tmp7_end;
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_el), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[5] = omc_InteractiveUtil_setSubmodifierInElementSpec(threadData, _inElementName, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 5))), _inMod);
_el = tmpMeta10;
tmpMeta5 = _el;
goto tmp7_done;
}
}
goto tmp7_end;
tmp7_end: ;
}
goto goto_6;
goto_6:;
goto goto_1;
goto tmp7_done;
tmp7_done:;
}
}
_outElement = tmpMeta5;
_outFound = 1;
_outContinue = 0;
goto tmp2_done;
}
case 1: {
_outFound = 0;
_outContinue = 1;
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
}
else
{
_outFound = 0;
_outContinue = 1;
}
_return: OMC_LABEL_UNUSED
if (out_outFound) { *out_outFound = _outFound; }
if (out_outContinue) { *out_outContinue = _outContinue; }
threadData->mmc_jumper = old_mmc_jumper;
return _outElement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_setSubmodifierInElement(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inFound, modelica_metatype _inElementName, modelica_metatype _inMod, modelica_metatype *out_outFound, modelica_metatype *out_outContinue)
{
modelica_integer tmp1;
modelica_boolean _outFound;
modelica_boolean _outContinue;
modelica_metatype _outElement = NULL;
tmp1 = mmc_unbox_integer(_inFound);
_outElement = omc_InteractiveUtil_setSubmodifierInElement(threadData, _inElement, tmp1, _inElementName, _inMod, &_outFound, &_outContinue);
if (out_outFound) { *out_outFound = mmc_mk_icon(_outFound); }
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _outElement;
}
static modelica_metatype closure2_InteractiveUtil_setSubmodifierInElement(threadData_t *thData, modelica_metatype closure, modelica_metatype inElement, modelica_metatype inFound, modelica_metatype tmp7, modelica_metatype tmp8)
{
modelica_metatype inElementName = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype inMod = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_setSubmodifierInElement(thData, inElement, inFound, inElementName, inMod, tmp7, tmp8);
}static modelica_metatype closure3_Interactive_setComponentSubmodifierInCompitems(threadData_t *thData, modelica_metatype closure, modelica_metatype inComponents, modelica_metatype inFound, modelica_metatype tmp13, modelica_metatype tmp14)
{
modelica_metatype inComponentName = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype inMod = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_Interactive_setComponentSubmodifierInCompitems(thData, inComponents, inFound, inComponentName, inMod, tmp13, tmp14);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setElementSubmodifierInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inElementName, modelica_metatype _inMod)
{
modelica_metatype _outClass = NULL;
modelica_boolean _found;
modelica_metatype tmpMeta11;
modelica_integer tmp12;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClass = _inClass;
_found = 0;
{
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_integer tmp6;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta9 = mmc_mk_box2(0, _inElementName, _inMod);
tmpMeta10 = omc_AbsynUtil_traverseClassElements(threadData, _inClass, (modelica_fnptr) mmc_mk_box2(0,closure2_InteractiveUtil_setSubmodifierInElement,tmpMeta9), mmc_mk_boolean(0), &tmpMeta5);
_outClass = tmpMeta10;
tmp6 = mmc_unbox_integer(tmpMeta5);
_found = tmp6;
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
if((!_found))
{
tmpMeta15 = mmc_mk_box2(0, _inElementName, _inMod);
tmpMeta16 = omc_AbsynUtil_traverseClassComponents(threadData, _inClass, (modelica_fnptr) mmc_mk_box2(0,closure3_Interactive_setComponentSubmodifierInCompitems,tmpMeta15), mmc_mk_boolean(0), &tmpMeta11);
_outClass = tmpMeta16;
tmp12 = mmc_unbox_integer(tmpMeta11);
if (1 != tmp12) MMC_THROW_INTERNAL();
}
_return: OMC_LABEL_UNUSED
return _outClass;
}
DLLExport
modelica_metatype omc_InteractiveUtil_setElementModifier(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inElementName, modelica_metatype _inMod, modelica_metatype _inProgram, modelica_string *out_outResult)
{
modelica_metatype _outProgram = NULL;
modelica_string _outResult = NULL;
modelica_metatype _p_class = NULL;
modelica_metatype _within_ = NULL;
modelica_metatype _cls = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
_p_class = omc_AbsynUtil_crefToPath(threadData, _inClass);
_within_ = omc_InteractiveUtil_buildWithin(threadData, _p_class);
_cls = omc_InteractiveUtil_getPathedClassInProgram(threadData, _p_class, _inProgram, 0, 0);
_cls = omc_InteractiveUtil_setElementSubmodifierInClass(threadData, _cls, _inElementName, _inMod);
tmpMeta5 = mmc_mk_cons(_cls, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta6 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta5, _within_);
_outProgram = omc_InteractiveUtil_updateProgram(threadData, tmpMeta6, _inProgram, 0);
_outResult = _OMC_LIT172;
goto tmp2_done;
}
case 1: {
_outProgram = _inProgram;
_outResult = _OMC_LIT162;
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
if (out_outResult) { *out_outResult = _outResult; }
return _outProgram;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_stripModifiersKeepRedeclares(threadData_t *threadData, modelica_metatype _inMod)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inMod;
{
modelica_metatype _m = NULL;
modelica_metatype _ea = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta1 = mmc_mk_none();
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta17;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_ea = tmpMeta7;
{
modelica_metatype __omcQ_24tmpVar11;
modelica_metatype* tmp9;
modelica_metatype tmpMeta10;
modelica_metatype __omcQ_24tmpVar10;
modelica_integer tmp11;
modelica_metatype _e_loopVar = 0;
modelica_boolean tmp12 = 0;
modelica_metatype _e;
_e_loopVar = _ea;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar11 = tmpMeta10;
tmp9 = &__omcQ_24tmpVar11;
while(1) {
tmp11 = 1;
while (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
{
modelica_metatype tmp15_1;
tmp15_1 = _e;
{
volatile mmc_switch_type tmp15;
int tmp16;
tmp15 = 0;
for (; tmp15 < 2; tmp15++) {
switch (MMC_SWITCH_CAST(tmp15)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp15_1,1,6) == 0) goto tmp14_end;
tmp12 = 1;
goto tmp14_done;
}
case 1: {
tmp12 = 0;
goto tmp14_done;
}
}
goto tmp14_end;
tmp14_end: ;
}
goto goto_13;
goto_13:;
goto goto_2;
goto tmp14_done;
tmp14_done:;
}
}
if (tmp12) {
tmp11--;
break;
}
}
if (tmp11 == 0) {
__omcQ_24tmpVar10 = _e;
*tmp9 = mmc_mk_cons(__omcQ_24tmpVar10,0);
tmp9 = &MMC_CDR(*tmp9);
} else if (tmp11 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp9 = mmc_mk_nil();
tmpMeta8 = __omcQ_24tmpVar11;
}
_ea = tmpMeta8;
tmpMeta17 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _ea, _OMC_LIT17);
_m = tmpMeta17;
tmpMeta1 = mmc_mk_some(_m);
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
_outMod = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_clearComponentModifiersInCompitems(threadData_t *threadData, modelica_metatype _inComponents, modelica_boolean _inFound, modelica_string _inComponentName, modelica_boolean _keepRedeclares, modelica_boolean *out_outFound, modelica_boolean *out_outContinue)
{
modelica_metatype _outComponents = NULL;
modelica_metatype tmpMeta1;
modelica_boolean _outFound;
modelica_boolean _outContinue;
modelica_metatype _item = NULL;
modelica_metatype _rest_items = NULL;
modelica_metatype _comp = NULL;
modelica_metatype _args_old = NULL;
modelica_metatype _args_new = NULL;
modelica_metatype _eqmod_old = NULL;
modelica_metatype _eqmod_new = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outComponents = tmpMeta1;
_rest_items = _inComponents;
while(1)
{
if(!(!listEmpty(_rest_items))) break;
tmpMeta2 = _rest_items;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_item = tmpMeta3;
_rest_items = tmpMeta4;
if((stringEqual(omc_AbsynUtil_componentName(threadData, _item), _inComponentName)))
{
{
modelica_metatype tmp7_1;
tmp7_1 = _item;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 1; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
_comp = tmpMeta9;
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_comp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[4] = ((!_keepRedeclares)?mmc_mk_none():omc_InteractiveUtil_stripModifiersKeepRedeclares(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_comp), 4)))));
_comp = tmpMeta10;
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_item), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[2] = _comp;
_item = tmpMeta11;
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
}
;
tmpMeta12 = mmc_mk_cons(_item, _rest_items);
_outComponents = omc_List_append__reverse(threadData, _outComponents, tmpMeta12);
_outFound = 1;
_outContinue = 0;
goto _return;
}
tmpMeta13 = mmc_mk_cons(_item, _outComponents);
_outComponents = tmpMeta13;
}
_outComponents = _inComponents;
_outFound = 0;
_outContinue = 1;
_return: OMC_LABEL_UNUSED
if (out_outFound) { *out_outFound = _outFound; }
if (out_outContinue) { *out_outContinue = _outContinue; }
return _outComponents;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_clearComponentModifiersInCompitems(threadData_t *threadData, modelica_metatype _inComponents, modelica_metatype _inFound, modelica_metatype _inComponentName, modelica_metatype _keepRedeclares, modelica_metatype *out_outFound, modelica_metatype *out_outContinue)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_boolean _outFound;
modelica_boolean _outContinue;
modelica_metatype _outComponents = NULL;
modelica_metatype tmpMeta3;
tmp1 = mmc_unbox_integer(_inFound);
tmp2 = mmc_unbox_integer(_keepRedeclares);
_outComponents = omc_InteractiveUtil_clearComponentModifiersInCompitems(threadData, _inComponents, tmp1, _inComponentName, tmp2, &_outFound, &_outContinue);
if (out_outFound) { *out_outFound = mmc_mk_icon(_outFound); }
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _outComponents;
}
static modelica_metatype closure4_InteractiveUtil_clearComponentModifiersInCompitems(threadData_t *thData, modelica_metatype closure, modelica_metatype inComponents, modelica_metatype inFound, modelica_metatype tmp3, modelica_metatype tmp4)
{
modelica_string inComponentName = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype keepRedeclares = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_clearComponentModifiersInCompitems(thData, inComponents, inFound, inComponentName, keepRedeclares, tmp3, tmp4);
}
DLLExport
modelica_metatype omc_InteractiveUtil_clearComponentModifiersInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_string _inComponentName, modelica_boolean _keepRedeclares)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta1;
modelica_integer tmp2;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClass = _inClass;
tmpMeta5 = mmc_mk_box2(0, _inComponentName, mmc_mk_boolean(_keepRedeclares));
tmpMeta6 = omc_AbsynUtil_traverseClassComponents(threadData, _inClass, (modelica_fnptr) mmc_mk_box2(0,closure4_InteractiveUtil_clearComponentModifiersInCompitems,tmpMeta5), mmc_mk_boolean(0), &tmpMeta1);
_outClass = tmpMeta6;
tmp2 = mmc_unbox_integer(tmpMeta1);
if (1 != tmp2) MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return _outClass;
}
modelica_metatype boxptr_InteractiveUtil_clearComponentModifiersInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inComponentName, modelica_metatype _keepRedeclares)
{
modelica_integer tmp1;
modelica_metatype _outClass = NULL;
tmp1 = mmc_unbox_integer(_keepRedeclares);
_outClass = omc_InteractiveUtil_clearComponentModifiersInClass(threadData, _inClass, _inComponentName, tmp1);
return _outClass;
}
DLLExport
modelica_metatype omc_InteractiveUtil_removeElementModifiers(threadData_t *threadData, modelica_metatype _path, modelica_string _inComponentName, modelica_metatype _inProgram, modelica_boolean _keepRedeclares, modelica_boolean *out_outResult)
{
modelica_metatype _outProgram = NULL;
modelica_boolean _outResult;
modelica_metatype _within_ = NULL;
modelica_metatype _cls = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
_within_ = omc_InteractiveUtil_buildWithin(threadData, _path);
_cls = omc_InteractiveUtil_getPathedClassInProgram(threadData, _path, _inProgram, 0, 0);
_cls = omc_InteractiveUtil_clearComponentModifiersInClass(threadData, _cls, _inComponentName, _keepRedeclares);
tmpMeta5 = mmc_mk_cons(_cls, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta6 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta5, _within_);
_outProgram = omc_InteractiveUtil_updateProgram(threadData, tmpMeta6, _inProgram, 0);
_outResult = 1;
goto tmp2_done;
}
case 1: {
_outProgram = _inProgram;
_outResult = 0;
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
if (out_outResult) { *out_outResult = _outResult; }
return _outProgram;
}
modelica_metatype boxptr_InteractiveUtil_removeElementModifiers(threadData_t *threadData, modelica_metatype _path, modelica_metatype _inComponentName, modelica_metatype _inProgram, modelica_metatype _keepRedeclares, modelica_metatype *out_outResult)
{
modelica_integer tmp1;
modelica_boolean _outResult;
modelica_metatype _outProgram = NULL;
tmp1 = mmc_unbox_integer(_keepRedeclares);
_outProgram = omc_InteractiveUtil_removeElementModifiers(threadData, _path, _inComponentName, _inProgram, tmp1, &_outResult);
if (out_outResult) { *out_outResult = mmc_mk_icon(_outResult); }
return _outProgram;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getExtendsElementspecInElement(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outElementSpec = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_metatype _ext = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,3) == 0) goto tmp3_end;
_ext = tmpMeta6;
tmpMeta1 = _ext;
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
_outElementSpec = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElementSpec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getExtendsElementspecInElementitems(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst)
{
modelica_metatype _outAbsynElementSpecLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inAbsynElementItemLst;
{
modelica_metatype _el = NULL;
modelica_metatype _elt = NULL;
modelica_metatype _res = NULL;
modelica_metatype _rest = NULL;
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
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_el = tmpMeta9;
_rest = tmpMeta8;
_elt = omc_InteractiveUtil_getExtendsElementspecInElement(threadData, _el);
_res = omc_InteractiveUtil_getExtendsElementspecInElementitems(threadData, _rest);
tmpMeta10 = mmc_mk_cons(_elt, _res);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmp4_1);
tmpMeta12 = MMC_CDR(tmp4_1);
_rest = tmpMeta12;
tmpMeta1 = omc_InteractiveUtil_getExtendsElementspecInElementitems(threadData, _rest);
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
_outAbsynElementSpecLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynElementSpecLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getExtendsElementspecInClassparts(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAbsynElementSpecLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _lst1 = NULL;
modelica_metatype _lst2 = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _rest = NULL;
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
tmp4 += 1;
_lst1 = omc_InteractiveUtil_getExtendsElementspecInClassparts(threadData, _rest);
_lst2 = omc_InteractiveUtil_getExtendsElementspecInElementitems(threadData, _elts);
tmpMeta1 = listAppend(_lst1, _lst2);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_elts = tmpMeta12;
_rest = tmpMeta11;
_lst1 = omc_InteractiveUtil_getExtendsElementspecInClassparts(threadData, _rest);
_lst2 = omc_InteractiveUtil_getExtendsElementspecInElementitems(threadData, _elts);
tmpMeta1 = listAppend(_lst1, _lst2);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
_rest = tmpMeta14;
tmpMeta1 = omc_InteractiveUtil_getExtendsElementspecInClassparts(threadData, _rest);
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
_outAbsynElementSpecLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynElementSpecLst;
}
DLLExport
modelica_metatype omc_InteractiveUtil_getExtendsElementspecInClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _outAbsynElementSpecLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_metatype _parts = NULL;
modelica_metatype _eltArg = NULL;
modelica_metatype _tp = NULL;
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
tmp4 += 2;
tmpMeta1 = omc_InteractiveUtil_getExtendsElementspecInClassparts(threadData, _parts);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
_parts = tmpMeta9;
tmp4 += 1;
tmpMeta1 = omc_InteractiveUtil_getExtendsElementspecInClassparts(threadData, _parts);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,4) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 4));
_tp = tmpMeta12;
_eltArg = tmpMeta13;
tmpMeta15 = mmc_mk_box4(4, &Absyn_ElementSpec_EXTENDS__desc, _tp, _eltArg, mmc_mk_none());
tmpMeta14 = mmc_mk_cons(tmpMeta15, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta16;
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
_outAbsynElementSpecLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynElementSpecLst;
}
