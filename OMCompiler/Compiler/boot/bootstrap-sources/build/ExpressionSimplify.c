#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "ExpressionSimplify.c"
#endif
#include "omc_simulation_settings.h"
#include "ExpressionSimplify.h"
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT0,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT0 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT0)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT1,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT1 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,17,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT3}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data "ExpressionSimplify.simplifyAddSymbolicOperation failed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,54,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,2,1) {_OMC_LIT5,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "min"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,3,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "max"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,3,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "array"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,5,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT10,1,18) {&Values_Value_META__FAIL__desc,}};
#define _OMC_LIT10 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT10)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT11,1,3) {&Absyn_ReductionIterType_COMBINE__desc,}};
#define _OMC_LIT11 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data ":"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,1,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data "Step equals 0 in array constructor %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,38,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT13}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(152)),_OMC_LIT0,_OMC_LIT1,_OMC_LIT14}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,2,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,2,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT16}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,2,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT19,0.0);
#define _OMC_LIT19 MMC_REFREALLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,2,4) {&DAE_Exp_RCONST__desc,_OMC_LIT19}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "semiLinear"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,10,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,2,6) {&DAE_Exp_BCONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,2,6) {&DAE_Exp_BCONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "abs"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,3,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "exp"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,3,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT26,1.0);
#define _OMC_LIT26 MMC_REFREALLIT(_OMC_LIT_STRUCT26)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT27,2,4) {&DAE_Exp_RCONST__desc,_OMC_LIT26}};
#define _OMC_LIT27 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT28,2.0);
#define _OMC_LIT28 MMC_REFREALLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,2,4) {&DAE_Exp_RCONST__desc,_OMC_LIT28}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT30,2,4) {&DAE_Type_T__REAL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT30 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,2,6) {&DAE_Operator_DIV__desc,_OMC_LIT30}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT32,0.5);
#define _OMC_LIT32 MMC_REFREALLIT(_OMC_LIT_STRUCT32)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT33,2,4) {&DAE_Exp_RCONST__desc,_OMC_LIT32}};
#define _OMC_LIT33 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT33)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT34,2,5) {&DAE_Operator_MUL__desc,_OMC_LIT30}};
#define _OMC_LIT34 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data "sqrt"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,4,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT36,2,7) {&DAE_Operator_POW__desc,_OMC_LIT30}};
#define _OMC_LIT36 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT36)
#define _OMC_LIT37_data "tan"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT37,3,_OMC_LIT37_data);
#define _OMC_LIT37 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT37)
#define _OMC_LIT38_data "cos"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT38,3,_OMC_LIT38_data);
#define _OMC_LIT38 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "sin"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,3,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
#define _OMC_LIT40_data "tanh"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT40,4,_OMC_LIT40_data);
#define _OMC_LIT40 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT40)
#define _OMC_LIT41_data "cosh"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,4,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "sinh"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,4,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "sign"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,4,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT44,1.5);
#define _OMC_LIT44 MMC_REFREALLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,2,4) {&DAE_Exp_RCONST__desc,_OMC_LIT44}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT46,2,3) {&DAE_Operator_ADD__desc,_OMC_LIT30}};
#define _OMC_LIT46 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,2,29) {&DAE_Operator_LESSEQ__desc,_OMC_LIT30}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,2,28) {&DAE_Operator_LESS__desc,_OMC_LIT30}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,2,32) {&DAE_Operator_EQUAL__desc,_OMC_LIT30}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,1,5) {&ExpressionSimplifyTypes_IntOp_ADDOP__desc,}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,1,6) {&ExpressionSimplifyTypes_IntOp_SUBOP__desc,}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,1,3) {&ExpressionSimplifyTypes_IntOp_MULOP__desc,}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,1,4) {&ExpressionSimplifyTypes_IntOp_DIVOP__desc,}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,2,3) {&DAE_Type_T__INTEGER__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT55,2,5) {&DAE_Operator_MUL__desc,_OMC_LIT54}};
#define _OMC_LIT55 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT55)
#define _OMC_LIT56_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT56,9,_OMC_LIT56_data);
#define _OMC_LIT56 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT56)
#define _OMC_LIT57_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT57,41,_OMC_LIT57_data);
#define _OMC_LIT57 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT57)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT58,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT57}};
#define _OMC_LIT58 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT58)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT59,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT56,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT58}};
#define _OMC_LIT59 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "- ExpressionSimplify.simplifyAdd failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,40,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "der"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,3,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "pre"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,3,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "previous"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,8,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
#define _OMC_LIT64_data "edge"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT64,4,_OMC_LIT64_data);
#define _OMC_LIT64 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT64)
#define _OMC_LIT65_data "change"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT65,6,_OMC_LIT65_data);
#define _OMC_LIT65 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data "asin"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,4,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
#define _OMC_LIT67_data "acos"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT67,4,_OMC_LIT67_data);
#define _OMC_LIT67 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "log"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,3,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
#define _OMC_LIT69_data "log10"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT69,5,_OMC_LIT69_data);
#define _OMC_LIT69 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,0,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT71,2,5) {&DAE_Exp_SCONST__desc,_OMC_LIT70}};
#define _OMC_LIT71 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT71)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT72,2,5) {&DAE_Type_T__STRING__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT72 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT72)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT73,2,3) {&DAE_Operator_ADD__desc,_OMC_LIT72}};
#define _OMC_LIT73 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT73)
#define _OMC_LIT74_data "stringAppendList"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT74,16,_OMC_LIT74_data);
#define _OMC_LIT74 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT74)
#define _OMC_LIT75_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT75,1,_OMC_LIT75_data);
#define _OMC_LIT75 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT75)
#define _OMC_LIT76_data "true"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT76,4,_OMC_LIT76_data);
#define _OMC_LIT76 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT76)
#define _OMC_LIT77_data "false"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT77,5,_OMC_LIT77_data);
#define _OMC_LIT77 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data "ExpressionSimplify.evalCatGetFlatArray: Got unbalanced array from "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,66,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
#define _OMC_LIT79_data "ExpressionSimplify.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT79,21,_OMC_LIT79_data);
#define _OMC_LIT79 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT79)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT80_6,0.0);
#define _OMC_LIT80_6 MMC_REFREALLIT(_OMC_LIT_STRUCT80_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT80,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT79,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1788)),MMC_IMMEDIATE(MMC_TAGFIXNUM(7)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1788)),MMC_IMMEDIATE(MMC_TAGFIXNUM(109)),_OMC_LIT80_6}};
#define _OMC_LIT80 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data "ExpressionSimplify.evalCat: cat got uneven dimensions for dim="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,62,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,2,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT83_6,0.0);
#define _OMC_LIT83_6 MMC_REFREALLIT(_OMC_LIT_STRUCT83_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT83,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT79,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1727)),MMC_IMMEDIATE(MMC_TAGFIXNUM(7)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1727)),MMC_IMMEDIATE(MMC_TAGFIXNUM(180)),_OMC_LIT83_6}};
#define _OMC_LIT83 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT83)
#define _OMC_LIT84_data "scalar"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT84,6,_OMC_LIT84_data);
#define _OMC_LIT84 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT84)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT85,2,3) {&DAE_Exp_ICONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT85 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT85)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT86,1,1) {_OMC_LIT85}};
#define _OMC_LIT86 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT86)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT87,2,6) {&DAE_Type_T__BOOL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT87 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT87)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT88,2,25) {&DAE_Operator_AND__desc,_OMC_LIT87}};
#define _OMC_LIT88 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT88)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT89,2,26) {&DAE_Operator_OR__desc,_OMC_LIT87}};
#define _OMC_LIT89 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT89)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT90,1,3) {&DAE_Const_C__CONST__desc,}};
#define _OMC_LIT90 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT90)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT91,1,3) {&DAE_Prefix_NOPRE__desc,}};
#define _OMC_LIT91 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT91)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT92,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT70,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT19}};
#define _OMC_LIT92 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT92)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT93,0.25);
#define _OMC_LIT93 MMC_REFREALLIT(_OMC_LIT_STRUCT93)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT94,2,4) {&DAE_Exp_RCONST__desc,_OMC_LIT93}};
#define _OMC_LIT94 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT94)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT95,2,8) {&DAE_Operator_UMINUS__desc,_OMC_LIT30}};
#define _OMC_LIT95 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT95)
#define _OMC_LIT96_data "delay"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT96,5,_OMC_LIT96_data);
#define _OMC_LIT96 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT96)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT97,1,7) {&DAE_Dimension_DIM__UNKNOWN__desc,}};
#define _OMC_LIT97 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT97)
#define _OMC_LIT98_data "sum"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT98,3,_OMC_LIT98_data);
#define _OMC_LIT98 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT98)
#define _OMC_LIT99_data "cat"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT99,3,_OMC_LIT99_data);
#define _OMC_LIT99 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT99)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT100,2,3) {&DAE_Dimension_DIM__INTEGER__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT100 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT100)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT101,1,3) {&DAE_ClockKind_INFERRED__CLOCK__desc,}};
#define _OMC_LIT101 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT101)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT102,2,7) {&DAE_Exp_CLKCONST__desc,_OMC_LIT101}};
#define _OMC_LIT102 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT102)
#define _OMC_LIT103_data "OpenModelica_fmuLoadResource"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT103,28,_OMC_LIT103_data);
#define _OMC_LIT103 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT103)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT104,1,3) {&Flags_FlagVisibility_INTERNAL__desc,}};
#define _OMC_LIT104 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT104)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT105,2,4) {&Flags_FlagData_BOOL__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT105 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT105)
#define _OMC_LIT106_data "Is true when building an FMU (so the compiler can look for URIs to package as FMI resources)."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT106,93,_OMC_LIT106_data);
#define _OMC_LIT106 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT106)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT107,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT106}};
#define _OMC_LIT107 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT107)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT108,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(117)),_OMC_LIT70,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT104,_OMC_LIT105,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT107}};
#define _OMC_LIT108 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT108)
#define _OMC_LIT109_data "cross"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT109,5,_OMC_LIT109_data);
#define _OMC_LIT109 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT109)
#define _OMC_LIT110_data "skew"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT110,4,_OMC_LIT110_data);
#define _OMC_LIT110 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT110)
#define _OMC_LIT111_data "fill"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT111,4,_OMC_LIT111_data);
#define _OMC_LIT111 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT111)
#define _OMC_LIT112_data "String"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT112,6,_OMC_LIT112_data);
#define _OMC_LIT112 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT112)
#define _OMC_LIT113_data "smooth"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT113,6,_OMC_LIT113_data);
#define _OMC_LIT113 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT113)
#define _OMC_LIT114_data "$_DF$DER"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT114,8,_OMC_LIT114_data);
#define _OMC_LIT114 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT114)
#define _OMC_LIT115_data "promote"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT115,7,_OMC_LIT115_data);
#define _OMC_LIT115 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT115)
#define _OMC_LIT116_data "transpose"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT116,9,_OMC_LIT116_data);
#define _OMC_LIT116 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT116)
#define _OMC_LIT117_data "symmetric"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT117,9,_OMC_LIT117_data);
#define _OMC_LIT117 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT117)
#define _OMC_LIT118_data "vector"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT118,6,_OMC_LIT118_data);
#define _OMC_LIT118 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT118)
#define _OMC_LIT119_data "inferredClock"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT119,13,_OMC_LIT119_data);
#define _OMC_LIT119 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT119)
#define _OMC_LIT120_data "realClock"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT120,9,_OMC_LIT120_data);
#define _OMC_LIT120 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT120)
#define _OMC_LIT121_data "booleanClock"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT121,12,_OMC_LIT121_data);
#define _OMC_LIT121 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT121)
#define _OMC_LIT122_data "rationalClock"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT122,13,_OMC_LIT122_data);
#define _OMC_LIT122 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT122)
#define _OMC_LIT123_data "solverClock"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT123,11,_OMC_LIT123_data);
#define _OMC_LIT123 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT123)
#define _OMC_LIT124_data "OpenModelica_uriToFilename"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT124,26,_OMC_LIT124_data);
#define _OMC_LIT124 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT124)
#define _OMC_LIT125_data "product"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT125,7,_OMC_LIT125_data);
#define _OMC_LIT125 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT125)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT126,2,6) {&Values_Value_BOOL__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT126 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT126)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT127,2,6) {&Values_Value_BOOL__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT127 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT127)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT128,2,3) {&Values_Value_INTEGER__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT128 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT128)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT129,2,4) {&Values_Value_REAL__desc,_OMC_LIT26}};
#define _OMC_LIT129 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT129)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT130,2,3) {&Values_Value_INTEGER__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT130 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT130)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT131,2,4) {&Values_Value_REAL__desc,_OMC_LIT19}};
#define _OMC_LIT131 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT131)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT132,1,7) {&DAE_InlineType_NO__INLINE__desc,}};
#define _OMC_LIT132 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT132)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT133,1,3) {&DAE_TailCall_NO__TAIL__desc,}};
#define _OMC_LIT133 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT133)
#define _OMC_LIT134_data "listReverse"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT134,11,_OMC_LIT134_data);
#define _OMC_LIT134 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT134)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT135,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT134}};
#define _OMC_LIT135 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT135)
#define _OMC_LIT136_data "list"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT136,4,_OMC_LIT136_data);
#define _OMC_LIT136 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT136)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT137,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT136}};
#define _OMC_LIT137 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT137)
#define _OMC_LIT138_data "sourceInfo() - simplify?\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT138,25,_OMC_LIT138_data);
#define _OMC_LIT138 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT138)
#define _OMC_LIT139_data "listAppend"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT139,10,_OMC_LIT139_data);
#define _OMC_LIT139 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT139)
#define _OMC_LIT140_data "intString"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT140,9,_OMC_LIT140_data);
#define _OMC_LIT140 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT140)
#define _OMC_LIT141_data "realString"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT141,10,_OMC_LIT141_data);
#define _OMC_LIT141 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT141)
#define _OMC_LIT142_data "boolString"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT142,10,_OMC_LIT142_data);
#define _OMC_LIT142 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT142)
#define _OMC_LIT143_data "listLength"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT143,10,_OMC_LIT143_data);
#define _OMC_LIT143 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT143)
#define _OMC_LIT144_data "mmc_mk_some"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT144,11,_OMC_LIT144_data);
#define _OMC_LIT144 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT144)
#define _OMC_LIT145_data "sourceInfo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT145,10,_OMC_LIT145_data);
#define _OMC_LIT145 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT145)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT146,2,27) {&DAE_Operator_NOT__desc,_OMC_LIT87}};
#define _OMC_LIT146 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT146)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT147,2,31) {&DAE_Exp_LIST__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT147 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT147)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT148,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT148 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT148)
#define _OMC_LIT149_data "Expression simplification iterated to the fix-point maximum, which may be a performance bottleneck. The last two iterations were: %s, and %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT149,141,_OMC_LIT149_data);
#define _OMC_LIT149 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT149)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT150,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT149}};
#define _OMC_LIT150 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT150)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT151,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(209)),_OMC_LIT0,_OMC_LIT148,_OMC_LIT150}};
#define _OMC_LIT151 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT151)
#define _OMC_LIT152_data "ExpressionSimplify"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT152,18,_OMC_LIT152_data);
#define _OMC_LIT152 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT152)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT153,1,6) {&ErrorTypes_Severity_NOTIFICATION__desc,}};
#define _OMC_LIT153 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT153)
#define _OMC_LIT154_data "Expression simplification '%s' → '%s' changed the type from %s to %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT154,71,_OMC_LIT154_data);
#define _OMC_LIT154 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT154)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT155,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT154}};
#define _OMC_LIT155 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT155)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT156,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(273)),_OMC_LIT0,_OMC_LIT153,_OMC_LIT155}};
#define _OMC_LIT156 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT156)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT157,1,6) {&ErrorTypes_MessageType_SYMBOLIC__desc,}};
#define _OMC_LIT157 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT157)
#define _OMC_LIT158_data "Simplification produced a higher complexity (%s) than the original (%s). The simplification was: %s => %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT158,106,_OMC_LIT158_data);
#define _OMC_LIT158 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT158)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT159,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT158}};
#define _OMC_LIT159 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT159)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT160,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(523)),_OMC_LIT157,_OMC_LIT153,_OMC_LIT159}};
#define _OMC_LIT160 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT160)
#define _OMC_LIT161_data "checkSimplify"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT161,13,_OMC_LIT161_data);
#define _OMC_LIT161 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT161)
#define _OMC_LIT162_data "Enables checks for expression simplification and prints a notification whenever an undesirable transformation has been performed."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT162,129,_OMC_LIT162_data);
#define _OMC_LIT162 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT162)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT163,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT162}};
#define _OMC_LIT163 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT163)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT164,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(65)),_OMC_LIT161,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT163}};
#define _OMC_LIT164 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT164)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT165,1,3) {&ExpressionSimplifyTypes_Evaluate_NO__EVAL__desc,}};
#define _OMC_LIT165 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT165)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT166,2,0) {MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT165}};
#define _OMC_LIT166 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT166)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT167,2,1) {_OMC_LIT8,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT167 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT167)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT168,2,1) {_OMC_LIT7,_OMC_LIT167}};
#define _OMC_LIT168 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT168)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT169,2,1) {_OMC_LIT125,_OMC_LIT168}};
#define _OMC_LIT169 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT169)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT170,2,1) {_OMC_LIT98,_OMC_LIT169}};
#define _OMC_LIT170 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT170)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT171,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT61}};
#define _OMC_LIT171 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT171)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT172,2,3) {&DAE_Exp_ICONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT172 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT172)
#define _OMC_LIT173_data "atan"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT173,4,_OMC_LIT173_data);
#define _OMC_LIT173 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT173)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT174,2,4) {&DAE_Operator_SUB__desc,_OMC_LIT30}};
#define _OMC_LIT174 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT174)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT175,1.570796326794897);
#define _OMC_LIT175 MMC_REFREALLIT(_OMC_LIT_STRUCT175)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT176,2,4) {&DAE_Exp_RCONST__desc,_OMC_LIT175}};
#define _OMC_LIT176 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT176)
#define _OMC_LIT177_data "homotopy"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT177,8,_OMC_LIT177_data);
#define _OMC_LIT177 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT177)
#define _OMC_LIT178_data "noEvent"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT178,7,_OMC_LIT178_data);
#define _OMC_LIT178 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT178)
#define _OMC_LIT179_data "identity"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT179,8,_OMC_LIT179_data);
#define _OMC_LIT179 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT179)
#define _OMC_LIT180_data "diagonal"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT180,8,_OMC_LIT180_data);
#define _OMC_LIT180 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT180)
#define _OMC_LIT181_data "mod"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT181,3,_OMC_LIT181_data);
#define _OMC_LIT181 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT181)
#define _OMC_LIT182_data "integer"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT182,7,_OMC_LIT182_data);
#define _OMC_LIT182 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT182)
#define _OMC_LIT183_data "atan2"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT183,5,_OMC_LIT183_data);
#define _OMC_LIT183 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT183)
#define _OMC_LIT184_data "simplify1 took "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT184,15,_OMC_LIT184_data);
#define _OMC_LIT184 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT184)
#define _OMC_LIT185_data " seconds for exp: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT185,18,_OMC_LIT185_data);
#define _OMC_LIT185 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT185)
#define _OMC_LIT186_data " \nsimplified to :"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT186,17,_OMC_LIT186_data);
#define _OMC_LIT186 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT186)
#define _OMC_LIT187_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT187,1,_OMC_LIT187_data);
#define _OMC_LIT187 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT187)
#define _OMC_LIT188_data "eval exp failed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT188,15,_OMC_LIT188_data);
#define _OMC_LIT188 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT188)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT189,2,1) {_OMC_LIT188,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT189 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT189)
#include "util/modelica.h"
#include "ExpressionSimplify_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ExpressionSimplify_removeMinMaxFoldableValues(threadData_t *threadData, modelica_metatype _e);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_removeMinMaxFoldableValues(threadData_t *threadData, modelica_metatype _e);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_removeMinMaxFoldableValues,2,0) {(void*) boxptr_ExpressionSimplify_removeMinMaxFoldableValues,0}};
#define boxvar_ExpressionSimplify_removeMinMaxFoldableValues MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_removeMinMaxFoldableValues)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_minElement(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _e2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_minElement,2,0) {(void*) boxptr_ExpressionSimplify_minElement,0}};
#define boxvar_ExpressionSimplify_minElement MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_minElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_maxElement(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _e2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_maxElement,2,0) {(void*) boxptr_ExpressionSimplify_maxElement,0}};
#define boxvar_ExpressionSimplify_maxElement MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_maxElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyNoEvent(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyNoEvent,2,0) {(void*) boxptr_ExpressionSimplify_simplifyNoEvent,0}};
#define boxvar_ExpressionSimplify_simplifyNoEvent MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyNoEvent)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyTSub(threadData_t *threadData, modelica_metatype _origExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyTSub,2,0) {(void*) boxptr_ExpressionSimplify_simplifyTSub,0}};
#define boxvar_ExpressionSimplify_simplifyTSub MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyTSub)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifySize(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _exp, modelica_metatype _optDim);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifySize,2,0) {(void*) boxptr_ExpressionSimplify_simplifySize,0}};
#define boxvar_ExpressionSimplify_simplifySize MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifySize)
PROTECTED_FUNCTION_STATIC void omc_ExpressionSimplify_checkZeroLengthArrayOp(threadData_t *threadData, modelica_metatype _op);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_checkZeroLengthArrayOp,2,0) {(void*) boxptr_ExpressionSimplify_checkZeroLengthArrayOp,0}};
#define boxvar_ExpressionSimplify_checkZeroLengthArrayOp MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_checkZeroLengthArrayOp)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ExpressionSimplify_hasZeroLengthIterator(threadData_t *threadData, modelica_metatype _inIters);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_hasZeroLengthIterator(threadData_t *threadData, modelica_metatype _inIters);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_hasZeroLengthIterator,2,0) {(void*) boxptr_ExpressionSimplify_hasZeroLengthIterator,0}};
#define boxvar_ExpressionSimplify_hasZeroLengthIterator MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_hasZeroLengthIterator)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyReductionFoldPhase2(threadData_t *threadData, modelica_metatype _inExps, modelica_metatype _foldExp, modelica_string _foldName, modelica_string _resultName, modelica_metatype _acc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyReductionFoldPhase2,2,0) {(void*) boxptr_ExpressionSimplify_simplifyReductionFoldPhase2,0}};
#define boxvar_ExpressionSimplify_simplifyReductionFoldPhase2 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyReductionFoldPhase2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyReductionFoldPhase(threadData_t *threadData, modelica_metatype _path, modelica_metatype _optFoldExp, modelica_string _foldName, modelica_string _resultName, modelica_metatype _ty, modelica_metatype _inExps, modelica_metatype _defaultValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyReductionFoldPhase,2,0) {(void*) boxptr_ExpressionSimplify_simplifyReductionFoldPhase,0}};
#define boxvar_ExpressionSimplify_simplifyReductionFoldPhase MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyReductionFoldPhase)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_replaceIteratorWithExpTraverser(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTpl, modelica_metatype *out_outTpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_replaceIteratorWithExpTraverser,2,0) {(void*) boxptr_ExpressionSimplify_replaceIteratorWithExpTraverser,0}};
#define boxvar_ExpressionSimplify_replaceIteratorWithExpTraverser MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_replaceIteratorWithExpTraverser)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_replaceIteratorWithExp(threadData_t *threadData, modelica_metatype _iterExp, modelica_metatype _exp, modelica_string _name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_replaceIteratorWithExp,2,0) {(void*) boxptr_ExpressionSimplify_replaceIteratorWithExp,0}};
#define boxvar_ExpressionSimplify_replaceIteratorWithExp MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_replaceIteratorWithExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_getIteratorValues(threadData_t *threadData, modelica_metatype _iter, modelica_metatype _inValues);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_getIteratorValues,2,0) {(void*) boxptr_ExpressionSimplify_getIteratorValues,0}};
#define boxvar_ExpressionSimplify_getIteratorValues MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_getIteratorValues)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyReduction(threadData_t *threadData, modelica_metatype _inReduction);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyReduction,2,0) {(void*) boxptr_ExpressionSimplify_simplifyReduction,0}};
#define boxvar_ExpressionSimplify_simplifyReduction MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyReduction)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyRangeReal2(threadData_t *threadData, modelica_real _inStart, modelica_real _inStep, modelica_integer _inSteps, modelica_metatype _inValues);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyRangeReal2(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inStep, modelica_metatype _inSteps, modelica_metatype _inValues);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyRangeReal2,2,0) {(void*) boxptr_ExpressionSimplify_simplifyRangeReal2,0}};
#define boxvar_ExpressionSimplify_simplifyRangeReal2 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyRangeReal2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_removeOperatorDimension(threadData_t *threadData, modelica_metatype _inop);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_removeOperatorDimension,2,0) {(void*) boxptr_ExpressionSimplify_removeOperatorDimension,0}};
#define boxvar_ExpressionSimplify_removeOperatorDimension MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_removeOperatorDimension)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBuiltinConstantDer(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBuiltinConstantDer,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBuiltinConstantDer,0}};
#define boxvar_ExpressionSimplify_simplifyBuiltinConstantDer MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBuiltinConstantDer)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinarySortConstantsMul(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinarySortConstantsMul,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinarySortConstantsMul,0}};
#define boxvar_ExpressionSimplify_simplifyBinarySortConstantsMul MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinarySortConstantsMul)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorScalarMatrix(threadData_t *threadData, modelica_metatype _imexpl, modelica_metatype _op, modelica_metatype _s1, modelica_boolean _arrayScalar);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyVectorScalarMatrix(threadData_t *threadData, modelica_metatype _imexpl, modelica_metatype _op, modelica_metatype _s1, modelica_metatype _arrayScalar);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyVectorScalarMatrix,2,0) {(void*) boxptr_ExpressionSimplify_simplifyVectorScalarMatrix,0}};
#define boxvar_ExpressionSimplify_simplifyVectorScalarMatrix MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyVectorScalarMatrix)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyUnary(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOperator2, modelica_metatype _inExp3);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyUnary,2,0) {(void*) boxptr_ExpressionSimplify_simplifyUnary,0}};
#define boxvar_ExpressionSimplify_simplifyUnary MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyUnary)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryDistributePow(threadData_t *threadData, modelica_metatype _inExpLst, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryDistributePow,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinaryDistributePow,0}};
#define boxvar_ExpressionSimplify_simplifyBinaryDistributePow MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryDistributePow)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyRelation2(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOp, modelica_metatype _lhs, modelica_metatype _rhs, modelica_integer _index, modelica_metatype _optionExpisASUB, modelica_fnptr _isPositive);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyRelation2(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOp, modelica_metatype _lhs, modelica_metatype _rhs, modelica_metatype _index, modelica_metatype _optionExpisASUB, modelica_fnptr _isPositive);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyRelation2,2,0) {(void*) boxptr_ExpressionSimplify_simplifyRelation2,0}};
#define boxvar_ExpressionSimplify_simplifyRelation2 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyRelation2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyRelation(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOperator2, modelica_metatype _inExp3, modelica_metatype _inExp4, modelica_integer _index, modelica_metatype _optionExpisASUB);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyRelation(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOperator2, modelica_metatype _inExp3, modelica_metatype _inExp4, modelica_metatype _index, modelica_metatype _optionExpisASUB);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyRelation,2,0) {(void*) boxptr_ExpressionSimplify_simplifyRelation,0}};
#define boxvar_ExpressionSimplify_simplifyRelation MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyRelation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyLBinary(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOperator2, modelica_metatype _inExp3, modelica_metatype _inExp4);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyLBinary,2,0) {(void*) boxptr_ExpressionSimplify_simplifyLBinary,0}};
#define boxvar_ExpressionSimplify_simplifyLBinary MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyLBinary)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyTwoBinaryExpressions(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _lhsOperator, modelica_metatype _e2, modelica_metatype _mainOperator, modelica_metatype _e3, modelica_metatype _rhsOperator, modelica_metatype _e4, modelica_boolean _expEqual_e1_e3, modelica_boolean _expEqual_e1_e4, modelica_boolean _expEqual_e2_e3, modelica_boolean _expEqual_e2_e4, modelica_boolean _isConst_e1, modelica_boolean _isConst_e2, modelica_boolean _isConst_e3, modelica_boolean _operatorEqualLhsRhs);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyTwoBinaryExpressions(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _lhsOperator, modelica_metatype _e2, modelica_metatype _mainOperator, modelica_metatype _e3, modelica_metatype _rhsOperator, modelica_metatype _e4, modelica_metatype _expEqual_e1_e3, modelica_metatype _expEqual_e1_e4, modelica_metatype _expEqual_e2_e3, modelica_metatype _expEqual_e2_e4, modelica_metatype _isConst_e1, modelica_metatype _isConst_e2, modelica_metatype _isConst_e3, modelica_metatype _operatorEqualLhsRhs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyTwoBinaryExpressions,2,0) {(void*) boxptr_ExpressionSimplify_simplifyTwoBinaryExpressions,0}};
#define boxvar_ExpressionSimplify_simplifyTwoBinaryExpressions MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyTwoBinaryExpressions)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinary(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOperator2, modelica_metatype _lhs, modelica_metatype _rhs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinary,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinary,0}};
#define boxvar_ExpressionSimplify_simplifyBinary MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinary)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryCommutativeWork(threadData_t *threadData, modelica_metatype _op, modelica_metatype _lhs, modelica_metatype _rhs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryCommutativeWork,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinaryCommutativeWork,0}};
#define boxvar_ExpressionSimplify_simplifyBinaryCommutativeWork MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryCommutativeWork)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ExpressionSimplify_simplifyRelationConst(threadData_t *threadData, modelica_metatype _op, modelica_metatype _e1, modelica_metatype _e2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyRelationConst(threadData_t *threadData, modelica_metatype _op, modelica_metatype _e1, modelica_metatype _e2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyRelationConst,2,0) {(void*) boxptr_ExpressionSimplify_simplifyRelationConst,0}};
#define boxvar_ExpressionSimplify_simplifyRelationConst MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyRelationConst)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryConst(threadData_t *threadData, modelica_metatype _inOperator1, modelica_metatype _inExp2, modelica_metatype _inExp3);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryConst,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinaryConst,0}};
#define boxvar_ExpressionSimplify_simplifyBinaryConst MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryConst)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubSlicing2(threadData_t *threadData, modelica_metatype _inSubscripts, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsubSlicing2,2,0) {(void*) boxptr_ExpressionSimplify_simplifyAsubSlicing2,0}};
#define boxvar_ExpressionSimplify_simplifyAsubSlicing2 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsubSlicing2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubSlicing(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inSubscripts);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsubSlicing,2,0) {(void*) boxptr_ExpressionSimplify_simplifyAsubSlicing,0}};
#define boxvar_ExpressionSimplify_simplifyAsubSlicing MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsubSlicing)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubOperator(threadData_t *threadData, modelica_metatype _inExp1, modelica_metatype _inOperator2, modelica_metatype _inOperator3);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsubOperator,2,0) {(void*) boxptr_ExpressionSimplify_simplifyAsubOperator,0}};
#define boxvar_ExpressionSimplify_simplifyAsubOperator MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsubOperator)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubArrayReduction(threadData_t *threadData, modelica_metatype _iter, modelica_metatype _sub, modelica_metatype _acc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsubArrayReduction,2,0) {(void*) boxptr_ExpressionSimplify_simplifyAsubArrayReduction,0}};
#define boxvar_ExpressionSimplify_simplifyAsubArrayReduction MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsubArrayReduction)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsub(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inSub);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsub,2,0) {(void*) boxptr_ExpressionSimplify_simplifyAsub,0}};
#define boxvar_ExpressionSimplify_simplifyAsub MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsub)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubCref(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _sub);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsubCref,2,0) {(void*) boxptr_ExpressionSimplify_simplifyAsubCref,0}};
#define boxvar_ExpressionSimplify_simplifyAsubCref MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsubCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsub0(threadData_t *threadData, modelica_metatype _ie, modelica_integer _sub, modelica_metatype _inSubExp);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyAsub0(threadData_t *threadData, modelica_metatype _ie, modelica_metatype _sub, modelica_metatype _inSubExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsub0,2,0) {(void*) boxptr_ExpressionSimplify_simplifyAsub0,0}};
#define boxvar_ExpressionSimplify_simplifyAsub0 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsub0)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryMulCoeff2(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryMulCoeff2,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinaryMulCoeff2,0}};
#define boxvar_ExpressionSimplify_simplifyBinaryMulCoeff2 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryMulCoeff2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryAddCoeff2(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryAddCoeff2,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinaryAddCoeff2,0}};
#define boxvar_ExpressionSimplify_simplifyBinaryAddCoeff2 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryAddCoeff2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAddMakeMul(threadData_t *threadData, modelica_metatype _inTplExpRealLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAddMakeMul,2,0) {(void*) boxptr_ExpressionSimplify_simplifyAddMakeMul,0}};
#define boxvar_ExpressionSimplify_simplifyAddMakeMul MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAddMakeMul)
PROTECTED_FUNCTION_STATIC modelica_real omc_ExpressionSimplify_simplifyAddJoinTermsFind(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTplExpRealLst, modelica_metatype *out_outTplExpRealLst);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyAddJoinTermsFind(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTplExpRealLst, modelica_metatype *out_outTplExpRealLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAddJoinTermsFind,2,0) {(void*) boxptr_ExpressionSimplify_simplifyAddJoinTermsFind,0}};
#define boxvar_ExpressionSimplify_simplifyAddJoinTermsFind MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAddJoinTermsFind)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAddJoinTerms(threadData_t *threadData, modelica_metatype _inTplExpRealLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAddJoinTerms,2,0) {(void*) boxptr_ExpressionSimplify_simplifyAddJoinTerms,0}};
#define boxvar_ExpressionSimplify_simplifyAddJoinTerms MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAddJoinTerms)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAdd(threadData_t *threadData, modelica_metatype _inExpLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAdd,2,0) {(void*) boxptr_ExpressionSimplify_simplifyAdd,0}};
#define boxvar_ExpressionSimplify_simplifyAdd MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAdd)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMulMakePow(threadData_t *threadData, modelica_metatype _inTplExpRealLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMulMakePow,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMulMakePow,0}};
#define boxvar_ExpressionSimplify_simplifyMulMakePow MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMulMakePow)
PROTECTED_FUNCTION_STATIC modelica_real omc_ExpressionSimplify_simplifyMulJoinFactorsFind(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTplExpRealLst, modelica_metatype *out_outTplExpRealLst);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyMulJoinFactorsFind(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTplExpRealLst, modelica_metatype *out_outTplExpRealLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMulJoinFactorsFind,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMulJoinFactorsFind,0}};
#define boxvar_ExpressionSimplify_simplifyMulJoinFactorsFind MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMulJoinFactorsFind)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMulJoinFactors(threadData_t *threadData, modelica_metatype _inTplExpRealLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMulJoinFactors,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMulJoinFactors,0}};
#define boxvar_ExpressionSimplify_simplifyMulJoinFactors MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMulJoinFactors)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMul(threadData_t *threadData, modelica_metatype _expl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMul,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMul,0}};
#define boxvar_ExpressionSimplify_simplifyMul MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMul)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryMulConstants(threadData_t *threadData, modelica_metatype _inExpLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryMulConstants,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinaryMulConstants,0}};
#define boxvar_ExpressionSimplify_simplifyBinaryMulConstants MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryMulConstants)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryAddConstants(threadData_t *threadData, modelica_metatype _inExpLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryAddConstants,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinaryAddConstants,0}};
#define boxvar_ExpressionSimplify_simplifyBinaryAddConstants MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryAddConstants)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryCoeff(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryCoeff,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinaryCoeff,0}};
#define boxvar_ExpressionSimplify_simplifyBinaryCoeff MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryCoeff)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinarySortConstants(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinarySortConstants,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinarySortConstants,0}};
#define boxvar_ExpressionSimplify_simplifyBinarySortConstants MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinarySortConstants)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixProduct4(threadData_t *threadData, modelica_metatype _inMatrix1, modelica_metatype _inMatrix2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixProduct4,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMatrixProduct4,0}};
#define boxvar_ExpressionSimplify_simplifyMatrixProduct4 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixProduct4)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixProduct3(threadData_t *threadData, modelica_metatype _inRow, modelica_metatype _inMatrix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixProduct3,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMatrixProduct3,0}};
#define boxvar_ExpressionSimplify_simplifyMatrixProduct3 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixProduct3)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixProduct2(threadData_t *threadData, modelica_metatype _inMatrix1, modelica_metatype _inMatrix2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixProduct2,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMatrixProduct2,0}};
#define boxvar_ExpressionSimplify_simplifyMatrixProduct2 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixProduct2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixProduct(threadData_t *threadData, modelica_metatype _inMatrix1, modelica_metatype _inMatrix2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixProduct,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMatrixProduct,0}};
#define boxvar_ExpressionSimplify_simplifyMatrixProduct MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixProduct)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixPow1(threadData_t *threadData, modelica_metatype _inRange, modelica_metatype _inMatrix, modelica_metatype _inValue);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixPow1,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMatrixPow1,0}};
#define boxvar_ExpressionSimplify_simplifyMatrixPow1 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixPow1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixPow(threadData_t *threadData, modelica_metatype _inExp1, modelica_metatype _inType, modelica_metatype _inExp2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixPow,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMatrixPow,0}};
#define boxvar_ExpressionSimplify_simplifyMatrixPow MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixPow)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixBinary2(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inRhs, modelica_metatype _inOperator);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixBinary2,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMatrixBinary2,0}};
#define boxvar_ExpressionSimplify_simplifyMatrixBinary2 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixBinary2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixBinary1(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inRhs, modelica_metatype _inOperator);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixBinary1,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMatrixBinary1,0}};
#define boxvar_ExpressionSimplify_simplifyMatrixBinary1 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixBinary1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixBinary(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inOperator, modelica_metatype _inRhs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixBinary,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMatrixBinary,0}};
#define boxvar_ExpressionSimplify_simplifyMatrixBinary MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatrixBinary)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorBinary2(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inRhs, modelica_metatype _inOperator);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyVectorBinary2,2,0) {(void*) boxptr_ExpressionSimplify_simplifyVectorBinary2,0}};
#define boxvar_ExpressionSimplify_simplifyVectorBinary2 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyVectorBinary2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorBinary(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inOperator, modelica_metatype _inRhs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyVectorBinary,2,0) {(void*) boxptr_ExpressionSimplify_simplifyVectorBinary,0}};
#define boxvar_ExpressionSimplify_simplifyVectorBinary MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyVectorBinary)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorBinary0(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _op, modelica_metatype _e2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyVectorBinary0,2,0) {(void*) boxptr_ExpressionSimplify_simplifyVectorBinary0,0}};
#define boxvar_ExpressionSimplify_simplifyVectorBinary0 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyVectorBinary0)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorScalar(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inOperator, modelica_metatype _inRhs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyVectorScalar,2,0) {(void*) boxptr_ExpressionSimplify_simplifyVectorScalar,0}};
#define boxvar_ExpressionSimplify_simplifyVectorScalar MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyVectorScalar)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_unliftOperator(threadData_t *threadData, modelica_metatype _inArray, modelica_metatype _inOperator);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_unliftOperator,2,0) {(void*) boxptr_ExpressionSimplify_unliftOperator,0}};
#define boxvar_ExpressionSimplify_unliftOperator MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_unliftOperator)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryArray(threadData_t *threadData, modelica_metatype _inExp1, modelica_metatype _inOperator2, modelica_metatype _inExp3);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryArray,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinaryArray,0}};
#define boxvar_ExpressionSimplify_simplifyBinaryArray MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryArray)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ExpressionSimplify_simplifyBinaryArrayOp(threadData_t *threadData, modelica_metatype _inOperator);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyBinaryArrayOp(threadData_t *threadData, modelica_metatype _inOperator);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryArrayOp,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBinaryArrayOp,0}};
#define boxvar_ExpressionSimplify_simplifyBinaryArrayOp MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBinaryArrayOp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCrefMM1(threadData_t *threadData, modelica_string _ident, modelica_metatype _ty, modelica_metatype _ssl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCrefMM1,2,0) {(void*) boxptr_ExpressionSimplify_simplifyCrefMM1,0}};
#define boxvar_ExpressionSimplify_simplifyCrefMM1 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCrefMM1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCrefMM(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inType, modelica_metatype _inCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCrefMM,2,0) {(void*) boxptr_ExpressionSimplify_simplifyCrefMM,0}};
#define boxvar_ExpressionSimplify_simplifyCrefMM MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCrefMM)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCrefMM__index(threadData_t *threadData, modelica_metatype _inExp, modelica_string _ident, modelica_metatype _ty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCrefMM__index,2,0) {(void*) boxptr_ExpressionSimplify_simplifyCrefMM__index,0}};
#define boxvar_ExpressionSimplify_simplifyCrefMM__index MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCrefMM__index)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCref2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inSsl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCref2,2,0) {(void*) boxptr_ExpressionSimplify_simplifyCref2,0}};
#define boxvar_ExpressionSimplify_simplifyCref2 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCref2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCref(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inCREF, modelica_metatype _inType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCref,2,0) {(void*) boxptr_ExpressionSimplify_simplifyCref,0}};
#define boxvar_ExpressionSimplify_simplifyCref MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBuiltinConstantCalls(threadData_t *threadData, modelica_string _name, modelica_metatype _exp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBuiltinConstantCalls,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBuiltinConstantCalls,0}};
#define boxvar_ExpressionSimplify_simplifyBuiltinConstantCalls MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBuiltinConstantCalls)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyStringAppendList(threadData_t *threadData, modelica_metatype _iexpl, modelica_metatype _iacc, modelica_boolean _ichange);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyStringAppendList(threadData_t *threadData, modelica_metatype _iexpl, modelica_metatype _iacc, modelica_metatype _ichange);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyStringAppendList,2,0) {(void*) boxptr_ExpressionSimplify_simplifyStringAppendList,0}};
#define boxvar_ExpressionSimplify_simplifyStringAppendList MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyStringAppendList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBuiltinStringFormat(threadData_t *threadData, modelica_metatype _exp, modelica_metatype _len_exp, modelica_metatype _just_exp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBuiltinStringFormat,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBuiltinStringFormat,0}};
#define boxvar_ExpressionSimplify_simplifyBuiltinStringFormat MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBuiltinStringFormat)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_evalCatGetFlatArray(threadData_t *threadData, modelica_metatype _e, modelica_integer _dim, modelica_fnptr _getArrayContents, modelica_fnptr _toString, modelica_metatype *out_outDims);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_evalCatGetFlatArray(threadData_t *threadData, modelica_metatype _e, modelica_metatype _dim, modelica_fnptr _getArrayContents, modelica_fnptr _toString, modelica_metatype *out_outDims);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_evalCatGetFlatArray,2,0) {(void*) boxptr_ExpressionSimplify_evalCatGetFlatArray,0}};
#define boxvar_ExpressionSimplify_evalCatGetFlatArray MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_evalCatGetFlatArray)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCat2(threadData_t *threadData, modelica_integer _dim, modelica_metatype _ies, modelica_metatype _acc, modelica_boolean _changed);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyCat2(threadData_t *threadData, modelica_metatype _dim, modelica_metatype _ies, modelica_metatype _acc, modelica_metatype _changed);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCat2,2,0) {(void*) boxptr_ExpressionSimplify_simplifyCat2,0}};
#define boxvar_ExpressionSimplify_simplifyCat2 MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCat2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCatArg(threadData_t *threadData, modelica_metatype _arg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCatArg,2,0) {(void*) boxptr_ExpressionSimplify_simplifyCatArg,0}};
#define boxvar_ExpressionSimplify_simplifyCatArg MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCatArg)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCat(threadData_t *threadData, modelica_integer _inDim, modelica_metatype _inExpList);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyCat(threadData_t *threadData, modelica_metatype _inDim, modelica_metatype _inExpList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCat,2,0) {(void*) boxptr_ExpressionSimplify_simplifyCat,0}};
#define boxvar_ExpressionSimplify_simplifyCat MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCat)
PROTECTED_FUNCTION_STATIC void omc_ExpressionSimplify_simplifySymmetric(threadData_t *threadData, modelica_metatype _marr, modelica_integer _i1, modelica_integer _i2);
PROTECTED_FUNCTION_STATIC void boxptr_ExpressionSimplify_simplifySymmetric(threadData_t *threadData, modelica_metatype _marr, modelica_metatype _i1, modelica_metatype _i2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifySymmetric,2,0) {(void*) boxptr_ExpressionSimplify_simplifySymmetric,0}};
#define boxvar_ExpressionSimplify_simplifySymmetric MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifySymmetric)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_makeNestedReduction(threadData_t *threadData, modelica_metatype _inExp, modelica_string _inName, modelica_metatype _inType, modelica_metatype _inCall);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_makeNestedReduction,2,0) {(void*) boxptr_ExpressionSimplify_makeNestedReduction,0}};
#define boxvar_ExpressionSimplify_makeNestedReduction MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_makeNestedReduction)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyScalar(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _tp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyScalar,2,0) {(void*) boxptr_ExpressionSimplify_simplifyScalar,0}};
#define boxvar_ExpressionSimplify_simplifyScalar MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyScalar)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBuiltinCalls(threadData_t *threadData, modelica_metatype _exp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBuiltinCalls,2,0) {(void*) boxptr_ExpressionSimplify_simplifyBuiltinCalls,0}};
#define boxvar_ExpressionSimplify_simplifyBuiltinCalls MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyBuiltinCalls)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_reductionExpression(threadData_t *threadData, modelica_string _name, modelica_metatype _ty, modelica_string _foldName, modelica_string _resultName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_reductionExpression,2,0) {(void*) boxptr_ExpressionSimplify_reductionExpression,0}};
#define boxvar_ExpressionSimplify_reductionExpression MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_reductionExpression)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_reductionDefaultValue(threadData_t *threadData, modelica_string _name, modelica_metatype _ty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_reductionDefaultValue,2,0) {(void*) boxptr_ExpressionSimplify_reductionDefaultValue,0}};
#define boxvar_ExpressionSimplify_reductionDefaultValue MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_reductionDefaultValue)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_addCast(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_addCast,2,0) {(void*) boxptr_ExpressionSimplify_addCast,0}};
#define boxvar_ExpressionSimplify_addCast MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_addCast)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCast(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _exp, modelica_metatype _tp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCast,2,0) {(void*) boxptr_ExpressionSimplify_simplifyCast,0}};
#define boxvar_ExpressionSimplify_simplifyCast MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCast)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatch(threadData_t *threadData, modelica_metatype _exp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatch,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMatch,0}};
#define boxvar_ExpressionSimplify_simplifyMatch MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMatch)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyUnbox(threadData_t *threadData, modelica_metatype _exp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyUnbox,2,0) {(void*) boxptr_ExpressionSimplify_simplifyUnbox,0}};
#define boxvar_ExpressionSimplify_simplifyUnbox MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyUnbox)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCons(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCons,2,0) {(void*) boxptr_ExpressionSimplify_simplifyCons,0}};
#define boxvar_ExpressionSimplify_simplifyCons MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCons)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMetaModelicaCalls(threadData_t *threadData, modelica_metatype _exp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMetaModelicaCalls,2,0) {(void*) boxptr_ExpressionSimplify_simplifyMetaModelicaCalls,0}};
#define boxvar_ExpressionSimplify_simplifyMetaModelicaCalls MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyMetaModelicaCalls)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyIfExp(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _cond, modelica_metatype _tb, modelica_metatype _fb);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyIfExp,2,0) {(void*) boxptr_ExpressionSimplify_simplifyIfExp,0}};
#define boxvar_ExpressionSimplify_simplifyIfExp MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyIfExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyReductionIterators(threadData_t *threadData, modelica_metatype _inIters, modelica_metatype _inAcc, modelica_boolean _inChange, modelica_boolean *out_outChange);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyReductionIterators(threadData_t *threadData, modelica_metatype _inIters, modelica_metatype _inAcc, modelica_metatype _inChange, modelica_metatype *out_outChange);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyReductionIterators,2,0) {(void*) boxptr_ExpressionSimplify_simplifyReductionIterators,0}};
#define boxvar_ExpressionSimplify_simplifyReductionIterators MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyReductionIterators)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplify1FixP(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inOptions, modelica_integer _n, modelica_boolean _cont, modelica_boolean _hasChanged, modelica_boolean *out_outHasChanged);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplify1FixP(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inOptions, modelica_metatype _n, modelica_metatype _cont, modelica_metatype _hasChanged, modelica_metatype *out_outHasChanged);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplify1FixP,2,0) {(void*) boxptr_ExpressionSimplify_simplify1FixP,0}};
#define boxvar_ExpressionSimplify_simplify1FixP MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplify1FixP)
PROTECTED_FUNCTION_STATIC void omc_ExpressionSimplify_checkSimplify(threadData_t *threadData, modelica_boolean _check, modelica_metatype _before, modelica_metatype _after);
PROTECTED_FUNCTION_STATIC void boxptr_ExpressionSimplify_checkSimplify(threadData_t *threadData, modelica_metatype _check, modelica_metatype _before, modelica_metatype _after);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_checkSimplify,2,0) {(void*) boxptr_ExpressionSimplify_checkSimplify,0}};
#define boxvar_ExpressionSimplify_checkSimplify MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_checkSimplify)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_edgeCref(threadData_t *threadData, modelica_metatype _ie, modelica_boolean _ib, modelica_boolean *out_cont, modelica_boolean *out_ob);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_edgeCref(threadData_t *threadData, modelica_metatype _ie, modelica_metatype _ib, modelica_metatype *out_cont, modelica_metatype *out_ob);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_edgeCref,2,0) {(void*) boxptr_ExpressionSimplify_edgeCref,0}};
#define boxvar_ExpressionSimplify_edgeCref MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_edgeCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_changeCref(threadData_t *threadData, modelica_metatype _ie, modelica_boolean _ib, modelica_boolean *out_cont, modelica_boolean *out_ob);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_changeCref(threadData_t *threadData, modelica_metatype _ie, modelica_metatype _ib, modelica_metatype *out_cont, modelica_metatype *out_ob);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_changeCref,2,0) {(void*) boxptr_ExpressionSimplify_changeCref,0}};
#define boxvar_ExpressionSimplify_changeCref MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_changeCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_previousCref(threadData_t *threadData, modelica_metatype _ie, modelica_boolean _ib, modelica_boolean *out_cont, modelica_boolean *out_ob);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_previousCref(threadData_t *threadData, modelica_metatype _ie, modelica_metatype _ib, modelica_metatype *out_cont, modelica_metatype *out_ob);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_previousCref,2,0) {(void*) boxptr_ExpressionSimplify_previousCref,0}};
#define boxvar_ExpressionSimplify_previousCref MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_previousCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_preCref(threadData_t *threadData, modelica_metatype _ie, modelica_boolean _ib, modelica_boolean *out_cont, modelica_boolean *out_ob);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_preCref(threadData_t *threadData, modelica_metatype _ie, modelica_metatype _ib, modelica_metatype *out_cont, modelica_metatype *out_ob);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_preCref,2,0) {(void*) boxptr_ExpressionSimplify_preCref,0}};
#define boxvar_ExpressionSimplify_preCref MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_preCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCall(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCall,2,0) {(void*) boxptr_ExpressionSimplify_simplifyCall,0}};
#define boxvar_ExpressionSimplify_simplifyCall MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyCall)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubExp(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inExp, modelica_metatype _inSubs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsubExp,2,0) {(void*) boxptr_ExpressionSimplify_simplifyAsubExp,0}};
#define boxvar_ExpressionSimplify_simplifyAsubExp MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyAsubExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyRSub(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fe);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyRSub,2,0) {(void*) boxptr_ExpressionSimplify_simplifyRSub,0}};
#define boxvar_ExpressionSimplify_simplifyRSub MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyRSub)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyWithOptions(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _options, modelica_boolean *out_hasChanged);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyWithOptions(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _options, modelica_metatype *out_hasChanged);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyWithOptions,2,0) {(void*) boxptr_ExpressionSimplify_simplifyWithOptions,0}};
#define boxvar_ExpressionSimplify_simplifyWithOptions MMC_REFSTRUCTLIT(boxvar_lit_ExpressionSimplify_simplifyWithOptions)
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyCross(threadData_t *threadData, modelica_metatype _v1, modelica_metatype _v2)
{
modelica_metatype _res = NULL;
modelica_metatype _x1 = NULL;
modelica_metatype _x2 = NULL;
modelica_metatype _x3 = NULL;
modelica_metatype _y1 = NULL;
modelica_metatype _y2 = NULL;
modelica_metatype _y3 = NULL;
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
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _v1;
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
if (listEmpty(tmpMeta3)) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_CAR(tmpMeta3);
tmpMeta5 = MMC_CDR(tmpMeta3);
if (listEmpty(tmpMeta5)) MMC_THROW_INTERNAL();
tmpMeta6 = MMC_CAR(tmpMeta5);
tmpMeta7 = MMC_CDR(tmpMeta5);
if (!listEmpty(tmpMeta7)) MMC_THROW_INTERNAL();
_x1 = tmpMeta2;
_x2 = tmpMeta4;
_x3 = tmpMeta6;
tmpMeta8 = _v2;
if (listEmpty(tmpMeta8)) MMC_THROW_INTERNAL();
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (listEmpty(tmpMeta10)) MMC_THROW_INTERNAL();
tmpMeta11 = MMC_CAR(tmpMeta10);
tmpMeta12 = MMC_CDR(tmpMeta10);
if (listEmpty(tmpMeta12)) MMC_THROW_INTERNAL();
tmpMeta13 = MMC_CAR(tmpMeta12);
tmpMeta14 = MMC_CDR(tmpMeta12);
if (!listEmpty(tmpMeta14)) MMC_THROW_INTERNAL();
_y1 = tmpMeta9;
_y2 = tmpMeta11;
_y3 = tmpMeta13;
tmpMeta15 = mmc_mk_cons(omc_Expression_makeDiff(threadData, omc_Expression_makeProduct(threadData, _x2, _y3), omc_Expression_makeProduct(threadData, _x3, _y2)), mmc_mk_cons(omc_Expression_makeDiff(threadData, omc_Expression_makeProduct(threadData, _x3, _y1), omc_Expression_makeProduct(threadData, _x1, _y3)), mmc_mk_cons(omc_Expression_makeDiff(threadData, omc_Expression_makeProduct(threadData, _x1, _y2), omc_Expression_makeProduct(threadData, _x2, _y1)), MMC_REFSTRUCTLIT(mmc_nil))));
_res = tmpMeta15;
_return: OMC_LABEL_UNUSED
return _res;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifySkew(threadData_t *threadData, modelica_metatype _v1)
{
modelica_metatype _res = NULL;
modelica_metatype _x1 = NULL;
modelica_metatype _x2 = NULL;
modelica_metatype _x3 = NULL;
modelica_metatype _zero = NULL;
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
tmpMeta1 = _v1;
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
if (listEmpty(tmpMeta3)) MMC_THROW_INTERNAL();
tmpMeta4 = MMC_CAR(tmpMeta3);
tmpMeta5 = MMC_CDR(tmpMeta3);
if (listEmpty(tmpMeta5)) MMC_THROW_INTERNAL();
tmpMeta6 = MMC_CAR(tmpMeta5);
tmpMeta7 = MMC_CDR(tmpMeta5);
if (!listEmpty(tmpMeta7)) MMC_THROW_INTERNAL();
_x1 = tmpMeta2;
_x2 = tmpMeta4;
_x3 = tmpMeta6;
_zero = omc_Expression_makeConstZero(threadData, omc_Expression_typeof(threadData, _x1));
tmpMeta9 = mmc_mk_cons(_zero, mmc_mk_cons(omc_Expression_negate(threadData, _x3), mmc_mk_cons(_x2, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta10 = mmc_mk_cons(_x3, mmc_mk_cons(_zero, mmc_mk_cons(omc_Expression_negate(threadData, _x1), MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta11 = mmc_mk_cons(omc_Expression_negate(threadData, _x2), mmc_mk_cons(_x1, mmc_mk_cons(_zero, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta8 = mmc_mk_cons(tmpMeta9, mmc_mk_cons(tmpMeta10, mmc_mk_cons(tmpMeta11, MMC_REFSTRUCTLIT(mmc_nil))));
_res = tmpMeta8;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ExpressionSimplify_removeMinMaxFoldableValues(threadData_t *threadData, modelica_metatype _e)
{
modelica_boolean _filter;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _e;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmp1 = 0;
goto tmp3_done;
}
case 3: {
tmp1 = 0;
goto tmp3_done;
}
case 6: {
tmp1 = 0;
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
_filter = tmp1;
_return: OMC_LABEL_UNUSED
return _filter;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_removeMinMaxFoldableValues(threadData_t *threadData, modelica_metatype _e)
{
modelica_boolean _filter;
modelica_metatype out_filter;
_filter = omc_ExpressionSimplify_removeMinMaxFoldableValues(threadData, _e);
out_filter = mmc_mk_icon(_filter);
return out_filter;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_minElement(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _e2)
{
modelica_metatype _elt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _e1;
tmp4_2 = _e2;
{
modelica_real _r1;
modelica_real _r2;
modelica_integer _i1;
modelica_integer _i2;
modelica_boolean _b1;
modelica_boolean _b2;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
tmpMeta1 = mmc_mk_some(_e1);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
tmpMeta1 = mmc_mk_some(_e1);
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
tmpMeta1 = mmc_mk_some(_e1);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta6;
modelica_real tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_real tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_real(tmpMeta6);
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmp10 = mmc_unbox_real(tmpMeta9);
_r1 = tmp7;
_r2 = tmp10;
tmpMeta1 = ((_r1 < _r2)?mmc_mk_some(_e1):_e2);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta11;
modelica_integer tmp12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp12 = mmc_unbox_integer(tmpMeta11);
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
_i1 = tmp12;
_i2 = tmp15;
tmpMeta1 = ((_i1 < _i2)?mmc_mk_some(_e1):_e2);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta16;
modelica_integer tmp17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
modelica_boolean tmp22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,3,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmp20 = mmc_unbox_integer(tmpMeta19);
_b1 = tmp17;
_b2 = tmp20;
tmp22 = (modelica_boolean)((!_b2) || ((!_b1 && !_b2) || (_b1 && _b2)));
if(tmp22)
{
tmpMeta23 = _e2;
}
else
{
tmpMeta21 = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_b1));
tmpMeta23 = mmc_mk_some(tmpMeta21);
}
tmpMeta1 = tmpMeta23;
goto tmp3_done;
}
case 6: {
tmpMeta1 = _e2;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_maxElement(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _e2)
{
modelica_metatype _elt = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _e1;
tmp4_2 = _e2;
{
modelica_real _r1;
modelica_real _r2;
modelica_integer _i1;
modelica_integer _i2;
modelica_boolean _b1;
modelica_boolean _b2;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
tmpMeta1 = mmc_mk_some(_e1);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
tmpMeta1 = mmc_mk_some(_e1);
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
tmpMeta1 = mmc_mk_some(_e1);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta6;
modelica_real tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_real tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_real(tmpMeta6);
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmp10 = mmc_unbox_real(tmpMeta9);
_r1 = tmp7;
_r2 = tmp10;
tmpMeta1 = ((_r1 > _r2)?mmc_mk_some(_e1):_e2);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta11;
modelica_integer tmp12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp12 = mmc_unbox_integer(tmpMeta11);
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
_i1 = tmp12;
_i2 = tmp15;
tmpMeta1 = ((_i1 > _i2)?mmc_mk_some(_e1):_e2);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta16;
modelica_integer tmp17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
modelica_boolean tmp22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,3,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmp20 = mmc_unbox_integer(tmpMeta19);
_b1 = tmp17;
_b2 = tmp20;
tmp22 = (modelica_boolean)(_b2 || ((!_b1 && !_b2) || (_b1 && _b2)));
if(tmp22)
{
tmpMeta23 = _e2;
}
else
{
tmpMeta21 = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_b1));
tmpMeta23 = mmc_mk_some(tmpMeta21);
}
tmpMeta1 = tmpMeta23;
goto tmp3_done;
}
case 6: {
tmpMeta1 = _e2;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyNoEvent(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _e = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_e = omc_Expression_addNoEventToEventTriggeringFunctions(threadData, omc_Expression_addNoEventToRelations(threadData, omc_Expression_stripNoEvent(threadData, _inExp)));
_return: OMC_LABEL_UNUSED
return _e;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyTSub(threadData_t *threadData, modelica_metatype _origExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _origExp;
{
modelica_metatype _expl = NULL;
modelica_integer _i;
modelica_metatype _e = NULL;
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
modelica_integer tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,20,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,19,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp10 = mmc_unbox_integer(tmpMeta9);
_expl = tmpMeta8;
_i = tmp10;
tmpMeta1 = listGet(_expl, _i);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_integer tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,19,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp14 = mmc_unbox_integer(tmpMeta13);
_expl = tmpMeta12;
_i = tmp14;
tmpMeta1 = listGet(_expl, _i);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,3) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,1,1) == 0) goto tmp3_end;
_e = tmpMeta15;
tmpMeta1 = _e;
goto tmp3_done;
}
case 3: {
tmpMeta1 = _origExp;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifySize(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _exp, modelica_metatype _optDim)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _optDim;
{
modelica_integer _i;
modelica_integer _n;
modelica_metatype _t = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _dim = NULL;
modelica_metatype _dimExp = NULL;
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
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_dimExp = tmpMeta6;
_i = omc_Expression_expInt(threadData, _dimExp);
_t = omc_Expression_typeof(threadData, _exp);
_dims = omc_Expression_arrayDimension(threadData, _t);
_dim = listGet(_dims, _i);
_n = omc_Expression_dimensionSize(threadData, _dim);
tmpMeta7 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_n));
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _origExp;
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_condSimplifyAddSymbolicOperation(threadData_t *threadData, modelica_boolean _cond, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype *out_source)
{
modelica_metatype _exp = NULL;
modelica_metatype _source = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
_source = __omcQ_24in_5Fsource;
if(_cond)
{
_exp = omc_ExpressionSimplify_simplifyAddSymbolicOperation(threadData, _exp, _source ,&_source);
}
_return: OMC_LABEL_UNUSED
if (out_source) { *out_source = _source; }
return _exp;
}
modelica_metatype boxptr_ExpressionSimplify_condSimplifyAddSymbolicOperation(threadData_t *threadData, modelica_metatype _cond, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5Fsource, modelica_metatype *out_source)
{
modelica_integer tmp1;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_integer(_cond);
_exp = omc_ExpressionSimplify_condSimplifyAddSymbolicOperation(threadData, tmp1, __omcQ_24in_5Fexp, __omcQ_24in_5Fsource, out_source);
return _exp;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyAddSymbolicOperation(threadData_t *threadData, modelica_metatype _exp, modelica_metatype _source, modelica_metatype *out_outSource)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outSource = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
modelica_boolean _changed;
modelica_boolean _changed1;
modelica_boolean _changed2;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_boolean tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta5;
_e = omc_ExpressionSimplify_simplify(threadData, _e ,&_changed);
tmp7 = (modelica_boolean)_changed;
if(tmp7)
{
tmpMeta6 = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e);
tmpMeta8 = tmpMeta6;
}
else
{
tmpMeta8 = _exp;
}
_outExp = tmpMeta8;
tmpMeta9 = mmc_mk_box3(4, &DAE_SymbolicOperation_SIMPLIFY__desc, _exp, _outExp);
_outSource = omc_ElementSource_condAddSymbolicTransformation(threadData, _changed, _source, tmpMeta9);
tmpMeta[0+0] = _outExp;
tmpMeta[0+1] = _outSource;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta10;
_e = omc_ExpressionSimplify_simplify(threadData, _e ,&_changed);
tmp12 = (modelica_boolean)_changed;
if(tmp12)
{
tmpMeta11 = mmc_mk_box2(4, &DAE_EquationExp_RESIDUAL__EXP__desc, _e);
tmpMeta13 = tmpMeta11;
}
else
{
tmpMeta13 = _exp;
}
_outExp = tmpMeta13;
tmpMeta14 = mmc_mk_box3(4, &DAE_SymbolicOperation_SIMPLIFY__desc, _exp, _outExp);
_outSource = omc_ElementSource_condAddSymbolicTransformation(threadData, _changed, _source, tmpMeta14);
tmpMeta[0+0] = _outExp;
tmpMeta[0+1] = _outSource;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta15;
_e2 = tmpMeta16;
_e1 = omc_ExpressionSimplify_simplify(threadData, _e1 ,&_changed1);
_e2 = omc_ExpressionSimplify_simplify(threadData, _e2 ,&_changed2);
_changed = (_changed1 || _changed2);
tmp18 = (modelica_boolean)_changed;
if(tmp18)
{
tmpMeta17 = mmc_mk_box3(5, &DAE_EquationExp_EQUALITY__EXPS__desc, _e1, _e2);
tmpMeta19 = tmpMeta17;
}
else
{
tmpMeta19 = _exp;
}
_outExp = tmpMeta19;
tmpMeta20 = mmc_mk_box3(4, &DAE_SymbolicOperation_SIMPLIFY__desc, _exp, _outExp);
_outSource = omc_ElementSource_condAddSymbolicTransformation(threadData, _changed, _source, tmpMeta20);
tmpMeta[0+0] = _outExp;
tmpMeta[0+1] = _outSource;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
omc_Error_addMessage(threadData, _OMC_LIT4, _OMC_LIT6);
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
_outExp = tmpMeta[0+0];
_outSource = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outSource) { *out_outSource = _outSource; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC void omc_ExpressionSimplify_checkZeroLengthArrayOp(threadData_t *threadData, modelica_metatype _op)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _op;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 10: {
goto tmp2_done;
}
case 11: {
goto tmp2_done;
}
case 12: {
goto tmp2_done;
}
case 13: {
goto tmp2_done;
}
case 23: {
goto tmp2_done;
}
case 24: {
goto tmp2_done;
}
case 14: {
goto tmp2_done;
}
case 15: {
goto tmp2_done;
}
case 19: {
goto tmp2_done;
}
case 16: {
goto tmp2_done;
}
case 20: {
goto tmp2_done;
}
case 18: {
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
modelica_metatype omc_ExpressionSimplify_condsimplifyList1(threadData_t *threadData, modelica_metatype _blst, modelica_metatype _expl, modelica_metatype *out_outBool)
{
modelica_metatype _outExpl = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _outBool = NULL;
modelica_metatype tmpMeta2;
modelica_metatype _rest_expl = NULL;
modelica_metatype _exp = NULL;
modelica_boolean _b2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outExpl = tmpMeta1;
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_outBool = tmpMeta2;
_rest_expl = _expl;
{
modelica_metatype _b;
for (tmpMeta3 = _blst; !listEmpty(tmpMeta3); tmpMeta3=MMC_CDR(tmpMeta3))
{
_b = MMC_CAR(tmpMeta3);
tmpMeta4 = _rest_expl;
if (listEmpty(tmpMeta4)) MMC_THROW_INTERNAL();
tmpMeta5 = MMC_CAR(tmpMeta4);
tmpMeta6 = MMC_CDR(tmpMeta4);
_exp = tmpMeta5;
_rest_expl = tmpMeta6;
_exp = omc_ExpressionSimplify_condsimplify(threadData, mmc_unbox_boolean(_b), _exp ,&_b2);
tmpMeta7 = mmc_mk_cons(_exp, _outExpl);
_outExpl = tmpMeta7;
tmpMeta8 = mmc_mk_cons(mmc_mk_boolean(_b2), _outBool);
_outBool = tmpMeta8;
}
}
_outExpl = listReverseInPlace(_outExpl);
_outBool = listReverseInPlace(_outBool);
_return: OMC_LABEL_UNUSED
if (out_outBool) { *out_outBool = _outBool; }
return _outExpl;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyList1(threadData_t *threadData, modelica_metatype _expl, modelica_metatype *out_outBool)
{
modelica_metatype _outExpl = NULL;
modelica_metatype _outBool = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outBool = tmpMeta1;
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype __omcQ_24tmpVar0;
modelica_integer tmp11;
modelica_metatype _exp_loopVar = 0;
modelica_metatype _exp;
_exp_loopVar = _expl;
tmpMeta4 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta4;
tmp3 = &__omcQ_24tmpVar1;
while(1) {
tmp11 = 1;
if (!listEmpty(_exp_loopVar)) {
_exp = MMC_CAR(_exp_loopVar);
_exp_loopVar = MMC_CDR(_exp_loopVar);
tmp11--;
}
if (tmp11 == 0) {
{
{
modelica_metatype _e = NULL;
modelica_boolean _b2;
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
for (; tmp8 < 1; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
modelica_metatype tmpMeta10;
_e = omc_ExpressionSimplify_simplify(threadData, _exp ,&_b2);
tmpMeta10 = mmc_mk_cons(mmc_mk_boolean(_b2), _outBool);
_outBool = tmpMeta10;
tmpMeta5 = _e;
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
}__omcQ_24tmpVar0 = tmpMeta5;
*tmp3 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp3 = &MMC_CDR(*tmp3);
} else if (tmp11 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp3 = mmc_mk_nil();
tmpMeta2 = __omcQ_24tmpVar1;
}
_outExpl = tmpMeta2;
_outBool = listReverseInPlace(_outBool);
_return: OMC_LABEL_UNUSED
if (out_outBool) { *out_outBool = _outBool; }
return _outExpl;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyList(threadData_t *threadData, modelica_metatype _expl)
{
modelica_metatype _outExpl = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype __omcQ_24tmpVar2;
modelica_integer tmp4;
modelica_metatype _exp_loopVar = 0;
modelica_metatype _exp;
_exp_loopVar = _expl;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar3;
while(1) {
tmp4 = 1;
if (!listEmpty(_exp_loopVar)) {
_exp = MMC_CAR(_exp_loopVar);
_exp_loopVar = MMC_CDR(_exp_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar2 = omc_ExpressionSimplify_simplify1(threadData, _exp, NULL);
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar3;
}
_outExpl = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExpl;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ExpressionSimplify_hasZeroLengthIterator(threadData_t *threadData, modelica_metatype _inIters)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inIters;
{
modelica_metatype _iters = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_integer tmp11;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (optionNone(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmp11 = mmc_unbox_integer(tmpMeta10);
if (0 != tmp11) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmp4_1);
tmpMeta13 = MMC_CDR(tmp4_1);
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,28,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
if (!listEmpty(tmpMeta15)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_1);
tmpMeta17 = MMC_CDR(tmp4_1);
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,16,3) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 4));
if (!listEmpty(tmpMeta19)) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta20 = MMC_CAR(tmp4_1);
tmpMeta21 = MMC_CDR(tmp4_1);
_iters = tmpMeta21;
_inIters = _iters;
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
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_hasZeroLengthIterator(threadData_t *threadData, modelica_metatype _inIters)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ExpressionSimplify_hasZeroLengthIterator(threadData, _inIters);
out_b = mmc_mk_icon(_b);
return out_b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyReductionFoldPhase2(threadData_t *threadData, modelica_metatype _inExps, modelica_metatype _foldExp, modelica_string _foldName, modelica_string _resultName, modelica_metatype _acc)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExps;
{
modelica_metatype _exps = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta1 = _acc;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
_exp = tmpMeta6;
_exps = tmpMeta7;
_exp = omc_ExpressionSimplify_replaceIteratorWithExp(threadData, _exp, _foldExp, _foldName);
_exp = omc_ExpressionSimplify_replaceIteratorWithExp(threadData, _acc, _exp, _resultName);
_inExps = _exps;
_acc = _exp;
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
_exp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyReductionFoldPhase(threadData_t *threadData, modelica_metatype _path, modelica_metatype _optFoldExp, modelica_string _foldName, modelica_string _resultName, modelica_metatype _ty, modelica_metatype _inExps, modelica_metatype _defaultValue)
{
modelica_metatype _exp = NULL;
modelica_boolean _checkForSimplifications;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_boolean tmp19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;
tmp4_1 = _path;
tmp4_2 = _optFoldExp;
tmp4_3 = _inExps;
tmp4_4 = _defaultValue;
{
modelica_metatype _val = NULL;
modelica_metatype _arr_exp = NULL;
modelica_metatype _foldExp = NULL;
modelica_metatype _aty = NULL;
modelica_metatype _ty2 = NULL;
modelica_metatype _exps = NULL;
modelica_integer _length;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (5 != MMC_STRLEN(tmpMeta6) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta6)) != 0) goto tmp3_end;
_aty = omc_Types_unliftArray(threadData, omc_Types_expTypetoTypesType(threadData, _ty));
_length = listLength(_inExps);
tmpMeta7 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_length));
_ty2 = omc_Types_liftArray(threadData, _aty, tmpMeta7);
_exp = omc_Expression_makeArray(threadData, _inExps, _ty2, (!omc_Types_isArray(threadData, _aty)));
tmpMeta[0+0] = _exp;
tmp1_c1 = 0;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
if (!listEmpty(tmp4_3)) goto tmp3_end;
if (optionNone(tmp4_4)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_4), 1));
_val = tmpMeta8;
tmpMeta[0+0] = omc_ValuesUtil_valueExp(threadData, _val, mmc_mk_none());
tmp1_c1 = 0;
goto tmp3_done;
}
case 2: {
if (!listEmpty(tmp4_3)) goto tmp3_end;
if (!optionNone(tmp4_4)) goto tmp3_end;
goto goto_2;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (3 != MMC_STRLEN(tmpMeta9) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmpMeta9)) != 0) goto tmp3_end;
_arr_exp = omc_Expression_makeScalarArray(threadData, _inExps, _ty);
tmpMeta10 = mmc_mk_cons(_arr_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT7, tmpMeta10, _ty);
tmp1_c1 = 1;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (3 != MMC_STRLEN(tmpMeta11) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta11)) != 0) goto tmp3_end;
_arr_exp = omc_Expression_makeScalarArray(threadData, _inExps, _ty);
tmpMeta12 = mmc_mk_cons(_arr_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT8, tmpMeta12, _ty);
tmp1_c1 = 1;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmp4_3);
tmpMeta15 = MMC_CDR(tmp4_3);
if (!listEmpty(tmpMeta15)) goto tmp3_end;
_exp = tmpMeta14;
tmpMeta[0+0] = _exp;
tmp1_c1 = 0;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (listEmpty(tmp4_3)) goto tmp3_end;
tmpMeta17 = MMC_CAR(tmp4_3);
tmpMeta18 = MMC_CDR(tmp4_3);
_foldExp = tmpMeta16;
_exp = tmpMeta17;
_exps = tmpMeta18;
_exp = omc_ExpressionSimplify_simplifyReductionFoldPhase2(threadData, _exps, _foldExp, _foldName, _resultName, _exp);
tmpMeta[0+0] = _exp;
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
_exp = tmpMeta[0+0];
_checkForSimplifications = tmp1_c1;
if(_checkForSimplifications)
{
tmpMeta20 = omc_ExpressionSimplify_simplify1(threadData, _exp, &tmp19);
_exp = tmpMeta20;
if (1 != tmp19) MMC_THROW_INTERNAL();
}
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_replaceIteratorWithExpTraverser(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTpl, modelica_metatype *out_outTpl)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outTpl = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inTpl;
{
modelica_string _id = NULL;
modelica_string _id2 = NULL;
modelica_string _name = NULL;
modelica_string _replName = NULL;
modelica_metatype _iterExp = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _ty1 = NULL;
modelica_metatype _ss = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _tpl = NULL;
modelica_metatype _callPath = NULL;
modelica_metatype _recordPath = NULL;
modelica_metatype _varLst = NULL;
modelica_metatype _exps = NULL;
modelica_integer _i;
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
modelica_integer tmp7;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (0 != tmp7) goto tmp3_end;
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inTpl;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 4));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_id = tmpMeta9;
_tpl = tmp4_2;
_name = tmpMeta11;
_iterExp = tmpMeta12;
if (!(stringEqual(_name, _id))) goto tmp3_end;
tmpMeta[0+0] = _iterExp;
tmpMeta[0+1] = _tpl;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,1,3) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_exp = tmp4_1;
_id = tmpMeta14;
_name = tmpMeta15;
_iterExp = tmpMeta16;
tmp4 += 4;
if (!(stringEqual(_name, _id))) goto tmp3_end;
tmpMeta17 = mmc_mk_box3(0, _name, _iterExp, mmc_mk_boolean(0));
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = tmpMeta17;
goto tmp3_done;
}
case 3: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,0,4) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 4));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 5));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,6,2) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,1,3) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 4));
if (!listEmpty(tmpMeta28)) goto tmp3_end;
_id = tmpMeta19;
_ty1 = tmpMeta20;
_ss = tmpMeta21;
_cr = tmpMeta22;
_ty = tmpMeta23;
_tpl = tmp4_2;
_name = tmpMeta24;
_replName = tmpMeta27;
if (!(stringEqual(_name, _id))) goto tmp3_end;
tmpMeta29 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _replName, _ty1, _ss, _cr);
tmpMeta30 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, tmpMeta29, _ty);
tmpMeta[0+0] = tmpMeta30;
tmpMeta[0+1] = _tpl;
goto tmp3_done;
}
case 4: {
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
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta32,6,2) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta33,1,3) == 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 2));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta36,0,4) == 0) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 2));
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 3));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 4));
if (!listEmpty(tmpMeta39)) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 5));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_tpl = tmp4_2;
_name = tmpMeta31;
_replName = tmpMeta34;
_ss = tmpMeta35;
_id = tmpMeta37;
_ty1 = tmpMeta38;
_cr = tmpMeta40;
_ty = tmpMeta41;
tmp4 += 1;
if (!(stringEqual(_name, _id))) goto tmp3_end;
tmpMeta42 = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _replName, _ty1, _ss, _cr);
tmpMeta43 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, tmpMeta42, _ty);
tmpMeta[0+0] = tmpMeta43;
tmpMeta[0+1] = _tpl;
goto tmp3_done;
}
case 5: {
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
modelica_boolean tmp59;
modelica_boolean tmp60;
modelica_boolean tmp61;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta45,13,3) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 2));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 3));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 4));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta48), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta49,9,3) == 0) goto tmp3_end;
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta50,3,1) == 0) goto tmp3_end;
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 2));
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta53,0,4) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta53), 2));
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta53), 4));
if (!listEmpty(tmpMeta55)) goto tmp3_end;
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta53), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta56,1,3) == 0) goto tmp3_end;
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta56), 2));
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta56), 4));
if (!listEmpty(tmpMeta58)) goto tmp3_end;
_tpl = tmp4_2;
_name = tmpMeta44;
_callPath = tmpMeta46;
_exps = tmpMeta47;
_recordPath = tmpMeta51;
_varLst = tmpMeta52;
_id = tmpMeta54;
_id2 = tmpMeta57;
tmp59 = (stringEqual(_name, _id));
if (1 != tmp59) goto goto_2;
tmp60 = omc_AbsynUtil_pathEqual(threadData, _callPath, _recordPath);
if (1 != tmp60) goto goto_2;
tmp61 = (listLength(_varLst) == listLength(_exps));
if (1 != tmp61) goto goto_2;
_i = omc_List_position1OnTrue(threadData, _varLst, boxvar_DAEUtil_typeVarIdentEqual, _id2);
_exp = listGet(_exps, _i);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _tpl;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta62,0,4) == 0) goto tmp3_end;
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta62), 2));
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_exp = tmp4_1;
_id = tmpMeta63;
_name = tmpMeta64;
_iterExp = tmpMeta65;
if (!(stringEqual(_name, _id))) goto tmp3_end;
tmpMeta66 = mmc_mk_box3(0, _name, _iterExp, mmc_mk_boolean(0));
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = tmpMeta66;
goto tmp3_done;
}
case 7: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inTpl;
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
_outExp = tmpMeta[0+0];
_outTpl = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outTpl) { *out_outTpl = _outTpl; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_replaceIteratorWithExp(threadData_t *threadData, modelica_metatype _iterExp, modelica_metatype _exp, modelica_string _name)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_integer tmp3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta4 = mmc_mk_box3(0, _name, _iterExp, mmc_mk_boolean(1));
tmpMeta5 = omc_Expression_traverseExpBottomUp(threadData, _exp, boxvar_ExpressionSimplify_replaceIteratorWithExpTraverser, tmpMeta4, &tmpMeta1);
_outExp = tmpMeta5;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp3 = mmc_unbox_integer(tmpMeta2);
if (1 != tmp3) MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_getIteratorValues(threadData_t *threadData, modelica_metatype _iter, modelica_metatype _inValues)
{
modelica_metatype _values = NULL;
modelica_string _iter_name = NULL;
modelica_metatype _range = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _iter;
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
if (!optionNone(tmpMeta4)) MMC_THROW_INTERNAL();
_iter_name = tmpMeta2;
_range = tmpMeta3;
_values = omc_Expression_getArrayOrRangeContents(threadData, _range);
_values = omc_List_threadMap1(threadData, _values, _inValues, boxvar_ExpressionSimplify_replaceIteratorWithExp, _iter_name);
_return: OMC_LABEL_UNUSED
return _values;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyReduction(threadData_t *threadData, modelica_metatype _inReduction)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inReduction;
{
modelica_metatype _expr = NULL;
modelica_metatype _range = NULL;
modelica_metatype _foldExpr = NULL;
modelica_metatype _foldExpr2 = NULL;
modelica_string _iter_name = NULL;
modelica_metatype _values = NULL;
modelica_metatype _defaultValue = NULL;
modelica_metatype _v = NULL;
modelica_metatype _foldExp = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _ty1 = NULL;
modelica_metatype _ety = NULL;
modelica_metatype _iter = NULL;
modelica_metatype _iterators = NULL;
modelica_string _foldName = NULL;
modelica_string _resultName = NULL;
modelica_string _foldName2 = NULL;
modelica_string _resultName2 = NULL;
modelica_metatype _path = NULL;
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
modelica_boolean tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
if (optionNone(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_v = tmpMeta8;
_iterators = tmpMeta9;
tmp10 = omc_ExpressionSimplify_hasZeroLengthIterator(threadData, _iterators);
if (1 != tmp10) goto goto_2;
tmpMeta1 = omc_ValuesUtil_valueExp(threadData, _v, mmc_mk_none());
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_iterators = tmpMeta11;
tmp12 = omc_ExpressionSimplify_hasZeroLengthIterator(threadData, _iterators);
if (1 != tmp12) goto goto_2;
tmpMeta1 = omc_ValuesUtil_valueExp(threadData, _OMC_LIT10, mmc_mk_none());
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
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 4));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 5));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 6));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 7));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 8));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta21)) goto tmp3_end;
tmpMeta22 = MMC_CAR(tmpMeta21);
tmpMeta23 = MMC_CDR(tmpMeta21);
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 3));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 4));
if (!optionNone(tmpMeta26)) goto tmp3_end;
if (!listEmpty(tmpMeta23)) goto tmp3_end;
_path = tmpMeta14;
_ty = tmpMeta15;
_defaultValue = tmpMeta16;
_foldName = tmpMeta17;
_resultName = tmpMeta18;
_foldExp = tmpMeta19;
_expr = tmpMeta20;
_iter_name = tmpMeta24;
_range = tmpMeta25;
_values = omc_Expression_getArrayOrRangeContents(threadData, _range);
_ety = omc_Types_simplifyType(threadData, _ty);
_values = omc_List_map2(threadData, _values, boxvar_ExpressionSimplify_replaceIteratorWithExp, _expr, _iter_name);
tmpMeta1 = omc_ExpressionSimplify_simplifyReductionFoldPhase(threadData, _path, _foldExp, _foldName, _resultName, _ety, _values, _defaultValue);
goto tmp3_done;
}
case 3: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 2));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,1,0) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 4));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 5));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 6));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 7));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 8));
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_path = tmpMeta28;
_ty = tmpMeta30;
_defaultValue = tmpMeta31;
_foldName = tmpMeta32;
_resultName = tmpMeta33;
_foldExp = tmpMeta34;
_expr = tmpMeta35;
_iterators = tmpMeta36;
tmp4 += 3;
tmpMeta37 = _iterators;
if (listEmpty(tmpMeta37)) goto goto_2;
tmpMeta38 = MMC_CAR(tmpMeta37);
tmpMeta39 = MMC_CDR(tmpMeta37);
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 2));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 3));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 4));
if (!optionNone(tmpMeta42)) goto goto_2;
_iter_name = tmpMeta40;
_range = tmpMeta41;
_iterators = tmpMeta39;
_values = omc_Expression_getArrayOrRangeContents(threadData, _range);
_ety = omc_Types_simplifyType(threadData, _ty);
_values = omc_List_map2(threadData, _values, boxvar_ExpressionSimplify_replaceIteratorWithExp, _expr, _iter_name);
_values = omc_List_fold(threadData, _iterators, boxvar_ExpressionSimplify_getIteratorValues, _values);
tmpMeta1 = omc_ExpressionSimplify_simplifyReductionFoldPhase(threadData, _path, _foldExp, _foldName, _resultName, _ety, _values, _defaultValue);
goto tmp3_done;
}
case 4: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta44,1,1) == 0) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 2));
if (5 != MMC_STRLEN(tmpMeta45) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta45)) != 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta46,0,0) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 4));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 6));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 7));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta51)) goto tmp3_end;
tmpMeta52 = MMC_CAR(tmpMeta51);
tmpMeta53 = MMC_CDR(tmpMeta51);
if (listEmpty(tmpMeta53)) goto tmp3_end;
tmpMeta54 = MMC_CAR(tmpMeta53);
tmpMeta55 = MMC_CDR(tmpMeta53);
_path = tmpMeta44;
_ty = tmpMeta47;
_foldName = tmpMeta48;
_resultName = tmpMeta49;
_expr = tmpMeta50;
_iter = tmpMeta52;
_iterators = tmpMeta53;
_foldName2 = omc_Util_getTempVariableIndex(threadData);
_resultName2 = omc_Util_getTempVariableIndex(threadData);
_ty1 = omc_Expression_unliftArray(threadData, _ty);
tmpMeta56 = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _path, _OMC_LIT11, _ty1, mmc_mk_none(), _foldName2, _resultName2, mmc_mk_none());
tmpMeta57 = mmc_mk_cons(_iter, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta58 = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta56, _expr, tmpMeta57);
_expr = tmpMeta58;
tmpMeta59 = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _path, _OMC_LIT11, _ty, mmc_mk_none(), _foldName, _resultName, mmc_mk_none());
tmpMeta60 = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta59, _expr, _iterators);
tmpMeta1 = tmpMeta60;
goto tmp3_done;
}
case 5: {
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
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta61), 2));
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta61), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta63,0,0) == 0) goto tmp3_end;
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta61), 4));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta61), 5));
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta61), 6));
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta61), 7));
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta61), 8));
if (!optionNone(tmpMeta68)) goto tmp3_end;
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta70)) goto tmp3_end;
tmpMeta71 = MMC_CAR(tmpMeta70);
tmpMeta72 = MMC_CDR(tmpMeta70);
if (listEmpty(tmpMeta72)) goto tmp3_end;
tmpMeta73 = MMC_CAR(tmpMeta72);
tmpMeta74 = MMC_CDR(tmpMeta72);
_path = tmpMeta62;
_ty = tmpMeta64;
_defaultValue = tmpMeta65;
_foldName = tmpMeta66;
_resultName = tmpMeta67;
_expr = tmpMeta69;
_iter = tmpMeta71;
_iterators = tmpMeta72;
tmp4 += 1;
_foldName2 = omc_Util_getTempVariableIndex(threadData);
_resultName2 = omc_Util_getTempVariableIndex(threadData);
tmpMeta75 = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _path, _OMC_LIT11, _ty, _defaultValue, _foldName2, _resultName2, mmc_mk_none());
tmpMeta76 = mmc_mk_cons(_iter, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta77 = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta75, _expr, tmpMeta76);
_expr = tmpMeta77;
tmpMeta78 = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _path, _OMC_LIT11, _ty, _defaultValue, _foldName, _resultName, mmc_mk_none());
tmpMeta79 = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta78, _expr, _iterators);
tmpMeta1 = tmpMeta79;
goto tmp3_done;
}
case 6: {
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
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta80 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 2));
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta82,0,0) == 0) goto tmp3_end;
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 4));
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 5));
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 6));
tmpMeta86 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 7));
tmpMeta87 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 8));
if (optionNone(tmpMeta87)) goto tmp3_end;
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta87), 1));
tmpMeta89 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta90 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta90)) goto tmp3_end;
tmpMeta91 = MMC_CAR(tmpMeta90);
tmpMeta92 = MMC_CDR(tmpMeta90);
if (listEmpty(tmpMeta92)) goto tmp3_end;
tmpMeta93 = MMC_CAR(tmpMeta92);
tmpMeta94 = MMC_CDR(tmpMeta92);
_path = tmpMeta81;
_ty = tmpMeta83;
_defaultValue = tmpMeta84;
_foldName = tmpMeta85;
_resultName = tmpMeta86;
_foldExpr = tmpMeta88;
_expr = tmpMeta89;
_iter = tmpMeta91;
_iterators = tmpMeta92;
_foldName2 = omc_Util_getTempVariableIndex(threadData);
_resultName2 = omc_Util_getTempVariableIndex(threadData);
tmpMeta95 = mmc_mk_box2(0, _foldName, _foldName2);
_foldExpr2 = omc_Expression_traverseExpBottomUp(threadData, _foldExpr, boxvar_Expression_renameExpCrefIdent, tmpMeta95, NULL);
tmpMeta96 = mmc_mk_box2(0, _resultName, _resultName2);
_foldExpr2 = omc_Expression_traverseExpBottomUp(threadData, _foldExpr2, boxvar_Expression_renameExpCrefIdent, tmpMeta96, NULL);
tmpMeta97 = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _path, _OMC_LIT11, _ty, _defaultValue, _foldName2, _resultName2, mmc_mk_some(_foldExpr2));
tmpMeta98 = mmc_mk_cons(_iter, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta99 = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta97, _expr, tmpMeta98);
_expr = tmpMeta99;
tmpMeta100 = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _path, _OMC_LIT11, _ty, _defaultValue, _foldName, _resultName, mmc_mk_some(_foldExpr));
tmpMeta101 = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta100, _expr, _iterators);
tmpMeta1 = tmpMeta101;
goto tmp3_done;
}
case 7: {
tmpMeta1 = _inReduction;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyRangeReal2(threadData_t *threadData, modelica_real _inStart, modelica_real _inStep, modelica_integer _inSteps, modelica_metatype _inValues)
{
modelica_metatype _outValues = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_integer tmp4_1;
tmp4_1 = _inSteps;
{
modelica_real _next;
modelica_metatype _vals = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (-1 != tmp4_1) goto tmp3_end;
tmpMeta1 = _inValues;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
_next = _inStart + (_inStep) * (((modelica_real)_inSteps));
tmpMeta6 = mmc_mk_cons(mmc_mk_real(_next), _inValues);
_vals = tmpMeta6;
_inSteps = ((modelica_integer) -1) + _inSteps;
_inValues = _vals;
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
_outValues = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValues;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyRangeReal2(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inStep, modelica_metatype _inSteps, modelica_metatype _inValues)
{
modelica_real tmp1;
modelica_real tmp2;
modelica_integer tmp3;
modelica_metatype _outValues = NULL;
tmp1 = mmc_unbox_real(_inStart);
tmp2 = mmc_unbox_real(_inStep);
tmp3 = mmc_unbox_integer(_inSteps);
_outValues = omc_ExpressionSimplify_simplifyRangeReal2(threadData, tmp1, tmp2, tmp3, _inValues);
return _outValues;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyRangeReal(threadData_t *threadData, modelica_real _inStart, modelica_real _inStep, modelica_real _inStop)
{
modelica_metatype _outValues = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_string _error_str = NULL;
modelica_integer _steps;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
tmp6 = (fabs(_inStep) <= 1e-14);
if (1 != tmp6) goto goto_2;
tmpMeta7 = mmc_mk_cons(mmc_mk_real(_inStart), mmc_mk_cons(mmc_mk_real(_inStep), mmc_mk_cons(mmc_mk_real(_inStop), MMC_REFSTRUCTLIT(mmc_nil))));
_error_str = stringDelimitList(omc_List_map(threadData, tmpMeta7, boxvar_realString), _OMC_LIT12);
tmpMeta8 = mmc_mk_cons(_error_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT15, tmpMeta8);
goto goto_2;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
equality(mmc_mk_real(_inStart), mmc_mk_real(_inStop));
tmpMeta9 = mmc_mk_cons(mmc_mk_real(_inStart), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
_steps = ((modelica_integer) -1) + omc_Util_realRangeSize(threadData, _inStart, _inStep, _inStop);
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ExpressionSimplify_simplifyRangeReal2(threadData, _inStart, _inStep, _steps, tmpMeta10);
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
_outValues = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outValues;
}
modelica_metatype boxptr_ExpressionSimplify_simplifyRangeReal(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inStep, modelica_metatype _inStop)
{
modelica_real tmp1;
modelica_real tmp2;
modelica_real tmp3;
modelica_metatype _outValues = NULL;
tmp1 = mmc_unbox_real(_inStart);
tmp2 = mmc_unbox_real(_inStep);
tmp3 = mmc_unbox_real(_inStop);
_outValues = omc_ExpressionSimplify_simplifyRangeReal(threadData, tmp1, tmp2, tmp3);
return _outValues;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyRange(threadData_t *threadData, modelica_integer _inStart, modelica_integer _inStep, modelica_integer _inStop)
{
modelica_metatype _outValues = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outValues = omc_List_intRange3(threadData, _inStart, _inStep, _inStop);
_return: OMC_LABEL_UNUSED
return _outValues;
}
modelica_metatype boxptr_ExpressionSimplify_simplifyRange(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inStep, modelica_metatype _inStop)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype _outValues = NULL;
tmp1 = mmc_unbox_integer(_inStart);
tmp2 = mmc_unbox_integer(_inStep);
tmp3 = mmc_unbox_integer(_inStop);
_outValues = omc_ExpressionSimplify_simplifyRange(threadData, tmp1, tmp2, tmp3);
return _outValues;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyRangeBool(threadData_t *threadData, modelica_boolean _inStart, modelica_boolean _inStop)
{
modelica_metatype _outRange = NULL;
modelica_metatype tmpMeta1;
modelica_boolean tmp2;
modelica_metatype tmpMeta3;
modelica_boolean tmp4;
modelica_metatype tmpMeta5;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp4 = (modelica_boolean)_inStart;
if(tmp4)
{
tmp2 = (modelica_boolean)_inStop;
if(tmp2)
{
tmpMeta3 = _OMC_LIT16;
}
else
{
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta3 = tmpMeta1;
}
tmpMeta5 = tmpMeta3;
}
else
{
tmpMeta5 = (_inStop?_OMC_LIT17:_OMC_LIT18);
}
_outRange = tmpMeta5;
_return: OMC_LABEL_UNUSED
return _outRange;
}
modelica_metatype boxptr_ExpressionSimplify_simplifyRangeBool(threadData_t *threadData, modelica_metatype _inStart, modelica_metatype _inStop)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outRange = NULL;
tmp1 = mmc_unbox_integer(_inStart);
tmp2 = mmc_unbox_integer(_inStop);
_outRange = omc_ExpressionSimplify_simplifyRangeBool(threadData, tmp1, tmp2);
return _outRange;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_removeOperatorDimension(threadData_t *threadData, modelica_metatype _inop)
{
modelica_metatype _outop = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inop;
{
modelica_metatype _ty1 = NULL;
modelica_metatype _ty2 = NULL;
modelica_boolean _b;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 10: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_boolean tmp8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ty1 = tmpMeta5;
_ty2 = omc_Expression_unliftArray(threadData, _ty1);
_b = omc_DAEUtil_expTypeArray(threadData, _ty2);
tmp8 = (modelica_boolean)_b;
if(tmp8)
{
tmpMeta6 = mmc_mk_box2(10, &DAE_Operator_ADD__ARR__desc, _ty2);
tmpMeta9 = tmpMeta6;
}
else
{
tmpMeta7 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty2);
tmpMeta9 = tmpMeta7;
}
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_boolean tmp13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ty1 = tmpMeta10;
_ty2 = omc_Expression_unliftArray(threadData, _ty1);
_b = omc_DAEUtil_expTypeArray(threadData, _ty2);
tmp13 = (modelica_boolean)_b;
if(tmp13)
{
tmpMeta11 = mmc_mk_box2(11, &DAE_Operator_SUB__ARR__desc, _ty2);
tmpMeta14 = tmpMeta11;
}
else
{
tmpMeta12 = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _ty2);
tmpMeta14 = tmpMeta12;
}
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ty1 = tmpMeta15;
_ty2 = omc_Expression_unliftArray(threadData, _ty1);
_b = omc_DAEUtil_expTypeArray(threadData, _ty2);
tmp18 = (modelica_boolean)_b;
if(tmp18)
{
tmpMeta16 = mmc_mk_box2(13, &DAE_Operator_DIV__ARR__desc, _ty2);
tmpMeta19 = tmpMeta16;
}
else
{
tmpMeta17 = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _ty2);
tmpMeta19 = tmpMeta17;
}
tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_boolean tmp23;
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ty1 = tmpMeta20;
_ty2 = omc_Expression_unliftArray(threadData, _ty1);
_b = omc_DAEUtil_expTypeArray(threadData, _ty2);
tmp23 = (modelica_boolean)_b;
if(tmp23)
{
tmpMeta21 = mmc_mk_box2(12, &DAE_Operator_MUL__ARR__desc, _ty2);
tmpMeta24 = tmpMeta21;
}
else
{
tmpMeta22 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty2);
tmpMeta24 = tmpMeta22;
}
tmpMeta1 = tmpMeta24;
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_boolean tmp28;
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,1) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ty1 = tmpMeta25;
_ty2 = omc_Expression_unliftArray(threadData, _ty1);
_b = omc_DAEUtil_expTypeArray(threadData, _ty2);
tmp28 = (modelica_boolean)_b;
if(tmp28)
{
tmpMeta26 = mmc_mk_box2(24, &DAE_Operator_POW__ARR2__desc, _ty2);
tmpMeta29 = tmpMeta26;
}
else
{
tmpMeta27 = mmc_mk_box2(7, &DAE_Operator_POW__desc, _ty2);
tmpMeta29 = tmpMeta27;
}
tmpMeta1 = tmpMeta29;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outop = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outop;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBuiltinConstantDer(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _dims = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT20;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT20;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,1,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_dims = tmpMeta8;
tmpMeta1 = omc_Expression_makeZeroExpression(threadData, _dims, NULL);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,6,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,0,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
_dims = tmpMeta11;
tmpMeta1 = omc_Expression_makeZeroExpression(threadData, _dims, NULL);
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinarySortConstantsMul(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype _e_lst = NULL;
modelica_metatype _e_lst_1 = NULL;
modelica_metatype _const_es1 = NULL;
modelica_metatype _const_es1_1 = NULL;
modelica_metatype _notconst_es1 = NULL;
modelica_metatype _res1 = NULL;
modelica_metatype _res2 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_e_lst = omc_Expression_factors(threadData, _inExp);
_const_es1 = omc_List_splitOnTrue(threadData, _e_lst, boxvar_Expression_isConst ,&_notconst_es1);
if((!listEmpty(_const_es1)))
{
_res1 = omc_ExpressionSimplify_simplifyBinaryMulConstants(threadData, _const_es1);
_res1 = omc_ExpressionSimplify_simplify1(threadData, _res1, NULL);
_res2 = omc_Expression_makeProductLst(threadData, _notconst_es1);
_outExp = omc_Expression_expMul(threadData, _res1, _res2);
}
else
{
_outExp = _inExp;
}
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorScalarMatrix(threadData_t *threadData, modelica_metatype _imexpl, modelica_metatype _op, modelica_metatype _s1, modelica_boolean _arrayScalar)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta10;
modelica_boolean tmp19;
modelica_metatype tmpMeta20;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp19 = (modelica_boolean)_arrayScalar;
if(tmp19)
{
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype __omcQ_24tmpVar6;
modelica_integer tmp9;
modelica_metatype _row_loopVar = 0;
modelica_metatype _row;
_row_loopVar = _imexpl;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar7;
while(1) {
tmp9 = 1;
if (!listEmpty(_row_loopVar)) {
_row = MMC_CAR(_row_loopVar);
_row_loopVar = MMC_CDR(_row_loopVar);
tmp9--;
}
if (tmp9 == 0) {
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype __omcQ_24tmpVar4;
modelica_integer tmp8;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _row;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta6;
tmp5 = &__omcQ_24tmpVar5;
while(1) {
tmp8 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp8--;
}
if (tmp8 == 0) {
tmpMeta7 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op, _s1);
__omcQ_24tmpVar4 = tmpMeta7;
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp8 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp5 = mmc_mk_nil();
tmpMeta4 = __omcQ_24tmpVar5;
}
__omcQ_24tmpVar6 = tmpMeta4;
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp9 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar7;
}
tmpMeta20 = tmpMeta1;
}
else
{
{
modelica_metatype __omcQ_24tmpVar11;
modelica_metatype* tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype __omcQ_24tmpVar10;
modelica_integer tmp18;
modelica_metatype _row_loopVar = 0;
modelica_metatype _row;
_row_loopVar = _imexpl;
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar11 = tmpMeta12;
tmp11 = &__omcQ_24tmpVar11;
while(1) {
tmp18 = 1;
if (!listEmpty(_row_loopVar)) {
_row = MMC_CAR(_row_loopVar);
_row_loopVar = MMC_CDR(_row_loopVar);
tmp18--;
}
if (tmp18 == 0) {
{
modelica_metatype __omcQ_24tmpVar9;
modelica_metatype* tmp14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype __omcQ_24tmpVar8;
modelica_integer tmp17;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _row;
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar9 = tmpMeta15;
tmp14 = &__omcQ_24tmpVar9;
while(1) {
tmp17 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp17--;
}
if (tmp17 == 0) {
tmpMeta16 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _s1, _op, _e);
__omcQ_24tmpVar8 = tmpMeta16;
*tmp14 = mmc_mk_cons(__omcQ_24tmpVar8,0);
tmp14 = &MMC_CDR(*tmp14);
} else if (tmp17 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp14 = mmc_mk_nil();
tmpMeta13 = __omcQ_24tmpVar9;
}
__omcQ_24tmpVar10 = tmpMeta13;
*tmp11 = mmc_mk_cons(__omcQ_24tmpVar10,0);
tmp11 = &MMC_CDR(*tmp11);
} else if (tmp18 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp11 = mmc_mk_nil();
tmpMeta10 = __omcQ_24tmpVar11;
}
tmpMeta20 = tmpMeta10;
}
_outExp = tmpMeta20;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyVectorScalarMatrix(threadData_t *threadData, modelica_metatype _imexpl, modelica_metatype _op, modelica_metatype _s1, modelica_metatype _arrayScalar)
{
modelica_integer tmp1;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_arrayScalar);
_outExp = omc_ExpressionSimplify_simplifyVectorScalarMatrix(threadData, _imexpl, _op, _s1, tmp1);
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyUnary(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOperator2, modelica_metatype _inExp3)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inOperator2;
tmp4_2 = _inExp3;
{
modelica_metatype _ty1 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_integer _i_1;
modelica_integer _i;
modelica_real _r_1;
modelica_real _r;
modelica_boolean _b1;
modelica_metatype _attr = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _mat = NULL;
modelica_metatype _op = NULL;
modelica_metatype _op2 = NULL;
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 20; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
_b1 = omc_Expression_toBool(threadData, _e1);
_b1 = (!_b1);
tmpMeta6 = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_b1));
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,10,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,24,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_e1 = tmpMeta8;
tmp4 += 17;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
_i = tmp10;
tmp4 += 3;
_i_1 = (-_i);
tmpMeta11 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i_1));
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta12;
modelica_real tmp13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp13 = mmc_unbox_real(tmpMeta12);
_r = tmp13;
tmp4 += 2;
_r_1 = (-_r);
tmpMeta14 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r_1));
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,2,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_op2 = tmp4_1;
_e1 = tmpMeta15;
_op = tmpMeta16;
_e2 = tmpMeta17;
tmp4 += 1;
tmpMeta18 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e1);
tmpMeta19 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta18, _op, _e2);
tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,9,1) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_op2 = tmp4_1;
_e1 = tmpMeta20;
_op = tmpMeta21;
_e2 = tmpMeta22;
tmp4 += 1;
tmpMeta23 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e1);
tmpMeta24 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta23, _op, _e2);
tmpMeta1 = tmpMeta24;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
tmp4 += 1;
if (!omc_Expression_isZero(threadData, _e1)) goto tmp3_end;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
tmp4 += 1;
if (!omc_Expression_isZero(threadData, _e1)) goto tmp3_end;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,1,1) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e1 = tmpMeta25;
_op = tmpMeta26;
_e2 = tmpMeta27;
tmp4 += 10;
tmpMeta28 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op, _e1);
tmpMeta1 = tmpMeta28;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta30,8,1) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e1 = tmpMeta29;
_op = tmpMeta30;
_e2 = tmpMeta31;
tmp4 += 9;
tmpMeta32 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op, _e1);
tmpMeta1 = tmpMeta32;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_boolean tmp36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,0,1) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_op2 = tmp4_1;
_e1 = tmpMeta33;
_op = tmpMeta34;
_e2 = tmpMeta35;
tmp4 += 8;
tmpMeta37 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e1);
tmpMeta38 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e2);
tmpMeta39 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta37, _op, tmpMeta38);
tmpMeta40 = omc_ExpressionSimplify_simplify1(threadData, tmpMeta39, &tmp36);
_e_1 = tmpMeta40;
if (1 != tmp36) goto goto_2;
tmpMeta1 = _e_1;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta42,7,1) == 0) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_op2 = tmp4_1;
_e1 = tmpMeta41;
_op = tmpMeta42;
_e2 = tmpMeta43;
tmp4 += 7;
tmpMeta44 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e1);
tmpMeta45 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e2);
tmpMeta46 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta44, _op, tmpMeta45);
tmpMeta1 = tmpMeta46;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta48,3,1) == 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_op2 = tmp4_1;
_e1 = tmpMeta47;
_op = tmpMeta48;
_e2 = tmpMeta49;
tmp4 += 6;
tmpMeta50 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e1);
tmpMeta51 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta50, _op, _e2);
tmpMeta1 = tmpMeta51;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta53,10,1) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_op2 = tmp4_1;
_e1 = tmpMeta52;
_op = tmpMeta53;
_e2 = tmpMeta54;
tmp4 += 5;
tmpMeta55 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e1);
tmpMeta56 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta55, _op, _e2);
tmpMeta1 = tmpMeta56;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,8,2) == 0) goto tmp3_end;
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta57,5,1) == 0) goto tmp3_end;
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_e1 = tmpMeta58;
tmp4 += 4;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,8,2) == 0) goto tmp3_end;
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta59,6,1) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_e1 = tmpMeta60;
tmp4 += 3;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 16: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta61,1,1) == 0) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta61), 2));
if (10 != MMC_STRLEN(tmpMeta62) || strcmp(MMC_STRINGDATA(_OMC_LIT21), MMC_STRINGDATA(tmpMeta62)) != 0) goto tmp3_end;
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta63)) goto tmp3_end;
tmpMeta64 = MMC_CAR(tmpMeta63);
tmpMeta65 = MMC_CDR(tmpMeta63);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta64,8,2) == 0) goto tmp3_end;
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta64), 3));
if (listEmpty(tmpMeta65)) goto tmp3_end;
tmpMeta67 = MMC_CAR(tmpMeta65);
tmpMeta68 = MMC_CDR(tmpMeta65);
if (listEmpty(tmpMeta68)) goto tmp3_end;
tmpMeta69 = MMC_CAR(tmpMeta68);
tmpMeta70 = MMC_CDR(tmpMeta68);
if (!listEmpty(tmpMeta70)) goto tmp3_end;
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_path = tmpMeta61;
_e1 = tmpMeta66;
_e2 = tmpMeta67;
_e3 = tmpMeta69;
_attr = tmpMeta71;
tmp4 += 2;
tmpMeta72 = mmc_mk_cons(_e1, mmc_mk_cons(_e3, mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta73 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _path, tmpMeta72, _attr);
tmpMeta1 = tmpMeta73;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_integer tmp76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,3) == 0) goto tmp3_end;
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp76 = mmc_unbox_integer(tmpMeta75);
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_ty1 = tmpMeta74;
_b1 = tmp76;
_expl = tmpMeta77;
tmp4 += 1;
_expl = omc_List_map(threadData, _expl, boxvar_Expression_negate);
tmpMeta78 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _ty1, mmc_mk_boolean(_b1), _expl);
tmpMeta1 = tmpMeta78;
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta79;
modelica_metatype tmpMeta80;
modelica_integer tmp81;
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,17,3) == 0) goto tmp3_end;
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta80 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp81 = mmc_unbox_integer(tmpMeta80);
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_ty1 = tmpMeta79;
_i = tmp81;
_mat = tmpMeta82;
_mat = omc_List_mapList(threadData, _mat, boxvar_Expression_negate);
tmpMeta83 = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _ty1, mmc_mk_integer(_i), _mat);
tmpMeta1 = tmpMeta83;
goto tmp3_done;
}
case 19: {
tmpMeta1 = _origExp;
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
if (++tmp4 < 20) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryDistributePow(threadData_t *threadData, modelica_metatype _inExpLst, modelica_metatype _inExp)
{
modelica_metatype _outExpLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar13;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype __omcQ_24tmpVar12;
modelica_integer tmp6;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inExpLst;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar13 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar13;
while(1) {
tmp6 = 1;
while (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
if ((!omc_Expression_isConstOne(threadData, _e))) {
tmp6--;
break;
}
}
if (tmp6 == 0) {
tmpMeta4 = mmc_mk_box2(7, &DAE_Operator_POW__desc, omc_Expression_typeof(threadData, _e));
tmpMeta5 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, tmpMeta4, _inExp);
__omcQ_24tmpVar12 = tmpMeta5;
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar12,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp6 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar13;
}
_outExpLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExpLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyRelation2(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOp, modelica_metatype _lhs, modelica_metatype _rhs, modelica_integer _index, modelica_metatype _optionExpisASUB, modelica_fnptr _isPositive)
{
modelica_metatype _oExp = NULL;
modelica_boolean _b;
modelica_metatype _tp = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_oExp = omc_Expression_expSub(threadData, _lhs, _rhs);
_oExp = omc_ExpressionSimplify_simplify(threadData, _oExp ,&_b);
if((omc_Expression_isGreatereqOrLesseq(threadData, _inOp) && mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_isPositive), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_isPositive), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_isPositive), 2))), _oExp) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_isPositive), 1)))) (threadData, _oExp))))
{
_oExp = _OMC_LIT23;
}
else
{
if(omc_Expression_isGreatereqOrLesseq(threadData, _inOp))
{
_oExp = _origExp;
}
else
{
_oExp = omc_Expression_negate(threadData, _oExp);
_oExp = omc_ExpressionSimplify_simplify(threadData, _oExp, NULL);
_oExp = (mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_isPositive), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_isPositive), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_isPositive), 2))), _oExp) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_isPositive), 1)))) (threadData, _oExp))?_OMC_LIT22:_origExp);
}
}
_return: OMC_LABEL_UNUSED
return _oExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyRelation2(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOp, modelica_metatype _lhs, modelica_metatype _rhs, modelica_metatype _index, modelica_metatype _optionExpisASUB, modelica_fnptr _isPositive)
{
modelica_integer tmp1;
modelica_metatype _oExp = NULL;
tmp1 = mmc_unbox_integer(_index);
_oExp = omc_ExpressionSimplify_simplifyRelation2(threadData, _origExp, _inOp, _lhs, _rhs, tmp1, _optionExpisASUB, _isPositive);
return _oExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyRelation(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOperator2, modelica_metatype _inExp3, modelica_metatype _inExp4, modelica_integer _index, modelica_metatype _optionExpisASUB)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inOperator2;
tmp4_2 = _inExp3;
tmp4_3 = _inExp4;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _oper = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 8; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
modelica_boolean tmp7;
modelica_metatype tmpMeta8;
_oper = tmp4_1;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmp6 = omc_Expression_isConstValue(threadData, _e1);
if (1 != tmp6) goto goto_2;
tmp7 = omc_Expression_isConstValue(threadData, _e2);
if (1 != tmp7) goto goto_2;
_b = omc_ExpressionSimplify_simplifyRelationConst(threadData, _oper, _e1, _e2);
tmpMeta8 = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_b));
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,29,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,6,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_cr1 = tmpMeta9;
_cr2 = tmpMeta10;
tmp4 += 5;
tmp11 = omc_ComponentReference_crefEqual(threadData, _cr1, _cr2);
if (1 != tmp11) goto goto_2;
tmpMeta1 = _OMC_LIT23;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_boolean tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,30,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,6,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_cr1 = tmpMeta12;
_cr2 = tmpMeta13;
tmp4 += 4;
tmp14 = omc_ComponentReference_crefEqual(threadData, _cr1, _cr2);
if (1 != tmp14) goto goto_2;
tmpMeta1 = _OMC_LIT22;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,28,1) == 0) goto tmp3_end;
tmp4 += 3;
tmpMeta1 = omc_ExpressionSimplify_simplifyRelation2(threadData, _origExp, _inOperator2, _inExp3, _inExp4, _index, _optionExpisASUB, boxvar_Expression_isPositiveOrZero);
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,1) == 0) goto tmp3_end;
tmp4 += 2;
tmpMeta1 = omc_ExpressionSimplify_simplifyRelation2(threadData, _origExp, _inOperator2, _inExp3, _inExp4, _index, _optionExpisASUB, boxvar_Expression_isPositiveOrZero);
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,26,1) == 0) goto tmp3_end;
tmp4 += 1;
tmpMeta1 = omc_ExpressionSimplify_simplifyRelation2(threadData, _origExp, _inOperator2, _inExp4, _inExp3, _index, _optionExpisASUB, boxvar_Expression_isPositiveOrZero);
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,25,1) == 0) goto tmp3_end;
tmpMeta1 = omc_ExpressionSimplify_simplifyRelation2(threadData, _origExp, _inOperator2, _inExp4, _inExp3, _index, _optionExpisASUB, boxvar_Expression_isPositiveOrZero);
goto tmp3_done;
}
case 7: {
tmpMeta1 = _origExp;
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyRelation(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOperator2, modelica_metatype _inExp3, modelica_metatype _inExp4, modelica_metatype _index, modelica_metatype _optionExpisASUB)
{
modelica_integer tmp1;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_index);
_outExp = omc_ExpressionSimplify_simplifyRelation(threadData, _origExp, _inOperator2, _inExp3, _inExp4, tmp1, _optionExpisASUB);
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyLBinary(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOperator2, modelica_metatype _inExp3, modelica_metatype _inExp4)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inOperator2;
tmp4_2 = _inExp3;
tmp4_3 = _inExp4;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 13; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta1 = _origExp;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,16,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta1 = _origExp;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,10,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,24,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_e2 = tmpMeta10;
_e1 = tmp4_2;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta1 = _OMC_LIT22;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,10,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,24,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_e1 = tmpMeta13;
_e2 = tmp4_3;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta1 = _OMC_LIT22;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,10,2) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,24,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_e2 = tmpMeta16;
_e1 = tmp4_2;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta1 = _OMC_LIT23;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,10,2) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,24,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_e1 = tmpMeta19;
_e2 = tmp4_3;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta1 = _OMC_LIT23;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta20;
modelica_integer tmp21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp21 = mmc_unbox_integer(tmpMeta20);
_e1 = tmp4_2;
_b = tmp21;
_e2 = tmp4_3;
tmpMeta1 = (_b?_e2:_e1);
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta22;
modelica_integer tmp23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp23 = mmc_unbox_integer(tmpMeta22);
_e2 = tmp4_3;
_b = tmp23;
_e1 = tmp4_2;
tmpMeta1 = (_b?_e1:_e2);
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta24;
modelica_integer tmp25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp25 = mmc_unbox_integer(tmpMeta24);
_e1 = tmp4_2;
_b = tmp25;
_e2 = tmp4_3;
tmpMeta1 = (_b?_e1:_e2);
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta26;
modelica_integer tmp27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp27 = mmc_unbox_integer(tmpMeta26);
_e2 = tmp4_3;
_b = tmp27;
_e1 = tmp4_2;
tmpMeta1 = (_b?_e2:_e1);
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,22,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
_e2 = tmp4_3;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
_e2 = tmp4_3;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 12: {
tmpMeta1 = _origExp;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyTwoBinaryExpressions(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _lhsOperator, modelica_metatype _e2, modelica_metatype _mainOperator, modelica_metatype _e3, modelica_metatype _rhsOperator, modelica_metatype _e4, modelica_boolean _expEqual_e1_e3, modelica_boolean _expEqual_e1_e4, modelica_boolean _expEqual_e2_e3, modelica_boolean _expEqual_e2_e4, modelica_boolean _isConst_e1, modelica_boolean _isConst_e2, modelica_boolean _isConst_e3, modelica_boolean _operatorEqualLhsRhs)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;modelica_metatype tmp4_4;modelica_metatype tmp4_5;modelica_metatype tmp4_6;modelica_metatype tmp4_7;modelica_boolean tmp4_8;modelica_boolean tmp4_9;modelica_boolean tmp4_10;modelica_boolean tmp4_11;modelica_boolean tmp4_12;modelica_boolean tmp4_13;modelica_boolean tmp4_14;
tmp4_1 = _e1;
tmp4_2 = _lhsOperator;
tmp4_3 = _e2;
tmp4_4 = _mainOperator;
tmp4_5 = _e3;
tmp4_6 = _rhsOperator;
tmp4_7 = _e4;
tmp4_8 = _expEqual_e1_e3;
tmp4_9 = _expEqual_e1_e4;
tmp4_10 = _expEqual_e2_e3;
tmp4_11 = _expEqual_e2_e4;
tmp4_12 = _isConst_e1;
tmp4_13 = _isConst_e2;
tmp4_14 = _operatorEqualLhsRhs;
{
modelica_metatype _e1_1 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _e_2 = NULL;
modelica_metatype _e_3 = NULL;
modelica_metatype _e_4 = NULL;
modelica_metatype _e_5 = NULL;
modelica_metatype _e_6 = NULL;
modelica_metatype _res = NULL;
modelica_metatype _one = NULL;
modelica_metatype _op1 = NULL;
modelica_metatype _op2 = NULL;
modelica_metatype _op3 = NULL;
modelica_metatype _op = NULL;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 17; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (1 != tmp4_8) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,1) == 0) goto tmp3_end;
_op2 = tmp4_2;
_op1 = tmp4_4;
tmpMeta6 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e4);
tmpMeta7 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, tmpMeta6);
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (1 != tmp4_9) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,1) == 0) goto tmp3_end;
_op2 = tmp4_2;
_op1 = tmp4_4;
tmpMeta8 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
tmpMeta9 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, tmpMeta8);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (1 != tmp4_10) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,1) == 0) goto tmp3_end;
_op2 = tmp4_2;
_op1 = tmp4_4;
tmpMeta10 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e4);
tmpMeta11 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op2, tmpMeta10);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (1 != tmp4_11) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,1) == 0) goto tmp3_end;
_op2 = tmp4_2;
_op1 = tmp4_4;
tmpMeta12 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e3);
tmpMeta13 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op2, tmpMeta12);
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (1 != tmp4_11) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,4,1) == 0) goto tmp3_end;
tmpMeta14 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _mainOperator, _e3);
tmpMeta15 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta14, _lhsOperator, _e2);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (1 != tmp4_11) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,4,1) == 0) goto tmp3_end;
tmpMeta16 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _mainOperator, _e3);
tmpMeta17 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta16, _lhsOperator, _e2);
tmpMeta1 = tmpMeta17;
goto tmp3_done;
}
case 6: {
if (1 != tmp4_8) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,4,1) == 0) goto tmp3_end;
_res = omc_Expression_expAdd(threadData, _e2, _e4);
tmpMeta1 = omc_Expression_expPow(threadData, _e1, _res);
goto tmp3_done;
}
case 7: {
if (1 != tmp4_8) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,4,1) == 0) goto tmp3_end;
_res = omc_Expression_expSub(threadData, _e2, _e4);
tmpMeta1 = omc_Expression_expPow(threadData, _e1, _res);
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (1 != tmp4_11) goto tmp3_end;
if (0 != tmp4_13) goto tmp3_end;
if (1 != tmp4_14) goto tmp3_end;
_op2 = tmp4_2;
_op1 = tmp4_4;
if (!(omc_Expression_isAddOrSub(threadData, _op1) && omc_Expression_isMulOrDiv(threadData, _op2))) goto tmp3_end;
tmpMeta18 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e3);
tmpMeta19 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta18, _op2, _e4);
tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (1 != tmp4_8) goto tmp3_end;
if (0 != tmp4_12) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,3,1) == 0) goto tmp3_end;
_op = tmp4_2;
_ty = tmpMeta20;
_op1 = tmp4_4;
if (!omc_Expression_isAddOrSub(threadData, _op1)) goto tmp3_end;
_one = omc_Expression_makeConstOne(threadData, _ty);
_e = omc_Expression_makeDiv(threadData, _one, _e4);
tmpMeta21 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e);
tmpMeta22 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta21, _op, _e1);
tmpMeta1 = tmpMeta22;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (1 != tmp4_8) goto tmp3_end;
if (0 != tmp4_12) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,1) == 0) goto tmp3_end;
_ty = tmpMeta23;
_op1 = tmp4_4;
if (!omc_Expression_isAddOrSub(threadData, _op1)) goto tmp3_end;
_one = omc_Expression_makeConstOne(threadData, _ty);
_e = omc_Expression_makeDiv(threadData, _one, _e2);
tmpMeta24 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op1, _e4);
tmpMeta25 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta26 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta24, tmpMeta25, _e1);
tmpMeta1 = tmpMeta26;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (1 != tmp4_11) goto tmp3_end;
if (0 != tmp4_13) goto tmp3_end;
if (1 != tmp4_14) goto tmp3_end;
_e1_1 = tmp4_1;
_op2 = tmp4_2;
_e_3 = tmp4_3;
_op1 = tmp4_4;
_e = tmp4_5;
if (!(omc_Expression_isAddOrSub(threadData, _op1) && omc_Expression_isMulOrDiv(threadData, _op2))) goto tmp3_end;
tmpMeta27 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op1, _e);
_res = tmpMeta27;
tmpMeta28 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _res, _op2, _e_3);
tmpMeta1 = tmpMeta28;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
_e_1 = tmpMeta29;
_op2 = tmpMeta30;
_e_2 = tmpMeta31;
_op = tmp4_2;
_e_3 = tmp4_3;
_op1 = tmp4_4;
_e = tmp4_5;
_op3 = tmp4_6;
_e_6 = tmp4_7;
if (!(((((!omc_Expression_isConstValue(threadData, _e_2)) && omc_Expression_expEqual(threadData, _e_2, _e_6)) && omc_Expression_operatorEqual(threadData, _op2, _op3)) && omc_Expression_isAddOrSub(threadData, _op1)) && omc_Expression_isMulOrDiv(threadData, _op2))) goto tmp3_end;
tmpMeta32 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e_1, _op, _e_3);
_e1_1 = tmpMeta32;
tmpMeta33 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op1, _e);
_res = tmpMeta33;
tmpMeta34 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _res, _op2, _e_2);
tmpMeta1 = tmpMeta34;
goto tmp3_done;
}
case 13: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_5,7,3) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_5), 2));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_5), 3));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_5), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,1) == 0) goto tmp3_end;
_e_1 = tmpMeta35;
_op2 = tmpMeta36;
_e_2 = tmpMeta37;
_op = tmp4_2;
_e_4 = tmpMeta38;
_op3 = tmpMeta39;
_e_5 = tmpMeta40;
_e_3 = tmp4_3;
_op1 = tmp4_4;
_e_6 = tmp4_7;
if (!(((((!omc_Expression_isConstValue(threadData, _e_2)) && omc_Expression_expEqual(threadData, _e_2, _e_5)) && omc_Expression_operatorEqual(threadData, _op2, _op3)) && omc_Expression_isAddOrSub(threadData, _op1)) && omc_Expression_isMulOrDiv(threadData, _op2))) goto tmp3_end;
tmpMeta41 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e_1, _op, _e_3);
_e1_1 = tmpMeta41;
tmpMeta42 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e_4, _op, _e_6);
_e = tmpMeta42;
tmpMeta43 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op1, _e);
_res = tmpMeta43;
tmpMeta44 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _res, _op2, _e_2);
tmpMeta1 = tmpMeta44;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
if (0 != tmp4_13) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_5,7,3) == 0) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_5), 2));
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_5), 3));
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_5), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,1) == 0) goto tmp3_end;
_e_4 = tmpMeta45;
_op3 = tmpMeta46;
_e_5 = tmpMeta47;
_op = tmp4_6;
_e_1 = tmp4_1;
_op2 = tmp4_2;
_e_3 = tmp4_3;
_op1 = tmp4_4;
_e_6 = tmp4_7;
if (!(((omc_Expression_expEqual(threadData, _e_3, _e_5) && omc_Expression_operatorEqual(threadData, _op2, _op3)) && omc_Expression_isAddOrSub(threadData, _op1)) && omc_Expression_isMulOrDiv(threadData, _op2))) goto tmp3_end;
tmpMeta48 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e_4, _op, _e_6);
_e = tmpMeta48;
tmpMeta49 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e_1, _op1, _e);
_res = tmpMeta49;
tmpMeta50 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _res, _op2, _e_3);
tmpMeta1 = tmpMeta50;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
if (1 != tmp4_8) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,1) == 0) goto tmp3_end;
tmpMeta51 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _mainOperator, _e4);
tmpMeta52 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _lhsOperator, tmpMeta51);
tmpMeta1 = tmpMeta52;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
if (1 != tmp4_9) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_4,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_6,2,1) == 0) goto tmp3_end;
tmpMeta53 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _mainOperator, _e3);
tmpMeta54 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _lhsOperator, tmpMeta53);
tmpMeta1 = tmpMeta54;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyTwoBinaryExpressions(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _lhsOperator, modelica_metatype _e2, modelica_metatype _mainOperator, modelica_metatype _e3, modelica_metatype _rhsOperator, modelica_metatype _e4, modelica_metatype _expEqual_e1_e3, modelica_metatype _expEqual_e1_e4, modelica_metatype _expEqual_e2_e3, modelica_metatype _expEqual_e2_e4, modelica_metatype _isConst_e1, modelica_metatype _isConst_e2, modelica_metatype _isConst_e3, modelica_metatype _operatorEqualLhsRhs)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
modelica_integer tmp8;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_expEqual_e1_e3);
tmp2 = mmc_unbox_integer(_expEqual_e1_e4);
tmp3 = mmc_unbox_integer(_expEqual_e2_e3);
tmp4 = mmc_unbox_integer(_expEqual_e2_e4);
tmp5 = mmc_unbox_integer(_isConst_e1);
tmp6 = mmc_unbox_integer(_isConst_e2);
tmp7 = mmc_unbox_integer(_isConst_e3);
tmp8 = mmc_unbox_integer(_operatorEqualLhsRhs);
_outExp = omc_ExpressionSimplify_simplifyTwoBinaryExpressions(threadData, _e1, _lhsOperator, _e2, _mainOperator, _e3, _rhsOperator, _e4, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8);
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinary(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inOperator2, modelica_metatype _lhs, modelica_metatype _rhs)
{
modelica_metatype _outExp = NULL;
modelica_boolean _lhsIsConstValue;
modelica_boolean _rhsIsConstValue;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_lhsIsConstValue = omc_Expression_isConstValue(threadData, _lhs);
_rhsIsConstValue = omc_Expression_isConstValue(threadData, _rhs);
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_boolean tmp4_4;volatile modelica_boolean tmp4_5;
tmp4_1 = _inOperator2;
tmp4_2 = _lhs;
tmp4_3 = _rhs;
tmp4_4 = _lhsIsConstValue;
tmp4_5 = _rhsIsConstValue;
{
modelica_metatype _e1_1 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e4 = NULL;
modelica_metatype _e5 = NULL;
modelica_metatype _e6 = NULL;
modelica_metatype _res = NULL;
modelica_metatype _one = NULL;
modelica_metatype _oper = NULL;
modelica_metatype _op1 = NULL;
modelica_metatype _op2 = NULL;
modelica_metatype _op3 = NULL;
modelica_metatype _op = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _ty2 = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _tp2 = NULL;
modelica_metatype _exp_lst = NULL;
modelica_metatype _exp_lst_1 = NULL;
modelica_boolean _b;
modelica_boolean _b2;
modelica_real _r;
modelica_real _r1;
modelica_metatype _oexp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 85; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_op = tmp4_1;
_e1 = tmp4_2;
_e2 = tmp4_3;
if (!omc_ExpressionSimplify_simplifyBinaryArrayOp(threadData, _op)) goto tmp3_end;
tmpMeta1 = omc_ExpressionSimplify_simplifyBinaryArray(threadData, _e1, _op, _e2);
goto tmp3_done;
}
case 1: {
_op = tmp4_1;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmpMeta1 = omc_ExpressionSimplify_simplifyBinaryCommutativeWork(threadData, _op, _e1, _e2);
goto tmp3_done;
}
case 2: {
_op = tmp4_1;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmpMeta1 = omc_ExpressionSimplify_simplifyBinaryCommutativeWork(threadData, _op, _e2, _e1);
goto tmp3_done;
}
case 3: {
if (1 != tmp4_4) goto tmp3_end;
if (1 != tmp4_5) goto tmp3_end;
_oper = tmp4_1;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmpMeta1 = omc_ExpressionSimplify_simplifyBinaryConst(threadData, _oper, _e1, _e2);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_e1 = tmpMeta6;
_op1 = tmpMeta7;
_e2 = tmpMeta8;
_e3 = tmpMeta9;
_op2 = tmpMeta10;
_e4 = tmpMeta11;
_oper = tmp4_1;
tmpMeta1 = omc_ExpressionSimplify_simplifyTwoBinaryExpressions(threadData, _e1, _op1, _e2, _oper, _e3, _op2, _e4, omc_Expression_expEqual(threadData, _e1, _e3), omc_Expression_expEqual(threadData, _e1, _e4), omc_Expression_expEqual(threadData, _e2, _e3), omc_Expression_expEqual(threadData, _e2, _e4), omc_Expression_isConstValue(threadData, _e1), omc_Expression_isConstValue(threadData, _e2), omc_Expression_isConstValue(threadData, _e3), omc_Expression_operatorEqual(threadData, _op1, _op2));
goto tmp3_done;
}
case 5: {
modelica_boolean tmp12;
_oper = tmp4_1;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmp12 = (omc_Expression_isConstZeroLength(threadData, _e1) || omc_Expression_isConstZeroLength(threadData, _e2));
if (1 != tmp12) goto goto_2;
omc_ExpressionSimplify_checkZeroLengthArrayOp(threadData, _oper);
tmpMeta1 = _e1;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,4,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,8,2) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,5,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
_e2 = tmpMeta13;
_op1 = tmpMeta14;
_ty2 = tmpMeta15;
_e3 = tmpMeta18;
_e1 = tmp4_2;
tmp4 += 32;
tmpMeta19 = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _ty2);
tmpMeta20 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
tmpMeta21 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta19, tmpMeta20);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,4,1) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,8,2) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,5,1) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 3));
_e2 = tmpMeta22;
_op1 = tmpMeta23;
_ty2 = tmpMeta24;
_e3 = tmpMeta27;
_e1 = tmp4_2;
tmp4 += 2;
tmpMeta28 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty2);
tmpMeta29 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
tmpMeta30 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta28, tmpMeta29);
tmpMeta1 = tmpMeta30;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_real tmp36;
modelica_boolean tmp37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta32,4,1) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,1,1) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 2));
tmp36 = mmc_unbox_real(tmpMeta35);
_e2 = tmpMeta31;
_op1 = tmpMeta32;
_ty2 = tmpMeta33;
_r = tmp36;
_e1 = tmp4_2;
tmp4 += 30;
tmp37 = (_r < 0.0);
if (1 != tmp37) goto goto_2;
_r = (-_r);
tmpMeta38 = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _ty2);
tmpMeta39 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta40 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, tmpMeta39);
tmpMeta41 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta38, tmpMeta40);
tmpMeta1 = tmpMeta41;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_real tmp47;
modelica_boolean tmp48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta43,4,1) == 0) goto tmp3_end;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta43), 2));
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta45,1,1) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 2));
tmp47 = mmc_unbox_real(tmpMeta46);
_e2 = tmpMeta42;
_op1 = tmpMeta43;
_ty2 = tmpMeta44;
_r = tmp47;
_e1 = tmp4_2;
tmp48 = (_r < 0.0);
if (1 != tmp48) goto goto_2;
_r = (-_r);
tmpMeta49 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty2);
tmpMeta50 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta51 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, tmpMeta50);
tmpMeta52 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta49, tmpMeta51);
tmpMeta1 = tmpMeta52;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_boolean tmp59;
modelica_boolean tmp60;
modelica_metatype tmpMeta61;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta53,7,3) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta53), 2));
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta53), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta55,2,1) == 0) goto tmp3_end;
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta53), 4));
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e1 = tmpMeta54;
_e2 = tmpMeta56;
_op1 = tmpMeta57;
_e3 = tmpMeta58;
_e4 = tmp4_3;
tmp59 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp59) goto goto_2;
tmp60 = omc_Expression_expEqual(threadData, _e2, _e4);
if (1 != tmp60) goto goto_2;
_e = omc_Expression_makeDiv(threadData, _e3, _e4);
tmpMeta61 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e);
tmpMeta1 = tmpMeta61;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_boolean tmp68;
modelica_boolean tmp69;
modelica_metatype tmpMeta70;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta64,7,3) == 0) goto tmp3_end;
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta64), 2));
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta64), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta66,2,1) == 0) goto tmp3_end;
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta64), 4));
_e3 = tmpMeta62;
_op1 = tmpMeta63;
_e1 = tmpMeta65;
_e2 = tmpMeta67;
_e4 = tmp4_3;
tmp68 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp68) goto goto_2;
tmp69 = omc_Expression_expEqual(threadData, _e2, _e4);
if (1 != tmp69) goto goto_2;
_e = omc_Expression_makeDiv(threadData, _e3, _e4);
tmpMeta70 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op1, _e1);
tmpMeta1 = tmpMeta70;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_boolean tmp80;
modelica_boolean tmp81;
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta71,7,3) == 0) goto tmp3_end;
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta71), 2));
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta71), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta73,2,1) == 0) goto tmp3_end;
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta71), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta74,7,3) == 0) goto tmp3_end;
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 2));
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta76,2,1) == 0) goto tmp3_end;
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 4));
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e1 = tmpMeta72;
_op2 = tmpMeta73;
_e2 = tmpMeta75;
_e3 = tmpMeta77;
_op1 = tmpMeta78;
_e4 = tmpMeta79;
_e5 = tmp4_3;
tmp4 += 1;
tmp80 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp80) goto goto_2;
tmp81 = omc_Expression_expEqual(threadData, _e3, _e5);
if (1 != tmp81) goto goto_2;
_e = omc_Expression_makeDiv(threadData, _e4, _e3);
tmpMeta82 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e2);
_e1_1 = tmpMeta82;
tmpMeta83 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op1, _e);
tmpMeta1 = tmpMeta83;
goto tmp3_done;
}
case 13: {
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
modelica_boolean tmp94;
modelica_metatype tmpMeta95;
modelica_metatype tmpMeta96;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta84,1,1) == 0) goto tmp3_end;
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta84), 2));
if (3 != MMC_STRLEN(tmpMeta85) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmpMeta85)) != 0) goto tmp3_end;
tmpMeta86 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta86)) goto tmp3_end;
tmpMeta87 = MMC_CAR(tmpMeta86);
tmpMeta88 = MMC_CDR(tmpMeta86);
if (!listEmpty(tmpMeta88)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta89 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta89,1,1) == 0) goto tmp3_end;
tmpMeta90 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta89), 2));
if (3 != MMC_STRLEN(tmpMeta90) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmpMeta90)) != 0) goto tmp3_end;
tmpMeta91 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta91)) goto tmp3_end;
tmpMeta92 = MMC_CAR(tmpMeta91);
tmpMeta93 = MMC_CDR(tmpMeta91);
if (!listEmpty(tmpMeta93)) goto tmp3_end;
_e1 = tmpMeta87;
_e2 = tmpMeta92;
_op2 = tmp4_1;
tmp4 += 14;
tmp94 = omc_Expression_isMulOrDiv(threadData, _op2);
if (1 != tmp94) goto goto_2;
_ty = omc_Expression_typeof(threadData, _e1);
tmpMeta95 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e2);
_res = tmpMeta95;
tmpMeta96 = mmc_mk_cons(_res, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT24, tmpMeta96, _ty);
goto tmp3_done;
}
case 14: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta97 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta98 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta98,1,1) == 0) goto tmp3_end;
tmpMeta99 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta98), 2));
if (3 != MMC_STRLEN(tmpMeta99) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta99)) != 0) goto tmp3_end;
tmpMeta100 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta100)) goto tmp3_end;
tmpMeta101 = MMC_CAR(tmpMeta100);
tmpMeta102 = MMC_CDR(tmpMeta100);
if (!listEmpty(tmpMeta102)) goto tmp3_end;
_ty = tmpMeta97;
_e2 = tmpMeta101;
_e1 = tmp4_2;
tmp4 += 1;
tmpMeta103 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _ty);
tmpMeta104 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta103, _e2);
_e = tmpMeta104;
_e = omc_ExpressionSimplify_simplify1(threadData, _e, NULL);
tmpMeta105 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT25, tmpMeta105, _ty);
tmpMeta106 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta107 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta106, _e3);
tmpMeta1 = tmpMeta107;
goto tmp3_done;
}
case 15: {
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
modelica_boolean tmp119;
modelica_metatype tmpMeta120;
modelica_metatype tmpMeta121;
modelica_metatype tmpMeta122;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta108 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta109 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta109,1,1) == 0) goto tmp3_end;
tmpMeta110 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta109), 2));
if (3 != MMC_STRLEN(tmpMeta110) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta110)) != 0) goto tmp3_end;
tmpMeta111 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta111)) goto tmp3_end;
tmpMeta112 = MMC_CAR(tmpMeta111);
tmpMeta113 = MMC_CDR(tmpMeta111);
if (!listEmpty(tmpMeta113)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta114 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta114,1,1) == 0) goto tmp3_end;
tmpMeta115 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta114), 2));
if (3 != MMC_STRLEN(tmpMeta115) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta115)) != 0) goto tmp3_end;
tmpMeta116 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta116)) goto tmp3_end;
tmpMeta117 = MMC_CAR(tmpMeta116);
tmpMeta118 = MMC_CDR(tmpMeta116);
if (!listEmpty(tmpMeta118)) goto tmp3_end;
_ty = tmpMeta108;
_e1 = tmpMeta112;
_e2 = tmpMeta117;
tmp4 += 23;
tmp119 = (omc_Expression_isConstValue(threadData, _e1) || omc_Expression_isConstValue(threadData, _e2));
if (0 != tmp119) goto goto_2;
tmpMeta120 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta121 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta120, _e2);
_e = tmpMeta121;
tmpMeta122 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT25, tmpMeta122, _ty);
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta123;
modelica_metatype tmpMeta124;
modelica_metatype tmpMeta125;
modelica_metatype tmpMeta126;
modelica_metatype tmpMeta127;
modelica_boolean tmp128;
modelica_metatype tmpMeta129;
if (1 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta123 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta124 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta124,0,1) == 0) goto tmp3_end;
tmpMeta125 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_op1 = tmp4_1;
_e1 = tmpMeta123;
_op2 = tmpMeta124;
_e2 = tmpMeta125;
_e3 = tmp4_3;
tmp4 += 1;
tmpMeta126 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e3);
_e = omc_ExpressionSimplify_simplify1(threadData, tmpMeta126 ,&_b);
tmpMeta127 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
_e4 = omc_ExpressionSimplify_simplify1(threadData, tmpMeta127 ,&_b2);
tmp128 = (_b || _b2);
if (1 != tmp128) goto goto_2;
tmpMeta129 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op2, _e4);
tmpMeta1 = tmpMeta129;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta130;
modelica_metatype tmpMeta131;
modelica_metatype tmpMeta132;
modelica_metatype tmpMeta133;
modelica_metatype tmpMeta134;
modelica_boolean tmp135;
modelica_metatype tmpMeta136;
if (1 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta130 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta131 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta131,1,1) == 0) goto tmp3_end;
tmpMeta132 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_op1 = tmp4_1;
_e1 = tmpMeta130;
_op2 = tmpMeta131;
_e2 = tmpMeta132;
_e3 = tmp4_3;
tmpMeta133 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e3);
_e = omc_ExpressionSimplify_simplify1(threadData, tmpMeta133 ,&_b);
tmpMeta134 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
_e4 = omc_ExpressionSimplify_simplify1(threadData, tmpMeta134 ,&_b2);
tmp135 = (_b || _b2);
if (1 != tmp135) goto goto_2;
tmpMeta136 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op2, _e4);
tmpMeta1 = tmpMeta136;
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta137;
modelica_metatype tmpMeta138;
modelica_metatype tmpMeta139;
modelica_metatype tmpMeta140;
modelica_metatype tmpMeta141;
modelica_metatype tmpMeta142;
modelica_metatype tmpMeta143;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta137 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta138 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta139 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta139,3,1) == 0) goto tmp3_end;
tmpMeta140 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_tp = tmpMeta137;
_e2 = tmpMeta138;
_op2 = tmpMeta139;
_e3 = tmpMeta140;
_e1 = tmp4_2;
tmpMeta141 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
tmpMeta142 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta141, _e3);
tmpMeta143 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta142, _op2, _e2);
tmpMeta1 = tmpMeta143;
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta144;
modelica_metatype tmpMeta145;
modelica_metatype tmpMeta146;
modelica_metatype tmpMeta147;
modelica_metatype tmpMeta148;
modelica_metatype tmpMeta149;
modelica_metatype tmpMeta150;
modelica_metatype tmpMeta151;
modelica_metatype tmpMeta152;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta144 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta145 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta146 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta146,3,1) == 0) goto tmp3_end;
tmpMeta147 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta146), 2));
tmpMeta148 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_tp = tmpMeta144;
_e1 = tmpMeta145;
_tp2 = tmpMeta147;
_e2 = tmpMeta148;
_e3 = tmp4_3;
tmpMeta149 = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _tp2);
tmpMeta150 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
tmpMeta151 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, tmpMeta150, _e3);
tmpMeta152 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta149, tmpMeta151);
tmpMeta1 = tmpMeta152;
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta153;
modelica_metatype tmpMeta154;
modelica_metatype tmpMeta155;
modelica_metatype tmpMeta156;
modelica_boolean tmp157;
modelica_metatype tmpMeta158;
modelica_metatype tmpMeta159;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta153 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta154 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta154,2,1) == 0) goto tmp3_end;
tmpMeta155 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta154), 2));
tmpMeta156 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_e2 = tmpMeta153;
_tp2 = tmpMeta155;
_e3 = tmpMeta156;
_e1 = tmp4_2;
tmp157 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp157) goto goto_2;
tmpMeta158 = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _tp2);
tmpMeta159 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, tmpMeta158, _e2);
tmpMeta1 = tmpMeta159;
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta160;
modelica_metatype tmpMeta161;
modelica_metatype tmpMeta162;
modelica_metatype tmpMeta163;
modelica_boolean tmp164;
modelica_metatype tmpMeta165;
modelica_metatype tmpMeta166;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta160 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta161 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta161,2,1) == 0) goto tmp3_end;
tmpMeta162 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta161), 2));
tmpMeta163 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_e2 = tmpMeta160;
_tp2 = tmpMeta162;
_e3 = tmpMeta163;
_e1 = tmp4_2;
tmp164 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp164) goto goto_2;
tmpMeta165 = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _tp2);
tmpMeta166 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, tmpMeta165, _e3);
tmpMeta1 = tmpMeta166;
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta167;
modelica_metatype tmpMeta168;
modelica_metatype tmpMeta169;
modelica_boolean tmp170;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta167 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta168 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta168,2,1) == 0) goto tmp3_end;
tmpMeta169 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e1 = tmpMeta167;
_e2 = tmpMeta169;
_e3 = tmp4_3;
tmp170 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp170) goto goto_2;
tmpMeta1 = _e2;
goto tmp3_done;
}
case 23: {
modelica_metatype tmpMeta171;
modelica_metatype tmpMeta172;
modelica_metatype tmpMeta173;
modelica_boolean tmp174;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta171 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta172 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta172,2,1) == 0) goto tmp3_end;
tmpMeta173 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e1 = tmpMeta171;
_e2 = tmpMeta173;
_e3 = tmp4_3;
tmp174 = omc_Expression_expEqual(threadData, _e2, _e3);
if (1 != tmp174) goto goto_2;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta175;
modelica_metatype tmpMeta176;
modelica_metatype tmpMeta177;
modelica_metatype tmpMeta178;
modelica_metatype tmpMeta179;
modelica_boolean tmp180;
modelica_metatype tmpMeta181;
modelica_metatype tmpMeta182;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta175 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta175,8,2) == 0) goto tmp3_end;
tmpMeta176 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta175), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta176,5,1) == 0) goto tmp3_end;
tmpMeta177 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta175), 3));
tmpMeta178 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta178,2,1) == 0) goto tmp3_end;
tmpMeta179 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e1 = tmpMeta177;
_e2 = tmpMeta179;
_e3 = tmp4_3;
tmp180 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp180) goto goto_2;
_tp2 = omc_Expression_typeof(threadData, _e2);
tmpMeta181 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _tp2);
tmpMeta182 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta181, _e2);
tmpMeta1 = tmpMeta182;
goto tmp3_done;
}
case 25: {
modelica_metatype tmpMeta183;
modelica_metatype tmpMeta184;
modelica_metatype tmpMeta185;
modelica_metatype tmpMeta186;
modelica_metatype tmpMeta187;
modelica_boolean tmp188;
modelica_metatype tmpMeta189;
modelica_metatype tmpMeta190;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta183 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta183,8,2) == 0) goto tmp3_end;
tmpMeta184 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta183), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta184,5,1) == 0) goto tmp3_end;
tmpMeta185 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta183), 3));
tmpMeta186 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta186,2,1) == 0) goto tmp3_end;
tmpMeta187 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e1 = tmpMeta185;
_e2 = tmpMeta187;
_e3 = tmp4_3;
tmp188 = omc_Expression_expEqual(threadData, _e2, _e3);
if (1 != tmp188) goto goto_2;
_tp2 = omc_Expression_typeof(threadData, _e1);
tmpMeta189 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _tp2);
tmpMeta190 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta189, _e1);
tmpMeta1 = tmpMeta190;
goto tmp3_done;
}
case 26: {
modelica_metatype tmpMeta191;
modelica_metatype tmpMeta192;
modelica_metatype tmpMeta193;
modelica_metatype tmpMeta194;
modelica_metatype tmpMeta195;
modelica_boolean tmp196;
modelica_metatype tmpMeta197;
modelica_metatype tmpMeta198;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta191 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta192 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta192,2,1) == 0) goto tmp3_end;
tmpMeta193 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,8,2) == 0) goto tmp3_end;
tmpMeta194 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta194,5,1) == 0) goto tmp3_end;
tmpMeta195 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_e1 = tmpMeta191;
_e2 = tmpMeta193;
_e3 = tmpMeta195;
tmp196 = omc_Expression_expEqual(threadData, _e2, _e3);
if (1 != tmp196) goto goto_2;
_tp2 = omc_Expression_typeof(threadData, _e1);
tmpMeta197 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _tp2);
tmpMeta198 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta197, _e1);
tmpMeta1 = tmpMeta198;
goto tmp3_done;
}
case 27: {
modelica_metatype tmpMeta199;
modelica_metatype tmpMeta200;
modelica_metatype tmpMeta201;
modelica_metatype tmpMeta202;
modelica_metatype tmpMeta203;
modelica_boolean tmp204;
modelica_metatype tmpMeta205;
modelica_metatype tmpMeta206;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta199 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta200 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta200,2,1) == 0) goto tmp3_end;
tmpMeta201 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,8,2) == 0) goto tmp3_end;
tmpMeta202 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta202,5,1) == 0) goto tmp3_end;
tmpMeta203 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_e1 = tmpMeta199;
_e2 = tmpMeta201;
_e3 = tmpMeta203;
tmp4 += 7;
tmp204 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp204) goto goto_2;
_tp2 = omc_Expression_typeof(threadData, _e2);
tmpMeta205 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _tp2);
tmpMeta206 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta205, _e2);
tmpMeta1 = tmpMeta206;
goto tmp3_done;
}
case 28: {
modelica_metatype tmpMeta207;
modelica_boolean tmp208;
modelica_metatype tmpMeta209;
modelica_metatype tmpMeta210;
if (1 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta207 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ty = tmpMeta207;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmp208 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp208) goto goto_2;
tmpMeta209 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _ty);
tmpMeta210 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta209, _e2);
tmpMeta1 = tmpMeta210;
goto tmp3_done;
}
case 29: {
modelica_boolean tmp211;
if (1 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmp211 = omc_Expression_isZero(threadData, _e2);
if (1 != tmp211) goto goto_2;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 30: {
modelica_metatype tmpMeta212;
modelica_boolean tmp213;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta212 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ty = tmpMeta212;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmp4 += 1;
tmp213 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp213) goto goto_2;
tmpMeta1 = omc_Expression_makeConstZero(threadData, _ty);
goto tmp3_done;
}
case 31: {
modelica_metatype tmpMeta214;
modelica_boolean tmp215;
modelica_boolean tmp216;
modelica_metatype tmpMeta217;
modelica_metatype tmpMeta218;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta214 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ty = tmpMeta214;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmp4 += 30;
tmp215 = omc_Types_isRealOrSubTypeReal(threadData, _ty);
if (1 != tmp215) goto goto_2;
tmp216 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp216) goto goto_2;
_e = omc_Expression_makeConstNumber(threadData, _ty, ((modelica_integer) 2));
tmpMeta217 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta218 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, tmpMeta217, _e1);
tmpMeta1 = tmpMeta218;
goto tmp3_done;
}
case 32: {
modelica_metatype tmpMeta219;
modelica_metatype tmpMeta220;
modelica_metatype tmpMeta221;
modelica_metatype tmpMeta222;
modelica_metatype tmpMeta223;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta219 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,8,2) == 0) goto tmp3_end;
tmpMeta220 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta220,5,1) == 0) goto tmp3_end;
tmpMeta221 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_ty = tmpMeta219;
_e2 = tmpMeta221;
_e1 = tmp4_2;
tmp4 += 49;
tmpMeta222 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta223 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta222, _e2);
tmpMeta1 = tmpMeta223;
goto tmp3_done;
}
case 33: {
modelica_metatype tmpMeta224;
modelica_metatype tmpMeta225;
modelica_metatype tmpMeta226;
modelica_metatype tmpMeta227;
modelica_metatype tmpMeta228;
modelica_metatype tmpMeta229;
modelica_metatype tmpMeta230;
modelica_metatype tmpMeta231;
modelica_metatype tmpMeta232;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta224 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta225 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta225,8,2) == 0) goto tmp3_end;
tmpMeta226 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta225), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta226,5,1) == 0) goto tmp3_end;
tmpMeta227 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta225), 3));
tmpMeta228 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta228,2,1) == 0) goto tmp3_end;
tmpMeta229 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_ty = tmpMeta224;
_e2 = tmpMeta227;
_op1 = tmpMeta228;
_e3 = tmpMeta229;
_e1 = tmp4_2;
tmp4 += 29;
tmpMeta230 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta231 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
tmpMeta232 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta230, tmpMeta231);
tmpMeta1 = tmpMeta232;
goto tmp3_done;
}
case 34: {
modelica_metatype tmpMeta233;
modelica_metatype tmpMeta234;
modelica_metatype tmpMeta235;
modelica_metatype tmpMeta236;
modelica_metatype tmpMeta237;
modelica_metatype tmpMeta238;
modelica_metatype tmpMeta239;
modelica_metatype tmpMeta240;
modelica_metatype tmpMeta241;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta233 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta234 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta234,8,2) == 0) goto tmp3_end;
tmpMeta235 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta234), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta235,5,1) == 0) goto tmp3_end;
tmpMeta236 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta234), 3));
tmpMeta237 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta237,3,1) == 0) goto tmp3_end;
tmpMeta238 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_ty = tmpMeta233;
_e2 = tmpMeta236;
_op1 = tmpMeta237;
_e3 = tmpMeta238;
_e1 = tmp4_2;
tmp4 += 29;
tmpMeta239 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta240 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
tmpMeta241 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta239, tmpMeta240);
tmpMeta1 = tmpMeta241;
goto tmp3_done;
}
case 35: {
modelica_boolean tmp242;
modelica_boolean tmp243;
if (1 != tmp4_4) goto tmp3_end;
if (0 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmp4 += 1;
tmp242 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp242) goto goto_2;
tmp243 = omc_Expression_isZero(threadData, _e2);
if (0 != tmp243) goto goto_2;
tmpMeta1 = _OMC_LIT20;
goto tmp3_done;
}
case 36: {
modelica_boolean tmp244;
if (0 != tmp4_4) goto tmp3_end;
if (1 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmp244 = omc_Expression_isConstOne(threadData, _e2);
if (1 != tmp244) goto goto_2;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 37: {
modelica_metatype tmpMeta245;
modelica_boolean tmp246;
modelica_metatype tmpMeta247;
modelica_metatype tmpMeta248;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta245 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ty = tmpMeta245;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmp246 = omc_Expression_isConstMinusOne(threadData, _e2);
if (1 != tmp246) goto goto_2;
tmpMeta247 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _ty);
tmpMeta248 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta247, _e1);
tmpMeta1 = tmpMeta248;
goto tmp3_done;
}
case 38: {
modelica_metatype tmpMeta249;
modelica_boolean tmp250;
modelica_boolean tmp251;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta249 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ty = tmpMeta249;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmp4 += 1;
tmp250 = omc_Expression_isZero(threadData, _e2);
if (0 != tmp250) goto goto_2;
tmp251 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp251) goto goto_2;
tmpMeta1 = omc_Expression_makeConstOne(threadData, _ty);
goto tmp3_done;
}
case 39: {
modelica_metatype tmpMeta252;
modelica_boolean tmp253;
modelica_boolean tmp254;
modelica_boolean tmp255;
modelica_metatype tmpMeta256;
modelica_metatype tmpMeta257;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta252 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ty = tmpMeta252;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmp4 += 3;
tmp253 = omc_Expression_isZero(threadData, _e2);
if (0 != tmp253) goto goto_2;
tmp254 = omc_Types_isRealOrSubTypeReal(threadData, _ty);
if (1 != tmp254) goto goto_2;
tmp255 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp255) goto goto_2;
tmpMeta256 = mmc_mk_box2(7, &DAE_Operator_POW__desc, _ty);
tmpMeta257 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta256, _OMC_LIT29);
tmpMeta1 = tmpMeta257;
goto tmp3_done;
}
case 40: {
modelica_metatype tmpMeta258;
modelica_metatype tmpMeta259;
modelica_real tmp260;
modelica_boolean tmp261;
modelica_real tmp262;
modelica_real tmp263;
modelica_metatype tmpMeta264;
modelica_metatype tmpMeta265;
modelica_metatype tmpMeta266;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta258 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta259 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp260 = mmc_unbox_real(tmpMeta259);
_tp = tmpMeta258;
_r1 = tmp260;
_e1 = tmp4_2;
tmp4 += 8;
tmp261 = (fabs(_r1) > 0.0);
if (1 != tmp261) goto goto_2;
tmp262 = _r1;
if (tmp262 == 0) {goto goto_2;}
_r = (1.0) / tmp262;
_r1 = (1000000000000.0) * (_r);
tmp263 = modelica_real_mod(_r1, 1.0);
if (0.0 != tmp263) goto goto_2;
tmpMeta264 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta265 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
tmpMeta266 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta264, tmpMeta265, _e1);
tmpMeta1 = tmpMeta266;
goto tmp3_done;
}
case 41: {
modelica_metatype tmpMeta267;
modelica_metatype tmpMeta268;
modelica_metatype tmpMeta269;
modelica_real tmp270;
modelica_metatype tmpMeta271;
modelica_metatype tmpMeta272;
modelica_boolean tmp273;
modelica_real tmp274;
modelica_real tmp275;
modelica_metatype tmpMeta276;
modelica_metatype tmpMeta277;
modelica_metatype tmpMeta278;
modelica_metatype tmpMeta279;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta267 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta268 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta268,1,1) == 0) goto tmp3_end;
tmpMeta269 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta268), 2));
tmp270 = mmc_unbox_real(tmpMeta269);
tmpMeta271 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta271,2,1) == 0) goto tmp3_end;
tmpMeta272 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_op2 = tmp4_1;
_tp = tmpMeta267;
_r1 = tmp270;
_e3 = tmpMeta272;
_e1 = tmp4_2;
tmp4 += 7;
tmp273 = (fabs(_r1) > 0.0);
if (1 != tmp273) goto goto_2;
tmp274 = _r1;
if (tmp274 == 0) {goto goto_2;}
_r = (1.0) / tmp274;
_r1 = (1000000000000.0) * (_r);
tmp275 = modelica_real_mod(_r1, 1.0);
if (0.0 != tmp275) goto goto_2;
tmpMeta276 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta277 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
tmpMeta278 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta276, tmpMeta277, _e1);
tmpMeta279 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta278, _op2, _e3);
tmpMeta1 = tmpMeta279;
goto tmp3_done;
}
case 42: {
modelica_metatype tmpMeta280;
modelica_metatype tmpMeta281;
modelica_metatype tmpMeta282;
modelica_metatype tmpMeta283;
modelica_metatype tmpMeta284;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,8,2) == 0) goto tmp3_end;
tmpMeta280 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta280,5,1) == 0) goto tmp3_end;
tmpMeta281 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,8,2) == 0) goto tmp3_end;
tmpMeta282 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta282,5,1) == 0) goto tmp3_end;
tmpMeta283 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_op1 = tmp4_1;
_e1 = tmpMeta281;
_e2 = tmpMeta283;
tmp4 += 5;
tmpMeta284 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e2);
tmpMeta1 = tmpMeta284;
goto tmp3_done;
}
case 43: {
modelica_metatype tmpMeta285;
modelica_metatype tmpMeta286;
modelica_metatype tmpMeta287;
modelica_metatype tmpMeta288;
modelica_metatype tmpMeta289;
modelica_metatype tmpMeta290;
modelica_metatype tmpMeta291;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,8,2) == 0) goto tmp3_end;
tmpMeta285 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta285,5,1) == 0) goto tmp3_end;
tmpMeta286 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta287 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta288 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta288,1,1) == 0) goto tmp3_end;
tmpMeta289 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_op2 = tmp4_1;
_e1 = tmpMeta286;
_e2 = tmpMeta287;
_op1 = tmpMeta288;
_e3 = tmpMeta289;
tmp4 += 1;
tmpMeta290 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op1, _e2);
tmpMeta291 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, tmpMeta290);
tmpMeta1 = tmpMeta291;
goto tmp3_done;
}
case 44: {
modelica_metatype tmpMeta292;
modelica_metatype tmpMeta293;
modelica_metatype tmpMeta294;
modelica_metatype tmpMeta295;
modelica_metatype tmpMeta296;
modelica_metatype tmpMeta297;
modelica_metatype tmpMeta298;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,8,2) == 0) goto tmp3_end;
tmpMeta292 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta292,5,1) == 0) goto tmp3_end;
tmpMeta293 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta294 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta295 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta295,1,1) == 0) goto tmp3_end;
tmpMeta296 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_op2 = tmp4_1;
_e1 = tmpMeta293;
_e2 = tmpMeta294;
_op1 = tmpMeta295;
_e3 = tmpMeta296;
tmp4 += 1;
tmpMeta297 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op1, _e2);
tmpMeta298 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, tmpMeta297);
tmpMeta1 = tmpMeta298;
goto tmp3_done;
}
case 45: {
modelica_metatype tmpMeta299;
modelica_metatype tmpMeta300;
modelica_metatype tmpMeta301;
modelica_metatype tmpMeta302;
modelica_metatype tmpMeta303;
modelica_metatype tmpMeta304;
modelica_metatype tmpMeta305;
modelica_metatype tmpMeta306;
modelica_metatype tmpMeta307;
modelica_metatype tmpMeta308;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta299 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta299,8,2) == 0) goto tmp3_end;
tmpMeta300 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta299), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta300,5,1) == 0) goto tmp3_end;
tmpMeta301 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta299), 3));
tmpMeta302 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta302,1,1) == 0) goto tmp3_end;
tmpMeta303 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta302), 2));
tmpMeta304 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_op2 = tmp4_1;
_op3 = tmpMeta300;
_e2 = tmpMeta301;
_ty = tmpMeta303;
_e3 = tmpMeta304;
_e1 = tmp4_2;
tmp4 += 38;
tmpMeta305 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op3, _e1);
tmpMeta306 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta307 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, tmpMeta306, _e3);
tmpMeta308 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta305, _op2, tmpMeta307);
tmpMeta1 = tmpMeta308;
goto tmp3_done;
}
case 46: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta309 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta309,8,2) == 0) goto tmp3_end;
tmpMeta310 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta309), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta310,5,1) == 0) goto tmp3_end;
tmpMeta311 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta309), 3));
tmpMeta312 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta312,1,1) == 0) goto tmp3_end;
tmpMeta313 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta312), 2));
tmpMeta314 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_op2 = tmp4_1;
_op3 = tmpMeta310;
_e2 = tmpMeta311;
_ty = tmpMeta313;
_e3 = tmpMeta314;
_e1 = tmp4_2;
tmp4 += 2;
tmpMeta315 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op3, _e1);
tmpMeta316 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta317 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, tmpMeta316, _e3);
tmpMeta318 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta315, _op2, tmpMeta317);
tmpMeta1 = tmpMeta318;
goto tmp3_done;
}
case 47: {
modelica_metatype tmpMeta319;
modelica_real tmp320;
modelica_metatype tmpMeta321;
modelica_metatype tmpMeta322;
modelica_metatype tmpMeta323;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta319 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp320 = mmc_unbox_real(tmpMeta319);
if (2.0 != tmp320) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,8,2) == 0) goto tmp3_end;
tmpMeta321 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta321,5,1) == 0) goto tmp3_end;
tmpMeta322 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_op2 = tmp4_1;
_e2 = tmp4_3;
_e1 = tmpMeta322;
tmp4 += 3;
tmpMeta323 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e2);
tmpMeta1 = tmpMeta323;
goto tmp3_done;
}
case 48: {
modelica_metatype tmpMeta324;
modelica_metatype tmpMeta325;
modelica_metatype tmpMeta326;
modelica_metatype tmpMeta327;
modelica_metatype tmpMeta328;
modelica_metatype tmpMeta329;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta324 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,8,2) == 0) goto tmp3_end;
tmpMeta325 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta325,5,1) == 0) goto tmp3_end;
tmpMeta326 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_op1 = tmp4_1;
_ty = tmpMeta324;
_e2 = tmpMeta326;
_e1 = tmp4_2;
tmpMeta327 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _ty);
tmpMeta328 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta327, _e1);
_e1_1 = tmpMeta328;
tmpMeta329 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op1, _e2);
tmpMeta1 = tmpMeta329;
goto tmp3_done;
}
case 49: {
modelica_metatype tmpMeta330;
modelica_metatype tmpMeta331;
modelica_metatype tmpMeta332;
modelica_boolean tmp333;
modelica_boolean tmp334;
modelica_metatype tmpMeta335;
modelica_metatype tmpMeta336;
modelica_metatype tmpMeta337;
if (1 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta330 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta331 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta331,2,1) == 0) goto tmp3_end;
tmpMeta332 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_op1 = tmp4_1;
_e2 = tmpMeta330;
_op2 = tmpMeta331;
_e3 = tmpMeta332;
_e1 = tmp4_3;
tmp333 = omc_Expression_isConstValue(threadData, _e3);
if (1 != tmp333) goto goto_2;
tmpMeta335 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op1, _e1);
tmpMeta336 = omc_ExpressionSimplify_simplify1(threadData, tmpMeta335, &tmp334);
_e = tmpMeta336;
if (1 != tmp334) goto goto_2;
tmpMeta337 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op2, _e2);
tmpMeta1 = tmpMeta337;
goto tmp3_done;
}
case 50: {
modelica_metatype tmpMeta338;
modelica_metatype tmpMeta339;
modelica_metatype tmpMeta340;
modelica_boolean tmp341;
modelica_boolean tmp342;
modelica_metatype tmpMeta343;
modelica_metatype tmpMeta344;
modelica_metatype tmpMeta345;
if (1 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta338 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta339 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta339,2,1) == 0) goto tmp3_end;
tmpMeta340 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_op1 = tmp4_1;
_e2 = tmpMeta338;
_op2 = tmpMeta339;
_e3 = tmpMeta340;
_e1 = tmp4_3;
tmp4 += 5;
tmp341 = omc_Expression_isConstValue(threadData, _e2);
if (1 != tmp341) goto goto_2;
tmpMeta343 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e1);
tmpMeta344 = omc_ExpressionSimplify_simplify1(threadData, tmpMeta343, &tmp342);
_e = tmpMeta344;
if (1 != tmp342) goto goto_2;
tmpMeta345 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op2, _e3);
tmpMeta1 = tmpMeta345;
goto tmp3_done;
}
case 51: {
modelica_boolean tmp346;
if (1 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
_e = tmp4_3;
tmp346 = omc_Expression_isConstOne(threadData, _e);
if (1 != tmp346) goto goto_2;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 52: {
modelica_metatype tmpMeta347;
modelica_boolean tmp348;
modelica_metatype tmpMeta349;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
tmpMeta347 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_tp = tmpMeta347;
_e2 = tmp4_2;
_e = tmp4_3;
tmp348 = omc_Expression_isConstMinusOne(threadData, _e);
if (1 != tmp348) goto goto_2;
_one = omc_Expression_makeConstOne(threadData, _tp);
tmpMeta349 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _one, _OMC_LIT31, _e2);
tmpMeta1 = tmpMeta349;
goto tmp3_done;
}
case 53: {
modelica_boolean tmp350;
if (1 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
_e = tmp4_3;
tmp350 = omc_Expression_isZero(threadData, _e);
if (1 != tmp350) goto goto_2;
_tp = omc_Expression_typeof(threadData, _e1);
tmpMeta1 = omc_Expression_makeConstOne(threadData, _tp);
goto tmp3_done;
}
case 54: {
modelica_metatype tmpMeta351;
modelica_real tmp352;
modelica_metatype tmpMeta353;
modelica_metatype tmpMeta354;
modelica_metatype tmpMeta355;
modelica_metatype tmpMeta356;
modelica_metatype tmpMeta357;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta351 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp352 = mmc_unbox_real(tmpMeta351);
if (2.0 != tmp352) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta353 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta353,1,1) == 0) goto tmp3_end;
tmpMeta354 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta353), 2));
if (4 != MMC_STRLEN(tmpMeta354) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta354)) != 0) goto tmp3_end;
tmpMeta355 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta355)) goto tmp3_end;
tmpMeta356 = MMC_CAR(tmpMeta355);
tmpMeta357 = MMC_CDR(tmpMeta355);
if (!listEmpty(tmpMeta357)) goto tmp3_end;
_e = tmpMeta356;
tmpMeta1 = _e;
goto tmp3_done;
}
case 55: {
modelica_metatype tmpMeta358;
modelica_metatype tmpMeta359;
modelica_metatype tmpMeta360;
modelica_metatype tmpMeta361;
modelica_metatype tmpMeta362;
modelica_metatype tmpMeta363;
modelica_metatype tmpMeta364;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta358 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta358,1,1) == 0) goto tmp3_end;
tmpMeta359 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta358), 2));
if (4 != MMC_STRLEN(tmpMeta359) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta359)) != 0) goto tmp3_end;
tmpMeta360 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta360)) goto tmp3_end;
tmpMeta361 = MMC_CAR(tmpMeta360);
tmpMeta362 = MMC_CDR(tmpMeta360);
if (!listEmpty(tmpMeta362)) goto tmp3_end;
_oper = tmp4_1;
_e1 = tmpMeta361;
_e = tmp4_3;
tmp4 += 5;
tmpMeta363 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT33, _OMC_LIT34, _e);
tmpMeta364 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _oper, tmpMeta363);
tmpMeta1 = tmpMeta364;
goto tmp3_done;
}
case 56: {
modelica_metatype tmpMeta365;
modelica_metatype tmpMeta366;
modelica_metatype tmpMeta367;
modelica_metatype tmpMeta368;
modelica_metatype tmpMeta369;
modelica_boolean tmp370;
modelica_metatype tmpMeta371;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta365 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta365,1,1) == 0) goto tmp3_end;
tmpMeta366 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta365), 2));
if (4 != MMC_STRLEN(tmpMeta366) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta366)) != 0) goto tmp3_end;
tmpMeta367 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta367)) goto tmp3_end;
tmpMeta368 = MMC_CAR(tmpMeta367);
tmpMeta369 = MMC_CDR(tmpMeta367);
if (!listEmpty(tmpMeta369)) goto tmp3_end;
_e2 = tmpMeta368;
_e1 = tmp4_2;
tmp370 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp370) goto goto_2;
tmpMeta371 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta371, _OMC_LIT30);
goto tmp3_done;
}
case 57: {
modelica_metatype tmpMeta372;
modelica_metatype tmpMeta373;
modelica_metatype tmpMeta374;
modelica_metatype tmpMeta375;
modelica_boolean tmp376;
modelica_metatype tmpMeta377;
modelica_metatype tmpMeta378;
modelica_metatype tmpMeta379;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta372 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta373 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta373,4,1) == 0) goto tmp3_end;
tmpMeta374 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta373), 2));
tmpMeta375 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e1 = tmpMeta372;
_op1 = tmpMeta373;
_ty = tmpMeta374;
_e2 = tmpMeta375;
_e3 = tmp4_3;
tmp4 += 1;
tmp376 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp376) goto goto_2;
_e4 = omc_Expression_makeConstOne(threadData, _ty);
tmpMeta377 = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _ty);
tmpMeta378 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, tmpMeta377, _e4);
_e4 = tmpMeta378;
tmpMeta379 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e4);
tmpMeta1 = tmpMeta379;
goto tmp3_done;
}
case 58: {
modelica_metatype tmpMeta380;
modelica_metatype tmpMeta381;
modelica_metatype tmpMeta382;
modelica_metatype tmpMeta383;
modelica_metatype tmpMeta384;
modelica_metatype tmpMeta385;
modelica_metatype tmpMeta386;
modelica_boolean tmp387;
modelica_metatype tmpMeta388;
modelica_metatype tmpMeta389;
modelica_metatype tmpMeta390;
modelica_metatype tmpMeta391;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta380 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta380,7,3) == 0) goto tmp3_end;
tmpMeta381 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta380), 2));
tmpMeta382 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta380), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta382,4,1) == 0) goto tmp3_end;
tmpMeta383 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta382), 2));
tmpMeta384 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta380), 4));
tmpMeta385 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta385,2,1) == 0) goto tmp3_end;
tmpMeta386 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e1 = tmpMeta381;
_op1 = tmpMeta382;
_ty = tmpMeta383;
_e2 = tmpMeta384;
_op2 = tmpMeta385;
_e5 = tmpMeta386;
_e3 = tmp4_3;
tmp387 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp387) goto goto_2;
_e4 = omc_Expression_makeConstOne(threadData, _ty);
tmpMeta388 = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _ty);
tmpMeta389 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, tmpMeta388, _e4);
_e4 = tmpMeta389;
tmpMeta390 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e4);
tmpMeta391 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta390, _op2, _e5);
tmpMeta1 = tmpMeta391;
goto tmp3_done;
}
case 59: {
modelica_metatype tmpMeta392;
modelica_metatype tmpMeta393;
modelica_metatype tmpMeta394;
modelica_metatype tmpMeta395;
modelica_boolean tmp396;
modelica_metatype tmpMeta397;
modelica_metatype tmpMeta398;
modelica_metatype tmpMeta399;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta392 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta393 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta393,4,1) == 0) goto tmp3_end;
tmpMeta394 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta393), 2));
tmpMeta395 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_e1 = tmpMeta392;
_op1 = tmpMeta393;
_ty = tmpMeta394;
_e2 = tmpMeta395;
_e3 = tmp4_2;
tmp4 += 24;
tmp396 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp396) goto goto_2;
_e4 = omc_Expression_makeConstOne(threadData, _ty);
tmpMeta397 = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _ty);
tmpMeta398 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, tmpMeta397, _e2);
_e4 = tmpMeta398;
tmpMeta399 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e4);
tmpMeta1 = tmpMeta399;
goto tmp3_done;
}
case 60: {
modelica_metatype tmpMeta400;
modelica_real tmp401;
modelica_metatype tmpMeta402;
modelica_metatype tmpMeta403;
modelica_metatype tmpMeta404;
modelica_boolean tmp405;
modelica_metatype tmpMeta406;
modelica_metatype tmpMeta407;
modelica_metatype tmpMeta408;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta400 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp401 = mmc_unbox_real(tmpMeta400);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta402 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta403 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta403,3,1) == 0) goto tmp3_end;
tmpMeta404 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_op2 = tmp4_1;
_r = tmp401;
_e1 = tmpMeta402;
_op1 = tmpMeta403;
_e2 = tmpMeta404;
tmp405 = (_r < 0.0);
if (1 != tmp405) goto goto_2;
_r = (-_r);
tmpMeta406 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e1);
tmpMeta407 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta408 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta406, _op2, tmpMeta407);
tmpMeta1 = tmpMeta408;
goto tmp3_done;
}
case 61: {
modelica_boolean tmp409;
if (1 != tmp4_4) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
tmp409 = omc_Expression_isConstOne(threadData, _e1);
if (1 != tmp409) goto goto_2;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 62: {
modelica_metatype tmpMeta410;
modelica_metatype tmpMeta411;
modelica_metatype tmpMeta412;
modelica_metatype tmpMeta413;
modelica_metatype tmpMeta414;
modelica_metatype tmpMeta415;
modelica_boolean tmp416;
modelica_metatype tmpMeta417;
modelica_metatype tmpMeta418;
modelica_metatype tmpMeta419;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,12,3) == 0) goto tmp3_end;
tmpMeta410 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta411 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta412 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,12,3) == 0) goto tmp3_end;
tmpMeta413 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta414 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta415 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_e1 = tmpMeta410;
_e2 = tmpMeta411;
_e3 = tmpMeta412;
_e4 = tmpMeta413;
_e5 = tmpMeta414;
_e6 = tmpMeta415;
_op1 = tmp4_1;
tmp4 += 6;
tmp416 = omc_Expression_expEqual(threadData, _e1, _e4);
if (1 != tmp416) goto goto_2;
tmpMeta417 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e5);
_e = tmpMeta417;
tmpMeta418 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op1, _e6);
_res = tmpMeta418;
tmpMeta419 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _e1, _e, _res);
tmpMeta1 = tmpMeta419;
goto tmp3_done;
}
case 63: {
modelica_metatype tmpMeta420;
modelica_metatype tmpMeta421;
modelica_metatype tmpMeta422;
modelica_metatype tmpMeta423;
modelica_metatype tmpMeta424;
modelica_metatype tmpMeta425;
modelica_metatype tmpMeta426;
modelica_metatype tmpMeta427;
modelica_metatype tmpMeta428;
modelica_boolean tmp429;
modelica_metatype tmpMeta430;
modelica_metatype tmpMeta431;
modelica_metatype tmpMeta432;
if (0 != tmp4_4) goto tmp3_end;
if (0 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta420 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta421 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta422 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta422,2,1) == 0) goto tmp3_end;
tmpMeta423 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta424 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta424,8,2) == 0) goto tmp3_end;
tmpMeta425 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta424), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta425,5,1) == 0) goto tmp3_end;
tmpMeta426 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta424), 3));
tmpMeta427 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta427,2,1) == 0) goto tmp3_end;
tmpMeta428 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_ty = tmpMeta420;
_e3 = tmpMeta421;
_e4 = tmpMeta423;
_e = tmpMeta424;
_e1 = tmpMeta426;
_op2 = tmpMeta427;
_e2 = tmpMeta428;
tmp4 += 1;
tmp429 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp429) goto goto_2;
tmpMeta430 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta431 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, tmpMeta430, _e4);
tmpMeta432 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op2, tmpMeta431);
tmpMeta1 = tmpMeta432;
goto tmp3_done;
}
case 64: {
modelica_metatype tmpMeta433;
modelica_metatype tmpMeta434;
modelica_metatype tmpMeta435;
modelica_metatype tmpMeta436;
modelica_metatype tmpMeta437;
modelica_metatype tmpMeta438;
modelica_metatype tmpMeta439;
modelica_metatype tmpMeta440;
modelica_metatype tmpMeta441;
modelica_boolean tmp442;
modelica_metatype tmpMeta443;
modelica_metatype tmpMeta444;
modelica_metatype tmpMeta445;
modelica_metatype tmpMeta446;
if (0 != tmp4_4) goto tmp3_end;
if (0 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta433 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta434 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta435 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta435,3,1) == 0) goto tmp3_end;
tmpMeta436 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta437 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta437,8,2) == 0) goto tmp3_end;
tmpMeta438 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta437), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta438,5,1) == 0) goto tmp3_end;
tmpMeta439 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta437), 3));
tmpMeta440 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta440,3,1) == 0) goto tmp3_end;
tmpMeta441 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_ty = tmpMeta433;
_e3 = tmpMeta434;
_e4 = tmpMeta436;
_e = tmpMeta437;
_e1 = tmpMeta439;
_e2 = tmpMeta441;
tmp4 += 19;
tmp442 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp442) goto goto_2;
tmpMeta443 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta444 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta445 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, omc_Expression_inverseFactors(threadData, _e2), tmpMeta444, omc_Expression_inverseFactors(threadData, _e4));
tmpMeta446 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, tmpMeta443, tmpMeta445);
tmpMeta1 = tmpMeta446;
goto tmp3_done;
}
case 65: {
modelica_metatype tmpMeta447;
modelica_metatype tmpMeta448;
modelica_metatype tmpMeta449;
modelica_metatype tmpMeta450;
modelica_metatype tmpMeta451;
modelica_metatype tmpMeta452;
modelica_metatype tmpMeta453;
modelica_metatype tmpMeta454;
modelica_metatype tmpMeta455;
modelica_metatype tmpMeta456;
modelica_metatype tmpMeta457;
modelica_metatype tmpMeta458;
modelica_boolean tmp459;
modelica_boolean tmp460;
modelica_boolean tmp461;
modelica_boolean tmp462;
modelica_metatype tmpMeta463;
modelica_metatype tmpMeta464;
modelica_metatype tmpMeta465;
modelica_metatype tmpMeta466;
if (0 != tmp4_4) goto tmp3_end;
if (0 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta447 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta448 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta448,2,1) == 0) goto tmp3_end;
tmpMeta449 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta449,7,3) == 0) goto tmp3_end;
tmpMeta450 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta449), 2));
tmpMeta451 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta449), 3));
tmpMeta452 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta449), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta453 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta454 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta454,2,1) == 0) goto tmp3_end;
tmpMeta455 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta455,7,3) == 0) goto tmp3_end;
tmpMeta456 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta455), 2));
tmpMeta457 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta455), 3));
tmpMeta458 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta455), 4));
_e1 = tmpMeta447;
_oper = tmpMeta448;
_e2 = tmpMeta450;
_op2 = tmpMeta451;
_e3 = tmpMeta452;
_e4 = tmpMeta453;
_e5 = tmpMeta456;
_op3 = tmpMeta457;
_e6 = tmpMeta458;
_op1 = tmp4_1;
tmp459 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp459) goto goto_2;
tmp460 = omc_Expression_isMulOrDiv(threadData, _op2);
if (1 != tmp460) goto goto_2;
tmp461 = omc_Expression_isMulOrDiv(threadData, _op3);
if (1 != tmp461) goto goto_2;
tmp462 = omc_Expression_expEqual(threadData, _e2, _e5);
if (1 != tmp462) goto goto_2;
tmpMeta463 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e3);
tmpMeta464 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, _op3, _e6);
tmpMeta465 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta463, _op1, tmpMeta464);
tmpMeta466 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e5, _oper, tmpMeta465);
tmpMeta1 = tmpMeta466;
goto tmp3_done;
}
case 66: {
modelica_metatype tmpMeta467;
modelica_metatype tmpMeta468;
modelica_metatype tmpMeta469;
modelica_metatype tmpMeta470;
modelica_metatype tmpMeta471;
modelica_metatype tmpMeta472;
modelica_metatype tmpMeta473;
modelica_metatype tmpMeta474;
modelica_metatype tmpMeta475;
modelica_boolean tmp476;
modelica_boolean tmp477;
modelica_boolean tmp478;
modelica_metatype tmpMeta479;
modelica_metatype tmpMeta480;
modelica_metatype tmpMeta481;
if (0 != tmp4_4) goto tmp3_end;
if (0 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta467 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta468 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta468,2,1) == 0) goto tmp3_end;
tmpMeta469 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta470 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta471 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta471,2,1) == 0) goto tmp3_end;
tmpMeta472 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta472,7,3) == 0) goto tmp3_end;
tmpMeta473 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta472), 2));
tmpMeta474 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta472), 3));
tmpMeta475 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta472), 4));
_e1 = tmpMeta467;
_oper = tmpMeta468;
_e2 = tmpMeta469;
_e4 = tmpMeta470;
_e5 = tmpMeta473;
_op3 = tmpMeta474;
_e6 = tmpMeta475;
_op1 = tmp4_1;
tmp476 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp476) goto goto_2;
tmp477 = omc_Expression_isMulOrDiv(threadData, _op3);
if (1 != tmp477) goto goto_2;
tmp478 = omc_Expression_expEqual(threadData, _e2, _e5);
if (1 != tmp478) goto goto_2;
tmpMeta479 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, _op3, _e6);
tmpMeta480 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, tmpMeta479);
tmpMeta481 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e5, _oper, tmpMeta480);
tmpMeta1 = tmpMeta481;
goto tmp3_done;
}
case 67: {
modelica_metatype tmpMeta482;
modelica_metatype tmpMeta483;
modelica_metatype tmpMeta484;
modelica_metatype tmpMeta485;
modelica_metatype tmpMeta486;
modelica_metatype tmpMeta487;
modelica_metatype tmpMeta488;
modelica_metatype tmpMeta489;
modelica_metatype tmpMeta490;
modelica_boolean tmp491;
modelica_boolean tmp492;
modelica_metatype tmpMeta493;
modelica_metatype tmpMeta494;
modelica_metatype tmpMeta495;
modelica_metatype tmpMeta496;
modelica_metatype tmpMeta497;
modelica_metatype tmpMeta498;
if (0 != tmp4_4) goto tmp3_end;
if (0 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta482 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta483 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta483,2,1) == 0) goto tmp3_end;
tmpMeta484 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta485 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta486 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta486,2,1) == 0) goto tmp3_end;
tmpMeta487 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta487,7,3) == 0) goto tmp3_end;
tmpMeta488 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta487), 2));
tmpMeta489 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta487), 3));
tmpMeta490 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta487), 4));
_e4 = tmpMeta482;
_e5 = tmpMeta484;
_e1 = tmpMeta485;
_oper = tmpMeta486;
_e2 = tmpMeta488;
_op2 = tmpMeta489;
_e3 = tmpMeta490;
_op1 = tmp4_1;
tmp491 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp491) goto goto_2;
tmp492 = omc_Expression_isMulOrDiv(threadData, _op2);
if (1 != tmp492) goto goto_2;
if(omc_Expression_expEqual(threadData, _e2, _e5))
{
tmpMeta493 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e3);
tmpMeta494 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta493, _op1, _e4);
tmpMeta495 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e5, _oper, tmpMeta494);
_outExp = tmpMeta495;
}
else
{
if(omc_Expression_expEqual(threadData, _e2, _e4))
{
tmpMeta496 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e3);
tmpMeta497 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta496, _op1, _e5);
tmpMeta498 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, _oper, tmpMeta497);
_outExp = tmpMeta498;
}
else
{
goto goto_2;
}
}
tmpMeta1 = _outExp;
goto tmp3_done;
}
case 68: {
modelica_metatype tmpMeta499;
modelica_metatype tmpMeta500;
modelica_metatype tmpMeta501;
modelica_metatype tmpMeta502;
modelica_metatype tmpMeta503;
modelica_metatype tmpMeta504;
modelica_metatype tmpMeta505;
modelica_metatype tmpMeta506;
modelica_metatype tmpMeta507;
modelica_boolean tmp508;
modelica_boolean tmp509;
modelica_metatype tmpMeta510;
modelica_metatype tmpMeta511;
modelica_metatype tmpMeta512;
modelica_metatype tmpMeta513;
modelica_metatype tmpMeta514;
modelica_metatype tmpMeta515;
if (0 != tmp4_4) goto tmp3_end;
if (0 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta499 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta500 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta500,2,1) == 0) goto tmp3_end;
tmpMeta501 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta502 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta502,7,3) == 0) goto tmp3_end;
tmpMeta503 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta502), 2));
tmpMeta504 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta502), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta504,2,1) == 0) goto tmp3_end;
tmpMeta505 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta502), 4));
tmpMeta506 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta507 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e4 = tmpMeta499;
_e5 = tmpMeta501;
_e1 = tmpMeta503;
_oper = tmpMeta504;
_e2 = tmpMeta505;
_op2 = tmpMeta506;
_e3 = tmpMeta507;
_op1 = tmp4_1;
tmp4 += 1;
tmp508 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp508) goto goto_2;
tmp509 = omc_Expression_isMulOrDiv(threadData, _op2);
if (1 != tmp509) goto goto_2;
if(omc_Expression_expEqual(threadData, _e2, _e5))
{
tmpMeta510 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e3);
tmpMeta511 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta510, _op1, _e4);
tmpMeta512 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e5, _oper, tmpMeta511);
_outExp = tmpMeta512;
}
else
{
if(omc_Expression_expEqual(threadData, _e2, _e4))
{
tmpMeta513 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e3);
tmpMeta514 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta513, _op1, _e5);
tmpMeta515 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, _oper, tmpMeta514);
_outExp = tmpMeta515;
}
else
{
goto goto_2;
}
}
tmpMeta1 = _outExp;
goto tmp3_done;
}
case 69: {
modelica_metatype tmpMeta516;
modelica_metatype tmpMeta517;
modelica_metatype tmpMeta518;
modelica_metatype tmpMeta519;
modelica_metatype tmpMeta520;
modelica_metatype tmpMeta521;
modelica_metatype tmpMeta522;
modelica_boolean tmp523;
if (1 != tmp4_5) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmpMeta516 = omc_Expression_factors(threadData, _e1);
if (listEmpty(tmpMeta516)) goto goto_2;
tmpMeta517 = MMC_CAR(tmpMeta516);
tmpMeta518 = MMC_CDR(tmpMeta516);
if (listEmpty(tmpMeta518)) goto goto_2;
tmpMeta519 = MMC_CAR(tmpMeta518);
tmpMeta520 = MMC_CDR(tmpMeta518);
if (listEmpty(tmpMeta520)) goto goto_2;
tmpMeta521 = MMC_CAR(tmpMeta520);
tmpMeta522 = MMC_CDR(tmpMeta520);
_exp_lst = tmpMeta516;
tmp523 = omc_List_exist(threadData, _exp_lst, boxvar_Expression_isConstValue);
if (1 != tmp523) goto goto_2;
_exp_lst_1 = omc_ExpressionSimplify_simplifyBinaryDistributePow(threadData, _exp_lst, _e2);
tmpMeta1 = omc_Expression_makeProductLst(threadData, _exp_lst_1);
goto tmp3_done;
}
case 70: {
modelica_metatype tmpMeta524;
modelica_metatype tmpMeta525;
modelica_metatype tmpMeta526;
modelica_metatype tmpMeta527;
modelica_metatype tmpMeta528;
modelica_metatype tmpMeta529;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta524 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta525 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta525,4,1) == 0) goto tmp3_end;
tmpMeta526 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e1 = tmpMeta524;
_e2 = tmpMeta526;
_e3 = tmp4_3;
if (!omc_Expression_isEven(threadData, _e2)) goto tmp3_end;
tmpMeta527 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta528 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _OMC_LIT34, _e3);
tmpMeta529 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT24, tmpMeta527, omc_Expression_typeof(threadData, _e1)), _OMC_LIT36, tmpMeta528);
tmpMeta1 = tmpMeta529;
goto tmp3_done;
}
case 71: {
modelica_metatype tmpMeta530;
modelica_metatype tmpMeta531;
modelica_metatype tmpMeta532;
modelica_metatype tmpMeta533;
modelica_metatype tmpMeta534;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta530 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta531 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta531,4,1) == 0) goto tmp3_end;
tmpMeta532 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e1 = tmpMeta530;
_e2 = tmpMeta532;
_e3 = tmp4_3;
tmp4 += 12;
tmpMeta533 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _OMC_LIT34, _e3);
tmpMeta534 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _OMC_LIT36, tmpMeta533);
tmpMeta1 = tmpMeta534;
goto tmp3_done;
}
case 72: {
modelica_metatype tmpMeta535;
modelica_metatype tmpMeta536;
modelica_metatype tmpMeta537;
modelica_metatype tmpMeta538;
modelica_metatype tmpMeta539;
modelica_metatype tmpMeta540;
modelica_metatype tmpMeta541;
modelica_metatype tmpMeta542;
modelica_metatype tmpMeta543;
modelica_metatype tmpMeta544;
modelica_metatype tmpMeta545;
modelica_boolean tmp546;
modelica_metatype tmpMeta547;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta535 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta536 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta536,1,1) == 0) goto tmp3_end;
tmpMeta537 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta536), 2));
if (3 != MMC_STRLEN(tmpMeta537) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta537)) != 0) goto tmp3_end;
tmpMeta538 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta538)) goto tmp3_end;
tmpMeta539 = MMC_CAR(tmpMeta538);
tmpMeta540 = MMC_CDR(tmpMeta538);
if (!listEmpty(tmpMeta540)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta541 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta541,1,1) == 0) goto tmp3_end;
tmpMeta542 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta541), 2));
if (3 != MMC_STRLEN(tmpMeta542) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta542)) != 0) goto tmp3_end;
tmpMeta543 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta543)) goto tmp3_end;
tmpMeta544 = MMC_CAR(tmpMeta543);
tmpMeta545 = MMC_CDR(tmpMeta543);
if (!listEmpty(tmpMeta545)) goto tmp3_end;
_ty = tmpMeta535;
_e1 = tmpMeta539;
_e2 = tmpMeta544;
tmp4 += 11;
tmp546 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp546) goto goto_2;
tmpMeta547 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT37, tmpMeta547, _ty);
goto tmp3_done;
}
case 73: {
modelica_metatype tmpMeta548;
modelica_metatype tmpMeta549;
modelica_metatype tmpMeta550;
modelica_metatype tmpMeta551;
modelica_metatype tmpMeta552;
modelica_metatype tmpMeta553;
modelica_metatype tmpMeta554;
modelica_metatype tmpMeta555;
modelica_metatype tmpMeta556;
modelica_metatype tmpMeta557;
modelica_metatype tmpMeta558;
modelica_boolean tmp559;
modelica_metatype tmpMeta560;
modelica_metatype tmpMeta561;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta548 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta549 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta549,1,1) == 0) goto tmp3_end;
tmpMeta550 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta549), 2));
if (3 != MMC_STRLEN(tmpMeta550) || strcmp(MMC_STRINGDATA(_OMC_LIT37), MMC_STRINGDATA(tmpMeta550)) != 0) goto tmp3_end;
tmpMeta551 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta551)) goto tmp3_end;
tmpMeta552 = MMC_CAR(tmpMeta551);
tmpMeta553 = MMC_CDR(tmpMeta551);
if (!listEmpty(tmpMeta553)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta554 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta554,1,1) == 0) goto tmp3_end;
tmpMeta555 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta554), 2));
if (3 != MMC_STRLEN(tmpMeta555) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta555)) != 0) goto tmp3_end;
tmpMeta556 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta556)) goto tmp3_end;
tmpMeta557 = MMC_CAR(tmpMeta556);
tmpMeta558 = MMC_CDR(tmpMeta556);
if (!listEmpty(tmpMeta558)) goto tmp3_end;
_op2 = tmp4_1;
_ty = tmpMeta548;
_e1 = tmpMeta552;
_e2 = tmpMeta557;
tmp4 += 10;
tmp559 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp559) goto goto_2;
_e3 = _OMC_LIT27;
tmpMeta560 = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e4 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT38, tmpMeta560, _ty);
tmpMeta561 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op2, _e4);
tmpMeta1 = tmpMeta561;
goto tmp3_done;
}
case 74: {
modelica_metatype tmpMeta562;
modelica_metatype tmpMeta563;
modelica_metatype tmpMeta564;
modelica_metatype tmpMeta565;
modelica_metatype tmpMeta566;
modelica_metatype tmpMeta567;
modelica_metatype tmpMeta568;
modelica_metatype tmpMeta569;
modelica_metatype tmpMeta570;
modelica_metatype tmpMeta571;
modelica_metatype tmpMeta572;
modelica_boolean tmp573;
modelica_metatype tmpMeta574;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta562 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta563 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta563,1,1) == 0) goto tmp3_end;
tmpMeta564 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta563), 2));
if (3 != MMC_STRLEN(tmpMeta564) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta564)) != 0) goto tmp3_end;
tmpMeta565 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta565)) goto tmp3_end;
tmpMeta566 = MMC_CAR(tmpMeta565);
tmpMeta567 = MMC_CDR(tmpMeta565);
if (!listEmpty(tmpMeta567)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta568 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta568,1,1) == 0) goto tmp3_end;
tmpMeta569 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta568), 2));
if (3 != MMC_STRLEN(tmpMeta569) || strcmp(MMC_STRINGDATA(_OMC_LIT37), MMC_STRINGDATA(tmpMeta569)) != 0) goto tmp3_end;
tmpMeta570 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta570)) goto tmp3_end;
tmpMeta571 = MMC_CAR(tmpMeta570);
tmpMeta572 = MMC_CDR(tmpMeta570);
if (!listEmpty(tmpMeta572)) goto tmp3_end;
_ty = tmpMeta562;
_e1 = tmpMeta566;
_e2 = tmpMeta571;
tmp573 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp573) goto goto_2;
tmpMeta574 = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT38, tmpMeta574, _ty);
goto tmp3_done;
}
case 75: {
modelica_metatype tmpMeta575;
modelica_metatype tmpMeta576;
modelica_metatype tmpMeta577;
modelica_metatype tmpMeta578;
modelica_metatype tmpMeta579;
modelica_metatype tmpMeta580;
modelica_metatype tmpMeta581;
modelica_metatype tmpMeta582;
modelica_metatype tmpMeta583;
modelica_metatype tmpMeta584;
modelica_metatype tmpMeta585;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta575 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta576 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta576,1,1) == 0) goto tmp3_end;
tmpMeta577 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta576), 2));
if (3 != MMC_STRLEN(tmpMeta577) || strcmp(MMC_STRINGDATA(_OMC_LIT37), MMC_STRINGDATA(tmpMeta577)) != 0) goto tmp3_end;
tmpMeta578 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta578)) goto tmp3_end;
tmpMeta579 = MMC_CAR(tmpMeta578);
tmpMeta580 = MMC_CDR(tmpMeta578);
if (!listEmpty(tmpMeta580)) goto tmp3_end;
_op2 = tmp4_1;
_ty = tmpMeta575;
_e2 = tmpMeta579;
_e1 = tmp4_2;
tmp4 += 8;
tmpMeta581 = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT39, tmpMeta581, _ty);
tmpMeta582 = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e4 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT38, tmpMeta582, _ty);
tmpMeta583 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, _op2, _e3);
_e = tmpMeta583;
tmpMeta584 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta585 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta584, _e);
tmpMeta1 = tmpMeta585;
goto tmp3_done;
}
case 76: {
modelica_metatype tmpMeta586;
modelica_metatype tmpMeta587;
modelica_metatype tmpMeta588;
modelica_metatype tmpMeta589;
modelica_metatype tmpMeta590;
modelica_metatype tmpMeta591;
modelica_metatype tmpMeta592;
modelica_metatype tmpMeta593;
modelica_metatype tmpMeta594;
modelica_metatype tmpMeta595;
modelica_metatype tmpMeta596;
modelica_boolean tmp597;
modelica_metatype tmpMeta598;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta586 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta587 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta587,1,1) == 0) goto tmp3_end;
tmpMeta588 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta587), 2));
if (4 != MMC_STRLEN(tmpMeta588) || strcmp(MMC_STRINGDATA(_OMC_LIT42), MMC_STRINGDATA(tmpMeta588)) != 0) goto tmp3_end;
tmpMeta589 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta589)) goto tmp3_end;
tmpMeta590 = MMC_CAR(tmpMeta589);
tmpMeta591 = MMC_CDR(tmpMeta589);
if (!listEmpty(tmpMeta591)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta592 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta592,1,1) == 0) goto tmp3_end;
tmpMeta593 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta592), 2));
if (4 != MMC_STRLEN(tmpMeta593) || strcmp(MMC_STRINGDATA(_OMC_LIT41), MMC_STRINGDATA(tmpMeta593)) != 0) goto tmp3_end;
tmpMeta594 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta594)) goto tmp3_end;
tmpMeta595 = MMC_CAR(tmpMeta594);
tmpMeta596 = MMC_CDR(tmpMeta594);
if (!listEmpty(tmpMeta596)) goto tmp3_end;
_ty = tmpMeta586;
_e1 = tmpMeta590;
_e2 = tmpMeta595;
tmp4 += 7;
tmp597 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp597) goto goto_2;
tmpMeta598 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT40, tmpMeta598, _ty);
goto tmp3_done;
}
case 77: {
modelica_metatype tmpMeta599;
modelica_metatype tmpMeta600;
modelica_metatype tmpMeta601;
modelica_metatype tmpMeta602;
modelica_metatype tmpMeta603;
modelica_metatype tmpMeta604;
modelica_metatype tmpMeta605;
modelica_metatype tmpMeta606;
modelica_metatype tmpMeta607;
modelica_metatype tmpMeta608;
modelica_metatype tmpMeta609;
modelica_boolean tmp610;
modelica_metatype tmpMeta611;
modelica_metatype tmpMeta612;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta599 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta600 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta600,1,1) == 0) goto tmp3_end;
tmpMeta601 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta600), 2));
if (4 != MMC_STRLEN(tmpMeta601) || strcmp(MMC_STRINGDATA(_OMC_LIT40), MMC_STRINGDATA(tmpMeta601)) != 0) goto tmp3_end;
tmpMeta602 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta602)) goto tmp3_end;
tmpMeta603 = MMC_CAR(tmpMeta602);
tmpMeta604 = MMC_CDR(tmpMeta602);
if (!listEmpty(tmpMeta604)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta605 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta605,1,1) == 0) goto tmp3_end;
tmpMeta606 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta605), 2));
if (4 != MMC_STRLEN(tmpMeta606) || strcmp(MMC_STRINGDATA(_OMC_LIT42), MMC_STRINGDATA(tmpMeta606)) != 0) goto tmp3_end;
tmpMeta607 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta607)) goto tmp3_end;
tmpMeta608 = MMC_CAR(tmpMeta607);
tmpMeta609 = MMC_CDR(tmpMeta607);
if (!listEmpty(tmpMeta609)) goto tmp3_end;
_op2 = tmp4_1;
_ty = tmpMeta599;
_e1 = tmpMeta603;
_e2 = tmpMeta608;
tmp4 += 6;
tmp610 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp610) goto goto_2;
_e3 = _OMC_LIT27;
tmpMeta611 = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e4 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT41, tmpMeta611, _ty);
tmpMeta612 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op2, _e4);
tmpMeta1 = tmpMeta612;
goto tmp3_done;
}
case 78: {
modelica_metatype tmpMeta613;
modelica_metatype tmpMeta614;
modelica_metatype tmpMeta615;
modelica_metatype tmpMeta616;
modelica_metatype tmpMeta617;
modelica_metatype tmpMeta618;
modelica_metatype tmpMeta619;
modelica_metatype tmpMeta620;
modelica_metatype tmpMeta621;
modelica_metatype tmpMeta622;
modelica_metatype tmpMeta623;
modelica_boolean tmp624;
modelica_metatype tmpMeta625;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta613 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta614 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta614,1,1) == 0) goto tmp3_end;
tmpMeta615 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta614), 2));
if (4 != MMC_STRLEN(tmpMeta615) || strcmp(MMC_STRINGDATA(_OMC_LIT42), MMC_STRINGDATA(tmpMeta615)) != 0) goto tmp3_end;
tmpMeta616 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta616)) goto tmp3_end;
tmpMeta617 = MMC_CAR(tmpMeta616);
tmpMeta618 = MMC_CDR(tmpMeta616);
if (!listEmpty(tmpMeta618)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta619 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta619,1,1) == 0) goto tmp3_end;
tmpMeta620 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta619), 2));
if (4 != MMC_STRLEN(tmpMeta620) || strcmp(MMC_STRINGDATA(_OMC_LIT40), MMC_STRINGDATA(tmpMeta620)) != 0) goto tmp3_end;
tmpMeta621 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta621)) goto tmp3_end;
tmpMeta622 = MMC_CAR(tmpMeta621);
tmpMeta623 = MMC_CDR(tmpMeta621);
if (!listEmpty(tmpMeta623)) goto tmp3_end;
_ty = tmpMeta613;
_e1 = tmpMeta617;
_e2 = tmpMeta622;
tmp4 += 5;
tmp624 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp624) goto goto_2;
tmpMeta625 = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT41, tmpMeta625, _ty);
goto tmp3_done;
}
case 79: {
modelica_metatype tmpMeta626;
modelica_metatype tmpMeta627;
modelica_metatype tmpMeta628;
modelica_metatype tmpMeta629;
modelica_metatype tmpMeta630;
modelica_metatype tmpMeta631;
modelica_metatype tmpMeta632;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta626 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,8,2) == 0) goto tmp3_end;
tmpMeta627 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta627,5,1) == 0) goto tmp3_end;
tmpMeta628 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_ty = tmpMeta626;
_e2 = tmpMeta628;
_e1 = tmp4_2;
tmp4 += 4;
tmpMeta629 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _ty);
tmpMeta630 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta629, _e1);
_e1_1 = tmpMeta630;
tmpMeta631 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta632 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, tmpMeta631, _e2);
tmpMeta1 = tmpMeta632;
goto tmp3_done;
}
case 80: {
modelica_metatype tmpMeta633;
modelica_metatype tmpMeta634;
modelica_metatype tmpMeta635;
modelica_metatype tmpMeta636;
modelica_metatype tmpMeta637;
modelica_metatype tmpMeta638;
modelica_metatype tmpMeta639;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,18,4) == 0) goto tmp3_end;
tmpMeta633 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta634 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta635 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta636 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
_ty = tmpMeta633;
_e1 = tmpMeta634;
_oexp = tmpMeta635;
_e2 = tmpMeta636;
tmpMeta637 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _inOperator2, _rhs);
_e1 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta637, _inOperator2, _e1, _rhs);
tmpMeta638 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _inOperator2, _rhs);
_e2 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta638, _inOperator2, _e2, _rhs);
tmpMeta639 = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, _ty, _e1, _oexp, _e2);
tmpMeta1 = tmpMeta639;
goto tmp3_done;
}
case 81: {
modelica_metatype tmpMeta640;
modelica_metatype tmpMeta641;
modelica_metatype tmpMeta642;
modelica_metatype tmpMeta643;
modelica_metatype tmpMeta644;
modelica_metatype tmpMeta645;
modelica_metatype tmpMeta646;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,18,4) == 0) goto tmp3_end;
tmpMeta640 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta641 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta642 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
tmpMeta643 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
_ty = tmpMeta640;
_e1 = tmpMeta641;
_oexp = tmpMeta642;
_e2 = tmpMeta643;
tmp4 += 2;
tmpMeta644 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _lhs, _inOperator2, _e1);
_e1 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta644, _inOperator2, _lhs, _e1);
tmpMeta645 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _lhs, _inOperator2, _e1);
_e2 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta645, _inOperator2, _lhs, _e2);
tmpMeta646 = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, _ty, _e1, _oexp, _e2);
tmpMeta1 = tmpMeta646;
goto tmp3_done;
}
case 82: {
modelica_metatype tmpMeta647;
modelica_metatype tmpMeta648;
modelica_metatype tmpMeta649;
modelica_metatype tmpMeta650;
modelica_metatype tmpMeta651;
modelica_metatype tmpMeta652;
modelica_metatype tmpMeta653;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,18,4) == 0) goto tmp3_end;
tmpMeta647 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta648 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta649 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta650 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 5));
_ty = tmpMeta647;
_e1 = tmpMeta648;
_oexp = tmpMeta649;
_e2 = tmpMeta650;
tmpMeta651 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _inOperator2, _rhs);
_e1 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta651, _inOperator2, _e1, _rhs);
tmpMeta652 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _inOperator2, _rhs);
_e2 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta652, _inOperator2, _e2, _rhs);
tmpMeta653 = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, _ty, _e1, _oexp, _e2);
tmpMeta1 = tmpMeta653;
goto tmp3_done;
}
case 83: {
modelica_metatype tmpMeta654;
modelica_metatype tmpMeta655;
modelica_metatype tmpMeta656;
modelica_metatype tmpMeta657;
modelica_metatype tmpMeta658;
modelica_metatype tmpMeta659;
modelica_metatype tmpMeta660;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,18,4) == 0) goto tmp3_end;
tmpMeta654 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta655 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta656 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
tmpMeta657 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 5));
_ty = tmpMeta654;
_e1 = tmpMeta655;
_oexp = tmpMeta656;
_e2 = tmpMeta657;
tmpMeta658 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _lhs, _inOperator2, _e1);
_e1 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta658, _inOperator2, _lhs, _e1);
tmpMeta659 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _lhs, _inOperator2, _e1);
_e2 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta659, _inOperator2, _lhs, _e2);
tmpMeta660 = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, _ty, _e1, _oexp, _e2);
tmpMeta1 = tmpMeta660;
goto tmp3_done;
}
case 84: {
tmpMeta1 = _origExp;
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
if (++tmp4 < 85) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryCommutativeWork(threadData_t *threadData, modelica_metatype _op, modelica_metatype _lhs, modelica_metatype _rhs)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _op;
tmp4_2 = _lhs;
tmp4_3 = _rhs;
{
modelica_metatype _e3 = NULL;
modelica_metatype _e4 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _op1 = NULL;
modelica_metatype _op2 = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _tp2 = NULL;
modelica_real _r1;
modelica_real _r2;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 22; tmp4++) {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (3 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (!listEmpty(tmpMeta10)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (3 != MMC_STRLEN(tmpMeta12) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta12)) != 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (!listEmpty(tmpMeta15)) goto tmp3_end;
_e1 = tmpMeta9;
_e2 = tmpMeta14;
tmp4 += 8;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
_op1 = _OMC_LIT34;
tmpMeta16 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT29, _op1, _e1);
_e = tmpMeta16;
tmpMeta17 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
_e = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT39, tmpMeta17, _OMC_LIT30);
tmpMeta18 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT33, _op1, _e);
tmpMeta1 = tmpMeta18;
goto tmp3_done;
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
modelica_real tmp29;
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
modelica_real tmp40;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,13,3) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,1,1) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 2));
if (3 != MMC_STRLEN(tmpMeta21) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta21)) != 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 3));
if (listEmpty(tmpMeta22)) goto tmp3_end;
tmpMeta23 = MMC_CAR(tmpMeta22);
tmpMeta24 = MMC_CDR(tmpMeta22);
if (!listEmpty(tmpMeta24)) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,4,1) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,1,1) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,1,1) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 2));
tmp29 = mmc_unbox_real(tmpMeta28);
if (2.0 != tmp29) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta30,13,3) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,1,1) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 2));
if (3 != MMC_STRLEN(tmpMeta32) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta32)) != 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 3));
if (listEmpty(tmpMeta33)) goto tmp3_end;
tmpMeta34 = MMC_CAR(tmpMeta33);
tmpMeta35 = MMC_CDR(tmpMeta33);
if (!listEmpty(tmpMeta35)) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta36,4,1) == 0) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta36), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta37,1,1) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta38,1,1) == 0) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 2));
tmp40 = mmc_unbox_real(tmpMeta39);
if (2.0 != tmp40) goto tmp3_end;
_e1 = tmpMeta23;
_e2 = tmpMeta34;
tmp4 += 5;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta1 = _OMC_LIT27;
goto tmp3_done;
}
case 2: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta42,1,1) == 0) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta42), 2));
if (3 != MMC_STRLEN(tmpMeta43) || strcmp(MMC_STRINGDATA(_OMC_LIT37), MMC_STRINGDATA(tmpMeta43)) != 0) goto tmp3_end;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta44)) goto tmp3_end;
tmpMeta45 = MMC_CAR(tmpMeta44);
tmpMeta46 = MMC_CDR(tmpMeta44);
if (!listEmpty(tmpMeta46)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta47,1,1) == 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta47), 2));
if (3 != MMC_STRLEN(tmpMeta48) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta48)) != 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta49)) goto tmp3_end;
tmpMeta50 = MMC_CAR(tmpMeta49);
tmpMeta51 = MMC_CDR(tmpMeta49);
if (!listEmpty(tmpMeta51)) goto tmp3_end;
_tp = tmpMeta41;
_e1 = tmpMeta45;
_e2 = tmpMeta50;
tmp4 += 6;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta52 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT39, tmpMeta52, _tp);
goto tmp3_done;
}
case 3: {
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
modelica_real tmp63;
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
modelica_real tmp76;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta53,13,3) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta53), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta54,1,1) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 2));
if (4 != MMC_STRLEN(tmpMeta55) || strcmp(MMC_STRINGDATA(_OMC_LIT41), MMC_STRINGDATA(tmpMeta55)) != 0) goto tmp3_end;
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta53), 3));
if (listEmpty(tmpMeta56)) goto tmp3_end;
tmpMeta57 = MMC_CAR(tmpMeta56);
tmpMeta58 = MMC_CDR(tmpMeta56);
if (!listEmpty(tmpMeta58)) goto tmp3_end;
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta59,4,1) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta59), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta60,1,1) == 0) goto tmp3_end;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta61,1,1) == 0) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta61), 2));
tmp63 = mmc_unbox_real(tmpMeta62);
if (2.0 != tmp63) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,8,2) == 0) goto tmp3_end;
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta64,5,1) == 0) goto tmp3_end;
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta65,7,3) == 0) goto tmp3_end;
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta66,13,3) == 0) goto tmp3_end;
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta66), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta67,1,1) == 0) goto tmp3_end;
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta67), 2));
if (4 != MMC_STRLEN(tmpMeta68) || strcmp(MMC_STRINGDATA(_OMC_LIT42), MMC_STRINGDATA(tmpMeta68)) != 0) goto tmp3_end;
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta66), 3));
if (listEmpty(tmpMeta69)) goto tmp3_end;
tmpMeta70 = MMC_CAR(tmpMeta69);
tmpMeta71 = MMC_CDR(tmpMeta69);
if (!listEmpty(tmpMeta71)) goto tmp3_end;
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta72,4,1) == 0) goto tmp3_end;
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta72), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta73,1,1) == 0) goto tmp3_end;
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta74,1,1) == 0) goto tmp3_end;
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 2));
tmp76 = mmc_unbox_real(tmpMeta75);
if (2.0 != tmp76) goto tmp3_end;
_e1 = tmpMeta57;
_e2 = tmpMeta70;
tmp4 += 1;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta1 = _OMC_LIT27;
goto tmp3_done;
}
case 4: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta78,1,1) == 0) goto tmp3_end;
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta78), 2));
if (4 != MMC_STRLEN(tmpMeta79) || strcmp(MMC_STRINGDATA(_OMC_LIT40), MMC_STRINGDATA(tmpMeta79)) != 0) goto tmp3_end;
tmpMeta80 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta80)) goto tmp3_end;
tmpMeta81 = MMC_CAR(tmpMeta80);
tmpMeta82 = MMC_CDR(tmpMeta80);
if (!listEmpty(tmpMeta82)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,13,3) == 0) goto tmp3_end;
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta83,1,1) == 0) goto tmp3_end;
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta83), 2));
if (4 != MMC_STRLEN(tmpMeta84) || strcmp(MMC_STRINGDATA(_OMC_LIT41), MMC_STRINGDATA(tmpMeta84)) != 0) goto tmp3_end;
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (listEmpty(tmpMeta85)) goto tmp3_end;
tmpMeta86 = MMC_CAR(tmpMeta85);
tmpMeta87 = MMC_CDR(tmpMeta85);
if (!listEmpty(tmpMeta87)) goto tmp3_end;
_tp = tmpMeta77;
_e1 = tmpMeta81;
_e2 = tmpMeta86;
tmp4 += 4;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta88 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT42, tmpMeta88, _tp);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta89 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,8,2) == 0) goto tmp3_end;
tmpMeta90 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta90,5,1) == 0) goto tmp3_end;
tmpMeta91 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_tp = tmpMeta89;
_e2 = tmpMeta91;
_e1 = tmp4_2;
tmp4 += 1;
tmpMeta92 = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _tp);
tmpMeta93 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta92, _e2);
tmpMeta1 = tmpMeta93;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta95 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta95,8,2) == 0) goto tmp3_end;
tmpMeta96 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta95), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta96,5,1) == 0) goto tmp3_end;
tmpMeta97 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta95), 3));
tmpMeta98 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmpMeta99 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_tp = tmpMeta94;
_e2 = tmpMeta97;
_op2 = tmpMeta98;
_e3 = tmpMeta99;
_e1 = tmp4_2;
if (!omc_Expression_isMulOrDiv(threadData, _op2)) goto tmp3_end;
tmpMeta100 = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _tp);
tmpMeta101 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op2, _e3);
tmpMeta102 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta100, tmpMeta101);
tmpMeta1 = tmpMeta102;
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
_e2 = tmp4_3;
tmp4 += 8;
if (!omc_Expression_isZero(threadData, _e1)) goto tmp3_end;
tmpMeta1 = _e2;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta103;
modelica_metatype tmpMeta104;
modelica_metatype tmpMeta105;
modelica_metatype tmpMeta106;
modelica_metatype tmpMeta107;
modelica_boolean tmp108;
modelica_metatype tmpMeta109;
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
modelica_metatype tmpMeta113;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta103 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta104 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta105 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta105,3,1) == 0) goto tmp3_end;
tmpMeta106 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta105), 2));
tmpMeta107 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_tp = tmpMeta103;
_e2 = tmpMeta104;
_tp2 = tmpMeta106;
_e3 = tmpMeta107;
_e1 = tmp4_2;
tmpMeta109 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
tmpMeta110 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta109, _e2);
tmpMeta111 = omc_ExpressionSimplify_simplify1(threadData, tmpMeta110, &tmp108);
_e = tmpMeta111;
if (1 != tmp108) goto goto_2;
tmpMeta112 = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _tp2);
tmpMeta113 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, tmpMeta112, _e3);
tmpMeta1 = tmpMeta113;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
_e2 = tmp4_3;
if (!omc_Expression_isZero(threadData, _e2)) goto tmp3_end;
tmpMeta1 = _e2;
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
_e1 = tmp4_2;
_e2 = tmp4_3;
if (!omc_Expression_isConstOne(threadData, _e2)) goto tmp3_end;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta114;
modelica_metatype tmpMeta115;
modelica_metatype tmpMeta116;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta114 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_ty = tmpMeta114;
_e1 = tmp4_2;
_e2 = tmp4_3;
if (!omc_Expression_isConstMinusOne(threadData, _e2)) goto tmp3_end;
tmpMeta115 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _ty);
tmpMeta116 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta115, _e1);
tmpMeta1 = tmpMeta116;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta117;
modelica_metatype tmpMeta118;
modelica_metatype tmpMeta119;
modelica_metatype tmpMeta120;
modelica_metatype tmpMeta121;
modelica_metatype tmpMeta122;
modelica_metatype tmpMeta123;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,3) == 0) goto tmp3_end;
tmpMeta117 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta118 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta118,2,1) == 0) goto tmp3_end;
tmpMeta119 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta118), 2));
tmpMeta120 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_e2 = tmpMeta117;
_op1 = tmpMeta118;
_ty = tmpMeta119;
_e3 = tmpMeta120;
_e1 = tmp4_3;
if (!(omc_Types_isScalarReal(threadData, _ty) && omc_Expression_expEqual(threadData, _e2, _e1))) goto tmp3_end;
tmpMeta121 = mmc_mk_box2(7, &DAE_Operator_POW__desc, _ty);
tmpMeta122 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta121, _OMC_LIT29);
tmpMeta123 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op1, tmpMeta122);
tmpMeta1 = tmpMeta123;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta124;
modelica_metatype tmpMeta125;
modelica_metatype tmpMeta126;
modelica_metatype tmpMeta127;
modelica_metatype tmpMeta128;
modelica_metatype tmpMeta129;
modelica_metatype tmpMeta130;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta124 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta125 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta125,2,1) == 0) goto tmp3_end;
tmpMeta126 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta125), 2));
tmpMeta127 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_e2 = tmpMeta124;
_op1 = tmpMeta125;
_ty = tmpMeta126;
_e3 = tmpMeta127;
_e1 = tmp4_2;
if (!(omc_Types_isScalarReal(threadData, _ty) && omc_Expression_expEqual(threadData, _e1, _e3))) goto tmp3_end;
tmpMeta128 = mmc_mk_box2(7, &DAE_Operator_POW__desc, _ty);
tmpMeta129 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta128, _OMC_LIT29);
tmpMeta130 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, tmpMeta129);
tmpMeta1 = tmpMeta130;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta131;
modelica_real tmp132;
modelica_metatype tmpMeta133;
modelica_metatype tmpMeta134;
modelica_real tmp135;
modelica_metatype tmpMeta136;
modelica_metatype tmpMeta137;
modelica_metatype tmpMeta138;
modelica_metatype tmpMeta139;
modelica_metatype tmpMeta140;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta131 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp132 = mmc_unbox_real(tmpMeta131);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta133 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta133,1,1) == 0) goto tmp3_end;
tmpMeta134 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta133), 2));
tmp135 = mmc_unbox_real(tmpMeta134);
tmpMeta136 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta136,2,1) == 0) goto tmp3_end;
tmpMeta137 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta136), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta137,1,1) == 0) goto tmp3_end;
tmpMeta138 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_r1 = tmp132;
_r2 = tmp135;
_e2 = tmpMeta138;
tmpMeta139 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real((_r1) * (_r2)));
tmpMeta140 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta139, _OMC_LIT34, _e2);
tmpMeta1 = tmpMeta140;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta141;
modelica_real tmp142;
modelica_metatype tmpMeta143;
modelica_metatype tmpMeta144;
modelica_metatype tmpMeta145;
modelica_metatype tmpMeta146;
modelica_metatype tmpMeta147;
modelica_real tmp148;
modelica_metatype tmpMeta149;
modelica_metatype tmpMeta150;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta141 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp142 = mmc_unbox_real(tmpMeta141);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta143 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta144 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta144,2,1) == 0) goto tmp3_end;
tmpMeta145 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta144), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta145,1,1) == 0) goto tmp3_end;
tmpMeta146 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta146,1,1) == 0) goto tmp3_end;
tmpMeta147 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta146), 2));
tmp148 = mmc_unbox_real(tmpMeta147);
_r1 = tmp142;
_e2 = tmpMeta143;
_r2 = tmp148;
tmp4 += 6;
tmpMeta149 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real((_r1) * (_r2)));
tmpMeta150 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta149, _OMC_LIT34, _e2);
tmpMeta1 = tmpMeta150;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta151;
modelica_real tmp152;
modelica_metatype tmpMeta153;
modelica_metatype tmpMeta154;
modelica_real tmp155;
modelica_metatype tmpMeta156;
modelica_metatype tmpMeta157;
modelica_metatype tmpMeta158;
modelica_metatype tmpMeta159;
modelica_metatype tmpMeta160;
modelica_metatype tmpMeta161;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta151 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp152 = mmc_unbox_real(tmpMeta151);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta153 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta153,1,1) == 0) goto tmp3_end;
tmpMeta154 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta153), 2));
tmp155 = mmc_unbox_real(tmpMeta154);
tmpMeta156 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta156,1,1) == 0) goto tmp3_end;
tmpMeta157 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta156), 2));
tmpMeta158 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta158,6,2) == 0) goto tmp3_end;
_r1 = tmp152;
_r2 = tmp155;
_ty = tmpMeta157;
_e1 = tmpMeta158;
tmp4 += 5;
tmpMeta159 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r1 + _r2));
tmpMeta160 = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _ty);
tmpMeta161 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta159, tmpMeta160, _e1);
tmpMeta1 = tmpMeta161;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta162;
modelica_metatype tmpMeta163;
modelica_metatype tmpMeta164;
modelica_metatype tmpMeta165;
modelica_metatype tmpMeta166;
modelica_metatype tmpMeta167;
modelica_metatype tmpMeta168;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta162 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta163 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta163,1,1) == 0) goto tmp3_end;
tmpMeta164 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta163), 2));
if (3 != MMC_STRLEN(tmpMeta164) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmpMeta164)) != 0) goto tmp3_end;
tmpMeta165 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta165)) goto tmp3_end;
tmpMeta166 = MMC_CAR(tmpMeta165);
tmpMeta167 = MMC_CDR(tmpMeta165);
if (!listEmpty(tmpMeta167)) goto tmp3_end;
_ty = tmpMeta162;
_e1 = tmpMeta166;
_e2 = tmp4_3;
tmp4 += 4;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta168 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT43, tmpMeta168, _ty);
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta169;
modelica_metatype tmpMeta170;
modelica_metatype tmpMeta171;
modelica_metatype tmpMeta172;
modelica_metatype tmpMeta173;
modelica_metatype tmpMeta174;
modelica_metatype tmpMeta175;
modelica_metatype tmpMeta176;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta169 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta170 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta171 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta171,2,1) == 0) goto tmp3_end;
tmpMeta172 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_op1 = tmp4_1;
_ty = tmpMeta169;
_e2 = tmpMeta170;
_op2 = tmpMeta171;
_e3 = tmpMeta172;
_e1 = tmp4_2;
tmp4 += 3;
if (!(!omc_Expression_isConstValue(threadData, _e1))) goto tmp3_end;
if(omc_Expression_expEqual(threadData, _e1, _e3))
{
tmpMeta173 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, omc_Expression_makeConstOne(threadData, _ty), _op1, _e2);
tmpMeta174 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, tmpMeta173);
_exp = tmpMeta174;
}
else
{
if(omc_Expression_expEqual(threadData, _e1, _e2))
{
tmpMeta175 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, omc_Expression_makeConstOne(threadData, _ty), _op1, _e3);
tmpMeta176 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, tmpMeta175);
_exp = tmpMeta176;
}
else
{
goto goto_2;
}
}
tmpMeta1 = _exp;
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta177;
modelica_metatype tmpMeta178;
modelica_metatype tmpMeta179;
modelica_metatype tmpMeta180;
modelica_metatype tmpMeta181;
modelica_metatype tmpMeta182;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta177 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta177,1,1) == 0) goto tmp3_end;
tmpMeta178 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta177), 2));
if (4 != MMC_STRLEN(tmpMeta178) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta178)) != 0) goto tmp3_end;
tmpMeta179 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta179)) goto tmp3_end;
tmpMeta180 = MMC_CAR(tmpMeta179);
tmpMeta181 = MMC_CDR(tmpMeta179);
if (!listEmpty(tmpMeta181)) goto tmp3_end;
_e1 = tmpMeta180;
_e2 = tmp4_3;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta182 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _OMC_LIT36, _OMC_LIT45);
tmpMeta1 = tmpMeta182;
goto tmp3_done;
}
case 20: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta183 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta184 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta184,4,1) == 0) goto tmp3_end;
tmpMeta185 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta186 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta186,1,1) == 0) goto tmp3_end;
tmpMeta187 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta186), 2));
if (4 != MMC_STRLEN(tmpMeta187) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta187)) != 0) goto tmp3_end;
tmpMeta188 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta188)) goto tmp3_end;
tmpMeta189 = MMC_CAR(tmpMeta188);
tmpMeta190 = MMC_CDR(tmpMeta188);
if (!listEmpty(tmpMeta190)) goto tmp3_end;
_e2 = tmpMeta183;
_e = tmpMeta185;
_e1 = tmpMeta189;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta191 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT46, _OMC_LIT33);
tmpMeta192 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _OMC_LIT36, tmpMeta191);
tmpMeta1 = tmpMeta192;
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta193;
modelica_metatype tmpMeta194;
modelica_metatype tmpMeta195;
modelica_metatype tmpMeta196;
modelica_metatype tmpMeta197;
modelica_metatype tmpMeta198;
modelica_metatype tmpMeta199;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,7,3) == 0) goto tmp3_end;
tmpMeta193 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta194 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta194,4,1) == 0) goto tmp3_end;
tmpMeta195 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta194), 2));
tmpMeta196 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_e3 = tmpMeta193;
_op1 = tmpMeta194;
_tp = tmpMeta195;
_e4 = tmpMeta196;
_e1 = tmp4_2;
if (!omc_Expression_expEqual(threadData, _e1, _e3)) goto tmp3_end;
_e = omc_Expression_makeConstOne(threadData, _tp);
tmpMeta197 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _tp);
tmpMeta198 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, tmpMeta197, _e4);
tmpMeta199 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, tmpMeta198);
tmpMeta1 = tmpMeta199;
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
if (++tmp4 < 22) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_exp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _exp;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_safeIntOp(threadData_t *threadData, modelica_integer _val1, modelica_integer _val2, modelica_metatype _op)
{
modelica_metatype _outv = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _op;
{
modelica_real _rv1;
modelica_real _rv2;
modelica_real _rv3;
modelica_integer _ires;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
_rv1 = ((modelica_real)_val1);
_rv2 = ((modelica_real)_val2);
_rv3 = (_rv1) * (_rv2);
tmpMeta1 = omc_Expression_realToIntIfPossible(threadData, _rv3);
goto tmp3_done;
}
case 4: {
modelica_integer tmp5;
modelica_metatype tmpMeta6;
tmp5 = _val2;
if (tmp5 == 0) {goto goto_2;}
_ires = ldiv(_val1,tmp5).quot;
tmpMeta6 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_ires));
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 6: {
_rv1 = ((modelica_real)_val1);
_rv2 = ((modelica_real)_val2);
_rv3 = _rv1 - _rv2;
tmpMeta1 = omc_Expression_realToIntIfPossible(threadData, _rv3);
goto tmp3_done;
}
case 5: {
_rv1 = ((modelica_real)_val1);
_rv2 = ((modelica_real)_val2);
_rv3 = _rv1 + _rv2;
tmpMeta1 = omc_Expression_realToIntIfPossible(threadData, _rv3);
goto tmp3_done;
}
case 7: {
modelica_real tmp7;
modelica_real tmp8;
modelica_real tmp9;
modelica_real tmp10;
modelica_real tmp11;
modelica_real tmp12;
modelica_real tmp13;
_rv1 = ((modelica_real)_val1);
_rv2 = ((modelica_real)_val2);
tmp7 = _rv1;
tmp8 = _rv2;
if(tmp7 < 0.0 && tmp8 != 0.0)
{
tmp10 = modf(tmp8, &tmp11);
if(tmp10 > 0.5)
{
tmp10 -= 1.0;
tmp11 += 1.0;
}
else if(tmp10 < -0.5)
{
tmp10 += 1.0;
tmp11 -= 1.0;
}
if(fabs(tmp10) < 1e-10)
tmp9 = pow(tmp7, tmp11);
else
{
tmp13 = modf(1.0/tmp8, &tmp12);
if(tmp13 > 0.5)
{
tmp13 -= 1.0;
tmp12 += 1.0;
}
else if(tmp13 < -0.5)
{
tmp13 += 1.0;
tmp12 -= 1.0;
}
if(fabs(tmp13) < 1e-10 && ((unsigned long)tmp12 & 1))
{
tmp9 = -pow(-tmp7, tmp10)*pow(tmp7, tmp11);
}
else
{
goto goto_2;
}
}
}
else
{
tmp9 = pow(tmp7, tmp8);
}
if(isnan(tmp9) || isinf(tmp9))
{
goto goto_2;
}
_rv3 = tmp9;
tmpMeta1 = omc_Expression_realToIntIfPossible(threadData, _rv3);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outv = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outv;
}
modelica_metatype boxptr_ExpressionSimplify_safeIntOp(threadData_t *threadData, modelica_metatype _val1, modelica_metatype _val2, modelica_metatype _op)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outv = NULL;
tmp1 = mmc_unbox_integer(_val1);
tmp2 = mmc_unbox_integer(_val2);
_outv = omc_ExpressionSimplify_safeIntOp(threadData, tmp1, tmp2, _op);
return _outv;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ExpressionSimplify_simplifyRelationConst(threadData_t *threadData, modelica_metatype _op, modelica_metatype _e1, modelica_metatype _e2)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _op;
tmp4_2 = _e1;
tmp4_3 = _e2;
{
modelica_real _v1;
modelica_real _v2;
modelica_boolean _b1;
modelica_boolean _b2;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 14; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,25,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (0 != tmp7) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
if (1 != tmp9) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,25,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,25,1) == 0) goto tmp3_end;
_v1 = omc_Expression_toReal(threadData, _e1);
_v2 = omc_Expression_toReal(threadData, _e2);
tmp1 = (_v1 < _v2);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta10;
modelica_integer tmp11;
modelica_metatype tmpMeta12;
modelica_integer tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,26,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp11 = mmc_unbox_integer(tmpMeta10);
if (1 != tmp11) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp13 = mmc_unbox_integer(tmpMeta12);
if (0 != tmp13) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,26,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,26,1) == 0) goto tmp3_end;
_v1 = omc_Expression_toReal(threadData, _e1);
_v2 = omc_Expression_toReal(threadData, _e2);
tmp1 = (_v1 <= _v2);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
modelica_integer tmp17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,29,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
_b1 = tmp15;
_b2 = tmp17;
tmp1 = ((!_b1 && !_b2) || (_b1 && _b2));
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,29,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_s1 = tmpMeta18;
_s2 = tmpMeta19;
tmp1 = (stringEqual(_s1, _s2));
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,29,1) == 0) goto tmp3_end;
_v1 = omc_Expression_toReal(threadData, _e1);
_v2 = omc_Expression_toReal(threadData, _e2);
tmp1 = (_v1 == _v2);
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,1) == 0) goto tmp3_end;
tmp1 = (!omc_ExpressionSimplify_simplifyRelationConst(threadData, _OMC_LIT47, _e1, _e2));
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,28,1) == 0) goto tmp3_end;
tmp1 = (!omc_ExpressionSimplify_simplifyRelationConst(threadData, _OMC_LIT48, _e1, _e2));
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta20;
modelica_integer tmp21;
modelica_metatype tmpMeta22;
modelica_integer tmp23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp21 = mmc_unbox_integer(tmpMeta20);
if (0 != tmp21) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp23 = mmc_unbox_integer(tmpMeta22);
if (1 != tmp23) goto tmp3_end;
tmp1 = (!omc_ExpressionSimplify_simplifyRelationConst(threadData, _OMC_LIT47, _e1, _e2));
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta24;
modelica_integer tmp25;
modelica_metatype tmpMeta26;
modelica_integer tmp27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,28,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp25 = mmc_unbox_integer(tmpMeta24);
if (0 != tmp25) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp27 = mmc_unbox_integer(tmpMeta26);
if (1 != tmp27) goto tmp3_end;
tmp1 = (!omc_ExpressionSimplify_simplifyRelationConst(threadData, _OMC_LIT48, _e1, _e2));
goto tmp3_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,30,1) == 0) goto tmp3_end;
tmp1 = (!omc_ExpressionSimplify_simplifyRelationConst(threadData, _OMC_LIT49, _e1, _e2));
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyRelationConst(threadData_t *threadData, modelica_metatype _op, modelica_metatype _e1, modelica_metatype _e2)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_ExpressionSimplify_simplifyRelationConst(threadData, _op, _e1, _e2);
out_b = mmc_mk_icon(_b);
return out_b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryConst(threadData_t *threadData, modelica_metatype _inOperator1, modelica_metatype _inExp2, modelica_metatype _inExp3)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inOperator1;
tmp4_2 = _inExp2;
tmp4_3 = _inExp3;
{
modelica_integer _ie1;
modelica_integer _ie2;
modelica_real _e2_1;
modelica_real _e1_1;
modelica_real _re1;
modelica_real _re2;
modelica_real _re3;
modelica_string _str = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 18; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
_ie1 = tmp7;
_ie2 = tmp9;
tmpMeta1 = omc_ExpressionSimplify_safeIntOp(threadData, _ie1, _ie2, _OMC_LIT50);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_real tmp11;
modelica_metatype tmpMeta12;
modelica_real tmp13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp11 = mmc_unbox_real(tmpMeta10);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp13 = mmc_unbox_real(tmpMeta12);
_re1 = tmp11;
_re2 = tmp13;
_re3 = _re1 + _re2;
tmpMeta14 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_real tmp16;
modelica_metatype tmpMeta17;
modelica_integer tmp18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp16 = mmc_unbox_real(tmpMeta15);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp18 = mmc_unbox_integer(tmpMeta17);
_re1 = tmp16;
_ie2 = tmp18;
_e2_1 = ((modelica_real)_ie2);
_re3 = _re1 + _e2_1;
tmpMeta19 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta19;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta20;
modelica_integer tmp21;
modelica_metatype tmpMeta22;
modelica_real tmp23;
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp21 = mmc_unbox_integer(tmpMeta20);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp23 = mmc_unbox_real(tmpMeta22);
_ie1 = tmp21;
_re2 = tmp23;
_e1_1 = ((modelica_real)_ie1);
_re3 = _e1_1 + _re2;
tmpMeta24 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta24;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,1) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_s1 = tmpMeta25;
_s2 = tmpMeta26;
tmpMeta27 = stringAppend(_s1,_s2);
_str = tmpMeta27;
tmpMeta28 = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _str);
tmpMeta1 = tmpMeta28;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta29;
modelica_integer tmp30;
modelica_metatype tmpMeta31;
modelica_integer tmp32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp30 = mmc_unbox_integer(tmpMeta29);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,1) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp32 = mmc_unbox_integer(tmpMeta31);
_ie1 = tmp30;
_ie2 = tmp32;
tmpMeta1 = omc_ExpressionSimplify_safeIntOp(threadData, _ie1, _ie2, _OMC_LIT51);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta33;
modelica_real tmp34;
modelica_metatype tmpMeta35;
modelica_real tmp36;
modelica_metatype tmpMeta37;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp34 = mmc_unbox_real(tmpMeta33);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp36 = mmc_unbox_real(tmpMeta35);
_re1 = tmp34;
_re2 = tmp36;
_re3 = _re1 - _re2;
tmpMeta37 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta37;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta38;
modelica_real tmp39;
modelica_metatype tmpMeta40;
modelica_integer tmp41;
modelica_metatype tmpMeta42;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp39 = mmc_unbox_real(tmpMeta38);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,1) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp41 = mmc_unbox_integer(tmpMeta40);
_re1 = tmp39;
_ie2 = tmp41;
_e2_1 = ((modelica_real)_ie2);
_re3 = _re1 - _e2_1;
tmpMeta42 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta42;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta43;
modelica_integer tmp44;
modelica_metatype tmpMeta45;
modelica_real tmp46;
modelica_metatype tmpMeta47;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp44 = mmc_unbox_integer(tmpMeta43);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp46 = mmc_unbox_real(tmpMeta45);
_ie1 = tmp44;
_re2 = tmp46;
_e1_1 = ((modelica_real)_ie1);
_re3 = _e1_1 - _re2;
tmpMeta47 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta47;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta48;
modelica_integer tmp49;
modelica_metatype tmpMeta50;
modelica_integer tmp51;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp49 = mmc_unbox_integer(tmpMeta48);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,1) == 0) goto tmp3_end;
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp51 = mmc_unbox_integer(tmpMeta50);
_ie1 = tmp49;
_ie2 = tmp51;
tmpMeta1 = omc_ExpressionSimplify_safeIntOp(threadData, _ie1, _ie2, _OMC_LIT52);
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta52;
modelica_real tmp53;
modelica_metatype tmpMeta54;
modelica_real tmp55;
modelica_metatype tmpMeta56;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp53 = mmc_unbox_real(tmpMeta52);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp55 = mmc_unbox_real(tmpMeta54);
_re1 = tmp53;
_re2 = tmp55;
_re3 = (_re1) * (_re2);
tmpMeta56 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta56;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta57;
modelica_real tmp58;
modelica_metatype tmpMeta59;
modelica_integer tmp60;
modelica_metatype tmpMeta61;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp58 = mmc_unbox_real(tmpMeta57);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,1) == 0) goto tmp3_end;
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp60 = mmc_unbox_integer(tmpMeta59);
_re1 = tmp58;
_ie2 = tmp60;
_e2_1 = ((modelica_real)_ie2);
_re3 = (_re1) * (_e2_1);
tmpMeta61 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta61;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta62;
modelica_integer tmp63;
modelica_metatype tmpMeta64;
modelica_real tmp65;
modelica_metatype tmpMeta66;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp63 = mmc_unbox_integer(tmpMeta62);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp65 = mmc_unbox_real(tmpMeta64);
_ie1 = tmp63;
_re2 = tmp65;
_e1_1 = ((modelica_real)_ie1);
_re3 = (_e1_1) * (_re2);
tmpMeta66 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta66;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta67;
modelica_integer tmp68;
modelica_metatype tmpMeta69;
modelica_integer tmp70;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp68 = mmc_unbox_integer(tmpMeta67);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,1) == 0) goto tmp3_end;
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp70 = mmc_unbox_integer(tmpMeta69);
_ie1 = tmp68;
_ie2 = tmp70;
tmpMeta1 = omc_ExpressionSimplify_safeIntOp(threadData, _ie1, _ie2, _OMC_LIT53);
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta71;
modelica_real tmp72;
modelica_metatype tmpMeta73;
modelica_real tmp74;
modelica_real tmp75;
modelica_metatype tmpMeta76;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp72 = mmc_unbox_real(tmpMeta71);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp74 = mmc_unbox_real(tmpMeta73);
_re1 = tmp72;
_re2 = tmp74;
tmp75 = _re2;
if (tmp75 == 0) {goto goto_2;}
_re3 = (_re1) / tmp75;
tmpMeta76 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta76;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta77;
modelica_real tmp78;
modelica_metatype tmpMeta79;
modelica_integer tmp80;
modelica_real tmp81;
modelica_metatype tmpMeta82;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp78 = mmc_unbox_real(tmpMeta77);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,0,1) == 0) goto tmp3_end;
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp80 = mmc_unbox_integer(tmpMeta79);
_re1 = tmp78;
_ie2 = tmp80;
_e2_1 = ((modelica_real)_ie2);
tmp81 = _e2_1;
if (tmp81 == 0) {goto goto_2;}
_re3 = (_re1) / tmp81;
tmpMeta82 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta82;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta83;
modelica_integer tmp84;
modelica_metatype tmpMeta85;
modelica_real tmp86;
modelica_real tmp87;
modelica_metatype tmpMeta88;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp84 = mmc_unbox_integer(tmpMeta83);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp86 = mmc_unbox_real(tmpMeta85);
_ie1 = tmp84;
_re2 = tmp86;
_e1_1 = ((modelica_real)_ie1);
tmp87 = _re2;
if (tmp87 == 0) {goto goto_2;}
_re3 = (_e1_1) / tmp87;
tmpMeta88 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta88;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta89;
modelica_real tmp90;
modelica_metatype tmpMeta91;
modelica_real tmp92;
modelica_real tmp93;
modelica_real tmp94;
modelica_real tmp95;
modelica_real tmp96;
modelica_real tmp97;
modelica_real tmp98;
modelica_real tmp99;
modelica_metatype tmpMeta100;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta89 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp90 = mmc_unbox_real(tmpMeta89);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,1) == 0) goto tmp3_end;
tmpMeta91 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp92 = mmc_unbox_real(tmpMeta91);
_re1 = tmp90;
_re2 = tmp92;
tmp93 = _re1;
tmp94 = _re2;
if(tmp93 < 0.0 && tmp94 != 0.0)
{
tmp96 = modf(tmp94, &tmp97);
if(tmp96 > 0.5)
{
tmp96 -= 1.0;
tmp97 += 1.0;
}
else if(tmp96 < -0.5)
{
tmp96 += 1.0;
tmp97 -= 1.0;
}
if(fabs(tmp96) < 1e-10)
tmp95 = pow(tmp93, tmp97);
else
{
tmp99 = modf(1.0/tmp94, &tmp98);
if(tmp99 > 0.5)
{
tmp99 -= 1.0;
tmp98 += 1.0;
}
else if(tmp99 < -0.5)
{
tmp99 += 1.0;
tmp98 -= 1.0;
}
if(fabs(tmp99) < 1e-10 && ((unsigned long)tmp98 & 1))
{
tmp95 = -pow(-tmp93, tmp96)*pow(tmp93, tmp97);
}
else
{
goto goto_2;
}
}
}
else
{
tmp95 = pow(tmp93, tmp94);
}
if(isnan(tmp95) || isinf(tmp95))
{
goto goto_2;
}
_re3 = tmp95;
tmpMeta100 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta1 = tmpMeta100;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubSlicing2(threadData_t *threadData, modelica_metatype _inSubscripts, modelica_metatype _inExp)
{
modelica_metatype _outAsub = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outAsub = omc_Expression_makeASUB(threadData, _inExp, _inSubscripts);
_return: OMC_LABEL_UNUSED
return _outAsub;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubSlicing(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inSubscripts)
{
modelica_metatype _outAsubArray = NULL;
modelica_metatype _indices = NULL;
modelica_metatype _asubs = NULL;
modelica_metatype _es = NULL;
modelica_integer _sz;
modelica_metatype _elem = NULL;
modelica_metatype _ty = NULL;
modelica_boolean _didSplit;
modelica_boolean _b;
modelica_metatype tmpMeta1;
modelica_boolean tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_didSplit = 0;
{
modelica_metatype __omcQ_24tmpVar15;
modelica_metatype* tmp2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype __omcQ_24tmpVar14;
modelica_integer tmp9;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inSubscripts;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar15 = tmpMeta3;
tmp2 = &__omcQ_24tmpVar15;
while(1) {
tmp9 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp9--;
}
if (tmp9 == 0) {
{
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 1; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
_es = omc_Expression_splitArray(threadData, omc_ExpressionSimplify_simplify1(threadData, _e, NULL) ,&_b);
_didSplit = (_didSplit || _b);
tmpMeta4 = _es;
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
}__omcQ_24tmpVar14 = tmpMeta4;
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar14,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp9 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta1 = __omcQ_24tmpVar15;
}
_indices = tmpMeta1;
tmp10 = _didSplit;
if (1 != tmp10) MMC_THROW_INTERNAL();
{
modelica_metatype _is;
for (tmpMeta11 = _indices; !listEmpty(tmpMeta11); tmpMeta11=MMC_CDR(tmpMeta11))
{
_is = MMC_CAR(tmpMeta11);
{
modelica_metatype _i;
for (tmpMeta12 = _is; !listEmpty(tmpMeta12); tmpMeta12=MMC_CDR(tmpMeta12))
{
_i = MMC_CAR(tmpMeta12);
{
modelica_metatype tmp15_1;
tmp15_1 = omc_Expression_typeof(threadData, _i);
{
int tmp15;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp15_1))) {
case 3: {
goto tmp14_done;
}
case 6: {
goto tmp14_done;
}
case 8: {
goto tmp14_done;
}
}
goto tmp14_end;
tmp14_end: ;
}
goto goto_13;
goto_13:;
MMC_THROW_INTERNAL();
goto tmp14_done;
tmp14_done:;
}
}
;
}
}
}
}
_asubs = omc_List_combinationMap1(threadData, _indices, boxvar_ExpressionSimplify_simplifyAsubSlicing2, _inExp);
_outAsubArray = omc_Expression_makeScalarArray(threadData, _asubs, omc_Types_unliftArray(threadData, omc_Expression_typeof(threadData, _inExp)));
_return: OMC_LABEL_UNUSED
return _outAsubArray;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubOperator(threadData_t *threadData, modelica_metatype _inExp1, modelica_metatype _inOperator2, modelica_metatype _inOperator3)
{
modelica_metatype _outOperator = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp1;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 19: {
tmpMeta1 = _inOperator3;
goto tmp3_done;
}
case 20: {
tmpMeta1 = _inOperator3;
goto tmp3_done;
}
case 21: {
tmpMeta1 = _inOperator3;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta1 = _inOperator2;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outOperator = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outOperator;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubArrayReduction(threadData_t *threadData, modelica_metatype _iter, modelica_metatype _sub, modelica_metatype _acc)
{
modelica_metatype _res = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _iter;
{
modelica_metatype _exp = NULL;
modelica_string _id = NULL;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta8)) goto tmp3_end;
_id = tmpMeta6;
_exp = tmpMeta7;
tmpMeta9 = mmc_mk_cons(_sub, MMC_REFSTRUCTLIT(mmc_nil));
_exp = omc_Expression_makeASUB(threadData, _exp, tmpMeta9);
tmpMeta1 = omc_ExpressionSimplify_replaceIteratorWithExp(threadData, _exp, _acc, _id);
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsub(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inSub)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inSub;
{
modelica_metatype _e_1 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e1_1 = NULL;
modelica_metatype _e2_1 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _sub = NULL;
modelica_metatype _t = NULL;
modelica_metatype _t_1 = NULL;
modelica_metatype _t2 = NULL;
modelica_integer _indx;
modelica_metatype _op = NULL;
modelica_metatype _op2 = NULL;
modelica_boolean _b;
modelica_metatype _exps = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _lstexps = NULL;
modelica_metatype _iters = NULL;
modelica_metatype _iter = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 22; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_e = tmp4_1;
_sub = tmp4_2;
tmpMeta1 = omc_ExpressionSimplify_simplifyAsub0(threadData, _e, omc_Expression_expInt(threadData, _sub), _inSub);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_boolean tmp10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta7;
_sub = tmp4_2;
tmp4 += 20;
_e_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e, _sub);
_t2 = omc_Expression_typeof(threadData, _e_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp10 = (modelica_boolean)_b;
if(tmp10)
{
tmpMeta8 = mmc_mk_box2(9, &DAE_Operator_UMINUS__ARR__desc, _t2);
tmpMeta11 = tmpMeta8;
}
else
{
tmpMeta9 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _t2);
tmpMeta11 = tmpMeta9;
}
_op2 = tmpMeta11;
tmpMeta12 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e_1);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,24,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta14;
_sub = tmp4_2;
tmp4 += 19;
_e_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e, _sub);
_t2 = omc_Expression_typeof(threadData, _e_1);
tmpMeta15 = mmc_mk_box2(27, &DAE_Operator_NOT__desc, _t2);
tmpMeta16 = mmc_mk_box3(13, &DAE_Exp_LUNARY__desc, tmpMeta15, _e_1);
tmpMeta1 = tmpMeta16;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_boolean tmp22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,8,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta17;
_e2 = tmpMeta19;
_sub = tmp4_2;
tmp4 += 18;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp22 = (modelica_boolean)_b;
if(tmp22)
{
tmpMeta20 = mmc_mk_box2(11, &DAE_Operator_SUB__ARR__desc, _t2);
tmpMeta23 = tmpMeta20;
}
else
{
tmpMeta21 = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _t2);
tmpMeta23 = tmpMeta21;
}
_op2 = tmpMeta23;
tmpMeta24 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op2, _e2_1);
tmpMeta1 = tmpMeta24;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_boolean tmp30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,11,1) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta25;
_e2 = tmpMeta27;
_sub = tmp4_2;
tmp4 += 17;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp30 = (modelica_boolean)_b;
if(tmp30)
{
tmpMeta28 = mmc_mk_box2(14, &DAE_Operator_MUL__ARRAY__SCALAR__desc, _t2);
tmpMeta31 = tmpMeta28;
}
else
{
tmpMeta29 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _t2);
tmpMeta31 = tmpMeta29;
}
_op = tmpMeta31;
tmpMeta32 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op, _e2);
tmpMeta1 = tmpMeta32;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_boolean tmp38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,12,1) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta33;
_e2 = tmpMeta35;
_sub = tmp4_2;
tmp4 += 16;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp38 = (modelica_boolean)_b;
if(tmp38)
{
tmpMeta36 = mmc_mk_box2(15, &DAE_Operator_ADD__ARRAY__SCALAR__desc, _t2);
tmpMeta39 = tmpMeta36;
}
else
{
tmpMeta37 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _t2);
tmpMeta39 = tmpMeta37;
}
_op = tmpMeta39;
tmpMeta40 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op, _e2);
tmpMeta1 = tmpMeta40;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_boolean tmp46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta42,13,1) == 0) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta41;
_e2 = tmpMeta43;
_sub = tmp4_2;
tmp4 += 15;
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e2_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp46 = (modelica_boolean)_b;
if(tmp46)
{
tmpMeta44 = mmc_mk_box2(16, &DAE_Operator_SUB__SCALAR__ARRAY__desc, _t2);
tmpMeta47 = tmpMeta44;
}
else
{
tmpMeta45 = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _t2);
tmpMeta47 = tmpMeta45;
}
_op = tmpMeta47;
tmpMeta48 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e2_1);
tmpMeta1 = tmpMeta48;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta50,15,1) == 0) goto tmp3_end;
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta49;
_e2 = tmpMeta51;
_sub = tmp4_2;
tmp4 += 14;
_e = omc_ExpressionSimplify_simplifyMatrixProduct(threadData, _e1, _e2);
tmpMeta1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e, _sub);
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_boolean tmp57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta53,17,1) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta52;
_e2 = tmpMeta54;
_sub = tmp4_2;
tmp4 += 13;
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e2_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp57 = (modelica_boolean)_b;
if(tmp57)
{
tmpMeta55 = mmc_mk_box2(20, &DAE_Operator_DIV__SCALAR__ARRAY__desc, _t2);
tmpMeta58 = tmpMeta55;
}
else
{
tmpMeta56 = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _t2);
tmpMeta58 = tmpMeta56;
}
_op = tmpMeta58;
tmpMeta59 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e2_1);
tmpMeta1 = tmpMeta59;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_boolean tmp65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta61,16,1) == 0) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta60;
_e2 = tmpMeta62;
_sub = tmp4_2;
tmp4 += 12;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp65 = (modelica_boolean)_b;
if(tmp65)
{
tmpMeta63 = mmc_mk_box2(19, &DAE_Operator_DIV__ARRAY__SCALAR__desc, _t2);
tmpMeta66 = tmpMeta63;
}
else
{
tmpMeta64 = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _t2);
tmpMeta66 = tmpMeta64;
}
_op = tmpMeta66;
tmpMeta67 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op, _e2);
tmpMeta1 = tmpMeta67;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_boolean tmp73;
modelica_metatype tmpMeta74;
modelica_metatype tmpMeta75;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta69,19,1) == 0) goto tmp3_end;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta68;
_e2 = tmpMeta70;
_sub = tmp4_2;
tmp4 += 11;
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e2_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp73 = (modelica_boolean)_b;
if(tmp73)
{
tmpMeta71 = mmc_mk_box2(22, &DAE_Operator_POW__SCALAR__ARRAY__desc, _t2);
tmpMeta74 = tmpMeta71;
}
else
{
tmpMeta72 = mmc_mk_box2(7, &DAE_Operator_POW__desc, _t2);
tmpMeta74 = tmpMeta72;
}
_op = tmpMeta74;
tmpMeta75 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e2_1);
tmpMeta1 = tmpMeta75;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_metatype tmpMeta80;
modelica_boolean tmp81;
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta77,18,1) == 0) goto tmp3_end;
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta76;
_e2 = tmpMeta78;
_sub = tmp4_2;
tmp4 += 10;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp81 = (modelica_boolean)_b;
if(tmp81)
{
tmpMeta79 = mmc_mk_box2(21, &DAE_Operator_POW__ARRAY__SCALAR__desc, _t2);
tmpMeta82 = tmpMeta79;
}
else
{
tmpMeta80 = mmc_mk_box2(7, &DAE_Operator_POW__desc, _t2);
tmpMeta82 = tmpMeta80;
}
_op = tmpMeta82;
tmpMeta83 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op, _e2);
tmpMeta1 = tmpMeta83;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
modelica_metatype tmpMeta88;
modelica_boolean tmp89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta85,7,1) == 0) goto tmp3_end;
tmpMeta86 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta84;
_e2 = tmpMeta86;
_sub = tmp4_2;
tmp4 += 9;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp89 = (modelica_boolean)_b;
if(tmp89)
{
tmpMeta87 = mmc_mk_box2(10, &DAE_Operator_ADD__ARR__desc, _t2);
tmpMeta90 = tmpMeta87;
}
else
{
tmpMeta88 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _t2);
tmpMeta90 = tmpMeta88;
}
_op2 = tmpMeta90;
tmpMeta91 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op2, _e2_1);
tmpMeta1 = tmpMeta91;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
modelica_metatype tmpMeta96;
modelica_boolean tmp97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta92 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta93 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta93,9,1) == 0) goto tmp3_end;
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta92;
_e2 = tmpMeta94;
_sub = tmp4_2;
tmp4 += 8;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp97 = (modelica_boolean)_b;
if(tmp97)
{
tmpMeta95 = mmc_mk_box2(12, &DAE_Operator_MUL__ARR__desc, _t2);
tmpMeta98 = tmpMeta95;
}
else
{
tmpMeta96 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _t2);
tmpMeta98 = tmpMeta96;
}
_op2 = tmpMeta98;
tmpMeta99 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op2, _e2_1);
tmpMeta1 = tmpMeta99;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
modelica_metatype tmpMeta104;
modelica_boolean tmp105;
modelica_metatype tmpMeta106;
modelica_metatype tmpMeta107;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta100 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta101 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta101,10,1) == 0) goto tmp3_end;
tmpMeta102 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta100;
_e2 = tmpMeta102;
_sub = tmp4_2;
tmp4 += 7;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp105 = (modelica_boolean)_b;
if(tmp105)
{
tmpMeta103 = mmc_mk_box2(13, &DAE_Operator_DIV__ARR__desc, _t2);
tmpMeta106 = tmpMeta103;
}
else
{
tmpMeta104 = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _t2);
tmpMeta106 = tmpMeta104;
}
_op2 = tmpMeta106;
tmpMeta107 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op2, _e2_1);
tmpMeta1 = tmpMeta107;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta108;
modelica_metatype tmpMeta109;
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
modelica_boolean tmp113;
modelica_metatype tmpMeta114;
modelica_metatype tmpMeta115;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta108 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta109 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta109,21,1) == 0) goto tmp3_end;
tmpMeta110 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta108;
_e2 = tmpMeta110;
_sub = tmp4_2;
tmp4 += 6;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp113 = (modelica_boolean)_b;
if(tmp113)
{
tmpMeta111 = mmc_mk_box2(24, &DAE_Operator_POW__ARR2__desc, _t2);
tmpMeta114 = tmpMeta111;
}
else
{
tmpMeta112 = mmc_mk_box2(7, &DAE_Operator_POW__desc, _t2);
tmpMeta114 = tmpMeta112;
}
_op2 = tmpMeta114;
tmpMeta115 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op2, _e2_1);
tmpMeta1 = tmpMeta115;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta116;
modelica_metatype tmpMeta117;
modelica_metatype tmpMeta118;
modelica_metatype tmpMeta119;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta116 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta117 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta118 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta116;
_op = tmpMeta117;
_e2 = tmpMeta118;
_sub = tmp4_2;
tmp4 += 5;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_op = omc_Expression_setOpType(threadData, _op, _t2);
tmpMeta119 = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _e1_1, _op, _e2_1);
tmpMeta1 = tmpMeta119;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta120;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta120 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exps = tmpMeta120;
_sub = tmp4_2;
tmp4 += 4;
_indx = omc_Expression_expInt(threadData, _sub);
tmpMeta1 = listGet(_exps, _indx);
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta121;
modelica_metatype tmpMeta122;
modelica_metatype tmpMeta123;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta121 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta122 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_t = tmpMeta121;
_lstexps = tmpMeta122;
_sub = tmp4_2;
tmp4 += 3;
_indx = omc_Expression_expInt(threadData, _sub);
_expl = listGet(_lstexps, _indx);
_t_1 = omc_Expression_unliftArray(threadData, _t);
tmpMeta123 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _t_1, mmc_mk_boolean(1), _expl);
tmpMeta1 = tmpMeta123;
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta124;
modelica_metatype tmpMeta125;
modelica_metatype tmpMeta126;
modelica_metatype tmpMeta127;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,3) == 0) goto tmp3_end;
tmpMeta124 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta125 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta126 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cond = tmpMeta124;
_e1 = tmpMeta125;
_e2 = tmpMeta126;
_sub = tmp4_2;
tmp4 += 2;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
tmpMeta127 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _cond, _e1_1, _e2_1);
tmpMeta1 = tmpMeta127;
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta128;
modelica_metatype tmpMeta129;
modelica_metatype tmpMeta130;
modelica_metatype tmpMeta131;
modelica_metatype tmpMeta132;
modelica_metatype tmpMeta133;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta128 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta129 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta128), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta129,1,1) == 0) goto tmp3_end;
tmpMeta130 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta129), 2));
if (5 != MMC_STRLEN(tmpMeta130) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta130)) != 0) goto tmp3_end;
tmpMeta131 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta128), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta131,1,0) == 0) goto tmp3_end;
tmpMeta132 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta133 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exp = tmpMeta132;
_iters = tmpMeta133;
_sub = tmp4_2;
tmp4 += 1;
tmpMeta1 = omc_List_fold1(threadData, _iters, boxvar_ExpressionSimplify_simplifyAsubArrayReduction, _sub, _exp);
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta134;
modelica_metatype tmpMeta135;
modelica_metatype tmpMeta136;
modelica_metatype tmpMeta137;
modelica_metatype tmpMeta138;
modelica_metatype tmpMeta139;
modelica_metatype tmpMeta140;
modelica_metatype tmpMeta141;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta134 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta135 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta134), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta135,1,1) == 0) goto tmp3_end;
tmpMeta136 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta135), 2));
if (5 != MMC_STRLEN(tmpMeta136) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta136)) != 0) goto tmp3_end;
tmpMeta137 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta134), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta137,0,0) == 0) goto tmp3_end;
tmpMeta138 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta139 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta139)) goto tmp3_end;
tmpMeta140 = MMC_CAR(tmpMeta139);
tmpMeta141 = MMC_CDR(tmpMeta139);
if (!listEmpty(tmpMeta141)) goto tmp3_end;
_exp = tmpMeta138;
_iter = tmpMeta140;
_sub = tmp4_2;
tmpMeta1 = omc_ExpressionSimplify_simplifyAsubArrayReduction(threadData, _iter, _sub, _exp);
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
if (++tmp4 < 22) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubCref(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _sub)
{
modelica_metatype _res = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _cr;
{
modelica_metatype _t2 = NULL;
modelica_metatype _c = NULL;
modelica_metatype _c_1 = NULL;
modelica_metatype _s = NULL;
modelica_metatype _s_1 = NULL;
modelica_string _idn = NULL;
modelica_metatype _dims = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_idn = tmpMeta6;
_t2 = tmpMeta7;
_s = tmpMeta8;
tmp4 += 3;
_s_1 = omc_Expression_subscriptsAppend(threadData, _s, _sub);
tmpMeta1 = omc_ComponentReference_makeCrefIdent(threadData, _idn, _t2, _s_1);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_boolean tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,6,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_idn = tmpMeta9;
_t2 = tmpMeta10;
_dims = tmpMeta11;
_s = tmpMeta12;
_c = tmpMeta13;
tmp14 = (listLength(_dims) > listLength(_s));
if (1 != tmp14) goto goto_2;
_s_1 = omc_Expression_subscriptsAppend(threadData, _s, _sub);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _idn, _t2, _s_1, _c);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_idn = tmpMeta15;
_t2 = tmpMeta16;
_s = tmpMeta17;
_c = tmpMeta18;
tmpMeta19 = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, _sub);
_s = omc_Expression_subscriptsReplaceSlice(threadData, _s, tmpMeta19);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _idn, _t2, _s, _c);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_idn = tmpMeta20;
_t2 = tmpMeta21;
_s = tmpMeta22;
_c = tmpMeta23;
_c_1 = omc_ExpressionSimplify_simplifyAsubCref(threadData, _c, _sub);
tmpMeta1 = omc_ComponentReference_makeCrefQual(threadData, _idn, _t2, _s, _c_1);
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
_res = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsub0(threadData_t *threadData, modelica_metatype _ie, modelica_integer _sub, modelica_metatype _inSubExp)
{
modelica_metatype _res = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ie;
{
modelica_metatype _t = NULL;
modelica_metatype _t1 = NULL;
modelica_boolean _b;
modelica_boolean _bstart;
modelica_boolean _bstop;
modelica_metatype _exps = NULL;
modelica_metatype _mexps = NULL;
modelica_metatype _mexpl = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _cond = NULL;
modelica_integer _istart;
modelica_integer _istop;
modelica_integer _istep;
modelica_integer _ival;
modelica_real _rstart;
modelica_real _rstop;
modelica_real _rstep;
modelica_real _rval;
modelica_metatype _c = NULL;
modelica_metatype _c_1 = NULL;
modelica_metatype _op = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 10; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_exps = tmpMeta6;
tmpMeta1 = listGet(_exps, _sub);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_integer tmp12;
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,3,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,3,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmp12 = mmc_unbox_integer(tmpMeta11);
_bstart = tmp9;
_bstop = tmp12;
_b = mmc_unbox_boolean(listGet(omc_ExpressionSimplify_simplifyRangeBool(threadData, _bstart, _bstop), _sub));
tmpMeta13 = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_b));
tmpMeta1 = tmpMeta13;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_integer tmp16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,0,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
tmp16 = mmc_unbox_integer(tmpMeta15);
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,0,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmp20 = mmc_unbox_integer(tmpMeta19);
_istart = tmp16;
_istop = tmp20;
_ival = mmc_unbox_integer(listGet(omc_ExpressionSimplify_simplifyRange(threadData, _istart, ((modelica_integer) 1), _istop), _sub));
tmpMeta21 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_ival));
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_integer tmp24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_integer tmp28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_integer tmp31;
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,0,1) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
tmp24 = mmc_unbox_integer(tmpMeta23);
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta25)) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,0,1) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 2));
tmp28 = mmc_unbox_integer(tmpMeta27);
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,0,1) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 2));
tmp31 = mmc_unbox_integer(tmpMeta30);
_istart = tmp24;
_istep = tmp28;
_istop = tmp31;
_ival = mmc_unbox_integer(listGet(omc_ExpressionSimplify_simplifyRange(threadData, _istart, _istep, _istop), _sub));
tmpMeta32 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_ival));
tmpMeta1 = tmpMeta32;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_real tmp35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_real tmp39;
modelica_metatype tmpMeta40;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta33,1,1) == 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 2));
tmp35 = mmc_unbox_real(tmpMeta34);
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta36)) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta37,1,1) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 2));
tmp39 = mmc_unbox_real(tmpMeta38);
_rstart = tmp35;
_rstop = tmp39;
_rval = mmc_unbox_real(listGet(omc_ExpressionSimplify_simplifyRangeReal(threadData, _rstart, 1.0, _rstop), _sub));
tmpMeta40 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_rval));
tmpMeta1 = tmpMeta40;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_real tmp43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_real tmp47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_real tmp50;
modelica_metatype tmpMeta51;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta41,1,1) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 2));
tmp43 = mmc_unbox_real(tmpMeta42);
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta44)) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta45,1,1) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 2));
tmp47 = mmc_unbox_real(tmpMeta46);
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta48,1,1) == 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta48), 2));
tmp50 = mmc_unbox_real(tmpMeta49);
_rstart = tmp43;
_rstep = tmp47;
_rstop = tmp50;
_rval = mmc_unbox_real(listGet(omc_ExpressionSimplify_simplifyRangeReal(threadData, _rstart, _rstep, _rstop), _sub));
tmpMeta51 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_rval));
tmpMeta1 = tmpMeta51;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_t = tmpMeta52;
_mexps = tmpMeta53;
_t1 = omc_Expression_unliftArray(threadData, _t);
_mexpl = listGet(_mexps, _sub);
tmpMeta54 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _t1, mmc_mk_boolean(1), _mexpl);
tmpMeta1 = tmpMeta54;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,3) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cond = tmpMeta55;
_e1 = tmpMeta56;
_e2 = tmpMeta57;
tmpMeta58 = mmc_mk_cons(_inSubExp, MMC_REFSTRUCTLIT(mmc_nil));
_e1 = omc_Expression_makeASUB(threadData, _e1, tmpMeta58);
tmpMeta59 = mmc_mk_cons(_inSubExp, MMC_REFSTRUCTLIT(mmc_nil));
_e2 = omc_Expression_makeASUB(threadData, _e2, tmpMeta59);
tmpMeta60 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _cond, _e1, _e2);
tmpMeta1 = tmpMeta60;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_boolean tmp63;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_c = tmpMeta61;
_t = tmpMeta62;
tmp63 = omc_Types_isArray(threadData, _t);
if (1 != tmp63) goto goto_2;
_t = omc_Expression_unliftArray(threadData, _t);
_c_1 = omc_ExpressionSimplify_simplifyAsubCref(threadData, _c, _inSubExp);
tmpMeta1 = omc_Expression_makeCrefExp(threadData, _c_1, _t);
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta64;
_op = tmpMeta65;
_e2 = tmpMeta66;
if (!(omc_Expression_isMulOrDiv(threadData, _op) || omc_Expression_isAddOrSub(threadData, _op))) goto tmp3_end;
tmpMeta67 = mmc_mk_cons(_inSubExp, MMC_REFSTRUCTLIT(mmc_nil));
_e1 = omc_Expression_makeASUB(threadData, _e1, tmpMeta67);
tmpMeta68 = mmc_mk_cons(_inSubExp, MMC_REFSTRUCTLIT(mmc_nil));
_e2 = omc_Expression_makeASUB(threadData, _e2, tmpMeta68);
tmpMeta1 = (omc_Expression_isMul(threadData, _op)?omc_Expression_expMul(threadData, _e1, _e2):(omc_Expression_isDiv(threadData, _op)?omc_Expression_makeDiv(threadData, _e1, _e2):(omc_Expression_isAdd(threadData, _op)?omc_Expression_expAdd(threadData, _e1, _e2):omc_Expression_expSub(threadData, _e1, _e2))));
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyAsub0(threadData_t *threadData, modelica_metatype _ie, modelica_metatype _sub, modelica_metatype _inSubExp)
{
modelica_integer tmp1;
modelica_metatype _res = NULL;
tmp1 = mmc_unbox_integer(_sub);
_res = omc_ExpressionSimplify_simplifyAsub0(threadData, _ie, tmp1, _inSubExp);
return _res;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifySumOperatorExpression(threadData_t *threadData, modelica_metatype _iSum, modelica_metatype _iop, modelica_metatype _iExp)
{
modelica_metatype _oExp = NULL;
modelica_metatype _T = NULL;
modelica_boolean _b;
modelica_metatype _e = NULL;
modelica_metatype _newE = NULL;
modelica_metatype _sE = NULL;
modelica_metatype _tp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_T = omc_Expression_termsExpandUnary(threadData, _iSum);
_tp = omc_Expression_typeofOp(threadData, _iop);
_oExp = omc_Expression_makeConstZero(threadData, _tp);
_sE = _oExp;
{
modelica_metatype _elem;
for (tmpMeta1 = _T; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_elem = MMC_CAR(tmpMeta1);
tmpMeta2 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _elem, _iop, _iExp);
_e = tmpMeta2;
_newE = omc_ExpressionSimplify_simplifyBinaryCoeff(threadData, _e);
_b = (!omc_Expression_expEqual(threadData, _e, _newE));
if(_b)
{
_sE = omc_Expression_expAdd(threadData, _sE, _newE);
}
else
{
_oExp = omc_Expression_expAdd(threadData, _oExp, _elem);
}
}
}
tmpMeta4 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _oExp, _iop, _iExp);
_e = tmpMeta4;
_oExp = omc_Expression_expAdd(threadData, _sE, _e);
_return: OMC_LABEL_UNUSED
return _oExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryMulCoeff2(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outRes = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_real _coeff;
modelica_real _coeff_1;
modelica_integer _icoeff;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
_e = tmp4_1;
tmpMeta6 = mmc_mk_box2(0, _e, _OMC_LIT26);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_real tmp11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,4,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmp11 = mmc_unbox_real(tmpMeta10);
_e1 = tmpMeta7;
_coeff = tmp11;
tmpMeta12 = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff));
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
modelica_real tmp19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,4,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,8,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,5,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,1,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
tmp19 = mmc_unbox_real(tmpMeta18);
_e1 = tmpMeta13;
_coeff = tmp19;
_coeff_1 = (-_coeff);
tmpMeta20 = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff_1));
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_integer tmp25;
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,4,1) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,0,1) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
tmp25 = mmc_unbox_integer(tmpMeta24);
_e1 = tmpMeta21;
_icoeff = tmp25;
_coeff_1 = ((modelica_real)_icoeff);
tmpMeta26 = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff_1));
tmpMeta1 = tmpMeta26;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_integer tmp33;
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,4,1) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,8,2) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta30,5,1) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta31,0,1) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta31), 2));
tmp33 = mmc_unbox_integer(tmpMeta32);
_e1 = tmpMeta27;
_icoeff = tmp33;
_coeff_1 = (-(((modelica_real)_icoeff)));
tmpMeta34 = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff_1));
tmpMeta1 = tmpMeta34;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta36,2,1) == 0) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta35;
_e2 = tmpMeta37;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta38 = mmc_mk_box2(0, _e1, _OMC_LIT28);
tmpMeta1 = tmpMeta38;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta39;
tmpMeta39 = mmc_mk_box2(0, _inExp, _OMC_LIT26);
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
_outRes = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRes;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryAddCoeff2(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outRes = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _exp = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_real _coeff;
modelica_real _coeff_1;
modelica_integer _icoeff;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 8; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = mmc_mk_box2(0, _inExp, _OMC_LIT26);
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
modelica_real tmp13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,5,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_exp = tmpMeta9;
tmpMeta10 = omc_ExpressionSimplify_simplifyBinaryAddCoeff2(threadData, _exp);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 2));
tmp13 = mmc_unbox_real(tmpMeta12);
_exp = tmpMeta11;
_coeff = tmp13;
_coeff = (-_coeff);
tmpMeta14 = mmc_mk_box2(0, _exp, mmc_mk_real(_coeff));
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_real tmp17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,1,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
tmp17 = mmc_unbox_real(tmpMeta16);
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,2,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_coeff = tmp17;
_e1 = tmpMeta19;
tmpMeta20 = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff));
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_real tmp25;
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,2,1) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta23,1,1) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta23), 2));
tmp25 = mmc_unbox_real(tmpMeta24);
_e1 = tmpMeta21;
_coeff = tmp25;
tmpMeta26 = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff));
tmpMeta1 = tmpMeta26;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_integer tmp31;
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,2,1) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,0,1) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 2));
tmp31 = mmc_unbox_integer(tmpMeta30);
_e1 = tmpMeta27;
_icoeff = tmp31;
_coeff_1 = ((modelica_real)_icoeff);
tmpMeta32 = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff_1));
tmpMeta1 = tmpMeta32;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_integer tmp35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta33,0,1) == 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 2));
tmp35 = mmc_unbox_integer(tmpMeta34);
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta36,2,1) == 0) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_icoeff = tmp35;
_e1 = tmpMeta37;
_coeff_1 = ((modelica_real)_icoeff);
tmpMeta38 = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff_1));
tmpMeta1 = tmpMeta38;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta40,0,1) == 0) goto tmp3_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta39;
_e2 = tmpMeta41;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta42 = mmc_mk_box2(0, _e1, _OMC_LIT28);
tmpMeta1 = tmpMeta42;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta43;
tmpMeta43 = mmc_mk_box2(0, _inExp, _OMC_LIT26);
tmpMeta1 = tmpMeta43;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outRes = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outRes;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAddMakeMul(threadData_t *threadData, modelica_metatype _inTplExpRealLst)
{
modelica_metatype _outExpLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _tplExpReal = NULL;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta25;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outExpLst = tmpMeta1;
{
modelica_metatype _tplExpReal;
for (tmpMeta2 = _inTplExpRealLst; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_tplExpReal = MMC_CAR(tmpMeta2);
{
volatile modelica_metatype tmp6_1;
tmp6_1 = _tplExpReal;
{
modelica_metatype _e = NULL;
modelica_real _r;
modelica_integer _tmpInt;
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp5_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp6 < 3; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_real tmp10;
modelica_metatype tmpMeta11;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
tmp10 = mmc_unbox_real(tmpMeta9);
_e = tmpMeta8;
_r = tmp10;
if (!(_r == 1.0)) goto tmp5_end;
tmpMeta11 = mmc_mk_cons(_e, _outExpLst);
tmpMeta3 = tmpMeta11;
goto tmp5_done;
}
case 1: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_real tmp14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 1));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
tmp14 = mmc_unbox_real(tmpMeta13);
_e = tmpMeta12;
_r = tmp14;
tmpMeta15 = omc_Expression_typeof(threadData, _e);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,0,1) == 0) goto goto_4;
_tmpInt = ((modelica_integer)floor(_r));
tmpMeta17 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_tmpInt));
tmpMeta18 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta17, _OMC_LIT55, _e);
tmpMeta16 = mmc_mk_cons(tmpMeta18, _outExpLst);
tmpMeta3 = tmpMeta16;
goto tmp5_done;
}
case 2: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_real tmp21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 1));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
tmp21 = mmc_unbox_real(tmpMeta20);
_e = tmpMeta19;
_r = tmp21;
tmpMeta23 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta24 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta23, _OMC_LIT34, _e);
tmpMeta22 = mmc_mk_cons(tmpMeta24, _outExpLst);
tmpMeta3 = tmpMeta22;
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
if (++tmp6 < 3) {
goto tmp5_top;
}
MMC_THROW_INTERNAL();
tmp5_done2:;
}
}
_outExpLst = tmpMeta3;
}
}
_return: OMC_LABEL_UNUSED
return _outExpLst;
}
PROTECTED_FUNCTION_STATIC modelica_real omc_ExpressionSimplify_simplifyAddJoinTermsFind(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTplExpRealLst, modelica_metatype *out_outTplExpRealLst)
{
modelica_real _outReal;
modelica_metatype _outTplExpRealLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _e = NULL;
modelica_real _coeff;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_real tmp6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outReal = 0.0;
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outTplExpRealLst = tmpMeta1;
{
modelica_metatype _t;
for (tmpMeta2 = _inTplExpRealLst; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_t = MMC_CAR(tmpMeta2);
tmpMeta3 = _t;
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 1));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmp6 = mmc_unbox_real(tmpMeta5);
_e = tmpMeta4;
_coeff = tmp6;
if(omc_Expression_expEqual(threadData, _inExp, _e))
{
_outReal = _outReal + _coeff;
}
else
{
tmpMeta7 = mmc_mk_cons(_t, _outTplExpRealLst);
_outTplExpRealLst = tmpMeta7;
}
}
}
_outTplExpRealLst = listReverseInPlace(_outTplExpRealLst);
_return: OMC_LABEL_UNUSED
if (out_outTplExpRealLst) { *out_outTplExpRealLst = _outTplExpRealLst; }
return _outReal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyAddJoinTermsFind(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTplExpRealLst, modelica_metatype *out_outTplExpRealLst)
{
modelica_real _outReal;
modelica_metatype out_outReal;
_outReal = omc_ExpressionSimplify_simplifyAddJoinTermsFind(threadData, _inExp, _inTplExpRealLst, out_outTplExpRealLst);
out_outReal = mmc_mk_rcon(_outReal);
return out_outReal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAddJoinTerms(threadData_t *threadData, modelica_metatype _inTplExpRealLst)
{
modelica_metatype _outTplExpRealLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _tplExpRealLst = NULL;
modelica_metatype _t = NULL;
modelica_metatype _e = NULL;
modelica_real _coeff;
modelica_real _coeff2;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_real tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outTplExpRealLst = tmpMeta1;
_tplExpRealLst = _inTplExpRealLst;
while(1)
{
if(!(!listEmpty(_tplExpRealLst))) break;
tmpMeta2 = _tplExpRealLst;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
_t = tmpMeta3;
_tplExpRealLst = tmpMeta4;
tmpMeta5 = _t;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 1));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta5), 2));
tmp8 = mmc_unbox_real(tmpMeta7);
_e = tmpMeta6;
_coeff = tmp8;
_coeff2 = omc_ExpressionSimplify_simplifyAddJoinTermsFind(threadData, _e, _tplExpRealLst ,&_tplExpRealLst);
_coeff = _coeff + _coeff2;
tmp11 = (modelica_boolean)(_coeff2 == 0.0);
if(tmp11)
{
tmpMeta12 = _t;
}
else
{
tmpMeta10 = mmc_mk_box2(0, _e, mmc_mk_real(_coeff));
tmpMeta12 = tmpMeta10;
}
tmpMeta9 = mmc_mk_cons(tmpMeta12, _outTplExpRealLst);
_outTplExpRealLst = tmpMeta9;
}
_return: OMC_LABEL_UNUSED
return _outTplExpRealLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAdd(threadData_t *threadData, modelica_metatype _inExpLst)
{
modelica_metatype _outExpLst = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _exp_const = NULL;
modelica_metatype _exp_const_1 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_exp_const = omc_List_map(threadData, _inExpLst, boxvar_ExpressionSimplify_simplifyBinaryAddCoeff2);
_exp_const_1 = omc_ExpressionSimplify_simplifyAddJoinTerms(threadData, _exp_const);
tmpMeta1 = omc_ExpressionSimplify_simplifyAddMakeMul(threadData, _exp_const_1);
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT59);
if (1 != tmp6) goto goto_2;
omc_Debug_trace(threadData, _OMC_LIT60);
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
_outExpLst = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExpLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMulMakePow(threadData_t *threadData, modelica_metatype _inTplExpRealLst)
{
modelica_metatype _outExpLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _tplExpReal = NULL;
modelica_metatype _e = NULL;
modelica_real _r;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_real tmp6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outExpLst = tmpMeta1;
{
modelica_metatype _tplExpReal;
for (tmpMeta2 = _inTplExpRealLst; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_tplExpReal = MMC_CAR(tmpMeta2);
tmpMeta3 = _tplExpReal;
tmpMeta4 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 1));
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmp6 = mmc_unbox_real(tmpMeta5);
_e = tmpMeta4;
_r = tmp6;
tmp11 = (modelica_boolean)(_r == 1.0);
if(tmp11)
{
tmpMeta7 = mmc_mk_cons(_e, _outExpLst);
tmpMeta12 = tmpMeta7;
}
else
{
tmpMeta9 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta10 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT36, tmpMeta9);
tmpMeta8 = mmc_mk_cons(tmpMeta10, _outExpLst);
tmpMeta12 = tmpMeta8;
}
_outExpLst = tmpMeta12;
}
}
_return: OMC_LABEL_UNUSED
return _outExpLst;
}
PROTECTED_FUNCTION_STATIC modelica_real omc_ExpressionSimplify_simplifyMulJoinFactorsFind(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTplExpRealLst, modelica_metatype *out_outTplExpRealLst)
{
modelica_real _outReal;
modelica_metatype _outTplExpRealLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _tplExpReal = NULL;
modelica_metatype tmpMeta2;
modelica_real tmp3_c0 __attribute__((unused)) = 0;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outReal = 0.0;
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outTplExpRealLst = tmpMeta1;
{
modelica_metatype _tplExpReal;
for (tmpMeta2 = _inTplExpRealLst; !listEmpty(tmpMeta2); tmpMeta2=MMC_CDR(tmpMeta2))
{
_tplExpReal = MMC_CAR(tmpMeta2);
{
modelica_metatype tmp6_1;
tmp6_1 = _tplExpReal;
{
modelica_real _coeff;
modelica_metatype _e2 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _op = NULL;
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 3; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_real tmp10;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 1));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
tmp10 = mmc_unbox_real(tmpMeta9);
_e2 = tmpMeta8;
_coeff = tmp10;
if (!omc_Expression_expEqual(threadData, _inExp, _e2)) goto tmp5_end;
tmp3_c0 = _coeff + _outReal;
tmpMeta[0+1] = _outTplExpRealLst;
goto tmp5_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_real tmp16;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
modelica_boolean tmp19;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,7,3) == 0) goto tmp5_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,3,1) == 0) goto tmp5_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 4));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 2));
tmp16 = mmc_unbox_real(tmpMeta15);
_e1 = tmpMeta12;
_op = tmpMeta13;
_e2 = tmpMeta14;
_coeff = tmp16;
tmp18 = (modelica_boolean)omc_Expression_isOne(threadData, _e1);
if(tmp18)
{
tmp19 = omc_Expression_expEqual(threadData, _inExp, _e2);
}
else
{
tmpMeta17 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op, _e1);
tmp19 = omc_Expression_expEqual(threadData, _inExp, tmpMeta17);
}
if (!tmp19) goto tmp5_end;
tmp3_c0 = _outReal - _coeff;
tmpMeta[0+1] = _outTplExpRealLst;
goto tmp5_done;
}
case 2: {
modelica_metatype tmpMeta20;
tmpMeta20 = mmc_mk_cons(_tplExpReal, _outTplExpRealLst);
tmp3_c0 = _outReal;
tmpMeta[0+1] = tmpMeta20;
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
_outReal = tmp3_c0;
_outTplExpRealLst = tmpMeta[0+1];
}
}
_outTplExpRealLst = listReverse(_outTplExpRealLst);
_return: OMC_LABEL_UNUSED
if (out_outTplExpRealLst) { *out_outTplExpRealLst = _outTplExpRealLst; }
return _outReal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyMulJoinFactorsFind(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTplExpRealLst, modelica_metatype *out_outTplExpRealLst)
{
modelica_real _outReal;
modelica_metatype out_outReal;
_outReal = omc_ExpressionSimplify_simplifyMulJoinFactorsFind(threadData, _inExp, _inTplExpRealLst, out_outTplExpRealLst);
out_outReal = mmc_mk_rcon(_outReal);
return out_outReal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMulJoinFactors(threadData_t *threadData, modelica_metatype _inTplExpRealLst)
{
modelica_metatype _outTplExpRealLst = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _tplExpRealLst = NULL;
modelica_metatype _e = NULL;
modelica_real _coeff;
modelica_real _coeff2;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_real tmp7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outTplExpRealLst = tmpMeta1;
_tplExpRealLst = _inTplExpRealLst;
while(1)
{
if(!(!listEmpty(_tplExpRealLst))) break;
tmpMeta2 = _tplExpRealLst;
if (listEmpty(tmpMeta2)) MMC_THROW_INTERNAL();
tmpMeta3 = MMC_CAR(tmpMeta2);
tmpMeta4 = MMC_CDR(tmpMeta2);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 1));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta3), 2));
tmp7 = mmc_unbox_real(tmpMeta6);
_e = tmpMeta5;
_coeff = tmp7;
_tplExpRealLst = tmpMeta4;
_coeff2 = omc_ExpressionSimplify_simplifyMulJoinFactorsFind(threadData, _e, _tplExpRealLst ,&_tplExpRealLst);
_coeff = _coeff + _coeff2;
tmpMeta9 = mmc_mk_box2(0, _e, mmc_mk_real(_coeff));
tmpMeta8 = mmc_mk_cons(tmpMeta9, _outTplExpRealLst);
_outTplExpRealLst = tmpMeta8;
}
_return: OMC_LABEL_UNUSED
return _outTplExpRealLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMul(threadData_t *threadData, modelica_metatype _expl)
{
modelica_metatype _expl_1 = NULL;
modelica_metatype _exp_const = NULL;
modelica_metatype _exp_const_1 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp_const = omc_List_map(threadData, _expl, boxvar_ExpressionSimplify_simplifyBinaryMulCoeff2);
_exp_const_1 = omc_ExpressionSimplify_simplifyMulJoinFactors(threadData, _exp_const);
_expl_1 = omc_ExpressionSimplify_simplifyMulMakePow(threadData, _exp_const_1);
_return: OMC_LABEL_UNUSED
return _expl_1;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryMulConstants(threadData_t *threadData, modelica_metatype _inExpLst)
{
modelica_metatype _outExp = NULL;
modelica_metatype _es = NULL;
modelica_metatype _tp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inExpLst;
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
_outExp = tmpMeta2;
_es = tmpMeta3;
_tp = omc_Expression_typeof(threadData, _outExp);
{
modelica_metatype _e;
for (tmpMeta4 = _es; !listEmpty(tmpMeta4); tmpMeta4=MMC_CDR(tmpMeta4))
{
_e = MMC_CAR(tmpMeta4);
tmpMeta5 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
_outExp = omc_ExpressionSimplify_simplifyBinaryConst(threadData, tmpMeta5, _outExp, _e);
}
}
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryAddConstants(threadData_t *threadData, modelica_metatype _inExpLst)
{
modelica_metatype _outExp = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _es = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inExpLst;
if (listEmpty(tmpMeta1)) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_CAR(tmpMeta1);
tmpMeta3 = MMC_CDR(tmpMeta1);
_outExp = tmpMeta2;
_es = tmpMeta3;
_tp = omc_Expression_typeof(threadData, _outExp);
{
modelica_metatype _e;
for (tmpMeta4 = _es; !listEmpty(tmpMeta4); tmpMeta4=MMC_CDR(tmpMeta4))
{
_e = MMC_CAR(tmpMeta4);
tmpMeta5 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _tp);
_outExp = omc_ExpressionSimplify_simplifyBinaryConst(threadData, tmpMeta5, _outExp, _e);
}
}
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryCoeff(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _e_lst = NULL;
modelica_metatype _e_lst_1 = NULL;
modelica_metatype _e1_lst = NULL;
modelica_metatype _e2_lst = NULL;
modelica_metatype _e2_lst_1 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _tp = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_e = tmp4_1;
_tp = tmpMeta7;
tmp4 += 3;
if (!omc_Types_isScalarReal(threadData, _tp)) goto tmp3_end;
_e_lst = omc_Expression_factors(threadData, _e);
_e_lst_1 = omc_ExpressionSimplify_simplifyMul(threadData, _e_lst);
tmpMeta1 = omc_Expression_makeProductLst(threadData, _e_lst_1);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,3,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta8;
_e2 = tmpMeta10;
tmp4 += 2;
tmp11 = omc_Expression_isZero(threadData, _e2);
if (0 != tmp11) goto goto_2;
_e1_lst = omc_Expression_factors(threadData, _e1);
_e2_lst = omc_Expression_factors(threadData, _e2);
_e2_lst_1 = omc_List_map(threadData, _e2_lst, boxvar_Expression_inverseFactors);
_e_lst = listAppend(_e1_lst, _e2_lst_1);
_e_lst_1 = omc_ExpressionSimplify_simplifyMul(threadData, _e_lst);
tmpMeta1 = omc_Expression_makeProductLst(threadData, _e_lst_1);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,0,1) == 0) goto tmp3_end;
_e = tmp4_1;
tmp4 += 1;
_e_lst = omc_Expression_terms(threadData, _e);
_e_lst_1 = omc_ExpressionSimplify_simplifyAdd(threadData, _e_lst);
tmpMeta1 = omc_Expression_makeSum(threadData, _e_lst_1);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,1,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta13;
_e2 = tmpMeta15;
_e1_lst = omc_Expression_terms(threadData, _e1);
_e2_lst = omc_Expression_terms(threadData, _e2);
_e2_lst = omc_List_map(threadData, _e2_lst, boxvar_Expression_negate);
_e_lst = listAppend(_e1_lst, _e2_lst);
_e_lst_1 = omc_ExpressionSimplify_simplifyAdd(threadData, _e_lst);
tmpMeta1 = omc_Expression_makeSum(threadData, _e_lst_1);
goto tmp3_done;
}
case 4: {
tmpMeta1 = _inExp;
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinarySortConstants(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _e_lst = NULL;
modelica_metatype _const_es1 = NULL;
modelica_metatype _notconst_es1 = NULL;
modelica_metatype _res = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _res1 = NULL;
modelica_metatype _res2 = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,2,1) == 0) goto tmp3_end;
_e = tmp4_1;
tmp4 += 2;
tmpMeta1 = omc_ExpressionSimplify_simplifyBinarySortConstantsMul(threadData, _e);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,3,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta7;
_tp = tmpMeta9;
_e2 = tmpMeta10;
tmp4 += 1;
_e1 = omc_ExpressionSimplify_simplifyBinarySortConstantsMul(threadData, _e1);
_e2 = omc_ExpressionSimplify_simplifyBinarySortConstantsMul(threadData, _e2);
tmpMeta11 = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _tp);
tmpMeta12 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta11, _e2);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,0,1) == 0) goto tmp3_end;
_e = tmp4_1;
_e_lst = omc_Expression_terms(threadData, _e);
_const_es1 = omc_List_splitOnTrue(threadData, _e_lst, boxvar_Expression_isConstValue ,&_notconst_es1);
if((!listEmpty(_const_es1)))
{
_res1 = omc_ExpressionSimplify_simplifyBinaryAddConstants(threadData, _const_es1);
_res2 = omc_Expression_makeSum1(threadData, _notconst_es1, 0);
_res = omc_Expression_expAdd(threadData, _res1, _res2);
}
else
{
_res = _inExp;
}
tmpMeta1 = _res;
goto tmp3_done;
}
case 3: {
tmpMeta1 = _inExp;
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixProduct4(threadData_t *threadData, modelica_metatype _inMatrix1, modelica_metatype _inMatrix2)
{
modelica_metatype _outDimensions = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inMatrix1;
tmp4_2 = _inMatrix2;
{
modelica_metatype _n = NULL;
modelica_metatype _m = NULL;
modelica_metatype _p = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
if (!listEmpty(tmpMeta9)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,6,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 3));
if (listEmpty(tmpMeta11)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmpMeta11);
tmpMeta13 = MMC_CDR(tmpMeta11);
if (listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (!listEmpty(tmpMeta15)) goto tmp3_end;
_n = tmpMeta12;
tmpMeta16 = mmc_mk_cons(_n, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta16;
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
modelica_metatype tmpMeta27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,6,2) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 3));
if (listEmpty(tmpMeta18)) goto tmp3_end;
tmpMeta19 = MMC_CAR(tmpMeta18);
tmpMeta20 = MMC_CDR(tmpMeta18);
if (!listEmpty(tmpMeta20)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,3) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,6,2) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 3));
if (listEmpty(tmpMeta22)) goto tmp3_end;
tmpMeta23 = MMC_CAR(tmpMeta22);
tmpMeta24 = MMC_CDR(tmpMeta22);
if (listEmpty(tmpMeta24)) goto tmp3_end;
tmpMeta25 = MMC_CAR(tmpMeta24);
tmpMeta26 = MMC_CDR(tmpMeta24);
if (!listEmpty(tmpMeta26)) goto tmp3_end;
_m = tmpMeta23;
tmpMeta27 = mmc_mk_cons(_m, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta27;
goto tmp3_done;
}
case 2: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,6,2) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 3));
if (listEmpty(tmpMeta29)) goto tmp3_end;
tmpMeta30 = MMC_CAR(tmpMeta29);
tmpMeta31 = MMC_CDR(tmpMeta29);
if (listEmpty(tmpMeta31)) goto tmp3_end;
tmpMeta32 = MMC_CAR(tmpMeta31);
tmpMeta33 = MMC_CDR(tmpMeta31);
if (!listEmpty(tmpMeta33)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,3) == 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,6,2) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 3));
if (listEmpty(tmpMeta35)) goto tmp3_end;
tmpMeta36 = MMC_CAR(tmpMeta35);
tmpMeta37 = MMC_CDR(tmpMeta35);
if (listEmpty(tmpMeta37)) goto tmp3_end;
tmpMeta38 = MMC_CAR(tmpMeta37);
tmpMeta39 = MMC_CDR(tmpMeta37);
if (!listEmpty(tmpMeta39)) goto tmp3_end;
_n = tmpMeta30;
_p = tmpMeta36;
tmpMeta40 = mmc_mk_cons(_n, mmc_mk_cons(_p, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta1 = tmpMeta40;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outDimensions = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outDimensions;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixProduct3(threadData_t *threadData, modelica_metatype _inRow, modelica_metatype _inMatrix)
{
modelica_metatype _outRow = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outRow = omc_List_map1r(threadData, _inMatrix, boxvar_ExpressionSimplify_simplifyScalarProduct, _inRow);
_return: OMC_LABEL_UNUSED
return _outRow;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixProduct2(threadData_t *threadData, modelica_metatype _inMatrix1, modelica_metatype _inMatrix2)
{
modelica_metatype _outProduct = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inMatrix1;
tmp4_2 = _inMatrix2;
{
modelica_metatype _n = NULL;
modelica_metatype _m = NULL;
modelica_metatype _p = NULL;
modelica_metatype _expl1 = NULL;
modelica_metatype _expl2 = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _row_ty = NULL;
modelica_metatype _matrix = NULL;
modelica_metatype _zero = NULL;
modelica_metatype _dims = NULL;
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
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
_ty = tmpMeta6;
_dims = tmpMeta7;
tmp8 = omc_Expression_arrayContainZeroDimension(threadData, _dims);
if (1 != tmp8) goto goto_2;
_zero = omc_Expression_makeConstZero(threadData, _ty);
_dims = omc_ExpressionSimplify_simplifyMatrixProduct4(threadData, _inMatrix1, _inMatrix2);
tmpMeta1 = omc_Expression_arrayFill(threadData, _dims, _zero);
goto tmp3_done;
}
case 1: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,6,2) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 3));
if (listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmpMeta10);
tmpMeta12 = MMC_CDR(tmpMeta10);
if (!listEmpty(tmpMeta12)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta13,6,2) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta13), 3));
if (listEmpty(tmpMeta15)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmpMeta15);
tmpMeta17 = MMC_CDR(tmpMeta15);
if (listEmpty(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmpMeta17);
tmpMeta19 = MMC_CDR(tmpMeta17);
if (!listEmpty(tmpMeta19)) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_ty = tmpMeta14;
_n = tmpMeta16;
_expl1 = tmpMeta20;
tmp4 += 2;
_expl1 = omc_List_map1(threadData, _expl1, boxvar_ExpressionSimplify_simplifyScalarProduct, _inMatrix2);
tmpMeta21 = mmc_mk_cons(_n, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta22 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta21);
_ty = tmpMeta22;
tmpMeta23 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _ty, mmc_mk_boolean(1), _expl1);
tmpMeta1 = tmpMeta23;
goto tmp3_done;
}
case 2: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,6,2) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 3));
if (listEmpty(tmpMeta25)) goto tmp3_end;
tmpMeta26 = MMC_CAR(tmpMeta25);
tmpMeta27 = MMC_CDR(tmpMeta25);
if (!listEmpty(tmpMeta27)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,3) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,6,2) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 2));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta28), 3));
if (listEmpty(tmpMeta30)) goto tmp3_end;
tmpMeta31 = MMC_CAR(tmpMeta30);
tmpMeta32 = MMC_CDR(tmpMeta30);
if (listEmpty(tmpMeta32)) goto tmp3_end;
tmpMeta33 = MMC_CAR(tmpMeta32);
tmpMeta34 = MMC_CDR(tmpMeta32);
if (!listEmpty(tmpMeta34)) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_ty = tmpMeta29;
_m = tmpMeta31;
_expl2 = tmpMeta35;
tmp4 += 1;
_expl1 = omc_List_map1r(threadData, _expl2, boxvar_ExpressionSimplify_simplifyScalarProduct, _inMatrix1);
tmpMeta36 = mmc_mk_cons(_m, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta37 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta36);
_ty = tmpMeta37;
tmpMeta38 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _ty, mmc_mk_boolean(1), _expl1);
tmpMeta1 = tmpMeta38;
goto tmp3_done;
}
case 3: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,6,2) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 2));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 3));
if (listEmpty(tmpMeta41)) goto tmp3_end;
tmpMeta42 = MMC_CAR(tmpMeta41);
tmpMeta43 = MMC_CDR(tmpMeta41);
if (listEmpty(tmpMeta43)) goto tmp3_end;
tmpMeta44 = MMC_CAR(tmpMeta43);
tmpMeta45 = MMC_CDR(tmpMeta43);
if (!listEmpty(tmpMeta45)) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,3) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta47,6,2) == 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta47), 3));
if (listEmpty(tmpMeta48)) goto tmp3_end;
tmpMeta49 = MMC_CAR(tmpMeta48);
tmpMeta50 = MMC_CDR(tmpMeta48);
if (listEmpty(tmpMeta50)) goto tmp3_end;
tmpMeta51 = MMC_CAR(tmpMeta50);
tmpMeta52 = MMC_CDR(tmpMeta50);
if (!listEmpty(tmpMeta52)) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_ty = tmpMeta40;
_n = tmpMeta42;
_expl1 = tmpMeta46;
_p = tmpMeta49;
_expl2 = tmpMeta53;
_matrix = omc_List_map1(threadData, _expl1, boxvar_ExpressionSimplify_simplifyMatrixProduct3, _expl2);
tmpMeta54 = mmc_mk_cons(_p, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta55 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta54);
_row_ty = tmpMeta55;
_expl1 = omc_List_map2(threadData, _matrix, boxvar_Expression_makeArray, _row_ty, mmc_mk_boolean(1));
tmpMeta56 = mmc_mk_cons(_n, mmc_mk_cons(_p, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta57 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta56);
tmpMeta58 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta57, mmc_mk_boolean(0), _expl1);
tmpMeta1 = tmpMeta58;
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
_outProduct = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outProduct;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixProduct(threadData_t *threadData, modelica_metatype _inMatrix1, modelica_metatype _inMatrix2)
{
modelica_metatype _outProduct = NULL;
modelica_metatype _mat1 = NULL;
modelica_metatype _mat2 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_mat1 = omc_Expression_matrixToArray(threadData, _inMatrix1);
_mat2 = omc_Expression_matrixToArray(threadData, _inMatrix2);
_mat2 = omc_Expression_transposeArray(threadData, _mat2, NULL);
_outProduct = omc_ExpressionSimplify_simplifyMatrixProduct2(threadData, _mat1, _mat2);
_return: OMC_LABEL_UNUSED
return _outProduct;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixPow1(threadData_t *threadData, modelica_metatype _inRange, modelica_metatype _inMatrix, modelica_metatype _inValue)
{
modelica_metatype _outMatrix = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inRange;
tmp4_2 = _inMatrix;
tmp4_3 = _inValue;
{
modelica_metatype _rm = NULL;
modelica_metatype _rm1 = NULL;
modelica_metatype _row = NULL;
modelica_metatype _row1 = NULL;
modelica_metatype _e = NULL;
modelica_integer _i;
modelica_metatype _rr = NULL;
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
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp4 += 2;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmp4_1);
tmpMeta8 = MMC_CDR(tmp4_1);
tmp9 = mmc_unbox_integer(tmpMeta7);
if (!listEmpty(tmpMeta8)) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmp4_2);
tmpMeta11 = MMC_CDR(tmp4_2);
if (!listEmpty(tmpMeta11)) goto tmp3_end;
_i = tmp9;
_row = tmpMeta10;
_e = tmp4_3;
_row1 = omc_List_replaceAt(threadData, _e, ((modelica_integer) 1) + _i, _row);
tmpMeta12 = mmc_mk_cons(_row1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmp4_1);
tmpMeta14 = MMC_CDR(tmp4_1);
tmp15 = mmc_unbox_integer(tmpMeta13);
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmp4_2);
tmpMeta17 = MMC_CDR(tmp4_2);
_i = tmp15;
_rr = tmpMeta14;
_row = tmpMeta16;
_rm = tmpMeta17;
_e = tmp4_3;
_row1 = omc_List_replaceAt(threadData, _e, ((modelica_integer) 1) + _i, _row);
_rm1 = omc_ExpressionSimplify_simplifyMatrixPow1(threadData, _rr, _rm, _e);
tmpMeta18 = mmc_mk_cons(_row1, _rm1);
tmpMeta1 = tmpMeta18;
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
_outMatrix = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outMatrix;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixPow(threadData_t *threadData, modelica_metatype _inExp1, modelica_metatype _inType, modelica_metatype _inExp2)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExp1;
tmp4_2 = _inExp2;
{
modelica_metatype _expl_1 = NULL;
modelica_metatype _expl2 = NULL;
modelica_metatype _el = NULL;
modelica_metatype _tp1 = NULL;
modelica_integer _size1;
modelica_integer _i;
modelica_integer _i_1;
modelica_metatype _range = NULL;
modelica_metatype _e = NULL;
modelica_metatype _m = NULL;
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
modelica_integer tmp8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_integer tmp11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp8 = mmc_unbox_integer(tmpMeta7);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
_tp1 = tmpMeta6;
_size1 = tmp8;
_i = tmp10;
tmp11 = _i;
if (0 != tmp11) goto goto_2;
_el = omc_List_fill(threadData, _OMC_LIT20, _size1);
_expl2 = omc_List_fill(threadData, _el, _size1);
_range = omc_List_intRange2(threadData, ((modelica_integer) 0), ((modelica_integer) -1) + _size1);
_expl_1 = omc_ExpressionSimplify_simplifyMatrixPow1(threadData, _range, _expl2, _OMC_LIT27);
tmpMeta12 = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _tp1, mmc_mk_integer(_size1), _expl_1);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_integer tmp14;
modelica_integer tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp14 = mmc_unbox_integer(tmpMeta13);
_m = tmp4_1;
_i = tmp14;
tmp15 = _i;
if (1 != tmp15) goto goto_2;
tmpMeta1 = _m;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_integer tmp17;
modelica_integer tmp18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
_m = tmp4_1;
_i = tmp17;
tmp18 = _i;
if (2 != tmp18) goto goto_2;
tmpMeta1 = omc_ExpressionSimplify_simplifyMatrixProduct(threadData, _m, _m);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_integer tmp21;
modelica_boolean tmp22;
modelica_integer tmp23;
modelica_integer tmp24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp21 = mmc_unbox_integer(tmpMeta20);
_m = tmp4_1;
_tp1 = tmpMeta19;
_i = tmp21;
tmp22 = (_i > ((modelica_integer) 3));
if (1 != tmp22) goto goto_2;
tmp23 = modelica_integer_mod(_i, ((modelica_integer) 2));
if (0 != tmp23) goto goto_2;
tmp24 = ((modelica_integer) 2);
if (tmp24 == 0) {goto goto_2;}
_i_1 = ldiv(_i,tmp24).quot;
tmpMeta25 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i_1));
_e = omc_ExpressionSimplify_simplifyMatrixPow(threadData, _m, _tp1, tmpMeta25);
tmpMeta1 = omc_ExpressionSimplify_simplifyMatrixProduct(threadData, _e, _e);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_integer tmp28;
modelica_boolean tmp29;
modelica_metatype tmpMeta30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp28 = mmc_unbox_integer(tmpMeta27);
_m = tmp4_1;
_tp1 = tmpMeta26;
_i = tmp28;
tmp29 = (((modelica_integer) 1) < _i);
if (1 != tmp29) goto goto_2;
_i_1 = ((modelica_integer) -1) + _i;
tmpMeta30 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i_1));
_e = omc_ExpressionSimplify_simplifyMatrixPow(threadData, _m, _tp1, tmpMeta30);
tmpMeta1 = omc_ExpressionSimplify_simplifyMatrixProduct(threadData, _m, _e);
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixBinary2(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inRhs, modelica_metatype _inOperator)
{
modelica_metatype _outExp = NULL;
modelica_metatype _op = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_op = omc_ExpressionSimplify_removeOperatorDimension(threadData, _inOperator);
tmpMeta1 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _inLhs, _op, _inRhs);
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixBinary1(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inRhs, modelica_metatype _inOperator)
{
modelica_metatype _outExpl = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExpl = omc_List_threadMap1(threadData, _inLhs, _inRhs, boxvar_ExpressionSimplify_simplifyMatrixBinary2, _inOperator);
_return: OMC_LABEL_UNUSED
return _outExpl;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixBinary(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inOperator, modelica_metatype _inRhs)
{
modelica_metatype _outResult = NULL;
modelica_metatype _lhs = NULL;
modelica_metatype _rhs = NULL;
modelica_metatype _res = NULL;
modelica_metatype _op = NULL;
modelica_integer _sz;
modelica_metatype _ty = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_lhs = omc_Expression_get2dArrayOrMatrixContent(threadData, _inLhs);
_rhs = omc_Expression_get2dArrayOrMatrixContent(threadData, _inRhs);
_op = omc_ExpressionSimplify_removeOperatorDimension(threadData, _inOperator);
_res = omc_List_threadMap1(threadData, _lhs, _rhs, boxvar_ExpressionSimplify_simplifyMatrixBinary1, _op);
_sz = listLength(_res);
_ty = omc_Expression_typeof(threadData, _inLhs);
tmpMeta1 = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _ty, mmc_mk_integer(_sz), _res);
_outResult = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorBinary2(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inRhs, modelica_metatype _inOperator)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _inLhs, _inOperator, _inRhs);
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorBinary(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inOperator, modelica_metatype _inRhs)
{
modelica_metatype _outResult = NULL;
modelica_metatype _ty = NULL;
modelica_boolean _sc;
modelica_metatype _lhs = NULL;
modelica_metatype _rhs = NULL;
modelica_metatype _res = NULL;
modelica_metatype _op = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_integer tmp4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = _inLhs;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta1,16,3) == 0) MMC_THROW_INTERNAL();
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 2));
tmpMeta3 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 3));
tmp4 = mmc_unbox_integer(tmpMeta3);
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_ty = tmpMeta2;
_sc = tmp4;
_lhs = tmpMeta5;
tmpMeta6 = _inRhs;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,16,3) == 0) MMC_THROW_INTERNAL();
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
_rhs = tmpMeta7;
_op = omc_ExpressionSimplify_removeOperatorDimension(threadData, _inOperator);
_res = omc_List_threadMap1(threadData, _lhs, _rhs, boxvar_ExpressionSimplify_simplifyVectorBinary2, _op);
tmpMeta8 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _ty, mmc_mk_boolean(_sc), _res);
_outResult = tmpMeta8;
_return: OMC_LABEL_UNUSED
return _outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorBinary0(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _op, modelica_metatype _e2)
{
modelica_metatype _res = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _op;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta1 = omc_ExpressionSimplify_simplifyVectorBinary(threadData, _e1, _op, _e2);
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmp4 += 3;
tmp6 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp6) goto goto_2;
tmpMeta1 = _e2;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,1) == 0) goto tmp3_end;
tmp4 += 2;
tmp7 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp7) goto goto_2;
tmpMeta1 = _e2;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,1) == 0) goto tmp3_end;
tmp4 += 1;
tmp8 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp8) goto goto_2;
tmpMeta1 = omc_Expression_negate(threadData, _e2);
goto tmp3_done;
}
case 4: {
modelica_boolean tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmp9 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp9) goto goto_2;
tmpMeta1 = omc_Expression_negate(threadData, _e2);
goto tmp3_done;
}
case 5: {
modelica_boolean tmp10;
tmp10 = omc_Expression_isZero(threadData, _e2);
if (1 != tmp10) goto goto_2;
tmpMeta1 = _e1;
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
_res = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorScalar(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inOperator, modelica_metatype _inRhs)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inLhs;
tmp4_2 = _inOperator;
tmp4_3 = _inRhs;
{
modelica_metatype _s1 = NULL;
modelica_metatype _op = NULL;
modelica_metatype _tp = NULL;
modelica_boolean _sc;
modelica_metatype _es = NULL;
modelica_metatype _mexpl = NULL;
modelica_integer _dims;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,16,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmp8 = mmc_unbox_integer(tmpMeta7);
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_tp = tmpMeta6;
_sc = tmp8;
_es = tmpMeta9;
_es = omc_List_map2r(threadData, _es, boxvar_Expression_makeBinaryExp, _inLhs, _inOperator);
tmpMeta10 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(_sc), _es);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_integer tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,17,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
tmp13 = mmc_unbox_integer(tmpMeta12);
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 4));
_tp = tmpMeta11;
_dims = tmp13;
_mexpl = tmpMeta14;
_s1 = tmp4_1;
_op = tmp4_2;
_mexpl = omc_ExpressionSimplify_simplifyVectorScalarMatrix(threadData, _mexpl, _op, _s1, 0);
tmpMeta15 = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _tp, mmc_mk_integer(_dims), _mexpl);
tmpMeta1 = tmpMeta15;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_integer tmp18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp18 = mmc_unbox_integer(tmpMeta17);
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_tp = tmpMeta16;
_sc = tmp18;
_es = tmpMeta19;
_es = omc_List_map2(threadData, _es, boxvar_Expression_makeBinaryExp, _inOperator, _inRhs);
tmpMeta20 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(_sc), _es);
tmpMeta1 = tmpMeta20;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_integer tmp23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp23 = mmc_unbox_integer(tmpMeta22);
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_tp = tmpMeta21;
_dims = tmp23;
_mexpl = tmpMeta24;
_op = tmp4_2;
_s1 = tmp4_3;
_mexpl = omc_ExpressionSimplify_simplifyVectorScalarMatrix(threadData, _mexpl, _op, _s1, 1);
tmpMeta25 = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _tp, mmc_mk_integer(_dims), _mexpl);
tmpMeta1 = tmpMeta25;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_unliftOperator(threadData_t *threadData, modelica_metatype _inArray, modelica_metatype _inOperator)
{
modelica_metatype _outOperator = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inArray;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta1 = omc_Expression_unliftOperatorX(threadData, _inOperator, ((modelica_integer) 2));
goto tmp3_done;
}
case 1: {
tmpMeta1 = omc_Expression_unliftOperator(threadData, _inOperator);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outOperator = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outOperator;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyScalarProduct(threadData_t *threadData, modelica_metatype _inVector1, modelica_metatype _inVector2)
{
modelica_metatype _outProduct = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inVector1;
tmp4_2 = _inVector2;
{
modelica_metatype _expl = NULL;
modelica_metatype _expl1 = NULL;
modelica_metatype _expl2 = NULL;
modelica_metatype _tp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
if (!listEmpty(tmpMeta8)) goto tmp3_end;
_tp = tmpMeta6;
tmpMeta1 = omc_Expression_makeConstZero(threadData, _tp);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
_expl1 = tmpMeta9;
_expl2 = tmpMeta10;
tmp11 = (omc_Expression_isVector(threadData, _inVector1) && omc_Expression_isVector(threadData, _inVector2));
if (1 != tmp11) goto goto_2;
_expl = omc_List_threadMap(threadData, _expl1, _expl2, boxvar_Expression_expMul);
tmpMeta1 = omc_List_reduce(threadData, _expl, boxvar_Expression_expAdd);
goto tmp3_done;
}
case 2: {
modelica_boolean tmp12;
tmp12 = (omc_Expression_isZero(threadData, _inVector1) || omc_Expression_isZero(threadData, _inVector2));
if (1 != tmp12) goto goto_2;
tmpMeta1 = omc_Expression_makeConstZero(threadData, _OMC_LIT30);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outProduct = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outProduct;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryArray(threadData_t *threadData, modelica_metatype _inExp1, modelica_metatype _inOperator2, modelica_metatype _inExp3)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;
tmp4_1 = _inExp1;
tmp4_2 = _inOperator2;
tmp4_3 = _inExp3;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _s1 = NULL;
modelica_metatype _a1 = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _op = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 20; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,15,1) == 0) goto tmp3_end;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 8;
tmpMeta1 = omc_ExpressionSimplify_simplifyMatrixProduct(threadData, _e1, _e2);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,1) == 0) goto tmp3_end;
_op = tmp4_2;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 6;
tmpMeta1 = omc_ExpressionSimplify_simplifyVectorBinary0(threadData, _e1, _op, _e2);
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,8,1) == 0) goto tmp3_end;
_op = tmp4_2;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 4;
tmpMeta1 = omc_ExpressionSimplify_simplifyVectorBinary0(threadData, _e1, _op, _e2);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,1) == 0) goto tmp3_end;
_op = tmp4_2;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 5;
tmpMeta1 = omc_ExpressionSimplify_simplifyVectorBinary(threadData, _e1, _op, _e2);
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,10,1) == 0) goto tmp3_end;
_op = tmp4_2;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 4;
tmpMeta1 = omc_ExpressionSimplify_simplifyVectorBinary(threadData, _e1, _op, _e2);
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,20,1) == 0) goto tmp3_end;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 3;
_tp = omc_Expression_typeof(threadData, _e1);
tmpMeta1 = omc_ExpressionSimplify_simplifyMatrixPow(threadData, _e1, _tp, _e2);
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,21,1) == 0) goto tmp3_end;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 2;
_tp = omc_Expression_typeof(threadData, _e1);
tmpMeta6 = mmc_mk_box2(24, &DAE_Operator_POW__ARR2__desc, _tp);
tmpMeta1 = omc_ExpressionSimplify_simplifyVectorBinary(threadData, _e1, tmpMeta6, _e2);
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,8,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,8,2) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_tp = tmpMeta7;
_e2 = tmpMeta8;
_e1 = tmp4_1;
tmp4 += 1;
tmpMeta9 = mmc_mk_box2(10, &DAE_Operator_ADD__ARR__desc, _tp);
tmpMeta10 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta9, _e2);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,8,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 3));
_tp = tmpMeta11;
_e2 = tmpMeta12;
_e1 = tmp4_1;
tmpMeta13 = mmc_mk_box2(11, &DAE_Operator_SUB__ARR__desc, _tp);
tmpMeta14 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta13, _e2);
tmpMeta1 = tmpMeta14;
goto tmp3_done;
}
case 9: {
modelica_boolean tmp15;
_a1 = tmp4_1;
_op = tmp4_2;
_s1 = tmp4_3;
tmp15 = omc_Expression_isArrayScalarOp(threadData, _op);
if (1 != tmp15) goto goto_2;
_op = omc_ExpressionSimplify_unliftOperator(threadData, _a1, _op);
tmpMeta1 = omc_ExpressionSimplify_simplifyVectorScalar(threadData, _a1, _op, _s1);
goto tmp3_done;
}
case 10: {
modelica_boolean tmp16;
_s1 = tmp4_1;
_op = tmp4_2;
_a1 = tmp4_3;
tmp16 = omc_Expression_isScalarArrayOp(threadData, _op);
if (1 != tmp16) goto goto_2;
_op = omc_ExpressionSimplify_unliftOperator(threadData, _a1, _op);
tmpMeta1 = omc_ExpressionSimplify_simplifyVectorScalar(threadData, _s1, _op, _a1);
goto tmp3_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,14,1) == 0) goto tmp3_end;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 8;
tmpMeta1 = omc_ExpressionSimplify_simplifyScalarProduct(threadData, _e1, _e2);
goto tmp3_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,7,1) == 0) goto tmp3_end;
_op = tmp4_2;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 7;
tmpMeta1 = omc_ExpressionSimplify_simplifyMatrixBinary(threadData, _e1, _op, _e2);
goto tmp3_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,8,1) == 0) goto tmp3_end;
_op = tmp4_2;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 6;
tmpMeta1 = omc_ExpressionSimplify_simplifyMatrixBinary(threadData, _e1, _op, _e2);
goto tmp3_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,1) == 0) goto tmp3_end;
_op = tmp4_2;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 5;
tmpMeta1 = omc_ExpressionSimplify_simplifyMatrixBinary(threadData, _e1, _op, _e2);
goto tmp3_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,10,1) == 0) goto tmp3_end;
_op = tmp4_2;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 2;
tmpMeta1 = omc_ExpressionSimplify_simplifyMatrixBinary(threadData, _e1, _op, _e2);
goto tmp3_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,21,1) == 0) goto tmp3_end;
_op = tmp4_2;
_e1 = tmp4_1;
_e2 = tmp4_3;
tmp4 += 3;
tmpMeta1 = omc_ExpressionSimplify_simplifyMatrixBinary(threadData, _e1, _op, _e2);
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,11,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_tp = tmpMeta17;
_e2 = tmp4_3;
tmp4 += 2;
tmp18 = omc_Expression_isZero(threadData, _e2);
if (1 != tmp18) goto goto_2;
tmpMeta1 = omc_Expression_makeZeroExpression(threadData, omc_Expression_arrayDimension(threadData, _tp), NULL);
goto tmp3_done;
}
case 18: {
modelica_boolean tmp19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,10,1) == 0) goto tmp3_end;
_e1 = tmp4_1;
tmp4 += 1;
tmp19 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp19) goto goto_2;
_tp = omc_Expression_typeof(threadData, _e1);
tmpMeta1 = omc_Expression_makeZeroExpression(threadData, omc_Expression_arrayDimension(threadData, _tp), NULL);
goto tmp3_done;
}
case 19: {
modelica_boolean tmp20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,16,1) == 0) goto tmp3_end;
_e1 = tmp4_1;
tmp20 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp20) goto goto_2;
_tp = omc_Expression_typeof(threadData, _e1);
tmpMeta1 = omc_Expression_makeZeroExpression(threadData, omc_Expression_arrayDimension(threadData, _tp), NULL);
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
if (++tmp4 < 20) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ExpressionSimplify_simplifyBinaryArrayOp(threadData_t *threadData, modelica_metatype _inOperator)
{
modelica_boolean _found;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inOperator;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 18: {
tmp1 = 1;
goto tmp3_done;
}
case 10: {
tmp1 = 1;
goto tmp3_done;
}
case 11: {
tmp1 = 1;
goto tmp3_done;
}
case 12: {
tmp1 = 1;
goto tmp3_done;
}
case 13: {
tmp1 = 1;
goto tmp3_done;
}
case 23: {
tmp1 = 1;
goto tmp3_done;
}
case 24: {
tmp1 = 1;
goto tmp3_done;
}
case 14: {
tmp1 = 1;
goto tmp3_done;
}
case 15: {
tmp1 = 1;
goto tmp3_done;
}
case 19: {
tmp1 = 1;
goto tmp3_done;
}
case 21: {
tmp1 = 1;
goto tmp3_done;
}
case 16: {
tmp1 = 1;
goto tmp3_done;
}
case 20: {
tmp1 = 1;
goto tmp3_done;
}
case 22: {
tmp1 = 1;
goto tmp3_done;
}
case 17: {
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
_found = tmp1;
_return: OMC_LABEL_UNUSED
return _found;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyBinaryArrayOp(threadData_t *threadData, modelica_metatype _inOperator)
{
modelica_boolean _found;
modelica_metatype out_found;
_found = omc_ExpressionSimplify_simplifyBinaryArrayOp(threadData, _inOperator);
out_found = mmc_mk_icon(_found);
return out_found;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplify2(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean _simplifyAddOrSub, modelica_boolean _simplifyMulOrDiv)
{
modelica_metatype _outExp = NULL;
modelica_metatype _ty = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ty = omc_Expression_typeof(threadData, _inExp);
if((!omc_Expression_isIntegerOrReal(threadData, _ty)))
{
_outExp = _inExp;
goto _return;
}
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _exp_2 = NULL;
modelica_metatype _exp_3 = NULL;
modelica_metatype _resConst = NULL;
modelica_metatype _lstConstExp = NULL;
modelica_metatype _lstExp = NULL;
modelica_metatype _op = NULL;
modelica_boolean _hasConst;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_boolean tmp7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_op = tmpMeta6;
if (!(_simplifyAddOrSub && omc_Expression_isAddOrSub(threadData, _op))) goto tmp3_end;
_lstExp = omc_Expression_terms(threadData, _inExp);
_lstConstExp = omc_List_splitOnTrue(threadData, _lstExp, boxvar_Expression_isConstValue ,&_lstExp);
_hasConst = (!listEmpty(_lstConstExp));
_resConst = (_hasConst?omc_ExpressionSimplify_simplifyBinaryAddConstants(threadData, _lstConstExp):omc_Expression_makeConstZero(threadData, _ty));
_exp_2 = (_hasConst?omc_Expression_makeSum1(threadData, _lstExp, 0):_inExp);
_exp_3 = omc_ExpressionSimplify_simplifyBinaryCoeff(threadData, _exp_2);
tmp7 = (modelica_boolean)_hasConst;
if(tmp7)
{
tmpMeta8 = omc_Expression_expAdd(threadData, _resConst, omc_ExpressionSimplify_simplify2(threadData, _exp_3, 0, 1));
}
else
{
_inExp = _exp_3;
_simplifyAddOrSub = 0;
_simplifyMulOrDiv = 1;
goto _tailrecursive;
}
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta9;
_op = tmpMeta10;
_e2 = tmpMeta11;
if (!omc_Expression_isAddOrSub(threadData, _op)) goto tmp3_end;
_e1 = omc_ExpressionSimplify_simplify2(threadData, _e1, 0, 1);
_e2 = omc_ExpressionSimplify_simplify2(threadData, _e2, 0, 1);
tmpMeta12 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e2);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_op = tmpMeta13;
if (!(_simplifyMulOrDiv && omc_Expression_isMulOrDiv(threadData, _op))) goto tmp3_end;
_lstExp = omc_Expression_factors(threadData, _inExp);
_lstConstExp = omc_List_splitOnTrue(threadData, _lstExp, boxvar_Expression_isConst ,&_lstExp);
if((!listEmpty(_lstConstExp)))
{
_resConst = omc_ExpressionSimplify_simplifyBinaryMulConstants(threadData, _lstConstExp);
_exp_2 = omc_Expression_makeProductLst(threadData, (omc_Types_isScalarReal(threadData, omc_Expression_typeofOp(threadData, _op))?omc_ExpressionSimplify_simplifyMul(threadData, _lstExp):_lstExp));
if(omc_Expression_isConstOne(threadData, _resConst))
{
_exp_3 = omc_ExpressionSimplify_simplify2(threadData, _exp_2, 1, 0);
}
else
{
if(omc_Expression_isConstMinusOne(threadData, _resConst))
{
_exp_3 = omc_Expression_negate(threadData, omc_ExpressionSimplify_simplify2(threadData, _exp_2, 1, 0));
}
else
{
_exp_3 = omc_Expression_expMul(threadData, _resConst, omc_ExpressionSimplify_simplify2(threadData, _exp_2, 1, 0));
}
}
}
else
{
_exp_2 = omc_ExpressionSimplify_simplifyBinaryCoeff(threadData, _inExp);
_exp_3 = omc_ExpressionSimplify_simplify2(threadData, _exp_2, 1, 0);
}
tmpMeta1 = _exp_3;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta14;
_op = tmpMeta15;
_e2 = tmpMeta16;
if (!omc_Expression_isMulOrDiv(threadData, _op)) goto tmp3_end;
_e1 = omc_ExpressionSimplify_simplify2(threadData, _e1, 1, 0);
_e2 = omc_ExpressionSimplify_simplify2(threadData, _e2, 1, 0);
tmpMeta17 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e2);
tmpMeta1 = tmpMeta17;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta18;
_op = tmpMeta19;
_e2 = tmpMeta20;
_e1 = omc_ExpressionSimplify_simplify2(threadData, _e1, 1, 1);
_e2 = omc_ExpressionSimplify_simplify2(threadData, _e2, 1, 1);
tmpMeta21 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e2);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_op = tmpMeta22;
_e1 = tmpMeta23;
_e1 = omc_ExpressionSimplify_simplify2(threadData, _e1, 1, 1);
tmpMeta24 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op, _e1);
tmpMeta1 = tmpMeta24;
goto tmp3_done;
}
case 6: {
tmpMeta1 = _inExp;
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype boxptr_ExpressionSimplify_simplify2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _simplifyAddOrSub, modelica_metatype _simplifyMulOrDiv)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_simplifyAddOrSub);
tmp2 = mmc_unbox_integer(_simplifyMulOrDiv);
_outExp = omc_ExpressionSimplify_simplify2(threadData, _inExp, tmp1, tmp2);
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCrefMM1(threadData_t *threadData, modelica_string _ident, modelica_metatype _ty, modelica_metatype _ssl)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ssl;
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
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta7 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _ident, _ty, tmpMeta6);
tmpMeta8 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, tmpMeta7, _ty);
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta16;
tmpMeta9 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta10 = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _ident, _ty, tmpMeta9);
tmpMeta11 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, tmpMeta10, _ty);
{
modelica_metatype __omcQ_24tmpVar17;
modelica_metatype* tmp13;
modelica_metatype tmpMeta14;
modelica_metatype __omcQ_24tmpVar16;
modelica_integer tmp15;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = _ssl;
tmpMeta14 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar17 = tmpMeta14;
tmp13 = &__omcQ_24tmpVar17;
while(1) {
tmp15 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp15--;
}
if (tmp15 == 0) {
__omcQ_24tmpVar16 = omc_Expression_subscriptIndexExp(threadData, _s);
*tmp13 = mmc_mk_cons(__omcQ_24tmpVar16,0);
tmp13 = &MMC_CDR(*tmp13);
} else if (tmp15 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp13 = mmc_mk_nil();
tmpMeta12 = __omcQ_24tmpVar17;
}
tmpMeta16 = mmc_mk_box3(24, &DAE_Exp_ASUB__desc, tmpMeta11, tmpMeta12);
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCrefMM(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inType, modelica_metatype _inCref)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCref;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta10;
modelica_boolean tmp11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
_exp = omc_ExpressionSimplify_simplifyCrefMM__index(threadData, _inExp, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 2))), _inType);
tmp11 = (modelica_boolean)listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 4))));
if(tmp11)
{
tmpMeta12 = _exp;
}
else
{
{
modelica_metatype __omcQ_24tmpVar19;
modelica_metatype* tmp7;
modelica_metatype tmpMeta8;
modelica_metatype __omcQ_24tmpVar18;
modelica_integer tmp9;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 4)));
tmpMeta8 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar19 = tmpMeta8;
tmp7 = &__omcQ_24tmpVar19;
while(1) {
tmp9 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar18 = omc_Expression_subscriptIndexExp(threadData, _s);
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar18,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp9 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp7 = mmc_mk_nil();
tmpMeta6 = __omcQ_24tmpVar19;
}
tmpMeta10 = mmc_mk_box3(24, &DAE_Exp_ASUB__desc, _exp, tmpMeta6);
tmpMeta12 = tmpMeta10;
}
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta17;
modelica_boolean tmp18;
modelica_metatype tmpMeta19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
_exp = omc_ExpressionSimplify_simplifyCrefMM__index(threadData, _inExp, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 2))), _inType);
tmp18 = (modelica_boolean)listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 4))));
if(tmp18)
{
tmpMeta19 = _exp;
}
else
{
{
modelica_metatype __omcQ_24tmpVar21;
modelica_metatype* tmp14;
modelica_metatype tmpMeta15;
modelica_metatype __omcQ_24tmpVar20;
modelica_integer tmp16;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 4)));
tmpMeta15 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar21 = tmpMeta15;
tmp14 = &__omcQ_24tmpVar21;
while(1) {
tmp16 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp16--;
}
if (tmp16 == 0) {
__omcQ_24tmpVar20 = omc_Expression_subscriptIndexExp(threadData, _s);
*tmp14 = mmc_mk_cons(__omcQ_24tmpVar20,0);
tmp14 = &MMC_CDR(*tmp14);
} else if (tmp16 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp14 = mmc_mk_nil();
tmpMeta13 = __omcQ_24tmpVar21;
}
tmpMeta17 = mmc_mk_box3(24, &DAE_Exp_ASUB__desc, _exp, tmpMeta13);
tmpMeta19 = tmpMeta17;
}
_exp = tmpMeta19;
_inExp = _exp;
_inType = omc_Expression_typeof(threadData, _exp);
_inCref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 5)));
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
_exp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCrefMM__index(threadData_t *threadData, modelica_metatype _inExp, modelica_string _ident, modelica_metatype _ty)
{
modelica_metatype _exp = NULL;
modelica_integer _index;
modelica_metatype _nty = NULL;
modelica_metatype _ty2 = NULL;
modelica_metatype _fields = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_fields = omc_Types_getMetaRecordFields(threadData, _ty);
_index = ((modelica_integer) 1) + omc_Types_findVarIndex(threadData, _ident, _fields);
tmpMeta1 = listGet(_fields, _index);
tmpMeta2 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta1), 4));
_nty = tmpMeta2;
tmpMeta3 = mmc_mk_box5(26, &DAE_Exp_RSUB__desc, _inExp, mmc_mk_integer(_index), _ident, _nty);
_exp = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCref2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inSsl)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inSsl;
{
modelica_metatype _t = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _exp_1 = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _expl_1 = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _ss = NULL;
modelica_metatype _ssl = NULL;
modelica_metatype _subs = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype _cr = NULL;
modelica_integer _dim;
modelica_boolean _sc;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_exp_1 = tmp4_1;
tmp4 += 2;
tmpMeta1 = _exp_1;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,3) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_2);
tmpMeta9 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta10,16,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 4));
_cr = tmpMeta6;
_t = tmpMeta7;
_expl_1 = tmpMeta11;
_ssl = tmpMeta9;
tmp4 += 2;
_subs = omc_List_map(threadData, _expl_1, boxvar_Expression_makeIndexSubscript);
_crefs = omc_List_map1r(threadData, omc_List_map(threadData, _subs, boxvar_List_create), boxvar_ComponentReference_subscriptCref, _cr);
_t = omc_Types_unliftArray(threadData, _t);
_expl = omc_List_map1(threadData, _crefs, boxvar_Expression_makeCrefExp, _t);
_dim = listLength(_expl);
tmpMeta13 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim));
tmpMeta12 = mmc_mk_cons(tmpMeta13, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta14 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _t, tmpMeta12);
tmpMeta15 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta14, mmc_mk_boolean(1), _expl);
tmpMeta1 = omc_ExpressionSimplify_simplifyCref2(threadData, tmpMeta15, _ssl);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,1,3) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmp4_2);
tmpMeta19 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,1,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta20,18,4) == 0) goto tmp3_end;
_cr = tmpMeta16;
_t = tmpMeta17;
_ss = tmpMeta18;
_ssl = tmpMeta19;
tmp4 += 1;
_subs = omc_Expression_expandSliceExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ss), 2))));
{
modelica_metatype __omcQ_24tmpVar23;
modelica_metatype* tmp22;
modelica_metatype tmpMeta23;
modelica_metatype __omcQ_24tmpVar22;
modelica_integer tmp24;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = _subs;
tmpMeta23 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar23 = tmpMeta23;
tmp22 = &__omcQ_24tmpVar23;
while(1) {
tmp24 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp24--;
}
if (tmp24 == 0) {
__omcQ_24tmpVar22 = omc_ComponentReference_subscriptCref(threadData, _cr, omc_List_create(threadData, _s));
*tmp22 = mmc_mk_cons(__omcQ_24tmpVar22,0);
tmp22 = &MMC_CDR(*tmp22);
} else if (tmp24 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp22 = mmc_mk_nil();
tmpMeta21 = __omcQ_24tmpVar23;
}
_crefs = tmpMeta21;
_t = omc_Types_unliftArray(threadData, _t);
{
modelica_metatype __omcQ_24tmpVar25;
modelica_metatype* tmp26;
modelica_metatype tmpMeta27;
modelica_metatype __omcQ_24tmpVar24;
modelica_integer tmp28;
modelica_metatype _cr_loopVar = 0;
modelica_metatype _cr;
_cr_loopVar = _crefs;
tmpMeta27 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar25 = tmpMeta27;
tmp26 = &__omcQ_24tmpVar25;
while(1) {
tmp28 = 1;
if (!listEmpty(_cr_loopVar)) {
_cr = MMC_CAR(_cr_loopVar);
_cr_loopVar = MMC_CDR(_cr_loopVar);
tmp28--;
}
if (tmp28 == 0) {
__omcQ_24tmpVar24 = omc_Expression_makeCrefExp(threadData, _cr, _t);
*tmp26 = mmc_mk_cons(__omcQ_24tmpVar24,0);
tmp26 = &MMC_CDR(*tmp26);
} else if (tmp28 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp26 = mmc_mk_nil();
tmpMeta25 = __omcQ_24tmpVar25;
}
_expl = tmpMeta25;
_dim = listLength(_expl);
tmpMeta30 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim));
tmpMeta29 = mmc_mk_cons(tmpMeta30, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta31 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _t, tmpMeta29);
tmpMeta32 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta31, mmc_mk_boolean(1), _expl);
_exp = tmpMeta32;
tmpMeta1 = omc_ExpressionSimplify_simplifyCref2(threadData, _exp, _ssl);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_integer tmp35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp35 = mmc_unbox_integer(tmpMeta34);
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_tp = tmpMeta33;
_sc = tmp35;
_expl = tmpMeta36;
_ssl = tmp4_2;
_expl = omc_List_map1(threadData, _expl, boxvar_ExpressionSimplify_simplifyCref2, _ssl);
tmpMeta37 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(_sc), _expl);
tmpMeta1 = tmpMeta37;
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCref(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inCREF, modelica_metatype _inType)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inCREF;
{
modelica_metatype _t2 = NULL;
modelica_metatype _ssl = NULL;
modelica_metatype _cr = NULL;
modelica_string _idn = NULL;
modelica_metatype _expCref = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,1,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,16,3) == 0) goto tmp3_end;
_idn = tmpMeta6;
_t2 = tmpMeta7;
_ssl = tmpMeta8;
tmp4 += 2;
tmpMeta12 = MMC_REFSTRUCTLIT(mmc_nil);
_cr = omc_ComponentReference_makeCrefIdent(threadData, _idn, _t2, tmpMeta12);
_expCref = omc_Expression_makeCrefExp(threadData, _cr, _inType);
tmpMeta1 = omc_ExpressionSimplify_simplifyCref2(threadData, _expCref, _ssl);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_CAR(tmpMeta13);
tmpMeta15 = MMC_CDR(tmpMeta13);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,1,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,18,4) == 0) goto tmp3_end;
tmp4 += 1;
_cr = omc_ComponentReference_crefStripSubs(threadData, _inCREF);
_expCref = omc_Expression_makeCrefExp(threadData, _cr, _inType);
tmpMeta1 = omc_ExpressionSimplify_simplifyCref2(threadData, _expCref, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCREF), 4))));
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,25,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_idn = tmpMeta17;
_t2 = tmpMeta19;
_ssl = tmpMeta20;
_cr = tmpMeta21;
_exp = omc_ExpressionSimplify_simplifyCrefMM1(threadData, _idn, _t2, _ssl);
tmpMeta1 = omc_ExpressionSimplify_simplifyCrefMM(threadData, _exp, omc_Expression_typeof(threadData, _exp), _cr);
goto tmp3_done;
}
case 3: {
tmpMeta1 = _origExp;
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
_exp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBuiltinConstantCalls(threadData_t *threadData, modelica_string _name, modelica_metatype _exp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_string tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _name;
tmp4_2 = _exp;
{
modelica_real _r;
modelica_real _v1;
modelica_real _v2;
modelica_integer _i;
modelica_integer _j;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 23; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT61), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
if (!listEmpty(tmpMeta8)) goto tmp3_end;
_e = tmpMeta7;
tmp4 += 22;
tmpMeta1 = omc_ExpressionSimplify_simplifyBuiltinConstantDer(threadData, _e);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT62), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
if (!listEmpty(tmpMeta11)) goto tmp3_end;
_e = tmpMeta10;
tmp4 += 21;
tmpMeta1 = _e;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (8 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT63), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta12)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmpMeta12);
tmpMeta14 = MMC_CDR(tmpMeta12);
if (!listEmpty(tmpMeta14)) goto tmp3_end;
_e = tmpMeta13;
tmp4 += 20;
tmpMeta1 = _e;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
if (4 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT64), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta15)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmpMeta15);
tmpMeta17 = MMC_CDR(tmpMeta15);
if (!listEmpty(tmpMeta17)) goto tmp3_end;
tmp4 += 19;
tmpMeta1 = _OMC_LIT22;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
if (6 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT65), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta18)) goto tmp3_end;
tmpMeta19 = MMC_CAR(tmpMeta18);
tmpMeta20 = MMC_CDR(tmpMeta18);
if (!listEmpty(tmpMeta20)) goto tmp3_end;
tmp4 += 18;
tmpMeta1 = _OMC_LIT22;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_real tmp24;
modelica_metatype tmpMeta25;
if (4 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta21)) goto tmp3_end;
tmpMeta22 = MMC_CAR(tmpMeta21);
tmpMeta23 = MMC_CDR(tmpMeta21);
if (!listEmpty(tmpMeta23)) goto tmp3_end;
_e = tmpMeta22;
tmp4 += 17;
tmp24 = omc_Expression_toReal(threadData, _e);
if(!(tmp24 >= 0.0))
{
FILE_INFO info = {"",0,0,0,0,0};
omc_assert(threadData, info, "Model error: Argument of sqrt(Expression.toReal(e)) was %g should be >= 0", tmp24);
}
_r = sqrt(tmp24);
tmpMeta25 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta25;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_real tmp30;
modelica_metatype tmpMeta31;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta26)) goto tmp3_end;
tmpMeta27 = MMC_CAR(tmpMeta26);
tmpMeta28 = MMC_CDR(tmpMeta26);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,1,1) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 2));
tmp30 = mmc_unbox_real(tmpMeta29);
if (!listEmpty(tmpMeta28)) goto tmp3_end;
_r = tmp30;
tmp4 += 16;
_r = fabs(_r);
tmpMeta31 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta31;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_integer tmp36;
modelica_metatype tmpMeta37;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta32)) goto tmp3_end;
tmpMeta33 = MMC_CAR(tmpMeta32);
tmpMeta34 = MMC_CDR(tmpMeta32);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta33,0,1) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 2));
tmp36 = mmc_unbox_integer(tmpMeta35);
if (!listEmpty(tmpMeta34)) goto tmp3_end;
_i = tmp36;
tmp4 += 15;
_i = labs(_i);
tmpMeta37 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta1 = tmpMeta37;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta38)) goto tmp3_end;
tmpMeta39 = MMC_CAR(tmpMeta38);
tmpMeta40 = MMC_CDR(tmpMeta38);
if (!listEmpty(tmpMeta40)) goto tmp3_end;
_e = tmpMeta39;
tmp4 += 14;
_r = sin(omc_Expression_toReal(threadData, _e));
tmpMeta41 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta41;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta42)) goto tmp3_end;
tmpMeta43 = MMC_CAR(tmpMeta42);
tmpMeta44 = MMC_CDR(tmpMeta42);
if (!listEmpty(tmpMeta44)) goto tmp3_end;
_e = tmpMeta43;
tmp4 += 13;
_r = cos(omc_Expression_toReal(threadData, _e));
tmpMeta45 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta45;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_boolean tmp49;
modelica_real tmp50;
modelica_metatype tmpMeta51;
if (4 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT66), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta46)) goto tmp3_end;
tmpMeta47 = MMC_CAR(tmpMeta46);
tmpMeta48 = MMC_CDR(tmpMeta46);
if (!listEmpty(tmpMeta48)) goto tmp3_end;
_e = tmpMeta47;
tmp4 += 12;
_r = omc_Expression_toReal(threadData, _e);
tmp49 = ((_r >= -1.0) && (_r <= 1.0));
if (1 != tmp49) goto goto_2;
tmp50 = _r;
if(!(tmp50 >= -1.0 && tmp50 <= 1.0))
{
FILE_INFO info = {"",0,0,0,0,0};
omc_assert(threadData, info, "Model error: Argument of asin(r) outside the domain -1.0 <= %g <= 1.0", tmp50);
}
_r = asin(tmp50);
tmpMeta51 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta51;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta52;
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_boolean tmp55;
modelica_real tmp56;
modelica_metatype tmpMeta57;
if (4 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT67), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta52)) goto tmp3_end;
tmpMeta53 = MMC_CAR(tmpMeta52);
tmpMeta54 = MMC_CDR(tmpMeta52);
if (!listEmpty(tmpMeta54)) goto tmp3_end;
_e = tmpMeta53;
tmp4 += 11;
_r = omc_Expression_toReal(threadData, _e);
tmp55 = ((_r >= -1.0) && (_r <= 1.0));
if (1 != tmp55) goto goto_2;
tmp56 = omc_Expression_toReal(threadData, _e);
if(!(tmp56 >= -1.0 && tmp56 <= 1.0))
{
FILE_INFO info = {"",0,0,0,0,0};
omc_assert(threadData, info, "Model error: Argument of acos(Expression.toReal(e)) outside the domain -1.0 <= %g <= 1.0", tmp56);
}
_r = acos(tmp56);
tmpMeta57 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta57;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT37), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta58)) goto tmp3_end;
tmpMeta59 = MMC_CAR(tmpMeta58);
tmpMeta60 = MMC_CDR(tmpMeta58);
if (!listEmpty(tmpMeta60)) goto tmp3_end;
_e = tmpMeta59;
tmp4 += 10;
_r = tan(omc_Expression_toReal(threadData, _e));
tmpMeta61 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta61;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta62)) goto tmp3_end;
tmpMeta63 = MMC_CAR(tmpMeta62);
tmpMeta64 = MMC_CDR(tmpMeta62);
if (!listEmpty(tmpMeta64)) goto tmp3_end;
_e = tmpMeta63;
tmp4 += 9;
_r = exp(omc_Expression_toReal(threadData, _e));
tmpMeta65 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta65;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
modelica_boolean tmp69;
modelica_real tmp70;
modelica_metatype tmpMeta71;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta66)) goto tmp3_end;
tmpMeta67 = MMC_CAR(tmpMeta66);
tmpMeta68 = MMC_CDR(tmpMeta66);
if (!listEmpty(tmpMeta68)) goto tmp3_end;
_e = tmpMeta67;
tmp4 += 8;
_r = omc_Expression_toReal(threadData, _e);
tmp69 = (_r > 0.0);
if (1 != tmp69) goto goto_2;
tmp70 = _r;
if(!(tmp70 > 0.0))
{
FILE_INFO info = {"",0,0,0,0,0};
omc_assert(threadData, info, "Model error: Argument of log(r) was %g should be > 0", tmp70);
}
_r = log(tmp70);
tmpMeta71 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta71;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
modelica_boolean tmp75;
modelica_real tmp76;
modelica_metatype tmpMeta77;
if (5 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT69), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta72)) goto tmp3_end;
tmpMeta73 = MMC_CAR(tmpMeta72);
tmpMeta74 = MMC_CDR(tmpMeta72);
if (!listEmpty(tmpMeta74)) goto tmp3_end;
_e = tmpMeta73;
tmp4 += 7;
_r = omc_Expression_toReal(threadData, _e);
tmp75 = (_r > 0.0);
if (1 != tmp75) goto goto_2;
tmp76 = _r;
if(!(tmp76 > 0.0))
{
FILE_INFO info = {"",0,0,0,0,0};
omc_assert(threadData, info, "Model error: Argument of log10(r) was %g should be > 0", tmp76);
}
_r = log10(tmp76);
tmpMeta77 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta77;
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
modelica_integer tmp82;
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
modelica_integer tmp86;
modelica_metatype tmpMeta87;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta78)) goto tmp3_end;
tmpMeta79 = MMC_CAR(tmpMeta78);
tmpMeta80 = MMC_CDR(tmpMeta78);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta79,0,1) == 0) goto tmp3_end;
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta79), 2));
tmp82 = mmc_unbox_integer(tmpMeta81);
if (listEmpty(tmpMeta80)) goto tmp3_end;
tmpMeta83 = MMC_CAR(tmpMeta80);
tmpMeta84 = MMC_CDR(tmpMeta80);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta83,0,1) == 0) goto tmp3_end;
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta83), 2));
tmp86 = mmc_unbox_integer(tmpMeta85);
if (!listEmpty(tmpMeta84)) goto tmp3_end;
_i = tmp82;
_j = tmp86;
_i = modelica_integer_min((modelica_integer)(_i),(modelica_integer)(_j));
tmpMeta87 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta1 = tmpMeta87;
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta88)) goto tmp3_end;
tmpMeta89 = MMC_CAR(tmpMeta88);
tmpMeta90 = MMC_CDR(tmpMeta88);
if (listEmpty(tmpMeta90)) goto tmp3_end;
tmpMeta91 = MMC_CAR(tmpMeta90);
tmpMeta92 = MMC_CDR(tmpMeta90);
if (!listEmpty(tmpMeta92)) goto tmp3_end;
tmpMeta93 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta93), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta94,1,1) == 0) goto tmp3_end;
_e = tmpMeta89;
_e1 = tmpMeta91;
_v1 = omc_Expression_toReal(threadData, _e);
_v2 = omc_Expression_toReal(threadData, _e1);
_r = fmin(_v1,_v2);
tmpMeta95 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta95;
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
modelica_integer tmp100;
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
modelica_integer tmp104;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta96 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta96)) goto tmp3_end;
tmpMeta97 = MMC_CAR(tmpMeta96);
tmpMeta98 = MMC_CDR(tmpMeta96);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta97,5,2) == 0) goto tmp3_end;
tmpMeta99 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta97), 3));
tmp100 = mmc_unbox_integer(tmpMeta99);
if (listEmpty(tmpMeta98)) goto tmp3_end;
tmpMeta101 = MMC_CAR(tmpMeta98);
tmpMeta102 = MMC_CDR(tmpMeta98);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta101,5,2) == 0) goto tmp3_end;
tmpMeta103 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta101), 3));
tmp104 = mmc_unbox_integer(tmpMeta103);
if (!listEmpty(tmpMeta102)) goto tmp3_end;
_e = tmpMeta97;
_i = tmp100;
_e1 = tmpMeta101;
_j = tmp104;
tmp4 += 4;
tmpMeta1 = ((_i < _j)?_e:_e1);
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta105;
modelica_metatype tmpMeta106;
modelica_metatype tmpMeta107;
modelica_metatype tmpMeta108;
modelica_integer tmp109;
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
modelica_integer tmp113;
modelica_metatype tmpMeta114;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta105 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta105)) goto tmp3_end;
tmpMeta106 = MMC_CAR(tmpMeta105);
tmpMeta107 = MMC_CDR(tmpMeta105);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta106,0,1) == 0) goto tmp3_end;
tmpMeta108 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta106), 2));
tmp109 = mmc_unbox_integer(tmpMeta108);
if (listEmpty(tmpMeta107)) goto tmp3_end;
tmpMeta110 = MMC_CAR(tmpMeta107);
tmpMeta111 = MMC_CDR(tmpMeta107);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta110,0,1) == 0) goto tmp3_end;
tmpMeta112 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta110), 2));
tmp113 = mmc_unbox_integer(tmpMeta112);
if (!listEmpty(tmpMeta111)) goto tmp3_end;
_i = tmp109;
_j = tmp113;
_i = modelica_integer_max((modelica_integer)(_i),(modelica_integer)(_j));
tmpMeta114 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta1 = tmpMeta114;
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta115;
modelica_metatype tmpMeta116;
modelica_metatype tmpMeta117;
modelica_metatype tmpMeta118;
modelica_metatype tmpMeta119;
modelica_metatype tmpMeta120;
modelica_metatype tmpMeta121;
modelica_metatype tmpMeta122;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta115 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta115)) goto tmp3_end;
tmpMeta116 = MMC_CAR(tmpMeta115);
tmpMeta117 = MMC_CDR(tmpMeta115);
if (listEmpty(tmpMeta117)) goto tmp3_end;
tmpMeta118 = MMC_CAR(tmpMeta117);
tmpMeta119 = MMC_CDR(tmpMeta117);
if (!listEmpty(tmpMeta119)) goto tmp3_end;
tmpMeta120 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 4));
tmpMeta121 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta120), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta121,1,1) == 0) goto tmp3_end;
_e = tmpMeta116;
_e1 = tmpMeta118;
_v1 = omc_Expression_toReal(threadData, _e);
_v2 = omc_Expression_toReal(threadData, _e1);
_r = fmax(_v1,_v2);
tmpMeta122 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta122;
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta123;
modelica_metatype tmpMeta124;
modelica_metatype tmpMeta125;
modelica_metatype tmpMeta126;
modelica_integer tmp127;
modelica_metatype tmpMeta128;
modelica_metatype tmpMeta129;
modelica_metatype tmpMeta130;
modelica_integer tmp131;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta123 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta123)) goto tmp3_end;
tmpMeta124 = MMC_CAR(tmpMeta123);
tmpMeta125 = MMC_CDR(tmpMeta123);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta124,5,2) == 0) goto tmp3_end;
tmpMeta126 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta124), 3));
tmp127 = mmc_unbox_integer(tmpMeta126);
if (listEmpty(tmpMeta125)) goto tmp3_end;
tmpMeta128 = MMC_CAR(tmpMeta125);
tmpMeta129 = MMC_CDR(tmpMeta125);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta128,5,2) == 0) goto tmp3_end;
tmpMeta130 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta128), 3));
tmp131 = mmc_unbox_integer(tmpMeta130);
if (!listEmpty(tmpMeta129)) goto tmp3_end;
_e = tmpMeta124;
_i = tmp127;
_e1 = tmpMeta128;
_j = tmp131;
tmp4 += 1;
tmpMeta1 = ((_i > _j)?_e:_e1);
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta132;
modelica_metatype tmpMeta133;
modelica_metatype tmpMeta134;
modelica_metatype tmpMeta135;
modelica_real tmp136;
modelica_metatype tmpMeta137;
if (4 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT43), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,13,3) == 0) goto tmp3_end;
tmpMeta132 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (listEmpty(tmpMeta132)) goto tmp3_end;
tmpMeta133 = MMC_CAR(tmpMeta132);
tmpMeta134 = MMC_CDR(tmpMeta132);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta133,1,1) == 0) goto tmp3_end;
tmpMeta135 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta133), 2));
tmp136 = mmc_unbox_real(tmpMeta135);
if (!listEmpty(tmpMeta134)) goto tmp3_end;
_r = tmp136;
_i = ((_r == 0.0)?((modelica_integer) 0):((_r > 0.0)?((modelica_integer) 1):((modelica_integer) -1)));
tmpMeta137 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta1 = tmpMeta137;
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
if (++tmp4 < 23) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyStringAppendList(threadData_t *threadData, modelica_metatype _iexpl, modelica_metatype _iacc, modelica_boolean _ichange)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_boolean tmp4_3;
tmp4_1 = _iexpl;
tmp4_2 = _iacc;
tmp4_3 = _ichange;
{
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_string _s = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _acc = NULL;
modelica_boolean _change;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta1 = _OMC_LIT71;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (!listEmpty(tmpMeta7)) goto tmp3_end;
_exp = tmpMeta6;
tmpMeta1 = _exp;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (!listEmpty(tmp4_1)) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmp4_2);
tmpMeta9 = MMC_CDR(tmp4_2);
if (listEmpty(tmpMeta9)) goto tmp3_end;
tmpMeta10 = MMC_CAR(tmpMeta9);
tmpMeta11 = MMC_CDR(tmpMeta9);
if (!listEmpty(tmpMeta11)) goto tmp3_end;
_exp1 = tmpMeta8;
_exp2 = tmpMeta10;
tmpMeta12 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _exp2, _OMC_LIT73, _exp1);
tmpMeta1 = tmpMeta12;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
if (1 != tmp4_3) goto tmp3_end;
if (!listEmpty(tmp4_1)) goto tmp3_end;
_acc = tmp4_2;
_acc = listReverse(_acc);
tmpMeta13 = mmc_mk_box2(31, &DAE_Exp_LIST__desc, _acc);
_exp = tmpMeta13;
tmpMeta14 = mmc_mk_cons(_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT74, tmpMeta14, _OMC_LIT72);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmp4_1);
tmpMeta16 = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,2,1) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmp4_2);
tmpMeta19 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,2,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 2));
_s1 = tmpMeta17;
_rest = tmpMeta16;
_s2 = tmpMeta20;
_acc = tmpMeta19;
tmpMeta21 = stringAppend(_s2,_s1);
_s = tmpMeta21;
tmpMeta23 = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _s);
tmpMeta22 = mmc_mk_cons(tmpMeta23, _acc);
_iexpl = _rest;
_iacc = tmpMeta22;
_ichange = 1;
goto _tailrecursive;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta24 = MMC_CAR(tmp4_1);
tmpMeta25 = MMC_CDR(tmp4_1);
_exp = tmpMeta24;
_rest = tmpMeta25;
_acc = tmp4_2;
_change = tmp4_3;
tmpMeta26 = mmc_mk_cons(_exp, _acc);
_iexpl = _rest;
_iacc = tmpMeta26;
_ichange = _change;
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
_exp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyStringAppendList(threadData_t *threadData, modelica_metatype _iexpl, modelica_metatype _iacc, modelica_metatype _ichange)
{
modelica_integer tmp1;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_integer(_ichange);
_exp = omc_ExpressionSimplify_simplifyStringAppendList(threadData, _iexpl, _iacc, tmp1);
return _exp;
}
DLLExport
modelica_string omc_ExpressionSimplify_cevalBuiltinStringFormat(threadData_t *threadData, modelica_string _inString, modelica_integer _stringLength, modelica_integer _minLength, modelica_boolean _leftJustified)
{
modelica_string _outString = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_boolean tmp3;
modelica_string tmp4;
modelica_boolean tmp5;
modelica_string tmp6;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp5 = (modelica_boolean)(_stringLength >= _minLength);
if(tmp5)
{
tmp6 = _inString;
}
else
{
tmp3 = (modelica_boolean)_leftJustified;
if(tmp3)
{
tmpMeta1 = stringAppend(_inString,stringAppendList(omc_List_fill(threadData, _OMC_LIT75, _minLength - _stringLength)));
tmp4 = tmpMeta1;
}
else
{
tmpMeta2 = stringAppend(stringAppendList(omc_List_fill(threadData, _OMC_LIT75, _minLength - _stringLength)),_inString);
tmp4 = tmpMeta2;
}
tmp6 = tmp4;
}
_outString = tmp6;
_return: OMC_LABEL_UNUSED
return _outString;
}
modelica_metatype boxptr_ExpressionSimplify_cevalBuiltinStringFormat(threadData_t *threadData, modelica_metatype _inString, modelica_metatype _stringLength, modelica_metatype _minLength, modelica_metatype _leftJustified)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_string _outString = NULL;
tmp1 = mmc_unbox_integer(_stringLength);
tmp2 = mmc_unbox_integer(_minLength);
tmp3 = mmc_unbox_integer(_leftJustified);
_outString = omc_ExpressionSimplify_cevalBuiltinStringFormat(threadData, _inString, tmp1, tmp2, tmp3);
return _outString;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBuiltinStringFormat(threadData_t *threadData, modelica_metatype _exp, modelica_metatype _len_exp, modelica_metatype _just_exp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _exp;
tmp4_2 = _len_exp;
tmp4_3 = _just_exp;
{
modelica_integer _i;
modelica_integer _len;
modelica_real _r;
modelica_boolean _b;
modelica_boolean _just;
modelica_string _str = NULL;
modelica_metatype _name = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
modelica_metatype tmpMeta5;
modelica_integer tmp6;
modelica_metatype tmpMeta7;
modelica_integer tmp8;
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta5);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp8 = mmc_unbox_integer(tmpMeta7);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
_i = tmp6;
_len = tmp8;
_just = tmp10;
_str = intString(_i);
_str = omc_ExpressionSimplify_cevalBuiltinStringFormat(threadData, _str, stringLength(_str), _len, _just);
tmpMeta11 = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _str);
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta12;
modelica_real tmp13;
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
modelica_integer tmp17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp13 = mmc_unbox_real(tmpMeta12);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
_r = tmp13;
_len = tmp15;
_just = tmp17;
_str = realString(_r);
_str = omc_ExpressionSimplify_cevalBuiltinStringFormat(threadData, _str, stringLength(_str), _len, _just);
tmpMeta18 = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _str);
tmpMeta1 = tmpMeta18;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
modelica_integer tmp22;
modelica_metatype tmpMeta23;
modelica_integer tmp24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp20 = mmc_unbox_integer(tmpMeta19);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp22 = mmc_unbox_integer(tmpMeta21);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp24 = mmc_unbox_integer(tmpMeta23);
_b = tmp20;
_len = tmp22;
_just = tmp24;
_str = (_b?_OMC_LIT76:_OMC_LIT77);
_str = omc_ExpressionSimplify_cevalBuiltinStringFormat(threadData, _str, stringLength(_str), _len, _just);
tmpMeta25 = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _str);
tmpMeta1 = tmpMeta25;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_integer tmp28;
modelica_metatype tmpMeta29;
modelica_integer tmp30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp28 = mmc_unbox_integer(tmpMeta27);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp30 = mmc_unbox_integer(tmpMeta29);
_name = tmpMeta26;
_len = tmp28;
_just = tmp30;
_str = omc_AbsynUtil_pathLastIdent(threadData, _name);
_str = omc_ExpressionSimplify_cevalBuiltinStringFormat(threadData, _str, stringLength(_str), _len, _just);
tmpMeta31 = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _str);
tmpMeta1 = tmpMeta31;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_evalCatGetFlatArray(threadData_t *threadData, modelica_metatype _e, modelica_integer _dim, modelica_fnptr _getArrayContents, modelica_fnptr _toString, modelica_metatype *out_outDims)
{
modelica_metatype _outExps = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _outDims = NULL;
modelica_metatype tmpMeta2;
modelica_metatype _arr = NULL;
modelica_metatype _dims = NULL;
modelica_integer _i;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_outExps = tmpMeta1;
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_outDims = tmpMeta2;
if((_dim == ((modelica_integer) 1)))
{
_outExps = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 1)))) (threadData, _e);
tmpMeta3 = mmc_mk_cons(mmc_mk_integer(listLength(_outExps)), MMC_REFSTRUCTLIT(mmc_nil));
_outDims = tmpMeta3;
goto _return;
}
_i = ((modelica_integer) 0);
{
modelica_metatype _exp;
for (tmpMeta4 = listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 1)))) (threadData, _e)); !listEmpty(tmpMeta4); tmpMeta4=MMC_CDR(tmpMeta4))
{
_exp = MMC_CAR(tmpMeta4);
_arr = omc_ExpressionSimplify_evalCatGetFlatArray(threadData, _exp, ((modelica_integer) -1) + _dim, ((modelica_fnptr) _getArrayContents), ((modelica_fnptr) _toString) ,&_dims);
if(listEmpty(_outDims))
{
_outDims = _dims;
}
else
{
if((!valueEq(_dims, _outDims)))
{
tmpMeta5 = stringAppend(_OMC_LIT78,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 1)))) (threadData, _e));
omc_Error_assertion(threadData, 0, tmpMeta5, _OMC_LIT80);
}
}
_outExps = listAppend(_arr, _outExps);
_i = ((modelica_integer) 1) + _i;
}
}
tmpMeta7 = mmc_mk_cons(mmc_mk_integer(_i), _outDims);
_outDims = tmpMeta7;
_return: OMC_LABEL_UNUSED
if (out_outDims) { *out_outDims = _outDims; }
return _outExps;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_evalCatGetFlatArray(threadData_t *threadData, modelica_metatype _e, modelica_metatype _dim, modelica_fnptr _getArrayContents, modelica_fnptr _toString, modelica_metatype *out_outDims)
{
modelica_integer tmp1;
modelica_metatype _outExps = NULL;
modelica_metatype tmpMeta2;
tmp1 = mmc_unbox_integer(_dim);
_outExps = omc_ExpressionSimplify_evalCatGetFlatArray(threadData, _e, tmp1, _getArrayContents, _toString, out_outDims);
return _outExps;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_evalCat(threadData_t *threadData, modelica_integer _dim, modelica_metatype _exps, modelica_fnptr _getArrayContents, modelica_fnptr _toString, modelica_metatype *out_outDims)
{
modelica_metatype _outExps = NULL;
modelica_metatype _outDims = NULL;
modelica_metatype _arr = NULL;
modelica_metatype _arrs = NULL;
modelica_metatype tmpMeta1;
modelica_metatype _dims = NULL;
modelica_metatype _firstDims = NULL;
modelica_metatype tmpMeta2;
modelica_metatype _lastDims = NULL;
modelica_metatype _reverseDims = NULL;
modelica_metatype _dimsLst = NULL;
modelica_metatype tmpMeta3;
modelica_integer _j;
modelica_integer _k;
modelica_integer _l;
modelica_integer _thisDim;
modelica_integer _lastDim;
modelica_metatype _expArr = NULL;
modelica_boolean tmp4;
modelica_boolean tmp5;
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_integer tmp14;
modelica_integer tmp16;
modelica_string tmp18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_integer tmp31;
modelica_integer tmp32;
modelica_integer tmp33;
modelica_metatype tmpMeta34;
modelica_integer tmp38;
modelica_metatype tmpMeta40;
modelica_integer tmp41;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_integer tmp47;
modelica_metatype tmpMeta48;
modelica_integer tmp49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_arrs = tmpMeta1;
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_firstDims = tmpMeta2;
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
_dimsLst = tmpMeta3;
tmp4 = (_dim >= ((modelica_integer) 1));
if (1 != tmp4) MMC_THROW_INTERNAL();
tmp5 = listEmpty(_exps);
if (0 != tmp5) MMC_THROW_INTERNAL();
if((((modelica_integer) 1) == _dim))
{
{
modelica_metatype __omcQ_24tmpVar27;
modelica_metatype tmpMeta7;
modelica_metatype __omcQ_24tmpVar26;
modelica_integer tmp8;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = listReverse(_exps);
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar27 = tmpMeta7;
while(1) {
tmp8 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp8--;
}
if (tmp8 == 0) {
__omcQ_24tmpVar26 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 1)))) (threadData, _e);
__omcQ_24tmpVar27 = listAppend(__omcQ_24tmpVar26, __omcQ_24tmpVar27);
} else if (tmp8 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmpMeta6 = __omcQ_24tmpVar27;
}
_outExps = tmpMeta6;
tmpMeta9 = mmc_mk_cons(mmc_mk_integer(listLength(_outExps)), MMC_REFSTRUCTLIT(mmc_nil));
_outDims = tmpMeta9;
goto _return;
}
{
modelica_metatype _e;
for (tmpMeta10 = listReverse(_exps); !listEmpty(tmpMeta10); tmpMeta10=MMC_CDR(tmpMeta10))
{
_e = MMC_CAR(tmpMeta10);
_arr = omc_ExpressionSimplify_evalCatGetFlatArray(threadData, _e, _dim, ((modelica_fnptr) _getArrayContents), ((modelica_fnptr) _toString) ,&_dims);
tmpMeta11 = mmc_mk_cons(_arr, _arrs);
_arrs = tmpMeta11;
tmpMeta12 = mmc_mk_cons(_dims, _dimsLst);
_dimsLst = tmpMeta12;
}
}
tmp31 = ((modelica_integer) 1); tmp32 = 1; tmp33 = ((modelica_integer) -1) + _dim;
if(!(((tmp32 > 0) && (tmp31 > tmp33)) || ((tmp32 < 0) && (tmp31 < tmp33))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp31, tmp33); _i += tmp32)
{
{
modelica_integer __omcQ_24tmpVar29;
modelica_integer __omcQ_24tmpVar28;
modelica_integer tmp15;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _dimsLst;
__omcQ_24tmpVar29 = ((modelica_integer) 4611686018427387903);
while(1) {
tmp15 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp15--;
}
if (tmp15 == 0) {
__omcQ_24tmpVar28 = mmc_unbox_integer(listHead(_d));
__omcQ_24tmpVar29 = modelica_integer_min((modelica_integer)(__omcQ_24tmpVar28),(modelica_integer)(__omcQ_24tmpVar29));
} else if (tmp15 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp14 = __omcQ_24tmpVar29;
}
_j = tmp14;
{
modelica_integer __omcQ_24tmpVar31;
modelica_integer __omcQ_24tmpVar30;
modelica_integer tmp17;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _dimsLst;
__omcQ_24tmpVar31 = ((modelica_integer) -4611686018427387903);
while(1) {
tmp17 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp17--;
}
if (tmp17 == 0) {
__omcQ_24tmpVar30 = mmc_unbox_integer(listHead(_d));
__omcQ_24tmpVar31 = modelica_integer_max((modelica_integer)(__omcQ_24tmpVar30),(modelica_integer)(__omcQ_24tmpVar31));
} else if (tmp17 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp16 = __omcQ_24tmpVar31;
}
if((_j != tmp16))
{
tmp18 = modelica_integer_to_modelica_string(_i, ((modelica_integer) 0), 1);
tmpMeta19 = stringAppend(_OMC_LIT81,tmp18);
tmpMeta20 = stringAppend(tmpMeta19,_OMC_LIT75);
{
modelica_metatype __omcQ_24tmpVar33;
modelica_metatype* tmp22;
modelica_metatype tmpMeta23;
modelica_string __omcQ_24tmpVar32;
modelica_integer tmp24;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _exps;
tmpMeta23 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar33 = tmpMeta23;
tmp22 = &__omcQ_24tmpVar33;
while(1) {
tmp24 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp24--;
}
if (tmp24 == 0) {
__omcQ_24tmpVar32 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 1)))) (threadData, _e);
*tmp22 = mmc_mk_cons(__omcQ_24tmpVar32,0);
tmp22 = &MMC_CDR(*tmp22);
} else if (tmp24 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp22 = mmc_mk_nil();
tmpMeta21 = __omcQ_24tmpVar33;
}
tmpMeta25 = stringAppend(tmpMeta20,stringDelimitList(tmpMeta21, _OMC_LIT82));
omc_Error_assertion(threadData, 0, tmpMeta25, _OMC_LIT83);
}
tmpMeta26 = mmc_mk_cons(mmc_mk_integer(_j), _firstDims);
_firstDims = tmpMeta26;
{
modelica_metatype __omcQ_24tmpVar35;
modelica_metatype* tmp28;
modelica_metatype tmpMeta29;
modelica_metatype __omcQ_24tmpVar34;
modelica_integer tmp30;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _dimsLst;
tmpMeta29 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar35 = tmpMeta29;
tmp28 = &__omcQ_24tmpVar35;
while(1) {
tmp30 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp30--;
}
if (tmp30 == 0) {
__omcQ_24tmpVar34 = listRest(_d);
*tmp28 = mmc_mk_cons(__omcQ_24tmpVar34,0);
tmp28 = &MMC_CDR(*tmp28);
} else if (tmp30 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp28 = mmc_mk_nil();
tmpMeta27 = __omcQ_24tmpVar35;
}
_dimsLst = tmpMeta27;
}
}
_reverseDims = _firstDims;
_firstDims = listReverse(_firstDims);
{
modelica_metatype __omcQ_24tmpVar37;
modelica_metatype* tmp35;
modelica_metatype tmpMeta36;
modelica_metatype __omcQ_24tmpVar36;
modelica_integer tmp37;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _dimsLst;
tmpMeta36 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar37 = tmpMeta36;
tmp35 = &__omcQ_24tmpVar37;
while(1) {
tmp37 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp37--;
}
if (tmp37 == 0) {
__omcQ_24tmpVar36 = listHead(_d);
*tmp35 = mmc_mk_cons(__omcQ_24tmpVar36,0);
tmp35 = &MMC_CDR(*tmp35);
} else if (tmp37 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp35 = mmc_mk_nil();
tmpMeta34 = __omcQ_24tmpVar37;
}
_lastDims = tmpMeta34;
{
modelica_integer __omcQ_24tmpVar39;
modelica_integer __omcQ_24tmpVar38;
modelica_integer tmp39;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _lastDims;
__omcQ_24tmpVar39 = ((modelica_integer) 0);
while(1) {
tmp39 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp39--;
}
if (tmp39 == 0) {
__omcQ_24tmpVar38 = mmc_unbox_integer(_d);
__omcQ_24tmpVar39 = __omcQ_24tmpVar39 + __omcQ_24tmpVar38;
} else if (tmp39 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp38 = __omcQ_24tmpVar39;
}
_lastDim = tmp38;
tmpMeta40 = mmc_mk_cons(mmc_mk_integer(_lastDim), _reverseDims);
_reverseDims = tmpMeta40;
{
modelica_integer __omcQ_24tmpVar41;
modelica_integer __omcQ_24tmpVar40;
modelica_integer tmp42;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _firstDims;
__omcQ_24tmpVar41 = ((modelica_integer) 1);
while(1) {
tmp42 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp42--;
}
if (tmp42 == 0) {
__omcQ_24tmpVar40 = mmc_unbox_integer(_d);
__omcQ_24tmpVar41 = (__omcQ_24tmpVar41) * (__omcQ_24tmpVar40);
} else if (tmp42 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp41 = __omcQ_24tmpVar41;
}
_expArr = arrayCreate((_lastDim) * (tmp41), listHead(listHead(_arrs)));
_k = ((modelica_integer) 1);
{
modelica_metatype _exps;
for (tmpMeta43 = _arrs; !listEmpty(tmpMeta43); tmpMeta43=MMC_CDR(tmpMeta43))
{
_exps = MMC_CAR(tmpMeta43);
tmpMeta44 = _lastDims;
if (listEmpty(tmpMeta44)) MMC_THROW_INTERNAL();
tmpMeta45 = MMC_CAR(tmpMeta44);
tmpMeta46 = MMC_CDR(tmpMeta44);
tmp47 = mmc_unbox_integer(tmpMeta45);
_thisDim = tmp47;
_lastDims = tmpMeta46;
_l = ((modelica_integer) 0);
{
modelica_metatype _e;
for (tmpMeta48 = _exps; !listEmpty(tmpMeta48); tmpMeta48=MMC_CDR(tmpMeta48))
{
_e = MMC_CAR(tmpMeta48);
tmp49 = _thisDim;
if (tmp49 == 0) {MMC_THROW_INTERNAL();}
arrayUpdate(_expArr, _k + modelica_integer_mod(_l, _thisDim) + (_lastDim) * (ldiv(_l,tmp49).quot), _e);
_l = ((modelica_integer) 1) + _l;
}
}
_k = _k + _thisDim;
}
}
_outExps = arrayList(_expArr);
_outDims = listReverse(_reverseDims);
_return: OMC_LABEL_UNUSED
if (out_outDims) { *out_outDims = _outDims; }
return _outExps;
}
modelica_metatype boxptr_ExpressionSimplify_evalCat(threadData_t *threadData, modelica_metatype _dim, modelica_metatype _exps, modelica_fnptr _getArrayContents, modelica_fnptr _toString, modelica_metatype *out_outDims)
{
modelica_integer tmp1;
modelica_metatype _outExps = NULL;
tmp1 = mmc_unbox_integer(_dim);
_outExps = omc_ExpressionSimplify_evalCat(threadData, tmp1, _exps, _getArrayContents, _toString, out_outDims);
return _outExps;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCat2(threadData_t *threadData, modelica_integer _dim, modelica_metatype _ies, modelica_metatype _acc, modelica_boolean _changed)
{
modelica_metatype _oes = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_integer tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_boolean tmp4_3;
tmp4_1 = _dim;
tmp4_2 = _ies;
tmp4_3 = _changed;
{
modelica_metatype _es1 = NULL;
modelica_metatype _es2 = NULL;
modelica_metatype _esn = NULL;
modelica_metatype _es = NULL;
modelica_metatype _e = NULL;
modelica_metatype _ndim = NULL;
modelica_metatype _dim1 = NULL;
modelica_metatype _dim2 = NULL;
modelica_metatype _dim11 = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _etp = NULL;
modelica_integer _i;
modelica_metatype _ms1 = NULL;
modelica_metatype _ms2 = NULL;
modelica_metatype _mss = NULL;
modelica_boolean _sc;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (1 != tmp4_3) goto tmp3_end;
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmp4 += 3;
tmpMeta1 = listReverse(_acc);
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
modelica_integer tmp14;
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
if (1 != tmp4_1) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_2);
tmpMeta7 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,16,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,6,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 3));
if (listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmpMeta10);
tmpMeta12 = MMC_CDR(tmpMeta10);
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmp14 = mmc_unbox_integer(tmpMeta13);
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta16 = MMC_CAR(tmpMeta7);
tmpMeta17 = MMC_CDR(tmpMeta7);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,16,3) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,6,2) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 3));
if (listEmpty(tmpMeta19)) goto tmp3_end;
tmpMeta20 = MMC_CAR(tmpMeta19);
tmpMeta21 = MMC_CDR(tmpMeta19);
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 4));
_etp = tmpMeta9;
_dim1 = tmpMeta11;
_dims = tmpMeta12;
_sc = tmp14;
_es1 = tmpMeta15;
_dim2 = tmpMeta20;
_es2 = tmpMeta22;
_es = tmpMeta17;
tmp4 += 1;
_esn = listAppend(_es1, _es2);
_ndim = omc_Expression_addDimensions(threadData, _dim1, _dim2);
tmpMeta23 = mmc_mk_cons(_ndim, _dims);
tmpMeta24 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _etp, tmpMeta23);
_etp = tmpMeta24;
tmpMeta25 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _etp, mmc_mk_boolean(_sc), _esn);
_e = tmpMeta25;
tmpMeta26 = mmc_mk_cons(_e, _es);
tmpMeta1 = omc_ExpressionSimplify_simplifyCat2(threadData, _dim, tmpMeta26, _acc, 1);
goto tmp3_done;
}
case 2: {
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
modelica_integer tmp37;
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
if (2 != tmp4_1) goto tmp3_end;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta27 = MMC_CAR(tmp4_2);
tmpMeta28 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,17,3) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,6,2) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 2));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 3));
if (listEmpty(tmpMeta31)) goto tmp3_end;
tmpMeta32 = MMC_CAR(tmpMeta31);
tmpMeta33 = MMC_CDR(tmpMeta31);
if (listEmpty(tmpMeta33)) goto tmp3_end;
tmpMeta34 = MMC_CAR(tmpMeta33);
tmpMeta35 = MMC_CDR(tmpMeta33);
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 3));
tmp37 = mmc_unbox_integer(tmpMeta36);
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 4));
if (listEmpty(tmpMeta28)) goto tmp3_end;
tmpMeta39 = MMC_CAR(tmpMeta28);
tmpMeta40 = MMC_CDR(tmpMeta28);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,17,3) == 0) goto tmp3_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta41,6,2) == 0) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 3));
if (listEmpty(tmpMeta42)) goto tmp3_end;
tmpMeta43 = MMC_CAR(tmpMeta42);
tmpMeta44 = MMC_CDR(tmpMeta42);
if (listEmpty(tmpMeta44)) goto tmp3_end;
tmpMeta45 = MMC_CAR(tmpMeta44);
tmpMeta46 = MMC_CDR(tmpMeta44);
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 4));
_etp = tmpMeta30;
_dim11 = tmpMeta32;
_dim1 = tmpMeta34;
_dims = tmpMeta35;
_i = tmp37;
_ms1 = tmpMeta38;
_dim2 = tmpMeta45;
_ms2 = tmpMeta47;
_es = tmpMeta40;
_mss = omc_List_threadMap(threadData, _ms1, _ms2, boxvar_listAppend);
_ndim = omc_Expression_addDimensions(threadData, _dim1, _dim2);
tmpMeta49 = mmc_mk_cons(_ndim, _dims);
tmpMeta48 = mmc_mk_cons(_dim11, tmpMeta49);
tmpMeta50 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _etp, tmpMeta48);
_etp = tmpMeta50;
tmpMeta51 = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _etp, mmc_mk_integer(_i), _mss);
_e = tmpMeta51;
tmpMeta52 = mmc_mk_cons(_e, _es);
tmpMeta1 = omc_ExpressionSimplify_simplifyCat2(threadData, _dim, tmpMeta52, _acc, 1);
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta53;
modelica_metatype tmpMeta54;
modelica_metatype tmpMeta55;
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta53 = MMC_CAR(tmp4_2);
tmpMeta54 = MMC_CDR(tmp4_2);
_e = tmpMeta53;
_es = tmpMeta54;
tmpMeta55 = mmc_mk_cons(_e, _acc);
tmpMeta1 = omc_ExpressionSimplify_simplifyCat2(threadData, _dim, _es, tmpMeta55, _changed);
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
_oes = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _oes;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyCat2(threadData_t *threadData, modelica_metatype _dim, modelica_metatype _ies, modelica_metatype _acc, modelica_metatype _changed)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _oes = NULL;
tmp1 = mmc_unbox_integer(_dim);
tmp2 = mmc_unbox_integer(_changed);
_oes = omc_ExpressionSimplify_simplifyCat2(threadData, tmp1, _ies, _acc, tmp2);
return _oes;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCatArg(threadData_t *threadData, modelica_metatype _arg)
{
modelica_metatype _outArg = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _arg;
{
modelica_metatype _dim = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta1 = omc_Expression_matrixToArray(threadData, _arg);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
if (listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_CAR(tmpMeta7);
tmpMeta9 = MMC_CDR(tmpMeta7);
if (!listEmpty(tmpMeta9)) goto tmp3_end;
_dim = tmpMeta8;
if (!omc_Expression_dimensionKnown(threadData, _dim)) goto tmp3_end;
tmpMeta10 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 3))), mmc_mk_boolean(1), omc_Expression_expandExpression(threadData, _arg, 0));
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 2: {
tmpMeta1 = _arg;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outArg = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outArg;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCat(threadData_t *threadData, modelica_integer _inDim, modelica_metatype _inExpList)
{
modelica_metatype _outExpList = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_integer tmp4_1;
tmp4_1 = _inDim;
{
modelica_metatype _expl = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (1 != tmp4_1) goto tmp3_end;
_expl = omc_List_map(threadData, _inExpList, boxvar_ExpressionSimplify_simplifyCatArg);
tmpMeta6 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ExpressionSimplify_simplifyCat2(threadData, _inDim, _expl, tmpMeta6, 0);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta7;
tmpMeta7 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ExpressionSimplify_simplifyCat2(threadData, _inDim, _inExpList, tmpMeta7, 0);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outExpList = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExpList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyCat(threadData_t *threadData, modelica_metatype _inDim, modelica_metatype _inExpList)
{
modelica_integer tmp1;
modelica_metatype _outExpList = NULL;
tmp1 = mmc_unbox_integer(_inDim);
_outExpList = omc_ExpressionSimplify_simplifyCat(threadData, tmp1, _inExpList);
return _outExpList;
}
PROTECTED_FUNCTION_STATIC void omc_ExpressionSimplify_simplifySymmetric(threadData_t *threadData, modelica_metatype _marr, modelica_integer _i1, modelica_integer _i2)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_integer tmp3_1;modelica_integer tmp3_2;
tmp3_1 = _i1;
tmp3_2 = _i2;
{
modelica_metatype _v1 = NULL;
modelica_metatype _v2 = NULL;
modelica_metatype _exp = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (0 != tmp3_1) goto tmp2_end;
if (1 != tmp3_2) goto tmp2_end;
goto tmp2_done;
}
case 1: {
modelica_integer tmp5;
_v1 = arrayGet(_marr, _i1);
_v2 = arrayGet(_marr, _i2);
_exp = arrayGet(_v1, _i2);
arrayUpdate(_v2, _i1, _exp);
tmp5 = ((_i1 == ((modelica_integer) 1))?((modelica_integer) -2) + _i2:((modelica_integer) -1) + _i1);
_i2 = ((_i1 == ((modelica_integer) 1))?((modelica_integer) -1) + _i2:_i2);
_i1 = tmp5;
goto _tailrecursive;
;
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
PROTECTED_FUNCTION_STATIC void boxptr_ExpressionSimplify_simplifySymmetric(threadData_t *threadData, modelica_metatype _marr, modelica_metatype _i1, modelica_metatype _i2)
{
modelica_integer tmp1;
modelica_integer tmp2;
tmp1 = mmc_unbox_integer(_i1);
tmp2 = mmc_unbox_integer(_i2);
omc_ExpressionSimplify_simplifySymmetric(threadData, _marr, tmp1, tmp2);
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_makeNestedReduction(threadData_t *threadData, modelica_metatype _inExp, modelica_string _inName, modelica_metatype _inType, modelica_metatype _inCall)
{
modelica_metatype _outCall = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_cons(_inExp, mmc_mk_cons(_inCall, MMC_REFSTRUCTLIT(mmc_nil)));
_outCall = omc_Expression_makePureBuiltinCall(threadData, _inName, tmpMeta1, _inType);
_return: OMC_LABEL_UNUSED
return _outCall;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyScalar(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _tp)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_CAR(tmpMeta6);
tmpMeta8 = MMC_CDR(tmpMeta6);
if (!listEmpty(tmpMeta8)) goto tmp3_end;
_exp = tmpMeta7;
tmpMeta9 = mmc_mk_cons(_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT84, tmpMeta9, _tp);
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmpMeta10);
tmpMeta12 = MMC_CDR(tmpMeta10);
if (listEmpty(tmpMeta11)) goto tmp3_end;
tmpMeta13 = MMC_CAR(tmpMeta11);
tmpMeta14 = MMC_CDR(tmpMeta11);
if (!listEmpty(tmpMeta14)) goto tmp3_end;
if (!listEmpty(tmpMeta12)) goto tmp3_end;
_exp = tmpMeta13;
tmpMeta15 = mmc_mk_cons(_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT84, tmpMeta15, _tp);
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!optionNone(tmpMeta17)) goto tmp3_end;
_exp = tmpMeta16;
omc_Types_flattenArrayType(threadData, omc_Expression_typeof(threadData, _inExp), &tmpMeta18);
if (listEmpty(tmpMeta18)) goto goto_2;
tmpMeta19 = MMC_CAR(tmpMeta18);
tmpMeta20 = MMC_CDR(tmpMeta18);
if (!listEmpty(tmpMeta20)) goto goto_2;
tmpMeta21 = mmc_mk_box3(27, &DAE_Exp_SIZE__desc, _exp, _OMC_LIT86);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta22;
omc_Types_flattenArrayType(threadData, omc_Expression_typeof(threadData, _inExp), &tmpMeta22);
if (!listEmpty(tmpMeta22)) goto goto_2;
tmpMeta1 = _inExp;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBuiltinCalls(threadData_t *threadData, modelica_metatype _exp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
modelica_metatype _mexpl = NULL;
modelica_metatype _es = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _e = NULL;
modelica_metatype _len_exp = NULL;
modelica_metatype _just_exp = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _e4 = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _tp1 = NULL;
modelica_metatype _tp2 = NULL;
modelica_metatype _op = NULL;
modelica_metatype _v1 = NULL;
modelica_metatype _v2 = NULL;
modelica_boolean _scalar;
modelica_boolean _sc;
modelica_metatype _valueLst = NULL;
modelica_integer _i;
modelica_integer _i1;
modelica_integer _i2;
modelica_integer _dim;
modelica_real _r1;
modelica_metatype _marr = NULL;
modelica_string _name = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_metatype _dims = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 57; tmp4++) {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,16,3) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
_name = tmpMeta7;
_e = tmpMeta9;
_tp = tmpMeta12;
if (!((stringEqual(_name, _OMC_LIT8)) || (stringEqual(_name, _OMC_LIT7)))) goto tmp3_end;
_expl = omc_Expression_flattenArrayExpToList(threadData, _e);
_e1 = omc_Expression_makeScalarArray(threadData, _expl, _tp);
tmp13 = omc_Expression_expEqual(threadData, _e, _e1);
if (0 != tmp13) goto goto_2;
tmpMeta14 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _name, tmpMeta14, _tp);
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta15,1,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmpMeta17);
tmpMeta19 = MMC_CDR(tmpMeta17);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta18,16,3) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta18), 4));
if (listEmpty(tmpMeta20)) goto tmp3_end;
tmpMeta21 = MMC_CAR(tmpMeta20);
tmpMeta22 = MMC_CDR(tmpMeta20);
if (!listEmpty(tmpMeta22)) goto tmp3_end;
if (!listEmpty(tmpMeta19)) goto tmp3_end;
_name = tmpMeta16;
_expl = tmpMeta20;
_e = tmpMeta21;
if (!((stringEqual(_name, _OMC_LIT8)) || (stringEqual(_name, _OMC_LIT7)))) goto tmp3_end;
if(omc_Expression_isArrayType(threadData, omc_Expression_typeof(threadData, _e)))
{
tmpMeta23 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta23), MMC_UNTAGPTR(_exp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta23))[3] = _expl;
_exp = tmpMeta23;
_e = _exp;
}
tmpMeta1 = _e;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta24,1,1) == 0) goto tmp3_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta24), 2));
if (3 != MMC_STRLEN(tmpMeta25) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta25)) != 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta26)) goto tmp3_end;
tmpMeta27 = MMC_CAR(tmpMeta26);
tmpMeta28 = MMC_CDR(tmpMeta26);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,16,3) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 4));
if (listEmpty(tmpMeta29)) goto tmp3_end;
tmpMeta30 = MMC_CAR(tmpMeta29);
tmpMeta31 = MMC_CDR(tmpMeta29);
if (!listEmpty(tmpMeta31)) goto tmp3_end;
if (!listEmpty(tmpMeta28)) goto tmp3_end;
_e = tmpMeta30;
tmpMeta1 = _e;
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
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_boolean tmp44;
modelica_metatype tmpMeta45;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta32,1,1) == 0) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 2));
if (3 != MMC_STRLEN(tmpMeta33) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta33)) != 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta34)) goto tmp3_end;
tmpMeta35 = MMC_CAR(tmpMeta34);
tmpMeta36 = MMC_CDR(tmpMeta34);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta35,16,3) == 0) goto tmp3_end;
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta35), 4));
if (!listEmpty(tmpMeta36)) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 2));
_es = tmpMeta37;
_tp = tmpMeta39;
tmp4 += 2;
_i1 = listLength(_es);
tmpMeta40 = MMC_REFSTRUCTLIT(mmc_nil);
_es = omc_List_union(threadData, _es, tmpMeta40);
_i2 = listLength(_es);
if((_i1 == _i2))
{
tmpMeta41 = omc_List_fold(threadData, _es, boxvar_ExpressionSimplify_maxElement, mmc_mk_none());
if (optionNone(tmpMeta41)) goto goto_2;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 1));
_e = tmpMeta42;
_es = omc_List_select(threadData, _es, boxvar_ExpressionSimplify_removeMinMaxFoldableValues);
tmpMeta43 = mmc_mk_cons(_e, _es);
_es = tmpMeta43;
_i2 = listLength(_es);
tmp44 = (_i2 < _i1);
if (1 != tmp44) goto goto_2;
_e = omc_Expression_makeScalarArray(threadData, _es, _tp);
}
else
{
_e = omc_Expression_makeScalarArray(threadData, _es, _tp);
}
tmpMeta45 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT8, tmpMeta45, _tp);
goto tmp3_done;
}
case 4: {
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
modelica_boolean tmp58;
modelica_metatype tmpMeta59;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta46,1,1) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 2));
if (3 != MMC_STRLEN(tmpMeta47) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmpMeta47)) != 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta48)) goto tmp3_end;
tmpMeta49 = MMC_CAR(tmpMeta48);
tmpMeta50 = MMC_CDR(tmpMeta48);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta49,16,3) == 0) goto tmp3_end;
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 4));
if (!listEmpty(tmpMeta50)) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta52), 2));
_es = tmpMeta51;
_tp = tmpMeta53;
_i1 = listLength(_es);
tmpMeta54 = MMC_REFSTRUCTLIT(mmc_nil);
_es = omc_List_union(threadData, _es, tmpMeta54);
_i2 = listLength(_es);
if((_i1 == _i2))
{
tmpMeta55 = omc_List_fold(threadData, _es, boxvar_ExpressionSimplify_minElement, mmc_mk_none());
if (optionNone(tmpMeta55)) goto goto_2;
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta55), 1));
_e = tmpMeta56;
_es = omc_List_select(threadData, _es, boxvar_ExpressionSimplify_removeMinMaxFoldableValues);
tmpMeta57 = mmc_mk_cons(_e, _es);
_es = tmpMeta57;
_i2 = listLength(_es);
tmp58 = (_i2 < _i1);
if (1 != tmp58) goto goto_2;
_e = omc_Expression_makeScalarArray(threadData, _es, _tp);
}
else
{
_e = omc_Expression_makeScalarArray(threadData, _es, _tp);
}
tmpMeta59 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT7, tmpMeta59, _tp);
goto tmp3_done;
}
case 5: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta60,1,1) == 0) goto tmp3_end;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta60), 2));
if (3 != MMC_STRLEN(tmpMeta61) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmpMeta61)) != 0) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta62)) goto tmp3_end;
tmpMeta63 = MMC_CAR(tmpMeta62);
tmpMeta64 = MMC_CDR(tmpMeta62);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta63,16,3) == 0) goto tmp3_end;
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta63), 4));
if (listEmpty(tmpMeta65)) goto tmp3_end;
tmpMeta66 = MMC_CAR(tmpMeta65);
tmpMeta67 = MMC_CDR(tmpMeta65);
if (listEmpty(tmpMeta67)) goto tmp3_end;
tmpMeta68 = MMC_CAR(tmpMeta67);
tmpMeta69 = MMC_CDR(tmpMeta67);
if (!listEmpty(tmpMeta69)) goto tmp3_end;
if (!listEmpty(tmpMeta64)) goto tmp3_end;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 2));
_e1 = tmpMeta66;
_e2 = tmpMeta68;
_tp = tmpMeta71;
tmp4 += 3;
tmpMeta72 = mmc_mk_cons(_e1, mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT7, tmpMeta72, _tp);
goto tmp3_done;
}
case 6: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta73,1,1) == 0) goto tmp3_end;
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta73), 2));
if (3 != MMC_STRLEN(tmpMeta74) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta74)) != 0) goto tmp3_end;
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta75)) goto tmp3_end;
tmpMeta76 = MMC_CAR(tmpMeta75);
tmpMeta77 = MMC_CDR(tmpMeta75);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta76,16,3) == 0) goto tmp3_end;
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta76), 4));
if (listEmpty(tmpMeta78)) goto tmp3_end;
tmpMeta79 = MMC_CAR(tmpMeta78);
tmpMeta80 = MMC_CDR(tmpMeta78);
if (listEmpty(tmpMeta80)) goto tmp3_end;
tmpMeta81 = MMC_CAR(tmpMeta80);
tmpMeta82 = MMC_CDR(tmpMeta80);
if (!listEmpty(tmpMeta82)) goto tmp3_end;
if (!listEmpty(tmpMeta77)) goto tmp3_end;
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta83), 2));
_e1 = tmpMeta79;
_e2 = tmpMeta81;
_tp = tmpMeta84;
tmp4 += 3;
tmpMeta85 = mmc_mk_cons(_e1, mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT8, tmpMeta85, _tp);
goto tmp3_done;
}
case 7: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta86 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta86,1,1) == 0) goto tmp3_end;
tmpMeta87 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta86), 2));
if (3 != MMC_STRLEN(tmpMeta87) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmpMeta87)) != 0) goto tmp3_end;
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta88)) goto tmp3_end;
tmpMeta89 = MMC_CAR(tmpMeta88);
tmpMeta90 = MMC_CDR(tmpMeta88);
if (listEmpty(tmpMeta90)) goto tmp3_end;
tmpMeta91 = MMC_CAR(tmpMeta90);
tmpMeta92 = MMC_CDR(tmpMeta90);
if (!listEmpty(tmpMeta92)) goto tmp3_end;
tmpMeta93 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta93), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta94,3,1) == 0) goto tmp3_end;
_e1 = tmpMeta89;
_e2 = tmpMeta91;
tmp4 += 49;
tmpMeta95 = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _e1, _OMC_LIT88, _e2);
tmpMeta1 = tmpMeta95;
goto tmp3_done;
}
case 8: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta96 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta96,1,1) == 0) goto tmp3_end;
tmpMeta97 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta96), 2));
if (3 != MMC_STRLEN(tmpMeta97) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta97)) != 0) goto tmp3_end;
tmpMeta98 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta98)) goto tmp3_end;
tmpMeta99 = MMC_CAR(tmpMeta98);
tmpMeta100 = MMC_CDR(tmpMeta98);
if (listEmpty(tmpMeta100)) goto tmp3_end;
tmpMeta101 = MMC_CAR(tmpMeta100);
tmpMeta102 = MMC_CDR(tmpMeta100);
if (!listEmpty(tmpMeta102)) goto tmp3_end;
tmpMeta103 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta104 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta103), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta104,3,1) == 0) goto tmp3_end;
_e1 = tmpMeta99;
_e2 = tmpMeta101;
tmp4 += 48;
tmpMeta105 = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _e1, _OMC_LIT89, _e2);
tmpMeta1 = tmpMeta105;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta106;
modelica_metatype tmpMeta107;
modelica_metatype tmpMeta108;
modelica_metatype tmpMeta109;
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
modelica_metatype tmpMeta113;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta106 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta106,1,1) == 0) goto tmp3_end;
tmpMeta107 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta106), 2));
if (3 != MMC_STRLEN(tmpMeta107) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmpMeta107)) != 0) goto tmp3_end;
tmpMeta108 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta108)) goto tmp3_end;
tmpMeta109 = MMC_CAR(tmpMeta108);
tmpMeta110 = MMC_CDR(tmpMeta108);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta109,16,3) == 0) goto tmp3_end;
tmpMeta111 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta109), 4));
if (!listEmpty(tmpMeta110)) goto tmp3_end;
tmpMeta112 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta113 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta112), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta113,3,1) == 0) goto tmp3_end;
_expl = tmpMeta111;
tmp4 += 1;
tmpMeta1 = omc_Expression_makeLBinary(threadData, _expl, _OMC_LIT88);
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta114;
modelica_metatype tmpMeta115;
modelica_metatype tmpMeta116;
modelica_metatype tmpMeta117;
modelica_metatype tmpMeta118;
modelica_metatype tmpMeta119;
modelica_metatype tmpMeta120;
modelica_metatype tmpMeta121;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta114 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta114,1,1) == 0) goto tmp3_end;
tmpMeta115 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta114), 2));
if (3 != MMC_STRLEN(tmpMeta115) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta115)) != 0) goto tmp3_end;
tmpMeta116 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta116)) goto tmp3_end;
tmpMeta117 = MMC_CAR(tmpMeta116);
tmpMeta118 = MMC_CDR(tmpMeta116);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta117,16,3) == 0) goto tmp3_end;
tmpMeta119 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta117), 4));
if (!listEmpty(tmpMeta118)) goto tmp3_end;
tmpMeta120 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta121 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta120), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta121,3,1) == 0) goto tmp3_end;
_expl = tmpMeta119;
tmpMeta1 = omc_Expression_makeLBinary(threadData, _expl, _OMC_LIT89);
goto tmp3_done;
}
case 11: {
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
modelica_boolean tmp134;
modelica_boolean tmp135;
modelica_metatype tmpMeta136;
modelica_metatype tmpMeta137;
modelica_metatype tmpMeta138;
modelica_metatype tmpMeta139;
modelica_metatype tmpMeta140;
modelica_metatype tmpMeta141;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta122 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta122,1,1) == 0) goto tmp3_end;
tmpMeta123 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta122), 2));
tmpMeta124 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta124)) goto tmp3_end;
tmpMeta125 = MMC_CAR(tmpMeta124);
tmpMeta126 = MMC_CDR(tmpMeta124);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta125,16,3) == 0) goto tmp3_end;
tmpMeta127 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta125), 4));
if (listEmpty(tmpMeta127)) goto tmp3_end;
tmpMeta128 = MMC_CAR(tmpMeta127);
tmpMeta129 = MMC_CDR(tmpMeta127);
if (listEmpty(tmpMeta129)) goto tmp3_end;
tmpMeta130 = MMC_CAR(tmpMeta129);
tmpMeta131 = MMC_CDR(tmpMeta129);
if (!listEmpty(tmpMeta126)) goto tmp3_end;
tmpMeta132 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta133 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta132), 2));
_name = tmpMeta123;
_expl = tmpMeta127;
_tp = tmpMeta133;
tmp134 = omc_Config_scalarizeMinMax(threadData);
if (1 != tmp134) goto goto_2;
tmp135 = ((stringEqual(_name, _OMC_LIT8)) || (stringEqual(_name, _OMC_LIT7)));
if (1 != tmp135) goto goto_2;
tmpMeta136 = listReverse(_expl);
if (listEmpty(tmpMeta136)) goto goto_2;
tmpMeta137 = MMC_CAR(tmpMeta136);
tmpMeta138 = MMC_CDR(tmpMeta136);
if (listEmpty(tmpMeta138)) goto goto_2;
tmpMeta139 = MMC_CAR(tmpMeta138);
tmpMeta140 = MMC_CDR(tmpMeta138);
_e1 = tmpMeta137;
_e2 = tmpMeta139;
_expl = tmpMeta140;
tmpMeta141 = mmc_mk_cons(_e2, mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil)));
_e1 = omc_Expression_makePureBuiltinCall(threadData, _name, tmpMeta141, _tp);
tmpMeta1 = omc_List_fold2(threadData, _expl, boxvar_ExpressionSimplify_makeNestedReduction, _name, _tp, _e1);
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta142;
modelica_metatype tmpMeta143;
modelica_metatype tmpMeta144;
modelica_metatype tmpMeta145;
modelica_metatype tmpMeta146;
modelica_metatype tmpMeta147;
modelica_metatype tmpMeta148;
modelica_metatype tmpMeta149;
modelica_metatype tmpMeta150;
modelica_metatype tmpMeta151;
modelica_metatype tmpMeta152;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta142 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta142,1,1) == 0) goto tmp3_end;
tmpMeta143 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta142), 2));
if (5 != MMC_STRLEN(tmpMeta143) || strcmp(MMC_STRINGDATA(_OMC_LIT109), MMC_STRINGDATA(tmpMeta143)) != 0) goto tmp3_end;
tmpMeta144 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmp4_1;
_expl = tmpMeta144;
tmp4 += 44;
tmpMeta145 = _expl;
if (listEmpty(tmpMeta145)) goto goto_2;
tmpMeta146 = MMC_CAR(tmpMeta145);
tmpMeta147 = MMC_CDR(tmpMeta145);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta146,16,3) == 0) goto goto_2;
tmpMeta148 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta146), 4));
if (listEmpty(tmpMeta147)) goto goto_2;
tmpMeta149 = MMC_CAR(tmpMeta147);
tmpMeta150 = MMC_CDR(tmpMeta147);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta149,16,3) == 0) goto goto_2;
tmpMeta151 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta149), 4));
if (!listEmpty(tmpMeta150)) goto goto_2;
_v1 = tmpMeta148;
_v2 = tmpMeta151;
_expl = omc_ExpressionSimplify_simplifyCross(threadData, _v1, _v2);
_tp = omc_Expression_typeof(threadData, _e);
_scalar = (!omc_Expression_isArrayType(threadData, omc_Expression_unliftArray(threadData, _tp)));
tmpMeta152 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(_scalar), _expl);
tmpMeta1 = tmpMeta152;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta153;
modelica_metatype tmpMeta154;
modelica_metatype tmpMeta155;
modelica_metatype tmpMeta156;
modelica_metatype tmpMeta157;
modelica_metatype tmpMeta158;
modelica_metatype tmpMeta159;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta153 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta153,1,1) == 0) goto tmp3_end;
tmpMeta154 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta153), 2));
if (4 != MMC_STRLEN(tmpMeta154) || strcmp(MMC_STRINGDATA(_OMC_LIT110), MMC_STRINGDATA(tmpMeta154)) != 0) goto tmp3_end;
tmpMeta155 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta155)) goto tmp3_end;
tmpMeta156 = MMC_CAR(tmpMeta155);
tmpMeta157 = MMC_CDR(tmpMeta155);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta156,16,3) == 0) goto tmp3_end;
tmpMeta158 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta156), 4));
if (!listEmpty(tmpMeta157)) goto tmp3_end;
_e = tmp4_1;
_v1 = tmpMeta158;
tmp4 += 43;
_mexpl = omc_ExpressionSimplify_simplifySkew(threadData, _v1);
_tp = omc_Expression_typeof(threadData, _e);
tmpMeta159 = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _tp, mmc_mk_integer(((modelica_integer) 3)), _mexpl);
tmpMeta1 = tmpMeta159;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta160;
modelica_metatype tmpMeta161;
modelica_metatype tmpMeta162;
modelica_metatype tmpMeta163;
modelica_metatype tmpMeta164;
modelica_metatype tmpMeta165;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta160 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta160,1,1) == 0) goto tmp3_end;
tmpMeta161 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta160), 2));
if (4 != MMC_STRLEN(tmpMeta161) || strcmp(MMC_STRINGDATA(_OMC_LIT111), MMC_STRINGDATA(tmpMeta161)) != 0) goto tmp3_end;
tmpMeta162 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta162)) goto tmp3_end;
tmpMeta163 = MMC_CAR(tmpMeta162);
tmpMeta164 = MMC_CDR(tmpMeta162);
_e = tmpMeta163;
_expl = tmpMeta164;
tmp4 += 42;
_valueLst = omc_List_map(threadData, _expl, boxvar_ValuesUtil_expValue);
tmpMeta165 = MMC_REFSTRUCTLIT(mmc_nil);
omc_Static_elabBuiltinFill2(threadData, omc_FCore_noCache(threadData), omc_FGraph_empty(threadData), _e, omc_Expression_typeof(threadData, _e), _valueLst, _OMC_LIT90, _OMC_LIT91, tmpMeta165, _OMC_LIT92 ,&_outExp ,NULL);
tmpMeta1 = _outExp;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta166;
modelica_metatype tmpMeta167;
modelica_metatype tmpMeta168;
modelica_metatype tmpMeta169;
modelica_metatype tmpMeta170;
modelica_metatype tmpMeta171;
modelica_metatype tmpMeta172;
modelica_metatype tmpMeta173;
modelica_metatype tmpMeta174;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta166 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta166,1,1) == 0) goto tmp3_end;
tmpMeta167 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta166), 2));
if (6 != MMC_STRLEN(tmpMeta167) || strcmp(MMC_STRINGDATA(_OMC_LIT112), MMC_STRINGDATA(tmpMeta167)) != 0) goto tmp3_end;
tmpMeta168 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta168)) goto tmp3_end;
tmpMeta169 = MMC_CAR(tmpMeta168);
tmpMeta170 = MMC_CDR(tmpMeta168);
if (listEmpty(tmpMeta170)) goto tmp3_end;
tmpMeta171 = MMC_CAR(tmpMeta170);
tmpMeta172 = MMC_CDR(tmpMeta170);
if (listEmpty(tmpMeta172)) goto tmp3_end;
tmpMeta173 = MMC_CAR(tmpMeta172);
tmpMeta174 = MMC_CDR(tmpMeta172);
if (!listEmpty(tmpMeta174)) goto tmp3_end;
_e = tmpMeta169;
_len_exp = tmpMeta171;
_just_exp = tmpMeta173;
tmp4 += 41;
tmpMeta1 = omc_ExpressionSimplify_simplifyBuiltinStringFormat(threadData, _e, _len_exp, _just_exp);
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta175;
modelica_metatype tmpMeta176;
modelica_metatype tmpMeta177;
modelica_metatype tmpMeta178;
modelica_metatype tmpMeta179;
modelica_metatype tmpMeta180;
modelica_metatype tmpMeta181;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta175 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta175,1,1) == 0) goto tmp3_end;
tmpMeta176 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta175), 2));
if (16 != MMC_STRLEN(tmpMeta176) || strcmp(MMC_STRINGDATA(_OMC_LIT74), MMC_STRINGDATA(tmpMeta176)) != 0) goto tmp3_end;
tmpMeta177 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta177)) goto tmp3_end;
tmpMeta178 = MMC_CAR(tmpMeta177);
tmpMeta179 = MMC_CDR(tmpMeta177);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta178,28,1) == 0) goto tmp3_end;
tmpMeta180 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta178), 2));
if (!listEmpty(tmpMeta179)) goto tmp3_end;
_expl = tmpMeta180;
tmp4 += 40;
tmpMeta181 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta1 = omc_ExpressionSimplify_simplifyStringAppendList(threadData, _expl, tmpMeta181, 0);
goto tmp3_done;
}
case 17: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta182 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta182,1,1) == 0) goto tmp3_end;
tmpMeta183 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta182), 2));
if (4 != MMC_STRLEN(tmpMeta183) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta183)) != 0) goto tmp3_end;
tmpMeta184 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta184)) goto tmp3_end;
tmpMeta185 = MMC_CAR(tmpMeta184);
tmpMeta186 = MMC_CDR(tmpMeta184);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta185,7,3) == 0) goto tmp3_end;
tmpMeta187 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta185), 2));
tmpMeta188 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta185), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta188,4,1) == 0) goto tmp3_end;
tmpMeta189 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta188), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta189,1,1) == 0) goto tmp3_end;
tmpMeta190 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta185), 4));
if (!listEmpty(tmpMeta186)) goto tmp3_end;
_e1 = tmpMeta187;
_e2 = tmpMeta190;
tmp4 += 39;
tmpMeta191 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT33, _OMC_LIT34, _e2);
tmpMeta192 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _OMC_LIT36, tmpMeta191);
_e = tmpMeta192;
tmpMeta193 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT24, tmpMeta193, _OMC_LIT30);
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta194;
modelica_metatype tmpMeta195;
modelica_metatype tmpMeta196;
modelica_metatype tmpMeta197;
modelica_metatype tmpMeta198;
modelica_metatype tmpMeta199;
modelica_metatype tmpMeta200;
modelica_metatype tmpMeta201;
modelica_metatype tmpMeta202;
modelica_metatype tmpMeta203;
modelica_metatype tmpMeta204;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta194 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta194,1,1) == 0) goto tmp3_end;
tmpMeta195 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta194), 2));
if (4 != MMC_STRLEN(tmpMeta195) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta195)) != 0) goto tmp3_end;
tmpMeta196 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta196)) goto tmp3_end;
tmpMeta197 = MMC_CAR(tmpMeta196);
tmpMeta198 = MMC_CDR(tmpMeta196);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta197,13,3) == 0) goto tmp3_end;
tmpMeta199 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta197), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta199,1,1) == 0) goto tmp3_end;
tmpMeta200 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta199), 2));
if (4 != MMC_STRLEN(tmpMeta200) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta200)) != 0) goto tmp3_end;
tmpMeta201 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta197), 3));
if (listEmpty(tmpMeta201)) goto tmp3_end;
tmpMeta202 = MMC_CAR(tmpMeta201);
tmpMeta203 = MMC_CDR(tmpMeta201);
if (!listEmpty(tmpMeta203)) goto tmp3_end;
if (!listEmpty(tmpMeta198)) goto tmp3_end;
_e1 = tmpMeta202;
tmp4 += 38;
tmpMeta204 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _OMC_LIT36, _OMC_LIT94);
tmpMeta1 = tmpMeta204;
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta205;
modelica_metatype tmpMeta206;
modelica_metatype tmpMeta207;
modelica_metatype tmpMeta208;
modelica_metatype tmpMeta209;
modelica_metatype tmpMeta210;
modelica_metatype tmpMeta211;
modelica_real tmp212;
modelica_metatype tmpMeta213;
modelica_metatype tmpMeta214;
modelica_metatype tmpMeta215;
modelica_boolean tmp216;
modelica_metatype tmpMeta217;
modelica_metatype tmpMeta218;
modelica_metatype tmpMeta219;
modelica_metatype tmpMeta220;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta205 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta205,1,1) == 0) goto tmp3_end;
tmpMeta206 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta205), 2));
if (4 != MMC_STRLEN(tmpMeta206) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta206)) != 0) goto tmp3_end;
tmpMeta207 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta207)) goto tmp3_end;
tmpMeta208 = MMC_CAR(tmpMeta207);
tmpMeta209 = MMC_CDR(tmpMeta207);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta208,7,3) == 0) goto tmp3_end;
tmpMeta210 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta208), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta210,1,1) == 0) goto tmp3_end;
tmpMeta211 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta210), 2));
tmp212 = mmc_unbox_real(tmpMeta211);
tmpMeta213 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta208), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta213,2,1) == 0) goto tmp3_end;
tmpMeta214 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta213), 2));
tmpMeta215 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta208), 4));
if (!listEmpty(tmpMeta209)) goto tmp3_end;
_e1 = tmpMeta210;
_r1 = tmp212;
_tp = tmpMeta214;
_e2 = tmpMeta215;
tmp4 += 37;
tmp216 = (_r1 >= 0.0);
if (1 != tmp216) goto goto_2;
tmpMeta217 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
_e = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta217, _OMC_LIT30);
tmpMeta218 = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta218, _OMC_LIT30);
tmpMeta219 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
tmpMeta220 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, tmpMeta219, _e3);
tmpMeta1 = tmpMeta220;
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta221;
modelica_metatype tmpMeta222;
modelica_metatype tmpMeta223;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta221 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta221,1,1) == 0) goto tmp3_end;
tmpMeta222 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta221), 2));
if (3 != MMC_STRLEN(tmpMeta222) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta222)) != 0) goto tmp3_end;
tmpMeta223 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta223)) goto tmp3_end;
tmpMeta224 = MMC_CAR(tmpMeta223);
tmpMeta225 = MMC_CDR(tmpMeta223);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta224,8,2) == 0) goto tmp3_end;
tmpMeta226 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta224), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta226,5,1) == 0) goto tmp3_end;
tmpMeta227 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta224), 3));
if (!listEmpty(tmpMeta225)) goto tmp3_end;
_e1 = tmpMeta227;
_expl = omc_Expression_expandFactors(threadData, _e1);
tmpMeta229 = omc_List_split1OnTrue(threadData, _expl, boxvar_Expression_isFunCall, _OMC_LIT68, &tmpMeta228);
if (listEmpty(tmpMeta229)) goto goto_2;
tmpMeta230 = MMC_CAR(tmpMeta229);
tmpMeta231 = MMC_CDR(tmpMeta229);
if (!listEmpty(tmpMeta231)) goto goto_2;
_e2 = tmpMeta230;
_es = tmpMeta228;
tmpMeta232 = _e2;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta232,13,3) == 0) goto goto_2;
tmpMeta233 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta232), 3));
if (listEmpty(tmpMeta233)) goto goto_2;
tmpMeta234 = MMC_CAR(tmpMeta233);
tmpMeta235 = MMC_CDR(tmpMeta233);
if (!listEmpty(tmpMeta235)) goto goto_2;
_e = tmpMeta234;
_e3 = omc_Expression_makeProductLst(threadData, _es);
tmpMeta1 = omc_Expression_expPow(threadData, _e, omc_Expression_negate(threadData, _e3));
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta236;
modelica_metatype tmpMeta237;
modelica_metatype tmpMeta238;
modelica_metatype tmpMeta239;
modelica_metatype tmpMeta240;
modelica_metatype tmpMeta241;
modelica_metatype tmpMeta242;
modelica_metatype tmpMeta243;
modelica_metatype tmpMeta244;
modelica_metatype tmpMeta245;
modelica_metatype tmpMeta246;
modelica_metatype tmpMeta247;
modelica_metatype tmpMeta248;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta236 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta236,1,1) == 0) goto tmp3_end;
tmpMeta237 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta236), 2));
if (3 != MMC_STRLEN(tmpMeta237) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta237)) != 0) goto tmp3_end;
tmpMeta238 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta238)) goto tmp3_end;
tmpMeta239 = MMC_CAR(tmpMeta238);
tmpMeta240 = MMC_CDR(tmpMeta238);
if (!listEmpty(tmpMeta240)) goto tmp3_end;
_e1 = tmpMeta239;
tmp4 += 35;
_expl = omc_Expression_expandFactors(threadData, _e1);
tmpMeta242 = omc_List_split1OnTrue(threadData, _expl, boxvar_Expression_isFunCall, _OMC_LIT68, &tmpMeta241);
if (listEmpty(tmpMeta242)) goto goto_2;
tmpMeta243 = MMC_CAR(tmpMeta242);
tmpMeta244 = MMC_CDR(tmpMeta242);
if (!listEmpty(tmpMeta244)) goto goto_2;
_e2 = tmpMeta243;
_es = tmpMeta241;
tmpMeta245 = _e2;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta245,13,3) == 0) goto goto_2;
tmpMeta246 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta245), 3));
if (listEmpty(tmpMeta246)) goto goto_2;
tmpMeta247 = MMC_CAR(tmpMeta246);
tmpMeta248 = MMC_CDR(tmpMeta246);
if (!listEmpty(tmpMeta248)) goto goto_2;
_e = tmpMeta247;
_e3 = omc_Expression_makeProductLst(threadData, _es);
tmpMeta1 = omc_Expression_expPow(threadData, _e, _e3);
goto tmp3_done;
}
case 22: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta249 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta249,13,3) == 0) goto tmp3_end;
tmpMeta250 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta249), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta250,1,1) == 0) goto tmp3_end;
tmpMeta251 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta250), 2));
if (3 != MMC_STRLEN(tmpMeta251) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta251)) != 0) goto tmp3_end;
tmpMeta252 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta249), 3));
if (listEmpty(tmpMeta252)) goto tmp3_end;
tmpMeta253 = MMC_CAR(tmpMeta252);
tmpMeta254 = MMC_CDR(tmpMeta252);
if (!listEmpty(tmpMeta254)) goto tmp3_end;
tmpMeta255 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta255,4,1) == 0) goto tmp3_end;
tmpMeta256 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta255), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta256,1,1) == 0) goto tmp3_end;
tmpMeta257 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta253;
_e2 = tmpMeta257;
tmp4 += 34;
_e3 = omc_Expression_expMul(threadData, _e, _e2);
tmpMeta258 = mmc_mk_cons(_e3, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT25, tmpMeta258, _OMC_LIT30);
goto tmp3_done;
}
case 23: {
modelica_metatype tmpMeta259;
modelica_metatype tmpMeta260;
modelica_metatype tmpMeta261;
modelica_metatype tmpMeta262;
modelica_metatype tmpMeta263;
modelica_metatype tmpMeta264;
modelica_metatype tmpMeta265;
modelica_metatype tmpMeta266;
modelica_metatype tmpMeta267;
modelica_metatype tmpMeta268;
modelica_real tmp269;
modelica_real tmp270;
modelica_metatype tmpMeta271;
modelica_metatype tmpMeta272;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta259 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta259,1,1) == 0) goto tmp3_end;
tmpMeta260 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta259), 2));
if (3 != MMC_STRLEN(tmpMeta260) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta260)) != 0) goto tmp3_end;
tmpMeta261 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta261)) goto tmp3_end;
tmpMeta262 = MMC_CAR(tmpMeta261);
tmpMeta263 = MMC_CDR(tmpMeta261);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta262,7,3) == 0) goto tmp3_end;
tmpMeta264 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta262), 2));
tmpMeta265 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta262), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta265,4,1) == 0) goto tmp3_end;
tmpMeta266 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta265), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta266,1,1) == 0) goto tmp3_end;
tmpMeta267 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta262), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta267,1,1) == 0) goto tmp3_end;
tmpMeta268 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta267), 2));
tmp269 = mmc_unbox_real(tmpMeta268);
if (!listEmpty(tmpMeta263)) goto tmp3_end;
_e1 = tmpMeta264;
_r1 = tmp269;
tmp4 += 33;
tmp270 = modelica_real_mod(_r1, 2.0);
if (1.0 != tmp270) goto goto_2;
tmpMeta271 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT68, tmpMeta271, _OMC_LIT30);
tmpMeta272 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r1));
tmpMeta1 = omc_Expression_expMul(threadData, tmpMeta272, _e3);
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta273;
modelica_metatype tmpMeta274;
modelica_metatype tmpMeta275;
modelica_metatype tmpMeta276;
modelica_metatype tmpMeta277;
modelica_metatype tmpMeta278;
modelica_metatype tmpMeta279;
modelica_real tmp280;
modelica_metatype tmpMeta281;
modelica_metatype tmpMeta282;
modelica_metatype tmpMeta283;
modelica_metatype tmpMeta284;
modelica_metatype tmpMeta285;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta273 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta273,1,1) == 0) goto tmp3_end;
tmpMeta274 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta273), 2));
if (3 != MMC_STRLEN(tmpMeta274) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta274)) != 0) goto tmp3_end;
tmpMeta275 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta275)) goto tmp3_end;
tmpMeta276 = MMC_CAR(tmpMeta275);
tmpMeta277 = MMC_CDR(tmpMeta275);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta276,7,3) == 0) goto tmp3_end;
tmpMeta278 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta276), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta278,1,1) == 0) goto tmp3_end;
tmpMeta279 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta278), 2));
tmp280 = mmc_unbox_real(tmpMeta279);
if (1.0 != tmp280) goto tmp3_end;
tmpMeta281 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta276), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta281,3,1) == 0) goto tmp3_end;
tmpMeta282 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta281), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta282,1,1) == 0) goto tmp3_end;
tmpMeta283 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta276), 4));
if (!listEmpty(tmpMeta277)) goto tmp3_end;
_e2 = tmpMeta283;
tmp4 += 32;
tmpMeta284 = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT68, tmpMeta284, _OMC_LIT30);
tmpMeta285 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _OMC_LIT95, _e3);
tmpMeta1 = tmpMeta285;
goto tmp3_done;
}
case 25: {
modelica_metatype tmpMeta286;
modelica_metatype tmpMeta287;
modelica_metatype tmpMeta288;
modelica_metatype tmpMeta289;
modelica_metatype tmpMeta290;
modelica_metatype tmpMeta291;
modelica_metatype tmpMeta292;
modelica_metatype tmpMeta293;
modelica_metatype tmpMeta294;
modelica_metatype tmpMeta295;
modelica_metatype tmpMeta296;
modelica_metatype tmpMeta297;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta286 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta286,1,1) == 0) goto tmp3_end;
tmpMeta287 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta286), 2));
if (3 != MMC_STRLEN(tmpMeta287) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta287)) != 0) goto tmp3_end;
tmpMeta288 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta288)) goto tmp3_end;
tmpMeta289 = MMC_CAR(tmpMeta288);
tmpMeta290 = MMC_CDR(tmpMeta288);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta289,13,3) == 0) goto tmp3_end;
tmpMeta291 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta289), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta291,1,1) == 0) goto tmp3_end;
tmpMeta292 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta291), 2));
if (4 != MMC_STRLEN(tmpMeta292) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta292)) != 0) goto tmp3_end;
tmpMeta293 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta289), 3));
if (listEmpty(tmpMeta293)) goto tmp3_end;
tmpMeta294 = MMC_CAR(tmpMeta293);
tmpMeta295 = MMC_CDR(tmpMeta293);
if (!listEmpty(tmpMeta295)) goto tmp3_end;
if (!listEmpty(tmpMeta290)) goto tmp3_end;
_e1 = tmpMeta294;
tmp4 += 31;
tmpMeta296 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT68, tmpMeta296, _OMC_LIT30);
tmpMeta297 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT33, _OMC_LIT34, _e3);
tmpMeta1 = tmpMeta297;
goto tmp3_done;
}
case 26: {
modelica_metatype tmpMeta298;
modelica_metatype tmpMeta299;
modelica_metatype tmpMeta300;
modelica_metatype tmpMeta301;
modelica_metatype tmpMeta302;
modelica_metatype tmpMeta303;
modelica_metatype tmpMeta304;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta298 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta298,1,1) == 0) goto tmp3_end;
tmpMeta299 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta298), 2));
if (6 != MMC_STRLEN(tmpMeta299) || strcmp(MMC_STRINGDATA(_OMC_LIT113), MMC_STRINGDATA(tmpMeta299)) != 0) goto tmp3_end;
tmpMeta300 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta300)) goto tmp3_end;
tmpMeta301 = MMC_CAR(tmpMeta300);
tmpMeta302 = MMC_CDR(tmpMeta300);
if (listEmpty(tmpMeta302)) goto tmp3_end;
tmpMeta303 = MMC_CAR(tmpMeta302);
tmpMeta304 = MMC_CDR(tmpMeta302);
if (!listEmpty(tmpMeta304)) goto tmp3_end;
_e1 = tmpMeta303;
tmp4 += 30;
if (!omc_Expression_isConst(threadData, _e1)) goto tmp3_end;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 27: {
modelica_metatype tmpMeta305;
modelica_metatype tmpMeta306;
modelica_metatype tmpMeta307;
modelica_metatype tmpMeta308;
modelica_metatype tmpMeta309;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta305 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta305,1,1) == 0) goto tmp3_end;
tmpMeta306 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta305), 2));
if (8 != MMC_STRLEN(tmpMeta306) || strcmp(MMC_STRINGDATA(_OMC_LIT114), MMC_STRINGDATA(tmpMeta306)) != 0) goto tmp3_end;
tmpMeta307 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta307)) goto tmp3_end;
tmpMeta308 = MMC_CAR(tmpMeta307);
tmpMeta309 = MMC_CDR(tmpMeta307);
if (!listEmpty(tmpMeta309)) goto tmp3_end;
_e1 = tmpMeta308;
tmp4 += 29;
if (!omc_Expression_isConst(threadData, _e1)) goto tmp3_end;
tmpMeta1 = omc_Expression_makeConstZeroE(threadData, _e1);
goto tmp3_done;
}
case 28: {
modelica_metatype tmpMeta310;
modelica_metatype tmpMeta311;
modelica_metatype tmpMeta312;
modelica_metatype tmpMeta313;
modelica_metatype tmpMeta314;
modelica_metatype tmpMeta315;
modelica_metatype tmpMeta316;
modelica_metatype tmpMeta317;
modelica_metatype tmpMeta318;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta310 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta310,1,1) == 0) goto tmp3_end;
tmpMeta311 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta310), 2));
if (5 != MMC_STRLEN(tmpMeta311) || strcmp(MMC_STRINGDATA(_OMC_LIT96), MMC_STRINGDATA(tmpMeta311)) != 0) goto tmp3_end;
tmpMeta312 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta312)) goto tmp3_end;
tmpMeta313 = MMC_CAR(tmpMeta312);
tmpMeta314 = MMC_CDR(tmpMeta312);
if (listEmpty(tmpMeta314)) goto tmp3_end;
tmpMeta315 = MMC_CAR(tmpMeta314);
tmpMeta316 = MMC_CDR(tmpMeta314);
if (!listEmpty(tmpMeta316)) goto tmp3_end;
_e = tmp4_1;
_e1 = tmpMeta313;
_e2 = tmpMeta315;
tmp4 += 28;
tmpMeta318 = mmc_mk_cons(_e1, mmc_mk_cons(_e2, mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta317 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta317), MMC_UNTAGPTR(_e), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta317))[3] = tmpMeta318;
_e = tmpMeta317;
tmpMeta1 = _e;
goto tmp3_done;
}
case 29: {
modelica_metatype tmpMeta319;
modelica_metatype tmpMeta320;
modelica_metatype tmpMeta321;
modelica_metatype tmpMeta322;
modelica_metatype tmpMeta323;
modelica_metatype tmpMeta324;
modelica_metatype tmpMeta325;
modelica_metatype tmpMeta326;
modelica_metatype tmpMeta327;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta319 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta319,1,1) == 0) goto tmp3_end;
tmpMeta320 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta319), 2));
if (5 != MMC_STRLEN(tmpMeta320) || strcmp(MMC_STRINGDATA(_OMC_LIT96), MMC_STRINGDATA(tmpMeta320)) != 0) goto tmp3_end;
tmpMeta321 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta321)) goto tmp3_end;
tmpMeta322 = MMC_CAR(tmpMeta321);
tmpMeta323 = MMC_CDR(tmpMeta321);
if (listEmpty(tmpMeta323)) goto tmp3_end;
tmpMeta324 = MMC_CAR(tmpMeta323);
tmpMeta325 = MMC_CDR(tmpMeta323);
if (listEmpty(tmpMeta325)) goto tmp3_end;
tmpMeta326 = MMC_CAR(tmpMeta325);
tmpMeta327 = MMC_CDR(tmpMeta325);
if (!listEmpty(tmpMeta327)) goto tmp3_end;
_e1 = tmpMeta322;
if (!omc_Expression_isConst(threadData, _e1)) goto tmp3_end;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 30: {
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
modelica_boolean tmp342;
modelica_metatype tmpMeta343;
modelica_metatype tmpMeta344;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta328 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta328,1,1) == 0) goto tmp3_end;
tmpMeta329 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta328), 2));
if (5 != MMC_STRLEN(tmpMeta329) || strcmp(MMC_STRINGDATA(_OMC_LIT96), MMC_STRINGDATA(tmpMeta329)) != 0) goto tmp3_end;
tmpMeta330 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta330)) goto tmp3_end;
tmpMeta331 = MMC_CAR(tmpMeta330);
tmpMeta332 = MMC_CDR(tmpMeta330);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta331,7,3) == 0) goto tmp3_end;
tmpMeta333 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta331), 2));
tmpMeta334 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta331), 3));
tmpMeta335 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta331), 4));
if (listEmpty(tmpMeta332)) goto tmp3_end;
tmpMeta336 = MMC_CAR(tmpMeta332);
tmpMeta337 = MMC_CDR(tmpMeta332);
if (listEmpty(tmpMeta337)) goto tmp3_end;
tmpMeta338 = MMC_CAR(tmpMeta337);
tmpMeta339 = MMC_CDR(tmpMeta337);
if (!listEmpty(tmpMeta339)) goto tmp3_end;
tmpMeta340 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta341 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta340), 2));
_e1 = tmpMeta333;
_op = tmpMeta334;
_e2 = tmpMeta335;
_e3 = tmpMeta336;
_e4 = tmpMeta338;
_tp = tmpMeta341;
tmp342 = omc_Expression_isConst(threadData, _e1);
if (1 != tmp342) goto goto_2;
tmpMeta343 = mmc_mk_cons(_e2, mmc_mk_cons(_e3, mmc_mk_cons(_e4, MMC_REFSTRUCTLIT(mmc_nil))));
_e = omc_Expression_makeImpureBuiltinCall(threadData, _OMC_LIT96, tmpMeta343, _tp);
tmpMeta344 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e);
tmpMeta1 = tmpMeta344;
goto tmp3_done;
}
case 31: {
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
modelica_boolean tmp359;
modelica_metatype tmpMeta360;
modelica_metatype tmpMeta361;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta345 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta345,1,1) == 0) goto tmp3_end;
tmpMeta346 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta345), 2));
if (5 != MMC_STRLEN(tmpMeta346) || strcmp(MMC_STRINGDATA(_OMC_LIT96), MMC_STRINGDATA(tmpMeta346)) != 0) goto tmp3_end;
tmpMeta347 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta347)) goto tmp3_end;
tmpMeta348 = MMC_CAR(tmpMeta347);
tmpMeta349 = MMC_CDR(tmpMeta347);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta348,7,3) == 0) goto tmp3_end;
tmpMeta350 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta348), 2));
tmpMeta351 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta348), 3));
tmpMeta352 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta348), 4));
if (listEmpty(tmpMeta349)) goto tmp3_end;
tmpMeta353 = MMC_CAR(tmpMeta349);
tmpMeta354 = MMC_CDR(tmpMeta349);
if (listEmpty(tmpMeta354)) goto tmp3_end;
tmpMeta355 = MMC_CAR(tmpMeta354);
tmpMeta356 = MMC_CDR(tmpMeta354);
if (!listEmpty(tmpMeta356)) goto tmp3_end;
tmpMeta357 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta358 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta357), 2));
_e1 = tmpMeta350;
_op = tmpMeta351;
_e2 = tmpMeta352;
_e3 = tmpMeta353;
_e4 = tmpMeta355;
_tp = tmpMeta358;
tmp4 += 25;
tmp359 = omc_Expression_isConst(threadData, _e2);
if (1 != tmp359) goto goto_2;
tmpMeta360 = mmc_mk_cons(_e1, mmc_mk_cons(_e3, mmc_mk_cons(_e4, MMC_REFSTRUCTLIT(mmc_nil))));
_e = omc_Expression_makeImpureBuiltinCall(threadData, _OMC_LIT96, tmpMeta360, _tp);
tmpMeta361 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op, _e2);
tmpMeta1 = tmpMeta361;
goto tmp3_done;
}
case 32: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta362 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta362,1,1) == 0) goto tmp3_end;
tmpMeta363 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta362), 2));
if (5 != MMC_STRLEN(tmpMeta363) || strcmp(MMC_STRINGDATA(_OMC_LIT96), MMC_STRINGDATA(tmpMeta363)) != 0) goto tmp3_end;
tmpMeta364 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta364)) goto tmp3_end;
tmpMeta365 = MMC_CAR(tmpMeta364);
tmpMeta366 = MMC_CDR(tmpMeta364);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta365,8,2) == 0) goto tmp3_end;
tmpMeta367 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta365), 2));
tmpMeta368 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta365), 3));
if (listEmpty(tmpMeta366)) goto tmp3_end;
tmpMeta369 = MMC_CAR(tmpMeta366);
tmpMeta370 = MMC_CDR(tmpMeta366);
if (listEmpty(tmpMeta370)) goto tmp3_end;
tmpMeta371 = MMC_CAR(tmpMeta370);
tmpMeta372 = MMC_CDR(tmpMeta370);
if (!listEmpty(tmpMeta372)) goto tmp3_end;
tmpMeta373 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta374 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta373), 2));
_op = tmpMeta367;
_e = tmpMeta368;
_e3 = tmpMeta369;
_e4 = tmpMeta371;
_tp = tmpMeta374;
tmp4 += 24;
tmpMeta375 = mmc_mk_cons(_e, mmc_mk_cons(_e3, mmc_mk_cons(_e4, MMC_REFSTRUCTLIT(mmc_nil))));
_e = omc_Expression_makeImpureBuiltinCall(threadData, _OMC_LIT96, tmpMeta375, _tp);
tmpMeta376 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op, _e);
tmpMeta1 = tmpMeta376;
goto tmp3_done;
}
case 33: {
modelica_metatype tmpMeta377;
modelica_metatype tmpMeta378;
modelica_metatype tmpMeta379;
modelica_metatype tmpMeta380;
modelica_metatype tmpMeta381;
modelica_metatype tmpMeta382;
modelica_metatype tmpMeta383;
modelica_metatype tmpMeta384;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta377 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta377,1,1) == 0) goto tmp3_end;
tmpMeta378 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta377), 2));
if (3 != MMC_STRLEN(tmpMeta378) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmpMeta378)) != 0) goto tmp3_end;
tmpMeta379 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta379)) goto tmp3_end;
tmpMeta380 = MMC_CAR(tmpMeta379);
tmpMeta381 = MMC_CDR(tmpMeta379);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta380,16,3) == 0) goto tmp3_end;
tmpMeta382 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta380), 4));
if (!listEmpty(tmpMeta382)) goto tmp3_end;
if (!listEmpty(tmpMeta381)) goto tmp3_end;
tmpMeta383 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta384 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta383), 2));
_tp1 = tmpMeta384;
tmp4 += 1;
tmpMeta1 = omc_Expression_makeConstZero(threadData, _tp1);
goto tmp3_done;
}
case 34: {
modelica_metatype tmpMeta385;
modelica_metatype tmpMeta386;
modelica_metatype tmpMeta387;
modelica_metatype tmpMeta388;
modelica_metatype tmpMeta389;
modelica_metatype tmpMeta390;
modelica_metatype tmpMeta391;
modelica_metatype tmpMeta392;
modelica_metatype tmpMeta393;
modelica_metatype tmpMeta394;
modelica_metatype tmpMeta395;
modelica_metatype tmpMeta396;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta385 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta385,1,1) == 0) goto tmp3_end;
tmpMeta386 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta385), 2));
if (3 != MMC_STRLEN(tmpMeta386) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmpMeta386)) != 0) goto tmp3_end;
tmpMeta387 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta387)) goto tmp3_end;
tmpMeta388 = MMC_CAR(tmpMeta387);
tmpMeta389 = MMC_CDR(tmpMeta387);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta388,17,3) == 0) goto tmp3_end;
tmpMeta390 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta388), 2));
tmpMeta391 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta388), 4));
if (!listEmpty(tmpMeta389)) goto tmp3_end;
tmpMeta392 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta393 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta392), 2));
_tp1 = tmpMeta390;
_mexpl = tmpMeta391;
_tp2 = tmpMeta393;
tmp4 += 22;
_es = omc_List_flatten(threadData, _mexpl);
_tp1 = omc_Expression_unliftArray(threadData, omc_Expression_unliftArray(threadData, _tp1));
_sc = (!omc_Expression_isArrayType(threadData, _tp1));
_tp1 = (_sc?omc_Expression_unliftArray(threadData, _tp1):_tp1);
_tp1 = (_sc?omc_Expression_liftArrayLeft(threadData, _tp1, _OMC_LIT97):_tp1);
_dim = listLength(_es);
tmpMeta394 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim));
_tp1 = omc_Expression_liftArrayLeft(threadData, _tp1, tmpMeta394);
tmpMeta395 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp1, mmc_mk_boolean(_sc), _es);
_e = tmpMeta395;
tmpMeta396 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT98, tmpMeta396, _tp2);
goto tmp3_done;
}
case 35: {
modelica_metatype tmpMeta397;
modelica_metatype tmpMeta398;
modelica_metatype tmpMeta399;
modelica_metatype tmpMeta400;
modelica_metatype tmpMeta401;
modelica_metatype tmpMeta402;
modelica_metatype tmpMeta403;
modelica_integer tmp404;
modelica_metatype tmpMeta405;
modelica_metatype tmpMeta406;
modelica_metatype tmpMeta407;
modelica_metatype tmpMeta408;
modelica_metatype tmpMeta409;
modelica_metatype tmpMeta410;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta397 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta397,1,1) == 0) goto tmp3_end;
tmpMeta398 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta397), 2));
if (3 != MMC_STRLEN(tmpMeta398) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmpMeta398)) != 0) goto tmp3_end;
tmpMeta399 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta399)) goto tmp3_end;
tmpMeta400 = MMC_CAR(tmpMeta399);
tmpMeta401 = MMC_CDR(tmpMeta399);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta400,16,3) == 0) goto tmp3_end;
tmpMeta402 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta400), 2));
tmpMeta403 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta400), 3));
tmp404 = mmc_unbox_integer(tmpMeta403);
if (0 != tmp404) goto tmp3_end;
tmpMeta405 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta400), 4));
if (!listEmpty(tmpMeta401)) goto tmp3_end;
tmpMeta406 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta407 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta406), 2));
_tp1 = tmpMeta402;
_es = tmpMeta405;
_tp2 = tmpMeta407;
_es = omc_ExpressionSimplify_simplifyCat(threadData, ((modelica_integer) 1), _es);
_tp1 = omc_Expression_unliftArray(threadData, _tp1);
_sc = (!omc_Expression_isArrayType(threadData, _tp1));
_tp1 = (_sc?omc_Expression_unliftArray(threadData, _tp1):_tp1);
_tp1 = (_sc?omc_Expression_liftArrayLeft(threadData, _tp1, _OMC_LIT97):_tp1);
_dim = listLength(_es);
tmpMeta408 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim));
_tp1 = omc_Expression_liftArrayLeft(threadData, _tp1, tmpMeta408);
tmpMeta409 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp1, mmc_mk_boolean(_sc), _es);
_e = tmpMeta409;
tmpMeta410 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT98, tmpMeta410, _tp2);
goto tmp3_done;
}
case 36: {
modelica_metatype tmpMeta411;
modelica_metatype tmpMeta412;
modelica_metatype tmpMeta413;
modelica_metatype tmpMeta414;
modelica_metatype tmpMeta415;
modelica_metatype tmpMeta416;
modelica_integer tmp417;
modelica_metatype tmpMeta418;
modelica_metatype tmpMeta419;
modelica_metatype tmpMeta420;
modelica_metatype tmpMeta421;
modelica_metatype tmpMeta422;
modelica_metatype tmpMeta423;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta411 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta411,1,1) == 0) goto tmp3_end;
tmpMeta412 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta411), 2));
if (3 != MMC_STRLEN(tmpMeta412) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmpMeta412)) != 0) goto tmp3_end;
tmpMeta413 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta413)) goto tmp3_end;
tmpMeta414 = MMC_CAR(tmpMeta413);
tmpMeta415 = MMC_CDR(tmpMeta413);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta414,16,3) == 0) goto tmp3_end;
tmpMeta416 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta414), 3));
tmp417 = mmc_unbox_integer(tmpMeta416);
if (0 != tmp417) goto tmp3_end;
tmpMeta418 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta414), 4));
if (listEmpty(tmpMeta418)) goto tmp3_end;
tmpMeta419 = MMC_CAR(tmpMeta418);
tmpMeta420 = MMC_CDR(tmpMeta418);
if (!listEmpty(tmpMeta420)) goto tmp3_end;
if (!listEmpty(tmpMeta415)) goto tmp3_end;
tmpMeta421 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta422 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta421), 2));
_e = tmpMeta419;
_tp2 = tmpMeta422;
tmp4 += 20;
tmpMeta423 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT98, tmpMeta423, _tp2);
goto tmp3_done;
}
case 37: {
modelica_metatype tmpMeta424;
modelica_metatype tmpMeta425;
modelica_metatype tmpMeta426;
modelica_metatype tmpMeta427;
modelica_metatype tmpMeta428;
modelica_metatype tmpMeta429;
modelica_integer tmp430;
modelica_metatype tmpMeta431;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta424 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta424,1,1) == 0) goto tmp3_end;
tmpMeta425 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta424), 2));
if (3 != MMC_STRLEN(tmpMeta425) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmpMeta425)) != 0) goto tmp3_end;
tmpMeta426 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta426)) goto tmp3_end;
tmpMeta427 = MMC_CAR(tmpMeta426);
tmpMeta428 = MMC_CDR(tmpMeta426);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta427,16,3) == 0) goto tmp3_end;
tmpMeta429 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta427), 3));
tmp430 = mmc_unbox_integer(tmpMeta429);
if (1 != tmp430) goto tmp3_end;
tmpMeta431 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta427), 4));
if (!listEmpty(tmpMeta428)) goto tmp3_end;
_es = tmpMeta431;
tmp4 += 19;
tmpMeta1 = omc_Expression_makeSum(threadData, _es);
goto tmp3_done;
}
case 38: {
modelica_metatype tmpMeta432;
modelica_metatype tmpMeta433;
modelica_metatype tmpMeta434;
modelica_metatype tmpMeta435;
modelica_metatype tmpMeta436;
modelica_metatype tmpMeta437;
modelica_metatype tmpMeta438;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta432 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta432,1,1) == 0) goto tmp3_end;
tmpMeta433 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta432), 2));
if (3 != MMC_STRLEN(tmpMeta433) || strcmp(MMC_STRINGDATA(_OMC_LIT99), MMC_STRINGDATA(tmpMeta433)) != 0) goto tmp3_end;
tmpMeta434 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta434)) goto tmp3_end;
tmpMeta435 = MMC_CAR(tmpMeta434);
tmpMeta436 = MMC_CDR(tmpMeta434);
if (listEmpty(tmpMeta436)) goto tmp3_end;
tmpMeta437 = MMC_CAR(tmpMeta436);
tmpMeta438 = MMC_CDR(tmpMeta436);
if (!listEmpty(tmpMeta438)) goto tmp3_end;
_e1 = tmpMeta437;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 39: {
modelica_metatype tmpMeta439;
modelica_metatype tmpMeta440;
modelica_metatype tmpMeta441;
modelica_metatype tmpMeta442;
modelica_metatype tmpMeta443;
modelica_metatype tmpMeta444;
modelica_integer tmp445;
modelica_metatype tmpMeta446;
modelica_metatype tmpMeta447;
modelica_metatype tmpMeta448;
modelica_metatype tmpMeta449;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta439 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta439,1,1) == 0) goto tmp3_end;
tmpMeta440 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta439), 2));
if (3 != MMC_STRLEN(tmpMeta440) || strcmp(MMC_STRINGDATA(_OMC_LIT99), MMC_STRINGDATA(tmpMeta440)) != 0) goto tmp3_end;
tmpMeta441 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta441)) goto tmp3_end;
tmpMeta442 = MMC_CAR(tmpMeta441);
tmpMeta443 = MMC_CDR(tmpMeta441);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta442,0,1) == 0) goto tmp3_end;
tmpMeta444 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta442), 2));
tmp445 = mmc_unbox_integer(tmpMeta444);
tmpMeta446 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta447 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta446), 2));
_i = tmp445;
_es = tmpMeta443;
_tp = tmpMeta447;
_es = omc_ExpressionSimplify_simplifyCat(threadData, _i, _es);
tmpMeta449 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta448 = mmc_mk_cons(tmpMeta449, _es);
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT99, tmpMeta448, _tp);
goto tmp3_done;
}
case 40: {
modelica_metatype tmpMeta450;
modelica_metatype tmpMeta451;
modelica_metatype tmpMeta452;
modelica_metatype tmpMeta453;
modelica_metatype tmpMeta454;
modelica_metatype tmpMeta455;
modelica_integer tmp456;
modelica_metatype tmpMeta457;
modelica_metatype tmpMeta458;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta450 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta450,1,1) == 0) goto tmp3_end;
tmpMeta451 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta450), 2));
if (3 != MMC_STRLEN(tmpMeta451) || strcmp(MMC_STRINGDATA(_OMC_LIT99), MMC_STRINGDATA(tmpMeta451)) != 0) goto tmp3_end;
tmpMeta452 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta452)) goto tmp3_end;
tmpMeta453 = MMC_CAR(tmpMeta452);
tmpMeta454 = MMC_CDR(tmpMeta452);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta453,0,1) == 0) goto tmp3_end;
tmpMeta455 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta453), 2));
tmp456 = mmc_unbox_integer(tmpMeta455);
tmpMeta457 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_i = tmp456;
_es = tmpMeta454;
tmp4 += 16;
_es = omc_ExpressionSimplify_evalCat(threadData, _i, _es, boxvar_Expression_getArrayOrMatrixContents, boxvar_ExpressionDump_printExpStr ,&_dims);
{
modelica_metatype __omcQ_24tmpVar43;
modelica_metatype* tmp459;
modelica_metatype tmpMeta460;
modelica_metatype tmpMeta461;
modelica_metatype __omcQ_24tmpVar42;
modelica_integer tmp462;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _dims;
tmpMeta460 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar43 = tmpMeta460;
tmp459 = &__omcQ_24tmpVar43;
while(1) {
tmp462 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp462--;
}
if (tmp462 == 0) {
tmpMeta461 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, _d);
__omcQ_24tmpVar42 = tmpMeta461;
*tmp459 = mmc_mk_cons(__omcQ_24tmpVar42,0);
tmp459 = &MMC_CDR(*tmp459);
} else if (tmp462 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp459 = mmc_mk_nil();
tmpMeta458 = __omcQ_24tmpVar43;
}
tmpMeta1 = omc_Expression_listToArray(threadData, _es, tmpMeta458);
goto tmp3_done;
}
case 41: {
modelica_metatype tmpMeta463;
modelica_metatype tmpMeta464;
modelica_metatype tmpMeta465;
modelica_metatype tmpMeta466;
modelica_metatype tmpMeta467;
modelica_metatype tmpMeta468;
modelica_metatype tmpMeta469;
modelica_metatype tmpMeta470;
modelica_integer tmp471;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta463 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta463,1,1) == 0) goto tmp3_end;
tmpMeta464 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta463), 2));
if (7 != MMC_STRLEN(tmpMeta464) || strcmp(MMC_STRINGDATA(_OMC_LIT115), MMC_STRINGDATA(tmpMeta464)) != 0) goto tmp3_end;
tmpMeta465 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta465)) goto tmp3_end;
tmpMeta466 = MMC_CAR(tmpMeta465);
tmpMeta467 = MMC_CDR(tmpMeta465);
if (listEmpty(tmpMeta467)) goto tmp3_end;
tmpMeta468 = MMC_CAR(tmpMeta467);
tmpMeta469 = MMC_CDR(tmpMeta467);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta468,0,1) == 0) goto tmp3_end;
tmpMeta470 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta468), 2));
tmp471 = mmc_unbox_integer(tmpMeta470);
if (!listEmpty(tmpMeta469)) goto tmp3_end;
_e1 = tmpMeta466;
_i = tmp471;
if (!(omc_Types_numberOfDimensions(threadData, omc_Expression_typeof(threadData, _e1)) == _i)) goto tmp3_end;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 42: {
modelica_metatype tmpMeta472;
modelica_metatype tmpMeta473;
modelica_metatype tmpMeta474;
modelica_metatype tmpMeta475;
modelica_metatype tmpMeta476;
modelica_metatype tmpMeta477;
modelica_metatype tmpMeta478;
modelica_metatype tmpMeta479;
modelica_metatype tmpMeta480;
modelica_metatype tmpMeta481;
modelica_integer tmp482;
modelica_metatype tmpMeta483;
modelica_metatype tmpMeta484;
modelica_metatype tmpMeta485;
modelica_metatype tmpMeta486;
modelica_integer tmp487;
modelica_metatype tmpMeta488;
modelica_metatype tmpMeta489;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta472 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta472,1,1) == 0) goto tmp3_end;
tmpMeta473 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta472), 2));
if (7 != MMC_STRLEN(tmpMeta473) || strcmp(MMC_STRINGDATA(_OMC_LIT115), MMC_STRINGDATA(tmpMeta473)) != 0) goto tmp3_end;
tmpMeta474 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta474)) goto tmp3_end;
tmpMeta475 = MMC_CAR(tmpMeta474);
tmpMeta476 = MMC_CDR(tmpMeta474);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta475,16,3) == 0) goto tmp3_end;
tmpMeta477 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta475), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta477,6,2) == 0) goto tmp3_end;
tmpMeta478 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta477), 3));
if (listEmpty(tmpMeta478)) goto tmp3_end;
tmpMeta479 = MMC_CAR(tmpMeta478);
tmpMeta480 = MMC_CDR(tmpMeta478);
if (!listEmpty(tmpMeta480)) goto tmp3_end;
tmpMeta481 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta475), 3));
tmp482 = mmc_unbox_integer(tmpMeta481);
tmpMeta483 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta475), 4));
if (listEmpty(tmpMeta476)) goto tmp3_end;
tmpMeta484 = MMC_CAR(tmpMeta476);
tmpMeta485 = MMC_CDR(tmpMeta476);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta484,0,1) == 0) goto tmp3_end;
tmpMeta486 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta484), 2));
tmp487 = mmc_unbox_integer(tmpMeta486);
if (2 != tmp487) goto tmp3_end;
if (!listEmpty(tmpMeta485)) goto tmp3_end;
_tp1 = tmpMeta477;
_sc = tmp482;
_es = tmpMeta483;
_tp = omc_Types_liftArray(threadData, omc_Types_unliftArray(threadData, _tp1), _OMC_LIT100);
_es = omc_List_map2(threadData, omc_List_map(threadData, _es, boxvar_List_create), boxvar_Expression_makeArray, _tp, mmc_mk_boolean(_sc));
_i = listLength(_es);
tmpMeta488 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_i));
_tp = omc_Expression_liftArrayLeft(threadData, _tp, tmpMeta488);
tmpMeta489 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(0), _es);
tmpMeta1 = tmpMeta489;
goto tmp3_done;
}
case 43: {
modelica_metatype tmpMeta490;
modelica_metatype tmpMeta491;
modelica_metatype tmpMeta492;
modelica_metatype tmpMeta493;
modelica_metatype tmpMeta494;
modelica_metatype tmpMeta495;
modelica_metatype tmpMeta496;
modelica_metatype tmpMeta497;
modelica_integer tmp498;
modelica_metatype tmpMeta499;
modelica_integer tmp500;
modelica_integer tmp501;
modelica_integer tmp502;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta490 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta490,1,1) == 0) goto tmp3_end;
tmpMeta491 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta490), 2));
if (7 != MMC_STRLEN(tmpMeta491) || strcmp(MMC_STRINGDATA(_OMC_LIT115), MMC_STRINGDATA(tmpMeta491)) != 0) goto tmp3_end;
tmpMeta492 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta492)) goto tmp3_end;
tmpMeta493 = MMC_CAR(tmpMeta492);
tmpMeta494 = MMC_CDR(tmpMeta492);
if (listEmpty(tmpMeta494)) goto tmp3_end;
tmpMeta495 = MMC_CAR(tmpMeta494);
tmpMeta496 = MMC_CDR(tmpMeta494);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta495,0,1) == 0) goto tmp3_end;
tmpMeta497 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta495), 2));
tmp498 = mmc_unbox_integer(tmpMeta497);
if (!listEmpty(tmpMeta496)) goto tmp3_end;
_e1 = tmpMeta493;
_i = tmp498;
tmp4 += 13;
if (!(!omc_Types_isArray(threadData, omc_Expression_typeof(threadData, _e1)))) goto tmp3_end;
_tp = omc_Expression_typeof(threadData, _e1);
tmp500 = ((modelica_integer) 1); tmp501 = 1; tmp502 = _i;
if(!(((tmp501 > 0) && (tmp500 > tmp502)) || ((tmp501 < 0) && (tmp500 < tmp502))))
{
modelica_integer _j;
for(_j = ((modelica_integer) 1); in_range_integer(_j, tmp500, tmp502); _j += tmp501)
{
_tp1 = omc_Types_liftArray(threadData, _tp, _OMC_LIT100);
tmpMeta499 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
_e1 = omc_Expression_makeArray(threadData, tmpMeta499, _tp1, (!omc_Types_isArray(threadData, _tp)));
_tp = _tp1;
}
}
tmpMeta1 = _e1;
goto tmp3_done;
}
case 44: {
modelica_metatype tmpMeta503;
modelica_metatype tmpMeta504;
modelica_metatype tmpMeta505;
modelica_metatype tmpMeta506;
modelica_metatype tmpMeta507;
modelica_metatype tmpMeta508;
modelica_boolean tmp509;
modelica_metatype tmpMeta510;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta503 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta503,1,1) == 0) goto tmp3_end;
tmpMeta504 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta503), 2));
if (9 != MMC_STRLEN(tmpMeta504) || strcmp(MMC_STRINGDATA(_OMC_LIT116), MMC_STRINGDATA(tmpMeta504)) != 0) goto tmp3_end;
tmpMeta505 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta505)) goto tmp3_end;
tmpMeta506 = MMC_CAR(tmpMeta505);
tmpMeta507 = MMC_CDR(tmpMeta505);
if (!listEmpty(tmpMeta507)) goto tmp3_end;
tmpMeta508 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta506;
tmp4 += 12;
tmpMeta510 = omc_Expression_transposeArray(threadData, _e, &tmp509);
_e = tmpMeta510;
if (1 != tmp509) goto goto_2;
tmpMeta1 = _e;
goto tmp3_done;
}
case 45: {
modelica_metatype tmpMeta511;
modelica_metatype tmpMeta512;
modelica_metatype tmpMeta513;
modelica_metatype tmpMeta514;
modelica_metatype tmpMeta515;
modelica_metatype tmpMeta516;
modelica_metatype tmpMeta517;
modelica_metatype tmpMeta518;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta511 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta511,1,1) == 0) goto tmp3_end;
tmpMeta512 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta511), 2));
if (9 != MMC_STRLEN(tmpMeta512) || strcmp(MMC_STRINGDATA(_OMC_LIT117), MMC_STRINGDATA(tmpMeta512)) != 0) goto tmp3_end;
tmpMeta513 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta513)) goto tmp3_end;
tmpMeta514 = MMC_CAR(tmpMeta513);
tmpMeta515 = MMC_CDR(tmpMeta513);
if (!listEmpty(tmpMeta515)) goto tmp3_end;
tmpMeta516 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta517 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta516), 2));
_e = tmpMeta514;
_tp = tmpMeta517;
tmp4 += 11;
_mexpl = omc_Expression_get2dArrayOrMatrixContent(threadData, _e);
{
modelica_metatype tmp521_1;
tmp521_1 = _mexpl;
{
volatile mmc_switch_type tmp521;
int tmp522;
tmp521 = 0;
for (; tmp521 < 3; tmp521++) {
switch (MMC_SWITCH_CAST(tmp521)) {
case 0: {
modelica_metatype tmpMeta523;
modelica_metatype tmpMeta524;
if (listEmpty(tmp521_1)) goto tmp520_end;
tmpMeta523 = MMC_CAR(tmp521_1);
tmpMeta524 = MMC_CDR(tmp521_1);
if (!listEmpty(tmpMeta523)) goto tmp520_end;
if (!listEmpty(tmpMeta524)) goto tmp520_end;
tmpMeta518 = _e;
goto tmp520_done;
}
case 1: {
modelica_metatype tmpMeta525;
modelica_metatype tmpMeta526;
modelica_metatype tmpMeta527;
modelica_metatype tmpMeta528;
if (listEmpty(tmp521_1)) goto tmp520_end;
tmpMeta525 = MMC_CAR(tmp521_1);
tmpMeta526 = MMC_CDR(tmp521_1);
if (listEmpty(tmpMeta525)) goto tmp520_end;
tmpMeta527 = MMC_CAR(tmpMeta525);
tmpMeta528 = MMC_CDR(tmpMeta525);
if (!listEmpty(tmpMeta528)) goto tmp520_end;
if (!listEmpty(tmpMeta526)) goto tmp520_end;
tmpMeta518 = _e;
goto tmp520_done;
}
case 2: {
modelica_boolean tmp529;
modelica_boolean tmp530;
_marr = listArray(omc_List_map(threadData, _mexpl, boxvar_listArray));
tmp529 = (arrayLength(_marr) == arrayLength(arrayGet(_marr, ((modelica_integer) 1))));
if (1 != tmp529) goto goto_519;
tmp530 = (arrayLength(_marr) > ((modelica_integer) 1));
if (1 != tmp530) goto goto_519;
omc_ExpressionSimplify_simplifySymmetric(threadData, _marr, ((modelica_integer) -1) + arrayLength(_marr), arrayLength(_marr));
_mexpl = omc_List_map(threadData, arrayList(_marr), boxvar_arrayList);
_tp1 = omc_Expression_unliftArray(threadData, _tp);
_es = omc_List_map2(threadData, _mexpl, boxvar_Expression_makeArray, _tp1, mmc_mk_boolean((!omc_Types_isArray(threadData, _tp1))));
tmpMeta518 = omc_Expression_makeArray(threadData, _es, _tp, 0);
goto tmp520_done;
}
}
goto tmp520_end;
tmp520_end: ;
}
goto goto_519;
goto_519:;
goto goto_2;
goto tmp520_done;
tmp520_done:;
}
}tmpMeta1 = tmpMeta518;
goto tmp3_done;
}
case 46: {
modelica_metatype tmpMeta531;
modelica_metatype tmpMeta532;
modelica_metatype tmpMeta533;
modelica_metatype tmpMeta534;
modelica_metatype tmpMeta535;
modelica_metatype tmpMeta536;
modelica_metatype tmpMeta537;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta531 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta531,1,1) == 0) goto tmp3_end;
tmpMeta532 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta531), 2));
if (6 != MMC_STRLEN(tmpMeta532) || strcmp(MMC_STRINGDATA(_OMC_LIT84), MMC_STRINGDATA(tmpMeta532)) != 0) goto tmp3_end;
tmpMeta533 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta533)) goto tmp3_end;
tmpMeta534 = MMC_CAR(tmpMeta533);
tmpMeta535 = MMC_CDR(tmpMeta533);
if (!listEmpty(tmpMeta535)) goto tmp3_end;
tmpMeta536 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta537 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta536), 2));
_e = tmpMeta534;
_tp = tmpMeta537;
tmp4 += 10;
tmpMeta1 = omc_ExpressionSimplify_simplifyScalar(threadData, _e, _tp);
goto tmp3_done;
}
case 47: {
modelica_metatype tmpMeta538;
modelica_metatype tmpMeta539;
modelica_metatype tmpMeta540;
modelica_metatype tmpMeta541;
modelica_metatype tmpMeta542;
modelica_metatype tmpMeta543;
modelica_metatype tmpMeta544;
modelica_metatype tmpMeta545;
modelica_boolean tmp546;
modelica_metatype tmpMeta547;
modelica_metatype tmpMeta548;
modelica_metatype tmpMeta549;
modelica_metatype tmpMeta550;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta538 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta538,1,1) == 0) goto tmp3_end;
tmpMeta539 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta538), 2));
if (6 != MMC_STRLEN(tmpMeta539) || strcmp(MMC_STRINGDATA(_OMC_LIT118), MMC_STRINGDATA(tmpMeta539)) != 0) goto tmp3_end;
tmpMeta540 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta540)) goto tmp3_end;
tmpMeta541 = MMC_CAR(tmpMeta540);
tmpMeta542 = MMC_CDR(tmpMeta540);
tmpMeta543 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta544 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta543), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta544,6,2) == 0) goto tmp3_end;
tmpMeta545 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta544), 2));
_es = tmpMeta540;
_e = tmpMeta541;
_tp = tmpMeta545;
tmp546 = omc_Types_isArray(threadData, omc_Expression_typeof(threadData, _e));
if (0 != tmp546) goto goto_2;
_i = listLength(_es);
tmpMeta548 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_i));
tmpMeta547 = mmc_mk_cons(tmpMeta548, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta549 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _tp, tmpMeta547);
_tp = tmpMeta549;
tmpMeta550 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(1), _es);
tmpMeta1 = tmpMeta550;
goto tmp3_done;
}
case 48: {
modelica_metatype tmpMeta551;
modelica_metatype tmpMeta552;
modelica_metatype tmpMeta553;
modelica_metatype tmpMeta554;
modelica_metatype tmpMeta555;
modelica_metatype tmpMeta556;
modelica_integer tmp557;
modelica_metatype tmpMeta558;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta551 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta551,1,1) == 0) goto tmp3_end;
tmpMeta552 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta551), 2));
if (6 != MMC_STRLEN(tmpMeta552) || strcmp(MMC_STRINGDATA(_OMC_LIT118), MMC_STRINGDATA(tmpMeta552)) != 0) goto tmp3_end;
tmpMeta553 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta553)) goto tmp3_end;
tmpMeta554 = MMC_CAR(tmpMeta553);
tmpMeta555 = MMC_CDR(tmpMeta553);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta554,16,3) == 0) goto tmp3_end;
tmpMeta556 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta554), 3));
tmp557 = mmc_unbox_integer(tmpMeta556);
if (1 != tmp557) goto tmp3_end;
if (!listEmpty(tmpMeta555)) goto tmp3_end;
tmpMeta558 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta554;
tmp4 += 1;
tmpMeta1 = _e;
goto tmp3_done;
}
case 49: {
modelica_metatype tmpMeta559;
modelica_metatype tmpMeta560;
modelica_metatype tmpMeta561;
modelica_metatype tmpMeta562;
modelica_metatype tmpMeta563;
modelica_metatype tmpMeta564;
modelica_metatype tmpMeta565;
modelica_metatype tmpMeta566;
modelica_metatype tmpMeta567;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta559 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta559,1,1) == 0) goto tmp3_end;
tmpMeta560 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta559), 2));
if (6 != MMC_STRLEN(tmpMeta560) || strcmp(MMC_STRINGDATA(_OMC_LIT118), MMC_STRINGDATA(tmpMeta560)) != 0) goto tmp3_end;
tmpMeta561 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta561)) goto tmp3_end;
tmpMeta562 = MMC_CAR(tmpMeta561);
tmpMeta563 = MMC_CDR(tmpMeta561);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta562,17,3) == 0) goto tmp3_end;
tmpMeta564 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta562), 4));
if (!listEmpty(tmpMeta563)) goto tmp3_end;
tmpMeta565 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta566 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta565), 2));
_mexpl = tmpMeta564;
_tp = tmpMeta566;
tmp4 += 7;
_es = omc_List_flatten(threadData, _mexpl);
_es = omc_List_map1(threadData, _es, boxvar_Expression_makeVectorCall, _tp);
tmpMeta567 = mmc_mk_cons(_OMC_LIT85, _es);
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT99, tmpMeta567, _tp);
goto tmp3_done;
}
case 50: {
modelica_metatype tmpMeta568;
modelica_metatype tmpMeta569;
modelica_metatype tmpMeta570;
modelica_metatype tmpMeta571;
modelica_metatype tmpMeta572;
modelica_metatype tmpMeta573;
modelica_metatype tmpMeta574;
modelica_metatype tmpMeta575;
modelica_metatype tmpMeta576;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta568 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta568,1,1) == 0) goto tmp3_end;
tmpMeta569 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta568), 2));
if (6 != MMC_STRLEN(tmpMeta569) || strcmp(MMC_STRINGDATA(_OMC_LIT118), MMC_STRINGDATA(tmpMeta569)) != 0) goto tmp3_end;
tmpMeta570 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta570)) goto tmp3_end;
tmpMeta571 = MMC_CAR(tmpMeta570);
tmpMeta572 = MMC_CDR(tmpMeta570);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta571,16,3) == 0) goto tmp3_end;
tmpMeta573 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta571), 4));
if (!listEmpty(tmpMeta572)) goto tmp3_end;
tmpMeta574 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta575 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta574), 2));
_es = tmpMeta573;
_tp = tmpMeta575;
tmp4 += 6;
_es = omc_List_map1(threadData, _es, boxvar_Expression_makeVectorCall, _tp);
tmpMeta576 = mmc_mk_cons(_OMC_LIT85, _es);
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT99, tmpMeta576, _tp);
goto tmp3_done;
}
case 51: {
modelica_metatype tmpMeta577;
modelica_metatype tmpMeta578;
modelica_metatype tmpMeta579;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta577 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta577,1,1) == 0) goto tmp3_end;
tmpMeta578 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta577), 2));
if (13 != MMC_STRLEN(tmpMeta578) || strcmp(MMC_STRINGDATA(_OMC_LIT119), MMC_STRINGDATA(tmpMeta578)) != 0) goto tmp3_end;
tmpMeta579 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta579)) goto tmp3_end;
tmp4 += 5;
tmpMeta1 = _OMC_LIT102;
goto tmp3_done;
}
case 52: {
modelica_metatype tmpMeta580;
modelica_metatype tmpMeta581;
modelica_metatype tmpMeta582;
modelica_metatype tmpMeta583;
modelica_metatype tmpMeta584;
modelica_metatype tmpMeta585;
modelica_metatype tmpMeta586;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta580 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta580,1,1) == 0) goto tmp3_end;
tmpMeta581 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta580), 2));
if (9 != MMC_STRLEN(tmpMeta581) || strcmp(MMC_STRINGDATA(_OMC_LIT120), MMC_STRINGDATA(tmpMeta581)) != 0) goto tmp3_end;
tmpMeta582 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta582)) goto tmp3_end;
tmpMeta583 = MMC_CAR(tmpMeta582);
tmpMeta584 = MMC_CDR(tmpMeta582);
if (!listEmpty(tmpMeta584)) goto tmp3_end;
_e1 = tmpMeta583;
tmp4 += 4;
tmpMeta585 = mmc_mk_box2(5, &DAE_ClockKind_REAL__CLOCK__desc, _e1);
tmpMeta586 = mmc_mk_box2(7, &DAE_Exp_CLKCONST__desc, tmpMeta585);
tmpMeta1 = tmpMeta586;
goto tmp3_done;
}
case 53: {
modelica_metatype tmpMeta587;
modelica_metatype tmpMeta588;
modelica_metatype tmpMeta589;
modelica_metatype tmpMeta590;
modelica_metatype tmpMeta591;
modelica_metatype tmpMeta592;
modelica_metatype tmpMeta593;
modelica_metatype tmpMeta594;
modelica_metatype tmpMeta595;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta587 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta587,1,1) == 0) goto tmp3_end;
tmpMeta588 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta587), 2));
if (12 != MMC_STRLEN(tmpMeta588) || strcmp(MMC_STRINGDATA(_OMC_LIT121), MMC_STRINGDATA(tmpMeta588)) != 0) goto tmp3_end;
tmpMeta589 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta589)) goto tmp3_end;
tmpMeta590 = MMC_CAR(tmpMeta589);
tmpMeta591 = MMC_CDR(tmpMeta589);
if (listEmpty(tmpMeta591)) goto tmp3_end;
tmpMeta592 = MMC_CAR(tmpMeta591);
tmpMeta593 = MMC_CDR(tmpMeta591);
if (!listEmpty(tmpMeta593)) goto tmp3_end;
_e1 = tmpMeta590;
_e2 = tmpMeta592;
tmp4 += 3;
tmpMeta594 = mmc_mk_box3(6, &DAE_ClockKind_BOOLEAN__CLOCK__desc, _e1, _e2);
tmpMeta595 = mmc_mk_box2(7, &DAE_Exp_CLKCONST__desc, tmpMeta594);
tmpMeta1 = tmpMeta595;
goto tmp3_done;
}
case 54: {
modelica_metatype tmpMeta596;
modelica_metatype tmpMeta597;
modelica_metatype tmpMeta598;
modelica_metatype tmpMeta599;
modelica_metatype tmpMeta600;
modelica_metatype tmpMeta601;
modelica_metatype tmpMeta602;
modelica_metatype tmpMeta603;
modelica_metatype tmpMeta604;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta596 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta596,1,1) == 0) goto tmp3_end;
tmpMeta597 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta596), 2));
if (13 != MMC_STRLEN(tmpMeta597) || strcmp(MMC_STRINGDATA(_OMC_LIT122), MMC_STRINGDATA(tmpMeta597)) != 0) goto tmp3_end;
tmpMeta598 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta598)) goto tmp3_end;
tmpMeta599 = MMC_CAR(tmpMeta598);
tmpMeta600 = MMC_CDR(tmpMeta598);
if (listEmpty(tmpMeta600)) goto tmp3_end;
tmpMeta601 = MMC_CAR(tmpMeta600);
tmpMeta602 = MMC_CDR(tmpMeta600);
if (!listEmpty(tmpMeta602)) goto tmp3_end;
_e1 = tmpMeta599;
_e2 = tmpMeta601;
tmp4 += 2;
tmpMeta603 = mmc_mk_box3(4, &DAE_ClockKind_INTEGER__CLOCK__desc, _e1, _e2);
tmpMeta604 = mmc_mk_box2(7, &DAE_Exp_CLKCONST__desc, tmpMeta603);
tmpMeta1 = tmpMeta604;
goto tmp3_done;
}
case 55: {
modelica_metatype tmpMeta605;
modelica_metatype tmpMeta606;
modelica_metatype tmpMeta607;
modelica_metatype tmpMeta608;
modelica_metatype tmpMeta609;
modelica_metatype tmpMeta610;
modelica_metatype tmpMeta611;
modelica_metatype tmpMeta612;
modelica_metatype tmpMeta613;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta605 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta605,1,1) == 0) goto tmp3_end;
tmpMeta606 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta605), 2));
if (11 != MMC_STRLEN(tmpMeta606) || strcmp(MMC_STRINGDATA(_OMC_LIT123), MMC_STRINGDATA(tmpMeta606)) != 0) goto tmp3_end;
tmpMeta607 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta607)) goto tmp3_end;
tmpMeta608 = MMC_CAR(tmpMeta607);
tmpMeta609 = MMC_CDR(tmpMeta607);
if (listEmpty(tmpMeta609)) goto tmp3_end;
tmpMeta610 = MMC_CAR(tmpMeta609);
tmpMeta611 = MMC_CDR(tmpMeta609);
if (!listEmpty(tmpMeta611)) goto tmp3_end;
_e1 = tmpMeta608;
_e2 = tmpMeta610;
tmp4 += 1;
tmpMeta612 = mmc_mk_box3(7, &DAE_ClockKind_SOLVER__CLOCK__desc, _e1, _e2);
tmpMeta613 = mmc_mk_box2(7, &DAE_Exp_CLKCONST__desc, tmpMeta612);
tmpMeta1 = tmpMeta613;
goto tmp3_done;
}
case 56: {
modelica_metatype tmpMeta614;
modelica_metatype tmpMeta615;
modelica_metatype tmpMeta616;
modelica_metatype tmpMeta617;
modelica_metatype tmpMeta618;
modelica_metatype tmpMeta619;
modelica_metatype tmpMeta620;
modelica_metatype tmpMeta621;
modelica_metatype tmpMeta622;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta614 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta614,1,1) == 0) goto tmp3_end;
tmpMeta615 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta614), 2));
if (26 != MMC_STRLEN(tmpMeta615) || strcmp(MMC_STRINGDATA(_OMC_LIT124), MMC_STRINGDATA(tmpMeta615)) != 0) goto tmp3_end;
tmpMeta616 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta616)) goto tmp3_end;
tmpMeta617 = MMC_CAR(tmpMeta616);
tmpMeta618 = MMC_CDR(tmpMeta616);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta617,2,1) == 0) goto tmp3_end;
tmpMeta619 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta617), 2));
if (!listEmpty(tmpMeta618)) goto tmp3_end;
_s1 = tmpMeta619;
_s2 = OpenModelica__uriToFilename(_s1);
if(omc_Flags_getConfigBool(threadData, _OMC_LIT108))
{
tmpMeta621 = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _s2);
tmpMeta620 = mmc_mk_cons(tmpMeta621, MMC_REFSTRUCTLIT(mmc_nil));
_e = omc_Expression_makeImpureBuiltinCall(threadData, _OMC_LIT103, tmpMeta620, _OMC_LIT72);
}
else
{
tmpMeta622 = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _s2);
_e = tmpMeta622;
}
tmpMeta1 = _e;
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
if (++tmp4 < 57) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_reductionExpression(threadData_t *threadData, modelica_string _name, modelica_metatype _ty, modelica_string _foldName, modelica_string _resultName)
{
modelica_metatype _foldExp = NULL;
modelica_metatype _foldNameExp = NULL;
modelica_metatype _resultNameExp = NULL;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
_foldNameExp = omc_Expression_makeCrefExp(threadData, omc_ComponentReference_makeCrefIdent(threadData, _foldName, _ty, tmpMeta1), _ty);
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
_resultNameExp = omc_Expression_makeCrefExp(threadData, omc_ComponentReference_makeCrefIdent(threadData, _resultName, _ty, tmpMeta2), _ty);
{
modelica_string tmp6_1;
tmp6_1 = _name;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 4; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
modelica_metatype tmpMeta8;
if (3 != MMC_STRLEN(tmp6_1) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmp6_1)) != 0) goto tmp5_end;
tmpMeta8 = mmc_mk_cons(_foldNameExp, mmc_mk_cons(_resultNameExp, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta3 = omc_Expression_makeBuiltinCall(threadData, _OMC_LIT7, tmpMeta8, _ty, 0);
goto tmp5_done;
}
case 1: {
modelica_metatype tmpMeta9;
if (3 != MMC_STRLEN(tmp6_1) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmp6_1)) != 0) goto tmp5_end;
tmpMeta9 = mmc_mk_cons(_foldNameExp, mmc_mk_cons(_resultNameExp, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta3 = omc_Expression_makeBuiltinCall(threadData, _OMC_LIT8, tmpMeta9, _ty, 0);
goto tmp5_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (7 != MMC_STRLEN(tmp6_1) || strcmp(MMC_STRINGDATA(_OMC_LIT125), MMC_STRINGDATA(tmp6_1)) != 0) goto tmp5_end;
tmpMeta10 = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta11 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _foldNameExp, tmpMeta10, _resultNameExp);
tmpMeta3 = tmpMeta11;
goto tmp5_done;
}
case 3: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
if (3 != MMC_STRLEN(tmp6_1) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmp6_1)) != 0) goto tmp5_end;
tmpMeta12 = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta13 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _foldNameExp, tmpMeta12, _resultNameExp);
tmpMeta3 = tmpMeta13;
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
_foldExp = tmpMeta3;
_return: OMC_LABEL_UNUSED
return _foldExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_reductionDefaultValue(threadData_t *threadData, modelica_string _name, modelica_metatype _ty)
{
modelica_metatype _defaultValue = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_string tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _name;
tmp4_2 = _ty;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 12; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT126;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta6 = mmc_mk_box2(3, &Values_Value_INTEGER__desc, mmc_mk_integer(intMaxLit()));
tmpMeta1 = tmpMeta6;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta7;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta7 = mmc_mk_box2(4, &Values_Value_REAL__desc, mmc_mk_real(realMaxLit()));
tmpMeta1 = tmpMeta7;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta8;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,5) == 0) goto tmp3_end;
tmpMeta8 = mmc_mk_box3(7, &Values_Value_ENUM__LITERAL__desc, omc_AbsynUtil_suffixPath(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 3))), omc_List_last(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 4))))), mmc_mk_integer(listLength((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 4))))));
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 4: {
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT127;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta9;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta9 = mmc_mk_box2(3, &Values_Value_INTEGER__desc, mmc_mk_integer((-intMaxLit())));
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta10;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta10 = mmc_mk_box2(4, &Values_Value_REAL__desc, mmc_mk_real((-realMaxLit())));
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta11;
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,5,5) == 0) goto tmp3_end;
tmpMeta11 = mmc_mk_box3(7, &Values_Value_ENUM__LITERAL__desc, omc_AbsynUtil_suffixPath(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 3))), omc_List_last(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 4))))), mmc_mk_integer(((modelica_integer) 1)));
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 8: {
if (7 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT125), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT128;
goto tmp3_done;
}
case 9: {
if (7 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT125), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT129;
goto tmp3_done;
}
case 10: {
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,0,1) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT130;
goto tmp3_done;
}
case 11: {
if (3 != MMC_STRLEN(tmp4_1) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmp4_1)) != 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
tmpMeta1 = _OMC_LIT131;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_defaultValue = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _defaultValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_addCast(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inType)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _inType, _inExp);
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCast(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _exp, modelica_metatype _tp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _exp;
tmp4_2 = _tp;
{
modelica_real _r;
modelica_integer _i;
modelica_integer _n;
modelica_boolean _b;
modelica_metatype _exps = NULL;
modelica_metatype _exps_1 = NULL;
modelica_metatype _tp_1 = NULL;
modelica_metatype _tp1 = NULL;
modelica_metatype _tp2 = NULL;
modelica_metatype _t1 = NULL;
modelica_metatype _t2 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _e1_1 = NULL;
modelica_metatype _e2_1 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _mexps = NULL;
modelica_metatype _mexps_1 = NULL;
modelica_metatype _eo = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
modelica_metatype _p3 = NULL;
modelica_metatype _fieldNames = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 14; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_real tmp7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_real(tmpMeta6);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
_r = tmp7;
tmpMeta8 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta8;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta9;
modelica_integer tmp10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp10 = mmc_unbox_integer(tmpMeta9);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,1) == 0) goto tmp3_end;
_i = tmp10;
_r = ((modelica_real)_i);
tmpMeta11 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta1 = tmpMeta11;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,6,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta13;
tmpMeta14 = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp, _e);
_e = tmpMeta14;
tmpMeta15 = mmc_mk_box2(9, &DAE_Operator_UMINUS__ARR__desc, _tp);
tmpMeta16 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta15, _e);
tmpMeta1 = tmpMeta16;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,5,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta18;
tmpMeta19 = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp, _e);
_e = tmpMeta19;
tmpMeta20 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _tp);
tmpMeta21 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta20, _e);
tmpMeta1 = tmpMeta21;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta22;
modelica_integer tmp23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,3) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp23 = mmc_unbox_integer(tmpMeta22);
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_b = tmp23;
_exps = tmpMeta24;
_tp_1 = omc_Expression_unliftArray(threadData, _tp);
_exps_1 = omc_List_map1(threadData, _exps, boxvar_ExpressionSimplify_addCast, _tp_1);
tmpMeta25 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(_b), _exps_1);
tmpMeta1 = tmpMeta25;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,2) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,1,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,18,4) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,6,2) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta28,0,1) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_tp2 = tmpMeta26;
_e1 = tmpMeta29;
_eo = tmpMeta30;
_e2 = tmpMeta31;
tmpMeta32 = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp2, _e1);
_e1 = tmpMeta32;
tmpMeta33 = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp2, _e2);
_e2 = tmpMeta33;
_eo = omc_Util_applyOption1(threadData, _eo, boxvar_ExpressionSimplify_addCast, _tp2);
tmpMeta34 = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, _tp, _e1, _eo, _e2);
tmpMeta1 = tmpMeta34;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_metatype tmpMeta37;
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,3) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta37 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_cond = tmpMeta35;
_e1 = tmpMeta36;
_e2 = tmpMeta37;
tmpMeta38 = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp, _e1);
_e1_1 = tmpMeta38;
tmpMeta39 = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp, _e2);
_e2_1 = tmpMeta39;
tmpMeta40 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _cond, _e1_1, _e2_1);
tmpMeta1 = tmpMeta40;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta41;
modelica_integer tmp42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,3) == 0) goto tmp3_end;
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp42 = mmc_unbox_integer(tmpMeta41);
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_n = tmp42;
_mexps = tmpMeta43;
_tp1 = omc_Expression_unliftArray(threadData, _tp);
_tp2 = omc_Expression_unliftArray(threadData, _tp1);
_mexps_1 = omc_List_map1List(threadData, _mexps, boxvar_ExpressionSimplify_addCast, _tp2);
tmpMeta44 = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _tp, mmc_mk_integer(_n), _mexps_1);
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,3) == 0) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta45,3,1) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta45), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta50 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta50,9,3) == 0) goto tmp3_end;
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta51,3,1) == 0) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta51), 2));
_p3 = tmpMeta46;
_p1 = tmpMeta47;
_exps = tmpMeta48;
_p2 = tmpMeta52;
if (!omc_AbsynUtil_pathEqual(threadData, _p1, _p2)) goto tmp3_end;
tmpMeta53 = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _tp, mmc_mk_boolean(0), mmc_mk_boolean(0), mmc_mk_boolean(0), mmc_mk_boolean(0), _OMC_LIT132, _OMC_LIT133);
tmpMeta54 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _p3, _exps, tmpMeta53);
tmpMeta1 = tmpMeta54;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta55;
modelica_metatype tmpMeta56;
modelica_metatype tmpMeta57;
modelica_metatype tmpMeta58;
modelica_metatype tmpMeta59;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,4) == 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,9,3) == 0) goto tmp3_end;
tmpMeta57 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta57,3,1) == 0) goto tmp3_end;
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta57), 2));
_exps = tmpMeta55;
_fieldNames = tmpMeta56;
_p3 = tmpMeta58;
tmpMeta59 = mmc_mk_box5(17, &DAE_Exp_RECORD__desc, _p3, _exps, _fieldNames, _tp);
tmpMeta1 = tmpMeta59;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta60,1,1) == 0) goto tmp3_end;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta60), 2));
if (4 != MMC_STRLEN(tmpMeta61) || strcmp(MMC_STRINGDATA(_OMC_LIT111), MMC_STRINGDATA(tmpMeta61)) != 0) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta62)) goto tmp3_end;
tmpMeta63 = MMC_CAR(tmpMeta62);
tmpMeta64 = MMC_CDR(tmpMeta62);
_e = tmpMeta63;
_exps = tmpMeta64;
_tp_1 = omc_List_fold(threadData, _exps, boxvar_Expression_unliftArrayIgnoreFirst, _tp);
tmpMeta65 = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp_1, _e);
_e = tmpMeta65;
tmpMeta66 = mmc_mk_cons(_e, _exps);
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT111, tmpMeta66, _tp);
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_integer tmp74;
modelica_metatype tmpMeta75;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,6,2) == 0) goto tmp3_end;
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta68,1,1) == 0) goto tmp3_end;
tmpMeta69 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta68), 2));
if (3 != MMC_STRLEN(tmpMeta69) || strcmp(MMC_STRINGDATA(_OMC_LIT99), MMC_STRINGDATA(tmpMeta69)) != 0) goto tmp3_end;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta70)) goto tmp3_end;
tmpMeta71 = MMC_CAR(tmpMeta70);
tmpMeta72 = MMC_CDR(tmpMeta70);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta71,0,1) == 0) goto tmp3_end;
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta71), 2));
tmp74 = mmc_unbox_integer(tmpMeta73);
_dims = tmpMeta67;
_e = tmpMeta71;
_n = tmp74;
_exps = tmpMeta72;
if (!omc_Expression_dimensionUnknown(threadData, listGet(_dims, _n))) goto tmp3_end;
_exps = omc_List_map1(threadData, _exps, boxvar_ExpressionSimplify_addCast, _tp);
tmpMeta75 = mmc_mk_cons(_e, _exps);
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT99, tmpMeta75, _tp);
goto tmp3_done;
}
case 12: {
_e = tmp4_1;
_t1 = omc_Expression_arrayEltType(threadData, _tp);
_t2 = omc_Expression_arrayEltType(threadData, omc_Expression_typeof(threadData, _e));
tmpMeta1 = (valueEq(_t1, _t2)?_e:_origExp);
goto tmp3_done;
}
case 13: {
tmpMeta1 = _origExp;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatch(threadData_t *threadData, modelica_metatype _exp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e1_1 = NULL;
modelica_metatype _e2_1 = NULL;
modelica_boolean _b1;
modelica_boolean _b2;
modelica_metatype _ty = NULL;
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
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,33,6) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (!listEmpty(tmpMeta6)) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (!listEmpty(tmpMeta7)) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (!listEmpty(tmpMeta11)) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
if (!listEmpty(tmpMeta12)) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 5));
if (!listEmpty(tmpMeta13)) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 6));
if (optionNone(tmpMeta14)) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 1));
if (!listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_e = tmpMeta15;
_ty = tmpMeta16;
if (!(!omc_Types_isTuple(threadData, _ty))) goto tmp3_end;
tmpMeta1 = _e;
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
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_integer tmp29;
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
modelica_integer tmp41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_metatype tmpMeta44;
modelica_metatype tmpMeta45;
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,33,6) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta17)) goto tmp3_end;
tmpMeta18 = MMC_CAR(tmpMeta17);
tmpMeta19 = MMC_CDR(tmpMeta17);
if (!listEmpty(tmpMeta19)) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (!listEmpty(tmpMeta20)) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (listEmpty(tmpMeta21)) goto tmp3_end;
tmpMeta22 = MMC_CAR(tmpMeta21);
tmpMeta23 = MMC_CDR(tmpMeta21);
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
if (listEmpty(tmpMeta24)) goto tmp3_end;
tmpMeta25 = MMC_CAR(tmpMeta24);
tmpMeta26 = MMC_CDR(tmpMeta24);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,1,2) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta27,3,1) == 0) goto tmp3_end;
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta27), 2));
tmp29 = mmc_unbox_integer(tmpMeta28);
if (!listEmpty(tmpMeta26)) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 4));
if (!listEmpty(tmpMeta30)) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 5));
if (!listEmpty(tmpMeta31)) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 6));
if (optionNone(tmpMeta32)) goto tmp3_end;
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta32), 1));
if (listEmpty(tmpMeta23)) goto tmp3_end;
tmpMeta34 = MMC_CAR(tmpMeta23);
tmpMeta35 = MMC_CDR(tmpMeta23);
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 2));
if (listEmpty(tmpMeta36)) goto tmp3_end;
tmpMeta37 = MMC_CAR(tmpMeta36);
tmpMeta38 = MMC_CDR(tmpMeta36);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta37,1,2) == 0) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,3,1) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 2));
tmp41 = mmc_unbox_integer(tmpMeta40);
if (!listEmpty(tmpMeta38)) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 4));
if (!listEmpty(tmpMeta42)) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 5));
if (!listEmpty(tmpMeta43)) goto tmp3_end;
tmpMeta44 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 6));
if (optionNone(tmpMeta44)) goto tmp3_end;
tmpMeta45 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta44), 1));
if (!listEmpty(tmpMeta35)) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_e = tmpMeta18;
_b1 = tmp29;
_e1 = tmpMeta33;
_b2 = tmp41;
_e2 = tmpMeta45;
_ty = tmpMeta46;
if (!((!((!_b1 && !_b2) || (_b1 && _b2))) && (!omc_Types_isTuple(threadData, _ty)))) goto tmp3_end;
_e1_1 = (_b1?_e1:_e2);
_e2_1 = (_b1?_e2:_e1);
tmpMeta47 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _e, _e1_1, _e2_1);
tmpMeta1 = tmpMeta47;
goto tmp3_done;
}
case 2: {
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
modelica_integer tmp61;
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
modelica_metatype tmpMeta76;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,33,6) == 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta48,2,1) == 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta49)) goto tmp3_end;
tmpMeta50 = MMC_CAR(tmpMeta49);
tmpMeta51 = MMC_CDR(tmpMeta49);
if (!listEmpty(tmpMeta51)) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (!listEmpty(tmpMeta52)) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (listEmpty(tmpMeta53)) goto tmp3_end;
tmpMeta54 = MMC_CAR(tmpMeta53);
tmpMeta55 = MMC_CDR(tmpMeta53);
tmpMeta56 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 2));
if (listEmpty(tmpMeta56)) goto tmp3_end;
tmpMeta57 = MMC_CAR(tmpMeta56);
tmpMeta58 = MMC_CDR(tmpMeta56);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta57,1,2) == 0) goto tmp3_end;
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta57), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta59,3,1) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta59), 2));
tmp61 = mmc_unbox_integer(tmpMeta60);
if (!listEmpty(tmpMeta58)) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 4));
if (!listEmpty(tmpMeta62)) goto tmp3_end;
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 5));
if (!listEmpty(tmpMeta63)) goto tmp3_end;
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta54), 6));
if (optionNone(tmpMeta64)) goto tmp3_end;
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta64), 1));
if (listEmpty(tmpMeta55)) goto tmp3_end;
tmpMeta66 = MMC_CAR(tmpMeta55);
tmpMeta67 = MMC_CDR(tmpMeta55);
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta66), 2));
if (listEmpty(tmpMeta68)) goto tmp3_end;
tmpMeta69 = MMC_CAR(tmpMeta68);
tmpMeta70 = MMC_CDR(tmpMeta68);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta69,0,0) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta70)) goto tmp3_end;
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta66), 4));
if (!listEmpty(tmpMeta71)) goto tmp3_end;
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta66), 5));
if (!listEmpty(tmpMeta72)) goto tmp3_end;
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta66), 6));
if (optionNone(tmpMeta73)) goto tmp3_end;
tmpMeta74 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta73), 1));
if (!listEmpty(tmpMeta67)) goto tmp3_end;
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_e = tmpMeta50;
_b1 = tmp61;
_e1 = tmpMeta65;
_e2 = tmpMeta74;
_ty = tmpMeta75;
if (!(!omc_Types_isTuple(threadData, _ty))) goto tmp3_end;
_e1_1 = (_b1?_e1:_e2);
_e2_1 = (_b1?_e2:_e1);
tmpMeta76 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _e, _e1_1, _e2_1);
tmpMeta1 = tmpMeta76;
goto tmp3_done;
}
case 3: {
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyUnbox(threadData_t *threadData, modelica_metatype _exp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,35,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,34,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
_outExp = tmpMeta7;
tmpMeta1 = _outExp;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,34,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,35,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
_outExp = tmpMeta9;
tmpMeta1 = _outExp;
goto tmp3_done;
}
case 2: {
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCons(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _e = NULL;
modelica_metatype _es = NULL;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,29,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta7,28,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta7), 2));
_e = tmpMeta6;
_es = tmpMeta8;
tmpMeta9 = mmc_mk_cons(_e, _es);
tmpMeta10 = mmc_mk_box2(31, &DAE_Exp_LIST__desc, tmpMeta9);
tmpMeta1 = tmpMeta10;
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inExp;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMetaModelicaCalls(threadData_t *threadData, modelica_metatype _exp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_boolean _b;
modelica_metatype _el = NULL;
modelica_integer _i;
modelica_real _r;
modelica_string _s = NULL;
modelica_metatype _foldExp = NULL;
modelica_metatype _v = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _riters = NULL;
modelica_string _foldName = NULL;
modelica_string _resultName = NULL;
modelica_metatype _rit = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 11; tmp4++) {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
if (10 != MMC_STRLEN(tmpMeta7) || strcmp(MMC_STRINGDATA(_OMC_LIT139), MMC_STRINGDATA(tmpMeta7)) != 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,28,1) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
if (listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta12 = MMC_CAR(tmpMeta10);
tmpMeta13 = MMC_CDR(tmpMeta10);
if (!listEmpty(tmpMeta13)) goto tmp3_end;
_el = tmpMeta11;
_e2 = tmpMeta12;
tmpMeta1 = omc_List_fold(threadData, listReverse(_el), boxvar_Expression_makeCons, _e2);
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta14,1,1) == 0) goto tmp3_end;
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta14), 2));
if (10 != MMC_STRLEN(tmpMeta15) || strcmp(MMC_STRINGDATA(_OMC_LIT139), MMC_STRINGDATA(tmpMeta15)) != 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta16)) goto tmp3_end;
tmpMeta17 = MMC_CAR(tmpMeta16);
tmpMeta18 = MMC_CDR(tmpMeta16);
if (listEmpty(tmpMeta18)) goto tmp3_end;
tmpMeta19 = MMC_CAR(tmpMeta18);
tmpMeta20 = MMC_CDR(tmpMeta18);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta19,28,1) == 0) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta19), 2));
if (!listEmpty(tmpMeta21)) goto tmp3_end;
if (!listEmpty(tmpMeta20)) goto tmp3_end;
_e1 = tmpMeta17;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_integer tmp28;
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,1,1) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
if (9 != MMC_STRLEN(tmpMeta23) || strcmp(MMC_STRINGDATA(_OMC_LIT140), MMC_STRINGDATA(tmpMeta23)) != 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta24)) goto tmp3_end;
tmpMeta25 = MMC_CAR(tmpMeta24);
tmpMeta26 = MMC_CDR(tmpMeta24);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,0,1) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
tmp28 = mmc_unbox_integer(tmpMeta27);
if (!listEmpty(tmpMeta26)) goto tmp3_end;
_i = tmp28;
_s = intString(_i);
tmpMeta29 = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _s);
tmpMeta1 = tmpMeta29;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_real tmp36;
modelica_metatype tmpMeta37;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta30,1,1) == 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta30), 2));
if (10 != MMC_STRLEN(tmpMeta31) || strcmp(MMC_STRINGDATA(_OMC_LIT141), MMC_STRINGDATA(tmpMeta31)) != 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta32)) goto tmp3_end;
tmpMeta33 = MMC_CAR(tmpMeta32);
tmpMeta34 = MMC_CDR(tmpMeta32);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta33,1,1) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta33), 2));
tmp36 = mmc_unbox_real(tmpMeta35);
if (!listEmpty(tmpMeta34)) goto tmp3_end;
_r = tmp36;
_s = realString(_r);
tmpMeta37 = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _s);
tmpMeta1 = tmpMeta37;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta38;
modelica_metatype tmpMeta39;
modelica_metatype tmpMeta40;
modelica_metatype tmpMeta41;
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_integer tmp44;
modelica_metatype tmpMeta45;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta38 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta38,1,1) == 0) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta38), 2));
if (10 != MMC_STRLEN(tmpMeta39) || strcmp(MMC_STRINGDATA(_OMC_LIT142), MMC_STRINGDATA(tmpMeta39)) != 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta40)) goto tmp3_end;
tmpMeta41 = MMC_CAR(tmpMeta40);
tmpMeta42 = MMC_CDR(tmpMeta40);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta41,3,1) == 0) goto tmp3_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta41), 2));
tmp44 = mmc_unbox_integer(tmpMeta43);
if (!listEmpty(tmpMeta42)) goto tmp3_end;
_b = tmp44;
_s = (_b?_OMC_LIT76:_OMC_LIT77);
tmpMeta45 = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _s);
tmpMeta1 = tmpMeta45;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta46;
modelica_metatype tmpMeta47;
modelica_metatype tmpMeta48;
modelica_metatype tmpMeta49;
modelica_metatype tmpMeta50;
modelica_metatype tmpMeta51;
modelica_metatype tmpMeta52;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta46 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta46,1,1) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta46), 2));
if (11 != MMC_STRLEN(tmpMeta47) || strcmp(MMC_STRINGDATA(_OMC_LIT134), MMC_STRINGDATA(tmpMeta47)) != 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta48)) goto tmp3_end;
tmpMeta49 = MMC_CAR(tmpMeta48);
tmpMeta50 = MMC_CDR(tmpMeta48);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta49,28,1) == 0) goto tmp3_end;
tmpMeta51 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta49), 2));
if (!listEmpty(tmpMeta50)) goto tmp3_end;
_el = tmpMeta51;
_el = listReverse(_el);
tmpMeta52 = mmc_mk_box2(31, &DAE_Exp_LIST__desc, _el);
tmpMeta1 = tmpMeta52;
goto tmp3_done;
}
case 6: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta53,1,1) == 0) goto tmp3_end;
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta53), 2));
if (11 != MMC_STRLEN(tmpMeta54) || strcmp(MMC_STRINGDATA(_OMC_LIT134), MMC_STRINGDATA(tmpMeta54)) != 0) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta55)) goto tmp3_end;
tmpMeta56 = MMC_CAR(tmpMeta55);
tmpMeta57 = MMC_CDR(tmpMeta55);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta56,27,3) == 0) goto tmp3_end;
tmpMeta58 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta56), 2));
tmpMeta59 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta58), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta59,1,1) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta59), 2));
if (4 != MMC_STRLEN(tmpMeta60) || strcmp(MMC_STRINGDATA(_OMC_LIT136), MMC_STRINGDATA(tmpMeta60)) != 0) goto tmp3_end;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta58), 3));
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta58), 4));
tmpMeta63 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta58), 5));
tmpMeta64 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta58), 6));
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta58), 7));
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta58), 8));
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta56), 3));
tmpMeta68 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta56), 4));
if (!listEmpty(tmpMeta57)) goto tmp3_end;
_rit = tmpMeta61;
_ty = tmpMeta62;
_v = tmpMeta63;
_foldName = tmpMeta64;
_resultName = tmpMeta65;
_foldExp = tmpMeta66;
_e1 = tmpMeta67;
_riters = tmpMeta68;
tmpMeta69 = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _OMC_LIT135, _rit, _ty, _v, _foldName, _resultName, _foldExp);
tmpMeta70 = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta69, _e1, _riters);
tmpMeta1 = tmpMeta70;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta71;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta71,1,1) == 0) goto tmp3_end;
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta71), 2));
if (11 != MMC_STRLEN(tmpMeta72) || strcmp(MMC_STRINGDATA(_OMC_LIT134), MMC_STRINGDATA(tmpMeta72)) != 0) goto tmp3_end;
tmpMeta73 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta73)) goto tmp3_end;
tmpMeta74 = MMC_CAR(tmpMeta73);
tmpMeta75 = MMC_CDR(tmpMeta73);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta74,27,3) == 0) goto tmp3_end;
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 2));
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta76), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta77,1,1) == 0) goto tmp3_end;
tmpMeta78 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta77), 2));
if (11 != MMC_STRLEN(tmpMeta78) || strcmp(MMC_STRINGDATA(_OMC_LIT134), MMC_STRINGDATA(tmpMeta78)) != 0) goto tmp3_end;
tmpMeta79 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta76), 3));
tmpMeta80 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta76), 4));
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta76), 5));
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta76), 6));
tmpMeta83 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta76), 7));
tmpMeta84 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta76), 8));
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 3));
tmpMeta86 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta74), 4));
if (!listEmpty(tmpMeta75)) goto tmp3_end;
_rit = tmpMeta79;
_ty = tmpMeta80;
_v = tmpMeta81;
_foldName = tmpMeta82;
_resultName = tmpMeta83;
_foldExp = tmpMeta84;
_e1 = tmpMeta85;
_riters = tmpMeta86;
tmpMeta87 = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _OMC_LIT137, _rit, _ty, _v, _foldName, _resultName, _foldExp);
tmpMeta88 = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta87, _e1, _riters);
tmpMeta1 = tmpMeta88;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta89 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta89,1,1) == 0) goto tmp3_end;
tmpMeta90 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta89), 2));
if (10 != MMC_STRLEN(tmpMeta90) || strcmp(MMC_STRINGDATA(_OMC_LIT143), MMC_STRINGDATA(tmpMeta90)) != 0) goto tmp3_end;
tmpMeta91 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta91)) goto tmp3_end;
tmpMeta92 = MMC_CAR(tmpMeta91);
tmpMeta93 = MMC_CDR(tmpMeta91);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta92,28,1) == 0) goto tmp3_end;
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta92), 2));
if (!listEmpty(tmpMeta93)) goto tmp3_end;
_el = tmpMeta94;
_i = listLength(_el);
tmpMeta95 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta1 = tmpMeta95;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta96 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta96,1,1) == 0) goto tmp3_end;
tmpMeta97 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta96), 2));
if (11 != MMC_STRLEN(tmpMeta97) || strcmp(MMC_STRINGDATA(_OMC_LIT144), MMC_STRINGDATA(tmpMeta97)) != 0) goto tmp3_end;
tmpMeta98 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta98)) goto tmp3_end;
tmpMeta99 = MMC_CAR(tmpMeta98);
tmpMeta100 = MMC_CDR(tmpMeta98);
if (!listEmpty(tmpMeta100)) goto tmp3_end;
_e = tmpMeta99;
tmpMeta101 = mmc_mk_box2(34, &DAE_Exp_META__OPTION__desc, mmc_mk_some(_e));
tmpMeta1 = tmpMeta101;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta102 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta102,1,1) == 0) goto tmp3_end;
tmpMeta103 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta102), 2));
if (10 != MMC_STRLEN(tmpMeta103) || strcmp(MMC_STRINGDATA(_OMC_LIT145), MMC_STRINGDATA(tmpMeta103)) != 0) goto tmp3_end;
fputs(MMC_STRINGDATA(_OMC_LIT138),stdout);
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyIfExp(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _cond, modelica_metatype _tb, modelica_metatype _fb)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _cond;
tmp4_2 = _tb;
tmp4_3 = _fb;
{
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 6; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta6);
if (1 != tmp7) goto tmp3_end;
tmpMeta1 = _tb;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp9 = mmc_unbox_integer(tmpMeta8);
if (0 != tmp9) goto tmp3_end;
tmpMeta1 = _fb;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_integer tmp11;
modelica_metatype tmpMeta12;
modelica_integer tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp11 = mmc_unbox_integer(tmpMeta10);
if (1 != tmp11) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp13 = mmc_unbox_integer(tmpMeta12);
if (0 != tmp13) goto tmp3_end;
_exp = tmp4_1;
tmpMeta1 = _exp;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta14;
modelica_integer tmp15;
modelica_metatype tmpMeta16;
modelica_integer tmp17;
modelica_metatype tmpMeta18;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp15 = mmc_unbox_integer(tmpMeta14);
if (0 != tmp15) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp17 = mmc_unbox_integer(tmpMeta16);
if (1 != tmp17) goto tmp3_end;
_exp = tmp4_1;
tmpMeta18 = mmc_mk_box3(13, &DAE_Exp_LUNARY__desc, _OMC_LIT146, _exp);
tmpMeta1 = tmpMeta18;
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,34,1) == 0) goto tmp3_end;
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,34,1) == 0) goto tmp3_end;
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_e1 = tmpMeta19;
_e2 = tmpMeta20;
_e = tmp4_1;
tmpMeta21 = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _e, _e1, _e2);
_e = tmpMeta21;
tmpMeta22 = mmc_mk_box2(37, &DAE_Exp_BOX__desc, _e);
tmpMeta1 = tmpMeta22;
goto tmp3_done;
}
case 5: {
tmpMeta1 = (omc_Expression_expEqual(threadData, _tb, _fb)?_tb:_origExp);
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyReductionIterators(threadData_t *threadData, modelica_metatype _inIters, modelica_metatype _inAcc, modelica_boolean _inChange, modelica_boolean *out_outChange)
{
modelica_metatype _outIters = NULL;
modelica_boolean _outChange;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_boolean tmp4_3;
tmp4_1 = _inIters;
tmp4_2 = _inAcc;
tmp4_3 = _inChange;
{
modelica_string _id = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _iter = NULL;
modelica_metatype _iters = NULL;
modelica_metatype _acc = NULL;
modelica_boolean _change;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_acc = tmp4_2;
_change = tmp4_3;
tmpMeta[0+0] = listReverse(_acc);
tmp1_c1 = _change;
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
modelica_integer tmp13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_CAR(tmp4_1);
tmpMeta7 = MMC_CDR(tmp4_1);
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 3));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 4));
if (optionNone(tmpMeta10)) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta10), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,3,1) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmp13 = mmc_unbox_integer(tmpMeta12);
if (1 != tmp13) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 5));
_id = tmpMeta8;
_exp = tmpMeta9;
_ty = tmpMeta14;
_iters = tmpMeta7;
_acc = tmp4_2;
tmpMeta16 = mmc_mk_box5(3, &DAE_ReductionIterator_REDUCTIONITER__desc, _id, _exp, mmc_mk_none(), _ty);
tmpMeta15 = mmc_mk_cons(tmpMeta16, _acc);
_inIters = _iters;
_inAcc = tmpMeta15;
_inChange = 1;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype tmpMeta21;
modelica_metatype tmpMeta22;
modelica_integer tmp23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta17 = MMC_CAR(tmp4_1);
tmpMeta18 = MMC_CDR(tmp4_1);
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 4));
if (optionNone(tmpMeta20)) goto tmp3_end;
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta20), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta21,3,1) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta21), 2));
tmp23 = mmc_unbox_integer(tmpMeta22);
if (0 != tmp23) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 5));
_id = tmpMeta19;
_ty = tmpMeta24;
tmpMeta26 = mmc_mk_box5(3, &DAE_ReductionIterator_REDUCTIONITER__desc, _id, _OMC_LIT147, mmc_mk_none(), _ty);
tmpMeta25 = mmc_mk_cons(tmpMeta26, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta25;
tmp1_c1 = 1;
goto tmp3_done;
}
case 3: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta27 = MMC_CAR(tmp4_1);
tmpMeta28 = MMC_CDR(tmp4_1);
_iter = tmpMeta27;
_iters = tmpMeta28;
_acc = tmp4_2;
_change = tmp4_3;
tmpMeta29 = mmc_mk_cons(_iter, _acc);
_inIters = _iters;
_inAcc = tmpMeta29;
_inChange = _change;
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
_outIters = tmpMeta[0+0];
_outChange = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outChange) { *out_outChange = _outChange; }
return _outIters;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyReductionIterators(threadData_t *threadData, modelica_metatype _inIters, modelica_metatype _inAcc, modelica_metatype _inChange, modelica_metatype *out_outChange)
{
modelica_integer tmp1;
modelica_boolean _outChange;
modelica_metatype _outIters = NULL;
tmp1 = mmc_unbox_integer(_inChange);
_outIters = omc_ExpressionSimplify_simplifyReductionIterators(threadData, _inIters, _inAcc, tmp1, &_outChange);
if (out_outChange) { *out_outChange = mmc_mk_icon(_outChange); }
return _outIters;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplify1FixP(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inOptions, modelica_integer _n, modelica_boolean _cont, modelica_boolean _hasChanged, modelica_boolean *out_outHasChanged)
{
modelica_metatype _outExp = NULL;
modelica_boolean _outHasChanged;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_integer tmp4_3;modelica_boolean tmp4_4;
tmp4_1 = _inExp;
tmp4_2 = _inOptions;
tmp4_3 = _n;
tmp4_4 = _cont;
{
modelica_metatype _exp = NULL;
modelica_metatype _expAfterSimplify = NULL;
modelica_boolean _b;
modelica_string _str1 = NULL;
modelica_string _str2 = NULL;
modelica_metatype _options = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (0 != tmp4_4) goto tmp3_end;
_exp = tmp4_1;
tmpMeta[0+0] = _exp;
tmp1_c1 = _hasChanged;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
if (0 != tmp4_3) goto tmp3_end;
_exp = tmp4_1;
_options = tmp4_2;
_str1 = omc_ExpressionDump_printExpStr(threadData, _exp);
_exp = omc_Expression_traverseExpBottomUp(threadData, _exp, boxvar_ExpressionSimplify_simplifyWork, _options, NULL);
_str2 = omc_ExpressionDump_printExpStr(threadData, _exp);
tmpMeta6 = mmc_mk_cons(_str1, mmc_mk_cons(_str2, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMessage(threadData, _OMC_LIT151, tmpMeta6);
tmpMeta[0+0] = _exp;
tmp1_c1 = _hasChanged;
goto tmp3_done;
}
case 2: {
if (1 != tmp4_4) goto tmp3_end;
_exp = tmp4_1;
_options = tmp4_2;
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT152);
_expAfterSimplify = omc_Expression_traverseExpBottomUp(threadData, _exp, boxvar_ExpressionSimplify_simplifyWork, _options ,&_options);
_b = (!referenceEq(_expAfterSimplify, _exp));
if(_b)
{
omc_ErrorExt_rollBack(threadData, _OMC_LIT152);
}
else
{
omc_ErrorExt_delCheckpoint(threadData, _OMC_LIT152);
}
_inExp = _expAfterSimplify;
_inOptions = _options;
_n = ((modelica_integer) -1) + _n;
_cont = _b;
_hasChanged = (_b || _hasChanged);
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
_outExp = tmpMeta[0+0];
_outHasChanged = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_outHasChanged) { *out_outHasChanged = _outHasChanged; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplify1FixP(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inOptions, modelica_metatype _n, modelica_metatype _cont, modelica_metatype _hasChanged, modelica_metatype *out_outHasChanged)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_boolean _outHasChanged;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_n);
tmp2 = mmc_unbox_integer(_cont);
tmp3 = mmc_unbox_integer(_hasChanged);
_outExp = omc_ExpressionSimplify_simplify1FixP(threadData, _inExp, _inOptions, tmp1, tmp2, tmp3, &_outHasChanged);
if (out_outHasChanged) { *out_outHasChanged = mmc_mk_icon(_outHasChanged); }
return _outExp;
}
PROTECTED_FUNCTION_STATIC void omc_ExpressionSimplify_checkSimplify(threadData_t *threadData, modelica_boolean _check, modelica_metatype _before, modelica_metatype _after)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;
tmp3_1 = _check;
{
modelica_integer _c1;
modelica_integer _c2;
modelica_boolean _b;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_string _s3 = NULL;
modelica_string _s4 = NULL;
modelica_metatype _ty1 = NULL;
modelica_metatype _ty2 = NULL;
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
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (1 != tmp3_1) goto tmp2_end;
_ty1 = omc_Expression_typeof(threadData, _before);
_ty2 = omc_Expression_typeof(threadData, _after);
_b = valueEq(_ty1, _ty2);
if((!_b))
{
_s1 = omc_ExpressionDump_printExpStr(threadData, _before);
_s2 = omc_ExpressionDump_printExpStr(threadData, _after);
_s3 = omc_Types_unparseType(threadData, _ty1);
_s4 = omc_Types_unparseType(threadData, _ty2);
tmpMeta5 = mmc_mk_cons(_s1, mmc_mk_cons(_s2, mmc_mk_cons(_s3, mmc_mk_cons(_s4, MMC_REFSTRUCTLIT(mmc_nil)))));
omc_Error_addMessage(threadData, _OMC_LIT156, tmpMeta5);
goto goto_1;
}
_c1 = omc_Expression_complexity(threadData, _before);
_c2 = omc_Expression_complexity(threadData, _after);
_b = (_c1 < _c2);
if(_b)
{
_s1 = intString(_c2);
_s2 = intString(_c1);
_s3 = omc_ExpressionDump_printExpStr(threadData, _before);
_s4 = omc_ExpressionDump_printExpStr(threadData, _after);
tmpMeta6 = mmc_mk_cons(_s1, mmc_mk_cons(_s2, mmc_mk_cons(_s3, mmc_mk_cons(_s4, MMC_REFSTRUCTLIT(mmc_nil)))));
omc_Error_addMessage(threadData, _OMC_LIT160, tmpMeta6);
goto goto_1;
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
PROTECTED_FUNCTION_STATIC void boxptr_ExpressionSimplify_checkSimplify(threadData_t *threadData, modelica_metatype _check, modelica_metatype _before, modelica_metatype _after)
{
modelica_integer tmp1;
tmp1 = mmc_unbox_integer(_check);
omc_ExpressionSimplify_checkSimplify(threadData, tmp1, _before, _after);
return;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplify1WithOptions(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _options, modelica_boolean *out_hasChanged)
{
modelica_metatype _outExp = NULL;
modelica_boolean _hasChanged;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = omc_ExpressionSimplify_simplify1FixP(threadData, _inExp, _options, ((modelica_integer) 100), 1, 0 ,&_hasChanged);
omc_ExpressionSimplify_checkSimplify(threadData, omc_Flags_isSet(threadData, _OMC_LIT164), _inExp, _outExp);
_return: OMC_LABEL_UNUSED
if (out_hasChanged) { *out_hasChanged = _hasChanged; }
return _outExp;
}
modelica_metatype boxptr_ExpressionSimplify_simplify1WithOptions(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _options, modelica_metatype *out_hasChanged)
{
modelica_boolean _hasChanged;
modelica_metatype _outExp = NULL;
_outExp = omc_ExpressionSimplify_simplify1WithOptions(threadData, _inExp, _options, &_hasChanged);
if (out_hasChanged) { *out_hasChanged = mmc_mk_icon(_hasChanged); }
return _outExp;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplify1o(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_e = tmpMeta6;
_e = omc_ExpressionSimplify_simplify1WithOptions(threadData, _e, _OMC_LIT166, NULL);
tmpMeta1 = mmc_mk_some(_e);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inExp;
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype omc_ExpressionSimplify_simplify1(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean *out_hasChanged)
{
modelica_metatype _outExp = NULL;
modelica_boolean _hasChanged;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = omc_ExpressionSimplify_simplify1WithOptions(threadData, _inExp, _OMC_LIT166 ,&_hasChanged);
_return: OMC_LABEL_UNUSED
if (out_hasChanged) { *out_hasChanged = _hasChanged; }
return _outExp;
}
modelica_metatype boxptr_ExpressionSimplify_simplify1(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype *out_hasChanged)
{
modelica_boolean _hasChanged;
modelica_metatype _outExp = NULL;
_outExp = omc_ExpressionSimplify_simplify1(threadData, _inExp, &_hasChanged);
if (out_hasChanged) { *out_hasChanged = mmc_mk_icon(_hasChanged); }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_edgeCref(threadData_t *threadData, modelica_metatype _ie, modelica_boolean _ib, modelica_boolean *out_cont, modelica_boolean *out_ob)
{
modelica_metatype _oe = NULL;
modelica_boolean _cont;
modelica_boolean _ob;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_boolean tmp4_2;
tmp4_1 = _ie;
tmp4_2 = _ib;
{
modelica_metatype _e = NULL;
modelica_boolean _b;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmp4_1;
_ty = tmpMeta6;
tmpMeta7 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = omc_Expression_makeBuiltinCall(threadData, _OMC_LIT64, tmpMeta7, _ty, 0);
tmp1_c1 = 0;
tmp1_c2 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (4 != MMC_STRLEN(tmpMeta9) || strcmp(MMC_STRINGDATA(_OMC_LIT64), MMC_STRINGDATA(tmpMeta9)) != 0) goto tmp3_end;
_e = tmp4_1;
_b = tmp4_2;
tmpMeta[0+0] = _e;
tmp1_c1 = 0;
tmp1_c2 = _b;
goto tmp3_done;
}
case 2: {
_e = tmp4_1;
_b = tmp4_2;
tmpMeta[0+0] = _e;
tmp1_c1 = (!_b);
tmp1_c2 = _b;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_oe = tmpMeta[0+0];
_cont = tmp1_c1;
_ob = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_cont) { *out_cont = _cont; }
if (out_ob) { *out_ob = _ob; }
return _oe;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_edgeCref(threadData_t *threadData, modelica_metatype _ie, modelica_metatype _ib, modelica_metatype *out_cont, modelica_metatype *out_ob)
{
modelica_integer tmp1;
modelica_boolean _cont;
modelica_boolean _ob;
modelica_metatype _oe = NULL;
tmp1 = mmc_unbox_integer(_ib);
_oe = omc_ExpressionSimplify_edgeCref(threadData, _ie, tmp1, &_cont, &_ob);
if (out_cont) { *out_cont = mmc_mk_icon(_cont); }
if (out_ob) { *out_ob = mmc_mk_icon(_ob); }
return _oe;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_changeCref(threadData_t *threadData, modelica_metatype _ie, modelica_boolean _ib, modelica_boolean *out_cont, modelica_boolean *out_ob)
{
modelica_metatype _oe = NULL;
modelica_boolean _cont;
modelica_boolean _ob;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_boolean tmp4_2;
tmp4_1 = _ie;
tmp4_2 = _ib;
{
modelica_metatype _e = NULL;
modelica_boolean _b;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmp4_1;
_ty = tmpMeta6;
tmpMeta7 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = omc_Expression_makeBuiltinCall(threadData, _OMC_LIT65, tmpMeta7, _ty, 0);
tmp1_c1 = 0;
tmp1_c2 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (6 != MMC_STRLEN(tmpMeta9) || strcmp(MMC_STRINGDATA(_OMC_LIT65), MMC_STRINGDATA(tmpMeta9)) != 0) goto tmp3_end;
_e = tmp4_1;
_b = tmp4_2;
tmpMeta[0+0] = _e;
tmp1_c1 = 0;
tmp1_c2 = _b;
goto tmp3_done;
}
case 2: {
_e = tmp4_1;
_b = tmp4_2;
tmpMeta[0+0] = _e;
tmp1_c1 = (!_b);
tmp1_c2 = _b;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_oe = tmpMeta[0+0];
_cont = tmp1_c1;
_ob = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_cont) { *out_cont = _cont; }
if (out_ob) { *out_ob = _ob; }
return _oe;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_changeCref(threadData_t *threadData, modelica_metatype _ie, modelica_metatype _ib, modelica_metatype *out_cont, modelica_metatype *out_ob)
{
modelica_integer tmp1;
modelica_boolean _cont;
modelica_boolean _ob;
modelica_metatype _oe = NULL;
tmp1 = mmc_unbox_integer(_ib);
_oe = omc_ExpressionSimplify_changeCref(threadData, _ie, tmp1, &_cont, &_ob);
if (out_cont) { *out_cont = mmc_mk_icon(_cont); }
if (out_ob) { *out_ob = mmc_mk_icon(_ob); }
return _oe;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_previousCref(threadData_t *threadData, modelica_metatype _ie, modelica_boolean _ib, modelica_boolean *out_cont, modelica_boolean *out_ob)
{
modelica_metatype _oe = NULL;
modelica_boolean _cont;
modelica_boolean _ob;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_boolean tmp4_2;
tmp4_1 = _ie;
tmp4_2 = _ib;
{
modelica_metatype _e = NULL;
modelica_boolean _b;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmp4_1;
_ty = tmpMeta6;
tmpMeta7 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = omc_Expression_makeBuiltinCall(threadData, _OMC_LIT63, tmpMeta7, _ty, 0);
tmp1_c1 = 0;
tmp1_c2 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (8 != MMC_STRLEN(tmpMeta9) || strcmp(MMC_STRINGDATA(_OMC_LIT63), MMC_STRINGDATA(tmpMeta9)) != 0) goto tmp3_end;
_e = tmp4_1;
_b = tmp4_2;
tmpMeta[0+0] = _e;
tmp1_c1 = 0;
tmp1_c2 = _b;
goto tmp3_done;
}
case 2: {
_e = tmp4_1;
_b = tmp4_2;
tmpMeta[0+0] = _e;
tmp1_c1 = (!_b);
tmp1_c2 = _b;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_oe = tmpMeta[0+0];
_cont = tmp1_c1;
_ob = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_cont) { *out_cont = _cont; }
if (out_ob) { *out_ob = _ob; }
return _oe;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_previousCref(threadData_t *threadData, modelica_metatype _ie, modelica_metatype _ib, modelica_metatype *out_cont, modelica_metatype *out_ob)
{
modelica_integer tmp1;
modelica_boolean _cont;
modelica_boolean _ob;
modelica_metatype _oe = NULL;
tmp1 = mmc_unbox_integer(_ib);
_oe = omc_ExpressionSimplify_previousCref(threadData, _ie, tmp1, &_cont, &_ob);
if (out_cont) { *out_cont = mmc_mk_icon(_cont); }
if (out_ob) { *out_ob = mmc_mk_icon(_ob); }
return _oe;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_preCref(threadData_t *threadData, modelica_metatype _ie, modelica_boolean _ib, modelica_boolean *out_cont, modelica_boolean *out_ob)
{
modelica_metatype _oe = NULL;
modelica_boolean _cont;
modelica_boolean _ob;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_boolean tmp1_c2 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_boolean tmp4_2;
tmp4_1 = _ie;
tmp4_2 = _ib;
{
modelica_metatype _e = NULL;
modelica_boolean _b;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmp4_1;
_ty = tmpMeta6;
tmpMeta7 = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = omc_Expression_makeBuiltinCall(threadData, _OMC_LIT62, tmpMeta7, _ty, 0);
tmp1_c1 = 0;
tmp1_c2 = 1;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta8,1,1) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta8), 2));
if (3 != MMC_STRLEN(tmpMeta9) || strcmp(MMC_STRINGDATA(_OMC_LIT62), MMC_STRINGDATA(tmpMeta9)) != 0) goto tmp3_end;
_e = tmp4_1;
_b = tmp4_2;
tmpMeta[0+0] = _e;
tmp1_c1 = 0;
tmp1_c2 = _b;
goto tmp3_done;
}
case 2: {
_e = tmp4_1;
_b = tmp4_2;
tmpMeta[0+0] = _e;
tmp1_c1 = (!_b);
tmp1_c2 = _b;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_oe = tmpMeta[0+0];
_cont = tmp1_c1;
_ob = tmp1_c2;
_return: OMC_LABEL_UNUSED
if (out_cont) { *out_cont = _cont; }
if (out_ob) { *out_ob = _ob; }
return _oe;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_preCref(threadData_t *threadData, modelica_metatype _ie, modelica_metatype _ib, modelica_metatype *out_cont, modelica_metatype *out_ob)
{
modelica_integer tmp1;
modelica_boolean _cont;
modelica_boolean _ob;
modelica_metatype _oe = NULL;
tmp1 = mmc_unbox_integer(_ib);
_oe = omc_ExpressionSimplify_preCref(threadData, _ie, tmp1, &_cont, &_ob);
if (out_cont) { *out_cont = mmc_mk_icon(_cont); }
if (out_ob) { *out_ob = mmc_mk_icon(_ob); }
return _oe;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCall(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _zero = NULL;
modelica_metatype _matrix = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _tp = NULL;
modelica_boolean _b2;
modelica_real _r1;
modelica_real _r2;
modelica_string _idn = NULL;
modelica_string _idn2 = NULL;
modelica_string _name = NULL;
modelica_integer _n;
modelica_integer _i1;
modelica_integer _i2;
modelica_metatype _ri = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 35; tmp4++) {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,1) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta8)) goto tmp3_end;
tmpMeta9 = MMC_CAR(tmpMeta8);
tmpMeta10 = MMC_CDR(tmpMeta8);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta9,27,3) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,1,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
if (5 != MMC_STRLEN(tmpMeta13) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta13)) != 0) goto tmp3_end;
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta9), 4));
if (listEmpty(tmpMeta14)) goto tmp3_end;
tmpMeta15 = MMC_CAR(tmpMeta14);
tmpMeta16 = MMC_CDR(tmpMeta14);
if (!listEmpty(tmpMeta16)) goto tmp3_end;
if (!listEmpty(tmpMeta10)) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
_name = tmpMeta7;
_e = tmpMeta9;
_ri = tmpMeta11;
_tp = tmpMeta18;
tmp4 += 1;
if (!listMember(_name, _OMC_LIT170)) goto tmp3_end;
tmpMeta20 = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _name);
tmpMeta21 = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, tmpMeta20, _OMC_LIT11, _tp, mmc_mk_some(omc_ExpressionSimplify_reductionDefaultValue(threadData, _name, _tp)), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ri), 6))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ri), 7))), mmc_mk_some(omc_ExpressionSimplify_reductionExpression(threadData, _name, _tp, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ri), 6))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ri), 7))))));
tmpMeta19 = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta19), MMC_UNTAGPTR(_e), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta19))[2] = tmpMeta21;
_e = tmpMeta19;
tmpMeta1 = _e;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta22,1,1) == 0) goto tmp3_end;
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta22), 2));
if (8 != MMC_STRLEN(tmpMeta23) || strcmp(MMC_STRINGDATA(_OMC_LIT177), MMC_STRINGDATA(tmpMeta23)) != 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta24)) goto tmp3_end;
tmpMeta25 = MMC_CAR(tmpMeta24);
tmpMeta26 = MMC_CDR(tmpMeta24);
if (listEmpty(tmpMeta26)) goto tmp3_end;
tmpMeta27 = MMC_CAR(tmpMeta26);
tmpMeta28 = MMC_CDR(tmpMeta26);
if (!listEmpty(tmpMeta28)) goto tmp3_end;
_e1 = tmpMeta25;
_e2 = tmpMeta27;
tmp4 += 15;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp3_end;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,1,1) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 2));
if (7 != MMC_STRLEN(tmpMeta30) || strcmp(MMC_STRINGDATA(_OMC_LIT178), MMC_STRINGDATA(tmpMeta30)) != 0) goto tmp3_end;
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta31)) goto tmp3_end;
tmpMeta32 = MMC_CAR(tmpMeta31);
tmpMeta33 = MMC_CDR(tmpMeta31);
if (!listEmpty(tmpMeta33)) goto tmp3_end;
_e = tmpMeta32;
tmp4 += 14;
_b2 = (omc_Expression_isRelation(threadData, _e) || omc_Expression_isEventTriggeringFunctionExp(threadData, _e));
tmpMeta1 = ((!_b2)?omc_ExpressionSimplify_simplifyNoEvent(threadData, _e):_inExp);
goto tmp3_done;
}
case 3: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta34,1,1) == 0) goto tmp3_end;
tmpMeta35 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta34), 2));
if (3 != MMC_STRLEN(tmpMeta35) || strcmp(MMC_STRINGDATA(_OMC_LIT61), MMC_STRINGDATA(tmpMeta35)) != 0) goto tmp3_end;
tmpMeta36 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta36)) goto tmp3_end;
tmpMeta37 = MMC_CAR(tmpMeta36);
tmpMeta38 = MMC_CDR(tmpMeta36);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta37,8,2) == 0) goto tmp3_end;
tmpMeta39 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta39,5,1) == 0) goto tmp3_end;
tmpMeta40 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta39), 2));
tmpMeta41 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta37), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta41,6,2) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta38)) goto tmp3_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_tp = tmpMeta40;
_e1 = tmpMeta41;
_attr = tmpMeta42;
tmp4 += 13;
tmpMeta43 = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _tp);
tmpMeta44 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta45 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT171, tmpMeta44, _attr);
tmpMeta46 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta43, tmpMeta45);
tmpMeta1 = tmpMeta46;
goto tmp3_done;
}
case 4: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta47 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta47,1,1) == 0) goto tmp3_end;
tmpMeta48 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta47), 2));
if (3 != MMC_STRLEN(tmpMeta48) || strcmp(MMC_STRINGDATA(_OMC_LIT61), MMC_STRINGDATA(tmpMeta48)) != 0) goto tmp3_end;
tmpMeta49 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta49)) goto tmp3_end;
tmpMeta50 = MMC_CAR(tmpMeta49);
tmpMeta51 = MMC_CDR(tmpMeta49);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta50,8,2) == 0) goto tmp3_end;
tmpMeta52 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta52,6,1) == 0) goto tmp3_end;
tmpMeta53 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta52), 2));
tmpMeta54 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta50), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta54,6,2) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta51)) goto tmp3_end;
tmpMeta55 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_tp = tmpMeta53;
_e1 = tmpMeta54;
_attr = tmpMeta55;
tmp4 += 12;
tmpMeta56 = mmc_mk_box2(9, &DAE_Operator_UMINUS__ARR__desc, _tp);
tmpMeta57 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta58 = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT171, tmpMeta57, _attr);
tmpMeta59 = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta56, tmpMeta58);
tmpMeta1 = tmpMeta59;
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta60;
modelica_metatype tmpMeta61;
modelica_metatype tmpMeta62;
modelica_metatype tmpMeta63;
modelica_metatype tmpMeta64;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta60 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta60,1,1) == 0) goto tmp3_end;
tmpMeta61 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta60), 2));
if (3 != MMC_STRLEN(tmpMeta61) || strcmp(MMC_STRINGDATA(_OMC_LIT62), MMC_STRINGDATA(tmpMeta61)) != 0) goto tmp3_end;
tmpMeta62 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta62)) goto tmp3_end;
tmpMeta63 = MMC_CAR(tmpMeta62);
tmpMeta64 = MMC_CDR(tmpMeta62);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta63,6,2) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta64)) goto tmp3_end;
tmp4 += 7;
tmpMeta1 = _inExp;
goto tmp3_done;
}
case 6: {
modelica_metatype tmpMeta65;
modelica_metatype tmpMeta66;
modelica_metatype tmpMeta67;
modelica_metatype tmpMeta68;
modelica_metatype tmpMeta69;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta65 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta65,1,1) == 0) goto tmp3_end;
tmpMeta66 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta65), 2));
if (8 != MMC_STRLEN(tmpMeta66) || strcmp(MMC_STRINGDATA(_OMC_LIT63), MMC_STRINGDATA(tmpMeta66)) != 0) goto tmp3_end;
tmpMeta67 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta67)) goto tmp3_end;
tmpMeta68 = MMC_CAR(tmpMeta67);
tmpMeta69 = MMC_CDR(tmpMeta67);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta68,6,2) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta69)) goto tmp3_end;
tmp4 += 7;
tmpMeta1 = _inExp;
goto tmp3_done;
}
case 7: {
modelica_metatype tmpMeta70;
modelica_metatype tmpMeta71;
modelica_metatype tmpMeta72;
modelica_metatype tmpMeta73;
modelica_metatype tmpMeta74;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta70 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta70,1,1) == 0) goto tmp3_end;
tmpMeta71 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta70), 2));
if (6 != MMC_STRLEN(tmpMeta71) || strcmp(MMC_STRINGDATA(_OMC_LIT65), MMC_STRINGDATA(tmpMeta71)) != 0) goto tmp3_end;
tmpMeta72 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta72)) goto tmp3_end;
tmpMeta73 = MMC_CAR(tmpMeta72);
tmpMeta74 = MMC_CDR(tmpMeta72);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta73,6,2) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta74)) goto tmp3_end;
tmp4 += 7;
tmpMeta1 = _inExp;
goto tmp3_done;
}
case 8: {
modelica_metatype tmpMeta75;
modelica_metatype tmpMeta76;
modelica_metatype tmpMeta77;
modelica_metatype tmpMeta78;
modelica_metatype tmpMeta79;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta75 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta75,1,1) == 0) goto tmp3_end;
tmpMeta76 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta75), 2));
if (4 != MMC_STRLEN(tmpMeta76) || strcmp(MMC_STRINGDATA(_OMC_LIT64), MMC_STRINGDATA(tmpMeta76)) != 0) goto tmp3_end;
tmpMeta77 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta77)) goto tmp3_end;
tmpMeta78 = MMC_CAR(tmpMeta77);
tmpMeta79 = MMC_CDR(tmpMeta77);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta78,6,2) == 0) goto tmp3_end;
if (!listEmpty(tmpMeta79)) goto tmp3_end;
tmp4 += 7;
tmpMeta1 = _inExp;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta80;
modelica_metatype tmpMeta81;
modelica_metatype tmpMeta82;
modelica_metatype tmpMeta83;
modelica_metatype tmpMeta84;
modelica_metatype tmpMeta85;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta80 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta80,1,1) == 0) goto tmp3_end;
tmpMeta81 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta80), 2));
if (3 != MMC_STRLEN(tmpMeta81) || strcmp(MMC_STRINGDATA(_OMC_LIT62), MMC_STRINGDATA(tmpMeta81)) != 0) goto tmp3_end;
tmpMeta82 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta82)) goto tmp3_end;
tmpMeta83 = MMC_CAR(tmpMeta82);
tmpMeta84 = MMC_CDR(tmpMeta82);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta83,21,2) == 0) goto tmp3_end;
tmpMeta85 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta83), 2));
if (!listEmpty(tmpMeta84)) goto tmp3_end;
_e = tmpMeta83;
_exp = tmpMeta85;
tmp4 += 3;
_b2 = omc_Expression_isConst(threadData, _exp);
tmpMeta1 = (_b2?_e:_inExp);
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta86;
modelica_metatype tmpMeta87;
modelica_metatype tmpMeta88;
modelica_metatype tmpMeta89;
modelica_metatype tmpMeta90;
modelica_metatype tmpMeta91;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta86 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta86,1,1) == 0) goto tmp3_end;
tmpMeta87 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta86), 2));
if (8 != MMC_STRLEN(tmpMeta87) || strcmp(MMC_STRINGDATA(_OMC_LIT63), MMC_STRINGDATA(tmpMeta87)) != 0) goto tmp3_end;
tmpMeta88 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta88)) goto tmp3_end;
tmpMeta89 = MMC_CAR(tmpMeta88);
tmpMeta90 = MMC_CDR(tmpMeta88);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta89,21,2) == 0) goto tmp3_end;
tmpMeta91 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta89), 2));
if (!listEmpty(tmpMeta90)) goto tmp3_end;
_e = tmpMeta89;
_exp = tmpMeta91;
tmp4 += 3;
_b2 = omc_Expression_isConst(threadData, _exp);
tmpMeta1 = (_b2?_e:_inExp);
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta92;
modelica_metatype tmpMeta93;
modelica_metatype tmpMeta94;
modelica_metatype tmpMeta95;
modelica_metatype tmpMeta96;
modelica_metatype tmpMeta97;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta92 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta92,1,1) == 0) goto tmp3_end;
tmpMeta93 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta92), 2));
if (6 != MMC_STRLEN(tmpMeta93) || strcmp(MMC_STRINGDATA(_OMC_LIT65), MMC_STRINGDATA(tmpMeta93)) != 0) goto tmp3_end;
tmpMeta94 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta94)) goto tmp3_end;
tmpMeta95 = MMC_CAR(tmpMeta94);
tmpMeta96 = MMC_CDR(tmpMeta94);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta95,21,2) == 0) goto tmp3_end;
tmpMeta97 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta95), 2));
if (!listEmpty(tmpMeta96)) goto tmp3_end;
_exp = tmpMeta97;
tmp4 += 3;
_b2 = omc_Expression_isConst(threadData, _exp);
tmpMeta1 = (_b2?_OMC_LIT22:_inExp);
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta98;
modelica_metatype tmpMeta99;
modelica_metatype tmpMeta100;
modelica_metatype tmpMeta101;
modelica_metatype tmpMeta102;
modelica_metatype tmpMeta103;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta98 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta98,1,1) == 0) goto tmp3_end;
tmpMeta99 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta98), 2));
if (4 != MMC_STRLEN(tmpMeta99) || strcmp(MMC_STRINGDATA(_OMC_LIT64), MMC_STRINGDATA(tmpMeta99)) != 0) goto tmp3_end;
tmpMeta100 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta100)) goto tmp3_end;
tmpMeta101 = MMC_CAR(tmpMeta100);
tmpMeta102 = MMC_CDR(tmpMeta100);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta101,21,2) == 0) goto tmp3_end;
tmpMeta103 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta101), 2));
if (!listEmpty(tmpMeta102)) goto tmp3_end;
_exp = tmpMeta103;
tmp4 += 3;
_b2 = omc_Expression_isConst(threadData, _exp);
tmpMeta1 = (_b2?_OMC_LIT22:_inExp);
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta104;
modelica_metatype tmpMeta105;
modelica_metatype tmpMeta106;
modelica_metatype tmpMeta107;
modelica_metatype tmpMeta108;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta104 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta104,1,1) == 0) goto tmp3_end;
tmpMeta105 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta104), 2));
if (3 != MMC_STRLEN(tmpMeta105) || strcmp(MMC_STRINGDATA(_OMC_LIT62), MMC_STRINGDATA(tmpMeta105)) != 0) goto tmp3_end;
tmpMeta106 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta106)) goto tmp3_end;
tmpMeta107 = MMC_CAR(tmpMeta106);
tmpMeta108 = MMC_CDR(tmpMeta106);
if (!listEmpty(tmpMeta108)) goto tmp3_end;
_e = tmpMeta107;
tmp4 += 3;
tmpMeta1 = omc_Expression_traverseExpTopDown(threadData, _e, boxvar_ExpressionSimplify_preCref, mmc_mk_boolean(0), NULL);
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta109;
modelica_metatype tmpMeta110;
modelica_metatype tmpMeta111;
modelica_metatype tmpMeta112;
modelica_metatype tmpMeta113;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta109 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta109,1,1) == 0) goto tmp3_end;
tmpMeta110 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta109), 2));
if (8 != MMC_STRLEN(tmpMeta110) || strcmp(MMC_STRINGDATA(_OMC_LIT63), MMC_STRINGDATA(tmpMeta110)) != 0) goto tmp3_end;
tmpMeta111 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta111)) goto tmp3_end;
tmpMeta112 = MMC_CAR(tmpMeta111);
tmpMeta113 = MMC_CDR(tmpMeta111);
if (!listEmpty(tmpMeta113)) goto tmp3_end;
_e = tmpMeta112;
tmp4 += 2;
tmpMeta1 = omc_Expression_traverseExpTopDown(threadData, _e, boxvar_ExpressionSimplify_previousCref, mmc_mk_boolean(0), NULL);
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta114;
modelica_metatype tmpMeta115;
modelica_metatype tmpMeta116;
modelica_metatype tmpMeta117;
modelica_metatype tmpMeta118;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta114 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta114,1,1) == 0) goto tmp3_end;
tmpMeta115 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta114), 2));
if (6 != MMC_STRLEN(tmpMeta115) || strcmp(MMC_STRINGDATA(_OMC_LIT65), MMC_STRINGDATA(tmpMeta115)) != 0) goto tmp3_end;
tmpMeta116 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta116)) goto tmp3_end;
tmpMeta117 = MMC_CAR(tmpMeta116);
tmpMeta118 = MMC_CDR(tmpMeta116);
if (!listEmpty(tmpMeta118)) goto tmp3_end;
_e = tmpMeta117;
tmp4 += 1;
tmpMeta1 = omc_Expression_traverseExpTopDown(threadData, _e, boxvar_ExpressionSimplify_changeCref, mmc_mk_boolean(0), NULL);
goto tmp3_done;
}
case 16: {
modelica_metatype tmpMeta119;
modelica_metatype tmpMeta120;
modelica_metatype tmpMeta121;
modelica_metatype tmpMeta122;
modelica_metatype tmpMeta123;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta119 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta119,1,1) == 0) goto tmp3_end;
tmpMeta120 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta119), 2));
if (4 != MMC_STRLEN(tmpMeta120) || strcmp(MMC_STRINGDATA(_OMC_LIT64), MMC_STRINGDATA(tmpMeta120)) != 0) goto tmp3_end;
tmpMeta121 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta121)) goto tmp3_end;
tmpMeta122 = MMC_CAR(tmpMeta121);
tmpMeta123 = MMC_CDR(tmpMeta121);
if (!listEmpty(tmpMeta123)) goto tmp3_end;
_e = tmpMeta122;
tmpMeta1 = omc_Expression_traverseExpTopDown(threadData, _e, boxvar_ExpressionSimplify_edgeCref, mmc_mk_boolean(0), NULL);
goto tmp3_done;
}
case 17: {
modelica_metatype tmpMeta124;
modelica_metatype tmpMeta125;
modelica_metatype tmpMeta126;
modelica_metatype tmpMeta127;
modelica_metatype tmpMeta128;
modelica_integer tmp129;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta124 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta124,1,1) == 0) goto tmp3_end;
tmpMeta125 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta124), 2));
tmpMeta126 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta127 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta128 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta127), 5));
tmp129 = mmc_unbox_integer(tmpMeta128);
if (0 != tmp129) goto tmp3_end;
_idn = tmpMeta125;
_expl = tmpMeta126;
if (!omc_Expression_isConstWorkList(threadData, _expl)) goto tmp3_end;
tmpMeta1 = omc_ExpressionSimplify_simplifyBuiltinConstantCalls(threadData, _idn, _inExp);
goto tmp3_done;
}
case 18: {
modelica_metatype tmpMeta130;
modelica_metatype tmpMeta131;
modelica_integer tmp132;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta130 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta131 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta130), 4));
tmp132 = mmc_unbox_integer(tmpMeta131);
if (1 != tmp132) goto tmp3_end;
tmpMeta1 = omc_ExpressionSimplify_simplifyBuiltinCalls(threadData, _inExp);
goto tmp3_done;
}
case 19: {
modelica_metatype tmpMeta133;
modelica_metatype tmpMeta134;
modelica_metatype tmpMeta135;
modelica_metatype tmpMeta136;
modelica_metatype tmpMeta137;
modelica_metatype tmpMeta138;
modelica_integer tmp139;
modelica_metatype tmpMeta140;
modelica_metatype tmpMeta156;
modelica_metatype tmpMeta157;
modelica_metatype tmpMeta158;
modelica_metatype tmpMeta159;
modelica_metatype tmpMeta160;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta133 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta133,1,1) == 0) goto tmp3_end;
tmpMeta134 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta133), 2));
if (8 != MMC_STRLEN(tmpMeta134) || strcmp(MMC_STRINGDATA(_OMC_LIT179), MMC_STRINGDATA(tmpMeta134)) != 0) goto tmp3_end;
tmpMeta135 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta135)) goto tmp3_end;
tmpMeta136 = MMC_CAR(tmpMeta135);
tmpMeta137 = MMC_CDR(tmpMeta135);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta136,0,1) == 0) goto tmp3_end;
tmpMeta138 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta136), 2));
tmp139 = mmc_unbox_integer(tmpMeta138);
if (!listEmpty(tmpMeta137)) goto tmp3_end;
_n = tmp139;
tmp4 += 13;
{
modelica_metatype __omcQ_24tmpVar47;
modelica_metatype* tmp141;
modelica_metatype tmpMeta142;
modelica_metatype tmpMeta143;
modelica_metatype tmpMeta144;
modelica_metatype tmpMeta145;
modelica_metatype tmpMeta146;
modelica_metatype tmpMeta152;
modelica_metatype __omcQ_24tmpVar46;
modelica_integer tmp153;
modelica_integer tmp154;
modelica_integer tmp155;
modelica_integer _j;
tmp154 = 1;
tmp155 = _n;
_j = ((modelica_integer) 1);
_j = (((modelica_integer) 1) /* Range start-value */)-tmp154;
tmpMeta142 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar47 = tmpMeta142;
tmp141 = &__omcQ_24tmpVar47;
while(1) {
tmp153 = 1;
if (tmp154 > 0 ? _j+tmp154 <= tmp155 : _j+tmp154 >= tmp155) {
_j += tmp154;
tmp153--;
}
if (tmp153 == 0) {
tmpMeta144 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_n));
tmpMeta143 = mmc_mk_cons(tmpMeta144, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta145 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT54, tmpMeta143);
{
modelica_metatype __omcQ_24tmpVar45;
modelica_metatype* tmp147;
modelica_metatype tmpMeta148;
modelica_metatype __omcQ_24tmpVar44;
modelica_integer tmp149;
modelica_integer tmp150;
modelica_integer tmp151;
modelica_integer _i;
tmp150 = 1;
tmp151 = _n;
_i = ((modelica_integer) 1);
_i = (((modelica_integer) 1) /* Range start-value */)-tmp150;
tmpMeta148 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar45 = tmpMeta148;
tmp147 = &__omcQ_24tmpVar45;
while(1) {
tmp149 = 1;
if (tmp150 > 0 ? _i+tmp150 <= tmp151 : _i+tmp150 >= tmp151) {
_i += tmp150;
tmp149--;
}
if (tmp149 == 0) {
__omcQ_24tmpVar44 = ((_i == _j)?_OMC_LIT85:_OMC_LIT172);
*tmp147 = mmc_mk_cons(__omcQ_24tmpVar44,0);
tmp147 = &MMC_CDR(*tmp147);
} else if (tmp149 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp147 = mmc_mk_nil();
tmpMeta146 = __omcQ_24tmpVar45;
}
tmpMeta152 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta145, mmc_mk_boolean(1), tmpMeta146);
__omcQ_24tmpVar46 = tmpMeta152;
*tmp141 = mmc_mk_cons(__omcQ_24tmpVar46,0);
tmp141 = &MMC_CDR(*tmp141);
} else if (tmp153 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp141 = mmc_mk_nil();
tmpMeta140 = __omcQ_24tmpVar47;
}
_matrix = tmpMeta140;
tmpMeta157 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_n));
tmpMeta158 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_n));
tmpMeta156 = mmc_mk_cons(tmpMeta157, mmc_mk_cons(tmpMeta158, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta159 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT54, tmpMeta156);
tmpMeta160 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta159, mmc_mk_boolean(0), _matrix);
tmpMeta1 = tmpMeta160;
goto tmp3_done;
}
case 20: {
modelica_metatype tmpMeta161;
modelica_metatype tmpMeta162;
modelica_metatype tmpMeta163;
modelica_metatype tmpMeta164;
modelica_metatype tmpMeta165;
modelica_metatype tmpMeta166;
modelica_metatype tmpMeta167;
modelica_metatype tmpMeta168;
modelica_metatype tmpMeta184;
modelica_metatype tmpMeta185;
modelica_metatype tmpMeta186;
modelica_metatype tmpMeta187;
modelica_metatype tmpMeta188;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta161 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta161,1,1) == 0) goto tmp3_end;
tmpMeta162 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta161), 2));
if (8 != MMC_STRLEN(tmpMeta162) || strcmp(MMC_STRINGDATA(_OMC_LIT180), MMC_STRINGDATA(tmpMeta162)) != 0) goto tmp3_end;
tmpMeta163 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta163)) goto tmp3_end;
tmpMeta164 = MMC_CAR(tmpMeta163);
tmpMeta165 = MMC_CDR(tmpMeta163);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta164,16,3) == 0) goto tmp3_end;
tmpMeta166 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta164), 2));
tmpMeta167 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta164), 4));
if (!listEmpty(tmpMeta165)) goto tmp3_end;
_tp = tmpMeta166;
_expl = tmpMeta167;
tmp4 += 12;
_n = listLength(_expl);
_tp = omc_Types_arrayElementType(threadData, _tp);
_zero = omc_Expression_makeConstZero(threadData, _tp);
{
modelica_metatype __omcQ_24tmpVar51;
modelica_metatype* tmp169;
modelica_metatype tmpMeta170;
modelica_metatype tmpMeta171;
modelica_metatype tmpMeta172;
modelica_metatype tmpMeta173;
modelica_metatype tmpMeta174;
modelica_metatype tmpMeta180;
modelica_metatype __omcQ_24tmpVar50;
modelica_integer tmp181;
modelica_integer tmp182;
modelica_integer tmp183;
modelica_integer _j;
tmp182 = 1;
tmp183 = _n;
_j = ((modelica_integer) 1);
_j = (((modelica_integer) 1) /* Range start-value */)-tmp182;
tmpMeta170 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar51 = tmpMeta170;
tmp169 = &__omcQ_24tmpVar51;
while(1) {
tmp181 = 1;
if (tmp182 > 0 ? _j+tmp182 <= tmp183 : _j+tmp182 >= tmp183) {
_j += tmp182;
tmp181--;
}
if (tmp181 == 0) {
tmpMeta172 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_n));
tmpMeta171 = mmc_mk_cons(tmpMeta172, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta173 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _tp, tmpMeta171);
{
modelica_metatype __omcQ_24tmpVar49;
modelica_metatype* tmp175;
modelica_metatype tmpMeta176;
modelica_metatype __omcQ_24tmpVar48;
modelica_integer tmp177;
modelica_integer tmp178;
modelica_integer tmp179;
modelica_integer _i;
tmp178 = 1;
tmp179 = _n;
_i = ((modelica_integer) 1);
_i = (((modelica_integer) 1) /* Range start-value */)-tmp178;
tmpMeta176 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar49 = tmpMeta176;
tmp175 = &__omcQ_24tmpVar49;
while(1) {
tmp177 = 1;
if (tmp178 > 0 ? _i+tmp178 <= tmp179 : _i+tmp178 >= tmp179) {
_i += tmp178;
tmp177--;
}
if (tmp177 == 0) {
__omcQ_24tmpVar48 = ((_i == _j)?listGet(_expl, _i):_zero);
*tmp175 = mmc_mk_cons(__omcQ_24tmpVar48,0);
tmp175 = &MMC_CDR(*tmp175);
} else if (tmp177 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp175 = mmc_mk_nil();
tmpMeta174 = __omcQ_24tmpVar49;
}
tmpMeta180 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta173, mmc_mk_boolean(1), tmpMeta174);
__omcQ_24tmpVar50 = tmpMeta180;
*tmp169 = mmc_mk_cons(__omcQ_24tmpVar50,0);
tmp169 = &MMC_CDR(*tmp169);
} else if (tmp181 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp169 = mmc_mk_nil();
tmpMeta168 = __omcQ_24tmpVar51;
}
_matrix = tmpMeta168;
tmpMeta185 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_n));
tmpMeta186 = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_n));
tmpMeta184 = mmc_mk_cons(tmpMeta185, mmc_mk_cons(tmpMeta186, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta187 = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _tp, tmpMeta184);
tmpMeta188 = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta187, mmc_mk_boolean(0), _matrix);
tmpMeta1 = tmpMeta188;
goto tmp3_done;
}
case 21: {
modelica_metatype tmpMeta189;
modelica_metatype tmpMeta190;
modelica_metatype tmpMeta191;
modelica_metatype tmpMeta192;
modelica_metatype tmpMeta193;
modelica_metatype tmpMeta194;
modelica_metatype tmpMeta195;
modelica_metatype tmpMeta196;
modelica_metatype tmpMeta197;
modelica_metatype tmpMeta198;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta189 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta189,1,1) == 0) goto tmp3_end;
tmpMeta190 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta189), 2));
tmpMeta191 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta191)) goto tmp3_end;
tmpMeta192 = MMC_CAR(tmpMeta191);
tmpMeta193 = MMC_CDR(tmpMeta191);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta192,13,3) == 0) goto tmp3_end;
tmpMeta194 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta192), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta194,1,1) == 0) goto tmp3_end;
tmpMeta195 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta194), 2));
tmpMeta196 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta192), 3));
if (listEmpty(tmpMeta196)) goto tmp3_end;
tmpMeta197 = MMC_CAR(tmpMeta196);
tmpMeta198 = MMC_CDR(tmpMeta196);
if (!listEmpty(tmpMeta198)) goto tmp3_end;
if (!listEmpty(tmpMeta193)) goto tmp3_end;
_idn = tmpMeta190;
_idn2 = tmpMeta195;
_e = tmpMeta197;
tmp4 += 3;
if (!((stringEqual(_idn, _OMC_LIT37)) && (stringEqual(_idn2, _OMC_LIT173)))) goto tmp3_end;
tmpMeta1 = _e;
goto tmp3_done;
}
case 22: {
modelica_metatype tmpMeta199;
modelica_metatype tmpMeta200;
modelica_metatype tmpMeta201;
modelica_metatype tmpMeta202;
modelica_metatype tmpMeta203;
modelica_metatype tmpMeta204;
modelica_real tmp205;
modelica_metatype tmpMeta206;
modelica_metatype tmpMeta207;
modelica_metatype tmpMeta208;
modelica_real tmp209;
modelica_metatype tmpMeta210;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta199 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta199,1,1) == 0) goto tmp3_end;
tmpMeta200 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta199), 2));
if (3 != MMC_STRLEN(tmpMeta200) || strcmp(MMC_STRINGDATA(_OMC_LIT181), MMC_STRINGDATA(tmpMeta200)) != 0) goto tmp3_end;
tmpMeta201 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta201)) goto tmp3_end;
tmpMeta202 = MMC_CAR(tmpMeta201);
tmpMeta203 = MMC_CDR(tmpMeta201);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta202,1,1) == 0) goto tmp3_end;
tmpMeta204 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta202), 2));
tmp205 = mmc_unbox_real(tmpMeta204);
if (listEmpty(tmpMeta203)) goto tmp3_end;
tmpMeta206 = MMC_CAR(tmpMeta203);
tmpMeta207 = MMC_CDR(tmpMeta203);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta206,1,1) == 0) goto tmp3_end;
tmpMeta208 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta206), 2));
tmp209 = mmc_unbox_real(tmpMeta208);
if (!listEmpty(tmpMeta207)) goto tmp3_end;
_r1 = tmp205;
_r2 = tmp209;
tmp4 += 10;
if (!(_r2 != 0.0)) goto tmp3_end;
tmpMeta210 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(modelica_real_mod(_r1, _r2)));
tmpMeta1 = tmpMeta210;
goto tmp3_done;
}
case 23: {
modelica_metatype tmpMeta211;
modelica_metatype tmpMeta212;
modelica_metatype tmpMeta213;
modelica_metatype tmpMeta214;
modelica_metatype tmpMeta215;
modelica_metatype tmpMeta216;
modelica_integer tmp217;
modelica_metatype tmpMeta218;
modelica_metatype tmpMeta219;
modelica_metatype tmpMeta220;
modelica_integer tmp221;
modelica_metatype tmpMeta222;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta211 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta211,1,1) == 0) goto tmp3_end;
tmpMeta212 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta211), 2));
if (3 != MMC_STRLEN(tmpMeta212) || strcmp(MMC_STRINGDATA(_OMC_LIT181), MMC_STRINGDATA(tmpMeta212)) != 0) goto tmp3_end;
tmpMeta213 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta213)) goto tmp3_end;
tmpMeta214 = MMC_CAR(tmpMeta213);
tmpMeta215 = MMC_CDR(tmpMeta213);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta214,0,1) == 0) goto tmp3_end;
tmpMeta216 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta214), 2));
tmp217 = mmc_unbox_integer(tmpMeta216);
if (listEmpty(tmpMeta215)) goto tmp3_end;
tmpMeta218 = MMC_CAR(tmpMeta215);
tmpMeta219 = MMC_CDR(tmpMeta215);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta218,0,1) == 0) goto tmp3_end;
tmpMeta220 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta218), 2));
tmp221 = mmc_unbox_integer(tmpMeta220);
if (!listEmpty(tmpMeta219)) goto tmp3_end;
_i1 = tmp217;
_i2 = tmp221;
tmp4 += 9;
if (!(((modelica_real)_i2) != 0.0)) goto tmp3_end;
tmpMeta222 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(modelica_integer_mod(_i1, _i2)));
tmpMeta1 = tmpMeta222;
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta223;
modelica_metatype tmpMeta224;
modelica_metatype tmpMeta225;
modelica_metatype tmpMeta226;
modelica_metatype tmpMeta227;
modelica_metatype tmpMeta228;
modelica_real tmp229;
modelica_metatype tmpMeta230;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta223 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta223,1,1) == 0) goto tmp3_end;
tmpMeta224 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta223), 2));
if (7 != MMC_STRLEN(tmpMeta224) || strcmp(MMC_STRINGDATA(_OMC_LIT182), MMC_STRINGDATA(tmpMeta224)) != 0) goto tmp3_end;
tmpMeta225 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta225)) goto tmp3_end;
tmpMeta226 = MMC_CAR(tmpMeta225);
tmpMeta227 = MMC_CDR(tmpMeta225);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta226,1,1) == 0) goto tmp3_end;
tmpMeta228 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta226), 2));
tmp229 = mmc_unbox_real(tmpMeta228);
if (!listEmpty(tmpMeta227)) goto tmp3_end;
_r1 = tmp229;
tmp4 += 8;
tmpMeta230 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(((modelica_integer)floor(_r1))));
tmpMeta1 = tmpMeta230;
goto tmp3_done;
}
case 25: {
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
modelica_metatype tmpMeta242;
modelica_metatype tmpMeta243;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta231 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta231,1,1) == 0) goto tmp3_end;
tmpMeta232 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta231), 2));
if (3 != MMC_STRLEN(tmpMeta232) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta232)) != 0) goto tmp3_end;
tmpMeta233 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta233)) goto tmp3_end;
tmpMeta234 = MMC_CAR(tmpMeta233);
tmpMeta235 = MMC_CDR(tmpMeta233);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta234,13,3) == 0) goto tmp3_end;
tmpMeta236 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta234), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta236,1,1) == 0) goto tmp3_end;
tmpMeta237 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta236), 2));
if (4 != MMC_STRLEN(tmpMeta237) || strcmp(MMC_STRINGDATA(_OMC_LIT67), MMC_STRINGDATA(tmpMeta237)) != 0) goto tmp3_end;
tmpMeta238 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta234), 3));
if (listEmpty(tmpMeta238)) goto tmp3_end;
tmpMeta239 = MMC_CAR(tmpMeta238);
tmpMeta240 = MMC_CDR(tmpMeta238);
if (!listEmpty(tmpMeta240)) goto tmp3_end;
if (!listEmpty(tmpMeta235)) goto tmp3_end;
_e = tmpMeta239;
tmp4 += 7;
tmpMeta242 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT34, _e);
tmpMeta243 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, _OMC_LIT174, tmpMeta242);
tmpMeta241 = mmc_mk_cons(tmpMeta243, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta241, _OMC_LIT30);
goto tmp3_done;
}
case 26: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta244 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta244,1,1) == 0) goto tmp3_end;
tmpMeta245 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta244), 2));
if (3 != MMC_STRLEN(tmpMeta245) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta245)) != 0) goto tmp3_end;
tmpMeta246 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta246)) goto tmp3_end;
tmpMeta247 = MMC_CAR(tmpMeta246);
tmpMeta248 = MMC_CDR(tmpMeta246);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta247,13,3) == 0) goto tmp3_end;
tmpMeta249 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta247), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta249,1,1) == 0) goto tmp3_end;
tmpMeta250 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta249), 2));
if (4 != MMC_STRLEN(tmpMeta250) || strcmp(MMC_STRINGDATA(_OMC_LIT66), MMC_STRINGDATA(tmpMeta250)) != 0) goto tmp3_end;
tmpMeta251 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta247), 3));
if (listEmpty(tmpMeta251)) goto tmp3_end;
tmpMeta252 = MMC_CAR(tmpMeta251);
tmpMeta253 = MMC_CDR(tmpMeta251);
if (!listEmpty(tmpMeta253)) goto tmp3_end;
if (!listEmpty(tmpMeta248)) goto tmp3_end;
_e = tmpMeta252;
tmp4 += 6;
tmpMeta255 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT34, _e);
tmpMeta256 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, _OMC_LIT174, tmpMeta255);
tmpMeta254 = mmc_mk_cons(tmpMeta256, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta254, _OMC_LIT30);
goto tmp3_done;
}
case 27: {
modelica_metatype tmpMeta257;
modelica_metatype tmpMeta258;
modelica_metatype tmpMeta259;
modelica_metatype tmpMeta260;
modelica_metatype tmpMeta261;
modelica_metatype tmpMeta262;
modelica_metatype tmpMeta263;
modelica_metatype tmpMeta264;
modelica_metatype tmpMeta265;
modelica_metatype tmpMeta266;
modelica_metatype tmpMeta267;
modelica_metatype tmpMeta268;
modelica_metatype tmpMeta269;
modelica_metatype tmpMeta270;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta257 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta257,1,1) == 0) goto tmp3_end;
tmpMeta258 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta257), 2));
if (3 != MMC_STRLEN(tmpMeta258) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta258)) != 0) goto tmp3_end;
tmpMeta259 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta259)) goto tmp3_end;
tmpMeta260 = MMC_CAR(tmpMeta259);
tmpMeta261 = MMC_CDR(tmpMeta259);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta260,13,3) == 0) goto tmp3_end;
tmpMeta262 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta260), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta262,1,1) == 0) goto tmp3_end;
tmpMeta263 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta262), 2));
if (4 != MMC_STRLEN(tmpMeta263) || strcmp(MMC_STRINGDATA(_OMC_LIT173), MMC_STRINGDATA(tmpMeta263)) != 0) goto tmp3_end;
tmpMeta264 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta260), 3));
if (listEmpty(tmpMeta264)) goto tmp3_end;
tmpMeta265 = MMC_CAR(tmpMeta264);
tmpMeta266 = MMC_CDR(tmpMeta264);
if (!listEmpty(tmpMeta266)) goto tmp3_end;
if (!listEmpty(tmpMeta261)) goto tmp3_end;
_e = tmpMeta265;
tmp4 += 5;
tmpMeta268 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT34, _e);
tmpMeta269 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, _OMC_LIT46, tmpMeta268);
tmpMeta267 = mmc_mk_cons(tmpMeta269, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta270 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT31, omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta267, _OMC_LIT30));
tmpMeta1 = tmpMeta270;
goto tmp3_done;
}
case 28: {
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta271 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta271,1,1) == 0) goto tmp3_end;
tmpMeta272 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta271), 2));
if (3 != MMC_STRLEN(tmpMeta272) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta272)) != 0) goto tmp3_end;
tmpMeta273 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta273)) goto tmp3_end;
tmpMeta274 = MMC_CAR(tmpMeta273);
tmpMeta275 = MMC_CDR(tmpMeta273);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta274,13,3) == 0) goto tmp3_end;
tmpMeta276 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta274), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta276,1,1) == 0) goto tmp3_end;
tmpMeta277 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta276), 2));
if (4 != MMC_STRLEN(tmpMeta277) || strcmp(MMC_STRINGDATA(_OMC_LIT173), MMC_STRINGDATA(tmpMeta277)) != 0) goto tmp3_end;
tmpMeta278 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta274), 3));
if (listEmpty(tmpMeta278)) goto tmp3_end;
tmpMeta279 = MMC_CAR(tmpMeta278);
tmpMeta280 = MMC_CDR(tmpMeta278);
if (!listEmpty(tmpMeta280)) goto tmp3_end;
if (!listEmpty(tmpMeta275)) goto tmp3_end;
_e = tmpMeta279;
tmp4 += 4;
tmpMeta282 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT34, _e);
tmpMeta283 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, _OMC_LIT46, tmpMeta282);
tmpMeta281 = mmc_mk_cons(tmpMeta283, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta284 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, _OMC_LIT31, omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta281, _OMC_LIT30));
tmpMeta1 = tmpMeta284;
goto tmp3_done;
}
case 29: {
modelica_metatype tmpMeta285;
modelica_metatype tmpMeta286;
modelica_metatype tmpMeta287;
modelica_metatype tmpMeta288;
modelica_metatype tmpMeta289;
modelica_metatype tmpMeta290;
modelica_metatype tmpMeta291;
modelica_metatype tmpMeta292;
modelica_metatype tmpMeta293;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta285 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta285,1,1) == 0) goto tmp3_end;
tmpMeta286 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta285), 2));
if (5 != MMC_STRLEN(tmpMeta286) || strcmp(MMC_STRINGDATA(_OMC_LIT183), MMC_STRINGDATA(tmpMeta286)) != 0) goto tmp3_end;
tmpMeta287 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta287)) goto tmp3_end;
tmpMeta288 = MMC_CAR(tmpMeta287);
tmpMeta289 = MMC_CDR(tmpMeta287);
if (listEmpty(tmpMeta289)) goto tmp3_end;
tmpMeta290 = MMC_CAR(tmpMeta289);
tmpMeta291 = MMC_CDR(tmpMeta289);
if (!listEmpty(tmpMeta291)) goto tmp3_end;
_e1 = tmpMeta288;
_e2 = tmpMeta290;
if (!omc_Expression_isZero(threadData, _e2)) goto tmp3_end;
tmpMeta292 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
_e = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT43, tmpMeta292, _OMC_LIT30);
tmpMeta293 = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT176, _OMC_LIT34, _e);
tmpMeta1 = tmpMeta293;
goto tmp3_done;
}
case 30: {
modelica_metatype tmpMeta294;
modelica_metatype tmpMeta295;
modelica_metatype tmpMeta296;
modelica_metatype tmpMeta297;
modelica_metatype tmpMeta298;
modelica_metatype tmpMeta299;
modelica_real tmp300;
modelica_metatype tmpMeta301;
modelica_metatype tmpMeta302;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta294 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta294,1,1) == 0) goto tmp3_end;
tmpMeta295 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta294), 2));
if (5 != MMC_STRLEN(tmpMeta295) || strcmp(MMC_STRINGDATA(_OMC_LIT183), MMC_STRINGDATA(tmpMeta295)) != 0) goto tmp3_end;
tmpMeta296 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta296)) goto tmp3_end;
tmpMeta297 = MMC_CAR(tmpMeta296);
tmpMeta298 = MMC_CDR(tmpMeta296);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta297,1,1) == 0) goto tmp3_end;
tmpMeta299 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta297), 2));
tmp300 = mmc_unbox_real(tmpMeta299);
if (0.0 != tmp300) goto tmp3_end;
if (listEmpty(tmpMeta298)) goto tmp3_end;
tmpMeta301 = MMC_CAR(tmpMeta298);
tmpMeta302 = MMC_CDR(tmpMeta298);
if (!listEmpty(tmpMeta302)) goto tmp3_end;
_e1 = tmpMeta297;
tmpMeta1 = _e1;
goto tmp3_done;
}
case 31: {
modelica_metatype tmpMeta303;
modelica_metatype tmpMeta304;
modelica_metatype tmpMeta305;
modelica_metatype tmpMeta306;
modelica_metatype tmpMeta307;
modelica_metatype tmpMeta308;
modelica_real tmp309;
modelica_metatype tmpMeta310;
modelica_metatype tmpMeta311;
modelica_metatype tmpMeta312;
modelica_real tmp313;
modelica_metatype tmpMeta314;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta303 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta303,1,1) == 0) goto tmp3_end;
tmpMeta304 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta303), 2));
if (5 != MMC_STRLEN(tmpMeta304) || strcmp(MMC_STRINGDATA(_OMC_LIT183), MMC_STRINGDATA(tmpMeta304)) != 0) goto tmp3_end;
tmpMeta305 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta305)) goto tmp3_end;
tmpMeta306 = MMC_CAR(tmpMeta305);
tmpMeta307 = MMC_CDR(tmpMeta305);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta306,1,1) == 0) goto tmp3_end;
tmpMeta308 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta306), 2));
tmp309 = mmc_unbox_real(tmpMeta308);
if (listEmpty(tmpMeta307)) goto tmp3_end;
tmpMeta310 = MMC_CAR(tmpMeta307);
tmpMeta311 = MMC_CDR(tmpMeta307);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta310,1,1) == 0) goto tmp3_end;
tmpMeta312 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta310), 2));
tmp313 = mmc_unbox_real(tmpMeta312);
if (!listEmpty(tmpMeta311)) goto tmp3_end;
_r1 = tmp309;
_r2 = tmp313;
tmp4 += 1;
tmpMeta314 = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(atan2(_r1, _r2)));
tmpMeta1 = tmpMeta314;
goto tmp3_done;
}
case 32: {
modelica_metatype tmpMeta315;
modelica_metatype tmpMeta316;
modelica_metatype tmpMeta317;
modelica_metatype tmpMeta318;
modelica_metatype tmpMeta319;
modelica_metatype tmpMeta320;
modelica_metatype tmpMeta321;
modelica_metatype tmpMeta322;
modelica_metatype tmpMeta323;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta315 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta315,1,1) == 0) goto tmp3_end;
tmpMeta316 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta315), 2));
if (3 != MMC_STRLEN(tmpMeta316) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmpMeta316)) != 0) goto tmp3_end;
tmpMeta317 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta317)) goto tmp3_end;
tmpMeta318 = MMC_CAR(tmpMeta317);
tmpMeta319 = MMC_CDR(tmpMeta317);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta318,8,2) == 0) goto tmp3_end;
tmpMeta320 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta318), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta320,5,1) == 0) goto tmp3_end;
tmpMeta321 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta320), 2));
tmpMeta322 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta318), 3));
if (!listEmpty(tmpMeta319)) goto tmp3_end;
_tp = tmpMeta321;
_e1 = tmpMeta322;
tmpMeta323 = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta1 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT24, tmpMeta323, _tp);
goto tmp3_done;
}
case 33: {
if (!omc_Config_acceptMetaModelicaGrammar(threadData)) goto tmp3_end;
tmpMeta1 = omc_ExpressionSimplify_simplifyMetaModelicaCalls(threadData, _inExp);
goto tmp3_done;
}
case 34: {
tmpMeta1 = _inExp;
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
if (++tmp4 < 35) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubExp(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inExp, modelica_metatype _inSubs)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _inSubs;
{
modelica_integer _sub;
modelica_integer _istart;
modelica_integer _istep;
modelica_integer _istop;
modelica_metatype _tp = NULL;
modelica_metatype _e = NULL;
modelica_metatype _eLst = NULL;
modelica_metatype _subs = NULL;
modelica_boolean _hasRange;
modelica_metatype _step = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
_e = tmp4_1;
tmpMeta1 = _e;
goto tmp3_done;
}
case 1: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_metatype tmpMeta9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_tp = tmpMeta6;
_e = tmpMeta7;
tmp4 += 1;
_tp = omc_Expression_unliftArray(threadData, _tp);
tmpMeta8 = mmc_mk_box3(24, &DAE_Exp_ASUB__desc, _e, _inSubs);
tmpMeta9 = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp, tmpMeta8);
tmpMeta1 = tmpMeta9;
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
modelica_metatype tmpMeta13;
modelica_integer tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,1) == 0) goto tmp3_end;
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta11 = MMC_CAR(tmp4_2);
tmpMeta12 = MMC_CDR(tmp4_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta11,0,1) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta11), 2));
tmp14 = mmc_unbox_integer(tmpMeta13);
if (!listEmpty(tmpMeta12)) goto tmp3_end;
_eLst = tmpMeta10;
_sub = tmp14;
if (!(_sub <= listLength(_eLst))) goto tmp3_end;
tmpMeta1 = listGet(_eLst, _sub);
goto tmp3_done;
}
case 3: {
tmpMeta1 = omc_ExpressionSimplify_simplifyAsubSlicing(threadData, _inExp, _inSubs);
goto tmp3_done;
}
case 4: {
modelica_metatype tmpMeta15;
modelica_metatype tmpMeta16;
{
modelica_metatype _exp;
for (tmpMeta15 = _inSubs; !listEmpty(tmpMeta15); tmpMeta15=MMC_CDR(tmpMeta15))
{
_exp = MMC_CAR(tmpMeta15);
omc_Expression_expInt(threadData, _exp);
}
}
tmpMeta1 = omc_List_foldr(threadData, _inSubs, boxvar_ExpressionSimplify_simplifyAsub, _inExp);
goto tmp3_done;
}
case 5: {
modelica_metatype tmpMeta17;
modelica_boolean tmp46;
modelica_metatype tmpMeta47;
_hasRange = 0;
{
modelica_metatype __omcQ_24tmpVar55;
modelica_metatype* tmp18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_metatype __omcQ_24tmpVar54;
modelica_integer tmp45;
modelica_metatype _exp_loopVar = 0;
modelica_metatype _exp;
_exp_loopVar = _inSubs;
tmpMeta19 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar55 = tmpMeta19;
tmp18 = &__omcQ_24tmpVar55;
while(1) {
tmp45 = 1;
if (!listEmpty(_exp_loopVar)) {
_exp = MMC_CAR(_exp_loopVar);
_exp_loopVar = MMC_CDR(_exp_loopVar);
tmp45--;
}
if (tmp45 == 0) {
{
modelica_metatype tmp23_1;
tmp23_1 = _exp;
{
volatile mmc_switch_type tmp23;
int tmp24;
tmp23 = 0;
for (; tmp23 < 2; tmp23++) {
switch (MMC_SWITCH_CAST(tmp23)) {
case 0: {
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
modelica_integer tmp27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_metatype tmpMeta30;
modelica_integer tmp31;
modelica_metatype tmpMeta32;
if (mmc__uniontype__metarecord__typedef__equal(tmp23_1,18,4) == 0) goto tmp22_end;
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp23_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta25,0,1) == 0) goto tmp22_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta25), 2));
tmp27 = mmc_unbox_integer(tmpMeta26);
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp23_1), 4));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp23_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta29,0,1) == 0) goto tmp22_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta29), 2));
tmp31 = mmc_unbox_integer(tmpMeta30);
_istart = tmp27;
_step = tmpMeta28;
_istop = tmp31;
{
modelica_metatype __omcQ_24tmpVar53;
modelica_metatype* tmp33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype __omcQ_24tmpVar52;
modelica_integer tmp36;
modelica_metatype _i_loopVar = 0;
modelica_integer tmp37 = 0;
modelica_metatype _i;
{
modelica_metatype tmp40_1;
tmp40_1 = _step;
{
volatile mmc_switch_type tmp40;
int tmp41;
tmp40 = 0;
for (; tmp40 < 2; tmp40++) {
switch (MMC_SWITCH_CAST(tmp40)) {
case 0: {
if (!optionNone(tmp40_1)) goto tmp39_end;
tmp37 = ((modelica_integer) 1);
goto tmp39_done;
}
case 1: {
modelica_metatype tmpMeta42;
modelica_metatype tmpMeta43;
modelica_integer tmp44;
if (optionNone(tmp40_1)) goto tmp39_end;
tmpMeta42 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp40_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta42,0,1) == 0) goto tmp39_end;
tmpMeta43 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta42), 2));
tmp44 = mmc_unbox_integer(tmpMeta43);
_istep = tmp44;
tmp37 = _istep;
goto tmp39_done;
}
}
goto tmp39_end;
tmp39_end: ;
}
goto goto_38;
goto_38:;
goto goto_21;
goto tmp39_done;
tmp39_done:;
}
}_i_loopVar = omc_ExpressionSimplify_simplifyRange(threadData, _istart, tmp37, _istop);
tmpMeta34 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar53 = tmpMeta34;
tmp33 = &__omcQ_24tmpVar53;
while(1) {
tmp36 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp36--;
}
if (tmp36 == 0) {
tmpMeta35 = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, _i);
__omcQ_24tmpVar52 = tmpMeta35;
*tmp33 = mmc_mk_cons(__omcQ_24tmpVar52,0);
tmp33 = &MMC_CDR(*tmp33);
} else if (tmp36 == 1) {
break;
} else {
goto goto_21;
}
}
*tmp33 = mmc_mk_nil();
tmpMeta32 = __omcQ_24tmpVar53;
}
_e = omc_Expression_makeArray(threadData, tmpMeta32, _OMC_LIT54, 1);
_hasRange = 1;
tmpMeta20 = _e;
goto tmp22_done;
}
case 1: {
tmpMeta20 = _exp;
goto tmp22_done;
}
}
goto tmp22_end;
tmp22_end: ;
}
goto goto_21;
goto_21:;
goto goto_2;
goto tmp22_done;
tmp22_done:;
}
}__omcQ_24tmpVar54 = tmpMeta20;
*tmp18 = mmc_mk_cons(__omcQ_24tmpVar54,0);
tmp18 = &MMC_CDR(*tmp18);
} else if (tmp45 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp18 = mmc_mk_nil();
tmpMeta17 = __omcQ_24tmpVar55;
}
_subs = tmpMeta17;
tmp46 = _hasRange;
if (1 != tmp46) goto goto_2;
tmpMeta47 = mmc_mk_box3(24, &DAE_Exp_ASUB__desc, _inExp, _subs);
tmpMeta1 = tmpMeta47;
goto tmp3_done;
}
case 6: {
tmpMeta1 = _origExp;
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
_outExp = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyRSub(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fe)
{
modelica_metatype _e = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_e = __omcQ_24in_5Fe;
{
modelica_metatype tmp4_1;
tmp4_1 = _e;
{
modelica_metatype _cr = NULL;
modelica_metatype _exps = NULL;
modelica_metatype _comp = NULL;
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
modelica_metatype _vars = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
modelica_integer tmp9;
modelica_metatype tmpMeta10;
modelica_metatype tmpMeta11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,4) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,6,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta6), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp9 = mmc_unbox_integer(tmpMeta8);
if (-1 != tmp9) goto tmp3_end;
_cr = tmpMeta7;
tmpMeta10 = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta11 = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_ComponentReference_joinCrefs(threadData, _cr, omc_ComponentReference_makeCrefIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 5))), tmpMeta10)), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 5))));
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
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_metatype tmpMeta20;
modelica_integer tmp21;
modelica_metatype tmpMeta22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,4) == 0) goto tmp3_end;
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta12,13,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 3));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta12), 4));
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta15), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta16,9,3) == 0) goto tmp3_end;
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta17,3,1) == 0) goto tmp3_end;
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta17), 2));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta16), 3));
tmpMeta20 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp21 = mmc_unbox_integer(tmpMeta20);
if (-1 != tmp21) goto tmp3_end;
_p1 = tmpMeta13;
_exps = tmpMeta14;
_p2 = tmpMeta18;
_vars = tmpMeta19;
if (!omc_AbsynUtil_pathEqual(threadData, _p1, _p2)) goto tmp3_end;
{
modelica_metatype __omcQ_24tmpVar57;
modelica_metatype* tmp23;
modelica_metatype tmpMeta24;
modelica_string __omcQ_24tmpVar56;
modelica_integer tmp25;
modelica_metatype _v_loopVar = 0;
modelica_metatype _v;
_v_loopVar = _vars;
tmpMeta24 = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar57 = tmpMeta24;
tmp23 = &__omcQ_24tmpVar57;
while(1) {
tmp25 = 1;
if (!listEmpty(_v_loopVar)) {
_v = MMC_CAR(_v_loopVar);
_v_loopVar = MMC_CDR(_v_loopVar);
tmp25--;
}
if (tmp25 == 0) {
__omcQ_24tmpVar56 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2)));
*tmp23 = mmc_mk_cons(__omcQ_24tmpVar56,0);
tmp23 = &MMC_CDR(*tmp23);
} else if (tmp25 == 1) {
break;
} else {
goto goto_2;
}
}
*tmp23 = mmc_mk_nil();
tmpMeta22 = __omcQ_24tmpVar57;
}
tmpMeta1 = listGet(_exps, omc_List_position1OnTrue(threadData, tmpMeta22, boxvar_stringEq, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 4)))));
goto tmp3_done;
}
case 2: {
modelica_metatype tmpMeta26;
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
modelica_integer tmp30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,23,4) == 0) goto tmp3_end;
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta26,14,4) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 3));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta26), 4));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp30 = mmc_unbox_integer(tmpMeta29);
if (-1 != tmp30) goto tmp3_end;
_exps = tmpMeta27;
_comp = tmpMeta28;
tmpMeta1 = listGet(_exps, omc_List_position1OnTrue(threadData, _comp, boxvar_stringEq, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 4)))));
goto tmp3_done;
}
case 3: {
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
_e = tmpMeta1;
_return: OMC_LABEL_UNUSED
return _e;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyWork(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _options, modelica_metatype *out_outOptions)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outOptions = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _t = NULL;
modelica_metatype _tp = NULL;
modelica_boolean _b2;
modelica_metatype _subs = NULL;
modelica_metatype _c_1 = NULL;
modelica_metatype _op = NULL;
modelica_integer _index_;
modelica_metatype _isExpisASUB = NULL;
modelica_metatype _reductionInfo = NULL;
modelica_metatype _riters = NULL;
modelica_metatype _oe = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 27: {
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta5 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta5;
_oe = tmpMeta6;
tmpMeta[0+0] = omc_ExpressionSimplify_simplifySize(threadData, _inExp, _e1, _oe);
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 23: {
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,2) == 0) goto tmp3_end;
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_tp = tmpMeta7;
_e = tmpMeta8;
_e = omc_ExpressionSimplify_simplifyCast(threadData, _inExp, _e, _tp);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 24: {
modelica_metatype tmpMeta9;
modelica_metatype tmpMeta10;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
tmpMeta9 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta10 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta9;
_subs = tmpMeta10;
_e = omc_ExpressionSimplify_simplifyAsubExp(threadData, _inExp, _e, _subs);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 25: {
tmpMeta[0+0] = omc_ExpressionSimplify_simplifyTSub(threadData, _inExp);
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 11: {
modelica_metatype tmpMeta11;
modelica_metatype tmpMeta12;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta11 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta12 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_op = tmpMeta11;
_e1 = tmpMeta12;
_e = omc_ExpressionSimplify_simplifyUnary(threadData, _inExp, _op, _e1);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 10: {
modelica_metatype tmpMeta13;
modelica_metatype tmpMeta14;
modelica_metatype tmpMeta15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta13 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta14 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta15 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta13;
_op = tmpMeta14;
_e2 = tmpMeta15;
_e = omc_ExpressionSimplify_simplifyBinary(threadData, _inExp, _op, _e1, _e2);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 14: {
modelica_metatype tmpMeta16;
modelica_metatype tmpMeta17;
modelica_metatype tmpMeta18;
modelica_metatype tmpMeta19;
modelica_integer tmp20;
modelica_metatype tmpMeta21;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,5) == 0) goto tmp3_end;
tmpMeta16 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta17 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta18 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta19 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp20 = mmc_unbox_integer(tmpMeta19);
tmpMeta21 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_e1 = tmpMeta16;
_op = tmpMeta17;
_e2 = tmpMeta18;
_index_ = tmp20;
_isExpisASUB = tmpMeta21;
_e = omc_ExpressionSimplify_simplifyRelation(threadData, _inExp, _op, _e1, _e2, _index_, _isExpisASUB);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 13: {
modelica_metatype tmpMeta22;
modelica_metatype tmpMeta23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmpMeta22 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta23 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_op = tmpMeta22;
_e1 = tmpMeta23;
_e = omc_ExpressionSimplify_simplifyUnary(threadData, _inExp, _op, _e1);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 12: {
modelica_metatype tmpMeta24;
modelica_metatype tmpMeta25;
modelica_metatype tmpMeta26;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta24 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta25 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta26 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta24;
_op = tmpMeta25;
_e2 = tmpMeta26;
_e = omc_ExpressionSimplify_simplifyLBinary(threadData, _inExp, _op, _e1, _e2);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 15: {
modelica_metatype tmpMeta27;
modelica_metatype tmpMeta28;
modelica_metatype tmpMeta29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,3) == 0) goto tmp3_end;
tmpMeta27 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta28 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta29 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta27;
_e2 = tmpMeta28;
_e3 = tmpMeta29;
_e = omc_ExpressionSimplify_simplifyIfExp(threadData, _inExp, _e1, _e2, _e3);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 9: {
modelica_metatype tmpMeta30;
modelica_metatype tmpMeta31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta30 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta31 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_c_1 = tmpMeta30;
_t = tmpMeta31;
_e = omc_ExpressionSimplify_simplifyCref(threadData, _inExp, _c_1, _t);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 30: {
modelica_metatype tmpMeta32;
modelica_metatype tmpMeta33;
modelica_metatype tmpMeta34;
modelica_metatype tmpMeta35;
modelica_metatype tmpMeta36;
modelica_boolean tmp37;
modelica_metatype tmpMeta38;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta32 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta33 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta34 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_reductionInfo = tmpMeta32;
_e1 = tmpMeta33;
_riters = tmpMeta34;
tmpMeta35 = MMC_REFSTRUCTLIT(mmc_nil);
_riters = omc_ExpressionSimplify_simplifyReductionIterators(threadData, _riters, tmpMeta35, 0 ,&_b2);
tmp37 = (modelica_boolean)_b2;
if(tmp37)
{
tmpMeta36 = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, _reductionInfo, _e1, _riters);
tmpMeta38 = tmpMeta36;
}
else
{
tmpMeta38 = _inExp;
}
_exp1 = tmpMeta38;
tmpMeta[0+0] = omc_ExpressionSimplify_simplifyReduction(threadData, _exp1);
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 16: {
tmpMeta[0+0] = omc_ExpressionSimplify_simplifyCall(threadData, _inExp);
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 26: {
tmpMeta[0+0] = omc_ExpressionSimplify_simplifyRSub(threadData, _inExp);
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 36: {
tmpMeta[0+0] = omc_ExpressionSimplify_simplifyMatch(threadData, _inExp);
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 38: {
tmpMeta[0+0] = omc_ExpressionSimplify_simplifyUnbox(threadData, _inExp);
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 37: {
tmpMeta[0+0] = omc_ExpressionSimplify_simplifyUnbox(threadData, _inExp);
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 32: {
tmpMeta[0+0] = omc_ExpressionSimplify_simplifyCons(threadData, _inExp);
tmpMeta[0+1] = _options;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outOptions = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outOptions) { *out_outOptions = _outOptions; }
return _outExp;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplify1time(threadData_t *threadData, modelica_metatype _e)
{
modelica_metatype _outE = NULL;
modelica_real _t1;
modelica_real _t2;
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
modelica_metatype tmpMeta4;
modelica_metatype tmpMeta5;
modelica_metatype tmpMeta6;
modelica_boolean tmp7;
modelica_string tmp8;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_t1 = mmc_clock();
_outE = omc_ExpressionSimplify_simplify1(threadData, _e, NULL);
_t2 = mmc_clock();
tmp7 = (modelica_boolean)(_t2 - _t1 > 0.01);
if(tmp7)
{
tmpMeta1 = stringAppend(_OMC_LIT184,realString(_t2 - _t1));
tmpMeta2 = stringAppend(tmpMeta1,_OMC_LIT185);
tmpMeta3 = stringAppend(tmpMeta2,omc_ExpressionDump_printExpStr(threadData, _e));
tmpMeta4 = stringAppend(tmpMeta3,_OMC_LIT186);
tmpMeta5 = stringAppend(tmpMeta4,omc_ExpressionDump_printExpStr(threadData, _outE));
tmpMeta6 = stringAppend(tmpMeta5,_OMC_LIT187);
tmp8 = tmpMeta6;
}
else
{
tmp8 = _OMC_LIT70;
}
fputs(MMC_STRINGDATA(tmp8),stdout);
_return: OMC_LABEL_UNUSED
return _outE;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplify1TraverseHelper(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inA, modelica_metatype *out_a)
{
modelica_metatype _outExp = NULL;
modelica_metatype _a = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_a = _inA;
_outExp = omc_ExpressionSimplify_simplify1(threadData, _inExp, NULL);
_return: OMC_LABEL_UNUSED
if (out_a) { *out_a = _a; }
return _outExp;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyTraverseHelper(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inA, modelica_metatype *out_a)
{
modelica_metatype _exp = NULL;
modelica_metatype _a = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_a = _inA;
_exp = omc_ExpressionSimplify_simplify(threadData, _inExp, NULL);
_return: OMC_LABEL_UNUSED
if (out_a) { *out_a = _a; }
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyWithOptions(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _options, modelica_boolean *out_hasChanged)
{
modelica_metatype _outExp = NULL;
modelica_boolean _hasChanged;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _options;
{
modelica_metatype _e = NULL;
modelica_metatype _eNew = NULL;
modelica_boolean _b;
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
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta6,1,0) == 0) goto tmp3_end;
_e = tmp4_1;
_eNew = omc_ExpressionSimplify_simplify1WithOptions(threadData, _e, _options, NULL);
omc_Error_assertionOrAddSourceMessage(threadData, omc_Expression_isConstValue(threadData, _eNew), _OMC_LIT4, _OMC_LIT189, _OMC_LIT92);
_b = (!omc_Expression_expEqual(threadData, _e, _eNew));
tmpMeta[0+0] = _eNew;
tmp1_c1 = _b;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
_e = tmp4_1;
tmp7 = omc_Config_getNoSimplify(threadData);
if (0 != tmp7) goto goto_2;
_eNew = omc_ExpressionSimplify_simplify1WithOptions(threadData, _e, _options, NULL);
_eNew = omc_ExpressionSimplify_simplify2(threadData, _eNew, 1, 1);
_eNew = omc_ExpressionSimplify_simplify1WithOptions(threadData, _eNew, _options, NULL);
_b = (!omc_Expression_expEqual(threadData, _e, _eNew));
tmpMeta[0+0] = _eNew;
tmp1_c1 = _b;
goto tmp3_done;
}
case 2: {
_e = tmp4_1;
tmpMeta[0+0] = omc_ExpressionSimplify_simplify1WithOptions(threadData, _e, _options, &tmp1_c1);
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
_outExp = tmpMeta[0+0];
_hasChanged = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_hasChanged) { *out_hasChanged = _hasChanged; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_simplifyWithOptions(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _options, modelica_metatype *out_hasChanged)
{
modelica_boolean _hasChanged;
modelica_metatype _outExp = NULL;
_outExp = omc_ExpressionSimplify_simplifyWithOptions(threadData, _inExp, _options, &_hasChanged);
if (out_hasChanged) { *out_hasChanged = mmc_mk_icon(_hasChanged); }
return _outExp;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyUnaryExp(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _e1 = NULL;
modelica_metatype _op = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_op = tmpMeta6;
_e1 = tmpMeta7;
tmpMeta1 = omc_ExpressionSimplify_simplifyUnary(threadData, _inExp, _op, _e1);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inExp;
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype omc_ExpressionSimplify_simplifyBinaryExp(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _op = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_metatype tmpMeta6;
modelica_metatype tmpMeta7;
modelica_metatype tmpMeta8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta6 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta7 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta8 = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta6;
_op = tmpMeta7;
_e2 = tmpMeta8;
tmpMeta1 = omc_ExpressionSimplify_simplifyBinary(threadData, _inExp, _op, _e1, _e2);
goto tmp3_done;
}
case 1: {
tmpMeta1 = _inExp;
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype omc_ExpressionSimplify_condsimplify(threadData_t *threadData, modelica_boolean _cond, modelica_metatype __omcQ_24in_5FioExp, modelica_boolean *out_hasChanged)
{
modelica_metatype _ioExp = NULL;
modelica_boolean _hasChanged;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ioExp = __omcQ_24in_5FioExp;
_hasChanged = 0;
if(_cond)
{
_ioExp = omc_ExpressionSimplify_simplifyWithOptions(threadData, _ioExp, _OMC_LIT166 ,&_hasChanged);
}
_return: OMC_LABEL_UNUSED
if (out_hasChanged) { *out_hasChanged = _hasChanged; }
return _ioExp;
}
modelica_metatype boxptr_ExpressionSimplify_condsimplify(threadData_t *threadData, modelica_metatype _cond, modelica_metatype __omcQ_24in_5FioExp, modelica_metatype *out_hasChanged)
{
modelica_integer tmp1;
modelica_boolean _hasChanged;
modelica_metatype _ioExp = NULL;
tmp1 = mmc_unbox_integer(_cond);
_ioExp = omc_ExpressionSimplify_condsimplify(threadData, tmp1, __omcQ_24in_5FioExp, &_hasChanged);
if (out_hasChanged) { *out_hasChanged = mmc_mk_icon(_hasChanged); }
return _ioExp;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplify(threadData_t *threadData, modelica_metatype _inExp, modelica_boolean *out_hasChanged)
{
modelica_metatype _outExp = NULL;
modelica_boolean _hasChanged;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = omc_ExpressionSimplify_simplifyWithOptions(threadData, _inExp, _OMC_LIT166 ,&_hasChanged);
_return: OMC_LABEL_UNUSED
if (out_hasChanged) { *out_hasChanged = _hasChanged; }
return _outExp;
}
modelica_metatype boxptr_ExpressionSimplify_simplify(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype *out_hasChanged)
{
modelica_boolean _hasChanged;
modelica_metatype _outExp = NULL;
_outExp = omc_ExpressionSimplify_simplify(threadData, _inExp, &_hasChanged);
if (out_hasChanged) { *out_hasChanged = mmc_mk_icon(_hasChanged); }
return _outExp;
}
