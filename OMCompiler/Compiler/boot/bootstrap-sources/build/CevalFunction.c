#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "CevalFunction.c"
#endif
#include "omc_simulation_settings.h"
#include "CevalFunction.h"
#define _OMC_LIT0_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,1,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "}, {"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,4,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "{"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,1,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data "}"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,1,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,0,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "Cyclically dependent constants or parameters found in scope %s: %s (ignore with -d=ignoreCycles)."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,97,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT8,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT7}};
#define _OMC_LIT8 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT8)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT9,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(170)),_OMC_LIT5,_OMC_LIT6,_OMC_LIT8}};
#define _OMC_LIT9 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,17,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT10}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT12,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT5,_OMC_LIT6,_OMC_LIT11}};
#define _OMC_LIT12 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "Different iterators in CevalFunction.compareIterators."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,54,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,2,1) {_OMC_LIT13,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,1,16) {&Values_Value_NORETCALL__desc,}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,9,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,41,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT17}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT16,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT18}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "- CevalFunction.getRecordVarBindingAndName failed on variable "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,62,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,1,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,2,3) {&Values_Value_INTEGER__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT23,0.0);
#define _OMC_LIT23 MMC_REFREALLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,2,4) {&Values_Value_REAL__desc,_OMC_LIT23}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,2,5) {&Values_Value_STRING__desc,_OMC_LIT4}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT26,2,6) {&Values_Value_BOOL__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT26 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT4}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,3,7) {&Values_Value_ENUM__LITERAL__desc,_OMC_LIT27,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "- CevalFunction.generateDefaultBinding failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,46,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,1,3) {&DAE_BindingSource_BINDING__FROM__DEFAULT__VALUE__desc,}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,1,4) {&FCore_Status_VAR__TYPED__desc,}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "- CevalFunction.assignVector failed on: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,40,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,2,3) {&DAE_Dimension_DIM__INTEGER__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,2,1) {_OMC_LIT33,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,2,3) {&DAE_Dimension_DIM__INTEGER__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(2))}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data "- CevalFunction.appendDimensions2 failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,41,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,1,3) {&DAE_Binding_UNBOUND__desc,}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,1,6) {&SCode_Variability_CONST__desc,}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,1,3) {&DAE_Const_C__CONST__desc,}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,1,1) {_OMC_LIT39}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "$functionEvaluation"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,19,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT42,2,24) {&FCore_Data_ND__desc,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT42 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT42)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT43,1,6) {&DAE_ConnectorType_NON__CONNECTOR__desc,}};
#define _OMC_LIT43 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,1,5) {&SCode_Parallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,1,3) {&SCode_Variability_VAR__desc,}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,1,5) {&Absyn_Direction_BIDIR__desc,}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,1,3) {&SCode_Visibility_PUBLIC__desc,}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,7,3) {&DAE_Attributes_ATTR__desc,_OMC_LIT43,_OMC_LIT44,_OMC_LIT45,_OMC_LIT46,_OMC_LIT47,_OMC_LIT48}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,1,4) {&SCode_Redeclare_NOT__REDECLARE__desc,}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,1,4) {&SCode_Final_NOT__FINAL__desc,}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,1,4) {&SCode_Replaceable_NOT__REPLACEABLE__desc,}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,6,3) {&SCode_Prefixes_PREFIXES__desc,_OMC_LIT48,_OMC_LIT50,_OMC_LIT51,_OMC_LIT47,_OMC_LIT52}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,1,3) {&SCode_ConnectorType_POTENTIAL__desc,}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT55,1,3) {&Absyn_IsField_NONFIELD__desc,}};
#define _OMC_LIT55 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,7,3) {&SCode_Attributes_ATTR__desc,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT54,_OMC_LIT44,_OMC_LIT45,_OMC_LIT46,_OMC_LIT55}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT57,3,3) {&Absyn_TypeSpec_TPATH__desc,_OMC_LIT27,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT57 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT57)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT58,1,5) {&SCode_Mod_NOMOD__desc,}};
#define _OMC_LIT58 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT58)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT59,3,3) {&SCode_Comment_COMMENT__desc,MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT59 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT59)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT60,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT4,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT23}};
#define _OMC_LIT60 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT60)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT61,1,5) {&DAE_Mod_NOMOD__desc,}};
#define _OMC_LIT61 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "- CevalFunction.extendEnvWithFunctionVars failed for:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,53,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT63,1,4) {&SCode_Encapsulated_NOT__ENCAPSULATED__desc,}};
#define _OMC_LIT63 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT63)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT64,1,3) {&FCore_ScopeType_FUNCTION__SCOPE__desc,}};
#define _OMC_LIT64 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT64)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT65,1,1) {_OMC_LIT64}};
#define _OMC_LIT65 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT65)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT66,2,3) {&Absyn_Msg_MSG__desc,_OMC_LIT60}};
#define _OMC_LIT66 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT66)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT67,1,18) {&Values_Value_META__FAIL__desc,}};
#define _OMC_LIT67 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "- CevalFunction.extractLhsComponentRef failed on "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,49,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT69,1,3) {&CevalFunction_LoopControl_NEXT__desc,}};
#define _OMC_LIT69 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data "- evaluateForStatement not implemented for:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,43,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT71,1,5) {&CevalFunction_LoopControl_RETURN__desc,}};
#define _OMC_LIT71 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT71)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT72,1,4) {&CevalFunction_LoopControl_BREAK__desc,}};
#define _OMC_LIT72 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT72)
#define _OMC_LIT73_data "- CevalFunction.evaluateStatement failed for:"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,45,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
#define _OMC_LIT74_data "dgeev"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT74,5,_OMC_LIT74_data);
#define _OMC_LIT74 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT74)
#define _OMC_LIT75_data "dgegv"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT75,5,_OMC_LIT75_data);
#define _OMC_LIT75 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT75)
#define _OMC_LIT76_data "dgels"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT76,5,_OMC_LIT76_data);
#define _OMC_LIT76 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT76)
#define _OMC_LIT77_data "dgelsx"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT77,6,_OMC_LIT77_data);
#define _OMC_LIT77 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data "dgelsy"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,6,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
#define _OMC_LIT79_data "dgesv"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT79,5,_OMC_LIT79_data);
#define _OMC_LIT79 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT79)
#define _OMC_LIT80_data "dgglse"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT80,6,_OMC_LIT80_data);
#define _OMC_LIT80 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data "dgtsv"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,5,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data "dgbsv"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,5,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
#define _OMC_LIT83_data "dgesvd"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT83,6,_OMC_LIT83_data);
#define _OMC_LIT83 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT83)
#define _OMC_LIT84_data "dgetrf"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT84,6,_OMC_LIT84_data);
#define _OMC_LIT84 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT84)
#define _OMC_LIT85_data "dgetrs"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT85,6,_OMC_LIT85_data);
#define _OMC_LIT85 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT85)
#define _OMC_LIT86_data "dgetri"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT86,6,_OMC_LIT86_data);
#define _OMC_LIT86 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT86)
#define _OMC_LIT87_data "dgeqpf"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT87,6,_OMC_LIT87_data);
#define _OMC_LIT87 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT87)
#define _OMC_LIT88_data "dorgqr"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT88,6,_OMC_LIT88_data);
#define _OMC_LIT88 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT88)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT89,1,11) {&DAE_Type_T__UNKNOWN__desc,}};
#define _OMC_LIT89 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT89)
#define _OMC_LIT90_data "- CevalFunction.evaluateExtInputArg failed on "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT90,46,_OMC_LIT90_data);
#define _OMC_LIT90 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT90)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT91,1,7) {&DAE_Dimension_DIM__UNKNOWN__desc,}};
#define _OMC_LIT91 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT91)
#define _OMC_LIT92_data "- CevalFunction.pairFuncParamsWithArgs failed because of too few input arguments.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT92,82,_OMC_LIT92_data);
#define _OMC_LIT92 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT92)
#define _OMC_LIT93_data "- CevalFunction.evaluateFunction failed.\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT93,41,_OMC_LIT93_data);
#define _OMC_LIT93 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT93)
#define _OMC_LIT94_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT94,1,_OMC_LIT94_data);
#define _OMC_LIT94 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT94)
#define _OMC_LIT95_data "- CevalFunction.evaluate failed for function: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT95,46,_OMC_LIT95_data);
#define _OMC_LIT95 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT95)
#define _OMC_LIT96_data "partial "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT96,8,_OMC_LIT96_data);
#define _OMC_LIT96 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT96)
#include "util/modelica.h"
#include "CevalFunction_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_optimizeExpTraverser(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inEnv, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_optimizeExpTraverser,2,0) {(void*) boxptr_CevalFunction_optimizeExpTraverser,0}};
#define boxvar_CevalFunction_optimizeExpTraverser MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_optimizeExpTraverser)
PROTECTED_FUNCTION_STATIC void omc_CevalFunction_checkCyclicalComponents(threadData_t *threadData, modelica_metatype _inCycles, modelica_metatype _inSource);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_checkCyclicalComponents,2,0) {(void*) boxptr_CevalFunction_checkCyclicalComponents,0}};
#define boxvar_CevalFunction_checkCyclicalComponents MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_checkCyclicalComponents)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_CevalFunction_isElementEqual(threadData_t *threadData, modelica_metatype _inElement1, modelica_metatype _inElement2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_isElementEqual(threadData_t *threadData, modelica_metatype _inElement1, modelica_metatype _inElement2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_isElementEqual,2,0) {(void*) boxptr_CevalFunction_isElementEqual,0}};
#define boxvar_CevalFunction_isElementEqual MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_isElementEqual)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_CevalFunction_isElementNamed(threadData_t *threadData, modelica_metatype _inName, modelica_metatype _inElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_isElementNamed(threadData_t *threadData, modelica_metatype _inName, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_isElementNamed,2,0) {(void*) boxptr_CevalFunction_isElementNamed,0}};
#define boxvar_CevalFunction_isElementNamed MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_isElementNamed)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_compareIterators(threadData_t *threadData, modelica_metatype _inRiters, modelica_metatype _inIters);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_compareIterators,2,0) {(void*) boxptr_CevalFunction_compareIterators,0}};
#define boxvar_CevalFunction_compareIterators MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_compareIterators)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getElementDependenciesTraverserExit(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inArg, modelica_metatype *out_outArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getElementDependenciesTraverserExit,2,0) {(void*) boxptr_CevalFunction_getElementDependenciesTraverserExit,0}};
#define boxvar_CevalFunction_getElementDependenciesTraverserExit MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getElementDependenciesTraverserExit)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getElementDependenciesTraverserEnter(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inArg, modelica_metatype *out_outArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getElementDependenciesTraverserEnter,2,0) {(void*) boxptr_CevalFunction_getElementDependenciesTraverserEnter,0}};
#define boxvar_CevalFunction_getElementDependenciesTraverserEnter MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getElementDependenciesTraverserEnter)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getElementDependenciesFromDims(threadData_t *threadData, modelica_metatype _inDimension, modelica_metatype _inArg, modelica_metatype *out_outArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getElementDependenciesFromDims,2,0) {(void*) boxptr_CevalFunction_getElementDependenciesFromDims,0}};
#define boxvar_CevalFunction_getElementDependenciesFromDims MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getElementDependenciesFromDims)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getElementDependencies(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inAllElements);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getElementDependencies,2,0) {(void*) boxptr_CevalFunction_getElementDependencies,0}};
#define boxvar_CevalFunction_getElementDependencies MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getElementDependencies)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_sortFunctionVarsByDependency(threadData_t *threadData, modelica_metatype _inFuncVars, modelica_metatype _inSource);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_sortFunctionVarsByDependency,2,0) {(void*) boxptr_CevalFunction_sortFunctionVarsByDependency,0}};
#define boxvar_CevalFunction_sortFunctionVarsByDependency MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_sortFunctionVarsByDependency)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_boxReturnValue(threadData_t *threadData, modelica_metatype _inReturnValues);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_boxReturnValue,2,0) {(void*) boxptr_CevalFunction_boxReturnValue,0}};
#define boxvar_CevalFunction_boxReturnValue MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_boxReturnValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getRecordComponentValue(threadData_t *threadData, modelica_metatype _inVars, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getRecordComponentValue,2,0) {(void*) boxptr_CevalFunction_getRecordComponentValue,0}};
#define boxvar_CevalFunction_getRecordComponentValue MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getRecordComponentValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getRecordValue(threadData_t *threadData, modelica_metatype _inRecordName, modelica_metatype _inType, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getRecordValue,2,0) {(void*) boxptr_CevalFunction_getRecordValue,0}};
#define boxvar_CevalFunction_getRecordValue MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getRecordValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getVariableValue(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inType, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getVariableValue,2,0) {(void*) boxptr_CevalFunction_getVariableValue,0}};
#define boxvar_CevalFunction_getVariableValue MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getVariableValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getFunctionReturnValue(threadData_t *threadData, modelica_metatype _inOutputVar, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getFunctionReturnValue,2,0) {(void*) boxptr_CevalFunction_getFunctionReturnValue,0}};
#define boxvar_CevalFunction_getFunctionReturnValue MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getFunctionReturnValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getRecordVarBindingAndName(threadData_t *threadData, modelica_metatype _inVar, modelica_string *out_outName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getRecordVarBindingAndName,2,0) {(void*) boxptr_CevalFunction_getRecordVarBindingAndName,0}};
#define boxvar_CevalFunction_getRecordVarBindingAndName MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getRecordVarBindingAndName)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_generateDefaultBinding(threadData_t *threadData, modelica_metatype _inType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_generateDefaultBinding,2,0) {(void*) boxptr_CevalFunction_generateDefaultBinding,0}};
#define boxvar_CevalFunction_generateDefaultBinding MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_generateDefaultBinding)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getBindingOrDefault(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _inType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getBindingOrDefault,2,0) {(void*) boxptr_CevalFunction_getBindingOrDefault,0}};
#define boxvar_CevalFunction_getBindingOrDefault MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getBindingOrDefault)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getBindingValueOpt(threadData_t *threadData, modelica_metatype _inBinding);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getBindingValueOpt,2,0) {(void*) boxptr_CevalFunction_getBindingValueOpt,0}};
#define boxvar_CevalFunction_getBindingValueOpt MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getBindingValueOpt)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getVariableTypeAndValue(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inEnv, modelica_metatype *out_outValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getVariableTypeAndValue,2,0) {(void*) boxptr_CevalFunction_getVariableTypeAndValue,0}};
#define boxvar_CevalFunction_getVariableTypeAndValue MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getVariableTypeAndValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getVariableTypeAndBinding(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inEnv, modelica_metatype *out_outBinding);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getVariableTypeAndBinding,2,0) {(void*) boxptr_CevalFunction_getVariableTypeAndBinding,0}};
#define boxvar_CevalFunction_getVariableTypeAndBinding MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getVariableTypeAndBinding)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_updateRecordComponentValue(threadData_t *threadData, modelica_string _inComponentId, modelica_metatype _inComponentValue, modelica_metatype _inRecordValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_updateRecordComponentValue,2,0) {(void*) boxptr_CevalFunction_updateRecordComponentValue,0}};
#define boxvar_CevalFunction_updateRecordComponentValue MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_updateRecordComponentValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_updateRecordComponentBinding(threadData_t *threadData, modelica_metatype _inVar, modelica_string _inComponentId, modelica_metatype _inValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_updateRecordComponentBinding,2,0) {(void*) boxptr_CevalFunction_updateRecordComponentBinding,0}};
#define boxvar_CevalFunction_updateRecordComponentBinding MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_updateRecordComponentBinding)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_updateRecordBinding(threadData_t *threadData, modelica_metatype _inVar, modelica_metatype _inValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_updateRecordBinding,2,0) {(void*) boxptr_CevalFunction_updateRecordBinding,0}};
#define boxvar_CevalFunction_updateRecordBinding MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_updateRecordBinding)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_updateVariableBinding(threadData_t *threadData, modelica_metatype _inVariableCref, modelica_metatype _inEnv, modelica_metatype _inType, modelica_metatype _inNewValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_updateVariableBinding,2,0) {(void*) boxptr_CevalFunction_updateVariableBinding,0}};
#define boxvar_CevalFunction_updateVariableBinding MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_updateVariableBinding)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignWholeDim(threadData_t *threadData, modelica_metatype _inNewValues, modelica_metatype _inOldValues, modelica_metatype _inSubscripts, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outResult);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_assignWholeDim,2,0) {(void*) boxptr_CevalFunction_assignWholeDim,0}};
#define boxvar_CevalFunction_assignWholeDim MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_assignWholeDim)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignSlice(threadData_t *threadData, modelica_metatype _inNewValues, modelica_metatype _inOldValues, modelica_metatype _inIndices, modelica_metatype _inSubscripts, modelica_integer _inIndex, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outResult);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_assignSlice(threadData_t *threadData, modelica_metatype _inNewValues, modelica_metatype _inOldValues, modelica_metatype _inIndices, modelica_metatype _inSubscripts, modelica_metatype _inIndex, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outResult);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_assignSlice,2,0) {(void*) boxptr_CevalFunction_assignSlice,0}};
#define boxvar_CevalFunction_assignSlice MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_assignSlice)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignRecordComponents(threadData_t *threadData, modelica_metatype _inVars, modelica_metatype _inValues, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_assignRecordComponents,2,0) {(void*) boxptr_CevalFunction_assignRecordComponents,0}};
#define boxvar_CevalFunction_assignRecordComponents MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_assignRecordComponents)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignRecord(threadData_t *threadData, modelica_metatype _inType, modelica_metatype _inValue, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_assignRecord,2,0) {(void*) boxptr_CevalFunction_assignRecord,0}};
#define boxvar_CevalFunction_assignRecord MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_assignRecord)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignTuple(threadData_t *threadData, modelica_metatype _inLhsCrefs, modelica_metatype _inRhsValues, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_assignTuple,2,0) {(void*) boxptr_CevalFunction_assignTuple,0}};
#define boxvar_CevalFunction_assignTuple MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_assignTuple)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignVariable(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inNewValue, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_assignVariable,2,0) {(void*) boxptr_CevalFunction_assignVariable,0}};
#define boxvar_CevalFunction_assignVariable MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_assignVariable)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_appendDimensions2(threadData_t *threadData, modelica_metatype _inType, modelica_metatype _inDims, modelica_metatype _inBindingDims, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_appendDimensions2,2,0) {(void*) boxptr_CevalFunction_appendDimensions2,0}};
#define boxvar_CevalFunction_appendDimensions2 MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_appendDimensions2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_appendDimensions(threadData_t *threadData, modelica_metatype _inType, modelica_metatype _inOptBinding, modelica_metatype _inDims, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_appendDimensions,2,0) {(void*) boxptr_CevalFunction_appendDimensions,0}};
#define boxvar_CevalFunction_appendDimensions MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_appendDimensions)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extendEnvWithForScope(threadData_t *threadData, modelica_string _inIterName, modelica_metatype _inIterType, modelica_metatype _inEnv, modelica_metatype *out_outIterType, modelica_metatype *out_outIterCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_extendEnvWithForScope,2,0) {(void*) boxptr_CevalFunction_extendEnvWithForScope,0}};
#define boxvar_CevalFunction_extendEnvWithForScope MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_extendEnvWithForScope)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extendEnvWithRecordVar(threadData_t *threadData, modelica_metatype _inVar, modelica_metatype _inOptValue, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_extendEnvWithRecordVar,2,0) {(void*) boxptr_CevalFunction_extendEnvWithRecordVar,0}};
#define boxvar_CevalFunction_extendEnvWithRecordVar MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_extendEnvWithRecordVar)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getRecordValues(threadData_t *threadData, modelica_metatype _inOptValue, modelica_metatype _inRecordType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_getRecordValues,2,0) {(void*) boxptr_CevalFunction_getRecordValues,0}};
#define boxvar_CevalFunction_getRecordValues MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_getRecordValues)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_makeRecordEnvironment(threadData_t *threadData, modelica_metatype _inRecordType, modelica_metatype _inOptValue, modelica_metatype _inCache, modelica_metatype _inGraph, modelica_metatype *out_outRecordEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_makeRecordEnvironment,2,0) {(void*) boxptr_CevalFunction_makeRecordEnvironment,0}};
#define boxvar_CevalFunction_makeRecordEnvironment MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_makeRecordEnvironment)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_makeBinding(threadData_t *threadData, modelica_metatype _inBindingValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_makeBinding,2,0) {(void*) boxptr_CevalFunction_makeBinding,0}};
#define boxvar_CevalFunction_makeBinding MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_makeBinding)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_makeFunctionVariable(threadData_t *threadData, modelica_string _inName, modelica_metatype _inType, modelica_metatype _inBinding);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_makeFunctionVariable,2,0) {(void*) boxptr_CevalFunction_makeFunctionVariable,0}};
#define boxvar_CevalFunction_makeFunctionVariable MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_makeFunctionVariable)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extendEnvWithVar(threadData_t *threadData, modelica_string _inName, modelica_metatype _inType, modelica_metatype _inOptValue, modelica_metatype _inDims, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_extendEnvWithVar,2,0) {(void*) boxptr_CevalFunction_extendEnvWithVar,0}};
#define boxvar_CevalFunction_extendEnvWithVar MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_extendEnvWithVar)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extendEnvWithElement(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inBindingValue, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_extendEnvWithElement,2,0) {(void*) boxptr_CevalFunction_extendEnvWithElement,0}};
#define boxvar_CevalFunction_extendEnvWithElement MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_extendEnvWithElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateBinding(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateBinding,2,0) {(void*) boxptr_CevalFunction_evaluateBinding,0}};
#define boxvar_CevalFunction_evaluateBinding MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateBinding)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extendEnvWithFunctionVar(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inFuncParam, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_extendEnvWithFunctionVar,2,0) {(void*) boxptr_CevalFunction_extendEnvWithFunctionVar,0}};
#define boxvar_CevalFunction_extendEnvWithFunctionVar MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_extendEnvWithFunctionVar)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extendEnvWithFunctionVars(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inFuncParams, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_extendEnvWithFunctionVars,2,0) {(void*) boxptr_CevalFunction_extendEnvWithFunctionVars,0}};
#define boxvar_CevalFunction_extendEnvWithFunctionVars MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_extendEnvWithFunctionVars)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_setupFunctionEnvironment(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _inFuncName, modelica_metatype _inFuncParams, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_setupFunctionEnvironment,2,0) {(void*) boxptr_CevalFunction_setupFunctionEnvironment,0}};
#define boxvar_CevalFunction_setupFunctionEnvironment MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_setupFunctionEnvironment)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_cevalExpList(threadData_t *threadData, modelica_metatype _inExpLst, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_cevalExpList,2,0) {(void*) boxptr_CevalFunction_cevalExpList,0}};
#define boxvar_CevalFunction_cevalExpList MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_cevalExpList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_cevalExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_cevalExp,2,0) {(void*) boxptr_CevalFunction_cevalExp,0}};
#define boxvar_CevalFunction_cevalExp MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_cevalExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extractLhsComponentRef(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_extractLhsComponentRef,2,0) {(void*) boxptr_CevalFunction_extractLhsComponentRef,0}};
#define boxvar_CevalFunction_extractLhsComponentRef MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_extractLhsComponentRef)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateWhileStatement(threadData_t *threadData, modelica_metatype _inCondition, modelica_metatype _inStatements, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inLoopControl, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateWhileStatement,2,0) {(void*) boxptr_CevalFunction_evaluateWhileStatement,0}};
#define boxvar_CevalFunction_evaluateWhileStatement MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateWhileStatement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateForLoopArray(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIter, modelica_metatype _inIterType, modelica_metatype _inValues, modelica_metatype _inStatements, modelica_metatype _inLoopControl, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateForLoopArray,2,0) {(void*) boxptr_CevalFunction_evaluateForLoopArray,0}};
#define boxvar_CevalFunction_evaluateForLoopArray MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateForLoopArray)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateForStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateForStatement,2,0) {(void*) boxptr_CevalFunction_evaluateForStatement,0}};
#define boxvar_CevalFunction_evaluateForStatement MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateForStatement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateIfStatement2(threadData_t *threadData, modelica_boolean _inCondition, modelica_metatype _inStatements, modelica_metatype _inElse, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_evaluateIfStatement2(threadData_t *threadData, modelica_metatype _inCondition, modelica_metatype _inStatements, modelica_metatype _inElse, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateIfStatement2,2,0) {(void*) boxptr_CevalFunction_evaluateIfStatement2,0}};
#define boxvar_CevalFunction_evaluateIfStatement2 MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateIfStatement2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateIfStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateIfStatement,2,0) {(void*) boxptr_CevalFunction_evaluateIfStatement,0}};
#define boxvar_CevalFunction_evaluateIfStatement MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateIfStatement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateTupleAssignStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateTupleAssignStatement,2,0) {(void*) boxptr_CevalFunction_evaluateTupleAssignStatement,0}};
#define boxvar_CevalFunction_evaluateTupleAssignStatement MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateTupleAssignStatement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateStatements2(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inLoopControl, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateStatements2,2,0) {(void*) boxptr_CevalFunction_evaluateStatements2,0}};
#define boxvar_CevalFunction_evaluateStatements2 MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateStatements2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateStatements(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateStatements,2,0) {(void*) boxptr_CevalFunction_evaluateStatements,0}};
#define boxvar_CevalFunction_evaluateStatements MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateStatements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateStatement,2,0) {(void*) boxptr_CevalFunction_evaluateStatement,0}};
#define boxvar_CevalFunction_evaluateStatement MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateStatement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateElement(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateElement,2,0) {(void*) boxptr_CevalFunction_evaluateElement,0}};
#define boxvar_CevalFunction_evaluateElement MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateElements(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inLoopControl, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateElements,2,0) {(void*) boxptr_CevalFunction_evaluateElements,0}};
#define boxvar_CevalFunction_evaluateElements MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateElements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateExternalFunc(threadData_t *threadData, modelica_string _inFuncName, modelica_metatype _inFuncArgs, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExternalFunc,2,0) {(void*) boxptr_CevalFunction_evaluateExternalFunc,0}};
#define boxvar_CevalFunction_evaluateExternalFunc MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExternalFunc)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_unliftExtOutputValue(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_unliftExtOutputValue,2,0) {(void*) boxptr_CevalFunction_unliftExtOutputValue,0}};
#define boxvar_CevalFunction_unliftExtOutputValue MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_unliftExtOutputValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignExtOutputs(threadData_t *threadData, modelica_metatype _inArgs, modelica_metatype _inValues, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_assignExtOutputs,2,0) {(void*) boxptr_CevalFunction_assignExtOutputs,0}};
#define boxvar_CevalFunction_assignExtOutputs MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_assignExtOutputs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateExtOutputArg(threadData_t *threadData, modelica_metatype _inArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtOutputArg,2,0) {(void*) boxptr_CevalFunction_evaluateExtOutputArg,0}};
#define boxvar_CevalFunction_evaluateExtOutputArg MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtOutputArg)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateExtRealMatrixArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtRealMatrixArg,2,0) {(void*) boxptr_CevalFunction_evaluateExtRealMatrixArg,0}};
#define boxvar_CevalFunction_evaluateExtRealMatrixArg MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtRealMatrixArg)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateExtRealArrayArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtRealArrayArg,2,0) {(void*) boxptr_CevalFunction_evaluateExtRealArrayArg,0}};
#define boxvar_CevalFunction_evaluateExtRealArrayArg MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtRealArrayArg)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateExtIntArrayArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtIntArrayArg,2,0) {(void*) boxptr_CevalFunction_evaluateExtIntArrayArg,0}};
#define boxvar_CevalFunction_evaluateExtIntArrayArg MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtIntArrayArg)
PROTECTED_FUNCTION_STATIC modelica_string omc_CevalFunction_evaluateExtStringArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtStringArg,2,0) {(void*) boxptr_CevalFunction_evaluateExtStringArg,0}};
#define boxvar_CevalFunction_evaluateExtStringArg MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtStringArg)
PROTECTED_FUNCTION_STATIC modelica_real omc_CevalFunction_evaluateExtRealArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_evaluateExtRealArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtRealArg,2,0) {(void*) boxptr_CevalFunction_evaluateExtRealArg,0}};
#define boxvar_CevalFunction_evaluateExtRealArg MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtRealArg)
PROTECTED_FUNCTION_STATIC modelica_integer omc_CevalFunction_evaluateExtIntArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_evaluateExtIntArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtIntArg,2,0) {(void*) boxptr_CevalFunction_evaluateExtIntArg,0}};
#define boxvar_CevalFunction_evaluateExtIntArg MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtIntArg)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateExtInputArg(threadData_t *threadData, modelica_metatype _inArgument, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtInputArg,2,0) {(void*) boxptr_CevalFunction_evaluateExtInputArg,0}};
#define boxvar_CevalFunction_evaluateExtInputArg MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateExtInputArg)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_CevalFunction_isCrefNamed(threadData_t *threadData, modelica_string _inName, modelica_metatype _inCref);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_isCrefNamed(threadData_t *threadData, modelica_metatype _inName, modelica_metatype _inCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_isCrefNamed,2,0) {(void*) boxptr_CevalFunction_isCrefNamed,0}};
#define boxvar_CevalFunction_isCrefNamed MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_isCrefNamed)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_removeSelfReferentialDim(threadData_t *threadData, modelica_metatype _inDim, modelica_string _inName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_removeSelfReferentialDim,2,0) {(void*) boxptr_CevalFunction_removeSelfReferentialDim,0}};
#define boxvar_CevalFunction_removeSelfReferentialDim MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_removeSelfReferentialDim)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_removeSelfReferentialDims(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_removeSelfReferentialDims,2,0) {(void*) boxptr_CevalFunction_removeSelfReferentialDims,0}};
#define boxvar_CevalFunction_removeSelfReferentialDims MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_removeSelfReferentialDims)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_pairFuncParamsWithArgs(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inValues);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_pairFuncParamsWithArgs,2,0) {(void*) boxptr_CevalFunction_pairFuncParamsWithArgs,0}};
#define boxvar_CevalFunction_pairFuncParamsWithArgs MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_pairFuncParamsWithArgs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateFunctionDefinition(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _inFuncName, modelica_metatype _inFunc, modelica_metatype _inFuncType, modelica_metatype _inFuncArgs, modelica_metatype _inSource, modelica_metatype *out_outResult);
static const MMC_DEFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateFunctionDefinition,2,0) {(void*) boxptr_CevalFunction_evaluateFunctionDefinition,0}};
#define boxvar_CevalFunction_evaluateFunctionDefinition MMC_REFSTRUCTLIT(boxvar_lit_CevalFunction_evaluateFunctionDefinition)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_optimizeExpTraverser(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inEnv, modelica_metatype *out_outEnv)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inEnv;
{
modelica_metatype _cref = NULL;
modelica_metatype _ety = NULL;
modelica_metatype _sub_exps = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _env = NULL;
modelica_metatype _exp = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cref = tmpMeta7;
_ety = tmpMeta8;
_sub_exps = tmpMeta9;
_env = tmp4_2;
_subs = omc_List_map(threadData, _sub_exps, boxvar_Expression_makeIndexSubscript);
_cref = omc_ComponentReference_subscriptCref(threadData, _cref, _subs);
_exp = omc_Expression_makeCrefExp(threadData, _cref, _ety);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _env;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,19,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
if (listEmpty(tmpMeta11)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmpMeta11);
tmpMeta13 = MMC_CDR(tmpMeta11);
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp15 = mmc_unbox_integer(tmpMeta14);
if (1 != tmp15) goto tmp3_end;
_exp = tmpMeta12;
_env = tmp4_2;
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _env;
goto tmp3_done;
}
case 2: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inEnv;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outExp = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC void omc_CevalFunction_checkCyclicalComponents(threadData_t *threadData, modelica_metatype _inCycles, modelica_metatype _inSource)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inCycles;
{
modelica_metatype _cycles = NULL;
modelica_metatype _elements = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype _names = NULL;
modelica_metatype _cycles_strs = NULL;
modelica_string _cycles_str = NULL;
modelica_string _scope_str = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
goto tmp2_done;
}
case 1: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
_cycles = omc_Graph_findCycles(threadData, _inCycles, boxvar_CevalFunction_isElementEqual);
_elements = omc_List_mapList(threadData, _cycles, boxvar_Util_tuple21);
_crefs = omc_List_mapList(threadData, _elements, boxvar_DAEUtil_varCref);
_names = omc_List_mapList(threadData, _crefs, boxvar_ComponentReference_printComponentRefStr);
_cycles_strs = omc_List_map1(threadData, _names, boxvar_stringDelimitList, _OMC_LIT0);
_cycles_str = stringDelimitList(_cycles_strs, _OMC_LIT1);
tmpMeta5 = stringAppend(_OMC_LIT2,_cycles_str);
tmpMeta6 = stringAppend(tmpMeta5,_OMC_LIT3);
_cycles_str = tmpMeta6;
_scope_str = _OMC_LIT4;
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _inSource);
tmpMeta7 = mmc_mk_cons(_scope_str, mmc_mk_cons(_cycles_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT9, tmpMeta7, _info);
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
PROTECTED_FUNCTION_STATIC modelica_boolean omc_CevalFunction_isElementEqual(threadData_t *threadData, modelica_metatype _inElement1, modelica_metatype _inElement2)
{
modelica_boolean _isEqual;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inElement1;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
_cr1 = tmpMeta3;
tmpMeta4 = _inElement2;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta4), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
_cr2 = tmpMeta6;
_isEqual = omc_ComponentReference_crefEqualWithoutSubs(threadData, _cr1, _cr2);
_return: OMC_LABEL_UNUSED
return _isEqual;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_isElementEqual(threadData_t *threadData, modelica_metatype _inElement1, modelica_metatype _inElement2)
{
modelica_boolean _isEqual;
modelica_metatype out_isEqual;
_isEqual = omc_CevalFunction_isElementEqual(threadData, _inElement1, _inElement2);
out_isEqual = mmc_mk_icon(_isEqual);
return out_isEqual;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_CevalFunction_isElementNamed(threadData_t *threadData, modelica_metatype _inName, modelica_metatype _inElement)
{
modelica_boolean _isNamed;
modelica_metatype _name = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inElement;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
_name = tmpMeta3;
_isNamed = omc_ComponentReference_crefEqualWithoutSubs(threadData, _name, _inName);
_return: OMC_LABEL_UNUSED
return _isNamed;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_isElementNamed(threadData_t *threadData, modelica_metatype _inName, modelica_metatype _inElement)
{
modelica_boolean _isNamed;
modelica_metatype out_isNamed;
_isNamed = omc_CevalFunction_isElementNamed(threadData, _inName, _inElement);
out_isNamed = mmc_mk_icon(_isNamed);
return out_isNamed;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_compareIterators(threadData_t *threadData, modelica_metatype _inRiters, modelica_metatype _inIters)
{
modelica_metatype _outIters = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inRiters;
tmp4_2 = _inIters;
{
modelica_string _id1 = NULL;
modelica_string _id2 = NULL;
modelica_metatype _riters = NULL;
modelica_metatype _iters = NULL;
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
modelica_boolean tmp11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_2);
tmpMeta10 = MMC_CDR(tmp4_2);
_id1 = tmpMeta8;
_riters = tmpMeta7;
_id2 = tmpMeta9;
_iters = tmpMeta10;
tmp4 += 1;
tmp11 = (stringEqual(_id1, _id2));
if (1 != tmp11) goto goto_2;
tmpMeta1 = omc_CevalFunction_compareIterators(threadData, _riters, _iters);
goto tmp3_done;
}
case 1: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _inIters;
goto tmp3_done;
}
case 2: {
omc_Error_addMessage(threadData, _OMC_LIT12, _OMC_LIT14);
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
_outIters = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outIters;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getElementDependenciesTraverserExit(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inArg;
{
modelica_metatype _exp = NULL;
modelica_metatype _all_el = NULL;
modelica_metatype _accum_el = NULL;
modelica_metatype _iters = NULL;
modelica_metatype _riters = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_exp = tmp4_1;
_riters = tmpMeta6;
_all_el = tmpMeta7;
_accum_el = tmpMeta8;
_iters = tmpMeta9;
_iters = omc_CevalFunction_compareIterators(threadData, listReverse(_riters), _iters);
tmpMeta10 = mmc_mk_box3(0, _all_el, _accum_el, _iters);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = tmpMeta10;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
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
_outExp = tmpMeta[0+0];
_outArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getElementDependenciesTraverserEnter(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inArg;
{
modelica_metatype _exp = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _all_el = NULL;
modelica_metatype _accum_el = NULL;
modelica_metatype _e = NULL;
modelica_string _iter = NULL;
modelica_metatype _iters = NULL;
modelica_metatype _riters = NULL;
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
modelica_boolean tmp13;
modelica_metatype tmpMeta14;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,1,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_all_el = tmpMeta6;
_accum_el = tmpMeta7;
_iters = tmpMeta8;
_exp = tmp4_1;
_iter = tmpMeta12;
tmp13 = omc_List_isMemberOnTrue(threadData, _iter, _iters, boxvar_stringEqual);
if (1 != tmp13) goto goto_2;
tmpMeta14 = mmc_mk_box3(0, _all_el, _accum_el, _iters);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = tmpMeta14;
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
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_exp = tmp4_1;
_cref = tmpMeta15;
_all_el = tmpMeta16;
_accum_el = tmpMeta17;
_iters = tmpMeta18;
tmp4 += 1;
tmpMeta21 = omc_List_deleteMemberOnTrue(threadData, _cref, _all_el, boxvar_CevalFunction_isElementNamed, &tmpMeta19);
_all_el = tmpMeta21;
if (optionNone(tmpMeta19)) goto goto_2;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 1));
_e = tmpMeta20;
tmpMeta22 = mmc_mk_cons(_e, _accum_el);
tmpMeta23 = mmc_mk_box3(0, _all_el, tmpMeta22, _iters);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = tmpMeta23;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_exp = tmp4_1;
_riters = tmpMeta24;
_all_el = tmpMeta25;
_accum_el = tmpMeta26;
_iters = tmpMeta27;
_iters = listAppend(omc_List_map(threadData, _riters, boxvar_Expression_reductionIterName), _iters);
tmpMeta28 = mmc_mk_box3(0, _all_el, _accum_el, _iters);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = tmpMeta28;
goto tmp3_done;
}
case 3: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inArg;
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
_outExp = tmpMeta[0+0];
_outArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getElementDependenciesFromDims(threadData_t *threadData, modelica_metatype _inDimension, modelica_metatype _inArg, modelica_metatype *out_outArg)
{
modelica_metatype _outDimension = NULL;
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _arg = NULL;
modelica_metatype _dim_exp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_dim_exp = omc_Expression_dimensionSizeExp(threadData, _inDimension);
omc_Expression_traverseExpBidir(threadData, _dim_exp, boxvar_CevalFunction_getElementDependenciesTraverserEnter, boxvar_CevalFunction_getElementDependenciesTraverserExit, _inArg ,&_arg);
tmpMeta[0+0] = _inDimension;
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inDimension;
tmpMeta[0+1] = _inArg;
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
_outDimension = tmpMeta[0+0];
_outArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outArg) { *out_outArg = _outArg; }
return _outDimension;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getElementDependencies(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inAllElements)
{
modelica_metatype _outDependencies = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_metatype _bind_exp = NULL;
modelica_metatype _deps = NULL;
modelica_metatype _dims = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,0,13) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 8));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 9));
_bind_exp = tmpMeta8;
_dims = tmpMeta9;
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta13 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta14 = mmc_mk_box3(0, _inAllElements, tmpMeta12, tmpMeta13);
omc_Expression_traverseExpBidir(threadData, _bind_exp, boxvar_CevalFunction_getElementDependenciesTraverserEnter, boxvar_CevalFunction_getElementDependenciesTraverserExit, tmpMeta14, &tmpMeta10);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_arg = tmpMeta10;
_deps = tmpMeta11;
omc_List_mapFold(threadData, _dims, boxvar_CevalFunction_getElementDependenciesFromDims, _arg, &tmpMeta15);
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
_deps = tmpMeta16;
tmpMeta1 = _deps;
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
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,0,13) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 9));
_dims = tmpMeta18;
tmpMeta21 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta22 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta23 = mmc_mk_box3(0, _inAllElements, tmpMeta21, tmpMeta22);
omc_List_mapFold(threadData, _dims, boxvar_CevalFunction_getElementDependenciesFromDims, tmpMeta23, &tmpMeta19);
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
_deps = tmpMeta20;
tmpMeta1 = _deps;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta24;
tmpMeta24 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta24;
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
_outDependencies = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDependencies;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_sortFunctionVarsByDependency(threadData_t *threadData, modelica_metatype _inFuncVars, modelica_metatype _inSource)
{
modelica_metatype _outFuncVars = NULL;
modelica_metatype _cycles = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outFuncVars = omc_Graph_topologicalSort(threadData, omc_Graph_buildGraph(threadData, _inFuncVars, boxvar_CevalFunction_getElementDependencies, _inFuncVars), boxvar_CevalFunction_isElementEqual ,&_cycles);
omc_CevalFunction_checkCyclicalComponents(threadData, _cycles, _inSource);
_return: OMC_LABEL_UNUSED
return _outFuncVars;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_boxReturnValue(threadData_t *threadData, modelica_metatype _inReturnValues)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inReturnValues;
{
modelica_metatype _val = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _OMC_LIT15;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (!listEmpty(tmpMeta7)) goto tmp3_end;
_val = tmpMeta6;
tmpMeta1 = _val;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_1);
tmpMeta9 = MMC_CDR(tmp4_1);
tmpMeta10 = mmc_mk_box2(11, &Values_Value_TUPLE__desc, _inReturnValues);
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
_outValue = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getRecordComponentValue(threadData_t *threadData, modelica_metatype _inVars, modelica_metatype _inEnv)
{
modelica_metatype _outValues = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVars;
{
modelica_metatype _val = NULL;
modelica_metatype _oval = NULL;
modelica_string _id = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _tvbinding = NULL;
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
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,9,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,1) == 0) goto tmp3_end;
_id = tmpMeta6;
_ty = tmpMeta7;
tmpMeta9 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _id);
tmpMeta1 = omc_CevalFunction_getRecordValue(threadData, tmpMeta9, _ty, _inEnv);
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
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta10;
_ty = tmpMeta11;
_tvbinding = tmpMeta12;
omc_Lookup_lookupIdentLocal(threadData, omc_FCore_emptyCache(threadData), _inEnv, _id, &tmpMeta13, NULL, NULL, NULL, NULL);
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 5));
_binding = tmpMeta14;
_oval = omc_CevalFunction_getBindingValueOpt(threadData, _binding);
if(isNone(_oval))
{
_oval = omc_CevalFunction_getBindingValueOpt(threadData, _tvbinding);
}
if(isSome(_oval))
{
tmpMeta15 = _oval;
if (optionNone(tmpMeta15)) goto goto_2;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 1));
_val = tmpMeta16;
}
else
{
_val = omc_CevalFunction_generateDefaultBinding(threadData, _ty);
}
tmpMeta1 = _val;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outValues = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValues;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getRecordValue(threadData_t *threadData, modelica_metatype _inRecordName, modelica_metatype _inType, modelica_metatype _inEnv)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inRecordName;
tmp4_2 = _inType;
{
modelica_metatype _vars = NULL;
modelica_metatype _vals = NULL;
modelica_metatype _var_names = NULL;
modelica_string _id = NULL;
modelica_metatype _p = NULL;
modelica_metatype _env = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_id = tmpMeta6;
_p = tmpMeta8;
_vars = tmpMeta9;
omc_Lookup_lookupIdentLocal(threadData, omc_FCore_emptyCache(threadData), _inEnv, _id ,NULL ,NULL ,NULL ,NULL ,&_env);
_vals = omc_List_map1(threadData, _vars, boxvar_CevalFunction_getRecordComponentValue, _env);
_var_names = omc_List_map(threadData, _vars, boxvar_Types_getVarName);
tmpMeta10 = mmc_mk_box5(13, &Values_Value_RECORD__desc, _p, _vals, _var_names, mmc_mk_integer(((modelica_integer) -1)));
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
_outValue = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getVariableValue(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inType, modelica_metatype _inEnv)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inType;
{
modelica_metatype _val = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,1) == 0) goto tmp3_end;
_p = omc_ComponentReference_crefToPath(threadData, _inCref);
tmpMeta1 = omc_CevalFunction_getRecordValue(threadData, _p, _inType, _inEnv);
goto tmp3_done;
}
case 1: {
omc_CevalFunction_getVariableTypeAndValue(threadData, _inCref, _inEnv ,&_val);
tmpMeta1 = _val;
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
_outValue = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getFunctionReturnValue(threadData_t *threadData, modelica_metatype _inOutputVar, modelica_metatype _inEnv)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inOutputVar;
{
modelica_metatype _cr = NULL;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_cr = tmpMeta6;
_ty = tmpMeta7;
tmpMeta1 = omc_CevalFunction_getVariableValue(threadData, _cr, _ty, _inEnv);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outValue = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getRecordVarBindingAndName(threadData_t *threadData, modelica_metatype _inVar, modelica_string *out_outName)
{
modelica_metatype _outBinding = NULL;
modelica_string _outName = NULL;
modelica_string tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inVar;
{
modelica_string _name = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _val = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_name = tmpMeta6;
_ty = tmpMeta7;
_binding = tmpMeta8;
_val = omc_CevalFunction_getBindingOrDefault(threadData, _binding, _ty);
tmpMeta[0+0] = _val;
tmp1_c1 = _name;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta9;
tmp10 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (1 != tmp10) goto goto_2;
tmpMeta11 = stringAppend(_OMC_LIT20,_name);
tmpMeta12 = stringAppend(tmpMeta11,_OMC_LIT21);
omc_Debug_traceln(threadData, tmpMeta12);
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
_outBinding = tmpMeta[0+0];
_outName = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outName) { *out_outName = _outName; }
return _outBinding;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_generateDefaultBinding(threadData_t *threadData, modelica_metatype _inType)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inType;
{
modelica_metatype _dim = NULL;
modelica_integer _int_dim;
modelica_metatype _dims = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _values = NULL;
modelica_metatype _value = NULL;
modelica_metatype _path = NULL;
modelica_metatype _vars = NULL;
modelica_metatype _var_names = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 8; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmp4 += 6;
tmpMeta1 = _OMC_LIT22;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmp4 += 5;
tmpMeta1 = _OMC_LIT24;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmp4 += 4;
tmpMeta1 = _OMC_LIT25;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmp4 += 3;
tmpMeta1 = _OMC_LIT26;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,5) == 0) goto tmp3_end;
tmp4 += 2;
tmpMeta1 = _OMC_LIT28;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
if (!listEmpty(tmpMeta9)) goto tmp3_end;
_ty = tmpMeta6;
_dim = tmpMeta8;
tmp4 += 1;
_int_dim = omc_Expression_dimensionSize(threadData, _dim);
_value = omc_CevalFunction_generateDefaultBinding(threadData, _ty);
_values = omc_List_fill(threadData, _value, _int_dim);
_dims = omc_ValuesUtil_valueDimensions(threadData, _value);
tmpMeta10 = mmc_mk_cons(mmc_mk_integer(_int_dim), _dims);
tmpMeta11 = mmc_mk_box3(8, &Values_Value_ARRAY__desc, _values, tmpMeta10);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,3,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_path = tmpMeta13;
_vars = tmpMeta14;
_values = omc_List_map__2(threadData, _vars, boxvar_CevalFunction_getRecordVarBindingAndName ,&_var_names);
tmpMeta15 = mmc_mk_box5(13, &Values_Value_RECORD__desc, _path, _values, _var_names, mmc_mk_integer(((modelica_integer) -1)));
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 7: {
modelica_boolean tmp16;
tmp16 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (1 != tmp16) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT29);
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
if (++tmp4 < 8) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outValue = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getBindingOrDefault(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _inType)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inBinding;
{
modelica_metatype _val = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_val = tmpMeta6;
tmpMeta1 = _val;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_val = tmpMeta8;
tmpMeta1 = _val;
goto tmp3_done;
}
case 2: {
tmpMeta1 = omc_CevalFunction_generateDefaultBinding(threadData, _inType);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outValue = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getBindingValueOpt(threadData_t *threadData, modelica_metatype _inBinding)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inBinding;
{
modelica_metatype _val = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_val = tmpMeta6;
tmpMeta1 = mmc_mk_some(_val);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_val = tmpMeta8;
tmpMeta1 = mmc_mk_some(_val);
goto tmp3_done;
}
case 2: {
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
_outValue = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getVariableTypeAndValue(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inEnv, modelica_metatype *out_outValue)
{
modelica_metatype _outType = NULL;
modelica_metatype _outValue = NULL;
modelica_metatype _binding = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outType = omc_CevalFunction_getVariableTypeAndBinding(threadData, _inCref, _inEnv ,&_binding);
_outValue = omc_CevalFunction_getBindingOrDefault(threadData, _binding, _outType);
_return: OMC_LABEL_UNUSED
if (out_outValue) { *out_outValue = _outValue; }
return _outType;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getVariableTypeAndBinding(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inEnv, modelica_metatype *out_outBinding)
{
modelica_metatype _outType = NULL;
modelica_metatype _outBinding = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_Lookup_lookupVar(threadData, omc_FCore_emptyCache(threadData), _inEnv, _inCref ,NULL ,&_outType ,&_outBinding ,NULL ,NULL ,NULL ,NULL ,NULL);
_return: OMC_LABEL_UNUSED
if (out_outBinding) { *out_outBinding = _outBinding; }
return _outType;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_updateRecordComponentValue(threadData_t *threadData, modelica_string _inComponentId, modelica_metatype _inComponentValue, modelica_metatype _inRecordValue)
{
modelica_metatype _outRecordValue = NULL;
modelica_metatype _name = NULL;
modelica_metatype _vals = NULL;
modelica_metatype _comps = NULL;
modelica_integer _pos;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_integer tmp6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inRecordValue;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,10,4) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 5));
tmp6 = mmc_unbox_integer(tmpMeta5);
if (-1 != tmp6) MMC_THROW_INTERNAL();
_name = tmpMeta2;
_vals = tmpMeta3;
_comps = tmpMeta4;
_pos = omc_List_position(threadData, _inComponentId, _comps);
_vals = omc_List_replaceAt(threadData, _inComponentValue, _pos, _vals);
tmpMeta7 = mmc_mk_box5(13, &Values_Value_RECORD__desc, _name, _vals, _comps, mmc_mk_integer(((modelica_integer) -1)));
_outRecordValue = tmpMeta7;
_return: OMC_LABEL_UNUSED
return _outRecordValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_updateRecordComponentBinding(threadData_t *threadData, modelica_metatype _inVar, modelica_string _inComponentId, modelica_metatype _inValue)
{
modelica_metatype _outVar = NULL;
modelica_metatype _val = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outVar = _inVar;
_val = omc_CevalFunction_getBindingOrDefault(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outVar), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_outVar), 4))));
_val = omc_CevalFunction_updateRecordComponentValue(threadData, _inComponentId, _inValue, _val);
tmpMeta2 = mmc_mk_box3(5, &DAE_Binding_VALBOUND__desc, _val, _OMC_LIT30);
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_outVar), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[5] = tmpMeta2;
_outVar = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outVar;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_updateRecordBinding(threadData_t *threadData, modelica_metatype _inVar, modelica_metatype _inValue)
{
modelica_metatype _outVar = NULL;
modelica_string _name = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _c = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outVar = _inVar;
tmpMeta2 = mmc_mk_box3(5, &DAE_Binding_VALBOUND__desc, _inValue, _OMC_LIT30);
tmpMeta1 = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta1), MMC_UNTAGPTR(_outVar), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta1))[5] = tmpMeta2;
_outVar = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outVar;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_updateVariableBinding(threadData_t *threadData, modelica_metatype _inVariableCref, modelica_metatype _inEnv, modelica_metatype _inType, modelica_metatype _inNewValue)
{
modelica_metatype _outEnv = NULL;
modelica_string _var_name = NULL;
modelica_metatype _var = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_var_name = omc_ComponentReference_crefStr(threadData, _inVariableCref);
tmpMeta1 = mmc_mk_box3(5, &DAE_Binding_VALBOUND__desc, _inNewValue, _OMC_LIT30);
_var = omc_CevalFunction_makeFunctionVariable(threadData, _var_name, _inType, tmpMeta1);
_outEnv = omc_FGraph_updateComp(threadData, _inEnv, _var, _OMC_LIT31, omc_FGraph_empty(threadData));
_return: OMC_LABEL_UNUSED
return _outEnv;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignWholeDim(threadData_t *threadData, modelica_metatype _inNewValues, modelica_metatype _inOldValues, modelica_metatype _inSubscripts, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outResult)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outResult = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inNewValues;
tmp4_2 = _inOldValues;
{
modelica_metatype _v1 = NULL;
modelica_metatype _v2 = NULL;
modelica_metatype _vl1 = NULL;
modelica_metatype _vl2 = NULL;
modelica_metatype _cache = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = tmpMeta6;
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
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_2);
tmpMeta10 = MMC_CDR(tmp4_2);
_v1 = tmpMeta7;
_vl1 = tmpMeta8;
_v2 = tmpMeta9;
_vl2 = tmpMeta10;
_cache = omc_CevalFunction_assignVector(threadData, _v1, _v2, _inSubscripts, _inCache, _inEnv ,&_v1);
_cache = omc_CevalFunction_assignWholeDim(threadData, _vl1, _vl2, _inSubscripts, _inCache, _inEnv ,&_vl1);
tmpMeta11 = mmc_mk_cons(_v1, _vl1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta11;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outResult = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outResult) { *out_outResult = _outResult; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignSlice(threadData_t *threadData, modelica_metatype _inNewValues, modelica_metatype _inOldValues, modelica_metatype _inIndices, modelica_metatype _inSubscripts, modelica_integer _inIndex, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outResult)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outResult = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inNewValues;
tmp4_2 = _inOldValues;
tmp4_3 = _inIndices;
{
modelica_metatype _v1 = NULL;
modelica_metatype _v2 = NULL;
modelica_metatype _index = NULL;
modelica_metatype _vl1 = NULL;
modelica_metatype _vl2 = NULL;
modelica_metatype _rest_indices = NULL;
modelica_metatype _cache = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_3)) goto tmp3_end;
tmp4 += 2;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inOldValues;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
modelica_metatype tmpMeta11;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_3);
tmpMeta9 = MMC_CDR(tmp4_3);
_v2 = tmpMeta6;
_vl2 = tmpMeta7;
_index = tmpMeta8;
_vl1 = tmp4_1;
tmp10 = (_inIndex < omc_ValuesUtil_valueInteger(threadData, _index));
if (1 != tmp10) goto goto_2;
_cache = omc_CevalFunction_assignSlice(threadData, _vl1, _vl2, _inIndices, _inSubscripts, ((modelica_integer) 1) + _inIndex, _inCache, _inEnv ,&_vl1);
tmpMeta11 = mmc_mk_cons(_v2, _vl1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta11;
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
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_1);
tmpMeta13 = MMC_CDR(tmp4_1);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmp4_2);
tmpMeta15 = MMC_CDR(tmp4_2);
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_3);
tmpMeta17 = MMC_CDR(tmp4_3);
_v1 = tmpMeta12;
_vl1 = tmpMeta13;
_v2 = tmpMeta14;
_vl2 = tmpMeta15;
_rest_indices = tmpMeta17;
_cache = omc_CevalFunction_assignVector(threadData, _v1, _v2, _inSubscripts, _inCache, _inEnv ,&_v1);
_cache = omc_CevalFunction_assignSlice(threadData, _vl1, _vl2, _rest_indices, _inSubscripts, ((modelica_integer) 1) + _inIndex, _inCache, _inEnv ,&_vl1);
tmpMeta18 = mmc_mk_cons(_v1, _vl1);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta18;
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
_outCache = tmpMeta[0+0];
_outResult = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outResult) { *out_outResult = _outResult; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_assignSlice(threadData_t *threadData, modelica_metatype _inNewValues, modelica_metatype _inOldValues, modelica_metatype _inIndices, modelica_metatype _inSubscripts, modelica_metatype _inIndex, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outResult)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inIndex);
_outCache = omc_CevalFunction_assignSlice(threadData, _inNewValues, _inOldValues, _inIndices, _inSubscripts, tmp1, _inCache, _inEnv, out_outResult);
return _outCache;
}
DLLExport
modelica_metatype omc_CevalFunction_assignVector(threadData_t *threadData, modelica_metatype _inNewValue, modelica_metatype _inOldValue, modelica_metatype _inSubscripts, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outResult)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outResult = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inNewValue;
tmp4_2 = _inOldValue;
tmp4_3 = _inSubscripts;
{
modelica_metatype _e = NULL;
modelica_metatype _index = NULL;
modelica_metatype _val = NULL;
modelica_metatype _values = NULL;
modelica_metatype _values2 = NULL;
modelica_metatype _old_values = NULL;
modelica_metatype _old_values2 = NULL;
modelica_metatype _indices = NULL;
modelica_metatype _dims = NULL;
modelica_integer _i;
modelica_metatype _sub = NULL;
modelica_metatype _rest_subs = NULL;
modelica_metatype _cache = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_3)) goto tmp3_end;
tmp4 += 4;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inNewValue;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_3);
tmpMeta9 = MMC_CDR(tmp4_3);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,2,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_values = tmpMeta6;
_dims = tmpMeta7;
_e = tmpMeta10;
_rest_subs = tmpMeta9;
tmp4 += 2;
_cache = omc_CevalFunction_cevalExp(threadData, _e, _inCache, _inEnv ,&_index);
_i = omc_ValuesUtil_valueInteger(threadData, _index);
_val = listGet(_values, _i);
_cache = omc_CevalFunction_assignVector(threadData, _inNewValue, _val, _rest_subs, _cache, _inEnv ,&_val);
_values = omc_List_replaceAt(threadData, _val, _i, _values);
tmpMeta11 = mmc_mk_box3(8, &Values_Value_ARRAY__desc, _values, _dims);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta11;
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
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_integer tmp23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_3);
tmpMeta16 = MMC_CDR(tmp4_3);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,1,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
_values = tmpMeta12;
_old_values = tmpMeta13;
_dims = tmpMeta14;
_e = tmpMeta17;
_rest_subs = tmpMeta16;
tmp4 += 1;
tmpMeta24 = omc_CevalFunction_cevalExp(threadData, _e, _inCache, _inEnv, &tmpMeta18);
_cache = tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,5,2) == 0) goto goto_2;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
if (listEmpty(tmpMeta19)) goto goto_2;
tmpMeta20 = MMC_CAR(tmpMeta19);
tmpMeta21 = MMC_CDR(tmpMeta19);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,0,1) == 0) goto goto_2;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
tmp23 = mmc_unbox_integer(tmpMeta22);
_indices = tmpMeta19;
_i = tmp23;
_old_values = omc_List_splitr(threadData, _old_values, ((modelica_integer) -1) + _i ,&_old_values2);
_cache = omc_CevalFunction_assignSlice(threadData, _values, _old_values2, _indices, _rest_subs, _i, _cache, _inEnv ,&_values2);
_values = omc_List_append__reverse(threadData, _old_values, _values2);
tmpMeta25 = mmc_mk_box3(8, &Values_Value_ARRAY__desc, _values, _dims);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta25;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,2) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta29 = MMC_CAR(tmp4_3);
tmpMeta30 = MMC_CDR(tmp4_3);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,0,0) == 0) goto tmp3_end;
_values = tmpMeta26;
_values2 = tmpMeta27;
_dims = tmpMeta28;
_rest_subs = tmpMeta30;
_cache = omc_CevalFunction_assignWholeDim(threadData, _values, _values2, _rest_subs, _inCache, _inEnv ,&_values);
tmpMeta31 = mmc_mk_box3(8, &Values_Value_ARRAY__desc, _values, _dims);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta31;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_boolean tmp34;
modelica_metatype tmpMeta35;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta32 = MMC_CAR(tmp4_3);
tmpMeta33 = MMC_CDR(tmp4_3);
_sub = tmpMeta32;
tmp34 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (1 != tmp34) goto goto_2;
fputs(MMC_STRINGDATA(_OMC_LIT32),stdout);
tmpMeta35 = stringAppend(omc_ExpressionDump_printSubscriptStr(threadData, _sub),_OMC_LIT21);
fputs(MMC_STRINGDATA(tmpMeta35),stdout);
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
_outCache = tmpMeta[0+0];
_outResult = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outResult) { *out_outResult = _outResult; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignRecordComponents(threadData_t *threadData, modelica_metatype _inVars, modelica_metatype _inValues, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inVars;
tmp4_2 = _inValues;
{
modelica_metatype _rest_vars = NULL;
modelica_metatype _val = NULL;
modelica_metatype _rest_vals = NULL;
modelica_string _name = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
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
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_2);
tmpMeta11 = MMC_CDR(tmp4_2);
_name = tmpMeta8;
_ty = tmpMeta9;
_rest_vars = tmpMeta7;
_val = tmpMeta10;
_rest_vals = tmpMeta11;
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
_cr = omc_ComponentReference_makeCrefIdent(threadData, _name, _ty, tmpMeta12);
_cache = omc_CevalFunction_assignVariable(threadData, _cr, _val, _inCache, _inEnv ,&_env);
_inVars = _rest_vars;
_inValues = _rest_vals;
_inCache = _cache;
_inEnv = _env;
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignRecord(threadData_t *threadData, modelica_metatype _inType, modelica_metatype _inValue, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inType;
tmp4_2 = _inValue;
{
modelica_metatype _values = NULL;
modelica_metatype _vars = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,10,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_vars = tmpMeta6;
_values = tmpMeta7;
tmpMeta[0+0] = omc_CevalFunction_assignRecordComponents(threadData, _vars, _values, _inCache, _inEnv, &tmpMeta[0+1]);
goto tmp3_done;
}
}
goto tmp3_end;
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
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignTuple(threadData_t *threadData, modelica_metatype _inLhsCrefs, modelica_metatype _inRhsValues, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _inLhsCrefs;
tmp4_2 = _inRhsValues;
tmp4_3 = _inCache;
tmp4_4 = _inEnv;
{
modelica_metatype _cr = NULL;
modelica_metatype _rest_crefs = NULL;
modelica_metatype _value = NULL;
modelica_metatype _rest_vals = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_cache = tmp4_3;
_env = tmp4_4;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
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
_cr = tmpMeta6;
_rest_crefs = tmpMeta7;
_value = tmpMeta8;
_rest_vals = tmpMeta9;
_cache = tmp4_3;
_env = tmp4_4;
_cache = omc_CevalFunction_assignVariable(threadData, _cr, _value, _cache, _env ,&_env);
_inLhsCrefs = _rest_crefs;
_inRhsValues = _rest_vals;
_inCache = _cache;
_inEnv = _env;
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignVariable(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inNewValue, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_metatype _cr = NULL;
modelica_metatype _cr_rest = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _ety = NULL;
modelica_metatype _val = NULL;
modelica_metatype _var = NULL;
modelica_metatype _inst_status = NULL;
modelica_string _id = NULL;
modelica_string _comp_id = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,0) == 0) goto tmp3_end;
tmp4 += 4;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,9,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta9)) goto tmp3_end;
_id = tmpMeta6;
_ety = tmpMeta7;
omc_Lookup_lookupIdentLocal(threadData, _inCache, _inEnv, _id ,&_var ,NULL ,NULL ,&_inst_status ,&_env);
_cache = omc_CevalFunction_assignRecord(threadData, _ety, _inNewValue, _inCache, _env ,&_env);
_var = omc_CevalFunction_updateRecordBinding(threadData, _var, _inNewValue);
_env = omc_FGraph_updateComp(threadData, _inEnv, _var, _inst_status, _env);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
_cr = tmp4_1;
_ty = omc_Types_unflattenArrayType(threadData, omc_Expression_typeof(threadData, omc_ValuesUtil_valueExp(threadData, _inNewValue, mmc_mk_none())));
_env = omc_CevalFunction_updateVariableBinding(threadData, _cr, _inEnv, _ty, _inNewValue);
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _env;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_subs = tmpMeta11;
tmp4 += 1;
_cr = omc_ComponentReference_crefStripSubs(threadData, _inCref);
_ty = omc_CevalFunction_getVariableTypeAndValue(threadData, _cr, _inEnv ,&_val);
_cache = omc_CevalFunction_assignVector(threadData, _inNewValue, _val, _subs, _inCache, _inEnv ,&_val);
_env = omc_CevalFunction_updateVariableBinding(threadData, _cr, _inEnv, _ty, _val);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_id = tmpMeta12;
_cr_rest = tmpMeta14;
omc_Lookup_lookupIdentLocal(threadData, _inCache, _inEnv, _id ,&_var ,NULL ,NULL ,&_inst_status ,&_env);
_cache = omc_CevalFunction_assignVariable(threadData, _cr_rest, _inNewValue, _inCache, _env ,&_env);
_comp_id = omc_ComponentReference_crefFirstIdent(threadData, _cr_rest);
_var = omc_CevalFunction_updateRecordComponentBinding(threadData, _var, _comp_id, _inNewValue);
_env = omc_FGraph_updateComp(threadData, _inEnv, _var, _inst_status, _env);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_appendDimensions2(threadData_t *threadData, modelica_metatype _inType, modelica_metatype _inDims, modelica_metatype _inBindingDims, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outType)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outType = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inType;
tmp4_2 = _inDims;
tmp4_3 = _inBindingDims;
{
modelica_metatype _rest_dims = NULL;
modelica_metatype _dim_exp = NULL;
modelica_metatype _dim_val = NULL;
modelica_integer _dim_int;
modelica_metatype _dim = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _bind_dims = NULL;
modelica_metatype _cache = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 8; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_ty = tmp4_1;
tmp4 += 7;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _ty;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_3);
tmpMeta7 = MMC_CDR(tmp4_3);
tmp8 = mmc_unbox_integer(tmpMeta6);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmp4_2);
tmpMeta10 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,4,0) == 0) goto tmp3_end;
_dim_int = tmp8;
_bind_dims = tmpMeta7;
_rest_dims = tmpMeta10;
_ty = tmp4_1;
_dim = omc_Expression_intDimension(threadData, _dim_int);
_cache = omc_CevalFunction_appendDimensions2(threadData, _ty, _rest_dims, _bind_dims, _inCache, _inEnv ,&_ty);
tmpMeta11 = mmc_mk_cons(_dim, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta12 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta11);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_2);
tmpMeta14 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,4,0) == 0) goto tmp3_end;
_rest_dims = tmpMeta14;
_ty = tmp4_1;
_bind_dims = tmp4_3;
tmp4 += 4;
_cache = omc_CevalFunction_appendDimensions2(threadData, _ty, _rest_dims, _bind_dims, _inCache, _inEnv ,&_ty);
tmpMeta15 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, _OMC_LIT34);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta15;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_integer tmp19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_2);
tmpMeta17 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,0,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
tmp19 = mmc_unbox_integer(tmpMeta18);
_dim_int = tmp19;
_rest_dims = tmpMeta17;
_ty = tmp4_1;
_bind_dims = tmp4_3;
tmp4 += 3;
tmpMeta20 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim_int));
_dim = tmpMeta20;
_bind_dims = omc_List_stripFirst(threadData, _bind_dims);
_cache = omc_CevalFunction_appendDimensions2(threadData, _ty, _rest_dims, _bind_dims, _inCache, _inEnv ,&_ty);
tmpMeta21 = mmc_mk_cons(_dim, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta22 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta21);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta22;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta23 = MMC_CAR(tmp4_2);
tmpMeta24 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,1,0) == 0) goto tmp3_end;
_rest_dims = tmpMeta24;
_ty = tmp4_1;
_bind_dims = tmp4_3;
tmp4 += 2;
_dim = _OMC_LIT35;
_bind_dims = omc_List_stripFirst(threadData, _bind_dims);
_cache = omc_CevalFunction_appendDimensions2(threadData, _ty, _rest_dims, _bind_dims, _inCache, _inEnv ,&_ty);
tmpMeta25 = mmc_mk_cons(_dim, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta26 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta25);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta26;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_integer tmp30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta27 = MMC_CAR(tmp4_2);
tmpMeta28 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,2,3) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 4));
tmp30 = mmc_unbox_integer(tmpMeta29);
_dim_int = tmp30;
_rest_dims = tmpMeta28;
_ty = tmp4_1;
_bind_dims = tmp4_3;
tmp4 += 1;
tmpMeta31 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim_int));
_dim = tmpMeta31;
_bind_dims = omc_List_stripFirst(threadData, _bind_dims);
_cache = omc_CevalFunction_appendDimensions2(threadData, _ty, _rest_dims, _bind_dims, _inCache, _inEnv ,&_ty);
tmpMeta32 = mmc_mk_cons(_dim, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta33 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta32);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta33;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta34 = MMC_CAR(tmp4_2);
tmpMeta35 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,3,1) == 0) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 2));
_dim_exp = tmpMeta36;
_rest_dims = tmpMeta35;
_ty = tmp4_1;
_bind_dims = tmp4_3;
_cache = omc_CevalFunction_cevalExp(threadData, _dim_exp, _inCache, _inEnv ,&_dim_val);
_dim_int = omc_ValuesUtil_valueInteger(threadData, _dim_val);
tmpMeta37 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim_int));
_dim = tmpMeta37;
_bind_dims = omc_List_stripFirst(threadData, _bind_dims);
_cache = omc_CevalFunction_appendDimensions2(threadData, _ty, _rest_dims, _bind_dims, _inCache, _inEnv ,&_ty);
tmpMeta38 = mmc_mk_cons(_dim, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta39 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta38);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta39;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_boolean tmp42;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta40 = MMC_CAR(tmp4_2);
tmpMeta41 = MMC_CDR(tmp4_2);
tmp42 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (1 != tmp42) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT36);
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
if (++tmp4 < 8) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outCache = tmpMeta[0+0];
_outType = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outType) { *out_outType = _outType; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_appendDimensions(threadData_t *threadData, modelica_metatype _inType, modelica_metatype _inOptBinding, modelica_metatype _inDims, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outType)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outType = NULL;
modelica_metatype _binding_dims = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_binding_dims = omc_ValuesUtil_valueDimensions(threadData, omc_Util_getOptionOrDefault(threadData, _inOptBinding, _OMC_LIT22));
_outCache = omc_CevalFunction_appendDimensions2(threadData, _inType, _inDims, _binding_dims, _inCache, _inEnv ,&_outType);
_return: OMC_LABEL_UNUSED
if (out_outType) { *out_outType = _outType; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extendEnvWithForScope(threadData_t *threadData, modelica_string _inIterName, modelica_metatype _inIterType, modelica_metatype _inEnv, modelica_metatype *out_outIterType, modelica_metatype *out_outIterCref)
{
modelica_metatype _outEnv = NULL;
modelica_metatype _outIterType = NULL;
modelica_metatype _outIterCref = NULL;
modelica_metatype _iter_cr = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIterType = omc_Types_expTypetoTypesType(threadData, _inIterType);
_outEnv = omc_FGraph_addForIterator(threadData, _inEnv, _inIterName, _outIterType, _OMC_LIT37, _OMC_LIT38, _OMC_LIT40);
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outIterCref = omc_ComponentReference_makeCrefIdent(threadData, _inIterName, _inIterType, tmpMeta1);
_return: OMC_LABEL_UNUSED
if (out_outIterType) { *out_outIterType = _outIterType; }
if (out_outIterCref) { *out_outIterCref = _outIterCref; }
return _outEnv;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extendEnvWithRecordVar(threadData_t *threadData, modelica_metatype _inVar, modelica_metatype _inOptValue, modelica_metatype _inEnv)
{
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inVar;
tmp4_2 = _inEnv;
{
modelica_string _name = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
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
modelica_metatype tmpMeta11;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_name = tmpMeta6;
_ty = tmpMeta7;
_cache = tmpMeta8;
_env = tmpMeta9;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
_cache = omc_CevalFunction_extendEnvWithVar(threadData, _name, _ty, _inOptValue, tmpMeta10, _cache, _env ,&_env);
tmpMeta11 = mmc_mk_box2(0, _cache, _env);
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
_outEnv = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outEnv;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_getRecordValues(threadData_t *threadData, modelica_metatype _inOptValue, modelica_metatype _inRecordType)
{
modelica_metatype _outValues = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inOptValue;
tmp4_2 = _inRecordType;
{
modelica_metatype _vals = NULL;
modelica_metatype _vars = NULL;
modelica_integer _n;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,10,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_vals = tmpMeta7;
tmpMeta1 = omc_List_map(threadData, _vals, boxvar_Util_makeOption);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
if (!optionNone(tmp4_1)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_vars = tmpMeta8;
_n = listLength(_vars);
tmpMeta1 = omc_List_fill(threadData, mmc_mk_none(), _n);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outValues = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValues;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_makeRecordEnvironment(threadData_t *threadData, modelica_metatype _inRecordType, modelica_metatype _inOptValue, modelica_metatype _inCache, modelica_metatype _inGraph, modelica_metatype *out_outRecordEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outRecordEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inRecordType;
{
modelica_metatype _var_lst = NULL;
modelica_metatype _vals = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _graph = NULL;
modelica_metatype _parent = NULL;
modelica_metatype _child = NULL;
modelica_metatype _node = NULL;
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
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,3,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_var_lst = tmpMeta7;
_parent = omc_FGraph_lastScopeRef(threadData, _inGraph);
tmpMeta8 = mmc_mk_cons(_parent, MMC_REFSTRUCTLIT(mmc_nil));
_graph = omc_FGraph_node(threadData, _inGraph, _OMC_LIT41, tmpMeta8, _OMC_LIT42 ,&_node);
_child = omc_FNode_toRef(threadData, _node);
omc_FNode_addChildRef(threadData, _parent, _OMC_LIT41, _child, 0);
_graph = omc_FGraph_pushScopeRef(threadData, _graph, _child);
_vals = omc_CevalFunction_getRecordValues(threadData, _inOptValue, _inRecordType);
tmpMeta9 = mmc_mk_box2(0, _inCache, _graph);
tmpMeta10 = omc_List_threadFold(threadData, _var_lst, _vals, boxvar_CevalFunction_extendEnvWithRecordVar, tmpMeta9);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_cache = tmpMeta11;
_graph = tmpMeta12;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _graph;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outRecordEnv = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRecordEnv) { *out_outRecordEnv = _outRecordEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_makeBinding(threadData_t *threadData, modelica_metatype _inBindingValue)
{
modelica_metatype _outBinding = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inBindingValue;
{
modelica_metatype _val = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_val = tmpMeta6;
tmpMeta7 = mmc_mk_box3(5, &DAE_Binding_VALBOUND__desc, _val, _OMC_LIT30);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta1 = _OMC_LIT37;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outBinding = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outBinding;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_makeFunctionVariable(threadData_t *threadData, modelica_string _inName, modelica_metatype _inType, modelica_metatype _inBinding)
{
modelica_metatype _outVar = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box7(3, &DAE_Var_TYPES__VAR__desc, _inName, _OMC_LIT49, _inType, _inBinding, mmc_mk_boolean(0), mmc_mk_none());
_outVar = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outVar;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extendEnvWithVar(threadData_t *threadData, modelica_string _inName, modelica_metatype _inType, modelica_metatype _inOptValue, modelica_metatype _inDims, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _ty = NULL;
modelica_metatype _var = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _record_env = NULL;
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
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmp6 = omc_Types_isRecord(threadData, _inType);
if (1 != tmp6) goto goto_2;
_binding = omc_CevalFunction_makeBinding(threadData, _inOptValue);
_cache = omc_CevalFunction_appendDimensions(threadData, _inType, _inOptValue, _inDims, _inCache, _inEnv ,&_ty);
tmpMeta7 = mmc_mk_box7(3, &DAE_Var_TYPES__VAR__desc, _inName, _OMC_LIT49, _ty, _binding, mmc_mk_boolean(0), mmc_mk_none());
_var = tmpMeta7;
_cache = omc_CevalFunction_makeRecordEnvironment(threadData, _inType, _inOptValue, _cache, _inEnv ,&_record_env);
tmpMeta8 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _inName, _OMC_LIT53, _OMC_LIT56, _OMC_LIT57, _OMC_LIT58, _OMC_LIT59, mmc_mk_none(), _OMC_LIT60);
_env = omc_FGraph_mkComponentNode(threadData, _inEnv, _var, tmpMeta8, _OMC_LIT61, _OMC_LIT31, _record_env);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
_binding = omc_CevalFunction_makeBinding(threadData, _inOptValue);
_cache = omc_CevalFunction_appendDimensions(threadData, _inType, _inOptValue, _inDims, _inCache, _inEnv ,&_ty);
tmpMeta9 = mmc_mk_box7(3, &DAE_Var_TYPES__VAR__desc, _inName, _OMC_LIT49, _ty, _binding, mmc_mk_boolean(0), mmc_mk_none());
_var = tmpMeta9;
tmpMeta10 = mmc_mk_box9(6, &SCode_Element_COMPONENT__desc, _inName, _OMC_LIT53, _OMC_LIT56, _OMC_LIT57, _OMC_LIT58, _OMC_LIT59, mmc_mk_none(), _OMC_LIT60);
_env = omc_FGraph_mkComponentNode(threadData, _inEnv, _var, tmpMeta10, _OMC_LIT61, _OMC_LIT31, omc_FGraph_empty(threadData));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extendEnvWithElement(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inBindingValue, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_metatype _cr = NULL;
modelica_string _name = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _dims = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
_cr = tmpMeta6;
_ty = tmpMeta7;
_dims = tmpMeta8;
_name = omc_ComponentReference_crefStr(threadData, _cr);
tmpMeta[0+0] = omc_CevalFunction_extendEnvWithVar(threadData, _name, _ty, _inBindingValue, _dims, _inCache, _inEnv, &tmpMeta[0+1]);
goto tmp3_done;
}
}
goto tmp3_end;
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
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateBinding(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache)
{
modelica_metatype _outValue = NULL;
modelica_metatype _outCache = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inBinding;
{
modelica_metatype _binding_exp = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _val = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_binding_exp = tmpMeta6;
_cache = omc_CevalFunction_cevalExp(threadData, _binding_exp, _inCache, _inEnv ,&_val);
tmpMeta[0+0] = mmc_mk_some(_val);
tmpMeta[0+1] = _cache;
goto tmp3_done;
}
case 1: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = _inCache;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outValue = tmpMeta[0+0];
_outCache = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extendEnvWithFunctionVar(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inFuncParam, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inEnv;
tmp4_2 = _inFuncParam;
{
modelica_metatype _e = NULL;
modelica_metatype _val = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _binding_exp = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
_e = tmpMeta6;
_val = tmpMeta7;
_env = tmp4_1;
tmp4 += 1;
tmpMeta[0+0] = omc_CevalFunction_extendEnvWithElement(threadData, _e, _val, _inCache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,13) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 8));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (!optionNone(tmpMeta11)) goto tmp3_end;
_e = tmpMeta9;
_binding_exp = tmpMeta10;
_env = tmp4_1;
_val = omc_CevalFunction_evaluateBinding(threadData, _binding_exp, _inCache, _inEnv ,&_cache);
tmpMeta[0+0] = omc_CevalFunction_extendEnvWithElement(threadData, _e, _val, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_boolean tmp13;
modelica_metatype tmpMeta14;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
_e = tmpMeta12;
tmp13 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (1 != tmp13) goto goto_2;
omc_Debug_traceln(threadData, _OMC_LIT62);
tmpMeta14 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
omc_Debug_traceln(threadData, omc_DAEDump_dumpElementsStr(threadData, tmpMeta14));
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extendEnvWithFunctionVars(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inFuncParams, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inFuncParams;
{
modelica_metatype _param = NULL;
modelica_metatype _rest_params = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_3);
tmpMeta7 = MMC_CDR(tmp4_3);
_param = tmpMeta6;
_rest_params = tmpMeta7;
_cache = tmp4_1;
_env = tmp4_2;
_cache = omc_CevalFunction_extendEnvWithFunctionVar(threadData, _cache, _env, _param ,&_env);
_inCache = _cache;
_inEnv = _env;
_inFuncParams = _rest_params;
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_setupFunctionEnvironment(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _inFuncName, modelica_metatype _inFuncParams, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outEnv = omc_FGraph_openScope(threadData, _inEnv, _OMC_LIT63, _inFuncName, _OMC_LIT65);
_outCache = omc_CevalFunction_extendEnvWithFunctionVars(threadData, _inCache, _outEnv, _inFuncParams ,&_outEnv);
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_cevalExpList(threadData_t *threadData, modelica_metatype _inExpLst, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outValue)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outValue = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = omc_Ceval_cevalList(threadData, _inCache, _inEnv, _inExpLst, 1, _OMC_LIT66, ((modelica_integer) 0) ,&_outValue);
_return: OMC_LABEL_UNUSED
if (out_outValue) { *out_outValue = _outValue; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_cevalExp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outValue)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outValue = NULL;
modelica_boolean tmp1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = omc_Ceval_ceval(threadData, _inCache, _inEnv, _inExp, 1, _OMC_LIT66, ((modelica_integer) 0) ,&_outValue);
tmp1 = valueEq(_OMC_LIT67, _outValue);
if (0 != tmp1) MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
if (out_outValue) { *out_outValue = _outValue; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_extractLhsComponentRef(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _cref = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cref = tmpMeta6;
tmpMeta1 = _cref;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
modelica_metatype tmpMeta8;
tmp7 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (1 != tmp7) goto goto_2;
tmpMeta8 = stringAppend(_OMC_LIT68,omc_ExpressionDump_printExpStr(threadData, _inExp));
omc_Debug_traceln(threadData, tmpMeta8);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateWhileStatement(threadData_t *threadData, modelica_metatype _inCondition, modelica_metatype _inStatements, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inLoopControl, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outLoopControl = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inLoopControl;
{
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _loop_ctrl = NULL;
modelica_boolean _b;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _OMC_LIT69;
goto tmp3_done;
}
case 5: {
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _inLoopControl;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
tmpMeta8 = omc_CevalFunction_cevalExp(threadData, _inCondition, _inCache, _inEnv, &tmpMeta5);
_cache = tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta5,3,1) == 0) goto goto_2;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
_b = tmp7;
if(_b)
{
_cache = omc_CevalFunction_evaluateStatements(threadData, _inStatements, _cache, _inEnv ,&_env ,&_loop_ctrl);
_cache = omc_CevalFunction_evaluateWhileStatement(threadData, _inCondition, _inStatements, _cache, _env, _loop_ctrl ,&_env ,&_loop_ctrl);
}
else
{
_loop_ctrl = _OMC_LIT69;
_env = _inEnv;
}
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _loop_ctrl;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outLoopControl = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outLoopControl) { *out_outLoopControl = _outLoopControl; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateForLoopArray(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inIter, modelica_metatype _inIterType, modelica_metatype _inValues, modelica_metatype _inStatements, modelica_metatype _inLoopControl, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outLoopControl = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inEnv;
tmp4_2 = _inValues;
tmp4_3 = _inLoopControl;
{
modelica_metatype _value = NULL;
modelica_metatype _rest_vals = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _loop_ctrl = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,0) == 0) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _OMC_LIT69;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,0) == 0) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _inLoopControl;
goto tmp3_done;
}
case 2: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _inLoopControl;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,0) == 0) goto tmp3_end;
_value = tmpMeta6;
_rest_vals = tmpMeta7;
_env = tmp4_1;
_env = omc_CevalFunction_updateVariableBinding(threadData, _inIter, _env, _inIterType, _value);
_cache = omc_CevalFunction_evaluateStatements(threadData, _inStatements, _inCache, _env ,&_env ,&_loop_ctrl);
_inCache = _cache;
_inEnv = _env;
_inValues = _rest_vals;
_inLoopControl = _loop_ctrl;
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outLoopControl = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outLoopControl) { *out_outLoopControl = _outLoopControl; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateForStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outLoopControl = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inStatement;
tmp4_2 = _inEnv;
{
modelica_metatype _ety = NULL;
modelica_metatype _ty = NULL;
modelica_string _iter_name = NULL;
modelica_metatype _range = NULL;
modelica_metatype _statements = NULL;
modelica_metatype _range_vals = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _iter_cr = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,7) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_ety = tmpMeta6;
_iter_name = tmpMeta7;
_range = tmpMeta8;
_statements = tmpMeta9;
_env = tmp4_2;
tmpMeta12 = omc_CevalFunction_cevalExp(threadData, _range, _inCache, _env, &tmpMeta10);
_cache = tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,5,2) == 0) goto goto_2;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
_range_vals = tmpMeta11;
_env = omc_CevalFunction_extendEnvWithForScope(threadData, _iter_name, _ety, _env ,&_ty ,&_iter_cr);
tmpMeta[0+0] = omc_CevalFunction_evaluateForLoopArray(threadData, _cache, _env, _iter_cr, _ty, _range_vals, _statements, _OMC_LIT69, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_boolean tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,7) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_range = tmpMeta13;
tmp14 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (1 != tmp14) goto goto_2;
omc_Debug_traceln(threadData, _OMC_LIT70);
omc_Debug_traceln(threadData, omc_ExpressionDump_printExpStr(threadData, _range));
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outLoopControl = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outLoopControl) { *out_outLoopControl = _outLoopControl; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateIfStatement2(threadData_t *threadData, modelica_boolean _inCondition, modelica_metatype _inStatements, modelica_metatype _inElse, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outLoopControl = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _inCondition;
tmp4_2 = _inStatements;
tmp4_3 = _inElse;
tmp4_4 = _inEnv;
{
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _statements = NULL;
modelica_metatype _condition = NULL;
modelica_boolean _bool_condition;
modelica_metatype _else_branch = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (1 != tmp4_1) goto tmp3_end;
_statements = tmp4_2;
_env = tmp4_4;
tmpMeta[0+0] = omc_CevalFunction_evaluateStatements(threadData, _statements, _inCache, _env, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (0 != tmp4_1) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_statements = tmpMeta6;
_env = tmp4_4;
tmpMeta[0+0] = omc_CevalFunction_evaluateStatements(threadData, _statements, _inCache, _env, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_integer tmp12;
modelica_metatype tmpMeta13;
if (0 != tmp4_1) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_condition = tmpMeta7;
_statements = tmpMeta8;
_else_branch = tmpMeta9;
_env = tmp4_4;
tmpMeta13 = omc_CevalFunction_cevalExp(threadData, _condition, _inCache, _env, &tmpMeta10);
_cache = tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,3,1) == 0) goto goto_2;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmp12 = mmc_unbox_integer(tmpMeta11);
_bool_condition = tmp12;
_inCondition = _bool_condition;
_inStatements = _statements;
_inElse = _else_branch;
_inCache = _cache;
_inEnv = _env;
goto _tailrecursive;
goto tmp3_done;
}
case 3: {
if (0 != tmp4_1) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,0) == 0) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _OMC_LIT69;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outLoopControl = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outLoopControl) { *out_outLoopControl = _outLoopControl; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_evaluateIfStatement2(threadData_t *threadData, modelica_metatype _inCondition, modelica_metatype _inStatements, modelica_metatype _inElse, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inCondition);
_outCache = omc_CevalFunction_evaluateIfStatement2(threadData, tmp1, _inStatements, _inElse, _inCache, _inEnv, out_outEnv, out_outLoopControl);
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateIfStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outLoopControl = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inStatement;
{
modelica_metatype _cond = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _else_branch = NULL;
modelica_metatype _cache = NULL;
modelica_boolean _bool_cond;
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
modelica_integer tmp11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cond = tmpMeta6;
_stmts = tmpMeta7;
_else_branch = tmpMeta8;
tmpMeta12 = omc_CevalFunction_cevalExp(threadData, _cond, _inCache, _inEnv, &tmpMeta9);
_cache = tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,1) == 0) goto goto_2;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmp11 = mmc_unbox_integer(tmpMeta10);
_bool_cond = tmp11;
tmpMeta[0+0] = omc_CevalFunction_evaluateIfStatement2(threadData, _bool_cond, _stmts, _else_branch, _cache, _inEnv, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
}
goto tmp3_end;
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
_outLoopControl = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outLoopControl) { *out_outLoopControl = _outLoopControl; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateTupleAssignStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inStatement;
tmp4_2 = _inEnv;
{
modelica_metatype _lhs_expl = NULL;
modelica_metatype _rhs = NULL;
modelica_metatype _rhs_vals = NULL;
modelica_metatype _lhs_crefs = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_lhs_expl = tmpMeta6;
_rhs = tmpMeta7;
_env = tmp4_2;
tmpMeta10 = omc_CevalFunction_cevalExp(threadData, _rhs, _inCache, _env, &tmpMeta8);
_cache = tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,8,1) == 0) goto goto_2;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_rhs_vals = tmpMeta9;
_lhs_crefs = omc_List_map(threadData, _lhs_expl, boxvar_CevalFunction_extractLhsComponentRef);
tmpMeta[0+0] = omc_CevalFunction_assignTuple(threadData, _lhs_crefs, _rhs_vals, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
}
goto tmp3_end;
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
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateStatements2(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inLoopControl, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outLoopControl = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inStatement;
tmp4_2 = _inLoopControl;
{
modelica_metatype _stmt = NULL;
modelica_metatype _rest_stmts = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _loop_ctrl = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _inLoopControl;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _inLoopControl;
goto tmp3_done;
}
case 2: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _inLoopControl;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,0) == 0) goto tmp3_end;
_stmt = tmpMeta6;
_rest_stmts = tmpMeta7;
_cache = omc_CevalFunction_evaluateStatement(threadData, _stmt, _inCache, _inEnv ,&_env ,&_loop_ctrl);
_inStatement = _rest_stmts;
_inCache = _cache;
_inEnv = _env;
_inLoopControl = _loop_ctrl;
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outLoopControl = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outLoopControl) { *out_outLoopControl = _outLoopControl; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateStatements(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outLoopControl = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCache = omc_CevalFunction_evaluateStatements2(threadData, _inStatement, _inCache, _inEnv, _OMC_LIT69 ,&_outEnv ,&_outLoopControl);
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outLoopControl) { *out_outLoopControl = _outLoopControl; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateStatement(threadData_t *threadData, modelica_metatype _inStatement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outLoopControl = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inStatement;
tmp4_2 = _inCache;
tmp4_3 = _inEnv;
{
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _lhs = NULL;
modelica_metatype _rhs = NULL;
modelica_metatype _condition = NULL;
modelica_metatype _lhs_cref = NULL;
modelica_metatype _rhs_val = NULL;
modelica_metatype _v = NULL;
modelica_metatype _exps = NULL;
modelica_metatype _vals = NULL;
modelica_metatype _statements = NULL;
modelica_metatype _tailCall = NULL;
modelica_string _var = NULL;
modelica_metatype _vars = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 12; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_lhs = tmpMeta6;
_rhs = tmpMeta7;
_cache = tmp4_2;
_env = tmp4_3;
_cache = omc_CevalFunction_cevalExp(threadData, _rhs, _cache, _env ,&_rhs_val);
_lhs_cref = omc_CevalFunction_extractLhsComponentRef(threadData, _lhs);
_cache = omc_CevalFunction_assignVariable(threadData, _lhs_cref, _rhs_val, _cache, _env ,&_env);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _OMC_LIT69;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
_cache = omc_CevalFunction_evaluateTupleAssignStatement(threadData, _inStatement, _inCache, _inEnv ,&_env);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _OMC_LIT69;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,4) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_lhs = tmpMeta8;
_rhs = tmpMeta9;
_env = tmp4_3;
_cache = omc_CevalFunction_cevalExp(threadData, _rhs, _inCache, _env ,&_rhs_val);
_lhs_cref = omc_CevalFunction_extractLhsComponentRef(threadData, _lhs);
_cache = omc_CevalFunction_assignVariable(threadData, _lhs_cref, _rhs_val, _cache, _env ,&_env);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _OMC_LIT69;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,4) == 0) goto tmp3_end;
tmpMeta[0+0] = omc_CevalFunction_evaluateIfStatement(threadData, _inStatement, _inCache, _inEnv, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,7) == 0) goto tmp3_end;
tmpMeta[0+0] = omc_CevalFunction_evaluateForStatement(threadData, _inStatement, _inCache, _inEnv, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_condition = tmpMeta10;
_statements = tmpMeta11;
tmpMeta[0+0] = omc_CevalFunction_evaluateWhileStatement(threadData, _condition, _statements, _inCache, _inEnv, _OMC_LIT69, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,4) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_condition = tmpMeta12;
tmpMeta16 = omc_CevalFunction_cevalExp(threadData, _condition, _inCache, _inEnv, &tmpMeta13);
_cache = tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,3,1) == 0) goto goto_2;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
if (1 != tmp15) goto goto_2;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _OMC_LIT69;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,4) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_condition = tmpMeta17;
tmpMeta21 = omc_CevalFunction_cevalExp(threadData, _condition, _inCache, _inEnv, &tmpMeta18);
_cache = tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,3,1) == 0) goto goto_2;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmp20 = mmc_unbox_integer(tmpMeta19);
if (1 != tmp20) goto goto_2;
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _OMC_LIT69;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,2) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,13,3) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 3));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 4));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 8));
_rhs = tmpMeta22;
_exps = tmpMeta23;
_tailCall = tmpMeta25;
_cache = omc_CevalFunction_cevalExpList(threadData, _exps, _inCache, _inEnv ,&_vals);
_cache = omc_CevalFunction_cevalExp(threadData, _rhs, _cache, _inEnv ,&_v);
{
modelica_metatype tmp29_1;
tmp29_1 = _tailCall;
{
volatile mmc_switch_type tmp29;
int tmp30;
tmp29 = 0;
for (; tmp29 < 4; tmp29++) {
switch (MMC_SWITCH_CAST(tmp29)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp29_1,0,0) == 0) goto tmp28_end;
tmpMeta[3+0] = _cache;
tmpMeta[3+1] = _inEnv;
tmpMeta[3+2] = _OMC_LIT69;
goto tmp28_done;
}
case 1: {
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp29_1,1,2) == 0) goto tmp28_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp29_1), 3));
if (!listEmpty(tmpMeta31)) goto tmp28_end;
tmpMeta[3+0] = _cache;
tmpMeta[3+1] = _inEnv;
tmpMeta[3+2] = _OMC_LIT71;
goto tmp28_done;
}
case 2: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp29_1,1,2) == 0) goto tmp28_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp29_1), 3));
if (listEmpty(tmpMeta32)) goto tmp28_end;
tmpMeta33 = MMC_CAR(tmpMeta32);
tmpMeta34 = MMC_CDR(tmpMeta32);
if (!listEmpty(tmpMeta34)) goto tmp28_end;
_var = tmpMeta33;
_cache = omc_CevalFunction_assignVariable(threadData, omc_ComponentReference_makeUntypedCrefIdent(threadData, _var), _v, _cache, _inEnv ,&_env);
tmpMeta[3+0] = _cache;
tmpMeta[3+1] = _env;
tmpMeta[3+2] = _OMC_LIT71;
goto tmp28_done;
}
case 3: {
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
if (mmc__uniontype__metarecord__typedef__equal(tmp29_1,1,2) == 0) goto tmp28_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp29_1), 3));
_vars = tmpMeta35;
tmpMeta36 = _v;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta36,8,1) == 0) goto goto_27;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 2));
_vals = tmpMeta37;
{
modelica_metatype _val;
for (tmpMeta38 = _vals; !listEmpty(tmpMeta38); tmpMeta38=MMC_CDR(tmpMeta38))
{
_val = MMC_CAR(tmpMeta38);
tmpMeta39 = _vars;
if (listEmpty(tmpMeta39)) goto goto_27;
tmpMeta40 = MMC_CAR(tmpMeta39);
tmpMeta41 = MMC_CDR(tmpMeta39);
_var = tmpMeta40;
_vars = tmpMeta41;
_cache = omc_CevalFunction_assignVariable(threadData, omc_ComponentReference_makeUntypedCrefIdent(threadData, _var), _val, _cache, _inEnv ,&_env);
}
}
tmpMeta[3+0] = _cache;
tmpMeta[3+1] = _env;
tmpMeta[3+2] = _OMC_LIT71;
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
_cache = tmpMeta[3+0];
_env = tmpMeta[3+1];
_outLoopControl = tmpMeta[3+2];
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _env;
tmpMeta[0+2] = _OMC_LIT69;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,1) == 0) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _OMC_LIT71;
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _OMC_LIT72;
goto tmp3_done;
}
case 11: {
modelica_boolean tmp43;
tmp43 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (1 != tmp43) goto goto_2;
omc_Debug_traceln(threadData, _OMC_LIT73);
omc_Debug_traceln(threadData, omc_DAEDump_ppStatementStr(threadData, _inStatement));
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outLoopControl = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outLoopControl) { *out_outLoopControl = _outLoopControl; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateElement(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outLoopControl = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_metatype _env = NULL;
modelica_metatype _sl = NULL;
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
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_sl = tmpMeta7;
tmpMeta10 = mmc_mk_box2(0, boxvar_CevalFunction_optimizeExpTraverser, _inEnv);
tmpMeta11 = omc_DAEUtil_traverseDAEEquationsStmts(threadData, _sl, boxvar_Expression_traverseSubexpressionsHelper, tmpMeta10, &tmpMeta8);
_sl = tmpMeta11;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_env = tmpMeta9;
tmpMeta[0+0] = omc_CevalFunction_evaluateStatements(threadData, _sl, _inCache, _env, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
}
goto tmp3_end;
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
_outLoopControl = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outLoopControl) { *out_outLoopControl = _outLoopControl; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateElements(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inLoopControl, modelica_metatype *out_outEnv, modelica_metatype *out_outLoopControl)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype _outLoopControl = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inElements;
tmp4_2 = _inLoopControl;
{
modelica_metatype _elem = NULL;
modelica_metatype _rest_elems = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _loop_ctrl = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _inLoopControl;
goto tmp3_done;
}
case 1: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
tmpMeta[0+2] = _OMC_LIT69;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_elem = tmpMeta6;
_rest_elems = tmpMeta7;
_cache = omc_CevalFunction_evaluateElement(threadData, _elem, _inCache, _inEnv ,&_env ,&_loop_ctrl);
_inElements = _rest_elems;
_inCache = _cache;
_inEnv = _env;
_inLoopControl = _loop_ctrl;
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_outLoopControl = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
if (out_outLoopControl) { *out_outLoopControl = _outLoopControl; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateExternalFunc(threadData_t *threadData, modelica_string _inFuncName, modelica_metatype _inFuncArgs, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _inFuncName;
tmp4_2 = _inFuncArgs;
tmp4_3 = _inCache;
tmp4_4 = _inEnv;
{
modelica_metatype _arg_JOBU = NULL;
modelica_metatype _arg_JOBVL = NULL;
modelica_metatype _arg_JOBVR = NULL;
modelica_metatype _arg_JOBVT = NULL;
modelica_metatype _arg_TRANS = NULL;
modelica_metatype _arg_INFO = NULL;
modelica_metatype _arg_K = NULL;
modelica_metatype _arg_KL = NULL;
modelica_metatype _arg_KU = NULL;
modelica_metatype _arg_LDA = NULL;
modelica_metatype _arg_LDAB = NULL;
modelica_metatype _arg_LDB = NULL;
modelica_metatype _arg_LDU = NULL;
modelica_metatype _arg_LDVL = NULL;
modelica_metatype _arg_LDVR = NULL;
modelica_metatype _arg_LDVT = NULL;
modelica_metatype _arg_LWORK = NULL;
modelica_metatype _arg_M = NULL;
modelica_metatype _arg_N = NULL;
modelica_metatype _arg_NRHS = NULL;
modelica_metatype _arg_P = NULL;
modelica_metatype _arg_RANK = NULL;
modelica_metatype _arg_RCOND = NULL;
modelica_metatype _arg_IPIV = NULL;
modelica_metatype _arg_JPVT = NULL;
modelica_metatype _arg_ALPHAI = NULL;
modelica_metatype _arg_ALPHAR = NULL;
modelica_metatype _arg_BETA = NULL;
modelica_metatype _arg_C = NULL;
modelica_metatype _arg_D = NULL;
modelica_metatype _arg_DL = NULL;
modelica_metatype _arg_DU = NULL;
modelica_metatype _arg_TAU = NULL;
modelica_metatype _arg_WI = NULL;
modelica_metatype _arg_WORK = NULL;
modelica_metatype _arg_WR = NULL;
modelica_metatype _arg_X = NULL;
modelica_metatype _arg_A = NULL;
modelica_metatype _arg_AB = NULL;
modelica_metatype _arg_B = NULL;
modelica_metatype _arg_S = NULL;
modelica_metatype _arg_U = NULL;
modelica_metatype _arg_VL = NULL;
modelica_metatype _arg_VR = NULL;
modelica_metatype _arg_VT = NULL;
modelica_metatype _val_INFO = NULL;
modelica_metatype _val_RANK = NULL;
modelica_metatype _val_IPIV = NULL;
modelica_metatype _val_JPVT = NULL;
modelica_metatype _val_ALPHAI = NULL;
modelica_metatype _val_ALPHAR = NULL;
modelica_metatype _val_BETA = NULL;
modelica_metatype _val_C = NULL;
modelica_metatype _val_D = NULL;
modelica_metatype _val_DL = NULL;
modelica_metatype _val_DU = NULL;
modelica_metatype _val_TAU = NULL;
modelica_metatype _val_WI = NULL;
modelica_metatype _val_WORK = NULL;
modelica_metatype _val_WR = NULL;
modelica_metatype _val_X = NULL;
modelica_metatype _val_A = NULL;
modelica_metatype _val_AB = NULL;
modelica_metatype _val_B = NULL;
modelica_metatype _val_S = NULL;
modelica_metatype _val_U = NULL;
modelica_metatype _val_VL = NULL;
modelica_metatype _val_VR = NULL;
modelica_metatype _val_VT = NULL;
modelica_integer _INFO;
modelica_integer _K;
modelica_integer _KL;
modelica_integer _KU;
modelica_integer _LDA;
modelica_integer _LDAB;
modelica_integer _LDB;
modelica_integer _LDU;
modelica_integer _LDVL;
modelica_integer _LDVR;
modelica_integer _LDVT;
modelica_integer _LWORK;
modelica_integer _M;
modelica_integer _N;
modelica_integer _NRHS;
modelica_integer _P;
modelica_integer _RANK;
modelica_real _RCOND;
modelica_string _JOBU = NULL;
modelica_string _JOBVL = NULL;
modelica_string _JOBVR = NULL;
modelica_string _JOBVT = NULL;
modelica_string _TRANS = NULL;
modelica_metatype _IPIV = NULL;
modelica_metatype _JPVT = NULL;
modelica_metatype _ALPHAI = NULL;
modelica_metatype _ALPHAR = NULL;
modelica_metatype _BETA = NULL;
modelica_metatype _C = NULL;
modelica_metatype _D = NULL;
modelica_metatype _DL = NULL;
modelica_metatype _DU = NULL;
modelica_metatype _TAU = NULL;
modelica_metatype _WI = NULL;
modelica_metatype _WORK = NULL;
modelica_metatype _WR = NULL;
modelica_metatype _X = NULL;
modelica_metatype _S = NULL;
modelica_metatype _A = NULL;
modelica_metatype _AB = NULL;
modelica_metatype _B = NULL;
modelica_metatype _U = NULL;
modelica_metatype _VL = NULL;
modelica_metatype _VR = NULL;
modelica_metatype _VT = NULL;
modelica_metatype _arg_out = NULL;
modelica_metatype _val_out = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 16; tmp4++) {
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
if (5 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT74), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
if (listEmpty(tmpMeta11)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmpMeta11);
tmpMeta13 = MMC_CDR(tmpMeta11);
if (listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (listEmpty(tmpMeta15)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmpMeta15);
tmpMeta17 = MMC_CDR(tmpMeta15);
if (listEmpty(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmpMeta17);
tmpMeta19 = MMC_CDR(tmpMeta17);
if (listEmpty(tmpMeta19)) goto tmp3_end;
tmpMeta20 = MMC_CAR(tmpMeta19);
tmpMeta21 = MMC_CDR(tmpMeta19);
if (listEmpty(tmpMeta21)) goto tmp3_end;
tmpMeta22 = MMC_CAR(tmpMeta21);
tmpMeta23 = MMC_CDR(tmpMeta21);
if (listEmpty(tmpMeta23)) goto tmp3_end;
tmpMeta24 = MMC_CAR(tmpMeta23);
tmpMeta25 = MMC_CDR(tmpMeta23);
if (listEmpty(tmpMeta25)) goto tmp3_end;
tmpMeta26 = MMC_CAR(tmpMeta25);
tmpMeta27 = MMC_CDR(tmpMeta25);
if (listEmpty(tmpMeta27)) goto tmp3_end;
tmpMeta28 = MMC_CAR(tmpMeta27);
tmpMeta29 = MMC_CDR(tmpMeta27);
if (listEmpty(tmpMeta29)) goto tmp3_end;
tmpMeta30 = MMC_CAR(tmpMeta29);
tmpMeta31 = MMC_CDR(tmpMeta29);
if (listEmpty(tmpMeta31)) goto tmp3_end;
tmpMeta32 = MMC_CAR(tmpMeta31);
tmpMeta33 = MMC_CDR(tmpMeta31);
if (!listEmpty(tmpMeta33)) goto tmp3_end;
_arg_JOBVL = tmpMeta6;
_arg_JOBVR = tmpMeta8;
_arg_N = tmpMeta10;
_arg_A = tmpMeta12;
_arg_LDA = tmpMeta14;
_arg_WR = tmpMeta16;
_arg_WI = tmpMeta18;
_arg_VL = tmpMeta20;
_arg_LDVL = tmpMeta22;
_arg_VR = tmpMeta24;
_arg_LDVR = tmpMeta26;
_arg_WORK = tmpMeta28;
_arg_LWORK = tmpMeta30;
_arg_INFO = tmpMeta32;
_cache = tmp4_3;
_env = tmp4_4;
_JOBVL = omc_CevalFunction_evaluateExtStringArg(threadData, _arg_JOBVL, _cache, _env ,&_cache);
_JOBVR = omc_CevalFunction_evaluateExtStringArg(threadData, _arg_JOBVR, _cache, _env ,&_cache);
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_LDVL = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDVL, _cache, _env ,&_cache);
_LDVR = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDVR, _cache, _env ,&_cache);
_WORK = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_WORK, _cache, _env ,&_cache);
_LWORK = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LWORK, _cache, _env ,&_cache);
_A = omc_Lapack_dgeev(threadData, _JOBVL, _JOBVR, _N, _A, _LDA, _LDVL, _LDVR, _WORK, _LWORK ,&_WR ,&_WI ,&_VL ,&_VR ,&_WORK ,&_INFO);
_val_A = omc_ValuesUtil_makeRealMatrix(threadData, _A);
_val_WR = omc_ValuesUtil_makeRealArray(threadData, _WR);
_val_WI = omc_ValuesUtil_makeRealArray(threadData, _WI);
_val_VL = omc_ValuesUtil_makeRealMatrix(threadData, _VL);
_val_VR = omc_ValuesUtil_makeRealMatrix(threadData, _VR);
_val_WORK = omc_ValuesUtil_makeRealArray(threadData, _WORK);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta34 = mmc_mk_cons(_arg_A, mmc_mk_cons(_arg_WR, mmc_mk_cons(_arg_WI, mmc_mk_cons(_arg_VL, mmc_mk_cons(_arg_VR, mmc_mk_cons(_arg_WORK, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil))))))));
_arg_out = tmpMeta34;
tmpMeta35 = mmc_mk_cons(_val_A, mmc_mk_cons(_val_WR, mmc_mk_cons(_val_WI, mmc_mk_cons(_val_VL, mmc_mk_cons(_val_VR, mmc_mk_cons(_val_WORK, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil))))))));
_val_out = tmpMeta35;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
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
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
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
if (5 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT75), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta36 = MMC_CAR(tmp4_2);
tmpMeta37 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta37)) goto tmp3_end;
tmpMeta38 = MMC_CAR(tmpMeta37);
tmpMeta39 = MMC_CDR(tmpMeta37);
if (listEmpty(tmpMeta39)) goto tmp3_end;
tmpMeta40 = MMC_CAR(tmpMeta39);
tmpMeta41 = MMC_CDR(tmpMeta39);
if (listEmpty(tmpMeta41)) goto tmp3_end;
tmpMeta42 = MMC_CAR(tmpMeta41);
tmpMeta43 = MMC_CDR(tmpMeta41);
if (listEmpty(tmpMeta43)) goto tmp3_end;
tmpMeta44 = MMC_CAR(tmpMeta43);
tmpMeta45 = MMC_CDR(tmpMeta43);
if (listEmpty(tmpMeta45)) goto tmp3_end;
tmpMeta46 = MMC_CAR(tmpMeta45);
tmpMeta47 = MMC_CDR(tmpMeta45);
if (listEmpty(tmpMeta47)) goto tmp3_end;
tmpMeta48 = MMC_CAR(tmpMeta47);
tmpMeta49 = MMC_CDR(tmpMeta47);
if (listEmpty(tmpMeta49)) goto tmp3_end;
tmpMeta50 = MMC_CAR(tmpMeta49);
tmpMeta51 = MMC_CDR(tmpMeta49);
if (listEmpty(tmpMeta51)) goto tmp3_end;
tmpMeta52 = MMC_CAR(tmpMeta51);
tmpMeta53 = MMC_CDR(tmpMeta51);
if (listEmpty(tmpMeta53)) goto tmp3_end;
tmpMeta54 = MMC_CAR(tmpMeta53);
tmpMeta55 = MMC_CDR(tmpMeta53);
if (listEmpty(tmpMeta55)) goto tmp3_end;
tmpMeta56 = MMC_CAR(tmpMeta55);
tmpMeta57 = MMC_CDR(tmpMeta55);
if (listEmpty(tmpMeta57)) goto tmp3_end;
tmpMeta58 = MMC_CAR(tmpMeta57);
tmpMeta59 = MMC_CDR(tmpMeta57);
if (listEmpty(tmpMeta59)) goto tmp3_end;
tmpMeta60 = MMC_CAR(tmpMeta59);
tmpMeta61 = MMC_CDR(tmpMeta59);
if (listEmpty(tmpMeta61)) goto tmp3_end;
tmpMeta62 = MMC_CAR(tmpMeta61);
tmpMeta63 = MMC_CDR(tmpMeta61);
if (listEmpty(tmpMeta63)) goto tmp3_end;
tmpMeta64 = MMC_CAR(tmpMeta63);
tmpMeta65 = MMC_CDR(tmpMeta63);
if (listEmpty(tmpMeta65)) goto tmp3_end;
tmpMeta66 = MMC_CAR(tmpMeta65);
tmpMeta67 = MMC_CDR(tmpMeta65);
if (listEmpty(tmpMeta67)) goto tmp3_end;
tmpMeta68 = MMC_CAR(tmpMeta67);
tmpMeta69 = MMC_CDR(tmpMeta67);
if (!listEmpty(tmpMeta69)) goto tmp3_end;
_arg_JOBVL = tmpMeta36;
_arg_JOBVR = tmpMeta38;
_arg_N = tmpMeta40;
_arg_A = tmpMeta42;
_arg_LDA = tmpMeta44;
_arg_B = tmpMeta46;
_arg_LDB = tmpMeta48;
_arg_ALPHAR = tmpMeta50;
_arg_ALPHAI = tmpMeta52;
_arg_BETA = tmpMeta54;
_arg_VL = tmpMeta56;
_arg_LDVL = tmpMeta58;
_arg_VR = tmpMeta60;
_arg_LDVR = tmpMeta62;
_arg_WORK = tmpMeta64;
_arg_LWORK = tmpMeta66;
_arg_INFO = tmpMeta68;
_cache = tmp4_3;
_env = tmp4_4;
_JOBVL = omc_CevalFunction_evaluateExtStringArg(threadData, _arg_JOBVL, _cache, _env ,&_cache);
_JOBVR = omc_CevalFunction_evaluateExtStringArg(threadData, _arg_JOBVR, _cache, _env ,&_cache);
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_B = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_B, _cache, _env ,&_cache);
_LDB = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDB, _cache, _env ,&_cache);
_LDVL = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDVL, _cache, _env ,&_cache);
_LDVR = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDVR, _cache, _env ,&_cache);
_WORK = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_WORK, _cache, _env ,&_cache);
_LWORK = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LWORK, _cache, _env ,&_cache);
_ALPHAR = omc_Lapack_dgegv(threadData, _JOBVL, _JOBVR, _N, _A, _LDA, _B, _LDB, _LDVL, _LDVR, _WORK, _LWORK ,&_ALPHAI ,&_BETA ,&_VL ,&_VR ,&_WORK ,&_INFO);
_val_ALPHAR = omc_ValuesUtil_makeRealArray(threadData, _ALPHAR);
_val_ALPHAI = omc_ValuesUtil_makeRealArray(threadData, _ALPHAI);
_val_BETA = omc_ValuesUtil_makeRealArray(threadData, _BETA);
_val_VL = omc_ValuesUtil_makeRealMatrix(threadData, _VL);
_val_VR = omc_ValuesUtil_makeRealMatrix(threadData, _VR);
_val_WORK = omc_ValuesUtil_makeRealArray(threadData, _WORK);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta70 = mmc_mk_cons(_arg_ALPHAR, mmc_mk_cons(_arg_ALPHAI, mmc_mk_cons(_arg_BETA, mmc_mk_cons(_arg_VL, mmc_mk_cons(_arg_VR, mmc_mk_cons(_arg_WORK, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil))))))));
_arg_out = tmpMeta70;
tmpMeta71 = mmc_mk_cons(_val_ALPHAR, mmc_mk_cons(_val_ALPHAI, mmc_mk_cons(_val_BETA, mmc_mk_cons(_val_VL, mmc_mk_cons(_val_VR, mmc_mk_cons(_val_WORK, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil))))))));
_val_out = tmpMeta71;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
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
if (5 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT76), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta72 = MMC_CAR(tmp4_2);
tmpMeta73 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta73)) goto tmp3_end;
tmpMeta74 = MMC_CAR(tmpMeta73);
tmpMeta75 = MMC_CDR(tmpMeta73);
if (listEmpty(tmpMeta75)) goto tmp3_end;
tmpMeta76 = MMC_CAR(tmpMeta75);
tmpMeta77 = MMC_CDR(tmpMeta75);
if (listEmpty(tmpMeta77)) goto tmp3_end;
tmpMeta78 = MMC_CAR(tmpMeta77);
tmpMeta79 = MMC_CDR(tmpMeta77);
if (listEmpty(tmpMeta79)) goto tmp3_end;
tmpMeta80 = MMC_CAR(tmpMeta79);
tmpMeta81 = MMC_CDR(tmpMeta79);
if (listEmpty(tmpMeta81)) goto tmp3_end;
tmpMeta82 = MMC_CAR(tmpMeta81);
tmpMeta83 = MMC_CDR(tmpMeta81);
if (listEmpty(tmpMeta83)) goto tmp3_end;
tmpMeta84 = MMC_CAR(tmpMeta83);
tmpMeta85 = MMC_CDR(tmpMeta83);
if (listEmpty(tmpMeta85)) goto tmp3_end;
tmpMeta86 = MMC_CAR(tmpMeta85);
tmpMeta87 = MMC_CDR(tmpMeta85);
if (listEmpty(tmpMeta87)) goto tmp3_end;
tmpMeta88 = MMC_CAR(tmpMeta87);
tmpMeta89 = MMC_CDR(tmpMeta87);
if (listEmpty(tmpMeta89)) goto tmp3_end;
tmpMeta90 = MMC_CAR(tmpMeta89);
tmpMeta91 = MMC_CDR(tmpMeta89);
if (listEmpty(tmpMeta91)) goto tmp3_end;
tmpMeta92 = MMC_CAR(tmpMeta91);
tmpMeta93 = MMC_CDR(tmpMeta91);
if (!listEmpty(tmpMeta93)) goto tmp3_end;
_arg_TRANS = tmpMeta72;
_arg_M = tmpMeta74;
_arg_N = tmpMeta76;
_arg_NRHS = tmpMeta78;
_arg_A = tmpMeta80;
_arg_LDA = tmpMeta82;
_arg_B = tmpMeta84;
_arg_LDB = tmpMeta86;
_arg_WORK = tmpMeta88;
_arg_LWORK = tmpMeta90;
_arg_INFO = tmpMeta92;
_cache = tmp4_3;
_env = tmp4_4;
_TRANS = omc_CevalFunction_evaluateExtStringArg(threadData, _arg_TRANS, _cache, _env ,&_cache);
_M = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_M, _cache, _env ,&_cache);
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_NRHS = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_NRHS, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_B = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_B, _cache, _env ,&_cache);
_LDB = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDB, _cache, _env ,&_cache);
_WORK = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_WORK, _cache, _env ,&_cache);
_LWORK = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LWORK, _cache, _env ,&_cache);
_A = omc_Lapack_dgels(threadData, _TRANS, _M, _N, _NRHS, _A, _LDA, _B, _LDB, _WORK, _LWORK ,&_B ,&_WORK ,&_INFO);
_val_A = omc_ValuesUtil_makeRealMatrix(threadData, _A);
_val_B = omc_ValuesUtil_makeRealMatrix(threadData, _B);
_val_WORK = omc_ValuesUtil_makeRealArray(threadData, _WORK);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta94 = mmc_mk_cons(_arg_A, mmc_mk_cons(_arg_B, mmc_mk_cons(_arg_WORK, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil)))));
_arg_out = tmpMeta94;
tmpMeta95 = mmc_mk_cons(_val_A, mmc_mk_cons(_val_B, mmc_mk_cons(_val_WORK, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil)))));
_val_out = tmpMeta95;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
modelica_metatype tmpMeta104;
modelica_metatype tmpMeta105;
modelica_metatype tmpMeta106;
modelica_metatype tmpMeta107;
modelica_metatype tmpMeta108;
modelica_metatype tmpMeta109;
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
modelica_metatype tmpMeta113;
modelica_metatype tmpMeta114;
modelica_metatype tmpMeta115;
modelica_metatype tmpMeta116;
modelica_metatype tmpMeta117;
modelica_metatype tmpMeta118;
modelica_metatype tmpMeta119;
modelica_metatype tmpMeta120;
modelica_metatype tmpMeta121;
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT77), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta96 = MMC_CAR(tmp4_2);
tmpMeta97 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta97)) goto tmp3_end;
tmpMeta98 = MMC_CAR(tmpMeta97);
tmpMeta99 = MMC_CDR(tmpMeta97);
if (listEmpty(tmpMeta99)) goto tmp3_end;
tmpMeta100 = MMC_CAR(tmpMeta99);
tmpMeta101 = MMC_CDR(tmpMeta99);
if (listEmpty(tmpMeta101)) goto tmp3_end;
tmpMeta102 = MMC_CAR(tmpMeta101);
tmpMeta103 = MMC_CDR(tmpMeta101);
if (listEmpty(tmpMeta103)) goto tmp3_end;
tmpMeta104 = MMC_CAR(tmpMeta103);
tmpMeta105 = MMC_CDR(tmpMeta103);
if (listEmpty(tmpMeta105)) goto tmp3_end;
tmpMeta106 = MMC_CAR(tmpMeta105);
tmpMeta107 = MMC_CDR(tmpMeta105);
if (listEmpty(tmpMeta107)) goto tmp3_end;
tmpMeta108 = MMC_CAR(tmpMeta107);
tmpMeta109 = MMC_CDR(tmpMeta107);
if (listEmpty(tmpMeta109)) goto tmp3_end;
tmpMeta110 = MMC_CAR(tmpMeta109);
tmpMeta111 = MMC_CDR(tmpMeta109);
if (listEmpty(tmpMeta111)) goto tmp3_end;
tmpMeta112 = MMC_CAR(tmpMeta111);
tmpMeta113 = MMC_CDR(tmpMeta111);
if (listEmpty(tmpMeta113)) goto tmp3_end;
tmpMeta114 = MMC_CAR(tmpMeta113);
tmpMeta115 = MMC_CDR(tmpMeta113);
if (listEmpty(tmpMeta115)) goto tmp3_end;
tmpMeta116 = MMC_CAR(tmpMeta115);
tmpMeta117 = MMC_CDR(tmpMeta115);
if (listEmpty(tmpMeta117)) goto tmp3_end;
tmpMeta118 = MMC_CAR(tmpMeta117);
tmpMeta119 = MMC_CDR(tmpMeta117);
if (!listEmpty(tmpMeta119)) goto tmp3_end;
_arg_M = tmpMeta96;
_arg_N = tmpMeta98;
_arg_NRHS = tmpMeta100;
_arg_A = tmpMeta102;
_arg_LDA = tmpMeta104;
_arg_B = tmpMeta106;
_arg_LDB = tmpMeta108;
_arg_JPVT = tmpMeta110;
_arg_RCOND = tmpMeta112;
_arg_RANK = tmpMeta114;
_arg_WORK = tmpMeta116;
_arg_INFO = tmpMeta118;
_cache = tmp4_3;
_env = tmp4_4;
_M = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_M, _cache, _env ,&_cache);
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_NRHS = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_NRHS, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_B = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_B, _cache, _env ,&_cache);
_LDB = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDB, _cache, _env ,&_cache);
_JPVT = omc_CevalFunction_evaluateExtIntArrayArg(threadData, _arg_JPVT, _cache, _env ,&_cache);
_RCOND = omc_CevalFunction_evaluateExtRealArg(threadData, _arg_RCOND, _cache, _env ,&_cache);
_WORK = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_WORK, _cache, _env ,&_cache);
_A = omc_Lapack_dgelsx(threadData, _M, _N, _NRHS, _A, _LDA, _B, _LDB, _JPVT, _RCOND, _WORK ,&_B ,&_JPVT ,&_RANK ,&_INFO);
_val_A = omc_ValuesUtil_makeRealMatrix(threadData, _A);
_val_B = omc_ValuesUtil_makeRealMatrix(threadData, _B);
_val_JPVT = omc_ValuesUtil_makeIntArray(threadData, _JPVT);
_val_RANK = omc_ValuesUtil_makeInteger(threadData, _RANK);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta120 = mmc_mk_cons(_arg_A, mmc_mk_cons(_arg_B, mmc_mk_cons(_arg_JPVT, mmc_mk_cons(_arg_RANK, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil))))));
_arg_out = tmpMeta120;
tmpMeta121 = mmc_mk_cons(_val_A, mmc_mk_cons(_val_B, mmc_mk_cons(_val_JPVT, mmc_mk_cons(_val_RANK, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil))))));
_val_out = tmpMeta121;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta122;
modelica_metatype tmpMeta123;
modelica_metatype tmpMeta124;
modelica_metatype tmpMeta125;
modelica_metatype tmpMeta126;
modelica_metatype tmpMeta127;
modelica_metatype tmpMeta128;
modelica_metatype tmpMeta129;
modelica_metatype tmpMeta130;
modelica_metatype tmpMeta131;
modelica_metatype tmpMeta132;
modelica_metatype tmpMeta133;
modelica_metatype tmpMeta134;
modelica_metatype tmpMeta135;
modelica_metatype tmpMeta136;
modelica_metatype tmpMeta137;
modelica_metatype tmpMeta138;
modelica_metatype tmpMeta139;
modelica_metatype tmpMeta140;
modelica_metatype tmpMeta141;
modelica_metatype tmpMeta142;
modelica_metatype tmpMeta143;
modelica_metatype tmpMeta144;
modelica_metatype tmpMeta145;
modelica_metatype tmpMeta146;
modelica_metatype tmpMeta147;
modelica_metatype tmpMeta148;
modelica_metatype tmpMeta149;
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT77), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta122 = MMC_CAR(tmp4_2);
tmpMeta123 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta123)) goto tmp3_end;
tmpMeta124 = MMC_CAR(tmpMeta123);
tmpMeta125 = MMC_CDR(tmpMeta123);
if (listEmpty(tmpMeta125)) goto tmp3_end;
tmpMeta126 = MMC_CAR(tmpMeta125);
tmpMeta127 = MMC_CDR(tmpMeta125);
if (listEmpty(tmpMeta127)) goto tmp3_end;
tmpMeta128 = MMC_CAR(tmpMeta127);
tmpMeta129 = MMC_CDR(tmpMeta127);
if (listEmpty(tmpMeta129)) goto tmp3_end;
tmpMeta130 = MMC_CAR(tmpMeta129);
tmpMeta131 = MMC_CDR(tmpMeta129);
if (listEmpty(tmpMeta131)) goto tmp3_end;
tmpMeta132 = MMC_CAR(tmpMeta131);
tmpMeta133 = MMC_CDR(tmpMeta131);
if (listEmpty(tmpMeta133)) goto tmp3_end;
tmpMeta134 = MMC_CAR(tmpMeta133);
tmpMeta135 = MMC_CDR(tmpMeta133);
if (listEmpty(tmpMeta135)) goto tmp3_end;
tmpMeta136 = MMC_CAR(tmpMeta135);
tmpMeta137 = MMC_CDR(tmpMeta135);
if (listEmpty(tmpMeta137)) goto tmp3_end;
tmpMeta138 = MMC_CAR(tmpMeta137);
tmpMeta139 = MMC_CDR(tmpMeta137);
if (listEmpty(tmpMeta139)) goto tmp3_end;
tmpMeta140 = MMC_CAR(tmpMeta139);
tmpMeta141 = MMC_CDR(tmpMeta139);
if (listEmpty(tmpMeta141)) goto tmp3_end;
tmpMeta142 = MMC_CAR(tmpMeta141);
tmpMeta143 = MMC_CDR(tmpMeta141);
if (listEmpty(tmpMeta143)) goto tmp3_end;
tmpMeta144 = MMC_CAR(tmpMeta143);
tmpMeta145 = MMC_CDR(tmpMeta143);
if (listEmpty(tmpMeta145)) goto tmp3_end;
tmpMeta146 = MMC_CAR(tmpMeta145);
tmpMeta147 = MMC_CDR(tmpMeta145);
if (!listEmpty(tmpMeta147)) goto tmp3_end;
_arg_M = tmpMeta122;
_arg_N = tmpMeta124;
_arg_NRHS = tmpMeta126;
_arg_A = tmpMeta128;
_arg_LDA = tmpMeta130;
_arg_B = tmpMeta132;
_arg_LDB = tmpMeta134;
_arg_JPVT = tmpMeta136;
_arg_RCOND = tmpMeta138;
_arg_RANK = tmpMeta140;
_arg_WORK = tmpMeta142;
_arg_INFO = tmpMeta146;
_cache = tmp4_3;
_env = tmp4_4;
_M = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_M, _cache, _env ,&_cache);
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_NRHS = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_NRHS, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_B = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_B, _cache, _env ,&_cache);
_LDB = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDB, _cache, _env ,&_cache);
_JPVT = omc_CevalFunction_evaluateExtIntArrayArg(threadData, _arg_JPVT, _cache, _env ,&_cache);
_RCOND = omc_CevalFunction_evaluateExtRealArg(threadData, _arg_RCOND, _cache, _env ,&_cache);
_WORK = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_WORK, _cache, _env ,&_cache);
_A = omc_Lapack_dgelsx(threadData, _M, _N, _NRHS, _A, _LDA, _B, _LDB, _JPVT, _RCOND, _WORK ,&_B ,&_JPVT ,&_RANK ,&_INFO);
_val_A = omc_ValuesUtil_makeRealMatrix(threadData, _A);
_val_B = omc_ValuesUtil_makeRealMatrix(threadData, _B);
_val_JPVT = omc_ValuesUtil_makeIntArray(threadData, _JPVT);
_val_RANK = omc_ValuesUtil_makeInteger(threadData, _RANK);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta148 = mmc_mk_cons(_arg_A, mmc_mk_cons(_arg_B, mmc_mk_cons(_arg_JPVT, mmc_mk_cons(_arg_RANK, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil))))));
_arg_out = tmpMeta148;
tmpMeta149 = mmc_mk_cons(_val_A, mmc_mk_cons(_val_B, mmc_mk_cons(_val_JPVT, mmc_mk_cons(_val_RANK, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil))))));
_val_out = tmpMeta149;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta150;
modelica_metatype tmpMeta151;
modelica_metatype tmpMeta152;
modelica_metatype tmpMeta153;
modelica_metatype tmpMeta154;
modelica_metatype tmpMeta155;
modelica_metatype tmpMeta156;
modelica_metatype tmpMeta157;
modelica_metatype tmpMeta158;
modelica_metatype tmpMeta159;
modelica_metatype tmpMeta160;
modelica_metatype tmpMeta161;
modelica_metatype tmpMeta162;
modelica_metatype tmpMeta163;
modelica_metatype tmpMeta164;
modelica_metatype tmpMeta165;
modelica_metatype tmpMeta166;
modelica_metatype tmpMeta167;
modelica_metatype tmpMeta168;
modelica_metatype tmpMeta169;
modelica_metatype tmpMeta170;
modelica_metatype tmpMeta171;
modelica_metatype tmpMeta172;
modelica_metatype tmpMeta173;
modelica_metatype tmpMeta174;
modelica_metatype tmpMeta175;
modelica_metatype tmpMeta176;
modelica_metatype tmpMeta177;
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT78), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta150 = MMC_CAR(tmp4_2);
tmpMeta151 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta151)) goto tmp3_end;
tmpMeta152 = MMC_CAR(tmpMeta151);
tmpMeta153 = MMC_CDR(tmpMeta151);
if (listEmpty(tmpMeta153)) goto tmp3_end;
tmpMeta154 = MMC_CAR(tmpMeta153);
tmpMeta155 = MMC_CDR(tmpMeta153);
if (listEmpty(tmpMeta155)) goto tmp3_end;
tmpMeta156 = MMC_CAR(tmpMeta155);
tmpMeta157 = MMC_CDR(tmpMeta155);
if (listEmpty(tmpMeta157)) goto tmp3_end;
tmpMeta158 = MMC_CAR(tmpMeta157);
tmpMeta159 = MMC_CDR(tmpMeta157);
if (listEmpty(tmpMeta159)) goto tmp3_end;
tmpMeta160 = MMC_CAR(tmpMeta159);
tmpMeta161 = MMC_CDR(tmpMeta159);
if (listEmpty(tmpMeta161)) goto tmp3_end;
tmpMeta162 = MMC_CAR(tmpMeta161);
tmpMeta163 = MMC_CDR(tmpMeta161);
if (listEmpty(tmpMeta163)) goto tmp3_end;
tmpMeta164 = MMC_CAR(tmpMeta163);
tmpMeta165 = MMC_CDR(tmpMeta163);
if (listEmpty(tmpMeta165)) goto tmp3_end;
tmpMeta166 = MMC_CAR(tmpMeta165);
tmpMeta167 = MMC_CDR(tmpMeta165);
if (listEmpty(tmpMeta167)) goto tmp3_end;
tmpMeta168 = MMC_CAR(tmpMeta167);
tmpMeta169 = MMC_CDR(tmpMeta167);
if (listEmpty(tmpMeta169)) goto tmp3_end;
tmpMeta170 = MMC_CAR(tmpMeta169);
tmpMeta171 = MMC_CDR(tmpMeta169);
if (listEmpty(tmpMeta171)) goto tmp3_end;
tmpMeta172 = MMC_CAR(tmpMeta171);
tmpMeta173 = MMC_CDR(tmpMeta171);
if (listEmpty(tmpMeta173)) goto tmp3_end;
tmpMeta174 = MMC_CAR(tmpMeta173);
tmpMeta175 = MMC_CDR(tmpMeta173);
if (!listEmpty(tmpMeta175)) goto tmp3_end;
_arg_M = tmpMeta150;
_arg_N = tmpMeta152;
_arg_NRHS = tmpMeta154;
_arg_A = tmpMeta156;
_arg_LDA = tmpMeta158;
_arg_B = tmpMeta160;
_arg_LDB = tmpMeta162;
_arg_JPVT = tmpMeta164;
_arg_RCOND = tmpMeta166;
_arg_RANK = tmpMeta168;
_arg_WORK = tmpMeta170;
_arg_LWORK = tmpMeta172;
_arg_INFO = tmpMeta174;
_cache = tmp4_3;
_env = tmp4_4;
_M = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_M, _cache, _env ,&_cache);
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_NRHS = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_NRHS, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_B = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_B, _cache, _env ,&_cache);
_LDB = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDB, _cache, _env ,&_cache);
_JPVT = omc_CevalFunction_evaluateExtIntArrayArg(threadData, _arg_JPVT, _cache, _env ,&_cache);
_RCOND = omc_CevalFunction_evaluateExtRealArg(threadData, _arg_RCOND, _cache, _env ,&_cache);
_WORK = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_WORK, _cache, _env ,&_cache);
_LWORK = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LWORK, _cache, _env ,&_cache);
_A = omc_Lapack_dgelsy(threadData, _M, _N, _NRHS, _A, _LDA, _B, _LDB, _JPVT, _RCOND, _WORK, _LWORK ,&_B ,&_JPVT ,&_RANK ,&_WORK ,&_INFO);
_val_A = omc_ValuesUtil_makeRealMatrix(threadData, _A);
_val_B = omc_ValuesUtil_makeRealMatrix(threadData, _B);
_val_JPVT = omc_ValuesUtil_makeIntArray(threadData, _JPVT);
_val_RANK = omc_ValuesUtil_makeInteger(threadData, _RANK);
_val_WORK = omc_ValuesUtil_makeRealArray(threadData, _WORK);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta176 = mmc_mk_cons(_arg_A, mmc_mk_cons(_arg_B, mmc_mk_cons(_arg_JPVT, mmc_mk_cons(_arg_RANK, mmc_mk_cons(_arg_WORK, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil)))))));
_arg_out = tmpMeta176;
tmpMeta177 = mmc_mk_cons(_val_A, mmc_mk_cons(_val_B, mmc_mk_cons(_val_JPVT, mmc_mk_cons(_val_RANK, mmc_mk_cons(_val_WORK, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil)))))));
_val_out = tmpMeta177;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta178;
modelica_metatype tmpMeta179;
modelica_metatype tmpMeta180;
modelica_metatype tmpMeta181;
modelica_metatype tmpMeta182;
modelica_metatype tmpMeta183;
modelica_metatype tmpMeta184;
modelica_metatype tmpMeta185;
modelica_metatype tmpMeta186;
modelica_metatype tmpMeta187;
modelica_metatype tmpMeta188;
modelica_metatype tmpMeta189;
modelica_metatype tmpMeta190;
modelica_metatype tmpMeta191;
modelica_metatype tmpMeta192;
modelica_metatype tmpMeta193;
modelica_metatype tmpMeta194;
modelica_metatype tmpMeta195;
if (5 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT79), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta178 = MMC_CAR(tmp4_2);
tmpMeta179 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta179)) goto tmp3_end;
tmpMeta180 = MMC_CAR(tmpMeta179);
tmpMeta181 = MMC_CDR(tmpMeta179);
if (listEmpty(tmpMeta181)) goto tmp3_end;
tmpMeta182 = MMC_CAR(tmpMeta181);
tmpMeta183 = MMC_CDR(tmpMeta181);
if (listEmpty(tmpMeta183)) goto tmp3_end;
tmpMeta184 = MMC_CAR(tmpMeta183);
tmpMeta185 = MMC_CDR(tmpMeta183);
if (listEmpty(tmpMeta185)) goto tmp3_end;
tmpMeta186 = MMC_CAR(tmpMeta185);
tmpMeta187 = MMC_CDR(tmpMeta185);
if (listEmpty(tmpMeta187)) goto tmp3_end;
tmpMeta188 = MMC_CAR(tmpMeta187);
tmpMeta189 = MMC_CDR(tmpMeta187);
if (listEmpty(tmpMeta189)) goto tmp3_end;
tmpMeta190 = MMC_CAR(tmpMeta189);
tmpMeta191 = MMC_CDR(tmpMeta189);
if (listEmpty(tmpMeta191)) goto tmp3_end;
tmpMeta192 = MMC_CAR(tmpMeta191);
tmpMeta193 = MMC_CDR(tmpMeta191);
if (!listEmpty(tmpMeta193)) goto tmp3_end;
_arg_N = tmpMeta178;
_arg_NRHS = tmpMeta180;
_arg_A = tmpMeta182;
_arg_LDA = tmpMeta184;
_arg_IPIV = tmpMeta186;
_arg_B = tmpMeta188;
_arg_LDB = tmpMeta190;
_arg_INFO = tmpMeta192;
_cache = tmp4_3;
_env = tmp4_4;
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_NRHS = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_NRHS, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_B = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_B, _cache, _env ,&_cache);
_LDB = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDB, _cache, _env ,&_cache);
_A = omc_Lapack_dgesv(threadData, _N, _NRHS, _A, _LDA, _B, _LDB ,&_IPIV ,&_B ,&_INFO);
_val_A = omc_ValuesUtil_makeRealMatrix(threadData, _A);
_val_IPIV = omc_ValuesUtil_makeIntArray(threadData, _IPIV);
_val_B = omc_ValuesUtil_makeRealMatrix(threadData, _B);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta194 = mmc_mk_cons(_arg_A, mmc_mk_cons(_arg_IPIV, mmc_mk_cons(_arg_B, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil)))));
_arg_out = tmpMeta194;
tmpMeta195 = mmc_mk_cons(_val_A, mmc_mk_cons(_val_IPIV, mmc_mk_cons(_val_B, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil)))));
_val_out = tmpMeta195;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta196;
modelica_metatype tmpMeta197;
modelica_metatype tmpMeta198;
modelica_metatype tmpMeta199;
modelica_metatype tmpMeta200;
modelica_metatype tmpMeta201;
modelica_metatype tmpMeta202;
modelica_metatype tmpMeta203;
modelica_metatype tmpMeta204;
modelica_metatype tmpMeta205;
modelica_metatype tmpMeta206;
modelica_metatype tmpMeta207;
modelica_metatype tmpMeta208;
modelica_metatype tmpMeta209;
modelica_metatype tmpMeta210;
modelica_metatype tmpMeta211;
modelica_metatype tmpMeta212;
modelica_metatype tmpMeta213;
modelica_metatype tmpMeta214;
modelica_metatype tmpMeta215;
modelica_metatype tmpMeta216;
modelica_metatype tmpMeta217;
modelica_metatype tmpMeta218;
modelica_metatype tmpMeta219;
modelica_metatype tmpMeta220;
modelica_metatype tmpMeta221;
modelica_metatype tmpMeta222;
modelica_metatype tmpMeta223;
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT80), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta196 = MMC_CAR(tmp4_2);
tmpMeta197 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta197)) goto tmp3_end;
tmpMeta198 = MMC_CAR(tmpMeta197);
tmpMeta199 = MMC_CDR(tmpMeta197);
if (listEmpty(tmpMeta199)) goto tmp3_end;
tmpMeta200 = MMC_CAR(tmpMeta199);
tmpMeta201 = MMC_CDR(tmpMeta199);
if (listEmpty(tmpMeta201)) goto tmp3_end;
tmpMeta202 = MMC_CAR(tmpMeta201);
tmpMeta203 = MMC_CDR(tmpMeta201);
if (listEmpty(tmpMeta203)) goto tmp3_end;
tmpMeta204 = MMC_CAR(tmpMeta203);
tmpMeta205 = MMC_CDR(tmpMeta203);
if (listEmpty(tmpMeta205)) goto tmp3_end;
tmpMeta206 = MMC_CAR(tmpMeta205);
tmpMeta207 = MMC_CDR(tmpMeta205);
if (listEmpty(tmpMeta207)) goto tmp3_end;
tmpMeta208 = MMC_CAR(tmpMeta207);
tmpMeta209 = MMC_CDR(tmpMeta207);
if (listEmpty(tmpMeta209)) goto tmp3_end;
tmpMeta210 = MMC_CAR(tmpMeta209);
tmpMeta211 = MMC_CDR(tmpMeta209);
if (listEmpty(tmpMeta211)) goto tmp3_end;
tmpMeta212 = MMC_CAR(tmpMeta211);
tmpMeta213 = MMC_CDR(tmpMeta211);
if (listEmpty(tmpMeta213)) goto tmp3_end;
tmpMeta214 = MMC_CAR(tmpMeta213);
tmpMeta215 = MMC_CDR(tmpMeta213);
if (listEmpty(tmpMeta215)) goto tmp3_end;
tmpMeta216 = MMC_CAR(tmpMeta215);
tmpMeta217 = MMC_CDR(tmpMeta215);
if (listEmpty(tmpMeta217)) goto tmp3_end;
tmpMeta218 = MMC_CAR(tmpMeta217);
tmpMeta219 = MMC_CDR(tmpMeta217);
if (listEmpty(tmpMeta219)) goto tmp3_end;
tmpMeta220 = MMC_CAR(tmpMeta219);
tmpMeta221 = MMC_CDR(tmpMeta219);
if (!listEmpty(tmpMeta221)) goto tmp3_end;
_arg_M = tmpMeta196;
_arg_N = tmpMeta198;
_arg_P = tmpMeta200;
_arg_A = tmpMeta202;
_arg_LDA = tmpMeta204;
_arg_B = tmpMeta206;
_arg_LDB = tmpMeta208;
_arg_C = tmpMeta210;
_arg_D = tmpMeta212;
_arg_X = tmpMeta214;
_arg_WORK = tmpMeta216;
_arg_LWORK = tmpMeta218;
_arg_INFO = tmpMeta220;
_cache = tmp4_3;
_env = tmp4_4;
_M = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_M, _cache, _env ,&_cache);
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_P = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_P, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_B = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_B, _cache, _env ,&_cache);
_LDB = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDB, _cache, _env ,&_cache);
_C = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_C, _cache, _env ,&_cache);
_D = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_D, _cache, _env ,&_cache);
_WORK = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_WORK, _cache, _env ,&_cache);
_LWORK = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LWORK, _cache, _env ,&_cache);
_A = omc_Lapack_dgglse(threadData, _M, _N, _P, _A, _LDA, _B, _LDB, _C, _D, _WORK, _LWORK ,&_B ,&_C ,&_D ,&_X ,&_WORK ,&_INFO);
_val_A = omc_ValuesUtil_makeRealMatrix(threadData, _A);
_val_B = omc_ValuesUtil_makeRealMatrix(threadData, _B);
_val_C = omc_ValuesUtil_makeRealArray(threadData, _C);
_val_D = omc_ValuesUtil_makeRealArray(threadData, _D);
_val_X = omc_ValuesUtil_makeRealArray(threadData, _X);
_val_WORK = omc_ValuesUtil_makeRealArray(threadData, _WORK);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta222 = mmc_mk_cons(_arg_A, mmc_mk_cons(_arg_B, mmc_mk_cons(_arg_C, mmc_mk_cons(_arg_D, mmc_mk_cons(_arg_X, mmc_mk_cons(_arg_WORK, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil))))))));
_arg_out = tmpMeta222;
tmpMeta223 = mmc_mk_cons(_val_A, mmc_mk_cons(_val_B, mmc_mk_cons(_val_C, mmc_mk_cons(_val_D, mmc_mk_cons(_val_X, mmc_mk_cons(_val_WORK, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil))))))));
_val_out = tmpMeta223;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta224;
modelica_metatype tmpMeta225;
modelica_metatype tmpMeta226;
modelica_metatype tmpMeta227;
modelica_metatype tmpMeta228;
modelica_metatype tmpMeta229;
modelica_metatype tmpMeta230;
modelica_metatype tmpMeta231;
modelica_metatype tmpMeta232;
modelica_metatype tmpMeta233;
modelica_metatype tmpMeta234;
modelica_metatype tmpMeta235;
modelica_metatype tmpMeta236;
modelica_metatype tmpMeta237;
modelica_metatype tmpMeta238;
modelica_metatype tmpMeta239;
modelica_metatype tmpMeta240;
modelica_metatype tmpMeta241;
if (5 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT81), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta224 = MMC_CAR(tmp4_2);
tmpMeta225 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta225)) goto tmp3_end;
tmpMeta226 = MMC_CAR(tmpMeta225);
tmpMeta227 = MMC_CDR(tmpMeta225);
if (listEmpty(tmpMeta227)) goto tmp3_end;
tmpMeta228 = MMC_CAR(tmpMeta227);
tmpMeta229 = MMC_CDR(tmpMeta227);
if (listEmpty(tmpMeta229)) goto tmp3_end;
tmpMeta230 = MMC_CAR(tmpMeta229);
tmpMeta231 = MMC_CDR(tmpMeta229);
if (listEmpty(tmpMeta231)) goto tmp3_end;
tmpMeta232 = MMC_CAR(tmpMeta231);
tmpMeta233 = MMC_CDR(tmpMeta231);
if (listEmpty(tmpMeta233)) goto tmp3_end;
tmpMeta234 = MMC_CAR(tmpMeta233);
tmpMeta235 = MMC_CDR(tmpMeta233);
if (listEmpty(tmpMeta235)) goto tmp3_end;
tmpMeta236 = MMC_CAR(tmpMeta235);
tmpMeta237 = MMC_CDR(tmpMeta235);
if (listEmpty(tmpMeta237)) goto tmp3_end;
tmpMeta238 = MMC_CAR(tmpMeta237);
tmpMeta239 = MMC_CDR(tmpMeta237);
if (!listEmpty(tmpMeta239)) goto tmp3_end;
_arg_N = tmpMeta224;
_arg_NRHS = tmpMeta226;
_arg_DL = tmpMeta228;
_arg_D = tmpMeta230;
_arg_DU = tmpMeta232;
_arg_B = tmpMeta234;
_arg_LDB = tmpMeta236;
_arg_INFO = tmpMeta238;
_cache = tmp4_3;
_env = tmp4_4;
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_NRHS = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_NRHS, _cache, _env ,&_cache);
_DL = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_DL, _cache, _env ,&_cache);
_D = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_D, _cache, _env ,&_cache);
_DU = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_DU, _cache, _env ,&_cache);
_B = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_B, _cache, _env ,&_cache);
_LDB = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDB, _cache, _env ,&_cache);
_DL = omc_Lapack_dgtsv(threadData, _N, _NRHS, _DL, _D, _DU, _B, _LDB ,&_D ,&_DU ,&_B ,&_INFO);
_val_DL = omc_ValuesUtil_makeRealArray(threadData, _DL);
_val_D = omc_ValuesUtil_makeRealArray(threadData, _D);
_val_DU = omc_ValuesUtil_makeRealArray(threadData, _DU);
_val_B = omc_ValuesUtil_makeRealMatrix(threadData, _B);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta240 = mmc_mk_cons(_arg_DL, mmc_mk_cons(_arg_D, mmc_mk_cons(_arg_DU, mmc_mk_cons(_arg_B, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil))))));
_arg_out = tmpMeta240;
tmpMeta241 = mmc_mk_cons(_val_DL, mmc_mk_cons(_val_D, mmc_mk_cons(_val_DU, mmc_mk_cons(_val_B, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil))))));
_val_out = tmpMeta241;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta242;
modelica_metatype tmpMeta243;
modelica_metatype tmpMeta244;
modelica_metatype tmpMeta245;
modelica_metatype tmpMeta246;
modelica_metatype tmpMeta247;
modelica_metatype tmpMeta248;
modelica_metatype tmpMeta249;
modelica_metatype tmpMeta250;
modelica_metatype tmpMeta251;
modelica_metatype tmpMeta252;
modelica_metatype tmpMeta253;
modelica_metatype tmpMeta254;
modelica_metatype tmpMeta255;
modelica_metatype tmpMeta256;
modelica_metatype tmpMeta257;
modelica_metatype tmpMeta258;
modelica_metatype tmpMeta259;
modelica_metatype tmpMeta260;
modelica_metatype tmpMeta261;
modelica_metatype tmpMeta262;
modelica_metatype tmpMeta263;
if (5 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT82), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta242 = MMC_CAR(tmp4_2);
tmpMeta243 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta243)) goto tmp3_end;
tmpMeta244 = MMC_CAR(tmpMeta243);
tmpMeta245 = MMC_CDR(tmpMeta243);
if (listEmpty(tmpMeta245)) goto tmp3_end;
tmpMeta246 = MMC_CAR(tmpMeta245);
tmpMeta247 = MMC_CDR(tmpMeta245);
if (listEmpty(tmpMeta247)) goto tmp3_end;
tmpMeta248 = MMC_CAR(tmpMeta247);
tmpMeta249 = MMC_CDR(tmpMeta247);
if (listEmpty(tmpMeta249)) goto tmp3_end;
tmpMeta250 = MMC_CAR(tmpMeta249);
tmpMeta251 = MMC_CDR(tmpMeta249);
if (listEmpty(tmpMeta251)) goto tmp3_end;
tmpMeta252 = MMC_CAR(tmpMeta251);
tmpMeta253 = MMC_CDR(tmpMeta251);
if (listEmpty(tmpMeta253)) goto tmp3_end;
tmpMeta254 = MMC_CAR(tmpMeta253);
tmpMeta255 = MMC_CDR(tmpMeta253);
if (listEmpty(tmpMeta255)) goto tmp3_end;
tmpMeta256 = MMC_CAR(tmpMeta255);
tmpMeta257 = MMC_CDR(tmpMeta255);
if (listEmpty(tmpMeta257)) goto tmp3_end;
tmpMeta258 = MMC_CAR(tmpMeta257);
tmpMeta259 = MMC_CDR(tmpMeta257);
if (listEmpty(tmpMeta259)) goto tmp3_end;
tmpMeta260 = MMC_CAR(tmpMeta259);
tmpMeta261 = MMC_CDR(tmpMeta259);
if (!listEmpty(tmpMeta261)) goto tmp3_end;
_arg_N = tmpMeta242;
_arg_KL = tmpMeta244;
_arg_KU = tmpMeta246;
_arg_NRHS = tmpMeta248;
_arg_AB = tmpMeta250;
_arg_LDAB = tmpMeta252;
_arg_IPIV = tmpMeta254;
_arg_B = tmpMeta256;
_arg_LDB = tmpMeta258;
_arg_INFO = tmpMeta260;
_cache = tmp4_3;
_env = tmp4_4;
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_KL = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_KL, _cache, _env ,&_cache);
_KU = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_KU, _cache, _env ,&_cache);
_NRHS = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_NRHS, _cache, _env ,&_cache);
_AB = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_AB, _cache, _env ,&_cache);
_LDAB = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDAB, _cache, _env ,&_cache);
_B = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_B, _cache, _env ,&_cache);
_LDB = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDB, _cache, _env ,&_cache);
_AB = omc_Lapack_dgbsv(threadData, _N, _KL, _KU, _NRHS, _AB, _LDAB, _B, _LDB ,&_IPIV ,&_B ,&_INFO);
_val_AB = omc_ValuesUtil_makeRealMatrix(threadData, _AB);
_val_IPIV = omc_ValuesUtil_makeIntArray(threadData, _IPIV);
_val_B = omc_ValuesUtil_makeRealMatrix(threadData, _B);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta262 = mmc_mk_cons(_arg_AB, mmc_mk_cons(_arg_IPIV, mmc_mk_cons(_arg_B, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil)))));
_arg_out = tmpMeta262;
tmpMeta263 = mmc_mk_cons(_val_AB, mmc_mk_cons(_val_IPIV, mmc_mk_cons(_val_B, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil)))));
_val_out = tmpMeta263;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta264;
modelica_metatype tmpMeta265;
modelica_metatype tmpMeta266;
modelica_metatype tmpMeta267;
modelica_metatype tmpMeta268;
modelica_metatype tmpMeta269;
modelica_metatype tmpMeta270;
modelica_metatype tmpMeta271;
modelica_metatype tmpMeta272;
modelica_metatype tmpMeta273;
modelica_metatype tmpMeta274;
modelica_metatype tmpMeta275;
modelica_metatype tmpMeta276;
modelica_metatype tmpMeta277;
modelica_metatype tmpMeta278;
modelica_metatype tmpMeta279;
modelica_metatype tmpMeta280;
modelica_metatype tmpMeta281;
modelica_metatype tmpMeta282;
modelica_metatype tmpMeta283;
modelica_metatype tmpMeta284;
modelica_metatype tmpMeta285;
modelica_metatype tmpMeta286;
modelica_metatype tmpMeta287;
modelica_metatype tmpMeta288;
modelica_metatype tmpMeta289;
modelica_metatype tmpMeta290;
modelica_metatype tmpMeta291;
modelica_metatype tmpMeta292;
modelica_metatype tmpMeta293;
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT83), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta264 = MMC_CAR(tmp4_2);
tmpMeta265 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta265)) goto tmp3_end;
tmpMeta266 = MMC_CAR(tmpMeta265);
tmpMeta267 = MMC_CDR(tmpMeta265);
if (listEmpty(tmpMeta267)) goto tmp3_end;
tmpMeta268 = MMC_CAR(tmpMeta267);
tmpMeta269 = MMC_CDR(tmpMeta267);
if (listEmpty(tmpMeta269)) goto tmp3_end;
tmpMeta270 = MMC_CAR(tmpMeta269);
tmpMeta271 = MMC_CDR(tmpMeta269);
if (listEmpty(tmpMeta271)) goto tmp3_end;
tmpMeta272 = MMC_CAR(tmpMeta271);
tmpMeta273 = MMC_CDR(tmpMeta271);
if (listEmpty(tmpMeta273)) goto tmp3_end;
tmpMeta274 = MMC_CAR(tmpMeta273);
tmpMeta275 = MMC_CDR(tmpMeta273);
if (listEmpty(tmpMeta275)) goto tmp3_end;
tmpMeta276 = MMC_CAR(tmpMeta275);
tmpMeta277 = MMC_CDR(tmpMeta275);
if (listEmpty(tmpMeta277)) goto tmp3_end;
tmpMeta278 = MMC_CAR(tmpMeta277);
tmpMeta279 = MMC_CDR(tmpMeta277);
if (listEmpty(tmpMeta279)) goto tmp3_end;
tmpMeta280 = MMC_CAR(tmpMeta279);
tmpMeta281 = MMC_CDR(tmpMeta279);
if (listEmpty(tmpMeta281)) goto tmp3_end;
tmpMeta282 = MMC_CAR(tmpMeta281);
tmpMeta283 = MMC_CDR(tmpMeta281);
if (listEmpty(tmpMeta283)) goto tmp3_end;
tmpMeta284 = MMC_CAR(tmpMeta283);
tmpMeta285 = MMC_CDR(tmpMeta283);
if (listEmpty(tmpMeta285)) goto tmp3_end;
tmpMeta286 = MMC_CAR(tmpMeta285);
tmpMeta287 = MMC_CDR(tmpMeta285);
if (listEmpty(tmpMeta287)) goto tmp3_end;
tmpMeta288 = MMC_CAR(tmpMeta287);
tmpMeta289 = MMC_CDR(tmpMeta287);
if (listEmpty(tmpMeta289)) goto tmp3_end;
tmpMeta290 = MMC_CAR(tmpMeta289);
tmpMeta291 = MMC_CDR(tmpMeta289);
if (!listEmpty(tmpMeta291)) goto tmp3_end;
_arg_JOBU = tmpMeta264;
_arg_JOBVT = tmpMeta266;
_arg_M = tmpMeta268;
_arg_N = tmpMeta270;
_arg_A = tmpMeta272;
_arg_LDA = tmpMeta274;
_arg_S = tmpMeta276;
_arg_U = tmpMeta278;
_arg_LDU = tmpMeta280;
_arg_VT = tmpMeta282;
_arg_LDVT = tmpMeta284;
_arg_WORK = tmpMeta286;
_arg_LWORK = tmpMeta288;
_arg_INFO = tmpMeta290;
_cache = tmp4_3;
_env = tmp4_4;
_JOBU = omc_CevalFunction_evaluateExtStringArg(threadData, _arg_JOBU, _cache, _env ,&_cache);
_JOBVT = omc_CevalFunction_evaluateExtStringArg(threadData, _arg_JOBVT, _cache, _env ,&_cache);
_M = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_M, _cache, _env ,&_cache);
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_LDU = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDU, _cache, _env ,&_cache);
_LDVT = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDVT, _cache, _env ,&_cache);
_WORK = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_WORK, _cache, _env ,&_cache);
_LWORK = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LWORK, _cache, _env ,&_cache);
_A = omc_Lapack_dgesvd(threadData, _JOBU, _JOBVT, _M, _N, _A, _LDA, _LDU, _LDVT, _WORK, _LWORK ,&_S ,&_U ,&_VT ,&_WORK ,&_INFO);
_val_A = omc_ValuesUtil_makeRealMatrix(threadData, _A);
_val_S = omc_ValuesUtil_makeRealArray(threadData, _S);
_val_U = omc_ValuesUtil_makeRealMatrix(threadData, _U);
_val_VT = omc_ValuesUtil_makeRealMatrix(threadData, _VT);
_val_WORK = omc_ValuesUtil_makeRealArray(threadData, _WORK);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta292 = mmc_mk_cons(_arg_A, mmc_mk_cons(_arg_S, mmc_mk_cons(_arg_U, mmc_mk_cons(_arg_VT, mmc_mk_cons(_arg_WORK, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil)))))));
_arg_out = tmpMeta292;
tmpMeta293 = mmc_mk_cons(_val_A, mmc_mk_cons(_val_S, mmc_mk_cons(_val_U, mmc_mk_cons(_val_VT, mmc_mk_cons(_val_WORK, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil)))))));
_val_out = tmpMeta293;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta294;
modelica_metatype tmpMeta295;
modelica_metatype tmpMeta296;
modelica_metatype tmpMeta297;
modelica_metatype tmpMeta298;
modelica_metatype tmpMeta299;
modelica_metatype tmpMeta300;
modelica_metatype tmpMeta301;
modelica_metatype tmpMeta302;
modelica_metatype tmpMeta303;
modelica_metatype tmpMeta304;
modelica_metatype tmpMeta305;
modelica_metatype tmpMeta306;
modelica_metatype tmpMeta307;
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT84), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta294 = MMC_CAR(tmp4_2);
tmpMeta295 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta295)) goto tmp3_end;
tmpMeta296 = MMC_CAR(tmpMeta295);
tmpMeta297 = MMC_CDR(tmpMeta295);
if (listEmpty(tmpMeta297)) goto tmp3_end;
tmpMeta298 = MMC_CAR(tmpMeta297);
tmpMeta299 = MMC_CDR(tmpMeta297);
if (listEmpty(tmpMeta299)) goto tmp3_end;
tmpMeta300 = MMC_CAR(tmpMeta299);
tmpMeta301 = MMC_CDR(tmpMeta299);
if (listEmpty(tmpMeta301)) goto tmp3_end;
tmpMeta302 = MMC_CAR(tmpMeta301);
tmpMeta303 = MMC_CDR(tmpMeta301);
if (listEmpty(tmpMeta303)) goto tmp3_end;
tmpMeta304 = MMC_CAR(tmpMeta303);
tmpMeta305 = MMC_CDR(tmpMeta303);
if (!listEmpty(tmpMeta305)) goto tmp3_end;
_arg_M = tmpMeta294;
_arg_N = tmpMeta296;
_arg_A = tmpMeta298;
_arg_LDA = tmpMeta300;
_arg_IPIV = tmpMeta302;
_arg_INFO = tmpMeta304;
_cache = tmp4_3;
_env = tmp4_4;
_M = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_M, _cache, _env ,&_cache);
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_A = omc_Lapack_dgetrf(threadData, _M, _N, _A, _LDA ,&_IPIV ,&_INFO);
_val_A = omc_ValuesUtil_makeRealMatrix(threadData, _A);
_val_IPIV = omc_ValuesUtil_makeIntArray(threadData, _IPIV);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta306 = mmc_mk_cons(_arg_A, mmc_mk_cons(_arg_IPIV, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil))));
_arg_out = tmpMeta306;
tmpMeta307 = mmc_mk_cons(_val_A, mmc_mk_cons(_val_IPIV, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil))));
_val_out = tmpMeta307;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta308;
modelica_metatype tmpMeta309;
modelica_metatype tmpMeta310;
modelica_metatype tmpMeta311;
modelica_metatype tmpMeta312;
modelica_metatype tmpMeta313;
modelica_metatype tmpMeta314;
modelica_metatype tmpMeta315;
modelica_metatype tmpMeta316;
modelica_metatype tmpMeta317;
modelica_metatype tmpMeta318;
modelica_metatype tmpMeta319;
modelica_metatype tmpMeta320;
modelica_metatype tmpMeta321;
modelica_metatype tmpMeta322;
modelica_metatype tmpMeta323;
modelica_metatype tmpMeta324;
modelica_metatype tmpMeta325;
modelica_metatype tmpMeta326;
modelica_metatype tmpMeta327;
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT85), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta308 = MMC_CAR(tmp4_2);
tmpMeta309 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta309)) goto tmp3_end;
tmpMeta310 = MMC_CAR(tmpMeta309);
tmpMeta311 = MMC_CDR(tmpMeta309);
if (listEmpty(tmpMeta311)) goto tmp3_end;
tmpMeta312 = MMC_CAR(tmpMeta311);
tmpMeta313 = MMC_CDR(tmpMeta311);
if (listEmpty(tmpMeta313)) goto tmp3_end;
tmpMeta314 = MMC_CAR(tmpMeta313);
tmpMeta315 = MMC_CDR(tmpMeta313);
if (listEmpty(tmpMeta315)) goto tmp3_end;
tmpMeta316 = MMC_CAR(tmpMeta315);
tmpMeta317 = MMC_CDR(tmpMeta315);
if (listEmpty(tmpMeta317)) goto tmp3_end;
tmpMeta318 = MMC_CAR(tmpMeta317);
tmpMeta319 = MMC_CDR(tmpMeta317);
if (listEmpty(tmpMeta319)) goto tmp3_end;
tmpMeta320 = MMC_CAR(tmpMeta319);
tmpMeta321 = MMC_CDR(tmpMeta319);
if (listEmpty(tmpMeta321)) goto tmp3_end;
tmpMeta322 = MMC_CAR(tmpMeta321);
tmpMeta323 = MMC_CDR(tmpMeta321);
if (listEmpty(tmpMeta323)) goto tmp3_end;
tmpMeta324 = MMC_CAR(tmpMeta323);
tmpMeta325 = MMC_CDR(tmpMeta323);
if (!listEmpty(tmpMeta325)) goto tmp3_end;
_arg_TRANS = tmpMeta308;
_arg_N = tmpMeta310;
_arg_NRHS = tmpMeta312;
_arg_A = tmpMeta314;
_arg_LDA = tmpMeta316;
_arg_IPIV = tmpMeta318;
_arg_B = tmpMeta320;
_arg_LDB = tmpMeta322;
_arg_INFO = tmpMeta324;
_cache = tmp4_3;
_env = tmp4_4;
_TRANS = omc_CevalFunction_evaluateExtStringArg(threadData, _arg_TRANS, _cache, _env ,&_cache);
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_NRHS = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_NRHS, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_IPIV = omc_CevalFunction_evaluateExtIntArrayArg(threadData, _arg_IPIV, _cache, _env ,&_cache);
_B = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_B, _cache, _env ,&_cache);
_LDB = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDB, _cache, _env ,&_cache);
_B = omc_Lapack_dgetrs(threadData, _TRANS, _N, _NRHS, _A, _LDA, _IPIV, _B, _LDB ,&_INFO);
_val_B = omc_ValuesUtil_makeRealMatrix(threadData, _B);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta326 = mmc_mk_cons(_arg_B, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil)));
_arg_out = tmpMeta326;
tmpMeta327 = mmc_mk_cons(_val_B, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil)));
_val_out = tmpMeta327;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta328;
modelica_metatype tmpMeta329;
modelica_metatype tmpMeta330;
modelica_metatype tmpMeta331;
modelica_metatype tmpMeta332;
modelica_metatype tmpMeta333;
modelica_metatype tmpMeta334;
modelica_metatype tmpMeta335;
modelica_metatype tmpMeta336;
modelica_metatype tmpMeta337;
modelica_metatype tmpMeta338;
modelica_metatype tmpMeta339;
modelica_metatype tmpMeta340;
modelica_metatype tmpMeta341;
modelica_metatype tmpMeta342;
modelica_metatype tmpMeta343;
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT86), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta328 = MMC_CAR(tmp4_2);
tmpMeta329 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta329)) goto tmp3_end;
tmpMeta330 = MMC_CAR(tmpMeta329);
tmpMeta331 = MMC_CDR(tmpMeta329);
if (listEmpty(tmpMeta331)) goto tmp3_end;
tmpMeta332 = MMC_CAR(tmpMeta331);
tmpMeta333 = MMC_CDR(tmpMeta331);
if (listEmpty(tmpMeta333)) goto tmp3_end;
tmpMeta334 = MMC_CAR(tmpMeta333);
tmpMeta335 = MMC_CDR(tmpMeta333);
if (listEmpty(tmpMeta335)) goto tmp3_end;
tmpMeta336 = MMC_CAR(tmpMeta335);
tmpMeta337 = MMC_CDR(tmpMeta335);
if (listEmpty(tmpMeta337)) goto tmp3_end;
tmpMeta338 = MMC_CAR(tmpMeta337);
tmpMeta339 = MMC_CDR(tmpMeta337);
if (listEmpty(tmpMeta339)) goto tmp3_end;
tmpMeta340 = MMC_CAR(tmpMeta339);
tmpMeta341 = MMC_CDR(tmpMeta339);
if (!listEmpty(tmpMeta341)) goto tmp3_end;
_arg_N = tmpMeta328;
_arg_A = tmpMeta330;
_arg_LDA = tmpMeta332;
_arg_IPIV = tmpMeta334;
_arg_WORK = tmpMeta336;
_arg_LWORK = tmpMeta338;
_arg_INFO = tmpMeta340;
_cache = tmp4_3;
_env = tmp4_4;
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_IPIV = omc_CevalFunction_evaluateExtIntArrayArg(threadData, _arg_IPIV, _cache, _env ,&_cache);
_WORK = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_WORK, _cache, _env ,&_cache);
_LWORK = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LWORK, _cache, _env ,&_cache);
_A = omc_Lapack_dgetri(threadData, _N, _A, _LDA, _IPIV, _WORK, _LWORK ,&_WORK ,&_INFO);
_val_A = omc_ValuesUtil_makeRealMatrix(threadData, _A);
_val_WORK = omc_ValuesUtil_makeRealArray(threadData, _WORK);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta342 = mmc_mk_cons(_arg_A, mmc_mk_cons(_arg_WORK, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil))));
_arg_out = tmpMeta342;
tmpMeta343 = mmc_mk_cons(_val_A, mmc_mk_cons(_val_WORK, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil))));
_val_out = tmpMeta343;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta344;
modelica_metatype tmpMeta345;
modelica_metatype tmpMeta346;
modelica_metatype tmpMeta347;
modelica_metatype tmpMeta348;
modelica_metatype tmpMeta349;
modelica_metatype tmpMeta350;
modelica_metatype tmpMeta351;
modelica_metatype tmpMeta352;
modelica_metatype tmpMeta353;
modelica_metatype tmpMeta354;
modelica_metatype tmpMeta355;
modelica_metatype tmpMeta356;
modelica_metatype tmpMeta357;
modelica_metatype tmpMeta358;
modelica_metatype tmpMeta359;
modelica_metatype tmpMeta360;
modelica_metatype tmpMeta361;
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT87), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta344 = MMC_CAR(tmp4_2);
tmpMeta345 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta345)) goto tmp3_end;
tmpMeta346 = MMC_CAR(tmpMeta345);
tmpMeta347 = MMC_CDR(tmpMeta345);
if (listEmpty(tmpMeta347)) goto tmp3_end;
tmpMeta348 = MMC_CAR(tmpMeta347);
tmpMeta349 = MMC_CDR(tmpMeta347);
if (listEmpty(tmpMeta349)) goto tmp3_end;
tmpMeta350 = MMC_CAR(tmpMeta349);
tmpMeta351 = MMC_CDR(tmpMeta349);
if (listEmpty(tmpMeta351)) goto tmp3_end;
tmpMeta352 = MMC_CAR(tmpMeta351);
tmpMeta353 = MMC_CDR(tmpMeta351);
if (listEmpty(tmpMeta353)) goto tmp3_end;
tmpMeta354 = MMC_CAR(tmpMeta353);
tmpMeta355 = MMC_CDR(tmpMeta353);
if (listEmpty(tmpMeta355)) goto tmp3_end;
tmpMeta356 = MMC_CAR(tmpMeta355);
tmpMeta357 = MMC_CDR(tmpMeta355);
if (listEmpty(tmpMeta357)) goto tmp3_end;
tmpMeta358 = MMC_CAR(tmpMeta357);
tmpMeta359 = MMC_CDR(tmpMeta357);
if (!listEmpty(tmpMeta359)) goto tmp3_end;
_arg_M = tmpMeta344;
_arg_N = tmpMeta346;
_arg_A = tmpMeta348;
_arg_LDA = tmpMeta350;
_arg_JPVT = tmpMeta352;
_arg_TAU = tmpMeta354;
_arg_WORK = tmpMeta356;
_arg_INFO = tmpMeta358;
_cache = tmp4_3;
_env = tmp4_4;
_M = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_M, _cache, _env ,&_cache);
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_JPVT = omc_CevalFunction_evaluateExtIntArrayArg(threadData, _arg_JPVT, _cache, _env ,&_cache);
_WORK = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_WORK, _cache, _env ,&_cache);
_A = omc_Lapack_dgeqpf(threadData, _M, _N, _A, _LDA, _JPVT, _WORK ,&_JPVT ,&_TAU ,&_INFO);
_val_A = omc_ValuesUtil_makeRealMatrix(threadData, _A);
_val_JPVT = omc_ValuesUtil_makeIntArray(threadData, _JPVT);
_val_TAU = omc_ValuesUtil_makeRealArray(threadData, _TAU);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta360 = mmc_mk_cons(_arg_A, mmc_mk_cons(_arg_JPVT, mmc_mk_cons(_arg_TAU, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil)))));
_arg_out = tmpMeta360;
tmpMeta361 = mmc_mk_cons(_val_A, mmc_mk_cons(_val_JPVT, mmc_mk_cons(_val_TAU, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil)))));
_val_out = tmpMeta361;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta362;
modelica_metatype tmpMeta363;
modelica_metatype tmpMeta364;
modelica_metatype tmpMeta365;
modelica_metatype tmpMeta366;
modelica_metatype tmpMeta367;
modelica_metatype tmpMeta368;
modelica_metatype tmpMeta369;
modelica_metatype tmpMeta370;
modelica_metatype tmpMeta371;
modelica_metatype tmpMeta372;
modelica_metatype tmpMeta373;
modelica_metatype tmpMeta374;
modelica_metatype tmpMeta375;
modelica_metatype tmpMeta376;
modelica_metatype tmpMeta377;
modelica_metatype tmpMeta378;
modelica_metatype tmpMeta379;
modelica_metatype tmpMeta380;
modelica_metatype tmpMeta381;
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT88), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta362 = MMC_CAR(tmp4_2);
tmpMeta363 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta363)) goto tmp3_end;
tmpMeta364 = MMC_CAR(tmpMeta363);
tmpMeta365 = MMC_CDR(tmpMeta363);
if (listEmpty(tmpMeta365)) goto tmp3_end;
tmpMeta366 = MMC_CAR(tmpMeta365);
tmpMeta367 = MMC_CDR(tmpMeta365);
if (listEmpty(tmpMeta367)) goto tmp3_end;
tmpMeta368 = MMC_CAR(tmpMeta367);
tmpMeta369 = MMC_CDR(tmpMeta367);
if (listEmpty(tmpMeta369)) goto tmp3_end;
tmpMeta370 = MMC_CAR(tmpMeta369);
tmpMeta371 = MMC_CDR(tmpMeta369);
if (listEmpty(tmpMeta371)) goto tmp3_end;
tmpMeta372 = MMC_CAR(tmpMeta371);
tmpMeta373 = MMC_CDR(tmpMeta371);
if (listEmpty(tmpMeta373)) goto tmp3_end;
tmpMeta374 = MMC_CAR(tmpMeta373);
tmpMeta375 = MMC_CDR(tmpMeta373);
if (listEmpty(tmpMeta375)) goto tmp3_end;
tmpMeta376 = MMC_CAR(tmpMeta375);
tmpMeta377 = MMC_CDR(tmpMeta375);
if (listEmpty(tmpMeta377)) goto tmp3_end;
tmpMeta378 = MMC_CAR(tmpMeta377);
tmpMeta379 = MMC_CDR(tmpMeta377);
if (!listEmpty(tmpMeta379)) goto tmp3_end;
_arg_M = tmpMeta362;
_arg_N = tmpMeta364;
_arg_K = tmpMeta366;
_arg_A = tmpMeta368;
_arg_LDA = tmpMeta370;
_arg_TAU = tmpMeta372;
_arg_WORK = tmpMeta374;
_arg_LWORK = tmpMeta376;
_arg_INFO = tmpMeta378;
_cache = tmp4_3;
_env = tmp4_4;
_M = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_M, _cache, _env ,&_cache);
_N = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_N, _cache, _env ,&_cache);
_K = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_K, _cache, _env ,&_cache);
_A = omc_CevalFunction_evaluateExtRealMatrixArg(threadData, _arg_A, _cache, _env ,&_cache);
_LDA = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LDA, _cache, _env ,&_cache);
_TAU = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_TAU, _cache, _env ,&_cache);
_WORK = omc_CevalFunction_evaluateExtRealArrayArg(threadData, _arg_WORK, _cache, _env ,&_cache);
_LWORK = omc_CevalFunction_evaluateExtIntArg(threadData, _arg_LWORK, _cache, _env ,&_cache);
_A = omc_Lapack_dorgqr(threadData, _M, _N, _K, _A, _LDA, _TAU, _WORK, _LWORK ,&_WORK ,&_INFO);
_val_A = omc_ValuesUtil_makeRealMatrix(threadData, _A);
_val_WORK = omc_ValuesUtil_makeRealArray(threadData, _WORK);
_val_INFO = omc_ValuesUtil_makeInteger(threadData, _INFO);
tmpMeta380 = mmc_mk_cons(_arg_A, mmc_mk_cons(_arg_WORK, mmc_mk_cons(_arg_INFO, MMC_REFSTRUCTLIT(mmc_nil))));
_arg_out = tmpMeta380;
tmpMeta381 = mmc_mk_cons(_val_A, mmc_mk_cons(_val_WORK, mmc_mk_cons(_val_INFO, MMC_REFSTRUCTLIT(mmc_nil))));
_val_out = tmpMeta381;
tmpMeta[0+0] = omc_CevalFunction_assignExtOutputs(threadData, _arg_out, _val_out, _cache, _env, &tmpMeta[0+1]);
goto tmp3_done;
}
}
goto tmp3_end;
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
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_unliftExtOutputValue(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inValue, modelica_metatype _inEnv)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inValue;
{
modelica_metatype _ty = NULL;
modelica_metatype _vals = NULL;
modelica_integer _dim;
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
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_integer tmp12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_boolean tmp16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,5,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
tmp12 = mmc_unbox_integer(tmpMeta10);
_vals = tmpMeta6;
_dim = tmp12;
tmpMeta13 = omc_CevalFunction_getVariableTypeAndBinding(threadData, _inCref, _inEnv, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,6,2) == 0) goto goto_2;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
_ty = tmpMeta14;
_dims = tmpMeta15;
tmp16 = omc_Types_isNonscalarArray(threadData, _ty, _dims);
if (0 != tmp16) goto goto_2;
_vals = omc_List_map(threadData, _vals, boxvar_ValuesUtil_arrayScalar);
tmpMeta17 = mmc_mk_cons(mmc_mk_integer(_dim), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta18 = mmc_mk_box3(8, &Values_Value_ARRAY__desc, _vals, tmpMeta17);
tmpMeta1 = tmpMeta18;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inValue;
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
_outValue = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_assignExtOutputs(threadData_t *threadData, modelica_metatype _inArgs, modelica_metatype _inValues, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outEnv)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outEnv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _inArgs;
tmp4_2 = _inValues;
tmp4_3 = _inCache;
tmp4_4 = _inEnv;
{
modelica_metatype _arg = NULL;
modelica_metatype _val = NULL;
modelica_metatype _rest_args = NULL;
modelica_metatype _rest_vals = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[0+0] = _inCache;
tmpMeta[0+1] = _inEnv;
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
_arg = tmpMeta6;
_rest_args = tmpMeta7;
_val = tmpMeta8;
_rest_vals = tmpMeta9;
_cache = tmp4_3;
_env = tmp4_4;
_cr = omc_CevalFunction_evaluateExtOutputArg(threadData, _arg);
_val = omc_CevalFunction_unliftExtOutputValue(threadData, _cr, _val, _env);
_cache = omc_CevalFunction_assignVariable(threadData, _cr, _val, _cache, _env ,&_env);
_inArgs = _rest_args;
_inValues = _rest_vals;
_inCache = _cache;
_inEnv = _env;
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
_outCache = tmpMeta[0+0];
_outEnv = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outEnv) { *out_outEnv = _outEnv; }
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateExtOutputArg(threadData_t *threadData, modelica_metatype _inArg)
{
modelica_metatype _outCref = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inArg;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,0,3) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
_outCref = tmpMeta2;
_return: OMC_LABEL_UNUSED
return _outCref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateExtRealMatrixArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache)
{
modelica_metatype _outValue = NULL;
modelica_metatype _outCache = NULL;
modelica_metatype _val = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_val = omc_CevalFunction_evaluateExtInputArg(threadData, _inArg, _inCache, _inEnv ,&_outCache);
_outValue = omc_ValuesUtil_matrixValueReals(threadData, _val);
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateExtRealArrayArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache)
{
modelica_metatype _outValue = NULL;
modelica_metatype _outCache = NULL;
modelica_metatype _val = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_val = omc_CevalFunction_evaluateExtInputArg(threadData, _inArg, _inCache, _inEnv ,&_outCache);
_outValue = omc_ValuesUtil_arrayValueReals(threadData, _val);
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateExtIntArrayArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache)
{
modelica_metatype _outValue = NULL;
modelica_metatype _outCache = NULL;
modelica_metatype _val = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_val = omc_CevalFunction_evaluateExtInputArg(threadData, _inArg, _inCache, _inEnv ,&_outCache);
_outValue = omc_ValuesUtil_arrayValueInts(threadData, _val);
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_CevalFunction_evaluateExtStringArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache)
{
modelica_string _outValue = NULL;
modelica_metatype _outCache = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta2 = omc_CevalFunction_evaluateExtInputArg(threadData, _inArg, _inCache, _inEnv, &tmpMeta1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,2,1) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
_outValue = tmpMeta3;
_outCache = tmpMeta1;
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_real omc_CevalFunction_evaluateExtRealArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache)
{
modelica_real _outValue;
modelica_metatype _outCache = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_real tmp4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta2 = omc_CevalFunction_evaluateExtInputArg(threadData, _inArg, _inCache, _inEnv, &tmpMeta1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,1,1) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
tmp4 = mmc_unbox_real(tmpMeta3);
_outValue = tmp4;
_outCache = tmpMeta1;
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_evaluateExtRealArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache)
{
modelica_real _outValue;
modelica_metatype out_outValue;
_outValue = omc_CevalFunction_evaluateExtRealArg(threadData, _inArg, _inCache, _inEnv, out_outCache);
out_outValue = mmc_mk_rcon(_outValue);
return out_outValue;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_CevalFunction_evaluateExtIntArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache)
{
modelica_integer _outValue;
modelica_metatype _outCache = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta2 = omc_CevalFunction_evaluateExtInputArg(threadData, _inArg, _inCache, _inEnv, &tmpMeta1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta2,0,1) == 0) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta2), 2));
tmp4 = mmc_unbox_integer(tmpMeta3);
_outValue = tmp4;
_outCache = tmpMeta1;
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_evaluateExtIntArg(threadData_t *threadData, modelica_metatype _inArg, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache)
{
modelica_integer _outValue;
modelica_metatype out_outValue;
_outValue = omc_CevalFunction_evaluateExtIntArg(threadData, _inArg, _inCache, _inEnv, out_outCache);
out_outValue = mmc_mk_icon(_outValue);
return out_outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateExtInputArg(threadData_t *threadData, modelica_metatype _inArgument, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype *out_outCache)
{
modelica_metatype _outValue = NULL;
modelica_metatype _outCache = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inArgument;
tmp4_2 = _inCache;
{
modelica_metatype _cref = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _val = NULL;
modelica_metatype _cache = NULL;
modelica_string _err_str = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cref = tmpMeta6;
_ty = tmpMeta7;
tmp4 += 2;
_val = omc_CevalFunction_getVariableValue(threadData, _cref, _ty, _inEnv);
tmpMeta[0+0] = _val;
tmpMeta[0+1] = _inCache;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta8;
_cache = tmp4_2;
tmp4 += 1;
_cache = omc_CevalFunction_cevalExp(threadData, _exp, _cache, _inEnv ,&_val);
tmpMeta[0+0] = _val;
tmpMeta[0+1] = _cache;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cref = tmpMeta9;
_exp = tmpMeta10;
_cache = tmp4_2;
tmpMeta11 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, _cref, _OMC_LIT89);
tmpMeta12 = mmc_mk_box3(27, &DAE_Exp_SIZE__desc, tmpMeta11, mmc_mk_some(_exp));
_exp = tmpMeta12;
_cache = omc_CevalFunction_cevalExp(threadData, _exp, _cache, _inEnv ,&_val);
tmpMeta[0+0] = _val;
tmpMeta[0+1] = _cache;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp13;
modelica_metatype tmpMeta14;
tmp13 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (1 != tmp13) goto goto_2;
_err_str = omc_DAEDump_dumpExtArgStr(threadData, _inArgument);
tmpMeta14 = stringAppend(_OMC_LIT90,_err_str);
omc_Debug_traceln(threadData, tmpMeta14);
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
_outValue = tmpMeta[0+0];
_outCache = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outCache) { *out_outCache = _outCache; }
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_CevalFunction_isCrefNamed(threadData_t *threadData, modelica_string _inName, modelica_metatype _inCref)
{
modelica_boolean _outIsNamed;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
modelica_string _name = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_name = tmpMeta6;
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_CevalFunction_isCrefNamed(threadData_t *threadData, modelica_metatype _inName, modelica_metatype _inCref)
{
modelica_boolean _outIsNamed;
modelica_metatype out_outIsNamed;
_outIsNamed = omc_CevalFunction_isCrefNamed(threadData, _inName, _inCref);
out_outIsNamed = mmc_mk_icon(_outIsNamed);
return out_outIsNamed;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_removeSelfReferentialDim(threadData_t *threadData, modelica_metatype _inDim, modelica_string _inName)
{
modelica_metatype _outDim = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inDim;
{
modelica_metatype _exp = NULL;
modelica_metatype _crefs = NULL;
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
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exp = tmpMeta6;
_crefs = omc_Expression_extractCrefsFromExp(threadData, _exp);
tmp7 = omc_List_isMemberOnTrue(threadData, _inName, _crefs, boxvar_CevalFunction_isCrefNamed);
if (1 != tmp7) goto goto_2;
tmpMeta1 = _OMC_LIT91;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inDim;
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
_outDim = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDim;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_removeSelfReferentialDims(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElement;
{
modelica_metatype _cref = NULL;
modelica_metatype _vk = NULL;
modelica_metatype _vd = NULL;
modelica_metatype _vp = NULL;
modelica_metatype _vv = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _bind = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _es = NULL;
modelica_metatype _va = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _io = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 10));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 11));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 12));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 13));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 14));
_cref = tmpMeta6;
_name = tmpMeta7;
_vk = tmpMeta8;
_vd = tmpMeta9;
_vp = tmpMeta10;
_vv = tmpMeta11;
_ty = tmpMeta12;
_bind = tmpMeta13;
_dims = tmpMeta14;
_ct = tmpMeta15;
_es = tmpMeta16;
_va = tmpMeta17;
_cmt = tmpMeta18;
_io = tmpMeta19;
_dims = omc_List_map1(threadData, _dims, boxvar_CevalFunction_removeSelfReferentialDim, _name);
tmpMeta20 = mmc_mk_box14(3, &DAE_Element_VAR__desc, _cref, _vk, _vd, _vp, _vv, _ty, _bind, _dims, _ct, _es, _va, _cmt, _io);
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_pairFuncParamsWithArgs(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inValues)
{
modelica_metatype _outFunctionVars = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inElements;
tmp4_2 = _inValues;
{
modelica_metatype _var = NULL;
modelica_metatype _rest_vars = NULL;
modelica_metatype _val = NULL;
modelica_metatype _rest_vals = NULL;
modelica_metatype _params = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
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
modelica_boolean tmp10;
if (!listEmpty(tmp4_2)) goto tmp3_end;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,0,13) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,0,0) == 0) goto tmp3_end;
tmp10 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (1 != tmp10) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT92);
goto goto_2;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmp4_2);
tmpMeta12 = MMC_CDR(tmp4_2);
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,13) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,0,0) == 0) goto tmp3_end;
_val = tmpMeta11;
_rest_vals = tmpMeta12;
_var = tmpMeta13;
_rest_vars = tmpMeta14;
_params = omc_CevalFunction_pairFuncParamsWithArgs(threadData, _rest_vars, _rest_vals);
tmpMeta17 = mmc_mk_box2(0, _var, mmc_mk_some(_val));
tmpMeta16 = mmc_mk_cons(tmpMeta17, _params);
tmpMeta1 = tmpMeta16;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmp4_1);
tmpMeta19 = MMC_CDR(tmp4_1);
_var = tmpMeta18;
_rest_vars = tmpMeta19;
_params = omc_CevalFunction_pairFuncParamsWithArgs(threadData, _rest_vars, _inValues);
tmpMeta21 = mmc_mk_box2(0, _var, mmc_mk_none());
tmpMeta20 = mmc_mk_cons(tmpMeta21, _params);
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outFunctionVars = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outFunctionVars;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_CevalFunction_evaluateFunctionDefinition(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_string _inFuncName, modelica_metatype _inFunc, modelica_metatype _inFuncType, modelica_metatype _inFuncArgs, modelica_metatype _inSource, modelica_metatype *out_outResult)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outResult = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inFunc;
{
modelica_metatype _body = NULL;
modelica_metatype _vars = NULL;
modelica_metatype _output_vars = NULL;
modelica_metatype _func_params = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _return_values = NULL;
modelica_metatype _return_value = NULL;
modelica_string _ext_fun_name = NULL;
modelica_metatype _ext_fun_args = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_body = tmpMeta6;
tmp4 += 1;
_vars = omc_List_splitOnFirstMatch(threadData, _body, boxvar_DAEUtil_isNotVar ,&_body);
_vars = omc_List_map(threadData, _vars, boxvar_CevalFunction_removeSelfReferentialDims);
_output_vars = omc_List_filterOnTrue(threadData, _vars, boxvar_DAEUtil_isOutputVar);
_func_params = omc_CevalFunction_pairFuncParamsWithArgs(threadData, _vars, _inFuncArgs);
_func_params = omc_CevalFunction_sortFunctionVarsByDependency(threadData, _func_params, _inSource);
_cache = omc_CevalFunction_setupFunctionEnvironment(threadData, _inCache, _inEnv, _inFuncName, _func_params ,&_env);
_cache = omc_CevalFunction_evaluateElements(threadData, _body, _cache, _env, _OMC_LIT69 ,&_env ,NULL);
_return_values = omc_List_map1(threadData, _output_vars, boxvar_CevalFunction_getFunctionReturnValue, _env);
_return_value = omc_CevalFunction_boxReturnValue(threadData, _return_values);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _return_value;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
_body = tmpMeta7;
_ext_fun_name = tmpMeta9;
_ext_fun_args = tmpMeta10;
_vars = omc_List_splitOnFirstMatch(threadData, _body, boxvar_DAEUtil_isNotVar, NULL);
_vars = omc_List_map(threadData, _vars, boxvar_CevalFunction_removeSelfReferentialDims);
_output_vars = omc_List_filterOnTrue(threadData, _vars, boxvar_DAEUtil_isOutputVar);
_func_params = omc_CevalFunction_pairFuncParamsWithArgs(threadData, _vars, _inFuncArgs);
_func_params = omc_CevalFunction_sortFunctionVarsByDependency(threadData, _func_params, _inSource);
_cache = omc_CevalFunction_setupFunctionEnvironment(threadData, _inCache, _inEnv, _inFuncName, _func_params ,&_env);
_cache = omc_CevalFunction_evaluateExternalFunc(threadData, _ext_fun_name, _ext_fun_args, _cache, _env ,&_env);
_return_values = omc_List_map1(threadData, _output_vars, boxvar_CevalFunction_getFunctionReturnValue, _env);
_return_value = omc_CevalFunction_boxReturnValue(threadData, _return_values);
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = _return_value;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp11;
tmp11 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (1 != tmp11) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT93);
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
_outCache = tmpMeta[0+0];
_outResult = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outResult) { *out_outResult = _outResult; }
return _outCache;
}
DLLExport
modelica_metatype omc_CevalFunction_evaluate(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inFunction, modelica_metatype _inFunctionArguments, modelica_metatype *out_outResult)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outResult = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inFunction;
{
modelica_metatype _p = NULL;
modelica_metatype _func = NULL;
modelica_metatype _ty = NULL;
modelica_string _func_name = NULL;
modelica_boolean _partialPrefix;
modelica_metatype _src = NULL;
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
modelica_integer tmp12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,10) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmp12 = mmc_unbox_integer(tmpMeta11);
if (0 != tmp12) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 10));
_p = tmpMeta6;
_func = tmpMeta8;
_ty = tmpMeta10;
_src = tmpMeta13;
_func_name = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT94, 1, 0);
tmpMeta[0+0] = omc_CevalFunction_evaluateFunctionDefinition(threadData, _inCache, _inEnv, _func_name, _func, _ty, _inFunctionArguments, _src, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_integer tmp19;
modelica_boolean tmp20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,10) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta15)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmpMeta15);
tmpMeta17 = MMC_CDR(tmpMeta15);
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmp19 = mmc_unbox_integer(tmpMeta18);
_p = tmpMeta14;
_partialPrefix = tmp19;
tmp20 = omc_Flags_isSet(threadData, _OMC_LIT19);
if (1 != tmp20) goto goto_2;
tmpMeta21 = stringAppend(_OMC_LIT95,(_partialPrefix?_OMC_LIT96:_OMC_LIT4));
tmpMeta22 = stringAppend(tmpMeta21,omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT94, 1, 0));
omc_Debug_traceln(threadData, tmpMeta22);
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
_outCache = tmpMeta[0+0];
_outResult = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outResult) { *out_outResult = _outResult; }
return _outCache;
}
