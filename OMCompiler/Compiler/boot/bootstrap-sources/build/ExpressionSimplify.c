#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/ExpressionSimplify.c"
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
#define _OMC_LIT41_data "sinh"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT41,4,_OMC_LIT41_data);
#define _OMC_LIT41 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "cosh"
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
#define _OMC_LIT79_data "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/FrontEnd/ExpressionSimplify.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT79,79,_OMC_LIT79_data);
#define _OMC_LIT79 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT79)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT80_6,1602262265.0);
#define _OMC_LIT80_6 MMC_REFREALLIT(_OMC_LIT_STRUCT80_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT80,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT79,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1731)),MMC_IMMEDIATE(MMC_TAGFIXNUM(7)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1731)),MMC_IMMEDIATE(MMC_TAGFIXNUM(109)),_OMC_LIT80_6}};
#define _OMC_LIT80 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data "ExpressionSimplify.evalCat: cat got uneven dimensions for dim="
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,62,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,2,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT83_6,1602262265.0);
#define _OMC_LIT83_6 MMC_REFREALLIT(_OMC_LIT_STRUCT83_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT83,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT79,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1670)),MMC_IMMEDIATE(MMC_TAGFIXNUM(7)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1670)),MMC_IMMEDIATE(MMC_TAGFIXNUM(180)),_OMC_LIT83_6}};
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
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT108,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(122)),_OMC_LIT70,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT104,_OMC_LIT105,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT107}};
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
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT125,1,7) {&DAE_InlineType_NO__INLINE__desc,}};
#define _OMC_LIT125 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT125)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT126,1,3) {&DAE_TailCall_NO__TAIL__desc,}};
#define _OMC_LIT126 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT126)
#define _OMC_LIT127_data "listReverse"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT127,11,_OMC_LIT127_data);
#define _OMC_LIT127 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT127)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT128,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT127}};
#define _OMC_LIT128 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT128)
#define _OMC_LIT129_data "list"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT129,4,_OMC_LIT129_data);
#define _OMC_LIT129 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT129)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT130,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT129}};
#define _OMC_LIT130 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT130)
#define _OMC_LIT131_data "sourceInfo() - simplify?\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT131,25,_OMC_LIT131_data);
#define _OMC_LIT131 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT131)
#define _OMC_LIT132_data "listAppend"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT132,10,_OMC_LIT132_data);
#define _OMC_LIT132 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT132)
#define _OMC_LIT133_data "intString"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT133,9,_OMC_LIT133_data);
#define _OMC_LIT133 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT133)
#define _OMC_LIT134_data "realString"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT134,10,_OMC_LIT134_data);
#define _OMC_LIT134 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT134)
#define _OMC_LIT135_data "boolString"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT135,10,_OMC_LIT135_data);
#define _OMC_LIT135 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT135)
#define _OMC_LIT136_data "listLength"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT136,10,_OMC_LIT136_data);
#define _OMC_LIT136 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT136)
#define _OMC_LIT137_data "mmc_mk_some"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT137,11,_OMC_LIT137_data);
#define _OMC_LIT137 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT137)
#define _OMC_LIT138_data "sourceInfo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT138,10,_OMC_LIT138_data);
#define _OMC_LIT138 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT138)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT139,2,27) {&DAE_Operator_NOT__desc,_OMC_LIT87}};
#define _OMC_LIT139 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT139)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT140,2,31) {&DAE_Exp_LIST__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT140 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT140)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT141,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT141 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT141)
#define _OMC_LIT142_data "Expression simplification iterated to the fix-point maximum, which may be a performance bottleneck. The last two iterations were: %s, and %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT142,141,_OMC_LIT142_data);
#define _OMC_LIT142 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT142)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT143,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT142}};
#define _OMC_LIT143 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT143)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT144,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(209)),_OMC_LIT0,_OMC_LIT141,_OMC_LIT143}};
#define _OMC_LIT144 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT144)
#define _OMC_LIT145_data "ExpressionSimplify"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT145,18,_OMC_LIT145_data);
#define _OMC_LIT145 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT145)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT146,1,6) {&ErrorTypes_Severity_NOTIFICATION__desc,}};
#define _OMC_LIT146 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT146)
#define _OMC_LIT147_data "Expression simplification '%s' → '%s' changed the type from %s to %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT147,71,_OMC_LIT147_data);
#define _OMC_LIT147 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT147)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT148,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT147}};
#define _OMC_LIT148 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT148)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT149,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(273)),_OMC_LIT0,_OMC_LIT146,_OMC_LIT148}};
#define _OMC_LIT149 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT149)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT150,1,6) {&ErrorTypes_MessageType_SYMBOLIC__desc,}};
#define _OMC_LIT150 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT150)
#define _OMC_LIT151_data "Simplification produced a higher complexity (%s) than the original (%s). The simplification was: %s => %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT151,106,_OMC_LIT151_data);
#define _OMC_LIT151 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT151)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT152,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT151}};
#define _OMC_LIT152 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT152)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT153,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(523)),_OMC_LIT150,_OMC_LIT146,_OMC_LIT152}};
#define _OMC_LIT153 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT153)
#define _OMC_LIT154_data "checkSimplify"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT154,13,_OMC_LIT154_data);
#define _OMC_LIT154 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT154)
#define _OMC_LIT155_data "Enables checks for expression simplification and prints a notification whenever an undesirable transformation has been performed."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT155,129,_OMC_LIT155_data);
#define _OMC_LIT155 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT155)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT156,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT155}};
#define _OMC_LIT156 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT156)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT157,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(66)),_OMC_LIT154,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT156}};
#define _OMC_LIT157 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT157)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT158,1,3) {&ExpressionSimplifyTypes_Evaluate_NO__EVAL__desc,}};
#define _OMC_LIT158 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT158)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT159,2,0) {MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT158}};
#define _OMC_LIT159 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT159)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT160,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT61}};
#define _OMC_LIT160 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT160)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT161,2,3) {&DAE_Exp_ICONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT161 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT161)
#define _OMC_LIT162_data "atan"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT162,4,_OMC_LIT162_data);
#define _OMC_LIT162 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT162)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT163,2,4) {&DAE_Operator_SUB__desc,_OMC_LIT30}};
#define _OMC_LIT163 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT163)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT164,1.570796326794897);
#define _OMC_LIT164 MMC_REFREALLIT(_OMC_LIT_STRUCT164)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT165,2,4) {&DAE_Exp_RCONST__desc,_OMC_LIT164}};
#define _OMC_LIT165 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT165)
#define _OMC_LIT166_data "homotopy"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT166,8,_OMC_LIT166_data);
#define _OMC_LIT166 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT166)
#define _OMC_LIT167_data "noEvent"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT167,7,_OMC_LIT167_data);
#define _OMC_LIT167 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT167)
#define _OMC_LIT168_data "identity"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT168,8,_OMC_LIT168_data);
#define _OMC_LIT168 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT168)
#define _OMC_LIT169_data "diagonal"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT169,8,_OMC_LIT169_data);
#define _OMC_LIT169 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT169)
#define _OMC_LIT170_data "mod"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT170,3,_OMC_LIT170_data);
#define _OMC_LIT170 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT170)
#define _OMC_LIT171_data "integer"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT171,7,_OMC_LIT171_data);
#define _OMC_LIT171 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT171)
#define _OMC_LIT172_data "atan2"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT172,5,_OMC_LIT172_data);
#define _OMC_LIT172 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT172)
#define _OMC_LIT173_data "simplify1 took "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT173,15,_OMC_LIT173_data);
#define _OMC_LIT173 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT173)
#define _OMC_LIT174_data " seconds for exp: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT174,18,_OMC_LIT174_data);
#define _OMC_LIT174 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT174)
#define _OMC_LIT175_data " \nsimplified to :"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT175,17,_OMC_LIT175_data);
#define _OMC_LIT175 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT175)
#define _OMC_LIT176_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT176,1,_OMC_LIT176_data);
#define _OMC_LIT176 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT176)
#define _OMC_LIT177_data "eval exp failed"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT177,15,_OMC_LIT177_data);
#define _OMC_LIT177 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT177)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT178,2,1) {_OMC_LIT177,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT178 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT178)
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
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _v1;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (listEmpty(tmpMeta[2])) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (listEmpty(tmpMeta[4])) MMC_THROW_INTERNAL();
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) MMC_THROW_INTERNAL();
_x1 = tmpMeta[1];
_x2 = tmpMeta[3];
_x3 = tmpMeta[5];
tmpMeta[0] = _v2;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (listEmpty(tmpMeta[2])) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (listEmpty(tmpMeta[4])) MMC_THROW_INTERNAL();
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) MMC_THROW_INTERNAL();
_y1 = tmpMeta[1];
_y2 = tmpMeta[3];
_y3 = tmpMeta[5];
tmpMeta[0] = mmc_mk_cons(omc_Expression_makeDiff(threadData, omc_Expression_makeProduct(threadData, _x2, _y3), omc_Expression_makeProduct(threadData, _x3, _y2)), mmc_mk_cons(omc_Expression_makeDiff(threadData, omc_Expression_makeProduct(threadData, _x3, _y1), omc_Expression_makeProduct(threadData, _x1, _y3)), mmc_mk_cons(omc_Expression_makeDiff(threadData, omc_Expression_makeProduct(threadData, _x1, _y2), omc_Expression_makeProduct(threadData, _x2, _y1)), MMC_REFSTRUCTLIT(mmc_nil))));
_res = tmpMeta[0];
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
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _v1;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (listEmpty(tmpMeta[2])) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (listEmpty(tmpMeta[4])) MMC_THROW_INTERNAL();
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) MMC_THROW_INTERNAL();
_x1 = tmpMeta[1];
_x2 = tmpMeta[3];
_x3 = tmpMeta[5];
_zero = omc_Expression_makeConstZero(threadData, omc_Expression_typeof(threadData, _x1));
tmpMeta[1] = mmc_mk_cons(_zero, mmc_mk_cons(omc_Expression_negate(threadData, _x3), mmc_mk_cons(_x2, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta[2] = mmc_mk_cons(_x3, mmc_mk_cons(_zero, mmc_mk_cons(omc_Expression_negate(threadData, _x1), MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta[3] = mmc_mk_cons(omc_Expression_negate(threadData, _x2), mmc_mk_cons(_x1, mmc_mk_cons(_zero, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], mmc_mk_cons(tmpMeta[2], mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil))));
_res = tmpMeta[0];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _e1;
tmp3_2 = _e2;
{
modelica_real _r1;
modelica_real _r2;
modelica_integer _i1;
modelica_integer _i2;
modelica_boolean _b1;
modelica_boolean _b2;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 7; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
if (!optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[0] = mmc_mk_some(_e1);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if (!optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[0] = mmc_mk_some(_e1);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (!optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[0] = mmc_mk_some(_e1);
goto tmp2_done;
}
case 3: {
modelica_real tmp5;
modelica_real tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_real(tmpMeta[1]);
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp6 = mmc_unbox_real(tmpMeta[3]);
_r1 = tmp5;
_r2 = tmp6;
tmpMeta[0] = ((_r1 < _r2)?mmc_mk_some(_e1):_e2);
goto tmp2_done;
}
case 4: {
modelica_integer tmp7;
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp8 = mmc_unbox_integer(tmpMeta[3]);
_i1 = tmp7;
_i2 = tmp8;
tmpMeta[0] = ((_i1 < _i2)?mmc_mk_some(_e1):_e2);
goto tmp2_done;
}
case 5: {
modelica_integer tmp9;
modelica_integer tmp10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp9 = mmc_unbox_integer(tmpMeta[1]);
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp10 = mmc_unbox_integer(tmpMeta[3]);
_b1 = tmp9;
_b2 = tmp10;
tmp11 = (modelica_boolean)((!_b2) || ((!_b1 && !_b2) || (_b1 && _b2)));
if(tmp11)
{
tmpMeta[2] = _e2;
}
else
{
tmpMeta[1] = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_b1));
tmpMeta[2] = mmc_mk_some(tmpMeta[1]);
}
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _e2;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_maxElement(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _e2)
{
modelica_metatype _elt = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _e1;
tmp3_2 = _e2;
{
modelica_real _r1;
modelica_real _r2;
modelica_integer _i1;
modelica_integer _i2;
modelica_boolean _b1;
modelica_boolean _b2;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 7; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
if (!optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[0] = mmc_mk_some(_e1);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if (!optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[0] = mmc_mk_some(_e1);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (!optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[0] = mmc_mk_some(_e1);
goto tmp2_done;
}
case 3: {
modelica_real tmp5;
modelica_real tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_real(tmpMeta[1]);
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp6 = mmc_unbox_real(tmpMeta[3]);
_r1 = tmp5;
_r2 = tmp6;
tmpMeta[0] = ((_r1 > _r2)?mmc_mk_some(_e1):_e2);
goto tmp2_done;
}
case 4: {
modelica_integer tmp7;
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp8 = mmc_unbox_integer(tmpMeta[3]);
_i1 = tmp7;
_i2 = tmp8;
tmpMeta[0] = ((_i1 > _i2)?mmc_mk_some(_e1):_e2);
goto tmp2_done;
}
case 5: {
modelica_integer tmp9;
modelica_integer tmp10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp9 = mmc_unbox_integer(tmpMeta[1]);
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp10 = mmc_unbox_integer(tmpMeta[3]);
_b1 = tmp9;
_b2 = tmp10;
tmp11 = (modelica_boolean)(_b2 || ((!_b1 && !_b2) || (_b1 && _b2)));
if(tmp11)
{
tmpMeta[2] = _e2;
}
else
{
tmpMeta[1] = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_b1));
tmpMeta[2] = mmc_mk_some(tmpMeta[1]);
}
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _e2;
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _origExp;
{
modelica_metatype _expl = NULL;
modelica_integer _i;
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,22,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],20,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],19,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp5 = mmc_unbox_integer(tmpMeta[4]);
_expl = tmpMeta[3];
_i = tmp5;
tmpMeta[0] = listGet(_expl, _i);
goto tmp2_done;
}
case 1: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,22,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],19,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[3]);
_expl = tmpMeta[2];
_i = tmp6;
tmpMeta[0] = listGet(_expl, _i);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,22,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
_e = tmpMeta[1];
tmpMeta[0] = _e;
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _origExp;
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifySize(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _exp, modelica_metatype _optDim)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _optDim;
{
modelica_integer _i;
modelica_integer _n;
modelica_metatype _t = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _dim = NULL;
modelica_metatype _dimExp = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_dimExp = tmpMeta[1];
_i = omc_Expression_expInt(threadData, _dimExp);
_t = omc_Expression_typeof(threadData, _exp);
_dims = omc_Expression_arrayDimension(threadData, _t);
_dim = listGet(_dims, _i);
_n = omc_Expression_dimensionSize(threadData, _dim);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_n));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _origExp;
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
_outExp = tmpMeta[0];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
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
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta[2];
_e = omc_ExpressionSimplify_simplify(threadData, _e ,&_changed);
tmp5 = (modelica_boolean)_changed;
if(tmp5)
{
tmpMeta[2] = mmc_mk_box2(3, &DAE_EquationExp_PARTIAL__EQUATION__desc, _e);
tmpMeta[3] = tmpMeta[2];
}
else
{
tmpMeta[3] = _exp;
}
_outExp = tmpMeta[3];
tmpMeta[2] = mmc_mk_box3(4, &DAE_SymbolicOperation_SIMPLIFY__desc, _exp, _outExp);
_outSource = omc_ElementSource_condAddSymbolicTransformation(threadData, _changed, _source, tmpMeta[2]);
tmpMeta[0+0] = _outExp;
tmpMeta[0+1] = _outSource;
goto tmp3_done;
}
case 4: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta[2];
_e = omc_ExpressionSimplify_simplify(threadData, _e ,&_changed);
tmp6 = (modelica_boolean)_changed;
if(tmp6)
{
tmpMeta[2] = mmc_mk_box2(4, &DAE_EquationExp_RESIDUAL__EXP__desc, _e);
tmpMeta[3] = tmpMeta[2];
}
else
{
tmpMeta[3] = _exp;
}
_outExp = tmpMeta[3];
tmpMeta[2] = mmc_mk_box3(4, &DAE_SymbolicOperation_SIMPLIFY__desc, _exp, _outExp);
_outSource = omc_ElementSource_condAddSymbolicTransformation(threadData, _changed, _source, tmpMeta[2]);
tmpMeta[0+0] = _outExp;
tmpMeta[0+1] = _outSource;
goto tmp3_done;
}
case 5: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_e1 = omc_ExpressionSimplify_simplify(threadData, _e1 ,&_changed1);
_e2 = omc_ExpressionSimplify_simplify(threadData, _e2 ,&_changed2);
_changed = (_changed1 || _changed2);
tmp7 = (modelica_boolean)_changed;
if(tmp7)
{
tmpMeta[2] = mmc_mk_box3(5, &DAE_EquationExp_EQUALITY__EXPS__desc, _e1, _e2);
tmpMeta[3] = tmpMeta[2];
}
else
{
tmpMeta[3] = _exp;
}
_outExp = tmpMeta[3];
tmpMeta[2] = mmc_mk_box3(4, &DAE_SymbolicOperation_SIMPLIFY__desc, _exp, _outExp);
_outSource = omc_ElementSource_condAddSymbolicTransformation(threadData, _changed, _source, tmpMeta[2]);
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
modelica_metatype _outBool = NULL;
modelica_metatype _rest_expl = NULL;
modelica_metatype _exp = NULL;
modelica_boolean _b2;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outExpl = tmpMeta[0];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_outBool = tmpMeta[1];
_rest_expl = _expl;
{
modelica_metatype _b;
for (tmpMeta[2] = _blst; !listEmpty(tmpMeta[2]); tmpMeta[2]=MMC_CDR(tmpMeta[2]))
{
_b = MMC_CAR(tmpMeta[2]);
tmpMeta[3] = _rest_expl;
if (listEmpty(tmpMeta[3])) MMC_THROW_INTERNAL();
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
_exp = tmpMeta[4];
_rest_expl = tmpMeta[5];
_exp = omc_ExpressionSimplify_condsimplify(threadData, mmc_unbox_boolean(_b), _exp ,&_b2);
tmpMeta[3] = mmc_mk_cons(_exp, _outExpl);
_outExpl = tmpMeta[3];
tmpMeta[3] = mmc_mk_cons(mmc_mk_boolean(_b2), _outBool);
_outBool = tmpMeta[3];
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outBool = tmpMeta[0];
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar0;
int tmp6;
modelica_metatype _exp_loopVar = 0;
modelica_metatype _exp;
_exp_loopVar = _expl;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[2];
tmp1 = &__omcQ_24tmpVar1;
while(1) {
tmp6 = 1;
if (!listEmpty(_exp_loopVar)) {
_exp = MMC_CAR(_exp_loopVar);
_exp_loopVar = MMC_CDR(_exp_loopVar);
tmp6--;
}
if (tmp6 == 0) {
{
{
modelica_metatype _e = NULL;
modelica_boolean _b2;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_e = omc_ExpressionSimplify_simplify(threadData, _exp ,&_b2);
tmpMeta[4] = mmc_mk_cons(mmc_mk_boolean(_b2), _outBool);
_outBool = tmpMeta[4];
tmpMeta[3] = _e;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}__omcQ_24tmpVar0 = tmpMeta[3];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp6 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar1;
}
_outExpl = tmpMeta[1];
_outBool = listReverseInPlace(_outBool);
_return: OMC_LABEL_UNUSED
if (out_outBool) { *out_outBool = _outBool; }
return _outExpl;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyList(threadData_t *threadData, modelica_metatype _expl)
{
modelica_metatype _outExpl = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar2;
int tmp2;
modelica_metatype _exp_loopVar = 0;
modelica_metatype _exp;
_exp_loopVar = _expl;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar3;
while(1) {
tmp2 = 1;
if (!listEmpty(_exp_loopVar)) {
_exp = MMC_CAR(_exp_loopVar);
_exp_loopVar = MMC_CDR(_exp_loopVar);
tmp2--;
}
if (tmp2 == 0) {
__omcQ_24tmpVar2 = omc_ExpressionSimplify_simplify1(threadData, _exp, NULL);
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar3;
}
_outExpl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExpl;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ExpressionSimplify_hasZeroLengthIterator(threadData_t *threadData, modelica_metatype _inIters)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
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
modelica_integer tmp6;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
if (optionNone(tmpMeta[2])) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],3,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[4]);
if (0 != tmp6) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],28,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (!listEmpty(tmpMeta[3])) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],16,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
if (!listEmpty(tmpMeta[3])) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 4: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
_iters = tmpMeta[1];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExps;
{
modelica_metatype _exps = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _acc;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_exp = tmpMeta[1];
_exps = tmpMeta[2];
_exp = omc_ExpressionSimplify_replaceIteratorWithExp(threadData, _exp, _foldExp, _foldName);
_exp = omc_ExpressionSimplify_replaceIteratorWithExp(threadData, _acc, _exp, _resultName);
_inExps = _exps;
_acc = _exp;
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
_exp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyReductionFoldPhase(threadData_t *threadData, modelica_metatype _path, modelica_metatype _optFoldExp, modelica_string _foldName, modelica_string _resultName, modelica_metatype _ty, modelica_metatype _inExps, modelica_metatype _defaultValue)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;modelica_metatype tmp3_4;
tmp3_1 = _path;
tmp3_2 = _optFoldExp;
tmp3_3 = _inExps;
tmp3_4 = _defaultValue;
{
modelica_metatype _val = NULL;
modelica_metatype _arr_exp = NULL;
modelica_metatype _foldExp = NULL;
modelica_metatype _aty = NULL;
modelica_metatype _ty2 = NULL;
modelica_metatype _exps = NULL;
modelica_integer _length;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 7; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (5 != MMC_STRLEN(tmpMeta[1]) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta[1])) != 0) goto tmp2_end;
_aty = omc_Types_unliftArray(threadData, omc_Types_expTypetoTypesType(threadData, _ty));
_length = listLength(_inExps);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_length));
_ty2 = omc_Types_liftArray(threadData, _aty, tmpMeta[1]);
tmpMeta[0] = omc_Expression_makeArray(threadData, _inExps, _ty2, (!omc_Types_isArray(threadData, _aty)));
goto tmp2_done;
}
case 1: {
if (!listEmpty(tmp3_3)) goto tmp2_end;
if (optionNone(tmp3_4)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_4), 1));
_val = tmpMeta[1];
tmpMeta[0] = omc_ValuesUtil_valueExp(threadData, _val, mmc_mk_none());
goto tmp2_done;
}
case 2: {
if (!listEmpty(tmp3_3)) goto tmp2_end;
if (!optionNone(tmp3_4)) goto tmp2_end;
goto goto_1;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (3 != MMC_STRLEN(tmpMeta[1]) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmpMeta[1])) != 0) goto tmp2_end;
_arr_exp = omc_Expression_makeScalarArray(threadData, _inExps, _ty);
tmpMeta[1] = mmc_mk_cons(_arr_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT7, tmpMeta[1], _ty);
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (3 != MMC_STRLEN(tmpMeta[1]) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta[1])) != 0) goto tmp2_end;
_arr_exp = omc_Expression_makeScalarArray(threadData, _inExps, _ty);
tmpMeta[1] = mmc_mk_cons(_arr_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT8, tmpMeta[1], _ty);
goto tmp2_done;
}
case 5: {
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
if (listEmpty(tmp3_3)) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmp3_3);
tmpMeta[3] = MMC_CDR(tmp3_3);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_exp = tmpMeta[2];
tmpMeta[0] = _exp;
goto tmp2_done;
}
case 6: {
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
if (listEmpty(tmp3_3)) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmp3_3);
tmpMeta[3] = MMC_CDR(tmp3_3);
_foldExp = tmpMeta[1];
_exp = tmpMeta[2];
_exps = tmpMeta[3];
tmpMeta[0] = omc_ExpressionSimplify_simplifyReductionFoldPhase2(threadData, _exps, _foldExp, _foldName, _resultName, _exp);
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
_exp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_replaceIteratorWithExpTraverser(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTpl, modelica_metatype *out_outTpl)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outTpl = NULL;
modelica_metatype tmpMeta[17] __attribute__((unused)) = {0};
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
modelica_integer tmp6;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
if (0 != tmp6) goto tmp3_end;
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inTpl;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
if (!listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_id = tmpMeta[3];
_tpl = tmp4_2;
_name = tmpMeta[5];
_iterExp = tmpMeta[6];
if (!(stringEqual(_name, _id))) goto tmp3_end;
tmpMeta[0+0] = _iterExp;
tmpMeta[0+1] = _tpl;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_exp = tmp4_1;
_id = tmpMeta[3];
_name = tmpMeta[4];
_iterExp = tmpMeta[5];
tmp4 += 4;
if (!(stringEqual(_name, _id))) goto tmp3_end;
tmpMeta[2] = mmc_mk_box3(0, _name, _iterExp, mmc_mk_boolean(0));
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = tmpMeta[2];
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],6,2) == 0) goto tmp3_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[10],1,3) == 0) goto tmp3_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 2));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 4));
if (!listEmpty(tmpMeta[12])) goto tmp3_end;
_id = tmpMeta[3];
_ty1 = tmpMeta[4];
_ss = tmpMeta[5];
_cr = tmpMeta[6];
_ty = tmpMeta[7];
_tpl = tmp4_2;
_name = tmpMeta[8];
_replName = tmpMeta[11];
if (!(stringEqual(_name, _id))) goto tmp3_end;
tmpMeta[2] = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _replName, _ty1, _ss, _cr);
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, tmpMeta[2], _ty);
tmpMeta[0+0] = tmpMeta[3];
tmpMeta[0+1] = _tpl;
goto tmp3_done;
}
case 4: {
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],6,2) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,3) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],0,4) == 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 3));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 4));
if (!listEmpty(tmpMeta[10])) goto tmp3_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 5));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_tpl = tmp4_2;
_name = tmpMeta[2];
_replName = tmpMeta[5];
_ss = tmpMeta[6];
_id = tmpMeta[8];
_ty1 = tmpMeta[9];
_cr = tmpMeta[11];
_ty = tmpMeta[12];
tmp4 += 1;
if (!(stringEqual(_name, _id))) goto tmp3_end;
tmpMeta[2] = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _replName, _ty1, _ss, _cr);
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, tmpMeta[2], _ty);
tmpMeta[0+0] = tmpMeta[3];
tmpMeta[0+1] = _tpl;
goto tmp3_done;
}
case 5: {
modelica_boolean tmp7;
modelica_boolean tmp8;
modelica_boolean tmp9;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],13,3) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],9,3) == 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],3,1) == 0) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[11],0,4) == 0) goto tmp3_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 2));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 4));
if (!listEmpty(tmpMeta[13])) goto tmp3_end;
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[14],1,3) == 0) goto tmp3_end;
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[14]), 2));
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[14]), 4));
if (!listEmpty(tmpMeta[16])) goto tmp3_end;
_tpl = tmp4_2;
_name = tmpMeta[2];
_callPath = tmpMeta[4];
_exps = tmpMeta[5];
_recordPath = tmpMeta[9];
_varLst = tmpMeta[10];
_id = tmpMeta[12];
_id2 = tmpMeta[15];
tmp7 = (stringEqual(_name, _id));
if (1 != tmp7) goto goto_2;
tmp8 = omc_AbsynUtil_pathEqual(threadData, _callPath, _recordPath);
if (1 != tmp8) goto goto_2;
tmp9 = (listLength(_varLst) == listLength(_exps));
if (1 != tmp9) goto goto_2;
_i = omc_List_position1OnTrue(threadData, _varLst, boxvar_DAEUtil_typeVarIdentEqual, _id2);
_exp = listGet(_exps, _i);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _tpl;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_exp = tmp4_1;
_id = tmpMeta[3];
_name = tmpMeta[4];
_iterExp = tmpMeta[5];
if (!(stringEqual(_name, _id))) goto tmp3_end;
tmpMeta[2] = mmc_mk_box3(0, _name, _iterExp, mmc_mk_boolean(0));
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = tmpMeta[2];
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
modelica_integer tmp1;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[2] = mmc_mk_box3(0, _name, _iterExp, mmc_mk_boolean(1));
tmpMeta[3] = omc_Expression_traverseExpBottomUp(threadData, _exp, boxvar_ExpressionSimplify_replaceIteratorWithExpTraverser, tmpMeta[2], &tmpMeta[0]);
_outExp = tmpMeta[3];
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp1) MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_getIteratorValues(threadData_t *threadData, modelica_metatype _iter, modelica_metatype _inValues)
{
modelica_metatype _values = NULL;
modelica_string _iter_name = NULL;
modelica_metatype _range = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _iter;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
if (!optionNone(tmpMeta[3])) MMC_THROW_INTERNAL();
_iter_name = tmpMeta[1];
_range = tmpMeta[2];
_values = omc_Expression_getArrayOrRangeContents(threadData, _range);
_values = omc_List_threadMap1(threadData, _values, _inValues, boxvar_ExpressionSimplify_replaceIteratorWithExp, _iter_name);
_return: OMC_LABEL_UNUSED
return _values;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyReduction(threadData_t *threadData, modelica_metatype _inReduction)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inReduction;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 8; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,27,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_v = tmpMeta[3];
_iterators = tmpMeta[4];
tmp5 = omc_ExpressionSimplify_hasZeroLengthIterator(threadData, _iterators);
if (1 != tmp5) goto goto_1;
tmpMeta[0] = omc_ValuesUtil_valueExp(threadData, _v, mmc_mk_none());
goto tmp2_done;
}
case 1: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,27,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_iterators = tmpMeta[1];
tmp6 = omc_ExpressionSimplify_hasZeroLengthIterator(threadData, _iterators);
if (1 != tmp6) goto goto_1;
tmpMeta[0] = omc_ValuesUtil_valueExp(threadData, _OMC_LIT10, mmc_mk_none());
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,27,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 2));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 3));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 4));
if (!optionNone(tmpMeta[14])) goto tmp2_end;
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_path = tmpMeta[2];
_ty = tmpMeta[3];
_defaultValue = tmpMeta[4];
_foldName = tmpMeta[5];
_resultName = tmpMeta[6];
_foldExp = tmpMeta[7];
_expr = tmpMeta[8];
_iter_name = tmpMeta[12];
_range = tmpMeta[13];
_values = omc_Expression_getArrayOrRangeContents(threadData, _range);
_ety = omc_Types_simplifyType(threadData, _ty);
_values = omc_List_map2(threadData, _values, boxvar_ExpressionSimplify_replaceIteratorWithExp, _expr, _iter_name);
tmpMeta[0] = omc_ExpressionSimplify_simplifyReductionFoldPhase(threadData, _path, _foldExp, _foldName, _resultName, _ety, _values, _defaultValue);
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,27,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,0) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_path = tmpMeta[2];
_ty = tmpMeta[4];
_defaultValue = tmpMeta[5];
_foldName = tmpMeta[6];
_resultName = tmpMeta[7];
_foldExp = tmpMeta[8];
_expr = tmpMeta[9];
_iterators = tmpMeta[10];
tmp3 += 3;
tmpMeta[1] = _iterators;
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
if (!optionNone(tmpMeta[6])) goto goto_1;
_iter_name = tmpMeta[4];
_range = tmpMeta[5];
_iterators = tmpMeta[3];
_values = omc_Expression_getArrayOrRangeContents(threadData, _range);
_ety = omc_Types_simplifyType(threadData, _ty);
_values = omc_List_map2(threadData, _values, boxvar_ExpressionSimplify_replaceIteratorWithExp, _expr, _iter_name);
_values = omc_List_fold(threadData, _iterators, boxvar_ExpressionSimplify_getIteratorValues, _values);
tmpMeta[0] = omc_ExpressionSimplify_simplifyReductionFoldPhase(threadData, _path, _foldExp, _foldName, _resultName, _ety, _values, _defaultValue);
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,27,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (5 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,0) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (listEmpty(tmpMeta[11])) goto tmp2_end;
tmpMeta[12] = MMC_CAR(tmpMeta[11]);
tmpMeta[13] = MMC_CDR(tmpMeta[11]);
_path = tmpMeta[2];
_ty = tmpMeta[5];
_foldName = tmpMeta[6];
_resultName = tmpMeta[7];
_expr = tmpMeta[8];
_iter = tmpMeta[10];
_iterators = tmpMeta[11];
_foldName2 = omc_Util_getTempVariableIndex(threadData);
_resultName2 = omc_Util_getTempVariableIndex(threadData);
_ty1 = omc_Expression_unliftArray(threadData, _ty);
tmpMeta[1] = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _path, _OMC_LIT11, _ty1, mmc_mk_none(), _foldName, _resultName, mmc_mk_none());
tmpMeta[2] = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta[1], _expr, _iterators);
_expr = tmpMeta[2];
tmpMeta[1] = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _path, _OMC_LIT11, _ty, mmc_mk_none(), _foldName2, _resultName2, mmc_mk_none());
tmpMeta[2] = mmc_mk_cons(_iter, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta[1], _expr, tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,27,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,0) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
if (!optionNone(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (listEmpty(tmpMeta[10])) goto tmp2_end;
tmpMeta[11] = MMC_CAR(tmpMeta[10]);
tmpMeta[12] = MMC_CDR(tmpMeta[10]);
if (listEmpty(tmpMeta[12])) goto tmp2_end;
tmpMeta[13] = MMC_CAR(tmpMeta[12]);
tmpMeta[14] = MMC_CDR(tmpMeta[12]);
_path = tmpMeta[2];
_ty = tmpMeta[4];
_defaultValue = tmpMeta[5];
_foldName = tmpMeta[6];
_resultName = tmpMeta[7];
_expr = tmpMeta[9];
_iter = tmpMeta[11];
_iterators = tmpMeta[12];
tmp3 += 1;
_foldName2 = omc_Util_getTempVariableIndex(threadData);
_resultName2 = omc_Util_getTempVariableIndex(threadData);
tmpMeta[1] = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _path, _OMC_LIT11, _ty, _defaultValue, _foldName2, _resultName2, mmc_mk_none());
tmpMeta[2] = mmc_mk_cons(_iter, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta[1], _expr, tmpMeta[2]);
_expr = tmpMeta[3];
tmpMeta[1] = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _path, _OMC_LIT11, _ty, _defaultValue, _foldName, _resultName, mmc_mk_none());
tmpMeta[2] = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta[1], _expr, _iterators);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,27,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,0) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
if (optionNone(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 1));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (listEmpty(tmpMeta[11])) goto tmp2_end;
tmpMeta[12] = MMC_CAR(tmpMeta[11]);
tmpMeta[13] = MMC_CDR(tmpMeta[11]);
if (listEmpty(tmpMeta[13])) goto tmp2_end;
tmpMeta[14] = MMC_CAR(tmpMeta[13]);
tmpMeta[15] = MMC_CDR(tmpMeta[13]);
_path = tmpMeta[2];
_ty = tmpMeta[4];
_defaultValue = tmpMeta[5];
_foldName = tmpMeta[6];
_resultName = tmpMeta[7];
_foldExpr = tmpMeta[9];
_expr = tmpMeta[10];
_iter = tmpMeta[12];
_iterators = tmpMeta[13];
_foldName2 = omc_Util_getTempVariableIndex(threadData);
_resultName2 = omc_Util_getTempVariableIndex(threadData);
tmpMeta[1] = mmc_mk_box2(0, _foldName, _foldName2);
_foldExpr2 = omc_Expression_traverseExpBottomUp(threadData, _foldExpr, boxvar_Expression_renameExpCrefIdent, tmpMeta[1], NULL);
tmpMeta[1] = mmc_mk_box2(0, _resultName, _resultName2);
_foldExpr2 = omc_Expression_traverseExpBottomUp(threadData, _foldExpr2, boxvar_Expression_renameExpCrefIdent, tmpMeta[1], NULL);
tmpMeta[1] = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _path, _OMC_LIT11, _ty, _defaultValue, _foldName2, _resultName2, mmc_mk_some(_foldExpr2));
tmpMeta[2] = mmc_mk_cons(_iter, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta[1], _expr, tmpMeta[2]);
_expr = tmpMeta[3];
tmpMeta[1] = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _path, _OMC_LIT11, _ty, _defaultValue, _foldName, _resultName, mmc_mk_some(_foldExpr));
tmpMeta[2] = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta[1], _expr, _iterators);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 7: {
tmpMeta[0] = _inReduction;
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
if (++tmp3 < 8) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outValue = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outValue;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyRangeReal2(threadData_t *threadData, modelica_real _inStart, modelica_real _inStep, modelica_integer _inSteps, modelica_metatype _inValues)
{
modelica_metatype _outValues = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_integer tmp3_1;
tmp3_1 = _inSteps;
{
modelica_real _next;
modelica_metatype _vals = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (-1 != tmp3_1) goto tmp2_end;
tmpMeta[0] = _inValues;
goto tmp2_done;
}
case 1: {
_next = _inStart + (_inStep) * (((modelica_real)_inSteps));
tmpMeta[1] = mmc_mk_cons(mmc_mk_real(_next), _inValues);
_vals = tmpMeta[1];
_inSteps = ((modelica_integer) -1) + _inSteps;
_inValues = _vals;
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
_outValues = tmpMeta[0];
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_string _error_str = NULL;
modelica_integer _steps;
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
tmp5 = (fabs(_inStep) <= 1e-14);
if (1 != tmp5) goto goto_1;
tmpMeta[1] = mmc_mk_cons(mmc_mk_real(_inStart), mmc_mk_cons(mmc_mk_real(_inStep), mmc_mk_cons(mmc_mk_real(_inStop), MMC_REFSTRUCTLIT(mmc_nil))));
_error_str = stringDelimitList(omc_List_map(threadData, tmpMeta[1], boxvar_realString), _OMC_LIT12);
tmpMeta[1] = mmc_mk_cons(_error_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT15, tmpMeta[1]);
goto goto_1;
goto tmp2_done;
}
case 1: {
equality(mmc_mk_real(_inStart), mmc_mk_real(_inStop));
tmpMeta[1] = mmc_mk_cons(mmc_mk_real(_inStart), MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
_steps = ((modelica_integer) -1) + omc_Util_realRangeSize(threadData, _inStart, _inStep, _inStop);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_ExpressionSimplify_simplifyRangeReal2(threadData, _inStart, _inStep, _steps, tmpMeta[1]);
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
_outValues = tmpMeta[0];
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
modelica_boolean tmp1;
modelica_boolean tmp2;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp2 = (modelica_boolean)_inStart;
if(tmp2)
{
tmp1 = (modelica_boolean)_inStop;
if(tmp1)
{
tmpMeta[1] = _OMC_LIT16;
}
else
{
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = tmpMeta[0];
}
tmpMeta[2] = tmpMeta[1];
}
else
{
tmpMeta[2] = (_inStop?_OMC_LIT17:_OMC_LIT18);
}
_outRange = tmpMeta[2];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inop;
{
modelica_metatype _ty1 = NULL;
modelica_metatype _ty2 = NULL;
modelica_boolean _b;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 10: {
modelica_boolean tmp4;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty1 = tmpMeta[1];
_ty2 = omc_Expression_unliftArray(threadData, _ty1);
_b = omc_DAEUtil_expTypeArray(threadData, _ty2);
tmp4 = (modelica_boolean)_b;
if(tmp4)
{
tmpMeta[1] = mmc_mk_box2(10, &DAE_Operator_ADD__ARR__desc, _ty2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty2);
tmpMeta[3] = tmpMeta[2];
}
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 11: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty1 = tmpMeta[1];
_ty2 = omc_Expression_unliftArray(threadData, _ty1);
_b = omc_DAEUtil_expTypeArray(threadData, _ty2);
tmp5 = (modelica_boolean)_b;
if(tmp5)
{
tmpMeta[1] = mmc_mk_box2(11, &DAE_Operator_SUB__ARR__desc, _ty2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _ty2);
tmpMeta[3] = tmpMeta[2];
}
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 13: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty1 = tmpMeta[1];
_ty2 = omc_Expression_unliftArray(threadData, _ty1);
_b = omc_DAEUtil_expTypeArray(threadData, _ty2);
tmp6 = (modelica_boolean)_b;
if(tmp6)
{
tmpMeta[1] = mmc_mk_box2(13, &DAE_Operator_DIV__ARR__desc, _ty2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _ty2);
tmpMeta[3] = tmpMeta[2];
}
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 12: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,9,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty1 = tmpMeta[1];
_ty2 = omc_Expression_unliftArray(threadData, _ty1);
_b = omc_DAEUtil_expTypeArray(threadData, _ty2);
tmp7 = (modelica_boolean)_b;
if(tmp7)
{
tmpMeta[1] = mmc_mk_box2(12, &DAE_Operator_MUL__ARR__desc, _ty2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty2);
tmpMeta[3] = tmpMeta[2];
}
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 24: {
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,21,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty1 = tmpMeta[1];
_ty2 = omc_Expression_unliftArray(threadData, _ty1);
_b = omc_DAEUtil_expTypeArray(threadData, _ty2);
tmp8 = (modelica_boolean)_b;
if(tmp8)
{
tmpMeta[1] = mmc_mk_box2(24, &DAE_Operator_POW__ARR2__desc, _ty2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(7, &DAE_Operator_POW__desc, _ty2);
tmpMeta[3] = tmpMeta[2];
}
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
_outop = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outop;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBuiltinConstantDer(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
modelica_metatype _dims = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT20;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT20;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_dims = tmpMeta[3];
tmpMeta[0] = omc_Expression_makeZeroExpression(threadData, _dims, NULL);
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_dims = tmpMeta[3];
tmpMeta[0] = omc_Expression_makeZeroExpression(threadData, _dims, NULL);
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
_outExp = tmpMeta[0];
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
modelica_boolean tmp9;
modelica_metatype tmpMeta[11] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp9 = (modelica_boolean)_arrayScalar;
if(tmp9)
{
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar6;
int tmp4;
modelica_metatype _row_loopVar = 0;
modelica_metatype _row;
_row_loopVar = _imexpl;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar7;
while(1) {
tmp4 = 1;
if (!listEmpty(_row_loopVar)) {
_row = MMC_CAR(_row_loopVar);
_row_loopVar = MMC_CDR(_row_loopVar);
tmp4--;
}
if (tmp4 == 0) {
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp2;
modelica_metatype __omcQ_24tmpVar4;
int tmp3;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _row;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta[3];
tmp2 = &__omcQ_24tmpVar5;
while(1) {
tmp3 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp3--;
}
if (tmp3 == 0) {
tmpMeta[4] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op, _s1);
__omcQ_24tmpVar4 = tmpMeta[4];
*tmp2 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp2 = &MMC_CDR(*tmp2);
} else if (tmp3 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp2 = mmc_mk_nil();
tmpMeta[2] = __omcQ_24tmpVar5;
}
__omcQ_24tmpVar6 = tmpMeta[2];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp4 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar7;
}
tmpMeta[10] = tmpMeta[0];
}
else
{
{
modelica_metatype __omcQ_24tmpVar11;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar10;
int tmp8;
modelica_metatype _row_loopVar = 0;
modelica_metatype _row;
_row_loopVar = _imexpl;
tmpMeta[6] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar11 = tmpMeta[6];
tmp5 = &__omcQ_24tmpVar11;
while(1) {
tmp8 = 1;
if (!listEmpty(_row_loopVar)) {
_row = MMC_CAR(_row_loopVar);
_row_loopVar = MMC_CDR(_row_loopVar);
tmp8--;
}
if (tmp8 == 0) {
{
modelica_metatype __omcQ_24tmpVar9;
modelica_metatype* tmp6;
modelica_metatype __omcQ_24tmpVar8;
int tmp7;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _row;
tmpMeta[8] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar9 = tmpMeta[8];
tmp6 = &__omcQ_24tmpVar9;
while(1) {
tmp7 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp7--;
}
if (tmp7 == 0) {
tmpMeta[9] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _s1, _op, _e);
__omcQ_24tmpVar8 = tmpMeta[9];
*tmp6 = mmc_mk_cons(__omcQ_24tmpVar8,0);
tmp6 = &MMC_CDR(*tmp6);
} else if (tmp7 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp6 = mmc_mk_nil();
tmpMeta[7] = __omcQ_24tmpVar9;
}
__omcQ_24tmpVar10 = tmpMeta[7];
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar10,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp8 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[5] = __omcQ_24tmpVar11;
}
tmpMeta[10] = tmpMeta[5];
}
_outExp = tmpMeta[10];
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
modelica_metatype tmpMeta[12] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inOperator2;
tmp3_2 = _inExp3;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 20; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,24,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
_b1 = omc_Expression_toBool(threadData, _e1);
_b1 = (!_b1);
tmpMeta[1] = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_b1));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,24,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,10,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],24,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
_e1 = tmpMeta[2];
tmp3 += 17;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 2: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
_i = tmp5;
tmp3 += 3;
_i_1 = (-_i);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i_1));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
modelica_real tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp6 = mmc_unbox_real(tmpMeta[1]);
_r = tmp6;
tmp3 += 2;
_r_1 = (-_r);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r_1));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_op2 = tmp3_1;
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
tmp3 += 1;
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e1);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op, _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_op2 = tmp3_1;
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
tmp3 += 1;
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e1);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op, _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
tmp3 += 1;
if (!omc_Expression_isZero(threadData, _e1)) goto tmp2_end;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
tmp3 += 1;
if (!omc_Expression_isZero(threadData, _e1)) goto tmp2_end;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
tmp3 += 10;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op, _e1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],8,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
tmp3 += 9;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op, _e1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 10: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_op2 = tmp3_1;
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
tmp3 += 8;
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e1);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e2);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op, tmpMeta[2]);
tmpMeta[4] = omc_ExpressionSimplify_simplify1(threadData, tmpMeta[3], &tmp7);
_e_1 = tmpMeta[4];
if (1 != tmp7) goto goto_1;
tmpMeta[0] = _e_1;
goto tmp2_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],7,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_op2 = tmp3_1;
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
tmp3 += 7;
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e1);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e2);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op, tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_op2 = tmp3_1;
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
tmp3 += 6;
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e1);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op, _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],10,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_op2 = tmp3_1;
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
tmp3 += 5;
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e1);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op, _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
_e1 = tmpMeta[2];
tmp3 += 4;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
_e1 = tmpMeta[2];
tmp3 += 3;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (10 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT21), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],8,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[5]);
tmpMeta[8] = MMC_CDR(tmpMeta[5]);
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_path = tmpMeta[1];
_e1 = tmpMeta[6];
_e2 = tmpMeta[7];
_e3 = tmpMeta[9];
_attr = tmpMeta[11];
tmp3 += 2;
tmpMeta[1] = mmc_mk_cons(_e1, mmc_mk_cons(_e3, mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta[2] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _path, tmpMeta[1], _attr);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 17: {
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp8 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_ty1 = tmpMeta[1];
_b1 = tmp8;
_expl = tmpMeta[3];
tmp3 += 1;
_expl = omc_List_map(threadData, _expl, boxvar_Expression_negate);
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _ty1, mmc_mk_boolean(_b1), _expl);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 18: {
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,17,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp9 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_ty1 = tmpMeta[1];
_i = tmp9;
_mat = tmpMeta[3];
_mat = omc_List_mapList(threadData, _mat, boxvar_Expression_negate);
tmpMeta[1] = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _ty1, mmc_mk_integer(_i), _mat);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 19: {
tmpMeta[0] = _origExp;
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
if (++tmp3 < 20) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryDistributePow(threadData_t *threadData, modelica_metatype _inExpLst, modelica_metatype _inExp)
{
modelica_metatype _outExpLst = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar13;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar12;
int tmp2;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inExpLst;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar13 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar13;
while(1) {
tmp2 = 1;
while (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
if ((!omc_Expression_isConstOne(threadData, _e))) {
tmp2--;
break;
}
}
if (tmp2 == 0) {
tmpMeta[2] = mmc_mk_box2(7, &DAE_Operator_POW__desc, omc_Expression_typeof(threadData, _e));
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, tmpMeta[2], _inExp);
__omcQ_24tmpVar12 = tmpMeta[3];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar12,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar13;
}
_outExpLst = tmpMeta[0];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;volatile modelica_metatype tmp3_3;
tmp3_1 = _inOperator2;
tmp3_2 = _inExp3;
tmp3_3 = _inExp4;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _oper = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 8; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
modelica_boolean tmp6;
_oper = tmp3_1;
_e1 = tmp3_2;
_e2 = tmp3_3;
tmp5 = omc_Expression_isConstValue(threadData, _e1);
if (1 != tmp5) goto goto_1;
tmp6 = omc_Expression_isConstValue(threadData, _e2);
if (1 != tmp6) goto goto_1;
_b = omc_ExpressionSimplify_simplifyRelationConst(threadData, _oper, _e1, _e2);
tmpMeta[1] = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_b));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,29,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
_cr1 = tmpMeta[1];
_cr2 = tmpMeta[2];
tmp3 += 5;
tmp7 = omc_ComponentReference_crefEqual(threadData, _cr1, _cr2);
if (1 != tmp7) goto goto_1;
tmpMeta[0] = _OMC_LIT23;
goto tmp2_done;
}
case 2: {
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,30,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
_cr1 = tmpMeta[1];
_cr2 = tmpMeta[2];
tmp3 += 4;
tmp8 = omc_ComponentReference_crefEqual(threadData, _cr1, _cr2);
if (1 != tmp8) goto goto_1;
tmpMeta[0] = _OMC_LIT22;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,28,1) == 0) goto tmp2_end;
tmp3 += 3;
tmpMeta[0] = omc_ExpressionSimplify_simplifyRelation2(threadData, _origExp, _inOperator2, _inExp3, _inExp4, _index, _optionExpisASUB, boxvar_Expression_isPositiveOrZero);
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,27,1) == 0) goto tmp2_end;
tmp3 += 2;
tmpMeta[0] = omc_ExpressionSimplify_simplifyRelation2(threadData, _origExp, _inOperator2, _inExp3, _inExp4, _index, _optionExpisASUB, boxvar_Expression_isPositiveOrZero);
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,26,1) == 0) goto tmp2_end;
tmp3 += 1;
tmpMeta[0] = omc_ExpressionSimplify_simplifyRelation2(threadData, _origExp, _inOperator2, _inExp4, _inExp3, _index, _optionExpisASUB, boxvar_Expression_isPositiveOrZero);
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,25,1) == 0) goto tmp2_end;
tmpMeta[0] = omc_ExpressionSimplify_simplifyRelation2(threadData, _origExp, _inOperator2, _inExp4, _inExp3, _index, _optionExpisASUB, boxvar_Expression_isPositiveOrZero);
goto tmp2_done;
}
case 7: {
tmpMeta[0] = _origExp;
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
if (++tmp3 < 8) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outExp = tmpMeta[0];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _inOperator2;
tmp3_2 = _inExp3;
tmp3_3 = _inExp4;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 13; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[0] = _origExp;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[0] = _origExp;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,22,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,10,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],24,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
_e2 = tmpMeta[3];
_e1 = tmp3_2;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[0] = _OMC_LIT22;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,22,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,10,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],24,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
_e1 = tmpMeta[3];
_e2 = tmp3_3;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[0] = _OMC_LIT22;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,23,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,10,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],24,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
_e2 = tmpMeta[3];
_e1 = tmp3_2;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[0] = _OMC_LIT23;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,23,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,10,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],24,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
_e1 = tmpMeta[3];
_e2 = tmp3_3;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[0] = _OMC_LIT23;
goto tmp2_done;
}
case 6: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,22,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
_e1 = tmp3_2;
_b = tmp5;
_e2 = tmp3_3;
tmpMeta[0] = (_b?_e2:_e1);
goto tmp2_done;
}
case 7: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,22,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
_e2 = tmp3_3;
_b = tmp6;
_e1 = tmp3_2;
tmpMeta[0] = (_b?_e1:_e2);
goto tmp2_done;
}
case 8: {
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,23,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
_e1 = tmp3_2;
_b = tmp7;
_e2 = tmp3_3;
tmpMeta[0] = (_b?_e1:_e2);
goto tmp2_done;
}
case 9: {
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,23,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp8 = mmc_unbox_integer(tmpMeta[1]);
_e2 = tmp3_3;
_b = tmp8;
_e1 = tmp3_2;
tmpMeta[0] = (_b?_e2:_e1);
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,22,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
_e2 = tmp3_3;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,23,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
_e2 = tmp3_3;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 12: {
tmpMeta[0] = _origExp;
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyTwoBinaryExpressions(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _lhsOperator, modelica_metatype _e2, modelica_metatype _mainOperator, modelica_metatype _e3, modelica_metatype _rhsOperator, modelica_metatype _e4, modelica_boolean _expEqual_e1_e3, modelica_boolean _expEqual_e1_e4, modelica_boolean _expEqual_e2_e3, modelica_boolean _expEqual_e2_e4, modelica_boolean _isConst_e1, modelica_boolean _isConst_e2, modelica_boolean _isConst_e3, modelica_boolean _operatorEqualLhsRhs)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;modelica_metatype tmp3_4;modelica_metatype tmp3_5;modelica_metatype tmp3_6;modelica_metatype tmp3_7;modelica_boolean tmp3_8;modelica_boolean tmp3_9;modelica_boolean tmp3_10;modelica_boolean tmp3_11;modelica_boolean tmp3_12;modelica_boolean tmp3_13;modelica_boolean tmp3_14;
tmp3_1 = _e1;
tmp3_2 = _lhsOperator;
tmp3_3 = _e2;
tmp3_4 = _mainOperator;
tmp3_5 = _e3;
tmp3_6 = _rhsOperator;
tmp3_7 = _e4;
tmp3_8 = _expEqual_e1_e3;
tmp3_9 = _expEqual_e1_e4;
tmp3_10 = _expEqual_e2_e3;
tmp3_11 = _expEqual_e2_e4;
tmp3_12 = _isConst_e1;
tmp3_13 = _isConst_e2;
tmp3_14 = _operatorEqualLhsRhs;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 17; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (1 != tmp3_8) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_4,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,2,1) == 0) goto tmp2_end;
_op2 = tmp3_2;
_op1 = tmp3_4;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e4);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
if (1 != tmp3_9) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_4,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,2,1) == 0) goto tmp2_end;
_op2 = tmp3_2;
_op1 = tmp3_4;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 2: {
if (1 != tmp3_10) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_4,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,2,1) == 0) goto tmp2_end;
_op2 = tmp3_2;
_op1 = tmp3_4;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e4);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op2, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 3: {
if (1 != tmp3_11) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_4,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,2,1) == 0) goto tmp2_end;
_op2 = tmp3_2;
_op1 = tmp3_4;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op2, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 4: {
if (1 != tmp3_11) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,4,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_4,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,4,1) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _mainOperator, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _lhsOperator, _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 5: {
if (1 != tmp3_11) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,4,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_4,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,4,1) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _mainOperator, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _lhsOperator, _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 6: {
if (1 != tmp3_8) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,4,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_4,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,4,1) == 0) goto tmp2_end;
_res = omc_Expression_expAdd(threadData, _e2, _e4);
tmpMeta[0] = omc_Expression_expPow(threadData, _e1, _res);
goto tmp2_done;
}
case 7: {
if (1 != tmp3_8) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,4,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_4,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,4,1) == 0) goto tmp2_end;
_res = omc_Expression_expSub(threadData, _e2, _e4);
tmpMeta[0] = omc_Expression_expPow(threadData, _e1, _res);
goto tmp2_done;
}
case 8: {
if (1 != tmp3_11) goto tmp2_end;
if (0 != tmp3_13) goto tmp2_end;
if (1 != tmp3_14) goto tmp2_end;
_op2 = tmp3_2;
_op1 = tmp3_4;
if (!(omc_Expression_isAddOrSub(threadData, _op1) && omc_Expression_isMulOrDiv(threadData, _op2))) goto tmp2_end;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op2, _e4);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 9: {
if (1 != tmp3_8) goto tmp2_end;
if (0 != tmp3_12) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,3,1) == 0) goto tmp2_end;
_op = tmp3_2;
_ty = tmpMeta[1];
_op1 = tmp3_4;
if (!omc_Expression_isAddOrSub(threadData, _op1)) goto tmp2_end;
_one = omc_Expression_makeConstOne(threadData, _ty);
_e = omc_Expression_makeDiv(threadData, _one, _e4);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op, _e1);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 10: {
if (1 != tmp3_8) goto tmp2_end;
if (0 != tmp3_12) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,2,1) == 0) goto tmp2_end;
_ty = tmpMeta[1];
_op1 = tmp3_4;
if (!omc_Expression_isAddOrSub(threadData, _op1)) goto tmp2_end;
_one = omc_Expression_makeConstOne(threadData, _ty);
_e = omc_Expression_makeDiv(threadData, _one, _e2);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op1, _e4);
tmpMeta[2] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], tmpMeta[2], _e1);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 11: {
if (1 != tmp3_11) goto tmp2_end;
if (0 != tmp3_13) goto tmp2_end;
if (1 != tmp3_14) goto tmp2_end;
_e1_1 = tmp3_1;
_op2 = tmp3_2;
_e_3 = tmp3_3;
_op1 = tmp3_4;
_e = tmp3_5;
if (!(omc_Expression_isAddOrSub(threadData, _op1) && omc_Expression_isMulOrDiv(threadData, _op2))) goto tmp2_end;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op1, _e);
_res = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _res, _op2, _e_3);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,1) == 0) goto tmp2_end;
_e_1 = tmpMeta[1];
_op2 = tmpMeta[2];
_e_2 = tmpMeta[3];
_op = tmp3_2;
_e_3 = tmp3_3;
_op1 = tmp3_4;
_e = tmp3_5;
_op3 = tmp3_6;
_e_6 = tmp3_7;
if (!(((((!omc_Expression_isConstValue(threadData, _e_2)) && omc_Expression_expEqual(threadData, _e_2, _e_6)) && omc_Expression_operatorEqual(threadData, _op2, _op3)) && omc_Expression_isAddOrSub(threadData, _op1)) && omc_Expression_isMulOrDiv(threadData, _op2))) goto tmp2_end;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e_1, _op, _e_3);
_e1_1 = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op1, _e);
_res = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _res, _op2, _e_2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_5,7,3) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_5), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_5), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_5), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,2,1) == 0) goto tmp2_end;
_e_1 = tmpMeta[1];
_op2 = tmpMeta[2];
_e_2 = tmpMeta[3];
_op = tmp3_2;
_e_4 = tmpMeta[4];
_op3 = tmpMeta[5];
_e_5 = tmpMeta[6];
_e_3 = tmp3_3;
_op1 = tmp3_4;
_e_6 = tmp3_7;
if (!(((((!omc_Expression_isConstValue(threadData, _e_2)) && omc_Expression_expEqual(threadData, _e_2, _e_5)) && omc_Expression_operatorEqual(threadData, _op2, _op3)) && omc_Expression_isAddOrSub(threadData, _op1)) && omc_Expression_isMulOrDiv(threadData, _op2))) goto tmp2_end;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e_1, _op, _e_3);
_e1_1 = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e_4, _op, _e_6);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op1, _e);
_res = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _res, _op2, _e_2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 14: {
if (0 != tmp3_13) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_5,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_5), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_5), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_5), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,2,1) == 0) goto tmp2_end;
_e_4 = tmpMeta[1];
_op3 = tmpMeta[2];
_e_5 = tmpMeta[3];
_op = tmp3_6;
_e_1 = tmp3_1;
_op2 = tmp3_2;
_e_3 = tmp3_3;
_op1 = tmp3_4;
_e_6 = tmp3_7;
if (!(((omc_Expression_expEqual(threadData, _e_3, _e_5) && omc_Expression_operatorEqual(threadData, _op2, _op3)) && omc_Expression_isAddOrSub(threadData, _op1)) && omc_Expression_isMulOrDiv(threadData, _op2))) goto tmp2_end;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e_4, _op, _e_6);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e_1, _op1, _e);
_res = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _res, _op2, _e_3);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 15: {
if (1 != tmp3_8) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_4,1,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,2,1) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _mainOperator, _e4);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _lhsOperator, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 16: {
if (1 != tmp3_9) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_4,1,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_6,2,1) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _mainOperator, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _lhsOperator, tmpMeta[1]);
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
_outExp = tmpMeta[0];
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
modelica_metatype tmpMeta[13] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_lhsIsConstValue = omc_Expression_isConstValue(threadData, _lhs);
_rhsIsConstValue = omc_Expression_isConstValue(threadData, _rhs);
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;volatile modelica_metatype tmp3_3;volatile modelica_boolean tmp3_4;volatile modelica_boolean tmp3_5;
tmp3_1 = _inOperator2;
tmp3_2 = _lhs;
tmp3_3 = _rhs;
tmp3_4 = _lhsIsConstValue;
tmp3_5 = _rhsIsConstValue;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 86; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_op = tmp3_1;
_e1 = tmp3_2;
_e2 = tmp3_3;
if (!omc_ExpressionSimplify_simplifyBinaryArrayOp(threadData, _op)) goto tmp2_end;
tmpMeta[0] = omc_ExpressionSimplify_simplifyBinaryArray(threadData, _e1, _op, _e2);
goto tmp2_done;
}
case 1: {
_op = tmp3_1;
_e1 = tmp3_2;
_e2 = tmp3_3;
tmpMeta[0] = omc_ExpressionSimplify_simplifyBinaryCommutativeWork(threadData, _op, _e1, _e2);
goto tmp2_done;
}
case 2: {
_op = tmp3_1;
_e1 = tmp3_2;
_e2 = tmp3_3;
tmpMeta[0] = omc_ExpressionSimplify_simplifyBinaryCommutativeWork(threadData, _op, _e2, _e1);
goto tmp2_done;
}
case 3: {
if (1 != tmp3_4) goto tmp2_end;
if (1 != tmp3_5) goto tmp2_end;
_oper = tmp3_1;
_e1 = tmp3_2;
_e2 = tmp3_3;
tmpMeta[0] = omc_ExpressionSimplify_simplifyBinaryConst(threadData, _oper, _e1, _e2);
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_e1 = tmpMeta[1];
_op1 = tmpMeta[2];
_e2 = tmpMeta[3];
_e3 = tmpMeta[4];
_op2 = tmpMeta[5];
_e4 = tmpMeta[6];
_oper = tmp3_1;
tmpMeta[0] = omc_ExpressionSimplify_simplifyTwoBinaryExpressions(threadData, _e1, _op1, _e2, _oper, _e3, _op2, _e4, omc_Expression_expEqual(threadData, _e1, _e3), omc_Expression_expEqual(threadData, _e1, _e4), omc_Expression_expEqual(threadData, _e2, _e3), omc_Expression_expEqual(threadData, _e2, _e4), omc_Expression_isConstValue(threadData, _e1), omc_Expression_isConstValue(threadData, _e2), omc_Expression_isConstValue(threadData, _e3), omc_Expression_operatorEqual(threadData, _op1, _op2));
goto tmp2_done;
}
case 5: {
modelica_boolean tmp5;
_oper = tmp3_1;
_e1 = tmp3_2;
_e2 = tmp3_3;
tmp5 = (omc_Expression_isConstZeroLength(threadData, _e1) || omc_Expression_isConstZeroLength(threadData, _e2));
if (1 != tmp5) goto goto_1;
omc_ExpressionSimplify_checkZeroLengthArrayOp(threadData, _oper);
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],8,2) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],5,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
_e2 = tmpMeta[1];
_op1 = tmpMeta[2];
_ty2 = tmpMeta[3];
_e3 = tmpMeta[6];
_e1 = tmp3_2;
tmp3 += 32;
tmpMeta[1] = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _ty2);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],8,2) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],5,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
_e2 = tmpMeta[1];
_op1 = tmpMeta[2];
_ty2 = tmpMeta[3];
_e3 = tmpMeta[6];
_e1 = tmp3_2;
tmp3 += 2;
tmpMeta[1] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty2);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 8: {
modelica_real tmp6;
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp6 = mmc_unbox_real(tmpMeta[5]);
_e2 = tmpMeta[1];
_op1 = tmpMeta[2];
_ty2 = tmpMeta[3];
_r = tmp6;
_e1 = tmp3_2;
tmp3 += 30;
tmp7 = (_r < 0.0);
if (1 != tmp7) goto goto_1;
_r = (-_r);
tmpMeta[1] = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _ty2);
tmpMeta[2] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, tmpMeta[2]);
tmpMeta[4] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], tmpMeta[3]);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 9: {
modelica_real tmp8;
modelica_boolean tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp8 = mmc_unbox_real(tmpMeta[5]);
_e2 = tmpMeta[1];
_op1 = tmpMeta[2];
_ty2 = tmpMeta[3];
_r = tmp8;
_e1 = tmp3_2;
tmp9 = (_r < 0.0);
if (1 != tmp9) goto goto_1;
_r = (-_r);
tmpMeta[1] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty2);
tmpMeta[2] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, tmpMeta[2]);
tmpMeta[4] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], tmpMeta[3]);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 10: {
modelica_boolean tmp10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e1 = tmpMeta[2];
_e2 = tmpMeta[4];
_op1 = tmpMeta[5];
_e3 = tmpMeta[6];
_e4 = tmp3_3;
tmp10 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp10) goto goto_1;
tmp11 = omc_Expression_expEqual(threadData, _e2, _e4);
if (1 != tmp11) goto goto_1;
_e = omc_Expression_makeDiv(threadData, _e3, _e4);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 11: {
modelica_boolean tmp12;
modelica_boolean tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],7,3) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],2,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 4));
_e3 = tmpMeta[1];
_op1 = tmpMeta[2];
_e1 = tmpMeta[4];
_e2 = tmpMeta[6];
_e4 = tmp3_3;
tmp12 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp12) goto goto_1;
tmp13 = omc_Expression_expEqual(threadData, _e2, _e4);
if (1 != tmp13) goto goto_1;
_e = omc_Expression_makeDiv(threadData, _e3, _e4);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op1, _e1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 12: {
modelica_boolean tmp14;
modelica_boolean tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],7,3) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],2,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e1 = tmpMeta[2];
_op2 = tmpMeta[3];
_e2 = tmpMeta[5];
_e3 = tmpMeta[7];
_op1 = tmpMeta[8];
_e4 = tmpMeta[9];
_e5 = tmp3_3;
tmp3 += 1;
tmp14 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp14) goto goto_1;
tmp15 = omc_Expression_expEqual(threadData, _e3, _e5);
if (1 != tmp15) goto goto_1;
_e = omc_Expression_makeDiv(threadData, _e4, _e3);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e2);
_e1_1 = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op1, _e);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 13: {
modelica_boolean tmp16;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (3 != MMC_STRLEN(tmpMeta[7]) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmpMeta[7])) != 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
_e1 = tmpMeta[4];
_e2 = tmpMeta[9];
_op2 = tmp3_1;
tmp3 += 14;
tmp16 = omc_Expression_isMulOrDiv(threadData, _op2);
if (1 != tmp16) goto goto_1;
_ty = omc_Expression_typeof(threadData, _e1);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e2);
_res = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_res, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT24, tmpMeta[1], _ty);
goto tmp2_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (3 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_ty = tmpMeta[1];
_e2 = tmpMeta[5];
_e1 = tmp3_2;
tmp3 += 1;
tmpMeta[1] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _ty);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], _e2);
_e = tmpMeta[2];
_e = omc_ExpressionSimplify_simplify1(threadData, _e, NULL);
tmpMeta[1] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT25, tmpMeta[1], _ty);
tmpMeta[1] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _e3);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 15: {
modelica_boolean tmp17;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (3 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (3 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_ty = tmpMeta[1];
_e1 = tmpMeta[5];
_e2 = tmpMeta[10];
tmp3 += 23;
tmp17 = (omc_Expression_isConstValue(threadData, _e1) || omc_Expression_isConstValue(threadData, _e2));
if (0 != tmp17) goto goto_1;
tmpMeta[1] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _e2);
_e = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT25, tmpMeta[1], _ty);
goto tmp2_done;
}
case 16: {
modelica_boolean tmp18;
if (1 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_op1 = tmp3_1;
_e1 = tmpMeta[1];
_op2 = tmpMeta[2];
_e2 = tmpMeta[3];
_e3 = tmp3_3;
tmp3 += 1;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e3);
_e = omc_ExpressionSimplify_simplify1(threadData, tmpMeta[1] ,&_b);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
_e4 = omc_ExpressionSimplify_simplify1(threadData, tmpMeta[1] ,&_b2);
tmp18 = (_b || _b2);
if (1 != tmp18) goto goto_1;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op2, _e4);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 17: {
modelica_boolean tmp19;
if (1 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_op1 = tmp3_1;
_e1 = tmpMeta[1];
_op2 = tmpMeta[2];
_e2 = tmpMeta[3];
_e3 = tmp3_3;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e3);
_e = omc_ExpressionSimplify_simplify1(threadData, tmpMeta[1] ,&_b);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
_e4 = omc_ExpressionSimplify_simplify1(threadData, tmpMeta[1] ,&_b2);
tmp19 = (_b || _b2);
if (1 != tmp19) goto goto_1;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op2, _e4);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],3,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_tp = tmpMeta[1];
_e2 = tmpMeta[2];
_op2 = tmpMeta[3];
_e3 = tmpMeta[4];
_e1 = tmp3_2;
tmpMeta[1] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _e3);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[2], _op2, _e2);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 19: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],3,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_tp = tmpMeta[1];
_e1 = tmpMeta[2];
_tp2 = tmpMeta[4];
_e2 = tmpMeta[5];
_e3 = tmp3_3;
tmpMeta[1] = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _tp2);
tmpMeta[2] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, tmpMeta[2], _e3);
tmpMeta[4] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], tmpMeta[3]);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 20: {
modelica_boolean tmp20;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_e2 = tmpMeta[1];
_tp2 = tmpMeta[3];
_e3 = tmpMeta[4];
_e1 = tmp3_2;
tmp20 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp20) goto goto_1;
tmpMeta[1] = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _tp2);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, tmpMeta[1], _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 21: {
modelica_boolean tmp21;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_e2 = tmpMeta[1];
_tp2 = tmpMeta[3];
_e3 = tmpMeta[4];
_e1 = tmp3_2;
tmp21 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp21) goto goto_1;
tmpMeta[1] = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _tp2);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, tmpMeta[1], _e3);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 22: {
modelica_boolean tmp22;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_e3 = tmp3_3;
tmp22 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp22) goto goto_1;
tmpMeta[0] = _e2;
goto tmp2_done;
}
case 23: {
modelica_boolean tmp23;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_e3 = tmp3_3;
tmp23 = omc_Expression_expEqual(threadData, _e2, _e3);
if (1 != tmp23) goto goto_1;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 24: {
modelica_boolean tmp24;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],8,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],2,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e1 = tmpMeta[3];
_e2 = tmpMeta[5];
_e3 = tmp3_3;
tmp24 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp24) goto goto_1;
_tp2 = omc_Expression_typeof(threadData, _e2);
tmpMeta[1] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _tp2);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 25: {
modelica_boolean tmp25;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],8,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],2,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e1 = tmpMeta[3];
_e2 = tmpMeta[5];
_e3 = tmp3_3;
tmp25 = omc_Expression_expEqual(threadData, _e2, _e3);
if (1 != tmp25) goto goto_1;
_tp2 = omc_Expression_typeof(threadData, _e1);
tmpMeta[1] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _tp2);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], _e1);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 26: {
modelica_boolean tmp26;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,8,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],5,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_e3 = tmpMeta[5];
tmp26 = omc_Expression_expEqual(threadData, _e2, _e3);
if (1 != tmp26) goto goto_1;
_tp2 = omc_Expression_typeof(threadData, _e1);
tmpMeta[1] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _tp2);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], _e1);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 27: {
modelica_boolean tmp27;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,8,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],5,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_e3 = tmpMeta[5];
tmp3 += 7;
tmp27 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp27) goto goto_1;
_tp2 = omc_Expression_typeof(threadData, _e2);
tmpMeta[1] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _tp2);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 28: {
modelica_boolean tmp28;
if (1 != tmp3_4) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty = tmpMeta[1];
_e1 = tmp3_2;
_e2 = tmp3_3;
tmp28 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp28) goto goto_1;
tmpMeta[1] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _ty);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 29: {
modelica_boolean tmp29;
if (1 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
_e2 = tmp3_3;
tmp29 = omc_Expression_isZero(threadData, _e2);
if (1 != tmp29) goto goto_1;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 30: {
modelica_boolean tmp30;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty = tmpMeta[1];
_e1 = tmp3_2;
_e2 = tmp3_3;
tmp3 += 1;
tmp30 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp30) goto goto_1;
tmpMeta[0] = omc_Expression_makeConstZero(threadData, _ty);
goto tmp2_done;
}
case 31: {
modelica_boolean tmp31;
modelica_boolean tmp32;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty = tmpMeta[1];
_e1 = tmp3_2;
_e2 = tmp3_3;
tmp3 += 30;
tmp31 = omc_Types_isRealOrSubTypeReal(threadData, _ty);
if (1 != tmp31) goto goto_1;
tmp32 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp32) goto goto_1;
_e = omc_Expression_makeConstNumber(threadData, _ty, ((modelica_integer) 2));
tmpMeta[1] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, tmpMeta[1], _e1);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 32: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,8,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
_ty = tmpMeta[1];
_e2 = tmpMeta[3];
_e1 = tmp3_2;
tmp3 += 50;
tmpMeta[1] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 33: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],8,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],5,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],2,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_ty = tmpMeta[1];
_e2 = tmpMeta[4];
_op1 = tmpMeta[5];
_e3 = tmpMeta[6];
_e1 = tmp3_2;
tmp3 += 29;
tmpMeta[1] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 34: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],8,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],5,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],3,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_ty = tmpMeta[1];
_e2 = tmpMeta[4];
_op1 = tmpMeta[5];
_e3 = tmpMeta[6];
_e1 = tmp3_2;
tmp3 += 29;
tmpMeta[1] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e3);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 35: {
modelica_boolean tmp33;
modelica_boolean tmp34;
if (1 != tmp3_4) goto tmp2_end;
if (0 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
_e2 = tmp3_3;
tmp3 += 1;
tmp33 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp33) goto goto_1;
tmp34 = omc_Expression_isZero(threadData, _e2);
if (0 != tmp34) goto goto_1;
tmpMeta[0] = _OMC_LIT20;
goto tmp2_done;
}
case 36: {
modelica_boolean tmp35;
if (0 != tmp3_4) goto tmp2_end;
if (1 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
_e2 = tmp3_3;
tmp35 = omc_Expression_isConstOne(threadData, _e2);
if (1 != tmp35) goto goto_1;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 37: {
modelica_boolean tmp36;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty = tmpMeta[1];
_e1 = tmp3_2;
_e2 = tmp3_3;
tmp36 = omc_Expression_isConstMinusOne(threadData, _e2);
if (1 != tmp36) goto goto_1;
tmpMeta[1] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _ty);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], _e1);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 38: {
modelica_boolean tmp37;
modelica_boolean tmp38;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty = tmpMeta[1];
_e1 = tmp3_2;
_e2 = tmp3_3;
tmp3 += 1;
tmp37 = omc_Expression_isZero(threadData, _e2);
if (0 != tmp37) goto goto_1;
tmp38 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp38) goto goto_1;
tmpMeta[0] = omc_Expression_makeConstOne(threadData, _ty);
goto tmp2_done;
}
case 39: {
modelica_boolean tmp39;
modelica_boolean tmp40;
modelica_boolean tmp41;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty = tmpMeta[1];
_e1 = tmp3_2;
_e2 = tmp3_3;
tmp3 += 3;
tmp39 = omc_Expression_isZero(threadData, _e2);
if (0 != tmp39) goto goto_1;
tmp40 = omc_Types_isRealOrSubTypeReal(threadData, _ty);
if (1 != tmp40) goto goto_1;
tmp41 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp41) goto goto_1;
tmpMeta[1] = mmc_mk_box2(7, &DAE_Operator_POW__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _OMC_LIT29);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 40: {
modelica_real tmp42;
modelica_boolean tmp43;
modelica_real tmp44;
modelica_real tmp45;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp42 = mmc_unbox_real(tmpMeta[2]);
_tp = tmpMeta[1];
_r1 = tmp42;
_e1 = tmp3_2;
tmp3 += 8;
tmp43 = (fabs(_r1) > 0.0);
if (1 != tmp43) goto goto_1;
tmp44 = _r1;
if (tmp44 == 0) {goto goto_1;}
_r = (1.0) / tmp44;
_r1 = (1000000000000.0) * (_r);
tmp45 = modelica_real_mod(_r1, 1.0);
if (0.0 != tmp45) goto goto_1;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[2] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], tmpMeta[2], _e1);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 41: {
modelica_real tmp46;
modelica_boolean tmp47;
modelica_real tmp48;
modelica_real tmp49;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp46 = mmc_unbox_real(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],2,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_op2 = tmp3_1;
_tp = tmpMeta[1];
_r1 = tmp46;
_e3 = tmpMeta[5];
_e1 = tmp3_2;
tmp3 += 7;
tmp47 = (fabs(_r1) > 0.0);
if (1 != tmp47) goto goto_1;
tmp48 = _r1;
if (tmp48 == 0) {goto goto_1;}
_r = (1.0) / tmp48;
_r1 = (1000000000000.0) * (_r);
tmp49 = modelica_real_mod(_r1, 1.0);
if (0.0 != tmp49) goto goto_1;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[2] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], tmpMeta[2], _e1);
tmpMeta[4] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[3], _op2, _e3);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 42: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,8,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],5,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
_op1 = tmp3_1;
_e1 = tmpMeta[2];
_e2 = tmpMeta[4];
tmp3 += 5;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 43: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_op2 = tmp3_1;
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_op1 = tmpMeta[4];
_e3 = tmpMeta[5];
tmp3 += 1;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op1, _e2);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 44: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_op2 = tmp3_1;
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_op1 = tmpMeta[4];
_e3 = tmpMeta[5];
tmp3 += 1;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op1, _e2);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 45: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],8,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_op2 = tmp3_1;
_op3 = tmpMeta[2];
_e2 = tmpMeta[3];
_ty = tmpMeta[5];
_e3 = tmpMeta[6];
_e1 = tmp3_2;
tmp3 += 39;
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op3, _e1);
tmpMeta[2] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, tmpMeta[2], _e3);
tmpMeta[4] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op2, tmpMeta[3]);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 46: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],8,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_op2 = tmp3_1;
_op3 = tmpMeta[2];
_e2 = tmpMeta[3];
_ty = tmpMeta[5];
_e3 = tmpMeta[6];
_e1 = tmp3_2;
tmp3 += 2;
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op3, _e1);
tmpMeta[2] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, tmpMeta[2], _e3);
tmpMeta[4] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op2, tmpMeta[3]);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 47: {
modelica_real tmp50;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp50 = mmc_unbox_real(tmpMeta[1]);
if (2.0 != tmp50) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
_op2 = tmp3_1;
_e2 = tmp3_3;
_e1 = tmpMeta[3];
tmp3 += 3;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 48: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,8,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
_op1 = tmp3_1;
_ty = tmpMeta[1];
_e2 = tmpMeta[3];
_e1 = tmp3_2;
tmpMeta[1] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _ty);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], _e1);
_e1_1 = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op1, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 49: {
modelica_boolean tmp51;
modelica_boolean tmp52;
if (1 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_op1 = tmp3_1;
_e2 = tmpMeta[1];
_op2 = tmpMeta[2];
_e3 = tmpMeta[3];
_e1 = tmp3_3;
tmp51 = omc_Expression_isConstValue(threadData, _e3);
if (1 != tmp51) goto goto_1;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op1, _e1);
tmpMeta[2] = omc_ExpressionSimplify_simplify1(threadData, tmpMeta[1], &tmp52);
_e = tmpMeta[2];
if (1 != tmp52) goto goto_1;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op2, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 50: {
modelica_boolean tmp53;
modelica_boolean tmp54;
if (1 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_op1 = tmp3_1;
_e2 = tmpMeta[1];
_op2 = tmpMeta[2];
_e3 = tmpMeta[3];
_e1 = tmp3_3;
tmp3 += 5;
tmp53 = omc_Expression_isConstValue(threadData, _e2);
if (1 != tmp53) goto goto_1;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e1);
tmpMeta[2] = omc_ExpressionSimplify_simplify1(threadData, tmpMeta[1], &tmp54);
_e = tmpMeta[2];
if (1 != tmp54) goto goto_1;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op2, _e3);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 51: {
modelica_boolean tmp55;
if (1 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
_e = tmp3_3;
tmp55 = omc_Expression_isConstOne(threadData, _e);
if (1 != tmp55) goto goto_1;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 52: {
modelica_boolean tmp56;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_tp = tmpMeta[1];
_e2 = tmp3_2;
_e = tmp3_3;
tmp56 = omc_Expression_isConstMinusOne(threadData, _e);
if (1 != tmp56) goto goto_1;
_one = omc_Expression_makeConstOne(threadData, _tp);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _one, _OMC_LIT31, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 53: {
modelica_boolean tmp57;
if (1 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
_e = tmp3_3;
tmp57 = omc_Expression_isZero(threadData, _e);
if (1 != tmp57) goto goto_1;
_tp = omc_Expression_typeof(threadData, _e1);
tmpMeta[0] = omc_Expression_makeConstOne(threadData, _tp);
goto tmp2_done;
}
case 54: {
modelica_real tmp58;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp58 = mmc_unbox_real(tmpMeta[1]);
if (2.0 != tmp58) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (4 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_e = tmpMeta[5];
tmpMeta[0] = _e;
goto tmp2_done;
}
case 55: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (4 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_oper = tmp3_1;
_e1 = tmpMeta[4];
_e = tmp3_3;
tmp3 += 5;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT33, _OMC_LIT34, _e);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _oper, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 56: {
modelica_boolean tmp59;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (4 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e2 = tmpMeta[4];
_e1 = tmp3_2;
tmp59 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp59) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta[1], _OMC_LIT30);
goto tmp2_done;
}
case 57: {
modelica_boolean tmp60;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e1 = tmpMeta[1];
_op1 = tmpMeta[2];
_ty = tmpMeta[3];
_e2 = tmpMeta[4];
_e3 = tmp3_3;
tmp3 += 1;
tmp60 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp60) goto goto_1;
_e4 = omc_Expression_makeConstOne(threadData, _ty);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, tmpMeta[1], _e4);
_e4 = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e4);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 58: {
modelica_boolean tmp61;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],4,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],2,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e1 = tmpMeta[2];
_op1 = tmpMeta[3];
_ty = tmpMeta[4];
_e2 = tmpMeta[5];
_op2 = tmpMeta[6];
_e5 = tmpMeta[7];
_e3 = tmp3_3;
tmp61 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp61) goto goto_1;
_e4 = omc_Expression_makeConstOne(threadData, _ty);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, tmpMeta[1], _e4);
_e4 = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e4);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op2, _e5);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 59: {
modelica_boolean tmp62;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_e1 = tmpMeta[1];
_op1 = tmpMeta[2];
_ty = tmpMeta[3];
_e2 = tmpMeta[4];
_e3 = tmp3_2;
tmp3 += 25;
tmp62 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp62) goto goto_1;
_e4 = omc_Expression_makeConstOne(threadData, _ty);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, tmpMeta[1], _e2);
_e4 = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, _e4);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 60: {
modelica_real tmp63;
modelica_boolean tmp64;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp63 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],3,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_op2 = tmp3_1;
_r = tmp63;
_e1 = tmpMeta[2];
_op1 = tmpMeta[3];
_e2 = tmpMeta[4];
tmp64 = (_r < 0.0);
if (1 != tmp64) goto goto_1;
_r = (-_r);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e1);
tmpMeta[2] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op2, tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 61: {
modelica_boolean tmp65;
if (1 != tmp3_4) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
tmp65 = omc_Expression_isConstOne(threadData, _e1);
if (1 != tmp65) goto goto_1;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 62: {
modelica_boolean tmp66;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,12,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,12,3) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[2];
_e3 = tmpMeta[3];
_e4 = tmpMeta[4];
_e5 = tmpMeta[5];
_e6 = tmpMeta[6];
_op1 = tmp3_1;
tmp3 += 6;
tmp66 = omc_Expression_expEqual(threadData, _e1, _e4);
if (1 != tmp66) goto goto_1;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, _e5);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op1, _e6);
_res = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _e1, _e, _res);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 63: {
modelica_boolean tmp67;
if (0 != tmp3_4) goto tmp2_end;
if (0 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],8,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],5,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],2,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_ty = tmpMeta[1];
_e3 = tmpMeta[2];
_e4 = tmpMeta[4];
_e = tmpMeta[5];
_e1 = tmpMeta[7];
_op2 = tmpMeta[8];
_e2 = tmpMeta[9];
tmp3 += 1;
tmp67 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp67) goto goto_1;
tmpMeta[1] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, tmpMeta[1], _e4);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op2, tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 64: {
modelica_boolean tmp68;
if (0 != tmp3_4) goto tmp2_end;
if (0 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],3,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],8,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],5,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],3,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_ty = tmpMeta[1];
_e3 = tmpMeta[2];
_e4 = tmpMeta[4];
_e = tmpMeta[5];
_e1 = tmpMeta[7];
_e2 = tmpMeta[9];
tmp3 += 20;
tmp68 = omc_Expression_expEqual(threadData, _e1, _e3);
if (1 != tmp68) goto goto_1;
tmpMeta[1] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta[2] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _ty);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, omc_Expression_inverseFactors(threadData, _e2), tmpMeta[2], omc_Expression_inverseFactors(threadData, _e4));
tmpMeta[4] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, tmpMeta[1], tmpMeta[3]);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 65: {
modelica_boolean tmp69;
modelica_boolean tmp70;
modelica_boolean tmp71;
modelica_boolean tmp72;
if (0 != tmp3_4) goto tmp2_end;
if (0 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],7,3) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],2,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],7,3) == 0) goto tmp2_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 2));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 3));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 4));
_e1 = tmpMeta[1];
_oper = tmpMeta[2];
_e2 = tmpMeta[4];
_op2 = tmpMeta[5];
_e3 = tmpMeta[6];
_e4 = tmpMeta[7];
_e5 = tmpMeta[10];
_op3 = tmpMeta[11];
_e6 = tmpMeta[12];
_op1 = tmp3_1;
tmp69 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp69) goto goto_1;
tmp70 = omc_Expression_isMulOrDiv(threadData, _op2);
if (1 != tmp70) goto goto_1;
tmp71 = omc_Expression_isMulOrDiv(threadData, _op3);
if (1 != tmp71) goto goto_1;
tmp72 = omc_Expression_expEqual(threadData, _e2, _e5);
if (1 != tmp72) goto goto_1;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, _op3, _e6);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op1, tmpMeta[2]);
tmpMeta[4] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e5, _oper, tmpMeta[3]);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 66: {
modelica_boolean tmp73;
modelica_boolean tmp74;
modelica_boolean tmp75;
if (0 != tmp3_4) goto tmp2_end;
if (0 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],2,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],7,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 4));
_e1 = tmpMeta[1];
_oper = tmpMeta[2];
_e2 = tmpMeta[3];
_e4 = tmpMeta[4];
_e5 = tmpMeta[7];
_op3 = tmpMeta[8];
_e6 = tmpMeta[9];
_op1 = tmp3_1;
tmp73 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp73) goto goto_1;
tmp74 = omc_Expression_isMulOrDiv(threadData, _op3);
if (1 != tmp74) goto goto_1;
tmp75 = omc_Expression_expEqual(threadData, _e2, _e5);
if (1 != tmp75) goto goto_1;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, _op3, _e6);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, tmpMeta[1]);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e5, _oper, tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 67: {
modelica_boolean tmp76;
modelica_boolean tmp77;
if (0 != tmp3_4) goto tmp2_end;
if (0 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],2,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],7,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 4));
_e4 = tmpMeta[1];
_e5 = tmpMeta[3];
_e1 = tmpMeta[4];
_oper = tmpMeta[5];
_e2 = tmpMeta[7];
_op2 = tmpMeta[8];
_e3 = tmpMeta[9];
_op1 = tmp3_1;
tmp76 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp76) goto goto_1;
tmp77 = omc_Expression_isMulOrDiv(threadData, _op2);
if (1 != tmp77) goto goto_1;
if(omc_Expression_expEqual(threadData, _e2, _e5))
{
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op1, _e4);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e5, _oper, tmpMeta[2]);
_outExp = tmpMeta[3];
}
else
{
if(omc_Expression_expEqual(threadData, _e2, _e4))
{
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op1, _e5);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, _oper, tmpMeta[2]);
_outExp = tmpMeta[3];
}
else
{
goto goto_1;
}
}
tmpMeta[0] = _outExp;
goto tmp2_done;
}
case 68: {
modelica_boolean tmp78;
modelica_boolean tmp79;
if (0 != tmp3_4) goto tmp2_end;
if (0 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],7,3) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],2,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e4 = tmpMeta[1];
_e5 = tmpMeta[3];
_e1 = tmpMeta[5];
_oper = tmpMeta[6];
_e2 = tmpMeta[7];
_op2 = tmpMeta[8];
_e3 = tmpMeta[9];
_op1 = tmp3_1;
tmp3 += 1;
tmp78 = omc_Expression_isAddOrSub(threadData, _op1);
if (1 != tmp78) goto goto_1;
tmp79 = omc_Expression_isMulOrDiv(threadData, _op2);
if (1 != tmp79) goto goto_1;
if(omc_Expression_expEqual(threadData, _e2, _e5))
{
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op1, _e4);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e5, _oper, tmpMeta[2]);
_outExp = tmpMeta[3];
}
else
{
if(omc_Expression_expEqual(threadData, _e2, _e4))
{
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _op1, _e5);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, _oper, tmpMeta[2]);
_outExp = tmpMeta[3];
}
else
{
goto goto_1;
}
}
tmpMeta[0] = _outExp;
goto tmp2_done;
}
case 69: {
modelica_boolean tmp80;
if (1 != tmp3_5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
_e2 = tmp3_3;
tmpMeta[1] = omc_Expression_factors(threadData, _e1);
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (listEmpty(tmpMeta[3])) goto goto_1;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto goto_1;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
_exp_lst = tmpMeta[1];
tmp80 = omc_List_exist(threadData, _exp_lst, boxvar_Expression_isConstValue);
if (1 != tmp80) goto goto_1;
_exp_lst_1 = omc_ExpressionSimplify_simplifyBinaryDistributePow(threadData, _exp_lst, _e2);
tmpMeta[0] = omc_Expression_makeProductLst(threadData, _exp_lst_1);
goto tmp2_done;
}
case 70: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_e3 = tmp3_3;
if (!omc_Expression_isEven(threadData, _e2)) goto tmp2_end;
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _OMC_LIT34, _e3);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT24, tmpMeta[1], omc_Expression_typeof(threadData, _e1)), _OMC_LIT36, tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 71: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_e3 = tmp3_3;
tmp3 += 13;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _OMC_LIT34, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _OMC_LIT36, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 72: {
modelica_boolean tmp81;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (3 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (3 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_ty = tmpMeta[1];
_e1 = tmpMeta[5];
_e2 = tmpMeta[10];
tmp3 += 12;
tmp81 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp81) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT37, tmpMeta[1], _ty);
goto tmp2_done;
}
case 73: {
modelica_boolean tmp82;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (3 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT37), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (3 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_op2 = tmp3_1;
_ty = tmpMeta[1];
_e1 = tmpMeta[5];
_e2 = tmpMeta[10];
tmp3 += 11;
tmp82 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp82) goto goto_1;
_e3 = _OMC_LIT27;
tmpMeta[1] = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e4 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT38, tmpMeta[1], _ty);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op2, _e4);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 74: {
modelica_boolean tmp83;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (3 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (3 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT37), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_ty = tmpMeta[1];
_e1 = tmpMeta[5];
_e2 = tmpMeta[10];
tmp83 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp83) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT39, tmpMeta[1], _ty);
goto tmp2_done;
}
case 75: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (3 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT37), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_op2 = tmp3_1;
_ty = tmpMeta[1];
_e2 = tmpMeta[5];
_e1 = tmp3_2;
tmp3 += 9;
tmpMeta[1] = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT39, tmpMeta[1], _ty);
tmpMeta[1] = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e4 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT38, tmpMeta[1], _ty);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, _op2, _e3);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _e);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 76: {
modelica_boolean tmp84;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (4 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT41), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (4 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT42), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_ty = tmpMeta[1];
_e1 = tmpMeta[5];
_e2 = tmpMeta[10];
tmp3 += 8;
tmp84 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp84) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT40, tmpMeta[1], _ty);
goto tmp2_done;
}
case 77: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (4 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT40), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_op2 = tmp3_1;
_ty = tmpMeta[1];
_e2 = tmpMeta[5];
_e1 = tmp3_2;
tmp3 += 1;
tmpMeta[1] = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT41, tmpMeta[1], _ty);
tmpMeta[1] = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e4 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT42, tmpMeta[1], _ty);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e4, _op2, _e3);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _e);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 78: {
modelica_boolean tmp85;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (4 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT40), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (4 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT41), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_op2 = tmp3_1;
_ty = tmpMeta[1];
_e1 = tmpMeta[5];
_e2 = tmpMeta[10];
tmp3 += 6;
tmp85 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp85) goto goto_1;
_e3 = _OMC_LIT27;
tmpMeta[1] = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e4 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT42, tmpMeta[1], _ty);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op2, _e4);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 79: {
modelica_boolean tmp86;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (4 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT42), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (4 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT40), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_ty = tmpMeta[1];
_e1 = tmpMeta[5];
_e2 = tmpMeta[10];
tmp3 += 5;
tmp86 = omc_Expression_expEqual(threadData, _e1, _e2);
if (1 != tmp86) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT41, tmpMeta[1], _ty);
goto tmp2_done;
}
case 80: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,8,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
_ty = tmpMeta[1];
_e2 = tmpMeta[3];
_e1 = tmp3_2;
tmp3 += 4;
tmpMeta[1] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _ty);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], _e1);
_e1_1 = tmpMeta[2];
tmpMeta[1] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, tmpMeta[1], _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 81: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,18,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 5));
_ty = tmpMeta[1];
_e1 = tmpMeta[2];
_oexp = tmpMeta[3];
_e2 = tmpMeta[4];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _inOperator2, _rhs);
_e1 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta[1], _inOperator2, _e1, _rhs);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _inOperator2, _rhs);
_e2 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta[1], _inOperator2, _e2, _rhs);
tmpMeta[1] = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, _ty, _e1, _oexp, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 82: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,18,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 5));
_ty = tmpMeta[1];
_e1 = tmpMeta[2];
_oexp = tmpMeta[3];
_e2 = tmpMeta[4];
tmp3 += 2;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _lhs, _inOperator2, _e1);
_e1 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta[1], _inOperator2, _lhs, _e1);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _lhs, _inOperator2, _e1);
_e2 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta[1], _inOperator2, _lhs, _e2);
tmpMeta[1] = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, _ty, _e1, _oexp, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 83: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,18,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 5));
_ty = tmpMeta[1];
_e1 = tmpMeta[2];
_oexp = tmpMeta[3];
_e2 = tmpMeta[4];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _inOperator2, _rhs);
_e1 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta[1], _inOperator2, _e1, _rhs);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _inOperator2, _rhs);
_e2 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta[1], _inOperator2, _e2, _rhs);
tmpMeta[1] = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, _ty, _e1, _oexp, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 84: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,18,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 5));
_ty = tmpMeta[1];
_e1 = tmpMeta[2];
_oexp = tmpMeta[3];
_e2 = tmpMeta[4];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _lhs, _inOperator2, _e1);
_e1 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta[1], _inOperator2, _lhs, _e1);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _lhs, _inOperator2, _e1);
_e2 = omc_ExpressionSimplify_simplifyBinary(threadData, tmpMeta[1], _inOperator2, _lhs, _e2);
tmpMeta[1] = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, _ty, _e1, _oexp, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 85: {
tmpMeta[0] = _origExp;
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
if (++tmp3 < 86) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryCommutativeWork(threadData_t *threadData, modelica_metatype _op, modelica_metatype _lhs, modelica_metatype _rhs)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta[23] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;volatile modelica_metatype tmp3_3;
tmp3_1 = _op;
tmp3_2 = _lhs;
tmp3_3 = _rhs;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 22; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (3 != MMC_STRLEN(tmpMeta[7]) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta[7])) != 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
_e1 = tmpMeta[4];
_e2 = tmpMeta[9];
tmp3 += 8;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
_op1 = _OMC_LIT34;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT29, _op1, _e1);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
_e = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT39, tmpMeta[1], _OMC_LIT30);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT33, _op1, _e);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_real tmp5;
modelica_real tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (3 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],4,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],1,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],1,1) == 0) goto tmp2_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 2));
tmp5 = mmc_unbox_real(tmpMeta[10]);
if (2.0 != tmp5) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[11],13,3) == 0) goto tmp2_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[12],1,1) == 0) goto tmp2_end;
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 2));
if (3 != MMC_STRLEN(tmpMeta[13]) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta[13])) != 0) goto tmp2_end;
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 3));
if (listEmpty(tmpMeta[14])) goto tmp2_end;
tmpMeta[15] = MMC_CAR(tmpMeta[14]);
tmpMeta[16] = MMC_CDR(tmpMeta[14]);
if (!listEmpty(tmpMeta[16])) goto tmp2_end;
tmpMeta[17] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[17],4,1) == 0) goto tmp2_end;
tmpMeta[18] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[17]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[18],1,1) == 0) goto tmp2_end;
tmpMeta[19] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[19],1,1) == 0) goto tmp2_end;
tmpMeta[20] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[19]), 2));
tmp6 = mmc_unbox_real(tmpMeta[20]);
if (2.0 != tmp6) goto tmp2_end;
_e1 = tmpMeta[5];
_e2 = tmpMeta[15];
tmp3 += 5;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[0] = _OMC_LIT27;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (3 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT37), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (3 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_tp = tmpMeta[1];
_e1 = tmpMeta[5];
_e2 = tmpMeta[10];
tmp3 += 6;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT39, tmpMeta[1], _tp);
goto tmp2_done;
}
case 3: {
modelica_real tmp7;
modelica_real tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (4 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT42), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],4,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],1,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],1,1) == 0) goto tmp2_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 2));
tmp7 = mmc_unbox_real(tmpMeta[10]);
if (2.0 != tmp7) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,8,2) == 0) goto tmp2_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[11],5,1) == 0) goto tmp2_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[12],7,3) == 0) goto tmp2_end;
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[13],13,3) == 0) goto tmp2_end;
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[13]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[14],1,1) == 0) goto tmp2_end;
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[14]), 2));
if (4 != MMC_STRLEN(tmpMeta[15]) || strcmp(MMC_STRINGDATA(_OMC_LIT41), MMC_STRINGDATA(tmpMeta[15])) != 0) goto tmp2_end;
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[13]), 3));
if (listEmpty(tmpMeta[16])) goto tmp2_end;
tmpMeta[17] = MMC_CAR(tmpMeta[16]);
tmpMeta[18] = MMC_CDR(tmpMeta[16]);
if (!listEmpty(tmpMeta[18])) goto tmp2_end;
tmpMeta[19] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[19],4,1) == 0) goto tmp2_end;
tmpMeta[20] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[19]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[20],1,1) == 0) goto tmp2_end;
tmpMeta[21] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[21],1,1) == 0) goto tmp2_end;
tmpMeta[22] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[21]), 2));
tmp8 = mmc_unbox_real(tmpMeta[22]);
if (2.0 != tmp8) goto tmp2_end;
_e1 = tmpMeta[5];
_e2 = tmpMeta[17];
tmp3 += 1;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[0] = _OMC_LIT27;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (4 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT40), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,13,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (4 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT42), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
_tp = tmpMeta[1];
_e1 = tmpMeta[5];
_e2 = tmpMeta[10];
tmp3 += 4;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT41, tmpMeta[1], _tp);
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,8,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
_tp = tmpMeta[1];
_e2 = tmpMeta[3];
_e1 = tmp3_2;
tmp3 += 1;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _tp);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],8,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],5,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_tp = tmpMeta[1];
_e2 = tmpMeta[4];
_op2 = tmpMeta[5];
_e3 = tmpMeta[6];
_e1 = tmp3_2;
if (!omc_Expression_isMulOrDiv(threadData, _op2)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _tp);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op2, _e3);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
_e2 = tmp3_3;
tmp3 += 8;
if (!omc_Expression_isZero(threadData, _e1)) goto tmp2_end;
tmpMeta[0] = _e2;
goto tmp2_done;
}
case 8: {
modelica_boolean tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],3,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_tp = tmpMeta[1];
_e2 = tmpMeta[2];
_tp2 = tmpMeta[4];
_e3 = tmpMeta[5];
_e1 = tmp3_2;
tmpMeta[1] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _e2);
tmpMeta[3] = omc_ExpressionSimplify_simplify1(threadData, tmpMeta[2], &tmp9);
_e = tmpMeta[3];
if (1 != tmp9) goto goto_1;
tmpMeta[1] = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _tp2);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, tmpMeta[1], _e3);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
_e2 = tmp3_3;
if (!omc_Expression_isZero(threadData, _e2)) goto tmp2_end;
tmpMeta[0] = _e2;
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
_e1 = tmp3_2;
_e2 = tmp3_3;
if (!omc_Expression_isConstOne(threadData, _e2)) goto tmp2_end;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty = tmpMeta[1];
_e1 = tmp3_2;
_e2 = tmp3_3;
if (!omc_Expression_isConstMinusOne(threadData, _e2)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _ty);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], _e1);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_e2 = tmpMeta[1];
_op1 = tmpMeta[2];
_ty = tmpMeta[3];
_e3 = tmpMeta[4];
_e1 = tmp3_3;
if (!(omc_Types_isScalarReal(threadData, _ty) && omc_Expression_expEqual(threadData, _e2, _e1))) goto tmp2_end;
tmpMeta[1] = mmc_mk_box2(7, &DAE_Operator_POW__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _OMC_LIT29);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e3, _op1, tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_e2 = tmpMeta[1];
_op1 = tmpMeta[2];
_ty = tmpMeta[3];
_e3 = tmpMeta[4];
_e1 = tmp3_2;
if (!(omc_Types_isScalarReal(threadData, _ty) && omc_Expression_expEqual(threadData, _e1, _e3))) goto tmp2_end;
tmpMeta[1] = mmc_mk_box2(7, &DAE_Operator_POW__desc, _ty);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _OMC_LIT29);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op1, tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 14: {
modelica_real tmp10;
modelica_real tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp10 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp11 = mmc_unbox_real(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],2,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],1,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_r1 = tmp10;
_r2 = tmp11;
_e2 = tmpMeta[6];
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real((_r1) * (_r2)));
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _OMC_LIT34, _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 15: {
modelica_real tmp12;
modelica_real tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp12 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],1,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmp13 = mmc_unbox_real(tmpMeta[6]);
_r1 = tmp12;
_e2 = tmpMeta[2];
_r2 = tmp13;
tmp3 += 6;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real((_r1) * (_r2)));
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], _OMC_LIT34, _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 16: {
modelica_real tmp14;
modelica_real tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp14 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp15 = mmc_unbox_real(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],6,2) == 0) goto tmp2_end;
_r1 = tmp14;
_r2 = tmp15;
_ty = tmpMeta[5];
_e1 = tmpMeta[6];
tmp3 += 5;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r1 + _r2));
tmpMeta[2] = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _ty);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[1], tmpMeta[2], _e1);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (3 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_ty = tmpMeta[1];
_e1 = tmpMeta[5];
_e2 = tmp3_3;
tmp3 += 4;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT43, tmpMeta[1], _ty);
goto tmp2_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_op1 = tmp3_1;
_ty = tmpMeta[1];
_e2 = tmpMeta[2];
_op2 = tmpMeta[3];
_e3 = tmpMeta[4];
_e1 = tmp3_2;
tmp3 += 3;
if (!(!omc_Expression_isConstValue(threadData, _e1))) goto tmp2_end;
if(omc_Expression_expEqual(threadData, _e1, _e3))
{
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, omc_Expression_makeConstOne(threadData, _ty), _op1, _e2);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, tmpMeta[1]);
_exp = tmpMeta[2];
}
else
{
if(omc_Expression_expEqual(threadData, _e1, _e2))
{
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, omc_Expression_makeConstOne(threadData, _ty), _op1, _e3);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op2, tmpMeta[1]);
_exp = tmpMeta[2];
}
else
{
goto goto_1;
}
}
tmpMeta[0] = _exp;
goto tmp2_done;
}
case 19: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (4 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e1 = tmpMeta[4];
_e2 = tmp3_3;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _OMC_LIT36, _OMC_LIT45);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (4 != MMC_STRLEN(tmpMeta[5]) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta[5])) != 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
_e2 = tmpMeta[1];
_e = tmpMeta[3];
_e1 = tmpMeta[7];
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT46, _OMC_LIT33);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _OMC_LIT36, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 21: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_e3 = tmpMeta[1];
_op1 = tmpMeta[2];
_tp = tmpMeta[3];
_e4 = tmpMeta[4];
_e1 = tmp3_2;
if (!omc_Expression_expEqual(threadData, _e1, _e3)) goto tmp2_end;
_e = omc_Expression_makeConstOne(threadData, _tp);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _tp);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, tmpMeta[1], _e4);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op1, tmpMeta[2]);
tmpMeta[0] = tmpMeta[3];
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
if (++tmp3 < 22) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_exp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _exp;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_safeIntOp(threadData_t *threadData, modelica_integer _val1, modelica_integer _val2, modelica_metatype _op)
{
modelica_metatype _outv = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _op;
{
modelica_real _rv1;
modelica_real _rv2;
modelica_real _rv3;
modelica_integer _ires;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
_rv1 = ((modelica_real)_val1);
_rv2 = ((modelica_real)_val2);
_rv3 = (_rv1) * (_rv2);
tmpMeta[0] = omc_Expression_realToIntIfPossible(threadData, _rv3);
goto tmp2_done;
}
case 4: {
modelica_integer tmp4;
tmp4 = _val2;
if (tmp4 == 0) {goto goto_1;}
_ires = ldiv(_val1,tmp4).quot;
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_ires));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
_rv1 = ((modelica_real)_val1);
_rv2 = ((modelica_real)_val2);
_rv3 = _rv1 - _rv2;
tmpMeta[0] = omc_Expression_realToIntIfPossible(threadData, _rv3);
goto tmp2_done;
}
case 5: {
_rv1 = ((modelica_real)_val1);
_rv2 = ((modelica_real)_val2);
_rv3 = _rv1 + _rv2;
tmpMeta[0] = omc_Expression_realToIntIfPossible(threadData, _rv3);
goto tmp2_done;
}
case 7: {
modelica_real tmp5;
modelica_real tmp6;
modelica_real tmp7;
modelica_real tmp8;
modelica_real tmp9;
modelica_real tmp10;
modelica_real tmp11;
_rv1 = ((modelica_real)_val1);
_rv2 = ((modelica_real)_val2);
tmp5 = _rv1;
tmp6 = _rv2;
if(tmp5 < 0.0 && tmp6 != 0.0)
{
tmp8 = modf(tmp6, &tmp9);
if(tmp8 > 0.5)
{
tmp8 -= 1.0;
tmp9 += 1.0;
}
else if(tmp8 < -0.5)
{
tmp8 += 1.0;
tmp9 -= 1.0;
}
if(fabs(tmp8) < 1e-10)
tmp7 = pow(tmp5, tmp9);
else
{
tmp11 = modf(1.0/tmp6, &tmp10);
if(tmp11 > 0.5)
{
tmp11 -= 1.0;
tmp10 += 1.0;
}
else if(tmp11 < -0.5)
{
tmp11 += 1.0;
tmp10 -= 1.0;
}
if(fabs(tmp11) < 1e-10 && ((unsigned long)tmp10 & 1))
{
tmp7 = -pow(-tmp5, tmp8)*pow(tmp5, tmp9);
}
else
{
goto goto_1;
}
}
}
else
{
tmp7 = pow(tmp5, tmp6);
}
if(isnan(tmp7) || isinf(tmp7))
{
goto goto_1;
}
_rv3 = tmp7;
tmpMeta[0] = omc_Expression_realToIntIfPossible(threadData, _rv3);
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
_outv = tmpMeta[0];
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_integer tmp6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,25,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp6 = mmc_unbox_integer(tmpMeta[0]);
if (0 != tmp6) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp7) goto tmp3_end;
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
modelica_integer tmp8;
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,26,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp8 = mmc_unbox_integer(tmpMeta[0]);
if (1 != tmp8) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp9 = mmc_unbox_integer(tmpMeta[1]);
if (0 != tmp9) goto tmp3_end;
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
modelica_integer tmp10;
modelica_integer tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,29,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp10 = mmc_unbox_integer(tmpMeta[0]);
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp11 = mmc_unbox_integer(tmpMeta[1]);
_b1 = tmp10;
_b2 = tmp11;
tmp1 = ((!_b1 && !_b2) || (_b1 && _b2));
goto tmp3_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,29,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,2,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
_s1 = tmpMeta[0];
_s2 = tmpMeta[1];
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
modelica_integer tmp12;
modelica_integer tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp12 = mmc_unbox_integer(tmpMeta[0]);
if (0 != tmp12) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp13 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp13) goto tmp3_end;
tmp1 = (!omc_ExpressionSimplify_simplifyRelationConst(threadData, _OMC_LIT47, _e1, _e2));
goto tmp3_done;
}
case 12: {
modelica_integer tmp14;
modelica_integer tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,28,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp14 = mmc_unbox_integer(tmpMeta[0]);
if (0 != tmp14) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,3,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_3), 2));
tmp15 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp15) goto tmp3_end;
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _inOperator1;
tmp3_2 = _inExp2;
tmp3_3 = _inExp3;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 18; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
_ie1 = tmp5;
_ie2 = tmp6;
tmpMeta[0] = omc_ExpressionSimplify_safeIntOp(threadData, _ie1, _ie2, _OMC_LIT50);
goto tmp2_done;
}
case 1: {
modelica_real tmp7;
modelica_real tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp7 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp8 = mmc_unbox_real(tmpMeta[2]);
_re1 = tmp7;
_re2 = tmp8;
_re3 = _re1 + _re2;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
modelica_real tmp9;
modelica_integer tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp9 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp10 = mmc_unbox_integer(tmpMeta[2]);
_re1 = tmp9;
_ie2 = tmp10;
_e2_1 = ((modelica_real)_ie2);
_re3 = _re1 + _e2_1;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
modelica_integer tmp11;
modelica_real tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp11 = mmc_unbox_integer(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp12 = mmc_unbox_real(tmpMeta[2]);
_ie1 = tmp11;
_re2 = tmp12;
_e1_1 = ((modelica_real)_ie1);
_re3 = _e1_1 + _re2;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,2,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
_s1 = tmpMeta[1];
_s2 = tmpMeta[2];
tmpMeta[1] = stringAppend(_s1,_s2);
_str = tmpMeta[1];
tmpMeta[1] = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _str);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
modelica_integer tmp13;
modelica_integer tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp13 = mmc_unbox_integer(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp14 = mmc_unbox_integer(tmpMeta[2]);
_ie1 = tmp13;
_ie2 = tmp14;
tmpMeta[0] = omc_ExpressionSimplify_safeIntOp(threadData, _ie1, _ie2, _OMC_LIT51);
goto tmp2_done;
}
case 6: {
modelica_real tmp15;
modelica_real tmp16;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp15 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp16 = mmc_unbox_real(tmpMeta[2]);
_re1 = tmp15;
_re2 = tmp16;
_re3 = _re1 - _re2;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 7: {
modelica_real tmp17;
modelica_integer tmp18;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp17 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp18 = mmc_unbox_integer(tmpMeta[2]);
_re1 = tmp17;
_ie2 = tmp18;
_e2_1 = ((modelica_real)_ie2);
_re3 = _re1 - _e2_1;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 8: {
modelica_integer tmp19;
modelica_real tmp20;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp19 = mmc_unbox_integer(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp20 = mmc_unbox_real(tmpMeta[2]);
_ie1 = tmp19;
_re2 = tmp20;
_e1_1 = ((modelica_real)_ie1);
_re3 = _e1_1 - _re2;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 9: {
modelica_integer tmp21;
modelica_integer tmp22;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp21 = mmc_unbox_integer(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp22 = mmc_unbox_integer(tmpMeta[2]);
_ie1 = tmp21;
_ie2 = tmp22;
tmpMeta[0] = omc_ExpressionSimplify_safeIntOp(threadData, _ie1, _ie2, _OMC_LIT52);
goto tmp2_done;
}
case 10: {
modelica_real tmp23;
modelica_real tmp24;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp23 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp24 = mmc_unbox_real(tmpMeta[2]);
_re1 = tmp23;
_re2 = tmp24;
_re3 = (_re1) * (_re2);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 11: {
modelica_real tmp25;
modelica_integer tmp26;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp25 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp26 = mmc_unbox_integer(tmpMeta[2]);
_re1 = tmp25;
_ie2 = tmp26;
_e2_1 = ((modelica_real)_ie2);
_re3 = (_re1) * (_e2_1);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 12: {
modelica_integer tmp27;
modelica_real tmp28;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp27 = mmc_unbox_integer(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp28 = mmc_unbox_real(tmpMeta[2]);
_ie1 = tmp27;
_re2 = tmp28;
_e1_1 = ((modelica_real)_ie1);
_re3 = (_e1_1) * (_re2);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 13: {
modelica_integer tmp29;
modelica_integer tmp30;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp29 = mmc_unbox_integer(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp30 = mmc_unbox_integer(tmpMeta[2]);
_ie1 = tmp29;
_ie2 = tmp30;
tmpMeta[0] = omc_ExpressionSimplify_safeIntOp(threadData, _ie1, _ie2, _OMC_LIT53);
goto tmp2_done;
}
case 14: {
modelica_real tmp31;
modelica_real tmp32;
modelica_real tmp33;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp31 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp32 = mmc_unbox_real(tmpMeta[2]);
_re1 = tmp31;
_re2 = tmp32;
tmp33 = _re2;
if (tmp33 == 0) {goto goto_1;}
_re3 = (_re1) / tmp33;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 15: {
modelica_real tmp34;
modelica_integer tmp35;
modelica_real tmp36;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp34 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp35 = mmc_unbox_integer(tmpMeta[2]);
_re1 = tmp34;
_ie2 = tmp35;
_e2_1 = ((modelica_real)_ie2);
tmp36 = _e2_1;
if (tmp36 == 0) {goto goto_1;}
_re3 = (_re1) / tmp36;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 16: {
modelica_integer tmp37;
modelica_real tmp38;
modelica_real tmp39;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp37 = mmc_unbox_integer(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp38 = mmc_unbox_real(tmpMeta[2]);
_ie1 = tmp37;
_re2 = tmp38;
_e1_1 = ((modelica_real)_ie1);
tmp39 = _re2;
if (tmp39 == 0) {goto goto_1;}
_re3 = (_e1_1) / tmp39;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 17: {
modelica_real tmp40;
modelica_real tmp41;
modelica_real tmp42;
modelica_real tmp43;
modelica_real tmp44;
modelica_real tmp45;
modelica_real tmp46;
modelica_real tmp47;
modelica_real tmp48;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp40 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp41 = mmc_unbox_real(tmpMeta[2]);
_re1 = tmp40;
_re2 = tmp41;
tmp42 = _re1;
tmp43 = _re2;
if(tmp42 < 0.0 && tmp43 != 0.0)
{
tmp45 = modf(tmp43, &tmp46);
if(tmp45 > 0.5)
{
tmp45 -= 1.0;
tmp46 += 1.0;
}
else if(tmp45 < -0.5)
{
tmp45 += 1.0;
tmp46 -= 1.0;
}
if(fabs(tmp45) < 1e-10)
tmp44 = pow(tmp42, tmp46);
else
{
tmp48 = modf(1.0/tmp43, &tmp47);
if(tmp48 > 0.5)
{
tmp48 -= 1.0;
tmp47 += 1.0;
}
else if(tmp48 < -0.5)
{
tmp48 += 1.0;
tmp47 -= 1.0;
}
if(fabs(tmp48) < 1e-10 && ((unsigned long)tmp47 & 1))
{
tmp44 = -pow(-tmp42, tmp45)*pow(tmp42, tmp46);
}
else
{
goto goto_1;
}
}
}
else
{
tmp44 = pow(tmp42, tmp43);
}
if(isnan(tmp44) || isinf(tmp44))
{
goto goto_1;
}
_re3 = tmp44;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_re3));
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
_outExp = tmpMeta[0];
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
modelica_boolean tmp7;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_didSplit = 0;
{
modelica_metatype __omcQ_24tmpVar15;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar14;
int tmp6;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _inSubscripts;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar15 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar15;
while(1) {
tmp6 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp6--;
}
if (tmp6 == 0) {
{
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
_es = omc_Expression_splitArray(threadData, omc_ExpressionSimplify_simplify1(threadData, _e, NULL) ,&_b);
_didSplit = (_didSplit || _b);
tmpMeta[2] = _es;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}__omcQ_24tmpVar14 = tmpMeta[2];
*tmp1 = mmc_mk_cons(__omcQ_24tmpVar14,0);
tmp1 = &MMC_CDR(*tmp1);
} else if (tmp6 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp1 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar15;
}
_indices = tmpMeta[0];
tmp7 = _didSplit;
if (1 != tmp7) MMC_THROW_INTERNAL();
{
modelica_metatype _is;
for (tmpMeta[0] = _indices; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_is = MMC_CAR(tmpMeta[0]);
{
modelica_metatype _i;
for (tmpMeta[1] = _is; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_i = MMC_CAR(tmpMeta[1]);
{
modelica_metatype tmp10_1;
tmp10_1 = omc_Expression_typeof(threadData, _i);
{
int tmp10;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp10_1))) {
case 3: {
goto tmp9_done;
}
case 6: {
goto tmp9_done;
}
case 8: {
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp1;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 19: {
tmpMeta[0] = _inOperator3;
goto tmp2_done;
}
case 20: {
tmpMeta[0] = _inOperator3;
goto tmp2_done;
}
case 21: {
tmpMeta[0] = _inOperator3;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _inOperator2;
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
_outOperator = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outOperator;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubArrayReduction(threadData_t *threadData, modelica_metatype _iter, modelica_metatype _sub, modelica_metatype _acc)
{
modelica_metatype _res = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _iter;
{
modelica_metatype _exp = NULL;
modelica_string _id = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (!optionNone(tmpMeta[3])) goto tmp2_end;
_id = tmpMeta[1];
_exp = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_sub, MMC_REFSTRUCTLIT(mmc_nil));
_exp = omc_Expression_makeASUB(threadData, _exp, tmpMeta[1]);
tmpMeta[0] = omc_ExpressionSimplify_replaceIteratorWithExp(threadData, _exp, _acc, _id);
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
_res = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsub(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inSub)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inExp;
tmp3_2 = _inSub;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 22; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_e = tmp3_1;
_sub = tmp3_2;
tmpMeta[0] = omc_ExpressionSimplify_simplifyAsub0(threadData, _e, omc_Expression_expInt(threadData, _sub), _inSub);
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_e = tmpMeta[2];
_sub = tmp3_2;
tmp3 += 20;
_e_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e, _sub);
_t2 = omc_Expression_typeof(threadData, _e_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp5 = (modelica_boolean)_b;
if(tmp5)
{
tmpMeta[1] = mmc_mk_box2(9, &DAE_Operator_UMINUS__ARR__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op2, _e_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],24,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_e = tmpMeta[2];
_sub = tmp3_2;
tmp3 += 19;
_e_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e, _sub);
_t2 = omc_Expression_typeof(threadData, _e_1);
tmpMeta[1] = mmc_mk_box2(27, &DAE_Operator_NOT__desc, _t2);
tmpMeta[2] = mmc_mk_box3(13, &DAE_Exp_LUNARY__desc, tmpMeta[1], _e_1);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 3: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],8,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 18;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp6 = (modelica_boolean)_b;
if(tmp6)
{
tmpMeta[1] = mmc_mk_box2(11, &DAE_Operator_SUB__ARR__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op2, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],11,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 17;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp7 = (modelica_boolean)_b;
if(tmp7)
{
tmpMeta[1] = mmc_mk_box2(14, &DAE_Operator_MUL__ARRAY__SCALAR__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],12,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 16;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp8 = (modelica_boolean)_b;
if(tmp8)
{
tmpMeta[1] = mmc_mk_box2(15, &DAE_Operator_ADD__ARRAY__SCALAR__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
modelica_boolean tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],13,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 15;
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e2_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp9 = (modelica_boolean)_b;
if(tmp9)
{
tmpMeta[1] = mmc_mk_box2(16, &DAE_Operator_SUB__SCALAR__ARRAY__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(4, &DAE_Operator_SUB__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],15,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 14;
_e = omc_ExpressionSimplify_simplifyMatrixProduct(threadData, _e1, _e2);
tmpMeta[0] = omc_ExpressionSimplify_simplifyAsub(threadData, _e, _sub);
goto tmp2_done;
}
case 8: {
modelica_boolean tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],17,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 13;
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e2_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp10 = (modelica_boolean)_b;
if(tmp10)
{
tmpMeta[1] = mmc_mk_box2(20, &DAE_Operator_DIV__SCALAR__ARRAY__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 9: {
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],16,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 12;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp11 = (modelica_boolean)_b;
if(tmp11)
{
tmpMeta[1] = mmc_mk_box2(19, &DAE_Operator_DIV__ARRAY__SCALAR__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 10: {
modelica_boolean tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],19,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 11;
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e2_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp12 = (modelica_boolean)_b;
if(tmp12)
{
tmpMeta[1] = mmc_mk_box2(22, &DAE_Operator_POW__SCALAR__ARRAY__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(7, &DAE_Operator_POW__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 11: {
modelica_boolean tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],18,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 10;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp13 = (modelica_boolean)_b;
if(tmp13)
{
tmpMeta[1] = mmc_mk_box2(21, &DAE_Operator_POW__ARRAY__SCALAR__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(7, &DAE_Operator_POW__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 12: {
modelica_boolean tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],7,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 9;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp14 = (modelica_boolean)_b;
if(tmp14)
{
tmpMeta[1] = mmc_mk_box2(10, &DAE_Operator_ADD__ARR__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op2, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 13: {
modelica_boolean tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 8;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp15 = (modelica_boolean)_b;
if(tmp15)
{
tmpMeta[1] = mmc_mk_box2(12, &DAE_Operator_MUL__ARR__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op2, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 14: {
modelica_boolean tmp16;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],10,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 7;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp16 = (modelica_boolean)_b;
if(tmp16)
{
tmpMeta[1] = mmc_mk_box2(13, &DAE_Operator_DIV__ARR__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op2, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 15: {
modelica_boolean tmp17;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],21,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 6;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_b = omc_DAEUtil_expTypeArray(threadData, _t2);
tmp17 = (modelica_boolean)_b;
if(tmp17)
{
tmpMeta[1] = mmc_mk_box2(24, &DAE_Operator_POW__ARR2__desc, _t2);
tmpMeta[3] = tmpMeta[1];
}
else
{
tmpMeta[2] = mmc_mk_box2(7, &DAE_Operator_POW__desc, _t2);
tmpMeta[3] = tmpMeta[2];
}
_op2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op2, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,9,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 5;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
_t2 = omc_Expression_typeof(threadData, _e1_1);
_op = omc_Expression_setOpType(threadData, _op, _t2);
tmpMeta[1] = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _e1_1, _op, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_exps = tmpMeta[1];
_sub = tmp3_2;
tmp3 += 4;
_indx = omc_Expression_expInt(threadData, _sub);
tmpMeta[0] = listGet(_exps, _indx);
goto tmp2_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_t = tmpMeta[1];
_lstexps = tmpMeta[2];
_sub = tmp3_2;
tmp3 += 3;
_indx = omc_Expression_expInt(threadData, _sub);
_expl = listGet(_lstexps, _indx);
_t_1 = omc_Expression_unliftArray(threadData, _t);
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _t_1, mmc_mk_boolean(1), _expl);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 19: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,12,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_cond = tmpMeta[1];
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_sub = tmp3_2;
tmp3 += 2;
_e1_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e1, _sub);
_e2_1 = omc_ExpressionSimplify_simplifyAsub(threadData, _e2, _sub);
tmpMeta[1] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _cond, _e1_1, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,27,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (5 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,0) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_exp = tmpMeta[5];
_iters = tmpMeta[6];
_sub = tmp3_2;
tmp3 += 1;
tmpMeta[0] = omc_List_fold1(threadData, _iters, boxvar_ExpressionSimplify_simplifyAsubArrayReduction, _sub, _exp);
goto tmp2_done;
}
case 21: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,27,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (5 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT9), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,0) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
_exp = tmpMeta[5];
_iter = tmpMeta[7];
_sub = tmp3_2;
tmpMeta[0] = omc_ExpressionSimplify_simplifyAsubArrayReduction(threadData, _iter, _sub, _exp);
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
if (++tmp3 < 22) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubCref(threadData_t *threadData, modelica_metatype _cr, modelica_metatype _sub)
{
modelica_metatype _res = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _cr;
{
modelica_metatype _t2 = NULL;
modelica_metatype _c = NULL;
modelica_metatype _c_1 = NULL;
modelica_metatype _s = NULL;
modelica_metatype _s_1 = NULL;
modelica_string _idn = NULL;
modelica_metatype _dims = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_idn = tmpMeta[1];
_t2 = tmpMeta[2];
_s = tmpMeta[3];
tmp3 += 3;
_s_1 = omc_Expression_subscriptsAppend(threadData, _s, _sub);
tmpMeta[0] = omc_ComponentReference_makeCrefIdent(threadData, _idn, _t2, _s_1);
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_idn = tmpMeta[1];
_t2 = tmpMeta[2];
_dims = tmpMeta[3];
_s = tmpMeta[4];
_c = tmpMeta[5];
tmp5 = (listLength(_dims) > listLength(_s));
if (1 != tmp5) goto goto_1;
_s_1 = omc_Expression_subscriptsAppend(threadData, _s, _sub);
tmpMeta[0] = omc_ComponentReference_makeCrefQual(threadData, _idn, _t2, _s_1, _c);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_idn = tmpMeta[1];
_t2 = tmpMeta[2];
_s = tmpMeta[3];
_c = tmpMeta[4];
tmpMeta[1] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, _sub);
_s = omc_Expression_subscriptsReplaceSlice(threadData, _s, tmpMeta[1]);
tmpMeta[0] = omc_ComponentReference_makeCrefQual(threadData, _idn, _t2, _s, _c);
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_idn = tmpMeta[1];
_t2 = tmpMeta[2];
_s = tmpMeta[3];
_c = tmpMeta[4];
_c_1 = omc_ExpressionSimplify_simplifyAsubCref(threadData, _c, _sub);
tmpMeta[0] = omc_ComponentReference_makeCrefQual(threadData, _idn, _t2, _s, _c_1);
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
_res = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsub0(threadData_t *threadData, modelica_metatype _ie, modelica_integer _sub, modelica_metatype _inSubExp)
{
modelica_metatype _res = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ie;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 10; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_exps = tmpMeta[1];
tmpMeta[0] = listGet(_exps, _sub);
goto tmp2_done;
}
case 1: {
modelica_integer tmp5;
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,18,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],3,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[4]);
_bstart = tmp5;
_bstop = tmp6;
_b = mmc_unbox_boolean(listGet(omc_ExpressionSimplify_simplifyRangeBool(threadData, _bstart, _bstop), _sub));
tmpMeta[1] = mmc_mk_box2(6, &DAE_Exp_BCONST__desc, mmc_mk_boolean(_b));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
modelica_integer tmp7;
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,18,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp7 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (!optionNone(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp8 = mmc_unbox_integer(tmpMeta[5]);
_istart = tmp7;
_istop = tmp8;
_ival = mmc_unbox_integer(listGet(omc_ExpressionSimplify_simplifyRange(threadData, _istart, ((modelica_integer) 1), _istop), _sub));
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_ival));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
modelica_integer tmp9;
modelica_integer tmp10;
modelica_integer tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,18,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp9 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (optionNone(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp10 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],0,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmp11 = mmc_unbox_integer(tmpMeta[7]);
_istart = tmp9;
_istep = tmp10;
_istop = tmp11;
_ival = mmc_unbox_integer(listGet(omc_ExpressionSimplify_simplifyRange(threadData, _istart, _istep, _istop), _sub));
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_ival));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
modelica_real tmp12;
modelica_real tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,18,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp12 = mmc_unbox_real(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (!optionNone(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp13 = mmc_unbox_real(tmpMeta[5]);
_rstart = tmp12;
_rstop = tmp13;
_rval = mmc_unbox_real(listGet(omc_ExpressionSimplify_simplifyRangeReal(threadData, _rstart, 1.0, _rstop), _sub));
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_rval));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
modelica_real tmp14;
modelica_real tmp15;
modelica_real tmp16;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,18,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp14 = mmc_unbox_real(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (optionNone(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp15 = mmc_unbox_real(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmp16 = mmc_unbox_real(tmpMeta[7]);
_rstart = tmp14;
_rstep = tmp15;
_rstop = tmp16;
_rval = mmc_unbox_real(listGet(omc_ExpressionSimplify_simplifyRangeReal(threadData, _rstart, _rstep, _rstop), _sub));
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_rval));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_t = tmpMeta[1];
_mexps = tmpMeta[2];
_t1 = omc_Expression_unliftArray(threadData, _t);
_mexpl = listGet(_mexps, _sub);
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _t1, mmc_mk_boolean(1), _mexpl);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,12,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_cond = tmpMeta[1];
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_cons(_inSubExp, MMC_REFSTRUCTLIT(mmc_nil));
_e1 = omc_Expression_makeASUB(threadData, _e1, tmpMeta[1]);
tmpMeta[1] = mmc_mk_cons(_inSubExp, MMC_REFSTRUCTLIT(mmc_nil));
_e2 = omc_Expression_makeASUB(threadData, _e2, tmpMeta[1]);
tmpMeta[1] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _cond, _e1, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 8: {
modelica_boolean tmp17;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_c = tmpMeta[1];
_t = tmpMeta[2];
tmp17 = omc_Types_isArray(threadData, _t);
if (1 != tmp17) goto goto_1;
_t = omc_Expression_unliftArray(threadData, _t);
_c_1 = omc_ExpressionSimplify_simplifyAsubCref(threadData, _c, _inSubExp);
tmpMeta[0] = omc_Expression_makeCrefExp(threadData, _c_1, _t);
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
if (!(omc_Expression_isMulOrDiv(threadData, _op) || omc_Expression_isAddOrSub(threadData, _op))) goto tmp2_end;
tmpMeta[1] = mmc_mk_cons(_inSubExp, MMC_REFSTRUCTLIT(mmc_nil));
_e1 = omc_Expression_makeASUB(threadData, _e1, tmpMeta[1]);
tmpMeta[1] = mmc_mk_cons(_inSubExp, MMC_REFSTRUCTLIT(mmc_nil));
_e2 = omc_Expression_makeASUB(threadData, _e2, tmpMeta[1]);
tmpMeta[0] = (omc_Expression_isMul(threadData, _op)?omc_Expression_expMul(threadData, _e1, _e2):(omc_Expression_isDiv(threadData, _op)?omc_Expression_makeDiv(threadData, _e1, _e2):(omc_Expression_isAdd(threadData, _op)?omc_Expression_expAdd(threadData, _e1, _e2):omc_Expression_expSub(threadData, _e1, _e2))));
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
_res = tmpMeta[0];
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_T = omc_Expression_termsExpandUnary(threadData, _iSum);
_tp = omc_Expression_typeofOp(threadData, _iop);
_oExp = omc_Expression_makeConstZero(threadData, _tp);
_sE = _oExp;
{
modelica_metatype _elem;
for (tmpMeta[0] = _T; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_elem = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _elem, _iop, _iExp);
_e = tmpMeta[1];
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
tmpMeta[0] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _oExp, _iop, _iExp);
_e = tmpMeta[0];
_oExp = omc_Expression_expAdd(threadData, _sE, _e);
_return: OMC_LABEL_UNUSED
return _oExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryMulCoeff2(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outRes = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_real _coeff;
modelica_real _coeff_1;
modelica_integer _icoeff;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 7; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
_e = tmp3_1;
tmpMeta[1] = mmc_mk_box2(0, _e, _OMC_LIT26);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_real tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmp5 = mmc_unbox_real(tmpMeta[4]);
_e1 = tmpMeta[1];
_coeff = tmp5;
tmpMeta[1] = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
modelica_real tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],8,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],5,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],1,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmp6 = mmc_unbox_real(tmpMeta[6]);
_e1 = tmpMeta[1];
_coeff = tmp6;
_coeff_1 = (-_coeff);
tmpMeta[1] = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff_1));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmp7 = mmc_unbox_integer(tmpMeta[4]);
_e1 = tmpMeta[1];
_icoeff = tmp7;
_coeff_1 = ((modelica_real)_icoeff);
tmpMeta[1] = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff_1));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],8,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],5,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmp8 = mmc_unbox_integer(tmpMeta[6]);
_e1 = tmpMeta[1];
_icoeff = tmp8;
_coeff_1 = (-(((modelica_real)_icoeff)));
tmpMeta[1] = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff_1));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box2(0, _e1, _OMC_LIT28);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
tmpMeta[1] = mmc_mk_box2(0, _inExp, _OMC_LIT26);
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
_outRes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outRes;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryAddCoeff2(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outRes = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
modelica_metatype _exp = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_real _coeff;
modelica_real _coeff_1;
modelica_integer _icoeff;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 8; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box2(0, _inExp, _OMC_LIT26);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_real tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_exp = tmpMeta[3];
tmpMeta[1] = omc_ExpressionSimplify_simplifyBinaryAddCoeff2(threadData, _exp);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp5 = mmc_unbox_real(tmpMeta[3]);
_exp = tmpMeta[2];
_coeff = tmp5;
_coeff = (-_coeff);
tmpMeta[1] = mmc_mk_box2(0, _exp, mmc_mk_real(_coeff));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
modelica_real tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp6 = mmc_unbox_real(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_coeff = tmp6;
_e1 = tmpMeta[4];
tmpMeta[1] = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
modelica_real tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmp7 = mmc_unbox_real(tmpMeta[4]);
_e1 = tmpMeta[1];
_coeff = tmp7;
tmpMeta[1] = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmp8 = mmc_unbox_integer(tmpMeta[4]);
_e1 = tmpMeta[1];
_icoeff = tmp8;
_coeff_1 = ((modelica_real)_icoeff);
tmpMeta[1] = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff_1));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp9 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_icoeff = tmp9;
_e1 = tmpMeta[4];
_coeff_1 = ((modelica_real)_icoeff);
tmpMeta[1] = mmc_mk_box2(0, _e1, mmc_mk_real(_coeff_1));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box2(0, _e1, _OMC_LIT28);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 7: {
tmpMeta[1] = mmc_mk_box2(0, _inExp, _OMC_LIT26);
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
_outRes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outRes;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAddMakeMul(threadData_t *threadData, modelica_metatype _inTplExpRealLst)
{
modelica_metatype _outExpLst = NULL;
modelica_metatype _tplExpReal = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outExpLst = tmpMeta[0];
{
modelica_metatype _tplExpReal;
for (tmpMeta[1] = _inTplExpRealLst; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_tplExpReal = MMC_CAR(tmpMeta[1]);
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _tplExpReal;
{
modelica_metatype _e = NULL;
modelica_real _r;
modelica_integer _tmpInt;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_real tmp5;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_real(tmpMeta[4]);
_e = tmpMeta[3];
_r = tmp5;
if (!(_r == 1.0)) goto tmp2_end;
tmpMeta[3] = mmc_mk_cons(_e, _outExpLst);
tmpMeta[2] = tmpMeta[3];
goto tmp2_done;
}
case 1: {
modelica_real tmp6;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp6 = mmc_unbox_real(tmpMeta[4]);
_e = tmpMeta[3];
_r = tmp6;
tmpMeta[3] = omc_Expression_typeof(threadData, _e);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,1) == 0) goto goto_1;
_tmpInt = ((modelica_integer)floor(_r));
tmpMeta[4] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_tmpInt));
tmpMeta[5] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[4], _OMC_LIT55, _e);
tmpMeta[3] = mmc_mk_cons(tmpMeta[5], _outExpLst);
tmpMeta[2] = tmpMeta[3];
goto tmp2_done;
}
case 2: {
modelica_real tmp7;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp7 = mmc_unbox_real(tmpMeta[4]);
_e = tmpMeta[3];
_r = tmp7;
tmpMeta[4] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[5] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, tmpMeta[4], _OMC_LIT34, _e);
tmpMeta[3] = mmc_mk_cons(tmpMeta[5], _outExpLst);
tmpMeta[2] = tmpMeta[3];
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
_outExpLst = tmpMeta[2];
}
}
_return: OMC_LABEL_UNUSED
return _outExpLst;
}
PROTECTED_FUNCTION_STATIC modelica_real omc_ExpressionSimplify_simplifyAddJoinTermsFind(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTplExpRealLst, modelica_metatype *out_outTplExpRealLst)
{
modelica_real _outReal;
modelica_metatype _outTplExpRealLst = NULL;
modelica_metatype _e = NULL;
modelica_real _coeff;
modelica_real tmp1;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outReal = 0.0;
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outTplExpRealLst = tmpMeta[0];
{
modelica_metatype _t;
for (tmpMeta[1] = _inTplExpRealLst; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_t = MMC_CAR(tmpMeta[1]);
tmpMeta[2] = _t;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp1 = mmc_unbox_real(tmpMeta[4]);
_e = tmpMeta[3];
_coeff = tmp1;
if(omc_Expression_expEqual(threadData, _inExp, _e))
{
_outReal = _outReal + _coeff;
}
else
{
tmpMeta[2] = mmc_mk_cons(_t, _outTplExpRealLst);
_outTplExpRealLst = tmpMeta[2];
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
modelica_metatype _tplExpRealLst = NULL;
modelica_metatype _t = NULL;
modelica_metatype _e = NULL;
modelica_real _coeff;
modelica_real _coeff2;
modelica_real tmp1;
modelica_boolean tmp2;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outTplExpRealLst = tmpMeta[0];
_tplExpRealLst = _inTplExpRealLst;
while(1)
{
if(!(!listEmpty(_tplExpRealLst))) break;
tmpMeta[1] = _tplExpRealLst;
if (listEmpty(tmpMeta[1])) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_t = tmpMeta[2];
_tplExpRealLst = tmpMeta[3];
tmpMeta[1] = _t;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp1 = mmc_unbox_real(tmpMeta[3]);
_e = tmpMeta[2];
_coeff = tmp1;
_coeff2 = omc_ExpressionSimplify_simplifyAddJoinTermsFind(threadData, _e, _tplExpRealLst ,&_tplExpRealLst);
_coeff = _coeff + _coeff2;
tmp2 = (modelica_boolean)(_coeff2 == 0.0);
if(tmp2)
{
tmpMeta[3] = _t;
}
else
{
tmpMeta[2] = mmc_mk_box2(0, _e, mmc_mk_real(_coeff));
tmpMeta[3] = tmpMeta[2];
}
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], _outTplExpRealLst);
_outTplExpRealLst = tmpMeta[1];
}
_return: OMC_LABEL_UNUSED
return _outTplExpRealLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAdd(threadData_t *threadData, modelica_metatype _inExpLst)
{
modelica_metatype _outExpLst = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _exp_const = NULL;
modelica_metatype _exp_const_1 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_exp_const = omc_List_map(threadData, _inExpLst, boxvar_ExpressionSimplify_simplifyBinaryAddCoeff2);
_exp_const_1 = omc_ExpressionSimplify_simplifyAddJoinTerms(threadData, _exp_const);
tmpMeta[0] = omc_ExpressionSimplify_simplifyAddMakeMul(threadData, _exp_const_1);
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
tmp5 = omc_Flags_isSet(threadData, _OMC_LIT59);
if (1 != tmp5) goto goto_1;
omc_Debug_trace(threadData, _OMC_LIT60);
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
_outExpLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExpLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMulMakePow(threadData_t *threadData, modelica_metatype _inTplExpRealLst)
{
modelica_metatype _outExpLst = NULL;
modelica_metatype _tplExpReal = NULL;
modelica_metatype _e = NULL;
modelica_real _r;
modelica_real tmp1;
modelica_boolean tmp2;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outExpLst = tmpMeta[0];
{
modelica_metatype _tplExpReal;
for (tmpMeta[1] = _inTplExpRealLst; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_tplExpReal = MMC_CAR(tmpMeta[1]);
tmpMeta[2] = _tplExpReal;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp1 = mmc_unbox_real(tmpMeta[4]);
_e = tmpMeta[3];
_r = tmp1;
tmp2 = (modelica_boolean)(_r == 1.0);
if(tmp2)
{
tmpMeta[2] = mmc_mk_cons(_e, _outExpLst);
tmpMeta[6] = tmpMeta[2];
}
else
{
tmpMeta[4] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[5] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT36, tmpMeta[4]);
tmpMeta[3] = mmc_mk_cons(tmpMeta[5], _outExpLst);
tmpMeta[6] = tmpMeta[3];
}
_outExpLst = tmpMeta[6];
}
}
_return: OMC_LABEL_UNUSED
return _outExpLst;
}
PROTECTED_FUNCTION_STATIC modelica_real omc_ExpressionSimplify_simplifyMulJoinFactorsFind(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTplExpRealLst, modelica_metatype *out_outTplExpRealLst)
{
modelica_real _outReal;
modelica_metatype _outTplExpRealLst = NULL;
modelica_metatype _tplExpReal = NULL;
modelica_real tmp1_c0 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outReal = 0.0;
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outTplExpRealLst = tmpMeta[0];
{
modelica_metatype _tplExpReal;
for (tmpMeta[1] = _inTplExpRealLst; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_tplExpReal = MMC_CAR(tmpMeta[1]);
{
modelica_metatype tmp4_1;
tmp4_1 = _tplExpReal;
{
modelica_real _coeff;
modelica_metatype _e2 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _op = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_real tmp6;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp6 = mmc_unbox_real(tmpMeta[5]);
_e2 = tmpMeta[4];
_coeff = tmp6;
if (!omc_Expression_expEqual(threadData, _inExp, _e2)) goto tmp3_end;
tmp1_c0 = _coeff + _outReal;
tmpMeta[2+1] = _outTplExpRealLst;
goto tmp3_done;
}
case 1: {
modelica_real tmp7;
modelica_boolean tmp8;
modelica_boolean tmp9;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],7,3) == 0) goto tmp3_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],3,1) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp7 = mmc_unbox_real(tmpMeta[8]);
_e1 = tmpMeta[5];
_op = tmpMeta[6];
_e2 = tmpMeta[7];
_coeff = tmp7;
tmp8 = (modelica_boolean)omc_Expression_isOne(threadData, _e1);
if(tmp8)
{
tmp9 = omc_Expression_expEqual(threadData, _inExp, _e2);
}
else
{
tmpMeta[4] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e2, _op, _e1);
tmp9 = omc_Expression_expEqual(threadData, _inExp, tmpMeta[4]);
}
if (!tmp9) goto tmp3_end;
tmp1_c0 = _outReal - _coeff;
tmpMeta[2+1] = _outTplExpRealLst;
goto tmp3_done;
}
case 2: {
tmpMeta[4] = mmc_mk_cons(_tplExpReal, _outTplExpRealLst);
tmp1_c0 = _outReal;
tmpMeta[2+1] = tmpMeta[4];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outReal = tmp1_c0;
_outTplExpRealLst = tmpMeta[2+1];
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
modelica_metatype _tplExpRealLst = NULL;
modelica_metatype _e = NULL;
modelica_real _coeff;
modelica_real _coeff2;
modelica_real tmp1;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outTplExpRealLst = tmpMeta[0];
_tplExpRealLst = _inTplExpRealLst;
while(1)
{
if(!(!listEmpty(_tplExpRealLst))) break;
tmpMeta[1] = _tplExpRealLst;
if (listEmpty(tmpMeta[1])) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp1 = mmc_unbox_real(tmpMeta[5]);
_e = tmpMeta[4];
_coeff = tmp1;
_tplExpRealLst = tmpMeta[3];
_coeff2 = omc_ExpressionSimplify_simplifyMulJoinFactorsFind(threadData, _e, _tplExpRealLst ,&_tplExpRealLst);
_coeff = _coeff + _coeff2;
tmpMeta[2] = mmc_mk_box2(0, _e, mmc_mk_real(_coeff));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _outTplExpRealLst);
_outTplExpRealLst = tmpMeta[1];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inExpLst;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
_outExp = tmpMeta[1];
_es = tmpMeta[2];
_tp = omc_Expression_typeof(threadData, _outExp);
{
modelica_metatype _e;
for (tmpMeta[0] = _es; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_e = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
_outExp = omc_ExpressionSimplify_simplifyBinaryConst(threadData, tmpMeta[1], _outExp, _e);
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inExpLst;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
_outExp = tmpMeta[1];
_es = tmpMeta[2];
_tp = omc_Expression_typeof(threadData, _outExp);
{
modelica_metatype _e;
for (tmpMeta[0] = _es; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_e = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Operator_ADD__desc, _tp);
_outExp = omc_ExpressionSimplify_simplifyBinaryConst(threadData, tmpMeta[1], _outExp, _e);
}
}
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryCoeff(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inExp;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_e = tmp3_1;
_tp = tmpMeta[2];
tmp3 += 3;
if (!omc_Types_isScalarReal(threadData, _tp)) goto tmp2_end;
_e_lst = omc_Expression_factors(threadData, _e);
_e_lst_1 = omc_ExpressionSimplify_simplifyMul(threadData, _e_lst);
tmpMeta[0] = omc_Expression_makeProductLst(threadData, _e_lst_1);
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
tmp3 += 2;
tmp5 = omc_Expression_isZero(threadData, _e2);
if (0 != tmp5) goto goto_1;
_e1_lst = omc_Expression_factors(threadData, _e1);
_e2_lst = omc_Expression_factors(threadData, _e2);
_e2_lst_1 = omc_List_map(threadData, _e2_lst, boxvar_Expression_inverseFactors);
_e_lst = listAppend(_e1_lst, _e2_lst_1);
_e_lst_1 = omc_ExpressionSimplify_simplifyMul(threadData, _e_lst);
tmpMeta[0] = omc_Expression_makeProductLst(threadData, _e_lst_1);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
_e = tmp3_1;
tmp3 += 1;
_e_lst = omc_Expression_terms(threadData, _e);
_e_lst_1 = omc_ExpressionSimplify_simplifyAdd(threadData, _e_lst);
tmpMeta[0] = omc_Expression_makeSum(threadData, _e_lst_1);
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[3];
_e1_lst = omc_Expression_terms(threadData, _e1);
_e2_lst = omc_Expression_terms(threadData, _e2);
_e2_lst = omc_List_map(threadData, _e2_lst, boxvar_Expression_negate);
_e_lst = listAppend(_e1_lst, _e2_lst);
_e_lst_1 = omc_ExpressionSimplify_simplifyAdd(threadData, _e_lst);
tmpMeta[0] = omc_Expression_makeSum(threadData, _e_lst_1);
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _inExp;
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinarySortConstants(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inExp;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) goto tmp2_end;
_e = tmp3_1;
tmp3 += 2;
tmpMeta[0] = omc_ExpressionSimplify_simplifyBinarySortConstantsMul(threadData, _e);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_tp = tmpMeta[3];
_e2 = tmpMeta[4];
tmp3 += 1;
_e1 = omc_ExpressionSimplify_simplifyBinarySortConstantsMul(threadData, _e1);
_e2 = omc_ExpressionSimplify_simplifyBinarySortConstantsMul(threadData, _e2);
tmpMeta[1] = mmc_mk_box2(6, &DAE_Operator_DIV__desc, _tp);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
_e = tmp3_1;
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
tmpMeta[0] = _res;
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _inExp;
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixProduct4(threadData_t *threadData, modelica_metatype _inMatrix1, modelica_metatype _inMatrix2)
{
modelica_metatype _outDimensions = NULL;
modelica_metatype tmpMeta[13] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inMatrix1;
tmp3_2 = _inMatrix2;
{
modelica_metatype _n = NULL;
modelica_metatype _m = NULL;
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
_n = tmpMeta[7];
tmpMeta[1] = mmc_mk_cons(_n, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
_m = tmpMeta[7];
tmpMeta[1] = mmc_mk_cons(_m, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],6,2) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 3));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (listEmpty(tmpMeta[10])) goto tmp2_end;
tmpMeta[11] = MMC_CAR(tmpMeta[10]);
tmpMeta[12] = MMC_CDR(tmpMeta[10]);
if (!listEmpty(tmpMeta[12])) goto tmp2_end;
_n = tmpMeta[3];
_p = tmpMeta[9];
tmpMeta[1] = mmc_mk_cons(_n, mmc_mk_cons(_p, MMC_REFSTRUCTLIT(mmc_nil)));
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
_outDimensions = tmpMeta[0];
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
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inMatrix1;
tmp3_2 = _inMatrix2;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_ty = tmpMeta[1];
_dims = tmpMeta[2];
tmp5 = omc_Expression_arrayContainZeroDimension(threadData, _dims);
if (1 != tmp5) goto goto_1;
_zero = omc_Expression_makeConstZero(threadData, _ty);
_dims = omc_ExpressionSimplify_simplifyMatrixProduct4(threadData, _inMatrix1, _inMatrix2);
tmpMeta[0] = omc_Expression_arrayFill(threadData, _dims, _zero);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
if (listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[8] = MMC_CAR(tmpMeta[7]);
tmpMeta[9] = MMC_CDR(tmpMeta[7]);
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_ty = tmpMeta[6];
_n = tmpMeta[8];
_expl1 = tmpMeta[12];
tmp3 += 2;
_expl1 = omc_List_map1(threadData, _expl1, boxvar_ExpressionSimplify_simplifyScalarProduct, _inMatrix2);
tmpMeta[1] = mmc_mk_cons(_n, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta[1]);
_ty = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _ty, mmc_mk_boolean(1), _expl1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
if (listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[8] = MMC_CAR(tmpMeta[7]);
tmpMeta[9] = MMC_CDR(tmpMeta[7]);
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_ty = tmpMeta[6];
_m = tmpMeta[8];
_expl2 = tmpMeta[12];
tmp3 += 1;
_expl1 = omc_List_map1r(threadData, _expl2, boxvar_ExpressionSimplify_simplifyScalarProduct, _inMatrix1);
tmpMeta[1] = mmc_mk_cons(_m, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta[1]);
_ty = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _ty, mmc_mk_boolean(1), _expl1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],6,2) == 0) goto tmp2_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 3));
if (listEmpty(tmpMeta[10])) goto tmp2_end;
tmpMeta[11] = MMC_CAR(tmpMeta[10]);
tmpMeta[12] = MMC_CDR(tmpMeta[10]);
if (listEmpty(tmpMeta[12])) goto tmp2_end;
tmpMeta[13] = MMC_CAR(tmpMeta[12]);
tmpMeta[14] = MMC_CDR(tmpMeta[12]);
if (!listEmpty(tmpMeta[14])) goto tmp2_end;
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_ty = tmpMeta[2];
_n = tmpMeta[4];
_expl1 = tmpMeta[8];
_p = tmpMeta[11];
_expl2 = tmpMeta[15];
_matrix = omc_List_map1(threadData, _expl1, boxvar_ExpressionSimplify_simplifyMatrixProduct3, _expl2);
tmpMeta[1] = mmc_mk_cons(_p, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta[1]);
_row_ty = tmpMeta[2];
_expl1 = omc_List_map2(threadData, _matrix, boxvar_Expression_makeArray, _row_ty, mmc_mk_boolean(1));
tmpMeta[1] = mmc_mk_cons(_n, mmc_mk_cons(_p, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[2] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _ty, tmpMeta[1]);
tmpMeta[3] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta[2], mmc_mk_boolean(0), _expl1);
tmpMeta[0] = tmpMeta[3];
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
_outProduct = tmpMeta[0];
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;volatile modelica_metatype tmp3_3;
tmp3_1 = _inRange;
tmp3_2 = _inMatrix;
tmp3_3 = _inValue;
{
modelica_metatype _rm = NULL;
modelica_metatype _rm1 = NULL;
modelica_metatype _row = NULL;
modelica_metatype _row1 = NULL;
modelica_metatype _e = NULL;
modelica_integer _i;
modelica_metatype _rr = NULL;
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
if (!listEmpty(tmp3_2)) goto tmp2_end;
tmp3 += 2;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_integer tmp5;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmp5 = mmc_unbox_integer(tmpMeta[1]);
if (!listEmpty(tmpMeta[2])) goto tmp2_end;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmp3_2);
tmpMeta[4] = MMC_CDR(tmp3_2);
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
_i = tmp5;
_row = tmpMeta[3];
_e = tmp3_3;
_row1 = omc_List_replaceAt(threadData, _e, ((modelica_integer) 1) + _i, _row);
tmpMeta[1] = mmc_mk_cons(_row1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
modelica_integer tmp6;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmp6 = mmc_unbox_integer(tmpMeta[1]);
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmp3_2);
tmpMeta[4] = MMC_CDR(tmp3_2);
_i = tmp6;
_rr = tmpMeta[2];
_row = tmpMeta[3];
_rm = tmpMeta[4];
_e = tmp3_3;
_row1 = omc_List_replaceAt(threadData, _e, ((modelica_integer) 1) + _i, _row);
_rm1 = omc_ExpressionSimplify_simplifyMatrixPow1(threadData, _rr, _rm, _e);
tmpMeta[1] = mmc_mk_cons(_row1, _rm1);
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
_outMatrix = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outMatrix;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixPow(threadData_t *threadData, modelica_metatype _inExp1, modelica_metatype _inType, modelica_metatype _inExp2)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inExp1;
tmp3_2 = _inExp2;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
modelica_integer tmp6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp6 = mmc_unbox_integer(tmpMeta[3]);
_tp1 = tmpMeta[1];
_size1 = tmp5;
_i = tmp6;
tmp7 = _i;
if (0 != tmp7) goto goto_1;
_el = omc_List_fill(threadData, _OMC_LIT20, _size1);
_expl2 = omc_List_fill(threadData, _el, _size1);
_range = omc_List_intRange2(threadData, ((modelica_integer) 0), ((modelica_integer) -1) + _size1);
_expl_1 = omc_ExpressionSimplify_simplifyMatrixPow1(threadData, _range, _expl2, _OMC_LIT27);
tmpMeta[1] = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _tp1, mmc_mk_integer(_size1), _expl_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_integer tmp8;
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,3) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp8 = mmc_unbox_integer(tmpMeta[1]);
_m = tmp3_1;
_i = tmp8;
tmp9 = _i;
if (1 != tmp9) goto goto_1;
tmpMeta[0] = _m;
goto tmp2_done;
}
case 2: {
modelica_integer tmp10;
modelica_integer tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,3) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp10 = mmc_unbox_integer(tmpMeta[1]);
_m = tmp3_1;
_i = tmp10;
tmp11 = _i;
if (2 != tmp11) goto goto_1;
tmpMeta[0] = omc_ExpressionSimplify_simplifyMatrixProduct(threadData, _m, _m);
goto tmp2_done;
}
case 3: {
modelica_integer tmp12;
modelica_boolean tmp13;
modelica_integer tmp14;
modelica_integer tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp12 = mmc_unbox_integer(tmpMeta[2]);
_m = tmp3_1;
_tp1 = tmpMeta[1];
_i = tmp12;
tmp13 = (_i > ((modelica_integer) 3));
if (1 != tmp13) goto goto_1;
tmp14 = modelica_integer_mod(_i, ((modelica_integer) 2));
if (0 != tmp14) goto goto_1;
tmp15 = ((modelica_integer) 2);
if (tmp15 == 0) {goto goto_1;}
_i_1 = ldiv(_i,tmp15).quot;
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i_1));
_e = omc_ExpressionSimplify_simplifyMatrixPow(threadData, _m, _tp1, tmpMeta[1]);
tmpMeta[0] = omc_ExpressionSimplify_simplifyMatrixProduct(threadData, _e, _e);
goto tmp2_done;
}
case 4: {
modelica_integer tmp16;
modelica_boolean tmp17;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp16 = mmc_unbox_integer(tmpMeta[2]);
_m = tmp3_1;
_tp1 = tmpMeta[1];
_i = tmp16;
tmp17 = (((modelica_integer) 1) < _i);
if (1 != tmp17) goto goto_1;
_i_1 = ((modelica_integer) -1) + _i;
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i_1));
_e = omc_ExpressionSimplify_simplifyMatrixPow(threadData, _m, _tp1, tmpMeta[1]);
tmpMeta[0] = omc_ExpressionSimplify_simplifyMatrixProduct(threadData, _m, _e);
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatrixBinary2(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inRhs, modelica_metatype _inOperator)
{
modelica_metatype _outExp = NULL;
modelica_metatype _op = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_op = omc_ExpressionSimplify_removeOperatorDimension(threadData, _inOperator);
tmpMeta[0] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _inLhs, _op, _inRhs);
_outExp = tmpMeta[0];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_lhs = omc_Expression_get2dArrayOrMatrixContent(threadData, _inLhs);
_rhs = omc_Expression_get2dArrayOrMatrixContent(threadData, _inRhs);
_op = omc_ExpressionSimplify_removeOperatorDimension(threadData, _inOperator);
_res = omc_List_threadMap1(threadData, _lhs, _rhs, boxvar_ExpressionSimplify_simplifyMatrixBinary1, _op);
_sz = listLength(_res);
_ty = omc_Expression_typeof(threadData, _inLhs);
tmpMeta[0] = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _ty, mmc_mk_integer(_sz), _res);
_outResult = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorBinary2(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inRhs, modelica_metatype _inOperator)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _inLhs, _inOperator, _inRhs);
_outExp = tmpMeta[0];
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
modelica_integer tmp1;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inLhs;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],16,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp1 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_ty = tmpMeta[1];
_sc = tmp1;
_lhs = tmpMeta[3];
tmpMeta[0] = _inRhs;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],16,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_rhs = tmpMeta[1];
_op = omc_ExpressionSimplify_removeOperatorDimension(threadData, _inOperator);
_res = omc_List_threadMap1(threadData, _lhs, _rhs, boxvar_ExpressionSimplify_simplifyVectorBinary2, _op);
tmpMeta[0] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _ty, mmc_mk_boolean(_sc), _res);
_outResult = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outResult;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorBinary0(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _op, modelica_metatype _e2)
{
modelica_metatype _res = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _op;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 6; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[0] = omc_ExpressionSimplify_simplifyVectorBinary(threadData, _e1, _op, _e2);
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmp3 += 3;
tmp5 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp5) goto goto_1;
tmpMeta[0] = _e2;
goto tmp2_done;
}
case 2: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,1) == 0) goto tmp2_end;
tmp3 += 2;
tmp6 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp6) goto goto_1;
tmpMeta[0] = _e2;
goto tmp2_done;
}
case 3: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,1) == 0) goto tmp2_end;
tmp3 += 1;
tmp7 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp7) goto goto_1;
tmpMeta[0] = omc_Expression_negate(threadData, _e2);
goto tmp2_done;
}
case 4: {
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmp8 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp8) goto goto_1;
tmpMeta[0] = omc_Expression_negate(threadData, _e2);
goto tmp2_done;
}
case 5: {
modelica_boolean tmp9;
tmp9 = omc_Expression_isZero(threadData, _e2);
if (1 != tmp9) goto goto_1;
tmpMeta[0] = _e1;
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
_res = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyVectorScalar(threadData_t *threadData, modelica_metatype _inLhs, modelica_metatype _inOperator, modelica_metatype _inRhs)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _inLhs;
tmp3_2 = _inOperator;
tmp3_3 = _inRhs;
{
modelica_metatype _s1 = NULL;
modelica_metatype _op = NULL;
modelica_metatype _tp = NULL;
modelica_boolean _sc;
modelica_metatype _es = NULL;
modelica_metatype _mexpl = NULL;
modelica_integer _dims;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_tp = tmpMeta[1];
_sc = tmp5;
_es = tmpMeta[3];
_es = omc_List_map2r(threadData, _es, boxvar_Expression_makeBinaryExp, _inLhs, _inOperator);
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(_sc), _es);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,17,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 4));
_tp = tmpMeta[1];
_dims = tmp6;
_mexpl = tmpMeta[3];
_s1 = tmp3_1;
_op = tmp3_2;
_mexpl = omc_ExpressionSimplify_simplifyVectorScalarMatrix(threadData, _mexpl, _op, _s1, 0);
tmpMeta[1] = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _tp, mmc_mk_integer(_dims), _mexpl);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp7 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_tp = tmpMeta[1];
_sc = tmp7;
_es = tmpMeta[3];
_es = omc_List_map2(threadData, _es, boxvar_Expression_makeBinaryExp, _inOperator, _inRhs);
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(_sc), _es);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp8 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_tp = tmpMeta[1];
_dims = tmp8;
_mexpl = tmpMeta[3];
_op = tmp3_2;
_s1 = tmp3_3;
_mexpl = omc_ExpressionSimplify_simplifyVectorScalarMatrix(threadData, _mexpl, _op, _s1, 1);
tmpMeta[1] = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _tp, mmc_mk_integer(_dims), _mexpl);
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_unliftOperator(threadData_t *threadData, modelica_metatype _inArray, modelica_metatype _inOperator)
{
modelica_metatype _outOperator = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inArray;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,3) == 0) goto tmp2_end;
tmpMeta[0] = omc_Expression_unliftOperatorX(threadData, _inOperator, ((modelica_integer) 2));
goto tmp2_done;
}
case 1: {
tmpMeta[0] = omc_Expression_unliftOperator(threadData, _inOperator);
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
_outOperator = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outOperator;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyScalarProduct(threadData_t *threadData, modelica_metatype _inVector1, modelica_metatype _inVector2)
{
modelica_metatype _outProduct = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inVector1;
tmp3_2 = _inVector2;
{
modelica_metatype _expl = NULL;
modelica_metatype _expl1 = NULL;
modelica_metatype _expl2 = NULL;
modelica_metatype _tp = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (!listEmpty(tmpMeta[2])) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_tp = tmpMeta[1];
tmpMeta[0] = omc_Expression_makeConstZero(threadData, _tp);
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
_expl1 = tmpMeta[1];
_expl2 = tmpMeta[2];
tmp5 = (omc_Expression_isVector(threadData, _inVector1) && omc_Expression_isVector(threadData, _inVector2));
if (1 != tmp5) goto goto_1;
_expl = omc_List_threadMap(threadData, _expl1, _expl2, boxvar_Expression_expMul);
tmpMeta[0] = omc_List_reduce(threadData, _expl, boxvar_Expression_expAdd);
goto tmp2_done;
}
case 2: {
modelica_boolean tmp6;
tmp6 = (omc_Expression_isZero(threadData, _inVector1) || omc_Expression_isZero(threadData, _inVector2));
if (1 != tmp6) goto goto_1;
tmpMeta[0] = omc_Expression_makeConstZero(threadData, _OMC_LIT30);
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
_outProduct = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outProduct;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBinaryArray(threadData_t *threadData, modelica_metatype _inExp1, modelica_metatype _inOperator2, modelica_metatype _inExp3)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;volatile modelica_metatype tmp3_3;
tmp3_1 = _inExp1;
tmp3_2 = _inOperator2;
tmp3_3 = _inExp3;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _s1 = NULL;
modelica_metatype _a1 = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _op = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 20; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,15,1) == 0) goto tmp2_end;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 8;
tmpMeta[0] = omc_ExpressionSimplify_simplifyMatrixProduct(threadData, _e1, _e2);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,1) == 0) goto tmp2_end;
_op = tmp3_2;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 6;
tmpMeta[0] = omc_ExpressionSimplify_simplifyVectorBinary0(threadData, _e1, _op, _e2);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,1) == 0) goto tmp2_end;
_op = tmp3_2;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 4;
tmpMeta[0] = omc_ExpressionSimplify_simplifyVectorBinary0(threadData, _e1, _op, _e2);
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,1) == 0) goto tmp2_end;
_op = tmp3_2;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 5;
tmpMeta[0] = omc_ExpressionSimplify_simplifyVectorBinary(threadData, _e1, _op, _e2);
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,10,1) == 0) goto tmp2_end;
_op = tmp3_2;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 4;
tmpMeta[0] = omc_ExpressionSimplify_simplifyVectorBinary(threadData, _e1, _op, _e2);
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,20,1) == 0) goto tmp2_end;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 3;
_tp = omc_Expression_typeof(threadData, _e1);
tmpMeta[0] = omc_ExpressionSimplify_simplifyMatrixPow(threadData, _e1, _tp, _e2);
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,21,1) == 0) goto tmp2_end;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 2;
_tp = omc_Expression_typeof(threadData, _e1);
tmpMeta[1] = mmc_mk_box2(24, &DAE_Operator_POW__ARR2__desc, _tp);
tmpMeta[0] = omc_ExpressionSimplify_simplifyVectorBinary(threadData, _e1, tmpMeta[1], _e2);
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,8,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
_tp = tmpMeta[1];
_e2 = tmpMeta[2];
_e1 = tmp3_1;
tmp3 += 1;
tmpMeta[1] = mmc_mk_box2(10, &DAE_Operator_ADD__ARR__desc, _tp);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,8,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 3));
_tp = tmpMeta[1];
_e2 = tmpMeta[2];
_e1 = tmp3_1;
tmpMeta[1] = mmc_mk_box2(11, &DAE_Operator_SUB__ARR__desc, _tp);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, tmpMeta[1], _e2);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 9: {
modelica_boolean tmp5;
_a1 = tmp3_1;
_op = tmp3_2;
_s1 = tmp3_3;
tmp5 = omc_Expression_isArrayScalarOp(threadData, _op);
if (1 != tmp5) goto goto_1;
_op = omc_ExpressionSimplify_unliftOperator(threadData, _a1, _op);
tmpMeta[0] = omc_ExpressionSimplify_simplifyVectorScalar(threadData, _a1, _op, _s1);
goto tmp2_done;
}
case 10: {
modelica_boolean tmp6;
_s1 = tmp3_1;
_op = tmp3_2;
_a1 = tmp3_3;
tmp6 = omc_Expression_isScalarArrayOp(threadData, _op);
if (1 != tmp6) goto goto_1;
_op = omc_ExpressionSimplify_unliftOperator(threadData, _a1, _op);
tmpMeta[0] = omc_ExpressionSimplify_simplifyVectorScalar(threadData, _s1, _op, _a1);
goto tmp2_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,14,1) == 0) goto tmp2_end;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 8;
tmpMeta[0] = omc_ExpressionSimplify_simplifyScalarProduct(threadData, _e1, _e2);
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,7,1) == 0) goto tmp2_end;
_op = tmp3_2;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 7;
tmpMeta[0] = omc_ExpressionSimplify_simplifyMatrixBinary(threadData, _e1, _op, _e2);
goto tmp2_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,1) == 0) goto tmp2_end;
_op = tmp3_2;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 6;
tmpMeta[0] = omc_ExpressionSimplify_simplifyMatrixBinary(threadData, _e1, _op, _e2);
goto tmp2_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,1) == 0) goto tmp2_end;
_op = tmp3_2;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 5;
tmpMeta[0] = omc_ExpressionSimplify_simplifyMatrixBinary(threadData, _e1, _op, _e2);
goto tmp2_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,10,1) == 0) goto tmp2_end;
_op = tmp3_2;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 2;
tmpMeta[0] = omc_ExpressionSimplify_simplifyMatrixBinary(threadData, _e1, _op, _e2);
goto tmp2_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,21,1) == 0) goto tmp2_end;
_op = tmp3_2;
_e1 = tmp3_1;
_e2 = tmp3_3;
tmp3 += 3;
tmpMeta[0] = omc_ExpressionSimplify_simplifyMatrixBinary(threadData, _e1, _op, _e2);
goto tmp2_done;
}
case 17: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,11,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
_tp = tmpMeta[1];
_e2 = tmp3_3;
tmp3 += 2;
tmp7 = omc_Expression_isZero(threadData, _e2);
if (1 != tmp7) goto goto_1;
tmpMeta[0] = omc_Expression_makeZeroExpression(threadData, omc_Expression_arrayDimension(threadData, _tp), NULL);
goto tmp2_done;
}
case 18: {
modelica_boolean tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,10,1) == 0) goto tmp2_end;
_e1 = tmp3_1;
tmp3 += 1;
tmp8 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp8) goto goto_1;
_tp = omc_Expression_typeof(threadData, _e1);
tmpMeta[0] = omc_Expression_makeZeroExpression(threadData, omc_Expression_arrayDimension(threadData, _tp), NULL);
goto tmp2_done;
}
case 19: {
modelica_boolean tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,16,1) == 0) goto tmp2_end;
_e1 = tmp3_1;
tmp9 = omc_Expression_isZero(threadData, _e1);
if (1 != tmp9) goto goto_1;
_tp = omc_Expression_typeof(threadData, _e1);
tmpMeta[0] = omc_Expression_makeZeroExpression(threadData, omc_Expression_arrayDimension(threadData, _tp), NULL);
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
if (++tmp3 < 20) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outExp = tmpMeta[0];
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ty = omc_Expression_typeof(threadData, _inExp);
if((!omc_Expression_isIntegerOrReal(threadData, _ty)))
{
_outExp = _inExp;
goto _return;
}
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 7; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_op = tmpMeta[1];
if (!(_simplifyAddOrSub && omc_Expression_isAddOrSub(threadData, _op))) goto tmp2_end;
_lstExp = omc_Expression_terms(threadData, _inExp);
_lstConstExp = omc_List_splitOnTrue(threadData, _lstExp, boxvar_Expression_isConstValue ,&_lstExp);
_hasConst = (!listEmpty(_lstConstExp));
_resConst = (_hasConst?omc_ExpressionSimplify_simplifyBinaryAddConstants(threadData, _lstConstExp):omc_Expression_makeConstZero(threadData, _ty));
_exp_2 = (_hasConst?omc_Expression_makeSum1(threadData, _lstExp, 0):_inExp);
_exp_3 = omc_ExpressionSimplify_simplifyBinaryCoeff(threadData, _exp_2);
tmp5 = (modelica_boolean)_hasConst;
if(tmp5)
{
tmpMeta[1] = omc_Expression_expAdd(threadData, _resConst, omc_ExpressionSimplify_simplify2(threadData, _exp_3, 0, 1));
}
else
{
_inExp = _exp_3;
_simplifyAddOrSub = 0;
_simplifyMulOrDiv = 1;
goto _tailrecursive;
}
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
if (!omc_Expression_isAddOrSub(threadData, _op)) goto tmp2_end;
_e1 = omc_ExpressionSimplify_simplify2(threadData, _e1, 0, 1);
_e2 = omc_ExpressionSimplify_simplify2(threadData, _e2, 0, 1);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_op = tmpMeta[1];
if (!(_simplifyMulOrDiv && omc_Expression_isMulOrDiv(threadData, _op))) goto tmp2_end;
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
tmpMeta[0] = _exp_3;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
if (!omc_Expression_isMulOrDiv(threadData, _op)) goto tmp2_end;
_e1 = omc_ExpressionSimplify_simplify2(threadData, _e1, 1, 0);
_e2 = omc_ExpressionSimplify_simplify2(threadData, _e2, 1, 0);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
_e1 = omc_ExpressionSimplify_simplify2(threadData, _e1, 1, 1);
_e2 = omc_ExpressionSimplify_simplify2(threadData, _e2, 1, 1);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_op = tmpMeta[1];
_e1 = tmpMeta[2];
_e1 = omc_ExpressionSimplify_simplify2(threadData, _e1, 1, 1);
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op, _e1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _inExp;
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
_outExp = tmpMeta[0];
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
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ssl;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _ident, _ty, tmpMeta[1]);
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, tmpMeta[2], _ty);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _ident, _ty, tmpMeta[1]);
tmpMeta[3] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, tmpMeta[2], _ty);
{
modelica_metatype __omcQ_24tmpVar17;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar16;
int tmp6;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = _ssl;
tmpMeta[5] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar17 = tmpMeta[5];
tmp5 = &__omcQ_24tmpVar17;
while(1) {
tmp6 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp6--;
}
if (tmp6 == 0) {
__omcQ_24tmpVar16 = omc_Expression_subscriptIndexExp(threadData, _s);
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar16,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[4] = __omcQ_24tmpVar17;
}
tmpMeta[6] = mmc_mk_box3(24, &DAE_Exp_ASUB__desc, tmpMeta[3], tmpMeta[4]);
tmpMeta[0] = tmpMeta[6];
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCrefMM(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inType, modelica_metatype _inCref)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inCref;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
_exp = omc_ExpressionSimplify_simplifyCrefMM__index(threadData, _inExp, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 2))), _inType);
tmp7 = (modelica_boolean)listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 4))));
if(tmp7)
{
tmpMeta[4] = _exp;
}
else
{
{
modelica_metatype __omcQ_24tmpVar19;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar18;
int tmp6;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 4)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar19 = tmpMeta[2];
tmp5 = &__omcQ_24tmpVar19;
while(1) {
tmp6 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp6--;
}
if (tmp6 == 0) {
__omcQ_24tmpVar18 = omc_Expression_subscriptIndexExp(threadData, _s);
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar18,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar19;
}
tmpMeta[3] = mmc_mk_box3(24, &DAE_Exp_ASUB__desc, _exp, tmpMeta[1]);
tmpMeta[4] = tmpMeta[3];
}
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 1: {
modelica_boolean tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
_exp = omc_ExpressionSimplify_simplifyCrefMM__index(threadData, _inExp, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 2))), _inType);
tmp10 = (modelica_boolean)listEmpty((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 4))));
if(tmp10)
{
tmpMeta[4] = _exp;
}
else
{
{
modelica_metatype __omcQ_24tmpVar21;
modelica_metatype* tmp8;
modelica_metatype __omcQ_24tmpVar20;
int tmp9;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 4)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar21 = tmpMeta[2];
tmp8 = &__omcQ_24tmpVar21;
while(1) {
tmp9 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp9--;
}
if (tmp9 == 0) {
__omcQ_24tmpVar20 = omc_Expression_subscriptIndexExp(threadData, _s);
*tmp8 = mmc_mk_cons(__omcQ_24tmpVar20,0);
tmp8 = &MMC_CDR(*tmp8);
} else if (tmp9 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp8 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar21;
}
tmpMeta[3] = mmc_mk_box3(24, &DAE_Exp_ASUB__desc, _exp, tmpMeta[1]);
tmpMeta[4] = tmpMeta[3];
}
_exp = tmpMeta[4];
_inExp = _exp;
_inType = omc_Expression_typeof(threadData, _exp);
_inCref = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCref), 5)));
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
_exp = tmpMeta[0];
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_fields = omc_Types_getMetaRecordFields(threadData, _ty);
_index = ((modelica_integer) 1) + omc_Types_findVarIndex(threadData, _ident, _fields);
tmpMeta[0] = listGet(_fields, _index);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_nty = tmpMeta[1];
tmpMeta[0] = mmc_mk_box5(26, &DAE_Exp_RSUB__desc, _inExp, mmc_mk_integer(_index), _ident, _nty);
_exp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCref2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inSsl)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inExp;
tmp3_2 = _inSsl;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
_exp_1 = tmp3_1;
tmp3 += 2;
tmpMeta[0] = _exp_1;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmp3_2);
tmpMeta[4] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
_cr = tmpMeta[1];
_t = tmpMeta[2];
_expl_1 = tmpMeta[6];
_ssl = tmpMeta[4];
tmp3 += 2;
_subs = omc_List_map(threadData, _expl_1, boxvar_Expression_makeIndexSubscript);
_crefs = omc_List_map1r(threadData, omc_List_map(threadData, _subs, boxvar_List_create), boxvar_ComponentReference_subscriptCref, _cr);
_t = omc_Types_unliftArray(threadData, _t);
_expl = omc_List_map1(threadData, _crefs, boxvar_Expression_makeCrefExp, _t);
_dim = listLength(_expl);
tmpMeta[2] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _t, tmpMeta[1]);
tmpMeta[4] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta[3], mmc_mk_boolean(1), _expl);
tmpMeta[0] = omc_ExpressionSimplify_simplifyCref2(threadData, tmpMeta[4], _ssl);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmp3_2);
tmpMeta[4] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],18,4) == 0) goto tmp2_end;
_cr = tmpMeta[1];
_t = tmpMeta[2];
_ss = tmpMeta[3];
_ssl = tmpMeta[4];
tmp3 += 1;
_subs = omc_Expression_expandSliceExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ss), 2))));
{
modelica_metatype __omcQ_24tmpVar23;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar22;
int tmp6;
modelica_metatype _s_loopVar = 0;
modelica_metatype _s;
_s_loopVar = _subs;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar23 = tmpMeta[2];
tmp5 = &__omcQ_24tmpVar23;
while(1) {
tmp6 = 1;
if (!listEmpty(_s_loopVar)) {
_s = MMC_CAR(_s_loopVar);
_s_loopVar = MMC_CDR(_s_loopVar);
tmp6--;
}
if (tmp6 == 0) {
__omcQ_24tmpVar22 = omc_ComponentReference_subscriptCref(threadData, _cr, omc_List_create(threadData, _s));
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar22,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar23;
}
_crefs = tmpMeta[1];
_t = omc_Types_unliftArray(threadData, _t);
{
modelica_metatype __omcQ_24tmpVar25;
modelica_metatype* tmp7;
modelica_metatype __omcQ_24tmpVar24;
int tmp8;
modelica_metatype _cr_loopVar = 0;
modelica_metatype _cr;
_cr_loopVar = _crefs;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar25 = tmpMeta[2];
tmp7 = &__omcQ_24tmpVar25;
while(1) {
tmp8 = 1;
if (!listEmpty(_cr_loopVar)) {
_cr = MMC_CAR(_cr_loopVar);
_cr_loopVar = MMC_CDR(_cr_loopVar);
tmp8--;
}
if (tmp8 == 0) {
__omcQ_24tmpVar24 = omc_Expression_makeCrefExp(threadData, _cr, _t);
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar24,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp8 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp7 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar25;
}
_expl = tmpMeta[1];
_dim = listLength(_expl);
tmpMeta[2] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _t, tmpMeta[1]);
tmpMeta[4] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta[3], mmc_mk_boolean(1), _expl);
_exp = tmpMeta[4];
tmpMeta[0] = omc_ExpressionSimplify_simplifyCref2(threadData, _exp, _ssl);
goto tmp2_done;
}
case 3: {
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp9 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_tp = tmpMeta[1];
_sc = tmp9;
_expl = tmpMeta[3];
_ssl = tmp3_2;
_expl = omc_List_map1(threadData, _expl, boxvar_ExpressionSimplify_simplifyCref2, _ssl);
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(_sc), _expl);
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCref(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inCREF, modelica_metatype _inType)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inCREF;
{
modelica_metatype _t2 = NULL;
modelica_metatype _ssl = NULL;
modelica_metatype _cr = NULL;
modelica_string _idn = NULL;
modelica_metatype _expCref = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],16,3) == 0) goto tmp2_end;
_idn = tmpMeta[1];
_t2 = tmpMeta[2];
_ssl = tmpMeta[3];
tmp3 += 2;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_cr = omc_ComponentReference_makeCrefIdent(threadData, _idn, _t2, tmpMeta[1]);
_expCref = omc_Expression_makeCrefExp(threadData, _cr, _inType);
tmpMeta[0] = omc_ExpressionSimplify_simplifyCref2(threadData, _expCref, _ssl);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],18,4) == 0) goto tmp2_end;
tmp3 += 1;
_cr = omc_ComponentReference_crefStripSubs(threadData, _inCREF);
_expCref = omc_Expression_makeCrefExp(threadData, _cr, _inType);
tmpMeta[0] = omc_ExpressionSimplify_simplifyCref2(threadData, _expCref, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inCREF), 4))));
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],25,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_idn = tmpMeta[1];
_t2 = tmpMeta[3];
_ssl = tmpMeta[4];
_cr = tmpMeta[5];
_exp = omc_ExpressionSimplify_simplifyCrefMM1(threadData, _idn, _t2, _ssl);
tmpMeta[0] = omc_ExpressionSimplify_simplifyCrefMM(threadData, _exp, omc_Expression_typeof(threadData, _exp), _cr);
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _origExp;
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
_exp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBuiltinConstantCalls(threadData_t *threadData, modelica_string _name, modelica_metatype _exp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_string tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _name;
tmp3_2 = _exp;
{
modelica_real _r;
modelica_real _v1;
modelica_real _v2;
modelica_integer _i;
modelica_integer _j;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 23; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT61), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_e = tmpMeta[2];
tmp3 += 22;
tmpMeta[0] = omc_ExpressionSimplify_simplifyBuiltinConstantDer(threadData, _e);
goto tmp2_done;
}
case 1: {
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT62), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_e = tmpMeta[2];
tmp3 += 21;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 2: {
if (8 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT63), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_e = tmpMeta[2];
tmp3 += 20;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 3: {
if (4 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT64), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
tmp3 += 19;
tmpMeta[0] = _OMC_LIT22;
goto tmp2_done;
}
case 4: {
if (6 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT65), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
tmp3 += 18;
tmpMeta[0] = _OMC_LIT22;
goto tmp2_done;
}
case 5: {
modelica_real tmp5;
if (4 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_e = tmpMeta[2];
tmp3 += 17;
tmp5 = omc_Expression_toReal(threadData, _e);
if(!(tmp5 >= 0.0))
{
FILE_INFO info = {"",0,0,0,0,0};
omc_assert(threadData, info, "Model error: Argument of sqrt(Expression.toReal(e)) was %g should be >= 0", tmp5);
}
_r = sqrt(tmp5);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
modelica_real tmp6;
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp6 = mmc_unbox_real(tmpMeta[4]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_r = tmp6;
tmp3 += 16;
_r = fabs(_r);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 7: {
modelica_integer tmp7;
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp7 = mmc_unbox_integer(tmpMeta[4]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_i = tmp7;
tmp3 += 15;
_i = labs(_i);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 8: {
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_e = tmpMeta[2];
tmp3 += 14;
_r = sin(omc_Expression_toReal(threadData, _e));
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 9: {
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_e = tmpMeta[2];
tmp3 += 13;
_r = cos(omc_Expression_toReal(threadData, _e));
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 10: {
modelica_boolean tmp8;
modelica_real tmp9;
if (4 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT66), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_e = tmpMeta[2];
tmp3 += 12;
_r = omc_Expression_toReal(threadData, _e);
tmp8 = ((_r >= -1.0) && (_r <= 1.0));
if (1 != tmp8) goto goto_1;
tmp9 = _r;
if(!(tmp9 >= -1.0 && tmp9 <= 1.0))
{
FILE_INFO info = {"",0,0,0,0,0};
omc_assert(threadData, info, "Model error: Argument of asin(r) outside the domain -1.0 <= %g <= 1.0", tmp9);
}
_r = asin(tmp9);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 11: {
modelica_boolean tmp10;
modelica_real tmp11;
if (4 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT67), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_e = tmpMeta[2];
tmp3 += 11;
_r = omc_Expression_toReal(threadData, _e);
tmp10 = ((_r >= -1.0) && (_r <= 1.0));
if (1 != tmp10) goto goto_1;
tmp11 = omc_Expression_toReal(threadData, _e);
if(!(tmp11 >= -1.0 && tmp11 <= 1.0))
{
FILE_INFO info = {"",0,0,0,0,0};
omc_assert(threadData, info, "Model error: Argument of acos(Expression.toReal(e)) outside the domain -1.0 <= %g <= 1.0", tmp11);
}
_r = acos(tmp11);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 12: {
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT37), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_e = tmpMeta[2];
tmp3 += 10;
_r = tan(omc_Expression_toReal(threadData, _e));
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 13: {
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_e = tmpMeta[2];
tmp3 += 9;
_r = exp(omc_Expression_toReal(threadData, _e));
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 14: {
modelica_boolean tmp12;
modelica_real tmp13;
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_e = tmpMeta[2];
tmp3 += 8;
_r = omc_Expression_toReal(threadData, _e);
tmp12 = (_r > 0.0);
if (1 != tmp12) goto goto_1;
tmp13 = _r;
if(!(tmp13 > 0.0))
{
FILE_INFO info = {"",0,0,0,0,0};
omc_assert(threadData, info, "Model error: Argument of log(r) was %g should be > 0", tmp13);
}
_r = log(tmp13);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 15: {
modelica_boolean tmp14;
modelica_real tmp15;
if (5 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT69), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_e = tmpMeta[2];
tmp3 += 7;
_r = omc_Expression_toReal(threadData, _e);
tmp14 = (_r > 0.0);
if (1 != tmp14) goto goto_1;
tmp15 = _r;
if(!(tmp15 > 0.0))
{
FILE_INFO info = {"",0,0,0,0,0};
omc_assert(threadData, info, "Model error: Argument of log10(r) was %g should be > 0", tmp15);
}
_r = log10(tmp15);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 16: {
modelica_integer tmp16;
modelica_integer tmp17;
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp16 = mmc_unbox_integer(tmpMeta[4]);
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[3]);
tmpMeta[6] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmp17 = mmc_unbox_integer(tmpMeta[7]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_i = tmp16;
_j = tmp17;
_i = modelica_integer_min((modelica_integer)(_i),(modelica_integer)(_j));
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 17: {
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
_e = tmpMeta[2];
_e1 = tmpMeta[4];
_v1 = omc_Expression_toReal(threadData, _e);
_v2 = omc_Expression_toReal(threadData, _e1);
_r = fmin(_v1,_v2);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 18: {
modelica_integer tmp18;
modelica_integer tmp19;
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp18 = mmc_unbox_integer(tmpMeta[4]);
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[3]);
tmpMeta[6] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],5,2) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
tmp19 = mmc_unbox_integer(tmpMeta[7]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_e = tmpMeta[2];
_i = tmp18;
_e1 = tmpMeta[5];
_j = tmp19;
tmp3 += 4;
tmpMeta[0] = ((_i < _j)?_e:_e1);
goto tmp2_done;
}
case 19: {
modelica_integer tmp20;
modelica_integer tmp21;
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp20 = mmc_unbox_integer(tmpMeta[4]);
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[3]);
tmpMeta[6] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmp21 = mmc_unbox_integer(tmpMeta[7]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_i = tmp20;
_j = tmp21;
_i = modelica_integer_max((modelica_integer)(_i),(modelica_integer)(_j));
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 20: {
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
_e = tmpMeta[2];
_e1 = tmpMeta[4];
_v1 = omc_Expression_toReal(threadData, _e);
_v2 = omc_Expression_toReal(threadData, _e1);
_r = fmax(_v1,_v2);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 21: {
modelica_integer tmp22;
modelica_integer tmp23;
if (3 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp22 = mmc_unbox_integer(tmpMeta[4]);
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[3]);
tmpMeta[6] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],5,2) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
tmp23 = mmc_unbox_integer(tmpMeta[7]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_e = tmpMeta[2];
_i = tmp22;
_e1 = tmpMeta[5];
_j = tmp23;
tmp3 += 1;
tmpMeta[0] = ((_i > _j)?_e:_e1);
goto tmp2_done;
}
case 22: {
modelica_real tmp24;
if (4 != MMC_STRLEN(tmp3_1) || strcmp(MMC_STRINGDATA(_OMC_LIT43), MMC_STRINGDATA(tmp3_1)) != 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp24 = mmc_unbox_real(tmpMeta[4]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_r = tmp24;
_i = ((_r == 0.0)?((modelica_integer) 0):((_r > 0.0)?((modelica_integer) 1):((modelica_integer) -1)));
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
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
if (++tmp3 < 23) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyStringAppendList(threadData_t *threadData, modelica_metatype _iexpl, modelica_metatype _iacc, modelica_boolean _ichange)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_boolean tmp3_3;
tmp3_1 = _iexpl;
tmp3_2 = _iacc;
tmp3_3 = _ichange;
{
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_string _s = NULL;
modelica_metatype _exp1 = NULL;
modelica_metatype _exp2 = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _acc = NULL;
modelica_boolean _change;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 6; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
if (!listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[0] = _OMC_LIT71;
goto tmp2_done;
}
case 1: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (!listEmpty(tmpMeta[2])) goto tmp2_end;
_exp = tmpMeta[1];
tmpMeta[0] = _exp;
goto tmp2_done;
}
case 2: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
_exp1 = tmpMeta[1];
_exp2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _exp2, _OMC_LIT73, _exp1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
if (1 != tmp3_3) goto tmp2_end;
if (!listEmpty(tmp3_1)) goto tmp2_end;
_acc = tmp3_2;
_acc = listReverse(_acc);
tmpMeta[1] = mmc_mk_box2(31, &DAE_Exp_LIST__desc, _acc);
_exp = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT74, tmpMeta[1], _OMC_LIT72);
goto tmp2_done;
}
case 4: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmp3_2);
tmpMeta[5] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],2,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
_s1 = tmpMeta[3];
_rest = tmpMeta[2];
_s2 = tmpMeta[6];
_acc = tmpMeta[5];
tmpMeta[1] = stringAppend(_s2,_s1);
_s = tmpMeta[1];
tmpMeta[2] = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _s);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _acc);
_iexpl = _rest;
_iacc = tmpMeta[1];
_ichange = 1;
goto _tailrecursive;
goto tmp2_done;
}
case 5: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_exp = tmpMeta[1];
_rest = tmpMeta[2];
_acc = tmp3_2;
_change = tmp3_3;
tmpMeta[1] = mmc_mk_cons(_exp, _acc);
_iexpl = _rest;
_iacc = tmpMeta[1];
_ichange = _change;
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
_exp = tmpMeta[0];
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
modelica_boolean tmp1;
modelica_string tmp2;
modelica_boolean tmp3;
modelica_string tmp4;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp3 = (modelica_boolean)(_stringLength >= _minLength);
if(tmp3)
{
tmp4 = _inString;
}
else
{
tmp1 = (modelica_boolean)_leftJustified;
if(tmp1)
{
tmpMeta[0] = stringAppend(_inString,stringAppendList(omc_List_fill(threadData, _OMC_LIT75, _minLength - _stringLength)));
tmp2 = tmpMeta[0];
}
else
{
tmpMeta[1] = stringAppend(stringAppendList(omc_List_fill(threadData, _OMC_LIT75, _minLength - _stringLength)),_inString);
tmp2 = tmpMeta[1];
}
tmp4 = tmp2;
}
_outString = tmp4;
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
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _exp;
tmp3_2 = _len_exp;
tmp3_3 = _just_exp;
{
modelica_integer _i;
modelica_integer _len;
modelica_real _r;
modelica_boolean _b;
modelica_boolean _just;
modelica_string _str = NULL;
modelica_metatype _name = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_integer tmp4;
modelica_integer tmp5;
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp4 = mmc_unbox_integer(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,3,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp6 = mmc_unbox_integer(tmpMeta[3]);
_i = tmp4;
_len = tmp5;
_just = tmp6;
_str = intString(_i);
_str = omc_ExpressionSimplify_cevalBuiltinStringFormat(threadData, _str, stringLength(_str), _len, _just);
tmpMeta[1] = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _str);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
modelica_real tmp7;
modelica_integer tmp8;
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp7 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp8 = mmc_unbox_integer(tmpMeta[2]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,3,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp9 = mmc_unbox_integer(tmpMeta[3]);
_r = tmp7;
_len = tmp8;
_just = tmp9;
_str = realString(_r);
_str = omc_ExpressionSimplify_cevalBuiltinStringFormat(threadData, _str, stringLength(_str), _len, _just);
tmpMeta[1] = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _str);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
modelica_integer tmp10;
modelica_integer tmp11;
modelica_integer tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp10 = mmc_unbox_integer(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp11 = mmc_unbox_integer(tmpMeta[2]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,3,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp12 = mmc_unbox_integer(tmpMeta[3]);
_b = tmp10;
_len = tmp11;
_just = tmp12;
_str = (_b?_OMC_LIT76:_OMC_LIT77);
_str = omc_ExpressionSimplify_cevalBuiltinStringFormat(threadData, _str, stringLength(_str), _len, _just);
tmpMeta[1] = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _str);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 8: {
modelica_integer tmp13;
modelica_integer tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp13 = mmc_unbox_integer(tmpMeta[2]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,3,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp14 = mmc_unbox_integer(tmpMeta[3]);
_name = tmpMeta[1];
_len = tmp13;
_just = tmp14;
_str = omc_AbsynUtil_pathLastIdent(threadData, _name);
_str = omc_ExpressionSimplify_cevalBuiltinStringFormat(threadData, _str, stringLength(_str), _len, _just);
tmpMeta[1] = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _str);
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_evalCatGetFlatArray(threadData_t *threadData, modelica_metatype _e, modelica_integer _dim, modelica_fnptr _getArrayContents, modelica_fnptr _toString, modelica_metatype *out_outDims)
{
modelica_metatype _outExps = NULL;
modelica_metatype _outDims = NULL;
modelica_metatype _arr = NULL;
modelica_metatype _dims = NULL;
modelica_integer _i;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outExps = tmpMeta[0];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_outDims = tmpMeta[1];
if((_dim == ((modelica_integer) 1)))
{
_outExps = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 1)))) (threadData, _e);
tmpMeta[2] = mmc_mk_cons(mmc_mk_integer(listLength(_outExps)), MMC_REFSTRUCTLIT(mmc_nil));
_outDims = tmpMeta[2];
goto _return;
}
_i = ((modelica_integer) 0);
{
modelica_metatype _exp;
for (tmpMeta[2] = listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 1)))) (threadData, _e)); !listEmpty(tmpMeta[2]); tmpMeta[2]=MMC_CDR(tmpMeta[2]))
{
_exp = MMC_CAR(tmpMeta[2]);
_arr = omc_ExpressionSimplify_evalCatGetFlatArray(threadData, _exp, ((modelica_integer) -1) + _dim, ((modelica_fnptr) _getArrayContents), ((modelica_fnptr) _toString) ,&_dims);
if(listEmpty(_outDims))
{
_outDims = _dims;
}
else
{
if((!valueEq(_dims, _outDims)))
{
tmpMeta[3] = stringAppend(_OMC_LIT78,(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 1)))) (threadData, _e));
omc_Error_assertion(threadData, 0, tmpMeta[3], _OMC_LIT80);
}
}
_outExps = listAppend(_arr, _outExps);
_i = ((modelica_integer) 1) + _i;
}
}
tmpMeta[2] = mmc_mk_cons(mmc_mk_integer(_i), _outDims);
_outDims = tmpMeta[2];
_return: OMC_LABEL_UNUSED
if (out_outDims) { *out_outDims = _outDims; }
return _outExps;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ExpressionSimplify_evalCatGetFlatArray(threadData_t *threadData, modelica_metatype _e, modelica_metatype _dim, modelica_fnptr _getArrayContents, modelica_fnptr _toString, modelica_metatype *out_outDims)
{
modelica_integer tmp1;
modelica_metatype _outExps = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
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
modelica_metatype _dims = NULL;
modelica_metatype _firstDims = NULL;
modelica_metatype _lastDims = NULL;
modelica_metatype _reverseDims = NULL;
modelica_metatype _dimsLst = NULL;
modelica_integer _j;
modelica_integer _k;
modelica_integer _l;
modelica_integer _thisDim;
modelica_integer _lastDim;
modelica_metatype _expArr = NULL;
modelica_boolean tmp1;
modelica_boolean tmp2;
modelica_integer tmp4;
modelica_integer tmp6;
modelica_string tmp8;
modelica_integer tmp13;
modelica_integer tmp14;
modelica_integer tmp15;
modelica_integer tmp18;
modelica_integer tmp20;
modelica_integer tmp22;
modelica_integer tmp23;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_arrs = tmpMeta[0];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_firstDims = tmpMeta[1];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_dimsLst = tmpMeta[2];
tmp1 = (_dim >= ((modelica_integer) 1));
if (1 != tmp1) MMC_THROW_INTERNAL();
tmp2 = listEmpty(_exps);
if (0 != tmp2) MMC_THROW_INTERNAL();
if((((modelica_integer) 1) == _dim))
{
{
modelica_metatype __omcQ_24tmpVar27;
modelica_metatype __omcQ_24tmpVar26;
int tmp3;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = listReverse(_exps);
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar27 = tmpMeta[4];
while(1) {
tmp3 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp3--;
}
if (tmp3 == 0) {
__omcQ_24tmpVar26 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_getArrayContents), 1)))) (threadData, _e);
__omcQ_24tmpVar27 = listAppend(__omcQ_24tmpVar26, __omcQ_24tmpVar27);
} else if (tmp3 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmpMeta[3] = __omcQ_24tmpVar27;
}
_outExps = tmpMeta[3];
tmpMeta[3] = mmc_mk_cons(mmc_mk_integer(listLength(_outExps)), MMC_REFSTRUCTLIT(mmc_nil));
_outDims = tmpMeta[3];
goto _return;
}
{
modelica_metatype _e;
for (tmpMeta[3] = listReverse(_exps); !listEmpty(tmpMeta[3]); tmpMeta[3]=MMC_CDR(tmpMeta[3]))
{
_e = MMC_CAR(tmpMeta[3]);
_arr = omc_ExpressionSimplify_evalCatGetFlatArray(threadData, _e, _dim, ((modelica_fnptr) _getArrayContents), ((modelica_fnptr) _toString) ,&_dims);
tmpMeta[4] = mmc_mk_cons(_arr, _arrs);
_arrs = tmpMeta[4];
tmpMeta[4] = mmc_mk_cons(_dims, _dimsLst);
_dimsLst = tmpMeta[4];
}
}
tmp13 = ((modelica_integer) 1); tmp14 = 1; tmp15 = ((modelica_integer) -1) + _dim;
if(!(((tmp14 > 0) && (tmp13 > tmp15)) || ((tmp14 < 0) && (tmp13 < tmp15))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp13, tmp15); _i += tmp14)
{
{
modelica_integer __omcQ_24tmpVar29;
modelica_integer __omcQ_24tmpVar28;
int tmp5;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _dimsLst;
__omcQ_24tmpVar29 = ((modelica_integer) 4611686018427387903);
while(1) {
tmp5 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp5--;
}
if (tmp5 == 0) {
__omcQ_24tmpVar28 = mmc_unbox_integer(listHead(_d));
__omcQ_24tmpVar29 = modelica_integer_min((modelica_integer)(__omcQ_24tmpVar28),(modelica_integer)(__omcQ_24tmpVar29));
} else if (tmp5 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp4 = __omcQ_24tmpVar29;
}
_j = tmp4;
{
modelica_integer __omcQ_24tmpVar31;
modelica_integer __omcQ_24tmpVar30;
int tmp7;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _dimsLst;
__omcQ_24tmpVar31 = ((modelica_integer) -4611686018427387903);
while(1) {
tmp7 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp7--;
}
if (tmp7 == 0) {
__omcQ_24tmpVar30 = mmc_unbox_integer(listHead(_d));
__omcQ_24tmpVar31 = modelica_integer_max((modelica_integer)(__omcQ_24tmpVar30),(modelica_integer)(__omcQ_24tmpVar31));
} else if (tmp7 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp6 = __omcQ_24tmpVar31;
}
if((_j != tmp6))
{
tmp8 = modelica_integer_to_modelica_string(_i, ((modelica_integer) 0), 1);
tmpMeta[3] = stringAppend(_OMC_LIT81,tmp8);
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT75);
{
modelica_metatype __omcQ_24tmpVar33;
modelica_metatype* tmp9;
modelica_string __omcQ_24tmpVar32;
int tmp10;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = _exps;
tmpMeta[6] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar33 = tmpMeta[6];
tmp9 = &__omcQ_24tmpVar33;
while(1) {
tmp10 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp10--;
}
if (tmp10 == 0) {
__omcQ_24tmpVar32 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_toString), 1)))) (threadData, _e);
*tmp9 = mmc_mk_cons(__omcQ_24tmpVar32,0);
tmp9 = &MMC_CDR(*tmp9);
} else if (tmp10 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp9 = mmc_mk_nil();
tmpMeta[5] = __omcQ_24tmpVar33;
}
tmpMeta[7] = stringAppend(tmpMeta[4],stringDelimitList(tmpMeta[5], _OMC_LIT82));
omc_Error_assertion(threadData, 0, tmpMeta[7], _OMC_LIT83);
}
tmpMeta[3] = mmc_mk_cons(mmc_mk_integer(_j), _firstDims);
_firstDims = tmpMeta[3];
{
modelica_metatype __omcQ_24tmpVar35;
modelica_metatype* tmp11;
modelica_metatype __omcQ_24tmpVar34;
int tmp12;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _dimsLst;
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar35 = tmpMeta[4];
tmp11 = &__omcQ_24tmpVar35;
while(1) {
tmp12 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp12--;
}
if (tmp12 == 0) {
__omcQ_24tmpVar34 = listRest(_d);
*tmp11 = mmc_mk_cons(__omcQ_24tmpVar34,0);
tmp11 = &MMC_CDR(*tmp11);
} else if (tmp12 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp11 = mmc_mk_nil();
tmpMeta[3] = __omcQ_24tmpVar35;
}
_dimsLst = tmpMeta[3];
}
}
_reverseDims = _firstDims;
_firstDims = listReverse(_firstDims);
{
modelica_metatype __omcQ_24tmpVar37;
modelica_metatype* tmp16;
modelica_metatype __omcQ_24tmpVar36;
int tmp17;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _dimsLst;
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar37 = tmpMeta[4];
tmp16 = &__omcQ_24tmpVar37;
while(1) {
tmp17 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp17--;
}
if (tmp17 == 0) {
__omcQ_24tmpVar36 = listHead(_d);
*tmp16 = mmc_mk_cons(__omcQ_24tmpVar36,0);
tmp16 = &MMC_CDR(*tmp16);
} else if (tmp17 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
*tmp16 = mmc_mk_nil();
tmpMeta[3] = __omcQ_24tmpVar37;
}
_lastDims = tmpMeta[3];
{
modelica_integer __omcQ_24tmpVar39;
modelica_integer __omcQ_24tmpVar38;
int tmp19;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _lastDims;
__omcQ_24tmpVar39 = ((modelica_integer) 0);
while(1) {
tmp19 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp19--;
}
if (tmp19 == 0) {
__omcQ_24tmpVar38 = mmc_unbox_integer(_d);
__omcQ_24tmpVar39 = __omcQ_24tmpVar39 + __omcQ_24tmpVar38;
} else if (tmp19 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp18 = __omcQ_24tmpVar39;
}
_lastDim = tmp18;
tmpMeta[3] = mmc_mk_cons(mmc_mk_integer(_lastDim), _reverseDims);
_reverseDims = tmpMeta[3];
{
modelica_integer __omcQ_24tmpVar41;
modelica_integer __omcQ_24tmpVar40;
int tmp21;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _firstDims;
__omcQ_24tmpVar41 = ((modelica_integer) 1);
while(1) {
tmp21 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp21--;
}
if (tmp21 == 0) {
__omcQ_24tmpVar40 = mmc_unbox_integer(_d);
__omcQ_24tmpVar41 = (__omcQ_24tmpVar41) * (__omcQ_24tmpVar40);
} else if (tmp21 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp20 = __omcQ_24tmpVar41;
}
_expArr = arrayCreate((_lastDim) * (tmp20), listHead(listHead(_arrs)));
_k = ((modelica_integer) 1);
{
modelica_metatype _exps;
for (tmpMeta[3] = _arrs; !listEmpty(tmpMeta[3]); tmpMeta[3]=MMC_CDR(tmpMeta[3]))
{
_exps = MMC_CAR(tmpMeta[3]);
tmpMeta[4] = _lastDims;
if (listEmpty(tmpMeta[4])) MMC_THROW_INTERNAL();
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
tmp22 = mmc_unbox_integer(tmpMeta[5]);
_thisDim = tmp22;
_lastDims = tmpMeta[6];
_l = ((modelica_integer) 0);
{
modelica_metatype _e;
for (tmpMeta[4] = _exps; !listEmpty(tmpMeta[4]); tmpMeta[4]=MMC_CDR(tmpMeta[4]))
{
_e = MMC_CAR(tmpMeta[4]);
tmp23 = _thisDim;
if (tmp23 == 0) {MMC_THROW_INTERNAL();}
arrayUpdate(_expArr, _k + modelica_integer_mod(_l, _thisDim) + (_lastDim) * (ldiv(_l,tmp23).quot), _e);
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
modelica_metatype tmpMeta[21] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_integer tmp3_1;volatile modelica_metatype tmp3_2;volatile modelica_boolean tmp3_3;
tmp3_1 = _dim;
tmp3_2 = _ies;
tmp3_3 = _changed;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (1 != tmp3_3) goto tmp2_end;
if (!listEmpty(tmp3_2)) goto tmp2_end;
tmp3 += 3;
tmpMeta[0] = listReverse(_acc);
goto tmp2_done;
}
case 1: {
modelica_integer tmp5;
if (1 != tmp3_1) goto tmp2_end;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],16,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],6,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmp5 = mmc_unbox_integer(tmpMeta[8]);
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[2]);
tmpMeta[11] = MMC_CDR(tmpMeta[2]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[10],16,3) == 0) goto tmp2_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[12],6,2) == 0) goto tmp2_end;
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 3));
if (listEmpty(tmpMeta[13])) goto tmp2_end;
tmpMeta[14] = MMC_CAR(tmpMeta[13]);
tmpMeta[15] = MMC_CDR(tmpMeta[13]);
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 4));
_etp = tmpMeta[4];
_dim1 = tmpMeta[6];
_dims = tmpMeta[7];
_sc = tmp5;
_es1 = tmpMeta[9];
_dim2 = tmpMeta[14];
_es2 = tmpMeta[16];
_es = tmpMeta[11];
tmp3 += 1;
_esn = listAppend(_es1, _es2);
_ndim = omc_Expression_addDimensions(threadData, _dim1, _dim2);
tmpMeta[1] = mmc_mk_cons(_ndim, _dims);
tmpMeta[2] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _etp, tmpMeta[1]);
_etp = tmpMeta[2];
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _etp, mmc_mk_boolean(_sc), _esn);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_e, _es);
tmpMeta[0] = omc_ExpressionSimplify_simplifyCat2(threadData, _dim, tmpMeta[1], _acc, 1);
goto tmp2_done;
}
case 2: {
modelica_integer tmp6;
if (2 != tmp3_1) goto tmp2_end;
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],17,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],6,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[8] = MMC_CAR(tmpMeta[7]);
tmpMeta[9] = MMC_CDR(tmpMeta[7]);
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmp6 = mmc_unbox_integer(tmpMeta[10]);
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[12] = MMC_CAR(tmpMeta[2]);
tmpMeta[13] = MMC_CDR(tmpMeta[2]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[12],17,3) == 0) goto tmp2_end;
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[14],6,2) == 0) goto tmp2_end;
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[14]), 3));
if (listEmpty(tmpMeta[15])) goto tmp2_end;
tmpMeta[16] = MMC_CAR(tmpMeta[15]);
tmpMeta[17] = MMC_CDR(tmpMeta[15]);
if (listEmpty(tmpMeta[17])) goto tmp2_end;
tmpMeta[18] = MMC_CAR(tmpMeta[17]);
tmpMeta[19] = MMC_CDR(tmpMeta[17]);
tmpMeta[20] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 4));
_etp = tmpMeta[4];
_dim11 = tmpMeta[6];
_dim1 = tmpMeta[8];
_dims = tmpMeta[9];
_i = tmp6;
_ms1 = tmpMeta[11];
_dim2 = tmpMeta[18];
_ms2 = tmpMeta[20];
_es = tmpMeta[13];
_mss = omc_List_threadMap(threadData, _ms1, _ms2, boxvar_listAppend);
_ndim = omc_Expression_addDimensions(threadData, _dim1, _dim2);
tmpMeta[2] = mmc_mk_cons(_ndim, _dims);
tmpMeta[1] = mmc_mk_cons(_dim11, tmpMeta[2]);
tmpMeta[3] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _etp, tmpMeta[1]);
_etp = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _etp, mmc_mk_integer(_i), _mss);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_e, _es);
tmpMeta[0] = omc_ExpressionSimplify_simplifyCat2(threadData, _dim, tmpMeta[1], _acc, 1);
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
_e = tmpMeta[1];
_es = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_e, _acc);
tmpMeta[0] = omc_ExpressionSimplify_simplifyCat2(threadData, _dim, _es, tmpMeta[1], _changed);
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
_oes = tmpMeta[0];
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _arg;
{
modelica_metatype _dim = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,3) == 0) goto tmp2_end;
tmpMeta[0] = omc_Expression_matrixToArray(threadData, _arg);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
_dim = tmpMeta[3];
if (!omc_Expression_dimensionKnown(threadData, _dim)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_arg), 3))), mmc_mk_boolean(1), omc_Expression_expandExpression(threadData, _arg, 0));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
tmpMeta[0] = _arg;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCat(threadData_t *threadData, modelica_integer _inDim, modelica_metatype _inExpList)
{
modelica_metatype _outExpList = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_integer tmp3_1;
tmp3_1 = _inDim;
{
modelica_metatype _expl = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (1 != tmp3_1) goto tmp2_end;
_expl = omc_List_map(threadData, _inExpList, boxvar_ExpressionSimplify_simplifyCatArg);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_ExpressionSimplify_simplifyCat2(threadData, _inDim, _expl, tmpMeta[1], 0);
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_ExpressionSimplify_simplifyCat2(threadData, _inDim, _inExpList, tmpMeta[1], 0);
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
_outExpList = tmpMeta[0];
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_cons(_inExp, mmc_mk_cons(_inCall, MMC_REFSTRUCTLIT(mmc_nil)));
_outCall = omc_Expression_makePureBuiltinCall(threadData, _inName, tmpMeta[0], _inType);
_return: OMC_LABEL_UNUSED
return _outCall;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyScalar(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _tp)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_exp = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT84, tmpMeta[1], _tp);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[2]);
tmpMeta[5] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_exp = tmpMeta[4];
tmpMeta[1] = mmc_mk_cons(_exp, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT84, tmpMeta[1], _tp);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,24,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (!optionNone(tmpMeta[2])) goto tmp2_end;
_exp = tmpMeta[1];
omc_Types_flattenArrayType(threadData, omc_Expression_typeof(threadData, _inExp), &tmpMeta[1]);
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto goto_1;
tmpMeta[1] = mmc_mk_box3(27, &DAE_Exp_SIZE__desc, _exp, _OMC_LIT86);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
omc_Types_flattenArrayType(threadData, omc_Expression_typeof(threadData, _inExp), &tmpMeta[1]);
if (!listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[0] = _inExp;
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
_exp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyBuiltinCalls(threadData_t *threadData, modelica_metatype _exp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[15] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _exp;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 57; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
_name = tmpMeta[2];
_e = tmpMeta[4];
_tp = tmpMeta[7];
if (!((stringEqual(_name, _OMC_LIT8)) || (stringEqual(_name, _OMC_LIT7)))) goto tmp2_end;
_expl = omc_Expression_flattenArrayExpToList(threadData, _e);
_e1 = omc_Expression_makeScalarArray(threadData, _expl, _tp);
tmp5 = omc_Expression_expEqual(threadData, _e, _e1);
if (0 != tmp5) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _name, tmpMeta[1], _tp);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_name = tmpMeta[2];
_expl = tmpMeta[6];
_e = tmpMeta[7];
if (!((stringEqual(_name, _OMC_LIT8)) || (stringEqual(_name, _OMC_LIT7)))) goto tmp2_end;
if(omc_Expression_isArrayType(threadData, omc_Expression_typeof(threadData, _e)))
{
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_exp), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[3] = _expl;
_exp = tmpMeta[1];
_e = _exp;
}
tmpMeta[0] = _e;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[7];
tmpMeta[0] = _e;
goto tmp2_done;
}
case 3: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
_es = tmpMeta[6];
_tp = tmpMeta[8];
tmp3 += 2;
_i1 = listLength(_es);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_es = omc_List_union(threadData, _es, tmpMeta[1]);
_i2 = listLength(_es);
if((_i1 == _i2))
{
tmpMeta[1] = omc_List_fold(threadData, _es, boxvar_ExpressionSimplify_maxElement, mmc_mk_none());
if (optionNone(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_e = tmpMeta[2];
_es = omc_List_select(threadData, _es, boxvar_ExpressionSimplify_removeMinMaxFoldableValues);
tmpMeta[1] = mmc_mk_cons(_e, _es);
_es = tmpMeta[1];
_i2 = listLength(_es);
tmp6 = (_i2 < _i1);
if (1 != tmp6) goto goto_1;
_e = omc_Expression_makeScalarArray(threadData, _es, _tp);
}
else
{
_e = omc_Expression_makeScalarArray(threadData, _es, _tp);
}
tmpMeta[1] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT8, tmpMeta[1], _tp);
goto tmp2_done;
}
case 4: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
_es = tmpMeta[6];
_tp = tmpMeta[8];
_i1 = listLength(_es);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_es = omc_List_union(threadData, _es, tmpMeta[1]);
_i2 = listLength(_es);
if((_i1 == _i2))
{
tmpMeta[1] = omc_List_fold(threadData, _es, boxvar_ExpressionSimplify_minElement, mmc_mk_none());
if (optionNone(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_e = tmpMeta[2];
_es = omc_List_select(threadData, _es, boxvar_ExpressionSimplify_removeMinMaxFoldableValues);
tmpMeta[1] = mmc_mk_cons(_e, _es);
_es = tmpMeta[1];
_i2 = listLength(_es);
tmp7 = (_i2 < _i1);
if (1 != tmp7) goto goto_1;
_e = omc_Expression_makeScalarArray(threadData, _es, _tp);
}
else
{
_e = omc_Expression_makeScalarArray(threadData, _es, _tp);
}
tmpMeta[1] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT7, tmpMeta[1], _tp);
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 2));
_e1 = tmpMeta[7];
_e2 = tmpMeta[9];
_tp = tmpMeta[12];
tmp3 += 3;
tmpMeta[1] = mmc_mk_cons(_e1, mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT7, tmpMeta[1], _tp);
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 2));
_e1 = tmpMeta[7];
_e2 = tmpMeta[9];
_tp = tmpMeta[12];
tmp3 += 3;
tmpMeta[1] = mmc_mk_cons(_e1, mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT8, tmpMeta[1], _tp);
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],3,1) == 0) goto tmp2_end;
_e1 = tmpMeta[4];
_e2 = tmpMeta[6];
tmp3 += 49;
tmpMeta[1] = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _e1, _OMC_LIT88, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],3,1) == 0) goto tmp2_end;
_e1 = tmpMeta[4];
_e2 = tmpMeta[6];
tmp3 += 48;
tmpMeta[1] = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _e1, _OMC_LIT89, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT7), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],3,1) == 0) goto tmp2_end;
_expl = tmpMeta[6];
tmp3 += 1;
tmpMeta[0] = omc_Expression_makeLBinary(threadData, _expl, _OMC_LIT88);
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT8), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],3,1) == 0) goto tmp2_end;
_expl = tmpMeta[6];
tmpMeta[0] = omc_Expression_makeLBinary(threadData, _expl, _OMC_LIT89);
goto tmp2_done;
}
case 11: {
modelica_boolean tmp8;
modelica_boolean tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 2));
_name = tmpMeta[2];
_expl = tmpMeta[6];
_tp = tmpMeta[12];
tmp8 = omc_Config_scalarizeMinMax(threadData);
if (1 != tmp8) goto goto_1;
tmp9 = ((stringEqual(_name, _OMC_LIT8)) || (stringEqual(_name, _OMC_LIT7)));
if (1 != tmp9) goto goto_1;
tmpMeta[1] = listReverse(_expl);
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (listEmpty(tmpMeta[3])) goto goto_1;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
_e1 = tmpMeta[2];
_e2 = tmpMeta[4];
_expl = tmpMeta[5];
tmpMeta[1] = mmc_mk_cons(_e2, mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil)));
_e1 = omc_Expression_makePureBuiltinCall(threadData, _name, tmpMeta[1], _tp);
tmpMeta[0] = omc_List_fold2(threadData, _expl, boxvar_ExpressionSimplify_makeNestedReduction, _name, _tp, _e1);
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (5 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT109), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_e = tmp3_1;
_expl = tmpMeta[3];
tmp3 += 44;
tmpMeta[1] = _expl;
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],16,3) == 0) goto goto_1;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
if (listEmpty(tmpMeta[3])) goto goto_1;
tmpMeta[5] = MMC_CAR(tmpMeta[3]);
tmpMeta[6] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],16,3) == 0) goto goto_1;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 4));
if (!listEmpty(tmpMeta[6])) goto goto_1;
_v1 = tmpMeta[4];
_v2 = tmpMeta[7];
_expl = omc_ExpressionSimplify_simplifyCross(threadData, _v1, _v2);
_tp = omc_Expression_typeof(threadData, _e);
_scalar = (!omc_Expression_isArrayType(threadData, omc_Expression_unliftArray(threadData, _tp)));
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(_scalar), _expl);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (4 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT110), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmp3_1;
_v1 = tmpMeta[6];
tmp3 += 43;
_mexpl = omc_ExpressionSimplify_simplifySkew(threadData, _v1);
_tp = omc_Expression_typeof(threadData, _e);
tmpMeta[1] = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _tp, mmc_mk_integer(((modelica_integer) 3)), _mexpl);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (4 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT111), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
_e = tmpMeta[4];
_expl = tmpMeta[5];
tmp3 += 42;
_valueLst = omc_List_map(threadData, _expl, boxvar_ValuesUtil_expValue);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Static_elabBuiltinFill2(threadData, omc_FCore_noCache(threadData), omc_FGraph_empty(threadData), _e, omc_Expression_typeof(threadData, _e), _valueLst, _OMC_LIT90, _OMC_LIT91, tmpMeta[1], _OMC_LIT92 ,&_outExp ,NULL);
tmpMeta[0] = _outExp;
goto tmp2_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT112), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[8] = MMC_CAR(tmpMeta[7]);
tmpMeta[9] = MMC_CDR(tmpMeta[7]);
if (!listEmpty(tmpMeta[9])) goto tmp2_end;
_e = tmpMeta[4];
_len_exp = tmpMeta[6];
_just_exp = tmpMeta[8];
tmp3 += 41;
tmpMeta[0] = omc_ExpressionSimplify_simplifyBuiltinStringFormat(threadData, _e, _len_exp, _just_exp);
goto tmp2_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (16 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT74), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],28,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_expl = tmpMeta[6];
tmp3 += 40;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_ExpressionSimplify_simplifyStringAppendList(threadData, _expl, tmpMeta[1], 0);
goto tmp2_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (4 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],7,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],4,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],1,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e1 = tmpMeta[6];
_e2 = tmpMeta[9];
tmp3 += 39;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT33, _OMC_LIT34, _e2);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _OMC_LIT36, tmpMeta[1]);
_e = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT24, tmpMeta[1], _OMC_LIT30);
goto tmp2_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (4 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],13,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (4 != MMC_STRLEN(tmpMeta[7]) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta[7])) != 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e1 = tmpMeta[9];
tmp3 += 38;
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _OMC_LIT36, _OMC_LIT94);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 19: {
modelica_real tmp10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (4 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],7,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmp10 = mmc_unbox_real(tmpMeta[7]);
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],2,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e1 = tmpMeta[6];
_r1 = tmp10;
_tp = tmpMeta[9];
_e2 = tmpMeta[10];
tmp3 += 37;
tmp11 = (_r1 >= 0.0);
if (1 != tmp11) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
_e = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta[1], _OMC_LIT30);
tmpMeta[1] = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta[1], _OMC_LIT30);
tmpMeta[1] = mmc_mk_box2(5, &DAE_Operator_MUL__desc, _tp);
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, tmpMeta[1], _e3);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],8,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],5,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e1 = tmpMeta[7];
_expl = omc_Expression_expandFactors(threadData, _e1);
tmpMeta[2] = omc_List_split1OnTrue(threadData, _expl, boxvar_Expression_isFunCall, _OMC_LIT68, &tmpMeta[1]);
if (listEmpty(tmpMeta[2])) goto goto_1;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto goto_1;
_e2 = tmpMeta[3];
_es = tmpMeta[1];
tmpMeta[1] = _e2;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],13,3) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[2])) goto goto_1;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto goto_1;
_e = tmpMeta[3];
_e3 = omc_Expression_makeProductLst(threadData, _es);
tmpMeta[0] = omc_Expression_expPow(threadData, _e, omc_Expression_negate(threadData, _e3));
goto tmp2_done;
}
case 21: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e1 = tmpMeta[4];
tmp3 += 35;
_expl = omc_Expression_expandFactors(threadData, _e1);
tmpMeta[2] = omc_List_split1OnTrue(threadData, _expl, boxvar_Expression_isFunCall, _OMC_LIT68, &tmpMeta[1]);
if (listEmpty(tmpMeta[2])) goto goto_1;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto goto_1;
_e2 = tmpMeta[3];
_es = tmpMeta[1];
tmpMeta[1] = _e2;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],13,3) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[2])) goto goto_1;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto goto_1;
_e = tmpMeta[3];
_e3 = omc_Expression_makeProductLst(threadData, _es);
tmpMeta[0] = omc_Expression_expPow(threadData, _e, _e3);
goto tmp2_done;
}
case 22: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (3 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT25), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],4,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],1,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e = tmpMeta[5];
_e2 = tmpMeta[9];
tmp3 += 34;
_e3 = omc_Expression_expMul(threadData, _e, _e2);
tmpMeta[1] = mmc_mk_cons(_e3, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT25, tmpMeta[1], _OMC_LIT30);
goto tmp2_done;
}
case 23: {
modelica_real tmp12;
modelica_real tmp13;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],7,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],4,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],1,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],1,1) == 0) goto tmp2_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 2));
tmp12 = mmc_unbox_real(tmpMeta[10]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e1 = tmpMeta[6];
_r1 = tmp12;
tmp3 += 33;
tmp13 = modelica_real_mod(_r1, 2.0);
if (1.0 != tmp13) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT68, tmpMeta[1], _OMC_LIT30);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r1));
tmpMeta[0] = omc_Expression_expMul(threadData, tmpMeta[1], _e3);
goto tmp2_done;
}
case 24: {
modelica_real tmp14;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],7,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmp14 = mmc_unbox_real(tmpMeta[7]);
if (1.0 != tmp14) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],3,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],1,1) == 0) goto tmp2_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e2 = tmpMeta[10];
tmp3 += 32;
tmpMeta[1] = mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT68, tmpMeta[1], _OMC_LIT30);
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _OMC_LIT95, _e3);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 25: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT68), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],13,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (4 != MMC_STRLEN(tmpMeta[7]) || strcmp(MMC_STRINGDATA(_OMC_LIT35), MMC_STRINGDATA(tmpMeta[7])) != 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e1 = tmpMeta[9];
tmp3 += 31;
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
_e3 = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT68, tmpMeta[1], _OMC_LIT30);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT33, _OMC_LIT34, _e3);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 26: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT113), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e1 = tmpMeta[6];
tmp3 += 30;
if (!omc_Expression_isConst(threadData, _e1)) goto tmp2_end;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 27: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (8 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT114), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e1 = tmpMeta[4];
tmp3 += 29;
if (!omc_Expression_isConst(threadData, _e1)) goto tmp2_end;
tmpMeta[0] = omc_Expression_makeConstZeroE(threadData, _e1);
goto tmp2_done;
}
case 28: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (5 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT96), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e = tmp3_1;
_e1 = tmpMeta[4];
_e2 = tmpMeta[6];
tmp3 += 28;
tmpMeta[2] = mmc_mk_cons(_e1, mmc_mk_cons(_e2, mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil))));
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_e), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[3] = tmpMeta[2];
_e = tmpMeta[1];
tmpMeta[0] = _e;
goto tmp2_done;
}
case 29: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (5 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT96), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[8] = MMC_CAR(tmpMeta[7]);
tmpMeta[9] = MMC_CDR(tmpMeta[7]);
if (!listEmpty(tmpMeta[9])) goto tmp2_end;
_e1 = tmpMeta[4];
if (!omc_Expression_isConst(threadData, _e1)) goto tmp2_end;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 30: {
modelica_boolean tmp15;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (5 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT96), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],7,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[5]);
tmpMeta[10] = MMC_CDR(tmpMeta[5]);
if (listEmpty(tmpMeta[10])) goto tmp2_end;
tmpMeta[11] = MMC_CAR(tmpMeta[10]);
tmpMeta[12] = MMC_CDR(tmpMeta[10]);
if (!listEmpty(tmpMeta[12])) goto tmp2_end;
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[13]), 2));
_e1 = tmpMeta[6];
_op = tmpMeta[7];
_e2 = tmpMeta[8];
_e3 = tmpMeta[9];
_e4 = tmpMeta[11];
_tp = tmpMeta[14];
tmp15 = omc_Expression_isConst(threadData, _e1);
if (1 != tmp15) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_e2, mmc_mk_cons(_e3, mmc_mk_cons(_e4, MMC_REFSTRUCTLIT(mmc_nil))));
_e = omc_Expression_makeImpureBuiltinCall(threadData, _OMC_LIT96, tmpMeta[1], _tp);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1, _op, _e);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 31: {
modelica_boolean tmp16;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (5 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT96), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],7,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[5]);
tmpMeta[10] = MMC_CDR(tmpMeta[5]);
if (listEmpty(tmpMeta[10])) goto tmp2_end;
tmpMeta[11] = MMC_CAR(tmpMeta[10]);
tmpMeta[12] = MMC_CDR(tmpMeta[10]);
if (!listEmpty(tmpMeta[12])) goto tmp2_end;
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[13]), 2));
_e1 = tmpMeta[6];
_op = tmpMeta[7];
_e2 = tmpMeta[8];
_e3 = tmpMeta[9];
_e4 = tmpMeta[11];
_tp = tmpMeta[14];
tmp3 += 25;
tmp16 = omc_Expression_isConst(threadData, _e2);
if (1 != tmp16) goto goto_1;
tmpMeta[1] = mmc_mk_cons(_e1, mmc_mk_cons(_e3, mmc_mk_cons(_e4, MMC_REFSTRUCTLIT(mmc_nil))));
_e = omc_Expression_makeImpureBuiltinCall(threadData, _OMC_LIT96, tmpMeta[1], _tp);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _op, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 32: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (5 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT96), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],8,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[8] = MMC_CAR(tmpMeta[5]);
tmpMeta[9] = MMC_CDR(tmpMeta[5]);
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 2));
_op = tmpMeta[6];
_e = tmpMeta[7];
_e3 = tmpMeta[8];
_e4 = tmpMeta[10];
_tp = tmpMeta[13];
tmp3 += 24;
tmpMeta[1] = mmc_mk_cons(_e, mmc_mk_cons(_e3, mmc_mk_cons(_e4, MMC_REFSTRUCTLIT(mmc_nil))));
_e = omc_Expression_makeImpureBuiltinCall(threadData, _OMC_LIT96, tmpMeta[1], _tp);
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op, _e);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 33: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
_tp1 = tmpMeta[8];
tmp3 += 1;
tmpMeta[0] = omc_Expression_makeConstZero(threadData, _tp1);
goto tmp2_done;
}
case 34: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],17,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 2));
_tp1 = tmpMeta[6];
_mexpl = tmpMeta[7];
_tp2 = tmpMeta[9];
tmp3 += 22;
_es = omc_List_flatten(threadData, _mexpl);
_tp1 = omc_Expression_unliftArray(threadData, omc_Expression_unliftArray(threadData, _tp1));
_sc = (!omc_Expression_isArrayType(threadData, _tp1));
_tp1 = (_sc?omc_Expression_unliftArray(threadData, _tp1):_tp1);
_tp1 = (_sc?omc_Expression_liftArrayLeft(threadData, _tp1, _OMC_LIT97):_tp1);
_dim = listLength(_es);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim));
_tp1 = omc_Expression_liftArrayLeft(threadData, _tp1, tmpMeta[1]);
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp1, mmc_mk_boolean(_sc), _es);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT98, tmpMeta[1], _tp2);
goto tmp2_done;
}
case 35: {
modelica_integer tmp17;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
tmp17 = mmc_unbox_integer(tmpMeta[7]);
if (0 != tmp17) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 2));
_tp1 = tmpMeta[6];
_es = tmpMeta[8];
_tp2 = tmpMeta[10];
_es = omc_ExpressionSimplify_simplifyCat(threadData, ((modelica_integer) 1), _es);
_tp1 = omc_Expression_unliftArray(threadData, _tp1);
_sc = (!omc_Expression_isArrayType(threadData, _tp1));
_tp1 = (_sc?omc_Expression_unliftArray(threadData, _tp1):_tp1);
_tp1 = (_sc?omc_Expression_liftArrayLeft(threadData, _tp1, _OMC_LIT97):_tp1);
_dim = listLength(_es);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim));
_tp1 = omc_Expression_liftArrayLeft(threadData, _tp1, tmpMeta[1]);
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp1, mmc_mk_boolean(_sc), _es);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT98, tmpMeta[1], _tp2);
goto tmp2_done;
}
case 36: {
modelica_integer tmp18;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
tmp18 = mmc_unbox_integer(tmpMeta[6]);
if (0 != tmp18) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[8] = MMC_CAR(tmpMeta[7]);
tmpMeta[9] = MMC_CDR(tmpMeta[7]);
if (!listEmpty(tmpMeta[9])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 2));
_e = tmpMeta[8];
_tp2 = tmpMeta[11];
tmp3 += 20;
tmpMeta[1] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT98, tmpMeta[1], _tp2);
goto tmp2_done;
}
case 37: {
modelica_integer tmp19;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT98), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
tmp19 = mmc_unbox_integer(tmpMeta[6]);
if (1 != tmp19) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_es = tmpMeta[7];
tmp3 += 19;
tmpMeta[0] = omc_Expression_makeSum(threadData, _es);
goto tmp2_done;
}
case 38: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT99), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e1 = tmpMeta[6];
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 39: {
modelica_integer tmp20;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT99), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp20 = mmc_unbox_integer(tmpMeta[6]);
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
_i = tmp20;
_es = tmpMeta[5];
_tp = tmpMeta[8];
_es = omc_ExpressionSimplify_simplifyCat(threadData, _i, _es);
tmpMeta[2] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _es);
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT99, tmpMeta[1], _tp);
goto tmp2_done;
}
case 40: {
modelica_integer tmp21;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT99), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp21 = mmc_unbox_integer(tmpMeta[6]);
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_i = tmp21;
_es = tmpMeta[5];
tmp3 += 16;
_es = omc_ExpressionSimplify_evalCat(threadData, _i, _es, boxvar_Expression_getArrayOrMatrixContents, boxvar_ExpressionDump_printExpStr ,&_dims);
{
modelica_metatype __omcQ_24tmpVar43;
modelica_metatype* tmp22;
modelica_metatype __omcQ_24tmpVar42;
int tmp23;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = _dims;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar43 = tmpMeta[2];
tmp22 = &__omcQ_24tmpVar43;
while(1) {
tmp23 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp23--;
}
if (tmp23 == 0) {
tmpMeta[3] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, _d);
__omcQ_24tmpVar42 = tmpMeta[3];
*tmp22 = mmc_mk_cons(__omcQ_24tmpVar42,0);
tmp22 = &MMC_CDR(*tmp22);
} else if (tmp23 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp22 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar43;
}
tmpMeta[0] = omc_Expression_listToArray(threadData, _es, tmpMeta[1]);
goto tmp2_done;
}
case 41: {
modelica_integer tmp24;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (7 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT115), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],0,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmp24 = mmc_unbox_integer(tmpMeta[8]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e1 = tmpMeta[4];
_i = tmp24;
if (!(omc_Types_numberOfDimensions(threadData, omc_Expression_typeof(threadData, _e1)) == _i)) goto tmp2_end;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 42: {
modelica_integer tmp25;
modelica_integer tmp26;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (7 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT115), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],6,2) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
if (listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[8] = MMC_CAR(tmpMeta[7]);
tmpMeta[9] = MMC_CDR(tmpMeta[7]);
if (!listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
tmp25 = mmc_unbox_integer(tmpMeta[10]);
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[12] = MMC_CAR(tmpMeta[5]);
tmpMeta[13] = MMC_CDR(tmpMeta[5]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[12],0,1) == 0) goto tmp2_end;
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 2));
tmp26 = mmc_unbox_integer(tmpMeta[14]);
if (2 != tmp26) goto tmp2_end;
if (!listEmpty(tmpMeta[13])) goto tmp2_end;
_tp1 = tmpMeta[6];
_sc = tmp25;
_es = tmpMeta[11];
_tp = omc_Types_liftArray(threadData, omc_Types_unliftArray(threadData, _tp1), _OMC_LIT100);
_es = omc_List_map2(threadData, omc_List_map(threadData, _es, boxvar_List_create), boxvar_Expression_makeArray, _tp, mmc_mk_boolean(_sc));
_i = listLength(_es);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_i));
_tp = omc_Expression_liftArrayLeft(threadData, _tp, tmpMeta[1]);
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(0), _es);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 43: {
modelica_integer tmp27;
modelica_integer tmp28;
modelica_integer tmp29;
modelica_integer tmp30;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (7 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT115), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],0,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmp27 = mmc_unbox_integer(tmpMeta[8]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e1 = tmpMeta[4];
_i = tmp27;
tmp3 += 13;
if (!(!omc_Types_isArray(threadData, omc_Expression_typeof(threadData, _e1)))) goto tmp2_end;
_tp = omc_Expression_typeof(threadData, _e1);
tmp28 = ((modelica_integer) 1); tmp29 = 1; tmp30 = _i;
if(!(((tmp29 > 0) && (tmp28 > tmp30)) || ((tmp29 < 0) && (tmp28 < tmp30))))
{
modelica_integer _j;
for(_j = ((modelica_integer) 1); in_range_integer(_j, tmp28, tmp30); _j += tmp29)
{
_tp1 = omc_Types_liftArray(threadData, _tp, _OMC_LIT100);
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
_e1 = omc_Expression_makeArray(threadData, tmpMeta[1], _tp1, (!omc_Types_isArray(threadData, _tp)));
_tp = _tp1;
}
}
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 44: {
modelica_boolean tmp31;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (9 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT116), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e = tmpMeta[4];
tmp3 += 12;
tmpMeta[1] = omc_Expression_transposeArray(threadData, _e, &tmp31);
_e = tmpMeta[1];
if (1 != tmp31) goto goto_1;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 45: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (9 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT117), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
_e = tmpMeta[4];
_tp = tmpMeta[7];
tmp3 += 11;
_mexpl = omc_Expression_get2dArrayOrMatrixContent(threadData, _e);
{
modelica_metatype tmp34_1;
tmp34_1 = _mexpl;
{
volatile mmc_switch_type tmp34;
int tmp35;
tmp34 = 0;
for (; tmp34 < 3; tmp34++) {
switch (MMC_SWITCH_CAST(tmp34)) {
case 0: {
if (listEmpty(tmp34_1)) goto tmp33_end;
tmpMeta[2] = MMC_CAR(tmp34_1);
tmpMeta[3] = MMC_CDR(tmp34_1);
if (!listEmpty(tmpMeta[2])) goto tmp33_end;
if (!listEmpty(tmpMeta[3])) goto tmp33_end;
tmpMeta[1] = _e;
goto tmp33_done;
}
case 1: {
if (listEmpty(tmp34_1)) goto tmp33_end;
tmpMeta[2] = MMC_CAR(tmp34_1);
tmpMeta[3] = MMC_CDR(tmp34_1);
if (listEmpty(tmpMeta[2])) goto tmp33_end;
tmpMeta[4] = MMC_CAR(tmpMeta[2]);
tmpMeta[5] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[5])) goto tmp33_end;
if (!listEmpty(tmpMeta[3])) goto tmp33_end;
tmpMeta[1] = _e;
goto tmp33_done;
}
case 2: {
modelica_boolean tmp36;
modelica_boolean tmp37;
_marr = listArray(omc_List_map(threadData, _mexpl, boxvar_listArray));
tmp36 = (arrayLength(_marr) == arrayLength(arrayGet(_marr, ((modelica_integer) 1))));
if (1 != tmp36) goto goto_32;
tmp37 = (arrayLength(_marr) > ((modelica_integer) 1));
if (1 != tmp37) goto goto_32;
omc_ExpressionSimplify_simplifySymmetric(threadData, _marr, ((modelica_integer) -1) + arrayLength(_marr), arrayLength(_marr));
_mexpl = omc_List_map(threadData, arrayList(_marr), boxvar_arrayList);
_tp1 = omc_Expression_unliftArray(threadData, _tp);
_es = omc_List_map2(threadData, _mexpl, boxvar_Expression_makeArray, _tp1, mmc_mk_boolean((!omc_Types_isArray(threadData, _tp1))));
tmpMeta[1] = omc_Expression_makeArray(threadData, _es, _tp, 0);
goto tmp33_done;
}
}
goto tmp33_end;
tmp33_end: ;
}
goto goto_32;
goto_32:;
goto goto_1;
goto tmp33_done;
tmp33_done:;
}
}tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 46: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT84), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
_e = tmpMeta[4];
_tp = tmpMeta[7];
tmp3 += 10;
tmpMeta[0] = omc_ExpressionSimplify_simplifyScalar(threadData, _e, _tp);
goto tmp2_done;
}
case 47: {
modelica_boolean tmp38;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT118), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],6,2) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
_es = tmpMeta[3];
_e = tmpMeta[4];
_tp = tmpMeta[8];
tmp38 = omc_Types_isArray(threadData, omc_Expression_typeof(threadData, _e));
if (0 != tmp38) goto goto_1;
_i = listLength(_es);
tmpMeta[2] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_i));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _tp, tmpMeta[1]);
_tp = tmpMeta[3];
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(1), _es);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 48: {
modelica_integer tmp39;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT118), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
tmp39 = mmc_unbox_integer(tmpMeta[6]);
if (1 != tmp39) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e = tmpMeta[4];
tmp3 += 1;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 49: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT118), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],17,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
_mexpl = tmpMeta[6];
_tp = tmpMeta[8];
tmp3 += 7;
_es = omc_List_flatten(threadData, _mexpl);
_es = omc_List_map1(threadData, _es, boxvar_Expression_makeVectorCall, _tp);
tmpMeta[1] = mmc_mk_cons(_OMC_LIT85, _es);
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT99, tmpMeta[1], _tp);
goto tmp2_done;
}
case 50: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT118), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
_es = tmpMeta[6];
_tp = tmpMeta[8];
tmp3 += 6;
_es = omc_List_map1(threadData, _es, boxvar_Expression_makeVectorCall, _tp);
tmpMeta[1] = mmc_mk_cons(_OMC_LIT85, _es);
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT99, tmpMeta[1], _tp);
goto tmp2_done;
}
case 51: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (13 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT119), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
tmp3 += 5;
tmpMeta[0] = _OMC_LIT102;
goto tmp2_done;
}
case 52: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (9 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT120), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e1 = tmpMeta[4];
tmp3 += 4;
tmpMeta[1] = mmc_mk_box2(5, &DAE_ClockKind_REAL__CLOCK__desc, _e1);
tmpMeta[2] = mmc_mk_box2(7, &DAE_Exp_CLKCONST__desc, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 53: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (12 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT121), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e1 = tmpMeta[4];
_e2 = tmpMeta[6];
tmp3 += 3;
tmpMeta[1] = mmc_mk_box3(6, &DAE_ClockKind_BOOLEAN__CLOCK__desc, _e1, _e2);
tmpMeta[2] = mmc_mk_box2(7, &DAE_Exp_CLKCONST__desc, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 54: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (13 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT122), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e1 = tmpMeta[4];
_e2 = tmpMeta[6];
tmp3 += 2;
tmpMeta[1] = mmc_mk_box3(4, &DAE_ClockKind_INTEGER__CLOCK__desc, _e1, _e2);
tmpMeta[2] = mmc_mk_box2(7, &DAE_Exp_CLKCONST__desc, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 55: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (11 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT123), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e1 = tmpMeta[4];
_e2 = tmpMeta[6];
tmp3 += 1;
tmpMeta[1] = mmc_mk_box3(7, &DAE_ClockKind_SOLVER__CLOCK__desc, _e1, _e2);
tmpMeta[2] = mmc_mk_box2(7, &DAE_Exp_CLKCONST__desc, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 56: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (26 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT124), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],2,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_s1 = tmpMeta[6];
_s2 = OpenModelica__uriToFilename(_s1);
if(omc_Flags_getConfigBool(threadData, _OMC_LIT108))
{
tmpMeta[2] = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _s2);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
_e = omc_Expression_makeImpureBuiltinCall(threadData, _OMC_LIT103, tmpMeta[1], _OMC_LIT72);
}
else
{
tmpMeta[1] = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _s2);
_e = tmpMeta[1];
}
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
if (++tmp3 < 57) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_addCast(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inType)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _inType, _inExp);
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCast(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _exp, modelica_metatype _tp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _exp;
tmp3_2 = _tp;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 14; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_real tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_real(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
_r = tmp5;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,1) == 0) goto tmp2_end;
_i = tmp6;
_r = ((modelica_real)_i);
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_r));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_e = tmpMeta[2];
tmpMeta[1] = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp, _e);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_box2(9, &DAE_Operator_UMINUS__ARR__desc, _tp);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], _e);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_e = tmpMeta[2];
tmpMeta[1] = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp, _e);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _tp);
tmpMeta[2] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], _e);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 4: {
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_b = tmp7;
_exps = tmpMeta[2];
_tp_1 = omc_Expression_unliftArray(threadData, _tp);
_exps_1 = omc_List_map1(threadData, _exps, boxvar_ExpressionSimplify_addCast, _tp_1);
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _tp, mmc_mk_boolean(_b), _exps_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,18,4) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_tp2 = tmpMeta[1];
_e1 = tmpMeta[4];
_eo = tmpMeta[5];
_e2 = tmpMeta[6];
tmpMeta[1] = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp2, _e1);
_e1 = tmpMeta[1];
tmpMeta[1] = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp2, _e2);
_e2 = tmpMeta[1];
_eo = omc_Util_applyOption1(threadData, _eo, boxvar_ExpressionSimplify_addCast, _tp2);
tmpMeta[1] = mmc_mk_box5(21, &DAE_Exp_RANGE__desc, _tp, _e1, _eo, _e2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,12,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_cond = tmpMeta[1];
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp, _e1);
_e1_1 = tmpMeta[1];
tmpMeta[1] = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp, _e2);
_e2_1 = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _cond, _e1_1, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 7: {
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp8 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_n = tmp8;
_mexps = tmpMeta[2];
_tp1 = omc_Expression_unliftArray(threadData, _tp);
_tp2 = omc_Expression_unliftArray(threadData, _tp1);
_mexps_1 = omc_List_map1List(threadData, _mexps, boxvar_ExpressionSimplify_addCast, _tp2);
tmpMeta[1] = mmc_mk_box4(20, &DAE_Exp_MATRIX__desc, _tp, mmc_mk_integer(_n), _mexps_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],9,3) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],3,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
_p3 = tmpMeta[2];
_p1 = tmpMeta[3];
_exps = tmpMeta[4];
_p2 = tmpMeta[8];
if (!omc_AbsynUtil_pathEqual(threadData, _p1, _p2)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _tp, mmc_mk_boolean(0), mmc_mk_boolean(0), mmc_mk_boolean(0), mmc_mk_boolean(0), _OMC_LIT125, _OMC_LIT126);
tmpMeta[2] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _p3, _exps, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,14,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,9,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],3,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_exps = tmpMeta[1];
_fieldNames = tmpMeta[2];
_p3 = tmpMeta[4];
tmpMeta[1] = mmc_mk_box5(17, &DAE_Exp_RECORD__desc, _p3, _exps, _fieldNames, _tp);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (4 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT111), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
_e = tmpMeta[4];
_exps = tmpMeta[5];
_tp_1 = omc_List_fold(threadData, _exps, boxvar_Expression_unliftArrayIgnoreFirst, _tp);
tmpMeta[1] = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp_1, _e);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_e, _exps);
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT111, tmpMeta[1], _tp);
goto tmp2_done;
}
case 11: {
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (3 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT99), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],0,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmp9 = mmc_unbox_integer(tmpMeta[7]);
_dims = tmpMeta[1];
_e = tmpMeta[5];
_n = tmp9;
_exps = tmpMeta[6];
if (!omc_Expression_dimensionUnknown(threadData, listGet(_dims, _n))) goto tmp2_end;
_exps = omc_List_map1(threadData, _exps, boxvar_ExpressionSimplify_addCast, _tp);
tmpMeta[1] = mmc_mk_cons(_e, _exps);
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT99, tmpMeta[1], _tp);
goto tmp2_done;
}
case 12: {
_e = tmp3_1;
_t1 = omc_Expression_arrayEltType(threadData, _tp);
_t2 = omc_Expression_arrayEltType(threadData, omc_Expression_typeof(threadData, _e));
tmpMeta[0] = (valueEq(_t1, _t2)?_e:_origExp);
goto tmp2_done;
}
case 13: {
tmpMeta[0] = _origExp;
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMatch(threadData_t *threadData, modelica_metatype _exp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[29] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _exp;
{
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e1_1 = NULL;
modelica_metatype _e2_1 = NULL;
modelica_boolean _b1;
modelica_boolean _b2;
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,33,6) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (!listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 5));
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 6));
if (optionNone(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 1));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_e = tmpMeta[10];
_ty = tmpMeta[11];
if (!(!omc_Types_isTuple(threadData, _ty))) goto tmp2_end;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 1: {
modelica_integer tmp5;
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,33,6) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],1,2) == 0) goto tmp2_end;
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[9]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[11],3,1) == 0) goto tmp2_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[11]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[12]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 4));
if (!listEmpty(tmpMeta[13])) goto tmp2_end;
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 5));
if (!listEmpty(tmpMeta[14])) goto tmp2_end;
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 6));
if (optionNone(tmpMeta[15])) goto tmp2_end;
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[15]), 1));
if (listEmpty(tmpMeta[7])) goto tmp2_end;
tmpMeta[17] = MMC_CAR(tmpMeta[7]);
tmpMeta[18] = MMC_CDR(tmpMeta[7]);
tmpMeta[19] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[17]), 2));
if (listEmpty(tmpMeta[19])) goto tmp2_end;
tmpMeta[20] = MMC_CAR(tmpMeta[19]);
tmpMeta[21] = MMC_CDR(tmpMeta[19]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[20],1,2) == 0) goto tmp2_end;
tmpMeta[22] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[20]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[22],3,1) == 0) goto tmp2_end;
tmpMeta[23] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[22]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[23]);
if (!listEmpty(tmpMeta[21])) goto tmp2_end;
tmpMeta[24] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[17]), 4));
if (!listEmpty(tmpMeta[24])) goto tmp2_end;
tmpMeta[25] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[17]), 5));
if (!listEmpty(tmpMeta[25])) goto tmp2_end;
tmpMeta[26] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[17]), 6));
if (optionNone(tmpMeta[26])) goto tmp2_end;
tmpMeta[27] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[26]), 1));
if (!listEmpty(tmpMeta[18])) goto tmp2_end;
tmpMeta[28] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_e = tmpMeta[2];
_b1 = tmp5;
_e1 = tmpMeta[16];
_b2 = tmp6;
_e2 = tmpMeta[27];
_ty = tmpMeta[28];
if (!((!((!_b1 && !_b2) || (_b1 && _b2))) && (!omc_Types_isTuple(threadData, _ty)))) goto tmp2_end;
_e1_1 = (_b1?_e1:_e2);
_e2_1 = (_b1?_e2:_e1);
tmpMeta[1] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _e, _e1_1, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,33,6) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (listEmpty(tmpMeta[6])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[6]);
tmpMeta[8] = MMC_CDR(tmpMeta[6]);
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (listEmpty(tmpMeta[9])) goto tmp2_end;
tmpMeta[10] = MMC_CAR(tmpMeta[9]);
tmpMeta[11] = MMC_CDR(tmpMeta[9]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[10],1,2) == 0) goto tmp2_end;
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[10]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[12],3,1) == 0) goto tmp2_end;
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[12]), 2));
tmp7 = mmc_unbox_integer(tmpMeta[13]);
if (!listEmpty(tmpMeta[11])) goto tmp2_end;
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 4));
if (!listEmpty(tmpMeta[14])) goto tmp2_end;
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 5));
if (!listEmpty(tmpMeta[15])) goto tmp2_end;
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 6));
if (optionNone(tmpMeta[16])) goto tmp2_end;
tmpMeta[17] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[16]), 1));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[18] = MMC_CAR(tmpMeta[8]);
tmpMeta[19] = MMC_CDR(tmpMeta[8]);
tmpMeta[20] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[18]), 2));
if (listEmpty(tmpMeta[20])) goto tmp2_end;
tmpMeta[21] = MMC_CAR(tmpMeta[20]);
tmpMeta[22] = MMC_CDR(tmpMeta[20]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[21],0,0) == 0) goto tmp2_end;
if (!listEmpty(tmpMeta[22])) goto tmp2_end;
tmpMeta[23] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[18]), 4));
if (!listEmpty(tmpMeta[23])) goto tmp2_end;
tmpMeta[24] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[18]), 5));
if (!listEmpty(tmpMeta[24])) goto tmp2_end;
tmpMeta[25] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[18]), 6));
if (optionNone(tmpMeta[25])) goto tmp2_end;
tmpMeta[26] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[25]), 1));
if (!listEmpty(tmpMeta[19])) goto tmp2_end;
tmpMeta[27] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_e = tmpMeta[3];
_b1 = tmp7;
_e1 = tmpMeta[17];
_e2 = tmpMeta[26];
_ty = tmpMeta[27];
if (!(!omc_Types_isTuple(threadData, _ty))) goto tmp2_end;
_e1_1 = (_b1?_e1:_e2);
_e2_1 = (_b1?_e2:_e1);
tmpMeta[1] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _e, _e1_1, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _exp;
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyUnbox(threadData_t *threadData, modelica_metatype _exp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _exp;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,35,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],34,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_outExp = tmpMeta[2];
tmpMeta[0] = _outExp;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,34,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],35,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_outExp = tmpMeta[2];
tmpMeta[0] = _outExp;
goto tmp2_done;
}
case 2: {
tmpMeta[0] = _exp;
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyCons(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
modelica_metatype _e = NULL;
modelica_metatype _es = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,29,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],28,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_e = tmpMeta[1];
_es = tmpMeta[3];
tmpMeta[1] = mmc_mk_cons(_e, _es);
tmpMeta[2] = mmc_mk_box2(31, &DAE_Exp_LIST__desc, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inExp;
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyMetaModelicaCalls(threadData_t *threadData, modelica_metatype _exp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[17] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _exp;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 11; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (10 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT132), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],28,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[5]);
tmpMeta[8] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
_el = tmpMeta[6];
_e2 = tmpMeta[7];
tmpMeta[0] = omc_List_fold(threadData, listReverse(_el), boxvar_Expression_makeCons, _e2);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (10 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT132), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],28,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e1 = tmpMeta[4];
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 2: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (9 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT133), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[6]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_i = tmp5;
_s = intString(_i);
tmpMeta[1] = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _s);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
modelica_real tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (10 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT134), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp6 = mmc_unbox_real(tmpMeta[6]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_r = tmp6;
_s = realString(_r);
tmpMeta[1] = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _s);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (10 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT135), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],3,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp7 = mmc_unbox_integer(tmpMeta[6]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_b = tmp7;
_s = (_b?_OMC_LIT76:_OMC_LIT77);
tmpMeta[1] = mmc_mk_box2(5, &DAE_Exp_SCONST__desc, _s);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (11 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT127), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],28,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_el = tmpMeta[6];
_el = listReverse(_el);
tmpMeta[1] = mmc_mk_box2(31, &DAE_Exp_LIST__desc, _el);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (11 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT127), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],27,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (4 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT129), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 4));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 5));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 6));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 7));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 8));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_rit = tmpMeta[9];
_ty = tmpMeta[10];
_v = tmpMeta[11];
_foldName = tmpMeta[12];
_resultName = tmpMeta[13];
_foldExp = tmpMeta[14];
_e1 = tmpMeta[15];
_riters = tmpMeta[16];
tmpMeta[1] = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _OMC_LIT128, _rit, _ty, _v, _foldName, _resultName, _foldExp);
tmpMeta[2] = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta[1], _e1, _riters);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (11 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT127), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],27,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
if (11 != MMC_STRLEN(tmpMeta[8]) || strcmp(MMC_STRINGDATA(_OMC_LIT127), MMC_STRINGDATA(tmpMeta[8])) != 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 4));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 5));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 6));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 7));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 8));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_rit = tmpMeta[9];
_ty = tmpMeta[10];
_v = tmpMeta[11];
_foldName = tmpMeta[12];
_resultName = tmpMeta[13];
_foldExp = tmpMeta[14];
_e1 = tmpMeta[15];
_riters = tmpMeta[16];
tmpMeta[1] = mmc_mk_box8(3, &DAE_ReductionInfo_REDUCTIONINFO__desc, _OMC_LIT130, _rit, _ty, _v, _foldName, _resultName, _foldExp);
tmpMeta[2] = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, tmpMeta[1], _e1, _riters);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (10 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT136), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],28,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_el = tmpMeta[6];
_i = listLength(_el);
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_i));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (11 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT137), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[4];
tmpMeta[1] = mmc_mk_box2(34, &DAE_Exp_META__OPTION__desc, mmc_mk_some(_e));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (10 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT138), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
fputs(MMC_STRINGDATA(_OMC_LIT131),stdout);
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyIfExp(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _cond, modelica_metatype _tb, modelica_metatype _fb)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _cond;
tmp3_2 = _tb;
tmp3_3 = _fb;
{
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 6; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp5) goto tmp2_end;
tmpMeta[0] = _tb;
goto tmp2_done;
}
case 1: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
if (0 != tmp6) goto tmp2_end;
tmpMeta[0] = _fb;
goto tmp2_done;
}
case 2: {
modelica_integer tmp7;
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
if (1 != tmp7) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,3,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp8 = mmc_unbox_integer(tmpMeta[2]);
if (0 != tmp8) goto tmp2_end;
_exp = tmp3_1;
tmpMeta[0] = _exp;
goto tmp2_done;
}
case 3: {
modelica_integer tmp9;
modelica_integer tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmp9 = mmc_unbox_integer(tmpMeta[1]);
if (0 != tmp9) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,3,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
tmp10 = mmc_unbox_integer(tmpMeta[2]);
if (1 != tmp10) goto tmp2_end;
_exp = tmp3_1;
tmpMeta[1] = mmc_mk_box3(13, &DAE_Exp_LUNARY__desc, _OMC_LIT139, _exp);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,34,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmp3_3,34,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
_e1 = tmpMeta[1];
_e2 = tmpMeta[2];
_e = tmp3_1;
tmpMeta[1] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _e, _e1, _e2);
_e = tmpMeta[1];
tmpMeta[1] = mmc_mk_box2(37, &DAE_Exp_BOX__desc, _e);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
tmpMeta[0] = (omc_Expression_expEqual(threadData, _tb, _fb)?_tb:_origExp);
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
_exp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyReductionIterators(threadData_t *threadData, modelica_metatype _inIters, modelica_metatype _inAcc, modelica_boolean _inChange, modelica_boolean *out_outChange)
{
modelica_metatype _outIters = NULL;
modelica_boolean _outChange;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
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
modelica_integer tmp6;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
if (optionNone(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],3,1) == 0) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[8]);
if (1 != tmp6) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_id = tmpMeta[4];
_exp = tmpMeta[5];
_ty = tmpMeta[9];
_iters = tmpMeta[3];
_acc = tmp4_2;
tmpMeta[3] = mmc_mk_box5(3, &DAE_ReductionIterator_REDUCTIONITER__desc, _id, _exp, mmc_mk_none(), _ty);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _acc);
_inIters = _iters;
_inAcc = tmpMeta[2];
_inChange = 1;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
modelica_integer tmp7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],3,1) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmp7 = mmc_unbox_integer(tmpMeta[7]);
if (0 != tmp7) goto tmp3_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_id = tmpMeta[4];
_ty = tmpMeta[8];
tmpMeta[3] = mmc_mk_box5(3, &DAE_ReductionIterator_REDUCTIONITER__desc, _id, _OMC_LIT140, mmc_mk_none(), _ty);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 3: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
_iter = tmpMeta[2];
_iters = tmpMeta[3];
_acc = tmp4_2;
_change = tmp4_3;
tmpMeta[2] = mmc_mk_cons(_iter, _acc);
_inIters = _iters;
_inAcc = tmpMeta[2];
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
if (0 != tmp4_3) goto tmp3_end;
_exp = tmp4_1;
_options = tmp4_2;
_str1 = omc_ExpressionDump_printExpStr(threadData, _exp);
_exp = omc_Expression_traverseExpBottomUp(threadData, _exp, boxvar_ExpressionSimplify_simplifyWork, _options, NULL);
_str2 = omc_ExpressionDump_printExpStr(threadData, _exp);
tmpMeta[2] = mmc_mk_cons(_str1, mmc_mk_cons(_str2, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addMessage(threadData, _OMC_LIT144, tmpMeta[2]);
tmpMeta[0+0] = _exp;
tmp1_c1 = _hasChanged;
goto tmp3_done;
}
case 2: {
if (1 != tmp4_4) goto tmp3_end;
_exp = tmp4_1;
_options = tmp4_2;
omc_ErrorExt_setCheckpoint(threadData, _OMC_LIT145);
_expAfterSimplify = omc_Expression_traverseExpBottomUp(threadData, _exp, boxvar_ExpressionSimplify_simplifyWork, _options ,&_options);
_b = (!referenceEq(_expAfterSimplify, _exp));
if(_b)
{
omc_ErrorExt_rollBack(threadData, _OMC_LIT145);
}
else
{
omc_ErrorExt_delCheckpoint(threadData, _OMC_LIT145);
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
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
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
tmpMeta[0] = mmc_mk_cons(_s1, mmc_mk_cons(_s2, mmc_mk_cons(_s3, mmc_mk_cons(_s4, MMC_REFSTRUCTLIT(mmc_nil)))));
omc_Error_addMessage(threadData, _OMC_LIT149, tmpMeta[0]);
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
tmpMeta[0] = mmc_mk_cons(_s1, mmc_mk_cons(_s2, mmc_mk_cons(_s3, mmc_mk_cons(_s4, MMC_REFSTRUCTLIT(mmc_nil)))));
omc_Error_addMessage(threadData, _OMC_LIT153, tmpMeta[0]);
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
omc_ExpressionSimplify_checkSimplify(threadData, omc_Flags_isSet(threadData, _OMC_LIT157), _inExp, _outExp);
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
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_e = tmpMeta[1];
_e = omc_ExpressionSimplify_simplify1WithOptions(threadData, _e, _OMC_LIT159, NULL);
tmpMeta[0] = mmc_mk_some(_e);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inExp;
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
_outExp = tmpMeta[0];
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
_outExp = omc_ExpressionSimplify_simplify1WithOptions(threadData, _inExp, _OMC_LIT159 ,&_hasChanged);
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmp4_1;
_ty = tmpMeta[3];
tmpMeta[3] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = omc_Expression_makeBuiltinCall(threadData, _OMC_LIT64, tmpMeta[3], _ty, 0);
tmp1_c1 = 0;
tmp1_c2 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (4 != MMC_STRLEN(tmpMeta[4]) || strcmp(MMC_STRINGDATA(_OMC_LIT64), MMC_STRINGDATA(tmpMeta[4])) != 0) goto tmp3_end;
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmp4_1;
_ty = tmpMeta[3];
tmpMeta[3] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = omc_Expression_makeBuiltinCall(threadData, _OMC_LIT65, tmpMeta[3], _ty, 0);
tmp1_c1 = 0;
tmp1_c2 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (6 != MMC_STRLEN(tmpMeta[4]) || strcmp(MMC_STRINGDATA(_OMC_LIT65), MMC_STRINGDATA(tmpMeta[4])) != 0) goto tmp3_end;
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmp4_1;
_ty = tmpMeta[3];
tmpMeta[3] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = omc_Expression_makeBuiltinCall(threadData, _OMC_LIT63, tmpMeta[3], _ty, 0);
tmp1_c1 = 0;
tmp1_c2 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (8 != MMC_STRLEN(tmpMeta[4]) || strcmp(MMC_STRINGDATA(_OMC_LIT63), MMC_STRINGDATA(tmpMeta[4])) != 0) goto tmp3_end;
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
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmp4_1;
_ty = tmpMeta[3];
tmpMeta[3] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = omc_Expression_makeBuiltinCall(threadData, _OMC_LIT62, tmpMeta[3], _ty, 0);
tmp1_c1 = 0;
tmp1_c2 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],1,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (3 != MMC_STRLEN(tmpMeta[4]) || strcmp(MMC_STRINGDATA(_OMC_LIT62), MMC_STRINGDATA(tmpMeta[4])) != 0) goto tmp3_end;
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
modelica_metatype tmpMeta[11] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inExp;
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
modelica_integer _n;
modelica_integer _i1;
modelica_integer _i2;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 34; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (8 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT166), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e1 = tmpMeta[4];
_e2 = tmpMeta[6];
tmp3 += 15;
if (!omc_Expression_expEqual(threadData, _e1, _e2)) goto tmp2_end;
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (7 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT167), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[4];
tmp3 += 14;
_b2 = (omc_Expression_isRelation(threadData, _e) || omc_Expression_isEventTriggeringFunctionExp(threadData, _e));
tmpMeta[0] = ((!_b2)?omc_ExpressionSimplify_simplifyNoEvent(threadData, _e):_inExp);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT61), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],8,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],5,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],6,2) == 0) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_tp = tmpMeta[7];
_e1 = tmpMeta[8];
_attr = tmpMeta[9];
tmp3 += 13;
tmpMeta[1] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _tp);
tmpMeta[2] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT160, tmpMeta[2], _attr);
tmpMeta[4] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], tmpMeta[3]);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT61), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],8,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],6,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[8],6,2) == 0) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_tp = tmpMeta[7];
_e1 = tmpMeta[8];
_attr = tmpMeta[9];
tmp3 += 12;
tmpMeta[1] = mmc_mk_box2(9, &DAE_Operator_UMINUS__ARR__desc, _tp);
tmpMeta[2] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT160, tmpMeta[2], _attr);
tmpMeta[4] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[1], tmpMeta[3]);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT62), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],6,2) == 0) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmp3 += 7;
tmpMeta[0] = _inExp;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (8 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT63), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],6,2) == 0) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmp3 += 7;
tmpMeta[0] = _inExp;
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT65), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],6,2) == 0) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmp3 += 7;
tmpMeta[0] = _inExp;
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (4 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT64), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],6,2) == 0) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmp3 += 7;
tmpMeta[0] = _inExp;
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT62), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],21,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[4];
_exp = tmpMeta[6];
tmp3 += 3;
_b2 = omc_Expression_isConst(threadData, _exp);
tmpMeta[0] = (_b2?_e:_inExp);
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (8 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT63), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],21,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[4];
_exp = tmpMeta[6];
tmp3 += 3;
_b2 = omc_Expression_isConst(threadData, _exp);
tmpMeta[0] = (_b2?_e:_inExp);
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT65), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],21,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_exp = tmpMeta[6];
tmp3 += 3;
_b2 = omc_Expression_isConst(threadData, _exp);
tmpMeta[0] = (_b2?_OMC_LIT22:_inExp);
goto tmp2_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (4 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT64), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],21,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_exp = tmpMeta[6];
tmp3 += 3;
_b2 = omc_Expression_isConst(threadData, _exp);
tmpMeta[0] = (_b2?_OMC_LIT22:_inExp);
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT62), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[4];
tmp3 += 3;
tmpMeta[0] = omc_Expression_traverseExpTopDown(threadData, _e, boxvar_ExpressionSimplify_preCref, mmc_mk_boolean(0), NULL);
goto tmp2_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (8 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT63), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[4];
tmp3 += 2;
tmpMeta[0] = omc_Expression_traverseExpTopDown(threadData, _e, boxvar_ExpressionSimplify_previousCref, mmc_mk_boolean(0), NULL);
goto tmp2_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (6 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT65), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[4];
tmp3 += 1;
tmpMeta[0] = omc_Expression_traverseExpTopDown(threadData, _e, boxvar_ExpressionSimplify_changeCref, mmc_mk_boolean(0), NULL);
goto tmp2_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (4 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT64), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[4];
tmpMeta[0] = omc_Expression_traverseExpTopDown(threadData, _e, boxvar_ExpressionSimplify_edgeCref, mmc_mk_boolean(0), NULL);
goto tmp2_done;
}
case 16: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 5));
tmp5 = mmc_unbox_integer(tmpMeta[5]);
if (0 != tmp5) goto tmp2_end;
_idn = tmpMeta[2];
_expl = tmpMeta[3];
if (!omc_Expression_isConstWorkList(threadData, _expl)) goto tmp2_end;
tmpMeta[0] = omc_ExpressionSimplify_simplifyBuiltinConstantCalls(threadData, _idn, _inExp);
goto tmp2_done;
}
case 17: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
if (1 != tmp6) goto tmp2_end;
tmpMeta[0] = omc_ExpressionSimplify_simplifyBuiltinCalls(threadData, _inExp);
goto tmp2_done;
}
case 18: {
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (8 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT168), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp7 = mmc_unbox_integer(tmpMeta[6]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_n = tmp7;
tmp3 += 13;
{
modelica_metatype __omcQ_24tmpVar47;
modelica_metatype* tmp8;
modelica_metatype __omcQ_24tmpVar46;
int tmp13;
modelica_integer tmp14;
modelica_integer tmp15;
modelica_integer _j;
tmp14 = 1;
tmp15 = _n;
_j = ((modelica_integer) 1);
_j = (((modelica_integer) 1) /* Range start-value */)-tmp14;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar47 = tmpMeta[2];
tmp8 = &__omcQ_24tmpVar47;
while(1) {
tmp13 = 1;
if (tmp14 > 0 ? _j+tmp14 <= tmp15 : _j+tmp14 >= tmp15) {
_j += tmp14;
tmp13--;
}
if (tmp13 == 0) {
tmpMeta[4] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_n));
tmpMeta[3] = mmc_mk_cons(tmpMeta[4], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[5] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT54, tmpMeta[3]);
{
modelica_metatype __omcQ_24tmpVar45;
modelica_metatype* tmp9;
modelica_metatype __omcQ_24tmpVar44;
int tmp10;
modelica_integer tmp11;
modelica_integer tmp12;
modelica_integer _i;
tmp11 = 1;
tmp12 = _n;
_i = ((modelica_integer) 1);
_i = (((modelica_integer) 1) /* Range start-value */)-tmp11;
tmpMeta[7] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar45 = tmpMeta[7];
tmp9 = &__omcQ_24tmpVar45;
while(1) {
tmp10 = 1;
if (tmp11 > 0 ? _i+tmp11 <= tmp12 : _i+tmp11 >= tmp12) {
_i += tmp11;
tmp10--;
}
if (tmp10 == 0) {
__omcQ_24tmpVar44 = ((_i == _j)?_OMC_LIT85:_OMC_LIT161);
*tmp9 = mmc_mk_cons(__omcQ_24tmpVar44,0);
tmp9 = &MMC_CDR(*tmp9);
} else if (tmp10 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp9 = mmc_mk_nil();
tmpMeta[6] = __omcQ_24tmpVar45;
}
tmpMeta[8] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta[5], mmc_mk_boolean(1), tmpMeta[6]);
__omcQ_24tmpVar46 = tmpMeta[8];
*tmp8 = mmc_mk_cons(__omcQ_24tmpVar46,0);
tmp8 = &MMC_CDR(*tmp8);
} else if (tmp13 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp8 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar47;
}
_matrix = tmpMeta[1];
tmpMeta[2] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_n));
tmpMeta[3] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_n));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[4] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _OMC_LIT54, tmpMeta[1]);
tmpMeta[5] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta[4], mmc_mk_boolean(0), _matrix);
tmpMeta[0] = tmpMeta[5];
goto tmp2_done;
}
case 19: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (8 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT169), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],16,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 4));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_tp = tmpMeta[6];
_expl = tmpMeta[7];
tmp3 += 12;
_n = listLength(_expl);
_tp = omc_Types_arrayElementType(threadData, _tp);
_zero = omc_Expression_makeConstZero(threadData, _tp);
{
modelica_metatype __omcQ_24tmpVar51;
modelica_metatype* tmp16;
modelica_metatype __omcQ_24tmpVar50;
int tmp21;
modelica_integer tmp22;
modelica_integer tmp23;
modelica_integer _j;
tmp22 = 1;
tmp23 = _n;
_j = ((modelica_integer) 1);
_j = (((modelica_integer) 1) /* Range start-value */)-tmp22;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar51 = tmpMeta[2];
tmp16 = &__omcQ_24tmpVar51;
while(1) {
tmp21 = 1;
if (tmp22 > 0 ? _j+tmp22 <= tmp23 : _j+tmp22 >= tmp23) {
_j += tmp22;
tmp21--;
}
if (tmp21 == 0) {
tmpMeta[4] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_n));
tmpMeta[3] = mmc_mk_cons(tmpMeta[4], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[5] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _tp, tmpMeta[3]);
{
modelica_metatype __omcQ_24tmpVar49;
modelica_metatype* tmp17;
modelica_metatype __omcQ_24tmpVar48;
int tmp18;
modelica_integer tmp19;
modelica_integer tmp20;
modelica_integer _i;
tmp19 = 1;
tmp20 = _n;
_i = ((modelica_integer) 1);
_i = (((modelica_integer) 1) /* Range start-value */)-tmp19;
tmpMeta[7] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar49 = tmpMeta[7];
tmp17 = &__omcQ_24tmpVar49;
while(1) {
tmp18 = 1;
if (tmp19 > 0 ? _i+tmp19 <= tmp20 : _i+tmp19 >= tmp20) {
_i += tmp19;
tmp18--;
}
if (tmp18 == 0) {
__omcQ_24tmpVar48 = ((_i == _j)?listGet(_expl, _i):_zero);
*tmp17 = mmc_mk_cons(__omcQ_24tmpVar48,0);
tmp17 = &MMC_CDR(*tmp17);
} else if (tmp18 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp17 = mmc_mk_nil();
tmpMeta[6] = __omcQ_24tmpVar49;
}
tmpMeta[8] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta[5], mmc_mk_boolean(1), tmpMeta[6]);
__omcQ_24tmpVar50 = tmpMeta[8];
*tmp16 = mmc_mk_cons(__omcQ_24tmpVar50,0);
tmp16 = &MMC_CDR(*tmp16);
} else if (tmp21 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp16 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar51;
}
_matrix = tmpMeta[1];
tmpMeta[2] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_n));
tmpMeta[3] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_n));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[4] = mmc_mk_box3(9, &DAE_Type_T__ARRAY__desc, _tp, tmpMeta[1]);
tmpMeta[5] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, tmpMeta[4], mmc_mk_boolean(0), _matrix);
tmpMeta[0] = tmpMeta[5];
goto tmp2_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],13,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_idn = tmpMeta[2];
_idn2 = tmpMeta[7];
_e = tmpMeta[9];
tmp3 += 3;
if (!((stringEqual(_idn, _OMC_LIT37)) && (stringEqual(_idn2, _OMC_LIT162)))) goto tmp2_end;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 21: {
modelica_real tmp24;
modelica_real tmp25;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT170), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp24 = mmc_unbox_real(tmpMeta[6]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[5]);
tmpMeta[8] = MMC_CDR(tmpMeta[5]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
tmp25 = mmc_unbox_real(tmpMeta[9]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
_r1 = tmp24;
_r2 = tmp25;
tmp3 += 10;
if (!(_r2 != 0.0)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(modelica_real_mod(_r1, _r2)));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 22: {
modelica_integer tmp26;
modelica_integer tmp27;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT170), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp26 = mmc_unbox_integer(tmpMeta[6]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[5]);
tmpMeta[8] = MMC_CDR(tmpMeta[5]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],0,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
tmp27 = mmc_unbox_integer(tmpMeta[9]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
_i1 = tmp26;
_i2 = tmp27;
tmp3 += 9;
if (!(((modelica_real)_i2) != 0.0)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(modelica_integer_mod(_i1, _i2)));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 23: {
modelica_real tmp28;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (7 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT171), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp28 = mmc_unbox_real(tmpMeta[6]);
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_r1 = tmp28;
tmp3 += 8;
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(((modelica_integer)floor(_r1))));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 24: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],13,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (4 != MMC_STRLEN(tmpMeta[7]) || strcmp(MMC_STRINGDATA(_OMC_LIT67), MMC_STRINGDATA(tmpMeta[7])) != 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[9];
tmp3 += 7;
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT34, _e);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, _OMC_LIT163, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta[1], _OMC_LIT30);
goto tmp2_done;
}
case 25: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],13,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (4 != MMC_STRLEN(tmpMeta[7]) || strcmp(MMC_STRINGDATA(_OMC_LIT66), MMC_STRINGDATA(tmpMeta[7])) != 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[9];
tmp3 += 6;
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT34, _e);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, _OMC_LIT163, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta[1], _OMC_LIT30);
goto tmp2_done;
}
case 26: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT39), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],13,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (4 != MMC_STRLEN(tmpMeta[7]) || strcmp(MMC_STRINGDATA(_OMC_LIT162), MMC_STRINGDATA(tmpMeta[7])) != 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[9];
tmp3 += 5;
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT34, _e);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, _OMC_LIT46, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[4] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT31, omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta[1], _OMC_LIT30));
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 27: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT38), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],13,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],1,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
if (4 != MMC_STRLEN(tmpMeta[7]) || strcmp(MMC_STRINGDATA(_OMC_LIT162), MMC_STRINGDATA(tmpMeta[7])) != 0) goto tmp2_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (listEmpty(tmpMeta[8])) goto tmp2_end;
tmpMeta[9] = MMC_CAR(tmpMeta[8]);
tmpMeta[10] = MMC_CDR(tmpMeta[8]);
if (!listEmpty(tmpMeta[10])) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_e = tmpMeta[9];
tmp3 += 4;
tmpMeta[2] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e, _OMC_LIT34, _e);
tmpMeta[3] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, _OMC_LIT46, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[4] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT27, _OMC_LIT31, omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT35, tmpMeta[1], _OMC_LIT30));
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 28: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (5 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT172), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[5]);
tmpMeta[7] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_e1 = tmpMeta[4];
_e2 = tmpMeta[6];
if (!omc_Expression_isZero(threadData, _e2)) goto tmp2_end;
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
_e = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT43, tmpMeta[1], _OMC_LIT30);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _OMC_LIT165, _OMC_LIT34, _e);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 29: {
modelica_real tmp29;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (5 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT172), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp29 = mmc_unbox_real(tmpMeta[6]);
if (0.0 != tmp29) goto tmp2_end;
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[5]);
tmpMeta[8] = MMC_CDR(tmpMeta[5]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
_e1 = tmpMeta[4];
tmpMeta[0] = _e1;
goto tmp2_done;
}
case 30: {
modelica_real tmp30;
modelica_real tmp31;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (5 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT172), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,1) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp30 = mmc_unbox_real(tmpMeta[6]);
if (listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[7] = MMC_CAR(tmpMeta[5]);
tmpMeta[8] = MMC_CDR(tmpMeta[5]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],1,1) == 0) goto tmp2_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
tmp31 = mmc_unbox_real(tmpMeta[9]);
if (!listEmpty(tmpMeta[8])) goto tmp2_end;
_r1 = tmp30;
_r2 = tmp31;
tmp3 += 1;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(atan2(_r1, _r2)));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 31: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (3 != MMC_STRLEN(tmpMeta[2]) || strcmp(MMC_STRINGDATA(_OMC_LIT24), MMC_STRINGDATA(tmpMeta[2])) != 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],8,2) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],5,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_tp = tmpMeta[7];
_e1 = tmpMeta[8];
tmpMeta[1] = mmc_mk_cons(_e1, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT24, tmpMeta[1], _tp);
goto tmp2_done;
}
case 32: {
if (!omc_Config_acceptMetaModelicaGrammar(threadData)) goto tmp2_end;
tmpMeta[0] = omc_ExpressionSimplify_simplifyMetaModelicaCalls(threadData, _inExp);
goto tmp2_done;
}
case 33: {
tmpMeta[0] = _inExp;
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
if (++tmp3 < 34) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyAsubExp(threadData_t *threadData, modelica_metatype _origExp, modelica_metatype _inExp, modelica_metatype _inSubs)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[9] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inExp;
tmp3_2 = _inSubs;
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
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 7; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
_e = tmp3_1;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,20,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_tp = tmpMeta[1];
_e = tmpMeta[2];
tmp3 += 1;
_tp = omc_Expression_unliftArray(threadData, _tp);
tmpMeta[1] = mmc_mk_box3(24, &DAE_Exp_ASUB__desc, _e, _inSubs);
tmpMeta[2] = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _tp, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 2: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,19,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmp3_2);
tmpMeta[3] = MMC_CDR(tmp3_2);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[4]);
if (!listEmpty(tmpMeta[3])) goto tmp2_end;
_eLst = tmpMeta[1];
_sub = tmp5;
if (!(_sub <= listLength(_eLst))) goto tmp2_end;
tmpMeta[0] = listGet(_eLst, _sub);
goto tmp2_done;
}
case 3: {
tmpMeta[0] = omc_ExpressionSimplify_simplifyAsubSlicing(threadData, _inExp, _inSubs);
goto tmp2_done;
}
case 4: {
{
modelica_metatype _exp;
for (tmpMeta[1] = _inSubs; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_exp = MMC_CAR(tmpMeta[1]);
omc_Expression_expInt(threadData, _exp);
}
}
tmpMeta[0] = omc_List_foldr(threadData, _inSubs, boxvar_ExpressionSimplify_simplifyAsub, _inExp);
goto tmp2_done;
}
case 5: {
modelica_boolean tmp22;
_hasRange = 0;
{
modelica_metatype __omcQ_24tmpVar55;
modelica_metatype* tmp6;
modelica_metatype __omcQ_24tmpVar54;
int tmp21;
modelica_metatype _exp_loopVar = 0;
modelica_metatype _exp;
_exp_loopVar = _inSubs;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar55 = tmpMeta[2];
tmp6 = &__omcQ_24tmpVar55;
while(1) {
tmp21 = 1;
if (!listEmpty(_exp_loopVar)) {
_exp = MMC_CAR(_exp_loopVar);
_exp_loopVar = MMC_CDR(_exp_loopVar);
tmp21--;
}
if (tmp21 == 0) {
{
modelica_metatype tmp9_1;
tmp9_1 = _exp;
{
volatile mmc_switch_type tmp9;
int tmp10;
tmp9 = 0;
for (; tmp9 < 2; tmp9++) {
switch (MMC_SWITCH_CAST(tmp9)) {
case 0: {
modelica_integer tmp11;
modelica_integer tmp12;
if (mmc__uniontype__metarecord__typedef__equal(tmp9_1,18,4) == 0) goto tmp8_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp9_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,1) == 0) goto tmp8_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmp11 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp9_1), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp9_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],0,1) == 0) goto tmp8_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
tmp12 = mmc_unbox_integer(tmpMeta[8]);
_istart = tmp11;
_step = tmpMeta[6];
_istop = tmp12;
{
modelica_metatype __omcQ_24tmpVar53;
modelica_metatype* tmp13;
modelica_metatype __omcQ_24tmpVar52;
int tmp14;
modelica_metatype _i_loopVar = 0;
modelica_integer tmp15 = 0;
modelica_metatype _i;
{
modelica_metatype tmp18_1;
tmp18_1 = _step;
{
volatile mmc_switch_type tmp18;
int tmp19;
tmp18 = 0;
for (; tmp18 < 2; tmp18++) {
switch (MMC_SWITCH_CAST(tmp18)) {
case 0: {
if (!optionNone(tmp18_1)) goto tmp17_end;
tmp15 = ((modelica_integer) 1);
goto tmp17_done;
}
case 1: {
modelica_integer tmp20;
if (optionNone(tmp18_1)) goto tmp17_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp18_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[7],0,1) == 0) goto tmp17_end;
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[7]), 2));
tmp20 = mmc_unbox_integer(tmpMeta[8]);
_istep = tmp20;
tmp15 = _istep;
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
}_i_loopVar = omc_ExpressionSimplify_simplifyRange(threadData, _istart, tmp15, _istop);
tmpMeta[5] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar53 = tmpMeta[5];
tmp13 = &__omcQ_24tmpVar53;
while(1) {
tmp14 = 1;
if (!listEmpty(_i_loopVar)) {
_i = MMC_CAR(_i_loopVar);
_i_loopVar = MMC_CDR(_i_loopVar);
tmp14--;
}
if (tmp14 == 0) {
tmpMeta[6] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, _i);
__omcQ_24tmpVar52 = tmpMeta[6];
*tmp13 = mmc_mk_cons(__omcQ_24tmpVar52,0);
tmp13 = &MMC_CDR(*tmp13);
} else if (tmp14 == 1) {
break;
} else {
goto goto_7;
}
}
*tmp13 = mmc_mk_nil();
tmpMeta[4] = __omcQ_24tmpVar53;
}
_e = omc_Expression_makeArray(threadData, tmpMeta[4], _OMC_LIT54, 1);
_hasRange = 1;
tmpMeta[3] = _e;
goto tmp8_done;
}
case 1: {
tmpMeta[3] = _exp;
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
}__omcQ_24tmpVar54 = tmpMeta[3];
*tmp6 = mmc_mk_cons(__omcQ_24tmpVar54,0);
tmp6 = &MMC_CDR(*tmp6);
} else if (tmp21 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp6 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar55;
}
_subs = tmpMeta[1];
tmp22 = _hasRange;
if (1 != tmp22) goto goto_1;
tmpMeta[1] = mmc_mk_box3(24, &DAE_Exp_ASUB__desc, _inExp, _subs);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _origExp;
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
if (++tmp3 < 7) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ExpressionSimplify_simplifyRSub(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fe)
{
modelica_metatype _e = NULL;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_e = __omcQ_24in_5Fe;
{
modelica_metatype tmp3_1;
tmp3_1 = _e;
{
modelica_metatype _cr = NULL;
modelica_metatype _exps = NULL;
modelica_metatype _comp = NULL;
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
modelica_metatype _vars = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,23,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp5 = mmc_unbox_integer(tmpMeta[3]);
if (-1 != tmp5) goto tmp2_end;
_cr = tmpMeta[2];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = mmc_mk_box3(9, &DAE_Exp_CREF__desc, omc_ComponentReference_joinCrefs(threadData, _cr, omc_ComponentReference_makeCrefIdent(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 5))), tmpMeta[1])), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 5))));
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,23,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],13,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],9,3) == 0) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],3,1) == 0) goto tmp2_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 3));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[9]);
if (-1 != tmp6) goto tmp2_end;
_p1 = tmpMeta[2];
_exps = tmpMeta[3];
_p2 = tmpMeta[7];
_vars = tmpMeta[8];
if (!omc_AbsynUtil_pathEqual(threadData, _p1, _p2)) goto tmp2_end;
{
modelica_metatype __omcQ_24tmpVar57;
modelica_metatype* tmp7;
modelica_string __omcQ_24tmpVar56;
int tmp8;
modelica_metatype _v_loopVar = 0;
modelica_metatype _v;
_v_loopVar = _vars;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar57 = tmpMeta[2];
tmp7 = &__omcQ_24tmpVar57;
while(1) {
tmp8 = 1;
if (!listEmpty(_v_loopVar)) {
_v = MMC_CAR(_v_loopVar);
_v_loopVar = MMC_CDR(_v_loopVar);
tmp8--;
}
if (tmp8 == 0) {
__omcQ_24tmpVar56 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_v), 2)));
*tmp7 = mmc_mk_cons(__omcQ_24tmpVar56,0);
tmp7 = &MMC_CDR(*tmp7);
} else if (tmp8 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp7 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar57;
}
tmpMeta[0] = listGet(_exps, omc_List_position1OnTrue(threadData, tmpMeta[1], boxvar_stringEq, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 4)))));
goto tmp2_done;
}
case 2: {
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,23,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],14,4) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp9 = mmc_unbox_integer(tmpMeta[4]);
if (-1 != tmp9) goto tmp2_end;
_exps = tmpMeta[2];
_comp = tmpMeta[3];
tmpMeta[0] = listGet(_exps, omc_List_position1OnTrue(threadData, _comp, boxvar_stringEq, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 4)))));
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _e;
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
_e = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _e;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyWork(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _options, modelica_metatype *out_outOptions)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outOptions = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,24,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e1 = tmpMeta[2];
_oe = tmpMeta[3];
tmpMeta[0+0] = omc_ExpressionSimplify_simplifySize(threadData, _inExp, _e1, _oe);
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 23: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,20,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_tp = tmpMeta[2];
_e = tmpMeta[3];
_e = omc_ExpressionSimplify_simplifyCast(threadData, _inExp, _e, _tp);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 24: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,21,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta[2];
_subs = tmpMeta[3];
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_op = tmpMeta[2];
_e1 = tmpMeta[3];
_e = omc_ExpressionSimplify_simplifyUnary(threadData, _inExp, _op, _e1);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta[2];
_op = tmpMeta[3];
_e2 = tmpMeta[4];
_e = omc_ExpressionSimplify_simplifyBinary(threadData, _inExp, _op, _e1, _e2);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 14: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,5) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp5 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
_e1 = tmpMeta[2];
_op = tmpMeta[3];
_e2 = tmpMeta[4];
_index_ = tmp5;
_isExpisASUB = tmpMeta[6];
_e = omc_ExpressionSimplify_simplifyRelation(threadData, _inExp, _op, _e1, _e2, _index_, _isExpisASUB);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_op = tmpMeta[2];
_e1 = tmpMeta[3];
_e = omc_ExpressionSimplify_simplifyUnary(threadData, _inExp, _op, _e1);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta[2];
_op = tmpMeta[3];
_e2 = tmpMeta[4];
_e = omc_ExpressionSimplify_simplifyLBinary(threadData, _inExp, _op, _e1, _e2);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_e3 = tmpMeta[4];
_e = omc_ExpressionSimplify_simplifyIfExp(threadData, _inExp, _e1, _e2, _e3);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_c_1 = tmpMeta[2];
_t = tmpMeta[3];
_e = omc_ExpressionSimplify_simplifyCref(threadData, _inExp, _c_1, _t);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _options;
goto tmp3_done;
}
case 30: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,27,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_reductionInfo = tmpMeta[2];
_e1 = tmpMeta[3];
_riters = tmpMeta[4];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_riters = omc_ExpressionSimplify_simplifyReductionIterators(threadData, _riters, tmpMeta[2], 0 ,&_b2);
tmp6 = (modelica_boolean)_b2;
if(tmp6)
{
tmpMeta[2] = mmc_mk_box4(30, &DAE_Exp_REDUCTION__desc, _reductionInfo, _e1, _riters);
tmpMeta[3] = tmpMeta[2];
}
else
{
tmpMeta[3] = _inExp;
}
_exp1 = tmpMeta[3];
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
modelica_boolean tmp1;
modelica_string tmp2;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_t1 = mmc_clock();
_outE = omc_ExpressionSimplify_simplify1(threadData, _e, NULL);
_t2 = mmc_clock();
tmp1 = (modelica_boolean)(_t2 - _t1 > 0.01);
if(tmp1)
{
tmpMeta[0] = stringAppend(_OMC_LIT173,realString(_t2 - _t1));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT174);
tmpMeta[2] = stringAppend(tmpMeta[1],omc_ExpressionDump_printExpStr(threadData, _e));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT175);
tmpMeta[4] = stringAppend(tmpMeta[3],omc_ExpressionDump_printExpStr(threadData, _outE));
tmpMeta[5] = stringAppend(tmpMeta[4],_OMC_LIT176);
tmp2 = tmpMeta[5];
}
else
{
tmp2 = _OMC_LIT70;
}
fputs(MMC_STRINGDATA(tmp2),stdout);
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,0) == 0) goto tmp3_end;
_e = tmp4_1;
_eNew = omc_ExpressionSimplify_simplify1WithOptions(threadData, _e, _options, NULL);
omc_Error_assertionOrAddSourceMessage(threadData, omc_Expression_isConstValue(threadData, _eNew), _OMC_LIT4, _OMC_LIT178, _OMC_LIT92);
_b = (!omc_Expression_expEqual(threadData, _e, _eNew));
tmpMeta[0+0] = _eNew;
tmp1_c1 = _b;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
_e = tmp4_1;
tmp6 = omc_Config_getNoSimplify(threadData);
if (0 != tmp6) goto goto_2;
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
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
modelica_metatype _e1 = NULL;
modelica_metatype _op = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_op = tmpMeta[1];
_e1 = tmpMeta[2];
tmpMeta[0] = omc_ExpressionSimplify_simplifyUnary(threadData, _inExp, _op, _e1);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inExp;
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
DLLExport
modelica_metatype omc_ExpressionSimplify_simplifyBinaryExp(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _op = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,7,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
tmpMeta[0] = omc_ExpressionSimplify_simplifyBinary(threadData, _inExp, _op, _e1, _e2);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inExp;
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
_outExp = tmpMeta[0];
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
_ioExp = omc_ExpressionSimplify_simplifyWithOptions(threadData, _ioExp, _OMC_LIT159 ,&_hasChanged);
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
_outExp = omc_ExpressionSimplify_simplifyWithOptions(threadData, _inExp, _OMC_LIT159 ,&_hasChanged);
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
