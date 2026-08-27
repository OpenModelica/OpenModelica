#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/SCodeUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "SCodeUtil.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "Invalid use of reserved attribute name %s as enumeration literal."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,65,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(127)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "quantity"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,8,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data "min"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,3,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "max"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,3,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "start"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,5,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "fixed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,5,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,2,1) {_OMC_LIT9,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,2,1) {_OMC_LIT8,_OMC_LIT10}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,2,1) {_OMC_LIT7,_OMC_LIT11}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,2,1) {_OMC_LIT6,_OMC_LIT12}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,2,1) {_OMC_LIT5,_OMC_LIT13}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,1,5) {&SCode_Mod_NOMOD__desc,}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "constructor"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,11,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "destructor"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,10,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "ExternalObject"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,14,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "__OpenModelica_builtin"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,22,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "builtin"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,7,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
#define _OMC_LIT22_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT22,1,_OMC_LIT22_data);
#define _OMC_LIT22 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,1,4) {&SCode_Visibility_PROTECTED__desc,}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,0,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT25,0.0);
#define _OMC_LIT25 MMC_REFREALLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT24,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT25}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "Inline"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,6,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "LateInline"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,10,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "InlineAfterIndexReduction"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,25,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data "Evaluate"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,8,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,1,5) {&SCode_ConnectorType_STREAM__desc,}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,1,3) {&SCode_ConnectorType_POTENTIAL__desc,}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,1,4) {&SCode_ConnectorType_FLOW__desc,}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,1,3) {&SCode_Final_FINAL__desc,}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,1,4) {&SCode_Final_NOT__FINAL__desc,}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,1,3) {&SCode_Partial_PARTIAL__desc,}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,1,4) {&SCode_Partial_NOT__PARTIAL__desc,}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,1,3) {&SCode_Encapsulated_ENCAPSULATED__desc,}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,1,4) {&SCode_Encapsulated_NOT__ENCAPSULATED__desc,}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "Ignoring constraint class because replaceable prefix is not present!\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,69,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,1,4) {&SCode_Replaceable_NOT__REPLACEABLE__desc,}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT42,1,3) {&SCode_Redeclare_REDECLARE__desc,}};
#define _OMC_LIT42 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT42)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT43,1,4) {&SCode_Redeclare_NOT__REDECLARE__desc,}};
#define _OMC_LIT43 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,1,3) {&SCode_Each_EACH__desc,}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,1,4) {&SCode_Each_NOT__EACH__desc,}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,1,3) {&SCode_Visibility_PUBLIC__desc,}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "SCodeUtil.getStatementInfo failed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,33,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
#define _OMC_LIT48_data "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/FrontEnd/SCodeUtil.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT48,70,_OMC_LIT48_data);
#define _OMC_LIT48 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT49_6,1605787387.0);
#define _OMC_LIT49_6 MMC_REFREALLIT(_OMC_LIT_STRUCT49_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT48,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2717)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(2717)),MMC_IMMEDIATE(MMC_TAGFIXNUM(82)),_OMC_LIT49_6}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
#define _OMC_LIT50_data "sin"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT50,3,_OMC_LIT50_data);
#define _OMC_LIT50 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT50)
#define _OMC_LIT51_data "cos"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT51,3,_OMC_LIT51_data);
#define _OMC_LIT51 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT51)
#define _OMC_LIT52_data "tan"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT52,3,_OMC_LIT52_data);
#define _OMC_LIT52 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "asin"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,4,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data "acos"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,4,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
#define _OMC_LIT55_data "atan"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT55,4,_OMC_LIT55_data);
#define _OMC_LIT55 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "atan2"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,5,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "sinh"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,4,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "cosh"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,4,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "tanh"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,4,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "exp"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,3,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "log"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,3,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "log10"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,5,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "sqrt"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,4,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT64,2,1) {_OMC_LIT63,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT64 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT64)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT65,2,1) {_OMC_LIT62,_OMC_LIT64}};
#define _OMC_LIT65 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT65)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT66,2,1) {_OMC_LIT61,_OMC_LIT65}};
#define _OMC_LIT66 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT66)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT67,2,1) {_OMC_LIT60,_OMC_LIT66}};
#define _OMC_LIT67 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT67)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT68,2,1) {_OMC_LIT59,_OMC_LIT67}};
#define _OMC_LIT68 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT68)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT69,2,1) {_OMC_LIT58,_OMC_LIT68}};
#define _OMC_LIT69 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT69)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT70,2,1) {_OMC_LIT57,_OMC_LIT69}};
#define _OMC_LIT70 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT70)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT71,2,1) {_OMC_LIT56,_OMC_LIT70}};
#define _OMC_LIT71 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT71)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT72,2,1) {_OMC_LIT55,_OMC_LIT71}};
#define _OMC_LIT72 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT72)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT73,2,1) {_OMC_LIT54,_OMC_LIT72}};
#define _OMC_LIT73 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT73)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT74,2,1) {_OMC_LIT53,_OMC_LIT73}};
#define _OMC_LIT74 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT74)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT75,2,1) {_OMC_LIT52,_OMC_LIT74}};
#define _OMC_LIT75 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT75)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT76,2,1) {_OMC_LIT51,_OMC_LIT75}};
#define _OMC_LIT76 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT76)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT77,2,1) {_OMC_LIT50,_OMC_LIT76}};
#define _OMC_LIT77 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data "C"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,1,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
#define _OMC_LIT79_data "assert"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT79,6,_OMC_LIT79_data);
#define _OMC_LIT79 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT79)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT80,3,5) {&Absyn_ComponentRef_CREF__IDENT__desc,_OMC_LIT79,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT80 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data "terminate"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,9,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT82,3,5) {&Absyn_ComponentRef_CREF__IDENT__desc,_OMC_LIT81,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT82 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT82)
#define _OMC_LIT83_data "reinit"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT83,6,_OMC_LIT83_data);
#define _OMC_LIT83 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT83)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT84,3,5) {&Absyn_ComponentRef_CREF__IDENT__desc,_OMC_LIT83,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT84 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT84)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT85,1,10) {&Absyn_Algorithm_ALG__RETURN__desc,}};
#define _OMC_LIT85 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT85)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT86,1,11) {&Absyn_Algorithm_ALG__BREAK__desc,}};
#define _OMC_LIT86 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT86)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT87,1,14) {&Absyn_Algorithm_ALG__CONTINUE__desc,}};
#define _OMC_LIT87 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT87)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT88,1,6) {&SCode_Variability_CONST__desc,}};
#define _OMC_LIT88 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT88)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT89,1,5) {&SCode_Variability_PARAM__desc,}};
#define _OMC_LIT89 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT89)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT90,1,4) {&SCode_Variability_DISCRETE__desc,}};
#define _OMC_LIT90 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT90)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT91,1,3) {&SCode_Variability_VAR__desc,}};
#define _OMC_LIT91 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT91)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT92,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT92 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT92)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT93,6,3) {&SCode_Prefixes_PREFIXES__desc,_OMC_LIT46,_OMC_LIT43,_OMC_LIT35,_OMC_LIT92,_OMC_LIT41}};
#define _OMC_LIT93 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT93)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT94,1,5) {&SCode_Parallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT94 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT94)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT95,1,5) {&Absyn_Direction_BIDIR__desc,}};
#define _OMC_LIT95 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT95)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT96,1,3) {&Absyn_IsField_NONFIELD__desc,}};
#define _OMC_LIT96 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT96)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT97,7,3) {&SCode_Attributes_ATTR__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT32,_OMC_LIT94,_OMC_LIT88,_OMC_LIT95,_OMC_LIT96}};
#define _OMC_LIT97 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT97)
#define _OMC_LIT98_data "EnumType"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT98,8,_OMC_LIT98_data);
#define _OMC_LIT98 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT98)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT99,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT98}};
#define _OMC_LIT99 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT99)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT100,3,3) {&Absyn_TypeSpec_TPATH__desc,_OMC_LIT99,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT100 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT100)
#define _OMC_LIT101_data "polymorphic"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT101,11,_OMC_LIT101_data);
#define _OMC_LIT101 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT101)
#include "util/modelica.h"
#include "SCodeUtil_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_hasExternalObjectConstructor(threadData_t *threadData, modelica_metatype _inEls);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_hasExternalObjectConstructor(threadData_t *threadData, modelica_metatype _inEls);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_hasExternalObjectConstructor,2,0) {(void*) boxptr_SCodeUtil_hasExternalObjectConstructor,0}};
#define boxvar_SCodeUtil_hasExternalObjectConstructor MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_hasExternalObjectConstructor)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_hasExternalObjectDestructor(threadData_t *threadData, modelica_metatype _inEls);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_hasExternalObjectDestructor(threadData_t *threadData, modelica_metatype _inEls);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_hasExternalObjectDestructor,2,0) {(void*) boxptr_SCodeUtil_hasExternalObjectDestructor,0}};
#define boxvar_SCodeUtil_hasExternalObjectDestructor MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_hasExternalObjectDestructor)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_hasExtendsOfExternalObject(threadData_t *threadData, modelica_metatype _inEls);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_hasExtendsOfExternalObject(threadData_t *threadData, modelica_metatype _inEls);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_hasExtendsOfExternalObject,2,0) {(void*) boxptr_SCodeUtil_hasExtendsOfExternalObject,0}};
#define boxvar_SCodeUtil_hasExtendsOfExternalObject MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_hasExtendsOfExternalObject)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_removeSub(threadData_t *threadData, modelica_metatype _inSub, modelica_metatype _inOld);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_removeSub,2,0) {(void*) boxptr_SCodeUtil_removeSub,0}};
#define boxvar_SCodeUtil_removeSub MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_removeSub)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_mergeSubMods(threadData_t *threadData, modelica_metatype _inNew, modelica_metatype _inOld);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_mergeSubMods,2,0) {(void*) boxptr_SCodeUtil_mergeSubMods,0}};
#define boxvar_SCodeUtil_mergeSubMods MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_mergeSubMods)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_mergeBindings(threadData_t *threadData, modelica_metatype _inNew, modelica_metatype _inOld);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_mergeBindings,2,0) {(void*) boxptr_SCodeUtil_mergeBindings,0}};
#define boxvar_SCodeUtil_mergeBindings MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_mergeBindings)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_partitionElements2(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inComponents, modelica_metatype _inClasses, modelica_metatype _inExtends, modelica_metatype _inImports, modelica_metatype _inDefineUnits, modelica_metatype *out_outClasses, modelica_metatype *out_outExtends, modelica_metatype *out_outImports, modelica_metatype *out_outDefineUnits);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_partitionElements2,2,0) {(void*) boxptr_SCodeUtil_partitionElements2,0}};
#define boxvar_SCodeUtil_partitionElements2 MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_partitionElements2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_setClassDefMod(threadData_t *threadData, modelica_metatype _inClassDef, modelica_metatype _inMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_setClassDefMod,2,0) {(void*) boxptr_SCodeUtil_setClassDefMod,0}};
#define boxvar_SCodeUtil_setClassDefMod MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_setClassDefMod)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_getElementWithId(threadData_t *threadData, modelica_metatype _inProgram, modelica_string _inId);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_getElementWithId,2,0) {(void*) boxptr_SCodeUtil_getElementWithId,0}};
#define boxvar_SCodeUtil_getElementWithId MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_getElementWithId)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_isInlineTypeSubMod(threadData_t *threadData, modelica_metatype _inSubMod);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_isInlineTypeSubMod(threadData_t *threadData, modelica_metatype _inSubMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_isInlineTypeSubMod,2,0) {(void*) boxptr_SCodeUtil_isInlineTypeSubMod,0}};
#define boxvar_SCodeUtil_isInlineTypeSubMod MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_isInlineTypeSubMod)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_getInlineTypeAnnotation(threadData_t *threadData, modelica_metatype _inAnnotation);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_getInlineTypeAnnotation,2,0) {(void*) boxptr_SCodeUtil_getInlineTypeAnnotation,0}};
#define boxvar_SCodeUtil_getInlineTypeAnnotation MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_getInlineTypeAnnotation)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_hasBooleanNamedAnnotation2(threadData_t *threadData, modelica_metatype _inSubMod, modelica_string _inName);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_hasBooleanNamedAnnotation2(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_hasBooleanNamedAnnotation2,2,0) {(void*) boxptr_SCodeUtil_hasBooleanNamedAnnotation2,0}};
#define boxvar_SCodeUtil_hasBooleanNamedAnnotation2 MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_hasBooleanNamedAnnotation2)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_hasNamedAnnotation(threadData_t *threadData, modelica_metatype _inSubMod, modelica_string _inName);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_hasNamedAnnotation(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_hasNamedAnnotation,2,0) {(void*) boxptr_SCodeUtil_hasNamedAnnotation,0}};
#define boxvar_SCodeUtil_hasNamedAnnotation MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_hasNamedAnnotation)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_isNotBuiltinClass(threadData_t *threadData, modelica_metatype _inClass);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_isNotBuiltinClass(threadData_t *threadData, modelica_metatype _inClass);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_isNotBuiltinClass,2,0) {(void*) boxptr_SCodeUtil_isNotBuiltinClass,0}};
#define boxvar_SCodeUtil_isNotBuiltinClass MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_isNotBuiltinClass)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseBranchExps(threadData_t *threadData, modelica_metatype _inBranch, modelica_fnptr _traverser, modelica_metatype _inArg, modelica_metatype *out_outArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseBranchExps,2,0) {(void*) boxptr_SCodeUtil_traverseBranchExps,0}};
#define boxvar_SCodeUtil_traverseBranchExps MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseBranchExps)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseBranchStatements(threadData_t *threadData, modelica_metatype _inBranch, modelica_metatype _inTuple, modelica_metatype *out_outTuple);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseBranchStatements,2,0) {(void*) boxptr_SCodeUtil_traverseBranchStatements,0}};
#define boxvar_SCodeUtil_traverseBranchStatements MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseBranchStatements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseForIteratorExps(threadData_t *threadData, modelica_metatype _inIterator, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseForIteratorExps,2,0) {(void*) boxptr_SCodeUtil_traverseForIteratorExps,0}};
#define boxvar_SCodeUtil_traverseForIteratorExps MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseForIteratorExps)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseNamedArgExps(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inTuple, modelica_metatype *out_outTuple);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseNamedArgExps,2,0) {(void*) boxptr_SCodeUtil_traverseNamedArgExps,0}};
#define boxvar_SCodeUtil_traverseNamedArgExps MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseNamedArgExps)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseElseWhenExps(threadData_t *threadData, modelica_metatype _inElseWhen, modelica_fnptr _traverser, modelica_metatype _inArg, modelica_metatype *out_outArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseElseWhenExps,2,0) {(void*) boxptr_SCodeUtil_traverseElseWhenExps,0}};
#define boxvar_SCodeUtil_traverseElseWhenExps MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseElseWhenExps)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseSubscriptExps(threadData_t *threadData, modelica_metatype _inSubscript, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseSubscriptExps,2,0) {(void*) boxptr_SCodeUtil_traverseSubscriptExps,0}};
#define boxvar_SCodeUtil_traverseSubscriptExps MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseSubscriptExps)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseComponentRefExps(threadData_t *threadData, modelica_metatype _inCref, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseComponentRefExps,2,0) {(void*) boxptr_SCodeUtil_traverseComponentRefExps,0}};
#define boxvar_SCodeUtil_traverseComponentRefExps MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseComponentRefExps)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseElseWhenEEquations(threadData_t *threadData, modelica_metatype _inElseWhen, modelica_metatype _inTuple, modelica_metatype *out_outTuple);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseElseWhenEEquations,2,0) {(void*) boxptr_SCodeUtil_traverseElseWhenEEquations,0}};
#define boxvar_SCodeUtil_traverseElseWhenEEquations MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_traverseElseWhenEEquations)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_filterComponents2(threadData_t *threadData, modelica_metatype _inElement, modelica_string *out_outName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_filterComponents2,2,0) {(void*) boxptr_SCodeUtil_filterComponents2,0}};
#define boxvar_SCodeUtil_filterComponents2 MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_filterComponents2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_filterComponents(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype *out_outComponentNames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_filterComponents,2,0) {(void*) boxptr_SCodeUtil_filterComponents,0}};
#define boxvar_SCodeUtil_filterComponents MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_filterComponents)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_arrayDimEqual(threadData_t *threadData, modelica_metatype _iad1, modelica_metatype _iad2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_arrayDimEqual(threadData_t *threadData, modelica_metatype _iad1, modelica_metatype _iad2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_arrayDimEqual,2,0) {(void*) boxptr_SCodeUtil_arrayDimEqual,0}};
#define boxvar_SCodeUtil_arrayDimEqual MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_arrayDimEqual)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_subscriptsEqual(threadData_t *threadData, modelica_metatype _inSs1, modelica_metatype _inSs2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_subscriptsEqual(threadData_t *threadData, modelica_metatype _inSs1, modelica_metatype _inSs2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_subscriptsEqual,2,0) {(void*) boxptr_SCodeUtil_subscriptsEqual,0}};
#define boxvar_SCodeUtil_subscriptsEqual MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_subscriptsEqual)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_subModsEqual(threadData_t *threadData, modelica_metatype _inSubModLst1, modelica_metatype _inSubModLst2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_subModsEqual(threadData_t *threadData, modelica_metatype _inSubModLst1, modelica_metatype _inSubModLst2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_subModsEqual,2,0) {(void*) boxptr_SCodeUtil_subModsEqual,0}};
#define boxvar_SCodeUtil_subModsEqual MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_subModsEqual)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_equationEqual22(threadData_t *threadData, modelica_metatype _inTb1, modelica_metatype _inTb2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_equationEqual22(threadData_t *threadData, modelica_metatype _inTb1, modelica_metatype _inTb2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_equationEqual22,2,0) {(void*) boxptr_SCodeUtil_equationEqual22,0}};
#define boxvar_SCodeUtil_equationEqual22 MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_equationEqual22)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_equationEqual2(threadData_t *threadData, modelica_metatype _eq1, modelica_metatype _eq2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_equationEqual2(threadData_t *threadData, modelica_metatype _eq1, modelica_metatype _eq2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_equationEqual2,2,0) {(void*) boxptr_SCodeUtil_equationEqual2,0}};
#define boxvar_SCodeUtil_equationEqual2 MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_equationEqual2)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_algorithmEqual2(threadData_t *threadData, modelica_metatype _ai1, modelica_metatype _ai2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_algorithmEqual2(threadData_t *threadData, modelica_metatype _ai1, modelica_metatype _ai2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_algorithmEqual2,2,0) {(void*) boxptr_SCodeUtil_algorithmEqual2,0}};
#define boxvar_SCodeUtil_algorithmEqual2 MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_algorithmEqual2)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_algorithmEqual(threadData_t *threadData, modelica_metatype _alg1, modelica_metatype _alg2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_algorithmEqual(threadData_t *threadData, modelica_metatype _alg1, modelica_metatype _alg2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_algorithmEqual,2,0) {(void*) boxptr_SCodeUtil_algorithmEqual,0}};
#define boxvar_SCodeUtil_algorithmEqual MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_algorithmEqual)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_subscriptEqual(threadData_t *threadData, modelica_metatype _sub1, modelica_metatype _sub2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_subscriptEqual(threadData_t *threadData, modelica_metatype _sub1, modelica_metatype _sub2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_subscriptEqual,2,0) {(void*) boxptr_SCodeUtil_subscriptEqual,0}};
#define boxvar_SCodeUtil_subscriptEqual MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_subscriptEqual)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_arraydimOptEqual(threadData_t *threadData, modelica_metatype _adopt1, modelica_metatype _adopt2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_arraydimOptEqual(threadData_t *threadData, modelica_metatype _adopt1, modelica_metatype _adopt2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_arraydimOptEqual,2,0) {(void*) boxptr_SCodeUtil_arraydimOptEqual,0}};
#define boxvar_SCodeUtil_arraydimOptEqual MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_arraydimOptEqual)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_classDefEqual(threadData_t *threadData, modelica_metatype _cdef1, modelica_metatype _cdef2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_classDefEqual(threadData_t *threadData, modelica_metatype _cdef1, modelica_metatype _cdef2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_classDefEqual,2,0) {(void*) boxptr_SCodeUtil_classDefEqual,0}};
#define boxvar_SCodeUtil_classDefEqual MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_classDefEqual)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_elementNamesWork(threadData_t *threadData, modelica_metatype _e, modelica_metatype _acc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_SCodeUtil_elementNamesWork,2,0) {(void*) boxptr_SCodeUtil_elementNamesWork,0}};
#define boxvar_SCodeUtil_elementNamesWork MMC_REFSTRUCTLIT(boxvar_lit_SCodeUtil_elementNamesWork)
DLLExport
modelica_boolean omc_SCodeUtil_hasNamedExternalCall(threadData_t *threadData, modelica_string _name, modelica_metatype _def)
{
modelica_boolean _hasCall;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _def;
{
modelica_string _fn_name = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
if (optionNone(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (optionNone(tmpMeta[2])) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_fn_name = tmpMeta[3];
tmp1 = (stringEqual(_fn_name, _name));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
_def = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_def), 3)));
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
_hasCall = tmp1;
_return: OMC_LABEL_UNUSED
return _hasCall;
}
modelica_metatype boxptr_SCodeUtil_hasNamedExternalCall(threadData_t *threadData, modelica_metatype _name, modelica_metatype _def)
{
modelica_boolean _hasCall;
modelica_metatype out_hasCall;
_hasCall = omc_SCodeUtil_hasNamedExternalCall(threadData, _name, _def);
out_hasCall = mmc_mk_icon(_hasCall);
return out_hasCall;
}
DLLExport
modelica_metatype omc_SCodeUtil_mergeSCodeMods(threadData_t *threadData, modelica_metatype _inModOuter, modelica_metatype _inModInner)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inModOuter;
tmp3_2 = _inModInner;
{
modelica_metatype _f1 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _subMods1 = NULL;
modelica_metatype _subMods2 = NULL;
modelica_metatype _b1 = NULL;
modelica_metatype _b2 = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _inModInner;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _inModOuter;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,5) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 5));
_f1 = tmpMeta[1];
_e1 = tmpMeta[2];
_subMods1 = tmpMeta[3];
_b1 = tmpMeta[4];
_info = tmpMeta[5];
_subMods2 = tmpMeta[6];
_b2 = tmpMeta[7];
_subMods2 = listAppend(_subMods1, _subMods2);
_b1 = (isSome(_b1)?_b1:_b2);
tmpMeta[1] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _f1, _e1, _subMods2, _b1, _info);
tmpMeta[0] = tmpMeta[1];
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
_outMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMod;
}
DLLExport
modelica_metatype omc_SCodeUtil_mergeSCodeOptAnn(threadData_t *threadData, modelica_metatype _inModOuter, modelica_metatype _inModInner)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inModOuter;
tmp3_2 = _inModInner;
{
modelica_metatype _mod1 = NULL;
modelica_metatype _mod2 = NULL;
modelica_metatype _mod = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _inModInner;
goto tmp2_done;
}
case 1: {
if (!optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[0] = _inModOuter;
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_mod1 = tmpMeta[2];
_mod2 = tmpMeta[4];
_mod = omc_SCodeUtil_mergeSCodeMods(threadData, _mod1, _mod2);
tmpMeta[1] = mmc_mk_box2(3, &SCode_Annotation_ANNOTATION__desc, _mod);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
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
_outMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMod;
}
DLLExport
modelica_boolean omc_SCodeUtil_isRedeclareElement(threadData_t *threadData, modelica_metatype _element)
{
modelica_boolean _isElement;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _element;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,2) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,0) == 0) goto tmp3_end;
tmp1 = 1;
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
_isElement = tmp1;
_return: OMC_LABEL_UNUSED
return _isElement;
}
modelica_metatype boxptr_SCodeUtil_isRedeclareElement(threadData_t *threadData, modelica_metatype _element)
{
modelica_boolean _isElement;
modelica_metatype out_isElement;
_isElement = omc_SCodeUtil_isRedeclareElement(threadData, _element);
out_isElement = mmc_mk_icon(_isElement);
return out_isElement;
}
DLLExport
void omc_SCodeUtil_checkValidEnumLiteral(threadData_t *threadData, modelica_string _inLiteral, modelica_metatype _inInfo)
{
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(listMember(_inLiteral, _OMC_LIT14))
{
tmpMeta[0] = mmc_mk_cons(_inLiteral, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT4, tmpMeta[0], _inInfo);
MMC_THROW_INTERNAL();
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromStatementBranch(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fbranch, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _branch = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _body = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_branch = __omcQ_24in_5Fbranch;
tmpMeta[0] = _branch;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_cond = tmpMeta[1];
_body = tmpMeta[2];
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar0;
int tmp2;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = _body;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar1;
while(1) {
tmp2 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp2--;
}
if (tmp2 == 0) {
__omcQ_24tmpVar0 = omc_SCodeUtil_stripCommentsFromStatement(threadData, _s, _stripAnn, _stripCmt);
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
_body = tmpMeta[0];
tmpMeta[0] = mmc_mk_box2(0, _cond, _body);
_branch = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _branch;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromStatementBranch(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fbranch, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _branch = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_branch = omc_SCodeUtil_stripCommentsFromStatementBranch(threadData, __omcQ_24in_5Fbranch, tmp1, tmp2);
return _branch;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromStatement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fstmt, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _stmt = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_stmt = __omcQ_24in_5Fstmt;
{
modelica_metatype tmp3_1;
tmp3_1 = _stmt;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 4: {
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp4;
modelica_metatype __omcQ_24tmpVar2;
int tmp5;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta[2];
tmp4 = &__omcQ_24tmpVar3;
while(1) {
tmp5 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp5--;
}
if (tmp5 == 0) {
__omcQ_24tmpVar2 = omc_SCodeUtil_stripCommentsFromStatement(threadData, _s, _stripAnn, _stripCmt);
*tmp4 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp4 = &MMC_CDR(*tmp4);
} else if (tmp5 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp4 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar3;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = tmpMeta[1];
_stmt = tmpMeta[0];
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp6;
modelica_metatype __omcQ_24tmpVar4;
int tmp7;
modelica_metatype _b_loopVar = 0;
modelica_metatype _b;
_b_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta[2];
tmp6 = &__omcQ_24tmpVar5;
while(1) {
tmp7 = 1;
if (!listEmpty(_b_loopVar)) {
_b = MMC_CAR(_b_loopVar);
_b_loopVar = MMC_CDR(_b_loopVar);
tmp7--;
}
if (tmp7 == 0) {
__omcQ_24tmpVar4 = omc_SCodeUtil_stripCommentsFromStatementBranch(threadData, _b, _stripAnn, _stripCmt);
*tmp6 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp6 = &MMC_CDR(*tmp6);
} else if (tmp7 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp6 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar5;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = tmpMeta[1];
_stmt = tmpMeta[0];
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp8;
modelica_metatype __omcQ_24tmpVar6;
int tmp9;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta[2];
tmp8 = &__omcQ_24tmpVar7;
while(1) {
tmp9 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar6 = omc_SCodeUtil_stripCommentsFromStatement(threadData, _s, _stripAnn, _stripCmt);
*tmp8 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp8 = &MMC_CDR(*tmp8);
} else if (tmp9 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp8 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar7;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = tmpMeta[1];
_stmt = tmpMeta[0];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[6] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 6))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 5: {
{
modelica_metatype __omcQ_24tmpVar9;
modelica_metatype* tmp10;
modelica_metatype __omcQ_24tmpVar8;
int tmp11;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar9 = tmpMeta[2];
tmp10 = &__omcQ_24tmpVar9;
while(1) {
tmp11 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp11--;
}
if (tmp11 == 0) {
__omcQ_24tmpVar8 = omc_SCodeUtil_stripCommentsFromStatement(threadData, _s, _stripAnn, _stripCmt);
*tmp10 = mmc_mk_cons(__omcQ_24tmpVar8,0);
tmp10 = &MMC_CDR(*tmp10);
} else if (tmp11 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp10 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar9;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = tmpMeta[1];
_stmt = tmpMeta[0];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 6: {
{
modelica_metatype __omcQ_24tmpVar11;
modelica_metatype* tmp12;
modelica_metatype __omcQ_24tmpVar10;
int tmp13;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar11 = tmpMeta[2];
tmp12 = &__omcQ_24tmpVar11;
while(1) {
tmp13 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp13--;
}
if (tmp13 == 0) {
__omcQ_24tmpVar10 = omc_SCodeUtil_stripCommentsFromStatement(threadData, _s, _stripAnn, _stripCmt);
*tmp12 = mmc_mk_cons(__omcQ_24tmpVar10,0);
tmp12 = &MMC_CDR(*tmp12);
} else if (tmp13 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp12 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar11;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = tmpMeta[1];
_stmt = tmpMeta[0];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 7: {
{
modelica_metatype __omcQ_24tmpVar13;
modelica_metatype* tmp14;
modelica_metatype __omcQ_24tmpVar12;
int tmp15;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar13 = tmpMeta[2];
tmp14 = &__omcQ_24tmpVar13;
while(1) {
tmp15 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp15--;
}
if (tmp15 == 0) {
__omcQ_24tmpVar12 = omc_SCodeUtil_stripCommentsFromStatement(threadData, _s, _stripAnn, _stripCmt);
*tmp14 = mmc_mk_cons(__omcQ_24tmpVar12,0);
tmp14 = &MMC_CDR(*tmp14);
} else if (tmp15 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp14 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar13;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = tmpMeta[1];
_stmt = tmpMeta[0];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 8: {
{
modelica_metatype __omcQ_24tmpVar15;
modelica_metatype* tmp16;
modelica_metatype __omcQ_24tmpVar14;
int tmp17;
modelica_metatype _b_loopVar = 0;
modelica_metatype _b;
_b_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 2)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar15 = tmpMeta[2];
tmp16 = &__omcQ_24tmpVar15;
while(1) {
tmp17 = 1;
if (!listEmpty(_b_loopVar)) {
_b = MMC_CAR(_b_loopVar);
_b_loopVar = MMC_CDR(_b_loopVar);
tmp17--;
}
if (tmp17 == 0) {
__omcQ_24tmpVar14 = omc_SCodeUtil_stripCommentsFromStatementBranch(threadData, _b, _stripAnn, _stripCmt);
*tmp16 = mmc_mk_cons(__omcQ_24tmpVar14,0);
tmp16 = &MMC_CDR(*tmp16);
} else if (tmp17 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp16 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar15;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = tmpMeta[1];
_stmt = tmpMeta[0];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 9: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 10: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 11: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 12: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 13: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 2))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 14: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 2))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 15: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 16: {
{
modelica_metatype __omcQ_24tmpVar17;
modelica_metatype* tmp18;
modelica_metatype __omcQ_24tmpVar16;
int tmp19;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 2)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar17 = tmpMeta[2];
tmp18 = &__omcQ_24tmpVar17;
while(1) {
tmp19 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp19--;
}
if (tmp19 == 0) {
__omcQ_24tmpVar16 = omc_SCodeUtil_stripCommentsFromStatement(threadData, _s, _stripAnn, _stripCmt);
*tmp18 = mmc_mk_cons(__omcQ_24tmpVar16,0);
tmp18 = &MMC_CDR(*tmp18);
} else if (tmp19 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp18 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar17;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = tmpMeta[1];
_stmt = tmpMeta[0];
{
modelica_metatype __omcQ_24tmpVar19;
modelica_metatype* tmp20;
modelica_metatype __omcQ_24tmpVar18;
int tmp21;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar19 = tmpMeta[2];
tmp20 = &__omcQ_24tmpVar19;
while(1) {
tmp21 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp21--;
}
if (tmp21 == 0) {
__omcQ_24tmpVar18 = omc_SCodeUtil_stripCommentsFromStatement(threadData, _s, _stripAnn, _stripCmt);
*tmp20 = mmc_mk_cons(__omcQ_24tmpVar18,0);
tmp20 = &MMC_CDR(*tmp20);
} else if (tmp21 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp20 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar19;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = tmpMeta[1];
_stmt = tmpMeta[0];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
goto tmp2_done;
}
case 17: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_stmt), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 2))), _stripAnn, _stripCmt);
_stmt = tmpMeta[0];
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
return _stmt;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromStatement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fstmt, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _stmt = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_stmt = omc_SCodeUtil_stripCommentsFromStatement(threadData, __omcQ_24in_5Fstmt, tmp1, tmp2);
return _stmt;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromAlgorithm(threadData_t *threadData, modelica_metatype __omcQ_24in_5Falg, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _alg = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_alg = __omcQ_24in_5Falg;
{
modelica_metatype __omcQ_24tmpVar21;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar20;
int tmp2;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar21 = tmpMeta[2];
tmp1 = &__omcQ_24tmpVar21;
while(1) {
tmp2 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp2--;
}
if (tmp2 == 0) {
__omcQ_24tmpVar20 = omc_SCodeUtil_stripCommentsFromStatement(threadData, _s, _stripAnn, _stripCmt);
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar20,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar21;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_alg), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = tmpMeta[1];
_alg = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _alg;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromAlgorithm(threadData_t *threadData, modelica_metatype __omcQ_24in_5Falg, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _alg = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_alg = omc_SCodeUtil_stripCommentsFromAlgorithm(threadData, __omcQ_24in_5Falg, tmp1, tmp2);
return _alg;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromWhenEqBranch(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fbranch, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _branch = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _body = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_branch = __omcQ_24in_5Fbranch;
tmpMeta[0] = _branch;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_cond = tmpMeta[1];
_body = tmpMeta[2];
{
modelica_metatype __omcQ_24tmpVar23;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar22;
int tmp2;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _body;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar23 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar23;
while(1) {
tmp2 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp2--;
}
if (tmp2 == 0) {
__omcQ_24tmpVar22 = omc_SCodeUtil_stripCommentsFromEEquation(threadData, _e, _stripAnn, _stripCmt);
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar22,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar23;
}
_body = tmpMeta[0];
tmpMeta[0] = mmc_mk_box2(0, _cond, _body);
_branch = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _branch;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromWhenEqBranch(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fbranch, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _branch = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_branch = omc_SCodeUtil_stripCommentsFromWhenEqBranch(threadData, __omcQ_24in_5Fbranch, tmp1, tmp2);
return _branch;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromEEquation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Feq, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _eq = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
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
{
modelica_metatype __omcQ_24tmpVar27;
modelica_metatype* tmp4;
modelica_metatype __omcQ_24tmpVar26;
int tmp7;
modelica_metatype _branch_loopVar = 0;
modelica_metatype _branch;
_branch_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar27 = tmpMeta[2];
tmp4 = &__omcQ_24tmpVar27;
while(1) {
tmp7 = 1;
if (!listEmpty(_branch_loopVar)) {
_branch = MMC_CAR(_branch_loopVar);
_branch_loopVar = MMC_CDR(_branch_loopVar);
tmp7--;
}
if (tmp7 == 0) {
{
modelica_metatype __omcQ_24tmpVar25;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar24;
int tmp6;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _branch;
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar25 = tmpMeta[4];
tmp5 = &__omcQ_24tmpVar25;
while(1) {
tmp6 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp6--;
}
if (tmp6 == 0) {
__omcQ_24tmpVar24 = omc_SCodeUtil_stripCommentsFromEEquation(threadData, _e, _stripAnn, _stripCmt);
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar24,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[3] = __omcQ_24tmpVar25;
}
__omcQ_24tmpVar26 = tmpMeta[3];
*tmp4 = mmc_mk_cons(__omcQ_24tmpVar26,0);
tmp4 = &MMC_CDR(*tmp4);
} else if (tmp7 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp4 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar27;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = tmpMeta[1];
_eq = tmpMeta[0];
{
modelica_metatype __omcQ_24tmpVar29;
modelica_metatype* tmp8;
modelica_metatype __omcQ_24tmpVar28;
int tmp9;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 4)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar29 = tmpMeta[2];
tmp8 = &__omcQ_24tmpVar29;
while(1) {
tmp9 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar28 = omc_SCodeUtil_stripCommentsFromEEquation(threadData, _e, _stripAnn, _stripCmt);
*tmp8 = mmc_mk_cons(__omcQ_24tmpVar28,0);
tmp8 = &MMC_CDR(*tmp8);
} else if (tmp9 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp8 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar29;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = tmpMeta[1];
_eq = tmpMeta[0];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 5))), _stripAnn, _stripCmt);
_eq = tmpMeta[0];
goto tmp2_done;
}
case 4: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 4))), _stripAnn, _stripCmt);
_eq = tmpMeta[0];
goto tmp2_done;
}
case 5: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 5))), _stripAnn, _stripCmt);
_eq = tmpMeta[0];
goto tmp2_done;
}
case 6: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 4))), _stripAnn, _stripCmt);
_eq = tmpMeta[0];
goto tmp2_done;
}
case 7: {
{
modelica_metatype __omcQ_24tmpVar31;
modelica_metatype* tmp10;
modelica_metatype __omcQ_24tmpVar30;
int tmp11;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 4)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar31 = tmpMeta[2];
tmp10 = &__omcQ_24tmpVar31;
while(1) {
tmp11 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp11--;
}
if (tmp11 == 0) {
__omcQ_24tmpVar30 = omc_SCodeUtil_stripCommentsFromEEquation(threadData, _e, _stripAnn, _stripCmt);
*tmp10 = mmc_mk_cons(__omcQ_24tmpVar30,0);
tmp10 = &MMC_CDR(*tmp10);
} else if (tmp11 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp10 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar31;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = tmpMeta[1];
_eq = tmpMeta[0];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 5))), _stripAnn, _stripCmt);
_eq = tmpMeta[0];
goto tmp2_done;
}
case 8: {
{
modelica_metatype __omcQ_24tmpVar33;
modelica_metatype* tmp12;
modelica_metatype __omcQ_24tmpVar32;
int tmp13;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar33 = tmpMeta[2];
tmp12 = &__omcQ_24tmpVar33;
while(1) {
tmp13 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp13--;
}
if (tmp13 == 0) {
__omcQ_24tmpVar32 = omc_SCodeUtil_stripCommentsFromEEquation(threadData, _e, _stripAnn, _stripCmt);
*tmp12 = mmc_mk_cons(__omcQ_24tmpVar32,0);
tmp12 = &MMC_CDR(*tmp12);
} else if (tmp13 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp12 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar33;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = tmpMeta[1];
_eq = tmpMeta[0];
{
modelica_metatype __omcQ_24tmpVar35;
modelica_metatype* tmp14;
modelica_metatype __omcQ_24tmpVar34;
int tmp15;
modelica_metatype _b_loopVar = 0;
modelica_metatype _b;
_b_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 4)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar35 = tmpMeta[2];
tmp14 = &__omcQ_24tmpVar35;
while(1) {
tmp15 = 1;
if (!listEmpty(_b_loopVar)) {
_b = MMC_CAR(_b_loopVar);
_b_loopVar = MMC_CDR(_b_loopVar);
tmp15--;
}
if (tmp15 == 0) {
__omcQ_24tmpVar34 = omc_SCodeUtil_stripCommentsFromWhenEqBranch(threadData, _b, _stripAnn, _stripCmt);
*tmp14 = mmc_mk_cons(__omcQ_24tmpVar34,0);
tmp14 = &MMC_CDR(*tmp14);
} else if (tmp15 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp14 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar35;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = tmpMeta[1];
_eq = tmpMeta[0];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 5))), _stripAnn, _stripCmt);
_eq = tmpMeta[0];
goto tmp2_done;
}
case 9: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 5))), _stripAnn, _stripCmt);
_eq = tmpMeta[0];
goto tmp2_done;
}
case 10: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3))), _stripAnn, _stripCmt);
_eq = tmpMeta[0];
goto tmp2_done;
}
case 11: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 4))), _stripAnn, _stripCmt);
_eq = tmpMeta[0];
goto tmp2_done;
}
case 12: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3))), _stripAnn, _stripCmt);
_eq = tmpMeta[0];
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
modelica_metatype boxptr_SCodeUtil_stripCommentsFromEEquation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Feq, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _eq = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_eq = omc_SCodeUtil_stripCommentsFromEEquation(threadData, __omcQ_24in_5Feq, tmp1, tmp2);
return _eq;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromEquation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Feq, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _eq = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_eq = __omcQ_24in_5Feq;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_eq), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = omc_SCodeUtil_stripCommentsFromEEquation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 2))), _stripAnn, _stripCmt);
_eq = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _eq;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromEquation(threadData_t *threadData, modelica_metatype __omcQ_24in_5Feq, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _eq = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_eq = omc_SCodeUtil_stripCommentsFromEquation(threadData, __omcQ_24in_5Feq, tmp1, tmp2);
return _eq;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromExternalDecl(threadData_t *threadData, modelica_metatype __omcQ_24in_5FextDecl, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _extDecl = NULL;
modelica_metatype _ext_decl = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_extDecl = __omcQ_24in_5FextDecl;
if((isSome(_extDecl) && _stripAnn))
{
tmpMeta[0] = _extDecl;
if (optionNone(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
_ext_decl = tmpMeta[1];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_ext_decl), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[6] = mmc_mk_none();
_ext_decl = tmpMeta[0];
_extDecl = mmc_mk_some(_ext_decl);
}
_return: OMC_LABEL_UNUSED
return _extDecl;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromExternalDecl(threadData_t *threadData, modelica_metatype __omcQ_24in_5FextDecl, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _extDecl = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_extDecl = omc_SCodeUtil_stripCommentsFromExternalDecl(threadData, __omcQ_24in_5FextDecl, tmp1, tmp2);
return _extDecl;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromComment(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcmt, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _cmt = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cmt = __omcQ_24in_5Fcmt;
if(_stripAnn)
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_cmt), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = mmc_mk_none();
_cmt = tmpMeta[0];
}
if(_stripCmt)
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_cmt), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = mmc_mk_none();
_cmt = tmpMeta[0];
}
_return: OMC_LABEL_UNUSED
return _cmt;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromComment(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcmt, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _cmt = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_cmt = omc_SCodeUtil_stripCommentsFromComment(threadData, __omcQ_24in_5Fcmt, tmp1, tmp2);
return _cmt;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromEnum(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fenum, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _enum = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_enum = __omcQ_24in_5Fenum;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_enum), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_enum), 3))), _stripAnn, _stripCmt);
_enum = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _enum;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromEnum(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fenum, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _enum = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_enum = omc_SCodeUtil_stripCommentsFromEnum(threadData, __omcQ_24in_5Fenum, tmp1, tmp2);
return _enum;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromClassDef(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcdef, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _cdef = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cdef = __omcQ_24in_5Fcdef;
{
modelica_metatype tmp3_1;
tmp3_1 = _cdef;
{
modelica_metatype _el = NULL;
modelica_metatype _eql = NULL;
modelica_metatype _ieql = NULL;
modelica_metatype _alg = NULL;
modelica_metatype _ialg = NULL;
modelica_metatype _ext = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
{
modelica_metatype __omcQ_24tmpVar37;
modelica_metatype* tmp4;
modelica_metatype __omcQ_24tmpVar36;
int tmp5;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 2)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar37 = tmpMeta[2];
tmp4 = &__omcQ_24tmpVar37;
while(1) {
tmp5 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp5--;
}
if (tmp5 == 0) {
__omcQ_24tmpVar36 = omc_SCodeUtil_stripCommentsFromElement(threadData, _e, _stripAnn, _stripCmt);
*tmp4 = mmc_mk_cons(__omcQ_24tmpVar36,0);
tmp4 = &MMC_CDR(*tmp4);
} else if (tmp5 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp4 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar37;
}
_el = tmpMeta[1];
{
modelica_metatype __omcQ_24tmpVar39;
modelica_metatype* tmp6;
modelica_metatype __omcQ_24tmpVar38;
int tmp7;
modelica_metatype _eq_loopVar = 0;
modelica_metatype _eq;
_eq_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 3)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar39 = tmpMeta[2];
tmp6 = &__omcQ_24tmpVar39;
while(1) {
tmp7 = 1;
if (!listEmpty(_eq_loopVar)) {
_eq = MMC_CAR(_eq_loopVar);
_eq_loopVar = MMC_CDR(_eq_loopVar);
tmp7--;
}
if (tmp7 == 0) {
__omcQ_24tmpVar38 = omc_SCodeUtil_stripCommentsFromEquation(threadData, _eq, _stripAnn, _stripCmt);
*tmp6 = mmc_mk_cons(__omcQ_24tmpVar38,0);
tmp6 = &MMC_CDR(*tmp6);
} else if (tmp7 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp6 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar39;
}
_eql = tmpMeta[1];
{
modelica_metatype __omcQ_24tmpVar41;
modelica_metatype* tmp8;
modelica_metatype __omcQ_24tmpVar40;
int tmp9;
modelica_metatype _ieq_loopVar = 0;
modelica_metatype _ieq;
_ieq_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar41 = tmpMeta[2];
tmp8 = &__omcQ_24tmpVar41;
while(1) {
tmp9 = 1;
if (!listEmpty(_ieq_loopVar)) {
_ieq = MMC_CAR(_ieq_loopVar);
_ieq_loopVar = MMC_CDR(_ieq_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar40 = omc_SCodeUtil_stripCommentsFromEquation(threadData, _ieq, _stripAnn, _stripCmt);
*tmp8 = mmc_mk_cons(__omcQ_24tmpVar40,0);
tmp8 = &MMC_CDR(*tmp8);
} else if (tmp9 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp8 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar41;
}
_ieql = tmpMeta[1];
{
modelica_metatype __omcQ_24tmpVar43;
modelica_metatype* tmp10;
modelica_metatype __omcQ_24tmpVar42;
int tmp11;
modelica_metatype _a_loopVar = 0;
modelica_metatype _a;
_a_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar43 = tmpMeta[2];
tmp10 = &__omcQ_24tmpVar43;
while(1) {
tmp11 = 1;
if (!listEmpty(_a_loopVar)) {
_a = MMC_CAR(_a_loopVar);
_a_loopVar = MMC_CDR(_a_loopVar);
tmp11--;
}
if (tmp11 == 0) {
__omcQ_24tmpVar42 = omc_SCodeUtil_stripCommentsFromAlgorithm(threadData, _a, _stripAnn, _stripCmt);
*tmp10 = mmc_mk_cons(__omcQ_24tmpVar42,0);
tmp10 = &MMC_CDR(*tmp10);
} else if (tmp11 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp10 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar43;
}
_alg = tmpMeta[1];
{
modelica_metatype __omcQ_24tmpVar45;
modelica_metatype* tmp12;
modelica_metatype __omcQ_24tmpVar44;
int tmp13;
modelica_metatype _ia_loopVar = 0;
modelica_metatype _ia;
_ia_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 6)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar45 = tmpMeta[2];
tmp12 = &__omcQ_24tmpVar45;
while(1) {
tmp13 = 1;
if (!listEmpty(_ia_loopVar)) {
_ia = MMC_CAR(_ia_loopVar);
_ia_loopVar = MMC_CDR(_ia_loopVar);
tmp13--;
}
if (tmp13 == 0) {
__omcQ_24tmpVar44 = omc_SCodeUtil_stripCommentsFromAlgorithm(threadData, _ia, _stripAnn, _stripCmt);
*tmp12 = mmc_mk_cons(__omcQ_24tmpVar44,0);
tmp12 = &MMC_CDR(*tmp12);
} else if (tmp13 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp12 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar45;
}
_ialg = tmpMeta[1];
_ext = omc_SCodeUtil_stripCommentsFromExternalDecl(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 9))), _stripAnn, _stripCmt);
tmpMeta[1] = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, _el, _eql, _ieql, _alg, _ialg, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 7))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 8))), _ext);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_cdef), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[2] = omc_SCodeUtil_stripCommentsFromMod(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 2))), _stripAnn, _stripCmt);
_cdef = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_cdef), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[3] = omc_SCodeUtil_stripCommentsFromClassDef(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 3))), _stripAnn, _stripCmt);
_cdef = tmpMeta[1];
tmpMeta[0] = _cdef;
goto tmp2_done;
}
case 5: {
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_cdef), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[3] = omc_SCodeUtil_stripCommentsFromMod(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 3))), _stripAnn, _stripCmt);
_cdef = tmpMeta[1];
tmpMeta[0] = _cdef;
goto tmp2_done;
}
case 6: {
{
modelica_metatype __omcQ_24tmpVar47;
modelica_metatype* tmp14;
modelica_metatype __omcQ_24tmpVar46;
int tmp15;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 2)));
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar47 = tmpMeta[3];
tmp14 = &__omcQ_24tmpVar47;
while(1) {
tmp15 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp15--;
}
if (tmp15 == 0) {
__omcQ_24tmpVar46 = omc_SCodeUtil_stripCommentsFromEnum(threadData, _e, _stripAnn, _stripCmt);
*tmp14 = mmc_mk_cons(__omcQ_24tmpVar46,0);
tmp14 = &MMC_CDR(*tmp14);
} else if (tmp15 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp14 = mmc_mk_nil();
tmpMeta[2] = __omcQ_24tmpVar47;
}
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_cdef), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[2] = tmpMeta[2];
_cdef = tmpMeta[1];
tmpMeta[0] = _cdef;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _cdef;
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
_cdef = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _cdef;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromClassDef(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fcdef, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _cdef = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_cdef = omc_SCodeUtil_stripCommentsFromClassDef(threadData, __omcQ_24in_5Fcdef, tmp1, tmp2);
return _cdef;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromSubMod(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsubmod, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _submod = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_submod = __omcQ_24in_5Fsubmod;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_submod), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = omc_SCodeUtil_stripCommentsFromMod(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_submod), 3))), _stripAnn, _stripCmt);
_submod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _submod;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromSubMod(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsubmod, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _submod = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_submod = omc_SCodeUtil_stripCommentsFromSubMod(threadData, __omcQ_24in_5Fsubmod, tmp1, tmp2);
return _submod;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromMod(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fmod, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _mod = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_mod = __omcQ_24in_5Fmod;
{
modelica_metatype tmp3_1;
tmp3_1 = _mod;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
{
modelica_metatype __omcQ_24tmpVar49;
modelica_metatype* tmp4;
modelica_metatype __omcQ_24tmpVar48;
int tmp5;
modelica_metatype _m_loopVar = 0;
modelica_metatype _m;
_m_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 4)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar49 = tmpMeta[2];
tmp4 = &__omcQ_24tmpVar49;
while(1) {
tmp5 = 1;
if (!listEmpty(_m_loopVar)) {
_m = MMC_CAR(_m_loopVar);
_m_loopVar = MMC_CDR(_m_loopVar);
tmp5--;
}
if (tmp5 == 0) {
__omcQ_24tmpVar48 = omc_SCodeUtil_stripCommentsFromSubMod(threadData, _m, _stripAnn, _stripCmt);
*tmp4 = mmc_mk_cons(__omcQ_24tmpVar48,0);
tmp4 = &MMC_CDR(*tmp4);
} else if (tmp5 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp4 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar49;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_mod), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = tmpMeta[1];
_mod = tmpMeta[0];
goto tmp2_done;
}
case 4: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_mod), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_SCodeUtil_stripCommentsFromElement(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 4))), _stripAnn, _stripCmt);
_mod = tmpMeta[0];
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
return _mod;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromMod(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fmod, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _mod = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_mod = omc_SCodeUtil_stripCommentsFromMod(threadData, __omcQ_24in_5Fmod, tmp1, tmp2);
return _mod;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_boolean _stripAnn, modelica_boolean _stripCmt)
{
modelica_metatype _element = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = __omcQ_24in_5Felement;
{
modelica_metatype tmp3_1;
tmp3_1 = _element;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 4: {
if(_stripAnn)
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = mmc_mk_none();
_element = tmpMeta[0];
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_SCodeUtil_stripCommentsFromMod(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4))), _stripAnn, _stripCmt);
_element = tmpMeta[0];
goto tmp2_done;
}
case 5: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(10));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 10*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[7] = omc_SCodeUtil_stripCommentsFromClassDef(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 7))), _stripAnn, _stripCmt);
_element = tmpMeta[0];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(10));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 10*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[8] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 8))), _stripAnn, _stripCmt);
_element = tmpMeta[0];
goto tmp2_done;
}
case 6: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(10));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 10*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[6] = omc_SCodeUtil_stripCommentsFromMod(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 6))), _stripAnn, _stripCmt);
_element = tmpMeta[0];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(10));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 10*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[7] = omc_SCodeUtil_stripCommentsFromComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 7))), _stripAnn, _stripCmt);
_element = tmpMeta[0];
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
return _element;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _stripAnn, modelica_metatype _stripCmt)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _element = NULL;
tmp1 = mmc_unbox_integer(_stripAnn);
tmp2 = mmc_unbox_integer(_stripCmt);
_element = omc_SCodeUtil_stripCommentsFromElement(threadData, __omcQ_24in_5Felement, tmp1, tmp2);
return _element;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripCommentsFromProgram(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fprogram, modelica_boolean _stripAnnotations, modelica_boolean _stripComments)
{
modelica_metatype _program = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_program = __omcQ_24in_5Fprogram;
{
modelica_metatype __omcQ_24tmpVar51;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar50;
int tmp2;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _program;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar51 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar51;
while(1) {
tmp2 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp2--;
}
if (tmp2 == 0) {
__omcQ_24tmpVar50 = omc_SCodeUtil_stripCommentsFromElement(threadData, _e, _stripAnnotations, _stripComments);
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar50,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar51;
}
_program = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _program;
}
modelica_metatype boxptr_SCodeUtil_stripCommentsFromProgram(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fprogram, modelica_metatype _stripAnnotations, modelica_metatype _stripComments)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _program = NULL;
tmp1 = mmc_unbox_integer(_stripAnnotations);
tmp2 = mmc_unbox_integer(_stripComments);
_program = omc_SCodeUtil_stripCommentsFromProgram(threadData, __omcQ_24in_5Fprogram, tmp1, tmp2);
return _program;
}
DLLExport
modelica_boolean omc_SCodeUtil_isEmptyClassDef(threadData_t *threadData, modelica_metatype _cdef)
{
modelica_boolean _isEmpty;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cdef;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = (((((listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 2)))) && listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 3))))) && listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 4))))) && listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 5))))) && listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 6))))) && isNone((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 9)))));
goto tmp3_done;
}
case 4: {
_cdef = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 3)));
goto _tailrecursive;
goto tmp3_done;
}
case 6: {
tmp1 = listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cdef), 2))));
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
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
_isEmpty = tmp1;
_return: OMC_LABEL_UNUSED
return _isEmpty;
}
modelica_metatype boxptr_SCodeUtil_isEmptyClassDef(threadData_t *threadData, modelica_metatype _cdef)
{
modelica_boolean _isEmpty;
modelica_metatype out_isEmpty;
_isEmpty = omc_SCodeUtil_isEmptyClassDef(threadData, _cdef);
out_isEmpty = mmc_mk_icon(_isEmpty);
return out_isEmpty;
}
DLLExport
modelica_metatype omc_SCodeUtil_getConstrainingMod(threadData_t *threadData, modelica_metatype _element)
{
modelica_metatype _mod = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _element;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (optionNone(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
_mod = tmpMeta[5];
tmpMeta[0] = _mod;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_mod = tmpMeta[2];
tmpMeta[0] = _mod;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (optionNone(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
_mod = tmpMeta[5];
tmpMeta[0] = _mod;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_mod = tmpMeta[1];
tmpMeta[0] = _mod;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT15;
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
_mod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _mod;
}
DLLExport
modelica_boolean omc_SCodeUtil_isEmptyMod(threadData_t *threadData, modelica_metatype _mod)
{
modelica_boolean _isEmpty;
modelica_boolean tmp1 = 0;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
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
_isEmpty = tmp1;
_return: OMC_LABEL_UNUSED
return _isEmpty;
}
modelica_metatype boxptr_SCodeUtil_isEmptyMod(threadData_t *threadData, modelica_metatype _mod)
{
modelica_boolean _isEmpty;
modelica_metatype out_isEmpty;
_isEmpty = omc_SCodeUtil_isEmptyMod(threadData, _mod);
out_isEmpty = mmc_mk_icon(_isEmpty);
return out_isEmpty;
}
DLLExport
modelica_boolean omc_SCodeUtil_isArrayComponent(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsArray;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (listEmpty(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
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
_outIsArray = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsArray;
}
modelica_metatype boxptr_SCodeUtil_isArrayComponent(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsArray;
modelica_metatype out_outIsArray;
_outIsArray = omc_SCodeUtil_isArrayComponent(threadData, _inElement);
out_outIsArray = mmc_mk_icon(_outIsArray);
return out_outIsArray;
}
DLLExport
modelica_metatype omc_SCodeUtil_setComponentName(threadData_t *threadData, modelica_metatype _inE, modelica_string _inName)
{
modelica_metatype _outE = NULL;
modelica_string _n = NULL;
modelica_metatype _pr = NULL;
modelica_metatype _atr = NULL;
modelica_metatype _ts = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _cnd = NULL;
modelica_metatype _bc = NULL;
modelica_metatype _v = NULL;
modelica_metatype _m = NULL;
modelica_metatype _a = NULL;
modelica_metatype _i = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inE;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
_n = tmpMeta[1];
_pr = tmpMeta[2];
_atr = tmpMeta[3];
_ts = tmpMeta[4];
_m = tmpMeta[5];
_cmt = tmpMeta[6];
_cnd = tmpMeta[7];
_i = tmpMeta[8];
tmpMeta[0] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _inName, _pr, _atr, _ts, _m, _cmt, _cnd, _i);
_outE = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outE;
}
DLLExport
modelica_metatype omc_SCodeUtil_checkSameRestriction(threadData_t *threadData, modelica_metatype _inResNew, modelica_metatype _inResOrig, modelica_metatype _inInfoNew, modelica_metatype _inInfoOrig, modelica_metatype *out_outInfo)
{
modelica_metatype _outRes = NULL;
modelica_metatype _outInfo = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0+0] = _inResNew;
tmpMeta[0+1] = _inInfoNew;
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
_outRes = tmpMeta[0+0];
_outInfo = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outInfo) { *out_outInfo = _outInfo; }
return _outRes;
}
DLLExport
modelica_boolean omc_SCodeUtil_isInitial(threadData_t *threadData, modelica_metatype _inInitial)
{
modelica_boolean _isIn;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inInitial;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
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
_isIn = tmp1;
_return: OMC_LABEL_UNUSED
return _isIn;
}
modelica_metatype boxptr_SCodeUtil_isInitial(threadData_t *threadData, modelica_metatype _inInitial)
{
modelica_boolean _isIn;
modelica_metatype out_isIn;
_isIn = omc_SCodeUtil_isInitial(threadData, _inInitial);
out_isIn = mmc_mk_icon(_isIn);
return out_isIn;
}
DLLExport
modelica_boolean omc_SCodeUtil_isInstantiableClassRestriction(threadData_t *threadData, modelica_metatype _inRestriction)
{
modelica_boolean _outIsInstantiable;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRestriction;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = 1;
goto tmp3_done;
}
case 5: {
tmp1 = 1;
goto tmp3_done;
}
case 6: {
tmp1 = 1;
goto tmp3_done;
}
case 7: {
tmp1 = 1;
goto tmp3_done;
}
case 8: {
tmp1 = 1;
goto tmp3_done;
}
case 10: {
tmp1 = 1;
goto tmp3_done;
}
case 13: {
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
_outIsInstantiable = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsInstantiable;
}
modelica_metatype boxptr_SCodeUtil_isInstantiableClassRestriction(threadData_t *threadData, modelica_metatype _inRestriction)
{
modelica_boolean _outIsInstantiable;
modelica_metatype out_outIsInstantiable;
_outIsInstantiable = omc_SCodeUtil_isInstantiableClassRestriction(threadData, _inRestriction);
out_outIsInstantiable = mmc_mk_icon(_outIsInstantiable);
return out_outIsInstantiable;
}
DLLExport
modelica_metatype omc_SCodeUtil_getExternalObjectConstructor(threadData_t *threadData, modelica_metatype _inEls)
{
modelica_metatype _cl = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inEls;
{
modelica_metatype _els = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (11 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT16), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
_cl = tmpMeta[1];
tmpMeta[0] = _cl;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_els = tmpMeta[2];
_inEls = _els;
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
_cl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _cl;
}
DLLExport
modelica_metatype omc_SCodeUtil_getExternalObjectDestructor(threadData_t *threadData, modelica_metatype _inEls)
{
modelica_metatype _cl = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inEls;
{
modelica_metatype _els = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (10 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT17), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
_cl = tmpMeta[1];
tmpMeta[0] = _cl;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_els = tmpMeta[2];
_inEls = _els;
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
_cl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _cl;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_hasExternalObjectConstructor(threadData_t *threadData, modelica_metatype _inEls)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inEls;
{
modelica_metatype _els = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,8) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (11 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT16), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
_els = tmpMeta[1];
_inEls = _els;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_hasExternalObjectConstructor(threadData_t *threadData, modelica_metatype _inEls)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_SCodeUtil_hasExternalObjectConstructor(threadData, _inEls);
out_res = mmc_mk_icon(_res);
return out_res;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_hasExternalObjectDestructor(threadData_t *threadData, modelica_metatype _inEls)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inEls;
{
modelica_metatype _els = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,8) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (10 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT17), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
_els = tmpMeta[1];
_inEls = _els;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_hasExternalObjectDestructor(threadData_t *threadData, modelica_metatype _inEls)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_SCodeUtil_hasExternalObjectDestructor(threadData, _inEls);
out_res = mmc_mk_icon(_res);
return out_res;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_hasExtendsOfExternalObject(threadData_t *threadData, modelica_metatype _inEls)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inEls;
{
modelica_metatype _els = NULL;
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_path = tmpMeta[2];
if (!omc_AbsynUtil_pathEqual(threadData, _path, _OMC_LIT19)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
_els = tmpMeta[1];
_inEls = _els;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_hasExtendsOfExternalObject(threadData_t *threadData, modelica_metatype _inEls)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_SCodeUtil_hasExtendsOfExternalObject(threadData, _inEls);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_SCodeUtil_isExternalObject(threadData_t *threadData, modelica_metatype _els)
{
modelica_boolean _res;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_res = ((listLength(_els) == ((modelica_integer) 3))?((omc_SCodeUtil_hasExtendsOfExternalObject(threadData, _els) && omc_SCodeUtil_hasExternalObjectDestructor(threadData, _els)) && omc_SCodeUtil_hasExternalObjectConstructor(threadData, _els)):0);
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_SCodeUtil_isExternalObject(threadData_t *threadData, modelica_metatype _els)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_SCodeUtil_isExternalObject(threadData, _els);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_SCodeUtil_classIsExternalObject(threadData_t *threadData, modelica_metatype _cl)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cl;
{
modelica_metatype _els = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,8) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_els = tmpMeta[1];
tmp1 = omc_SCodeUtil_isExternalObject(threadData, _els);
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
modelica_metatype boxptr_SCodeUtil_classIsExternalObject(threadData_t *threadData, modelica_metatype _cl)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_SCodeUtil_classIsExternalObject(threadData, _cl);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_SCodeUtil_isValidPackageElement(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsValid;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
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
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outIsValid = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsValid;
}
modelica_metatype boxptr_SCodeUtil_isValidPackageElement(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsValid;
modelica_metatype out_outIsValid;
_outIsValid = omc_SCodeUtil_isValidPackageElement(threadData, _inElement);
out_outIsValid = mmc_mk_icon(_outIsValid);
return out_outIsValid;
}
DLLExport
modelica_boolean omc_SCodeUtil_isPartial(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_isPartial(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_SCodeUtil_isPartial(threadData, _inClass);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_SCodeUtil_isPackage(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],8,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_isPackage(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_SCodeUtil_isPackage(threadData, _inClass);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_metatype omc_SCodeUtil_propagatePrefixInnerOuter(threadData_t *threadData, modelica_metatype _inOriginalIO, modelica_metatype _inIO)
{
modelica_metatype _outIO = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inIO;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,0) == 0) goto tmp2_end;
tmpMeta[0] = _inOriginalIO;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inIO;
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
_outIO = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outIO;
}
DLLExport
modelica_metatype omc_SCodeUtil_propagatePrefixes(threadData_t *threadData, modelica_metatype _inOriginalPrefixes, modelica_metatype _inNewPrefixes)
{
modelica_metatype _outNewPrefixes = NULL;
modelica_metatype _vis1 = NULL;
modelica_metatype _vis2 = NULL;
modelica_metatype _io1 = NULL;
modelica_metatype _io2 = NULL;
modelica_metatype _rdp = NULL;
modelica_metatype _fp = NULL;
modelica_metatype _rpp = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inOriginalPrefixes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_vis1 = tmpMeta[1];
_io1 = tmpMeta[2];
tmpMeta[0] = _inNewPrefixes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
_vis2 = tmpMeta[1];
_rdp = tmpMeta[2];
_fp = tmpMeta[3];
_io2 = tmpMeta[4];
_rpp = tmpMeta[5];
_io2 = omc_SCodeUtil_propagatePrefixInnerOuter(threadData, _io1, _io2);
tmpMeta[0] = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _vis2, _rdp, _fp, _io2, _rpp);
_outNewPrefixes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNewPrefixes;
}
DLLExport
modelica_metatype omc_SCodeUtil_propagateAttributesClass(threadData_t *threadData, modelica_metatype _inOriginalClass, modelica_metatype _inNewClass)
{
modelica_metatype _outNewClass = NULL;
modelica_string _name = NULL;
modelica_metatype _pref1 = NULL;
modelica_metatype _pref2 = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _pp = NULL;
modelica_metatype _res = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _info = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inOriginalClass;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_pref1 = tmpMeta[1];
tmpMeta[0] = _inNewClass;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
_name = tmpMeta[1];
_pref2 = tmpMeta[2];
_ep = tmpMeta[3];
_pp = tmpMeta[4];
_res = tmpMeta[5];
_cdef = tmpMeta[6];
_cmt = tmpMeta[7];
_info = tmpMeta[8];
_pref2 = omc_SCodeUtil_propagatePrefixes(threadData, _pref1, _pref2);
tmpMeta[0] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name, _pref2, _ep, _pp, _res, _cdef, _cmt, _info);
_outNewClass = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNewClass;
}
DLLExport
modelica_metatype omc_SCodeUtil_propagateAttributesVar(threadData_t *threadData, modelica_metatype _inOriginalVar, modelica_metatype _inNewVar, modelica_boolean _inNewTypeIsArray)
{
modelica_metatype _outNewVar = NULL;
modelica_string _name = NULL;
modelica_metatype _pref1 = NULL;
modelica_metatype _pref2 = NULL;
modelica_metatype _attr1 = NULL;
modelica_metatype _attr2 = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _info = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inOriginalVar;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_pref1 = tmpMeta[1];
_attr1 = tmpMeta[2];
tmpMeta[0] = _inNewVar;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
_name = tmpMeta[1];
_pref2 = tmpMeta[2];
_attr2 = tmpMeta[3];
_ty = tmpMeta[4];
_mod = tmpMeta[5];
_cmt = tmpMeta[6];
_cond = tmpMeta[7];
_info = tmpMeta[8];
_pref2 = omc_SCodeUtil_propagatePrefixes(threadData, _pref1, _pref2);
_attr2 = omc_SCodeUtil_propagateAttributes(threadData, _attr1, _attr2, _inNewTypeIsArray);
tmpMeta[0] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _name, _pref2, _attr2, _ty, _mod, _cmt, _cond, _info);
_outNewVar = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNewVar;
}
modelica_metatype boxptr_SCodeUtil_propagateAttributesVar(threadData_t *threadData, modelica_metatype _inOriginalVar, modelica_metatype _inNewVar, modelica_metatype _inNewTypeIsArray)
{
modelica_integer tmp1;
modelica_metatype _outNewVar = NULL;
tmp1 = mmc_unbox_integer(_inNewTypeIsArray);
_outNewVar = omc_SCodeUtil_propagateAttributesVar(threadData, _inOriginalVar, _inNewVar, tmp1);
return _outNewVar;
}
DLLExport
modelica_metatype omc_SCodeUtil_propagateIsField(threadData_t *threadData, modelica_metatype _inOriginalIsField, modelica_metatype _inNewIsField)
{
modelica_metatype _outNewIsField = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inNewIsField;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,0) == 0) goto tmp2_end;
tmpMeta[0] = _inOriginalIsField;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inNewIsField;
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
_outNewIsField = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNewIsField;
}
DLLExport
modelica_metatype omc_SCodeUtil_propagateDirection(threadData_t *threadData, modelica_metatype _inOriginalDirection, modelica_metatype _inNewDirection)
{
modelica_metatype _outNewDirection = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inNewDirection;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _inOriginalDirection;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inNewDirection;
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
_outNewDirection = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNewDirection;
}
DLLExport
modelica_metatype omc_SCodeUtil_propagateVariability(threadData_t *threadData, modelica_metatype _inOriginalVariability, modelica_metatype _inNewVariability)
{
modelica_metatype _outNewVariability = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inNewVariability;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,0) == 0) goto tmp2_end;
tmpMeta[0] = _inOriginalVariability;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inNewVariability;
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
_outNewVariability = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNewVariability;
}
DLLExport
modelica_metatype omc_SCodeUtil_propagateParallelism(threadData_t *threadData, modelica_metatype _inOriginalParallelism, modelica_metatype _inNewParallelism)
{
modelica_metatype _outNewParallelism = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inNewParallelism;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _inOriginalParallelism;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inNewParallelism;
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
_outNewParallelism = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNewParallelism;
}
DLLExport
modelica_metatype omc_SCodeUtil_propagateConnectorType(threadData_t *threadData, modelica_metatype _inOriginalConnectorType, modelica_metatype _inNewConnectorType)
{
modelica_metatype _outNewConnectorType = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inNewConnectorType;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,0) == 0) goto tmp2_end;
tmpMeta[0] = _inOriginalConnectorType;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inNewConnectorType;
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
_outNewConnectorType = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNewConnectorType;
}
DLLExport
modelica_metatype omc_SCodeUtil_propagateArrayDimensions(threadData_t *threadData, modelica_metatype _inOriginalDims, modelica_metatype _inNewDims)
{
modelica_metatype _outNewDims = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inNewDims;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _inOriginalDims;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inNewDims;
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
_outNewDims = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNewDims;
}
DLLExport
modelica_metatype omc_SCodeUtil_propagateAttributes(threadData_t *threadData, modelica_metatype _inOriginalAttributes, modelica_metatype _inNewAttributes, modelica_boolean _inNewTypeIsArray)
{
modelica_metatype _outNewAttributes = NULL;
modelica_metatype _dims1 = NULL;
modelica_metatype _dims2 = NULL;
modelica_metatype _ct1 = NULL;
modelica_metatype _ct2 = NULL;
modelica_metatype _prl1 = NULL;
modelica_metatype _prl2 = NULL;
modelica_metatype _var1 = NULL;
modelica_metatype _var2 = NULL;
modelica_metatype _dir1 = NULL;
modelica_metatype _dir2 = NULL;
modelica_metatype _if1 = NULL;
modelica_metatype _if2 = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inOriginalAttributes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
_dims1 = tmpMeta[1];
_ct1 = tmpMeta[2];
_prl1 = tmpMeta[3];
_var1 = tmpMeta[4];
_dir1 = tmpMeta[5];
_if1 = tmpMeta[6];
tmpMeta[0] = _inNewAttributes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
_dims2 = tmpMeta[1];
_ct2 = tmpMeta[2];
_prl2 = tmpMeta[3];
_var2 = tmpMeta[4];
_dir2 = tmpMeta[5];
_if2 = tmpMeta[6];
if((!_inNewTypeIsArray))
{
_dims2 = omc_SCodeUtil_propagateArrayDimensions(threadData, _dims1, _dims2);
}
_ct2 = omc_SCodeUtil_propagateConnectorType(threadData, _ct1, _ct2);
_prl2 = omc_SCodeUtil_propagateParallelism(threadData, _prl1, _prl2);
_var2 = omc_SCodeUtil_propagateVariability(threadData, _var1, _var2);
_dir2 = omc_SCodeUtil_propagateDirection(threadData, _dir1, _dir2);
_if2 = omc_SCodeUtil_propagateIsField(threadData, _if1, _if2);
tmpMeta[0] = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _dims2, _ct2, _prl2, _var2, _dir2, _if2);
_outNewAttributes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNewAttributes;
}
modelica_metatype boxptr_SCodeUtil_propagateAttributes(threadData_t *threadData, modelica_metatype _inOriginalAttributes, modelica_metatype _inNewAttributes, modelica_metatype _inNewTypeIsArray)
{
modelica_integer tmp1;
modelica_metatype _outNewAttributes = NULL;
tmp1 = mmc_unbox_integer(_inNewTypeIsArray);
_outNewAttributes = omc_SCodeUtil_propagateAttributes(threadData, _inOriginalAttributes, _inNewAttributes, tmp1);
return _outNewAttributes;
}
DLLExport
modelica_metatype omc_SCodeUtil_mergeComponentModifiers(threadData_t *threadData, modelica_metatype _inNewComp, modelica_metatype _inOldComp)
{
modelica_metatype _outComp = NULL;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inNewComp;
tmp3_2 = _inOldComp;
{
modelica_string _n1 = NULL;
modelica_metatype _p1 = NULL;
modelica_metatype _a1 = NULL;
modelica_metatype _t1 = NULL;
modelica_metatype _m1 = NULL;
modelica_metatype _m2 = NULL;
modelica_metatype _m = NULL;
modelica_metatype _c1 = NULL;
modelica_metatype _cnd1 = NULL;
modelica_metatype _i1 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,3,8) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 6));
_n1 = tmpMeta[1];
_p1 = tmpMeta[2];
_a1 = tmpMeta[3];
_t1 = tmpMeta[4];
_m1 = tmpMeta[5];
_c1 = tmpMeta[6];
_cnd1 = tmpMeta[7];
_i1 = tmpMeta[8];
_m2 = tmpMeta[9];
_m = omc_SCodeUtil_mergeModifiers(threadData, _m1, _m2);
tmpMeta[1] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _n1, _p1, _a1, _t1, _m, _c1, _cnd1, _i1);
tmpMeta[0] = tmpMeta[1];
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
_outComp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outComp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_removeSub(threadData_t *threadData, modelica_metatype _inSub, modelica_metatype _inOld)
{
modelica_metatype _outSubs = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inSub;
tmp3_2 = _inOld;
{
modelica_metatype _rest = NULL;
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
modelica_metatype _s = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
tmp3 += 2;
tmpMeta[0] = _inOld;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_id2 = tmpMeta[3];
_rest = tmpMeta[2];
_id1 = tmpMeta[4];
tmp5 = (stringEqual(_id1, _id2));
if (1 != tmp5) goto goto_1;
tmpMeta[0] = _rest;
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
_s = tmpMeta[1];
_rest = tmpMeta[2];
_rest = omc_SCodeUtil_removeSub(threadData, _inSub, _rest);
tmpMeta[1] = mmc_mk_cons(_s, _rest);
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
if (++tmp3 < 3) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outSubs = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outSubs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_mergeSubMods(threadData_t *threadData, modelica_metatype _inNew, modelica_metatype _inOld)
{
modelica_metatype _outSubs = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inNew;
{
modelica_metatype _sl = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _old = NULL;
modelica_metatype _s = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmp3 += 1;
tmpMeta[0] = _inOld;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_s = tmpMeta[1];
_rest = tmpMeta[2];
_old = omc_SCodeUtil_removeSub(threadData, _s, _inOld);
_sl = omc_SCodeUtil_mergeSubMods(threadData, _rest, _old);
tmpMeta[1] = mmc_mk_cons(_s, _sl);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
tmpMeta[0] = _inNew;
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
if (++tmp3 < 3) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outSubs = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outSubs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_mergeBindings(threadData_t *threadData, modelica_metatype _inNew, modelica_metatype _inOld)
{
modelica_metatype _outBnd = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inNew;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[0] = _inNew;
goto tmp2_done;
}
case 1: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _inOld;
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
_outBnd = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outBnd;
}
DLLExport
modelica_metatype omc_SCodeUtil_mergeModifiers(threadData_t *threadData, modelica_metatype _inNewMod, modelica_metatype _inOldMod)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inNewMod;
tmp3_2 = _inOldMod;
{
modelica_metatype _f1 = NULL;
modelica_metatype _f2 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _sl1 = NULL;
modelica_metatype _sl2 = NULL;
modelica_metatype _sl = NULL;
modelica_metatype _b1 = NULL;
modelica_metatype _b2 = NULL;
modelica_metatype _b = NULL;
modelica_metatype _i1 = NULL;
modelica_metatype _m = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _inNewMod;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,0) == 0) goto tmp2_end;
tmp3 += 2;
tmpMeta[0] = _inOldMod;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmp3 += 1;
tmpMeta[0] = _inNewMod;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,5) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 5));
_f1 = tmpMeta[1];
_e1 = tmpMeta[2];
_sl1 = tmpMeta[3];
_b1 = tmpMeta[4];
_i1 = tmpMeta[5];
_f2 = tmpMeta[6];
_e2 = tmpMeta[7];
_sl2 = tmpMeta[8];
_b2 = tmpMeta[9];
_b = omc_SCodeUtil_mergeBindings(threadData, _b1, _b2);
_sl = omc_SCodeUtil_mergeSubMods(threadData, _sl1, _sl2);
if((referenceEq(_b, _b1) && referenceEq(_sl, _sl1)))
{
_m = _inNewMod;
}
else
{
if((((referenceEq(_b, _b2) && referenceEq(_sl, _sl2)) && valueEq(_f1, _f2)) && valueEq(_e1, _e2)))
{
_m = _inOldMod;
}
else
{
tmpMeta[1] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _f1, _e1, _sl, _b, _i1);
_m = tmpMeta[1];
}
}
tmpMeta[0] = _m;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _inNewMod;
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
if (++tmp3 < 5) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMod;
}
DLLExport
modelica_metatype omc_SCodeUtil_mergeClassDef(threadData_t *threadData, modelica_metatype _inNew, modelica_metatype _inOld, modelica_metatype _inCCModNew, modelica_metatype _inCCModOld)
{
modelica_metatype _outNew = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inNew;
tmp3_2 = _inOld;
{
modelica_metatype _ts1 = NULL;
modelica_metatype _m1 = NULL;
modelica_metatype _m2 = NULL;
modelica_metatype _a1 = NULL;
modelica_metatype _a2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,3) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_ts1 = tmpMeta[1];
_m1 = tmpMeta[2];
_a1 = tmpMeta[3];
_m2 = tmpMeta[4];
_a2 = tmpMeta[5];
_m2 = omc_SCodeUtil_mergeModifiers(threadData, _m2, _inCCModOld);
_m1 = omc_SCodeUtil_mergeModifiers(threadData, _m1, _inCCModNew);
_m2 = omc_SCodeUtil_mergeModifiers(threadData, _m1, _m2);
_a2 = omc_SCodeUtil_propagateAttributes(threadData, _a2, _a1, 0);
tmpMeta[1] = mmc_mk_box4(5, &SCode_ClassDef_DERIVED__desc, _ts1, _m2, _a2);
tmpMeta[0] = tmpMeta[1];
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
_outNew = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNew;
}
DLLExport
modelica_metatype omc_SCodeUtil_getConstrainedByModifiers(threadData_t *threadData, modelica_metatype _inPrefixes)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inPrefixes;
{
modelica_metatype _m = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
_m = tmpMeta[4];
tmpMeta[0] = _m;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _OMC_LIT15;
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
_outMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMod;
}
DLLExport
modelica_metatype omc_SCodeUtil_mergeWithOriginal(threadData_t *threadData, modelica_metatype _inNew, modelica_metatype _inOld)
{
modelica_metatype _outNew = NULL;
modelica_metatype tmpMeta[11] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inNew;
tmp3_2 = _inOld;
{
modelica_string _name1 = NULL;
modelica_metatype _prefixes1 = NULL;
modelica_metatype _prefixes2 = NULL;
modelica_metatype _en1 = NULL;
modelica_metatype _p1 = NULL;
modelica_metatype _restr1 = NULL;
modelica_metatype _cd1 = NULL;
modelica_metatype _cd2 = NULL;
modelica_metatype _cm = NULL;
modelica_metatype _i = NULL;
modelica_metatype _mCCNew = NULL;
modelica_metatype _mCCOld = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
tmp5 = omc_SCodeUtil_isFunction(threadData, _inNew);
if (1 != tmp5) goto goto_1;
tmpMeta[0] = _inNew;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,8) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 7));
_name1 = tmpMeta[1];
_prefixes1 = tmpMeta[2];
_en1 = tmpMeta[3];
_p1 = tmpMeta[4];
_restr1 = tmpMeta[5];
_cd1 = tmpMeta[6];
_cm = tmpMeta[7];
_i = tmpMeta[8];
_prefixes2 = tmpMeta[9];
_cd2 = tmpMeta[10];
_mCCNew = omc_SCodeUtil_getConstrainedByModifiers(threadData, _prefixes1);
_mCCOld = omc_SCodeUtil_getConstrainedByModifiers(threadData, _prefixes2);
_cd1 = omc_SCodeUtil_mergeClassDef(threadData, _cd1, _cd2, _mCCNew, _mCCOld);
_prefixes1 = omc_SCodeUtil_propagatePrefixes(threadData, _prefixes2, _prefixes1);
tmpMeta[1] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name1, _prefixes1, _en1, _p1, _restr1, _cd1, _cm, _i);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
tmpMeta[0] = _inNew;
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
if (++tmp3 < 3) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outNew = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNew;
}
DLLExport
modelica_boolean omc_SCodeUtil_isOverloadedFunction(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _isOverloaded;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],4,1) == 0) goto tmp3_end;
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
_isOverloaded = tmp1;
_return: OMC_LABEL_UNUSED
return _isOverloaded;
}
modelica_metatype boxptr_SCodeUtil_isOverloadedFunction(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _isOverloaded;
modelica_metatype out_isOverloaded;
_isOverloaded = omc_SCodeUtil_isOverloadedFunction(threadData, _inElement);
out_isOverloaded = mmc_mk_icon(_isOverloaded);
return out_isOverloaded;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripAnnotationFromComment(threadData_t *threadData, modelica_metatype _inComment)
{
modelica_metatype _outComment = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inComment;
{
modelica_metatype _str = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_str = tmpMeta[2];
tmpMeta[1] = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, mmc_mk_none(), _str);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = mmc_mk_none();
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
_outComment = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outComment;
}
DLLExport
modelica_metatype omc_SCodeUtil_getElementComment(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outComment = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_metatype _cmt = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_cmt = tmpMeta[1];
tmpMeta[0] = mmc_mk_some(_cmt);
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_cmt = tmpMeta[1];
tmpMeta[0] = mmc_mk_some(_cmt);
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = mmc_mk_none();
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
_outComment = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outComment;
}
DLLExport
modelica_boolean omc_SCodeUtil_isClassNamed(threadData_t *threadData, modelica_string _inName, modelica_metatype _inClass)
{
modelica_boolean _outIsNamed;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_string _name = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta[0];
tmp1 = (stringEqual(_inName, _name));
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
modelica_metatype boxptr_SCodeUtil_isClassNamed(threadData_t *threadData, modelica_metatype _inName, modelica_metatype _inClass)
{
modelica_boolean _outIsNamed;
modelica_metatype out_outIsNamed;
_outIsNamed = omc_SCodeUtil_isClassNamed(threadData, _inName, _inClass);
out_outIsNamed = mmc_mk_icon(_outIsNamed);
return out_outIsNamed;
}
DLLExport
modelica_metatype omc_SCodeUtil_setElementVisibility(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inVisibility)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_string _name = NULL;
modelica_metatype _prefs = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _info = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _pp = NULL;
modelica_metatype _res = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype _bc = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _imp = NULL;
modelica_metatype _unit = NULL;
modelica_metatype _weight = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_name = tmpMeta[1];
_prefs = tmpMeta[2];
_attr = tmpMeta[3];
_ty = tmpMeta[4];
_mod = tmpMeta[5];
_cmt = tmpMeta[6];
_cond = tmpMeta[7];
_info = tmpMeta[8];
_prefs = omc_SCodeUtil_prefixesSetVisibility(threadData, _prefs, _inVisibility);
tmpMeta[1] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _name, _prefs, _attr, _ty, _mod, _cmt, _cond, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_name = tmpMeta[1];
_prefs = tmpMeta[2];
_ep = tmpMeta[3];
_pp = tmpMeta[4];
_res = tmpMeta[5];
_cdef = tmpMeta[6];
_cmt = tmpMeta[7];
_info = tmpMeta[8];
_prefs = omc_SCodeUtil_prefixesSetVisibility(threadData, _prefs, _inVisibility);
tmpMeta[1] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name, _prefs, _ep, _pp, _res, _cdef, _cmt, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_bc = tmpMeta[1];
_mod = tmpMeta[2];
_ann = tmpMeta[3];
_info = tmpMeta[4];
tmpMeta[1] = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _bc, _inVisibility, _mod, _ann, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_imp = tmpMeta[1];
_info = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(3, &SCode_Element_IMPORT__desc, _imp, _inVisibility, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_name = tmpMeta[1];
_unit = tmpMeta[2];
_weight = tmpMeta[3];
_info = tmpMeta[4];
tmpMeta[1] = mmc_mk_box6(7, &SCode_Element_DEFINEUNIT__desc, _name, _inVisibility, _unit, _weight, _info);
tmpMeta[0] = tmpMeta[1];
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
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLExport
modelica_boolean omc_SCodeUtil_isRestrictionImpure(threadData_t *threadData, modelica_metatype _inRestr, modelica_boolean _hasZeroOutputPreMSL3_2)
{
modelica_boolean _isExternal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_boolean tmp4_2;
tmp4_1 = _inRestr;
tmp4_2 = _hasZeroOutputPreMSL3_2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp6) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp7) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_integer tmp8;
if (0 != tmp4_2) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp8 = mmc_unbox_integer(tmpMeta[1]);
if (0 != tmp8) goto tmp3_end;
tmp1 = 1;
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
_isExternal = tmp1;
_return: OMC_LABEL_UNUSED
return _isExternal;
}
modelica_metatype boxptr_SCodeUtil_isRestrictionImpure(threadData_t *threadData, modelica_metatype _inRestr, modelica_metatype _hasZeroOutputPreMSL3_2)
{
modelica_integer tmp1;
modelica_boolean _isExternal;
modelica_metatype out_isExternal;
tmp1 = mmc_unbox_integer(_hasZeroOutputPreMSL3_2);
_isExternal = omc_SCodeUtil_isRestrictionImpure(threadData, _inRestr, tmp1);
out_isExternal = mmc_mk_icon(_isExternal);
return out_isExternal;
}
DLLExport
modelica_boolean omc_SCodeUtil_isImpureFunctionRestriction(threadData_t *threadData, modelica_metatype _inRestr)
{
modelica_boolean _isExternal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRestr;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta[0]);
if (1 != tmp6) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta[0]);
if (1 != tmp7) goto tmp3_end;
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
_isExternal = tmp1;
_return: OMC_LABEL_UNUSED
return _isExternal;
}
modelica_metatype boxptr_SCodeUtil_isImpureFunctionRestriction(threadData_t *threadData, modelica_metatype _inRestr)
{
modelica_boolean _isExternal;
modelica_metatype out_isExternal;
_isExternal = omc_SCodeUtil_isImpureFunctionRestriction(threadData, _inRestr);
out_isExternal = mmc_mk_icon(_isExternal);
return out_isExternal;
}
DLLExport
modelica_boolean omc_SCodeUtil_isExternalFunctionRestriction(threadData_t *threadData, modelica_metatype _inRestr)
{
modelica_boolean _isExternal;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRestr;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
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
_isExternal = tmp1;
_return: OMC_LABEL_UNUSED
return _isExternal;
}
modelica_metatype boxptr_SCodeUtil_isExternalFunctionRestriction(threadData_t *threadData, modelica_metatype _inRestr)
{
modelica_boolean _isExternal;
modelica_metatype out_isExternal;
_isExternal = omc_SCodeUtil_isExternalFunctionRestriction(threadData, _inRestr);
out_isExternal = mmc_mk_icon(_isExternal);
return out_isExternal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_partitionElements2(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inComponents, modelica_metatype _inClasses, modelica_metatype _inExtends, modelica_metatype _inImports, modelica_metatype _inDefineUnits, modelica_metatype *out_outClasses, modelica_metatype *out_outExtends, modelica_metatype *out_outImports, modelica_metatype *out_outDefineUnits)
{
modelica_metatype _outComponents = NULL;
modelica_metatype _outClasses = NULL;
modelica_metatype _outExtends = NULL;
modelica_metatype _outImports = NULL;
modelica_metatype _outDefineUnits = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;modelica_metatype tmp4_5;modelica_metatype tmp4_6;
tmp4_1 = _inElements;
tmp4_2 = _inComponents;
tmp4_3 = _inClasses;
tmp4_4 = _inExtends;
tmp4_5 = _inImports;
tmp4_6 = _inDefineUnits;
{
modelica_metatype _el = NULL;
modelica_metatype _rest_el = NULL;
modelica_metatype _comp = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _ext = NULL;
modelica_metatype _imp = NULL;
modelica_metatype _def = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmp4_1);
tmpMeta[6] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],3,8) == 0) goto tmp3_end;
_el = tmpMeta[5];
_rest_el = tmpMeta[6];
_comp = tmp4_2;
_cls = tmp4_3;
_ext = tmp4_4;
_imp = tmp4_5;
_def = tmp4_6;
tmpMeta[5] = mmc_mk_cons(_el, _comp);
_inElements = _rest_el;
_inComponents = tmpMeta[5];
_inClasses = _cls;
_inExtends = _ext;
_inImports = _imp;
_inDefineUnits = _def;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmp4_1);
tmpMeta[6] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],2,8) == 0) goto tmp3_end;
_el = tmpMeta[5];
_rest_el = tmpMeta[6];
_comp = tmp4_2;
_cls = tmp4_3;
_ext = tmp4_4;
_imp = tmp4_5;
_def = tmp4_6;
tmpMeta[5] = mmc_mk_cons(_el, _cls);
_inElements = _rest_el;
_inComponents = _comp;
_inClasses = tmpMeta[5];
_inExtends = _ext;
_inImports = _imp;
_inDefineUnits = _def;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmp4_1);
tmpMeta[6] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],1,5) == 0) goto tmp3_end;
_el = tmpMeta[5];
_rest_el = tmpMeta[6];
_comp = tmp4_2;
_cls = tmp4_3;
_ext = tmp4_4;
_imp = tmp4_5;
_def = tmp4_6;
tmpMeta[5] = mmc_mk_cons(_el, _ext);
_inElements = _rest_el;
_inComponents = _comp;
_inClasses = _cls;
_inExtends = tmpMeta[5];
_inImports = _imp;
_inDefineUnits = _def;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmp4_1);
tmpMeta[6] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,3) == 0) goto tmp3_end;
_el = tmpMeta[5];
_rest_el = tmpMeta[6];
_comp = tmp4_2;
_cls = tmp4_3;
_ext = tmp4_4;
_imp = tmp4_5;
_def = tmp4_6;
tmpMeta[5] = mmc_mk_cons(_el, _imp);
_inElements = _rest_el;
_inComponents = _comp;
_inClasses = _cls;
_inExtends = _ext;
_inImports = tmpMeta[5];
_inDefineUnits = _def;
goto _tailrecursive;
goto tmp3_done;
}
case 4: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmp4_1);
tmpMeta[6] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],4,5) == 0) goto tmp3_end;
_el = tmpMeta[5];
_rest_el = tmpMeta[6];
_comp = tmp4_2;
_cls = tmp4_3;
_ext = tmp4_4;
_imp = tmp4_5;
_def = tmp4_6;
tmpMeta[5] = mmc_mk_cons(_el, _def);
_inElements = _rest_el;
_inComponents = _comp;
_inClasses = _cls;
_inExtends = _ext;
_inImports = _imp;
_inDefineUnits = tmpMeta[5];
goto _tailrecursive;
goto tmp3_done;
}
case 5: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_comp = tmp4_2;
_cls = tmp4_3;
_ext = tmp4_4;
_imp = tmp4_5;
_def = tmp4_6;
tmpMeta[0+0] = listReverse(_comp);
tmpMeta[0+1] = listReverse(_cls);
tmpMeta[0+2] = listReverse(_ext);
tmpMeta[0+3] = listReverse(_imp);
tmpMeta[0+4] = listReverse(_def);
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
_outComponents = tmpMeta[0+0];
_outClasses = tmpMeta[0+1];
_outExtends = tmpMeta[0+2];
_outImports = tmpMeta[0+3];
_outDefineUnits = tmpMeta[0+4];
_return: OMC_LABEL_UNUSED
if (out_outClasses) { *out_outClasses = _outClasses; }
if (out_outExtends) { *out_outExtends = _outExtends; }
if (out_outImports) { *out_outImports = _outImports; }
if (out_outDefineUnits) { *out_outDefineUnits = _outDefineUnits; }
return _outComponents;
}
DLLExport
modelica_metatype omc_SCodeUtil_partitionElements(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype *out_outClasses, modelica_metatype *out_outExtends, modelica_metatype *out_outImports, modelica_metatype *out_outDefineUnits)
{
modelica_metatype _outComponents = NULL;
modelica_metatype _outClasses = NULL;
modelica_metatype _outExtends = NULL;
modelica_metatype _outImports = NULL;
modelica_metatype _outDefineUnits = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
_outComponents = omc_SCodeUtil_partitionElements2(threadData, _inElements, tmpMeta[0], tmpMeta[1], tmpMeta[2], tmpMeta[3], tmpMeta[4] ,&_outClasses ,&_outExtends ,&_outImports ,&_outDefineUnits);
_return: OMC_LABEL_UNUSED
if (out_outClasses) { *out_outClasses = _outClasses; }
if (out_outExtends) { *out_outExtends = _outExtends; }
if (out_outImports) { *out_outImports = _outImports; }
if (out_outDefineUnits) { *out_outDefineUnits = _outDefineUnits; }
return _outComponents;
}
DLLExport
modelica_boolean omc_SCodeUtil_isBuiltinElement(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsBuiltin;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,8) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
if (7 != MMC_STRLEN(tmpMeta[4]) || strcmp(MMC_STRINGDATA(_OMC_LIT21), MMC_STRINGDATA(tmpMeta[4])) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_ann = tmpMeta[2];
tmp1 = omc_SCodeUtil_hasBooleanNamedAnnotation(threadData, _ann, _OMC_LIT20);
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
_outIsBuiltin = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsBuiltin;
}
modelica_metatype boxptr_SCodeUtil_isBuiltinElement(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsBuiltin;
modelica_metatype out_outIsBuiltin;
_outIsBuiltin = omc_SCodeUtil_isBuiltinElement(threadData, _inElement);
out_outIsBuiltin = mmc_mk_icon(_outIsBuiltin);
return out_outIsBuiltin;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_setClassDefMod(threadData_t *threadData, modelica_metatype _inClassDef, modelica_metatype _inMod)
{
modelica_metatype _outClassDef = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inClassDef;
{
modelica_metatype _cdef = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _attr = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_ty = tmpMeta[1];
_attr = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(5, &SCode_ClassDef_DERIVED__desc, _ty, _inMod, _attr);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_cdef = tmpMeta[1];
tmpMeta[1] = mmc_mk_box3(4, &SCode_ClassDef_CLASS__EXTENDS__desc, _inMod, _cdef);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _inClassDef;
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
_outClassDef = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outClassDef;
}
DLLExport
modelica_metatype omc_SCodeUtil_setElementMod(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inMod)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_string _n = NULL;
modelica_metatype _pf = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _cnd = NULL;
modelica_metatype _i = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _pp = NULL;
modelica_metatype _res = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype _bc = NULL;
modelica_metatype _vis = NULL;
modelica_metatype _ann = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_n = tmpMeta[1];
_pf = tmpMeta[2];
_attr = tmpMeta[3];
_ty = tmpMeta[4];
_cmt = tmpMeta[5];
_cnd = tmpMeta[6];
_i = tmpMeta[7];
tmpMeta[1] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _n, _pf, _attr, _ty, _inMod, _cmt, _cnd, _i);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_n = tmpMeta[1];
_pf = tmpMeta[2];
_ep = tmpMeta[3];
_pp = tmpMeta[4];
_res = tmpMeta[5];
_cdef = tmpMeta[6];
_cmt = tmpMeta[7];
_i = tmpMeta[8];
_cdef = omc_SCodeUtil_setClassDefMod(threadData, _cdef, _inMod);
tmpMeta[1] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _n, _pf, _ep, _pp, _res, _cdef, _cmt, _i);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_bc = tmpMeta[1];
_vis = tmpMeta[2];
_ann = tmpMeta[3];
_i = tmpMeta[4];
tmpMeta[1] = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _bc, _vis, _inMod, _ann, _i);
tmpMeta[0] = tmpMeta[1];
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
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLExport
modelica_metatype omc_SCodeUtil_elementMod(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_metatype _mod = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_mod = tmpMeta[1];
tmpMeta[0] = _mod;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_mod = tmpMeta[2];
tmpMeta[0] = _mod;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_mod = tmpMeta[2];
tmpMeta[0] = _mod;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_mod = tmpMeta[1];
tmpMeta[0] = _mod;
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
_outMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMod;
}
DLLExport
modelica_metatype omc_SCodeUtil_componentMod(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_metatype _mod = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_mod = tmpMeta[1];
tmpMeta[0] = _mod;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _OMC_LIT15;
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
_outMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMod;
}
DLLExport
modelica_boolean omc_SCodeUtil_isRedeclareSubMod(threadData_t *threadData, modelica_metatype _inSubMod)
{
modelica_boolean _outIsRedeclare;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSubMod;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,3) == 0) goto tmp3_end;
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
_outIsRedeclare = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsRedeclare;
}
modelica_metatype boxptr_SCodeUtil_isRedeclareSubMod(threadData_t *threadData, modelica_metatype _inSubMod)
{
modelica_boolean _outIsRedeclare;
modelica_metatype out_outIsRedeclare;
_outIsRedeclare = omc_SCodeUtil_isRedeclareSubMod(threadData, _inSubMod);
out_outIsRedeclare = mmc_mk_icon(_outIsRedeclare);
return out_outIsRedeclare;
}
DLLExport
modelica_metatype omc_SCodeUtil_getClassRestriction(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outRestriction = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inElement;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
_outRestriction = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outRestriction;
}
DLLExport
modelica_metatype omc_SCodeUtil_getClassPartialPrefix(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outPartial = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inElement;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_outPartial = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outPartial;
}
DLLExport
modelica_boolean omc_SCodeUtil_algorithmContainReinit(threadData_t *threadData, modelica_metatype _inAlg)
{
modelica_boolean _hasReinit;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAlg;
{
modelica_boolean _b1;
modelica_boolean _b2;
modelica_boolean _b3;
modelica_metatype _algs = NULL;
modelica_metatype _algs1 = NULL;
modelica_metatype _algs2 = NULL;
modelica_metatype _algs_lst = NULL;
modelica_metatype _tpl_alg = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 11: {
tmp1 = 1;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_tpl_alg = tmpMeta[0];
_algs_lst = omc_List_map(threadData, _tpl_alg, boxvar_Util_tuple22);
tmp1 = mmc_unbox_boolean(omc_List_applyAndFold(threadData, _algs_lst, boxvar_boolOr, boxvar_SCodeUtil_algorithmsContainReinit, mmc_mk_boolean(0)));
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,6) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_algs1 = tmpMeta[0];
_tpl_alg = tmpMeta[1];
_algs2 = tmpMeta[2];
_b1 = omc_SCodeUtil_algorithmsContainReinit(threadData, _algs1);
_algs_lst = omc_List_map(threadData, _tpl_alg, boxvar_Util_tuple22);
_b2 = mmc_unbox_boolean(omc_List_applyAndFold(threadData, _algs_lst, boxvar_boolOr, boxvar_SCodeUtil_algorithmsContainReinit, mmc_mk_boolean(_b1)));
_b3 = omc_SCodeUtil_algorithmsContainReinit(threadData, _algs2);
tmp1 = (_b1 || (_b2 || _b3));
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_algs = tmpMeta[0];
tmp1 = omc_SCodeUtil_algorithmsContainReinit(threadData, _algs);
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_algs = tmpMeta[0];
tmp1 = omc_SCodeUtil_algorithmsContainReinit(threadData, _algs);
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
_hasReinit = tmp1;
_return: OMC_LABEL_UNUSED
return _hasReinit;
}
modelica_metatype boxptr_SCodeUtil_algorithmContainReinit(threadData_t *threadData, modelica_metatype _inAlg)
{
modelica_boolean _hasReinit;
modelica_metatype out_hasReinit;
_hasReinit = omc_SCodeUtil_algorithmContainReinit(threadData, _inAlg);
out_hasReinit = mmc_mk_icon(_hasReinit);
return out_hasReinit;
}
DLLExport
modelica_boolean omc_SCodeUtil_algorithmsContainReinit(threadData_t *threadData, modelica_metatype _inAlgs)
{
modelica_boolean _hasReinit;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hasReinit = mmc_unbox_boolean(omc_List_applyAndFold(threadData, _inAlgs, boxvar_boolOr, boxvar_SCodeUtil_algorithmContainReinit, mmc_mk_boolean(0)));
_return: OMC_LABEL_UNUSED
return _hasReinit;
}
modelica_metatype boxptr_SCodeUtil_algorithmsContainReinit(threadData_t *threadData, modelica_metatype _inAlgs)
{
modelica_boolean _hasReinit;
modelica_metatype out_hasReinit;
_hasReinit = omc_SCodeUtil_algorithmsContainReinit(threadData, _inAlgs);
out_hasReinit = mmc_mk_icon(_hasReinit);
return out_hasReinit;
}
DLLExport
modelica_boolean omc_SCodeUtil_equationContainReinit(threadData_t *threadData, modelica_metatype _inEq)
{
modelica_boolean _hasReinit;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inEq;
{
modelica_boolean _b;
modelica_metatype _eqs = NULL;
modelica_metatype _eqs_lst = NULL;
modelica_metatype _tpl_el = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 11: {
tmp1 = 1;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_eqs = tmpMeta[0];
_tpl_el = tmpMeta[1];
_b = omc_SCodeUtil_equationsContainReinit(threadData, _eqs);
_eqs_lst = omc_List_map(threadData, _tpl_el, boxvar_Util_tuple22);
tmp1 = mmc_unbox_boolean(omc_List_applyAndFold(threadData, _eqs_lst, boxvar_boolOr, boxvar_SCodeUtil_equationsContainReinit, mmc_mk_boolean(_b)));
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_eqs_lst = tmpMeta[0];
_eqs = tmpMeta[1];
_b = omc_SCodeUtil_equationsContainReinit(threadData, _eqs);
tmp1 = mmc_unbox_boolean(omc_List_applyAndFold(threadData, _eqs_lst, boxvar_boolOr, boxvar_SCodeUtil_equationsContainReinit, mmc_mk_boolean(_b)));
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_eqs = tmpMeta[0];
tmp1 = omc_SCodeUtil_equationsContainReinit(threadData, _eqs);
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
_hasReinit = tmp1;
_return: OMC_LABEL_UNUSED
return _hasReinit;
}
modelica_metatype boxptr_SCodeUtil_equationContainReinit(threadData_t *threadData, modelica_metatype _inEq)
{
modelica_boolean _hasReinit;
modelica_metatype out_hasReinit;
_hasReinit = omc_SCodeUtil_equationContainReinit(threadData, _inEq);
out_hasReinit = mmc_mk_icon(_hasReinit);
return out_hasReinit;
}
DLLExport
modelica_boolean omc_SCodeUtil_equationsContainReinit(threadData_t *threadData, modelica_metatype _inEqs)
{
modelica_boolean _hasReinit;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hasReinit = mmc_unbox_boolean(omc_List_applyAndFold(threadData, _inEqs, boxvar_boolOr, boxvar_SCodeUtil_equationContainReinit, mmc_mk_boolean(0)));
_return: OMC_LABEL_UNUSED
return _hasReinit;
}
modelica_metatype boxptr_SCodeUtil_equationsContainReinit(threadData_t *threadData, modelica_metatype _inEqs)
{
modelica_boolean _hasReinit;
modelica_metatype out_hasReinit;
_hasReinit = omc_SCodeUtil_equationsContainReinit(threadData, _inEqs);
out_hasReinit = mmc_mk_icon(_hasReinit);
return out_hasReinit;
}
DLLExport
modelica_metatype omc_SCodeUtil_getClassDef(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _outCdef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inClass;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_outCdef = tmpMeta[1];
tmpMeta[0] = _outCdef;
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
_outCdef = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outCdef;
}
DLLExport
modelica_metatype omc_SCodeUtil_makeEquation(threadData_t *threadData, modelica_metatype _inEEq)
{
modelica_metatype _outEq = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box2(3, &SCode_Equation_EQUATION__desc, _inEEq);
_outEq = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outEq;
}
DLLExport
modelica_metatype omc_SCodeUtil_setClassPrefixes(threadData_t *threadData, modelica_metatype _inPrefixes, modelica_metatype _cl)
{
modelica_metatype _outCl = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _cl;
{
modelica_metatype _parts = NULL;
modelica_metatype _e = NULL;
modelica_string _id = NULL;
modelica_metatype _info = NULL;
modelica_metatype _restriction = NULL;
modelica_metatype _pp = NULL;
modelica_metatype _cmt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_id = tmpMeta[1];
_e = tmpMeta[2];
_pp = tmpMeta[3];
_restriction = tmpMeta[4];
_parts = tmpMeta[5];
_cmt = tmpMeta[6];
_info = tmpMeta[7];
tmpMeta[1] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _id, _inPrefixes, _e, _pp, _restriction, _parts, _cmt, _info);
tmpMeta[0] = tmpMeta[1];
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
_outCl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outCl;
}
DLLExport
modelica_metatype omc_SCodeUtil_getDerivedMod(threadData_t *threadData, modelica_metatype _inE)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inE;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_outMod = tmpMeta[2];
_return: OMC_LABEL_UNUSED
return _outMod;
}
DLLExport
modelica_metatype omc_SCodeUtil_getDerivedTypeSpec(threadData_t *threadData, modelica_metatype _inE)
{
modelica_metatype _outTypeSpec = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inE;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_outTypeSpec = tmpMeta[2];
_return: OMC_LABEL_UNUSED
return _outTypeSpec;
}
DLLExport
modelica_metatype omc_SCodeUtil_setDerivedTypeSpec(threadData_t *threadData, modelica_metatype _inE, modelica_metatype _inTypeSpec)
{
modelica_metatype _outE = NULL;
modelica_string _n = NULL;
modelica_metatype _pr = NULL;
modelica_metatype _atr = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _pp = NULL;
modelica_metatype _res = NULL;
modelica_metatype _cd = NULL;
modelica_metatype _i = NULL;
modelica_metatype _ts = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _m = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inE;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
_n = tmpMeta[1];
_pr = tmpMeta[2];
_ep = tmpMeta[3];
_pp = tmpMeta[4];
_res = tmpMeta[5];
_cd = tmpMeta[6];
_cmt = tmpMeta[7];
_i = tmpMeta[8];
tmpMeta[0] = _cd;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_ts = tmpMeta[1];
_m = tmpMeta[2];
_atr = tmpMeta[3];
tmpMeta[0] = mmc_mk_box4(5, &SCode_ClassDef_DERIVED__desc, _inTypeSpec, _m, _atr);
_cd = tmpMeta[0];
tmpMeta[0] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _n, _pr, _ep, _pp, _res, _cd, _cmt, _i);
_outE = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outE;
}
DLLExport
modelica_boolean omc_SCodeUtil_isClassExtends(threadData_t *threadData, modelica_metatype _cls)
{
modelica_boolean _isCE;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cls;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,2) == 0) goto tmp3_end;
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
_isCE = tmp1;
_return: OMC_LABEL_UNUSED
return _isCE;
}
modelica_metatype boxptr_SCodeUtil_isClassExtends(threadData_t *threadData, modelica_metatype _cls)
{
modelica_boolean _isCE;
modelica_metatype out_isCE;
_isCE = omc_SCodeUtil_isClassExtends(threadData, _cls);
out_isCE = mmc_mk_icon(_isCE);
return out_isCE;
}
DLLExport
modelica_boolean omc_SCodeUtil_isDerivedClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _isDerived;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,3) == 0) goto tmp3_end;
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
_isDerived = tmp1;
_return: OMC_LABEL_UNUSED
return _isDerived;
}
modelica_metatype boxptr_SCodeUtil_isDerivedClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _isDerived;
modelica_metatype out_isDerived;
_isDerived = omc_SCodeUtil_isDerivedClass(threadData, _inClass);
out_isDerived = mmc_mk_icon(_isDerived);
return out_isDerived;
}
DLLExport
modelica_metatype omc_SCodeUtil_getComponentMod(threadData_t *threadData, modelica_metatype _inE)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inE;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
_outMod = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outMod;
}
DLLExport
modelica_metatype omc_SCodeUtil_setComponentMod(threadData_t *threadData, modelica_metatype _inE, modelica_metatype _inMod)
{
modelica_metatype _outE = NULL;
modelica_string _n = NULL;
modelica_metatype _pr = NULL;
modelica_metatype _atr = NULL;
modelica_metatype _ts = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _cnd = NULL;
modelica_metatype _bc = NULL;
modelica_metatype _v = NULL;
modelica_metatype _m = NULL;
modelica_metatype _a = NULL;
modelica_metatype _i = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inE;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
_n = tmpMeta[1];
_pr = tmpMeta[2];
_atr = tmpMeta[3];
_ts = tmpMeta[4];
_m = tmpMeta[5];
_cmt = tmpMeta[6];
_cnd = tmpMeta[7];
_i = tmpMeta[8];
tmpMeta[0] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _n, _pr, _atr, _ts, _inMod, _cmt, _cnd, _i);
_outE = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outE;
}
DLLExport
modelica_metatype omc_SCodeUtil_getComponentTypeSpec(threadData_t *threadData, modelica_metatype _inE)
{
modelica_metatype _outTypeSpec = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inE;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_outTypeSpec = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outTypeSpec;
}
DLLExport
modelica_metatype omc_SCodeUtil_setComponentTypeSpec(threadData_t *threadData, modelica_metatype _inE, modelica_metatype _inTypeSpec)
{
modelica_metatype _outE = NULL;
modelica_string _n = NULL;
modelica_metatype _pr = NULL;
modelica_metatype _atr = NULL;
modelica_metatype _ts = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _cnd = NULL;
modelica_metatype _bc = NULL;
modelica_metatype _v = NULL;
modelica_metatype _m = NULL;
modelica_metatype _a = NULL;
modelica_metatype _i = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inE;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
_n = tmpMeta[1];
_pr = tmpMeta[2];
_atr = tmpMeta[3];
_ts = tmpMeta[4];
_m = tmpMeta[5];
_cmt = tmpMeta[6];
_cnd = tmpMeta[7];
_i = tmpMeta[8];
tmpMeta[0] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _n, _pr, _atr, _inTypeSpec, _m, _cmt, _cnd, _i);
_outE = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outE;
}
DLLExport
modelica_metatype omc_SCodeUtil_getBaseClassPath(threadData_t *threadData, modelica_metatype _inE)
{
modelica_metatype _outBcPath = NULL;
modelica_metatype _bc = NULL;
modelica_metatype _v = NULL;
modelica_metatype _m = NULL;
modelica_metatype _a = NULL;
modelica_metatype _i = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inE;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,5) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_outBcPath = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outBcPath;
}
DLLExport
modelica_metatype omc_SCodeUtil_setBaseClassPath(threadData_t *threadData, modelica_metatype _inE, modelica_metatype _inBcPath)
{
modelica_metatype _outE = NULL;
modelica_metatype _bc = NULL;
modelica_metatype _v = NULL;
modelica_metatype _m = NULL;
modelica_metatype _a = NULL;
modelica_metatype _i = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inE;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,5) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
_bc = tmpMeta[1];
_v = tmpMeta[2];
_m = tmpMeta[3];
_a = tmpMeta[4];
_i = tmpMeta[5];
tmpMeta[0] = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _inBcPath, _v, _m, _a, _i);
_outE = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outE;
}
DLLExport
modelica_string omc_SCodeUtil_getElementName(threadData_t *threadData, modelica_metatype _e)
{
modelica_string _s = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _e;
{
modelica_metatype _p = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_s = tmpMeta[0];
tmp1 = _s;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_s = tmpMeta[0];
tmp1 = _s;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_p = tmpMeta[0];
tmp1 = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0);
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
modelica_metatype omc_SCodeUtil_getElementWithPath(threadData_t *threadData, modelica_metatype _inProgram, modelica_metatype _inPath)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inPath;
{
modelica_metatype _sp = NULL;
modelica_metatype _e = NULL;
modelica_metatype _p = NULL;
modelica_string _i = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta[1];
_inPath = _p;
goto _tailrecursive;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_i = tmpMeta[1];
tmpMeta[0] = omc_SCodeUtil_getElementWithId(threadData, _inProgram, _i);
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_i = tmpMeta[1];
_p = tmpMeta[2];
_e = omc_SCodeUtil_getElementWithId(threadData, _inProgram, _i);
_sp = omc_SCodeUtil_getElementsFromElement(threadData, _inProgram, _e);
_inProgram = _sp;
_inPath = _p;
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
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_getElementWithId(threadData_t *threadData, modelica_metatype _inProgram, modelica_string _inId)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_string tmp3_2;
tmp3_1 = _inProgram;
tmp3_2 = _inId;
{
modelica_metatype _rest = NULL;
modelica_metatype _e = NULL;
modelica_metatype _p = NULL;
modelica_string _i = NULL;
modelica_string _n = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_e = tmpMeta[1];
_n = tmpMeta[3];
_i = tmp3_2;
if (!(stringEqual(_n, _i))) goto tmp2_end;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_e = tmpMeta[1];
_n = tmpMeta[3];
_i = tmp3_2;
if (!(stringEqual(_n, _i))) goto tmp2_end;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,5) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_e = tmpMeta[1];
_p = tmpMeta[3];
_i = tmp3_2;
if (!(stringEqual(omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0), _i))) goto tmp2_end;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
_i = tmp3_2;
_inProgram = _rest;
_inId = _i;
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
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLExport
modelica_metatype omc_SCodeUtil_replaceElementsInClassDef(threadData_t *threadData, modelica_metatype _inProgram, modelica_metatype __omcQ_24in_5FclassDef, modelica_metatype _inElements, modelica_metatype *out_outElementOpt)
{
modelica_metatype _classDef = NULL;
modelica_metatype _outElementOpt = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_classDef = __omcQ_24in_5FclassDef;
{
modelica_metatype tmp3_1;
tmp3_1 = _classDef;
{
modelica_metatype _e = NULL;
modelica_metatype _p = NULL;
modelica_metatype _composition = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_p = tmpMeta[2];
_e = omc_SCodeUtil_getElementWithPath(threadData, _inProgram, _p);
_e = omc_SCodeUtil_replaceElementsInElement(threadData, _inProgram, _e, _inElements);
tmpMeta[0] = mmc_mk_some(_e);
goto tmp2_done;
}
case 3: {
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(10));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_classDef), 10*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[2] = _inElements;
_classDef = tmpMeta[1];
tmpMeta[0] = mmc_mk_none();
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_composition = tmpMeta[1];
_composition = omc_SCodeUtil_replaceElementsInClassDef(threadData, _inProgram, _composition, _inElements ,&_outElementOpt);
if(isNone(_outElementOpt))
{
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_classDef), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[3] = _composition;
_classDef = tmpMeta[1];
}
tmpMeta[0] = _outElementOpt;
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
_outElementOpt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
if (out_outElementOpt) { *out_outElementOpt = _outElementOpt; }
return _classDef;
}
DLLExport
modelica_metatype omc_SCodeUtil_replaceElementsInElement(threadData_t *threadData, modelica_metatype _inProgram, modelica_metatype _inElement, modelica_metatype _inElements)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_metatype _e = NULL;
modelica_string _name = NULL;
modelica_metatype _prefixes = NULL;
modelica_metatype _encapsulatedPrefix = NULL;
modelica_metatype _partialPrefix = NULL;
modelica_metatype _restriction = NULL;
modelica_metatype _classDef = NULL;
modelica_metatype _info = NULL;
modelica_metatype _cmt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_name = tmpMeta[1];
_prefixes = tmpMeta[2];
_encapsulatedPrefix = tmpMeta[3];
_partialPrefix = tmpMeta[4];
_restriction = tmpMeta[5];
_classDef = tmpMeta[6];
_cmt = tmpMeta[7];
_info = tmpMeta[8];
tmpMeta[2] = omc_SCodeUtil_replaceElementsInClassDef(threadData, _inProgram, _classDef, _inElements, &tmpMeta[1]);
_classDef = tmpMeta[2];
if (!optionNone(tmpMeta[1])) goto goto_1;
tmpMeta[1] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name, _prefixes, _encapsulatedPrefix, _partialPrefix, _restriction, _classDef, _cmt, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_classDef = tmpMeta[1];
tmpMeta[3] = omc_SCodeUtil_replaceElementsInClassDef(threadData, _inProgram, _classDef, _inElements, &tmpMeta[1]);
_classDef = tmpMeta[3];
if (optionNone(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_e = tmpMeta[2];
tmpMeta[0] = _e;
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
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLExport
modelica_metatype omc_SCodeUtil_getElementsFromElement(threadData_t *threadData, modelica_metatype _inProgram, modelica_metatype _inElement)
{
modelica_metatype _outProgram = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_metatype _els = NULL;
modelica_metatype _e = NULL;
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,8) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_els = tmpMeta[2];
tmpMeta[0] = _els;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_els = tmpMeta[3];
tmpMeta[0] = _els;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_p = tmpMeta[3];
_e = omc_SCodeUtil_getElementWithPath(threadData, _inProgram, _p);
_inElement = _e;
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
_outProgram = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outProgram;
}
DLLExport
modelica_metatype omc_SCodeUtil_replaceOrAddElementWithId(threadData_t *threadData, modelica_metatype _inProgram, modelica_metatype _inElement, modelica_string _inId)
{
modelica_metatype _outProgram = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_string tmp3_2;
tmp3_1 = _inProgram;
tmp3_2 = _inId;
{
modelica_metatype _sp = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _e = NULL;
modelica_metatype _p = NULL;
modelica_string _i = NULL;
modelica_string _n = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_n = tmpMeta[3];
_rest = tmpMeta[2];
_i = tmp3_2;
tmp3 += 2;
tmp5 = (stringEqual(_n, _i));
if (1 != tmp5) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_inElement, _rest);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_boolean tmp6;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_n = tmpMeta[3];
_rest = tmpMeta[2];
_i = tmp3_2;
tmp3 += 1;
tmp6 = (stringEqual(_n, _i));
if (1 != tmp6) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_inElement, _rest);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
modelica_boolean tmp7;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,5) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_p = tmpMeta[3];
_rest = tmpMeta[2];
_i = tmp3_2;
tmp7 = (stringEqual(omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT22, 1, 0), _i));
if (1 != tmp7) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_inElement, _rest);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_e = tmpMeta[1];
_rest = tmpMeta[2];
_i = tmp3_2;
tmp3 += 1;
_sp = omc_SCodeUtil_replaceOrAddElementWithId(threadData, _rest, _inElement, _i);
tmpMeta[1] = mmc_mk_cons(_e, _sp);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = mmc_mk_cons(_inElement, MMC_REFSTRUCTLIT(mmc_nil));
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
if (++tmp3 < 5) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outProgram = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outProgram;
}
DLLExport
modelica_metatype omc_SCodeUtil_replaceOrAddElementInProgram(threadData_t *threadData, modelica_metatype _inProgram, modelica_metatype _inElement, modelica_metatype _inClassPath)
{
modelica_metatype _outProgram = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inClassPath;
{
modelica_metatype _sp = NULL;
modelica_metatype _e = NULL;
modelica_metatype _p = NULL;
modelica_string _i = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_i = tmpMeta[1];
_p = tmpMeta[2];
_e = omc_SCodeUtil_getElementWithId(threadData, _inProgram, _i);
_sp = omc_SCodeUtil_getElementsFromElement(threadData, _inProgram, _e);
_sp = omc_SCodeUtil_replaceOrAddElementInProgram(threadData, _sp, _inElement, _p);
_e = omc_SCodeUtil_replaceElementsInElement(threadData, _inProgram, _e, _sp);
tmpMeta[0] = omc_SCodeUtil_replaceOrAddElementWithId(threadData, _inProgram, _e, _i);
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_i = tmpMeta[1];
tmpMeta[0] = omc_SCodeUtil_replaceOrAddElementWithId(threadData, _inProgram, _inElement, _i);
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_p = tmpMeta[1];
_inClassPath = _p;
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
_outProgram = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outProgram;
}
DLLExport
modelica_boolean omc_SCodeUtil_isElementEncapsulated(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsEncapsulated;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,0) == 0) goto tmp3_end;
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
_outIsEncapsulated = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsEncapsulated;
}
modelica_metatype boxptr_SCodeUtil_isElementEncapsulated(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsEncapsulated;
modelica_metatype out_outIsEncapsulated;
_outIsEncapsulated = omc_SCodeUtil_isElementEncapsulated(threadData, _inElement);
out_outIsEncapsulated = mmc_mk_icon(_outIsEncapsulated);
return out_outIsEncapsulated;
}
DLLExport
modelica_boolean omc_SCodeUtil_isElementProtected(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsProtected;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIsProtected = (!omc_SCodeUtil_visibilityBool(threadData, omc_SCodeUtil_prefixesVisibility(threadData, omc_SCodeUtil_elementPrefixes(threadData, _inElement))));
_return: OMC_LABEL_UNUSED
return _outIsProtected;
}
modelica_metatype boxptr_SCodeUtil_isElementProtected(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsProtected;
modelica_metatype out_outIsProtected;
_outIsProtected = omc_SCodeUtil_isElementProtected(threadData, _inElement);
out_outIsProtected = mmc_mk_icon(_outIsProtected);
return out_outIsProtected;
}
DLLExport
modelica_boolean omc_SCodeUtil_isElementPublic(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsPublic;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIsPublic = omc_SCodeUtil_visibilityBool(threadData, omc_SCodeUtil_prefixesVisibility(threadData, omc_SCodeUtil_elementPrefixes(threadData, _inElement)));
_return: OMC_LABEL_UNUSED
return _outIsPublic;
}
modelica_metatype boxptr_SCodeUtil_isElementPublic(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsPublic;
modelica_metatype out_outIsPublic;
_outIsPublic = omc_SCodeUtil_isElementPublic(threadData, _inElement);
out_outIsPublic = mmc_mk_icon(_outIsPublic);
return out_outIsPublic;
}
DLLExport
modelica_metatype omc_SCodeUtil_makeElementProtected(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[13] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_string _name = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _cnd = NULL;
modelica_metatype _info = NULL;
modelica_metatype _rdp = NULL;
modelica_metatype _fp = NULL;
modelica_metatype _io = NULL;
modelica_metatype _rpp = NULL;
modelica_metatype _bc = NULL;
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,0) == 0) goto tmp2_end;
tmpMeta[0] = _inElement;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_name = tmpMeta[1];
_rdp = tmpMeta[3];
_fp = tmpMeta[4];
_io = tmpMeta[5];
_rpp = tmpMeta[6];
_attr = tmpMeta[7];
_ty = tmpMeta[8];
_mod = tmpMeta[9];
_cmt = tmpMeta[10];
_cnd = tmpMeta[11];
_info = tmpMeta[12];
tmpMeta[1] = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _OMC_LIT23, _rdp, _fp, _io, _rpp);
tmpMeta[2] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _name, tmpMeta[1], _attr, _ty, _mod, _cmt, _cnd, _info);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,0) == 0) goto tmp2_end;
tmpMeta[0] = _inElement;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_bc = tmpMeta[1];
_mod = tmpMeta[2];
_ann = tmpMeta[3];
_info = tmpMeta[4];
tmpMeta[1] = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _bc, _OMC_LIT23, _mod, _ann, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _inElement;
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
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLExport
modelica_boolean omc_SCodeUtil_isInnerComponent(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsInner;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_metatype _io = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_io = tmpMeta[1];
tmp1 = omc_AbsynUtil_isInner(threadData, _io);
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
_outIsInner = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsInner;
}
modelica_metatype boxptr_SCodeUtil_isInnerComponent(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsInner;
modelica_metatype out_outIsInner;
_outIsInner = omc_SCodeUtil_isInnerComponent(threadData, _inElement);
out_outIsInner = mmc_mk_icon(_outIsInner);
return out_outIsInner;
}
DLLExport
modelica_metatype omc_SCodeUtil_removeComponentCondition(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outElement = NULL;
modelica_string _name = NULL;
modelica_metatype _pf = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _info = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inElement;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
_name = tmpMeta[1];
_pf = tmpMeta[2];
_attr = tmpMeta[3];
_ty = tmpMeta[4];
_mod = tmpMeta[5];
_cmt = tmpMeta[6];
_info = tmpMeta[7];
tmpMeta[0] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _name, _pf, _attr, _ty, _mod, _cmt, mmc_mk_none(), _info);
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLExport
modelica_metatype omc_SCodeUtil_getComponentCondition(threadData_t *threadData, modelica_metatype _element)
{
modelica_metatype _condition = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
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
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 8)));
goto tmp2_done;
}
case 1: {
tmpMeta[0] = mmc_mk_none();
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
_condition = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _condition;
}
DLLExport
modelica_metatype omc_SCodeUtil_getModifierBinding(threadData_t *threadData, modelica_metatype _inMod)
{
modelica_metatype _outBinding = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inMod;
{
modelica_metatype _binding = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_binding = tmpMeta[2];
tmpMeta[0] = mmc_mk_some(_binding);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = mmc_mk_none();
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
_outBinding = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outBinding;
}
DLLExport
modelica_metatype omc_SCodeUtil_getModifierInfo(threadData_t *threadData, modelica_metatype _inMod)
{
modelica_metatype _outInfo = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inMod;
{
modelica_metatype _info = NULL;
modelica_metatype _el = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_el = tmpMeta[1];
tmpMeta[0] = omc_SCodeUtil_elementInfo(threadData, _el);
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _OMC_LIT26;
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
_outInfo = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outInfo;
}
DLLExport
modelica_metatype omc_SCodeUtil_appendAnnotationToComment(threadData_t *threadData, modelica_metatype _inAnnotation, modelica_metatype _inComment)
{
modelica_metatype _outComment = NULL;
modelica_metatype tmpMeta[12] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inAnnotation;
tmp3_2 = _inComment;
{
modelica_metatype _cmt = NULL;
modelica_metatype _fp = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _mods1 = NULL;
modelica_metatype _mods2 = NULL;
modelica_metatype _b = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (!optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
_cmt = tmpMeta[2];
tmpMeta[1] = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, mmc_mk_some(_inAnnotation), _cmt);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,5) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (optionNone(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,5) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 5));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 6));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
_mods1 = tmpMeta[2];
_fp = tmpMeta[6];
_ep = tmpMeta[7];
_mods2 = tmpMeta[8];
_b = tmpMeta[9];
_info = tmpMeta[10];
_cmt = tmpMeta[11];
_mods2 = listAppend(_mods1, _mods2);
tmpMeta[1] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _fp, _ep, _mods2, _b, _info);
tmpMeta[2] = mmc_mk_box2(3, &SCode_Annotation_ANNOTATION__desc, tmpMeta[1]);
tmpMeta[3] = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, mmc_mk_some(tmpMeta[2]), _cmt);
tmpMeta[0] = tmpMeta[3];
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
_outComment = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outComment;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_isInlineTypeSubMod(threadData_t *threadData, modelica_metatype _inSubMod)
{
modelica_boolean _outIsInlineType;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSubMod;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (6 != MMC_STRLEN(tmpMeta[0]) || strcmp(MMC_STRINGDATA(_OMC_LIT27), MMC_STRINGDATA(tmpMeta[0])) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (10 != MMC_STRLEN(tmpMeta[0]) || strcmp(MMC_STRINGDATA(_OMC_LIT28), MMC_STRINGDATA(tmpMeta[0])) != 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (25 != MMC_STRLEN(tmpMeta[0]) || strcmp(MMC_STRINGDATA(_OMC_LIT29), MMC_STRINGDATA(tmpMeta[0])) != 0) goto tmp3_end;
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
_outIsInlineType = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsInlineType;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_isInlineTypeSubMod(threadData_t *threadData, modelica_metatype _inSubMod)
{
modelica_boolean _outIsInlineType;
modelica_metatype out_outIsInlineType;
_outIsInlineType = omc_SCodeUtil_isInlineTypeSubMod(threadData, _inSubMod);
out_outIsInlineType = mmc_mk_icon(_outIsInlineType);
return out_outIsInlineType;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_getInlineTypeAnnotation(threadData_t *threadData, modelica_metatype _inAnnotation)
{
modelica_metatype _outAnnotation = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inAnnotation;
{
modelica_metatype _submods = NULL;
modelica_metatype _inline_mod = NULL;
modelica_metatype _fp = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,5) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
_fp = tmpMeta[2];
_ep = tmpMeta[3];
_submods = tmpMeta[4];
_info = tmpMeta[5];
_inline_mod = omc_List_find(threadData, _submods, boxvar_SCodeUtil_isInlineTypeSubMod);
tmpMeta[1] = mmc_mk_cons(_inline_mod, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _fp, _ep, tmpMeta[1], mmc_mk_none(), _info);
tmpMeta[3] = mmc_mk_box2(3, &SCode_Annotation_ANNOTATION__desc, tmpMeta[2]);
tmpMeta[0] = mmc_mk_some(tmpMeta[3]);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = mmc_mk_none();
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
_outAnnotation = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAnnotation;
}
DLLExport
modelica_metatype omc_SCodeUtil_getInlineTypeAnnotationFromCmt(threadData_t *threadData, modelica_metatype _inComment)
{
modelica_metatype _outAnnotation = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inComment;
{
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_ann = tmpMeta[2];
tmpMeta[0] = omc_SCodeUtil_getInlineTypeAnnotation(threadData, _ann);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = mmc_mk_none();
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
_outAnnotation = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAnnotation;
}
DLLExport
modelica_boolean omc_SCodeUtil_getEvaluateAnnotation(threadData_t *threadData, modelica_metatype _inCommentOpt)
{
modelica_boolean _evalIsTrue;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCommentOpt;
{
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_ann = tmpMeta[2];
tmp1 = omc_SCodeUtil_hasBooleanNamedAnnotation(threadData, _ann, _OMC_LIT30);
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
_evalIsTrue = tmp1;
_return: OMC_LABEL_UNUSED
return _evalIsTrue;
}
modelica_metatype boxptr_SCodeUtil_getEvaluateAnnotation(threadData_t *threadData, modelica_metatype _inCommentOpt)
{
modelica_boolean _evalIsTrue;
modelica_metatype out_evalIsTrue;
_evalIsTrue = omc_SCodeUtil_getEvaluateAnnotation(threadData, _inCommentOpt);
out_evalIsTrue = mmc_mk_icon(_evalIsTrue);
return out_evalIsTrue;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_hasBooleanNamedAnnotation2(threadData_t *threadData, modelica_metatype _inSubMod, modelica_string _inName)
{
modelica_boolean _outIsMatch;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSubMod;
{
modelica_string _id = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (optionNone(tmpMeta[2])) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],4,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[4]);
if (1 != tmp6) goto tmp3_end;
_id = tmpMeta[0];
tmp1 = (stringEqual(_id, _inName));
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
_outIsMatch = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsMatch;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_hasBooleanNamedAnnotation2(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inName)
{
modelica_boolean _outIsMatch;
modelica_metatype out_outIsMatch;
_outIsMatch = omc_SCodeUtil_hasBooleanNamedAnnotation2(threadData, _inSubMod, _inName);
out_outIsMatch = mmc_mk_icon(_outIsMatch);
return out_outIsMatch;
}
DLLExport
modelica_boolean omc_SCodeUtil_hasBooleanNamedAnnotation(threadData_t *threadData, modelica_metatype _inAnnotation, modelica_string _inName)
{
modelica_boolean _outHasEntry;
modelica_metatype _submods = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inAnnotation;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,5) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_submods = tmpMeta[2];
_outHasEntry = omc_List_exist1(threadData, _submods, boxvar_SCodeUtil_hasBooleanNamedAnnotation2, _inName);
_return: OMC_LABEL_UNUSED
return _outHasEntry;
}
modelica_metatype boxptr_SCodeUtil_hasBooleanNamedAnnotation(threadData_t *threadData, modelica_metatype _inAnnotation, modelica_metatype _inName)
{
modelica_boolean _outHasEntry;
modelica_metatype out_outHasEntry;
_outHasEntry = omc_SCodeUtil_hasBooleanNamedAnnotation(threadData, _inAnnotation, _inName);
out_outHasEntry = mmc_mk_icon(_outHasEntry);
return out_outHasEntry;
}
DLLExport
modelica_boolean omc_SCodeUtil_commentHasBooleanNamedAnnotation(threadData_t *threadData, modelica_metatype _comm, modelica_string _annotationName)
{
modelica_boolean _outB;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _comm;
{
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
_ann = tmpMeta[1];
tmp1 = omc_SCodeUtil_hasBooleanNamedAnnotation(threadData, _ann, _annotationName);
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
_outB = tmp1;
_return: OMC_LABEL_UNUSED
return _outB;
}
modelica_metatype boxptr_SCodeUtil_commentHasBooleanNamedAnnotation(threadData_t *threadData, modelica_metatype _comm, modelica_metatype _annotationName)
{
modelica_boolean _outB;
modelica_metatype out_outB;
_outB = omc_SCodeUtil_commentHasBooleanNamedAnnotation(threadData, _comm, _annotationName);
out_outB = mmc_mk_icon(_outB);
return out_outB;
}
DLLExport
modelica_boolean omc_SCodeUtil_optCommentHasBooleanNamedAnnotation(threadData_t *threadData, modelica_metatype _comm, modelica_string _annotationName)
{
modelica_boolean _outB;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _comm;
{
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_ann = tmpMeta[2];
tmp1 = omc_SCodeUtil_hasBooleanNamedAnnotation(threadData, _ann, _annotationName);
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
_outB = tmp1;
_return: OMC_LABEL_UNUSED
return _outB;
}
modelica_metatype boxptr_SCodeUtil_optCommentHasBooleanNamedAnnotation(threadData_t *threadData, modelica_metatype _comm, modelica_metatype _annotationName)
{
modelica_boolean _outB;
modelica_metatype out_outB;
_outB = omc_SCodeUtil_optCommentHasBooleanNamedAnnotation(threadData, _comm, _annotationName);
out_outB = mmc_mk_icon(_outB);
return out_outB;
}
DLLExport
modelica_boolean omc_SCodeUtil_hasBooleanNamedAnnotationInComponent(threadData_t *threadData, modelica_metatype _inComponent, modelica_string _namedAnnotation)
{
modelica_boolean _hasAnn;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComponent;
{
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_ann = tmpMeta[2];
tmp1 = omc_SCodeUtil_hasBooleanNamedAnnotation(threadData, _ann, _namedAnnotation);
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
_hasAnn = tmp1;
_return: OMC_LABEL_UNUSED
return _hasAnn;
}
modelica_metatype boxptr_SCodeUtil_hasBooleanNamedAnnotationInComponent(threadData_t *threadData, modelica_metatype _inComponent, modelica_metatype _namedAnnotation)
{
modelica_boolean _hasAnn;
modelica_metatype out_hasAnn;
_hasAnn = omc_SCodeUtil_hasBooleanNamedAnnotationInComponent(threadData, _inComponent, _namedAnnotation);
out_hasAnn = mmc_mk_icon(_hasAnn);
return out_hasAnn;
}
DLLExport
modelica_boolean omc_SCodeUtil_hasBooleanNamedAnnotationInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_string _namedAnnotation)
{
modelica_boolean _hasAnn;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_ann = tmpMeta[2];
tmp1 = omc_SCodeUtil_hasBooleanNamedAnnotation(threadData, _ann, _namedAnnotation);
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
_hasAnn = tmp1;
_return: OMC_LABEL_UNUSED
return _hasAnn;
}
modelica_metatype boxptr_SCodeUtil_hasBooleanNamedAnnotationInClass(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _namedAnnotation)
{
modelica_boolean _hasAnn;
modelica_metatype out_hasAnn;
_hasAnn = omc_SCodeUtil_hasBooleanNamedAnnotationInClass(threadData, _inClass, _namedAnnotation);
out_hasAnn = mmc_mk_icon(_hasAnn);
return out_hasAnn;
}
DLLExport
modelica_metatype omc_SCodeUtil_lookupNamedAnnotations(threadData_t *threadData, modelica_metatype _ann, modelica_string _name)
{
modelica_metatype _mods = NULL;
modelica_metatype _submods = NULL;
modelica_string _id = NULL;
modelica_metatype _mod = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_mods = tmpMeta[0];
{
modelica_metatype tmp3_1;
tmp3_1 = _ann;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,5) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_submods = tmpMeta[3];
{
modelica_metatype _sm;
for (tmpMeta[2] = _submods; !listEmpty(tmpMeta[2]); tmpMeta[2]=MMC_CDR(tmpMeta[2]))
{
_sm = MMC_CAR(tmpMeta[2]);
tmpMeta[3] = _sm;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
_id = tmpMeta[4];
_mod = tmpMeta[5];
if((stringEqual(_id, _name)))
{
tmpMeta[3] = mmc_mk_cons(_mod, _mods);
_mods = tmpMeta[3];
}
}
}
tmpMeta[1] = _mods;
goto tmp2_done;
}
case 1: {
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = tmpMeta[2];
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
_mods = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _mods;
}
DLLExport
modelica_metatype omc_SCodeUtil_lookupNamedAnnotation(threadData_t *threadData, modelica_metatype _ann, modelica_string _name)
{
modelica_metatype _mod = NULL;
modelica_metatype _submods = NULL;
modelica_string _id = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ann;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,5) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_submods = tmpMeta[2];
{
modelica_metatype _sm;
for (tmpMeta[1] = _submods; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_sm = MMC_CAR(tmpMeta[1]);
tmpMeta[2] = _sm;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_id = tmpMeta[3];
_mod = tmpMeta[4];
if((stringEqual(_id, _name)))
{
goto _return;
}
}
}
tmpMeta[0] = _OMC_LIT15;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _OMC_LIT15;
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
_mod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _mod;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_hasNamedAnnotation(threadData_t *threadData, modelica_metatype _inSubMod, modelica_string _inName)
{
modelica_boolean _outIsMatch;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inSubMod;
{
modelica_string _id = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (optionNone(tmpMeta[2])) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_id = tmpMeta[0];
tmp1 = (stringEqual(_id, _inName));
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
_outIsMatch = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsMatch;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_hasNamedAnnotation(threadData_t *threadData, modelica_metatype _inSubMod, modelica_metatype _inName)
{
modelica_boolean _outIsMatch;
modelica_metatype out_outIsMatch;
_outIsMatch = omc_SCodeUtil_hasNamedAnnotation(threadData, _inSubMod, _inName);
out_outIsMatch = mmc_mk_icon(_outIsMatch);
return out_outIsMatch;
}
DLLExport
modelica_metatype omc_SCodeUtil_getNamedAnnotation(threadData_t *threadData, modelica_metatype _inAnnotation, modelica_string _inName, modelica_metatype *out_info)
{
modelica_metatype _exp = NULL;
modelica_metatype _info = NULL;
modelica_metatype _submods = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inAnnotation;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,5) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_submods = tmpMeta[2];
tmpMeta[0] = omc_List_find1(threadData, _submods, boxvar_SCodeUtil_hasNamedAnnotation, _inName);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,5) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (optionNone(tmpMeta[2])) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
_exp = tmpMeta[3];
_info = tmpMeta[4];
_return: OMC_LABEL_UNUSED
if (out_info) { *out_info = _info; }
return _exp;
}
DLLExport
modelica_metatype omc_SCodeUtil_getElementNamedAnnotation(threadData_t *threadData, modelica_metatype _element, modelica_string _name)
{
modelica_metatype _exp = NULL;
modelica_metatype _ann = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _element;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_ann = tmpMeta[2];
tmpMeta[0] = _ann;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_ann = tmpMeta[3];
tmpMeta[0] = _ann;
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_ann = tmpMeta[3];
tmpMeta[0] = _ann;
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
_ann = tmpMeta[0];
_exp = omc_SCodeUtil_getNamedAnnotation(threadData, _ann, _name, NULL);
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_isNotBuiltinClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,8) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
if (7 != MMC_STRLEN(tmpMeta[4]) || strcmp(MMC_STRINGDATA(_OMC_LIT21), MMC_STRINGDATA(tmpMeta[4])) != 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_isNotBuiltinClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_SCodeUtil_isNotBuiltinClass(threadData, _inClass);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_SCodeUtil_removeBuiltinsFromTopScope(threadData_t *threadData, modelica_metatype _inProgram)
{
modelica_metatype _outProgram = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outProgram = omc_List_filterOnTrue(threadData, _inProgram, boxvar_SCodeUtil_isNotBuiltinClass);
_return: OMC_LABEL_UNUSED
return _outProgram;
}
DLLExport
modelica_boolean omc_SCodeUtil_isConnector(threadData_t *threadData, modelica_metatype _inRestriction)
{
modelica_boolean _isConnector;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRestriction;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
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
_isConnector = tmp1;
_return: OMC_LABEL_UNUSED
return _isConnector;
}
modelica_metatype boxptr_SCodeUtil_isConnector(threadData_t *threadData, modelica_metatype _inRestriction)
{
modelica_boolean _isConnector;
modelica_metatype out_isConnector;
_isConnector = omc_SCodeUtil_isConnector(threadData, _inRestriction);
out_isConnector = mmc_mk_icon(_isConnector);
return out_isConnector;
}
DLLExport
modelica_boolean omc_SCodeUtil_isDerivedClassDef(threadData_t *threadData, modelica_metatype _inClassDef)
{
modelica_boolean _isDerived;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClassDef;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
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
_isDerived = tmp1;
_return: OMC_LABEL_UNUSED
return _isDerived;
}
modelica_metatype boxptr_SCodeUtil_isDerivedClassDef(threadData_t *threadData, modelica_metatype _inClassDef)
{
modelica_boolean _isDerived;
modelica_metatype out_isDerived;
_isDerived = omc_SCodeUtil_isDerivedClassDef(threadData, _inClassDef);
out_isDerived = mmc_mk_icon(_isDerived);
return out_isDerived;
}
DLLExport
modelica_metatype omc_SCodeUtil_setAttributesVariability(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fattributes, modelica_metatype _variability)
{
modelica_metatype _attributes = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_attributes = __omcQ_24in_5Fattributes;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_attributes), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = _variability;
_attributes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _attributes;
}
DLLExport
modelica_metatype omc_SCodeUtil_attrVariability(threadData_t *threadData, modelica_metatype _attr)
{
modelica_metatype _var = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_metatype _v = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_v = tmpMeta[1];
tmpMeta[0] = _v;
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
_var = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _var;
}
DLLExport
modelica_metatype omc_SCodeUtil_setAttributesDirection(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fattributes, modelica_metatype _direction)
{
modelica_metatype _attributes = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_attributes = __omcQ_24in_5Fattributes;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_attributes), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[6] = _direction;
_attributes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _attributes;
}
DLLExport
modelica_metatype omc_SCodeUtil_removeAttributeDimensions(threadData_t *threadData, modelica_metatype _inAttributes)
{
modelica_metatype _outAttributes = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _v = NULL;
modelica_metatype _p = NULL;
modelica_metatype _d = NULL;
modelica_metatype _isf = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inAttributes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
_ct = tmpMeta[1];
_p = tmpMeta[2];
_v = tmpMeta[3];
_d = tmpMeta[4];
_isf = tmpMeta[5];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, tmpMeta[0], _ct, _p, _v, _d, _isf);
_outAttributes = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outAttributes;
}
DLLExport
modelica_metatype omc_SCodeUtil_prefixesSetInnerOuter(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fprefixes, modelica_metatype _innerOuter)
{
modelica_metatype _prefixes = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_prefixes = __omcQ_24in_5Fprefixes;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_prefixes), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = _innerOuter;
_prefixes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _prefixes;
}
DLLExport
modelica_metatype omc_SCodeUtil_prefixesInnerOuter(threadData_t *threadData, modelica_metatype _inPrefixes)
{
modelica_metatype _outInnerOuter = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inPrefixes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_outInnerOuter = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outInnerOuter;
}
DLLExport
modelica_boolean omc_SCodeUtil_isElementRedeclare(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _isRedeclare;
modelica_metatype _pf = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_pf = omc_SCodeUtil_elementPrefixes(threadData, _inElement);
_isRedeclare = omc_SCodeUtil_redeclareBool(threadData, omc_SCodeUtil_prefixesRedeclare(threadData, _pf));
_return: OMC_LABEL_UNUSED
return _isRedeclare;
}
modelica_metatype boxptr_SCodeUtil_isElementRedeclare(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _isRedeclare;
modelica_metatype out_isRedeclare;
_isRedeclare = omc_SCodeUtil_isElementRedeclare(threadData, _inElement);
out_isRedeclare = mmc_mk_icon(_isRedeclare);
return out_isRedeclare;
}
DLLExport
modelica_boolean omc_SCodeUtil_isElementReplaceable(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _isReplaceable;
modelica_metatype _pf = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_pf = omc_SCodeUtil_elementPrefixes(threadData, _inElement);
_isReplaceable = omc_SCodeUtil_replaceableBool(threadData, omc_SCodeUtil_prefixesReplaceable(threadData, _pf));
_return: OMC_LABEL_UNUSED
return _isReplaceable;
}
modelica_metatype boxptr_SCodeUtil_isElementReplaceable(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _isReplaceable;
modelica_metatype out_isReplaceable;
_isReplaceable = omc_SCodeUtil_isElementReplaceable(threadData, _inElement);
out_isReplaceable = mmc_mk_icon(_isReplaceable);
return out_isReplaceable;
}
DLLExport
modelica_metatype omc_SCodeUtil_elementPrefixes(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outPrefixes = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_metatype _pf = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_pf = tmpMeta[1];
tmpMeta[0] = _pf;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_pf = tmpMeta[1];
tmpMeta[0] = _pf;
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
_outPrefixes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outPrefixes;
}
DLLExport
modelica_metatype omc_SCodeUtil_prefixesReplaceable(threadData_t *threadData, modelica_metatype _prefixes)
{
modelica_metatype _repl = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _prefixes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
_repl = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _repl;
}
DLLExport
modelica_boolean omc_SCodeUtil_prefixesEqual(threadData_t *threadData, modelica_metatype _prefixes1, modelica_metatype _prefixes2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _prefixes1;
tmp4_2 = _prefixes2;
{
modelica_metatype _v1 = NULL;
modelica_metatype _v2 = NULL;
modelica_metatype _rd1 = NULL;
modelica_metatype _rd2 = NULL;
modelica_metatype _f1 = NULL;
modelica_metatype _f2 = NULL;
modelica_metatype _io1 = NULL;
modelica_metatype _io2 = NULL;
modelica_metatype _rpl1 = NULL;
modelica_metatype _rpl2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
_v1 = tmpMeta[0];
_rd1 = tmpMeta[1];
_f1 = tmpMeta[2];
_io1 = tmpMeta[3];
_rpl1 = tmpMeta[4];
_v2 = tmpMeta[5];
_rd2 = tmpMeta[6];
_f2 = tmpMeta[7];
_io2 = tmpMeta[8];
_rpl2 = tmpMeta[9];
if (!((((valueEq(_v1, _v2) && valueEq(_rd1, _rd2)) && valueEq(_f1, _f2)) && omc_AbsynUtil_innerOuterEqual(threadData, _io1, _io2)) && omc_SCodeUtil_replaceableEqual(threadData, _rpl1, _rpl2))) goto tmp3_end;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_SCodeUtil_prefixesEqual(threadData_t *threadData, modelica_metatype _prefixes1, modelica_metatype _prefixes2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_prefixesEqual(threadData, _prefixes1, _prefixes2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_SCodeUtil_replaceableEqual(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _r1;
tmp4_2 = _r2;
{
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
modelica_metatype _m1 = NULL;
modelica_metatype _m2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmp4 += 2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (optionNone(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 1));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
_p1 = tmpMeta[2];
_m1 = tmpMeta[3];
_p2 = tmpMeta[6];
_m2 = tmpMeta[7];
tmp4 += 1;
tmp6 = omc_AbsynUtil_pathEqual(threadData, _p1, _p2);
if (1 != tmp6) goto goto_2;
tmp7 = omc_SCodeUtil_modEqual(threadData, _m1, _m2);
if (1 != tmp7) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!optionNone(tmpMeta[0])) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (!optionNone(tmpMeta[1])) goto tmp3_end;
tmp1 = 1;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_SCodeUtil_replaceableEqual(threadData_t *threadData, modelica_metatype _r1, modelica_metatype _r2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_replaceableEqual(threadData, _r1, _r2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_SCodeUtil_eachEqual(threadData_t *threadData, modelica_metatype _each1, modelica_metatype _each2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _each1;
tmp4_2 = _each2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_SCodeUtil_eachEqual(threadData_t *threadData, modelica_metatype _each1, modelica_metatype _each2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_eachEqual(threadData, _each1, _each2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_metatype omc_SCodeUtil_prefixesSetVisibility(threadData_t *threadData, modelica_metatype _inPrefixes, modelica_metatype _inVisibility)
{
modelica_metatype _outPrefixes = NULL;
modelica_metatype _rd = NULL;
modelica_metatype _f = NULL;
modelica_metatype _io = NULL;
modelica_metatype _rp = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inPrefixes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
_rd = tmpMeta[1];
_f = tmpMeta[2];
_io = tmpMeta[3];
_rp = tmpMeta[4];
tmpMeta[0] = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _inVisibility, _rd, _f, _io, _rp);
_outPrefixes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outPrefixes;
}
DLLExport
modelica_metatype omc_SCodeUtil_prefixesVisibility(threadData_t *threadData, modelica_metatype _inPrefixes)
{
modelica_metatype _outVisibility = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inPrefixes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_outVisibility = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outVisibility;
}
DLLExport
modelica_metatype omc_SCodeUtil_mergeAttributes(threadData_t *threadData, modelica_metatype _ele, modelica_metatype _oEle)
{
modelica_metatype _outoEle = NULL;
modelica_metatype tmpMeta[13] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _ele;
tmp3_2 = _oEle;
{
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
modelica_metatype _p = NULL;
modelica_metatype _v1 = NULL;
modelica_metatype _v2 = NULL;
modelica_metatype _v = NULL;
modelica_metatype _d1 = NULL;
modelica_metatype _d2 = NULL;
modelica_metatype _d = NULL;
modelica_metatype _isf1 = NULL;
modelica_metatype _isf2 = NULL;
modelica_metatype _isf = NULL;
modelica_metatype _ad1 = NULL;
modelica_metatype _ad = NULL;
modelica_metatype _ct1 = NULL;
modelica_metatype _ct2 = NULL;
modelica_metatype _ct = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[0] = mmc_mk_some(_ele);
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_ct2 = tmpMeta[2];
_p2 = tmpMeta[3];
_v2 = tmpMeta[4];
_d2 = tmpMeta[5];
_isf2 = tmpMeta[6];
_ad1 = tmpMeta[7];
_ct1 = tmpMeta[8];
_p1 = tmpMeta[9];
_v1 = tmpMeta[10];
_d1 = tmpMeta[11];
_isf1 = tmpMeta[12];
_ct = omc_SCodeUtil_propagateConnectorType(threadData, _ct1, _ct2);
_p = omc_SCodeUtil_propagateParallelism(threadData, _p1, _p2);
_v = omc_SCodeUtil_propagateVariability(threadData, _v1, _v2);
_d = omc_SCodeUtil_propagateDirection(threadData, _d1, _d2);
_isf = omc_SCodeUtil_propagateIsField(threadData, _isf1, _isf2);
_ad = _ad1;
tmpMeta[1] = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _ad, _ct, _p, _v, _d, _isf);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
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
_outoEle = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outoEle;
}
DLLExport
modelica_metatype omc_SCodeUtil_mergeAttributesFromClass(threadData_t *threadData, modelica_metatype _inAttributes, modelica_metatype _inClass)
{
modelica_metatype _outAttributes = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inClass;
{
modelica_metatype _cls_attr = NULL;
modelica_metatype _attr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_cls_attr = tmpMeta[2];
tmpMeta[1] = omc_SCodeUtil_mergeAttributes(threadData, _inAttributes, mmc_mk_some(_cls_attr));
if (optionNone(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_attr = tmpMeta[2];
tmpMeta[0] = _attr;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inAttributes;
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
_outAttributes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttributes;
}
DLLExport
modelica_metatype omc_SCodeUtil_boolStream(threadData_t *threadData, modelica_boolean _inBoolStream)
{
modelica_metatype _outStream = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStream = (_inBoolStream?_OMC_LIT31:_OMC_LIT32);
_return: OMC_LABEL_UNUSED
return _outStream;
}
modelica_metatype boxptr_SCodeUtil_boolStream(threadData_t *threadData, modelica_metatype _inBoolStream)
{
modelica_integer tmp1;
modelica_metatype _outStream = NULL;
tmp1 = mmc_unbox_integer(_inBoolStream);
_outStream = omc_SCodeUtil_boolStream(threadData, tmp1);
return _outStream;
}
DLLExport
modelica_boolean omc_SCodeUtil_streamBool(threadData_t *threadData, modelica_metatype _inStream)
{
modelica_boolean _bStream;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inStream;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
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
_bStream = tmp1;
_return: OMC_LABEL_UNUSED
return _bStream;
}
modelica_metatype boxptr_SCodeUtil_streamBool(threadData_t *threadData, modelica_metatype _inStream)
{
modelica_boolean _bStream;
modelica_metatype out_bStream;
_bStream = omc_SCodeUtil_streamBool(threadData, _inStream);
out_bStream = mmc_mk_icon(_bStream);
return out_bStream;
}
DLLExport
modelica_metatype omc_SCodeUtil_boolFlow(threadData_t *threadData, modelica_boolean _inBoolFlow)
{
modelica_metatype _outFlow = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outFlow = (_inBoolFlow?_OMC_LIT33:_OMC_LIT32);
_return: OMC_LABEL_UNUSED
return _outFlow;
}
modelica_metatype boxptr_SCodeUtil_boolFlow(threadData_t *threadData, modelica_metatype _inBoolFlow)
{
modelica_integer tmp1;
modelica_metatype _outFlow = NULL;
tmp1 = mmc_unbox_integer(_inBoolFlow);
_outFlow = omc_SCodeUtil_boolFlow(threadData, tmp1);
return _outFlow;
}
DLLExport
modelica_boolean omc_SCodeUtil_flowBool(threadData_t *threadData, modelica_metatype _inConnectorType)
{
modelica_boolean _outFlow;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inConnectorType;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
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
_outFlow = tmp1;
_return: OMC_LABEL_UNUSED
return _outFlow;
}
modelica_metatype boxptr_SCodeUtil_flowBool(threadData_t *threadData, modelica_metatype _inConnectorType)
{
modelica_boolean _outFlow;
modelica_metatype out_outFlow;
_outFlow = omc_SCodeUtil_flowBool(threadData, _inConnectorType);
out_outFlow = mmc_mk_icon(_outFlow);
return out_outFlow;
}
DLLExport
modelica_boolean omc_SCodeUtil_potentialBool(threadData_t *threadData, modelica_metatype _inConnectorType)
{
modelica_boolean _outPotential;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inConnectorType;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
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
_outPotential = tmp1;
_return: OMC_LABEL_UNUSED
return _outPotential;
}
modelica_metatype boxptr_SCodeUtil_potentialBool(threadData_t *threadData, modelica_metatype _inConnectorType)
{
modelica_boolean _outPotential;
modelica_metatype out_outPotential;
_outPotential = omc_SCodeUtil_potentialBool(threadData, _inConnectorType);
out_outPotential = mmc_mk_icon(_outPotential);
return out_outPotential;
}
DLLExport
modelica_boolean omc_SCodeUtil_connectorTypeEqual(threadData_t *threadData, modelica_metatype _inConnectorType1, modelica_metatype _inConnectorType2)
{
modelica_boolean _outEqual;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inConnectorType1;
tmp4_2 = _inConnectorType2;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
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
_outEqual = tmp1;
_return: OMC_LABEL_UNUSED
return _outEqual;
}
modelica_metatype boxptr_SCodeUtil_connectorTypeEqual(threadData_t *threadData, modelica_metatype _inConnectorType1, modelica_metatype _inConnectorType2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_SCodeUtil_connectorTypeEqual(threadData, _inConnectorType1, _inConnectorType2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
DLLExport
modelica_metatype omc_SCodeUtil_boolFinal(threadData_t *threadData, modelica_boolean _inBoolFinal)
{
modelica_metatype _outFinal = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outFinal = (_inBoolFinal?_OMC_LIT34:_OMC_LIT35);
_return: OMC_LABEL_UNUSED
return _outFinal;
}
modelica_metatype boxptr_SCodeUtil_boolFinal(threadData_t *threadData, modelica_metatype _inBoolFinal)
{
modelica_integer tmp1;
modelica_metatype _outFinal = NULL;
tmp1 = mmc_unbox_integer(_inBoolFinal);
_outFinal = omc_SCodeUtil_boolFinal(threadData, tmp1);
return _outFinal;
}
DLLExport
modelica_boolean omc_SCodeUtil_finalEqual(threadData_t *threadData, modelica_metatype _inFinal1, modelica_metatype _inFinal2)
{
modelica_boolean _bFinal;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inFinal1;
tmp4_2 = _inFinal2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
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
_bFinal = tmp1;
_return: OMC_LABEL_UNUSED
return _bFinal;
}
modelica_metatype boxptr_SCodeUtil_finalEqual(threadData_t *threadData, modelica_metatype _inFinal1, modelica_metatype _inFinal2)
{
modelica_boolean _bFinal;
modelica_metatype out_bFinal;
_bFinal = omc_SCodeUtil_finalEqual(threadData, _inFinal1, _inFinal2);
out_bFinal = mmc_mk_icon(_bFinal);
return out_bFinal;
}
DLLExport
modelica_boolean omc_SCodeUtil_finalBool(threadData_t *threadData, modelica_metatype _inFinal)
{
modelica_boolean _bFinal;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inFinal;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
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
_bFinal = tmp1;
_return: OMC_LABEL_UNUSED
return _bFinal;
}
modelica_metatype boxptr_SCodeUtil_finalBool(threadData_t *threadData, modelica_metatype _inFinal)
{
modelica_boolean _bFinal;
modelica_metatype out_bFinal;
_bFinal = omc_SCodeUtil_finalBool(threadData, _inFinal);
out_bFinal = mmc_mk_icon(_bFinal);
return out_bFinal;
}
DLLExport
modelica_metatype omc_SCodeUtil_prefixesFinal(threadData_t *threadData, modelica_metatype _inPrefixes)
{
modelica_metatype _outFinal = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inPrefixes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_outFinal = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outFinal;
}
DLLExport
modelica_metatype omc_SCodeUtil_boolPartial(threadData_t *threadData, modelica_boolean _inBoolPartial)
{
modelica_metatype _outPartial = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outPartial = (_inBoolPartial?_OMC_LIT36:_OMC_LIT37);
_return: OMC_LABEL_UNUSED
return _outPartial;
}
modelica_metatype boxptr_SCodeUtil_boolPartial(threadData_t *threadData, modelica_metatype _inBoolPartial)
{
modelica_integer tmp1;
modelica_metatype _outPartial = NULL;
tmp1 = mmc_unbox_integer(_inBoolPartial);
_outPartial = omc_SCodeUtil_boolPartial(threadData, tmp1);
return _outPartial;
}
DLLExport
modelica_boolean omc_SCodeUtil_partialBool(threadData_t *threadData, modelica_metatype _inPartial)
{
modelica_boolean _bPartial;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPartial;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
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
_bPartial = tmp1;
_return: OMC_LABEL_UNUSED
return _bPartial;
}
modelica_metatype boxptr_SCodeUtil_partialBool(threadData_t *threadData, modelica_metatype _inPartial)
{
modelica_boolean _bPartial;
modelica_metatype out_bPartial;
_bPartial = omc_SCodeUtil_partialBool(threadData, _inPartial);
out_bPartial = mmc_mk_icon(_bPartial);
return out_bPartial;
}
DLLExport
modelica_metatype omc_SCodeUtil_boolEncapsulated(threadData_t *threadData, modelica_boolean _inBoolEncapsulated)
{
modelica_metatype _outEncapsulated = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outEncapsulated = (_inBoolEncapsulated?_OMC_LIT38:_OMC_LIT39);
_return: OMC_LABEL_UNUSED
return _outEncapsulated;
}
modelica_metatype boxptr_SCodeUtil_boolEncapsulated(threadData_t *threadData, modelica_metatype _inBoolEncapsulated)
{
modelica_integer tmp1;
modelica_metatype _outEncapsulated = NULL;
tmp1 = mmc_unbox_integer(_inBoolEncapsulated);
_outEncapsulated = omc_SCodeUtil_boolEncapsulated(threadData, tmp1);
return _outEncapsulated;
}
DLLExport
modelica_boolean omc_SCodeUtil_encapsulatedBool(threadData_t *threadData, modelica_metatype _inEncapsulated)
{
modelica_boolean _bEncapsulated;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inEncapsulated;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
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
_bEncapsulated = tmp1;
_return: OMC_LABEL_UNUSED
return _bEncapsulated;
}
modelica_metatype boxptr_SCodeUtil_encapsulatedBool(threadData_t *threadData, modelica_metatype _inEncapsulated)
{
modelica_boolean _bEncapsulated;
modelica_metatype out_bEncapsulated;
_bEncapsulated = omc_SCodeUtil_encapsulatedBool(threadData, _inEncapsulated);
out_bEncapsulated = mmc_mk_icon(_bEncapsulated);
return out_bEncapsulated;
}
DLLExport
modelica_metatype omc_SCodeUtil_boolReplaceable(threadData_t *threadData, modelica_boolean _inBoolReplaceable, modelica_metatype _inOptConstrainClass)
{
modelica_metatype _outReplaceable = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inBoolReplaceable;
tmp3_2 = _inOptConstrainClass;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (1 != tmp3_1) goto tmp2_end;
tmpMeta[1] = mmc_mk_box2(3, &SCode_Replaceable_REPLACEABLE__desc, _inOptConstrainClass);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (0 != tmp3_1) goto tmp2_end;
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
fputs(MMC_STRINGDATA(_OMC_LIT40),stdout);
tmpMeta[0] = _OMC_LIT41;
goto tmp2_done;
}
case 2: {
if (0 != tmp3_1) goto tmp2_end;
tmpMeta[0] = _OMC_LIT41;
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
_outReplaceable = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outReplaceable;
}
modelica_metatype boxptr_SCodeUtil_boolReplaceable(threadData_t *threadData, modelica_metatype _inBoolReplaceable, modelica_metatype _inOptConstrainClass)
{
modelica_integer tmp1;
modelica_metatype _outReplaceable = NULL;
tmp1 = mmc_unbox_integer(_inBoolReplaceable);
_outReplaceable = omc_SCodeUtil_boolReplaceable(threadData, tmp1, _inOptConstrainClass);
return _outReplaceable;
}
DLLExport
modelica_metatype omc_SCodeUtil_replaceableOptConstraint(threadData_t *threadData, modelica_metatype _inReplaceable)
{
modelica_metatype _outOptConstrainClass = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inReplaceable;
{
modelica_metatype _cc = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_cc = tmpMeta[1];
tmpMeta[0] = _cc;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,0) == 0) goto tmp2_end;
tmpMeta[0] = mmc_mk_none();
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
_outOptConstrainClass = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outOptConstrainClass;
}
DLLExport
modelica_boolean omc_SCodeUtil_replaceableBool(threadData_t *threadData, modelica_metatype _inReplaceable)
{
modelica_boolean _bReplaceable;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inReplaceable;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
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
_bReplaceable = tmp1;
_return: OMC_LABEL_UNUSED
return _bReplaceable;
}
modelica_metatype boxptr_SCodeUtil_replaceableBool(threadData_t *threadData, modelica_metatype _inReplaceable)
{
modelica_boolean _bReplaceable;
modelica_metatype out_bReplaceable;
_bReplaceable = omc_SCodeUtil_replaceableBool(threadData, _inReplaceable);
out_bReplaceable = mmc_mk_icon(_bReplaceable);
return out_bReplaceable;
}
DLLExport
modelica_metatype omc_SCodeUtil_boolRedeclare(threadData_t *threadData, modelica_boolean _inBoolRedeclare)
{
modelica_metatype _outRedeclare = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outRedeclare = (_inBoolRedeclare?_OMC_LIT42:_OMC_LIT43);
_return: OMC_LABEL_UNUSED
return _outRedeclare;
}
modelica_metatype boxptr_SCodeUtil_boolRedeclare(threadData_t *threadData, modelica_metatype _inBoolRedeclare)
{
modelica_integer tmp1;
modelica_metatype _outRedeclare = NULL;
tmp1 = mmc_unbox_integer(_inBoolRedeclare);
_outRedeclare = omc_SCodeUtil_boolRedeclare(threadData, tmp1);
return _outRedeclare;
}
DLLExport
modelica_boolean omc_SCodeUtil_redeclareBool(threadData_t *threadData, modelica_metatype _inRedeclare)
{
modelica_boolean _bRedeclare;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRedeclare;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
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
_bRedeclare = tmp1;
_return: OMC_LABEL_UNUSED
return _bRedeclare;
}
modelica_metatype boxptr_SCodeUtil_redeclareBool(threadData_t *threadData, modelica_metatype _inRedeclare)
{
modelica_boolean _bRedeclare;
modelica_metatype out_bRedeclare;
_bRedeclare = omc_SCodeUtil_redeclareBool(threadData, _inRedeclare);
out_bRedeclare = mmc_mk_icon(_bRedeclare);
return out_bRedeclare;
}
DLLExport
modelica_metatype omc_SCodeUtil_prefixesSetReplaceable(threadData_t *threadData, modelica_metatype _inPrefixes, modelica_metatype _inReplaceable)
{
modelica_metatype _outPrefixes = NULL;
modelica_metatype _v = NULL;
modelica_metatype _f = NULL;
modelica_metatype _io = NULL;
modelica_metatype _rd = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inPrefixes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_v = tmpMeta[1];
_rd = tmpMeta[2];
_f = tmpMeta[3];
_io = tmpMeta[4];
tmpMeta[0] = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _v, _rd, _f, _io, _inReplaceable);
_outPrefixes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outPrefixes;
}
DLLExport
modelica_metatype omc_SCodeUtil_prefixesSetRedeclare(threadData_t *threadData, modelica_metatype _inPrefixes, modelica_metatype _inRedeclare)
{
modelica_metatype _outPrefixes = NULL;
modelica_metatype _v = NULL;
modelica_metatype _f = NULL;
modelica_metatype _io = NULL;
modelica_metatype _rp = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inPrefixes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
_v = tmpMeta[1];
_f = tmpMeta[2];
_io = tmpMeta[3];
_rp = tmpMeta[4];
tmpMeta[0] = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _v, _inRedeclare, _f, _io, _rp);
_outPrefixes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outPrefixes;
}
DLLExport
modelica_metatype omc_SCodeUtil_prefixesRedeclare(threadData_t *threadData, modelica_metatype _inPrefixes)
{
modelica_metatype _outRedeclare = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inPrefixes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_outRedeclare = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outRedeclare;
}
DLLExport
modelica_metatype omc_SCodeUtil_boolEach(threadData_t *threadData, modelica_boolean _inBoolEach)
{
modelica_metatype _outEach = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outEach = (_inBoolEach?_OMC_LIT44:_OMC_LIT45);
_return: OMC_LABEL_UNUSED
return _outEach;
}
modelica_metatype boxptr_SCodeUtil_boolEach(threadData_t *threadData, modelica_metatype _inBoolEach)
{
modelica_integer tmp1;
modelica_metatype _outEach = NULL;
tmp1 = mmc_unbox_integer(_inBoolEach);
_outEach = omc_SCodeUtil_boolEach(threadData, tmp1);
return _outEach;
}
DLLExport
modelica_boolean omc_SCodeUtil_eachBool(threadData_t *threadData, modelica_metatype _inEach)
{
modelica_boolean _bEach;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inEach;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
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
_bEach = tmp1;
_return: OMC_LABEL_UNUSED
return _bEach;
}
modelica_metatype boxptr_SCodeUtil_eachBool(threadData_t *threadData, modelica_metatype _inEach)
{
modelica_boolean _bEach;
modelica_metatype out_bEach;
_bEach = omc_SCodeUtil_eachBool(threadData, _inEach);
out_bEach = mmc_mk_icon(_bEach);
return out_bEach;
}
DLLExport
modelica_boolean omc_SCodeUtil_visibilityEqual(threadData_t *threadData, modelica_metatype _inVisibility1, modelica_metatype _inVisibility2)
{
modelica_boolean _outEqual;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inVisibility1;
tmp4_2 = _inVisibility2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
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
_outEqual = tmp1;
_return: OMC_LABEL_UNUSED
return _outEqual;
}
modelica_metatype boxptr_SCodeUtil_visibilityEqual(threadData_t *threadData, modelica_metatype _inVisibility1, modelica_metatype _inVisibility2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_SCodeUtil_visibilityEqual(threadData, _inVisibility1, _inVisibility2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
DLLExport
modelica_metatype omc_SCodeUtil_boolVisibility(threadData_t *threadData, modelica_boolean _inBoolVisibility)
{
modelica_metatype _outVisibility = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outVisibility = (_inBoolVisibility?_OMC_LIT46:_OMC_LIT23);
_return: OMC_LABEL_UNUSED
return _outVisibility;
}
modelica_metatype boxptr_SCodeUtil_boolVisibility(threadData_t *threadData, modelica_metatype _inBoolVisibility)
{
modelica_integer tmp1;
modelica_metatype _outVisibility = NULL;
tmp1 = mmc_unbox_integer(_inBoolVisibility);
_outVisibility = omc_SCodeUtil_boolVisibility(threadData, tmp1);
return _outVisibility;
}
DLLExport
modelica_boolean omc_SCodeUtil_visibilityBool(threadData_t *threadData, modelica_metatype _inVisibility)
{
modelica_boolean _bVisibility;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVisibility;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
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
_bVisibility = tmp1;
_return: OMC_LABEL_UNUSED
return _bVisibility;
}
modelica_metatype boxptr_SCodeUtil_visibilityBool(threadData_t *threadData, modelica_metatype _inVisibility)
{
modelica_boolean _bVisibility;
modelica_metatype out_bVisibility;
_bVisibility = omc_SCodeUtil_visibilityBool(threadData, _inVisibility);
out_bVisibility = mmc_mk_icon(_bVisibility);
return out_bVisibility;
}
DLLExport
modelica_metatype omc_SCodeUtil_setElementClassDefinition(threadData_t *threadData, modelica_metatype _inClassDef, modelica_metatype _inElement)
{
modelica_metatype _outElement = NULL;
modelica_string _n = NULL;
modelica_metatype _pf = NULL;
modelica_metatype _pp = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _r = NULL;
modelica_metatype _i = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inElement;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
_n = tmpMeta[1];
_pf = tmpMeta[2];
_ep = tmpMeta[3];
_pp = tmpMeta[4];
_r = tmpMeta[5];
_cmt = tmpMeta[6];
_i = tmpMeta[7];
tmpMeta[0] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _n, _pf, _ep, _pp, _r, _inClassDef, _cmt, _i);
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLExport
modelica_metatype omc_SCodeUtil_addElementToCompositeClassDef(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inClassDef)
{
modelica_metatype _outClassDef = NULL;
modelica_metatype _el = NULL;
modelica_metatype _nel = NULL;
modelica_metatype _iel = NULL;
modelica_metatype _nal = NULL;
modelica_metatype _ial = NULL;
modelica_metatype _nco = NULL;
modelica_metatype _ed = NULL;
modelica_metatype _clsattrs = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inClassDef;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
_el = tmpMeta[1];
_nel = tmpMeta[2];
_iel = tmpMeta[3];
_nal = tmpMeta[4];
_ial = tmpMeta[5];
_nco = tmpMeta[6];
_clsattrs = tmpMeta[7];
_ed = tmpMeta[8];
tmpMeta[0] = mmc_mk_cons(_inElement, _el);
tmpMeta[1] = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, tmpMeta[0], _nel, _iel, _nal, _ial, _nco, _clsattrs, _ed);
_outClassDef = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outClassDef;
}
DLLExport
modelica_metatype omc_SCodeUtil_addElementToClass(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inClassDef)
{
modelica_metatype _outClassDef = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inClassDef;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
_cdef = tmpMeta[1];
_cdef = omc_SCodeUtil_addElementToCompositeClassDef(threadData, _inElement, _cdef);
_outClassDef = omc_SCodeUtil_setElementClassDefinition(threadData, _cdef, _inClassDef);
_return: OMC_LABEL_UNUSED
return _outClassDef;
}
DLLExport
modelica_metatype omc_SCodeUtil_prependSubModToMod(threadData_t *threadData, modelica_metatype _subMod, modelica_metatype __omcQ_24in_5Fmod)
{
modelica_metatype _mod = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_mod = __omcQ_24in_5Fmod;
{
modelica_metatype tmp3_1;
tmp3_1 = _mod;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,0) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_cons(_subMod, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _OMC_LIT35, _OMC_LIT45, tmpMeta[1], mmc_mk_none(), _OMC_LIT26);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[2] = mmc_mk_cons(_subMod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 4))));
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_mod), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[4] = tmpMeta[2];
_mod = tmpMeta[1];
tmpMeta[0] = _mod;
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
_mod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _mod;
}
DLLExport
modelica_metatype omc_SCodeUtil_getStatementInfo(threadData_t *threadData, modelica_metatype _inStatement)
{
modelica_metatype _outInfo = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inStatement;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 5)));
goto tmp2_done;
}
case 4: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 7)));
goto tmp2_done;
}
case 5: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 6)));
goto tmp2_done;
}
case 6: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 6)));
goto tmp2_done;
}
case 7: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 5)));
goto tmp2_done;
}
case 8: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4)));
goto tmp2_done;
}
case 9: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 6)));
goto tmp2_done;
}
case 10: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4)));
goto tmp2_done;
}
case 11: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 5)));
goto tmp2_done;
}
case 12: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4)));
goto tmp2_done;
}
case 13: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3)));
goto tmp2_done;
}
case 14: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3)));
goto tmp2_done;
}
case 15: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4)));
goto tmp2_done;
}
case 16: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 5)));
goto tmp2_done;
}
case 17: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3)));
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
omc_Error_addInternalError(threadData, _OMC_LIT47, _OMC_LIT49);
tmpMeta[0] = _OMC_LIT26;
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
_outInfo = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outInfo;
}
DLLExport
modelica_metatype omc_SCodeUtil_getEEquationInfo(threadData_t *threadData, modelica_metatype _inEEquation)
{
modelica_metatype _outInfo = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inEEquation;
{
modelica_metatype _info = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,9,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_info = tmpMeta[1];
tmpMeta[0] = _info;
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
_outInfo = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outInfo;
}
DLLExport
modelica_string omc_SCodeUtil_isBuiltinFunction(threadData_t *threadData, modelica_metatype _cl, modelica_metatype _inVars, modelica_metatype _outVars)
{
modelica_string _name = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cl;
tmp4_2 = _outVars;
{
modelica_string _outVar1 = NULL;
modelica_string _outVar2 = NULL;
modelica_metatype _argsStr = NULL;
modelica_metatype _args = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],9,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,8) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 9));
if (optionNone(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 1));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (!optionNone(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
if (optionNone(tmpMeta[7])) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 1));
if (7 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT21), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp3_end;
_name = tmpMeta[0];
tmp1 = _name;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],9,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,8) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 9));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (optionNone(tmpMeta[7])) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 1));
if (7 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT21), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp3_end;
_name = tmpMeta[6];
tmp1 = _name;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],9,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,0) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,8) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 9));
if (optionNone(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 1));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (!optionNone(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
if (optionNone(tmpMeta[7])) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 1));
if (7 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT21), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp3_end;
_name = tmpMeta[0];
tmp1 = _name;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],9,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,0) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,8) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 9));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (optionNone(tmpMeta[7])) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 1));
if (7 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT21), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp3_end;
_name = tmpMeta[6];
tmp1 = _name;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp6;
modelica_boolean tmp7;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_2);
tmpMeta[1] = MMC_CDR(tmp4_2);
if (!listEmpty(tmpMeta[1])) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,8) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 9));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (optionNone(tmpMeta[7])) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 1));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
if (optionNone(tmpMeta[9])) goto tmp3_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 1));
if (1 != MMC_STRLEN(tmpMeta[10]) || strcmp(MMC_STRINGDATA(_OMC_LIT78), MMC_STRINGDATA(tmpMeta[10])) != 0) goto tmp3_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 4));
if (optionNone(tmpMeta[11])) goto tmp3_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[12],2,2) == 0) goto tmp3_end;
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 2));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 3));
if (!listEmpty(tmpMeta[14])) goto tmp3_end;
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 5));
_outVar1 = tmpMeta[0];
_name = tmpMeta[8];
_outVar2 = tmpMeta[13];
_args = tmpMeta[15];
tmp6 = listMember(_name, _OMC_LIT77);
if (1 != tmp6) goto goto_2;
tmp7 = (stringEqual(_outVar2, _outVar1));
if (1 != tmp7) goto goto_2;
_argsStr = omc_List_mapMap(threadData, _args, boxvar_AbsynUtil_expCref, boxvar_AbsynUtil_crefIdent);
equality(_argsStr, _inVars);
tmp1 = _name;
goto tmp3_done;
}
case 5: {
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],9,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,8) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 9));
if (optionNone(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 1));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (!optionNone(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
if (optionNone(tmpMeta[7])) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 1));
if (1 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT78), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp3_end;
_name = tmpMeta[0];
tmp8 = listMember(_name, _OMC_LIT77);
if (1 != tmp8) goto goto_2;
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
_name = tmp1;
_return: OMC_LABEL_UNUSED
return _name;
}
DLLExport
modelica_metatype omc_SCodeUtil_getElementClass(threadData_t *threadData, modelica_metatype _el)
{
modelica_metatype _cl = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _el;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[0] = _el;
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
_cl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _cl;
}
DLLExport
modelica_boolean omc_SCodeUtil_elementIsProtectedImport(threadData_t *threadData, modelica_metatype _el)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _el;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_elementIsProtectedImport(threadData_t *threadData, modelica_metatype _el)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_SCodeUtil_elementIsProtectedImport(threadData, _el);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_SCodeUtil_elementIsPublicImport(threadData_t *threadData, modelica_metatype _el)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _el;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_elementIsPublicImport(threadData_t *threadData, modelica_metatype _el)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_SCodeUtil_elementIsPublicImport(threadData, _el);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_SCodeUtil_elementIsImport(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsImport;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,3) == 0) goto tmp3_end;
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
_outIsImport = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsImport;
}
modelica_metatype boxptr_SCodeUtil_elementIsImport(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsImport;
modelica_metatype out_outIsImport;
_outIsImport = omc_SCodeUtil_elementIsImport(threadData, _inElement);
out_outIsImport = mmc_mk_icon(_outIsImport);
return out_outIsImport;
}
DLLExport
modelica_boolean omc_SCodeUtil_elementIsClass(threadData_t *threadData, modelica_metatype _el)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _el;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_elementIsClass(threadData_t *threadData, modelica_metatype _el)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_SCodeUtil_elementIsClass(threadData, _el);
out_b = mmc_mk_icon(_b);
return out_b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseBranchExps(threadData_t *threadData, modelica_metatype _inBranch, modelica_fnptr _traverser, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outBranch = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype _arg = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inBranch;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_exp = tmpMeta[1];
_stmts = tmpMeta[2];
_exp = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _exp, _inArg ,&_outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _exp, _inArg ,&_outArg);
tmpMeta[0] = mmc_mk_box2(0, _exp, _stmts);
_outBranch = tmpMeta[0];
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outBranch;
}
DLLExport
modelica_metatype omc_SCodeUtil_traverseStatementExps(threadData_t *threadData, modelica_metatype _inStatement, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outStatement = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_fnptr tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inStatement;
tmp4_2 = ((modelica_fnptr) _inFunc);
tmp4_3 = _inArg;
{
modelica_fnptr _traverser;
modelica_metatype _arg = NULL;
modelica_string _iterator = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _stmts1 = NULL;
modelica_metatype _stmts2 = NULL;
modelica_metatype _branches = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 11; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_comment = tmpMeta[4];
_info = tmpMeta[5];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e2, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box5(3, &SCode_Statement_ALG__ASSIGN__desc, _e1, _e2, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,6) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_e1 = tmpMeta[2];
_stmts1 = tmpMeta[3];
_branches = tmpMeta[4];
_stmts2 = tmpMeta[5];
_comment = tmpMeta[6];
_info = tmpMeta[7];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
_branches = omc_List_map1Fold(threadData, _branches, boxvar_SCodeUtil_traverseBranchExps, ((modelica_fnptr) _traverser), _arg ,&_arg);
tmpMeta[2] = mmc_mk_box7(4, &SCode_Statement_ALG__IF__desc, _e1, _stmts1, _branches, _stmts2, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_iterator = tmpMeta[2];
_e1 = tmpMeta[4];
_stmts1 = tmpMeta[5];
_comment = tmpMeta[6];
_info = tmpMeta[7];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box6(5, &SCode_Statement_ALG__FOR__desc, _iterator, mmc_mk_some(_e1), _stmts1, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_iterator = tmpMeta[2];
_e1 = tmpMeta[4];
_stmts1 = tmpMeta[5];
_comment = tmpMeta[6];
_info = tmpMeta[7];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box6(6, &SCode_Statement_ALG__PARFOR__desc, _iterator, mmc_mk_some(_e1), _stmts1, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta[2];
_stmts1 = tmpMeta[3];
_comment = tmpMeta[4];
_info = tmpMeta[5];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box5(7, &SCode_Statement_ALG__WHILE__desc, _e1, _stmts1, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_branches = tmpMeta[2];
_comment = tmpMeta[3];
_info = tmpMeta[4];
_traverser = tmp4_2;
_arg = tmp4_3;
_branches = omc_List_map1Fold(threadData, _branches, boxvar_SCodeUtil_traverseBranchExps, ((modelica_fnptr) _traverser), _arg ,&_arg);
tmpMeta[2] = mmc_mk_box4(8, &SCode_Statement_ALG__WHEN__A__desc, _branches, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,5) == 0) goto tmp3_end;
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _arg ,&_arg);
_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), _arg ,&_arg);
_e3 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4))), _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4))), _arg ,&_arg);
tmpMeta[2] = mmc_mk_box6(9, &SCode_Statement_ALG__ASSERT__desc, _e1, _e2, _e3, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 6))));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _arg ,&_arg);
tmpMeta[2] = mmc_mk_box4(10, &SCode_Statement_ALG__TERMINATE__desc, _e1, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4))));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,4) == 0) goto tmp3_end;
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _arg ,&_arg);
_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), _arg ,&_arg);
tmpMeta[2] = mmc_mk_box5(11, &SCode_Statement_ALG__REINIT__desc, _e1, _e2, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 5))));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta[2];
_comment = tmpMeta[3];
_info = tmpMeta[4];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box4(12, &SCode_Statement_ALG__NORETCALL__desc, _e1, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 10: {
tmpMeta[0+0] = _inStatement;
tmpMeta[0+1] = _inArg;
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
_outStatement = tmpMeta[0+0];
_outArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outStatement;
}
DLLExport
modelica_metatype omc_SCodeUtil_traverseStatementListExps(threadData_t *threadData, modelica_metatype _inStatements, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outStatements = NULL;
modelica_metatype _outArg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStatements = omc_List_map1Fold(threadData, _inStatements, boxvar_SCodeUtil_traverseStatementExps, ((modelica_fnptr) _inFunc), _inArg ,&_outArg);
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outStatements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseBranchStatements(threadData_t *threadData, modelica_metatype _inBranch, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outBranch = NULL;
modelica_metatype _outTuple = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inBranch;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_exp = tmpMeta[1];
_stmts = tmpMeta[2];
_stmts = omc_SCodeUtil_traverseStatementsList(threadData, _stmts, _inTuple ,&_outTuple);
tmpMeta[0] = mmc_mk_box2(0, _exp, _stmts);
_outBranch = tmpMeta[0];
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _outBranch;
}
DLLExport
modelica_metatype omc_SCodeUtil_traverseStatements2(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outStatement = NULL;
modelica_metatype _outTuple = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inStatement;
tmp4_2 = _inTuple;
{
modelica_metatype _tup = NULL;
modelica_metatype _e = NULL;
modelica_metatype _stmts1 = NULL;
modelica_metatype _stmts2 = NULL;
modelica_metatype _branches = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _info = NULL;
modelica_string _iter = NULL;
modelica_metatype _range = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,6) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_e = tmpMeta[2];
_stmts1 = tmpMeta[3];
_branches = tmpMeta[4];
_stmts2 = tmpMeta[5];
_comment = tmpMeta[6];
_info = tmpMeta[7];
_tup = tmp4_2;
_stmts1 = omc_SCodeUtil_traverseStatementsList(threadData, _stmts1, _tup ,&_tup);
_branches = omc_List_mapFold(threadData, _branches, boxvar_SCodeUtil_traverseBranchStatements, _tup ,&_tup);
_stmts2 = omc_SCodeUtil_traverseStatementsList(threadData, _stmts2, _tup ,&_tup);
tmpMeta[2] = mmc_mk_box7(4, &SCode_Statement_ALG__IF__desc, _e, _stmts1, _branches, _stmts2, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _tup;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_iter = tmpMeta[2];
_range = tmpMeta[3];
_stmts1 = tmpMeta[4];
_comment = tmpMeta[5];
_info = tmpMeta[6];
_tup = tmp4_2;
_stmts1 = omc_SCodeUtil_traverseStatementsList(threadData, _stmts1, _tup ,&_tup);
tmpMeta[2] = mmc_mk_box6(5, &SCode_Statement_ALG__FOR__desc, _iter, _range, _stmts1, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _tup;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_iter = tmpMeta[2];
_range = tmpMeta[3];
_stmts1 = tmpMeta[4];
_comment = tmpMeta[5];
_info = tmpMeta[6];
_tup = tmp4_2;
_stmts1 = omc_SCodeUtil_traverseStatementsList(threadData, _stmts1, _tup ,&_tup);
tmpMeta[2] = mmc_mk_box6(6, &SCode_Statement_ALG__PARFOR__desc, _iter, _range, _stmts1, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _tup;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e = tmpMeta[2];
_stmts1 = tmpMeta[3];
_comment = tmpMeta[4];
_info = tmpMeta[5];
_tup = tmp4_2;
_stmts1 = omc_SCodeUtil_traverseStatementsList(threadData, _stmts1, _tup ,&_tup);
tmpMeta[2] = mmc_mk_box5(7, &SCode_Statement_ALG__WHILE__desc, _e, _stmts1, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _tup;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_branches = tmpMeta[2];
_comment = tmpMeta[3];
_info = tmpMeta[4];
_tup = tmp4_2;
_branches = omc_List_mapFold(threadData, _branches, boxvar_SCodeUtil_traverseBranchStatements, _tup ,&_tup);
tmpMeta[2] = mmc_mk_box4(8, &SCode_Statement_ALG__WHEN__A__desc, _branches, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _tup;
goto tmp3_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_stmts1 = tmpMeta[2];
_comment = tmpMeta[3];
_info = tmpMeta[4];
_tup = tmp4_2;
_stmts1 = omc_SCodeUtil_traverseStatementsList(threadData, _stmts1, _tup ,&_tup);
tmpMeta[2] = mmc_mk_box4(15, &SCode_Statement_ALG__FAILURE__desc, _stmts1, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _tup;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta[0+0] = _inStatement;
tmpMeta[0+1] = _inTuple;
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
_outStatement = tmpMeta[0+0];
_outTuple = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _outStatement;
}
DLLExport
modelica_metatype omc_SCodeUtil_traverseStatements(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outStatement = NULL;
modelica_metatype _outTuple = NULL;
modelica_fnptr _traverser;
modelica_metatype _arg = NULL;
modelica_metatype _stmt = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inTuple;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_traverser = tmpMeta[1];
_arg = tmpMeta[2];
tmpMeta[0] = mmc_mk_box2(0, _inStatement, _arg);
tmpMeta[1] = mmc_mk_box2(0, _inStatement, _arg);
tmpMeta[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), tmpMeta[1]) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, tmpMeta[0]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_stmt = tmpMeta[3];
_arg = tmpMeta[4];
tmpMeta[0] = mmc_mk_box2(0, ((modelica_fnptr) _traverser), _arg);
_outStatement = omc_SCodeUtil_traverseStatements2(threadData, _stmt, tmpMeta[0] ,&_outTuple);
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _outStatement;
}
DLLExport
modelica_metatype omc_SCodeUtil_traverseStatementsList(threadData_t *threadData, modelica_metatype _inStatements, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outStatements = NULL;
modelica_metatype _outTuple = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStatements = omc_List_mapFold(threadData, _inStatements, boxvar_SCodeUtil_traverseStatements, _inTuple ,&_outTuple);
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _outStatements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseForIteratorExps(threadData_t *threadData, modelica_metatype _inIterator, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outIterator = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_fnptr tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inIterator;
tmp4_2 = ((modelica_fnptr) _inFunc);
tmp4_3 = _inArg;
{
modelica_fnptr _traverser;
modelica_metatype _arg = NULL;
modelica_string _ident = NULL;
modelica_metatype _guardExp = NULL;
modelica_metatype _range = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta[4])) goto tmp3_end;
_ident = tmpMeta[2];
_arg = tmp4_3;
tmpMeta[2] = mmc_mk_box4(3, &Absyn_ForIterator_ITERATOR__desc, _ident, mmc_mk_none(), mmc_mk_none());
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 1: {
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 1));
_ident = tmpMeta[2];
_range = tmpMeta[5];
_traverser = tmp4_2;
_arg = tmp4_3;
_range = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _range, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _range, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box4(3, &Absyn_ForIterator_ITERATOR__desc, _ident, mmc_mk_none(), mmc_mk_some(_range));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 2: {
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
_ident = tmpMeta[2];
_guardExp = tmpMeta[4];
_range = tmpMeta[6];
_traverser = tmp4_2;
_arg = tmp4_3;
_guardExp = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _guardExp, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _guardExp, _arg ,&_arg);
_range = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _range, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _range, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box4(3, &Absyn_ForIterator_ITERATOR__desc, _ident, mmc_mk_some(_guardExp), mmc_mk_some(_range));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 3: {
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta[5])) goto tmp3_end;
_ident = tmpMeta[2];
_guardExp = tmpMeta[4];
_traverser = tmp4_2;
_arg = tmp4_3;
_guardExp = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _guardExp, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _guardExp, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box4(3, &Absyn_ForIterator_ITERATOR__desc, _ident, mmc_mk_some(_guardExp), mmc_mk_none());
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
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
_outIterator = tmpMeta[0+0];
_outArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outIterator;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseNamedArgExps(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outArg = NULL;
modelica_metatype _outTuple = NULL;
modelica_fnptr _traverser;
modelica_metatype _arg = NULL;
modelica_string _name = NULL;
modelica_metatype _value = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inTuple;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_traverser = tmpMeta[1];
_arg = tmpMeta[2];
tmpMeta[0] = _inArg;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_name = tmpMeta[1];
_value = tmpMeta[2];
_value = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _value, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _value, _arg ,&_arg);
tmpMeta[0] = mmc_mk_box3(3, &Absyn_NamedArg_NAMEDARG__desc, _name, _value);
_outArg = tmpMeta[0];
tmpMeta[0] = mmc_mk_box2(0, ((modelica_fnptr) _traverser), _arg);
_outTuple = tmpMeta[0];
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _outArg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseElseWhenExps(threadData_t *threadData, modelica_metatype _inElseWhen, modelica_fnptr _traverser, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outElseWhen = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _eql = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inElseWhen;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_exp = tmpMeta[1];
_eql = tmpMeta[2];
_exp = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _exp, _inArg ,&_outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _exp, _inArg ,&_outArg);
tmpMeta[0] = mmc_mk_box2(0, _exp, _eql);
_outElseWhen = tmpMeta[0];
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outElseWhen;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseSubscriptExps(threadData_t *threadData, modelica_metatype _inSubscript, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outSubscript = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_fnptr tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inSubscript;
tmp4_2 = ((modelica_fnptr) _inFunc);
tmp4_3 = _inArg;
{
modelica_metatype _sub_exp = NULL;
modelica_fnptr _traverser;
modelica_metatype _arg = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_sub_exp = tmpMeta[2];
_traverser = tmp4_2;
_arg = tmp4_3;
_sub_exp = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _sub_exp, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _sub_exp, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box2(4, &Absyn_Subscript_SUBSCRIPT__desc, _sub_exp);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmpMeta[0+0] = _inSubscript;
tmpMeta[0+1] = _inArg;
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
_outSubscript = tmpMeta[0+0];
_outArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outSubscript;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseComponentRefExps(threadData_t *threadData, modelica_metatype _inCref, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outCref = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _name = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _arg = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cr = tmpMeta[2];
_cr = omc_SCodeUtil_traverseComponentRefExps(threadData, _cr, ((modelica_fnptr) _inFunc), _inArg ,&_arg);
tmpMeta[0+0] = omc_AbsynUtil_crefMakeFullyQualified(threadData, _cr);
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_name = tmpMeta[2];
_subs = tmpMeta[3];
_cr = tmpMeta[4];
_cr = omc_SCodeUtil_traverseComponentRefExps(threadData, _cr, ((modelica_fnptr) _inFunc), _inArg ,&_arg);
_subs = omc_List_map1Fold(threadData, _subs, boxvar_SCodeUtil_traverseSubscriptExps, ((modelica_fnptr) _inFunc), _arg ,&_arg);
tmpMeta[2] = mmc_mk_box4(4, &Absyn_ComponentRef_CREF__QUAL__desc, _name, _subs, _cr);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_name = tmpMeta[2];
_subs = tmpMeta[3];
_subs = omc_List_map1Fold(threadData, _subs, boxvar_SCodeUtil_traverseSubscriptExps, ((modelica_fnptr) _inFunc), _inArg ,&_arg);
tmpMeta[2] = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _name, _subs);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 6: {
tmpMeta[0+0] = _inCref;
tmpMeta[0+1] = _inArg;
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
_outCref = tmpMeta[0+0];
_outArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outCref;
}
DLLExport
modelica_metatype omc_SCodeUtil_traverseEEquationExps(threadData_t *threadData, modelica_metatype _inEEquation, modelica_fnptr _inFunc, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outEEquation = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_fnptr tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inEEquation;
tmp4_2 = ((modelica_fnptr) _inFunc);
tmp4_3 = _inArg;
{
modelica_fnptr _traverser;
modelica_metatype _arg = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _expl1 = NULL;
modelica_metatype _then_branch = NULL;
modelica_metatype _else_branch = NULL;
modelica_metatype _eql = NULL;
modelica_metatype _else_when = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _info = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _domain = NULL;
modelica_string _index = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 11; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_expl1 = tmpMeta[2];
_then_branch = tmpMeta[3];
_else_branch = tmpMeta[4];
_comment = tmpMeta[5];
_info = tmpMeta[6];
_traverser = tmp4_2;
_arg = tmp4_3;
_expl1 = omc_AbsynUtil_traverseExpList(threadData, _expl1, ((modelica_fnptr) _traverser), _arg ,&_arg);
tmpMeta[2] = mmc_mk_box6(3, &SCode_EEquation_EQ__IF__desc, _expl1, _then_branch, _else_branch, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_comment = tmpMeta[4];
_info = tmpMeta[5];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e2, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box5(4, &SCode_EEquation_EQ__EQUALS__desc, _e1, _e2, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_domain = tmpMeta[4];
_comment = tmpMeta[5];
_info = tmpMeta[6];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e2, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box6(5, &SCode_EEquation_EQ__PDE__desc, _e1, _e2, _domain, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_cr1 = tmpMeta[2];
_cr2 = tmpMeta[3];
_comment = tmpMeta[4];
_info = tmpMeta[5];
_cr1 = omc_SCodeUtil_traverseComponentRefExps(threadData, _cr1, ((modelica_fnptr) _inFunc), _inArg ,&_arg);
_cr2 = omc_SCodeUtil_traverseComponentRefExps(threadData, _cr2, ((modelica_fnptr) _inFunc), _arg ,&_arg);
tmpMeta[2] = mmc_mk_box5(6, &SCode_EEquation_EQ__CONNECT__desc, _cr1, _cr2, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_index = tmpMeta[2];
_e1 = tmpMeta[4];
_eql = tmpMeta[5];
_comment = tmpMeta[6];
_info = tmpMeta[7];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box6(7, &SCode_EEquation_EQ__FOR__desc, _index, mmc_mk_some(_e1), _eql, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_e1 = tmpMeta[2];
_eql = tmpMeta[3];
_else_when = tmpMeta[4];
_comment = tmpMeta[5];
_info = tmpMeta[6];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
_else_when = omc_List_map1Fold(threadData, _else_when, boxvar_SCodeUtil_traverseElseWhenExps, ((modelica_fnptr) _traverser), _arg ,&_arg);
tmpMeta[2] = mmc_mk_box6(8, &SCode_EEquation_EQ__WHEN__desc, _e1, _eql, _else_when, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_e3 = tmpMeta[4];
_comment = tmpMeta[5];
_info = tmpMeta[6];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e2, _arg ,&_arg);
_e3 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e3, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e3, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box6(9, &SCode_EEquation_EQ__ASSERT__desc, _e1, _e2, _e3, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta[2];
_comment = tmpMeta[3];
_info = tmpMeta[4];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box4(10, &SCode_EEquation_EQ__TERMINATE__desc, _e1, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_comment = tmpMeta[4];
_info = tmpMeta[5];
_traverser = tmp4_2;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _inArg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _inArg ,&_arg);
_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e2, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box5(11, &SCode_EEquation_EQ__REINIT__desc, _e1, _e2, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta[2];
_comment = tmpMeta[3];
_info = tmpMeta[4];
_traverser = tmp4_2;
_arg = tmp4_3;
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, _e1, _arg ,&_arg);
tmpMeta[2] = mmc_mk_box4(12, &SCode_EEquation_EQ__NORETCALL__desc, _e1, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 10: {
tmpMeta[0+0] = _inEEquation;
tmpMeta[0+1] = _inArg;
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
_outEEquation = tmpMeta[0+0];
_outArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outEEquation;
}
DLLExport
modelica_metatype omc_SCodeUtil_traverseEEquationListExps(threadData_t *threadData, modelica_metatype _inEEquations, modelica_fnptr _traverser, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outEEquations = NULL;
modelica_metatype _outArg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outEEquations = omc_List_map1Fold(threadData, _inEEquations, boxvar_SCodeUtil_traverseEEquationExps, ((modelica_fnptr) _traverser), _inArg ,&_outArg);
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outEEquations;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_traverseElseWhenEEquations(threadData_t *threadData, modelica_metatype _inElseWhen, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outElseWhen = NULL;
modelica_metatype _outTuple = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _eql = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inElseWhen;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_exp = tmpMeta[1];
_eql = tmpMeta[2];
_eql = omc_SCodeUtil_traverseEEquationsList(threadData, _eql, _inTuple ,&_outTuple);
tmpMeta[0] = mmc_mk_box2(0, _exp, _eql);
_outElseWhen = tmpMeta[0];
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _outElseWhen;
}
DLLExport
modelica_metatype omc_SCodeUtil_traverseEEquations2(threadData_t *threadData, modelica_metatype _inEEquation, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outEEquation = NULL;
modelica_metatype _outTuple = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inEEquation;
tmp4_2 = _inTuple;
{
modelica_metatype _tup = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _oe1 = NULL;
modelica_metatype _expl1 = NULL;
modelica_metatype _then_branch = NULL;
modelica_metatype _else_branch = NULL;
modelica_metatype _eql = NULL;
modelica_metatype _else_when = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _info = NULL;
modelica_string _index = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_expl1 = tmpMeta[2];
_then_branch = tmpMeta[3];
_else_branch = tmpMeta[4];
_comment = tmpMeta[5];
_info = tmpMeta[6];
_tup = tmp4_2;
_then_branch = omc_List_mapFold(threadData, _then_branch, boxvar_SCodeUtil_traverseEEquationsList, _tup ,&_tup);
_else_branch = omc_SCodeUtil_traverseEEquationsList(threadData, _else_branch, _tup ,&_tup);
tmpMeta[2] = mmc_mk_box6(3, &SCode_EEquation_EQ__IF__desc, _expl1, _then_branch, _else_branch, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _tup;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_index = tmpMeta[2];
_oe1 = tmpMeta[3];
_eql = tmpMeta[4];
_comment = tmpMeta[5];
_info = tmpMeta[6];
_tup = tmp4_2;
_eql = omc_SCodeUtil_traverseEEquationsList(threadData, _eql, _tup ,&_tup);
tmpMeta[2] = mmc_mk_box6(7, &SCode_EEquation_EQ__FOR__desc, _index, _oe1, _eql, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _tup;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_e1 = tmpMeta[2];
_eql = tmpMeta[3];
_else_when = tmpMeta[4];
_comment = tmpMeta[5];
_info = tmpMeta[6];
_tup = tmp4_2;
_eql = omc_SCodeUtil_traverseEEquationsList(threadData, _eql, _tup ,&_tup);
_else_when = omc_List_mapFold(threadData, _else_when, boxvar_SCodeUtil_traverseElseWhenEEquations, _tup ,&_tup);
tmpMeta[2] = mmc_mk_box6(8, &SCode_EEquation_EQ__WHEN__desc, _e1, _eql, _else_when, _comment, _info);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _tup;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta[0+0] = _inEEquation;
tmpMeta[0+1] = _inTuple;
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
_outEEquation = tmpMeta[0+0];
_outTuple = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _outEEquation;
}
DLLExport
modelica_metatype omc_SCodeUtil_traverseEEquations(threadData_t *threadData, modelica_metatype _inEEquation, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outEEquation = NULL;
modelica_metatype _outTuple = NULL;
modelica_fnptr _traverser;
modelica_metatype _arg = NULL;
modelica_metatype _eq = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inTuple;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_traverser = tmpMeta[1];
_arg = tmpMeta[2];
tmpMeta[0] = mmc_mk_box2(0, _inEEquation, _arg);
tmpMeta[1] = mmc_mk_box2(0, _inEEquation, _arg);
tmpMeta[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 2))), tmpMeta[1]) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_traverser), 1)))) (threadData, tmpMeta[0]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_eq = tmpMeta[3];
_arg = tmpMeta[4];
tmpMeta[0] = mmc_mk_box2(0, ((modelica_fnptr) _traverser), _arg);
_outEEquation = omc_SCodeUtil_traverseEEquations2(threadData, _eq, tmpMeta[0] ,&_outTuple);
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _outEEquation;
}
DLLExport
modelica_metatype omc_SCodeUtil_traverseEEquationsList(threadData_t *threadData, modelica_metatype _inEEquations, modelica_metatype _inTuple, modelica_metatype *out_outTuple)
{
modelica_metatype _outEEquations = NULL;
modelica_metatype _outTuple = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outEEquations = omc_List_mapFold(threadData, _inEEquations, boxvar_SCodeUtil_traverseEEquations, _inTuple ,&_outTuple);
_return: OMC_LABEL_UNUSED
if (out_outTuple) { *out_outTuple = _outTuple; }
return _outEEquations;
}
DLLExport
modelica_metatype omc_SCodeUtil_foldStatementsExps(threadData_t *threadData, modelica_metatype _inStatement, modelica_fnptr _inFunc, modelica_metatype _inArg)
{
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArg = _inArg;
{
modelica_metatype tmp3_1;
tmp3_1 = _inStatement;
{
modelica_metatype _exp = NULL;
modelica_metatype _stmts = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg);
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), _outArg);
goto tmp2_done;
}
case 4: {
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg);
_outArg = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), boxvar_SCodeUtil_foldStatementsExps, ((modelica_fnptr) _inFunc), _outArg);
{
modelica_metatype _branch;
for (tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4))); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_branch = MMC_CAR(tmpMeta[1]);
tmpMeta[2] = _branch;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_exp = tmpMeta[3];
_stmts = tmpMeta[4];
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _exp, _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _exp, _outArg);
_outArg = omc_List_fold1(threadData, _stmts, boxvar_SCodeUtil_foldStatementsExps, ((modelica_fnptr) _inFunc), _outArg);
}
}
tmpMeta[0] = _outArg;
goto tmp2_done;
}
case 5: {
if(isSome((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3)))))
{
tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3)));
if (optionNone(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_exp = tmpMeta[2];
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _exp, _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _exp, _outArg);
}
tmpMeta[0] = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4))), boxvar_SCodeUtil_foldStatementsExps, ((modelica_fnptr) _inFunc), _outArg);
goto tmp2_done;
}
case 6: {
if(isSome((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3)))))
{
tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3)));
if (optionNone(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_exp = tmpMeta[2];
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _exp, _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _exp, _outArg);
}
tmpMeta[0] = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4))), boxvar_SCodeUtil_foldStatementsExps, ((modelica_fnptr) _inFunc), _outArg);
goto tmp2_done;
}
case 7: {
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg);
tmpMeta[0] = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), boxvar_SCodeUtil_foldStatementsExps, ((modelica_fnptr) _inFunc), _outArg);
goto tmp2_done;
}
case 8: {
{
modelica_metatype _branch;
for (tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_branch = MMC_CAR(tmpMeta[1]);
tmpMeta[2] = _branch;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_exp = tmpMeta[3];
_stmts = tmpMeta[4];
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _exp, _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _exp, _outArg);
_outArg = omc_List_fold1(threadData, _stmts, boxvar_SCodeUtil_foldStatementsExps, ((modelica_fnptr) _inFunc), _outArg);
}
}
tmpMeta[0] = _outArg;
goto tmp2_done;
}
case 9: {
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg);
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), _outArg);
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 4))), _outArg);
goto tmp2_done;
}
case 10: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg);
goto tmp2_done;
}
case 11: {
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg);
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), _outArg);
goto tmp2_done;
}
case 12: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), _outArg);
goto tmp2_done;
}
case 15: {
tmpMeta[0] = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), boxvar_SCodeUtil_foldStatementsExps, ((modelica_fnptr) _inFunc), _outArg);
goto tmp2_done;
}
case 16: {
_outArg = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 2))), boxvar_SCodeUtil_foldStatementsExps, ((modelica_fnptr) _inFunc), _outArg);
tmpMeta[0] = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inStatement), 3))), boxvar_SCodeUtil_foldStatementsExps, ((modelica_fnptr) _inFunc), _outArg);
goto tmp2_done;
}
case 13: {
tmpMeta[0] = _outArg;
goto tmp2_done;
}
case 14: {
tmpMeta[0] = _outArg;
goto tmp2_done;
}
case 17: {
tmpMeta[0] = _outArg;
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
_outArg = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outArg;
}
DLLExport
modelica_metatype omc_SCodeUtil_foldEEquationsExps(threadData_t *threadData, modelica_metatype _inEquation, modelica_fnptr _inFunc, modelica_metatype _inArg)
{
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArg = _inArg;
{
modelica_metatype tmp3_1;
tmp3_1 = _inEquation;
{
modelica_metatype _exp = NULL;
modelica_metatype _eql = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
_outArg = omc_List_fold(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), ((modelica_fnptr) _inFunc), _outArg);
_outArg = omc_List_foldList1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), boxvar_SCodeUtil_foldEEquationsExps, ((modelica_fnptr) _inFunc), _outArg);
tmpMeta[0] = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))), boxvar_SCodeUtil_foldEEquationsExps, ((modelica_fnptr) _inFunc), _outArg);
goto tmp2_done;
}
case 4: {
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _outArg);
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _outArg);
goto tmp2_done;
}
case 5: {
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _outArg);
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _outArg);
goto tmp2_done;
}
case 6: {
tmpMeta[1] = mmc_mk_box2(5, &Absyn_Exp_CREF__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))));
tmpMeta[2] = mmc_mk_box2(5, &Absyn_Exp_CREF__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))));
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), tmpMeta[2], _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, tmpMeta[1], _outArg);
tmpMeta[1] = mmc_mk_box2(5, &Absyn_Exp_CREF__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))));
tmpMeta[2] = mmc_mk_box2(5, &Absyn_Exp_CREF__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))));
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), tmpMeta[2], _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, tmpMeta[1], _outArg);
goto tmp2_done;
}
case 7: {
if(isSome((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3)))))
{
tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3)));
if (optionNone(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_exp = tmpMeta[2];
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _exp, _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _exp, _outArg);
}
tmpMeta[0] = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))), boxvar_SCodeUtil_foldEEquationsExps, ((modelica_fnptr) _inFunc), _outArg);
goto tmp2_done;
}
case 8: {
_outArg = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), boxvar_SCodeUtil_foldEEquationsExps, ((modelica_fnptr) _inFunc), _outArg);
{
modelica_metatype _branch;
for (tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_branch = MMC_CAR(tmpMeta[1]);
tmpMeta[2] = _branch;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_exp = tmpMeta[3];
_eql = tmpMeta[4];
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _exp, _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _exp, _outArg);
_outArg = omc_List_fold1(threadData, _eql, boxvar_SCodeUtil_foldEEquationsExps, ((modelica_fnptr) _inFunc), _outArg);
}
}
tmpMeta[0] = _outArg;
goto tmp2_done;
}
case 9: {
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _outArg);
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _outArg);
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))), _outArg);
goto tmp2_done;
}
case 10: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _outArg);
goto tmp2_done;
}
case 11: {
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _outArg);
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _outArg);
goto tmp2_done;
}
case 12: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _outArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _outArg);
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
_outArg = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outArg;
}
DLLExport
modelica_metatype omc_SCodeUtil_foldEEquations(threadData_t *threadData, modelica_metatype _inEquation, modelica_fnptr _inFunc, modelica_metatype _inArg)
{
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outArg = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 2))), _inEquation, _inArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inFunc), 1)))) (threadData, _inEquation, _inArg);
{
modelica_metatype tmp3_1;
tmp3_1 = _inEquation;
{
modelica_metatype _eql = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
_outArg = omc_List_foldList1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), boxvar_SCodeUtil_foldEEquations, ((modelica_fnptr) _inFunc), _outArg);
tmpMeta[0] = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))), boxvar_SCodeUtil_foldEEquations, ((modelica_fnptr) _inFunc), _outArg);
goto tmp2_done;
}
case 7: {
tmpMeta[0] = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))), boxvar_SCodeUtil_foldEEquations, ((modelica_fnptr) _inFunc), _outArg);
goto tmp2_done;
}
case 8: {
_outArg = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), boxvar_SCodeUtil_foldEEquations, ((modelica_fnptr) _inFunc), _outArg);
{
modelica_metatype _branch;
for (tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_branch = MMC_CAR(tmpMeta[1]);
tmpMeta[2] = _branch;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_eql = tmpMeta[3];
_outArg = omc_List_fold1(threadData, _eql, boxvar_SCodeUtil_foldEEquations, ((modelica_fnptr) _inFunc), _outArg);
}
}
tmpMeta[0] = _outArg;
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
_outArg = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outArg;
}
DLLExport
modelica_boolean omc_SCodeUtil_isClass(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsClass;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
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
_outIsClass = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsClass;
}
modelica_metatype boxptr_SCodeUtil_isClass(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsClass;
modelica_metatype out_outIsClass;
_outIsClass = omc_SCodeUtil_isClass(threadData, _inElement);
out_outIsClass = mmc_mk_icon(_outIsClass);
return out_outIsClass;
}
DLLExport
modelica_boolean omc_SCodeUtil_isClassOrComponent(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsClassOrComponent;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
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
_outIsClassOrComponent = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsClassOrComponent;
}
modelica_metatype boxptr_SCodeUtil_isClassOrComponent(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outIsClassOrComponent;
modelica_metatype out_outIsClassOrComponent;
_outIsClassOrComponent = omc_SCodeUtil_isClassOrComponent(threadData, _inElement);
out_outIsClassOrComponent = mmc_mk_icon(_outIsClassOrComponent);
return out_outIsClassOrComponent;
}
DLLExport
modelica_boolean omc_SCodeUtil_isNotComponent(threadData_t *threadData, modelica_metatype _elt)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _elt;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_SCodeUtil_isNotComponent(threadData_t *threadData, modelica_metatype _elt)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_SCodeUtil_isNotComponent(threadData, _elt);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_SCodeUtil_isComponent(threadData_t *threadData, modelica_metatype _elt)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _elt;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_isComponent(threadData_t *threadData, modelica_metatype _elt)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_SCodeUtil_isComponent(threadData, _elt);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_SCodeUtil_isComponentWithDirection(threadData_t *threadData, modelica_metatype _elt, modelica_metatype _dir1)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _elt;
{
modelica_metatype _dir2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
_dir2 = tmpMeta[1];
tmp1 = omc_AbsynUtil_directionEqual(threadData, _dir1, _dir2);
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
modelica_metatype boxptr_SCodeUtil_isComponentWithDirection(threadData_t *threadData, modelica_metatype _elt, modelica_metatype _dir1)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_SCodeUtil_isComponentWithDirection(threadData, _elt, _dir1);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_SCodeUtil_emptyModOrEquality(threadData_t *threadData, modelica_metatype _mod)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _mod;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta[0])) goto tmp3_end;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_SCodeUtil_emptyModOrEquality(threadData_t *threadData, modelica_metatype _mod)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_SCodeUtil_emptyModOrEquality(threadData, _mod);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_SCodeUtil_equationFileInfo(threadData_t *threadData, modelica_metatype _eq)
{
modelica_metatype _info = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _eq;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_info = tmpMeta[1];
tmpMeta[0] = _info;
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,9,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_info = tmpMeta[1];
tmpMeta[0] = _info;
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
_info = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _info;
}
DLLExport
modelica_metatype omc_SCodeUtil_statementToAlgorithmItem(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_metatype _algi = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _stmt;
{
modelica_metatype _functionCall = NULL;
modelica_metatype _assignComponent = NULL;
modelica_metatype _boolExpr = NULL;
modelica_metatype _value = NULL;
modelica_string _iterator = NULL;
modelica_metatype _range = NULL;
modelica_metatype _functionArgs = NULL;
modelica_metatype _info = NULL;
modelica_metatype _conditions = NULL;
modelica_metatype _stmtsList = NULL;
modelica_metatype _body = NULL;
modelica_metatype _trueBranch = NULL;
modelica_metatype _elseBranch = NULL;
modelica_metatype _branches = NULL;
modelica_metatype _algs1 = NULL;
modelica_metatype _algs2 = NULL;
modelica_metatype _algsLst = NULL;
modelica_metatype _abranches = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_assignComponent = tmpMeta[1];
_value = tmpMeta[2];
_info = tmpMeta[3];
tmpMeta[1] = mmc_mk_box3(3, &Absyn_Algorithm_ALG__ASSIGN__desc, _assignComponent, _value);
tmpMeta[2] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, tmpMeta[1], mmc_mk_none(), _info);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,6) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_boolExpr = tmpMeta[1];
_trueBranch = tmpMeta[2];
_branches = tmpMeta[3];
_elseBranch = tmpMeta[4];
_info = tmpMeta[5];
_algs1 = omc_List_map(threadData, _trueBranch, boxvar_SCodeUtil_statementToAlgorithmItem);
_conditions = omc_List_map(threadData, _branches, boxvar_Util_tuple21);
_stmtsList = omc_List_map(threadData, _branches, boxvar_Util_tuple22);
_algsLst = omc_List_mapList(threadData, _stmtsList, boxvar_SCodeUtil_statementToAlgorithmItem);
_abranches = omc_List_zip(threadData, _conditions, _algsLst);
_algs2 = omc_List_map(threadData, _elseBranch, boxvar_SCodeUtil_statementToAlgorithmItem);
tmpMeta[1] = mmc_mk_box5(4, &Absyn_Algorithm_ALG__IF__desc, _boolExpr, _algs1, _abranches, _algs2);
tmpMeta[2] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, tmpMeta[1], mmc_mk_none(), _info);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_iterator = tmpMeta[1];
_range = tmpMeta[2];
_body = tmpMeta[3];
_info = tmpMeta[4];
_algs1 = omc_List_map(threadData, _body, boxvar_SCodeUtil_statementToAlgorithmItem);
tmpMeta[2] = mmc_mk_box4(3, &Absyn_ForIterator_ITERATOR__desc, _iterator, mmc_mk_none(), _range);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box3(5, &Absyn_Algorithm_ALG__FOR__desc, tmpMeta[1], _algs1);
tmpMeta[4] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, tmpMeta[3], mmc_mk_none(), _info);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_iterator = tmpMeta[1];
_range = tmpMeta[2];
_body = tmpMeta[3];
_info = tmpMeta[4];
_algs1 = omc_List_map(threadData, _body, boxvar_SCodeUtil_statementToAlgorithmItem);
tmpMeta[2] = mmc_mk_box4(3, &Absyn_ForIterator_ITERATOR__desc, _iterator, mmc_mk_none(), _range);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box3(6, &Absyn_Algorithm_ALG__PARFOR__desc, tmpMeta[1], _algs1);
tmpMeta[4] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, tmpMeta[3], mmc_mk_none(), _info);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_boolExpr = tmpMeta[1];
_body = tmpMeta[2];
_info = tmpMeta[3];
_algs1 = omc_List_map(threadData, _body, boxvar_SCodeUtil_statementToAlgorithmItem);
tmpMeta[1] = mmc_mk_box3(7, &Absyn_Algorithm_ALG__WHILE__desc, _boolExpr, _algs1);
tmpMeta[2] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, tmpMeta[1], mmc_mk_none(), _info);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_branches = tmpMeta[1];
_info = tmpMeta[2];
tmpMeta[1] = omc_List_map(threadData, _branches, boxvar_Util_tuple21);
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_boolExpr = tmpMeta[2];
_conditions = tmpMeta[3];
_stmtsList = omc_List_map(threadData, _branches, boxvar_Util_tuple22);
tmpMeta[1] = omc_List_mapList(threadData, _stmtsList, boxvar_SCodeUtil_statementToAlgorithmItem);
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_algs1 = tmpMeta[2];
_algsLst = tmpMeta[3];
_abranches = omc_List_zip(threadData, _conditions, _algsLst);
tmpMeta[1] = mmc_mk_box4(8, &Absyn_Algorithm_ALG__WHEN__A__desc, _boolExpr, _algs1, _abranches);
tmpMeta[2] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, tmpMeta[1], mmc_mk_none(), _info);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 9: {
tmpMeta[1] = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 2))), mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3))), mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4))), MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = mmc_mk_box3(3, &Absyn_FunctionArgs_FUNCTIONARGS__desc, tmpMeta[1], tmpMeta[2]);
tmpMeta[4] = mmc_mk_box3(9, &Absyn_Algorithm_ALG__NORETCALL__desc, _OMC_LIT80, tmpMeta[3]);
tmpMeta[5] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, tmpMeta[4], mmc_mk_none(), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 6))));
tmpMeta[0] = tmpMeta[5];
goto tmp2_done;
}
case 10: {
tmpMeta[1] = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 2))), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = mmc_mk_box3(3, &Absyn_FunctionArgs_FUNCTIONARGS__desc, tmpMeta[1], tmpMeta[2]);
tmpMeta[4] = mmc_mk_box3(9, &Absyn_Algorithm_ALG__NORETCALL__desc, _OMC_LIT82, tmpMeta[3]);
tmpMeta[5] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, tmpMeta[4], mmc_mk_none(), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 4))));
tmpMeta[0] = tmpMeta[5];
goto tmp2_done;
}
case 11: {
tmpMeta[1] = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 2))), mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 3))), MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = mmc_mk_box3(3, &Absyn_FunctionArgs_FUNCTIONARGS__desc, tmpMeta[1], tmpMeta[2]);
tmpMeta[4] = mmc_mk_box3(9, &Absyn_Algorithm_ALG__NORETCALL__desc, _OMC_LIT84, tmpMeta[3]);
tmpMeta[5] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, tmpMeta[4], mmc_mk_none(), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_stmt), 5))));
tmpMeta[0] = tmpMeta[5];
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,9,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],11,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_functionCall = tmpMeta[2];
_functionArgs = tmpMeta[3];
_info = tmpMeta[4];
tmpMeta[1] = mmc_mk_box3(9, &Absyn_Algorithm_ALG__NORETCALL__desc, _functionCall, _functionArgs);
tmpMeta[2] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, tmpMeta[1], mmc_mk_none(), _info);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_info = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, _OMC_LIT85, mmc_mk_none(), _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,11,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_info = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, _OMC_LIT86, mmc_mk_none(), _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,14,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_info = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, _OMC_LIT87, mmc_mk_none(), _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,12,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_body = tmpMeta[1];
_info = tmpMeta[2];
_algs1 = omc_List_map(threadData, _body, boxvar_SCodeUtil_statementToAlgorithmItem);
tmpMeta[1] = mmc_mk_box2(12, &Absyn_Algorithm_ALG__FAILURE__desc, _algs1);
tmpMeta[2] = mmc_mk_box4(3, &Absyn_AlgorithmItem_ALGORITHMITEM__desc, tmpMeta[1], mmc_mk_none(), _info);
tmpMeta[0] = tmpMeta[2];
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
_algi = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _algi;
}
DLLExport
modelica_metatype omc_SCodeUtil_variabilityOr(threadData_t *threadData, modelica_metatype _inConst1, modelica_metatype _inConst2)
{
modelica_metatype _outConst = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inConst1;
tmp3_2 = _inConst2;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 7; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT88;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,3,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT88;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT89;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT89;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT90;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT90;
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _OMC_LIT91;
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
_outConst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outConst;
}
DLLExport
modelica_metatype omc_SCodeUtil_makeEnumType(threadData_t *threadData, modelica_metatype _inEnum, modelica_metatype _inInfo)
{
modelica_metatype _outEnumType = NULL;
modelica_string _literal = NULL;
modelica_metatype _comment = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inEnum;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_literal = tmpMeta[1];
_comment = tmpMeta[2];
omc_SCodeUtil_checkValidEnumLiteral(threadData, _literal, _inInfo);
tmpMeta[0] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _literal, _OMC_LIT93, _OMC_LIT97, _OMC_LIT100, _OMC_LIT15, _comment, mmc_mk_none(), _inInfo);
_outEnumType = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outEnumType;
}
DLLExport
modelica_metatype omc_SCodeUtil_getClassElements(threadData_t *threadData, modelica_metatype _cl)
{
modelica_metatype _elts = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _cl;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,8) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_elts = tmpMeta[2];
tmpMeta[0] = _elts;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_elts = tmpMeta[3];
tmpMeta[0] = _elts;
goto tmp2_done;
}
case 2: {
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
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
_elts = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _elts;
}
DLLExport
modelica_metatype omc_SCodeUtil_getClassComponents(threadData_t *threadData, modelica_metatype _cl, modelica_metatype *out_compNames)
{
modelica_metatype _compElts = NULL;
modelica_metatype _compNames = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cl;
{
modelica_metatype _elts = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,8) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_elts = tmpMeta[3];
tmpMeta[0+0] = omc_SCodeUtil_filterComponents(threadData, _elts, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,8) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_elts = tmpMeta[4];
tmpMeta[0+0] = omc_SCodeUtil_filterComponents(threadData, _elts, &tmpMeta[0+1]);
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
_compElts = tmpMeta[0+0];
_compNames = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_compNames) { *out_compNames = _compNames; }
return _compElts;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_filterComponents2(threadData_t *threadData, modelica_metatype _inElement, modelica_string *out_outName)
{
modelica_metatype _outComponent = NULL;
modelica_string _outName = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inElement;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_outName = tmpMeta[1];
_outComponent = _inElement;
_return: OMC_LABEL_UNUSED
if (out_outName) { *out_outName = _outName; }
return _outComponent;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_filterComponents(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype *out_outComponentNames)
{
modelica_metatype _outComponents = NULL;
modelica_metatype _outComponentNames = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outComponents = omc_List_map__2(threadData, _inElements, boxvar_SCodeUtil_filterComponents2 ,&_outComponentNames);
_return: OMC_LABEL_UNUSED
if (out_outComponentNames) { *out_outComponentNames = _outComponentNames; }
return _outComponents;
}
static modelica_metatype closure0_AbsynUtil_findIteratorIndexedCrefs(threadData_t *thData, modelica_metatype closure, modelica_metatype inExp, modelica_metatype inCrefs)
{
modelica_string inIterator = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_findIteratorIndexedCrefs(thData, inExp, inIterator, inCrefs);
}
DLLExport
modelica_metatype omc_SCodeUtil_findIteratorIndexedCrefsInStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_string _inIterator, modelica_metatype _inCrefs)
{
modelica_metatype _outCrefs = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box1(0, _inIterator);
_outCrefs = omc_SCodeUtil_foldStatementsExps(threadData, _inStatement, (modelica_fnptr) mmc_mk_box2(0,closure0_AbsynUtil_findIteratorIndexedCrefs,tmpMeta[0]), _inCrefs);
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
DLLExport
modelica_metatype omc_SCodeUtil_findIteratorIndexedCrefsInStatements(threadData_t *threadData, modelica_metatype _inStatements, modelica_string _inIterator, modelica_metatype _inCrefs)
{
modelica_metatype _outCrefs = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCrefs = omc_List_fold1(threadData, _inStatements, boxvar_SCodeUtil_findIteratorIndexedCrefsInStatement, _inIterator, _inCrefs);
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
static modelica_metatype closure1_AbsynUtil_findIteratorIndexedCrefs(threadData_t *thData, modelica_metatype closure, modelica_metatype inExp, modelica_metatype inCrefs)
{
modelica_string inIterator = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_AbsynUtil_findIteratorIndexedCrefs(thData, inExp, inIterator, inCrefs);
}
DLLExport
modelica_metatype omc_SCodeUtil_findIteratorIndexedCrefsInEEquation(threadData_t *threadData, modelica_metatype _inEq, modelica_string _inIterator, modelica_metatype _inCrefs)
{
modelica_metatype _outCrefs = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box1(0, _inIterator);
_outCrefs = omc_SCodeUtil_foldEEquationsExps(threadData, _inEq, (modelica_fnptr) mmc_mk_box2(0,closure1_AbsynUtil_findIteratorIndexedCrefs,tmpMeta[0]), _inCrefs);
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
DLLExport
modelica_metatype omc_SCodeUtil_findIteratorIndexedCrefsInEEquations(threadData_t *threadData, modelica_metatype _inEqs, modelica_string _inIterator, modelica_metatype _inCrefs)
{
modelica_metatype _outCrefs = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCrefs = omc_List_fold1(threadData, _inEqs, boxvar_SCodeUtil_findIteratorIndexedCrefsInEEquation, _inIterator, _inCrefs);
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
DLLExport
modelica_metatype omc_SCodeUtil_setClassPartialPrefix(threadData_t *threadData, modelica_metatype _partialPrefix, modelica_metatype _cl)
{
modelica_metatype _outCl = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _cl;
{
modelica_metatype _parts = NULL;
modelica_metatype _e = NULL;
modelica_string _id = NULL;
modelica_metatype _info = NULL;
modelica_metatype _restriction = NULL;
modelica_metatype _prefixes = NULL;
modelica_metatype _oldPartialPrefix = NULL;
modelica_metatype _cmt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_oldPartialPrefix = tmpMeta[1];
tmp5 = valueEq(_partialPrefix, _oldPartialPrefix);
if (1 != tmp5) goto goto_1;
tmpMeta[0] = _cl;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_id = tmpMeta[1];
_prefixes = tmpMeta[2];
_e = tmpMeta[3];
_restriction = tmpMeta[4];
_parts = tmpMeta[5];
_cmt = tmpMeta[6];
_info = tmpMeta[7];
tmpMeta[1] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _id, _prefixes, _e, _partialPrefix, _restriction, _parts, _cmt, _info);
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
_outCl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outCl;
}
DLLExport
modelica_metatype omc_SCodeUtil_makeClassPartial(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClass = _inClass;
{
modelica_metatype tmp3_1;
tmp3_1 = _outClass;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,0) == 0) goto tmp2_end;
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(10));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_outClass), 10*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[5] = _OMC_LIT36;
_outClass = tmpMeta[1];
tmpMeta[0] = _outClass;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _outClass;
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
_outClass = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outClass;
}
DLLExport
modelica_metatype omc_SCodeUtil_setClassName(threadData_t *threadData, modelica_string _name, modelica_metatype _cl)
{
modelica_metatype _outCl = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _cl;
{
modelica_metatype _parts = NULL;
modelica_metatype _p = NULL;
modelica_metatype _e = NULL;
modelica_metatype _info = NULL;
modelica_metatype _prefixes = NULL;
modelica_metatype _r = NULL;
modelica_string _id = NULL;
modelica_metatype _cmt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_id = tmpMeta[1];
tmp5 = (stringEqual(_name, _id));
if (1 != tmp5) goto goto_1;
tmpMeta[0] = _cl;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_prefixes = tmpMeta[1];
_e = tmpMeta[2];
_p = tmpMeta[3];
_r = tmpMeta[4];
_parts = tmpMeta[5];
_cmt = tmpMeta[6];
_info = tmpMeta[7];
tmpMeta[1] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _name, _prefixes, _e, _p, _r, _parts, _cmt, _info);
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
_outCl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outCl;
}
DLLExport
modelica_metatype omc_SCodeUtil_setClassRestriction(threadData_t *threadData, modelica_metatype _r, modelica_metatype _cl)
{
modelica_metatype _outCl = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _cl;
{
modelica_metatype _parts = NULL;
modelica_metatype _p = NULL;
modelica_metatype _e = NULL;
modelica_string _id = NULL;
modelica_metatype _info = NULL;
modelica_metatype _prefixes = NULL;
modelica_metatype _oldR = NULL;
modelica_metatype _cmt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_oldR = tmpMeta[1];
tmp5 = omc_SCodeUtil_restrictionEqual(threadData, _r, _oldR);
if (1 != tmp5) goto goto_1;
tmpMeta[0] = _cl;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_id = tmpMeta[1];
_prefixes = tmpMeta[2];
_e = tmpMeta[3];
_p = tmpMeta[4];
_parts = tmpMeta[5];
_cmt = tmpMeta[6];
_info = tmpMeta[7];
tmpMeta[1] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _id, _prefixes, _e, _p, _r, _parts, _cmt, _info);
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
_outCl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outCl;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_arrayDimEqual(threadData_t *threadData, modelica_metatype _iad1, modelica_metatype _iad2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _iad1;
tmp4_2 = _iad2;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _ad1 = NULL;
modelica_metatype _ad2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp4 += 2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,0) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_2);
tmpMeta[3] = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,0) == 0) goto tmp3_end;
_ad1 = tmpMeta[1];
_ad2 = tmpMeta[3];
tmp4 += 1;
tmp6 = omc_SCodeUtil_arrayDimEqual(threadData, _ad1, _ad2);
if (1 != tmp6) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp7;
modelica_boolean tmp8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[3] = MMC_CAR(tmp4_2);
tmpMeta[4] = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_e1 = tmpMeta[2];
_ad1 = tmpMeta[1];
_e2 = tmpMeta[5];
_ad2 = tmpMeta[4];
tmp7 = omc_AbsynUtil_expEqual(threadData, _e1, _e2);
if (1 != tmp7) goto goto_2;
tmp8 = omc_SCodeUtil_arrayDimEqual(threadData, _ad1, _ad2);
if (1 != tmp8) goto goto_2;
tmp1 = 1;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_arrayDimEqual(threadData_t *threadData, modelica_metatype _iad1, modelica_metatype _iad2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_arrayDimEqual(threadData, _iad1, _iad2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_SCodeUtil_variabilityEqual(threadData_t *threadData, modelica_metatype _var1, modelica_metatype _var2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _var1;
tmp4_2 = _var2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,0) == 0) goto tmp3_end;
tmp1 = 1;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_SCodeUtil_variabilityEqual(threadData_t *threadData, modelica_metatype _var1, modelica_metatype _var2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_variabilityEqual(threadData, _var1, _var2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_SCodeUtil_parallelismEqual(threadData_t *threadData, modelica_metatype _prl1, modelica_metatype _prl2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _prl1;
tmp4_2 = _prl2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmp1 = 1;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_SCodeUtil_parallelismEqual(threadData_t *threadData, modelica_metatype _prl1, modelica_metatype _prl2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_parallelismEqual(threadData, _prl1, _prl2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_SCodeUtil_attributesEqual(threadData_t *threadData, modelica_metatype _attr1, modelica_metatype _attr2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[12] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _attr1;
tmp4_2 = _attr2;
{
modelica_metatype _prl1 = NULL;
modelica_metatype _prl2 = NULL;
modelica_metatype _var1 = NULL;
modelica_metatype _var2 = NULL;
modelica_metatype _ct1 = NULL;
modelica_metatype _ct2 = NULL;
modelica_metatype _ad1 = NULL;
modelica_metatype _ad2 = NULL;
modelica_metatype _dir1 = NULL;
modelica_metatype _dir2 = NULL;
modelica_metatype _if1 = NULL;
modelica_metatype _if2 = NULL;
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
modelica_boolean tmp7;
modelica_boolean tmp8;
modelica_boolean tmp9;
modelica_boolean tmp10;
modelica_boolean tmp11;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
_ad1 = tmpMeta[0];
_ct1 = tmpMeta[1];
_prl1 = tmpMeta[2];
_var1 = tmpMeta[3];
_dir1 = tmpMeta[4];
_if1 = tmpMeta[5];
_ad2 = tmpMeta[6];
_ct2 = tmpMeta[7];
_prl2 = tmpMeta[8];
_var2 = tmpMeta[9];
_dir2 = tmpMeta[10];
_if2 = tmpMeta[11];
tmp6 = omc_SCodeUtil_arrayDimEqual(threadData, _ad1, _ad2);
if (1 != tmp6) goto goto_2;
tmp7 = valueEq(_ct1, _ct2);
if (1 != tmp7) goto goto_2;
tmp8 = omc_SCodeUtil_parallelismEqual(threadData, _prl1, _prl2);
if (1 != tmp8) goto goto_2;
tmp9 = omc_SCodeUtil_variabilityEqual(threadData, _var1, _var2);
if (1 != tmp9) goto goto_2;
tmp10 = omc_AbsynUtil_directionEqual(threadData, _dir1, _dir2);
if (1 != tmp10) goto goto_2;
tmp11 = omc_AbsynUtil_isFieldEqual(threadData, _if1, _if2);
if (1 != tmp11) goto goto_2;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_SCodeUtil_attributesEqual(threadData_t *threadData, modelica_metatype _attr1, modelica_metatype _attr2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_attributesEqual(threadData, _attr1, _attr2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_subscriptsEqual(threadData_t *threadData, modelica_metatype _inSs1, modelica_metatype _inSs2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inSs1;
tmp4_2 = _inSs2;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _ss1 = NULL;
modelica_metatype _ss2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp4 += 2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,0) == 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_2);
tmpMeta[3] = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,0) == 0) goto tmp3_end;
_ss1 = tmpMeta[1];
_ss2 = tmpMeta[3];
tmp4 += 1;
tmp1 = omc_SCodeUtil_subscriptsEqual(threadData, _ss1, _ss2);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp6;
modelica_boolean tmp7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[3] = MMC_CAR(tmp4_2);
tmpMeta[4] = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_e1 = tmpMeta[2];
_ss1 = tmpMeta[1];
_e2 = tmpMeta[5];
_ss2 = tmpMeta[4];
tmp6 = omc_AbsynUtil_expEqual(threadData, _e1, _e2);
if (1 != tmp6) goto goto_2;
tmp7 = omc_SCodeUtil_subscriptsEqual(threadData, _ss1, _ss2);
if (1 != tmp7) goto goto_2;
tmp1 = 1;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_subscriptsEqual(threadData_t *threadData, modelica_metatype _inSs1, modelica_metatype _inSs2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_subscriptsEqual(threadData, _inSs1, _inSs2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_subModsEqual(threadData_t *threadData, modelica_metatype _inSubModLst1, modelica_metatype _inSubModLst2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inSubModLst1;
tmp4_2 = _inSubModLst2;
{
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
modelica_metatype _mod1 = NULL;
modelica_metatype _mod2 = NULL;
modelica_metatype _subModLst1 = NULL;
modelica_metatype _subModLst2 = NULL;
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
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp4 += 1;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
modelica_boolean tmp7;
modelica_boolean tmp8;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[4] = MMC_CAR(tmp4_2);
tmpMeta[5] = MMC_CDR(tmp4_2);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
_id1 = tmpMeta[2];
_mod1 = tmpMeta[3];
_subModLst1 = tmpMeta[1];
_id2 = tmpMeta[6];
_mod2 = tmpMeta[7];
_subModLst2 = tmpMeta[5];
tmp6 = (stringEqual(_id1, _id2));
if (1 != tmp6) goto goto_2;
tmp7 = omc_SCodeUtil_modEqual(threadData, _mod1, _mod2);
if (1 != tmp7) goto goto_2;
tmp8 = omc_SCodeUtil_subModsEqual(threadData, _subModLst1, _subModLst2);
if (1 != tmp8) goto goto_2;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_subModsEqual(threadData_t *threadData, modelica_metatype _inSubModLst1, modelica_metatype _inSubModLst2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_subModsEqual(threadData, _inSubModLst1, _inSubModLst2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_SCodeUtil_modEqual(threadData_t *threadData, modelica_metatype _mod1, modelica_metatype _mod2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _mod1;
tmp4_2 = _mod2;
{
modelica_metatype _f1 = NULL;
modelica_metatype _f2 = NULL;
modelica_metatype _each1 = NULL;
modelica_metatype _each2 = NULL;
modelica_metatype _submodlst1 = NULL;
modelica_metatype _submodlst2 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _elt1 = NULL;
modelica_metatype _elt2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
modelica_boolean tmp7;
modelica_boolean tmp8;
modelica_boolean tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,5) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (optionNone(tmpMeta[8])) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 1));
_f1 = tmpMeta[0];
_each1 = tmpMeta[1];
_submodlst1 = tmpMeta[2];
_e1 = tmpMeta[4];
_f2 = tmpMeta[5];
_each2 = tmpMeta[6];
_submodlst2 = tmpMeta[7];
_e2 = tmpMeta[9];
tmp4 += 3;
tmp6 = valueEq(_f1, _f2);
if (1 != tmp6) goto goto_2;
tmp7 = omc_SCodeUtil_eachEqual(threadData, _each1, _each2);
if (1 != tmp7) goto goto_2;
tmp8 = omc_SCodeUtil_subModsEqual(threadData, _submodlst1, _submodlst2);
if (1 != tmp8) goto goto_2;
tmp9 = omc_AbsynUtil_expEqual(threadData, _e1, _e2);
if (1 != tmp9) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp10;
modelica_boolean tmp11;
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (!optionNone(tmpMeta[3])) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,5) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
if (!optionNone(tmpMeta[7])) goto tmp3_end;
_f1 = tmpMeta[0];
_each1 = tmpMeta[1];
_submodlst1 = tmpMeta[2];
_f2 = tmpMeta[4];
_each2 = tmpMeta[5];
_submodlst2 = tmpMeta[6];
tmp4 += 2;
tmp10 = valueEq(_f1, _f2);
if (1 != tmp10) goto goto_2;
tmp11 = omc_SCodeUtil_eachEqual(threadData, _each1, _each2);
if (1 != tmp11) goto goto_2;
tmp12 = omc_SCodeUtil_subModsEqual(threadData, _submodlst1, _submodlst2);
if (1 != tmp12) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmp4 += 1;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp13;
modelica_boolean tmp14;
modelica_boolean tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_f1 = tmpMeta[0];
_each1 = tmpMeta[1];
_elt1 = tmpMeta[2];
_f2 = tmpMeta[3];
_each2 = tmpMeta[4];
_elt2 = tmpMeta[5];
tmp13 = valueEq(_f1, _f2);
if (1 != tmp13) goto goto_2;
tmp14 = omc_SCodeUtil_eachEqual(threadData, _each1, _each2);
if (1 != tmp14) goto goto_2;
tmp15 = omc_SCodeUtil_elementEqual(threadData, _elt1, _elt2);
if (1 != tmp15) goto goto_2;
tmp1 = 1;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_SCodeUtil_modEqual(threadData_t *threadData, modelica_metatype _mod1, modelica_metatype _mod2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_modEqual(threadData, _mod1, _mod2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_equationEqual22(threadData_t *threadData, modelica_metatype _inTb1, modelica_metatype _inTb2)
{
modelica_boolean _bOut;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inTb1;
tmp4_2 = _inTb2;
{
modelica_metatype _tb_1 = NULL;
modelica_metatype _tb_2 = NULL;
modelica_metatype _tb1 = NULL;
modelica_metatype _tb2 = NULL;
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
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 2: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 2;
tmp1 = 0;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp6;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_2);
tmpMeta[3] = MMC_CDR(tmp4_2);
_tb_1 = tmpMeta[0];
_tb1 = tmpMeta[1];
_tb_2 = tmpMeta[2];
_tb2 = tmpMeta[3];
omc_List_threadMapAllValue(threadData, _tb_1, _tb_2, boxvar_SCodeUtil_equationEqual2, mmc_mk_boolean(1));
tmp6 = omc_SCodeUtil_equationEqual22(threadData, _tb1, _tb2);
if (1 != tmp6) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_2);
tmpMeta[3] = MMC_CDR(tmp4_2);
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
_bOut = tmp1;
_return: OMC_LABEL_UNUSED
return _bOut;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_equationEqual22(threadData_t *threadData, modelica_metatype _inTb1, modelica_metatype _inTb2)
{
modelica_boolean _bOut;
modelica_metatype out_bOut;
_bOut = omc_SCodeUtil_equationEqual22(threadData, _inTb1, _inTb2);
out_bOut = mmc_mk_icon(_bOut);
return out_bOut;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_equationEqual2(threadData_t *threadData, modelica_metatype _eq1, modelica_metatype _eq2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _eq1;
tmp4_2 = _eq2;
{
modelica_metatype _tb1 = NULL;
modelica_metatype _tb2 = NULL;
modelica_metatype _cond1 = NULL;
modelica_metatype _cond2 = NULL;
modelica_metatype _ifcond1 = NULL;
modelica_metatype _ifcond2 = NULL;
modelica_metatype _e11 = NULL;
modelica_metatype _e12 = NULL;
modelica_metatype _e21 = NULL;
modelica_metatype _e22 = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
modelica_metatype _m1 = NULL;
modelica_metatype _m2 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _cr11 = NULL;
modelica_metatype _cr12 = NULL;
modelica_metatype _cr21 = NULL;
modelica_metatype _cr22 = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
modelica_metatype _fb1 = NULL;
modelica_metatype _fb2 = NULL;
modelica_metatype _eql1 = NULL;
modelica_metatype _eql2 = NULL;
modelica_metatype _elst1 = NULL;
modelica_metatype _elst2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 11; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,5) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_ifcond1 = tmpMeta[0];
_tb1 = tmpMeta[1];
_fb1 = tmpMeta[2];
_ifcond2 = tmpMeta[3];
_tb2 = tmpMeta[4];
_fb2 = tmpMeta[5];
tmp4 += 9;
tmp6 = omc_SCodeUtil_equationEqual22(threadData, _tb1, _tb2);
if (1 != tmp6) goto goto_2;
omc_List_threadMapAllValue(threadData, _fb1, _fb2, boxvar_SCodeUtil_equationEqual2, mmc_mk_boolean(1));
omc_List_threadMapAllValue(threadData, _ifcond1, _ifcond2, boxvar_AbsynUtil_expEqual, mmc_mk_boolean(1));
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_e11 = tmpMeta[0];
_e12 = tmpMeta[1];
_e21 = tmpMeta[2];
_e22 = tmpMeta[3];
tmp4 += 8;
tmp7 = omc_AbsynUtil_expEqual(threadData, _e11, _e21);
if (1 != tmp7) goto goto_2;
tmp8 = omc_AbsynUtil_expEqual(threadData, _e12, _e22);
if (1 != tmp8) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp9;
modelica_boolean tmp10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,5) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e11 = tmpMeta[0];
_e12 = tmpMeta[1];
_cr1 = tmpMeta[2];
_e21 = tmpMeta[3];
_e22 = tmpMeta[4];
_cr2 = tmpMeta[5];
tmp4 += 7;
tmp9 = omc_AbsynUtil_expEqual(threadData, _e11, _e21);
if (1 != tmp9) goto goto_2;
tmp10 = omc_AbsynUtil_expEqual(threadData, _e12, _e22);
if (1 != tmp10) goto goto_2;
tmp11 = omc_AbsynUtil_crefEqual(threadData, _cr1, _cr2);
if (1 != tmp11) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp12;
modelica_boolean tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_cr11 = tmpMeta[0];
_cr12 = tmpMeta[1];
_cr21 = tmpMeta[2];
_cr22 = tmpMeta[3];
tmp4 += 6;
tmp12 = omc_AbsynUtil_crefEqual(threadData, _cr11, _cr21);
if (1 != tmp12) goto goto_2;
tmp13 = omc_AbsynUtil_crefEqual(threadData, _cr12, _cr22);
if (1 != tmp13) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp14;
modelica_boolean tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,5) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_id1 = tmpMeta[0];
_exp1 = tmpMeta[2];
_eql1 = tmpMeta[3];
_id2 = tmpMeta[4];
_exp2 = tmpMeta[6];
_eql2 = tmpMeta[7];
tmp4 += 5;
omc_List_threadMapAllValue(threadData, _eql1, _eql2, boxvar_SCodeUtil_equationEqual2, mmc_mk_boolean(1));
tmp14 = omc_AbsynUtil_expEqual(threadData, _exp1, _exp2);
if (1 != tmp14) goto goto_2;
tmp15 = (stringEqual(_id1, _id2));
if (1 != tmp15) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 5: {
modelica_boolean tmp16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,5) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (!optionNone(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_id1 = tmpMeta[0];
_eql1 = tmpMeta[2];
_id2 = tmpMeta[3];
_eql2 = tmpMeta[5];
tmp4 += 4;
omc_List_threadMapAllValue(threadData, _eql1, _eql2, boxvar_SCodeUtil_equationEqual2, mmc_mk_boolean(1));
tmp16 = (stringEqual(_id1, _id2));
if (1 != tmp16) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 6: {
modelica_boolean tmp17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_cond1 = tmpMeta[0];
_elst1 = tmpMeta[1];
_cond2 = tmpMeta[2];
_elst2 = tmpMeta[3];
tmp4 += 3;
omc_List_threadMapAllValue(threadData, _elst1, _elst2, boxvar_SCodeUtil_equationEqual2, mmc_mk_boolean(1));
tmp17 = omc_AbsynUtil_expEqual(threadData, _cond1, _cond2);
if (1 != tmp17) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 7: {
modelica_boolean tmp18;
modelica_boolean tmp19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_c1 = tmpMeta[0];
_m1 = tmpMeta[1];
_c2 = tmpMeta[2];
_m2 = tmpMeta[3];
tmp4 += 2;
tmp18 = omc_AbsynUtil_expEqual(threadData, _c1, _c2);
if (1 != tmp18) goto goto_2;
tmp19 = omc_AbsynUtil_expEqual(threadData, _m1, _m2);
if (1 != tmp19) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 8: {
modelica_boolean tmp20;
modelica_boolean tmp21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,4) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,8,4) == 0) goto tmp3_end;
tmp4 += 1;
tmp20 = omc_AbsynUtil_expEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq2), 2))));
if (1 != tmp20) goto goto_2;
tmp21 = omc_AbsynUtil_expEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq1), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq2), 3))));
if (1 != tmp21) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 9: {
modelica_boolean tmp22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,3) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_e1 = tmpMeta[0];
_e2 = tmpMeta[1];
tmp22 = omc_AbsynUtil_expEqual(threadData, _e1, _e2);
if (1 != tmp22) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 10: {
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
if (++tmp4 < 11) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_equationEqual2(threadData_t *threadData, modelica_metatype _eq1, modelica_metatype _eq2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_equationEqual2(threadData, _eq1, _eq2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_SCodeUtil_equationEqual(threadData_t *threadData, modelica_metatype _eqn1, modelica_metatype _eqn2)
{
modelica_boolean _equal;
modelica_metatype _eq1 = NULL;
modelica_metatype _eq2 = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _eqn1;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_eq1 = tmpMeta[1];
tmpMeta[0] = _eqn2;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_eq2 = tmpMeta[1];
_equal = omc_SCodeUtil_equationEqual2(threadData, _eq1, _eq2);
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_SCodeUtil_equationEqual(threadData_t *threadData, modelica_metatype _eqn1, modelica_metatype _eqn2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_equationEqual(threadData, _eqn1, _eqn2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_algorithmEqual2(threadData_t *threadData, modelica_metatype _ai1, modelica_metatype _ai2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _ai1;
tmp4_2 = _ai2;
{
modelica_metatype _alg1 = NULL;
modelica_metatype _alg2 = NULL;
modelica_metatype _a1 = NULL;
modelica_metatype _a2 = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e11 = NULL;
modelica_metatype _e12 = NULL;
modelica_metatype _e21 = NULL;
modelica_metatype _e22 = NULL;
modelica_boolean _b1;
modelica_boolean _b2;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_cr1 = tmpMeta[1];
_e1 = tmpMeta[2];
_cr2 = tmpMeta[4];
_e2 = tmpMeta[5];
tmp4 += 1;
_b1 = omc_AbsynUtil_crefEqual(threadData, _cr1, _cr2);
_b2 = omc_AbsynUtil_expEqual(threadData, _e1, _e2);
tmp1 = (_b1 && _b2);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],16,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],16,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_e11 = tmpMeta[0];
_e12 = tmpMeta[1];
_e21 = tmpMeta[2];
_e22 = tmpMeta[3];
_b1 = omc_AbsynUtil_expEqual(threadData, _e11, _e21);
_b2 = omc_AbsynUtil_expEqual(threadData, _e12, _e22);
tmp1 = (_b1 && _b2);
goto tmp3_done;
}
case 2: {
_a1 = tmp4_1;
_a2 = tmp4_2;
tmpMeta[0] = omc_SCodeUtil_statementToAlgorithmItem(threadData, _a1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,3) == 0) goto goto_2;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_alg1 = tmpMeta[1];
tmpMeta[0] = omc_SCodeUtil_statementToAlgorithmItem(threadData, _a2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,3) == 0) goto goto_2;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_alg2 = tmpMeta[1];
equality(_alg1, _alg2);
tmp1 = 1;
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_algorithmEqual2(threadData_t *threadData, modelica_metatype _ai1, modelica_metatype _ai2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_algorithmEqual2(threadData, _ai1, _ai2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_algorithmEqual(threadData_t *threadData, modelica_metatype _alg1, modelica_metatype _alg2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _alg1;
tmp4_2 = _alg2;
{
modelica_metatype _a1 = NULL;
modelica_metatype _a2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_a1 = tmpMeta[0];
_a2 = tmpMeta[1];
omc_List_threadMapAllValue(threadData, _a1, _a2, boxvar_SCodeUtil_algorithmEqual2, mmc_mk_boolean(1));
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_algorithmEqual(threadData_t *threadData, modelica_metatype _alg1, modelica_metatype _alg2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_algorithmEqual(threadData, _alg1, _alg2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_subscriptEqual(threadData_t *threadData, modelica_metatype _sub1, modelica_metatype _sub2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _sub1;
tmp4_2 = _sub2;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_e1 = tmpMeta[0];
_e2 = tmpMeta[1];
tmp1 = omc_AbsynUtil_expEqual(threadData, _e1, _e2);
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_subscriptEqual(threadData_t *threadData, modelica_metatype _sub1, modelica_metatype _sub2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_subscriptEqual(threadData, _sub1, _sub2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_arraydimOptEqual(threadData_t *threadData, modelica_metatype _adopt1, modelica_metatype _adopt2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _adopt1;
tmp4_2 = _adopt2;
{
modelica_metatype _lst1 = NULL;
modelica_metatype _lst2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
tmp4 += 2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_lst1 = tmpMeta[0];
_lst2 = tmpMeta[1];
omc_List_threadMapAllValue(threadData, _lst1, _lst2, boxvar_SCodeUtil_subscriptEqual, mmc_mk_boolean(1));
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_arraydimOptEqual(threadData_t *threadData, modelica_metatype _adopt1, modelica_metatype _adopt2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_arraydimOptEqual(threadData, _adopt1, _adopt2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_SCodeUtil_classDefEqual(threadData_t *threadData, modelica_metatype _cdef1, modelica_metatype _cdef2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[14] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _cdef1;
tmp4_2 = _cdef2;
{
modelica_metatype _elts1 = NULL;
modelica_metatype _elts2 = NULL;
modelica_metatype _eqns1 = NULL;
modelica_metatype _eqns2 = NULL;
modelica_metatype _ieqns1 = NULL;
modelica_metatype _ieqns2 = NULL;
modelica_metatype _algs1 = NULL;
modelica_metatype _algs2 = NULL;
modelica_metatype _ialgs1 = NULL;
modelica_metatype _ialgs2 = NULL;
modelica_metatype _attr1 = NULL;
modelica_metatype _attr2 = NULL;
modelica_metatype _tySpec1 = NULL;
modelica_metatype _tySpec2 = NULL;
modelica_metatype _mod1 = NULL;
modelica_metatype _mod2 = NULL;
modelica_metatype _elst1 = NULL;
modelica_metatype _elst2 = NULL;
modelica_metatype _ilst1 = NULL;
modelica_metatype _ilst2 = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,8) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
_elts1 = tmpMeta[0];
_eqns1 = tmpMeta[1];
_ieqns1 = tmpMeta[2];
_algs1 = tmpMeta[3];
_ialgs1 = tmpMeta[4];
_elts2 = tmpMeta[5];
_eqns2 = tmpMeta[6];
_ieqns2 = tmpMeta[7];
_algs2 = tmpMeta[8];
_ialgs2 = tmpMeta[9];
omc_List_threadMapAllValue(threadData, _elts1, _elts2, boxvar_SCodeUtil_elementEqual, mmc_mk_boolean(1));
omc_List_threadMapAllValue(threadData, _eqns1, _eqns2, boxvar_SCodeUtil_equationEqual, mmc_mk_boolean(1));
omc_List_threadMapAllValue(threadData, _ieqns1, _ieqns2, boxvar_SCodeUtil_equationEqual, mmc_mk_boolean(1));
omc_List_threadMapAllValue(threadData, _algs1, _algs2, boxvar_SCodeUtil_algorithmEqual, mmc_mk_boolean(1));
omc_List_threadMapAllValue(threadData, _ialgs1, _ialgs2, boxvar_SCodeUtil_algorithmEqual, mmc_mk_boolean(1));
tmp1 = 1;
goto tmp3_done;
}
case 5: {
modelica_boolean tmp5;
modelica_boolean tmp6;
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_tySpec1 = tmpMeta[0];
_mod1 = tmpMeta[1];
_attr1 = tmpMeta[2];
_tySpec2 = tmpMeta[3];
_mod2 = tmpMeta[4];
_attr2 = tmpMeta[5];
tmp5 = omc_AbsynUtil_typeSpecEqual(threadData, _tySpec1, _tySpec2);
if (1 != tmp5) goto goto_2;
tmp6 = omc_SCodeUtil_modEqual(threadData, _mod1, _mod2);
if (1 != tmp6) goto goto_2;
tmp7 = omc_SCodeUtil_attributesEqual(threadData, _attr1, _attr2);
if (1 != tmp7) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_elst1 = tmpMeta[0];
_elst2 = tmpMeta[1];
omc_List_threadMapAllValue(threadData, _elst1, _elst2, boxvar_SCodeUtil_enumEqual, mmc_mk_boolean(1));
tmp1 = 1;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,8) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,2) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],0,8) == 0) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 3));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 4));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 5));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 6));
_mod1 = tmpMeta[0];
_elts1 = tmpMeta[2];
_eqns1 = tmpMeta[3];
_ieqns1 = tmpMeta[4];
_algs1 = tmpMeta[5];
_ialgs1 = tmpMeta[6];
_mod2 = tmpMeta[7];
_elts2 = tmpMeta[9];
_eqns2 = tmpMeta[10];
_ieqns2 = tmpMeta[11];
_algs2 = tmpMeta[12];
_ialgs2 = tmpMeta[13];
omc_List_threadMapAllValue(threadData, _elts1, _elts2, boxvar_SCodeUtil_elementEqual, mmc_mk_boolean(1));
omc_List_threadMapAllValue(threadData, _eqns1, _eqns2, boxvar_SCodeUtil_equationEqual, mmc_mk_boolean(1));
omc_List_threadMapAllValue(threadData, _ieqns1, _ieqns2, boxvar_SCodeUtil_equationEqual, mmc_mk_boolean(1));
omc_List_threadMapAllValue(threadData, _algs1, _algs2, boxvar_SCodeUtil_algorithmEqual, mmc_mk_boolean(1));
omc_List_threadMapAllValue(threadData, _ialgs1, _ialgs2, boxvar_SCodeUtil_algorithmEqual, mmc_mk_boolean(1));
tmp8 = omc_SCodeUtil_modEqual(threadData, _mod1, _mod2);
if (1 != tmp8) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,2) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_ilst1 = tmpMeta[0];
_ilst2 = tmpMeta[1];
omc_List_threadMapAllValue(threadData, _ilst1, _ilst2, boxvar_stringEq, mmc_mk_boolean(1));
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_SCodeUtil_classDefEqual(threadData_t *threadData, modelica_metatype _cdef1, modelica_metatype _cdef2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_classDefEqual(threadData, _cdef1, _cdef2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_SCodeUtil_enumEqual(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _e2)
{
modelica_boolean _isEqual;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _e1;
tmp4_2 = _e2;
{
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_s1 = tmpMeta[0];
_s2 = tmpMeta[1];
tmp1 = (stringEqual(_s1, _s2));
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
_isEqual = tmp1;
_return: OMC_LABEL_UNUSED
return _isEqual;
}
modelica_metatype boxptr_SCodeUtil_enumEqual(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _e2)
{
modelica_boolean _isEqual;
modelica_metatype out_isEqual;
_isEqual = omc_SCodeUtil_enumEqual(threadData, _e1, _e2);
out_isEqual = mmc_mk_icon(_isEqual);
return out_isEqual;
}
DLLExport
modelica_boolean omc_SCodeUtil_funcRestrictionEqual(threadData_t *threadData, modelica_metatype _funcRestr1, modelica_metatype _funcRestr2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _funcRestr1;
tmp4_2 = _funcRestr2;
{
modelica_boolean _b1;
modelica_boolean _b2;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta[0]);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
_b1 = tmp6;
_b2 = tmp7;
tmp1 = ((!_b1 && !_b2) || (_b1 && _b2));
goto tmp3_done;
}
case 1: {
modelica_integer tmp8;
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp8 = mmc_unbox_integer(tmpMeta[0]);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp9 = mmc_unbox_integer(tmpMeta[1]);
_b1 = tmp8;
_b2 = tmp9;
tmp1 = ((!_b1 && !_b2) || (_b1 && _b2));
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 6: {
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_SCodeUtil_funcRestrictionEqual(threadData_t *threadData, modelica_metatype _funcRestr1, modelica_metatype _funcRestr2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_funcRestrictionEqual(threadData, _funcRestr1, _funcRestr2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_SCodeUtil_restrictionEqual(threadData_t *threadData, modelica_metatype _restr1, modelica_metatype _restr2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _restr1;
tmp4_2 = _restr2;
{
modelica_metatype _funcRest1 = NULL;
modelica_metatype _funcRest2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 21; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_integer tmp6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta[0]);
if (1 != tmp6) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp7) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
modelica_integer tmp8;
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp8 = mmc_unbox_integer(tmpMeta[0]);
if (0 != tmp8) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp9 = mmc_unbox_integer(tmpMeta[1]);
if (0 != tmp9) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 6: {
modelica_integer tmp10;
modelica_integer tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp10 = mmc_unbox_integer(tmpMeta[0]);
if (1 != tmp10) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp11 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp11) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 7: {
modelica_integer tmp12;
modelica_integer tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp12 = mmc_unbox_integer(tmpMeta[0]);
if (0 != tmp12) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp13 = mmc_unbox_integer(tmpMeta[1]);
if (0 != tmp13) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,8,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_funcRest1 = tmpMeta[0];
_funcRest2 = tmpMeta[1];
tmp1 = omc_SCodeUtil_funcRestrictionEqual(threadData, _funcRest1, _funcRest2);
goto tmp3_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,10,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,11,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,12,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,14,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,15,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 19: {
modelica_boolean tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,18,1) == 0) goto tmp3_end;
{
modelica_boolean __omcQ_24tmpVar53;
modelica_boolean __omcQ_24tmpVar52;
int tmp15;
modelica_metatype _t2_loopVar = 0;
modelica_metatype _t2;
modelica_metatype _t1_loopVar = 0;
modelica_metatype _t1;
_t2_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_restr2), 2)));
_t1_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_restr1), 2)));
__omcQ_24tmpVar53 = 1;
while(1) {
tmp15 = 2;
if (!listEmpty(_t2_loopVar)) {
_t2 = MMC_CAR(_t2_loopVar);
_t2_loopVar = MMC_CDR(_t2_loopVar);
tmp15--;
}if (!listEmpty(_t1_loopVar)) {
_t1 = MMC_CAR(_t1_loopVar);
_t1_loopVar = MMC_CDR(_t1_loopVar);
tmp15--;
}
if (tmp15 == 0) {
__omcQ_24tmpVar52 = (stringEqual(_t1, _t2));
__omcQ_24tmpVar53 = (__omcQ_24tmpVar52 && __omcQ_24tmpVar53);
} else if (tmp15 == 2) {
break;
} else {
goto goto_2;
}
}
tmp14 = __omcQ_24tmpVar53;
}
tmp1 = tmp14;
goto tmp3_done;
}
case 20: {
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
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_SCodeUtil_restrictionEqual(threadData_t *threadData, modelica_metatype _restr1, modelica_metatype _restr2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_restrictionEqual(threadData, _restr1, _restr2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_SCodeUtil_annotationEqual(threadData_t *threadData, modelica_metatype _annotation1, modelica_metatype _annotation2)
{
modelica_boolean _equal;
modelica_metatype _mod1 = NULL;
modelica_metatype _mod2 = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _annotation1;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_mod1 = tmpMeta[1];
tmpMeta[0] = _annotation2;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_mod2 = tmpMeta[1];
_equal = omc_SCodeUtil_modEqual(threadData, _mod1, _mod2);
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_SCodeUtil_annotationEqual(threadData_t *threadData, modelica_metatype _annotation1, modelica_metatype _annotation2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_annotationEqual(threadData, _annotation1, _annotation2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_boolean omc_SCodeUtil_elementEqual(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[12] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _element1;
tmp4_2 = _element2;
{
modelica_string _name1 = NULL;
modelica_string _name2 = NULL;
modelica_metatype _prefixes1 = NULL;
modelica_metatype _prefixes2 = NULL;
modelica_metatype _en1 = NULL;
modelica_metatype _en2 = NULL;
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
modelica_metatype _restr1 = NULL;
modelica_metatype _restr2 = NULL;
modelica_metatype _attr1 = NULL;
modelica_metatype _attr2 = NULL;
modelica_metatype _mod1 = NULL;
modelica_metatype _mod2 = NULL;
modelica_metatype _tp1 = NULL;
modelica_metatype _tp2 = NULL;
modelica_metatype _im1 = NULL;
modelica_metatype _im2 = NULL;
modelica_metatype _path1 = NULL;
modelica_metatype _path2 = NULL;
modelica_metatype _os1 = NULL;
modelica_metatype _os2 = NULL;
modelica_metatype _or1 = NULL;
modelica_metatype _or2 = NULL;
modelica_metatype _cond1 = NULL;
modelica_metatype _cond2 = NULL;
modelica_metatype _cd1 = NULL;
modelica_metatype _cd2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
modelica_boolean tmp7;
modelica_boolean tmp8;
modelica_boolean tmp9;
modelica_boolean tmp10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,8) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 7));
_name1 = tmpMeta[0];
_prefixes1 = tmpMeta[1];
_en1 = tmpMeta[2];
_p1 = tmpMeta[3];
_restr1 = tmpMeta[4];
_cd1 = tmpMeta[5];
_name2 = tmpMeta[6];
_prefixes2 = tmpMeta[7];
_en2 = tmpMeta[8];
_p2 = tmpMeta[9];
_restr2 = tmpMeta[10];
_cd2 = tmpMeta[11];
tmp4 += 4;
tmp6 = (stringEqual(_name1, _name2));
if (1 != tmp6) goto goto_2;
tmp7 = omc_SCodeUtil_prefixesEqual(threadData, _prefixes1, _prefixes2);
if (1 != tmp7) goto goto_2;
tmp8 = valueEq(_en1, _en2);
if (1 != tmp8) goto goto_2;
tmp9 = valueEq(_p1, _p2);
if (1 != tmp9) goto goto_2;
tmp10 = omc_SCodeUtil_restrictionEqual(threadData, _restr1, _restr2);
if (1 != tmp10) goto goto_2;
tmp11 = omc_SCodeUtil_classDefEqual(threadData, _cd1, _cd2);
if (1 != tmp11) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp12;
modelica_boolean tmp13;
modelica_boolean tmp14;
modelica_boolean tmp15;
modelica_boolean tmp16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,8) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 8));
_name1 = tmpMeta[0];
_prefixes1 = tmpMeta[1];
_attr1 = tmpMeta[2];
_tp1 = tmpMeta[3];
_mod1 = tmpMeta[4];
_cond1 = tmpMeta[5];
_name2 = tmpMeta[6];
_prefixes2 = tmpMeta[7];
_attr2 = tmpMeta[8];
_tp2 = tmpMeta[9];
_mod2 = tmpMeta[10];
_cond2 = tmpMeta[11];
tmp4 += 3;
equality(_cond1, _cond2);
tmp12 = (stringEqual(_name1, _name2));
if (1 != tmp12) goto goto_2;
tmp13 = omc_SCodeUtil_prefixesEqual(threadData, _prefixes1, _prefixes2);
if (1 != tmp13) goto goto_2;
tmp14 = omc_SCodeUtil_attributesEqual(threadData, _attr1, _attr2);
if (1 != tmp14) goto goto_2;
tmp15 = omc_SCodeUtil_modEqual(threadData, _mod1, _mod2);
if (1 != tmp15) goto goto_2;
tmp16 = omc_AbsynUtil_typeSpecEqual(threadData, _tp1, _tp2);
if (1 != tmp16) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp17;
modelica_boolean tmp18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_path1 = tmpMeta[0];
_mod1 = tmpMeta[1];
_path2 = tmpMeta[2];
_mod2 = tmpMeta[3];
tmp4 += 2;
tmp17 = omc_AbsynUtil_pathEqual(threadData, _path1, _path2);
if (1 != tmp17) goto goto_2;
tmp18 = omc_SCodeUtil_modEqual(threadData, _mod1, _mod2);
if (1 != tmp18) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,3) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_im1 = tmpMeta[0];
_im2 = tmpMeta[1];
tmp4 += 1;
tmp19 = omc_AbsynUtil_importEqual(threadData, _im1, _im2);
if (1 != tmp19) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,5) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
_name1 = tmpMeta[0];
_os1 = tmpMeta[1];
_or1 = tmpMeta[2];
_name2 = tmpMeta[3];
_os2 = tmpMeta[4];
_or2 = tmpMeta[5];
tmp20 = (stringEqual(_name1, _name2));
if (1 != tmp20) goto goto_2;
equality(_os1, _os2);
equality(_or1, _or2);
tmp1 = 1;
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
tmp3_done:
(void)tmp4;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp3_done2;
goto_2:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp4 < 6) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_equal = tmp1;
_return: OMC_LABEL_UNUSED
return _equal;
}
modelica_metatype boxptr_SCodeUtil_elementEqual(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_SCodeUtil_elementEqual(threadData, _element1, _element2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_metatype omc_SCodeUtil_classSetPartial(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inPartial)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inClass;
tmp3_2 = _inPartial;
{
modelica_string _id = NULL;
modelica_metatype _enc = NULL;
modelica_metatype _partialPrefix = NULL;
modelica_metatype _restr = NULL;
modelica_metatype _def = NULL;
modelica_metatype _info = NULL;
modelica_metatype _prefixes = NULL;
modelica_metatype _cmt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_id = tmpMeta[1];
_prefixes = tmpMeta[2];
_enc = tmpMeta[3];
_restr = tmpMeta[4];
_def = tmpMeta[5];
_cmt = tmpMeta[6];
_info = tmpMeta[7];
_partialPrefix = tmp3_2;
tmpMeta[1] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _id, _prefixes, _enc, _partialPrefix, _restr, _def, _cmt, _info);
tmpMeta[0] = tmpMeta[1];
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
_outClass = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outClass;
}
DLLExport
modelica_string omc_SCodeUtil_className(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_string _outName = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inClass;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_outName = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outName;
}
DLLExport
modelica_boolean omc_SCodeUtil_isOperator(threadData_t *threadData, modelica_metatype _el)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _el;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],6,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],9,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,0) == 0) goto tmp3_end;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_SCodeUtil_isOperator(threadData_t *threadData, modelica_metatype _el)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_SCodeUtil_isOperator(threadData, _el);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_SCodeUtil_isFunctionOrExtFunctionRestriction(threadData_t *threadData, modelica_metatype _r)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _r;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp3_end;
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
_res = tmp1;
_return: OMC_LABEL_UNUSED
return _res;
}
modelica_metatype boxptr_SCodeUtil_isFunctionOrExtFunctionRestriction(threadData_t *threadData, modelica_metatype _r)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_SCodeUtil_isFunctionOrExtFunctionRestriction(threadData, _r);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_SCodeUtil_isFunctionRestriction(threadData_t *threadData, modelica_metatype _inRestriction)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRestriction;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_isFunctionRestriction(threadData_t *threadData, modelica_metatype _inRestriction)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_SCodeUtil_isFunctionRestriction(threadData, _inRestriction);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_SCodeUtil_isUniontype(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],18,1) == 0) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_isUniontype(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_SCodeUtil_isUniontype(threadData, _inClass);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_SCodeUtil_isFunction(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],9,1) == 0) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_isFunction(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_SCodeUtil_isFunction(threadData, _inClass);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_SCodeUtil_isOperatorRecord(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp6) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_isOperatorRecord(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_SCodeUtil_isOperatorRecord(threadData, _inClass);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_SCodeUtil_isPolymorphicTypeVar(threadData_t *threadData, modelica_metatype _cls)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cls;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],7,0) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (11 != MMC_STRLEN(tmpMeta[4]) || strcmp(MMC_STRINGDATA(_OMC_LIT101), MMC_STRINGDATA(tmpMeta[4])) != 0) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_isPolymorphicTypeVar(threadData_t *threadData, modelica_metatype _cls)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_SCodeUtil_isPolymorphicTypeVar(threadData, _cls);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_SCodeUtil_isTypeVar(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],7,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_isTypeVar(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_SCodeUtil_isTypeVar(threadData, _inClass);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_SCodeUtil_isRecord(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,1) == 0) goto tmp3_end;
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
modelica_metatype boxptr_SCodeUtil_isRecord(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_SCodeUtil_isRecord(threadData, _inClass);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_string omc_SCodeUtil_enumName(threadData_t *threadData, modelica_metatype _e)
{
modelica_string _s = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _e;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_s = tmpMeta[0];
tmp1 = _s;
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
modelica_boolean omc_SCodeUtil_elementNameEqual(threadData_t *threadData, modelica_metatype _inElement1, modelica_metatype _inElement2)
{
modelica_boolean _outEqual;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inElement1;
tmp4_2 = _inElement2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,8) == 0) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement2), 2)))));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,8) == 0) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement2), 2)))));
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,5) == 0) goto tmp3_end;
tmp1 = (stringEqual((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement2), 2)))));
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,5) == 0) goto tmp3_end;
tmp1 = omc_AbsynUtil_pathEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement2), 2))));
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,3) == 0) goto tmp3_end;
tmp1 = omc_AbsynUtil_importEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElement2), 2))));
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
_outEqual = tmp1;
_return: OMC_LABEL_UNUSED
return _outEqual;
}
modelica_metatype boxptr_SCodeUtil_elementNameEqual(threadData_t *threadData, modelica_metatype _inElement1, modelica_metatype _inElement2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_SCodeUtil_elementNameEqual(threadData, _inElement1, _inElement2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
DLLExport
modelica_metatype omc_SCodeUtil_renameElement(threadData_t *threadData, modelica_metatype _inElement, modelica_string _inName)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_metatype _pf = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _pp = NULL;
modelica_metatype _res = NULL;
modelica_metatype _cdef = NULL;
modelica_metatype _i = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _cond = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_pf = tmpMeta[1];
_ep = tmpMeta[2];
_pp = tmpMeta[3];
_res = tmpMeta[4];
_cdef = tmpMeta[5];
_cmt = tmpMeta[6];
_i = tmpMeta[7];
tmpMeta[1] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _inName, _pf, _ep, _pp, _res, _cdef, _cmt, _i);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_pf = tmpMeta[1];
_attr = tmpMeta[2];
_ty = tmpMeta[3];
_mod = tmpMeta[4];
_cmt = tmpMeta[5];
_cond = tmpMeta[6];
_i = tmpMeta[7];
tmpMeta[1] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _inName, _pf, _attr, _ty, _mod, _cmt, _cond, _i);
tmpMeta[0] = tmpMeta[1];
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
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_SCodeUtil_elementNamesWork(threadData_t *threadData, modelica_metatype _e, modelica_metatype _acc)
{
modelica_metatype _out = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _e;
{
modelica_string _s = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_s = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_s, _acc);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_s = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_s, _acc);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _acc;
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
_out = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _out;
}
DLLExport
modelica_metatype omc_SCodeUtil_elementNames(threadData_t *threadData, modelica_metatype _elts)
{
modelica_metatype _names = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_names = omc_List_fold(threadData, _elts, boxvar_SCodeUtil_elementNamesWork, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return _names;
}
DLLExport
modelica_string omc_SCodeUtil_elementNameInfo(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype *out_outInfo)
{
modelica_string _outName = NULL;
modelica_metatype _outInfo = NULL;
modelica_string tmp1_c0 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_string _name = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
_name = tmpMeta[2];
_info = tmpMeta[3];
tmp1_c0 = _name;
tmpMeta[0+1] = _info;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
_name = tmpMeta[2];
_info = tmpMeta[3];
tmp1_c0 = _name;
tmpMeta[0+1] = _info;
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
_outName = tmp1_c0;
_outInfo = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outInfo) { *out_outInfo = _outInfo; }
return _outName;
}
DLLExport
modelica_string omc_SCodeUtil_elementName(threadData_t *threadData, modelica_metatype _e)
{
modelica_string _s = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _e;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_s = tmpMeta[0];
tmp1 = _s;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_s = tmpMeta[0];
tmp1 = _s;
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
modelica_metatype omc_SCodeUtil_elementInfo(threadData_t *threadData, modelica_metatype _e)
{
modelica_metatype _info = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _e;
{
modelica_metatype _i = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_i = tmpMeta[1];
tmpMeta[0] = _i;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
_i = tmpMeta[1];
tmpMeta[0] = _i;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_i = tmpMeta[1];
tmpMeta[0] = _i;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_i = tmpMeta[1];
tmpMeta[0] = _i;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _OMC_LIT26;
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
_info = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _info;
}
DLLExport
modelica_string omc_SCodeUtil_componentName(threadData_t *threadData, modelica_metatype _inComponent)
{
modelica_string _outName = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inComponent;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,8) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_outName = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outName;
}
DLLExport
modelica_metatype omc_SCodeUtil_componentNamesFromElts(threadData_t *threadData, modelica_metatype _inElements)
{
modelica_metatype _outComponentNames = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outComponentNames = omc_List_filterMap(threadData, _inElements, boxvar_SCodeUtil_componentName);
_return: OMC_LABEL_UNUSED
return _outComponentNames;
}
DLLExport
modelica_metatype omc_SCodeUtil_componentNames(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _outStringLst = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inClass;
{
modelica_metatype _elts = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,8) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_elts = tmpMeta[2];
tmpMeta[0] = omc_SCodeUtil_componentNamesFromElts(threadData, _elts);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_elts = tmpMeta[3];
tmpMeta[0] = omc_SCodeUtil_componentNamesFromElts(threadData, _elts);
goto tmp2_done;
}
case 2: {
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
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
_outStringLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outStringLst;
}
DLLExport
modelica_integer omc_SCodeUtil_countParts(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_integer _outInteger;
modelica_integer tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_metatype _elts = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,8) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_elts = tmpMeta[1];
tmp4 += 1;
tmp1 = listLength(_elts);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,2) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,8) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_elts = tmpMeta[2];
tmp1 = listLength(_elts);
goto tmp3_done;
}
case 2: {
tmp1 = ((modelica_integer) 0);
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
_outInteger = tmp1;
_return: OMC_LABEL_UNUSED
return _outInteger;
}
modelica_metatype boxptr_SCodeUtil_countParts(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_integer _outInteger;
modelica_metatype out_outInteger;
_outInteger = omc_SCodeUtil_countParts(threadData, _inClass);
out_outInteger = mmc_mk_icon(_outInteger);
return out_outInteger;
}
DLLExport
modelica_boolean omc_SCodeUtil_isConstant(threadData_t *threadData, modelica_metatype _inVariability)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVariability;
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_SCodeUtil_isConstant(threadData_t *threadData, modelica_metatype _inVariability)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_SCodeUtil_isConstant(threadData, _inVariability);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_SCodeUtil_isParameterOrConst(threadData_t *threadData, modelica_metatype _inVariability)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVariability;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
modelica_metatype boxptr_SCodeUtil_isParameterOrConst(threadData_t *threadData, modelica_metatype _inVariability)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_SCodeUtil_isParameterOrConst(threadData, _inVariability);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_SCodeUtil_isNotElementClassExtends(threadData_t *threadData, modelica_metatype _ele)
{
modelica_boolean _isExtend;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ele;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,2) == 0) goto tmp3_end;
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
_isExtend = tmp1;
_return: OMC_LABEL_UNUSED
return _isExtend;
}
modelica_metatype boxptr_SCodeUtil_isNotElementClassExtends(threadData_t *threadData, modelica_metatype _ele)
{
modelica_boolean _isExtend;
modelica_metatype out_isExtend;
_isExtend = omc_SCodeUtil_isNotElementClassExtends(threadData, _ele);
out_isExtend = mmc_mk_icon(_isExtend);
return out_isExtend;
}
DLLExport
modelica_boolean omc_SCodeUtil_isElementExtendsOrClassExtends(threadData_t *threadData, modelica_metatype _ele)
{
modelica_boolean _isExtend;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ele;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
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
_isExtend = tmp1;
_return: OMC_LABEL_UNUSED
return _isExtend;
}
modelica_metatype boxptr_SCodeUtil_isElementExtendsOrClassExtends(threadData_t *threadData, modelica_metatype _ele)
{
modelica_boolean _isExtend;
modelica_metatype out_isExtend;
_isExtend = omc_SCodeUtil_isElementExtendsOrClassExtends(threadData, _ele);
out_isExtend = mmc_mk_icon(_isExtend);
return out_isExtend;
}
DLLExport
modelica_boolean omc_SCodeUtil_isElementExtends(threadData_t *threadData, modelica_metatype _ele)
{
modelica_boolean _isExtend;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ele;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
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
_isExtend = tmp1;
_return: OMC_LABEL_UNUSED
return _isExtend;
}
modelica_metatype boxptr_SCodeUtil_isElementExtends(threadData_t *threadData, modelica_metatype _ele)
{
modelica_boolean _isExtend;
modelica_metatype out_isExtend;
_isExtend = omc_SCodeUtil_isElementExtends(threadData, _ele);
out_isExtend = mmc_mk_icon(_isExtend);
return out_isExtend;
}
DLLExport
modelica_metatype omc_SCodeUtil_getElementNamedFromElts(threadData_t *threadData, modelica_string _inIdent, modelica_metatype _inElementLst)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_string tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inIdent;
tmp3_2 = _inElementLst;
{
modelica_metatype _comp = NULL;
modelica_metatype _cdef = NULL;
modelica_string _id2 = NULL;
modelica_string _id1 = NULL;
modelica_metatype _xs = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 6; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_comp = tmpMeta[1];
_id1 = tmpMeta[3];
_id2 = tmp3_1;
tmp5 = (stringEqual(_id1, _id2));
if (1 != tmp5) goto goto_1;
tmpMeta[0] = _comp;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp6;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_id1 = tmpMeta[3];
_xs = tmpMeta[2];
_id2 = tmp3_1;
tmp3 += 3;
tmp6 = (stringEqual(_id1, _id2));
if (0 != tmp6) goto goto_1;
tmpMeta[0] = omc_SCodeUtil_getElementNamedFromElts(threadData, _id2, _xs);
goto tmp2_done;
}
case 2: {
modelica_boolean tmp7;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_id1 = tmpMeta[3];
_xs = tmpMeta[2];
_id2 = tmp3_1;
tmp3 += 1;
tmp7 = (stringEqual(_id1, _id2));
if (0 != tmp7) goto goto_1;
tmpMeta[0] = omc_SCodeUtil_getElementNamedFromElts(threadData, _id2, _xs);
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,5) == 0) goto tmp2_end;
_xs = tmpMeta[2];
_id2 = tmp3_1;
tmp3 += 1;
tmpMeta[0] = omc_SCodeUtil_getElementNamedFromElts(threadData, _id2, _xs);
goto tmp2_done;
}
case 4: {
modelica_boolean tmp8;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cdef = tmpMeta[1];
_id1 = tmpMeta[3];
_id2 = tmp3_1;
tmp8 = (stringEqual(_id1, _id2));
if (1 != tmp8) goto goto_1;
tmpMeta[0] = _cdef;
goto tmp2_done;
}
case 5: {
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
_xs = tmpMeta[2];
_id2 = tmp3_1;
tmpMeta[0] = omc_SCodeUtil_getElementNamedFromElts(threadData, _id2, _xs);
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
if (++tmp3 < 6) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLExport
modelica_metatype omc_SCodeUtil_getElementNamed(threadData_t *threadData, modelica_string _inIdent, modelica_metatype _inClass)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inIdent;
tmp3_2 = _inClass;
{
modelica_string _id = NULL;
modelica_metatype _elts = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,8) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_elts = tmpMeta[2];
_id = tmp3_1;
tmpMeta[0] = omc_SCodeUtil_getElementNamedFromElts(threadData, _id, _elts);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_elts = tmpMeta[3];
_id = tmp3_1;
tmpMeta[0] = omc_SCodeUtil_getElementNamedFromElts(threadData, _id, _elts);
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
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLExport
modelica_boolean omc_SCodeUtil_removeGivenSubModNames(threadData_t *threadData, modelica_metatype _submod, modelica_metatype _namesToRemove)
{
modelica_boolean _keep;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_keep = (!listMember((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_submod), 2))), _namesToRemove));
_return: OMC_LABEL_UNUSED
return _keep;
}
modelica_metatype boxptr_SCodeUtil_removeGivenSubModNames(threadData_t *threadData, modelica_metatype _submod, modelica_metatype _namesToRemove)
{
modelica_boolean _keep;
modelica_metatype out_keep;
_keep = omc_SCodeUtil_removeGivenSubModNames(threadData, _submod, _namesToRemove);
out_keep = mmc_mk_icon(_keep);
return out_keep;
}
DLLExport
modelica_boolean omc_SCodeUtil_filterGivenSubModNames(threadData_t *threadData, modelica_metatype _submod, modelica_metatype _namesToKeep)
{
modelica_boolean _keep;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_keep = listMember((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_submod), 2))), _namesToKeep);
_return: OMC_LABEL_UNUSED
return _keep;
}
modelica_metatype boxptr_SCodeUtil_filterGivenSubModNames(threadData_t *threadData, modelica_metatype _submod, modelica_metatype _namesToKeep)
{
modelica_boolean _keep;
modelica_metatype out_keep;
_keep = omc_SCodeUtil_filterGivenSubModNames(threadData, _submod, _namesToKeep);
out_keep = mmc_mk_icon(_keep);
return out_keep;
}
DLLExport
modelica_metatype omc_SCodeUtil_filterSubMods(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fmod, modelica_fnptr _filter)
{
modelica_metatype _mod = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_mod = __omcQ_24in_5Fmod;
{
modelica_metatype tmp3_1;
tmp3_1 = _mod;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
{
modelica_metatype __omcQ_24tmpVar55;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar54;
int tmp6;
modelica_metatype _m_loopVar = 0;
modelica_metatype _m;
_m_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_mod), 4)));
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar55 = tmpMeta[3];
tmp5 = &__omcQ_24tmpVar55;
while(1) {
tmp6 = 1;
while (!listEmpty(_m_loopVar)) {
_m = MMC_CAR(_m_loopVar);
_m_loopVar = MMC_CDR(_m_loopVar);
if (mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_filter), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_filter), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_filter), 2))), _m) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_filter), 1)))) (threadData, _m))) {
tmp6--;
break;
}
}
if (tmp6 == 0) {
__omcQ_24tmpVar54 = _m;
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar54,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[2] = __omcQ_24tmpVar55;
}
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_mod), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[4] = tmpMeta[2];
_mod = tmpMeta[1];
{
modelica_metatype tmp9_1;
tmp9_1 = _mod;
{
volatile mmc_switch_type tmp9;
int tmp10;
tmp9 = 0;
for (; tmp9 < 2; tmp9++) {
switch (MMC_SWITCH_CAST(tmp9)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp9_1,0,5) == 0) goto tmp8_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp9_1), 4));
if (!listEmpty(tmpMeta[2])) goto tmp8_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp9_1), 5));
if (!optionNone(tmpMeta[3])) goto tmp8_end;
tmpMeta[1] = _OMC_LIT15;
goto tmp8_done;
}
case 1: {
tmpMeta[1] = _mod;
goto tmp8_done;
}
}
goto tmp8_end;
tmp8_end: ;
}
goto goto_7;
goto_7:;
goto goto_1;
goto tmp8_done;
tmp8_done:;
}
}tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _mod;
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
_mod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _mod;
}
DLLExport
modelica_metatype omc_SCodeUtil_stripSubmod(threadData_t *threadData, modelica_metatype _inMod)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inMod;
{
modelica_metatype _fp = NULL;
modelica_metatype _ep = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_fp = tmpMeta[1];
_ep = tmpMeta[2];
_binding = tmpMeta[3];
_info = tmpMeta[4];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _fp, _ep, tmpMeta[1], _binding, _info);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inMod;
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
_outMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMod;
}
