#include "omc_simulation_settings.h"
#include "InteractiveUtil.h"
#define _OMC_LIT0_data "origin"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,6,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "Diagram"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,7,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "graphics"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,8,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,3,3) {&Absyn_Path_QUALIFIED__desc,_OMC_LIT1,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "Line"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,4,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "points"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,6,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT6}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,3,3) {&Absyn_Path_QUALIFIED__desc,_OMC_LIT5,_OMC_LIT7}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,1,3) {&Absyn_Operator_ADD__desc,}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,1,4) {&Absyn_Operator_SUB__desc,}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,1,3) {&Absyn_EqMod_NOMOD__desc,}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,3,3) {&Absyn_Modification_CLASSMOD__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT11}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,0,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT14,0.0);
#define _OMC_LIT14 MMC_REFREALLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT13,MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT14}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT0}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "Placement"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,9,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "iconTransformation"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,18,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,3,3) {&Absyn_Path_QUALIFIED__desc,_OMC_LIT17,_OMC_LIT19}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,2,3) {&Absyn_Annotation_ANNOTATION__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "transformation"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,14,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,3,3) {&Absyn_Path_QUALIFIED__desc,_OMC_LIT22,_OMC_LIT16}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,3,3) {&Absyn_Path_QUALIFIED__desc,_OMC_LIT17,_OMC_LIT23}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,1,4) {&Absyn_Within_TOP__desc,}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "__OpenModelica_TopLevel"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,23,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,1,8) {&ErrorTypes_MessageType_SCRIPTING__desc,}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,1,6) {&ErrorTypes_Severity_NOTIFICATION__desc,}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "Cannot access encrypted and protected class contents."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,53,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(7023)),_OMC_LIT27,_OMC_LIT28,_OMC_LIT29}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data "nfAPINoise"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,10,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "Enables error display for the experimental new instantiation use in the OMC API."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,80,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(172)),_OMC_LIT31,MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */)),_OMC_LIT32}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data "InteractiveUtil.accessClass"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,27,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "InteractiveUtil.getInheritedAnnotation"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,38,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "Conflicting '%s' annotations inherited by class '%s':\n  %s from 'extends %s'\n  %s from 'extends %s'"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,99,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(414)),_OMC_LIT27,_OMC_LIT36,_OMC_LIT37}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,1,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "model dummy\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,12,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "end dummy;\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,11,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "<interactive>"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,13,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "std"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,3,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,1,4) {&Flags_FlagVisibility_EXTERNAL__desc,}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
#define _OMC_LIT45_data "1.x"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT45,3,_OMC_LIT45_data);
#define _OMC_LIT45 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,2,0) {_OMC_LIT45,MMC_IMMEDIATE(MMC_TAGFIXNUM(10))}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "2.x"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,3,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,2,0) {_OMC_LIT47,MMC_IMMEDIATE(MMC_TAGFIXNUM(20))}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
#define _OMC_LIT49_data "3.0"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT49,3,_OMC_LIT49_data);
#define _OMC_LIT49 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,2,0) {_OMC_LIT49,MMC_IMMEDIATE(MMC_TAGFIXNUM(30))}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
#define _OMC_LIT51_data "3.1"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT51,3,_OMC_LIT51_data);
#define _OMC_LIT51 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,2,0) {_OMC_LIT51,MMC_IMMEDIATE(MMC_TAGFIXNUM(31))}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "3.2"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,3,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,2,0) {_OMC_LIT53,MMC_IMMEDIATE(MMC_TAGFIXNUM(32))}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "3.3"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,3,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,2,0) {_OMC_LIT55,MMC_IMMEDIATE(MMC_TAGFIXNUM(33))}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "3.4"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,3,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT58,2,0) {_OMC_LIT57,MMC_IMMEDIATE(MMC_TAGFIXNUM(34))}};
#define _OMC_LIT58 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "3.5"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,3,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT60,2,0) {_OMC_LIT59,MMC_IMMEDIATE(MMC_TAGFIXNUM(35))}};
#define _OMC_LIT60 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "3.6"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,3,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT62,2,0) {_OMC_LIT61,MMC_IMMEDIATE(MMC_TAGFIXNUM(36))}};
#define _OMC_LIT62 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "latest"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,6,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT64,2,0) {_OMC_LIT63,MMC_IMMEDIATE(MMC_TAGFIXNUM(1000))}};
#define _OMC_LIT64 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT64)
#define _OMC_LIT65_data "experimental"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT65,12,_OMC_LIT65_data);
#define _OMC_LIT65 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT65)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT66,2,0) {_OMC_LIT65,MMC_IMMEDIATE(MMC_TAGFIXNUM(9999))}};
#define _OMC_LIT66 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT66)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT67,2,1) {_OMC_LIT66,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT67 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT67)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT68,2,1) {_OMC_LIT64,_OMC_LIT67}};
#define _OMC_LIT68 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT68)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT69,2,1) {_OMC_LIT62,_OMC_LIT68}};
#define _OMC_LIT69 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT69)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT70,2,1) {_OMC_LIT60,_OMC_LIT69}};
#define _OMC_LIT70 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT70)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT71,2,1) {_OMC_LIT58,_OMC_LIT70}};
#define _OMC_LIT71 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT71)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT72,2,1) {_OMC_LIT56,_OMC_LIT71}};
#define _OMC_LIT72 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT72)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT73,2,1) {_OMC_LIT54,_OMC_LIT72}};
#define _OMC_LIT73 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT73)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT74,2,1) {_OMC_LIT52,_OMC_LIT73}};
#define _OMC_LIT74 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT74)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT75,2,1) {_OMC_LIT50,_OMC_LIT74}};
#define _OMC_LIT75 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT75)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT76,2,1) {_OMC_LIT48,_OMC_LIT75}};
#define _OMC_LIT76 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT76)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT77,2,1) {_OMC_LIT46,_OMC_LIT76}};
#define _OMC_LIT77 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT77)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT78,3,10) {&Flags_FlagData_ENUM__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1000)),_OMC_LIT77}};
#define _OMC_LIT78 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT78)
#define _OMC_LIT79_data "Sets the language standard that should be used."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT79,47,_OMC_LIT79_data);
#define _OMC_LIT79 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT79)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT80,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(8)),_OMC_LIT43,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT44,_OMC_LIT78,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT79}};
#define _OMC_LIT80 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data "strict"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,6,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT82,2,4) {&Flags_FlagData_BOOL__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0 /* false */))}};
#define _OMC_LIT82 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT82)
#define _OMC_LIT83_data "Enables stricter enforcement of Modelica language rules."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT83,56,_OMC_LIT83_data);
#define _OMC_LIT83 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT83)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT84,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(43)),_OMC_LIT81,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT44,_OMC_LIT82,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT83}};
#define _OMC_LIT84 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT84)
#define _OMC_LIT85_data "()"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT85,2,_OMC_LIT85_data);
#define _OMC_LIT85 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT85)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT86,1,24) {&Absyn_Restriction_R__UNKNOWN__desc,}};
#define _OMC_LIT86 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT86)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT87,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT87 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT87)
#define _OMC_LIT88_data "Class %s not found inside class %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT88,35,_OMC_LIT88_data);
#define _OMC_LIT88 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT88)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT89,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(555)),_OMC_LIT27,_OMC_LIT36,_OMC_LIT88}};
#define _OMC_LIT89 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT89)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT90,1,4) {&Absyn_Each_NON__EACH__desc,}};
#define _OMC_LIT90 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT90)
#define _OMC_LIT91_data "- InteractiveUtil.namedargToModification failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT91,48,_OMC_LIT91_data);
#define _OMC_LIT91 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT91)
#define _OMC_LIT92_data "InteractiveUtil.recordConstructorToModification failed, exp="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT92,60,_OMC_LIT92_data);
#define _OMC_LIT92 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT92)
#define _OMC_LIT93_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT93,1,_OMC_LIT93_data);
#define _OMC_LIT93 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT93)
#define _OMC_LIT94_data "annotate"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT94,8,_OMC_LIT94_data);
#define _OMC_LIT94 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT94)
#define _OMC_LIT95_data "comment"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT95,7,_OMC_LIT95_data);
#define _OMC_LIT95 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT95)
#define _OMC_LIT96_data "input"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT96,5,_OMC_LIT96_data);
#define _OMC_LIT96 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT96)
#define _OMC_LIT97_data "output"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT97,6,_OMC_LIT97_data);
#define _OMC_LIT97 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT97)
#define _OMC_LIT98_data "unspecified"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT98,11,_OMC_LIT98_data);
#define _OMC_LIT98 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT98)
#define _OMC_LIT99_data "discrete"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT99,8,_OMC_LIT99_data);
#define _OMC_LIT99 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT99)
#define _OMC_LIT100_data "parameter"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT100,9,_OMC_LIT100_data);
#define _OMC_LIT100 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT100)
#define _OMC_LIT101_data "constant"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT101,8,_OMC_LIT101_data);
#define _OMC_LIT101 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT101)
#define _OMC_LIT102_data "parglobal"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT102,9,_OMC_LIT102_data);
#define _OMC_LIT102 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT102)
#define _OMC_LIT103_data "parlocal"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT103,8,_OMC_LIT103_data);
#define _OMC_LIT103 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT103)
#define _OMC_LIT104_data "true"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT104,4,_OMC_LIT104_data);
#define _OMC_LIT104 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT104)
#define _OMC_LIT105_data "false"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT105,5,_OMC_LIT105_data);
#define _OMC_LIT105 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT105)
#define _OMC_LIT106_data "inner"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT106,5,_OMC_LIT106_data);
#define _OMC_LIT106 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT106)
#define _OMC_LIT107_data "outer"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT107,5,_OMC_LIT107_data);
#define _OMC_LIT107 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT107)
#define _OMC_LIT108_data "none"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT108,4,_OMC_LIT108_data);
#define _OMC_LIT108 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT108)
#define _OMC_LIT109_data "innerouter"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT109,10,_OMC_LIT109_data);
#define _OMC_LIT109 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT109)
#define _OMC_LIT110_data "$Any"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT110,4,_OMC_LIT110_data);
#define _OMC_LIT110 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT110)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT111,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT110}};
#define _OMC_LIT111 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT111)
#define _OMC_LIT112_data "nfAPI"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT112,5,_OMC_LIT112_data);
#define _OMC_LIT112 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT112)
#define _OMC_LIT113_data "Enables experimental new instantiation use in the OMC API."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT113,58,_OMC_LIT113_data);
#define _OMC_LIT113 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT113)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT114,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(170)),_OMC_LIT112,MMC_IMMEDIATE(MMC_TAGFIXNUM(1 /* true */)),_OMC_LIT113}};
#define _OMC_LIT114 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT114)
#define _OMC_LIT115_data "Real"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT115,4,_OMC_LIT115_data);
#define _OMC_LIT115 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT115)
#define _OMC_LIT116_data "Integer"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT116,7,_OMC_LIT116_data);
#define _OMC_LIT116 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT116)
#define _OMC_LIT117_data "Boolean"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT117,7,_OMC_LIT117_data);
#define _OMC_LIT117 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT117)
#define _OMC_LIT118_data "String"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT118,6,_OMC_LIT118_data);
#define _OMC_LIT118 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT118)
#define _OMC_LIT119_data "public"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT119,6,_OMC_LIT119_data);
#define _OMC_LIT119 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT119)
#define _OMC_LIT120_data "protected"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT120,9,_OMC_LIT120_data);
#define _OMC_LIT120 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT120)
#define _OMC_LIT121_data "co"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT121,2,_OMC_LIT121_data);
#define _OMC_LIT121 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT121)
#define _OMC_LIT122_data "-"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT122,1,_OMC_LIT122_data);
#define _OMC_LIT122 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT122)
#define _OMC_LIT123_data "cl"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT123,2,_OMC_LIT123_data);
#define _OMC_LIT123 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT123)
#define _OMC_LIT124_data "checkModel"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT124,10,_OMC_LIT124_data);
#define _OMC_LIT124 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT124)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT125,1,3) {&Flags_FlagVisibility_INTERNAL__desc,}};
#define _OMC_LIT125 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT125)
#define _OMC_LIT126_data "Set when checkModel is used to turn on specific features for checking."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT126,70,_OMC_LIT126_data);
#define _OMC_LIT126 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT126)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT127,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(28)),_OMC_LIT124,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT125,_OMC_LIT82,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT126}};
#define _OMC_LIT127 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT127)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT128,3,3) {&Absyn_Program_PROGRAM__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT25}};
#define _OMC_LIT128 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT128)
#define _OMC_LIT129_data "/lib/omc/AnnotationsBuiltin_"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT129,28,_OMC_LIT129_data);
#define _OMC_LIT129 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT129)
#define _OMC_LIT130_data "_"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT130,1,_OMC_LIT130_data);
#define _OMC_LIT130 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT130)
#define _OMC_LIT131_data ".mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT131,3,_OMC_LIT131_data);
#define _OMC_LIT131 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT131)
#define _OMC_LIT132_data "UTF-8"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT132,5,_OMC_LIT132_data);
#define _OMC_LIT132 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT132)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT133,1,3) {&DAE_Prefix_NOPRE__desc,}};
#define _OMC_LIT133 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT133)
#define _OMC_LIT134_data "="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT134,1,_OMC_LIT134_data);
#define _OMC_LIT134 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT134)
#define _OMC_LIT135_data "Icon"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT135,4,_OMC_LIT135_data);
#define _OMC_LIT135 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT135)
#define _OMC_LIT136_data "choices"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT136,7,_OMC_LIT136_data);
#define _OMC_LIT136 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT136)
#define _OMC_LIT137_data "buildEnvForGraphicProgram"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT137,25,_OMC_LIT137_data);
#define _OMC_LIT137 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT137)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT138,1,4) {&SCode_Final_NOT__FINAL__desc,}};
#define _OMC_LIT138 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT138)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT139,1,4) {&SCode_Each_NOT__EACH__desc,}};
#define _OMC_LIT139 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT139)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT140,1,4) {&UnitAbsyn_InstStore_NOSTORE__desc,}};
#define _OMC_LIT140 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT140)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT141,1,3) {&InstTypes_CallingScope_TOP__CALL__desc,}};
#define _OMC_LIT141 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT141)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT142,7,3) {&ConnectionGraph_ConnectionGraph_GRAPH__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1 /* true */)),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT142 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT142)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT143,1,6) {&DAE_ComponentRef_WILD__desc,}};
#define _OMC_LIT143 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT143)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT144,5,3) {&DAE_Connect_SetTrieNode_SET__TRIE__NODE__desc,_OMC_LIT13,_OMC_LIT143,MMC_REFSTRUCTLIT(mmc_nil),MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT144 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT144)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT145,5,3) {&DAE_Connect_Sets_SETS__desc,_OMC_LIT144,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT145 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT145)
#define _OMC_LIT146_data "getAnnotationString: Icon"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT146,25,_OMC_LIT146_data);
#define _OMC_LIT146 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT146)
#define _OMC_LIT147_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT147,1,_OMC_LIT147_data);
#define _OMC_LIT147 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT147)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT148,1,4) {&SCode_Partial_NOT__PARTIAL__desc,}};
#define _OMC_LIT148 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT148)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT149,2,1) {_OMC_LIT136,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT149 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT149)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT150,2,1) {_OMC_LIT1,_OMC_LIT149}};
#define _OMC_LIT150 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT150)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT151,2,1) {_OMC_LIT135,_OMC_LIT150}};
#define _OMC_LIT151 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT151)
#define _OMC_LIT152_data "("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT152,1,_OMC_LIT152_data);
#define _OMC_LIT152 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT152)
#define _OMC_LIT153_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT153,1,_OMC_LIT153_data);
#define _OMC_LIT153 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT153)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT154,1,5) {&DAE_Mod_NOMOD__desc,}};
#define _OMC_LIT154 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT154)
#define _OMC_LIT155_data "error evaluating: annotation("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT155,29,_OMC_LIT155_data);
#define _OMC_LIT155 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT155)
#define _OMC_LIT156_data "(\""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT156,2,_OMC_LIT156_data);
#define _OMC_LIT156 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT156)
#define _OMC_LIT157_data "\")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT157,2,_OMC_LIT157_data);
#define _OMC_LIT157 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT157)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT158,2,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT158 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT158)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT159,3,8) {&Values_Value_ARRAY__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT158}};
#define _OMC_LIT159 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT159)
#define _OMC_LIT160_data "empty"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT160,5,_OMC_LIT160_data);
#define _OMC_LIT160 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT160)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT161,2,4) {&FCore_Graph_EG__desc,_OMC_LIT160}};
#define _OMC_LIT161 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT161)
#define _OMC_LIT162_data "permissive"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT162,10,_OMC_LIT162_data);
#define _OMC_LIT162 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT162)
#define _OMC_LIT163_data "Disables some error checks to allow erroneous models to compile."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT163,64,_OMC_LIT163_data);
#define _OMC_LIT163 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT163)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT164,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(77)),_OMC_LIT162,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT125,_OMC_LIT82,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT163}};
#define _OMC_LIT164 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT164)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT165,1,3) {&SCode_Visibility_PUBLIC__desc,}};
#define _OMC_LIT165 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT165)
#define _OMC_LIT166_data "InteractiveUtil.getExtendsModifierNames"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT166,39,_OMC_LIT166_data);
#define _OMC_LIT166 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT166)
#define _OMC_LIT167_data "Error"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT167,5,_OMC_LIT167_data);
#define _OMC_LIT167 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT167)
#define _OMC_LIT168_data "dummy"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT168,5,_OMC_LIT168_data);
#define _OMC_LIT168 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT168)
#include "util/modelica.h"
#include "InteractiveUtil_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_offsetGraphicsItemExpression_offset__named__origin(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_integer _x, modelica_integer _y, modelica_boolean *out_found);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_offsetGraphicsItemExpression_offset__named__origin(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_metatype _x, modelica_metatype _y, modelica_metatype *out_found);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_offsetGraphicsItemExpression_offset__named__origin,2,0) {(void*) boxptr_InteractiveUtil_offsetGraphicsItemExpression_offset__named__origin,0}};
#define boxvar_InteractiveUtil_offsetGraphicsItemExpression_offset__named__origin MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_offsetGraphicsItemExpression_offset__named__origin)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_offsetIconTransformationAnnotation_impl(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_integer _x, modelica_integer _y);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_offsetIconTransformationAnnotation_impl(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_metatype _x, modelica_metatype _y);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_offsetIconTransformationAnnotation_impl,2,0) {(void*) boxptr_InteractiveUtil_offsetIconTransformationAnnotation_impl,0}};
#define boxvar_InteractiveUtil_offsetIconTransformationAnnotation_impl MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_offsetIconTransformationAnnotation_impl)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInComponent(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomponent, modelica_metatype _nameMap, modelica_boolean _renameElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_renameElementsInComponent(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomponent, modelica_metatype _nameMap, modelica_metatype _renameElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInComponent,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInComponent,0}};
#define boxvar_InteractiveUtil_renameElementsInComponent MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInComponent)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInComponentItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomponent, modelica_metatype _nameMap, modelica_boolean _renameElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_renameElementsInComponentItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomponent, modelica_metatype _nameMap, modelica_metatype _renameElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInComponentItem,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInComponentItem,0}};
#define boxvar_InteractiveUtil_renameElementsInComponentItem MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInComponentItem)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAttributes(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fattrs, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAttributes,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInAttributes,0}};
#define boxvar_InteractiveUtil_renameElementsInAttributes MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAttributes)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInTypeSpec(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fspec, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInTypeSpec,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInTypeSpec,0}};
#define boxvar_InteractiveUtil_renameElementsInTypeSpec MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInTypeSpec)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInExternalDecl(threadData_t *threadData, modelica_metatype __omcQ_24in_5FextDecl, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInExternalDecl,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInExternalDecl,0}};
#define boxvar_InteractiveUtil_renameElementsInExternalDecl MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInExternalDecl)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInSubscript(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsub, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInSubscript,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInSubscript,0}};
#define boxvar_InteractiveUtil_renameElementsInSubscript MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInSubscript)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInSubscripts(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsubs, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInSubscripts,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInSubscripts,0}};
#define boxvar_InteractiveUtil_renameElementsInSubscripts MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInSubscripts)
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_renameElementsInIdent(threadData_t *threadData, modelica_string __omcQ_24in_5Fident, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInIdent,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInIdent,0}};
#define boxvar_InteractiveUtil_renameElementsInIdent MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInIdent)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInPath(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpath, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInPath,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInPath,0}};
#define boxvar_InteractiveUtil_renameElementsInPath MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInPath)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInCref(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcref, modelica_metatype _nameMap, modelica_boolean _onlySubs);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_renameElementsInCref(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcref, modelica_metatype _nameMap, modelica_metatype _onlySubs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInCref,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInCref,0}};
#define boxvar_InteractiveUtil_renameElementsInCref MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInExp(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5FnameMap, modelica_metatype *out_nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInExp,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInExp,0}};
#define boxvar_InteractiveUtil_renameElementsInExp MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInEqMod(threadData_t *threadData, modelica_metatype __omcQ_24in_5FeqMod, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInEqMod,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInEqMod,0}};
#define boxvar_InteractiveUtil_renameElementsInEqMod MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInEqMod)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInModification(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fmod, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInModification,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInModification,0}};
#define boxvar_InteractiveUtil_renameElementsInModification MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInModification)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInModificationOpt(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fmod, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInModificationOpt,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInModificationOpt,0}};
#define boxvar_InteractiveUtil_renameElementsInModificationOpt MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInModificationOpt)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fann, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAnnotation,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInAnnotation,0}};
#define boxvar_InteractiveUtil_renameElementsInAnnotation MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAnnotation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAnnotationOpt(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fann, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAnnotationOpt,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInAnnotationOpt,0}};
#define boxvar_InteractiveUtil_renameElementsInAnnotationOpt MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAnnotationOpt)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInComment(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomment, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInComment,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInComment,0}};
#define boxvar_InteractiveUtil_renameElementsInComment MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInComment)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInCommentOpt(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomment, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInCommentOpt,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInCommentOpt,0}};
#define boxvar_InteractiveUtil_renameElementsInCommentOpt MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInCommentOpt)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInConstrainClass(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcc, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInConstrainClass,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInConstrainClass,0}};
#define boxvar_InteractiveUtil_renameElementsInConstrainClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInConstrainClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInConstrainClassOpt(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcc, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInConstrainClassOpt,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInConstrainClassOpt,0}};
#define boxvar_InteractiveUtil_renameElementsInConstrainClassOpt MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInConstrainClassOpt)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInElementArg(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInElementArg,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInElementArg,0}};
#define boxvar_InteractiveUtil_renameElementsInElementArg MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInElementArg)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAlgorithmBranch(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fbranch, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAlgorithmBranch,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInAlgorithmBranch,0}};
#define boxvar_InteractiveUtil_renameElementsInAlgorithmBranch MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAlgorithmBranch)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAlgorithm(threadData_t *threadData, modelica_metatype __omcQ_24in_5Falg, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAlgorithm,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInAlgorithm,0}};
#define boxvar_InteractiveUtil_renameElementsInAlgorithm MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAlgorithm)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAlgorithmItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAlgorithmItem,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInAlgorithmItem,0}};
#define boxvar_InteractiveUtil_renameElementsInAlgorithmItem MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAlgorithmItem)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAlgorithmItems(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitems, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAlgorithmItems,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInAlgorithmItems,0}};
#define boxvar_InteractiveUtil_renameElementsInAlgorithmItems MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInAlgorithmItems)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInIterator(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fiter, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInIterator,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInIterator,0}};
#define boxvar_InteractiveUtil_renameElementsInIterator MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInIterator)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInEquationBranch(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fbranch, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInEquationBranch,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInEquationBranch,0}};
#define boxvar_InteractiveUtil_renameElementsInEquationBranch MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInEquationBranch)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInEquation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Feq, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInEquation,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInEquation,0}};
#define boxvar_InteractiveUtil_renameElementsInEquation MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInEquation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInEquationItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInEquationItem,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInEquationItem,0}};
#define boxvar_InteractiveUtil_renameElementsInEquationItem MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInEquationItem)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInEquationItems(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitems, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInEquationItems,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInEquationItems,0}};
#define boxvar_InteractiveUtil_renameElementsInEquationItems MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInEquationItems)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInElementItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInElementItem,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInElementItem,0}};
#define boxvar_InteractiveUtil_renameElementsInElementItem MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInElementItem)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInClassPart(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpart, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInClassPart,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInClassPart,0}};
#define boxvar_InteractiveUtil_renameElementsInClassPart MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInClassPart)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInClassDef(threadData_t *threadData, modelica_metatype __omcQ_24in_5FclassDef, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInClassDef,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInClassDef,0}};
#define boxvar_InteractiveUtil_renameElementsInClassDef MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInClassDef)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInClass(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype _nameMap, modelica_boolean _renameElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_renameElementsInClass(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype _nameMap, modelica_metatype _renameElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInClass,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInClass,0}};
#define boxvar_InteractiveUtil_renameElementsInClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInElementSpec(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fspec, modelica_metatype _nameMap, modelica_boolean _renameElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_renameElementsInElementSpec(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fspec, modelica_metatype _nameMap, modelica_metatype _renameElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInElementSpec,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInElementSpec,0}};
#define boxvar_InteractiveUtil_renameElementsInElementSpec MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInElementSpec)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _nameMap);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInElement,2,0) {(void*) boxptr_InteractiveUtil_renameElementsInElement,0}};
#define boxvar_InteractiveUtil_renameElementsInElement MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_renameElementsInElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_resolveMergeContentsConflicts(threadData_t *threadData, modelica_metatype _oldElement, modelica_metatype __omcQ_24in_5FnewContent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_resolveMergeContentsConflicts,2,0) {(void*) boxptr_InteractiveUtil_resolveMergeContentsConflicts,0}};
#define boxvar_InteractiveUtil_resolveMergeContentsConflicts MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_resolveMergeContentsConflicts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_mergeAnnotationLists(threadData_t *threadData, modelica_metatype _newAnnotations, modelica_metatype _oldAnnotations);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_mergeAnnotationLists,2,0) {(void*) boxptr_InteractiveUtil_mergeAnnotationLists,0}};
#define boxvar_InteractiveUtil_mergeAnnotationLists MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_mergeAnnotationLists)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_mergeClassParts(threadData_t *threadData, modelica_metatype _newParts, modelica_metatype _oldParts);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_mergeClassParts,2,0) {(void*) boxptr_InteractiveUtil_mergeClassParts,0}};
#define boxvar_InteractiveUtil_mergeClassParts MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_mergeClassParts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInElementSpec(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fspec, modelica_metatype *out_element, modelica_boolean *out_success);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInElementSpec(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fspec, modelica_metatype *out_element, modelica_metatype *out_success);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInElementSpec,2,0) {(void*) boxptr_InteractiveUtil_transformPathedElementInElementSpec,0}};
#define boxvar_InteractiveUtil_transformPathedElementInElementSpec MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInElementSpec)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInElement(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Felement, modelica_metatype *out_outElement, modelica_boolean *out_success);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInElement(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Felement, modelica_metatype *out_outElement, modelica_metatype *out_success);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInElement,2,0) {(void*) boxptr_InteractiveUtil_transformPathedElementInElement,0}};
#define boxvar_InteractiveUtil_transformPathedElementInElement MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInElementItem(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype *out_outElement, modelica_boolean *out_success);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInElementItem(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype *out_outElement, modelica_metatype *out_success);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInElementItem,2,0) {(void*) boxptr_InteractiveUtil_transformPathedElementInElementItem,0}};
#define boxvar_InteractiveUtil_transformPathedElementInElementItem MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInElementItem)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInClassPart(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fpart, modelica_metatype *out_element, modelica_boolean *out_success);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInClassPart(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fpart, modelica_metatype *out_element, modelica_metatype *out_success);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInClassPart,2,0) {(void*) boxptr_InteractiveUtil_transformPathedElementInClassPart,0}};
#define boxvar_InteractiveUtil_transformPathedElementInClassPart MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInClassPart)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInClassDef(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fdef, modelica_metatype *out_element, modelica_boolean *out_success);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInClassDef(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fdef, modelica_metatype *out_element, modelica_metatype *out_success);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInClassDef,2,0) {(void*) boxptr_InteractiveUtil_transformPathedElementInClassDef,0}};
#define boxvar_InteractiveUtil_transformPathedElementInClassDef MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInClassDef)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInClass(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype *out_element, modelica_boolean *out_success);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInClass(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype *out_element, modelica_metatype *out_success);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInClass,2,0) {(void*) boxptr_InteractiveUtil_transformPathedElementInClass,0}};
#define boxvar_InteractiveUtil_transformPathedElementInClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInProgram_transform__class(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype *out_outElement, modelica_boolean *out_found);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInProgram_transform__class(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype *out_outElement, modelica_metatype *out_found);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInProgram_transform__class,2,0) {(void*) boxptr_InteractiveUtil_transformPathedElementInProgram_transform__class,0}};
#define boxvar_InteractiveUtil_transformPathedElementInProgram_transform__class MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_transformPathedElementInProgram_transform__class)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getPathedElementInElement(threadData_t *threadData, modelica_metatype _path, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getPathedElementInElement,2,0) {(void*) boxptr_InteractiveUtil_getPathedElementInElement,0}};
#define boxvar_InteractiveUtil_getPathedElementInElement MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getPathedElementInElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getPathedElementInClassPart(threadData_t *threadData, modelica_metatype _path, modelica_metatype _part);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getPathedElementInClassPart,2,0) {(void*) boxptr_InteractiveUtil_getPathedElementInClassPart,0}};
#define boxvar_InteractiveUtil_getPathedElementInClassPart MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getPathedElementInClassPart)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getPathedElementInClass(threadData_t *threadData, modelica_metatype _path, modelica_metatype _cls);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getPathedElementInClass,2,0) {(void*) boxptr_InteractiveUtil_getPathedElementInClass,0}};
#define boxvar_InteractiveUtil_getPathedElementInClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getPathedElementInClass)
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
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InteractiveUtil_isSubtypeOf(threadData_t *threadData, modelica_metatype _classPath, modelica_metatype _baseClassPath, modelica_metatype _program);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_isSubtypeOf(threadData_t *threadData, modelica_metatype _classPath, modelica_metatype _baseClassPath, modelica_metatype _program);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_isSubtypeOf,2,0) {(void*) boxptr_InteractiveUtil_isSubtypeOf,0}};
#define boxvar_InteractiveUtil_isSubtypeOf MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_isSubtypeOf)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getAllSubtypeOfCandidates(threadData_t *threadData, modelica_metatype _path, modelica_metatype _parentClass, modelica_metatype _program, modelica_boolean _includePartial, modelica_metatype __omcQ_24in_5Fcandidates);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getAllSubtypeOfCandidates(threadData_t *threadData, modelica_metatype _path, modelica_metatype _parentClass, modelica_metatype _program, modelica_metatype _includePartial, modelica_metatype __omcQ_24in_5Fcandidates);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getAllSubtypeOfCandidates,2,0) {(void*) boxptr_InteractiveUtil_getAllSubtypeOfCandidates,0}};
#define boxvar_InteractiveUtil_getAllSubtypeOfCandidates MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getAllSubtypeOfCandidates)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_namedargToModification(threadData_t *threadData, modelica_metatype _inNamedArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_namedargToModification,2,0) {(void*) boxptr_InteractiveUtil_namedargToModification,0}};
#define boxvar_InteractiveUtil_namedargToModification MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_namedargToModification)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_recordConstructorToModification(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_recordConstructorToModification,2,0) {(void*) boxptr_InteractiveUtil_recordConstructorToModification,0}};
#define boxvar_InteractiveUtil_recordConstructorToModification MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_recordConstructorToModification)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementInfo(threadData_t *threadData, modelica_metatype _element, modelica_boolean _isPublic, modelica_boolean _quoteNames, modelica_boolean _onlyComponents, modelica_metatype _env, modelica_metatype __omcQ_24in_5Finfos);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getElementInfo(threadData_t *threadData, modelica_metatype _element, modelica_metatype _isPublic, modelica_metatype _quoteNames, modelica_metatype _onlyComponents, modelica_metatype _env, modelica_metatype __omcQ_24in_5Finfos);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getModificationNames(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_boolean _includeRedeclares);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getModificationNames(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_metatype _includeRedeclares);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getModificationNames,2,0) {(void*) boxptr_InteractiveUtil_getModificationNames,0}};
#define boxvar_InteractiveUtil_getModificationNames MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getModificationNames)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getModificationValues(threadData_t *threadData, modelica_metatype _inAbsynElementArgLst, modelica_metatype _inPath);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_getModificationValues,2,0) {(void*) boxptr_InteractiveUtil_getModificationValues,0}};
#define boxvar_InteractiveUtil_getModificationValues MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_getModificationValues)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_createNestedSubMod(threadData_t *threadData, modelica_metatype _inComponentName, modelica_metatype _inMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_createNestedSubMod,2,0) {(void*) boxptr_InteractiveUtil_createNestedSubMod,0}};
#define boxvar_InteractiveUtil_createNestedSubMod MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_createNestedSubMod)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_propagateMod2(threadData_t *threadData, modelica_metatype _inComponentName, modelica_metatype _inSubMods, modelica_metatype _inNewMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_propagateMod2,2,0) {(void*) boxptr_InteractiveUtil_propagateMod2,0}};
#define boxvar_InteractiveUtil_propagateMod2 MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_propagateMod2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_removeEmptySubMods(threadData_t *threadData, modelica_metatype _subMods);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_removeEmptySubMods,2,0) {(void*) boxptr_InteractiveUtil_removeEmptySubMods,0}};
#define boxvar_InteractiveUtil_removeEmptySubMods MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_removeEmptySubMods)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_mergeElementArgs(threadData_t *threadData, modelica_metatype _inOldArgs, modelica_metatype _inNewArgs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_mergeElementArgs,2,0) {(void*) boxptr_InteractiveUtil_mergeElementArgs,0}};
#define boxvar_InteractiveUtil_mergeElementArgs MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_mergeElementArgs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setSubmodifierInClass(threadData_t *threadData, modelica_metatype _inElementName, modelica_metatype _inClass, modelica_metatype _inMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_setSubmodifierInClass,2,0) {(void*) boxptr_InteractiveUtil_setSubmodifierInClass,0}};
#define boxvar_InteractiveUtil_setSubmodifierInClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_setSubmodifierInClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setSubmodifierInElementSpec(threadData_t *threadData, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype __omcQ_24in_5FelSpec);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_setSubmodifierInElementSpec,2,0) {(void*) boxptr_InteractiveUtil_setSubmodifierInElementSpec,0}};
#define boxvar_InteractiveUtil_setSubmodifierInElementSpec MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_setSubmodifierInElementSpec)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setExtendsSubmodifierInElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _extendsPath, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype _env, modelica_boolean __omcQ_24in_5Ffound, modelica_boolean *out_found, modelica_boolean *out_outContinue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_setExtendsSubmodifierInElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _extendsPath, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype _env, modelica_metatype __omcQ_24in_5Ffound, modelica_metatype *out_found, modelica_metatype *out_outContinue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_setExtendsSubmodifierInElement,2,0) {(void*) boxptr_InteractiveUtil_setExtendsSubmodifierInElement,0}};
#define boxvar_InteractiveUtil_setExtendsSubmodifierInElement MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_setExtendsSubmodifierInElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setSubmodifierInElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_boolean __omcQ_24in_5Ffound, modelica_metatype _elementName, modelica_metatype _mod, modelica_boolean *out_found, modelica_boolean *out_outContinue);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_setSubmodifierInElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype __omcQ_24in_5Ffound, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype *out_found, modelica_metatype *out_outContinue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_setSubmodifierInElement,2,0) {(void*) boxptr_InteractiveUtil_setSubmodifierInElement,0}};
#define boxvar_InteractiveUtil_setSubmodifierInElement MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_setSubmodifierInElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setExtendsSubmodifierInClass(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype _extendsPath, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype _env, modelica_boolean *out_found);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_setExtendsSubmodifierInClass(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype _extendsPath, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype _env, modelica_metatype *out_found);
static const MMC_DEFSTRUCTLIT(boxvar_lit_InteractiveUtil_setExtendsSubmodifierInClass,2,0) {(void*) boxptr_InteractiveUtil_setExtendsSubmodifierInClass,0}};
#define boxvar_InteractiveUtil_setExtendsSubmodifierInClass MMC_REFSTRUCTLIT(boxvar_lit_InteractiveUtil_setExtendsSubmodifierInClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setElementSubmodifierInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inElementName, modelica_metatype _inMod, modelica_boolean *out_found);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_setElementSubmodifierInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inElementName, modelica_metatype _inMod, modelica_metatype *out_found);
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
DLLDirection
modelica_metatype omc_InteractiveUtil_addToEquation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype _eq)
{
modelica_metatype _cls = NULL;
modelica_metatype _eqlst = NULL;
modelica_metatype _cdef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cls = __omcQ_24in_5Fcls;
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _cls;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,0,5) == 0) goto tmp2_end;
_cdef = tmpMeta5;
_eqlst = omc_InteractiveUtil_getEquationList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))));
_eqlst = omc_List_appendElt(threadData, _eq, _eqlst);
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[4] = omc_InteractiveUtil_replaceEquationList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))), _eqlst);
_cdef = tmpMeta6;
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[7] = _cdef;
_cls = tmpMeta7;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,5) == 0) goto tmp2_end;
_cdef = tmpMeta8;
tmp3 += 2;
tmpMeta10 = mmc_mk_cons(_eq, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta11 = mmc_mk_box2(6, &Absyn_ClassPart_EQUATIONS__desc, tmpMeta10);
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[4] = omc_List_appendElt(threadData, tmpMeta11, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))));
_cdef = tmpMeta9;
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[7] = _cdef;
_cls = tmpMeta12;
goto tmp2_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,4,5) == 0) goto tmp2_end;
_cdef = tmpMeta13;
_eqlst = omc_InteractiveUtil_getEquationList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))));
_eqlst = omc_List_appendElt(threadData, _eq, _eqlst);
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[5] = omc_InteractiveUtil_replaceEquationList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))), _eqlst);
_cdef = tmpMeta14;
tmpMeta15 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta15), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta15))[7] = _cdef;
_cls = tmpMeta15;
goto tmp2_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,4,5) == 0) goto tmp2_end;
_cdef = tmpMeta16;
tmpMeta18 = mmc_mk_cons(_eq, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta19 = mmc_mk_box2(6, &Absyn_ClassPart_EQUATIONS__desc, tmpMeta18);
tmpMeta17 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta17), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta17))[5] = omc_List_appendElt(threadData, tmpMeta19, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))));
_cdef = tmpMeta17;
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta20))[7] = _cdef;
_cls = tmpMeta20;
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
;
_return: OMC_LABEL_UNUSED
return _cls;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_addToProtected(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype _element)
{
modelica_metatype _cls = NULL;
modelica_metatype _elems = NULL;
modelica_metatype _cdef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cls = __omcQ_24in_5Fcls;
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _cls;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,0,5) == 0) goto tmp2_end;
_cdef = tmpMeta5;
_elems = omc_ProgramUtil_getProtectedList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))));
_elems = omc_List_appendElt(threadData, _element, _elems);
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[4] = omc_ProgramUtil_replaceProtectedList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))), _elems);
_cdef = tmpMeta6;
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[7] = _cdef;
_cls = tmpMeta7;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,5) == 0) goto tmp2_end;
_cdef = tmpMeta8;
tmp3 += 2;
tmpMeta11 = mmc_mk_cons(_element, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta12 = mmc_mk_box2(4, &Absyn_ClassPart_PROTECTED__desc, tmpMeta11);
tmpMeta10 = mmc_mk_cons(tmpMeta12, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))));
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[4] = tmpMeta10;
_cdef = tmpMeta9;
tmpMeta13 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta13), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta13))[7] = _cdef;
_cls = tmpMeta13;
goto tmp2_done;
}
case 2: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,4,5) == 0) goto tmp2_end;
_cdef = tmpMeta14;
_elems = omc_ProgramUtil_getProtectedList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))));
_elems = omc_List_appendElt(threadData, _element, _elems);
tmpMeta15 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta15), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta15))[5] = omc_ProgramUtil_replaceProtectedList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))), _elems);
_cdef = tmpMeta15;
tmpMeta16 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta16), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta16))[7] = _cdef;
_cls = tmpMeta16;
goto tmp2_done;
}
case 3: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,4,5) == 0) goto tmp2_end;
_cdef = tmpMeta17;
tmpMeta20 = mmc_mk_cons(_element, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta21 = mmc_mk_box2(4, &Absyn_ClassPart_PROTECTED__desc, tmpMeta20);
tmpMeta19 = mmc_mk_cons(tmpMeta21, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))));
tmpMeta18 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta18), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta18))[5] = tmpMeta19;
_cdef = tmpMeta18;
tmpMeta22 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta22), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta22))[7] = _cdef;
_cls = tmpMeta22;
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
;
_return: OMC_LABEL_UNUSED
return _cls;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_addToPublic(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype _element)
{
modelica_metatype _cls = NULL;
modelica_metatype _elems = NULL;
modelica_metatype _cdef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cls = __omcQ_24in_5Fcls;
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _cls;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,0,5) == 0) goto tmp2_end;
_cdef = tmpMeta5;
_elems = omc_ProgramUtil_getPublicList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))));
_elems = omc_List_appendElt(threadData, _element, _elems);
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[4] = omc_ProgramUtil_replacePublicList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))), _elems);
_cdef = tmpMeta6;
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[7] = _cdef;
_cls = tmpMeta7;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,5) == 0) goto tmp2_end;
_cdef = tmpMeta8;
tmp3 += 2;
tmpMeta11 = mmc_mk_cons(_element, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta12 = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, tmpMeta11);
tmpMeta10 = mmc_mk_cons(tmpMeta12, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))));
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[4] = tmpMeta10;
_cdef = tmpMeta9;
tmpMeta13 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta13), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta13))[7] = _cdef;
_cls = tmpMeta13;
goto tmp2_done;
}
case 2: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,4,5) == 0) goto tmp2_end;
_cdef = tmpMeta14;
_elems = omc_ProgramUtil_getPublicList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))));
_elems = omc_List_appendElt(threadData, _element, _elems);
tmpMeta15 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta15), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta15))[5] = omc_ProgramUtil_replacePublicList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))), _elems);
_cdef = tmpMeta15;
tmpMeta16 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta16), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta16))[7] = _cdef;
_cls = tmpMeta16;
goto tmp2_done;
}
case 3: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,4,5) == 0) goto tmp2_end;
_cdef = tmpMeta17;
tmpMeta20 = mmc_mk_cons(_element, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta21 = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, tmpMeta20);
tmpMeta19 = mmc_mk_cons(tmpMeta21, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))));
tmpMeta18 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta18), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta18))[5] = tmpMeta19;
_cdef = tmpMeta18;
tmpMeta22 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta22), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta22))[7] = _cdef;
_cls = tmpMeta22;
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
;
_return: OMC_LABEL_UNUSED
return _cls;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_offsetGraphicsItemExpression_offset__named__origin(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_integer _x, modelica_integer _y, modelica_boolean *out_found)
{
modelica_metatype _arg = NULL;
modelica_boolean _found;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_arg = __omcQ_24in_5Farg;
_found = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 2))), _OMC_LIT0));
if(_found)
{
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_arg), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[3] = omc_InteractiveUtil_offsetPointExpression(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 3))), _x, _y);
_arg = tmpMeta1;
}
_return: OMC_LABEL_UNUSED
if (out_found) { *out_found = _found; }
return _arg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_offsetGraphicsItemExpression_offset__named__origin(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_metatype _x, modelica_metatype _y, modelica_metatype *out_found)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_boolean _found;
modelica_metatype _arg = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_arg = omc_InteractiveUtil_offsetGraphicsItemExpression_offset__named__origin(threadData, __omcQ_24in_5Farg, tmp1, tmp2, &_found);
if (out_found) { *out_found = mmc_mk_icon(_found); }
return _arg;
}
static modelica_metatype closure0_InteractiveUtil_offsetGraphicsItemExpression_offset__named__origin(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_arg, modelica_metatype tmp14)
{
modelica_metatype x = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype y = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_offsetGraphicsItemExpression_offset__named__origin(thData, $in_arg, x, y, tmp14);
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetGraphicsItemExpression(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _item = NULL;
modelica_metatype _args = NULL;
modelica_metatype _named_args = NULL;
modelica_boolean _found;
modelica_metatype _visible = NULL;
modelica_metatype _origin = NULL;
modelica_metatype _rest = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_item = __omcQ_24in_5Fitem;
{
modelica_metatype tmp3_1;
tmp3_1 = _item;
{
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
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,11,3) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,0,2) == 0) goto tmp2_end;
_args = tmpMeta5;
if((listLength((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_args), 2)))) >= ((modelica_integer) 2)))
{
tmpMeta6 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_args), 2)));
if (listEmpty(tmpMeta6)) goto goto_1;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
if (listEmpty(tmpMeta8)) goto goto_1;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
_visible = tmpMeta7;
_origin = tmpMeta9;
_rest = tmpMeta10;
_origin = omc_InteractiveUtil_offsetPointExpression(threadData, _origin, _x, _y);
tmpMeta13 = mmc_mk_cons(_origin, _rest);
tmpMeta12 = mmc_mk_cons(_visible, tmpMeta13);
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_args), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[2] = tmpMeta12;
_args = tmpMeta11;
}
else
{
tmpMeta15 = mmc_mk_box2(0, mmc_mk_integer(_x), mmc_mk_integer(_y));
_named_args = omc_List_findMap(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_args), 3))), (modelica_fnptr) mmc_mk_box2(0,closure0_InteractiveUtil_offsetGraphicsItemExpression_offset__named__origin,tmpMeta15) ,&_found);
if(_found)
{
tmpMeta16 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta16), MMC_UNTAGPTR(_args), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta16))[3] = _named_args;
_args = tmpMeta16;
}
else
{
tmpMeta19 = mmc_mk_box3(3, &Absyn_NamedArg_NAMEDARG__desc, _OMC_LIT0, omc_InteractiveUtil_makeOrigin(threadData, _x, _y));
tmpMeta18 = mmc_mk_cons(tmpMeta19, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_args), 3))));
tmpMeta17 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta17), MMC_UNTAGPTR(_args), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta17))[3] = tmpMeta18;
_args = tmpMeta17;
}
}
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_item), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta20))[3] = _args;
_item = tmpMeta20;
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
return _item;
}
modelica_metatype boxptr_InteractiveUtil_offsetGraphicsItemExpression(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _item = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_item = omc_InteractiveUtil_offsetGraphicsItemExpression(threadData, __omcQ_24in_5Fitem, tmp1, tmp2);
return _item;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetGraphicsExpression(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fgraphics, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _graphics = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_graphics = __omcQ_24in_5Fgraphics;
{
modelica_metatype tmp3_1;
tmp3_1 = _graphics;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,1) == 0) goto tmp2_end;
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp7;
modelica_metatype tmpMeta8;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp9;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_graphics), 2)));
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta8;
tmp7 = &__omcQ_24tmpVar1;
while(1) {
tmp9 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar0 = omc_InteractiveUtil_offsetGraphicsItemExpression(threadData, _p, _x, _y);
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp9 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp7 = mmc_mk_nil();
tmpMeta6 = __omcQ_24tmpVar1;
}
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_graphics), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = tmpMeta6;
_graphics = tmpMeta5;
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
return _graphics;
}
modelica_metatype boxptr_InteractiveUtil_offsetGraphicsExpression(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fgraphics, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _graphics = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_graphics = omc_InteractiveUtil_offsetGraphicsExpression(threadData, __omcQ_24in_5Fgraphics, tmp1, tmp2);
return _graphics;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetGraphicsAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _arg = NULL;
modelica_metatype _eq_mod = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp3_1;
tmp3_1 = _arg;
{
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
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,6) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (optionNone(tmpMeta5)) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,2) == 0) goto tmp2_end;
_eq_mod = tmpMeta7;
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_eq_mod), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[2] = omc_InteractiveUtil_offsetGraphicsExpression(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq_mod), 2))), _x, _y);
_eq_mod = tmpMeta8;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta11 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta10, _eq_mod);
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_arg), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[5] = mmc_mk_some(tmpMeta11);
_arg = tmpMeta9;
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
return _arg;
}
modelica_metatype boxptr_InteractiveUtil_offsetGraphicsAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _arg = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_arg = omc_InteractiveUtil_offsetGraphicsAnnotation(threadData, __omcQ_24in_5Farg, tmp1, tmp2);
return _arg;
}
static modelica_metatype closure1_InteractiveUtil_offsetGraphicsAnnotation(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_arg)
{
modelica_metatype x = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype y = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_offsetGraphicsAnnotation(thData, $in_arg, x, y);
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetDiagramAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fann, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _ann = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ann = __omcQ_24in_5Fann;
tmpMeta1 = mmc_mk_box2(0, mmc_mk_integer(_x), mmc_mk_integer(_y));
_ann = omc_AbsynUtil_transformAnnotationArg(threadData, _ann, _OMC_LIT4, (modelica_fnptr) mmc_mk_box2(0,closure1_InteractiveUtil_offsetGraphicsAnnotation,tmpMeta1), 1 /* true */);
_return: OMC_LABEL_UNUSED
return _ann;
}
modelica_metatype boxptr_InteractiveUtil_offsetDiagramAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fann, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _ann = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_ann = omc_InteractiveUtil_offsetDiagramAnnotation(threadData, __omcQ_24in_5Fann, tmp1, tmp2);
return _ann;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetDiagramAnnotationInOptComment(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcmt, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _cmt = NULL;
modelica_metatype _cmt_str = NULL;
modelica_metatype _ann = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cmt = __omcQ_24in_5Fcmt;
{
modelica_metatype tmp3_1;
tmp3_1 = _cmt;
{
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
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
if (optionNone(tmpMeta6)) goto tmp2_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 3));
_ann = tmpMeta7;
_cmt_str = tmpMeta8;
_ann = omc_InteractiveUtil_offsetDiagramAnnotation(threadData, _ann, _x, _y);
tmpMeta9 = mmc_mk_box3(3, &Absyn_Comment_COMMENT__desc, mmc_mk_some(_ann), _cmt_str);
_cmt = mmc_mk_some(tmpMeta9);
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
return _cmt;
}
modelica_metatype boxptr_InteractiveUtil_offsetDiagramAnnotationInOptComment(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcmt, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _cmt = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_cmt = omc_InteractiveUtil_offsetDiagramAnnotationInOptComment(threadData, __omcQ_24in_5Fcmt, tmp1, tmp2);
return _cmt;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetConnectionLineAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _arg = NULL;
modelica_metatype _eq_mod = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp3_1;
tmp3_1 = _arg;
{
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
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,6) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (optionNone(tmpMeta5)) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,2) == 0) goto tmp2_end;
_eq_mod = tmpMeta7;
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_eq_mod), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[2] = omc_InteractiveUtil_offsetLineExpression(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq_mod), 2))), _x, _y);
_eq_mod = tmpMeta8;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta11 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta10, _eq_mod);
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_arg), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[5] = mmc_mk_some(tmpMeta11);
_arg = tmpMeta9;
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
return _arg;
}
modelica_metatype boxptr_InteractiveUtil_offsetConnectionLineAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _arg = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_arg = omc_InteractiveUtil_offsetConnectionLineAnnotation(threadData, __omcQ_24in_5Farg, tmp1, tmp2);
return _arg;
}
static modelica_metatype closure2_InteractiveUtil_offsetConnectionLineAnnotation(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_arg)
{
modelica_metatype x = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype y = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_offsetConnectionLineAnnotation(thData, $in_arg, x, y);
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetAnnotationsInEquationItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _item = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _ann = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_item = __omcQ_24in_5Fitem;
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _item;
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
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,3) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (optionNone(tmpMeta5)) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (optionNone(tmpMeta7)) goto tmp2_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_cmt = tmpMeta6;
_ann = tmpMeta8;
tmpMeta9 = mmc_mk_box2(0, mmc_mk_integer(_x), mmc_mk_integer(_y));
_ann = omc_AbsynUtil_transformAnnotationArg(threadData, _ann, _OMC_LIT8, (modelica_fnptr) mmc_mk_box2(0,closure2_InteractiveUtil_offsetConnectionLineAnnotation,tmpMeta9), 0 /* false */);
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_cmt), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[2] = mmc_mk_some(_ann);
_cmt = tmpMeta10;
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_item), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[3] = mmc_mk_some(_cmt);
_item = tmpMeta11;
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
_return: OMC_LABEL_UNUSED
return _item;
}
modelica_metatype boxptr_InteractiveUtil_offsetAnnotationsInEquationItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _item = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_item = omc_InteractiveUtil_offsetAnnotationsInEquationItem(threadData, __omcQ_24in_5Fitem, tmp1, tmp2);
return _item;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetLineExpression(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fline, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _line = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_line = __omcQ_24in_5Fline;
{
modelica_metatype tmp3_1;
tmp3_1 = _line;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,1) == 0) goto tmp2_end;
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp7;
modelica_metatype tmpMeta8;
modelica_metatype __omcQ_24tmpVar2;
modelica_integer tmp9;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_line), 2)));
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta8;
tmp7 = &__omcQ_24tmpVar3;
while(1) {
tmp9 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar2 = omc_InteractiveUtil_offsetPointExpression(threadData, _p, _x, _y);
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp9 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp7 = mmc_mk_nil();
tmpMeta6 = __omcQ_24tmpVar3;
}
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_line), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = tmpMeta6;
_line = tmpMeta5;
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
return _line;
}
modelica_metatype boxptr_InteractiveUtil_offsetLineExpression(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fline, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _line = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_line = omc_InteractiveUtil_offsetLineExpression(threadData, __omcQ_24in_5Fline, tmp1, tmp2);
return _line;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetIntegerExpression(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_integer _offset)
{
modelica_metatype _exp = NULL;
modelica_integer _v;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = mmc_mk_box2(3, &Absyn_Exp_INTEGER__desc, mmc_mk_integer(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 2)))) + _offset));
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,5,0) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
_v = tmp10;
tmpMeta11 = mmc_mk_box2(3, &Absyn_Exp_INTEGER__desc, mmc_mk_integer(_v + _offset));
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,6,0) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
_v = tmp15;
tmpMeta16 = mmc_mk_box2(3, &Absyn_Exp_INTEGER__desc, mmc_mk_integer(_offset - _v));
tmpMeta1 = tmpMeta16;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_boolean tmp21;
modelica_metatype tmpMeta22;
modelica_boolean tmp23;
modelica_metatype tmpMeta24;
tmp23 = (modelica_boolean)(_offset > ((modelica_integer) 0));
if(tmp23)
{
tmpMeta17 = mmc_mk_box2(3, &Absyn_Exp_INTEGER__desc, mmc_mk_integer(_offset));
tmpMeta18 = mmc_mk_box4(8, &Absyn_Exp_BINARY__desc, _exp, _OMC_LIT9, tmpMeta17);
tmpMeta24 = tmpMeta18;
}
else
{
tmp21 = (modelica_boolean)(_offset < ((modelica_integer) 0));
if(tmp21)
{
tmpMeta19 = mmc_mk_box2(3, &Absyn_Exp_INTEGER__desc, mmc_mk_integer((-_offset)));
tmpMeta20 = mmc_mk_box4(8, &Absyn_Exp_BINARY__desc, _exp, _OMC_LIT10, tmpMeta19);
tmpMeta22 = tmpMeta20;
}
else
{
tmpMeta22 = _exp;
}
tmpMeta24 = tmpMeta22;
}
tmpMeta1 = tmpMeta24;
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
return _exp;
}
modelica_metatype boxptr_InteractiveUtil_offsetIntegerExpression(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype _offset)
{
modelica_integer tmp1;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_integer(_offset);
_exp = omc_InteractiveUtil_offsetIntegerExpression(threadData, __omcQ_24in_5Fexp, tmp1);
return _exp;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetPointExpression(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpoint, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _point = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_point = __omcQ_24in_5Fpoint;
{
modelica_metatype tmp4_1;
tmp4_1 = _point;
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
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (!listEmpty(tmpMeta10)) goto tmp3_end;
_e1 = tmpMeta7;
_e2 = tmpMeta9;
tmpMeta11 = mmc_mk_cons(omc_InteractiveUtil_offsetIntegerExpression(threadData, _e1, _x), mmc_mk_cons(omc_InteractiveUtil_offsetIntegerExpression(threadData, _e2, _y), MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta12 = mmc_mk_box2(16, &Absyn_Exp_ARRAY__desc, tmpMeta11);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
tmpMeta13 = mmc_mk_box4(8, &Absyn_Exp_BINARY__desc, _point, _OMC_LIT9, omc_InteractiveUtil_makeOrigin(threadData, _x, _y));
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
_point = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _point;
}
modelica_metatype boxptr_InteractiveUtil_offsetPointExpression(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpoint, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _point = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_point = omc_InteractiveUtil_offsetPointExpression(threadData, __omcQ_24in_5Fpoint, tmp1, tmp2);
return _point;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_makeOrigin(threadData_t *threadData, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _origin = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta2 = mmc_mk_box2(3, &Absyn_Exp_INTEGER__desc, mmc_mk_integer(_x));
tmpMeta3 = mmc_mk_box2(3, &Absyn_Exp_INTEGER__desc, mmc_mk_integer(_y));
tmpMeta1 = mmc_mk_cons(tmpMeta2, mmc_mk_cons(tmpMeta3, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta4 = mmc_mk_box2(16, &Absyn_Exp_ARRAY__desc, tmpMeta1);
_origin = tmpMeta4;
_return: OMC_LABEL_UNUSED
return _origin;
}
modelica_metatype boxptr_InteractiveUtil_makeOrigin(threadData_t *threadData, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _origin = NULL;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_origin = omc_InteractiveUtil_makeOrigin(threadData, tmp1, tmp2);
return _origin;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetOriginAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _arg = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _eq_mod = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp3_1;
tmp3_1 = _arg;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,6) == 0) goto tmp2_end;
if(isSome((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 5)))))
{
tmpMeta5 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 5)));
if (optionNone(tmpMeta5)) goto goto_1;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
_mod = tmpMeta6;
}
else
{
_mod = _OMC_LIT12;
}
_eq_mod = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 3)));
{
modelica_metatype tmp11_1;
tmp11_1 = _eq_mod;
{
volatile mmc_switch_type tmp11;
int tmp12;
tmp11 = 0;
for (; tmp11 < 2; tmp11++) {
switch (MMC_SWITCH_CAST(tmp11)) {
case 0: {
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp11_1,1,2) == 0) goto tmp10_end;
tmpMeta13 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta13), MMC_UNTAGPTR(_eq_mod), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta13))[2] = omc_InteractiveUtil_offsetPointExpression(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq_mod), 2))), _x, _y);
_eq_mod = tmpMeta13;
tmpMeta8 = _eq_mod;
goto tmp10_done;
}
case 1: {
modelica_metatype tmpMeta14;
tmpMeta14 = mmc_mk_box3(4, &Absyn_EqMod_EQMOD__desc, omc_InteractiveUtil_makeOrigin(threadData, _x, _y), _OMC_LIT15);
tmpMeta8 = tmpMeta14;
goto tmp10_done;
}
}
goto tmp10_end;
tmp10_end: ;
}
goto goto_9;
goto_9:;
goto goto_1;
goto tmp10_done;
tmp10_done:;
}
}
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_mod), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[3] = tmpMeta8;
_mod = tmpMeta7;
tmpMeta15 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta15), MMC_UNTAGPTR(_arg), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta15))[5] = mmc_mk_some(_mod);
_arg = tmpMeta15;
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
return _arg;
}
modelica_metatype boxptr_InteractiveUtil_offsetOriginAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _arg = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_arg = omc_InteractiveUtil_offsetOriginAnnotation(threadData, __omcQ_24in_5Farg, tmp1, tmp2);
return _arg;
}
static modelica_metatype closure3_InteractiveUtil_offsetOriginAnnotation(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_arg)
{
modelica_metatype x = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype y = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_offsetOriginAnnotation(thData, $in_arg, x, y);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_offsetIconTransformationAnnotation_impl(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _arg = NULL;
modelica_metatype _mod = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp3_1;
tmp3_1 = _arg;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,6) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (optionNone(tmpMeta5)) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
_mod = tmpMeta6;
tmpMeta8 = mmc_mk_box2(0, mmc_mk_integer(_x), mmc_mk_integer(_y));
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_mod), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[2] = omc_AbsynUtil_transformAnnotationInArgs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 2))), _OMC_LIT16, (modelica_fnptr) mmc_mk_box2(0,closure3_InteractiveUtil_offsetOriginAnnotation,tmpMeta8), 1 /* true */);
_mod = tmpMeta7;
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_arg), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[5] = mmc_mk_some(_mod);
_arg = tmpMeta9;
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
return _arg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_offsetIconTransformationAnnotation_impl(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _arg = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_arg = omc_InteractiveUtil_offsetIconTransformationAnnotation_impl(threadData, __omcQ_24in_5Farg, tmp1, tmp2);
return _arg;
}
static modelica_metatype closure4_InteractiveUtil_offsetIconTransformationAnnotation_impl(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_arg)
{
modelica_metatype x = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype y = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_offsetIconTransformationAnnotation_impl(thData, $in_arg, x, y);
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetIconTransformationAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fann, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _ann = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ann = __omcQ_24in_5Fann;
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
tmpMeta5 = mmc_mk_box2(0, mmc_mk_integer(_x), mmc_mk_integer(_y));
_ann = omc_AbsynUtil_transformAnnotationArg(threadData, _ann, _OMC_LIT20, (modelica_fnptr) mmc_mk_box2(0,closure4_InteractiveUtil_offsetIconTransformationAnnotation_impl,tmpMeta5), 0 /* false */);
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
_return: OMC_LABEL_UNUSED
return _ann;
}
modelica_metatype boxptr_InteractiveUtil_offsetIconTransformationAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fann, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _ann = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_ann = omc_InteractiveUtil_offsetIconTransformationAnnotation(threadData, __omcQ_24in_5Fann, tmp1, tmp2);
return _ann;
}
static modelica_metatype closure5_InteractiveUtil_offsetOriginAnnotation(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_arg)
{
modelica_metatype x = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype y = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_offsetOriginAnnotation(thData, $in_arg, x, y);
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetAnnotationsInComponentItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _item = NULL;
modelica_metatype _oann = NULL;
modelica_metatype _ann = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_item = __omcQ_24in_5Fitem;
_oann = omc_AbsynUtil_getCommentOptAnnotation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_item), 4))));
_ann = (isSome(_oann)?omc_Util_getOption(threadData, _oann):_OMC_LIT21);
tmpMeta1 = mmc_mk_box2(0, mmc_mk_integer(_x), mmc_mk_integer(_y));
_ann = omc_AbsynUtil_transformAnnotationArg(threadData, _ann, _OMC_LIT24, (modelica_fnptr) mmc_mk_box2(0,closure5_InteractiveUtil_offsetOriginAnnotation,tmpMeta1), 1 /* true */);
_ann = omc_InteractiveUtil_offsetIconTransformationAnnotation(threadData, _ann, _x, _y);
_item = omc_AbsynUtil_setComponentItemAnnotation(threadData, _item, mmc_mk_some(_ann));
_return: OMC_LABEL_UNUSED
return _item;
}
modelica_metatype boxptr_InteractiveUtil_offsetAnnotationsInComponentItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _item = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_item = omc_InteractiveUtil_offsetAnnotationsInComponentItem(threadData, __omcQ_24in_5Fitem, tmp1, tmp2);
return _item;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetAnnotationsInElementSpec(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fspec, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _spec = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_spec = __omcQ_24in_5Fspec;
{
modelica_metatype tmp3_1;
tmp3_1 = _spec;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,3) == 0) goto tmp2_end;
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp7;
modelica_metatype tmpMeta8;
modelica_metatype __omcQ_24tmpVar4;
modelica_integer tmp9;
modelica_metatype _c_loopVar = 0;
modelica_metatype _c;
_c_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 4)));
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta8;
tmp7 = &__omcQ_24tmpVar5;
while(1) {
tmp9 = 1;
if (!listEmpty(_c_loopVar)) {
_c = MMC_CAR(_c_loopVar);
_c_loopVar = MMC_CDR(_c_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar4 = omc_InteractiveUtil_offsetAnnotationsInComponentItem(threadData, _c, _x, _y);
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp9 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp7 = mmc_mk_nil();
tmpMeta6 = __omcQ_24tmpVar5;
}
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_spec), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[4] = tmpMeta6;
_spec = tmpMeta5;
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
return _spec;
}
modelica_metatype boxptr_InteractiveUtil_offsetAnnotationsInElementSpec(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fspec, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _spec = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_spec = omc_InteractiveUtil_offsetAnnotationsInElementSpec(threadData, __omcQ_24in_5Fspec, tmp1, tmp2);
return _spec;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetAnnotationsInElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _element = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = __omcQ_24in_5Felement;
{
modelica_metatype tmp3_1;
tmp3_1 = _element;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,6) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_element), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[5] = omc_InteractiveUtil_offsetAnnotationsInElementSpec(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5))), _x, _y);
_element = tmpMeta5;
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
return _element;
}
modelica_metatype boxptr_InteractiveUtil_offsetAnnotationsInElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _element = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_element = omc_InteractiveUtil_offsetAnnotationsInElement(threadData, __omcQ_24in_5Felement, tmp1, tmp2);
return _element;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetAnnotationsInElementItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _item = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_item = __omcQ_24in_5Fitem;
{
modelica_metatype tmp3_1;
tmp3_1 = _item;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_item), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = omc_InteractiveUtil_offsetAnnotationsInElement(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_item), 2))), _x, _y);
_item = tmpMeta5;
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
return _item;
}
modelica_metatype boxptr_InteractiveUtil_offsetAnnotationsInElementItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _item = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_item = omc_InteractiveUtil_offsetAnnotationsInElementItem(threadData, __omcQ_24in_5Fitem, tmp1, tmp2);
return _item;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetAnnotationsInClassPart(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpart, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _part = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_part = __omcQ_24in_5Fpart;
{
modelica_metatype tmp3_1;
tmp3_1 = _part;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp6;
modelica_metatype tmpMeta7;
modelica_metatype __omcQ_24tmpVar6;
modelica_integer tmp8;
modelica_metatype _i_loopVar = 0;
modelica_metatype _i;
_i_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2)));
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta7;
tmp6 = &__omcQ_24tmpVar7;
while(1) {
tmp8 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp8--;
}
if (tmp8 == 0) {
__omcQ_24tmpVar6 = omc_InteractiveUtil_offsetAnnotationsInElementItem(threadData, _i, _x, _y);
*tmp6 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp6 = &MMC_CDR(*tmp6);
} else if (tmp8 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp6 = mmc_mk_nil();
tmpMeta5 = __omcQ_24tmpVar7;
}
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[2] = tmpMeta5;
_part = tmpMeta4;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
{
modelica_metatype __omcQ_24tmpVar9;
modelica_metatype* tmp11;
modelica_metatype tmpMeta12;
modelica_metatype __omcQ_24tmpVar8;
modelica_integer tmp13;
modelica_metatype _i_loopVar = 0;
modelica_metatype _i;
_i_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2)));
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar9 = tmpMeta12;
tmp11 = &__omcQ_24tmpVar9;
while(1) {
tmp13 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp13--;
}
if (tmp13 == 0) {
__omcQ_24tmpVar8 = omc_InteractiveUtil_offsetAnnotationsInElementItem(threadData, _i, _x, _y);
*tmp11 = mmc_mk_cons(__omcQ_24tmpVar8,0);
tmp11 = &MMC_CDR(*tmp11);
} else if (tmp13 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp11 = mmc_mk_nil();
tmpMeta10 = __omcQ_24tmpVar9;
}
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[2] = tmpMeta10;
_part = tmpMeta9;
goto tmp2_done;
}
case 6: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
{
modelica_metatype __omcQ_24tmpVar11;
modelica_metatype* tmp16;
modelica_metatype tmpMeta17;
modelica_metatype __omcQ_24tmpVar10;
modelica_integer tmp18;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2)));
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar11 = tmpMeta17;
tmp16 = &__omcQ_24tmpVar11;
while(1) {
tmp18 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp18--;
}
if (tmp18 == 0) {
__omcQ_24tmpVar10 = omc_InteractiveUtil_offsetAnnotationsInEquationItem(threadData, _e, _x, _y);
*tmp16 = mmc_mk_cons(__omcQ_24tmpVar10,0);
tmp16 = &MMC_CDR(*tmp16);
} else if (tmp18 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp16 = mmc_mk_nil();
tmpMeta15 = __omcQ_24tmpVar11;
}
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[2] = tmpMeta15;
_part = tmpMeta14;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _part;
}
modelica_metatype boxptr_InteractiveUtil_offsetAnnotationsInClassPart(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpart, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _part = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_part = omc_InteractiveUtil_offsetAnnotationsInClassPart(threadData, __omcQ_24in_5Fpart, tmp1, tmp2);
return _part;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_offsetAnnotationsInClassDef(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcdef, modelica_integer _x, modelica_integer _y)
{
modelica_metatype _cdef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cdef = __omcQ_24in_5Fcdef;
if(((_x == ((modelica_integer) 0)) && (_y == ((modelica_integer) 0))))
{
goto _return;
}
{
modelica_metatype tmp3_1;
tmp3_1 = _cdef;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
{
modelica_metatype __omcQ_24tmpVar13;
modelica_metatype* tmp6;
modelica_metatype tmpMeta7;
modelica_metatype __omcQ_24tmpVar12;
modelica_integer tmp8;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4)));
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar13 = tmpMeta7;
tmp6 = &__omcQ_24tmpVar13;
while(1) {
tmp8 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp8--;
}
if (tmp8 == 0) {
__omcQ_24tmpVar12 = omc_InteractiveUtil_offsetAnnotationsInClassPart(threadData, _p, _x, _y);
*tmp6 = mmc_mk_cons(__omcQ_24tmpVar12,0);
tmp6 = &MMC_CDR(*tmp6);
} else if (tmp8 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp6 = mmc_mk_nil();
tmpMeta5 = __omcQ_24tmpVar13;
}
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[4] = tmpMeta5;
_cdef = tmpMeta4;
{
modelica_metatype __omcQ_24tmpVar15;
modelica_metatype* tmp11;
modelica_metatype tmpMeta12;
modelica_metatype __omcQ_24tmpVar14;
modelica_integer tmp13;
modelica_metatype _a_loopVar = 0;
modelica_metatype _a;
_a_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5)));
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar15 = tmpMeta12;
tmp11 = &__omcQ_24tmpVar15;
while(1) {
tmp13 = 1;
if (!listEmpty(_a_loopVar)) {
_a = MMC_CAR(_a_loopVar);
_a_loopVar = MMC_CDR(_a_loopVar);
tmp13--;
}
if (tmp13 == 0) {
__omcQ_24tmpVar14 = omc_InteractiveUtil_offsetDiagramAnnotation(threadData, _a, _x, _y);
*tmp11 = mmc_mk_cons(__omcQ_24tmpVar14,0);
tmp11 = &MMC_CDR(*tmp11);
} else if (tmp13 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp11 = mmc_mk_nil();
tmpMeta10 = __omcQ_24tmpVar15;
}
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[5] = tmpMeta10;
_cdef = tmpMeta9;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta14;
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_cdef), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[5] = omc_InteractiveUtil_offsetDiagramAnnotationInOptComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))), _x, _y);
_cdef = tmpMeta14;
goto tmp2_done;
}
case 5: {
modelica_metatype tmpMeta15;
tmpMeta15 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta15), MMC_UNTAGPTR(_cdef), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta15))[3] = omc_InteractiveUtil_offsetDiagramAnnotationInOptComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 3))), _x, _y);
_cdef = tmpMeta15;
goto tmp2_done;
}
case 6: {
modelica_metatype tmpMeta16;
tmpMeta16 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta16), MMC_UNTAGPTR(_cdef), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta16))[3] = omc_InteractiveUtil_offsetDiagramAnnotationInOptComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 3))), _x, _y);
_cdef = tmpMeta16;
goto tmp2_done;
}
case 7: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
{
modelica_metatype __omcQ_24tmpVar17;
modelica_metatype* tmp19;
modelica_metatype tmpMeta20;
modelica_metatype __omcQ_24tmpVar16;
modelica_integer tmp21;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5)));
tmpMeta20 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar17 = tmpMeta20;
tmp19 = &__omcQ_24tmpVar17;
while(1) {
tmp21 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp21--;
}
if (tmp21 == 0) {
__omcQ_24tmpVar16 = omc_InteractiveUtil_offsetAnnotationsInClassPart(threadData, _p, _x, _y);
*tmp19 = mmc_mk_cons(__omcQ_24tmpVar16,0);
tmp19 = &MMC_CDR(*tmp19);
} else if (tmp21 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp19 = mmc_mk_nil();
tmpMeta18 = __omcQ_24tmpVar17;
}
tmpMeta17 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta17), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta17))[5] = tmpMeta18;
_cdef = tmpMeta17;
{
modelica_metatype __omcQ_24tmpVar19;
modelica_metatype* tmp24;
modelica_metatype tmpMeta25;
modelica_metatype __omcQ_24tmpVar18;
modelica_integer tmp26;
modelica_metatype _a_loopVar = 0;
modelica_metatype _a;
_a_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 6)));
tmpMeta25 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar19 = tmpMeta25;
tmp24 = &__omcQ_24tmpVar19;
while(1) {
tmp26 = 1;
if (!listEmpty(_a_loopVar)) {
_a = MMC_CAR(_a_loopVar);
_a_loopVar = MMC_CDR(_a_loopVar);
tmp26--;
}
if (tmp26 == 0) {
__omcQ_24tmpVar18 = omc_InteractiveUtil_offsetDiagramAnnotation(threadData, _a, _x, _y);
*tmp24 = mmc_mk_cons(__omcQ_24tmpVar18,0);
tmp24 = &MMC_CDR(*tmp24);
} else if (tmp26 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp24 = mmc_mk_nil();
tmpMeta23 = __omcQ_24tmpVar19;
}
tmpMeta22 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta22), MMC_UNTAGPTR(_cdef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta22))[6] = tmpMeta23;
_cdef = tmpMeta22;
goto tmp2_done;
}
case 8: {
modelica_metatype tmpMeta27;
tmpMeta27 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta27), MMC_UNTAGPTR(_cdef), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta27))[4] = omc_InteractiveUtil_offsetDiagramAnnotationInOptComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))), _x, _y);
_cdef = tmpMeta27;
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
return _cdef;
}
modelica_metatype boxptr_InteractiveUtil_offsetAnnotationsInClassDef(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcdef, modelica_metatype _x, modelica_metatype _y)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _cdef = NULL;
tmp1 = mmc_unbox_integer(_x);
tmp2 = mmc_unbox_integer(_y);
_cdef = omc_InteractiveUtil_offsetAnnotationsInClassDef(threadData, __omcQ_24in_5Fcdef, tmp1, tmp2);
return _cdef;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_parseWithinPath(threadData_t *threadData, modelica_metatype _path)
{
modelica_metatype _outWithin = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _path;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (23 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT26), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT25;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
tmpMeta7 = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, _path);
tmpMeta1 = tmpMeta7;
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
DLLDirection
modelica_metatype omc_InteractiveUtil_makeAnnotationArrayValue(threadData_t *threadData, modelica_metatype _annotations)
{
modelica_metatype _arr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar21;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar20;
modelica_integer tmp4;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = _annotations;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar21 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar21;
while(1) {
tmp4 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar20 = omc_ValuesMake_makeCodeTypeNameStr(threadData, _s);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar20,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar21;
}
_arr = omc_ValuesMake_makeArray(threadData, tmpMeta1);
_return: OMC_LABEL_UNUSED
return _arr;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_accessClass(threadData_t *threadData, modelica_metatype _classPath, modelica_metatype _program, modelica_fnptr _fn, modelica_boolean _evaluateParams, modelica_boolean _graphicsExpMode, modelica_integer _accessLevel)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _result = NULL;
modelica_integer _access;
modelica_boolean _silent;
modelica_boolean _eval_params;
modelica_boolean _graphics_exp_mode;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_silent = 0;
_eval_params = omc_Config_getEvaluateParametersInAnnotations(threadData);
_graphics_exp_mode = omc_Config_getGraphicsExpMode(threadData);
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
_access = omc_Interactive_checkAccessAnnotationAndEncryption(threadData, _classPath, _program);
if(((modelica_integer)_access < (modelica_integer)_accessLevel))
{
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addMessage(threadData, _OMC_LIT30, tmpMeta5);
_result = omc_ValuesMake_makeBoolean(threadData, 0 /* false */);
goto _return;
}
_silent = (!omc_Flags_isSet(threadData, _OMC_LIT33));
if(_silent)
{
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT34);
}
omc_Config_setEvaluateParametersInAnnotations(threadData, _evaluateParams);
omc_Config_setGraphicsExpMode(threadData, _graphicsExpMode);
_result = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 2))), _classPath, _program, mmc_mk_integer((modelica_integer)_access)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fn), 1)))) (threadData, _classPath, _program, mmc_mk_integer((modelica_integer)_access));
goto tmp2_done;
}
case 1: {
_result = omc_ValuesMake_makeBoolean(threadData, 0 /* false */);
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
if(_silent)
{
omc_ErrorExt_rollBack(threadData, _OMC_LIT34);
}
omc_Config_setGraphicsExpMode(threadData, _graphics_exp_mode);
omc_Config_setEvaluateParametersInAnnotations(threadData, _eval_params);
_return: OMC_LABEL_UNUSED
threadData->mmc_jumper = old_mmc_jumper;
return _result;
}
modelica_metatype boxptr_InteractiveUtil_accessClass(threadData_t *threadData, modelica_metatype _classPath, modelica_metatype _program, modelica_fnptr _fn, modelica_metatype _evaluateParams, modelica_metatype _graphicsExpMode, modelica_metatype _accessLevel)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _result = NULL;
tmp1 = mmc_unbox_integer(_evaluateParams);
tmp2 = mmc_unbox_integer(_graphicsExpMode);
tmp3 = mmc_unbox_integer(_accessLevel);
_result = omc_InteractiveUtil_accessClass(threadData, _classPath, _program, _fn, tmp1, tmp2, tmp3);
return _result;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_makeModifierFromArgs(threadData_t *threadData, modelica_metatype _bindingExp, modelica_metatype _modifier, modelica_metatype _info, modelica_metatype _oldModifier)
{
modelica_metatype _outModifier = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _bindingExp;
tmp4_2 = _modifier;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta1 = _oldModifier;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta1 = mmc_mk_some(_modifier);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
tmpMeta9 = mmc_mk_box3(4, &Absyn_EqMod_EQMOD__desc, _bindingExp, _info);
tmpMeta10 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_modifier), 2))), tmpMeta9);
tmpMeta1 = mmc_mk_some(tmpMeta10);
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
_outModifier = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outModifier;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_makeCommentFromArgs(threadData_t *threadData, modelica_metatype _commentExp, modelica_metatype _annotationExp, modelica_metatype _oldComment)
{
modelica_metatype _comment = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta15;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _commentExp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta1 = mmc_mk_none();
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta1 = mmc_mk_some((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_commentExp), 2))));
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
_cmt = tmpMeta1;
{
modelica_metatype tmp10_1;
tmp10_1 = _annotationExp;
{
volatile mmc_switch_type tmp10;
int tmp11;
tmp10 = 0;
for (; tmp10 < 2; tmp10++) {
switch (MMC_SWITCH_CAST(tmp10)) {
case 0: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp10_1,16,1) == 0) goto tmp9_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp10_1), 2));
if (!listEmpty(tmpMeta12)) goto tmp9_end;
tmpMeta7 = mmc_mk_none();
goto tmp9_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
tmpMeta13 = mmc_mk_cons(omc_InteractiveUtil_recordConstructorToModification(threadData, _annotationExp), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta14 = mmc_mk_box2(3, &Absyn_Annotation_ANNOTATION__desc, tmpMeta13);
tmpMeta7 = mmc_mk_some(tmpMeta14);
goto tmp9_done;
}
}
goto tmp9_end;
tmp9_end: ;
}
goto goto_8;
goto_8:;
MMC_THROW_INTERNAL();
goto tmp9_done;
tmp9_done:;
}
}
_ann = tmpMeta7;
if((isSome(_cmt) || isSome(_ann)))
{
_cmt = (isSome(_cmt)?_cmt:omc_AbsynUtil_getCommentOptComment(threadData, _oldComment));
_ann = (isSome(_ann)?_ann:omc_AbsynUtil_getCommentOptAnnotation(threadData, _oldComment));
tmpMeta15 = mmc_mk_box3(3, &Absyn_Comment_COMMENT__desc, _ann, _cmt);
_comment = mmc_mk_some(tmpMeta15);
}
else
{
_comment = _oldComment;
}
_return: OMC_LABEL_UNUSED
return _comment;
}
static modelica_metatype closure6_AbsynUtil_setElementType(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_element)
{
modelica_metatype typeSpec = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype allowMultipleComponents = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_AbsynUtil_setElementType(thData, $in_element, typeSpec, allowMultipleComponents);
}
DLLDirection
modelica_metatype omc_InteractiveUtil_setElementType(threadData_t *threadData, modelica_metatype _elementPath, modelica_metatype _className, modelica_metatype __omcQ_24in_5Fprogram, modelica_boolean *out_success)
{
modelica_metatype _program = NULL;
modelica_boolean _success;
modelica_metatype _elem_opt = NULL;
modelica_metatype _ty = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_program = __omcQ_24in_5Fprogram;
_success = 1;
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
_ty = omc_AbsynUtil_crefToTypeSpec(threadData, _className);
tmpMeta5 = mmc_mk_box2(0, _ty, mmc_mk_boolean(0 /* false */));
_program = omc_InteractiveUtil_transformPathedElementInProgram(threadData, _elementPath, (modelica_fnptr) mmc_mk_box2(0,closure6_AbsynUtil_setElementType,tmpMeta5), _program ,&_elem_opt ,&_success);
if(_success)
{
omc_SymbolTable_setAbsynElement(threadData, _program, omc_Util_getOption(threadData, _elem_opt), _elementPath);
}
goto tmp2_done;
}
case 1: {
_success = 0;
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
if (out_success) { *out_success = _success; }
return _program;
}
modelica_metatype boxptr_InteractiveUtil_setElementType(threadData_t *threadData, modelica_metatype _elementPath, modelica_metatype _className, modelica_metatype __omcQ_24in_5Fprogram, modelica_metatype *out_success)
{
modelica_boolean _success;
modelica_metatype _program = NULL;
_program = omc_InteractiveUtil_setElementType(threadData, _elementPath, _className, __omcQ_24in_5Fprogram, &_success);
if (out_success) { *out_success = mmc_mk_icon(_success); }
return _program;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getInheritedAnnotation(threadData_t *threadData, modelica_metatype _modelPath, modelica_string _annotationName, modelica_metatype _program, modelica_boolean _printConflictWarning)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _outAnnotation = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _extends_paths = NULL;
modelica_metatype _extends_oannl = NULL;
modelica_metatype _extends_ann = NULL;
modelica_metatype _extends_ann2 = NULL;
modelica_metatype _extends_path = NULL;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outAnnotation = mmc_mk_none();
_cls = omc_ProgramUtil_getPathedClassInProgram(threadData, _modelPath, _program, 0 /* false */, 0 /* false */);
_outAnnotation = omc_AbsynUtil_lookupClassAnnotation(threadData, _cls, _annotationName);
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT35);
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
_extends_paths = omc_NFApi_getInheritedClasses(threadData, _modelPath, _program);
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
_extends_paths = tmpMeta5;
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
omc_ErrorExt_rollBack(threadData, _OMC_LIT35);
if(listEmpty(_extends_paths))
{
goto _return;
}
{
modelica_metatype __omcQ_24tmpVar23;
modelica_metatype* tmp7;
modelica_metatype tmpMeta8;
modelica_metatype __omcQ_24tmpVar22;
modelica_integer tmp9;
modelica_metatype _ep_loopVar = 0;
modelica_metatype _ep;
_ep_loopVar = _extends_paths;
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar23 = tmpMeta8;
tmp7 = &__omcQ_24tmpVar23;
while(1) {
tmp9 = 1;
if (!listEmpty(_ep_loopVar)) {
_ep = MMC_CAR(_ep_loopVar);
_ep_loopVar = MMC_CDR(_ep_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar22 = omc_InteractiveUtil_getInheritedAnnotation(threadData, _ep, _annotationName, _program, 1 /* true */);
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar22,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp9 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp7 = mmc_mk_nil();
tmpMeta6 = __omcQ_24tmpVar23;
}
_extends_oannl = tmpMeta6;
while(1)
{
if(!(!listEmpty(_extends_oannl))) break;
if(isSome(listHead(_extends_oannl)))
{
_extends_ann = omc_Util_getOption(threadData, listHead(_extends_oannl));
if(isSome(_outAnnotation))
{
_outAnnotation = mmc_mk_some(omc_AbsynUtil_mergeModifiers(threadData, omc_Util_getOption(threadData, _outAnnotation), _extends_ann));
}
else
{
_outAnnotation = mmc_mk_some(_extends_ann);
}
if(_printConflictWarning)
{
tmpMeta10 = _extends_paths;
if (listEmpty(tmpMeta10)) MMC_THROW_INTERNAL();
tmpMeta11 = MMC_CAR(tmpMeta10);
tmpMeta12 = MMC_CDR(tmpMeta10);
_extends_path = tmpMeta11;
_extends_paths = tmpMeta12;
{
modelica_metatype _a;
for (tmpMeta13 = listRest(_extends_oannl); !listEmpty(tmpMeta13); tmpMeta13=MMC_CDR(tmpMeta13))
{
_a = MMC_CAR(tmpMeta13);
if(isSome(_a))
{
tmpMeta14 = _a;
if (optionNone(tmpMeta14)) MMC_THROW_INTERNAL();
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 1));
_extends_ann2 = tmpMeta15;
if((!valueEq(_extends_ann, _extends_ann2)))
{
tmpMeta16 = mmc_mk_cons(_annotationName, mmc_mk_cons(omc_AbsynUtil_pathString(threadData, _modelPath, _OMC_LIT39, 1 /* true */, 0 /* false */), mmc_mk_cons(omc_Dump_unparseModificationStr(threadData, _extends_ann), mmc_mk_cons(omc_AbsynUtil_pathString(threadData, _extends_path, _OMC_LIT39, 1 /* true */, 0 /* false */), mmc_mk_cons(omc_Dump_unparseModificationStr(threadData, _extends_ann2), mmc_mk_cons(omc_AbsynUtil_pathString(threadData, listHead(_extends_paths), _OMC_LIT39, 1 /* true */, 0 /* false */), MMC_REFSTRUCTLIT(mmc_nil)))))));
omc_Error_addMessage(threadData, _OMC_LIT38, tmpMeta16);
break;
}
_extends_paths = listRest(_extends_paths);
}
}
}
}
goto _return;
}
_extends_oannl = listRest(_extends_oannl);
_extends_paths = listRest(_extends_paths);
}
_return: OMC_LABEL_UNUSED
threadData->mmc_jumper = old_mmc_jumper;
return _outAnnotation;
}
modelica_metatype boxptr_InteractiveUtil_getInheritedAnnotation(threadData_t *threadData, modelica_metatype _modelPath, modelica_metatype _annotationName, modelica_metatype _program, modelica_metatype _printConflictWarning)
{
modelica_integer tmp1;
modelica_metatype _outAnnotation = NULL;
tmp1 = mmc_unbox_integer(_printConflictWarning);
_outAnnotation = omc_InteractiveUtil_getInheritedAnnotation(threadData, _modelPath, _annotationName, _program, tmp1);
return _outAnnotation;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInComponent(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomponent, modelica_metatype _nameMap, modelica_boolean _renameElement)
{
modelica_metatype __omcQ_24mrfa_5F0 = NULL;
modelica_metatype __omcQ_24mrfa_5F1 = NULL;
modelica_metatype _component = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_component = __omcQ_24in_5Fcomponent;
if(_renameElement)
{
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_component), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[2] = omc_InteractiveUtil_renameElementsInIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_component), 2))), _nameMap);
_component = tmpMeta1;
}
__omcQ_24mrfa_5F0 = omc_InteractiveUtil_renameElementsInSubscripts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_component), 3))), _nameMap);
__omcQ_24mrfa_5F1 = omc_InteractiveUtil_renameElementsInModificationOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_component), 4))), _nameMap);
tmpMeta2 = mmc_mk_box4(3, &Absyn_Component_COMPONENT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_component), 2))), __omcQ_24mrfa_5F0, __omcQ_24mrfa_5F1);
_component = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _component;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_renameElementsInComponent(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomponent, modelica_metatype _nameMap, modelica_metatype _renameElement)
{
modelica_integer tmp1;
modelica_metatype _component = NULL;
tmp1 = mmc_unbox_integer(_renameElement);
_component = omc_InteractiveUtil_renameElementsInComponent(threadData, __omcQ_24in_5Fcomponent, _nameMap, tmp1);
return _component;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInComponentItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomponent, modelica_metatype _nameMap, modelica_boolean _renameElement)
{
modelica_metatype _component = NULL;
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_component = __omcQ_24in_5Fcomponent;
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_component), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[2] = omc_InteractiveUtil_renameElementsInComponent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_component), 2))), _nameMap, _renameElement);
_component = tmpMeta1;
if(isSome((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_component), 3)))))
{
tmpMeta2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_component), 3)));
if (optionNone(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 1));
_exp = tmpMeta3;
_exp = omc_AbsynUtil_traverseExp(threadData, _exp, boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_component), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[3] = mmc_mk_some(_exp);
_component = tmpMeta4;
}
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_component), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[4] = omc_InteractiveUtil_renameElementsInCommentOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_component), 4))), _nameMap);
_component = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _component;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_renameElementsInComponentItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomponent, modelica_metatype _nameMap, modelica_metatype _renameElement)
{
modelica_integer tmp1;
modelica_metatype _component = NULL;
tmp1 = mmc_unbox_integer(_renameElement);
_component = omc_InteractiveUtil_renameElementsInComponentItem(threadData, __omcQ_24in_5Fcomponent, _nameMap, tmp1);
return _component;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAttributes(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fattrs, modelica_metatype _nameMap)
{
modelica_metatype _attrs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_attrs = __omcQ_24in_5Fattrs;
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_attrs), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[8] = omc_InteractiveUtil_renameElementsInSubscripts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attrs), 8))), _nameMap);
_attrs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _attrs;
}
static modelica_metatype closure7_InteractiveUtil_renameElementsInSubscripts(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_subs)
{
modelica_metatype nameMap = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_InteractiveUtil_renameElementsInSubscripts(thData, $in_subs, nameMap);
}static modelica_metatype closure8_InteractiveUtil_renameElementsInSubscripts(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_subs)
{
modelica_metatype nameMap = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_InteractiveUtil_renameElementsInSubscripts(thData, $in_subs, nameMap);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInTypeSpec(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fspec, modelica_metatype _nameMap)
{
modelica_metatype _spec = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_spec = __omcQ_24in_5Fspec;
{
modelica_metatype tmp3_1;
tmp3_1 = _spec;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_spec), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = omc_InteractiveUtil_renameElementsInPath(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 2))), _nameMap);
_spec = tmpMeta5;
tmpMeta7 = mmc_mk_box1(0, _nameMap);
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_spec), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[3] = omc_Util_applyOption(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 3))), (modelica_fnptr) mmc_mk_box2(0,closure7_InteractiveUtil_renameElementsInSubscripts,tmpMeta7));
_spec = tmpMeta6;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_spec), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[2] = omc_InteractiveUtil_renameElementsInPath(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 2))), _nameMap);
_spec = tmpMeta8;
tmpMeta10 = mmc_mk_box1(0, _nameMap);
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_spec), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[4] = omc_Util_applyOption(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 4))), (modelica_fnptr) mmc_mk_box2(0,closure8_InteractiveUtil_renameElementsInSubscripts,tmpMeta10));
_spec = tmpMeta9;
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
return _spec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInExternalDecl(threadData_t *threadData, modelica_metatype __omcQ_24in_5FextDecl, modelica_metatype _nameMap)
{
modelica_metatype __omcQ_24mrfa_5F2 = NULL;
modelica_metatype __omcQ_24mrfa_5F3 = NULL;
modelica_metatype _extDecl = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_extDecl = __omcQ_24in_5FextDecl;
{
modelica_metatype __omcQ_24tmpVar25;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar24;
modelica_integer tmp4;
modelica_metatype _a_loopVar = 0;
modelica_metatype _a;
_a_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_extDecl), 5)));
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar25 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar25;
while(1) {
tmp4 = 1;
if (!listEmpty(_a_loopVar)) {
_a = MMC_CAR(_a_loopVar);
_a_loopVar = MMC_CDR(_a_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar24 = omc_InteractiveUtil_renameElementsInExp(threadData, _a, _nameMap, NULL);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar24,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar25;
}
__omcQ_24mrfa_5F2 = tmpMeta1;
__omcQ_24mrfa_5F3 = omc_InteractiveUtil_renameElementsInAnnotationOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_extDecl), 6))), _nameMap);
tmpMeta5 = mmc_mk_box6(3, &Absyn_ExternalDecl_EXTERNALDECL__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_extDecl), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_extDecl), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_extDecl), 4))), __omcQ_24mrfa_5F2, __omcQ_24mrfa_5F3);
_extDecl = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _extDecl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInSubscript(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsub, modelica_metatype _nameMap)
{
modelica_metatype _sub = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sub = __omcQ_24in_5Fsub;
{
modelica_metatype tmp3_1;
tmp3_1 = _sub;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_sub), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sub), 2))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_sub = tmpMeta5;
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
return _sub;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInSubscripts(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsubs, modelica_metatype _nameMap)
{
modelica_metatype _subs = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_subs = __omcQ_24in_5Fsubs;
{
modelica_metatype __omcQ_24tmpVar27;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar26;
modelica_integer tmp4;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = _subs;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar27 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar27;
while(1) {
tmp4 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar26 = omc_InteractiveUtil_renameElementsInSubscript(threadData, _s, _nameMap);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar26,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar27;
}
_subs = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _subs;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_InteractiveUtil_renameElementsInIdent(threadData_t *threadData, modelica_string __omcQ_24in_5Fident, modelica_metatype _nameMap)
{
modelica_string _ident = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ident = __omcQ_24in_5Fident;
_ident = omc_UnorderedMap_getOrDefault(threadData, _ident, _nameMap, _ident);
_return: OMC_LABEL_UNUSED
return _ident;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInPath(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpath, modelica_metatype _nameMap)
{
modelica_metatype _path = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_path = __omcQ_24in_5Fpath;
{
modelica_metatype tmp3_1;
tmp3_1 = _path;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta4;
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_path), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[2] = omc_InteractiveUtil_renameElementsInIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))), _nameMap);
_path = tmpMeta4;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_path), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = omc_InteractiveUtil_renameElementsInIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_path), 2))), _nameMap);
_path = tmpMeta5;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _path;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInCref(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcref, modelica_metatype _nameMap, modelica_boolean _onlySubs)
{
modelica_metatype _cref = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref = __omcQ_24in_5Fcref;
{
modelica_metatype tmp3_1;
tmp3_1 = _cref;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 4: {
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta10;
if((!_onlySubs))
{
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_cref), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[2] = omc_InteractiveUtil_renameElementsInIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))), _nameMap);
_cref = tmpMeta4;
}
{
modelica_metatype __omcQ_24tmpVar29;
modelica_metatype* tmp7;
modelica_metatype tmpMeta8;
modelica_metatype __omcQ_24tmpVar28;
modelica_integer tmp9;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 3)));
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar29 = tmpMeta8;
tmp7 = &__omcQ_24tmpVar29;
while(1) {
tmp9 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar28 = omc_InteractiveUtil_renameElementsInSubscript(threadData, _s, _nameMap);
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar28,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp9 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp7 = mmc_mk_nil();
tmpMeta6 = __omcQ_24tmpVar29;
}
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_cref), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[3] = tmpMeta6;
_cref = tmpMeta5;
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_cref), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[4] = omc_InteractiveUtil_renameElementsInCref(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4))), _nameMap, 1 /* true */);
_cref = tmpMeta10;
goto tmp2_done;
}
case 5: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if((!_onlySubs))
{
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_cref), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[2] = omc_InteractiveUtil_renameElementsInIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))), _nameMap);
_cref = tmpMeta11;
}
{
modelica_metatype __omcQ_24tmpVar31;
modelica_metatype* tmp14;
modelica_metatype tmpMeta15;
modelica_metatype __omcQ_24tmpVar30;
modelica_integer tmp16;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 3)));
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar31 = tmpMeta15;
tmp14 = &__omcQ_24tmpVar31;
while(1) {
tmp16 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp16--;
}
if (tmp16 == 0) {
__omcQ_24tmpVar30 = omc_InteractiveUtil_renameElementsInSubscript(threadData, _s, _nameMap);
*tmp14 = mmc_mk_cons(__omcQ_24tmpVar30,0);
tmp14 = &MMC_CDR(*tmp14);
} else if (tmp16 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp14 = mmc_mk_nil();
tmpMeta13 = __omcQ_24tmpVar31;
}
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_cref), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[3] = tmpMeta13;
_cref = tmpMeta12;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _cref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_renameElementsInCref(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcref, modelica_metatype _nameMap, modelica_metatype _onlySubs)
{
modelica_integer tmp1;
modelica_metatype _cref = NULL;
tmp1 = mmc_unbox_integer(_onlySubs);
_cref = omc_InteractiveUtil_renameElementsInCref(threadData, __omcQ_24in_5Fcref, _nameMap, tmp1);
return _cref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInExp(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5FnameMap, modelica_metatype *out_nameMap)
{
modelica_metatype _exp = NULL;
modelica_metatype _nameMap = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
_nameMap = __omcQ_24in_5FnameMap;
{
modelica_metatype tmp3_1;
tmp3_1 = _exp;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 5: {
modelica_metatype tmpMeta4;
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_exp), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[2] = omc_InteractiveUtil_renameElementsInCref(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 2))), _nameMap, 0 /* false */);
_exp = tmpMeta4;
goto tmp2_done;
}
case 14: {
modelica_metatype tmpMeta5;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_exp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = omc_InteractiveUtil_renameElementsInCref(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 2))), _nameMap, 0 /* false */);
_exp = tmpMeta5;
goto tmp2_done;
}
case 15: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_exp), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[2] = omc_InteractiveUtil_renameElementsInCref(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_exp), 2))), _nameMap, 0 /* false */);
_exp = tmpMeta6;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
if (out_nameMap) { *out_nameMap = _nameMap; }
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInEqMod(threadData_t *threadData, modelica_metatype __omcQ_24in_5FeqMod, modelica_metatype _nameMap)
{
modelica_metatype _eqMod = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_eqMod = __omcQ_24in_5FeqMod;
{
modelica_metatype tmp3_1;
tmp3_1 = _eqMod;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,2) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_eqMod), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqMod), 2))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_eqMod = tmpMeta5;
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
return _eqMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInModification(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fmod, modelica_metatype _nameMap)
{
modelica_metatype __omcQ_24mrfa_5F4 = NULL;
modelica_metatype __omcQ_24mrfa_5F5 = NULL;
modelica_metatype _mod = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_mod = __omcQ_24in_5Fmod;
{
modelica_metatype __omcQ_24tmpVar33;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar32;
modelica_integer tmp4;
modelica_metatype _a_loopVar = 0;
modelica_metatype _a;
_a_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 2)));
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar33 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar33;
while(1) {
tmp4 = 1;
if (!listEmpty(_a_loopVar)) {
_a = MMC_CAR(_a_loopVar);
_a_loopVar = MMC_CDR(_a_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar32 = omc_InteractiveUtil_renameElementsInElementArg(threadData, _a, _nameMap);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar32,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar33;
}
__omcQ_24mrfa_5F4 = tmpMeta1;
__omcQ_24mrfa_5F5 = omc_InteractiveUtil_renameElementsInEqMod(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 3))), _nameMap);
tmpMeta5 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, __omcQ_24mrfa_5F4, __omcQ_24mrfa_5F5);
_mod = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _mod;
}
static modelica_metatype closure9_InteractiveUtil_renameElementsInModification(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_mod)
{
modelica_metatype nameMap = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_InteractiveUtil_renameElementsInModification(thData, $in_mod, nameMap);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInModificationOpt(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fmod, modelica_metatype _nameMap)
{
modelica_metatype _mod = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_mod = __omcQ_24in_5Fmod;
tmpMeta1 = mmc_mk_box1(0, _nameMap);
_mod = omc_Util_applyOption(threadData, _mod, (modelica_fnptr) mmc_mk_box2(0,closure9_InteractiveUtil_renameElementsInModification,tmpMeta1));
_return: OMC_LABEL_UNUSED
return _mod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAnnotation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fann, modelica_metatype _nameMap)
{
modelica_metatype _ann = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ann = __omcQ_24in_5Fann;
{
modelica_metatype __omcQ_24tmpVar35;
modelica_metatype* tmp3;
modelica_metatype tmpMeta4;
modelica_metatype __omcQ_24tmpVar34;
modelica_integer tmp5;
modelica_metatype _a_loopVar = 0;
modelica_metatype _a;
_a_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ann), 2)));
tmpMeta4 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar35 = tmpMeta4;
tmp3 = &__omcQ_24tmpVar35;
while(1) {
tmp5 = 1;
if (!listEmpty(_a_loopVar)) {
_a = MMC_CAR(_a_loopVar);
_a_loopVar = MMC_CDR(_a_loopVar);
tmp5--;
}
if (tmp5 == 0) {
__omcQ_24tmpVar34 = omc_InteractiveUtil_renameElementsInElementArg(threadData, _a, _nameMap);
*tmp3 = mmc_mk_cons(__omcQ_24tmpVar34,0);
tmp3 = &MMC_CDR(*tmp3);
} else if (tmp5 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp3 = mmc_mk_nil();
tmpMeta2 = __omcQ_24tmpVar35;
}
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_ann), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[2] = tmpMeta2;
_ann = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _ann;
}
static modelica_metatype closure10_InteractiveUtil_renameElementsInAnnotation(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_ann)
{
modelica_metatype nameMap = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_InteractiveUtil_renameElementsInAnnotation(thData, $in_ann, nameMap);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAnnotationOpt(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fann, modelica_metatype _nameMap)
{
modelica_metatype _ann = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ann = __omcQ_24in_5Fann;
tmpMeta1 = mmc_mk_box1(0, _nameMap);
_ann = omc_Util_applyOption(threadData, _ann, (modelica_fnptr) mmc_mk_box2(0,closure10_InteractiveUtil_renameElementsInAnnotation,tmpMeta1));
_return: OMC_LABEL_UNUSED
return _ann;
}
static modelica_metatype closure11_InteractiveUtil_renameElementsInAnnotation(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_ann)
{
modelica_metatype nameMap = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_InteractiveUtil_renameElementsInAnnotation(thData, $in_ann, nameMap);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInComment(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomment, modelica_metatype _nameMap)
{
modelica_metatype _comment = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_comment = __omcQ_24in_5Fcomment;
tmpMeta2 = mmc_mk_box1(0, _nameMap);
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_comment), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[2] = omc_Util_applyOption(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_comment), 2))), (modelica_fnptr) mmc_mk_box2(0,closure11_InteractiveUtil_renameElementsInAnnotation,tmpMeta2));
_comment = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _comment;
}
static modelica_metatype closure12_InteractiveUtil_renameElementsInComment(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_comment)
{
modelica_metatype nameMap = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_InteractiveUtil_renameElementsInComment(thData, $in_comment, nameMap);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInCommentOpt(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcomment, modelica_metatype _nameMap)
{
modelica_metatype _comment = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_comment = __omcQ_24in_5Fcomment;
tmpMeta1 = mmc_mk_box1(0, _nameMap);
_comment = omc_Util_applyOption(threadData, _comment, (modelica_fnptr) mmc_mk_box2(0,closure12_InteractiveUtil_renameElementsInComment,tmpMeta1));
_return: OMC_LABEL_UNUSED
return _comment;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInConstrainClass(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcc, modelica_metatype _nameMap)
{
modelica_metatype __omcQ_24mrfa_5F6 = NULL;
modelica_metatype __omcQ_24mrfa_5F7 = NULL;
modelica_metatype _cc = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cc = __omcQ_24in_5Fcc;
__omcQ_24mrfa_5F6 = omc_InteractiveUtil_renameElementsInElementSpec(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cc), 2))), _nameMap, 1 /* true */);
__omcQ_24mrfa_5F7 = omc_InteractiveUtil_renameElementsInCommentOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cc), 3))), _nameMap);
tmpMeta1 = mmc_mk_box3(3, &Absyn_ConstrainClass_CONSTRAINCLASS__desc, __omcQ_24mrfa_5F6, __omcQ_24mrfa_5F7);
_cc = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _cc;
}
static modelica_metatype closure13_InteractiveUtil_renameElementsInConstrainClass(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_cc)
{
modelica_metatype nameMap = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_InteractiveUtil_renameElementsInConstrainClass(thData, $in_cc, nameMap);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInConstrainClassOpt(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcc, modelica_metatype _nameMap)
{
modelica_metatype _cc = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cc = __omcQ_24in_5Fcc;
tmpMeta1 = mmc_mk_box1(0, _nameMap);
_cc = omc_Util_applyOption(threadData, _cc, (modelica_fnptr) mmc_mk_box2(0,closure13_InteractiveUtil_renameElementsInConstrainClass,tmpMeta1));
_return: OMC_LABEL_UNUSED
return _cc;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInElementArg(threadData_t *threadData, modelica_metatype __omcQ_24in_5Farg, modelica_metatype _nameMap)
{
modelica_metatype _arg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp3_1;
tmp3_1 = _arg;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta4;
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_arg), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[5] = omc_InteractiveUtil_renameElementsInModificationOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 5))), _nameMap);
_arg = tmpMeta4;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_arg), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[5] = omc_InteractiveUtil_renameElementsInElementSpec(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 5))), _nameMap, 0 /* false */);
_arg = tmpMeta5;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_arg), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[6] = omc_InteractiveUtil_renameElementsInConstrainClassOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 6))), _nameMap);
_arg = tmpMeta6;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _arg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAlgorithmBranch(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fbranch, modelica_metatype _nameMap)
{
modelica_metatype _branch = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _body = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_branch = __omcQ_24in_5Fbranch;
tmpMeta1 = _branch;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_cond = tmpMeta2;
_body = tmpMeta3;
_cond = omc_AbsynUtil_traverseExp(threadData, _cond, boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_body = omc_InteractiveUtil_renameElementsInAlgorithmItems(threadData, _body, _nameMap);
tmpMeta4 = mmc_mk_box2(0, _cond, _body);
_branch = tmpMeta4;
_return: OMC_LABEL_UNUSED
return _branch;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAlgorithm(threadData_t *threadData, modelica_metatype __omcQ_24in_5Falg, modelica_metatype _nameMap)
{
modelica_metatype _alg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_alg = __omcQ_24in_5Falg;
{
modelica_metatype tmp3_1;
tmp3_1 = _alg;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_alg), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[2] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_alg = tmpMeta4;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_alg), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[3] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_alg = tmpMeta5;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta13;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_alg), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[2] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_alg = tmpMeta6;
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_alg), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[3] = omc_InteractiveUtil_renameElementsInAlgorithmItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))), _nameMap);
_alg = tmpMeta7;
{
modelica_metatype __omcQ_24tmpVar37;
modelica_metatype* tmp10;
modelica_metatype tmpMeta11;
modelica_metatype __omcQ_24tmpVar36;
modelica_integer tmp12;
modelica_metatype _b_loopVar = 0;
modelica_metatype _b;
_b_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 4)));
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar37 = tmpMeta11;
tmp10 = &__omcQ_24tmpVar37;
while(1) {
tmp12 = 1;
if (!listEmpty(_b_loopVar)) {
_b = MMC_CAR(_b_loopVar);
_b_loopVar = MMC_CDR(_b_loopVar);
tmp12--;
}
if (tmp12 == 0) {
__omcQ_24tmpVar36 = omc_InteractiveUtil_renameElementsInAlgorithmBranch(threadData, _b, _nameMap);
*tmp10 = mmc_mk_cons(__omcQ_24tmpVar36,0);
tmp10 = &MMC_CDR(*tmp10);
} else if (tmp12 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp10 = mmc_mk_nil();
tmpMeta9 = __omcQ_24tmpVar37;
}
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_alg), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[4] = tmpMeta9;
_alg = tmpMeta8;
tmpMeta13 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta13), MMC_UNTAGPTR(_alg), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta13))[5] = omc_InteractiveUtil_renameElementsInAlgorithmItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 5))), _nameMap);
_alg = tmpMeta13;
goto tmp2_done;
}
case 5: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta19;
{
modelica_metatype __omcQ_24tmpVar39;
modelica_metatype* tmp16;
modelica_metatype tmpMeta17;
modelica_metatype __omcQ_24tmpVar38;
modelica_integer tmp18;
modelica_metatype _i_loopVar = 0;
modelica_metatype _i;
_i_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2)));
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar39 = tmpMeta17;
tmp16 = &__omcQ_24tmpVar39;
while(1) {
tmp18 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp18--;
}
if (tmp18 == 0) {
__omcQ_24tmpVar38 = omc_InteractiveUtil_renameElementsInIterator(threadData, _i, _nameMap);
*tmp16 = mmc_mk_cons(__omcQ_24tmpVar38,0);
tmp16 = &MMC_CDR(*tmp16);
} else if (tmp18 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp16 = mmc_mk_nil();
tmpMeta15 = __omcQ_24tmpVar39;
}
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_alg), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[2] = tmpMeta15;
_alg = tmpMeta14;
tmpMeta19 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta19), MMC_UNTAGPTR(_alg), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta19))[3] = omc_InteractiveUtil_renameElementsInAlgorithmItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))), _nameMap);
_alg = tmpMeta19;
goto tmp2_done;
}
case 6: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta25;
{
modelica_metatype __omcQ_24tmpVar41;
modelica_metatype* tmp22;
modelica_metatype tmpMeta23;
modelica_metatype __omcQ_24tmpVar40;
modelica_integer tmp24;
modelica_metatype _i_loopVar = 0;
modelica_metatype _i;
_i_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2)));
tmpMeta23 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar41 = tmpMeta23;
tmp22 = &__omcQ_24tmpVar41;
while(1) {
tmp24 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp24--;
}
if (tmp24 == 0) {
__omcQ_24tmpVar40 = omc_InteractiveUtil_renameElementsInIterator(threadData, _i, _nameMap);
*tmp22 = mmc_mk_cons(__omcQ_24tmpVar40,0);
tmp22 = &MMC_CDR(*tmp22);
} else if (tmp24 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp22 = mmc_mk_nil();
tmpMeta21 = __omcQ_24tmpVar41;
}
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_alg), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta20))[2] = tmpMeta21;
_alg = tmpMeta20;
tmpMeta25 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta25), MMC_UNTAGPTR(_alg), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta25))[3] = omc_InteractiveUtil_renameElementsInAlgorithmItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))), _nameMap);
_alg = tmpMeta25;
goto tmp2_done;
}
case 7: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
tmpMeta26 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta26), MMC_UNTAGPTR(_alg), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta26))[2] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_alg = tmpMeta26;
tmpMeta27 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta27), MMC_UNTAGPTR(_alg), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta27))[3] = omc_InteractiveUtil_renameElementsInAlgorithmItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))), _nameMap);
_alg = tmpMeta27;
goto tmp2_done;
}
case 8: {
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
tmpMeta28 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta28), MMC_UNTAGPTR(_alg), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta28))[2] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_alg = tmpMeta28;
tmpMeta29 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta29), MMC_UNTAGPTR(_alg), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta29))[3] = omc_InteractiveUtil_renameElementsInAlgorithmItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))), _nameMap);
_alg = tmpMeta29;
{
modelica_metatype __omcQ_24tmpVar43;
modelica_metatype* tmp32;
modelica_metatype tmpMeta33;
modelica_metatype __omcQ_24tmpVar42;
modelica_integer tmp34;
modelica_metatype _b_loopVar = 0;
modelica_metatype _b;
_b_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 4)));
tmpMeta33 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar43 = tmpMeta33;
tmp32 = &__omcQ_24tmpVar43;
while(1) {
tmp34 = 1;
if (!listEmpty(_b_loopVar)) {
_b = MMC_CAR(_b_loopVar);
_b_loopVar = MMC_CDR(_b_loopVar);
tmp34--;
}
if (tmp34 == 0) {
__omcQ_24tmpVar42 = omc_InteractiveUtil_renameElementsInAlgorithmBranch(threadData, _b, _nameMap);
*tmp32 = mmc_mk_cons(__omcQ_24tmpVar42,0);
tmp32 = &MMC_CDR(*tmp32);
} else if (tmp34 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp32 = mmc_mk_nil();
tmpMeta31 = __omcQ_24tmpVar43;
}
tmpMeta30 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta30), MMC_UNTAGPTR(_alg), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta30))[4] = tmpMeta31;
_alg = tmpMeta30;
goto tmp2_done;
}
case 9: {
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
tmpMeta35 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta35), MMC_UNTAGPTR(_alg), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta35))[2] = omc_InteractiveUtil_renameElementsInCref(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), _nameMap, 0 /* false */);
_alg = tmpMeta35;
tmpMeta36 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta36), MMC_UNTAGPTR(_alg), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta36))[3] = omc_AbsynUtil_traverseExpBidirFunctionArgs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))), boxvar_InteractiveUtil_renameElementsInExp, boxvar_AbsynUtil_dummyTraverseExp, _nameMap, NULL);
_alg = tmpMeta36;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _alg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAlgorithmItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype _nameMap)
{
modelica_metatype _item = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_item = __omcQ_24in_5Fitem;
{
modelica_metatype tmp3_1;
tmp3_1 = _item;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,3) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_item), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = omc_InteractiveUtil_renameElementsInAlgorithm(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_item), 2))), _nameMap);
_item = tmpMeta5;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_item), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[3] = omc_InteractiveUtil_renameElementsInCommentOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_item), 3))), _nameMap);
_item = tmpMeta6;
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
return _item;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInAlgorithmItems(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitems, modelica_metatype _nameMap)
{
modelica_metatype _items = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_items = __omcQ_24in_5Fitems;
{
modelica_metatype __omcQ_24tmpVar45;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar44;
modelica_integer tmp4;
modelica_metatype _i_loopVar = 0;
modelica_metatype _i;
_i_loopVar = _items;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar45 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar45;
while(1) {
tmp4 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar44 = omc_InteractiveUtil_renameElementsInAlgorithmItem(threadData, _i, _nameMap);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar44,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar45;
}
_items = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _items;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInIterator(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fiter, modelica_metatype _nameMap)
{
modelica_metatype _iter = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_iter = __omcQ_24in_5Fiter;
if(isSome((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_iter), 4)))))
{
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_iter), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[4] = mmc_mk_some(omc_AbsynUtil_traverseExp(threadData, omc_Util_getOption(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_iter), 4)))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL));
_iter = tmpMeta1;
}
_return: OMC_LABEL_UNUSED
return _iter;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInEquationBranch(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fbranch, modelica_metatype _nameMap)
{
modelica_metatype _branch = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _body = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_branch = __omcQ_24in_5Fbranch;
tmpMeta1 = _branch;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_cond = tmpMeta2;
_body = tmpMeta3;
_cond = omc_AbsynUtil_traverseExp(threadData, _cond, boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_body = omc_InteractiveUtil_renameElementsInEquationItems(threadData, _body, _nameMap);
tmpMeta4 = mmc_mk_box2(0, _cond, _body);
_branch = tmpMeta4;
_return: OMC_LABEL_UNUSED
return _branch;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInEquation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Feq, modelica_metatype _nameMap)
{
modelica_metatype _eq = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_eq = __omcQ_24in_5Feq;
{
modelica_metatype tmp3_1;
tmp3_1 = _eq;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta11;
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_eq), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[2] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 2))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_eq = tmpMeta4;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_eq), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[3] = omc_InteractiveUtil_renameElementsInEquationItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3))), _nameMap);
_eq = tmpMeta5;
{
modelica_metatype __omcQ_24tmpVar47;
modelica_metatype* tmp8;
modelica_metatype tmpMeta9;
modelica_metatype __omcQ_24tmpVar46;
modelica_integer tmp10;
modelica_metatype _b_loopVar = 0;
modelica_metatype _b;
_b_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 4)));
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar47 = tmpMeta9;
tmp8 = &__omcQ_24tmpVar47;
while(1) {
tmp10 = 1;
if (!listEmpty(_b_loopVar)) {
_b = MMC_CAR(_b_loopVar);
_b_loopVar = MMC_CDR(_b_loopVar);
tmp10--;
}
if (tmp10 == 0) {
__omcQ_24tmpVar46 = omc_InteractiveUtil_renameElementsInEquationBranch(threadData, _b, _nameMap);
*tmp8 = mmc_mk_cons(__omcQ_24tmpVar46,0);
tmp8 = &MMC_CDR(*tmp8);
} else if (tmp10 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp8 = mmc_mk_nil();
tmpMeta7 = __omcQ_24tmpVar47;
}
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_eq), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[4] = tmpMeta7;
_eq = tmpMeta6;
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_eq), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[5] = omc_InteractiveUtil_renameElementsInEquationItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 5))), _nameMap);
_eq = tmpMeta11;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_eq), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[2] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 2))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_eq = tmpMeta12;
tmpMeta13 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta13), MMC_UNTAGPTR(_eq), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta13))[3] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_eq = tmpMeta13;
goto tmp2_done;
}
case 5: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_eq), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[2] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 2))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_eq = tmpMeta14;
tmpMeta15 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta15), MMC_UNTAGPTR(_eq), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta15))[3] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_eq = tmpMeta15;
goto tmp2_done;
}
case 6: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
tmpMeta16 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta16), MMC_UNTAGPTR(_eq), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta16))[2] = omc_InteractiveUtil_renameElementsInCref(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 2))), _nameMap, 0 /* false */);
_eq = tmpMeta16;
tmpMeta17 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta17), MMC_UNTAGPTR(_eq), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta17))[3] = omc_InteractiveUtil_renameElementsInCref(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3))), _nameMap, 0 /* false */);
_eq = tmpMeta17;
goto tmp2_done;
}
case 7: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta23;
{
modelica_metatype __omcQ_24tmpVar49;
modelica_metatype* tmp20;
modelica_metatype tmpMeta21;
modelica_metatype __omcQ_24tmpVar48;
modelica_integer tmp22;
modelica_metatype _i_loopVar = 0;
modelica_metatype _i;
_i_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 2)));
tmpMeta21 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar49 = tmpMeta21;
tmp20 = &__omcQ_24tmpVar49;
while(1) {
tmp22 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp22--;
}
if (tmp22 == 0) {
__omcQ_24tmpVar48 = omc_InteractiveUtil_renameElementsInIterator(threadData, _i, _nameMap);
*tmp20 = mmc_mk_cons(__omcQ_24tmpVar48,0);
tmp20 = &MMC_CDR(*tmp20);
} else if (tmp22 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp20 = mmc_mk_nil();
tmpMeta19 = __omcQ_24tmpVar49;
}
tmpMeta18 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta18), MMC_UNTAGPTR(_eq), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta18))[2] = tmpMeta19;
_eq = tmpMeta18;
tmpMeta23 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta23), MMC_UNTAGPTR(_eq), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta23))[3] = omc_InteractiveUtil_renameElementsInEquationItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3))), _nameMap);
_eq = tmpMeta23;
goto tmp2_done;
}
case 8: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
tmpMeta24 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta24), MMC_UNTAGPTR(_eq), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta24))[2] = omc_AbsynUtil_traverseExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 2))), boxvar_InteractiveUtil_renameElementsInExp, _nameMap, NULL);
_eq = tmpMeta24;
tmpMeta25 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta25), MMC_UNTAGPTR(_eq), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta25))[3] = omc_InteractiveUtil_renameElementsInEquationItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3))), _nameMap);
_eq = tmpMeta25;
{
modelica_metatype __omcQ_24tmpVar51;
modelica_metatype* tmp28;
modelica_metatype tmpMeta29;
modelica_metatype __omcQ_24tmpVar50;
modelica_integer tmp30;
modelica_metatype _b_loopVar = 0;
modelica_metatype _b;
_b_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 4)));
tmpMeta29 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar51 = tmpMeta29;
tmp28 = &__omcQ_24tmpVar51;
while(1) {
tmp30 = 1;
if (!listEmpty(_b_loopVar)) {
_b = MMC_CAR(_b_loopVar);
_b_loopVar = MMC_CDR(_b_loopVar);
tmp30--;
}
if (tmp30 == 0) {
__omcQ_24tmpVar50 = omc_InteractiveUtil_renameElementsInEquationBranch(threadData, _b, _nameMap);
*tmp28 = mmc_mk_cons(__omcQ_24tmpVar50,0);
tmp28 = &MMC_CDR(*tmp28);
} else if (tmp30 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp28 = mmc_mk_nil();
tmpMeta27 = __omcQ_24tmpVar51;
}
tmpMeta26 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta26), MMC_UNTAGPTR(_eq), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta26))[4] = tmpMeta27;
_eq = tmpMeta26;
goto tmp2_done;
}
case 9: {
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
tmpMeta31 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta31), MMC_UNTAGPTR(_eq), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta31))[2] = omc_InteractiveUtil_renameElementsInCref(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 2))), _nameMap, 0 /* false */);
_eq = tmpMeta31;
tmpMeta32 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta32), MMC_UNTAGPTR(_eq), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta32))[3] = omc_AbsynUtil_traverseExpBidirFunctionArgs(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3))), boxvar_InteractiveUtil_renameElementsInExp, boxvar_AbsynUtil_dummyTraverseExp, _nameMap, NULL);
_eq = tmpMeta32;
goto tmp2_done;
}
case 10: {
modelica_metatype tmpMeta33;
tmpMeta33 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta33), MMC_UNTAGPTR(_eq), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta33))[2] = omc_InteractiveUtil_renameElementsInEquationItem(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 2))), _nameMap);
_eq = tmpMeta33;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _eq;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInEquationItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype _nameMap)
{
modelica_metatype _item = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_item = __omcQ_24in_5Fitem;
{
modelica_metatype tmp3_1;
tmp3_1 = _item;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,3) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_item), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = omc_InteractiveUtil_renameElementsInEquation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_item), 2))), _nameMap);
_item = tmpMeta5;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_item), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[3] = omc_InteractiveUtil_renameElementsInCommentOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_item), 3))), _nameMap);
_item = tmpMeta6;
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
return _item;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInEquationItems(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitems, modelica_metatype _nameMap)
{
modelica_metatype _items = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_items = __omcQ_24in_5Fitems;
{
modelica_metatype __omcQ_24tmpVar53;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar52;
modelica_integer tmp4;
modelica_metatype _i_loopVar = 0;
modelica_metatype _i;
_i_loopVar = _items;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar53 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar53;
while(1) {
tmp4 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar52 = omc_InteractiveUtil_renameElementsInEquationItem(threadData, _i, _nameMap);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar52,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar53;
}
_items = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _items;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInElementItem(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype _nameMap)
{
modelica_metatype _item = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_item = __omcQ_24in_5Fitem;
{
modelica_metatype tmp3_1;
tmp3_1 = _item;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_item), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[2] = omc_InteractiveUtil_renameElementsInElement(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_item), 2))), _nameMap);
_item = tmpMeta5;
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
return _item;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInClassPart(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fpart, modelica_metatype _nameMap)
{
modelica_metatype _part = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_part = __omcQ_24in_5Fpart;
{
modelica_metatype tmp3_1;
tmp3_1 = _part;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
{
modelica_metatype __omcQ_24tmpVar55;
modelica_metatype* tmp6;
modelica_metatype tmpMeta7;
modelica_metatype __omcQ_24tmpVar54;
modelica_integer tmp8;
modelica_metatype _i_loopVar = 0;
modelica_metatype _i;
_i_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2)));
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar55 = tmpMeta7;
tmp6 = &__omcQ_24tmpVar55;
while(1) {
tmp8 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp8--;
}
if (tmp8 == 0) {
__omcQ_24tmpVar54 = omc_InteractiveUtil_renameElementsInElementItem(threadData, _i, _nameMap);
*tmp6 = mmc_mk_cons(__omcQ_24tmpVar54,0);
tmp6 = &MMC_CDR(*tmp6);
} else if (tmp8 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp6 = mmc_mk_nil();
tmpMeta5 = __omcQ_24tmpVar55;
}
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[2] = tmpMeta5;
_part = tmpMeta4;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
{
modelica_metatype __omcQ_24tmpVar57;
modelica_metatype* tmp11;
modelica_metatype tmpMeta12;
modelica_metatype __omcQ_24tmpVar56;
modelica_integer tmp13;
modelica_metatype _i_loopVar = 0;
modelica_metatype _i;
_i_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2)));
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar57 = tmpMeta12;
tmp11 = &__omcQ_24tmpVar57;
while(1) {
tmp13 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp13--;
}
if (tmp13 == 0) {
__omcQ_24tmpVar56 = omc_InteractiveUtil_renameElementsInElementItem(threadData, _i, _nameMap);
*tmp11 = mmc_mk_cons(__omcQ_24tmpVar56,0);
tmp11 = &MMC_CDR(*tmp11);
} else if (tmp13 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp11 = mmc_mk_nil();
tmpMeta10 = __omcQ_24tmpVar57;
}
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[2] = tmpMeta10;
_part = tmpMeta9;
goto tmp2_done;
}
case 5: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
{
modelica_metatype __omcQ_24tmpVar59;
modelica_metatype* tmp16;
modelica_metatype tmpMeta17;
modelica_metatype __omcQ_24tmpVar58;
modelica_integer tmp18;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2)));
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar59 = tmpMeta17;
tmp16 = &__omcQ_24tmpVar59;
while(1) {
tmp18 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp18--;
}
if (tmp18 == 0) {
__omcQ_24tmpVar58 = omc_InteractiveUtil_renameElementsInExp(threadData, _e, _nameMap, NULL);
*tmp16 = mmc_mk_cons(__omcQ_24tmpVar58,0);
tmp16 = &MMC_CDR(*tmp16);
} else if (tmp18 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp16 = mmc_mk_nil();
tmpMeta15 = __omcQ_24tmpVar59;
}
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[2] = tmpMeta15;
_part = tmpMeta14;
goto tmp2_done;
}
case 6: {
modelica_metatype tmpMeta19;
tmpMeta19 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta19), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta19))[2] = omc_InteractiveUtil_renameElementsInEquationItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2))), _nameMap);
_part = tmpMeta19;
goto tmp2_done;
}
case 7: {
modelica_metatype tmpMeta20;
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta20))[2] = omc_InteractiveUtil_renameElementsInEquationItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2))), _nameMap);
_part = tmpMeta20;
goto tmp2_done;
}
case 8: {
modelica_metatype tmpMeta21;
tmpMeta21 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta21), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta21))[2] = omc_InteractiveUtil_renameElementsInAlgorithmItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2))), _nameMap);
_part = tmpMeta21;
goto tmp2_done;
}
case 9: {
modelica_metatype tmpMeta22;
tmpMeta22 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta22), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta22))[2] = omc_InteractiveUtil_renameElementsInAlgorithmItems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2))), _nameMap);
_part = tmpMeta22;
goto tmp2_done;
}
case 10: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
tmpMeta23 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta23), MMC_UNTAGPTR(_part), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta23))[2] = omc_InteractiveUtil_renameElementsInExternalDecl(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2))), _nameMap);
_part = tmpMeta23;
tmpMeta24 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta24), MMC_UNTAGPTR(_part), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta24))[3] = omc_InteractiveUtil_renameElementsInAnnotationOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 3))), _nameMap);
_part = tmpMeta24;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _part;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInClassDef(threadData_t *threadData, modelica_metatype __omcQ_24in_5FclassDef, modelica_metatype _nameMap)
{
modelica_metatype _classDef = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_classDef = __omcQ_24in_5FclassDef;
{
modelica_metatype tmp3_1;
tmp3_1 = _classDef;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
{
modelica_metatype __omcQ_24tmpVar61;
modelica_metatype* tmp6;
modelica_metatype tmpMeta7;
modelica_metatype __omcQ_24tmpVar60;
modelica_integer tmp8;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_classDef), 4)));
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar61 = tmpMeta7;
tmp6 = &__omcQ_24tmpVar61;
while(1) {
tmp8 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp8--;
}
if (tmp8 == 0) {
__omcQ_24tmpVar60 = omc_InteractiveUtil_renameElementsInClassPart(threadData, _p, _nameMap);
*tmp6 = mmc_mk_cons(__omcQ_24tmpVar60,0);
tmp6 = &MMC_CDR(*tmp6);
} else if (tmp8 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp6 = mmc_mk_nil();
tmpMeta5 = __omcQ_24tmpVar61;
}
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_classDef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[4] = tmpMeta5;
_classDef = tmpMeta4;
{
modelica_metatype __omcQ_24tmpVar63;
modelica_metatype* tmp11;
modelica_metatype tmpMeta12;
modelica_metatype __omcQ_24tmpVar62;
modelica_integer tmp13;
modelica_metatype _a_loopVar = 0;
modelica_metatype _a;
_a_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_classDef), 5)));
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar63 = tmpMeta12;
tmp11 = &__omcQ_24tmpVar63;
while(1) {
tmp13 = 1;
if (!listEmpty(_a_loopVar)) {
_a = MMC_CAR(_a_loopVar);
_a_loopVar = MMC_CDR(_a_loopVar);
tmp13--;
}
if (tmp13 == 0) {
__omcQ_24tmpVar62 = omc_InteractiveUtil_renameElementsInAnnotation(threadData, _a, _nameMap);
*tmp11 = mmc_mk_cons(__omcQ_24tmpVar62,0);
tmp11 = &MMC_CDR(*tmp11);
} else if (tmp13 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp11 = mmc_mk_nil();
tmpMeta10 = __omcQ_24tmpVar63;
}
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_classDef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[5] = tmpMeta10;
_classDef = tmpMeta9;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta21;
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_classDef), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[2] = omc_InteractiveUtil_renameElementsInTypeSpec(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_classDef), 2))), _nameMap);
_classDef = tmpMeta14;
tmpMeta15 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta15), MMC_UNTAGPTR(_classDef), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta15))[3] = omc_InteractiveUtil_renameElementsInAttributes(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_classDef), 3))), _nameMap);
_classDef = tmpMeta15;
{
modelica_metatype __omcQ_24tmpVar65;
modelica_metatype* tmp18;
modelica_metatype tmpMeta19;
modelica_metatype __omcQ_24tmpVar64;
modelica_integer tmp20;
modelica_metatype _a_loopVar = 0;
modelica_metatype _a;
_a_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_classDef), 4)));
tmpMeta19 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar65 = tmpMeta19;
tmp18 = &__omcQ_24tmpVar65;
while(1) {
tmp20 = 1;
if (!listEmpty(_a_loopVar)) {
_a = MMC_CAR(_a_loopVar);
_a_loopVar = MMC_CDR(_a_loopVar);
tmp20--;
}
if (tmp20 == 0) {
__omcQ_24tmpVar64 = omc_InteractiveUtil_renameElementsInElementArg(threadData, _a, _nameMap);
*tmp18 = mmc_mk_cons(__omcQ_24tmpVar64,0);
tmp18 = &MMC_CDR(*tmp18);
} else if (tmp20 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp18 = mmc_mk_nil();
tmpMeta17 = __omcQ_24tmpVar65;
}
tmpMeta16 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta16), MMC_UNTAGPTR(_classDef), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta16))[4] = tmpMeta17;
_classDef = tmpMeta16;
tmpMeta21 = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta21), MMC_UNTAGPTR(_classDef), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta21))[5] = omc_InteractiveUtil_renameElementsInCommentOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_classDef), 5))), _nameMap);
_classDef = tmpMeta21;
goto tmp2_done;
}
case 7: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
{
modelica_metatype __omcQ_24tmpVar67;
modelica_metatype* tmp24;
modelica_metatype tmpMeta25;
modelica_metatype __omcQ_24tmpVar66;
modelica_integer tmp26;
modelica_metatype _a_loopVar = 0;
modelica_metatype _a;
_a_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_classDef), 3)));
tmpMeta25 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar67 = tmpMeta25;
tmp24 = &__omcQ_24tmpVar67;
while(1) {
tmp26 = 1;
if (!listEmpty(_a_loopVar)) {
_a = MMC_CAR(_a_loopVar);
_a_loopVar = MMC_CDR(_a_loopVar);
tmp26--;
}
if (tmp26 == 0) {
__omcQ_24tmpVar66 = omc_InteractiveUtil_renameElementsInElementArg(threadData, _a, _nameMap);
*tmp24 = mmc_mk_cons(__omcQ_24tmpVar66,0);
tmp24 = &MMC_CDR(*tmp24);
} else if (tmp26 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp24 = mmc_mk_nil();
tmpMeta23 = __omcQ_24tmpVar67;
}
tmpMeta22 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta22), MMC_UNTAGPTR(_classDef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta22))[3] = tmpMeta23;
_classDef = tmpMeta22;
{
modelica_metatype __omcQ_24tmpVar69;
modelica_metatype* tmp29;
modelica_metatype tmpMeta30;
modelica_metatype __omcQ_24tmpVar68;
modelica_integer tmp31;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_classDef), 5)));
tmpMeta30 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar69 = tmpMeta30;
tmp29 = &__omcQ_24tmpVar69;
while(1) {
tmp31 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp31--;
}
if (tmp31 == 0) {
__omcQ_24tmpVar68 = omc_InteractiveUtil_renameElementsInClassPart(threadData, _p, _nameMap);
*tmp29 = mmc_mk_cons(__omcQ_24tmpVar68,0);
tmp29 = &MMC_CDR(*tmp29);
} else if (tmp31 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp29 = mmc_mk_nil();
tmpMeta28 = __omcQ_24tmpVar69;
}
tmpMeta27 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta27), MMC_UNTAGPTR(_classDef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta27))[5] = tmpMeta28;
_classDef = tmpMeta27;
{
modelica_metatype __omcQ_24tmpVar71;
modelica_metatype* tmp34;
modelica_metatype tmpMeta35;
modelica_metatype __omcQ_24tmpVar70;
modelica_integer tmp36;
modelica_metatype _a_loopVar = 0;
modelica_metatype _a;
_a_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_classDef), 6)));
tmpMeta35 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar71 = tmpMeta35;
tmp34 = &__omcQ_24tmpVar71;
while(1) {
tmp36 = 1;
if (!listEmpty(_a_loopVar)) {
_a = MMC_CAR(_a_loopVar);
_a_loopVar = MMC_CDR(_a_loopVar);
tmp36--;
}
if (tmp36 == 0) {
__omcQ_24tmpVar70 = omc_InteractiveUtil_renameElementsInAnnotation(threadData, _a, _nameMap);
*tmp34 = mmc_mk_cons(__omcQ_24tmpVar70,0);
tmp34 = &MMC_CDR(*tmp34);
} else if (tmp36 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp34 = mmc_mk_nil();
tmpMeta33 = __omcQ_24tmpVar71;
}
tmpMeta32 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta32), MMC_UNTAGPTR(_classDef), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta32))[6] = tmpMeta33;
_classDef = tmpMeta32;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _classDef;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInClass(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype _nameMap, modelica_boolean _renameElement)
{
modelica_metatype _cls = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cls = __omcQ_24in_5Fcls;
if(_renameElement)
{
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[2] = omc_InteractiveUtil_renameElementsInIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 2))), _nameMap);
_cls = tmpMeta1;
}
tmpMeta2 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta2), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta2))[7] = omc_InteractiveUtil_renameElementsInClassDef(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 7))), _nameMap);
_cls = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _cls;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_renameElementsInClass(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype _nameMap, modelica_metatype _renameElement)
{
modelica_integer tmp1;
modelica_metatype _cls = NULL;
tmp1 = mmc_unbox_integer(_renameElement);
_cls = omc_InteractiveUtil_renameElementsInClass(threadData, __omcQ_24in_5Fcls, _nameMap, tmp1);
return _cls;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInElementSpec(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fspec, modelica_metatype _nameMap, modelica_boolean _renameElement)
{
modelica_metatype _spec = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_spec = __omcQ_24in_5Fspec;
{
modelica_metatype tmp3_1;
tmp3_1 = _spec;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_metatype tmpMeta4;
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_spec), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[3] = omc_InteractiveUtil_renameElementsInClass(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 3))), _nameMap, _renameElement);
_spec = tmpMeta4;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta10;
{
modelica_metatype __omcQ_24tmpVar73;
modelica_metatype* tmp7;
modelica_metatype tmpMeta8;
modelica_metatype __omcQ_24tmpVar72;
modelica_integer tmp9;
modelica_metatype _a_loopVar = 0;
modelica_metatype _a;
_a_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 3)));
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar73 = tmpMeta8;
tmp7 = &__omcQ_24tmpVar73;
while(1) {
tmp9 = 1;
if (!listEmpty(_a_loopVar)) {
_a = MMC_CAR(_a_loopVar);
_a_loopVar = MMC_CDR(_a_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar72 = omc_InteractiveUtil_renameElementsInElementArg(threadData, _a, _nameMap);
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar72,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp9 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp7 = mmc_mk_nil();
tmpMeta6 = __omcQ_24tmpVar73;
}
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_spec), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[3] = tmpMeta6;
_spec = tmpMeta5;
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_spec), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[4] = omc_InteractiveUtil_renameElementsInAnnotationOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 4))), _nameMap);
_spec = tmpMeta10;
goto tmp2_done;
}
case 6: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_spec), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[2] = omc_InteractiveUtil_renameElementsInAttributes(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 2))), _nameMap);
_spec = tmpMeta11;
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_spec), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[3] = omc_InteractiveUtil_renameElementsInTypeSpec(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 3))), _nameMap);
_spec = tmpMeta12;
{
modelica_metatype __omcQ_24tmpVar75;
modelica_metatype* tmp15;
modelica_metatype tmpMeta16;
modelica_metatype __omcQ_24tmpVar74;
modelica_integer tmp17;
modelica_metatype _c_loopVar = 0;
modelica_metatype _c;
_c_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 4)));
tmpMeta16 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar75 = tmpMeta16;
tmp15 = &__omcQ_24tmpVar75;
while(1) {
tmp17 = 1;
if (!listEmpty(_c_loopVar)) {
_c = MMC_CAR(_c_loopVar);
_c_loopVar = MMC_CDR(_c_loopVar);
tmp17--;
}
if (tmp17 == 0) {
__omcQ_24tmpVar74 = omc_InteractiveUtil_renameElementsInComponentItem(threadData, _c, _nameMap, _renameElement);
*tmp15 = mmc_mk_cons(__omcQ_24tmpVar74,0);
tmp15 = &MMC_CDR(*tmp15);
} else if (tmp17 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp15 = mmc_mk_nil();
tmpMeta14 = __omcQ_24tmpVar75;
}
tmpMeta13 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta13), MMC_UNTAGPTR(_spec), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta13))[4] = tmpMeta14;
_spec = tmpMeta13;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
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
return _spec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_renameElementsInElementSpec(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fspec, modelica_metatype _nameMap, modelica_metatype _renameElement)
{
modelica_integer tmp1;
modelica_metatype _spec = NULL;
tmp1 = mmc_unbox_integer(_renameElement);
_spec = omc_InteractiveUtil_renameElementsInElementSpec(threadData, __omcQ_24in_5Fspec, _nameMap, tmp1);
return _spec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_renameElementsInElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _nameMap)
{
modelica_metatype _element = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = __omcQ_24in_5Felement;
{
modelica_metatype tmp3_1;
tmp3_1 = _element;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,6) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_element), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[5] = omc_InteractiveUtil_renameElementsInElementSpec(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5))), _nameMap, 1 /* true */);
_element = tmpMeta5;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_element), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[7] = omc_InteractiveUtil_renameElementsInConstrainClassOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 7))), _nameMap);
_element = tmpMeta6;
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
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_resolveMergeContentsConflicts(threadData_t *threadData, modelica_metatype _oldElement, modelica_metatype __omcQ_24in_5FnewContent)
{
modelica_metatype _newContent = NULL;
modelica_metatype _old_names = NULL;
modelica_metatype _rename_map = NULL;
modelica_string _new_name = NULL;
modelica_integer _index;
modelica_metatype _conflicting_names = NULL;
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
modelica_string tmp12;
modelica_metatype tmpMeta13;
modelica_string tmp14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_newContent = __omcQ_24in_5FnewContent;
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_conflicting_names = tmpMeta1;
_old_names = omc_UnorderedSet_new(threadData, boxvar_stringHashDjb2, boxvar_stringEq, ((modelica_integer) 13));
{
modelica_metatype _e;
for (tmpMeta2 = omc_AbsynUtil_getElementItemsInElement(threadData, _oldElement); !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_e = MMC_CAR(tmpMeta2);
{
modelica_metatype _name;
for (tmpMeta3 = omc_AbsynUtil_elementItemNames(threadData, _e); !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
{
_name = MMC_CAR(tmpMeta3);
omc_UnorderedSet_add(threadData, _name, _old_names);
}
}
}
}
_rename_map = omc_UnorderedMap_new(threadData, boxvar_stringHashDjb2, boxvar_stringEq, ((modelica_integer) 1));
{
modelica_metatype _e;
for (tmpMeta6 = omc_AbsynUtil_getElementItemsInClassDef(threadData, _newContent); !listEmpty(tmpMeta6); tmpMeta6=MMC_CDR(tmpMeta6))
{
_e = MMC_CAR(tmpMeta6);
{
modelica_metatype _name;
for (tmpMeta7 = omc_AbsynUtil_elementItemNames(threadData, _e); !listEmpty(tmpMeta7); tmpMeta7=MMC_CDR(tmpMeta7))
{
_name = MMC_CAR(tmpMeta7);
if(omc_UnorderedSet_contains(threadData, _name, _old_names))
{
tmpMeta8 = mmc_mk_cons(_name, _conflicting_names);
_conflicting_names = tmpMeta8;
}
else
{
omc_UnorderedSet_add(threadData, _name, _old_names);
}
}
}
}
}
if(listEmpty(_conflicting_names))
{
goto _return;
}
{
modelica_metatype _name;
for (tmpMeta11 = listReverse(_conflicting_names); !listEmpty(tmpMeta11); tmpMeta11=MMC_CDR(tmpMeta11))
{
_name = MMC_CAR(tmpMeta11);
_index = ((modelica_integer) 1);
tmp12 = modelica_integer_to_modelica_string(_index, ((modelica_integer) 0), 1 /* true */);
tmpMeta13 = stringAppend(_name,tmp12);
_new_name = tmpMeta13;
while(1)
{
if(!omc_UnorderedSet_contains(threadData, _new_name, _old_names)) break;
_index = ((modelica_integer) 1) + _index;
tmp14 = modelica_integer_to_modelica_string(_index, ((modelica_integer) 0), 1 /* true */);
tmpMeta15 = stringAppend(_name,tmp14);
_new_name = tmpMeta15;
}
omc_UnorderedMap_add(threadData, _name, _new_name, _rename_map);
omc_UnorderedSet_add(threadData, _new_name, _old_names);
}
}
if((!omc_UnorderedMap_isEmpty(threadData, _rename_map)))
{
_newContent = omc_InteractiveUtil_renameElementsInClassDef(threadData, _newContent, _rename_map);
}
_return: OMC_LABEL_UNUSED
return _newContent;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_mergeAnnotationLists(threadData_t *threadData, modelica_metatype _newAnnotations, modelica_metatype _oldAnnotations)
{
modelica_metatype _outAnnotations = NULL;
modelica_metatype _old_ann = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(listEmpty(_oldAnnotations))
{
_outAnnotations = _newAnnotations;
}
else
{
_old_ann = listHead(_oldAnnotations);
{
modelica_metatype _new_ann;
for (tmpMeta1 = _newAnnotations; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_new_ann = MMC_CAR(tmpMeta1);
_old_ann = omc_AbsynUtil_mergeAnnotations(threadData, _old_ann, _new_ann, 1 /* true */, 1 /* true */);
}
}
tmpMeta3 = mmc_mk_cons(_old_ann, listRest(_oldAnnotations));
_outAnnotations = tmpMeta3;
}
_return: OMC_LABEL_UNUSED
return _outAnnotations;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_mergeClassParts(threadData_t *threadData, modelica_metatype _newParts, modelica_metatype _oldParts)
{
modelica_metatype _outParts = NULL;
modelica_metatype _parts = NULL;
modelica_metatype _op = NULL;
modelica_metatype _p = NULL;
modelica_integer _index;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta29;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_parts = omc_Vector_fromList(threadData, _oldParts);
{
modelica_metatype _part;
for (tmpMeta1 = _newParts; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_part = MMC_CAR(tmpMeta1);
{
modelica_metatype tmp4_1;
tmp4_1 = _part;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
_op = omc_Vector_findLast(threadData, _parts, boxvar_AbsynUtil_isElementSection ,&_index);
{
modelica_metatype tmp7_1;
tmp7_1 = _op;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 2; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (optionNone(tmp7_1)) goto tmp6_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,1) == 0) goto tmp6_end;
_p = tmpMeta9;
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[2] = listAppend((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2))));
_part = tmpMeta10;
omc_Vector_updateNoBounds(threadData, _parts, _index, _part);
goto tmp6_done;
}
case 1: {
omc_Vector_insert(threadData, _parts, _part, modelica_integer_max((modelica_integer)(((modelica_integer) 1) + _index),(modelica_integer)(((modelica_integer) 1))));
goto tmp6_done;
}
}
goto tmp6_end;
tmp6_end: ;
}
goto goto_5;
goto_5:;
goto goto_2;
goto tmp6_done;
tmp6_done:;
}
}
;
goto tmp3_done;
}
case 4: {
_op = omc_Vector_findLast(threadData, _parts, boxvar_AbsynUtil_isElementSection ,&_index);
{
modelica_metatype tmp13_1;
tmp13_1 = _op;
{
volatile mmc_switch_type tmp13;
int tmp14;
tmp13 = 0;
for (; tmp13 < 2; tmp13++) {
switch (MMC_SWITCH_CAST(tmp13)) {
case 0: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (optionNone(tmp13_1)) goto tmp12_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp13_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,1,1) == 0) goto tmp12_end;
_p = tmpMeta15;
tmpMeta16 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta16), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta16))[2] = listAppend((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2))));
_part = tmpMeta16;
omc_Vector_updateNoBounds(threadData, _parts, _index, _part);
goto tmp12_done;
}
case 1: {
omc_Vector_insert(threadData, _parts, _part, modelica_integer_max((modelica_integer)(((modelica_integer) 1) + _index),(modelica_integer)(((modelica_integer) 1))));
goto tmp12_done;
}
}
goto tmp12_end;
tmp12_end: ;
}
goto goto_11;
goto_11:;
goto goto_2;
goto tmp12_done;
tmp12_done:;
}
}
;
goto tmp3_done;
}
case 6: {
_op = omc_Vector_findLast(threadData, _parts, boxvar_AbsynUtil_isEquationSection ,&_index);
{
modelica_metatype tmp19_1;
tmp19_1 = _op;
{
volatile mmc_switch_type tmp19;
int tmp20;
tmp19 = 0;
for (; tmp19 < 2; tmp19++) {
switch (MMC_SWITCH_CAST(tmp19)) {
case 0: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (optionNone(tmp19_1)) goto tmp18_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp19_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,3,1) == 0) goto tmp18_end;
_p = tmpMeta21;
tmpMeta22 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta22), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta22))[2] = listAppend((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2))));
_part = tmpMeta22;
omc_Vector_updateNoBounds(threadData, _parts, _index, _part);
goto tmp18_done;
}
case 1: {
if((_index == ((modelica_integer) -1)))
{
omc_Vector_findLast(threadData, _parts, boxvar_AbsynUtil_isElementSection ,&_index);
}
omc_Vector_insert(threadData, _parts, _part, modelica_integer_max((modelica_integer)(((modelica_integer) 1) + _index),(modelica_integer)(((modelica_integer) 1))));
goto tmp18_done;
}
}
goto tmp18_end;
tmp18_end: ;
}
goto goto_17;
goto_17:;
goto goto_2;
goto tmp18_done;
tmp18_done:;
}
}
;
goto tmp3_done;
}
case 7: {
_op = omc_Vector_findLast(threadData, _parts, boxvar_AbsynUtil_isEquationSection ,&_index);
{
modelica_metatype tmp25_1;
tmp25_1 = _op;
{
volatile mmc_switch_type tmp25;
int tmp26;
tmp25 = 0;
for (; tmp25 < 2; tmp25++) {
switch (MMC_SWITCH_CAST(tmp25)) {
case 0: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (optionNone(tmp25_1)) goto tmp24_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp25_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,4,1) == 0) goto tmp24_end;
_p = tmpMeta27;
tmpMeta28 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta28), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta28))[2] = listAppend((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_p), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2))));
_part = tmpMeta28;
omc_Vector_updateNoBounds(threadData, _parts, _index, _part);
goto tmp24_done;
}
case 1: {
if((_index == ((modelica_integer) -1)))
{
omc_Vector_findLast(threadData, _parts, boxvar_AbsynUtil_isElementSection ,&_index);
}
omc_Vector_insert(threadData, _parts, _part, modelica_integer_max((modelica_integer)(((modelica_integer) 1) + _index),(modelica_integer)(((modelica_integer) 1))));
goto tmp24_done;
}
}
goto tmp24_end;
tmp24_end: ;
}
goto goto_23;
goto_23:;
goto goto_2;
goto tmp24_done;
tmp24_done:;
}
}
;
goto tmp3_done;
}
case 10: {
omc_Vector_findLast(threadData, _parts, boxvar_AbsynUtil_isExternalPart ,&_index);
if((_index != ((modelica_integer) -1)))
{
omc_Vector_updateNoBounds(threadData, _parts, _index, _part);
}
else
{
omc_Vector_push(threadData, _parts, _part);
}
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
omc_Vector_push(threadData, _parts, _part);
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
_outParts = omc_Vector_toList(threadData, _parts);
_return: OMC_LABEL_UNUSED
return _outParts;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_mergeClassContents(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _newContent)
{
modelica_metatype _element = NULL;
modelica_metatype _spec = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _old_content = NULL;
modelica_metatype _new_content = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = __omcQ_24in_5Felement;
_new_content = omc_InteractiveUtil_resolveMergeContentsConflicts(threadData, _element, _newContent);
{
modelica_metatype tmp3_1;
tmp3_1 = _element;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,6) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,0,2) == 0) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 7));
_spec = tmpMeta5;
_cls = tmpMeta6;
_old_content = tmpMeta7;
{
modelica_metatype tmp10_1;modelica_metatype tmp10_2;
tmp10_1 = _old_content;
tmp10_2 = _new_content;
{
volatile mmc_switch_type tmp10;
int tmp11;
tmp10 = 0;
for (; tmp10 < 2; tmp10++) {
switch (MMC_SWITCH_CAST(tmp10)) {
case 0: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp10_1,0,5) == 0) goto tmp9_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp10_2,0,5) == 0) goto tmp9_end;
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_old_content), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[4] = omc_InteractiveUtil_mergeClassParts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_new_content), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_old_content), 4))));
_old_content = tmpMeta12;
tmpMeta13 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta13), MMC_UNTAGPTR(_old_content), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta13))[5] = omc_InteractiveUtil_mergeAnnotationLists(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_new_content), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_old_content), 5))));
_old_content = tmpMeta13;
goto tmp9_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp10_1,4,5) == 0) goto tmp9_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp10_2,0,5) == 0) goto tmp9_end;
tmpMeta14 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta14), MMC_UNTAGPTR(_old_content), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta14))[5] = omc_InteractiveUtil_mergeClassParts(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_new_content), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_old_content), 5))));
_old_content = tmpMeta14;
tmpMeta15 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta15), MMC_UNTAGPTR(_old_content), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta15))[6] = omc_InteractiveUtil_mergeAnnotationLists(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_new_content), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_old_content), 6))));
_old_content = tmpMeta15;
goto tmp9_done;
}
}
goto tmp9_end;
tmp9_end: ;
}
goto goto_8;
goto_8:;
goto goto_1;
goto tmp9_done;
tmp9_done:;
}
}
;
tmpMeta16 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta16), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta16))[7] = _old_content;
_cls = tmpMeta16;
tmpMeta17 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta17), MMC_UNTAGPTR(_spec), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta17))[3] = _cls;
_spec = tmpMeta17;
tmpMeta18 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta18), MMC_UNTAGPTR(_element), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta18))[5] = _spec;
_element = tmpMeta18;
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
return _element;
}
static modelica_metatype closure14_InteractiveUtil_mergeClassContents(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_element)
{
modelica_metatype newContent = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_InteractiveUtil_mergeClassContents(thData, $in_element, newContent);
}
DLLDirection
modelica_metatype omc_InteractiveUtil_loadClassContentString(threadData_t *threadData, modelica_string _content, modelica_metatype _classPath, modelica_integer _offsetX, modelica_integer _offsetY, modelica_metatype __omcQ_24in_5Fprogram, modelica_boolean *out_success)
{
modelica_metatype _program = NULL;
modelica_boolean _success;
modelica_metatype _parsed_body = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_program = __omcQ_24in_5Fprogram;
_success = 1;
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
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta5 = mmc_mk_cons(_OMC_LIT40, mmc_mk_cons(_content, mmc_mk_cons(_OMC_LIT41, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta6 = omc_Parser_parsestring(threadData, stringAppendList(tmpMeta5), _OMC_LIT42, omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT80), omc_Flags_getConfigBool(threadData, _OMC_LIT84));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (listEmpty(tmpMeta7)) goto goto_1;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 7));
if (!listEmpty(tmpMeta9)) goto goto_1;
_parsed_body = tmpMeta10;
_parsed_body = omc_InteractiveUtil_offsetAnnotationsInClassDef(threadData, _parsed_body, _offsetX, _offsetY);
tmpMeta11 = mmc_mk_box1(0, _parsed_body);
_program = omc_InteractiveUtil_transformPathedElementInProgram(threadData, _classPath, (modelica_fnptr) mmc_mk_box2(0,closure14_InteractiveUtil_mergeClassContents,tmpMeta11), _program ,NULL ,&_success);
goto tmp2_done;
}
case 1: {
_success = 0;
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
if (out_success) { *out_success = _success; }
return _program;
}
modelica_metatype boxptr_InteractiveUtil_loadClassContentString(threadData_t *threadData, modelica_metatype _content, modelica_metatype _classPath, modelica_metatype _offsetX, modelica_metatype _offsetY, modelica_metatype __omcQ_24in_5Fprogram, modelica_metatype *out_success)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_boolean _success;
modelica_metatype _program = NULL;
tmp1 = mmc_unbox_integer(_offsetX);
tmp2 = mmc_unbox_integer(_offsetY);
_program = omc_InteractiveUtil_loadClassContentString(threadData, _content, _classPath, tmp1, tmp2, __omcQ_24in_5Fprogram, &_success);
if (out_success) { *out_success = mmc_mk_icon(_success); }
return _program;
}
static modelica_metatype closure15_AbsynUtil_setElementAnnotation(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_element)
{
modelica_string name = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype inAnnotation = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_AbsynUtil_setElementAnnotation(thData, $in_element, name, inAnnotation);
}
DLLDirection
modelica_metatype omc_InteractiveUtil_setElementAnnotation(threadData_t *threadData, modelica_metatype _elementPath, modelica_metatype _annotationMod, modelica_metatype __omcQ_24in_5Fprogram, modelica_boolean *out_success)
{
modelica_metatype _program = NULL;
modelica_boolean _success;
modelica_metatype _ann = NULL;
modelica_string _name = NULL;
modelica_metatype _elem_opt = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_program = __omcQ_24in_5Fprogram;
_success = 1;
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
if(listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_annotationMod), 2)))))
{
_ann = mmc_mk_none();
}
else
{
tmpMeta5 = mmc_mk_box2(3, &Absyn_Annotation_ANNOTATION__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_annotationMod), 2))));
_ann = mmc_mk_some(tmpMeta5);
}
_name = omc_AbsynUtil_pathLastIdent(threadData, _elementPath);
tmpMeta6 = mmc_mk_box2(0, _name, _ann);
_program = omc_InteractiveUtil_transformPathedElementInProgram(threadData, _elementPath, (modelica_fnptr) mmc_mk_box2(0,closure15_AbsynUtil_setElementAnnotation,tmpMeta6), _program ,&_elem_opt ,&_success);
if(_success)
{
omc_SymbolTable_setAbsynElement(threadData, _program, omc_Util_getOption(threadData, _elem_opt), _elementPath);
}
goto tmp2_done;
}
case 1: {
_success = 0;
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
if (out_success) { *out_success = _success; }
return _program;
}
modelica_metatype boxptr_InteractiveUtil_setElementAnnotation(threadData_t *threadData, modelica_metatype _elementPath, modelica_metatype _annotationMod, modelica_metatype __omcQ_24in_5Fprogram, modelica_metatype *out_success)
{
modelica_boolean _success;
modelica_metatype _program = NULL;
_program = omc_InteractiveUtil_setElementAnnotation(threadData, _elementPath, _annotationMod, __omcQ_24in_5Fprogram, &_success);
if (out_success) { *out_success = mmc_mk_icon(_success); }
return _program;
}
DLLDirection
modelica_string omc_InteractiveUtil_getElementAnnotation(threadData_t *threadData, modelica_metatype _elementPath, modelica_metatype _program)
{
modelica_string _annotationString = NULL;
modelica_metatype _elem = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _eargs = NULL;
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
modelica_metatype tmpMeta7;
_elem = omc_InteractiveUtil_getPathedElementInProgram(threadData, _elementPath, _program);
_ann = omc_AbsynUtil_getElementAnnotation(threadData, _elem, omc_AbsynUtil_pathLastIdent(threadData, _elementPath));
if(isSome(_ann))
{
tmpMeta5 = _ann;
if (optionNone(tmpMeta5)) goto goto_1;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_eargs = tmpMeta7;
_annotationString = omc_List_toString(threadData, _eargs, boxvar_Dump_unparseElementArgStr, 3);
}
else
{
_annotationString = _OMC_LIT85;
}
goto tmp2_done;
}
case 1: {
_annotationString = _OMC_LIT13;
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
return _annotationString;
}
static modelica_metatype closure16_SCodeUtil_isElementNamed(threadData_t *thData, modelica_metatype closure, modelica_metatype element)
{
modelica_string name = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_SCodeUtil_isElementNamed(thData, name, element);
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getPathedSCodeElementInProgram(threadData_t *threadData, modelica_metatype _path, modelica_metatype _program)
{
modelica_metatype _element = NULL;
modelica_string _name = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_name = omc_AbsynUtil_pathFirstIdent(threadData, _path);
tmpMeta1 = mmc_mk_box1(0, _name);
_element = omc_List_find(threadData, _program, (modelica_fnptr) mmc_mk_box2(0,closure16_SCodeUtil_isElementNamed,tmpMeta1));
if((!omc_AbsynUtil_pathIsIdent(threadData, _path)))
{
_path = omc_AbsynUtil_pathRest(threadData, _path);
_program = omc_SCodeUtil_getClassElements(threadData, _element);
goto _tailrecursive;
;
}
_return: OMC_LABEL_UNUSED
return _element;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getPathedClassRestriction(threadData_t *threadData, modelica_metatype _path, modelica_metatype _program)
{
modelica_metatype _restriction = NULL;
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
tmpMeta5 = omc_ProgramUtil_getPathedClassInProgram(threadData, _path, _program, 0 /* false */, 0 /* false */);
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 6));
_restriction = tmpMeta6;
goto tmp2_done;
}
case 1: {
_restriction = _OMC_LIT86;
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
return _restriction;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInElementSpec(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fspec, modelica_metatype *out_element, modelica_boolean *out_success)
{
modelica_metatype _spec = NULL;
modelica_metatype _element = NULL;
modelica_boolean _success;
modelica_metatype _cls = NULL;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_spec = __omcQ_24in_5Fspec;
_element = mmc_mk_none();
{
modelica_metatype tmp4_1;
tmp4_1 = _spec;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
_cls = omc_InteractiveUtil_transformPathedElementInClass(threadData, _path, ((modelica_fnptr) _func), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_spec), 3))) ,&_element ,&_success);
if(_success)
{
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_spec), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[3] = _cls;
_spec = tmpMeta6;
}
tmp1 = _success;
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
_success = tmp1;
_return: OMC_LABEL_UNUSED
if (out_element) { *out_element = _element; }
if (out_success) { *out_success = _success; }
return _spec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInElementSpec(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fspec, modelica_metatype *out_element, modelica_metatype *out_success)
{
modelica_boolean _success;
modelica_metatype _spec = NULL;
_spec = omc_InteractiveUtil_transformPathedElementInElementSpec(threadData, _path, _func, __omcQ_24in_5Fspec, out_element, &_success);
if (out_success) { *out_success = mmc_mk_icon(_success); }
return _spec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInElement(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Felement, modelica_metatype *out_outElement, modelica_boolean *out_success)
{
modelica_metatype _element = NULL;
modelica_metatype _outElement = NULL;
modelica_boolean _success;
modelica_metatype _spec = NULL;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = __omcQ_24in_5Felement;
_outElement = mmc_mk_none();
{
modelica_metatype tmp4_1;
tmp4_1 = _element;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
_spec = omc_InteractiveUtil_transformPathedElementInElementSpec(threadData, _path, ((modelica_fnptr) _func), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5))) ,&_outElement ,&_success);
if(_success)
{
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_element), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[5] = _spec;
_element = tmpMeta6;
}
tmp1 = _success;
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
_success = tmp1;
_return: OMC_LABEL_UNUSED
if (out_outElement) { *out_outElement = _outElement; }
if (out_success) { *out_success = _success; }
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInElement(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Felement, modelica_metatype *out_outElement, modelica_metatype *out_success)
{
modelica_boolean _success;
modelica_metatype _element = NULL;
_element = omc_InteractiveUtil_transformPathedElementInElement(threadData, _path, _func, __omcQ_24in_5Felement, out_outElement, &_success);
if (out_success) { *out_success = mmc_mk_icon(_success); }
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInElementItem(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype *out_outElement, modelica_boolean *out_success)
{
modelica_metatype _item = NULL;
modelica_metatype _outElement = NULL;
modelica_boolean _success;
modelica_metatype _element = NULL;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_item = __omcQ_24in_5Fitem;
_outElement = mmc_mk_none();
{
modelica_metatype tmp4_1;
tmp4_1 = _item;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (!omc_AbsynUtil_isElementItemNamed(threadData, omc_AbsynUtil_pathFirstIdent(threadData, _path), _item)) goto tmp3_end;
if(omc_AbsynUtil_pathIsIdent(threadData, _path))
{
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_item), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_item), 2)))) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_item), 2))));
_item = tmpMeta6;
_outElement = mmc_mk_some((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_item), 2))));
_success = 1;
}
else
{
_element = omc_InteractiveUtil_transformPathedElementInElement(threadData, omc_AbsynUtil_pathRest(threadData, _path), ((modelica_fnptr) _func), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_item), 2))) ,&_outElement ,&_success);
if(_success)
{
tmpMeta7 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta7), MMC_UNTAGPTR(_item), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta7))[2] = _element;
_item = tmpMeta7;
}
}
tmp1 = _success;
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
_success = tmp1;
_return: OMC_LABEL_UNUSED
if (out_outElement) { *out_outElement = _outElement; }
if (out_success) { *out_success = _success; }
return _item;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInElementItem(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fitem, modelica_metatype *out_outElement, modelica_metatype *out_success)
{
modelica_boolean _success;
modelica_metatype _item = NULL;
_item = omc_InteractiveUtil_transformPathedElementInElementItem(threadData, _path, _func, __omcQ_24in_5Fitem, out_outElement, &_success);
if (out_success) { *out_success = mmc_mk_icon(_success); }
return _item;
}
static modelica_metatype closure17_InteractiveUtil_transformPathedElementInElementItem(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_item, modelica_metatype tmp5, modelica_metatype tmp6)
{
modelica_metatype path = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_fnptr func = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_transformPathedElementInElementItem(thData, path, func, $in_item, tmp5, tmp6);
}static modelica_metatype closure18_InteractiveUtil_transformPathedElementInElementItem(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_item, modelica_metatype tmp9, modelica_metatype tmp10)
{
modelica_metatype path = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_fnptr func = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_transformPathedElementInElementItem(thData, path, func, $in_item, tmp9, tmp10);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInClassPart(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fpart, modelica_metatype *out_element, modelica_boolean *out_success)
{
modelica_metatype _part = NULL;
modelica_metatype _element = NULL;
modelica_boolean _success;
modelica_metatype _items = NULL;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_part = __omcQ_24in_5Fpart;
_element = mmc_mk_none();
{
modelica_metatype tmp4_1;
tmp4_1 = _part;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta7 = mmc_mk_box2(0, _path, ((modelica_fnptr) _func));
_items = omc_InteractiveUtil_transformPathedElementInList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2))), (modelica_fnptr) mmc_mk_box2(0,closure17_InteractiveUtil_transformPathedElementInElementItem,tmpMeta7) ,&_element ,&_success);
if(_success)
{
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[2] = _items;
_part = tmpMeta8;
}
tmp1 = _success;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta11 = mmc_mk_box2(0, _path, ((modelica_fnptr) _func));
_items = omc_InteractiveUtil_transformPathedElementInList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_part), 2))), (modelica_fnptr) mmc_mk_box2(0,closure18_InteractiveUtil_transformPathedElementInElementItem,tmpMeta11) ,&_element ,&_success);
if(_success)
{
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_part), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[2] = _items;
_part = tmpMeta12;
}
tmp1 = _success;
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
_success = tmp1;
_return: OMC_LABEL_UNUSED
if (out_element) { *out_element = _element; }
if (out_success) { *out_success = _success; }
return _part;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInClassPart(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fpart, modelica_metatype *out_element, modelica_metatype *out_success)
{
modelica_boolean _success;
modelica_metatype _part = NULL;
_part = omc_InteractiveUtil_transformPathedElementInClassPart(threadData, _path, _func, __omcQ_24in_5Fpart, out_element, &_success);
if (out_success) { *out_success = mmc_mk_icon(_success); }
return _part;
}
static modelica_metatype closure19_InteractiveUtil_transformPathedElementInClassPart(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_part, modelica_metatype tmp5, modelica_metatype tmp6)
{
modelica_metatype path = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_fnptr func = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_transformPathedElementInClassPart(thData, path, func, $in_part, tmp5, tmp6);
}static modelica_metatype closure20_InteractiveUtil_transformPathedElementInClassPart(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_part, modelica_metatype tmp9, modelica_metatype tmp10)
{
modelica_metatype path = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_fnptr func = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_transformPathedElementInClassPart(thData, path, func, $in_part, tmp9, tmp10);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInClassDef(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fdef, modelica_metatype *out_element, modelica_boolean *out_success)
{
modelica_metatype _def = NULL;
modelica_metatype _element = NULL;
modelica_boolean _success;
modelica_metatype _parts = NULL;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_def = __omcQ_24in_5Fdef;
_element = mmc_mk_none();
{
modelica_metatype tmp4_1;
tmp4_1 = _def;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta7 = mmc_mk_box2(0, _path, ((modelica_fnptr) _func));
_parts = omc_InteractiveUtil_transformPathedElementInList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_def), 4))), (modelica_fnptr) mmc_mk_box2(0,closure19_InteractiveUtil_transformPathedElementInClassPart,tmpMeta7) ,&_element ,&_success);
if(_success)
{
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_def), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[4] = _parts;
_def = tmpMeta8;
}
tmp1 = _success;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta11 = mmc_mk_box2(0, _path, ((modelica_fnptr) _func));
_parts = omc_InteractiveUtil_transformPathedElementInList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_def), 5))), (modelica_fnptr) mmc_mk_box2(0,closure20_InteractiveUtil_transformPathedElementInClassPart,tmpMeta11) ,&_element ,&_success);
if(_success)
{
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_def), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta12))[5] = _parts;
_def = tmpMeta12;
}
tmp1 = _success;
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
_success = tmp1;
_return: OMC_LABEL_UNUSED
if (out_element) { *out_element = _element; }
if (out_success) { *out_success = _success; }
return _def;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInClassDef(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fdef, modelica_metatype *out_element, modelica_metatype *out_success)
{
modelica_boolean _success;
modelica_metatype _def = NULL;
_def = omc_InteractiveUtil_transformPathedElementInClassDef(threadData, _path, _func, __omcQ_24in_5Fdef, out_element, &_success);
if (out_success) { *out_success = mmc_mk_icon(_success); }
return _def;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInClass(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype *out_element, modelica_boolean *out_success)
{
modelica_metatype _cls = NULL;
modelica_metatype _element = NULL;
modelica_boolean _success;
modelica_metatype _def = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cls = __omcQ_24in_5Fcls;
_def = omc_InteractiveUtil_transformPathedElementInClassDef(threadData, _path, ((modelica_fnptr) _func), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 7))) ,&_element ,&_success);
if(_success)
{
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[7] = _def;
_cls = tmpMeta1;
}
_return: OMC_LABEL_UNUSED
if (out_element) { *out_element = _element; }
if (out_success) { *out_success = _success; }
return _cls;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInClass(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype *out_element, modelica_metatype *out_success)
{
modelica_boolean _success;
modelica_metatype _cls = NULL;
_cls = omc_InteractiveUtil_transformPathedElementInClass(threadData, _path, _func, __omcQ_24in_5Fcls, out_element, &_success);
if (out_success) { *out_success = mmc_mk_icon(_success); }
return _cls;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_transformPathedElementInProgram_transform__class(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype *out_outElement, modelica_boolean *out_found)
{
modelica_metatype _cls = NULL;
modelica_metatype _outElement = NULL;
modelica_boolean _found;
modelica_metatype _elem = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cls = __omcQ_24in_5Fcls;
_found = (stringEqual(omc_AbsynUtil_pathFirstIdent(threadData, _path), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 2)))));
if(_found)
{
if(omc_AbsynUtil_pathIsIdent(threadData, _path))
{
tmpMeta1 = mmc_mk_box3(3, &Absyn_ElementSpec_CLASSDEF__desc, mmc_mk_boolean(0 /* false */), _cls);
tmpMeta2 = mmc_mk_box7(3, &Absyn_Element_ELEMENT__desc, mmc_mk_boolean(0 /* false */), mmc_mk_none(), _OMC_LIT87, tmpMeta1, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 11))), mmc_mk_none());
_elem = tmpMeta2;
_elem = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _elem) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _elem);
_outElement = mmc_mk_some(_elem);
tmpMeta3 = _elem;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta3,0,6) == 0) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta4,0,2) == 0) MMC_THROW_INTERNAL();
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 3));
_cls = tmpMeta5;
}
else
{
_cls = omc_InteractiveUtil_transformPathedElementInClass(threadData, omc_AbsynUtil_pathRest(threadData, _path), ((modelica_fnptr) _func), _cls ,&_outElement ,&_found);
}
}
else
{
_outElement = mmc_mk_none();
}
_return: OMC_LABEL_UNUSED
if (out_outElement) { *out_outElement = _outElement; }
if (out_found) { *out_found = _found; }
return _cls;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_transformPathedElementInProgram_transform__class(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype *out_outElement, modelica_metatype *out_found)
{
modelica_boolean _found;
modelica_metatype _cls = NULL;
_cls = omc_InteractiveUtil_transformPathedElementInProgram_transform__class(threadData, _path, _func, __omcQ_24in_5Fcls, out_outElement, &_found);
if (out_found) { *out_found = mmc_mk_icon(_found); }
return _cls;
}
static modelica_metatype closure21_InteractiveUtil_transformPathedElementInProgram_transform__class(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_cls, modelica_metatype tmp1, modelica_metatype tmp2)
{
modelica_metatype path = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_fnptr func = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_transformPathedElementInProgram_transform__class(thData, path, func, $in_cls, tmp1, tmp2);
}
DLLDirection
modelica_metatype omc_InteractiveUtil_transformPathedElementInProgram(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fprogram, modelica_metatype *out_element, modelica_boolean *out_success)
{
modelica_metatype _program = NULL;
modelica_metatype _element = NULL;
modelica_boolean _success;
modelica_metatype _clss = NULL;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_program = __omcQ_24in_5Fprogram;
tmpMeta3 = mmc_mk_box2(0, _path, ((modelica_fnptr) _func));
_clss = omc_InteractiveUtil_transformPathedElementInList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_program), 2))), (modelica_fnptr) mmc_mk_box2(0,closure21_InteractiveUtil_transformPathedElementInProgram_transform__class,tmpMeta3) ,&_element ,&_success);
if(_success)
{
tmpMeta4 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta4), MMC_UNTAGPTR(_program), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta4))[2] = _clss;
_program = tmpMeta4;
}
_return: OMC_LABEL_UNUSED
if (out_element) { *out_element = _element; }
if (out_success) { *out_success = _success; }
return _program;
}
modelica_metatype boxptr_InteractiveUtil_transformPathedElementInProgram(threadData_t *threadData, modelica_metatype _path, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Fprogram, modelica_metatype *out_element, modelica_metatype *out_success)
{
modelica_boolean _success;
modelica_metatype _program = NULL;
_program = omc_InteractiveUtil_transformPathedElementInProgram(threadData, _path, _func, __omcQ_24in_5Fprogram, out_element, &_success);
if (out_success) { *out_success = mmc_mk_icon(_success); }
return _program;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_transformPathedElementInList(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outElement, modelica_boolean *out_outFound)
{
modelica_metatype _outList = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _outElement = NULL;
modelica_boolean _outFound;
modelica_metatype _e = NULL;
modelica_metatype _rest = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outList = tmpMeta1;
_outElement = mmc_mk_none();
_outFound = 0;
_rest = _inList;
while(1)
{
if(!((!listEmpty(_rest)) && (!_outFound))) break;
tmpMeta2 = _rest;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_e = tmpMeta3;
_rest = tmpMeta4;
tmpMeta8 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _e, &tmpMeta5, &tmpMeta6) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _e, &tmpMeta5, &tmpMeta6);
_e = tmpMeta8;
tmp7 = mmc_unbox_integer(tmpMeta6);
_outElement = tmpMeta5;
_outFound = tmp7;
tmpMeta9 = mmc_mk_cons(_e, _outList);
_outList = tmpMeta9;
}
_outList = omc_List_append__reverse(threadData, _outList, _rest);
_return: OMC_LABEL_UNUSED
if (out_outElement) { *out_outElement = _outElement; }
if (out_outFound) { *out_outFound = _outFound; }
return _outList;
}
modelica_metatype boxptr_InteractiveUtil_transformPathedElementInList(threadData_t *threadData, modelica_metatype _inList, modelica_fnptr _inFunc, modelica_metatype *out_outElement, modelica_metatype *out_outFound)
{
modelica_boolean _outFound;
modelica_metatype _outList = NULL;
modelica_metatype tmpMeta1;
_outList = omc_InteractiveUtil_transformPathedElementInList(threadData, _inList, _inFunc, out_outElement, &_outFound);
if (out_outFound) { *out_outFound = mmc_mk_icon(_outFound); }
return _outList;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getPathedExtendsInProgram(threadData_t *threadData, modelica_metatype _classPath, modelica_metatype _extendsPath, modelica_metatype _program)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _extendsSpec = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _env = NULL;
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
_cls = omc_ProgramUtil_getPathedClassInProgram(threadData, _classPath, _program, 0 /* false */, 0 /* false */);
_env = omc_Interactive_getClassEnv(threadData, _program, _classPath);
{
modelica_metatype _ext;
for (tmpMeta5 = omc_InteractiveUtil_getExtendsElementspecInClass(threadData, _cls); !listEmpty(tmpMeta5); tmpMeta5=MMC_CDR(tmpMeta5))
{
_ext = MMC_CAR(tmpMeta5);
_ext = omc_Interactive_makeExtendsFullyQualified(threadData, _ext, _env);
if(omc_AbsynUtil_pathEqual(threadData, _extendsPath, omc_AbsynUtil_elementSpecToPath(threadData, _ext)))
{
_extendsSpec = mmc_mk_some(_ext);
goto _return;
}
}
}
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
_extendsSpec = mmc_mk_none();
_return: OMC_LABEL_UNUSED
threadData->mmc_jumper = old_mmc_jumper;
return _extendsSpec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getPathedElementInElement(threadData_t *threadData, modelica_metatype _path, modelica_metatype _element)
{
modelica_metatype _outElement = NULL;
modelica_metatype _cls = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _element;
{
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_cls = tmpMeta7;
tmpMeta1 = omc_InteractiveUtil_getPathedElementInClass(threadData, _path, _cls);
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
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outElement = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getPathedElementInClassPart(threadData_t *threadData, modelica_metatype _path, modelica_metatype _part)
{
modelica_metatype _element = NULL;
modelica_metatype _e = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = mmc_mk_none();
{
modelica_metatype _item;
for (tmpMeta1 = omc_AbsynUtil_getElementItemsInClassPart(threadData, _part); !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_item = MMC_CAR(tmpMeta1);
if(omc_AbsynUtil_isElementItemNamed(threadData, omc_AbsynUtil_pathFirstIdent(threadData, _path), _item))
{
tmpMeta2 = _item;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,0,1) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
_e = tmpMeta3;
if(omc_AbsynUtil_pathIsIdent(threadData, _path))
{
_element = mmc_mk_some(_e);
}
else
{
_element = omc_InteractiveUtil_getPathedElementInElement(threadData, omc_AbsynUtil_pathRest(threadData, _path), _e);
}
break;
}
}
}
_return: OMC_LABEL_UNUSED
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getPathedElementInClass(threadData_t *threadData, modelica_metatype _path, modelica_metatype _cls)
{
modelica_metatype _element = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = mmc_mk_none();
{
modelica_metatype _part;
for (tmpMeta1 = omc_AbsynUtil_getClassPartsInClass(threadData, _cls); !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_part = MMC_CAR(tmpMeta1);
_element = omc_InteractiveUtil_getPathedElementInClassPart(threadData, _path, _part);
if(isSome(_element))
{
break;
}
}
}
_return: OMC_LABEL_UNUSED
return _element;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getPathedElementInProgram(threadData_t *threadData, modelica_metatype _path, modelica_metatype _program)
{
modelica_metatype _element = NULL;
modelica_metatype _cls = NULL;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
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
_cls = omc_ProgramUtil_getClassInProgram(threadData, omc_AbsynUtil_pathFirstIdent(threadData, _path), _program);
goto tmp2_done;
}
case 1: {
_cls = omc_ProgramUtil_getClassInProgram(threadData, omc_AbsynUtil_pathFirstIdent(threadData, _path), omc_FBuiltin_getInitialFunctions(threadData, NULL));
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
if(omc_AbsynUtil_pathIsIdent(threadData, _path))
{
tmpMeta5 = mmc_mk_box3(3, &Absyn_ElementSpec_CLASSDEF__desc, mmc_mk_boolean(0 /* false */), _cls);
tmpMeta6 = mmc_mk_box7(3, &Absyn_Element_ELEMENT__desc, mmc_mk_boolean(0 /* false */), mmc_mk_none(), _OMC_LIT87, tmpMeta5, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cls), 11))), mmc_mk_none());
_element = tmpMeta6;
}
else
{
tmpMeta7 = omc_InteractiveUtil_getPathedElementInClass(threadData, omc_AbsynUtil_pathRest(threadData, _path), _cls);
if (optionNone(tmpMeta7)) MMC_THROW_INTERNAL();
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_element = tmpMeta8;
}
_return: OMC_LABEL_UNUSED
return _element;
}
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
_outElements = omc_List_deleteMemberOnTrue(threadData, _name, _inElements, boxvar_ProgramUtil_classElementItemIsNamed, NULL);
_return: OMC_LABEL_UNUSED
return _outElements;
}
DLLDirection
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
_publst = omc_ProgramUtil_getPublicList(threadData, _parts);
_publst2 = omc_InteractiveUtil_removeClassInElementitemlist(threadData, _publst, _c1);
_parts2 = omc_ProgramUtil_replacePublicList(threadData, _parts, _publst2);
tmpMeta13 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars, _classAttrs, _parts2, _ann, _cmt);
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
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
_prolst = omc_ProgramUtil_getProtectedList(threadData, _parts);
_prolst2 = omc_InteractiveUtil_removeClassInElementitemlist(threadData, _prolst, _c1);
_parts2 = omc_ProgramUtil_replaceProtectedList(threadData, _parts, _prolst2);
tmpMeta21 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, _typeVars, _classAttrs, _parts2, _ann, _cmt);
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
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
_publst = omc_ProgramUtil_getPublicList(threadData, _parts);
_publst2 = omc_InteractiveUtil_removeClassInElementitemlist(threadData, _publst, _c1);
_parts2 = omc_ProgramUtil_replacePublicList(threadData, _parts, _publst2);
tmpMeta29 = mmc_mk_box6(7, &Absyn_ClassDef_CLASS__EXTENDS__desc, _bcname, _modif, _cmt, _parts2, _ann);
tmpMeta28 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta28), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
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
_prolst = omc_ProgramUtil_getProtectedList(threadData, _parts);
_prolst2 = omc_InteractiveUtil_removeClassInElementitemlist(threadData, _prolst, _c1);
_parts2 = omc_ProgramUtil_replaceProtectedList(threadData, _parts, _prolst2);
tmpMeta37 = mmc_mk_box6(7, &Absyn_ClassDef_CLASS__EXTENDS__desc, _bcname, _modif, _cmt, _parts2, _ann);
tmpMeta36 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta36), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
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
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 11));
_n = tmpMeta38;
_a = tmpMeta39;
_file_info = tmpMeta40;
tmpMeta41 = mmc_mk_cons(_n, mmc_mk_cons(_a, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT89, tmpMeta41, _file_info);
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
DLLDirection
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
if (0 /* false */ != tmp11) goto tmp4_end;
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
if (0 /* false */ != tmp19) goto tmp4_end;
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
DLLDirection
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
if (1 /* true */ != tmp4_2) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_elts = tmpMeta12;
_rest = tmpMeta11;
_c = tmp4_3;
_l1 = omc_InteractiveUtil_getClassnamesInEltsNoPartial(threadData, _elts, _c);
_l2 = omc_InteractiveUtil_getClassnamesInPartsNoPartial(threadData, _rest, 1 /* true */, _c);
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
_found = (((stringEqual(_c1_str, _from)) && (stringEqual(_c2_str, _to)))?1 /* true */:((stringEqual(_c1_str, _to)) && (stringEqual(_c2_str, _from))));
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
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
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
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
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
DLLDirection
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
_cdef = omc_ProgramUtil_getPathedClassInProgram(threadData, _path, _p, 0 /* false */, 0 /* false */);
_newcdef = omc_InteractiveUtil_updateConnectionNamesInClass(threadData, _cdef, _from, _to, _fromNew, _toNew);
tmpMeta6 = mmc_mk_cons(_newcdef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta7 = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, _modelwithin);
tmpMeta8 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta6, tmpMeta7);
_newp = omc_ProgramUtil_updateProgram(threadData, tmpMeta8, _p, 0 /* false */);
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
_cdef = omc_ProgramUtil_getPathedClassInProgram(threadData, _path, _p, 0 /* false */, 0 /* false */);
_newcdef = omc_InteractiveUtil_updateConnectionNamesInClass(threadData, _cdef, _from, _to, _fromNew, _toNew);
tmpMeta9 = mmc_mk_cons(_newcdef, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta10 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta9, _OMC_LIT25);
_newp = omc_ProgramUtil_updateProgram(threadData, tmpMeta10, _p, 0 /* false */);
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
DLLDirection
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
tmpMeta12 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta12), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
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
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_outClass), 12*sizeof(modelica_metatype));
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
DLLDirection
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
_cls = omc_ProgramUtil_getPathedClassInProgram(threadData, _class_path, _inProgram, 0 /* false */, 0 /* false */);
_cls = omc_InteractiveUtil_updateConnectionAnnotationInClass(threadData, _cls, _inFrom, _inTo, omc_InteractiveUtil_annotationListToAbsyn(threadData, _inAnnotation));
tmp2 = (modelica_boolean)omc_AbsynUtil_pathIsIdent(threadData, _class_path);
if(tmp2)
{
tmpMeta3 = _OMC_LIT25;
}
else
{
tmpMeta1 = mmc_mk_box2(3, &Absyn_Within_WITHIN__desc, omc_AbsynUtil_stripLast(threadData, _class_path));
tmpMeta3 = tmpMeta1;
}
_class_within = tmpMeta3;
tmpMeta4 = mmc_mk_cons(_cls, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta5 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta4, _class_within);
_outProgram = omc_ProgramUtil_updateProgram(threadData, tmpMeta5, _inProgram, 0 /* false */);
_return: OMC_LABEL_UNUSED
return _outProgram;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_InteractiveUtil_isSubtypeOf(threadData_t *threadData, modelica_metatype _classPath, modelica_metatype _baseClassPath, modelica_metatype _program)
{
modelica_boolean _res;
modelica_metatype _base_classes = NULL;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_base_classes = omc_InteractiveUtil_getAllInheritedClasses(threadData, _classPath, _program);
_res = omc_List_contains(threadData, _base_classes, _baseClassPath, boxvar_AbsynUtil_pathSuffixOfr);
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_isSubtypeOf(threadData_t *threadData, modelica_metatype _classPath, modelica_metatype _baseClassPath, modelica_metatype _program)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_InteractiveUtil_isSubtypeOf(threadData, _classPath, _baseClassPath, _program);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getAllSubtypeOf2(threadData_t *threadData, modelica_metatype _baseClass, modelica_metatype _parentClass, modelica_metatype _program, modelica_boolean _includePartial, modelica_boolean _sort)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _entries = NULL;
modelica_metatype _strlst = NULL;
modelica_metatype _p = NULL;
modelica_metatype _parent = NULL;
modelica_metatype _base_class = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _base_entry = NULL;
modelica_metatype _classes = NULL;
modelica_metatype _result_path_lst = NULL;
modelica_metatype _acc = NULL;
modelica_metatype _locals = NULL;
modelica_metatype _candidates = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _genv = NULL;
modelica_metatype _opt_path = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
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
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_candidates = tmpMeta1;
{
modelica_metatype _ext;
for (tmpMeta2 = omc_InteractiveUtil_getAllInheritedClasses(threadData, _parentClass, _program); !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_ext = MMC_CAR(tmpMeta2);
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_acc = omc_InteractiveUtil_getAllSubtypeOfCandidates(threadData, _ext, _ext, _program, _includePartial, tmpMeta3);
tmpMeta5 = mmc_mk_box2(0, _ext, _acc);
tmpMeta4 = mmc_mk_cons(tmpMeta5, _candidates);
_candidates = tmpMeta4;
}
}
tmpMeta7 = _program;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_classes = tmpMeta8;
if((!_includePartial))
{
{
modelica_metatype __omcQ_24tmpVar77;
modelica_metatype* tmp10;
modelica_metatype tmpMeta11;
modelica_metatype __omcQ_24tmpVar76;
modelica_integer tmp12;
modelica_metatype _c_loopVar = 0;
modelica_metatype _c;
_c_loopVar = _classes;
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar77 = tmpMeta11;
tmp10 = &__omcQ_24tmpVar77;
while(1) {
tmp12 = 1;
while (!listEmpty(_c_loopVar)) {
_c = MMC_CAR(_c_loopVar);
_c_loopVar = MMC_CDR(_c_loopVar);
if (omc_AbsynUtil_isNotPartial(threadData, _c)) {
tmp12--;
break;
}
}
if (tmp12 == 0) {
__omcQ_24tmpVar76 = _c;
*tmp10 = mmc_mk_cons(__omcQ_24tmpVar76,0);
tmp10 = &MMC_CDR(*tmp10);
} else if (tmp12 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp10 = mmc_mk_nil();
tmpMeta9 = __omcQ_24tmpVar77;
}
_classes = tmpMeta9;
}
_strlst = omc_List_map(threadData, _classes, boxvar_AbsynUtil_getClassName);
{
modelica_metatype __omcQ_24tmpVar79;
modelica_metatype* tmp14;
modelica_metatype tmpMeta15;
modelica_metatype __omcQ_24tmpVar78;
modelica_integer tmp16;
modelica_metatype _str_loopVar = 0;
modelica_metatype _str;
_str_loopVar = _strlst;
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar79 = tmpMeta15;
tmp14 = &__omcQ_24tmpVar79;
while(1) {
tmp16 = 1;
if (!listEmpty(_str_loopVar)) {
_str = MMC_CAR(_str_loopVar);
_str_loopVar = MMC_CDR(_str_loopVar);
tmp16--;
}
if (tmp16 == 0) {
__omcQ_24tmpVar78 = omc_AbsynUtil_makeIdentPathFromString(threadData, _str);
*tmp14 = mmc_mk_cons(__omcQ_24tmpVar78,0);
tmp14 = &MMC_CDR(*tmp14);
} else if (tmp16 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp14 = mmc_mk_nil();
tmpMeta13 = __omcQ_24tmpVar79;
}
_result_path_lst = tmpMeta13;
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
_acc = tmpMeta17;
{
modelica_metatype _p;
for (tmpMeta18 = _result_path_lst; !listEmpty(tmpMeta18); tmpMeta18=MMC_CDR(tmpMeta18))
{
_p = MMC_CAR(tmpMeta18);
_acc = omc_InteractiveUtil_getAllSubtypeOfCandidates(threadData, _p, _parentClass, _program, _includePartial, _acc);
}
}
tmpMeta21 = mmc_mk_box2(0, _parentClass, _acc);
tmpMeta20 = mmc_mk_cons(tmpMeta21, _candidates);
_candidates = tmpMeta20;
{
{
volatile mmc_switch_type tmp24;
int tmp25;
tmp24 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp23_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp24 < 2; tmp24++) {
switch (MMC_SWITCH_CAST(tmp24)) {
case 0: {
_genv = omc_InteractiveUtil_createEnvironment(threadData, _program, mmc_mk_none(), _parentClass);
_base_class = omc_InteractiveUtil_qualifyPath(threadData, _genv, _baseClass, 1 /* true */);
goto tmp23_done;
}
case 1: {
modelica_metatype tmpMeta26;
tmpMeta26 = MMC_REFSTRUCTLIT(mmc_nil);
_entries = tmpMeta26;
goto _return;
goto tmp23_done;
}
}
goto tmp23_end;
tmp23_end: ;
}
goto goto_22;
tmp23_done:
(void)tmp24;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp23_done2;
goto_22:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp24 < 2) {
goto tmp23_top;
}
MMC_THROW_INTERNAL();
tmp23_done2:;
}
}
;
tmpMeta27 = MMC_REFSTRUCTLIT(mmc_nil);
_entries = tmpMeta27;
tmpMeta28 = MMC_REFSTRUCTLIT(mmc_nil);
_locals = tmpMeta28;
{
modelica_metatype _tup;
for (tmpMeta29 = _candidates; !listEmpty(tmpMeta29); tmpMeta29=MMC_CDR(tmpMeta29))
{
_tup = MMC_CAR(tmpMeta29);
tmpMeta30 = _tup;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 1));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 2));
_parent = tmpMeta31;
_acc = tmpMeta32;
{
modelica_metatype _entry;
for (tmpMeta33 = _acc; !listEmpty(tmpMeta33); tmpMeta33=MMC_CDR(tmpMeta33))
{
_entry = MMC_CAR(tmpMeta33);
if(omc_InteractiveUtil_isSubtypeOf(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_entry), 2))), _base_class, _program))
{
_opt_path = omc_AbsynUtil_removePrefixOpt(threadData, _parent, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_entry), 2))));
if(isSome(_opt_path))
{
tmpMeta34 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta34), MMC_UNTAGPTR(_entry), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta34))[2] = omc_Util_getOption(threadData, _opt_path);
_entry = tmpMeta34;
tmpMeta35 = mmc_mk_cons(_entry, _locals);
_locals = tmpMeta35;
}
else
{
tmpMeta36 = mmc_mk_cons(_entry, _entries);
_entries = tmpMeta36;
}
}
}
}
}
}
_cls = omc_ProgramUtil_getPathedClassInProgram(threadData, _base_class, _program, 0 /* false */, 0 /* false */);
tmpMeta39 = mmc_mk_box3(3, &InteractiveUtil_ClassEntry_CLASS__ENTRY__desc, _base_class, _cls);
_base_entry = tmpMeta39;
{
modelica_metatype _tup;
for (tmpMeta40 = _candidates; !listEmpty(tmpMeta40); tmpMeta40=MMC_CDR(tmpMeta40))
{
_tup = MMC_CAR(tmpMeta40);
tmpMeta41 = _tup;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 2));
_acc = tmpMeta42;
if(omc_List_contains(threadData, _acc, _base_entry, boxvar_InteractiveUtil_ClassEntry_equal))
{
tmpMeta43 = mmc_mk_cons(_base_entry, _entries);
_entries = tmpMeta43;
break;
}
}
}
_entries = listAppend(_locals, _entries);
_entries = omc_List_uniqueOnTrue(threadData, _entries, boxvar_InteractiveUtil_ClassEntry_equal);
if(_sort)
{
_entries = omc_List_sort(threadData, _entries, boxvar_InteractiveUtil_ClassEntry_greaterEq);
}
_return: OMC_LABEL_UNUSED
threadData->mmc_jumper = old_mmc_jumper;
return _entries;
}
modelica_metatype boxptr_InteractiveUtil_getAllSubtypeOf2(threadData_t *threadData, modelica_metatype _baseClass, modelica_metatype _parentClass, modelica_metatype _program, modelica_metatype _includePartial, modelica_metatype _sort)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _entries = NULL;
tmp1 = mmc_unbox_integer(_includePartial);
tmp2 = mmc_unbox_integer(_sort);
_entries = omc_InteractiveUtil_getAllSubtypeOf2(threadData, _baseClass, _parentClass, _program, tmp1, tmp2);
return _entries;
}
static modelica_metatype closure22_InteractiveUtil_getAllSubtypeOfCandidates(threadData_t *thData, modelica_metatype closure, modelica_metatype path, modelica_metatype $in_candidates)
{
modelica_metatype parentClass = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype program = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
modelica_metatype includePartial = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),3));
return boxptr_InteractiveUtil_getAllSubtypeOfCandidates(thData, path, parentClass, program, includePartial, $in_candidates);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getAllSubtypeOfCandidates(threadData_t *threadData, modelica_metatype _path, modelica_metatype _parentClass, modelica_metatype _program, modelica_boolean _includePartial, modelica_metatype __omcQ_24in_5Fcandidates)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _candidates = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype _names = NULL;
modelica_metatype _paths = NULL;
modelica_boolean _is_parent;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta11;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_candidates = __omcQ_24in_5Fcandidates;
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
_cdef = omc_ProgramUtil_getPathedClassInProgram(threadData, _path, _program, 0 /* false */, 0 /* false */);
goto tmp2_done;
}
case 1: {
goto _return;
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
if((_includePartial || omc_AbsynUtil_isNotPartial(threadData, _cdef)))
{
tmpMeta6 = mmc_mk_box3(3, &InteractiveUtil_ClassEntry_CLASS__ENTRY__desc, _path, _cdef);
tmpMeta5 = mmc_mk_cons(tmpMeta6, _candidates);
_candidates = tmpMeta5;
_is_parent = omc_AbsynUtil_pathEqual(threadData, _path, _parentClass);
if((omc_AbsynUtil_isPackageRestriction(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 6)))) || _is_parent))
{
_names = omc_InteractiveUtil_getClassnamesInClassListNoPartial(threadData, _path, _program, _cdef, _is_parent, 0 /* false */);
{
modelica_metatype __omcQ_24tmpVar81;
modelica_metatype* tmp8;
modelica_metatype tmpMeta9;
modelica_metatype __omcQ_24tmpVar80;
modelica_integer tmp10;
modelica_metatype _n_loopVar = 0;
modelica_metatype _n;
_n_loopVar = _names;
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar81 = tmpMeta9;
tmp8 = &__omcQ_24tmpVar81;
while(1) {
tmp10 = 1;
if (!listEmpty(_n_loopVar)) {
_n = MMC_CAR(_n_loopVar);
_n_loopVar = MMC_CDR(_n_loopVar);
tmp10--;
}
if (tmp10 == 0) {
__omcQ_24tmpVar80 = omc_AbsynUtil_suffixPath(threadData, _path, _n);
*tmp8 = mmc_mk_cons(__omcQ_24tmpVar80,0);
tmp8 = &MMC_CDR(*tmp8);
} else if (tmp10 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp8 = mmc_mk_nil();
tmpMeta7 = __omcQ_24tmpVar81;
}
_paths = tmpMeta7;
tmpMeta11 = mmc_mk_box3(0, _parentClass, _program, mmc_mk_boolean(_includePartial));
_candidates = omc_List_fold(threadData, _paths, (modelica_fnptr) mmc_mk_box2(0,closure22_InteractiveUtil_getAllSubtypeOfCandidates,tmpMeta11), _candidates);
}
}
_return: OMC_LABEL_UNUSED
threadData->mmc_jumper = old_mmc_jumper;
return _candidates;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getAllSubtypeOfCandidates(threadData_t *threadData, modelica_metatype _path, modelica_metatype _parentClass, modelica_metatype _program, modelica_metatype _includePartial, modelica_metatype __omcQ_24in_5Fcandidates)
{
modelica_integer tmp1;
modelica_metatype _candidates = NULL;
tmp1 = mmc_unbox_integer(_includePartial);
_candidates = omc_InteractiveUtil_getAllSubtypeOfCandidates(threadData, _path, _parentClass, _program, tmp1, __omcQ_24in_5Fcandidates);
return _candidates;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getReplaceableChoices(threadData_t *threadData, modelica_metatype _baseClass, modelica_metatype _parentClass, modelica_metatype _program, modelica_boolean _includePartial, modelica_boolean _sort)
{
modelica_metatype _res = NULL;
modelica_metatype _classes = NULL;
modelica_metatype _vals = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _name_val = NULL;
modelica_metatype _cmt_val = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_vals = tmpMeta1;
_classes = omc_InteractiveUtil_getAllSubtypeOf2(threadData, _baseClass, _parentClass, _program, _includePartial, _sort);
{
modelica_metatype _entry;
for (tmpMeta2 = _classes; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_entry = MMC_CAR(tmpMeta2);
_name_val = omc_ValuesMake_makeString(threadData, omc_AbsynUtil_pathString(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_entry), 2))), _OMC_LIT39, 1 /* true */, 0 /* false */));
_cmt_val = omc_ValuesMake_makeString(threadData, omc_AbsynUtil_classDefStringComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_entry), 3)))), 7)))));
tmpMeta4 = mmc_mk_cons(_name_val, mmc_mk_cons(_cmt_val, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta3 = mmc_mk_cons(omc_ValuesMake_makeArray(threadData, tmpMeta4), _vals);
_vals = tmpMeta3;
}
}
_res = omc_ValuesMake_makeArray(threadData, listReverseInPlace(_vals));
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_InteractiveUtil_getReplaceableChoices(threadData_t *threadData, modelica_metatype _baseClass, modelica_metatype _parentClass, modelica_metatype _program, modelica_metatype _includePartial, modelica_metatype _sort)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _res = NULL;
tmp1 = mmc_unbox_integer(_includePartial);
tmp2 = mmc_unbox_integer(_sort);
_res = omc_InteractiveUtil_getReplaceableChoices(threadData, _baseClass, _parentClass, _program, tmp1, tmp2);
return _res;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getAllSubtypeOf(threadData_t *threadData, modelica_metatype _baseClass, modelica_metatype _parentClass, modelica_metatype _program, modelica_boolean _includePartial, modelica_boolean _sort)
{
modelica_metatype _paths = NULL;
modelica_metatype _classes = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_classes = omc_InteractiveUtil_getAllSubtypeOf2(threadData, _baseClass, _parentClass, _program, _includePartial, _sort);
{
modelica_metatype __omcQ_24tmpVar83;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar82;
modelica_integer tmp4;
modelica_metatype _c_loopVar = 0;
modelica_metatype _c;
_c_loopVar = _classes;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar83 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar83;
while(1) {
tmp4 = 1;
if (!listEmpty(_c_loopVar)) {
_c = MMC_CAR(_c_loopVar);
_c_loopVar = MMC_CDR(_c_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar82 = omc_InteractiveUtil_ClassEntry_getPath(threadData, _c);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar82,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar83;
}
_paths = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _paths;
}
modelica_metatype boxptr_InteractiveUtil_getAllSubtypeOf(threadData_t *threadData, modelica_metatype _baseClass, modelica_metatype _parentClass, modelica_metatype _program, modelica_metatype _includePartial, modelica_metatype _sort)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _paths = NULL;
tmp1 = mmc_unbox_integer(_includePartial);
tmp2 = mmc_unbox_integer(_sort);
_paths = omc_InteractiveUtil_getAllSubtypeOf(threadData, _baseClass, _parentClass, _program, tmp1, tmp2);
return _paths;
}
DLLDirection
modelica_boolean omc_InteractiveUtil_ClassEntry_equal(threadData_t *threadData, modelica_metatype _entry1, modelica_metatype _entry2)
{
modelica_boolean _res;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_entry1), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_entry2), 3))));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_InteractiveUtil_ClassEntry_equal(threadData_t *threadData, modelica_metatype _entry1, modelica_metatype _entry2)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_InteractiveUtil_ClassEntry_equal(threadData, _entry1, _entry2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_boolean omc_InteractiveUtil_ClassEntry_greaterEq(threadData_t *threadData, modelica_metatype _entry1, modelica_metatype _entry2)
{
modelica_boolean _res;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = omc_AbsynUtil_pathGe(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_entry1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_entry2), 2))));
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _res;
}
modelica_metatype boxptr_InteractiveUtil_ClassEntry_greaterEq(threadData_t *threadData, modelica_metatype _entry1, modelica_metatype _entry2)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_InteractiveUtil_ClassEntry_greaterEq(threadData, _entry1, _entry2);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_ClassEntry_getPath(threadData_t *threadData, modelica_metatype _entry)
{
modelica_metatype _path = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_path = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_entry), 2)));
_return: OMC_LABEL_UNUSED
return _path;
}
DLLDirection
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
DLLDirection
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
_cdef = omc_ProgramUtil_getPathedClassInProgram(threadData, _p_class, _p, 0 /* false */, 0 /* false */);
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
tmpMeta13 = mmc_mk_cons(omc_InteractiveUtil_qualifyPath(threadData, _genv, _pt, 0 /* false */), _fqpaths);
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
tmpMeta16 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _elts, _OMC_LIT11);
tmpMeta17 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0 /* false */), _OMC_LIT90, tmpMeta15, mmc_mk_some(tmpMeta16), mmc_mk_none(), _OMC_LIT15);
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
tmpMeta22 = mmc_mk_box3(4, &Absyn_EqMod_EQMOD__desc, _e, _OMC_LIT15);
tmpMeta23 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta21, tmpMeta22);
tmpMeta24 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0 /* false */), _OMC_LIT90, tmpMeta20, mmc_mk_some(tmpMeta23), mmc_mk_none(), _OMC_LIT15);
tmpMeta1 = tmpMeta24;
goto tmp3_done;
}
case 2: {
omc_Print_printBuf(threadData, _OMC_LIT91);
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,11,3) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
_cr = tmpMeta6;
_e = tmpMeta9;
_nargs = tmpMeta11;
tmp4 += 1;
_eltarglst = omc_List_map(threadData, _nargs, boxvar_InteractiveUtil_namedargToModification);
_emod = omc_InteractiveUtil_recordConstructorToModification(threadData, _e);
_p = omc_AbsynUtil_crefToPath(threadData, _cr);
tmpMeta12 = mmc_mk_cons(_emod, _eltarglst);
tmpMeta13 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta12, _OMC_LIT11);
tmpMeta14 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0 /* false */), _OMC_LIT90, _p, mmc_mk_some(tmpMeta13), mmc_mk_none(), _OMC_LIT15);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,0,2) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
if (!listEmpty(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
_cr = tmpMeta15;
_nargs = tmpMeta18;
tmp4 += 1;
_eltarglst = omc_List_map(threadData, _nargs, boxvar_InteractiveUtil_namedargToModification);
_p = omc_AbsynUtil_crefToPath(threadData, _cr);
tmpMeta19 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _eltarglst, _OMC_LIT11);
tmpMeta20 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0 /* false */), _OMC_LIT90, _p, mmc_mk_some(tmpMeta19), mmc_mk_none(), _OMC_LIT15);
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
case 2: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,3) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,0,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
if (listEmpty(tmpMeta23)) goto tmp3_end;
tmpMeta24 = MMC_CAR(tmpMeta23);
tmpMeta25 = MMC_CDR(tmpMeta23);
if (!listEmpty(tmpMeta25)) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 3));
if (!listEmpty(tmpMeta26)) goto tmp3_end;
_cr = tmpMeta21;
_e = tmpMeta24;
_p = omc_AbsynUtil_crefToPath(threadData, _cr);
tmpMeta27 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta28 = mmc_mk_box3(4, &Absyn_EqMod_EQMOD__desc, _e, _OMC_LIT15);
tmpMeta29 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta27, tmpMeta28);
tmpMeta30 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0 /* false */), _OMC_LIT90, _p, mmc_mk_some(tmpMeta29), mmc_mk_none(), _OMC_LIT15);
tmpMeta1 = tmpMeta30;
goto tmp3_done;
}
case 3: {
omc_Print_printBuf(threadData, _OMC_LIT92);
omc_Print_printBuf(threadData, omc_Dump_printExpStr(threadData, _inExp));
omc_Print_printBuf(threadData, _OMC_LIT93);
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
DLLDirection
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
if (8 != MMC_STRLEN(tmpMeta8) || strcmp(MMC_STRINGDATA(_OMC_LIT94), MMC_STRINGDATA(tmpMeta8)) != 0) goto tmp5_end;
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
if (7 != MMC_STRLEN(tmpMeta11) || strcmp(MMC_STRINGDATA(_OMC_LIT95), MMC_STRINGDATA(tmpMeta11)) != 0) goto tmp5_end;
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
DLLDirection
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
DLLDirection
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
DLLDirection
modelica_metatype omc_InteractiveUtil_getComponentItemsNameAndComment(threadData_t *threadData, modelica_metatype _inComponents, modelica_metatype _inElement)
{
modelica_metatype _outStrings = NULL;
modelica_metatype tmpMeta1;
modelica_string _name = NULL;
modelica_string _cmt_str = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta11;
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
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_name = tmpMeta8;
_cmt_str = omc_InteractiveUtil_getComponentComment(threadData, _comp, _inElement);
_cmt_str = omc_StringUtil_quote(threadData, _cmt_str);
tmpMeta10 = mmc_mk_cons(_name, mmc_mk_cons(_cmt_str, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta9 = mmc_mk_cons(tmpMeta10, _outStrings);
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
DLLDirection
modelica_string omc_InteractiveUtil_getComponentComment(threadData_t *threadData, modelica_metatype _component, modelica_metatype _element)
{
modelica_string _comment = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_comment = omc_InteractiveUtil_getConstrainingClassComment(threadData, omc_AbsynUtil_getElementConstrainingClass(threadData, _element));
if((stringLength(_comment) == ((modelica_integer) 0)))
{
_comment = omc_InteractiveUtil_getClassCommentInCommentOpt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_component), 4))));
}
_return: OMC_LABEL_UNUSED
return _comment;
}
DLLDirection
modelica_string omc_InteractiveUtil_getConstrainingClassComment(threadData_t *threadData, modelica_metatype _constrainingClass)
{
modelica_string _comment = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _constrainingClass;
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
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
if (optionNone(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 1));
_comment = tmpMeta10;
tmp1 = _comment;
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT13;
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
_comment = tmp1;
_return: OMC_LABEL_UNUSED
return _comment;
}
DLLDirection
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
tmp1 = _OMC_LIT96;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT97;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT98;
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
DLLDirection
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
tmp1 = _OMC_LIT98;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT99;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT100;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta9;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT101;
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
DLLDirection
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
tmp1 = _OMC_LIT102;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT103;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT13;
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
DLLDirection
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
tmp1 = (_s?_OMC_LIT104:_OMC_LIT105);
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
DLLDirection
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
tmp1 = (_f?_OMC_LIT104:_OMC_LIT105);
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
DLLDirection
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
tmp1 = _OMC_LIT106;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT107;
goto tmp3_done;
}
case 6: {
tmp1 = _OMC_LIT108;
goto tmp3_done;
}
case 5: {
tmp1 = _OMC_LIT109;
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
DLLDirection
modelica_boolean omc_InteractiveUtil_keywordReplaceable(threadData_t *threadData, modelica_metatype _inAbsynRedeclareKeywordsOption)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
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
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
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
DLLDirection
modelica_metatype omc_InteractiveUtil_getElementsInfo(threadData_t *threadData, modelica_metatype _elements, modelica_boolean _isPublic, modelica_boolean _useQuotes, modelica_boolean _onlyComponents, modelica_metatype _env, modelica_metatype __omcQ_24in_5Finfos)
{
modelica_metatype _infos = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_infos = __omcQ_24in_5Finfos;
{
modelica_metatype _elem;
for (tmpMeta1 = listReverse(_elements); !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_elem = MMC_CAR(tmpMeta1);
_infos = omc_InteractiveUtil_getElementInfo(threadData, _elem, _isPublic, _useQuotes, _onlyComponents, _env, _infos);
}
}
_return: OMC_LABEL_UNUSED
return _infos;
}
modelica_metatype boxptr_InteractiveUtil_getElementsInfo(threadData_t *threadData, modelica_metatype _elements, modelica_metatype _isPublic, modelica_metatype _useQuotes, modelica_metatype _onlyComponents, modelica_metatype _env, modelica_metatype __omcQ_24in_5Finfos)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _infos = NULL;
tmp1 = mmc_unbox_integer(_isPublic);
tmp2 = mmc_unbox_integer(_useQuotes);
tmp3 = mmc_unbox_integer(_onlyComponents);
_infos = omc_InteractiveUtil_getElementsInfo(threadData, _elements, tmp1, tmp2, tmp3, _env, __omcQ_24in_5Finfos);
return _infos;
}
DLLDirection
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
DLLDirection
modelica_metatype omc_InteractiveUtil_getConstrainClassPath(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _occ)
{
modelica_metatype _path = NULL;
modelica_metatype tmpMeta1;
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
_path = tmpMeta8;
tmpMeta1 = omc_InteractiveUtil_qualifyPath(threadData, _inEnv, _path, 0 /* false */);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _OMC_LIT111;
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
_path = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _path;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_qualifyPath(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_boolean _failOnError)
{
modelica_metatype _outPath = NULL;
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
if (4 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT115), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
tmpMeta1 = _inPath;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (7 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT116), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmpMeta1 = _inPath;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (7 != MMC_STRLEN(tmpMeta8) || strcmp(MMC_STRINGDATA(_OMC_LIT117), MMC_STRINGDATA(tmpMeta8)) != 0) goto tmp3_end;
tmpMeta1 = _inPath;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (6 != MMC_STRLEN(tmpMeta9) || strcmp(MMC_STRINGDATA(_OMC_LIT118), MMC_STRINGDATA(tmpMeta9)) != 0) goto tmp3_end;
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
if(omc_Flags_isSet(threadData, _OMC_LIT114))
{
omc_Interactive_mkFullyQual(threadData, _inEnv, _inPath, _failOnError ,&_outPath);
}
else
{
_outPath = omc_InteractiveUtil_qualifyType(threadData, omc_Interactive_envFromGraphicEnvCache(threadData, _inEnv), _inPath);
}
goto tmp11_done;
}
case 1: {
if(_failOnError)
{
goto goto_10;
}
else
{
_outPath = _inPath;
}
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
modelica_metatype boxptr_InteractiveUtil_qualifyPath(threadData_t *threadData, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _failOnError)
{
modelica_integer tmp1;
modelica_metatype _outPath = NULL;
tmp1 = mmc_unbox_integer(_failOnError);
_outPath = omc_InteractiveUtil_qualifyPath(threadData, _inEnv, _inPath, tmp1);
return _outPath;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getElementAttributeValues(threadData_t *threadData, modelica_metatype _element, modelica_boolean _isPublic, modelica_boolean _quoteNames, modelica_metatype __omcQ_24in_5FattrValues)
{
modelica_metatype _attrValues = NULL;
modelica_metatype _attr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_attrValues = __omcQ_24in_5FattrValues;
{
modelica_metatype tmp4_1;
tmp4_1 = _element;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_string tmp19;
modelica_metatype tmpMeta20;
modelica_string tmp21;
modelica_metatype tmpMeta22;
modelica_string tmp23;
modelica_metatype tmpMeta24;
modelica_string tmp25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
{
modelica_metatype tmp9_1;
tmp9_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5)));
{
volatile mmc_switch_type tmp9;
int tmp10;
tmp9 = 0;
for (; tmp9 < 2; tmp9++) {
switch (MMC_SWITCH_CAST(tmp9)) {
case 0: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp9_1,0,2) == 0) goto tmp8_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp9_1), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,1,4) == 0) goto tmp8_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
_attr = tmpMeta13;
tmpMeta6 = _attr;
goto tmp8_done;
}
case 1: {
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp9_1,3,3) == 0) goto tmp8_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp9_1), 2));
_attr = tmpMeta14;
tmpMeta6 = _attr;
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
_attr = tmpMeta6;
tmpMeta17 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, omc_InteractiveUtil_attrDirectionStr(threadData, _attr)), _attrValues);
tmpMeta16 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, omc_InteractiveUtil_innerOuterStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4))))), tmpMeta17);
tmpMeta15 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, omc_InteractiveUtil_attrVariabilityStr(threadData, _attr)), tmpMeta16);
_attrValues = tmpMeta15;
if(_quoteNames)
{
tmp19 = modelica_boolean_to_modelica_string(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 2)))), ((modelica_integer) 0), 1 /* true */);
tmp21 = modelica_boolean_to_modelica_string(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 2)))), ((modelica_integer) 0), 1 /* true */);
tmp23 = modelica_boolean_to_modelica_string(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 3)))), ((modelica_integer) 0), 1 /* true */);
tmp25 = modelica_boolean_to_modelica_string(omc_AbsynUtil_isElementReplaceable(threadData, _element), ((modelica_integer) 0), 1 /* true */);
tmpMeta24 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, tmp25), _attrValues);
tmpMeta22 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, tmp23), tmpMeta24);
tmpMeta20 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, tmp21), tmpMeta22);
tmpMeta18 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, tmp19), tmpMeta20);
_attrValues = tmpMeta18;
}
else
{
tmpMeta29 = mmc_mk_cons(omc_ValuesMake_makeBoolean(threadData, omc_AbsynUtil_isElementReplaceable(threadData, _element)), _attrValues);
tmpMeta28 = mmc_mk_cons(omc_ValuesMake_makeBoolean(threadData, mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 3))))), tmpMeta29);
tmpMeta27 = mmc_mk_cons(omc_ValuesMake_makeBoolean(threadData, mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 2))))), tmpMeta28);
tmpMeta26 = mmc_mk_cons(omc_ValuesMake_makeBoolean(threadData, mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 2))))), tmpMeta27);
_attrValues = tmpMeta26;
}
tmpMeta30 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, (_isPublic?_OMC_LIT119:_OMC_LIT120)), _attrValues);
tmpMeta1 = tmpMeta30;
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
_attrValues = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _attrValues;
}
modelica_metatype boxptr_InteractiveUtil_getElementAttributeValues(threadData_t *threadData, modelica_metatype _element, modelica_metatype _isPublic, modelica_metatype _quoteNames, modelica_metatype __omcQ_24in_5FattrValues)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _attrValues = NULL;
tmp1 = mmc_unbox_integer(_isPublic);
tmp2 = mmc_unbox_integer(_quoteNames);
_attrValues = omc_InteractiveUtil_getElementAttributeValues(threadData, _element, tmp1, tmp2, __omcQ_24in_5FattrValues);
return _attrValues;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementInfo(threadData_t *threadData, modelica_metatype _element, modelica_boolean _isPublic, modelica_boolean _quoteNames, modelica_boolean _onlyComponents, modelica_metatype _env, modelica_metatype __omcQ_24in_5Finfos)
{
modelica_metatype _infos = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _cc_path = NULL;
modelica_metatype _comps = NULL;
modelica_string _name = NULL;
modelica_string _cmt = NULL;
modelica_metatype _common_info = NULL;
modelica_metatype _info = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _restriction = NULL;
modelica_metatype _opt_cmt = NULL;
modelica_metatype _opt_cc = NULL;
modelica_metatype _opt_adim = NULL;
modelica_metatype _common_dims = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _dims_val = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_infos = __omcQ_24in_5Finfos;
{
modelica_metatype tmp4_1;
tmp4_1 = _element;
{
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_attr = tmpMeta7;
_ty = tmpMeta9;
_opt_adim = tmpMeta10;
_comps = tmpMeta11;
_opt_cc = tmpMeta12;
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
_common_info = tmpMeta13;
_ty = omc_InteractiveUtil_qualifyPath(threadData, _env, _ty, 0 /* false */);
_common_dims = omc_InteractiveUtil_dimensionListValues(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 8))));
if((!_onlyComponents))
{
_cc_path = omc_InteractiveUtil_getConstrainClassPath(threadData, _env, _opt_cc);
if(_quoteNames)
{
tmpMeta14 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, omc_AbsynUtil_pathString(threadData, _cc_path, _OMC_LIT39, 1 /* true */, 0 /* false */)), _common_info);
_common_info = tmpMeta14;
}
else
{
tmpMeta15 = mmc_mk_cons(omc_ValuesMake_makeCodeTypeName(threadData, omc_InteractiveUtil_getConstrainClassPath(threadData, _env, _opt_cc)), _common_info);
_common_info = tmpMeta15;
}
}
_common_info = omc_InteractiveUtil_getElementAttributeValues(threadData, _element, _isPublic, _quoteNames, _common_info);
{
modelica_metatype _comp;
for (tmpMeta16 = listReverse(_comps); !listEmpty(tmpMeta16); tmpMeta16=MMC_CDR(tmpMeta16))
{
_comp = MMC_CAR(tmpMeta16);
_name = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_comp), 2)))), 2)));
_cmt = omc_InteractiveUtil_getComponentComment(threadData, _comp, _element);
_dims = omc_InteractiveUtil_dimensionListValues(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_comp), 2)))), 3))));
_dims_val = omc_ValuesMake_makeArray(threadData, listAppend(_dims, _common_dims));
if(_quoteNames)
{
_dims_val = omc_ValuesMake_makeString(threadData, omc_ValuesDump_printValStr(threadData, _dims_val));
}
_info = omc_List_appendElt(threadData, _dims_val, _common_info);
tmpMeta17 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, _cmt), _info);
_info = tmpMeta17;
if(_quoteNames)
{
tmpMeta18 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, _name), _info);
_info = tmpMeta18;
tmpMeta19 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, omc_AbsynUtil_pathString(threadData, _ty, _OMC_LIT39, 1 /* true */, 0 /* false */)), _info);
_info = tmpMeta19;
}
else
{
tmpMeta20 = mmc_mk_cons(omc_ValuesMake_makeCodeTypeNameStr(threadData, _name), _info);
_info = tmpMeta20;
tmpMeta21 = mmc_mk_cons(omc_ValuesMake_makeCodeTypeName(threadData, _ty), _info);
_info = tmpMeta21;
}
if((!_onlyComponents))
{
tmpMeta23 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, _OMC_LIT122), _info);
tmpMeta22 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, _OMC_LIT121), tmpMeta23);
_info = tmpMeta22;
}
tmpMeta24 = mmc_mk_cons(omc_ValuesMake_makeArray(threadData, _info), _infos);
_infos = tmpMeta24;
}
}
tmpMeta1 = _infos;
goto tmp3_done;
}
case 1: {
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
modelica_boolean tmp38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,0,2) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 3));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 2));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 6));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta30,1,4) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,0,2) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 2));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 3));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 3));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 5));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_cls = tmpMeta27;
_name = tmpMeta28;
_restriction = tmpMeta29;
_ty = tmpMeta32;
_opt_adim = tmpMeta33;
_attr = tmpMeta34;
_opt_cmt = tmpMeta35;
_opt_cc = tmpMeta36;
if (!(!_onlyComponents)) goto tmp3_end;
_ty = omc_InteractiveUtil_qualifyPath(threadData, _env, _ty, 0 /* false */);
_cmt = omc_InteractiveUtil_getConstrainingClassComment(threadData, _opt_cc);
if((stringLength(_cmt) == ((modelica_integer) 0)))
{
_cmt = omc_InteractiveUtil_getClassCommentInCommentOpt(threadData, _opt_cmt);
}
tmp38 = (modelica_boolean)isSome(_opt_adim);
if(tmp38)
{
tmpMeta39 = omc_InteractiveUtil_dimensionListValues(threadData, omc_Util_getOption(threadData, _opt_adim));
}
else
{
tmpMeta37 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta39 = tmpMeta37;
}
_dims = tmpMeta39;
_dims = listAppend(omc_InteractiveUtil_dimensionListValues(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 8)))), _dims);
_dims_val = omc_ValuesMake_makeArray(threadData, _dims);
if(_quoteNames)
{
_dims_val = omc_ValuesMake_makeString(threadData, omc_ValuesDump_printValStr(threadData, _dims_val));
}
tmpMeta40 = mmc_mk_cons(_dims_val, MMC_REFSTRUCTLIT(mmc_nil));
_info = tmpMeta40;
tmpMeta41 = mmc_mk_cons(omc_ValuesMake_makeCodeTypeName(threadData, omc_InteractiveUtil_getConstrainClassPath(threadData, _env, _opt_cc)), _info);
_info = tmpMeta41;
_info = omc_InteractiveUtil_getElementAttributeValues(threadData, _element, _isPublic, _quoteNames, _info);
tmpMeta42 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, _cmt), _info);
_info = tmpMeta42;
tmpMeta43 = mmc_mk_cons(omc_ValuesMake_makeCodeTypeNameStr(threadData, _name), _info);
_info = tmpMeta43;
tmpMeta44 = mmc_mk_cons(omc_ValuesMake_makeCodeTypeName(threadData, _ty), _info);
_info = tmpMeta44;
tmpMeta45 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, omc_Dump_unparseRestrictionStr(threadData, _restriction)), _info);
_info = tmpMeta45;
tmpMeta46 = mmc_mk_cons(omc_ValuesMake_makeString(threadData, _OMC_LIT123), _info);
_info = tmpMeta46;
tmpMeta47 = mmc_mk_cons(omc_ValuesMake_makeArray(threadData, _info), _infos);
tmpMeta1 = tmpMeta47;
goto tmp3_done;
}
case 2: {
tmpMeta1 = _infos;
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
_infos = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _infos;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_getElementInfo(threadData_t *threadData, modelica_metatype _element, modelica_metatype _isPublic, modelica_metatype _quoteNames, modelica_metatype _onlyComponents, modelica_metatype _env, modelica_metatype __omcQ_24in_5Finfos)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _infos = NULL;
tmp1 = mmc_unbox_integer(_isPublic);
tmp2 = mmc_unbox_integer(_quoteNames);
tmp3 = mmc_unbox_integer(_onlyComponents);
_infos = omc_InteractiveUtil_getElementInfo(threadData, _element, tmp1, tmp2, tmp3, _env, __omcQ_24in_5Finfos);
return _infos;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_dimensionListValues(threadData_t *threadData, modelica_metatype _dims)
{
modelica_metatype _vals = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar85;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar84;
modelica_integer tmp4;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _dims;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar85 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar85;
while(1) {
tmp4 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar84 = omc_ValuesMake_makeCodeTypeNameStr(threadData, omc_Dump_printSubscriptStr(threadData, _d));
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar84,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar85;
}
_vals = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _vals;
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
DLLDirection
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
DLLDirection
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
DLLDirection
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
_outCache = omc_FCore_emptyCache(threadData);
_outEnv = omc_FGraph_empty(threadData);
_failed = 0;
_graphic_program = omc_InteractiveUtil_modelicaAnnotationProgram(threadData, omc_Config_getAnnotationVersion(threadData));
_outProgram = omc_ProgramUtil_updateProgram(threadData, _graphic_program, _inProgram, 0 /* false */);
_scode_program = omc_AbsynToSCode_translateAbsyn2SCode(threadData, _outProgram);
_check_model = omc_Flags_getConfigBool(threadData, _OMC_LIT127);
_eval_param = omc_Config_getEvaluateParametersInAnnotations(threadData);
_graphics_mode = omc_Config_getGraphicsExpMode(threadData);
omc_FlagsUtil_setConfigBool(threadData, _OMC_LIT127, 1 /* true */);
omc_Config_setEvaluateParametersInAnnotations(threadData, 1 /* true */);
omc_Config_setGraphicsExpMode(threadData, 1 /* true */);
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
_outCache = omc_Inst_instantiateClass(threadData, omc_FCore_emptyCache(threadData), tmpMeta5, _scode_program, _inModelPath, 1 /* true */, 1 /* true */, 1 /* true */ ,&_outEnv, NULL, NULL);
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
omc_FlagsUtil_setConfigBool(threadData, _OMC_LIT127, _check_model);
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
DLLDirection
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
tmpMeta[0+2] = _OMC_LIT128;
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
DLLDirection
modelica_metatype omc_InteractiveUtil_modelicaAnnotationProgram(threadData_t *threadData, modelica_string _annotationVersion)
{
modelica_metatype _annotationProgram = NULL;
modelica_string _filename = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = stringAppend(omc_Settings_getInstallationDirectoryPath(threadData),_OMC_LIT129);
tmpMeta2 = stringAppend(tmpMeta1,omc_Util_stringReplaceChar(threadData, _annotationVersion, _OMC_LIT39, _OMC_LIT130));
tmpMeta3 = stringAppend(tmpMeta2,_OMC_LIT131);
_filename = tmpMeta3;
_annotationProgram = omc_Parser_parse(threadData, _filename, _OMC_LIT132, _OMC_LIT13, mmc_mk_none(), omc_Config_acceptedGrammar(threadData), omc_Flags_getConfigEnum(threadData, _OMC_LIT80), omc_Flags_getConfigBool(threadData, _OMC_LIT84));
_return: OMC_LABEL_UNUSED
return _annotationProgram;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementitemsAnnotationsFromItems(threadData_t *threadData, modelica_metatype _inComponentItems, modelica_metatype _ccAnnotations, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype _inCache, modelica_metatype *out_outCache)
{
modelica_metatype _result = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _outCache = NULL;
modelica_metatype _annotations = NULL;
modelica_metatype _strl = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_result = tmpMeta1;
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
_strl = omc_InteractiveUtil_getElementitemsAnnotationsElArgs(threadData, _annotations, _inEnv, _inClass, _outCache, 1 /* true */ ,&_outCache);
tmpMeta13 = mmc_mk_cons(omc_InteractiveUtil_makeAnnotationArrayValue(threadData, _strl), _result);
_result = tmpMeta13;
}
}
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _result;
}
DLLDirection
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
omc_StaticScript_elabGraphicsExp(threadData, _cache, _env, _eq_aexp, 0 /* false */, _OMC_LIT133, _info ,&_eq_dexp ,&_prop);
_cache = omc_Ceval_cevalIfConstant(threadData, _cache, _env, _eq_dexp, _prop, 0 /* false */, _info ,&_eq_dexp ,&_prop);
_eq_dexp = omc_ExpressionSimplify_simplify1(threadData, _eq_dexp, NULL);
omc_Print_clearErrorBuf(threadData);
_str = omc_ExpressionBasics_printExpStr(threadData, _eq_dexp);
tmpMeta17 = mmc_mk_cons(_ann_name, mmc_mk_cons(_OMC_LIT134, mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil))));
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
if((!listMember(_ann_name, _OMC_LIT151)))
{
_cache = omc_InteractiveUtil_buildEnvForGraphicProgram(threadData, _outCache, _mod ,&_env ,NULL ,&_outCache);
_cache = omc_Lookup_lookupClassIdent(threadData, _cache, _inEnv, _ann_name, mmc_mk_none() ,&_c ,&_env2);
tmpMeta25 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _mod, _OMC_LIT11);
_smod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta25), _OMC_LIT138, _OMC_LIT139, mmc_mk_none(), _info, 0 /* false */);
tmpMeta26 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta27 = mmc_mk_box2(3, &Mod_ModScope_COMPONENT__desc, _ann_name);
_cache = omc_Mod_elabMod(threadData, _cache, _env, tmpMeta26, _OMC_LIT133, _smod, 0 /* false */, tmpMeta27, _OMC_LIT15 ,&_dmod);
_c = omc_SCodeUtil_classSetPartial(threadData, _c, _OMC_LIT148);
tmpMeta28 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta29 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Inst_instClass(threadData, _cache, _env2, tmpMeta28, _OMC_LIT140, _dmod, _OMC_LIT133, _c, tmpMeta29, 0 /* false */, _OMC_LIT141, _OMC_LIT142, _OMC_LIT145 ,NULL ,NULL ,NULL ,&_dae, NULL, NULL, NULL, NULL, NULL);
_str = omc_DAEUtil_getVariableBindingsStr(threadData, omc_DAEUtil_daeElements(threadData, _dae));
}
else
{
_is_icon = (stringEqual(_ann_name, _OMC_LIT135));
_is_diagram = ((stringEqual(_ann_name, _OMC_LIT1)) || (stringEqual(_ann_name, _OMC_LIT136)));
_stripped_mod = omc_AbsynUtil_stripGraphicsAndInteractionModification(threadData, _mod ,&_graphic_mod);
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT137);
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
omc_ErrorExt_rollBack(threadData, _OMC_LIT137);
goto tmp31_done;
}
case 1: {
modelica_metatype tmpMeta34;
omc_ErrorExt_delCheckpoint(threadData, _OMC_LIT137);
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
tmpMeta35 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _stripped_mod, _OMC_LIT11);
_smod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta35), _OMC_LIT138, _OMC_LIT139, mmc_mk_none(), _info, 0 /* false */);
tmpMeta36 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta37 = mmc_mk_box2(3, &Mod_ModScope_COMPONENT__desc, _ann_name);
_cache = omc_Mod_elabMod(threadData, _cache, _env, tmpMeta36, _OMC_LIT133, _smod, 0 /* false */, tmpMeta37, _info ,&_dmod);
_placement_cls = omc_AbsynToSCode_translateClass(threadData, omc_ProgramUtil_getClassInProgram(threadData, _ann_name, _graphic_prog));
tmpMeta38 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta39 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_Inst_instClass(threadData, _cache, _env, tmpMeta38, _OMC_LIT140, _dmod, _OMC_LIT133, _placement_cls, tmpMeta39, 0 /* false */, _OMC_LIT141, _OMC_LIT142, _OMC_LIT145 ,NULL ,NULL ,NULL ,&_dae, NULL, NULL, NULL, NULL, NULL);
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
omc_StaticScript_elabGraphicsExp(threadData, _cache, _env, _graphic_exp, 0 /* false */, _OMC_LIT133, _info ,&_graphic_dexp ,&_prop);
if(_is_icon)
{
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT146);
_cache = omc_Ceval_cevalIfConstant(threadData, _cache, _env, _graphic_dexp, _prop, 0 /* false */, _info ,&_graphic_dexp, NULL);
_graphic_dexp = omc_ExpressionSimplify_simplify1(threadData, _graphic_dexp, NULL);
omc_ErrorExt_rollBack(threadData, _OMC_LIT146);
}
tmpMeta51 = stringAppend(_str,_OMC_LIT147);
tmpMeta52 = stringAppend(tmpMeta51,omc_ExpressionBasics_printExpStr(threadData, _graphic_dexp));
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
tmpMeta53 = mmc_mk_cons(_ann_name, mmc_mk_cons(_OMC_LIT152, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT153, MMC_REFSTRUCTLIT(mmc_nil)))));
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
_c = omc_SCodeUtil_classSetPartial(threadData, _c, _OMC_LIT148);
tmpMeta60 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta61 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Inst_instClass(threadData, _cache, _env, tmpMeta60, _OMC_LIT140, _OMC_LIT154, _OMC_LIT133, _c, tmpMeta61, 0 /* false */, _OMC_LIT141, _OMC_LIT142, _OMC_LIT145 ,NULL ,NULL ,NULL ,&_dae, NULL, NULL, NULL, NULL, NULL);
_str = omc_DAEUtil_getVariableBindingsStr(threadData, omc_DAEUtil_daeElements(threadData, _dae));
tmp63 = (modelica_boolean)_addAnnotationName;
if(tmp63)
{
tmpMeta62 = mmc_mk_cons(_ann_name, mmc_mk_cons(_OMC_LIT152, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT153, MMC_REFSTRUCTLIT(mmc_nil)))));
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
tmpMeta68 = stringAppend(_OMC_LIT155,omc_Dump_unparseElementArgStr(threadData, _e));
tmpMeta69 = stringAppend(tmpMeta68,_OMC_LIT153);
_str = tmpMeta69;
_str = omc_Util_escapeQuotes(threadData, _str);
tmpMeta70 = mmc_mk_cons(_ann_name, mmc_mk_cons(_OMC_LIT156, mmc_mk_cons(_str, mmc_mk_cons(_OMC_LIT157, MMC_REFSTRUCTLIT(mmc_nil)))));
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
modelica_metatype _result = NULL;
modelica_metatype _outCache = NULL;
modelica_metatype _annotations = NULL;
modelica_metatype _strl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = _inCache;
_annotations = listAppend(_inAnnotations, _ccAnnotations);
_strl = omc_InteractiveUtil_getElementitemsAnnotationsElArgs(threadData, _annotations, _inEnv, _inClass, _outCache, 1 /* true */ ,&_outCache);
{
modelica_metatype __omcQ_24tmpVar87;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar86;
modelica_integer tmp4;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = _strl;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar87 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar87;
while(1) {
tmp4 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar86 = omc_ValuesMake_makeCodeTypeNameStr(threadData, _s);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar86,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar87;
}
_result = tmpMeta1;
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _result;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_getElementitemsAnnotations(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inEnv, modelica_metatype _inClass, modelica_metatype _inCache)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _result = NULL;
modelica_metatype _res = NULL;
modelica_metatype _accum = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _cache = NULL;
modelica_metatype _items = NULL;
modelica_metatype _cc = NULL;
modelica_metatype _annotations = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _fullProgram = NULL;
modelica_metatype _modelPath = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta33;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_accum = tmpMeta1;
_cache = _inCache;
if(omc_Flags_isSet(threadData, _OMC_LIT114))
{
_fullProgram = omc_Interactive_cacheProgramAndPath(threadData, _inCache ,&_modelPath);
_result = omc_InteractiveUtil_makeAnnotationArrayValue(threadData, omc_NFApi_evaluateAnnotations(threadData, _fullProgram, _modelPath, _inElements));
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
tmpMeta3 = listAppend(_res, _accum);
goto tmp5_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta26;
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
tmpMeta26 = mmc_mk_cons(omc_ValuesMake_makeArray(threadData, _res), _accum);
tmpMeta3 = tmpMeta26;
goto tmp5_done;
}
case 2: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,6) == 0) goto tmp5_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,3,3) == 0) goto tmp5_end;
tmp6 += 1;
tmpMeta28 = mmc_mk_cons(_OMC_LIT159, _accum);
tmpMeta3 = tmpMeta28;
goto tmp5_done;
}
case 3: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,6) == 0) goto tmp5_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,0,2) == 0) goto tmp5_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 3));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,1,4) == 0) goto tmp5_end;
tmpMeta32 = mmc_mk_cons(_OMC_LIT159, _accum);
tmpMeta3 = tmpMeta32;
goto tmp5_done;
}
case 4: {
tmpMeta3 = _accum;
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
_accum = tmpMeta3;
}
}
_result = omc_ValuesMake_makeArray(threadData, _accum);
_return: OMC_LABEL_UNUSED
threadData->mmc_jumper = old_mmc_jumper;
return _result;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getElementAnnotationsFromElts(threadData_t *threadData, modelica_metatype _els, modelica_metatype _inClass, modelica_metatype _inFullProgram, modelica_metatype _inModelPath)
{
modelica_metatype _result = NULL;
modelica_metatype _graphicProgramSCode = NULL;
modelica_metatype _env = NULL;
modelica_metatype _placementProgram = NULL;
modelica_metatype _cache = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((!omc_Flags_isSet(threadData, _OMC_LIT114)))
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
_result = omc_InteractiveUtil_getElementitemsAnnotations(threadData, _els, _env, _inClass, _cache);
_return: OMC_LABEL_UNUSED
return _result;
}
DLLDirection
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
tmp1 = _OMC_LIT13;
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
DLLDirection
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
modelica_metatype _cache = NULL;
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
if(omc_Flags_isSet(threadData, _OMC_LIT114))
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
_ci_state = omc_ClassInfUtil_start(threadData, _restr, omc_FGraph_getGraphName(threadData, _env2));
_permissive = omc_Flags_getConfigBool(threadData, _OMC_LIT164);
omc_FlagsUtil_setConfigBool(threadData, _OMC_LIT164, 1 /* true */);
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
omc_Inst_partialInstClassIn(threadData, _cache, _env2, tmpMeta12, _OMC_LIT154, _OMC_LIT133, _ci_state, _c, _OMC_LIT165, tmpMeta13, ((modelica_integer) 0) ,&_env2 ,NULL ,NULL ,NULL);
omc_FlagsUtil_setConfigBool(threadData, _OMC_LIT164, _permissive);
goto tmp9_done;
}
case 1: {
omc_FlagsUtil_setConfigBool(threadData, _OMC_LIT164, _permissive);
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
DLLDirection
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
DLLDirection
modelica_boolean omc_InteractiveUtil_componentitemNamed(threadData_t *threadData, modelica_metatype _inComponentItem, modelica_string _inIdent)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
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
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
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
DLLDirection
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
DLLDirection
modelica_metatype omc_InteractiveUtil_getComponentsInElementitems(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst)
{
modelica_metatype _outAbsynElementLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta10;
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
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,0,1) == 0) goto tmp4_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,6) == 0) goto tmp4_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,3) == 0) goto tmp4_end;
_elt = tmpMeta7;
tmpMeta9 = mmc_mk_cons(_elt, _outAbsynElementLst);
_outAbsynElementLst = tmpMeta9;
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
DLLDirection
modelica_metatype omc_InteractiveUtil_getProtectedComponentsInClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _components = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_components = omc_InteractiveUtil_getComponentsInClass(threadData, _inClass, 2);
_return: OMC_LABEL_UNUSED
return _components;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getPublicComponentsInClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _components = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_components = omc_InteractiveUtil_getComponentsInClass(threadData, _inClass, 1);
_return: OMC_LABEL_UNUSED
return _components;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getComponentsInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_integer _visibility)
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
modelica_metatype tmpMeta13;
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
modelica_metatype tmp16_1;
tmp16_1 = _elt;
{
volatile mmc_switch_type tmp16;
int tmp17;
tmp16 = 0;
for (; tmp16 < 3; tmp16++) {
switch (MMC_SWITCH_CAST(tmp16)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp16_1,0,1) == 0) goto tmp15_end;
if (!((modelica_integer)_visibility != 2)) goto tmp15_end;
_lst1 = omc_InteractiveUtil_getComponentsInElementitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))));
tmpMeta13 = omc_List_append__reverse(threadData, _lst1, _res);
goto tmp15_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp16_1,1,1) == 0) goto tmp15_end;
if (!((modelica_integer)_visibility != 1)) goto tmp15_end;
_lst1 = omc_InteractiveUtil_getComponentsInElementitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))));
tmpMeta13 = omc_List_append__reverse(threadData, _lst1, _res);
goto tmp15_done;
}
case 2: {
tmpMeta13 = _res;
goto tmp15_done;
}
}
goto tmp15_end;
tmp15_end: ;
}
goto goto_14;
goto_14:;
goto goto_2;
goto tmp15_done;
tmp15_done:;
}
}
_res = tmpMeta13;
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
modelica_metatype tmpMeta26;
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
modelica_metatype tmp29_1;
tmp29_1 = _elt;
{
volatile mmc_switch_type tmp29;
int tmp30;
tmp29 = 0;
for (; tmp29 < 3; tmp29++) {
switch (MMC_SWITCH_CAST(tmp29)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp29_1,0,1) == 0) goto tmp28_end;
if (!((modelica_integer)_visibility != 2)) goto tmp28_end;
_lst1 = omc_InteractiveUtil_getComponentsInElementitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))));
tmpMeta26 = omc_List_append__reverse(threadData, _lst1, _res);
goto tmp28_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp29_1,1,1) == 0) goto tmp28_end;
if (!((modelica_integer)_visibility != 1)) goto tmp28_end;
_lst1 = omc_InteractiveUtil_getComponentsInElementitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))));
tmpMeta26 = omc_List_append__reverse(threadData, _lst1, _res);
goto tmp28_done;
}
case 2: {
tmpMeta26 = _res;
goto tmp28_done;
}
}
goto tmp28_end;
tmp28_end: ;
}
goto goto_27;
goto_27:;
goto goto_2;
goto tmp28_done;
tmp28_done:;
}
}
_res = tmpMeta26;
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
modelica_metatype boxptr_InteractiveUtil_getComponentsInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _visibility)
{
modelica_integer tmp1;
modelica_metatype _outAbsynElementLst = NULL;
tmp1 = mmc_unbox_integer(_visibility);
_outAbsynElementLst = omc_InteractiveUtil_getComponentsInClass(threadData, _inClass, tmp1);
return _outAbsynElementLst;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getNthComponentInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_integer _nth)
{
modelica_metatype _outElement = NULL;
modelica_metatype _pub = NULL;
modelica_metatype _pro = NULL;
modelica_integer _n;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_pub = omc_InteractiveUtil_getPublicComponentsInClass(threadData, _inClass);
_n = listLength(_pub);
if((_nth <= _n))
{
_outElement = listGet(_pub, _nth);
}
else
{
_pro = omc_InteractiveUtil_getProtectedComponentsInClass(threadData, _inClass);
_outElement = listGet(_pro, _nth - _n);
}
_return: OMC_LABEL_UNUSED
return _outElement;
}
modelica_metatype boxptr_InteractiveUtil_getNthComponentInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _nth)
{
modelica_integer tmp1;
modelica_metatype _outElement = NULL;
tmp1 = mmc_unbox_integer(_nth);
_outElement = omc_InteractiveUtil_getNthComponentInClass(threadData, _inClass, tmp1);
return _outElement;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getComponentInClass(threadData_t *threadData, modelica_metatype _cls, modelica_string _componentName)
{
modelica_metatype _component = NULL;
modelica_metatype _body = NULL;
modelica_metatype _parts = NULL;
modelica_metatype _elements = NULL;
modelica_metatype _components = NULL;
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
DLLDirection
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
_cls = omc_ProgramUtil_getPathedClassInProgram(threadData, _path, _program, 0 /* false */, 0 /* false */);
_component = omc_InteractiveUtil_getComponentInClass(threadData, _cls, _parameterName);
_bindingStr = omc_Dump_printExpStr(threadData, omc_InteractiveUtil_getVariableBindingInComponentitem(threadData, _component));
goto tmp2_done;
}
case 1: {
_bindingStr = _OMC_LIT13;
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
_name = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT39, 1 /* true */, 0 /* false */);
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
_name = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT39, 1 /* true */, 0 /* false */);
{
modelica_metatype __omcQ_24tmpVar89;
modelica_metatype* tmp28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_string __omcQ_24tmpVar88;
modelica_integer tmp32;
modelica_metatype _n_loopVar = 0;
modelica_metatype _n;
_n_loopVar = omc_InteractiveUtil_getModificationNames(threadData, _args, _includeRedeclares);
tmpMeta29 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar89 = tmpMeta29;
tmp28 = &__omcQ_24tmpVar89;
while(1) {
tmp32 = 1;
if (!listEmpty(_n_loopVar)) {
_n = MMC_CAR(_n_loopVar);
_n_loopVar = MMC_CDR(_n_loopVar);
tmp32--;
}
if (tmp32 == 0) {
tmpMeta30 = stringAppend(_name,_OMC_LIT39);
tmpMeta31 = stringAppend(tmpMeta30,_n);
__omcQ_24tmpVar88 = tmpMeta31;
*tmp28 = mmc_mk_cons(__omcQ_24tmpVar88,0);
tmp28 = &MMC_CDR(*tmp28);
} else if (tmp32 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp28 = mmc_mk_nil();
tmpMeta27 = __omcQ_24tmpVar89;
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
_name = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT39, 1 /* true */, 0 /* false */);
{
modelica_metatype __omcQ_24tmpVar91;
modelica_metatype* tmp41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_string __omcQ_24tmpVar90;
modelica_integer tmp45;
modelica_metatype _n_loopVar = 0;
modelica_metatype _n;
_n_loopVar = omc_InteractiveUtil_getModificationNames(threadData, _args, _includeRedeclares);
tmpMeta42 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar91 = tmpMeta42;
tmp41 = &__omcQ_24tmpVar91;
while(1) {
tmp45 = 1;
if (!listEmpty(_n_loopVar)) {
_n = MMC_CAR(_n_loopVar);
_n_loopVar = MMC_CDR(_n_loopVar);
tmp45--;
}
if (tmp45 == 0) {
tmpMeta43 = stringAppend(_name,_OMC_LIT39);
tmpMeta44 = stringAppend(tmpMeta43,_n);
__omcQ_24tmpVar90 = tmpMeta44;
*tmp41 = mmc_mk_cons(__omcQ_24tmpVar90,0);
tmp41 = &MMC_CDR(*tmp41);
} else if (tmp45 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp41 = mmc_mk_nil();
tmpMeta40 = __omcQ_24tmpVar91;
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
DLLDirection
modelica_metatype omc_InteractiveUtil_getExtendsModifierNames(threadData_t *threadData, modelica_metatype _classPath, modelica_metatype _extendsPath, modelica_boolean _useQuotes, modelica_metatype _program)
{
modelica_metatype _result = NULL;
modelica_metatype _extmod = NULL;
modelica_metatype _res = NULL;
modelica_boolean _silent;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_silent = (!omc_Flags_isSet(threadData, _OMC_LIT33));
if(_silent)
{
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT166);
}
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
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmpMeta5 = omc_InteractiveUtil_getPathedExtendsInProgram(threadData, _classPath, _extendsPath, _program);
if (optionNone(tmpMeta5)) goto goto_1;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,3) == 0) goto goto_1;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_extmod = tmpMeta7;
_res = omc_InteractiveUtil_getModificationNames(threadData, _extmod, 1 /* true */);
if(_useQuotes)
{
_res = omc_Interactive_insertQuotesToList(threadData, _res);
}
{
modelica_metatype __omcQ_24tmpVar93;
modelica_metatype* tmp9;
modelica_metatype tmpMeta10;
modelica_metatype __omcQ_24tmpVar92;
modelica_integer tmp11;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = _res;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar93 = tmpMeta10;
tmp9 = &__omcQ_24tmpVar93;
while(1) {
tmp11 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp11--;
}
if (tmp11 == 0) {
__omcQ_24tmpVar92 = omc_ValuesMake_makeCodeTypeName(threadData, omc_AbsynUtil_makeIdentPathFromString(threadData, _s));
*tmp9 = mmc_mk_cons(__omcQ_24tmpVar92,0);
tmp9 = &MMC_CDR(*tmp9);
} else if (tmp11 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp9 = mmc_mk_nil();
tmpMeta8 = __omcQ_24tmpVar93;
}
_result = omc_ValuesMake_makeArray(threadData, tmpMeta8);
goto tmp2_done;
}
case 1: {
_result = omc_ValuesMake_makeString(threadData, _OMC_LIT167);
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
if(_silent)
{
omc_ErrorExt_rollBack(threadData, _OMC_LIT166);
}
_return: OMC_LABEL_UNUSED
return _result;
}
modelica_metatype boxptr_InteractiveUtil_getExtendsModifierNames(threadData_t *threadData, modelica_metatype _classPath, modelica_metatype _extendsPath, modelica_metatype _useQuotes, modelica_metatype _program)
{
modelica_integer tmp1;
modelica_metatype _result = NULL;
tmp1 = mmc_unbox_integer(_useQuotes);
_result = omc_InteractiveUtil_getExtendsModifierNames(threadData, _classPath, _extendsPath, tmp1, _program);
return _result;
}
DLLDirection
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
_cdef = omc_ProgramUtil_getPathedClassInProgram(threadData, _path, _p, 0 /* false */, 0 /* false */);
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
tmpMeta26 = omc_Util_getOptionOrDefault(threadData, _optMod, _OMC_LIT12);
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
tmpMeta1 = omc_InteractiveUtil_getModificationNames(threadData, _mod, 1 /* true */);
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
tmpMeta24 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta23, _OMC_LIT11);
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
DLLDirection
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
tmp1 = omc_System_escapedString(threadData, omc_Dump_unparseElementArgStr(threadData, _arg), 0 /* false */);
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
DLLDirection
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
_cdef = omc_ProgramUtil_getPathedClassInProgram(threadData, _p_class, _p, 0 /* false */, 0 /* false */);
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
tmp1 = _OMC_LIT167;
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
DLLDirection
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
_value = _OMC_LIT13;
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
_value = omc_System_escapedString(threadData, omc_Dump_unparseElementArgStr(threadData, _arg), 0 /* false */);
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
DLLDirection
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
_cls = omc_ProgramUtil_getPathedClassInProgram(threadData, _cls_path, _program, 0 /* false */, 0 /* false */);
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
tmpMeta24 = omc_Util_getOptionOrDefault(threadData, _optMod, _OMC_LIT12);
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
_valueStr = _OMC_LIT13;
}
goto tmp3_done;
}
case 1: {
_valueStr = _OMC_LIT13;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_createNestedSubMod(threadData_t *threadData, modelica_metatype _inComponentName, modelica_metatype _inMod)
{
modelica_metatype _outSubMod = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_AbsynUtil_pathIsIdent(threadData, _inComponentName))
{
tmpMeta1 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0 /* false */), _OMC_LIT90, _inComponentName, mmc_mk_some(_inMod), mmc_mk_none(), _OMC_LIT15);
_outSubMod = tmpMeta1;
}
else
{
_outSubMod = omc_InteractiveUtil_createNestedSubMod(threadData, omc_AbsynUtil_pathRest(threadData, _inComponentName), _inMod);
tmpMeta2 = mmc_mk_cons(_outSubMod, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta3 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, tmpMeta2, _OMC_LIT11);
tmpMeta4 = mmc_mk_box7(3, &Absyn_ElementArg_MODIFICATION__desc, mmc_mk_boolean(0 /* false */), _OMC_LIT90, omc_AbsynUtil_pathFirstPath(threadData, _inComponentName), mmc_mk_some(tmpMeta3), mmc_mk_none(), _OMC_LIT15);
_outSubMod = tmpMeta4;
}
_return: OMC_LABEL_UNUSED
return _outSubMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_propagateMod2(threadData_t *threadData, modelica_metatype _inComponentName, modelica_metatype _inSubMods, modelica_metatype _inNewMod)
{
modelica_metatype _outSubMods = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _submod = NULL;
modelica_metatype _rest_submods = NULL;
modelica_metatype _comp_name = NULL;
modelica_metatype _comp_rest = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outSubMods = tmpMeta1;
_rest_submods = _inSubMods;
while(1)
{
if(!(!listEmpty(_rest_submods))) break;
tmpMeta2 = _rest_submods;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_submod = tmpMeta3;
_rest_submods = tmpMeta4;
_comp_name = omc_AbsynUtil_pathRest(threadData, _inComponentName);
_comp_rest = _comp_name;
while(1)
{
if(!1 /* true */) break;
if(omc_AbsynUtil_pathEqual(threadData, _comp_name, omc_AbsynUtil_elementArgName(threadData, _submod)))
{
{
modelica_metatype tmp7_1;
tmp7_1 = _submod;
{
int tmp7;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp7_1))) {
case 3: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if((!omc_AbsynUtil_pathIsIdent(threadData, _comp_name)))
{
_comp_name = omc_AbsynUtil_pathPrefix(threadData, _comp_name);
_comp_rest = omc_AbsynUtil_removePrefix(threadData, _comp_name, _comp_rest);
}
tmpMeta8 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta8), MMC_UNTAGPTR(_submod), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta8))[5] = omc_InteractiveUtil_propagateMod(threadData, _comp_rest, _inNewMod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_submod), 5))));
_submod = tmpMeta8;
if(isSome((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_submod), 5)))))
{
tmpMeta9 = mmc_mk_cons(_submod, _rest_submods);
_rest_submods = tmpMeta9;
}
goto tmp6_done;
}
case 4: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_submod), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[5] = omc_InteractiveUtil_setSubmodifierInElementSpec(threadData, _comp_rest, _inNewMod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_submod), 5))));
_submod = tmpMeta10;
tmpMeta11 = mmc_mk_cons(_submod, _rest_submods);
_rest_submods = tmpMeta11;
goto tmp6_done;
}
default:
tmp6_default: OMC_LABEL_UNUSED; {
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
_outSubMods = omc_List_append__reverse(threadData, _outSubMods, _rest_submods);
goto _return;
}
if(omc_AbsynUtil_pathIsIdent(threadData, _comp_name))
{
break;
}
else
{
_comp_name = omc_AbsynUtil_pathPrefix(threadData, _comp_name);
}
}
tmpMeta12 = mmc_mk_cons(_submod, _outSubMods);
_outSubMods = tmpMeta12;
}
if((!omc_AbsynUtil_isEmptyMod(threadData, _inNewMod)))
{
_submod = omc_InteractiveUtil_createNestedSubMod(threadData, omc_AbsynUtil_pathRest(threadData, _inComponentName), _inNewMod);
tmpMeta13 = mmc_mk_cons(_submod, _outSubMods);
_outSubMods = listReverse(tmpMeta13);
}
else
{
_outSubMods = _inSubMods;
}
_return: OMC_LABEL_UNUSED
return _outSubMods;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_removeEmptySubMods(threadData_t *threadData, modelica_metatype _subMods)
{
modelica_metatype _outSubMods = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _mod = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outSubMods = tmpMeta1;
{
modelica_metatype _m;
for (tmpMeta2 = _subMods; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_m = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp5_1;
tmp5_1 = _m;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,0,6) == 0) goto tmp4_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 5));
if (optionNone(tmpMeta7)) goto tmp4_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_mod = tmpMeta8;
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_mod), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[2] = omc_InteractiveUtil_removeEmptySubMods(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 2))));
_mod = tmpMeta9;
tmpMeta10 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta10), MMC_UNTAGPTR(_m), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[5] = (omc_AbsynUtil_isEmptyMod(threadData, _mod)?mmc_mk_none():mmc_mk_some(_mod));
_m = tmpMeta10;
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
if((!omc_AbsynUtil_isEmptySubMod(threadData, _m)))
{
tmpMeta11 = mmc_mk_cons(_m, _outSubMods);
_outSubMods = tmpMeta11;
}
}
}
_outSubMods = listReverseInPlace(_outSubMods);
_return: OMC_LABEL_UNUSED
return _outSubMods;
}
static modelica_metatype closure23_AbsynUtil_elementArgEqualName(threadData_t *thData, modelica_metatype closure, modelica_metatype inArg1)
{
modelica_metatype inArg2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_elementArgEqualName(thData, inArg1, inArg2);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_mergeElementArgs(threadData_t *threadData, modelica_metatype _inOldArgs, modelica_metatype _inNewArgs)
{
modelica_metatype _outArgs = NULL;
modelica_boolean _found;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArgs = _inOldArgs;
if(listEmpty(_inOldArgs))
{
_outArgs = omc_InteractiveUtil_removeEmptySubMods(threadData, _inNewArgs);
}
else
{
if(listEmpty(_inNewArgs))
{
_outArgs = _inOldArgs;
}
else
{
{
modelica_metatype _narg;
for (tmpMeta1 = _inNewArgs; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_narg = MMC_CAR(tmpMeta1);
tmpMeta2 = mmc_mk_box1(0, _narg);
_outArgs = omc_List_replaceOnTrue(threadData, _narg, _outArgs, (modelica_fnptr) mmc_mk_box2(0,closure23_AbsynUtil_elementArgEqualName,tmpMeta2) ,&_found);
if((!_found))
{
_outArgs = omc_List_appendElt(threadData, _narg, _outArgs);
}
}
}
_outArgs = omc_InteractiveUtil_removeEmptySubMods(threadData, _outArgs);
}
}
_return: OMC_LABEL_UNUSED
return _outArgs;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_propagateMod(threadData_t *threadData, modelica_metatype _inComponentName, modelica_metatype _inNewMod, modelica_metatype _inOldMod)
{
modelica_metatype _outMod = NULL;
modelica_metatype _new_args = NULL;
modelica_metatype _old_args = NULL;
modelica_metatype _new_eqmod = NULL;
modelica_metatype _old_eqmod = NULL;
modelica_metatype _mod = NULL;
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
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(isSome(_inOldMod))
{
tmpMeta1 = _inOldMod;
if (optionNone(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 3));
_old_args = tmpMeta3;
_old_eqmod = tmpMeta4;
}
else
{
tmpMeta5 = MMC_REFSTRUCTLIT(mmc_nil);
_old_args = tmpMeta5;
_old_eqmod = _OMC_LIT11;
}
if(omc_AbsynUtil_pathIsIdent(threadData, _inComponentName))
{
tmpMeta6 = _inNewMod;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_new_args = tmpMeta7;
_new_eqmod = tmpMeta8;
if((valueEq(_new_eqmod, _OMC_LIT11) && (!listEmpty(_new_args))))
{
_new_eqmod = _old_eqmod;
}
if((!omc_AbsynUtil_isEmptyMod(threadData, _inNewMod)))
{
_new_args = omc_InteractiveUtil_mergeElementArgs(threadData, _old_args, _new_args);
}
tmpMeta9 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _new_args, _new_eqmod);
_mod = tmpMeta9;
}
else
{
_new_args = omc_InteractiveUtil_propagateMod2(threadData, _inComponentName, _old_args, _inNewMod);
tmpMeta10 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _new_args, _old_eqmod);
_mod = tmpMeta10;
}
_outMod = (omc_AbsynUtil_isEmptyMod(threadData, _mod)?mmc_mk_none():mmc_mk_some(_mod));
_return: OMC_LABEL_UNUSED
return _outMod;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_setComponentSubmodifierInCompitems(threadData_t *threadData, modelica_metatype _inComponents, modelica_boolean _inFound, modelica_metatype _inComponentName, modelica_metatype _inMod, modelica_boolean *out_outFound, modelica_boolean *out_outContinue)
{
modelica_metatype _outComponents = NULL;
modelica_metatype tmpMeta1;
modelica_boolean _outFound;
modelica_boolean _outContinue;
modelica_metatype _item = NULL;
modelica_metatype _rest_items = NULL;
modelica_metatype _comp = NULL;
modelica_string _comp_id = NULL;
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
_comp_id = omc_AbsynUtil_pathFirstIdent(threadData, _inComponentName);
while(1)
{
if(!(!listEmpty(_rest_items))) break;
tmpMeta2 = _rest_items;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_item = tmpMeta3;
_rest_items = tmpMeta4;
if((stringEqual(omc_AbsynUtil_componentName(threadData, _item), _comp_id)))
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
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta10))[4] = omc_InteractiveUtil_propagateMod(threadData, _inComponentName, _inMod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_comp), 4))));
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
modelica_metatype boxptr_InteractiveUtil_setComponentSubmodifierInCompitems(threadData_t *threadData, modelica_metatype _inComponents, modelica_metatype _inFound, modelica_metatype _inComponentName, modelica_metatype _inMod, modelica_metatype *out_outFound, modelica_metatype *out_outContinue)
{
modelica_integer tmp1;
modelica_boolean _outFound;
modelica_boolean _outContinue;
modelica_metatype _outComponents = NULL;
modelica_metatype tmpMeta2;
tmp1 = mmc_unbox_integer(_inFound);
_outComponents = omc_InteractiveUtil_setComponentSubmodifierInCompitems(threadData, _inComponents, tmp1, _inComponentName, _inMod, &_outFound, &_outContinue);
if (out_outFound) { *out_outFound = mmc_mk_icon(_outFound); }
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _outComponents;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setSubmodifierInClass(threadData_t *threadData, modelica_metatype _inElementName, modelica_metatype _inClass, modelica_metatype _inMod)
{
modelica_metatype _outClass = NULL;
modelica_metatype _cls = NULL;
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
tmpMeta11 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_body), 4))), _OMC_LIT11);
tmpMeta12 = omc_InteractiveUtil_propagateMod(threadData, _inElementName, _inMod, mmc_mk_some(tmpMeta11));
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
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_cls), 12*sizeof(modelica_metatype));
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setSubmodifierInElementSpec(threadData_t *threadData, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype __omcQ_24in_5FelSpec)
{
modelica_metatype _elSpec = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elSpec = __omcQ_24in_5FelSpec;
{
modelica_metatype tmp3_1;
tmp3_1 = _elSpec;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_metatype tmpMeta5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta5 = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta5), MMC_UNTAGPTR(_elSpec), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta5))[3] = omc_InteractiveUtil_setSubmodifierInClass(threadData, _elementName, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elSpec), 3))), _mod);
_elSpec = tmpMeta5;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,3) == 0) goto tmp2_end;
tmpMeta6 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta6), MMC_UNTAGPTR(_elSpec), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta6))[4] = omc_InteractiveUtil_setComponentSubmodifierInCompitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elSpec), 4))), 0 /* false */, _elementName, _mod, NULL, NULL);
_elSpec = tmpMeta6;
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
return _elSpec;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setExtendsSubmodifierInElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _extendsPath, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype _env, modelica_boolean __omcQ_24in_5Ffound, modelica_boolean *out_found, modelica_boolean *out_outContinue)
{
modelica_metatype _element = NULL;
modelica_boolean _found;
modelica_boolean _outContinue;
modelica_metatype _ext_spec = NULL;
modelica_metatype _full_path = NULL;
modelica_metatype _eargs = NULL;
modelica_metatype _opt_mod = NULL;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = __omcQ_24in_5Felement;
_found = __omcQ_24in_5Ffound;
_outContinue = 1;
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _element;
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
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_ext_spec = tmpMeta6;
_eargs = tmpMeta7;
omc_Interactive_mkFullyQual(threadData, _env, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ext_spec), 2))), 0 /* false */ ,&_full_path);
tmp8 = omc_AbsynUtil_pathEqual(threadData, _extendsPath, _full_path);
if (1 /* true */ != tmp8) goto goto_2;
if((stringEqual(omc_AbsynUtil_pathFirstIdent(threadData, _elementName), _OMC_LIT130)))
{
tmpMeta9 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _eargs, _OMC_LIT11);
_opt_mod = omc_InteractiveUtil_propagateMod(threadData, _elementName, _mod, mmc_mk_some(tmpMeta9));
}
else
{
tmpMeta10 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _eargs, _OMC_LIT11);
_opt_mod = omc_InteractiveUtil_propagateMod(threadData, omc_AbsynUtil_prefixPath(threadData, _OMC_LIT168, _elementName), _mod, mmc_mk_some(tmpMeta10));
}
{
modelica_metatype tmp15_1;
tmp15_1 = _opt_mod;
{
volatile mmc_switch_type tmp15;
int tmp16;
tmp15 = 0;
for (; tmp15 < 2; tmp15++) {
switch (MMC_SWITCH_CAST(tmp15)) {
case 0: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (optionNone(tmp15_1)) goto tmp14_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp15_1), 1));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
_eargs = tmpMeta18;
tmpMeta12 = _eargs;
goto tmp14_done;
}
case 1: {
modelica_metatype tmpMeta19;
tmpMeta19 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta12 = tmpMeta19;
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
tmpMeta11 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta11), MMC_UNTAGPTR(_ext_spec), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta11))[3] = tmpMeta12;
_ext_spec = tmpMeta11;
tmpMeta20 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta20), MMC_UNTAGPTR(_element), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta20))[5] = _ext_spec;
_element = tmpMeta20;
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
_found = tmp1;
_outContinue = (!_found);
_return: OMC_LABEL_UNUSED
if (out_found) { *out_found = _found; }
if (out_outContinue) { *out_outContinue = _outContinue; }
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_setExtendsSubmodifierInElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _extendsPath, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype _env, modelica_metatype __omcQ_24in_5Ffound, modelica_metatype *out_found, modelica_metatype *out_outContinue)
{
modelica_integer tmp1;
modelica_boolean _found;
modelica_boolean _outContinue;
modelica_metatype _element = NULL;
tmp1 = mmc_unbox_integer(__omcQ_24in_5Ffound);
_element = omc_InteractiveUtil_setExtendsSubmodifierInElement(threadData, __omcQ_24in_5Felement, _extendsPath, _elementName, _mod, _env, tmp1, &_found, &_outContinue);
if (out_found) { *out_found = mmc_mk_icon(_found); }
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setSubmodifierInElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_boolean __omcQ_24in_5Ffound, modelica_metatype _elementName, modelica_metatype _mod, modelica_boolean *out_found, modelica_boolean *out_outContinue)
{
modelica_metatype _element = NULL;
modelica_boolean _found;
modelica_boolean _outContinue;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = __omcQ_24in_5Felement;
_found = __omcQ_24in_5Ffound;
_outContinue = 1;
if(omc_AbsynUtil_isElementNamed(threadData, omc_AbsynUtil_pathFirstIdent(threadData, _elementName), _element))
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
{
modelica_metatype tmp7_1;
tmp7_1 = _element;
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 1; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,6) == 0) goto tmp6_end;
tmpMeta9 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta9), MMC_UNTAGPTR(_element), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta9))[5] = omc_InteractiveUtil_setSubmodifierInElementSpec(threadData, _elementName, _mod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 5))));
_element = tmpMeta9;
goto tmp6_done;
}
}
goto tmp6_end;
tmp6_end: ;
}
goto goto_5;
goto_5:;
goto goto_1;
goto tmp6_done;
tmp6_done:;
}
}
;
_found = 1;
_outContinue = 0;
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
}
_return: OMC_LABEL_UNUSED
if (out_found) { *out_found = _found; }
if (out_outContinue) { *out_outContinue = _outContinue; }
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_setSubmodifierInElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype __omcQ_24in_5Ffound, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype *out_found, modelica_metatype *out_outContinue)
{
modelica_integer tmp1;
modelica_boolean _found;
modelica_boolean _outContinue;
modelica_metatype _element = NULL;
tmp1 = mmc_unbox_integer(__omcQ_24in_5Ffound);
_element = omc_InteractiveUtil_setSubmodifierInElement(threadData, __omcQ_24in_5Felement, tmp1, _elementName, _mod, &_found, &_outContinue);
if (out_found) { *out_found = mmc_mk_icon(_found); }
if (out_outContinue) { *out_outContinue = mmc_mk_icon(_outContinue); }
return _element;
}
static modelica_metatype closure24_InteractiveUtil_setExtendsSubmodifierInElement(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_element, modelica_metatype $in_found, modelica_metatype tmp3, modelica_metatype tmp4)
{
modelica_metatype extendsPath = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype elementName = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
modelica_metatype mod = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),3));
modelica_metatype env = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),4));
return boxptr_InteractiveUtil_setExtendsSubmodifierInElement(thData, $in_element, extendsPath, elementName, mod, env, $in_found, tmp3, tmp4);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setExtendsSubmodifierInClass(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype _extendsPath, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype _env, modelica_boolean *out_found)
{
modelica_metatype _cls = NULL;
modelica_boolean _found;
modelica_metatype tmpMeta1;
modelica_integer tmp2;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cls = __omcQ_24in_5Fcls;
tmpMeta5 = mmc_mk_box4(0, _extendsPath, _elementName, _mod, _env);
tmpMeta6 = omc_AbsynUtil_traverseClassElements(threadData, _cls, (modelica_fnptr) mmc_mk_box2(0,closure24_InteractiveUtil_setExtendsSubmodifierInElement,tmpMeta5), mmc_mk_boolean(0 /* false */), &tmpMeta1);
_cls = tmpMeta6;
tmp2 = mmc_unbox_integer(tmpMeta1);
_found = tmp2;
_return: OMC_LABEL_UNUSED
if (out_found) { *out_found = _found; }
return _cls;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_setExtendsSubmodifierInClass(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcls, modelica_metatype _extendsPath, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype _env, modelica_metatype *out_found)
{
modelica_boolean _found;
modelica_metatype _cls = NULL;
_cls = omc_InteractiveUtil_setExtendsSubmodifierInClass(threadData, __omcQ_24in_5Fcls, _extendsPath, _elementName, _mod, _env, &_found);
if (out_found) { *out_found = mmc_mk_icon(_found); }
return _cls;
}
static modelica_metatype closure25_InteractiveUtil_setSubmodifierInElement(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_element, modelica_metatype $in_found, modelica_metatype tmp3, modelica_metatype tmp4)
{
modelica_metatype elementName = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype mod = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_setSubmodifierInElement(thData, $in_element, $in_found, elementName, mod, tmp3, tmp4);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_InteractiveUtil_setElementSubmodifierInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inElementName, modelica_metatype _inMod, modelica_boolean *out_found)
{
modelica_metatype _outClass = NULL;
modelica_boolean _found;
modelica_metatype tmpMeta1;
modelica_integer tmp2;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClass = _inClass;
tmpMeta5 = mmc_mk_box2(0, _inElementName, _inMod);
tmpMeta6 = omc_AbsynUtil_traverseClassElements(threadData, _inClass, (modelica_fnptr) mmc_mk_box2(0,closure25_InteractiveUtil_setSubmodifierInElement,tmpMeta5), mmc_mk_boolean(0 /* false */), &tmpMeta1);
_outClass = tmpMeta6;
tmp2 = mmc_unbox_integer(tmpMeta1);
_found = tmp2;
_return: OMC_LABEL_UNUSED
if (out_found) { *out_found = _found; }
return _outClass;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_InteractiveUtil_setElementSubmodifierInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inElementName, modelica_metatype _inMod, modelica_metatype *out_found)
{
modelica_boolean _found;
modelica_metatype _outClass = NULL;
_outClass = omc_InteractiveUtil_setElementSubmodifierInClass(threadData, _inClass, _inElementName, _inMod, &_found);
if (out_found) { *out_found = mmc_mk_icon(_found); }
return _outClass;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_setExtendsModifier(threadData_t *threadData, modelica_metatype _className, modelica_metatype _extendsName, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype __omcQ_24in_5Fprogram, modelica_boolean *out_result)
{
modelica_metatype _program = NULL;
modelica_boolean _result;
modelica_metatype _within_ = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _env = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_program = __omcQ_24in_5Fprogram;
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
_cls = omc_ProgramUtil_getPathedClassInProgram(threadData, _className, _program, 0 /* false */, 0 /* false */);
_env = omc_Interactive_getClassEnv(threadData, _program, _className);
_cls = omc_InteractiveUtil_setExtendsSubmodifierInClass(threadData, _cls, _extendsName, _elementName, _mod, _env ,&_result);
_within_ = omc_ProgramUtil_buildWithin(threadData, _className);
tmpMeta5 = mmc_mk_cons(_cls, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta6 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta5, _within_);
_program = omc_ProgramUtil_updateProgram(threadData, tmpMeta6, _program, 0 /* false */);
goto tmp2_done;
}
case 1: {
_result = 0;
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
if (out_result) { *out_result = _result; }
return _program;
}
modelica_metatype boxptr_InteractiveUtil_setExtendsModifier(threadData_t *threadData, modelica_metatype _className, modelica_metatype _extendsName, modelica_metatype _elementName, modelica_metatype _mod, modelica_metatype __omcQ_24in_5Fprogram, modelica_metatype *out_result)
{
modelica_boolean _result;
modelica_metatype _program = NULL;
_program = omc_InteractiveUtil_setExtendsModifier(threadData, _className, _extendsName, _elementName, _mod, __omcQ_24in_5Fprogram, &_result);
if (out_result) { *out_result = mmc_mk_icon(_result); }
return _program;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_setElementModifier(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inElementName, modelica_metatype _inMod, modelica_metatype __omcQ_24in_5Fprogram, modelica_boolean *out_outResult)
{
modelica_metatype _program = NULL;
modelica_boolean _outResult;
modelica_metatype _within_ = NULL;
modelica_metatype _cls = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_program = __omcQ_24in_5Fprogram;
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
_cls = omc_ProgramUtil_getPathedClassInProgram(threadData, _inClass, _program, 0 /* false */, 0 /* false */);
_cls = omc_InteractiveUtil_setElementSubmodifierInClass(threadData, _cls, _inElementName, _inMod ,&_outResult);
_within_ = omc_ProgramUtil_buildWithin(threadData, _inClass);
tmpMeta5 = mmc_mk_cons(_cls, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta6 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta5, _within_);
_program = omc_ProgramUtil_updateProgram(threadData, tmpMeta6, _program, 0 /* false */);
goto tmp2_done;
}
case 1: {
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
return _program;
}
modelica_metatype boxptr_InteractiveUtil_setElementModifier(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inElementName, modelica_metatype _inMod, modelica_metatype __omcQ_24in_5Fprogram, modelica_metatype *out_outResult)
{
modelica_boolean _outResult;
modelica_metatype _program = NULL;
_program = omc_InteractiveUtil_setElementModifier(threadData, _inClass, _inElementName, _inMod, __omcQ_24in_5Fprogram, &_outResult);
if (out_outResult) { *out_outResult = mmc_mk_icon(_outResult); }
return _program;
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
modelica_metatype __omcQ_24tmpVar95;
modelica_metatype* tmp9;
modelica_metatype tmpMeta10;
modelica_metatype __omcQ_24tmpVar94;
modelica_integer tmp11;
modelica_metatype _e_loopVar = 0;
modelica_boolean tmp12 = 0;
modelica_metatype _e;
_e_loopVar = _ea;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar95 = tmpMeta10;
tmp9 = &__omcQ_24tmpVar95;
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
__omcQ_24tmpVar94 = _e;
*tmp9 = mmc_mk_cons(__omcQ_24tmpVar94,0);
tmp9 = &MMC_CDR(*tmp9);
} else if (tmp11 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp9 = mmc_mk_nil();
tmpMeta8 = __omcQ_24tmpVar95;
}
_ea = tmpMeta8;
tmpMeta17 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _ea, _OMC_LIT11);
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
static modelica_metatype closure26_InteractiveUtil_clearComponentModifiersInCompitems(threadData_t *thData, modelica_metatype closure, modelica_metatype inComponents, modelica_metatype inFound, modelica_metatype tmp3, modelica_metatype tmp4)
{
modelica_string inComponentName = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype keepRedeclares = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
return boxptr_InteractiveUtil_clearComponentModifiersInCompitems(thData, inComponents, inFound, inComponentName, keepRedeclares, tmp3, tmp4);
}
DLLDirection
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
tmpMeta6 = omc_AbsynUtil_traverseClassComponents(threadData, _inClass, (modelica_fnptr) mmc_mk_box2(0,closure26_InteractiveUtil_clearComponentModifiersInCompitems,tmpMeta5), mmc_mk_boolean(0 /* false */), &tmpMeta1);
_outClass = tmpMeta6;
tmp2 = mmc_unbox_integer(tmpMeta1);
if (1 /* true */ != tmp2) MMC_THROW_INTERNAL();
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
DLLDirection
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
_within_ = omc_ProgramUtil_buildWithin(threadData, _path);
_cls = omc_ProgramUtil_getPathedClassInProgram(threadData, _path, _inProgram, 0 /* false */, 0 /* false */);
_cls = omc_InteractiveUtil_clearComponentModifiersInClass(threadData, _cls, _inComponentName, _keepRedeclares);
tmpMeta5 = mmc_mk_cons(_cls, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta6 = mmc_mk_box3(3, &Absyn_Program_PROGRAM__desc, tmpMeta5, _within_);
_outProgram = omc_ProgramUtil_updateProgram(threadData, tmpMeta6, _inProgram, 0 /* false */);
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
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _lst1 = NULL;
modelica_metatype _lst2 = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
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
_elts = tmpMeta9;
_rest = tmpMeta8;
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
_inAbsynClassPartLst = _rest;
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
_outAbsynElementSpecLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynElementSpecLst;
}
DLLDirection
modelica_metatype omc_InteractiveUtil_getExtendsElementspecInClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _outAbsynElementSpecLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_metatype _parts = NULL;
modelica_metatype _eltArg = NULL;
modelica_metatype _tp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_parts = tmpMeta7;
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
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outAbsynElementSpecLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynElementSpecLst;
}
