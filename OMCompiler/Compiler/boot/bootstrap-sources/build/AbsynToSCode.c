#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/AbsynToSCode.c"
#endif
#include "omc_simulation_settings.h"
#include "AbsynToSCode.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,6) {&ErrorTypes_Severity_NOTIFICATION__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "Tuple complex type specifiers need to have more than one type name: %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,71,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(276)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "Non-tuple complex type specifiers need to have exactly one type name: %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,73,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT5}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT7,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(275)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT6}};
#define _OMC_LIT7 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "list"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,4,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT8}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "List"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,4,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT10}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "array"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,5,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT12}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data "Array"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,5,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT14}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "polymorphic"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,11,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT16}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data "Option"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,6,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,2,1) {_OMC_LIT19,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,2,1) {_OMC_LIT17,_OMC_LIT20}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,2,1) {_OMC_LIT15,_OMC_LIT21}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,2,1) {_OMC_LIT13,_OMC_LIT22}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,2,1) {_OMC_LIT11,_OMC_LIT23}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,2,1) {_OMC_LIT9,_OMC_LIT24}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "tuple"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,5,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,1,3) {&SCode_Each_EACH__desc,}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,1,4) {&SCode_Each_NOT__EACH__desc,}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "Any"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,3,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT29}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,3,3) {&Absyn_TypeSpec_TPATH__desc,_OMC_LIT30,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,2,1) {_OMC_LIT31,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,4,4) {&Absyn_TypeSpec_TCOMPLEX__desc,_OMC_LIT17,_OMC_LIT32,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,1,5) {&SCode_Mod_NOMOD__desc,}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,1,3) {&SCode_ConnectorType_POTENTIAL__desc,}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,1,5) {&SCode_Parallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,1,3) {&SCode_Variability_VAR__desc,}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,1,5) {&Absyn_Direction_BIDIR__desc,}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,1,3) {&Absyn_IsField_NONFIELD__desc,}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,7,3) {&SCode_Attributes_ATTR__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT35,_OMC_LIT36,_OMC_LIT37,_OMC_LIT38,_OMC_LIT39}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,1,3) {&SCode_Visibility_PUBLIC__desc,}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT42,1,4) {&SCode_Redeclare_NOT__REDECLARE__desc,}};
#define _OMC_LIT42 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT42)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT43,1,3) {&SCode_Final_FINAL__desc,}};
#define _OMC_LIT43 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,1,4) {&SCode_Replaceable_NOT__REPLACEABLE__desc,}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,6,3) {&SCode_Prefixes_PREFIXES__desc,_OMC_LIT41,_OMC_LIT42,_OMC_LIT43,_OMC_LIT44,_OMC_LIT45}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,1,4) {&SCode_Encapsulated_NOT__ENCAPSULATED__desc,}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,1,4) {&SCode_Partial_NOT__PARTIAL__desc,}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,1,10) {&SCode_Restriction_R__TYPE__desc,}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,3,3) {&SCode_Comment_COMMENT__desc,MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,1,4) {&SCode_Final_NOT__FINAL__desc,}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,1,3) {&Absyn_EqMod_NOMOD__desc,}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,17,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT55,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT54}};
#define _OMC_LIT55 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT0,_OMC_LIT53,_OMC_LIT55}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "For loops with guards not yet implemented"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,41,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT58,2,1) {_OMC_LIT57,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT58 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "Connect equations are not allowed in initial equation sections."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,63,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT60,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT59}};
#define _OMC_LIT60 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT60)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT61,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(221)),_OMC_LIT0,_OMC_LIT53,_OMC_LIT60}};
#define _OMC_LIT61 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "AssertionLevel"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,14,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "error"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,5,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT64,3,5) {&Absyn_ComponentRef_CREF__IDENT__desc,_OMC_LIT63,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT64 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT64)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT65,4,4) {&Absyn_ComponentRef_CREF__QUAL__desc,_OMC_LIT62,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT64}};
#define _OMC_LIT65 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT65)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT66,2,3) {&Absyn_ComponentRef_CREF__FULLYQUALIFIED__desc,_OMC_LIT65}};
#define _OMC_LIT66 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT66)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT67,2,5) {&Absyn_Exp_CREF__desc,_OMC_LIT66}};
#define _OMC_LIT67 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "assert"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,6,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
#define _OMC_LIT69_data "level"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT69,5,_OMC_LIT69_data);
#define _OMC_LIT69 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data "terminate"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,9,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
#define _OMC_LIT71_data "reinit"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT71,6,_OMC_LIT71_data);
#define _OMC_LIT71 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT71)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT72,0.0);
#define _OMC_LIT72 MMC_REFREALLIT(_OMC_LIT_STRUCT72)
#define _OMC_LIT73_data "__OpenModelica_FileInfo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,23,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT74,1,4) {&SCode_Variability_DISCRETE__desc,}};
#define _OMC_LIT74 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT74)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT75,1,5) {&SCode_Variability_PARAM__desc,}};
#define _OMC_LIT75 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT75)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT76,1,6) {&SCode_Variability_CONST__desc,}};
#define _OMC_LIT76 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT76)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT77,1,3) {&SCode_Parallelism_PARGLOBAL__desc,}};
#define _OMC_LIT77 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT77)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT78,1,4) {&SCode_Parallelism_PARLOCAL__desc,}};
#define _OMC_LIT78 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT78)
#define _OMC_LIT79_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT79,0,_OMC_LIT79_data);
#define _OMC_LIT79 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT79)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT80,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT79,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT72}};
#define _OMC_LIT80 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT80)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT81,1,9) {&SCode_Restriction_R__OPERATOR__desc,}};
#define _OMC_LIT81 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data "$in_"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,4,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT83,1,3) {&Absyn_Direction_INPUT__desc,}};
#define _OMC_LIT83 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT83)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT84,1,4) {&Absyn_Direction_OUTPUT__desc,}};
#define _OMC_LIT84 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT84)
#define _OMC_LIT85_data "skipInputOutputSyntacticSugar"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT85,29,_OMC_LIT85_data);
#define _OMC_LIT85 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT85)
#define _OMC_LIT86_data "Used when bootstrapping to preserve the input output parsing of the code output by the list command."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT86,100,_OMC_LIT86_data);
#define _OMC_LIT86 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT86)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT87,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT86}};
#define _OMC_LIT87 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT87)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT88,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(154)),_OMC_LIT85,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT87}};
#define _OMC_LIT88 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT88)
#define _OMC_LIT89_data "AbsynToSCode.translateElementspec failed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT89,40,_OMC_LIT89_data);
#define _OMC_LIT89 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT89)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT90,2,1) {_OMC_LIT89,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT90 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT90)
#define _OMC_LIT91_data "exp"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT91,3,_OMC_LIT91_data);
#define _OMC_LIT91 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT91)
#define _OMC_LIT92_data "weight"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT92,6,_OMC_LIT92_data);
#define _OMC_LIT92 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT92)
#define _OMC_LIT93_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT93,9,_OMC_LIT93_data);
#define _OMC_LIT93 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT93)
#define _OMC_LIT94_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT94,41,_OMC_LIT94_data);
#define _OMC_LIT94 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT94)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT95,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT94}};
#define _OMC_LIT95 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT95)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT96,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT93,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT95}};
#define _OMC_LIT96 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT96)
#define _OMC_LIT97_data "- AbsynToSCode.translateClassdefConstraints failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT97,51,_OMC_LIT97_data);
#define _OMC_LIT97 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT97)
#define _OMC_LIT98_data "- AbsynToSCode.translateClassdefAlgorithms failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT98,50,_OMC_LIT98_data);
#define _OMC_LIT98 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT98)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT99,1,4) {&SCode_Visibility_PROTECTED__desc,}};
#define _OMC_LIT99 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT99)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT100,2,6) {&SCode_ClassDef_ENUMERATION__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT100 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT100)
#define _OMC_LIT101_data "AbsynToSCode.translateClassdef failed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT101,37,_OMC_LIT101_data);
#define _OMC_LIT101 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT101)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT102,2,1) {_OMC_LIT101,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT102 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT102)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT103,1,4) {&SCode_ConnectorType_FLOW__desc,}};
#define _OMC_LIT103 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT103)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT104,1,5) {&SCode_ConnectorType_STREAM__desc,}};
#define _OMC_LIT104 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT104)
#define _OMC_LIT105_data "AbsynToSCode.translateConnectorType got both flow and stream prefix."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT105,68,_OMC_LIT105_data);
#define _OMC_LIT105 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT105)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT106,2,1) {_OMC_LIT105,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT106 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT106)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT107,1,5) {&SCode_FunctionRestriction_FR__OPERATOR__FUNCTION__desc,}};
#define _OMC_LIT107 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT107)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT108,2,12) {&SCode_Restriction_R__FUNCTION__desc,_OMC_LIT107}};
#define _OMC_LIT108 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT108)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT109,1,7) {&SCode_FunctionRestriction_FR__PARALLEL__FUNCTION__desc,}};
#define _OMC_LIT109 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT109)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT110,2,12) {&SCode_Restriction_R__FUNCTION__desc,_OMC_LIT109}};
#define _OMC_LIT110 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT110)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT111,1,8) {&SCode_FunctionRestriction_FR__KERNEL__FUNCTION__desc,}};
#define _OMC_LIT111 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT111)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT112,2,12) {&SCode_Restriction_R__FUNCTION__desc,_OMC_LIT111}};
#define _OMC_LIT112 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT112)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT113,1,3) {&SCode_Restriction_R__CLASS__desc,}};
#define _OMC_LIT113 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT113)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT114,1,4) {&SCode_Restriction_R__OPTIMIZATION__desc,}};
#define _OMC_LIT114 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT114)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT115,1,5) {&SCode_Restriction_R__MODEL__desc,}};
#define _OMC_LIT115 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT115)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT116,2,6) {&SCode_Restriction_R__RECORD__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT116 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT116)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT117,2,6) {&SCode_Restriction_R__RECORD__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT117 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT117)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT118,1,7) {&SCode_Restriction_R__BLOCK__desc,}};
#define _OMC_LIT118 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT118)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT119,2,8) {&SCode_Restriction_R__CONNECTOR__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT119 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT119)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT120,2,8) {&SCode_Restriction_R__CONNECTOR__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT120 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT120)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT121,1,11) {&SCode_Restriction_R__PACKAGE__desc,}};
#define _OMC_LIT121 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT121)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT122,1,13) {&SCode_Restriction_R__ENUMERATION__desc,}};
#define _OMC_LIT122 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT122)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT123,1,14) {&SCode_Restriction_R__PREDEFINED__INTEGER__desc,}};
#define _OMC_LIT123 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT123)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT124,1,15) {&SCode_Restriction_R__PREDEFINED__REAL__desc,}};
#define _OMC_LIT124 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT124)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT125,1,16) {&SCode_Restriction_R__PREDEFINED__STRING__desc,}};
#define _OMC_LIT125 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT125)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT126,1,17) {&SCode_Restriction_R__PREDEFINED__BOOLEAN__desc,}};
#define _OMC_LIT126 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT126)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT127,1,19) {&SCode_Restriction_R__PREDEFINED__CLOCK__desc,}};
#define _OMC_LIT127 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT127)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT128,1,18) {&SCode_Restriction_R__PREDEFINED__ENUMERATION__desc,}};
#define _OMC_LIT128 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT128)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT129,2,21) {&SCode_Restriction_R__UNIONTYPE__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT129 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT129)
#define _OMC_LIT130_data "Could not translate operator to SCode because it is not using class parts."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT130,74,_OMC_LIT130_data);
#define _OMC_LIT130 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT130)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT131,2,1) {_OMC_LIT130,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT131 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT131)
#define _OMC_LIT132_data "AbsynToSCode.translateClass2 failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT132,37,_OMC_LIT132_data);
#define _OMC_LIT132 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT132)
#include "util/modelica.h"
#include "AbsynToSCode_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC void omc_AbsynToSCode_checkTypeSpec(threadData_t *threadData, modelica_metatype _ts, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_checkTypeSpec,2,0) {(void*) boxptr_AbsynToSCode_checkTypeSpec,0}};
#define boxvar_AbsynToSCode_checkTypeSpec MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_checkTypeSpec)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEach(threadData_t *threadData, modelica_metatype _inAEach);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateEach,2,0) {(void*) boxptr_AbsynToSCode_translateEach,0}};
#define boxvar_AbsynToSCode_translateEach MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateEach)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_makeTypeVarElement(threadData_t *threadData, modelica_string _str, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_makeTypeVarElement,2,0) {(void*) boxptr_AbsynToSCode_makeTypeVarElement,0}};
#define boxvar_AbsynToSCode_makeTypeVarElement MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_makeTypeVarElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateSub(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inMod, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateSub,2,0) {(void*) boxptr_AbsynToSCode_translateSub,0}};
#define boxvar_AbsynToSCode_translateSub MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateSub)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateArgs(threadData_t *threadData, modelica_metatype _args);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateArgs,2,0) {(void*) boxptr_AbsynToSCode_translateArgs,0}};
#define boxvar_AbsynToSCode_translateArgs MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateArgs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateElementAddinfo(threadData_t *threadData, modelica_metatype _elem, modelica_metatype _nfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateElementAddinfo,2,0) {(void*) boxptr_AbsynToSCode_translateElementAddinfo,0}};
#define boxvar_AbsynToSCode_translateElementAddinfo MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateElementAddinfo)
PROTECTED_FUNCTION_STATIC modelica_string omc_AbsynToSCode_translateIterator(threadData_t *threadData, modelica_metatype _inIterator, modelica_metatype _inInfo, modelica_metatype *out_outRange);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateIterator,2,0) {(void*) boxptr_AbsynToSCode_translateIterator,0}};
#define boxvar_AbsynToSCode_translateIterator MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateIterator)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEqBranch(threadData_t *threadData, modelica_metatype _inBranch, modelica_boolean _inIsInitial, modelica_metatype *out_outBody);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateEqBranch(threadData_t *threadData, modelica_metatype _inBranch, modelica_metatype _inIsInitial, modelica_metatype *out_outBody);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateEqBranch,2,0) {(void*) boxptr_AbsynToSCode_translateEqBranch,0}};
#define boxvar_AbsynToSCode_translateEqBranch MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateEqBranch)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEquation(threadData_t *threadData, modelica_metatype _inEquation, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_boolean _inIsInitial);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateEquation(threadData_t *threadData, modelica_metatype _inEquation, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inIsInitial);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateEquation,2,0) {(void*) boxptr_AbsynToSCode_translateEquation,0}};
#define boxvar_AbsynToSCode_translateEquation MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateEquation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateCommentSeparate(threadData_t *threadData, modelica_metatype _inComment, modelica_metatype *out_outStr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateCommentSeparate,2,0) {(void*) boxptr_AbsynToSCode_translateCommentSeparate,0}};
#define boxvar_AbsynToSCode_translateCommentSeparate MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateCommentSeparate)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateCommentList(threadData_t *threadData, modelica_metatype _inAnns, modelica_metatype _inString);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateCommentList,2,0) {(void*) boxptr_AbsynToSCode_translateCommentList,0}};
#define boxvar_AbsynToSCode_translateCommentList MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateCommentList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateComment(threadData_t *threadData, modelica_metatype _inComment);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateComment,2,0) {(void*) boxptr_AbsynToSCode_translateComment,0}};
#define boxvar_AbsynToSCode_translateComment MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateComment)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_getInfoAnnotationOrDefault2(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _default);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_getInfoAnnotationOrDefault2,2,0) {(void*) boxptr_AbsynToSCode_getInfoAnnotationOrDefault2,0}};
#define boxvar_AbsynToSCode_getInfoAnnotationOrDefault2 MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_getInfoAnnotationOrDefault2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_getInfoAnnotationOrDefault(threadData_t *threadData, modelica_metatype _comment, modelica_metatype _default);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_getInfoAnnotationOrDefault,2,0) {(void*) boxptr_AbsynToSCode_getInfoAnnotationOrDefault,0}};
#define boxvar_AbsynToSCode_getInfoAnnotationOrDefault MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_getInfoAnnotationOrDefault)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateCommentWithLineInfoChanges(threadData_t *threadData, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype *out_outInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateCommentWithLineInfoChanges,2,0) {(void*) boxptr_AbsynToSCode_translateCommentWithLineInfoChanges,0}};
#define boxvar_AbsynToSCode_translateCommentWithLineInfoChanges MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateCommentWithLineInfoChanges)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEEquations(threadData_t *threadData, modelica_metatype _inAbsynEquationItemLst, modelica_boolean _inIsInitial);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateEEquations(threadData_t *threadData, modelica_metatype _inAbsynEquationItemLst, modelica_metatype _inIsInitial);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateEEquations,2,0) {(void*) boxptr_AbsynToSCode_translateEEquations,0}};
#define boxvar_AbsynToSCode_translateEEquations MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateEEquations)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEquations(threadData_t *threadData, modelica_metatype _inAbsynEquationItemLst, modelica_boolean _inIsInitial);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateEquations(threadData_t *threadData, modelica_metatype _inAbsynEquationItemLst, modelica_metatype _inIsInitial);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateEquations,2,0) {(void*) boxptr_AbsynToSCode_translateEquations,0}};
#define boxvar_AbsynToSCode_translateEquations MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateEquations)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateVariability(threadData_t *threadData, modelica_metatype _inVariability);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateVariability,2,0) {(void*) boxptr_AbsynToSCode_translateVariability,0}};
#define boxvar_AbsynToSCode_translateVariability MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateVariability)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateParallelism(threadData_t *threadData, modelica_metatype _inParallelism);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateParallelism,2,0) {(void*) boxptr_AbsynToSCode_translateParallelism,0}};
#define boxvar_AbsynToSCode_translateParallelism MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateParallelism)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateConstrainClass(threadData_t *threadData, modelica_metatype _inConstrainClass);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateConstrainClass,2,0) {(void*) boxptr_AbsynToSCode_translateConstrainClass,0}};
#define boxvar_AbsynToSCode_translateConstrainClass MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateConstrainClass)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynToSCode_translateRedeclarekeywords(threadData_t *threadData, modelica_metatype _inRedeclKeywords, modelica_boolean *out_outIsRedeclared);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateRedeclarekeywords(threadData_t *threadData, modelica_metatype _inRedeclKeywords, modelica_metatype *out_outIsRedeclared);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateRedeclarekeywords,2,0) {(void*) boxptr_AbsynToSCode_translateRedeclarekeywords,0}};
#define boxvar_AbsynToSCode_translateRedeclarekeywords MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateRedeclarekeywords)
PROTECTED_FUNCTION_STATIC void omc_AbsynToSCode_setHasStreamConnectorsHandler(threadData_t *threadData, modelica_boolean _streamPrefix);
PROTECTED_FUNCTION_STATIC void boxptr_AbsynToSCode_setHasStreamConnectorsHandler(threadData_t *threadData, modelica_metatype _streamPrefix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_setHasStreamConnectorsHandler,2,0) {(void*) boxptr_AbsynToSCode_setHasStreamConnectorsHandler,0}};
#define boxvar_AbsynToSCode_setHasStreamConnectorsHandler MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_setHasStreamConnectorsHandler)
PROTECTED_FUNCTION_STATIC void omc_AbsynToSCode_setHasInnerOuterDefinitionsHandler(threadData_t *threadData, modelica_metatype _io);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_setHasInnerOuterDefinitionsHandler,2,0) {(void*) boxptr_AbsynToSCode_setHasInnerOuterDefinitionsHandler,0}};
#define boxvar_AbsynToSCode_setHasInnerOuterDefinitionsHandler MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_setHasInnerOuterDefinitionsHandler)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateGroupImport(threadData_t *threadData, modelica_metatype _gimp, modelica_metatype _prefix, modelica_metatype _visibility, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateGroupImport,2,0) {(void*) boxptr_AbsynToSCode_translateGroupImport,0}};
#define boxvar_AbsynToSCode_translateGroupImport MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateGroupImport)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateImports(threadData_t *threadData, modelica_metatype _imp, modelica_metatype _visibility, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateImports,2,0) {(void*) boxptr_AbsynToSCode_translateImports,0}};
#define boxvar_AbsynToSCode_translateImports MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateImports)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateElementspec(threadData_t *threadData, modelica_metatype _cc, modelica_boolean _finalPrefix, modelica_metatype _io, modelica_metatype _inRedeclareKeywords, modelica_metatype _inVisibility, modelica_metatype _inElementSpec4, modelica_metatype _inInfo);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateElementspec(threadData_t *threadData, modelica_metatype _cc, modelica_metatype _finalPrefix, modelica_metatype _io, modelica_metatype _inRedeclareKeywords, modelica_metatype _inVisibility, modelica_metatype _inElementSpec4, modelica_metatype _inInfo);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateElementspec,2,0) {(void*) boxptr_AbsynToSCode_translateElementspec,0}};
#define boxvar_AbsynToSCode_translateElementspec MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateElementspec)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateDefineunitParam2(threadData_t *threadData, modelica_metatype _inArgs, modelica_string _inArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateDefineunitParam2,2,0) {(void*) boxptr_AbsynToSCode_translateDefineunitParam2,0}};
#define boxvar_AbsynToSCode_translateDefineunitParam2 MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateDefineunitParam2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateDefineunitParam(threadData_t *threadData, modelica_metatype _inArgs, modelica_string _inArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateDefineunitParam,2,0) {(void*) boxptr_AbsynToSCode_translateDefineunitParam,0}};
#define boxvar_AbsynToSCode_translateDefineunitParam MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateDefineunitParam)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefExternaldecls(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefExternaldecls,2,0) {(void*) boxptr_AbsynToSCode_translateClassdefExternaldecls,0}};
#define boxvar_AbsynToSCode_translateClassdefExternaldecls MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefExternaldecls)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateAlgBranches(threadData_t *threadData, modelica_metatype _inBranches);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateAlgBranches,2,0) {(void*) boxptr_AbsynToSCode_translateAlgBranches,0}};
#define boxvar_AbsynToSCode_translateAlgBranches MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateAlgBranches)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefAlgorithmItem(threadData_t *threadData, modelica_metatype _inAlgorithm);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefAlgorithmItem,2,0) {(void*) boxptr_AbsynToSCode_translateClassdefAlgorithmItem,0}};
#define boxvar_AbsynToSCode_translateClassdefAlgorithmItem MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefAlgorithmItem)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefInitialalgorithms(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefInitialalgorithms,2,0) {(void*) boxptr_AbsynToSCode_translateClassdefInitialalgorithms,0}};
#define boxvar_AbsynToSCode_translateClassdefInitialalgorithms MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefInitialalgorithms)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefConstraints(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefConstraints,2,0) {(void*) boxptr_AbsynToSCode_translateClassdefConstraints,0}};
#define boxvar_AbsynToSCode_translateClassdefConstraints MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefConstraints)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefAlgorithms(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefAlgorithms,2,0) {(void*) boxptr_AbsynToSCode_translateClassdefAlgorithms,0}};
#define boxvar_AbsynToSCode_translateClassdefAlgorithms MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefAlgorithms)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefInitialequations(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefInitialequations,2,0) {(void*) boxptr_AbsynToSCode_translateClassdefInitialequations,0}};
#define boxvar_AbsynToSCode_translateClassdefInitialequations MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefInitialequations)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefEquations(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefEquations,2,0) {(void*) boxptr_AbsynToSCode_translateClassdefEquations,0}};
#define boxvar_AbsynToSCode_translateClassdefEquations MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdefEquations)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEnumlist(threadData_t *threadData, modelica_metatype _inAbsynEnumLiteralLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateEnumlist,2,0) {(void*) boxptr_AbsynToSCode_translateEnumlist,0}};
#define boxvar_AbsynToSCode_translateEnumlist MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateEnumlist)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_mergeSCodeAnnotationsFromParts(threadData_t *threadData, modelica_metatype _part, modelica_metatype _inMod);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_mergeSCodeAnnotationsFromParts,2,0) {(void*) boxptr_AbsynToSCode_mergeSCodeAnnotationsFromParts,0}};
#define boxvar_AbsynToSCode_mergeSCodeAnnotationsFromParts MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_mergeSCodeAnnotationsFromParts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateAlternativeExternalAnnotation(threadData_t *threadData, modelica_metatype _decl, modelica_metatype _comment);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateAlternativeExternalAnnotation,2,0) {(void*) boxptr_AbsynToSCode_translateAlternativeExternalAnnotation,0}};
#define boxvar_AbsynToSCode_translateAlternativeExternalAnnotation MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateAlternativeExternalAnnotation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdef(threadData_t *threadData, modelica_metatype _inClassDef, modelica_metatype _info, modelica_metatype _re, modelica_metatype *out_outComment);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdef,2,0) {(void*) boxptr_AbsynToSCode_translateClassdef,0}};
#define boxvar_AbsynToSCode_translateClassdef MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClassdef)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateConnectorType(threadData_t *threadData, modelica_boolean _inFlow, modelica_boolean _inStream);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateConnectorType(threadData_t *threadData, modelica_metatype _inFlow, modelica_metatype _inStream);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateConnectorType,2,0) {(void*) boxptr_AbsynToSCode_translateConnectorType,0}};
#define boxvar_AbsynToSCode_translateConnectorType MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateConnectorType)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateAttributes(threadData_t *threadData, modelica_metatype _inEA, modelica_metatype _extraArrayDim);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateAttributes,2,0) {(void*) boxptr_AbsynToSCode_translateAttributes,0}};
#define boxvar_AbsynToSCode_translateAttributes MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateAttributes)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynToSCode_containsExternalFuncDecl(threadData_t *threadData, modelica_metatype _inClass);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_containsExternalFuncDecl(threadData_t *threadData, modelica_metatype _inClass);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_containsExternalFuncDecl,2,0) {(void*) boxptr_AbsynToSCode_containsExternalFuncDecl,0}};
#define boxvar_AbsynToSCode_containsExternalFuncDecl MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_containsExternalFuncDecl)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClass2(threadData_t *threadData, modelica_metatype _inClass, modelica_integer _inNumMessages);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateClass2(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inNumMessages);
static const MMC_DEFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClass2,2,0) {(void*) boxptr_AbsynToSCode_translateClass2,0}};
#define boxvar_AbsynToSCode_translateClass2 MMC_REFSTRUCTLIT(boxvar_lit_AbsynToSCode_translateClass2)
PROTECTED_FUNCTION_STATIC void omc_AbsynToSCode_checkTypeSpec(threadData_t *threadData, modelica_metatype _ts, modelica_metatype _info)
{
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ts;
{
modelica_metatype _tss = NULL;
modelica_metatype _ts2 = NULL;
modelica_string _str = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (5 != MMC_STRLEN(tmpMeta[1]) || strcmp(MMC_STRINGDATA(_OMC_LIT26), MMC_STRINGDATA(tmpMeta[1])) != 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
_ts2 = tmpMeta[3];
_str = omc_AbsynUtil_typeSpecString(threadData, _ts);
tmpMeta[0] = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT4, tmpMeta[0], _info);
_ts = _ts2;
goto _tailrecursive;
;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (5 != MMC_STRLEN(tmpMeta[1]) || strcmp(MMC_STRINGDATA(_OMC_LIT26), MMC_STRINGDATA(tmpMeta[1])) != 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
_tss = tmpMeta[2];
omc_List_map1__0(threadData, _tss, boxvar_AbsynToSCode_checkTypeSpec, _info);
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[0])) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (!listEmpty(tmpMeta[2])) goto tmp2_end;
_ts2 = tmpMeta[1];
_ts = _ts2;
goto _tailrecursive;
;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_tss = tmpMeta[0];
if(listMember((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ts), 2))), _OMC_LIT25))
{
_str = omc_AbsynUtil_typeSpecString(threadData, _ts);
tmpMeta[0] = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT7, tmpMeta[0], _info);
omc_List_map1__0(threadData, _tss, boxvar_AbsynToSCode_checkTypeSpec, _info);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEach(threadData_t *threadData, modelica_metatype _inAEach)
{
modelica_metatype _outSEach = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAEach;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT27;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT28;
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
_outSEach = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outSEach;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_makeTypeVarElement(threadData_t *threadData, modelica_string _str, modelica_metatype _info)
{
modelica_metatype _elt = NULL;
modelica_metatype _cd = NULL;
modelica_metatype _ts = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ts = _OMC_LIT33;
tmpMeta[0] = mmc_mk_box4(5, &SCode_ClassDef_DERIVED__desc, _ts, _OMC_LIT34, _OMC_LIT40);
_cd = tmpMeta[0];
tmpMeta[0] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _str, _OMC_LIT46, _OMC_LIT47, _OMC_LIT48, _OMC_LIT49, _cd, _OMC_LIT50, _info);
_elt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _elt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateSub(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inMod, modelica_metatype _info)
{
modelica_metatype _outSubMod = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inPath;
tmp3_2 = _inMod;
{
modelica_string _i = NULL;
modelica_metatype _path = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _sub = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_i = tmpMeta[1];
_mod = tmp3_2;
tmpMeta[1] = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _i, _mod);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_i = tmpMeta[1];
_path = tmpMeta[2];
_mod = tmp3_2;
_sub = omc_AbsynToSCode_translateSub(threadData, _path, _mod, _info);
tmpMeta[1] = mmc_mk_cons(_sub, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _OMC_LIT51, _OMC_LIT28, tmpMeta[1], mmc_mk_none(), _info);
_mod = tmpMeta[2];
tmpMeta[1] = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _i, _mod);
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
_outSubMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outSubMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateArgs(threadData_t *threadData, modelica_metatype _args)
{
modelica_metatype _subMods = NULL;
modelica_metatype _smod = NULL;
modelica_metatype _elem = NULL;
modelica_metatype _sub = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_subMods = tmpMeta[0];
{
modelica_metatype _arg;
for (tmpMeta[1] = _args; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_arg = MMC_CAR(tmpMeta[1]);
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
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,6) == 0) goto tmp2_end;
_smod = omc_AbsynToSCode_translateMod(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 5))), omc_SCodeUtil_boolFinal(threadData, mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 2))))), omc_AbsynToSCode_translateEach(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 3)))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 7))));
if((!omc_SCodeUtil_isEmptyMod(threadData, _smod)))
{
_sub = omc_AbsynToSCode_translateSub(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 4))), _smod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 7))));
tmpMeta[3] = mmc_mk_cons(_sub, _subMods);
_subMods = tmpMeta[3];
}
tmpMeta[2] = _subMods;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,6) == 0) goto tmp2_end;
tmpMeta[3] = omc_AbsynToSCode_translateElementspec(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 6))), mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 2)))), _OMC_LIT44, mmc_mk_some((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 3)))), _OMC_LIT41, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 7))));
if (listEmpty(tmpMeta[3])) goto goto_1;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto goto_1;
_elem = tmpMeta[4];
tmpMeta[3] = mmc_mk_box4(4, &SCode_Mod_REDECL__desc, omc_SCodeUtil_boolFinal(threadData, mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 2))))), omc_AbsynToSCode_translateEach(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 4)))), _elem);
tmpMeta[4] = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, omc_AbsynUtil_elementSpecName(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 5)))), tmpMeta[3]);
_sub = tmpMeta[4];
tmpMeta[3] = mmc_mk_cons(_sub, _subMods);
tmpMeta[2] = tmpMeta[3];
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
_subMods = tmpMeta[2];
}
}
_subMods = listReverse(_subMods);
_return: OMC_LABEL_UNUSED
return _subMods;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateMod(threadData_t *threadData, modelica_metatype _inMod, modelica_metatype _finalPrefix, modelica_metatype _eachPrefix, modelica_metatype _info)
{
modelica_metatype _outMod = NULL;
modelica_metatype _args = NULL;
modelica_metatype _eqmod = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _binding = NULL;
modelica_boolean tmp6;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inMod;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_args = tmpMeta[3];
_eqmod = tmpMeta[4];
tmpMeta[0+0] = _args;
tmpMeta[0+1] = _eqmod;
goto tmp3_done;
}
case 1: {
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _OMC_LIT52;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_args = tmpMeta[0+0];
_eqmod = tmpMeta[0+1];
tmp6 = (modelica_boolean)listEmpty(_args);
if(tmp6)
{
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = tmpMeta[0];
}
else
{
tmpMeta[1] = omc_AbsynToSCode_translateArgs(threadData, _args);
}
_subs = tmpMeta[1];
{
modelica_metatype tmp9_1;
tmp9_1 = _eqmod;
{
volatile mmc_switch_type tmp9;
int tmp10;
tmp9 = 0;
for (; tmp9 < 2; tmp9++) {
switch (MMC_SWITCH_CAST(tmp9)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp9_1,1,2) == 0) goto tmp8_end;
tmpMeta[0] = mmc_mk_some((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqmod), 2))));
goto tmp8_done;
}
case 1: {
tmpMeta[0] = mmc_mk_none();
goto tmp8_done;
}
}
goto tmp8_end;
tmp8_end: ;
}
goto goto_7;
goto_7:;
MMC_THROW_INTERNAL();
goto tmp8_done;
tmp8_done:;
}
}
_binding = tmpMeta[0];
{
modelica_metatype tmp13_1;modelica_metatype tmp13_2;modelica_metatype tmp13_3;modelica_metatype tmp13_4;
tmp13_1 = _subs;
tmp13_2 = _binding;
tmp13_3 = _finalPrefix;
tmp13_4 = _eachPrefix;
{
volatile mmc_switch_type tmp13;
int tmp14;
tmp13 = 0;
for (; tmp13 < 2; tmp13++) {
switch (MMC_SWITCH_CAST(tmp13)) {
case 0: {
if (!listEmpty(tmp13_1)) goto tmp12_end;
if (!optionNone(tmp13_2)) goto tmp12_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp13_3,1,0) == 0) goto tmp12_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp13_4,1,0) == 0) goto tmp12_end;
tmpMeta[0] = _OMC_LIT34;
goto tmp12_done;
}
case 1: {
tmpMeta[1] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _finalPrefix, _eachPrefix, _subs, _binding, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp12_done;
}
}
goto tmp12_end;
tmp12_end: ;
}
goto goto_11;
goto_11:;
MMC_THROW_INTERNAL();
goto tmp12_done;
tmp12_done:;
}
}
_outMod = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateElementAddinfo(threadData_t *threadData, modelica_metatype _elem, modelica_metatype _nfo)
{
modelica_metatype _oelem = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _elem;
{
modelica_string _a1 = NULL;
modelica_metatype _a6 = NULL;
modelica_metatype _a7 = NULL;
modelica_metatype _a8 = NULL;
modelica_metatype _a10 = NULL;
modelica_metatype _a11 = NULL;
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
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
_a1 = tmpMeta[1];
_p = tmpMeta[2];
_a6 = tmpMeta[3];
_a7 = tmpMeta[4];
_a8 = tmpMeta[5];
_a10 = tmpMeta[6];
_a11 = tmpMeta[7];
tmpMeta[1] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _a1, _p, _a6, _a7, _a8, _a10, _a11, _nfo);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _elem;
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
_oelem = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _oelem;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_AbsynToSCode_translateIterator(threadData_t *threadData, modelica_metatype _inIterator, modelica_metatype _inInfo, modelica_metatype *out_outRange)
{
modelica_string _outName = NULL;
modelica_metatype _outRange = NULL;
modelica_metatype _guard_exp = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inIterator;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_outName = tmpMeta[1];
_guard_exp = tmpMeta[2];
_outRange = tmpMeta[3];
if(isSome(_guard_exp))
{
omc_Error_addSourceMessageAndFail(threadData, _OMC_LIT56, _OMC_LIT58, _inInfo);
}
_return: OMC_LABEL_UNUSED
if (out_outRange) { *out_outRange = _outRange; }
return _outName;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEqBranch(threadData_t *threadData, modelica_metatype _inBranch, modelica_boolean _inIsInitial, modelica_metatype *out_outBody)
{
modelica_metatype _outCondition = NULL;
modelica_metatype _outBody = NULL;
modelica_metatype _body = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inBranch;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_outCondition = tmpMeta[1];
_body = tmpMeta[2];
_outBody = omc_AbsynToSCode_translateEEquations(threadData, _body, _inIsInitial);
_return: OMC_LABEL_UNUSED
if (out_outBody) { *out_outBody = _outBody; }
return _outCondition;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateEqBranch(threadData_t *threadData, modelica_metatype _inBranch, modelica_metatype _inIsInitial, modelica_metatype *out_outBody)
{
modelica_integer tmp1;
modelica_metatype _outCondition = NULL;
tmp1 = mmc_unbox_integer(_inIsInitial);
_outCondition = omc_AbsynToSCode_translateEqBranch(threadData, _inBranch, tmp1, out_outBody);
return _outCondition;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEquation(threadData_t *threadData, modelica_metatype _inEquation, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_boolean _inIsInitial)
{
modelica_metatype _outEEquation = NULL;
modelica_metatype tmpMeta[14] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inEquation;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _else_branch = NULL;
modelica_metatype _body = NULL;
modelica_metatype _branches = NULL;
modelica_string _iter_name = NULL;
modelica_metatype _iter_range = NULL;
modelica_metatype _conditions = NULL;
modelica_metatype _bodies = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 12; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
_body = omc_AbsynToSCode_translateEEquations(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _inIsInitial);
_conditions = omc_List_map1__2(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))), boxvar_AbsynToSCode_translateEqBranch, mmc_mk_boolean(_inIsInitial) ,&_bodies);
tmpMeta[1] = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _conditions);
_conditions = tmpMeta[1];
_else_branch = omc_AbsynToSCode_translateEEquations(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 5))), _inIsInitial);
tmpMeta[1] = mmc_mk_cons(_body, _bodies);
tmpMeta[2] = mmc_mk_box6(3, &SCode_EEquation_EQ__IF__desc, _conditions, tmpMeta[1], _else_branch, _inComment, _inInfo);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,3) == 0) goto tmp2_end;
_body = omc_AbsynToSCode_translateEEquations(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _inIsInitial);
_conditions = omc_List_map1__2(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))), boxvar_AbsynToSCode_translateEqBranch, mmc_mk_boolean(_inIsInitial) ,&_bodies);
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar0;
int tmp6;
modelica_metatype _b_loopVar = 0;
modelica_metatype _b;
modelica_metatype _c_loopVar = 0;
modelica_metatype _c;
_b_loopVar = _bodies;
_c_loopVar = _conditions;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[2];
tmp5 = &__omcQ_24tmpVar1;
while(1) {
tmp6 = 2;
if (!listEmpty(_b_loopVar)) {
_b = MMC_CAR(_b_loopVar);
_b_loopVar = MMC_CDR(_b_loopVar);
tmp6--;
}if (!listEmpty(_c_loopVar)) {
_c = MMC_CAR(_c_loopVar);
_c_loopVar = MMC_CDR(_c_loopVar);
tmp6--;
}
if (tmp6 == 0) {
tmpMeta[3] = mmc_mk_box2(0, _c, _b);
__omcQ_24tmpVar0 = tmpMeta[3];
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 2) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar1;
}
_branches = tmpMeta[1];
tmpMeta[1] = mmc_mk_box6(8, &SCode_EEquation_EQ__WHEN__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _body, _branches, _inComment, _inInfo);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,2) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box5(4, &SCode_EEquation_EQ__EQUALS__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _inComment, _inInfo);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,3) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box6(5, &SCode_EEquation_EQ__PDE__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))), _inComment, _inInfo);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,2) == 0) goto tmp2_end;
if(_inIsInitial)
{
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessageAndFail(threadData, _OMC_LIT61, tmpMeta[1], _inInfo);
}
tmpMeta[1] = mmc_mk_box5(6, &SCode_EEquation_EQ__CONNECT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _inComment, _inInfo);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,2) == 0) goto tmp2_end;
_body = omc_AbsynToSCode_translateEEquations(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _inIsInitial);
{
modelica_metatype _i;
for (tmpMeta[1] = listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2)))); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_i = MMC_CAR(tmpMeta[1]);
_iter_name = omc_AbsynToSCode_translateIterator(threadData, _i, _inInfo ,&_iter_range);
tmpMeta[3] = mmc_mk_box6(7, &SCode_EEquation_EQ__FOR__desc, _iter_name, _iter_range, _body, _inComment, _inInfo);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
_body = tmpMeta[2];
}
}
tmpMeta[0] = listHead(_body);
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (!listEmpty(tmpMeta[9])) goto tmp2_end;
_e1 = tmpMeta[5];
_e2 = tmpMeta[7];
tmpMeta[1] = mmc_mk_box6(9, &SCode_EEquation_EQ__ASSERT__desc, _e1, _e2, _OMC_LIT67, _inComment, _inInfo);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_e1 = tmpMeta[5];
_e2 = tmpMeta[7];
_e3 = tmpMeta[9];
tmpMeta[1] = mmc_mk_box6(9, &SCode_EEquation_EQ__ASSERT__desc, _e1, _e2, _e3, _inComment, _inInfo);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 2));
if (5 != MMC_STRLEN(tmpMeta[12]) || strcmp(MMC_STRINGDATA(_OMC_LIT69), MMC_STRINGDATA(tmpMeta[12])) != 0) goto tmp2_end;
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 3));
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_e1 = tmpMeta[5];
_e2 = tmpMeta[7];
_e3 = tmpMeta[13];
tmpMeta[1] = mmc_mk_box6(9, &SCode_EEquation_EQ__ASSERT__desc, _e1, _e2, _e3, _inComment, _inInfo);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (9 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT70), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e1 = tmpMeta[5];
tmpMeta[1] = mmc_mk_box4(10, &SCode_EEquation_EQ__TERMINATE__desc, _e1, _inComment, _inInfo);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT71), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (!listEmpty(tmpMeta[9])) goto tmp2_end;
_e1 = tmpMeta[5];
_e2 = tmpMeta[7];
tmpMeta[1] = mmc_mk_box5(11, &SCode_EEquation_EQ__REINIT__desc, _e1, _e2, _inComment, _inInfo);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = mmc_mk_box4(14, &Absyn_Exp_CALL__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), tmpMeta[1]);
tmpMeta[3] = mmc_mk_box4(12, &SCode_EEquation_EQ__NORETCALL__desc, tmpMeta[2], _inComment, _inInfo);
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
_outEEquation = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outEEquation;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateEquation(threadData_t *threadData, modelica_metatype _inEquation, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype _inIsInitial)
{
modelica_integer tmp1;
modelica_metatype _outEEquation = NULL;
tmp1 = mmc_unbox_integer(_inIsInitial);
_outEEquation = omc_AbsynToSCode_translateEquation(threadData, _inEquation, _inComment, _inInfo, tmp1);
return _outEEquation;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateCommentSeparate(threadData_t *threadData, modelica_metatype _inComment, modelica_metatype *out_outStr)
{
modelica_metatype _outAnn = NULL;
modelica_metatype _outStr = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComment;
{
modelica_metatype _absann = NULL;
modelica_metatype _ann = NULL;
modelica_string _str = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = mmc_mk_none();
goto tmp3_done;
}
case 1: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (!optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (!optionNone(tmpMeta[4])) goto tmp3_end;
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = mmc_mk_none();
goto tmp3_done;
}
case 2: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (!optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (optionNone(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 1));
_str = tmpMeta[5];
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = mmc_mk_some(_str);
goto tmp3_done;
}
case 3: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (!optionNone(tmpMeta[5])) goto tmp3_end;
_absann = tmpMeta[4];
_ann = omc_AbsynToSCode_translateAnnotation(threadData, _absann);
tmpMeta[0+0] = _ann;
tmpMeta[0+1] = mmc_mk_none();
goto tmp3_done;
}
case 4: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
_absann = tmpMeta[4];
_str = tmpMeta[6];
_ann = omc_AbsynToSCode_translateAnnotation(threadData, _absann);
tmpMeta[0+0] = _ann;
tmpMeta[0+1] = mmc_mk_some(_str);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outAnn = tmpMeta[0+0];
_outStr = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outStr) { *out_outStr = _outStr; }
return _outAnn;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateCommentList(threadData_t *threadData, modelica_metatype _inAnns, modelica_metatype _inString)
{
modelica_metatype _outComment = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAnns;
{
modelica_metatype _absann = NULL;
modelica_metatype _anns = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _ostr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, mmc_mk_none(), _inString);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (!listEmpty(tmpMeta[2])) goto tmp2_end;
_absann = tmpMeta[1];
_ann = omc_AbsynToSCode_translateAnnotation(threadData, _absann);
_ostr = omc_Util_applyOption(threadData, _inString, boxvar_System_unescapedString);
tmpMeta[1] = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, _ann, _ostr);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_absann = tmpMeta[1];
_anns = tmpMeta[2];
_absann = omc_List_fold(threadData, _anns, boxvar_AbsynUtil_mergeAnnotations, _absann);
_ann = omc_AbsynToSCode_translateAnnotation(threadData, _absann);
_ostr = omc_Util_applyOption(threadData, _inString, boxvar_System_unescapedString);
tmpMeta[1] = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, _ann, _ostr);
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
_outComment = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outComment;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateComment(threadData_t *threadData, modelica_metatype _inComment)
{
modelica_metatype _outComment = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inComment;
{
modelica_metatype _absann = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _ostr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _OMC_LIT50;
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_absann = tmpMeta[2];
_ostr = tmpMeta[3];
_ann = omc_AbsynToSCode_translateAnnotationOpt(threadData, _absann);
_ostr = omc_Util_applyOption(threadData, _ostr, boxvar_System_unescapedString);
tmpMeta[1] = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, _ann, _ostr);
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
_outComment = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outComment;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_getInfoAnnotationOrDefault2(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _default)
{
modelica_metatype _info = NULL;
modelica_metatype tmpMeta[14] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _lst;
{
modelica_metatype _rest = NULL;
modelica_string _fileName = NULL;
modelica_integer _line;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _default;
goto tmp2_done;
}
case 1: {
modelica_integer tmp5;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (23 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT73), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,5) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 5));
if (optionNone(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],16,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[8] = MMC_CAR(tmpMeta[7]);
tmpMeta[9] = MMC_CDR(tmpMeta[7]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],3,1) == 0) goto tmp2_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[11] = MMC_CAR(tmpMeta[9]);
tmpMeta[12] = MMC_CDR(tmpMeta[9]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[11],0,1) == 0) goto tmp2_end;
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[13]);
if (!listEmpty(tmpMeta[12])) goto tmp2_end;
_fileName = tmpMeta[10];
_line = tmp5;
tmpMeta[1] = mmc_mk_box8(3, &SourceInfo_SOURCEINFO__desc, _fileName, mmc_mk_boolean(0), mmc_mk_integer(_line), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(_line), mmc_mk_integer(((modelica_integer) 0)), _OMC_LIT72);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
_lst = _rest;
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
_info = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _info;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_getInfoAnnotationOrDefault(threadData_t *threadData, modelica_metatype _comment, modelica_metatype _default)
{
modelica_metatype _info = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _comment;
{
modelica_metatype _lst = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,5) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 4));
_lst = tmpMeta[4];
tmpMeta[0] = omc_AbsynToSCode_getInfoAnnotationOrDefault2(threadData, _lst, _default);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _default;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateCommentWithLineInfoChanges(threadData_t *threadData, modelica_metatype _inComment, modelica_metatype _inInfo, modelica_metatype *out_outInfo)
{
modelica_metatype _outComment = NULL;
modelica_metatype _outInfo = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outComment = omc_AbsynToSCode_translateComment(threadData, _inComment);
_outInfo = omc_AbsynToSCode_getInfoAnnotationOrDefault(threadData, _outComment, _inInfo);
_return: OMC_LABEL_UNUSED
if (out_outInfo) { *out_outInfo = _outInfo; }
return _outComment;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEEquations(threadData_t *threadData, modelica_metatype _inAbsynEquationItemLst, modelica_boolean _inIsInitial)
{
modelica_metatype _outEEquationLst = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAbsynEquationItemLst;
{
modelica_metatype _e_1 = NULL;
modelica_metatype _es_1 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _es = NULL;
modelica_metatype _acom = NULL;
modelica_metatype _com = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_e = tmpMeta[3];
_acom = tmpMeta[4];
_info = tmpMeta[5];
_es = tmpMeta[2];
_com = omc_AbsynToSCode_translateCommentWithLineInfoChanges(threadData, _acom, _info ,&_info);
_e_1 = omc_AbsynToSCode_translateEquation(threadData, _e, _com, _info, _inIsInitial);
_es_1 = omc_AbsynToSCode_translateEEquations(threadData, _es, _inIsInitial);
tmpMeta[1] = mmc_mk_cons(_e_1, _es_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
_es = tmpMeta[2];
_inAbsynEquationItemLst = _es;
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
_outEEquationLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outEEquationLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateEEquations(threadData_t *threadData, modelica_metatype _inAbsynEquationItemLst, modelica_metatype _inIsInitial)
{
modelica_integer tmp1;
modelica_metatype _outEEquationLst = NULL;
tmp1 = mmc_unbox_integer(_inIsInitial);
_outEEquationLst = omc_AbsynToSCode_translateEEquations(threadData, _inAbsynEquationItemLst, tmp1);
return _outEEquationLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEquations(threadData_t *threadData, modelica_metatype _inAbsynEquationItemLst, modelica_boolean _inIsInitial)
{
modelica_metatype _outEquationLst = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar2;
int tmp6;
modelica_metatype _eq_loopVar = 0;
modelica_boolean tmp7 = 0;
modelica_metatype _eq;
_eq_loopVar = _inAbsynEquationItemLst;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar3;
while(1) {
tmp6 = 1;
while (!listEmpty(_eq_loopVar)) {
_eq = MMC_CAR(_eq_loopVar);
_eq_loopVar = MMC_CDR(_eq_loopVar);
{
modelica_metatype tmp10_1;
tmp10_1 = _eq;
{
volatile mmc_switch_type tmp10;
int tmp11;
tmp10 = 0;
for (; tmp10 < 2; tmp10++) {
switch (MMC_SWITCH_CAST(tmp10)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp10_1,0,3) == 0) goto tmp9_end;
tmp7 = 1;
goto tmp9_done;
}
case 1: {
tmp7 = 0;
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
if (tmp7) {
tmp6--;
break;
}
}
if (tmp6 == 0) {
{
modelica_metatype tmp4_1;
tmp4_1 = _eq;
{
modelica_metatype _com = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,3) == 0) goto tmp3_end;
_com = omc_AbsynToSCode_translateCommentWithLineInfoChanges(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 4))) ,&_info);
tmpMeta[3] = mmc_mk_box2(3, &SCode_Equation_EQUATION__desc, omc_AbsynToSCode_translateEquation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 2))), _com, _info, _inIsInitial));
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}__omcQ_24tmpVar2 = tmpMeta[2];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp6 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar3;
}
_outEquationLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outEquationLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateEquations(threadData_t *threadData, modelica_metatype _inAbsynEquationItemLst, modelica_metatype _inIsInitial)
{
modelica_integer tmp1;
modelica_metatype _outEquationLst = NULL;
tmp1 = mmc_unbox_integer(_inIsInitial);
_outEquationLst = omc_AbsynToSCode_translateEquations(threadData, _inAbsynEquationItemLst, tmp1);
return _outEquationLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateVariability(threadData_t *threadData, modelica_metatype _inVariability)
{
modelica_metatype _outVariability = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVariability;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = _OMC_LIT37;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT74;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT75;
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _OMC_LIT76;
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
_outVariability = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outVariability;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateParallelism(threadData_t *threadData, modelica_metatype _inParallelism)
{
modelica_metatype _outParallelism = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inParallelism;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = _OMC_LIT77;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT78;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT36;
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
_outParallelism = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outParallelism;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateConstrainClass(threadData_t *threadData, modelica_metatype _inConstrainClass)
{
modelica_metatype _outConstrainClass = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inConstrainClass;
{
modelica_metatype _cc_path = NULL;
modelica_metatype _eltargs = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _cc_cmt = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _cc_mod = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_cc_path = tmpMeta[3];
_eltargs = tmpMeta[4];
_cmt = tmpMeta[5];
tmpMeta[1] = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _eltargs, _OMC_LIT52);
_mod = tmpMeta[1];
_cc_mod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(_mod), _OMC_LIT51, _OMC_LIT28, _OMC_LIT80);
_cc_cmt = omc_AbsynToSCode_translateComment(threadData, _cmt);
tmpMeta[1] = mmc_mk_box4(3, &SCode_ConstrainClass_CONSTRAINCLASS__desc, _cc_path, _cc_mod, _cc_cmt);
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
_outConstrainClass = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outConstrainClass;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynToSCode_translateRedeclarekeywords(threadData_t *threadData, modelica_metatype _inRedeclKeywords, modelica_boolean *out_outIsRedeclared)
{
modelica_boolean _outIsReplaceable;
modelica_boolean _outIsRedeclared;
modelica_boolean tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRedeclKeywords;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,0) == 0) goto tmp3_end;
tmp1_c0 = 0;
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,0) == 0) goto tmp3_end;
tmp1_c0 = 1;
tmp1_c1 = 0;
goto tmp3_done;
}
case 2: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,0) == 0) goto tmp3_end;
tmp1_c0 = 1;
tmp1_c1 = 1;
goto tmp3_done;
}
case 3: {
tmp1_c0 = 0;
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
_outIsReplaceable = tmp1_c0;
_outIsRedeclared = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outIsRedeclared) { *out_outIsRedeclared = _outIsRedeclared; }
return _outIsReplaceable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateRedeclarekeywords(threadData_t *threadData, modelica_metatype _inRedeclKeywords, modelica_metatype *out_outIsRedeclared)
{
modelica_boolean _outIsRedeclared;
modelica_boolean _outIsReplaceable;
modelica_metatype out_outIsReplaceable;
_outIsReplaceable = omc_AbsynToSCode_translateRedeclarekeywords(threadData, _inRedeclKeywords, &_outIsRedeclared);
out_outIsReplaceable = mmc_mk_icon(_outIsReplaceable);
if (out_outIsRedeclared) { *out_outIsRedeclared = mmc_mk_icon(_outIsRedeclared); }
return out_outIsReplaceable;
}
PROTECTED_FUNCTION_STATIC void omc_AbsynToSCode_setHasStreamConnectorsHandler(threadData_t *threadData, modelica_boolean _streamPrefix)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;
tmp3_1 = _streamPrefix;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (0 != tmp3_1) goto tmp2_end;
goto tmp2_done;
}
case 1: {
if (1 != tmp3_1) goto tmp2_end;
omc_System_setHasStreamConnectors(threadData, 1);
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
PROTECTED_FUNCTION_STATIC void boxptr_AbsynToSCode_setHasStreamConnectorsHandler(threadData_t *threadData, modelica_metatype _streamPrefix)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_streamPrefix);
omc_AbsynToSCode_setHasStreamConnectorsHandler(threadData, tmp1);
return;
}
PROTECTED_FUNCTION_STATIC void omc_AbsynToSCode_setHasInnerOuterDefinitionsHandler(threadData_t *threadData, modelica_metatype _io)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _io;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,0) == 0) goto tmp2_end;
goto tmp2_done;
}
case 1: {
omc_System_setHasInnerOuterDefinitions(threadData, 1);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateGroupImport(threadData_t *threadData, modelica_metatype _gimp, modelica_metatype _prefix, modelica_metatype _visibility, modelica_metatype _info)
{
modelica_metatype _elt = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _gimp;
tmp3_2 = _visibility;
{
modelica_string _name = NULL;
modelica_string _rename = NULL;
modelica_metatype _path = NULL;
modelica_metatype _vis = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_name = tmpMeta[1];
_vis = tmp3_2;
tmpMeta[1] = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
_path = omc_AbsynUtil_joinPaths(threadData, _prefix, tmpMeta[1]);
tmpMeta[1] = mmc_mk_box2(4, &Absyn_Import_QUAL__IMPORT__desc, _path);
tmpMeta[2] = mmc_mk_box4(3, &SCode_Element_IMPORT__desc, tmpMeta[1], _vis, _info);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_rename = tmpMeta[1];
_name = tmpMeta[2];
_vis = tmp3_2;
tmpMeta[1] = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
_path = omc_AbsynUtil_joinPaths(threadData, _prefix, tmpMeta[1]);
tmpMeta[1] = mmc_mk_box3(3, &Absyn_Import_NAMED__IMPORT__desc, _rename, _path);
tmpMeta[2] = mmc_mk_box4(3, &SCode_Element_IMPORT__desc, tmpMeta[1], _vis, _info);
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
_elt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _elt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateImports(threadData_t *threadData, modelica_metatype _imp, modelica_metatype _visibility, modelica_metatype _info)
{
modelica_metatype _elts = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _imp;
{
modelica_string _name = NULL;
modelica_metatype _p = NULL;
modelica_metatype _groups = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_name = tmpMeta[1];
_p = tmpMeta[3];
tmpMeta[1] = mmc_mk_box3(3, &Absyn_Import_NAMED__IMPORT__desc, _name, _p);
_imp = tmpMeta[1];
goto _tailrecursive;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_p = tmpMeta[2];
tmpMeta[1] = mmc_mk_box2(4, &Absyn_Import_QUAL__IMPORT__desc, _p);
_imp = tmpMeta[1];
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_p = tmpMeta[2];
tmpMeta[1] = mmc_mk_box2(5, &Absyn_Import_UNQUAL__IMPORT__desc, _p);
_imp = tmpMeta[1];
goto _tailrecursive;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_p = tmpMeta[1];
_groups = tmpMeta[2];
tmpMeta[0] = omc_List_map3(threadData, _groups, boxvar_AbsynToSCode_translateGroupImport, _p, _visibility, _info);
goto tmp2_done;
}
case 4: {
tmpMeta[2] = mmc_mk_box4(3, &SCode_Element_IMPORT__desc, _imp, _visibility, _info);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateElementspec(threadData_t *threadData, modelica_metatype _cc, modelica_boolean _finalPrefix, modelica_metatype _io, modelica_metatype _inRedeclareKeywords, modelica_metatype _inVisibility, modelica_metatype _inElementSpec4, modelica_metatype _inInfo)
{
modelica_metatype _outElementLst = NULL;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;modelica_metatype tmp3_4;
tmp3_1 = _inRedeclareKeywords;
tmp3_2 = _inVisibility;
tmp3_3 = _inElementSpec4;
tmp3_4 = _inInfo;
{
modelica_metatype _de_1 = NULL;
modelica_metatype _re_1 = NULL;
modelica_boolean _rp;
modelica_boolean _pa;
modelica_boolean _e;
modelica_boolean _repl_1;
modelica_boolean _fl;
modelica_boolean _st;
modelica_boolean _redecl;
modelica_metatype _repl = NULL;
modelica_metatype _cl = NULL;
modelica_string _n = NULL;
modelica_metatype _re = NULL;
modelica_metatype _de = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _args = NULL;
modelica_metatype _xs_1 = NULL;
modelica_metatype _prl1 = NULL;
modelica_metatype _var1 = NULL;
modelica_metatype _tot_dim = NULL;
modelica_metatype _ad = NULL;
modelica_metatype _d = NULL;
modelica_metatype _di = NULL;
modelica_metatype _isf = NULL;
modelica_metatype _t = NULL;
modelica_metatype _m = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _imp = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _path = NULL;
modelica_metatype _absann = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _variability = NULL;
modelica_metatype _parallelism = NULL;
modelica_metatype _i = NULL;
modelica_metatype _info = NULL;
modelica_metatype _cls = NULL;
modelica_metatype _sRed = NULL;
modelica_metatype _sFin = NULL;
modelica_metatype _sRep = NULL;
modelica_metatype _sEnc = NULL;
modelica_metatype _sPar = NULL;
modelica_metatype _vis = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _prefixes = NULL;
modelica_metatype _scc = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 8; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,0,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp6 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmp7 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],10,0) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
_rp = tmp5;
_n = tmpMeta[3];
_pa = tmp6;
_e = tmp7;
_de = tmpMeta[7];
_i = tmpMeta[8];
_repl = tmp3_1;
_vis = tmp3_2;
_de_1 = omc_AbsynToSCode_translateOperatorDef(threadData, _de, _n, _i ,&_cmt);
omc_AbsynToSCode_translateRedeclarekeywords(threadData, _repl ,&_redecl);
_sRed = omc_SCodeUtil_boolRedeclare(threadData, _redecl);
_sFin = omc_SCodeUtil_boolFinal(threadData, _finalPrefix);
_scc = omc_AbsynToSCode_translateConstrainClass(threadData, _cc);
tmp8 = (modelica_boolean)_rp;
if(tmp8)
{
tmpMeta[1] = mmc_mk_box2(3, &SCode_Replaceable_REPLACEABLE__desc, _scc);
tmpMeta[2] = tmpMeta[1];
}
else
{
tmpMeta[2] = _OMC_LIT45;
}
_sRep = tmpMeta[2];
_sEnc = omc_SCodeUtil_boolEncapsulated(threadData, _e);
_sPar = omc_SCodeUtil_boolPartial(threadData, _pa);
tmpMeta[1] = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _vis, _sRed, _sFin, _io, _sRep);
tmpMeta[2] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _n, tmpMeta[1], _sEnc, _sPar, _OMC_LIT81, _de_1, _cmt, _i);
_cls = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_cls, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_integer tmp9;
modelica_integer tmp10;
modelica_integer tmp11;
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,0,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp9 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp10 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmp11 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
_rp = tmp9;
_cl = tmpMeta[2];
_n = tmpMeta[3];
_pa = tmp10;
_e = tmp11;
_re = tmpMeta[6];
_de = tmpMeta[7];
_i = tmpMeta[8];
_repl = tmp3_1;
_vis = tmp3_2;
_re_1 = omc_AbsynToSCode_translateRestriction(threadData, _cl, _re);
_de_1 = omc_AbsynToSCode_translateClassdef(threadData, _de, _i, _re_1 ,&_cmt);
omc_AbsynToSCode_translateRedeclarekeywords(threadData, _repl ,&_redecl);
_sRed = omc_SCodeUtil_boolRedeclare(threadData, _redecl);
_sFin = omc_SCodeUtil_boolFinal(threadData, _finalPrefix);
_scc = omc_AbsynToSCode_translateConstrainClass(threadData, _cc);
tmp12 = (modelica_boolean)_rp;
if(tmp12)
{
tmpMeta[1] = mmc_mk_box2(3, &SCode_Replaceable_REPLACEABLE__desc, _scc);
tmpMeta[2] = tmpMeta[1];
}
else
{
tmpMeta[2] = _OMC_LIT45;
}
_sRep = tmpMeta[2];
_sEnc = omc_SCodeUtil_boolEncapsulated(threadData, _e);
_sPar = omc_SCodeUtil_boolPartial(threadData, _pa);
tmpMeta[1] = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _vis, _sRed, _sFin, _io, _sRep);
tmpMeta[2] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _n, tmpMeta[1], _sEnc, _sPar, _re_1, _de_1, _cmt, _i);
_cls = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_cls, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (!optionNone(tmpMeta[3])) goto tmp2_end;
_path = tmpMeta[1];
_args = tmpMeta[2];
_vis = tmp3_2;
_info = tmp3_4;
tmpMeta[1] = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _args, _OMC_LIT52);
_mod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta[1]), _OMC_LIT51, _OMC_LIT28, _OMC_LIT80);
tmpMeta[2] = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _path, _vis, _mod, mmc_mk_none(), _info);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (optionNone(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
_path = tmpMeta[1];
_args = tmpMeta[2];
_absann = tmpMeta[4];
_vis = tmp3_2;
_info = tmp3_4;
tmpMeta[1] = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _args, _OMC_LIT52);
_mod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta[1]), _OMC_LIT51, _OMC_LIT28, _OMC_LIT80);
_ann = omc_AbsynToSCode_translateAnnotation(threadData, _absann);
tmpMeta[2] = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _path, _vis, _mod, _ann, _info);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,3,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
modelica_integer tmp13;
modelica_integer tmp14;
modelica_boolean tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,3,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp13 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmp14 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
_fl = tmp13;
_st = tmp14;
_parallelism = tmpMeta[4];
_variability = tmpMeta[5];
_di = tmpMeta[6];
_isf = tmpMeta[7];
_ad = tmpMeta[8];
_t = tmpMeta[9];
_repl = tmp3_1;
_vis = tmp3_2;
_info = tmp3_4;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_xs_1 = tmpMeta[1];
{
modelica_metatype _comp;
for (tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElementSpec4), 4))); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_comp = MMC_CAR(tmpMeta[1]);
tmpMeta[2] = _comp;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_n = tmpMeta[4];
_d = tmpMeta[5];
_m = tmpMeta[6];
_cond = tmpMeta[7];
_comment = tmpMeta[8];
omc_AbsynToSCode_checkTypeSpec(threadData, _t, _info);
omc_AbsynToSCode_setHasInnerOuterDefinitionsHandler(threadData, _io);
omc_AbsynToSCode_setHasStreamConnectorsHandler(threadData, _st);
_mod = omc_AbsynToSCode_translateMod(threadData, _m, _OMC_LIT51, _OMC_LIT28, _info);
_prl1 = omc_AbsynToSCode_translateParallelism(threadData, _parallelism);
_var1 = omc_AbsynToSCode_translateVariability(threadData, _variability);
_tot_dim = listAppend(_d, _ad);
_repl_1 = omc_AbsynToSCode_translateRedeclarekeywords(threadData, _repl ,&_redecl);
_cmt = omc_AbsynToSCode_translateCommentWithLineInfoChanges(threadData, _comment, _info ,&_info);
_sFin = omc_SCodeUtil_boolFinal(threadData, _finalPrefix);
_sRed = omc_SCodeUtil_boolRedeclare(threadData, _redecl);
_scc = omc_AbsynToSCode_translateConstrainClass(threadData, _cc);
tmp15 = (modelica_boolean)_repl_1;
if(tmp15)
{
tmpMeta[2] = mmc_mk_box2(3, &SCode_Replaceable_REPLACEABLE__desc, _scc);
tmpMeta[3] = tmpMeta[2];
}
else
{
tmpMeta[3] = _OMC_LIT45;
}
_sRep = tmpMeta[3];
_ct = omc_AbsynToSCode_translateConnectorType(threadData, _fl, _st);
tmpMeta[2] = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _vis, _sRed, _sFin, _io, _sRep);
_prefixes = tmpMeta[2];
{
modelica_metatype tmp18_1;
tmp18_1 = _di;
{
modelica_metatype _attr1 = NULL;
modelica_metatype _attr2 = NULL;
modelica_metatype _mod2 = NULL;
modelica_string _inName = NULL;
volatile mmc_switch_type tmp18;
int tmp19;
tmp18 = 0;
for (; tmp18 < 2; tmp18++) {
switch (MMC_SWITCH_CAST(tmp18)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp18_1,3,0) == 0) goto tmp17_end;
if (!(!omc_Flags_isSet(threadData, _OMC_LIT88))) goto tmp17_end;
tmpMeta[3] = stringAppend(_OMC_LIT82,_n);
_inName = tmpMeta[3];
tmpMeta[3] = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _tot_dim, _ct, _prl1, _var1, _OMC_LIT83, _isf);
_attr1 = tmpMeta[3];
tmpMeta[3] = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _tot_dim, _ct, _prl1, _var1, _OMC_LIT84, _isf);
_attr2 = tmpMeta[3];
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[5] = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _inName, tmpMeta[4]);
tmpMeta[6] = mmc_mk_box2(5, &Absyn_Exp_CREF__desc, tmpMeta[5]);
tmpMeta[7] = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _OMC_LIT43, _OMC_LIT28, tmpMeta[3], mmc_mk_some(tmpMeta[6]), _info);
_mod2 = tmpMeta[7];
tmpMeta[4] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _n, _prefixes, _attr2, _t, _mod2, _cmt, _cond, _info);
tmpMeta[6] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _inName, _prefixes, _attr1, _t, _mod, _cmt, _cond, _info);
tmpMeta[5] = mmc_mk_cons(tmpMeta[6], _xs_1);
tmpMeta[3] = mmc_mk_cons(tmpMeta[4], tmpMeta[5]);
tmpMeta[2] = tmpMeta[3];
goto tmp17_done;
}
case 1: {
tmpMeta[4] = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _tot_dim, _ct, _prl1, _var1, _di, _isf);
tmpMeta[5] = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _n, _prefixes, tmpMeta[4], _t, _mod, _cmt, _cond, _info);
tmpMeta[3] = mmc_mk_cons(tmpMeta[5], _xs_1);
tmpMeta[2] = tmpMeta[3];
goto tmp17_done;
}
}
goto tmp17_end;
tmp17_end: ;
}
goto goto_16;
goto_16:;
goto goto_1;
goto tmp17_done;
tmp17_done:;
}
}
_xs_1 = tmpMeta[2];
}
}
tmpMeta[0] = listReverseInPlace(_xs_1);
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,2,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_imp = tmpMeta[1];
_info = tmpMeta[2];
_vis = tmp3_2;
tmpMeta[0] = omc_AbsynToSCode_translateImports(threadData, _imp, _vis, _info);
goto tmp2_done;
}
case 7: {
omc_Error_addMessage(threadData, _OMC_LIT56, _OMC_LIT90);
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
_outElementLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElementLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateElementspec(threadData_t *threadData, modelica_metatype _cc, modelica_metatype _finalPrefix, modelica_metatype _io, modelica_metatype _inRedeclareKeywords, modelica_metatype _inVisibility, modelica_metatype _inElementSpec4, modelica_metatype _inInfo)
{
modelica_integer tmp1;
modelica_metatype _outElementLst = NULL;
tmp1 = mmc_unbox_integer(_finalPrefix);
_outElementLst = omc_AbsynToSCode_translateElementspec(threadData, _cc, tmp1, _io, _inRedeclareKeywords, _inVisibility, _inElementSpec4, _inInfo);
return _outElementLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateDefineunitParam2(threadData_t *threadData, modelica_metatype _inArgs, modelica_string _inArg)
{
modelica_metatype _weightOpt = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_string tmp3_2;
tmp3_1 = _inArgs;
tmp3_2 = _inArg;
{
modelica_string _name = NULL;
modelica_string _arg = NULL;
modelica_string _s = NULL;
modelica_real _r;
modelica_metatype _args = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
_name = tmpMeta[3];
_s = tmpMeta[5];
_arg = tmp3_2;
if (!(stringEqual(_name, _arg))) goto tmp2_end;
_r = stringReal(_s);
tmpMeta[0] = mmc_mk_some(mmc_mk_real(_r));
goto tmp2_done;
}
case 1: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = mmc_mk_none();
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_args = tmpMeta[2];
_arg = tmp3_2;
_inArgs = _args;
_inArg = _arg;
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
_weightOpt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _weightOpt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateDefineunitParam(threadData_t *threadData, modelica_metatype _inArgs, modelica_string _inArg)
{
modelica_metatype _expOpt = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_string tmp3_2;
tmp3_1 = _inArgs;
tmp3_2 = _inArg;
{
modelica_string _str = NULL;
modelica_string _name = NULL;
modelica_string _arg = NULL;
modelica_metatype _args = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],3,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
_name = tmpMeta[3];
_str = tmpMeta[5];
_arg = tmp3_2;
if (!(stringEqual(_name, _arg))) goto tmp2_end;
tmpMeta[0] = mmc_mk_some(_str);
goto tmp2_done;
}
case 1: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = mmc_mk_none();
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_args = tmpMeta[2];
_arg = tmp3_2;
_inArgs = _args;
_inArg = _arg;
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
_expOpt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _expOpt;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateElement(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inVisibility)
{
modelica_metatype _outElementLst = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inElement;
tmp3_2 = _inVisibility;
{
modelica_boolean _f;
modelica_metatype _repl = NULL;
modelica_metatype _s = NULL;
modelica_metatype _io = NULL;
modelica_metatype _info = NULL;
modelica_metatype _cc = NULL;
modelica_metatype _expOpt = NULL;
modelica_metatype _weightOpt = NULL;
modelica_metatype _args = NULL;
modelica_string _name = NULL;
modelica_metatype _vis = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,6) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_f = tmp5;
_repl = tmpMeta[2];
_io = tmpMeta[3];
_s = tmpMeta[4];
_info = tmpMeta[5];
_cc = tmpMeta[6];
_vis = tmp3_2;
tmpMeta[0] = omc_AbsynToSCode_translateElementspec(threadData, _cc, _f, _io, _repl, _vis, _s, _info);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_name = tmpMeta[1];
_args = tmpMeta[2];
_info = tmpMeta[3];
_vis = tmp3_2;
_expOpt = omc_AbsynToSCode_translateDefineunitParam(threadData, _args, _OMC_LIT91);
_weightOpt = omc_AbsynToSCode_translateDefineunitParam2(threadData, _args, _OMC_LIT92);
tmpMeta[2] = mmc_mk_box6(7, &SCode_Element_DEFINEUNIT__desc, _name, _vis, _expOpt, _weightOpt, _info);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
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
_outElementLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElementLst;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateAnnotationOpt(threadData_t *threadData, modelica_metatype _absynAnnotation)
{
modelica_metatype _scodeAnnotation = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _absynAnnotation;
{
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_ann = tmpMeta[1];
tmpMeta[0] = omc_AbsynToSCode_translateAnnotation(threadData, _ann);
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
_scodeAnnotation = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _scodeAnnotation;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateAnnotation(threadData_t *threadData, modelica_metatype _inAnnotation)
{
modelica_metatype _outAnnotation = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAnnotation;
{
modelica_metatype _args = NULL;
modelica_metatype _m = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[0] = mmc_mk_none();
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_args = tmpMeta[1];
tmpMeta[1] = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _args, _OMC_LIT52);
_m = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta[1]), _OMC_LIT51, _OMC_LIT28, _OMC_LIT80);
tmp5 = (modelica_boolean)omc_SCodeUtil_isEmptyMod(threadData, _m);
if(tmp5)
{
tmpMeta[2] = mmc_mk_none();
}
else
{
tmpMeta[1] = mmc_mk_box2(3, &SCode_Annotation_ANNOTATION__desc, _m);
tmpMeta[2] = mmc_mk_some(tmpMeta[1]);
}
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
_outAnnotation = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAnnotation;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateEitemlist(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _inVisibility)
{
modelica_metatype _outElementLst = NULL;
modelica_metatype _l = NULL;
modelica_metatype _es = NULL;
modelica_metatype _ei = NULL;
modelica_metatype _vis = NULL;
modelica_metatype _e = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_l = tmpMeta[0];
_es = _inAbsynElementItemLst;
{
modelica_metatype _ei;
for (tmpMeta[1] = _es; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_ei = MMC_CAR(tmpMeta[1]);
{
modelica_metatype tmp3_1;
tmp3_1 = _ei;
{
modelica_metatype _e_1 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_e = tmpMeta[2];
_e_1 = omc_AbsynToSCode_translateElement(threadData, _e, _inVisibility);
_l = omc_List_append__reverse(threadData, _e_1, _l);
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
}
}
_outElementLst = listReverseInPlace(_l);
_return: OMC_LABEL_UNUSED
return _outElementLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefExternaldecls(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAbsynExternalDeclOption = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAbsynClassPartLst;
{
modelica_metatype _rest = NULL;
modelica_metatype _fn_name = NULL;
modelica_metatype _lang = NULL;
modelica_metatype _output_ = NULL;
modelica_metatype _args = NULL;
modelica_metatype _aann = NULL;
modelica_metatype _sann = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],7,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 5));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 6));
_fn_name = tmpMeta[4];
_lang = tmpMeta[5];
_output_ = tmpMeta[6];
_args = tmpMeta[7];
_aann = tmpMeta[8];
_sann = omc_AbsynToSCode_translateAnnotationOpt(threadData, _aann);
tmpMeta[1] = mmc_mk_box6(3, &SCode_ExternalDecl_EXTERNALDECL__desc, _fn_name, _lang, _output_, _args, _sann);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
_inAbsynClassPartLst = _rest;
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
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
_outAbsynExternalDeclOption = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAbsynExternalDeclOption;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateAlgBranches(threadData_t *threadData, modelica_metatype _inBranches)
{
modelica_metatype _outBranches = NULL;
modelica_metatype _condition = NULL;
modelica_metatype _body = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar4;
int tmp6;
modelica_metatype _branch_loopVar = 0;
modelica_metatype _branch;
_branch_loopVar = _inBranches;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar5;
while(1) {
tmp6 = 1;
if (!listEmpty(_branch_loopVar)) {
_branch = MMC_CAR(_branch_loopVar);
_branch_loopVar = MMC_CDR(_branch_loopVar);
tmp6--;
}
if (tmp6 == 0) {
{
modelica_metatype tmp4_1;
tmp4_1 = _branch;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_condition = tmpMeta[3];
_body = tmpMeta[4];
tmpMeta[3] = mmc_mk_box2(0, _condition, omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, _body));
tmpMeta[2] = tmpMeta[3];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}__omcQ_24tmpVar4 = tmpMeta[2];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp6 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar5;
}
_outBranches = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outBranches;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefAlgorithmItem(threadData_t *threadData, modelica_metatype _inAlgorithm)
{
modelica_metatype _outStatement = NULL;
modelica_metatype _absynComment = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _info = NULL;
modelica_metatype _alg = NULL;
modelica_metatype tmpMeta[14] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inAlgorithm;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_alg = tmpMeta[1];
_absynComment = tmpMeta[2];
_info = tmpMeta[3];
_comment = omc_AbsynToSCode_translateCommentWithLineInfoChanges(threadData, _absynComment, _info ,&_info);
{
modelica_metatype tmp3_1;
tmp3_1 = _alg;
{
modelica_metatype _body = NULL;
modelica_metatype _else_body = NULL;
modelica_metatype _branches = NULL;
modelica_string _iter_name = NULL;
modelica_metatype _iter_range = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 17; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box5(3, &SCode_Statement_ALG__ASSIGN__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))), _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,4) == 0) goto tmp2_end;
_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))));
_else_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 5))));
_branches = omc_AbsynToSCode_translateAlgBranches(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 4))));
tmpMeta[1] = mmc_mk_box7(4, &SCode_Statement_ALG__IF__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), _body, _branches, _else_body, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,2) == 0) goto tmp2_end;
_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))));
{
modelica_metatype _i;
for (tmpMeta[1] = listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2)))); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_i = MMC_CAR(tmpMeta[1]);
_iter_name = omc_AbsynToSCode_translateIterator(threadData, _i, _info ,&_iter_range);
tmpMeta[3] = mmc_mk_box6(5, &SCode_Statement_ALG__FOR__desc, _iter_name, _iter_range, _body, _comment, _info);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
_body = tmpMeta[2];
}
}
tmpMeta[0] = listHead(_body);
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,2) == 0) goto tmp2_end;
_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))));
{
modelica_metatype _i;
for (tmpMeta[1] = listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2)))); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_i = MMC_CAR(tmpMeta[1]);
_iter_name = omc_AbsynToSCode_translateIterator(threadData, _i, _info ,&_iter_range);
tmpMeta[3] = mmc_mk_box6(6, &SCode_Statement_ALG__PARFOR__desc, _iter_name, _iter_range, _body, _comment, _info);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
_body = tmpMeta[2];
}
}
tmpMeta[0] = listHead(_body);
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,2) == 0) goto tmp2_end;
_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))));
tmpMeta[1] = mmc_mk_box5(7, &SCode_Statement_ALG__WHILE__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), _body, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,3) == 0) goto tmp2_end;
tmpMeta[2] = mmc_mk_box2(0, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 4))));
_branches = omc_AbsynToSCode_translateAlgBranches(threadData, tmpMeta[1]);
tmpMeta[1] = mmc_mk_box4(8, &SCode_Statement_ALG__WHEN__A__desc, _branches, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (!listEmpty(tmpMeta[9])) goto tmp2_end;
_e1 = tmpMeta[5];
_e2 = tmpMeta[7];
tmpMeta[1] = mmc_mk_box6(9, &SCode_Statement_ALG__ASSERT__desc, _e1, _e2, _OMC_LIT67, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_e1 = tmpMeta[5];
_e2 = tmpMeta[7];
_e3 = tmpMeta[9];
tmpMeta[1] = mmc_mk_box6(9, &SCode_Statement_ALG__ASSERT__desc, _e1, _e2, _e3, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 2));
if (5 != MMC_STRLEN(tmpMeta[12]) || strcmp(MMC_STRINGDATA(_OMC_LIT69), MMC_STRINGDATA(tmpMeta[12])) != 0) goto tmp2_end;
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 3));
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_e1 = tmpMeta[5];
_e2 = tmpMeta[7];
_e3 = tmpMeta[13];
tmpMeta[1] = mmc_mk_box6(9, &SCode_Statement_ALG__ASSERT__desc, _e1, _e2, _e3, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (9 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT70), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e1 = tmpMeta[5];
tmpMeta[1] = mmc_mk_box4(10, &SCode_Statement_ALG__TERMINATE__desc, _e1, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT71), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (!listEmpty(tmpMeta[9])) goto tmp2_end;
_e1 = tmpMeta[5];
_e2 = tmpMeta[7];
tmpMeta[1] = mmc_mk_box5(11, &SCode_Statement_ALG__REINIT__desc, _e1, _e2, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = mmc_mk_box4(14, &Absyn_Exp_CALL__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))), tmpMeta[1]);
_e1 = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(12, &SCode_Statement_ALG__NORETCALL__desc, _e1, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,9,1) == 0) goto tmp2_end;
_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))));
tmpMeta[1] = mmc_mk_box4(15, &SCode_Statement_ALG__FAILURE__desc, _body, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,2) == 0) goto tmp2_end;
_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))));
_else_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))));
tmpMeta[1] = mmc_mk_box5(16, &SCode_Statement_ALG__TRY__desc, _body, _else_body, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,0) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box3(13, &SCode_Statement_ALG__RETURN__desc, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,0) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box3(14, &SCode_Statement_ALG__BREAK__desc, _comment, _info);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,11,0) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box3(17, &SCode_Statement_ALG__CONTINUE__desc, _comment, _info);
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
_outStatement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData_t *threadData, modelica_metatype _inStatements)
{
modelica_metatype _outStatements = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar6;
int tmp2;
modelica_metatype _stmt_loopVar = 0;
modelica_metatype _stmt;
_stmt_loopVar = _inStatements;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar7;
while(1) {
tmp2 = 1;
while (!listEmpty(_stmt_loopVar)) {
_stmt = MMC_CAR(_stmt_loopVar);
_stmt_loopVar = MMC_CDR(_stmt_loopVar);
if (omc_AbsynUtil_isAlgorithmItem(threadData, _stmt)) {
tmp2--;
break;
}
}
if (tmp2 == 0) {
__omcQ_24tmpVar6 = omc_AbsynToSCode_translateClassdefAlgorithmItem(threadData, _stmt);
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar7;
}
_outStatements = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outStatements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefInitialalgorithms(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAlgorithmLst = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAbsynClassPartLst;
{
modelica_metatype _als = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _al = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_al = tmpMeta[3];
_rest = tmpMeta[2];
_stmts = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, _al);
_als = omc_AbsynToSCode_translateClassdefInitialalgorithms(threadData, _rest);
tmpMeta[2] = mmc_mk_box2(3, &SCode_AlgorithmSection_ALGORITHM__desc, _stmts);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _als);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
_inAbsynClassPartLst = _rest;
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
_outAlgorithmLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAlgorithmLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefConstraints(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outConstraintLst = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAbsynClassPartLst;
{
modelica_metatype _cos = NULL;
modelica_metatype _consts = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_consts = tmpMeta[3];
_rest = tmpMeta[2];
_cos = omc_AbsynToSCode_translateClassdefConstraints(threadData, _rest);
tmpMeta[2] = mmc_mk_box2(3, &SCode_ConstraintSection_CONSTRAINTS__desc, _consts);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _cos);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
_inAbsynClassPartLst = _rest;
goto _tailrecursive;
goto tmp2_done;
}
case 3: {
modelica_boolean tmp5;
tmp5 = omc_Flags_isSet(threadData, _OMC_LIT96);
if (1 != tmp5) goto goto_1;
omc_Debug_trace(threadData, _OMC_LIT97);
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
_outConstraintLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outConstraintLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefAlgorithms(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAlgorithmLst = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAbsynClassPartLst;
{
modelica_metatype _als = NULL;
modelica_metatype _al_1 = NULL;
modelica_metatype _al = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_al = tmpMeta[3];
_rest = tmpMeta[2];
_al_1 = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, _al);
_als = omc_AbsynToSCode_translateClassdefAlgorithms(threadData, _rest);
tmpMeta[2] = mmc_mk_box2(3, &SCode_AlgorithmSection_ALGORITHM__desc, _al_1);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _als);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
_inAbsynClassPartLst = _rest;
goto _tailrecursive;
goto tmp2_done;
}
case 3: {
modelica_boolean tmp5;
tmp5 = omc_Flags_isSet(threadData, _OMC_LIT96);
if (1 != tmp5) goto goto_1;
omc_Debug_trace(threadData, _OMC_LIT98);
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
_outAlgorithmLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAlgorithmLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefInitialequations(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outEquationLst = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAbsynClassPartLst;
{
modelica_metatype _eqs = NULL;
modelica_metatype _eql_1 = NULL;
modelica_metatype _eql = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_eql = tmpMeta[3];
_rest = tmpMeta[2];
_eql_1 = omc_AbsynToSCode_translateEquations(threadData, _eql, 1);
_eqs = omc_AbsynToSCode_translateClassdefInitialequations(threadData, _rest);
tmpMeta[0] = listAppend(_eqs, _eql_1);
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
_inAbsynClassPartLst = _rest;
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
_outEquationLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outEquationLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefEquations(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outEquationLst = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAbsynClassPartLst;
{
modelica_metatype _eqs = NULL;
modelica_metatype _eql_1 = NULL;
modelica_metatype _eql = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_eql = tmpMeta[3];
_rest = tmpMeta[2];
_eql_1 = omc_AbsynToSCode_translateEquations(threadData, _eql, 0);
_eqs = omc_AbsynToSCode_translateClassdefEquations(threadData, _rest);
tmpMeta[0] = listAppend(_eqs, _eql_1);
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
_inAbsynClassPartLst = _rest;
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
_outEquationLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outEquationLst;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateClassdefElements(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outElementLst = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAbsynClassPartLst;
{
modelica_metatype _els = NULL;
modelica_metatype _es_1 = NULL;
modelica_metatype _es = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_es = tmpMeta[3];
_rest = tmpMeta[2];
_es_1 = omc_AbsynToSCode_translateEitemlist(threadData, _es, _OMC_LIT41);
_els = omc_AbsynToSCode_translateClassdefElements(threadData, _rest);
tmpMeta[0] = listAppend(_es_1, _els);
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_es = tmpMeta[3];
_rest = tmpMeta[2];
_es_1 = omc_AbsynToSCode_translateEitemlist(threadData, _es, _OMC_LIT99);
_els = omc_AbsynToSCode_translateClassdefElements(threadData, _rest);
tmpMeta[0] = listAppend(_es_1, _els);
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
_inAbsynClassPartLst = _rest;
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
_outElementLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElementLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEnumlist(threadData_t *threadData, modelica_metatype _inAbsynEnumLiteralLst)
{
modelica_metatype _outEnumLst = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAbsynEnumLiteralLst;
{
modelica_metatype _res = NULL;
modelica_string _id = NULL;
modelica_metatype _cmtOpt = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_id = tmpMeta[3];
_cmtOpt = tmpMeta[4];
_rest = tmpMeta[2];
_cmt = omc_AbsynToSCode_translateComment(threadData, _cmtOpt);
_res = omc_AbsynToSCode_translateEnumlist(threadData, _rest);
tmpMeta[2] = mmc_mk_box3(3, &SCode_Enum_ENUM__desc, _id, _cmt);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _res);
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
_outEnumLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outEnumLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_mergeSCodeAnnotationsFromParts(threadData_t *threadData, modelica_metatype _part, modelica_metatype _inMod)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _part;
{
modelica_metatype _aann = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_aann = tmpMeta[2];
_ann = omc_AbsynToSCode_translateAnnotation(threadData, _aann);
tmpMeta[0] = omc_SCodeUtil_mergeSCodeOptAnn(threadData, _ann, _inMod);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_rest = tmpMeta[3];
tmpMeta[1] = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, _rest);
_part = tmpMeta[1];
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_rest = tmpMeta[3];
tmpMeta[1] = mmc_mk_box2(4, &Absyn_ClassPart_PROTECTED__desc, _rest);
_part = tmpMeta[1];
goto _tailrecursive;
goto tmp2_done;
}
case 3: {
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateAlternativeExternalAnnotation(threadData_t *threadData, modelica_metatype _decl, modelica_metatype _comment)
{
modelica_metatype _outDecl = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _decl;
tmp3_2 = _comment;
{
modelica_metatype _name = NULL;
modelica_metatype _l = NULL;
modelica_metatype _out = NULL;
modelica_metatype _a = NULL;
modelica_metatype _ann1 = NULL;
modelica_metatype _ann2 = NULL;
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = mmc_mk_none();
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
_name = tmpMeta[2];
_l = tmpMeta[3];
_out = tmpMeta[4];
_a = tmpMeta[5];
_ann1 = tmpMeta[6];
_ann2 = tmpMeta[7];
_ann = omc_SCodeUtil_mergeSCodeOptAnn(threadData, _ann1, _ann2);
tmpMeta[1] = mmc_mk_box6(3, &SCode_ExternalDecl_EXTERNALDECL__desc, _name, _l, _out, _a, _ann);
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
_outDecl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDecl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdef(threadData_t *threadData, modelica_metatype _inClassDef, modelica_metatype _info, modelica_metatype _re, modelica_metatype *out_outComment)
{
modelica_metatype _outClassDef = NULL;
modelica_metatype _outComment = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClassDef;
{
modelica_metatype _mod = NULL;
modelica_metatype _t = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _a = NULL;
modelica_metatype _cmod = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _cmtString = NULL;
modelica_metatype _els = NULL;
modelica_metatype _tvels = NULL;
modelica_metatype _eqs = NULL;
modelica_metatype _initeqs = NULL;
modelica_metatype _als = NULL;
modelica_metatype _initals = NULL;
modelica_metatype _cos = NULL;
modelica_metatype _decl = NULL;
modelica_metatype _parts = NULL;
modelica_metatype _vars = NULL;
modelica_metatype _lst_1 = NULL;
modelica_metatype _lst = NULL;
modelica_metatype _scodeCmt = NULL;
modelica_metatype _path = NULL;
modelica_metatype _pathLst = NULL;
modelica_metatype _typeVars = NULL;
modelica_metatype _scodeAttr = NULL;
modelica_metatype _classAttrs = NULL;
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 8; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_t = tmpMeta[2];
_attr = tmpMeta[3];
_a = tmpMeta[4];
_cmt = tmpMeta[5];
omc_AbsynToSCode_checkTypeSpec(threadData, _t, _info);
tmpMeta[2] = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _a, _OMC_LIT52);
_mod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta[2]), _OMC_LIT51, _OMC_LIT28, _info);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_scodeAttr = omc_AbsynToSCode_translateAttributes(threadData, _attr, tmpMeta[2]);
_scodeCmt = omc_AbsynToSCode_translateComment(threadData, _cmt);
tmpMeta[2] = mmc_mk_box4(5, &SCode_ClassDef_DERIVED__desc, _t, _mod, _scodeAttr);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_typeVars = tmpMeta[2];
_classAttrs = tmpMeta[3];
_parts = tmpMeta[4];
_ann = tmpMeta[5];
_cmtString = tmpMeta[6];
{
modelica_metatype tmp8_1;
tmp8_1 = _re;
{
int tmp8;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp8_1))) {
case 20: {
tmpMeta[2] = omc_List_union(threadData, _typeVars, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_re), 6))));
goto tmp7_done;
}
case 21: {
tmpMeta[2] = omc_List_union(threadData, _typeVars, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_re), 2))));
goto tmp7_done;
}
default:
tmp7_default: OMC_LABEL_UNUSED; {
tmpMeta[2] = _typeVars;
goto tmp7_done;
}
}
goto tmp7_end;
tmp7_end: ;
}
goto goto_6;
goto_6:;
goto goto_2;
goto tmp7_done;
tmp7_done:;
}
}
_typeVars = tmpMeta[2];
_tvels = omc_List_map1(threadData, _typeVars, boxvar_AbsynToSCode_makeTypeVarElement, _info);
_els = omc_AbsynToSCode_translateClassdefElements(threadData, _parts);
_els = listAppend(_tvels, _els);
_eqs = omc_AbsynToSCode_translateClassdefEquations(threadData, _parts);
_initeqs = omc_AbsynToSCode_translateClassdefInitialequations(threadData, _parts);
_als = omc_AbsynToSCode_translateClassdefAlgorithms(threadData, _parts);
_initals = omc_AbsynToSCode_translateClassdefInitialalgorithms(threadData, _parts);
_cos = omc_AbsynToSCode_translateClassdefConstraints(threadData, _parts);
_scodeCmt = omc_AbsynToSCode_translateCommentList(threadData, _ann, _cmtString);
_decl = omc_AbsynToSCode_translateClassdefExternaldecls(threadData, _parts);
_decl = omc_AbsynToSCode_translateAlternativeExternalAnnotation(threadData, _decl, _scodeCmt);
tmpMeta[2] = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, _els, _eqs, _initeqs, _als, _initals, _cos, _classAttrs, _decl);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_lst = tmpMeta[3];
_cmt = tmpMeta[4];
_lst_1 = omc_AbsynToSCode_translateEnumlist(threadData, _lst);
_scodeCmt = omc_AbsynToSCode_translateComment(threadData, _cmt);
tmpMeta[2] = mmc_mk_box2(6, &SCode_ClassDef_ENUMERATION__desc, _lst_1);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,0) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cmt = tmpMeta[3];
_scodeCmt = omc_AbsynToSCode_translateComment(threadData, _cmt);
tmpMeta[0+0] = _OMC_LIT100;
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_pathLst = tmpMeta[2];
_cmt = tmpMeta[3];
_scodeCmt = omc_AbsynToSCode_translateComment(threadData, _cmt);
tmpMeta[2] = mmc_mk_box2(7, &SCode_ClassDef_OVERLOAD__desc, _pathLst);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_cmod = tmpMeta[2];
_cmtString = tmpMeta[3];
_parts = tmpMeta[4];
_ann = tmpMeta[5];
_els = omc_AbsynToSCode_translateClassdefElements(threadData, _parts);
_eqs = omc_AbsynToSCode_translateClassdefEquations(threadData, _parts);
_initeqs = omc_AbsynToSCode_translateClassdefInitialequations(threadData, _parts);
_als = omc_AbsynToSCode_translateClassdefAlgorithms(threadData, _parts);
_initals = omc_AbsynToSCode_translateClassdefInitialalgorithms(threadData, _parts);
_cos = omc_AbsynToSCode_translateClassdefConstraints(threadData, _parts);
tmpMeta[2] = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _cmod, _OMC_LIT52);
_mod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta[2]), _OMC_LIT51, _OMC_LIT28, _OMC_LIT80);
_scodeCmt = omc_AbsynToSCode_translateCommentList(threadData, _ann, _cmtString);
_decl = omc_AbsynToSCode_translateClassdefExternaldecls(threadData, _parts);
_decl = omc_AbsynToSCode_translateAlternativeExternalAnnotation(threadData, _decl, _scodeCmt);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, _els, _eqs, _initeqs, _als, _initals, _cos, tmpMeta[2], _decl);
tmpMeta[4] = mmc_mk_box3(4, &SCode_ClassDef_CLASS__EXTENDS__desc, _mod, tmpMeta[3]);
tmpMeta[0+0] = tmpMeta[4];
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_path = tmpMeta[2];
_vars = tmpMeta[3];
_cmt = tmpMeta[4];
_scodeCmt = omc_AbsynToSCode_translateComment(threadData, _cmt);
tmpMeta[2] = mmc_mk_box3(8, &SCode_ClassDef_PDER__desc, _path, _vars);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 7: {
omc_Error_addMessage(threadData, _OMC_LIT56, _OMC_LIT102);
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
_outClassDef = tmpMeta[0+0];
_outComment = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outComment) { *out_outComment = _outComment; }
return _outClassDef;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateConnectorType(threadData_t *threadData, modelica_boolean _inFlow, modelica_boolean _inStream)
{
modelica_metatype _outType = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;modelica_boolean tmp3_2;
tmp3_1 = _inFlow;
tmp3_2 = _inStream;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (0 != tmp3_1) goto tmp2_end;
if (0 != tmp3_2) goto tmp2_end;
tmpMeta[0] = _OMC_LIT35;
goto tmp2_done;
}
case 1: {
if (1 != tmp3_1) goto tmp2_end;
if (0 != tmp3_2) goto tmp2_end;
tmpMeta[0] = _OMC_LIT103;
goto tmp2_done;
}
case 2: {
if (0 != tmp3_1) goto tmp2_end;
if (1 != tmp3_2) goto tmp2_end;
tmpMeta[0] = _OMC_LIT104;
goto tmp2_done;
}
case 3: {
if (1 != tmp3_1) goto tmp2_end;
if (1 != tmp3_2) goto tmp2_end;
omc_Error_addMessage(threadData, _OMC_LIT56, _OMC_LIT106);
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
_outType = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outType;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateConnectorType(threadData_t *threadData, modelica_metatype _inFlow, modelica_metatype _inStream)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outType = NULL;
tmp1 = mmc_unbox_integer(_inFlow);
tmp2 = mmc_unbox_integer(_inStream);
_outType = omc_AbsynToSCode_translateConnectorType(threadData, tmp1, tmp2);
return _outType;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateAttributes(threadData_t *threadData, modelica_metatype _inEA, modelica_metatype _extraArrayDim)
{
modelica_metatype _outA = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inEA;
tmp3_2 = _extraArrayDim;
{
modelica_boolean _f;
modelica_boolean _s;
modelica_metatype _v = NULL;
modelica_metatype _p = NULL;
modelica_metatype _adim = NULL;
modelica_metatype _extraADim = NULL;
modelica_metatype _dir = NULL;
modelica_metatype _fi = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _sp = NULL;
modelica_metatype _sv = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_f = tmp5;
_s = tmp6;
_p = tmpMeta[3];
_v = tmpMeta[4];
_dir = tmpMeta[5];
_fi = tmpMeta[6];
_adim = tmpMeta[7];
_extraADim = tmp3_2;
_ct = omc_AbsynToSCode_translateConnectorType(threadData, _f, _s);
_sv = omc_AbsynToSCode_translateVariability(threadData, _v);
_sp = omc_AbsynToSCode_translateParallelism(threadData, _p);
_adim = listAppend(_extraADim, _adim);
tmpMeta[1] = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _adim, _ct, _sp, _sv, _dir, _fi);
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
_outA = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outA;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynToSCode_containsExternalFuncDecl(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[12] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClass;
{
modelica_boolean _b;
modelica_boolean _c;
modelica_boolean _d;
modelica_string _a = NULL;
modelica_metatype _e = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _file_info = NULL;
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,5) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
if (listEmpty(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],7,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp7 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp8 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,5) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
if (listEmpty(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 5));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 6));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_a = tmpMeta[0];
_b = tmp6;
_c = tmp7;
_d = tmp8;
_e = tmpMeta[4];
_rest = tmpMeta[8];
_ann = tmpMeta[9];
_cmt = tmpMeta[10];
_file_info = tmpMeta[11];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, tmpMeta[0], tmpMeta[1], _rest, _ann, _cmt);
tmpMeta[3] = mmc_mk_box8(3, &Absyn_Class_CLASS__desc, _a, mmc_mk_boolean(_b), mmc_mk_boolean(_c), mmc_mk_boolean(_d), _e, tmpMeta[2], _file_info);
_inClass = tmpMeta[3];
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],4,5) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
if (listEmpty(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],7,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_integer tmp9;
modelica_integer tmp10;
modelica_integer tmp11;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp9 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp10 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp11 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],4,5) == 0) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 5));
if (listEmpty(tmpMeta[7])) goto tmp3_end;
tmpMeta[8] = MMC_CAR(tmpMeta[7]);
tmpMeta[9] = MMC_CDR(tmpMeta[7]);
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 6));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_a = tmpMeta[0];
_b = tmp9;
_c = tmp10;
_d = tmp11;
_e = tmpMeta[4];
_cmt = tmpMeta[6];
_rest = tmpMeta[9];
_ann = tmpMeta[10];
_file_info = tmpMeta[11];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, tmpMeta[0], tmpMeta[1], _rest, _ann, _cmt);
tmpMeta[3] = mmc_mk_box8(3, &Absyn_Class_CLASS__desc, _a, mmc_mk_boolean(_b), mmc_mk_boolean(_c), mmc_mk_boolean(_d), _e, tmpMeta[2], _file_info);
_inClass = tmpMeta[3];
goto _tailrecursive;
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
_outBoolean = tmp1;
_return: OMC_LABEL_UNUSED
return _outBoolean;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_containsExternalFuncDecl(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_AbsynToSCode_containsExternalFuncDecl(threadData, _inClass);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateRestriction(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inRestriction)
{
modelica_metatype _outRestriction = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inClass;
tmp3_2 = _inRestriction;
{
modelica_metatype _d = NULL;
modelica_metatype _name = NULL;
modelica_integer _index;
modelica_boolean _singleton;
modelica_boolean _isImpure;
modelica_boolean _moved;
modelica_metatype _purity = NULL;
modelica_metatype _typeVars = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 25; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_purity = tmpMeta[2];
_d = tmp3_1;
_isImpure = omc_AbsynToSCode_translatePurity(threadData, _purity);
tmp5 = (modelica_boolean)omc_AbsynToSCode_containsExternalFuncDecl(threadData, _d);
if(tmp5)
{
tmpMeta[1] = mmc_mk_box2(4, &SCode_FunctionRestriction_FR__EXTERNAL__FUNCTION__desc, mmc_mk_boolean(_isImpure));
tmpMeta[2] = mmc_mk_box2(12, &SCode_Restriction_R__FUNCTION__desc, tmpMeta[1]);
tmpMeta[5] = tmpMeta[2];
}
else
{
tmpMeta[3] = mmc_mk_box2(3, &SCode_FunctionRestriction_FR__NORMAL__FUNCTION__desc, mmc_mk_boolean(_isImpure));
tmpMeta[4] = mmc_mk_box2(12, &SCode_Restriction_R__FUNCTION__desc, tmpMeta[3]);
tmpMeta[5] = tmpMeta[4];
}
tmpMeta[0] = tmpMeta[5];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT108;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT110;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT112;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT113;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT114;
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT115;
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,3,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT116;
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,11,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT117;
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,4,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT118;
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT119;
goto tmp2_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,6,0) == 0) goto tmp2_end;
omc_System_setHasExpandableConnectors(threadData, 1);
tmpMeta[0] = _OMC_LIT120;
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,10,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT81;
goto tmp2_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT49;
goto tmp2_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT121;
goto tmp2_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,12,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT122;
goto tmp2_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT123;
goto tmp2_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,14,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT124;
goto tmp2_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,15,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT125;
goto tmp2_done;
}
case 19: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT126;
goto tmp2_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,18,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT127;
goto tmp2_done;
}
case 21: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,17,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT128;
goto tmp2_done;
}
case 22: {
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,20,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
tmp7 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 5));
tmp8 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 6));
_name = tmpMeta[1];
_index = tmp6;
_singleton = tmp7;
_moved = tmp8;
_typeVars = tmpMeta[5];
tmpMeta[1] = mmc_mk_box6(20, &SCode_Restriction_R__METARECORD__desc, _name, mmc_mk_integer(_index), mmc_mk_boolean(_singleton), mmc_mk_boolean(_moved), _typeVars);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 23: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,5) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,19,0) == 0) goto tmp2_end;
_typeVars = tmpMeta[2];
tmpMeta[1] = mmc_mk_box2(21, &SCode_Restriction_R__UNIONTYPE__desc, _typeVars);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 24: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,19,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT129;
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
_outRestriction = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outRestriction;
}
DLLExport
modelica_boolean omc_AbsynToSCode_translatePurity(threadData_t *threadData, modelica_metatype _inPurity)
{
modelica_boolean _outPurity;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inPurity;
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
_outPurity = tmp1;
_return: OMC_LABEL_UNUSED
return _outPurity;
}
modelica_metatype boxptr_AbsynToSCode_translatePurity(threadData_t *threadData, modelica_metatype _inPurity)
{
modelica_boolean _outPurity;
modelica_metatype out_outPurity;
_outPurity = omc_AbsynToSCode_translatePurity(threadData, _inPurity);
out_outPurity = mmc_mk_icon(_outPurity);
return out_outPurity;
}
DLLExport
modelica_metatype omc_AbsynToSCode_getListofQualOperatorFuncsfromOperator(threadData_t *threadData, modelica_metatype _inOperator)
{
modelica_metatype _outNames = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inOperator;
{
modelica_metatype _els = NULL;
modelica_string _opername = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,0) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,8) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_opername = tmpMeta[1];
_els = tmpMeta[4];
tmpMeta[0] = omc_List_map1(threadData, _els, boxvar_AbsynToSCode_getOperatorQualName, _opername);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,0) == 0) goto tmp2_end;
_opername = tmpMeta[1];
tmpMeta[2] = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _opername);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
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
_outNames = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outNames;
}
DLLExport
modelica_metatype omc_AbsynToSCode_getOperatorQualName(threadData_t *threadData, modelica_metatype _inOperatorFunction, modelica_string _operName)
{
modelica_metatype _outName = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_string tmp3_2;
tmp3_1 = _inOperatorFunction;
tmp3_2 = _operName;
{
modelica_string _name = NULL;
modelica_string _opname = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,1) == 0) goto tmp2_end;
_name = tmpMeta[1];
_opname = tmp3_2;
tmpMeta[1] = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _opname);
tmpMeta[2] = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
tmpMeta[0] = omc_AbsynUtil_joinPaths(threadData, tmpMeta[1], tmpMeta[2]);
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
_outName = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outName;
}
DLLExport
modelica_metatype omc_AbsynToSCode_getOperatorGivenName(threadData_t *threadData, modelica_metatype _inOperatorFunction)
{
modelica_metatype _outName = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inOperatorFunction;
{
modelica_string _name = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,8) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,0) == 0) goto tmp2_end;
_name = tmpMeta[1];
tmpMeta[1] = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
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
_outName = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outName;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateOperatorDef(threadData_t *threadData, modelica_metatype _inClassDef, modelica_string _operatorName, modelica_metatype _info, modelica_metatype *out_cmt)
{
modelica_metatype _outOperDef = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inClassDef;
{
modelica_metatype _cmtString = NULL;
modelica_metatype _els = NULL;
modelica_metatype _parts = NULL;
modelica_metatype _aann = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_parts = tmpMeta[2];
_aann = tmpMeta[3];
_cmtString = tmpMeta[4];
_els = omc_AbsynToSCode_translateClassdefElements(threadData, _parts);
_cmt = omc_AbsynToSCode_translateCommentList(threadData, _aann, _cmtString);
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[5] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[6] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[7] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[8] = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, _els, tmpMeta[2], tmpMeta[3], tmpMeta[4], tmpMeta[5], tmpMeta[6], tmpMeta[7], mmc_mk_none());
tmpMeta[0+0] = tmpMeta[8];
tmpMeta[0+1] = _cmt;
goto tmp3_done;
}
case 1: {
omc_Error_addSourceMessage(threadData, _OMC_LIT56, _OMC_LIT131, _info);
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
_outOperDef = tmpMeta[0+0];
_cmt = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_cmt) { *out_cmt = _cmt; }
return _outOperDef;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClass2(threadData_t *threadData, modelica_metatype _inClass, modelica_integer _inNumMessages)
{
modelica_metatype _outClass = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inClass;
{
modelica_metatype _d_1 = NULL;
modelica_metatype _r_1 = NULL;
modelica_metatype _c = NULL;
modelica_string _n = NULL;
modelica_boolean _p;
modelica_boolean _f;
modelica_boolean _e;
modelica_metatype _r = NULL;
modelica_metatype _d = NULL;
modelica_metatype _file_info = NULL;
modelica_metatype _sFin = NULL;
modelica_metatype _sEnc = NULL;
modelica_metatype _sPar = NULL;
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
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmp6 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmp7 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_c = tmp3_1;
_n = tmpMeta[1];
_p = tmp5;
_f = tmp6;
_e = tmp7;
_r = tmpMeta[5];
_d = tmpMeta[6];
_file_info = tmpMeta[7];
_r_1 = omc_AbsynToSCode_translateRestriction(threadData, _c, _r);
_d_1 = omc_AbsynToSCode_translateClassdef(threadData, _d, _file_info, _r_1 ,&_cmt);
_sFin = omc_SCodeUtil_boolFinal(threadData, _f);
_sEnc = omc_SCodeUtil_boolEncapsulated(threadData, _e);
_sPar = omc_SCodeUtil_boolPartial(threadData, _p);
tmpMeta[1] = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _OMC_LIT41, _OMC_LIT42, _sFin, _OMC_LIT44, _OMC_LIT45);
tmpMeta[2] = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _n, tmpMeta[1], _sEnc, _sPar, _r_1, _d_1, _cmt, _file_info);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
modelica_boolean tmp8;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_n = tmpMeta[1];
_file_info = tmpMeta[2];
tmp8 = (omc_Error_getNumMessages(threadData) == _inNumMessages);
if (1 != tmp8) goto goto_1;
tmpMeta[1] = stringAppend(_OMC_LIT132,_n);
_n = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_n, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT56, tmpMeta[1], _file_info);
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
_outClass = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outClass;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_AbsynToSCode_translateClass2(threadData_t *threadData, modelica_metatype _inClass, modelica_metatype _inNumMessages)
{
modelica_integer tmp1;
modelica_metatype _outClass = NULL;
tmp1 = mmc_unbox_integer(_inNumMessages);
_outClass = omc_AbsynToSCode_translateClass2(threadData, _inClass, tmp1);
return _outClass;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateClass(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_metatype _outClass = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outClass = omc_AbsynToSCode_translateClass2(threadData, _inClass, omc_Error_getNumMessages(threadData));
_return: OMC_LABEL_UNUSED
return _outClass;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateAbsyn2SCode(threadData_t *threadData, modelica_metatype _inProgram)
{
modelica_metatype _outProgram = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _inClasses = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
omc_InstHashTable_init(threadData);
tmpMeta[1] = omc_MetaUtil_createMetaClassesInProgram(threadData, _inProgram);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_inClasses = tmpMeta[2];
omc_System_setHasInnerOuterDefinitions(threadData, 0);
omc_System_setHasExpandableConnectors(threadData, 0);
omc_System_setHasOverconstrainedConnectors(threadData, 0);
omc_System_setHasStreamConnectors(threadData, 0);
{
modelica_metatype __omcQ_24tmpVar9;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar8;
int tmp6;
modelica_metatype _c_loopVar = 0;
modelica_metatype _c;
_c_loopVar = _inClasses;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar9 = tmpMeta[2];
tmp5 = &__omcQ_24tmpVar9;
while(1) {
tmp6 = 1;
if (!listEmpty(_c_loopVar)) {
_c = MMC_CAR(_c_loopVar);
_c_loopVar = MMC_CDR(_c_loopVar);
tmp6--;
}
if (tmp6 == 0) {
__omcQ_24tmpVar8 = omc_AbsynToSCode_translateClass(threadData, _c);
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar8,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar9;
}
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
_outProgram = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outProgram;
}
