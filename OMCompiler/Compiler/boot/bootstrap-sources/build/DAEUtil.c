#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/DAEUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "DAEUtil.h"
#define _OMC_LIT0_data "mergeAlgSections"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,16,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "Disables coloring algorithm while sparsity detection."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,53,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT2,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT1}};
#define _OMC_LIT2 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT2)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT3,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(169)),_OMC_LIT0,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT2}};
#define _OMC_LIT3 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT3)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT4,1,4) {&SCode_ConnectorType_FLOW__desc,}};
#define _OMC_LIT4 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT4)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT5,1,5) {&SCode_ConnectorType_STREAM__desc,}};
#define _OMC_LIT5 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT5)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT6,1,3) {&SCode_ConnectorType_POTENTIAL__desc,}};
#define _OMC_LIT6 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,0,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "flow"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,4,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "stream()"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,8,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "stream("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,7,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data ")"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,1,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "non connector"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,13,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT13,1,3) {&DAE_VarInnerOuter_INNER__desc,}};
#define _OMC_LIT13 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT13)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT14,1,4) {&DAE_VarInnerOuter_OUTER__desc,}};
#define _OMC_LIT14 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT14)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT15,1,5) {&DAE_VarInnerOuter_INNER__OUTER__desc,}};
#define _OMC_LIT15 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT15)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT16,1,6) {&DAE_VarInnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT16 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT16)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT17,1,6) {&DAE_ConnectorType_NON__CONNECTOR__desc,}};
#define _OMC_LIT17 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT17)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT18,1,5) {&SCode_Parallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT18 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT18)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT19,1,3) {&SCode_Variability_VAR__desc,}};
#define _OMC_LIT19 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT19)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT20,1,5) {&Absyn_Direction_BIDIR__desc,}};
#define _OMC_LIT20 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT20)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT21,1,6) {&Absyn_InnerOuter_NOT__INNER__OUTER__desc,}};
#define _OMC_LIT21 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,1,3) {&SCode_Visibility_PUBLIC__desc,}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,7,3) {&DAE_Attributes_ATTR__desc,_OMC_LIT17,_OMC_LIT18,_OMC_LIT19,_OMC_LIT20,_OMC_LIT21,_OMC_LIT22}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT24,1,11) {&DAE_Type_T__UNKNOWN__desc,}};
#define _OMC_LIT24 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT24)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT25,1,3) {&DAE_Binding_UNBOUND__desc,}};
#define _OMC_LIT25 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data "\n  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,3,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data "Cache has: \n  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,14,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
#define _OMC_LIT28_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT28,1,_OMC_LIT28_data);
#define _OMC_LIT28 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT28)
#define _OMC_LIT29_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT29,1,_OMC_LIT29_data);
#define _OMC_LIT29 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data " [invalid]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,10,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
#define _OMC_LIT31_data " [valid]  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT31,10,_OMC_LIT31_data);
#define _OMC_LIT31 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT31)
#define _OMC_LIT32_data "[DEFAULT VALUE]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT32,15,_OMC_LIT32_data);
#define _OMC_LIT32 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "[RECORD SUBMOD]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,15,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data "[START VALUE]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,13,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
#define _OMC_LIT35_data " = "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT35,3,_OMC_LIT35_data);
#define _OMC_LIT35 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,2,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,1,6) {&ErrorTypes_Severity_NOTIFICATION__desc,}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
#define _OMC_LIT39_data "The following structural parameters were evaluated in the front-end: %s\nStructural parameters are parameters used to calculate array dimensions or branch selection in certain if-equations or if-expressions among other things."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT39,225,_OMC_LIT39_data);
#define _OMC_LIT39 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT39}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(272)),_OMC_LIT37,_OMC_LIT38,_OMC_LIT40}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "printStructuralParameters"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,25,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "Prints the structural parameters identified by the front-end"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,60,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT44,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT43}};
#define _OMC_LIT44 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(103)),_OMC_LIT42,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT44}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "newInst"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,7,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
#define _OMC_LIT47_data "Enables experimental new instantiation phase."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT47,45,_OMC_LIT47_data);
#define _OMC_LIT47 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT47}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(67)),_OMC_LIT46,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT48}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT50,0.0);
#define _OMC_LIT50 MMC_REFREALLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT7,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT50}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,1,4) {&DAE_ComponentPrefix_NOCOMPPRE__desc,}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT53,8,3) {&DAE_ElementSource_SOURCE__desc,_OMC_LIT51,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT52,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT53 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT53)
#define _OMC_LIT54_data "stateMachine"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT54,12,_OMC_LIT54_data);
#define _OMC_LIT54 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT54)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT55,1,1) {_OMC_LIT54}};
#define _OMC_LIT55 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,3,3) {&SCode_Comment_COMMENT__desc,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT55}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT57,1,1) {_OMC_LIT56}};
#define _OMC_LIT57 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "state"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,5,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT59,1,1) {_OMC_LIT58}};
#define _OMC_LIT59 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT59)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT60,3,3) {&SCode_Comment_COMMENT__desc,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT59}};
#define _OMC_LIT60 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT60)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT61,1,1) {_OMC_LIT60}};
#define _OMC_LIT61 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "DAEUtil.splitElements got unknown element."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,42,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
#define _OMC_LIT63_data "infoXmlOperations"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT63,17,_OMC_LIT63_data);
#define _OMC_LIT63 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT63)
#define _OMC_LIT64_data "Enables output of the operations in the _info.xml file when translating models."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT64,79,_OMC_LIT64_data);
#define _OMC_LIT64 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT64)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT65,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT64}};
#define _OMC_LIT65 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT65)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT66,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(95)),_OMC_LIT63,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT65}};
#define _OMC_LIT66 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT66)
#define _OMC_LIT67_data "visxml"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT67,6,_OMC_LIT67_data);
#define _OMC_LIT67 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT67)
#define _OMC_LIT68_data "Outputs a xml-file that contains information for visualization."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT68,63,_OMC_LIT68_data);
#define _OMC_LIT68 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT68)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT69,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT68}};
#define _OMC_LIT69 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT69)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT70,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(129)),_OMC_LIT67,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT69}};
#define _OMC_LIT70 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT70)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT71,1,3) {&DAE_Else_NOELSE__desc,}};
#define _OMC_LIT71 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT71)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT72,2,3) {&DAE_Exp_ICONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(-1))}};
#define _OMC_LIT72 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT72)
#define _OMC_LIT73_data "DAEUtil.traverseDAEStmts not implemented correctly: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT73,52,_OMC_LIT73_data);
#define _OMC_LIT73 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT73)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT74,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT74 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT74)
#define _OMC_LIT75_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT75,17,_OMC_LIT75_data);
#define _OMC_LIT75 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT75)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT76,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT75}};
#define _OMC_LIT76 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT76)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT77,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT37,_OMC_LIT74,_OMC_LIT76}};
#define _OMC_LIT77 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT77)
#define _OMC_LIT78_data "DAEUtil.traverseDAEEquationsStmts not implemented correctly: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT78,61,_OMC_LIT78_data);
#define _OMC_LIT78 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT78)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT79,1,4) {&DAEUtil_TraverseStatementsOptions_TRAVERSE__RHS__ONLY__desc,}};
#define _OMC_LIT79 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT79)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT80,1,3) {&DAEUtil_TraverseStatementsOptions_TRAVERSE__ALL__desc,}};
#define _OMC_LIT80 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT80)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT81,1,3) {&DAE_Const_C__CONST__desc,}};
#define _OMC_LIT81 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT81)
#define _OMC_LIT82_data "DAEUtil.traverseDAEElement not implemented correctly for element: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT82,66,_OMC_LIT82_data);
#define _OMC_LIT82 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT82)
#define _OMC_LIT83_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT83,9,_OMC_LIT83_data);
#define _OMC_LIT83 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT83)
#define _OMC_LIT84_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT84,41,_OMC_LIT84_data);
#define _OMC_LIT84 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT84)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT85,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT84}};
#define _OMC_LIT85 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT85)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT86,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT83,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT85}};
#define _OMC_LIT86 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT86)
#define _OMC_LIT87_data "- DAEUtil.traverseDAEFuncLst failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT87,37,_OMC_LIT87_data);
#define _OMC_LIT87 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT87)
#define _OMC_LIT88_data "\n "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT88,2,_OMC_LIT88_data);
#define _OMC_LIT88 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT88)
#define _OMC_LIT89_data "Tried to use function %s, but it was not instantiated."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT89,54,_OMC_LIT89_data);
#define _OMC_LIT89 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT89)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT90,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT89}};
#define _OMC_LIT90 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT90)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT91,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(5009)),_OMC_LIT37,_OMC_LIT74,_OMC_LIT90}};
#define _OMC_LIT91 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT91)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT92,1,5) {&DAE_AvlTreePathFunction_Tree_EMPTY__desc,}};
#define _OMC_LIT92 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT92)
#define _OMC_LIT93_data "$unique$outer$"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT93,14,_OMC_LIT93_data);
#define _OMC_LIT93 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT93)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT94,1,4) {&Absyn_Msg_NO__MSG__desc,}};
#define _OMC_LIT94 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT94)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT95,1,5) {&DAE_VarKind_PARAM__desc,}};
#define _OMC_LIT95 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT95)
#define _OMC_LIT96_data "Evaluate"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT96,8,_OMC_LIT96_data);
#define _OMC_LIT96 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT96)
#define _OMC_LIT97_data "Invalid left-hand side of when-equation: %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT97,44,_OMC_LIT97_data);
#define _OMC_LIT97 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT97)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT98,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT97}};
#define _OMC_LIT98 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT98)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT99,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(158)),_OMC_LIT37,_OMC_LIT74,_OMC_LIT98}};
#define _OMC_LIT99 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT99)
#define _OMC_LIT100_data "All branches must write to the same variable"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT100,44,_OMC_LIT100_data);
#define _OMC_LIT100 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT100)
#define _OMC_LIT101_data "Using reinit in when with condition initial() is not allowed. Use assignment or equality equation instead."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT101,106,_OMC_LIT101_data);
#define _OMC_LIT101 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT101)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT102,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT101}};
#define _OMC_LIT102 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT102)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT103,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(531)),_OMC_LIT37,_OMC_LIT74,_OMC_LIT102}};
#define _OMC_LIT103 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT103)
#define _OMC_LIT104_data "Nested when statements are not allowed."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT104,39,_OMC_LIT104_data);
#define _OMC_LIT104 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT104)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT105,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT104}};
#define _OMC_LIT105 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT105)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT106,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(126)),_OMC_LIT37,_OMC_LIT74,_OMC_LIT105}};
#define _OMC_LIT106 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT106)
#define _OMC_LIT107_data "Clocked when equation inside the body of when equation."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT107,55,_OMC_LIT107_data);
#define _OMC_LIT107 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT107)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT108,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT107}};
#define _OMC_LIT108 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT108)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT109,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(566)),_OMC_LIT37,_OMC_LIT74,_OMC_LIT108}};
#define _OMC_LIT109 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT109)
#define _OMC_LIT110_data "- DAEUtil.verifyWhenEquationStatements failed on: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT110,50,_OMC_LIT110_data);
#define _OMC_LIT110 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT110)
#define _OMC_LIT111_data "- DAEUtil.collectWhenEquationBranches failed on: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT111,49,_OMC_LIT111_data);
#define _OMC_LIT111 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT111)
#define _OMC_LIT112_data "Clocked when branch in when equation."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT112,37,_OMC_LIT112_data);
#define _OMC_LIT112 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT112)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT113,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT112}};
#define _OMC_LIT113 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT113)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT114,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(565)),_OMC_LIT37,_OMC_LIT74,_OMC_LIT113}};
#define _OMC_LIT114 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT114)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT115,1,6) {&ErrorTypes_MessageType_SYMBOLIC__desc,}};
#define _OMC_LIT115 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT115)
#define _OMC_LIT116_data "The same variables must be solved in elsewhen clause as in the when clause."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT116,75,_OMC_LIT116_data);
#define _OMC_LIT116 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT116)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT117,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT116}};
#define _OMC_LIT117 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT117)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT118,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(95)),_OMC_LIT115,_OMC_LIT74,_OMC_LIT117}};
#define _OMC_LIT118 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT118)
#define _OMC_LIT119_data "Operator reinit may only be used in the body of a when equation."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT119,64,_OMC_LIT119_data);
#define _OMC_LIT119 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT119)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT120,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT119}};
#define _OMC_LIT120 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT120)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT121,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(563)),_OMC_LIT37,_OMC_LIT74,_OMC_LIT120}};
#define _OMC_LIT121 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT121)
#define _OMC_LIT122_data "Nested clocked when statements are not allowed."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT122,47,_OMC_LIT122_data);
#define _OMC_LIT122 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT122)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT123,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT122}};
#define _OMC_LIT123 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT123)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT124,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(564)),_OMC_LIT37,_OMC_LIT74,_OMC_LIT123}};
#define _OMC_LIT124 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT124)
#define _OMC_LIT125_data "Clocked when equation can not contain elsewhen part."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT125,52,_OMC_LIT125_data);
#define _OMC_LIT125 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT125)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT126,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT125}};
#define _OMC_LIT126 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT126)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT127,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(562)),_OMC_LIT37,_OMC_LIT74,_OMC_LIT126}};
#define _OMC_LIT127 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT127)
#define _OMC_LIT128_data "- Differentiatte.getStatement failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT128,37,_OMC_LIT128_data);
#define _OMC_LIT128 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT128)
#define _OMC_LIT129_data "- DAEUtil.getNamedFunctionFromList failed "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT129,42,_OMC_LIT129_data);
#define _OMC_LIT129 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT129)
#define _OMC_LIT130_data "DAEUtil.getNamedFunction failed: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT130,33,_OMC_LIT130_data);
#define _OMC_LIT130 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT130)
#define _OMC_LIT131_data "\nThe following functions were part of the cache:\n  "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT131,51,_OMC_LIT131_data);
#define _OMC_LIT131 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT131)
#define _OMC_LIT132_data "_"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT132,1,_OMC_LIT132_data);
#define _OMC_LIT132 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT132)
#define _OMC_LIT133_data "to_modelica_form_elts(ALGORITHM) not impl. yet\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT133,47,_OMC_LIT133_data);
#define _OMC_LIT133 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT133)
#define _OMC_LIT134_data "to_modelica_form_elts(INITIALALGORITHM) not impl. yet\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT134,54,_OMC_LIT134_data);
#define _OMC_LIT134 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT134)
#define _OMC_LIT135_data "- DAEUtil.daeToRecordValue failed on: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT135,38,_OMC_LIT135_data);
#define _OMC_LIT135 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT135)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT136,1,5) {&DAE_VarParallelism_NON__PARALLEL__desc,}};
#define _OMC_LIT136 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT136)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT137,1,3) {&DAE_VarParallelism_PARGLOBAL__desc,}};
#define _OMC_LIT137 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT137)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT138,1,4) {&DAE_VarParallelism_PARLOCAL__desc,}};
#define _OMC_LIT138 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT138)
#define _OMC_LIT139_data "\n- DAEUtil.toDaeParallelism: parglobal component '"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT139,50,_OMC_LIT139_data);
#define _OMC_LIT139 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT139)
#define _OMC_LIT140_data "' in non-function class: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT140,25,_OMC_LIT140_data);
#define _OMC_LIT140 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT140)
#define _OMC_LIT141_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT141,1,_OMC_LIT141_data);
#define _OMC_LIT141 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT141)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT142,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT142 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT142)
#define _OMC_LIT143_data "ParModelica: %s."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT143,16,_OMC_LIT143_data);
#define _OMC_LIT143 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT143)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT144,2,4) {&Gettext_TranslatableContent_notrans__desc,_OMC_LIT143}};
#define _OMC_LIT144 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT144)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT145,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(7004)),_OMC_LIT37,_OMC_LIT142,_OMC_LIT144}};
#define _OMC_LIT145 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT145)
#define _OMC_LIT146_data "\n- DAEUtil.toDaeParallelism: parlocal component '"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT146,49,_OMC_LIT146_data);
#define _OMC_LIT146 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT146)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT147,1,4) {&DAE_ConnectorType_FLOW__desc,}};
#define _OMC_LIT147 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT147)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT148,1,3) {&DAE_ConnectorType_POTENTIAL__desc,}};
#define _OMC_LIT148 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT148)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT149,2,5) {&DAE_ConnectorType_STREAM__desc,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT149 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT149)
#define _OMC_LIT150_data " error in getBindings \n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT150,23,_OMC_LIT150_data);
#define _OMC_LIT150 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT150)
#define _OMC_LIT151_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT151,1,_OMC_LIT151_data);
#define _OMC_LIT151 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT151)
#define _OMC_LIT152_data "-,"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT152,2,_OMC_LIT152_data);
#define _OMC_LIT152 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT152)
#define _OMC_LIT153_data "- DAEUtil.boolVarVisibility failed\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT153,35,_OMC_LIT153_data);
#define _OMC_LIT153 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT153)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT154,16,3) {&DAE_VariableAttributes_VAR__ATTR__REAL__desc,MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none),MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT154 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT154)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT155,1,1) {_OMC_LIT154}};
#define _OMC_LIT155 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT155)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT156,1.0);
#define _OMC_LIT156 MMC_REFREALLIT(_OMC_LIT_STRUCT156)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT157,2,4) {&DAE_Exp_RCONST__desc,_OMC_LIT156}};
#define _OMC_LIT157 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT157)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT158,2,4) {&DAE_Exp_RCONST__desc,_OMC_LIT50}};
#define _OMC_LIT158 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT158)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT159,2,5) {&DAE_Exp_SCONST__desc,_OMC_LIT7}};
#define _OMC_LIT159 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT159)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT160,1,4) {&Absyn_InnerOuter_OUTER__desc,}};
#define _OMC_LIT160 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT160)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT161,1,7) {&DAE_ComponentRef_WILD__desc,}};
#define _OMC_LIT161 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT161)
#define _OMC_LIT162_data " failure unNameInnerouterUniqueCref: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT162,37,_OMC_LIT162_data);
#define _OMC_LIT162 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT162)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT163,2,3) {&DAE_DAElist_DAE__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT163 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT163)
#define _OMC_LIT164_data "DAEUtil.splitDAEIntoVarsAndEquations failed for "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT164,48,_OMC_LIT164_data);
#define _OMC_LIT164 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT164)
#define _OMC_LIT165_data "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/FrontEnd/DAEUtil.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT165,68,_OMC_LIT165_data);
#define _OMC_LIT165 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT165)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT166_6,1605721860.0);
#define _OMC_LIT166_6 MMC_REFREALLIT(_OMC_LIT_STRUCT166_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT166,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT165,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(520)),MMC_IMMEDIATE(MMC_TAGFIXNUM(11)),MMC_IMMEDIATE(MMC_TAGFIXNUM(520)),MMC_IMMEDIATE(MMC_TAGFIXNUM(128)),_OMC_LIT166_6}};
#define _OMC_LIT166 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT166)
#define _OMC_LIT167_data "-failure in DAEUtil.addEquationBoundString\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT167,43,_OMC_LIT167_data);
#define _OMC_LIT167 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT167)
#define _OMC_LIT168_data "Dimensions must be parameter or constant expression (in %s)."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT168,60,_OMC_LIT168_data);
#define _OMC_LIT168 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT168)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT169,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT168}};
#define _OMC_LIT169 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT169)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT170,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(23)),_OMC_LIT37,_OMC_LIT74,_OMC_LIT169}};
#define _OMC_LIT170 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT170)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT171,1,4) {&DAE_Connect_Face_OUTSIDE__desc,}};
#define _OMC_LIT171 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT171)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT172,1,3) {&DAE_VarVisibility_PUBLIC__desc,}};
#define _OMC_LIT172 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT172)
#define _OMC_LIT173_data "parglobal "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT173,10,_OMC_LIT173_data);
#define _OMC_LIT173 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT173)
#define _OMC_LIT174_data "parlocal "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT174,9,_OMC_LIT174_data);
#define _OMC_LIT174 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT174)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT175,1,3) {&DAE_VarKind_VARIABLE__desc,}};
#define _OMC_LIT175 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT175)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT176,1,6) {&DAE_VarKind_CONST__desc,}};
#define _OMC_LIT176 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT176)
#define _OMC_LIT177_data "parameter "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT177,10,_OMC_LIT177_data);
#define _OMC_LIT177 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT177)
#define _OMC_LIT178_data "constant "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT178,9,_OMC_LIT178_data);
#define _OMC_LIT178 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT178)
#define _OMC_LIT179_data "VAR"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT179,3,_OMC_LIT179_data);
#define _OMC_LIT179 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT179)
#define _OMC_LIT180_data "PARAM"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT180,5,_OMC_LIT180_data);
#define _OMC_LIT180 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT180)
#define _OMC_LIT181_data "CONST"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT181,5,_OMC_LIT181_data);
#define _OMC_LIT181 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT181)
#include "util/modelica.h"
#include "DAEUtil_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_replaceCompRef(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _replIn, modelica_metatype *out_replOut);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_replaceCompRef,2,0) {(void*) boxptr_DAEUtil_replaceCompRef,0}};
#define boxvar_DAEUtil_replaceCompRef MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_replaceCompRef)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_statementsContainTryBlock2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inStmt, modelica_boolean _b, modelica_boolean *out_ob);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_statementsContainTryBlock2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inStmt, modelica_metatype _b, modelica_metatype *out_ob);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_statementsContainTryBlock2,2,0) {(void*) boxptr_DAEUtil_statementsContainTryBlock2,0}};
#define boxvar_DAEUtil_statementsContainTryBlock2 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_statementsContainTryBlock2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_statementsContainReturn2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inStmt, modelica_boolean _b, modelica_boolean *out_ob);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_statementsContainReturn2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inStmt, modelica_metatype _b, modelica_metatype *out_ob);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_statementsContainReturn2,2,0) {(void*) boxptr_DAEUtil_statementsContainReturn2,0}};
#define boxvar_DAEUtil_statementsContainReturn2 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_statementsContainReturn2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_collectAllExpandableCrefsInExp(threadData_t *threadData, modelica_metatype _exp, modelica_metatype _acc, modelica_metatype *out_outCrefs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_collectAllExpandableCrefsInExp,2,0) {(void*) boxptr_DAEUtil_collectAllExpandableCrefsInExp,0}};
#define boxvar_DAEUtil_collectAllExpandableCrefsInExp MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_collectAllExpandableCrefsInExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_splitVariableNamed(threadData_t *threadData, modelica_metatype _inElementLst, modelica_string _inName, modelica_metatype _inAccNamed, modelica_metatype _inAccRest, modelica_metatype *out_outRest);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_splitVariableNamed,2,0) {(void*) boxptr_DAEUtil_splitVariableNamed,0}};
#define boxvar_DAEUtil_splitVariableNamed MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_splitVariableNamed)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_sortDAEElementsInModelicaCodeOrder(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inDaeEls);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_sortDAEElementsInModelicaCodeOrder,2,0) {(void*) boxptr_DAEUtil_sortDAEElementsInModelicaCodeOrder,0}};
#define boxvar_DAEUtil_sortDAEElementsInModelicaCodeOrder MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_sortDAEElementsInModelicaCodeOrder)
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_showCacheFuncs(threadData_t *threadData, modelica_metatype _tree);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_showCacheFuncs,2,0) {(void*) boxptr_DAEUtil_showCacheFuncs,0}};
#define boxvar_DAEUtil_showCacheFuncs MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_showCacheFuncs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_makeEvaluatedParamFinal(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _ht);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_makeEvaluatedParamFinal,2,0) {(void*) boxptr_DAEUtil_makeEvaluatedParamFinal,0}};
#define boxvar_DAEUtil_makeEvaluatedParamFinal MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_makeEvaluatedParamFinal)
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_transformationsBeforeBackendNotification(threadData_t *threadData, modelica_metatype _ht);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_transformationsBeforeBackendNotification,2,0) {(void*) boxptr_DAEUtil_transformationsBeforeBackendNotification,0}};
#define boxvar_DAEUtil_transformationsBeforeBackendNotification MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_transformationsBeforeBackendNotification)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getDAEDeclsFromValueblocks(threadData_t *threadData, modelica_metatype _exps);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_getDAEDeclsFromValueblocks,2,0) {(void*) boxptr_DAEUtil_getDAEDeclsFromValueblocks,0}};
#define boxvar_DAEUtil_getDAEDeclsFromValueblocks MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_getDAEDeclsFromValueblocks)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getUniontypePathsElements(threadData_t *threadData, modelica_metatype _elements, modelica_metatype _acc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_getUniontypePathsElements,2,0) {(void*) boxptr_DAEUtil_getUniontypePathsElements,0}};
#define boxvar_DAEUtil_getUniontypePathsElements MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_getUniontypePathsElements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getUniontypePathsFunctions(threadData_t *threadData, modelica_metatype _elements);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_getUniontypePathsFunctions,2,0) {(void*) boxptr_DAEUtil_getUniontypePathsFunctions,0}};
#define boxvar_DAEUtil_getUniontypePathsFunctions MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_getUniontypePathsFunctions)
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_isIfEquation(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_isIfEquation,2,0) {(void*) boxptr_DAEUtil_isIfEquation,0}};
#define boxvar_DAEUtil_isIfEquation MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_isIfEquation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_addComponentType2(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felt, modelica_metatype _inPath);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_addComponentType2,2,0) {(void*) boxptr_DAEUtil_addComponentType2,0}};
#define boxvar_DAEUtil_addComponentType2 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_addComponentType2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEVarAttr(threadData_t *threadData, modelica_metatype _attr, modelica_fnptr _func, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEVarAttr,2,0) {(void*) boxptr_DAEUtil_traverseDAEVarAttr,0}};
#define boxvar_DAEUtil_traverseDAEVarAttr MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEVarAttr)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEExpListStmt(threadData_t *threadData, modelica_metatype _iexps, modelica_fnptr _func, modelica_metatype _istmt, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEExpListStmt,2,0) {(void*) boxptr_DAEUtil_traverseDAEExpListStmt,0}};
#define boxvar_DAEUtil_traverseDAEExpListStmt MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEExpListStmt)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEStmtsElse(threadData_t *threadData, modelica_metatype _inElse, modelica_fnptr _func, modelica_metatype _istmt, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEStmtsElse,2,0) {(void*) boxptr_DAEUtil_traverseDAEStmtsElse,0}};
#define boxvar_DAEUtil_traverseDAEStmtsElse MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEStmtsElse)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEEquationsStmtsElse(threadData_t *threadData, modelica_metatype _inElse, modelica_fnptr _func, modelica_metatype _opt, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEEquationsStmtsElse,2,0) {(void*) boxptr_DAEUtil_traverseDAEEquationsStmtsElse,0}};
#define boxvar_DAEUtil_traverseDAEEquationsStmtsElse MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEEquationsStmtsElse)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEEquationsStmtsWork(threadData_t *threadData, modelica_metatype _inStmt, modelica_fnptr _func, modelica_metatype _opt, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEEquationsStmtsWork,2,0) {(void*) boxptr_DAEUtil_traverseDAEEquationsStmtsWork,0}};
#define boxvar_DAEUtil_traverseDAEEquationsStmtsWork MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEEquationsStmtsWork)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseStatementsOptionsEvalLhs(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inA, modelica_fnptr _func, modelica_metatype _opt, modelica_metatype *out_outA);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseStatementsOptionsEvalLhs,2,0) {(void*) boxptr_DAEUtil_traverseStatementsOptionsEvalLhs,0}};
#define boxvar_DAEUtil_traverseStatementsOptionsEvalLhs MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseStatementsOptionsEvalLhs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEEquationsStmtsList(threadData_t *threadData, modelica_metatype _inStmts, modelica_fnptr _func, modelica_metatype _opt, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEEquationsStmtsList,2,0) {(void*) boxptr_DAEUtil_traverseDAEEquationsStmtsList,0}};
#define boxvar_DAEUtil_traverseDAEEquationsStmtsList MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEEquationsStmtsList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEElement,2,0) {(void*) boxptr_DAEUtil_traverseDAEElement,0}};
#define boxvar_DAEUtil_traverseDAEElement MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEFunc(threadData_t *threadData, modelica_metatype __omcQ_24in_5FdaeFunction, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEFunc,2,0) {(void*) boxptr_DAEUtil_traverseDAEFunc,0}};
#define boxvar_DAEUtil_traverseDAEFunc MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEFunc)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEFuncHelper(threadData_t *threadData, modelica_metatype _key, modelica_metatype __omcQ_24in_5Fvalue, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEFuncHelper,2,0) {(void*) boxptr_DAEUtil_traverseDAEFuncHelper,0}};
#define boxvar_DAEUtil_traverseDAEFuncHelper MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEFuncHelper)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_DAEUtil_isValidFunctionEntry(threadData_t *threadData, modelica_metatype _tpl);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_isValidFunctionEntry(threadData_t *threadData, modelica_metatype _tpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_isValidFunctionEntry,2,0) {(void*) boxptr_DAEUtil_isValidFunctionEntry,0}};
#define boxvar_DAEUtil_isValidFunctionEntry MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_isValidFunctionEntry)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_DAEUtil_isInvalidFunctionEntry(threadData_t *threadData, modelica_metatype _tpl);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_isInvalidFunctionEntry(threadData_t *threadData, modelica_metatype _tpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_isInvalidFunctionEntry,2,0) {(void*) boxptr_DAEUtil_isInvalidFunctionEntry,0}};
#define boxvar_DAEUtil_isInvalidFunctionEntry MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_isInvalidFunctionEntry)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEList(threadData_t *threadData, modelica_metatype _idaeList, modelica_fnptr _func, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEList,2,0) {(void*) boxptr_DAEUtil_traverseDAEList,0}};
#define boxvar_DAEUtil_traverseDAEList MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEExpList(threadData_t *threadData, modelica_metatype _iexps, modelica_fnptr _func, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEExpList,2,0) {(void*) boxptr_DAEUtil_traverseDAEExpList,0}};
#define boxvar_DAEUtil_traverseDAEExpList MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEExpList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEOptExp(threadData_t *threadData, modelica_metatype _oexp, modelica_fnptr _func, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEOptExp,2,0) {(void*) boxptr_DAEUtil_traverseDAEOptExp,0}};
#define boxvar_DAEUtil_traverseDAEOptExp MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_traverseDAEOptExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_addUniqueIdentifierToCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _oarg, modelica_metatype *out_outDummy);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_addUniqueIdentifierToCref,2,0) {(void*) boxptr_DAEUtil_addUniqueIdentifierToCref,0}};
#define boxvar_DAEUtil_addUniqueIdentifierToCref MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_addUniqueIdentifierToCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_removeUniqieIdentifierFromCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _oarg, modelica_metatype *out_outDummy);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_removeUniqieIdentifierFromCref,2,0) {(void*) boxptr_DAEUtil_removeUniqieIdentifierFromCref,0}};
#define boxvar_DAEUtil_removeUniqieIdentifierFromCref MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_removeUniqieIdentifierFromCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotation4(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inCr, modelica_metatype _inExp, modelica_integer _inInteger1, modelica_integer _inInteger2, modelica_metatype _inHt, modelica_metatype *out_outHt, modelica_metatype *out_outCache);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_evaluateAnnotation4(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inCr, modelica_metatype _inExp, modelica_metatype _inInteger1, modelica_metatype _inInteger2, modelica_metatype _inHt, modelica_metatype *out_outHt, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotation4,2,0) {(void*) boxptr_DAEUtil_evaluateAnnotation4,0}};
#define boxvar_DAEUtil_evaluateAnnotation4 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotation4)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotation3(threadData_t *threadData, modelica_metatype _iel, modelica_metatype _inHt, modelica_metatype *out_outHt);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotation3,2,0) {(void*) boxptr_DAEUtil_evaluateAnnotation3,0}};
#define boxvar_DAEUtil_evaluateAnnotation3 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotation3)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotation2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inDAElist, modelica_metatype _inHt, modelica_metatype *out_outHt, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotation2,2,0) {(void*) boxptr_DAEUtil_evaluateAnnotation2,0}};
#define boxvar_DAEUtil_evaluateAnnotation2 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotation2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotation2__loop1(threadData_t *threadData, modelica_boolean _finish, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inDAElist, modelica_metatype _inHt, modelica_integer _sizeBefore, modelica_metatype *out_outHt, modelica_metatype *out_outCache);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_evaluateAnnotation2__loop1(threadData_t *threadData, modelica_metatype _finish, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inDAElist, modelica_metatype _inHt, modelica_metatype _sizeBefore, modelica_metatype *out_outHt, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotation2__loop1,2,0) {(void*) boxptr_DAEUtil_evaluateAnnotation2__loop1,0}};
#define boxvar_DAEUtil_evaluateAnnotation2__loop1 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotation2__loop1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotation2__loop(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inDAElist, modelica_metatype _inHt, modelica_integer _sizeBefore, modelica_metatype *out_outHt, modelica_metatype *out_outCache);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_evaluateAnnotation2__loop(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inDAElist, modelica_metatype _inHt, modelica_metatype _sizeBefore, modelica_metatype *out_outHt, modelica_metatype *out_outCache);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotation2__loop,2,0) {(void*) boxptr_DAEUtil_evaluateAnnotation2__loop,0}};
#define boxvar_DAEUtil_evaluateAnnotation2__loop MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotation2__loop)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateParameter(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inPV);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateParameter,2,0) {(void*) boxptr_DAEUtil_evaluateParameter,0}};
#define boxvar_DAEUtil_evaluateParameter MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateParameter)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotation1Fold(threadData_t *threadData, modelica_metatype _tpl, modelica_metatype _el, modelica_metatype _inPV);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotation1Fold,2,0) {(void*) boxptr_DAEUtil_evaluateAnnotation1Fold,0}};
#define boxvar_DAEUtil_evaluateAnnotation1Fold MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotation1Fold)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getParameterVars2(threadData_t *threadData, modelica_metatype _elt, modelica_metatype _ht);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_getParameterVars2,2,0) {(void*) boxptr_DAEUtil_getParameterVars2,0}};
#define boxvar_DAEUtil_getParameterVars2 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_getParameterVars2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_replaceCrefInAnnotation(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTable);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_replaceCrefInAnnotation,2,0) {(void*) boxptr_DAEUtil_replaceCrefInAnnotation,0}};
#define boxvar_DAEUtil_replaceCrefInAnnotation MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_replaceCrefInAnnotation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotationTraverse(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _itpl, modelica_metatype *out_otpl);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotationTraverse,2,0) {(void*) boxptr_DAEUtil_evaluateAnnotationTraverse,0}};
#define boxvar_DAEUtil_evaluateAnnotationTraverse MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_evaluateAnnotationTraverse)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_compareCrefList(threadData_t *threadData, modelica_metatype _inCrefs, modelica_boolean *out_matching);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_compareCrefList(threadData_t *threadData, modelica_metatype _inCrefs, modelica_metatype *out_matching);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_compareCrefList,2,0) {(void*) boxptr_DAEUtil_compareCrefList,0}};
#define boxvar_DAEUtil_compareCrefList MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_compareCrefList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_collectWhenCrefs1(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _source, modelica_metatype _inCrefs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_collectWhenCrefs1,2,0) {(void*) boxptr_DAEUtil_collectWhenCrefs1,0}};
#define boxvar_DAEUtil_collectWhenCrefs1 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_collectWhenCrefs1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_collectWhenCrefs(threadData_t *threadData, modelica_metatype _inExps, modelica_metatype _source, modelica_metatype _inCrefs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_collectWhenCrefs,2,0) {(void*) boxptr_DAEUtil_collectWhenCrefs,0}};
#define boxvar_DAEUtil_collectWhenCrefs MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_collectWhenCrefs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_verifyBoolWhenEquation1(threadData_t *threadData, modelica_metatype _inElems, modelica_boolean _initCond, modelica_metatype _inCrefs);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_verifyBoolWhenEquation1(threadData_t *threadData, modelica_metatype _inElems, modelica_metatype _initCond, modelica_metatype _inCrefs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_verifyBoolWhenEquation1,2,0) {(void*) boxptr_DAEUtil_verifyBoolWhenEquation1,0}};
#define boxvar_DAEUtil_verifyBoolWhenEquation1 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_verifyBoolWhenEquation1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_verifyBoolWhenEquationBranch(threadData_t *threadData, modelica_metatype _inCond, modelica_metatype _inEqs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_verifyBoolWhenEquationBranch,2,0) {(void*) boxptr_DAEUtil_verifyBoolWhenEquationBranch,0}};
#define boxvar_DAEUtil_verifyBoolWhenEquationBranch MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_verifyBoolWhenEquationBranch)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_collectWhenEquationBranches(threadData_t *threadData, modelica_metatype _inElseWhen, modelica_metatype _inWhenBranches);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_collectWhenEquationBranches,2,0) {(void*) boxptr_DAEUtil_collectWhenEquationBranches,0}};
#define boxvar_DAEUtil_collectWhenEquationBranches MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_collectWhenEquationBranches)
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_verifyBoolWhenEquation(threadData_t *threadData, modelica_metatype _inCond, modelica_metatype _inEqs, modelica_metatype _inElseWhen, modelica_metatype _source);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_verifyBoolWhenEquation,2,0) {(void*) boxptr_DAEUtil_verifyBoolWhenEquation,0}};
#define boxvar_DAEUtil_verifyBoolWhenEquation MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_verifyBoolWhenEquation)
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_verifyClockWhenEquation1(threadData_t *threadData, modelica_metatype _inEqs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_verifyClockWhenEquation1,2,0) {(void*) boxptr_DAEUtil_verifyClockWhenEquation1,0}};
#define boxvar_DAEUtil_verifyClockWhenEquation1 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_verifyClockWhenEquation1)
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_verifyClockWhenEquation(threadData_t *threadData, modelica_metatype _cond, modelica_metatype _eqs, modelica_metatype _ew, modelica_metatype _source);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_verifyClockWhenEquation,2,0) {(void*) boxptr_DAEUtil_verifyClockWhenEquation,0}};
#define boxvar_DAEUtil_verifyClockWhenEquation MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_verifyClockWhenEquation)
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_verifyWhenEquation(threadData_t *threadData, modelica_metatype _cond, modelica_metatype _eqs, modelica_metatype _ew, modelica_metatype _source);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_verifyWhenEquation,2,0) {(void*) boxptr_DAEUtil_verifyWhenEquation,0}};
#define boxvar_DAEUtil_verifyWhenEquation MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_verifyWhenEquation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_crefToExp(threadData_t *threadData, modelica_metatype _inComponentRef);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_crefToExp,2,0) {(void*) boxptr_DAEUtil_crefToExp,0}};
#define boxvar_DAEUtil_crefToExp MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_crefToExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getFunctionsElements(threadData_t *threadData, modelica_metatype _elements);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_getFunctionsElements,2,0) {(void*) boxptr_DAEUtil_getFunctionsElements,0}};
#define boxvar_DAEUtil_getFunctionsElements MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_getFunctionsElements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_toModelicaFormExp(threadData_t *threadData, modelica_metatype _inExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_toModelicaFormExp,2,0) {(void*) boxptr_DAEUtil_toModelicaFormExp,0}};
#define boxvar_DAEUtil_toModelicaFormExp MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_toModelicaFormExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_toModelicaFormCref(threadData_t *threadData, modelica_metatype _cr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_toModelicaFormCref,2,0) {(void*) boxptr_DAEUtil_toModelicaFormCref,0}};
#define boxvar_DAEUtil_toModelicaFormCref MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_toModelicaFormCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_toModelicaFormExpOpt(threadData_t *threadData, modelica_metatype _inExpExpOption);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_toModelicaFormExpOpt,2,0) {(void*) boxptr_DAEUtil_toModelicaFormExpOpt,0}};
#define boxvar_DAEUtil_toModelicaFormExpOpt MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_toModelicaFormExpOpt)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_toModelicaFormElts(threadData_t *threadData, modelica_metatype _inElementLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_toModelicaFormElts,2,0) {(void*) boxptr_DAEUtil_toModelicaFormElts,0}};
#define boxvar_DAEUtil_toModelicaFormElts MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_toModelicaFormElts)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getStreamVariables2(threadData_t *threadData, modelica_metatype _inExpComponentRefLst, modelica_string _inIdent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_getStreamVariables2,2,0) {(void*) boxptr_DAEUtil_getStreamVariables2,0}};
#define boxvar_DAEUtil_getStreamVariables2 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_getStreamVariables2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getFlowVariables2(threadData_t *threadData, modelica_metatype _inExpComponentRefLst, modelica_string _inIdent);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_getFlowVariables2,2,0) {(void*) boxptr_DAEUtil_getFlowVariables2,0}};
#define boxvar_DAEUtil_getFlowVariables2 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_getFlowVariables2)
PROTECTED_FUNCTION_STATIC modelica_string omc_DAEUtil_getBindingsStr(threadData_t *threadData, modelica_metatype _inElementLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_getBindingsStr,2,0) {(void*) boxptr_DAEUtil_getBindingsStr,0}};
#define boxvar_DAEUtil_getBindingsStr MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_getBindingsStr)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getVariableList(threadData_t *threadData, modelica_metatype _inElementLst);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_getVariableList,2,0) {(void*) boxptr_DAEUtil_getVariableList,0}};
#define boxvar_DAEUtil_getVariableList MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_getVariableList)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_findAllMatchingElements2(threadData_t *threadData, modelica_metatype _elements, modelica_fnptr _cond1, modelica_fnptr _cond2, modelica_metatype _accumFirst, modelica_metatype _accumSecond, modelica_metatype *out_secondList);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_findAllMatchingElements2,2,0) {(void*) boxptr_DAEUtil_findAllMatchingElements2,0}};
#define boxvar_DAEUtil_findAllMatchingElements2 MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_findAllMatchingElements2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_removeInnerAttribute(threadData_t *threadData, modelica_metatype _io);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_removeInnerAttribute,2,0) {(void*) boxptr_DAEUtil_removeInnerAttribute,0}};
#define boxvar_DAEUtil_removeInnerAttribute MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_removeInnerAttribute)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_DAEUtil_compareUniquedVarWithNonUnique(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_compareUniquedVarWithNonUnique(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_compareUniquedVarWithNonUnique,2,0) {(void*) boxptr_DAEUtil_compareUniquedVarWithNonUnique,0}};
#define boxvar_DAEUtil_compareUniquedVarWithNonUnique MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_compareUniquedVarWithNonUnique)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_removeVariable(threadData_t *threadData, modelica_metatype _var, modelica_metatype _dae);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_removeVariable,2,0) {(void*) boxptr_DAEUtil_removeVariable,0}};
#define boxvar_DAEUtil_removeVariable MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_removeVariable)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_removeVariablesFromElements(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _variableNames);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_removeVariablesFromElements,2,0) {(void*) boxptr_DAEUtil_removeVariablesFromElements,0}};
#define boxvar_DAEUtil_removeVariablesFromElements MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_removeVariablesFromElements)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_DAEUtil_topLevelConnectorType(threadData_t *threadData, modelica_metatype _inConnectorType);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_topLevelConnectorType(threadData_t *threadData, modelica_metatype _inConnectorType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_DAEUtil_topLevelConnectorType,2,0) {(void*) boxptr_DAEUtil_topLevelConnectorType,0}};
#define boxvar_DAEUtil_topLevelConnectorType MMC_REFSTRUCTLIT(boxvar_lit_DAEUtil_topLevelConnectorType)
DLLExport
modelica_metatype omc_DAEUtil_getParameters(threadData_t *threadData, modelica_metatype _elts, modelica_metatype _acc)
{
modelica_metatype _params = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _elts;
{
modelica_metatype _e = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _celts = NULL;
modelica_metatype _a = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],17,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_celts = tmpMeta[3];
_rest = tmpMeta[2];
_a = omc_DAEUtil_getParameters(threadData, _celts, _acc);
_elts = _rest;
_acc = _a;
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
modelica_boolean tmp5;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,13) == 0) goto tmp2_end;
_e = tmpMeta[1];
_rest = tmpMeta[2];
tmp5 = (modelica_boolean)omc_DAEUtil_isParameterOrConstant(threadData, _e);
if(tmp5)
{
tmpMeta[1] = mmc_mk_cons(_e, omc_DAEUtil_getParameters(threadData, _rest, _acc));
tmpMeta[2] = tmpMeta[1];
}
else
{
_elts = _rest;
goto _tailrecursive;
}
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
_elts = _rest;
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
_params = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _params;
}
DLLExport
modelica_metatype omc_DAEUtil_moveElementToInitialSection(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felt)
{
modelica_metatype _elt = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elt = __omcQ_24in_5Felt;
{
modelica_metatype tmp3_1;
tmp3_1 = _elt;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 6: {
tmpMeta[1] = mmc_mk_box4(17, &DAE_Element_INITIALEQUATION__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 4))));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
tmpMeta[1] = mmc_mk_box4(5, &DAE_Element_INITIALDEFINE__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 4))));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 8: {
tmpMeta[1] = mmc_mk_box5(9, &DAE_Element_INITIAL__ARRAY__EQUATION__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 5))));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 11: {
tmpMeta[1] = mmc_mk_box4(12, &DAE_Element_INITIAL__COMPLEX__EQUATION__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 4))));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 15: {
tmpMeta[1] = mmc_mk_box5(16, &DAE_Element_INITIAL__IF__EQUATION__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 5))));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 18: {
tmpMeta[1] = mmc_mk_box3(19, &DAE_Element_INITIALALGORITHM__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 3))));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 22: {
tmpMeta[1] = mmc_mk_box5(23, &DAE_Element_INITIAL__ASSERT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 3))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 5))));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 24: {
tmpMeta[1] = mmc_mk_box3(25, &DAE_Element_INITIAL__TERMINATE__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 3))));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 27: {
tmpMeta[1] = mmc_mk_box3(28, &DAE_Element_INITIAL__NORETCALL__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 3))));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _elt;
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
DLLExport
modelica_metatype omc_DAEUtil_mergeAlgorithmSections(threadData_t *threadData, modelica_metatype _inDae)
{
modelica_metatype _outDae = NULL;
modelica_metatype _els = NULL;
modelica_metatype _newEls = NULL;
modelica_metatype _dAElist = NULL;
modelica_metatype _istmts = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _s = NULL;
modelica_metatype _source = NULL;
modelica_metatype _src = NULL;
modelica_string _ident = NULL;
modelica_metatype _comment = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_newEls = tmpMeta[0];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_istmts = tmpMeta[1];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_stmts = tmpMeta[2];
if((!omc_Flags_isSet(threadData, _OMC_LIT3)))
{
_outDae = _inDae;
goto _return;
}
tmpMeta[3] = _inDae;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_els = tmpMeta[4];
{
modelica_metatype _e;
for (tmpMeta[3] = _els; !listEmpty(tmpMeta[3]); tmpMeta[3]=MMC_CDR(tmpMeta[3]))
{
_e = MMC_CAR(tmpMeta[3]);
{
modelica_metatype tmp3_1;
tmp3_1 = _e;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,4) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_ident = tmpMeta[4];
_dAElist = tmpMeta[5];
_src = tmpMeta[6];
_comment = tmpMeta[7];
tmpMeta[4] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _dAElist);
tmpMeta[5] = omc_DAEUtil_mergeAlgorithmSections(threadData, tmpMeta[4]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
_dAElist = tmpMeta[6];
tmpMeta[5] = mmc_mk_box5(20, &DAE_Element_COMP__desc, _ident, _dAElist, _src, _comment);
tmpMeta[4] = mmc_mk_cons(tmpMeta[5], _newEls);
_newEls = tmpMeta[4];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,15,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_s = tmpMeta[5];
_source = tmpMeta[6];
_stmts = omc_List_append__reverse(threadData, _s, _stmts);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_s = tmpMeta[5];
_source = tmpMeta[6];
_istmts = omc_List_append__reverse(threadData, _s, _istmts);
goto tmp2_done;
}
case 3: {
tmpMeta[4] = mmc_mk_cons(_e, _newEls);
_newEls = tmpMeta[4];
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
if((!listEmpty(_istmts)))
{
tmpMeta[4] = mmc_mk_box2(3, &DAE_Algorithm_ALGORITHM__STMTS__desc, listReverse(_istmts));
tmpMeta[5] = mmc_mk_box3(19, &DAE_Element_INITIALALGORITHM__desc, tmpMeta[4], _source);
tmpMeta[3] = mmc_mk_cons(tmpMeta[5], _newEls);
_newEls = tmpMeta[3];
}
if((!listEmpty(_stmts)))
{
tmpMeta[4] = mmc_mk_box2(3, &DAE_Algorithm_ALGORITHM__STMTS__desc, listReverse(_stmts));
tmpMeta[5] = mmc_mk_box3(18, &DAE_Element_ALGORITHM__desc, tmpMeta[4], _source);
tmpMeta[3] = mmc_mk_cons(tmpMeta[5], _newEls);
_newEls = tmpMeta[3];
}
_newEls = listReverse(_newEls);
tmpMeta[3] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _newEls);
_outDae = tmpMeta[3];
_return: OMC_LABEL_UNUSED
return _outDae;
}
DLLExport
modelica_metatype omc_DAEUtil_toSCodeConnectorType(threadData_t *threadData, modelica_metatype _daeConnectorType)
{
modelica_metatype _scodeConnectorType = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _daeConnectorType;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 4: {
tmpMeta[0] = _OMC_LIT4;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT5;
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _OMC_LIT6;
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _OMC_LIT6;
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
_scodeConnectorType = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _scodeConnectorType;
}
DLLExport
modelica_boolean omc_DAEUtil_connectorTypeEqual(threadData_t *threadData, modelica_metatype _inConnectorType1, modelica_metatype _inConnectorType2)
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_connectorTypeEqual(threadData_t *threadData, modelica_metatype _inConnectorType1, modelica_metatype _inConnectorType2)
{
modelica_boolean _outEqual;
modelica_metatype out_outEqual;
_outEqual = omc_DAEUtil_connectorTypeEqual(threadData, _inConnectorType1, _inConnectorType2);
out_outEqual = mmc_mk_icon(_outEqual);
return out_outEqual;
}
DLLExport
modelica_boolean omc_DAEUtil_potentialBool(threadData_t *threadData, modelica_metatype _inConnectorType)
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
modelica_metatype boxptr_DAEUtil_potentialBool(threadData_t *threadData, modelica_metatype _inConnectorType)
{
modelica_boolean _outPotential;
modelica_metatype out_outPotential;
_outPotential = omc_DAEUtil_potentialBool(threadData, _inConnectorType);
out_outPotential = mmc_mk_icon(_outPotential);
return out_outPotential;
}
DLLExport
modelica_boolean omc_DAEUtil_streamBool(threadData_t *threadData, modelica_metatype _inStream)
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_streamBool(threadData_t *threadData, modelica_metatype _inStream)
{
modelica_boolean _bStream;
modelica_metatype out_bStream;
_bStream = omc_DAEUtil_streamBool(threadData, _inStream);
out_bStream = mmc_mk_icon(_bStream);
return out_bStream;
}
DLLExport
modelica_string omc_DAEUtil_connectorTypeStr(threadData_t *threadData, modelica_metatype _connectorType)
{
modelica_string _string = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _connectorType;
{
modelica_metatype _cref = NULL;
modelica_string _cref_str = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT7;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT8;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!optionNone(tmpMeta[0])) goto tmp3_end;
tmp1 = _OMC_LIT9;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
_cref = tmpMeta[1];
_cref_str = omc_ComponentReference_printComponentRefStr(threadData, _cref);
tmpMeta[0] = stringAppend(_OMC_LIT10,_cref_str);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT11);
tmp1 = tmpMeta[1];
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT12;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_string = tmp1;
_return: OMC_LABEL_UNUSED
return _string;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_replaceCompRef(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _replIn, modelica_metatype *out_replOut)
{
modelica_metatype _outExp = NULL;
modelica_metatype _replOut = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_replOut = _replIn;
_outExp = omc_VarTransform_replaceExp(threadData, _inExp, _replIn, mmc_mk_none(), NULL);
_return: OMC_LABEL_UNUSED
if (out_replOut) { *out_replOut = _replOut; }
return _outExp;
}
DLLExport
modelica_metatype omc_DAEUtil_replaceCrefBottomUp(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _replIn, modelica_metatype *out_replOut)
{
modelica_metatype _outExp = NULL;
modelica_metatype _replOut = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_replOut = _replIn;
_outExp = omc_Expression_traverseExpBottomUp(threadData, _inExp, boxvar_DAEUtil_replaceCompRef, _replIn, NULL);
_return: OMC_LABEL_UNUSED
if (out_replOut) { *out_replOut = _replOut; }
return _outExp;
}
DLLExport
modelica_metatype omc_DAEUtil_replaceCrefInDAEElements(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inCref, modelica_metatype _inExp)
{
modelica_metatype _outElements = NULL;
modelica_metatype _repl = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_repl = omc_VarTransform_emptyReplacements(threadData);
_repl = omc_VarTransform_addReplacement(threadData, _repl, _inCref, _inExp);
_outElements = omc_DAEUtil_traverseDAEElementList(threadData, _inElements, boxvar_DAEUtil_replaceCrefBottomUp, _repl, NULL);
_return: OMC_LABEL_UNUSED
return _outElements;
}
DLLExport
modelica_metatype omc_DAEUtil_evaluateExp(threadData_t *threadData, modelica_metatype _iexp, modelica_metatype _iels)
{
jmp_buf *old_mmc_jumper = threadData->mmc_jumper;
modelica_metatype _oexp = NULL;
modelica_metatype _e = NULL;
modelica_metatype _ee = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype _oexps = NULL;
modelica_metatype _o = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_oexp = mmc_mk_none();
if(omc_Expression_isConst(threadData, _iexp))
{
_oexp = mmc_mk_some(_iexp);
goto _return;
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
_e = _iexp;
_crefs = omc_Expression_getAllCrefs(threadData, _e);
_oexps = omc_List_map1(threadData, _crefs, boxvar_DAEUtil_evaluateCref, _iels);
{
modelica_metatype _c;
for (tmpMeta[0] = _crefs; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_c = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = _oexps;
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (optionNone(tmpMeta[2])) goto goto_1;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_ee = tmpMeta[4];
_oexps = tmpMeta[3];
_e = omc_Expression_replaceCrefBottomUp(threadData, _e, _c, _ee);
_e = omc_ExpressionSimplify_simplify(threadData, _e, NULL);
}
}
_oexp = mmc_mk_some(_e);
goto tmp2_done;
}
case 1: {
_oexp = mmc_mk_none();
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
threadData->mmc_jumper = old_mmc_jumper;
return _oexp;
}
DLLExport
modelica_metatype omc_DAEUtil_evaluateCref(threadData_t *threadData, modelica_metatype _icr, modelica_metatype _iels)
{
modelica_metatype _oexp = NULL;
modelica_metatype _e = NULL;
modelica_metatype _ee = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype _oexps = NULL;
modelica_metatype _o = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_oexp = omc_DAEUtil_getVarBinding(threadData, _iels, _icr);
if(isSome(_oexp))
{
tmpMeta[0] = _oexp;
if (optionNone(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
_e = tmpMeta[1];
_e = omc_ExpressionSimplify_simplify(threadData, _e, NULL);
if(omc_Expression_isConst(threadData, _e))
{
_oexp = mmc_mk_some(_e);
goto _return;
}
_crefs = omc_Expression_getAllCrefs(threadData, _e);
_oexps = omc_List_map1(threadData, _crefs, boxvar_DAEUtil_evaluateCref, _iels);
{
modelica_metatype _c;
for (tmpMeta[0] = _crefs; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_c = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = _oexps;
if (listEmpty(tmpMeta[1])) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (optionNone(tmpMeta[2])) MMC_THROW_INTERNAL();
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_ee = tmpMeta[4];
_oexps = tmpMeta[3];
tmpMeta[1] = mmc_mk_box2(0, _c, _ee);
_e = omc_Expression_replaceCref(threadData, _e, tmpMeta[1], NULL);
_e = omc_ExpressionSimplify_simplify(threadData, _e, NULL);
}
}
_oexp = mmc_mk_some(_e);
}
_return: OMC_LABEL_UNUSED
return _oexp;
}
DLLExport
modelica_metatype omc_DAEUtil_getVarBinding(threadData_t *threadData, modelica_metatype _iels, modelica_metatype _icr)
{
modelica_metatype _obnd = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _e = NULL;
modelica_metatype _lst = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_obnd = mmc_mk_none();
{
modelica_metatype _i;
for (tmpMeta[0] = _iels; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_i = MMC_CAR(tmpMeta[0]);
{
modelica_metatype tmp3_1;
tmp3_1 = _i;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 8; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_cr = tmpMeta[2];
_obnd = tmpMeta[3];
if(omc_ComponentReference_crefEqualNoStringCompare(threadData, _icr, _cr))
{
goto _return;
}
tmpMeta[1] = _obnd;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_cr = tmpMeta[2];
_e = tmpMeta[3];
_obnd = mmc_mk_some(_e);
if(omc_ComponentReference_crefEqualNoStringCompare(threadData, _icr, _cr))
{
goto _return;
}
tmpMeta[1] = _obnd;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_cr = tmpMeta[2];
_e = tmpMeta[3];
_obnd = mmc_mk_some(_e);
if(omc_ComponentReference_crefEqualNoStringCompare(threadData, _icr, _cr))
{
goto _return;
}
tmpMeta[1] = _obnd;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_cr = tmpMeta[3];
_e = tmpMeta[4];
_obnd = mmc_mk_some(_e);
if(omc_ComponentReference_crefEqualNoStringCompare(threadData, _icr, _cr))
{
goto _return;
}
tmpMeta[1] = _obnd;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],6,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_e = tmpMeta[2];
_cr = tmpMeta[4];
_obnd = mmc_mk_some(_e);
if(omc_ComponentReference_crefEqualNoStringCompare(threadData, _icr, _cr))
{
goto _return;
}
tmpMeta[1] = _obnd;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,14,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_cr = tmpMeta[3];
_e = tmpMeta[4];
_obnd = mmc_mk_some(_e);
if(omc_ComponentReference_crefEqualNoStringCompare(threadData, _icr, _cr))
{
goto _return;
}
tmpMeta[1] = _obnd;
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,14,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],6,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_e = tmpMeta[2];
_cr = tmpMeta[4];
_obnd = mmc_mk_some(_e);
if(omc_ComponentReference_crefEqualNoStringCompare(threadData, _icr, _cr))
{
goto _return;
}
tmpMeta[1] = _obnd;
goto tmp2_done;
}
case 7: {
tmpMeta[1] = _obnd;
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
_obnd = tmpMeta[1];
}
}
_return: OMC_LABEL_UNUSED
return _obnd;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_statementsContainTryBlock2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inStmt, modelica_boolean _b, modelica_boolean *out_ob)
{
modelica_metatype _outExp = NULL;
modelica_boolean _ob;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = _inExp;
_ob = _b;
if((!_b))
{
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,33,6) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
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
_ob = tmp1;
}
_return: OMC_LABEL_UNUSED
if (out_ob) { *out_ob = _ob; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_statementsContainTryBlock2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inStmt, modelica_metatype _b, modelica_metatype *out_ob)
{
modelica_integer tmp1;
modelica_boolean _ob;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_b);
_outExp = omc_DAEUtil_statementsContainTryBlock2(threadData, _inExp, _inStmt, tmp1, &_ob);
if (out_ob) { *out_ob = mmc_mk_icon(_ob); }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_statementsContainReturn2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inStmt, modelica_boolean _b, modelica_boolean *out_ob)
{
modelica_metatype _outExp = NULL;
modelica_boolean _ob;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = _inExp;
_ob = _b;
if((!_b))
{
{
modelica_metatype tmp4_1;
tmp4_1 = _inStmt;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,1) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6 = 0;
{
modelica_metatype tmp9_1;
tmp9_1 = _inExp;
{
modelica_metatype _cases = NULL;
modelica_metatype _body = NULL;
volatile mmc_switch_type tmp9;
int tmp10;
tmp9 = 0;
for (; tmp9 < 2; tmp9++) {
switch (MMC_SWITCH_CAST(tmp9)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp9_1,33,6) == 0) goto tmp8_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp9_1), 6));
_cases = tmpMeta[0];
{
modelica_metatype _c;
for (tmpMeta[0] = _cases; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_c = MMC_CAR(tmpMeta[0]);
if((!_ob))
{
tmpMeta[1] = _c;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
_body = tmpMeta[2];
_ob = omc_DAEUtil_statementsContainReturn(threadData, _body);
}
}
}
tmp6 = _ob;
goto tmp8_done;
}
case 1: {
tmp6 = 0;
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
}tmp1 = tmp6;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_ob = tmp1;
}
_return: OMC_LABEL_UNUSED
if (out_ob) { *out_ob = _ob; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_statementsContainReturn2(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inStmt, modelica_metatype _b, modelica_metatype *out_ob)
{
modelica_integer tmp1;
modelica_boolean _ob;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_b);
_outExp = omc_DAEUtil_statementsContainReturn2(threadData, _inExp, _inStmt, tmp1, &_ob);
if (out_ob) { *out_ob = mmc_mk_icon(_ob); }
return _outExp;
}
DLLExport
modelica_boolean omc_DAEUtil_statementsContainTryBlock(threadData_t *threadData, modelica_metatype _stmts)
{
modelica_boolean _b;
modelica_integer tmp1;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_DAEUtil_traverseDAEStmts(threadData, _stmts, boxvar_DAEUtil_statementsContainTryBlock2, mmc_mk_boolean(0), &tmpMeta[0]);
tmp1 = mmc_unbox_integer(tmpMeta[0]);
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_DAEUtil_statementsContainTryBlock(threadData_t *threadData, modelica_metatype _stmts)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_statementsContainTryBlock(threadData, _stmts);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_DAEUtil_statementsContainReturn(threadData_t *threadData, modelica_metatype _stmts)
{
modelica_boolean _b;
modelica_integer tmp1;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
omc_DAEUtil_traverseDAEStmts(threadData, _stmts, boxvar_DAEUtil_statementsContainReturn2, mmc_mk_boolean(0), &tmpMeta[0]);
tmp1 = mmc_unbox_integer(tmpMeta[0]);
_b = tmp1;
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_DAEUtil_statementsContainReturn(threadData_t *threadData, modelica_metatype _stmts)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_statementsContainReturn(threadData, _stmts);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_DAEUtil_bindingValue(threadData_t *threadData, modelica_metatype _inBinding)
{
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inBinding;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 4: {
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inBinding), 3)));
goto tmp2_done;
}
case 5: {
tmpMeta[0] = mmc_mk_some((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_inBinding), 2))));
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
_outValue = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outValue;
}
DLLExport
modelica_integer omc_DAEUtil_getSubscriptIndex(threadData_t *threadData, modelica_metatype _iSubscript)
{
modelica_integer _oIndex;
modelica_integer _index;
modelica_metatype _exp = NULL;
modelica_integer tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _iSubscript;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[1]);
_index = tmp6;
tmp1 = _index;
goto tmp3_done;
}
case 1: {
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],5,2) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
_index = tmp7;
tmp1 = _index;
goto tmp3_done;
}
case 2: {
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
_oIndex = tmp1;
_return: OMC_LABEL_UNUSED
return _oIndex;
}
modelica_metatype boxptr_DAEUtil_getSubscriptIndex(threadData_t *threadData, modelica_metatype _iSubscript)
{
modelica_integer _oIndex;
modelica_metatype out_oIndex;
_oIndex = omc_DAEUtil_getSubscriptIndex(threadData, _iSubscript);
out_oIndex = mmc_mk_icon(_oIndex);
return out_oIndex;
}
DLLExport
modelica_metatype omc_DAEUtil_getAssertConditionCrefs(threadData_t *threadData, modelica_metatype _stmt, modelica_metatype _crefsIn)
{
modelica_metatype _crefsOut = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _stmt;
{
modelica_metatype _cond = NULL;
modelica_metatype _crefs = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_cond = tmpMeta[1];
_crefs = omc_Expression_extractCrefsFromExp(threadData, _cond);
tmpMeta[0] = listAppend(_crefsIn, _crefs);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _crefsIn;
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
_crefsOut = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _crefsOut;
}
DLLExport
modelica_metatype omc_DAEUtil_toDAEInnerOuter(threadData_t *threadData, modelica_metatype _ioIn)
{
modelica_metatype _ioOut = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _ioIn;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = _OMC_LIT13;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT14;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT15;
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _OMC_LIT16;
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
_ioOut = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _ioOut;
}
DLLExport
modelica_integer omc_DAEUtil_funcArgDim(threadData_t *threadData, modelica_metatype _argIn)
{
modelica_integer _dim;
modelica_integer tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _argIn;
{
modelica_metatype _arrayDims = NULL;
modelica_metatype _names = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],6,2) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_arrayDims = tmpMeta[1];
tmp1 = mmc_unbox_integer(omc_List_applyAndFold(threadData, _arrayDims, boxvar_intAdd, boxvar_Expression_dimensionSize, mmc_mk_integer(((modelica_integer) 0))));
goto tmp3_done;
}
case 1: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],5,5) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_names = tmpMeta[1];
tmp1 = listLength(_names);
goto tmp3_done;
}
case 2: {
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_dim = tmp1;
_return: OMC_LABEL_UNUSED
return _dim;
}
modelica_metatype boxptr_DAEUtil_funcArgDim(threadData_t *threadData, modelica_metatype _argIn)
{
modelica_integer _dim;
modelica_metatype out_dim;
_dim = omc_DAEUtil_funcArgDim(threadData, _argIn);
out_dim = mmc_mk_icon(_dim);
return out_dim;
}
DLLExport
modelica_boolean omc_DAEUtil_funcIsRecord(threadData_t *threadData, modelica_metatype _func)
{
modelica_boolean _isRec;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _func;
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
_isRec = tmp1;
_return: OMC_LABEL_UNUSED
return _isRec;
}
modelica_metatype boxptr_DAEUtil_funcIsRecord(threadData_t *threadData, modelica_metatype _func)
{
modelica_boolean _isRec;
modelica_metatype out_isRec;
_isRec = omc_DAEUtil_funcIsRecord(threadData, _func);
out_isRec = mmc_mk_icon(_isRec);
return out_isRec;
}
DLLExport
modelica_metatype omc_DAEUtil_replaceCallAttrType(threadData_t *threadData, modelica_metatype _caIn, modelica_metatype _typeIn)
{
modelica_metatype _caOut = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_caOut = _caIn;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_caOut), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _typeIn;
_caOut = tmpMeta[0];
if(omc_Types_isTuple(threadData, _typeIn))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_caOut), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = mmc_mk_boolean(1);
_caOut = tmpMeta[0];
}
_return: OMC_LABEL_UNUSED
return _caOut;
}
DLLExport
modelica_string omc_DAEUtil_daeDescription(threadData_t *threadData, modelica_metatype _inDAE)
{
modelica_string _comment = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inDAE;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (listEmpty(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],17,4) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (optionNone(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
_comment = tmpMeta[6];
tmp1 = _comment;
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT7;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_collectAllExpandableCrefsInExp(threadData_t *threadData, modelica_metatype _exp, modelica_metatype _acc, modelica_metatype *out_outCrefs)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outCrefs = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_cr = tmpMeta[2];
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = omc_List_consOnTrue(threadData, omc_ConnectUtil_isExpandable(threadData, _cr), _cr, _acc);
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _acc;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outCrefs = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outCrefs) { *out_outCrefs = _outCrefs; }
return _outExp;
}
DLLExport
modelica_metatype omc_DAEUtil_getAllExpandableCrefsFromDAE(threadData_t *threadData, modelica_metatype _inDAE)
{
modelica_metatype _outCrefs = NULL;
modelica_metatype _elts = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inDAE;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_elts = tmpMeta[1];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = mmc_mk_box2(0, boxvar_DAEUtil_collectAllExpandableCrefsInExp, tmpMeta[2]);
omc_DAEUtil_traverseDAEElementList(threadData, _elts, boxvar_Expression_traverseSubexpressionsHelper, tmpMeta[3], &tmpMeta[0]);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_outCrefs = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_splitVariableNamed(threadData_t *threadData, modelica_metatype _inElementLst, modelica_string _inName, modelica_metatype _inAccNamed, modelica_metatype _inAccRest, modelica_metatype *out_outRest)
{
modelica_metatype _outNamed = NULL;
modelica_metatype _outRest = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _inElementLst;
tmp4_2 = _inAccNamed;
tmp4_3 = _inAccRest;
{
modelica_metatype _lst = NULL;
modelica_metatype _accNamed = NULL;
modelica_metatype _accRest = NULL;
modelica_metatype _x = NULL;
modelica_boolean _equal;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0+0] = listReverse(_inAccNamed);
tmpMeta[0+1] = listReverse(_inAccRest);
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,13) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_x = tmpMeta[2];
_cr = tmpMeta[4];
_lst = tmpMeta[3];
_accNamed = tmp4_2;
_accRest = tmp4_3;
_equal = (stringEqual(omc_ComponentReference_crefFirstIdent(threadData, _cr), _inName));
_accNamed = omc_List_consOnTrue(threadData, _equal, _x, _accNamed);
_accRest = omc_List_consOnTrue(threadData, (!_equal), _x, _accRest);
_inElementLst = _lst;
_inAccNamed = _accNamed;
_inAccRest = _accRest;
goto _tailrecursive;
goto tmp3_done;
}
case 2: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
_x = tmpMeta[2];
_lst = tmpMeta[3];
_accNamed = tmp4_2;
_accRest = tmp4_3;
tmpMeta[2] = mmc_mk_cons(_x, _accRest);
_inElementLst = _lst;
_inAccNamed = _accNamed;
_inAccRest = tmpMeta[2];
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
_outNamed = tmpMeta[0+0];
_outRest = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outRest) { *out_outRest = _outRest; }
return _outNamed;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_sortDAEElementsInModelicaCodeOrder(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _inDaeEls)
{
modelica_metatype _outDaeEls = NULL;
modelica_metatype _rest = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outDaeEls = tmpMeta[0];
_rest = _inDaeEls;
{
modelica_metatype _e;
for (tmpMeta[1] = _inElements; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_e = MMC_CAR(tmpMeta[1]);
{
modelica_metatype tmp3_1;
tmp3_1 = _e;
{
modelica_metatype _named = NULL;
modelica_string _name = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,8) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_name = tmpMeta[3];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
_named = omc_DAEUtil_splitVariableNamed(threadData, _rest, _name, tmpMeta[2], tmpMeta[3] ,&_rest);
_outDaeEls = omc_List_append__reverse(threadData, _named, _outDaeEls);
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
_outDaeEls = omc_List_append__reverse(threadData, _inDaeEls, _outDaeEls);
_outDaeEls = listReverseInPlace(_outDaeEls);
_return: OMC_LABEL_UNUSED
return _outDaeEls;
}
DLLExport
modelica_metatype omc_DAEUtil_sortDAEInModelicaCodeOrder(threadData_t *threadData, modelica_boolean _inShouldSort, modelica_metatype _inElements, modelica_metatype _inDae)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp3_1;modelica_metatype tmp3_2;modelica_metatype tmp3_3;
tmp3_1 = _inShouldSort;
tmp3_2 = _inElements;
tmp3_3 = _inDae;
{
modelica_metatype _els = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (0 != tmp3_1) goto tmp2_end;
tmpMeta[0] = _inDae;
goto tmp2_done;
}
case 1: {
if (1 != tmp3_1) goto tmp2_end;
if (!listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[0] = _inDae;
goto tmp2_done;
}
case 2: {
if (1 != tmp3_1) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_3), 2));
_els = tmpMeta[1];
_els = omc_DAEUtil_sortDAEElementsInModelicaCodeOrder(threadData, _inElements, _els);
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _els);
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
_outDae = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDae;
}
modelica_metatype boxptr_DAEUtil_sortDAEInModelicaCodeOrder(threadData_t *threadData, modelica_metatype _inShouldSort, modelica_metatype _inElements, modelica_metatype _inDae)
{
modelica_integer tmp1;
modelica_metatype _outDae = NULL;
tmp1 = mmc_unbox_integer(_inShouldSort);
_outDae = omc_DAEUtil_sortDAEInModelicaCodeOrder(threadData, tmp1, _inElements, _inDae);
return _outDae;
}
DLLExport
modelica_metatype omc_DAEUtil_mkEmptyVar(threadData_t *threadData, modelica_string _name)
{
modelica_metatype _outVar = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box7(3, &DAE_Var_TYPES__VAR__desc, _name, _OMC_LIT23, _OMC_LIT24, _OMC_LIT25, mmc_mk_boolean(0), mmc_mk_none());
_outVar = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outVar;
}
DLLExport
modelica_metatype omc_DAEUtil_getElements(threadData_t *threadData, modelica_metatype _inDAE)
{
modelica_metatype _outElements = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inDAE;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_outElements = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _outElements;
}
DLLExport
modelica_boolean omc_DAEUtil_isComplexVar(threadData_t *threadData, modelica_metatype _inVar)
{
modelica_boolean _outIsComplex;
modelica_metatype _ty = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inVar;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_ty = tmpMeta[1];
_outIsComplex = omc_Types_isComplexType(threadData, _ty);
_return: OMC_LABEL_UNUSED
return _outIsComplex;
}
modelica_metatype boxptr_DAEUtil_isComplexVar(threadData_t *threadData, modelica_metatype _inVar)
{
modelica_boolean _outIsComplex;
modelica_metatype out_outIsComplex;
_outIsComplex = omc_DAEUtil_isComplexVar(threadData, _inVar);
out_outIsComplex = mmc_mk_icon(_outIsComplex);
return out_outIsComplex;
}
DLLExport
modelica_boolean omc_DAEUtil_varDirectionEqual(threadData_t *threadData, modelica_metatype _inDirection1, modelica_metatype _inDirection2)
{
modelica_boolean _outIsEqual;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inDirection1;
tmp4_2 = _inDirection2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
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
_outIsEqual = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsEqual;
}
modelica_metatype boxptr_DAEUtil_varDirectionEqual(threadData_t *threadData, modelica_metatype _inDirection1, modelica_metatype _inDirection2)
{
modelica_boolean _outIsEqual;
modelica_metatype out_outIsEqual;
_outIsEqual = omc_DAEUtil_varDirectionEqual(threadData, _inDirection1, _inDirection2);
out_outIsEqual = mmc_mk_icon(_outIsEqual);
return out_outIsEqual;
}
DLLExport
modelica_boolean omc_DAEUtil_varKindEqual(threadData_t *threadData, modelica_metatype _inVariability1, modelica_metatype _inVariability2)
{
modelica_boolean _outIsEqual;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inVariability1;
tmp4_2 = _inVariability2;
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
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,3,0) == 0) goto tmp3_end;
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
_outIsEqual = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsEqual;
}
modelica_metatype boxptr_DAEUtil_varKindEqual(threadData_t *threadData, modelica_metatype _inVariability1, modelica_metatype _inVariability2)
{
modelica_boolean _outIsEqual;
modelica_metatype out_outIsEqual;
_outIsEqual = omc_DAEUtil_varKindEqual(threadData, _inVariability1, _inVariability2);
out_outIsEqual = mmc_mk_icon(_outIsEqual);
return out_outIsEqual;
}
DLLExport
modelica_metatype omc_DAEUtil_setAttributeDirection(threadData_t *threadData, modelica_metatype _inDirection, modelica_metatype _inAttributes)
{
modelica_metatype _outAttributes = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _p = NULL;
modelica_metatype _var = NULL;
modelica_metatype _io = NULL;
modelica_metatype _vis = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inAttributes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
_ct = tmpMeta[1];
_p = tmpMeta[2];
_var = tmpMeta[3];
_io = tmpMeta[4];
_vis = tmpMeta[5];
tmpMeta[0] = mmc_mk_box7(3, &DAE_Attributes_ATTR__desc, _ct, _p, _var, _inDirection, _io, _vis);
_outAttributes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttributes;
}
DLLExport
modelica_boolean omc_DAEUtil_isNotCompleteFunction(threadData_t *threadData, modelica_metatype _f)
{
modelica_boolean _isNotComplete;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_isNotComplete = (!omc_DAEUtil_isCompleteFunction(threadData, _f));
_return: OMC_LABEL_UNUSED
return _isNotComplete;
}
modelica_metatype boxptr_DAEUtil_isNotCompleteFunction(threadData_t *threadData, modelica_metatype _f)
{
modelica_boolean _isNotComplete;
modelica_metatype out_isNotComplete;
_isNotComplete = omc_DAEUtil_isNotCompleteFunction(threadData, _f);
out_isNotComplete = mmc_mk_icon(_isNotComplete);
return out_isNotComplete;
}
DLLExport
modelica_boolean omc_DAEUtil_isCompleteFunctionBody(threadData_t *threadData, modelica_metatype _functions)
{
modelica_boolean _isComplete;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _functions;
{
modelica_metatype _rest = NULL;
modelica_metatype _els = NULL;
modelica_metatype _a = NULL;
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
tmp4 += 3;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,2) == 0) goto tmp3_end;
tmp4 += 2;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp6;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_els = tmpMeta[2];
tmp4 += 1;
omc_DAEUtil_splitElements(threadData, _els ,NULL ,NULL ,NULL ,&_a ,NULL ,NULL ,NULL, NULL, NULL);
tmp6 = listEmpty(_a);
if (0 != tmp6) goto goto_2;
tmp1 = 1;
goto tmp3_done;
}
case 3: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,6) == 0) goto tmp3_end;
_rest = tmpMeta[1];
tmp1 = omc_DAEUtil_isCompleteFunctionBody(threadData, _rest);
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
_isComplete = tmp1;
_return: OMC_LABEL_UNUSED
return _isComplete;
}
modelica_metatype boxptr_DAEUtil_isCompleteFunctionBody(threadData_t *threadData, modelica_metatype _functions)
{
modelica_boolean _isComplete;
modelica_metatype out_isComplete;
_isComplete = omc_DAEUtil_isCompleteFunctionBody(threadData, _functions);
out_isComplete = mmc_mk_icon(_isComplete);
return out_isComplete;
}
DLLExport
modelica_boolean omc_DAEUtil_isCompleteFunction(threadData_t *threadData, modelica_metatype _f)
{
modelica_boolean _isComplete;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _f;
{
modelica_metatype _functions = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmp1 = 1;
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,10) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_functions = tmpMeta[0];
tmp1 = omc_DAEUtil_isCompleteFunctionBody(threadData, _functions);
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
_isComplete = tmp1;
_return: OMC_LABEL_UNUSED
return _isComplete;
}
modelica_metatype boxptr_DAEUtil_isCompleteFunction(threadData_t *threadData, modelica_metatype _f)
{
modelica_boolean _isComplete;
modelica_metatype out_isComplete;
_isComplete = omc_DAEUtil_isCompleteFunction(threadData, _f);
out_isComplete = mmc_mk_icon(_isComplete);
return out_isComplete;
}
DLLExport
modelica_boolean omc_DAEUtil_isBound(threadData_t *threadData, modelica_metatype _inBinding)
{
modelica_boolean _outIsBound;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inBinding;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
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
_outIsBound = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsBound;
}
modelica_metatype boxptr_DAEUtil_isBound(threadData_t *threadData, modelica_metatype _inBinding)
{
modelica_boolean _outIsBound;
modelica_metatype out_outIsBound;
_outIsBound = omc_DAEUtil_isBound(threadData, _inBinding);
out_outIsBound = mmc_mk_icon(_outIsBound);
return out_outIsBound;
}
DLLExport
modelica_metatype omc_DAEUtil_bindingExp(threadData_t *threadData, modelica_metatype _bind)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _bind;
{
modelica_metatype _e = NULL;
modelica_metatype _v = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,0) == 0) goto tmp2_end;
tmpMeta[0] = mmc_mk_none();
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_v = tmpMeta[2];
_e = omc_ValuesUtil_valueExp(threadData, _v, mmc_mk_none());
tmpMeta[0] = mmc_mk_some(_e);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_e = tmpMeta[1];
tmpMeta[0] = mmc_mk_some(_e);
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_v = tmpMeta[1];
_e = omc_ValuesUtil_valueExp(threadData, _v, mmc_mk_none());
tmpMeta[0] = mmc_mk_some(_e);
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
DLLExport
modelica_metatype omc_DAEUtil_varType(threadData_t *threadData, modelica_metatype _var)
{
modelica_metatype _type_ = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _var;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_type_ = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _type_;
}
DLLExport
modelica_boolean omc_DAEUtil_typeVarIdentEqual(threadData_t *threadData, modelica_metatype _var, modelica_string _name)
{
modelica_boolean _b;
modelica_string _name2 = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _var;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_name2 = tmpMeta[1];
_b = (stringEqual(_name, _name2));
_return: OMC_LABEL_UNUSED
return _b;
}
modelica_metatype boxptr_DAEUtil_typeVarIdentEqual(threadData_t *threadData, modelica_metatype _var, modelica_metatype _name)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_typeVarIdentEqual(threadData, _var, _name);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_string omc_DAEUtil_typeVarIdent(threadData_t *threadData, modelica_metatype _var)
{
modelica_string _name = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _var;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_name = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _name;
}
DLLExport
modelica_string omc_DAEUtil_varName(threadData_t *threadData, modelica_metatype _var)
{
modelica_string _name = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _var;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_name = tmpMeta[2];
_return: OMC_LABEL_UNUSED
return _name;
}
DLLExport
modelica_metatype omc_DAEUtil_translateSCodeAttrToDAEAttr(threadData_t *threadData, modelica_metatype _inAttributes, modelica_metatype _inPrefixes)
{
modelica_metatype _outAttributes = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _var = NULL;
modelica_metatype _dir = NULL;
modelica_metatype _io = NULL;
modelica_metatype _vis = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inAttributes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
_ct = tmpMeta[1];
_prl = tmpMeta[2];
_var = tmpMeta[3];
_dir = tmpMeta[4];
tmpMeta[0] = _inPrefixes;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_vis = tmpMeta[1];
_io = tmpMeta[2];
tmpMeta[0] = mmc_mk_box7(3, &DAE_Attributes_ATTR__desc, omc_DAEUtil_toConnectorTypeNoState(threadData, _ct, mmc_mk_none()), _prl, _var, _dir, _io, _vis);
_outAttributes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttributes;
}
DLLExport
modelica_metatype omc_DAEUtil_getAttrInnerOuter(threadData_t *threadData, modelica_metatype _attr)
{
modelica_metatype _io = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_io = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 6)));
_return: OMC_LABEL_UNUSED
return _io;
}
DLLExport
modelica_metatype omc_DAEUtil_setAttrInnerOuter(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fattr, modelica_metatype _io)
{
modelica_metatype _attr = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_attr = __omcQ_24in_5Fattr;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_attr), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[6] = _io;
_attr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _attr;
}
DLLExport
modelica_metatype omc_DAEUtil_getAttrDirection(threadData_t *threadData, modelica_metatype _attr)
{
modelica_metatype _dir = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_dir = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 5)));
_return: OMC_LABEL_UNUSED
return _dir;
}
DLLExport
modelica_metatype omc_DAEUtil_setAttrDirection(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fattr, modelica_metatype _dir)
{
modelica_metatype _attr = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_attr = __omcQ_24in_5Fattr;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_attr), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = _dir;
_attr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _attr;
}
DLLExport
modelica_metatype omc_DAEUtil_getAttrVariability(threadData_t *threadData, modelica_metatype _attr)
{
modelica_metatype _var = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_var = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_attr), 4)));
_return: OMC_LABEL_UNUSED
return _var;
}
DLLExport
modelica_metatype omc_DAEUtil_setAttrVariability(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fattr, modelica_metatype _var)
{
modelica_metatype _attr = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_attr = __omcQ_24in_5Fattr;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_attr), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = _var;
_attr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _attr;
}
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_showCacheFuncs(threadData_t *threadData, modelica_metatype _tree)
{
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_string _msg = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
_msg = stringDelimitList(omc_DAEUtil_getFunctionsInfo(threadData, _tree), _OMC_LIT26);
tmpMeta[0] = stringAppend(_OMC_LIT27,_msg);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT28);
fputs(MMC_STRINGDATA(tmpMeta[1]),stdout);
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
modelica_string omc_DAEUtil_getInfo(threadData_t *threadData, modelica_metatype _tpl)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _tpl;
{
modelica_metatype _p = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!optionNone(tmpMeta[1])) goto tmp3_end;
_p = tmpMeta[0];
tmpMeta[0] = stringAppend(omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT29, 1, 0),_OMC_LIT30);
tmp1 = tmpMeta[0];
goto tmp3_done;
}
case 1: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_p = tmpMeta[0];
tmpMeta[0] = stringAppend(omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT29, 1, 0),_OMC_LIT31);
tmp1 = tmpMeta[0];
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype omc_DAEUtil_getFunctionsInfo(threadData_t *threadData, modelica_metatype _ft)
{
modelica_metatype _strs = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _lst = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_lst = omc_DAE_AvlTreePathFunction_toList(threadData, _ft, tmpMeta[1]);
_strs = omc_List_map(threadData, _lst, boxvar_DAEUtil_getInfo);
tmpMeta[0] = omc_List_sort(threadData, _strs, boxvar_Util_strcmpBool);
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
_strs = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _strs;
}
DLLExport
modelica_metatype omc_DAEUtil_addDaeExtFunction(threadData_t *threadData, modelica_metatype _ifuncs, modelica_metatype _itree)
{
modelica_metatype _outTree = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _ifuncs;
tmp3_2 = _itree;
{
modelica_metatype _func = NULL;
modelica_metatype _funcs = NULL;
modelica_metatype _tree = NULL;
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
_tree = tmp3_2;
tmp3 += 2;
tmpMeta[0] = _tree;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_func = tmpMeta[1];
_funcs = tmpMeta[2];
_tree = tmp3_2;
tmp5 = omc_DAEUtil_isExtFunction(threadData, _func);
if (1 != tmp5) goto goto_1;
_tree = omc_DAE_AvlTreePathFunction_add(threadData, _tree, omc_DAEUtil_functionName(threadData, _func), mmc_mk_some(_func), boxvar_DAE_AvlTreePathFunction_addConflictDefault);
tmpMeta[0] = omc_DAEUtil_addDaeExtFunction(threadData, _funcs, _tree);
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_funcs = tmpMeta[2];
_tree = tmp3_2;
tmpMeta[0] = omc_DAEUtil_addDaeExtFunction(threadData, _funcs, _tree);
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
_outTree = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outTree;
}
DLLExport
modelica_metatype omc_DAEUtil_addFunctionDefinition(threadData_t *threadData, modelica_metatype _ifunc, modelica_metatype _iFuncDef)
{
modelica_metatype _func = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_func = _ifunc;
{
modelica_metatype tmp3_1;
tmp3_1 = _func;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,10) == 0) goto tmp2_end;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_func), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = omc_List_appendElt(threadData, _iFuncDef, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 3))));
_func = tmpMeta[0];
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
return _func;
}
DLLExport
modelica_metatype omc_DAEUtil_addDaeFunction(threadData_t *threadData, modelica_metatype _functions, modelica_metatype __omcQ_24in_5FfunctionTree)
{
modelica_metatype _functionTree = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_functionTree = __omcQ_24in_5FfunctionTree;
{
modelica_metatype _f;
for (tmpMeta[0] = _functions; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_f = MMC_CAR(tmpMeta[0]);
_functionTree = omc_DAE_AvlTreePathFunction_add(threadData, _functionTree, omc_DAEUtil_functionName(threadData, _f), mmc_mk_some(_f), boxvar_DAE_AvlTreePathFunction_addConflictDefault);
}
}
_return: OMC_LABEL_UNUSED
return _functionTree;
}
DLLExport
modelica_metatype omc_DAEUtil_collectFunctionRefVarPaths(threadData_t *threadData, modelica_metatype _inElem, modelica_metatype _acc)
{
modelica_metatype _outAcc = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElem;
{
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],11,4) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
_path = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_path, _acc);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
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
_outAcc = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAcc;
}
DLLExport
modelica_metatype omc_DAEUtil_collectValueblockFunctionRefVars(threadData_t *threadData, modelica_metatype _exp, modelica_metatype _acc, modelica_metatype *out_outAcc)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outAcc = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
modelica_metatype _decls = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,33,6) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_decls = tmpMeta[2];
_outAcc = omc_List_fold(threadData, _decls, boxvar_DAEUtil_collectFunctionRefVarPaths, _acc);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _outAcc;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _acc;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outAcc = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outAcc) { *out_outAcc = _outAcc; }
return _outExp;
}
DLLExport
modelica_string omc_DAEUtil_printBindingSourceStr(threadData_t *threadData, modelica_metatype _bindingSource)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _bindingSource;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT32;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT33;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
tmp1 = _OMC_LIT34;
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_string omc_DAEUtil_printBindingExpStr(threadData_t *threadData, modelica_metatype _binding)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _binding;
{
modelica_metatype _e = NULL;
modelica_metatype _v = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT7;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_e = tmpMeta[0];
tmp1 = omc_ExpressionDump_printExpStr(threadData, _e);
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,2) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_v = tmpMeta[0];
tmpMeta[0] = stringAppend(_OMC_LIT35,omc_ValuesUtil_valString(threadData, _v));
tmp1 = tmpMeta[0];
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype omc_DAEUtil_setBindingSource(threadData_t *threadData, modelica_metatype _inBinding, modelica_metatype _bindingSource)
{
modelica_metatype _outBinding = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inBinding;
{
modelica_metatype _exp = NULL;
modelica_metatype _evaluatedExp = NULL;
modelica_metatype _cnst = NULL;
modelica_metatype _valBound = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = _inBinding;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_exp = tmpMeta[1];
_evaluatedExp = tmpMeta[2];
_cnst = tmpMeta[3];
tmpMeta[1] = mmc_mk_box5(4, &DAE_Binding_EQBOUND__desc, _exp, _evaluatedExp, _cnst, _bindingSource);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_valBound = tmpMeta[1];
tmpMeta[1] = mmc_mk_box3(5, &DAE_Binding_VALBOUND__desc, _valBound, _bindingSource);
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
_outBinding = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outBinding;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_makeEvaluatedParamFinal(threadData_t *threadData, modelica_metatype _inElement, modelica_metatype _ht)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_metatype _cr = NULL;
modelica_metatype _varOpt = NULL;
modelica_string _id = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _source = NULL;
modelica_metatype _cmt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,0) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 12));
_cr = tmpMeta[1];
_varOpt = tmpMeta[3];
tmpMeta[0] = (omc_AvlSetCR_hasKey(threadData, _ht, _cr)?omc_DAEUtil_setVariableAttributes(threadData, _inElement, omc_DAEUtil_setFinalAttr(threadData, _varOpt, 1)):_inElement);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_id = tmpMeta[1];
_elts = tmpMeta[2];
_source = tmpMeta[3];
_cmt = tmpMeta[4];
_elts = omc_List_map1(threadData, _elts, boxvar_DAEUtil_makeEvaluatedParamFinal, _ht);
tmpMeta[1] = mmc_mk_box5(20, &DAE_Element_COMP__desc, _id, _elts, _source, _cmt);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
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
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_transformationsBeforeBackendNotification(threadData_t *threadData, modelica_metatype _ht)
{
modelica_metatype _crs = NULL;
modelica_metatype _strs = NULL;
modelica_string _str = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_crs = omc_AvlSetCR_listKeys(threadData, _ht, tmpMeta[0]);
if((!listEmpty(_crs)))
{
_strs = omc_List_map(threadData, _crs, boxvar_ComponentReference_printComponentRefStr);
_str = stringDelimitList(_strs, _OMC_LIT36);
tmpMeta[0] = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT41, tmpMeta[0]);
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_DAEUtil_transformationsBeforeBackend(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inDAElist)
{
modelica_metatype _outDAElist = NULL;
modelica_metatype _dAElist = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _ht = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_dAElist = omc_StateMachineFlatten_stateMachineToDataFlow(threadData, _cache, _env, _inDAElist);
if(omc_Flags_isSet(threadData, _OMC_LIT49))
{
tmpMeta[0] = _dAElist;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_elts = tmpMeta[1];
tmpMeta[0] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elts);
_outDAElist = tmpMeta[0];
}
else
{
tmpMeta[0] = _dAElist;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_elts = tmpMeta[1];
_ht = omc_FCore_getEvaluatedParams(threadData, _cache);
_elts = omc_List_map1(threadData, _elts, boxvar_DAEUtil_makeEvaluatedParamFinal, _ht);
if(omc_Flags_isSet(threadData, _OMC_LIT45))
{
omc_DAEUtil_transformationsBeforeBackendNotification(threadData, _ht);
}
tmpMeta[0] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elts);
_outDAElist = tmpMeta[0];
}
_return: OMC_LABEL_UNUSED
return _outDAElist;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getDAEDeclsFromValueblocks(threadData_t *threadData, modelica_metatype _exps)
{
modelica_metatype _outEls = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outEls = tmpMeta[0];
{
modelica_metatype _ex;
for (tmpMeta[1] = _exps; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_ex = MMC_CAR(tmpMeta[1]);
{
modelica_metatype tmp3_1;
tmp3_1 = _ex;
{
modelica_metatype _els1 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,33,6) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_els1 = tmpMeta[2];
_outEls = omc_List_append__reverse(threadData, _els1, _outEls);
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
_outEls = listReverseInPlace(_outEls);
_return: OMC_LABEL_UNUSED
return _outEls;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getUniontypePathsElements(threadData_t *threadData, modelica_metatype _elements, modelica_metatype _acc)
{
modelica_metatype _outPaths = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _elements;
{
modelica_metatype _rest = NULL;
modelica_metatype _tys = NULL;
modelica_metatype _ft = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_List_applyAndFold(threadData, _acc, boxvar_listAppend, boxvar_Types_getUniontypePaths, tmpMeta[1]);
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,13) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
_ft = tmpMeta[3];
_rest = tmpMeta[2];
_tys = omc_Types_getAllInnerTypesOfType(threadData, _ft, boxvar_Types_uniontypeFilter);
_elements = _rest;
_acc = listAppend(_tys, _acc);
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_rest = tmpMeta[2];
_elements = _rest;
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
_outPaths = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outPaths;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getUniontypePathsFunctions(threadData_t *threadData, modelica_metatype _elements)
{
modelica_metatype _outPaths = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_metatype _els = NULL;
modelica_metatype _els1 = NULL;
modelica_metatype _els2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = mmc_mk_box2(0, boxvar_DAEUtil_collectLocalDecls, tmpMeta[3]);
omc_DAEUtil_traverseDAEFunctions(threadData, _elements, boxvar_Expression_traverseSubexpressionsHelper, tmpMeta[4], &tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_els1 = tmpMeta[2];
_els2 = omc_DAEUtil_getFunctionsElements(threadData, _elements);
_els = listAppend(_els1, _els2);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_DAEUtil_getUniontypePathsElements(threadData, _els, tmpMeta[1]);
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
_outPaths = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outPaths;
}
DLLExport
modelica_metatype omc_DAEUtil_getUniontypePaths(threadData_t *threadData, modelica_metatype _funcs, modelica_metatype _els)
{
modelica_metatype _outPaths = NULL;
modelica_metatype _paths1 = NULL;
modelica_metatype _paths2 = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
modelica_boolean tmp5;
tmp5 = omc_Config_acceptMetaModelicaGrammar(threadData);
if (0 != tmp5) goto goto_1;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
_paths1 = omc_DAEUtil_getUniontypePathsFunctions(threadData, _funcs);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_paths2 = omc_DAEUtil_getUniontypePathsElements(threadData, _els, tmpMeta[1]);
tmpMeta[0] = listAppend(_paths1, _paths2);
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
_outPaths = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outPaths;
}
DLLExport
modelica_metatype omc_DAEUtil_collectLocalDecls(threadData_t *threadData, modelica_metatype _e, modelica_metatype _inElements, modelica_metatype *out_outElements)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outElements = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _e;
tmp4_2 = _inElements;
{
modelica_metatype _ld1 = NULL;
modelica_metatype _ld2 = NULL;
modelica_metatype _ld = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,33,6) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_ld1 = tmpMeta[2];
_ld2 = tmp4_2;
_ld = listAppend(_ld1, _ld2);
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _ld;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _inElements;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outElements = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outElements) { *out_outElements = _outElements; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_isIfEquation(threadData_t *threadData, modelica_metatype _inElement)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,12,4) == 0) goto tmp2_end;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,4) == 0) goto tmp2_end;
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
modelica_metatype omc_DAEUtil_splitComponent(threadData_t *threadData, modelica_metatype _component)
{
modelica_metatype _splitComponent = NULL;
modelica_metatype _v = NULL;
modelica_metatype _ie = NULL;
modelica_metatype _ia = NULL;
modelica_metatype _e = NULL;
modelica_metatype _a = NULL;
modelica_metatype _co = NULL;
modelica_metatype _o = NULL;
modelica_metatype _ca = NULL;
modelica_metatype _sm = NULL;
modelica_metatype _split_el = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _component;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,4) == 0) goto tmp2_end;
_v = omc_DAEUtil_splitElements(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_component), 3))) ,&_ie ,&_ia ,&_e ,&_a ,&_co ,&_o ,&_ca ,&_sm, NULL);
tmpMeta[1] = mmc_mk_box10(3, &DAEDump_splitElements_SPLIT__ELEMENTS__desc, _v, _ie, _ia, _e, _a, _co, _o, _ca, _sm);
_split_el = tmpMeta[1];
tmpMeta[1] = mmc_mk_box4(3, &DAEDump_compWithSplitElements_COMP__WITH__SPLIT__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_component), 2))), _split_el, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_component), 5))));
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
_splitComponent = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _splitComponent;
}
DLLExport
modelica_metatype omc_DAEUtil_splitElements(threadData_t *threadData, modelica_metatype _elements, modelica_metatype *out_initialEquations, modelica_metatype *out_initialAlgorithms, modelica_metatype *out_equations, modelica_metatype *out_algorithms, modelica_metatype *out_classAttributes, modelica_metatype *out_constraints, modelica_metatype *out_externalObjects, modelica_metatype *out_stateMachineComps, modelica_metatype *out_comments)
{
modelica_metatype _variables = NULL;
modelica_metatype _initialEquations = NULL;
modelica_metatype _initialAlgorithms = NULL;
modelica_metatype _equations = NULL;
modelica_metatype _algorithms = NULL;
modelica_metatype _classAttributes = NULL;
modelica_metatype _constraints = NULL;
modelica_metatype _externalObjects = NULL;
modelica_metatype _stateMachineComps = NULL;
modelica_metatype _comments = NULL;
modelica_metatype _split_comp = NULL;
modelica_metatype tmpMeta[12] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_variables = tmpMeta[0];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_initialEquations = tmpMeta[1];
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
_initialAlgorithms = tmpMeta[2];
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
_equations = tmpMeta[3];
tmpMeta[4] = MMC_REFSTRUCTLIT(mmc_nil);
_algorithms = tmpMeta[4];
tmpMeta[5] = MMC_REFSTRUCTLIT(mmc_nil);
_classAttributes = tmpMeta[5];
tmpMeta[6] = MMC_REFSTRUCTLIT(mmc_nil);
_constraints = tmpMeta[6];
tmpMeta[7] = MMC_REFSTRUCTLIT(mmc_nil);
_externalObjects = tmpMeta[7];
tmpMeta[8] = MMC_REFSTRUCTLIT(mmc_nil);
_stateMachineComps = tmpMeta[8];
tmpMeta[9] = MMC_REFSTRUCTLIT(mmc_nil);
_comments = tmpMeta[9];
{
modelica_metatype _e;
for (tmpMeta[10] = _elements; !listEmpty(tmpMeta[10]); tmpMeta[10]=MMC_CDR(tmpMeta[10]))
{
_e = MMC_CAR(tmpMeta[10]);
{
modelica_metatype tmp3_1;
tmp3_1 = _e;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[11] = mmc_mk_cons(_e, _variables);
_variables = tmpMeta[11];
goto tmp2_done;
}
case 17: {
tmpMeta[11] = mmc_mk_cons(_e, _initialEquations);
_initialEquations = tmpMeta[11];
goto tmp2_done;
}
case 9: {
tmpMeta[11] = mmc_mk_cons(_e, _initialEquations);
_initialEquations = tmpMeta[11];
goto tmp2_done;
}
case 12: {
tmpMeta[11] = mmc_mk_cons(_e, _initialEquations);
_initialEquations = tmpMeta[11];
goto tmp2_done;
}
case 5: {
tmpMeta[11] = mmc_mk_cons(_e, _initialEquations);
_initialEquations = tmpMeta[11];
goto tmp2_done;
}
case 16: {
tmpMeta[11] = mmc_mk_cons(_e, _initialEquations);
_initialEquations = tmpMeta[11];
goto tmp2_done;
}
case 23: {
tmpMeta[11] = mmc_mk_cons(_e, _initialEquations);
_initialEquations = tmpMeta[11];
goto tmp2_done;
}
case 25: {
tmpMeta[11] = mmc_mk_cons(_e, _initialEquations);
_initialEquations = tmpMeta[11];
goto tmp2_done;
}
case 28: {
tmpMeta[11] = mmc_mk_cons(_e, _initialEquations);
_initialEquations = tmpMeta[11];
goto tmp2_done;
}
case 19: {
tmpMeta[11] = mmc_mk_cons(_e, _initialAlgorithms);
_initialAlgorithms = tmpMeta[11];
goto tmp2_done;
}
case 6: {
tmpMeta[11] = mmc_mk_cons(_e, _equations);
_equations = tmpMeta[11];
goto tmp2_done;
}
case 7: {
tmpMeta[11] = mmc_mk_cons(_e, _equations);
_equations = tmpMeta[11];
goto tmp2_done;
}
case 8: {
tmpMeta[11] = mmc_mk_cons(_e, _equations);
_equations = tmpMeta[11];
goto tmp2_done;
}
case 11: {
tmpMeta[11] = mmc_mk_cons(_e, _equations);
_equations = tmpMeta[11];
goto tmp2_done;
}
case 4: {
tmpMeta[11] = mmc_mk_cons(_e, _equations);
_equations = tmpMeta[11];
goto tmp2_done;
}
case 22: {
tmpMeta[11] = mmc_mk_cons(_e, _equations);
_equations = tmpMeta[11];
goto tmp2_done;
}
case 24: {
tmpMeta[11] = mmc_mk_cons(_e, _equations);
_equations = tmpMeta[11];
goto tmp2_done;
}
case 15: {
tmpMeta[11] = mmc_mk_cons(_e, _equations);
_equations = tmpMeta[11];
goto tmp2_done;
}
case 14: {
tmpMeta[11] = mmc_mk_cons(_e, _equations);
_equations = tmpMeta[11];
goto tmp2_done;
}
case 13: {
tmpMeta[11] = mmc_mk_cons(_e, _equations);
_equations = tmpMeta[11];
goto tmp2_done;
}
case 26: {
tmpMeta[11] = mmc_mk_cons(_e, _equations);
_equations = tmpMeta[11];
goto tmp2_done;
}
case 27: {
tmpMeta[11] = mmc_mk_cons(_e, _equations);
_equations = tmpMeta[11];
goto tmp2_done;
}
case 18: {
tmpMeta[11] = mmc_mk_cons(_e, _algorithms);
_algorithms = tmpMeta[11];
goto tmp2_done;
}
case 29: {
tmpMeta[11] = mmc_mk_cons(_e, _constraints);
_constraints = tmpMeta[11];
goto tmp2_done;
}
case 30: {
tmpMeta[11] = mmc_mk_cons(_e, _classAttributes);
_classAttributes = tmpMeta[11];
goto tmp2_done;
}
case 21: {
tmpMeta[11] = mmc_mk_cons(_e, _externalObjects);
_externalObjects = tmpMeta[11];
goto tmp2_done;
}
case 20: {
_variables = listAppend((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 3))), _variables);
goto tmp2_done;
}
case 31: {
tmpMeta[11] = mmc_mk_box5(20, &DAE_Element_COMP__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 3))), _OMC_LIT53, _OMC_LIT57);
_split_comp = omc_DAEUtil_splitComponent(threadData, tmpMeta[11]);
tmpMeta[11] = mmc_mk_cons(_split_comp, _stateMachineComps);
_stateMachineComps = tmpMeta[11];
goto tmp2_done;
}
case 32: {
tmpMeta[11] = mmc_mk_box5(20, &DAE_Element_COMP__desc, omc_ComponentReference_crefStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 2)))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 3))), _OMC_LIT53, _OMC_LIT61);
_split_comp = omc_DAEUtil_splitComponent(threadData, tmpMeta[11]);
tmpMeta[11] = mmc_mk_cons(_split_comp, _stateMachineComps);
_stateMachineComps = tmpMeta[11];
goto tmp2_done;
}
case 33: {
tmpMeta[11] = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 2))), _comments);
_comments = tmpMeta[11];
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
omc_Error_addInternalError(threadData, _OMC_LIT62, _OMC_LIT51);
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
}
}
_variables = listReverse(_variables);
_initialEquations = listReverse(_initialEquations);
_initialAlgorithms = listReverse(_initialAlgorithms);
_equations = listReverse(_equations);
_algorithms = listReverse(_algorithms);
_classAttributes = listReverse(_classAttributes);
_constraints = listReverse(_constraints);
_externalObjects = listReverse(_externalObjects);
_stateMachineComps = listReverse(_stateMachineComps);
_return: OMC_LABEL_UNUSED
if (out_initialEquations) { *out_initialEquations = _initialEquations; }
if (out_initialAlgorithms) { *out_initialAlgorithms = _initialAlgorithms; }
if (out_equations) { *out_equations = _equations; }
if (out_algorithms) { *out_algorithms = _algorithms; }
if (out_classAttributes) { *out_classAttributes = _classAttributes; }
if (out_constraints) { *out_constraints = _constraints; }
if (out_externalObjects) { *out_externalObjects = _externalObjects; }
if (out_stateMachineComps) { *out_stateMachineComps = _stateMachineComps; }
if (out_comments) { *out_comments = _comments; }
return _variables;
}
DLLExport
modelica_metatype omc_DAEUtil_joinDaeLst(threadData_t *threadData, modelica_metatype _idaeLst)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _idaeLst;
{
modelica_metatype _dae = NULL;
modelica_metatype _dae1 = NULL;
modelica_metatype _daeLst = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (!listEmpty(tmpMeta[2])) goto tmp2_end;
_dae = tmpMeta[1];
tmpMeta[0] = _dae;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_dae = tmpMeta[1];
_daeLst = tmpMeta[2];
_dae1 = omc_DAEUtil_joinDaeLst(threadData, _daeLst);
tmpMeta[0] = omc_DAEUtil_joinDaes(threadData, _dae, _dae1);
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
_outDae = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDae;
}
DLLExport
modelica_metatype omc_DAEUtil_joinDaes(threadData_t *threadData, modelica_metatype _dae1, modelica_metatype _dae2)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _dae1;
tmp3_2 = _dae2;
{
modelica_metatype _elts1 = NULL;
modelica_metatype _elts2 = NULL;
modelica_metatype _elts = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
_elts1 = tmpMeta[1];
_elts2 = tmpMeta[2];
_elts = listAppend(_elts1, _elts2);
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elts);
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
_outDae = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDae;
}
DLLExport
modelica_metatype omc_DAEUtil_daeElements(threadData_t *threadData, modelica_metatype _dae)
{
modelica_metatype _elts = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _dae;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_elts = tmpMeta[1];
tmpMeta[0] = _elts;
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
modelica_boolean omc_DAEUtil_convertInlineTypeToBool(threadData_t *threadData, modelica_metatype _it)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _it;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_convertInlineTypeToBool(threadData_t *threadData, modelica_metatype _it)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_convertInlineTypeToBool(threadData, _it);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_DAEUtil_functionName(threadData_t *threadData, modelica_metatype _elt)
{
modelica_metatype _name = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _elt;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,10) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_name = tmpMeta[1];
tmpMeta[0] = _name;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_name = tmpMeta[1];
tmpMeta[0] = _name;
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
_name = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _name;
}
DLLExport
modelica_boolean omc_DAEUtil_isExtFunction(threadData_t *threadData, modelica_metatype _elt)
{
modelica_boolean _res;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,10) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,2) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_isExtFunction(threadData_t *threadData, modelica_metatype _elt)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_DAEUtil_isExtFunction(threadData, _elt);
out_res = mmc_mk_icon(_res);
return out_res;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_addComponentType2(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felt, modelica_metatype _inPath)
{
modelica_metatype _elt = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elt = __omcQ_24in_5Felt;
{
modelica_metatype tmp3_1;
tmp3_1 = _elt;
{
modelica_metatype _source = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(15));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_elt), 15*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[11] = omc_ElementSource_addElementSourceType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_elt), 11))), _inPath);
_elt = tmpMeta[1];
tmpMeta[0] = _elt;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _elt;
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
DLLExport
modelica_metatype omc_DAEUtil_addComponentType(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fdae, modelica_metatype _newtype)
{
modelica_metatype _dae = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_dae = __omcQ_24in_5Fdae;
if((!(omc_Flags_isSet(threadData, _OMC_LIT66) || omc_Flags_isSet(threadData, _OMC_LIT70))))
{
goto _return;
}
{
modelica_metatype tmp3_1;
tmp3_1 = _dae;
{
modelica_metatype _elts = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_elts = tmpMeta[1];
_elts = omc_List_map1(threadData, _elts, boxvar_DAEUtil_addComponentType2, _newtype);
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elts);
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
_dae = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _dae;
}
DLLExport
modelica_metatype omc_DAEUtil_addComponentTypeOpt(threadData_t *threadData, modelica_metatype _inDae, modelica_metatype _inPath)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inDae;
tmp3_2 = _inPath;
{
modelica_metatype _p = NULL;
modelica_metatype _dae = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
_p = tmpMeta[1];
_dae = tmp3_1;
tmpMeta[0] = omc_DAEUtil_addComponentType(threadData, _dae, _p);
goto tmp2_done;
}
case 1: {
if (!optionNone(tmp3_2)) goto tmp2_end;
_dae = tmp3_1;
tmpMeta[0] = _dae;
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
_outDae = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDae;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEVarAttr(threadData_t *threadData, modelica_metatype _attr, modelica_fnptr _func, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg)
{
modelica_metatype _traversedDaeList = NULL;
modelica_metatype _oextraArg = NULL;
modelica_metatype tmpMeta[18] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _attr;
tmp4_2 = _iextraArg;
{
modelica_metatype _quantity = NULL;
modelica_metatype _unit = NULL;
modelica_metatype _displayUnit = NULL;
modelica_metatype _min = NULL;
modelica_metatype _max = NULL;
modelica_metatype _start = NULL;
modelica_metatype _fixed = NULL;
modelica_metatype _nominal = NULL;
modelica_metatype _eb = NULL;
modelica_metatype _so = NULL;
modelica_metatype _stateSelect = NULL;
modelica_metatype _uncertainty = NULL;
modelica_metatype _distribution = NULL;
modelica_metatype _ip = NULL;
modelica_metatype _fn = NULL;
modelica_metatype _extraArg = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,15) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 9));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 10));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 11));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 12));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 13));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 14));
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 15));
tmpMeta[17] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 16));
_quantity = tmpMeta[3];
_unit = tmpMeta[4];
_displayUnit = tmpMeta[5];
_min = tmpMeta[6];
_max = tmpMeta[7];
_start = tmpMeta[8];
_fixed = tmpMeta[9];
_nominal = tmpMeta[10];
_stateSelect = tmpMeta[11];
_uncertainty = tmpMeta[12];
_distribution = tmpMeta[13];
_eb = tmpMeta[14];
_ip = tmpMeta[15];
_fn = tmpMeta[16];
_so = tmpMeta[17];
_extraArg = tmp4_2;
_quantity = omc_DAEUtil_traverseDAEOptExp(threadData, _quantity, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_unit = omc_DAEUtil_traverseDAEOptExp(threadData, _unit, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_displayUnit = omc_DAEUtil_traverseDAEOptExp(threadData, _displayUnit, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_min = omc_DAEUtil_traverseDAEOptExp(threadData, _min, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_max = omc_DAEUtil_traverseDAEOptExp(threadData, _max, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_start = omc_DAEUtil_traverseDAEOptExp(threadData, _start, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_fixed = omc_DAEUtil_traverseDAEOptExp(threadData, _fixed, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_nominal = omc_DAEUtil_traverseDAEOptExp(threadData, _nominal, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmpMeta[2] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, _quantity, _unit, _displayUnit, _min, _max, _start, _fixed, _nominal, _stateSelect, _uncertainty, _distribution, _eb, _ip, _fn, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta[2]);
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 1: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,11) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 9));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 10));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 11));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 12));
_quantity = tmpMeta[3];
_min = tmpMeta[4];
_max = tmpMeta[5];
_start = tmpMeta[6];
_fixed = tmpMeta[7];
_uncertainty = tmpMeta[8];
_distribution = tmpMeta[9];
_eb = tmpMeta[10];
_ip = tmpMeta[11];
_fn = tmpMeta[12];
_so = tmpMeta[13];
_extraArg = tmp4_2;
_quantity = omc_DAEUtil_traverseDAEOptExp(threadData, _quantity, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_min = omc_DAEUtil_traverseDAEOptExp(threadData, _min, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_max = omc_DAEUtil_traverseDAEOptExp(threadData, _max, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_start = omc_DAEUtil_traverseDAEOptExp(threadData, _start, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_fixed = omc_DAEUtil_traverseDAEOptExp(threadData, _fixed, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmpMeta[2] = mmc_mk_box12(4, &DAE_VariableAttributes_VAR__ATTR__INT__desc, _quantity, _min, _max, _start, _fixed, _uncertainty, _distribution, _eb, _ip, _fn, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta[2]);
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 2: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,7) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
_quantity = tmpMeta[3];
_start = tmpMeta[4];
_fixed = tmpMeta[5];
_eb = tmpMeta[6];
_ip = tmpMeta[7];
_fn = tmpMeta[8];
_so = tmpMeta[9];
_extraArg = tmp4_2;
_quantity = omc_DAEUtil_traverseDAEOptExp(threadData, _quantity, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_start = omc_DAEUtil_traverseDAEOptExp(threadData, _start, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_fixed = omc_DAEUtil_traverseDAEOptExp(threadData, _fixed, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmpMeta[2] = mmc_mk_box8(5, &DAE_VariableAttributes_VAR__ATTR__BOOL__desc, _quantity, _start, _fixed, _eb, _ip, _fn, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta[2]);
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 3: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,2) == 0) goto tmp3_end;
_extraArg = tmp4_2;
tmpMeta[0+0] = _attr;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 4: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,7) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
_quantity = tmpMeta[3];
_start = tmpMeta[4];
_fixed = tmpMeta[5];
_eb = tmpMeta[6];
_ip = tmpMeta[7];
_fn = tmpMeta[8];
_so = tmpMeta[9];
_extraArg = tmp4_2;
_quantity = omc_DAEUtil_traverseDAEOptExp(threadData, _quantity, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_start = omc_DAEUtil_traverseDAEOptExp(threadData, _start, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_fixed = omc_DAEUtil_traverseDAEOptExp(threadData, _fixed, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmpMeta[2] = mmc_mk_box8(7, &DAE_VariableAttributes_VAR__ATTR__STRING__desc, _quantity, _start, _fixed, _eb, _ip, _fn, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta[2]);
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 5: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,9) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 9));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 10));
_quantity = tmpMeta[3];
_min = tmpMeta[4];
_max = tmpMeta[5];
_start = tmpMeta[6];
_fixed = tmpMeta[7];
_eb = tmpMeta[8];
_ip = tmpMeta[9];
_fn = tmpMeta[10];
_so = tmpMeta[11];
_extraArg = tmp4_2;
_quantity = omc_DAEUtil_traverseDAEOptExp(threadData, _quantity, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_start = omc_DAEUtil_traverseDAEOptExp(threadData, _start, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmpMeta[2] = mmc_mk_box10(8, &DAE_VariableAttributes_VAR__ATTR__ENUMERATION__desc, _quantity, _min, _max, _start, _fixed, _eb, _ip, _fn, _so);
tmpMeta[0+0] = mmc_mk_some(tmpMeta[2]);
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 6: {
if (!optionNone(tmp4_1)) goto tmp3_end;
_extraArg = tmp4_2;
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_traversedDaeList = tmpMeta[0+0];
_oextraArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_oextraArg) { *out_oextraArg = _oextraArg; }
return _traversedDaeList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEExpListStmt(threadData_t *threadData, modelica_metatype _iexps, modelica_fnptr _func, modelica_metatype _istmt, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg)
{
modelica_metatype _oexps = NULL;
modelica_metatype _oextraArg = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _iexps;
tmp4_2 = _iextraArg;
{
modelica_metatype _e = NULL;
modelica_metatype _extraArg = NULL;
modelica_metatype _exps = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_extraArg = tmp4_2;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
_e = tmpMeta[2];
_exps = tmpMeta[3];
_extraArg = tmp4_2;
_e = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _istmt, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _istmt, _extraArg ,&_extraArg);
_oexps = omc_DAEUtil_traverseDAEExpListStmt(threadData, _exps, ((modelica_fnptr) _func), _istmt, _extraArg ,&_extraArg);
tmpMeta[2] = mmc_mk_cons(_e, _oexps);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_oexps = tmpMeta[0+0];
_oextraArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_oextraArg) { *out_oextraArg = _oextraArg; }
return _oexps;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEStmtsElse(threadData_t *threadData, modelica_metatype _inElse, modelica_fnptr _func, modelica_metatype _istmt, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg)
{
modelica_metatype _outElse = NULL;
modelica_metatype _oextraArg = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inElse;
tmp4_2 = _iextraArg;
{
modelica_metatype _e = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _st = NULL;
modelica_metatype _st_1 = NULL;
modelica_metatype _el = NULL;
modelica_metatype _el_1 = NULL;
modelica_metatype _extraArg = NULL;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
_extraArg = tmp4_2;
tmpMeta[0+0] = _OMC_LIT71;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta[2];
_st = tmpMeta[3];
_el = tmpMeta[4];
_extraArg = tmp4_2;
_el_1 = omc_DAEUtil_traverseDAEStmtsElse(threadData, _el, ((modelica_fnptr) _func), _istmt, _extraArg ,&_extraArg);
_st_1 = omc_DAEUtil_traverseDAEStmts(threadData, _st, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _istmt, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _istmt, _extraArg ,&_extraArg);
tmpMeta[0+0] = omc_Algorithm_optimizeElseIf(threadData, _e_1, _st_1, _el_1);
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_st = tmpMeta[2];
_extraArg = tmp4_2;
_st_1 = omc_DAEUtil_traverseDAEStmts(threadData, _st, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmpMeta[2] = mmc_mk_box2(5, &DAE_Else_ELSE__desc, _st_1);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outElse = tmpMeta[0+0];
_oextraArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_oextraArg) { *out_oextraArg = _oextraArg; }
return _outElse;
}
DLLExport
modelica_metatype omc_DAEUtil_traverseDAEStmts(threadData_t *threadData, modelica_metatype _inStmts, modelica_fnptr _func, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg)
{
modelica_metatype _outStmts = NULL;
modelica_metatype _oextraArg = NULL;
modelica_metatype tmpMeta[12] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inStmts;
tmp4_2 = _iextraArg;
{
modelica_metatype _e_1 = NULL;
modelica_metatype _e_2 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _e_3 = NULL;
modelica_metatype _expl1 = NULL;
modelica_metatype _expl2 = NULL;
modelica_metatype _xs_1 = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _stmts1 = NULL;
modelica_metatype _stmts2 = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _x = NULL;
modelica_metatype _ew = NULL;
modelica_boolean _b1;
modelica_string _id1 = NULL;
modelica_string _str = NULL;
modelica_integer _ix;
modelica_metatype _source = NULL;
modelica_metatype _algElse = NULL;
modelica_metatype _extraArg = NULL;
modelica_metatype _loopPrlVars = NULL;
modelica_metatype _conditions = NULL;
modelica_boolean _initialCall;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 19; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_extraArg = tmp4_2;
tmp4 += 18;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_x = tmpMeta[2];
_tp = tmpMeta[4];
_e2 = tmpMeta[5];
_e = tmpMeta[6];
_source = tmpMeta[7];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 16;
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg ,&_extraArg);
_e_2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _x, _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmp6 = (modelica_boolean)((referenceEq(_e, _e_1) && referenceEq(_e2, _e_2)) && referenceEq(_xs, _xs_1));
if(tmp6)
{
tmpMeta[4] = _inStmts;
}
else
{
tmpMeta[3] = mmc_mk_box5(3, &DAE_Statement_STMT__ASSIGN__desc, _tp, _e_2, _e_1, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[4] = tmpMeta[2];
}
_outStmts = tmpMeta[4];
tmpMeta[0+0] = _outStmts;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_x = tmpMeta[2];
_tp = tmpMeta[4];
_expl1 = tmpMeta[5];
_e = tmpMeta[6];
_source = tmpMeta[7];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 15;
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg ,&_extraArg);
_expl2 = omc_DAEUtil_traverseDAEExpListStmt(threadData, _expl1, ((modelica_fnptr) _func), _x, _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmp7 = (modelica_boolean)((referenceEq(_e, _e_1) && referenceEq(_expl2, _expl1)) && referenceEq(_xs, _xs_1));
if(tmp7)
{
tmpMeta[4] = _inStmts;
}
else
{
tmpMeta[3] = mmc_mk_box5(4, &DAE_Statement_STMT__TUPLE__ASSIGN__desc, _tp, _expl2, _e_1, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[4] = tmpMeta[2];
}
_outStmts = tmpMeta[4];
tmpMeta[0+0] = _outStmts;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp12;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_x = tmpMeta[2];
_tp = tmpMeta[4];
_e = tmpMeta[5];
_e2 = tmpMeta[6];
_source = tmpMeta[7];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 14;
_e_2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _x, _extraArg ,&_extraArg);
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
tmpMeta[3] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg, &tmpMeta[2]) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg, &tmpMeta[2]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],6,2) == 0) goto goto_8;
_e_1 = tmpMeta[3];
_extraArg = tmpMeta[2];
goto tmp9_done;
}
case 1: {
_e_1 = _e;
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
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmp12 = (modelica_boolean)((referenceEq(_e, _e_1) && referenceEq(_e2, _e_2)) && referenceEq(_xs, _xs_1));
if(tmp12)
{
tmpMeta[4] = _inStmts;
}
else
{
tmpMeta[3] = mmc_mk_box5(5, &DAE_Statement_STMT__ASSIGN__ARR__desc, _tp, _e_1, _e_2, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[4] = tmpMeta[2];
}
_outStmts = tmpMeta[4];
tmpMeta[0+0] = _outStmts;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 4: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_x = tmpMeta[2];
_e = tmpMeta[4];
_stmts = tmpMeta[5];
_algElse = tmpMeta[6];
_source = tmpMeta[7];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 13;
_algElse = omc_DAEUtil_traverseDAEStmtsElse(threadData, _algElse, ((modelica_fnptr) _func), _x, _extraArg ,&_extraArg);
_stmts2 = omc_DAEUtil_traverseDAEStmts(threadData, _stmts, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_stmts1 = omc_Algorithm_optimizeIf(threadData, _e_1, _stmts2, _algElse, _source, NULL);
tmpMeta[0+0] = listAppend(_stmts1, _xs_1);
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 5: {
modelica_integer tmp13;
modelica_integer tmp14;
modelica_boolean tmp15;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,7) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp13 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmp14 = mmc_unbox_integer(tmpMeta[7]);
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
_x = tmpMeta[2];
_tp = tmpMeta[4];
_b1 = tmp13;
_id1 = tmpMeta[6];
_ix = tmp14;
_e = tmpMeta[8];
_stmts = tmpMeta[9];
_source = tmpMeta[10];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 12;
_stmts2 = omc_DAEUtil_traverseDAEStmts(threadData, _stmts, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmp15 = (modelica_boolean)((referenceEq(_e, _e_1) && referenceEq(_stmts, _stmts2)) && referenceEq(_xs, _xs_1));
if(tmp15)
{
tmpMeta[4] = _inStmts;
}
else
{
tmpMeta[3] = mmc_mk_box8(7, &DAE_Statement_STMT__FOR__desc, _tp, mmc_mk_boolean(_b1), _id1, mmc_mk_integer(_ix), _e_1, _stmts2, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[4] = tmpMeta[2];
}
_outStmts = tmpMeta[4];
tmpMeta[0+0] = _outStmts;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 6: {
modelica_integer tmp16;
modelica_integer tmp17;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,8) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp16 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmp17 = mmc_unbox_integer(tmpMeta[7]);
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 9));
_x = tmpMeta[2];
_tp = tmpMeta[4];
_b1 = tmp16;
_id1 = tmpMeta[6];
_ix = tmp17;
_e = tmpMeta[8];
_stmts = tmpMeta[9];
_loopPrlVars = tmpMeta[10];
_source = tmpMeta[11];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 11;
_stmts2 = omc_DAEUtil_traverseDAEStmts(threadData, _stmts, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmpMeta[3] = mmc_mk_box9(8, &DAE_Statement_STMT__PARFOR__desc, _tp, mmc_mk_boolean(_b1), _id1, mmc_mk_integer(_ix), _e_1, _stmts2, _loopPrlVars, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 7: {
modelica_boolean tmp18;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,3) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_x = tmpMeta[2];
_e = tmpMeta[4];
_stmts = tmpMeta[5];
_source = tmpMeta[6];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 10;
_stmts2 = omc_DAEUtil_traverseDAEStmts(threadData, _stmts, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmp18 = (modelica_boolean)((referenceEq(_e, _e_1) && referenceEq(_stmts, _stmts2)) && referenceEq(_xs, _xs_1));
if(tmp18)
{
tmpMeta[4] = _inStmts;
}
else
{
tmpMeta[3] = mmc_mk_box4(9, &DAE_Statement_STMT__WHILE__desc, _e_1, _stmts2, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[4] = tmpMeta[2];
}
_outStmts = tmpMeta[4];
tmpMeta[0+0] = _outStmts;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 8: {
modelica_integer tmp19;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],7,6) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmp19 = mmc_unbox_integer(tmpMeta[6]);
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
if (!optionNone(tmpMeta[8])) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
_x = tmpMeta[2];
_e = tmpMeta[4];
_conditions = tmpMeta[5];
_initialCall = tmp19;
_stmts = tmpMeta[7];
_source = tmpMeta[9];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 9;
_stmts2 = omc_DAEUtil_traverseDAEStmts(threadData, _stmts, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmpMeta[3] = mmc_mk_box7(10, &DAE_Statement_STMT__WHEN__desc, _e_1, _conditions, mmc_mk_boolean(_initialCall), _stmts2, mmc_mk_none(), _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 9: {
modelica_integer tmp20;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],7,6) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmp20 = mmc_unbox_integer(tmpMeta[6]);
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
if (optionNone(tmpMeta[8])) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 1));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
_x = tmpMeta[2];
_e = tmpMeta[4];
_conditions = tmpMeta[5];
_initialCall = tmp20;
_stmts = tmpMeta[7];
_ew = tmpMeta[9];
_source = tmpMeta[10];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 8;
tmpMeta[3] = mmc_mk_cons(_ew, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[4] = omc_DAEUtil_traverseDAEStmts(threadData, tmpMeta[3], ((modelica_fnptr) _func), _extraArg, &tmpMeta[2]);
if (listEmpty(tmpMeta[4])) goto goto_2;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto goto_2;
_extraArg = tmpMeta[2];
_stmts2 = omc_DAEUtil_traverseDAEStmts(threadData, _stmts, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmpMeta[3] = mmc_mk_box7(10, &DAE_Statement_STMT__WHEN__desc, _e_1, _conditions, mmc_mk_boolean(_initialCall), _stmts2, mmc_mk_some(_ew), _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 10: {
modelica_boolean tmp21;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],8,4) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_x = tmpMeta[2];
_e = tmpMeta[4];
_e2 = tmpMeta[5];
_e3 = tmpMeta[6];
_source = tmpMeta[7];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 7;
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg ,&_extraArg);
_e_2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _x, _extraArg ,&_extraArg);
_e_3 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e3, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e3, _x, _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmp21 = (modelica_boolean)(((referenceEq(_e, _e_1) && referenceEq(_e2, _e_2)) && referenceEq(_e3, _e_3)) && referenceEq(_xs, _xs_1));
if(tmp21)
{
tmpMeta[4] = _inStmts;
}
else
{
tmpMeta[3] = mmc_mk_box5(11, &DAE_Statement_STMT__ASSERT__desc, _e_1, _e_2, _e_3, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[4] = tmpMeta[2];
}
_outStmts = tmpMeta[4];
tmpMeta[0+0] = _outStmts;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 11: {
modelica_boolean tmp22;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,2) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_x = tmpMeta[2];
_e = tmpMeta[4];
_source = tmpMeta[5];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 6;
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmp22 = (modelica_boolean)(referenceEq(_e, _e_1) && referenceEq(_xs, _xs_1));
if(tmp22)
{
tmpMeta[4] = _inStmts;
}
else
{
tmpMeta[3] = mmc_mk_box3(12, &DAE_Statement_STMT__TERMINATE__desc, _e_1, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[4] = tmpMeta[2];
}
_outStmts = tmpMeta[4];
tmpMeta[0+0] = _outStmts;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 12: {
modelica_boolean tmp23;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],10,3) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_x = tmpMeta[2];
_e = tmpMeta[4];
_e2 = tmpMeta[5];
_source = tmpMeta[6];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 5;
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg ,&_extraArg);
_e_2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _x, _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmp23 = (modelica_boolean)((referenceEq(_e, _e_1) && referenceEq(_e2, _e_2)) && referenceEq(_xs, _xs_1));
if(tmp23)
{
tmpMeta[4] = _inStmts;
}
else
{
tmpMeta[3] = mmc_mk_box4(13, &DAE_Statement_STMT__REINIT__desc, _e_1, _e_2, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[4] = tmpMeta[2];
}
_outStmts = tmpMeta[4];
tmpMeta[0+0] = _outStmts;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 13: {
modelica_boolean tmp24;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],11,2) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_x = tmpMeta[2];
_e = tmpMeta[4];
_source = tmpMeta[5];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 4;
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _x, _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmp24 = (modelica_boolean)(referenceEq(_e, _e_1) && referenceEq(_xs, _xs_1));
if(tmp24)
{
tmpMeta[4] = _inStmts;
}
else
{
tmpMeta[3] = mmc_mk_box3(14, &DAE_Statement_STMT__NORETCALL__desc, _e_1, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[4] = tmpMeta[2];
}
_outStmts = tmpMeta[4];
tmpMeta[0+0] = _outStmts;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 14: {
modelica_boolean tmp25;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],12,1) == 0) goto tmp3_end;
_x = tmpMeta[2];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 3;
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _OMC_LIT72, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _OMC_LIT72, _x, _extraArg ,&_extraArg);
tmp25 = (modelica_boolean)referenceEq(_xs, _xs_1);
if(tmp25)
{
tmpMeta[3] = _inStmts;
}
else
{
tmpMeta[2] = mmc_mk_cons(_x, _xs_1);
tmpMeta[3] = tmpMeta[2];
}
tmpMeta[0+0] = tmpMeta[3];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 15: {
modelica_boolean tmp26;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],13,1) == 0) goto tmp3_end;
_x = tmpMeta[2];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 2;
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _OMC_LIT72, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _OMC_LIT72, _x, _extraArg ,&_extraArg);
tmp26 = (modelica_boolean)referenceEq(_xs, _xs_1);
if(tmp26)
{
tmpMeta[3] = _inStmts;
}
else
{
tmpMeta[2] = mmc_mk_cons(_x, _xs_1);
tmpMeta[3] = tmpMeta[2];
}
tmpMeta[0+0] = tmpMeta[3];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 16: {
modelica_boolean tmp27;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],14,1) == 0) goto tmp3_end;
_x = tmpMeta[2];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 1;
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _OMC_LIT72, _x, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _OMC_LIT72, _x, _extraArg ,&_extraArg);
tmp27 = (modelica_boolean)referenceEq(_xs, _xs_1);
if(tmp27)
{
tmpMeta[3] = _inStmts;
}
else
{
tmpMeta[2] = mmc_mk_cons(_x, _xs_1);
tmpMeta[3] = tmpMeta[2];
}
tmpMeta[0+0] = tmpMeta[3];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 17: {
modelica_boolean tmp28;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],16,2) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
_stmts = tmpMeta[4];
_source = tmpMeta[5];
_xs = tmpMeta[3];
_extraArg = tmp4_2;
_stmts2 = omc_DAEUtil_traverseDAEStmts(threadData, _stmts, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_xs_1 = omc_DAEUtil_traverseDAEStmts(threadData, _xs, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmp28 = (modelica_boolean)(referenceEq(_stmts, _stmts2) && referenceEq(_xs, _xs_1));
if(tmp28)
{
tmpMeta[4] = _inStmts;
}
else
{
tmpMeta[3] = mmc_mk_box3(19, &DAE_Statement_STMT__FAILURE__desc, _stmts2, _source);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _xs_1);
tmpMeta[4] = tmpMeta[2];
}
_outStmts = tmpMeta[4];
tmpMeta[0+0] = _outStmts;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 18: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
_x = tmpMeta[2];
_str = omc_DAEDump_ppStatementStr(threadData, _x);
tmpMeta[2] = stringAppend(_OMC_LIT73,_str);
_str = tmpMeta[2];
tmpMeta[2] = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT77, tmpMeta[2]);
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
if (++tmp4 < 19) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outStmts = tmpMeta[0+0];
_oextraArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_oextraArg) { *out_oextraArg = _oextraArg; }
return _outStmts;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEEquationsStmtsElse(threadData_t *threadData, modelica_metatype _inElse, modelica_fnptr _func, modelica_metatype _opt, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg)
{
modelica_metatype _outElse = NULL;
modelica_metatype _oextraArg = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inElse;
tmp4_2 = _iextraArg;
{
modelica_metatype _e = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _st = NULL;
modelica_metatype _st_1 = NULL;
modelica_metatype _el = NULL;
modelica_metatype _el_1 = NULL;
modelica_metatype _extraArg = NULL;
modelica_boolean _b;
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
_extraArg = tmp4_2;
tmpMeta[0+0] = _OMC_LIT71;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta[2];
_st = tmpMeta[3];
_el = tmpMeta[4];
_extraArg = tmp4_2;
_el_1 = omc_DAEUtil_traverseDAEEquationsStmtsElse(threadData, _el, ((modelica_fnptr) _func), _opt, _extraArg ,&_extraArg);
_st_1 = omc_DAEUtil_traverseDAEEquationsStmtsList(threadData, _st, ((modelica_fnptr) _func), _opt, _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
_outElse = omc_Algorithm_optimizeElseIf(threadData, _e_1, _st_1, _el_1);
_b = ((referenceEq(_el, _el_1) && referenceEq(_st, _st_1)) && referenceEq(_e, _e_1));
_outElse = (_b?_inElse:_outElse);
tmpMeta[0+0] = _outElse;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 5: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_st = tmpMeta[2];
_extraArg = tmp4_2;
_st_1 = omc_DAEUtil_traverseDAEEquationsStmtsList(threadData, _st, ((modelica_fnptr) _func), _opt, _extraArg ,&_extraArg);
tmp5 = (modelica_boolean)referenceEq(_st, _st_1);
if(tmp5)
{
tmpMeta[3] = _inElse;
}
else
{
tmpMeta[2] = mmc_mk_box2(5, &DAE_Else_ELSE__desc, _st_1);
tmpMeta[3] = tmpMeta[2];
}
_outElse = tmpMeta[3];
tmpMeta[0+0] = _outElse;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outElse = tmpMeta[0+0];
_oextraArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_oextraArg) { *out_oextraArg = _oextraArg; }
return _outElse;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEEquationsStmtsWork(threadData_t *threadData, modelica_metatype _inStmt, modelica_fnptr _func, modelica_metatype _opt, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg)
{
modelica_metatype _outStmts = NULL;
modelica_metatype _oextraArg = NULL;
modelica_metatype tmpMeta[10] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inStmt;
tmp4_2 = _iextraArg;
{
modelica_metatype _e_1 = NULL;
modelica_metatype _e_2 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _e_3 = NULL;
modelica_metatype _expl1 = NULL;
modelica_metatype _expl2 = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _stmts1 = NULL;
modelica_metatype _stmts2 = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _x = NULL;
modelica_metatype _ew = NULL;
modelica_metatype _ew_1 = NULL;
modelica_boolean _b1;
modelica_string _id1 = NULL;
modelica_string _str = NULL;
modelica_integer _ix;
modelica_metatype _source = NULL;
modelica_metatype _algElse = NULL;
modelica_metatype _algElse1 = NULL;
modelica_metatype _extraArg = NULL;
modelica_metatype _loopPrlVars = NULL;
modelica_metatype _conditions = NULL;
modelica_boolean _initialCall;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 18; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_boolean tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_tp = tmpMeta[2];
_e = tmpMeta[3];
_e2 = tmpMeta[4];
_source = tmpMeta[5];
_extraArg = tmp4_2;
tmp4 += 16;
_e_1 = omc_DAEUtil_traverseStatementsOptionsEvalLhs(threadData, _e, _extraArg, ((modelica_fnptr) _func), _opt ,&_extraArg);
_e_2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _extraArg ,&_extraArg);
tmp6 = (modelica_boolean)(referenceEq(_e, _e_1) && referenceEq(_e2, _e_2));
if(tmp6)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box5(3, &DAE_Statement_STMT__ASSIGN__desc, _tp, _e_1, _e_2, _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_tp = tmpMeta[2];
_expl1 = tmpMeta[3];
_e = tmpMeta[4];
_source = tmpMeta[5];
_extraArg = tmp4_2;
tmp4 += 15;
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
tmpMeta[3] = mmc_mk_box2(22, &DAE_Exp_TUPLE__desc, _expl1);
tmpMeta[4] = omc_DAEUtil_traverseStatementsOptionsEvalLhs(threadData, tmpMeta[3], _extraArg, ((modelica_fnptr) _func), _opt, &tmpMeta[2]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],19,1) == 0) goto goto_2;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
_expl2 = tmpMeta[5];
_extraArg = tmpMeta[2];
tmp7 = (modelica_boolean)(referenceEq(_e, _e_1) && referenceEq(_expl1, _expl2));
if(tmp7)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box5(4, &DAE_Statement_STMT__TUPLE__ASSIGN__desc, _tp, _expl2, _e_1, _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_tp = tmpMeta[2];
_e = tmpMeta[3];
_e2 = tmpMeta[4];
_source = tmpMeta[5];
_extraArg = tmp4_2;
tmp4 += 14;
_e_2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _extraArg ,&_extraArg);
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
modelica_boolean tmp12;
tmpMeta[3] = omc_DAEUtil_traverseStatementsOptionsEvalLhs(threadData, _e, _extraArg, ((modelica_fnptr) _func), _opt, &tmpMeta[2]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],6,2) == 0) goto goto_8;
_e_1 = tmpMeta[3];
_extraArg = tmpMeta[2];
tmp12 = (modelica_boolean)(referenceEq(_e2, _e_2) && referenceEq(_e, _e_1));
if(tmp12)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box5(5, &DAE_Statement_STMT__ASSIGN__ARR__desc, _tp, _e_1, _e_2, _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
goto tmp9_done;
}
case 1: {
modelica_boolean tmp13;
modelica_boolean tmp15;
tmp13 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmpMeta[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg, NULL) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,2) == 0) goto goto_14;
tmp13 = 1;
goto goto_14;
goto_14:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp13) {goto goto_8;}
tmp15 = (modelica_boolean)referenceEq(_e2, _e_2);
if(tmp15)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box5(5, &DAE_Statement_STMT__ASSIGN__ARR__desc, _tp, _e, _e_2, _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
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
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 3: {
modelica_boolean tmp16;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e = tmpMeta[2];
_stmts = tmpMeta[3];
_algElse = tmpMeta[4];
_source = tmpMeta[5];
_extraArg = tmp4_2;
tmp4 += 13;
_algElse1 = omc_DAEUtil_traverseDAEEquationsStmtsElse(threadData, _algElse, ((modelica_fnptr) _func), _opt, _extraArg ,&_extraArg);
_stmts2 = omc_DAEUtil_traverseDAEEquationsStmtsList(threadData, _stmts, ((modelica_fnptr) _func), _opt, _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
_stmts1 = omc_Algorithm_optimizeIf(threadData, _e_1, _stmts2, _algElse1, _source ,&_b);
tmp16 = (modelica_boolean)((((!_b) && referenceEq(_e, _e_1)) && referenceEq(_stmts, _stmts2)) && referenceEq(_algElse, _algElse1));
if(tmp16)
{
tmpMeta[2] = mmc_mk_cons(_inStmt, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = tmpMeta[2];
}
else
{
tmpMeta[3] = _stmts1;
}
_stmts1 = tmpMeta[3];
tmpMeta[0+0] = _stmts1;
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 4: {
modelica_integer tmp17;
modelica_integer tmp18;
modelica_boolean tmp19;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,4,7) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp17 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp18 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
_tp = tmpMeta[2];
_b1 = tmp17;
_id1 = tmpMeta[4];
_ix = tmp18;
_e = tmpMeta[6];
_stmts = tmpMeta[7];
_source = tmpMeta[8];
_extraArg = tmp4_2;
tmp4 += 12;
_stmts2 = omc_DAEUtil_traverseDAEEquationsStmtsList(threadData, _stmts, ((modelica_fnptr) _func), _opt, _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
tmp19 = (modelica_boolean)(referenceEq(_e, _e_1) && referenceEq(_stmts, _stmts2));
if(tmp19)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box8(7, &DAE_Statement_STMT__FOR__desc, _tp, mmc_mk_boolean(_b1), _id1, mmc_mk_integer(_ix), _e_1, _stmts2, _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 5: {
modelica_integer tmp20;
modelica_integer tmp21;
modelica_boolean tmp22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,8) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmp20 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmp21 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
_tp = tmpMeta[2];
_b1 = tmp20;
_id1 = tmpMeta[4];
_ix = tmp21;
_e = tmpMeta[6];
_stmts = tmpMeta[7];
_loopPrlVars = tmpMeta[8];
_source = tmpMeta[9];
_extraArg = tmp4_2;
tmp4 += 11;
_stmts2 = omc_DAEUtil_traverseDAEEquationsStmtsList(threadData, _stmts, ((modelica_fnptr) _func), _opt, _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
tmp22 = (modelica_boolean)(referenceEq(_e, _e_1) && referenceEq(_stmts, _stmts2));
if(tmp22)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box9(8, &DAE_Statement_STMT__PARFOR__desc, _tp, mmc_mk_boolean(_b1), _id1, mmc_mk_integer(_ix), _e_1, _stmts2, _loopPrlVars, _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 6: {
modelica_boolean tmp23;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta[2];
_stmts = tmpMeta[3];
_source = tmpMeta[4];
_extraArg = tmp4_2;
tmp4 += 10;
_stmts2 = omc_DAEUtil_traverseDAEEquationsStmtsList(threadData, _stmts, ((modelica_fnptr) _func), _opt, _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
tmp23 = (modelica_boolean)(referenceEq(_e, _e_1) && referenceEq(_stmts, _stmts2));
if(tmp23)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box4(9, &DAE_Statement_STMT__WHILE__desc, _e_1, _stmts2, _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 7: {
modelica_integer tmp24;
modelica_boolean tmp25;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,6) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp24 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (!optionNone(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_e = tmpMeta[2];
_conditions = tmpMeta[3];
_initialCall = tmp24;
_stmts = tmpMeta[5];
_source = tmpMeta[7];
_extraArg = tmp4_2;
tmp4 += 9;
_stmts2 = omc_DAEUtil_traverseDAEEquationsStmtsList(threadData, _stmts, ((modelica_fnptr) _func), _opt, _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
tmp25 = (modelica_boolean)(referenceEq(_e, _e_1) && referenceEq(_stmts, _stmts2));
if(tmp25)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box7(10, &DAE_Statement_STMT__WHEN__desc, _e_1, _conditions, mmc_mk_boolean(_initialCall), _stmts2, mmc_mk_none(), _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 8: {
modelica_integer tmp26;
modelica_boolean tmp27;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,7,6) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp26 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
if (optionNone(tmpMeta[6])) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 1));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
_e = tmpMeta[2];
_conditions = tmpMeta[3];
_initialCall = tmp26;
_stmts = tmpMeta[5];
_ew = tmpMeta[7];
_source = tmpMeta[8];
_extraArg = tmp4_2;
tmp4 += 8;
tmpMeta[3] = mmc_mk_cons(_ew, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[4] = omc_DAEUtil_traverseDAEEquationsStmtsList(threadData, tmpMeta[3], ((modelica_fnptr) _func), _opt, _extraArg, &tmpMeta[2]);
if (listEmpty(tmpMeta[4])) goto goto_2;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (!listEmpty(tmpMeta[6])) goto goto_2;
_ew_1 = tmpMeta[5];
_extraArg = tmpMeta[2];
_stmts2 = omc_DAEUtil_traverseDAEEquationsStmtsList(threadData, _stmts, ((modelica_fnptr) _func), _opt, _extraArg ,&_extraArg);
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
tmp27 = (modelica_boolean)((referenceEq(_ew, _ew_1) && referenceEq(_e, _e_1)) && referenceEq(_stmts, _stmts2));
if(tmp27)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box7(10, &DAE_Statement_STMT__WHEN__desc, _e_1, _conditions, mmc_mk_boolean(_initialCall), _stmts2, mmc_mk_some(_ew_1), _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 9: {
modelica_boolean tmp28;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_e = tmpMeta[2];
_e2 = tmpMeta[3];
_e3 = tmpMeta[4];
_source = tmpMeta[5];
_extraArg = tmp4_2;
tmp4 += 7;
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
_e_2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _extraArg ,&_extraArg);
_e_3 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e3, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e3, _extraArg ,&_extraArg);
tmp28 = (modelica_boolean)((referenceEq(_e, _e_1) && referenceEq(_e2, _e_2)) && referenceEq(_e3, _e_3));
if(tmp28)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box5(11, &DAE_Statement_STMT__ASSERT__desc, _e_1, _e_2, _e_3, _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 10: {
modelica_boolean tmp29;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta[2];
_source = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 6;
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
tmp29 = (modelica_boolean)referenceEq(_e, _e_1);
if(tmp29)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box3(12, &DAE_Statement_STMT__TERMINATE__desc, _e_1, _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 11: {
modelica_boolean tmp30;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_e = tmpMeta[2];
_e2 = tmpMeta[3];
_source = tmpMeta[4];
_extraArg = tmp4_2;
tmp4 += 5;
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
_e_2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _extraArg ,&_extraArg);
tmp30 = (modelica_boolean)(referenceEq(_e, _e_1) && referenceEq(_e2, _e_2));
if(tmp30)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box4(13, &DAE_Statement_STMT__REINIT__desc, _e_1, _e_2, _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 12: {
modelica_boolean tmp31;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,11,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_e = tmpMeta[2];
_source = tmpMeta[3];
_extraArg = tmp4_2;
tmp4 += 4;
_e_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
tmp31 = (modelica_boolean)referenceEq(_e, _e_1);
if(tmp31)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box3(14, &DAE_Statement_STMT__NORETCALL__desc, _e_1, _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,1) == 0) goto tmp3_end;
_x = tmp4_1;
_extraArg = tmp4_2;
tmp4 += 3;
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,1) == 0) goto tmp3_end;
_x = tmp4_1;
_extraArg = tmp4_2;
tmp4 += 2;
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,1) == 0) goto tmp3_end;
_x = tmp4_1;
_extraArg = tmp4_2;
tmp4 += 1;
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 16: {
modelica_boolean tmp32;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,16,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_stmts = tmpMeta[2];
_source = tmpMeta[3];
_extraArg = tmp4_2;
_stmts2 = omc_DAEUtil_traverseDAEEquationsStmtsList(threadData, _stmts, ((modelica_fnptr) _func), _opt, _extraArg ,&_extraArg);
tmp32 = (modelica_boolean)referenceEq(_stmts, _stmts2);
if(tmp32)
{
tmpMeta[3] = _inStmt;
}
else
{
tmpMeta[2] = mmc_mk_box3(19, &DAE_Statement_STMT__FAILURE__desc, _stmts2, _source);
tmpMeta[3] = tmpMeta[2];
}
_x = tmpMeta[3];
tmpMeta[2] = mmc_mk_cons(_x, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 17: {
_x = tmp4_1;
_str = omc_DAEDump_ppStatementStr(threadData, _x);
tmpMeta[2] = stringAppend(_OMC_LIT78,_str);
_str = tmpMeta[2];
tmpMeta[2] = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT77, tmpMeta[2]);
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
if (++tmp4 < 18) {
goto tmp3_top;
}
MMC_THROW_INTERNAL();
tmp3_done2:;
}
}
_outStmts = tmpMeta[0+0];
_oextraArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_oextraArg) { *out_oextraArg = _oextraArg; }
return _outStmts;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseStatementsOptionsEvalLhs(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inA, modelica_fnptr _func, modelica_metatype _opt, modelica_metatype *out_outA)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outA = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _opt;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
tmpMeta[0+0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _inExp, _inA, &tmpMeta[0+1]) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _inExp, _inA, &tmpMeta[0+1]);
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _inA;
goto tmp3_done;
}
}
goto tmp3_end;
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
_outA = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outA) { *out_outA = _outA; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEEquationsStmtsList(threadData_t *threadData, modelica_metatype _inStmts, modelica_fnptr _func, modelica_metatype _opt, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg)
{
modelica_metatype _outStmts = NULL;
modelica_metatype _oextraArg = NULL;
modelica_metatype _outStmtsLst = NULL;
modelica_boolean _b;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outStmtsLst = omc_List_map2Fold(threadData, _inStmts, boxvar_DAEUtil_traverseDAEEquationsStmtsWork, ((modelica_fnptr) _func), _opt, _iextraArg, tmpMeta[0] ,&_oextraArg);
_outStmts = omc_List_flatten(threadData, _outStmtsLst);
_b = omc_List_allReferenceEq(threadData, _inStmts, _outStmts);
_outStmts = (_b?_inStmts:_outStmts);
_return: OMC_LABEL_UNUSED
if (out_oextraArg) { *out_oextraArg = _oextraArg; }
return _outStmts;
}
DLLExport
modelica_metatype omc_DAEUtil_traverseDAEEquationsStmtsRhsOnly(threadData_t *threadData, modelica_metatype _inStmts, modelica_fnptr _func, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg)
{
modelica_metatype _outStmts = NULL;
modelica_metatype _oextraArg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStmts = omc_DAEUtil_traverseDAEEquationsStmtsList(threadData, _inStmts, ((modelica_fnptr) _func), _OMC_LIT79, _iextraArg ,&_oextraArg);
_return: OMC_LABEL_UNUSED
if (out_oextraArg) { *out_oextraArg = _oextraArg; }
return _outStmts;
}
DLLExport
modelica_metatype omc_DAEUtil_traverseDAEEquationsStmts(threadData_t *threadData, modelica_metatype _inStmts, modelica_fnptr _func, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg)
{
modelica_metatype _outStmts = NULL;
modelica_metatype _oextraArg = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outStmts = omc_DAEUtil_traverseDAEEquationsStmtsList(threadData, _inStmts, ((modelica_fnptr) _func), _OMC_LIT80, _iextraArg ,&_oextraArg);
_return: OMC_LABEL_UNUSED
if (out_oextraArg) { *out_oextraArg = _oextraArg; }
return _outStmts;
}
DLLExport
modelica_metatype omc_DAEUtil_traverseAlgorithmExps(threadData_t *threadData, modelica_metatype _inAlgorithm, modelica_fnptr _func, modelica_metatype _inTypeA)
{
modelica_metatype _outTypeA = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAlgorithm;
{
modelica_metatype _stmts = NULL;
modelica_metatype _ext_arg_1 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_stmts = tmpMeta[1];
omc_DAEUtil_traverseDAEEquationsStmts(threadData, _stmts, ((modelica_fnptr) _func), _inTypeA ,&_ext_arg_1);
tmpMeta[0] = _ext_arg_1;
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
_outTypeA = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outTypeA;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _element = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = __omcQ_24in_5Felement;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp3_1;
tmp3_1 = _element;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _new_e1 = NULL;
modelica_metatype _new_e2 = NULL;
modelica_metatype _new_e3 = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _new_cr1 = NULL;
modelica_metatype _new_cr2 = NULL;
modelica_metatype _el = NULL;
modelica_metatype _new_el = NULL;
modelica_metatype _eqll = NULL;
modelica_metatype _new_eqll = NULL;
modelica_metatype _e = NULL;
modelica_metatype _new_e = NULL;
modelica_metatype _stmts = NULL;
modelica_metatype _new_stmts = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _new_expl = NULL;
modelica_metatype _binding = NULL;
modelica_metatype _new_binding = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _new_attr = NULL;
modelica_metatype _varLst = NULL;
modelica_metatype _daebinding = NULL;
modelica_metatype _new_daebinding = NULL;
modelica_boolean _changed;
modelica_metatype _new_ty = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 31; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 12));
_cr1 = tmpMeta[0];
_binding = tmpMeta[1];
_attr = tmpMeta[2];
_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), omc_Expression_crefExp(threadData, _cr1), _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, omc_Expression_crefExp(threadData, _cr1), _arg ,&_arg);
if(omc_Expression_isCref(threadData, _e1))
{
_new_cr1 = omc_Expression_expCref(threadData, _e1);
if((!referenceEq(_cr1, _new_cr1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(15));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 15*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_cr1;
_element = tmpMeta[0];
}
}
{
modelica_metatype __omcQ_24tmpVar1;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar0;
int tmp11;
modelica_metatype _d_loopVar = 0;
modelica_metatype _d;
_d_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 9)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar1 = tmpMeta[2];
tmp5 = &__omcQ_24tmpVar1;
while(1) {
tmp11 = 1;
if (!listEmpty(_d_loopVar)) {
_d = MMC_CAR(_d_loopVar);
_d_loopVar = MMC_CDR(_d_loopVar);
tmp11--;
}
if (tmp11 == 0) {
{
modelica_metatype tmp8_1;
tmp8_1 = _d;
{
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
for (; tmp8 < 2; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
modelica_boolean tmp10;
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,3,1) == 0) goto tmp7_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp8_1), 2));
_e1 = tmpMeta[4];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
tmp10 = (modelica_boolean)referenceEq(_e1, _new_e1);
if(tmp10)
{
tmpMeta[5] = _d;
}
else
{
tmpMeta[4] = mmc_mk_box2(6, &DAE_Dimension_DIM__EXP__desc, _new_e1);
tmpMeta[5] = tmpMeta[4];
}
tmpMeta[3] = tmpMeta[5];
goto tmp7_done;
}
case 1: {
tmpMeta[3] = _d;
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
}__omcQ_24tmpVar0 = tmpMeta[3];
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar0,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp11 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar1;
}
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(15));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 15*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[9] = tmpMeta[1];
_element = tmpMeta[0];
{
modelica_metatype tmp14_1;modelica_metatype _ty;
tmp14_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 7)));
_ty = tmp14_1;
{
volatile mmc_switch_type tmp14;
int tmp15;
tmp14 = 0;
for (; tmp14 < 2; tmp14++) {
switch (MMC_SWITCH_CAST(tmp14)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp14_1,9,3) == 0) goto tmp13_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp14_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) goto tmp13_end;
_changed = 0;
{
modelica_metatype __omcQ_24tmpVar3;
modelica_metatype* tmp16;
modelica_metatype __omcQ_24tmpVar2;
int tmp21;
modelica_metatype _v_loopVar = 0;
modelica_metatype _v;
_v_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 3)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar3 = tmpMeta[2];
tmp16 = &__omcQ_24tmpVar3;
while(1) {
tmp21 = 1;
if (!listEmpty(_v_loopVar)) {
_v = MMC_CAR(_v_loopVar);
_v_loopVar = MMC_CDR(_v_loopVar);
tmp21--;
}
if (tmp21 == 0) {
{
modelica_metatype tmp19_1;
tmp19_1 = _v;
{
volatile mmc_switch_type tmp19;
int tmp20;
tmp19 = 0;
for (; tmp19 < 3; tmp19++) {
switch (MMC_SWITCH_CAST(tmp19)) {
case 0: {
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp19_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,4) == 0) goto tmp18_end;
_daebinding = tmpMeta[4];
_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_daebinding), 2))), _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_daebinding), 2))), _arg ,&_arg);
if((!referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_daebinding), 2))), _e2)))
{
tmpMeta[4] = mmc_mk_box5(4, &DAE_Binding_EQBOUND__desc, _e2, mmc_mk_none(), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_daebinding), 4))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_daebinding), 5))));
_daebinding = tmpMeta[4];
tmpMeta[4] = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta[4]), MMC_UNTAGPTR(_v), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[4]))[5] = _daebinding;
_v = tmpMeta[4];
_changed = 1;
}
tmpMeta[3] = _v;
goto tmp18_done;
}
case 1: {
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp19_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],2,2) == 0) goto tmp18_end;
_daebinding = tmpMeta[4];
_e1 = omc_ValuesUtil_valueExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_daebinding), 2))), mmc_mk_none());
_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _e2)))
{
tmpMeta[4] = mmc_mk_box5(4, &DAE_Binding_EQBOUND__desc, _e2, mmc_mk_none(), _OMC_LIT81, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_daebinding), 3))));
_new_daebinding = tmpMeta[4];
tmpMeta[4] = MMC_TAGPTR(mmc_alloc_words(8));
memcpy(MMC_UNTAGPTR(tmpMeta[4]), MMC_UNTAGPTR(_v), 8*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[4]))[5] = _new_daebinding;
_v = tmpMeta[4];
_changed = 1;
}
tmpMeta[3] = _v;
goto tmp18_done;
}
case 2: {
tmpMeta[3] = _v;
goto tmp18_done;
}
}
goto tmp18_end;
tmp18_end: ;
}
goto goto_17;
goto_17:;
goto goto_12;
goto tmp18_done;
tmp18_done:;
}
}__omcQ_24tmpVar2 = tmpMeta[3];
*tmp16 = mmc_mk_cons(__omcQ_24tmpVar2,0);
tmp16 = &MMC_CDR(*tmp16);
} else if (tmp21 == 1) {
break;
} else {
goto goto_12;
}
}
*tmp16 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar3;
}
_varLst = tmpMeta[1];
if((!referenceEq(_varLst, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 3))))))
{
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_ty), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[3] = _varLst;
_ty = tmpMeta[1];
}
tmpMeta[0] = _ty;
goto tmp13_done;
}
case 1: {
tmpMeta[0] = _ty;
goto tmp13_done;
}
}
goto tmp13_end;
tmp13_end: ;
}
goto goto_12;
goto_12:;
goto goto_1;
goto tmp13_done;
tmp13_done:;
}
}
_new_ty = tmpMeta[0];
if((!referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 7))), _new_ty)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(15));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 15*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[7] = _new_ty;
_element = tmpMeta[0];
}
_new_binding = omc_DAEUtil_traverseDAEOptExp(threadData, _binding, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_binding, _new_binding)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(15));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 15*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[8] = _new_binding;
_element = tmpMeta[0];
}
_new_attr = omc_DAEUtil_traverseDAEVarAttr(threadData, _attr, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_attr, _new_attr)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(15));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 15*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[12] = _new_attr;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_cr1 = tmpMeta[0];
_e1 = tmpMeta[1];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_e1;
_element = tmpMeta[0];
}
tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), omc_Expression_crefExp(threadData, _cr1), _arg, &tmpMeta[0]) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, omc_Expression_crefExp(threadData, _cr1), _arg, &tmpMeta[0]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_new_cr1 = tmpMeta[2];
_arg = tmpMeta[0];
if((!referenceEq(_cr1, _new_cr1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_cr1;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_cr1 = tmpMeta[0];
_e1 = tmpMeta[1];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_e1;
_element = tmpMeta[0];
}
tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), omc_Expression_crefExp(threadData, _cr1), _arg, &tmpMeta[0]) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, omc_Expression_crefExp(threadData, _cr1), _arg, &tmpMeta[0]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_new_cr1 = tmpMeta[2];
_arg = tmpMeta[0];
if((!referenceEq(_cr1, _new_cr1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_cr1;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_cr1 = tmpMeta[0];
_cr2 = tmpMeta[1];
tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), omc_Expression_crefExp(threadData, _cr1), _arg, &tmpMeta[0]) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, omc_Expression_crefExp(threadData, _cr1), _arg, &tmpMeta[0]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_new_cr1 = tmpMeta[2];
_arg = tmpMeta[0];
if((!referenceEq(_cr1, _new_cr1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_cr1;
_element = tmpMeta[0];
}
tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), omc_Expression_crefExp(threadData, _cr2), _arg, &tmpMeta[0]) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, omc_Expression_crefExp(threadData, _cr2), _arg, &tmpMeta[0]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_new_cr2 = tmpMeta[2];
_arg = tmpMeta[0];
if((!referenceEq(_cr2, _new_cr2)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_cr2;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_e1 = tmpMeta[0];
_e2 = tmpMeta[1];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_e1;
_element = tmpMeta[0];
}
_new_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _arg ,&_arg);
if((!referenceEq(_e2, _new_e2)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_e2;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,14,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_e1 = tmpMeta[0];
_e2 = tmpMeta[1];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_e1;
_element = tmpMeta[0];
}
_new_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _arg ,&_arg);
if((!referenceEq(_e2, _new_e2)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_e2;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_e1 = tmpMeta[0];
_e2 = tmpMeta[1];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_e1;
_element = tmpMeta[0];
}
_new_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _arg ,&_arg);
if((!referenceEq(_e2, _new_e2)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_e2;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,9,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_e1 = tmpMeta[0];
_e2 = tmpMeta[1];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_e1;
_element = tmpMeta[0];
}
_new_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _arg ,&_arg);
if((!referenceEq(_e2, _new_e2)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_e2;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,4) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[0];
_e2 = tmpMeta[1];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_e1;
_element = tmpMeta[0];
}
_new_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _arg ,&_arg);
if((!referenceEq(_e2, _new_e2)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = _new_e2;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,4) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[0];
_e2 = tmpMeta[1];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_e1;
_element = tmpMeta[0];
}
_new_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _arg ,&_arg);
if((!referenceEq(_e2, _new_e2)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = _new_e2;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_e1 = tmpMeta[0];
_el = tmpMeta[1];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_e1;
_element = tmpMeta[0];
}
_new_el = omc_DAEUtil_traverseDAEElementList(threadData, _el, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_el, _new_el)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_el;
_element = tmpMeta[0];
}
if(isSome((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)))))
{
tmpMeta[0] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)));
if (optionNone(tmpMeta[0])) goto goto_1;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
_e = tmpMeta[1];
_new_e = omc_DAEUtil_traverseDAEElement(threadData, _e, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_e, _new_e)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = mmc_mk_some(_new_e);
_element = tmpMeta[0];
}
}
goto tmp2_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,11,7) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_e1 = tmpMeta[0];
_el = tmpMeta[1];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[6] = _new_e1;
_element = tmpMeta[0];
}
_new_el = omc_DAEUtil_traverseDAEElementList(threadData, _el, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_el, _new_el)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[7] = _new_el;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,4) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_el = tmpMeta[0];
_new_el = omc_DAEUtil_traverseDAEElementList(threadData, _el, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_el, _new_el)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_el;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,18,2) == 0) goto tmp2_end;
goto tmp2_done;
}
case 14: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,19,4) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[0];
_e2 = tmpMeta[1];
_e3 = tmpMeta[2];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_e1;
_element = tmpMeta[0];
}
_new_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _arg ,&_arg);
if((!referenceEq(_e2, _new_e2)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_e2;
_element = tmpMeta[0];
}
_new_e3 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e3, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e3, _arg ,&_arg);
if((!referenceEq(_e3, _new_e3)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = _new_e3;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 15: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,20,4) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[0];
_e2 = tmpMeta[1];
_e3 = tmpMeta[2];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_e1;
_element = tmpMeta[0];
}
_new_e2 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e2, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e2, _arg ,&_arg);
if((!referenceEq(_e2, _new_e2)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_e2;
_element = tmpMeta[0];
}
_new_e3 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e3, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e3, _arg ,&_arg);
if((!referenceEq(_e3, _new_e3)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = _new_e3;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 16: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,21,2) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_e1 = tmpMeta[0];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_e1;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 17: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,22,2) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_e1 = tmpMeta[0];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_e1;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 18: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,24,2) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_e1 = tmpMeta[0];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_e1;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 19: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,25,2) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_e1 = tmpMeta[0];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_e1;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,23,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_cr1 = tmpMeta[0];
_e1 = tmpMeta[1];
_new_e1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e1, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e1, _arg ,&_arg);
if((!referenceEq(_e1, _new_e1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_e1;
_element = tmpMeta[0];
}
tmpMeta[1] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), omc_Expression_crefExp(threadData, _cr1), _arg, &tmpMeta[0]) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, omc_Expression_crefExp(threadData, _cr1), _arg, &tmpMeta[0]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_new_cr1 = tmpMeta[2];
_arg = tmpMeta[0];
if((!referenceEq(_cr1, _new_cr1)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_cr1;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 21: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,15,2) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_stmts = tmpMeta[1];
_new_stmts = omc_DAEUtil_traverseDAEEquationsStmts(threadData, _stmts, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_stmts, _new_stmts)))
{
tmpMeta[1] = mmc_mk_box2(3, &DAE_Algorithm_ALGORITHM__STMTS__desc, _new_stmts);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = tmpMeta[1];
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 22: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,2) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_stmts = tmpMeta[1];
_new_stmts = omc_DAEUtil_traverseDAEEquationsStmts(threadData, _stmts, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_stmts, _new_stmts)))
{
tmpMeta[1] = mmc_mk_box2(3, &DAE_Algorithm_ALGORITHM__STMTS__desc, _new_stmts);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = tmpMeta[1];
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 23: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,26,2) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_expl = tmpMeta[1];
_new_expl = omc_DAEUtil_traverseDAEExpList(threadData, _expl, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_expl, _new_expl)))
{
tmpMeta[1] = mmc_mk_box2(3, &DAE_Constraint_CONSTRAINT__EXPS__desc, _new_expl);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = tmpMeta[1];
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 24: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,27,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 25: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,12,4) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_expl = tmpMeta[0];
_eqll = tmpMeta[1];
_el = tmpMeta[2];
_new_expl = omc_DAEUtil_traverseDAEExpList(threadData, _expl, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_expl, _new_expl)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_expl;
_element = tmpMeta[0];
}
_new_eqll = omc_DAEUtil_traverseDAEList(threadData, _eqll, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_eqll, _new_eqll)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_eqll;
_element = tmpMeta[0];
}
_new_el = omc_DAEUtil_traverseDAEElementList(threadData, _el, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_el, _new_el)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = _new_el;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 26: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,4) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_expl = tmpMeta[0];
_eqll = tmpMeta[1];
_el = tmpMeta[2];
_new_expl = omc_DAEUtil_traverseDAEExpList(threadData, _expl, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_expl, _new_expl)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _new_expl;
_element = tmpMeta[0];
}
_new_eqll = omc_DAEUtil_traverseDAEList(threadData, _eqll, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_eqll, _new_eqll)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_eqll;
_element = tmpMeta[0];
}
_new_el = omc_DAEUtil_traverseDAEElementList(threadData, _el, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_el, _new_el)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = _new_el;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 27: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,28,2) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_el = tmpMeta[0];
_new_el = omc_DAEUtil_traverseDAEElementList(threadData, _el, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_el, _new_el)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_el;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 28: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,29,2) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_el = tmpMeta[0];
_new_el = omc_DAEUtil_traverseDAEElementList(threadData, _el, ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq(_el, _new_el)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = _new_el;
_element = tmpMeta[0];
}
goto tmp2_done;
}
case 29: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,30,1) == 0) goto tmp2_end;
goto tmp2_done;
}
case 30: {
tmpMeta[1] = mmc_mk_cons(_element, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = stringAppend(_OMC_LIT82,omc_DAEDump_dumpElementsStr(threadData, tmpMeta[1]));
tmpMeta[0] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT77, tmpMeta[0]);
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
if (out_arg) { *out_arg = _arg; }
return _element;
}
static modelica_metatype closure0_DAEUtil_traverseDAEElement(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_element, modelica_metatype $in_arg, modelica_metatype tmp1)
{
modelica_fnptr func = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_DAEUtil_traverseDAEElement(thData, $in_element, func, $in_arg, tmp1);
}
DLLExport
modelica_metatype omc_DAEUtil_traverseDAEElementList(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felements, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _elements = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elements = __omcQ_24in_5Felements;
_arg = __omcQ_24in_5Farg;
tmpMeta[0] = mmc_mk_box1(0, ((modelica_fnptr) _func));
_elements = omc_List_mapFold(threadData, _elements, (modelica_fnptr) mmc_mk_box2(0,closure0_DAEUtil_traverseDAEElement,tmpMeta[0]), _arg ,&_arg);
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _elements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEFunc(threadData_t *threadData, modelica_metatype __omcQ_24in_5FdaeFunction, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _daeFunction = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_daeFunction = __omcQ_24in_5FdaeFunction;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp3_1;
tmp3_1 = _daeFunction;
{
modelica_metatype _fdef = NULL;
modelica_metatype _rest_defs = NULL;
modelica_metatype _el = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,10) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[0])) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,1) == 0) goto tmp2_end;
_fdef = tmpMeta[1];
_rest_defs = tmpMeta[2];
_el = omc_DAEUtil_traverseDAEElementList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fdef), 2))), ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fdef), 2))), _el)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_fdef), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _el;
_fdef = tmpMeta[0];
tmpMeta[1] = mmc_mk_cons(_fdef, _rest_defs);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_daeFunction), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = tmpMeta[1];
_daeFunction = tmpMeta[0];
}
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,10) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[0])) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,2) == 0) goto tmp2_end;
_fdef = tmpMeta[1];
_rest_defs = tmpMeta[2];
_el = omc_DAEUtil_traverseDAEElementList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fdef), 2))), ((modelica_fnptr) _func), _arg ,&_arg);
if((!referenceEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_fdef), 2))), _el)))
{
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(4));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_fdef), 4*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _el;
_fdef = tmpMeta[0];
tmpMeta[1] = mmc_mk_cons(_fdef, _rest_defs);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(12));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_daeFunction), 12*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = tmpMeta[1];
_daeFunction = tmpMeta[0];
}
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
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
if (out_arg) { *out_arg = _arg; }
return _daeFunction;
}
static modelica_metatype closure1_DAEUtil_traverseDAEFunc(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_daeFunction, modelica_metatype $in_arg, modelica_metatype tmp1)
{
modelica_fnptr func = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_DAEUtil_traverseDAEFunc(thData, $in_daeFunction, func, $in_arg, tmp1);
}
DLLExport
modelica_metatype omc_DAEUtil_traverseDAEFunctions(threadData_t *threadData, modelica_metatype __omcQ_24in_5Ffunctions, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _functions = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_functions = __omcQ_24in_5Ffunctions;
_arg = __omcQ_24in_5Farg;
tmpMeta[0] = mmc_mk_box1(0, ((modelica_fnptr) _func));
_functions = omc_List_mapFold(threadData, _functions, (modelica_fnptr) mmc_mk_box2(0,closure1_DAEUtil_traverseDAEFunc,tmpMeta[0]), _arg ,&_arg);
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _functions;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEFuncHelper(threadData_t *threadData, modelica_metatype _key, modelica_metatype __omcQ_24in_5Fvalue, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _value = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_value = __omcQ_24in_5Fvalue;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp4_1;
tmp4_1 = _value;
{
modelica_metatype _daeFunc1 = NULL;
modelica_metatype _daeFunc2 = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_daeFunc1 = tmpMeta[2];
_daeFunc2 = omc_DAEUtil_traverseDAEFunc(threadData, _daeFunc1, ((modelica_fnptr) _func), _arg ,&_arg);
tmpMeta[0+0] = (referenceEq(_daeFunc1, _daeFunc2)?_value:mmc_mk_some(_daeFunc2));
tmpMeta[0+1] = _arg;
goto tmp3_done;
}
case 1: {
modelica_boolean tmp6;
if (!optionNone(tmp4_1)) goto tmp3_end;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT86);
if (1 != tmp6) goto goto_2;
tmpMeta[2] = stringAppend(_OMC_LIT87,omc_AbsynUtil_pathString(threadData, _key, _OMC_LIT29, 1, 0));
omc_Debug_traceln(threadData, tmpMeta[2]);
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
_value = tmpMeta[0+0];
_arg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _value;
}
static modelica_metatype closure2_DAEUtil_traverseDAEFuncHelper(threadData_t *thData, modelica_metatype closure, modelica_metatype key, modelica_metatype $in_value, modelica_metatype $in_arg, modelica_metatype tmp1)
{
modelica_fnptr func = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_DAEUtil_traverseDAEFuncHelper(thData, key, $in_value, func, $in_arg, tmp1);
}
DLLExport
modelica_metatype omc_DAEUtil_traverseDAE(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fdae, modelica_metatype __omcQ_24in_5FfunctionTree, modelica_fnptr _func, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_functionTree, modelica_metatype *out_arg)
{
modelica_metatype _dae = NULL;
modelica_metatype _functionTree = NULL;
modelica_metatype _arg = NULL;
modelica_metatype _el = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_dae = __omcQ_24in_5Fdae;
_functionTree = __omcQ_24in_5FfunctionTree;
_arg = __omcQ_24in_5Farg;
_el = omc_DAEUtil_traverseDAEElementList(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_dae), 2))), ((modelica_fnptr) _func), _arg ,&_arg);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(3));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_dae), 3*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _el;
_dae = tmpMeta[0];
tmpMeta[0] = mmc_mk_box1(0, ((modelica_fnptr) _func));
_functionTree = omc_DAE_AvlTreePathFunction_mapFold(threadData, _functionTree, (modelica_fnptr) mmc_mk_box2(0,closure2_DAEUtil_traverseDAEFuncHelper,tmpMeta[0]), _arg ,&_arg);
_return: OMC_LABEL_UNUSED
if (out_functionTree) { *out_functionTree = _functionTree; }
if (out_arg) { *out_arg = _arg; }
return _dae;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_DAEUtil_isValidFunctionEntry(threadData_t *threadData, modelica_metatype _tpl)
{
modelica_boolean _b;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_b = (!omc_DAEUtil_isInvalidFunctionEntry(threadData, _tpl));
_return: OMC_LABEL_UNUSED
return _b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_isValidFunctionEntry(threadData_t *threadData, modelica_metatype _tpl)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_isValidFunctionEntry(threadData, _tpl);
out_b = mmc_mk_icon(_b);
return out_b;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_DAEUtil_isInvalidFunctionEntry(threadData_t *threadData, modelica_metatype _tpl)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _tpl;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!optionNone(tmpMeta[0])) goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_isInvalidFunctionEntry(threadData_t *threadData, modelica_metatype _tpl)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_isInvalidFunctionEntry(threadData, _tpl);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_DAEUtil_getFunctionNames(threadData_t *threadData, modelica_metatype _ft)
{
modelica_metatype _strs = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_strs = omc_List_mapMap(threadData, omc_DAEUtil_getFunctionList(threadData, _ft, 0), boxvar_DAEUtil_functionName, boxvar_AbsynUtil_pathStringDefault);
_return: OMC_LABEL_UNUSED
return _strs;
}
DLLExport
modelica_metatype omc_DAEUtil_getFunctionList(threadData_t *threadData, modelica_metatype _ft, modelica_boolean _failOnError)
{
modelica_metatype _fns = NULL;
modelica_metatype _lst = NULL;
modelica_metatype _lstInvalid = NULL;
modelica_string _str = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_fns = omc_List_map(threadData, omc_DAE_AvlTreePathFunction_listValues(threadData, _ft, tmpMeta[0]), boxvar_Util_getOption);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_lst = omc_DAE_AvlTreePathFunction_toList(threadData, _ft, tmpMeta[0]);
_lstInvalid = omc_List_select(threadData, _lst, boxvar_DAEUtil_isInvalidFunctionEntry);
{
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype* tmp5;
modelica_string __omcQ_24tmpVar4;
int tmp6;
modelica_metatype _p_loopVar = 0;
modelica_metatype _p;
_p_loopVar = omc_List_map(threadData, _lstInvalid, boxvar_Util_tuple21);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar5 = tmpMeta[1];
tmp5 = &__omcQ_24tmpVar5;
while(1) {
tmp6 = 1;
if (!listEmpty(_p_loopVar)) {
_p = MMC_CAR(_p_loopVar);
_p_loopVar = MMC_CDR(_p_loopVar);
tmp6--;
}
if (tmp6 == 0) {
__omcQ_24tmpVar4 = omc_AbsynUtil_pathString(threadData, _p, _OMC_LIT29, 1, 0);
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar4,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar5;
}
_str = stringDelimitList(tmpMeta[0], _OMC_LIT88);
tmpMeta[0] = stringAppend(_OMC_LIT88,_str);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT28);
_str = tmpMeta[1];
tmpMeta[0] = mmc_mk_cons(_str, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT91, tmpMeta[0]);
if(_failOnError)
{
goto goto_1;
}
_fns = omc_List_mapMap(threadData, omc_List_select(threadData, _lst, boxvar_DAEUtil_isValidFunctionEntry), boxvar_Util_tuple22, boxvar_Util_getOption);
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
return _fns;
}
modelica_metatype boxptr_DAEUtil_getFunctionList(threadData_t *threadData, modelica_metatype _ft, modelica_metatype _failOnError)
{
modelica_integer tmp1;
modelica_metatype _fns = NULL;
tmp1 = mmc_unbox_integer(_failOnError);
_fns = omc_DAEUtil_getFunctionList(threadData, _ft, tmp1);
return _fns;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEList(threadData_t *threadData, modelica_metatype _idaeList, modelica_fnptr _func, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg)
{
modelica_metatype _traversedDaeList = NULL;
modelica_metatype _oextraArg = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _idaeList;
tmp4_2 = _iextraArg;
{
modelica_metatype _branch = NULL;
modelica_metatype _branch2 = NULL;
modelica_metatype _recRes = NULL;
modelica_metatype _daeList = NULL;
modelica_metatype _extraArg = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_extraArg = tmp4_2;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
_branch = tmpMeta[2];
_daeList = tmpMeta[3];
_extraArg = tmp4_2;
_branch2 = omc_DAEUtil_traverseDAEElementList(threadData, _branch, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
_recRes = omc_DAEUtil_traverseDAEList(threadData, _daeList, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmpMeta[2] = mmc_mk_cons(_branch2, _recRes);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_traversedDaeList = tmpMeta[0+0];
_oextraArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_oextraArg) { *out_oextraArg = _oextraArg; }
return _traversedDaeList;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEExpList(threadData_t *threadData, modelica_metatype _iexps, modelica_fnptr _func, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg)
{
modelica_metatype _oexps = NULL;
modelica_metatype _oextraArg = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _iexps;
tmp4_2 = _iextraArg;
{
modelica_metatype _e = NULL;
modelica_metatype _extraArg = NULL;
modelica_metatype _exps = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
_extraArg = tmp4_2;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
_e = tmpMeta[2];
_exps = tmpMeta[3];
_extraArg = tmp4_2;
_e = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
_oexps = omc_DAEUtil_traverseDAEExpList(threadData, _exps, ((modelica_fnptr) _func), _extraArg ,&_extraArg);
tmpMeta[2] = mmc_mk_cons(_e, _oexps);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_oexps = tmpMeta[0+0];
_oextraArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_oextraArg) { *out_oextraArg = _oextraArg; }
return _oexps;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_traverseDAEOptExp(threadData_t *threadData, modelica_metatype _oexp, modelica_fnptr _func, modelica_metatype _iextraArg, modelica_metatype *out_oextraArg)
{
modelica_metatype _ooexp = NULL;
modelica_metatype _oextraArg = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _oexp;
tmp4_2 = _iextraArg;
{
modelica_metatype _e = NULL;
modelica_metatype _extraArg = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
_extraArg = tmp4_2;
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
case 1: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_e = tmpMeta[2];
_extraArg = tmp4_2;
_e = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, _extraArg ,&_extraArg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, _extraArg ,&_extraArg);
tmpMeta[0+0] = mmc_mk_some(_e);
tmpMeta[0+1] = _extraArg;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_ooexp = tmpMeta[0+0];
_oextraArg = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_oextraArg) { *out_oextraArg = _oextraArg; }
return _ooexp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_addUniqueIdentifierToCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _oarg, modelica_metatype *out_outDummy)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outDummy = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _cr = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _exp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cr = tmpMeta[2];
_ty = tmpMeta[3];
_cr2 = omc_DAEUtil_nameInnerouterUniqueCref(threadData, _cr);
_exp = omc_Expression_makeCrefExp(threadData, _cr2, _ty);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _oarg;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _oarg;
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
_outExp = tmpMeta[0+0];
_outDummy = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outDummy) { *out_outDummy = _outDummy; }
return _outExp;
}
DLLExport
modelica_metatype omc_DAEUtil_nameUniqueOuterVars(threadData_t *threadData, modelica_metatype _dae)
{
modelica_metatype _odae = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = mmc_mk_box2(0, boxvar_DAEUtil_addUniqueIdentifierToCref, tmpMeta[0]);
_odae = omc_DAEUtil_traverseDAE(threadData, _dae, _OMC_LIT92, boxvar_Expression_traverseSubexpressionsHelper, tmpMeta[1], NULL, NULL);
_return: OMC_LABEL_UNUSED
return _odae;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_removeUniqieIdentifierFromCref(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _oarg, modelica_metatype *out_outDummy)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outDummy = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _cr = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _exp = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
_cr = tmpMeta[2];
_ty = tmpMeta[3];
_cr2 = omc_DAEUtil_unNameInnerouterUniqueCref(threadData, _cr, _OMC_LIT93);
_exp = omc_Expression_makeCrefExp(threadData, _cr2, _ty);
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = _oarg;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _oarg;
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
_outExp = tmpMeta[0+0];
_outDummy = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outDummy) { *out_outDummy = _outDummy; }
return _outExp;
}
DLLExport
modelica_metatype omc_DAEUtil_renameUniqueOuterVars(threadData_t *threadData, modelica_metatype _dae)
{
modelica_metatype _odae = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = mmc_mk_box2(0, boxvar_DAEUtil_removeUniqieIdentifierFromCref, tmpMeta[0]);
_odae = omc_DAEUtil_traverseDAE(threadData, _dae, _OMC_LIT92, boxvar_Expression_traverseSubexpressionsHelper, tmpMeta[1], NULL, NULL);
_return: OMC_LABEL_UNUSED
return _odae;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotation4(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inCr, modelica_metatype _inExp, modelica_integer _inInteger1, modelica_integer _inInteger2, modelica_metatype _inHt, modelica_metatype *out_outHt, modelica_metatype *out_outCache)
{
modelica_metatype _outExp = NULL;
modelica_metatype _outHt = NULL;
modelica_metatype _outCache = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_integer tmp4_3;volatile modelica_integer tmp4_4;volatile modelica_metatype tmp4_5;
tmp4_1 = _inCr;
tmp4_2 = _inExp;
tmp4_3 = _inInteger1;
tmp4_4 = _inInteger2;
tmp4_5 = _inHt;
{
modelica_metatype _cr = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_integer _i;
modelica_integer _j;
modelica_metatype _ht = NULL;
modelica_metatype _ht1 = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _value = NULL;
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
_cr = tmp4_1;
_e = tmp4_2;
_i = tmp4_3;
_j = tmp4_4;
_ht = tmp4_5;
tmp6 = (_j > ((modelica_integer) 0));
if (1 != tmp6) goto goto_2;
tmp7 = (_i == ((modelica_integer) 0));
if (1 != tmp7) goto goto_2;
tmpMeta[5] = mmc_mk_box3(0, _ht, mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)));
tmpMeta[6] = omc_Expression_traverseExpBottomUp(threadData, _e, boxvar_DAEUtil_evaluateAnnotationTraverse, tmpMeta[5], &tmpMeta[3]);
_e1 = tmpMeta[6];
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
_ht = tmpMeta[4];
_cache = omc_Ceval_ceval(threadData, _inCache, _env, _e1, 0, _OMC_LIT94, ((modelica_integer) 0) ,&_value);
_e1 = omc_ValuesUtil_valueExp(threadData, _value, mmc_mk_none());
tmpMeta[3] = mmc_mk_box2(0, _cr, _e1);
_ht1 = omc_BaseHashTable_add(threadData, tmpMeta[3], _ht);
tmpMeta[0+0] = _e1;
tmpMeta[0+1] = _ht1;
tmpMeta[0+2] = _cache;
goto tmp3_done;
}
case 1: {
_e = tmp4_2;
_ht = tmp4_5;
tmpMeta[0+0] = _e;
tmpMeta[0+1] = _ht;
tmpMeta[0+2] = _inCache;
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
_outExp = tmpMeta[0+0];
_outHt = tmpMeta[0+1];
_outCache = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outHt) { *out_outHt = _outHt; }
if (out_outCache) { *out_outCache = _outCache; }
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_evaluateAnnotation4(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inCr, modelica_metatype _inExp, modelica_metatype _inInteger1, modelica_metatype _inInteger2, modelica_metatype _inHt, modelica_metatype *out_outHt, modelica_metatype *out_outCache)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outExp = NULL;
tmp1 = mmc_unbox_integer(_inInteger1);
tmp2 = mmc_unbox_integer(_inInteger2);
_outExp = omc_DAEUtil_evaluateAnnotation4(threadData, _inCache, _env, _inCr, _inExp, tmp1, tmp2, _inHt, out_outHt, out_outCache);
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotation3(threadData_t *threadData, modelica_metatype _iel, modelica_metatype _inHt, modelica_metatype *out_outHt)
{
modelica_metatype _oel = NULL;
modelica_metatype _outHt = NULL;
modelica_metatype tmpMeta[19] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _iel;
tmp4_2 = _inHt;
{
modelica_metatype _httpl = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _sublist = NULL;
modelica_metatype _sublist1 = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _ht1 = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_string _ident = NULL;
modelica_metatype _source = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _direction = NULL;
modelica_metatype _parallelism = NULL;
modelica_metatype _protection = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _variableAttributesOption = NULL;
modelica_metatype _absynCommentOption = NULL;
modelica_metatype _innerOuter = NULL;
modelica_integer _i;
modelica_integer _j;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,17,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
_ident = tmpMeta[2];
_sublist = tmpMeta[3];
_source = tmpMeta[4];
_comment = tmpMeta[5];
tmp4 += 1;
_sublist1 = omc_List_mapFold(threadData, _sublist, boxvar_DAEUtil_evaluateAnnotation3, _inHt ,&_httpl);
tmpMeta[2] = mmc_mk_box5(20, &DAE_Element_COMP__desc, _ident, _sublist1, _source, _comment);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = _httpl;
goto tmp3_done;
}
case 1: {
modelica_integer tmp6;
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],2,0) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
if (optionNone(tmpMeta[8])) goto tmp3_end;
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[8]), 1));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 9));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 10));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 11));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 12));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 13));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 14));
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[17] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmpMeta[18] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
_cr = tmpMeta[2];
_direction = tmpMeta[4];
_parallelism = tmpMeta[5];
_protection = tmpMeta[6];
_ty = tmpMeta[7];
_e = tmpMeta[9];
_dims = tmpMeta[10];
_ct = tmpMeta[11];
_source = tmpMeta[12];
_variableAttributesOption = tmpMeta[13];
_absynCommentOption = tmpMeta[14];
_innerOuter = tmpMeta[15];
_ht = tmpMeta[16];
_cache = tmpMeta[17];
_env = tmpMeta[18];
tmpMeta[5] = mmc_mk_box3(0, _ht, mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)));
tmpMeta[6] = omc_Expression_traverseExpBottomUp(threadData, _e, boxvar_DAEUtil_evaluateAnnotationTraverse, tmpMeta[5], &tmpMeta[2]);
_e1 = tmpMeta[6];
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp6 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp7 = mmc_unbox_integer(tmpMeta[4]);
_i = tmp6;
_j = tmp7;
_e2 = omc_DAEUtil_evaluateAnnotation4(threadData, _cache, _env, _cr, _e1, _i, _j, _ht ,&_ht1 ,&_cache);
tmpMeta[2] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _cr, _OMC_LIT95, _direction, _parallelism, _protection, _ty, mmc_mk_some(_e2), _dims, _ct, _source, _variableAttributesOption, _absynCommentOption, _innerOuter);
tmpMeta[3] = mmc_mk_box3(0, _ht1, _cache, _env);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = tmpMeta[3];
goto tmp3_done;
}
case 2: {
tmpMeta[0+0] = _iel;
tmpMeta[0+1] = _inHt;
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
_oel = tmpMeta[0+0];
_outHt = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outHt) { *out_outHt = _outHt; }
return _oel;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotation2(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inDAElist, modelica_metatype _inHt, modelica_metatype *out_outHt, modelica_metatype *out_outCache)
{
modelica_metatype _outDAElist = NULL;
modelica_metatype _outHt = NULL;
modelica_metatype _outCache = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inDAElist;
tmp4_2 = _inHt;
{
modelica_metatype _elementLst = NULL;
modelica_metatype _elementLst1 = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _ht1 = NULL;
modelica_metatype _cache = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!listEmpty(tmpMeta[3])) goto tmp3_end;
_ht = tmp4_2;
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta[3];
tmpMeta[0+1] = _ht;
tmpMeta[0+2] = _inCache;
goto tmp3_done;
}
case 1: {
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_elementLst = tmpMeta[3];
_ht = tmp4_2;
tmpMeta[6] = mmc_mk_box3(0, _ht, _inCache, _env);
tmpMeta[7] = omc_List_mapFold(threadData, _elementLst, boxvar_DAEUtil_evaluateAnnotation3, tmpMeta[6], &tmpMeta[3]);
_elementLst1 = tmpMeta[7];
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
_ht1 = tmpMeta[4];
_cache = tmpMeta[5];
tmpMeta[0+0] = _elementLst1;
tmpMeta[0+1] = _ht1;
tmpMeta[0+2] = _cache;
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
_outDAElist = tmpMeta[0+0];
_outHt = tmpMeta[0+1];
_outCache = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outHt) { *out_outHt = _outHt; }
if (out_outCache) { *out_outCache = _outCache; }
return _outDAElist;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotation2__loop1(threadData_t *threadData, modelica_boolean _finish, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inDAElist, modelica_metatype _inHt, modelica_integer _sizeBefore, modelica_metatype *out_outHt, modelica_metatype *out_outCache)
{
modelica_metatype _outDAElist = NULL;
modelica_metatype _outHt = NULL;
modelica_metatype _outCache = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_boolean tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _finish;
tmp4_2 = _inDAElist;
{
modelica_metatype _elst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (1 != tmp4_1) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
_elst = tmpMeta[3];
tmpMeta[0+0] = _elst;
tmpMeta[0+1] = _inHt;
tmpMeta[0+2] = _inCache;
goto tmp3_done;
}
case 1: {
tmpMeta[0+0] = omc_DAEUtil_evaluateAnnotation2__loop(threadData, _inCache, _env, _inDAElist, _inHt, _sizeBefore, &tmpMeta[0+1], &tmpMeta[0+2]);
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outDAElist = tmpMeta[0+0];
_outHt = tmpMeta[0+1];
_outCache = tmpMeta[0+2];
_return: OMC_LABEL_UNUSED
if (out_outHt) { *out_outHt = _outHt; }
if (out_outCache) { *out_outCache = _outCache; }
return _outDAElist;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_evaluateAnnotation2__loop1(threadData_t *threadData, modelica_metatype _finish, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inDAElist, modelica_metatype _inHt, modelica_metatype _sizeBefore, modelica_metatype *out_outHt, modelica_metatype *out_outCache)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _outDAElist = NULL;
tmp1 = mmc_unbox_integer(_finish);
tmp2 = mmc_unbox_integer(_sizeBefore);
_outDAElist = omc_DAEUtil_evaluateAnnotation2__loop1(threadData, tmp1, _inCache, _env, _inDAElist, _inHt, tmp2, out_outHt, out_outCache);
return _outDAElist;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotation2__loop(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inDAElist, modelica_metatype _inHt, modelica_integer _sizeBefore, modelica_metatype *out_outHt, modelica_metatype *out_outCache)
{
modelica_metatype _outDAElist = NULL;
modelica_metatype _outHt = NULL;
modelica_metatype _outCache = NULL;
modelica_integer _newsize;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outDAElist = omc_DAEUtil_evaluateAnnotation2(threadData, _cache, _env, _inDAElist, _inHt ,&_outHt ,&_outCache);
_newsize = omc_BaseHashTable_hashTableCurrentSize(threadData, _outHt);
tmpMeta[0] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _outDAElist);
_outDAElist = omc_DAEUtil_evaluateAnnotation2__loop1(threadData, (_newsize == _sizeBefore), _outCache, _env, tmpMeta[0], _outHt, _newsize ,&_outHt ,&_outCache);
_return: OMC_LABEL_UNUSED
if (out_outHt) { *out_outHt = _outHt; }
if (out_outCache) { *out_outCache = _outCache; }
return _outDAElist;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_evaluateAnnotation2__loop(threadData_t *threadData, modelica_metatype _cache, modelica_metatype _env, modelica_metatype _inDAElist, modelica_metatype _inHt, modelica_metatype _sizeBefore, modelica_metatype *out_outHt, modelica_metatype *out_outCache)
{
modelica_integer tmp1;
modelica_metatype _outDAElist = NULL;
tmp1 = mmc_unbox_integer(_sizeBefore);
_outDAElist = omc_DAEUtil_evaluateAnnotation2__loop(threadData, _cache, _env, _inDAElist, _inHt, tmp1, out_outHt, out_outCache);
return _outDAElist;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateParameter(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inPV)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inExp;
tmp3_2 = _inPV;
{
modelica_metatype _pv = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
modelica_integer _i;
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
_e = tmp3_1;
tmp5 = omc_Expression_isConst(threadData, _e);
if (1 != tmp5) goto goto_1;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp6;
_e = tmp3_1;
tmp6 = omc_Expression_expHasCrefs(threadData, _e);
if (0 != tmp6) goto goto_1;
tmpMeta[0] = _e;
goto tmp2_done;
}
case 2: {
modelica_integer tmp7;
modelica_boolean tmp8;
_e = tmp3_1;
_pv = tmp3_2;
tmpMeta[3] = mmc_mk_box3(0, _pv, mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)));
tmpMeta[4] = omc_Expression_traverseExpBottomUp(threadData, _e, boxvar_DAEUtil_evaluateAnnotationTraverse, tmpMeta[3], &tmpMeta[1]);
_e1 = tmpMeta[4];
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp7 = mmc_unbox_integer(tmpMeta[2]);
_i = tmp7;
tmp8 = (_i == ((modelica_integer) 0));
if (1 != tmp8) goto goto_1;
tmpMeta[0] = omc_DAEUtil_evaluateParameter(threadData, _e1, _pv);
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
_outExp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotation1Fold(threadData_t *threadData, modelica_metatype _tpl, modelica_metatype _el, modelica_metatype _inPV)
{
modelica_metatype _otpl = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;volatile modelica_metatype tmp3_3;
tmp3_1 = _tpl;
tmp3_2 = _el;
tmp3_3 = _inPV;
{
modelica_metatype _sublist = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _ht1 = NULL;
modelica_metatype _pv = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _anno = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e1 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,17,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
_sublist = tmpMeta[1];
_pv = tmp3_3;
tmp3 += 1;
tmpMeta[0] = omc_List_fold1r(threadData, _sublist, boxvar_DAEUtil_evaluateAnnotation1Fold, _pv, _tpl);
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,0) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 8));
if (optionNone(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 13));
if (optionNone(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_cr = tmpMeta[1];
_e = tmpMeta[4];
_comment = tmpMeta[6];
_ht = tmpMeta[7];
_pv = tmp3_3;
tmpMeta[1] = _comment;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (optionNone(tmpMeta[2])) goto goto_1;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_anno = tmpMeta[3];
tmp5 = omc_SCodeUtil_hasBooleanNamedAnnotation(threadData, _anno, _OMC_LIT96);
if (1 != tmp5) goto goto_1;
_e1 = omc_DAEUtil_evaluateParameter(threadData, _e, _pv);
tmpMeta[1] = mmc_mk_box2(0, _cr, _e1);
_ht1 = omc_BaseHashTable_add(threadData, tmpMeta[1], _ht);
tmpMeta[1] = mmc_mk_box2(0, _ht1, mmc_mk_boolean(1));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
tmpMeta[0] = _tpl;
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
_otpl = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _otpl;
}
DLLExport
modelica_metatype omc_DAEUtil_evaluateAnnotation1(threadData_t *threadData, modelica_metatype _dae, modelica_metatype _pv, modelica_metatype _ht, modelica_boolean *out_hasEvaluate)
{
modelica_metatype _oht = NULL;
modelica_boolean _hasEvaluate;
modelica_metatype _elts = NULL;
modelica_integer tmp1;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _dae;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_elts = tmpMeta[1];
tmpMeta[0] = mmc_mk_box2(0, _ht, mmc_mk_boolean(0));
tmpMeta[1] = omc_List_fold1r(threadData, _elts, boxvar_DAEUtil_evaluateAnnotation1Fold, _pv, tmpMeta[0]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[3]);
_oht = tmpMeta[2];
_hasEvaluate = tmp1;
_return: OMC_LABEL_UNUSED
if (out_hasEvaluate) { *out_hasEvaluate = _hasEvaluate; }
return _oht;
}
modelica_metatype boxptr_DAEUtil_evaluateAnnotation1(threadData_t *threadData, modelica_metatype _dae, modelica_metatype _pv, modelica_metatype _ht, modelica_metatype *out_hasEvaluate)
{
modelica_boolean _hasEvaluate;
modelica_metatype _oht = NULL;
_oht = omc_DAEUtil_evaluateAnnotation1(threadData, _dae, _pv, _ht, &_hasEvaluate);
if (out_hasEvaluate) { *out_hasEvaluate = mmc_mk_icon(_hasEvaluate); }
return _oht;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getParameterVars2(threadData_t *threadData, modelica_metatype _elt, modelica_metatype _ht)
{
modelica_metatype _ouHt = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _elt;
{
modelica_metatype _cr = NULL;
modelica_metatype _e = NULL;
modelica_metatype _dae_var_attr = NULL;
modelica_metatype _elts = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_elts = tmpMeta[1];
tmp3 += 2;
tmpMeta[0] = omc_List_fold(threadData, _elts, boxvar_DAEUtil_getParameterVars2, _ht);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,0) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
if (optionNone(tmpMeta[3])) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 1));
_cr = tmpMeta[1];
_e = tmpMeta[4];
tmpMeta[1] = mmc_mk_box2(0, _cr, _e);
tmpMeta[0] = omc_BaseHashTable_add(threadData, tmpMeta[1], _ht);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,0) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 12));
_cr = tmpMeta[1];
_dae_var_attr = tmpMeta[3];
_e = omc_DAEUtil_getStartAttrFail(threadData, _dae_var_attr);
tmpMeta[1] = mmc_mk_box2(0, _cr, _e);
tmpMeta[0] = omc_BaseHashTable_add(threadData, tmpMeta[1], _ht);
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _ht;
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
_ouHt = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _ouHt;
}
DLLExport
modelica_metatype omc_DAEUtil_getParameterVars(threadData_t *threadData, modelica_metatype _dae, modelica_metatype _ht)
{
modelica_metatype _oht = NULL;
modelica_metatype _elts = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _dae;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_elts = tmpMeta[1];
_oht = omc_List_fold(threadData, _elts, boxvar_DAEUtil_getParameterVars2, _ht);
_return: OMC_LABEL_UNUSED
return _oht;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_replaceCrefInAnnotation(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _inTable)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
modelica_metatype _cr = NULL;
modelica_metatype _exp = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_cr = tmpMeta[1];
_exp = omc_BaseHashTable_get(threadData, _cr, _inTable);
tmpMeta[0] = omc_DAEUtil_replaceCrefInAnnotation(threadData, _exp, _inTable);
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_evaluateAnnotationTraverse(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _itpl, modelica_metatype *out_otpl)
{
modelica_metatype _outExp = NULL;
modelica_metatype _otpl = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;
tmp4_1 = _inExp;
tmp4_2 = _itpl;
{
modelica_metatype _ht = NULL;
modelica_metatype _exp = NULL;
modelica_metatype _e1 = NULL;
modelica_integer _i;
modelica_integer _j;
modelica_integer _k;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
modelica_integer tmp7;
modelica_boolean tmp8;
modelica_integer tmp9;
modelica_integer tmp10;
modelica_boolean tmp11;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,3) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],3,1) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp6 = mmc_unbox_integer(tmpMeta[5]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp7 = mmc_unbox_integer(tmpMeta[6]);
_exp = tmp4_1;
_ht = tmpMeta[4];
_i = tmp6;
_j = tmp7;
tmp4 += 1;
tmpMeta[2] = omc_Expression_extendArrExp(threadData, _exp, 0, &tmp8);
_e1 = tmpMeta[2];
if (1 != tmp8) goto goto_2;
tmpMeta[6] = omc_Expression_traverseExpBottomUp(threadData, _e1, boxvar_DAEUtil_evaluateAnnotationTraverse, _itpl, &tmpMeta[2]);
_e1 = tmpMeta[6];
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp9 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp10 = mmc_unbox_integer(tmpMeta[5]);
_ht = tmpMeta[3];
_i = tmp9;
_k = tmp10;
tmp11 = (_k > _j);
if (1 != tmp11) goto goto_2;
tmpMeta[2] = mmc_mk_box3(0, _ht, mmc_mk_integer(_i), mmc_mk_integer(_k));
tmpMeta[0+0] = _e1;
tmpMeta[0+1] = tmpMeta[2];
goto tmp3_done;
}
case 1: {
modelica_integer tmp12;
modelica_integer tmp13;
modelica_boolean tmp14;
modelica_integer tmp15;
modelica_integer tmp16;
modelica_boolean tmp17;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],6,2) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp12 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp13 = mmc_unbox_integer(tmpMeta[5]);
_exp = tmp4_1;
_ht = tmpMeta[3];
_i = tmp12;
_j = tmp13;
tmpMeta[2] = omc_Expression_extendArrExp(threadData, _exp, 0, &tmp14);
_e1 = tmpMeta[2];
if (1 != tmp14) goto goto_2;
tmpMeta[6] = omc_Expression_traverseExpBottomUp(threadData, _e1, boxvar_DAEUtil_evaluateAnnotationTraverse, _itpl, &tmpMeta[2]);
_e1 = tmpMeta[6];
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp15 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmp16 = mmc_unbox_integer(tmpMeta[5]);
_ht = tmpMeta[3];
_i = tmp15;
_k = tmp16;
tmp17 = (_k > _j);
if (1 != tmp17) goto goto_2;
tmpMeta[2] = mmc_mk_box3(0, _ht, mmc_mk_integer(_i), mmc_mk_integer(_k));
tmpMeta[0+0] = _e1;
tmpMeta[0+1] = tmpMeta[2];
goto tmp3_done;
}
case 2: {
modelica_integer tmp18;
modelica_integer tmp19;
modelica_boolean tmp20;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp18 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp19 = mmc_unbox_integer(tmpMeta[4]);
_exp = tmp4_1;
_ht = tmpMeta[2];
_i = tmp18;
_j = tmp19;
_e1 = omc_DAEUtil_replaceCrefInAnnotation(threadData, _exp, _ht);
tmp20 = omc_Expression_isConst(threadData, _e1);
if (1 != tmp20) goto goto_2;
tmpMeta[2] = mmc_mk_box3(0, _ht, mmc_mk_integer(_i), mmc_mk_integer(((modelica_integer) 1) + _j));
tmpMeta[0+0] = _e1;
tmpMeta[0+1] = tmpMeta[2];
goto tmp3_done;
}
case 3: {
modelica_integer tmp21;
modelica_integer tmp22;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 2));
tmp21 = mmc_unbox_integer(tmpMeta[3]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmp22 = mmc_unbox_integer(tmpMeta[4]);
_exp = tmp4_1;
_ht = tmpMeta[2];
_i = tmp21;
_j = tmp22;
tmpMeta[2] = mmc_mk_box3(0, _ht, mmc_mk_integer(((modelica_integer) 1) + _i), mmc_mk_integer(_j));
tmpMeta[0+0] = _exp;
tmpMeta[0+1] = tmpMeta[2];
goto tmp3_done;
}
case 4: {
tmpMeta[0+0] = _inExp;
tmpMeta[0+1] = _itpl;
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
_outExp = tmpMeta[0+0];
_otpl = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_otpl) { *out_otpl = _otpl; }
return _outExp;
}
DLLExport
modelica_metatype omc_DAEUtil_evaluateAnnotation(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _env, modelica_metatype _inDAElist)
{
modelica_metatype _outDAElist = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inDAElist;
{
modelica_metatype _dae = NULL;
modelica_metatype _ht = NULL;
modelica_metatype _pv = NULL;
modelica_metatype _ht1 = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _elts2 = NULL;
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
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_dae = tmp3_1;
_elts = tmpMeta[1];
_pv = omc_DAEUtil_getParameterVars(threadData, _dae, omc_HashTable2_emptyHashTable(threadData));
tmpMeta[1] = omc_DAEUtil_evaluateAnnotation1(threadData, _dae, _pv, omc_HashTable2_emptyHashTable(threadData), &tmp5);
_ht = tmpMeta[1];
if (1 != tmp5) goto goto_1;
omc_DAEUtil_evaluateAnnotation2__loop(threadData, _inCache, _env, _dae, _ht, omc_BaseHashTable_hashTableCurrentSize(threadData, _ht) ,&_ht1 ,NULL);
tmpMeta[1] = mmc_mk_box3(0, _ht1, mmc_mk_integer(((modelica_integer) 0)), mmc_mk_integer(((modelica_integer) 0)));
tmpMeta[2] = mmc_mk_box2(0, boxvar_DAEUtil_evaluateAnnotationTraverse, tmpMeta[1]);
_elts2 = omc_DAEUtil_traverseDAEElementList(threadData, _elts, boxvar_Expression_traverseSubexpressionsHelper, tmpMeta[2], NULL);
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elts2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _inDAElist;
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
_outDAElist = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDAElist;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_compareCrefList(threadData_t *threadData, modelica_metatype _inCrefs, modelica_boolean *out_matching)
{
modelica_metatype _outrefs = NULL;
modelica_boolean _matching;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inCrefs;
{
modelica_metatype _crefs = NULL;
modelica_metatype _recRefs = NULL;
modelica_integer _i;
modelica_boolean _b1;
modelica_boolean _b2;
modelica_boolean _b3;
modelica_metatype _llrefs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta[2];
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (!listEmpty(tmpMeta[3])) goto tmp3_end;
_crefs = tmpMeta[2];
tmpMeta[0+0] = _crefs;
tmp1_c1 = 1;
goto tmp3_done;
}
case 2: {
modelica_boolean tmp6;
modelica_boolean tmp7;
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
_crefs = tmpMeta[2];
_llrefs = tmpMeta[3];
_recRefs = omc_DAEUtil_compareCrefList(threadData, _llrefs ,&_b3);
_i = listLength(_recRefs);
if((_i > ((modelica_integer) 0)))
{
_b1 = (((modelica_integer) 0) == modelica_integer_mod(listLength(_crefs), _i));
tmpMeta[2] = mmc_mk_cons(_recRefs, mmc_mk_cons(_crefs, MMC_REFSTRUCTLIT(mmc_nil)));
_crefs = omc_List_unionOnTrueList(threadData, tmpMeta[2], boxvar_ComponentReference_crefEqual);
_b2 = (listLength(_crefs) == _i);
_b1 = (_b1 && (_b2 && _b3));
}
else
{
tmp6 = (_i == ((modelica_integer) 0));
if (1 != tmp6) goto goto_2;
tmp7 = (listLength(_crefs) == ((modelica_integer) 0));
if (1 != tmp7) goto goto_2;
_b1 = 1;
}
tmpMeta[0+0] = _crefs;
tmp1_c1 = _b1;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outrefs = tmpMeta[0+0];
_matching = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_matching) { *out_matching = _matching; }
return _outrefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_compareCrefList(threadData_t *threadData, modelica_metatype _inCrefs, modelica_metatype *out_matching)
{
modelica_boolean _matching;
modelica_metatype _outrefs = NULL;
_outrefs = omc_DAEUtil_compareCrefList(threadData, _inCrefs, &_matching);
if (out_matching) { *out_matching = mmc_mk_icon(_matching); }
return _outrefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_collectWhenCrefs1(threadData_t *threadData, modelica_metatype _inExp, modelica_metatype _source, modelica_metatype _inCrefs)
{
modelica_metatype _outCrefs = NULL;
modelica_metatype _e = NULL;
modelica_metatype _exps = NULL;
modelica_metatype _cr = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
modelica_string _msg = NULL;
modelica_metatype _info = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_cr = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_cr, _inCrefs);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 22: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,19,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_exps = tmpMeta[1];
tmpMeta[0] = omc_DAEUtil_collectWhenCrefs(threadData, _exps, _source, _inCrefs);
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
_msg = omc_ExpressionDump_printExpStr(threadData, _inExp);
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _source);
tmpMeta[1] = mmc_mk_cons(_msg, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT99, tmpMeta[1], _info);
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
_outCrefs = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_collectWhenCrefs(threadData_t *threadData, modelica_metatype _inExps, modelica_metatype _source, modelica_metatype _inCrefs)
{
modelica_metatype _outCrefs = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outCrefs = omc_List_fold1(threadData, _inExps, boxvar_DAEUtil_collectWhenCrefs1, _source, _inCrefs);
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_verifyBoolWhenEquation1(threadData_t *threadData, modelica_metatype _inElems, modelica_boolean _initCond, modelica_metatype _inCrefs)
{
modelica_metatype _outCrefs = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElems;
{
modelica_metatype _rest = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _e = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype _crefsLists = NULL;
modelica_metatype _source = NULL;
modelica_metatype _info = NULL;
modelica_metatype _el = NULL;
modelica_metatype _falseEqs = NULL;
modelica_metatype _trueEqs = NULL;
modelica_boolean _b;
modelica_string _msg = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 14; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _inCrefs;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,13) == 0) goto tmp2_end;
_rest = tmpMeta[2];
_inElems = _rest;
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cr = tmpMeta[3];
_rest = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_cr, _inCrefs);
_inElems = _rest;
_inCrefs = tmpMeta[1];
goto _tailrecursive;
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_e = tmpMeta[3];
_source = tmpMeta[4];
_rest = tmpMeta[2];
_crefs = omc_DAEUtil_collectWhenCrefs1(threadData, _e, _source, _inCrefs);
_inElems = _rest;
_inCrefs = _crefs;
goto _tailrecursive;
goto tmp2_done;
}
case 4: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
_e = tmpMeta[3];
_source = tmpMeta[4];
_rest = tmpMeta[2];
_crefs = omc_DAEUtil_collectWhenCrefs1(threadData, _e, _source, _inCrefs);
_inElems = _rest;
_inCrefs = _crefs;
goto _tailrecursive;
goto tmp2_done;
}
case 5: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],8,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_e = tmpMeta[3];
_source = tmpMeta[4];
_rest = tmpMeta[2];
_crefs = omc_DAEUtil_collectWhenCrefs1(threadData, _e, _source, _inCrefs);
_inElems = _rest;
_inCrefs = _crefs;
goto _tailrecursive;
goto tmp2_done;
}
case 6: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cr = tmpMeta[3];
_rest = tmpMeta[2];
tmpMeta[1] = mmc_mk_cons(_cr, _inCrefs);
_inElems = _rest;
_inCrefs = tmpMeta[1];
goto _tailrecursive;
goto tmp2_done;
}
case 7: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],12,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
_trueEqs = tmpMeta[3];
_falseEqs = tmpMeta[4];
_source = tmpMeta[5];
_rest = tmpMeta[2];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_crefsLists = omc_List_map2(threadData, _trueEqs, boxvar_DAEUtil_verifyBoolWhenEquation1, mmc_mk_boolean(_initCond), tmpMeta[1]);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_crefs = omc_DAEUtil_verifyBoolWhenEquation1(threadData, _falseEqs, _initCond, tmpMeta[1]);
tmpMeta[1] = mmc_mk_cons(_crefs, _crefsLists);
_crefsLists = tmpMeta[1];
_crefs = omc_DAEUtil_compareCrefList(threadData, _crefsLists ,&_b);
if((!_b))
{
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _source);
_msg = _OMC_LIT100;
tmpMeta[1] = mmc_mk_cons(_msg, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT99, tmpMeta[1], _info);
goto goto_1;
}
_inElems = _rest;
_inCrefs = listAppend(_crefs, _inCrefs);
goto _tailrecursive;
goto tmp2_done;
}
case 8: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],19,4) == 0) goto tmp2_end;
_rest = tmpMeta[2];
_inElems = _rest;
goto _tailrecursive;
goto tmp2_done;
}
case 9: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],21,2) == 0) goto tmp2_end;
_rest = tmpMeta[2];
_inElems = _rest;
goto _tailrecursive;
goto tmp2_done;
}
case 10: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],23,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_source = tmpMeta[3];
_rest = tmpMeta[2];
if(_initCond)
{
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _source);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessage(threadData, _OMC_LIT103, tmpMeta[1], _info);
goto goto_1;
}
_inElems = _rest;
goto _tailrecursive;
goto tmp2_done;
}
case 11: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],24,2) == 0) goto tmp2_end;
_rest = tmpMeta[2];
_inElems = _rest;
goto _tailrecursive;
goto tmp2_done;
}
case 12: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],10,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
_e = tmpMeta[3];
_source = tmpMeta[4];
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _source);
if(omc_Types_isClockOrSubTypeClock(threadData, omc_Expression_typeof(threadData, _e)))
{
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessage(threadData, _OMC_LIT109, tmpMeta[1], _info);
}
else
{
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessage(threadData, _OMC_LIT106, tmpMeta[1], _info);
}
goto goto_1;
goto tmp2_done;
}
case 13: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_el = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_el, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = stringAppend(_OMC_LIT110,omc_DAEDump_dumpElementsStr(threadData, tmpMeta[1]));
_msg = tmpMeta[2];
_info = omc_ElementSource_getElementSourceFileInfo(threadData, omc_ElementSource_getElementSource(threadData, _el));
tmpMeta[1] = mmc_mk_cons(_msg, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT77, tmpMeta[1], _info);
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
_outCrefs = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outCrefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_verifyBoolWhenEquation1(threadData_t *threadData, modelica_metatype _inElems, modelica_metatype _initCond, modelica_metatype _inCrefs)
{
modelica_integer tmp1;
modelica_metatype _outCrefs = NULL;
tmp1 = mmc_unbox_integer(_initCond);
_outCrefs = omc_DAEUtil_verifyBoolWhenEquation1(threadData, _inElems, tmp1, _inCrefs);
return _outCrefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_verifyBoolWhenEquationBranch(threadData_t *threadData, modelica_metatype _inCond, modelica_metatype _inEqs)
{
modelica_metatype _crefs = NULL;
modelica_boolean _initCond;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_initCond = omc_Expression_containsInitialCall(threadData, _inCond);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_crefs = omc_DAEUtil_verifyBoolWhenEquation1(threadData, _inEqs, _initCond, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return _crefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_collectWhenEquationBranches(threadData_t *threadData, modelica_metatype _inElseWhen, modelica_metatype _inWhenBranches)
{
modelica_metatype _outWhenBranches = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElseWhen;
{
modelica_metatype _cond = NULL;
modelica_metatype _eqs = NULL;
modelica_metatype _ew = NULL;
modelica_metatype _info = NULL;
modelica_string _msg = NULL;
modelica_metatype _el = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _inWhenBranches;
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],10,4) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_cond = tmpMeta[2];
_eqs = tmpMeta[3];
_ew = tmpMeta[4];
tmpMeta[2] = mmc_mk_box2(0, _cond, _eqs);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _inWhenBranches);
_inElseWhen = _ew;
_inWhenBranches = tmpMeta[1];
goto _tailrecursive;
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_el = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_el, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = stringAppend(_OMC_LIT111,omc_DAEDump_dumpElementsStr(threadData, tmpMeta[1]));
_msg = tmpMeta[2];
_info = omc_ElementSource_getElementSourceFileInfo(threadData, omc_ElementSource_getElementSource(threadData, _el));
tmpMeta[1] = mmc_mk_cons(_msg, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT77, tmpMeta[1], _info);
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
_outWhenBranches = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outWhenBranches;
}
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_verifyBoolWhenEquation(threadData_t *threadData, modelica_metatype _inCond, modelica_metatype _inEqs, modelica_metatype _inElseWhen, modelica_metatype _source)
{
modelica_metatype _crefs1 = NULL;
modelica_metatype _crefs2 = NULL;
modelica_metatype _whenBranches = NULL;
modelica_metatype _whenBranch = NULL;
modelica_metatype _cond = NULL;
modelica_metatype _eqs = NULL;
modelica_metatype _info = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_crefs1 = omc_DAEUtil_verifyBoolWhenEquationBranch(threadData, _inCond, _inEqs);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_whenBranches = omc_DAEUtil_collectWhenEquationBranches(threadData, _inElseWhen, tmpMeta[0]);
{
modelica_metatype _whenBranch;
for (tmpMeta[0] = _whenBranches; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_whenBranch = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = _whenBranch;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cond = tmpMeta[2];
_eqs = tmpMeta[3];
if(omc_Types_isClockOrSubTypeClock(threadData, omc_Expression_typeof(threadData, _cond)))
{
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _source);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessageAndFail(threadData, _OMC_LIT114, tmpMeta[1], _info);
}
_crefs2 = omc_DAEUtil_verifyBoolWhenEquationBranch(threadData, _cond, _eqs);
_crefs2 = omc_List_unionOnTrue(threadData, _crefs1, _crefs2, boxvar_ComponentReference_crefEqual);
if((listLength(_crefs2) != listLength(_crefs1)))
{
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _source);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessageAndFail(threadData, _OMC_LIT118, tmpMeta[1], _info);
}
}
}
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_verifyClockWhenEquation1(threadData_t *threadData, modelica_metatype _inEqs)
{
modelica_metatype _el = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _el;
for (tmpMeta[0] = _inEqs; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_el = MMC_CAR(tmpMeta[0]);
{
modelica_metatype tmp3_1;
tmp3_1 = _el;
{
modelica_metatype _cond = NULL;
modelica_metatype _eqs = NULL;
modelica_metatype _ew = NULL;
modelica_metatype _source = NULL;
modelica_metatype _info = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 26: {
_info = omc_ElementSource_getElementSourceFileInfo(threadData, omc_ElementSource_getElementSource(threadData, _el));
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessageAndFail(threadData, _OMC_LIT121, tmpMeta[1], _info);
goto tmp2_done;
}
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_cond = tmpMeta[1];
_eqs = tmpMeta[2];
_ew = tmpMeta[3];
_source = tmpMeta[4];
if(omc_Types_isClockOrSubTypeClock(threadData, omc_Expression_typeof(threadData, _cond)))
{
_info = omc_ElementSource_getElementSourceFileInfo(threadData, omc_ElementSource_getElementSource(threadData, _el));
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessageAndFail(threadData, _OMC_LIT124, tmpMeta[1], _info);
}
omc_DAEUtil_verifyBoolWhenEquation(threadData, _cond, _eqs, _ew, _source);
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
}
}
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_verifyClockWhenEquation(threadData_t *threadData, modelica_metatype _cond, modelica_metatype _eqs, modelica_metatype _ew, modelica_metatype _source)
{
modelica_metatype _info = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if((!isNone(_ew)))
{
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _source);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessageAndFail(threadData, _OMC_LIT127, tmpMeta[0], _info);
}
omc_DAEUtil_verifyClockWhenEquation1(threadData, _eqs);
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC void omc_DAEUtil_verifyWhenEquation(threadData_t *threadData, modelica_metatype _cond, modelica_metatype _eqs, modelica_metatype _ew, modelica_metatype _source)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_Types_isClockOrSubTypeClock(threadData, omc_Expression_typeof(threadData, _cond)))
{
omc_DAEUtil_verifyClockWhenEquation(threadData, _cond, _eqs, _ew, _source);
}
else
{
omc_DAEUtil_verifyBoolWhenEquation(threadData, _cond, _eqs, _ew, _source);
}
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_DAEUtil_verifyEquationsDAE(threadData_t *threadData, modelica_metatype _dae)
{
modelica_metatype _cond = NULL;
modelica_metatype _dae_elts = NULL;
modelica_metatype _eqs = NULL;
modelica_metatype _ew = NULL;
modelica_metatype _source = NULL;
modelica_metatype _el = NULL;
modelica_metatype _info = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _dae;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_dae_elts = tmpMeta[1];
{
modelica_metatype _el;
for (tmpMeta[0] = _dae_elts; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_el = MMC_CAR(tmpMeta[0]);
{
modelica_metatype tmp3_1;
tmp3_1 = _el;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 13: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_cond = tmpMeta[1];
_eqs = tmpMeta[2];
_ew = tmpMeta[3];
_source = tmpMeta[4];
omc_DAEUtil_verifyWhenEquation(threadData, _cond, _eqs, _ew, _source);
goto tmp2_done;
}
case 26: {
_info = omc_ElementSource_getElementSourceFileInfo(threadData, omc_ElementSource_getElementSource(threadData, _el));
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Error_addSourceMessageAndFail(threadData, _OMC_LIT121, tmpMeta[1], _info);
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
}
}
_return: OMC_LABEL_UNUSED
return;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_crefToExp(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outExp = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outExp = omc_Expression_makeCrefExp(threadData, _inComponentRef, _OMC_LIT24);
_return: OMC_LABEL_UNUSED
return _outExp;
}
DLLExport
modelica_metatype omc_DAEUtil_getTupleExps(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _exps = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,19,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_exps = tmpMeta[1];
tmpMeta[0] = _exps;
goto tmp2_done;
}
case 1: {
tmpMeta[1] = mmc_mk_cons(_inExp, MMC_REFSTRUCTLIT(mmc_nil));
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
_exps = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _exps;
}
DLLExport
modelica_integer omc_DAEUtil_getTupleSize(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_integer _size;
modelica_integer tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inExp;
{
modelica_metatype _exps = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,19,1) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
_exps = tmpMeta[0];
tmp1 = listLength(_exps);
goto tmp3_done;
}
case 1: {
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
_size = tmp1;
_return: OMC_LABEL_UNUSED
return _size;
}
modelica_metatype boxptr_DAEUtil_getTupleSize(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_integer _size;
modelica_metatype out_size;
_size = omc_DAEUtil_getTupleSize(threadData, _inExp);
out_size = mmc_mk_icon(_size);
return out_size;
}
DLLExport
modelica_metatype omc_DAEUtil_getStatement(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outStatements = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_metatype _stmts = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,15,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_stmts = tmpMeta[2];
tmpMeta[0] = _stmts;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
tmp5 = omc_Flags_isSet(threadData, _OMC_LIT86);
if (1 != tmp5) goto goto_1;
omc_Debug_trace(threadData, _OMC_LIT128);
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
_outStatements = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outStatements;
}
DLLExport
modelica_metatype omc_DAEUtil_getFunctionAlgorithmStmts(threadData_t *threadData, modelica_metatype _fn)
{
modelica_metatype _bodyStmts = NULL;
modelica_metatype _elements = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elements = omc_DAEUtil_getFunctionElements(threadData, _fn);
_bodyStmts = omc_List_mapFlat(threadData, omc_List_filterOnTrue(threadData, _elements, boxvar_DAEUtil_isAlgorithm), boxvar_DAEUtil_getStatement);
_return: OMC_LABEL_UNUSED
return _bodyStmts;
}
DLLExport
modelica_metatype omc_DAEUtil_getFunctionAlgorithms(threadData_t *threadData, modelica_metatype _fn)
{
modelica_metatype _outEls = NULL;
modelica_metatype _elements = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elements = omc_DAEUtil_getFunctionElements(threadData, _fn);
_outEls = omc_List_filterOnTrue(threadData, _elements, boxvar_DAEUtil_isAlgorithm);
_return: OMC_LABEL_UNUSED
return _outEls;
}
DLLExport
modelica_metatype omc_DAEUtil_getFunctionProtectedVars(threadData_t *threadData, modelica_metatype _fn)
{
modelica_metatype _outEls = NULL;
modelica_metatype _elements = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elements = omc_DAEUtil_getFunctionElements(threadData, _fn);
_outEls = omc_List_filterOnTrue(threadData, _elements, boxvar_DAEUtil_isProtectedVar);
_return: OMC_LABEL_UNUSED
return _outEls;
}
DLLExport
modelica_metatype omc_DAEUtil_getFunctionOutputVars(threadData_t *threadData, modelica_metatype _fn)
{
modelica_metatype _outEls = NULL;
modelica_metatype _elements = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elements = omc_DAEUtil_getFunctionElements(threadData, _fn);
_outEls = omc_List_filterOnTrue(threadData, _elements, boxvar_DAEUtil_isOutputVar);
_return: OMC_LABEL_UNUSED
return _outEls;
}
DLLExport
modelica_metatype omc_DAEUtil_getFunctionInputVars(threadData_t *threadData, modelica_metatype _fn)
{
modelica_metatype _outEls = NULL;
modelica_metatype _elements = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elements = omc_DAEUtil_getFunctionElements(threadData, _fn);
_outEls = omc_List_filterOnTrue(threadData, _elements, boxvar_DAEUtil_isInputVar);
_return: OMC_LABEL_UNUSED
return _outEls;
}
DLLExport
modelica_metatype omc_DAEUtil_getFunctionInlineType(threadData_t *threadData, modelica_metatype _fn)
{
modelica_metatype _outInlineType = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _fn;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,10) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
_outInlineType = tmpMeta[1];
tmpMeta[0] = _outInlineType;
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
_outInlineType = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outInlineType;
}
DLLExport
modelica_boolean omc_DAEUtil_getFunctionImpureAttribute(threadData_t *threadData, modelica_metatype _fn)
{
modelica_boolean _outImpure;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _fn;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,10) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
tmp6 = mmc_unbox_integer(tmpMeta[0]);
_outImpure = tmp6;
tmp1 = _outImpure;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outImpure = tmp1;
_return: OMC_LABEL_UNUSED
return _outImpure;
}
modelica_metatype boxptr_DAEUtil_getFunctionImpureAttribute(threadData_t *threadData, modelica_metatype _fn)
{
modelica_boolean _outImpure;
modelica_metatype out_outImpure;
_outImpure = omc_DAEUtil_getFunctionImpureAttribute(threadData, _fn);
out_outImpure = mmc_mk_icon(_outImpure);
return out_outImpure;
}
DLLExport
modelica_metatype omc_DAEUtil_getFunctionType(threadData_t *threadData, modelica_metatype _fn)
{
modelica_metatype _outType = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _fn;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,10) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_outType = tmpMeta[1];
tmpMeta[0] = _outType;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,10) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_outType = tmpMeta[1];
tmpMeta[0] = _outType;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_outType = tmpMeta[1];
tmpMeta[0] = _outType;
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
DLLExport
modelica_metatype omc_DAEUtil_getFunctionElements(threadData_t *threadData, modelica_metatype _fn)
{
modelica_metatype _els = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _fn;
{
modelica_metatype _elements = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,10) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,1) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_elements = tmpMeta[4];
tmpMeta[0] = _elements;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,10) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,2) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_elements = tmpMeta[4];
tmpMeta[0] = _elements;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
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
_els = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _els;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getFunctionsElements(threadData_t *threadData, modelica_metatype _elements)
{
modelica_metatype _els = NULL;
modelica_metatype _elsList = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elsList = omc_List_map(threadData, _elements, boxvar_DAEUtil_getFunctionElements);
_els = omc_List_flatten(threadData, _elsList);
_return: OMC_LABEL_UNUSED
return _els;
}
DLLExport
modelica_metatype omc_DAEUtil_getFunctionVisibility(threadData_t *threadData, modelica_metatype _fn)
{
modelica_metatype _visibility = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _fn;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,10) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_visibility = tmpMeta[1];
tmpMeta[0] = _visibility;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _OMC_LIT22;
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
_visibility = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _visibility;
}
DLLExport
modelica_metatype omc_DAEUtil_getNamedFunctionFromList(threadData_t *threadData, modelica_metatype _ipath, modelica_metatype _ifns)
{
modelica_metatype _fn = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _ipath;
tmp3_2 = _ifns;
{
modelica_metatype _path = NULL;
modelica_metatype _fns = NULL;
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
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
_fn = tmpMeta[1];
_path = tmp3_1;
tmp5 = omc_AbsynUtil_pathEqual(threadData, omc_DAEUtil_functionName(threadData, _fn), _path);
if (1 != tmp5) goto goto_1;
tmpMeta[0] = _fn;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_2);
tmpMeta[2] = MMC_CDR(tmp3_2);
_fns = tmpMeta[2];
_path = tmp3_1;
tmp3 += 1;
tmpMeta[0] = omc_DAEUtil_getNamedFunctionFromList(threadData, _path, _fns);
goto tmp2_done;
}
case 2: {
modelica_boolean tmp6;
if (!listEmpty(tmp3_2)) goto tmp2_end;
_path = tmp3_1;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT86);
if (1 != tmp6) goto goto_1;
tmpMeta[1] = stringAppend(_OMC_LIT129,omc_AbsynUtil_pathString(threadData, _path, _OMC_LIT29, 1, 0));
omc_Debug_traceln(threadData, tmpMeta[1]);
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
if (++tmp3 < 3) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_fn = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _fn;
}
DLLExport
modelica_metatype omc_DAEUtil_getNamedFunctionWithError(threadData_t *threadData, modelica_metatype _path, modelica_metatype _functions, modelica_metatype _info)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_string _msg = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[0] = omc_Util_getOption(threadData, omc_DAE_AvlTreePathFunction_get(threadData, _functions, _path));
goto tmp2_done;
}
case 1: {
_msg = stringDelimitList(omc_List_mapMap(threadData, omc_DAEUtil_getFunctionList(threadData, _functions, 0), boxvar_DAEUtil_functionName, boxvar_AbsynUtil_pathStringDefault), _OMC_LIT26);
tmpMeta[1] = stringAppend(_OMC_LIT130,omc_AbsynUtil_pathString(threadData, _path, _OMC_LIT29, 1, 0));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT131);
tmpMeta[3] = stringAppend(tmpMeta[2],_msg);
_msg = tmpMeta[3];
tmpMeta[1] = mmc_mk_cons(_msg, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT77, tmpMeta[1], _info);
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
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
DLLExport
modelica_metatype omc_DAEUtil_getNamedFunction(threadData_t *threadData, modelica_metatype _path, modelica_metatype _functions)
{
modelica_metatype _outElement = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
{
modelica_string _msg = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[0] = omc_Util_getOption(threadData, omc_DAE_AvlTreePathFunction_get(threadData, _functions, _path));
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
tmp5 = omc_Flags_isSet(threadData, _OMC_LIT86);
if (1 != tmp5) goto goto_1;
_msg = stringDelimitList(omc_List_mapMap(threadData, omc_DAEUtil_getFunctionList(threadData, _functions, 0), boxvar_DAEUtil_functionName, boxvar_AbsynUtil_pathStringDefault), _OMC_LIT26);
tmpMeta[1] = stringAppend(_OMC_LIT130,omc_AbsynUtil_pathString(threadData, _path, _OMC_LIT29, 1, 0));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT131);
tmpMeta[3] = stringAppend(tmpMeta[2],_msg);
_msg = tmpMeta[3];
omc_Debug_traceln(threadData, _msg);
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
_outElement = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_toModelicaFormExp(threadData_t *threadData, modelica_metatype _inExp)
{
modelica_metatype _outExp = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inExp;
{
modelica_metatype _cr_1 = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _t = NULL;
modelica_metatype _e1_1 = NULL;
modelica_metatype _e2_1 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e3_1 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _op = NULL;
modelica_metatype _expl_1 = NULL;
modelica_metatype _expl = NULL;
modelica_metatype _f = NULL;
modelica_boolean _b;
modelica_integer _i;
modelica_metatype _eopt_1 = NULL;
modelica_metatype _eopt = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _optionExpisASUB = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 14; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_cr = tmpMeta[1];
_t = tmpMeta[2];
tmp3 += 12;
_cr_1 = omc_DAEUtil_toModelicaFormCref(threadData, _cr);
tmpMeta[0] = omc_Expression_makeCrefExp(threadData, _cr_1, _t);
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
tmp3 += 11;
_e1_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
_e2_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e2);
tmpMeta[1] = mmc_mk_box4(10, &DAE_Exp_BINARY__desc, _e1_1, _op, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,9,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
tmp3 += 10;
_e1_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
_e2_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e2);
tmpMeta[1] = mmc_mk_box4(12, &DAE_Exp_LBINARY__desc, _e1_1, _op, _e2_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,8,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_op = tmpMeta[1];
_e = tmpMeta[2];
tmp3 += 9;
_e_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e);
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, _op, _e_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,10,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_op = tmpMeta[1];
_e = tmpMeta[2];
tmp3 += 8;
_e_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e);
tmpMeta[1] = mmc_mk_box3(13, &DAE_Exp_LUNARY__desc, _op, _e_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,11,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmp5 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
_e1 = tmpMeta[1];
_op = tmpMeta[2];
_e2 = tmpMeta[3];
_i = tmp5;
_optionExpisASUB = tmpMeta[5];
tmp3 += 7;
_e1_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
_e2_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e2);
tmpMeta[1] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, _e1_1, _op, _e2_1, mmc_mk_integer(_i), _optionExpisASUB);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,12,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_e1 = tmpMeta[1];
_e2 = tmpMeta[2];
_e3 = tmpMeta[3];
tmp3 += 6;
_e1_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
_e2_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e2);
_e3_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e3);
tmpMeta[1] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, _e1_1, _e2_1, _e3_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 7: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_f = tmpMeta[1];
_expl = tmpMeta[2];
_attr = tmpMeta[3];
tmp3 += 5;
_expl_1 = omc_List_map(threadData, _expl, boxvar_DAEUtil_toModelicaFormExp);
tmpMeta[1] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _f, _expl_1, _attr);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 8: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,16,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_t = tmpMeta[1];
_b = tmp6;
_expl = tmpMeta[3];
tmp3 += 4;
_expl_1 = omc_List_map(threadData, _expl, boxvar_DAEUtil_toModelicaFormExp);
tmpMeta[1] = mmc_mk_box4(19, &DAE_Exp_ARRAY__desc, _t, mmc_mk_boolean(_b), _expl_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,19,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_expl = tmpMeta[1];
tmp3 += 3;
_expl_1 = omc_List_map(threadData, _expl, boxvar_DAEUtil_toModelicaFormExp);
tmpMeta[1] = mmc_mk_box2(22, &DAE_Exp_TUPLE__desc, _expl_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 10: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,20,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_t = tmpMeta[1];
_e = tmpMeta[2];
tmp3 += 2;
_e_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e);
tmpMeta[1] = mmc_mk_box3(23, &DAE_Exp_CAST__desc, _t, _e_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 11: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,21,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_e = tmpMeta[1];
_expl = tmpMeta[2];
tmp3 += 1;
_e_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e);
tmpMeta[0] = omc_Expression_makeASUB(threadData, _e_1, _expl);
goto tmp2_done;
}
case 12: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,24,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_e = tmpMeta[1];
_eopt = tmpMeta[2];
_e_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e);
_eopt_1 = omc_DAEUtil_toModelicaFormExpOpt(threadData, _eopt);
tmpMeta[1] = mmc_mk_box3(27, &DAE_Exp_SIZE__desc, _e_1, _eopt_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 13: {
_e = tmp3_1;
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
if (++tmp3 < 14) {
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_toModelicaFormCref(threadData_t *threadData, modelica_metatype _cr)
{
modelica_metatype _outComponentRef = NULL;
modelica_string _str = NULL;
modelica_string _str_1 = NULL;
modelica_metatype _ty = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_str = omc_ComponentReference_printComponentRefStr(threadData, _cr);
_ty = omc_ComponentReference_crefLastType(threadData, _cr);
_str_1 = omc_Util_stringReplaceChar(threadData, _str, _OMC_LIT29, _OMC_LIT132);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outComponentRef = omc_ComponentReference_makeCrefIdent(threadData, _str_1, _ty, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return _outComponentRef;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_toModelicaFormExpOpt(threadData_t *threadData, modelica_metatype _inExpExpOption)
{
modelica_metatype _outExpExpOption = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inExpExpOption;
{
modelica_metatype _e_1 = NULL;
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
_e_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e);
tmpMeta[0] = mmc_mk_some(_e_1);
goto tmp2_done;
}
case 1: {
if (!optionNone(tmp3_1)) goto tmp2_end;
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
_outExpExpOption = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExpExpOption;
}
DLLExport
modelica_metatype omc_DAEUtil_replaceBindungInVar(threadData_t *threadData, modelica_metatype _newBindung, modelica_metatype _inelem)
{
modelica_metatype _outelem = NULL;
modelica_metatype tmpMeta[13] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inelem;
{
modelica_metatype _a1 = NULL;
modelica_metatype _a2 = NULL;
modelica_metatype _a3 = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _a4 = NULL;
modelica_metatype _a5 = NULL;
modelica_metatype _a7 = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _source = NULL;
modelica_metatype _a11 = NULL;
modelica_metatype _a12 = NULL;
modelica_metatype _a13 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 10));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 11));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 12));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 13));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 14));
_a1 = tmpMeta[1];
_a2 = tmpMeta[2];
_a3 = tmpMeta[3];
_prl = tmpMeta[4];
_a4 = tmpMeta[5];
_a5 = tmpMeta[6];
_a7 = tmpMeta[7];
_ct = tmpMeta[8];
_source = tmpMeta[9];
_a11 = tmpMeta[10];
_a12 = tmpMeta[11];
_a13 = tmpMeta[12];
tmpMeta[1] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _a1, _a2, _a3, _prl, _a4, _a5, mmc_mk_some(_newBindung), _a7, _ct, _source, _a11, _a12, _a13);
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
_outelem = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outelem;
}
DLLExport
modelica_metatype omc_DAEUtil_replaceCrefandTypeInVar(threadData_t *threadData, modelica_metatype _newCr, modelica_metatype _newType, modelica_metatype _inelem)
{
modelica_metatype _outelem = NULL;
modelica_metatype tmpMeta[12] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inelem;
{
modelica_metatype _a2 = NULL;
modelica_metatype _a3 = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _a4 = NULL;
modelica_metatype _a7 = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _a6 = NULL;
modelica_metatype _source = NULL;
modelica_metatype _a11 = NULL;
modelica_metatype _a12 = NULL;
modelica_metatype _a13 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 10));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 11));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 12));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 13));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 14));
_a2 = tmpMeta[1];
_a3 = tmpMeta[2];
_prl = tmpMeta[3];
_a4 = tmpMeta[4];
_a6 = tmpMeta[5];
_a7 = tmpMeta[6];
_ct = tmpMeta[7];
_source = tmpMeta[8];
_a11 = tmpMeta[9];
_a12 = tmpMeta[10];
_a13 = tmpMeta[11];
tmpMeta[1] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _newCr, _a2, _a3, _prl, _a4, _newType, _a6, _a7, _ct, _source, _a11, _a12, _a13);
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
_outelem = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outelem;
}
DLLExport
modelica_metatype omc_DAEUtil_replaceTypeInVar(threadData_t *threadData, modelica_metatype _newType, modelica_metatype _inelem)
{
modelica_metatype _outelem = NULL;
modelica_metatype tmpMeta[13] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inelem;
{
modelica_metatype _a1 = NULL;
modelica_metatype _a2 = NULL;
modelica_metatype _a3 = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _a4 = NULL;
modelica_metatype _a7 = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _a6 = NULL;
modelica_metatype _source = NULL;
modelica_metatype _a11 = NULL;
modelica_metatype _a12 = NULL;
modelica_metatype _a13 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 10));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 11));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 12));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 13));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 14));
_a1 = tmpMeta[1];
_a2 = tmpMeta[2];
_a3 = tmpMeta[3];
_prl = tmpMeta[4];
_a4 = tmpMeta[5];
_a6 = tmpMeta[6];
_a7 = tmpMeta[7];
_ct = tmpMeta[8];
_source = tmpMeta[9];
_a11 = tmpMeta[10];
_a12 = tmpMeta[11];
_a13 = tmpMeta[12];
tmpMeta[1] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _a1, _a2, _a3, _prl, _a4, _newType, _a6, _a7, _ct, _source, _a11, _a12, _a13);
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
_outelem = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outelem;
}
DLLExport
modelica_metatype omc_DAEUtil_replaceCrefInVar(threadData_t *threadData, modelica_metatype _newCr, modelica_metatype _inelem)
{
modelica_metatype _outelem = NULL;
modelica_metatype tmpMeta[13] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inelem;
{
modelica_metatype _a2 = NULL;
modelica_metatype _a3 = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _a4 = NULL;
modelica_metatype _a5 = NULL;
modelica_metatype _a7 = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _a6 = NULL;
modelica_metatype _source = NULL;
modelica_metatype _a11 = NULL;
modelica_metatype _a12 = NULL;
modelica_metatype _a13 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 10));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 11));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 12));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 13));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 14));
_a2 = tmpMeta[1];
_a3 = tmpMeta[2];
_prl = tmpMeta[3];
_a4 = tmpMeta[4];
_a5 = tmpMeta[5];
_a6 = tmpMeta[6];
_a7 = tmpMeta[7];
_ct = tmpMeta[8];
_source = tmpMeta[9];
_a11 = tmpMeta[10];
_a12 = tmpMeta[11];
_a13 = tmpMeta[12];
tmpMeta[1] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _newCr, _a2, _a3, _prl, _a4, _a5, _a6, _a7, _ct, _source, _a11, _a12, _a13);
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
_outelem = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outelem;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_toModelicaFormElts(threadData_t *threadData, modelica_metatype _inElementLst)
{
modelica_metatype _outElementLst = NULL;
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElementLst;
{
modelica_string _str = NULL;
modelica_string _str_1 = NULL;
modelica_string _id = NULL;
modelica_metatype _elts_1 = NULL;
modelica_metatype _elts = NULL;
modelica_metatype _welts_1 = NULL;
modelica_metatype _welts = NULL;
modelica_metatype _eelts_1 = NULL;
modelica_metatype _eelts = NULL;
modelica_metatype _elts2 = NULL;
modelica_metatype _d_1 = NULL;
modelica_metatype _d = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _cr_1 = NULL;
modelica_metatype _cref_ = NULL;
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _a = NULL;
modelica_metatype _b = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _t = NULL;
modelica_metatype _instDim = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _elt_1 = NULL;
modelica_metatype _elt = NULL;
modelica_metatype _prot = NULL;
modelica_metatype _dae_var_attr = NULL;
modelica_metatype _comment = NULL;
modelica_metatype _e_1 = NULL;
modelica_metatype _e1_1 = NULL;
modelica_metatype _e2_1 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e_2 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _e_3 = NULL;
modelica_metatype _io = NULL;
modelica_metatype _conds = NULL;
modelica_metatype _conds_1 = NULL;
modelica_metatype _trueBranches = NULL;
modelica_metatype _trueBranches_1 = NULL;
modelica_metatype _source = NULL;
modelica_metatype _alg = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 20; tmp3++) {
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
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,13) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 13));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 14));
_cr = tmpMeta[3];
_a = tmpMeta[4];
_b = tmpMeta[5];
_prl = tmpMeta[6];
_prot = tmpMeta[7];
_t = tmpMeta[8];
_d = tmpMeta[9];
_instDim = tmpMeta[10];
_ct = tmpMeta[11];
_source = tmpMeta[12];
_dae_var_attr = tmpMeta[13];
_comment = tmpMeta[14];
_io = tmpMeta[15];
_elts = tmpMeta[2];
_str = omc_ComponentReference_printComponentRefStr(threadData, _cr);
_str_1 = omc_Util_stringReplaceChar(threadData, _str, _OMC_LIT29, _OMC_LIT132);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
_d_1 = omc_DAEUtil_toModelicaFormExpOpt(threadData, _d);
_ty = omc_ComponentReference_crefLastType(threadData, _cr);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_cref_ = omc_ComponentReference_makeCrefIdent(threadData, _str_1, _ty, tmpMeta[1]);
tmpMeta[2] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _cref_, _a, _b, _prl, _prot, _t, _d_1, _instDim, _ct, _source, _dae_var_attr, _comment, _io);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_cr = tmpMeta[3];
_e = tmpMeta[4];
_source = tmpMeta[5];
_elts = tmpMeta[2];
_e_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e);
_cr_1 = omc_DAEUtil_toModelicaFormCref(threadData, _cr);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box4(4, &DAE_Element_DEFINE__desc, _cr_1, _e_1, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_cr = tmpMeta[3];
_e = tmpMeta[4];
_source = tmpMeta[5];
_elts = tmpMeta[2];
_e_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e);
_cr_1 = omc_DAEUtil_toModelicaFormCref(threadData, _cr);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box4(5, &DAE_Element_INITIALDEFINE__desc, _cr_1, _e_1, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 4: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_source = tmpMeta[5];
_elts = tmpMeta[2];
_e1_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
_e2_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e2);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _e1_1, _e2_1, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 5: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],8,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_source = tmpMeta[5];
_elts = tmpMeta[2];
_e1_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
_e2_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e2);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box4(11, &DAE_Element_COMPLEX__EQUATION__desc, _e1_1, _e2_1, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],9,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_source = tmpMeta[5];
_elts = tmpMeta[2];
_e1_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
_e2_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e2);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box4(12, &DAE_Element_INITIAL__COMPLEX__EQUATION__desc, _e1_1, _e2_1, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 7: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_cr1 = tmpMeta[3];
_cr2 = tmpMeta[4];
_source = tmpMeta[5];
_elts = tmpMeta[2];
tmpMeta[1] = omc_DAEUtil_toModelicaFormExp(threadData, omc_Expression_crefExp(threadData, _cr1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cr1 = tmpMeta[2];
tmpMeta[1] = omc_DAEUtil_toModelicaFormExp(threadData, omc_Expression_crefExp(threadData, _cr2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_cr2 = tmpMeta[2];
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box4(7, &DAE_Element_EQUEQUATION__desc, _cr1, _cr2, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 8: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],10,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
if (optionNone(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
_e1 = tmpMeta[3];
_welts = tmpMeta[4];
_elt = tmpMeta[6];
_source = tmpMeta[7];
_elts = tmpMeta[2];
_e1_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
_welts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _welts);
tmpMeta[1] = mmc_mk_cons(_elt, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = omc_DAEUtil_toModelicaFormElts(threadData, tmpMeta[1]);
if (listEmpty(tmpMeta[2])) goto goto_1;
tmpMeta[3] = MMC_CAR(tmpMeta[2]);
tmpMeta[4] = MMC_CDR(tmpMeta[2]);
if (!listEmpty(tmpMeta[4])) goto goto_1;
_elt_1 = tmpMeta[3];
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _e1_1, _welts_1, mmc_mk_some(_elt_1), _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 9: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],10,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
if (!optionNone(tmpMeta[5])) goto tmp2_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
_e1 = tmpMeta[3];
_welts = tmpMeta[4];
_source = tmpMeta[6];
_elts = tmpMeta[2];
_e1_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
_welts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _welts);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box5(13, &DAE_Element_WHEN__EQUATION__desc, _e1_1, _welts_1, mmc_mk_none(), _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 10: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],12,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
_conds = tmpMeta[3];
_trueBranches = tmpMeta[4];
_eelts = tmpMeta[5];
_source = tmpMeta[6];
_elts = tmpMeta[2];
_conds_1 = omc_List_map(threadData, _conds, boxvar_DAEUtil_toModelicaFormExp);
_trueBranches_1 = omc_List_map(threadData, _trueBranches, boxvar_DAEUtil_toModelicaFormElts);
_eelts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _eelts);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box5(15, &DAE_Element_IF__EQUATION__desc, _conds_1, _trueBranches_1, _eelts_1, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 11: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],13,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
_conds = tmpMeta[3];
_trueBranches = tmpMeta[4];
_eelts = tmpMeta[5];
_source = tmpMeta[6];
_elts = tmpMeta[2];
_conds_1 = omc_List_map(threadData, _conds, boxvar_DAEUtil_toModelicaFormExp);
_trueBranches_1 = omc_List_map(threadData, _trueBranches, boxvar_DAEUtil_toModelicaFormElts);
_eelts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _eelts);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box5(16, &DAE_Element_INITIAL__IF__EQUATION__desc, _conds_1, _trueBranches_1, _eelts_1, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 12: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],14,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_source = tmpMeta[5];
_elts = tmpMeta[2];
_e1_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
_e2_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e2);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box4(17, &DAE_Element_INITIALEQUATION__desc, _e1_1, _e2_1, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 13: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],15,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_alg = tmpMeta[3];
_source = tmpMeta[4];
_elts = tmpMeta[2];
fputs(MMC_STRINGDATA(_OMC_LIT133),stdout);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box3(18, &DAE_Element_ALGORITHM__desc, _alg, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 14: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],16,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_alg = tmpMeta[3];
_source = tmpMeta[4];
_elts = tmpMeta[2];
fputs(MMC_STRINGDATA(_OMC_LIT134),stdout);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box3(19, &DAE_Element_INITIALALGORITHM__desc, _alg, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 15: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],17,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
_id = tmpMeta[3];
_elts2 = tmpMeta[4];
_source = tmpMeta[5];
_comment = tmpMeta[6];
_elts = tmpMeta[2];
_elts2 = omc_DAEUtil_toModelicaFormElts(threadData, _elts2);
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[2] = mmc_mk_box5(20, &DAE_Element_COMP__desc, _id, _elts2, _source, _comment);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 16: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],19,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_e3 = tmpMeta[5];
_source = tmpMeta[6];
_elts = tmpMeta[2];
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
_e_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
_e_2 = omc_DAEUtil_toModelicaFormExp(threadData, _e2);
_e_3 = omc_DAEUtil_toModelicaFormExp(threadData, _e3);
tmpMeta[2] = mmc_mk_box5(22, &DAE_Element_ASSERT__desc, _e_1, _e_2, _e_3, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 17: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],20,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
_e1 = tmpMeta[3];
_e2 = tmpMeta[4];
_e3 = tmpMeta[5];
_source = tmpMeta[6];
_elts = tmpMeta[2];
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
_e_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
_e_2 = omc_DAEUtil_toModelicaFormExp(threadData, _e2);
_e_3 = omc_DAEUtil_toModelicaFormExp(threadData, _e3);
tmpMeta[2] = mmc_mk_box5(23, &DAE_Element_INITIAL__ASSERT__desc, _e_1, _e_2, _e_3, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 18: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],21,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_e1 = tmpMeta[3];
_source = tmpMeta[4];
_elts = tmpMeta[2];
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
_e_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
tmpMeta[2] = mmc_mk_box3(24, &DAE_Element_TERMINATE__desc, _e_1, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 19: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],22,2) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_e1 = tmpMeta[3];
_source = tmpMeta[4];
_elts = tmpMeta[2];
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
_e_1 = omc_DAEUtil_toModelicaFormExp(threadData, _e1);
tmpMeta[2] = mmc_mk_box3(25, &DAE_Element_INITIAL__TERMINATE__desc, _e_1, _source);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elts_1);
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
modelica_metatype omc_DAEUtil_toModelicaForm(threadData_t *threadData, modelica_metatype _inDAElist)
{
modelica_metatype _outDAElist = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inDAElist;
{
modelica_metatype _elts_1 = NULL;
modelica_metatype _elts = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_elts = tmpMeta[1];
_elts_1 = omc_DAEUtil_toModelicaFormElts(threadData, _elts);
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elts_1);
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
_outDAElist = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDAElist;
}
DLLExport
modelica_metatype omc_DAEUtil_daeToRecordValue(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _inElementLst, modelica_boolean _inBoolean, modelica_metatype *out_outValue)
{
modelica_metatype _outCache = NULL;
modelica_metatype _outValue = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;volatile modelica_metatype tmp4_2;volatile modelica_metatype tmp4_3;volatile modelica_metatype tmp4_4;volatile modelica_boolean tmp4_5;
tmp4_1 = _inCache;
tmp4_2 = _inEnv;
tmp4_3 = _inPath;
tmp4_4 = _inElementLst;
tmp4_5 = _inBoolean;
{
modelica_metatype _cname = NULL;
modelica_metatype _value = NULL;
modelica_metatype _vals = NULL;
modelica_metatype _names = NULL;
modelica_string _cr_str = NULL;
modelica_string _str = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _rhs = NULL;
modelica_metatype _rest = NULL;
modelica_boolean _impl;
modelica_integer _ix;
modelica_metatype _el = NULL;
modelica_metatype _cache = NULL;
modelica_metatype _env = NULL;
modelica_metatype _source = NULL;
modelica_metatype _info = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_4)) goto tmp3_end;
_cache = tmp4_1;
_cname = tmp4_3;
tmp4 += 2;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = mmc_mk_box5(13, &Values_Value_RECORD__desc, _cname, tmpMeta[2], tmpMeta[3], mmc_mk_integer(((modelica_integer) -1)));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta[4];
goto tmp3_done;
}
case 1: {
modelica_integer tmp6;
if (listEmpty(tmp4_4)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_4);
tmpMeta[3] = MMC_CDR(tmp4_4);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,13) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 11));
_cr = tmpMeta[4];
_rhs = tmpMeta[6];
_source = tmpMeta[7];
_rest = tmpMeta[3];
_cache = tmp4_1;
_env = tmp4_2;
_cname = tmp4_3;
_impl = tmp4_5;
_info = omc_ElementSource_getElementSourceFileInfo(threadData, _source);
tmpMeta[2] = mmc_mk_box2(3, &Absyn_Msg_MSG__desc, _info);
_cache = omc_Ceval_ceval(threadData, _cache, _env, _rhs, _impl, tmpMeta[2], ((modelica_integer) 0) ,&_value);
tmpMeta[7] = omc_DAEUtil_daeToRecordValue(threadData, _cache, _env, _cname, _rest, _impl, &tmpMeta[2]);
_cache = tmpMeta[7];
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],10,4) == 0) goto goto_2;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmp6 = mmc_unbox_integer(tmpMeta[6]);
_cname = tmpMeta[3];
_vals = tmpMeta[4];
_names = tmpMeta[5];
_ix = tmp6;
_cr_str = omc_ComponentReference_printComponentRefStr(threadData, _cr);
tmpMeta[2] = mmc_mk_cons(_value, _vals);
tmpMeta[3] = mmc_mk_cons(_cr_str, _names);
tmpMeta[4] = mmc_mk_box5(13, &Values_Value_RECORD__desc, _cname, tmpMeta[2], tmpMeta[3], mmc_mk_integer(_ix));
tmpMeta[0+0] = _cache;
tmpMeta[0+1] = tmpMeta[4];
goto tmp3_done;
}
case 2: {
modelica_boolean tmp7;
if (listEmpty(tmp4_4)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_4);
tmpMeta[3] = MMC_CDR(tmp4_4);
_el = tmpMeta[2];
tmp7 = omc_Flags_isSet(threadData, _OMC_LIT86);
if (1 != tmp7) goto goto_2;
tmpMeta[2] = mmc_mk_cons(_el, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta[2]);
_str = omc_DAEDump_dumpDebugDAE(threadData, tmpMeta[3]);
tmpMeta[2] = stringAppend(_OMC_LIT135,_str);
omc_Debug_traceln(threadData, tmpMeta[2]);
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
_outValue = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outValue) { *out_outValue = _outValue; }
return _outCache;
}
modelica_metatype boxptr_DAEUtil_daeToRecordValue(threadData_t *threadData, modelica_metatype _inCache, modelica_metatype _inEnv, modelica_metatype _inPath, modelica_metatype _inElementLst, modelica_metatype _inBoolean, modelica_metatype *out_outValue)
{
modelica_integer tmp1;
modelica_metatype _outCache = NULL;
tmp1 = mmc_unbox_integer(_inBoolean);
_outCache = omc_DAEUtil_daeToRecordValue(threadData, _inCache, _inEnv, _inPath, _inElementLst, tmp1, out_outValue);
return _outCache;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getStreamVariables2(threadData_t *threadData, modelica_metatype _inExpComponentRefLst, modelica_string _inIdent)
{
modelica_metatype _outExpComponentRefLst = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_string tmp3_2;
tmp3_1 = _inExpComponentRefLst;
tmp3_2 = _inIdent;
{
modelica_string _id = NULL;
modelica_metatype _res = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _cr_1 = NULL;
modelica_metatype _cr = NULL;
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
_cr = tmpMeta[1];
_xs = tmpMeta[2];
_id = tmp3_2;
_res = omc_DAEUtil_getStreamVariables2(threadData, _xs, _id);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_cr_1 = omc_ComponentReference_makeCrefQual(threadData, _id, _OMC_LIT24, tmpMeta[1], _cr);
tmpMeta[1] = mmc_mk_cons(_cr_1, _res);
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
_outExpComponentRefLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExpComponentRefLst;
}
DLLExport
modelica_metatype omc_DAEUtil_getStreamVariables(threadData_t *threadData, modelica_metatype _inElementLst)
{
modelica_metatype _outExpComponentRefLst = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inElementLst;
{
modelica_metatype _res = NULL;
modelica_metatype _res1 = NULL;
modelica_metatype _res1_1 = NULL;
modelica_metatype _res2 = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _lst = NULL;
modelica_string _id = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmp3 += 3;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,13) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],2,1) == 0) goto tmp2_end;
_cr = tmpMeta[3];
_xs = tmpMeta[2];
tmp3 += 1;
_res = omc_DAEUtil_getStreamVariables(threadData, _xs);
tmpMeta[1] = mmc_mk_cons(_cr, _res);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],17,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_id = tmpMeta[3];
_lst = tmpMeta[4];
_xs = tmpMeta[2];
_res1 = omc_DAEUtil_getStreamVariables(threadData, _lst);
_res1_1 = omc_DAEUtil_getStreamVariables2(threadData, _res1, _id);
_res2 = omc_DAEUtil_getStreamVariables(threadData, _xs);
tmpMeta[0] = listAppend(_res1_1, _res2);
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_xs = tmpMeta[2];
tmpMeta[0] = omc_DAEUtil_getStreamVariables(threadData, _xs);
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
_outExpComponentRefLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExpComponentRefLst;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getFlowVariables2(threadData_t *threadData, modelica_metatype _inExpComponentRefLst, modelica_string _inIdent)
{
modelica_metatype _outExpComponentRefLst = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_string tmp3_2;
tmp3_1 = _inExpComponentRefLst;
tmp3_2 = _inIdent;
{
modelica_string _id = NULL;
modelica_metatype _res = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _cr_1 = NULL;
modelica_metatype _cr = NULL;
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
_cr = tmpMeta[1];
_xs = tmpMeta[2];
_id = tmp3_2;
_res = omc_DAEUtil_getFlowVariables2(threadData, _xs, _id);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_cr_1 = omc_ComponentReference_makeCrefQual(threadData, _id, _OMC_LIT24, tmpMeta[1], _cr);
tmpMeta[1] = mmc_mk_cons(_cr_1, _res);
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
_outExpComponentRefLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExpComponentRefLst;
}
DLLExport
modelica_metatype omc_DAEUtil_getFlowVariables(threadData_t *threadData, modelica_metatype _inElementLst)
{
modelica_metatype _outExpComponentRefLst = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inElementLst;
{
modelica_metatype _res = NULL;
modelica_metatype _res1 = NULL;
modelica_metatype _res1_1 = NULL;
modelica_metatype _res2 = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _xs = NULL;
modelica_metatype _lst = NULL;
modelica_string _id = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmp3 += 3;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,13) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,0) == 0) goto tmp2_end;
_cr = tmpMeta[3];
_xs = tmpMeta[2];
tmp3 += 1;
_res = omc_DAEUtil_getFlowVariables(threadData, _xs);
tmpMeta[1] = mmc_mk_cons(_cr, _res);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],17,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_id = tmpMeta[3];
_lst = tmpMeta[4];
_xs = tmpMeta[2];
_res1 = omc_DAEUtil_getFlowVariables(threadData, _lst);
_res1_1 = omc_DAEUtil_getFlowVariables2(threadData, _res1, _id);
_res2 = omc_DAEUtil_getFlowVariables(threadData, _xs);
tmpMeta[0] = listAppend(_res1_1, _res2);
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_xs = tmpMeta[2];
tmpMeta[0] = omc_DAEUtil_getFlowVariables(threadData, _xs);
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
_outExpComponentRefLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outExpComponentRefLst;
}
DLLExport
modelica_boolean omc_DAEUtil_daeParallelismEqual(threadData_t *threadData, modelica_metatype _inParallelism1, modelica_metatype _inParallelism2)
{
modelica_boolean _equal;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _inParallelism1;
tmp4_2 = _inParallelism2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,2,0) == 0) goto tmp3_end;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_daeParallelismEqual(threadData_t *threadData, modelica_metatype _inParallelism1, modelica_metatype _inParallelism2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_DAEUtil_daeParallelismEqual(threadData, _inParallelism1, _inParallelism2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_metatype omc_DAEUtil_scodePrlToDaePrl(threadData_t *threadData, modelica_metatype _inParallelism)
{
modelica_metatype _outVarParallelism = NULL;
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
case 5: {
tmpMeta[0] = _OMC_LIT136;
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _OMC_LIT137;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT138;
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
_outVarParallelism = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outVarParallelism;
}
DLLExport
modelica_metatype omc_DAEUtil_toDaeParallelism(threadData_t *threadData, modelica_metatype _inCref, modelica_metatype _inParallelism, modelica_metatype _inState, modelica_metatype _inInfo)
{
modelica_metatype _outParallelism = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _inParallelism;
tmp3_2 = _inState;
{
modelica_string _str1 = NULL;
modelica_metatype _path = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,0) == 0) goto tmp2_end;
tmp3 += 4;
tmpMeta[0] = _OMC_LIT136;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,0) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,2) == 0) goto tmp2_end;
tmp3 += 1;
tmpMeta[0] = _OMC_LIT137;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,0) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,8,2) == 0) goto tmp2_end;
tmp3 += 1;
tmpMeta[0] = _OMC_LIT138;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,0) == 0) goto tmp2_end;
tmp3 += 1;
_path = omc_ClassInf_getStateName(threadData, _inState);
tmpMeta[1] = stringAppend(_OMC_LIT139,omc_ComponentReference_printComponentRefStr(threadData, _inCref));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT140);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_ClassInf_printStateStr(threadData, _inState));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT141);
tmpMeta[5] = stringAppend(tmpMeta[4],omc_AbsynUtil_pathString(threadData, _path, _OMC_LIT29, 1, 0));
_str1 = tmpMeta[5];
tmpMeta[1] = mmc_mk_cons(_str1, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT145, tmpMeta[1], _inInfo);
tmpMeta[0] = _OMC_LIT137;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,0) == 0) goto tmp2_end;
_path = omc_ClassInf_getStateName(threadData, _inState);
tmpMeta[1] = stringAppend(_OMC_LIT146,omc_ComponentReference_printComponentRefStr(threadData, _inCref));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT140);
tmpMeta[3] = stringAppend(tmpMeta[2],omc_ClassInf_printStateStr(threadData, _inState));
tmpMeta[4] = stringAppend(tmpMeta[3],_OMC_LIT141);
tmpMeta[5] = stringAppend(tmpMeta[4],omc_AbsynUtil_pathString(threadData, _path, _OMC_LIT29, 1, 0));
_str1 = tmpMeta[5];
tmpMeta[1] = mmc_mk_cons(_str1, MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addSourceMessage(threadData, _OMC_LIT145, tmpMeta[1], _inInfo);
tmpMeta[0] = _OMC_LIT138;
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
_outParallelism = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outParallelism;
}
DLLExport
modelica_metatype omc_DAEUtil_toConnectorTypeNoState(threadData_t *threadData, modelica_metatype _scodeConnectorType, modelica_metatype _flowName)
{
modelica_metatype _daeConnectorType = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _scodeConnectorType;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 4: {
tmpMeta[0] = _OMC_LIT147;
goto tmp2_done;
}
case 5: {
tmpMeta[1] = mmc_mk_box2(5, &DAE_ConnectorType_STREAM__desc, _flowName);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _OMC_LIT148;
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
_daeConnectorType = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _daeConnectorType;
}
DLLExport
modelica_metatype omc_DAEUtil_toConnectorType(threadData_t *threadData, modelica_metatype _inConnectorType, modelica_metatype _inState)
{
modelica_metatype _outConnectorType = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _inConnectorType;
tmp3_2 = _inState;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT147;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT149;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,5,2) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT148;
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _OMC_LIT17;
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
_outConnectorType = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outConnectorType;
}
DLLExport
modelica_metatype omc_DAEUtil_getBindings(threadData_t *threadData, modelica_metatype _inElementLst, modelica_metatype *out_oute)
{
modelica_metatype _outc = NULL;
modelica_metatype _oute = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inElementLst;
{
modelica_metatype _cr = NULL;
modelica_metatype _e = NULL;
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
if (!listEmpty(tmp4_1)) goto tmp3_end;
tmp4 += 2;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = tmpMeta[3];
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,13) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
if (optionNone(tmpMeta[5])) goto tmp3_end;
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 1));
_cr = tmpMeta[4];
_e = tmpMeta[6];
_rest = tmpMeta[3];
tmp4 += 1;
_outc = omc_DAEUtil_getBindings(threadData, _rest ,&_oute);
tmpMeta[2] = mmc_mk_cons(_cr, _outc);
tmpMeta[3] = mmc_mk_cons(_e, _oute);
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = tmpMeta[3];
goto tmp3_done;
}
case 2: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_1);
tmpMeta[3] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,13) == 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
if (!optionNone(tmpMeta[4])) goto tmp3_end;
_rest = tmpMeta[3];
tmpMeta[0+0] = omc_DAEUtil_getBindings(threadData, _rest, &tmpMeta[0+1]);
goto tmp3_done;
}
case 3: {
fputs(MMC_STRINGDATA(_OMC_LIT150),stdout);
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
_outc = tmpMeta[0+0];
_oute = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_oute) { *out_oute = _oute; }
return _outc;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_DAEUtil_getBindingsStr(threadData_t *threadData, modelica_metatype _inElementLst)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElementLst;
{
modelica_string _expstr = NULL;
modelica_string _s3 = NULL;
modelica_string _s4 = NULL;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _lst = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,13) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
if (optionNone(tmpMeta[2])) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
if (listEmpty(tmpMeta[1])) goto tmp3_end;
tmpMeta[4] = MMC_CAR(tmpMeta[1]);
tmpMeta[5] = MMC_CDR(tmpMeta[1]);
_e = tmpMeta[3];
_lst = tmpMeta[1];
_expstr = omc_ExpressionDump_printExpStr(threadData, _e);
tmpMeta[0] = stringAppend(_expstr,_OMC_LIT151);
_s3 = tmpMeta[0];
_s4 = omc_DAEUtil_getBindingsStr(threadData, _lst);
tmpMeta[0] = stringAppend(_s3,_s4);
tmp1 = tmpMeta[0];
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,13) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
if (!optionNone(tmpMeta[2])) goto tmp3_end;
if (listEmpty(tmpMeta[1])) goto tmp3_end;
tmpMeta[3] = MMC_CAR(tmpMeta[1]);
tmpMeta[4] = MMC_CDR(tmpMeta[1]);
_lst = tmpMeta[1];
_s1 = _OMC_LIT152;
_s2 = omc_DAEUtil_getBindingsStr(threadData, _lst);
tmpMeta[0] = stringAppend(_s1,_s2);
tmp1 = tmpMeta[0];
goto tmp3_done;
}
case 2: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,13) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
if (optionNone(tmpMeta[2])) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
if (!listEmpty(tmpMeta[1])) goto tmp3_end;
_e = tmpMeta[3];
tmp1 = omc_ExpressionDump_printExpStr(threadData, _e);
goto tmp3_done;
}
case 3: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,13) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
if (!optionNone(tmpMeta[2])) goto tmp3_end;
if (!listEmpty(tmpMeta[1])) goto tmp3_end;
tmp1 = _OMC_LIT7;
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype omc_DAEUtil_getVariableType(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype _outType = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
modelica_metatype _tp = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
_tp = tmpMeta[1];
tmpMeta[0] = _tp;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_getVariableList(threadData_t *threadData, modelica_metatype _inElementLst)
{
modelica_metatype _outElementLst = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp1;
modelica_metatype __omcQ_24tmpVar6;
int tmp2;
modelica_metatype _e_loopVar = 0;
modelica_boolean tmp3 = 0;
modelica_metatype _e;
_e_loopVar = _inElementLst;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta[1];
tmp1 = &__omcQ_24tmpVar7;
while(1) {
tmp2 = 1;
while (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
{
modelica_metatype tmp6_1;
tmp6_1 = _e;
{
volatile mmc_switch_type tmp6;
int tmp7;
tmp6 = 0;
for (; tmp6 < 3; tmp6++) {
switch (MMC_SWITCH_CAST(tmp6)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,13) == 0) goto tmp5_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp6_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,3) == 0) goto tmp5_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],3,1) == 0) goto tmp5_end;
tmp3 = 0;
goto tmp5_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp6_1,0,13) == 0) goto tmp5_end;
tmp3 = 1;
goto tmp5_done;
}
case 2: {
tmp3 = 0;
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
if (tmp3) {
tmp2--;
break;
}
}
if (tmp2 == 0) {
__omcQ_24tmpVar6 = _e;
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
_outElementLst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElementLst;
}
DLLExport
modelica_string omc_DAEUtil_getVariableBindingsStr(threadData_t *threadData, modelica_metatype _elts)
{
modelica_string _str = NULL;
modelica_metatype _varlst = NULL;
modelica_metatype _els = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _elts;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (listEmpty(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_CAR(tmp4_1);
tmpMeta[1] = MMC_CDR(tmp4_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],17,4) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (!listEmpty(tmpMeta[1])) goto tmp3_end;
_els = tmpMeta[2];
_elts = _els;
goto _tailrecursive;
goto tmp3_done;
}
case 1: {
_varlst = omc_DAEUtil_getVariableList(threadData, _elts);
tmp1 = omc_DAEUtil_getBindingsStr(threadData, _varlst);
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype omc_DAEUtil_findElement(threadData_t *threadData, modelica_metatype _inElementLst, modelica_fnptr _inFuncTypeElementTo)
{
modelica_metatype _outElementOption = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_fnptr tmp3_2;
tmp3_1 = _inElementLst;
tmp3_2 = ((modelica_fnptr) _inFuncTypeElementTo);
{
modelica_metatype _e = NULL;
modelica_metatype _rest = NULL;
modelica_fnptr _f;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[0] = mmc_mk_none();
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_e = tmpMeta[1];
_rest = tmpMeta[2];
_f = tmp3_2;
{
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp6_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp7 < 2; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_f), 2))) ? ((void(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_f), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_f), 2))), _e) : ((void(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_f), 1)))) (threadData, _e);
tmpMeta[1] = mmc_mk_some(_e);
goto tmp6_done;
}
case 1: {
modelica_boolean tmp9;
tmp9 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_f), 2))) ? ((void(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_f), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_f), 2))), _e) : ((void(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_f), 1)))) (threadData, _e);
tmp9 = 1;
goto goto_10;
goto_10:;
MMC_CATCH_INTERNAL(mmc_jumper)
if (tmp9) {goto goto_5;}
tmpMeta[1] = omc_DAEUtil_findElement(threadData, _rest, ((modelica_fnptr) _f));
goto tmp6_done;
}
}
goto tmp6_end;
tmp6_end: ;
}
goto goto_5;
tmp6_done:
(void)tmp7;
MMC_RESTORE_INTERNAL(mmc_jumper);
goto tmp6_done2;
goto_5:;
MMC_CATCH_INTERNAL(mmc_jumper);
if (++tmp7 < 2) {
goto tmp6_top;
}
goto goto_1;
tmp6_done2:;
}
}tmpMeta[0] = tmpMeta[1];
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
_outElementOption = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElementOption;
}
DLLExport
modelica_boolean omc_DAEUtil_isFunctionInlineFalse(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _res;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,10) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],4,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_isFunctionInlineFalse(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _res;
modelica_metatype out_res;
_res = omc_DAEUtil_isFunctionInlineFalse(threadData, _inElement);
out_res = mmc_mk_icon(_res);
return out_res;
}
DLLExport
modelica_boolean omc_DAEUtil_isComplexEquation(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,3) == 0) goto tmp3_end;
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
_outMatch = tmp1;
_return: OMC_LABEL_UNUSED
return _outMatch;
}
modelica_metatype boxptr_DAEUtil_isComplexEquation(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
modelica_metatype out_outMatch;
_outMatch = omc_DAEUtil_isComplexEquation(threadData, _inElement);
out_outMatch = mmc_mk_icon(_outMatch);
return out_outMatch;
}
DLLExport
modelica_boolean omc_DAEUtil_isStmtTerminate(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _stmt;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,2) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_isStmtTerminate(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_isStmtTerminate(threadData, _stmt);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_DAEUtil_isStmtReinit(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _stmt;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,3) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_isStmtReinit(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_isStmtReinit(threadData, _stmt);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_DAEUtil_isStmtReturn(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _stmt;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,12,1) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_isStmtReturn(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_isStmtReturn(threadData, _stmt);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_DAEUtil_isStmtAssert(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _stmt;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,8,4) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_isStmtAssert(threadData_t *threadData, modelica_metatype _stmt)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_isStmtAssert(threadData, _stmt);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_DAEUtil_isAlgorithm(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,15,2) == 0) goto tmp3_end;
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
_outMatch = tmp1;
_return: OMC_LABEL_UNUSED
return _outMatch;
}
modelica_metatype boxptr_DAEUtil_isAlgorithm(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
modelica_metatype out_outMatch;
_outMatch = omc_DAEUtil_isAlgorithm(threadData, _inElement);
out_outMatch = mmc_mk_icon(_outMatch);
return out_outMatch;
}
DLLExport
modelica_boolean omc_DAEUtil_isComment(threadData_t *threadData, modelica_metatype _elt)
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,30,1) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_isComment(threadData_t *threadData, modelica_metatype _elt)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_isComment(threadData, _elt);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_DAEUtil_isFunctionRefVar(threadData_t *threadData, modelica_metatype _inElem)
{
modelica_boolean _outBoolean;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElem;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 7));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],11,4) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_isFunctionRefVar(threadData_t *threadData, modelica_metatype _inElem)
{
modelica_boolean _outBoolean;
modelica_metatype out_outBoolean;
_outBoolean = omc_DAEUtil_isFunctionRefVar(threadData, _inElem);
out_outBoolean = mmc_mk_icon(_outBoolean);
return out_outBoolean;
}
DLLExport
modelica_boolean omc_DAEUtil_isVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
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
_outMatch = tmp1;
_return: OMC_LABEL_UNUSED
return _outMatch;
}
modelica_metatype boxptr_DAEUtil_isVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
modelica_metatype out_outMatch;
_outMatch = omc_DAEUtil_isVar(threadData, _inElement);
out_outMatch = mmc_mk_icon(_outMatch);
return out_outMatch;
}
DLLExport
modelica_boolean omc_DAEUtil_isNotVar(threadData_t *threadData, modelica_metatype _e)
{
modelica_boolean _outMatch;
modelica_boolean tmp1 = 0;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
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
_outMatch = tmp1;
_return: OMC_LABEL_UNUSED
return _outMatch;
}
modelica_metatype boxptr_DAEUtil_isNotVar(threadData_t *threadData, modelica_metatype _e)
{
modelica_boolean _outMatch;
modelica_metatype out_outMatch;
_outMatch = omc_DAEUtil_isNotVar(threadData, _e);
out_outMatch = mmc_mk_icon(_outMatch);
return out_outMatch;
}
DLLExport
modelica_boolean omc_DAEUtil_isInput(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
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
_outMatch = tmp1;
_return: OMC_LABEL_UNUSED
return _outMatch;
}
modelica_metatype boxptr_DAEUtil_isInput(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
modelica_metatype out_outMatch;
_outMatch = omc_DAEUtil_isInput(threadData, _inElement);
out_outMatch = mmc_mk_icon(_outMatch);
return out_outMatch;
}
DLLExport
modelica_boolean omc_DAEUtil_isInputVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
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
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,0) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,0) == 0) goto tmp3_end;
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
_outMatch = tmp1;
_return: OMC_LABEL_UNUSED
return _outMatch;
}
modelica_metatype boxptr_DAEUtil_isInputVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
modelica_metatype out_outMatch;
_outMatch = omc_DAEUtil_isInputVar(threadData, _inElement);
out_outMatch = mmc_mk_icon(_outMatch);
return out_outMatch;
}
DLLExport
modelica_boolean omc_DAEUtil_isBidirVarDirection(threadData_t *threadData, modelica_metatype _inVarDirection)
{
modelica_boolean _outIsBidir;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVarDirection;
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
_outIsBidir = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsBidir;
}
modelica_metatype boxptr_DAEUtil_isBidirVarDirection(threadData_t *threadData, modelica_metatype _inVarDirection)
{
modelica_boolean _outIsBidir;
modelica_metatype out_outIsBidir;
_outIsBidir = omc_DAEUtil_isBidirVarDirection(threadData, _inVarDirection);
out_outIsBidir = mmc_mk_icon(_outIsBidir);
return out_outIsBidir;
}
DLLExport
modelica_boolean omc_DAEUtil_isBidirVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
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
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,0) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,0) == 0) goto tmp3_end;
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
_outMatch = tmp1;
_return: OMC_LABEL_UNUSED
return _outMatch;
}
modelica_metatype boxptr_DAEUtil_isBidirVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
modelica_metatype out_outMatch;
_outMatch = omc_DAEUtil_isBidirVar(threadData, _inElement);
out_outMatch = mmc_mk_icon(_outMatch);
return out_outMatch;
}
DLLExport
modelica_boolean omc_DAEUtil_isPublicVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
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
_outMatch = tmp1;
_return: OMC_LABEL_UNUSED
return _outMatch;
}
modelica_metatype boxptr_DAEUtil_isPublicVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
modelica_metatype out_outMatch;
_outMatch = omc_DAEUtil_isPublicVar(threadData, _inElement);
out_outMatch = mmc_mk_icon(_outMatch);
return out_outMatch;
}
DLLExport
modelica_boolean omc_DAEUtil_isProtectedVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _b;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 6));
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
modelica_metatype boxptr_DAEUtil_isProtectedVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_isProtectedVar(threadData, _inElement);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
void omc_DAEUtil_assertProtectedVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,0) == 0) goto tmp2_end;
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
modelica_boolean omc_DAEUtil_isOutputVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
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
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,0) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,0) == 0) goto tmp3_end;
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
_outMatch = tmp1;
_return: OMC_LABEL_UNUSED
return _outMatch;
}
modelica_metatype boxptr_DAEUtil_isOutputVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outMatch;
modelica_metatype out_outMatch;
_outMatch = omc_DAEUtil_isOutputVar(threadData, _inElement);
out_outMatch = mmc_mk_icon(_outMatch);
return out_outMatch;
}
DLLExport
modelica_boolean omc_DAEUtil_isStream(threadData_t *threadData, modelica_metatype _inStream)
{
modelica_boolean _outIsStream;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
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
_outIsStream = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsStream;
}
modelica_metatype boxptr_DAEUtil_isStream(threadData_t *threadData, modelica_metatype _inStream)
{
modelica_boolean _outIsStream;
modelica_metatype out_outIsStream;
_outIsStream = omc_DAEUtil_isStream(threadData, _inStream);
out_outIsStream = mmc_mk_icon(_outIsStream);
return out_outIsStream;
}
DLLExport
modelica_boolean omc_DAEUtil_isFlow(threadData_t *threadData, modelica_metatype _inFlow)
{
modelica_boolean _outIsFlow;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inFlow;
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
_outIsFlow = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsFlow;
}
modelica_metatype boxptr_DAEUtil_isFlow(threadData_t *threadData, modelica_metatype _inFlow)
{
modelica_boolean _outIsFlow;
modelica_metatype out_outIsFlow;
_outIsFlow = omc_DAEUtil_isFlow(threadData, _inFlow);
out_outIsFlow = mmc_mk_icon(_outIsFlow);
return out_outIsFlow;
}
DLLExport
void omc_DAEUtil_isStreamVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inElement;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,0) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 10));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
void omc_DAEUtil_isFlowVar(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inElement;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,0) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 10));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,0) == 0) MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_DAEUtil_getInputVars(threadData_t *threadData, modelica_metatype _vl)
{
modelica_metatype _vl_1 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_vl_1 = omc_DAEUtil_getMatchingElements(threadData, _vl, boxvar_DAEUtil_isInput);
_return: OMC_LABEL_UNUSED
return _vl_1;
}
DLLExport
modelica_metatype omc_DAEUtil_getBidirVars(threadData_t *threadData, modelica_metatype _vl)
{
modelica_metatype _vl_1 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_vl_1 = omc_DAEUtil_getMatchingElements(threadData, _vl, boxvar_DAEUtil_isBidirVar);
_return: OMC_LABEL_UNUSED
return _vl_1;
}
DLLExport
modelica_metatype omc_DAEUtil_getProtectedVars(threadData_t *threadData, modelica_metatype _vl)
{
modelica_metatype _vl_1 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_vl_1 = omc_DAEUtil_getMatchingElements(threadData, _vl, boxvar_DAEUtil_isProtectedVar);
_return: OMC_LABEL_UNUSED
return _vl_1;
}
DLLExport
modelica_metatype omc_DAEUtil_getOutputVars(threadData_t *threadData, modelica_metatype _vl)
{
modelica_metatype _vl_1 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_vl_1 = omc_DAEUtil_getMatchingElements(threadData, _vl, boxvar_DAEUtil_isOutputVar);
_return: OMC_LABEL_UNUSED
return _vl_1;
}
DLLExport
void omc_DAEUtil_isComp(threadData_t *threadData, modelica_metatype _inElement)
{
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inElement;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,4) == 0) goto tmp2_end;
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
modelica_boolean omc_DAEUtil_isOuterVar(threadData_t *threadData, modelica_metatype _element)
{
modelica_boolean _isOuter;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 14));
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
_isOuter = tmp1;
_return: OMC_LABEL_UNUSED
return _isOuter;
}
modelica_metatype boxptr_DAEUtil_isOuterVar(threadData_t *threadData, modelica_metatype _element)
{
modelica_boolean _isOuter;
modelica_metatype out_isOuter;
_isOuter = omc_DAEUtil_isOuterVar(threadData, _element);
out_isOuter = mmc_mk_icon(_isOuter);
return out_isOuter;
}
DLLExport
modelica_boolean omc_DAEUtil_isInnerVar(threadData_t *threadData, modelica_metatype _element)
{
modelica_boolean _isInner;
modelica_boolean tmp1 = 0;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmp1 = omc_AbsynUtil_isInner(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 14))));
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
_isInner = tmp1;
_return: OMC_LABEL_UNUSED
return _isInner;
}
modelica_metatype boxptr_DAEUtil_isInnerVar(threadData_t *threadData, modelica_metatype _element)
{
modelica_boolean _isInner;
modelica_metatype out_isInner;
_isInner = omc_DAEUtil_isInnerVar(threadData, _element);
out_isInner = mmc_mk_icon(_isInner);
return out_isInner;
}
DLLExport
modelica_boolean omc_DAEUtil_isParamOrConstVarKind(threadData_t *threadData, modelica_metatype _inVarKind)
{
modelica_boolean _outIsParamOrConst;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVarKind;
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
_outIsParamOrConst = tmp1;
_return: OMC_LABEL_UNUSED
return _outIsParamOrConst;
}
modelica_metatype boxptr_DAEUtil_isParamOrConstVarKind(threadData_t *threadData, modelica_metatype _inVarKind)
{
modelica_boolean _outIsParamOrConst;
modelica_metatype out_outIsParamOrConst;
_outIsParamOrConst = omc_DAEUtil_isParamOrConstVarKind(threadData, _inVarKind);
out_outIsParamOrConst = mmc_mk_icon(_outIsParamOrConst);
return out_outIsParamOrConst;
}
DLLExport
modelica_boolean omc_DAEUtil_isParamConstOrComplexVar(threadData_t *threadData, modelica_metatype _inVar)
{
modelica_boolean _outIsParamConstComplex;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIsParamConstComplex = (omc_DAEUtil_isParamOrConstVar(threadData, _inVar) || omc_DAEUtil_isComplexVar(threadData, _inVar));
_return: OMC_LABEL_UNUSED
return _outIsParamConstComplex;
}
modelica_metatype boxptr_DAEUtil_isParamConstOrComplexVar(threadData_t *threadData, modelica_metatype _inVar)
{
modelica_boolean _outIsParamConstComplex;
modelica_metatype out_outIsParamConstComplex;
_outIsParamConstComplex = omc_DAEUtil_isParamConstOrComplexVar(threadData, _inVar);
out_outIsParamConstComplex = mmc_mk_icon(_outIsParamConstComplex);
return out_outIsParamConstComplex;
}
DLLExport
modelica_boolean omc_DAEUtil_isNotParamOrConstVar(threadData_t *threadData, modelica_metatype _inVar)
{
modelica_boolean _outIsNotParamOrConst;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outIsNotParamOrConst = (!omc_DAEUtil_isParamOrConstVar(threadData, _inVar));
_return: OMC_LABEL_UNUSED
return _outIsNotParamOrConst;
}
modelica_metatype boxptr_DAEUtil_isNotParamOrConstVar(threadData_t *threadData, modelica_metatype _inVar)
{
modelica_boolean _outIsNotParamOrConst;
modelica_metatype out_outIsNotParamOrConst;
_outIsNotParamOrConst = omc_DAEUtil_isNotParamOrConstVar(threadData, _inVar);
out_outIsNotParamOrConst = mmc_mk_icon(_outIsNotParamOrConst);
return out_outIsNotParamOrConst;
}
DLLExport
modelica_boolean omc_DAEUtil_isParamOrConstVar(threadData_t *threadData, modelica_metatype _inVar)
{
modelica_boolean _outIsParamOrConst;
modelica_metatype _var = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inVar;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_var = tmpMeta[2];
_outIsParamOrConst = omc_SCodeUtil_isParameterOrConst(threadData, _var);
_return: OMC_LABEL_UNUSED
return _outIsParamOrConst;
}
modelica_metatype boxptr_DAEUtil_isParamOrConstVar(threadData_t *threadData, modelica_metatype _inVar)
{
modelica_boolean _outIsParamOrConst;
modelica_metatype out_outIsParamOrConst;
_outIsParamOrConst = omc_DAEUtil_isParamOrConstVar(threadData, _inVar);
out_outIsParamOrConst = mmc_mk_icon(_outIsParamOrConst);
return out_outIsParamOrConst;
}
DLLExport
modelica_boolean omc_DAEUtil_isParameterOrConstant(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _b;
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
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,0) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_isParameterOrConstant(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_isParameterOrConstant(threadData, _inElement);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_boolean omc_DAEUtil_isParameter(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outB;
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
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,0) == 0) goto tmp3_end;
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
_outB = tmp1;
_return: OMC_LABEL_UNUSED
return _outB;
}
modelica_metatype boxptr_DAEUtil_isParameter(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_boolean _outB;
modelica_metatype out_outB;
_outB = omc_DAEUtil_isParameter(threadData, _inElement);
out_outB = mmc_mk_icon(_outB);
return out_outB;
}
DLLExport
modelica_boolean omc_DAEUtil_isAfterIndexInlineFunc(threadData_t *threadData, modelica_metatype _inElem)
{
modelica_boolean _b;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inElem;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,10) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 8));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],5,0) == 0) goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_isAfterIndexInlineFunc(threadData_t *threadData, modelica_metatype _inElem)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_isAfterIndexInlineFunc(threadData, _inElem);
out_b = mmc_mk_icon(_b);
return out_b;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_findAllMatchingElements2(threadData_t *threadData, modelica_metatype _elements, modelica_fnptr _cond1, modelica_fnptr _cond2, modelica_metatype _accumFirst, modelica_metatype _accumSecond, modelica_metatype *out_secondList)
{
modelica_metatype _firstList = NULL;
modelica_metatype _secondList = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_firstList = _accumFirst;
_secondList = _accumSecond;
{
modelica_metatype _e;
for (tmpMeta[0] = _elements; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_e = MMC_CAR(tmpMeta[0]);
{
modelica_metatype tmp3_1;
tmp3_1 = _e;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,4) == 0) goto tmp2_end;
_firstList = omc_DAEUtil_findAllMatchingElements2(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 3))), ((modelica_fnptr) _cond1), ((modelica_fnptr) _cond2), _firstList, _secondList ,&_secondList);
goto tmp2_done;
}
case 1: {
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond1), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond1), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond1), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond1), 1)))) (threadData, _e)))
{
tmpMeta[1] = mmc_mk_cons(_e, _firstList);
_firstList = tmpMeta[1];
}
if(mmc_unbox_boolean((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond2), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond2), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond2), 2))), _e) : ((modelica_metatype(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond2), 1)))) (threadData, _e)))
{
tmpMeta[1] = mmc_mk_cons(_e, _secondList);
_secondList = tmpMeta[1];
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
}
}
_return: OMC_LABEL_UNUSED
if (out_secondList) { *out_secondList = _secondList; }
return _firstList;
}
DLLExport
modelica_metatype omc_DAEUtil_findAllMatchingElements(threadData_t *threadData, modelica_metatype _dae, modelica_fnptr _cond1, modelica_fnptr _cond2, modelica_metatype *out_secondList)
{
modelica_metatype _firstList = NULL;
modelica_metatype _secondList = NULL;
modelica_metatype _elements = NULL;
modelica_metatype _el1 = NULL;
modelica_metatype _el2 = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _dae;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_elements = tmpMeta[1];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_el1 = omc_DAEUtil_findAllMatchingElements2(threadData, _elements, ((modelica_fnptr) _cond1), ((modelica_fnptr) _cond2), tmpMeta[0], tmpMeta[1] ,&_el2);
tmpMeta[0] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, listReverseInPlace(_el1));
_firstList = tmpMeta[0];
tmpMeta[0] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, listReverseInPlace(_el2));
_secondList = tmpMeta[0];
_return: OMC_LABEL_UNUSED
if (out_secondList) { *out_secondList = _secondList; }
return _firstList;
}
DLLExport
modelica_metatype omc_DAEUtil_getAllMatchingElements(threadData_t *threadData, modelica_metatype _elist, modelica_fnptr _cond)
{
modelica_metatype _outElist = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _elist;
{
modelica_metatype _elist1 = NULL;
modelica_metatype _elist2 = NULL;
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmp3 += 3;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],17,4) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
_elist1 = tmpMeta[3];
_elist2 = tmpMeta[2];
_elist1 = omc_DAEUtil_getAllMatchingElements(threadData, _elist1, ((modelica_fnptr) _cond));
_elist2 = omc_DAEUtil_getAllMatchingElements(threadData, _elist2, ((modelica_fnptr) _cond));
tmpMeta[0] = listAppend(_elist1, _elist2);
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_e = tmpMeta[1];
_elist2 = tmpMeta[2];
(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond), 2))) ? ((void(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond), 2))), _e) : ((void(*)(threadData_t*, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cond), 1)))) (threadData, _e);
_elist2 = omc_DAEUtil_getAllMatchingElements(threadData, _elist2, ((modelica_fnptr) _cond));
tmpMeta[1] = mmc_mk_cons(_e, _elist2);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_elist2 = tmpMeta[2];
tmpMeta[0] = omc_DAEUtil_getAllMatchingElements(threadData, _elist2, ((modelica_fnptr) _cond));
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
_outElist = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outElist;
}
DLLExport
modelica_metatype omc_DAEUtil_getMatchingElements(threadData_t *threadData, modelica_metatype _elist, modelica_fnptr _cond)
{
modelica_metatype _oelist = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_oelist = omc_List_filterOnTrue(threadData, _elist, ((modelica_fnptr) _cond));
_return: OMC_LABEL_UNUSED
return _oelist;
}
DLLExport
modelica_string omc_DAEUtil_getStartAttrString(threadData_t *threadData, modelica_metatype _inVariableAttributesOption)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp4_1;
tmp4_1 = _inVariableAttributesOption;
{
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp3_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmp4 += 2;
tmp1 = _OMC_LIT7;
goto tmp3_done;
}
case 1: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,15) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_r = tmpMeta[2];
tmp4 += 1;
tmp1 = omc_ExpressionDump_printExpStr(threadData, _r);
goto tmp3_done;
}
case 2: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,11) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_r = tmpMeta[2];
tmp1 = omc_ExpressionDump_printExpStr(threadData, _r);
goto tmp3_done;
}
case 3: {
tmp1 = _OMC_LIT7;
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
_outString = tmp1;
_return: OMC_LABEL_UNUSED
return _outString;
}
DLLExport
modelica_boolean omc_DAEUtil_hasStartAttr(threadData_t *threadData, modelica_metatype _inVariableAttributesOption)
{
modelica_boolean _hasStart;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVariableAttributesOption;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,15) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,11) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,7) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp1 = 1;
goto tmp3_done;
}
case 3: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],4,7) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
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
_hasStart = tmp1;
_return: OMC_LABEL_UNUSED
return _hasStart;
}
modelica_metatype boxptr_DAEUtil_hasStartAttr(threadData_t *threadData, modelica_metatype _inVariableAttributesOption)
{
modelica_boolean _hasStart;
modelica_metatype out_hasStart;
_hasStart = omc_DAEUtil_hasStartAttr(threadData, _inVariableAttributesOption);
out_hasStart = mmc_mk_icon(_hasStart);
return out_hasStart;
}
DLLExport
modelica_boolean omc_DAEUtil_boolVarVisibility(threadData_t *threadData, modelica_metatype _vp)
{
modelica_boolean _prot;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _vp;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = 0;
goto tmp3_done;
}
case 4: {
tmp1 = 1;
goto tmp3_done;
}
default:
tmp3_default: OMC_LABEL_UNUSED; {
fputs(MMC_STRINGDATA(_OMC_LIT153),stdout);
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
_prot = tmp1;
_return: OMC_LABEL_UNUSED
return _prot;
}
modelica_metatype boxptr_DAEUtil_boolVarVisibility(threadData_t *threadData, modelica_metatype _vp)
{
modelica_boolean _prot;
modelica_metatype out_prot;
_prot = omc_DAEUtil_boolVarVisibility(threadData, _vp);
out_prot = mmc_mk_icon(_prot);
return out_prot;
}
DLLExport
modelica_boolean omc_DAEUtil_getFinalAttr(threadData_t *threadData, modelica_metatype _attr)
{
modelica_boolean _finalPrefix;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _attr;
{
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,15) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 15));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
_b = tmp6;
tmp1 = _b;
goto tmp3_done;
}
case 1: {
modelica_integer tmp7;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,11) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 11));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp7 = mmc_unbox_integer(tmpMeta[2]);
_b = tmp7;
tmp1 = _b;
goto tmp3_done;
}
case 2: {
modelica_integer tmp8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,7) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp8 = mmc_unbox_integer(tmpMeta[2]);
_b = tmp8;
tmp1 = _b;
goto tmp3_done;
}
case 3: {
modelica_integer tmp9;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],4,7) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 7));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp9 = mmc_unbox_integer(tmpMeta[2]);
_b = tmp9;
tmp1 = _b;
goto tmp3_done;
}
case 4: {
modelica_integer tmp10;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],5,9) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 9));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp10 = mmc_unbox_integer(tmpMeta[2]);
_b = tmp10;
tmp1 = _b;
goto tmp3_done;
}
case 5: {
modelica_integer tmp11;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,2) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp11 = mmc_unbox_integer(tmpMeta[2]);
_b = tmp11;
tmp1 = _b;
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
_finalPrefix = tmp1;
_return: OMC_LABEL_UNUSED
return _finalPrefix;
}
modelica_metatype boxptr_DAEUtil_getFinalAttr(threadData_t *threadData, modelica_metatype _attr)
{
modelica_boolean _finalPrefix;
modelica_metatype out_finalPrefix;
_finalPrefix = omc_DAEUtil_getFinalAttr(threadData, _attr);
out_finalPrefix = mmc_mk_icon(_finalPrefix);
return out_finalPrefix;
}
DLLExport
modelica_metatype omc_DAEUtil_setFinalAttr(threadData_t *threadData, modelica_metatype _attr, modelica_boolean _finalPrefix)
{
modelica_metatype _outAttr = NULL;
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_metatype _q = NULL;
modelica_metatype _u = NULL;
modelica_metatype _du = NULL;
modelica_metatype _i = NULL;
modelica_metatype _f = NULL;
modelica_metatype _n = NULL;
modelica_metatype _so = NULL;
modelica_metatype _min = NULL;
modelica_metatype _max = NULL;
modelica_metatype _ss = NULL;
modelica_metatype _unc = NULL;
modelica_metatype _distOpt = NULL;
modelica_metatype _eb = NULL;
modelica_metatype _ip = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 7; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 13));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 14));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 16));
_q = tmpMeta[2];
_u = tmpMeta[3];
_du = tmpMeta[4];
_min = tmpMeta[5];
_max = tmpMeta[6];
_i = tmpMeta[7];
_f = tmpMeta[8];
_n = tmpMeta[9];
_ss = tmpMeta[10];
_unc = tmpMeta[11];
_distOpt = tmpMeta[12];
_eb = tmpMeta[13];
_ip = tmpMeta[14];
_so = tmpMeta[15];
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, _q, _u, _du, _min, _max, _i, _f, _n, _ss, _unc, _distOpt, _eb, _ip, mmc_mk_some(mmc_mk_boolean(_finalPrefix)), _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,11) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
_q = tmpMeta[2];
_min = tmpMeta[3];
_max = tmpMeta[4];
_i = tmpMeta[5];
_f = tmpMeta[6];
_unc = tmpMeta[7];
_distOpt = tmpMeta[8];
_eb = tmpMeta[9];
_ip = tmpMeta[10];
_so = tmpMeta[11];
tmpMeta[1] = mmc_mk_box12(4, &DAE_VariableAttributes_VAR__ATTR__INT__desc, _q, _min, _max, _i, _f, _unc, _distOpt, _eb, _ip, mmc_mk_some(mmc_mk_boolean(_finalPrefix)), _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_q = tmpMeta[2];
_i = tmpMeta[3];
_f = tmpMeta[4];
_eb = tmpMeta[5];
_ip = tmpMeta[6];
_so = tmpMeta[7];
tmpMeta[1] = mmc_mk_box8(5, &DAE_VariableAttributes_VAR__ATTR__BOOL__desc, _q, _i, _f, _eb, _ip, mmc_mk_some(mmc_mk_boolean(_finalPrefix)), _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 3: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_ip = tmpMeta[2];
tmpMeta[1] = mmc_mk_box3(6, &DAE_VariableAttributes_VAR__ATTR__CLOCK__desc, _ip, mmc_mk_some(mmc_mk_boolean(_finalPrefix)));
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 4: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_q = tmpMeta[2];
_i = tmpMeta[3];
_f = tmpMeta[4];
_eb = tmpMeta[5];
_ip = tmpMeta[6];
_so = tmpMeta[7];
tmpMeta[1] = mmc_mk_box8(7, &DAE_VariableAttributes_VAR__ATTR__STRING__desc, _q, _i, _f, _eb, _ip, mmc_mk_some(mmc_mk_boolean(_finalPrefix)), _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 5: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,9) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
_q = tmpMeta[2];
_min = tmpMeta[3];
_max = tmpMeta[4];
_u = tmpMeta[5];
_du = tmpMeta[6];
_eb = tmpMeta[7];
_ip = tmpMeta[8];
_so = tmpMeta[9];
tmpMeta[1] = mmc_mk_box10(8, &DAE_VariableAttributes_VAR__ATTR__ENUMERATION__desc, _q, _min, _max, _u, _du, _eb, _ip, mmc_mk_some(mmc_mk_boolean(_finalPrefix)), _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 6: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_some(mmc_mk_boolean(_finalPrefix)), mmc_mk_none());
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
_outAttr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttr;
}
modelica_metatype boxptr_DAEUtil_setFinalAttr(threadData_t *threadData, modelica_metatype _attr, modelica_metatype _finalPrefix)
{
modelica_integer tmp1;
modelica_metatype _outAttr = NULL;
tmp1 = mmc_unbox_integer(_finalPrefix);
_outAttr = omc_DAEUtil_setFinalAttr(threadData, _attr, tmp1);
return _outAttr;
}
DLLExport
modelica_metatype omc_DAEUtil_setFixedAttr(threadData_t *threadData, modelica_metatype _attr, modelica_metatype _fixed)
{
modelica_metatype _outAttr = NULL;
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_metatype _q = NULL;
modelica_metatype _u = NULL;
modelica_metatype _du = NULL;
modelica_metatype _n = NULL;
modelica_metatype _ini = NULL;
modelica_metatype _so = NULL;
modelica_metatype _min = NULL;
modelica_metatype _max = NULL;
modelica_metatype _ss = NULL;
modelica_metatype _unc = NULL;
modelica_metatype _distOpt = NULL;
modelica_metatype _eb = NULL;
modelica_metatype _ip = NULL;
modelica_metatype _fn = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 13));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 14));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 15));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 16));
_q = tmpMeta[2];
_u = tmpMeta[3];
_du = tmpMeta[4];
_min = tmpMeta[5];
_max = tmpMeta[6];
_ini = tmpMeta[7];
_n = tmpMeta[8];
_ss = tmpMeta[9];
_unc = tmpMeta[10];
_distOpt = tmpMeta[11];
_eb = tmpMeta[12];
_ip = tmpMeta[13];
_fn = tmpMeta[14];
_so = tmpMeta[15];
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, _q, _u, _du, _min, _max, _ini, _fixed, _n, _ss, _unc, _distOpt, _eb, _ip, _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,11) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
_q = tmpMeta[2];
_min = tmpMeta[3];
_max = tmpMeta[4];
_ini = tmpMeta[5];
_unc = tmpMeta[6];
_distOpt = tmpMeta[7];
_eb = tmpMeta[8];
_ip = tmpMeta[9];
_fn = tmpMeta[10];
_so = tmpMeta[11];
tmpMeta[1] = mmc_mk_box12(4, &DAE_VariableAttributes_VAR__ATTR__INT__desc, _q, _min, _max, _ini, _fixed, _unc, _distOpt, _eb, _ip, _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_q = tmpMeta[2];
_ini = tmpMeta[3];
_eb = tmpMeta[4];
_ip = tmpMeta[5];
_fn = tmpMeta[6];
_so = tmpMeta[7];
tmpMeta[1] = mmc_mk_box8(5, &DAE_VariableAttributes_VAR__ATTR__BOOL__desc, _q, _ini, _fixed, _eb, _ip, _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 3: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_q = tmpMeta[2];
_ini = tmpMeta[3];
_eb = tmpMeta[4];
_ip = tmpMeta[5];
_fn = tmpMeta[6];
_so = tmpMeta[7];
tmpMeta[1] = mmc_mk_box8(7, &DAE_VariableAttributes_VAR__ATTR__STRING__desc, _q, _ini, _fixed, _eb, _ip, _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 4: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,9) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
_q = tmpMeta[2];
_min = tmpMeta[3];
_max = tmpMeta[4];
_u = tmpMeta[5];
_eb = tmpMeta[6];
_ip = tmpMeta[7];
_fn = tmpMeta[8];
_so = tmpMeta[9];
tmpMeta[1] = mmc_mk_box10(8, &DAE_VariableAttributes_VAR__ATTR__ENUMERATION__desc, _q, _min, _max, _u, _fixed, _eb, _ip, _fn, _so);
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
_outAttr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttr;
}
DLLExport
modelica_boolean omc_DAEUtil_getProtectedAttr(threadData_t *threadData, modelica_metatype _attr)
{
modelica_boolean _isProtected;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _attr;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 7; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,15) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 14));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
_isProtected = tmp6;
tmp1 = _isProtected;
goto tmp3_done;
}
case 1: {
modelica_integer tmp7;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,11) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 10));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp7 = mmc_unbox_integer(tmpMeta[2]);
_isProtected = tmp7;
tmp1 = _isProtected;
goto tmp3_done;
}
case 2: {
modelica_integer tmp8;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],2,7) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp8 = mmc_unbox_integer(tmpMeta[2]);
_isProtected = tmp8;
tmp1 = _isProtected;
goto tmp3_done;
}
case 3: {
modelica_integer tmp9;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],4,7) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp9 = mmc_unbox_integer(tmpMeta[2]);
_isProtected = tmp9;
tmp1 = _isProtected;
goto tmp3_done;
}
case 4: {
modelica_integer tmp10;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],5,9) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 8));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp10 = mmc_unbox_integer(tmpMeta[2]);
_isProtected = tmp10;
tmp1 = _isProtected;
goto tmp3_done;
}
case 5: {
modelica_integer tmp11;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],3,2) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (optionNone(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
tmp11 = mmc_unbox_integer(tmpMeta[2]);
_isProtected = tmp11;
tmp1 = _isProtected;
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
_isProtected = tmp1;
_return: OMC_LABEL_UNUSED
return _isProtected;
}
modelica_metatype boxptr_DAEUtil_getProtectedAttr(threadData_t *threadData, modelica_metatype _attr)
{
modelica_boolean _isProtected;
modelica_metatype out_isProtected;
_isProtected = omc_DAEUtil_getProtectedAttr(threadData, _attr);
out_isProtected = mmc_mk_icon(_isProtected);
return out_isProtected;
}
DLLExport
modelica_metatype omc_DAEUtil_setProtectedAttr(threadData_t *threadData, modelica_metatype _attr, modelica_boolean _isProtected)
{
modelica_metatype _outAttr = NULL;
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_metatype _q = NULL;
modelica_metatype _u = NULL;
modelica_metatype _du = NULL;
modelica_metatype _i = NULL;
modelica_metatype _f = NULL;
modelica_metatype _n = NULL;
modelica_metatype _so = NULL;
modelica_metatype _min = NULL;
modelica_metatype _max = NULL;
modelica_metatype _ss = NULL;
modelica_metatype _unc = NULL;
modelica_metatype _distOpt = NULL;
modelica_metatype _eb = NULL;
modelica_metatype _fn = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 7; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 13));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 15));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 16));
_q = tmpMeta[2];
_u = tmpMeta[3];
_du = tmpMeta[4];
_min = tmpMeta[5];
_max = tmpMeta[6];
_i = tmpMeta[7];
_f = tmpMeta[8];
_n = tmpMeta[9];
_ss = tmpMeta[10];
_unc = tmpMeta[11];
_distOpt = tmpMeta[12];
_eb = tmpMeta[13];
_fn = tmpMeta[14];
_so = tmpMeta[15];
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, _q, _u, _du, _min, _max, _i, _f, _n, _ss, _unc, _distOpt, _eb, mmc_mk_some(mmc_mk_boolean(_isProtected)), _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,11) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
_q = tmpMeta[2];
_min = tmpMeta[3];
_max = tmpMeta[4];
_i = tmpMeta[5];
_f = tmpMeta[6];
_unc = tmpMeta[7];
_distOpt = tmpMeta[8];
_eb = tmpMeta[9];
_fn = tmpMeta[10];
_so = tmpMeta[11];
tmpMeta[1] = mmc_mk_box12(4, &DAE_VariableAttributes_VAR__ATTR__INT__desc, _q, _min, _max, _i, _f, _unc, _distOpt, _eb, mmc_mk_some(mmc_mk_boolean(_isProtected)), _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_q = tmpMeta[2];
_i = tmpMeta[3];
_f = tmpMeta[4];
_eb = tmpMeta[5];
_fn = tmpMeta[6];
_so = tmpMeta[7];
tmpMeta[1] = mmc_mk_box8(5, &DAE_VariableAttributes_VAR__ATTR__BOOL__desc, _q, _i, _f, _eb, mmc_mk_some(mmc_mk_boolean(_isProtected)), _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 3: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_q = tmpMeta[2];
_i = tmpMeta[3];
_f = tmpMeta[4];
_eb = tmpMeta[5];
_fn = tmpMeta[6];
_so = tmpMeta[7];
tmpMeta[1] = mmc_mk_box8(7, &DAE_VariableAttributes_VAR__ATTR__STRING__desc, _q, _i, _f, _eb, mmc_mk_some(mmc_mk_boolean(_isProtected)), _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 4: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,9) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
_q = tmpMeta[2];
_min = tmpMeta[3];
_max = tmpMeta[4];
_u = tmpMeta[5];
_du = tmpMeta[6];
_eb = tmpMeta[7];
_fn = tmpMeta[8];
_so = tmpMeta[9];
tmpMeta[1] = mmc_mk_box10(8, &DAE_VariableAttributes_VAR__ATTR__ENUMERATION__desc, _q, _min, _max, _u, _du, _eb, mmc_mk_some(mmc_mk_boolean(_isProtected)), _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 5: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_fn = tmpMeta[2];
tmpMeta[1] = mmc_mk_box3(6, &DAE_VariableAttributes_VAR__ATTR__CLOCK__desc, _fn, mmc_mk_some(mmc_mk_boolean(_isProtected)));
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 6: {
if (!optionNone(tmp3_1)) goto tmp2_end;
_attr = _OMC_LIT155;
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
_outAttr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttr;
}
modelica_metatype boxptr_DAEUtil_setProtectedAttr(threadData_t *threadData, modelica_metatype _attr, modelica_metatype _isProtected)
{
modelica_integer tmp1;
modelica_metatype _outAttr = NULL;
tmp1 = mmc_unbox_integer(_isProtected);
_outAttr = omc_DAEUtil_setProtectedAttr(threadData, _attr, tmp1);
return _outAttr;
}
DLLExport
modelica_metatype omc_DAEUtil_setElementVarBinding(threadData_t *threadData, modelica_metatype _elt, modelica_metatype _binding)
{
modelica_metatype _e = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_e = _elt;
{
modelica_metatype tmp3_1;
tmp3_1 = _e;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(15));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_e), 15*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[8] = _binding;
_e = tmpMeta[1];
tmpMeta[0] = _e;
goto tmp2_done;
}
case 1: {
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
modelica_metatype omc_DAEUtil_setElementVarDirection(threadData_t *threadData, modelica_metatype _elt, modelica_metatype _direction)
{
modelica_metatype _e = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_e = _elt;
{
modelica_metatype tmp3_1;
tmp3_1 = _e;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(15));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_e), 15*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[4] = _direction;
_e = tmpMeta[1];
tmpMeta[0] = _e;
goto tmp2_done;
}
case 1: {
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
modelica_metatype omc_DAEUtil_setElementVarVisibility(threadData_t *threadData, modelica_metatype _elt, modelica_metatype _visibility)
{
modelica_metatype _e = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_e = _elt;
{
modelica_metatype tmp3_1;
tmp3_1 = _e;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(15));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_e), 15*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[6] = _visibility;
_e = tmpMeta[1];
tmpMeta[0] = _e;
goto tmp2_done;
}
case 1: {
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
modelica_metatype omc_DAEUtil_setUnitAttr(threadData_t *threadData, modelica_metatype _attr, modelica_metatype _unit)
{
modelica_metatype _outAttr = NULL;
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_metatype _q = NULL;
modelica_metatype _du = NULL;
modelica_metatype _f = NULL;
modelica_metatype _n = NULL;
modelica_metatype _s = NULL;
modelica_metatype _so = NULL;
modelica_metatype _min = NULL;
modelica_metatype _max = NULL;
modelica_metatype _ss = NULL;
modelica_metatype _unc = NULL;
modelica_metatype _distOpt = NULL;
modelica_metatype _eb = NULL;
modelica_metatype _ip = NULL;
modelica_metatype _fn = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 13));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 14));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 15));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 16));
_q = tmpMeta[2];
_du = tmpMeta[3];
_min = tmpMeta[4];
_max = tmpMeta[5];
_s = tmpMeta[6];
_f = tmpMeta[7];
_n = tmpMeta[8];
_ss = tmpMeta[9];
_unc = tmpMeta[10];
_distOpt = tmpMeta[11];
_eb = tmpMeta[12];
_ip = tmpMeta[13];
_fn = tmpMeta[14];
_so = tmpMeta[15];
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, _q, mmc_mk_some(_unit), _du, _min, _max, _s, _f, _n, _ss, _unc, _distOpt, _eb, _ip, _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 1: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, mmc_mk_none(), mmc_mk_some(_unit), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none());
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
_outAttr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttr;
}
DLLExport
modelica_metatype omc_DAEUtil_setNominalAttr(threadData_t *threadData, modelica_metatype _attr, modelica_metatype _nominal)
{
modelica_metatype _outAttr = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_metatype _va = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
_va = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(17));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_va), 17*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[9] = mmc_mk_some(_nominal);
_va = tmpMeta[1];
tmpMeta[0] = mmc_mk_some(_va);
goto tmp2_done;
}
case 1: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_some(_nominal), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none());
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
_outAttr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttr;
}
DLLExport
modelica_metatype omc_DAEUtil_getNominalAttr(threadData_t *threadData, modelica_metatype _attr)
{
modelica_metatype _nominal = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_metatype _n = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_n = tmpMeta[3];
tmpMeta[0] = _n;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _OMC_LIT157;
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
_nominal = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _nominal;
}
DLLExport
modelica_metatype omc_DAEUtil_setStartOrigin(threadData_t *threadData, modelica_metatype _attr, modelica_metatype _startOrigin)
{
modelica_metatype _outAttr = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_metatype _va = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 6; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
_va = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(17));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_va), 17*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[16] = _startOrigin;
_va = tmpMeta[1];
tmpMeta[0] = mmc_mk_some(_va);
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,11) == 0) goto tmp2_end;
_va = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(13));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_va), 13*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[12] = _startOrigin;
_va = tmpMeta[1];
tmpMeta[0] = mmc_mk_some(_va);
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,7) == 0) goto tmp2_end;
_va = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_va), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[8] = _startOrigin;
_va = tmpMeta[1];
tmpMeta[0] = mmc_mk_some(_va);
goto tmp2_done;
}
case 3: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,7) == 0) goto tmp2_end;
_va = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_va), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[8] = _startOrigin;
_va = tmpMeta[1];
tmpMeta[0] = mmc_mk_some(_va);
goto tmp2_done;
}
case 4: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,9) == 0) goto tmp2_end;
_va = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_va), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[10] = _startOrigin;
_va = tmpMeta[1];
tmpMeta[0] = mmc_mk_some(_va);
goto tmp2_done;
}
case 5: {
modelica_boolean tmp5;
if (!optionNone(tmp3_1)) goto tmp2_end;
tmp5 = (modelica_boolean)isNone(_startOrigin);
if(tmp5)
{
tmpMeta[2] = mmc_mk_none();
}
else
{
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), _startOrigin);
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
_outAttr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttr;
}
DLLExport
modelica_metatype omc_DAEUtil_setStartAttrOption(threadData_t *threadData, modelica_metatype _attr, modelica_metatype _start)
{
modelica_metatype _outAttr = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_metatype _va = NULL;
modelica_metatype _at = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 6; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
_va = tmpMeta[1];
if(valueEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_va), 7))), _start))
{
_at = _attr;
}
else
{
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(17));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_va), 17*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[7] = _start;
_va = tmpMeta[1];
_at = mmc_mk_some(_va);
}
tmpMeta[0] = _at;
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,11) == 0) goto tmp2_end;
_va = tmpMeta[1];
if(valueEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_va), 5))), _start))
{
_at = _attr;
}
else
{
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(13));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_va), 13*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[5] = _start;
_va = tmpMeta[1];
_at = mmc_mk_some(_va);
}
tmpMeta[0] = _at;
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,7) == 0) goto tmp2_end;
_va = tmpMeta[1];
if(valueEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_va), 3))), _start))
{
_at = _attr;
}
else
{
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_va), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[3] = _start;
_va = tmpMeta[1];
_at = mmc_mk_some(_va);
}
tmpMeta[0] = _at;
goto tmp2_done;
}
case 3: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,7) == 0) goto tmp2_end;
_va = tmpMeta[1];
if(valueEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_va), 3))), _start))
{
_at = _attr;
}
else
{
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(9));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_va), 9*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[3] = _start;
_va = tmpMeta[1];
_at = mmc_mk_some(_va);
}
tmpMeta[0] = _at;
goto tmp2_done;
}
case 4: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,9) == 0) goto tmp2_end;
_va = tmpMeta[1];
if(valueEq((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_va), 5))), _start))
{
_at = _attr;
}
else
{
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(11));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_va), 11*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[5] = _start;
_va = tmpMeta[1];
_at = mmc_mk_some(_va);
}
tmpMeta[0] = _at;
goto tmp2_done;
}
case 5: {
modelica_boolean tmp5;
if (!optionNone(tmp3_1)) goto tmp2_end;
tmp5 = (modelica_boolean)isNone(_start);
if(tmp5)
{
tmpMeta[2] = mmc_mk_none();
}
else
{
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), _start, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none());
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
_outAttr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttr;
}
DLLExport
modelica_metatype omc_DAEUtil_setStartAttr(threadData_t *threadData, modelica_metatype _attr, modelica_metatype _start)
{
modelica_metatype _outAttr = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outAttr = omc_DAEUtil_setStartAttrOption(threadData, _attr, mmc_mk_some(_start));
_return: OMC_LABEL_UNUSED
return _outAttr;
}
DLLExport
modelica_metatype omc_DAEUtil_setStateSelect(threadData_t *threadData, modelica_metatype _attr, modelica_metatype _s)
{
modelica_metatype _outAttr = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_metatype _va = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
_va = tmpMeta[1];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(17));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_va), 17*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[10] = mmc_mk_some(_s);
_va = tmpMeta[1];
tmpMeta[0] = mmc_mk_some(_va);
goto tmp2_done;
}
case 1: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_some(_s), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none());
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
_outAttr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttr;
}
DLLExport
modelica_metatype omc_DAEUtil_setVariableAttributes(threadData_t *threadData, modelica_metatype _var, modelica_metatype _varOpt)
{
modelica_metatype _v = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_v = _var;
{
modelica_metatype tmp3_1;
tmp3_1 = _v;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(15));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_v), 15*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[12] = _varOpt;
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
_v = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _v;
}
DLLExport
modelica_metatype omc_DAEUtil_getMaxAttrFail(threadData_t *threadData, modelica_metatype _inVariableAttributesOption)
{
modelica_metatype _outMax = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inVariableAttributesOption;
if (optionNone(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
if (optionNone(tmpMeta[2])) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_outMax = tmpMeta[3];
_return: OMC_LABEL_UNUSED
return _outMax;
}
DLLExport
modelica_metatype omc_DAEUtil_getMinAttrFail(threadData_t *threadData, modelica_metatype _inVariableAttributesOption)
{
modelica_metatype _outMin = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inVariableAttributesOption;
if (optionNone(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (optionNone(tmpMeta[2])) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_outMin = tmpMeta[3];
_return: OMC_LABEL_UNUSED
return _outMin;
}
DLLExport
modelica_metatype omc_DAEUtil_getNominalAttrFail(threadData_t *threadData, modelica_metatype _inVariableAttributesOption)
{
modelica_metatype _nominal = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVariableAttributesOption;
{
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
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
_nominal = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _nominal;
}
DLLExport
modelica_metatype omc_DAEUtil_getStartAttrFail(threadData_t *threadData, modelica_metatype _inVariableAttributesOption)
{
modelica_metatype _start = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVariableAttributesOption;
{
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,11) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 3: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 4: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,9) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
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
_start = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _start;
}
DLLExport
modelica_metatype omc_DAEUtil_getStartOrigin(threadData_t *threadData, modelica_metatype _inVariableAttributesOption)
{
modelica_metatype _startOrigin = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVariableAttributesOption;
{
modelica_metatype _so = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 6; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 16));
_so = tmpMeta[2];
tmpMeta[0] = _so;
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,11) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
_so = tmpMeta[2];
tmpMeta[0] = _so;
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_so = tmpMeta[2];
tmpMeta[0] = _so;
goto tmp2_done;
}
case 3: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_so = tmpMeta[2];
tmpMeta[0] = _so;
goto tmp2_done;
}
case 4: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,9) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
_so = tmpMeta[2];
tmpMeta[0] = _so;
goto tmp2_done;
}
case 5: {
if (!optionNone(tmp3_1)) goto tmp2_end;
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
_startOrigin = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _startOrigin;
}
DLLExport
modelica_metatype omc_DAEUtil_getStartAttr(threadData_t *threadData, modelica_metatype _inVariableAttributesOption)
{
modelica_metatype _start = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVariableAttributesOption;
{
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 6; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,11) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 3: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 4: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,9) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT158;
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
_start = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _start;
}
DLLExport
modelica_metatype omc_DAEUtil_setMinMax(threadData_t *threadData, modelica_metatype _inAttr, modelica_metatype _inMin, modelica_metatype _inMax)
{
modelica_metatype _outAttr = NULL;
modelica_metatype tmpMeta[17] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inAttr;
{
modelica_metatype _q = NULL;
modelica_metatype _u = NULL;
modelica_metatype _du = NULL;
modelica_metatype _f = NULL;
modelica_metatype _n = NULL;
modelica_metatype _i = NULL;
modelica_metatype _ss = NULL;
modelica_metatype _unc = NULL;
modelica_metatype _distOpt = NULL;
modelica_metatype _eb = NULL;
modelica_metatype _ip = NULL;
modelica_metatype _fn = NULL;
modelica_metatype _so = NULL;
modelica_metatype _min = NULL;
modelica_metatype _max = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_boolean tmp5;
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 13));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 14));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 15));
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 16));
_q = tmpMeta[2];
_u = tmpMeta[3];
_du = tmpMeta[4];
_min = tmpMeta[5];
_max = tmpMeta[6];
_i = tmpMeta[7];
_f = tmpMeta[8];
_n = tmpMeta[9];
_ss = tmpMeta[10];
_unc = tmpMeta[11];
_distOpt = tmpMeta[12];
_eb = tmpMeta[13];
_ip = tmpMeta[14];
_fn = tmpMeta[15];
_so = tmpMeta[16];
tmp5 = (modelica_boolean)(referenceEq(_min, _inMin) && referenceEq(_max, _inMax));
if(tmp5)
{
tmpMeta[2] = _inAttr;
}
else
{
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, _q, _u, _du, _inMin, _inMax, _i, _f, _n, _ss, _unc, _distOpt, _eb, _ip, _fn, _so);
tmpMeta[2] = mmc_mk_some(tmpMeta[1]);
}
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 1: {
modelica_boolean tmp6;
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,11) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
_q = tmpMeta[2];
_min = tmpMeta[3];
_max = tmpMeta[4];
_i = tmpMeta[5];
_f = tmpMeta[6];
_unc = tmpMeta[7];
_distOpt = tmpMeta[8];
_eb = tmpMeta[9];
_ip = tmpMeta[10];
_fn = tmpMeta[11];
_so = tmpMeta[12];
tmp6 = (modelica_boolean)(referenceEq(_min, _inMin) && referenceEq(_max, _inMax));
if(tmp6)
{
tmpMeta[2] = _inAttr;
}
else
{
tmpMeta[1] = mmc_mk_box12(4, &DAE_VariableAttributes_VAR__ATTR__INT__desc, _q, _inMin, _inMax, _i, _f, _unc, _distOpt, _eb, _ip, _fn, _so);
tmpMeta[2] = mmc_mk_some(tmpMeta[1]);
}
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 2: {
modelica_boolean tmp7;
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,9) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
_q = tmpMeta[2];
_min = tmpMeta[3];
_max = tmpMeta[4];
_u = tmpMeta[5];
_du = tmpMeta[6];
_eb = tmpMeta[7];
_ip = tmpMeta[8];
_fn = tmpMeta[9];
_so = tmpMeta[10];
tmp7 = (modelica_boolean)(referenceEq(_min, _inMin) && referenceEq(_max, _inMax));
if(tmp7)
{
tmpMeta[2] = _inAttr;
}
else
{
tmpMeta[1] = mmc_mk_box10(8, &DAE_VariableAttributes_VAR__ATTR__ENUMERATION__desc, _q, _inMin, _inMax, _u, _du, _eb, _ip, _fn, _so);
tmpMeta[2] = mmc_mk_some(tmpMeta[1]);
}
tmpMeta[0] = tmpMeta[2];
goto tmp2_done;
}
case 3: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), _inMin, _inMax, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_none());
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
_outAttr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outAttr;
}
DLLExport
modelica_metatype omc_DAEUtil_getMinMaxValues(threadData_t *threadData, modelica_metatype _inVariableAttributesOption, modelica_metatype *out_outMaxValue)
{
modelica_metatype _outMinValue = NULL;
modelica_metatype _outMaxValue = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVariableAttributesOption;
{
modelica_metatype _minValue = NULL;
modelica_metatype _maxValue = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,9) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_minValue = tmpMeta[3];
_maxValue = tmpMeta[4];
tmpMeta[0+0] = _minValue;
tmpMeta[0+1] = _maxValue;
goto tmp3_done;
}
case 1: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,11) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
_minValue = tmpMeta[3];
_maxValue = tmpMeta[4];
tmpMeta[0+0] = _minValue;
tmpMeta[0+1] = _maxValue;
goto tmp3_done;
}
case 2: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,15) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
_minValue = tmpMeta[3];
_maxValue = tmpMeta[4];
tmpMeta[0+0] = _minValue;
tmpMeta[0+1] = _maxValue;
goto tmp3_done;
}
case 3: {
tmpMeta[0+0] = mmc_mk_none();
tmpMeta[0+1] = mmc_mk_none();
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_outMinValue = tmpMeta[0+0];
_outMaxValue = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_outMaxValue) { *out_outMaxValue = _outMaxValue; }
return _outMinValue;
}
DLLExport
modelica_metatype omc_DAEUtil_getMinMax(threadData_t *threadData, modelica_metatype _inVariableAttributesOption)
{
modelica_metatype _oExps = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVariableAttributesOption;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,9) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_cons(_e1, mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,11) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_cons(_e1, mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_cons(_e1, mmc_mk_cons(_e2, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
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
_oExps = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _oExps;
}
DLLExport
modelica_metatype omc_DAEUtil_getStartAttrEmpty(threadData_t *threadData, modelica_metatype _inVariableAttributesOption, modelica_metatype _optExp)
{
modelica_metatype _start = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVariableAttributesOption;
{
modelica_metatype _r = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 6; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,11) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 3: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 4: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,9) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_r = tmpMeta[3];
tmpMeta[0] = _r;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _optExp;
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
_start = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _start;
}
DLLExport
modelica_metatype omc_DAEUtil_getUnitAttr(threadData_t *threadData, modelica_metatype _inVariableAttributesOption)
{
modelica_metatype _start = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inVariableAttributesOption;
{
modelica_metatype _u = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_u = tmpMeta[3];
tmpMeta[0] = _u;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _OMC_LIT159;
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
_start = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _start;
}
DLLExport
modelica_metatype omc_DAEUtil_getVariableAttributes(threadData_t *threadData, modelica_metatype _elt)
{
modelica_metatype _variableAttributesOption = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _elt;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 12));
_variableAttributesOption = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _variableAttributesOption;
}
DLLExport
modelica_metatype omc_DAEUtil_varCref(threadData_t *threadData, modelica_metatype _elt)
{
modelica_metatype _cr = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _elt;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,13) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_cr = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _cr;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_removeInnerAttribute(threadData_t *threadData, modelica_metatype _io)
{
modelica_metatype _ioOut = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _io;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = _OMC_LIT21;
goto tmp2_done;
}
case 5: {
tmpMeta[0] = _OMC_LIT160;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[0] = _io;
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
_ioOut = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _ioOut;
}
DLLExport
modelica_metatype omc_DAEUtil_unNameInnerouterUniqueCref(threadData_t *threadData, modelica_metatype _cr, modelica_string _removalString)
{
modelica_metatype _ocr = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _cr;
{
modelica_string _str = NULL;
modelica_string _str2 = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _child = NULL;
modelica_metatype _child_2 = NULL;
modelica_metatype _subs = NULL;
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
_str = tmpMeta[1];
_ty = tmpMeta[2];
_subs = tmpMeta[3];
tmp3 += 2;
_str2 = omc_System_stringReplace(threadData, _str, _removalString, _OMC_LIT7);
tmpMeta[0] = omc_ComponentReference_makeCrefIdent(threadData, _str2, _ty, _subs);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_str = tmpMeta[1];
_ty = tmpMeta[2];
_subs = tmpMeta[3];
_child = tmpMeta[4];
tmp3 += 1;
_child_2 = omc_DAEUtil_unNameInnerouterUniqueCref(threadData, _child, _removalString);
_str2 = omc_System_stringReplace(threadData, _str, _removalString, _OMC_LIT7);
tmpMeta[0] = omc_ComponentReference_makeCrefQual(threadData, _str2, _ty, _subs, _child_2);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,4,0) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT161;
goto tmp2_done;
}
case 3: {
_child = tmp3_1;
fputs(MMC_STRINGDATA(_OMC_LIT162),stdout);
tmpMeta[1] = stringAppend(omc_ComponentReference_printComponentRefStr(threadData, _child),_OMC_LIT28);
fputs(MMC_STRINGDATA(tmpMeta[1]),stdout);
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
if (++tmp3 < 4) {
goto tmp2_top;
}
MMC_THROW_INTERNAL();
tmp2_done2:;
}
}
_ocr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _ocr;
}
DLLExport
modelica_metatype omc_DAEUtil_nameInnerouterUniqueCref(threadData_t *threadData, modelica_metatype _inCr)
{
modelica_metatype _outCr = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inCr;
{
modelica_metatype _newChild = NULL;
modelica_metatype _child = NULL;
modelica_string _id = NULL;
modelica_metatype _idt = NULL;
modelica_metatype _subs = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_id = tmpMeta[1];
_idt = tmpMeta[2];
_subs = tmpMeta[3];
tmpMeta[1] = stringAppend(_OMC_LIT93,_id);
_id = tmpMeta[1];
tmpMeta[0] = omc_ComponentReference_makeCrefIdent(threadData, _id, _idt, _subs);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_id = tmpMeta[1];
_idt = tmpMeta[2];
_subs = tmpMeta[3];
_child = tmpMeta[4];
_newChild = omc_DAEUtil_nameInnerouterUniqueCref(threadData, _child);
tmpMeta[0] = omc_ComponentReference_makeCrefQual(threadData, _id, _idt, _subs, _newChild);
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
_outCr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outCr;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_DAEUtil_compareUniquedVarWithNonUnique(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_string _s1 = NULL;
modelica_string _s2 = NULL;
modelica_string _s3 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_s1 = omc_ComponentReference_printComponentRefStr(threadData, _cr1);
_s2 = omc_ComponentReference_printComponentRefStr(threadData, _cr2);
_s1 = omc_System_stringReplace(threadData, _s1, _OMC_LIT93, _OMC_LIT7);
_s2 = omc_System_stringReplace(threadData, _s2, _OMC_LIT93, _OMC_LIT7);
_equal = (stringEqual(_s1, _s2));
_return: OMC_LABEL_UNUSED
return _equal;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_compareUniquedVarWithNonUnique(threadData_t *threadData, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _equal;
modelica_metatype out_equal;
_equal = omc_DAEUtil_compareUniquedVarWithNonUnique(threadData, _cr1, _cr2);
out_equal = mmc_mk_icon(_equal);
return out_equal;
}
DLLExport
modelica_metatype omc_DAEUtil_removeInnerAttr(threadData_t *threadData, modelica_metatype _var, modelica_metatype _dae)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta[17] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _dae;
{
modelica_metatype _cr = NULL;
modelica_metatype _oldVar = NULL;
modelica_metatype _newVar = NULL;
modelica_metatype _elist = NULL;
modelica_metatype _elist2 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _u = NULL;
modelica_metatype _o = NULL;
modelica_string _id = NULL;
modelica_metatype _kind = NULL;
modelica_metatype _prl = NULL;
modelica_metatype _dir = NULL;
modelica_metatype _tp = NULL;
modelica_metatype _bind = NULL;
modelica_metatype _dim = NULL;
modelica_metatype _ct = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _cmt = NULL;
modelica_metatype _io = NULL;
modelica_metatype _io2 = NULL;
modelica_metatype _prot = NULL;
modelica_metatype _source = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[0] = _OMC_LIT163;
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,13) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 9));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 10));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 11));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 12));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 13));
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 14));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[16],2,0) == 0) goto tmp2_end;
_oldVar = tmpMeta[4];
_kind = tmpMeta[5];
_dir = tmpMeta[6];
_prl = tmpMeta[7];
_prot = tmpMeta[8];
_tp = tmpMeta[9];
_bind = tmpMeta[10];
_dim = tmpMeta[11];
_ct = tmpMeta[12];
_source = tmpMeta[13];
_attr = tmpMeta[14];
_cmt = tmpMeta[15];
_elist = tmpMeta[3];
if (!omc_DAEUtil_compareUniquedVarWithNonUnique(threadData, _var, _oldVar)) goto tmp2_end;
_newVar = omc_DAEUtil_nameInnerouterUniqueCref(threadData, _oldVar);
tmpMeta[1] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _oldVar, _kind, _dir, _prl, _prot, _tp, mmc_mk_none(), _dim, _ct, _source, _attr, _cmt, _OMC_LIT160);
_o = tmpMeta[1];
tmpMeta[1] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _newVar, _kind, _dir, _prl, _prot, _tp, _bind, _dim, _ct, _source, _attr, _cmt, _OMC_LIT21);
_u = tmpMeta[1];
tmpMeta[2] = mmc_mk_cons(_o, _elist);
tmpMeta[1] = mmc_mk_cons(_u, tmpMeta[2]);
_elist = tmpMeta[1];
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elist);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,13) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 6));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 7));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 8));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 9));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 10));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 11));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 12));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 13));
tmpMeta[16] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 14));
_cr = tmpMeta[4];
_kind = tmpMeta[5];
_dir = tmpMeta[6];
_prl = tmpMeta[7];
_prot = tmpMeta[8];
_tp = tmpMeta[9];
_bind = tmpMeta[10];
_dim = tmpMeta[11];
_ct = tmpMeta[12];
_source = tmpMeta[13];
_attr = tmpMeta[14];
_cmt = tmpMeta[15];
_io = tmpMeta[16];
_elist = tmpMeta[3];
if (!omc_ComponentReference_crefEqualNoStringCompare(threadData, _var, _cr)) goto tmp2_end;
_io2 = omc_DAEUtil_removeInnerAttribute(threadData, _io);
tmpMeta[2] = mmc_mk_box14(3, &DAE_Element_VAR__desc, _cr, _kind, _dir, _prl, _prot, _tp, _bind, _dim, _ct, _source, _attr, _cmt, _io2);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elist);
tmpMeta[3] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta[1]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 3: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],17,4) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_id = tmpMeta[4];
_elist = tmpMeta[5];
_source = tmpMeta[6];
_cmt = tmpMeta[7];
_elist2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elist);
tmpMeta[2] = omc_DAEUtil_removeInnerAttr(threadData, _var, tmpMeta[1]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_elist = tmpMeta[3];
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elist2);
tmpMeta[2] = omc_DAEUtil_removeInnerAttr(threadData, _var, tmpMeta[1]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_elist2 = tmpMeta[3];
tmpMeta[2] = mmc_mk_box5(20, &DAE_Element_COMP__desc, _id, _elist, _source, _cmt);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elist2);
tmpMeta[3] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta[1]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 4: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_e = tmpMeta[2];
_elist = tmpMeta[3];
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elist);
tmpMeta[2] = omc_DAEUtil_removeInnerAttr(threadData, _var, tmpMeta[1]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_elist = tmpMeta[3];
tmpMeta[1] = mmc_mk_cons(_e, _elist);
tmpMeta[2] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta[1]);
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
_outDae = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDae;
}
DLLExport
modelica_metatype omc_DAEUtil_removeInnerAttrs(threadData_t *threadData, modelica_metatype _dae, modelica_metatype _vars)
{
modelica_metatype _outDae = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outDae = omc_List_fold(threadData, _vars, boxvar_DAEUtil_removeInnerAttr, _dae);
_return: OMC_LABEL_UNUSED
return _outDae;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_removeVariable(threadData_t *threadData, modelica_metatype _var, modelica_metatype _dae)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _dae;
{
modelica_metatype _cr = NULL;
modelica_metatype _elist = NULL;
modelica_metatype _elist2 = NULL;
modelica_metatype _e = NULL;
modelica_string _id = NULL;
modelica_metatype _source = NULL;
modelica_metatype _cmt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (!listEmpty(tmpMeta[1])) goto tmp2_end;
tmp3 += 3;
tmpMeta[0] = _OMC_LIT163;
goto tmp2_done;
}
case 1: {
modelica_boolean tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,13) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_cr = tmpMeta[4];
_elist = tmpMeta[3];
tmp3 += 1;
tmp5 = omc_ComponentReference_crefEqualNoStringCompare(threadData, _var, _cr);
if (1 != tmp5) goto goto_1;
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elist);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],17,4) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 3));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 4));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 5));
_id = tmpMeta[4];
_elist = tmpMeta[5];
_source = tmpMeta[6];
_cmt = tmpMeta[7];
_elist2 = tmpMeta[3];
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elist);
tmpMeta[2] = omc_DAEUtil_removeVariable(threadData, _var, tmpMeta[1]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_elist = tmpMeta[3];
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elist2);
tmpMeta[2] = omc_DAEUtil_removeVariable(threadData, _var, tmpMeta[1]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_elist2 = tmpMeta[3];
tmpMeta[2] = mmc_mk_box5(20, &DAE_Element_COMP__desc, _id, _elist, _source, _cmt);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _elist2);
tmpMeta[3] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta[1]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 3: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (listEmpty(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_e = tmpMeta[2];
_elist = tmpMeta[3];
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elist);
tmpMeta[2] = omc_DAEUtil_removeVariable(threadData, _var, tmpMeta[1]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
_elist = tmpMeta[3];
tmpMeta[1] = mmc_mk_cons(_e, _elist);
tmpMeta[2] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta[1]);
tmpMeta[0] = tmpMeta[2];
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
_outDae = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDae;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_DAEUtil_removeVariablesFromElements(threadData_t *threadData, modelica_metatype _inElements, modelica_metatype _variableNames)
{
modelica_metatype _outElements = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_outElements = tmpMeta[0];
if(listEmpty(_variableNames))
{
_outElements = _inElements;
goto _return;
}
{
modelica_metatype _el;
for (tmpMeta[1] = _inElements; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_el = MMC_CAR(tmpMeta[1]);
{
modelica_metatype tmp3_1;
tmp3_1 = _el;
{
modelica_metatype _cr = NULL;
modelica_metatype _elist = NULL;
modelica_metatype _v = NULL;
modelica_string _id = NULL;
modelica_metatype _source = NULL;
modelica_metatype _cmt = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_v = tmp3_1;
_cr = tmpMeta[2];
if(listEmpty(omc_List_select1(threadData, _variableNames, boxvar_ComponentReference_crefEqual, _cr)))
{
tmpMeta[2] = mmc_mk_cons(_v, _outElements);
_outElements = tmpMeta[2];
}
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,4) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_id = tmpMeta[2];
_elist = tmpMeta[3];
_source = tmpMeta[4];
_cmt = tmpMeta[5];
_elist = omc_DAEUtil_removeVariablesFromElements(threadData, _elist, _variableNames);
tmpMeta[3] = mmc_mk_box5(20, &DAE_Element_COMP__desc, _id, _elist, _source, _cmt);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _outElements);
_outElements = tmpMeta[2];
goto tmp2_done;
}
case 2: {
tmpMeta[2] = mmc_mk_cons(_el, _outElements);
_outElements = tmpMeta[2];
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
_outElements = listReverseInPlace(_outElements);
_return: OMC_LABEL_UNUSED
return _outElements;
}
DLLExport
modelica_metatype omc_DAEUtil_removeVariables(threadData_t *threadData, modelica_metatype _dae, modelica_metatype _vars)
{
modelica_metatype _outDae = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _dae;
tmp3_2 = _vars;
{
modelica_metatype _elements = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_2)) goto tmp2_end;
tmpMeta[0] = _dae;
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_elements = tmpMeta[1];
_elements = omc_DAEUtil_removeVariablesFromElements(threadData, _elements, _vars);
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elements);
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
_outDae = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outDae;
}
DLLExport
modelica_metatype omc_DAEUtil_splitDAEIntoVarsAndEquations(threadData_t *threadData, modelica_metatype _inDae, modelica_metatype *out_allEqs)
{
modelica_metatype _allVars = NULL;
modelica_metatype _allEqs = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _vars = NULL;
modelica_metatype _eqs = NULL;
modelica_metatype tmpMeta[6] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inDae;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_rest = tmpMeta[1];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_vars = omc_DoubleEnded_fromList(threadData, tmpMeta[0]);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_eqs = omc_DoubleEnded_fromList(threadData, tmpMeta[0]);
{
modelica_metatype _elt;
for (tmpMeta[0] = _rest; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_elt = MMC_CAR(tmpMeta[0]);
{
modelica_metatype tmp3_1;
tmp3_1 = _elt;
{
modelica_metatype _elts1 = NULL;
modelica_metatype _elts11 = NULL;
modelica_metatype _elts3 = NULL;
modelica_string _id = NULL;
modelica_metatype _source = NULL;
modelica_metatype _cmt = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
omc_DoubleEnded_push__back(threadData, _vars, _elt);
goto tmp2_done;
}
case 20: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,17,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_id = tmpMeta[1];
_elts1 = tmpMeta[2];
_source = tmpMeta[3];
_cmt = tmpMeta[4];
tmpMeta[3] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _elts1);
tmpMeta[4] = omc_DAEUtil_splitDAEIntoVarsAndEquations(threadData, tmpMeta[3], &tmpMeta[1]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 2));
_elts11 = tmpMeta[5];
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
_elts3 = tmpMeta[2];
tmpMeta[1] = mmc_mk_box5(20, &DAE_Element_COMP__desc, _id, _elts11, _source, _cmt);
omc_DoubleEnded_push__back(threadData, _vars, tmpMeta[1]);
omc_DoubleEnded_push__list__back(threadData, _eqs, _elts3);
goto tmp2_done;
}
case 6: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 7: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 17: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 8: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 9: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 11: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 12: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 5: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 4: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 13: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 14: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 15: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 16: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 18: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 19: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 21: {
omc_DoubleEnded_push__back(threadData, _vars, _elt);
goto tmp2_done;
}
case 22: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 23: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 24: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 25: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 26: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 27: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
case 28: {
omc_DoubleEnded_push__back(threadData, _eqs, _elt);
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[1] = mmc_mk_cons(_elt, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta[1]);
tmpMeta[3] = stringAppend(_OMC_LIT164,omc_DAEDump_dumpDAEElementsStr(threadData, tmpMeta[2]));
omc_Error_addInternalError(threadData, tmpMeta[3], _OMC_LIT166);
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
}
}
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, omc_DoubleEnded_toListAndClear(threadData, _vars, tmpMeta[0]));
_allVars = tmpMeta[1];
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, omc_DoubleEnded_toListAndClear(threadData, _eqs, tmpMeta[0]));
_allEqs = tmpMeta[1];
_return: OMC_LABEL_UNUSED
if (out_allEqs) { *out_allEqs = _allEqs; }
return _allVars;
}
DLLExport
modelica_metatype omc_DAEUtil_getBoundStartEquation(threadData_t *threadData, modelica_metatype _attr)
{
modelica_metatype _oe = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_metatype _beq = NULL;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,15) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 13));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_beq = tmpMeta[2];
tmpMeta[0] = _beq;
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,11) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 9));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_beq = tmpMeta[2];
tmpMeta[0] = _beq;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,7) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_beq = tmpMeta[2];
tmpMeta[0] = _beq;
goto tmp2_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,9) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 7));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_beq = tmpMeta[2];
tmpMeta[0] = _beq;
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
_oe = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _oe;
}
DLLExport
modelica_metatype omc_DAEUtil_getClassList(threadData_t *threadData, modelica_metatype _v)
{
modelica_metatype _lst = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _v;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 11));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
_lst = tmpMeta[2];
tmpMeta[0] = _lst;
goto tmp2_done;
}
case 1: {
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
_lst = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _lst;
}
DLLExport
modelica_metatype omc_DAEUtil_addEquationBoundString(threadData_t *threadData, modelica_metatype _bindExp, modelica_metatype _attr)
{
modelica_metatype _oattr = NULL;
modelica_metatype tmpMeta[16] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _attr;
{
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _e3 = NULL;
modelica_metatype _e4 = NULL;
modelica_metatype _e5 = NULL;
modelica_metatype _e6 = NULL;
modelica_metatype _so = NULL;
modelica_metatype _min = NULL;
modelica_metatype _max = NULL;
modelica_metatype _sSelectOption = NULL;
modelica_metatype _unc = NULL;
modelica_metatype _distOption = NULL;
modelica_metatype _ip = NULL;
modelica_metatype _fn = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 6; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,15) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[12] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
tmpMeta[13] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 14));
tmpMeta[14] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 15));
tmpMeta[15] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 16));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_e3 = tmpMeta[4];
_min = tmpMeta[5];
_max = tmpMeta[6];
_e4 = tmpMeta[7];
_e5 = tmpMeta[8];
_e6 = tmpMeta[9];
_sSelectOption = tmpMeta[10];
_unc = tmpMeta[11];
_distOption = tmpMeta[12];
_ip = tmpMeta[13];
_fn = tmpMeta[14];
_so = tmpMeta[15];
tmpMeta[1] = mmc_mk_box16(3, &DAE_VariableAttributes_VAR__ATTR__REAL__desc, _e1, _e2, _e3, _min, _max, _e4, _e5, _e6, _sSelectOption, _unc, _distOption, mmc_mk_some(_bindExp), _ip, _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,11) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 11));
tmpMeta[11] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 12));
_e1 = tmpMeta[2];
_min = tmpMeta[3];
_max = tmpMeta[4];
_e2 = tmpMeta[5];
_e3 = tmpMeta[6];
_unc = tmpMeta[7];
_distOption = tmpMeta[8];
_ip = tmpMeta[9];
_fn = tmpMeta[10];
_so = tmpMeta[11];
tmpMeta[1] = mmc_mk_box12(4, &DAE_VariableAttributes_VAR__ATTR__INT__desc, _e1, _min, _max, _e2, _e3, _unc, _distOption, mmc_mk_some(_bindExp), _ip, _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_e3 = tmpMeta[4];
_ip = tmpMeta[5];
_fn = tmpMeta[6];
_so = tmpMeta[7];
tmpMeta[1] = mmc_mk_box8(5, &DAE_VariableAttributes_VAR__ATTR__BOOL__desc, _e1, _e2, _e3, mmc_mk_some(_bindExp), _ip, _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 3: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,7) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
_e1 = tmpMeta[2];
_e2 = tmpMeta[3];
_e3 = tmpMeta[4];
_ip = tmpMeta[5];
_fn = tmpMeta[6];
_so = tmpMeta[7];
tmpMeta[1] = mmc_mk_box8(7, &DAE_VariableAttributes_VAR__ATTR__STRING__desc, _e1, _e2, _e3, mmc_mk_some(_bindExp), _ip, _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 4: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],5,9) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 8));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 9));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 10));
_e1 = tmpMeta[2];
_min = tmpMeta[3];
_max = tmpMeta[4];
_e2 = tmpMeta[5];
_e3 = tmpMeta[6];
_ip = tmpMeta[7];
_fn = tmpMeta[8];
_so = tmpMeta[9];
tmpMeta[1] = mmc_mk_box10(8, &DAE_VariableAttributes_VAR__ATTR__ENUMERATION__desc, _e1, _min, _max, _e2, _e3, mmc_mk_some(_bindExp), _ip, _fn, _so);
tmpMeta[0] = mmc_mk_some(tmpMeta[1]);
goto tmp2_done;
}
case 5: {
fputs(MMC_STRINGDATA(_OMC_LIT167),stdout);
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
_oattr = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _oattr;
}
DLLExport
modelica_metatype omc_DAEUtil_getDerivativePaths(threadData_t *threadData, modelica_metatype _inFuncDefs)
{
modelica_metatype _paths = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _inFuncDefs;
{
modelica_metatype _pLst1 = NULL;
modelica_metatype _pLst2 = NULL;
modelica_metatype _p1 = NULL;
modelica_metatype _p2 = NULL;
modelica_metatype _funcDefs = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!listEmpty(tmp3_1)) goto tmp2_end;
tmp3 += 3;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,6) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
if (optionNone(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 1));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
_p1 = tmpMeta[3];
_p2 = tmpMeta[5];
_pLst1 = tmpMeta[6];
_funcDefs = tmpMeta[2];
tmp3 += 1;
_pLst2 = omc_DAEUtil_getDerivativePaths(threadData, _funcDefs);
tmpMeta[2] = mmc_mk_cons(_p2, _pLst1);
tmpMeta[1] = mmc_mk_cons(_p1, tmpMeta[2]);
tmpMeta[0] = omc_List_union(threadData, tmpMeta[1], _pLst2);
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,6) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 6));
if (!optionNone(tmpMeta[4])) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 7));
_p1 = tmpMeta[3];
_pLst1 = tmpMeta[5];
_funcDefs = tmpMeta[2];
_pLst2 = omc_DAEUtil_getDerivativePaths(threadData, _funcDefs);
tmpMeta[1] = mmc_mk_cons(_p1, _pLst1);
tmpMeta[0] = omc_List_union(threadData, tmpMeta[1], _pLst2);
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_funcDefs = tmpMeta[2];
tmpMeta[0] = omc_DAEUtil_getDerivativePaths(threadData, _funcDefs);
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
_paths = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _paths;
}
DLLExport
modelica_boolean omc_DAEUtil_derivativeOrder(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _e2)
{
modelica_boolean _b;
modelica_integer _i1;
modelica_integer _i2;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _e1;
tmp4_2 = _e2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
modelica_integer tmp7;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
tmp6 = mmc_unbox_integer(tmpMeta[0]);
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
tmp7 = mmc_unbox_integer(tmpMeta[1]);
_i1 = tmp6;
_i2 = tmp7;
tmp1 = omc_Util_isIntGreater(threadData, _i1, _i2);
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype boxptr_DAEUtil_derivativeOrder(threadData_t *threadData, modelica_metatype _e1, modelica_metatype _e2)
{
modelica_boolean _b;
modelica_metatype out_b;
_b = omc_DAEUtil_derivativeOrder(threadData, _e1, _e2);
out_b = mmc_mk_icon(_b);
return out_b;
}
DLLExport
modelica_metatype omc_DAEUtil_dimExp(threadData_t *threadData, modelica_metatype _dim)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _dim;
{
modelica_integer _iconst;
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
modelica_integer tmp4;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmp4 = mmc_unbox_integer(tmpMeta[1]);
_iconst = tmp4;
tmpMeta[1] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_iconst));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,3,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_exp = tmpMeta[1];
tmpMeta[0] = _exp;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[1] = mmc_mk_cons(mmc_anyString(_dim), MMC_REFSTRUCTLIT(mmc_nil));
omc_Error_addMessage(threadData, _OMC_LIT170, tmpMeta[1]);
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
_exp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _exp;
}
DLLExport
modelica_metatype omc_DAEUtil_expTypeArrayDimensions(threadData_t *threadData, modelica_metatype _tp)
{
modelica_metatype _dims = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _tp;
{
modelica_metatype _array_dims = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_array_dims = tmpMeta[1];
tmpMeta[0] = omc_List_map(threadData, _array_dims, boxvar_Expression_dimensionSize);
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
_dims = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _dims;
}
DLLExport
modelica_boolean omc_DAEUtil_expTypeTuple(threadData_t *threadData, modelica_metatype _tp)
{
modelica_boolean _isTuple;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _tp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,14,2) == 0) goto tmp3_end;
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
_isTuple = tmp1;
_return: OMC_LABEL_UNUSED
return _isTuple;
}
modelica_metatype boxptr_DAEUtil_expTypeTuple(threadData_t *threadData, modelica_metatype _tp)
{
modelica_boolean _isTuple;
modelica_metatype out_isTuple;
_isTuple = omc_DAEUtil_expTypeTuple(threadData, _tp);
out_isTuple = mmc_mk_icon(_isTuple);
return out_isTuple;
}
DLLExport
modelica_boolean omc_DAEUtil_expTypeArray(threadData_t *threadData, modelica_metatype _tp)
{
modelica_boolean _isArray;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _tp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
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
_isArray = tmp1;
_return: OMC_LABEL_UNUSED
return _isArray;
}
modelica_metatype boxptr_DAEUtil_expTypeArray(threadData_t *threadData, modelica_metatype _tp)
{
modelica_boolean _isArray;
modelica_metatype out_isArray;
_isArray = omc_DAEUtil_expTypeArray(threadData, _tp);
out_isArray = mmc_mk_icon(_isArray);
return out_isArray;
}
DLLExport
modelica_boolean omc_DAEUtil_expTypeComplex(threadData_t *threadData, modelica_metatype _tp)
{
modelica_boolean _isComplex;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _tp;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
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
_isComplex = tmp1;
_return: OMC_LABEL_UNUSED
return _isComplex;
}
modelica_metatype boxptr_DAEUtil_expTypeComplex(threadData_t *threadData, modelica_metatype _tp)
{
modelica_boolean _isComplex;
modelica_metatype out_isComplex;
_isComplex = omc_DAEUtil_expTypeComplex(threadData, _tp);
out_isComplex = mmc_mk_icon(_isComplex);
return out_isComplex;
}
DLLExport
modelica_metatype omc_DAEUtil_expTypeElementType(threadData_t *threadData, modelica_metatype _tp)
{
modelica_metatype _eltTp = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _tp;
{
modelica_metatype _ty = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,6,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_ty = tmpMeta[1];
_tp = _ty;
goto _tailrecursive;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _tp;
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
_eltTp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _eltTp;
}
DLLExport
modelica_boolean omc_DAEUtil_expTypeSimple(threadData_t *threadData, modelica_metatype _tp)
{
modelica_boolean _isSimple;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _tp;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmp1 = 1;
goto tmp3_done;
}
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
_isSimple = tmp1;
_return: OMC_LABEL_UNUSED
return _isSimple;
}
modelica_metatype boxptr_DAEUtil_expTypeSimple(threadData_t *threadData, modelica_metatype _tp)
{
modelica_boolean _isSimple;
modelica_metatype out_isSimple;
_isSimple = omc_DAEUtil_expTypeSimple(threadData, _tp);
out_isSimple = mmc_mk_icon(_isSimple);
return out_isSimple;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_DAEUtil_topLevelConnectorType(threadData_t *threadData, modelica_metatype _inConnectorType)
{
modelica_boolean _isTopLevel;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inConnectorType;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmp1 = 1;
goto tmp3_done;
}
case 3: {
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
_isTopLevel = tmp1;
_return: OMC_LABEL_UNUSED
return _isTopLevel;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_DAEUtil_topLevelConnectorType(threadData_t *threadData, modelica_metatype _inConnectorType)
{
modelica_boolean _isTopLevel;
modelica_metatype out_isTopLevel;
_isTopLevel = omc_DAEUtil_topLevelConnectorType(threadData, _inConnectorType);
out_isTopLevel = mmc_mk_icon(_isTopLevel);
return out_isTopLevel;
}
DLLExport
modelica_boolean omc_DAEUtil_topLevelOutput(threadData_t *threadData, modelica_metatype _componentRef, modelica_metatype _varDirection, modelica_metatype _connectorType)
{
modelica_boolean _isTopLevel;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _varDirection;
tmp4_2 = _componentRef;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,0) == 0) goto tmp3_end;
if (!omc_ConnectUtil_faceEqual(threadData, omc_ConnectUtil_componentFaceType(threadData, _componentRef), _OMC_LIT171)) goto tmp3_end;
tmp1 = omc_DAEUtil_topLevelConnectorType(threadData, _connectorType);
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
_isTopLevel = tmp1;
_return: OMC_LABEL_UNUSED
return _isTopLevel;
}
modelica_metatype boxptr_DAEUtil_topLevelOutput(threadData_t *threadData, modelica_metatype _componentRef, modelica_metatype _varDirection, modelica_metatype _connectorType)
{
modelica_boolean _isTopLevel;
modelica_metatype out_isTopLevel;
_isTopLevel = omc_DAEUtil_topLevelOutput(threadData, _componentRef, _varDirection, _connectorType);
out_isTopLevel = mmc_mk_icon(_isTopLevel);
return out_isTopLevel;
}
DLLExport
modelica_boolean omc_DAEUtil_topLevelInput(threadData_t *threadData, modelica_metatype _componentRef, modelica_metatype _varDirection, modelica_metatype _connectorType, modelica_metatype _visibility)
{
modelica_boolean _isTopLevel;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;modelica_metatype tmp4_3;
tmp4_1 = _varDirection;
tmp4_2 = _componentRef;
tmp4_3 = _visibility;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_3,1,0) == 0) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_2,1,3) == 0) goto tmp3_end;
tmp1 = 1;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,0) == 0) goto tmp3_end;
if (!omc_ConnectUtil_faceEqual(threadData, omc_ConnectUtil_componentFaceType(threadData, _componentRef), _OMC_LIT171)) goto tmp3_end;
tmp1 = omc_DAEUtil_topLevelConnectorType(threadData, _connectorType);
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
_isTopLevel = tmp1;
_return: OMC_LABEL_UNUSED
return _isTopLevel;
}
modelica_metatype boxptr_DAEUtil_topLevelInput(threadData_t *threadData, modelica_metatype _componentRef, modelica_metatype _varDirection, modelica_metatype _connectorType, modelica_metatype _visibility)
{
modelica_boolean _isTopLevel;
modelica_metatype out_isTopLevel;
_isTopLevel = omc_DAEUtil_topLevelInput(threadData, _componentRef, _varDirection, _connectorType, _visibility);
out_isTopLevel = mmc_mk_icon(_isTopLevel);
return out_isTopLevel;
}
DLLExport
modelica_string omc_DAEUtil_dumpVarParallelismStr(threadData_t *threadData, modelica_metatype _inVarParallelism)
{
modelica_string _outString = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _inVarParallelism;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmp1 = _OMC_LIT7;
goto tmp3_done;
}
case 3: {
tmp1 = _OMC_LIT173;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT174;
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_metatype omc_DAEUtil_const2VarKind(threadData_t *threadData, modelica_metatype _const)
{
modelica_metatype _kind = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _const;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 5: {
tmpMeta[0] = _OMC_LIT175;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT95;
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _OMC_LIT176;
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
_kind = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _kind;
}
DLLExport
modelica_string omc_DAEUtil_constStrFriendly(threadData_t *threadData, modelica_metatype _const)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _const;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmp1 = _OMC_LIT7;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT177;
goto tmp3_done;
}
case 3: {
tmp1 = _OMC_LIT178;
goto tmp3_done;
}
}
goto tmp3_end;
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
modelica_string omc_DAEUtil_constStr(threadData_t *threadData, modelica_metatype _const)
{
modelica_string _str = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _const;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 5: {
tmp1 = _OMC_LIT179;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT180;
goto tmp3_done;
}
case 3: {
tmp1 = _OMC_LIT181;
goto tmp3_done;
}
}
goto tmp3_end;
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
