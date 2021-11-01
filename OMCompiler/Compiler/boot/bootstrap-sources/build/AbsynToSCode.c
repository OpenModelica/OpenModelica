#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "AbsynToSCode.c"
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
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT88,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(145)),_OMC_LIT85,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT87}};
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
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,1,1) == 0) goto tmp2_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
if (5 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT26), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp2_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta7)) goto tmp2_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
if (!listEmpty(tmpMeta9)) goto tmp2_end;
_ts2 = tmpMeta8;
_str = omc_AbsynUtil_typeSpecString(threadData, _ts);
tmpMeta10 = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT4, tmpMeta10, _info);
_ts = _ts2;
goto _tailrecursive;
;
goto tmp2_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,1,1) == 0) goto tmp2_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (5 != MMC_STRLEN(tmpMeta12) || strcmp(MMC_STRINGDATA(_OMC_LIT26), MMC_STRINGDATA(tmpMeta12)) != 0) goto tmp2_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta13)) goto tmp2_end;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (listEmpty(tmpMeta15)) goto tmp2_end;
tmpMeta16 = MMC_CAR(tmpMeta15);
tmpMeta17 = MMC_CDR(tmpMeta15);
_tss = tmpMeta13;
omc_List_map1__0(threadData, _tss, boxvar_AbsynToSCode_checkTypeSpec, _info);
goto tmp2_done;
}
case 3: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta18)) goto tmp2_end;
tmpMeta19 = MMC_CAR(tmpMeta18);
tmpMeta20 = MMC_CDR(tmpMeta18);
if (!listEmpty(tmpMeta20)) goto tmp2_end;
_ts2 = tmpMeta19;
_ts = _ts2;
goto _tailrecursive;
;
goto tmp2_done;
}
case 4: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_tss = tmpMeta21;
if(listMember((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ts), 2))), _OMC_LIT25))
{
_str = omc_AbsynUtil_typeSpecString(threadData, _ts);
tmpMeta22 = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT7, tmpMeta22, _info);
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAEach;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT27;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT28;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outSEach = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSEach;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_makeTypeVarElement(threadData_t *threadData, modelica_string _str, modelica_metatype _info)
{
modelica_metatype _elt = NULL;
modelica_metatype _cd = NULL;
modelica_metatype _ts = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ts = _OMC_LIT33;
tmpMeta1 = mmc_mk_box4(5, &SCode_ClassDef_DERIVED__desc, _ts, _OMC_LIT34, _OMC_LIT40);
_cd = tmpMeta1;
tmpMeta2 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _str, _OMC_LIT46, _OMC_LIT47, _OMC_LIT48, _OMC_LIT49, _cd, _OMC_LIT50, _info);
_elt = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _elt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateSub(threadData_t *threadData, modelica_metatype _inPath, modelica_metatype _inMod, modelica_metatype _info)
{
modelica_metatype _outSubMod = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inPath;
tmp4_2 = _inMod;
{
modelica_string _i = NULL;
modelica_metatype _path = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _sub = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_i = tmpMeta6;
_mod = tmp4_2;
tmpMeta7 = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _i, _mod);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_i = tmpMeta8;
_path = tmpMeta9;
_mod = tmp4_2;
_sub = omc_AbsynToSCode_translateSub(threadData, _path, _mod, _info);
tmpMeta10 = mmc_mk_cons(_sub, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta11 = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _OMC_LIT51, _OMC_LIT28, tmpMeta10, mmc_mk_none(), _info);
_mod = tmpMeta11;
tmpMeta12 = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, _i, _mod);
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
_outSubMod = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outSubMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateArgs(threadData_t *threadData, modelica_metatype _args)
{
modelica_metatype _subMods = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _smod = NULL;
modelica_metatype _elem = NULL;
modelica_metatype _sub = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta15;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_subMods = tmpMeta1;
{
modelica_metatype _arg;
for (tmpMeta2 = _args; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_arg = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp6_1;
tmp6_1 = _arg;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 2; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,6) == 0) goto tmp5_end;
_smod = omc_AbsynToSCode_translateMod(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 5))), omc_SCodeUtil_boolFinal(threadData, mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 2))))), omc_AbsynToSCode_translateEach(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 3)))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 7))));
if((!omc_SCodeUtil_isEmptyMod(threadData, _smod)))
{
_sub = omc_AbsynToSCode_translateSub(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 4))), _smod, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 7))));
tmpMeta8 = mmc_mk_cons(_sub, _subMods);
_subMods = tmpMeta8;
}
tmpMeta3 = _subMods;
goto tmp5_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,1,6) == 0) goto tmp5_end;
tmpMeta9 = omc_AbsynToSCode_translateElementspec(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 6))), mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 2)))), _OMC_LIT44, mmc_mk_some((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 3)))), _OMC_LIT41, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 7))));
if (listEmpty(tmpMeta9)) goto goto_4;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
if (!listEmpty(tmpMeta11)) goto goto_4;
_elem = tmpMeta10;
tmpMeta12 = mmc_mk_box4(4, &SCode_Mod_REDECL__desc, omc_SCodeUtil_boolFinal(threadData, mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 2))))), omc_AbsynToSCode_translateEach(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 4)))), _elem);
tmpMeta13 = mmc_mk_box3(3, &SCode_SubMod_NAMEMOD__desc, omc_AbsynUtil_elementSpecName(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 5)))), tmpMeta12);
_sub = tmpMeta13;
tmpMeta14 = mmc_mk_cons(_sub, _subMods);
tmpMeta3 = tmpMeta14;
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
_subMods = tmpMeta3;
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
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_args = tmpMeta7;
_eqmod = tmpMeta8;
tmpMeta[0+0] = _args;
tmpMeta[0+1] = _eqmod;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta9;
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
tmp11 = (modelica_boolean)listEmpty(_args);
if(tmp11)
{
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta12 = tmpMeta10;
}
else
{
tmpMeta12 = omc_AbsynToSCode_translateArgs(threadData, _args);
}
_subs = tmpMeta12;
{
modelica_metatype tmp16_1;
tmp16_1 = _eqmod;
{
volatile mmc_switch_type tmp16;
int tmp17;
tmp16 = 0;
for (; tmp16 < 2; tmp16++) {
switch (MMC_SWITCH_CAST(tmp16)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp16_1,1,2) == 0) goto tmp15_end;
tmpMeta13 = mmc_mk_some((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eqmod), 2))));
goto tmp15_done;
}
case 1: {
tmpMeta13 = mmc_mk_none();
goto tmp15_done;
}
}
goto tmp15_end;
tmp15_end: ;
}
goto goto_14;
goto_14:;
MMC_THROW_INTERNAL();
goto tmp15_done;
tmp15_done:;
}
}
_binding = tmpMeta13;
{
modelica_metatype tmp21_1;modelica_metatype tmp21_2;modelica_metatype tmp21_3;modelica_metatype tmp21_4;
tmp21_1 = _subs;
tmp21_2 = _binding;
tmp21_3 = _finalPrefix;
tmp21_4 = _eachPrefix;
{
volatile mmc_switch_type tmp21;
int tmp22;
tmp21 = 0;
for (; tmp21 < 2; tmp21++) {
switch (MMC_SWITCH_CAST(tmp21)) {
case 0: {
if (!listEmpty(tmp21_1)) goto tmp20_end;
if (!optionNone(tmp21_2)) goto tmp20_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp21_3,1,0) == 0) goto tmp20_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp21_4,1,0) == 0) goto tmp20_end;
tmpMeta18 = _OMC_LIT34;
goto tmp20_done;
}
case 1: {
modelica_metatype tmpMeta23;
tmpMeta23 = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _finalPrefix, _eachPrefix, _subs, _binding, _info);
tmpMeta18 = tmpMeta23;
goto tmp20_done;
}
}
goto tmp20_end;
tmp20_end: ;
}
goto goto_19;
goto_19:;
MMC_THROW_INTERNAL();
goto tmp20_done;
tmp20_done:;
}
}
_outMod = tmpMeta18;
_return: OMC_LABEL_UNUSED
return _outMod;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateElementAddinfo(threadData_t *threadData, modelica_metatype _elem, modelica_metatype _nfo)
{
modelica_metatype _oelem = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _elem;
{
modelica_string _a1 = NULL;
modelica_metatype _a6 = NULL;
modelica_metatype _a7 = NULL;
modelica_metatype _a8 = NULL;
modelica_metatype _a10 = NULL;
modelica_metatype _a11 = NULL;
modelica_metatype _p = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_a1 = tmpMeta6;
_p = tmpMeta7;
_a6 = tmpMeta8;
_a7 = tmpMeta9;
_a8 = tmpMeta10;
_a10 = tmpMeta11;
_a11 = tmpMeta12;
tmpMeta13 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _a1, _p, _a6, _a7, _a8, _a10, _a11, _nfo);
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _elem;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_oelem = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _oelem;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_AbsynToSCode_translateIterator(threadData_t *threadData, modelica_metatype _inIterator, modelica_metatype _inInfo, modelica_metatype *out_outRange)
{
modelica_string _outName = NULL;
modelica_metatype _outRange = NULL;
modelica_metatype _guard_exp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inIterator;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_outName = tmpMeta2;
_guard_exp = tmpMeta3;
_outRange = tmpMeta4;
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
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inBranch;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_outCondition = tmpMeta2;
_body = tmpMeta3;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inEquation;
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
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 12; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
_body = omc_AbsynToSCode_translateEEquations(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _inIsInitial);
_conditions = omc_List_map1__2(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))), boxvar_AbsynToSCode_translateEqBranch, mmc_mk_boolean(_inIsInitial) ,&_bodies);
tmpMeta6 = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _conditions);
_conditions = tmpMeta6;
_else_branch = omc_AbsynToSCode_translateEEquations(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 5))), _inIsInitial);
tmpMeta7 = mmc_mk_cons(_body, _bodies);
tmpMeta8 = mmc_mk_box6(3, &SCode_EEquation_EQ__IF__desc, _conditions, tmpMeta7, _else_branch, _inComment, _inInfo);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
_body = omc_AbsynToSCode_translateEEquations(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _inIsInitial);
_conditions = omc_List_map1__2(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))), boxvar_AbsynToSCode_translateEqBranch, mmc_mk_boolean(_inIsInitial) ,&_bodies);
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp13;
modelica_metatype _c_loopVar = 0;
modelica_metatype _c;
modelica_metatype _b_loopVar = 0;
modelica_metatype _b;
_c_loopVar = _conditions;
_b_loopVar = _bodies;
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta11;
tmp10 = &__omcQ_24tmpVar1;
while(1) {
tmp13 = 2;
if (!listEmpty(_c_loopVar)) {
_c = MMC_CAR(_c_loopVar);
_c_loopVar = MMC_CDR(_c_loopVar);
tmp13--;
}if (!listEmpty(_b_loopVar)) {
_b = MMC_CAR(_b_loopVar);
_b_loopVar = MMC_CDR(_b_loopVar);
tmp13--;
}
if (tmp13 == 0) {
tmpMeta12 = mmc_mk_box2(0, _c, _b);
__omcQ_24tmpVar0 = tmpMeta12;
*tmp10 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp10 = &MMC_CDR(*tmp10);
} else if (tmp13 == 2) {
break;
} else {
goto goto_2;
}
}
*tmp10 = mmc_mk_nil();
tmpMeta9 = __omcQ_24tmpVar1;
}
_branches = tmpMeta9;
tmpMeta14 = mmc_mk_box6(8, &SCode_EEquation_EQ__WHEN__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), _body, _branches, _inComment, _inInfo);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta15 = mmc_mk_box5(4, &SCode_EEquation_EQ__EQUALS__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _inComment, _inInfo);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta16 = mmc_mk_box6(5, &SCode_EEquation_EQ__PDE__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 4))), _inComment, _inInfo);
tmpMeta1 = tmpMeta16;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,2) == 0) goto tmp3_end;
if(_inIsInitial)
{
tmpMeta17 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessageAndFail(threadData, _OMC_LIT61, tmpMeta17, _inInfo);
}
tmpMeta18 = mmc_mk_box5(6, &SCode_EEquation_EQ__CONNECT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _inComment, _inInfo);
tmpMeta1 = tmpMeta18;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,2) == 0) goto tmp3_end;
_body = omc_AbsynToSCode_translateEEquations(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), _inIsInitial);
{
modelica_metatype _i;
for (tmpMeta19 = listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2)))); !listEmpty(tmpMeta19); tmpMeta19=MMC_CDR(tmpMeta19))
{
_i = MMC_CAR(tmpMeta19);
_iter_name = omc_AbsynToSCode_translateIterator(threadData, _i, _inInfo ,&_iter_range);
tmpMeta21 = mmc_mk_box6(7, &SCode_EEquation_EQ__FOR__desc, _iter_name, _iter_range, _body, _inComment, _inInfo);
tmpMeta20 = mmc_mk_cons(tmpMeta21, MMC_REFSTRUCTLIT(mmc_nil));
_body = tmpMeta20;
}
}
tmpMeta1 = listHead(_body);
goto tmp3_done;
}
case 6: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,2,2) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
if (6 != MMC_STRLEN(tmpMeta24) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta24)) != 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,0,2) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
if (listEmpty(tmpMeta26)) goto tmp3_end;
tmpMeta27 = MMC_CAR(tmpMeta26);
tmpMeta28 = MMC_CDR(tmpMeta26);
if (listEmpty(tmpMeta28)) goto tmp3_end;
tmpMeta29 = MMC_CAR(tmpMeta28);
tmpMeta30 = MMC_CDR(tmpMeta28);
if (!listEmpty(tmpMeta30)) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 3));
if (!listEmpty(tmpMeta31)) goto tmp3_end;
_e1 = tmpMeta27;
_e2 = tmpMeta29;
tmpMeta32 = mmc_mk_box6(9, &SCode_EEquation_EQ__ASSERT__desc, _e1, _e2, _OMC_LIT67, _inComment, _inInfo);
tmpMeta1 = tmpMeta32;
goto tmp3_done;
}
case 7: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta33,2,2) == 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 2));
if (6 != MMC_STRLEN(tmpMeta34) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta34)) != 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta35,0,2) == 0) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 2));
if (listEmpty(tmpMeta36)) goto tmp3_end;
tmpMeta37 = MMC_CAR(tmpMeta36);
tmpMeta38 = MMC_CDR(tmpMeta36);
if (listEmpty(tmpMeta38)) goto tmp3_end;
tmpMeta39 = MMC_CAR(tmpMeta38);
tmpMeta40 = MMC_CDR(tmpMeta38);
if (listEmpty(tmpMeta40)) goto tmp3_end;
tmpMeta41 = MMC_CAR(tmpMeta40);
tmpMeta42 = MMC_CDR(tmpMeta40);
if (!listEmpty(tmpMeta42)) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 3));
if (!listEmpty(tmpMeta43)) goto tmp3_end;
_e1 = tmpMeta37;
_e2 = tmpMeta39;
_e3 = tmpMeta41;
tmpMeta44 = mmc_mk_box6(9, &SCode_EEquation_EQ__ASSERT__desc, _e1, _e2, _e3, _inComment, _inInfo);
tmpMeta1 = tmpMeta44;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta45,2,2) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 2));
if (6 != MMC_STRLEN(tmpMeta46) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta46)) != 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta47,0,2) == 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta47), 2));
if (listEmpty(tmpMeta48)) goto tmp3_end;
tmpMeta49 = MMC_CAR(tmpMeta48);
tmpMeta50 = MMC_CDR(tmpMeta48);
if (listEmpty(tmpMeta50)) goto tmp3_end;
tmpMeta51 = MMC_CAR(tmpMeta50);
tmpMeta52 = MMC_CDR(tmpMeta50);
if (!listEmpty(tmpMeta52)) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta47), 3));
if (listEmpty(tmpMeta53)) goto tmp3_end;
tmpMeta54 = MMC_CAR(tmpMeta53);
tmpMeta55 = MMC_CDR(tmpMeta53);
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 2));
if (5 != MMC_STRLEN(tmpMeta56) || strcmp(MMC_STRINGDATA(_OMC_LIT69), MMC_STRINGDATA(tmpMeta56)) != 0) goto tmp3_end;
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 3));
if (!listEmpty(tmpMeta55)) goto tmp3_end;
_e1 = tmpMeta49;
_e2 = tmpMeta51;
_e3 = tmpMeta57;
tmpMeta58 = mmc_mk_box6(9, &SCode_EEquation_EQ__ASSERT__desc, _e1, _e2, _e3, _inComment, _inInfo);
tmpMeta1 = tmpMeta58;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta59,2,2) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta59), 2));
if (9 != MMC_STRLEN(tmpMeta60) || strcmp(MMC_STRINGDATA(_OMC_LIT70), MMC_STRINGDATA(tmpMeta60)) != 0) goto tmp3_end;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta61,0,2) == 0) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta61), 2));
if (listEmpty(tmpMeta62)) goto tmp3_end;
tmpMeta63 = MMC_CAR(tmpMeta62);
tmpMeta64 = MMC_CDR(tmpMeta62);
if (!listEmpty(tmpMeta64)) goto tmp3_end;
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta61), 3));
if (!listEmpty(tmpMeta65)) goto tmp3_end;
_e1 = tmpMeta63;
tmpMeta66 = mmc_mk_box4(10, &SCode_EEquation_EQ__TERMINATE__desc, _e1, _inComment, _inInfo);
tmpMeta1 = tmpMeta66;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta67,2,2) == 0) goto tmp3_end;
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta67), 2));
if (6 != MMC_STRLEN(tmpMeta68) || strcmp(MMC_STRINGDATA(_OMC_LIT71), MMC_STRINGDATA(tmpMeta68)) != 0) goto tmp3_end;
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta69,0,2) == 0) goto tmp3_end;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 2));
if (listEmpty(tmpMeta70)) goto tmp3_end;
tmpMeta71 = MMC_CAR(tmpMeta70);
tmpMeta72 = MMC_CDR(tmpMeta70);
if (listEmpty(tmpMeta72)) goto tmp3_end;
tmpMeta73 = MMC_CAR(tmpMeta72);
tmpMeta74 = MMC_CDR(tmpMeta72);
if (!listEmpty(tmpMeta74)) goto tmp3_end;
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 3));
if (!listEmpty(tmpMeta75)) goto tmp3_end;
_e1 = tmpMeta71;
_e2 = tmpMeta73;
tmpMeta76 = mmc_mk_box5(11, &SCode_EEquation_EQ__REINIT__desc, _e1, _e2, _inComment, _inInfo);
tmpMeta1 = tmpMeta76;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta77 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta78 = mmc_mk_box4(14, &Absyn_Exp_CALL__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inEquation), 3))), tmpMeta77);
tmpMeta79 = mmc_mk_box4(12, &SCode_EEquation_EQ__NORETCALL__desc, tmpMeta78, _inComment, _inInfo);
tmpMeta1 = tmpMeta79;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outEEquation = tmpMeta1;
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (!optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (!optionNone(tmpMeta8)) goto tmp3_end;
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = mmc_mk_none();
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (!optionNone(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
if (optionNone(tmpMeta11)) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 1));
_str = tmpMeta12;
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = mmc_mk_some(_str);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
if (optionNone(tmpMeta14)) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 1));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
if (!optionNone(tmpMeta16)) goto tmp3_end;
_absann = tmpMeta15;
_ann = omc_AbsynToSCode_translateAnnotation(threadData, _absann);
tmpMeta[0+0] = _ann;
tmpMeta[0+1] = mmc_mk_none();
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
if (optionNone(tmpMeta18)) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 1));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 3));
if (optionNone(tmpMeta20)) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 1));
_absann = tmpMeta19;
_str = tmpMeta21;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAnns;
{
modelica_metatype _absann = NULL;
modelica_metatype _anns = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _ostr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, mmc_mk_none(), _inString);
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
if (!listEmpty(tmpMeta8)) goto tmp3_end;
_absann = tmpMeta7;
_ann = omc_AbsynToSCode_translateAnnotation(threadData, _absann);
_ostr = omc_Util_applyOption(threadData, _inString, boxvar_System_unescapedString);
tmpMeta9 = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, _ann, _ostr);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_absann = tmpMeta10;
_anns = tmpMeta11;
_absann = omc_List_fold(threadData, _anns, boxvar_AbsynUtil_mergeAnnotations, _absann);
_ann = omc_AbsynToSCode_translateAnnotation(threadData, _absann);
_ostr = omc_Util_applyOption(threadData, _inString, boxvar_System_unescapedString);
tmpMeta12 = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, _ann, _ostr);
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
_outComment = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComment;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateComment(threadData_t *threadData, modelica_metatype _inComment)
{
modelica_metatype _outComment = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inComment;
{
modelica_metatype _absann = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _ostr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta1 = _OMC_LIT50;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_absann = tmpMeta7;
_ostr = tmpMeta8;
_ann = omc_AbsynToSCode_translateAnnotationOpt(threadData, _absann);
_ostr = omc_Util_applyOption(threadData, _ostr, boxvar_System_unescapedString);
tmpMeta9 = mmc_mk_box3(3, &SCode_Comment_COMMENT__desc, _ann, _ostr);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outComment = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outComment;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_getInfoAnnotationOrDefault2(threadData_t *threadData, modelica_metatype _lst, modelica_metatype _default)
{
modelica_metatype _info = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _lst;
{
modelica_metatype _rest = NULL;
modelica_string _fileName = NULL;
modelica_integer _line;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _default;
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
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_integer tmp19;
modelica_metatype tmpMeta20;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (23 != MMC_STRLEN(tmpMeta8) || strcmp(MMC_STRINGDATA(_OMC_LIT73), MMC_STRINGDATA(tmpMeta8)) != 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,5) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 5));
if (optionNone(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,16,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (listEmpty(tmpMeta12)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmpMeta12);
tmpMeta14 = MMC_CDR(tmpMeta12);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,3,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
if (listEmpty(tmpMeta14)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmpMeta14);
tmpMeta17 = MMC_CDR(tmpMeta14);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,0,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmp19 = mmc_unbox_integer(tmpMeta18);
if (!listEmpty(tmpMeta17)) goto tmp3_end;
_fileName = tmpMeta15;
_line = tmp19;
tmpMeta20 = mmc_mk_box8(3, &SourceInfo_SOURCEINFO__desc, _fileName, mmc_mk_boolean(0), mmc_mk_integer(_line), mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(_line), mmc_mk_integer(((modelica_integer) 0)), _OMC_LIT72);
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta21 = MMC_CAR(tmp4_1);
tmpMeta22 = MMC_CDR(tmp4_1);
_rest = tmpMeta22;
_lst = _rest;
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
_info = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _info;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_getInfoAnnotationOrDefault(threadData_t *threadData, modelica_metatype _comment, modelica_metatype _default)
{
modelica_metatype _info = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _comment;
{
modelica_metatype _lst = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,5) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
_lst = tmpMeta9;
tmpMeta1 = omc_AbsynToSCode_getInfoAnnotationOrDefault2(threadData, _lst, _default);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _default;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_info = tmpMeta1;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynEquationItemLst;
{
modelica_metatype _e_1 = NULL;
modelica_metatype _es_1 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _es = NULL;
modelica_metatype _acom = NULL;
modelica_metatype _com = NULL;
modelica_metatype _info = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
_e = tmpMeta9;
_acom = tmpMeta10;
_info = tmpMeta11;
_es = tmpMeta8;
_com = omc_AbsynToSCode_translateCommentWithLineInfoChanges(threadData, _acom, _info ,&_info);
_e_1 = omc_AbsynToSCode_translateEquation(threadData, _e, _com, _info, _inIsInitial);
_es_1 = omc_AbsynToSCode_translateEEquations(threadData, _es, _inIsInitial);
tmpMeta12 = mmc_mk_cons(_e_1, _es_1);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,1,1) == 0) goto tmp3_end;
_es = tmpMeta14;
_inAbsynEquationItemLst = _es;
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
_outEEquationLst = tmpMeta1;
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
modelica_metatype _eq_loopVar = 0;
modelica_boolean tmp11 = 0;
modelica_metatype _eq;
_eq_loopVar = _inAbsynEquationItemLst;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar3;
while(1) {
tmp10 = 1;
while (!listEmpty(_eq_loopVar)) {
_eq = MMC_CAR(_eq_loopVar);
_eq_loopVar = MMC_CDR(_eq_loopVar);
{
modelica_metatype tmp14_1;
tmp14_1 = _eq;
{
volatile mmc_switch_type tmp14;
int tmp15;
tmp14 = 0;
for (; tmp14 < 2; tmp14++) {
switch (MMC_SWITCH_CAST(tmp14)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp14_1,0,3) == 0) goto tmp13_end;
tmp11 = 1;
goto tmp13_done;
}
case 1: {
tmp11 = 0;
goto tmp13_done;
}
}
goto tmp13_end;
tmp13_end: ;
}
goto goto_12;
goto_12:;
MMC_THROW_INTERNAL();
goto tmp13_done;
tmp13_done:;
}
}
if (tmp11) {
tmp10--;
break;
}
}
if (tmp10 == 0) {
{
modelica_metatype tmp7_1;
tmp7_1 = _eq;
{
modelica_metatype _com = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 1; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,3) == 0) goto tmp6_end;
_com = omc_AbsynToSCode_translateCommentWithLineInfoChanges(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 4))) ,&_info);
tmpMeta9 = mmc_mk_box2(3, &SCode_Equation_EQUATION__desc, omc_AbsynToSCode_translateEquation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_eq), 2))), _com, _info, _inIsInitial));
tmpMeta4 = tmpMeta9;
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
_outEquationLst = tmpMeta1;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVariability;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmpMeta1 = _OMC_LIT37;
goto tmp3_done;
}
case 4: {
tmpMeta1 = _OMC_LIT74;
goto tmp3_done;
}
case 5: {
tmpMeta1 = _OMC_LIT75;
goto tmp3_done;
}
case 6: {
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
_outVariability = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outVariability;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateParallelism(threadData_t *threadData, modelica_metatype _inParallelism)
{
modelica_metatype _outParallelism = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inParallelism;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmpMeta1 = _OMC_LIT77;
goto tmp3_done;
}
case 4: {
tmpMeta1 = _OMC_LIT78;
goto tmp3_done;
}
case 5: {
tmpMeta1 = _OMC_LIT36;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outParallelism = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outParallelism;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateConstrainClass(threadData_t *threadData, modelica_metatype _inConstrainClass)
{
modelica_metatype _outConstrainClass = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inConstrainClass;
{
modelica_metatype _cc_path = NULL;
modelica_metatype _eltargs = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _cc_cmt = NULL;
modelica_metatype _mod = NULL;
modelica_metatype _cc_mod = NULL;
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
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_cc_path = tmpMeta8;
_eltargs = tmpMeta9;
_cmt = tmpMeta10;
tmpMeta11 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _eltargs, _OMC_LIT52);
_mod = tmpMeta11;
_cc_mod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(_mod), _OMC_LIT51, _OMC_LIT28, _OMC_LIT80);
_cc_cmt = omc_AbsynToSCode_translateComment(threadData, _cmt);
tmpMeta12 = mmc_mk_box4(3, &SCode_ConstrainClass_CONSTRAINCLASS__desc, _cc_path, _cc_mod, _cc_cmt);
tmpMeta1 = mmc_mk_some(tmpMeta12);
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
_outConstrainClass = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outConstrainClass;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynToSCode_translateRedeclarekeywords(threadData_t *threadData, modelica_metatype _inRedeclKeywords, modelica_boolean *out_outIsRedeclared)
{
modelica_boolean _outIsReplaceable;
modelica_boolean _outIsRedeclared;
modelica_boolean tmp1_c0 __attribute__((unused)) = 0;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,0) == 0) goto tmp3_end;
tmp1_c0 = 0;
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,0) == 0) goto tmp3_end;
tmp1_c0 = 1;
tmp1_c1 = 0;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,0) == 0) goto tmp3_end;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _gimp;
tmp4_2 = _visibility;
{
modelica_string _name = NULL;
modelica_string _rename = NULL;
modelica_metatype _path = NULL;
modelica_metatype _vis = NULL;
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
_name = tmpMeta6;
_vis = tmp4_2;
tmpMeta7 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
_path = omc_AbsynUtil_joinPaths(threadData, _prefix, tmpMeta7);
tmpMeta8 = mmc_mk_box2(4, &Absyn_Import_QUAL__IMPORT__desc, _path);
tmpMeta9 = mmc_mk_box4(3, &SCode_Element_IMPORT__desc, tmpMeta8, _vis, _info);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_rename = tmpMeta10;
_name = tmpMeta11;
_vis = tmp4_2;
tmpMeta12 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
_path = omc_AbsynUtil_joinPaths(threadData, _prefix, tmpMeta12);
tmpMeta13 = mmc_mk_box3(3, &Absyn_Import_NAMED__IMPORT__desc, _rename, _path);
tmpMeta14 = mmc_mk_box4(3, &SCode_Element_IMPORT__desc, tmpMeta13, _vis, _info);
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
_elt = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _elt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateImports(threadData_t *threadData, modelica_metatype _imp, modelica_metatype _visibility, modelica_metatype _info)
{
modelica_metatype _elts = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _imp;
{
modelica_string _name = NULL;
modelica_metatype _p = NULL;
modelica_metatype _groups = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,2,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_name = tmpMeta6;
_p = tmpMeta8;
tmpMeta9 = mmc_mk_box3(3, &Absyn_Import_NAMED__IMPORT__desc, _name, _p);
_imp = tmpMeta9;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,2,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_p = tmpMeta11;
tmpMeta12 = mmc_mk_box2(4, &Absyn_Import_QUAL__IMPORT__desc, _p);
_imp = tmpMeta12;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,2,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
_p = tmpMeta14;
tmpMeta15 = mmc_mk_box2(5, &Absyn_Import_UNQUAL__IMPORT__desc, _p);
_imp = tmpMeta15;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_p = tmpMeta16;
_groups = tmpMeta17;
tmpMeta1 = omc_List_map3(threadData, _groups, boxvar_AbsynToSCode_translateGroupImport, _p, _visibility, _info);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
tmpMeta19 = mmc_mk_box4(3, &SCode_Element_IMPORT__desc, _imp, _visibility, _info);
tmpMeta18 = mmc_mk_cons(tmpMeta19, MMC_REFSTRUCTLIT(mmc_nil));
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
_elts = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _elts;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateElementspec(threadData_t *threadData, modelica_metatype _cc, modelica_boolean _finalPrefix, modelica_metatype _io, modelica_metatype _inRedeclareKeywords, modelica_metatype _inVisibility, modelica_metatype _inElementSpec4, modelica_metatype _inInfo)
{
modelica_metatype _outElementLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _inRedeclareKeywords;
tmp4_2 = _inVisibility;
tmp4_3 = _inElementSpec4;
tmp4_4 = _inInfo;
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
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 8; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_integer tmp11;
modelica_metatype tmpMeta12;
modelica_integer tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
tmp11 = mmc_unbox_integer(tmpMeta10);
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
tmp13 = mmc_unbox_integer(tmpMeta12);
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,10,0) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 7));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 8));
_rp = tmp7;
_n = tmpMeta9;
_pa = tmp11;
_e = tmp13;
_de = tmpMeta15;
_i = tmpMeta16;
_repl = tmp4_1;
_vis = tmp4_2;
_de_1 = omc_AbsynToSCode_translateOperatorDef(threadData, _de, _n, _i ,&_cmt);
omc_AbsynToSCode_translateRedeclarekeywords(threadData, _repl ,&_redecl);
_sRed = omc_SCodeUtil_boolRedeclare(threadData, _redecl);
_sFin = omc_SCodeUtil_boolFinal(threadData, _finalPrefix);
_scc = omc_AbsynToSCode_translateConstrainClass(threadData, _cc);
tmp18 = (modelica_boolean)_rp;
if(tmp18)
{
tmpMeta17 = mmc_mk_box2(3, &SCode_Replaceable_REPLACEABLE__desc, _scc);
tmpMeta19 = tmpMeta17;
}
else
{
tmpMeta19 = _OMC_LIT45;
}
_sRep = tmpMeta19;
_sEnc = omc_SCodeUtil_boolEncapsulated(threadData, _e);
_sPar = omc_SCodeUtil_boolPartial(threadData, _pa);
tmpMeta20 = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _vis, _sRed, _sFin, _io, _sRep);
tmpMeta21 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _n, tmpMeta20, _sEnc, _sPar, _OMC_LIT81, _de_1, _cmt, _i);
_cls = tmpMeta21;
tmpMeta22 = mmc_mk_cons(_cls, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta22;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta23;
modelica_integer tmp24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_integer tmp28;
modelica_metatype tmpMeta29;
modelica_integer tmp30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_boolean tmp35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp24 = mmc_unbox_integer(tmpMeta23);
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 3));
tmp28 = mmc_unbox_integer(tmpMeta27);
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 5));
tmp30 = mmc_unbox_integer(tmpMeta29);
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 6));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 7));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 8));
_rp = tmp24;
_cl = tmpMeta25;
_n = tmpMeta26;
_pa = tmp28;
_e = tmp30;
_re = tmpMeta31;
_de = tmpMeta32;
_i = tmpMeta33;
_repl = tmp4_1;
_vis = tmp4_2;
_re_1 = omc_AbsynToSCode_translateRestriction(threadData, _cl, _re);
_de_1 = omc_AbsynToSCode_translateClassdef(threadData, _de, _i, _re_1 ,&_cmt);
omc_AbsynToSCode_translateRedeclarekeywords(threadData, _repl ,&_redecl);
_sRed = omc_SCodeUtil_boolRedeclare(threadData, _redecl);
_sFin = omc_SCodeUtil_boolFinal(threadData, _finalPrefix);
_scc = omc_AbsynToSCode_translateConstrainClass(threadData, _cc);
tmp35 = (modelica_boolean)_rp;
if(tmp35)
{
tmpMeta34 = mmc_mk_box2(3, &SCode_Replaceable_REPLACEABLE__desc, _scc);
tmpMeta36 = tmpMeta34;
}
else
{
tmpMeta36 = _OMC_LIT45;
}
_sRep = tmpMeta36;
_sEnc = omc_SCodeUtil_boolEncapsulated(threadData, _e);
_sPar = omc_SCodeUtil_boolPartial(threadData, _pa);
tmpMeta37 = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _vis, _sRed, _sFin, _io, _sRep);
tmpMeta38 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _n, tmpMeta37, _sEnc, _sPar, _re_1, _de_1, _cmt, _i);
_cls = tmpMeta38;
tmpMeta39 = mmc_mk_cons(_cls, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta39;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,3) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (!optionNone(tmpMeta42)) goto tmp3_end;
_path = tmpMeta40;
_args = tmpMeta41;
_vis = tmp4_2;
_info = tmp4_4;
tmpMeta43 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _args, _OMC_LIT52);
_mod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta43), _OMC_LIT51, _OMC_LIT28, _OMC_LIT80);
tmpMeta45 = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _path, _vis, _mod, mmc_mk_none(), _info);
tmpMeta44 = mmc_mk_cons(tmpMeta45, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta44;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,3) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (optionNone(tmpMeta48)) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta48), 1));
_path = tmpMeta46;
_args = tmpMeta47;
_absann = tmpMeta49;
_vis = tmp4_2;
_info = tmp4_4;
tmpMeta50 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _args, _OMC_LIT52);
_mod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta50), _OMC_LIT51, _OMC_LIT28, _OMC_LIT80);
_ann = omc_AbsynToSCode_translateAnnotation(threadData, _absann);
tmpMeta52 = mmc_mk_box6(4, &SCode_Element_EXTENDS__desc, _path, _vis, _mod, _ann, _info);
tmpMeta51 = mmc_mk_cons(tmpMeta52, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta51;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,3) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (!listEmpty(tmpMeta53)) goto tmp3_end;
tmpMeta54 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta54;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_integer tmp57;
modelica_metatype tmpMeta58;
modelica_integer tmp59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_boolean tmp76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_metatype tmpMeta99;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,3) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta55), 2));
tmp57 = mmc_unbox_integer(tmpMeta56);
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta55), 3));
tmp59 = mmc_unbox_integer(tmpMeta58);
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta55), 4));
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta55), 5));
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta55), 6));
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta55), 7));
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta55), 8));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_fl = tmp57;
_st = tmp59;
_parallelism = tmpMeta60;
_variability = tmpMeta61;
_di = tmpMeta62;
_isf = tmpMeta63;
_ad = tmpMeta64;
_t = tmpMeta65;
_repl = tmp4_1;
_vis = tmp4_2;
_info = tmp4_4;
tmpMeta66 = MMC_REFSTRUCTLIT(mmc_nil);
_xs_1 = tmpMeta66;
{
modelica_metatype _comp;
for (tmpMeta67 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inElementSpec4), 4))); !listEmpty(tmpMeta67); tmpMeta67=MMC_CDR(tmpMeta67))
{
_comp = MMC_CAR(tmpMeta67);
tmpMeta68 = _comp;
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta68), 2));
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 2));
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 3));
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta69), 4));
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta68), 3));
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta68), 4));
_n = tmpMeta70;
_d = tmpMeta71;
_m = tmpMeta72;
_cond = tmpMeta73;
_comment = tmpMeta74;
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
tmp76 = (modelica_boolean)_repl_1;
if(tmp76)
{
tmpMeta75 = mmc_mk_box2(3, &SCode_Replaceable_REPLACEABLE__desc, _scc);
tmpMeta77 = tmpMeta75;
}
else
{
tmpMeta77 = _OMC_LIT45;
}
_sRep = tmpMeta77;
_ct = omc_AbsynToSCode_translateConnectorType(threadData, _fl, _st);
tmpMeta78 = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _vis, _sRed, _sFin, _io, _sRep);
_prefixes = tmpMeta78;
{
modelica_metatype tmp82_1;
tmp82_1 = _di;
{
modelica_metatype _attr1 = NULL;
modelica_metatype _attr2 = NULL;
modelica_metatype _mod2 = NULL;
modelica_string _inName = NULL;
volatile mmc_switch_type tmp82;
int tmp83;
tmp82 = 0;
for (; tmp82 < 2; tmp82++) {
switch (MMC_SWITCH_CAST(tmp82)) {
case 0: {
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
if (mmc__uniontype__metarecord__typedef__equal(tmp82_1,3,0) == 0) goto tmp81_end;
if (!(!omc_Flags_isSet(threadData, _OMC_LIT88))) goto tmp81_end;
tmpMeta84 = stringAppend(_OMC_LIT82,_n);
_inName = tmpMeta84;
tmpMeta85 = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _tot_dim, _ct, _prl1, _var1, _OMC_LIT83, _isf);
_attr1 = tmpMeta85;
tmpMeta86 = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _tot_dim, _ct, _prl1, _var1, _OMC_LIT84, _isf);
_attr2 = tmpMeta86;
tmpMeta87 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta88 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta89 = mmc_mk_box3(5, &Absyn_ComponentRef_CREF__IDENT__desc, _inName, tmpMeta88);
tmpMeta90 = mmc_mk_box2(5, &Absyn_Exp_CREF__desc, tmpMeta89);
tmpMeta91 = mmc_mk_box6(3, &SCode_Mod_MOD__desc, _OMC_LIT43, _OMC_LIT28, tmpMeta87, mmc_mk_some(tmpMeta90), _info);
_mod2 = tmpMeta91;
tmpMeta93 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _n, _prefixes, _attr2, _t, _mod2, _cmt, _cond, _info);
tmpMeta95 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _inName, _prefixes, _attr1, _t, _mod, _cmt, _cond, _info);
tmpMeta94 = mmc_mk_cons(tmpMeta95, _xs_1);
tmpMeta92 = mmc_mk_cons(tmpMeta93, tmpMeta94);
tmpMeta79 = tmpMeta92;
goto tmp81_done;
}
case 1: {
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
tmpMeta97 = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _tot_dim, _ct, _prl1, _var1, _di, _isf);
tmpMeta98 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _n, _prefixes, tmpMeta97, _t, _mod, _cmt, _cond, _info);
tmpMeta96 = mmc_mk_cons(tmpMeta98, _xs_1);
tmpMeta79 = tmpMeta96;
goto tmp81_done;
}
}
goto tmp81_end;
tmp81_end: ;
}
goto goto_80;
goto_80:;
goto goto_2;
goto tmp81_done;
tmp81_done:;
}
}
_xs_1 = tmpMeta79;
}
}
tmpMeta1 = listReverseInPlace(_xs_1);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,3) == 0) goto tmp3_end;
tmpMeta100 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta101 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_imp = tmpMeta100;
_info = tmpMeta101;
_vis = tmp4_2;
tmpMeta1 = omc_AbsynToSCode_translateImports(threadData, _imp, _vis, _info);
goto tmp3_done;
}
case 7: {
omc_Error_addMessage(threadData, _OMC_LIT56, _OMC_LIT90);
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
_outElementLst = tmpMeta1;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_string tmp4_2;
tmp4_1 = _inArgs;
tmp4_2 = _inArg;
{
modelica_string _name = NULL;
modelica_string _arg = NULL;
modelica_string _s = NULL;
modelica_real _r;
modelica_metatype _args = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_name = tmpMeta8;
_s = tmpMeta10;
_arg = tmp4_2;
if (!(stringEqual(_name, _arg))) goto tmp3_end;
_r = stringReal(_s);
tmpMeta1 = mmc_mk_some(mmc_mk_real(_r));
goto tmp3_done;
}
case 1: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = mmc_mk_none();
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmp4_1);
tmpMeta12 = MMC_CDR(tmp4_1);
_args = tmpMeta12;
_arg = tmp4_2;
_inArgs = _args;
_inArg = _arg;
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
_weightOpt = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _weightOpt;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateDefineunitParam(threadData_t *threadData, modelica_metatype _inArgs, modelica_string _inArg)
{
modelica_metatype _expOpt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_string tmp4_2;
tmp4_1 = _inArgs;
tmp4_2 = _inArg;
{
modelica_string _str = NULL;
modelica_string _name = NULL;
modelica_string _arg = NULL;
modelica_metatype _args = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
_name = tmpMeta8;
_str = tmpMeta10;
_arg = tmp4_2;
if (!(stringEqual(_name, _arg))) goto tmp3_end;
tmpMeta1 = mmc_mk_some(_str);
goto tmp3_done;
}
case 1: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = mmc_mk_none();
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmp4_1);
tmpMeta12 = MMC_CDR(tmp4_1);
_args = tmpMeta12;
_arg = tmp4_2;
_inArgs = _args;
_inArg = _arg;
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
_expOpt = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _expOpt;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateElement(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inVisibility)
{
modelica_metatype _outElementLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inElement;
tmp4_2 = _inVisibility;
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
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_f = tmp7;
_repl = tmpMeta8;
_io = tmpMeta9;
_s = tmpMeta10;
_info = tmpMeta11;
_cc = tmpMeta12;
_vis = tmp4_2;
tmpMeta1 = omc_AbsynToSCode_translateElementspec(threadData, _cc, _f, _io, _repl, _vis, _s, _info);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_name = tmpMeta13;
_args = tmpMeta14;
_info = tmpMeta15;
_vis = tmp4_2;
_expOpt = omc_AbsynToSCode_translateDefineunitParam(threadData, _args, _OMC_LIT91);
_weightOpt = omc_AbsynToSCode_translateDefineunitParam2(threadData, _args, _OMC_LIT92);
tmpMeta17 = mmc_mk_box6(7, &SCode_Element_DEFINEUNIT__desc, _name, _vis, _expOpt, _weightOpt, _info);
tmpMeta16 = mmc_mk_cons(tmpMeta17, MMC_REFSTRUCTLIT(mmc_nil));
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
_outElementLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElementLst;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateAnnotationOpt(threadData_t *threadData, modelica_metatype _absynAnnotation)
{
modelica_metatype _scodeAnnotation = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _absynAnnotation;
{
modelica_metatype _ann = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_ann = tmpMeta6;
tmpMeta1 = omc_AbsynToSCode_translateAnnotation(threadData, _ann);
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
_scodeAnnotation = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _scodeAnnotation;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateAnnotation(threadData_t *threadData, modelica_metatype _inAnnotation)
{
modelica_metatype _outAnnotation = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAnnotation;
{
modelica_metatype _args = NULL;
modelica_metatype _m = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta1 = mmc_mk_none();
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
modelica_metatype tmpMeta11;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_args = tmpMeta7;
tmpMeta8 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _args, _OMC_LIT52);
_m = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta8), _OMC_LIT51, _OMC_LIT28, _OMC_LIT80);
tmp10 = (modelica_boolean)omc_SCodeUtil_isEmptyMod(threadData, _m);
if(tmp10)
{
tmpMeta11 = mmc_mk_none();
}
else
{
tmpMeta9 = mmc_mk_box2(3, &SCode_Annotation_ANNOTATION__desc, _m);
tmpMeta11 = mmc_mk_some(tmpMeta9);
}
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
_outAnnotation = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAnnotation;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateEitemlist(threadData_t *threadData, modelica_metatype _inAbsynElementItemLst, modelica_metatype _inVisibility)
{
modelica_metatype _outElementLst = NULL;
modelica_metatype _l = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _es = NULL;
modelica_metatype _ei = NULL;
modelica_metatype _vis = NULL;
modelica_metatype _e = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_l = tmpMeta1;
_es = _inAbsynElementItemLst;
{
modelica_metatype _ei;
for (tmpMeta2 = _es; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_ei = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp5_1;
tmp5_1 = _ei;
{
modelica_metatype _e_1 = NULL;
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 2; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,0,1) == 0) goto tmp4_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
_e = tmpMeta7;
_e_1 = omc_AbsynToSCode_translateElement(threadData, _e, _inVisibility);
_l = omc_List_append__reverse(threadData, _e_1, _l);
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
_outElementLst = listReverseInPlace(_l);
_return: OMC_LABEL_UNUSED
return _outElementLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefExternaldecls(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAbsynExternalDeclOption = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _rest = NULL;
modelica_metatype _fn_name = NULL;
modelica_metatype _lang = NULL;
modelica_metatype _output_ = NULL;
modelica_metatype _args = NULL;
modelica_metatype _aann = NULL;
modelica_metatype _sann = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,7,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 5));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 6));
_fn_name = tmpMeta9;
_lang = tmpMeta10;
_output_ = tmpMeta11;
_args = tmpMeta12;
_aann = tmpMeta13;
_sann = omc_AbsynToSCode_translateAnnotationOpt(threadData, _aann);
tmpMeta14 = mmc_mk_box6(3, &SCode_ExternalDecl_EXTERNALDECL__desc, _fn_name, _lang, _output_, _args, _sann);
tmpMeta1 = mmc_mk_some(tmpMeta14);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_1);
tmpMeta16 = MMC_CDR(tmp4_1);
_rest = tmpMeta16;
_inAbsynClassPartLst = _rest;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
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
_outAbsynExternalDeclOption = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAbsynExternalDeclOption;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateAlgBranches(threadData_t *threadData, modelica_metatype _inBranches)
{
modelica_metatype _outBranches = NULL;
modelica_metatype _condition = NULL;
modelica_metatype _body = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype __omcQ_24tmpVar4;
modelica_integer tmp12;
modelica_metatype _branch_loopVar = 0;
modelica_metatype _branch;
_branch_loopVar = _inBranches;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar5;
while(1) {
tmp12 = 1;
if (!listEmpty(_branch_loopVar)) {
_branch = MMC_CAR(_branch_loopVar);
_branch_loopVar = MMC_CDR(_branch_loopVar);
tmp12--;
}
if (tmp12 == 0) {
{
modelica_metatype tmp7_1;
tmp7_1 = _branch;
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
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 1));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp7_1), 2));
_condition = tmpMeta9;
_body = tmpMeta10;
tmpMeta11 = mmc_mk_box2(0, _condition, omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, _body));
tmpMeta4 = tmpMeta11;
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
}__omcQ_24tmpVar4 = tmpMeta4;
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp12 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar5;
}
_outBranches = tmpMeta1;
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
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inAlgorithm;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,0,3) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_alg = tmpMeta2;
_absynComment = tmpMeta3;
_info = tmpMeta4;
_comment = omc_AbsynToSCode_translateCommentWithLineInfoChanges(threadData, _absynComment, _info ,&_info);
{
modelica_metatype tmp8_1;
tmp8_1 = _alg;
{
modelica_metatype _body = NULL;
modelica_metatype _else_body = NULL;
modelica_metatype _branches = NULL;
modelica_string _iter_name = NULL;
modelica_metatype _iter_range = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
for (; tmp8 < 17; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,0,2) == 0) goto tmp7_end;
tmpMeta10 = mmc_mk_box5(3, &SCode_Statement_ALG__ASSIGN__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))), _comment, _info);
tmpMeta5 = tmpMeta10;
goto tmp7_done;
}
case 1: {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,1,4) == 0) goto tmp7_end;
_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))));
_else_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 5))));
_branches = omc_AbsynToSCode_translateAlgBranches(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 4))));
tmpMeta11 = mmc_mk_box7(4, &SCode_Statement_ALG__IF__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), _body, _branches, _else_body, _comment, _info);
tmpMeta5 = tmpMeta11;
goto tmp7_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,2,2) == 0) goto tmp7_end;
_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))));
{
modelica_metatype _i;
for (tmpMeta12 = listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2)))); !listEmpty(tmpMeta12); tmpMeta12=MMC_CDR(tmpMeta12))
{
_i = MMC_CAR(tmpMeta12);
_iter_name = omc_AbsynToSCode_translateIterator(threadData, _i, _info ,&_iter_range);
tmpMeta14 = mmc_mk_box6(5, &SCode_Statement_ALG__FOR__desc, _iter_name, _iter_range, _body, _comment, _info);
tmpMeta13 = mmc_mk_cons(tmpMeta14, MMC_REFSTRUCTLIT(mmc_nil));
_body = tmpMeta13;
}
}
tmpMeta5 = listHead(_body);
goto tmp7_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,3,2) == 0) goto tmp7_end;
_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))));
{
modelica_metatype _i;
for (tmpMeta16 = listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2)))); !listEmpty(tmpMeta16); tmpMeta16=MMC_CDR(tmpMeta16))
{
_i = MMC_CAR(tmpMeta16);
_iter_name = omc_AbsynToSCode_translateIterator(threadData, _i, _info ,&_iter_range);
tmpMeta18 = mmc_mk_box6(6, &SCode_Statement_ALG__PARFOR__desc, _iter_name, _iter_range, _body, _comment, _info);
tmpMeta17 = mmc_mk_cons(tmpMeta18, MMC_REFSTRUCTLIT(mmc_nil));
_body = tmpMeta17;
}
}
tmpMeta5 = listHead(_body);
goto tmp7_done;
}
case 4: {
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,4,2) == 0) goto tmp7_end;
_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))));
tmpMeta20 = mmc_mk_box5(7, &SCode_Statement_ALG__WHILE__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), _body, _comment, _info);
tmpMeta5 = tmpMeta20;
goto tmp7_done;
}
case 5: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,5,3) == 0) goto tmp7_end;
tmpMeta22 = mmc_mk_box2(0, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))));
tmpMeta21 = mmc_mk_cons(tmpMeta22, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 4))));
_branches = omc_AbsynToSCode_translateAlgBranches(threadData, tmpMeta21);
tmpMeta23 = mmc_mk_box4(8, &SCode_Statement_ALG__WHEN__A__desc, _branches, _comment, _info);
tmpMeta5 = tmpMeta23;
goto tmp7_done;
}
case 6: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,6,2) == 0) goto tmp7_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,2,2) == 0) goto tmp7_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 2));
if (6 != MMC_STRLEN(tmpMeta25) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta25)) != 0) goto tmp7_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,0,2) == 0) goto tmp7_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
if (listEmpty(tmpMeta27)) goto tmp7_end;
tmpMeta28 = MMC_CAR(tmpMeta27);
tmpMeta29 = MMC_CDR(tmpMeta27);
if (listEmpty(tmpMeta29)) goto tmp7_end;
tmpMeta30 = MMC_CAR(tmpMeta29);
tmpMeta31 = MMC_CDR(tmpMeta29);
if (!listEmpty(tmpMeta31)) goto tmp7_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 3));
if (!listEmpty(tmpMeta32)) goto tmp7_end;
_e1 = tmpMeta28;
_e2 = tmpMeta30;
tmpMeta33 = mmc_mk_box6(9, &SCode_Statement_ALG__ASSERT__desc, _e1, _e2, _OMC_LIT67, _comment, _info);
tmpMeta5 = tmpMeta33;
goto tmp7_done;
}
case 7: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,6,2) == 0) goto tmp7_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,2,2) == 0) goto tmp7_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 2));
if (6 != MMC_STRLEN(tmpMeta35) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta35)) != 0) goto tmp7_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta36,0,2) == 0) goto tmp7_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 2));
if (listEmpty(tmpMeta37)) goto tmp7_end;
tmpMeta38 = MMC_CAR(tmpMeta37);
tmpMeta39 = MMC_CDR(tmpMeta37);
if (listEmpty(tmpMeta39)) goto tmp7_end;
tmpMeta40 = MMC_CAR(tmpMeta39);
tmpMeta41 = MMC_CDR(tmpMeta39);
if (listEmpty(tmpMeta41)) goto tmp7_end;
tmpMeta42 = MMC_CAR(tmpMeta41);
tmpMeta43 = MMC_CDR(tmpMeta41);
if (!listEmpty(tmpMeta43)) goto tmp7_end;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 3));
if (!listEmpty(tmpMeta44)) goto tmp7_end;
_e1 = tmpMeta38;
_e2 = tmpMeta40;
_e3 = tmpMeta42;
tmpMeta45 = mmc_mk_box6(9, &SCode_Statement_ALG__ASSERT__desc, _e1, _e2, _e3, _comment, _info);
tmpMeta5 = tmpMeta45;
goto tmp7_done;
}
case 8: {
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,6,2) == 0) goto tmp7_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta46,2,2) == 0) goto tmp7_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 2));
if (6 != MMC_STRLEN(tmpMeta47) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta47)) != 0) goto tmp7_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta48,0,2) == 0) goto tmp7_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta48), 2));
if (listEmpty(tmpMeta49)) goto tmp7_end;
tmpMeta50 = MMC_CAR(tmpMeta49);
tmpMeta51 = MMC_CDR(tmpMeta49);
if (listEmpty(tmpMeta51)) goto tmp7_end;
tmpMeta52 = MMC_CAR(tmpMeta51);
tmpMeta53 = MMC_CDR(tmpMeta51);
if (!listEmpty(tmpMeta53)) goto tmp7_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta48), 3));
if (listEmpty(tmpMeta54)) goto tmp7_end;
tmpMeta55 = MMC_CAR(tmpMeta54);
tmpMeta56 = MMC_CDR(tmpMeta54);
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta55), 2));
if (5 != MMC_STRLEN(tmpMeta57) || strcmp(MMC_STRINGDATA(_OMC_LIT69), MMC_STRINGDATA(tmpMeta57)) != 0) goto tmp7_end;
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta55), 3));
if (!listEmpty(tmpMeta56)) goto tmp7_end;
_e1 = tmpMeta50;
_e2 = tmpMeta52;
_e3 = tmpMeta58;
tmpMeta59 = mmc_mk_box6(9, &SCode_Statement_ALG__ASSERT__desc, _e1, _e2, _e3, _comment, _info);
tmpMeta5 = tmpMeta59;
goto tmp7_done;
}
case 9: {
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,6,2) == 0) goto tmp7_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta60,2,2) == 0) goto tmp7_end;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta60), 2));
if (9 != MMC_STRLEN(tmpMeta61) || strcmp(MMC_STRINGDATA(_OMC_LIT70), MMC_STRINGDATA(tmpMeta61)) != 0) goto tmp7_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta62,0,2) == 0) goto tmp7_end;
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 2));
if (listEmpty(tmpMeta63)) goto tmp7_end;
tmpMeta64 = MMC_CAR(tmpMeta63);
tmpMeta65 = MMC_CDR(tmpMeta63);
if (!listEmpty(tmpMeta65)) goto tmp7_end;
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 3));
if (!listEmpty(tmpMeta66)) goto tmp7_end;
_e1 = tmpMeta64;
tmpMeta67 = mmc_mk_box4(10, &SCode_Statement_ALG__TERMINATE__desc, _e1, _comment, _info);
tmpMeta5 = tmpMeta67;
goto tmp7_done;
}
case 10: {
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,6,2) == 0) goto tmp7_end;
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta68,2,2) == 0) goto tmp7_end;
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta68), 2));
if (6 != MMC_STRLEN(tmpMeta69) || strcmp(MMC_STRINGDATA(_OMC_LIT71), MMC_STRINGDATA(tmpMeta69)) != 0) goto tmp7_end;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta70,0,2) == 0) goto tmp7_end;
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 2));
if (listEmpty(tmpMeta71)) goto tmp7_end;
tmpMeta72 = MMC_CAR(tmpMeta71);
tmpMeta73 = MMC_CDR(tmpMeta71);
if (listEmpty(tmpMeta73)) goto tmp7_end;
tmpMeta74 = MMC_CAR(tmpMeta73);
tmpMeta75 = MMC_CDR(tmpMeta73);
if (!listEmpty(tmpMeta75)) goto tmp7_end;
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 3));
if (!listEmpty(tmpMeta76)) goto tmp7_end;
_e1 = tmpMeta72;
_e2 = tmpMeta74;
tmpMeta77 = mmc_mk_box5(11, &SCode_Statement_ALG__REINIT__desc, _e1, _e2, _comment, _info);
tmpMeta5 = tmpMeta77;
goto tmp7_done;
}
case 11: {
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_metatype tmpMeta80;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,6,2) == 0) goto tmp7_end;
tmpMeta78 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta79 = mmc_mk_box4(14, &Absyn_Exp_CALL__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))), tmpMeta78);
_e1 = tmpMeta79;
tmpMeta80 = mmc_mk_box4(12, &SCode_Statement_ALG__NORETCALL__desc, _e1, _comment, _info);
tmpMeta5 = tmpMeta80;
goto tmp7_done;
}
case 12: {
modelica_metatype tmpMeta81;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,9,1) == 0) goto tmp7_end;
_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))));
tmpMeta81 = mmc_mk_box4(15, &SCode_Statement_ALG__FAILURE__desc, _body, _comment, _info);
tmpMeta5 = tmpMeta81;
goto tmp7_done;
}
case 13: {
modelica_metatype tmpMeta82;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,10,2) == 0) goto tmp7_end;
_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 2))));
_else_body = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_alg), 3))));
tmpMeta82 = mmc_mk_box5(16, &SCode_Statement_ALG__TRY__desc, _body, _else_body, _comment, _info);
tmpMeta5 = tmpMeta82;
goto tmp7_done;
}
case 14: {
modelica_metatype tmpMeta83;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,7,0) == 0) goto tmp7_end;
tmpMeta83 = mmc_mk_box3(13, &SCode_Statement_ALG__RETURN__desc, _comment, _info);
tmpMeta5 = tmpMeta83;
goto tmp7_done;
}
case 15: {
modelica_metatype tmpMeta84;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,8,0) == 0) goto tmp7_end;
tmpMeta84 = mmc_mk_box3(14, &SCode_Statement_ALG__BREAK__desc, _comment, _info);
tmpMeta5 = tmpMeta84;
goto tmp7_done;
}
case 16: {
modelica_metatype tmpMeta85;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,11,0) == 0) goto tmp7_end;
tmpMeta85 = mmc_mk_box3(17, &SCode_Statement_ALG__CONTINUE__desc, _comment, _info);
tmpMeta5 = tmpMeta85;
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
_outStatement = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _outStatement;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData_t *threadData, modelica_metatype _inStatements)
{
modelica_metatype _outStatements = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar6;
modelica_integer tmp4;
modelica_metatype _stmt_loopVar = 0;
modelica_metatype _stmt;
_stmt_loopVar = _inStatements;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar7;
while(1) {
tmp4 = 1;
while (!listEmpty(_stmt_loopVar)) {
_stmt = MMC_CAR(_stmt_loopVar);
_stmt_loopVar = MMC_CDR(_stmt_loopVar);
if (omc_AbsynUtil_isAlgorithmItem(threadData, _stmt)) {
tmp4--;
break;
}
}
if (tmp4 == 0) {
__omcQ_24tmpVar6 = omc_AbsynToSCode_translateClassdefAlgorithmItem(threadData, _stmt);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar7;
}
_outStatements = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outStatements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefInitialalgorithms(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAlgorithmLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _als = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _al = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,6,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_al = tmpMeta9;
_rest = tmpMeta8;
_stmts = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, _al);
_als = omc_AbsynToSCode_translateClassdefInitialalgorithms(threadData, _rest);
tmpMeta11 = mmc_mk_box2(3, &SCode_AlgorithmSection_ALGORITHM__desc, _stmts);
tmpMeta10 = mmc_mk_cons(tmpMeta11, _als);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_1);
tmpMeta13 = MMC_CDR(tmp4_1);
_rest = tmpMeta13;
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
_outAlgorithmLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAlgorithmLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefConstraints(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outConstraintLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _cos = NULL;
modelica_metatype _consts = NULL;
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
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,2,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_consts = tmpMeta9;
_rest = tmpMeta8;
_cos = omc_AbsynToSCode_translateClassdefConstraints(threadData, _rest);
tmpMeta11 = mmc_mk_box2(3, &SCode_ConstraintSection_CONSTRAINTS__desc, _consts);
tmpMeta10 = mmc_mk_cons(tmpMeta11, _cos);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_1);
tmpMeta13 = MMC_CDR(tmp4_1);
_rest = tmpMeta13;
_inAbsynClassPartLst = _rest;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp14;
tmp14 = omc_Flags_isSet(threadData, _OMC_LIT96);
if (1 != tmp14) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT97);
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
_outConstraintLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outConstraintLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefAlgorithms(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outAlgorithmLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _als = NULL;
modelica_metatype _al_1 = NULL;
modelica_metatype _al = NULL;
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
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,5,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_al = tmpMeta9;
_rest = tmpMeta8;
_al_1 = omc_AbsynToSCode_translateClassdefAlgorithmitems(threadData, _al);
_als = omc_AbsynToSCode_translateClassdefAlgorithms(threadData, _rest);
tmpMeta11 = mmc_mk_box2(3, &SCode_AlgorithmSection_ALGORITHM__desc, _al_1);
tmpMeta10 = mmc_mk_cons(tmpMeta11, _als);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_1);
tmpMeta13 = MMC_CDR(tmp4_1);
_rest = tmpMeta13;
_inAbsynClassPartLst = _rest;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp14;
tmp14 = omc_Flags_isSet(threadData, _OMC_LIT96);
if (1 != tmp14) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT98);
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
_outAlgorithmLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outAlgorithmLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefInitialequations(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outEquationLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _eqs = NULL;
modelica_metatype _eql_1 = NULL;
modelica_metatype _eql = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,4,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_eql = tmpMeta9;
_rest = tmpMeta8;
_eql_1 = omc_AbsynToSCode_translateEquations(threadData, _eql, 1);
_eqs = omc_AbsynToSCode_translateClassdefInitialequations(threadData, _rest);
tmpMeta1 = listAppend(_eqs, _eql_1);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_rest = tmpMeta11;
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
_outEquationLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outEquationLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdefEquations(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outEquationLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _eqs = NULL;
modelica_metatype _eql_1 = NULL;
modelica_metatype _eql = NULL;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_eql = tmpMeta9;
_rest = tmpMeta8;
_eql_1 = omc_AbsynToSCode_translateEquations(threadData, _eql, 0);
_eqs = omc_AbsynToSCode_translateClassdefEquations(threadData, _rest);
tmpMeta1 = listAppend(_eqs, _eql_1);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_1);
tmpMeta11 = MMC_CDR(tmp4_1);
_rest = tmpMeta11;
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
_outEquationLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outEquationLst;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateClassdefElements(threadData_t *threadData, modelica_metatype _inAbsynClassPartLst)
{
modelica_metatype _outElementLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynClassPartLst;
{
modelica_metatype _els = NULL;
modelica_metatype _es_1 = NULL;
modelica_metatype _es = NULL;
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
_es = tmpMeta9;
_rest = tmpMeta8;
_es_1 = omc_AbsynToSCode_translateEitemlist(threadData, _es, _OMC_LIT41);
_els = omc_AbsynToSCode_translateClassdefElements(threadData, _rest);
tmpMeta1 = listAppend(_es_1, _els);
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
_es = tmpMeta12;
_rest = tmpMeta11;
_es_1 = omc_AbsynToSCode_translateEitemlist(threadData, _es, _OMC_LIT99);
_els = omc_AbsynToSCode_translateClassdefElements(threadData, _rest);
tmpMeta1 = listAppend(_es_1, _els);
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
_outElementLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outElementLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateEnumlist(threadData_t *threadData, modelica_metatype _inAbsynEnumLiteralLst)
{
modelica_metatype _outEnumLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inAbsynEnumLiteralLst;
{
modelica_metatype _res = NULL;
modelica_string _id = NULL;
modelica_metatype _cmtOpt = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
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
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 3));
_id = tmpMeta9;
_cmtOpt = tmpMeta10;
_rest = tmpMeta8;
_cmt = omc_AbsynToSCode_translateComment(threadData, _cmtOpt);
_res = omc_AbsynToSCode_translateEnumlist(threadData, _rest);
tmpMeta12 = mmc_mk_box3(3, &SCode_Enum_ENUM__desc, _id, _cmt);
tmpMeta11 = mmc_mk_cons(tmpMeta12, _res);
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
_outEnumLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outEnumLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_mergeSCodeAnnotationsFromParts(threadData_t *threadData, modelica_metatype _part, modelica_metatype _inMod)
{
modelica_metatype _outMod = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _part;
{
modelica_metatype _aann = NULL;
modelica_metatype _ann = NULL;
modelica_metatype _rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 1));
_aann = tmpMeta7;
_ann = omc_AbsynToSCode_translateAnnotation(threadData, _aann);
tmpMeta1 = omc_SCodeUtil_mergeSCodeOptAnn(threadData, _ann, _inMod);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
_rest = tmpMeta10;
tmpMeta11 = mmc_mk_box2(3, &Absyn_ClassPart_PUBLIC__desc, _rest);
_part = tmpMeta11;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmpMeta12)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmpMeta12);
tmpMeta14 = MMC_CDR(tmpMeta12);
_rest = tmpMeta14;
tmpMeta15 = mmc_mk_box2(4, &Absyn_ClassPart_PROTECTED__desc, _rest);
_part = tmpMeta15;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
tmpMeta1 = _inMod;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateAlternativeExternalAnnotation(threadData_t *threadData, modelica_metatype _decl, modelica_metatype _comment)
{
modelica_metatype _outDecl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _decl;
tmp4_2 = _comment;
{
modelica_metatype _name = NULL;
modelica_metatype _l = NULL;
modelica_metatype _out = NULL;
modelica_metatype _a = NULL;
modelica_metatype _ann1 = NULL;
modelica_metatype _ann2 = NULL;
modelica_metatype _ann = NULL;
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
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 6));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_name = tmpMeta7;
_l = tmpMeta8;
_out = tmpMeta9;
_a = tmpMeta10;
_ann1 = tmpMeta11;
_ann2 = tmpMeta12;
_ann = omc_SCodeUtil_mergeSCodeOptAnn(threadData, _ann1, _ann2);
tmpMeta13 = mmc_mk_box6(3, &SCode_ExternalDecl_EXTERNALDECL__desc, _name, _l, _out, _a, _ann);
tmpMeta1 = mmc_mk_some(tmpMeta13);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outDecl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDecl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_AbsynToSCode_translateClassdef(threadData_t *threadData, modelica_metatype _inClassDef, modelica_metatype _info, modelica_metatype _re, modelica_metatype *out_outComment)
{
modelica_metatype _outClassDef = NULL;
modelica_metatype _outComment = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_t = tmpMeta6;
_attr = tmpMeta7;
_a = tmpMeta8;
_cmt = tmpMeta9;
omc_AbsynToSCode_checkTypeSpec(threadData, _t, _info);
tmpMeta10 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _a, _OMC_LIT52);
_mod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta10), _OMC_LIT51, _OMC_LIT28, _info);
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
_scodeAttr = omc_AbsynToSCode_translateAttributes(threadData, _attr, tmpMeta11);
_scodeCmt = omc_AbsynToSCode_translateComment(threadData, _cmt);
tmpMeta12 = mmc_mk_box4(5, &SCode_ClassDef_DERIVED__desc, _t, _mod, _scodeAttr);
tmpMeta[0+0] = tmpMeta12;
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_typeVars = tmpMeta13;
_classAttrs = tmpMeta14;
_parts = tmpMeta15;
_ann = tmpMeta16;
_cmtString = tmpMeta17;
{
modelica_metatype tmp21_1;
tmp21_1 = _re;
{
int tmp21;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp21_1))) {
case 20: {
tmpMeta18 = omc_List_union(threadData, _typeVars, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_re), 6))));
goto tmp20_done;
}
case 21: {
tmpMeta18 = omc_List_union(threadData, _typeVars, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_re), 2))));
goto tmp20_done;
}
default:
tmp20_default: OMC_LABEL_UNUSED; {
tmpMeta18 = _typeVars;
goto tmp20_done;
}
}
goto tmp20_end;
tmp20_end: ;
}
goto goto_19;
goto_19:;
goto goto_2;
goto tmp20_done;
tmp20_done:;
}
}
_typeVars = tmpMeta18;
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
tmpMeta22 = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, _els, _eqs, _initeqs, _als, _initals, _cos, _classAttrs, _decl);
tmpMeta[0+0] = tmpMeta22;
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,0,1) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_lst = tmpMeta24;
_cmt = tmpMeta25;
_lst_1 = omc_AbsynToSCode_translateEnumlist(threadData, _lst);
_scodeCmt = omc_AbsynToSCode_translateComment(threadData, _cmt);
tmpMeta26 = mmc_mk_box2(6, &SCode_ClassDef_ENUMERATION__desc, _lst_1);
tmpMeta[0+0] = tmpMeta26;
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,1,0) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cmt = tmpMeta28;
_scodeCmt = omc_AbsynToSCode_translateComment(threadData, _cmt);
tmpMeta[0+0] = _OMC_LIT100;
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,2) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_pathLst = tmpMeta29;
_cmt = tmpMeta30;
_scodeCmt = omc_AbsynToSCode_translateComment(threadData, _cmt);
tmpMeta31 = mmc_mk_box2(7, &SCode_ClassDef_OVERLOAD__desc, _pathLst);
tmpMeta[0+0] = tmpMeta31;
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,5) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_cmod = tmpMeta32;
_cmtString = tmpMeta33;
_parts = tmpMeta34;
_ann = tmpMeta35;
_els = omc_AbsynToSCode_translateClassdefElements(threadData, _parts);
_eqs = omc_AbsynToSCode_translateClassdefEquations(threadData, _parts);
_initeqs = omc_AbsynToSCode_translateClassdefInitialequations(threadData, _parts);
_als = omc_AbsynToSCode_translateClassdefAlgorithms(threadData, _parts);
_initals = omc_AbsynToSCode_translateClassdefInitialalgorithms(threadData, _parts);
_cos = omc_AbsynToSCode_translateClassdefConstraints(threadData, _parts);
tmpMeta36 = mmc_mk_box3(3, &Absyn_Modification_CLASSMOD__desc, _cmod, _OMC_LIT52);
_mod = omc_AbsynToSCode_translateMod(threadData, mmc_mk_some(tmpMeta36), _OMC_LIT51, _OMC_LIT28, _OMC_LIT80);
_scodeCmt = omc_AbsynToSCode_translateCommentList(threadData, _ann, _cmtString);
_decl = omc_AbsynToSCode_translateClassdefExternaldecls(threadData, _parts);
_decl = omc_AbsynToSCode_translateAlternativeExternalAnnotation(threadData, _decl, _scodeCmt);
tmpMeta37 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta38 = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, _els, _eqs, _initeqs, _als, _initals, _cos, tmpMeta37, _decl);
tmpMeta39 = mmc_mk_box3(4, &SCode_ClassDef_CLASS__EXTENDS__desc, _mod, tmpMeta38);
tmpMeta[0+0] = tmpMeta39;
tmpMeta[0+1] = _scodeCmt;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,3) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_path = tmpMeta40;
_vars = tmpMeta41;
_cmt = tmpMeta42;
_scodeCmt = omc_AbsynToSCode_translateComment(threadData, _cmt);
tmpMeta43 = mmc_mk_box3(8, &SCode_ClassDef_PDER__desc, _path, _vars);
tmpMeta[0+0] = tmpMeta43;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp4_1;modelica_boolean tmp4_2;
tmp4_1 = _inFlow;
tmp4_2 = _inStream;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (0 != tmp4_1) goto tmp3_end;
if (0 != tmp4_2) goto tmp3_end;
tmpMeta1 = _OMC_LIT35;
goto tmp3_done;
}
case 1: {
if (1 != tmp4_1) goto tmp3_end;
if (0 != tmp4_2) goto tmp3_end;
tmpMeta1 = _OMC_LIT103;
goto tmp3_done;
}
case 2: {
if (0 != tmp4_1) goto tmp3_end;
if (1 != tmp4_2) goto tmp3_end;
tmpMeta1 = _OMC_LIT104;
goto tmp3_done;
}
case 3: {
if (1 != tmp4_1) goto tmp3_end;
if (1 != tmp4_2) goto tmp3_end;
omc_Error_addMessage(threadData, _OMC_LIT56, _OMC_LIT106);
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inEA;
tmp4_2 = _extraArrayDim;
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
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp9 = mmc_unbox_integer(tmpMeta8);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_f = tmp7;
_s = tmp9;
_p = tmpMeta10;
_v = tmpMeta11;
_dir = tmpMeta12;
_fi = tmpMeta13;
_adim = tmpMeta14;
_extraADim = tmp4_2;
_ct = omc_AbsynToSCode_translateConnectorType(threadData, _f, _s);
_sv = omc_AbsynToSCode_translateVariability(threadData, _v);
_sp = omc_AbsynToSCode_translateParallelism(threadData, _p);
_adim = listAppend(_extraADim, _adim);
tmpMeta15 = mmc_mk_box7(3, &SCode_Attributes_ATTR__desc, _adim, _ct, _sp, _sv, _dir, _fi);
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
_outA = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outA;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_AbsynToSCode_containsExternalFuncDecl(threadData_t *threadData, modelica_metatype _inClass)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
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
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,5) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,7,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_integer tmp12;
modelica_metatype tmpMeta13;
modelica_integer tmp14;
modelica_metatype tmpMeta15;
modelica_integer tmp16;
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
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp12 = mmc_unbox_integer(tmpMeta11);
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp14 = mmc_unbox_integer(tmpMeta13);
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp16 = mmc_unbox_integer(tmpMeta15);
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,0,5) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 4));
if (listEmpty(tmpMeta19)) goto tmp3_end;
tmpMeta20 = MMC_CAR(tmpMeta19);
tmpMeta21 = MMC_CDR(tmpMeta19);
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 5));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 6));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_a = tmpMeta10;
_b = tmp12;
_c = tmp14;
_d = tmp16;
_e = tmpMeta17;
_rest = tmpMeta21;
_ann = tmpMeta22;
_cmt = tmpMeta23;
_file_info = tmpMeta24;
tmpMeta25 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta26 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta27 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, tmpMeta25, tmpMeta26, _rest, _ann, _cmt);
tmpMeta28 = mmc_mk_box8(3, &Absyn_Class_CLASS__desc, _a, mmc_mk_boolean(_b), mmc_mk_boolean(_c), mmc_mk_boolean(_d), _e, tmpMeta27, _file_info);
_inClass = tmpMeta28;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,4,5) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 5));
if (listEmpty(tmpMeta30)) goto tmp3_end;
tmpMeta31 = MMC_CAR(tmpMeta30);
tmpMeta32 = MMC_CDR(tmpMeta30);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,7,2) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_integer tmp35;
modelica_metatype tmpMeta36;
modelica_integer tmp37;
modelica_metatype tmpMeta38;
modelica_integer tmp39;
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
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp35 = mmc_unbox_integer(tmpMeta34);
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp37 = mmc_unbox_integer(tmpMeta36);
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp39 = mmc_unbox_integer(tmpMeta38);
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta41,4,5) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 4));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 5));
if (listEmpty(tmpMeta43)) goto tmp3_end;
tmpMeta44 = MMC_CAR(tmpMeta43);
tmpMeta45 = MMC_CDR(tmpMeta43);
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 6));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_a = tmpMeta33;
_b = tmp35;
_c = tmp37;
_d = tmp39;
_e = tmpMeta40;
_cmt = tmpMeta42;
_rest = tmpMeta45;
_ann = tmpMeta46;
_file_info = tmpMeta47;
tmpMeta48 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta49 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta50 = mmc_mk_box6(3, &Absyn_ClassDef_PARTS__desc, tmpMeta48, tmpMeta49, _rest, _ann, _cmt);
tmpMeta51 = mmc_mk_box8(3, &Absyn_Class_CLASS__desc, _a, mmc_mk_boolean(_b), mmc_mk_boolean(_c), mmc_mk_boolean(_d), _e, tmpMeta50, _file_info);
_inClass = tmpMeta51;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inClass;
tmp4_2 = _inRestriction;
{
modelica_metatype _d = NULL;
modelica_metatype _name = NULL;
modelica_integer _index;
modelica_boolean _singleton;
modelica_boolean _isImpure;
modelica_boolean _moved;
modelica_metatype _purity = NULL;
modelica_metatype _typeVars = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 25; tmp4++) {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_purity = tmpMeta7;
_d = tmp4_1;
_isImpure = omc_AbsynToSCode_translatePurity(threadData, _purity);
tmp12 = (modelica_boolean)omc_AbsynToSCode_containsExternalFuncDecl(threadData, _d);
if(tmp12)
{
tmpMeta8 = mmc_mk_box2(4, &SCode_FunctionRestriction_FR__EXTERNAL__FUNCTION__desc, mmc_mk_boolean(_isImpure));
tmpMeta9 = mmc_mk_box2(12, &SCode_Restriction_R__FUNCTION__desc, tmpMeta8);
tmpMeta13 = tmpMeta9;
}
else
{
tmpMeta10 = mmc_mk_box2(3, &SCode_FunctionRestriction_FR__NORMAL__FUNCTION__desc, mmc_mk_boolean(_isImpure));
tmpMeta11 = mmc_mk_box2(12, &SCode_Restriction_R__FUNCTION__desc, tmpMeta10);
tmpMeta13 = tmpMeta11;
}
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,1,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT108;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,2,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT110;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,3,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT112;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT113;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT114;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT115;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT116;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,11,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT117;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT118;
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT119;
goto tmp3_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,0) == 0) goto tmp3_end;
omc_System_setHasExpandableConnectors(threadData, 1);
tmpMeta1 = _OMC_LIT120;
goto tmp3_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,10,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT81;
goto tmp3_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT49;
goto tmp3_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,8,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT121;
goto tmp3_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,12,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT122;
goto tmp3_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT123;
goto tmp3_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,14,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT124;
goto tmp3_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,15,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT125;
goto tmp3_done;
}
case 19: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT126;
goto tmp3_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,18,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT127;
goto tmp3_done;
}
case 21: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,17,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT128;
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_integer tmp19;
modelica_metatype tmpMeta20;
modelica_integer tmp21;
modelica_metatype tmpMeta22;
modelica_integer tmp23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,20,5) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp19 = mmc_unbox_integer(tmpMeta18);
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmp21 = mmc_unbox_integer(tmpMeta20);
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
tmp23 = mmc_unbox_integer(tmpMeta22);
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
_name = tmpMeta17;
_index = tmp19;
_singleton = tmp21;
_moved = tmp23;
_typeVars = tmpMeta24;
tmpMeta25 = mmc_mk_box6(20, &SCode_Restriction_R__METARECORD__desc, _name, mmc_mk_integer(_index), mmc_mk_boolean(_singleton), mmc_mk_boolean(_moved), _typeVars);
tmpMeta1 = tmpMeta25;
goto tmp3_done;
}
case 23: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,0,5) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,19,0) == 0) goto tmp3_end;
_typeVars = tmpMeta27;
tmpMeta28 = mmc_mk_box2(21, &SCode_Restriction_R__UNIONTYPE__desc, _typeVars);
tmpMeta1 = tmpMeta28;
goto tmp3_done;
}
case 24: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,19,0) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT129;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outRestriction = tmpMeta1;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inOperator;
{
modelica_metatype _els = NULL;
modelica_string _opername = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,6,0) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,0,8) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_opername = tmpMeta6;
_els = tmpMeta9;
tmpMeta1 = omc_List_map1(threadData, _els, boxvar_AbsynToSCode_getOperatorQualName, _opername);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,9,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,2,0) == 0) goto tmp3_end;
_opername = tmpMeta10;
tmpMeta14 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _opername);
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
_outNames = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outNames;
}
DLLExport
modelica_metatype omc_AbsynToSCode_getOperatorQualName(threadData_t *threadData, modelica_metatype _inOperatorFunction, modelica_string _operName)
{
modelica_metatype _outName = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_string tmp4_2;
tmp4_1 = _inOperatorFunction;
tmp4_2 = _operName;
{
modelica_string _name = NULL;
modelica_string _opname = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,9,1) == 0) goto tmp3_end;
_name = tmpMeta6;
_opname = tmp4_2;
tmpMeta8 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _opname);
tmpMeta9 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
tmpMeta1 = omc_AbsynUtil_joinPaths(threadData, tmpMeta8, tmpMeta9);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outName = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outName;
}
DLLExport
modelica_metatype omc_AbsynToSCode_getOperatorGivenName(threadData_t *threadData, modelica_metatype _inOperatorFunction)
{
modelica_metatype _outName = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inOperatorFunction;
{
modelica_string _name = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,8) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,9,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,0) == 0) goto tmp3_end;
_name = tmpMeta6;
tmpMeta9 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outName = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outName;
}
DLLExport
modelica_metatype omc_AbsynToSCode_translateOperatorDef(threadData_t *threadData, modelica_metatype _inClassDef, modelica_string _operatorName, modelica_metatype _info, modelica_metatype *out_cmt)
{
modelica_metatype _outOperDef = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,5) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_parts = tmpMeta6;
_aann = tmpMeta7;
_cmtString = tmpMeta8;
_els = omc_AbsynToSCode_translateClassdefElements(threadData, _parts);
_cmt = omc_AbsynToSCode_translateCommentList(threadData, _aann, _cmtString);
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta11 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta15 = mmc_mk_box9(3, &SCode_ClassDef_PARTS__desc, _els, tmpMeta9, tmpMeta10, tmpMeta11, tmpMeta12, tmpMeta13, tmpMeta14, mmc_mk_none());
tmpMeta[0+0] = tmpMeta15;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inClass;
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
modelica_integer tmp8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
modelica_integer tmp12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp8 = mmc_unbox_integer(tmpMeta7);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp10 = mmc_unbox_integer(tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp12 = mmc_unbox_integer(tmpMeta11);
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_c = tmp4_1;
_n = tmpMeta6;
_p = tmp8;
_f = tmp10;
_e = tmp12;
_r = tmpMeta13;
_d = tmpMeta14;
_file_info = tmpMeta15;
_r_1 = omc_AbsynToSCode_translateRestriction(threadData, _c, _r);
_d_1 = omc_AbsynToSCode_translateClassdef(threadData, _d, _file_info, _r_1 ,&_cmt);
_sFin = omc_SCodeUtil_boolFinal(threadData, _f);
_sEnc = omc_SCodeUtil_boolEncapsulated(threadData, _e);
_sPar = omc_SCodeUtil_boolPartial(threadData, _p);
tmpMeta16 = mmc_mk_box6(3, &SCode_Prefixes_PREFIXES__desc, _OMC_LIT41, _OMC_LIT42, _sFin, _OMC_LIT44, _OMC_LIT45);
tmpMeta17 = mmc_mk_box9(5, &SCode_Element_CLASS__desc, _n, tmpMeta16, _sEnc, _sPar, _r_1, _d_1, _cmt, _file_info);
tmpMeta1 = tmpMeta17;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_boolean tmp20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_n = tmpMeta18;
_file_info = tmpMeta19;
tmp20 = (omc_Error_getNumMessages(threadData) == _inNumMessages);
if (1 != tmp20) goto goto_2;
tmpMeta21 = stringAppend(_OMC_LIT132,_n);
_n = tmpMeta21;
tmpMeta22 = mmc_mk_cons(_n, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT56, tmpMeta22, _file_info);
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
_outClass = tmpMeta1;
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
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _inClasses = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
omc_InstHashTable_init(threadData);
tmpMeta6 = omc_MetaUtil_createMetaClassesInProgram(threadData, _inProgram);
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_inClasses = tmpMeta7;
omc_System_setHasInnerOuterDefinitions(threadData, 0);
omc_System_setHasExpandableConnectors(threadData, 0);
omc_System_setHasOverconstrainedConnectors(threadData, 0);
omc_System_setHasStreamConnectors(threadData, 0);
{
modelica_metatype __omcQ_24tmpVar9;
modelica_metatype* tmp9;
modelica_metatype tmpMeta10;
modelica_metatype __omcQ_24tmpVar8;
modelica_integer tmp11;
modelica_metatype _c_loopVar = 0;
modelica_metatype _c;
_c_loopVar = _inClasses;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar9 = tmpMeta10;
tmp9 = &__omcQ_24tmpVar9;
while(1) {
tmp11 = 1;
if (!listEmpty(_c_loopVar)) {
_c = MMC_CAR(_c_loopVar);
_c_loopVar = MMC_CDR(_c_loopVar);
tmp11--;
}
if (tmp11 == 0) {
__omcQ_24tmpVar8 = omc_AbsynToSCode_translateClass(threadData, _c);
*tmp9 = mmc_mk_cons(__omcQ_24tmpVar8,0);
tmp9 = &MMC_CDR(*tmp9);
} else if (tmp11 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp9 = mmc_mk_nil();
tmpMeta8 = __omcQ_24tmpVar9;
}
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
_outProgram = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outProgram;
}
