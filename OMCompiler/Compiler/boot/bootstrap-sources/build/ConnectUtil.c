#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/ConnectUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "ConnectUtil.h"
#define _OMC_LIT0_data ", "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,2,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#define _OMC_LIT1_data "pointer to set "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT1,15,_OMC_LIT1_data);
#define _OMC_LIT1 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT1)
#define _OMC_LIT2_data "	"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT2,1,_OMC_LIT2_data);
#define _OMC_LIT2 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT2)
#define _OMC_LIT3_data " connected to "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT3,14,_OMC_LIT3_data);
#define _OMC_LIT3 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT3)
#define _OMC_LIT4_data "\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT4,1,_OMC_LIT4_data);
#define _OMC_LIT4 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT4)
#define _OMC_LIT5_data ""
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT5,0,_OMC_LIT5_data);
#define _OMC_LIT5 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT5)
#define _OMC_LIT6_data " associated flow: "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT6,18,_OMC_LIT6_data);
#define _OMC_LIT6 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT6)
#define _OMC_LIT7_data "equ"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT7,3,_OMC_LIT7_data);
#define _OMC_LIT7 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT7)
#define _OMC_LIT8_data "flow"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT8,4,_OMC_LIT8_data);
#define _OMC_LIT8 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT8)
#define _OMC_LIT9_data "stream"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT9,6,_OMC_LIT9_data);
#define _OMC_LIT9 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT9)
#define _OMC_LIT10_data "inside"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT10,6,_OMC_LIT10_data);
#define _OMC_LIT10 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT10)
#define _OMC_LIT11_data "outside"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT11,7,_OMC_LIT11_data);
#define _OMC_LIT11 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT11)
#define _OMC_LIT12_data "unknown"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT12,7,_OMC_LIT12_data);
#define _OMC_LIT12 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT12)
#define _OMC_LIT13_data " "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT13,1,_OMC_LIT13_data);
#define _OMC_LIT13 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT13)
#define _OMC_LIT14_data " ["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT14,2,_OMC_LIT14_data);
#define _OMC_LIT14 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT14)
#define _OMC_LIT15_data "]"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT15,1,_OMC_LIT15_data);
#define _OMC_LIT15 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT15)
#define _OMC_LIT16_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT16,1,_OMC_LIT16_data);
#define _OMC_LIT16 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT16)
#define _OMC_LIT17_data ":"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT17,1,_OMC_LIT17_data);
#define _OMC_LIT17 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT17)
#define _OMC_LIT18_data " sets:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT18,7,_OMC_LIT18_data);
#define _OMC_LIT18 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT18)
#define _OMC_LIT19_data "Connected sets:\n"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT19,16,_OMC_LIT19_data);
#define _OMC_LIT19 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT19)
#define _OMC_LIT20_data "failtrace"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT20,9,_OMC_LIT20_data);
#define _OMC_LIT20 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT20)
#define _OMC_LIT21_data "Sets whether to print a failtrace or not."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT21,41,_OMC_LIT21_data);
#define _OMC_LIT21 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT21)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT22,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT21}};
#define _OMC_LIT22 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT22)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT23,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),_OMC_LIT20,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT22}};
#define _OMC_LIT23 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT23)
#define _OMC_LIT24_data "- ConnectUtil.sizeOfType failed on "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT24,35,_OMC_LIT24_data);
#define _OMC_LIT24 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT24)
#define _OMC_LIT25_data "The number of potential variables ("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT25,35,_OMC_LIT25_data);
#define _OMC_LIT25 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT25)
#define _OMC_LIT26_data ") is not equal to the number of flow variables ("
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT26,48,_OMC_LIT26_data);
#define _OMC_LIT26 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT26)
#define _OMC_LIT27_data ")."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT27,2,_OMC_LIT27_data);
#define _OMC_LIT27 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT27)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT28,1,5) {&ErrorTypes_MessageType_TRANSLATION__desc,}};
#define _OMC_LIT28 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT28)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT29,1,5) {&ErrorTypes_Severity_WARNING__desc,}};
#define _OMC_LIT29 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT29)
#define _OMC_LIT30_data "Connector %s is not balanced: %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT30,32,_OMC_LIT30_data);
#define _OMC_LIT30 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT30)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT31,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT30}};
#define _OMC_LIT31 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT31)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT32,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(150)),_OMC_LIT28,_OMC_LIT29,_OMC_LIT31}};
#define _OMC_LIT32 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT32)
#define _OMC_LIT33_data "A stream connector must have exactly one flow variable, this connector has "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT33,75,_OMC_LIT33_data);
#define _OMC_LIT33 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT33)
#define _OMC_LIT34_data " flow variables."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT34,16,_OMC_LIT34_data);
#define _OMC_LIT34 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT34)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT35,1,4) {&ErrorTypes_Severity_ERROR__desc,}};
#define _OMC_LIT35 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT35)
#define _OMC_LIT36_data "Invalid stream connector %s: %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT36,31,_OMC_LIT36_data);
#define _OMC_LIT36 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT36)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT37,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT36}};
#define _OMC_LIT37 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT37)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT38,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(216)),_OMC_LIT28,_OMC_LIT35,_OMC_LIT37}};
#define _OMC_LIT38 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT38)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT39,1,4) {&DAE_Connect_Face_OUTSIDE__desc,}};
#define _OMC_LIT39 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT39)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT40,1,3) {&DAE_Connect_Face_INSIDE__desc,}};
#define _OMC_LIT40 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT40)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT41,1,11) {&DAE_Type_T__UNKNOWN__desc,}};
#define _OMC_LIT41 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT41)
#define _OMC_LIT42_data "min"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT42,3,_OMC_LIT42_data);
#define _OMC_LIT42 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT42)
#define _OMC_LIT43_data "max"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT43,3,_OMC_LIT43_data);
#define _OMC_LIT43 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT43)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT44,0.0);
#define _OMC_LIT44 MMC_REFREALLIT(_OMC_LIT_STRUCT44)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT45,2,4) {&DAE_Exp_RCONST__desc,_OMC_LIT44}};
#define _OMC_LIT45 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT45)
#define _OMC_LIT46_data "smooth"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT46,6,_OMC_LIT46_data);
#define _OMC_LIT46 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT46)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT47,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT46}};
#define _OMC_LIT47 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT47)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT48,2,3) {&DAE_Exp_ICONST__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(0))}};
#define _OMC_LIT48 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT48)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT49,2,4) {&DAE_Type_T__REAL__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT49 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT49)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT50,1,7) {&DAE_InlineType_NO__INLINE__desc,}};
#define _OMC_LIT50 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT50)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT51,1,3) {&DAE_TailCall_NO__TAIL__desc,}};
#define _OMC_LIT51 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT51)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT52,8,3) {&DAE_CallAttributes_CALL__ATTR__desc,_OMC_LIT49,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(1)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT50,_OMC_LIT51}};
#define _OMC_LIT52 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT52)
#define _OMC_LIT53_data "$OMC$inStreamDiv"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT53,16,_OMC_LIT53_data);
#define _OMC_LIT53 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT53)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT54,2,5) {&DAE_Connect_ConnectorType_STREAM__desc,MMC_REFSTRUCTLIT(mmc_none)}};
#define _OMC_LIT54 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT54)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT55,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT5,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT44}};
#define _OMC_LIT55 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT55)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT56,1,4) {&DAE_ComponentPrefix_NOCOMPPRE__desc,}};
#define _OMC_LIT56 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT56)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT57,8,3) {&DAE_ElementSource_SOURCE__desc,_OMC_LIT55,MMC_REFSTRUCTLIT(mmc_nil),_OMC_LIT56,MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil),MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT57 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT57)
#define _OMC_LIT58_data "- ConnectUtil.evaluateInStream failed for "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT58,42,_OMC_LIT58_data);
#define _OMC_LIT58 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT58)
#define _OMC_LIT59_data "inStream"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT59,8,_OMC_LIT59_data);
#define _OMC_LIT59 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT59)
#define _OMC_LIT60_data "actualStream"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT60,12,_OMC_LIT60_data);
#define _OMC_LIT60 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT60)
#define _OMC_LIT61_data "cardinality"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT61,11,_OMC_LIT61_data);
#define _OMC_LIT61 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT61)
#define _OMC_LIT62_data "flowThreshold"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT62,13,_OMC_LIT62_data);
#define _OMC_LIT62 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT62)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT63,1,4) {&Flags_FlagVisibility_EXTERNAL__desc,}};
#define _OMC_LIT63 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT63)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT64,1e-07);
#define _OMC_LIT64 MMC_REFREALLIT(_OMC_LIT_STRUCT64)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT65,2,7) {&Flags_FlagData_REAL__FLAG__desc,_OMC_LIT64}};
#define _OMC_LIT65 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT65)
#define _OMC_LIT66_data "Sets the minium threshold for stream flow rates"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT66,47,_OMC_LIT66_data);
#define _OMC_LIT66 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT66)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT67,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT66}};
#define _OMC_LIT67 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT67)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT68,8,3) {&Flags_ConfigFlag_CONFIG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(74)),_OMC_LIT62,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT63,_OMC_LIT65,MMC_REFSTRUCTLIT(mmc_none),_OMC_LIT67}};
#define _OMC_LIT68 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT68)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT69,1,5) {&DAE_AvlTreePathFunction_Tree_EMPTY__desc,}};
#define _OMC_LIT69 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT69)
#define _OMC_LIT70_data "nominal"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT70,7,_OMC_LIT70_data);
#define _OMC_LIT70 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT70)
#define _OMC_LIT71_data "$OMC$PositiveMax"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT71,16,_OMC_LIT71_data);
#define _OMC_LIT71 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT71)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT72,2,4) {&Absyn_Path_IDENT__desc,_OMC_LIT71}};
#define _OMC_LIT72 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT72)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT73,1,1) {MMC_IMMEDIATE(MMC_TAGFIXNUM(1))}};
#define _OMC_LIT73 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT73)
#define _OMC_LIT74_data " equation generated by stream handling"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT74,38,_OMC_LIT74_data);
#define _OMC_LIT74 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT74)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT75,2,3) {&DAE_DAElist_DAE__desc,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT75 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT75)
#define _OMC_LIT76_data "Internal error %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT76,17,_OMC_LIT76_data);
#define _OMC_LIT76 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT76)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT77,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT76}};
#define _OMC_LIT77 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT77)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT78,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(63)),_OMC_LIT28,_OMC_LIT35,_OMC_LIT77}};
#define _OMC_LIT78 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT78)
#define _OMC_LIT79_data "ConnectUtil.equationsDispatch failed on connection set with no type."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT79,68,_OMC_LIT79_data);
#define _OMC_LIT79 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT79)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT80,2,1) {_OMC_LIT79,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT80 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT80)
#define _OMC_LIT81_data "ConnectUtil.equationsDispatch failed because of unknown reason."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT81,63,_OMC_LIT81_data);
#define _OMC_LIT81 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT81)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT82,2,1) {_OMC_LIT81,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT82 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT82)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT83,1,6) {&DAE_Connect_ConnectorType_NO__TYPE__desc,}};
#define _OMC_LIT83 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT83)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT84,3,3) {&DAE_Connect_Set_SET__desc,_OMC_LIT83,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT84 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT84)
#define _OMC_LIT85_data "["
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT85,1,_OMC_LIT85_data);
#define _OMC_LIT85 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT85)
#define _OMC_LIT86_data ","
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT86,1,_OMC_LIT86_data);
#define _OMC_LIT86 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT86)
#define _OMC_LIT87_data "The language feature %s is not supported. Suggested workaround: %s"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT87,66,_OMC_LIT87_data);
#define _OMC_LIT87 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT87)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT88,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT87}};
#define _OMC_LIT88 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT88)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT89,5,3) {&ErrorTypes_Message_MESSAGE__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(35)),_OMC_LIT28,_OMC_LIT35,_OMC_LIT88}};
#define _OMC_LIT89 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT89)
#define _OMC_LIT90_data "Connections where both connectors are outer references"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT90,54,_OMC_LIT90_data);
#define _OMC_LIT90 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT90)
#define _OMC_LIT91_data "No suggestion"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT91,13,_OMC_LIT91_data);
#define _OMC_LIT91 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT91)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT92,2,1) {_OMC_LIT91,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT92 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT92)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT93,2,1) {_OMC_LIT90,_OMC_LIT92}};
#define _OMC_LIT93 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT93)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT94,1,4) {&DAE_Connect_ConnectorType_FLOW__desc,}};
#define _OMC_LIT94 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT94)
#define _OMC_LIT95_data "Unknown var "
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT95,12,_OMC_LIT95_data);
#define _OMC_LIT95 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT95)
#define _OMC_LIT96_data " in ConnectUtil.daeVarToCrefs"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT96,29,_OMC_LIT96_data);
#define _OMC_LIT96 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT96)
#define _OMC_LIT97_data "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/FrontEnd/ConnectUtil.mo"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT97,72,_OMC_LIT97_data);
#define _OMC_LIT97 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT97)
static const MMC_DEFREALLIT(_OMC_LIT_STRUCT98_6,1602262265.0);
#define _OMC_LIT98_6 MMC_REFREALLIT(_OMC_LIT_STRUCT98_6)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT98,8,3) {&SourceInfo_SOURCEINFO__desc,_OMC_LIT97,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),MMC_IMMEDIATE(MMC_TAGFIXNUM(465)),MMC_IMMEDIATE(MMC_TAGFIXNUM(9)),MMC_IMMEDIATE(MMC_TAGFIXNUM(466)),MMC_IMMEDIATE(MMC_TAGFIXNUM(57)),_OMC_LIT98_6}};
#define _OMC_LIT98 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT98)
#define _OMC_LIT99_data "disableSingleFlowEq"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT99,19,_OMC_LIT99_data);
#define _OMC_LIT99 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT99)
#define _OMC_LIT100_data "Disables the generation of single flow equations."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT100,49,_OMC_LIT100_data);
#define _OMC_LIT100 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT100)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT101,2,3) {&Gettext_TranslatableContent_gettext__desc,_OMC_LIT100}};
#define _OMC_LIT101 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT101)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT102,5,3) {&Flags_DebugFlag_DEBUG__FLAG__desc,MMC_IMMEDIATE(MMC_TAGFIXNUM(92)),_OMC_LIT99,MMC_IMMEDIATE(MMC_TAGFIXNUM(0)),_OMC_LIT101}};
#define _OMC_LIT102 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT102)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT103,1,3) {&DAE_Connect_ConnectorType_EQU__desc,}};
#define _OMC_LIT103 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT103)
#define _OMC_LIT104_data "ConnectUtil.makeConnectorType: invalid connector type."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT104,54,_OMC_LIT104_data);
#define _OMC_LIT104 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT104)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT105,2,1) {_OMC_LIT104,MMC_REFSTRUCTLIT(mmc_nil)}};
#define _OMC_LIT105 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT105)
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT106,1,7) {&DAE_ComponentRef_WILD__desc,}};
#define _OMC_LIT106 MMC_REFSTRUCTLIT(_OMC_LIT_STRUCT106)
#include "util/modelica.h"
#include "ConnectUtil_includes.h"
#if !defined(PROTECTED_FUNCTION_STATIC)
#define PROTECTED_FUNCTION_STATIC
#endif
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isEquType(threadData_t *threadData, modelica_metatype _ty);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isEquType(threadData_t *threadData, modelica_metatype _ty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_isEquType,2,0) {(void*) boxptr_ConnectUtil_isEquType,0}};
#define boxvar_ConnectUtil_isEquType MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_isEquType)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_removeUnusedExpandableVariablesAndConnections(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype __omcQ_24in_5FDAE, modelica_metatype *out_DAE);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_removeUnusedExpandableVariablesAndConnections,2,0) {(void*) boxptr_ConnectUtil_removeUnusedExpandableVariablesAndConnections,0}};
#define boxvar_ConnectUtil_removeUnusedExpandableVariablesAndConnections MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_removeUnusedExpandableVariablesAndConnections)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getAllEquCrefs(threadData_t *threadData, modelica_metatype _sets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_getAllEquCrefs,2,0) {(void*) boxptr_ConnectUtil_getAllEquCrefs,0}};
#define boxvar_ConnectUtil_getAllEquCrefs MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_getAllEquCrefs)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printSetStr(threadData_t *threadData, modelica_metatype _set);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_printSetStr,2,0) {(void*) boxptr_ConnectUtil_printSetStr,0}};
#define boxvar_ConnectUtil_printSetStr MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_printSetStr)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printSetConnection(threadData_t *threadData, modelica_metatype _connection);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_printSetConnection,2,0) {(void*) boxptr_ConnectUtil_printSetConnection,0}};
#define boxvar_ConnectUtil_printSetConnection MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_printSetConnection)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printSetConnections(threadData_t *threadData, modelica_metatype _connections);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_printSetConnections,2,0) {(void*) boxptr_ConnectUtil_printSetConnections,0}};
#define boxvar_ConnectUtil_printSetConnections MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_printSetConnections)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printOptFlowAssociation(threadData_t *threadData, modelica_metatype _cref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_printOptFlowAssociation,2,0) {(void*) boxptr_ConnectUtil_printOptFlowAssociation,0}};
#define boxvar_ConnectUtil_printOptFlowAssociation MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_printOptFlowAssociation)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printConnectorTypeStr(threadData_t *threadData, modelica_metatype _ty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_printConnectorTypeStr,2,0) {(void*) boxptr_ConnectUtil_printConnectorTypeStr,0}};
#define boxvar_ConnectUtil_printConnectorTypeStr MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_printConnectorTypeStr)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printLeafElementStr(threadData_t *threadData, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_printLeafElementStr,2,0) {(void*) boxptr_ConnectUtil_printLeafElementStr,0}};
#define boxvar_ConnectUtil_printLeafElementStr MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_printLeafElementStr)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printSetTrieStr(threadData_t *threadData, modelica_metatype _trie, modelica_string _accumName);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_printSetTrieStr,2,0) {(void*) boxptr_ConnectUtil_printSetTrieStr,0}};
#define boxvar_ConnectUtil_printSetTrieStr MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_printSetTrieStr)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_removeReferenceFromConnects2(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _element);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_removeReferenceFromConnects2(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_removeReferenceFromConnects2,2,0) {(void*) boxptr_ConnectUtil_removeReferenceFromConnects2,0}};
#define boxvar_ConnectUtil_removeReferenceFromConnects2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_removeReferenceFromConnects2)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ConnectUtil_sizeOfType(threadData_t *threadData, modelica_metatype _ty);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sizeOfType(threadData_t *threadData, modelica_metatype _ty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_sizeOfType,2,0) {(void*) boxptr_ConnectUtil_sizeOfType,0}};
#define boxvar_ConnectUtil_sizeOfType MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_sizeOfType)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ConnectUtil_sizeOfVariableList(threadData_t *threadData, modelica_metatype _vars);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sizeOfVariableList(threadData_t *threadData, modelica_metatype _vars);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_sizeOfVariableList,2,0) {(void*) boxptr_ConnectUtil_sizeOfVariableList,0}};
#define boxvar_ConnectUtil_sizeOfVariableList MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_sizeOfVariableList)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ConnectUtil_countConnectorVars(threadData_t *threadData, modelica_metatype _vars, modelica_integer *out_flowVars, modelica_integer *out_streamVars);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_countConnectorVars(threadData_t *threadData, modelica_metatype _vars, modelica_metatype *out_flowVars, modelica_metatype *out_streamVars);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_countConnectorVars,2,0) {(void*) boxptr_ConnectUtil_countConnectorVars,0}};
#define boxvar_ConnectUtil_countConnectorVars MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_countConnectorVars)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_checkConnectorBalance2(threadData_t *threadData, modelica_integer _potentialVars, modelica_integer _flowVars, modelica_integer _streamVars, modelica_metatype _path, modelica_metatype _info);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_checkConnectorBalance2(threadData_t *threadData, modelica_metatype _potentialVars, modelica_metatype _flowVars, modelica_metatype _streamVars, modelica_metatype _path, modelica_metatype _info);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_checkConnectorBalance2,2,0) {(void*) boxptr_ConnectUtil_checkConnectorBalance2,0}};
#define boxvar_ConnectUtil_checkConnectorBalance2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_checkConnectorBalance2)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_compareCrefStreamSet(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _element);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_compareCrefStreamSet(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_compareCrefStreamSet,2,0) {(void*) boxptr_ConnectUtil_compareCrefStreamSet,0}};
#define boxvar_ConnectUtil_compareCrefStreamSet MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_compareCrefStreamSet)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_removeStreamSetElement(threadData_t *threadData, modelica_metatype _cref, modelica_metatype __omcQ_24in_5Felements);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_removeStreamSetElement,2,0) {(void*) boxptr_ConnectUtil_removeStreamSetElement,0}};
#define boxvar_ConnectUtil_removeStreamSetElement MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_removeStreamSetElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_simplifyDAEIfEquation(threadData_t *threadData, modelica_metatype _conditions, modelica_metatype _branches, modelica_metatype _elseBranch);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_simplifyDAEIfEquation,2,0) {(void*) boxptr_ConnectUtil_simplifyDAEIfEquation,0}};
#define boxvar_ConnectUtil_simplifyDAEIfEquation MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_simplifyDAEIfEquation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_simplifyDAEElement(threadData_t *threadData, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_simplifyDAEElement,2,0) {(void*) boxptr_ConnectUtil_simplifyDAEElement,0}};
#define boxvar_ConnectUtil_simplifyDAEElement MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_simplifyDAEElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_simplifyDAEElements(threadData_t *threadData, modelica_boolean _hasCardinality, modelica_metatype __omcQ_24in_5FDAE);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_simplifyDAEElements(threadData_t *threadData, modelica_metatype _hasCardinality, modelica_metatype __omcQ_24in_5FDAE);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_simplifyDAEElements,2,0) {(void*) boxptr_ConnectUtil_simplifyDAEElements,0}};
#define boxvar_ConnectUtil_simplifyDAEElements MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_simplifyDAEElements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_evaluateCardinality(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _sets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateCardinality,2,0) {(void*) boxptr_ConnectUtil_evaluateCardinality,0}};
#define boxvar_ConnectUtil_evaluateCardinality MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateCardinality)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ConnectUtil_evaluateFlowDirection(threadData_t *threadData, modelica_metatype _ty);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_evaluateFlowDirection(threadData_t *threadData, modelica_metatype _ty);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateFlowDirection,2,0) {(void*) boxptr_ConnectUtil_evaluateFlowDirection,0}};
#define boxvar_ConnectUtil_evaluateFlowDirection MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateFlowDirection)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_evaluateActualStream(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _sets, modelica_metatype _setArray, modelica_real _flowThreshold);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_evaluateActualStream(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _sets, modelica_metatype _setArray, modelica_metatype _flowThreshold);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateActualStream,2,0) {(void*) boxptr_ConnectUtil_evaluateActualStream,0}};
#define boxvar_ConnectUtil_evaluateActualStream MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateActualStream)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_generateInStreamExp(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _streams, modelica_metatype _sets, modelica_metatype _setArray, modelica_real _flowThreshold);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_generateInStreamExp(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _streams, modelica_metatype _sets, modelica_metatype _setArray, modelica_metatype _flowThreshold);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_generateInStreamExp,2,0) {(void*) boxptr_ConnectUtil_generateInStreamExp,0}};
#define boxvar_ConnectUtil_generateInStreamExp MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_generateInStreamExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_evaluateInStream(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _sets, modelica_metatype _setArray, modelica_real _flowThreshold);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_evaluateInStream(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _sets, modelica_metatype _setArray, modelica_metatype _flowThreshold);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateInStream,2,0) {(void*) boxptr_ConnectUtil_evaluateInStream,0}};
#define boxvar_ConnectUtil_evaluateInStream MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateInStream)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_mkArrayIfNeeded(threadData_t *threadData, modelica_metatype _ty, modelica_metatype __omcQ_24in_5Fexp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_mkArrayIfNeeded,2,0) {(void*) boxptr_ConnectUtil_mkArrayIfNeeded,0}};
#define boxvar_ConnectUtil_mkArrayIfNeeded MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_mkArrayIfNeeded)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_evaluateConnectionOperatorsExp(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype _sets, modelica_metatype _setArray, modelica_real _flowThreshold, modelica_boolean __omcQ_24in_5Fchanged, modelica_boolean *out_changed);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_evaluateConnectionOperatorsExp(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype _sets, modelica_metatype _setArray, modelica_metatype _flowThreshold, modelica_metatype __omcQ_24in_5Fchanged, modelica_metatype *out_changed);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateConnectionOperatorsExp,2,0) {(void*) boxptr_ConnectUtil_evaluateConnectionOperatorsExp,0}};
#define boxvar_ConnectUtil_evaluateConnectionOperatorsExp MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateConnectionOperatorsExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_evaluateConnectionOperators2(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _setArray, modelica_boolean _hasCardinality, modelica_real _flowThreshold, modelica_metatype *out_sets);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_evaluateConnectionOperators2(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _setArray, modelica_metatype _hasCardinality, modelica_metatype _flowThreshold, modelica_metatype *out_sets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateConnectionOperators2,2,0) {(void*) boxptr_ConnectUtil_evaluateConnectionOperators2,0}};
#define boxvar_ConnectUtil_evaluateConnectionOperators2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateConnectionOperators2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_evaluateConnectionOperators(threadData_t *threadData, modelica_metatype _sets, modelica_metatype _setArray, modelica_metatype __omcQ_24in_5FDAE);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateConnectionOperators,2,0) {(void*) boxptr_ConnectUtil_evaluateConnectionOperators,0}};
#define boxvar_ConnectUtil_evaluateConnectionOperators MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_evaluateConnectionOperators)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_makePositiveMaxCall(threadData_t *threadData, modelica_metatype _flowExp, modelica_metatype _flowThreshold);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_makePositiveMaxCall,2,0) {(void*) boxptr_ConnectUtil_makePositiveMaxCall,0}};
#define boxvar_ConnectUtil_makePositiveMaxCall MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_makePositiveMaxCall)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_makeInStreamCall(threadData_t *threadData, modelica_metatype _streamExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_makeInStreamCall,2,0) {(void*) boxptr_ConnectUtil_makeInStreamCall,0}};
#define boxvar_ConnectUtil_makeInStreamCall MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_makeInStreamCall)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_sumInside2(threadData_t *threadData, modelica_metatype _element, modelica_real _flowThreshold);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sumInside2(threadData_t *threadData, modelica_metatype _element, modelica_metatype _flowThreshold);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_sumInside2,2,0) {(void*) boxptr_ConnectUtil_sumInside2,0}};
#define boxvar_ConnectUtil_sumInside2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_sumInside2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_sumOutside2(threadData_t *threadData, modelica_metatype _element, modelica_real _flowThreshold);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sumOutside2(threadData_t *threadData, modelica_metatype _element, modelica_metatype _flowThreshold);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_sumOutside2,2,0) {(void*) boxptr_ConnectUtil_sumOutside2,0}};
#define boxvar_ConnectUtil_sumOutside2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_sumOutside2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_sumInside1(threadData_t *threadData, modelica_metatype _element, modelica_real _flowThreshold);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sumInside1(threadData_t *threadData, modelica_metatype _element, modelica_metatype _flowThreshold);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_sumInside1,2,0) {(void*) boxptr_ConnectUtil_sumInside1,0}};
#define boxvar_ConnectUtil_sumInside1 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_sumInside1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_sumOutside1(threadData_t *threadData, modelica_metatype _element, modelica_real _flowThreshold);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sumOutside1(threadData_t *threadData, modelica_metatype _element, modelica_metatype _flowThreshold);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_sumOutside1,2,0) {(void*) boxptr_ConnectUtil_sumOutside1,0}};
#define boxvar_ConnectUtil_sumOutside1 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_sumOutside1)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_flowExp(threadData_t *threadData, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_flowExp,2,0) {(void*) boxptr_ConnectUtil_flowExp,0}};
#define boxvar_ConnectUtil_flowExp MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_flowExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_streamFlowExp(threadData_t *threadData, modelica_metatype _element, modelica_metatype *out_flowExp);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_streamFlowExp,2,0) {(void*) boxptr_ConnectUtil_streamFlowExp,0}};
#define boxvar_ConnectUtil_streamFlowExp MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_streamFlowExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_sumMap(threadData_t *threadData, modelica_metatype _elements, modelica_fnptr _func, modelica_real _flowThreshold);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sumMap(threadData_t *threadData, modelica_metatype _elements, modelica_fnptr _func, modelica_metatype _flowThreshold);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_sumMap,2,0) {(void*) boxptr_ConnectUtil_sumMap,0}};
#define boxvar_ConnectUtil_sumMap MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_sumMap)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_streamSumEquationExp(threadData_t *threadData, modelica_metatype _outsideElements, modelica_metatype _insideElements, modelica_real _flowThreshold);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_streamSumEquationExp(threadData_t *threadData, modelica_metatype _outsideElements, modelica_metatype _insideElements, modelica_metatype _flowThreshold);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_streamSumEquationExp,2,0) {(void*) boxptr_ConnectUtil_streamSumEquationExp,0}};
#define boxvar_ConnectUtil_streamSumEquationExp MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_streamSumEquationExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_streamEquationGeneral(threadData_t *threadData, modelica_metatype _outsideElements, modelica_metatype _insideElements, modelica_real _flowThreshold);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_streamEquationGeneral(threadData_t *threadData, modelica_metatype _outsideElements, modelica_metatype _insideElements, modelica_metatype _flowThreshold);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_streamEquationGeneral,2,0) {(void*) boxptr_ConnectUtil_streamEquationGeneral,0}};
#define boxvar_ConnectUtil_streamEquationGeneral MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_streamEquationGeneral)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isZeroFlow(threadData_t *threadData, modelica_metatype _element, modelica_string _attr);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isZeroFlow(threadData_t *threadData, modelica_metatype _element, modelica_metatype _attr);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_isZeroFlow,2,0) {(void*) boxptr_ConnectUtil_isZeroFlow,0}};
#define boxvar_ConnectUtil_isZeroFlow MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_isZeroFlow)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isZeroFlowMinMax(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _element);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isZeroFlowMinMax(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_isZeroFlowMinMax,2,0) {(void*) boxptr_ConnectUtil_isZeroFlowMinMax,0}};
#define boxvar_ConnectUtil_isZeroFlowMinMax MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_isZeroFlowMinMax)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isOutsideElement(threadData_t *threadData, modelica_metatype _element);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isOutsideElement(threadData_t *threadData, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_isOutsideElement,2,0) {(void*) boxptr_ConnectUtil_isOutsideElement,0}};
#define boxvar_ConnectUtil_isOutsideElement MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_isOutsideElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_generateStreamEquations(threadData_t *threadData, modelica_metatype _elements, modelica_real _flowThreshold);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_generateStreamEquations(threadData_t *threadData, modelica_metatype _elements, modelica_metatype _flowThreshold);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_generateStreamEquations,2,0) {(void*) boxptr_ConnectUtil_generateStreamEquations,0}};
#define boxvar_ConnectUtil_generateStreamEquations MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_generateStreamEquations)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_increaseRefCount(threadData_t *threadData, modelica_integer _amount, modelica_metatype __omcQ_24in_5Fnode);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_increaseRefCount(threadData_t *threadData, modelica_metatype _amount, modelica_metatype __omcQ_24in_5Fnode);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_increaseRefCount,2,0) {(void*) boxptr_ConnectUtil_increaseRefCount,0}};
#define boxvar_ConnectUtil_increaseRefCount MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_increaseRefCount)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_makeFlowExp(threadData_t *threadData, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_makeFlowExp,2,0) {(void*) boxptr_ConnectUtil_makeFlowExp,0}};
#define boxvar_ConnectUtil_makeFlowExp MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_makeFlowExp)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_generateFlowEquations(threadData_t *threadData, modelica_metatype _elements);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_generateFlowEquations,2,0) {(void*) boxptr_ConnectUtil_generateFlowEquations,0}};
#define boxvar_ConnectUtil_generateFlowEquations MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_generateFlowEquations)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_shouldFlipEquEquation(threadData_t *threadData, modelica_metatype _lhsCref, modelica_metatype _lhsSource);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_shouldFlipEquEquation(threadData_t *threadData, modelica_metatype _lhsCref, modelica_metatype _lhsSource);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_shouldFlipEquEquation,2,0) {(void*) boxptr_ConnectUtil_shouldFlipEquEquation,0}};
#define boxvar_ConnectUtil_shouldFlipEquEquation MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_shouldFlipEquEquation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_generateEquEquations(threadData_t *threadData, modelica_metatype _elements);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_generateEquEquations,2,0) {(void*) boxptr_ConnectUtil_generateEquEquations,0}};
#define boxvar_ConnectUtil_generateEquEquations MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_generateEquEquations)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_equationsDispatch(threadData_t *threadData, modelica_metatype _sets, modelica_metatype _connected, modelica_metatype _broken);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_equationsDispatch,2,0) {(void*) boxptr_ConnectUtil_equationsDispatch,0}};
#define boxvar_ConnectUtil_equationsDispatch MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_equationsDispatch)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setArrayGet(threadData_t *threadData, modelica_metatype _setArray, modelica_integer _index);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setArrayGet(threadData_t *threadData, modelica_metatype _setArray, modelica_metatype _index);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setArrayGet,2,0) {(void*) boxptr_ConnectUtil_setArrayGet,0}};
#define boxvar_ConnectUtil_setArrayGet MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setArrayGet)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_equSetElementLess(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_equSetElementLess(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_equSetElementLess,2,0) {(void*) boxptr_ConnectUtil_equSetElementLess,0}};
#define boxvar_ConnectUtil_equSetElementLess MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_equSetElementLess)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setArrayUpdate(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_integer _index, modelica_metatype _element);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setArrayUpdate(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _index, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setArrayUpdate,2,0) {(void*) boxptr_ConnectUtil_setArrayUpdate,0}};
#define boxvar_ConnectUtil_setArrayUpdate MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setArrayUpdate)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_buildElementPrefix(threadData_t *threadData, modelica_metatype _prefix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_buildElementPrefix,2,0) {(void*) boxptr_ConnectUtil_buildElementPrefix,0}};
#define boxvar_ConnectUtil_buildElementPrefix MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_buildElementPrefix)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setArrayAddElement(threadData_t *threadData, modelica_metatype _element, modelica_metatype _prefix, modelica_metatype __omcQ_24in_5Fsets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setArrayAddElement,2,0) {(void*) boxptr_ConnectUtil_setArrayAddElement,0}};
#define boxvar_ConnectUtil_setArrayAddElement MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setArrayAddElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_insertFlowAssociationInStreamElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _flowCref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_insertFlowAssociationInStreamElement,2,0) {(void*) boxptr_ConnectUtil_insertFlowAssociationInStreamElement,0}};
#define boxvar_ConnectUtil_insertFlowAssociationInStreamElement MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_insertFlowAssociationInStreamElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_generateSetArray2(threadData_t *threadData, modelica_metatype _sets, modelica_metatype _prefix, modelica_metatype __omcQ_24in_5FsetArray);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_generateSetArray2,2,0) {(void*) boxptr_ConnectUtil_generateSetArray2,0}};
#define boxvar_ConnectUtil_generateSetArray2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_generateSetArray2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setArrayAddConnection2(threadData_t *threadData, modelica_integer _setPointer, modelica_integer _setPointee, modelica_metatype __omcQ_24in_5Fsets);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setArrayAddConnection2(threadData_t *threadData, modelica_metatype _setPointer, modelica_metatype _setPointee, modelica_metatype __omcQ_24in_5Fsets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setArrayAddConnection2,2,0) {(void*) boxptr_ConnectUtil_setArrayAddConnection2,0}};
#define boxvar_ConnectUtil_setArrayAddConnection2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setArrayAddConnection2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setArrayAddConnection(threadData_t *threadData, modelica_integer _set, modelica_metatype _edges, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype __omcQ_24in_5Fgraph, modelica_metatype *out_graph);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setArrayAddConnection(threadData_t *threadData, modelica_metatype _set, modelica_metatype _edges, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype __omcQ_24in_5Fgraph, modelica_metatype *out_graph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setArrayAddConnection,2,0) {(void*) boxptr_ConnectUtil_setArrayAddConnection,0}};
#define boxvar_ConnectUtil_setArrayAddConnection MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setArrayAddConnection)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addConnectionToGraph(threadData_t *threadData, modelica_metatype _connection, modelica_metatype __omcQ_24in_5Fgraph);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_addConnectionToGraph,2,0) {(void*) boxptr_ConnectUtil_addConnectionToGraph,0}};
#define boxvar_ConnectUtil_addConnectionToGraph MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_addConnectionToGraph)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setArrayAddConnections(threadData_t *threadData, modelica_metatype _connections, modelica_integer _setCount, modelica_metatype __omcQ_24in_5Fsets);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setArrayAddConnections(threadData_t *threadData, modelica_metatype _connections, modelica_metatype _setCount, modelica_metatype __omcQ_24in_5Fsets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setArrayAddConnections,2,0) {(void*) boxptr_ConnectUtil_setArrayAddConnections,0}};
#define boxvar_ConnectUtil_setArrayAddConnections MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setArrayAddConnections)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_generateSetArray(threadData_t *threadData, modelica_metatype _sets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_generateSetArray,2,0) {(void*) boxptr_ConnectUtil_generateSetArray,0}};
#define boxvar_ConnectUtil_generateSetArray MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_generateSetArray)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getOnlyExpandableConnectedCrefs(threadData_t *threadData, modelica_metatype _sets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_getOnlyExpandableConnectedCrefs,2,0) {(void*) boxptr_ConnectUtil_getOnlyExpandableConnectedCrefs,0}};
#define boxvar_ConnectUtil_getOnlyExpandableConnectedCrefs MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_getOnlyExpandableConnectedCrefs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_mergeWithRest(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fset, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _acc, modelica_metatype *out_sets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_mergeWithRest,2,0) {(void*) boxptr_ConnectUtil_mergeWithRest,0}};
#define boxvar_ConnectUtil_mergeWithRest MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_mergeWithRest)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_mergeEquSetsAsCrefs(threadData_t *threadData, modelica_metatype __omcQ_24in_5FsetsAsCrefs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_mergeEquSetsAsCrefs,2,0) {(void*) boxptr_ConnectUtil_mergeEquSetsAsCrefs,0}};
#define boxvar_ConnectUtil_mergeEquSetsAsCrefs MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_mergeEquSetsAsCrefs)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_removeCrefsFromSets2(threadData_t *threadData, modelica_metatype _set, modelica_metatype _nonUsefulExpandable);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_removeCrefsFromSets2(threadData_t *threadData, modelica_metatype _set, modelica_metatype _nonUsefulExpandable);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_removeCrefsFromSets2,2,0) {(void*) boxptr_ConnectUtil_removeCrefsFromSets2,0}};
#define boxvar_ConnectUtil_removeCrefsFromSets2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_removeCrefsFromSets2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_removeCrefsFromSets(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _nonUsefulExpandable);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_removeCrefsFromSets,2,0) {(void*) boxptr_ConnectUtil_removeCrefsFromSets,0}};
#define boxvar_ConnectUtil_removeCrefsFromSets MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_removeCrefsFromSets)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getExpandableEquSetsAsCrefs(threadData_t *threadData, modelica_metatype _sets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_getExpandableEquSetsAsCrefs,2,0) {(void*) boxptr_ConnectUtil_getExpandableEquSetsAsCrefs,0}};
#define boxvar_ConnectUtil_getExpandableEquSetsAsCrefs MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_getExpandableEquSetsAsCrefs)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_setTrieIsNode(threadData_t *threadData, modelica_metatype _node);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setTrieIsNode(threadData_t *threadData, modelica_metatype _node);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieIsNode,2,0) {(void*) boxptr_ConnectUtil_setTrieIsNode,0}};
#define boxvar_ConnectUtil_setTrieIsNode MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieIsNode)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_setTrieLeafNamed(threadData_t *threadData, modelica_string _id, modelica_metatype _node);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setTrieLeafNamed(threadData_t *threadData, modelica_metatype _id, modelica_metatype _node);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieLeafNamed,2,0) {(void*) boxptr_ConnectUtil_setTrieLeafNamed,0}};
#define boxvar_ConnectUtil_setTrieLeafNamed MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieLeafNamed)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieGetLeaf(threadData_t *threadData, modelica_string _id, modelica_metatype _nodes);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieGetLeaf,2,0) {(void*) boxptr_ConnectUtil_setTrieGetLeaf,0}};
#define boxvar_ConnectUtil_setTrieGetLeaf MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieGetLeaf)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_setTrieNodeNamed(threadData_t *threadData, modelica_string _id, modelica_metatype _node);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setTrieNodeNamed(threadData_t *threadData, modelica_metatype _id, modelica_metatype _node);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieNodeNamed,2,0) {(void*) boxptr_ConnectUtil_setTrieNodeNamed,0}};
#define boxvar_ConnectUtil_setTrieNodeNamed MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieNodeNamed)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieGetNode(threadData_t *threadData, modelica_string _id, modelica_metatype _nodes);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieGetNode,2,0) {(void*) boxptr_ConnectUtil_setTrieGetNode,0}};
#define boxvar_ConnectUtil_setTrieGetNode MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieGetNode)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieGet(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _trie, modelica_boolean _matchPrefix);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setTrieGet(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _trie, modelica_metatype _matchPrefix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieGet,2,0) {(void*) boxptr_ConnectUtil_setTrieGet,0}};
#define boxvar_ConnectUtil_setTrieGet MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieGet)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieTraverseLeaves(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fnode, modelica_fnptr _updateFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieTraverseLeaves,2,0) {(void*) boxptr_ConnectUtil_setTrieTraverseLeaves,0}};
#define boxvar_ConnectUtil_setTrieTraverseLeaves MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieTraverseLeaves)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieUpdateLeaf(threadData_t *threadData, modelica_string _id, modelica_metatype _arg, modelica_metatype __omcQ_24in_5Fnodes, modelica_fnptr _updateFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieUpdateLeaf,2,0) {(void*) boxptr_ConnectUtil_setTrieUpdateLeaf,0}};
#define boxvar_ConnectUtil_setTrieUpdateLeaf MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieUpdateLeaf)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieUpdateNode2(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _arg, modelica_fnptr _updateFunc, modelica_metatype __omcQ_24in_5Fnodes);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieUpdateNode2,2,0) {(void*) boxptr_ConnectUtil_setTrieUpdateNode2,0}};
#define boxvar_ConnectUtil_setTrieUpdateNode2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieUpdateNode2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieUpdateNode(threadData_t *threadData, modelica_string _id, modelica_metatype _wholeCref, modelica_metatype _cref, modelica_metatype _arg, modelica_fnptr _updateFunc, modelica_metatype __omcQ_24in_5Fnodes);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieUpdateNode,2,0) {(void*) boxptr_ConnectUtil_setTrieUpdateNode,0}};
#define boxvar_ConnectUtil_setTrieUpdateNode MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieUpdateNode)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieUpdate(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _arg, modelica_metatype __omcQ_24in_5Ftrie, modelica_fnptr _updateFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieUpdate,2,0) {(void*) boxptr_ConnectUtil_setTrieUpdate,0}};
#define boxvar_ConnectUtil_setTrieUpdate MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieUpdate)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_updateSetLeaf(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _cref, modelica_metatype _arg, modelica_fnptr _updateFunc);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_updateSetLeaf,2,0) {(void*) boxptr_ConnectUtil_updateSetLeaf,0}};
#define boxvar_ConnectUtil_updateSetLeaf MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_updateSetLeaf)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieAdd(threadData_t *threadData, modelica_metatype _element, modelica_metatype __omcQ_24in_5Ftrie);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieAdd,2,0) {(void*) boxptr_ConnectUtil_setTrieAdd,0}};
#define boxvar_ConnectUtil_setTrieAdd MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieAdd)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieGetLeafElement(threadData_t *threadData, modelica_metatype _node, modelica_metatype _face);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieGetLeafElement,2,0) {(void*) boxptr_ConnectUtil_setTrieGetLeafElement,0}};
#define boxvar_ConnectUtil_setTrieGetLeafElement MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieGetLeafElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieAddLeafElement(threadData_t *threadData, modelica_metatype _element, modelica_metatype __omcQ_24in_5Fnode);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieAddLeafElement,2,0) {(void*) boxptr_ConnectUtil_setTrieAddLeafElement,0}};
#define boxvar_ConnectUtil_setTrieAddLeafElement MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieAddLeafElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieGetElement(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _face, modelica_metatype _trie);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieGetElement,2,0) {(void*) boxptr_ConnectUtil_setTrieGetElement,0}};
#define boxvar_ConnectUtil_setTrieGetElement MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieGetElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_connectSets(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2, modelica_metatype __omcQ_24in_5Fsets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_connectSets,2,0) {(void*) boxptr_ConnectUtil_connectSets,0}};
#define boxvar_ConnectUtil_connectSets MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_connectSets)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addToSet(threadData_t *threadData, modelica_metatype _element, modelica_metatype _set, modelica_metatype __omcQ_24in_5Fsets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_addToSet,2,0) {(void*) boxptr_ConnectUtil_addToSet,0}};
#define boxvar_ConnectUtil_addToSet MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_addToSet)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addNewSet(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2, modelica_metatype __omcQ_24in_5Fsets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_addNewSet,2,0) {(void*) boxptr_ConnectUtil_addNewSet,0}};
#define boxvar_ConnectUtil_addNewSet MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_addNewSet)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_mergeSets2(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2, modelica_boolean _isNew1, modelica_boolean _isNew2, modelica_metatype __omcQ_24in_5Fsets);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_mergeSets2(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2, modelica_metatype _isNew1, modelica_metatype _isNew2, modelica_metatype __omcQ_24in_5Fsets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_mergeSets2,2,0) {(void*) boxptr_ConnectUtil_mergeSets2,0}};
#define boxvar_ConnectUtil_mergeSets2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_mergeSets2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_mergeSets(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2, modelica_metatype __omcQ_24in_5Fsets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_mergeSets,2,0) {(void*) boxptr_ConnectUtil_mergeSets,0}};
#define boxvar_ConnectUtil_mergeSets MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_mergeSets)
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_setTrieNodeName(threadData_t *threadData, modelica_metatype _node);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieNodeName,2,0) {(void*) boxptr_ConnectUtil_setTrieNodeName,0}};
#define boxvar_ConnectUtil_setTrieNodeName MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieNodeName)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieNewNode(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieNewNode,2,0) {(void*) boxptr_ConnectUtil_setTrieNewNode,0}};
#define boxvar_ConnectUtil_setTrieNewNode MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieNewNode)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieNewLeaf(threadData_t *threadData, modelica_string _id, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieNewLeaf,2,0) {(void*) boxptr_ConnectUtil_setTrieNewLeaf,0}};
#define boxvar_ConnectUtil_setTrieNewLeaf MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setTrieNewLeaf)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getElementSource(threadData_t *threadData, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_getElementSource,2,0) {(void*) boxptr_ConnectUtil_getElementSource,0}};
#define boxvar_ConnectUtil_getElementSource MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_getElementSource)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setElementName(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _name);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setElementName,2,0) {(void*) boxptr_ConnectUtil_setElementName,0}};
#define boxvar_ConnectUtil_setElementName MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setElementName)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getElementName(threadData_t *threadData, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_getElementName,2,0) {(void*) boxptr_ConnectUtil_getElementName,0}};
#define boxvar_ConnectUtil_getElementName MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_getElementName)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setElementSetIndex(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_integer _index);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setElementSetIndex(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _index);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_setElementSetIndex,2,0) {(void*) boxptr_ConnectUtil_setElementSetIndex,0}};
#define boxvar_ConnectUtil_setElementSetIndex MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_setElementSetIndex)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ConnectUtil_getElementSetIndex(threadData_t *threadData, modelica_metatype _inElement);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_getElementSetIndex(threadData_t *threadData, modelica_metatype _inElement);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_getElementSetIndex,2,0) {(void*) boxptr_ConnectUtil_getElementSetIndex,0}};
#define boxvar_ConnectUtil_getElementSetIndex MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_getElementSetIndex)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isNewElement(threadData_t *threadData, modelica_metatype _element);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isNewElement(threadData_t *threadData, modelica_metatype _element);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_isNewElement,2,0) {(void*) boxptr_ConnectUtil_isNewElement,0}};
#define boxvar_ConnectUtil_isNewElement MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_isNewElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_newElement(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _face, modelica_metatype _ty, modelica_metatype _source, modelica_integer _set);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_newElement(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _face, modelica_metatype _ty, modelica_metatype _source, modelica_metatype _set);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_newElement,2,0) {(void*) boxptr_ConnectUtil_newElement,0}};
#define boxvar_ConnectUtil_newElement MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_newElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_findElement(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _face, modelica_metatype _ty, modelica_metatype _source, modelica_metatype _sets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_findElement,2,0) {(void*) boxptr_ConnectUtil_findElement,0}};
#define boxvar_ConnectUtil_findElement MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_findElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_optPrefixCref(threadData_t *threadData, modelica_metatype _prefix, modelica_metatype __omcQ_24in_5Fcref);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_optPrefixCref,2,0) {(void*) boxptr_ConnectUtil_optPrefixCref,0}};
#define boxvar_ConnectUtil_optPrefixCref MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_optPrefixCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_findInnerElement(threadData_t *threadData, modelica_metatype _outerElement, modelica_metatype _innerCref, modelica_metatype _innerFace, modelica_metatype _sets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_findInnerElement,2,0) {(void*) boxptr_ConnectUtil_findInnerElement,0}};
#define boxvar_ConnectUtil_findInnerElement MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_findInnerElement)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_collectOuterElements2(threadData_t *threadData, modelica_metatype _node, modelica_metatype _face, modelica_metatype _prefix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_collectOuterElements2,2,0) {(void*) boxptr_ConnectUtil_collectOuterElements2,0}};
#define boxvar_ConnectUtil_collectOuterElements2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_collectOuterElements2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_collectOuterElements(threadData_t *threadData, modelica_metatype _node, modelica_metatype _face);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_collectOuterElements,2,0) {(void*) boxptr_ConnectUtil_collectOuterElements,0}};
#define boxvar_ConnectUtil_collectOuterElements MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_collectOuterElements)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addOuterConnectToSets2(threadData_t *threadData, modelica_metatype _outerCref, modelica_metatype _innerCref, modelica_metatype _outerFace, modelica_metatype _innerFace, modelica_metatype __omcQ_24in_5Fsets, modelica_boolean *out_added);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_addOuterConnectToSets2(threadData_t *threadData, modelica_metatype _outerCref, modelica_metatype _innerCref, modelica_metatype _outerFace, modelica_metatype _innerFace, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype *out_added);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_addOuterConnectToSets2,2,0) {(void*) boxptr_ConnectUtil_addOuterConnectToSets2,0}};
#define boxvar_ConnectUtil_addOuterConnectToSets2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_addOuterConnectToSets2)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_outerConnectionMatches(threadData_t *threadData, modelica_metatype _oc, modelica_metatype _cr1, modelica_metatype _cr2);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_outerConnectionMatches(threadData_t *threadData, modelica_metatype _oc, modelica_metatype _cr1, modelica_metatype _cr2);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_outerConnectionMatches,2,0) {(void*) boxptr_ConnectUtil_outerConnectionMatches,0}};
#define boxvar_ConnectUtil_outerConnectionMatches MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_outerConnectionMatches)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getStreamFlowAssociation(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _sets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_getStreamFlowAssociation,2,0) {(void*) boxptr_ConnectUtil_getStreamFlowAssociation,0}};
#define boxvar_ConnectUtil_getStreamFlowAssociation MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_getStreamFlowAssociation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addStreamFlowAssociation2(threadData_t *threadData, modelica_metatype _flowCref, modelica_metatype __omcQ_24in_5Fnode);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_addStreamFlowAssociation2,2,0) {(void*) boxptr_ConnectUtil_addStreamFlowAssociation2,0}};
#define boxvar_ConnectUtil_addStreamFlowAssociation2 MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_addStreamFlowAssociation2)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addStreamFlowAssociation(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _flowCref, modelica_metatype __omcQ_24in_5Fsets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_addStreamFlowAssociation,2,0) {(void*) boxptr_ConnectUtil_addStreamFlowAssociation,0}};
#define boxvar_ConnectUtil_addStreamFlowAssociation MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_addStreamFlowAssociation)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addInsideFlowVariable(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _cref, modelica_metatype _source, modelica_metatype _prefix);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_addInsideFlowVariable,2,0) {(void*) boxptr_ConnectUtil_addInsideFlowVariable,0}};
#define boxvar_ConnectUtil_addInsideFlowVariable MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_addInsideFlowVariable)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getNextIndex(threadData_t *threadData, modelica_metatype _dim, modelica_metatype *out_restDim);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_getNextIndex,2,0) {(void*) boxptr_ConnectUtil_getNextIndex,0}};
#define boxvar_ConnectUtil_getNextIndex MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_getNextIndex)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_reverseEnumType(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fdim);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_reverseEnumType,2,0) {(void*) boxptr_ConnectUtil_reverseEnumType,0}};
#define boxvar_ConnectUtil_reverseEnumType MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_reverseEnumType)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_expandArrayCref(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _dims, modelica_metatype _accumCrefs);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_expandArrayCref,2,0) {(void*) boxptr_ConnectUtil_expandArrayCref,0}};
#define boxvar_ConnectUtil_expandArrayCref MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_expandArrayCref)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_daeVarToCrefs(threadData_t *threadData, modelica_metatype _var);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_daeVarToCrefs,2,0) {(void*) boxptr_ConnectUtil_daeVarToCrefs,0}};
#define boxvar_ConnectUtil_daeVarToCrefs MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_daeVarToCrefs)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addStreamFlowAssociations(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _prefix, modelica_metatype _streamVars, modelica_metatype _flowVars);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_addStreamFlowAssociations,2,0) {(void*) boxptr_ConnectUtil_addStreamFlowAssociations,0}};
#define boxvar_ConnectUtil_addStreamFlowAssociations MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_addStreamFlowAssociations)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getStreamAndFlowVariables(threadData_t *threadData, modelica_metatype _variables, modelica_metatype *out_streams);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_getStreamAndFlowVariables,2,0) {(void*) boxptr_ConnectUtil_getStreamAndFlowVariables,0}};
#define boxvar_ConnectUtil_getStreamAndFlowVariables MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_getStreamAndFlowVariables)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getExpandableVariablesWithNoBinding(threadData_t *threadData, modelica_metatype _variables);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_getExpandableVariablesWithNoBinding,2,0) {(void*) boxptr_ConnectUtil_getExpandableVariablesWithNoBinding,0}};
#define boxvar_ConnectUtil_getExpandableVariablesWithNoBinding MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_getExpandableVariablesWithNoBinding)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isVarExpandable(threadData_t *threadData, modelica_metatype _var);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isVarExpandable(threadData_t *threadData, modelica_metatype _var);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_isVarExpandable,2,0) {(void*) boxptr_ConnectUtil_isVarExpandable,0}};
#define boxvar_ConnectUtil_isVarExpandable MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_isVarExpandable)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_daeHasExpandableConnectors(threadData_t *threadData, modelica_metatype _DAE);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_daeHasExpandableConnectors(threadData_t *threadData, modelica_metatype _DAE);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_daeHasExpandableConnectors,2,0) {(void*) boxptr_ConnectUtil_daeHasExpandableConnectors,0}};
#define boxvar_ConnectUtil_daeHasExpandableConnectors MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_daeHasExpandableConnectors)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addFlowVariableFromDAE(threadData_t *threadData, modelica_metatype _variable, modelica_metatype _elementSource, modelica_metatype _prefix, modelica_metatype __omcQ_24in_5Fsets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_addFlowVariableFromDAE,2,0) {(void*) boxptr_ConnectUtil_addFlowVariableFromDAE,0}};
#define boxvar_ConnectUtil_addFlowVariableFromDAE MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_addFlowVariableFromDAE)
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_makeConnectorType(threadData_t *threadData, modelica_metatype _connectorType);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_makeConnectorType,2,0) {(void*) boxptr_ConnectUtil_makeConnectorType,0}};
#define boxvar_ConnectUtil_makeConnectorType MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_makeConnectorType)
PROTECTED_FUNCTION_STATIC modelica_integer omc_ConnectUtil_getConnectCount(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _trie);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_getConnectCount(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _trie);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_getConnectCount,2,0) {(void*) boxptr_ConnectUtil_getConnectCount,0}};
#define boxvar_ConnectUtil_getConnectCount MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_getConnectCount)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isEmptySet(threadData_t *threadData, modelica_metatype _sets);
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isEmptySet(threadData_t *threadData, modelica_metatype _sets);
static const MMC_DEFSTRUCTLIT(boxvar_lit_ConnectUtil_isEmptySet,2,0) {(void*) boxptr_ConnectUtil_isEmptySet,0}};
#define boxvar_ConnectUtil_isEmptySet MMC_REFSTRUCTLIT(boxvar_lit_ConnectUtil_isEmptySet)
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isEquType(threadData_t *threadData, modelica_metatype _ty)
{
modelica_boolean _isEqu;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ty;
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
_isEqu = tmp1;
_return: OMC_LABEL_UNUSED
return _isEqu;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isEquType(threadData_t *threadData, modelica_metatype _ty)
{
modelica_boolean _isEqu;
modelica_metatype out_isEqu;
_isEqu = omc_ConnectUtil_isEquType(threadData, _ty);
out_isEqu = mmc_mk_icon(_isEqu);
return out_isEqu;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_removeUnusedExpandableVariablesAndConnections(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype __omcQ_24in_5FDAE, modelica_metatype *out_DAE)
{
modelica_metatype _sets = NULL;
modelica_metatype _DAE = NULL;
modelica_metatype _elems = NULL;
modelica_metatype _expandableVars = NULL;
modelica_metatype _unnecessary = NULL;
modelica_metatype _usedInDAE = NULL;
modelica_metatype _onlyExpandableConnected = NULL;
modelica_metatype _equVars = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _setsAsCrefs = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_DAE = __omcQ_24in_5FDAE;
tmpMeta[0] = _DAE;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_elems = tmpMeta[1];
_expandableVars = omc_ConnectUtil_getExpandableVariablesWithNoBinding(threadData, _elems);
_dae = omc_DAEUtil_removeVariables(threadData, _DAE, _expandableVars);
_usedInDAE = omc_DAEUtil_getAllExpandableCrefsFromDAE(threadData, _dae);
_setsAsCrefs = omc_ConnectUtil_getExpandableEquSetsAsCrefs(threadData, _sets);
_setsAsCrefs = omc_ConnectUtil_mergeEquSetsAsCrefs(threadData, _setsAsCrefs);
_setsAsCrefs = omc_ConnectUtil_mergeEquSetsAsCrefs(threadData, _setsAsCrefs);
_onlyExpandableConnected = omc_ConnectUtil_getOnlyExpandableConnectedCrefs(threadData, _setsAsCrefs);
_unnecessary = omc_List_setDifferenceOnTrue(threadData, _onlyExpandableConnected, _usedInDAE, boxvar_ComponentReference_crefEqualWithoutSubs);
_DAE = omc_DAEUtil_removeVariables(threadData, _DAE, _unnecessary);
_sets = omc_ConnectUtil_removeCrefsFromSets(threadData, _sets, _unnecessary);
_equVars = omc_ConnectUtil_getAllEquCrefs(threadData, _sets);
_expandableVars = omc_List_setDifferenceOnTrue(threadData, _expandableVars, _usedInDAE, boxvar_ComponentReference_crefEqualWithoutSubs);
_unnecessary = omc_List_setDifferenceOnTrue(threadData, _expandableVars, _equVars, boxvar_ComponentReference_crefEqualWithoutSubs);
_DAE = omc_DAEUtil_removeVariables(threadData, _DAE, _unnecessary);
_return: OMC_LABEL_UNUSED
if (out_DAE) { *out_DAE = _DAE; }
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getAllEquCrefs(threadData_t *threadData, modelica_metatype _sets)
{
modelica_metatype _crefs = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_crefs = tmpMeta[0];
{
modelica_metatype _set;
for (tmpMeta[1] = _sets; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_set = MMC_CAR(tmpMeta[1]);
{
modelica_metatype tmp3_1;
tmp3_1 = _set;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,0) == 0) goto tmp2_end;
{
modelica_metatype _e;
for (tmpMeta[2] = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))); !listEmpty(tmpMeta[2]); tmpMeta[2]=MMC_CDR(tmpMeta[2]))
{
_e = MMC_CAR(tmpMeta[2]);
tmpMeta[3] = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 2))), _crefs);
_crefs = tmpMeta[3];
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
return _crefs;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printSetStr(threadData_t *threadData, modelica_metatype _set)
{
modelica_string _string = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _set;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,2) == 0) goto tmp3_end;
tmp1 = stringDelimitList(omc_List_map(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))), boxvar_ConnectUtil_printElementStr), _OMC_LIT0);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmpMeta[0] = stringAppend(_OMC_LIT1,intString(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2))))));
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
_string = tmp1;
_return: OMC_LABEL_UNUSED
return _string;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printSetConnection(threadData_t *threadData, modelica_metatype _connection)
{
modelica_string _string = NULL;
modelica_integer _set1;
modelica_integer _set2;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_string tmp3;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _connection;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp2 = mmc_unbox_integer(tmpMeta[2]);
_set1 = tmp1;
_set2 = tmp2;
tmp3 = modelica_integer_to_modelica_string(_set1, ((modelica_integer) 0), 1);
tmpMeta[0] = stringAppend(_OMC_LIT2,tmp3);
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT3);
tmpMeta[2] = stringAppend(tmpMeta[1],intString(_set2));
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT4);
_string = tmpMeta[3];
_return: OMC_LABEL_UNUSED
return _string;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printSetConnections(threadData_t *threadData, modelica_metatype _connections)
{
modelica_string _string = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_string = stringAppendList(omc_List_map(threadData, _connections, boxvar_ConnectUtil_printSetConnection));
_return: OMC_LABEL_UNUSED
return _string;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printOptFlowAssociation(threadData_t *threadData, modelica_metatype _cref)
{
modelica_string _string = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _cref;
{
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
tmp1 = _OMC_LIT5;
goto tmp3_done;
}
case 1: {
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_cr = tmpMeta[0];
tmpMeta[0] = stringAppend(_OMC_LIT6,omc_ComponentReference_printComponentRefStr(threadData, _cr));
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
_string = tmp1;
_return: OMC_LABEL_UNUSED
return _string;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printConnectorTypeStr(threadData_t *threadData, modelica_metatype _ty)
{
modelica_string _string = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ty;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT7;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT8;
goto tmp3_done;
}
case 5: {
tmp1 = _OMC_LIT9;
goto tmp3_done;
}
}
goto tmp3_end;
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
DLLExport
modelica_string omc_ConnectUtil_printFaceStr(threadData_t *threadData, modelica_metatype _face)
{
modelica_string _string = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _face;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = _OMC_LIT10;
goto tmp3_done;
}
case 4: {
tmp1 = _OMC_LIT11;
goto tmp3_done;
}
case 5: {
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
DLLExport
modelica_string omc_ConnectUtil_printElementStr(threadData_t *threadData, modelica_metatype _element)
{
modelica_string _string = NULL;
modelica_string tmp1;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = stringAppend(omc_ComponentReference_printComponentRefStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 2)))),_OMC_LIT13);
_string = tmpMeta[0];
tmpMeta[0] = stringAppend(_string,omc_ConnectUtil_printFaceStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)))));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT13);
_string = tmpMeta[1];
tmpMeta[0] = stringAppend(_string,omc_ConnectUtil_printConnectorTypeStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4)))));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT14);
tmp1 = modelica_integer_to_modelica_string(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 6)))), ((modelica_integer) 0), 1);
tmpMeta[2] = stringAppend(tmpMeta[1],tmp1);
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT15);
_string = tmpMeta[3];
_return: OMC_LABEL_UNUSED
return _string;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printLeafElementStr(threadData_t *threadData, modelica_metatype _element)
{
modelica_string _string = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _element;
{
modelica_metatype _e = NULL;
modelica_string _res = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_string tmp6;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
_e = tmpMeta[0];
tmpMeta[0] = stringAppend(_OMC_LIT13,omc_ConnectUtil_printFaceStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 3)))));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT13);
_res = tmpMeta[1];
tmpMeta[0] = stringAppend(_res,omc_ConnectUtil_printConnectorTypeStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 4)))));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT14);
tmp6 = modelica_integer_to_modelica_string(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 6)))), ((modelica_integer) 0), 1);
tmpMeta[2] = stringAppend(tmpMeta[1],tmp6);
tmpMeta[3] = stringAppend(tmpMeta[2],_OMC_LIT15);
tmp1 = tmpMeta[3];
goto tmp3_done;
}
case 1: {
tmp1 = _OMC_LIT5;
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_printSetTrieStr(threadData_t *threadData, modelica_metatype _trie, modelica_string _accumName)
{
modelica_string _string = NULL;
modelica_string tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _trie;
{
modelica_string _name = NULL;
modelica_string _res = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 3; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
tmpMeta[0] = stringAppend(_accumName,_OMC_LIT16);
tmpMeta[1] = stringAppend(tmpMeta[0],(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_trie), 2))));
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT17);
_res = tmpMeta[2];
tmpMeta[0] = stringAppend(_res,omc_ConnectUtil_printLeafElementStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_trie), 3)))));
_res = tmpMeta[0];
tmpMeta[0] = stringAppend(_res,omc_ConnectUtil_printLeafElementStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_trie), 4)))));
_res = tmpMeta[0];
tmpMeta[0] = stringAppend(_res,omc_ConnectUtil_printOptFlowAssociation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_trie), 5)))));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT4);
tmp1 = tmpMeta[1];
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (0 != MMC_STRLEN(tmpMeta[0]) || strcmp(MMC_STRINGDATA(_OMC_LIT5), MMC_STRINGDATA(tmpMeta[0])) != 0) goto tmp3_end;
tmp1 = stringAppendList(omc_List_map1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_trie), 4))), boxvar_ConnectUtil_printSetTrieStr, _accumName));
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmpMeta[0] = stringAppend(_accumName,_OMC_LIT16);
tmpMeta[1] = stringAppend(tmpMeta[0],(MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_trie), 2))));
_name = tmpMeta[1];
tmp1 = stringAppendList(omc_List_map1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_trie), 4))), boxvar_ConnectUtil_printSetTrieStr, _name));
goto tmp3_done;
}
}
goto tmp3_end;
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
DLLExport
modelica_string omc_ConnectUtil_printSetsStr(threadData_t *threadData, modelica_metatype _sets)
{
modelica_string _string = NULL;
modelica_string tmp1;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmp1 = modelica_integer_to_modelica_string(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 3)))), ((modelica_integer) 0), 1);
tmpMeta[0] = stringAppend(tmp1,_OMC_LIT18);
_string = tmpMeta[0];
tmpMeta[0] = stringAppend(_string,omc_ConnectUtil_printSetTrieStr(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))), _OMC_LIT2));
_string = tmpMeta[0];
tmpMeta[0] = stringAppend(_string,_OMC_LIT19);
_string = tmpMeta[0];
tmpMeta[0] = stringAppend(_string,omc_ConnectUtil_printSetConnections(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 4)))));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT4);
_string = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _string;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_removeReferenceFromConnects2(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _element)
{
modelica_boolean _matches;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_matches = omc_ComponentReference_crefPrefixOf(threadData, _cref, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 2))));
_return: OMC_LABEL_UNUSED
return _matches;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_removeReferenceFromConnects2(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _element)
{
modelica_boolean _matches;
modelica_metatype out_matches;
_matches = omc_ConnectUtil_removeReferenceFromConnects2(threadData, _cref, _element);
out_matches = mmc_mk_icon(_matches);
return out_matches;
}
DLLExport
modelica_metatype omc_ConnectUtil_removeReferenceFromConnects(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fconnects, modelica_metatype _cref, modelica_boolean *out_wasRemoved)
{
modelica_metatype _connects = NULL;
modelica_boolean _wasRemoved;
modelica_metatype _oe = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_connects = __omcQ_24in_5Fconnects;
_connects = omc_List_deleteMemberOnTrue(threadData, _cref, _connects, boxvar_ConnectUtil_removeReferenceFromConnects2 ,&_oe);
_wasRemoved = isSome(_oe);
_return: OMC_LABEL_UNUSED
if (out_wasRemoved) { *out_wasRemoved = _wasRemoved; }
return _connects;
}
modelica_metatype boxptr_ConnectUtil_removeReferenceFromConnects(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fconnects, modelica_metatype _cref, modelica_metatype *out_wasRemoved)
{
modelica_boolean _wasRemoved;
modelica_metatype _connects = NULL;
_connects = omc_ConnectUtil_removeReferenceFromConnects(threadData, __omcQ_24in_5Fconnects, _cref, &_wasRemoved);
if (out_wasRemoved) { *out_wasRemoved = mmc_mk_icon(_wasRemoved); }
return _connects;
}
DLLExport
modelica_boolean omc_ConnectUtil_isReferenceInConnects(threadData_t *threadData, modelica_metatype _connects, modelica_metatype _cref)
{
modelica_boolean _isThere;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_isThere = 0;
{
modelica_metatype _ce;
for (tmpMeta[0] = _connects; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_ce = MMC_CAR(tmpMeta[0]);
if(omc_ComponentReference_crefPrefixOf(threadData, _cref, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ce), 2)))))
{
_isThere = 1;
goto _return;
}
}
}
_return: OMC_LABEL_UNUSED
return _isThere;
}
modelica_metatype boxptr_ConnectUtil_isReferenceInConnects(threadData_t *threadData, modelica_metatype _connects, modelica_metatype _cref)
{
modelica_boolean _isThere;
modelica_metatype out_isThere;
_isThere = omc_ConnectUtil_isReferenceInConnects(threadData, _connects, _cref);
out_isThere = mmc_mk_icon(_isThere);
return out_isThere;
}
DLLExport
modelica_boolean omc_ConnectUtil_checkShortConnectorDef(threadData_t *threadData, modelica_metatype _state, modelica_metatype _attributes, modelica_metatype _info)
{
modelica_boolean _isValid;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _state;
tmp4_2 = _attributes;
{
modelica_integer _pv;
modelica_integer _fv;
modelica_integer _sv;
modelica_metatype _ct = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
_pv = ((modelica_integer) 0);
_fv = ((modelica_integer) 0);
_sv = ((modelica_integer) 0);
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,2) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 6));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,0) == 0) goto tmp3_end;
_ct = tmpMeta[0];
if(omc_SCodeUtil_flowBool(threadData, _ct))
{
_fv = ((modelica_integer) 1);
}
else
{
if(omc_SCodeUtil_streamBool(threadData, _ct))
{
_sv = ((modelica_integer) 1);
}
else
{
_pv = ((modelica_integer) 1);
}
}
tmp1 = omc_ConnectUtil_checkConnectorBalance2(threadData, _pv, _fv, _sv, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_state), 2))), _info);
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
_isValid = tmp1;
_return: OMC_LABEL_UNUSED
return _isValid;
}
modelica_metatype boxptr_ConnectUtil_checkShortConnectorDef(threadData_t *threadData, modelica_metatype _state, modelica_metatype _attributes, modelica_metatype _info)
{
modelica_boolean _isValid;
modelica_metatype out_isValid;
_isValid = omc_ConnectUtil_checkShortConnectorDef(threadData, _state, _attributes, _info);
out_isValid = mmc_mk_icon(_isValid);
return out_isValid;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ConnectUtil_sizeOfType(threadData_t *threadData, modelica_metatype _ty)
{
modelica_integer _size;
modelica_integer tmp1 = 0;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _ty;
{
modelica_integer _n;
modelica_metatype _t = NULL;
modelica_metatype _v = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 11; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,3,1) == 0) goto tmp3_end;
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,5,5) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (!optionNone(tmpMeta[0])) goto tmp3_end;
tmp1 = ((modelica_integer) 1);
goto tmp3_done;
}
case 5: {
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,6,2) == 0) goto tmp3_end;
{
int tmp6;
modelica_integer __omcQ_24tmpVar1;
modelica_integer __omcQ_24tmpVar0;
int tmp8;
modelica_metatype _dim_loopVar = 0;
modelica_metatype _dim;
_dim_loopVar = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 3)));
tmp6 = 0;
while(1) {
tmp8 = 1;
if (!listEmpty(_dim_loopVar)) {
_dim = MMC_CAR(_dim_loopVar);
_dim_loopVar = MMC_CDR(_dim_loopVar);
tmp8--;
}
if (tmp8 == 0) {
__omcQ_24tmpVar0 = omc_Expression_dimensionSize(threadData, _dim);
if(tmp6)
{
__omcQ_24tmpVar1 = (__omcQ_24tmpVar0) * (__omcQ_24tmpVar1);
}
else
{
__omcQ_24tmpVar1 = __omcQ_24tmpVar0;
tmp6 = 1;
}
} else if (tmp8 == 1) {
break;
} else {
goto goto_2;
}
}
if (!tmp6) goto goto_2;
tmp7 = __omcQ_24tmpVar1;
}
tmp1 = (tmp7) * (omc_ConnectUtil_sizeOfType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 2)))));
goto tmp3_done;
}
case 6: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!optionNone(tmpMeta[1])) goto tmp3_end;
_v = tmpMeta[0];
tmp1 = omc_ConnectUtil_sizeOfVariableList(threadData, _v);
goto tmp3_done;
}
case 7: {
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,9,3) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (optionNone(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp9 = mmc_unbox_integer(tmpMeta[2]);
_n = tmp9;
tmp1 = _n;
goto tmp3_done;
}
case 8: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (optionNone(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 9: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,10,4) == 0) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
_t = tmpMeta[0];
_ty = _t;
goto _tailrecursive;
goto tmp3_done;
}
case 10: {
modelica_boolean tmp10;
tmp10 = omc_Flags_isSet(threadData, _OMC_LIT23);
if (1 != tmp10) goto goto_2;
tmpMeta[0] = stringAppend(_OMC_LIT24,omc_Types_printTypeStr(threadData, _ty));
omc_Debug_traceln(threadData, tmpMeta[0]);
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
_size = tmp1;
_return: OMC_LABEL_UNUSED
return _size;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sizeOfType(threadData_t *threadData, modelica_metatype _ty)
{
modelica_integer _size;
modelica_metatype out_size;
_size = omc_ConnectUtil_sizeOfType(threadData, _ty);
out_size = mmc_mk_icon(_size);
return out_size;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ConnectUtil_sizeOfVariableList(threadData_t *threadData, modelica_metatype _vars)
{
modelica_integer _size;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_size = ((modelica_integer) 0);
{
modelica_metatype _var;
for (tmpMeta[0] = _vars; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_var = MMC_CAR(tmpMeta[0]);
_size = _size + omc_ConnectUtil_sizeOfType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_var), 4))));
}
}
_return: OMC_LABEL_UNUSED
return _size;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sizeOfVariableList(threadData_t *threadData, modelica_metatype _vars)
{
modelica_integer _size;
modelica_metatype out_size;
_size = omc_ConnectUtil_sizeOfVariableList(threadData, _vars);
out_size = mmc_mk_icon(_size);
return out_size;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ConnectUtil_countConnectorVars(threadData_t *threadData, modelica_metatype _vars, modelica_integer *out_flowVars, modelica_integer *out_streamVars)
{
modelica_integer _potentialVars;
modelica_integer _flowVars;
modelica_integer _streamVars;
modelica_metatype _ty = NULL;
modelica_metatype _ty2 = NULL;
modelica_metatype _attr = NULL;
modelica_integer _n;
modelica_integer _p;
modelica_integer _f;
modelica_integer _s;
modelica_integer tmp1;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_potentialVars = ((modelica_integer) 0);
_flowVars = ((modelica_integer) 0);
_streamVars = ((modelica_integer) 0);
{
modelica_metatype _var;
for (tmpMeta[0] = _vars; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_var = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = _var;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_attr = tmpMeta[2];
_ty = tmpMeta[3];
_ty2 = omc_Types_arrayElementType(threadData, _ty);
if(omc_Types_isConnector(threadData, _ty2))
{
{
modelica_integer __omcQ_24tmpVar3;
modelica_integer __omcQ_24tmpVar2;
int tmp2;
modelica_metatype _dim_loopVar = 0;
modelica_metatype _dim;
_dim_loopVar = omc_Types_getDimensionSizes(threadData, _ty);
__omcQ_24tmpVar3 = ((modelica_integer) 1);
while(1) {
tmp2 = 1;
if (!listEmpty(_dim_loopVar)) {
_dim = MMC_CAR(_dim_loopVar);
_dim_loopVar = MMC_CDR(_dim_loopVar);
tmp2--;
}
if (tmp2 == 0) {
__omcQ_24tmpVar2 = mmc_unbox_integer(_dim);
__omcQ_24tmpVar3 = (__omcQ_24tmpVar3) * (__omcQ_24tmpVar2);
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
tmp1 = __omcQ_24tmpVar3;
}
_n = tmp1;
_p = omc_ConnectUtil_countConnectorVars(threadData, omc_Types_getConnectorVars(threadData, _ty2) ,&_f ,&_s);
if(omc_AbsynUtil_isInputOrOutput(threadData, omc_DAEUtil_getAttrDirection(threadData, _attr)))
{
_p = ((modelica_integer) 0);
}
_potentialVars = _potentialVars + (_p) * (_n);
_flowVars = _flowVars + (_f) * (_n);
_streamVars = _streamVars + (_s) * (_n);
}
else
{
{
modelica_metatype tmp5_1;
tmp5_1 = _attr;
{
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 4; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,0) == 0) goto tmp4_end;
_flowVars = _flowVars + omc_ConnectUtil_sizeOfType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_var), 4))));
goto tmp4_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) goto tmp4_end;
_streamVars = _streamVars + omc_ConnectUtil_sizeOfType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_var), 4))));
goto tmp4_done;
}
case 2: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,0) == 0) goto tmp4_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp5_1), 5));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,0) == 0) goto tmp4_end;
_potentialVars = _potentialVars + omc_ConnectUtil_sizeOfType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_var), 4))));
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
}
_return: OMC_LABEL_UNUSED
if (out_flowVars) { *out_flowVars = _flowVars; }
if (out_streamVars) { *out_streamVars = _streamVars; }
return _potentialVars;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_countConnectorVars(threadData_t *threadData, modelica_metatype _vars, modelica_metatype *out_flowVars, modelica_metatype *out_streamVars)
{
modelica_integer _flowVars;
modelica_integer _streamVars;
modelica_integer _potentialVars;
modelica_metatype out_potentialVars;
_potentialVars = omc_ConnectUtil_countConnectorVars(threadData, _vars, &_flowVars, &_streamVars);
out_potentialVars = mmc_mk_icon(_potentialVars);
if (out_flowVars) { *out_flowVars = mmc_mk_icon(_flowVars); }
if (out_streamVars) { *out_streamVars = mmc_mk_icon(_streamVars); }
return out_potentialVars;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_checkConnectorBalance2(threadData_t *threadData, modelica_integer _potentialVars, modelica_integer _flowVars, modelica_integer _streamVars, modelica_metatype _path, modelica_metatype _info)
{
modelica_boolean _isBalanced;
modelica_string _error_str = NULL;
modelica_string _flow_str = NULL;
modelica_string _potential_str = NULL;
modelica_string _class_str = NULL;
modelica_string tmp1;
modelica_string tmp2;
modelica_string tmp3;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_isBalanced = 1;
if(omc_Config_languageStandardAtMost(threadData, 2))
{
goto _return;
}
if((_potentialVars != _flowVars))
{
tmp1 = modelica_integer_to_modelica_string(_flowVars, ((modelica_integer) 0), 1);
_flow_str = tmp1;
tmp2 = modelica_integer_to_modelica_string(_potentialVars, ((modelica_integer) 0), 1);
_potential_str = tmp2;
_class_str = omc_AbsynUtil_pathString(threadData, _path, _OMC_LIT16, 1, 0);
tmpMeta[0] = mmc_mk_cons(_OMC_LIT25, mmc_mk_cons(_potential_str, mmc_mk_cons(_OMC_LIT26, mmc_mk_cons(_flow_str, mmc_mk_cons(_OMC_LIT27, MMC_REFSTRUCTLIT(mmc_nil))))));
_error_str = stringAppendList(tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_class_str, mmc_mk_cons(_error_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT32, tmpMeta[0], _info);
}
if(((_streamVars > ((modelica_integer) 0)) && (_flowVars != ((modelica_integer) 1))))
{
tmp3 = modelica_integer_to_modelica_string(_flowVars, ((modelica_integer) 0), 1);
_flow_str = tmp3;
_class_str = omc_AbsynUtil_pathString(threadData, _path, _OMC_LIT16, 1, 0);
tmpMeta[0] = mmc_mk_cons(_OMC_LIT33, mmc_mk_cons(_flow_str, mmc_mk_cons(_OMC_LIT34, MMC_REFSTRUCTLIT(mmc_nil))));
_error_str = stringAppendList(tmpMeta[0]);
tmpMeta[0] = mmc_mk_cons(_class_str, mmc_mk_cons(_error_str, MMC_REFSTRUCTLIT(mmc_nil)));
omc_Error_addSourceMessage(threadData, _OMC_LIT38, tmpMeta[0], _info);
_isBalanced = 0;
}
_return: OMC_LABEL_UNUSED
return _isBalanced;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_checkConnectorBalance2(threadData_t *threadData, modelica_metatype _potentialVars, modelica_metatype _flowVars, modelica_metatype _streamVars, modelica_metatype _path, modelica_metatype _info)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_boolean _isBalanced;
modelica_metatype out_isBalanced;
tmp1 = mmc_unbox_integer(_potentialVars);
tmp2 = mmc_unbox_integer(_flowVars);
tmp3 = mmc_unbox_integer(_streamVars);
_isBalanced = omc_ConnectUtil_checkConnectorBalance2(threadData, tmp1, tmp2, tmp3, _path, _info);
out_isBalanced = mmc_mk_icon(_isBalanced);
return out_isBalanced;
}
DLLExport
void omc_ConnectUtil_checkConnectorBalance(threadData_t *threadData, modelica_metatype _vars, modelica_metatype _path, modelica_metatype _info)
{
modelica_integer _potentials;
modelica_integer _flows;
modelica_integer _streams;
modelica_boolean tmp1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_potentials = omc_ConnectUtil_countConnectorVars(threadData, _vars ,&_flows ,&_streams);
tmp1 = omc_ConnectUtil_checkConnectorBalance2(threadData, _potentials, _flows, _streams, _path, _info);
if (1 != tmp1) MMC_THROW_INTERNAL();
_return: OMC_LABEL_UNUSED
return;
}
DLLExport
modelica_metatype omc_ConnectUtil_componentFaceType(threadData_t *threadData, modelica_metatype _inComponentRef)
{
modelica_metatype _outFace = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _inComponentRef;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT39;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],9,3) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,2) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT39;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],6,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],9,3) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],5,2) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT39;
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT40;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outFace = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outFace;
}
DLLExport
modelica_metatype omc_ConnectUtil_componentFace(threadData_t *threadData, modelica_metatype _env, modelica_metatype _componentRef)
{
modelica_metatype _face = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _componentRef;
{
modelica_string _id = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
tmp3 += 2;
tmpMeta[0] = _OMC_LIT39;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_id = tmpMeta[1];
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
omc_Lookup_lookupVar(threadData, omc_FCore_emptyCache(threadData), _env, omc_ComponentReference_makeCrefIdent(threadData, _id, _OMC_LIT41, tmpMeta[3]), NULL, &tmpMeta[1], NULL, NULL, NULL, NULL, NULL, NULL);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],9,3) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],5,2) == 0) goto goto_1;
tmpMeta[0] = _OMC_LIT39;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[0] = _OMC_LIT40;
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
_face = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _face;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_compareCrefStreamSet(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _element)
{
modelica_boolean _matches;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_matches = omc_ComponentReference_crefEqualNoStringCompare(threadData, _cref, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 2))));
_return: OMC_LABEL_UNUSED
return _matches;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_compareCrefStreamSet(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _element)
{
modelica_boolean _matches;
modelica_metatype out_matches;
_matches = omc_ConnectUtil_compareCrefStreamSet(threadData, _cref, _element);
out_matches = mmc_mk_icon(_matches);
return out_matches;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_removeStreamSetElement(threadData_t *threadData, modelica_metatype _cref, modelica_metatype __omcQ_24in_5Felements)
{
modelica_metatype _elements = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_elements = __omcQ_24in_5Felements;
_elements = omc_List_deleteMemberOnTrue(threadData, _cref, _elements, boxvar_ConnectUtil_compareCrefStreamSet, NULL);
_return: OMC_LABEL_UNUSED
return _elements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_simplifyDAEIfEquation(threadData_t *threadData, modelica_metatype _conditions, modelica_metatype _branches, modelica_metatype _elseBranch)
{
modelica_metatype _elements = NULL;
modelica_boolean _cond_value;
modelica_metatype _rest_branches = NULL;
modelica_integer tmp1;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_rest_branches = _branches;
{
modelica_metatype _cond;
for (tmpMeta[0] = _conditions; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_cond = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = _cond;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp1 = mmc_unbox_integer(tmpMeta[2]);
_cond_value = tmp1;
if(((!_cond_value && !1) || (_cond_value && 1)))
{
_elements = listReverse(listHead(_rest_branches));
goto _return;
}
_rest_branches = listRest(_rest_branches);
}
}
_elements = listReverse(_elseBranch);
_return: OMC_LABEL_UNUSED
return _elements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_simplifyDAEElement(threadData_t *threadData, modelica_metatype _element)
{
modelica_metatype _elements = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _element;
{
modelica_metatype _conds = NULL;
modelica_metatype _branches = NULL;
modelica_metatype _else_branch = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,12,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_conds = tmpMeta[1];
_branches = tmpMeta[2];
_else_branch = tmpMeta[3];
tmp3 += 2;
tmpMeta[0] = omc_ConnectUtil_simplifyDAEIfEquation(threadData, _conds, _branches, _else_branch);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,13,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
_conds = tmpMeta[1];
_branches = tmpMeta[2];
_else_branch = tmpMeta[3];
tmp3 += 1;
tmpMeta[0] = omc_ConnectUtil_simplifyDAEIfEquation(threadData, _conds, _branches, _else_branch);
goto tmp2_done;
}
case 2: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,19,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],3,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
if (1 != tmp5) goto tmp2_end;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 3: {
tmpMeta[1] = mmc_mk_cons(_element, MMC_REFSTRUCTLIT(mmc_nil));
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
_elements = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _elements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_simplifyDAEElements(threadData_t *threadData, modelica_boolean _hasCardinality, modelica_metatype __omcQ_24in_5FDAE)
{
modelica_metatype _DAE = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_DAE = __omcQ_24in_5FDAE;
if(_hasCardinality)
{
tmpMeta[0] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, omc_List_mapFlat(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_DAE), 2))), boxvar_ConnectUtil_simplifyDAEElement));
_DAE = tmpMeta[0];
}
_return: OMC_LABEL_UNUSED
return _DAE;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_simplifyDAEElements(threadData_t *threadData, modelica_metatype _hasCardinality, modelica_metatype __omcQ_24in_5FDAE)
{
modelica_integer tmp1;
modelica_metatype _DAE = NULL;
tmp1 = mmc_unbox_integer(_hasCardinality);
_DAE = omc_ConnectUtil_simplifyDAEElements(threadData, tmp1, __omcQ_24in_5FDAE);
return _DAE;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_evaluateCardinality(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _sets)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(omc_ConnectUtil_getConnectCount(threadData, _cref, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))))));
_exp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ConnectUtil_evaluateFlowDirection(threadData_t *threadData, modelica_metatype _ty)
{
modelica_integer _direction;
modelica_metatype _attr = NULL;
modelica_metatype _min_oval = NULL;
modelica_metatype _max_oval = NULL;
modelica_real _min_val;
modelica_real _max_val;
modelica_integer tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_direction = ((modelica_integer) 0);
_attr = omc_Types_getAttributes(threadData, _ty);
if(listEmpty(_attr))
{
goto _return;
}
_min_oval = omc_Types_lookupAttributeValue(threadData, _attr, _OMC_LIT42);
_max_oval = omc_Types_lookupAttributeValue(threadData, _attr, _OMC_LIT43);
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _min_oval;
tmp4_2 = _max_oval;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 5; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!optionNone(tmp4_1)) goto tmp3_end;
if (!optionNone(tmp4_2)) goto tmp3_end;
tmp1 = ((modelica_integer) 0);
goto tmp3_done;
}
case 1: {
modelica_real tmp6;
if (!optionNone(tmp4_2)) goto tmp3_end;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp6 = mmc_unbox_real(tmpMeta[1]);
_min_val = tmp6;
tmp1 = ((_min_val >= 0.0)?((modelica_integer) 1):((modelica_integer) 0));
goto tmp3_done;
}
case 2: {
modelica_real tmp7;
if (!optionNone(tmp4_1)) goto tmp3_end;
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp7 = mmc_unbox_real(tmpMeta[1]);
_max_val = tmp7;
tmp1 = ((_max_val <= 0.0)?((modelica_integer) -1):((modelica_integer) 0));
goto tmp3_done;
}
case 3: {
modelica_real tmp8;
modelica_real tmp9;
if (optionNone(tmp4_1)) goto tmp3_end;
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,1) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp8 = mmc_unbox_real(tmpMeta[1]);
if (optionNone(tmp4_2)) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_2), 1));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
tmp9 = mmc_unbox_real(tmpMeta[3]);
_min_val = tmp8;
_max_val = tmp9;
tmp1 = (((_min_val >= 0.0) && (_max_val >= _min_val))?((modelica_integer) 1):(((_max_val <= 0.0) && (_min_val <= _max_val))?((modelica_integer) -1):((modelica_integer) 0)));
goto tmp3_done;
}
case 4: {
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
_direction = tmp1;
_return: OMC_LABEL_UNUSED
return _direction;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_evaluateFlowDirection(threadData_t *threadData, modelica_metatype _ty)
{
modelica_integer _direction;
modelica_metatype out_direction;
_direction = omc_ConnectUtil_evaluateFlowDirection(threadData, _ty);
out_direction = mmc_mk_icon(_direction);
return out_direction;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_evaluateActualStream(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _sets, modelica_metatype _setArray, modelica_real _flowThreshold)
{
modelica_metatype _exp = NULL;
modelica_metatype _flow_cr = NULL;
modelica_metatype _e = NULL;
modelica_metatype _flow_exp = NULL;
modelica_metatype _stream_exp = NULL;
modelica_metatype _instream_exp = NULL;
modelica_metatype _rel_exp = NULL;
modelica_metatype _ety = NULL;
modelica_integer _flow_dir;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_flow_cr = omc_ConnectUtil_getStreamFlowAssociation(threadData, _streamCref, _sets);
_ety = omc_ComponentReference_crefLastType(threadData, _flow_cr);
_flow_dir = omc_ConnectUtil_evaluateFlowDirection(threadData, _ety);
if((_flow_dir == ((modelica_integer) 1)))
{
_rel_exp = omc_ConnectUtil_evaluateInStream(threadData, _streamCref, _sets, _setArray, _flowThreshold);
}
else
{
if((_flow_dir == ((modelica_integer) -1)))
{
_rel_exp = omc_Expression_crefExp(threadData, _streamCref);
}
else
{
_flow_exp = omc_Expression_crefExp(threadData, _flow_cr);
_stream_exp = omc_Expression_crefExp(threadData, _streamCref);
_instream_exp = omc_ConnectUtil_evaluateInStream(threadData, _streamCref, _sets, _setArray, _flowThreshold);
tmpMeta[0] = mmc_mk_box2(30, &DAE_Operator_GREATER__desc, _ety);
tmpMeta[1] = mmc_mk_box6(14, &DAE_Exp_RELATION__desc, _flow_exp, tmpMeta[0], _OMC_LIT45, mmc_mk_integer(((modelica_integer) -1)), mmc_mk_none());
tmpMeta[2] = mmc_mk_box4(15, &DAE_Exp_IFEXP__desc, tmpMeta[1], _instream_exp, _stream_exp);
_rel_exp = tmpMeta[2];
}
}
tmpMeta[0] = mmc_mk_cons(_OMC_LIT48, mmc_mk_cons(_rel_exp, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[1] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT47, tmpMeta[0], _OMC_LIT52);
_exp = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_evaluateActualStream(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _sets, modelica_metatype _setArray, modelica_metatype _flowThreshold)
{
modelica_real tmp1;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_real(_flowThreshold);
_exp = omc_ConnectUtil_evaluateActualStream(threadData, _streamCref, _sets, _setArray, tmp1);
return _exp;
}
static modelica_metatype closure0_ConnectUtil_isZeroFlowMinMax(threadData_t *thData, modelica_metatype closure, modelica_metatype element)
{
modelica_metatype streamCref = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
return boxptr_ConnectUtil_isZeroFlowMinMax(thData, streamCref, element);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_generateInStreamExp(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _streams, modelica_metatype _sets, modelica_metatype _setArray, modelica_real _flowThreshold)
{
modelica_metatype _exp = NULL;
modelica_metatype _reducedStreams = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box1(0, _streamCref);
_reducedStreams = omc_List_filterOnFalse(threadData, _streams, (modelica_fnptr) mmc_mk_box2(0,closure0_ConnectUtil_isZeroFlowMinMax,tmpMeta[0]));
{
modelica_metatype tmp3_1;
tmp3_1 = _reducedStreams;
{
modelica_metatype _c = NULL;
modelica_metatype _f1 = NULL;
modelica_metatype _f2 = NULL;
modelica_metatype _e = NULL;
modelica_metatype _expr = NULL;
modelica_metatype _inside = NULL;
modelica_metatype _outside = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],0,0) == 0) goto tmp2_end;
if (!listEmpty(tmpMeta[2])) goto tmp2_end;
_c = tmpMeta[3];
tmpMeta[0] = omc_Expression_crefExp(threadData, _c);
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,0) == 0) goto tmp2_end;
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[2]);
tmpMeta[5] = MMC_CDR(tmpMeta[2]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],0,0) == 0) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[1] = omc_ConnectUtil_removeStreamSetElement(threadData, _streamCref, _reducedStreams);
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (!listEmpty(tmpMeta[3])) goto goto_1;
_c = tmpMeta[4];
tmpMeta[0] = omc_Expression_crefExp(threadData, _c);
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[2]);
tmpMeta[5] = MMC_CDR(tmpMeta[2]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
_f1 = tmpMeta[3];
_f2 = tmpMeta[6];
if (!(!omc_ConnectUtil_faceEqual(threadData, _f1, _f2))) goto tmp2_end;
tmpMeta[1] = omc_ConnectUtil_removeStreamSetElement(threadData, _streamCref, _reducedStreams);
if (listEmpty(tmpMeta[1])) goto goto_1;
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (!listEmpty(tmpMeta[3])) goto goto_1;
_c = tmpMeta[4];
tmpMeta[0] = omc_ConnectUtil_evaluateInStream(threadData, _c, _sets, _setArray, _flowThreshold);
goto tmp2_done;
}
case 3: {
_outside = omc_List_splitOnTrue(threadData, _reducedStreams, boxvar_ConnectUtil_isOutsideElement ,&_inside);
_inside = omc_ConnectUtil_removeStreamSetElement(threadData, _streamCref, _inside);
_e = omc_ConnectUtil_streamSumEquationExp(threadData, _outside, _inside, _flowThreshold);
if((!listEmpty(_inside)))
{
_expr = omc_ConnectUtil_streamFlowExp(threadData, omc_List_first(threadData, _inside), NULL);
tmpMeta[1] = mmc_mk_cons(_e, mmc_mk_cons(_expr, MMC_REFSTRUCTLIT(mmc_nil)));
_e = omc_Expression_makePureBuiltinCall(threadData, _OMC_LIT53, tmpMeta[1], omc_Expression_typeof(threadData, _e));
}
tmpMeta[0] = omc_ConnectUtil_evaluateConnectionOperators2(threadData, _e, _sets, _setArray, 0, _flowThreshold, NULL);
goto tmp2_done;
}
}
goto tmp2_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_generateInStreamExp(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _streams, modelica_metatype _sets, modelica_metatype _setArray, modelica_metatype _flowThreshold)
{
modelica_real tmp1;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_real(_flowThreshold);
_exp = omc_ConnectUtil_generateInStreamExp(threadData, _streamCref, _streams, _sets, _setArray, tmp1);
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_evaluateInStream(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _sets, modelica_metatype _setArray, modelica_real _flowThreshold)
{
modelica_metatype _exp = NULL;
modelica_metatype _e = NULL;
modelica_metatype _sl = NULL;
modelica_integer _set;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
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
modelica_integer tmp5;
_e = omc_ConnectUtil_findElement(threadData, _streamCref, _OMC_LIT40, _OMC_LIT54, _OMC_LIT57, _sets);
if(omc_ConnectUtil_isNewElement(threadData, _e))
{
tmpMeta[0] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
_sl = tmpMeta[0];
}
else
{
tmpMeta[0] = _e;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmp5 = mmc_unbox_integer(tmpMeta[1]);
_set = tmp5;
tmpMeta[0] = omc_ConnectUtil_setArrayGet(threadData, _setArray, _set);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,2) == 0) goto goto_1;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) goto goto_1;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
_sl = tmpMeta[2];
}
_exp = omc_ConnectUtil_generateInStreamExp(threadData, _streamCref, _sl, _sets, _setArray, _flowThreshold);
goto tmp2_done;
}
case 1: {
modelica_boolean tmp6;
tmp6 = omc_Flags_isSet(threadData, _OMC_LIT23);
if (1 != tmp6) goto goto_1;
tmpMeta[0] = stringAppend(_OMC_LIT58,omc_ComponentReference_crefStr(threadData, _streamCref));
tmpMeta[1] = stringAppend(tmpMeta[0],_OMC_LIT4);
omc_Debug_traceln(threadData, tmpMeta[1]);
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
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_evaluateInStream(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _sets, modelica_metatype _setArray, modelica_metatype _flowThreshold)
{
modelica_real tmp1;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_real(_flowThreshold);
_exp = omc_ConnectUtil_evaluateInStream(threadData, _streamCref, _sets, _setArray, tmp1);
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_mkArrayIfNeeded(threadData_t *threadData, modelica_metatype _ty, modelica_metatype __omcQ_24in_5Fexp)
{
modelica_metatype _exp = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
_exp = omc_Expression_arrayFill(threadData, omc_Types_getDimensions(threadData, _ty), _exp);
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_evaluateConnectionOperatorsExp(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype _sets, modelica_metatype _setArray, modelica_real _flowThreshold, modelica_boolean __omcQ_24in_5Fchanged, modelica_boolean *out_changed)
{
modelica_metatype _exp = NULL;
modelica_boolean _changed;
modelica_boolean tmp1_c1 __attribute__((unused)) = 0;
modelica_metatype tmpMeta[8] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
_changed = __omcQ_24in_5Fchanged;
{
modelica_metatype tmp4_1;
tmp4_1 = _exp;
{
modelica_metatype _cr = NULL;
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (8 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT59), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (!listEmpty(tmpMeta[6])) goto tmp3_end;
_cr = tmpMeta[7];
_e = omc_ConnectUtil_evaluateInStream(threadData, _cr, _sets, _setArray, _flowThreshold);
tmpMeta[0+0] = _e;
tmp1_c1 = 1;
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (12 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT60), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (!listEmpty(tmpMeta[6])) goto tmp3_end;
_cr = tmpMeta[7];
_e = omc_ConnectUtil_evaluateActualStream(threadData, _cr, _sets, _setArray, _flowThreshold);
tmpMeta[0+0] = _e;
tmp1_c1 = 1;
goto tmp3_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,13,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,1) == 0) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 2));
if (11 != MMC_STRLEN(tmpMeta[3]) || strcmp(MMC_STRINGDATA(_OMC_LIT61), MMC_STRINGDATA(tmpMeta[3])) != 0) goto tmp3_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[4])) goto tmp3_end;
tmpMeta[5] = MMC_CAR(tmpMeta[4]);
tmpMeta[6] = MMC_CDR(tmpMeta[4]);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[5],6,2) == 0) goto tmp3_end;
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
if (!listEmpty(tmpMeta[6])) goto tmp3_end;
_cr = tmpMeta[7];
_e = omc_ConnectUtil_evaluateCardinality(threadData, _cr, _sets);
tmpMeta[0+0] = _e;
tmp1_c1 = 1;
goto tmp3_done;
}
case 3: {
tmpMeta[0+0] = _exp;
tmp1_c1 = _changed;
goto tmp3_done;
}
}
goto tmp3_end;
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
_changed = tmp1_c1;
_return: OMC_LABEL_UNUSED
if (out_changed) { *out_changed = _changed; }
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_evaluateConnectionOperatorsExp(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype _sets, modelica_metatype _setArray, modelica_metatype _flowThreshold, modelica_metatype __omcQ_24in_5Fchanged, modelica_metatype *out_changed)
{
modelica_real tmp1;
modelica_integer tmp2;
modelica_boolean _changed;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_real(_flowThreshold);
tmp2 = mmc_unbox_integer(__omcQ_24in_5Fchanged);
_exp = omc_ConnectUtil_evaluateConnectionOperatorsExp(threadData, __omcQ_24in_5Fexp, _sets, _setArray, tmp1, tmp2, &_changed);
if (out_changed) { *out_changed = mmc_mk_icon(_changed); }
return _exp;
}
static modelica_metatype closure1_ConnectUtil_evaluateConnectionOperatorsExp(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_changed, modelica_metatype tmp2)
{
modelica_metatype sets = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype setArray = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
modelica_metatype flowThreshold = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),3));
return boxptr_ConnectUtil_evaluateConnectionOperatorsExp(thData, $in_exp, sets, setArray, flowThreshold, $in_changed, tmp2);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_evaluateConnectionOperators2(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _setArray, modelica_boolean _hasCardinality, modelica_real _flowThreshold, modelica_metatype *out_sets)
{
modelica_metatype _exp = NULL;
modelica_metatype _sets = NULL;
modelica_boolean _changed;
modelica_integer tmp1;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = __omcQ_24in_5Fexp;
_sets = __omcQ_24in_5Fsets;
tmpMeta[1] = mmc_mk_box3(0, _sets, _setArray, mmc_mk_real(_flowThreshold));
tmpMeta[2] = omc_Expression_traverseExpBottomUp(threadData, _exp, (modelica_fnptr) mmc_mk_box2(0,closure1_ConnectUtil_evaluateConnectionOperatorsExp,tmpMeta[1]), mmc_mk_boolean(0), &tmpMeta[0]);
_exp = tmpMeta[2];
tmp1 = mmc_unbox_integer(tmpMeta[0]);
_changed = tmp1;
if((_changed && _hasCardinality))
{
_exp = omc_ExpressionSimplify_simplify(threadData, _exp, NULL);
}
_return: OMC_LABEL_UNUSED
if (out_sets) { *out_sets = _sets; }
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_evaluateConnectionOperators2(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fexp, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _setArray, modelica_metatype _hasCardinality, modelica_metatype _flowThreshold, modelica_metatype *out_sets)
{
modelica_integer tmp1;
modelica_real tmp2;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_integer(_hasCardinality);
tmp2 = mmc_unbox_real(_flowThreshold);
_exp = omc_ConnectUtil_evaluateConnectionOperators2(threadData, __omcQ_24in_5Fexp, __omcQ_24in_5Fsets, _setArray, tmp1, tmp2, out_sets);
return _exp;
}
static modelica_metatype closure2_ConnectUtil_evaluateConnectionOperators2(threadData_t *thData, modelica_metatype closure, modelica_metatype $in_exp, modelica_metatype $in_sets, modelica_metatype tmp1)
{
modelica_metatype setArray = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),1));
modelica_metatype hasCardinality = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),2));
modelica_metatype flowThreshold = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(closure),3));
return boxptr_ConnectUtil_evaluateConnectionOperators2(thData, $in_exp, $in_sets, setArray, hasCardinality, flowThreshold, tmp1);
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_evaluateConnectionOperators(threadData_t *threadData, modelica_metatype _sets, modelica_metatype _setArray, modelica_metatype __omcQ_24in_5FDAE)
{
modelica_metatype _DAE = NULL;
modelica_real _flow_threshold;
modelica_boolean _has_cardinality;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_DAE = __omcQ_24in_5FDAE;
_has_cardinality = omc_System_getUsesCardinality(threadData);
if((omc_System_getHasStreamConnectors(threadData) || _has_cardinality))
{
_flow_threshold = omc_Flags_getConfigReal(threadData, _OMC_LIT68);
tmpMeta[0] = mmc_mk_box3(0, _setArray, mmc_mk_boolean(_has_cardinality), mmc_mk_real(_flow_threshold));
_DAE = omc_DAEUtil_traverseDAE(threadData, _DAE, _OMC_LIT69, (modelica_fnptr) mmc_mk_box2(0,closure2_ConnectUtil_evaluateConnectionOperators2,tmpMeta[0]), _sets, NULL, NULL);
_DAE = omc_ConnectUtil_simplifyDAEElements(threadData, _has_cardinality, _DAE);
}
_return: OMC_LABEL_UNUSED
return _DAE;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_makePositiveMaxCall(threadData_t *threadData, modelica_metatype _flowExp, modelica_metatype _flowThreshold)
{
modelica_metatype _positiveMaxCall = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _attr = NULL;
modelica_metatype _nominal_oexp = NULL;
modelica_metatype _nominal_exp = NULL;
modelica_metatype _flow_threshold = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ty = omc_Expression_typeof(threadData, _flowExp);
_nominal_oexp = omc_Types_lookupAttributeExp(threadData, omc_Types_getAttributes(threadData, _ty), _OMC_LIT70);
if(isSome(_nominal_oexp))
{
tmpMeta[0] = _nominal_oexp;
if (optionNone(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
_nominal_exp = tmpMeta[1];
_flow_threshold = omc_Expression_expMul(threadData, _flowThreshold, _nominal_exp);
}
else
{
_flow_threshold = _flowThreshold;
}
tmpMeta[0] = mmc_mk_cons(_flowExp, mmc_mk_cons(_flow_threshold, MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[1] = mmc_mk_box8(3, &DAE_CallAttributes_CALL__ATTR__desc, _ty, mmc_mk_boolean(0), mmc_mk_boolean(1), mmc_mk_boolean(0), mmc_mk_boolean(0), _OMC_LIT50, _OMC_LIT51);
tmpMeta[2] = mmc_mk_box4(16, &DAE_Exp_CALL__desc, _OMC_LIT72, tmpMeta[0], tmpMeta[1]);
_positiveMaxCall = tmpMeta[2];
setGlobalRoot(((modelica_integer) 27), _OMC_LIT73);
_return: OMC_LABEL_UNUSED
return _positiveMaxCall;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_makeInStreamCall(threadData_t *threadData, modelica_metatype _streamExp)
{
modelica_metatype _inStreamCall = NULL;
modelica_metatype _ty = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_ty = omc_Expression_typeof(threadData, _streamExp);
tmpMeta[0] = mmc_mk_cons(_streamExp, MMC_REFSTRUCTLIT(mmc_nil));
_inStreamCall = omc_Expression_makeBuiltinCall(threadData, _OMC_LIT59, tmpMeta[0], _ty, 0);
_return: OMC_LABEL_UNUSED
return _inStreamCall;
}
DLLExport
modelica_boolean omc_ConnectUtil_faceEqual(threadData_t *threadData, modelica_metatype _face1, modelica_metatype _face2)
{
modelica_boolean _sameFaces;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sameFaces = (valueConstructor(_face1) == valueConstructor(_face2));
_return: OMC_LABEL_UNUSED
return _sameFaces;
}
modelica_metatype boxptr_ConnectUtil_faceEqual(threadData_t *threadData, modelica_metatype _face1, modelica_metatype _face2)
{
modelica_boolean _sameFaces;
modelica_metatype out_sameFaces;
_sameFaces = omc_ConnectUtil_faceEqual(threadData, _face1, _face2);
out_sameFaces = mmc_mk_icon(_sameFaces);
return out_sameFaces;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_sumInside2(threadData_t *threadData, modelica_metatype _element, modelica_real _flowThreshold)
{
modelica_metatype _exp = NULL;
modelica_metatype _flow_exp = NULL;
modelica_metatype _flowTy = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_flow_exp = omc_ConnectUtil_flowExp(threadData, _element);
_flowTy = omc_Expression_typeof(threadData, _flow_exp);
tmpMeta[0] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _flowTy);
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[0], _flow_exp);
_flow_exp = tmpMeta[1];
tmpMeta[0] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_flowThreshold));
_exp = omc_ConnectUtil_makePositiveMaxCall(threadData, _flow_exp, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sumInside2(threadData_t *threadData, modelica_metatype _element, modelica_metatype _flowThreshold)
{
modelica_real tmp1;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_real(_flowThreshold);
_exp = omc_ConnectUtil_sumInside2(threadData, _element, tmp1);
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_sumOutside2(threadData_t *threadData, modelica_metatype _element, modelica_real _flowThreshold)
{
modelica_metatype _exp = NULL;
modelica_metatype _flow_exp = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_flow_exp = omc_ConnectUtil_flowExp(threadData, _element);
tmpMeta[0] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_flowThreshold));
_exp = omc_ConnectUtil_makePositiveMaxCall(threadData, _flow_exp, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sumOutside2(threadData_t *threadData, modelica_metatype _element, modelica_metatype _flowThreshold)
{
modelica_real tmp1;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_real(_flowThreshold);
_exp = omc_ConnectUtil_sumOutside2(threadData, _element, tmp1);
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_sumInside1(threadData_t *threadData, modelica_metatype _element, modelica_real _flowThreshold)
{
modelica_metatype _exp = NULL;
modelica_metatype _stream_exp = NULL;
modelica_metatype _flow_exp = NULL;
modelica_metatype _flow_threshold = NULL;
modelica_metatype _flowTy = NULL;
modelica_metatype _streamTy = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_stream_exp = omc_ConnectUtil_streamFlowExp(threadData, _element ,&_flow_exp);
_flowTy = omc_Expression_typeof(threadData, _flow_exp);
tmpMeta[0] = mmc_mk_box2(8, &DAE_Operator_UMINUS__desc, _flowTy);
tmpMeta[1] = mmc_mk_box3(11, &DAE_Exp_UNARY__desc, tmpMeta[0], _flow_exp);
_flow_exp = tmpMeta[1];
tmpMeta[0] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_flowThreshold));
_flow_threshold = tmpMeta[0];
_exp = omc_Expression_expMul(threadData, omc_ConnectUtil_makePositiveMaxCall(threadData, _flow_exp, _flow_threshold), _stream_exp);
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sumInside1(threadData_t *threadData, modelica_metatype _element, modelica_metatype _flowThreshold)
{
modelica_real tmp1;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_real(_flowThreshold);
_exp = omc_ConnectUtil_sumInside1(threadData, _element, tmp1);
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_sumOutside1(threadData_t *threadData, modelica_metatype _element, modelica_real _flowThreshold)
{
modelica_metatype _exp = NULL;
modelica_metatype _stream_exp = NULL;
modelica_metatype _flow_exp = NULL;
modelica_metatype _flow_threshold = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_stream_exp = omc_ConnectUtil_streamFlowExp(threadData, _element ,&_flow_exp);
tmpMeta[0] = mmc_mk_box2(4, &DAE_Exp_RCONST__desc, mmc_mk_real(_flowThreshold));
_flow_threshold = tmpMeta[0];
_exp = omc_Expression_expMul(threadData, omc_ConnectUtil_makePositiveMaxCall(threadData, _flow_exp, _flow_threshold), omc_ConnectUtil_makeInStreamCall(threadData, _stream_exp));
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sumOutside1(threadData_t *threadData, modelica_metatype _element, modelica_metatype _flowThreshold)
{
modelica_real tmp1;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_real(_flowThreshold);
_exp = omc_ConnectUtil_sumOutside1(threadData, _element, tmp1);
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_flowExp(threadData_t *threadData, modelica_metatype _element)
{
modelica_metatype _flowExp = NULL;
modelica_metatype _flow_cr = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _element;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (optionNone(tmpMeta[2])) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_flow_cr = tmpMeta[3];
_flowExp = omc_Expression_crefExp(threadData, _flow_cr);
_return: OMC_LABEL_UNUSED
return _flowExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_streamFlowExp(threadData_t *threadData, modelica_metatype _element, modelica_metatype *out_flowExp)
{
modelica_metatype _streamExp = NULL;
modelica_metatype _flowExp = NULL;
modelica_metatype _flow_cr = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _element;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (optionNone(tmpMeta[2])) MMC_THROW_INTERNAL();
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[2]), 1));
_flow_cr = tmpMeta[3];
_streamExp = omc_Expression_crefExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 2))));
_flowExp = omc_Expression_crefExp(threadData, _flow_cr);
_return: OMC_LABEL_UNUSED
if (out_flowExp) { *out_flowExp = _flowExp; }
return _streamExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_sumMap(threadData_t *threadData, modelica_metatype _elements, modelica_fnptr _func, modelica_real _flowThreshold)
{
modelica_metatype _exp = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
int tmp1;
modelica_metatype __omcQ_24tmpVar5;
modelica_metatype __omcQ_24tmpVar4;
int tmp2;
modelica_metatype _e_loopVar = 0;
modelica_metatype _e;
_e_loopVar = listReverse(_elements);
tmp1 = 0;
while(1) {
tmp2 = 1;
if (!listEmpty(_e_loopVar)) {
_e = MMC_CAR(_e_loopVar);
_e_loopVar = MMC_CDR(_e_loopVar);
tmp2--;
}
if (tmp2 == 0) {
__omcQ_24tmpVar4 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 2))), _e, mmc_mk_real(_flowThreshold)) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_func), 1)))) (threadData, _e, mmc_mk_real(_flowThreshold));
if(tmp1)
{
__omcQ_24tmpVar5 = omc_Expression_expAdd(threadData, __omcQ_24tmpVar4, __omcQ_24tmpVar5);
}
else
{
__omcQ_24tmpVar5 = __omcQ_24tmpVar4;
tmp1 = 1;
}
} else if (tmp2 == 1) {
break;
} else {
MMC_THROW_INTERNAL();
}
}
if (!tmp1) MMC_THROW_INTERNAL();
tmpMeta[0] = __omcQ_24tmpVar5;
}
_exp = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_sumMap(threadData_t *threadData, modelica_metatype _elements, modelica_fnptr _func, modelica_metatype _flowThreshold)
{
modelica_real tmp1;
modelica_metatype _exp = NULL;
tmp1 = mmc_unbox_real(_flowThreshold);
_exp = omc_ConnectUtil_sumMap(threadData, _elements, _func, tmp1);
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_streamSumEquationExp(threadData_t *threadData, modelica_metatype _outsideElements, modelica_metatype _insideElements, modelica_real _flowThreshold)
{
modelica_metatype _sumExp = NULL;
modelica_metatype _outside_sum1 = NULL;
modelica_metatype _outside_sum2 = NULL;
modelica_metatype _inside_sum1 = NULL;
modelica_metatype _inside_sum2 = NULL;
modelica_metatype _res = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(listEmpty(_outsideElements))
{
_inside_sum1 = omc_ConnectUtil_sumMap(threadData, _insideElements, boxvar_ConnectUtil_sumInside1, _flowThreshold);
_inside_sum2 = omc_ConnectUtil_sumMap(threadData, _insideElements, boxvar_ConnectUtil_sumInside2, _flowThreshold);
_sumExp = omc_Expression_expDiv(threadData, _inside_sum1, _inside_sum2);
}
else
{
if(listEmpty(_insideElements))
{
_outside_sum1 = omc_ConnectUtil_sumMap(threadData, _outsideElements, boxvar_ConnectUtil_sumOutside1, _flowThreshold);
_outside_sum2 = omc_ConnectUtil_sumMap(threadData, _outsideElements, boxvar_ConnectUtil_sumOutside2, _flowThreshold);
_sumExp = omc_Expression_expDiv(threadData, _outside_sum1, _outside_sum2);
}
else
{
_outside_sum1 = omc_ConnectUtil_sumMap(threadData, _outsideElements, boxvar_ConnectUtil_sumOutside1, _flowThreshold);
_outside_sum2 = omc_ConnectUtil_sumMap(threadData, _outsideElements, boxvar_ConnectUtil_sumOutside2, _flowThreshold);
_inside_sum1 = omc_ConnectUtil_sumMap(threadData, _insideElements, boxvar_ConnectUtil_sumInside1, _flowThreshold);
_inside_sum2 = omc_ConnectUtil_sumMap(threadData, _insideElements, boxvar_ConnectUtil_sumInside2, _flowThreshold);
_sumExp = omc_Expression_expDiv(threadData, omc_Expression_expAdd(threadData, _outside_sum1, _inside_sum1), omc_Expression_expAdd(threadData, _outside_sum2, _inside_sum2));
}
}
_return: OMC_LABEL_UNUSED
return _sumExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_streamSumEquationExp(threadData_t *threadData, modelica_metatype _outsideElements, modelica_metatype _insideElements, modelica_metatype _flowThreshold)
{
modelica_real tmp1;
modelica_metatype _sumExp = NULL;
tmp1 = mmc_unbox_real(_flowThreshold);
_sumExp = omc_ConnectUtil_streamSumEquationExp(threadData, _outsideElements, _insideElements, tmp1);
return _sumExp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_streamEquationGeneral(threadData_t *threadData, modelica_metatype _outsideElements, modelica_metatype _insideElements, modelica_real _flowThreshold)
{
modelica_metatype _DAE = NULL;
modelica_metatype _outside = NULL;
modelica_metatype _cref_exp = NULL;
modelica_metatype _res = NULL;
modelica_metatype _src = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _name = NULL;
modelica_metatype _eql = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_eql = tmpMeta[0];
{
modelica_metatype _e;
for (tmpMeta[1] = _outsideElements; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_e = MMC_CAR(tmpMeta[1]);
_cref_exp = omc_Expression_crefExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 2))));
_outside = omc_ConnectUtil_removeStreamSetElement(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 2))), _outsideElements);
_res = omc_ConnectUtil_streamSumEquationExp(threadData, _outside, _insideElements, _flowThreshold);
_src = omc_ElementSource_addAdditionalComment(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 5))), _OMC_LIT74);
tmpMeta[3] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _cref_exp, _res, _src);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _eql);
_eql = tmpMeta[2];
}
}
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, _eql);
_DAE = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _DAE;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_streamEquationGeneral(threadData_t *threadData, modelica_metatype _outsideElements, modelica_metatype _insideElements, modelica_metatype _flowThreshold)
{
modelica_real tmp1;
modelica_metatype _DAE = NULL;
tmp1 = mmc_unbox_real(_flowThreshold);
_DAE = omc_ConnectUtil_streamEquationGeneral(threadData, _outsideElements, _insideElements, tmp1);
return _DAE;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isZeroFlow(threadData_t *threadData, modelica_metatype _element, modelica_string _attr)
{
modelica_boolean _isZero;
modelica_metatype _ty = NULL;
modelica_metatype _attr_oexp = NULL;
modelica_metatype _flow_exp = NULL;
modelica_metatype _attr_exp = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_flow_exp = omc_ConnectUtil_flowExp(threadData, _element);
_ty = omc_Expression_typeof(threadData, _flow_exp);
_attr_oexp = omc_Types_lookupAttributeExp(threadData, omc_Types_getAttributes(threadData, _ty), _attr);
if(isSome(_attr_oexp))
{
tmpMeta[0] = _attr_oexp;
if (optionNone(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
_attr_exp = tmpMeta[1];
_isZero = omc_Expression_isZero(threadData, _attr_exp);
}
else
{
_isZero = 0;
}
_return: OMC_LABEL_UNUSED
return _isZero;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isZeroFlow(threadData_t *threadData, modelica_metatype _element, modelica_metatype _attr)
{
modelica_boolean _isZero;
modelica_metatype out_isZero;
_isZero = omc_ConnectUtil_isZeroFlow(threadData, _element, _attr);
out_isZero = mmc_mk_icon(_isZero);
return out_isZero;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isZeroFlowMinMax(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _element)
{
modelica_boolean _isZero;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_ConnectUtil_compareCrefStreamSet(threadData, _streamCref, _element))
{
_isZero = 0;
}
else
{
if(omc_ConnectUtil_isOutsideElement(threadData, _element))
{
_isZero = omc_ConnectUtil_isZeroFlow(threadData, _element, _OMC_LIT43);
}
else
{
_isZero = omc_ConnectUtil_isZeroFlow(threadData, _element, _OMC_LIT42);
}
}
_return: OMC_LABEL_UNUSED
return _isZero;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isZeroFlowMinMax(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _element)
{
modelica_boolean _isZero;
modelica_metatype out_isZero;
_isZero = omc_ConnectUtil_isZeroFlowMinMax(threadData, _streamCref, _element);
out_isZero = mmc_mk_icon(_isZero);
return out_isZero;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isOutsideElement(threadData_t *threadData, modelica_metatype _element)
{
modelica_boolean _isOutside;
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
_isOutside = tmp1;
_return: OMC_LABEL_UNUSED
return _isOutside;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isOutsideElement(threadData_t *threadData, modelica_metatype _element)
{
modelica_boolean _isOutside;
modelica_metatype out_isOutside;
_isOutside = omc_ConnectUtil_isOutsideElement(threadData, _element);
out_isOutside = mmc_mk_icon(_isOutside);
return out_isOutside;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_generateStreamEquations(threadData_t *threadData, modelica_metatype _elements, modelica_real _flowThreshold)
{
modelica_metatype _DAE = NULL;
modelica_metatype tmpMeta[11] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _elements;
{
modelica_metatype _cr1 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype _src1 = NULL;
modelica_metatype _src2 = NULL;
modelica_metatype _src = NULL;
modelica_metatype _cref1 = NULL;
modelica_metatype _cref2 = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _inside = NULL;
modelica_metatype _outside = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 5; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,0) == 0) goto tmp2_end;
if (!listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[0] = _OMC_LIT75;
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,0) == 0) goto tmp2_end;
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[4] = MMC_CAR(tmpMeta[2]);
tmpMeta[5] = MMC_CDR(tmpMeta[2]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[4]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[6],0,0) == 0) goto tmp2_end;
if (!listEmpty(tmpMeta[5])) goto tmp2_end;
tmpMeta[0] = _OMC_LIT75;
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,0) == 0) goto tmp2_end;
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[6] = MMC_CAR(tmpMeta[2]);
tmpMeta[7] = MMC_CDR(tmpMeta[2]);
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 2));
tmpMeta[9] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[9],1,0) == 0) goto tmp2_end;
tmpMeta[10] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[6]), 5));
if (!listEmpty(tmpMeta[7])) goto tmp2_end;
_cr1 = tmpMeta[3];
_src1 = tmpMeta[5];
_cr2 = tmpMeta[8];
_src2 = tmpMeta[10];
_cref1 = omc_Expression_crefExp(threadData, _cr1);
_cref2 = omc_Expression_crefExp(threadData, _cr2);
_e1 = omc_ConnectUtil_makeInStreamCall(threadData, _cref2);
_e2 = omc_ConnectUtil_makeInStreamCall(threadData, _cref1);
_src = omc_ElementSource_mergeSources(threadData, _src1, _src2);
tmpMeta[2] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _cref1, _e1, _src);
tmpMeta[3] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _cref2, _e2, _src);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil)));
tmpMeta[4] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta[1]);
tmpMeta[0] = tmpMeta[4];
goto tmp2_done;
}
case 3: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 5));
if (listEmpty(tmpMeta[2])) goto tmp2_end;
tmpMeta[5] = MMC_CAR(tmpMeta[2]);
tmpMeta[6] = MMC_CDR(tmpMeta[2]);
tmpMeta[7] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 2));
tmpMeta[8] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[5]), 5));
if (!listEmpty(tmpMeta[6])) goto tmp2_end;
_cr1 = tmpMeta[3];
_src1 = tmpMeta[4];
_cr2 = tmpMeta[7];
_src2 = tmpMeta[8];
_src = omc_ElementSource_mergeSources(threadData, _src1, _src2);
_e1 = omc_Expression_crefExp(threadData, _cr1);
_e2 = omc_Expression_crefExp(threadData, _cr2);
tmpMeta[2] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _e1, _e2, _src);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[3] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta[1]);
tmpMeta[0] = tmpMeta[3];
goto tmp2_done;
}
case 4: {
_outside = omc_List_splitOnTrue(threadData, _elements, boxvar_ConnectUtil_isOutsideElement ,&_inside);
tmpMeta[0] = omc_ConnectUtil_streamEquationGeneral(threadData, _outside, _inside, _flowThreshold);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_DAE = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _DAE;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_generateStreamEquations(threadData_t *threadData, modelica_metatype _elements, modelica_metatype _flowThreshold)
{
modelica_real tmp1;
modelica_metatype _DAE = NULL;
tmp1 = mmc_unbox_real(_flowThreshold);
_DAE = omc_ConnectUtil_generateStreamEquations(threadData, _elements, tmp1);
return _DAE;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_increaseRefCount(threadData_t *threadData, modelica_integer _amount, modelica_metatype __omcQ_24in_5Fnode)
{
modelica_metatype _node = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_node = __omcQ_24in_5Fnode;
{
modelica_metatype tmp3_1;
tmp3_1 = _node;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_node), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = mmc_mk_integer(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 5)))) + _amount);
_node = tmpMeta[0];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_node), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[6] = mmc_mk_integer(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 6)))) + _amount);
_node = tmpMeta[0];
goto tmp2_done;
}
}
goto tmp2_end;
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
return _node;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_increaseRefCount(threadData_t *threadData, modelica_metatype _amount, modelica_metatype __omcQ_24in_5Fnode)
{
modelica_integer tmp1;
modelica_metatype _node = NULL;
tmp1 = mmc_unbox_integer(_amount);
_node = omc_ConnectUtil_increaseRefCount(threadData, tmp1, __omcQ_24in_5Fnode);
return _node;
}
DLLExport
modelica_metatype omc_ConnectUtil_increaseConnectRefCount2(threadData_t *threadData, modelica_metatype _crefs, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
{
modelica_metatype _cr;
for (tmpMeta[0] = _crefs; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_cr = MMC_CAR(tmpMeta[0]);
_sets = omc_ConnectUtil_setTrieUpdate(threadData, _cr, mmc_mk_integer(((modelica_integer) 1)), _sets, boxvar_ConnectUtil_increaseRefCount);
}
}
_return: OMC_LABEL_UNUSED
return _sets;
}
DLLExport
modelica_metatype omc_ConnectUtil_increaseConnectRefCount(threadData_t *threadData, modelica_metatype _lhsCref, modelica_metatype _rhsCref, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
if(omc_System_getUsesCardinality(threadData))
{
_crefs = omc_ComponentReference_expandCref(threadData, _lhsCref, 0);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_sets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = omc_ConnectUtil_increaseConnectRefCount2(threadData, _crefs, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))));
_sets = tmpMeta[0];
_crefs = omc_ComponentReference_expandCref(threadData, _rhsCref, 0);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_sets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = omc_ConnectUtil_increaseConnectRefCount2(threadData, _crefs, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))));
_sets = tmpMeta[0];
}
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_makeFlowExp(threadData_t *threadData, modelica_metatype _element)
{
modelica_metatype _exp = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_exp = omc_Expression_crefExp(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 2))));
if(omc_ConnectUtil_isOutsideElement(threadData, _element))
{
_exp = omc_Expression_negateReal(threadData, _exp);
}
_return: OMC_LABEL_UNUSED
return _exp;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_generateFlowEquations(threadData_t *threadData, modelica_metatype _elements)
{
modelica_metatype _DAE = NULL;
modelica_metatype _sum = NULL;
modelica_metatype _src = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sum = omc_ConnectUtil_makeFlowExp(threadData, listHead(_elements));
_src = omc_ConnectUtil_getElementSource(threadData, listHead(_elements));
{
modelica_metatype _e;
for (tmpMeta[0] = listRest(_elements); !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_e = MMC_CAR(tmpMeta[0]);
_sum = omc_Expression_makeRealAdd(threadData, _sum, omc_ConnectUtil_makeFlowExp(threadData, _e));
_src = omc_ElementSource_mergeSources(threadData, _src, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e), 5))));
}
}
tmpMeta[1] = mmc_mk_box4(6, &DAE_Element_EQUATION__desc, _sum, _OMC_LIT45, _src);
tmpMeta[0] = mmc_mk_cons(tmpMeta[1], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, tmpMeta[0]);
_DAE = tmpMeta[2];
_return: OMC_LABEL_UNUSED
return _DAE;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_shouldFlipEquEquation(threadData_t *threadData, modelica_metatype _lhsCref, modelica_metatype _lhsSource)
{
modelica_boolean _shouldFlip;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _lhsSource;
{
modelica_metatype _lhs = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (listEmpty(tmpMeta[0])) goto tmp3_end;
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_lhs = tmpMeta[3];
tmp1 = (!omc_ComponentReference_crefPrefixOf(threadData, _lhs, _lhsCref));
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
_shouldFlip = tmp1;
_return: OMC_LABEL_UNUSED
return _shouldFlip;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_shouldFlipEquEquation(threadData_t *threadData, modelica_metatype _lhsCref, modelica_metatype _lhsSource)
{
modelica_boolean _shouldFlip;
modelica_metatype out_shouldFlip;
_shouldFlip = omc_ConnectUtil_shouldFlipEquEquation(threadData, _lhsCref, _lhsSource);
out_shouldFlip = mmc_mk_icon(_shouldFlip);
return out_shouldFlip;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_generateEquEquations(threadData_t *threadData, modelica_metatype _elements)
{
modelica_metatype _DAE = NULL;
modelica_metatype _eql = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _src = NULL;
modelica_metatype _x_src = NULL;
modelica_metatype _y_src = NULL;
modelica_metatype _x = NULL;
modelica_metatype _y = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_DAE = _OMC_LIT75;
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_eql = tmpMeta[0];
if(listEmpty(_elements))
{
goto _return;
}
_e1 = listHead(_elements);
if(omc_Config_orderConnections(threadData))
{
{
modelica_metatype _e2;
for (tmpMeta[1] = listRest(_elements); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_e2 = MMC_CAR(tmpMeta[1]);
_src = omc_ElementSource_mergeSources(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e1), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e2), 5))));
tmpMeta[2] = mmc_mk_box2(0, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e2), 2))));
_src = omc_ElementSource_addElementSourceConnect(threadData, _src, tmpMeta[2]);
tmpMeta[3] = mmc_mk_box4(7, &DAE_Element_EQUEQUATION__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e2), 2))), _src);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _eql);
_eql = tmpMeta[2];
}
}
}
else
{
{
modelica_metatype _e2;
for (tmpMeta[1] = listRest(_elements); !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_e2 = MMC_CAR(tmpMeta[1]);
_x = omc_Util_swap(threadData, omc_ConnectUtil_shouldFlipEquEquation(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e1), 5)))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e1), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e2), 2))) ,&_y);
_src = omc_ElementSource_mergeSources(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e1), 5))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_e2), 5))));
tmpMeta[2] = mmc_mk_box2(0, _x, _y);
_src = omc_ElementSource_addElementSourceConnect(threadData, _src, tmpMeta[2]);
tmpMeta[3] = mmc_mk_box4(7, &DAE_Element_EQUEQUATION__desc, _x, _y, _src);
tmpMeta[2] = mmc_mk_cons(tmpMeta[3], _eql);
_eql = tmpMeta[2];
_e1 = _e2;
}
}
}
tmpMeta[1] = mmc_mk_box2(3, &DAE_DAElist_DAE__desc, listReverse(_eql));
_DAE = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _DAE;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_equationsDispatch(threadData_t *threadData, modelica_metatype _sets, modelica_metatype _connected, modelica_metatype _broken)
{
modelica_metatype _DAE = NULL;
modelica_metatype _eql = NULL;
modelica_metatype _eqll = NULL;
modelica_real _flowThreshold;
modelica_metatype _dae = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_DAE = _OMC_LIT75;
_flowThreshold = omc_Flags_getConfigReal(threadData, _OMC_LIT68);
{
modelica_metatype _set;
for (tmpMeta[0] = _sets; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_set = MMC_CAR(tmpMeta[0]);
{
modelica_metatype tmp3_1;
tmp3_1 = _set;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 6; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
tmpMeta[1] = _DAE;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,0) == 0) goto tmp2_end;
_eqll = omc_ConnectionGraph_removeBrokenConnects(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))), _connected, _broken);
{
modelica_metatype _eql;
for (tmpMeta[2] = _eqll; !listEmpty(tmpMeta[2]); tmpMeta[2]=MMC_CDR(tmpMeta[2]))
{
_eql = MMC_CAR(tmpMeta[2]);
_DAE = omc_DAEUtil_joinDaes(threadData, omc_ConnectUtil_generateEquEquations(threadData, _eql), _DAE);
}
}
tmpMeta[1] = _DAE;
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],1,0) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_eql = tmpMeta[3];
tmpMeta[1] = omc_DAEUtil_joinDaes(threadData, omc_ConnectUtil_generateFlowEquations(threadData, _eql), _DAE);
goto tmp2_done;
}
case 3: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],2,1) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_eql = tmpMeta[3];
tmpMeta[1] = omc_DAEUtil_joinDaes(threadData, omc_ConnectUtil_generateStreamEquations(threadData, _eql, _flowThreshold), _DAE);
goto tmp2_done;
}
case 4: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],3,0) == 0) goto tmp2_end;
omc_Error_addMessage(threadData, _OMC_LIT78, _OMC_LIT80);
goto goto_1;
goto tmp2_done;
}
case 5: {
omc_Error_addMessage(threadData, _OMC_LIT78, _OMC_LIT82);
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
_DAE = tmpMeta[1];
}
}
_return: OMC_LABEL_UNUSED
return _DAE;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setArrayGet(threadData_t *threadData, modelica_metatype _setArray, modelica_integer _index)
{
modelica_metatype _set = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_set = arrayGet(_setArray,_index);
{
modelica_metatype tmp3_1;
tmp3_1 = _set;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[0] = _set;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
_index = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2))));
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
_set = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _set;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setArrayGet(threadData_t *threadData, modelica_metatype _setArray, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_metatype _set = NULL;
tmp1 = mmc_unbox_integer(_index);
_set = omc_ConnectUtil_setArrayGet(threadData, _setArray, tmp1);
return _set;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_equSetElementLess(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2)
{
modelica_boolean _isLess;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_isLess = omc_ComponentReference_crefSortFunc(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element2), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element1), 2))));
_return: OMC_LABEL_UNUSED
return _isLess;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_equSetElementLess(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2)
{
modelica_boolean _isLess;
modelica_metatype out_isLess;
_isLess = omc_ConnectUtil_equSetElementLess(threadData, _element1, _element2);
out_isLess = mmc_mk_icon(_isLess);
return out_isLess;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setArrayUpdate(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_integer _index, modelica_metatype _element)
{
modelica_metatype _sets = NULL;
modelica_metatype _set = NULL;
modelica_metatype _el = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_set = arrayGet(_sets,_index);
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _set;
tmp3_2 = _element;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
if((omc_Config_orderConnections(threadData) && omc_ConnectUtil_isEquType(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4))))))
{
tmpMeta[1] = mmc_mk_cons(_element, MMC_REFSTRUCTLIT(mmc_nil));
_el = omc_List_mergeSorted(threadData, tmpMeta[1], (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))), boxvar_ConnectUtil_equSetElementLess);
}
else
{
tmpMeta[1] = mmc_mk_cons(_element, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 3))));
_el = tmpMeta[1];
}
tmpMeta[1] = mmc_mk_box3(3, &DAE_Connect_Set_SET__desc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 4))), _el);
tmpMeta[0] = arrayUpdate(_sets, _index, tmpMeta[1]);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
__omcQ_24in_5Fsets = _sets;
_index = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2))));
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
_sets = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setArrayUpdate(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _index, modelica_metatype _element)
{
modelica_integer tmp1;
modelica_metatype _sets = NULL;
tmp1 = mmc_unbox_integer(_index);
_sets = omc_ConnectUtil_setArrayUpdate(threadData, __omcQ_24in_5Fsets, tmp1, _element);
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_buildElementPrefix(threadData_t *threadData, modelica_metatype _prefix)
{
modelica_metatype _cref = NULL;
modelica_metatype _cr = NULL;
modelica_string _id = NULL;
modelica_metatype _subs = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(listEmpty(_prefix))
{
_cref = mmc_mk_none();
}
else
{
_cr = listHead(_prefix);
{
modelica_metatype _c;
for (tmpMeta[0] = listRest(_prefix); !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_c = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = _c;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,3) == 0) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 4));
_id = tmpMeta[2];
_subs = tmpMeta[3];
tmpMeta[1] = mmc_mk_box5(3, &DAE_ComponentRef_CREF__QUAL__desc, _id, _OMC_LIT41, _subs, _cr);
_cr = tmpMeta[1];
}
}
_cref = mmc_mk_some(_cr);
}
_return: OMC_LABEL_UNUSED
return _cref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setArrayAddElement(threadData_t *threadData, modelica_metatype _element, modelica_metatype _prefix, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _element;
tmp3_2 = _prefix;
{
modelica_metatype _el = NULL;
modelica_metatype _prefix_cr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _sets;
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (!optionNone(tmp3_2)) goto tmp2_end;
_el = tmpMeta[1];
tmpMeta[0] = omc_ConnectUtil_setArrayUpdate(threadData, _sets, mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 6)))), _el);
goto tmp2_done;
}
case 2: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
if (optionNone(tmp3_2)) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 1));
_el = tmpMeta[1];
_prefix_cr = tmpMeta[2];
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_el), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[2] = omc_ComponentReference_joinCrefs(threadData, _prefix_cr, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 2))));
_el = tmpMeta[1];
tmpMeta[0] = omc_ConnectUtil_setArrayUpdate(threadData, _sets, mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_el), 6)))), _el);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_sets = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_insertFlowAssociationInStreamElement(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _flowCref)
{
modelica_metatype _element = NULL;
modelica_metatype _el = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = __omcQ_24in_5Felement;
if(isSome(_element))
{
tmpMeta[0] = _element;
if (optionNone(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
_el = tmpMeta[1];
{
modelica_metatype tmp3_1;
tmp3_1 = _el;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],2,1) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 2));
if (!optionNone(tmpMeta[2])) goto tmp2_end;
tmpMeta[2] = mmc_mk_box2(5, &DAE_Connect_ConnectorType_STREAM__desc, _flowCref);
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_el), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[4] = tmpMeta[2];
_el = tmpMeta[1];
tmpMeta[0] = mmc_mk_some(_el);
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _element;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_element = tmpMeta[0];
}
_return: OMC_LABEL_UNUSED
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_generateSetArray2(threadData_t *threadData, modelica_metatype _sets, modelica_metatype _prefix, modelica_metatype __omcQ_24in_5FsetArray)
{
modelica_metatype _setArray = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_setArray = __omcQ_24in_5FsetArray;
{
modelica_metatype tmp3_1;
tmp3_1 = _sets;
{
modelica_metatype _ie = NULL;
modelica_metatype _oe = NULL;
modelica_metatype _prefix_cr = NULL;
modelica_metatype _flow_cr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],4,0) == 0) goto tmp2_end;
tmpMeta[0] = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 4))), boxvar_ConnectUtil_generateSetArray2, _prefix, _setArray);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 3))), _prefix);
tmpMeta[0] = omc_List_fold1(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 4))), boxvar_ConnectUtil_generateSetArray2, tmpMeta[1], _setArray);
goto tmp2_done;
}
case 2: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
_ie = tmpMeta[1];
_oe = tmpMeta[2];
_flow_cr = tmpMeta[3];
_ie = omc_ConnectUtil_insertFlowAssociationInStreamElement(threadData, _ie, _flow_cr);
_oe = omc_ConnectUtil_insertFlowAssociationInStreamElement(threadData, _oe, _flow_cr);
_prefix_cr = omc_ConnectUtil_buildElementPrefix(threadData, _prefix);
_setArray = omc_ConnectUtil_setArrayAddElement(threadData, _ie, _prefix_cr, _setArray);
tmpMeta[0] = omc_ConnectUtil_setArrayAddElement(threadData, _oe, _prefix_cr, _setArray);
goto tmp2_done;
}
case 3: {
tmpMeta[0] = _setArray;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_setArray = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _setArray;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setArrayAddConnection2(threadData_t *threadData, modelica_integer _setPointer, modelica_integer _setPointee, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_metatype _set = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_set = arrayGet(_sets,_setPointee);
{
modelica_metatype tmp3_1;
tmp3_1 = _set;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box2(4, &DAE_Connect_Set_SET__POINTER__desc, mmc_mk_integer(_setPointee));
tmpMeta[0] = arrayUpdate(_sets, _setPointer, tmpMeta[1]);
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,1) == 0) goto tmp2_end;
_setPointee = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_set), 2))));
__omcQ_24in_5Fsets = _sets;
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
_sets = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setArrayAddConnection2(threadData_t *threadData, modelica_metatype _setPointer, modelica_metatype _setPointee, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _sets = NULL;
tmp1 = mmc_unbox_integer(_setPointer);
tmp2 = mmc_unbox_integer(_setPointee);
_sets = omc_ConnectUtil_setArrayAddConnection2(threadData, tmp1, tmp2, __omcQ_24in_5Fsets);
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setArrayAddConnection(threadData_t *threadData, modelica_integer _set, modelica_metatype _edges, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype __omcQ_24in_5Fgraph, modelica_metatype *out_graph)
{
modelica_metatype _sets = NULL;
modelica_metatype _graph = NULL;
modelica_metatype _edge_lst = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_graph = __omcQ_24in_5Fgraph;
{
modelica_metatype _e;
for (tmpMeta[0] = _edges; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_e = MMC_CAR(tmpMeta[0]);
if((mmc_unbox_integer(_e) != _set))
{
_sets = omc_ConnectUtil_setArrayAddConnection2(threadData, mmc_unbox_integer(_e), _set, _sets);
_edge_lst = arrayGet(_graph,mmc_unbox_integer(_e));
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
arrayUpdate(_graph,mmc_unbox_integer(_e),tmpMeta[1]);
_sets = omc_ConnectUtil_setArrayAddConnection(threadData, _set, _edge_lst, _sets, _graph ,&_graph);
}
}
}
_return: OMC_LABEL_UNUSED
if (out_graph) { *out_graph = _graph; }
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setArrayAddConnection(threadData_t *threadData, modelica_metatype _set, modelica_metatype _edges, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype __omcQ_24in_5Fgraph, modelica_metatype *out_graph)
{
modelica_integer tmp1;
modelica_metatype _sets = NULL;
tmp1 = mmc_unbox_integer(_set);
_sets = omc_ConnectUtil_setArrayAddConnection(threadData, tmp1, _edges, __omcQ_24in_5Fsets, __omcQ_24in_5Fgraph, out_graph);
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addConnectionToGraph(threadData_t *threadData, modelica_metatype _connection, modelica_metatype __omcQ_24in_5Fgraph)
{
modelica_metatype _graph = NULL;
modelica_integer _set1;
modelica_integer _set2;
modelica_metatype _node1 = NULL;
modelica_metatype _node2 = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_graph = __omcQ_24in_5Fgraph;
tmpMeta[0] = _connection;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 1));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmp2 = mmc_unbox_integer(tmpMeta[2]);
_set1 = tmp1;
_set2 = tmp2;
_node1 = arrayGet(_graph, _set1);
tmpMeta[0] = mmc_mk_cons(mmc_mk_integer(_set2), _node1);
_graph = arrayUpdate(_graph, _set1, tmpMeta[0]);
_node2 = arrayGet(_graph, _set2);
tmpMeta[0] = mmc_mk_cons(mmc_mk_integer(_set1), _node2);
_graph = arrayUpdate(_graph, _set2, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return _graph;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setArrayAddConnections(threadData_t *threadData, modelica_metatype _connections, modelica_integer _setCount, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_metatype _graph = NULL;
modelica_integer tmp1;
modelica_integer tmp2;
modelica_integer tmp3;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_graph = arrayCreate(_setCount, tmpMeta[0]);
_graph = omc_List_fold(threadData, _connections, boxvar_ConnectUtil_addConnectionToGraph, _graph);
tmp1 = ((modelica_integer) 1); tmp2 = 1; tmp3 = arrayLength(_graph);
if(!(((tmp2 > 0) && (tmp1 > tmp3)) || ((tmp2 < 0) && (tmp1 < tmp3))))
{
modelica_integer _i;
for(_i = ((modelica_integer) 1); in_range_integer(_i, tmp1, tmp3); _i += tmp2)
{
_sets = omc_ConnectUtil_setArrayAddConnection(threadData, _i, arrayGet(_graph,_i) /* DAE.ASUB */, _sets, _graph ,&_graph);
}
}
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setArrayAddConnections(threadData_t *threadData, modelica_metatype _connections, modelica_metatype _setCount, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_integer tmp1;
modelica_metatype _sets = NULL;
tmp1 = mmc_unbox_integer(_setCount);
_sets = omc_ConnectUtil_setArrayAddConnections(threadData, _connections, tmp1, __omcQ_24in_5Fsets);
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_generateSetArray(threadData_t *threadData, modelica_metatype _sets)
{
modelica_metatype _setArray = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_setArray = arrayCreate(mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 3)))), _OMC_LIT84);
_setArray = omc_ConnectUtil_setArrayAddConnections(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 4))), mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 3)))), _setArray);
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_setArray = omc_ConnectUtil_generateSetArray2(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))), tmpMeta[0], _setArray);
_return: OMC_LABEL_UNUSED
return _setArray;
}
DLLExport
modelica_boolean omc_ConnectUtil_allCrefsAreExpandable(threadData_t *threadData, modelica_metatype _connects)
{
modelica_boolean _allAreExpandable;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype _cr;
for (tmpMeta[0] = _connects; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_cr = MMC_CAR(tmpMeta[0]);
if((!omc_ConnectUtil_isExpandable(threadData, _cr)))
{
_allAreExpandable = 0;
goto _return;
}
}
}
_allAreExpandable = 1;
_return: OMC_LABEL_UNUSED
return _allAreExpandable;
}
modelica_metatype boxptr_ConnectUtil_allCrefsAreExpandable(threadData_t *threadData, modelica_metatype _connects)
{
modelica_boolean _allAreExpandable;
modelica_metatype out_allAreExpandable;
_allAreExpandable = omc_ConnectUtil_allCrefsAreExpandable(threadData, _connects);
out_allAreExpandable = mmc_mk_icon(_allAreExpandable);
return out_allAreExpandable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getOnlyExpandableConnectedCrefs(threadData_t *threadData, modelica_metatype _sets)
{
modelica_metatype _usefulConnectedExpandable = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_usefulConnectedExpandable = tmpMeta[0];
{
modelica_metatype _set;
for (tmpMeta[1] = _sets; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_set = MMC_CAR(tmpMeta[1]);
if(omc_ConnectUtil_allCrefsAreExpandable(threadData, _set))
{
_usefulConnectedExpandable = listAppend(_set, _usefulConnectedExpandable);
}
}
}
_return: OMC_LABEL_UNUSED
return _usefulConnectedExpandable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_mergeWithRest(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fset, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _acc, modelica_metatype *out_sets)
{
modelica_metatype _set = NULL;
modelica_metatype _sets = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_set = __omcQ_24in_5Fset;
_sets = __omcQ_24in_5Fsets;
{
modelica_metatype tmp4_1;modelica_metatype tmp4_2;
tmp4_1 = _set;
tmp4_2 = _sets;
{
modelica_metatype _set1 = NULL;
modelica_metatype _set2 = NULL;
modelica_metatype _rest = NULL;
modelica_boolean _b;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (!listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[0+0] = _set;
tmpMeta[0+1] = listReverse(_acc);
goto tmp3_done;
}
case 1: {
if (listEmpty(tmp4_2)) goto tmp3_end;
tmpMeta[2] = MMC_CAR(tmp4_2);
tmpMeta[3] = MMC_CDR(tmp4_2);
_set2 = tmpMeta[2];
_rest = tmpMeta[3];
_set1 = tmp4_1;
_b = listEmpty(omc_List_intersectionOnTrue(threadData, _set1, _set2, boxvar_ComponentReference_crefEqualNoStringCompare));
_set = ((!_b)?omc_List_unionOnTrue(threadData, _set1, _set2, boxvar_ComponentReference_crefEqualNoStringCompare):_set1);
__omcQ_24in_5Fset = _set;
__omcQ_24in_5Fsets = _rest;
_acc = omc_List_consOnTrue(threadData, _b, _set2, _acc);
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
_set = tmpMeta[0+0];
_sets = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_sets) { *out_sets = _sets; }
return _set;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_mergeEquSetsAsCrefs(threadData_t *threadData, modelica_metatype __omcQ_24in_5FsetsAsCrefs)
{
modelica_metatype _setsAsCrefs = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_setsAsCrefs = __omcQ_24in_5FsetsAsCrefs;
{
modelica_metatype tmp3_1;
tmp3_1 = _setsAsCrefs;
{
modelica_metatype _set = NULL;
modelica_metatype _rest = NULL;
modelica_metatype _sets = NULL;
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
if (!listEmpty(tmpMeta[2])) goto tmp2_end;
_set = tmpMeta[1];
tmpMeta[1] = mmc_mk_cons(_set, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 2: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_set = tmpMeta[1];
_rest = tmpMeta[2];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_set = omc_ConnectUtil_mergeWithRest(threadData, _set, _rest, tmpMeta[1] ,&_rest);
_sets = omc_ConnectUtil_mergeEquSetsAsCrefs(threadData, _rest);
tmpMeta[1] = mmc_mk_cons(_set, _sets);
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
_setsAsCrefs = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _setsAsCrefs;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_removeCrefsFromSets2(threadData_t *threadData, modelica_metatype _set, modelica_metatype _nonUsefulExpandable)
{
modelica_boolean _isInSet;
modelica_metatype _setCrefs = NULL;
modelica_metatype _lst = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_cons(_set, MMC_REFSTRUCTLIT(mmc_nil));
_setCrefs = omc_ConnectUtil_getAllEquCrefs(threadData, tmpMeta[0]);
_lst = omc_List_intersectionOnTrue(threadData, _setCrefs, _nonUsefulExpandable, boxvar_ComponentReference_crefEqualNoStringCompare);
_isInSet = listEmpty(_lst);
_return: OMC_LABEL_UNUSED
return _isInSet;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_removeCrefsFromSets2(threadData_t *threadData, modelica_metatype _set, modelica_metatype _nonUsefulExpandable)
{
modelica_boolean _isInSet;
modelica_metatype out_isInSet;
_isInSet = omc_ConnectUtil_removeCrefsFromSets2(threadData, _set, _nonUsefulExpandable);
out_isInSet = mmc_mk_icon(_isInSet);
return out_isInSet;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_removeCrefsFromSets(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _nonUsefulExpandable)
{
modelica_metatype _sets = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_sets = omc_List_select1(threadData, _sets, boxvar_ConnectUtil_removeCrefsFromSets2, _nonUsefulExpandable);
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getExpandableEquSetsAsCrefs(threadData_t *threadData, modelica_metatype _sets)
{
modelica_metatype _crefSets = NULL;
modelica_metatype _cref_set = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_crefSets = tmpMeta[0];
{
modelica_metatype _set;
for (tmpMeta[1] = _sets; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_set = MMC_CAR(tmpMeta[1]);
{
modelica_metatype tmp3_1;
tmp3_1 = _set;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,2) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],0,0) == 0) goto tmp2_end;
tmpMeta[2] = mmc_mk_cons(_set, MMC_REFSTRUCTLIT(mmc_nil));
_cref_set = omc_ConnectUtil_getAllEquCrefs(threadData, tmpMeta[2]);
if(mmc_unbox_boolean(omc_List_applyAndFold(threadData, _cref_set, boxvar_boolOr, boxvar_ConnectUtil_isExpandable, mmc_mk_boolean(0))))
{
tmpMeta[2] = mmc_mk_cons(_cref_set, _crefSets);
_crefSets = tmpMeta[2];
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
return _crefSets;
}
DLLExport
modelica_metatype omc_ConnectUtil_equations(threadData_t *threadData, modelica_boolean _topScope, modelica_metatype _sets, modelica_metatype __omcQ_24in_5FDAE, modelica_metatype _connectionGraph, modelica_string _modelNameQualified)
{
modelica_metatype _DAE = NULL;
modelica_metatype _set_list = NULL;
modelica_metatype _set_array = NULL;
modelica_metatype _dae = NULL;
modelica_metatype _dae2 = NULL;
modelica_boolean _has_stream;
modelica_boolean _has_expandable;
modelica_boolean _has_cardinality;
modelica_metatype _broken = NULL;
modelica_metatype _connected = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_DAE = __omcQ_24in_5FDAE;
setGlobalRoot(((modelica_integer) 27), mmc_mk_none());
if((!_topScope))
{
goto _return;
}
_set_array = omc_ConnectUtil_generateSetArray(threadData, _sets);
_set_list = arrayList(_set_array);
if(omc_ConnectUtil_daeHasExpandableConnectors(threadData, _DAE))
{
_set_list = omc_ConnectUtil_removeUnusedExpandableVariablesAndConnections(threadData, _set_list, _DAE ,&_dae);
}
else
{
_dae = _DAE;
}
_dae = omc_ConnectionGraph_handleOverconstrainedConnections(threadData, _connectionGraph, _modelNameQualified, _dae ,&_connected ,&_broken);
_dae2 = omc_ConnectUtil_equationsDispatch(threadData, listReverse(_set_list), _connected, _broken);
_DAE = omc_DAEUtil_joinDaes(threadData, _dae, _dae2);
_DAE = omc_ConnectUtil_evaluateConnectionOperators(threadData, _sets, _set_array, _DAE);
_DAE = omc_ConnectionGraph_addBrokenEqualityConstraintEquations(threadData, _DAE, _broken);
_return: OMC_LABEL_UNUSED
return _DAE;
}
modelica_metatype boxptr_ConnectUtil_equations(threadData_t *threadData, modelica_metatype _topScope, modelica_metatype _sets, modelica_metatype __omcQ_24in_5FDAE, modelica_metatype _connectionGraph, modelica_metatype _modelNameQualified)
{
modelica_integer tmp1;
modelica_metatype _DAE = NULL;
tmp1 = mmc_unbox_integer(_topScope);
_DAE = omc_ConnectUtil_equations(threadData, tmp1, _sets, __omcQ_24in_5FDAE, _connectionGraph, _modelNameQualified);
return _DAE;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_setTrieIsNode(threadData_t *threadData, modelica_metatype _node)
{
modelica_boolean _isNode;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _node;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
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
_isNode = tmp1;
_return: OMC_LABEL_UNUSED
return _isNode;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setTrieIsNode(threadData_t *threadData, modelica_metatype _node)
{
modelica_boolean _isNode;
modelica_metatype out_isNode;
_isNode = omc_ConnectUtil_setTrieIsNode(threadData, _node);
out_isNode = mmc_mk_icon(_isNode);
return out_isNode;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_setTrieLeafNamed(threadData_t *threadData, modelica_string _id, modelica_metatype _node)
{
modelica_boolean _isNamed;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _node;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
tmp1 = (stringEqual(_id, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 2)))));
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
_isNamed = tmp1;
_return: OMC_LABEL_UNUSED
return _isNamed;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setTrieLeafNamed(threadData_t *threadData, modelica_metatype _id, modelica_metatype _node)
{
modelica_boolean _isNamed;
modelica_metatype out_isNamed;
_isNamed = omc_ConnectUtil_setTrieLeafNamed(threadData, _id, _node);
out_isNamed = mmc_mk_icon(_isNamed);
return out_isNamed;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieGetLeaf(threadData_t *threadData, modelica_string _id, modelica_metatype _nodes)
{
modelica_metatype _node = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_node = omc_List_getMemberOnTrue(threadData, _id, _nodes, boxvar_ConnectUtil_setTrieLeafNamed);
_return: OMC_LABEL_UNUSED
return _node;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_setTrieNodeNamed(threadData_t *threadData, modelica_string _id, modelica_metatype _node)
{
modelica_boolean _isNamed;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _node;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 3: {
tmp1 = (stringEqual(_id, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 2)))));
goto tmp3_done;
}
case 4: {
tmp1 = (stringEqual(_id, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 2)))));
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
_isNamed = tmp1;
_return: OMC_LABEL_UNUSED
return _isNamed;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setTrieNodeNamed(threadData_t *threadData, modelica_metatype _id, modelica_metatype _node)
{
modelica_boolean _isNamed;
modelica_metatype out_isNamed;
_isNamed = omc_ConnectUtil_setTrieNodeNamed(threadData, _id, _node);
out_isNamed = mmc_mk_icon(_isNamed);
return out_isNamed;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieGetNode(threadData_t *threadData, modelica_string _id, modelica_metatype _nodes)
{
modelica_metatype _node = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_node = omc_List_getMemberOnTrue(threadData, _id, _nodes, boxvar_ConnectUtil_setTrieNodeNamed);
_return: OMC_LABEL_UNUSED
return _node;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieGet(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _trie, modelica_boolean _matchPrefix)
{
modelica_metatype _leaf = NULL;
modelica_metatype _nodes = NULL;
modelica_string _subs_str = NULL;
modelica_string _id_subs = NULL;
modelica_string _id_nosubs = NULL;
modelica_metatype _node = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _trie;
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,4) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_nodes = tmpMeta[1];
_id_nosubs = omc_ComponentReference_crefFirstIdent(threadData, _cref);
_subs_str = omc_List_toString(threadData, omc_ComponentReference_crefFirstSubs(threadData, _cref), boxvar_ExpressionDump_printSubscriptStr, _OMC_LIT5, _OMC_LIT85, _OMC_LIT86, _OMC_LIT15, 0);
tmpMeta[0] = stringAppend(_id_nosubs,_subs_str);
_id_subs = tmpMeta[0];
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
_leaf = omc_ConnectUtil_setTrieGetNode(threadData, _id_subs, _nodes);
goto tmp2_done;
}
case 1: {
_leaf = omc_ConnectUtil_setTrieGetNode(threadData, _id_nosubs, _nodes);
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
if((!omc_ComponentReference_crefIsIdent(threadData, _cref)))
{
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
_leaf = omc_ConnectUtil_setTrieGet(threadData, omc_ComponentReference_crefRest(threadData, _cref), _leaf, _matchPrefix);
goto tmp6_done;
}
case 1: {
modelica_boolean tmp9;
tmp9 = (_matchPrefix && (!omc_ConnectUtil_setTrieIsNode(threadData, _leaf)));
if (1 != tmp9) goto goto_5;
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
MMC_THROW_INTERNAL();
tmp6_done2:;
}
}
;
}
_return: OMC_LABEL_UNUSED
return _leaf;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setTrieGet(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _trie, modelica_metatype _matchPrefix)
{
modelica_integer tmp1;
modelica_metatype _leaf = NULL;
tmp1 = mmc_unbox_integer(_matchPrefix);
_leaf = omc_ConnectUtil_setTrieGet(threadData, _cref, _trie, tmp1);
return _leaf;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieTraverseLeaves(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fnode, modelica_fnptr _updateFunc, modelica_metatype __omcQ_24in_5Farg, modelica_metatype *out_arg)
{
modelica_metatype _node = NULL;
modelica_metatype _arg = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_node = __omcQ_24in_5Fnode;
_arg = __omcQ_24in_5Farg;
{
modelica_metatype tmp3_1;
tmp3_1 = _node;
{
modelica_metatype _nodes = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
_nodes = omc_List_map1Fold(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 4))), boxvar_ConnectUtil_setTrieTraverseLeaves, ((modelica_fnptr) _updateFunc), _arg ,&_arg);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_node), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = _nodes;
_node = tmpMeta[0];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
_node = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 2))), _node, _arg ,&_arg) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 1)))) (threadData, _node, _arg ,&_arg);
goto tmp2_done;
}
}
goto tmp2_end;
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
return _node;
}
DLLExport
modelica_metatype omc_ConnectUtil_traverseSets(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype __omcQ_24in_5Farg, modelica_fnptr _updateFunc, modelica_metatype *out_arg)
{
modelica_metatype _sets = NULL;
modelica_metatype _arg = NULL;
modelica_metatype _node = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_arg = __omcQ_24in_5Farg;
_node = omc_ConnectUtil_setTrieTraverseLeaves(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))), ((modelica_fnptr) _updateFunc), _arg ,&_arg);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_sets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _node;
_sets = tmpMeta[0];
_return: OMC_LABEL_UNUSED
if (out_arg) { *out_arg = _arg; }
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieUpdateLeaf(threadData_t *threadData, modelica_string _id, modelica_metatype _arg, modelica_metatype __omcQ_24in_5Fnodes, modelica_fnptr _updateFunc)
{
modelica_metatype _nodes = NULL;
modelica_integer _n;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nodes = __omcQ_24in_5Fnodes;
_n = ((modelica_integer) 1);
{
modelica_metatype _node;
for (tmpMeta[0] = _nodes; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_node = MMC_CAR(tmpMeta[0]);
if((stringEqual(omc_ConnectUtil_setTrieNodeName(threadData, _node), _id)))
{
_nodes = omc_List_replaceAt(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 2))), _arg, _node) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 1)))) (threadData, _arg, _node), _n, _nodes);
goto _return;
}
_n = ((modelica_integer) 1) + _n;
}
}
tmpMeta[1] = mmc_mk_box6(4, &DAE_Connect_SetTrieNode_SET__TRIE__LEAF__desc, _id, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_integer(((modelica_integer) 0)));
tmpMeta[2] = mmc_mk_box6(4, &DAE_Connect_SetTrieNode_SET__TRIE__LEAF__desc, _id, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_integer(((modelica_integer) 0)));
tmpMeta[0] = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 2))), _arg, tmpMeta[2]) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 1)))) (threadData, _arg, tmpMeta[1]), _nodes);
_nodes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _nodes;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieUpdateNode2(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _arg, modelica_fnptr _updateFunc, modelica_metatype __omcQ_24in_5Fnodes)
{
modelica_metatype _nodes = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nodes = __omcQ_24in_5Fnodes;
{
modelica_metatype tmp3_1;
tmp3_1 = _cref;
{
modelica_string _id = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _node = NULL;
modelica_metatype _child_nodes = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
_id = omc_ComponentReference_printComponentRefStr(threadData, _cref);
tmpMeta[1] = mmc_mk_box6(4, &DAE_Connect_SetTrieNode_SET__TRIE__LEAF__desc, _id, mmc_mk_none(), mmc_mk_none(), mmc_mk_none(), mmc_mk_integer(((modelica_integer) 0)));
_node = tmpMeta[1];
_node = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 2))) ? ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 1)))) (threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 2))), _arg, _node) : ((modelica_metatype(*)(threadData_t*, modelica_metatype, modelica_metatype)) (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_updateFunc), 1)))) (threadData, _arg, _node);
tmpMeta[1] = mmc_mk_cons(_node, _nodes);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
_cr = omc_ComponentReference_crefFirstCref(threadData, _cref);
_id = omc_ComponentReference_printComponentRefStr(threadData, _cr);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_child_nodes = omc_ConnectUtil_setTrieUpdateNode2(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 5))), _arg, ((modelica_fnptr) _updateFunc), tmpMeta[1]);
tmpMeta[2] = mmc_mk_box5(3, &DAE_Connect_SetTrieNode_SET__TRIE__NODE__desc, _id, _cr, _child_nodes, mmc_mk_integer(((modelica_integer) 0)));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], _nodes);
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
_nodes = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _nodes;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieUpdateNode(threadData_t *threadData, modelica_string _id, modelica_metatype _wholeCref, modelica_metatype _cref, modelica_metatype _arg, modelica_fnptr _updateFunc, modelica_metatype __omcQ_24in_5Fnodes)
{
modelica_metatype _nodes = NULL;
modelica_metatype _node2 = NULL;
modelica_integer _n;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_nodes = __omcQ_24in_5Fnodes;
_n = ((modelica_integer) 1);
{
modelica_metatype _node;
for (tmpMeta[0] = _nodes; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_node = MMC_CAR(tmpMeta[0]);
if((omc_ConnectUtil_setTrieIsNode(threadData, _node) && (stringEqual(omc_ConnectUtil_setTrieNodeName(threadData, _node), _id))))
{
_node2 = omc_ConnectUtil_setTrieUpdate(threadData, _cref, _arg, _node, ((modelica_fnptr) _updateFunc));
_nodes = omc_List_replaceAt(threadData, _node2, _n, _nodes);
goto _return;
}
else
{
_n = ((modelica_integer) 1) + _n;
}
}
}
_nodes = omc_ConnectUtil_setTrieUpdateNode2(threadData, _wholeCref, _arg, ((modelica_fnptr) _updateFunc), _nodes);
_return: OMC_LABEL_UNUSED
return _nodes;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieUpdate(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _arg, modelica_metatype __omcQ_24in_5Ftrie, modelica_fnptr _updateFunc)
{
modelica_metatype _trie = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_trie = __omcQ_24in_5Ftrie;
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _cref;
tmp3_2 = _trie;
{
modelica_string _id = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,4) == 0) goto tmp2_end;
_id = omc_ComponentReference_printComponentRef2Str(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4))));
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_trie), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_ConnectUtil_setTrieUpdateNode(threadData, _id, _cref, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 5))), _arg, ((modelica_fnptr) _updateFunc), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_trie), 4))));
_trie = tmpMeta[0];
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,0,4) == 0) goto tmp2_end;
_id = omc_ComponentReference_printComponentRef2Str(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 4))));
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_trie), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = omc_ConnectUtil_setTrieUpdateLeaf(threadData, _id, _arg, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_trie), 4))), ((modelica_fnptr) _updateFunc));
_trie = tmpMeta[0];
goto tmp2_done;
}
}
goto tmp2_end;
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
return _trie;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_updateSetLeaf(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _cref, modelica_metatype _arg, modelica_fnptr _updateFunc)
{
modelica_metatype _sets = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_sets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = omc_ConnectUtil_setTrieUpdate(threadData, _cref, _arg, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))), ((modelica_fnptr) _updateFunc));
_sets = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieAdd(threadData_t *threadData, modelica_metatype _element, modelica_metatype __omcQ_24in_5Ftrie)
{
modelica_metatype _trie = NULL;
modelica_metatype _cref = NULL;
modelica_metatype _el_cr = NULL;
modelica_metatype _el = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_trie = __omcQ_24in_5Ftrie;
_cref = omc_ConnectUtil_getElementName(threadData, _element);
_el_cr = omc_ComponentReference_crefLastCref(threadData, _cref);
_el = omc_ConnectUtil_setElementName(threadData, _element, _el_cr);
_trie = omc_ConnectUtil_setTrieUpdate(threadData, _cref, _el, _trie, boxvar_ConnectUtil_setTrieAddLeafElement);
_return: OMC_LABEL_UNUSED
return _trie;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieGetLeafElement(threadData_t *threadData, modelica_metatype _node, modelica_metatype _face)
{
modelica_metatype _element = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;modelica_metatype tmp3_2;
tmp3_1 = _face;
tmp3_2 = _node;
{
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,0) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
if (optionNone(tmpMeta[1])) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_e = tmpMeta[2];
tmpMeta[0] = _e;
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,0) == 0) goto tmp2_end;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_2,1,5) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
if (optionNone(tmpMeta[1])) goto tmp2_end;
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
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_element = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieAddLeafElement(threadData_t *threadData, modelica_metatype _element, modelica_metatype __omcQ_24in_5Fnode)
{
modelica_metatype _node = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_node = __omcQ_24in_5Fnode;
{
modelica_metatype tmp3_1;
tmp3_1 = _node;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
{
modelica_metatype tmp7_1;
tmp7_1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_element), 3)));
{
volatile mmc_switch_type tmp7;
int tmp8;
tmp7 = 0;
for (; tmp7 < 2; tmp7++) {
switch (MMC_SWITCH_CAST(tmp7)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,0,0) == 0) goto tmp6_end;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_node), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = mmc_mk_some(_element);
_node = tmpMeta[0];
goto tmp6_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp7_1,1,0) == 0) goto tmp6_end;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_node), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = mmc_mk_some(_element);
_node = tmpMeta[0];
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
goto tmp2_done;
}
}
goto tmp2_end;
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
return _node;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieGetElement(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _face, modelica_metatype _trie)
{
modelica_metatype _element = NULL;
modelica_metatype _node = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_node = omc_ConnectUtil_setTrieGet(threadData, _cref, _trie, 0);
_element = omc_ConnectUtil_setTrieGetLeafElement(threadData, _node, _face);
_return: OMC_LABEL_UNUSED
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_connectSets(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_integer _set1;
modelica_integer _set2;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_set1 = omc_ConnectUtil_getElementSetIndex(threadData, _element1);
_set2 = omc_ConnectUtil_getElementSetIndex(threadData, _element2);
if((_set1 != _set2))
{
tmpMeta[2] = mmc_mk_box2(0, mmc_mk_integer(_set1), mmc_mk_integer(_set2));
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 4))));
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_sets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[4] = tmpMeta[1];
_sets = tmpMeta[0];
}
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addToSet(threadData_t *threadData, modelica_metatype _element, modelica_metatype _set, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_integer _index;
modelica_metatype _e = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_index = omc_ConnectUtil_getElementSetIndex(threadData, _set);
_e = omc_ConnectUtil_setElementSetIndex(threadData, _element, _index);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_sets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = omc_ConnectUtil_setTrieAdd(threadData, _e, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))));
_sets = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addNewSet(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_metatype _node = NULL;
modelica_integer _sc;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_sc = ((modelica_integer) 1) + mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 3))));
_e1 = omc_ConnectUtil_setElementSetIndex(threadData, _element1, _sc);
_e2 = omc_ConnectUtil_setElementSetIndex(threadData, _element2, _sc);
_node = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2)));
_node = omc_ConnectUtil_setTrieAdd(threadData, _e1, _node);
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_sets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = omc_ConnectUtil_setTrieAdd(threadData, _e2, _node);
_sets = tmpMeta[0];
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_sets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = mmc_mk_integer(_sc);
_sets = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_mergeSets2(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2, modelica_boolean _isNew1, modelica_boolean _isNew2, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
{
modelica_boolean tmp3_1;modelica_boolean tmp3_2;
tmp3_1 = _isNew1;
tmp3_2 = _isNew2;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (1 != tmp3_1) goto tmp2_end;
if (1 != tmp3_2) goto tmp2_end;
tmpMeta[0] = omc_ConnectUtil_addNewSet(threadData, _element1, _element2, _sets);
goto tmp2_done;
}
case 1: {
if (1 != tmp3_1) goto tmp2_end;
if (0 != tmp3_2) goto tmp2_end;
tmpMeta[0] = omc_ConnectUtil_addToSet(threadData, _element1, _element2, _sets);
goto tmp2_done;
}
case 2: {
if (0 != tmp3_1) goto tmp2_end;
if (1 != tmp3_2) goto tmp2_end;
tmpMeta[0] = omc_ConnectUtil_addToSet(threadData, _element2, _element1, _sets);
goto tmp2_done;
}
case 3: {
if (0 != tmp3_1) goto tmp2_end;
if (0 != tmp3_2) goto tmp2_end;
tmpMeta[0] = omc_ConnectUtil_connectSets(threadData, _element1, _element2, _sets);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_sets = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_mergeSets2(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2, modelica_metatype _isNew1, modelica_metatype _isNew2, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_integer tmp1;
modelica_integer tmp2;
modelica_metatype _sets = NULL;
tmp1 = mmc_unbox_integer(_isNew1);
tmp2 = mmc_unbox_integer(_isNew2);
_sets = omc_ConnectUtil_mergeSets2(threadData, _element1, _element2, tmp1, tmp2, __omcQ_24in_5Fsets);
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_mergeSets(threadData_t *threadData, modelica_metatype _element1, modelica_metatype _element2, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_boolean _new1;
modelica_boolean _new2;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_new1 = omc_ConnectUtil_isNewElement(threadData, _element1);
_new2 = omc_ConnectUtil_isNewElement(threadData, _element2);
_sets = omc_ConnectUtil_mergeSets2(threadData, _element1, _element2, _new1, _new2, _sets);
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_string omc_ConnectUtil_setTrieNodeName(threadData_t *threadData, modelica_metatype _node)
{
modelica_string _name = NULL;
modelica_string tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _node;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,4) == 0) goto tmp3_end;
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 2)));
goto tmp3_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,1,5) == 0) goto tmp3_end;
tmp1 = (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 2)));
goto tmp3_done;
}
}
goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieNewNode(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _element)
{
modelica_metatype _node = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _cref;
{
modelica_string _id = NULL;
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,3) == 0) goto tmp2_end;
_id = omc_ComponentReference_printComponentRefStr(threadData, _cref);
tmpMeta[0] = omc_ConnectUtil_setTrieNewLeaf(threadData, _id, omc_ConnectUtil_setElementName(threadData, _element, _cref));
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
_cr = omc_ComponentReference_crefFirstCref(threadData, _cref);
_id = omc_ComponentReference_printComponentRefStr(threadData, _cr);
_node = omc_ConnectUtil_setTrieNewNode(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_cref), 5))), _element);
tmpMeta[1] = mmc_mk_cons(_node, MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[2] = mmc_mk_box5(3, &DAE_Connect_SetTrieNode_SET__TRIE__NODE__desc, _id, _cr, tmpMeta[1], mmc_mk_integer(((modelica_integer) 0)));
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
_node = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _node;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setTrieNewLeaf(threadData_t *threadData, modelica_string _id, modelica_metatype _element)
{
modelica_metatype _leaf = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
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
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,0) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box6(4, &DAE_Connect_SetTrieNode_SET__TRIE__LEAF__desc, _id, mmc_mk_some(_element), mmc_mk_none(), mmc_mk_none(), mmc_mk_integer(((modelica_integer) 0)));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],1,0) == 0) goto tmp2_end;
tmpMeta[1] = mmc_mk_box6(4, &DAE_Connect_SetTrieNode_SET__TRIE__LEAF__desc, _id, mmc_mk_none(), mmc_mk_some(_element), mmc_mk_none(), mmc_mk_integer(((modelica_integer) 0)));
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
_leaf = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _leaf;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getElementSource(threadData_t *threadData, modelica_metatype _element)
{
modelica_metatype _source = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _element;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_source = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _source;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setElementName(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _name)
{
modelica_metatype _element = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = __omcQ_24in_5Felement;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = _name;
_element = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getElementName(threadData_t *threadData, modelica_metatype _element)
{
modelica_metatype _name = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _element;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_name = tmpMeta[1];
_return: OMC_LABEL_UNUSED
return _name;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_setElementSetIndex(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_integer _index)
{
modelica_metatype _element = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_element = __omcQ_24in_5Felement;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_element), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[6] = mmc_mk_integer(_index);
_element = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_setElementSetIndex(threadData_t *threadData, modelica_metatype __omcQ_24in_5Felement, modelica_metatype _index)
{
modelica_integer tmp1;
modelica_metatype _element = NULL;
tmp1 = mmc_unbox_integer(_index);
_element = omc_ConnectUtil_setElementSetIndex(threadData, __omcQ_24in_5Felement, tmp1);
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ConnectUtil_getElementSetIndex(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_integer _outIndex;
modelica_integer tmp1;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _inElement;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
_outIndex = tmp1;
_return: OMC_LABEL_UNUSED
return _outIndex;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_getElementSetIndex(threadData_t *threadData, modelica_metatype _inElement)
{
modelica_integer _outIndex;
modelica_metatype out_outIndex;
_outIndex = omc_ConnectUtil_getElementSetIndex(threadData, _inElement);
out_outIndex = mmc_mk_icon(_outIndex);
return out_outIndex;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isNewElement(threadData_t *threadData, modelica_metatype _element)
{
modelica_boolean _isNew;
modelica_integer _set;
modelica_integer tmp1;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _element;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 6));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
_set = tmp1;
_isNew = (_set == ((modelica_integer) -1));
_return: OMC_LABEL_UNUSED
return _isNew;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isNewElement(threadData_t *threadData, modelica_metatype _element)
{
modelica_boolean _isNew;
modelica_metatype out_isNew;
_isNew = omc_ConnectUtil_isNewElement(threadData, _element);
out_isNew = mmc_mk_icon(_isNew);
return out_isNew;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_newElement(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _face, modelica_metatype _ty, modelica_metatype _source, modelica_integer _set)
{
modelica_metatype _element = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box6(3, &DAE_Connect_ConnectorElement_CONNECTOR__ELEMENT__desc, _cref, _face, _ty, _source, mmc_mk_integer(_set));
_element = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_newElement(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _face, modelica_metatype _ty, modelica_metatype _source, modelica_metatype _set)
{
modelica_integer tmp1;
modelica_metatype _element = NULL;
tmp1 = mmc_unbox_integer(_set);
_element = omc_ConnectUtil_newElement(threadData, _cref, _face, _ty, _source, tmp1);
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_findElement(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _face, modelica_metatype _ty, modelica_metatype _source, modelica_metatype _sets)
{
modelica_metatype _element = NULL;
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
_element = omc_ConnectUtil_setTrieGetElement(threadData, _cref, _face, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))));
goto tmp2_done;
}
case 1: {
_element = omc_ConnectUtil_newElement(threadData, _cref, _face, _ty, _source, ((modelica_integer) -1));
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
return _element;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_optPrefixCref(threadData_t *threadData, modelica_metatype _prefix, modelica_metatype __omcQ_24in_5Fcref)
{
modelica_metatype _cref = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_cref = __omcQ_24in_5Fcref;
{
modelica_metatype tmp3_1;
tmp3_1 = _prefix;
{
modelica_metatype _cr = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[0] = _cref;
goto tmp2_done;
}
case 1: {
if (optionNone(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 1));
_cr = tmpMeta[1];
tmpMeta[0] = omc_ComponentReference_joinCrefs(threadData, _cr, _cref);
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_cref = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _cref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_findInnerElement(threadData_t *threadData, modelica_metatype _outerElement, modelica_metatype _innerCref, modelica_metatype _innerFace, modelica_metatype _sets)
{
modelica_metatype _innerElement = NULL;
modelica_metatype _name = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _src = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _outerElement;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
_name = tmpMeta[1];
_ty = tmpMeta[2];
_src = tmpMeta[3];
_name = omc_ComponentReference_joinCrefs(threadData, _innerCref, _name);
_innerElement = omc_ConnectUtil_findElement(threadData, _name, _innerFace, _ty, _src, _sets);
_return: OMC_LABEL_UNUSED
return _innerElement;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_collectOuterElements2(threadData_t *threadData, modelica_metatype _node, modelica_metatype _face, modelica_metatype _prefix)
{
modelica_metatype _outerElements = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _node;
{
modelica_metatype _cr = NULL;
modelica_metatype _e = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
_cr = tmpMeta[1];
_cr = omc_ConnectUtil_optPrefixCref(threadData, _prefix, _cr);
tmpMeta[0] = omc_List_map2Flat(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 4))), boxvar_ConnectUtil_collectOuterElements2, _face, mmc_mk_some(_cr));
goto tmp2_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
_e = omc_ConnectUtil_setTrieGetLeafElement(threadData, _node, _face);
_cr = omc_ConnectUtil_getElementName(threadData, _e);
_e = omc_ConnectUtil_setElementName(threadData, _e, omc_ConnectUtil_optPrefixCref(threadData, _prefix, _cr));
tmpMeta[1] = mmc_mk_cons(_e, MMC_REFSTRUCTLIT(mmc_nil));
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
_outerElements = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outerElements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_collectOuterElements(threadData_t *threadData, modelica_metatype _node, modelica_metatype _face)
{
modelica_metatype _outerElements = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _node;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,4) == 0) goto tmp2_end;
tmpMeta[0] = omc_List_map2Flat(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 4))), boxvar_ConnectUtil_collectOuterElements2, _face, mmc_mk_none());
goto tmp2_done;
}
case 1: {
tmpMeta[0] = omc_ConnectUtil_collectOuterElements2(threadData, _node, _face, mmc_mk_none());
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_outerElements = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _outerElements;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addOuterConnectToSets2(threadData_t *threadData, modelica_metatype _outerCref, modelica_metatype _innerCref, modelica_metatype _outerFace, modelica_metatype _innerFace, modelica_metatype __omcQ_24in_5Fsets, modelica_boolean *out_added)
{
modelica_metatype _sets = NULL;
modelica_boolean _added;
modelica_metatype _node = NULL;
modelica_metatype _outer_els = NULL;
modelica_metatype _inner_els = NULL;
modelica_integer _sc;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
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
_node = omc_ConnectUtil_setTrieGet(threadData, _outerCref, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))), 1);
_outer_els = omc_ConnectUtil_collectOuterElements(threadData, _node, _outerFace);
{
modelica_metatype __omcQ_24tmpVar7;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar6;
int tmp6;
modelica_metatype _oe_loopVar = 0;
modelica_metatype _oe;
_oe_loopVar = _outer_els;
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar7 = tmpMeta[1];
tmp5 = &__omcQ_24tmpVar7;
while(1) {
tmp6 = 1;
if (!listEmpty(_oe_loopVar)) {
_oe = MMC_CAR(_oe_loopVar);
_oe_loopVar = MMC_CDR(_oe_loopVar);
tmp6--;
}
if (tmp6 == 0) {
__omcQ_24tmpVar6 = omc_ConnectUtil_findInnerElement(threadData, _oe, _innerCref, _innerFace, _sets);
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar6,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[0] = __omcQ_24tmpVar7;
}
_inner_els = tmpMeta[0];
_sc = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 3))));
_sets = omc_List_threadFold(threadData, _outer_els, _inner_els, boxvar_ConnectUtil_mergeSets, _sets);
_added = (_sc != mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 3)))));
goto tmp2_done;
}
case 1: {
_added = 0;
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
if (out_added) { *out_added = _added; }
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_addOuterConnectToSets2(threadData_t *threadData, modelica_metatype _outerCref, modelica_metatype _innerCref, modelica_metatype _outerFace, modelica_metatype _innerFace, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype *out_added)
{
modelica_boolean _added;
modelica_metatype _sets = NULL;
_sets = omc_ConnectUtil_addOuterConnectToSets2(threadData, _outerCref, _innerCref, _outerFace, _innerFace, __omcQ_24in_5Fsets, &_added);
if (out_added) { *out_added = mmc_mk_icon(_added); }
return _sets;
}
DLLExport
modelica_metatype omc_ConnectUtil_addOuterConnectToSets(threadData_t *threadData, modelica_metatype _cref1, modelica_metatype _cref2, modelica_metatype _io1, modelica_metatype _io2, modelica_metatype _face1, modelica_metatype _face2, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _inInfo, modelica_boolean *out_added)
{
modelica_metatype _sets = NULL;
modelica_boolean _added;
modelica_boolean _is_outer1;
modelica_boolean _is_outer2;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_is_outer1 = omc_AbsynUtil_isOuter(threadData, _io1);
_is_outer2 = omc_AbsynUtil_isOuter(threadData, _io2);
{
modelica_boolean tmp4_1;modelica_boolean tmp4_2;
tmp4_1 = _is_outer1;
tmp4_2 = _is_outer2;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (1 != tmp4_1) goto tmp3_end;
if (1 != tmp4_2) goto tmp3_end;
omc_Error_addSourceMessage(threadData, _OMC_LIT89, _OMC_LIT93, _inInfo);
tmp1 = 0;
goto tmp3_done;
}
case 1: {
if (0 != tmp4_1) goto tmp3_end;
if (0 != tmp4_2) goto tmp3_end;
tmp1 = 0;
goto tmp3_done;
}
case 2: {
if (1 != tmp4_1) goto tmp3_end;
if (0 != tmp4_2) goto tmp3_end;
_sets = omc_ConnectUtil_addOuterConnectToSets2(threadData, _cref1, _cref2, _face1, _face2, _sets ,&_added);
tmp1 = _added;
goto tmp3_done;
}
case 3: {
if (0 != tmp4_1) goto tmp3_end;
if (1 != tmp4_2) goto tmp3_end;
_sets = omc_ConnectUtil_addOuterConnectToSets2(threadData, _cref2, _cref1, _face2, _face1, _sets ,&_added);
tmp1 = _added;
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_added = tmp1;
_return: OMC_LABEL_UNUSED
if (out_added) { *out_added = _added; }
return _sets;
}
modelica_metatype boxptr_ConnectUtil_addOuterConnectToSets(threadData_t *threadData, modelica_metatype _cref1, modelica_metatype _cref2, modelica_metatype _io1, modelica_metatype _io2, modelica_metatype _face1, modelica_metatype _face2, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _inInfo, modelica_metatype *out_added)
{
modelica_boolean _added;
modelica_metatype _sets = NULL;
_sets = omc_ConnectUtil_addOuterConnectToSets(threadData, _cref1, _cref2, _io1, _io2, _face1, _face2, __omcQ_24in_5Fsets, _inInfo, &_added);
if (out_added) { *out_added = mmc_mk_icon(_added); }
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_outerConnectionMatches(threadData_t *threadData, modelica_metatype _oc, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _matches;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _oc;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 1; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmp1 = ((omc_ComponentReference_crefEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_oc), 3))), _cr1) && omc_ComponentReference_crefEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_oc), 6))), _cr2)) || (omc_ComponentReference_crefEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_oc), 3))), _cr2) && omc_ComponentReference_crefEqual(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_oc), 6))), _cr1)));
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_matches = tmp1;
_return: OMC_LABEL_UNUSED
return _matches;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_outerConnectionMatches(threadData_t *threadData, modelica_metatype _oc, modelica_metatype _cr1, modelica_metatype _cr2)
{
modelica_boolean _matches;
modelica_metatype out_matches;
_matches = omc_ConnectUtil_outerConnectionMatches(threadData, _oc, _cr1, _cr2);
out_matches = mmc_mk_icon(_matches);
return out_matches;
}
DLLExport
modelica_metatype omc_ConnectUtil_addOuterConnection(threadData_t *threadData, modelica_metatype _scope, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _cr1, modelica_metatype _cr2, modelica_metatype _io1, modelica_metatype _io2, modelica_metatype _f1, modelica_metatype _f2, modelica_metatype _source)
{
modelica_metatype _sets = NULL;
modelica_metatype _new_oc = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
if((!omc_List_exist2(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 5))), boxvar_ConnectUtil_outerConnectionMatches, _cr1, _cr2)))
{
tmpMeta[0] = mmc_mk_box9(3, &DAE_Connect_OuterConnect_OUTERCONNECT__desc, _scope, _cr1, _io1, _f1, _cr2, _io2, _f2, _source);
_new_oc = tmpMeta[0];
tmpMeta[1] = mmc_mk_cons(_new_oc, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 5))));
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_sets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = tmpMeta[1];
_sets = tmpMeta[0];
}
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getStreamFlowAssociation(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _sets)
{
modelica_metatype _flowCref = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = omc_ConnectUtil_setTrieGet(threadData, _streamCref, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))), 0);
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],1,5) == 0) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 5));
if (optionNone(tmpMeta[1])) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 1));
_flowCref = tmpMeta[2];
_return: OMC_LABEL_UNUSED
return _flowCref;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addStreamFlowAssociation2(threadData_t *threadData, modelica_metatype _flowCref, modelica_metatype __omcQ_24in_5Fnode)
{
modelica_metatype _node = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_node = __omcQ_24in_5Fnode;
{
modelica_metatype tmp3_1;
tmp3_1 = _node;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 1; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,1,5) == 0) goto tmp2_end;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(7));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_node), 7*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[5] = mmc_mk_some(_flowCref);
_node = tmpMeta[0];
goto tmp2_done;
}
}
goto tmp2_end;
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
return _node;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addStreamFlowAssociation(threadData_t *threadData, modelica_metatype _streamCref, modelica_metatype _flowCref, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_sets = omc_ConnectUtil_updateSetLeaf(threadData, _sets, _streamCref, _flowCref, boxvar_ConnectUtil_addStreamFlowAssociation2);
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addInsideFlowVariable(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _cref, modelica_metatype _source, modelica_metatype _prefix)
{
modelica_metatype _sets = NULL;
modelica_metatype _e = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
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
omc_ConnectUtil_setTrieGetElement(threadData, _cref, _OMC_LIT40, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))));
goto tmp2_done;
}
case 1: {
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_sets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = mmc_mk_integer(((modelica_integer) 1) + mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 3)))));
_sets = tmpMeta[0];
_e = omc_ConnectUtil_newElement(threadData, _cref, _OMC_LIT40, _OMC_LIT94, _source, mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 3)))));
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_sets), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[2] = omc_ConnectUtil_setTrieAdd(threadData, _e, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_sets), 2))));
_sets = tmpMeta[0];
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
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getNextIndex(threadData_t *threadData, modelica_metatype _dim, modelica_metatype *out_restDim)
{
modelica_metatype _nextIndex = NULL;
modelica_metatype _restDim = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _dim;
{
modelica_integer _new_idx;
modelica_integer _dim_size;
modelica_metatype _p = NULL;
modelica_metatype _ep = NULL;
modelica_string _l = NULL;
modelica_metatype _l_rest = NULL;
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 4; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
modelica_integer tmp6;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp6 = mmc_unbox_integer(tmpMeta[2]);
if (0 != tmp6) goto tmp3_end;
goto goto_2;
goto tmp3_done;
}
case 1: {
modelica_integer tmp7;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp7 = mmc_unbox_integer(tmpMeta[2]);
if (0 != tmp7) goto tmp3_end;
goto goto_2;
goto tmp3_done;
}
case 2: {
modelica_integer tmp8;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,1) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmp8 = mmc_unbox_integer(tmpMeta[2]);
_new_idx = tmp8;
_dim_size = ((modelica_integer) -1) + _new_idx;
tmpMeta[2] = mmc_mk_box2(3, &DAE_Exp_ICONST__desc, mmc_mk_integer(_new_idx));
tmpMeta[3] = mmc_mk_box2(3, &DAE_Dimension_DIM__INTEGER__desc, mmc_mk_integer(_dim_size));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = tmpMeta[3];
goto tmp3_done;
}
case 3: {
modelica_integer tmp9;
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,2,3) == 0) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 3));
if (listEmpty(tmpMeta[3])) goto tmp3_end;
tmpMeta[4] = MMC_CAR(tmpMeta[3]);
tmpMeta[5] = MMC_CDR(tmpMeta[3]);
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
tmp9 = mmc_unbox_integer(tmpMeta[6]);
_p = tmpMeta[2];
_l = tmpMeta[4];
_l_rest = tmpMeta[5];
_new_idx = tmp9;
tmpMeta[2] = mmc_mk_box2(4, &Absyn_Path_IDENT__desc, _l);
_ep = omc_AbsynUtil_joinPaths(threadData, _p, tmpMeta[2]);
_dim_size = ((modelica_integer) -1) + _new_idx;
tmpMeta[2] = mmc_mk_box3(8, &DAE_Exp_ENUM__LITERAL__desc, _ep, mmc_mk_integer(_new_idx));
tmpMeta[3] = mmc_mk_box4(5, &DAE_Dimension_DIM__ENUM__desc, _p, _l_rest, mmc_mk_integer(_dim_size));
tmpMeta[0+0] = tmpMeta[2];
tmpMeta[0+1] = tmpMeta[3];
goto tmp3_done;
}
}
goto tmp3_end;
tmp3_end: ;
}
goto goto_2;
goto_2:;
MMC_THROW_INTERNAL();
goto tmp3_done;
tmp3_done:;
}
}
_nextIndex = tmpMeta[0+0];
_restDim = tmpMeta[0+1];
_return: OMC_LABEL_UNUSED
if (out_restDim) { *out_restDim = _restDim; }
return _nextIndex;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_reverseEnumType(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fdim)
{
modelica_metatype _dim = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_dim = __omcQ_24in_5Fdim;
{
modelica_metatype tmp3_1;
tmp3_1 = _dim;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,3) == 0) goto tmp2_end;
tmpMeta[0] = MMC_TAGPTR(mmc_alloc_words(5));
memcpy(MMC_UNTAGPTR(tmpMeta[0]), MMC_UNTAGPTR(_dim), 5*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[0]))[3] = listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_dim), 3))));
_dim = tmpMeta[0];
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
return _dim;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_expandArrayCref(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _dims, modelica_metatype _accumCrefs)
{
modelica_metatype _crefs = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;
tmp3_1 = _dims;
{
modelica_metatype _dim = NULL;
modelica_metatype _rest_dims = NULL;
modelica_metatype _idx = NULL;
modelica_metatype _cr = NULL;
modelica_metatype _crs = NULL;
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
tmpMeta[1] = mmc_mk_cons(_cref, _accumCrefs);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 1: {
if (listEmpty(tmp3_1)) goto tmp2_end;
tmpMeta[1] = MMC_CAR(tmp3_1);
tmpMeta[2] = MMC_CDR(tmp3_1);
_dim = tmpMeta[1];
_rest_dims = tmpMeta[2];
_idx = omc_ConnectUtil_getNextIndex(threadData, _dim ,&_dim);
tmpMeta[2] = mmc_mk_box2(5, &DAE_Subscript_INDEX__desc, _idx);
tmpMeta[1] = mmc_mk_cons(tmpMeta[2], MMC_REFSTRUCTLIT(mmc_nil));
_cr = omc_ComponentReference_subscriptCref(threadData, _cref, tmpMeta[1]);
_crs = omc_ConnectUtil_expandArrayCref(threadData, _cr, _rest_dims, _accumCrefs);
tmpMeta[1] = mmc_mk_cons(_dim, _rest_dims);
tmpMeta[0] = omc_ConnectUtil_expandArrayCref(threadData, _cref, tmpMeta[1], _crs);
goto tmp2_done;
}
case 2: {
tmpMeta[0] = _accumCrefs;
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
_crefs = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _crefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_daeVarToCrefs(threadData_t *threadData, modelica_metatype _var)
{
modelica_metatype _crefs = NULL;
modelica_string _name = NULL;
modelica_metatype _ty = NULL;
modelica_metatype _crs = NULL;
modelica_metatype _dims = NULL;
modelica_metatype _cr = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = _var;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
_name = tmpMeta[1];
_ty = tmpMeta[2];
_ty = omc_Types_derivedBasicType(threadData, _ty);
{
modelica_metatype tmp3_1;
tmp3_1 = _ty;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 4: {
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _name, _ty, tmpMeta[2]);
tmpMeta[1] = mmc_mk_cons(tmpMeta[3], MMC_REFSTRUCTLIT(mmc_nil));
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 12: {
{
modelica_metatype __omcQ_24tmpVar9;
modelica_metatype __omcQ_24tmpVar8;
int tmp4;
modelica_metatype _v_loopVar = 0;
modelica_metatype _v;
_v_loopVar = listReverse((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_ty), 3))));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar9 = tmpMeta[2];
while(1) {
tmp4 = 1;
if (!listEmpty(_v_loopVar)) {
_v = MMC_CAR(_v_loopVar);
_v_loopVar = MMC_CDR(_v_loopVar);
tmp4--;
}
if (tmp4 == 0) {
__omcQ_24tmpVar8 = omc_ConnectUtil_daeVarToCrefs(threadData, _v);
__omcQ_24tmpVar9 = listAppend(__omcQ_24tmpVar8, __omcQ_24tmpVar9);
} else if (tmp4 == 1) {
break;
} else {
goto goto_1;
}
}
tmpMeta[1] = __omcQ_24tmpVar9;
}
_crs = tmpMeta[1];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _name, _OMC_LIT49, tmpMeta[1]);
_cr = tmpMeta[2];
{
modelica_metatype __omcQ_24tmpVar11;
modelica_metatype* tmp5;
modelica_metatype __omcQ_24tmpVar10;
int tmp6;
modelica_metatype _c_loopVar = 0;
modelica_metatype _c;
_c_loopVar = _crs;
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
__omcQ_24tmpVar11 = tmpMeta[2];
tmp5 = &__omcQ_24tmpVar11;
while(1) {
tmp6 = 1;
if (!listEmpty(_c_loopVar)) {
_c = MMC_CAR(_c_loopVar);
_c_loopVar = MMC_CDR(_c_loopVar);
tmp6--;
}
if (tmp6 == 0) {
__omcQ_24tmpVar10 = omc_ComponentReference_joinCrefs(threadData, _cr, _c);
*tmp5 = mmc_mk_cons(__omcQ_24tmpVar10,0);
tmp5 = &MMC_CDR(*tmp5);
} else if (tmp6 == 1) {
break;
} else {
goto goto_1;
}
}
*tmp5 = mmc_mk_nil();
tmpMeta[1] = __omcQ_24tmpVar11;
}
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 9: {
_dims = omc_Types_getDimensions(threadData, _ty);
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[2] = mmc_mk_box4(4, &DAE_ComponentRef_CREF__IDENT__desc, _name, _ty, tmpMeta[1]);
_cr = tmpMeta[2];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[0] = omc_ConnectUtil_expandArrayCref(threadData, _cr, _dims, tmpMeta[1]);
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
tmpMeta[1] = stringAppend(_OMC_LIT95,_name);
tmpMeta[2] = stringAppend(tmpMeta[1],_OMC_LIT96);
omc_Error_addInternalError(threadData, tmpMeta[2], _OMC_LIT98);
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
_crefs = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _crefs;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addStreamFlowAssociations(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _prefix, modelica_metatype _streamVars, modelica_metatype _flowVars)
{
modelica_metatype _sets = NULL;
modelica_metatype _flow_var = NULL;
modelica_metatype _flow_cr = NULL;
modelica_metatype _stream_crs = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
if(listEmpty(_streamVars))
{
goto _return;
}
tmpMeta[0] = _flowVars;
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (!listEmpty(tmpMeta[2])) MMC_THROW_INTERNAL();
_flow_var = tmpMeta[1];
tmpMeta[0] = omc_ConnectUtil_daeVarToCrefs(threadData, _flow_var);
if (listEmpty(tmpMeta[0])) MMC_THROW_INTERNAL();
tmpMeta[1] = MMC_CAR(tmpMeta[0]);
tmpMeta[2] = MMC_CDR(tmpMeta[0]);
if (!listEmpty(tmpMeta[2])) MMC_THROW_INTERNAL();
_flow_cr = tmpMeta[1];
_flow_cr = omc_PrefixUtil_prefixCrefNoContext(threadData, _prefix, _flow_cr);
{
modelica_metatype _stream_var;
for (tmpMeta[0] = _streamVars; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_stream_var = MMC_CAR(tmpMeta[0]);
_stream_crs = omc_ConnectUtil_daeVarToCrefs(threadData, _stream_var);
{
modelica_metatype _stream_cr;
for (tmpMeta[1] = _stream_crs; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_stream_cr = MMC_CAR(tmpMeta[1]);
_sets = omc_ConnectUtil_addStreamFlowAssociation(threadData, _stream_cr, _flow_cr, _sets);
}
}
}
}
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getStreamAndFlowVariables(threadData_t *threadData, modelica_metatype _variables, modelica_metatype *out_streams)
{
modelica_metatype _flows = NULL;
modelica_metatype _streams = NULL;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_flows = tmpMeta[0];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_streams = tmpMeta[1];
{
modelica_metatype _var;
for (tmpMeta[2] = _variables; !listEmpty(tmpMeta[2]); tmpMeta[2]=MMC_CDR(tmpMeta[2]))
{
_var = MMC_CAR(tmpMeta[2]);
{
modelica_metatype tmp3_1;
tmp3_1 = _var;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 3; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],1,0) == 0) goto tmp2_end;
tmpMeta[3] = mmc_mk_cons(_var, _flows);
_flows = tmpMeta[3];
goto tmp2_done;
}
case 1: {
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],2,1) == 0) goto tmp2_end;
tmpMeta[3] = mmc_mk_cons(_var, _streams);
_streams = tmpMeta[3];
goto tmp2_done;
}
case 2: {
goto tmp2_done;
}
}
goto tmp2_end;
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
if (out_streams) { *out_streams = _streams; }
return _flows;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_getExpandableVariablesWithNoBinding(threadData_t *threadData, modelica_metatype _variables)
{
modelica_metatype _potential = NULL;
modelica_metatype _name = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_potential = tmpMeta[0];
{
modelica_metatype _var;
for (tmpMeta[1] = _variables; !listEmpty(tmpMeta[1]); tmpMeta[1]=MMC_CDR(tmpMeta[1]))
{
_var = MMC_CAR(tmpMeta[1]);
{
modelica_metatype tmp3_1;
tmp3_1 = _var;
{
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,0,13) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 8));
if (!optionNone(tmpMeta[3])) goto tmp2_end;
_name = tmpMeta[2];
if(omc_ConnectUtil_isExpandable(threadData, _name))
{
tmpMeta[2] = mmc_mk_cons(_name, _potential);
_potential = tmpMeta[2];
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
return _potential;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isVarExpandable(threadData_t *threadData, modelica_metatype _var)
{
modelica_boolean _isExpandable;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _var;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp4_1,0,13) == 0) goto tmp3_end;
tmp1 = omc_ConnectUtil_isExpandable(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_var), 2))));
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
_isExpandable = tmp1;
_return: OMC_LABEL_UNUSED
return _isExpandable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isVarExpandable(threadData_t *threadData, modelica_metatype _var)
{
modelica_boolean _isExpandable;
modelica_metatype out_isExpandable;
_isExpandable = omc_ConnectUtil_isVarExpandable(threadData, _var);
out_isExpandable = mmc_mk_icon(_isExpandable);
return out_isExpandable;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_daeHasExpandableConnectors(threadData_t *threadData, modelica_metatype _DAE)
{
modelica_boolean _hasExpandable;
modelica_metatype _vars = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
if(omc_System_getHasExpandableConnectors(threadData))
{
tmpMeta[0] = _DAE;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 2));
_vars = tmpMeta[1];
_hasExpandable = omc_List_exist(threadData, _vars, boxvar_ConnectUtil_isVarExpandable);
}
else
{
_hasExpandable = 0;
}
_return: OMC_LABEL_UNUSED
return _hasExpandable;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_daeHasExpandableConnectors(threadData_t *threadData, modelica_metatype _DAE)
{
modelica_boolean _hasExpandable;
modelica_metatype out_hasExpandable;
_hasExpandable = omc_ConnectUtil_daeHasExpandableConnectors(threadData, _DAE);
out_hasExpandable = mmc_mk_icon(_hasExpandable);
return out_hasExpandable;
}
DLLExport
modelica_boolean omc_ConnectUtil_isExpandable(threadData_t *threadData, modelica_metatype _name)
{
modelica_boolean _expandableConnector;
modelica_boolean tmp1 = 0;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _name;
{
int tmp4;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp4_1))) {
case 4: {
tmp1 = omc_Types_isExpandableConnector(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_name), 3))));
goto tmp3_done;
}
case 3: {
tmp1 = (omc_Types_isExpandableConnector(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_name), 3)))) || omc_ConnectUtil_isExpandable(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_name), 5)))));
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
_expandableConnector = tmp1;
_return: OMC_LABEL_UNUSED
return _expandableConnector;
}
modelica_metatype boxptr_ConnectUtil_isExpandable(threadData_t *threadData, modelica_metatype _name)
{
modelica_boolean _expandableConnector;
modelica_metatype out_expandableConnector;
_expandableConnector = omc_ConnectUtil_isExpandable(threadData, _name);
out_expandableConnector = mmc_mk_icon(_expandableConnector);
return out_expandableConnector;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_addFlowVariableFromDAE(threadData_t *threadData, modelica_metatype _variable, modelica_metatype _elementSource, modelica_metatype _prefix, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_metatype _crefs = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_crefs = omc_ConnectUtil_daeVarToCrefs(threadData, _variable);
{
modelica_metatype _cr;
for (tmpMeta[0] = _crefs; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_cr = MMC_CAR(tmpMeta[0]);
_sets = omc_ConnectUtil_addInsideFlowVariable(threadData, _sets, _cr, _elementSource, _prefix);
}
}
_return: OMC_LABEL_UNUSED
return _sets;
}
DLLExport
modelica_metatype omc_ConnectUtil_addConnectorVariablesFromDAE(threadData_t *threadData, modelica_boolean _ignore, modelica_metatype _classState, modelica_metatype _prefix, modelica_metatype _vars, modelica_metatype _info, modelica_metatype _elementSource, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_metatype tmpMeta[3] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
{
modelica_metatype tmp3_1;
tmp3_1 = _classState;
{
modelica_metatype _class_path = NULL;
modelica_metatype _streams = NULL;
modelica_metatype _flows = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
for (; tmp3 < 2; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
modelica_integer tmp5;
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,5,2) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 3));
tmp5 = mmc_unbox_integer(tmpMeta[2]);
if (0 != tmp5) goto tmp2_end;
_class_path = tmpMeta[1];
if (!(!_ignore)) goto tmp2_end;
omc_ConnectUtil_checkConnectorBalance(threadData, _vars, _class_path, _info);
if((!omc_Flags_isSet(threadData, _OMC_LIT102)))
{
_flows = omc_ConnectUtil_getStreamAndFlowVariables(threadData, _vars ,&_streams);
_sets = omc_List_fold2(threadData, _flows, boxvar_ConnectUtil_addFlowVariableFromDAE, _elementSource, _prefix, _sets);
_sets = omc_ConnectUtil_addStreamFlowAssociations(threadData, _sets, _prefix, _streams, _flows);
}
tmpMeta[0] = _sets;
goto tmp2_done;
}
case 1: {
tmpMeta[0] = _sets;
goto tmp2_done;
}
}
goto tmp2_end;
tmp2_end: ;
}
goto goto_1;
goto_1:;
MMC_THROW_INTERNAL();
goto tmp2_done;
tmp2_done:;
}
}
_sets = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _sets;
}
modelica_metatype boxptr_ConnectUtil_addConnectorVariablesFromDAE(threadData_t *threadData, modelica_metatype _ignore, modelica_metatype _classState, modelica_metatype _prefix, modelica_metatype _vars, modelica_metatype _info, modelica_metatype _elementSource, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_integer tmp1;
modelica_metatype _sets = NULL;
tmp1 = mmc_unbox_integer(_ignore);
_sets = omc_ConnectUtil_addConnectorVariablesFromDAE(threadData, tmp1, _classState, _prefix, _vars, _info, _elementSource, __omcQ_24in_5Fsets);
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_metatype omc_ConnectUtil_makeConnectorType(threadData_t *threadData, modelica_metatype _connectorType)
{
modelica_metatype _ty = NULL;
modelica_metatype _flowName = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp3_1;
tmp3_1 = _connectorType;
{
int tmp3;
{
switch (MMC_SWITCH_CAST(valueConstructor(tmp3_1))) {
case 3: {
tmpMeta[0] = _OMC_LIT103;
goto tmp2_done;
}
case 4: {
tmpMeta[0] = _OMC_LIT94;
goto tmp2_done;
}
case 5: {
if (mmc__uniontype__metarecord__typedef__equal(tmp3_1,2,1) == 0) goto tmp2_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
_flowName = tmpMeta[1];
tmpMeta[1] = mmc_mk_box2(5, &DAE_Connect_ConnectorType_STREAM__desc, _flowName);
tmpMeta[0] = tmpMeta[1];
goto tmp2_done;
}
case 6: {
tmpMeta[0] = _OMC_LIT83;
goto tmp2_done;
}
default:
tmp2_default: OMC_LABEL_UNUSED; {
omc_Error_addMessage(threadData, _OMC_LIT78, _OMC_LIT105);
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
_ty = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _ty;
}
DLLExport
modelica_metatype omc_ConnectUtil_addArrayConnection(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _cref1, modelica_metatype _face1, modelica_metatype _cref2, modelica_metatype _face2, modelica_metatype _source, modelica_metatype _connectorType)
{
modelica_metatype _sets = NULL;
modelica_metatype _crefs1 = NULL;
modelica_metatype _crefs2 = NULL;
modelica_metatype _cr2 = NULL;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_crefs1 = omc_ComponentReference_expandCref(threadData, _cref1, 0);
_crefs2 = omc_ComponentReference_expandCref(threadData, _cref2, 0);
{
modelica_metatype _cr1;
for (tmpMeta[0] = _crefs1; !listEmpty(tmpMeta[0]); tmpMeta[0]=MMC_CDR(tmpMeta[0]))
{
_cr1 = MMC_CAR(tmpMeta[0]);
tmpMeta[1] = _crefs2;
if (listEmpty(tmpMeta[1])) MMC_THROW_INTERNAL();
tmpMeta[2] = MMC_CAR(tmpMeta[1]);
tmpMeta[3] = MMC_CDR(tmpMeta[1]);
_cr2 = tmpMeta[2];
_crefs2 = tmpMeta[3];
_sets = omc_ConnectUtil_addConnection(threadData, _sets, _cr1, _face1, _cr2, _face2, _connectorType, _source);
}
}
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_integer omc_ConnectUtil_getConnectCount(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _trie)
{
modelica_integer _count;
modelica_metatype _node = NULL;
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
modelica_integer tmp5 = 0;
_node = omc_ConnectUtil_setTrieGet(threadData, _cref, _trie, 0);
{
modelica_metatype tmp8_1;
tmp8_1 = _node;
{
volatile mmc_switch_type tmp8;
int tmp9;
tmp8 = 0;
for (; tmp8 < 2; tmp8++) {
switch (MMC_SWITCH_CAST(tmp8)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,0,4) == 0) goto tmp7_end;
tmp5 = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 5))));
goto tmp7_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp8_1,1,5) == 0) goto tmp7_end;
tmp5 = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 6))));
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
_count = tmp5;
goto tmp2_done;
}
case 1: {
_count = ((modelica_integer) 0);
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
return _count;
}
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_getConnectCount(threadData_t *threadData, modelica_metatype _cref, modelica_metatype _trie)
{
modelica_integer _count;
modelica_metatype out_count;
_count = omc_ConnectUtil_getConnectCount(threadData, _cref, _trie);
out_count = mmc_mk_icon(_count);
return out_count;
}
DLLExport
modelica_metatype omc_ConnectUtil_addConnection(threadData_t *threadData, modelica_metatype __omcQ_24in_5Fsets, modelica_metatype _cref1, modelica_metatype _face1, modelica_metatype _cref2, modelica_metatype _face2, modelica_metatype _connectorType, modelica_metatype _source)
{
modelica_metatype _sets = NULL;
modelica_metatype _e1 = NULL;
modelica_metatype _e2 = NULL;
modelica_metatype _ty = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
_ty = omc_ConnectUtil_makeConnectorType(threadData, _connectorType);
_e1 = omc_ConnectUtil_findElement(threadData, _cref1, _face1, _ty, _source, _sets);
_e2 = omc_ConnectUtil_findElement(threadData, _cref2, _face2, _ty, _source, _sets);
_sets = omc_ConnectUtil_mergeSets(threadData, _e1, _e2, _sets);
_return: OMC_LABEL_UNUSED
return _sets;
}
PROTECTED_FUNCTION_STATIC modelica_boolean omc_ConnectUtil_isEmptySet(threadData_t *threadData, modelica_metatype _sets)
{
modelica_boolean _isEmpty;
modelica_boolean tmp1 = 0;
modelica_metatype tmpMeta[4] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
modelica_metatype tmp4_1;
tmp4_1 = _sets;
{
volatile mmc_switch_type tmp4;
int tmp5;
tmp4 = 0;
for (; tmp4 < 2; tmp4++) {
switch (MMC_SWITCH_CAST(tmp4)) {
case 0: {
tmpMeta[0] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[0],0,4) == 0) goto tmp3_end;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 4));
if (!listEmpty(tmpMeta[1])) goto tmp3_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 4));
if (!listEmpty(tmpMeta[2])) goto tmp3_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp4_1), 5));
if (!listEmpty(tmpMeta[3])) goto tmp3_end;
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
PROTECTED_FUNCTION_STATIC modelica_metatype boxptr_ConnectUtil_isEmptySet(threadData_t *threadData, modelica_metatype _sets)
{
modelica_boolean _isEmpty;
modelica_metatype out_isEmpty;
_isEmpty = omc_ConnectUtil_isEmptySet(threadData, _sets);
out_isEmpty = mmc_mk_icon(_isEmpty);
return out_isEmpty;
}
DLLExport
modelica_metatype omc_ConnectUtil_addSet(threadData_t *threadData, modelica_metatype _parentSets, modelica_metatype _childSets)
{
modelica_metatype _sets = NULL;
modelica_metatype tmpMeta[7] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
volatile modelica_metatype tmp3_1;volatile modelica_metatype tmp3_2;
tmp3_1 = _parentSets;
tmp3_2 = _childSets;
{
modelica_metatype _c1 = NULL;
modelica_metatype _c2 = NULL;
modelica_metatype _o1 = NULL;
modelica_metatype _o2 = NULL;
modelica_integer _sc;
modelica_metatype _node = NULL;
volatile mmc_switch_type tmp3;
int tmp4;
tmp3 = 0;
MMC_TRY_INTERNAL(mmc_jumper)
tmp2_top:
threadData->mmc_jumper = &new_mmc_jumper;
for (; tmp3 < 4; tmp3++) {
switch (MMC_SWITCH_CAST(tmp3)) {
case 0: {
if (!omc_ConnectUtil_isEmptySet(threadData, _childSets)) goto tmp2_end;
tmpMeta[0] = _parentSets;
goto tmp2_done;
}
case 1: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,4) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[1]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[2],4,0) == 0) goto tmp2_end;
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[3],0,4) == 0) goto tmp2_end;
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[3]), 3));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[4],4,0) == 0) goto tmp2_end;
tmpMeta[0] = _childSets;
goto tmp2_done;
}
case 2: {
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,4) == 0) goto tmp2_end;
_node = tmpMeta[1];
omc_ConnectUtil_setTrieGetNode(threadData, omc_ConnectUtil_setTrieNodeName(threadData, (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_childSets), 2)))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 4))));
tmpMeta[0] = _parentSets;
goto tmp2_done;
}
case 3: {
modelica_integer tmp5;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 2));
if (mmc__uniontype__metarecord__typedef__equal(tmpMeta[1],0,4) == 0) goto tmp2_end;
tmpMeta[2] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 4));
tmpMeta[3] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_1), 5));
tmpMeta[4] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 3));
tmp5 = mmc_unbox_integer(tmpMeta[4]);
tmpMeta[5] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 4));
tmpMeta[6] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmp3_2), 5));
_node = tmpMeta[1];
_c1 = tmpMeta[2];
_o1 = tmpMeta[3];
_sc = tmp5;
_c2 = tmpMeta[5];
_o2 = tmpMeta[6];
_c1 = listAppend(_c2, _c1);
_o1 = listAppend(_o2, _o1);
tmpMeta[2] = mmc_mk_cons((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_childSets), 2))), (MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_node), 4))));
tmpMeta[1] = MMC_TAGPTR(mmc_alloc_words(6));
memcpy(MMC_UNTAGPTR(tmpMeta[1]), MMC_UNTAGPTR(_node), 6*sizeof(modelica_metatype));
((modelica_metatype*)MMC_UNTAGPTR(tmpMeta[1]))[4] = tmpMeta[2];
_node = tmpMeta[1];
tmpMeta[1] = mmc_mk_box5(3, &DAE_Connect_Sets_SETS__desc, _node, mmc_mk_integer(_sc), _c1, _o1);
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
_sets = tmpMeta[0];
_return: OMC_LABEL_UNUSED
return _sets;
}
DLLExport
modelica_metatype omc_ConnectUtil_newSet(threadData_t *threadData, modelica_metatype _prefix, modelica_metatype __omcQ_24in_5Fsets)
{
modelica_metatype _sets = NULL;
modelica_string _pstr = NULL;
modelica_integer _sc;
modelica_metatype _cr = NULL;
modelica_integer tmp1;
modelica_metatype tmpMeta[5] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_sets = __omcQ_24in_5Fsets;
tmpMeta[0] = _sets;
tmpMeta[1] = MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(tmpMeta[0]), 3));
tmp1 = mmc_unbox_integer(tmpMeta[1]);
_sc = tmp1;
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
_cr = omc_PrefixUtil_prefixFirstCref(threadData, _prefix);
_pstr = omc_ComponentReference_printComponentRefStr(threadData, _cr);
goto tmp3_done;
}
case 1: {
_cr = _OMC_LIT106;
_pstr = _OMC_LIT5;
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
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[1] = mmc_mk_box5(3, &DAE_Connect_SetTrieNode_SET__TRIE__NODE__desc, _pstr, _cr, tmpMeta[0], mmc_mk_integer(((modelica_integer) 0)));
tmpMeta[2] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[3] = MMC_REFSTRUCTLIT(mmc_nil);
tmpMeta[4] = mmc_mk_box5(3, &DAE_Connect_Sets_SETS__desc, tmpMeta[1], mmc_mk_integer(_sc), tmpMeta[2], tmpMeta[3]);
_sets = tmpMeta[4];
_return: OMC_LABEL_UNUSED
return _sets;
}
